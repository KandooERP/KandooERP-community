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

	Source code beautified by beautify.pl on 2020-01-02 10:35:02	$Id: $
}





############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#######################################################################
# FUNCTION show_acct(p_cmpy)
#
# patch over the account with the segment patches
#######################################################################
FUNCTION account_patch(p_cmpy, p_account_code, p_seg_patch_acct) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_account_code CHAR(18) 
	DEFINE p_seg_patch_acct CHAR(18) 
	DEFINE l_blanks CHAR(18) 
	DEFINE l_question_marks CHAR(18) 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_length_num SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_pos_cnt SMALLINT 
	
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	LET l_blanks = " " 
	LET l_question_marks = "??????????????????" 
	DECLARE structurecurs CURSOR FOR 
	SELECT * 
	INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind = "S" 
	ORDER BY start_num 

	LET l_pos_cnt = 1 
	FOREACH structurecurs 
		LET l_pos_cnt = l_rec_structure.start_num 
		LET l_end_pos = l_pos_cnt + l_rec_structure.length_num 
		LET l_length_num = l_rec_structure.length_num 
		IF p_seg_patch_acct[l_pos_cnt, l_end_pos-1] IS NULL 
		OR p_seg_patch_acct[l_pos_cnt, l_end_pos-1] = l_blanks[1, l_length_num ] 
		OR p_seg_patch_acct[l_pos_cnt, l_end_pos-1] = l_question_marks[1, l_length_num ] 
		THEN 
		ELSE 
			LET p_account_code[l_pos_cnt, l_end_pos - 1] = p_seg_patch_acct[l_pos_cnt, l_end_pos-1] 
		END IF 
	END FOREACH 

	RETURN (p_account_code) 

END FUNCTION 


