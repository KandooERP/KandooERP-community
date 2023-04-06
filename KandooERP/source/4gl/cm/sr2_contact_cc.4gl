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
 * contact credit card functions
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

#######################
FUNCTION cc_menu() 
	#######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success 
	SMALLINT, 
	cc_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	any_contact 
	SMALLINT 


	MESSAGE"" 
	CALL init_cc() 

	CURRENT WINDOW IS w_contact 

	MENU "Credit Card" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_cc","menu-Credit_Card-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query by credit card data" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET any_contact = false 
			CALL qbe_cc(any_contact) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_cc_cursor(send1, send2, send3,any_contact) 
			END IF 

		COMMAND "+" "Next found" 
			MESSAGE"" 
			CALL init_cc_win() 
			CALL n_cc(any_contact) 

		COMMAND "-" "Previous found" 
			MESSAGE"" 
			CALL init_cc_win() 
			CALL p_cc(any_contact) 

		COMMAND "Add" "Add new credit card number FOR this contact" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET success = au_contact_cc(g_contact.contact_id,true) #add_mode 

		COMMAND "Edit" "Modify current credit card" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET success = au_contact_cc(g_contact.contact_id,false) #add_mode 

		COMMAND "New role" "Add a new role FOR this credit card" 
			MESSAGE"" 
			CALL init_cc_win() 
			CALL new_cc_role() 

		COMMAND "Change role" "Change roles FOR this credit card" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET cc_id = all_cc_roles(2,false) 
			DISPLAY FORM f_cc1 
			CALL display_cc() 
			IF 
			cc_id IS NOT NULL 
			THEN 
				CALL disp_selected_cc(cc_id) 
			END IF 


		COMMAND KEY ("r","R") "all Roles" "DISPLAY all role AND credit card info on this contact, including history" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET cc_id = all_cc_roles(2,false) 
			DISPLAY FORM f_cc1 
			CALL display_cc() 
			IF 
			cc_id IS NOT NULL 
			THEN 
				CALL disp_selected_cc(cc_id) 
			END IF 

		COMMAND "History" "DISPLAY all historycal credit card info" 
			MESSAGE"" 
			CALL init_cc_win() 
			LET cc_id = cc_hist("2",FALSE) 
			DISPLAY FORM f_cc1 
			CALL display_cc() 
			CALL disp_selected_cc(cc_id) 

		COMMAND "Delete" "Delete current credit card" 
			MESSAGE"" 
			CALL init_cc_win() 
			CALL del_cc() 

		COMMAND KEY ("y","Y") "anY credit card" "Query FOR any contact credit card data" 
			MESSAGE "" 
			CALL init_cc_win() 
			LET any_contact = true 
			CALL qbe_cc(any_contact) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_cc_cursor(send1, send2, send3,any_contact) 
			END IF 


		COMMAND "Switch" "Switch current contact TO the one that the displayed CC belongs TO" 

			IF g_credit_card.contact_id <> g_contact.contact_id THEN 
				CALL get_contact_name(g_credit_card.contact_id) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_cc","menu-Switch-1") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current CC belongs TO" 
						MESSAGE "" 
						CALL switch_contact(g_credit_card.contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This credit card belongs TO the current contact: Cannot switch" 
			END IF 

			#        COMMAND "Screen" "Show next SCREEN of current cc data"
			#            CALL next_cc_screen()

		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #cc_menu() 

####################################
FUNCTION disp_selected_cc(cc_id) 
	####################################
	DEFINE 
	cc_id 
	SMALLINT, 
	send1, send2, send3 #where_part 
	CHAR (200) 


	IF cc_id IS NOT NULL THEN 
		LET send1 = " credit_card.cc_id = ", cc_id 
		INITIALIZE send2, send3 TO NULL 

		CALL cc_where_part(send1, send2, send3,false) #any_contact 
		RETURNING send1, send2, send3 

		CALL open_cc_cursor(send1, send2, send3,false) #any_contact 
	END IF 
END FUNCTION 


######################
FUNCTION init_cc() 
	######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	#already opmen FOR Info !
	#	OPEN WINDOW w_cc
	#        AT 12,2 with 13 rows, 75 columns
	#			attribute (border)


	CALL init_cc_win() 

	# We want TO get all Credit Cards FOR a contact NOT
	# just the DEFAULT
	#	LET send1 = " role.role_name = 'DEFAULT' ",
	#                " AND role.class_name = 'CREDIT CARD' ",
	#                " AND role.role_code = contact_cc.role_code ",
	#		        " AND contact_cc.contact_id = ", g_contact.contact_id, " "

	LET send1 = " contact_cc.contact_id = ", g_contact.contact_id, " " 

	INITIALIZE send2, send3 TO NULL 

	CALL cc_where_part(send1, send2, send3,false) 
	RETURNING send1, send2, send3 

	CALL open_cc_cursor(send1, send2, send3,false) 

	MESSAGE "Default Credit Card number:" 

END FUNCTION #init_cc() 

######################
FUNCTION init_cc_win() 
	######################

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_cc1 

	LET current_cc_form = 1 

END FUNCTION 

############################
FUNCTION qbe_cc(any_contact) 
	############################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	tmp_cc_role_name, tmp_name 
	LIKE role.role_name, 
	tmp_cc_type_name 
	LIKE cc_type.cc_type_name, 
	any_contact 
	SMALLINT 

	IF current_cc_form <> 1 THEN 
		CALL d_cc1() 
	END IF 

	MESSAGE "Enter the query conndition AND press Accept" 


	CONSTRUCT where_part ON 

	cc_type.cc_type_name, 
	role.role_name, 
	credit_card.cc_no, 
	credit_card.cc_expire, 
	credit_card.valid_from, 
	credit_card.valid_to 

	FROM 
	s_cc.cc_type_name, 
	s_cc.cc_role_name, 
	s_cc.cc_no, 
	s_cc.cc_expire, 
	s_cc.valid_from, 
	s_cc.valid_to 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact_cc","construct-credit_card-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############################
		AFTER FIELD cc_role_name 
			############################
			LET tmp_cc_role_name = get_fldbuf(cc_role_name) 

			IF 
			tmp_cc_role_name IS NOT NULL 
			AND 
			length (tmp_cc_role_name) > 0 
			THEN 
				LET tmp_name = get_fldbuf(cc_role_name) 

				SELECT * FROM role 
				WHERE role_name = tmp_name 
				AND class_name = "CREDIT CARD" 

				IF status = notfound THEN 
					ERROR "This role IS NOT defined" 
					NEXT FIELD cc_role_name 

				END IF 
			ELSE 
				LET tmp_name = "DEFAULT" 
				DISPLAY tmp_name TO s_cc.cc_role_name 
			END IF 

			############################
		AFTER FIELD cc_type_name 
			############################
			LET tmp_cc_type_name = get_fldbuf(cc_type_name) 

			IF 
			tmp_cc_type_name IS NOT NULL 
			AND 
			length (tmp_cc_type_name) > 0 
			THEN 
				LET tmp_name = get_fldbuf(cc_type_name) 

				SELECT * FROM cc_type 
				WHERE cc_type_name = tmp_name 

				IF status = notfound THEN 
					ERROR "This type IS NOT defined" 
					NEXT FIELD cc_type_name 

				END IF 
			ELSE 
				#LET tmp_name = "DEFAULT"
				#DISPLAY tmp_name TO s_cc.cc_role_name
			END IF 


			#############
	END CONSTRUCT 
	#############


	MESSAGE "" 

	IF NOT any_contact THEN 
		LET where_part = where_part clipped, 
		" AND contact_cc.contact_id = ", g_contact.contact_id, " " 
	END IF 


	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	CALL cc_where_part(send1, send2, send3, any_contact) 
	RETURNING send1, send2, send3 

	#    LET last_cc_where_part = where_part

	RETURN send1, send2, send3 #where_part 

END FUNCTION #q_cc() 


####################
FUNCTION d_cc1() 
	####################

	DISPLAY FORM f_cc1 
	LET current_cc_form = 1 
	CALL display_cc() 

END FUNCTION 

######################################
FUNCTION get_cc_roles(tmp_cc_id,and_hist) 
	######################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt, 
	and_hist 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 
	tmp_cc_id 
	LIKE credit_card.cc_id, 
	where_part 
	CHAR (300) 


	IF tmp_cc_id IS NULL 
	THEN 
		LET tmp_cc_id = g_credit_card.cc_id 
	END IF 


	LET where_part = 
	" SELECT unique role_code FROM contact_cc ", 
	" WHERE cc_id = ", tmp_cc_id, 
	" AND contact_id = ", g_contact.contact_id 

	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" AND (valid_to IS NULL OR valid_to > today )" 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE xde44 FROM where_part 
	DECLARE c_cc_roles CURSOR FOR xde44 


	INITIALIZE all_roles TO NULL 

	LET cnt = 1 

	############################################
	FOREACH c_cc_roles INTO a_role_codes[cnt] 
		############################################

		LET tmp_role_name = get_role_name(a_role_codes[cnt], "CREDIT CARD") 

		IF cnt = 1 THEN 
			LET all_roles = tmp_role_name 
		ELSE 
			LET all_roles = all_roles clipped,", ", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_cc_roles 
	FREE c_cc_roles 
	MESSAGE "" 
	RETURN all_roles 

END FUNCTION #get_cc_roles() 

#######################################################
FUNCTION cc_where_part(send1, send2, send3,any_contact) 
	#######################################################
	DEFINE 
	where_part, 
	received_where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT 

	LET received_where_part = send1, send2, send3 

	LET where_part = "SELECT unique credit_card.* ", 
	#" , contact_cc.* ",
	" FROM credit_card, contact_cc " 

	IF received_where_part matches "*role.role_name*" THEN 
		LET where_part = where_part clipped, 
		", role " 
	END IF 

	IF received_where_part matches "*cc_type.cc_type_name*" THEN 
		LET where_part = where_part clipped, 
		", cc_type " 
	END IF 


	LET where_part = where_part clipped, 
	" WHERE ", received_where_part clipped, 
	#        " AND contact_cc.contact_id = ", g_contact.contact_id,
	" AND contact_cc.cc_id = credit_card.cc_id " 


	IF 
	received_where_part matches "*role.role_name*" 
	THEN 
		LET where_part = where_part clipped, 
		" AND role.role_code = contact_cc.role_code ", 
		" AND role.class_name = 'CREDIT CARD' " 
	END IF 

	IF 
	received_where_part matches "*cc_type.cc_type_name*" 
	THEN 
		LET where_part = where_part clipped, 
		" AND cc_type.cc_type_code = credit_card.cc_type_code " 
	END IF 


	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	RETURN send1, send2, send3 #where_part 

END FUNCTION #cc_where_part() 


########################################################
FUNCTION open_cc_cursor(send1, send2, send3,any_contact) 
	########################################################
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
		" AND (contact_cc.valid_to IS NULL OR contact_cc.valid_to > TODAY)", 
		" AND (credit_card.valid_to IS NULL OR credit_card.valid_to > TODAY)" 

	END IF 

	#    LET where_part = where_part clipped," group by credit_card.cc_id, credit_card.contact_id ... line1 etc must be in group by "

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE xc2 FROM where_part 
	DECLARE c_read_cc SCROLL CURSOR with HOLD FOR xc2 
	OPEN c_read_cc 

	FETCH FIRST c_read_cc INTO g_credit_card.* #, g_contact_cc.* 

	IF 
	status = notfound 
	THEN 
		MESSAGE "" 
		ERROR "No records found" 
		INITIALIZE g_credit_card.* TO NULL 
	ELSE 
		MESSAGE "" 
		LET all_roles = get_cc_roles(gv_null,show_history) 
		LET c_credit_card.cc_type_name = get_cc_type(g_credit_card.cc_type_code) 
		CALL display_cc() 
	END IF 

END FUNCTION #open_cc_cursor() 

##########################
FUNCTION n_cc(any_contact) 
	##########################
	DEFINE 
	any_contact 
	SMALLINT 

	IF 
	g_credit_card.cc_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 

	FETCH NEXT c_read_cc INTO g_credit_card.* #, g_contact_cc.* 

	IF 
	status = notfound 
	THEN 
		CALL display_cc() 
		ERROR "No more records found" 
	ELSE 
		LET all_roles = get_cc_roles(gv_null,show_history) 
		LET c_credit_card.cc_type_name = get_cc_type(g_credit_card.cc_type_code) 
		CALL display_cc() 
	END IF 

END FUNCTION #n_cc() 

##########################
FUNCTION p_cc(any_contact) 
	##########################
	DEFINE 
	any_contact 
	SMALLINT 

	IF 
	g_credit_card.cc_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 


	FETCH previous c_read_cc INTO g_credit_card.* #, g_contact_cc.* 
	IF status = notfound THEN 
		CALL display_cc() 
		ERROR "No previous records found" 
	ELSE 
		LET all_roles = get_cc_roles(gv_null,show_history) 
		LET c_credit_card.cc_type_name = get_cc_type(g_credit_card.cc_type_code) 
		CALL display_cc() 
	END IF 

END FUNCTION #p_cc() 


####################################################
FUNCTION au_contact_cc(tmp_contact_id,add_mode) 
	####################################################
	DEFINE 
	tmp_contact_id LIKE contact.contact_id, 
	p_cc_role_name, new_cc_role_name LIKE role.role_name, 
	new_cc_role_code LIKE role.role_code, 
	new_cc_type_code LIKE cc_type.cc_type_code, 
	p_cc_type_name, new_cc_type_name LIKE cc_type.cc_type_name, 

	add_mode, 
	success 
	SMALLINT, 
	store_cc RECORD LIKE credit_card.*, 
	store_contact_cc RECORD LIKE contact_cc.*, 

	store_c_credit_card RECORD 
		cc_type_name LIKE cc_type.cc_type_name, 
		cc_role_name LIKE role.role_name 
	END RECORD 


	IF current_cc_form <> 1 THEN 
		CALL d_cc1() 
	END IF 

	IF add_mode THEN 
		INITIALIZE g_credit_card TO NULL 
		INITIALIZE g_contact_cc TO NULL 
		CLEAR FORM 
		MESSAGE "Enter new credit card data AND press Accept" 
	ELSE 
		LET store_cc.* = g_credit_card.* 
		LET store_contact_cc.* = g_contact_cc.* 
		LET store_c_credit_card.* = c_credit_card.* 
		MESSAGE "Enter changes AND press Accept" 
	END IF 

	#############
	INPUT 
	#############

	c_credit_card.cc_type_name, 
	c_credit_card.cc_role_name, 
	g_credit_card.cc_no, 
	g_credit_card.cc_expire, 
	g_credit_card.valid_from, 
	g_credit_card.valid_to 

	WITHOUT DEFAULTS FROM 

	s_cc.cc_type_name, 
	s_cc.cc_role_name, 
	s_cc.cc_no, 
	s_cc.cc_expire, 
	s_cc.valid_from, 
	s_cc.valid_to 

	############
		BEFORE INPUT 
			############
			CALL publish_toolbar("kandoo","contact_cc","input-c_credit_card-1") -- albo kd-513 
			IF NOT add_mode THEN 
				DISPLAY all_roles TO s_cc.cc_role_name 
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############
		ON KEY (f10) 
			############

			####
			CASE 
			####
			##########################
				WHEN infield(cc_role_name) 
					##########################

					CALL role_lp("CREDIT CARD") 
					RETURNING new_cc_role_code, new_cc_role_name 

					IF new_cc_role_code IS NOT NULL THEN 
						LET p_cc_role_name = new_cc_role_name 
						LET c_credit_card.cc_role_name = new_cc_role_name 
						LET g_contact_cc.role_code = new_cc_role_code 
						DISPLAY p_cc_role_name TO cc_role_name 
					END IF 

					##########################
				WHEN infield(cc_type_name) 
					##########################

					CALL cc_type_lp() 
					RETURNING new_cc_type_code, new_cc_type_name 

					IF new_cc_type_code IS NOT NULL THEN 
						LET p_cc_type_name = new_cc_type_name 
						LET c_credit_card.cc_type_name = new_cc_type_name 
						LET g_credit_card.cc_type_code = new_cc_type_code 
						DISPLAY p_cc_type_name TO cc_type_name 
					END IF 

					########
			END CASE 
			########

			#########################
		BEFORE FIELD cc_role_name 
			#########################

			IF NOT add_mode THEN 
				NEXT FIELD NEXT 
			END IF 


			########################
		AFTER FIELD cc_role_name 
			########################

			IF p_cc_role_name IS NOT NULL AND 
			add_mode 
			THEN 

				LET g_contact_cc.role_code = get_role_code(p_cc_role_name, "CREDIT CARD") 

				IF g_contact_cc.role_code IS NULL THEN 

					CALL role_lp("CREDIT CARD") 
					RETURNING new_cc_role_code, new_cc_role_name 

					IF new_cc_role_code IS NULL THEN 
						LET p_cc_role_name = "DEFAULT" 

						LET g_contact_cc.role_code = get_default_code("CREDIT CARD") 

					ELSE 
						LET g_contact_cc.role_code = new_cc_role_code 
						LET p_cc_role_name = new_cc_role_name 
					END IF 
				ELSE 

					IF duplicate_cc_role(new_cc_role_code) 
					AND add_mode THEN 
						ERROR "This contact already have credit card with this role !" 
						SLEEP 2 
						NEXT FIELD cc_role_name 

					END IF 
				END IF 

				DISPLAY p_cc_role_name TO cc_role_name 

			END IF 

			######################
		AFTER FIELD valid_from 
			######################
			IF g_credit_card.valid_from IS NULL THEN 
				LET g_credit_card.valid_from = today 
				DISPLAY BY NAME g_credit_card.valid_from 
			END IF 

			###########
		AFTER INPUT 
			###########

			IF int_flag THEN 
				EXIT INPUT 
			END IF 


			LET g_contact_cc.contact_id = g_contact.contact_id 
			LET g_contact_cc.valid_from = today 

			#LET g_credit_card.cc_id = 0
			LET g_credit_card.valid_from = today 

			IF p_cc_role_name IS NULL 
			OR length (p_cc_role_name) < 1 THEN 
				LET p_cc_role_name = "DEFAULT" 

				LET g_contact_cc.role_code = get_default_code("CREDIT CARD") 

			END IF 
			IF duplicate_cc_role(g_contact_cc.role_code) 
			AND add_mode THEN 
				ERROR "This contact already have CC with DEFAULT role. Please SELECT another role !" 
				SLEEP 2 
				NEXT FIELD cc_role_name 

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

		g_credit_card.cc_type_code = store_cc.cc_type_code 

		AND 
		g_credit_card.cc_no = store_cc.cc_no 
		AND 
		g_credit_card.cc_expire = store_cc.cc_expire 
		AND 
		g_credit_card.valid_from = store_cc.valid_from 
		AND 
		g_credit_card.valid_to = store_cc.valid_to 
		AND 

		store_c_credit_card.cc_role_name = c_credit_card.cc_role_name 

		THEN 
			ERROR "Nothhing changed: nothing TO UPDATE" 
			RETURN false 
		END IF 
	END IF 

	LET success = f_store_cc(add_mode) 

	RETURN success 

END FUNCTION #au_contact_cc() 


###############################
FUNCTION f_store_cc(add_mode) 
	###############################
	DEFINE 
	add_mode 
	SMALLINT, 
	old_cc_id 
	INTEGER 

	LET old_cc_id = g_credit_card.cc_id 

	##########
	BEGIN WORK 
		##########

		IF NOT add_mode THEN #logical UPDATE 

			#first, close previous record
			UPDATE credit_card SET 
			valid_to = today 
			WHERE cc_id = old_cc_id 

			IF status <> 0 THEN 
				ERROR "Cannot close previous record: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

		END IF 

		LET g_credit_card.contact_id = g_contact.contact_id 
		LET g_credit_card.cc_id = 0 
		LET g_credit_card.valid_from = today 
		#LET g_contact.mod_user_id = glob_rec_kandoouser.sign_on_code


		################################################
		INSERT INTO credit_card VALUES (g_credit_card.*) 
		################################################

		IF 
		status <> 0 
		THEN 
			ERROR "Cannot INSERT new record: Update/Add aborted !" 
			SLEEP 5 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		LET g_credit_card.cc_id = sqlca.sqlerrd[2] 


		IF 
		########
		add_mode 
		########
		THEN 

			LET g_contact_cc.cc_id = g_credit_card.cc_id 

			INSERT INTO contact_cc VALUES (g_contact_cc.*) 

			IF status <> 0 THEN 
				ERROR "Cannot add contact credit card: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 
			####
		ELSE #logical UPDATE 
			####        #
			{
					SELECT * INTO g_contact_cc.*
			            FROM contact_cc
			                WHERE cc_id = old_cc_id

					UPDATE contact_cc
			            SET valid_to =  today
			                WHERE cc_id = old_cc_id


					LET g_contact_cc.cc_id = g_credit_card.cc_id #new
					INSERT INTO contact_cc VALUES (g_contact_cc.*)
			}
			UPDATE contact_cc 
			SET cc_id = g_credit_card.cc_id #new 
			WHERE cc_id = old_cc_id #old 

			IF status <> 0 THEN 
				ERROR "Cannot UPDATE contact credit card: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

			LET g_contact_cc.cc_id = g_credit_card.cc_id #new 

		END IF 

		###########
	COMMIT WORK 
	###########

	RETURN true #success 


END FUNCTION #store_cc() 


##########################
FUNCTION display_cc() 
	##########################
	DEFINE 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	IF g_credit_card.cc_id IS NULL THEN #to prevent uninitialised dates 
		#FROM displaying as 31/12/1899
		INITIALIZE g_credit_card.* TO NULL 
	END IF 

	IF g_credit_card.contact_id <> g_contact.contact_id THEN 
		CALL get_contact_name(g_credit_card.contact_id) RETURNING tmp_first, tmp_last 

		ERROR "WARNING ! This credit card does NOT belong TO current contact" 
		attribute (red) 
		MESSAGE "This credit card belongs TO ",tmp_first clipped, " ", tmp_last clipped 
		attribute (red) 
	END IF 


	CASE current_cc_form 

		WHEN 1 #ccs.per 
			DISPLAY BY NAME 

			g_credit_card.cc_no, 
			g_credit_card.cc_expire, 
			g_credit_card.valid_from, 
			g_credit_card.valid_to 


			DISPLAY all_roles TO s_cc.cc_role_name 
			DISPLAY BY NAME c_credit_card.cc_type_name 

			#         WHEN 2 #?.per

		OTHERWISE 

			ERROR "Unknown form: contact_cc.4gl, display_cc()" 
			EXIT program 
	END CASE 

END FUNCTION #display_cc() 


####################
FUNCTION del_cc() 
	####################


	IF is_default_cc_role() THEN 
		ERROR "cannot deactivate default credit card. Use Modify instead" 
		SLEEP 2 
		RETURN 
	END IF 

	MESSAGE "Mark this credit card information as deleted?" 


	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_cc","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE credit_card SET 
			valid_to = today 
			WHERE cc_id = g_credit_card.cc_id 

			UPDATE contact_cc SET 
			valid_to = today 
			WHERE cc_id = g_credit_card.cc_id 

			CLEAR FORM 
			EXIT MENU 
	END MENU 

	MESSAGE "" 

END FUNCTION #d_cc() 


###########################
FUNCTION next_cc_screen() 
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
FUNCTION new_cc_role() 
	#########################
	DEFINE 
	new_cc_role_name LIKE role.role_name, 
	new_cc_role_code LIKE role.role_code 


	CALL role_lp("CREDIT CARD") 
	RETURNING new_cc_role_code, new_cc_role_name 

	# IF Null IS RETURN THEN the users has interrupted
	IF new_cc_role_code IS NOT NULL 
	AND new_cc_role_name IS NOT NULL 
	THEN 
		IF duplicate_cc_role(new_cc_role_code) THEN 
			ERROR "This contact already have credit card with this role !" 
			SLEEP 2 
		ELSE 
			INSERT INTO contact_cc VALUES 
			(g_contact.contact_id, 
			g_credit_card.cc_id, 
			new_cc_role_code, 
			today, 
			"") 

			LET all_roles = get_cc_roles(gv_null,false) 
			LET c_credit_card.cc_type_name = get_cc_type(g_credit_card.cc_type_code) 
			CALL display_cc() 

		END IF 
	END IF 

END FUNCTION #new_cc_role() 

##################################################
FUNCTION duplicate_cc_role(new_cc_role_code) 
	##################################################
	DEFINE 
	new_cc_role_code LIKE role.role_code 


	SELECT * FROM contact_cc 
	WHERE contact_id = g_contact.contact_id 
	AND 
	cc_id = g_credit_card.cc_id 
	AND 
	role_code = new_cc_role_code 

	IF status <> notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_cc_role() 

#################################
FUNCTION get_default_cc_code() 
	#################################
	DEFINE 
	default_code LIKE role.role_code 


	SELECT cc_role_code INTO default_code 
	FROM cc_role 
	WHERE cc_role.cc_role_name = "DEFAULT" 

	RETURN default_code 

END FUNCTION #get_default_cc_code() 

##############################################
FUNCTION all_cc_roles(disp_format,and_exit) 
	##############################################
	DEFINE 
	a_contact_cc ARRAY [100] OF RECORD 
		contact_id LIKE contact_cc.contact_id, 
		cc_id LIKE contact_cc.cc_id, 
		cc_role_code LIKE contact_cc.role_code, 
		valid_from LIKE contact_cc.valid_from, 
		valid_to LIKE contact_cc.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		cc_role_name LIKE role.role_name, 
		valid_from LIKE contact_cc.valid_from, 
		valid_to LIKE contact_cc.valid_to, 
		cc_type_name CHAR (10), #like credit_card., 
		cc_no CHAR (20), #like credit_card., 
		cc_expire CHAR (10) #like credit_card. 
	END RECORD, 

	cnt, 
	changed, 
	line_cnt, 
	disp_format, 
	and_exit 
	SMALLINT, 
	new_cc_role_code 
	LIKE role.role_code, 
	new_cc_role_name 
	LIKE role.role_name 


	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_roles with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_cc_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_cc_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_all_cc_roles CURSOR FOR 
	SELECT * FROM contact_cc 
	WHERE contact_id = g_contact.contact_id 
	ORDER BY valid_from desc 

	LET cnt = 1 

	##################################################
	FOREACH c_all_cc_roles INTO a_contact_cc[cnt].* 
		##################################################

		LET a_display[cnt].cc_role_name = get_role_name(a_contact_cc[cnt].cc_role_code, "CREDIT CARD") 

		LET a_display[cnt].valid_from = a_contact_cc[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_cc[cnt].valid_to 

		SELECT cc_no, cc_expire INTO 
		a_display[cnt].cc_no, 
		a_display[cnt].cc_expire 
		FROM credit_card WHERE 
		cc_id = a_contact_cc[cnt].cc_id #tmp_cc_id 


		SELECT cc_type_name INTO a_display[cnt].cc_type_name 
		FROM cc_type, credit_card 
		WHERE 
		credit_card.cc_id = a_contact_cc[cnt].cc_id 
		AND 
		credit_card.cc_type_code = cc_type.cc_type_code 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_all_cc_roles 
	FREE c_all_cc_roles 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All credit card roles FOR this contact" 
	ELSE 
		MESSAGE "All credit card roles FOR this contact (SELECT=Accept,F6=change,F7=remove)" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_acc","display_arr-a_display-1") -- albo kd-513 

		BEFORE ROW 
			{! BEFORE ROW  !}
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

			IF a_contact_cc[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				CONTINUE DISPLAY 
				{! continue DISPLAY !}
			END IF 


			CALL role_lp("CREDIT CARD") 
			RETURNING new_cc_role_code, new_cc_role_name 

			IF 
			new_cc_role_code IS NOT NULL 
			THEN 
				#				LET line_CNT = ARR_CURR()		#SCR_LINE()
				#                #here this returns WRONG line (FROM previous L&P SCREEN !!!)
				#               error a_contact_address[line_cnt].addr_role_code,a_display[line_cnt].addr_role_name sleep 5
				#				error new_addr_role_code,new_addr_role_name sleep 5
				#               error line_cnt sleep 5

				IF change_cc_role( false, new_cc_role_code, new_cc_role_name, a_contact_cc[line_cnt].contact_id, a_contact_cc[line_cnt].cc_id, a_contact_cc[line_cnt].cc_role_code) THEN 
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
			IF a_contact_cc[line_cnt].valid_to IS NOT NULL THEN 
				ERROR "Cannot change deactivated role !" 
				SLEEP 2 
				CONTINUE DISPLAY 
				{! continue DISPLAY !}
			END IF 

			IF change_cc_role( true, gv_null, gv_null, a_contact_cc[line_cnt].contact_id, a_contact_cc[line_cnt].cc_id, a_contact_cc[line_cnt].cc_role_code) THEN 
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
			#			DISPLAY FORM f_cc1
			#			CALL display_cc()
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
		get_cc_roles(a_contact_cc[cnt].cc_id,FALSE) #cc_id,and_hist 
	END IF 


	RETURN a_contact_cc[cnt].cc_id 

END FUNCTION #all_cc_roles() 


###########################################
FUNCTION cc_hist(disp_format,and_exit) 
	###########################################
	DEFINE 
	a_cc ARRAY [100] OF RECORD 
		cc_id LIKE credit_card.cc_id, 
		contact_id LIKE credit_card.contact_id, 
		cc_type_code LIKE credit_card.cc_type_code, 
		cc_no LIKE credit_card.cc_no, 
		cc_expire LIKE credit_card.cc_expire, 
		valid_from LIKE credit_card.valid_from, 
		valid_to LIKE credit_card.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		cc_role_name LIKE role.role_name, 
		valid_from LIKE contact_cc.valid_from, 
		valid_to LIKE contact_cc.valid_to, 
		cc_type_name CHAR (10), #like credit_card., 
		cc_no CHAR (20), #like credit_card., 
		cc_expire CHAR (10) #like credit_card. 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit 
	SMALLINT 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_cc_hist with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_cc_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_cc_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_cc_hist CURSOR FOR 
	SELECT unique credit_card.* FROM contact_cc, credit_card 
	WHERE contact_cc.contact_id = g_contact.contact_id 
	AND contact_cc.cc_id = credit_card.cc_id 
	ORDER BY credit_card.valid_to desc 

	{
	    if NOT and_hist THEN
		    LET where_part = where_part clipped,
	        " AND phone.valid_to IS NULL OR phone.valid_to >= today "

	    END IF
	}


	LET cnt = 1 

	#########################################
	FOREACH c_cc_hist INTO a_cc[cnt].* 
		#########################################

		LET a_display[cnt].cc_role_name = get_cc_roles(a_cc[cnt].cc_id,true) 

		LET a_display[cnt].valid_from = a_cc[cnt].valid_from 
		LET a_display[cnt].valid_to = a_cc[cnt].valid_to 

		LET a_display[cnt].cc_no = a_cc[cnt].cc_no 
		LET a_display[cnt].cc_expire = a_cc[cnt].cc_expire 


		SELECT cc_type_name INTO a_display[cnt].cc_type_name 
		FROM cc_type 
		WHERE cc_type.cc_type_code = a_cc[cnt].cc_type_code 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_cc_hist 
	FREE c_cc_hist 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All credit cards FOR this contact" 
	ELSE 
		MESSAGE "All credit cards FOR this contact - SELECT AND press Accept" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_acc","display_arr-a_display-2") -- albo kd-513 

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

			CLOSE WINDOW w_cc_hist 
		WHEN 2 
			#			DISPLAY FORM f_cc1
			#			CALL display_cc()
	END CASE 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_cc[cnt].cc_id 

END FUNCTION #cc_hist() 

#########################################
FUNCTION get_contact_cc(p_cc_id) 
	#########################################
	DEFINE 
	p_credit_card RECORD LIKE credit_card.*, 
	p_cc_id LIKE credit_card.cc_id 


	SELECT * INTO p_credit_card.* 
	FROM credit_card 
	WHERE cc_id = p_cc_id 


	RETURN p_credit_card.* 

END FUNCTION #get_contact_cc 


##########################################################
FUNCTION get_cc_for_contact(p_contact_id,p_role_name) 
	##########################################################
	DEFINE 
	p_contact_id LIKE contact.contact_id, 
	p_role_name LIKE role.role_name, 
	pr_credit_card RECORD LIKE credit_card.* 

	SELECT unique credit_card.* INTO pr_credit_card.* 
	FROM credit_card, contact_cc, role 
	WHERE 
	contact_cc.cc_id = credit_card.cc_id 
	AND 
	contact_cc.contact_id = p_contact_id 
	AND 
	contact_cc.role_code = role.role_code 
	AND 
	role.role_name = p_role_name 
	AND 
	role.class_name = "CREDIT CARD" 
	AND 
	(contact_cc.valid_to IS NULL OR contact_cc.valid_to > today) 
	AND 
	(credit_card.valid_to IS NULL OR credit_card.valid_to > today) 

	IF status = notfound THEN 
		INITIALIZE pr_credit_card.* TO NULL 
	END IF 

	RETURN pr_credit_card.* 

END FUNCTION #get_cc_for_contact 

#####################################################
FUNCTION get_cc_type(p_cc_type_code) 
	#####################################################
	DEFINE 
	p_cc_type_code LIKE credit_card.cc_type_code, 
	p_cc_type_name LIKE cc_type.cc_type_name 


	SELECT cc_type_name INTO p_cc_type_name 
	FROM cc_type 
	WHERE cc_type_code = p_cc_type_code 

	RETURN p_cc_type_name 

END FUNCTION #get_cc_type_name() 


################################
FUNCTION is_default_cc_role() 
	################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 

	is_default 
	SMALLINT 

	LET is_default = false 
	MESSAGE "Searching...please wait" 
	DECLARE c_rolesc2 CURSOR FOR 
	SELECT unique cc_role_code FROM contact_cc 
	WHERE cc_id = g_credit_card.cc_id 

	INITIALIZE all_roles TO NULL 

	LET cnt = 1 

	######################################
	FOREACH c_rolesc2 INTO a_role_codes[cnt] 
		######################################

		SELECT cc_role_name INTO tmp_role_name FROM cc_role_code 
		WHERE cc_role_code = a_role_codes[cnt] 

		IF tmp_role_name = "DEFAULT" THEN 
			LET is_default = true 
			EXIT FOREACH 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_rolesc2 
	FREE c_rolesc2 
	MESSAGE "" 
	RETURN is_default 

END FUNCTION #is_default_cc_role() 

#####################################################################
FUNCTION change_cc_role(and_remove,new_cc_role_code,new_cc_role_name, 
	p_contact_id,p_cc_id,p_cc_role_code) 
	#####################################################################
	DEFINE 
	changed, 
	tmp_cnt, 
	and_remove 
	SMALLINT, 
	new_cc_role_code, 
	p_cc_role_code 
	LIKE role.role_code, 
	new_cc_role_name 
	LIKE role.role_name, 
	p_contact_id 
	LIKE contact.contact_id, 
	p_cc_id 
	LIKE credit_card.cc_id 


	IF and_remove THEN 
		MESSAGE "Do you realy want TO remove selected role ?" 
		attribute (red) 
	ELSE 
		MESSAGE "Do you realy want TO change selected role TO ", 
		new_cc_role_name clipped, " ?" 
		attribute (red) 
	END IF 


	MENU "Change role" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_cc","menu-Change_role-1") -- albo kd-513 

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
				UPDATE contact_cc 
				SET valid_to = today 
				WHERE contact_id = p_contact_id 
				AND cc_id = p_cc_id 
				AND role_code = p_cc_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact Credit Card: aborted !" 
					SLEEP 5 
					LET changed = false 
				ELSE 
					LET changed = true 
				END IF 

				SELECT count (*) INTO tmp_cnt 
				FROM contact_cc 
				WHERE cc_id = p_cc_id 
				AND (valid_to IS NULL OR valid_to > today) 


				IF tmp_cnt = 0 THEN # no valid relations TO this cc FROM any contact 
					UPDATE credit_card 
					SET valid_to = today 
					WHERE cc_id = p_cc_id 
				END IF 

			ELSE #change 

				UPDATE contact_cc 
				SET role_code = new_cc_role_code 
				WHERE contact_id = p_contact_id 
				AND cc_id = p_cc_id 
				AND role_code = p_cc_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact cc: aborted !" 
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

END FUNCTION #change_cc_role() 


###################################################### module end
