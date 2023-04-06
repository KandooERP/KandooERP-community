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
# \brief module GC8 foreign exchange transactions
# It generates cbaudit records
# It also 'posts period activity' by generating the GL batch FOR the batch.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC8_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_cbaudit RECORD LIKE cbaudit.* 
	DEFINE glob_arr_rec_trans array[2] OF 
	RECORD {(1) IS selling, (2) IS buying } 
		bank_code LIKE bank.bank_code, 
		name_acct_text LIKE bank.name_acct_text, 
		currency_code LIKE bank.currency_code, 
		acct_code LIKE bank.acct_code, 
		trans_amt LIKE batchdetl.debit_amt, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE glob_rec_save_bathd RECORD LIKE batchhead.* 
	DEFINE glob_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE glob_rec_banking RECORD LIKE banking.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_base_currency_code LIKE glparms.base_currency_code 
	DEFINE glob_exch_account_code LIKE glparms.exch_acct_code 
	DEFINE glob_rept_jour_num LIKE glparms.next_jour_num 
	DEFINE glob_msgresp char(1) 
	DEFINE glob_ans char(1) 
	DEFINE glob_local_currency_ind SMALLINT 
	DEFINE glob_foreign_currency_ind SMALLINT 
	#DEFINE glob_i SMALLINT #not used
	DEFINE glob_failed SMALLINT 
	DEFINE glob_cnt SMALLINT 

	DEFINE glob_try_again char(1) 
	DEFINE glob_err_message char(40) 
	#DEFINE glob_idx INTEGER #not used
	#DEFINE glob_next_seq INTEGER #not used
	DEFINE glob_rate_1 decimal(8,4) 
	DEFINE glob_rate_2 decimal(8,4) 
	DEFINE glob_sell_rate FLOAT 
	DEFINE glob_buy_rate FLOAT 
END GLOBALS 

###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GC8") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--	SELECT glparms.*
	--	INTO glob_rec_glparms.*
	--	FROM glparms
	--	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND glparms.key_code = "1"

	--	IF glob_rec_glparms.cash_book_flag = "Y" THEN
	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		LET glob_msgresp = kandoomsg("G",9502,"") 
		EXIT PROGRAM 
	END IF 

	LET glob_base_currency_code = glob_rec_glparms.base_currency_code 
	LET glob_exch_account_code = glob_rec_glparms.exch_acct_code 

	LET glob_ans = "Y" 
	WHILE glob_ans = "Y" 
		LET int_flag = 0 
		LET quit_flag = 0 
		CALL doit() 
		CLOSE WINDOW g167 

		IF int_flag = 0 AND quit_flag = 0 THEN 
			IF promptTF("",kandoomsg2("U",8026,""),1)	THEN 
				IF glob_arr_rec_trans[1].currency_code != glob_arr_rec_trans[2].currency_code THEN 
					CALL cross_curr_tran( ) 
				ELSE 
					CALL insertit() 
				END IF 
			END IF 
		END IF 

	END WHILE 

END MAIN 


###########################################################################
# FUNCTION doit()
#
#
###########################################################################
FUNCTION doit() 

	INITIALIZE glob_rec_banking.* TO NULL 
	INITIALIZE glob_rec_batchhead.* TO NULL 

	LET glob_rec_batchhead.for_debit_amt = 0 
	LET glob_rec_batchhead.debit_amt = 0 
	LET glob_rec_batchhead.for_credit_amt = 0 
	LET glob_rec_batchhead.credit_amt = 0 

	--INITIALIZE glob_arr_rec_trans[1].* TO NULL 
	--INITIALIZE glob_arr_rec_trans[2].* TO NULL 
	INITIALIZE glob_rec_cbaudit.* TO NULL 

	LET glob_buy_rate = 0 
	LET glob_sell_rate = 0 
	LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_batchhead.jour_date = today 

	OPEN WINDOW g167 with FORM "G167" 
	CALL windecoration_g("G167") 

	LET glob_arr_rec_trans[1].desc_text = "FOREX sale " 
	LET glob_arr_rec_trans[2].desc_text = "FOREX purchase " 

	DISPLAY 
	glob_rec_batchhead.jour_date, 
	glob_rec_batchhead.entry_code, 
	glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_arr_rec_trans[1].*, 
	glob_arr_rec_trans[2].*, 
	glob_sell_rate, 
	glob_buy_rate, 
	glob_rec_batchhead.com1_text, 
	glob_rec_batchhead.com2_text 
	TO 
	jour_date, 
	entry_code, 
	year_num, 
	period_num, 
	s_bank_code , 
	s_name_acct_text , 
	s_currency_code , 
	s_acct_code , 
	s_trans_amt , 
	s_desc_text, 
	b_bank_code , 
	b_name_acct_text , 
	b_currency_code , 
	b_acct_code , 
	b_trans_amt , 
	b_desc_text, 
	s_rate, 
	b_rate, 
	com1_text, 
	com2_text 


	INPUT 
	glob_rec_batchhead.jour_date, 
	glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_arr_rec_trans[1].bank_code , 
	glob_arr_rec_trans[1].name_acct_text , 
	glob_arr_rec_trans[1].currency_code , 
	glob_arr_rec_trans[1].acct_code , 
	glob_arr_rec_trans[1].trans_amt , 
	glob_arr_rec_trans[1].desc_text, 
	glob_arr_rec_trans[2].bank_code , 
	glob_arr_rec_trans[2].name_acct_text , 
	glob_arr_rec_trans[2].currency_code , 
	glob_arr_rec_trans[2].acct_code , 
	glob_arr_rec_trans[2].trans_amt , 
	glob_arr_rec_trans[2].desc_text, 
	glob_sell_rate, 
	glob_buy_rate, 
	glob_rec_batchhead.com1_text, 
	glob_rec_batchhead.com2_text 

	WITHOUT DEFAULTS FROM 
	jour_date, 
	year_num, 
	period_num, 
	s_bank_code , 
	s_name_acct_text , 
	s_currency_code , 
	s_acct_code , 
	s_trans_amt , 
	s_desc_text, 
	b_bank_code , 
	b_name_acct_text , 
	b_currency_code , 
	b_acct_code , 
	b_trans_amt , 
	b_desc_text, 
	s_rate, 
	b_rate, 
	com1_text, 
	com2_text 

	ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC8","inp-batch-trans") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD jour_date 

			IF glob_rec_batchhead.jour_date IS NULL THEN 
				LET glob_msgresp = kandoomsg("J",9505,"") 
				NEXT FIELD jour_date 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_batchhead.jour_date) 
			RETURNING glob_rec_batchhead.year_num, glob_rec_batchhead.period_num 

			#DISPLAY by name
			#glob_rec_batchhead.year_num, glob_rec_batchhead.period_num

			NEXT FIELD period_num 

		AFTER FIELD period_num 
			IF glob_rec_batchhead.period_num IS NULL THEN 
				LET glob_msgresp = kandoomsg("U",9112,"Accounting period") 
				NEXT FIELD period_num 

			ELSE 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num, 
					LEDGER_TYPE_GL) 
				RETURNING 
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num, 
					glob_failed 

				IF glob_failed THEN 
					NEXT FIELD year_num 
				END IF 

			END IF 


		AFTER FIELD s_bank_code 

			IF bank_code_check(1) THEN 
				#DISPLAY glob_arr_rec_trans[1].name_acct_text, glob_arr_rec_trans[1].acct_code ,
				#glob_arr_rec_trans[1].currency_code
				#TO s_name_acct_text,s_acct_code, s_currency_code

				CALL get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					glob_arr_rec_trans[1].currency_code, 
					glob_rec_batchhead.jour_date, 
					CASH_EXCHANGE_SELL) 
				RETURNING glob_sell_rate 
				#DISPLAY glob_sell_rate TO s_rate
			ELSE 
				CLEAR s_name_acct_text, s_currency_code 
				NEXT FIELD s_bank_code 
			END IF 

		AFTER FIELD b_bank_code 

			IF glob_arr_rec_trans[1].bank_code = glob_arr_rec_trans[2].bank_code THEN 
				LET glob_msgresp = kandoomsg("G",9067,"") 
				NEXT FIELD b_bank_code 
			END IF 

			IF bank_code_check(2) THEN 
				#DISPLAY glob_arr_rec_trans[2].name_acct_text, glob_arr_rec_trans[2].acct_code ,
				#glob_arr_rec_trans[2].currency_code
				#TO b_name_acct_text,b_acct_code, b_currency_code

				IF glob_arr_rec_trans[2].currency_code != glob_arr_rec_trans[1].currency_code THEN 
					CALL get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						glob_arr_rec_trans[2].currency_code, 
						glob_rec_batchhead.jour_date, 
						CASH_EXCHANGE_BUY) 
					RETURNING glob_buy_rate 
				ELSE 
					LET glob_buy_rate = glob_sell_rate 
				END IF 

				#DISPLAY glob_buy_rate TO b_rate

			ELSE 
				CLEAR b_name_acct_text, b_currency_code 
				NEXT FIELD b_bank_code 
			END IF 

			IF glob_arr_rec_trans[1].currency_code = glob_arr_rec_trans[2].currency_code THEN 
				LET glob_arr_rec_trans[2].trans_amt = glob_arr_rec_trans[1].trans_amt 
			END IF 


		AFTER FIELD s_trans_amt 
			IF glob_arr_rec_trans[1].trans_amt IS NULL OR 
			glob_arr_rec_trans[1].trans_amt <= 0 THEN 
				LET glob_msgresp = kandoomsg("G",9068,"") 
				NEXT FIELD s_trans_amt 
			END IF 

			IF glob_arr_rec_trans[1].trans_amt > 999999999.99 
			THEN 
				LET glob_msgresp = kandoomsg("G",9069,"") 
				NEXT FIELD s_trans_amt 
			END IF 

		AFTER FIELD b_trans_amt 
			IF glob_arr_rec_trans[2].trans_amt IS NULL OR 
			glob_arr_rec_trans[2].trans_amt <= 0 THEN 
				LET glob_msgresp = kandoomsg("G",9070,"") 
				NEXT FIELD b_trans_amt 
			END IF 

			IF glob_arr_rec_trans[2].trans_amt > 999999999.99 

			THEN 
				LET glob_msgresp = kandoomsg("G",9069,"") 
				NEXT FIELD s_trans_amt 
			END IF 

			IF glob_arr_rec_trans[1].currency_code = glob_arr_rec_trans[2].currency_code 
			AND glob_arr_rec_trans[2].trans_amt != glob_arr_rec_trans[1].trans_amt THEN 
				LET glob_msgresp = kandoomsg("G",9072,"") 
				NEXT FIELD s_trans_amt 
			END IF 


		ON ACTION "LOOKUP" infield (s_bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_arr_rec_trans[1].bank_code, glob_arr_rec_trans[1].acct_code 
			#DISPLAY glob_arr_rec_trans[1].bank_code, glob_arr_rec_trans[1].acct_code
			#TO s_bank_code, s_acct_code

			NEXT FIELD s_bank_code 


		ON ACTION "LOOKUP" infield (b_bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_arr_rec_trans[2].bank_code, glob_arr_rec_trans[2].acct_code 
			#DISPLAY glob_arr_rec_trans[2].bank_code, glob_arr_rec_trans[2].acct_code
			#TO b_bank_code, b_acct_code

			NEXT FIELD b_bank_code 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT PROGRAM 
			END IF 

			IF glob_arr_rec_trans[1].currency_code = glob_arr_rec_trans[2].currency_code THEN 
				IF glob_buy_rate != glob_sell_rate THEN 
					LET glob_msgresp = kandoomsg("G",9073,"") 
					LET glob_buy_rate = glob_sell_rate 
					#    DISPLAY glob_buy_rate TO b_rate
					NEXT FIELD s_rate 
				END IF 

				IF glob_arr_rec_trans[1].trans_amt != glob_arr_rec_trans[2].trans_amt THEN 
					LET glob_msgresp = kandoomsg("G",9072,"") 
					NEXT FIELD s_trans_amt 
				END IF 
			END IF 
			IF glob_arr_rec_trans[1].currency_code = glob_base_currency_code THEN 

				IF glob_sell_rate != 1.0 THEN 
					LET glob_msgresp = kandoomsg("G",9071,"") 
					NEXT FIELD s_rate 
				END IF 
				LET glob_local_currency_ind = 1 
				LET glob_foreign_currency_ind = 2 
			ELSE 
				IF glob_arr_rec_trans[2].currency_code = glob_base_currency_code THEN 

					IF glob_buy_rate != 1.0 THEN 
						LET glob_msgresp = kandoomsg("G",9071,"") 
						NEXT FIELD b_rate 
					END IF 
					LET glob_local_currency_ind = 2 
					LET glob_foreign_currency_ind = 1 
					LET glob_local_currency_ind = 0 
					LET glob_foreign_currency_ind = 1 
				END IF 
			END IF 

			CALL valid_period(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				LEDGER_TYPE_GL) 
			RETURNING 
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				glob_failed 

			IF glob_failed THEN 
				NEXT FIELD year_num 
			END IF 

			IF glob_arr_rec_trans[1].bank_code IS NULL THEN 
				LET glob_msgresp = kandoomsg("U",9112,"bank account") 
				NEXT FIELD s_bank_code 
			END IF 

			IF glob_arr_rec_trans[2].bank_code IS NULL THEN 
				LET glob_msgresp = kandoomsg("U",9112,"bank account") 
				NEXT FIELD b_bank_code 
			END IF 

			IF glob_arr_rec_trans[1].trans_amt IS NULL OR 
			glob_arr_rec_trans[1].trans_amt <= 0 THEN 
				LET glob_msgresp = kandoomsg("G",9068,"") 
				NEXT FIELD s_trans_amt 
			END IF 

			IF glob_arr_rec_trans[2].trans_amt IS NULL OR 
			glob_arr_rec_trans[2].trans_amt <= 0 THEN 
				LET glob_msgresp = kandoomsg("G",9070,"") 
				NEXT FIELD b_trans_amt 
			END IF 

			--		ON KEY (control-w)
			--			CALL kandoohelp("")

	END INPUT 


	IF int_flag OR quit_flag THEN EXIT PROGRAM END IF 

END FUNCTION 


###########################################################################
# FUNCTION exch_rate()
#
###########################################################################
FUNCTION exch_rate() 
	LET glob_sell_rate = glob_arr_rec_trans[1].trans_amt / glob_arr_rec_trans[2].trans_amt 
	LET glob_rate_1 = glob_sell_rate 
	LET glob_buy_rate = glob_arr_rec_trans[2].trans_amt / glob_arr_rec_trans[1].trans_amt 
	LET glob_rate_2 = glob_buy_rate 

	DISPLAY glob_arr_rec_trans[1].currency_code, glob_arr_rec_trans[2].currency_code , glob_rate_1, glob_rate_2 
	TO s_curr, b_curr, s_rate, b_rate 

END FUNCTION 


###########################################################################
# FUNCTION bank_code_check(p_idx)
#
###########################################################################
FUNCTION bank_code_check(p_idx) 
	DEFINE p_idx SMALLINT 
	DECLARE bank_c CURSOR FOR 
	SELECT bank.* , coa.* 
	INTO glob_rec_bank.*, glob_rec_coa.* 
	FROM bank, coa 
	WHERE bank_code = glob_arr_rec_trans[p_idx].bank_code AND 
	bank.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	coa.acct_code = bank.acct_code AND 
	coa.cmpy_code = bank.cmpy_code 

	OPEN bank_c 
	FETCH bank_c 

	IF status = NOTFOUND THEN 
		LET glob_msgresp = kandoomsg("U",9112,"banking account - try window") 
		LET glob_arr_rec_trans[p_idx].bank_code = NULL 
		LET glob_arr_rec_trans[p_idx].currency_code = NULL 
		LET glob_arr_rec_trans[p_idx].acct_code = NULL 
		LET glob_arr_rec_trans[p_idx].name_acct_text = NULL 
		RETURN false 
	ELSE 
		LET glob_arr_rec_trans[p_idx].currency_code = glob_rec_bank.currency_code 
		LET glob_arr_rec_trans[p_idx].acct_code = glob_rec_bank.acct_code 
		LET glob_arr_rec_trans[p_idx].name_acct_text = glob_rec_bank.name_acct_text 
		RETURN true 
	END IF 

END FUNCTION # bank_code_check 



###########################################################################
# FUNCTION show_batch_num(p_ask)
#
###########################################################################
FUNCTION show_batch_num(p_ask) 
	#
	# MESSAGE out batch number AND whether TO continue with another
	#
	DEFINE p_ask SMALLINT 

	OPEN WINDOW g115 with FORM "G115" 
	CALL windecoration_g("G115") 

	DISPLAY BY NAME glob_rec_batchhead.jour_num 


	IF p_ask THEN 
		IF promptTF("",kandoomsg2("G",8026,""),1)	THEN 
			LET glob_ans = "Y" 
		ELSE 
			LET glob_ans = "N" 
		END IF 
	ELSE 
		LET glob_ans = "Y" 
	END IF 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		EXIT PROGRAM 
	END IF 

	LET glob_ans = upshift(glob_ans) 
	CLOSE WINDOW g115 

END FUNCTION { show_batch_num } 


###########################################################################
# FUNCTION insertit()
#
#
###########################################################################
FUNCTION insertit() 
	#DEFINE l_balance_amount LIKE accountcur.bal_amt #not used
	#DEFINE l_base_balance_amt LIKE accountcur.base_bal_amt #not used
	#DEFINE l_conv_type CHAR(1) #not used
	#DEFINE l_rate_average LIKE batchhead.conv_qty #not used
	#DEFINE l_error_msg CHAR(80)  #not used
	DEFINE l_seq_num SMALLINT 
	DEFINE l_run_arg_str STRING 
	LET glob_msgresp = kandoomsg("G",1011,"") 

	GOTO bypass 

	LABEL recovery: 
	LET glob_try_again = error_recover(glob_err_message, status) 
	IF glob_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 
		--SET CONSTRAINTS DEFERRED #Eric Tip
		EXECUTE immediate "SET CONSTRAINTS ALL deferred" #huho had ERROR -691 

		DECLARE update_gl CURSOR FOR 
		SELECT glparms.* 
		INTO glob_rec_glparms.* 
		FROM glparms 
		WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND glparms.key_code = "1" 
		FOR UPDATE OF next_jour_num 

		OPEN update_gl 
		FETCH update_gl 
		INTO glob_rec_glparms.* 

		LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 

		UPDATE glparms 
		SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE CURRENT OF update_gl 

		CLOSE update_gl 

				{ Now the details, first the credit entry, the selling side
				 Cash going out of a GL bank account credits the bank account.
				the amount of the transfer IS the local currency amount.
				}
		IF glob_local_currency_ind = 0 THEN 
			LET glob_foreign_currency_ind = 1 
		END IF 

		LET glob_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchdetl.jour_code = "CB" 
		LET glob_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
		LET l_seq_num = 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.tran_type_ind= "CB" 
		LET glob_rec_batchdetl.analysis_text = NULL 
		LET glob_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
		LET glob_rec_batchdetl.ref_text = "BANK tfr." 
		LET glob_rec_batchdetl.ref_num = 0 
		LET glob_rec_batchdetl.acct_code = glob_arr_rec_trans[1].acct_code 
		LET glob_rec_batchdetl.desc_text = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_batchdetl.debit_amt = 0 
		LET glob_rec_batchdetl.stats_qty = 0 

		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[glob_foreign_currency_ind].currency_code 

		LET glob_rec_batchdetl.conv_qty = glob_sell_rate 
		LET glob_rec_batchdetl.credit_amt = glob_arr_rec_trans[glob_foreign_currency_ind].trans_amt / 
		glob_sell_rate 

		LET glob_rec_batchdetl.for_debit_amt = 0 
		LET glob_rec_batchdetl.for_credit_amt = glob_arr_rec_trans[glob_foreign_currency_ind].trans_amt 


		IF glob_rec_batchhead.for_credit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_credit_amt = 0 
		END IF 
		IF glob_rec_batchhead.credit_amt IS NULL THEN 
			LET glob_rec_batchhead.credit_amt = 0 
		END IF 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + 
		glob_rec_batchdetl.for_credit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + 
		glob_rec_batchdetl.credit_amt 

		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

		{ Now the debit entry, the buying side }
		IF glob_local_currency_ind = 0 THEN 
			LET glob_foreign_currency_ind = 2 
		END IF 

		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.acct_code = glob_arr_rec_trans[2].acct_code 
		LET glob_rec_batchdetl.desc_text = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_batchdetl.credit_amt = 0 
		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[glob_foreign_currency_ind].currency_code 

		LET glob_rec_batchdetl.conv_qty = glob_buy_rate 
		LET glob_rec_batchdetl.debit_amt = glob_arr_rec_trans[glob_foreign_currency_ind].trans_amt / 
		glob_buy_rate 

		LET glob_rec_batchdetl.for_debit_amt = glob_arr_rec_trans[glob_foreign_currency_ind].trans_amt 
		LET glob_rec_batchdetl.for_credit_amt = 0 

		IF glob_rec_batchhead.for_debit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_debit_amt = 0 
		END IF 
		IF glob_rec_batchhead.debit_amt IS NULL THEN 
			LET glob_rec_batchhead.debit_amt = 0 
		END IF 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + 
		glob_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + 
		glob_rec_batchdetl.debit_amt 

		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

				{IF the debit_amt generated does NOT equal the credit_amt, the
				 difference IS TO become an exchange variance in a separate
				 Batch detail
				}

		IF glob_rec_batchhead.debit_amt != glob_rec_batchhead.credit_amt THEN 
			LET l_seq_num = l_seq_num + 1 
			LET glob_rec_batchdetl.seq_num = l_seq_num 
			LET glob_rec_batchdetl.tran_type_ind = "EXG" 
			LET glob_rec_batchdetl.tran_date = today 
			LET glob_rec_batchdetl.desc_text = "FOREX exchange variance" 
			LET glob_rec_batchdetl.acct_code = glob_exch_account_code 

			LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[glob_foreign_currency_ind].currency_code 
			IF glob_arr_rec_trans[1].currency_code = glob_base_currency_code THEN 
				LET glob_rec_batchdetl.conv_qty = glob_buy_rate 
			ELSE 
				LET glob_rec_batchdetl.conv_qty = glob_sell_rate 
			END IF 

			IF glob_rec_batchhead.credit_amt > glob_rec_batchhead.debit_amt THEN 
				LET glob_rec_batchdetl.debit_amt = glob_rec_batchhead.credit_amt - 
				glob_rec_batchhead.debit_amt 
				LET glob_rec_batchdetl.credit_amt = 0 
			ELSE 
				LET glob_rec_batchdetl.credit_amt = glob_rec_batchhead.debit_amt - 
				glob_rec_batchhead.credit_amt 
				LET glob_rec_batchdetl.debit_amt = 0 
			END IF 

			LET glob_rec_batchdetl.for_debit_amt = 0 
			LET glob_rec_batchdetl.for_credit_amt = 0 
			LET glob_rec_batchdetl.stats_qty = 0 


			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
				LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
				LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
				LET glob_rec_batchdetl.conv_qty = 1 
			END IF 


			LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + 
			glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + 
			glob_rec_batchdetl.debit_amt 

			INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

		END IF 

		LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchhead.jour_code = "CB" 
		LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_batchhead.currency_code = glob_arr_rec_trans[glob_foreign_currency_ind].currency_code 
		LET glob_rec_batchhead.post_flag = "N" 
		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchhead.seq_num = l_seq_num 
		LET glob_rec_batchhead.cleared_flag = "Y" 
		LET glob_rec_batchhead.post_run_num = NULL 
		LET glob_rec_batchhead.consol_num = NULL 
		LET glob_rec_batchhead.conv_qty = glob_rec_batchdetl.conv_qty 
		LET glob_rec_batchhead.source_ind = "C" 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchhead.conv_qty = 1 
		END IF 

		LET glob_rec_batchhead.control_qty = 0 
		LET glob_rec_batchhead.stats_qty = 0 
		LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 

		CALL fgl_winmessage("11 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

				{Now the banking reconcilliation table, since this matches up with
				  the bank's statement, the debits abd credits are reversed
				First the selling side which generates a debit entry on the statement
				These transactions are in the local currency.
				}

		LET glob_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_banking.bk_acct = glob_arr_rec_trans[1].acct_code 
		LET glob_rec_banking.bk_type = "TO" 
		LET glob_rec_banking.bk_bankdt = glob_rec_batchhead.jour_date 
		LET glob_rec_banking.bk_desc = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_banking.bk_sh_no = NULL 
		LET glob_rec_banking.bk_seq_no = NULL 
		LET glob_rec_banking.bk_rec_part = NULL 
		LET glob_rec_banking.bk_year = glob_rec_batchhead.year_num 
		LET glob_rec_banking.bk_per = glob_rec_batchhead.period_num 
		LET glob_rec_banking.bk_debit = glob_arr_rec_trans[1].trans_amt 
		LET glob_rec_banking.bk_cred = 0 
		LET glob_rec_banking.bk_enter = glob_rec_batchhead.entry_code 


		LET glob_rec_banking.bank_dep_num = glob_rec_batchhead.jour_num 
		LET glob_rec_banking.base_debit_amt = glob_rec_batchhead.debit_amt 
		LET glob_rec_banking.base_cred_amt = 0 
		LET glob_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (glob_rec_banking.*) 

				{
				Now the buying side which generates a credit entry on the statement
				}

		LET glob_rec_banking.bk_type = "TI" 
		LET glob_rec_banking.bk_acct = glob_arr_rec_trans[2].acct_code 
		LET glob_rec_banking.bk_desc = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_banking.bk_debit = 0 
		LET glob_rec_banking.bk_cred = glob_arr_rec_trans[2].trans_amt 


		LET glob_rec_banking.bank_dep_num = glob_rec_batchhead.jour_num 
		LET glob_rec_banking.base_cred_amt = glob_rec_batchhead.credit_amt 
		LET glob_rec_banking.base_debit_amt = 0 
		LET glob_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (glob_rec_banking.*) 

				{Next cab off the rank IS the cbaudit table,
				  all transactions in local currency
				}

		LET glob_rec_cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_cbaudit.tran_date = glob_rec_batchhead.jour_date 

		LET glob_rec_cbaudit.tran_type_ind = "TO" 
		LET glob_rec_cbaudit.sheet_num = NULL 
		LET glob_rec_cbaudit.line_num = NULL 
		LET glob_rec_cbaudit.year_num = glob_rec_batchhead.year_num 
		LET glob_rec_cbaudit.period_num = glob_rec_batchhead.period_num 
		LET glob_rec_cbaudit.source_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_cbaudit.tran_text = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_cbaudit.tran_amt = glob_arr_rec_trans[1].trans_amt 
		LET glob_rec_cbaudit.entry_code = glob_rec_batchhead.entry_code 

		LET glob_rec_cbaudit.bank_code = glob_arr_rec_trans[1].bank_code 

		INSERT INTO cbaudit VALUES (glob_rec_cbaudit.*) 

		LET glob_rec_cbaudit.tran_type_ind = "TI" 
		LET glob_rec_cbaudit.tran_text = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_cbaudit.tran_amt = glob_arr_rec_trans[2].trans_amt 

		LET glob_rec_cbaudit.bank_code = glob_arr_rec_trans[2].bank_code 

		INSERT INTO cbaudit VALUES (glob_rec_cbaudit.*) 

	COMMIT WORK 


	{
	   LET last_batch_num  = (3)
	   LET sent_batch_num  = (2)
	   LET PROG_PARENT     = (1)
	}
	LET glob_rept_jour_num = glob_rec_batchhead.jour_num 
	LET l_run_arg_str = "SENT_BATCH_NUMBER=", trim(glob_rept_jour_num) 
	CALL run_prog("GB5","PROG_PARENT=GC8",l_run_arg_str,"","") 
	CALL show_batch_num(true ) 

	WHENEVER ERROR stop 
END FUNCTION { insertit } 



###########################################################################
# FUNCTION cross_curr_tran( )
#
#
###########################################################################
FUNCTION cross_curr_tran( ) 
	DEFINE l_balance_amount LIKE accountcur.bal_amt 
	#DEFINE l_base_balance_amt LIKE accountcur.base_bal_amt #not used
	DEFINE l_conv_type char(1) 
	#DEFINE l_rate_average LIKE batchhead.conv_qty #not used
	DEFINE l_error_msg char(80) 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_run_arg_str STRING 

	LET glob_msgresp = kandoomsg("G",1011,"") 

	GOTO bypass 

	LABEL recovery: 
	LET glob_try_again = error_recover(glob_err_message, status) 
	IF glob_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 
	#@huho gorb_rec_batchhead has got empty cmpy_code, jour_oce, entry_code curency code, ,conv_qty....
	LET glob_rec_save_bathd.* = glob_rec_batchhead.* 

	BEGIN WORK 
		--SET CONSTRAINTS DEFERRED #Eric Tip
		EXECUTE immediate "SET CONSTRAINTS ALL deferred" #huho had ERROR -691 

		DECLARE update_gl1 CURSOR FOR 

		SELECT glparms.* 
		INTO glob_rec_glparms.* 
		FROM glparms 
		WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND glparms.key_code = "1" 
		FOR UPDATE OF next_jour_num 
		OPEN update_gl1 

		FETCH update_gl1 
		INTO glob_rec_glparms.* 
		LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 

		UPDATE glparms 
		SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE CURRENT OF update_gl1 

		CLOSE update_gl1 

				{ Now the details, first the credit entry, the selling side
				 Cash going out of a GL bank account credits the bank account.
				the amount of the transfer IS the local currency amount.
				}
		LET glob_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchdetl.jour_code = "CB" 
		LET glob_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
		LET l_seq_num = 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.tran_type_ind= "CB" 
		LET glob_rec_batchdetl.analysis_text = NULL 
		LET glob_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
		LET glob_rec_batchdetl.ref_text = "BANK tfr." 
		LET glob_rec_batchdetl.ref_num = 0 
		LET glob_rec_batchdetl.acct_code = glob_arr_rec_trans[1].acct_code 
		LET glob_rec_batchdetl.desc_text = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_batchdetl.stats_qty = 0 
		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[1].currency_code 
		LET glob_rec_batchdetl.debit_amt = 0 
		LET glob_rec_batchdetl.credit_amt = glob_arr_rec_trans[1].trans_amt / 
		glob_sell_rate 
		LET glob_rec_batchdetl.conv_qty = glob_sell_rate 

		LET glob_rec_batchdetl.for_debit_amt = 0 
		LET glob_rec_batchdetl.for_credit_amt = glob_arr_rec_trans[1].trans_amt 


		IF glob_rec_batchhead.for_credit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_credit_amt = 0 
		END IF 

		IF glob_rec_batchhead.credit_amt IS NULL THEN 
			LET glob_rec_batchhead.credit_amt = 0 
		END IF 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + 
		glob_rec_batchdetl.for_credit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + 
		glob_rec_batchdetl.credit_amt 


		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.tran_type_ind = "EXG" 
		LET glob_rec_batchdetl.tran_date = today 
		LET glob_rec_batchdetl.desc_text = "FOREX exchange variance" 
		LET glob_rec_batchdetl.acct_code = glob_exch_account_code 

		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[1].currency_code 
		LET glob_rec_batchdetl.conv_qty = glob_sell_rate 

		LET glob_rec_batchdetl.debit_amt = glob_rec_batchhead.credit_amt - 
		glob_rec_batchhead.debit_amt 
		LET glob_rec_batchdetl.credit_amt = 0 

		LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchhead.for_credit_amt 
		LET glob_rec_batchdetl.for_credit_amt = 0 
		LET glob_rec_batchdetl.stats_qty = 0 


		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + 
		glob_rec_batchdetl.for_credit_amt 
		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + 
		glob_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + 
		glob_rec_batchdetl.credit_amt 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + 
		glob_rec_batchdetl.debit_amt 

		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

		{ Now INSERT the header details }

		LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchhead.jour_code = "CB" 
		LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_batchhead.currency_code = glob_arr_rec_trans[1].currency_code 
		LET glob_rec_batchhead.post_flag = "N" 
		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchhead.seq_num = l_seq_num 
		LET glob_rec_batchhead.cleared_flag = "Y" 
		LET glob_rec_batchhead.post_run_num = NULL 
		LET glob_rec_batchhead.consol_num = NULL 


		LET glob_rec_batchhead.conv_qty = glob_sell_rate 
		LET glob_rec_batchhead.source_ind = "C" 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchhead.conv_qty = 1 
		END IF 

		LET glob_rec_batchhead.control_qty = 0 
		LET glob_rec_batchhead.stats_qty = 0 
		LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 

		CALL fgl_winmessage("12 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

		LET glob_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_banking.bk_acct = glob_arr_rec_trans[1].acct_code 

		LET glob_rec_banking.bk_type = "TO" 
		LET glob_rec_banking.bk_bankdt = glob_rec_batchhead.jour_date 
		LET glob_rec_banking.bk_desc = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_banking.bk_sh_no = NULL 
		LET glob_rec_banking.bk_seq_no = NULL 
		LET glob_rec_banking.bk_rec_part = NULL 
		LET glob_rec_banking.bk_year = glob_rec_batchhead.year_num 
		LET glob_rec_banking.bk_per = glob_rec_batchhead.period_num 
		LET glob_rec_banking.bk_debit = glob_arr_rec_trans[1].trans_amt 
		LET glob_rec_banking.bk_cred = 0 
		LET glob_rec_banking.bk_enter = glob_rec_batchhead.entry_code 


		LET glob_rec_banking.bank_dep_num = glob_rec_batchhead.jour_num 
		LET glob_rec_banking.base_debit_amt = glob_rec_batchhead.debit_amt 
		LET glob_rec_banking.base_cred_amt = 0 
		LET glob_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (glob_rec_banking.*) 

		{Next IS the cbaudit table, all transactions in local currency }

		LET glob_rec_cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_cbaudit.tran_date = glob_rec_batchhead.jour_date 

		LET glob_rec_cbaudit.tran_type_ind = "TO" 
		LET glob_rec_cbaudit.sheet_num = NULL 
		LET glob_rec_cbaudit.line_num = NULL 
		LET glob_rec_cbaudit.year_num = glob_rec_batchhead.year_num 
		LET glob_rec_cbaudit.period_num = glob_rec_batchhead.period_num 
		LET glob_rec_cbaudit.source_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_cbaudit.tran_text = glob_arr_rec_trans[1].desc_text 
		LET glob_rec_cbaudit.tran_amt = glob_arr_rec_trans[1].trans_amt 
		LET glob_rec_cbaudit.entry_code = glob_rec_batchhead.entry_code 

		LET glob_rec_cbaudit.bank_code = glob_arr_rec_trans[1].bank_code 

		INSERT INTO cbaudit VALUES (glob_rec_cbaudit.*) 

		CALL show_batch_num(false) 


		{
		   LET last_batch_num  = (3)
		   LET sent_batch_num  = (2)
		   LET PROG_PARENT     = (1)
		}
		LET glob_rept_jour_num = glob_rec_batchhead.jour_num 
		LET l_run_arg_str = "SENT_BATCH_NUMBER=", trim(glob_rept_jour_num) 

		CALL run_prog("GB5","PROG_PARENT=GC8",l_run_arg_str,"","") 


		##########################
		# Now do the buying side #
		#
		#
		##########################

		LET glob_rec_batchhead.* = glob_rec_save_bathd.* 

		OPEN update_gl1 
		FETCH update_gl1 INTO glob_rec_glparms.* 

		LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 

		UPDATE glparms 
		SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE CURRENT OF update_gl1 
		CLOSE update_gl1 

		LET glob_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchdetl.jour_code = "CB" 
		LET glob_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
		LET l_seq_num = 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.tran_type_ind= "CB" 
		LET glob_rec_batchdetl.analysis_text = NULL 
		LET glob_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
		LET glob_rec_batchdetl.ref_text = "BANK tfr." 
		LET glob_rec_batchdetl.ref_num = 0 
		LET glob_rec_batchdetl.acct_code = glob_arr_rec_trans[2].acct_code 
		LET glob_rec_batchdetl.desc_text = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[2].currency_code 

		LET glob_rec_batchdetl.conv_qty = glob_buy_rate 



		LET glob_rec_batchdetl.credit_amt = 0 
		LET glob_rec_batchdetl.debit_amt = glob_arr_rec_trans[2].trans_amt / glob_buy_rate 


		LET glob_rec_batchdetl.for_debit_amt = glob_arr_rec_trans[2].trans_amt 
		LET glob_rec_batchdetl.for_credit_amt = 0 

		IF glob_rec_batchhead.for_debit_amt IS NULL THEN 
			LET glob_rec_batchhead.for_debit_amt = 0 
		END IF 

		IF glob_rec_batchhead.debit_amt IS NULL THEN 
			LET glob_rec_batchhead.debit_amt = 0 
		END IF 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + 
		glob_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + 
		glob_rec_batchdetl.debit_amt 

		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 


		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchdetl.seq_num = l_seq_num 
		LET glob_rec_batchdetl.tran_type_ind = "EXG" 
		LET glob_rec_batchdetl.tran_date = today 
		LET glob_rec_batchdetl.desc_text = "FOREX exchange variance" 
		LET glob_rec_batchdetl.acct_code = glob_exch_account_code 

		LET glob_rec_batchdetl.currency_code = glob_arr_rec_trans[2].currency_code 
		LET glob_rec_batchdetl.conv_qty = glob_buy_rate 

		LET glob_rec_batchdetl.credit_amt = glob_rec_batchhead.debit_amt - glob_rec_batchhead.credit_amt 
		LET glob_rec_batchdetl.debit_amt = 0 

		LET glob_rec_batchdetl.for_debit_amt = 0 
		LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchhead.for_debit_amt 
		LET glob_rec_batchdetl.stats_qty = 0 


		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchdetl.for_debit_amt = glob_rec_batchdetl.debit_amt 
			LET glob_rec_batchdetl.for_credit_amt = glob_rec_batchdetl.credit_amt 
			LET glob_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchdetl.conv_qty = 1 
		END IF 


		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + 
		glob_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + 
		glob_rec_batchdetl.credit_amt 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + 
		glob_rec_batchdetl.debit_amt 
		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + 
		glob_rec_batchdetl.for_credit_amt 

		INSERT INTO batchdetl VALUES (glob_rec_batchdetl.*) 

		{ Now INSERT the header details }

		LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_batchhead.jour_code = "CB" 
		LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_batchhead.currency_code = glob_arr_rec_trans[2].currency_code 
		LET glob_rec_batchhead.post_flag = "N" 
		LET l_seq_num = l_seq_num + 1 
		LET glob_rec_batchhead.seq_num = l_seq_num 
		LET glob_rec_batchhead.cleared_flag = "Y" 
		LET glob_rec_batchhead.post_run_num = NULL 
		LET glob_rec_batchhead.consol_num = NULL 


		LET glob_rec_batchhead.conv_qty = glob_buy_rate 
		LET glob_rec_batchhead.source_ind = "C" 

		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET glob_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
			LET glob_rec_batchhead.conv_qty = 1 
		END IF 

		LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
		LET glob_rec_batchhead.control_qty = 0 
		LET glob_rec_batchhead.stats_qty = 0 

		CALL fgl_winmessage("13 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

		LET glob_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_banking.bk_acct = glob_arr_rec_trans[2].acct_code 

		LET glob_rec_banking.bk_type = "TI" 
		LET glob_rec_banking.bk_bankdt = glob_rec_batchhead.jour_date 
		LET glob_rec_banking.bk_desc = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_banking.bk_sh_no = NULL 
		LET glob_rec_banking.bk_seq_no = NULL 
		LET glob_rec_banking.bk_rec_part = NULL 
		LET glob_rec_banking.bk_year = glob_rec_batchhead.year_num 
		LET glob_rec_banking.bk_per = glob_rec_batchhead.period_num 
		LET glob_rec_banking.bk_cred = glob_arr_rec_trans[2].trans_amt 
		LET glob_rec_banking.bk_debit = 0 
		LET glob_rec_banking.bk_enter = glob_rec_batchhead.entry_code 


		LET glob_rec_banking.bank_dep_num = glob_rec_batchhead.jour_num 
		LET glob_rec_banking.base_cred_amt = glob_rec_batchhead.credit_amt 
		LET glob_rec_banking.base_debit_amt = 0 
		LET glob_rec_banking.doc_num = 0 

		INSERT INTO banking VALUES (glob_rec_banking.*) 

		{Next IS the cbaudit table, all transactions in local currency }

		LET glob_rec_cbaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_cbaudit.tran_date = glob_rec_batchhead.jour_date 

		LET glob_rec_cbaudit.tran_type_ind = "TI" 
		LET glob_rec_cbaudit.sheet_num = NULL 
		LET glob_rec_cbaudit.line_num = NULL 
		LET glob_rec_cbaudit.year_num = glob_rec_batchhead.year_num 
		LET glob_rec_cbaudit.period_num = glob_rec_batchhead.period_num 
		LET glob_rec_cbaudit.source_num = glob_rec_glparms.next_jour_num 
		LET glob_rec_cbaudit.tran_text = glob_arr_rec_trans[2].desc_text 
		LET glob_rec_cbaudit.tran_amt = glob_arr_rec_trans[2].trans_amt 
		LET glob_rec_cbaudit.entry_code = glob_rec_batchhead.entry_code 

		LET glob_rec_cbaudit.bank_code = glob_arr_rec_trans[2].bank_code 

		INSERT INTO cbaudit VALUES (glob_rec_cbaudit.*) 

		CALL show_batch_num(true) 

	COMMIT WORK 

	{
	   LET last_batch_num  = (3)
	   LET sent_batch_num  = (2)
	   LET PROG_PARENT     = (1)
	}


	LET glob_rept_jour_num = glob_rec_batchhead.jour_num 
	LET l_run_arg_str = "SENT_BATCH_NUMBER=", trim(glob_rept_jour_num) 
	CALL run_prog("GB5","PROG_PARENT=GC8",l_run_arg_str,"","") 

	WHENEVER ERROR stop 

END FUNCTION 
