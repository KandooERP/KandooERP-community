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
 * contact comment functions
 *
 * @author: Andrej Falout
 *
 *}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 

###############################
FUNCTION contact_comment_menu() 
	###############################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200), 
	success 
	SMALLINT, 
	comment_id 
	INTEGER, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	INITIALIZE g_contact_comment.* TO NULL 
	LET comment_cursor = false 

	MESSAGE "" 
	CALL init_comment() 

	CURRENT WINDOW IS w_contact 

	MENU "Comment" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_comment","menu-Comment-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query by comment data" 
			MESSAGE "" 
			CALL init_comment_win() 
			CALL qbe_comment(false) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_comment_cursor(send1, send2, send3) 
			END IF 

		COMMAND "+" "Next found" 
			MESSAGE "" 
			CALL init_comment_win() 
			CALL n_comment() 

		COMMAND "-" "Previous found" 
			MESSAGE "" 
			CALL init_comment_win() 
			CALL p_comment() 

		COMMAND "Add" "Add new comment FOR this contact" 
			MESSAGE "" 
			CALL init_comment_win() 
			LET success = au_contact_comment(g_contact.contact_id,true) 

		COMMAND "Edit" "Modify current comment" 
			MESSAGE "" 
			CALL init_comment_win() 
			IF 
			g_contact_comment.date_closed IS NOT NULL 
			THEN 
				ERROR "This comment IS resolved - closed: cannot modify" 
				SLEEP 2 
			ELSE 
				IF g_contact_comment.contact_id <> g_contact.contact_id THEN 
					ERROR "This comment does NOT belongs TO current contact; cannot modify" 
				ELSE 
					LET success = au_contact_comment(g_contact.contact_id,false) 
				END IF 
			END IF 


		COMMAND "History" "DISPLAY all historycal comment info" 
			MESSAGE "" 
			CALL init_comment_win() 
			LET comment_id = comment_hist("2",FALSE,FALSE) 
			IF 
			comment_id IS NOT NULL 
			THEN 
				DISPLAY FORM f_comment1 
				CALL display_comment() 
				CALL disp_selected_comment(comment_id) 
			END IF 

		COMMAND "Delete" "Mark current comment resolved" 
			MESSAGE "" 
			CALL init_comment_win() 
			IF 
			g_contact_comment.date_closed IS NOT NULL 
			THEN 
				ERROR "This comment IS resolved - closed: cannot resolve" 
				SLEEP 2 
			ELSE 
				IF g_contact_comment.contact_id <> g_contact.contact_id THEN 
					ERROR "This comment does NOT belongs TO current contact; cannot modify" 
				ELSE 
					CALL del_comment() 
				END IF 
			END IF 

		COMMAND KEY ("c","C") "any Comment" "Query FOR any contact comment" 
			MESSAGE "" 
			CALL init_comment_win() 
			CALL qbe_comment(true) RETURNING send1, send2, send3 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				CALL open_comment_cursor(send1, send2, send3) 
			END IF 


		COMMAND "Switch" "Switch current contact TO the one that the displayed comment belongs TO" 

			IF g_contact_comment.contact_id <> g_contact.contact_id THEN 
				SELECT last_org_name, first_name 
				INTO tmp_last, tmp_first 
				FROM contact 
				WHERE contact_id = g_contact_comment.contact_id 
				AND valid_to IS NULL OR valid_to > today 


				LET g_msg = "Switch current contact TO ", 
				tmp_first clipped, " ", tmp_last clipped, " ?" 

				MESSAGE g_msg clipped 

				MENU "Switch" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","contact_comment","menu-Switch-1") -- albo kd-513 

					ON ACTION "WEB-HELP" -- albo 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Cancel" "Do NOT switch TO new contact" 
						MESSAGE "" 
						EXIT MENU 

					COMMAND "OK" "Yes, switch TO the contact that the current comment belongs TO" 
						MESSAGE "" 
						CALL switch_contact(g_contact_comment.contact_id) 

						EXIT MENU 
				END MENU 

				MESSAGE "" 

			ELSE 
				ERROR "This comment belongs TO the current contact: Cannot switch" 
			END IF 


		COMMAND KEY ("x","X",interrupt,escape) "eXit" "Exit TO the previous menu" 
			MESSAGE "" 
			EXIT MENU 

	END MENU 

	OPTIONS MESSAGE line FIRST + 1 
	MESSAGE "" #clear MENU desctiption text 
	OPTIONS MESSAGE line FIRST 

END FUNCTION 

######################
FUNCTION init_comment() 
	######################
	DEFINE 
	send1, send2, send3 #where_part 
	CHAR (200) 

	#already opmen FOR Info !
	#	OPEN WINDOW w_comment
	#        AT 12,2 with 13 rows, 75 columns
	#			attribute (border)

	#    CURRENT WINDOW IS w_info
	#	DISPLAY FORM f_comment1
	#	DISPLAY FORM f_all_comment
	#    LET current_comm_form = 2
	CALL init_comment_win() 

	LET send1 = " contact_comment.contact_id = ", g_contact.contact_id, " " 
	INITIALIZE send2, send3 TO NULL 

	CALL comment_where_part(send1, send2, send3) 
	RETURNING send1, send2, send3 

	CALL open_comment_cursor(send1, send2, send3) 


	#    LET dummy = comment_hist("2",TRUE,TRUE)

END FUNCTION #init_comment() 


#########################
FUNCTION init_comment_win() 
	#########################
	CURRENT WINDOW IS w_info 

	DISPLAY FORM f_all_comment 

	LET current_comm_form = 2 

END FUNCTION #init_comment_win() 



################################
FUNCTION qbe_comment(any_contact) 
	################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200), 
	any_contact 
	SMALLINT 

	IF current_comm_form <> 1 THEN 
		CALL d_comment1() 
	END IF 

	CLEAR FORM 

	MESSAGE "Enter query condition AND press Accept" 

	CONSTRUCT where_part ON 
	comment.comment_text, 
	contact_comment.date_entered, 
	contact_comment.user_id_entered, 
	contact_comment.date_modified, 
	contact_comment.user_id_modified, 
	contact_comment.date_closed 

	FROM 
	s_comment_text.comment_text, 
	s_comment.date_entered, 
	s_comment.user_id_entered, 
	s_comment.date_modified, 
	s_comment.user_id_modified, 
	s_comment.date_closed 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","contact_comment","construct-contact_comment-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 


	MESSAGE "" 


	IF 
	show_valid 
	THEN 
		LET where_part = where_part clipped, 
		" AND (contact_comment.date_closed IS NULL) " 
	END IF 

	IF NOT any_contact THEN 
		LET where_part = where_part clipped, 
		" AND contact_comment.contact_id = ", g_contact.contact_id, " " 
	END IF 


	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	CALL comment_where_part(send1, send2, send3) 
	RETURNING send1, send2, send3 

	#    LET last_comm_where_part = where_part

	RETURN send1, send2, send3 #where_part 

END FUNCTION #qbe_comment() 


##############################################
FUNCTION comment_where_part(send1, send2, send3) 
	##############################################
	DEFINE 
	where_part, 
	received_where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200) 

	LET received_where_part = send1, send2, send3 

	LET where_part = "SELECT unique contact_comment.* ", 
	" FROM contact_comment " 

	IF received_where_part matches "*comment.comment_text*" THEN 
		LET where_part = where_part clipped, 
		", comment " 
	END IF 

	LET where_part = where_part clipped, 
	" WHERE ", received_where_part clipped 
	IF received_where_part matches "*comment.comment_text*" THEN 
		LET where_part = where_part clipped, 
		" AND comment.comment_id = contact_comment.comment_id " 
	END IF 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 

	LET send1 = where_part[1,200] 
	LET send2 = where_part[201,400] 
	LET send3 = where_part[401,600] 

	RETURN send1, send2, send3 #where_part 

END FUNCTION #comment_where_part() 

##############################################
FUNCTION open_comment_cursor(send1, send2, send3) 
	##############################################
	DEFINE 
	where_part 
	CHAR (600), 
	send1, send2, send3 #function calls are limited TO 200 CHAR 
	CHAR (200) 

	LET where_part = send1, send2, send3 

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE x3 FROM where_part 
	DECLARE c_read_comment SCROLL CURSOR with HOLD FOR x3 
	OPEN c_read_comment 

	FETCH FIRST c_read_comment INTO g_contact_comment.* 

	LET comment_cursor = true 

	IF 
	status = notfound 
	THEN 
		MESSAGE "" 
		ERROR "No records found" 
		INITIALIZE g_contact_comment.* TO NULL 
		CALL init_comment_arr() 
		#CLEAR field ... #form
	ELSE 
		MESSAGE "" 
		CALL display_comment() 
	END IF 

END FUNCTION #read_qbf() 

###################
FUNCTION n_comment() 
	###################

	IF 
	g_contact_comment.comment_id IS NULL 
	OR 
	NOT comment_cursor 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 

	FETCH NEXT c_read_comment INTO g_contact_comment.* 

	IF 
	status = notfound 
	THEN 
		CALL display_comment() 
		ERROR "No more records found" 
	ELSE 
		CALL display_comment() 
	END IF 

END FUNCTION #read_next() 

###################
FUNCTION p_comment() 
	###################

	IF 
	g_contact_comment.comment_id IS NULL 
	OR 
	NOT comment_cursor 
	THEN 
		ERROR "Please enter Query condition first !" 
		RETURN 
	END IF 


	FETCH previous c_read_comment INTO g_contact_comment.* 
	IF status = notfound THEN 
		CALL display_comment() 
		ERROR "No previous records found" 
	ELSE 
		CALL display_comment() 
	END IF 

END FUNCTION #read_previous() 


####################################################
FUNCTION au_contact_comment(tmp_contact_id,add_mode) 
	####################################################
	DEFINE 
	tmp_contact_id LIKE contact.contact_id, 
	add_mode, 
	success, 
	arr_changed, 
	added_lines, 
	deleted_lines, 
	store_comment_arr_full 
	SMALLINT, 
	a_store_comment array[10] OF RECORD 
		comment_line_id LIKE comment.comment_line_id, 
		comment_id LIKE comment.comment_id, 
		comment_text LIKE comment.comment_text 
	END RECORD, 
	a_comment_input array[10] OF RECORD 
		comment_text LIKE comment.comment_text 
	END RECORD, 

	store_contact_comment 
	RECORD LIKE contact_comment.* 


		LET store_comment_arr_full = comment_arr_full 

		IF current_comm_form <> 1 THEN 
			CALL d_comment1() 
		END IF 

		IF add_mode THEN 
			MESSAGE "Enter comment AND press Accept" 
			INITIALIZE g_comment TO NULL 
			CALL init_comment_arr() 
			INITIALIZE g_contact_comment TO NULL 
			CLEAR FORM 
		ELSE 

			MESSAGE "Enter changes AND press Accept" 

			LET store_contact_comment.* = g_contact_comment.* 

			IF comment_arr_full > 0 THEN 
				###############################
				FOR cnt = 1 TO comment_arr_full 
					###############################

					LET a_store_comment[cnt].* = a_comment[cnt].* 
					LET a_comment_input[cnt].comment_text = a_comment[cnt].comment_text 

					#######
				END FOR 
				#######

			END IF 

		END IF 

		#############
		INPUT ARRAY 
		#############

		a_comment_input 
		{
		            a_comment[1].comment_text,
		            a_comment[2].comment_text,
		            a_comment[3].comment_text,
		            a_comment[4].comment_text
		}
		WITHOUT DEFAULTS FROM 

		s_comment_text.* 
		{
		            s_comment_text[1].comment_text,
		            s_comment_text[2].comment_text,
		            s_comment_text[3].comment_text,
		            s_comment_text[4].comment_text
		}

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","contact_comment","input-arr-comment_input-1") -- albo kd-513 

			ON ACTION "WEB-HELP" -- albo 
				CALL onlinehelp(getmoduleid(),null) 

				###########
			AFTER INPUT 
				###########

				IF add_mode THEN 
					LET g_contact_comment.contact_id = g_contact.contact_id 
					LET g_contact_comment.comment_id = 0 
					LET g_contact_comment.user_id_entered = glob_rec_kandoouser.sign_on_code 
					LET g_contact_comment.date_entered = today 
				END IF 

				###############################
				FOR cnt = 1 TO comment_arr_max 
					###############################


					LET a_comment[cnt].comment_text = a_comment_input[cnt].comment_text 

					LET a_comment[cnt].comment_line_id = cnt 

					IF length (a_comment_input[cnt].comment_text) > 0 THEN 
						LET comment_arr_full = cnt 
					END IF 

					#######
				END FOR 
				#######


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

			LET arr_changed = false 

			###############################
			FOR cnt = 1 TO comment_arr_max 
				###############################

				#MESSAGE a_store_comment[cnt].comment_text clipped, "==",a_comment[cnt].comment_text clipped
				#sleep 3
				IF a_store_comment[cnt].comment_text <> a_comment[cnt].comment_text 
				OR length (a_store_comment[cnt].comment_text) <> length (a_comment[cnt].comment_text) THEN 
					#ERROR "Yesss!" sleep 2
					LET arr_changed = true 
					EXIT FOR 
				END IF 

				#######
			END FOR 
			#######


			IF 
			arr_changed 
			THEN 


				#       3                8                   5
				#      -2                3                   5

				LET added_lines = comment_arr_full - store_comment_arr_full 

				IF 
				added_lines < 0 
				THEN 
					LET added_lines = 0 
					#
					#       2                5                          3

					LET deleted_lines = store_comment_arr_full - comment_arr_full 
				END IF 

				MESSAGE deleted_lines, " lines deleted, ", added_lines, " added." SLEEP 3 

			ELSE 
				ERROR "Nothing changed: nothing TO UPDATE" 
				SLEEP 1 
				RETURN false 
			END IF 
		END IF 

		LET success = store_comment(add_mode,added_lines,deleted_lines) 

		RETURN success 

END FUNCTION #au_contact_comment() 

############################
FUNCTION init_comment_arr() 
	############################
	DEFINE 
	cnt 
	SMALLINT 

	###############################
	FOR cnt = 1 TO comment_arr_full 
		###############################

		INITIALIZE a_comment[cnt].* TO NULL 

		#######
	END FOR 
	#######


END FUNCTION #init_comment_arr() 

##########################################################
FUNCTION store_comment(add_mode,added_lines,deleted_lines) 
	##########################################################
	DEFINE 
	add_mode, 
	added_lines, 
	deleted_lines 
	SMALLINT 

	##########
	BEGIN WORK 
		##########

		IF NOT add_mode THEN #logical UPDATE 
			LET g_contact_comment.date_modified = today 
			LET g_contact_comment.user_id_modified = glob_rec_kandoouser.sign_on_code 

			UPDATE contact_comment 
			SET contact_comment.* = g_contact_comment.* 
			WHERE contact_comment.comment_id = g_contact_comment.comment_id 


			###############################################
			FOR cnt = 1 TO (comment_arr_full - added_lines) 
				###############################################
				#previously existing lines

				UPDATE comment 
				SET comment_text = a_comment[cnt].comment_text 
				WHERE comment_id = a_comment[cnt].comment_id 
				AND comment_line_id = a_comment[cnt].comment_line_id 

				#######
			END FOR 
			#######

			IF added_lines > 0 THEN 
				#new lines
				####################################################################
				FOR cnt = ((comment_arr_full - added_lines)+ 1) TO comment_arr_full 
					####################################################################

					LET a_comment[cnt].comment_line_id = cnt 
					LET a_comment[cnt].comment_id = g_contact_comment.comment_id 

					INSERT INTO comment VALUES (a_comment[cnt].*) 

					#######
				END FOR 
				#######
			END IF 

			IF deleted_lines > 0 THEN 
				DELETE FROM comment WHERE comment_id = g_contact_comment.comment_id 
				AND comment_line_id > comment_arr_full 
			END IF 


			######################
		ELSE #new comment 
			######################

			LET g_contact_comment.date_entered = today 
			LET g_contact_comment.user_id_entered = glob_rec_kandoouser.sign_on_code 
			LET g_contact_comment.contact_id = g_contact.contact_id 

			INSERT INTO contact_comment VALUES (g_contact_comment.*) 

			LET g_contact_comment.comment_id = sqlca.sqlerrd[2] 

			###############################
			FOR cnt = 1 TO comment_arr_full 
				###############################

				LET a_comment[cnt].comment_id = g_contact_comment.comment_id 
				LET a_comment[cnt].comment_line_id = cnt 

				INSERT INTO comment VALUES (a_comment[cnt].*) 

				#######
			END FOR 
			#######

		END IF 

		###########
	COMMIT WORK 
	###########

	RETURN true #success 


END FUNCTION #store_comment() 

#######################################################
FUNCTION comment_hist(disp_format,and_exit,only_active) 
	#######################################################
	DEFINE 

	a_display ARRAY [10] OF RECORD 
		display_text CHAR(70) 
	END RECORD, 

	a_comment_id ARRAY [10] OF RECORD 
		comment_id LIKE contact_comment.comment_id 
	END RECORD, 

	cnt, 
	disp_format, 
	and_exit, 
	only_active 
	SMALLINT, 
	tmp_comment_text 
	LIKE comment.comment_text 

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			OPEN WINDOW w_comm_hist with FORM "all_role" 
			CALL winDecoration("all_role") -- albo kd-766 

		WHEN 2 #small inside existing lower WINDOW 
			{
					    OPEN WINDOW w_comm_hist
				    	    AT 12,2 	#with 13 rows, 75 columns
					            WITH FORM "all_role_sml"
								attribute (border)
			}

			CURRENT WINDOW IS w_info 

			DISPLAY FORM f_all_comment 

	END CASE 
	MESSAGE "Searching...please wait" 
	DECLARE c_comm_hist CURSOR FOR 
	SELECT unique contact_comment.* FROM contact_comment 
	WHERE contact_comment.contact_id = g_contact.contact_id 
	ORDER BY contact_comment.date_entered, date_modified desc 


	LET cnt = 1 

	###########################################
	FOREACH c_comm_hist INTO g_contact_comment.* 
		###########################################
		IF only_active 
		AND g_contact_comment.date_closed IS NOT NULL THEN 
			CONTINUE FOREACH 
		END IF 

		LET a_comment_id[cnt].comment_id = g_contact_comment.comment_id 

		SELECT comment_text INTO tmp_comment_text 
		FROM comment 
		WHERE comment.comment_id = g_contact_comment.comment_id 
		AND comment_line_id = 1 


		LET a_display[cnt].display_text = 
		g_contact_comment.date_entered USING "dd/mm"," ", 
		tmp_comment_text[1,64] 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	LET cnt = cnt - 1 


	CLOSE c_comm_hist 
	FREE c_comm_hist 
	MESSAGE "" 
	CALL set_count(cnt) 

	IF and_exit THEN 
		IF only_active THEN 
			MESSAGE "All comments FOR this contact (Active only)" 
		ELSE 
			MESSAGE "All comments FOR this contact (Active AND History)" 
		END IF 
	ELSE 
		IF only_active THEN 
			MESSAGE "All comments FOR this contact (Active only) - SELECT AND press Accept" 
		ELSE 
			MESSAGE "All comments FOR this contact (Active AND History) - SELECT AND press Accept" 
		END IF 
	END IF 

	###################################
	DISPLAY ARRAY a_display TO s_info.* 
	###################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","contact_comment","display_arr-a_display-1") -- albo kd-513 

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

	#    MESSAGE ""

	CASE disp_format 
		WHEN 1 #big new WINDOW 

			CLOSE WINDOW w_comm_hist 
		WHEN 2 
			#			DISPLAY FORM f_comment1
			#			CALL display_comment()
	END CASE 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_comment_id[cnt].comment_id 

END FUNCTION #comment_hist() 


##########################
FUNCTION display_comment() 
	##########################
	DEFINE 
	a_comment_display array[10] OF RECORD 
		comment_text LIKE comment.comment_text 
	END RECORD, 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name 

	IF g_contact_comment.comment_id IS NULL THEN #to prevent uninitialised dates 
		#FROM displaying as 31/12/1899
		INITIALIZE g_comment.* TO NULL 
	END IF 

	IF g_contact_comment.contact_id <> g_contact.contact_id THEN 
		SELECT last_org_name, first_name 
		INTO tmp_last, tmp_first 
		FROM contact 
		WHERE contact_id = g_contact_comment.contact_id 
		AND valid_to IS NULL OR valid_to > today 

		ERROR "WARNING ! This comment does NOT belong TO current contact" 
		attribute (red) 
		MESSAGE "This comment belongs TO ",tmp_first clipped, " ", tmp_last clipped 
		attribute (red) 
	END IF 

	IF current_comm_form <> 1 THEN 
		DISPLAY FORM f_comment1 
		LET current_comm_form = 1 
	END IF 


	######################
	CASE current_comm_form 
	######################

		WHEN 1 #comment.per 
			DISPLAY BY NAME 
			g_contact_comment.date_entered, 
			g_contact_comment.user_id_entered, 
			g_contact_comment.date_modified, 
			g_contact_comment.user_id_modified, 
			g_contact_comment.date_closed 


			#load comment lines:
			MESSAGE "Searching...please wait" 
			DECLARE c_comment CURSOR FOR 
			SELECT * FROM comment 
			WHERE comment_id = g_contact_comment.comment_id 
			ORDER BY comment_line_id 

			LET cnt = 1 

			########################################
			FOREACH c_comment INTO a_comment[cnt].* 
				########################################

				LET a_comment_display[cnt].comment_text = a_comment[cnt].comment_text 

				LET cnt = cnt + 1 

				IF 
				comment_arr_max + 1 = cnt 
				THEN 
					#ERROR "Umph! Argggght!" sleep 2
					EXIT FOREACH 
				END IF 


				###########
			END FOREACH 
			###########

			LET comment_arr_full = cnt - 1 

			CALL set_count(comment_arr_full) 
			MESSAGE "" 

			###################################################
			DISPLAY ARRAY a_comment_display TO s_comment_text.* 
			###################################################

				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","contact_comment","display_arr-a_comment-1") -- albo kd-513 

				BEFORE ROW 
					{! BEFORE ROW !}
					EXIT DISPLAY 
					{! EXIT DISPLAY !}

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 

			END DISPLAY 
			{! END DISPLAY !}

			#         WHEN 2 #?.per

		OTHERWISE 

			ERROR "Unknown form: contact_comment.4gl, display_comment()" 
			EXIT program 
			########
	END CASE 
	########

END FUNCTION #display_comment() 


##########################################
FUNCTION disp_selected_comment(comment_id) 
	##########################################
	DEFINE 
	comment_id 
	SMALLINT, 
	send1, send2, send3 #where_part 
	CHAR (200) 


	IF comment_id IS NOT NULL THEN 
		LET send1 = " contact_comment.comment_id = ", comment_id 
		INITIALIZE send2, send3 TO NULL 

		CALL comment_where_part(send1, send2, send3) 
		RETURNING send1, send2, send3 

		CALL open_comment_cursor(send1, send2, send3) 
	END IF 
END FUNCTION 


####################
FUNCTION del_comment() 
	####################


	MESSAGE "Mark this comment resolved ?" 

	MENU "Confirm" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","contact_comment","menu-Confirm-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete this record" 
			MESSAGE"" 
			EXIT MENU 

		COMMAND "OK" "Delete this record" 
			MESSAGE"" 

			UPDATE contact_comment SET 
			date_closed = today 
			WHERE comment_id = g_contact_comment.comment_id 

			CLEAR FORM 
			EXIT MENU 
	END MENU 

END FUNCTION #del_comment() 

####################
FUNCTION d_comment1() 
	####################

	DISPLAY FORM f_comment1 
	LET current_comm_form = 1 
	CALL display_comment() 

END FUNCTION 


####################################################### END of file


