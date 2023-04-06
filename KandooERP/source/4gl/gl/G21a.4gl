###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
# \file
# \brief module G21a  - Contains common routines FOR GL batch entry/edit
#                  (G21a.4gl superceeds batadd/batupd)
#   These functions are called throughout KandooERP GL WHERE ever batches
#   are created AND/OR GL account distribution IS performed.  Note that
#   WHEN editting any batch with bank accounts,  no editting/deletion of
#   bank acount lines in permitted.  This IS TO ensure full bank
#   reconciliation IS maintained.  The UPDATE routines creates banking/
#   cbaudit entires but note the edit routine assumes thay exist.
#
#   Functions in this source file are called FROM:-
#      G21 - General Journal Entry
#      G22 - General Journal Edit
#      G29 - Subsidiary Batch Edit
#      G27 - External Batch Edit
#      GC1 - Cash Book Batch Edit (SC)
#      GC2 - Cash Book Batch Edit (BC)
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G21_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_balanced_flag boolean 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_dbg_accept boolean 
DEFINE modu_balanced_text array[2] OF STRING 
############################################################
# FUNCTION init_journal(p_jour_num)
#
#
############################################################
FUNCTION init_journal(p_jour_num) 
	DEFINE p_jour_num LIKE batchhead.jour_num 
	DEFINE l_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_arr_rec_t_batchdetl DYNAMIC ARRAY OF RECORD LIKE t_batchdetl.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_query_text STRING 
	DEFINE l_rows_number SMALLINT 

	LET l_sign_on_code = glob_rec_kandoouser.sign_on_code 

	--	CLEAR FORM #I don't like to have this UI stuff in db logic
	-- DELETE FROM t_batchdetl
	IF p_jour_num IS NULL THEN #null = new batch 
		INITIALIZE glob_rec_batchhead.* TO NULL 

		LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchhead.jour_num = NULL 
		LET glob_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
		LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_batchhead.jour_date = today 
		LET glob_rec_batchhead.source_ind = "G" 
		LET glob_rec_batchhead.control_amt = 0 
		LET glob_rec_batchhead.control_qty = 0 
		LET glob_rec_batchhead.stats_qty = 0 
		LET glob_rec_batchhead.for_debit_amt = 0 
		LET glob_rec_batchhead.for_credit_amt= 0 
		LET glob_rec_batchhead.debit_amt = 0 
		LET glob_rec_batchhead.credit_amt= 0 
		LET glob_rec_batchhead.seq_num= 0 
		LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
		LET glob_rec_batchhead.conv_qty = 1 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING glob_rec_batchhead.year_num, glob_rec_batchhead.period_num 

	ELSE #edit existing (none-posted) batch with p_jour_num 

		SELECT * INTO glob_rec_batchhead.* 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_num = p_jour_num 
		LET glob_rec_1_batchhead.* = glob_rec_batchhead.* #what IS this FOR ? 

		# ------------------------------------------------------
		# Make sure that static temp table for this user is empty before populating it
		DELETE FROM t_batchdetl WHERE (1 = 1) AND username = l_sign_on_code 
		# ------------------------------------------------------

		#Select batch details and store in static-temp-table
		LET l_query_text = 
			"SELECT * FROM batchdetl ", 
			"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
			"AND jour_num = ", trim(p_jour_num), " ", 
			"ORDER BY seq_num" 

		PREPARE p_edit_batchdetl FROM l_query_text 
		DECLARE c_edit_batchdetl CURSOR FOR p_edit_batchdetl 

		--	LET rows_number = 0
		LET l_rows_number = 0 
		# look in the 'uncompleted batches personal tank' if there is some batch


		FOREACH c_edit_batchdetl INTO l_rec_batchdetl 
			LET l_rows_number = l_rows_number + 1 
			CALL batchdetl_to_t_batchdetl_rec_data_morphing(l_rec_batchdetl.*) RETURNING l_arr_rec_t_batchdetl[l_rows_number].* 

			IF get_debug() THEN 
				DISPLAY "-----------------" 
				DISPLAY "cmpy_code", l_arr_rec_t_batchdetl[l_rows_number].cmpy_code 
				DISPLAY "jour_code", l_arr_rec_t_batchdetl[l_rows_number].jour_code 
				DISPLAY "jour_num", l_arr_rec_t_batchdetl[l_rows_number].jour_num 
				DISPLAY "seq_num", l_arr_rec_t_batchdetl[l_rows_number].seq_num 
				DISPLAY "tran_type_ind", l_arr_rec_t_batchdetl[l_rows_number].tran_type_ind 
				DISPLAY "analysis_text", l_arr_rec_t_batchdetl[l_rows_number].analysis_text 
				DISPLAY "tran_date", l_arr_rec_t_batchdetl[l_rows_number].tran_date 
				DISPLAY "ref_text", l_arr_rec_t_batchdetl[l_rows_number].ref_text 
				DISPLAY "ref_num", l_arr_rec_t_batchdetl[l_rows_number].ref_num 
				DISPLAY "acct_code", l_arr_rec_t_batchdetl[l_rows_number].acct_code 
				DISPLAY "desc_text", l_arr_rec_t_batchdetl[l_rows_number].desc_text 
				DISPLAY "debit_amt", l_arr_rec_t_batchdetl[l_rows_number].debit_amt 
				DISPLAY "credit_amt", l_arr_rec_t_batchdetl[l_rows_number].credit_amt 
				DISPLAY "currency_code", l_arr_rec_t_batchdetl[l_rows_number].currency_code 
				DISPLAY "conv_qty", l_arr_rec_t_batchdetl[l_rows_number].conv_qty 
				DISPLAY "for_debit_amt", l_arr_rec_t_batchdetl[l_rows_number].for_debit_amt 
				DISPLAY "for_credit_amt", l_arr_rec_t_batchdetl[l_rows_number].for_credit_amt 
				DISPLAY "stats_qty", l_arr_rec_t_batchdetl[l_rows_number].stats_qty 
				DISPLAY "username", l_arr_rec_t_batchdetl[l_rows_number].username 
				DISPLAY "-----------------" 
			END IF 
			{
						INSERT INTO t_batchdetl
			(
			cmpy_code,
			jour_code,
			jour_num,
			seq_num,
			tran_type_ind,
			analysis_text,
			tran_date,
			ref_text,
			ref_num,
			acct_code,
			desc_text,
			debit_amt,
			credit_amt,
			currency_code,
			conv_qty,
			for_debit_amt,
			for_credit_amt,
			stats_qty,
			username

			)
					VALUES(
			'KA',
			'GJ',
			127,
			1,
			'ADJ',
			'OK..............',
			'20/12/2019',
			'',
			'',
			'KAU-002-0011 ',
			'',
			33.00,
			0.00,
			'UAH',
			1.00,
			33.00,
			0.00,
			0.00,
			'AnBl'
			)

			}

			--			INSERT INTO t_batchdetl VALUES (l_arr_rec_batchdetl[l_rows_number].*)
			INSERT INTO t_batchdetl( 
				cmpy_code, 
				jour_code, 
				jour_num, 
				seq_num, 
				tran_type_ind, 
				analysis_text, 
				tran_date, 
				ref_text, 
				ref_num, 
				acct_code, 
				desc_text, 
				debit_amt, 
				credit_amt, 
				currency_code, 
				conv_qty, 
				for_debit_amt, 
				for_credit_amt, 
				stats_qty, 
				username ) 
			VALUES ( 
				l_arr_rec_t_batchdetl[l_rows_number].cmpy_code, 
				l_arr_rec_t_batchdetl[l_rows_number].jour_code, 
				l_arr_rec_t_batchdetl[l_rows_number].jour_num, 
				l_arr_rec_t_batchdetl[l_rows_number].seq_num, 
				l_arr_rec_t_batchdetl[l_rows_number].tran_type_ind, 
				l_arr_rec_t_batchdetl[l_rows_number].analysis_text, 
				l_arr_rec_t_batchdetl[l_rows_number].tran_date, 
				l_arr_rec_t_batchdetl[l_rows_number].ref_text, 
				l_arr_rec_t_batchdetl[l_rows_number].ref_num, 
				l_arr_rec_t_batchdetl[l_rows_number].acct_code, 
				l_arr_rec_t_batchdetl[l_rows_number].desc_text, 
				l_arr_rec_t_batchdetl[l_rows_number].debit_amt, 
				l_arr_rec_t_batchdetl[l_rows_number].credit_amt, 
				l_arr_rec_t_batchdetl[l_rows_number].currency_code, 
				l_arr_rec_t_batchdetl[l_rows_number].conv_qty, 
				l_arr_rec_t_batchdetl[l_rows_number].for_debit_amt, 
				l_arr_rec_t_batchdetl[l_rows_number].for_credit_amt, 
				l_arr_rec_t_batchdetl[l_rows_number].stats_qty, 
				l_arr_rec_t_batchdetl[l_rows_number].username	) 

			IF sqlca.sqlcode != 0 THEN 
				ERROR "Could not insert this row" 
			END IF 
		END FOREACH 

		# ------------------------------------------------------------
		# delete invalid rows from table before processing
		# This batch is not posted, so it's validate to check and remove corrupted lines

		DELETE FROM t_batchdetl WHERE (seq_num = 0 OR seq_num IS null) AND username = l_sign_on_code 
		DELETE FROM t_batchdetl WHERE (acct_code IS null) AND username = l_sign_on_code 

		DELETE FROM t_batchdetl 
		WHERE (debit_amt = 0 OR debit_amt IS null) 
		AND (credit_amt = 0 OR credit_amt IS null) 
		AND (for_debit_amt = 0 OR for_debit_amt IS null) 
		AND (for_credit_amt = 0 OR for_credit_amt IS null) 
		AND username = l_sign_on_code 
		# ------------------------------------------------------------

		LET glob_rec_batchhead.seq_num = sqlca.sqlerrd[3] #@eric, why IS this required, why should this be done ? 

	END IF 
END FUNCTION 
############################################################
# END FUNCTION init_journal(p_jour_num)
############################################################


############################################################
# FUNCTION G21_header()
#
#
############################################################
FUNCTION G21_header() 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_temp_text char(20) 
	DEFINE l_invalid_period SMALLINT 

	DISPLAY glob_rec_batchhead.entry_code TO batchhead.entry_code 
	DISPLAY glob_rec_batchhead.jour_num TO batchhead.jour_num 
	DISPLAY glob_rec_batchhead.jour_date TO batchhead.jour_date 

	MESSAGE kandoomsg2("G",1041,"") #1041 Enter batch info;   OK TO Continue.

	INPUT BY NAME 
		glob_rec_batchhead.jour_code, 
		glob_rec_batchhead.year_num, 
		glob_rec_batchhead.period_num, 
		glob_rec_batchhead.currency_code, 
		glob_rec_batchhead.rate_type_ind, 
		glob_rec_batchhead.conv_qty, 
		glob_rec_batchhead.control_qty, 
		glob_rec_batchhead.control_amt, 
		glob_rec_batchhead.stats_qty, 
		glob_rec_batchhead.for_debit_amt, 
		glob_rec_batchhead.for_credit_amt, 
		glob_rec_batchhead.com1_text, 
		glob_rec_batchhead.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G21a","input-batchhead") 
			CALL fgl_dialog_setkeylabel("ACCEPT","DETAILS") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_batchhead.jour_code = l_temp_text 
			END IF 
			NEXT FIELD jour_code 
					
		ON ACTION "LOOKUP" infield (currency_code) 
			LET l_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_batchhead.currency_code = l_temp_text 
			END IF 

			NEXT FIELD currency_code 


		BEFORE FIELD jour_code 
			IF glob_rec_batchhead.jour_num IS NOT NULL THEN 
				SELECT * INTO l_rec_journal.* 

				FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_batchhead.jour_code 

				DISPLAY l_rec_journal.desc_text TO journal.desc_text 

				NEXT FIELD year_num 
			END IF 

		AFTER FIELD jour_code 
			CLEAR journal.desc_text 

			SELECT * INTO l_rec_journal.* 
			FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = glob_rec_batchhead.jour_code 

			CASE 
				WHEN status = NOTFOUND 
					ERROR kandoomsg2("G",9029,"") #9029 " Journal NOT Found - Try Window"
					NEXT FIELD jour_code 

				WHEN l_rec_journal.gl_flag = "N" 
					ERROR kandoomsg2("G",7015,"") #G7015 " Journal Cannot be Entered - Refer Menu GZ2 "
					NEXT FIELD jour_code 

				OTHERWISE 
					DISPLAY l_rec_journal.desc_text TO journal.desc_text 

			END CASE 

			#added varrible to first fields after field block - in case the user presses accept (wants to continue with current data)
			#user also sees initialised fields/data

			#currency & rate_type_ind
			LET l_temp_text = NULL 
			IF glob_rec_batchhead.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_temp_text = glob_rec_batchhead.rate_type_ind 
			END IF 

			IF glob_rec_batchhead.currency_code IS NULL THEN 
				LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
			END IF 

			SELECT * INTO l_rec_currency.* 
			FROM currency 
			WHERE currency_code = glob_rec_batchhead.currency_code 

			CASE 
				WHEN glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
					LET glob_rec_batchhead.conv_qty = 1 
					LET glob_rec_batchhead.rate_type_ind = "B" 

					DISPLAY glob_rec_batchhead.rate_type_ind TO rate_type_ind 

				OTHERWISE 
					IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
						LET glob_rec_batchhead.rate_type_ind = "B" 
					END IF 

					CALL get_conv_rate( 
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_batchhead.currency_code, 
						today, 
						glob_rec_batchhead.rate_type_ind) 
					RETURNING glob_rec_batchhead.conv_qty 


			END CASE 

			DISPLAY l_rec_currency.desc_text TO currency.desc_text 

			DISPLAY glob_rec_batchhead.currency_code TO currency_code 
			DISPLAY glob_rec_batchhead.conv_qty TO conv_qty 
			DISPLAY glob_rec_batchhead.rate_type_ind TO rate_type_ind 

			IF glob_rec_batchhead.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_temp_text = glob_rec_batchhead.rate_type_ind 
			END IF 

			#control_qty
			IF glob_rec_batchhead.control_qty IS NULL THEN 
				LET glob_rec_batchhead.control_qty = 0 
			END IF 


			#conv_qty
			IF glob_rec_batchhead.conv_qty IS NULL OR glob_rec_batchhead.conv_qty = 0 THEN 
				IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
					LET glob_rec_batchhead.rate_type_ind = "B" 
				END IF 

				CALL get_conv_rate( 
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_batchhead.currency_code, 
					today, 
					glob_rec_batchhead.rate_type_ind) 
				RETURNING glob_rec_batchhead.conv_qty 

				DISPLAY glob_rec_batchhead.conv_qty TO conv_qty 
				DISPLAY glob_rec_batchhead.rate_type_ind TO rate_type_ind 
			END IF 

			#control_amt
			LET l_temp_text = NULL 
			IF glob_rec_glparms.control_tot_flag != "N" THEN 
				LET l_temp_text = glob_rec_batchhead.control_amt 
			END IF 

			IF glob_rec_batchhead.control_amt IS NULL OR glob_rec_batchhead.control_amt < 0 THEN 
				LET glob_rec_batchhead.control_amt = l_temp_text 
			END IF 

			# ------------------------------------------------------
			#HuHo - otherwise, user always has to click TWICE ACCEPT/APPLY
			--			NEXT FIELD year_num

		BEFORE FIELD currency_code 
			LET l_temp_text = NULL 
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD period_num 
				ELSE 
					NEXT FIELD control_qty 
				END IF 
			ELSE 
				LET l_temp_text = glob_rec_batchhead.currency_code 
			END IF 

		AFTER FIELD currency_code 
			CLEAR currency.desc_text 
			IF glob_rec_batchhead.currency_code IS NULL THEN 
				LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
			END IF 
			
			SELECT * INTO l_rec_currency.* 
			FROM currency 
			WHERE currency_code = glob_rec_batchhead.currency_code 

			CASE 
				WHEN status = NOTFOUND 
					ERROR kandoomsg2("G",9505,"") #9505" Currency NOT found, try window"
					NEXT FIELD currency_code 

				WHEN glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
					LET glob_rec_batchhead.conv_qty = 1 
					LET glob_rec_batchhead.rate_type_ind = "B" 

				OTHERWISE 
					IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
						LET glob_rec_batchhead.rate_type_ind = "B" 
					END IF 

					IF glob_rec_batchhead.currency_code != l_temp_text THEN 
						LET glob_rec_batchhead.conv_qty =	get_conv_rate(
							glob_rec_kandoouser.cmpy_code,
							glob_rec_batchhead.currency_code, 
							today,
							glob_rec_batchhead.rate_type_ind) 
					END IF 
			END CASE 

			DISPLAY l_rec_currency.desc_text TO currency.desc_text 

			DISPLAY glob_rec_batchhead.currency_code TO currency_code 
			DISPLAY glob_rec_batchhead.conv_qty TO conv_qty 
			DISPLAY glob_rec_batchhead.rate_type_ind TO rate_type_ind 

		BEFORE FIELD rate_type_ind 
			LET l_temp_text = NULL 

			IF glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD currency_code 
				ELSE 
					NEXT FIELD control_qty 
				END IF 
			ELSE 
				LET l_temp_text = glob_rec_batchhead.rate_type_ind 
			END IF 

		AFTER FIELD rate_type_ind 
			IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
				MESSAGE kandoomsg2("G",9047,"") #9047 A value must be entered FOR the Rate Type.
				NEXT FIELD rate_type_ind 
			ELSE 
				IF glob_rec_batchhead.rate_type_ind != l_temp_text THEN 
					LET glob_rec_batchhead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_batchhead.currency_code, 
						today,
						glob_rec_batchhead.rate_type_ind) 
					
					DISPLAY BY NAME glob_rec_batchhead.conv_qty 

				END IF 
			END IF 

		BEFORE FIELD conv_qty 
			LET l_temp_text = NULL 

			IF glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD currency_code 
				ELSE 
					NEXT FIELD control_qty 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_batchhead.conv_qty IS NULL OR glob_rec_batchhead.conv_qty = 0 THEN 
				IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
					LET glob_rec_batchhead.rate_type_ind = "B" 
				END IF 

				CALL get_conv_rate( 
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_batchhead.currency_code, 
					today, 
					glob_rec_batchhead.rate_type_ind) 
				RETURNING glob_rec_batchhead.conv_qty 

				DISPLAY glob_rec_batchhead.conv_qty TO conv_qty 
				DISPLAY glob_rec_batchhead.rate_type_ind TO rate_type_ind 
			END IF 

		BEFORE FIELD control_qty 
			LET l_temp_text = NULL 

			IF glob_rec_glparms.control_tot_flag = "N" THEN 
				MESSAGE "Control Totals disabled in GL Configuration"
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD conv_qty 
				ELSE 
					NEXT FIELD com1_text 
				END IF 
			END IF 

		AFTER FIELD control_qty 
			IF glob_rec_batchhead.control_qty IS NULL THEN 
				LET glob_rec_batchhead.control_qty = 0 
			END IF 

		BEFORE FIELD control_amt 
			LET l_temp_text = NULL 

			IF glob_rec_glparms.control_tot_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD conv_qty 
				ELSE 
					NEXT FIELD com1_text 
				END IF 
			ELSE 
				LET l_temp_text = glob_rec_batchhead.control_amt 
			END IF 

		AFTER FIELD control_amt 
			IF glob_rec_batchhead.control_amt IS NULL	OR glob_rec_batchhead.control_amt < 0 THEN 
				LET glob_rec_batchhead.control_amt = l_temp_text 
				MESSAGE kandoomsg2("G",9048,"") #G9048 " Control Amount must be greater than zero "
				NEXT FIELD control_amt 
			END IF 


		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num,
					LEDGER_TYPE_GL) 
				RETURNING 
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num, 
					l_invalid_period 

				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 

			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION G21_header()
############################################################


############################################################
# FUNCTION batch_lines_entry()  USED to be FUNCTION line_entry()
# Main differences are the array structure, no temp table and the sub-INPUT (from INPUT ARRAY) has been merged into the INPUT ARRAY
#
# This FUNCTION provides a black-box method of entering/editting
# disbursement lines.  The t_batchdetl table IS used as the common
# storage location FOR returning the entered lines TO the calling program.
#
# Bank lines must have a corresponding t_banking entry.
#
#
# Who wrote this ???
# Warning: this function is being replaced by the function batc
############################################################
FUNCTION batch_lines_entry() 
	DEFINE l_rec_batchdetl RECORD LIKE t_batchdetl.* 
	DEFINE l_rec_s_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_s_batchdetl_uom_code LIKE coa.uom_code 
	DEFINE l_arr_rec_batchdetl DYNAMIC ARRAY OF t_rec_batchdetl 

	# this record saves the contents of the current line
	DEFINE l_save_batchdetl t_rec_batchdetl 

	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_temp_text char(20) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE i,a SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_arrcurr SMALLINT 
--	DEFINE l_scrline SMALLINT 
	DEFINE l_row_exists boolean 
	DEFINE l_disburse_ind SMALLINT 
	DEFINE l_feature_ind SMALLINT 
	DEFINE l_valid_tran LIKE language.yes_flag 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_desc_text LIKE batchdetl.desc_text 
	DEFINE l_ref_text LIKE batchdetl.ref_text 
	DEFINE l_anal_text LIKE batchdetl.analysis_text 
	DEFINE l_error_num INTEGER 
	--	DEFINE l_row_was_deleted BOOLEAN #when a row is deleted, AFTER row/field validation should not be processed

	#Balanced and none-balanced warning message
	LET modu_balanced_text[1] = "Journal Line Items are balanced" 
	LET modu_balanced_text[2] = "Journal Line Items are NOT balanced" 

	--	LET l_row_was_deleted = FALSE #default

	SELECT cash_book_flag 
	INTO glob_rec_glparms.cash_book_flag 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	# IF the cash book application is installed/enabled, it MUST not use GL Bank Acccounts
	IF glob_rec_glparms.cash_book_flag = "Y" THEN 
		LET glob_fv_cash_book = "1" 
	ELSE 
		LET glob_fv_cash_book = "2" 
	END IF 

	CASE get_kandoooption_feature_state('GL','MS') 
		WHEN 'A' 
			LET glob_desc_ind = "1" 
		WHEN 'D' 
			LET glob_desc_ind = "2" 
		WHEN 'H' 
			LET glob_desc_ind = "3" 
		OTHERWISE 
			LET glob_desc_ind = "1" 
	END CASE 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2, 
	INPUT no wrap 

	DISPLAY glob_rec_batchhead.jour_code TO batchhead.jour_code 
	DISPLAY glob_rec_batchhead.jour_num TO batchhead.jour_num 
	DISPLAY glob_rec_batchhead.jour_date TO batchhead.jour_date 

	IF glob_rec_batchhead.jour_num IS NULL THEN #new batch NOT saved yet 
		DISPLAY "<New Batch>" TO lb_batch_state #display information ON the batch state (it's a new batch)
		#Eric, this label (not a text field) did/does exist in G114. I have now renambed it to lb_batch_state to clarify it's purpose
		-- ERROR "lb_batch_state does not exit in the form, please check form and code"
		-- ericv 20200723 field does not exist DISPLAY "<New Batch>" TO lb_batch_state #display information ON the batch state (it's a new batch) 
	END IF 

	LET l_temp_text = kandooword("batchhead.desc_ind",glob_desc_ind) 
	DISPLAY l_temp_text TO desc_mode 

	#This is shit... sorry to say this.. lazy but expensive approach of displaying the same string to 2 labels
	DISPLAY glob_rec_batchhead.currency_code TO sr_currency[1].* 
	DISPLAY glob_rec_batchhead.currency_code TO sr_currency[2].* 

	IF glob_rec_batchhead.seq_num < 20 THEN 
		## Dont bother user FOR criteria on small batches OR WHEN adding new
		## batches.  Drives those with only 6-10 line batches crazy.
		# erve = ??????
		LET l_where_text = "1=1" 
	ELSE 
		MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT l_where_text ON 
			seq_num, 
			acct_code, 
			analysis_text, 
			for_debit_amt, 
			for_credit_amt, 
			stats_qty, 
			ref_text, 
			desc_text 
		FROM 
			batchdetl.seq_num, 
			batchdetl.acct_code, 
			batchdetl.analysis_text, 
			batchdetl.for_debit_amt, 
			batchdetl.for_credit_amt, 
			batchdetl.stats_qty, 
			batchdetl.ref_text, 
			batchdetl.desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G21a","construct-batchdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	END IF 

	IF NOT ( int_flag OR quit_flag ) THEN 
		LET l_query_text = 
			"SELECT b.seq_num, ", 
			"b.acct_code, ", 
			----- misssing G/L Account Desription
			"b.analysis_text,", 
			"b.for_debit_amt,", 
			"b.for_credit_amt,", 
			"b.stats_qty,", 
			"c.uom_code,", 
			"b.ref_text,", 
			"b.desc_text ", 
			" FROM t_batchdetl b, ", 
			" OUTER coa c", 
			" WHERE b.acct_code = c.acct_code ", 
			" AND b.cmpy_code = c.cmpy_code AND ", 
			l_where_text clipped, 
			" AND b.username = ","'",glob_rec_kandoouser.sign_on_code clipped, 
			"'"," ORDER BY b.seq_num" 
	END IF 

	------------------------------------------------------------ WHILE -----------------
	WHILE not(int_flag OR quit_flag) 
		MESSAGE kandoomsg2("U",1002,"") #1002 Searching database;  Please wait.
		LET l_idx = 0 

		LET l_idx = 1 
		# look in the 'uncompleted batches personal tank' if there is some batch
		CALL l_arr_rec_batchdetl.clear()
		CALL retrieve_unsaved_batch (l_query_text,false) RETURNING l_arr_rec_batchdetl 

		LET l_disburse_ind = false 
		LET l_feature_ind = get_kandoooption_feature_state("GL","GL") 
		# 1  = DISPLAY of default acct IS required OR kandoooption NOT setup..
		# 2 = No default account will be displayed..

		MESSAGE kandoomsg2("G",1029,"") #NEW Batch NOT Edit #1029 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse
		INPUT ARRAY l_arr_rec_batchdetl WITHOUT DEFAULTS FROM sr_batchdetl_v2.* attributes(unbuffered,delete ROW = true, INSERT row=false,append ROW = true, auto append = true ) #works with append !!!! you NEED TO have a toolbar button 
		-- ATTRIBUTES(UNBUFFERED,delete row = true, auto append = false, insert row=falsaaaae) #works with APPEND !!!! you need to have a toolbar button
		--		attributes(unbuffered,delete ROW = true, INSERT row=false,append ROW = true, auto append = true ) #works with append !!!! you NEED TO have a toolbar button
			BEFORE INPUT 
				--				CALL display_batch_balance(l_arr_rec_batchdetl)
				LET l_temp_text = kandooword("batchhead.desc_ind",glob_desc_ind) 
				DISPLAY l_temp_text TO desc_mode #operation mode ?
		
				CALL publish_toolbar("kandoo","G21a","input-arr-batchdetl") 
				CALL disp_total() #details in balance groupbox i.e. total debit etc.. 
				CALL display_batch_balance(l_arr_rec_batchdetl) #display/validate batch IF it's balanced 
		
				IF glob_rec_glparms.control_tot_flag != "N" THEN #control amount IS disabled in configuration program 
					DISPLAY true TO cb_control_amount_switch 
				ELSE 
					DISPLAY false TO cb_control_amount_switch 
				END IF 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (acct_code) --lookup 
				LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_temp_text,glob_fv_cash_book,"N") THEN 
					MESSAGE kandoomsg2("G",9202,"") #9202 Subsidiary Ledger Control Accounts can NOT be used.
					LET l_disburse_ind = true 
					EXIT INPUT 
				END IF 

				IF (glob_rec_batchhead.source_ind = "P"	OR glob_rec_batchhead.source_ind = "R")	AND l_temp_text IS NOT NULL THEN 
					SELECT unique(1) 
					FROM fundsapproved 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = l_temp_text 
					IF status != NOTFOUND THEN 
						IF l_temp_text != l_rec_batchdetl.acct_code THEN 
							ERROR kandoomsg2("G",9604,"") #9604 Cannot edit capital account code.
						ELSE 
							ERROR kandoomsg2("G",9605,"") #9605 Cannot add capital account code.
						END IF 
						LET l_temp_text = NULL 
					END IF 
				END IF 

				IF l_temp_text IS NOT NULL THEN 
					LET l_arr_rec_batchdetl[l_idx].acct_code = l_temp_text 
					NEXT FIELD acct_code 
				END IF 
				#END IF


			#input-arr-batchdetl F9 Description +1 ic_switch_camera_24px.svg
			ON ACTION "DESC_IND+" --ON KEY (f9) --change glob_desc_ind ?? toggle description 1-3 
				CASE glob_desc_ind 
					WHEN "1" 
						LET glob_desc_ind = "2" 
					WHEN "2" 
						LET glob_desc_ind = "3" 
					OTHERWISE 
						LET glob_desc_ind = "1" 
				END CASE 

				LET l_temp_text = kandooword("batchhead.desc_ind",glob_desc_ind) 
				DISPLAY l_temp_text TO desc_mode 

			#input-arr-batchdetl F10 Disburse=True ic_add_circle_outline_24px.svg 23
			ON ACTION "DISBURSE" --ON KEY (f10) --disburse 
				IF enter_disburse() THEN 
					LET l_disburse_ind = true 
					EXIT INPUT 
				END IF 

				# --------------------------------------------------------------------------------------------
			BEFORE ROW 
				#  erve 2019-10-26 always set l_arrcurr and l_scrline at before row,
				# use those variables and not any SMALLINT
				LET l_arrcurr = arr_curr() 
				--LET l_scrline = scr_line() 

				--IF glob_rec_batchhead.control_amt IS NULL THEN LET glob_rec_batchhead.control_amt = 0 END IF

				# ----------------------------- Cashbook special GC1 and GC2
				--				IF not acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr].acct_code,glob_fv_cash_book,"N") THEN
				--					ERROR kandoomsg2("G",9056,"")
				--					LET l_disburse_ind = true
				--added for GC1/GC2
				--					IF l_arrcurr < 2 THEN  #Row 1 is reserved as it is the static/single side of the balance
				--						NEXT FIELD sr_batchdetl_v2[2].acct_code
				--					END IF

				--				END IF
				# ----------------------------


				# check if row existed in t_batchdetl
				IF l_arr_rec_batchdetl.getlength() > 0 THEN 
					SELECT 1 
					INTO l_row_exists 
					FROM t_batchdetl 
					WHERE username = glob_rec_kandoouser.sign_on_code 
					AND seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num 
					IF sqlca.sqlcode = 100 THEN 
						LET l_row_exists = false 
						INITIALIZE l_rec_batchdetl.* TO NULL #do we really NEED TO do this over AND over again ? 
						INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL 
						LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_arrcurr 

						#To make sure, we don'T get NULL in decimal columns
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 END IF 
							IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 END IF 
								IF l_arr_rec_batchdetl[l_arrcurr].stats_qty IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 END IF 

								ELSE 
									# save the current element's contents
									LET l_save_batchdetl.* = l_arr_rec_batchdetl[l_arrcurr].* 
									LET l_rec_s_batchdetl.* = l_rec_batchdetl.* 
									LET l_rec_s_batchdetl_uom_code = l_arr_rec_batchdetl[l_arrcurr].uom_code 

								END IF 
								IF l_row_exists = false THEN 
									# if row does not exist, set max (existing rows+1)
									SELECT nvl(max(seq_num) ,0)+1 
									INTO l_arr_rec_batchdetl[l_arrcurr].seq_num 
									FROM t_batchdetl 
									WHERE username = glob_rec_kandoouser.sign_on_code 
									--					DISPLAY BY NAME l_arr_rec_batchdetl[l_arrcurr].seq_num
								END IF 
								-----------------------
								-- NEXT FIELD scroll_flag
								--					NEXT FIELD acct_code #I think this breaks the usage flow as any field row navigation (mouse) stops at the account field
							END IF #check IF ARRAY IS NOT empty 


							# -------------------------------------------------------------------------------- INSERT
			BEFORE INSERT #note! we only allow append 
				LET l_arrcurr = arr_curr() 
--				LET l_scrline = scr_line() 
				--				LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num + 1

				INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL 
				INITIALIZE l_rec_batchdetl.* TO NULL 
				INITIALIZE l_rec_s_batchdetl.* TO NULL 

				#To make sure, we don'T get NULL in decimal columns
				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 END IF 
					IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 END IF 
						IF l_arr_rec_batchdetl[l_arrcurr].stats_qty IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 END IF 
							IF l_rec_batchdetl.for_debit_amt IS NULL THEN LET l_rec_batchdetl.for_debit_amt = 0 END IF 
								IF l_rec_batchdetl.for_credit_amt IS NULL THEN LET l_rec_batchdetl.for_credit_amt = 0 END IF 
									IF l_rec_batchdetl.stats_qty IS NULL THEN LET l_rec_batchdetl.stats_qty = 0 END IF 

										#Add incrementing seq_num for each row
										CASE 
											WHEN l_arrcurr = 0 

											WHEN l_arrcurr = 1 
												LET l_arr_rec_batchdetl[l_arrcurr].seq_num = 1 

											WHEN l_arrcurr > 1 
												LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_arr_rec_batchdetl[l_arrcurr-1].seq_num + 1 
										END CASE 

										#HuHo 17.12.2019: User can add multiple new/empty rows.. we need to prevent this
										IF l_arrcurr > 1 THEN #more than one line 
											IF (l_arr_rec_batchdetl[l_arrcurr-1].for_debit_amt = 0) AND (l_arr_rec_batchdetl[l_arrcurr-1].for_credit_amt = 0) THEN 
												ERROR "Complete the current line before you append a new line" 
												NEXT FIELD scroll_flag 
											END IF 
										END IF 

										IF l_feature_ind = 1 AND l_arrcurr > 1 THEN 
											IF acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr-1].acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
												##
												## Only default account TO the above line if
												## 1. Max option IS turned on
												## 2. There IS an above line
												## 3. Above line IS NOT a control account
												##
												LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_arr_rec_batchdetl[l_arrcurr-1].acct_code 
											END IF 
										END IF 
										##
										## A minor Informix problem exists WHERE WHEN pressing delete
										## on last line actually performs a delete AND an INSERT. To
										## avoid this the following check IS included.
										##
										IF fgl_lastkey() = fgl_keyval("delete") 
										OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
											# INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
											NEXT FIELD scroll_flag 
										ELSE 
											NEXT FIELD acct_code 
										END IF 

										# -------------------------------------------------------------------------------- AFTER INSERT
			AFTER INSERT 
				CALL display_batch_balance(l_arr_rec_batchdetl) 

				# -------------------------------------------------------------------------------- DELETE
			BEFORE DELETE 
				LET l_arrcurr = arr_curr() 

				-- IF not acct_type(glob_rec_kandoouser.cmpy_code,l_rec_batchdetl.acct_code,glob_fv_cash_book,"N") THEN
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr].acct_code,glob_fv_cash_book,"N") THEN 
					MESSAGE kandoomsg2("G",9056,"") 
					LET l_disburse_ind = true 
					--added for GC1/GC2
					IF l_arrcurr < 2 THEN #row 1 IS reserved as it IS the static/single side OF the balance 
						EXIT INPUT --next FIELD previous --next FIELD sr_batchdetl_v2[1].acct_code 
					END IF 

					EXIT INPUT 
				ELSE 
					DELETE FROM t_batchdetl 
					WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num 
					AND username = glob_rec_kandoouser.sign_on_code 
					CALL disp_total() 
					CALL display_batch_balance(l_arr_rec_batchdetl) #display/validate batch IF it's balanced 

					# INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD scroll_flag #first FIELD in INPUT ARRAY 
				LET a = 1 

			BEFORE FIELD acct_code 
				# What can we do before we know acct_code value ?

				# -------------------------------------------------------------------------------- AFTER FIELD acct_code
			AFTER FIELD acct_code 
				IF l_arr_rec_batchdetl[l_arrcurr].acct_code IS NULL THEN #gl account code IS empty 
					--					DISPLAY fgl_lastaction()
					--					IF fgl_lastkey() = fgl_keyval("accept") THEN
					IF fgl_lastaction() = "accept" THEN 

						LET modu_dbg_accept = true #huho this line will be never be processed... i move it TO the line BEFORE EXIT INPUT 
						EXIT INPUT #@temptest 
						--						LET modu_dbg_accept = true  #HuHo This line will be NEVER be processed... I move it to the line before EXIT INPUT
					ELSE 
						IF get_debug() THEN 
							DISPLAY "--------------------------------------" 
							DISPLAY "Last key=", fgl_lastkey() 
							DISPLAY "Last key name =", fgl_keyname(fgl_lastkey()) 
							DISPLAY "Last key=", fgl_lastkey() 
							DISPLAY "last key", fgl_keyname(fgl_lastkey()) -- fgl_lastkey(fgl_keyname()) 
							DISPLAY "last action", fgl_lastaction() 
							DISPLAY "Array Size=", l_arr_rec_batchdetl.getsize() 
							DISPLAY "l_arrcurr=", l_arrcurr 
							DISPLAY "--------------------------------------" 
						END IF 

						#IF/When user navigates back -> would move to previous row
						IF fgl_lastkey() = fgl_keyval("UP") OR fgl_lastkey() = fgl_keyval("left") THEN 
							--THEN
							IF t_batchdetl_can_row_get_removed(l_arr_rec_batchdetl[l_arrcurr].*) THEN 
								CALL l_arr_rec_batchdetl.deleteelement(l_arrcurr) 
								LET l_arrcurr = arr_curr() 

								IF get_debug() THEN 
									DISPLAY "--------------------------------------" 
									DISPLAY "Array Size=", l_arr_rec_batchdetl.getsize() 
									DISPLAY "l_arrcurr=", l_arrcurr 
									DISPLAY "--------------------------------------" 
								END IF 

								--								LET l_row_was_deleted = TRUE
							END IF 

						ELSE 
							ERROR kandoomsg2("G",9032,"") #9032 Account must be entered;  Try Window.
							NEXT FIELD acct_code 
						END IF 
					END IF 
				END IF 

				--IF l_row_was_deleted = FALSE THEN
				#Verify if GL account code is valid
				#We need to check again, in case row was deleted -if it was deleted, no further validation needs to be done
				IF get_debug() THEN 
					DISPLAY "--------------------------------------" 
					DISPLAY "Array Size=", l_arr_rec_batchdetl.getsize() 
					DISPLAY "l_arrcurr=", l_arrcurr 
					DISPLAY "--------------------------------------" 
				END IF 

				IF l_arrcurr <= l_arr_rec_batchdetl.getsize() THEN 

					CALL verify_acct_code(
						glob_rec_kandoouser.cmpy_code, 
						l_arr_rec_batchdetl[l_arrcurr].acct_code, 
						glob_rec_batchhead.year_num, 
						glob_rec_batchhead.period_num) 
					RETURNING l_rec_coa.* 

					IF l_rec_coa.acct_code IS NULL THEN 
						NEXT FIELD acct_code 
					ELSE 
						LET l_arr_rec_batchdetl[l_idx].uom_code = l_rec_coa.uom_code 
						--DISPLAY BY NAME l_arr_rec_batchdetl[l_idx].uom_code  #HuHo we work in unbuffered input mode
					END IF 

					IF l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_coa.acct_code THEN 
						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_coa.acct_code 
						NEXT FIELD acct_code 
					END IF 

-- #TODO Hubert asked to comment it)) KD-2271
--					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,glob_fv_cash_book,"Y") THEN 
--						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = NULL 
--						NEXT FIELD acct_code 
--					END IF 

					# Cannot add OR edit account code FOR purchase ORDER
					# OR voucher.
					-- IF (l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_batchdetl.acct_code
					--IF (l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
					--AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0)
					--AND (glob_rec_batchhead.source_ind = "P"
					--OR glob_rec_batchhead.source_ind = "R") THEN
					--SELECT unique(1)
					--FROM fundsapproved
					--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					--AND acct_code = l_arr_rec_batchdetl[l_arrcurr].acct_code
					--IF status != NOTFOUND THEN
					--IF l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_batchdetl.acct_code THEN
					--ERROR kandoomsg2("G",9604,"")	#9604 Cannot edit capital account code.
					--ELSE
					--ERROR kandoomsg2("G",9605,"")	#9605 Cannot add capital account code.
					--END IF
					--LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_batchdetl.acct_code
					--NEXT FIELD acct_code
					--END IF

					-- { erve 2019-10-26 get rid of usage of l_rec_batchdetl
					-- IF (l_rec_batchdetl.acct_code is null) OR (l_rec_batchdetl.acct_code != l_rec_coa.acct_code) THEN

					IF (l_arr_rec_batchdetl[l_arrcurr].acct_code IS null) OR (l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_coa.acct_code) THEN 
						CALL read_coa(l_rec_coa.acct_code,glob_desc_ind, l_idx) 
						RETURNING 
							l_arr_rec_batchdetl[l_arrcurr].desc_text, 
							l_rec_batchdetl.ref_text, 
							l_arr_rec_batchdetl[l_arrcurr].analysis_text 
					END IF 
					LET l_rec_batchdetl.acct_code = l_rec_coa.acct_code 

				END IF #end OF CHECK IF l_arrcurr <= l_arr_rec_batchdetl.getsize() THEN 

				# erve 2019-10-26 to be checked after ....
				--IF l_rec_coa.uom_code is null THEN
				--LET l_arr_rec_batchdetl[l_arrcurr].uom_code = null
				--LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = null
				--ELSE
				--LET l_arr_rec_batchdetl[l_arrcurr].uom_code = l_rec_coa.uom_code
				--END IF

				--IF l_rec_coa.uom_code is not null
				--AND l_arr_rec_batchdetl[l_arrcurr].stats_qty is null THEN
				--LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
				--END IF

				# DISPLAY l_arr_rec_batchdetl[l_arrcurr].stats_qty,
				#         l_arr_rec_batchdetl[l_arrcurr].uom_code
				#      TO sr_batchdetl[scrn].stats_qty,
				#         sr_batchdetl[scrn].uom_code

				--CALL display_batch_balance()
				--CASE
				--WHEN fgl_lastkey() = fgl_keyval("accept")
				--IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
				--AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
				--AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
				--OR l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
				--ERROR kandoomsg2("G",9044,"")			#G9044 " Amount must be positive "
				--NEXT FIELD acct_code
				--END IF

				--IF l_rec_batchdetl.analysis_text is null
				--AND l_rec_coa.analy_req_flag = "Y" THEN
				--ERROR kandoomsg2("P",9016,"")				#9016 " Analysis IS required "
				--NEXT FIELD uom_code
				--ELSE
				--NEXT FIELD scroll_flag
				--END IF

				--WHEN fgl_lastkey() = fgl_keyval("RETURN") #huho .. we NEED TO get away FROM legacy navigation
				--OR fgl_lastkey() = fgl_keyval("right")
				--OR fgl_lastkey() = fgl_keyval("tab")
				--OR fgl_lastkey() = fgl_keyval("down")
				--NEXT FIELD NEXT

				--WHEN fgl_lastkey() = fgl_keyval("left")
				--OR fgl_lastkey() = fgl_keyval("up")
				--IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
				--AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
				--AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 OR
				--l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
				--ERROR kandoomsg2("G",9044,"")				#G9044 " Amount must be positive "
				--NEXT FIELD acct_code
				--END IF

				--IF l_rec_batchdetl.analysis_text is null
				--AND l_rec_coa.analy_req_flag = "Y" THEN
				--ERROR kandoomsg2("P",9016,"")			#9016 " Analysis IS required "
				--NEXT FIELD uom_code
				--END IF
				--NEXT FIELD scroll_flag
				--OTHERWISE
				--NEXT FIELD acct_code
				--END CASE

				--END IF #end IF FROM the initial right, tab, enter KEY condition

				--			END IF #end of IF row_was_deleted

			BEFORE FIELD analysis_text 
				-- DISPLAY "BEFORE FIELD analysis_text"

				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_arr_rec_batchdetl[l_arrcurr].acct_code 
				IF l_rec_coa.analy_prompt_text IS NULL THEN 
					LET l_rec_coa.analy_prompt_text = kandooword("Analysis",1) 
				END IF 

				LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"................" 
				LET l_arr_rec_batchdetl[l_arrcurr].analysis_text = l_temp_text 

				--	DISPLAY l_rec_coa.analy_prompt_text TO coa.analy_prompt_text
				# -------------------------------------------------------------------------------- AFTER FIELD for_debit_amt

			AFTER FIELD analysis_text 
				-- DISPLAY "AFTER FIELD analysis_text" 				#--------------------------
				IF l_arr_rec_batchdetl[l_arrcurr].analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					#9016 Analysis IS required.
					MESSAGE kandoomsg2("G",9016,"") #RETURN 9016 #huho return 9016 ??? what is this now
					NEXT FIELD analysis_text 
				END IF 

			BEFORE FIELD for_debit_amt 
				# Nothing
				# -------------------------------------------------------------------------------- AFTER FIELD for_debit_amt
			AFTER FIELD for_debit_amt 
				#Requested by Anna - only debit or credit
				--				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 END IF
				--				IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 END IF
				--				IF l_arr_rec_batchdetl[l_arrcurr].stats_qty IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 END IF

				IF l_arr_rec_batchdetl[l_arrcurr].acct_code IS NOT NULL THEN #don't do anything WITHOUT an account 

					LET l_error_num = batch_line_validation(l_arr_rec_batchdetl[l_arrcurr].*,l_rec_coa.analy_req_flag,1) 
					IF l_error_num THEN 
						CASE l_error_num 
							WHEN 9016 
								--							LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
								ERROR "Analysis Text is required" 
								NEXT FIELD analysis_text 
						END CASE 

						MESSAGE kandoomsg2("G",l_error_num,"") 
						LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 
					END IF 

					IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN 
						LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 
						DISPLAY BY NAME l_arr_rec_batchdetl[l_arrcurr].for_debit_amt 
					ELSE 
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt > 0 THEN 
							LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 
							DISPLAY BY NAME l_arr_rec_batchdetl[l_arrcurr].for_credit_amt 
							--NEXT FIELD stats_qty
						END IF 
					END IF 

					IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0 AND glob_rec_batchhead.source_ind NOT matches "[PR]" THEN 
						CALL check_funds(glob_rec_kandoouser.cmpy_code, 
						l_arr_rec_batchdetl[l_arrcurr].acct_code, 
						l_arr_rec_batchdetl[l_arrcurr].for_debit_amt, 
						l_arr_rec_batchdetl[l_arrcurr].seq_num, 
						glob_rec_batchhead.year_num, 
						glob_rec_batchhead.period_num, 
						"G", 
						glob_rec_batchhead.jour_num, 
						"Y") 
						RETURNING l_valid_tran, l_available_amt 
						MESSAGE kandoomsg2("G",1029,"") #1029 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse

						IF NOT l_valid_tran THEN 
							NEXT FIELD acct_code 
						END IF 
					END IF 

					CALL display_batch_balance(l_arr_rec_batchdetl) 

				END IF #end OF check,if we have actually an account 

				# -------------------------------------------------------------------------------- AFTER FIELD for_credit_amt
			AFTER FIELD for_credit_amt 
				#Requested by Anna - only debit or credit
				--				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 END IF
				--				IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 END IF
				--				IF l_arr_rec_batchdetl[l_arrcurr].stats_qty IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 END IF

				IF l_arr_rec_batchdetl[l_arrcurr].acct_code IS NOT NULL THEN #only do something IF we have an account 

					LET l_error_num = batch_line_validation (l_arr_rec_batchdetl[l_arrcurr].*,l_rec_coa.analy_req_flag,1) 
					IF l_error_num THEN 
						CASE l_error_num 
							WHEN 9016 
								LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 
								ERROR "Analysis Text is required" 
								NEXT FIELD analysis_text 
						END CASE 

						MESSAGE kandoomsg2("G",l_error_num,"") 
						LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 
						--					NEXT FIELD for_debit_amt

					ELSE 

						IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN 
							LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 
							DISPLAY BY NAME l_arr_rec_batchdetl[l_arrcurr].for_credit_amt 
						END IF 

						CALL display_batch_balance(l_arr_rec_batchdetl) 
					END IF 

				END IF #end OF check,if we have actually an account 


				# -------------------------------------------------------------------------------- BEFORE FIELD stats_qty
			BEFORE FIELD stats_qty 
				IF l_arr_rec_batchdetl[l_arrcurr].uom_code IS NULL THEN 
					NEXT FIELD ref_text 
				END IF 

				# -------------------------------------------------------------------------------- AFTER FIELD stats_qty
			AFTER FIELD stats_qty 
				LET l_error_num = batch_line_validation (l_arr_rec_batchdetl[l_arrcurr].*,l_rec_coa.analy_req_flag,1) 
				IF l_error_num THEN 
					MESSAGE kandoomsg2("G",l_error_num,"") 
					LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 
					NEXT FIELD for_debit_amt 
				END IF 

			BEFORE FIELD ref_text 
				-- "BEFORE FIELD ref_text"

			AFTER FIELD ref_text 
				--DISPLAY "BEFORE FIELD ref_text"

			BEFORE FIELD desc_text 
				--DISPLAY "BEFORE FIELD desc_text"

			AFTER FIELD desc_text 
				--DISPLAY "AFTER FIELD desc_text"

				#---------------------------------------------------------------------------------- AFTER ROW
			AFTER ROW 
				IF get_debug() THEN 
					DISPLAY "AFTER ROW -----------------------------------------------------------" 
					DISPLAY "l_arr_rec_batchdetl.getlength()=", l_arr_rec_batchdetl.getlength() 
					DISPLAY "l_arrcurr=", l_arrcurr 
					DISPLAY "l_arr_rec_batchdetl[l_arrcurr].acct_code=", l_arr_rec_batchdetl[l_arrcurr].acct_code 
					DISPLAY " -----------------------------------------------------------" 
				END IF 

				#Delete row if it qualifies to be deleted (i.e. user creates a new row but navigates instantly away
				IF t_batchdetl_can_row_get_removed(l_arr_rec_batchdetl[l_arrcurr].*) THEN 
					CALL l_arr_rec_batchdetl.deleteelement(l_arrcurr) 
					--						LET l_row_was_deleted = TRUE
				ELSE 
					--				IF ((l_arr_rec_batchdetl.getLength() > 0) AND (l_row_was_deleted = FALSE) AND (l_arr_rec_batchdetl[l_arrcurr].acct_code IS NOT NULL)) THEN #all array elements / rows could be deleted
					IF ((l_arr_rec_batchdetl.getlength() > 0) 
					--AND (l_arr_rec_batchdetl.getlength() <= l_arrcurr) #Commented due to a feature request by Anna - wish to modify header row 
					AND (l_arr_rec_batchdetl[l_arrcurr].acct_code IS NOT null)) THEN #all ARRAY elements / ROWS could be deleted 
						#Validate current row / batch line
						LET l_error_num = batch_line_validation (l_arr_rec_batchdetl[l_arrcurr].*,l_rec_coa.analy_req_flag,3) 

							CALL display_batch_balance(l_arr_rec_batchdetl) #huho, trying TO CALL the balanced CHECK FUNCTION FOR user feedback 

						IF l_error_num THEN
							CALL fgl_winmessage("Error",kandoomsg2("G",l_error_num,"") ,"ERROR") 
							MESSAGE kandoomsg2("G",l_error_num,"") 
							--LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0  #27.11.2020 have to comment this as it does not work correctly 
							NEXT FIELD acct_code #huho 27.11.2020 - changed to acct_code from for_debit_amt 
							--CALL fgl_dialog_setcurrline(l_arrcurr,l_scrline) 
						END IF 

						#UPDATE Batch LINE TO temp table
						--				CALL display_batch_balance(l_arr_rec_batchdetl)   #HuHo, do we need this again ? trying to call the balanced check function for user feedback
						IF field_touched(sr_batchdetl_v2.*) THEN 
							IF l_row_exists THEN 
								UPDATE t_batchdetl 
								SET (
									acct_code, 
									analysis_text, 
									for_debit_amt, 
									for_credit_amt, 
									stats_qty, 
									ref_text, 
									desc_text) 
								= (
									l_arr_rec_batchdetl[l_arrcurr].acct_code, 
									l_arr_rec_batchdetl[l_arrcurr].analysis_text, 
									l_arr_rec_batchdetl[l_arrcurr].for_debit_amt, 
									l_arr_rec_batchdetl[l_arrcurr].for_credit_amt, 
									l_arr_rec_batchdetl[l_arrcurr].stats_qty, 
									l_arr_rec_batchdetl[l_arrcurr].ref_text, 
									l_arr_rec_batchdetl[l_arrcurr].desc_text	)									 
								WHERE username = glob_rec_kandoouser.sign_on_code 
								AND seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num 
								IF sqlca.sqlerrd[3] != 1 THEN 
									CALL fgl_winmessage("Update Failed","Could not update this row, returning","ERROR") 
									NEXT FIELD acct_code 
								END IF 
							ELSE 
								IF get_debug() THEN 
									DISPLAY "INSERT 1 t_batchdetl -----------------------------------------------------------" 
									DISPLAY "cmpy_code=", glob_rec_batchhead.cmpy_code 
									DISPLAY "seq_num=", l_arr_rec_batchdetl[l_arrcurr].seq_num 
									DISPLAY "acct_code=", l_arr_rec_batchdetl[l_arrcurr].acct_code 
									DISPLAY "analysis_text=", l_arr_rec_batchdetl[l_arrcurr].analysis_text 
									DISPLAY "for_debit_amt=", l_arr_rec_batchdetl[l_arrcurr].for_debit_amt 
									DISPLAY "for_credit_amt=", l_arr_rec_batchdetl[l_arrcurr].for_credit_amt 
									DISPLAY "stats_qty=", l_arr_rec_batchdetl[l_arrcurr].stats_qty 
									DISPLAY "ref_text=", l_arr_rec_batchdetl[l_arrcurr].ref_text 
									DISPLAY "desc_text=", l_arr_rec_batchdetl[l_arrcurr].desc_text 

									DISPLAY "jour_code=", glob_rec_batchhead.jour_code 
									DISPLAY "sign_on_code=", glob_rec_kandoouser.sign_on_code 
								END IF 

								#To make sure, we don'T get NULL in decimal columns
								IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 END IF 
									IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0 END IF 
										IF l_arr_rec_batchdetl[l_arrcurr].stats_qty IS NULL THEN LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 END IF 
											--IF glob_rec_batchhead.control_amt IS NULL THEN LET glob_rec_batchhead.control_amt = 0 END IF
											INSERT INTO t_batchdetl (
												cmpy_code, 
												seq_num, 
												acct_code, 
												analysis_text, 
												for_debit_amt, 
												for_credit_amt, 
												stats_qty, 
												ref_text, 
												desc_text, 
												jour_code, 
												username ) 
											VALUES (
												glob_rec_batchhead.cmpy_code, 
												l_arr_rec_batchdetl[l_arrcurr].seq_num, 
												l_arr_rec_batchdetl[l_arrcurr].acct_code, 
												l_arr_rec_batchdetl[l_arrcurr].analysis_text, 
												l_arr_rec_batchdetl[l_arrcurr].for_debit_amt, 
												l_arr_rec_batchdetl[l_arrcurr].for_credit_amt, 
												l_arr_rec_batchdetl[l_arrcurr].stats_qty, 
												l_arr_rec_batchdetl[l_arrcurr].ref_text, 
												l_arr_rec_batchdetl[l_arrcurr].desc_text, 
												glob_rec_batchhead.jour_code, 
												glob_rec_kandoouser.sign_on_code) 

											IF sqlca.sqlcode != 0 THEN 
												ERROR "Could not insert this row, returning" 
												NEXT FIELD acct_code 
											END IF 
										END IF 
									END IF 

								ELSE 
									--					LET l_row_was_deleted = FALSE
								END IF #if condition TO check, IF the ARRAY has at least one element / ROW 

							END IF 

				
			AFTER INPUT 
				#DEL & ESC go back TO scroll_flag IF CURSOR NOT on scroll_flag
				#				IF fgl_lastkey() = fgl_keyval("accept") THEN  @ErVe
				#					LET modu_dbg_accept = true
				#				ELSE
				#					LET modu_dbg_accept = false
				#				END IF
				IF int_flag OR quit_flag THEN 
					--IF not infield(scroll_flag) AND l_idx > 0 THEN
					LET int_flag = false 
					LET quit_flag = false 
					--DELETE FROM t_batchdetl
					--WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
					--IF l_rec_s_batchdetl.acct_code is not null THEN
					--LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_rec_s_batchdetl.seq_num
					--LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_s_batchdetl.acct_code
					--LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt= l_rec_s_batchdetl.for_debit_amt
					--LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt= l_rec_s_batchdetl.for_credit_amt
					--LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = l_rec_s_batchdetl.stats_qty
					--LET l_arr_rec_batchdetl[l_arrcurr].uom_code = l_rec_s_batchdetl_uom_code
					#DISPLAY l_arr_rec_batchdetl[l_arrcurr].* TO sr_batchdetl[scrn].*
					--INSERT INTO t_batchdetl values(l_rec_s_batchdetl.*)
					--ELSE
					--FOR i = arr_curr() TO arr_count()
					--IF l_arr_rec_batchdetl[i+1].acct_code is not null THEN
					--LET l_arr_rec_batchdetl[i].* = l_arr_rec_batchdetl[i+1].*
					--ELSE
					--INITIALIZE l_arr_rec_batchdetl[i].* TO null
					--END IF
					#IF scrn <= 7 THEN
					#   DISPLAY l_arr_rec_batchdetl[i].* TO sr_batchdetl[scrn].*
					#
					#   LET scrn = scrn + 1
					#END IF
					--END FOR
					#LET scrn = scr_line()
					--END IF
					CALL display_batch_balance(l_arr_rec_batchdetl) 
					#User presses Cancel BUT it would still show the none-finished row (last row) - let's delete it
					--						IF (l_arr_rec_batchdetl.getSize() > 0) AND
					--							(
					--								((l_arr_rec_batchdetl[l_arr_rec_batchdetl.getSize()].for_debit_amt = 0) OR (l_arr_rec_batchdetl[l_arr_rec_batchdetl.getSize()].for_debit_amt IS NULL))
					--								AND
					--								((l_arr_rec_batchdetl[l_arr_rec_batchdetl.getSize()].for_credit_amt = 0) OR (l_arr_rec_batchdetl[l_arr_rec_batchdetl.getSize()].for_credit_amt IS NULL))
					--							) THEN
					--
					--							CALL l_arr_rec_batchdetl.deleteElement(l_arr_rec_batchdetl.getSize())
					--
					--						END IF
					--						NEXT FIELD scroll_flag
					--END IF
				END IF 

		END INPUT 

		IF NOT l_disburse_ind THEN 
			EXIT WHILE 
		END IF 

	END WHILE 
	------------------------------------------------------------ END WHILE -----------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION batch_lines_entry()  USED to be FUNCTION line_entry()
############################################################


##########################################################################
# t_batchdetl_can_row_get_removed(p_arr_rec_batchdetl.*)
#
# Common check if row should/can be removed
# Example, User navigates a ways from a row in the input array... what should happen...
##########################################################################
FUNCTION t_batchdetl_can_row_get_removed(p_arr_rec_batchdetl) 
	DEFINE p_arr_rec_batchdetl OF t_rec_batchdetl 

	#No Sequence number, no valid row
	IF (p_arr_rec_batchdetl.seq_num = 0) OR (p_arr_rec_batchdetl.seq_num IS null) THEN 
		RETURN true 
	END IF 

	IF 
	--		((p_arr_rec_batchdetl.debit_amt = 0) OR (p_arr_rec_batchdetl.debit_amt IS NULL))
	--	AND
	--		((p_arr_rec_batchdetl.credit_amt = 0) OR (p_arr_rec_batchdetl.credit_amt IS NULL))
	--	AND
	((p_arr_rec_batchdetl.for_debit_amt = 0) OR (p_arr_rec_batchdetl.for_debit_amt IS null)) 
	AND 
	((p_arr_rec_batchdetl.for_credit_amt = 0) OR (p_arr_rec_batchdetl.for_credit_amt IS null)) 
	THEN 
		RETURN true 
	END IF 

END FUNCTION 
##########################################################################
# END t_batchdetl_can_row_get_removed(p_arr_rec_batchdetl.*)
##########################################################################

{
############################################################
# FUNCTION line_entry()
#
# This FUNCTION provides a black-box method of entering/editting
# disbursement lines.  The t_batchdetl table IS used as the common
# storage location FOR returning the entered lines TO the calling program.
#
# Bank lines must have a corresponding t_banking entry.
#
#  Warning: this function is being replaced by the function batch_lines_entry
############################################################
FUNCTION line_entry()
	DEFINE l_rec_batchdetl RECORD LIKE t_batchdetl.*
	DEFINE l_rec_s_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_s_batchdetl_uom_code LIKE coa.uom_code
	DEFINE l_arr_rec_batchdetl DYNAMIC ARRAY OF RECORD     #array[3000] OF RECORD
		scroll_flag char(1),
		seq_num LIKE batchdetl.seq_num,
		acct_code LIKE batchdetl.acct_code,
		analysis_text LIKE batchdetl.analysis_text,
		for_debit_amt LIKE batchdetl.for_debit_amt,
		for_credit_amt LIKE batchdetl.for_credit_amt,
		stats_qty LIKE batchdetl.stats_qty,
		uom_code LIKE coa.uom_code,
		ref_text LIKE batchdetl.ref_text, # #ali feature request
		desc_text LIKE batchdetl.desc_text
	END RECORD
# this record saves the contents of the current line
	DEFINE l_save_batchdetl RECORD
		scroll_flag char(1),
		seq_num LIKE batchdetl.seq_num,
		acct_code LIKE batchdetl.acct_code,
		analysis_text LIKE batchdetl.analysis_text,
		for_debit_amt LIKE batchdetl.for_debit_amt,
		for_credit_amt LIKE batchdetl.for_credit_amt,
		stats_qty LIKE batchdetl.stats_qty,
		uom_code LIKE coa.uom_code,
		ref_text LIKE batchdetl.ref_text, # #ali feature request
		desc_text LIKE batchdetl.desc_text
	END RECORD

	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_temp_text char(20)
	DEFINE l_query_text char(300)
	DEFINE l_where_text STRING
	DEFINE i,a SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_arrcurr SMALLINT
	DEFINE l_scrline SMALLINT
	DEFINE l_disburse_ind SMALLINT
	DEFINE l_feature_ind SMALLINT
	DEFINE l_valid_tran LIKE language.yes_flag
	DEFINE l_available_amt LIKE fundsapproved.limit_amt
	DEFINE l_desc_text LIKE batchdetl.desc_text
	DEFINE l_ref_text LIKE batchdetl.ref_text
	DEFINE l_anal_text LIKE batchdetl.analysis_text
	DEFINE l_msgresp LIKE language.yes_flag

	SELECT cash_book_flag INTO glob_rec_glparms.cash_book_flag FROM glparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND key_code = "1"

	IF glob_rec_glparms.cash_book_flag = "Y" THEN
		LET glob_fv_cash_book = "1"
	ELSE
		LET glob_fv_cash_book = "2"
	END IF

	CASE get_kandoooption_feature_state('GL','MS')
		WHEN 'A'
			LET glob_desc_ind = "1"
		WHEN 'D'
			LET glob_desc_ind = "2"
		WHEN 'H'
			LET glob_desc_ind = "3"
		OTHERWISE
			LET glob_desc_ind = "1"
	END CASE

--	OPTIONS INSERT KEY f1,
--	DELETE KEY f2

	DISPLAY BY NAME glob_rec_batchhead.jour_code,
	glob_rec_batchhead.jour_num,
	glob_rec_batchhead.jour_date

#This is shit... sorry to say this.. lazy but expensive approach of displaying the same string to 2 labels
	DISPLAY glob_rec_batchhead.currency_code TO sr_currency[1].*
	DISPLAY glob_rec_batchhead.currency_code TO sr_currency[2].*

	IF glob_rec_batchhead.seq_num < 20 THEN
## Dont bother user FOR criteria on small batches OR WHEN adding new
## batches.  Drives those with only 6-10 line batches crazy.
		LET l_where_text = "1=1"
	ELSE
		MESSAGE kandoomsg2("U",1001,"")#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT l_where_text ON seq_num,
		acct_code,
		analysis_text,
		for_debit_amt,
		for_credit_amt,
		stats_qty,
		ref_text,
		desc_text
		FROM batchdetl.seq_num,
		batchdetl.acct_code,
		batchdetl.analysis_text,
		batchdetl.for_debit_amt,
		batchdetl.for_credit_amt,
		batchdetl.stats_qty,
		batchdetl.ref_text,
		batchdetl.desc_text
			BEFORE CONSTRUCT
				CALL publish_toolbar("kandoo","G21a","construct-batchdetl")

			ON ACTION "WEB-HELP"
				CALL onlinehelp(getmoduleid(),null)

			ON ACTION "actToolbarManager"
				CALL setuptoolbar()

		END CONSTRUCT

	END IF

	IF not ( int_flag OR quit_flag ) THEN
		LET l_query_text = "SELECT * FROM t_batchdetl ",
		"WHERE ",l_where_text clipped,
		" AND username = '",glob_rec_kandoouser.sign_on_code,"'",
		" ORDER BY seq_num"
		PREPARE s1_t_batchdetl FROM l_query_text
		DECLARE c1_t_batchdetl CURSOR FOR s1_t_batchdetl
	END IF

------------------------------------------------------------ WHILE -----------------
	WHILE not(int_flag OR quit_flag)
		MESSAGE kandoomsg2("U",1002,"")#1002 Searching database;  Please wait.
		LET l_idx = 0
# OPEN c1_t_batchdetl # OPEN is useless before FOREACH, unless you do OPEN ... USING placeholders

		LET l_idx = 1
# look in the 'uncompleted batches personal tank' if there is some batch
		FOREACH c1_t_batchdetl INTO l_rec_batchdetl.*
#Needs changing for new array structure
		LET l_arr_rec_batchdetl[l_idx].seq_num = l_rec_batchdetl.seq_num
		LET l_arr_rec_batchdetl[l_idx].acct_code = l_rec_batchdetl.acct_code
		LET l_arr_rec_batchdetl[l_idx].analysis_text = l_rec_batchdetl.analysis_text
		LET l_arr_rec_batchdetl[l_idx].for_debit_amt = l_rec_batchdetl.for_debit_amt
		LET l_arr_rec_batchdetl[l_idx].for_credit_amt = l_rec_batchdetl.for_credit_amt
		LET l_arr_rec_batchdetl[l_idx].for_credit_amt = l_rec_batchdetl.for_credit_amt

#These 3 were requested by Ali A. - feature request 17.10.2019
#LET l_arr_rec_batchdetl[l_idx].analysis_text = l_rec_batchdetl.analysis_text
			LET l_arr_rec_batchdetl[l_idx].ref_text = l_rec_batchdetl.ref_text
			LET l_arr_rec_batchdetl[l_idx].desc_text = l_rec_batchdetl.desc_text

			SELECT uom_code
			INTO l_arr_rec_batchdetl[l_idx].uom_code
			FROM coa
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND acct_code = l_arr_rec_batchdetl[l_idx].acct_code

#check this and add to display_balanced
			IF l_arr_rec_batchdetl[l_idx].uom_code is null THEN
				LET l_arr_rec_batchdetl[l_idx].stats_qty = null
			ELSE
				LET l_arr_rec_batchdetl[l_idx].stats_qty = l_rec_batchdetl.stats_qty
			END IF
			LET l_idx = l_idx + 1
		END FOREACH
		LET l_idx = l_idx - 1  # l_idx is 1 ahead in the cursor, must be reset to value - 1

		LET l_disburse_ind = false
		LET l_feature_ind = get_kandoooption_feature_state("GL","GL")
# 1  = DISPLAY of default acct IS required OR kandoooption NOT setup..
# 2 = No default account will be displayed..
#		CALL set_count(l_idx)
#      IF l_idx = 0 THEN
#         INITIALIZE l_arr_rec_batchdetl[1].* TO NULL
#      END IF
		MESSAGE kandoomsg2("G",1029,"") #EDIT Batch line #For what is this input array used ?
#1029 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse
		INPUT ARRAY l_arr_rec_batchdetl WITHOUT DEFAULTS FROM sr_batchdetl_v2.* attributes(unbuffered,delete ROW = true, insert row=false, append row = true)
-- ATTRIBUTES(UNBUFFERED,delete row = true, auto append = false, insert row=false) #works with APPEND !!!! you need to have a toolbar button
--attributes(unbuffered,delete ROW = true, insert row=false, append row = true) #works with append !!!! you NEED TO have a toolbar button
			BEFORE INPUT
				CALL disp_total()

				IF glob_rec_glparms.control_tot_flag != "N" THEN #Control amount is disabled in configuration program
					DISPLAY "Control Amount is enabled" TO lb_control_amount_switch
				END IF


				LET l_temp_text = kandooword("batchh0ead.desc_ind",glob_desc_ind)
				DISPLAY l_temp_text TO desc_mode
				CALL publish_toolbar("kandoo","G21a","input-arr-batchdetl")

			ON ACTION "WEB-HELP"
				CALL onlinehelp(getmoduleid(),null)

			ON ACTION "actToolbarManager"
				CALL setuptoolbar()
					
		ON ACTION "LOOKUP"  infield(acct_code) --lookup
#IF infield(acct_code) THEN
				LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code)

				IF not acct_type(glob_rec_kandoouser.cmpy_code,l_temp_text,glob_fv_cash_book,"N") THEN
					ERROR kandoomsg2("G",9202,"") #9202 Subsidiary Ledger Control Accounts can NOT be used.
					LET l_disburse_ind = true
					EXIT INPUT
				END IF
				OPTIONS INSERT KEY f1,
				DELETE KEY f2

				IF (glob_rec_batchhead.source_ind = "P"
				OR glob_rec_batchhead.source_ind = "R")
				AND l_temp_text is not null THEN
					SELECT unique(1) FROM fundsapproved
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					AND acct_code = l_temp_text
					IF status != NOTFOUND THEN
						IF l_temp_text != l_rec_batchdetl.acct_code THEN
							ERROR kandoomsg2("G",9604,"") #9604 Cannot edit capital account code.
						ELSE
							ERROR kandoomsg2("G",9605,"") #9605 Cannot add capital account code.
						END IF
						LET l_temp_text = null
					END IF
				END IF
				IF l_temp_text is not null THEN
					LET l_arr_rec_batchdetl[l_idx].acct_code = l_temp_text
					NEXT FIELD acct_code
				END IF
#END IF

			ON key(f9) --change glob_desc_ind ?? toggle description 1-3
				CASE glob_desc_ind
					WHEN "1"
						LET glob_desc_ind = "2"
					WHEN "2"
						LET glob_desc_ind = "3"
					OTHERWISE
						LET glob_desc_ind = "1"
				END CASE
				LET l_temp_text = kandooword("batchhead.desc_ind",glob_desc_ind)
				DISPLAY l_temp_text TO desc_mode

			ON key(f10) --disburse
				IF enter_disburse() THEN
					LET l_disburse_ind = true
					EXIT INPUT
				END IF


			BEFORE ROW
#  erve 2019-10-26 always set l_arrcurr and l_scrline at before row,
# use those variables and not any SMALLINT
				LET l_arrcurr = arr_curr()
				LET l_scrline = scr_line()

# check if row exists
				SELECT 1
				FROM t_batchdetl
				WHERE username = glob_rec_kandoouser.sign_on_code
				AND seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
				IF sqlca.sqlcode = 100 THEN
					INITIALIZE l_rec_batchdetl.* TO null
					INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
					LET  l_arr_rec_batchdetl[l_arrcurr].seq_num = l_arrcurr
				ELSE
# save the current element's contents
					LET l_save_batchdetl.* = l_arr_rec_batchdetl[l_arrcurr].*
					LET l_rec_s_batchdetl.* = l_rec_batchdetl.*
					LET l_rec_s_batchdetl_uom_code = l_arr_rec_batchdetl[l_arrcurr].uom_code

#DISPLAY "DEBUG3 - CALL input_line_detail() commented"
--					IF input_line_detail(false,l_rec_batchdetl.*) THEN
#do nothing ?
--					END IF
				END IF
-- END IF #l_idx > 0
-----------------------
				NEXT FIELD scroll_flag


			BEFORE FIELD scroll_flag #first FIELD in INPUT ARRAY
				LET a = 1
--{ erve 2019-10-26 this block is redundant with BEFORE ROW
-- IF l_idx > 0 THEN
-- SELECT * INTO l_rec_batchdetl.* FROM t_batchdetl
-- WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
-- IF status = NOTFOUND THEN
-- INITIALIZE l_rec_batchdetl.* TO null
-- END IF
-- LET l_rec_s_batchdetl.* = l_rec_batchdetl.*
-- LET l_rec_s_batchdetl_uom_code = l_arr_rec_batchdetl[l_arrcurr].uom_code
-- IF input_line_detail(false,l_rec_batchdetl.*) THEN
--END IF
-- END IF

			BEFORE INSERT
				LET l_arrcurr = arr_curr()
				LET l_scrline = scr_line()
				INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
				INITIALIZE l_rec_batchdetl.* TO null
				INITIALIZE l_rec_s_batchdetl.* TO null
-- IF l_idx > 0 THEN
-- LET l_rec_s_batchdetl_uom_code = l_arr_rec_batchdetl[l_arrcurr].uom_code
-- END IF
-- IF l_feature_ind = 1 AND l_idx > 1 THEN
				IF l_feature_ind = 1 AND l_arrcurr > 1 THEN
					IF acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr-1].acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN
##
## Only default account TO the above line if
## 1. Max option IS turned on
## 2. There IS an above line
## 3. Above line IS NOT a control account
##
						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_arr_rec_batchdetl[l_arrcurr-1].acct_code
					END IF
				END IF
##
## A minor Informix problem exists WHERE WHEN pressing delete
## on last line actually performs a delete AND an INSERT. To
## avoid this the following check IS included.
##
				IF fgl_lastkey() = fgl_keyval("delete")
				OR fgl_lastkey() = fgl_keyval("interrupt") THEN
# INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
					NEXT FIELD scroll_flag
				ELSE
					NEXT FIELD acct_code
				END IF

			BEFORE DELETE
-- IF not acct_type(glob_rec_kandoouser.cmpy_code,l_rec_batchdetl.acct_code,glob_fv_cash_book,"N") THEN
				IF not acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr].acct_code,glob_fv_cash_book,"N") THEN
					ERROR kandoomsg2("G",9056,"")
					LET l_disburse_ind = true
					EXIT INPUT
				ELSE
					DELETE FROM t_batchdetl
					WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
					AND username = glob_rec_kandoouser.sign_on_code
					CALL disp_total()
# INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
					NEXT FIELD scroll_flag
				END IF

			BEFORE FIELD seq_num
				IF l_arr_rec_batchdetl[l_arrcurr].seq_num is null
				OR l_arr_rec_batchdetl[l_arrcurr].seq_num = 0 THEN
					SELECT nvl(max(seq_num) ,0)+1
					INTO l_arr_rec_batchdetl[l_arrcurr].seq_num
					FROM t_batchdetl
					WHERE username = glob_rec_kandoouser.sign_on_code
					DISPLAY l_arr_rec_batchdetl[l_arrcurr].seq_num TO sr_batchdetl[l_scrline].seqnum
				END IF

			BEFORE FIELD acct_code
				IF l_arr_rec_batchdetl[l_arrcurr].acct_code IS NOT NULL THEN
					CALL read_coa(l_arr_rec_batchdetl[l_arrcurr].acct_code,glob_desc_ind, l_arrcurr)
					RETURNING l_desc_text,l_ref_text,l_anal_text

					LET l_rec_batchdetl.desc_text = l_desc_text
					LET l_rec_batchdetl.ref_text = l_ref_text
					LET l_rec_batchdetl.analysis_text = l_anal_text
--					#DISPLAY "DEBUG4 - CALL input_line_detail() commented"
--					IF input_line_detail(false,l_rec_batchdetl.*) THEN
--						#
--					END IF
-- DISPLAY l_arr_rec_batchdetl[l_arrcurr].seq_num TO l_idx

					IF not acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[l_arrcurr].acct_code,glob_fv_cash_book,"N") THEN
##
## IF account IS a control account THEN only allow edit of
## refernece type fields.  IF account OR amount IS changed
## THEN will notmatch corresponding control entry.
##
#DISPLAY "DEBUG6 - CALL input_line_detail() commented"
--						IF input_line_detail(true,l_rec_batchdetl.*) THEN
--							NEXT FIELD scroll_flag
--						ELSE
--							NEXT FIELD scroll_flag
--						END IF
					ELSE
## IF account IS a capital, don't allow edit.
						IF glob_rec_batchhead.source_ind = "P"
						OR glob_rec_batchhead.source_ind = "R" THEN
							SELECT unique(1) FROM fundsapproved
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
							AND acct_code = l_arr_rec_batchdetl[l_arrcurr].acct_code
							IF status != NOTFOUND THEN
								ERROR kandoomsg2("G",9603,"")#9603 Cannot edit capital line.
								NEXT FIELD scroll_flag
							END IF
						END IF
					END IF
				END IF

			AFTER FIELD acct_code

				IF get_debug() THEN
					DISPLAY "fgl_lastaction()=", fgl_lastaction()
					DISPLAY "fgl_lastkey()=", fgl_lastkey()
					DISPLAY "fgl_keyname(fgl_lastkey())=", fgl_keyname(fgl_lastkey())
				END IF

				IF fgl_lastkey() != fgl_keyval("RETURN")
				AND fgl_lastkey() != fgl_keyval("right")
				AND fgl_lastkey() != fgl_keyval("tab") THEN

					IF get_debug() THEN
						DISPLAY "user did NOT press return, right or tab"
					END IF

				ELSE
					IF get_debug() THEN
						DISPLAY "Return, Right -> or TAB key"
					END IF

					IF l_arr_rec_batchdetl[l_arrcurr].acct_code is null THEN
						DISPLAY fgl_lastaction()
						IF fgl_lastkey() = fgl_keyval("accept") THEN
							EXIT INPUT #@temptest
							LET modu_dbg_accept = true
						ELSE
							ERROR kandoomsg2("G",9032,"")#9032 Account must be entered;  Try Window.
							NEXT FIELD acct_code
						END IF
					END IF
					CALL verify_acct_code(glob_rec_kandoouser.cmpy_code,
					l_arr_rec_batchdetl[l_arrcurr].acct_code,
					glob_rec_batchhead.year_num,
					glob_rec_batchhead.period_num)
					RETURNING l_rec_coa.*

					IF l_rec_coa.acct_code is null THEN
						NEXT FIELD acct_code
#ELSE
#	LET l_arr_rec_batchdetl[l_arrcurr].desc_text = db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code)
					END IF
					IF l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_coa.acct_code THEN
						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_coa.acct_code
						NEXT FIELD acct_code
					END IF
#We check, if the choosen gl-account is a normal account (must not be bank)
					IF not acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,glob_fv_cash_book,"Y") THEN
						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = null
						NEXT FIELD acct_code
					END IF
# Cannot add OR edit account code FOR purchase ORDER
# OR voucher.
-- IF (l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_batchdetl.acct_code
					IF (l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
					AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0)
					AND (glob_rec_batchhead.source_ind = "P"
					OR glob_rec_batchhead.source_ind = "R") THEN
						SELECT unique(1)
						FROM fundsapproved
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
						AND acct_code = l_arr_rec_batchdetl[l_arrcurr].acct_code
						IF status != NOTFOUND THEN
							IF l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_batchdetl.acct_code THEN
								ERROR kandoomsg2("G",9604,"")#9604 Cannot edit capital account code.
							ELSE
								ERROR kandoomsg2("G",9605,"")#9605 Cannot add capital account code.
							END IF
							LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_batchdetl.acct_code
							NEXT FIELD acct_code
						END IF
					END IF

-- { erve 2019-10-26 get rid of usage of l_rec_batchdetl
-- IF (l_rec_batchdetl.acct_code is null) OR (l_rec_batchdetl.acct_code != l_rec_coa.acct_code) THEN
					IF (l_arr_rec_batchdetl[l_arrcurr].acct_code is null) OR (l_arr_rec_batchdetl[l_arrcurr].acct_code != l_rec_coa.acct_code) THEN
						CALL read_coa(l_rec_coa.acct_code,glob_desc_ind, l_idx)
						RETURNING l_desc_text,
						l_ref_text,
						l_anal_text
						LET l_arr_rec_batchdetl[l_arrcurr].desc_text = l_desc_text
						LET l_rec_batchdetl.ref_text = l_ref_text
						LET l_arr_rec_batchdetl[l_arrcurr].analysis_text = l_anal_text

					END IF
					LET l_rec_batchdetl.acct_code = l_rec_coa.acct_code

#DISPLAY "DEBUG1 - CALL input_line_detail() commented"
-- IF input_line_detail(false,l_rec_batchdetl.*) THEN #funny condition ????
-- IF input_line_detail(false,l_arr_rec_batchdetl[l_arrcurr].*) THEN #funny condition ????
#
-- END IF

					IF l_rec_coa.uom_code is null THEN
						LET l_arr_rec_batchdetl[l_arrcurr].uom_code = null
						LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = null
					ELSE
						LET l_arr_rec_batchdetl[l_arrcurr].uom_code = l_rec_coa.uom_code
					END IF

					IF l_rec_coa.uom_code is not null
					AND l_arr_rec_batchdetl[l_arrcurr].stats_qty is null THEN
						LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
					END IF

# DISPLAY l_arr_rec_batchdetl[l_arrcurr].stats_qty,
#         l_arr_rec_batchdetl[l_arrcurr].uom_code
#      TO sr_batchdetl[scrn].stats_qty,
#         sr_batchdetl[scrn].uom_code

					CASE
						WHEN fgl_lastkey() = fgl_keyval("accept")
							IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
							AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
							AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
							OR l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
								ERROR kandoomsg2("G",9044,"") #G9044 " Amount must be positive "
								NEXT FIELD acct_code
							END IF

							IF l_rec_batchdetl.analysis_text is null
							AND l_rec_coa.analy_req_flag = "Y" THEN
								CALL display_batch_balance(l_arr_rec_batchdetl)
								ERROR kandoomsg2("P",9016,"") #9016 " Analysis IS required "
								NEXT FIELD uom_code
							ELSE
								NEXT FIELD scroll_flag
							END IF

						WHEN fgl_lastkey() = fgl_keyval("RETURN") #huho .. we NEED TO get away FROM legacy navigation
							OR fgl_lastkey() = fgl_keyval("right")
							OR fgl_lastkey() = fgl_keyval("tab")
							OR fgl_lastkey() = fgl_keyval("down")
							NEXT FIELD NEXT

						WHEN fgl_lastkey() = fgl_keyval("left")
							OR fgl_lastkey() = fgl_keyval("up")
							IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
							AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
							AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 OR
							l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
								ERROR kandoomsg2("G",9044,"")#G9044 " Amount must be positive "
								NEXT FIELD acct_code
							END IF

							IF l_rec_batchdetl.analysis_text is null
							AND l_rec_coa.analy_req_flag = "Y" THEN
								ERROR kandoomsg2("P",9016,"")#9016 " Analysis IS required "
								CALL display_batch_balance(l_arr_rec_batchdetl)

								NEXT FIELD uom_code
							END IF
							NEXT FIELD scroll_flag
						OTHERWISE
							NEXT FIELD acct_code
					END CASE

				END IF #end IF FROM the initial right, tab, enter KEY condition

#--------------------------

			AFTER FIELD for_debit_amt
#Requested by Anna - only debit or credit
				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0 THEN #some amount was entered
					IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt != 0 THEN #debit also has a value must not happen
						ERROR "You can not enter both, a Debit and a Credit Amount for the same batch"
						LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
#NEXT FIELD for_debit_amt
					ELSE
#NEXT FIELD stats_qty
					END IF
				END IF
-- end of Anna Feature Request

				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt is null THEN
					LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
					NEXT FIELD for_debit_amt
				END IF

				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt < 0 THEN
					ERROR kandoomsg2("G",9044,"")#9044 Amount must be positive.
					LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
					NEXT FIELD for_debit_amt
				END IF

				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0
				AND glob_rec_batchhead.source_ind not matches "[PR]" THEN
					CALL check_funds(glob_rec_kandoouser.cmpy_code,
					l_arr_rec_batchdetl[l_arrcurr].acct_code,
					l_arr_rec_batchdetl[l_arrcurr].for_debit_amt,
					l_arr_rec_batchdetl[l_arrcurr].seq_num,
					glob_rec_batchhead.year_num,
					glob_rec_batchhead.period_num,
					"G",
					glob_rec_batchhead.jour_num,
					"Y")
					RETURNING l_valid_tran, l_available_amt
					ERROR kandoomsg2("G",1029,"") #1029 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse

					IF not l_valid_tran THEN
						NEXT FIELD acct_code
					END IF
				END IF

#Update Debit_amt
				UPDATE t_batchdetl
				SET for_debit_amt = l_arr_rec_batchdetl[l_arrcurr].for_debit_amt
				WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num

				CALL disp_total() #display balance information / totals
				CASE
					WHEN fgl_lastkey() = fgl_keyval("accept")
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
						AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
						AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 OR
						l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
							ERROR kandoomsg2("G",9044,"") #G9044 " Amount must be positive "
							NEXT FIELD for_debit_amt
						END IF
						IF l_rec_batchdetl.analysis_text is null
						AND l_rec_coa.analy_req_flag = "Y" THEN
							CALL display_batch_balance(l_arr_rec_batchdetl)
							ERROR kandoomsg2("P",9016,"") #9016 " Analysis IS required "
							NEXT FIELD uom_code
						ELSE
							NEXT FIELD scroll_flag
						END IF

					WHEN fgl_lastkey() = fgl_keyval("RETURN")
						OR fgl_lastkey() = fgl_keyval("right")
						OR fgl_lastkey() = fgl_keyval("tab")
						OR fgl_lastkey() = fgl_keyval("down")
#NEXT FIELD next #huho
#Requested by Anna - only debit or credit
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0 THEN #some amount was entered
							NEXT FIELD stats_qty
						ELSE
							NEXT FIELD for_credit_amt
						END IF
-- end of Anna Feature Request
					WHEN fgl_lastkey() = fgl_keyval("left")
						OR fgl_lastkey() = fgl_keyval("up")
						NEXT FIELD previous

					OTHERWISE
						NEXT FIELD for_debit_amt
				END CASE

			AFTER FIELD for_credit_amt
#Requested by Anna - only debit or credit
				IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt != 0 THEN #some amount was entered
					IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0 THEN #debit also has a value must not happen
						ERROR "You can not enter both, a Debit and a Credit Amount for the same batch"
						LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
#NEXT FIELD for_credit_amt
					ELSE
#NEXT FIELD stats_qty
					END IF
				END IF
-- end of Anna Feature Request

				IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt is null THEN
					LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
					NEXT FIELD for_credit_amt
				END IF

				IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt < 0 THEN
					ERROR kandoomsg2("G",9044,"") #9044 Amount must be positive.
					LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
					NEXT FIELD for_credit_amt
				END IF

#Update Credit_amt
				UPDATE t_batchdetl
				SET for_credit_amt = l_arr_rec_batchdetl[l_arrcurr].for_credit_amt
				WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num

				CALL disp_total()
				CASE
					WHEN fgl_lastkey() = fgl_keyval("accept")
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
						AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
						AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0 OR
						l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
							ERROR kandoomsg2("G",9044,"") #9044 Amount must be positive.
							NEXT FIELD for_credit_amt
						END IF

						IF l_rec_batchdetl.analysis_text is null
						AND l_rec_coa.analy_req_flag = "Y" THEN
							CALL display_batch_balance(l_arr_rec_batchdetl)
							ERROR kandoomsg2("P",9016,"") #9016 Analysis IS required.
							NEXT FIELD uom_code
						ELSE
							NEXT FIELD scroll_flag
						END IF

					WHEN fgl_lastkey() = fgl_keyval("RETURN")
						OR fgl_lastkey() = fgl_keyval("right")
						OR fgl_lastkey() = fgl_keyval("tab")
						OR fgl_lastkey() = fgl_keyval("down")
#NEXT FIELD next #huho
#Requested by Anna - only debit or credit
						IF l_arr_rec_batchdetl[l_arrcurr].for_credit_amt != 0 THEN #some amount was entered
							NEXT FIELD stats_qty
						ELSE
							IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0 THEN
								ERROR "You can not specify NULL Amnounts for Credit and debit!"
								NEXT FIELD for_credit_amt
							ELSE
								NEXT FIELD stats_qty
							END IF
						END IF
-- end of Anna Feature Request

					WHEN fgl_lastkey() = fgl_keyval("left")
						OR fgl_lastkey() = fgl_keyval("up")
						NEXT FIELD previous
					OTHERWISE
						NEXT FIELD for_credit_amt
				END CASE

			BEFORE FIELD stats_qty
				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt != 0
				AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt!= 0 THEN
					ERROR kandoomsg2("G",9050,"") #9050 An entry can have a debit OR a credit, NOT both.
					NEXT FIELD for_debit_amt
				END IF

				IF l_arr_rec_batchdetl[l_arrcurr].uom_code is null THEN
					NEXT FIELD NEXT
				END IF

			AFTER FIELD stats_qty
#Update stats_qty and seq_num
				UPDATE t_batchdetl
				SET stats_qty = l_arr_rec_batchdetl[l_arrcurr].stats_qty
				WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
				CALL disp_total()

				CASE
					WHEN fgl_lastkey() = fgl_keyval("accept")
						IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
						AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
						AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
						OR l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
							ERROR kandoomsg2("G",9044,"") #9044 Amount must be positive.
							NEXT FIELD stats_qty
						END IF
						IF l_rec_batchdetl.analysis_text is null
						AND l_rec_coa.analy_req_flag = "Y" THEN
							CALL display_batch_balance(l_arr_rec_batchdetl)
							ERROR kandoomsg2("P",9016,"")#9016 Analysis IS required.
							NEXT FIELD uom_code
						ELSE
							NEXT FIELD scroll_flag
						END IF

					WHEN fgl_lastkey() = fgl_keyval("RETURN")
						OR fgl_lastkey() = fgl_keyval("right")
						OR fgl_lastkey() = fgl_keyval("tab")
						OR fgl_lastkey() = fgl_keyval("down")
						NEXT FIELD NEXT

					WHEN fgl_lastkey() = fgl_keyval("left")
						OR fgl_lastkey() = fgl_keyval("up")
						NEXT FIELD previous

					OTHERWISE
						NEXT FIELD stats_qty
				END CASE

			BEFORE FIELD uom_code
				IF l_arr_rec_batchdetl[l_arrcurr].for_debit_amt = 0
				AND l_arr_rec_batchdetl[l_arrcurr].for_credit_amt = 0
				AND (l_arr_rec_batchdetl[l_arrcurr].stats_qty = 0
				OR l_arr_rec_batchdetl[l_arrcurr].stats_qty is null) THEN
					ERROR kandoomsg2("G",9044,"")#9044 Amount must be positive.
					NEXT FIELD for_debit_amt
				END IF

#DISPLAY "DEBUG2 - CALL input_line_detail() commented"
--				IF not input_line_detail(true,l_rec_batchdetl.*) THEN
--					DELETE FROM t_batchdetl
--					WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
--					AND username = glob_rec_kandoouser.sign_on_code
--					LET l_rec_batchdetl.username = glob_rec_kandoouser.sign_on_code
--					IF l_rec_s_batchdetl.acct_code is not null THEN
--						LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_rec_s_batchdetl.seq_num
--						LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_s_batchdetl.acct_code
--						LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt=l_rec_s_batchdetl.for_debit_amt
--						LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt= l_rec_s_batchdetl.for_credit_amt
--						LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = l_rec_s_batchdetl.stats_qty
--						LET l_arr_rec_batchdetl[l_arrcurr].uom_code = l_rec_s_batchdetl_uom_code
--
--						# shouldn't we prefere and UPDATE here, instead of DELETE /  INSERT ?
--						INSERT INTO t_batchdetl values(l_rec_s_batchdetl.*)
--
--					ELSE
--						FOR i = arr_curr() TO arr_count()
--							IF l_arr_rec_batchdetl[i+1].acct_code is not null THEN
--								LET l_arr_rec_batchdetl[i].* = l_arr_rec_batchdetl[i+1].*
--							ELSE
--								INITIALIZE l_arr_rec_batchdetl[i].* TO null
--							END IF
--							# IF scrn <= 7 THEN
--							#    DISPLAY l_arr_rec_batchdetl[i].* TO sr_batchdetl[scrn].*
--							#
--							#    LET scrn = scrn + 1
--							# END IF
--						END FOR
--						#LET scrn = scr_line()
--				END IF
--					CALL disp_total()
--					NEXT FIELD scroll_flag
--				END IF
#Ali Feature request
#										
#		ON ACTION "LOOKUP" infield(desc_text)
#            LET l_arr_rec_batchdetl[i].desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchdetl[i].desc_text)
#            NEXT FIELD desc_text


			BEFORE FIELD analysis_text
				DISPLAY "BEFORE FIELD analysis_text"

			AFTER FIELD analysis_text
				DISPLAY "BEFORE FIELD analysis_text"

			BEFORE FIELD ref_text
				DISPLAY "BEFORE FIELD ref_text"

			AFTER FIELD ref_text
				DISPLAY "BEFORE FIELD ref_text"

			BEFORE FIELD desc_text
				DISPLAY "BEFORE FIELD desc_text"

			AFTER FIELD desc_text
				DISPLAY "BEFORE FIELD desc_text"


			AFTER ROW
				IF l_idx > 0 THEN
					SELECT unique 1 FROM t_batchdetl
					WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
					IF status = NOTFOUND THEN
						IF l_idx > 1 THEN
							LET l_idx = l_idx - 1
						ELSE
							LET l_idx = 1
						END IF
					END IF
#						INITIALIZE l_arr_rec_batchdetl[l_arrcurr].* TO NULL
				END IF
#				IF fgl_lastkey() = fgl_keyval("accept") THEN   #@ErVe - this blocks Anna of adding another new row
#					LET modu_dbg_accept = true
#				ELSE
#					LET modu_dbg_accept = false
#				END IF
#DISPLAY l_arr_rec_batchdetl[l_arrcurr].* TO sr_batchdetl[scrn].*

			AFTER INPUT
#DEL & ESC go back TO scroll_flag IF CURSOR NOT on scroll_flag
#				IF fgl_lastkey() = fgl_keyval("accept") THEN  @ErVe
#					LET modu_dbg_accept = true
#				ELSE
#					LET modu_dbg_accept = false
#				END IF
				IF int_flag OR quit_flag THEN
					IF not infield(scroll_flag) AND l_idx > 0 THEN
						LET int_flag = false
						LET quit_flag = false
						DELETE FROM t_batchdetl
						WHERE seq_num = l_arr_rec_batchdetl[l_arrcurr].seq_num
						AND username = glob_rec_kandoouser.sign_on_code
						IF l_rec_s_batchdetl.acct_code is not null THEN
							LET l_arr_rec_batchdetl[l_arrcurr].seq_num = l_rec_s_batchdetl.seq_num
							LET l_arr_rec_batchdetl[l_arrcurr].acct_code = l_rec_s_batchdetl.acct_code
							LET l_arr_rec_batchdetl[l_arrcurr].for_debit_amt= l_rec_s_batchdetl.for_debit_amt
							LET l_arr_rec_batchdetl[l_arrcurr].for_credit_amt= l_rec_s_batchdetl.for_credit_amt
							LET l_arr_rec_batchdetl[l_arrcurr].stats_qty = l_rec_s_batchdetl.stats_qty
							LET l_arr_rec_batchdetl[l_arrcurr].uom_code = l_rec_s_batchdetl_uom_code

						IF get_debug() THEN
							DISPLAY "INSERT 2 t_batchdetl -----------------------------------------------------------"
							DISPLAY "cmpy_code=", glob_rec_batchhead.cmpy_code

							DISPLAY "seq_num=", l_arr_rec_batchdetl[l_arrcurr].seq_num
							DISPLAY "acct_code=", l_arr_rec_batchdetl[l_arrcurr].acct_code
							DISPLAY "analysis_text=", l_arr_rec_batchdetl[l_arrcurr].analysis_text
							DISPLAY "for_debit_amt=", l_arr_rec_batchdetl[l_arrcurr].for_debit_amt
							DISPLAY "for_credit_amt=", l_arr_rec_batchdetl[l_arrcurr].for_credit_amt
							DISPLAY "stats_qty=", l_arr_rec_batchdetl[l_arrcurr].stats_qty
							DISPLAY "ref_text=", l_arr_rec_batchdetl[l_arrcurr].ref_text
							DISPLAY "desc_text=", l_arr_rec_batchdetl[l_arrcurr].desc_text

							DISPLAY "jour_code=", glob_rec_batchhead.jour_code
							DISPLAY "sign_on_code=", glob_rec_kandoouser.sign_on_code
						END IF

							INSERT INTO t_batchdetl values(l_rec_s_batchdetl.*, glob_rec_kandoouser.sign_on_code)

						ELSE
							FOR i = arr_curr() TO arr_count()
								IF l_arr_rec_batchdetl[i+1].acct_code is not null THEN
									LET l_arr_rec_batchdetl[i].* = l_arr_rec_batchdetl[i+1].*
								ELSE
									INITIALIZE l_arr_rec_batchdetl[i].* TO null
								END IF
#IF scrn <= 7 THEN
#   DISPLAY l_arr_rec_batchdetl[i].* TO sr_batchdetl[scrn].*
#
#   LET scrn = scrn + 1
#END IF
							END FOR
#LET scrn = scr_line()
						END IF
						CALL disp_total()
						NEXT FIELD scroll_flag
					END IF
				END IF

# ON KEY (control-w)  --help
# CALL kandoohelp("")

		END INPUT

		IF not l_disburse_ind THEN
			EXIT WHILE
		END IF

	END WHILE
------------------------------------------------------------ END WHILE -----------------

	IF int_flag OR quit_flag THEN
		LET int_flag = false
		LET quit_flag = false
		RETURN false
	ELSE
		RETURN true
	END IF
END FUNCTION

}
############################################################
# FUNCTION input_line_detail(p_update_ind,p_rec_batchdetl)
#
# input_line_detail(FALSE,l_rec_batchdetl.*)
############################################################
FUNCTION input_line_detail(p_update_ind,p_rec_batchdetl) 
	DEFINE p_update_ind SMALLINT ## true=update false=display 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_temp_text char(30) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_rec_line_details array[1] OF RECORD LIKE batchdetl.* 
	#			p_rec_batchdetl.analysis_text,
	#			p_rec_batchdetl.ref_text,
	#			p_rec_batchdetl.desc_text
	#		END RECORD

	LET l_arr_rec_line_details[1].* = p_rec_batchdetl.* 


	#	DISPLAY "Debug p_rec_batchdetl.acct_code=", p_rec_batchdetl.acct_code
	#	DISPLAY "Debug p_rec_batchdetl.desc_text=", p_rec_batchdetl.desc_text
	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_rec_batchdetl.acct_code 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = kandooword("Analysis",1) 
	END IF 

	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"................" 
	LET l_rec_coa.analy_prompt_text = l_temp_text 

	DISPLAY l_rec_coa.analy_prompt_text TO coa.analy_prompt_text 

	OPTIONS INPUT no wrap #we don't want this here - leaving the LAST FIELD should save the CURRENT ROW 

	DISPLAY p_rec_batchdetl.desc_text TO batchdetl.desc_text 

	#INPUT ARRAY l_arr_rec_line_details[]

	INPUT 
	--{ erve 2019-10-25 KD-1314
	-- p_rec_batchdetl.analysis_text,
	--}
		p_rec_batchdetl.ref_text, 
		p_rec_batchdetl.desc_text 
	WITHOUT DEFAULTS 
	FROM 
		-- batchdetl.analysis_text,
		batchdetl.ref_text, 
		batchdetl.desc_text	ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G21a","input-batchdetl") 
			DISPLAY p_rec_batchdetl.desc_text TO batchdetl.desc_text 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (desc_text) 
			LET p_rec_batchdetl.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,p_rec_batchdetl.desc_text) 
			NEXT FIELD desc_text 

		BEFORE FIELD analysis_text 
			IF p_update_ind THEN 
				LET l_rec_batchdetl.* = p_rec_batchdetl.* 
			ELSE 
				EXIT INPUT 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF glob_desc_ind = "2" THEN 
					LET glob_default_text = p_rec_batchdetl.desc_text 
				END IF 

				IF glob_desc_ind = "3" AND p_rec_batchdetl.seq_num = 1 THEN 
					LET glob_default_ref = p_rec_batchdetl.ref_text 
					LET glob_default_anal = p_rec_batchdetl.analysis_text 
				END IF 
				
				IF p_rec_batchdetl.analysis_text IS NULL AND l_rec_coa.analy_req_flag = "Y" THEN 
					MESSAGE kandoomsg2("G",9051,"") #9051 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF 

			END IF 

	END INPUT 

	OPTIONS INPUT wrap 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		#Update ref_text, analysis_text, desc_text
		UPDATE t_batchdetl 
		SET 
			ref_text = p_rec_batchdetl.ref_text, 
			analysis_text = p_rec_batchdetl.analysis_text, 
			desc_text = p_rec_batchdetl.desc_text 
		WHERE seq_num = p_rec_batchdetl.seq_num 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION input_line_detail(p_update_ind,p_rec_batchdetl)
############################################################


############################################################
# FUNCTION read_coa(p_acct_code,p_mode_ind, p_line)
#
#
############################################################
FUNCTION read_coa(p_acct_code,p_mode_ind, p_line) 
	DEFINE p_acct_code LIKE batchdetl.acct_code 
	DEFINE p_line SMALLINT 
	DEFINE p_mode_ind char(1) 
	DEFINE l_desc_text LIKE batchdetl.desc_text 
	DEFINE l_ref_text LIKE batchdetl.ref_text 
	DEFINE l_anal_text LIKE batchdetl.analysis_text 

	CASE p_mode_ind 
		WHEN "1" ### account description 
			SELECT desc_text INTO l_desc_text 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_acct_code 
		WHEN "2" ### default description 
			LET l_desc_text = glob_default_text 
			EXIT CASE 
		WHEN "3" ### HOLD description 
			SELECT desc_text INTO l_desc_text 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_acct_code 
			IF p_line > 1 THEN 
				LET l_ref_text = glob_default_ref 
				LET l_anal_text = glob_default_anal 
			END IF 
	END CASE 

	RETURN l_desc_text, l_ref_text, l_anal_text 
END FUNCTION 
############################################################
# END FUNCTION read_coa(p_acct_code,p_mode_ind, p_line)
############################################################


############################################################
# FUNCTION display_batch_balance ()
# calculates and displays the batch balance information near real time
# by reading the t_batchdetl table
############################################################
FUNCTION display_batch_balance (p_arr_batch_entries) #balance information 
	DEFINE p_arr_batch_entries DYNAMIC ARRAY OF t_rec_batchdetl 
	DEFINE l_msg_text char(18) 
	DEFINE l_elem SMALLINT 
	DEFINE l_array_size SMALLINT 
	DEFINE l_temp_amount LIKE t_batchdetl.for_debit_amt #only used FOR DISPLAY 

	--SELECT sum(for_debit_amt),
	--sum(for_credit_amt),
	--sum(stats_qty)
	--INTO glob_rec_batchhead.for_debit_amt,
	--glob_rec_batchhead.for_credit_amt,
	--glob_rec_batchhead.stats_qty
	--FROM t_batchdetl

	# initialize values to 0
	-- HuHo I don't think so...	LET l_array_size = p_arr_batch_entries.getSize() - 1   #HuHO hmm -1 for the last row ? ALWAYS ????

	IF p_arr_batch_entries.getsize() > 0 THEN #only UPDATE MESSAGE FOR balanced/unbalanced IF any ROWS exist 

		LET glob_rec_batchhead.for_debit_amt = 0 
		LET glob_rec_batchhead.for_credit_amt = 0 
		LET glob_rec_batchhead.stats_qty = 0 

		FOR l_elem = 1 TO p_arr_batch_entries.getsize() 
			LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + p_arr_batch_entries[l_elem].for_debit_amt 
			LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + p_arr_batch_entries[l_elem].for_credit_amt 
		END FOR 

		IF glob_rec_batchhead.for_debit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_debit_amt = 0 
		END IF 
		IF glob_rec_batchhead.for_credit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_credit_amt = 0 
		END IF 
		IF glob_rec_batchhead.stats_qty IS NULL THEN 
			LET glob_rec_batchhead.stats_qty = 0 
		END IF 
		IF glob_rec_batchhead.control_amt IS NULL THEN 
			LET glob_rec_batchhead.control_amt = 0 
		END IF 
		IF glob_rec_batchhead.control_qty IS NULL THEN 
			LET glob_rec_batchhead.control_qty = 0 
		END IF 

							IF glob_rec_glparms.control_tot_flag = "N" THEN #control amount IS disabled in configuration program 
								LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 
								--		CASE
								--			WHEN glob_rec_batchhead.for_debit_amt > glob_rec_batchhead.for_credit_amt
								--				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt
								--			WHEN glob_rec_batchhead.for_debit_amt < glob_rec_batchhead.for_credit_amt
								--				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt
								--			OTHERWISE
								--				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt
								--				IF glob_rec_batchhead.for_debit_amt > 0 THEN
								--					LET l_msg_text = kandooword(" Batch in balance",1)
								--				END IF
								--		END CASE



								CASE 

									WHEN ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt) #debit = credit 
									AND (glob_rec_batchhead.for_debit_amt > 0)) 
										LET l_msg_text = kandooword(" Batch in balance",1) 
										LET l_msg_text = "Batch in balance" 

									OTHERWISE 
										LET l_msg_text = NULL 

								END CASE 


							ELSE #control amount/quantity IS enabled 

								CASE 
									WHEN ((glob_rec_batchhead.control_amt = 0) AND (glob_rec_batchhead.control_qty = 0)) #user did NOT enter a control amount OR quantity 
										IF ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt) 
										AND (glob_rec_batchhead.for_debit_amt > 0)) THEN 
											LET l_msg_text = kandooword(" Batch in balance",1) 
											LET l_msg_text = "Batch in balance" 
										END IF 

									WHEN ((glob_rec_batchhead.control_amt != 0) AND (glob_rec_batchhead.control_qty = 0)) #user did NOT enter a control amount but no quantity 
										IF ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt) 
										AND (glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.control_amt) 
										AND (glob_rec_batchhead.for_debit_amt > 0)) THEN 
											LET l_msg_text = kandooword(" Batch in balance",1) 
											LET l_msg_text = "Batch in balance" 
										END IF 


									WHEN ((glob_rec_batchhead.control_amt = 0) AND (glob_rec_batchhead.control_qty != 0)) #user did NOT enter no control amount but control quantity 
										IF ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt) 
										AND (glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty) 
										AND (glob_rec_batchhead.for_debit_amt > 0)) THEN 
											LET l_msg_text = kandooword(" Batch in balance",1) 
											LET l_msg_text = "Batch in balance" 
										END IF 

									WHEN ((glob_rec_batchhead.control_amt != 0) AND (glob_rec_batchhead.control_qty != 0)) #user did enter control amount AND control quantity 
										IF ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt) 
										AND (glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.control_amt) 
										AND (glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty) 
										AND (glob_rec_batchhead.for_debit_amt > 0)) THEN 
											LET l_msg_text = kandooword(" Batch in balance",1) 
											LET l_msg_text = "Batch in balance" 
										END IF 

								END CASE 

								{

										IF (glob_rec_batchhead.control_amt = 0) AND (glob_rec_batchhead.control_qty = 0) THEN #User entered a control amount

										ELSE
											IF ((glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt)
											AND (glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty)
											AND (glob_rec_batchhead.for_debit_amt > 0)) THEN
												LET l_msg_text = kandooword(" Batch in balance",1)
												LET l_msg_text = "Batch in balance"
											END IF

										END IF
								}

							END IF 

							IF l_msg_text IS NOT NULL THEN 
								MESSAGE l_msg_text 
								DISPLAY modu_balanced_text[1] TO lbbalanced attribute(green,reverse) 
								LET glob_balanced_flag = true 
							ELSE 
								DISPLAY modu_balanced_text[2] TO lbbalanced attribute(red,reverse) 
								LET glob_balanced_flag = false 
							END IF 

							--	IF (glob_rec_batchhead.for_debit_amt > 0) OR (glob_rec_batchhead.for_credit_amt > 0) THEN
							--		IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt THEN
							--			LET glob_balanced_flag = true
							--			DISPLAY "Journal Line Items are balanced" TO lbbalanced attribute(green,reverse)
							--		ELSE
							--			LET glob_balanced_flag = false
							--			DISPLAY "Journal Line Items are NOT balanced" TO lbbalanced attribute(red,reverse)
							--		END IF
							--	ELSE #no vlaid journal line items exist
							--		DISPLAY "" TO lbbalanced
							--	END IF

							DISPLAY glob_rec_batchhead.for_debit_amt TO batchhead.for_debit_amt 
							DISPLAY glob_rec_batchhead.for_credit_amt TO batchhead.for_credit_amt 
							DISPLAY glob_rec_batchhead.stats_qty TO batchhead.stats_qty 
							--	DISPLAY glob_rec_batchhead.control_amt TO batchhead.control_amt
							--	DISPLAY glob_rec_batchhead.control_qty TO batchhead.control_qty

							LET l_temp_amount = glob_rec_batchhead.for_debit_amt - glob_rec_batchhead.for_credit_amt 
							IF l_temp_amount <> 0 THEN 
								DISPLAY l_temp_amount TO for_balance_amt attribute(RED, reverse) 
							ELSE 
								DISPLAY l_temp_amount TO for_balance_amt --attribute(RED, green) 
							END IF 

							IF ((glob_rec_batchhead.control_amt IS NOT null) AND (glob_rec_batchhead.control_amt != 0) AND (glob_rec_glparms.control_tot_flag != "N") ) THEN 
								LET l_temp_amount = glob_rec_batchhead.for_debit_amt - glob_rec_batchhead.control_amt 
								IF l_temp_amount <> 0 THEN 
									DISPLAY l_temp_amount TO for_balance_control_amt attribute(RED, reverse) 
								ELSE 
									DISPLAY l_temp_amount TO for_balance_control_amt --attribute(RED, green) 
								END IF 
							END IF 

							IF ((glob_rec_glparms.control_tot_flag != "N") ) THEN 
								DISPLAY (glob_rec_batchhead.stats_qty - glob_rec_batchhead.control_qty) TO balance_quantity 
							END IF 

						END IF 


END FUNCTION 
############################################################
# END FUNCTION display_batch_balance ()
############################################################


############################################################
# FUNCTION disp_total()
# calculates and displays the batch balance information near real time
# by reading the t_batchdetl table
############################################################
FUNCTION disp_total() #balance information 
	DEFINE l_msg_text char(18) 

	SELECT 
		sum(for_debit_amt), 
		sum(for_credit_amt), 
		sum(stats_qty) 
	INTO 
		glob_rec_batchhead.for_debit_amt, 
		glob_rec_batchhead.for_credit_amt, 
		glob_rec_batchhead.stats_qty 
	FROM t_batchdetl 
	WHERE username = glob_rec_kandoouser.sign_on_code 
	--AND seq_num = l_rec_batchdetl.seq_num 
							
	IF glob_rec_batchhead.for_debit_amt IS NULL THEN 
		LET glob_rec_batchhead.for_debit_amt = 0 
	END IF 

	IF glob_rec_batchhead.for_credit_amt IS NULL THEN 
		LET glob_rec_batchhead.for_credit_amt = 0 
	END IF 


	IF glob_rec_batchhead.stats_qty IS NULL THEN 
		LET glob_rec_batchhead.stats_qty = 0 
	END IF 
###########################################################################
	IF glob_rec_glparms.control_tot_flag = "N" THEN 
		LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 
		CASE 
			WHEN glob_rec_batchhead.for_debit_amt > glob_rec_batchhead.for_credit_amt 
				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
			WHEN glob_rec_batchhead.for_debit_amt < glob_rec_batchhead.for_credit_amt 
				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt 
			OTHERWISE 
				LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt 
				IF glob_rec_batchhead.for_debit_amt > 0 THEN 
					--					LET l_msg_text = kandooword(" Batch in balance",1)
				END IF 
		END CASE 
	ELSE 
		IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt 
		AND glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.control_amt 
		AND glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty 
		AND glob_rec_batchhead.for_debit_amt > 0 THEN 
			--			LET l_msg_text = kandooword(" Batch in balance",1)
		END IF 
	END IF 

	IF l_msg_text IS NOT NULL THEN 
		--		MESSAGE l_msg_text
		--		DISPLAY "Journal Line Items are balanced" TO lbbalanced attribute(green,reverse)
	END IF 

	IF (glob_rec_batchhead.for_debit_amt > 0) OR (glob_rec_batchhead.for_credit_amt > 0) THEN 
		IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt THEN 
			LET glob_balanced_flag = true 
			--			DISPLAY "Journal Line Items are balanced" TO lbbalanced attribute(green,reverse)
		ELSE 
			LET glob_balanced_flag = false 
			--			DISPLAY "Journal Line Items are NOT balanced" TO lbbalanced attribute(red,reverse)
		END IF 
	ELSE #no vlaid journal line items exist 
		DISPLAY "" TO lbbalanced 
	END IF 


	DISPLAY glob_rec_batchhead.for_debit_amt TO batchhead.for_debit_amt 
	DISPLAY glob_rec_batchhead.for_credit_amt TO batchhead.for_credit_amt 
	DISPLAY glob_rec_batchhead.stats_qty TO batchhead.stats_qty 

	IF glob_rec_glparms.control_tot_flag != "N" THEN #control amount IS disabled in configuration program 
		DISPLAY glob_rec_batchhead.control_amt TO batchhead.control_amt 
		DISPLAY glob_rec_batchhead.control_qty TO batchhead.control_qty 
	ELSE 
		DISPLAY NULL TO batchhead.control_amt 
		DISPLAY NULL TO batchhead.control_qty 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION disp_total()
############################################################


############################################################
# FUNCTION G21a_write_gl_batch(l_mode)
#
#
############################################################
FUNCTION G21a_write_gl_batch(l_mode) 
	DEFINE l_mode char(4) 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_rec_cbaudit RECORD LIKE cbaudit.* 
	DEFINE l_err_message char(60) 
	DEFINE l_valid_tran char(1) 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING 

	MESSAGE kandoomsg2("G",1005,"") #G1005 Updating database - pls wait

	#To make sure, we don'T get NULL in decimal columns
	IF glob_rec_batchhead.for_debit_amt IS NULL THEN 
		LET glob_rec_batchhead.for_debit_amt = 0 
	END IF 
	
	IF glob_rec_batchhead.for_credit_amt IS NULL THEN 
		LET glob_rec_batchhead.for_credit_amt = 0 
	END IF 
	
	IF glob_rec_batchhead.stats_qty IS NULL 
		THEN LET glob_rec_batchhead.stats_qty = 0 
	END IF 
	
	IF glob_rec_batchhead.control_amt IS NULL THEN 
		LET glob_rec_batchhead.control_amt = 0 
	END IF 


	GOTO bypass 

	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
	EXECUTE immediate "SET CONSTRAINTS ALL deferred" 
						IF l_mode = MODE_CLASSIC_ADD THEN 
							LET l_err_message=" G21a - glparms select" 
							DECLARE c_glparms CURSOR FOR 
							SELECT * FROM glparms 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND key_code = "1" 
							FOR UPDATE 
							OPEN c_glparms 
							FETCH c_glparms INTO glob_rec_glparms.* 
							LET l_err_message=" G21a - glparms update" 
							
							UPDATE glparms #increase the auto-incrementing journal number FOR this company 
							SET next_jour_num = glob_rec_glparms.next_jour_num + 1 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND key_code = "1" 
							LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num + 1 

						ELSE 

							LET l_err_message=" G21a - Batch Header select" 
							DECLARE c_batchhead CURSOR FOR 
							SELECT * FROM batchhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_num = glob_rec_batchhead.jour_num 
							FOR UPDATE 
							OPEN c_batchhead 
							FETCH c_batchhead INTO glob_rec_2_batchhead.* 

							#This IS done TO prevent multiple users editing the same batch
							#OR completing edit WHERE batch has JUST been posted
							IF glob_rec_1_batchhead.jour_date != glob_rec_2_batchhead.jour_date 
							OR glob_rec_1_batchhead.year_num != glob_rec_2_batchhead.year_num 
							OR glob_rec_1_batchhead.period_num != glob_rec_2_batchhead.period_num 
							OR glob_rec_1_batchhead.debit_amt != glob_rec_2_batchhead.debit_amt 
							OR glob_rec_1_batchhead.credit_amt != glob_rec_2_batchhead.credit_amt 
							OR glob_rec_1_batchhead.currency_code != glob_rec_2_batchhead.currency_code 
							OR glob_rec_1_batchhead.conv_qty != glob_rec_2_batchhead.conv_qty 
							OR glob_rec_1_batchhead.post_flag != glob_rec_2_batchhead.post_flag 
							OR glob_rec_1_batchhead.seq_num != glob_rec_2_batchhead.seq_num 
							OR glob_rec_1_batchhead.com1_text != glob_rec_2_batchhead.com1_text 
							OR glob_rec_1_batchhead.com2_text != glob_rec_2_batchhead.com2_text 
							OR glob_rec_1_batchhead.control_amt != glob_rec_2_batchhead.control_amt 
							OR glob_rec_1_batchhead.control_qty != glob_rec_2_batchhead.control_qty 
							OR glob_rec_1_batchhead.stats_qty != glob_rec_2_batchhead.stats_qty THEN 

								ROLLBACK WORK 
								ERROR kandoomsg2("G",7020,"") #G 7020 Batch has being edited by another user - Changes Discarded"
								RETURN 0 

							END IF 
							
							LET l_err_message=" G21a - Delete batchdetls" 
							
							DELETE FROM batchdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_num = glob_rec_batchhead.jour_num 
						END IF 
						
						LET glob_rec_batchhead.for_debit_amt = 0 
						LET glob_rec_batchhead.for_credit_amt = 0 
						LET glob_rec_batchhead.debit_amt = 0 
						LET glob_rec_batchhead.credit_amt = 0 
						LET glob_rec_batchhead.stats_qty = 0 
						LET glob_rec_batchhead.seq_num = 0 
						
						IF glob_rec_batchhead.rate_type_ind IS NULL THEN 
							LET glob_rec_batchhead.rate_type_ind = "B" 
						END IF 
						
						DECLARE c_batchdetl CURSOR FOR 
						SELECT * 
						FROM t_batchdetl 
						WHERE username = glob_rec_kandoouser.sign_on_code 
						ORDER BY seq_num 

						FOREACH c_batchdetl INTO l_rec_batchdetl.* 
							IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
								LET l_rec_batchdetl.for_debit_amt = 0 
							END IF
							 
							IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
								LET l_rec_batchdetl.for_credit_amt = 0 
							END IF
							 
							IF l_rec_batchdetl.stats_qty IS NULL THEN 
								LET l_rec_batchdetl.stats_qty = 0 
							END IF 
							
							IF l_rec_batchdetl.for_debit_amt = 0 AND l_rec_batchdetl.for_credit_amt = 0	AND l_rec_batchdetl.stats_qty = 0 THEN 
								CONTINUE FOREACH 
							END IF 

							LET glob_rec_batchhead.seq_num = glob_rec_batchhead.seq_num + 1 
							LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_batchdetl.jour_code = glob_rec_batchhead.jour_code 
							LET l_rec_batchdetl.jour_num = glob_rec_batchhead.jour_num 
							LET l_rec_batchdetl.seq_num = glob_rec_batchhead.seq_num 
							
							IF l_rec_batchdetl.tran_type_ind IS NULL THEN 
								LET l_rec_batchdetl.tran_type_ind = "ADJ" 
							END IF 
							
							IF l_rec_batchdetl.tran_date IS NULL THEN 
								LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
							END IF 
							
							LET l_rec_batchdetl.currency_code = glob_rec_batchhead.currency_code 
							LET l_rec_batchdetl.conv_qty = glob_rec_batchhead.conv_qty 
							LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt /	l_rec_batchdetl.conv_qty 
							LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt /	l_rec_batchdetl.conv_qty
							 
							IF l_rec_batchdetl.for_debit_amt != 0 AND glob_rec_batchhead.source_ind NOT matches "[PR]" THEN 
								CALL check_funds(
									glob_rec_kandoouser.cmpy_code, 
									l_rec_batchdetl.acct_code, 
									l_rec_batchdetl.debit_amt, 
									l_rec_batchdetl.seq_num, 
									glob_rec_batchhead.year_num, 
									glob_rec_batchhead.period_num, 
									"G", 
									glob_rec_batchhead.jour_num, 
									"N") 
								RETURNING 
									l_valid_tran, 
									l_available_amt 

								IF NOT l_valid_tran THEN 
									# Only want TO DISPLAY error MESSAGE once.
									MESSAGE kandoomsg2("U",9939,"") #9939 Capital account(s) have insufficient funds ...
									ROLLBACK WORK 
									RETURN (glob_rec_batchhead.jour_num * -1) 
								END IF 
							END IF 

							IF acct_type(glob_rec_kandoouser.cmpy_code,l_rec_batchdetl.acct_code,COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK,"N") THEN 
								IF l_mode= MODE_CLASSIC_ADD THEN 
									INITIALIZE l_rec_banking.* TO NULL 
									LET l_err_message=" G21a - Insert Banking entry" 
									LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
									LET l_rec_banking.bk_acct = l_rec_batchdetl.acct_code 
									LET l_rec_banking.bk_type = l_rec_batchdetl.tran_type_ind 
									LET l_rec_banking.bk_bankdt = l_rec_batchdetl.tran_date 
									LET l_rec_banking.bk_desc = l_rec_batchdetl.desc_text 
									LET l_rec_banking.bk_sh_no = NULL 
									LET l_rec_banking.bk_seq_no = NULL 
									LET l_rec_banking.bk_rec_part = "N" 
									LET l_rec_banking.bk_year = glob_rec_batchhead.year_num 
									LET l_rec_banking.bk_per = glob_rec_batchhead.period_num 
									LET l_rec_banking.bk_debit = l_rec_batchdetl.for_credit_amt 
									LET l_rec_banking.bk_cred = l_rec_batchdetl.for_debit_amt 
									LET l_rec_banking.bk_enter = glob_rec_batchhead.entry_code 
									LET l_rec_banking.bank_dep_num = glob_rec_batchhead.jour_num 
									LET l_rec_banking.base_debit_amt = l_rec_banking.bk_debit / l_rec_batchdetl.conv_qty 
									LET l_rec_banking.base_cred_amt = l_rec_banking.bk_cred / l_rec_batchdetl.conv_qty 
									LET l_rec_banking.balance_date = NULL 
									LET l_rec_banking.doc_num = 0 

									INSERT INTO banking VALUES (l_rec_banking.*) 

									INITIALIZE l_rec_cbaudit.* TO NULL 
									LET l_err_message=" G21a - Insert Cashbook Audit trail" 
									LET l_rec_cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
									LET l_rec_cbaudit.tran_date = l_rec_batchdetl.tran_date 
									LET l_rec_cbaudit.tran_type_ind = l_rec_batchdetl.tran_type_ind 
									LET l_rec_cbaudit.sheet_num = NULL 
									LET l_rec_cbaudit.line_num = NULL 
									LET l_rec_cbaudit.year_num = glob_rec_batchhead.year_num 
									LET l_rec_cbaudit.period_num = glob_rec_batchhead.period_num 
									LET l_rec_cbaudit.source_num = glob_rec_batchhead.jour_num 
									LET l_rec_cbaudit.tran_text = l_rec_batchdetl.desc_text 

									IF l_rec_batchdetl.credit_amt != 0 THEN 
										LET l_rec_cbaudit.tran_amt = l_rec_batchdetl.credit_amt 
									ELSE 
										LET l_rec_cbaudit.tran_amt = l_rec_batchdetl.debit_amt 
									END IF 

									LET l_rec_cbaudit.entry_code = glob_rec_batchhead.entry_code 

									DECLARE c_bank CURSOR FOR 
									SELECT bank_code FROM bank 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND acct_code = l_rec_batchdetl.acct_code 
									OPEN c_bank 
									FETCH c_bank INTO l_rec_cbaudit.bank_code 
									INSERT INTO cbaudit VALUES (l_rec_cbaudit.*) 

								END IF 
							END IF 

							###
							LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
							LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 

							INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
							DELETE FROM t_batchdetl 
							WHERE username = glob_rec_kandoouser.sign_on_code 
							AND seq_num = l_rec_batchdetl.seq_num 

							LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
							LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
							LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
						END FOREACH 

						# IF the batch header foreign credits = debits THEN we must ensure
						# that the base credits = debits.( They may be some round off in the
						# currency coversion).  Any difference between base debits & credits
						# IS absorbed by the last line of the batch.
						IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt	AND glob_rec_batchhead.debit_amt != glob_rec_batchhead.credit_amt THEN 
							IF l_rec_batchdetl.credit_amt != 0 THEN 
								LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.credit_amt +	(glob_rec_batchhead.debit_amt - glob_rec_batchhead.credit_amt) 
								LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.debit_amt 
							ELSE 
								LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.debit_amt +	(glob_rec_batchhead.credit_amt - glob_rec_batchhead.debit_amt) 
								LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.credit_amt 
							END IF 

							LET l_err_message=" G21a - Update batchdetl" 
							
							UPDATE batchdetl 
							SET 
								credit_amt = l_rec_batchdetl.credit_amt, 
								debit_amt = l_rec_batchdetl.debit_amt 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_num = glob_rec_batchhead.jour_num 
							AND seq_num = glob_rec_batchhead.seq_num 

						END IF
						 
						LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET glob_rec_batchhead.post_flag = "N" 
						
						IF glob_rec_glparms.use_clear_flag = "Y" THEN 
							LET glob_rec_batchhead.cleared_flag = "N" 
						ELSE 
							LET glob_rec_batchhead.cleared_flag = "Y" 
						END IF 
						
						IF l_mode = MODE_CLASSIC_ADD THEN 
							LET l_err_message=" G21a - Insert Batch header"
							#glob_rec_batchhead.source_ind = 'G'
							INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 
						ELSE 
							LET l_err_message=" G21a - Update Batch header" 
							UPDATE batchhead SET * = glob_rec_batchhead.* 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_num = glob_rec_batchhead.jour_num 
						END IF 
	COMMIT WORK 
	WHENEVER ERROR STOP 

					#	IF glob_rec_batchhead.for_debit_amt != glob_rec_batchhead.for_credit_amt THEN
					#		LET l_msg = "Unbal"anced batch\nDebit=", trim(glob_rec_batchhead.for_debit_amt), "\nCredit=", trim(glob_rec_batchhead.for_credit_amt)
					#		CALL fgl_winmessage("Batch is unbalanced",l_msg,"error")
					#		ERROR l_msg
					#	ELSE
					#		LET l_msg = "Correctly Balanced batch\nDebit=", trim(glob_rec_batchhead.for_debit_amt), "\nCredit=", trim(glob_rec_batchhead.for_credit_amt)
					#		MESSAGE l_msg
					#	END IF

					RETURN glob_rec_batchhead.jour_num 
END FUNCTION 
############################################################
# END FUNCTION G21a_write_gl_batch(l_mode)
############################################################


############################################################
# FUNCTION enter_disburse()
# Oh yes, totally useless commments here!
#
############################################################
FUNCTION enter_disburse() 
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_s_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_debit_amt LIKE batchdetl.for_debit_amt 
	DEFINE l_credit_amt LIKE batchdetl.for_credit_amt 
	DEFINE l_temp_text char(40) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW G465 with FORM "G465" 
	CALL windecoration_g("G465") 

	MESSAGE kandoomsg2("G",1040,"") #G1040 Enter disbursment Info
	INPUT 
		l_rec_disbhead.disb_code, 
		l_debit_amt, 
		l_credit_amt WITHOUT DEFAULTS 
	FROM 
		disb_code, 
		debit_amt, 
		credit_amt attributes (unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G21a","input-disburse") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (disb_code) 
			LET l_temp_text = show_disb(glob_rec_kandoouser.cmpy_code,"") 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_disbhead.disb_code = l_temp_text 
				NEXT FIELD disb_code 
			END IF 

		AFTER FIELD disb_code 
			CLEAR desc_text 
			
			IF l_rec_disbhead.disb_code IS NULL THEN 
				MESSAGE kandoomsg2("G",9045,"") #G9045 "Must enter a disbursement code"
				NEXT FIELD disb_code 
			
			ELSE
			 
				SELECT * INTO l_rec_disbhead.* 
				FROM disbhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND disb_code = l_rec_disbhead.disb_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("G",9046,"") #G9046 "Disbursement Code does NOT exist"
					NEXT FIELD disb_code 
				
				ELSE 
				
					IF l_rec_disbhead.dr_cr_ind = DISBURSE_CDB_CREDIT_1 THEN #IF Disburse Credit
						LET l_debit_amt = NULL 
						
						IF glob_rec_glparms.control_tot_flag = "Y" THEN 
							LET l_credit_amt = glob_rec_batchhead.control_amt - glob_rec_batchhead.for_credit_amt 
						ELSE 
							LET l_credit_amt = glob_rec_batchhead.for_debit_amt - glob_rec_batchhead.for_credit_amt 
						END IF 
						
						IF l_credit_amt < 0 THEN 
							LET l_debit_amt = 0 - l_credit_amt 
							LET l_credit_amt = NULL 
						END IF 
					ELSE 
						LET l_credit_amt = NULL
						 
						IF glob_rec_glparms.control_tot_flag = "Y" THEN 
							LET l_debit_amt = glob_rec_batchhead.control_amt- glob_rec_batchhead.for_debit_amt 
						ELSE 
							LET l_debit_amt = glob_rec_batchhead.for_credit_amt	- glob_rec_batchhead.for_debit_amt 
						END IF 
						
						IF l_debit_amt < 0 THEN 
							LET l_credit_amt = 0 - l_debit_amt 
							LET l_debit_amt = NULL 
						END IF 
					END IF 
					 
					DISPLAY l_rec_disbhead.desc_text TO desc_text
					DISPLAY l_debit_amt TO debit_amt
					DISPLAY l_credit_amt TO credit_amt 
				END IF 
			END IF 

		AFTER FIELD debit_amt 
			IF l_debit_amt IS NOT NULL AND l_debit_amt < 0 THEN 
				ERROR kandoomsg2("G",9044,"") #G9044 Must enter a positive amount"
				NEXT FIELD debit_amt 
			END IF 

		BEFORE FIELD credit_amt 
			IF l_debit_amt IS NOT NULL AND l_debit_amt > 0 THEN 
				LET l_credit_amt = NULL 
				EXIT INPUT 
			END IF 

		AFTER FIELD credit_amt 
			IF l_credit_amt IS NOT NULL AND l_credit_amt < 0 THEN 
				ERROR kandoomsg2("G",9044,"") #G9044 Must enter a positive amount"
				NEXT FIELD credit_amt 
			END IF 

		AFTER INPUT 
			IF l_debit_amt IS NOT NULL AND l_debit_amt > 0 THEN 
				LET l_credit_amt = 0 
			ELSE 
				LET l_debit_amt = 0 
			END IF 

	END INPUT 

	CLOSE WINDOW g465 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 

		IF l_rec_disbhead.acct_code IS NOT NULL THEN 
			IF kandoomsg("G",8014,l_rec_disbhead.acct_code) = "Y" THEN		#8014 Confirm TO create balancing disbursement entry TO A/C 123"
				LET l_rec_s_batchdetl.for_credit_amt = 0 
				LET l_rec_s_batchdetl.for_debit_amt = 0 
			END IF 
		END IF 

		SELECT max(seq_num) 
		INTO glob_rec_batchhead.seq_num 
		FROM t_batchdetl 

		IF glob_rec_batchhead.seq_num IS NULL THEN 
			LET glob_rec_batchhead.seq_num = 0 
		END IF 

		DECLARE c_disbdetl CURSOR FOR 
		SELECT * FROM disbdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND disb_code = l_rec_disbhead.disb_code 
		ORDER BY 2,3 

		FOREACH c_disbdetl INTO l_rec_disbdetl.* 
			
			INITIALIZE l_rec_batchdetl.* TO NULL 
			
			LET glob_rec_batchhead.seq_num = glob_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = glob_rec_batchhead.seq_num 
			LET l_rec_batchdetl.acct_code = l_rec_disbdetl.acct_code 
			LET l_rec_batchdetl.desc_text = l_rec_disbdetl.desc_text 
			LET l_rec_batchdetl.ref_text = l_rec_disbdetl.disb_code 
			LET l_rec_batchdetl.analysis_text = l_rec_disbdetl.analysis_text 
			LET l_rec_batchdetl.for_credit_amt = l_credit_amt	* (l_rec_disbdetl.disb_qty/l_rec_disbhead.total_qty) 
			
			IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
				LET l_rec_batchdetl.for_credit_amt = 0 
			END IF
			 
			LET l_rec_batchdetl.for_debit_amt = l_debit_amt * (l_rec_disbdetl.disb_qty/l_rec_disbhead.total_qty)
			 
			IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
				LET l_rec_batchdetl.for_debit_amt = 0 
			END IF
			 
			LET l_rec_batchdetl.stats_qty = 0 

			IF get_debug() THEN 
				DISPLAY "INSERT 2 batchdetl" 
				DISPLAY "cmpy_code=", glob_rec_batchhead.cmpy_code 

				DISPLAY "seq_num=", l_rec_batchdetl.seq_num 
				DISPLAY "acct_code=", l_rec_batchdetl.acct_code 
				DISPLAY "analysis_text=", l_rec_batchdetl.analysis_text 
				DISPLAY "for_debit_amt=", l_rec_batchdetl.for_debit_amt 
				DISPLAY "for_credit_amt=", l_rec_batchdetl.for_credit_amt 
				DISPLAY "stats_qty=", l_rec_batchdetl.stats_qty 
				DISPLAY "ref_text=", l_rec_batchdetl.ref_text 
				DISPLAY "desc_text=", l_rec_batchdetl.desc_text 

				DISPLAY "jour_code=", glob_rec_batchhead.jour_code 
				DISPLAY "sign_on_code=", glob_rec_kandoouser.sign_on_code 
			END IF 

			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			IF sqlca.sqlcode != 0 THEN 
				ERROR "Could not insert this row" 
			END IF 

			LET l_rec_s_batchdetl.for_credit_amt = l_rec_s_batchdetl.for_credit_amt + l_rec_batchdetl.for_debit_amt 
			LET l_rec_s_batchdetl.for_debit_amt = l_rec_s_batchdetl.for_debit_amt + l_rec_batchdetl.for_credit_amt 

		END FOREACH 

		IF l_rec_s_batchdetl.for_credit_amt > 0 OR l_rec_s_batchdetl.for_debit_amt > 0 THEN 
			
			INITIALIZE l_rec_batchdetl.* TO NULL 
			
			LET glob_rec_batchhead.seq_num = glob_rec_batchhead.seq_num + 1 
			LET l_rec_s_batchdetl.seq_num = glob_rec_batchhead.seq_num 
			LET l_rec_s_batchdetl.acct_code = l_rec_disbhead.acct_code 
			LET l_rec_s_batchdetl.desc_text = l_rec_disbhead.desc_text 
			LET l_rec_s_batchdetl.ref_text = l_rec_disbhead.disb_code
			 
			IF l_rec_s_batchdetl.for_credit_amt IS NULL THEN 
				LET l_rec_s_batchdetl.for_credit_amt = 0 
			END IF
			 
			IF l_rec_s_batchdetl.for_debit_amt IS NULL THEN 
				LET l_rec_s_batchdetl.for_debit_amt = 0 
			END IF
			 
			LET l_rec_s_batchdetl.stats_qty = 0
			 
			INSERT INTO t_batchdetl VALUES (l_rec_s_batchdetl.*, glob_rec_kandoouser.sign_on_code)			 
			IF sqlca.sqlcode != 0 THEN 
				ERROR "Could not insert this row" 
			END IF 
			
		END IF 

		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION enter_disburse()
############################################################


############################################################
# FUNCTION retrieve_unsaved_batch (p_query_text)
#
#
############################################################
FUNCTION retrieve_unsaved_batch (p_query_text,p_delete) 
	DEFINE p_query_text STRING 
	DEFINE p_delete boolean 
	DEFINE l_arr_rec_batchdetl DYNAMIC ARRAY OF t_rec_batchdetl 
	DEFINE l_rec_temp_batchdetl OF t_rec_temp_batchdetl 
	DEFINE l_rows_number SMALLINT #do we NEED this one ? 
	DEFINE l_sign_on_code LIKE kandoouser.sign_on_code 

	LET l_sign_on_code = glob_rec_kandoouser.sign_on_code 
	--scroll_flag char(1),
	--seq_num LIKE batchdetl.seq_num,
	--acct_code LIKE batchdetl.acct_code,
	--analysis_text LIKE batchdetl.analysis_text,
	--for_debit_amt LIKE batchdetl.for_debit_amt,
	--for_credit_amt LIKE batchdetl.for_credit_amt,
	--stats_qty LIKE batchdetl.stats_qty,
	--uom_code LIKE coa.uom_code,
	--ref_text LIKE batchdetl.ref_text, # #ali feature request
	--desc_text LIKE batchdetl.desc_text
	--END RECORD

	IF p_delete THEN 
		CALL db_t_batchdetl_delete_all() 
	END IF 

	#delete invalid rows from table before processing
	DELETE FROM t_batchdetl WHERE (seq_num = 0 OR seq_num IS null) AND username = l_sign_on_code 
	DELETE FROM t_batchdetl WHERE (acct_code IS null) AND username = l_sign_on_code 

	DELETE FROM t_batchdetl 
	WHERE (debit_amt = 0 OR debit_amt IS null) 
	AND (credit_amt = 0 OR credit_amt IS null) 
	AND (for_debit_amt = 0 OR for_debit_amt IS null) 
	AND (for_credit_amt = 0 OR for_credit_amt IS null) 
	AND username = l_sign_on_code 

	--	#We need more properties in this static temp table to manage it - otherwise, we will get the same query for EDIT
	--	IF db_t_batchdetl_get_count() > 0 THEN
	--		IF NOT promptTF("Batch data found","Batch data session exist!\nDo you want to use them ?",FALSE) THEN
	--		CALL db_t_batchdetl_delete_all()
	--		CALL l_arr_rec_batchdetl.clear()
	--		END IF
	--
	--	ELSE

	PREPARE p_t_batchdetl FROM p_query_text 
	DECLARE c_t_batchdetl CURSOR FOR p_t_batchdetl 

	--	LET rows_number = 0
	LET l_rows_number = 0 
	# look in the 'uncompleted batches personal tank' if there is some batch


	FOREACH c_t_batchdetl INTO l_rec_temp_batchdetl 
		LET l_rows_number = l_rows_number + 1 
		{		IF
					(
						(l_rec_batchdetl.seq_num = 0) OR (l_rec_batchdetl.seq_num IS NULL)
					) #if seq_number is 0 or NULL, empty row

					OR

					(
						(l_rec_batchdetl.for_debit_amt = 0) OR (l_rec_batchdetl.for_debit_amt IS NULL)
					AND
						(l_rec_batchdetl.for_credit_amt = 0) OR (l_rec_batchdetl.for_credit_amt IS NULL)
					)  #error check for debit/credit = 0
				THEN
					CALL l_arr_rec_batchdetl.deleteElement(rows_number)
					LET rows_number = rows_number - 1			#not really required
					EXIT FOREACH
				ELSE
					LET rows_number = rows_number + 1
				END IF
		}

		LET l_arr_rec_batchdetl[l_rows_number].seq_num = l_rec_temp_batchdetl.seq_num 
		LET l_arr_rec_batchdetl[l_rows_number].acct_code = l_rec_temp_batchdetl.acct_code 
		LET l_arr_rec_batchdetl[l_rows_number].analysis_text = l_rec_temp_batchdetl.analysis_text 
		LET l_arr_rec_batchdetl[l_rows_number].for_debit_amt = l_rec_temp_batchdetl.for_debit_amt 
		LET l_arr_rec_batchdetl[l_rows_number].for_credit_amt = l_rec_temp_batchdetl.for_credit_amt 
		LET l_arr_rec_batchdetl[l_rows_number].stats_qty = l_rec_temp_batchdetl.stats_qty 
		LET l_arr_rec_batchdetl[l_rows_number].uom_code = l_rec_temp_batchdetl.uom_code 
		LET l_arr_rec_batchdetl[l_rows_number].ref_text = l_rec_temp_batchdetl.ref_text 
		LET l_arr_rec_batchdetl[l_rows_number].desc_text = l_rec_temp_batchdetl.desc_text 


		--	INTO l_arr_rec_batchdetl[rows_number].seq_num,
		--		l_arr_rec_batchdetl[rows_number].acct_code,
		--		l_arr_rec_batchdetl[rows_number].analysis_text,
		--		l_arr_rec_batchdetl[rows_number].for_debit_amt,
		--		l_arr_rec_batchdetl[rows_number].for_credit_amt,
		--		l_arr_rec_batchdetl[rows_number].stats_qty,
		--		l_arr_rec_batchdetl[rows_number].uom_code,
		--		l_arr_rec_batchdetl[rows_number].ref_text,
		--		l_arr_rec_batchdetl[rows_number].desc_text

		--		IF ((l_arr_rec_batchdetl[rows_number].seq_num = 0) OR (l_arr_rec_batchdetl[rows_number].seq_num IS NULL)) #if seq_number is 0 or NULL, empty row
		--			OR ((l_arr_rec_batchdetl[rows_number].for_debit_amt = 0) AND (l_arr_rec_batchdetl[rows_number].for_credit_amt = 0))  #error check for debit/credit = 0
		--		THEN
		--			CALL l_arr_rec_batchdetl.deleteElement(rows_number)
		--			LET rows_number = rows_number - 1			#not really required
		--			EXIT FOREACH
		--		ELSE

		--		END IF
	END FOREACH 

	IF l_arr_rec_batchdetl.getsize() > 0 THEN 
		CALL display_batch_balance(l_arr_rec_batchdetl) #check instantly, IF the batch IS balanced 
	END IF 
	--	END IF  #END IF uer wants to use the found temp data from previous session

	RETURN l_arr_rec_batchdetl 
END FUNCTION 
############################################################
# END FUNCTION retrieve_unsaved_batch (p_query_text)
############################################################


############################################################
# FUNCTION batch_line_validation(p_entry_line,p_analy_req_flag,p_step_number) 
# inbound params:
# 	p_entry_line: the array line
#	p_step_number: 1 check if no debit and credit value>0 at the same time
#				 2 step 1 plus quantity not null or 0
############################################################
FUNCTION batch_line_validation(p_entry_line,p_analy_req_flag,p_step_number) 
	DEFINE p_entry_line t_rec_batchdetl 
	DEFINE p_step_number SMALLINT 
	DEFINE p_analy_req_flag CHAR(1) 
	DEFINE l_error_num INTEGER 
	DEFINE a SMALLINT 

	IF p_entry_line.for_debit_amt IS NOT NULL AND p_entry_line.for_debit_amt != 0 THEN 
		#some amount was entered
		IF p_entry_line.for_credit_amt IS NOT NULL AND p_entry_line.for_credit_amt != 0 THEN 
			# debit amount has a value AND credit amount has a value: forbidden
			RETURN 9050 
		END IF 
	END IF 

	IF (p_entry_line.for_debit_amt IS NOT NULL AND p_entry_line.for_debit_amt < 0 ) THEN 
		RETURN 9044 
		#G9044 " Amount must be positive "
	END IF 

	IF p_entry_line.for_debit_amt = 0 AND p_entry_line.for_credit_amt = 0 THEN 
		RETURN 9044 
		#G9044 " Amount must be positive "
	END IF 
	
	IF p_entry_line.analysis_text IS NULL	AND p_analy_req_flag = "Y" THEN 
		CALL fgl_winmessage("Error","Analysis is applied to this account which requires a corresponding Analysis Text","ERROR")
		ERROR "Analysis is applied to this account which requires a corresponding Analysis Text"
		SLEEP 2
		RETURN 9701 #huho was RETURN 9016 ??? changed to 9701, a new message  
		#9016 Analysis IS required.
		#P|9016|ENG|9|5|Analysis is required.||0|||
		#G|9051|ENG|9|5|Account analysis is required.||0|||
	END IF 

	IF p_step_number >= 2 THEN 
		IF (p_entry_line.stats_qty = 0 OR p_entry_line.stats_qty IS null) THEN 
			IF p_entry_line.uom_code IS NOT NULL AND p_analy_req_flag ="Y" THEN # there should be a parameter that states stats_qty IS mandatory 
				#RETURN true .. this can not work ! we need a real error code or nothing
				CALL fgl_winmessage("Error","Analysis is applied to this account which requires a valid UOM-Quantity value","ERROR")
				ERROR "Analysis is applied to this account which requires a valid UOM-Quantity value"
				
				SLEEP 2
				RETURN 9702 #huho was RETURN TRUE??? changed to 9702, a new message  
			END IF 
		END IF 
	END IF 

	RETURN false 
END FUNCTION 
############################################################
# END FUNCTION batch_line_validation:
############################################################