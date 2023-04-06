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

	Source code beautified by beautify.pl on 2020-01-03 10:10:06	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW6_GLOBALS.4gl" 

# Purpose - Table Maintenance Program functions. These
#           functions are based on the rpthead_group table.
#           This program allows users TO Query, Add AND Update, Delete
#           the different rpthead_group records available.


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	--- Set the interrupt handling  - unfortunately the following statements can
	---                               NOT be placed in the set_options FUNCTION


	CALL setModuleId("GW6") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	#authenticate
	#Note: Different return handling TO OTHER kandoo modules.. do NOT change...
	CALL authenticate(getmoduleid()) RETURNING gv_cmpy_code, gv_username #note: this IS different TO o most kandoo modules 
	CALL init_t_gw() #init batch module 

	CALL set_options() 

	OPEN WINDOW w0_rptgrp with FORM "TG566" 
	CALL windecoration_t("TG566") -- albo kd-768 

	MENU "Menu " 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW6","menu-Menu-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY (a) "Add" "Add a REPORT group" 
			CALL input_rptgrp () 

		COMMAND KEY (Q) "Query" "SELECT records TO delete OR UPDATE" 
			CALL select_rptgrp () 

		COMMAND KEY (E, interrupt) "Exit" "Exit the menu" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW w0_rptgrp 

END MAIN 

------------------------------------------------------------------------------

FUNCTION input_rptgrp () 

	DEFINE lr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE lr_dummy RECORD LIKE rpthead_group.* 
	DEFINE lv_error_flag SMALLINT 
	DEFINE lv_records_count INTEGER 

	MESSAGE "ADD: [INTERRUPT] TO abort, [ESC] TO accept, [CTRL-B] TO browse" 
	attribute(YELLOW) 

	DISPLAY "" at 2,1 

	LET int_flag = false 
	LET quit_flag = false 

	CALL initialize_rptgrp (lr_rpthead_group.*) RETURNING lr_rpthead_group.* 

	INPUT BY NAME lr_rpthead_group.rptgrp_id, 
	lr_rpthead_group.rptgrp_text, 
	lr_rpthead_group.rptgrp_desc2 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW6","input-rptgrp_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" ---------- browse infield(rptgrp_id) 

					CALL pick_rptgrp(gv_cmpy_code) 
					RETURNING lr_dummy.rptgrp_id, 
					lr_dummy.rptgrp_text 


		AFTER FIELD rptgrp_id --------------- section --------------- 

			IF lr_rpthead_group.rptgrp_id IS NULL THEN 

				ERROR "Please Enter a value" 
				attribute(RED) 
				NEXT FIELD rptgrp_id 
			END IF 

			IF exists_rptgrp (lr_rpthead_group.rptgrp_id) THEN 

				ERROR "This REPORT group code already exists in the database" 
				attribute(RED) 
				NEXT FIELD rptgrp_id 
			END IF 


		AFTER FIELD rptgrp_text --------------- section --------------- 

			IF lr_rpthead_group.rptgrp_text IS NULL THEN 

				ERROR "Please Enter rpthead_group Description" 
				attribute(RED) 
				NEXT FIELD rptgrp_text 
			END IF 

		AFTER INPUT ------------------ section ------------------ 

			IF interrupted() THEN 
				CLEAR FORM 
				EXIT INPUT 
			END IF 

			LET lv_records_count = "1" 

			CALL init_array_rpt() 

			IF scroll_rpt(lv_records_count, lr_rpthead_group.*) THEN 

				CALL insert_rptgrp (lr_rpthead_group.*) RETURNING lv_error_flag 

				IF NOT error_trap(lv_error_flag) THEN 

					OPTIONS MESSAGE line LAST 
					MESSAGE "Record Added Successfully" attribute (YELLOW) 
					SLEEP 2 
					OPTIONS MESSAGE line FIRST 

					CALL initialize_rptgrp (lr_rpthead_group.*) 
					RETURNING lr_rpthead_group.* 

					CLEAR FORM 
				ELSE 

					CONTINUE INPUT 
				END IF 
			END IF 

			NEXT FIELD rptgrp_id 
	END INPUT 

END FUNCTION 


------------------------------------------------------------------------------
FUNCTION insert_rptgrp(pr_rpthead_group) 

	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 

	LET pr_rpthead_group.cmpy_code = gv_cmpy_code 

	INSERT INTO rpthead_group VALUES (pr_rpthead_group.*) 

	RETURN status 

END FUNCTION 

------------------------------------------------------------------------------

FUNCTION initialize_rptgrp(pr_rpthead_group) 

	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 

	INITIALIZE pr_rpthead_group.* TO NULL 

	RETURN pr_rpthead_group.* 

END FUNCTION 

------------------------------------------------------------------------------


FUNCTION select_rptgrp() 

	DEFINE lv_records INTEGER 

	LET lv_records = 0 

	WHILE lv_records = 0 

		IF NOT query_rptgrp() THEN 

			RETURN 
		END IF 

		LET lv_records = load_array_rptgrp() 

		IF lv_records = 0 THEN 

			MESSAGE "No records found, please redefine your selection criteria" 
			attribute(YELLOW) 

			CONTINUE WHILE 
		END IF 
	END WHILE 

	CALL scroll_rptgrp(lv_records) 
	CALL close_cursor_rptgrp() 

END FUNCTION 

------------------------------------------------------------------------------

FUNCTION modify_rptgrp(pr_rpthead_group) 

	DEFINE pr_rpthead_group, lr_copy RECORD LIKE rpthead_group.* 
	DEFINE lv_error_flag SMALLINT 
	DEFINE lv_flag SMALLINT 
	DEFINE lv_records_count INTEGER 

	CURRENT WINDOW IS w0_rptgrp 

	MESSAGE "UPDATE: [INTERRUPT] TO abort, [ESC] TO accept" 
	attribute(YELLOW) 

	LET lr_copy.* = pr_rpthead_group.* 

	DISPLAY BY NAME pr_rpthead_group.rptgrp_id, 
	pr_rpthead_group.rptgrp_text, 
	pr_rpthead_group.rptgrp_desc2 


	INPUT BY NAME pr_rpthead_group.rptgrp_text, 
	pr_rpthead_group.rptgrp_desc2 

	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW6","input-rptgrp_text-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


		AFTER FIELD rptgrp_text --------------- section --------------- 

			IF pr_rpthead_group.rptgrp_text IS NULL THEN 
				ERROR "Please enter a value" 
				attribute(RED) 
				NEXT FIELD rptgrp_text 
			END IF 


		AFTER INPUT ------------------- section ------------------- 

			IF interrupted() THEN 

				LET pr_rpthead_group.* = lr_copy.* 
				EXIT INPUT 
			END IF 

			#########

			CALL init_array_rpt() 

			LET lv_flag = query_rpt(pr_rpthead_group.rptgrp_id) 

			LET lv_records_count = load_array_rpt() 

			IF lv_records_count = "0" THEN 
				LET lv_records_count = "1" 
			END IF 

			LET lv_flag = scroll_rpt(lv_records_count, pr_rpthead_group.*) 

			#########

			IF lv_flag THEN 
				LET lv_error_flag = update_rptgrp(pr_rpthead_group.*) 

				IF error_trap(lv_error_flag) THEN 

					NEXT FIELD previous 
				END IF 

				OPTIONS MESSAGE line LAST 
				MESSAGE "Record Updated Successfully" attribute (YELLOW) 
				SLEEP 2 
				OPTIONS MESSAGE line FIRST 

			ELSE 
				IF interrupted() THEN 
				END IF 
			END IF 

	END INPUT 

	CLEAR FORM 

	RETURN pr_rpthead_group.rptgrp_id, 
	pr_rpthead_group.rptgrp_text, 
	pr_rpthead_group.rptgrp_desc2 
END FUNCTION 

------------------------------------------------------------------------------
FUNCTION remove_rptgrp(pr_rpthead_group) 

	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE lv_response CHAR(1) 
	DEFINE lv_error_flag SMALLINT 

	CURRENT WINDOW IS w0_rptgrp 

	DISPLAY BY NAME pr_rpthead_group.rptgrp_id, 
	pr_rpthead_group.rptgrp_text 


	MENU "DELETE" 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "No" " No, do NOT delete the RECORD " 
			LET lv_response = false 
			EXIT MENU 

		COMMAND "Yes" " Yes, delete the record" 
			LET lv_response = true 
			EXIT MENU 

		COMMAND KEY (INTERRUPT,E,ESC) "Exit" " Exit FROM this menu" 
			LET lv_response = false 
			EXIT MENU 

	END MENU 

	MESSAGE "" 
	DISPLAY "" at 2,1 
	CLEAR FORM 

	IF lv_response THEN 

		LET lv_error_flag = delete_rptgrp(pr_rpthead_group.rptgrp_id) 

		IF NOT error_trap(lv_error_flag) THEN 

			RETURN true 
		END IF 
	END IF 

	RETURN false 

END FUNCTION 

------------------------------------------------------------------------------
FUNCTION update_rptgrp(pr_rpthead_group) 

	DEFINE pr_rpthead_group RECORD LIKE rpthead_group.* 

	LET pr_rpthead_group.cmpy_code = gv_cmpy_code 

	UPDATE rpthead_group 
	SET * = pr_rpthead_group.* 
	WHERE rptgrp_id = pr_rpthead_group.rptgrp_id 
	AND cmpy_code = gv_cmpy_code 

	IF sqlca.sqlerrd[3] = 0 THEN 
		RETURN -69 
	END IF 

	RETURN status 

END FUNCTION 

------------------------------------------------------------------------
FUNCTION delete_rptgrp (pv_rptgrp_id) 

	DEFINE pv_rptgrp_id LIKE rpthead_group.rptgrp_id 

	DELETE FROM rpthead_group 
	WHERE rptgrp_id = pv_rptgrp_id 
	AND cmpy_code = gv_cmpy_code 

	DELETE FROM rpthead_struct 
	WHERE rpthead_struct.rptgrp_id = pv_rptgrp_id 
	AND rpthead_struct.cmpy_code = gv_cmpy_code 

	RETURN status 

END FUNCTION 

------------------------------------------------------------------------


FUNCTION exists_rptgrp(pv_rptgrp_id) 

	DEFINE pv_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lv_count INTEGER 

	SELECT count(*) 
	INTO lv_count 
	FROM rpthead_group 
	WHERE rptgrp_id = pv_rptgrp_id 
	AND cmpy_code = gv_cmpy_code 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN lv_count 

END FUNCTION 

-----------------------------------------------------------------------------
{################
FUNCTION display_rptgrp  (pr_rpthead_group)

DEFINE pr_rpthead_group       RECORD LIKE rpthead_group.*
DEFINE lv_found_flag     SMALLINT

CURRENT WINDOW IS w0_rptgrp

CALL get_descript_rptgrp  (pr_rpthead_group.rptgrp_id)
     RETURNING lv_found_flag

DISPLAY BY NAME pr_rpthead_group.rptgrp_id,
                pr_rpthead_group.rptgrp_text


MESSAGE "Your access only permits you TO VIEW the records in this table "
   ATTRIBUTE (YELLOW)

DISPLAY "[ESC] TO continue" AT 2,1
           ATTRIBUTE(YELLOW)

CALL continue_prompt()

CLEAR FORM
MESSAGE ""
DISPLAY "" AT 2,1

END FUNCTION

################ }

-----------------------------------------------------------------------------
FUNCTION get_rptgrp(pv_rptgrp_id)

DEFINE pv_rptgrp_id  LIKE rpthead_group.rptgrp_id
DEFINE pr_rpthead_group  RECORD LIKE rpthead_group.*

SELECT rptgrp_id, rptgrp_text, rptgrp_desc1 , rptgrp_desc2
INTO pr_rpthead_group.rptgrp_id,
     pr_rpthead_group.rptgrp_text,
     pr_rpthead_group.rptgrp_desc1,
     pr_rpthead_group.rptgrp_desc2
FROM rpthead_group
WHERE rpthead_group.rptgrp_id = pv_rptgrp_id
  AND rpthead_group.cmpy_code = gv_cmpy_code


IF error_trap(STATUS) THEN

    INITIALIZE pr_rpthead_group.* TO NULL

    RETURN pr_rpthead_group.rptgrp_id,
           pr_rpthead_group.rptgrp_text,
           pr_rpthead_group.rptgrp_desc1,
           pr_rpthead_group.rptgrp_desc2,
           FALSE
END IF

RETURN pr_rpthead_group.rptgrp_id,
       pr_rpthead_group.rptgrp_text,
       pr_rpthead_group.rptgrp_desc1,
       pr_rpthead_group.rptgrp_desc2,
       TRUE

END FUNCTION

------------------------------------------------------------------------------
