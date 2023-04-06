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

	Source code beautified by beautify.pl on 2020-01-02 10:35:04	$Id: $
}




# Module bk_ac_ck checks whether the passed account IS a bank account.
# Prohibits the posting of journals TO a bank account IF the cash book
# IS installed.
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION bk_ac_ck(p_cmpy, p_acct, p_cash_book_flag) 
	DEFINE p_cmpy LIKE bank.cmpy_code 
	DEFINE p_acct LIKE bank.acct_code 
	DEFINE p_cash_book_flag LIKE glparms.cash_book_flag 
	DEFINE r_flag SMALLINT 
	DEFINE l_cnt SMALLINT 

	IF p_cash_book_flag = "Y" THEN 
		SELECT count(*) 
		INTO l_cnt 
		FROM bank 
		WHERE cmpy_code = p_cmpy AND 
		acct_code = p_acct 
		IF l_cnt <> 0 THEN 
			ERROR "You may NOT disburse TO a bank account." 
			LET r_flag = true 
		ELSE 
			LET r_flag = false 
		END IF 
	ELSE 
		LET r_flag = false 
	END IF 
	RETURN r_flag 
END FUNCTION 
