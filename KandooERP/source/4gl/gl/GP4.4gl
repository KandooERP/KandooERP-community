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

###########################################################################
# \brief module GP4  Create journal batch closing Income AND Expense Account
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_rec_coa RECORD LIKE coa.* 
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.* 
	--DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE modu_rec_period RECORD LIKE period.* 
	DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE modu_rec_account RECORD LIKE account.* 
 
	DEFINE modu_rec_structure RECORD LIKE structure.* 
	DEFINE modu_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD 
		year_num SMALLINT, 
		period_num SMALLINT 
	END RECORD 
	DEFINE modu_arr_rec_coa DYNAMIC ARRAY OF RECORD 
		flex_code LIKE validflex.flex_code, 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text 
	END RECORD 
	DEFINE modu_err_message CHAR(40) 
	DEFINE modu_net_worth_acct LIKE account.acct_code
	DEFINE modu_net_worth_flex LIKE validflex.flex_code 
	DEFINE modu_ofs_debit money(15,2)
	DEFINE modu_ofs_credit money(15,2)
	DEFINE modu_fisc_year SMALLINT
	DEFINE modu_idx SMALLINT
	DEFINE modu_tempper SMALLINT	
	DEFINE modu_ledg_cnt SMALLINT
	DEFINE modu_multiledger_ind SMALLINT
	DEFINE modu_start_num SMALLINT
	DEFINE modu_length SMALLINT
	DEFINE modu_sel_text CHAR(800) 

###########################################################################
# FUNCTION GP4_main()
#
#
###########################################################################
FUNCTION GP4_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	OPEN WINDOW G161 with FORM "G161" 
	CALL windecoration_g("G161") 

	LET modu_multiledger_ind = true 
	
	SELECT * INTO modu_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET modu_multiledger_ind = false 
	ELSE 
		LET modu_start_num = modu_rec_structure.start_num 
		LET modu_length = modu_rec_structure.start_num + modu_rec_structure.length_num - 1 
	END IF 
	
	SELECT use_currency_flag INTO glob_rec_glparms.use_currency_flag FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("Error #5007",kandoomsg2("G",5007,""),"ERROR") 	#5007 " General Ledger Parametere Not Set Up"
	ELSE 
		WHILE get_info() 
		END WHILE 
	END IF 

	CLOSE WINDOW G161 

END FUNCTION   
###########################################################################
# END FUNCTION GP4_main() 
###########################################################################


###########################################################################
# FUNCTION get_info()
#
#
###########################################################################
FUNCTION get_info() 
	DEFINE l_where_part STRING 
	DEFINE l_runner CHAR(40) 
	DEFINE l_i SMALLINT 
	DEFINE l_arg_str1 STRING 
	DEFINE l_arg_str2 STRING 
	
	FOR l_i = 1 TO 12 
		CLEAR sr_period[l_i].year_num 
		CLEAR sr_period[l_i].period_num 
	END FOR
	 
	MESSAGE kandoomsg2("G",1048,"") 	#1048 " Enter offset account - ESC TO Continue
	INPUT BY NAME modu_rec_coa.acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GP4","inp-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET modu_rec_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME modu_rec_coa.acct_code 

			NEXT FIELD acct_code 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF NOT modu_multiledger_ind THEN 
				IF modu_rec_coa.acct_code IS NULL THEN 
					ERROR kandoomsg2("G",9132,"") 				#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct_code 
				END IF 
			END IF 
			IF modu_rec_coa.acct_code IS NULL THEN 
				LET modu_rec_coa.desc_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_rec_coa.acct_code 
				AND type_ind = "N" 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9132,"") 				#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct_code 
				END IF 
			END IF
			 
			LET modu_net_worth_acct = modu_rec_coa.acct_code 
			DISPLAY modu_rec_coa.acct_code TO acct_code 
			DISPLAY modu_rec_coa.desc_text TO desc_text 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_part ON 
		year_num, 
		period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GP4","construct-year") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
			 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN true 
	END IF 
	
	MESSAGE kandoomsg2("U",1002,"") 	#1002 " Searching database - please wait"

	LET modu_sel_text = 
		"SELECT unique year_num, period_num FROM accounthist ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_part clipped," ", 
		"ORDER BY year_num, period_num " 

	PREPARE getper FROM modu_sel_text 
	DECLARE c_per CURSOR FOR getper 

	LET modu_idx = 0 
	FOREACH c_per INTO modu_rec_period.year_num, modu_rec_period.period_num 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_period[modu_idx].year_num = modu_rec_period.year_num 
		LET modu_arr_rec_period[modu_idx].period_num = modu_rec_period.period_num 
	END FOREACH 

	IF modu_idx = 0 THEN 
		ERROR kandoomsg2("G",9134,"") 	#9133 " No Periods satisfied selection criteria
	END IF 

	ERROR kandoomsg2("G",1034,"")	#1034 " RETURN on line TO Close

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GP4","inp-arr-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#LET scrn = scr_line()

		AFTER FIELD year_num 
			IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() = arr_count() THEN 
				ERROR kandoomsg2("U",9001,"") #9001 " No more rows in the direction you are going"
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD period_num 
			LET modu_tempper = modu_arr_rec_period[modu_idx].period_num 
			LET modu_fisc_year = modu_arr_rec_period[modu_idx].year_num
			 
			SELECT unique 1 FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_fisc_year 
			AND period_num = modu_tempper 
			AND post_flag = "N" 
			IF status <> NOTFOUND THEN 
				ERROR kandoomsg2("G",9085,"") 
				CALL run_prog("GP2","","","","") 
				NEXT FIELD year_num 
			END IF 

			MESSAGE kandoomsg2("U",1002,"")	#1002 Searching Database - please wait"
			# check anything TO close
			IF glob_rec_glparms.use_currency_flag = "Y" THEN 
				SELECT unique 1 FROM accounthistcur h, coa c 
				WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND h.year_num = modu_fisc_year 
				AND h.period_num = modu_tempper 
				AND (H.close_amt != 0 OR h.base_close_amt != 0) 
				AND h.acct_code = c.acct_code 
				AND c.type_ind in ("l_i","E") 
				IF status <> NOTFOUND THEN 
					IF modu_multiledger_ind THEN 
						IF NOT setup_ledg() THEN 
							# Deleted out of Networth Ledger setup
							MESSAGE kandoomsg2("G",1034,"") 			#1034 " RETURN on line TO Close
							NEXT FIELD year_num 
						ELSE 
							MESSAGE kandoomsg2("U",1005,"")							#1005 Updating database
							FOR l_i = 1 TO modu_ledg_cnt 
								LET modu_net_worth_flex = modu_arr_rec_coa[l_i].flex_code 
								LET modu_net_worth_acct = modu_arr_rec_coa[l_i].acct_code 
								CALL post_closing_curr() 
							END FOR 
						END IF 
					ELSE 
						CALL post_closing_curr() 
					END IF 
				ELSE 
					ERROR kandoomsg2("G",9086,"")
					SLEEP 3 #???? double message ????? 
					MESSAGE kandoomsg2("G",1034,"") 		#1034 " RETURN on line TO Close
					NEXT FIELD year_num 
				END IF 
			ELSE 
				SELECT unique 1 FROM accounthist h, coa c 
				WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND h.year_num = modu_fisc_year 
				AND h.period_num = modu_tempper 
				AND h.close_amt <> 0 
				AND h.acct_code = c.acct_code 
				AND c.type_ind in ("l_i","E") 
				IF status <> NOTFOUND THEN 
					IF modu_multiledger_ind THEN 
						IF NOT setup_ledg() THEN 
							# Deleted out of Networth Ledger setup
							MESSAGE kandoomsg2("G",1034,"") 				#1034 " RETURN on line TO Close
							NEXT FIELD year_num 
						ELSE 
							MESSAGE kandoomsg2("U",1005,"") 						#1005 Updating database
							FOR l_i = 1 TO modu_ledg_cnt 
								LET modu_net_worth_flex = modu_arr_rec_coa[l_i].flex_code 
								LET modu_net_worth_acct = modu_arr_rec_coa[l_i].acct_code 
								CALL do_close() 
							END FOR 
						END IF 
					ELSE 
						CALL do_close() 
					END IF 
				ELSE 
					ERROR kandoomsg2("G",9087,"")				#9087 "No need TO close period, no Income OR Expense VALUES "
					SLEEP 3 #double message ?
					MESSAGE kandoomsg2("G",1034,"") 			#1034 " RETURN on line TO Close
					NEXT FIELD year_num 
				END IF 
			END IF 

			LET l_arg_str1 = "FISCAL_YEAR_NUM=", trim(modu_fisc_year) 
			LET l_arg_str2 = "modu_tempper=", trim(modu_tempper) 

			--         CALL run_prog("GP2","y",modu_fisc_year,modu_tempper,"")
			CALL run_prog("GP2","AUTOPOST=y",l_arg_str1,l_arg_str2,"") 

			MESSAGE kandoomsg2("G",1034,"") 	#1034 " RETURN on line TO Close
			NEXT FIELD year_num 
	END INPUT 

	LET quit_flag = false 
	LET int_flag = false 
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION get_info()
###########################################################################


############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION do_close() 
	DEFINE l_counter INTEGER 
	DEFINE l_sum_bal money(15,2) 
	DEFINE l_sum_deb money(15,2) 
	DEFINE l_sum_cred money(15,2) 

	GOTO bypass 
	LABEL recovery: 
	
	IF error_recover (modu_err_message, status)  != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 
		LOCK TABLE glparms in share MODE 
		LOCK TABLE accounthist in share MODE 
		LOCK TABLE batchhead in share MODE 
		LOCK TABLE batchdetl in share MODE 

		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		INITIALIZE modu_rec_batchhead.* TO NULL 

		LET modu_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
		LET modu_rec_batchhead.entry_code = "GL" 
		LET modu_rec_batchhead.cleared_flag = "Y" 
		LET modu_rec_batchhead.jour_date = today 
		LET modu_rec_batchhead.period_num = modu_tempper 
		LET modu_rec_batchhead.post_flag = "N" 
		LET modu_rec_batchhead.com1_text = "Automatic Closing Entries" 
		LET modu_rec_batchhead.control_amt = 0 
		LET modu_rec_batchhead.debit_amt = 0 
		LET modu_rec_batchhead.credit_amt = 0 
		LET modu_rec_batchhead.control_qty = 0 
		LET modu_rec_batchhead.stats_qty = 0 
		LET modu_rec_batchhead.for_debit_amt = 0 
		LET modu_rec_batchhead.for_credit_amt = 0 
		LET modu_rec_batchhead.year_num = modu_fisc_year 
		LET modu_rec_batchhead.seq_num = 1 
		LET modu_rec_batchhead.source_ind = "G" 
		LET modu_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
		LET modu_rec_batchhead.conv_qty = 1.0 
		LET modu_rec_batchhead.rate_type_ind = "U" 
		LET modu_sel_text = 
			"SELECT account.*, coa.* FROM account, coa", 
			" WHERE account.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
			" AND coa.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
			" AND account.year_num = '",modu_fisc_year,"'", 
			" AND account.acct_code = coa.acct_code", 
			" AND coa.type_ind <> 'A'", 
			" AND coa.type_ind <> 'L'", 
			" AND coa.type_ind <> 'N'" 
		IF modu_multiledger_ind THEN 
			LET modu_sel_text = 
				modu_sel_text clipped, 
				" AND coa.acct_code[",modu_start_num USING "&&",",", 
				modu_length USING "&&","] = '",modu_net_worth_flex,"'" 
		END IF
		 
		LET modu_ofs_debit = 0 
		LET modu_ofs_credit = 0 
		LET l_counter = 0 

		PREPARE acct_state FROM modu_sel_text 
		DECLARE acctcurs CURSOR FOR acct_state 
		FOREACH acctcurs INTO modu_rec_account.*, modu_rec_coa.* 
			# TO allow correct postings TO past periods the the bal_amt
			# IS SET TO the sum of the accountledger FOR that period
			# You must NOT delete off any accountledger FOR that year, OR
			# AT the worst only an equal amount of credits AND debits
			# changed TO accounthist speed up SMC request

			SELECT sum(debit_amt), sum(credit_amt) INTO l_sum_deb, l_sum_cred 
			FROM accounthist 
			WHERE cmpy_code = modu_rec_account.cmpy_code 
			AND acct_code = modu_rec_account.acct_code 
			AND year_num = modu_rec_account.year_num 
			AND period_num = modu_tempper 

			INITIALIZE modu_rec_batchdetl.* TO NULL 

			LET l_sum_bal = l_sum_deb - l_sum_cred 
			IF l_sum_bal != 0 THEN 
				IF l_counter = 0 THEN 
					#ie Found an account FOR this ledger with non zero balance
					#   Therefore, allocate next batch number...
					LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
					LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
					UPDATE glparms 
					SET next_jour_num = glob_rec_glparms.next_jour_num, 
					last_close_date = today 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
				END IF 

				IF l_sum_bal < 0 THEN 
					LET modu_ofs_debit = modu_ofs_debit - l_sum_bal 
				ELSE 
					LET modu_ofs_credit = modu_ofs_credit + l_sum_bal 
				END IF 
				LET modu_rec_batchdetl.tran_type_ind = "CL" 

				IF l_sum_bal < 0 THEN 
					LET modu_rec_batchdetl.debit_amt = 0 - l_sum_bal 
					LET modu_rec_batchdetl.credit_amt = 0 
				ELSE 
					LET modu_rec_batchdetl.credit_amt = l_sum_bal 
					LET modu_rec_batchdetl.debit_amt = 0 
				END IF 

				IF modu_rec_batchdetl.credit_amt IS NULL THEN 
					LET modu_rec_batchdetl.credit_amt = 0 
				END IF 

				IF modu_rec_batchdetl.debit_amt IS NULL THEN 
					LET modu_rec_batchdetl.debit_amt = 0 
				END IF 
				LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_batchdetl.acct_code = modu_rec_account.acct_code 
				LET modu_rec_batchdetl.desc_text = "Closing Entry" 
				LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.debit_amt 
				LET modu_rec_batchdetl.for_credit_amt = modu_rec_batchdetl.credit_amt 

				CALL setup() 

				INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 

				LET l_counter = l_counter + 1 
			END IF 
		END FOREACH 

		IF l_counter > 0 THEN 
			IF modu_ofs_debit <> modu_ofs_credit THEN 
				INITIALIZE modu_rec_batchdetl.* TO NULL 

				CALL setup_offset() 
				CALL setup() 

				INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 

			END IF 

			IF modu_rec_batchhead.debit_amt <> modu_rec_batchhead.credit_amt THEN 
				MESSAGE "Debit: ", modu_rec_batchhead.debit_amt, " Credits:",	modu_rec_batchhead.credit_amt 
				SLEEP 5 

				IF promptTF("",kandoomsg2("G",8016,""),1)	THEN

					CALL fgl_winmessage("16 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 

					INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
				ELSE 
					ROLLBACK WORK 
					RETURN 
				END IF 
				
			ELSE 
			
				LET modu_rec_batchhead.control_amt = modu_rec_batchhead.debit_amt 
				CALL fgl_winmessage("17 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 

				INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 

			END IF 
		END IF 

	COMMIT WORK 
	WHENEVER ERROR 
	CONTINUE 

END FUNCTION 
############################################################
# END FUNCTION get_info()
############################################################


############################################################
# FUNCTION setup()
#
#
############################################################
FUNCTION setup() 

	LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchdetl.stats_qty = 0 
	LET modu_rec_batchhead.debit_amt = modu_rec_batchhead.debit_amt +	modu_rec_batchdetl.debit_amt 
	LET modu_rec_batchhead.credit_amt = modu_rec_batchhead.credit_amt +	modu_rec_batchdetl.credit_amt 
	LET modu_rec_batchhead.for_debit_amt = modu_rec_batchhead.for_debit_amt +	modu_rec_batchdetl.for_debit_amt 
	LET modu_rec_batchhead.for_credit_amt = modu_rec_batchhead.for_credit_amt +	modu_rec_batchdetl.for_credit_amt 
	LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
	LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
	LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 
	LET modu_rec_batchdetl.tran_date = today 
	LET modu_rec_batchdetl.currency_code = modu_rec_batchhead.currency_code 
END FUNCTION 
############################################################
# END FUNCTION setup()
############################################################


############################################################
# FUNCTION setup_offset()
#
#
############################################################
FUNCTION setup_offset() 

	LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchdetl.tran_type_ind = "CL" 
	LET modu_rec_batchdetl.acct_code = modu_net_worth_acct 
	LET modu_rec_batchdetl.desc_text = "Closing Entry Offset" 
	IF modu_ofs_credit > modu_ofs_debit THEN 
		LET modu_rec_batchdetl.debit_amt = modu_ofs_credit - modu_ofs_debit 
		LET modu_rec_batchdetl.credit_amt = 0 
	ELSE 
		LET modu_rec_batchdetl.credit_amt = modu_ofs_debit - modu_ofs_credit 
		LET modu_rec_batchdetl.debit_amt = 0 
	END IF 
	LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.debit_amt 
	LET modu_rec_batchdetl.for_credit_amt = modu_rec_batchdetl.credit_amt 
END FUNCTION 
############################################################
# END FUNCTION setup_offset()
############################################################


############################################################
# FUNCTION post_closing_curr()
#
#
############################################################
FUNCTION post_closing_curr() 
	DEFINE l_prev_currency LIKE batchhead.currency_code 
	DEFINE for_post_balance LIKE batchhead.currency_code 
	DEFINE base_post_balance LIKE batchdetl.debit_amt 

	GOTO bypass 
	LABEL recovery: 

	IF error_recover (modu_err_message, status) != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	LET modu_sel_text = 
		"SELECT H.* FROM accounthistcur H, coa C", 
		" WHERE H.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
		" AND C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
		" AND H.year_num = '",modu_fisc_year,"'", 
		" AND H.period_num = '",modu_tempper,"'", 
		" AND H.acct_code = C.acct_code", 
		" AND C.type_ind <> 'A'", 
		" AND C.type_ind <> 'L'", 
		" AND C.type_ind <> 'N'", 
		" AND (H.close_amt != 0 OR H.base_close_amt != 0)" 

	IF modu_multiledger_ind THEN 
		LET modu_sel_text = modu_sel_text clipped, " AND C.acct_code[",modu_start_num USING "&&",",", modu_length USING "&&","] = '",modu_net_worth_flex,"'", " ORDER BY H.currency_code " 
	ELSE 
		LET modu_sel_text = modu_sel_text clipped,	" ORDER BY H.currency_code " 
	END IF 

	PREPARE close_curr FROM modu_sel_text 
	DECLARE close_curr_curs CURSOR FOR close_curr 

	BEGIN WORK 
		LOCK TABLE glparms in share MODE 
		LOCK TABLE accounthistcur in share MODE 
		LOCK TABLE batchhead in share MODE 
		LOCK TABLE batchdetl in share MODE 

		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		CALL set_up_header() 
		CALL set_up_detail() 
		LET l_prev_currency = NULL 

		FOREACH close_curr_curs INTO modu_rec_accounthistcur.* 
			IF l_prev_currency IS NULL THEN 
				CALL new_batch(modu_rec_accounthistcur.currency_code) 
				LET l_prev_currency = modu_rec_accounthistcur.currency_code 
			ELSE 
				IF modu_rec_accounthistcur.currency_code != l_prev_currency THEN 
					CALL finish_batch() 
					CALL new_batch(modu_rec_accounthistcur.currency_code) 
					LET l_prev_currency = modu_rec_accounthistcur.currency_code 
				END IF 

			END IF 
			
			#----------------------------------------------------------------------			
			# Calculate posting balances FROM the debit AND credit totals in CASE
			# a prior posting AND close off have NOT yet been reflected in a
			# history roll-up
			LET for_post_balance = modu_rec_accounthistcur.debit_amt - modu_rec_accounthistcur.credit_amt 
			LET base_post_balance = modu_rec_accounthistcur.base_debit_amt -	modu_rec_accounthistcur.base_credit_amt 
			
			CALL set_detl_amts(for_post_balance, base_post_balance) 
			
			LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
			LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 
			LET modu_rec_batchdetl.acct_code = modu_rec_accounthistcur.acct_code
			 
			INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
			
		END FOREACH 

		IF l_prev_currency IS NOT NULL THEN 
			CALL finish_batch() 
			UPDATE glparms 
			SET 
				next_jour_num = glob_rec_glparms.next_jour_num, 
				last_close_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		END IF
		 
	COMMIT WORK 
	
	WHENEVER ERROR CONTINUE 
	
END FUNCTION 
############################################################
# END FUNCTION post_closing_curr()
############################################################


############################################################
# FUNCTION set_up_header()
#
#
############################################################
FUNCTION set_up_header()
 
	INITIALIZE modu_rec_batchhead.* TO NULL 

	LET modu_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
	LET modu_rec_batchhead.entry_code = "GL" 
	LET modu_rec_batchhead.cleared_flag = "Y" 
	LET modu_rec_batchhead.jour_date = today 
	LET modu_rec_batchhead.period_num = modu_tempper 
	LET modu_rec_batchhead.post_flag = "N" 
	LET modu_rec_batchhead.com1_text = "Automatic Closing Entries" 
	LET modu_rec_batchhead.year_num = modu_fisc_year 
	LET modu_rec_batchhead.source_ind = "G" 
	
END FUNCTION 
############################################################
# END FUNCTION set_up_header()
############################################################


############################################################
# FUNCTION set_up_detail()
#
#
############################################################
FUNCTION set_up_detail()
 
	INITIALIZE modu_rec_batchdetl.* TO NULL 

	LET modu_rec_batchdetl.cmpy_code = modu_rec_batchhead.cmpy_code 
	LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
	LET modu_rec_batchdetl.tran_type_ind = "CL" 
	LET modu_rec_batchdetl.tran_date = today 
	LET modu_rec_batchdetl.desc_text = "Closing Entry" 
	LET modu_rec_batchdetl.stats_qty = 0 
	
END FUNCTION 
############################################################
# END FUNCTION set_up_detail()
############################################################


############################################################
# FUNCTION new_batch(l_currency)
#
#
############################################################
FUNCTION new_batch(l_currency) 
	DEFINE l_currency LIKE batchhead.currency_code 

	LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
	LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET modu_rec_batchhead.currency_code = l_currency 
	LET modu_rec_batchhead.control_amt = 0 
	LET modu_rec_batchhead.debit_amt = 0 
	LET modu_rec_batchhead.credit_amt = 0 
	LET modu_rec_batchhead.control_qty = 0 
	LET modu_rec_batchhead.stats_qty = 0 
	LET modu_rec_batchhead.for_debit_amt = 0 
	LET modu_rec_batchhead.for_credit_amt = 0 
	LET modu_rec_batchhead.seq_num = 1 
	LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchdetl.currency_code = modu_rec_batchhead.currency_code 
	LET modu_rec_batchdetl.desc_text = "Closing Entry"
	 
END FUNCTION 
############################################################
# END FUNCTION new_batch(l_currency)
############################################################


###########################################################
# FUNCTION set_detl_amts(p_for_amt, p_base_amt)
#
# Amounts posted should close the account TO zero FOR the period
# Closing amounts > 0 (DR balance) result in a Credit posting AND
# closing amounts < 0 (CR balance) result in a Debit posting (sign reversed)
############################################################
FUNCTION set_detl_amts(p_for_amt, p_base_amt) 
	DEFINE p_for_amt LIKE batchdetl.debit_amt 
	DEFINE p_base_amt LIKE batchdetl.debit_amt 

	CASE 
		WHEN (p_for_amt = 0) 
			LET modu_rec_batchdetl.for_debit_amt = 0 
			LET modu_rec_batchdetl.for_credit_amt = 0 

		WHEN (p_for_amt > 0) 
			LET modu_rec_batchdetl.for_credit_amt = p_for_amt 
			LET modu_rec_batchdetl.for_debit_amt = 0 
			LET modu_rec_batchhead.for_credit_amt = modu_rec_batchhead.for_credit_amt + modu_rec_batchdetl.for_credit_amt 

		OTHERWISE 
			LET modu_rec_batchdetl.for_debit_amt = 0 - p_for_amt 
			LET modu_rec_batchdetl.for_credit_amt = 0 
			LET modu_rec_batchhead.for_debit_amt = 	modu_rec_batchhead.for_debit_amt + modu_rec_batchdetl.for_debit_amt 
	END CASE
	 
	CASE 
		WHEN (p_base_amt = 0) 
			LET modu_rec_batchdetl.debit_amt = 0 
			LET modu_rec_batchdetl.credit_amt = 0 
			LET modu_rec_batchdetl.conv_qty = 0 

		WHEN (p_base_amt > 0) 
			LET modu_rec_batchdetl.credit_amt = p_base_amt 
			LET modu_rec_batchdetl.debit_amt = 0 
			LET modu_rec_batchhead.credit_amt = modu_rec_batchhead.credit_amt +	modu_rec_batchdetl.credit_amt 
			LET modu_rec_batchdetl.conv_qty = modu_rec_batchdetl.for_credit_amt	/ modu_rec_batchdetl.credit_amt 

		OTHERWISE 
			LET modu_rec_batchdetl.debit_amt = 0 - p_base_amt 
			LET modu_rec_batchdetl.credit_amt = 0 
			LET modu_rec_batchhead.debit_amt = modu_rec_batchhead.debit_amt + modu_rec_batchdetl.debit_amt 
			LET modu_rec_batchdetl.conv_qty = modu_rec_batchdetl.for_debit_amt	/ modu_rec_batchdetl.debit_amt 
	END CASE 

END FUNCTION 
###########################################################
# END FUNCTION set_detl_amts(p_for_amt, p_base_amt)
############################################################


###########################################################
#FUNCTION finish_batch()
#
#
############################################################
FUNCTION finish_batch() 
	DEFINE l_bal_for_amt LIKE batchhead.debit_amt
	DEFINE l_bal_base_amt LIKE batchhead.debit_amt
	 

	LET l_bal_for_amt = modu_rec_batchhead.for_debit_amt -	modu_rec_batchhead.for_credit_amt 
	LET l_bal_base_amt = modu_rec_batchhead.debit_amt -	modu_rec_batchhead.credit_amt
	 
	IF l_bal_for_amt != 0 OR l_bal_base_amt != 0 THEN 
		CALL set_detl_amts(
			l_bal_for_amt, 
			l_bal_base_amt) 

		LET modu_rec_batchdetl.acct_code = modu_net_worth_acct 
		LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
		LET modu_rec_batchdetl.desc_text = "Closing Entry Offset" 
		LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 

		INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
	END IF
	 
	LET modu_rec_batchhead.control_amt = modu_rec_batchhead.for_debit_amt 

	CALL fgl_winmessage("18 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 

	INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 

END FUNCTION 
###########################################################
#END FUNCTION finish_batch()
############################################################


###########################################################
# FUNCTION setup_ledg()
#
#
############################################################
FUNCTION setup_ledg() 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_flex_code LIKE validflex.flex_code 
	DEFINE l_query_text STRING
	DEFINE l_i SMALLINT 
	DEFINE l_idx2 SMALLINT 
	DEFINE l_post_ind SMALLINT 

	OPEN WINDOW G454 with FORM "G454" 
	CALL windecoration_g("G454") 

	DECLARE c_validflex CURSOR FOR 
	SELECT flex_code FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = modu_rec_structure.start_num 
	ORDER BY flex_code 
	
	LET l_idx2 = 0 

	LET l_query_text = 
		" SELECT unique 1 FROM coa ", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND acct_code[?,?] = '",l_flex_code,"' ", 
		" AND type_ind in ('l_i','E') " 

	PREPARE s_coa FROM l_query_text 
	DECLARE c_coa CURSOR FOR s_coa 

	FOREACH c_validflex INTO l_flex_code 
		OPEN c_coa USING modu_start_num,modu_length 
		FETCH c_coa 
		IF status = NOTFOUND THEN 
			CLOSE c_coa 
			CONTINUE FOREACH 
		END IF 

		CLOSE c_coa 

		LET l_idx2 = l_idx2 + 1 
		LET modu_arr_rec_coa[l_idx2].flex_code = l_flex_code 

		IF modu_net_worth_acct IS NULL THEN 
			LET modu_arr_rec_coa[l_idx2].acct_code = NULL 
			LET modu_arr_rec_coa[l_idx2].desc_text = NULL 
		ELSE 
			LET modu_arr_rec_coa[l_idx2].acct_code = modu_net_worth_acct 
			LET modu_arr_rec_coa[l_idx2].acct_code[modu_start_num,modu_length] =		l_flex_code[modu_start_num,modu_length] 

			SELECT desc_text INTO l_rec_coa.desc_text FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_arr_rec_coa[l_idx2].acct_code 
			AND type_ind = "N" 
			IF status = NOTFOUND THEN 
				LET modu_arr_rec_coa[l_idx2].desc_text = NULL 
			ELSE 
				LET modu_arr_rec_coa[l_idx2].desc_text = l_rec_coa.desc_text 
			END IF 
		END IF 

	END FOREACH 

	IF l_idx2 = 0 THEN 
		MESSAGE kandoomsg2("G",9110,"")		#9110" No ledgers satisfied selection criteria "
		RETURN false 
	END IF 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
 
	LET modu_ledg_cnt = l_idx2
	 
	MESSAGE kandoomsg2("G",1035,"") 	#1035 " RETURN on line TO Edit "
	INPUT ARRAY modu_arr_rec_coa WITHOUT DEFAULTS FROM sr_coa.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GP4","inp-arr-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET modu_arr_rec_coa[l_idx2].acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD acct_code 

		BEFORE ROW 
			LET l_idx2 = arr_curr() 

		AFTER FIELD acct_code 
			IF (fgl_lastkey() = fgl_keyval("up") OR fgl_lastkey() = fgl_keyval("prevpage")) THEN
			 
			ELSE 
				IF (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("RETURN")) 
				AND fgl_lastkey() != fgl_keyval("accept") 
				AND arr_curr() = arr_count() THEN 
					ERROR kandoomsg2("G",9001,"") 			#9001 " No more rows in the direction you are going"
					NEXT FIELD acct_code 
				END IF 
				
				IF modu_arr_rec_coa[l_idx2].acct_code IS NULL THEN 
					ERROR kandoomsg2("G",9113,"") 				#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct_code 
				END IF 

				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_arr_rec_coa[l_idx2].acct_code 
				AND type_ind = "N" 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9132,"") 	#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct_code 
				END IF 

				IF modu_arr_rec_coa[l_idx2].acct_code[modu_start_num,modu_length] != modu_arr_rec_coa[l_idx2].flex_code THEN 
					ERROR kandoomsg2("G",9117,"") 		#9117 Account code does NOT exist FOR this Ledger - Try Window
					NEXT FIELD acct_code 
				ELSE 
					LET modu_arr_rec_coa[l_idx2].desc_text = l_rec_coa.desc_text 
				END IF 
			END IF 

		AFTER INPUT 
			LET l_post_ind = true 
			IF int_flag OR quit_flag THEN 
				LET l_post_ind = false 
				EXIT INPUT 
			ELSE 
				FOR l_i = 1 TO modu_ledg_cnt 

					IF modu_arr_rec_coa[l_i].acct_code IS NULL THEN 
						ERROR kandoomsg2("G",9113,"") 					#9113 Account code must NOT be NULL - Try Window
						LET l_post_ind = false 
						EXIT FOR 
					END IF 

					SELECT unique 1 FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = modu_arr_rec_coa[l_i].acct_code 
					AND type_ind = "N" 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("G",9132,"") 					#9132 Networth Account code does NOT exist - Try Window
						LET l_post_ind = false 
						EXIT FOR 
					END IF 
				END FOR 

				IF NOT l_post_ind THEN 
					NEXT FIELD acct_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW G454 

	RETURN l_post_ind 
END FUNCTION
###########################################################
# END FUNCTION setup_ledg()
############################################################