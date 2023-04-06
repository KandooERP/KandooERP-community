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
#   A1D - Customer Card Maintenance
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A1D_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE err_message STRING

########################################################
# FUNCTION A1D_main()
#
#
########################################################
FUNCTION A1D_main() 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A1D") 

	OPEN WINDOW A676 with FORM "A676" 
	CALL windecoration_a("A676") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_custcard() 
 
	CLOSE WINDOW A676 
END FUNCTION 
########################################################
# END FUNCTION A1D_main()
########################################################


########################################################
# FUNCTION db_custcard_get_datasource(p_filter)
#
#
########################################################
FUNCTION db_custcard_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_rec_custcard RECORD LIKE custcard.* 
	DEFINE l_arr_rec_custcard DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		card_code LIKE custcard.card_code, 
		cust_code LIKE custcard.cust_code, 
		card_text LIKE custcard.card_text, 
		expiry_date LIKE custcard.expiry_date, 
		hold_code LIKE custcard.hold_code 
	END RECORD 
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			card_code, 
			cust_code, 
			card_text, 
			expiry_date, 
			hold_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A1D","construct-custcard") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM custcard ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY custcard.card_code" 
	PREPARE s_custcard FROM l_query_text 
	DECLARE c_custcard CURSOR FOR s_custcard 

	LET l_idx = 0 
	FOREACH c_custcard INTO l_rec_custcard.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_custcard[l_idx].card_code = l_rec_custcard.card_code 
		LET l_arr_rec_custcard[l_idx].cust_code = l_rec_custcard.cust_code 
		LET l_arr_rec_custcard[l_idx].card_text = l_rec_custcard.card_text 
		LET l_arr_rec_custcard[l_idx].expiry_date = l_rec_custcard.expiry_date 
		LET l_arr_rec_custcard[l_idx].hold_code = l_rec_custcard.hold_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	IF l_idx = 0 AND p_filter = TRUE THEN 
		ERROR kandoomsg2("A",9004,"") 	#9004" No entries satisfied selection criteria "
	END IF 

	RETURN l_arr_rec_custcard 
END FUNCTION 
########################################################
# END FUNCTION db_custcard_get_datasource(p_filter)
########################################################


########################################################
# FUNCTION A1D_scan_custcard_event_manager() 
#
# Hides/Shows toolbar buttons depending on data array size empty/filled
########################################################
FUNCTION A1D_scan_custcard_event_manager(p_arr_size) 
	DEFINE p_arr_size SMALLINT
	IF p_arr_size THEN
		CALL dialog.setActionHidden("EDIT",FALSE)
		CALL dialog.setActionHidden("DELETE",FALSE)
		CALL dialog.setActionHidden("FIND",FALSE)
	ELSE
		CALL dialog.setActionHidden("EDIT",TRUE)
		CALL dialog.setActionHidden("DELETE",TRUE)
		CALL dialog.setActionHidden("FIND",TRUE)
	END IF
END FUNCTION
########################################################
# FUNCTION A1D_scan_custcard_event_manager() 
#
# Hides/Shows toolbar buttons depending on data array size empty/filled
########################################################
########################################################
# FUNCTION scan_custcard()
#
#
########################################################
FUNCTION scan_custcard() 
	DEFINE l_rec_custcard RECORD LIKE custcard.* 
	DEFINE l_rec_s_custcard RECORD LIKE custcard.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_custcard DYNAMIC ARRAY OF RECORD -- array[800] OF RECORD 
		scroll_flag CHAR(1), 
		card_code LIKE custcard.card_code, 
		cust_code LIKE custcard.cust_code, 
		card_text LIKE custcard.card_text, 
		expiry_date LIKE custcard.expiry_date, 
		hold_code LIKE custcard.hold_code 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_vcnt SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_auto INTEGER 

	CALL db_custcard_get_datasource(FALSE) RETURNING l_arr_rec_custcard

	MESSAGE kandoomsg2("A",1090,"") #" F2 TO Delete; F10 Automatic Card Generation; Enter on line TO Edit "

	DISPLAY ARRAY l_arr_rec_custcard TO sr_custcard.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A1D","inp-arr-custcard")
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL A1D_scan_custcard_event_manager(l_arr_rec_custcard.getSize()) 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "FILTER"
			CALL db_custcard_get_datasource(FALSE) RETURNING l_arr_rec_custcard
			CALL A1D_scan_custcard_event_manager(l_arr_rec_custcard.getSize())		

		ON ACTION "REFRESH"
			CALL windecoration_a("A676")		
			CALL db_custcard_get_datasource(FALSE) RETURNING l_arr_rec_custcard
			CALL A1D_scan_custcard_event_manager(l_arr_rec_custcard.getSize())		

		ON ACTION "NEW"--ON KEY (F10) infield(scroll_flag) 
			IF auto_card_generate() THEN 
				LET l_auto = true
				CALL db_custcard_get_datasource(FALSE) RETURNING l_arr_rec_custcard
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_custcard.getSize()) 
			END IF 
			CALL A1D_scan_custcard_event_manager(l_arr_rec_custcard.getSize())
			
		BEFORE ROW
			LET l_idx = arr_curr() 

--		BEFORE FIELD scroll_flag 
--			LET l_idx = arr_curr() 
--			LET l_scroll_flag = l_arr_rec_custcard[l_idx].scroll_flag 
--			#DISPLAY l_arr_rec_custcard[l_idx].* TO sr_custcard[scrn].*

--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_custcard[l_idx].scroll_flag = l_scroll_flag 

		ON ACTION ("EDIT","doubleClick") --BEFORE FIELD card_code 
--			IF l_arr_rec_custcard[l_idx].scroll_flag = "*" THEN 
--				ERROR kandoomsg2("A",9318,"")				#9318 Customer card has been marked FOR deletion
--				NEXT FIELD scroll_flag 
--			END IF 

			IF edit_custcard(l_arr_rec_custcard[l_idx].card_code) THEN 
				SELECT * INTO l_rec_custcard.* FROM custcard 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND card_code = l_arr_rec_custcard[l_idx].card_code 
				LET l_arr_rec_custcard[l_idx].card_code = l_rec_custcard.card_code 
				LET l_arr_rec_custcard[l_idx].cust_code = l_rec_custcard.cust_code 
				LET l_arr_rec_custcard[l_idx].card_text = l_rec_custcard.card_text 
				LET l_arr_rec_custcard[l_idx].expiry_date = l_rec_custcard.expiry_date 
				LET l_arr_rec_custcard[l_idx].hold_code = l_rec_custcard.hold_code 
			END IF 
--			NEXT FIELD scroll_flag 

		ON ACTION "DELETE" --KEY (F2) infield(scroll_flag) --delete marker 			
			LET l_del_cnt = 0 
			FOR l_idx = 1 TO l_arr_rec_custcard.getsize() 
				IF dialog.isRowSelected("sr_custcard",l_idx) THEN 
					LET l_del_cnt = l_del_cnt + 1 
				END IF 
			END FOR 
			
			--IF l_del_cnt = 0 THEN
				

			IF kandoomsg("U",8020,l_del_cnt) = "Y" THEN --user confirmation required
				FOR l_idx = 1 TO l_arr_rec_custcard.getsize() --arr_count() 

					IF dialog.isRowSelected("sr_custcard",l_idx) THEN
			
						BEGIN WORK 
			
						DELETE FROM custcard 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND card_code = l_arr_rec_custcard[l_idx].card_code 
			
						COMMIT WORK
			
					END IF
				END FOR
				CALL db_custcard_get_datasource(FALSE) RETURNING l_arr_rec_custcard
--				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_custcard.getSize())
			END IF		
			CALL A1D_scan_custcard_event_manager(l_arr_rec_custcard.getSize())
{		
		@@@@@ delete
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
		
				IF l_del_cnt > 0 THEN 			 	
					IF kandoomsg2("A",8034,l_del_cnt)= "Y" THEN #8034 Confirmation TO Delete ",l_del_cnt," customer card(s)? (Y/N)"
						FOR l_idx = 1 TO arr_count() 
							IF l_arr_rec_custcard[l_idx].scroll_flag = "*" THEN 
								LET err_message = "Delete Customer Card (A1D)" 
								DELETE FROM custcard 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND card_code = l_arr_rec_custcard[l_idx].card_code 
							END IF 
						END FOR 
					END IF 
				END IF 
		
			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler


			IF l_arr_rec_custcard[l_idx].card_code IS NOT NULL THEN 
				IF l_arr_rec_custcard[l_idx].scroll_flag != "*" 
				OR l_arr_rec_custcard[l_idx].scroll_flag IS NULL THEN 
					IF l_arr_rec_custcard[l_idx].cust_code IS NULL THEN 
						LET l_arr_rec_custcard[l_idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					ELSE 
						ERROR kandoomsg2("A",9316,"") 						#9316 Customer Card NOT available FOR deletion
					END IF 
				ELSE 
					LET l_arr_rec_custcard[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
}
	END DISPLAY
	##################

	IF l_auto THEN 
		RETURN 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

{
	MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please wait.


	GOTO bypass 

	LABEL recovery: 

	IF error_recover(err_message, status) = "N" THEN 
		RETURN 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		IF l_del_cnt > 0 THEN 			 	
			IF kandoomsg2("A",8034,l_del_cnt)= "Y" THEN #8034 Confirmation TO Delete ",l_del_cnt," customer card(s)? (Y/N)"
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_custcard[l_idx].scroll_flag = "*" THEN 
						LET err_message = "Delete Customer Card (A1D)" 
						DELETE FROM custcard 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND card_code = l_arr_rec_custcard[l_idx].card_code 
					END IF 
				END FOR 
			END IF 
		END IF 

	COMMIT WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
}
END FUNCTION 


########################################################
# FUNCTION auto_card_generate()
########################################################
FUNCTION auto_card_generate() 
	DEFINE l_rec_custcard RECORD LIKE custcard.* 
	DEFINE l_beg_num DECIMAL(16,0)
	DEFINE l_end_num DECIMAL(16,0)
	DEFINE l_exp_date DATE 
	DEFINE l_insert_cnt INTEGER
	DEFINE i INTEGER


	OPEN WINDOW A677 with FORM "A677" 
	CALL windecoration_a("A677") 

	MESSAGE kandoomsg2("A",1091,"") #1091 Enter Card Details; OK TO Continue
	INPUT l_beg_num, 
	l_end_num, 
	l_exp_date 
	FROM 
		beg_num, 
		end_num, 
		exp_date	
	ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A1D","inp-card-details") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD beg_num 
			IF l_beg_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD beg_num 
			END IF 
			IF l_beg_num < 0 THEN 
				ERROR kandoomsg2("U",9907,"0") 			#9907 Value must be greater than zero
				NEXT FIELD beg_num 
			END IF 

		AFTER FIELD end_num 
			IF l_end_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD end_num 
			END IF 
			IF l_end_num < l_beg_num THEN 
				ERROR kandoomsg2("U",9907,l_beg_num) 				#9907 Value must be greater than zero
				NEXT FIELD end_num 
			END IF 

		AFTER FIELD exp_date 
			IF l_exp_date < today THEN 
				ERROR kandoomsg2("U",9907,today) 			#9907 Value must be greater than zero
				NEXT FIELD exp_date 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_beg_num IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
					NEXT FIELD beg_num 
				END IF 
				IF l_end_num IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD end_num 
				END IF 
				SELECT unique 1 FROM custcard 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND card_code between l_beg_num AND l_end_num 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9317,"") 					#9317 Customer cards have already been allocated in this range
					NEXT FIELD beg_num 
				END IF 
			END IF 

	END INPUT 
	########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A677 
		RETURN false 
	END IF 

	LET l_insert_cnt = 0 
	
	IF kandoomsg("A",8035,"") = "Y" THEN #8035 Confirmation TO create customer cards? (Y/N)"
		MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please wait.
		INITIALIZE l_rec_custcard.* TO NULL 
		LET l_rec_custcard.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_custcard.expiry_date = l_exp_date 
		LET l_rec_custcard.pin_expiry_date = l_exp_date 

		FOR i = l_beg_num TO l_end_num 

			GOTO bypass 

			LABEL recovery: 
			IF error_recover(err_message, status) = "N" THEN 
				CLOSE WINDOW A677 
				RETURN false 
			END IF 

			LABEL bypass: 

			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 
				SELECT unique 1 FROM custcard 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND card_code = i 

				IF status = 0 THEN 
					ERROR kandoomsg2("A",7093,"") #7093 An attempt was made TO create customer card already.....
					EXIT FOR 
				END IF 

				LET l_rec_custcard.card_code = i 
				LET l_rec_custcard.access_ind = 0 
				LET err_message = "Insert Customer Card (A1D)" 

				INSERT INTO custcard VALUES (l_rec_custcard.*) 
			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			LET l_insert_cnt = l_insert_cnt + 1 
		END FOR 
	END IF 

	CLOSE WINDOW A677 

	IF l_insert_cnt > 0 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


########################################################
# FUNCTION edit_custcard(p_card_code)
#
#
########################################################
FUNCTION edit_custcard(p_card_code) 
	DEFINE p_card_code LIKE custcard.card_code 
	DEFINE l_tmp_hold_code LIKE custcard.hold_code 
	DEFINE l_rec_custcard RECORD LIKE custcard.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_rec_s_custcard RECORD LIKE custcard.* 
	DEFINE l_temp_text CHAR(60) 

	OPEN WINDOW A706 with FORM "A706" 
	CALL windecoration_a("A706") 

--	INITIALIZE l_rec_custcard.* TO NULL 
	SELECT * INTO l_rec_custcard.* FROM custcard 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND card_code = p_card_code 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",7001,"Customer Card") #7001 Logic Error Customer Card RECORD does NOT exist
		RETURN false 
	END IF 

	IF l_rec_custcard.hold_code IS NOT NULL THEN 
--		INITIALIZE l_rec_holdreas.* TO NULL 
		SELECT * INTO l_rec_holdreas.* FROM holdreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = l_rec_custcard.hold_code 
		DISPLAY l_rec_holdreas.reason_text TO reason_text

	END IF 

	LET l_tmp_hold_code = l_rec_custcard.hold_code 

	MESSAGE kandoomsg2("U",1020,"Customer Card") 	#1020 Enter Customer Card Details; OK TO Continue.

	INPUT BY NAME l_rec_custcard.card_code, 
	l_rec_custcard.cust_code, 
	l_rec_custcard.card_text, 
	l_rec_custcard.expiry_date, 
	l_rec_custcard.hold_code, 
	l_rec_custcard.pin_text, 
	l_rec_custcard.pin_expiry_date, 
	l_rec_custcard.access_ind, 
	l_rec_custcard.voice_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A1D","inp-custcard") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
			LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_custcard.cust_code = l_temp_text 
				NEXT FIELD cust_code 
			END IF 

		ON ACTION "LOOKUP" infield (hold_code) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_custcard.hold_code = l_temp_text 
				NEXT FIELD hold_code 
			END IF 

		BEFORE FIELD card_code 
			NEXT FIELD cust_code 

		ON CHANGE cust_code
				IF l_rec_custcard.card_text IS NULL THEN 
					IF l_rec_customer.contact_text IS NOT NULL THEN 
						LET l_rec_custcard.card_text = l_rec_customer.contact_text 
					ELSE 
						LET l_rec_custcard.card_text = l_rec_customer.name_text 
					END IF 
				END IF 

		AFTER FIELD cust_code 
			IF l_rec_custcard.cust_code IS NOT NULL THEN 
				CALL db_customer_get_rec(UI_OFF,l_rec_custcard.cust_code ) RETURNING l_rec_customer.*
				 
				IF l_rec_customer.cust_code IS NULL	THEN			
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found - Try Window
					NEXT FIELD cust_code 
				END IF 

				IF l_rec_custcard.card_text IS NULL THEN 
					IF l_rec_customer.contact_text IS NOT NULL THEN 
						LET l_rec_custcard.card_text = l_rec_customer.contact_text 
					ELSE 
						LET l_rec_custcard.card_text = l_rec_customer.name_text 
					END IF 
				END IF 

				DISPLAY l_rec_custcard.card_text TO card_text

			END IF 

		AFTER FIELD expiry_date 
			IF l_rec_custcard.expiry_date IS NOT NULL 
			AND l_rec_custcard.expiry_date < today THEN 
				ERROR kandoomsg2("U",9907,today) 			#9907 Value must be greater than today
				NEXT FIELD expiry_date 
			END IF 

		AFTER FIELD pin_expiry_date 
			IF l_rec_custcard.pin_expiry_date IS NULL 
			AND l_rec_custcard.pin_text IS NOT NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD pin_expiry_date 
			END IF 

		ON CHANGE hold_code
			DISPLAY db_holdreas_get_reason_text(UI_OFF,l_rec_custcard.hold_code) TO reason_text		

		AFTER FIELD hold_code 
			IF l_rec_custcard.hold_code IS NOT NULL THEN 
				INITIALIZE l_rec_holdreas.* TO NULL 
				SELECT * INTO l_rec_holdreas.* FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_custcard.hold_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found - Try Window
					NEXT FIELD hold_code 
				END IF 
				DISPLAY db_holdreas_get_reason_text(UI_OFF,l_rec_custcard.hold_code) TO reason_text

			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_custcard.cust_code IS NOT NULL THEN 
					IF l_rec_custcard.card_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
						NEXT FIELD card_text 
					END IF 
				END IF 

				IF l_rec_custcard.expiry_date IS NOT NULL 
				AND l_rec_custcard.expiry_date < today THEN 
					ERROR kandoomsg2("U",9907,today) 			#9907 Value must be greater than today
					NEXT FIELD expiry_date 
				END IF 

				IF l_rec_custcard.hold_code IS NOT NULL THEN 
					SELECT unique 1 FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = l_rec_custcard.hold_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("U",9105,"") 					#9105 RECORD NOT found - Try Window
						NEXT FIELD hold_code 
					END IF 
				END IF 

				IF l_rec_custcard.pin_expiry_date IS NULL 
				AND l_rec_custcard.pin_text IS NOT NULL THEN 
					ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
					NEXT FIELD pin_expiry_date 
				END IF 

				IF l_rec_custcard.hold_code IS NOT NULL 
				AND (l_rec_custcard.hold_code != l_tmp_hold_code 
				OR l_tmp_hold_code IS null) THEN 
					LET l_rec_custcard.hold_datetime = CURRENT year TO second 
				ELSE 
					LET l_rec_custcard.hold_datetime = NULL 
				END IF 
			END IF 

	END INPUT 
	##########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = true 
		LET quit_flag = true 

		CLOSE WINDOW A706 

		RETURN false 
	END IF 
{
	MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please wait.

	GOTO bypass 

	LABEL recovery: 
}
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW A706 
		RETURN false 
	END IF 
{
	LABEL bypass: 
}
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c3_custcard CURSOR FOR 
		SELECT * FROM custcard 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND card_code = l_rec_custcard.card_code 
		AND cust_code = l_rec_custcard.cust_code 
		FOR UPDATE 

		OPEN c3_custcard 
		FETCH c3_custcard INTO l_rec_s_custcard.* 

		IF status = NOTFOUND THEN 
			LET l_rec_custcard.issue_date = today 
		END IF 

		LET err_message = "Update Customer Card Details (A1D)" 

		UPDATE custcard 
		SET * = l_rec_custcard.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND card_code = l_rec_custcard.card_code 

	COMMIT WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CLOSE WINDOW A706 

	RETURN true 
END FUNCTION 
