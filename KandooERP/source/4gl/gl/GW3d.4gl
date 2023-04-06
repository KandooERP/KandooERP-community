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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



#   This module deletes the current row of the selected SET.
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# FUNCTION col_dlte()
#
# Description         :   This FUNCTION deletes the current row of the
#                         selected SET AND all rows associated with it.
# Incoming parameters :   None
# RETURN parameters   :   None
# Impact GLOBALS      :   glob_rec_rptcol
# perform screens     :
############################################################
FUNCTION col_dlte() 
	DEFINE l_counter SMALLINT 
	DEFINE l_prmpt_text CHAR(60) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF upshift(kandoomsg("G",3503,glob_rec_rptcol.col_id)) = "Y" THEN 
		GOTO bypass 
		LABEL recovery: 
		LET l_try_again = error_recover(l_err_message, status) 
		IF l_try_again != "Y" THEN 
			LET l_msgresp = kandoomsg("G",7008,glob_rec_rptcol.col_id) 
			#7008 ??? Report Column NOT deleted.
			CLEAR FORM 
			RETURN 
		END IF 
		LABEL bypass: 
		BEGIN WORK 
			CALL delete_rptcol(glob_rec_kandoouser.cmpy_code, glob_rec_rpthead.rpt_id, glob_rec_rptcol.col_uid) 
			RETURNING l_err_message 
			IF status THEN 
				GOTO recovery 
			END IF 
			UPDATE rptcol 
			SET col_id = col_id - 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 
			AND col_id > glob_rec_rptcol.col_id 
		COMMIT WORK 
		CLEAR FORM 
	END IF 

END FUNCTION #col_dlte() 
