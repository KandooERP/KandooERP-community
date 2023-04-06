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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZT_GLOBALS.4gl" 

##################################################################
# MAIN
#
# AZT.4gl - Maintainence Program FOR Sales Territories.
##################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("AZT") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A613 with FORM "A613" 
	CALL windecoration_a("A613") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_territory_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	WHILE select_territory(l_withquery) 
		LET l_withquery = scan_territory() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW A613 
END MAIN 
##################################################################
# END MAIN
##################################################################


##################################################################
# FUNCTION select_territory()
#
#
##################################################################
FUNCTION select_territory(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text STRING 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			terr_code, 
			desc_text, 
			area_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZT","construct-terr") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	MESSAGE kandoomsg2("A",1002,"")#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * ", 
	"FROM territory ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY 1,2" 
	PREPARE s_territory FROM l_query_text 
	DECLARE c_territory CURSOR FOR s_territory 

	RETURN 1 
END FUNCTION 
##################################################################
# END FUNCTION select_territory()
##################################################################


##################################################################
# FUNCTION scan_territory()
#
#
##################################################################
FUNCTION scan_territory() 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF #array[500] OF 
	RECORD 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code 
	END RECORD 
	--DEFINE scroll_flag CHAR(1)
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_del_cnt SMALLINT
	DEFINE l_del_cnt_success SMALLINT 
	DEFINE l_del_cnt_failure SMALLINT 
	DEFINE l_arr_delete_id DYNAMIC ARRAY OF LIKE territory.terr_code
	
	LET l_idx = 0 
	FOREACH c_territory INTO l_rec_territory.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_territory[l_idx].terr_code = l_rec_territory.terr_code 
		LET l_arr_rec_territory[l_idx].desc_text = l_rec_territory.desc_text 
		LET l_arr_rec_territory[l_idx].area_code = l_rec_territory.area_code 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9081,"")#9081" No Sales Territories Satsified Selection Criteria "
	END IF 

	ERROR kandoomsg2("A",1003,"")	#" F1 TO Add - F2 TO Delete - RETURN TO Edit "
	DISPLAY ARRAY l_arr_rec_territory TO sr_territory.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZT","inp-arr-territory")
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_territory.getSize()) 
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_territory.getSize())
						
		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN true 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



			--      BEFORE FIELD scroll_flag
			--         LET l_idx = arr_curr()
			--         --LET scrn = scr_line()
			--         LET l_scroll_flag = l_arr_rec_territory[l_idx].scroll_flag
			--         --DISPLAY l_arr_rec_territory[l_idx].*
			--         --     TO sr_territory[scrn].*

			--      AFTER FIELD scroll_flag
			--         LET l_arr_rec_territory[l_idx].scroll_flag = l_scroll_flag
			--
			--         IF fgl_lastkey() = fgl_keyval("down") THEN
			--            IF arr_curr() = arr_count() THEN
			--               ERROR kandoomsg2("A",9001,"")      --9001 There are no more rows in the direction ...
			--               NEXT FIELD scroll_flag
			--            ELSE
			--               IF l_arr_rec_territory[l_idx+1].terr_code IS NULL THEN
			--                  ERROR kandoomsg2("A",9001,"")    --9001 There are no more rows in the direction ...
			--                  NEXT FIELD scroll_flag
			--               END IF
			--            END IF
			--         END IF

		ON ACTION ("EDIT", "doubleclick") --edit 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_territory.getSize()) THEN 
				IF edit_territory(l_arr_rec_territory[l_idx].terr_code) THEN 
					SELECT desc_text, 
					area_code 
					INTO l_arr_rec_territory[l_idx].desc_text, 
					l_arr_rec_territory[l_idx].area_code 
					FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terr_code = l_arr_rec_territory[l_idx].terr_code 
				END IF 
				#         END IF
			END IF 

			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_territory.getSize()) 
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_territory.getSize())
 

			--         NEXT FIELD scroll_flag

			--      BEFORE FIELD terr_code
			--         IF l_arr_rec_territory[l_idx].terr_code IS NOT NULL THEN
			--            IF edit_territory(l_arr_rec_territory[l_idx].terr_code) THEN
			--               SELECT desc_text,
			--                      area_code
			--                 INTO l_arr_rec_territory[l_idx].desc_text,
			--                      l_arr_rec_territory[l_idx].area_code
			--                 FROM territory
			--                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			--                  AND terr_code = l_arr_rec_territory[l_idx].terr_code
			--            END IF
			--         END IF
			--         NEXT FIELD scroll_flag

			ON ACTION "ADD" #before INSERT --new RECORD 
				#         IF arr_curr() < arr_count() THEN
				LET l_rowid = edit_territory("") 
				IF l_idx < 1 THEN --empty TABLE 
					LET l_idx = 1 
				END IF 
				SELECT terr_code, 
				desc_text, 
				area_code 
				INTO l_arr_rec_territory[l_idx].terr_code, 
				l_arr_rec_territory[l_idx].desc_text, 
				l_arr_rec_territory[l_idx].area_code 
				FROM territory 
				WHERE rowid = l_rowid 
				--IF STATUS = NOTFOUND THEN
				--   FOR l_idx = arr_curr() TO arr_count()
				--      LET l_arr_rec_territory[l_idx].* = l_arr_rec_territory[l_idx+1].*
				--      IF scrn <= 14 THEN
				--         DISPLAY l_arr_rec_territory[l_idx].*
				--              TO sr_territory[scrn].*
				--
				--         LET scrn = scrn + 1
				--      END IF
				--   END FOR
				--   INITIALIZE l_arr_rec_territory[l_idx].* TO NULL
				--END IF
				--         ELSE
				--            IF l_idx > 1 THEN
				--               ERROR kandoomsg2("A",9001,"")			--               --9001There are no more rows in the direction you are going
				--            END IF
				--         END IF

			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_territory.getSize()) 
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_territory.getSize())
 

		ON ACTION "DELETE" #key(F2) --delete 
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_territory.getSize()) THEN #data array must not be empty
					LET l_del_cnt = 0 
					FOR l_idx = 1 TO l_arr_rec_territory.getsize() #check, what rows are selected AND if they can be deleted 
						IF dialog.isRowSelected("sr_territory",l_idx) THEN
							LET l_del_cnt = l_del_cnt + 1
							CALL l_arr_delete_id.append(l_arr_rec_territory[l_idx].terr_code) #if valid, add cond_Code to array
						END IF 
					END FOR 
	
					IF kandoomsg("A",8007,l_del_cnt) = "Y" THEN #8007 Confirm TO Delete ",del_cnt," Sales Territory(s)? (Y/N)"
						FOR i = 1 TO l_arr_delete_id.getSize() 
							IF db_territory_delete(UI_ON,UI_CONFIRM_ON,l_arr_delete_id[i]) >= 0 THEN 
								LET l_del_cnt_success = l_del_cnt_success+1 
							ELSE
								LET l_del_cnt_failure = l_del_cnt_failure+1
							END IF
						END FOR
						
						CASE
							WHEN l_del_cnt_success = 0 AND l_del_cnt_failure = 0
								ERROR "No rows were selected to be deleted"
							
							WHEN l_del_cnt_success > 0 AND l_del_cnt_failure = 0
								MESSAGE "All ", trim(l_del_cnt_success), " selected territories deleted"
							
							WHEN l_del_cnt_success = 0 AND l_del_cnt_failure > 0
								MESSAGE "None of the ", trim(l_del_cnt_failure), " selected territories could be deleted"
								
							WHEN l_del_cnt_success > 0 AND l_del_cnt_failure > 0
								MESSAGE trim(l_del_cnt_success), " territories could be deleted. (", trim(l_del_cnt_failure), " deletion(s) failed)"
							OTHERWISE
								CALL fgl_winmessage("Internal 4gl error","Contact support #-42342","ERROR") 
						END CASE  
--			
--						SELECT unique 1 FROM salesperson 
--						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--						AND terri_code = l_arr_delete_id[d] 
--						IF status = 0 THEN 
--							ERROR kandoomsg2("A",7016,l_arr_delete_id[d])						#7016 Salespersons exits FOR this territory - deletion no
--						ELSE 
--							DELETE FROM territory 
--							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--							AND terr_code = l_arr_delete_id[d] 
--	
--							CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_territory.getSize()) 
--							CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_territory.getSize())
--	
--						END IF 
--					END FOR  --END FOR LOOP
						
				END IF 
	
		END IF
			--         IF l_arr_rec_territory[l_idx].terr_code IS NOT NULL THEN
			--            IF l_arr_rec_territory[l_idx].scroll_flag IS NULL THEN
			--               IF delete_terr(l_arr_rec_territory[l_idx].terr_code) THEN
			--                  LET l_arr_rec_territory[l_idx].scroll_flag = "*"
			--                  LET del_cnt = del_cnt + 1
			--               END IF
			--            ELSE
			--               LET l_arr_rec_territory[l_idx].scroll_flag = NULL
			--               LET del_cnt = del_cnt - 1
			--            END IF
			--         END IF
			--         NEXT FIELD scroll_flag

			--AFTER ROW
			--   DISPLAY l_arr_rec_territory[l_idx].*
			--        TO sr_territory[scrn].*



	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	END IF 

	--   ELSE
	--      IF del_cnt > 0 THEN
	--         IF kandoomsg("A",8007,del_cnt) = "Y" THEN	--8007 Confirm TO Delete ",del_cnt," Sales Territory(s)? (Y/N)"
	--            FOR l_idx = 1 TO arr_count()
	--               IF l_arr_rec_territory[l_idx].scroll_flag = "*" THEN
	--                  SELECT unique 1 FROM salesperson
	--                     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	--                       AND terri_code = l_arr_rec_territory[l_idx].terr_code
	--                  IF STATUS = 0 THEN
	--                     ERROR kandoomsg2("A",7016,l_arr_rec_territory[l_idx].terr_code)       --7016 Salespersons exits FOR this territory - deletion no
	--                  ELSE
	--                     DELETE FROM territory
	--                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	--                          AND terr_code = l_arr_rec_territory[l_idx].terr_code
	--                  END IF
	--               END IF
	--            END FOR
	--         END IF
	--      END IF
	--   END IF
END FUNCTION 
##################################################################
# END FUNCTION scan_territory()
##################################################################


##################################################################
# FUNCTION edit_territory(l_terr_code)
#
#
##################################################################
FUNCTION edit_territory(l_terr_code) 
	DEFINE l_terr_code LIKE territory.terr_code 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_sale_cnt SMALLINT 
	DEFINE l_temp_text CHAR(40)  

	SELECT * INTO l_rec_territory.* 
	FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terr_code = l_terr_code 

	OPEN WINDOW A614 with FORM "A614" 
	CALL windecoration_a("A614") 

	MESSAGE kandoomsg2("A",1015,"") #1015" Enter sales territory details - ESC TO Continue"
	IF l_rec_territory.area_code IS NOT NULL THEN 
		SELECT * INTO l_rec_salearea.* 
		FROM salearea 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_rec_territory.area_code 
		IF status = NOTFOUND THEN 
			LET l_rec_salearea.desc_text = "**********" 
		END IF 
		DISPLAY l_rec_salearea.desc_text TO salearea.desc_text 

	END IF 

	IF l_rec_territory.sale_code IS NOT NULL THEN 

		CALL db_salesperson_get_rec(UI_OFF,l_rec_territory.sale_code ) RETURNING l_rec_salesperson.*
		IF l_rec_salesperson.sale_code IS NULL THEN
			LET l_rec_salesperson.name_text = "**********"
		END IF
		
		DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

	END IF 

	INPUT BY NAME 
		l_rec_territory.terr_code, 
		l_rec_territory.desc_text, 
		l_rec_territory.area_code, 
		l_rec_territory.terr_type_ind, 
		l_rec_territory.sale_code WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZT","inp-territory") 

			IF l_terr_code IS NOT NULL THEN 
				CALL set_fieldAttribute_readOnly("terr_code",FALSE) 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (area_code) 
			LET l_temp_text = show_area(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_territory.area_code = l_temp_text 
				NEXT FIELD area_code 
			END IF 

		ON ACTION "LOOKUP" infield (sale_code) 
			LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_territory.sale_code = l_temp_text 
				NEXT FIELD sale_code 
			END IF 


		BEFORE FIELD terr_code 
			IF l_terr_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD terr_code 
			IF l_rec_territory.terr_code IS NULL THEN 
				ERROR kandoomsg2("A",9083,"")			#9083" Sale territory code must be entered
				NEXT FIELD terr_code 
			ELSE 
				SELECT unique 1 FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = l_rec_territory.terr_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9089,"")				#9089" Sales Territory already exists - Please Re Enter "
					NEXT FIELD terr_code 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_territory.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9087,"") 		#9087 Sales Territory name OR description must be Entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD area_code 
			IF l_rec_territory.area_code IS NULL THEN 
				ERROR kandoomsg2("A",9014,"") 		#9014 area must be entered
				CLEAR salearea.desc_text 
				NEXT FIELD area_code 
			ELSE 
				SELECT * INTO l_rec_salearea.* 
				FROM salearea 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND area_code = l_rec_territory.area_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9088,"")		#9088 area NOT found - try window
					CLEAR salearea.desc_text 
				ELSE 
					DISPLAY l_rec_salearea.desc_text 
					TO salearea.desc_text 

				END IF 
			END IF 

		AFTER FIELD sale_code 
			CLEAR salesperson.name_text 
			IF l_rec_territory.sale_code IS NOT NULL THEN 

				#get sales person record
				CALL db_salesperson_get_rec(UI_OFF,l_rec_territory.sale_code) RETURNING l_rec_salesperson.*

				IF l_rec_salesperson.sale_code IS NULL THEN
					ERROR kandoomsg2("A",9032,"") 			#9032 sale NOT found - try window
					NEXT FIELD sale_code 
				END IF
				
				IF l_rec_salesperson.terri_code IS NOT NULL 
				AND l_rec_territory.terr_code IS NOT NULL 
				AND l_rec_salesperson.terri_code != l_rec_territory.terr_code THEN 
					ERROR kandoomsg2("A",7046,l_rec_salesperson.terri_code)				#7046"salespersonis assigned TO Territory
					NEXT FIELD sale_code 
				END IF 
				
				DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM salearea 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND area_code = l_rec_territory.area_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9088,"") 			#9088 area NOT found - try window
					CLEAR salearea.desc_text 
				END IF 
				
				IF l_rec_territory.sale_code IS NOT NULL THEN 
					SELECT count(*) INTO l_sale_cnt 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terri_code = l_rec_territory.terr_code 

					CASE l_sale_cnt 
						WHEN "0" 

						WHEN "1" 
							SELECT sale_code INTO l_temp_text 
							FROM salesperson 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND terri_code = l_rec_territory.terr_code 
							IF l_temp_text != l_rec_territory.sale_code THEN 
								ERROR kandoomsg2("A",7044,l_temp_text)							#7044"Territory IS assigned TO salesperson
								LET l_rec_territory.sale_code = l_temp_text 
								NEXT FIELD sale_code 
							END IF 

						OTHERWISE 
							ERROR kandoomsg2("A",7045,"") 				#7045"Territory IS assigned TO multiple salesperson"
							NEXT FIELD sale_code 
					END CASE 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A614 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		IF l_terr_code IS NULL THEN 
			LET l_rec_territory.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO territory VALUES (l_rec_territory.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE territory 
			SET territory.* = l_rec_territory.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND terr_code = l_terr_code 
			RETURN sqlca.sqlerrd[3] 
		END IF 
	END IF 
END FUNCTION 
##################################################################
# END FUNCTION edit_territory(l_terr_code)
##################################################################


##################################################################
# FUNCTION delete_terr(p_terr)
#
#
##################################################################
FUNCTION delete_terr(p_terr) 
	DEFINE p_terr LIKE territory.terr_code 

	SELECT unique 1 FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terri_code = p_terr 
	IF status = 0 THEN 
		ERROR kandoomsg2("A",7016,p_terr) 	#7016 Salespersons exists FOR this territory - deletion no
		RETURN false 
	END IF 

	SELECT unique 1 FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND territory_code = p_terr 
	IF status = 0 THEN 
		ERROR kandoomsg2("A",7086,p_terr) 	#7086 Customer exists FOR this territory - deletion no
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
##################################################################
# END FUNCTION delete_terr(p_terr)
##################################################################