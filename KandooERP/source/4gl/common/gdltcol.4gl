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

	Source code beautified by beautify.pl on 2020-01-02 10:35:12	$Id: $
}


# Description :

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION delete_rptcol(p_cmpy_code, p_rpt_id, p_col_id)
#
# This module deletes all rows associated with the
# parameters cmpy_code, rpt_id FOR COLUMN details.
############################################################
FUNCTION delete_rptcol(p_cmpy_code,p_rpt_id,p_col_id) 
	DEFINE p_cmpy_code LIKE cheque.cmpy_code 
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE p_col_id LIKE rptcol.col_id 
	DEFINE r_err_message CHAR(40) 

	GOTO bypass2 
	LABEL recovery: 
	RETURN r_err_message 

	LABEL bypass2: 

	LET r_err_message = "gdltcol - Deleting rptcol rows." 

	DELETE FROM rptcol 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	#Delete All other COLUMN detail rows.

	#Delete rptcoldesc details.
	LET r_err_message = "gdltcol - Deleting rptcoldesc rows." 
	DELETE FROM rptcoldesc 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	#Delete colitem details.
	LET r_err_message = "gdltcol - Deleting colitem rows." 
	DELETE FROM colitem 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	#Delete colitemdetl details.
	LET r_err_message = "gdltcol - Deleting colitemdetl rows." 
	DELETE FROM colitemdetl 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	#Delete colitemcolid details.
	LET r_err_message = "gdltcol - Deleting colitemcolid rows." 
	DELETE FROM colitemcolid 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	#Delete colitemval details.
	LET r_err_message = "gdltcol - Deleting colitemval rows." 
	DELETE FROM colitemval 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND col_uid = p_col_id 

	LET r_err_message = "gdltcol - Delete Finished with no errors" 

	RETURN r_err_message 
END FUNCTION 
