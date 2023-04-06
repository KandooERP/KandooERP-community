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





############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION delete_rptline(p_cmpy_code, p_rpt_id, p_line_uid)
#
#  This module deletes all rows associated with the
#  parameters cmpy_code, rpt_id FOR line details.
############################################################
FUNCTION delete_rptline(p_cmpy_code,p_rpt_id,p_line_uid) 
	DEFINE p_cmpy_code LIKE rptline. cmpy_code
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE p_line_uid INTEGER 
	DEFINE r_err_message CHAR(40) 

	GOTO bypass2 
	LABEL recovery: 
	RETURN r_err_message 

	LABEL bypass2: 
	WHENEVER ERROR GOTO recovery 

	LET r_err_message = "gdltline - Deleting rptcol rows." 
	DELETE FROM rptline 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND line_uid = p_line_uid 

	#Delete existing glline details IF they exist
	LET r_err_message = "gdltline - Deleting glline rows." 
	DELETE FROM glline 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND line_uid = p_line_uid 

	#Delete existing gllinedetl details IF they exist
	LET r_err_message = "gdltline - Deleting gllinedetl rows." 
	DELETE FROM gllinedetl 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND line_uid = p_line_uid 

	#Delete existing glline details IF they exist
	LET r_err_message = "gdltline - Deleting calcline rows." 
	DELETE FROM calcline 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND line_uid = p_line_uid 

	#Delete existing glline details IF they exist
	LET r_err_message = "gdltline - Deleting txtline rows." 
	DELETE FROM txtline 
	WHERE cmpy_code = p_cmpy_code 
	AND rpt_id = p_rpt_id 
	AND line_uid = p_line_uid 

	LET r_err_message = "gdltline - Delete Finished with no errors" 

	RETURN r_err_message 

END FUNCTION 
