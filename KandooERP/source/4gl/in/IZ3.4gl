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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../in/I_IN_GLOBALS.4gl" 
GLOBALS "../in/IZ_GROUP_GLOBALS.4gl"
GLOBALS "../in/IZ3_GLOBALS.4gl"

####################################################################
# FUNCTION IZ3_main()
#
# IZ3 Allows the user TO enter AND maintain warehouses
####################################################################
FUNCTION IZ3_main() 
	DEFER quit 
	DEFER interrupt 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("IZ3") 

	OPEN WINDOW I133 with FORM "I133" 
	 CALL windecoration_i("I133") 

	CALL scan_warehouse() 

	CLOSE WINDOW I133 
END FUNCTION 
####################################################################
# END FUNCTION IZ3_main()
####################################################################

####################################################################
# FUNCTION db_warehouse_get_datasourcce(p_filter)
#
#
####################################################################
FUNCTION db_warehouse_get_datasourcce(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF t_rec_warehouse_w_d_c_t 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("I",1001,"")	#1001 Enter selection criteria - ESC TO continue
		CONSTRUCT BY NAME l_where_text ON 
			ware_code, 
			desc_text, 
			contact_text, 
			tele_text ,
			mobile_phone,
			email 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IZ3","construct-ware_code-1") -- albo kd-505 
	
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE 
		LET l_where_text = " 1=1 "
	END IF

	MESSAGE kandoomsg2("I",1002,"")		#1002 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM warehouse ", 
		"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY ware_code" 
	#      PREPARE s_warehouse FROM l_query_text
	#      DECLARE c_warehouse CURSOR FOR s_warehouse
	#      RETURN TRUE

	CALL db_warehouse_get_arr_rec_w_d_c_t(filter_query_off,null) RETURNING l_arr_rec_warehouse 

	RETURN l_arr_rec_warehouse 
	 
END FUNCTION 
####################################################################
# END FUNCTION db_warehouse_get_datasourcce(p_filter)
####################################################################


####################################################################
# FUNCTION scan_warehouse()
#
#
####################################################################
FUNCTION scan_warehouse() 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	#	DEFINE pr_scroll_flag CHAR(1)
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF t_rec_warehouse_w_d_c_t 
	#      of record
	# #        scroll_flag CHAR(1),
	#         ware_code LIKE warehouse.ware_code,
	#         desc_text LIKE warehouse.desc_text,
	#         contact_text LIKE warehouse.contact_text,
	#         tele_text LIKE warehouse.tele_text
	#      END RECORD,
	DEFINE l_query_text CHAR(500) 
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 
	DEFINE del_cnt SMALLINT 

	CALL db_warehouse_get_datasourcce(FALSE) RETURNING l_arr_rec_warehouse 

	#   LET l_idx = 0
	#   FOREACH c_warehouse INTO l_rec_warehouse.*
	#      LET l_idx = l_idx + 1
	#      LET l_arr_rec_warehouse[l_idx].scroll_flag = NULL
	#      LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code
	#      LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text
	#      LET l_arr_rec_warehouse[l_idx].contact_text = l_rec_warehouse.contact_text
	#      LET l_arr_rec_warehouse[l_idx].tele_text = l_rec_warehouse.tele_text
	#   END FOREACH
	#   IF l_idx = 0 THEN
	#      ERROR kandoomsg2("I",9087,"")  #9087 " No warehouses satisfied the selection criteria"
	#      LET l_idx = 1
	#   END IF
	#
	#   OPTIONS INSERT KEY F1,
	#           DELETE KEY F36
	#   #CALL set_count(l_idx)
	#
	#   MESSAGE kandoomsg2("I",1003,"")  # "F1 TO add, RETURN on line TO change, F2 TO delete"
	#   #INPUT ARRAY l_arr_rec_warehouse WITHOUT DEFAULTS FROM sr_warehouse.*
	DISPLAY ARRAY l_arr_rec_warehouse TO sr_warehouse.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZ3","input-arr-l_arr_rec_warehouse-1") -- albo kd-505
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_warehouse.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_warehouse.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_warehouse.clear()
			CALL db_warehouse_get_datasourcce(TRUE) RETURNING l_arr_rec_warehouse 
	
		ON ACTION "REFRESH"
			 CALL windecoration_i("I133") 
			CALL l_arr_rec_warehouse.clear()
			CALL db_warehouse_get_datasourcce(FALSE) RETURNING l_arr_rec_warehouse 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			
		ON ACTION ("EDIT","DOUBLECLICK") 
			LET l_idx = arr_curr() #to be sure we take the focused line/row 
			CALL edit_warehouse(l_arr_rec_warehouse[l_idx].ware_code) 
				RETURNING l_rec_warehouse.cmpy_code,l_rec_warehouse.ware_code
			
			IF l_arr_rec_warehouse[l_idx].ware_code IS NOT NULL THEN 
				SELECT 
					desc_text, 
					contact_text, 
					tele_text ,
					mobile_phone,
					email
				INTO 
					l_arr_rec_warehouse[l_idx].desc_text, 
					l_arr_rec_warehouse[l_idx].contact_text, 
					l_arr_rec_warehouse[l_idx].tele_text ,
					l_arr_rec_warehouse[l_idx].mobile_phone,
					l_arr_rec_warehouse[l_idx].email
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_arr_rec_warehouse[l_idx].ware_code 

				CALL l_arr_rec_warehouse.clear()
				CALL db_warehouse_get_datasourcce(FALSE) RETURNING l_arr_rec_warehouse 
			END IF 

		ON ACTION "NEW" 
			#BEFORE INSERT
			#			IF arr_curr() < arr_count() THEN
			--LET l_rowid = edit_warehouse("")
			CALL edit_warehouse("") RETURNING l_rec_warehouse.cmpy_code,l_rec_warehouse.ware_code 
			##### No rowids please !!!!!!

			SELECT 
				ware_code,
				desc_text,
				contact_text,
				tele_text,
				mobile_phone,
				email
			INTO 
				l_arr_rec_warehouse[l_idx].ware_code,
				l_arr_rec_warehouse[l_idx].desc_text,
				l_arr_rec_warehouse[l_idx].contact_text,
				l_arr_rec_warehouse[l_idx].tele_text,
				l_arr_rec_warehouse[l_idx].mobile_phone,
				l_arr_rec_warehouse[l_idx].email
			FROM warehouse
			WHERE cmpy_code = l_rec_warehouse.cmpy_code
				AND ware_code = l_rec_warehouse.ware_code
			--IF STATUS = NOTFOUND THEN
				--FOR l_idx = arr_curr() TO arr_count()
					--LET l_arr_rec_warehouse[l_idx].* = l_arr_rec_warehouse[l_idx+1].*
					--IF scrn <= 14 THEN
						--DISPLAY l_arr_rec_warehouse[l_idx].*
						--TO sr_warehouse[scrn].*
						--LET scrn = scrn + 1
					--END IF
				--END FOR
				--INITIALIZE l_arr_rec_warehouse[l_idx].* TO NULL
			--END IF
			#			END IF
				CALL l_arr_rec_warehouse.clear()
				CALL db_warehouse_get_datasourcce(FALSE) RETURNING l_arr_rec_warehouse 
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_warehouse.getSize())
				
		ON ACTION "DELETE" 
			IF delete_warehouse(l_arr_rec_warehouse[l_idx].ware_code) THEN 
				DELETE FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_arr_rec_warehouse[l_idx].ware_code 

				CALL l_arr_rec_warehouse.clear()
				CALL db_warehouse_get_datasourcce(FALSE) RETURNING l_arr_rec_warehouse 

			END IF 

			#      ON KEY(F2)
			#         IF l_arr_rec_warehouse[l_idx].ware_code IS NOT NULL THEN
			#            IF l_arr_rec_warehouse[l_idx].scroll_flag IS NULL THEN
			#               IF delete_warehouse(l_arr_rec_warehouse[l_idx].ware_code) THEN
			#                  LET l_arr_rec_warehouse[l_idx].scroll_flag = "*"
			#                  LET del_cnt = del_cnt + 1
			#               END IF
			#            ELSE
			#              LET l_arr_rec_warehouse[l_idx].scroll_flag = NULL
			#              LET del_cnt = del_cnt - 1
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag
			#     AFTER ROW
			#         DISPLAY l_arr_rec_warehouse[l_idx].* TO sr_warehouse[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END DISPLAY 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	#	ELSE
	#      IF del_cnt > 0 THEN
	#         IF kandoomsg("I",8003,del_cnt) = "Y" THEN
	#            #8003 Confirm TO Delete ",del_cnt," warehouse(s)? (Y/N)"
	#            ERROR kandoomsg2("I",1005,"")
	#            FOR l_idx = 1 TO arr_count()
	#               IF l_arr_rec_warehouse[l_idx].scroll_flag = "*" THEN
	#                  IF delete_warehouse(l_arr_rec_warehouse[l_idx].ware_code) THEN
	#                     DELETE FROM warehouse
	#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#                          AND ware_code = l_arr_rec_warehouse[l_idx].ware_code
	#                  END IF
	#               END IF
	#            END FOR
	#         END IF
	#      END IF
	#	END IF
END FUNCTION 
####################################################################
# END FUNCTION scan_warehouse()
####################################################################


####################################################################
# FUNCTION edit_warehouse(p_ware_code)
#
#
####################################################################
FUNCTION edit_warehouse(p_ware_code) 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE l_rec_cartarea RECORD LIKE cartarea.* 
	DEFINE l_mask_code LIKE account.acct_code 
	DEFINE l_acct_desc_text LIKE coa.desc_text 
	DEFINE l_winds_text CHAR(60) 
	DEFINE l_entry_flag SMALLINT 

	IF p_ware_code IS NOT NULL THEN 
		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		IF sqlca.sqlcode = notfound THEN 
			RETURN false 
		END IF 
	ELSE 
		LET l_rec_warehouse.back_order_ind = "0" 
		LET l_rec_warehouse.pick_flag = "N" 
		LET l_rec_warehouse.pick_print_code = "" 
		LET l_rec_warehouse.confirm_flag = "N" 
		LET l_rec_warehouse.inv_flag = "N" 
		LET l_rec_warehouse.inv_print_code = "" 
		LET l_rec_warehouse.connote_flag = "N" 
		LET l_rec_warehouse.ship_label_flag = "N" 
		LET l_rec_warehouse.next_pick_num = 1 
		LET l_rec_warehouse.pick_reten_num = NULL 
		LET l_rec_warehouse.auto_run_num = NULL 
		LET l_rec_warehouse.next_sched_date = NULL 
	END IF 

	OPEN WINDOW I132 with FORM "I132" 
	 CALL windecoration_i("I132") 

	IF l_rec_warehouse.waregrp_code IS NOT NULL THEN 
		SELECT * INTO l_rec_waregrp.* 
		FROM waregrp 
		WHERE waregrp_code = l_rec_warehouse.waregrp_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		DISPLAY l_rec_waregrp.name_text TO waregrp_text	attribute(white) 
	END IF 

	IF l_rec_warehouse.cart_area_code IS NOT NULL THEN 
		SELECT * INTO l_rec_cartarea.* 
		FROM cartarea 
		WHERE cart_area_code = l_rec_warehouse.cart_area_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		DISPLAY l_rec_cartarea.desc_text TO cart_text attribute(white) 
	END IF 

	INPUT BY NAME 
		l_rec_warehouse.ware_code, 
		l_rec_warehouse.desc_text, 
		l_rec_warehouse.addr1_text, 
		l_rec_warehouse.addr2_text, 
		l_rec_warehouse.city_text, 
		l_rec_warehouse.state_code, 
		l_rec_warehouse.post_code, 
		l_rec_warehouse.country_code, 
		l_rec_warehouse.waregrp_code, 
		l_rec_warehouse.cart_area_code, 
		l_rec_warehouse.map_gps_coordinates, 
		l_rec_warehouse.contact_text, 
		l_rec_warehouse.tele_text, 
		l_rec_warehouse.mobile_phone,
		l_rec_warehouse.email,
		l_rec_warehouse.back_order_ind, 
		l_rec_warehouse.acct_mask_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ3","input-l_rec_warehouse-1") -- albo kd-505 
			#CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_warehouse.country_code,COMBO_NULL_SPACE)
			CALL db_country_localize(l_rec_warehouse.country_code) #Localize
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REFRESH" 
			 CALL windecoration_i("I132") 

		ON CHANGE country_code 
		--CALL comboList_state("",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_warehouse.country_code,COMBO_NULL_SPACE) 
			#CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_warehouse.country_code,COMBO_NULL_SPACE)
			CALL db_country_localize(l_rec_warehouse.country_code) #Localize

		ON ACTION "LOOKUP" infield (cart_area_code) 
			LET l_winds_text = show_cart_area(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.cart_area_code = l_winds_text 
				SELECT * INTO l_rec_cartarea.* 
				FROM cartarea 
				WHERE cart_area_code = l_rec_warehouse.cart_area_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY l_rec_cartarea.desc_text TO cart_text 
				attribute(white) 
			END IF 
			NEXT FIELD cart_area_code 

		-- KD-2021: ericv 2020-04-30 City is not suburb, disabled this combo
		-- ON KEY (control-b) infield (city_text) 
			-- LET l_winds_text = show_wsub(glob_rec_kandoouser.cmpy_code) 
			-- IF l_winds_text IS NOT NULL THEN 
				-- SELECT suburb_text INTO l_rec_warehouse.city_text 
				-- FROM suburb 
				-- WHERE suburb_code = l_winds_text 
				-- AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				-- NEXT FIELD city_text 
			-- END IF 

		ON ACTION "LOOKUP" infield (waregrp_code) 
			LET l_winds_text = show_waregrp() 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_warehouse.waregrp_code = l_winds_text 
				SELECT * INTO l_rec_waregrp.* 
				FROM waregrp 
				WHERE waregrp_code = l_rec_warehouse.waregrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY l_rec_waregrp.name_text TO waregrp_text 	attribute(white) 
			END IF 
			NEXT FIELD waregrp_code 

		BEFORE FIELD ware_code 
			IF p_ware_code IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD ware_code 
			IF l_rec_warehouse.ware_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_warehouse.desc_text
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_warehouse.ware_code 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("I",9083,"") # Warehouse Code already exists
					NEXT FIELD ware_code 
				END IF 
			END IF 

		-- KD-2021: ericv 2020-04-30 City is not suburb, disabled this combo
		--AFTER FIELD city_text 
			--IF l_rec_warehouse.city_text IS NOT NULL THEN 
				--IF getModuleState("W") THEN 
					#IF glob_rec_company.module_text[23,23] = "W" THEN
					--SELECT unique 1 FROM suburb 
					--WHERE suburb_text = l_rec_warehouse.city_text 
					--AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					--IF status = notfound THEN 
						--ERROR kandoomsg2("W",9201,"") # Suburb NOT found try window
						--NEXT FIELD city_text 
					--END IF 
				--END IF 
			--END IF 
		AFTER FIELD state_code
			DISPLAY BY NAME l_rec_warehouse.state_code
			
		AFTER FIELD waregrp_code 
			CLEAR waregrp_text 
			IF l_rec_warehouse.waregrp_code IS NOT NULL THEN 
				IF getModuleState("W") THEN 
					#IF glob_rec_company.module_text[23,23] = "W" THEN
					SELECT * INTO l_rec_waregrp.* 
					FROM waregrp 
					WHERE waregrp_code = l_rec_warehouse.waregrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = notfound THEN 
						ERROR kandoomsg2("W",9375,"") # 9375 Warehouse Group code NOT found - use window
						NEXT FIELD waregrp_code 
					ELSE 
						DISPLAY l_rec_waregrp.name_text TO waregrp_text	attribute(white) 
					END IF 
				END IF 
			END IF 

		AFTER FIELD cart_area_code 
			IF l_rec_warehouse.cart_area_code IS NOT NULL THEN 
				IF getModuleState("W") THEN 
					#IF glob_rec_company.module_text[23,23] = "W" THEN
					SELECT * INTO l_rec_cartarea.* 
					FROM cartarea 
					WHERE cart_area_code = l_rec_warehouse.cart_area_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = notfound THEN 
						ERROR kandoomsg2("W",9202,"") 				# Cartage area NOT found - Try window
						NEXT FIELD cart_area_code 
					ELSE 
						DISPLAY l_rec_cartarea.desc_text TO cart_text	attribute(white) 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD acct_mask_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
			RETURNING l_mask_code 
			
			IF l_rec_warehouse.acct_mask_code IS NULL OR l_rec_warehouse.acct_mask_code = " " THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
				RETURNING l_rec_warehouse.acct_mask_code 
			END IF 
			
			CALL account_fill(glob_rec_kandoouser.cmpy_code,l_mask_code,	l_rec_warehouse.acct_mask_code,4,"User Defaults") 
			RETURNING l_rec_warehouse.acct_mask_code,l_acct_desc_text,l_entry_flag 
			
			DISPLAY BY NAME l_rec_warehouse.acct_mask_code 

			LET int_flag = false 
			LET quit_flag = false 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF l_rec_warehouse.ware_code IS NULL THEN 
					ERROR kandoomsg2("I",9029,"") # Warehouse code must be entered.
					NEXT FIELD ware_code 
				END IF 

				IF l_rec_warehouse.desc_text IS NULL THEN 
					ERROR kandoomsg2("I",9084,"") 		# 9084 Must enter description
					NEXT FIELD desc_text 
				END IF 
				
				IF getModuleState("W") THEN  #Company has got warehouse enabled 
					IF glob_rec_company.module_text[23,23] = "W" THEN
						IF l_rec_warehouse.waregrp_code IS NULL THEN 
							ERROR kandoomsg2("W",9365,"") 				# Warehouse Group must be entered
							NEXT FIELD waregrp_code 
						END IF 
						IF l_rec_warehouse.city_text IS NULL THEN 
							ERROR kandoomsg2("U",9102,"") 					# Value must be entered
							NEXT FIELD city_text 
						END IF 
						--IF l_rec_warehouse.cart_area_code IS NULL THEN 
						--	ERROR kandoomsg2("W",9044,"") # Cartage area must be entered
						--	NEXT FIELD cart_area_code 
						--END IF 
						IF l_rec_warehouse.map_gps_coordinates IS NULL THEN 
							ERROR kandoomsg2("W",9037,"") 			# Map reference must be entered
							NEXT FIELD map_gps_coordinates 
						END IF 
					END IF
				END IF				 
			END IF 
	END INPUT 

	CLOSE WINDOW I132
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF p_ware_code IS NULL THEN 
			LET l_rec_warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO warehouse VALUES (l_rec_warehouse.*)
			# No Rowids: return primary key 
			--RETURN sqlca.sqlerrd[6] 
			RETURN l_rec_warehouse.cmpy_code,l_rec_warehouse.ware_code
		ELSE 
			UPDATE warehouse 
			SET warehouse.* = l_rec_warehouse.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_ware_code 
			-- RETURN sqlca.sqlerrd[3]
			RETURN l_rec_warehouse.cmpy_code,l_rec_warehouse.ware_code 
		END IF 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION edit_warehouse(p_ware_code)
####################################################################


####################################################################
# FUNCTION delete_warehouse(p_ware_code)
#
#
####################################################################
FUNCTION delete_warehouse(p_ware_code) 
	DEFINE p_ware_code LIKE warehouse.ware_code 

	SELECT unique 1 FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	AND mast_ware_code = p_ware_code 
	IF sqlca.sqlcode = 0 THEN 
		ERROR kandoomsg2("I",7023 ,p_ware_code)	#7023 According TO inventory param. Main warehouse, No Deletion
		RETURN false 
	ELSE 
		SELECT unique 1 FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		IF sqlca.sqlcode = 0 THEN 
			ERROR kandoomsg2("I",7024,p_ware_code)			#7024 Warehouse appears on product, No Deletion
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION delete_warehouse(p_ware_code)
####################################################################