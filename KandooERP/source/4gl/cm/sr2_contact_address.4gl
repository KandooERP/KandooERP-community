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
 * contact address related functions
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

a_all_addr_owners array[40] OF RECORD 
	contact_id LIKE contact_address.contact_seed, 
	address_id LIKE contact_address.address_id, 
	role_code LIKE contact_address.role_code, 
	valid_from LIKE contact_address.valid_from, 
	valid_to LIKE contact_address.valid_to 
END RECORD, 

all_addr_owners_cnt 
SMALLINT 

#######################
FUNCTION address_menu() 
	#######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success, 
	any_contact 
	SMALLINT, 
	address_id, 
	tmp_contact_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	new_address_id LIKE address.address_id, 
	new_addr_role_code LIKE role.role_code, 
	new_addr_role_name LIKE role.role_name 

	MESSAGE"" 
	CALL init_addr() 

	CURRENT WINDOW IS w_contact 

	MENU "Address" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_address","menu-Address-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query by address data" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET any_contact = false 
			CALL qbe_address(any_contact) RETURNING send1, send2, send3 
			CALL addr_where_part(send1, send2, send3, any_contact) 
			RETURNING send1, send2, send3 

			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET success = open_addr_cursor(send1, send2, send3, any_contact) 
			END IF 

		COMMAND "+" "Next found" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET success = n_address(any_contact) 

		COMMAND "-" "Previous found" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET success = p_address(any_contact) 

		COMMAND "Add" "Add new address FOR this contact" 
			MESSAGE"" 
			CALL init_addr_win() 
			MENU "Add address" 
				COMMAND "Add new" "Add a new phisycal address TO the database" 
					LET success = au_contact_address(g_contact.contact_id,true) #add_mode 
					EXIT MENU 

				COMMAND "Pick" "Pick an existing address TO be used by this Contact" 


					LET new_address_id = select_address(g_contact.contact_id,g_address.address_id) 
					MESSAGE "" 

					IF new_address_id IS NOT NULL THEN 
						CALL role_lp("ADDRESS") 
						RETURNING new_addr_role_code, new_addr_role_name 

						IF new_addr_role_code IS NOT NULL THEN 
							IF duplicate_addr_role(new_addr_role_code) THEN 
								ERROR "This contact already has an address with this role. Please SELECT another role !" 
								SLEEP 2 
								CONTINUE MENU 
							END IF 

							LET g_contact_address.contact_seed = g_contact.contact_id 
							LET g_contact_address.address_id = new_address_id 
							LET g_contact_address.role_code = new_addr_role_code 
							LET g_contact_address.valid_from = today 
							INITIALIZE g_contact_address.valid_to TO NULL 

							INSERT INTO contact_address VALUES (g_contact_address.*) 

							IF status <> 0 THEN 
								ERROR "Cannot add contact phone: Add aborted !" 
								SLEEP 5 
							ELSE 
								ERROR "Selected address added under the role of ", new_addr_role_name clipped 
								SLEEP 1 
								EXIT MENU 
							END IF 
						END IF 
					END IF 


				COMMAND KEY ("c","C",interrupt,escape) "Cancel" "Do NOT add a new address" 
					EXIT MENU 
			END MENU 

		COMMAND "Edit" "Modify current address fot this contact" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET success = au_contact_address(g_contact.contact_id,false) #add_mode 

		COMMAND "New role" "Add a new role FOR this address" 
			MESSAGE"" 
			CALL init_addr_win() 
			CALL new_addr_role() 

		COMMAND "Change role" "Change roles FOR this address" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET address_id = all_address_roles(2,false) 
			DISPLAY FORM f_address1 
			CALL display_address() 
			IF address_id IS NOT NULL THEN 
				CALL disp_selected_addr(address_id) 
			END IF 

		COMMAND KEY ("r","R") "all Roles" "DISPLAY all role AND address info on this contact, including history" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET address_id = all_address_roles(2,false) 
			DISPLAY FORM f_address1 
			CALL display_address() 
			IF address_id IS NOT NULL THEN 
				CALL disp_selected_addr(address_id) 
			END IF 

		COMMAND "History" "DISPLAY all historycal address info" 
			MESSAGE"" 
			CALL init_addr_win() 
			LET address_id = address_hist("2",FALSE,TRUE) 
			DISPLAY FORM f_address1 
			CALL display_address() 
			CALL disp_selected_addr(address_id) 

		COMMAND "Delete" "Delete current address" 
			MESSAGE"" 
			CALL init_addr_win() 
			CALL del_address() 

		COMMAND KEY ("y","Y") "anY address" "Query FOR any contact address" 
			MESSAGE "" 
			CALL init_addr_win() 
			LET any_contact = true 
			CALL qbe_address(any_contact) RETURNING send1, send2, send3 
			CALL addr_where_part(send1, send2, send3, any_contact) 
			RETURNING send1, send2, send3 

			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				LET success = open_addr_cursor(send1, send2, send3, any_contact) 
			END IF 


		COMMAND "Switch" "Switch current contact TO the one that the displayed address belongs TO" 

			IF g_contact_address.contact_seed <> g_contact.contact_id THEN 
				CALL get_contact_name(g_contact_address.contact_seed) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_address","menu-Switch-1") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current address belongs TO" 
						MESSAGE "" 
						CALL switch_contact(g_contact_address.contact_seed) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This address belongs TO the current contact: Cannot switch" 
			END IF 


			#        COMMAND "Screen" "Show next SCREEN of current address data"
			#            CALL next_addr_screen()

		COMMAND "Owners" "Show all owners of this address" 
			CALL init_addr_win() 
			LET tmp_contact_id = list_all_addr_owners(g_address.address_id) 

			IF tmp_contact_id IS NOT NULL THEN 
				IF tmp_contact_id <> g_contact.contact_id THEN 
					CALL get_contact_name(tmp_contact_id) RETURNING tmp_first, tmp_last 

					LET g_msg = "Switch current contact TO ", 
					tmp_first clipped, " ", tmp_last clipped, " ?" 

					MESSAGE g_msg clipped 

					MENU "Switch" 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","contact_address","menu-Switch-2") -- albo kd-513 

						ON ACTION "WEB-HELP" -- albo 
							CALL onlinehelp(getmoduleid(),null) 

						COMMAND "Cancel" "Do NOT switch TO new contact" 
							MESSAGE "" 
							EXIT MENU 

						COMMAND "OK" "Yes, switch TO the contact that the current address belongs TO" 
							MESSAGE "" 
							CALL switch_contact(tmp_contact_id) 

							EXIT MENU 
					END MENU 

					MESSAGE "" 

				ELSE 
					ERROR "This address belongs TO the current contact: Cannot switch" 
				END IF 
			END IF 

		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #address_menu() 

####################################
FUNCTION disp_selected_addr(address_id) 
	####################################
	DEFINE 
	address_id 
	LIKE address.address_id, 
	success 
	SMALLINT, 
	send1, send2, send3 #where_part 
	CHAR (200) 

	IF address_id IS NOT NULL THEN 
		LET send1 = " address.address_id = ", address_id 
		INITIALIZE send2, send3 TO NULL 

		CALL addr_where_part(send1, send2, send3, false) #any_contact 
		RETURNING send1, send2, send3 

		LET success = open_addr_cursor(send1, send2, send3, false) #any_contact 
	END IF 
END FUNCTION 


######################
FUNCTION init_addr() 
	######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	#already opmen FOR Info !
	#    OPEN WINDOW w_address
	#        AT 12,2 with 13 rows, 75 columns
	#            attribute (border)

	CALL init_addr_win() 

	# We want TO get all Address's FOR a contact NOT
	# just the DEFAULT
	#    LET send1 = " role.role_name = 'DEFAULT' ",
	#                " AND role.class_name = 'ADDRESS' ",
	#                " AND role.role_code = contact_address.role_code ",
	#                " AND contact_address.contact_seed = ", g_contact.contact_id, " "

	LET send1 = " contact_address.contact_seed = ", g_contact.contact_id, " " 

	INITIALIZE send2, send3 TO NULL 

	CALL addr_where_part(send1, send2, send3,false) #any_contact 
	RETURNING send1, send2, send3 

	LET dummy = open_addr_cursor(send1, send2, send3, false) #any_contact 

	MESSAGE "Default address:" 

END FUNCTION #init_addr() 

########################
FUNCTION init_addr_win() 
	########################
	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_address1 

	LET current_addr_form = 1 

END FUNCTION 


################################
FUNCTION qbe_address(any_contact) 
	################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	tmp_addr_role_name, tmp_name 
	LIKE role.role_name, 
	any_contact 
	SMALLINT 

	IF current_addr_form <> 1 THEN 
		CALL d_address1() 
	END IF 


	LABEL start_construct: 
	CLEAR FORM 
	INITIALIZE where_part TO NULL 
	MESSAGE "Enter the query conndition AND press Accept" 


	CONSTRUCT where_part ON 
	address.line1, 
	role.role_name, 
	address.line2, 
	address.street, 
	address.suburb, 
	address.city, 
	address.region, 
	address.post_code, 
	address.country, 
	address.user_defined1, 
	address.user_defined2, 
	address.user_defined3, 
	address.user_defined4, 
	address.valid_from, 
	address.valid_to 

	FROM 
	s_address.line1, 
	s_address.addr_role_name, 
	s_address.line2, 
	s_address.street, 
	s_address.suburb, 
	s_address.city, 
	s_address.region, 
	s_address.post_code, 
	s_address.country, 
	s_address.user_defined1, 
	s_address.user_defined2, 
	s_address.user_defined3, 
	s_address.user_defined4, 
	s_address.valid_from, 
	s_address.valid_to 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact_address","construct-s_address-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############################
		AFTER FIELD addr_role_name 
			############################
			LET tmp_addr_role_name = get_fldbuf(addr_role_name) 

			IF tmp_addr_role_name IS NOT NULL 
			AND length (tmp_addr_role_name) > 0 THEN 
				LET tmp_name = get_fldbuf(addr_role_name) 

				SELECT * FROM role 
				WHERE role_name = tmp_name 
				AND class_name = "ADDRESS" 

				IF status = notfound THEN 
					ERROR "This role IS NOT defined" 
					NEXT FIELD addr_role_name 

				END IF 
				{
				        ELSE
				            LET tmp_name = "DEFAULT"
				            DISPLAY tmp_name TO s_address.addr_role_name
				}
			END IF 

			###############
		AFTER CONSTRUCT 
			###############

			IF any_contact 
			AND where_part matches "*1=1*" THEN 
				#does NOT work: variable IS NOT accessible insid eof the
				#CONSTRUCT statemant

				ERROR "Please enter AT least on codition FOR this query" 
				SLEEP 1 
				CONTINUE CONSTRUCT 
			END IF 


			LET tmp_addr_role_name = get_fldbuf(addr_role_name) 

			IF tmp_addr_role_name IS NOT NULL 
			AND length (tmp_addr_role_name) > 0 THEN 
				LET tmp_name = get_fldbuf(addr_role_name) 

				SELECT * FROM role 
				WHERE role_name = tmp_name 
				AND class_name = "ADDRESS" 

				IF status = notfound THEN 
					ERROR "This role IS NOT defined" 
					NEXT FIELD addr_role_name 

				END IF 
				{
				        ELSE
				            LET tmp_name = "DEFAULT"
				            DISPLAY tmp_name TO s_address.addr_role_name
				}
			END IF 


			#############
	END CONSTRUCT 
	#############

	IF int_flag THEN 
		#        LET int_flag = FALSE
		RETURN gv_null, gv_null, gv_null #where_part 
	END IF 

	IF any_contact 
	AND where_part matches "*1=1*" THEN 
		ERROR "Please enter AT least one codition FOR this query" 
		SLEEP 2 
		GOTO start_construct 
	END IF 

	MESSAGE "" 

	IF NOT any_contact THEN 
		LET where_part = where_part clipped, 
		" AND contact_address.contact_seed = ", g_contact.contact_id, " " 
	END IF 


	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	#    CALL addr_where_part(send1, send2, send3, any_contact)
	#       returning send1, send2, send3

	#    LET last_addr_where_part = where_part

	RETURN send1, send2, send3 #where_part 

END FUNCTION #q_address() 


####################
FUNCTION d_address1() 
	####################

	DISPLAY FORM f_address1 
	LET current_addr_form = 1 
	CALL display_address() 

END FUNCTION 

###################################################
FUNCTION get_address_roles(tmp_address_id,and_hist) 
	###################################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt, 
	and_hist 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 
	tmp_address_id 
	LIKE address.address_id, 
	where_part 
	CHAR (300) 

	IF tmp_address_id IS NULL THEN 
		LET tmp_address_id = g_address.address_id 
	END IF 

	LET where_part = 
	" SELECT unique role_code FROM contact_address ", 
	" WHERE address_id = ", tmp_address_id, 
	" AND contact_id = ", g_contact.contact_id 

	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" AND (valid_to IS NULL OR valid_to > today )" 
	END IF 
	IF do_debug THEN 
		CALL errorlog (where_part) 
	END IF 

	MESSAGE "Searching...please wait" 
	PREPARE xde33 FROM where_part 
	DECLARE c_roles CURSOR FOR xde33 

	#    INITIALIZE all_roles TO NULL
	LET all_roles = "UNKNOWN" 

	LET cnt = 1 

	######################################
	FOREACH c_roles INTO a_role_codes[cnt] 
		######################################

		LET tmp_role_name = get_role_name(a_role_codes[cnt], "ADDRESS") 

		IF cnt = 1 THEN 
			LET all_roles = tmp_role_name 
		ELSE 
			LET all_roles = all_roles clipped,", ", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	MESSAGE "" 

	CLOSE c_roles 
	FREE c_roles 

	RETURN all_roles 

END FUNCTION #get_address_roles() 

##########################################################
FUNCTION addr_where_part(send1, send2, send3, any_contact) 
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

	LET where_part = "SELECT ", 
	" unique ", 
	" address.* ", 
	#" , contact_address.* ",
	" FROM address, contact_address " 

	IF received_where_part matches "*role.role_name*" THEN 
		LET where_part = where_part clipped, 
		", role " 
	END IF 

	LET where_part = where_part clipped, 
	" WHERE ", received_where_part clipped, 
	#        " AND contact_address.contact_seed = ", g_contact.contact_id,
	" AND contact_address.address_id = address.address_id " 


	IF received_where_part matches "*role.role_name*" THEN 
		LET where_part = where_part clipped, 
		" AND role.role_code = contact_address.role_code ", 
		" AND role.class_name = 'ADDRESS' " 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	RETURN send1, send2, send3 #where_part 

END FUNCTION #addr_where_part() 


##########################################################
FUNCTION open_addr_cursor(send1, send2, send3,any_contact) 
	##########################################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT, 
	dummy_address 
	RECORD LIKE address.* 

		LET where_part = send1, send2, send3 

		IF show_valid THEN 
			LET where_part = where_part clipped, 
			" AND (contact_address.valid_to IS NULL OR contact_address.valid_to > TODAY)", 
			" AND (address.valid_to IS NULL OR address.valid_to > TODAY)" 

		END IF 

		#    LET where_part = where_part clipped," group by address.address_id, address.contact_id ... line1 etc must be in group by "

		IF do_debug THEN 
			CALL errorlog(where_part) 
		END IF 

		PREPARE x2 FROM where_part 
		DECLARE c_read_addr SCROLL CURSOR with HOLD FOR x2 

		MESSAGE "Preparing query, please wait..." 

		OPEN c_read_addr 

		MESSAGE "Searching FOR first match, please wait..." 

		FETCH FIRST c_read_addr INTO g_address.* #, g_contact_address.* 

		IF status = notfound THEN 
			MESSAGE "" 
			ERROR "No records found" 
			INITIALIZE g_address.* TO NULL 
			RETURN false 
		ELSE 
			MESSAGE "" 
			CALL get_address_owners(any_contact) 
			LET all_roles = get_address_roles(gv_null,show_history) #address_id,and_hist 
			CALL display_address() 


			FETCH NEXT c_read_addr INTO dummy_address.* 

			IF status <> notfound THEN 
				ERROR "Query returned more THEN one record" 
					FETCH previous c_read_addr INTO dummy_address.* 
				END IF 

				RETURN true 
			END IF 

END FUNCTION #open_addr_cursor() 


#####################################################
FUNCTION get_one_addr_role(p_address_id,p_contact_id) 
	#####################################################
	DEFINE 
	p_address_id LIKE address.address_id, 
	p_contact_id LIKE contact.contact_id, 
	tmp_role_code LIKE role.role_code 


	DECLARE c_one_addr_role CURSOR FOR 
	SELECT role_code FROM contact_address 
	WHERE contact_id = p_contact_id 
	AND address_id = p_address_id 
	GROUP BY role_code 


	MESSAGE "Searching FOR one role, please wait..." 

	##########################################
	FOREACH c_one_addr_role INTO tmp_role_code 
		##########################################

		IF is_default_role(tmp_role_code, "ADDRESS") THEN 
			EXIT FOREACH 
		END IF 

		###########
	END FOREACH 
	###########

	MESSAGE "" 

	CLOSE c_one_addr_role 
	FREE c_one_addr_role 

	RETURN tmp_role_code 

END FUNCTION #get_one_addr_role 

###############################
FUNCTION n_address(any_contact) 
	###############################
	DEFINE 
	any_contact 
	SMALLINT 

	IF g_address.address_id IS NULL THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 

	FETCH NEXT c_read_addr INTO g_address.* #, g_contact_address.* 

	IF status = notfound 
	THEN 
		ERROR "No more records found" 
		CALL display_address() 
		RETURN false 
	ELSE 
		CALL get_address_owners(any_contact) 
		LET all_roles = get_address_roles(gv_null,show_history) #address_id, and_hist 
		CALL display_address() 
		RETURN true 
	END IF 

END FUNCTION #read_next() 

################################
FUNCTION p_address(any_contact) 
	################################
	DEFINE 
	any_contact 
	SMALLINT 

	IF g_address.address_id IS NULL THEN 
		ERROR "Please enter Query condition first !" 
		RETURN false 
	END IF 


	FETCH previous c_read_addr INTO g_address.* #, g_contact_address.* 
	IF status = notfound THEN 
		ERROR "No previous records found" 
		CALL display_address() 
		RETURN false 
	ELSE 
		CALL get_address_owners(any_contact) 
		LET all_roles = get_address_roles(gv_null,show_history) #address_id, and_hist 
		CALL display_address() 
		RETURN true 
	END IF 

END FUNCTION #read_previous() 


####################################################
FUNCTION au_contact_address(tmp_contact_id,add_mode) 
	####################################################
	DEFINE 
	tmp_contact_id LIKE contact.contact_id, 
	p_addr_role_name, new_addr_role_name LIKE role.role_name, 
	new_addr_role_code LIKE role.role_code, 
	add_mode, 
	success 
	SMALLINT, 
	fr_store_address RECORD LIKE address.*, 
	store_contact_addr RECORD LIKE contact_address.* 

	IF current_addr_form <> 1 THEN 
		CALL d_address1() 
	END IF 

	IF add_mode THEN 
		INITIALIZE g_address TO NULL 
		INITIALIZE g_contact_address TO NULL 
		CLEAR FORM 
		MESSAGE "Enter new address data AND press Accept" 
	ELSE 
		LET fr_store_address.* = g_address.* 
		LET store_contact_addr.* = g_contact_address.* 
		MESSAGE "Enter changes AND press Accept" 
	END IF 

	#############
	INPUT 
	#############
	g_address.line1, 
	p_addr_role_name, 
	g_address.line2, 
	g_address.street, 
	g_address.suburb, 
	g_address.city, 
	g_address.region, 
	g_address.post_code, 
	g_address.country, 
	g_address.user_defined1, 
	g_address.user_defined2, 
	g_address.user_defined3, 
	g_address.user_defined4, 
	g_address.valid_from, 
	g_address.valid_to 

	WITHOUT DEFAULTS FROM 

	s_address.line1, 
	s_address.addr_role_name, 
	s_address.line2, 
	s_address.street, 
	s_address.suburb, 
	s_address.city, 
	s_address.region, 
	s_address.post_code, 
	s_address.country, 
	s_address.user_defined1, 
	s_address.user_defined2, 
	s_address.user_defined3, 
	s_address.user_defined4, 
	s_address.valid_from, 
	s_address.valid_to 


	############
		BEFORE INPUT 
			############
			CALL publish_toolbar("kandoo","contact_address","menu-s_address-1") -- albo kd-513 
			IF NOT add_mode THEN 
				DISPLAY all_roles TO s_address.addr_role_name 
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
				WHEN infield(addr_role_name) 
					############################

					CALL role_lp("ADDRESS") 
					RETURNING new_addr_role_code, new_addr_role_name 

					IF new_addr_role_code IS NOT NULL THEN 
						LET p_addr_role_name = new_addr_role_name 
						LET g_contact_address.role_code = new_addr_role_code 
						DISPLAY p_addr_role_name TO addr_role_name 
					END IF 


					########
			END CASE 
			########

			###########################
		BEFORE FIELD addr_role_name 
			###########################

			IF NOT add_mode THEN 
				NEXT FIELD NEXT 
			END IF 


			##########################
		AFTER FIELD addr_role_name 
			##########################

			IF p_addr_role_name IS NOT NULL 
			AND add_mode THEN 
				LET g_contact_address.role_code = get_role_code(p_addr_role_name, "ADDRESS") 

				IF g_contact_address.role_code IS NULL THEN 

					CALL role_lp("ADDRESS") 
					RETURNING new_addr_role_code, new_addr_role_name 

					IF new_addr_role_code IS NULL THEN 
						LET p_addr_role_name = "DEFAULT" 
						LET g_contact_address.role_code = get_default_code("ADDRESS") 
					ELSE 
						LET g_contact_address.role_code = new_addr_role_code 
						LET p_addr_role_name = new_addr_role_name 
					END IF 
				ELSE 

					IF add_mode THEN 
						IF duplicate_addr_role(new_addr_role_code) THEN 
							ERROR "This contact already has an address with this role !" 
							SLEEP 2 
							NEXT FIELD addr_role_name 

						END IF 
						#ELSE - no ELSE: user cannot change role in UPDATE SCREEN
					END IF 
				END IF 

				DISPLAY p_addr_role_name TO addr_role_name 

			END IF 

			######################
		AFTER FIELD valid_from 
			######################
			IF g_address.valid_from IS NULL THEN 
				LET g_address.valid_from = today 
				DISPLAY BY NAME g_address.valid_from 
			END IF 

			#####################
		AFTER FIELD post_code 
			#####################

			IF add_mode THEN 
				#IF duplicate_address() THEN
				#offer TO pick existing instead of adding
			END IF 

			###########
		AFTER INPUT 
			###########

			IF int_flag THEN 
				EXIT INPUT 
			END IF 


			LET g_contact_address.contact_seed = g_contact.contact_id 
			LET g_contact_address.valid_from = today 

			#LET g_address.address_id = 0
			LET g_address.valid_from = today 

			IF p_addr_role_name IS NULL 
			OR length (p_addr_role_name) < 1 THEN 
				LET p_addr_role_name = "DEFAULT" 

				LET g_contact_address.role_code = get_default_code("ADDRESS") 

			END IF 

			IF add_mode THEN 
				IF duplicate_addr_role(g_contact_address.role_code) THEN 
					ERROR "This contact already has an address with this role. Please SELECT another role !" 
					SLEEP 2 
					NEXT FIELD addr_role_name 

				END IF 
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

		IF g_address.line1 = fr_store_address.line1 
		AND g_address.line2 = fr_store_address.line2 
		AND g_address.street = fr_store_address.street 
		AND g_address.suburb = fr_store_address.suburb 
		AND g_address.city = fr_store_address.city 
		AND g_address.region = fr_store_address.region 
		AND g_address.post_code = fr_store_address.post_code 
		AND g_address.country = fr_store_address.country 
		AND g_address.user_defined1 = fr_store_address.user_defined1 
		AND g_address.user_defined2 = fr_store_address.user_defined2 
		AND g_address.user_defined3 = fr_store_address.user_defined3 
		AND g_address.user_defined4 = fr_store_address.user_defined4 
		AND g_address.valid_from = fr_store_address.valid_from 
		AND g_address.valid_to = fr_store_address.valid_to THEN 
			ERROR "Nothhing changed: nothing TO UPDATE" 
			RETURN false 
		END IF 
	END IF 

	LET success = store_address(add_mode) 

	RETURN success 

END FUNCTION #au_contact_address() 


###############################
FUNCTION store_address(add_mode) 
	###############################
	DEFINE 
	add_mode 
	SMALLINT, 
	old_address_id 
	INTEGER 

	LET old_address_id = g_address.address_id 

	##########
	BEGIN WORK 
		##########

		IF NOT add_mode  THEN #logical UPDATE

			#first, close previous record
			UPDATE address SET 
			valid_to = today 
			WHERE address_id = g_address.address_id 

			IF status <> 0 THEN 
				ERROR "Cannot close previous record: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

		END IF 

		LET g_contact_address.contact_seed = g_contact.contact_id 
		LET g_address.address_id = 0 
		LET g_address.valid_from = today 
		#LET g_contact.mod_user_id = glob_rec_kandoouser.sign_on_code

		INSERT INTO address VALUES (g_address.*) 

		IF status <> 0 THEN 
			ERROR "Cannot INSERT new record: Update/Add aborted !" 
			SLEEP 5 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		LET g_address.address_id = sqlca.sqlerrd[2] 


		IF add_mode THEN 

			LET g_contact_address.address_id = g_address.address_id 

			INSERT INTO contact_address VALUES (g_contact_address.*) 

			IF status <> 0 THEN 
				ERROR "Cannot add contact address: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 
			####
		ELSE #logical UPDATE 
			####
			{
			        SELECT * INTO g_contact_address.*
			            FROM contact_address
			                WHERE address_id = old_address_id

			        UPDATE contact_address
			            SET valid_to =  today
			                WHERE address_id = old_address_id

			}
			LET g_contact_address.address_id = g_address.address_id #new 
			#        INSERT INTO contact_address VALUES (g_contact_address.*)

			UPDATE contact_address 
			SET address_id = g_address.address_id 
			WHERE address_id = old_address_id 

			IF status <> 0 THEN 
				ERROR "Cannot UPDATE contact address: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

			{        SELECT * INTO g_contact_mailing.*
			            FROM contact_mailing
			             WHERE address_id = old_address_id

			        if STATUS <> NOTFOUND THEN
			            UPDATE contact_mailing
			                SET valid_to = today
			                    WHERE address_id = old_address_id

			            LET g_contact_mailing.address_id = g_address.address_id #new
			            INSERT INTO contact_mailing VALUES (g_contact_mailing.*)
			        END IF

			}

			UPDATE contact_mailing 
			SET address_id = g_address.address_id 
			WHERE address_id = old_address_id 

		END IF 

		###########
	COMMIT WORK 
	###########

	RETURN true #success 


END FUNCTION #store_address() 


##########################
FUNCTION display_address() 
	##########################
	DEFINE 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	IF g_address.address_id IS NULL THEN #to prevent uninitialised dates #from displaying as 31/12/1899 
		INITIALIZE g_address.* TO NULL 
	END IF 
	{
	Since I removed contact_id FROM address table, there IS no concept of
	ownership of the address. FUNCTION get_all_owners should warn IF there
	are multiple users of this address, AND 'list all owners' menu option
	will provide full list AND access

	    if g_contact_address.contact_seed <> g_contact.contact_id THEN
	        CALL get_contact_name(g_contact_address.contact_seed) returning tmp_first, tmp_last

	        ERROR "WARNING ! This address does NOT belong TO current contact"
	            attribute (red)
	        MESSAGE "This address belongs TO ",tmp_first clipped, " ", tmp_last clipped
	            attribute (red)
	    END IF
	}

	CASE current_addr_form 

		WHEN 1 #addresss.per 
			DISPLAY BY NAME 
			g_address.line1, 
			g_address.line2, 
			g_address.street, 
			g_address.suburb, 
			g_address.city, 
			g_address.region, 
			g_address.post_code, 
			g_address.country, 
			g_address.user_defined1, 
			g_address.user_defined2, 
			g_address.user_defined3, 
			g_address.user_defined4, 
			g_address.valid_from, 
			g_address.valid_to 


			DISPLAY all_roles TO s_address.addr_role_name 

			#         WHEN 2 #?.per

		OTHERWISE 

			ERROR "Unknown form: contact_address.4gl, display_address()" 
			SLEEP 5 

			EXIT program 
	END CASE 

END FUNCTION #display_address() 


######################
FUNCTION del_address() 
	######################


	SELECT * FROM contact_mailing 
	WHERE address_id = g_address.address_id 


	IF status <> notfound THEN 
		ERROR "This address IS used in mailings. Cannot delete. Remove mailing first" 
		SLEEP 2 
		RETURN 
	END IF 


	IF is_default_address(g_address.address_id) THEN 
		ERROR "cannot deactivate default address. Use Modify instead" 
		SLEEP 2 
		RETURN 
	END IF 

	IF all_addr_owners_cnt > 1 THEN 
		ERROR "This address IS used by several Contacts. Unbind there ussage of this address first" 
		SLEEP 5 
		RETURN 
	END IF 


	MESSAGE "Mark this addres information as deleted?" 


	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_address","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE address SET 
			valid_to = today 
			WHERE address_id = g_address.address_id 

			UPDATE contact_address SET 
			valid_to = today 
			WHERE address_id = g_address.address_id 
			AND contact_id = g_contact_address.contact_seed 

			CLEAR FORM 
			EXIT MENU 
	END MENU 

	MESSAGE "" 

END FUNCTION #d_address() 


###########################
FUNCTION next_addr_screen() 
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

########################
FUNCTION new_addr_role() 
	########################
	DEFINE 
	new_addr_role_name LIKE role.role_name, 
	new_addr_role_code LIKE role.role_code 


	CALL role_lp("ADDRESS") 
	RETURNING new_addr_role_code, new_addr_role_name 

	# IF Null IS RETURN THEN the users has interrupted
	IF new_addr_role_code IS NOT NULL 
	AND new_addr_role_name IS NOT NULL 
	THEN 
		IF duplicate_addr_role(new_addr_role_code) THEN 
			ERROR "This contact already has an address with this role !" 
			SLEEP 2 
		ELSE 
			INSERT INTO contact_address VALUES 
			(g_contact.contact_id, 
			g_address.address_id, 
			new_addr_role_code, 
			today, 
			"") 

			LET all_roles = get_address_roles(gv_null,false) #address_id, and_hist 
			CALL display_address() 

		END IF 
	END IF 

END FUNCTION #new_addr_role() 

################################################
FUNCTION duplicate_addr_role(new_addr_role_code) 
	################################################
	DEFINE 
	new_addr_role_code LIKE role.role_code, 
	cnt 
	INTEGER 

	LET cnt = 0 

	SELECT count(*) INTO cnt FROM contact_address 
	WHERE contact_id = g_contact.contact_id 
	#            AND
	#            address_id = g_address.address_id
	AND 
	contact_address.role_code = new_addr_role_code 
	AND 
	(valid_to IS NULL OR valid_to > today) 


	IF cnt > 0 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 

################################################
FUNCTION all_address_roles(disp_format,and_exit) 
	################################################
	DEFINE 
	a_contact_address ARRAY [100] OF RECORD 
		contact_id LIKE contact_address.contact_seed, 
		address_id LIKE contact_address.address_id, 
		addr_role_code LIKE contact_address.role_code, 
		valid_from LIKE contact_address.valid_from, 
		valid_to LIKE contact_address.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		addr_role_name LIKE role.role_name, 
		valid_from LIKE contact_address.valid_from, 
		valid_to LIKE contact_address.valid_to, 
		street CHAR (20), #like address.street, 
		suburb CHAR (10), #like address.suburb, 
		city CHAR (10) #like address.city 
	END RECORD, 

	cnt, 
	line_cnt, 
	disp_format, 
	and_exit, 
	changed 
	SMALLINT, 
	new_addr_role_code 
	LIKE role.role_code, 
	new_addr_role_name 
	LIKE role.role_name 


	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_roles with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
			            OPEN WINDOW w_addr_hist
			                AT 12,2     #with 13 rows, 75 columns
			                    WITH FORM "all_role_sml"
			                    attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_all_roles 

	END CASE 

	DECLARE c_all_roles CURSOR FOR 
	SELECT * FROM contact_address 
	WHERE contact_id = g_contact.contact_id 
	ORDER BY valid_from desc 

	LET cnt = 1 

	MESSAGE "Searching FOR all roles, please wait..." 


	################################################
	FOREACH c_all_roles INTO a_contact_address[cnt].* 
		################################################

		LET a_display[cnt].addr_role_name = get_role_name(a_contact_address[cnt].addr_role_code, "ADDRESS") 

		LET a_display[cnt].valid_from = a_contact_address[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_address[cnt].valid_to 

		SELECT street, suburb, city INTO 
		a_display[cnt].street, 
		a_display[cnt].suburb, 
		a_display[cnt].city 
		FROM address WHERE 
		address_id = a_contact_address[cnt].address_id #tmp_address_id 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 

	MESSAGE "" 

	CLOSE c_all_roles 
	FREE c_all_roles 

	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All Address roles FOR this contact" 
	ELSE 
		MESSAGE "All Address roles FOR this contact (SELECT=Accept,F6=change,F7=remove)" 
	END IF 

	LET changed = false 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_address","display_arr-a_display-1") -- albo kd-513 

			###########
		BEFORE ROW 
			{! BEFORE ROW !}
			###########
			IF and_exit THEN 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			###########
		ON KEY (f6) #change role 
			{! ON KEY (f6) !}
			###########

			LET line_cnt = arr_curr() #scr_line() 

			IF a_contact_address[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				ERROR "Must EXIT - FIXME continue display" 
				SLEEP 2 
				CONTINUE DISPLAY 
				{! continue DISPLAY !}
				#Querix:
				#				continue display
				#|________________________^
				#|
				#|   A grammatical error has been found on line 1643, character 26.
				#| The CONSTRUCT IS NOT understandable in its context.
				#|
				#| Check error -4373.
				#|
			END IF 


			CALL role_lp("ADDRESS") 
			RETURNING new_addr_role_code, new_addr_role_name 

			IF new_addr_role_code IS NOT NULL THEN 
				#                LET line_CNT = ARR_CURR()        #SCR_LINE()
				#                #here this returns WRONG line (FROM previous L&P SCREEN !!!)
				#               error a_contact_address[line_cnt].addr_role_code,a_display[line_cnt].addr_role_name sleep 5
				#                error new_addr_role_code,new_addr_role_name sleep 5
				#               error line_cnt sleep 5


				IF change_addr_role 
				( false, new_addr_role_code, new_addr_role_name, a_contact_address[line_cnt].contact_id, a_contact_address[line_cnt].address_id, a_contact_address[line_cnt].addr_role_code) THEN 
					LET changed = true 
					EXIT DISPLAY 
					{! EXIT DISPLAY !}
				END IF 
			END IF 

			########################
		ON KEY (f7) #remove role 
			{!  ON KEY (f7) !}
			########################
			LET line_cnt = arr_curr() #scr_line() 
			IF a_contact_address[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				ERROR "Must EXIT - FIXME continue display" 
				SLEEP 2 
				#Querix:
				#                continue display
				#|________________________^
				#|
				#|   A grammatical error has been found on line 1684, character 26.
				#| The CONSTRUCT IS NOT understandable in its context.
				#|
				#| Check error -4373.
				#|
			END IF 

			IF change_addr_role 
			( true, gv_null, gv_null, a_contact_address[line_cnt].contact_id, a_contact_address[line_cnt].address_id, a_contact_address[line_cnt].addr_role_code) THEN 
				LET changed = true 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 

			###########
	END DISPLAY 
	{! END DISPLAY !}
	###########

	LET cnt = arr_curr() #scr_line() 

	MESSAGE "" 

	CASE disp_format 
		WHEN 1 #big new WINDOW 
			CLOSE WINDOW w_all_roles 

		WHEN 2 
			#            DISPLAY FORM f_address1
			#            CALL display_address()
	END CASE 

	IF changed THEN 
		LET all_roles = 
		get_address_roles(a_contact_address[cnt].address_id,FALSE) #address_id,and_hist 
	END IF 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	#    LET CNT = ARR_CURR()        #SCR_LINE()

	RETURN a_contact_address[cnt].address_id 

END FUNCTION #all_address_roles() 

#####################################################################
FUNCTION change_addr_role(and_remove,new_addr_role_code,new_addr_role_name, 
	p_contact_id,p_address_id,p_addr_role_code) 
	#####################################################################
	DEFINE 
	changed, 
	tmp_cnt, 
	and_remove 
	SMALLINT, 
	new_addr_role_code, 
	p_addr_role_code 
	LIKE role.role_code, 
	new_addr_role_name 
	LIKE role.role_name, 
	p_contact_id 
	LIKE contact.contact_id, 
	p_address_id 
	LIKE address.address_id 


	IF and_remove THEN 
		MESSAGE "Do you realy want TO remove selected role ?" 
		attribute (red) 
	ELSE 
		IF duplicate_addr_role(new_addr_role_code) THEN 
			ERROR "This contact already has an address with this role !" 
			SLEEP 2 
			RETURN false 
		END IF 

		MESSAGE "Do you realy want TO change selected role TO ", 
		new_addr_role_name clipped, " ?" 
		attribute (red) 
	END IF 


	MENU "Change role" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_address","menu-Change_role-1") -- albo kd-513 

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
				UPDATE contact_address 
				SET valid_to = today 
				WHERE contact_id = p_contact_id 
				AND address_id = p_address_id 
				AND role_code = p_addr_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact address: aborted !" 
					SLEEP 5 
					LET changed = false 
				ELSE 
					LET changed = true 
				END IF 

				SELECT count (*) INTO tmp_cnt 
				FROM contact_address 
				WHERE address_id = p_address_id 
				AND (valid_to IS NULL OR valid_to > today) 


				IF tmp_cnt = 0 THEN # no valid relations TO this address FROM any contact 
					UPDATE address 
					SET valid_to = today 
					WHERE address_id = p_address_id 
				END IF 

			ELSE #change 
				{
				    if do_debug THEN
				        CALL errorlog(p_contact_id)
				        CALL errorlog(p_address_id)
				        CALL errorlog(p_addr_role_code)
				        CALL errorlog(new_addr_role_code)
				    END IF
				}
				UPDATE contact_address 
				SET role_code = new_addr_role_code 
				WHERE contact_id = p_contact_id 
				AND address_id = p_address_id 
				AND role_code = p_addr_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact address: aborted !" 
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

END FUNCTION #change_addr_role() 

####################################################
FUNCTION address_hist(disp_format,and_exit,and_hist) 
	####################################################
	DEFINE 
	a_address ARRAY [100] OF RECORD 
		address_id LIKE address.address_id, 
		#       contact_id LIKE address.contact_id,
		line1 LIKE address.line1, 
		line2 LIKE address.line2, 
		street LIKE address.street, 
		suburb LIKE address.suburb, 
		city LIKE address.city, 
		region LIKE address.region, 
		post_code LIKE address.post_code, 
		country LIKE address.country, 
		user_defined1 LIKE address.user_defined1, 
		user_defined2 LIKE address.user_defined2, 
		user_defined3 LIKE address.user_defined3, 
		user_defined4 LIKE address.user_defined4, 
		valid_from LIKE address.valid_from, 
		valid_to LIKE address.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		addr_role_name LIKE role.role_name, 
		valid_from LIKE contact_address.valid_from, 
		valid_to LIKE contact_address.valid_to, 
		street CHAR (20), #like address.street, 
		suburb CHAR (10), #like address.suburb, 
		city CHAR (10) #like address.city 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	and_hist 
	SMALLINT, 
	where_part 
	CHAR(400) 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_addr_hist with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
			            OPEN WINDOW w_addr_hist
			                AT 12,2     #with 13 rows, 75 columns
			                    WITH FORM "all_role_sml"
			                    attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_addr_hist 

	END CASE 


	LET where_part = 
	"SELECT unique address.* FROM contact_address, address ", 
	" WHERE contact_address.contact_seed = ",g_contact.contact_id, 
	" AND contact_address.address_id = address.address_id " 


	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" AND (address.valid_to IS NULL OR address.valid_to >= today) " 

	END IF 

	LET where_part = where_part clipped, 
	" ORDER BY address.valid_to desc " 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 


	PREPARE xx1 FROM where_part 
	DECLARE c_addr_hist CURSOR FOR xx1 


	LET cnt = 1 

	MESSAGE "Searching FOR history data, please wait..." 


	#########################################
	FOREACH c_addr_hist INTO a_address[cnt].* 
		#########################################

		LET a_display[cnt].addr_role_name = get_address_roles(a_address[cnt].address_id,and_hist) 

		LET a_display[cnt].valid_from = a_address[cnt].valid_from 
		LET a_display[cnt].valid_to = a_address[cnt].valid_to 

		LET a_display[cnt].street = a_address[cnt].street 
		LET a_display[cnt].suburb = a_address[cnt].suburb 
		LET a_display[cnt].city = a_address[cnt].city 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 

	MESSAGE "" 

	CLOSE c_addr_hist 
	FREE c_addr_hist 

	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All Addresses FOR this contact" 
	ELSE 
		MESSAGE "All Addresses FOR this contact - SELECT AND press Accept" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_address","display_arr-a_display-2") -- albo kd-513 

		BEFORE ROW 
			IF and_exit THEN 
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

			CLOSE WINDOW w_addr_hist 
		WHEN 2 
			#            DISPLAY FORM f_address1
			#            CALL display_address()
	END CASE 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_address[cnt].address_id 

END FUNCTION #address_hist() 

#########################################
FUNCTION get_contact_address(p_address_id) 
	#########################################
	DEFINE 
	pr_address RECORD LIKE address.*, 
	p_address_id LIKE address.address_id 


	SELECT * INTO pr_address.* 
	FROM address 
	WHERE address_id = p_address_id 


	RETURN pr_address.* 

END FUNCTION #get_contact_address 


##########################################################
FUNCTION get_address_for_contact(p_contact_id,p_role_name) 
	##########################################################
	DEFINE 
	p_contact_id LIKE contact.contact_id, 
	p_role_name LIKE role.role_name, 
	pr_address RECORD LIKE address.* 

	SELECT unique address.* INTO pr_address.* 
	FROM address, contact_address, role 
	WHERE 
	contact_address.address_id = address.address_id 
	AND 
	contact_address.contact_seed = p_contact_id 
	AND 
	contact_address.role_code = role.role_code 
	AND 
	role.role_name = p_role_name 
	AND 
	role.class_name = "ADDRESS" 
	AND 
	(contact_address.valid_to IS NULL OR contact_address.valid_to > today) 
	AND 
	(address.valid_to IS NULL OR address.valid_to > today) 

	IF status = notfound THEN 
		INITIALIZE pr_address.* TO NULL 
	END IF 

	RETURN pr_address.* 

END FUNCTION #get_addres_for_contact 


###################################################
FUNCTION is_default_address(p_address_id) 
	###################################################
	DEFINE 
	p_address_id LIKE address.address_id, 
	tmp_role_code LIKE role.role_code 

	LET tmp_role_code = get_role_code("DEFAULT","ADDRESS") 

	SELECT * FROM contact_address 
	WHERE role_code = tmp_role_code 
	AND address_id = p_address_id 
	AND contact_id = g_contact.contact_id 


	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 


END FUNCTION #is_default_address() 


#########################################
FUNCTION get_address_owners(any_contact) 
	#########################################
	DEFINE 
	any_contact, 
	cnt, 
	tmp_one_role 
	SMALLINT 

	LET query_1 = 
	"SELECT ", 
	#" unique ",
	" contact_id ", #, address_id,role_code,valid_from,valid_to ", 
	" FROM contact_address ", 
	" WHERE contact_address.address_id = ",g_address.address_id, 
	" group by contact_address.contact_seed" 

	PREPARE x_stmt FROM query_1 
	DECLARE c_cntct CURSOR FOR x_stmt 

	LET cnt = 1 

	MESSAGE "Searching FOR owners, please wait..." 

	######################################################
	FOREACH c_cntct INTO a_all_addr_owners[cnt].contact_id #* 
		######################################################

		IF a_all_addr_owners[cnt].contact_id = g_contact.contact_id THEN 
			LET tmp_one_role = get_one_addr_role(g_address.address_id,a_all_addr_owners[cnt].contact_id) 

			SELECT * INTO g_contact_address.* 
			FROM contact_address 
			WHERE contact_address.address_id = g_address.address_id 
			AND contact_address.contact_seed = a_all_addr_owners[cnt].contact_id 
			AND contact_address.role_code = tmp_one_role 

			#LET g_contact_address.* = a_all_owners[cnt].*
		ELSE 
			IF any_contact THEN 
				LET tmp_one_role = get_one_addr_role(g_address.address_id,a_all_addr_owners[cnt].contact_id) 

				SELECT * INTO g_contact_address.* 
				FROM contact_address 
				WHERE contact_address.address_id = g_address.address_id 
				AND contact_address.contact_seed = a_all_addr_owners[cnt].contact_id 
				AND contact_address.role_code = tmp_one_role 
				AND valid_to IS NULL OR valid_to > today 


			END IF 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_cntct 
	FREE c_cntct 

	MESSAGE "" 

	LET all_addr_owners_cnt = cnt - 1 

	IF all_addr_owners_cnt > 1 THEN 
		MESSAGE "WARNING: This address belongs TO ", 
		all_addr_owners_cnt USING "##&", 
		" Contacts !" 
		attribute (red) 
		ERROR "WARNING: This address belongs TO multiple Contacts !" 
		attribute (red) 
		SLEEP 1 
	END IF 

END FUNCTION #get_address_owners() 


##############################################
FUNCTION list_all_addr_owners(tmp_address_id) 
	##############################################
	DEFINE 
	tmp_address_id LIKE address.address_id, 
	a_names array[40] OF RECORD 
		NAME CHAR(15) 
	END RECORD, 
	cnt 
	SMALLINT, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	tmp_name CHAR(100) 



	OPEN WINDOW w_allownaddr_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	MESSAGE "SELECT AND press Accept" 

	##################################
	FOR cnt = 1 TO all_addr_owners_cnt 
		##################################

		CALL get_contact_name(a_all_addr_owners[cnt].contact_id) 
		RETURNING tmp_first, tmp_last 

		IF length (tmp_first) > 0 THEN 
			LET tmp_name = tmp_first clipped, " ", tmp_last clipped 
		ELSE 
			LET tmp_name = tmp_last clipped 
		END IF 

		LET a_names[cnt].name = tmp_name [1,15] 

		#######
	END FOR 
	#######

	CALL set_count(all_addr_owners_cnt) 

	DISPLAY ARRAY a_names TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_address","display_arr-a_names-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 

	LET cnt = arr_curr() #scr_line() 

	CLOSE WINDOW w_allownaddr_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	RETURN a_all_addr_owners[cnt].contact_id 


END FUNCTION #list_all_addr_owners() 

################################################
FUNCTION show_addr(addr_id) 
	################################################
	DEFINE 
	addr_id LIKE contact_mailing.address_id, 
	dummy_char CHAR(1), 
	store_show_valid SMALLINT 
	{
	    OPEN WINDOW w_addr  -- albo  KD-766
	        AT 12,2 with 13 rows, 75 columns
	            attribute (border)
	}
	DISPLAY FORM f_address1 
	LET current_addr_form = 1 
	LET store_show_valid = show_valid 
	LET show_valid = false 


	#    error addr_id sleep 3
	CALL disp_selected_addr(addr_id) 
	LET show_valid = store_show_valid 

	PROMPT "Press a key TO continue" FOR CHAR dummy_char 
	#    DISPLAY FORM f_contact_mailings
	--    CLOSE WINDOW w_addr  -- albo  KD-766

END FUNCTION #show_addr() 


###############################################################
FUNCTION select_address(restrict_contact_id,current_address_id) 
	###############################################################
	DEFINE 
	restrict_contact_id 
	LIKE contact.contact_id, 
	selected_address_id, 
	current_address_id 
	LIKE address.address_id, 
	where_part 
	CHAR (800), 
	send1, send2, send3, send4 #where_part 
	CHAR (200), 
	save_contact_address 
	RECORD LIKE contact_address.*, 
		save_address 
		RECORD LIKE address.* 


			LET save_contact_address.* = g_contact_address.* 
			LET save_address.* = g_address.* 


			#IF we OPEN a new window in the upper part of the SCREEN, since the
			#upper window IS smaller THEN the lower, NOT all fields will be
			#wisible, so we we need TO OPEN a new window over existing lower window:
			{
			            OPEN WINDOW w_addr_select
			                AT 2,2 with 9 rows, 75 columns
			                    attribute (border)
			}


			LET g_msg = "You are Selecting a new ADDRESS TO be used by ", 
			g_contact.first_name clipped , " ", 
			g_contact.last_org_name clipped 

			MESSAGE g_msg attribute (red) 
			#MESSAGE displayed in upper window
			{
			    OPEN WINDOW w_addr_select  -- albo  KD-766
			        AT 12,2 with 13 rows, 75 columns
			            attribute (border)
			}

			LABEL start_here: 


			#            CALL clear_info()
			#            CURRENT WINDOW IS w_contact

			DISPLAY FORM f_address1 

			OPTIONS MESSAGE line FIRST + 1 
			MESSAGE g_msg attribute (red) 
			OPTIONS MESSAGE line FIRST 

			#MESSAGE displayed in lower window



			MESSAGE "" 


			CALL qbe_address(true) #any_contact 
			RETURNING send1, send2, send3 #, send4 
			CALL addr_where_part(send1, send2, send3, true) 
			RETURNING send1, send2, send3 


			IF send1 IS NULL THEN 
				LET int_flag = false 
				--                CLOSE WINDOW w_addr_select  -- albo  KD-766
				RETURN gv_null 
			ELSE 

				LET where_part = send1, send2, send3, send4 

				LET where_part = where_part clipped, 
				" AND contact_address.contact_seed <> ", restrict_contact_id, 
				" AND contact_address.address_id = address.address_id " 


				LET send1 = where_part[1,200] 
				LET send2 = where_part[201,400] 
				LET send3 = where_part[401,600] 
				#                LET send4 = where_part[601,800]


				IF open_addr_cursor(send1, send2, send3, true) THEN #any_contact 
					#CALL contact_info("1")

					MESSAGE g_msg attribute (red) 

					MENU "SELECT new address FOR Contact" 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","contact_address","menu-SELECT_new_address_role-1") -- albo kd-513 

						ON ACTION "WEB-HELP" -- albo 
							CALL onlinehelp(getmoduleid(),null) 


						COMMAND "+" "Next found" 
							MESSAGE"" 
							CURRENT WINDOW IS w_addr_select 
							IF n_address(true) THEN #any_contact THEN 
								#CALL contact_info("1")
							END IF 

						COMMAND "-" "Previous found" 
							MESSAGE"" 
							CURRENT WINDOW IS w_addr_select 
							IF p_address(true) THEN #any_contact 
								#CALL contact_info("1")
							END IF 

						COMMAND "SELECT" "SELECT current address TO be used FOR Contact" 
							LET selected_address_id = g_address.address_id 
							EXIT MENU 

						COMMAND "Quit" "Quit selection without selecting new address" 
							INITIALIZE selected_address_id TO NULL 
							EXIT MENU 

					END MENU 
				ELSE 
					ERROR "No records foud; Try again, OR SELECT CTRL+C AND THEN Quit" 
						SLEEP 2 
						GOTO start_here 
					END IF 
				END IF 

				IF current_address_id IS NOT NULL THEN #restore global records 
					        {
					        SELECT * INTO g_address.*
					            FROM address
					                WHERE address.address_id = current_address_id
					        }

					LET g_address.* = save_address.* 
					LET g_contact_address.* = save_contact_address.* 

				END IF 

				#    CALL get_codes()
				#    CALL display_contact()

				--    CLOSE WINDOW w_addr_select  -- albo  KD-766

				RETURN selected_address_id 

END FUNCTION #select_address() 


###################################################### module end
