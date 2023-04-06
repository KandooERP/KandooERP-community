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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
#######################################################################
# FUNCTION ac_detl_disp(p_cmpy,p_acct,p_acc_year,p_per,p_seq)
#
# FUNCTION ac_detl_disp displays full account ledger detail
#######################################################################
FUNCTION ac_detl_disp(p_cmpy,p_acct,p_acc_year,p_per,p_seq) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accountledger.acct_code 
	DEFINE p_acc_year LIKE accountledger.year_num 
	DEFINE p_per LIKE accountledger.period_num 
	DEFINE p_seq LIKE accountledger.seq_num 
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_account_ledger CHAR(150) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg_str1 STRING 
	DEFINE l_arg_str2 STRING 
	DEFINE l_arg_str3 STRING 
	DEFINE l_arg_str4 STRING 

	OPEN WINDOW G103 with FORM "G103" 
	CALL winDecoration_g("G103") 

	SELECT * INTO l_rec_accountledger.* FROM accountledger 
	WHERE cmpy_code = p_cmpy 
	AND accountledger.acct_code = p_acct 
	AND accountledger.year_num = p_acc_year 
	AND accountledger.period_num = p_per 
	AND accountledger.seq_num = p_seq
	 
	SELECT * INTO l_rec_journal.* FROM journal 
	WHERE cmpy_code = l_rec_accountledger.cmpy_code 
	AND jour_code = l_rec_accountledger.jour_code 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = l_rec_accountledger.cmpy_code 
	AND acct_code = l_rec_accountledger.acct_code 

	DISPLAY l_rec_coa.desc_text TO coa.desc_text 
	DISPLAY l_rec_journal.desc_text TO journal.desc_text
	DISPLAY l_rec_accountledger.desc_text TO accountledger.desc_text 
	 

	DISPLAY BY NAME 
		l_rec_accountledger.acct_code, 
		l_rec_accountledger.year_num, 
		l_rec_accountledger.period_num, 
		l_rec_accountledger.seq_num, 
		l_rec_accountledger.ref_text, 
		l_rec_accountledger.ref_num, 
		l_rec_accountledger.tran_date, 
		l_rec_accountledger.jour_code, 
		l_rec_accountledger.jour_num, 
		l_rec_accountledger.jour_seq_num, 
		l_rec_accountledger.debit_amt, 
		l_rec_accountledger.credit_amt, 
		l_rec_accountledger.stats_qty, 
		l_rec_coa.uom_code 


	IF kandoomsg("G",8002,"") = "Y" THEN 
		CALL jo_det_scan(p_cmpy,l_rec_accountledger.jour_num) 
	END IF 
	
	 
	IF kandoomsg("G",8003,"") = "Y" THEN 
		LET l_account_ledger = l_rec_accountledger.jour_num, 	"|",l_rec_accountledger.acct_code 

		LET l_arg_str1 = "TRAN_TYPE_IND=", trim(l_rec_accountledger.tran_type_ind) 
		LET l_arg_str2 = "REF_TEXT=", trim(l_rec_accountledger.ref_text) 
		LET l_arg_str3 = "REF_NUM=", trim(l_rec_accountledger.ref_num) 
		LET l_arg_str4 = "ACCOUNT_LEDGER=", trim(l_account_ledger) 

		CALL run_prog(
			"GXX",
			l_arg_str1, 
			l_arg_str2, 
			l_arg_str3, 
			l_arg_str4) 
	END IF
	 
	CLOSE WINDOW g103
	 
	LET int_flag = false 
	LET quit_flag = false
	 
END FUNCTION