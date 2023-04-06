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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EZ_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EZA_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_winds_text char(60) 
--	DEFINE modu_entry_flag SMALLINT 
###########################################################################
# FUNCTION EZA_main()
#
# EZA - Allows user TO main delivery information on warehouse table
###########################################################################
FUNCTION EZA_main() 
	DEFER QUIT 
	DEFER INTERRUPT
	
	CALL setModuleId("EZA") -- albo 

	OPEN WINDOW I133 with FORM "I133" 
	 CALL windecoration_i("I133") -- albo kd-755 

	CALL scan_ware() 
	
	CLOSE WINDOW I133 
	
END FUNCTION 
###########################################################################
# END FUNCTION EZA_main()
###########################################################################


###########################################################################
# FUNCTION db_warehouse_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_warehouse_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF #array[250] OF RECORD 
		RECORD 
			--scroll_flag char(1), 
			ware_code LIKE warehouse.ware_code, 
			desc_text LIKE warehouse.desc_text, 
			contact_text LIKE warehouse.contact_text, 
			tele_text LIKE warehouse.tele_text,
			mobile_phone LIKE warehouse.mobile_phone ,
			email LIKE warehouse.email
		END RECORD 
		DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 	#1001 Enter selection criteria - ESC TO continue
		CONSTRUCT BY NAME l_where_text ON 
			ware_code, 
			desc_text, 
			contact_text, 
			tele_text,
			mobile_phone,
			email	 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EZA","construct-ware_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = "1=1"
		END IF 
	ELSE 
		LET l_where_text = "1=1"
	END IF
	
	MESSAGE kandoomsg2("E",1002,"") #1002 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM warehouse ", 
		"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY ware_code" 
	PREPARE s_warehouse FROM l_query_text 
	DECLARE c_warehouse cursor FOR s_warehouse 

	LET l_idx = 0 
	FOREACH c_warehouse INTO l_rec_warehouse.* 
		LET l_idx = l_idx + 1 
		--LET l_arr_rec_warehouse[l_idx].scroll_flag = NULL 
		LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code 
		LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text 
		LET l_arr_rec_warehouse[l_idx].contact_text = l_rec_warehouse.contact_text 
		LET l_arr_rec_warehouse[l_idx].tele_text = l_rec_warehouse.tele_text 
		LET l_arr_rec_warehouse[l_idx].mobile_phone = l_rec_warehouse.mobile_phone
		LET l_arr_rec_warehouse[l_idx].email = l_rec_warehouse.email

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("I",9087,"") 		#9087 " No warehouses satisfied the selection criteria"
	END IF 

	RETURN l_arr_rec_warehouse		
END FUNCTION 
###########################################################################
# END FUNCTION db_warehouse_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_ware()
#
#
###########################################################################
FUNCTION scan_ware() 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF #array[250] OF RECORD 
		RECORD 
			--scroll_flag char(1), 
			ware_code LIKE warehouse.ware_code, 
			desc_text LIKE warehouse.desc_text, 
			contact_text LIKE warehouse.contact_text, 
			tele_text LIKE warehouse.tele_text,
			mobile_phone LIKE warehouse.mobile_phone ,
			email LIKE warehouse.email
		END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_warehouse_get_datasource(FALSE) RETURNING l_arr_rec_warehouse

		MESSAGE kandoomsg2("E",1178,"") 	#1178 "F1 TO add, RETURN on line TO change, F2 TO delete"
		DISPLAY ARRAY l_arr_rec_warehouse TO sr_warehouse.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","EZA","display-arr-warehouse")
				CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_warehouse.getSize())
				IF l_arr_rec_warehouse.getSize() = 0 THEN
					CALL dialog.setActionHidden("EDIT",TRUE)
				END IF	

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
				CALL l_arr_rec_warehouse.clear()
				CALL db_warehouse_get_datasource(TRUE) RETURNING l_arr_rec_warehouse

			ON ACTION "REFRESH"
				 CALL windecoration_i("I133")
				CALL l_arr_rec_warehouse.clear()
				CALL db_warehouse_get_datasource(FALSE) RETURNING l_arr_rec_warehouse


			ON ACTION ("EDIT","DOUBLECLICK") 
				LET l_idx = arr_curr() 
				IF edit_cycle(l_arr_rec_warehouse[l_idx].ware_code) THEN
					CALL l_arr_rec_warehouse.clear()
					CALL db_warehouse_get_datasource(FALSE) RETURNING l_arr_rec_warehouse
				END IF 

		END DISPLAY 

		LET int_flag = FALSE 
		LET quit_flag = FALSE
		 
END FUNCTION 
###########################################################################
# END FUNCTION scan_ware()
###########################################################################


###########################################################################
# FUNCTION edit_cycle(p_ware_code)
#
#
###########################################################################
FUNCTION edit_cycle(p_ware_code) 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_warehouse2 RECORD LIKE warehouse.* 
	DEFINE l_pick_print_text LIKE printcodes.desc_text 
	DEFINE l_inv_print_text LIKE printcodes.desc_text 
	DEFINE l_connote_print_text LIKE printcodes.desc_text 
	DEFINE l_ship_print_text LIKE printcodes.desc_text 
	DEFINE l_temp_text char(30) 
	DEFINE l_arr_datetime array[2] OF	RECORD 
		cycle_date DATE, 
		cycle_time char(5) 
	END RECORD 
	DEFINE l_err_message char(60) 
	DEFINE l_auto_run_num LIKE warehouse.auto_run_num 
	DEFINE l_next_pick_num LIKE warehouse.next_pick_num 
	DEFINE l_auto_run_num2 LIKE warehouse.auto_run_num 
	DEFINE l_recalculate_yn LIKE language.yes_flag  #KEEP This here

	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = p_ware_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN FALSE 
	END IF 
	
	LET l_auto_run_num2 = l_rec_warehouse.auto_run_num 
	LET l_next_pick_num = l_rec_warehouse.next_pick_num 
	LET l_rec_warehouse.city_text = 
		l_rec_warehouse.city_text clipped," ", 
		l_rec_warehouse.state_code clipped," ", 
		l_rec_warehouse.post_code clipped 
	
	OPEN WINDOW E293 with FORM "E293" 
	 CALL windecoration_e("E293") -- albo kd-755 

	LET l_temp_text = l_rec_warehouse.next_sched_date 
	LET l_arr_datetime[1].cycle_date = mdy(l_temp_text[6,7],l_temp_text[9,10],l_temp_text[1,4]) 
	LET l_arr_datetime[1].cycle_time = l_temp_text[12,16] 
	LET l_temp_text = CURRENT 
	LET l_arr_datetime[2].cycle_date = mdy(l_temp_text[6,7],l_temp_text[9,10],l_temp_text[1,4]) 
	LET l_arr_datetime[2].cycle_time = l_temp_text[12,16] 
	
	DISPLAY BY NAME 
		l_rec_warehouse.ware_code, 
		l_rec_warehouse.desc_text, 
		l_rec_warehouse.addr1_text, 
		l_rec_warehouse.addr2_text, 
		l_rec_warehouse.city_text 

	DISPLAY l_arr_datetime[1].cycle_date TO next_sched_date 
	DISPLAY l_arr_datetime[1].cycle_time TO next_sched_time 
	DISPLAY l_arr_datetime[2].cycle_date TO current_date 
	DISPLAY l_arr_datetime[2].cycle_time TO current_time 

	MESSAGE kandoomsg2("E",1179,"")	#1179 Enter Auto Delive Details
	INPUT BY NAME 
		l_rec_warehouse.auto_run_num, 
		l_rec_warehouse.pick_flag, 
		l_rec_warehouse.pick_print_code, 
		l_rec_warehouse.confirm_flag, 
		l_rec_warehouse.inv_flag, 
		l_rec_warehouse.inv_print_code, 
		l_rec_warehouse.connote_flag, 
		l_rec_warehouse.connote_print_code, 
		l_rec_warehouse.ship_label_flag, 
		l_rec_warehouse.ship_print_code, 
		l_rec_warehouse.next_pick_num, 
		l_rec_warehouse.pick_reten_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZA","input-l_rec_warehouse-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (pick_print_code) 
			LET modu_winds_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF modu_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.pick_print_code = modu_winds_text 
			END IF 
			NEXT FIELD pick_print_code 

		ON ACTION "LOOKUP" infield (inv_print_code) 
			LET modu_winds_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF modu_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.inv_print_code = modu_winds_text 
			END IF 
			NEXT FIELD inv_print_code 

		ON ACTION "LOOKUP" infield (connote_print_code) 
			LET modu_winds_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF modu_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.connote_print_code = modu_winds_text 
			END IF 
			NEXT FIELD connote_print_code 

		ON ACTION "LOOKUP" infield (ship_print_code) 
			LET modu_winds_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF modu_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.ship_print_code = modu_winds_text 
			END IF 
			NEXT FIELD ship_print_code 

		BEFORE FIELD auto_run_num 
			IF l_rec_warehouse.auto_run_num IS NULL THEN 
				LET l_auto_run_num = 0 
			ELSE 
				LET l_auto_run_num = l_rec_warehouse.auto_run_num 
			END IF 

		AFTER FIELD auto_run_num 
			IF l_rec_warehouse.auto_run_num < 0 THEN 
				ERROR kandoomsg2("I",9088,"") # 9088 A negative value IS NOT allowed
				NEXT FIELD auto_run_num 
			END IF
			 
			IF l_rec_warehouse.auto_run_num IS NULL THEN 
				LET l_rec_warehouse.next_sched_date = NULL 
				CLEAR next_sched_date, next_sched_time 
			ELSE 
				IF l_rec_warehouse.auto_run_num != l_auto_run_num THEN
				
					#----------------------------------------------------------- 
					#IF it was previously NULL be re-calculate.. Always...
					#-----------------------------------------------------------
					IF l_rec_warehouse.next_sched_date IS NULL THEN 
						LET l_rec_warehouse.next_sched_date = CURRENT year TO minute 
						LET l_recalculate_yn = "Y" 
					ELSE 
						LET l_recalculate_yn = kandoomsg("E",8007," ") #8003 Confirm TO recalculate (Y/N)"
						IF l_recalculate_yn = "Y" THEN	
							#-----------------------------------------------------------						 
							# First subtract old delivery cycle time
							# THEN add new delivery cycle time.
							#-----------------------------------------------------------
							LET l_rec_warehouse.next_sched_date = 
							l_rec_warehouse.next_sched_date - 
							l_auto_run_num units minute + 
							l_rec_warehouse.auto_run_num units minute 
							LET l_temp_text = l_rec_warehouse.next_sched_date 
							LET l_arr_datetime[1].cycle_date = mdy(l_temp_text[6,7],	l_temp_text[9,10],	l_temp_text[1,4]) 
							
							LET l_arr_datetime[1].cycle_time = l_temp_text[12,16] 
							DISPLAY l_arr_datetime[1].cycle_date TO next_sched_date 
							DISPLAY l_arr_datetime[1].cycle_time TO next_sched_time  
						END IF 
					END IF
				END IF 
			END IF 

		BEFORE FIELD pick_print_code 
			IF l_rec_warehouse.pick_flag = "N" THEN 
				LET l_rec_warehouse.pick_print_code = NULL 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD pick_print_code 
			IF l_rec_warehouse.pick_print_code IS NOT NULL THEN 
				SELECT desc_text INTO l_pick_print_text FROM printcodes 
				WHERE print_code = l_rec_warehouse.pick_print_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9509,"") #9509 Printer NOT defined
					NEXT FIELD pick_print_code 
				ELSE 
					DISPLAY BY NAME l_pick_print_text 

				END IF 
			END IF 

		BEFORE FIELD inv_print_code 
			IF l_rec_warehouse.inv_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD inv_print_code 
			IF l_rec_warehouse.inv_print_code IS NOT NULL THEN 
				SELECT desc_text INTO l_inv_print_text FROM printcodes 
				WHERE print_code = l_rec_warehouse.inv_print_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9509,"") #9509 Printer NOT defined
					NEXT FIELD inv_print_code 
				ELSE 
					DISPLAY BY NAME l_inv_print_text 

				END IF 
			END IF 

		BEFORE FIELD connote_print_code 
			IF l_rec_warehouse.connote_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD connote_print_code 
			IF l_rec_warehouse.connote_print_code IS NOT NULL THEN 
				SELECT desc_text INTO l_connote_print_text FROM printcodes 
				WHERE print_code = l_rec_warehouse.connote_print_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9509,"")		#9509 Printer NOT defined
					NEXT FIELD connote_print_code 
				ELSE 
					DISPLAY BY NAME l_connote_print_text 

				END IF 
			END IF 

		BEFORE FIELD ship_print_code 
			IF l_rec_warehouse.ship_label_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD ship_print_code 
			IF l_rec_warehouse.ship_print_code IS NOT NULL THEN 
				SELECT desc_text INTO l_ship_print_text FROM printcodes 
				WHERE print_code = l_rec_warehouse.ship_print_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9509,"") #9509 Printer NOT defined
					NEXT FIELD ship_print_code 
				ELSE 
					DISPLAY BY NAME l_ship_print_text 

				END IF 
			END IF 

		AFTER FIELD next_pick_num 
			IF l_rec_warehouse.next_pick_num IS NULL 
			OR l_rec_warehouse.next_pick_num <= 0 THEN 
				ERROR kandoomsg2("I",9085,"") # Must enter a value greater than zero.
				NEXT FIELD next_pick_num 
			END IF 
			SELECT unique 1 FROM pickhead 
			WHERE pick_num = l_rec_warehouse.next_pick_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_warehouse.ware_code 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("E",9255,"") #9255 This pick number has already been used.
				NEXT FIELD next_pick_num 
			END IF 

		AFTER FIELD pick_reten_num 
			IF l_rec_warehouse.pick_reten_num < 0 THEN 
				ERROR kandoomsg2("I",9088,"") # 9088 A negative value IS NOT allowed
				NEXT FIELD pick_reten_num 
			END IF 

	END INPUT 

	CLOSE WINDOW E293 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	GOTO bypass 
	LABEL recovery:
	 
	IF error_recover(l_err_message, status) != "Y" THEN 
		RETURN FALSE 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		DECLARE c2_warehouse cursor FOR 
		SELECT * FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		FOR UPDATE 

		OPEN c2_warehouse 
		FETCH c2_warehouse INTO l_rec_warehouse2.* 
		IF l_rec_warehouse2.next_pick_num != l_next_pick_num 
		OR l_rec_warehouse2.auto_run_num != l_auto_run_num2 THEN 
			ERROR kandoomsg2("E",7001,"") #7001 This warehouse has been editted
			ROLLBACK WORK 
			RETURN FALSE 
		END IF 
		LET l_err_message = "EZA - Updating warehouse" 

		UPDATE warehouse 
		SET pick_flag = l_rec_warehouse.pick_flag, 
		pick_print_code = l_rec_warehouse.pick_print_code, 
		confirm_flag = l_rec_warehouse.confirm_flag, 
		inv_flag = l_rec_warehouse.inv_flag, 
		inv_print_code = l_rec_warehouse.inv_print_code, 
		connote_flag = l_rec_warehouse.connote_flag, 
		connote_print_code = l_rec_warehouse.connote_print_code, 
		ship_label_flag = l_rec_warehouse.ship_label_flag, 
		ship_print_code = l_rec_warehouse.ship_print_code, 
		next_pick_num = l_rec_warehouse.next_pick_num, 
		pick_reten_num = l_rec_warehouse.pick_reten_num, 
		auto_run_num = l_rec_warehouse.auto_run_num, 
		next_sched_date = l_rec_warehouse.next_sched_date 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
	COMMIT WORK
	
	MESSAGE "Warehouse configuration updated" 
	RETURN TRUE 

END FUNCTION 
###########################################################################
# END FUNCTION edit_cycle(p_ware_code)
###########################################################################