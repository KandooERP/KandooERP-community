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
# FUNCTION direct_banking() allows the user TO enter conversion rate AND
# GL period data FOR direct bank credits AND deposits AND TO dissect the
# transaction according TO GL posting account
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION direct_banking(p_rec_bankstatement, p_seq_num)
#
#
###########################################################################
FUNCTION direct_banking(p_rec_bankstatement, p_seq_num) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE p_seq_num INTEGER 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_last_field char(4) 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_rec_flag SMALLINT 
	DEFINE l_tran_type_text char(16) 
	DEFINE l_credit_type_text char(19) 
	DEFINE l_credit_type_desc char(13) 
	DEFINE l_dep_type char(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g409 with FORM "G409" 
	CALL windecoration_g("G409") 

	SELECT * INTO l_rec_currency.* FROM currency 
	WHERE currency_code = glob_rec_bank.currency_code 
	IF status = NOTFOUND THEN 
		LET l_rec_currency.desc_text = "" 
	END IF 

	IF p_rec_bankstatement.conv_qty IS NULL 
	OR p_rec_bankstatement.conv_qty = 0 THEN 
		CALL get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			glob_rec_bank.currency_code, 
			p_rec_bankstatement.tran_date, 
			CASH_EXCHANGE_SELL) 
		RETURNING 
		p_rec_bankstatement.conv_qty 
	END IF 
	
	IF p_rec_bankstatement.entry_type_code = "SC" THEN 
		LET l_tran_type_text = "Credits/Deposits" 
		LET l_credit_type_text = "Credit type........" 
	ELSE 
		LET l_tran_type_text = "Bank charges" 
		LET l_credit_type_text = " " 
	END IF 

	CASE p_rec_bankstatement.type_code 
		WHEN "S" 
			LET l_credit_type_desc = "Sundry credit" 
			LET l_dep_type = "S" 
		WHEN "D" 
			LET l_credit_type_desc = "Deposit" 
			LET l_dep_type = "D" 
		OTHERWISE 
			LET l_credit_type_desc = " " 
			LET l_dep_type = " " 
	END CASE 

	DISPLAY l_tran_type_text TO tran_type_text 
	DISPLAY l_credit_type_text TO credit_type_text 

	DISPLAY BY NAME glob_rec_bank.bank_code, 
	glob_rec_bank.name_acct_text, 
	glob_rec_bank.acct_code, 
	glob_rec_bank.currency_code, 
	l_rec_currency.desc_text, 
	p_rec_bankstatement.tran_amt, 
	p_rec_bankstatement.tran_date, 
	p_rec_bankstatement.conv_qty, 
	p_rec_bankstatement.entry_code, 
	p_rec_bankstatement.year_num, 
	p_rec_bankstatement.period_num 

	DISPLAY l_dep_type TO dep_type
	DISPLAY l_credit_type_desc TO credit_type_desc

	WHILE true 

		INPUT 
		p_rec_bankstatement.conv_qty, 
		l_dep_type, 
		p_rec_bankstatement.year_num, 
		p_rec_bankstatement.period_num, 
		p_rec_bankstatement.com1_text, 
		p_rec_bankstatement.com2_text 
		WITHOUT DEFAULTS 
		FROM
		conv_qty, 
		dep_type, 
		year_num, 
		period_num, 
		com1_text, 
		com2_text 

		
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEc","inp-bankstatement") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE FIELD conv_qty 
				IF glob_rec_glparms.base_currency_code = glob_rec_bank.currency_code THEN 
					IF p_rec_bankstatement.entry_type_code = "SC" THEN 
						NEXT FIELD dep_type 
					ELSE 
						NEXT FIELD year_num 
					END IF 
				END IF 
			AFTER FIELD conv_qty 
				IF p_rec_bankstatement.conv_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 " Value must be entered.
					NEXT FIELD conv_qty 
				END IF 
				IF p_rec_bankstatement.conv_qty <= 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					#9012 " Value must be greater than zero"
					NEXT FIELD conv_qty 
				END IF 
				LET l_last_field = "rate" 

			BEFORE FIELD dep_type 
				IF p_rec_bankstatement.entry_type_code = "BC" THEN 
					IF l_last_field = "rate" THEN 
						NEXT FIELD year_num 
					ELSE 
						NEXT FIELD conv_qty 
					END IF 
				END IF 

			AFTER FIELD dep_type 
				IF p_rec_bankstatement.entry_type_code = "SC" THEN 
					CASE 
						WHEN l_dep_type = "S" 
							LET l_credit_type_desc = "Sundry credit" 
						WHEN l_dep_type = "D" 
							LET l_credit_type_desc = "Deposit" 
						OTHERWISE 
							LET l_msgresp = kandoomsg("G",9080,"") 
							#9080 " Credit type must be S)undry credit OR D)eposit"
							NEXT FIELD dep_type 
					END CASE 

					DISPLAY l_credit_type_desc TO credit_type_desc 

				END IF 

			AFTER FIELD year_num 
				LET l_last_field = "year" 

			AFTER FIELD period_num 
				IF p_rec_bankstatement.period_num IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9121,"") 
					#9121 " Period IS required "
					NEXT FIELD period_num 
				ELSE 
					CALL valid_period(
						glob_rec_kandoouser.cmpy_code, 
						p_rec_bankstatement.year_num, 
						p_rec_bankstatement.period_num, 
						LEDGER_TYPE_GL) 
					RETURNING 
						p_rec_bankstatement.year_num, 
						p_rec_bankstatement.period_num, 
						l_invalid_period 
					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				IF p_rec_bankstatement.conv_qty IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 	#1037 " Value must be entered.
					NEXT FIELD conv_qty 
				END IF 
				IF p_rec_bankstatement.conv_qty <= 0 THEN 
					LET l_msgresp = kandoomsg("P",9927,"0") 
					#9927 " Exchange Rate must be greater than zero"
					NEXT FIELD conv_qty 
				END IF 
				IF p_rec_bankstatement.entry_type_code = "SC" THEN 
					CASE 
						WHEN l_dep_type = "S" 
							LET l_credit_type_desc = "Sundry credit" 
						WHEN l_dep_type = "D" 
							LET l_credit_type_desc = "Deposit" 
						OTHERWISE 
							LET l_msgresp = kandoomsg("G",9080,"") 
							#9080 " Credit type must be S)undry credit OR D)eposit"
							NEXT FIELD dep_type 
					END CASE 
					DISPLAY l_credit_type_desc TO credit_type_desc 

				END IF 
				IF p_rec_bankstatement.period_num IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9121,"") 
					#9121 " Period IS required "
					NEXT FIELD period_num 
				ELSE 
					CALL valid_period(
						glob_rec_kandoouser.cmpy_code, 
						p_rec_bankstatement.year_num, 
						p_rec_bankstatement.period_num, 
						LEDGER_TYPE_GL) 
					RETURNING 
						p_rec_bankstatement.year_num, 
						p_rec_bankstatement.period_num, 
						l_invalid_period 
					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
				END IF 

				--         ON KEY (control-w)
				--            CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_flag = false 
			EXIT WHILE 
		ELSE 
			UPDATE t_bkstate 
			SET conv_qty = p_rec_bankstatement.conv_qty, 
			year_num = p_rec_bankstatement.year_num, 
			period_num = p_rec_bankstatement.period_num, 
			type_code = l_dep_type, 
			com1_text = p_rec_bankstatement.com1_text, 
			com2_text = p_rec_bankstatement.com2_text 
			WHERE seq_num = p_seq_num 
			LET l_rec_flag = disburse(p_rec_bankstatement.entry_type_code, 
			p_rec_bankstatement.tran_amt, 
			p_seq_num, 
			p_rec_bankstatement.year_num, 
			p_rec_bankstatement.period_num, 
			p_rec_bankstatement.conv_qty) 
			IF l_rec_flag THEN 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW g409 

	RETURN l_rec_flag 
END FUNCTION 



############################################################
#FUNCTION disburse(p_tr_type_code,
#                  p_total_tran_amt,
#                  p_seq_num,
#                  p_tr_year_num,
#                  p_tr_period_num,
#                  p_tr_conv_qty)
#
#
############################################################
FUNCTION disburse(p_tr_type_code, 
	p_total_tran_amt, 
	p_seq_num, 
	p_tr_year_num, 
	p_tr_period_num, 
	p_tr_conv_qty) 
	DEFINE p_tr_type_code LIKE bankstatement.entry_type_code 
	DEFINE p_total_tran_amt, dissect_amt LIKE bankstatement.tran_amt 
	DEFINE p_seq_num INTEGER 
	DEFINE p_tr_year_num LIKE bankstatement.year_num 
	DEFINE p_tr_period_num LIKE bankstatement.period_num 
	DEFINE p_tr_conv_qty LIKE bankstatement.conv_qty 
	DEFINE l_rec_bkdetl RECORD 
		seq_num INTEGER, 
		ref_code LIKE bankdetails.ref_code, 
		ref_num LIKE bankdetails.ref_num, 
		ref_text LIKE bankdetails.ref_text, 
		tran_amt LIKE bankdetails.tran_amt, 
		disc_amt LIKE bankdetails.disc_amt, 
		acct_code LIKE bankdetails.acct_code, 
		desc_text LIKE bankdetails.desc_text, 
		conv_qty LIKE bankdetails.conv_qty 
	END RECORD 
	DEFINE l_arr_rec_disbdetl DYNAMIC ARRAY OF RECORD -- array[150] OF RECORD 
		acct_code LIKE bankdetails.acct_code, 
		ref_text LIKE bankdetails.ref_text, 
		tran_amt LIKE bankdetails.tran_amt, 
		desc_text LIKE bankdetails.desc_text 
	END RECORD 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_amt_type_text char(6) 
	DEFINE l_amt_type_text2 char(6) 
	DEFINE l_idx, i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g410 with FORM "G410" 
	CALL windecoration_g("G410") 

	IF p_tr_type_code = "SC" THEN 
		LET l_amt_type_text = "Credit" 
		LET l_amt_type_text2 = "Credit" 
	ELSE 
		LET l_amt_type_text = " debit" 
		LET l_amt_type_text2 = " debit" 
	END IF 
	
	DISPLAY l_amt_type_text TO amt_type_text 
	DISPLAY l_amt_type_text2  TO amt_type_text2
	DISPLAY p_total_tran_amt TO total_tran_amt

	DECLARE c_disbdetl CURSOR FOR 
	SELECT * 
	FROM t_bkdetl 
	WHERE seq_num = p_seq_num 
	LET l_idx = 0 
	FOREACH c_disbdetl INTO l_rec_bkdetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_disbdetl[l_idx].acct_code = l_rec_bkdetl.acct_code 
		LET l_arr_rec_disbdetl[l_idx].ref_text = l_rec_bkdetl.ref_text 
		LET l_arr_rec_disbdetl[l_idx].tran_amt = l_rec_bkdetl.tran_amt 
		LET l_arr_rec_disbdetl[l_idx].desc_text = l_rec_bkdetl.desc_text 
		--      IF l_idx = 150 THEN
		--         LET l_msgresp = kandoomsg("U",6100,l_idx)
		--         EXIT FOREACH
		--      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	FREE c_disbdetl 
	--   CALL set_count(l_idx)

	INPUT ARRAY l_arr_rec_disbdetl WITHOUT DEFAULTS FROM sr_disbdetl.* attributes(unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEc","inp-arr-disbdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_arr_rec_disbdetl[l_idx].acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			#DISPLAY l_arr_rec_disbdetl[l_idx].acct_code
			#     TO sr_disbdetl[scrn].acct_code

			NEXT FIELD acct_code 

		ON ACTION "NOTES" infield (desc_text) 
			LET l_arr_rec_disbdetl[l_idx].desc_text = 
			sys_noter(glob_rec_kandoouser.cmpy_code, 
			l_arr_rec_disbdetl[l_idx].desc_text) 
			#DISPLAY l_arr_rec_disbdetl[l_idx].desc_text
			#     TO sr_disbdetl[scrn].desc_text

			NEXT FIELD desc_text 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

		BEFORE FIELD acct_code 
			LET l_rec_bkdetl.acct_code = l_arr_rec_disbdetl[l_idx].acct_code 
			LET dissect_amt = 0 
			FOR i = 1 TO arr_count() 
				IF l_arr_rec_disbdetl[i].tran_amt IS NOT NULL THEN 
					LET dissect_amt = dissect_amt 
					+ l_arr_rec_disbdetl[i].tran_amt 
				END IF 
			END FOR 
			IF p_total_tran_amt = dissect_amt THEN 
				LET l_msgresp = kandoomsg("G",1061,"") 
			ELSE 
				LET l_msgresp = kandoomsg("G",1003,"") 
			END IF 
			DISPLAY BY NAME dissect_amt 

		AFTER FIELD acct_code 
			IF l_rec_bkdetl.acct_code IS NOT NULL THEN 
				LET l_arr_rec_disbdetl[l_idx].acct_code = l_rec_bkdetl.acct_code 
				#DISPLAY l_arr_rec_disbdetl[l_idx].acct_code
				#     TO sr_disbdetl[scrn].acct_code

			END IF 

		BEFORE FIELD ref_text 
			IF l_arr_rec_disbdetl[l_idx].acct_code IS NULL THEN 
				NEXT FIELD acct_code 
			END IF 
			CALL verify_acct_code(glob_rec_kandoouser.cmpy_code, 
			l_arr_rec_disbdetl[l_idx].acct_code, 
			p_tr_year_num, 
			p_tr_period_num) 
			RETURNING l_rec_coa.* 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,coa_account_required_can_be_normal_transaction, glob_rec_glparms.cash_book_flag) THEN 
				NEXT FIELD acct_code 
			END IF 
			LET l_arr_rec_disbdetl[l_idx].acct_code = l_rec_coa.acct_code 
			IF l_arr_rec_disbdetl[l_idx].desc_text IS NULL THEN 
				LET l_arr_rec_disbdetl[l_idx].desc_text = l_rec_coa.desc_text 
			END IF 
			IF l_arr_rec_disbdetl[l_idx].ref_text IS NULL AND l_idx > 1 THEN 
				LET l_arr_rec_disbdetl[l_idx].ref_text = l_arr_rec_disbdetl[l_idx-1].ref_text 
				#DISPLAY l_arr_rec_disbdetl[l_idx].ref_text
				#     TO sr_disbdetl[scrn].ref_text

			END IF 
			IF l_arr_rec_disbdetl[l_idx].tran_amt IS NULL THEN 
				LET l_arr_rec_disbdetl[l_idx].tran_amt = p_total_tran_amt 
				- dissect_amt 
			END IF 
			#DISPLAY l_arr_rec_disbdetl[l_idx].*
			#     TO sr_disbdetl[scrn].*

		AFTER FIELD ref_text 
			IF l_arr_rec_disbdetl[l_idx].ref_text IS NULL 
			AND l_rec_coa.analy_req_flag = "Y" THEN 
				LET l_msgresp = kandoomsg("P",9016,"") 
				#9016" Analysis IS required "
				NEXT FIELD ref_text 
			ELSE 
				NEXT FIELD tran_amt 
			END IF 

		BEFORE FIELD tran_amt 
			LET l_rec_bkdetl.tran_amt = l_arr_rec_disbdetl[l_idx].tran_amt 
			IF l_rec_bkdetl.tran_amt IS NULL THEN 
				LET l_rec_bkdetl.tran_amt = 0 
			END IF 

		AFTER FIELD tran_amt 
			IF l_arr_rec_disbdetl[l_idx].tran_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				LET l_arr_rec_disbdetl[l_idx].tran_amt = p_total_tran_amt - dissect_amt 
				+ l_rec_bkdetl.tran_amt 
				NEXT FIELD tran_amt 
			END IF 
			IF l_arr_rec_disbdetl[l_idx].tran_amt <= 0 THEN 
				LET l_msgresp = kandoomsg("U",9927,"0") 
				#9927 " Amount must be greater than zero "
				NEXT FIELD tran_amt 
			END IF 
			NEXT FIELD desc_text 

		AFTER FIELD desc_text 
			IF l_arr_rec_disbdetl[l_idx].desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9084 " Value IS required "
				NEXT FIELD desc_text 
			END IF 
			NEXT FIELD acct_code 

		AFTER DELETE 
			NEXT FIELD acct_code 

		BEFORE INSERT 
			NEXT FIELD acct_code 

		AFTER ROW 
			IF l_arr_rec_disbdetl[l_idx].tran_amt IS NULL THEN 
				INITIALIZE l_arr_rec_disbdetl[l_idx].* TO NULL 
			END IF 
			#DISPLAY l_arr_rec_disbdetl[l_idx].* TO sr_disbdetl[scrn].*

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_total_tran_amt != dissect_amt THEN 
					LET l_msgresp = kandoomsg("G",9081,"") 
					#9081 " Transaction total NOT equal TO amount disbursed"
					NEXT FIELD acct_code 
				END IF 
			END IF 

			--      ON KEY (control-w)
			--         CALL kandoohelp("")

	END INPUT 

	CLOSE WINDOW g410 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		DELETE 
		FROM t_bkdetl 
		WHERE seq_num = p_seq_num 
		RETURN false 
	ELSE 
		DELETE 
		FROM t_bkdetl 
		WHERE seq_num = p_seq_num 
		FOR i = 1 TO arr_count() 
			IF l_arr_rec_disbdetl[i].tran_amt IS NOT NULL THEN 
				LET l_rec_bkdetl.seq_num = p_seq_num 
				LET l_rec_bkdetl.ref_text = l_arr_rec_disbdetl[i].ref_text 
				LET l_rec_bkdetl.tran_amt = l_arr_rec_disbdetl[i].tran_amt 
				LET l_rec_bkdetl.acct_code = l_arr_rec_disbdetl[i].acct_code 
				LET l_rec_bkdetl.desc_text = l_arr_rec_disbdetl[i].desc_text 
				LET l_rec_bkdetl.conv_qty = p_tr_conv_qty 
				INSERT INTO t_bkdetl VALUES (l_rec_bkdetl.*) 
			END IF 
		END FOR 
		RETURN true 
	END IF 

END FUNCTION 
