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

	Source code beautified by beautify.pl on 2020-01-03 14:28:28	Source code beautified by beautify.pl on 2019-11-01 09:53:15	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G13 provides Account/detail inquiry facilites FOR foreign
#            AND reporting currencies

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION base_curr_ledg_sum(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code)
#
#
############################################################
FUNCTION base_curr_ledg_sum(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 
	DEFINE p_curr_code LIKE currency.currency_code 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_accounthistcur DYNAMIC ARRAY OF RECORD #array[50] OF RECORD 
		currency_code LIKE accounthistcur.currency_code, 
		base_debit_amt LIKE accounthistcur.base_debit_amt, 
		base_credit_amt LIKE accounthistcur.base_credit_amt, 
		base_close_amt LIKE accounthistcur.base_close_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_size SMALLINT 

	OPEN WINDOW wg198 with FORM "G198" 
	CALL windecoration_g("G198") 

	SELECT * 
	INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		CLOSE WINDOW wg198 
		RETURN " " 
	END IF 

	SELECT * 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.acct_code = p_acct 
	AND coa.cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg198 
		RETURN " " 
	END IF 

	SELECT * 
	INTO l_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		CLOSE WINDOW wg198 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_accounthist.* 
	FROM accounthist 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	AND period_num = p_per 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg198 
		RETURN " " 
	END IF 

	DISPLAY p_cmpy, 
	l_rec_company.name_text, 
	p_acct, 
	l_rec_coa.desc_text, 
	p_acc_year, 
	p_per, 
	l_rec_accounthist.open_amt, 
	l_rec_accounthist.close_amt, 
	l_rec_accounthist.debit_amt, 
	l_rec_accounthist.credit_amt 
	TO accounthist.cmpy_code, 
	company.name_text, 
	accounthist.acct_code, 
	coa.desc_text, 
	accounthist.year_num, 
	accounthist.period_num, 
	accounthist.open_amt, 
	accounthist.close_amt, 
	accounthist.debit_amt, 
	accounthist.credit_amt 


	DECLARE acchistcurr CURSOR FOR 
	SELECT * 
	INTO l_rec_accounthistcur.* 
	FROM accounthistcur 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	AND period_num = p_per 

	LET l_idx = 0 
	FOREACH acchistcurr 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_accounthistcur[l_idx].currency_code = 
		l_rec_accounthistcur.currency_code 
		LET l_arr_rec_accounthistcur[l_idx].base_debit_amt = 
		l_rec_accounthistcur.base_debit_amt 
		LET l_arr_rec_accounthistcur[l_idx].base_credit_amt = 
		l_rec_accounthistcur.base_credit_amt 
		LET l_arr_rec_accounthistcur[l_idx].base_close_amt = 
		l_rec_accounthistcur.base_close_amt 
		#      IF l_idx > 49 THEN
		#         LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         EXIT FOREACH
		#      END IF
	END FOREACH 
	LET l_arr_size = l_idx 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("U",9101,"") 
		CLOSE WINDOW wg198 
		RETURN " " 
	END IF 

	#   CALL set_count (l_idx)

	LET l_msgresp = kandoomsg("G",1007,"") 
	INPUT ARRAY l_arr_rec_accounthistcur WITHOUT DEFAULTS FROM sr_accounthistcur.* attributes(unbuffered) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G13c","input-arr-accounthistcur") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_accounthistcur.currency_code = 
			l_arr_rec_accounthistcur[l_idx].currency_code 
			IF l_idx > l_arr_size THEN 
				LET l_msgresp = kandoomsg("G",9001,"") 
			END IF 

		AFTER FIELD currency_code 
			LET l_arr_rec_accounthistcur[l_idx].currency_code = 
			l_rec_accounthistcur.currency_code 
			#DISPLAY l_arr_rec_accounthistcur[l_idx].* TO sr_accounthistcur[scrn].*


		BEFORE FIELD base_debit_amt 
			IF l_arr_rec_accounthistcur[l_idx].currency_code IS NULL THEN 
				LET l_msgresp = kandoomsg("R",9002,"") 
				NEXT FIELD currency_code 
			END IF 
			LET l_rec_accounthistcur.currency_code = 
			l_arr_rec_accounthistcur[l_idx].currency_code 
			EXIT INPUT 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				LET l_rec_accounthistcur.currency_code = NULL 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW wg198 

	RETURN l_rec_accounthistcur.currency_code 
END FUNCTION 


############################################################
# FUNCTION ledg_detl(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code)
#
#
############################################################
FUNCTION ledg_detl(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 
	DEFINE p_curr_code LIKE currency.currency_code 

	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_disp_curr_code LIKE currency.currency_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_accountledger DYNAMIC ARRAY OF RECORD #array[250] OF RECORD 
		currency_code LIKE accountledger.currency_code, 
		desc_text LIKE accountledger.desc_text, 
		for_debit_amt LIKE accountledger.for_debit_amt, 
		for_credit_amt LIKE accountledger.for_credit_amt 
	END RECORD 
	DEFINE l_arr_rec_seq DYNAMIC ARRAY OF RECORD # array[250] OF RECORD 
		seq_num LIKE accountledger.seq_num 
	END RECORD 
	DEFINE l_seq LIKE accountledger.seq_num 
	DEFINE l_idx SMALLINT 
	#	DEFINE l_arr_size SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg199 with FORM "G199" 
	CALL windecoration_g("G199") 

	SELECT * 
	INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		CLOSE WINDOW wg199 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.acct_code = p_acct 
	AND coa.cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg199 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		CLOSE WINDOW wg199 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_currency.* 
	FROM currency 
	WHERE currency_code = p_curr_code 

	IF status = NOTFOUND THEN 
		LET l_rec_currency.desc_text = " " 
	END IF 

	IF p_curr_code IS NULL THEN 
		LET l_disp_curr_code = l_rec_glparms.base_currency_code 
	ELSE 
		LET l_disp_curr_code = p_curr_code 
	END IF 

	SELECT * 
	INTO l_rec_accounthist.* 
	FROM accounthist 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	AND period_num = p_per 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg199 
		RETURN 
	END IF 

	DISPLAY p_cmpy TO accounthist.cmpy_code 
	DISPLAY l_rec_company.name_text TO company.name_text 
	DISPLAY p_acct TO accounthist.acct_code 
	DISPLAY l_rec_coa.desc_text TO coa.desc_text 
	DISPLAY p_acc_year TO accounthist.year_num 
	DISPLAY p_per TO accounthist.period_num 
	DISPLAY p_curr_code TO formonly.currency_code 
	DISPLAY l_rec_currency.desc_text TO currency.desc_text 
	DISPLAY l_disp_curr_code TO glparms.base_currency_code 

	IF p_curr_code IS NULL THEN 
		DECLARE accledg CURSOR FOR 
		SELECT * 
		INTO l_rec_accountledger.* 
		FROM accountledger 
		WHERE cmpy_code = p_cmpy 
		AND acct_code = p_acct 
		AND year_num = p_acc_year 
		AND period_num = p_per 
	ELSE 
		DECLARE accledgcurr CURSOR FOR 
		SELECT * 
		INTO l_rec_accountledger.* 
		FROM accountledger 
		WHERE cmpy_code = p_cmpy 
		AND acct_code = p_acct 
		AND year_num = p_acc_year 
		AND period_num = p_per 
		AND currency_code = p_curr_code 
	END IF 

	LET l_idx = 0 
	IF p_curr_code IS NULL THEN 
		FOREACH accledg 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_accountledger[l_idx].currency_code = l_rec_accountledger.currency_code 
			LET l_arr_rec_accountledger[l_idx].desc_text = l_rec_accountledger.desc_text 
			LET l_arr_rec_accountledger[l_idx].for_debit_amt = l_rec_accountledger.debit_amt 
			LET l_arr_rec_accountledger[l_idx].for_credit_amt = l_rec_accountledger.credit_amt 
			LET l_arr_rec_seq[l_idx].seq_num = l_rec_accountledger.seq_num 
		END FOREACH 
	ELSE 
		FOREACH accledgcurr 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_accountledger[l_idx].currency_code = l_rec_accountledger.currency_code 
			LET l_arr_rec_accountledger[l_idx].desc_text = l_rec_accountledger.desc_text 
			LET l_arr_rec_accountledger[l_idx].for_debit_amt = l_rec_accountledger.for_debit_amt 
			LET l_arr_rec_accountledger[l_idx].for_credit_amt = l_rec_accountledger.for_credit_amt 
			LET l_arr_rec_seq[l_idx].seq_num = l_rec_accountledger.seq_num 
		END FOREACH 
	END IF 

	--	LET l_arr_size = l_idx

	IF l_idx = 0 THEN 
		CALL fgl_winmessage("Error - Ledger Details not found","I'm currently not sure IF this is normal, OR a db data problem OR a program bug\n should do: listing the transactions FOR the balances","error") 
		LET l_msgresp = kandoomsg("U",9101,"") 
		CLOSE WINDOW wg199 
		RETURN 
	END IF 

	#   CALL set_count (l_idx)

	LET l_msgresp = kandoomsg("G",1007,"") 
	--   INPUT ARRAY l_arr_rec_accountledger WITHOUT DEFAULTS FROM sr_accountledger.*  ATTRIBUTES(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_accountledger TO sr_accountledger.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G13c","input-arr-accountledger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_idx > 0 THEN 
				LET l_rec_accountledger.currency_code = l_arr_rec_accountledger[l_idx].currency_code 
				--				IF l_idx > l_arr_size THEN
				--					LET l_msgresp = kandoomsg("G",9001,"")
				--				END IF

				IF l_arr_rec_accountledger[l_idx].currency_code IS NULL THEN 
					LET l_msgresp = kandoomsg("R",9002,"") 
					--NEXT FIELD currency_code
				END IF 
				CALL disp_ledger_details(p_cmpy, p_acct, p_acc_year, p_per, l_seq) 
			END IF 

		AFTER ROW 
			--AFTER FIELD currency_code
			IF l_idx > 0 THEN 
				LET l_arr_rec_accountledger[l_idx].currency_code = 
				l_rec_accountledger.currency_code 
				#DISPLAY l_arr_rec_accountledger[l_idx].* TO sr_accountledger[scrn].*

				LET l_seq = l_arr_rec_seq[l_idx].seq_num 
			END IF 
			--   BEFORE FIELD desc_text
			--      IF l_arr_rec_accountledger[l_idx].currency_code IS NULL THEN
			--         LET l_msgresp = kandoomsg("R",9002,"")
			--         --NEXT FIELD currency_code
			--      END IF
			--      CALL disp_ledger_details(p_cmpy, p_acct, p_acc_year, p_per, l_seq)
			--      --NEXT FIELD currency_code

		AFTER DISPLAY 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END DISPLAY 

	CLOSE WINDOW wg199 

END FUNCTION 


############################################################
# FUNCTION disp_ledger_details(p_cmpy, p_acct, p_acc_year, p_per, p_seq)
#
#
############################################################
FUNCTION disp_ledger_details(p_cmpy, p_acct, p_acc_year, p_per, p_seq) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accountledger.acct_code 
	DEFINE p_acc_year LIKE accountledger.year_num 
	DEFINE p_per LIKE accountledger.period_num 
	DEFINE p_seq LIKE accountledger.seq_num 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_account_ledger char(150) 
	DEFINE l_ans char(1) 

	DEFINE arg_str1 STRING 
	DEFINE arg_str2 STRING 
	DEFINE arg_str3 STRING 
	DEFINE arg_str4 STRING 

	OPEN WINDOW wg200 with FORM "G200" 
	CALL windecoration_g("G200") 
	CALL ui.interface.refresh() 

	SELECT * 
	INTO l_rec_accountledger.* 
	FROM accountledger 
	WHERE cmpy_code = p_cmpy 
	AND accountledger.acct_code = p_acct 
	AND accountledger.year_num = p_acc_year 
	AND accountledger.period_num = p_per 
	AND accountledger.seq_num = p_seq 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"Ledger Details not found for this!") #@no RECORD found MESSAGE ? 
		CALL ui.interface.refresh() 
		SLEEP 3 
		CALL fgl_winmessage("Searching for Ledger Details","No Ledger Details found!","info") 
		CLOSE WINDOW wg200 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_journal.* 
	FROM journal 
	WHERE cmpy_code = l_rec_accountledger.cmpy_code 
	AND jour_code = l_rec_accountledger.jour_code 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg200 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = l_rec_accountledger.cmpy_code 
	AND acct_code = l_rec_accountledger.acct_code 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9226,"") 
		CLOSE WINDOW wg200 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = l_rec_accountledger.cmpy_code 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		CLOSE WINDOW wg200 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		CLOSE WINDOW wg200 
		RETURN 
	END IF 

	DISPLAY l_rec_accountledger.cmpy_code, 
	l_rec_company.name_text, 
	l_rec_accountledger.acct_code, 
	l_rec_coa.desc_text, 
	l_rec_accountledger.year_num, 
	l_rec_accountledger.period_num, 
	l_rec_accountledger.jour_code, 
	l_rec_journal.desc_text, 
	l_rec_accountledger.jour_num, 
	l_rec_accountledger.jour_seq_num, 
	l_rec_accountledger.seq_num, 
	l_rec_accountledger.ref_text, 
	l_rec_accountledger.desc_text, 
	l_rec_accountledger.tran_date, 
	l_rec_accountledger.ref_num, 
	l_rec_accountledger.currency_code, 
	l_rec_accountledger.for_debit_amt, 
	l_rec_accountledger.for_credit_amt, 
	l_rec_glparms.base_currency_code, 
	l_rec_accountledger.debit_amt, 
	l_rec_accountledger.credit_amt, 
	l_rec_accountledger.conv_qty 
	TO accountledger.cmpy_code, 
	company.name_text, 
	accountledger.acct_code, 
	coa.desc_text, 
	accountledger.year_num, 
	accountledger.period_num, 
	accountledger.jour_code, 
	journal.desc_text, 
	accountledger.jour_num, 
	accountledger.jour_seq_num, 
	accountledger.seq_num, 
	accountledger.ref_text, 
	accountledger.desc_text, 
	accountledger.tran_date, 
	accountledger.ref_num, 
	accountledger.currency_code, 
	accountledger.for_debit_amt, 
	accountledger.for_credit_amt, 
	glparms.base_currency_code, 
	accountledger.debit_amt, 
	accountledger.credit_amt, 
	accountledger.conv_qty 

	IF promptTF("",kandoomsg2("G",8032,""),1)	THEN
		CALL jo_det_scan(p_cmpy,l_rec_accountledger.jour_num) 
	END IF 
	IF promptTF("",kandoomsg2("G",8003,""),1)	THEN
		LET l_account_ledger = l_rec_accountledger.jour_num, 
		"|",l_rec_accountledger.acct_code 

		LET arg_str1 = "TRAN_TYPE_IND=", trim(l_rec_accountledger.tran_type_ind) 
		LET arg_str2 = "REF_TEXT=", trim(l_rec_accountledger.ref_text) 
		LET arg_str3 = "REF_NUM=", trim(l_rec_accountledger.ref_num) 
		LET arg_str4 = "ACCOUNT_LEDGER=", trim(l_account_ledger) 

		CALL run_prog("GXX",arg_str1, 
		arg_str2, 
		arg_str3, 
		arg_str4) 
	END IF 

	CLOSE WINDOW wg200 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 
