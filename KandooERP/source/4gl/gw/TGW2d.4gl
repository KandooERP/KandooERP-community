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

	Source code beautified by beautify.pl on 2020-01-03 10:10:02	$Id: $
}




#   This module deletes the current row of the selected SET.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 


{
FUNCTION            :   hdr_dlte
Description         :   This FUNCTION deletes the current row of the
                        selected SET AND any COLUMN AND line information
                        associated with it.
Incoming parameters :   None
RETURN parameters   :   None
Impact GLOBALS      :   gr_hdrhead
perform screens     :
}

FUNCTION hdr_dlte () 

	DEFINE 
	fv_counter SMALLINT, 
	fv_prmpt_text CHAR(60) 

	MESSAGE " " 
	DISPLAY "" at 2,2 

	IF upshift(kandoomsg("G",1622,gr_rpthead.rpt_id)) = "Y" THEN 
		MESSAGE "Deleting a REPORT header ",gr_rpthead.rpt_id, ", please wait..." 

		IF delete_rpthead() THEN 
			MESSAGE "Report Header ",gr_rpthead.rpt_id, " deleted" 
			RETURN true 
		ELSE 
			MESSAGE "Report Header ",gr_rpthead.rpt_id, " NOT deleted" 
			RETURN false 
		END IF 
		SLEEP 1 
		CLEAR FORM 
	ELSE 
		MESSAGE "Report Header ",gr_rpthead.rpt_id, " NOT deleted" 
		SLEEP 1 
		RETURN false 
	END IF 

END FUNCTION 

FUNCTION delete_rpthead() 

	DEFINE fv_try_again CHAR(1), 
	fv_err_message CHAR(40), 
	fv_col_uid LIKE rptcol.col_uid, 
	fv_line_uid LIKE rptline.line_uid 

	GOTO bypass 
	LABEL recovery: 
	LET fv_try_again = error_recover(fv_err_message, status) 
	IF fv_try_again != "Y" THEN 
		RETURN (FALSE) 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 


	BEGIN WORK 

		DELETE FROM rpthead 
		WHERE cmpy_code = gr_rpthead.cmpy_code 
		AND rpt_id = gr_rpthead.rpt_id 

	COMMIT WORK 

	RETURN true 
	INITIALIZE gr_rpthead.* TO NULL 

END FUNCTION 
