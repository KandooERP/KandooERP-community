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
 * contact bank account functions
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

a_all_acc_owners array[40] OF RECORD 
	contact_id LIKE contact_bank_acc.contact_id, 

	acc_id LIKE contact_bank_acc.acc_id, 

	role_code LIKE contact_bank_acc.role_code, 
	valid_from LIKE contact_bank_acc.valid_from, 
	valid_to LIKE contact_bank_acc.valid_to 
END RECORD, 

all_acc_owners_cnt 
SMALLINT 



FUNCTION crap() 


	ERROR "fdfasdf" 

END FUNCTION 



#######################
FUNCTION bank_menu() 
	#######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success, 
	any_contact 
	SMALLINT, 
	acc_id, 
	tmp_contact_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 


	MESSAGE"" 
	CALL init_bank_acc() 

	CURRENT WINDOW IS w_contact 

	MENU "Bank Account" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_bank","menu-Bank_Account-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query by bank account data" 
			LET any_contact = false 
			MESSAGE"" 
			CALL init_bank_win() 
			CALL qbe_bank_acc(any_contact) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_bank_acc_cursor(send1, send2, send3,any_contact) 
			END IF 

		COMMAND "+" "Next found" 
			MESSAGE"" 
			CALL init_bank_win() 
			CALL n_bank_acc(any_contact) 

		COMMAND "-" "Previous found" 
			MESSAGE"" 
			CALL init_bank_win() 
			CALL p_bank_acc(any_contact) 

		COMMAND "Add" "Add new bank account FOR this contact" 
			MESSAGE"" 
			CALL init_bank_win() 
			MENU "Add phone" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","contact_bank","menu-Add_phone-1") -- albo kd-513 

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Add new" "Add a new bank account TO the database" 
					LET success = au_contact_bank_acc(g_contact.contact_id,true) #add_mode 
					IF success THEN 
						CALL get_acc_owners(false) #any_contact 
					END IF 

					EXIT MENU 

				COMMAND "Pick" "Pick an existing bank account TO be used by this Contact" 

				COMMAND "Cancel" "Do NOT add a new bank account" 
					EXIT MENU 
			END MENU 

		COMMAND "Edit" "Modify current bank account FOR this contact" 
			MESSAGE"" 
			CALL init_bank_win() 
			LET success = au_contact_bank_acc(g_contact.contact_id,false) #add_mode 

		COMMAND "New role" "Add a new role FOR this bank account" 
			MESSAGE"" 
			CALL init_bank_win() 
			CALL new_bank_acc_role() 

		COMMAND "Change role" "Change roles FOR this bank account" 
			MESSAGE"" 
			CALL init_bank_win() 
			LET acc_id = all_bank_acc_roles(2,false) 
			DISPLAY FORM f_bank_acc1 
			CALL display_bank_acc() 
			IF 
			acc_id IS NOT NULL 
			THEN 
				CALL disp_selected_bank_acc(acc_id) 
			END IF 

		COMMAND KEY ("r","R") "all Roles" "DISPLAY all role AND bank acc. info on this contact, including history" 
			MESSAGE"" 
			CALL init_bank_win() 
			LET acc_id = all_bank_acc_roles(2,false) 
			DISPLAY FORM f_bank_acc1 
			CALL display_bank_acc() 
			IF 
			acc_id IS NOT NULL 
			THEN 
				CALL disp_selected_bank_acc(acc_id) 
			END IF 

		COMMAND "History" "DISPLAY all historycal bank account info" 
			MESSAGE"" 
			CALL init_bank_win() 
			LET acc_id = bank_acc_hist("2",FALSE) 
			DISPLAY FORM f_bank_acc1 
			CALL display_bank_acc() 
			CALL disp_selected_bank_acc(acc_id) 

		COMMAND "Delete" "Delete current bank account" 
			MESSAGE"" 
			CALL init_bank_win() 
			CALL del_bank_acc() 

		COMMAND KEY ("y","Y") "anY bank acct" "Query FOR any contact bank account data" 
			MESSAGE "" 
			CALL init_bank_win() 
			LET any_contact = true 
			CALL qbe_bank_acc(any_contact) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_bank_acc_cursor(send1, send2, send3,any_contact) 
				#                show option "Switch"
			END IF 

		COMMAND "Switch" "Switch current contact TO the one that the displayed bank acc. belongs TO" 

			IF g_contact_bank_acc.contact_id <> g_contact.contact_id THEN 
				CALL get_contact_name(g_contact_bank_acc.contact_id) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_bank","menu-Switch-1") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current bank acc. belongs TO" 
						MESSAGE "" 
						CALL switch_contact(g_contact_bank_acc.contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This bank account belongs TO the current contact: Cannot switch" 
			END IF 

			#        COMMAND "Screen" "Show next SCREEN of current bank account data"
			#            CALL next_bank_acc_screen()


		COMMAND "Owners" "Show all owners of this bank account" 
			LET tmp_contact_id = list_all_acc_owners(g_bank_acc.acc_id) 

			IF tmp_contact_id <> g_contact.contact_id 
			AND tmp_contact_id IS NOT NULL THEN 
				CALL get_contact_name(tmp_contact_id) RETURNING tmp_first, tmp_last 

				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_bank","menu-Switch-2") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current bank acc. belongs TO" 
						MESSAGE "" 
						CALL switch_contact(tmp_contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This bank account belongs TO the current contact: Cannot switch" 
			END IF 


		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #bank_acc_menu() 

####################################
FUNCTION disp_selected_bank_acc(acc_id) 
	####################################
	DEFINE 
	acc_id 
	SMALLINT, 
	send1, send2, send3 #where_part 
	CHAR (200) 


	IF acc_id IS NOT NULL THEN 
		LET send1 = " bank_acc.acc_id = ", acc_id 
		INITIALIZE send2, send3 TO NULL 

		CALL bank_acc_where_part(send1, send2, send3,false) #any_contact 
		RETURNING send1, send2, send3 

		CALL open_bank_acc_cursor(send1, send2, send3,false) #any_contact 
	END IF 
END FUNCTION 


######################
FUNCTION init_bank_acc() 
	######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	#already opmen FOR Info !
	#	OPEN WINDOW w_bank_acc
	#        AT 12,2 with 13 rows, 75 columns
	#			attribute (border)

	CALL init_bank_win() 

	# We want TO get all Bank accounts FOR a contact NOT
	# just the DEFAULT
	#	LET send1 = " role.role_name = 'DEFAULT' ",
	#                " AND role.class_name = 'BANK ACCOUNT' ",
	#                " AND role.role_code = contact_bank_acc.role_code ",
	#		        " AND contact_bank_acc.contact_id = ", g_contact.contact_id, " "

	LET send1 = " contact_bank_acc.contact_id = ", g_contact.contact_id, " " 

	INITIALIZE send2, send3 TO NULL 

	CALL bank_acc_where_part(send1, send2, send3,false) #any_contact 
	RETURNING send1, send2, send3 

	CALL open_bank_acc_cursor(send1, send2, send3,false) #any_contact 

	MESSAGE "Default bank account:" 

END FUNCTION #init_bank_acc() 

###########################
FUNCTION init_bank_win() 
	###########################

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_bank_acc1 

	LET current_bank_acc_form = 1 

END FUNCTION #init_bank_window() 


################################
FUNCTION qbe_bank_acc(any_contact) 
	################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	tmp_bank_acc_role_name, tmp_name 
	LIKE role.role_name, 

	any_contact 
	SMALLINT 

	IF current_bank_acc_form <> 1 THEN 
		CALL d_bank_acc1() 
	END IF 

	MESSAGE "Enter the query conndition AND press Accept" 


	CONSTRUCT where_part ON 
	bank_acc.bank_name, 
	bank_acc.bank_branch, 
	bank_acc.acc_no, 
	role.role_name, 
	bank_acc.acc_name, 
	bank_acc.country, 
	bank_acc.valid_from, 
	bank_acc.valid_to 

	FROM 
	s_bank_acc.bank_name, 
	s_bank_acc.bank_branch, 
	s_bank_acc.acc_no, 
	s_bank_acc.acc_role_name, 
	s_bank_acc.acc_name, 
	s_bank_acc.country, 
	s_bank_acc.valid_from, 
	s_bank_acc.valid_to 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact_bank","construct-bank_acc-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############################
		AFTER FIELD acc_role_name 
			############################
			LET tmp_bank_acc_role_name = get_fldbuf(acc_role_name) 

			IF 
			tmp_bank_acc_role_name IS NOT NULL 
			AND 
			length (tmp_bank_acc_role_name) > 0 
			THEN 
				LET tmp_name = get_fldbuf(acc_role_name) 

				SELECT * FROM role 
				WHERE role_name = tmp_name 
				AND class_name = "BANK ACCOUNT" 

				IF status = notfound THEN 
					ERROR "This role IS NOT defined" 
					NEXT FIELD acc_role_name 

				END IF 
			ELSE 
				LET tmp_name = "DEFAULT" 
				DISPLAY tmp_name TO s_bank_acc.acc_role_name 
			END IF 



			#############
	END CONSTRUCT 
	#############


	MESSAGE "" 

	IF NOT any_contact THEN 
		LET where_part = where_part clipped, 
		" AND contact_bank_acc.contact_id = ", g_contact.contact_id, " " 
	END IF 


	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	CALL bank_acc_where_part(send1, send2, send3, any_contact) 
	RETURNING send1, send2, send3 

	#    LET last_bank_acc_where_part = where_part

	RETURN send1, send2, send3 #where_part 

END FUNCTION #q_bank_acc() 


####################
FUNCTION d_bank_acc1() 
	####################

	DISPLAY FORM f_bank_acc1 
	LET current_bank_acc_form = 1 
	CALL display_bank_acc() 

END FUNCTION 

################################################
FUNCTION get_bank_acc_roles(tmp_acc_id,and_hist) 
	################################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt, 
	and_hist 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 
	tmp_acc_id 
	LIKE bank_acc.acc_id, 
	where_part 
	CHAR (300) 

	IF tmp_acc_id IS NULL THEN 
		LET tmp_acc_id = g_bank_acc.acc_id 
	END IF 


	LET where_part = 
	" SELECT unique role_code FROM contact_bank_acc ", 
	" WHERE acc_id = ", tmp_acc_id, 
	" AND contact_id = ", g_contact.contact_id 

	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" AND (valid_to IS NULL OR valid_to > today )" 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE xde55 FROM where_part 
	DECLARE c_bank_acc_roles CURSOR FOR xde55 


	INITIALIZE all_roles TO NULL 

	LET cnt = 1 

	############################################
	FOREACH c_bank_acc_roles INTO a_role_codes[cnt] 
		############################################

		LET tmp_role_name = get_role_name(a_role_codes[cnt], "BANK ACCOUNT") 

		IF cnt = 1 THEN 
			LET all_roles = tmp_role_name 
		ELSE 
			LET all_roles = all_roles clipped,", ", tmp_role_name clipped 
		END IF 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	CLOSE c_bank_acc_roles 
	FREE c_bank_acc_roles 
	MESSAGE "" 
	RETURN all_roles 

END FUNCTION #get_bank_acc_roles() 


#############################################################
FUNCTION bank_acc_where_part(send1, send2, send3,any_contact) 
	#############################################################
	DEFINE 
	where_part, 
	received_where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT 

	LET received_where_part = send1, send2, send3 

	LET where_part = "SELECT unique bank_acc.* ", 
	#" , contact_bank_acc.* ",
	" FROM bank_acc, contact_bank_acc " 

	IF received_where_part matches "*role.role_name*" THEN 
		LET where_part = where_part clipped, 
		", role " 
	END IF 

	LET where_part = where_part clipped, 
	" WHERE ", received_where_part clipped, 
	#        " AND contact_bank_acc.contact_id = ", g_contact.contact_id,
	" AND contact_bank_acc.acc_id = bank_acc.acc_id " 


	IF 
	received_where_part matches "*role.role_name*" 
	THEN 
		LET where_part = where_part clipped, 
		" AND role.role_code = contact_bank_acc.role_code ", 
		" AND role.class_name = 'BANK ACCOUNT' " 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	RETURN send1, send2, send3 #where_part 

END FUNCTION #bank_acc_where_part() 


###############################################################
FUNCTION open_bank_acc_cursor(send1, send2, send3, any_contact) 
	###############################################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact SMALLINT 

	LET where_part = send1, send2, send3 

	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_bank_acc.valid_to IS NULL OR contact_bank_acc.valid_to > TODAY)", 
		" AND (bank_acc.valid_to IS NULL OR bank_acc.valid_to > TODAY)" 

	END IF 

	#    LET where_part = where_part clipped," group by bank_acc.acc_id, bank_acc.contact_id ... line1 etc must be in group by "

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	MESSAGE "Please wait..." attribute (blink) 

	PREPARE xpee3 FROM where_part 
	DECLARE c_read_bank_acc SCROLL CURSOR with HOLD FOR xpee3 
	OPEN c_read_bank_acc 

	INITIALIZE g_bank_acc.* TO NULL 

	FETCH FIRST c_read_bank_acc INTO g_bank_acc.* #, g_contact_bank_acc.* 

	IF 
	status = notfound 
	THEN 
		MESSAGE "" 
		ERROR "No records found" 
		INITIALIZE g_bank_acc.* TO NULL 
	ELSE 
		MESSAGE "" 
		IF 
		g_bank_acc.acc_id IS NULL 
		THEN 
			ERROR "ERROR! Status IS FOUND, AND there IS no RECORD ! " 
			SLEEP 10 
		END IF 


		CALL get_acc_owners(any_contact) 
		LET all_roles = get_bank_acc_roles(gv_null,show_history) 
		CALL display_bank_acc() 
	END IF 

END FUNCTION #open_bank_acc_cursor() 

###################################################
FUNCTION get_one_acc_role(p_acc_id,p_contact_id) 
	###################################################
	DEFINE 
	p_acc_id LIKE bank_acc.acc_id, 
	p_contact_id LIKE contact.contact_id, 
	tmp_role_code LIKE role.role_code 

	MESSAGE "Searching...please wait" 
	DECLARE c_one_acc_role CURSOR FOR 
	SELECT role_code FROM contact_bank_acc 
	WHERE contact_id = p_contact_id 
	AND acc_id = p_acc_id 
	GROUP BY role_code 

	########################################
	FOREACH c_one_acc_role INTO tmp_role_code 
		########################################

		IF 
		is_default_role(tmp_role_code, "BANK ACCOUNT") 
		THEN 
			EXIT FOREACH 
		END IF 

		###########
	END FOREACH 
	###########

	CLOSE c_one_acc_role 
	FREE c_one_acc_role 
	MESSAGE "" 
	RETURN tmp_role_code 

END FUNCTION #get_one_acc_role 


################################
FUNCTION n_bank_acc(any_contact) 
	################################
	DEFINE 
	any_contact 
	SMALLINT 
	IF 
	g_bank_acc.acc_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 

	MESSAGE "Please wait..." attribute (blink) 

	FETCH NEXT c_read_bank_acc INTO g_bank_acc.* #, g_contact_bank_acc.* 

	IF 
	status = notfound 
	THEN 
		MESSAGE "" 
		CALL display_bank_acc() 
		ERROR "No more records found" 
	ELSE 
		MESSAGE "" 
		CALL get_acc_owners(any_contact) 
		LET all_roles = get_bank_acc_roles(gv_null,show_history) 
		CALL display_bank_acc() 
	END IF 

END FUNCTION #n_bank_acc() 

################################
FUNCTION p_bank_acc(any_contact) 
	################################
	DEFINE 
	any_contact 
	SMALLINT 

	IF 
	g_bank_acc.acc_id IS NULL 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 

	MESSAGE "Please wait..." attribute (blink) 

	FETCH previous c_read_bank_acc INTO g_bank_acc.* #, g_contact_bank_acc.* 

	IF status = notfound THEN 
		MESSAGE "" 
		CALL display_bank_acc() 
		ERROR "No previous records found" 
	ELSE 
		MESSAGE "" 
		CALL get_acc_owners(any_contact) 
		LET all_roles = get_bank_acc_roles(gv_null,show_history) 
		CALL display_bank_acc() 
	END IF 

END FUNCTION #p_bank_acc() 


####################################################
FUNCTION au_contact_bank_acc(tmp_contact_id,add_mode) 
	####################################################
	DEFINE 
	tmp_contact_id LIKE contact.contact_id, 
	p_bank_acc_role_name, new_bank_acc_role_name LIKE role.role_name, 
	new_bank_acc_role_code LIKE role.role_code, 

	add_mode, 
	success 
	SMALLINT, 
	store_bank_acc RECORD LIKE bank_acc.*, 
	store_contact_bank_acc RECORD LIKE contact_bank_acc.* 

	IF current_bank_acc_form <> 1 THEN 
		CALL d_bank_acc1() 
	END IF 

	IF add_mode THEN 
		INITIALIZE g_bank_acc TO NULL 
		INITIALIZE g_contact_bank_acc TO NULL 
		CLEAR FORM 
		MESSAGE "Enter new bank account data AND press Accept" 
	ELSE 
		LET store_bank_acc.* = g_bank_acc.* 
		LET store_contact_bank_acc.* = g_contact_bank_acc.* 
		MESSAGE "Enter changes AND press Accept" 
	END IF 

	#############
	INPUT 
	#############
	g_bank_acc.bank_name, 
	g_bank_acc.bank_branch, 
	g_bank_acc.acc_no, 
	c_bank_acc.acc_role_name, 
	g_bank_acc.acc_name, 
	g_bank_acc.country, 
	g_bank_acc.valid_from, 
	g_bank_acc.valid_to 

	WITHOUT DEFAULTS FROM 
	s_bank_acc.bank_name, 
	s_bank_acc.bank_branch, 
	s_bank_acc.acc_no, 
	s_bank_acc.acc_role_name, 
	s_bank_acc.acc_name, 
	s_bank_acc.country, 
	s_bank_acc.valid_from, 
	s_bank_acc.valid_to 


	############
		BEFORE INPUT 
			############
			CALL publish_toolbar("kandoo","contact_bank","input-s_bank_acc-1") -- albo kd-513 
			IF NOT add_mode THEN 
				DISPLAY all_roles TO s_bank_acc.acc_role_name 
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
				WHEN infield(acc_role_name) 
					############################

					CALL role_lp("BANK ACCOUNT") 
					RETURNING new_bank_acc_role_code, new_bank_acc_role_name 

					IF new_bank_acc_role_code IS NOT NULL THEN 
						LET p_bank_acc_role_name = new_bank_acc_role_name 
						LET g_contact_bank_acc.role_code = new_bank_acc_role_code 
						LET c_bank_acc.acc_role_name = new_bank_acc_role_name 
						DISPLAY c_bank_acc.acc_role_name TO acc_role_name 
					END IF 

					########
			END CASE 
			########

			##########################
		BEFORE FIELD acc_role_name 
			##########################

			IF NOT add_mode THEN 
				NEXT FIELD NEXT 
			END IF 


			#########################
		AFTER FIELD acc_role_name 
			#########################

			IF c_bank_acc.acc_role_name #p_bank_acc_role_name IS NOT NULL 
			AND add_mode THEN 
				LET g_contact_bank_acc.role_code = get_role_code(c_bank_acc.acc_role_name, "BANK ACCOUNT") 


				IF g_contact_bank_acc.role_code IS NULL THEN 

					CALL role_lp("BANK ACCOUNT") 
					RETURNING new_bank_acc_role_code, new_bank_acc_role_name 

					IF new_bank_acc_role_code IS NULL THEN 
						LET p_bank_acc_role_name = "DEFAULT" 
						LET g_contact_bank_acc.role_code = get_default_code("BANK ACCOUNT") 
						LET c_bank_acc.acc_role_name = p_bank_acc_role_name 

					ELSE 
						LET g_contact_bank_acc.role_code = new_bank_acc_role_code 
						LET p_bank_acc_role_name = new_bank_acc_role_name 
						LET c_bank_acc.acc_role_name = new_bank_acc_role_name 
					END IF 
				ELSE 

					IF duplicate_bank_acc_role(new_bank_acc_role_code) 
					AND add_mode THEN 
						ERROR "This contact already have bank account with this role !" 
						SLEEP 2 
						NEXT FIELD acc_role_name 

					END IF 
				END IF 

				DISPLAY p_bank_acc_role_name TO acc_role_name 

			END IF 

			######################
		AFTER FIELD valid_from 
			######################
			IF g_bank_acc.valid_from IS NULL THEN 
				LET g_bank_acc.valid_from = today 
				DISPLAY BY NAME g_bank_acc.valid_from 
			END IF 


			#########################
		AFTER FIELD acc_no 
			#########################

			IF add_mode THEN 
				#IF duplicate_acc() THEN
				#offer TO pick existing instead of adding
			END IF 


			###########
		AFTER INPUT 
			###########

			IF int_flag THEN 
				EXIT INPUT 
			END IF 

			LET g_contact_bank_acc.contact_id = g_contact.contact_id 
			LET g_contact_bank_acc.valid_from = today 

			#LET g_bank_acc.acc_id = 0
			LET g_bank_acc.valid_from = today 

			IF c_bank_acc.acc_role_name #p_bank_acc_role_name IS NULL 
			OR length (c_bank_acc.acc_role_name) < 1 THEN #p_bank_acc_role_name) < 1 
				LET p_bank_acc_role_name = "DEFAULT" 
				LET c_bank_acc.acc_role_name = p_bank_acc_role_name 

				LET g_contact_bank_acc.role_code = get_default_code("BANK ACCOUNT") 

			END IF 

			IF duplicate_bank_acc_role(g_contact_bank_acc.role_code) 
			AND add_mode THEN 
				ERROR "This contact already have bank account with this role. Please SELECT another role !" 
				SLEEP 2 
				NEXT FIELD acc_role_name 
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
		g_bank_acc.bank_name = store_bank_acc.bank_name 
		AND 
		g_bank_acc.bank_branch = store_bank_acc.bank_branch 
		AND 
		g_bank_acc.acc_no = store_bank_acc.acc_no 
		AND 
		#g_bank_acc.acc_role_name,
		g_bank_acc.acc_name = store_bank_acc.acc_name 
		AND 
		g_bank_acc.country = store_bank_acc.country 
		AND 
		g_bank_acc.valid_to = store_bank_acc.valid_to 

		THEN 
			ERROR "Nothhing changed: nothing TO UPDATE" 
			RETURN false 
		END IF 
	END IF 

	LET success = do_store_bank_acc(add_mode) 

	RETURN success 

END FUNCTION #au_contact_bank_acc() 


###############################
FUNCTION do_store_bank_acc(add_mode) 
	###############################
	DEFINE 
	add_mode 
	SMALLINT, 
	old_acc_id 
	INTEGER 

	LET old_acc_id = g_bank_acc.acc_id 

	##########
	BEGIN WORK 
		##########

		IF NOT add_mode THEN #logical UPDATE 

			#first, close previous record
			UPDATE bank_acc SET 
			valid_to = today 
			WHERE acc_id = old_acc_id 

			IF status <> 0 THEN 
				ERROR "Cannot close previous record: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

		END IF 

		LET g_contact_bank_acc.contact_id = g_contact.contact_id 
		LET g_bank_acc.acc_id = 0 
		LET g_bank_acc.valid_from = today 
		#LET g_contact.mod_user_id = glob_rec_kandoouser.sign_on_code


		##########################################
		INSERT INTO bank_acc VALUES (g_bank_acc.*) 
		##########################################

		IF 
		status <> 0 
		THEN 
			ERROR "Cannot INSERT new record: Update/Add aborted !" 
			SLEEP 5 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		LET g_bank_acc.acc_id = sqlca.sqlerrd[2] 


		IF 
		########
		add_mode 
		########
		THEN 

			LET g_contact_bank_acc.acc_id = g_bank_acc.acc_id 

			INSERT INTO contact_bank_acc VALUES (g_contact_bank_acc.*) 

			IF status <> 0 THEN 
				ERROR "Cannot add contact bank account: Add aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 
			####
		ELSE #logical UPDATE 
			####

			UPDATE contact_bank_acc 
			SET acc_id = g_bank_acc.acc_id 
			WHERE acc_id = old_acc_id 

			IF status <> 0 THEN 
				ERROR "Cannot UPDATE contact bank account: Update aborted !" 
				SLEEP 5 
				ROLLBACK WORK 
				RETURN false 
			END IF 

			LET g_contact_bank_acc.acc_id = g_bank_acc.acc_id #new 

		END IF 

		###########
	COMMIT WORK 
	###########

	RETURN true #success 


END FUNCTION #store_bank_acc() 


##########################
FUNCTION display_bank_acc() 
	##########################
	DEFINE 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	IF g_bank_acc.acc_id IS NULL THEN 
		#TO prevent uninitialised dates
		#FROM displaying as 31/12/1899
		INITIALIZE g_bank_acc.* TO NULL 
	END IF 

	IF g_contact_bank_acc.contact_id <> g_contact.contact_id 
	AND g_contact_bank_acc.contact_id IS NOT NULL 
	AND g_bank_acc.acc_id IS NOT NULL THEN 
		CALL get_contact_name(g_contact_bank_acc.contact_id) RETURNING tmp_first, tmp_last 

		ERROR "WARNING ! This bank account does NOT belong TO current contact" 
		attribute (red) 
		MESSAGE "This account belongs TO ",tmp_first clipped, " ", tmp_last clipped 
		attribute (red) 
	END IF 


	CASE current_bank_acc_form 

		WHEN 1 #bank_accs.per 
			DISPLAY BY NAME 
			g_bank_acc.bank_name, 
			g_bank_acc.bank_branch, 
			g_bank_acc.acc_no, 
			g_bank_acc.acc_name, 
			g_bank_acc.country, 
			g_bank_acc.valid_from, 
			g_bank_acc.valid_to 


			DISPLAY all_roles TO s_bank_acc.acc_role_name 


			#         WHEN 2 #?.per

		OTHERWISE 

			ERROR "Unknown form: contact_bank.4gl, display_bank_acc()" 
			EXIT program 
	END CASE 

END FUNCTION #display_bank_acc() 


####################
FUNCTION del_bank_acc() 
	####################


	IF is_default_bank_acc(g_bank_acc.acc_id) THEN 
		ERROR "cannot deactivate default bank account. Use Modify instead" 
		SLEEP 2 
		RETURN 
	END IF 

	MESSAGE "Mark this bank account information as deleted?" 


	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_bank","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE bank_acc SET 
			valid_to = today 
			WHERE acc_id = g_bank_acc.acc_id 

			UPDATE contact_bank_acc SET 
			valid_to = today 
			WHERE acc_id = g_bank_acc.acc_id 
			AND contact_id = g_contact_bank_acc.contact_id 

			CLEAR FORM 
			EXIT MENU 
	END MENU 

	MESSAGE "" 

END FUNCTION #d_bank_acc() 


#########################
FUNCTION new_bank_acc_role() 
	#########################
	DEFINE 
	new_bank_acc_role_name LIKE role.role_name, 
	new_bank_acc_role_code LIKE role.role_code 


	CALL role_lp("BANK ACCOUNT") 
	RETURNING new_bank_acc_role_code, new_bank_acc_role_name 

	# IF Null IS RETURN THEN the users has interrupted
	IF new_bank_acc_role_code IS NOT NULL 
	AND new_bank_acc_role_name IS NOT NULL 
	THEN 
		IF duplicate_bank_acc_role(new_bank_acc_role_code) THEN 
			ERROR "This contact already have bank account with this role !" 
			SLEEP 2 
		ELSE 
			INSERT INTO contact_bank_acc VALUES 
			(g_contact.contact_id, 
			new_bank_acc_role_code, 
			g_bank_acc.acc_id, 
			today, 
			"") 

			LET all_roles = get_bank_acc_roles(gv_null,false) 
			CALL display_bank_acc() 

		END IF 
	END IF 

END FUNCTION #new_bank_acc_role() 

##################################################
FUNCTION duplicate_bank_acc_role(new_bank_acc_role_code) 
	##################################################
	DEFINE 
	new_bank_acc_role_code LIKE role.role_code 



	SELECT * FROM contact_bank_acc 
	WHERE contact_id = g_contact.contact_id 
	AND 
	acc_id = g_bank_acc.acc_id 
	AND 
	role_code = new_bank_acc_role_code 

	IF status <> notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_bank_acc_role() 

##############################################
FUNCTION all_bank_acc_roles(disp_format,and_exit) 
	##############################################
	DEFINE 
	a_contact_bank_acc ARRAY [100] OF RECORD 
		contact_id LIKE contact_bank_acc.contact_id, 
		bank_acc_role_code LIKE contact_bank_acc.role_code, 
		acc_id LIKE contact_bank_acc.acc_id, 
		valid_from LIKE contact_bank_acc.valid_from, 
		valid_to LIKE contact_bank_acc.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		bank_acc_role_name LIKE role.role_name, 
		valid_from LIKE contact_bank_acc.valid_from, 
		valid_to LIKE contact_bank_acc.valid_to, 
		bank_name CHAR (20), #like bank_acc., 
		bank_branch CHAR (10), #like bank_acc., 
		acc_name CHAR (20) #like bank_acc. 
	END RECORD, 

	cnt, 
	line_cnt, 
	changed, 
	disp_format, 
	and_exit 
	SMALLINT, 
	new_acc_role_code 
	LIKE role.role_code, 
	new_acc_role_name 
	LIKE role.role_name 


	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_roles with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_bank_acc_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_all_ac_roles CURSOR FOR 
	SELECT * FROM contact_bank_acc 
	WHERE contact_id = g_contact.contact_id 
	ORDER BY valid_from desc 

	LET cnt = 1 

	##################################################
	FOREACH c_all_ac_roles INTO a_contact_bank_acc[cnt].* 
		##################################################

		LET a_display[cnt].bank_acc_role_name = get_role_name(a_contact_bank_acc[cnt].bank_acc_role_code, "BANK ACCOUNT") 

		LET a_display[cnt].valid_from = a_contact_bank_acc[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_bank_acc[cnt].valid_to 

		SELECT bank_name, bank_branch, acc_name INTO 
		a_display[cnt].bank_name, 
		a_display[cnt].bank_branch, 
		a_display[cnt].acc_name 
		FROM bank_acc WHERE 
		acc_id = a_contact_bank_acc[cnt].acc_id #tmp_acc_id 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_all_ac_roles 
	FREE c_all_ac_roles 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All bank account roles FOR this contact" 
	ELSE 
		MESSAGE "All bank account roles FOR this contact (SELECT=Accept,F6=change,F7=remove)" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_bank","display_arr-a_display-1") -- albo kd-513 

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

			###########
		ON KEY (f6) #change role 
			{! ON KEY (f6) #change role !}
			###########

			LET line_cnt = arr_curr() #scr_line() 

			IF a_contact_bank_acc[line_cnt].valid_to IS NOT NULL THEN 
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
				#|   A grammatical error has been found on line 1391, character 26.
				#| The CONSTRUCT IS NOT understandable in its context.
				#|
				#| Check error -4373.
				#|
			END IF 


			CALL role_lp("bank_acc") 
			RETURNING new_acc_role_code, new_acc_role_name 

			IF 
			new_acc_role_code IS NOT NULL 
			THEN 
				#				LET line_CNT = ARR_CURR()		#SCR_LINE()
				#                #here this returns WRONG line (FROM previous L&P SCREEN !!!)
				#               error a_contact_bank_acc[line_cnt].acc_role_code,a_display[line_cnt].acc_role_name sleep 5
				#				error new_acc_role_code,new_acc_role_name sleep 5
				#               error line_cnt sleep 5

				IF change_acc_role( 
				false, 
				new_acc_role_code, 
				new_acc_role_name, 
				a_contact_bank_acc[line_cnt].contact_id, 
				a_contact_bank_acc[line_cnt].acc_id, 
				a_contact_bank_acc[line_cnt].bank_acc_role_code 
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
			IF a_contact_bank_acc[line_cnt].valid_to IS NOT NULL THEN 
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
				#|   A grammatical error has been found on line 1431, character 26.
				#| The CONSTRUCT IS NOT understandable in its context.
				#|
				#| Check error -4373.
				#|
			END IF 

			IF 
			change_acc_role( 
			true, 
			gv_null, 
			gv_null, 
			a_contact_bank_acc[line_cnt].contact_id, 
			a_contact_bank_acc[line_cnt].acc_id, 
			a_contact_bank_acc[line_cnt].bank_acc_role_code 
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
			#			DISPLAY FORM f_bank_acc1
			#			CALL display_bank_acc()
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
		get_bank_acc_roles(a_contact_bank_acc[cnt].acc_id,FALSE) #bank_acc_id,and_hist 
	END IF 


	RETURN a_contact_bank_acc[cnt].acc_id 

END FUNCTION #all_bank_acc_roles() 


###########################################
FUNCTION bank_acc_hist(disp_format,and_exit) 
	###########################################
	DEFINE 
	a_bank_acc ARRAY [100] OF RECORD 
		acc_id LIKE bank_acc.acc_id, 
		#	   contact_id LIKE contact_bank_acc.contact_id,
		bank_name LIKE bank_acc.bank_name, 
		bank_branch LIKE bank_acc.bank_branch, 
		acc_no LIKE bank_acc.acc_no, 
		acc_name LIKE bank_acc.acc_name, 
		country LIKE bank_acc.country, 
		valid_from LIKE bank_acc.valid_from, 
		valid_to LIKE bank_acc.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		bank_acc_role_name LIKE role.role_name, 
		valid_from LIKE contact_bank_acc.valid_from, 
		valid_to LIKE contact_bank_acc.valid_to, 
		bank_name CHAR (20), #like bank_acc., 
		bank_branch CHAR (10), #like bank_acc., 
		acc_name CHAR (20) #like bank_acc. 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	and_hist 
	SMALLINT 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_bank_acc_hist with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_bank_acc_roles 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_bank_acc_hist CURSOR FOR 
	SELECT unique bank_acc.* FROM contact_bank_acc, bank_acc 
	WHERE contact_bank_acc.contact_id = g_contact.contact_id 
	AND contact_bank_acc.acc_id = bank_acc.acc_id 
	ORDER BY bank_acc.valid_to desc 

	#    if NOT and_hist THEN
	#	    LET where_part = where_part clipped,
	#        " AND phone.valid_to IS NULL OR phone.valid_to >= today "
	#
	#    END IF


	LET cnt = 1 

	#########################################
	FOREACH c_bank_acc_hist INTO a_bank_acc[cnt].* 
		#########################################

		LET a_display[cnt].bank_acc_role_name = get_bank_acc_roles(a_bank_acc[cnt].acc_id,true) 

		LET a_display[cnt].valid_from = a_bank_acc[cnt].valid_from 
		LET a_display[cnt].valid_to = a_bank_acc[cnt].valid_to 

		LET a_display[cnt].bank_name = a_bank_acc[cnt].bank_name 
		LET a_display[cnt].bank_branch = a_bank_acc[cnt].bank_branch 
		LET a_display[cnt].acc_name = a_bank_acc[cnt].acc_name 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_bank_acc_hist 
	FREE c_bank_acc_hist 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		MESSAGE "All bank accounts FOR this contact" 
	ELSE 
		MESSAGE "All bank accounts FOR this contact - SELECT AND press Accept" 
	END IF 

	######################################
	DISPLAY ARRAY a_display TO s_display.* 
	######################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_bank","display_arr-a_display-2") -- albo kd-513 

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

			CLOSE WINDOW w_bank_acc_hist 
		WHEN 2 
			#			DISPLAY FORM f_bank_acc1
			#			CALL display_bank_acc()
	END CASE 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_bank_acc[cnt].acc_id 

END FUNCTION #bank_acc_hist() 

#########################################
FUNCTION get_contact_bank_acc(p_acc_id) 
	#########################################
	DEFINE 
	p_bank_acc RECORD LIKE bank_acc.*, 
	p_acc_id LIKE bank_acc.acc_id 


	SELECT * INTO p_bank_acc.* 
	FROM bank_acc 
	WHERE acc_id = p_acc_id 


	RETURN p_bank_acc.* 

END FUNCTION #get_contact_bank_acc 


##########################################################
FUNCTION get_bank_acc_for_contact(p_contact_id,p_role_name) 
	##########################################################
	DEFINE 
	p_contact_id LIKE contact.contact_id, 
	p_role_name LIKE role.role_name, 
	pr_bank_acc RECORD LIKE bank_acc.* 

	SELECT unique bank_acc.* INTO pr_bank_acc.* 
	FROM bank_acc, contact_bank_acc, role 
	WHERE 
	contact_bank_acc.acc_id = bank_acc.acc_id 
	AND 
	contact_bank_acc.contact_id = p_contact_id 
	AND 
	contact_bank_acc.role_code = role.role_code 
	AND 
	role.role_name = p_role_name 
	AND 
	role.class_name = "BANK ACCOUNT" 
	AND 
	(contact_bank_acc.valid_to IS NULL OR contact_bank_acc.valid_to > today) 
	AND 
	(bank_acc.valid_to IS NULL OR bank_acc.valid_to > today) 
	IF status = notfound THEN 
		INITIALIZE pr_bank_acc.* TO NULL 
	END IF 

	RETURN pr_bank_acc.* 

END FUNCTION #get_bank_acc_for_contact 
#####################################
FUNCTION is_default_bank_acc(p_acc_id) 
	#####################################
	DEFINE 
	a_role_codes array[10] 
	OF SMALLINT, 
	cnt 
	SMALLINT, 
	tmp_role_name 
	LIKE role.role_name, 
	tmp_role_code 
	LIKE role.role_code, 

	is_default 
	SMALLINT, 
	p_acc_id 
	LIKE bank_acc.acc_id 

	LET tmp_role_code = get_role_code("DEFAULT","BANK ACCOUNT") 

	SELECT * FROM contact_bank_acc 
	WHERE role_code = tmp_role_code 
	AND acc_id = p_acc_id 
	AND contact_id = g_contact.contact_id 


	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION #is_default_bank_acc_role() 


#########################################
FUNCTION get_acc_owners(any_contact) 
	#########################################
	DEFINE 
	any_contact, 
	cnt, 
	tmp_one_role 
	SMALLINT 

	LET query_1 = 
	"SELECT unique contact_id ", #, bank_acc_id,role_code,valid_from,valid_to ", 
	" FROM contact_bank_acc ", 
	" WHERE contact_bank_acc.acc_id = ",g_bank_acc.acc_id, 
	" group by contact_bank_acc.contact_id" 
	MESSAGE "Searching...please wait" 
	PREPARE xa_stmt FROM query_1 
	DECLARE c_acntct CURSOR FOR xa_stmt 

	LET cnt = 1 

	#######################################
	FOREACH c_acntct INTO a_all_acc_owners[cnt].contact_id #* 
		#######################################

		IF a_all_acc_owners[cnt].contact_id = g_contact.contact_id THEN 
			LET tmp_one_role = get_one_acc_role(g_bank_acc.acc_id,a_all_acc_owners[cnt].contact_id) 

			SELECT * INTO g_contact_bank_acc.* 
			FROM contact_bank_acc 
			WHERE contact_bank_acc.acc_id = g_bank_acc.acc_id 
			AND contact_bank_acc.contact_id = a_all_acc_owners[cnt].contact_id 
			AND contact_bank_acc.role_code = tmp_one_role 

		ELSE 
			IF any_contact THEN 
				LET tmp_one_role = get_one_acc_role(g_bank_acc.acc_id,a_all_acc_owners[cnt].contact_id) 

				SELECT * INTO g_contact_bank_acc.* 
				FROM contact_bank_acc 
				WHERE contact_bank_acc.acc_id = g_bank_acc.acc_id 
				AND contact_bank_acc.acc_id = a_all_acc_owners[cnt].contact_id 
				AND contact_bank_acc.role_code = tmp_one_role 
				AND valid_to IS NULL OR valid_to > today 
			END IF 
		END IF 

		LET cnt = cnt + 1 

		IF cnt = 41 THEN 
			ERROR "Cannot fit more THEN 40 owners" 
				SLEEP 2 
				EXIT FOREACH 
			END IF 

			###########
		END FOREACH 
		###########

		CLOSE c_acntct 
		FREE c_acntct 
		MESSAGE "" 

		LET all_acc_owners_cnt = cnt - 1 

		IF all_acc_owners_cnt > 1 THEN 
			MESSAGE "WARNING: This bank account belongs TO multiple Contacts !" 
			attribute (red) 
			SLEEP 3 
		END IF 

END FUNCTION #get_acc_owners() 


##############################################
FUNCTION list_all_acc_owners(tmp_acc_id) 
	##############################################
	DEFINE 
	tmp_acc_id LIKE bank_acc.acc_id, 
	a_names array[40] OF RECORD 
		NAME CHAR(15) 
	END RECORD, 
	cnt 
	SMALLINT, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	tmp_name CHAR(100) 

	OPEN WINDOW w_allownacc_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	MESSAGE "SELECT AND press Accept" 

	#################################
	FOR cnt = 1 TO all_acc_owners_cnt 
		#################################

		CALL get_contact_name(a_all_acc_owners[cnt].contact_id) RETURNING tmp_first, tmp_last 

		IF length(tmp_first) > 0 THEN 
			LET tmp_name = tmp_first clipped, " ", tmp_last clipped 
		ELSE 
			LET tmp_name = tmp_last clipped 
		END IF 

		LET a_names[cnt].name = tmp_name [1,15] 


		IF cnt = 40 THEN 
			ERROR "Cannot fit ", all_acc_owners_cnt, " owners." 
			SLEEP 2 
			EXIT FOR 
		END IF 


		#######
	END FOR 
	#######

	CALL set_count(cnt-1) 

	DISPLAY ARRAY a_names TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_bank","display_arr-a_names-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 


	LET cnt = arr_curr() #scr_line() 

	CLOSE WINDOW w_allownacc_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	RETURN a_all_acc_owners[cnt].contact_id 


END FUNCTION #list_all_acc_owners() 

#----


#####################################################################
FUNCTION change_acc_role(and_remove,new_acc_role_code,new_acc_role_name, 
	p_contact_id,p_bank_acc_id,p_acc_role_code) 
	#####################################################################
	DEFINE 
	changed, 
	tmp_cnt, 
	and_remove 
	SMALLINT, 
	new_acc_role_code, 
	p_acc_role_code 
	LIKE role.role_code, 
	new_acc_role_name 
	LIKE role.role_name, 
	p_contact_id 
	LIKE contact.contact_id, 
	p_bank_acc_id 
	LIKE bank_acc.acc_id 



	IF and_remove THEN 
		MESSAGE "Do you realy want TO remove selected role ?" 
		attribute (red) 
	ELSE 
		MESSAGE "Do you realy want TO change selected role TO ", 
		new_acc_role_name clipped, " ?" 
		attribute (red) 
	END IF 


	MENU "Change role" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_bank","menu-Change_role-1") -- albo kd-513 

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
				UPDATE contact_bank_acc 
				SET valid_to = today 
				WHERE contact_id = p_contact_id 
				AND bank_acc_id = p_bank_acc_id 
				AND role_code = p_acc_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact bank_acc: aborted !" 
					SLEEP 5 
					LET changed = false 
				ELSE 
					LET changed = true 
				END IF 

				SELECT count (*) INTO tmp_cnt 
				FROM contact_bank_acc 
				WHERE bank_acc_id = p_bank_acc_id 
				AND (valid_to IS NULL OR valid_to > today) 


				IF tmp_cnt = 0 THEN # no valid relations TO this bank_acc FROM any contact 
					UPDATE bank_acc 
					SET valid_to = today 
					WHERE bank_acc_id = p_bank_acc_id 
				END IF 

			ELSE #change 

				IF do_debug THEN 

					CALL errorlog(p_contact_id) 
					#        CALL errorlog(p_bank_acc_id)
					#        CALL errorlog(p_acc_role_code)
					#        CALL errorlog(new_acc_role_code)
				END IF 


				UPDATE contact_bank_acc 
				SET role_code = new_acc_role_code 
				WHERE contact_id = p_contact_id 
				AND bank_acc_id = p_bank_acc_id 
				AND role_code = p_acc_role_code 

				IF status <> 0 THEN 
					ERROR "Cannot UPDATE contact bank_acc: aborted !" 
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

END FUNCTION #change_acc_role() 

###################################################### module end



