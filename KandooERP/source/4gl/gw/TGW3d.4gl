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

	Source code beautified by beautify.pl on 2020-01-03 10:10:03	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 

#   This module deletes the current row of the selected SET.



{
FUNCTION            :   col_dlte
Description         :   This FUNCTION deletes the current row of the
                        selected SET AND all rows associated with it.
Incoming parameters :   None
RETURN parameters   :   fv_dltd - indicates successful delete
Impact GLOBALS      :   gr_rptcol
perform screens     :
}

FUNCTION col_dlte () 

	DEFINE fv_dltd, 
	fv_status, 
	fv_count SMALLINT, 
	fv_col_code LIKE rptcolgrp.col_code 

	MESSAGE " " 
	DISPLAY "" at 2,1 

	LET fv_dltd = false 
	LET fv_col_code = gr_rptcolgrp.col_code 

	BEGIN WORK 

		MENU "DELETE" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","TGW3d","menu-DELETE-1") -- albo kd-515 

			ON ACTION "WEB-HELP" -- albo kd-378 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Column" "Delete displayed COLUMN" 
				MESSAGE "Deleting COLUMN ",gr_rptcol.col_id, ", please wait..." 
				CALL delete_1rptcol() 
				RETURNING fv_status 

				#Now shuffle all columns TO remove the deleted gap.
				UPDATE rptcol 
				SET col_id = col_id - 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcol.col_code 
				AND col_id > gr_rptcol.col_id 

				IF fv_status = 0 THEN 
					MESSAGE "Column ",gr_rptcol.col_id, " deleted" 
					SLEEP 1 
					CLEAR FORM 
					INITIALIZE gr_rptcol.* TO NULL 
					LET fv_dltd = true 
				ELSE 
					MESSAGE "Column ",gr_rptcol.col_id, " NOT deleted" 
					SLEEP 1 
				END IF 

				EXIT MENU 

			COMMAND "Group" "Delete COLUMN code, AND all associated columns" 

				SELECT count(*) 
				INTO fv_count 
				FROM rpthead 
				WHERE cmpy_code = gr_rptcolgrp.cmpy_code 
				AND col_code = gr_rptcolgrp.col_code 

				IF fv_count > 0 THEN 
					ERROR "There are Reports using this COLUMN code - can't delete" 
					EXIT MENU 
				END IF 

				DECLARE col_curs CURSOR FOR 
				SELECT * 
				FROM rptcol 
				WHERE cmpy_code = gr_rptcol.cmpy_code 
				AND col_code = gr_rptcol.col_code 

				MESSAGE "Deleting COLUMN group ",gr_rptcol.col_code clipped, 
				", please wait..." 

				FOREACH col_curs INTO gr_rptcol.* 
					CALL delete_1rptcol() 
					RETURNING fv_status 
					IF fv_status <> 0 THEN 
						EXIT FOREACH 
					END IF 
				END FOREACH 

				IF fv_status = 0 THEN 
					DELETE FROM rptcolgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND col_code = fv_col_code 
					SLEEP 1 
					CLEAR FORM 
					MESSAGE "Column group ",gr_rptcol.col_code clipped, " deleted" 
					INITIALIZE gr_rptcolgrp.* TO NULL 
					INITIALIZE gr_rptcol.* TO NULL 
					LET fv_dltd = true 
				ELSE 
					MESSAGE "Column group ",gr_rptcol.col_code clipped, " NOT deleted" 
					SLEEP 1 
				END IF 

				EXIT MENU 

			COMMAND KEY (E,interrupt) "DEL TO EXIT" "Cancel delete" 
				EXIT MENU 

		END MENU 

	COMMIT WORK 

	RETURN fv_dltd 

END FUNCTION 


FUNCTION delete_1rptcol() 

	DEFINE fv_try_again CHAR(1), 
	fv_err_message CHAR(40), 
	fv_status SMALLINT 

	LET fv_status = 0 

	GOTO bypass 
	LABEL recovery: 
	LET fv_try_again = error_recover(fv_err_message, status) 
	IF fv_try_again != "Y" THEN 
		MESSAGE "Column ",gr_rptcol.col_id, " Not deleted" 
		SLEEP 1 
		CLEAR FORM 
		LET fv_status = 1 
		RETURN fv_status 
	END IF 

	LABEL bypass: 
	CALL delete_rptcol(glob_rec_kandoouser.cmpy_code, gr_rptcolgrp.col_code, gr_rptcol.col_uid) 
	RETURNING fv_err_message 

	IF status THEN 
		GOTO recovery 
	END IF 

	RETURN status 
END FUNCTION 
