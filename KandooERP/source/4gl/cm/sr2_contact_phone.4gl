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

	 $Id$
}


{**
 *
 * contact phone functions
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
CHAR(50), 

a_all_ph_owners array[40] OF RECORD 
	contact_id LIKE contact_phone.contact_id, 
	phone_id LIKE contact_phone.phone_id, 
	role_code LIKE contact_phone.role_code, 
	valid_from LIKE contact_phone.valid_from, 
	valid_to LIKE contact_phone.valid_to 
END RECORD, 

all_ph_owners_cnt 
SMALLINT 



#######################
FUNCTION phone_menu() 
	#######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success, 
	any_contact 
	SMALLINT, 
	phone_id, 
	tmp_contact_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	new_phone_id LIKE phone.phone_id, 
	new_phone_role_code 
	LIKE role.role_code, 
	new_phone_role_name 
	LIKE role.role_name 


	MESSAGE"" 
	CALL init_phone() 

	CURRENT WINDOW IS w_contact 

	MENU "phone" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_phone","menu-phone-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query by phone data" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET any_contact = false 
			CALL qbe_phone(any_contact) RETURNING send1, send2, send3 
			CALL phone_where_part(send1, send2, send3, any_contact) 
			RETURNING send1, send2, send3 

			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET success = open_phone_cursor(send1, send2, send3, any_contact) 
			END IF 

		COMMAND "+" "Next found" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET success = n_phone(any_contact) 

		COMMAND "-" "Previous found" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET success = p_phone(any_contact) 

		COMMAND "Add" "Add new phone number" 
			MESSAGE"" 
			CALL init_phone_win() 
			MENU "Add phone" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","contact_phone","menu-Add_phone-1") -- albo kd-513 

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Add new" "Add a new phone number TO the database" 
					LET success = au_contact_phone(g_contact.contact_id,true) #add_mode 
					IF success THEN 
						LET all_roles = get_phone_roles(gv_null,show_history) 
						DISPLAY all_roles TO s_phone.phone_role_name 
					END IF 

					EXIT MENU 

				COMMAND "Pick" "Pick an existing phone number TO be used by this Contact" 

					LET g_msg = "You are Selecting a new PHONE TO be used by ", 
					g_contact.first_name clipped , " ", 
					g_contact.last_org_name clipped 

					MESSAGE g_msg attribute (red) 
					LET new_phone_id = select_phone(g_contact.contact_id,g_phone.phone_id) 
					MESSAGE "" 

					IF new_phone_id IS NOT NULL THEN 
						CALL role_lp("PHONE") 
						RETURNING new_phone_role_code, new_phone_role_name 
						IF new_phone_role_code IS NOT NULL THEN 

							IF 
							duplicate_phone_role(new_phone_role_code) 
							THEN 
								ERROR "This contact already has an phone with this role. Please SELECT another role !" 
								SLEEP 2 
								CONTINUE MENU 
							END IF 

							LET g_contact_phone.contact_id = g_contact.contact_id 
							LET g_contact_phone.phone_id = new_phone_id 
							LET g_contact_phone.role_code = new_phone_role_code 
							LET g_contact_phone.valid_from = today 
							INITIALIZE g_contact_phone.valid_to TO NULL 

							INSERT INTO contact_phone VALUES (g_contact_phone.*) 

							IF status <> 0 THEN 
								ERROR "Cannot add contact phone: Add aborted !" 
								SLEEP 5 
							ELSE 
								ERROR "Selected phone added under the role of ", new_phone_role_name clipped 
								SLEEP 1 
								EXIT MENU 
							END IF 
						END IF 
					END IF 

				COMMAND "Cancel" "Do NOT add a new phone number" 
					EXIT MENU 
			END MENU 

		COMMAND "Edit" "Modify current phone FOR this contact" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET success = au_contact_phone(g_contact.contact_id,false) #add_mode 

		COMMAND "New role" "Add a new role FOR this phone" 
			MESSAGE"" 
			CALL init_phone_win() 
			CALL new_phone_role() 

		COMMAND "Change role" "Change roles FOR this phone" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET phone_id = all_phone_roles(2,false) 
			DISPLAY FORM f_phone1 
			CALL display_phone() 
			IF 
			phone_id IS NOT NULL 
			THEN 
				CALL disp_selected_phone(phone_id) 
			END IF 

		COMMAND KEY ("r","R") "all Roles" "DISPLAY all role AND phone info on this contact, including history" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET phone_id = all_phone_roles(2,false) 
			DISPLAY FORM f_phone1 
			CALL display_phone() 
			IF 
			phone_id IS NOT NULL 
			THEN 
				CALL disp_selected_phone(phone_id) 
			END IF 

		COMMAND "History" "DISPLAY all historycal phone info" 
			MESSAGE"" 
			CALL init_phone_win() 
			LET phone_id = phone_hist("2",FALSE) 
			DISPLAY FORM f_phone1 
			CALL display_phone() 
			CALL disp_selected_phone(phone_id) 

		COMMAND "Delete" "Delete current phone" 
			MESSAGE"" 
			CALL init_phone_win() 
			CALL del_phone() 


		COMMAND KEY ("y","Y") "anY phone" "Query FOR any contact phone number" 
			MESSAGE "" 
			CALL init_phone_win() 
			LET any_contact = true 
			CALL qbe_phone(any_contact) RETURNING send1, send2, send3 
			CALL phone_where_part(send1, send2, send3, any_contact) 
			RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET success = open_phone_cursor(send1, send2, send3,any_contact) 
			END IF 


		COMMAND "Switch" "Switch current contact TO the one that the displayed phone belongs TO" 

			IF g_contact_phone.contact_id <> g_contact.contact_id THEN 
				CALL get_contact_name(g_contact_phone.contact_id) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_phone","menu-Switch-1") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 

						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current phone belongs TO" 
						MESSAGE "" 
						CALL switch_contact(g_contact_phone.contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This phone belongs TO the current contact: Cannot switch" 
			END IF 

			#        COMMAND "Screen" "Show next SCREEN of current phone data"
			#            CALL next_phone_screen()

		COMMAND "Owners" "Show all owners of this phone number" 
			LET tmp_contact_id = list_all_ph_owners(g_phone.phone_id) 

			IF tmp_contact_id <> g_contact.contact_id THEN 
				CALL get_contact_name(tmp_contact_id) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_phone","menu-Switch-2") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current phone belongs TO" 
						MESSAGE "" 
						CALL switch_contact(tmp_contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			END IF 


		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #phone_menu() 

####################################
FUNCTION disp_selected_phone(phone_id) 
	####################################
	DEFINE 
	phone_id, 
	success 
	SMALLINT, 
	send1, send2, send3 #where_part 
	CHAR (200) 


	IF phone_id IS NOT NULL THEN 
		LET send1 = " phone.phone_id = ", phone_id 
		INITIALIZE send2, send3 TO NULL 

		CALL phone_where_part(send1, send2, send3,false) #any_contact 
		RETURNING send1, send2, send3 

		LET success = open_phone_cursor(send1, send2, send3, false) #any_contact 
	END IF 
END FUNCTION 


######################
FUNCTION init_phone() 
	######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success 
	SMALLINT 

	#already opmen FOR Info !
	#	OPEN WINDOW w_phone
	#        AT 12,2 with 13 rows, 75 columns
	#			attribute (border)

	CALL init_phone_win() 

	# We want TO get all Phone numbers FOR a contact NOT
	# just the DEFAULT
	#	LET send1 = " role.role_name = 'DEFAULT' ",
	#                " AND role.class_name = 'PHONE' ",
	#                " AND role.role_code = contact_phone.role_code ",
	#		        " AND contact_phone.contact_id = ", g_contact.contact_id, " "

	LET send1 = " contact_phone.contact_id = ", g_contact.contact_id, " " 

	INITIALIZE send2, send3 TO NULL 

	CALL phone_where_part(send1, send2, send3,false) #any_contact 
	RETURNING send1, send2, send3 
	LET success = open_phone_cursor(send1, send2, send3,false) #any_contact 

	MESSAGE "Default phone number:" 

END FUNCTION #init_phone() 

#########################
FUNCTION init_phone_win() 
	#########################
	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_phone1 

	LET current_phone_form = 1 

END FUNCTION #init_phone_win() 



{**
 *
 *
 * @table time_restrict
 *
 *}
################################
FUNCTION qbe_phone(any_contact) 
	################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	tmp_phone_role_name, tmp_name 
	LIKE role.role_name, 
	any_contact 
	SMALLINT 

	IF current_phone_form <> 1 THEN 
		CALL d_phone1() 
	END IF 

	MESSAGE "Enter the query conndition AND press Accept" 


	CONSTRUCT where_part ON 
	phone.country_code, 
	phone.area_code, 
	phone.phone_number, 
	phone.extension, 
	time_restrict.time_restrict_name, 
	role.role_name, 
	phone.valid_from, 
	phone.valid_to 

	FROM 
	s_phone.country_code, 
	s_phone.area_code, 
	s_phone.phone_number, 
	s_phone.extension, 
	s_phone.time_restrict_name, 
	s_phone.phone_role_name, 
	s_phone.valid_from, 
	s_phone.valid_to 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact_phone","construct-phone-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############################
		AFTER FIELD phone_role_name 
			############################
			LET tmp_phone_role_name = get_fldbuf(phone_role_name) 

			IF 
			tmp_phone_role_name IS NOT NULL 
			AND 
			length (tmp_phone_role_name) > 0 
			THEN 
				LET tmp_name = get_fldbuf(phone_role_name) 

				SELECT * FROM role 
				WHERE role_name = tmp_name 
				AND class_name = "PHONE" 

				IF status = notfound THEN 
					ERROR "This role IS NOT defined" 
					NEXT FIELD phone_role_name 

				END IF 
			ELSE 
				LET tmp_name = "DEFAULT" 
				DISPLAY tmp_name TO s_phone.phone_role_name 
			END IF 



			#############
	END CONSTRUCT 
	#############


	MESSAGE "" 

	IF NOT any_contact THEN 
		LET where_part = where_part clipped, 
		" AND contact_phone.contact_id = ", g_contact.contact_id, " " 
	END IF 


	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	# Need just the WHERE part of the SELECT TO be returned FROM this FUNCTION
	#	CALL phone_where_part(send1, send2, send3, any_contact)
	#        returning send1, send2, send3

	#    LET last_phone_where_part = where_part

	RETURN send1, send2, send3 #where_part 

END FUNCTION #q_phone() 


####################
FUNCTION d_phone1() 
	####################

	DISPLAY FORM f_phone1 
	LET current_phone_form = 1 
	CALL display_phone() 

END FUNCTION 

###############################################
FUNCTION get_phone_roles(tmp_phone_id,and_hist) 
	###############################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt, 
	and_hist 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 
	tmp_phone_id 
	LIKE phone.phone_id, 
	where_part 
	CHAR (300) 

	IF tmp_phone_id IS NULL THEN 
		LET tmp_phone_id = g_phone.phone_id 
	END IF 

	LET where_part = 
	" SELECT unique role_code FROM contact_phone ", 
	" WHERE phone_id = ", tmp_phone_id, 
	" AND contact_id = ", g_contact.contact_id 

	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" AND (valid_to IS NULL OR valid_to > today )" 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE xde66 FROM where_part 
	DECLARE c_phone_roles CURSOR FOR xde66 


	INITIALIZE all_roles TO NULL 

	LET cnt = 1 

	############################################
	FOREACH c_phone_roles INTO a_role_codes[cnt] 
		############################################

		LET tmp_role_name = get_role_name(a_role_codes[cnt], "PHONE") 

		IF cnt = 1 THEN 
			LET all_roles = tmp_role_name 
		ELSE 
			LET all_roles = all_roles clipped,", ", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_phone_roles 
	FREE c_phone_roles 
	MESSAGE "" 
	RETURN all_roles 

END FUNCTION #get_phone_roles() 

##########################################################
FUNCTION phone_where_part(send1, send2, send3,any_contact) 
	##########################################################
	DEFINE 
	where_part, 
	received_where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT 

	LET received_where_part = send1, send2, send3 

	LET where_part = "SELECT unique phone.* ", 
	#" , contact_phone.* ",
	" FROM phone, contact_phone " 

	IF received_where_part matches "*role.role_name*" THEN 
		LET where_part = where_part clipped, 
		", role " 
	END IF 

	LET where_part = where_part clipped, 
	" WHERE ", received_where_part clipped, 
	#        " AND contact_phone.contact_id = ", g_contact.contact_id,
	" AND contact_phone.phone_id = phone.phone_id " 


	IF 
	received_where_part matches "*role.role_name*" 
	THEN 
		LET where_part = where_part clipped, 
		" AND role.role_code = contact_phone.role_code ", 
		" AND role.class_name = 'PHONE' " 

	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	RETURN send1, send2, send3 #where_part 

END FUNCTION #phone_where_part() 


###########################################################
FUNCTION open_phone_cursor(send1, send2, send3,any_contact) 
	###########################################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT 

	LET where_part = send1, send2, send3 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_phone.valid_to IS NULL OR contact_phone.valid_to > TODAY)", 
		" AND (phone.valid_to IS NULL OR phone.valid_to > TODAY)" 

	END IF 

	#    LET where_part = where_part clipped," group by phone.phone_id, phone.contact_id ... line1 etc must be in group by "

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE xp2 FROM where_part 
	DECLARE c_read_phone SCROLL CURSOR with HOLD FOR xp2 
	OPEN c_read_phone 

	FETCH FIRST c_read_phone INTO g_phone.* #, g_contact_phone.* 

	IF 
	status = notfound 
	THEN 
		MESSAGE "" 
		ERROR "No records found" 
		INITIALIZE g_phone.* TO NULL 
		RETURN false 
	ELSE 
		MESSAGE "" 
		CALL get_phone_owners(any_contact) 
		LET all_roles = get_phone_roles(gv_null,show_history) 
		CALL display_phone() 
		RETURN true 
	END IF 

END FUNCTION #open_phone_cursor() 


###################################################
FUNCTION get_one_ph_role(p_phone_id,p_contact_id) 
	###################################################
	DEFINE 
	p_phone_id LIKE phone.phone_id, 
	p_contact_id LIKE contact.contact_id, 
	tmp_role_code LIKE role.role_code 

	MESSAGE "Searching...please wait" 
	DECLARE c_one_ph_role CURSOR FOR 
	SELECT role_code FROM contact_phone 
	WHERE contact_id = p_contact_id 
	AND phone_id = p_phone_id 
	GROUP BY role_code 

	########################################
	FOREACH c_one_ph_role INTO tmp_role_code 
		########################################

		IF 
		is_default_role(tmp_role_code, "PHONE") 
		THEN 
			EXIT FOREACH 
		END IF 

		###########
	END FOREACH 
	###########

	CLOSE c_one_ph_role 
	FREE c_one_ph_role 
	MESSAGE "" 
	RETURN tmp_role_code 

END FUNCTION #get_one_ph_role 


#############################
FUNCTION n_phone(any_contact) 
	#############################
	DEFINE 
	any_contact 
	SMALLINT 
	IF 
	g_phone.phone_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 

	FETCH NEXT c_read_phone INTO g_phone.* #, g_contact_phone.* 

	IF 
	status = notfound 
	THEN 
		ERROR "No more records found" 
		CALL display_phone() 
		RETURN false 
	ELSE 
		CALL get_phone_owners(any_contact) 
		LET all_roles = get_phone_roles(gv_null,show_history) 
		CALL display_phone() 
		RETURN true 
	END IF 

END FUNCTION #n_phone() 

##############################
FUNCTION p_phone(any_contact) 
	##############################
	DEFINE 
	any_contact 
	SMALLINT 

	IF 
	g_phone.phone_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 


	FETCH previous c_read_phone INTO g_phone.* #, g_contact_phone.* 
	IF status = notfound THEN 
		ERROR "No previous records found" 
		CALL display_phone() 
		RETURN false 
	ELSE 
		CALL get_phone_owners(any_contact) 
		LET all_roles = get_phone_roles(gv_null,show_history) 
		CALL display_phone() 
		RETURN true 
	END IF 

END FUNCTION #p_phone() 


####################################################
FUNCTION au_contact_phone(tmp_contact_id,add_mode) 
	####################################################
	DEFINE 
	tmp_contact_id LIKE contact.contact_id, 
	p_phone_role_name, new_phone_role_name LIKE role.role_name, 
	new_phone_role_code LIKE role.role_code, 
	new_time_restrict_code LIKE time_restrict.time_restrict_code, 
	p_time_restrict_name, new_time_restrict_name LIKE time_restrict.time_restrict_name, 

	add_mode, 
	success 
	SMALLINT, 
	store_phone RECORD LIKE phone.*, 
	store_contact_phone RECORD LIKE contact_phone.* 

	IF current_phone_form <> 1 THEN 
		CALL d_phone1() 
	END IF 

	IF add_mode THEN 
		INITIALIZE g_phone TO NULL 
		INITIALIZE g_contact_phone TO NULL 
		CLEAR FORM 
		MESSAGE "Enter new phone data AND press Accept" 
	ELSE 
		LET store_phone.* = g_phone.* 
		LET store_contact_phone.* = g_contact_phone.* 
		MESSAGE "Enter changes AND press Accept" 
	END IF 


	#############
	INPUT 
	#############
	g_phone.country_code, 
	g_phone.area_code, 
	g_phone.phone_number, 
	g_phone.extension, 
	c_phone.time_restrict_name, 
	c_phone.phone_role_name, 
	g_phone.valid_from, 
	g_phone.valid_to 

	WITHOUT DEFAULTS FROM 

	s_phone.country_code, 
	s_phone.area_code, 
	s_phone.phone_number, 
	s_phone.extension, 
	s_phone.time_restrict_name, 
	s_phone.phone_role_name, 
	s_phone.valid_from, 
	s_phone.valid_to 

	############
		BEFORE INPUT 
			############
			CALL publish_toolbar("kandoo","contact_phone","input-g_phone-1") -- albo kd-513 
			IF NOT add_mode THEN 
				DISPLAY all_roles TO s_phone.phone_role_name 
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############
		ON KEY (f10) 
			############

			####
			CASE 
			####
			############################
				WHEN infield(phone_role_name) 
					############################

					CALL role_lp("PHONE") 
					RETURNING new_phone_role_code, new_phone_role_name 

					IF new_phone_role_code IS NOT NULL THEN 
						LET p_phone_role_name = new_phone_role_name 
						LET g_contact_phone.role_code = new_phone_role_code 
						DISPLAY p_phone_role_name TO phone_role_name 
					END IF 

					################################
				WHEN infield(time_restrict_name) 
					################################

					CALL time_restrict_lp() 
					RETURNING new_time_restrict_code, new_time_restrict_name 

					IF new_time_restrict_code IS NOT NULL THEN 
						LET p_time_restrict_name = new_time_restrict_name 
						LET g_phone.time_restrict_code = new_time_restrict_code 
						DISPLAY p_time_restrict_name TO time_restrict_name 
					END IF 

					########
			END CASE 
			########

			############################
		BEFORE FIELD phone_role_name 
			############################

			IF NOT add_mode THEN 
				NEXT FIELD NEXT 
			END IF 


			###########################
		AFTER FIELD phone_role_name 
			###########################

			IF c_phone.phone_role_name IS NOT NULL 
			AND add_mode THEN 

				LET g_contact_phone.role_code = get_role_code(c_phone.phone_role_name, "PHONE") 

				IF g_contact_phone.role_code IS NULL THEN 

					CALL role_lp("PHONE") 
					RETURNING new_phone_role_code, new_phone_role_name 

					IF 
					new_phone_role_code IS NULL 
					THEN 
						LET p_phone_role_name = "DEFAULT" 
						LET c_phone.phone_role_name = p_phone_role_name 
						LET g_contact_phone.role_code = get_default_code("PHONE") 
					ELSE 
						LET g_contact_phone.role_code = new_phone_role_code 
						LET c_phone.phone_role_name = new_phone_role_name 
						LET p_phone_role_name = new_phone_role_name 
					END IF 
				ELSE 

					IF duplicate_phone_role(new_phone_role_code) 
					AND add_mode THEN 
						ERROR "This contact already has an phone with this role !" 
						SLEEP 2 
						NEXT FIELD phone_role_name 
					END IF 
				END IF 

				DISPLAY p_phone_role_name TO phone_role_name 

			END IF 

			######################
		AFTER FIELD valid_from 
			######################
			IF g_phone.valid_from IS NULL THEN 
				LET g_phone.valid_from = today 
				DISPLAY BY NAME g_phone.valid_from 
			END IF 

			#########################
		AFTER FIELD phone_number 
			#########################

			IF add_mode THEN 
				#IF duplicate_phone() THEN
				#offer TO pick existing instead of adding
			END IF 


			###########
		AFTER INPUT 
			###########
			IF int_flag THEN 
				EXIT INPUT 
			END IF 


			LET g_contact_phone.contact_id = g_contact.contact_id 
			LET g_contact_phone.valid_from = today 

			#LET g_phone.phone_id = 0
			LET g_phone.valid_from = today 

			IF p_phone_role_name IS NULL 
			OR length (p_phone_role_name) < 1 THEN 
				LET p_phone_role_name = "DEFAULT" 
				LET c_phone.phone_role_name = new_phone_role_name 

				LET g_contact_phone.role_code = get_default_code("PHONE") 
			END IF 

			IF duplicate_phone_role(g_contact_phone.role_code) 
			AND add_mode THEN 
				ERROR "This contact already has an phone with this role. Please SELECT another role !" 
				SLEEP 2 
				NEXT FIELD phone_role_name 
			END IF 

			#########
	END INPUT 
	#########

	MESSAGE "" 

	IF int_flag THEN 
		LET int_flag = false 
		RETURN false 
	END IF 

	IF NOT add_mode THEN 
		#any change FOR UPDATE?

		IF 
		g_phone.country_code = store_phone.country_code 
		AND 
		g_phone.area_code = store_phone.area_code 
		AND 
		g_phone.phone_number = store_phone.phone_number 
		AND 
		g_phone.extension = store_phone.extension 
		AND 
		g_phone.valid_from = store_phone.valid_from 
		AND 
		g_phone.valid_to = store_phone.valid_to 
		AND 
		g_phone.time_restrict_code = store_phone.time_restrict_code 

		THEN 
			ERROR "Nothhing changed: nothing TO UPDATE" 
			RETURN false 
		END IF 
	END IF 

	LET success = f_store_phone(add_mode) 

	RETURN success 

END FUNCTION #au_contact_phone() 


###############################
FUNCTION f_store_phone(add_mode) 
	###############################
	DEFINE 
	add_mode 
	SMALLINT, 
	old_phone_id 
	INTEGER 

	LET old_phone_id = g_phone.phone_id 

	##########
	BEGIN WORK 
		##########

		IF NOT add_mode THEN #logical UPDATE 

			#first, close previous record
			UPDATE phone SET 
			valid_to = today 
			WHERE phone_id = old_phone_id 

			IF status <> 0 THEN 
				ERROR "Cannot close previous record: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

		END IF 

		LET g_contact_phone.contact_id = g_contact.contact_id 
		LET g_phone.phone_id = 0 
		LET g_phone.valid_from = today 
		#LET g_contact.mod_user_id = glob_rec_kandoouser.sign_on_code


		####################################
		INSERT INTO phone VALUES (g_phone.*) 
		####################################

		IF 
		status <> 0 
		THEN 
			ERROR "Cannot INSERT new record: Update/Add aborted !" 
			SLEEP 5 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		LET g_phone.phone_id = sqlca.sqlerrd[2] 


		IF 
		########
		add_mode 
		########
		THEN 

			LET g_contact_phone.phone_id = g_phone.phone_id 

			INSERT INTO contact_phone VALUES (g_contact_phone.*) 

			IF status <> 0 THEN 
				ERROR "Cannot add contact phone: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 
			####
		ELSE #logical UPDATE 
			####
			{
					SELECT * INTO g_contact_phone.*
			            FROM contact_phone
			                WHERE phone_id = old_phone_id

					UPDATE contact_phone
			            SET valid_to =  today
			                WHERE phone_id = old_phone_id


					LET g_contact_phone.phone_id = g_phone.phone_id #new
					INSERT INTO contact_phone VALUES (g_contact_phone.*)
			}



			UPDATE contact_phone 
			SET phone_id = g_phone.phone_id #new 
			WHERE phone_id = old_phone_id #old 

			IF status <> 0 THEN 
				ERROR "Cannot UPDATE contact phone: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

			LET g_contact_phone.phone_id = g_phone.phone_id 

		END IF 

		###########
	COMMIT WORK #this will CLOSE all opened cursors, including contact SELECT 
	########### #main curor, IF NOT defined "with hold"  !!!!

	RETURN true #success 


END FUNCTION #store_phone() 


##########################
FUNCTION display_phone() 
	##########################
	DEFINE 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	IF g_phone.phone_id IS NULL THEN #to prevent uninitialised dates 
		#FROM displaying as 31/12/1899
		INITIALIZE g_phone.* TO NULL 
	END IF 

	{removed contact_id FROM phone table: no concept of ownership

		if g_contact_phone.contact_id <> g_contact.contact_id THEN
	        CALL get_contact_name(g_contact_phone.contact_id) returning tmp_first, tmp_last

			ERROR "WARNING ! This phone does NOT belong TO current contact"
	            attribute (red)
	        MESSAGE "This phone belongs TO ",tmp_first clipped, " ", tmp_last clipped
	            attribute (red)
	    END IF

	}
	CASE current_phone_form 

		WHEN 1 #phones.per 
			DISPLAY BY NAME 

			g_phone.country_code, 
			g_phone.area_code, 
			g_phone.phone_number, 
			g_phone.extension, 
			g_phone.valid_from, 
			g_phone.valid_to 


			DISPLAY all_roles TO s_phone.phone_role_name 

			LET c_phone.time_restrict_name = 
			get_time_restrict_name(g_phone.time_restrict_code) 

			DISPLAY BY NAME c_phone.time_restrict_name 


			#         WHEN 2 #?.per

		OTHERWISE 

			ERROR "Unknown form: contact_phone.4gl, display_phone()" 
			EXIT program 
	END CASE 

END FUNCTION #display_phone() 


####################
FUNCTION del_phone() 
	####################


	IF is_default_phone(g_phone.phone_id) THEN 
		ERROR "cannot deactivate default phone. Use Modify instead" 
		SLEEP 2 
		RETURN 
	END IF 

	IF all_ph_owners_cnt > 1 THEN 
		ERROR "This phone IS used by several Contacts. Unbind there ussage of this phone first" 
		SLEEP 5 
		RETURN 
	END IF 

	MESSAGE "Mark this phone information as deleted?" 


	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_phone","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE phone SET 
			valid_to = today 
			WHERE phone_id = g_phone.phone_id 

			UPDATE contact_phone SET 
			valid_to = today 
			WHERE phone_id = g_phone.phone_id 
			AND contact_id = g_contact_phone.contact_id 

			CLEAR FORM 
			EXIT MENU 
	END MENU 

	MESSAGE "" 

END FUNCTION #d_phone() 


###########################
FUNCTION next_phone_screen() 
	###########################


	{
		CASE current_form
	        WHEN 1
	            CALL d_contact2()
			WHEN 2
	            CALL d_contact1()
	        OTHERWISE
	            ERROR "Unknown form: contact.4gl, next_screen()"
	            EXIT PROGRAM
	    END CASE
	}

END FUNCTION 

#########################
FUNCTION new_phone_role() 
	#########################
	DEFINE 
	new_phone_role_name LIKE role.role_name, 
	new_phone_role_code LIKE role.role_code 


	CALL role_lp("PHONE") 
	RETURNING new_phone_role_code, new_phone_role_name 

	# IF Null IS RETURN THEN the users has interrupted
	IF new_phone_role_code IS NOT NULL 
	AND new_phone_role_name IS NOT NULL 
	THEN 

		IF duplicate_phone_role(new_phone_role_code) THEN 
			ERROR "This contact already has an phone with this role !" 
			SLEEP 2 
		ELSE 
			INSERT INTO contact_phone VALUES 
			(g_contact.contact_id, 
			g_phone.phone_id, 
			new_phone_role_code, 
			today, 
			"") 

			LET all_roles = get_phone_roles(gv_null,false) 
			CALL display_phone() 

		END IF 
	END IF 

END FUNCTION #new_phone_role() 

##################################################
FUNCTION duplicate_phone_role(new_phone_role_code) 
	##################################################
	DEFINE 
	new_phone_role_code LIKE role.role_code, 
	cnt 
	INTEGER 

	LET cnt = 0 

	SELECT count(*) INTO cnt FROM contact_phone 
	WHERE contact_id = g_contact.contact_id 
	#            AND
	#            phone_id = g_phone.phone_id
	AND 
	role_code = new_phone_role_code 
	AND 
	(valid_to IS NULL OR valid_to > today) 

	IF 
	cnt > 0 
	THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_phone_role() 

##############################################
FUNCTION all_phone_roles(disp_format,and_exit) 
	##############################################
	DEFINE 
	a_contact_phone ARRAY [100] OF RECORD 
		contact_id LIKE contact_phone.contact_id, 
		phone_id LIKE contact_phone.phone_id, 
		phone_role_code LIKE contact_phone.role_code, 
		valid_from LIKE contact_phone.valid_from, 
		valid_to LIKE contact_phone.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		phone_role_name LIKE role.role_name, 
		valid_from LIKE contact_phone.valid_from, 
		valid_to LIKE contact_phone.valid_to, 
		country_code CHAR (3), #like phone., 
		area_code CHAR (4), #like phone., 
		phone_number CHAR (10) #like phone. 
	END RECORD, 

	cnt, 
	line_cnt, 
	changed, 
	disp_format, 
	and_exit 
	SMALLINT, 
	new_phone_role_code 
	LIKE role.role_code, 
	new_phone_role_name 
	LIKE role.role_name 


	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_roles with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_phone_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_phone_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_all_ph_roles CURSOR FOR 
	SELECT * FROM contact_phone 
	WHERE contact_id = g_contact.contact_id 
	ORDER BY valid_from desc 


	LET cnt = 1 

	##################################################
	FOREACH c_all_ph_roles INTO a_contact_phone[cnt].* 
		##################################################

		LET a_display[cnt].phone_role_name = get_role_name(a_contact_phone[cnt].phone_role_code, "PHONE") 


		LET a_display[cnt].valid_from = a_contact_phone[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_phone[cnt].valid_to 

		SELECT country_code, area_code, phone_number INTO 
		a_display[cnt].country_code, 
		a_display[cnt].area_code, 
		a_display[cnt].phone_number 
		FROM phone WHERE 
		phone_id = a_contact_phone[cnt].phone_id #tmp_phone_id 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_all_ph_roles 
	FREE c_all_ph_roles 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All phone roles FOR this contact" 
	ELSE 
		MESSAGE "All phone roles FOR this contact (SELECT=Accept,F6=change,F7=remove)" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_phone","display_arr-a_display-1") -- albo kd-513 

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

			###########
		ON KEY (f6) #change role 
			{! ON KEY (f6) #change role !}
			###########

			LET line_cnt = arr_curr() #scr_line() 

			IF a_contact_phone[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				CONTINUE DISPLAY 
				{! continue DISPLAY !}
			END IF 


			CALL role_lp("PHONE") 
			RETURNING new_phone_role_code, new_phone_role_name 

			IF 
			new_phone_role_code IS NOT NULL 
			THEN 

				IF change_phone_role( false, 
				new_phone_role_code, 
				new_phone_role_name, 
				a_contact_phone[line_cnt].contact_id, 
				a_contact_phone[line_cnt].phone_id, 
				a_contact_phone[line_cnt].phone_role_code 
				) THEN 
					LET changed = true 
					EXIT DISPLAY 
					{! EXIT DISPLAY !}
				END IF 
			END IF 

			########################
		ON KEY (f7) #remove role 
			{! ON KEY (f7) #remove role !}
			########################
			LET line_cnt = arr_curr() #scr_line() 
			IF a_contact_phone[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				CONTINUE DISPLAY 
				{! continue DISPLAY !}
			END IF 

			IF 
			change_phone_role( 
			true, 
			gv_null, 
			gv_null, 
			a_contact_phone[line_cnt].contact_id, 
			a_contact_phone[line_cnt].phone_id, 
			a_contact_phone[line_cnt].phone_role_code 
			) 
			THEN 
				LET changed = true 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 


			###########
	END DISPLAY 
	{! END DISPLAY !}
	###########

	MESSAGE "" 

	CASE disp_format 
		WHEN 1 #big new WINDOW 
			CLOSE WINDOW w_all_roles 

		WHEN 2 
			#			DISPLAY FORM f_phone1
			#			CALL display_phone()
	END CASE 


	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	IF 
	changed 
	THEN 
		LET all_roles = 
		get_phone_roles(a_contact_phone[cnt].phone_id,FALSE) #phone_id,and_hist 
	END IF 

	RETURN a_contact_phone[cnt].phone_id 

END FUNCTION #all_phone_roles() 


###########################################
FUNCTION phone_hist(disp_format,and_exit) 
	###########################################
	DEFINE 
	a_phone ARRAY [100] OF RECORD 
		phone_id LIKE phone.phone_id, 
		#	   contact_id LIKE contact_phone.contact_id,
		time_restrict_code LIKE phone.time_restrict_code, 
		country_code LIKE phone.country_code, 
		area_code LIKE phone.area_code, 
		phone_number LIKE phone.phone_number, 
		extension LIKE phone.extension, 
		valid_from LIKE phone.valid_from, 
		valid_to LIKE phone.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		phone_role_name LIKE role.role_name, 
		valid_from LIKE contact_phone.valid_from, 
		valid_to LIKE contact_phone.valid_to, 
		area_code CHAR (3), #like phone., 
		phone_number CHAR (10), #like phone., 
		extension CHAR (5) #like phone. 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	and_hist 
	SMALLINT 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_phone_hist with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_phone_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_phone_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_phone_hist CURSOR FOR 
	SELECT unique phone.* FROM contact_phone, phone 
	WHERE contact_phone.contact_id = g_contact.contact_id 
	AND contact_phone.phone_id = phone.phone_id 
	ORDER BY phone.valid_to desc 
	{
	    if NOT and_hist THEN
		    LET where_part = where_part clipped,
	        " AND phone.valid_to IS NULL OR phone.valid_to >= today "

	    END IF
	}

	LET cnt = 1 

	#########################################
	FOREACH c_phone_hist INTO a_phone[cnt].* 
		#########################################

		LET a_display[cnt].phone_role_name = get_phone_roles(a_phone[cnt].phone_id,true) 

		LET a_display[cnt].valid_from = a_phone[cnt].valid_from 
		LET a_display[cnt].valid_to = a_phone[cnt].valid_to 

		LET a_display[cnt].area_code = a_phone[cnt].area_code 
		LET a_display[cnt].phone_number = a_phone[cnt].phone_number 
		LET a_display[cnt].extension = a_phone[cnt].extension 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_phone_hist 
	FREE c_phone_hist 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF 
	and_exit 
	THEN 
		MESSAGE "All phones FOR this contact" 
	ELSE 
		MESSAGE "All phones FOR this contact - SELECT AND press Accept" 
	END IF 

	#######################################
	DISPLAY ARRAY a_display TO s_display.* 
	#######################################
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_phone","display_arr-a_display-2") -- albo kd-513 

		BEFORE ROW 
			{! BEFORE ROW !}
			IF 
			and_exit 
			THEN 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 
	{! END DISPLAY !}

	MESSAGE "" 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			CLOSE WINDOW w_phone_hist 
		WHEN 2 
			#			DISPLAY FORM f_phone1
			#			CALL display_phone()
	END CASE 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_phone[cnt].phone_id 

END FUNCTION #phone_hist() 


#########################################
FUNCTION get_contact_phone(p_phone_id) 
	#########################################
	DEFINE 
	p_phone RECORD LIKE phone.*, 
	p_phone_id LIKE phone.phone_id 


	SELECT * INTO p_phone.* 
	FROM phone 
	WHERE phone_id = p_phone_id 


	RETURN p_phone.* 

END FUNCTION #get_contact_phone 


##########################################################
FUNCTION get_phone_for_contact(p_contact_id,p_role_name) 
	##########################################################
	DEFINE 
	p_contact_id LIKE contact.contact_id, 
	p_role_name LIKE role.role_name, 
	pr_phone RECORD LIKE phone.* 

	SELECT unique phone.* INTO pr_phone.* 
	FROM phone, contact_phone, role 
	WHERE 
	contact_phone.phone_id = phone.phone_id 
	AND 
	contact_phone.contact_id = p_contact_id 
	AND 
	contact_phone.role_code = role.role_code 
	AND 
	role.role_name = p_role_name 
	AND 
	role.class_name = "PHONE" 
	AND 
	(contact_phone.valid_to IS NULL OR contact_phone.valid_to > today) 
	AND 
	(phone.valid_to IS NULL OR phone.valid_to > today) 

	IF status = notfound THEN 
		INITIALIZE pr_phone.* TO NULL 
	END IF 

	RETURN pr_phone.* 

END FUNCTION #get_phone_for_contact 



#####################################################
FUNCTION get_time_restrict_name(p_time_restrict_code) 
	#####################################################
	DEFINE 
	p_time_restrict_code LIKE phone.time_restrict_code, 
	p_time_restrict_name LIKE time_restrict.time_restrict_name 


	SELECT time_restrict_name INTO p_time_restrict_name 
	FROM time_restrict 
	WHERE time_restrict_code = p_time_restrict_code 

	RETURN p_time_restrict_name 

END FUNCTION #get_time_restrict_name() 



######################################
FUNCTION is_default_phone(p_phone_id) 
	######################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt 
	SMALLINT, 
	tmp_role_code 
	LIKE role.role_code, 
	is_default 
	SMALLINT, 
	p_phone_id 
	LIKE phone.phone_id 


	LET tmp_role_code = get_role_code("DEFAULT","PHONE") 

	SELECT * FROM contact_phone 
	WHERE role_code = tmp_role_code 
	AND phone_id = p_phone_id 
	AND contact_id = g_contact.contact_id 


	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 



	{
	    LET is_default = FALSE

	    DECLARE c_rolesp2 CURSOR FOR
	        SELECT unique phone_role_code FROM contact_phone
	            WHERE phone_id = g_phone.phone_id

	    INITIALIZE all_roles TO NULL

	    LET cnt = 1

	######################################
	    FOREACH c_rolesp2 INTO a_role_codes[cnt]
	######################################

	        SELECT phone_role_name INTO tmp_role_name FROM phone_role_code
	            WHERE phone_role_code = a_role_codes[cnt]

	        if tmp_role_name = "DEFAULT" THEN
	            LET is_default = TRUE
	            EXIT FOREACH
	        END IF

	        LET cnt = cnt + 1

	###########
	    END FOREACH
	###########

	    close c_rolesp2
	    free c_rolesp2

	    RETURN is_default
	}
END FUNCTION #is_default_phone() 

#########################################
FUNCTION get_phone_owners(any_contact) 
	#########################################
	DEFINE 
	any_contact, 
	cnt, 
	tmp_one_role 
	SMALLINT 

	LET query_1 = 
	"SELECT unique contact_id ", #, phone_id,role_code,valid_from,valid_to ", 
	" FROM contact_phone ", 
	" WHERE contact_phone.phone_id = ",g_phone.phone_id, 
	" group by contact_phone.contact_id" 
	MESSAGE "Searching...please wait" 
	PREPARE xp_stmt FROM query_1 
	DECLARE c_pcntct CURSOR FOR xp_stmt 

	LET cnt = 1 

	#######################################
	FOREACH c_pcntct INTO a_all_ph_owners[cnt].contact_id #* 
		#######################################

		IF a_all_ph_owners[cnt].contact_id = g_contact.contact_id THEN 
			LET tmp_one_role = get_one_ph_role(g_phone.phone_id,a_all_ph_owners[cnt].contact_id) 

			SELECT * INTO g_contact_phone.* 
			FROM contact_phone 
			WHERE contact_phone.phone_id = g_phone.phone_id 
			AND contact_phone.contact_id = a_all_ph_owners[cnt].contact_id 
			AND contact_phone.role_code = tmp_one_role 

		ELSE 
			IF any_contact THEN 
				LET tmp_one_role = get_one_ph_role(g_phone.phone_id,a_all_ph_owners[cnt].contact_id) 

				SELECT * INTO g_contact_phone.* 
				FROM contact_phone 
				WHERE contact_phone.phone_id = g_phone.phone_id 
				AND contact_phone.contact_id = a_all_ph_owners[cnt].contact_id 
				AND contact_phone.role_code = tmp_one_role 
				AND valid_to IS NULL OR valid_to > today 
			END IF 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_pcntct 
	FREE c_pcntct 
	MESSAGE "" 

	LET all_ph_owners_cnt = cnt - 1 

	IF all_ph_owners_cnt > 1 THEN 
		MESSAGE "WARNING: This phone belongs TO multiple Contacts !" 
		attribute (red) 
		SLEEP 3 
	END IF 

END FUNCTION #get_phone_owners() 


##############################################
FUNCTION list_all_ph_owners(tmp_phone_id) 
	##############################################
	DEFINE 
	tmp_phone_id LIKE phone.phone_id, 
	a_names array[40] OF RECORD 
		NAME CHAR(15) 
	END RECORD, 
	cnt 
	SMALLINT, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	tmp_name CHAR(100) 

	OPEN WINDOW w_allownph_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	MESSAGE "SELECT AND press Accept" 

	#############################
	FOR cnt = 1 TO all_ph_owners_cnt 
		#############################

		CALL get_contact_name(a_all_ph_owners[cnt].contact_id) RETURNING tmp_first, tmp_last 

		IF length (tmp_first) > 0 THEN 
			LET tmp_name = tmp_first clipped, " ", tmp_last clipped 
		ELSE 
			LET tmp_name = tmp_last clipped 
		END IF 
		LET a_names[cnt].name = tmp_name [1,15] 

		#######
	END FOR 
	#######

	CALL set_count(all_ph_owners_cnt) 

	DISPLAY ARRAY a_names TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_phone","display_arr-a_names-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 

	LET cnt = arr_curr() #scr_line() 

	CLOSE WINDOW w_allownph_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	RETURN a_all_ph_owners[cnt].contact_id 


END FUNCTION #list_all_ph_owners() 


#####################################################################
FUNCTION change_phone_role(and_remove,new_phone_role_code,new_phone_role_name, 
	p_contact_id,p_phone_id,p_phone_role_code) 
	#####################################################################
	DEFINE 
	changed, 
	tmp_cnt, 
	and_remove 
	SMALLINT, 
	new_phone_role_code, 
	p_phone_role_code 
	LIKE role.role_code, 
	new_phone_role_name 
	LIKE role.role_name, 
	p_contact_id 
	LIKE contact.contact_id, 
	p_phone_id 
	LIKE phone.phone_id 


	IF and_remove THEN 
		MESSAGE "Do you realy want TO remove selected role ?" 
		attribute (red) 
	ELSE 
		MESSAGE "Do you realy want TO change selected role TO ", 
		new_phone_role_name clipped, " ?" 
		attribute (red) 
	END IF 


	MENU "Change role" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_phone","menu-Change_role-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			###############################################
		COMMAND "Cancel" "Abort, don't change anything" 
			###############################################

			LET changed = false 
			EXIT MENU 

			##################################
		COMMAND "OK" "Execute the change" 
			##################################

			IF and_remove THEN 
				UPDATE contact_phone 
				SET valid_to = today 
				WHERE contact_id = p_contact_id 
				AND phone_id = p_phone_id 
				AND role_code = p_phone_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact phone: aborted !" 
					SLEEP 5 
					LET changed = false 
				ELSE 
					LET changed = true 
				END IF 

				SELECT count (*) INTO tmp_cnt 
				FROM contact_phone 
				WHERE phone_id = p_phone_id 
				AND (valid_to IS NULL OR valid_to > today) 


				IF tmp_cnt = 0 THEN # no valid relations TO this phone FROM any contact 
					UPDATE phone 
					SET valid_to = today 
					WHERE phone_id = p_phone_id 
				END IF 

			ELSE #change 

				UPDATE contact_phone 
				SET role_code = new_phone_role_code 
				WHERE contact_id = p_contact_id 
				AND phone_id = p_phone_id 
				AND role_code = p_phone_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact phone: aborted !" 
					SLEEP 5 
					LET changed = false 
				ELSE 
					LET changed = true 
				END IF 

			END IF 

			EXIT MENU 

			########
	END MENU 
	########

	MESSAGE "" 

	RETURN changed 

END FUNCTION #change_phone_role() 


###############################################################
FUNCTION select_phone(restrict_contact_id,current_phone_id) 
	###############################################################
	DEFINE 
	restrict_contact_id 
	LIKE contact.contact_id, 
	selected_phone_id, 
	current_phone_id 
	LIKE phone.phone_id, 
	where_part 
	CHAR (800), 
	send1, send2, send3, send4 #where_part 
	CHAR (200), 
	save_contact_phone 
	RECORD LIKE contact_phone.*, 
		save_phone 
		RECORD LIKE phone.* 


			LET save_contact_phone.* = g_contact_phone.* 
			LET save_phone.* = g_phone.* 
			{
						OPEN WINDOW w_phone_select  -- albo  KD-766
					        AT 2,2 with 9 rows, 75 columns
								attribute (border)
			}
			LABEL start_here: 


			#			CALL clear_info()
			#            CURRENT WINDOW IS w_contact

			DISPLAY FORM f_phone1 

			MESSAGE "" 

			CALL qbe_phone(true) #any_contact 
			RETURNING send1, send2, send3 #, send4 
			CALL phone_where_part(send1, send2, send3, true) 
			RETURNING send1, send2, send3 

			IF 
			send1 IS NULL 
			THEN 
				LET int_flag = false 
				--				CLOSE WINDOW w_phone_select  -- albo  KD-766
				RETURN gv_null 
			ELSE 

				LET where_part = send1, send2, send3, send4 

				LET where_part = where_part clipped, 
				" AND contact_phone.contact_id <> ", restrict_contact_id, 
				" AND contact_phone.phone_id = phone.phone_id " 


				LET send1 = where_part[1,200] 
				LET send2 = where_part[201,400] 
				LET send3 = where_part[401,600] 
				#			    LET send4 = where_part[601,800]


				IF 
				open_phone_cursor(send1, send2, send3, true) #any_contact 
				THEN 
					#CALL contact_info("1")
					MENU "SELECT new phone FOR Contact" 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","contact_phone","menu-new_phone-1") -- albo kd-513 

						ON ACTION "WEB-HELP" -- albo 
							CALL onlinehelp(getmoduleid(),null) 

						COMMAND "+" "Next found" 
							MESSAGE"" 
							CURRENT WINDOW IS w_phone_select 
							IF 
							n_phone(TRUE) #any_contact 
							THEN 
								#CALL contact_info("1")
							END IF 

						COMMAND "-" "Previous found" 
							MESSAGE"" 
							CURRENT WINDOW IS w_phone_select 
							IF 
							p_phone(TRUE) #any_contact 
							THEN 
								#CALL contact_info("1")
							END IF 

						COMMAND "SELECT" "SELECT current phone TO be used FOR Contact" 
							LET selected_phone_id = g_phone.phone_id 
							EXIT MENU 

						COMMAND "Quit" "Quit selection without selecting new phone number" 
							INITIALIZE selected_phone_id TO NULL 
							EXIT MENU 

					END MENU 
				ELSE 
					ERROR "No records foud; Try again, OR SELECT CTRL+C AND THEN Quit" 
						SLEEP 2 
						GOTO start_here 
					END IF 
				END IF 

				IF 
				current_phone_id IS NOT NULL #restore global records 
				THEN 
							{
							SELECT * INTO g_phone.*
						        FROM phone
						            WHERE phone.phone_id = current_phone_id
					        }

					LET g_phone.* = save_phone.* 
					LET g_contact_phone.* = save_contact_phone.* 

				END IF 

				#    CALL get_codes()
				#	CALL display_contact()

				--	CLOSE WINDOW w_phone_select  -- albo  KD-766

				RETURN selected_phone_id 

END FUNCTION #select_phone() 

###################################################### module end
