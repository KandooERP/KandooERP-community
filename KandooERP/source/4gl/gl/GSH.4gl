{
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

	Source code beautified by beautify.pl on 2020-01-03 14:28:52	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GSH generates posting entries FOR calculated unrealised
#             exchange rate losses/gains
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--	DEFINE modu_rec_period RECORD LIKE period.*
DEFINE modu_rec_batchhead RECORD LIKE batchhead.*
DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.*
DEFINE modu_rec_structure RECORD LIKE structure.*
DEFINE modu_arr_rec_exchangevar DYNAMIC ARRAY OF RECORD 
	currency_code LIKE currency.currency_code, 
	desc_text LIKE currency.desc_text, 
	conv_qty LIKE batchhead.conv_qty 
END RECORD
DEFINE modu_arr_rec_coa DYNAMIC ARRAY OF RECORD 
	flex_code LIKE validflex.flex_code, 
	acct_code LIKE coa.acct_code, 
	desc_text LIKE coa.desc_text 
END RECORD
DEFINE modu_acct LIKE accountcur.acct_code
DEFINE modu_curr_code LIKE accountcur.currency_code
DEFINE modu_base_balance_amt LIKE accountcur.base_bal_amt
DEFINE modu_balance_amt LIKE accountcur.bal_amt
DEFINE modu_exch_variance LIKE accountcur.base_bal_amt
DEFINE modu_rept_jour_num LIKE batchhead.jour_num
DEFINE modu_old_jour_num LIKE batchhead.jour_num
DEFINE modu_old_jour_code LIKE batchhead.jour_code
DEFINE modu_first_jour_num LIKE batchhead.jour_num
DEFINE modu_last_jour_num LIKE batchhead.jour_num	
DEFINE modu_batch_inserted SMALLINT
DEFINE modu_curr_idx SMALLINT
DEFINE modu_per_num SMALLINT
DEFINE modu_arr_size SMALLINT
DEFINE i SMALLINT	
--	DEFINE idx SMALLINT
DEFINE modu_multiledger_on SMALLINT
DEFINE modu_start_num SMALLINT
DEFINE modu_length SMALLINT
DEFINE modu_fisc_year SMALLINT	
DEFINE modu_try_again CHAR(1)
DEFINE modu_msgans CHAR(1)
DEFINE modu_delete_flag CHAR(1)	 
DEFINE modu_err_message CHAR(40) 
DEFINE modu_v_date DATE 
	
############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GSH") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	LET modu_batch_inserted = false 
	LET modu_multiledger_on = true
	 
	SELECT * INTO modu_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 

	IF status = NOTFOUND THEN 
		LET modu_multiledger_on = false 
		LET modu_start_num = 1 ## NEED default VALUES as these 
		LET modu_length = 1 ## fields are referenced even IF multiledger off 
	ELSE 
		LET modu_start_num = modu_rec_structure.start_num 
		LET modu_length = modu_rec_structure.start_num	+ modu_rec_structure.length_num	- 1 
	END IF 
	
	WHILE true	
		LET modu_delete_flag = "Y" 
		IF process_exch_var() THEN 
			EXIT WHILE 
		END IF 
		
		CLOSE WINDOW wg205 
	END WHILE 
	
END MAIN 


############################################################
# FUNCTION process_exch_var()
#
#
############################################################
FUNCTION process_exch_var() 
	DEFINE l_use_curr_flag LIKE glparms.use_currency_flag
	DEFINE l_base_curr_code LIKE glparms.base_currency_code 
	DEFINE l_curr_desc_text LIKE currency.desc_text
	DEFINE l_orig_curr_code LIKE currency.currency_code 
	DEFINE l_valid_currencies CHAR(300) 
	DEFINE l_query_text CHAR(600) 
	DEFINE l_messg CHAR(53)
	DEFINE l_err_msg CHAR(53)
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_curr_from_tab SMALLINT
	DEFINE l_invalid_period SMALLINT
	DEFINE l_order_by_text CHAR(65) 
	DEFINE l_run_arg_str1 STRING 
	DEFINE l_run_arg_str2 STRING 
	DEFINE idx SMALLINT

	OPEN WINDOW wg205 with FORM "G205" 
	CALL windecoration_g("G205") 

	LET modu_msgans = kandoomsg("G",1077,"") 
	#1077 " Enter Currency Data - OK TO Continue"
	LET l_curr_from_tab = false 
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = NOTFOUND THEN 
		LET modu_msgans = kandoomsg("G",5007,"") 
		#5007 " General Ledger parameters NOT found, see menu GZP"
		RETURN true 
	END IF 
	
	LET l_use_curr_flag = glob_rec_glparms.use_currency_flag 
	LET l_base_curr_code = glob_rec_glparms.base_currency_code 
	IF l_use_curr_flag != "Y" THEN 
		LET modu_msgans = kandoomsg("G",9504,"") 
		#9504 " Foreign currency NOT in use"
		RETURN true 
	END IF 
	
	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_msgans = kandoomsg("G",5000,"") 
		#5000 " Company does NOT exist, try again"
		RETURN true 
	END IF 
	
	# Allow user TO SELECT the date FOR revaluation TO be run.
	# Revaluations will be done TO the END of the previous period FROM the
	# period the revaluation date IS in.
	LET modu_v_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, modu_v_date) RETURNING modu_fisc_year, modu_per_num 
	DISPLAY BY NAME glob_rec_company.cmpy_code, glob_rec_company.name_text 

	INPUT modu_fisc_year, modu_per_num,	modu_v_date WITHOUT DEFAULTS 
	FROM batchhead.year_num, batchhead.period_num,batchhead.jour_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSH","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,modu_fisc_year,modu_per_num,"GL") 
			RETURNING modu_fisc_year, modu_per_num, l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD batchhead.year_num 
			END IF 
	
	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN true 
	END IF 
	
	
	WHILE modu_delete_flag = "Y" 
		LET modu_delete_flag = " " 

		INPUT ARRAY modu_arr_rec_exchangevar WITHOUT DEFAULTS FROM sr_exchangevar.* attributes(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GSH","inp-arr-exchangevar") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield(currency_code) 
				LET l_curr_from_tab = true 
				LET modu_arr_rec_exchangevar[idx].currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
				#DISPLAY modu_arr_rec_exchangevar[idx].currency_code
				#     TO sr_exchangevar[scrn].currency_code

				NEXT FIELD currency_code 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()

			BEFORE FIELD currency_code 
				IF modu_arr_rec_exchangevar[idx].currency_code IS NOT NULL THEN 
					LET l_orig_curr_code = modu_arr_rec_exchangevar[idx].currency_code 
				END IF 

			AFTER DELETE 
				LET l_orig_curr_code = NULL 
				LET modu_delete_flag = "Y" 
				LET modu_arr_rec_exchangevar[idx].currency_code = NULL 
				LET modu_arr_rec_exchangevar[idx].desc_text = NULL 
				LET modu_arr_rec_exchangevar[idx].conv_qty = NULL 
				LET idx = idx - 1 
				EXIT INPUT 
	
			BEFORE FIELD conv_qty 
--				LET arr_size = modu_arr_rec_exchangevar.getSize() 
				IF modu_arr_rec_exchangevar[idx].currency_code IS NULL THEN 
					LET modu_msgans = kandoomsg("G",9505,"") 
					#9505 " Currency NOT found, try window"
					NEXT FIELD currency_code 
				END IF 
				FOR i = 1 TO modu_arr_rec_exchangevar.getSize() 
					IF i != idx THEN 
						IF modu_arr_rec_exchangevar[idx].currency_code = 
						modu_arr_rec_exchangevar[i].currency_code THEN 
							LET modu_msgans = kandoomsg("G",9506,"") 
							#9506 " Currency code has already been entered"
							NEXT FIELD currency_code 
							EXIT FOR 
						END IF 
					END IF 
				END FOR 
				
				IF modu_arr_rec_exchangevar[idx].currency_code IS NOT NULL THEN 
					SELECT desc_text INTO l_curr_desc_text FROM currency 
					WHERE currency_code = modu_arr_rec_exchangevar[idx].currency_code 
					IF status = NOTFOUND THEN 
						LET modu_msgans = kandoomsg("G",9505,"") 
						#9505 " Currency NOT found, try window"
						NEXT FIELD currency_code 
					ELSE 
						LET modu_arr_rec_exchangevar[idx].desc_text = l_curr_desc_text 
						#DISPLAY l_curr_desc_text TO sr_exchangevar[scrn].desc_text

					END IF 
					SELECT min(batchhead.jour_num) INTO l_jour_num FROM batchhead 
					WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batchhead.year_num = modu_fisc_year 
					AND batchhead.period_num = modu_per_num 
					AND batchhead.currency_code = l_base_curr_code 
					AND batchhead.com2_text[1,3] = modu_arr_rec_exchangevar[idx].currency_code 
	
					IF status = 0 AND l_jour_num > 0 THEN 
						IF kandoomsg("G",8030,l_jour_num) != "Y" THEN 
							##8030 Exchange batch already created FOR this
							##     currency/year/period - OK TO continue?
							LET modu_delete_flag = "Y" 
							LET modu_arr_rec_exchangevar[idx].currency_code = NULL 
							LET modu_arr_rec_exchangevar[idx].desc_text = NULL 
							LET modu_arr_rec_exchangevar[idx].conv_qty = NULL 
							#DISPLAY modu_arr_rec_exchangevar[idx].* TO sr_exchangevar[scrn].*

							LET idx = idx - 1 
							EXIT INPUT 
						END IF 
					END IF 
				END IF 
	
				IF modu_arr_rec_exchangevar[idx].currency_code != l_orig_curr_code OR l_orig_curr_code IS NULL OR l_curr_from_tab THEN 
					LET l_curr_from_tab = false 
					CALL get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						modu_arr_rec_exchangevar[idx].currency_code, 
						modu_v_date, 
						CASH_EXCHANGE_SELL) 
					RETURNING modu_arr_rec_exchangevar[idx].conv_qty 
					
					IF modu_arr_rec_exchangevar[idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[idx].conv_qty = "" THEN 
						LET modu_arr_rec_exchangevar[idx].conv_qty = 0 
					END IF 
					
					#DISPLAY modu_arr_rec_exchangevar[idx].conv_qty
					#     TO sr_exchangevar[scrn].conv_qty

					LET l_orig_curr_code = modu_arr_rec_exchangevar[idx].currency_code 
				END IF 
	
			AFTER FIELD conv_qty 
				IF modu_arr_rec_exchangevar[idx].conv_qty IS NULL THEN 
					LET modu_msgans = kandoomsg("P",1037,"") 
					#1037 " Exchange Rate must have a value"
					NEXT FIELD conv_qty 
				END IF 
				IF modu_arr_rec_exchangevar[idx].conv_qty <= 0 THEN 
					LET modu_msgans = kandoomsg("P",9012,"") 
					#9012 " Exchange Rate must be greater than zero"
					NEXT FIELD conv_qty 
				END IF 
				
			AFTER ROW 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
--				LET arr_size = modu_arr_rec_exchangevar.getSize() 
				IF modu_arr_rec_exchangevar[idx].currency_code IS NOT NULL 
				OR modu_arr_rec_exchangevar[idx].conv_qty IS NOT NULL THEN 
					FOR i = 1 TO modu_arr_rec_exchangevar.getSize()  
						IF i != idx THEN 
							IF modu_arr_rec_exchangevar[idx].currency_code = 
							modu_arr_rec_exchangevar[i].currency_code THEN 
								LET modu_msgans = kandoomsg("G",9104,"") 
								#9104 "Record Exists
								NEXT FIELD currency_code 
								EXIT FOR 
							END IF 
						END IF 
					END FOR 
					
					SELECT desc_text INTO l_curr_desc_text FROM currency 
					WHERE currency_code = modu_arr_rec_exchangevar[idx].currency_code 
					IF status = NOTFOUND THEN 
						LET modu_msgans = kandoomsg("G",9505,"") 					#9505 " Currency NOT found, try window"
						NEXT FIELD currency_code 
					END IF 
					
					IF modu_arr_rec_exchangevar[idx].currency_code != l_orig_curr_code OR l_orig_curr_code IS NULL THEN 
						CALL get_conv_rate(
							glob_rec_kandoouser.cmpy_code, 
							modu_arr_rec_exchangevar[idx].currency_code, 
							modu_v_date, 
							CASH_EXCHANGE_SELL) 
						RETURNING modu_arr_rec_exchangevar[idx].conv_qty
						 
						IF modu_arr_rec_exchangevar[idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[idx].conv_qty = "" THEN 
							LET modu_arr_rec_exchangevar[idx].conv_qty = 0 
						END IF 
						#DISPLAY modu_arr_rec_exchangevar[idx].conv_qty
						#     TO sr_exchangevar[scrn].conv_qty

						LET l_orig_curr_code = modu_arr_rec_exchangevar[idx].currency_code 
					END IF 
					
					IF modu_arr_rec_exchangevar[idx].conv_qty IS NULL THEN 
						LET modu_msgans = kandoomsg("G",9102,"") 					#9102 Value must be entered
						NEXT FIELD conv_qty 
					END IF 
					
					IF modu_arr_rec_exchangevar[idx].conv_qty <= 0 THEN 
						LET modu_msgans = kandoomsg("P",9012,"") 					#9012 " Exchange Rate must be greater than zero"
						NEXT FIELD conv_qty 
					END IF 
				END IF 
				
			AFTER INPUT 
				IF modu_arr_rec_exchangevar.getSize() = 0 THEN 
					LET modu_msgans = kandoomsg("G",9026,"Currency") 
					#9026 "You must enter a currency"
					NEXT FIELD currency_code 
				END IF 
				IF modu_multiledger_on THEN 
					IF NOT setup_ledg() THEN 
						NEXT FIELD currency_code 
					END IF 
				END IF 

		END INPUT 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		RETURN true 
	END IF 

	# Added TO fix error WHEN Esc IS pressed before any entry
	IF modu_arr_rec_exchangevar.getSize() = 0 THEN 
		LET modu_msgans = kandoomsg("G",9516,"") 
		RETURN true 
	ELSE 
		FOR i = 1 TO modu_arr_rec_exchangevar.getSize() 
			IF i = modu_arr_rec_exchangevar.getSize() THEN 
				LET l_valid_currencies = l_valid_currencies clipped, "\"", 
				modu_arr_rec_exchangevar[i].currency_code, "\"" 
			ELSE 
				LET l_valid_currencies = l_valid_currencies clipped, "\"", 
				modu_arr_rec_exchangevar[i].currency_code, "\"\," 
			END IF 
		END FOR 
	END IF 

	LET l_valid_currencies = "\(", l_valid_currencies clipped, "\)" 

	IF modu_multiledger_on THEN 
		LET l_order_by_text = 
		"accounthistcur.currency_code, ", 
		"accounthistcur.acct_code[",modu_start_num USING "<<<", 
		",",modu_length USING "<<<", "]" 
	ELSE 
		LET l_order_by_text = "accounthistcur.currency_code" 
	END IF 
	LET l_query_text = "SELECT accounthistcur.acct_code, ", 
	"accounthistcur.currency_code, ", 
	"accounthistcur.base_close_amt, ", 
	"accounthistcur.close_amt ", 
	"FROM accounthistcur, coa WHERE ", 
	"accounthistcur.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND accounthistcur.year_num = ", modu_fisc_year, " ", 
	"AND accounthistcur.period_num = ", modu_per_num, " ", 
	"AND coa.acct_code = accounthistcur.acct_code ", 
	"AND coa.cmpy_code = accounthistcur.cmpy_code ", 
	"AND coa.type_ind in (\"A\",\"L\") ", 
	"AND accounthistcur.currency_code != \"", 
	l_base_curr_code, "\" ", 
	"AND accounthistcur.currency_code in ", 
	l_valid_currencies clipped, " ", 
	"ORDER BY ", l_order_by_text clipped 

	PREPARE accrecs FROM l_query_text 
	DECLARE acctcurr CURSOR FOR accrecs 
	LET modu_msgans = kandoomsg("G",1011,"") 
	#1011 " Adding transactions now - please wait"

	OPEN WINDOW w11 with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	DISPLAY " Batch: " TO lblabel1 -- 1,1 

	CALL calc_exch_variances() 
	CLOSE WINDOW w11 

	IF modu_batch_inserted THEN 
		LET l_messg = " ",modu_first_jour_num USING "<<<<<<<&"," TO ", 
		modu_last_jour_num USING "<<<<<<<&" 
		LET modu_msgans = kandoomsg("G",7023,l_messg) 
		#1075 " Batches added successfully"

		{
		   LET last_batch_num  = arg_val(3)
		   LET sent_batch_num  = arg_val(2)
		   LET PROG_PARENT     = arg_val(1)
		}
		LET l_run_arg_str1 = "SENT_BATCH_NUMBER=", trim(modu_first_jour_num) 
		LET l_run_arg_str2 = "LAST_BATCH_NUMBER", trim(modu_last_jour_num) 


		CALL run_prog("GB5","PROG_PARENT=GSH",modu_first_jour_num,modu_last_jour_num,"") 
		CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
	ELSE 
		LET modu_msgans = kandoomsg("G",1076,"") 
		#1076 " No batches added"
	END IF 

	RETURN false 
END FUNCTION 


############################################################
# FUNCTION setup_ledg() 
#
#
############################################################
FUNCTION setup_ledg() 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_flex_code LIKE validflex.flex_code 
--	DEFINE l_query_text2 CHAR(300) 
	DEFINE l_exch_acct LIKE account.acct_code 
	DEFINE j SMALLINT
	DEFINE l_idx2 SMALLINT
	DEFINE l_ledg_cnt SMALLINT
	DEFINE l_post_ind SMALLINT	 

	OPEN WINDOW wg444 with FORM "G444" 
	CALL windecoration_g("G444") 

	LET l_exch_acct = glob_rec_glparms.unexch_acct_code 
	DECLARE c_validflex CURSOR FOR 
	SELECT flex_code FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = modu_rec_structure.start_num 
	ORDER BY flex_code 
	LET l_idx2 = 0 

	FOREACH c_validflex INTO l_flex_code 
		LET l_idx2 = l_idx2 + 1 
		LET modu_arr_rec_coa[l_idx2].flex_code = l_flex_code 
		IF l_exch_acct IS NULL THEN 
			LET modu_arr_rec_coa[l_idx2].acct_code = NULL 
			LET modu_arr_rec_coa[l_idx2].desc_text = NULL 
		ELSE 
			LET modu_arr_rec_coa[l_idx2].acct_code = l_exch_acct 
			LET modu_arr_rec_coa[l_idx2].acct_code[modu_start_num,modu_length] = 
			l_flex_code[modu_start_num,modu_length] 
			SELECT desc_text INTO l_rec_coa.desc_text FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_arr_rec_coa[l_idx2].acct_code 
			IF status = NOTFOUND THEN 
				LET modu_arr_rec_coa[l_idx2].desc_text = NULL 
			ELSE 
				LET modu_arr_rec_coa[l_idx2].desc_text = l_rec_coa.desc_text 
			END IF 
		END IF 

	END FOREACH 

	IF l_idx2 = 0 THEN 
		LET modu_msgans = kandoomsg("G",9110,"") 
		#9110" No ledgers satisfied selection criteria "
		RETURN false 
	END IF 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
 
	LET l_ledg_cnt = l_idx2 
	LET modu_msgans = kandoomsg("G",1035,"") 
	#1035 " RETURN on line TO Edit "

	INPUT ARRAY modu_arr_rec_coa WITHOUT DEFAULTS FROM sr_coa.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSH","inp-arr-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET modu_arr_rec_coa[l_idx2].acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD acct_code 

		BEFORE ROW 
			LET l_idx2 = arr_curr() 
			#LET scrn2 = scr_line()
			#DISPLAY modu_arr_rec_coa[l_idx2].* TO sr_coa[scrn2].*

		AFTER FIELD acct_code 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("prevpage")) THEN 
			ELSE 
				IF (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("RETURN")) 
				AND fgl_lastkey() != fgl_keyval("accept") 
				AND arr_curr() = arr_count() THEN 
					LET modu_msgans = kandoomsg("G",9001,"") 
					#9001 " No more rows in the direction you are going"
					NEXT FIELD acct_code 
				END IF 
				IF modu_arr_rec_coa[l_idx2].acct_code IS NULL THEN 
					LET modu_msgans=kandoomsg("G",9112,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct_code 
				END IF 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_arr_rec_coa[l_idx2].acct_code 
				IF status = NOTFOUND THEN 
					LET modu_msgans=kandoomsg("G",9112,"") 
					#9112 Account code does NOT exist - Try Window
					NEXT FIELD acct_code 
				END IF 
				IF modu_arr_rec_coa[l_idx2].acct_code[modu_start_num,modu_length] != 
				modu_arr_rec_coa[l_idx2].flex_code THEN 
					LET modu_msgans=kandoomsg("G",9117,"") 
					#9117 Account code does NOT exist FOR this Ledger - Try Window
					NEXT FIELD acct_code 
				ELSE 
					LET modu_arr_rec_coa[l_idx2].desc_text = l_rec_coa.desc_text 
				END IF 
			END IF 
			#AFTER ROW
			#   DISPLAY modu_arr_rec_coa[l_idx2].* TO sr_coa[scrn2].*

		AFTER INPUT 
			LET l_post_ind = true 
			IF int_flag OR quit_flag THEN 
				LET l_post_ind = false 
				EXIT INPUT 
			ELSE 
				FOR j = 1 TO l_ledg_cnt 
					IF modu_arr_rec_coa[j].acct_code IS NULL THEN 
						LET modu_msgans=kandoomsg("G",9112,"") 
						#9112 Account code must NOT be NULL - Try Window
						LET l_post_ind = false 
						EXIT FOR 
					END IF 
					SELECT unique 1 FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = modu_arr_rec_coa[j].acct_code 
					IF status = NOTFOUND THEN 
						LET modu_msgans=kandoomsg("G",9112,"") 
						#9112 Account code does NOT exist - Try Window
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

	CLOSE WINDOW wg444 

	RETURN l_post_ind 
END FUNCTION 


############################################################
# FUNCTION calc_exch_variances()  
#
#
############################################################
FUNCTION calc_exch_variances() 
	DEFINE l_prev_curr_code LIKE accountcur.currency_code 
	DEFINE l_new_base_amt LIKE accountcur.base_bal_amt
	DEFINE l_prev_ledger LIKE coa.acct_code 

	GOTO bypass 
	LABEL recovery: 
	LET modu_try_again = error_recover(modu_err_message, status) 
	IF modu_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	LET modu_batch_inserted = false 

	BEGIN WORK 

		LOCK TABLE glparms in share MODE 
		LOCK TABLE accounthistcur in share MODE 
		LOCK TABLE batchhead in share MODE 
		LOCK TABLE batchdetl in share MODE 

		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		IF status = NOTFOUND THEN 
			LET modu_msgans = kandoomsg("G",5007,"") 
			#5007 " General Ledger parameters NOT found, see menu GZP"
			EXIT PROGRAM 
		END IF 

		CALL set_up_header() 
		CALL set_up_detail() 
		LET l_prev_curr_code = NULL 
		LET l_prev_ledger = NULL 

		FOREACH acctcurr INTO modu_acct, modu_curr_code, modu_base_balance_amt, modu_balance_amt 
			## IF either "prev" key field IS NULL, THEN a new batch IS required
			## as this IS the first time through.  IF multi-ledger IS in use,
			## a new batch IS required IF either ledger OR currency changes,
			## OTHERWISE only IF the currency changes
			IF l_prev_curr_code IS NULL THEN 
				LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
				LET modu_first_jour_num = glob_rec_glparms.next_jour_num 
				CALL new_batch(modu_curr_code) 
				LET l_prev_curr_code = modu_curr_code 
				LET l_prev_ledger = modu_acct[modu_start_num, modu_length] 
			ELSE 
				IF (modu_multiledger_on = false AND modu_curr_code != l_prev_curr_code) OR 
				(modu_multiledger_on = true AND (modu_curr_code != l_prev_curr_code OR 
				modu_acct[modu_start_num, modu_length] <> l_prev_ledger)) THEN 
					IF modu_rec_batchdetl.seq_num > 0 THEN 
						CALL finish_batch(l_prev_ledger) 
						LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
					END IF 
					CALL new_batch(modu_curr_code) 
					LET l_prev_curr_code = modu_curr_code 
					LET l_prev_ledger = modu_acct[modu_start_num, modu_length] 
				END IF 
			END IF 

			IF modu_arr_rec_exchangevar[modu_curr_idx].conv_qty != 0 THEN 
				LET l_new_base_amt = modu_balance_amt / modu_arr_rec_exchangevar[modu_curr_idx].conv_qty 
			END IF 

			LET modu_exch_variance = l_new_base_amt - modu_base_balance_amt 

			IF modu_exch_variance != 0 THEN 
				IF modu_exch_variance > 0 THEN 
					LET modu_rec_batchdetl.debit_amt = modu_exch_variance 
					LET modu_rec_batchdetl.for_debit_amt = modu_exch_variance 
					LET modu_rec_batchdetl.credit_amt = 0 
					LET modu_rec_batchdetl.for_credit_amt = 0 
				ELSE 
					LET modu_rec_batchdetl.debit_amt = 0 
					LET modu_rec_batchdetl.for_debit_amt = 0 
					LET modu_rec_batchdetl.credit_amt = 0 - modu_exch_variance + 0 
					LET modu_rec_batchdetl.for_credit_amt = 0 - modu_exch_variance + 0 
				END IF 

				LET modu_rec_batchhead.debit_amt = modu_rec_batchhead.debit_amt +	modu_rec_batchdetl.debit_amt 
				LET modu_rec_batchhead.credit_amt = modu_rec_batchhead.credit_amt +	modu_rec_batchdetl.credit_amt 
				LET modu_rec_batchhead.for_debit_amt = modu_rec_batchhead.for_debit_amt +	modu_rec_batchdetl.for_debit_amt 
				LET modu_rec_batchhead.for_credit_amt = modu_rec_batchhead.for_credit_amt +	modu_rec_batchdetl.for_credit_amt 
				LET modu_rec_batchdetl.seq_num = modu_rec_batchdetl.seq_num + 1 
				LET modu_rec_batchdetl.acct_code = modu_acct 
				LET modu_err_message = "Adding batchdetl" 
				INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
			END IF 
		END FOREACH 
		
		IF l_prev_curr_code IS NOT NULL THEN 
			IF modu_rec_batchdetl.seq_num > 0 THEN 
				CALL finish_batch(l_prev_ledger) 
			END IF 
		END IF
		 
	COMMIT WORK 
	WHENEVER ERROR CONTINUE 
END FUNCTION 


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
	LET modu_rec_batchhead.jour_date = today 
	LET modu_rec_batchhead.year_num = modu_fisc_year 
	LET modu_rec_batchhead.period_num = modu_per_num 
	LET modu_rec_batchhead.debit_amt = 0 
	LET modu_rec_batchhead.credit_amt = 0 
	LET modu_rec_batchhead.for_debit_amt = 0 
	LET modu_rec_batchhead.for_credit_amt = 0 
	LET modu_rec_batchhead.source_ind = "G" 
	LET modu_rec_batchhead.post_flag = "N" 
	LET modu_rec_batchhead.com1_text = "Automatic Unrealised Exchange" 
	LET modu_rec_batchhead.cleared_flag = "Y" 
	LET modu_rec_batchhead.post_run_num = 0 
	LET modu_rec_batchhead.consol_num = 0 
	LET modu_rec_batchhead.control_amt = 0 

END FUNCTION 


############################################################
# FUNCTION set_up_detail()   
#
#
############################################################
FUNCTION set_up_detail() 

	INITIALIZE modu_rec_batchdetl.* TO NULL 
	LET modu_rec_batchdetl.cmpy_code = modu_rec_batchhead.cmpy_code 
	LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
	LET modu_rec_batchdetl.tran_type_ind = "EXG" 
	LET modu_rec_batchdetl.tran_date = today 
	LET modu_rec_batchdetl.desc_text = "Unrealised Exchange Variance" 
	LET modu_rec_batchdetl.stats_qty = 0 
END FUNCTION 


############################################################
# FUNCTION new_batch(p_currency_code)   
#
#
############################################################
FUNCTION new_batch(p_currency_code) 
	DEFINE p_currency_code LIKE batchhead.currency_code 

	LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET modu_rec_batchhead.year_num = modu_fisc_year 
	LET modu_rec_batchhead.period_num = modu_per_num 
	LET modu_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
	LET modu_rec_batchhead.debit_amt = 0 
	LET modu_rec_batchhead.credit_amt = 0 
	LET modu_rec_batchhead.for_debit_amt = 0 
	LET modu_rec_batchhead.for_credit_amt = 0 
	LET modu_rec_batchhead.control_amt = 0 

	FOR i = 1 TO modu_arr_rec_exchangevar.getSize() 
		IF modu_arr_rec_exchangevar[i].currency_code = p_currency_code THEN 
			EXIT FOR 
		END IF 
	END FOR 

	LET modu_curr_idx = i 
	LET modu_rec_batchhead.conv_qty = 1.0 
	LET modu_rec_batchhead.com2_text = p_currency_code, " Batch AT " ,	modu_arr_rec_exchangevar[modu_curr_idx].conv_qty USING "<<<<.<<<<" 
	LET modu_rec_batchhead.seq_num = 0 

	LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchdetl.currency_code = modu_rec_batchhead.currency_code 
	LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
	LET modu_rec_batchdetl.conv_qty = modu_rec_batchhead.conv_qty 
	LET modu_rec_batchdetl.debit_amt = 0 
	LET modu_rec_batchdetl.for_debit_amt = 0 
	LET modu_rec_batchdetl.credit_amt = 0 
	LET modu_rec_batchdetl.for_credit_amt = 0
	 
END FUNCTION 


############################################################
# FUNCTION finish_batch(p_prev_ledger)
#
#
############################################################
FUNCTION finish_batch(p_prev_ledger) 
	DEFINE p_prev_ledger LIKE coa.acct_code
	DEFINE l_k SMALLINT 

	LET modu_rec_batchdetl.debit_amt = 0 
	LET modu_rec_batchdetl.credit_amt = 0 
	LET modu_rec_batchdetl.for_debit_amt = 0 
	LET modu_rec_batchdetl.for_credit_amt = 0 
	IF modu_rec_batchhead.debit_amt > modu_rec_batchhead.credit_amt THEN 
		LET modu_rec_batchdetl.credit_amt = modu_rec_batchhead.debit_amt - 
		modu_rec_batchhead.credit_amt 
		LET modu_rec_batchdetl.for_credit_amt = modu_rec_batchdetl.credit_amt 
	ELSE 
		LET modu_rec_batchdetl.debit_amt = modu_rec_batchhead.credit_amt - 
		modu_rec_batchhead.debit_amt 
		LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.debit_amt 
	END IF 

	IF modu_rec_batchdetl.debit_amt != 0 
	OR modu_rec_batchdetl.credit_amt != 0 THEN 
		LET modu_rec_batchdetl.seq_num = modu_rec_batchdetl.seq_num + 1 
		IF modu_multiledger_on THEN 
			LET modu_rec_batchdetl.acct_code = NULL 
			FOR l_k = 1 TO 200 
				IF modu_arr_rec_coa[l_k].acct_code IS NULL THEN 
					EXIT FOR 
				END IF 
				IF p_prev_ledger = modu_arr_rec_coa[l_k].flex_code THEN 
					LET modu_rec_batchdetl.acct_code = modu_arr_rec_coa[l_k].acct_code 
					EXIT FOR 
				END IF 
			END FOR 
		ELSE 
			LET modu_rec_batchdetl.acct_code = glob_rec_glparms.unexch_acct_code 
		END IF 

		LET modu_err_message = "Adding batchdetl" 
		INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
		LET modu_rec_batchhead.debit_amt = modu_rec_batchhead.debit_amt + 
		modu_rec_batchdetl.debit_amt 
		LET modu_rec_batchhead.credit_amt = modu_rec_batchhead.credit_amt + 
		modu_rec_batchdetl.credit_amt 
		LET modu_rec_batchhead.for_debit_amt = modu_rec_batchhead.for_debit_amt + 
		modu_rec_batchdetl.for_debit_amt 
		LET modu_rec_batchhead.for_credit_amt = modu_rec_batchhead.for_credit_amt + 
		modu_rec_batchdetl.for_credit_amt 
	END IF 

	LET modu_rec_batchhead.seq_num = modu_rec_batchdetl.seq_num + 1 
	LET modu_rec_batchhead.control_amt = modu_rec_batchhead.debit_amt 
	LET modu_rec_batchhead.control_qty = 0 
	LET modu_rec_batchhead.stats_qty = 0 
	LET modu_err_message = "Adding batchhead" 

	CALL fgl_winmessage("22 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
	INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
	LET modu_batch_inserted = true 
	IF modu_batch_inserted THEN 
		UPDATE glparms 
		SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = 1 
	END IF 
	DISPLAY modu_rec_batchhead.jour_num USING "########" TO lblabel1 -- 1,10 

	LET modu_rept_jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchhead.post_flag = "N" 
	LET modu_rec_batchhead.jour_date = today 

	CALL change_period(glob_rec_kandoouser.cmpy_code,modu_fisc_year,modu_per_num,1) 
	RETURNING modu_rec_batchhead.year_num, modu_rec_batchhead.period_num 

	IF modu_rec_batchhead.com2_text IS NOT NULL THEN 
		LET modu_rec_batchhead.com2_text = "Rev ", modu_rec_batchhead.com2_text clipped 
		LET modu_rec_batchhead.com2_text[28,40] = " ORIG", 
		modu_rec_batchhead.jour_num USING "########" 
	ELSE 
		LET modu_rec_batchhead.com2_text = "ORIG", modu_rec_batchhead.jour_num USING "########" 
	END IF 

	LET modu_old_jour_num = modu_rec_batchhead.jour_num 
	LET modu_old_jour_code = modu_rec_batchhead.jour_code
	 
	CALL rev_insertit()
	 
END FUNCTION 


############################################################
# FUNCTION rev_insertit() 
#
#
############################################################
FUNCTION rev_insertit() 
	DEFINE l_stats_qty_flag SMALLINT 
	DEFINE l_tempdebit LIKE batchdetl.debit_amt 

	DECLARE update_gl1 CURSOR FOR 
	SELECT glparms.* INTO glob_rec_glparms.* FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	FOR UPDATE OF next_jour_num
	 
	OPEN update_gl1 
	FETCH update_gl1 INTO glob_rec_glparms.*
	 
	LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
	LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num
	 
	UPDATE glparms 
	SET next_jour_num = glob_rec_glparms.next_jour_num 
	WHERE CURRENT OF update_gl1
	 
	CLOSE update_gl1
	 
	LET l_stats_qty_flag = false 
	DECLARE curser_item CURSOR FOR 
	SELECT batchdetl.* INTO modu_rec_batchdetl.* FROM batchdetl 
	WHERE batchdetl.jour_num = modu_old_jour_num 
	AND batchdetl.jour_code = modu_old_jour_code 
	AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	FOREACH curser_item 
		LET modu_rec_batchdetl.ref_text = " " 
		LET modu_rec_batchdetl.ref_num = 0 
		LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
		LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
		LET l_tempdebit = modu_rec_batchdetl.for_debit_amt 
		LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.for_credit_amt 
		LET modu_rec_batchdetl.for_credit_amt = l_tempdebit 
		LET l_tempdebit = modu_rec_batchdetl.debit_amt 
		LET modu_rec_batchdetl.debit_amt = modu_rec_batchdetl.credit_amt 
		LET modu_rec_batchdetl.credit_amt = l_tempdebit
		 
		IF modu_rec_batchdetl.stats_qty IS NULL 
		OR modu_rec_batchdetl.stats_qty = 0 THEN 
		ELSE 
			LET modu_rec_batchdetl.stats_qty = 0 - modu_rec_batchdetl.stats_qty + 0 
			LET l_stats_qty_flag = true 
		END IF
		 
		INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*)
		 
	END FOREACH
	 
	LET modu_rec_batchhead.control_amt = modu_rec_batchhead.for_debit_amt 
	LET modu_rec_batchhead.control_qty = 0 
	LET modu_rec_batchhead.stats_qty = 0 

	CALL fgl_winmessage("23 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
	INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
	#  Now UPDATE the original batch header with the cross reference TO this one
	DECLARE xx CURSOR FOR 
	SELECT com2_text FROM batchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = modu_old_jour_code 
	AND l_jour_num = modu_old_jour_num 
	FOR UPDATE OF com2_text 
	OPEN xx 
	FETCH xx INTO modu_rec_batchhead.com2_text 
	
	IF modu_rec_batchhead.com2_text IS NOT NULL THEN 
		LET modu_rec_batchhead.com2_text[29,40] = 
		" REV", modu_rec_batchhead.jour_num USING "########" 
	ELSE 
		LET modu_rec_batchhead.com2_text = 
		"REV", modu_rec_batchhead.jour_num USING "########" 
	END IF 
	
	UPDATE batchhead 
	SET com2_text = modu_rec_batchhead.com2_text 
	WHERE CURRENT OF xx 
	CLOSE xx 
	DISPLAY modu_rec_batchhead.jour_num USING "########" TO lblabel1 -- 1,10 

	LET modu_rept_jour_num = modu_rec_batchhead.jour_num 
	LET modu_last_jour_num = modu_rec_batchhead.jour_num 
	
END FUNCTION 