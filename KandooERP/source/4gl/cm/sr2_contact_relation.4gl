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
 * contact contact relation functions
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
all_relations 
CHAR(50) 


########################
FUNCTION relation_menu() 
	########################
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
	tmp_contact_id LIKE contact.contact_id 


	MESSAGE"" 
	CALL init_contact_relation() 

	CURRENT WINDOW IS w_contact 

	MENU "contact relation" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_relation","menu-contact_relation-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Add (new relation)" "Add a new relation FOR this contact" 
			MESSAGE"" 
			CALL init_contact_relation() 
			LET changed = new_contact_relation() 
			IF changed THEN 
				#LET dummy = all_contact_relations('2', TRUE,FALSE) #disp_format,and_exit
				CALL init_contact_relation() 
			ELSE 
				CURRENT WINDOW IS w_info 
			END IF 

		COMMAND KEY ("r","R") "all Relations" "DISPLAY all valid relation info on this contact" 
			MESSAGE"" 
			CALL init_contact_relation() 
			CALL all_contact_relations(2,false,false) #disp_format,and_exit,history 
			RETURNING success, tmp_contact_id 

			IF 
			tmp_contact_id IS NOT NULL 
			THEN 
				IF 
				tmp_contact_id <> g_contact.contact_id 
				THEN 
					CALL get_contact_name(tmp_contact_id) RETURNING tmp_first, tmp_last 

					LET g_msg = "Switch current contact TO ", 
					tmp_first clipped, " ", tmp_last clipped, " ?" 

					MESSAGE g_msg clipped 

					MENU "Switch" 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","contact_relation","menu-Switch-1") -- albo kd-513 

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
					ERROR "This relationship belongs TO the current contact: Cannot switch" 
					#this IS actially impossible
				END IF 
			END IF 

			#        COMMAND "Switch" "SELECT a contact FROM this contact's relationships list TO switch TO"


		COMMAND "History" "DISPLAY all historycal contact relation info" 
			MESSAGE"" 
			CALL init_contact_relation() 
			CALL all_contact_relations(2,true,true) 
			RETURNING success, tmp_contact_id 


		COMMAND "Delete" "Mark contact relation as no longer valid" 
			MESSAGE"" 
			CALL init_contact_relation() 
			CALL all_contact_relations('2', false,false) #disp_format,and_exit,hist 
			RETURNING changed, tmp_contact_id 
			IF changed THEN 
				CALL all_contact_relations('2', true,false) #disp_format,and_exit 
				RETURNING dummy, tmp_contact_id 
			END IF 

		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE"" 
			EXIT MENU 

	END MENU 

	CALL clr_menudesc() 

END FUNCTION #contact_relation_menu() 

###############################
FUNCTION init_contact_relation() 
	###############################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_contact_relations 

	LET current_contact_relation_form = 1 

	MESSAGE "All relations of this contact:" 

	CALL all_contact_relations('2', true,false) #disp_format,and_exit,hist 
	RETURNING dummy, dummy 

END FUNCTION #init_contact_relation() 


###############################
FUNCTION del_contact_relation() 
	###############################
	DEFINE 
	success 
	SMALLINT 

	LET success = false 

	MESSAGE "Mark this contact relation information as deleted?" 

	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_relation","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE "" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE "" 
			UPDATE contact_relation SET 
			valid_to = today 
			WHERE 
			contact_relation.role_code = g_contact_relation.role_code 
			AND 
			contact_relation.contact_id_sec = g_contact_relation.contact_id_sec 
			AND 
			contact_relation.contact_id_pri = g_contact_relation.contact_id_pri 
			AND 
			contact_relation.valid_from = g_contact_relation.valid_from 
			AND 
			(contact_relation.valid_to = g_contact_relation.valid_to 
			OR 
			contact_relation.valid_to IS null) 

			IF status <> 0 THEN 
				ERROR "Error updating relation, STATUS IS = ", status 
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

END FUNCTION #d_contact_relation() 


##############################
FUNCTION new_contact_relation() 
	##############################
	DEFINE 
	new_relation_name LIKE role.role_name, 
	new_relation_code LIKE role.role_code, 
	new_contact_id_sec LIKE contact_relation.contact_id_sec, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	CALL role_lp("RELATION") 
	RETURNING new_relation_code, new_relation_name 

	IF new_relation_code IS NULL THEN 
		RETURN false 
	END IF 

	#SELECT contact TO which this relation will be established
	SELECT last_org_name, first_name 
	INTO tmp_last, tmp_first 
	FROM contact 
	WHERE contact_id = g_contact_relation.contact_id_pri 
	AND valid_to IS NULL OR valid_to > today 



	LET g_msg = "You are Selecting a new contact in relationship TO ", 
	tmp_first clipped , " ", tmp_last clipped 
	MESSAGE g_msg attribute (red) 
	LET new_contact_id_sec = select_contact(g_contact.contact_id,gv_null) #initial_contact_id 
	MESSAGE "" 

	IF new_contact_id_sec IS NULL THEN 
		RETURN false 
	END IF 

	IF 
	duplicate_contact_relation(new_relation_code, new_contact_id_sec) 
	THEN 
		ERROR "This contact already have this relation with selected new contact !" 
		SLEEP 2 
		RETURN false 
	ELSE 
		INSERT INTO contact_relation VALUES 
		( 
		g_contact.contact_id, 
		new_contact_id_sec, 
		new_relation_code, 
		today, 
		"" 
		) 

		RETURN true 
	END IF 

END FUNCTION #new_contact_relation() 

#########################################################################
FUNCTION duplicate_contact_relation(new_relation_code,new_sec_contact_id) 
	#########################################################################
	DEFINE 
	new_relation_code LIKE role.role_code, 
	new_sec_contact_id LIKE contact_relation.contact_id_sec 


	SELECT * FROM contact_relation 
	WHERE 
	role_code = new_relation_code 
	AND 
	((contact_id_pri = g_contact.contact_id 
	AND 
	contact_id_sec = new_sec_contact_id) 
	OR 
	(contact_id_sec = g_contact.contact_id 
	AND 
	contact_id_pri = new_sec_contact_id)) 

	IF status <> notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION #duplicate_contact_relation() 

###########################################################
FUNCTION all_contact_relations(disp_format,and_exit,history) 
	###########################################################
	DEFINE 
	a_contact_relation ARRAY [100] OF RECORD 
		contact_id_pri LIKE contact_relation.contact_id_pri, 
		contact_id_sec LIKE contact_relation.contact_id_sec, 
		relation_code LIKE role.role_code, 
		valid_from LIKE contact_relation.valid_from, 
		valid_to LIKE contact_relation.valid_to 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		relation_name LIKE role.role_name, 
		valid_from LIKE contact_relation.valid_from, 
		valid_to LIKE contact_relation.valid_to, 
		relation_to CHAR(39) 
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
	msg_2 CHAR (20), 

	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	tmp_contact_id LIKE contact.contact_id 


	LET changed = false 
	#    CALL init_contact_relation()
	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_all_relations with FORM "all_relation" 
			CALL winDecoration("all_relation") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_contact_relation_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_relation_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_contact_relations #maybe i'm comming FROM somewhere ELSE 

	END CASE 


	LET where_part = 
	"SELECT * FROM contact_relation WHERE (contact_id_pri = ",g_contact.contact_id, 
	" OR contact_id_sec = ",g_contact.contact_id, ")" 

	IF 
	#show_valid
	NOT history 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_relation.valid_to IS NULL OR contact_relation.valid_to > TODAY)" 

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
	PREPARE relationx12 FROM where_part 
	DECLARE c_all_per_relation CURSOR FOR relationx12 

	LET cnt = 1 

	##########################################################
	FOREACH c_all_per_relation INTO a_contact_relation[cnt].* 
		##########################################################

		SELECT role_name INTO a_display[cnt].relation_name 
		FROM role 
		WHERE role_code = a_contact_relation[cnt].relation_code 
		AND class_name = "RELATION" 


		IF a_contact_relation[cnt].contact_id_sec <> g_contact.contact_id THEN 
			SELECT last_org_name, first_name 
			INTO tmp_last, tmp_first 
			FROM contact 
			WHERE contact_id = a_contact_relation[cnt].contact_id_sec 
			AND valid_to IS NULL OR valid_to > today 
		ELSE 
			SELECT last_org_name, first_name 
			INTO tmp_last, tmp_first 
			FROM contact 
			WHERE contact_id = a_contact_relation[cnt].contact_id_pri 
			AND valid_to IS NULL OR valid_to > today 


		END IF 
		LET a_display[cnt].relation_to = tmp_first clipped, " ", tmp_last clipped 

		LET a_display[cnt].valid_from = a_contact_relation[cnt].valid_from 
		LET a_display[cnt].valid_to = a_contact_relation[cnt].valid_to 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_all_per_relation 
	FREE c_all_per_relation 
	MESSAGE "" 
	CALL set_count(cnt) 


	IF and_exit THEN 
		MESSAGE "All relations FOR this contact", msg_2 clipped 
	ELSE 
		MESSAGE "All relations FOR this contact", msg_2 clipped, " (F5=delete,ESC=switch,Abort=EXIT)" 
	END IF 

	IF cnt = 0 THEN 
		MESSAGE "This contact has no defined relations" 
		RETURN changed, gv_null 
	END IF 


	#########################################
	DISPLAY ARRAY a_display TO s_display.* 
	#########################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_relation","display_arr-a_display-1") -- albo kd-513 

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
			LET g_contact_relation.* = a_contact_relation[cnt].* 
			LET success = del_contact_relation() 
			IF success THEN 
				LET changed = true 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
			END IF 


			###########
	END DISPLAY 
	{! END DISPLAY !}
	###########

	#    MESSAGE ""

	CASE disp_format 
		WHEN 1 #big new WINDOW 
			CLOSE WINDOW w_all_relations 

		WHEN 2 
			#			DISPLAY FORM f_contact_relation1
			#			CALL display_contact_relation()
	END CASE 


	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null, gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	IF 
	a_contact_relation[cnt].contact_id_pri = g_contact.contact_id 
	THEN 
		LET tmp_contact_id = a_contact_relation[cnt].contact_id_sec 
	ELSE 
		LET tmp_contact_id = a_contact_relation[cnt].contact_id_pri 
	END IF 

	RETURN changed, tmp_contact_id 

END FUNCTION #all_contact_relations() 


###################################################### module end
