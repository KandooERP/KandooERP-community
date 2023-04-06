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

	Source code beautified by beautify.pl on 2020-01-03 10:10:04	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

#   This module deletes the current row of the selected SET.



{
FUNCTION            :   line_dlte
Description         :   This FUNCTION deletes all lines FOR a given line code
Incoming parameters :   None
RETURN parameters   :   fv_status
Impact GLOBALS      :   gr_rptline
perform screens     :
}

FUNCTION line_dlte (fv_line_code) 

	DEFINE 
	fv_line_code LIKE rptlinegrp.line_code, 
	fv_status, 
	fv_count SMALLINT, 
	fv_prmpt_text CHAR(60), 
	fv_err_message CHAR(40), 
	fv_try_again CHAR(1) 


	MESSAGE " " 


	DISPLAY "" at 2,1 

	SELECT count(*) 
	INTO fv_count 
	FROM rpthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 

	IF fv_count > 0 THEN 
		ERROR "There are Reports using this line code - can't delete" 
		RETURN true 
	END IF 

	###LET fv_prmpt_text = "Confirm deletion of REPORT lines  (Y/N) "
	####IF upshift(continue_prompt(fv_prmpt_text)) = "Y" THEN

	IF upshift(kandoomsg("G",1623,"")) = "Y" THEN 
		MESSAGE "Deleting lines FOR ", gr_rptlinegrp.line_code clipped, 
		", please wait..." 

		GOTO bypass 
		LABEL recovery: 
		LET fv_try_again = error_recover(fv_err_message, status) 
		IF fv_try_again != "Y" THEN 
			MESSAGE "Lines deletion FOR ", gr_rptlinegrp.line_code clipped, 
			" NOT successful" 
			SLEEP 1 
			CLEAR FORM 
			RETURN true 
		END IF 

		LABEL bypass: 

		BEGIN WORK 

			DECLARE line_curs CURSOR FOR 
			SELECT * FROM rptline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = gr_rptlinegrp.line_code 

			FOREACH line_curs INTO gr_rptline.* 
				CALL delete_rptline(glob_rec_kandoouser.cmpy_code, gr_rptlinegrp.line_code, gr_rptline.line_uid) 
				RETURNING fv_err_message 
				IF status THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			IF status THEN 
				GOTO recovery 
			END IF 

			DELETE FROM rptlinegrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = gr_rptlinegrp.line_code 

		COMMIT WORK 

		MESSAGE "Lines FOR ",gr_rptlinegrp.line_code clipped, " deleted" 
		LET gv_line_added = false 

		INITIALIZE gr_rptline.* TO NULL 
		INITIALIZE gr_rptlinegrp.* TO NULL 

		SLEEP 1 
		CLEAR FORM 
	ELSE 
		MESSAGE "Lines FOR ",gr_rptlinegrp.line_code clipped, " NOT deleted" 
		SLEEP 1 
		RETURN true 
	END IF 

	RETURN false 

END FUNCTION 
