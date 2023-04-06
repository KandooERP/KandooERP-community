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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A13_GLOBALS.4gl" 


###########################################################################
# FUNCTION edit_notes(glob_rec_kandoouser.cmpy_code,p_cust_code)
#
#
###########################################################################
FUNCTION edit_notes(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customernote RECORD LIKE customernote.* 
	DEFINE l_arr_rec_customernote DYNAMIC ARRAY OF RECORD 
		note_date LIKE customernote.note_date, 
		note_text LIKE customernote.note_text 
	END RECORD 
	DEFINE l_curr_date DATE 
	DEFINE l_redisplay INTEGER 
	DEFINE l_err_message STRING 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT --,scrn 
	DEFINE l_append_row BOOLEAN #true when user naviates forsward on last field in row 

	CALL db_customer_get_rec_not_deleted(UI_OFF,p_cust_code) RETURNING l_rec_customer.* 
	IF l_rec_customer.cust_code IS NULL THEN
		RETURN 
	END IF 

	DELETE FROM t_customernote 

	OPEN WINDOW A621 with FORM "A621" 
	CALL windecoration_a("A621") 

	DISPLAY BY NAME 
		l_rec_customer.cust_code, 
		l_rec_customer.name_text, 
		l_rec_customer.contact_text, 
		l_rec_customer.tele_text, 
		l_rec_customer.mobile_phone 

	SELECT count(*) INTO l_idx 
	FROM customernote 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_cust_code 

	IF l_idx >= glob_rec_settings.maxListArraySizeSwitch THEN 
		MESSAGE kandoomsg2("A",1001,"") 

		#------------------------------------------
		CONSTRUCT BY NAME l_where_text ON note_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A13a","construct-WHERE-date") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 
		IF int_flag THEN
			LET l_where_text = " 1=1 "
		END IF
		#--------------------------------------------

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		MESSAGE kandoomsg2("A",1002,"") 
		LET l_query_text = "SELECT * FROM customernote ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cust_code = '",p_cust_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 2,3 desc,4,1" 

		PREPARE s_note FROM l_query_text 
		DECLARE c_note CURSOR FOR s_note 

		LET l_idx = 0 
		FOREACH c_note INTO l_rec_customernote.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_customernote[l_idx].note_date = l_rec_customernote.note_date 
			LET l_arr_rec_customernote[l_idx].note_text = l_rec_customernote.note_text 
			INSERT INTO t_customernote VALUES (l_rec_customernote.*) 
			## keep track of whats in the ARRAY so it can undergo
			## a (delete/re-add) UPDATE logic
			#         IF l_idx = 1000 THEN
			#            EXIT FOREACH
			#         END IF
		END FOREACH 

		#      IF l_idx = 0 THEN
		#         LET l_idx = 1
		#         LET l_arr_rec_customernote[1].note_date = NULL
		#      END IF

		LET l_redisplay = false 

		WHILE true 

			IF l_redisplay THEN 
				DECLARE c_t_customernote CURSOR FOR 
				SELECT * FROM t_customernote 
				ORDER BY 2,3 desc,4,1 
				LET l_idx = 0 

				FOREACH c_t_customernote INTO l_rec_customernote.* 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_customernote[l_idx].note_date = l_rec_customernote.note_date 
					LET l_arr_rec_customernote[l_idx].note_text = l_rec_customernote.note_text 
				END FOREACH 

				IF l_idx = 0 THEN 
					LET l_idx = 1 
					LET l_arr_rec_customernote[1].note_date = NULL 
				END IF 
				LET l_redisplay = false 

			END IF 

			#Init date as requested by tester
			LET l_curr_date = TODAY
			IF get_debug() THEN
				DISPLAY l_curr_date
			END IF 

			MESSAGE kandoomsg2("A",1032,"")				#1032 F1 Add F2 Delete RETURN Edit F10 Finish Note Entry
			INPUT ARRAY l_arr_rec_customernote WITHOUT DEFAULTS FROM sr_customernote.* ATTRIBUTE(UNBUFFERED, AUTO APPEND = TRUE, INSERT ROW = FALSE) 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","A13a","inp-arr-customernote") 

				BEFORE ROW 
					LET l_idx = arr_curr() 

--						IF l_curr_date IS NOT NULL THEN 
--							LET l_arr_rec_customernote[l_idx].note_date = l_curr_date 
--							--NEXT FIELD note_date 
--						END IF 


				AFTER ROW
					IF (l_idx > 0) AND (l_idx <= l_arr_rec_customernote.getSize()) THEN 
						IF get_is_screen_navigation_forward() THEN
							IF l_arr_rec_customernote[l_idx].note_text IS NULL THEN
								NEXT FIELD note_text
							END IF
						ELSE
							IF l_arr_rec_customernote[l_idx].note_text IS NULL THEN					
								IF l_arr_rec_customernote.getSize() > 1 THEN
									CALL l_arr_rec_customernote.delete(l_idx)
								END IF
							END IF
						END IF	
					END IF

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

									
				ON ACTION "FINISH NOTE ?" --ON KEY (f10) --data manager ?
					IF (l_idx > 0) AND (l_idx <= l_arr_rec_customernote.getSize()) THEN 
						LET l_arr_rec_customernote[l_idx].note_text = get_fldbuf(note_text) 
						LET l_curr_date = NULL 
					END IF

--          #This is sooo legacy text world style
--					ON ACTION "BULK INPUT" --ON KEY (F6) --bulk INPUT 
--						CALL input_bulk() 
--						LET l_redisplay = true 
--						EXIT INPUT 



				BEFORE INSERT
					LET l_arr_rec_customernote[l_idx].note_date = l_curr_date 
					--NEXT FIELD note_date 

				BEFORE DELETE 
					IF (l_idx > 0) AND (l_idx <= l_arr_rec_customernote.getSize()) THEN
						--INITIALIZE l_arr_rec_customernote[l_idx].* TO NULL
						CALL l_arr_rec_customernote.delete(l_idx) 
						LET l_curr_date = NULL 
					END IF 

					
				BEFORE FIELD note_date 
					IF l_arr_rec_customernote[l_idx].note_date IS NOT NULL THEN 
						NEXT FIELD note_text 
					END IF 

				AFTER FIELD note_date 
					IF l_arr_rec_customernote[l_idx].note_date IS NULL THEN 
					END IF 

				AFTER FIELD note_text 
					IF get_is_screen_navigation_forward() THEN
						IF l_arr_rec_customernote[l_idx].note_text IS NULL #append row only if current row has no NULL values / is completed
							OR l_arr_rec_customernote[l_idx].note_date IS NULL THEN
								NEXT FIELD  note_text
							ELSE
								LET l_append_row = TRUE #can be removed again								
 
						--IF fgl_lastkey() != fgl_keyval("up") THEN 

						## WHEN going down take the date with the CURSOR
--							IF l_arr_rec_customernote[l_idx+1].note_date IS NULL 
--							OR l_arr_rec_customernote[l_idx+1].note_date = 0 THEN 
							LET l_curr_date = l_arr_rec_customernote[l_idx].note_date 
						END IF 
					ELSE 
					--	LET l_curr_date = NULL 
					END IF 



			END INPUT 
			#--------------------------------

			IF l_redisplay = false THEN 
				EXIT WHILE 
			END IF 

		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			#MESSAGE kandoomsg2("A",1005,"") 
			#SLEEP 2
			IF promptTF("", kandoomsg2("A",8036,""),1) THEN 

				GOTO bypass 

				LABEL recovery: 
				IF error_recover(l_err_message, status) = "N" THEN 
					CLOSE WINDOW A621 
					RETURN 
				END IF 

				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					LET l_err_message = "Deleting previous notes" 
					DECLARE c_customernote CURSOR FOR 
					SELECT * FROM t_customernote
					 
					FOREACH c_customernote INTO l_rec_customernote.*
					 
						DELETE FROM customernote 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_rec_customernote.cust_code 
						AND note_date = l_rec_customernote.note_date 
						AND note_num = l_rec_customernote.note_num
						 
						DELETE FROM t_customernote 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_rec_customernote.cust_code 
						AND note_date = l_rec_customernote.note_date 
						AND note_num = l_rec_customernote.note_num 

					END FOREACH 

					LET l_err_message = "E11 - Adding new notes" 
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_customernote[l_idx].note_date IS NOT NULL 
						AND l_arr_rec_customernote[l_idx].note_date != 0 THEN 
							UPDATE customernote 
							SET note_text = l_arr_rec_customernote[l_idx].note_text 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = l_rec_customernote.cust_code 
							AND note_date = l_arr_rec_customernote[l_idx].note_date 
							AND note_num = l_idx 
							IF sqlca.sqlerrd[3] = 0 THEN 
								INSERT INTO customernote 
								VALUES (glob_rec_kandoouser.cmpy_code,p_cust_code, 
								l_arr_rec_customernote[l_idx].note_date, 
								l_idx, 
								l_arr_rec_customernote[l_idx].note_text) 
							END IF 
						END IF 
					END FOR 
				COMMIT WORK 
				WHENEVER ERROR stop 
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			END IF 
		END IF 
	END IF 

	CLOSE WINDOW A621 
END FUNCTION 
###########################################################################
# END FUNCTION edit_notes(glob_rec_kandoouser.cmpy_code,p_cust_code)
###########################################################################

{ This is soooo legacy... let's not use it
###############################################################################
# FUNCTION input_bulk()
#
#
###############################################################################
FUNCTION input_bulk() 
	DEFINE l_date DATE 
	DEFINE l_text STRING 
	DEFINE l_rec_customernote RECORD LIKE customernote.* 
	DEFINE i INTEGER 
	DEFINE idx2 INTEGER 
	DEFINE l_idx INTEGER 
	DEFINE cnt INTEGER 

	OPEN WINDOW A683 with FORM "A683" 
	CALL windecoration_a("A683") 

	MESSAGE kandoomsg2("A",1096,"")	# INPUT date AND note. ENTER TO complete note

	LET l_date = today 
	INPUT l_date WITHOUT DEFAULTS FROM date ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A13a","inp-date") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 
	################

	LET l_idx = 0 
	CALL set_count(l_idx) 


	INPUT l_text FROM text ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A13a","inp-text") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 
	##########

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	ELSE 
		SELECT max(note_num) INTO cnt 
		FROM t_customernote 
		IF cnt IS NULL THEN 
			LET cnt = 0 
		END IF 
		LET idx2 = 0 

		WHILE true 
			LET i = length(l_text) 
			IF i = 0 THEN 
				EXIT WHILE 
			END IF 
			IF i > 60 THEN 
				LET i = 60 
				IF l_text[60] IS NOT NULL OR 
				l_text[60] != " " THEN 
					FOR i = 60 TO 1 step -1 
						IF l_text[i] = " " THEN 
							EXIT FOR 
						END IF 
					END FOR 
				END IF 
				IF i <= 1 THEN 
					LET i = 60 
				END IF 
			END IF 

			LET l_rec_customernote.note_date = l_date 
			LET l_rec_customernote.note_text = l_text[1,i] 
			LET cnt = cnt + 1 
			LET idx2 = idx2 + i 
			LET l_idx = length(l_text) 
			LET l_rec_customernote.note_num = cnt 
			INSERT INTO t_customernote VALUES (l_rec_customernote.*) 

			IF idx2 >= 1920 THEN #????? what ?????
				EXIT WHILE 
			END IF 

			IF i < l_idx THEN 
				LET l_text = l_text[i+1,l_idx] 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

	END IF 

	CLOSE WINDOW A683 

END FUNCTION 
###############################################################################
# END FUNCTION input_bulk()
###############################################################################
}