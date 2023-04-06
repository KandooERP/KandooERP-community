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
# MODULE DESCRIPTION GC1a.4gl
###########################################################################

###########################################################################
# Common routine TO enter bank transaction header information.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC1_GLOBALS.4gl"
GLOBALS "../gl/G21_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION gc_header(p_mode,p_prompt_text)
#
# Common routine TO enter bank transaction header information.
###########################################################################
FUNCTION gc_header(p_mode,p_prompt_text) 
	DEFINE p_mode char(2) ##"CR = Sundry Credits/DR - Bank charges" 
	DEFINE p_prompt_text char(30) 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_total_amt LIKE batchhead.for_credit_amt 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_bank_code LIKE bank.bank_code 
	DEFINE l_jour_date LIKE batchhead.jour_date 
	DEFINE l_temp_text char(30) 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_bk_type char(1) 
	DEFINE l_module_id VARCHAR(5)
	
	CLEAR FORM 
	DISPLAY p_prompt_text TO prompt_text 
	MESSAGE kandoomsg2("G",1049,"") 

	#G1049 Enter Cashbook Transaction - ESC TO Continue
	# erve to huho: why not use INPUT BY NAME (implies renaming l_bk_type l_total_amt or put the into a record) ALSO l_bk_type is CHAR[1] and in record char(2)
	INPUT 
		l_rec_bank.bank_code, 
		l_bk_type, 
		glob_rec_batchhead.jour_date, 
		l_total_amt, 
		glob_rec_batchhead.conv_qty, 
		glob_rec_batchhead.year_num, 
		glob_rec_batchhead.period_num, 
		glob_rec_batchhead.entry_code, 
		glob_rec_batchhead.com1_text, 
		glob_rec_batchhead.com2_text WITHOUT DEFAULTS 
	FROM 
		bank_code, 
		bk_type, 
		jour_date, 
		total_amt, 
		conv_qty, 
		year_num, 
		period_num, 
		entry_code, 
		com1_text, 
		com2_text ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC1a","inp-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING l_temp_text, 
			l_rec_bank.acct_code 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_bank.bank_code = l_temp_text 
				NEXT FIELD bank_code 
			END IF 

		ON CHANGE bank_code
			DISPLAY db_bank_get_name_acct_text(UI_OFF,l_rec_bank.bank_code) TO bank.name_acct_text
			DISPLAY db_bank_get_iban(UI_OFF,l_rec_bank.bank_code) TO bank.iban
			DISPLAY db_bank_get_bic_code(UI_OFF,l_rec_bank.bank_code) TO bank.bic_code		

		AFTER FIELD bank_code 
			IF l_rec_bank.bank_code IS NULL THEN 
				ERROR kandoomsg2("G",9143,"") 
				NEXT FIELD bank_code 
			END IF 

			IF l_rec_bank_code IS NULL OR l_rec_bank_code != l_rec_bank.bank_code THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_rec_bank.bank_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9143,"") 
					NEXT FIELD bank_code 
				END IF 
				
				LET glob_rec_batchhead.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					l_rec_bank.currency_code,
					today,
					CASH_EXCHANGE_SELL)
				 
				DISPLAY BY NAME l_rec_bank.name_acct_text 
				DISPLAY BY NAME l_rec_bank.acct_code 
				DISPLAY BY NAME glob_rec_batchhead.conv_qty 

				DISPLAY BY NAME l_rec_bank.currency_code 

				LET l_rec_bank_code = l_rec_bank.bank_code 

				#HuHo Make field also visually readOnly
				IF p_mode = "DR" THEN 
					CALL set_fieldAttribute_readOnly("bk_type",TRUE) 
				ELSE 
					CALL set_fieldAttribute_readOnly("bk_type",FALSE) 
				END IF 

			END IF 

		ON CHANGE bk_type
			CASE 
				WHEN l_bk_type = "S" 
					LET l_rec_banking.bk_type = "SC" 
					LET l_rec_banking.bk_desc = "Sundry credit" 
				WHEN l_bk_type = "D" 
					LET l_rec_banking.bk_type = "DP" 
					LET l_rec_banking.bk_desc = "Deposit" 
				OTHERWISE 
					ERROR "Need a deposit type" 
					NEXT FIELD bk_type 
			END CASE 
			
			DISPLAY BY NAME l_rec_banking.bk_desc 
		

		BEFORE FIELD bk_type #note: implementation IS very confusing with l_bk_type char(1) AND the db-table-rec bk_type char(2) 
			IF p_mode = "DR" THEN 
				LET l_rec_banking.bk_type = "BC" 
				LET l_rec_banking.bk_desc = "Bank charges" 
				DISPLAY l_rec_banking.bk_desc TO bk_desc 
				--DISPLAY l_bk_type TO bk_type

				CALL set_fieldAttribute_readOnly("bk_type",TRUE) #huho make FIELD also visually readonly 

				#huho - I hate this implementation ...  we need to keep this - otherwise after field validation will kick in  in DR mode
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				CALL set_fieldAttribute_readOnly("bk_type",FALSE) 
			END IF 

			####################################################
			# Note, there is some strange implementation for field bk_type
			# 1. DepositType is in some variables char(1) and in the main record variable (AND DB) char(2)
			# 2. DepositType is in the char(1) assigned
			# D or S (Deposit or Sundry)
			# in the CHAR(2) / DATABASE
			# BC Bank Charges
			# SC Sundry Credit
			# DP Deposit

			#				WHEN l_bk_type = "S"
			#					LET l_rec_banking.bk_type = "SC"
			#					LET l_rec_banking.bk_desc = "Sundry credit"
			#				WHEN l_bk_type = "D"
			#					LET l_rec_banking.bk_type = "DP"
			#					LET l_rec_banking.bk_desc = "Deposit"
			#
			# on the form level, we have char(1) and this comment text
			# toolTip=" Type of Deposit - (D)eposit - (S)undry Credit"
			#
			# NOTE: With this implementation, the comboBox will NOT show any value -
			# just the description text field will be populated/shown
			####################################################


		AFTER FIELD bk_type 
			CASE 
				WHEN l_bk_type = "S" 
					LET l_rec_banking.bk_type = "SC" 
					LET l_rec_banking.bk_desc = "Sundry credit" 
				WHEN l_bk_type = "D" 
					LET l_rec_banking.bk_type = "DP" 
					LET l_rec_banking.bk_desc = "Deposit" 
				OTHERWISE 
					ERROR "Need a deposit type" 
					NEXT FIELD bk_type 
			END CASE 
			
			DISPLAY BY NAME l_rec_banking.bk_desc 

		BEFORE FIELD jour_date 
			LET l_jour_date = glob_rec_batchhead.jour_date 

		AFTER FIELD jour_date 
			IF glob_rec_batchhead.jour_date IS NULL THEN 
				LET glob_rec_batchhead.jour_date = today 
				ERROR kandoomsg2("J",9505,"") 
				NEXT FIELD jour_date 
			END IF 

			IF l_jour_date != glob_rec_batchhead.jour_date THEN 
				IF l_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET glob_rec_batchhead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						l_rec_bank.currency_code,	
						glob_rec_batchhead.jour_date,
						CASH_EXCHANGE_SELL) 
				END IF 

				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, glob_rec_batchhead.jour_date) 
				RETURNING 
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num
					 
				DISPLAY BY NAME 
					glob_rec_batchhead.conv_qty, 
					glob_rec_batchhead.year_num, 
					glob_rec_batchhead.period_num 

			END IF 

		AFTER FIELD total_amt 
			CASE 
				WHEN l_total_amt <= 0 
					ERROR kandoomsg2("U",9927,"") 	#9927 Value must be > 0
					NEXT FIELD total_amt 
				WHEN l_total_amt IS NULL 
					ERROR kandoomsg2("U",9927,"") #9927 Value must be > 0
					NEXT FIELD total_amt 
			END CASE 

		BEFORE FIELD conv_qty 
			IF l_rec_bank.currency_code = glob_rec_glparms.base_currency_code THEN 
				LET glob_rec_batchhead.conv_qty = 1 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			CASE 
				WHEN glob_rec_batchhead.conv_qty IS NULL 
					ERROR kandoomsg2("U",9927,"") 		#9927 Value must be > 0
					NEXT FIELD conv_qty 
				WHEN glob_rec_batchhead.conv_qty <= 0 
					ERROR kandoomsg2("U",9927,"") 	#9927 Value must be > 0
					NEXT FIELD conv_qty 
			END CASE 


		AFTER FIELD period_num 
			IF glob_rec_batchhead.period_num IS NULL THEN 
				ERROR kandoomsg2("G",9012,"") 
				NEXT FIELD period_num 
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

		DELETE FROM t_batchdetl WHERE username = glob_rec_kandoouser.sign_on_code 

		LET glob_rec_batchhead.jour_code = glob_rec_glparms.cb_code 
		LET glob_rec_batchhead.source_ind = "C" 
		LET glob_rec_batchhead.currency_code = l_rec_bank.currency_code 
		LET glob_rec_batchhead.control_amt = l_total_amt 
		LET l_rec_batchdetl.seq_num = 1 
		LET l_rec_batchdetl.acct_code = l_rec_bank.acct_code 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.tran_type_ind = l_rec_banking.bk_type 
		LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
		LET l_rec_batchdetl.currency_code = glob_rec_batchhead.currency_code 
		LET l_rec_batchdetl.conv_qty = glob_rec_batchhead.conv_qty 
		LET l_rec_batchdetl.ref_text = l_rec_banking.bk_desc 
		LET l_rec_batchdetl.desc_text = l_rec_bank.name_acct_text 
		LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
		LET l_rec_batchdetl.currency_code = glob_rec_batchhead.currency_code 

		IF p_mode = "DR" THEN 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = l_total_amt 
		ELSE 
			## switch CR & DR's as the "credit" IS used as INPUT variable
			LET l_rec_batchdetl.for_debit_amt = l_total_amt 
			LET l_rec_batchdetl.for_credit_amt = 0 
		END IF 

		LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt	/ glob_rec_batchhead.conv_qty 
		LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt	/ glob_rec_batchhead.conv_qty 

		LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_module_id = getmoduleid()

		INSERT INTO t_batchdetl VALUES (
			l_rec_batchdetl.*,
			glob_rec_kandoouser.sign_on_code,
			l_module_id) #this crashes because l_ rec_batchdetl.* IS native TABLE RECORD AND t_batchdetl.* IS 
		# like batchdetl PLUS one more column for username

		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION gc_header(p_mode,p_prompt_text)
###########################################################################