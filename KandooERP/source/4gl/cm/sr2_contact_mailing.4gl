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
 * contact mailing functions
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
all_mailings 
CHAR(50) 

#######################
FUNCTION mailing_menu() 
	#######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success, 
	changed 
	SMALLINT, 
	acc_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	p_mailing_role_code LIKE mailing_dates.mailing_role_code, 
	p_mail_date LIKE mailing_dates.mail_date 


	MESSAGE"" 
	CALL init_contact_mailing() 

	CURRENT WINDOW IS w_contact 

	MENU "Contact mailing" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_mailing","menu-Contact_mailing-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Add (new mailing)" "Add a new mailing FOR this contact" 
			MESSAGE"" 
			CALL init_mailing_win() 
			LET changed = new_contact_mailing() 
			IF changed THEN 
				LET dummy = all_contact_mailings('2', true,false) #disp_format,and_exit 
			END IF 

		COMMAND "all Mailings" "DISPLAY all valid mailing info on this contact" 
			MESSAGE"" 
			CALL init_mailing_win() 
			LET success = all_contact_mailings(2,true,false) 

		COMMAND "History" "DISPLAY all historycal contact mailing info" 
			MESSAGE"" 
			CALL init_mailing_win() 
			LET success = all_contact_mailings(2,true,true) 


		COMMAND "Delete" "Mark contact mailing as no longer valid" 
			MESSAGE"" 
			CALL init_mailing_win() 
			LET changed= all_contact_mailings('2', false,false) #disp_format,and_exit,hist 
			IF changed THEN 
				LET dummy = all_contact_mailings('2', true,false) #disp_format,and_exit 
			END IF 

		COMMAND "Show address" "Show the address used FOR an mailing" 
			MESSAGE"" 
			CALL init_mailing_win() 
			LET changed= all_contact_mailings('2', false,true) #disp_format,and_exit,hist 
			IF changed THEN 
				LET dummy = all_contact_mailings('2', true,false) #disp_format,and_exit 
			END IF 

		COMMAND KEY ("e","E") "mailing Events" "Maintain mailing event menu (ALL CONTACTS)" 
			CALL init_mailing_win() 
			CALL m_mailing_dates() #mailntain.4gl 

		COMMAND KEY ("r","R") "mailing Roles" "Maintain Mail role definitions menu (ALL CONTACTS)" 
			CALL init_mailing_win() 
			CALL m_mailing_role() #maintain.4gl 

		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #contact_mailing_menu() 

##############################
FUNCTION init_contact_mailing() 
	##############################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	CALL init_mailing_win() 

	MESSAGE "All mailings of this contact:" 

	LET dummy = all_contact_mailings('2', true,false) #disp_format,and_exit,hist 

END FUNCTION #init_contact_mailing() 

###########################
FUNCTION init_mailing_win() 
	###########################

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_contact_mailings 

	LET current_contact_mailing_form = 1 

END FUNCTION 


##############################
FUNCTION del_contact_mailing() 
	##############################
	DEFINE 
	success 
	SMALLINT, 
	new_termination_code LIKE role.role_code, 
	new_termination_name LIKE role.role_name 

	LET success = false 

	MESSAGE "Mark this contact mailing information as deleted?" 

	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_mailing","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 


			CALL role_lp("MAIL TERMINATION") 
			RETURNING new_termination_code, new_termination_name 

			IF new_termination_code IS NULL THEN 
				RETURN false 
			END IF 

			MESSAGE "" 
			UPDATE contact_mailing SET 
			valid_to = today, 
			termination_code = new_termination_code, 
			user_id_terminated = glob_rec_kandoouser.sign_on_code 
			WHERE 
			contact_mailing.mailing_id = g_contact_mailing.mailing_id 

			IF status <> 0 THEN 
				ERROR "Error updating mailing, STATUS IS = ", status 
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

END FUNCTION #d_contact_mailing() 


#############################
FUNCTION new_contact_mailing() 
	#############################
	DEFINE 
	new_mailing_name LIKE mailing_role.mailing_name, 
	new_mailing_role_code LIKE mailing_role.mailing_role_code, 
	new_address_id LIKE address.address_id 


	CALL mailing_role_lp(false) 
	RETURNING new_mailing_role_code, new_mailing_name 

	IF new_mailing_role_code IS NULL THEN 
		RETURN false 
	END IF 

	LET new_address_id = address_hist("2",FALSE, false) #disp_format,and_exit,and_hist contact_address.4gl 
	DISPLAY FORM f_contact_mailings 

	IF new_address_id IS NULL THEN 
		RETURN false 
	END IF 

	IF 
	duplicate_contact_mailing(new_mailing_role_code, new_address_id) 
	THEN 
		ERROR "This contact already have this mailing on selected address!" 
		SLEEP 2 
		RETURN false 
	ELSE 


		INSERT INTO contact_mailing VALUES 

		( 
		0, 
		g_contact.contact_id, 
		new_mailing_role_code, 
		new_address_id, 
		today, 
		"", #valid_to 
		"", #termination_code 
		"") #user_id_retminated 

		RETURN true 
	END IF 

END FUNCTION #new_contact_mailing() 

##################################################################
FUNCTION duplicate_contact_mailing(new_mailing_role_code,new_address_id) 
	##################################################################
	DEFINE 
	new_mailing_role_code LIKE mailing_role.mailing_role_code, 
	new_address_id LIKE address.address_id 


	SELECT * FROM contact_mailing 
	WHERE contact_id = g_contact.contact_id 
	AND 
	mailing_role_code = new_mailing_role_code 
	AND 
	address_id = new_address_id 
	AND 
	valid_to IS NULL OR valid_to > today 

	IF status <> notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_contact_mailing() 

################################################
FUNCTION all_contact_mailings(disp_format,and_exit,history) 
	################################################
	DEFINE 
	a_contact_mailing ARRAY [100] OF RECORD 
		mailing_id LIKE contact_mailing.mailing_id, 
		contact_id LIKE contact_mailing.contact_id, 
		mailing_role_code LIKE contact_mailing.mailing_role_code, 
		address_id LIKE contact_mailing.address_id, 
		valid_from LIKE contact_mailing.valid_from, 
		valid_to LIKE contact_mailing.valid_to, 
		termination_code LIKE contact_mailing.termination_code, 
		user_id_terminated LIKE contact_mailing.user_id_terminated 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		mailing_name LIKE mailing_role.mailing_name, 
		valid_from LIKE contact_mailing.valid_from, 
		valid_to LIKE contact_mailing.valid_to, 
		address_id LIKE contact_mailing.address_id, 
		termination_name LIKE role.role_name 

	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	history, 
	changed, 
	success 
	SMALLINT, 
	where_part 
	CHAR(300), 
	msg_2 CHAR (20) 

	LET changed = false 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_mailings with FORM "all_mailing" 
			CALL winDecoration("all_mailing") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_contact_mailing_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_mailing_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_contact_mailings #maybe i'm comming FROM somewhere ELSE 

	END CASE 


	LET where_part = 
	"SELECT * FROM contact_mailing WHERE contact_id = ",g_contact.contact_id 
	IF 
	#show_valid
	NOT history 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_mailing.valid_to IS NULL OR contact_mailing.valid_to > TODAY)" 

		LET msg_2 = ", valid only" 
	ELSE 
		LET msg_2 = ", including history" 
	END IF 

	LET where_part = where_part clipped, 
	" ORDER BY valid_from desc " 
	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE mailingx12 FROM where_part 
	DECLARE c_all_per_mailings CURSOR FOR mailingx12 

	LET cnt = 1 

	#######################################################
	FOREACH c_all_per_mailings INTO a_contact_mailing[cnt].* 
		#######################################################

		SELECT mailing_name INTO a_display[cnt].mailing_name 
		FROM mailing_role 
		WHERE mailing_role_code = a_contact_mailing[cnt].mailing_role_code 

		IF a_contact_mailing[cnt].termination_code IS NOT NULL THEN 
			SELECT termination_name INTO a_display[cnt].termination_name 
			FROM mail_termination 
			WHERE termination_code = a_contact_mailing[cnt].termination_code 
		END IF 

		LET a_display[cnt].valid_from = a_contact_mailing[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_mailing[cnt].valid_to 
		LET a_display[cnt].address_id = a_contact_mailing[cnt].address_id 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_all_per_mailings 
	FREE c_all_per_mailings 
	MESSAGE "" 
	CALL set_count(cnt) 


	IF and_exit THEN 
		MESSAGE "All mailings FOR this contact", msg_2 clipped 
	ELSE 
		MESSAGE "All mailings FOR this contact", msg_2 clipped, " (F5=delete, F10=show addr)" 
	END IF 

	IF cnt = 0 THEN 
		MESSAGE "This contact has no defined mailings" 
		RETURN changed 
	END IF 


	#########################################
	DISPLAY ARRAY a_display TO s_display.* 
	#########################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_mailing","display_arr-a_display-1") -- albo kd-513 

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
		ON KEY ("F5") #delete 
			{! ON KEY ("F5")      #delete !}
			##############
			LET cnt = arr_curr() #scr_line() 
			LET g_contact_mailing.* = a_contact_mailing[cnt].* 
			LET success = del_contact_mailing() 
			IF success THEN 
				LET changed = true 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 

			##############
		ON KEY ("F10") #show address 
			{! ON KEY ("F10")      #show address !}
			##############
			LET cnt = arr_curr() #scr_line() 
			LET g_contact_mailing.* = a_contact_mailing[cnt].* 
			#            CALL show_addr(a_contact_mailing[cnt].address_id) #g_contact_mailing.address_id
			#            error cnt sleep 3
			#            error a_display[cnt].address_id sleep 3
			CALL show_addr(a_display[cnt].address_id) #g_contact_mailing.address_id 
			###########
	END DISPLAY 
	{! END DISPLAY !}
	###########

	#    MESSAGE ""

	CASE disp_format 
		WHEN 1 #big new WINDOW 
			CLOSE WINDOW w_all_mailings 

		WHEN 2 
			#			DISPLAY FORM f_contact_mailing1
			#			CALL display_contact_mailing()
	END CASE 


	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN changed 

END FUNCTION #all_contact_mailings() 



###################################################### module end
