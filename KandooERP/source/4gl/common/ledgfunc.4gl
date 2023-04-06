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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}



# Multiledger Inventory Posting


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION get_ledg_accts(p_cmpy_code, p_acct1_code, p_acct2_code, p_start_num, p_length_num)
#
#
############################################################
FUNCTION get_ledg_accts(p_cmpy_code,p_acct1_code,p_acct2_code,p_start_num,p_length_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct1_code LIKE coa.acct_code 
	DEFINE p_acct2_code LIKE coa.acct_code 
	DEFINE p_start_num LIKE structure.start_num 
	DEFINE p_length_num LIKE structure.length_num 
	DEFINE l_flex1_code LIKE validflex.flex_code 
	DEFINE l_flex2_code LIKE validflex.flex_code 
	DEFINE l_ledg1_acct LIKE ledgerreln.acct1_code 
	DEFINE l_ledg2_acct LIKE ledgerreln.acct1_code 
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 

	LET l_ledg1_acct = NULL 
	LET l_ledg2_acct = NULL 
	LET l_flex1_code = p_acct1_code[p_start_num, p_length_num] 
	LET l_flex2_code = p_acct2_code[p_start_num, p_length_num] 
	IF l_flex1_code != l_flex2_code THEN 
		DECLARE c_ledgerreln CURSOR FOR 
		SELECT * FROM ledgerreln 
		WHERE cmpy_code = p_cmpy_code 
		AND ((flex1_code = l_flex1_code AND 
		flex2_code = l_flex2_code) OR 
		(flex2_code = l_flex1_code AND 
		flex1_code = l_flex2_code)) 
		OPEN c_ledgerreln 
		FETCH c_ledgerreln INTO l_rec_ledgerreln.* 
		IF status != notfound THEN 
			IF l_flex1_code = l_rec_ledgerreln.flex1_code THEN 
				LET l_ledg1_acct = l_rec_ledgerreln.acct1_code 
				LET l_ledg2_acct = l_rec_ledgerreln.acct2_code 
			ELSE 
				LET l_ledg1_acct = l_rec_ledgerreln.acct2_code 
				LET l_ledg2_acct = l_rec_ledgerreln.acct1_code 
			END IF 
		END IF 
		CLOSE c_ledgerreln 
	END IF 
	RETURN l_ledg1_acct, l_ledg2_acct 
END FUNCTION 


