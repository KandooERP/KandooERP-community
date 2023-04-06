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

	Source code beautified by beautify.pl on 2020-01-03 14:28:56	$Id: $
}



#   This module deletes the current row of the selected SET.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW2_GLOBALS.4gl" 


############################################################
# FUNCTION hdr_dlte()
#
#Description         :   This FUNCTION deletes the current row of the
#                        selected SET AND any COLUMN AND line information
#                        associated with it.
#Incoming parameters :   None
#RETURN parameters   :   None
#Impact GLOBALS      :   glob_rec_hdrhead
#perform screens     :
############################################################
FUNCTION hdr_dlte() 
	--	DEFINE l_counter SMALLINT
	--	DEFINE l_prmpt_text CHAR(60)
	DEFINE l_msgresp LIKE language.yes_flag 

	IF upshift(kandoomsg("G",3505,glob_rec_rpthead.rpt_id)) = "Y" THEN 
		IF NOT delete_rpthead() THEN 
			LET l_msgresp = kandoomsg("G",7007,glob_rec_rpthead.rpt_id) 
			#7007 "Report Header ??????? NOT deleted"
		END IF 
		CLEAR FORM 
	END IF 
END FUNCTION #hdr_dlte() 


############################################################
# FUNCTION delete_rpthead()
#
#
############################################################
FUNCTION delete_rpthead() 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_col_uid LIKE rptcol.col_uid 
	DEFINE l_line_uid LIKE rptline.line_uid 

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again != "Y" THEN 
		RETURN (FALSE) 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DELETE FROM rpthead 
		WHERE cmpy_code = glob_rec_rpthead.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		DECLARE col_curs CURSOR FOR 
		SELECT col_uid 
		FROM rptcol 
		WHERE cmpy_code = glob_rec_rpthead.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		FOREACH col_curs INTO l_col_uid 
			CALL delete_rptcol(glob_rec_kandoouser.cmpy_code, glob_rec_rpthead.rpt_id, l_col_uid) 
			RETURNING l_err_message # returns ERROR MESSAGE 
			IF status THEN EXIT FOREACH END IF 
			END FOREACH 
			IF status THEN GOTO recovery END IF 
				DECLARE line_curs CURSOR FOR 
				SELECT line_uid 
				FROM rptline 
				WHERE cmpy_code = glob_rec_rpthead.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				FOREACH line_curs INTO l_line_uid 
					CALL delete_rptline(glob_rec_kandoouser.cmpy_code, glob_rec_rpthead.rpt_id, l_line_uid) 
					RETURNING l_err_message # returns ERROR MESSAGE 
					IF status THEN EXIT FOREACH END IF 
					END FOREACH 
					IF status THEN GOTO recovery END IF 

					COMMIT WORK 

					RETURN true 
END FUNCTION 
