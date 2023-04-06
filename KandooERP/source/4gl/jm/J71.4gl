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
# \brief module J71. - JM Resource Addition
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/J7_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J71_GLOBALS.4gl"
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("J71") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_j_jm() #init a/ar module/program 
	--CALL J71_main()
	
	OPEN WINDOW J120 with FORM "J120" -- alch kd-747 
	CALL winDecoration_j("J120") -- alch kd-747 
	LET msgresp = kandoomsg("J",1426,"") 
	# Enter Resource details; OK TO continue.
	WHILE newres() 
		#      OPEN WINDOW J71w1 AT 10,10 with 4 rows,52 columns
		#         ATTRIBUTE(border, menu line 3)      -- alch KD-747
		LET msgresp = kandoomsg("J",1008,pr_jmresource.res_code) 	#1008 "Resource BRICK Added Successfully"
		MENU " Resource Entry" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","J71","menu-resource_entry-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Add " " Add Another Resource" 
				EXIT MENU 
			COMMAND KEY(interrupt,"E")"Exit" " EXIT PROGRAM" 
				EXIT program 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		#      CLOSE WINDOW J71w1      -- alch KD-747
		CLEAR FORM 
	END WHILE 
	CLOSE WINDOW j120 
END MAIN 


FUNCTION newres () 
	INITIALIZE pr_jmresource.* TO NULL 
	DISPLAY pr_jmresource.res_code, 
	pr_jmresource.desc_text 
	TO res_code, 
	desc_text 

	WHILE true 
		INPUT pr_jmresource.res_code, 
		pr_jmresource.desc_text, 
		pr_jmresource.resgrp_code WITHOUT DEFAULTS 
		FROM res_code, 
		desc_text, 
		resgrp_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J71","input-pr_jmresource-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				IF infield (res_code) THEN 
					LET pr_jmresource.res_code = show_res(glob_rec_kandoouser.cmpy_code) 
					SELECT desc_text 
					INTO pr_jmresource.desc_text 
					FROM jmresource 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND res_code = pr_jmresource.res_code 
					DISPLAY BY NAME pr_jmresource.res_code, 
					pr_jmresource.desc_text 

				END IF 
				IF infield (resgrp_code) THEN 
					LET pr_jmresource.resgrp_code = show_resg(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_jmresource.resgrp_code 

				END IF 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
			AFTER FIELD res_code 
				IF pr_jmresource.res_code IS NULL THEN 
					#ERROR " Resource Code must be entered "
					LET msgresp = kandoomsg("J",9514," ") 
					NEXT FIELD res_code 
				END IF 
				SELECT count(*) 
				INTO cnt 
				FROM jmresource 
				WHERE jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jmresource.res_code 
				IF cnt != 0 THEN 
					#ERROR " The Resource Exists - Resource Code must be Unique"
					LET msgresp = kandoomsg("J",9562," ") 
					NEXT FIELD res_code 
				END IF 
			AFTER FIELD desc_text 
				IF pr_jmresource.desc_text = " " 
				OR pr_jmresource.desc_text IS NULL THEN 
					#ERROR "value must be entered"
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD desc_text 
				END IF 
			AFTER FIELD resgrp_code 
				IF pr_jmresource.resgrp_code IS NULL THEN 
					#ERROR "value must be entered"
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD resgrp_code 
				END IF 
				IF pr_jmresource.resgrp_code IS NOT NULL THEN 
					SELECT count(*) 
					INTO cnt 
					FROM resgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND resgrp_code = pr_jmresource.resgrp_code 
					IF cnt = 0 THEN 
						#ERROR "Resource group IS invalid - Try window"
						LET msgresp = kandoomsg("J",9580," ") 
						NEXT FIELD resgrp_code 
					END IF 
				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					EXIT program 
				END IF 
				IF pr_jmresource.res_code IS NULL THEN 
					#ERROR " Resource Code must be entered "
					LET msgresp = kandoomsg("J",9514," ") 
					NEXT FIELD res_code 
				END IF 
				SELECT count(*) 
				INTO cnt 
				FROM jmresource 
				WHERE jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jmresource.res_code 
				IF cnt != 0 THEN 
					#ERROR " The Resource Exists - Resource Code must be Unique"
					LET msgresp = kandoomsg("J",9562," ") 
					NEXT FIELD res_code 
				END IF 
				IF pr_jmresource.desc_text = " " 
				OR pr_jmresource.desc_text IS NULL THEN 
					#ERROR "Value must be entered"
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD desc_text 
				END IF 
				IF pr_jmresource.resgrp_code IS NULL THEN 
					#ERROR "value must be entered"
					LET msgresp = kandoomsg("U",9102," ") 
					NEXT FIELD resgrp_code 
				END IF 
				IF pr_jmresource.resgrp_code IS NOT NULL THEN 
					SELECT count(*) 
					INTO cnt 
					FROM resgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND resgrp_code = pr_jmresource.resgrp_code 
					IF cnt = 0 THEN 
						#ERROR "Resource group IS invalid - Try window"
						LET msgresp = kandoomsg("J",9580," ") 
						NEXT FIELD resgrp_code 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			#LET int_flag = FALSE
			#LET quit_flag = FALSE
			#RETURN FALSE
			EXIT WHILE 
		END IF 
		LET pr_jmresource.cost_ind = 1 
		LET pr_jmresource.bill_ind = 1 
		LET pr_jmresource.allocation_ind = "A" 
		LET pr_jmresource.allocation_flag = "1" 
		CALL read_resource() 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			#  RETURN TRUE
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
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
		LET err_message = " J71 - Inserting Resource" 
		WHENEVER ERROR GOTO recovery 
		LET pr_jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO jmresource VALUES (pr_jmresource.*) 
		WHENEVER ERROR stop 
	COMMIT WORK 
	RETURN true 
END FUNCTION 
