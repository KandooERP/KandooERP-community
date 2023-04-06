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

	Source code beautified by beautify.pl on 2020-01-02 17:31:20	$Id: $
}


# Purpose - BOR Item Delete

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	err_continue CHAR(1), 
	err_message CHAR(50) 

END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("M17") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL delete_parent() 

END MAIN 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION delete_parent() 

	DEFINE 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.parent_part_code, 
	fv_msg_text CHAR(51), 
	fv_cnt SMALLINT 

	OPEN WINDOW w1_m124 with FORM "M124" 
	CALL  windecoration_m("M124") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE " ESC TO Accept - DEL TO Exit"

	WHILE true 
		INPUT fv_parent_part_code FROM parent_part_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CALL show_parents(glob_rec_kandoouser.cmpy_code) RETURNING fv_part_code 

				IF fv_part_code IS NOT NULL THEN 
					LET fv_parent_part_code = fv_part_code 
					NEXT FIELD parent_part_code 
				END IF 

			AFTER FIELD parent_part_code 
				IF fv_parent_part_code IS NULL THEN 
					LET msgresp = kandoomsg("M",9507,"") 					# ERROR "Parent product code must be entered"
					NEXT FIELD parent_part_code 
				END IF 

				SELECT unique parent_part_code 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_parent_part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9516,"") 
					# ERROR "This product does NOT exist as a parent in a BOR"
					NEXT FIELD parent_part_code 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		GOTO bypass 

		LABEL recovery: 
		LET err_continue = error_recover(err_message, status) 
		IF err_continue != "Y" THEN 
			EXIT program 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 

			LET err_message = "M17 - DELETE FROM BOR failed" 

			DELETE FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = fv_parent_part_code 

		COMMIT WORK 
		WHENEVER ERROR stop 

		LET msgresp = kandoomsg("M", 7100, fv_parent_part_code) 
		# prompt "<part code> deleted successfully - Any key TO continue"
	END WHILE 

	CLOSE WINDOW w1_m124 

END FUNCTION 
