{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6a.4gl
# Purpose - Table Maintenance Program functions. These
#           functions are based on the rpthead_group table.
#           This program allows users TO Query, Add AND Update, Delete
#           the different rpthead_group records available.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW6_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GW6") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--- Set the interrupt handling  - unfortunately the following statements can
	---                               NOT be placed in the set_options FUNCTION
	# DEFER QUIT

	CALL set_options() 

	OPEN WINDOW w0_rptgrp with FORM "G566" ### used TO be mrw_main 
	CALL windecoration_g("G566") 


	MENU "Menu " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW6","menu-REPORT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "ADD" 
			#COMMAND KEY (A) "ADD" "Add a REPORT group"
			CALL input_rptgrp () 

		ON ACTION "Query" 
			#COMMAND KEY (Q) "Query" "SELECT records TO delete OR UPDATE"
			CALL select_rptgrp () 

		ON ACTION "Exit" 
			#COMMAND KEY (E, INTERRUPT) "Exit" "Exit the menu"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW w0_rptgrp 

END MAIN 

------------------------------------------------------------------------------


############################################################
# FUNCTION input_rptgrp()
#
#
############################################################
FUNCTION input_rptgrp() 
	DEFINE l_rec_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE l_rec_dummy RECORD LIKE rpthead_group.* 
	DEFINE l_error_flag SMALLINT 
	DEFINE l_records_count INTEGER 

	MESSAGE "ADD: [INTERRUPT] TO abort, [ESC] TO accept, [CTRL-B] TO browse" 


	#DISPLAY "" AT 2,1

	LET int_flag = false 
	LET quit_flag = false 

	CALL initialize_rptgrp (l_rec_rpthead_group.*) RETURNING l_rec_rpthead_group.* 

	INPUT BY NAME 
		l_rec_rpthead_group.rptgrp_id, 
		l_rec_rpthead_group.rptgrp_text, 
		l_rec_rpthead_group.rptgrp_desc2	WITHOUT DEFAULTS 
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW6","inp-rpthead_group1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON ACTION "LOOKUP" infield(rptgrp_id)  ---------- browse windows ----------

			CALL pick_rptgrp(glob_rec_kandoouser.cmpy_code) 
			RETURNING 
				l_rec_dummy.rptgrp_id, 
				l_rec_dummy.rptgrp_text 


		AFTER FIELD rptgrp_id --------------- section --------------- 

			IF l_rec_rpthead_group.rptgrp_id IS NULL THEN 

				ERROR "Please Enter a value" 

				NEXT FIELD rptgrp_id 
			END IF 

			IF exists_rptgrp (l_rec_rpthead_group.rptgrp_id) THEN 

				ERROR "This REPORT group code already exists in the database" 

				NEXT FIELD rptgrp_id 
			END IF 


		AFTER FIELD rptgrp_text --------------- section --------------- 

			IF l_rec_rpthead_group.rptgrp_text IS NULL THEN 

				ERROR "Please Enter rpthead_group Description" 

				NEXT FIELD rptgrp_text 
			END IF 

		AFTER INPUT ------------------ section ------------------ 

			IF interrupted() THEN 
				CLEAR FORM 
				EXIT INPUT 
			END IF 

			LET l_records_count = "1" 

			CALL init_array_rpt() 

			IF scroll_rpt(l_records_count, l_rec_rpthead_group.*) THEN 

				CALL insert_rptgrp (l_rec_rpthead_group.*) RETURNING l_error_flag 

				IF NOT error_trap(l_error_flag) THEN 

					OPTIONS MESSAGE line LAST 
					MESSAGE "Record Added Successfully" 
					SLEEP 2 
					OPTIONS MESSAGE line FIRST 

					CALL initialize_rptgrp (l_rec_rpthead_group.*) 
					RETURNING l_rec_rpthead_group.* 

					CLEAR FORM 
				ELSE 

					CONTINUE INPUT 
				END IF 
			END IF 

			NEXT FIELD rptgrp_id 
	END INPUT 

END FUNCTION 



############################################################
# FUNCTION insert_rptgrp(p_rec_rpthead_group)
#
#
############################################################
FUNCTION insert_rptgrp(p_rec_rpthead_group) 
	DEFINE p_rec_rpthead_group RECORD LIKE rpthead_group.* 

	LET p_rec_rpthead_group.cmpy_code = glob_rec_kandoouser.cmpy_code 
	INSERT INTO rpthead_group VALUES (p_rec_rpthead_group.*) 

	RETURN status 
END FUNCTION 

------------------------------------------------------------------------------


############################################################
# FUNCTION INITIALIZE_rptgrp(p_rec_rpthead_group)
#
#
############################################################
FUNCTION initialize_rptgrp(p_rec_rpthead_group) 
	DEFINE p_rec_rpthead_group RECORD LIKE rpthead_group.* 

	INITIALIZE p_rec_rpthead_group.* TO NULL 

	RETURN p_rec_rpthead_group.* 
END FUNCTION 

------------------------------------------------------------------------------



############################################################
# FUNCTION select_rptgrp()
#
#
############################################################
FUNCTION select_rptgrp() 
	DEFINE l_records INTEGER 

	LET l_records = 0 

	WHILE l_records = 0 
		IF NOT query_rptgrp() THEN 

			RETURN 
		END IF 

		LET l_records = load_array_rptgrp() 

		IF l_records = 0 THEN 

			MESSAGE "No records found, please redefine your selection criteria" 


			CONTINUE WHILE 
		END IF 
	END WHILE 

	CALL scroll_rptgrp(l_records) 
	CALL close_cursor_rptgrp() 

END FUNCTION 

------------------------------------------------------------------------------

############################################################
# FUNCTION modify_rptgrp(p_rec_rpthead_group)
#
#
############################################################
FUNCTION modify_rptgrp(p_rec_rpthead_group) 
	DEFINE p_rec_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE l_rec_copy_rpthead_group RECORD LIKE rpthead_group.* 

	DEFINE l_error_flag SMALLINT 
	DEFINE l_flag SMALLINT 
	DEFINE l_records_count INTEGER 

	CURRENT WINDOW IS w0_rptgrp 

	MESSAGE "UPDATE: [INTERRUPT] TO abort, [ESC] TO accept" 


	LET l_rec_copy_rpthead_group.* = p_rec_rpthead_group.* 

	DISPLAY BY NAME p_rec_rpthead_group.rptgrp_id, 
	p_rec_rpthead_group.rptgrp_text, 
	p_rec_rpthead_group.rptgrp_desc2 


	INPUT BY NAME p_rec_rpthead_group.rptgrp_text, 
	p_rec_rpthead_group.rptgrp_desc2 

	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW6","inp-rpthead_group2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

#Don't get this.. this makes no sense
#		ON ACTION "LOOKUP" ---------- browse windows ---------- 
#
#			ERROR "There IS no browse window available FOR this field" 



		AFTER FIELD rptgrp_text --------------- section --------------- 

			IF p_rec_rpthead_group.rptgrp_text IS NULL THEN 
				ERROR "Please enter a value" 

				NEXT FIELD rptgrp_text 
			END IF 


		AFTER INPUT ------------------- section ------------------- 

			IF interrupted() THEN 

				LET p_rec_rpthead_group.* = l_rec_copy_rpthead_group.* 
				EXIT INPUT 
			END IF 

			#########

			CALL init_array_rpt() 

			LET l_flag = query_rpt(p_rec_rpthead_group.rptgrp_id) 

			LET l_records_count = load_array_rpt() 

			IF l_records_count = "0" THEN 
				LET l_records_count = "1" 
			END IF 

			LET l_flag = scroll_rpt(l_records_count, p_rec_rpthead_group.*) 

			#########

			IF l_flag THEN 
				LET l_error_flag = update_rptgrp(p_rec_rpthead_group.*) 

				IF error_trap(l_error_flag) THEN 

					NEXT FIELD previous 
				END IF 

				OPTIONS MESSAGE line LAST 
				MESSAGE "Record Updated Successfully" 
				SLEEP 2 
				OPTIONS MESSAGE line FIRST 

			ELSE 
				IF interrupted() THEN 
				END IF 
			END IF 

	END INPUT 

	CLEAR FORM 

	RETURN p_rec_rpthead_group.rptgrp_id, 
	p_rec_rpthead_group.rptgrp_text, 
	p_rec_rpthead_group.rptgrp_desc2 
END FUNCTION 

------------------------------------------------------------------------------

############################################################
# FUNCTION remove_rptgrp(p_rec_rpthead_group)
#
#
############################################################
FUNCTION remove_rptgrp(p_rec_rpthead_group) 
	DEFINE p_rec_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE l_response CHAR(1) 
	DEFINE l_error_flag SMALLINT 

	CURRENT WINDOW IS w0_rptgrp 

	DISPLAY BY NAME p_rec_rpthead_group.rptgrp_id, 
	p_rec_rpthead_group.rptgrp_text 


	MENU "DELETE" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW5","menu-delete") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "No" " No, do NOT delete the RECORD " 
			LET l_response = false 
			EXIT MENU 

		COMMAND "Yes" " Yes, delete the record" 
			LET l_response = true 
			EXIT MENU 

		COMMAND KEY (INTERRUPT,E,ESC) "Exit" " Exit FROM this menu" 
			LET l_response = false 
			EXIT MENU 

	END MENU 

	MESSAGE "" 
	DISPLAY "" at 2,1 
	CLEAR FORM 

	IF l_response THEN 

		LET l_error_flag = delete_rptgrp(p_rec_rpthead_group.rptgrp_id) 

		IF NOT error_trap(l_error_flag) THEN 

			RETURN true 
		END IF 
	END IF 

	RETURN false 

END FUNCTION 


############################################################
# FUNCTION update_rptgrp(p_rec_rpthead_group)
#
#
############################################################
FUNCTION update_rptgrp(p_rec_rpthead_group) 
	DEFINE p_rec_rpthead_group RECORD LIKE rpthead_group.* 

	LET p_rec_rpthead_group.cmpy_code = glob_rec_kandoouser.cmpy_code 

	UPDATE rpthead_group 
	SET * = p_rec_rpthead_group.* 
	WHERE rptgrp_id = p_rec_rpthead_group.rptgrp_id 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlerrd[3] = 0 THEN 
		RETURN -69 
	END IF 

	RETURN status 

END FUNCTION 


############################################################
# FUNCTION delete_rptgrp(p_rptgrp_id)
#
#
############################################################
FUNCTION delete_rptgrp(p_rptgrp_id) 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 

	DELETE FROM rpthead_group 
	WHERE rptgrp_id = p_rptgrp_id 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	DELETE FROM rpthead_struct 
	WHERE rpthead_struct.rptgrp_id = p_rptgrp_id 
	AND rpthead_struct.cmpy_code = glob_rec_kandoouser.cmpy_code 

	RETURN status 

END FUNCTION 

------------------------------------------------------------------------

############################################################
# FUNCTION exists_rptgrp(p_rptgrp_id)
#
#
############################################################
FUNCTION exists_rptgrp(p_rptgrp_id) 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lv_count INTEGER 

	SELECT count(*) 
	INTO lv_count 
	FROM rpthead_group 
	WHERE rptgrp_id = p_rptgrp_id 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN lv_count 

END FUNCTION 


############################################################
# FUNCTION get_rptgrp(p_rptgrp_id)
#
#
############################################################
FUNCTION get_rptgrp(p_rptgrp_id) 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE l_rec_rpthead_group RECORD LIKE rpthead_group.* 

	SELECT rptgrp_id, rptgrp_text, rptgrp_desc1 , rptgrp_desc2 
	INTO l_rec_rpthead_group.rptgrp_id, 
	l_rec_rpthead_group.rptgrp_text, 
	l_rec_rpthead_group.rptgrp_desc1, 
	l_rec_rpthead_group.rptgrp_desc2 
	FROM rpthead_group 
	WHERE rpthead_group.rptgrp_id = p_rptgrp_id 
	AND rpthead_group.cmpy_code = glob_rec_kandoouser.cmpy_code 


	IF error_trap(status) THEN 

		INITIALIZE l_rec_rpthead_group.* TO NULL 

		RETURN l_rec_rpthead_group.rptgrp_id, 
		l_rec_rpthead_group.rptgrp_text, 
		l_rec_rpthead_group.rptgrp_desc1, 
		l_rec_rpthead_group.rptgrp_desc2, 
		false 
	END IF 

	RETURN l_rec_rpthead_group.rptgrp_id, 
	l_rec_rpthead_group.rptgrp_text, 
	l_rec_rpthead_group.rptgrp_desc1, 
	l_rec_rpthead_group.rptgrp_desc2, 
	true 

END FUNCTION 
