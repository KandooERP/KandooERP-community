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



{**
 *
 * contact contact Role functions
 *
 * @author: Andrej Falout
 *
 *}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 


DEFINE 
all_roles 
CHAR(50) 


###########################
FUNCTION contact_role_menu() 
	###########################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success, 
	changed 
	SMALLINT, 
	acc_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 


	MESSAGE"" 

	CALL init_contact_role() 
	CURRENT WINDOW IS w_contact 

	MENU "Contact Role" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_role","menu-Contact_Role-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "New role" "Add a new role FOR this contact" 
			MESSAGE"" 
			CALL init_contact_role() 
			LET changed = new_contact_role() 
			IF changed THEN 
				LET dummy = all_contact_roles('2', true,false,false) #disp_format,and_exit,hist,in_context 
			END IF 

		COMMAND "Delete" "Mark contact role as no longer valid" 
			MESSAGE"" 
			CALL init_contact_role() 
			LET changed= all_contact_roles('2', false,false,false) #disp_format,and_exit,hist,in_context 
			IF changed THEN 
				LET dummy = all_contact_roles('2', true,false,false) #disp_format,and_exit,hist,in_context 
			END IF 


		COMMAND KEY ("r","R") "all Roles" "DISPLAY all valid role info on this contact" 
			MESSAGE"" 
			CALL init_contact_role() 
			LET success = all_contact_roles(2,true,false,false) #in_context 

		COMMAND "History" "DISPLAY all historycal contact Role info" 
			MESSAGE"" 
			CALL init_contact_role() 
			LET success = all_contact_roles(2,true,true,false) 

		COMMAND "Context" "Start the maintainance program FOR this contact's role" 
			MESSAGE"" 
			CALL init_contact_role() 
			LET dummy = all_contact_roles('2', false,false,true) #disp_format,and_exit,hist,in_context 

		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #contact_role_menu() 

###########################
FUNCTION init_contact_role() 
	###########################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_contact_roles 

	LET current_contact_role_form = 1 

	MESSAGE "All Roles of this contact:" 

	LET dummy = all_contact_roles('2', true,false,false) #disp_format,and_exit,hist,in_context 

END FUNCTION #init_contact_role() 


##########################
FUNCTION del_contact_role() 
	##########################
	DEFINE 
	success 
	SMALLINT 

	LET success = false 

	MESSAGE "Mark this contact Role information as deleted?" 

	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_role","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE contact_role SET 
			valid_to = today 
			WHERE 
			contact_role.role_code = g_contact_role.role_code 
			AND 
			contact_role.contact_id = g_contact_role.contact_id 
			AND 
			contact_role.valid_from = g_contact_role.valid_from 
			AND 
			(contact_role.valid_to = g_contact_role.valid_to 
			OR 
			contact_role.valid_to IS null) 

			IF status <> 0 THEN 
				ERROR "Error updating role, STATUS IS = ", status 
				SLEEP 5 
				LET success = false 
			ELSE 
				CLEAR FORM 
				LET success = true 
			END IF 
			EXIT MENU 
	END MENU 

	MESSAGE "" 

	RETURN success 

END FUNCTION #d_contact_role() 


#########################
FUNCTION new_contact_role() 
	#########################
	DEFINE 
	new_role_name LIKE role.role_name, 
	new_role_code LIKE role.role_code, 
	success 
	SMALLINT 


	CALL role_lp("CONTACT ROLE") 
	RETURNING new_role_code, new_role_name 

	IF new_role_code IS NULL THEN 
		RETURN false 
	END IF 

	LET success = add_contact_role(g_contact.contact_id, new_role_code, new_role_name) 

	RETURN success 

END FUNCTION #new_contact_role() 

##################################################################
FUNCTION add_contact_role(p_contact_id, p_role_code, p_role_name) 
	###################################################################
	DEFINE 
	p_contact_id 
	LIKE contact.contact_id, 
	p_role_code 
	LIKE role.role_code, 
	p_role_name 
	LIKE role.role_name 

	IF p_role_name IS NULL 
	AND p_role_code IS NULL THEN 
		ERROR "Must have code OR name. contact_role.4gl, add_contact_role(). Must Exit" 
		SLEEP 3 
		EXIT program 
	END IF 

	IF p_role_name IS NULL THEN 
		LET p_role_name = get_role_name(p_role_code, "CONTACT ROLE") 
	END IF 

	IF p_role_code IS NULL THEN 
		LET p_role_code = get_role_code(p_role_name, "CONTACT ROLE") 
	END IF 

	IF 
	duplicate_contact_role(p_role_code) 
	THEN 
		ERROR "This contact already have this role !" 
		SLEEP 2 
		RETURN false 
	ELSE 
		INSERT INTO contact_role VALUES 

		(p_role_code, 
		p_contact_id, 
		"", 
		today) 

		IF status = 0 THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	END IF 

END FUNCTION #add_contact_role() 

##################################################
FUNCTION duplicate_contact_role(new_role_code) 
	##################################################
	DEFINE 
	new_role_code LIKE role.role_code 

	SELECT * FROM contact_role 
	WHERE contact_id = g_contact.contact_id 
	AND 
	role_code = new_role_code 

	IF status <> notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_contact_role() 

###################################################################
FUNCTION all_contact_roles(disp_format,and_exit,history,in_context) 
	###################################################################
	DEFINE 
	a_contact_role ARRAY [100] OF RECORD 
		role_code LIKE contact_role.role_code, 
		contact_id LIKE contact_role.contact_id, 
		valid_to LIKE contact_role.valid_to, 
		valid_from LIKE contact_role.valid_from 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		role_name LIKE role.role_name, 
		valid_from LIKE contact_role.valid_from, 
		valid_to LIKE contact_role.valid_to 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	history, 
	changed, 
	success, 
	in_context 
	SMALLINT, 
	where_part 
	CHAR(300), 
	msg_2 CHAR (60) 

	LET changed = false 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_roles with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_contact_role_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_contact_roles #maybe i'm comming FROM somewhere ELSE 

	END CASE 


	LET where_part = 
	"SELECT * FROM contact_role WHERE contact_id = ",g_contact.contact_id 
	IF 
	#show_valid
	NOT history 
	OR 
	in_context 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_role.valid_to IS NULL OR contact_role.valid_to > TODAY)" 

		LET msg_2 = ", valid only" 

		IF 
		in_context 
		THEN 
			LET msg_2 = msg_2 clipped , " (F9 TO maintain in context)" 
		END IF 

	ELSE 
		LET msg_2 = ", including history" 
	END IF 

	LET where_part = where_part clipped, 
	" ORDER BY valid_from desc " 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE rolex12 FROM where_part 
	DECLARE c_all_per_roles CURSOR FOR rolex12 

	LET cnt = 1 

	##################################################
	FOREACH c_all_per_roles INTO a_contact_role[cnt].* 
		##################################################


		LET a_display[cnt].role_name = 
		get_role_name(a_contact_role[cnt].role_code, "CONTACT ROLE") 

		IF in_context THEN 
			IF 
			a_display[cnt].role_name <> "CONTRIBUTOR" 
			AND 
			a_display[cnt].role_name <> "DEPOSITOR" 
			THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 

		LET a_display[cnt].valid_from = a_contact_role[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_role[cnt].valid_to 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 

	CLOSE c_all_per_roles 
	FREE c_all_per_roles 
	MESSAGE "" 
	CALL set_count(cnt) 


	IF and_exit THEN 
		MESSAGE "All roles FOR this contact", msg_2 clipped 
	ELSE 
		IF 
		in_context 
		THEN 
			MESSAGE "ONLY Roles in context ", msg_2 clipped, " (F5=delete)" 
		ELSE 
			MESSAGE "All roles FOR this contact", msg_2 clipped, " (F5=delete)" 
		END IF 
	END IF 

	IF cnt = 0 THEN 
		MESSAGE "This contact have no defined roles" 
		RETURN changed 
	END IF 


	#########################################
	DISPLAY ARRAY a_display TO s_display.* 
	#########################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_role","display_arr-a_display-1") -- albo kd-513 

			##########
		BEFORE ROW 
			{! BEFORE ROW !}
			##########
			IF 
			and_exit 
			THEN 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			##############
		ON KEY ("F5") 
			{! ON KEY ("F5") !}
			##############
			LET cnt = arr_curr() #scr_line() 
			LET g_contact_role.* = a_contact_role[cnt].* 
			LET success = del_contact_role() 
			IF success THEN 
				LET changed = true 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 


			#############
		ON KEY ("F9") 
			{! ON KEY ("F9") !}
			#############
			LET cnt = arr_curr() #scr_line() 

			IF 
			in_context 
			THEN 
				CALL run_in_context(g_contact.contact_id,a_display[cnt].role_name) 
			END IF 


			###########
	END DISPLAY 
	{! END DISPLAY !}
	###########

	#    MESSAGE ""

	CASE disp_format 
		WHEN 1 #big new WINDOW 
			CLOSE WINDOW w_all_roles 

		WHEN 2 
			#			DISPLAY FORM f_contact_role1
			#			CALL display_contact_role()
	END CASE 


	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN changed 

END FUNCTION #all_contact_roles() 

#################################################
FUNCTION run_in_context(p_contact_id,p_role_name) 
	#################################################
	DEFINE 
	p_contact_id 
	LIKE contact.contact_id, 
	p_role_name 
	LIKE role.role_name 

	CASE p_role_name 

		WHEN "CONTRIBUTOR" 
			CALL run_prog ("C11", p_contact_id, "", "", "") 
			CALL prompt_to_continue() 

		WHEN "DEPOSITOR" 
			ERROR "Matt, what TO run here ?" SLEEP 5 
			CALL prompt_to_continue() 

		OTHERWISE 
			ERROR "Unknown context" SLEEP 5 
	END CASE 

END FUNCTION #run_in_context() 

#############################
FUNCTION prompt_to_continue() 
	#############################

	LET ga_grid[1] = "Do you want TO continue working" 
	LET ga_grid[2] = "in contact management?" 

	IF NOT ask_yes_no(2) THEN #used LINES 
		EXIT program 
	END IF 


END FUNCTION #prompt_to_continue() 

###################################################### module end

