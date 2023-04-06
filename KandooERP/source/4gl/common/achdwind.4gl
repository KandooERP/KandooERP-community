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
# FUNCTION ac_hist_disp( p_cmpy, p_acct, p_acc_year, p_per)
#
# FUNCTION ac_hist_disp displays the history account ledger information
#######################################################################
FUNCTION ac_hist_disp(p_cmpy, p_acct, p_acc_year, p_per) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_accounthist.* FROM accounthist 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	AND period_num = p_per 
	IF status = notfound THEN 
		ERROR kandoomsg2("U",7001,"Ledger Detail") #7001 Logic Error: Ledger Detail RECORD NOT found
		RETURN 
	END IF 
	
	SELECT * INTO l_rec_account.* FROM account 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	IF status = notfound THEN 
		ERROR kandoomsg2("U",7001,"Account Ledger") 	#7001 Logic Error: Account Ledger RECORD NOT found
		RETURN 
	END IF 
	
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	IF status = notfound THEN 
		ERROR kandoomsg2("U",7001,"COA") 	#7001 Logic Error: COA RECORD NOT found
		RETURN 
	END IF 
	
	OPEN WINDOW G105 with FORM "G105" 
	CALL winDecoration_g("G105") -- albo kd-767 

	DISPLAY BY NAME 
		l_rec_accounthist.acct_code, 
		l_rec_coa.desc_text, 
		l_rec_account.bal_amt, 
		l_rec_accounthist.year_num, 
		l_rec_accounthist.period_num, 
		l_rec_accounthist.open_amt, 
		l_rec_accounthist.debit_amt, 
		l_rec_accounthist.credit_amt, 
		l_rec_accounthist.stats_qty, 
		l_rec_accounthist.close_amt, 
		l_rec_accounthist.pre_close_amt, 
		l_rec_accounthist.budg1_amt, 
		l_rec_accounthist.budg2_amt, 
		l_rec_accounthist.budg3_amt, 
		l_rec_accounthist.budg4_amt, 
		l_rec_accounthist.budg5_amt, 
		l_rec_accounthist.budg6_amt, 
		l_rec_accounthist.ytd_pre_close_amt 


	IF  kandoomsg("G",8001,"") = "Y" THEN 
		CALL ac_detl_scan(p_cmpy,p_acct,p_acc_year,p_per,0) 
	END IF 
	
	CLOSE WINDOW G105
	LET int_flag = false 
	LET quit_flag = false
	 
END FUNCTION 
#######################################################################
# END FUNCTION ac_hist_disp( p_cmpy, p_acct, p_acc_year, p_per)
#######################################################################