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

	Source code beautified by beautify.pl on 2020-01-03 14:28:54	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_banking RECORD LIKE banking.* 
DEFINE modu_rec_bank RECORD LIKE bank.* 
DEFINE modu_msgresp LIKE language.yes_flag 
DEFINE modu_clo_base_bal_amt DECIMAL(16,4) 
DEFINE modu_save_base_bal_amt DECIMAL(16,4) 
DEFINE modu_op_base_bal_amt DECIMAL(16,4) 
DEFINE modu_pv_rowid INTEGER 


############################################################
# MAIN 
#
#
############################################################
MAIN 
	DEFINE l_msg STRING
	
	CALL setModuleId("GSZ") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	SELECT glparms.* 
	INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 

	IF glob_rec_glparms.cash_book_flag != "Y" THEN 
		LET modu_msgresp = kandoomsg("G",9502,"") 
		#9502 "Cash Book IS NOT Installed - See System Administrator"
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g136a with FORM "G136a" 
	CALL windecoration_g("G136a") 

	WHILE get_bank() 

		MESSAGE "Enter bank code FOR UPDATE.." 


		IF calc_balances() THEN 

			#UPDATE the bank file with the entered base closing amount
			UPDATE bank 
			SET state_base_bal_amt = modu_save_base_bal_amt 
			WHERE bank.bank_code = modu_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_msg = "Bank ", modu_rec_bank.bank_code, " has been updated" 
			MESSAGE l_msg
			SLEEP 2 

		ELSE 
			EXIT PROGRAM 0 
		END IF 

	END WHILE 

	CLOSE WINDOW g136a 

END MAIN 




############################################################
# FUNCTION get_bank()
#
# SELECT the bank AND enter the balance amount in base currency
# FOR the latest closed sheet.
############################################################
FUNCTION get_bank() 

	LET modu_clo_base_bal_amt = 0 

	CLEAR FORM 

	INPUT modu_rec_bank.bank_code, modu_clo_base_bal_amt WITHOUT DEFAULTS 
	FROM bank_code, clo_bal 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSZ","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING modu_rec_bank.bank_code, 
			modu_rec_bank.acct_code 
			DISPLAY modu_rec_bank.bank_code TO bank_code 

			NEXT FIELD bank_code 

		ON CHANGE bank_code
			DISPLAY db_bank_get_name_acct_text(UI_OFF,modu_rec_bank.bank_code) TO name_acct_text
			DISPLAY db_bank_get_iban(UI_OFF,modu_rec_bank.bank_code) TO iban
			DISPLAY db_bank_get_state_bal_amt(UI_OFF,modu_rec_bank.bank_code) TO state_bal_amt
			DISPLAY db_bank_get_sheet_num(UI_OFF,modu_rec_bank.bank_code) TO sheet_num
			DISPLAY db_bank_get_bic_code(UI_OFF,modu_rec_bank.bank_code) TO bic_code
			
		AFTER FIELD bank_code 
			SELECT bank.* 
			INTO modu_rec_bank.* 
			FROM bank 
			WHERE bank.bank_code = modu_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF status = NOTFOUND THEN 
				LET modu_msgresp = kandoomsg("U",9105,"") 
				#9105 "Record NOT found - Try Window"
				NEXT FIELD bank_code 
			END IF 

			DISPLAY modu_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY modu_rec_bank.iban TO iban
			DISPLAY modu_rec_bank.bic_code TO bic_code			
			DISPLAY modu_rec_bank.state_bal_amt TO state_bal_amt  
			DISPLAY modu_rec_bank.sheet_num TO sheet_num

		AFTER FIELD clo_bal 
			LET modu_save_base_bal_amt = modu_clo_base_bal_amt 
			#gets used TO UPDATE the bank file.

--		ON KEY (control-w) 
--			CALL kandoohelp("") 
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
# FUNCTION calc_balances()
#
# OPEN a CURSOR FOR each sheet AND work out the opening AND
# closing balances
############################################################
FUNCTION calc_balances() 

	MESSAGE "Creating historical balances, please wait.."  

	DECLARE reset_curs CURSOR FOR 
	SELECT rowid, * 
	FROM banking 
	WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND bk_type matches "X*" 
	AND bk_acct = modu_rec_bank.acct_code 


	ORDER BY bk_sh_no desc, bk_type #will get closing RECORD FIRST 

	FOREACH reset_curs INTO modu_pv_rowid, modu_rec_banking.* 

		IF modu_rec_banking.bk_type = "XC" THEN 

			IF modu_rec_banking.bk_sh_no = modu_rec_bank.sheet_num THEN #latest sheet 
				#do nothing, the keyed in amount IS the one we want.
			ELSE 
				LET modu_clo_base_bal_amt = modu_op_base_bal_amt 
			END IF 

			CALL update_banking("C") 

		ELSE 

			#work out the opening balance.
			LET modu_op_base_bal_amt = work_out_base_amts(modu_clo_base_bal_amt, 
			modu_rec_banking.bk_sh_no , 
			modu_rec_banking.bk_acct) 

			CALL update_banking("O") 

		END IF 


	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


############################################################
# FUNCTION update_banking(p_type_ind)
#
#  writes the base amounts TO the record, the easy bit.
############################################################
FUNCTION update_banking(p_type_ind) 
	DEFINE p_type_ind CHAR(1) 

	IF p_type_ind = "C" THEN 

		UPDATE banking 
		SET base_debit_amt = modu_clo_base_bal_amt 
		WHERE rowid = modu_pv_rowid 

	ELSE 

		UPDATE banking 
		SET base_cred_amt = modu_op_base_bal_amt 
		WHERE rowid = modu_pv_rowid 

	END IF 

END FUNCTION 


############################################################
# FUNCTION work_out_base_amts( p_clo_amt, p_bk_sh_no , p_acct)
#
#
############################################################
FUNCTION work_out_base_amts( p_clo_amt, p_bk_sh_no , p_acct) 
	DEFINE p_clo_amt DECIMAL(16,4) 
	DEFINE p_bk_sh_no SMALLINT 
	DEFINE p_acct LIKE banking.bk_acct 
	DEFINE l_bkdt DATE 
	DEFINE l_cred_amt DECIMAL (16,4) 
	DEFINE l_debit_amt DECIMAL (16,4) 


	#first decrement all the banking rows.
	DECLARE bk_curs CURSOR FOR 
	SELECT bk_bankdt, 
	sum(bk_debit), 
	sum(bk_cred) 
	FROM banking 
	WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND bk_acct = p_acct 
	AND bk_sh_no = p_bk_sh_no 
	AND bk_type NOT matches "X*" #don't want balance records 

	GROUP BY bk_bankdt 

	FOREACH bk_curs INTO l_bkdt, l_debit_amt, l_cred_amt 

		LET l_cred_amt = check_null(l_cred_amt) 
		LET l_debit_amt = check_null(l_debit_amt) 

		LET l_cred_amt = conv_currency(l_cred_amt, glob_rec_kandoouser.cmpy_code, 
		modu_rec_bank.currency_code, 
		"F", l_bkdt, "S") 

		LET l_debit_amt = conv_currency(l_debit_amt, glob_rec_kandoouser.cmpy_code, 
		modu_rec_bank.currency_code, 
		"F", l_bkdt, "S") 

		LET p_clo_amt = p_clo_amt - l_cred_amt 
		LET p_clo_amt = p_clo_amt + l_debit_amt 

	END FOREACH 

	#now add back all the cheques.
	SELECT sum(cheque.pay_amt / cheque.conv_qty) 
	INTO l_debit_amt 
	FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_acct_code = p_acct 
	AND rec_state_num = p_bk_sh_no 
	AND conv_qty IS NOT NULL 

	IF l_debit_amt IS NOT NULL THEN 
		LET p_clo_amt = p_clo_amt + l_debit_amt 
	END IF 

	RETURN p_clo_amt 

END FUNCTION 


############################################################
# FUNCTION check_null(p_amt)
#
#
############################################################
FUNCTION check_null(p_amt) 

	DEFINE p_amt DECIMAL (16,4) 

	IF p_amt IS NULL THEN 
		RETURN 0 
	ELSE 
		RETURN p_amt 
	END IF 

END FUNCTION