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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ3_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_customer RECORD LIKE customer.*
##################################################################
# FUNCTION AZ3_main()
#
# \brief module AZ3 - Salesperson Maintanence
##################################################################
FUNCTION AZ3_main() 
	DEFINE i SMALLINT 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("AZ3") 

	--SELECT country.* 
	--INTO glob_rec_country.* 
	--FROM company, 
	--country 
	--WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
	--AND country.country_code = company.country_code 
	--IF status = NOTFOUND THEN 
	--	LET glob_rec_country.state_code_text ="State........" 
	--	LET glob_rec_country.post_code_text = "Post Code.........." 
	--ELSE 
	--	LET i = length(glob_rec_country.state_code_text) 
	--	LET glob_rec_country.state_code_text[i+1,20] = "................." 
	--	LET i = length(glob_rec_country.post_code_text) 
	--	LET glob_rec_country.post_code_text[i+1,20] = "................." 
	--END IF 

	OPEN WINDOW A159 with FORM "A159" 
	CALL windecoration_a("A159") 

	CALL AZ3_sales_maintenance()
--	WHILE AZ3_rpt_query() 
--		LET l_withquery = AZ3_sales_maintenance() 
--		IF l_withquery = 2 OR int_flag THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 

	CLOSE WINDOW A159 
END FUNCTION 
##################################################################
# END FUNCTION AZ3_main()
##################################################################


##################################################################
# FUNCTION AZ3_rpt_query(p_withquery)
# select_sales
#
##################################################################
FUNCTION AZ3_rpt_query(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			city_text, 
			terri_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ3","construct-sale") 

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

	RETURN l_where_text 

END FUNCTION 
##################################################################
# END FUNCTION AZ3_rpt_query(p_withquery)
##################################################################


##################################################################
# FUNCTION AZ3_sales_datasource(p_where_text)
#
#
##################################################################
FUNCTION AZ3_sales_datasource(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_idx SMALLINT 	
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY of	RECORD 
			sale_code LIKE salesperson.sale_code, 
			name_text LIKE salesperson.name_text, 
			city_text LIKE salesperson.city_text, 
			terri_code LIKE salesperson.terri_code, 
			sale_type_ind LIKE salesperson.sale_type_ind 
		END RECORD 

	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY 1,2" 

	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson CURSOR FOR s_salesperson 


	LET l_idx = 0 
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
		LET l_arr_rec_salesperson[l_idx].name_text = l_rec_salesperson.name_text 

		IF l_rec_salesperson.city_text IS NULL THEN 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.addr2_text 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.city_text 
		END IF 

		LET l_arr_rec_salesperson[l_idx].terri_code = l_rec_salesperson.terri_code 

		IF l_rec_salesperson.sale_type_ind = "2" THEN 
			LET l_arr_rec_salesperson[l_idx].sale_type_ind = "*" 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].sale_type_ind = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF				

	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9077,"")	#9077 " No Salespersons Selected"
	END IF 
		
	RETURN l_arr_rec_salesperson	

END FUNCTION 
##################################################################
# END FUNCTION AZ3_sales_datasource(p_where_text)
##################################################################


##################################################################
# FUNCTION AZ3_sales_maintenance()
# Scan and process sales
# AZ3 - Salesperson Maintenance
##################################################################
FUNCTION AZ3_sales_maintenance() 
	DEFINE l_filter BOOLEAN
	#DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD 
			sale_code LIKE salesperson.sale_code, 
			name_text LIKE salesperson.name_text, 
			city_text LIKE salesperson.city_text, 
			terri_code LIKE salesperson.terri_code, 
			sale_type_ind LIKE salesperson.sale_type_ind 
		END RECORD 
--		DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_qty SMALLINT 

	IF db_salesperson_get_count() > glob_rec_settings.maxListArraySizeSwitch THEN
		LET l_filter = TRUE
	ELSE
		LET l_filter = FALSE		
	END IF

	CALL AZ3_sales_datasource(AZ3_rpt_query(l_filter)) RETURNING l_arr_rec_salesperson

	MESSAGE kandoomsg2("A",1098,"") #1003 F1 TO add, RETURN TO edit, F2 TO delete, F5 TO Reassign"
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZ3","inp-arr-salesperson")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("REASSIGN AND REPORT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_salesperson.getSize())
 
		ON ACTION "FILTER"
			CALL l_arr_rec_salesperson.clear()
			CALL AZ3_sales_datasource(AZ3_rpt_query(TRUE)) RETURNING l_arr_rec_salesperson 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("REASSIGN AND REPORT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_salesperson.getSize())
			
		ON ACTION "REFRESH" 
			CALL windecoration_a("A159") 
			CALL l_arr_rec_salesperson.clear()
			CALL AZ3_sales_datasource(AZ3_rpt_query(FALSE)) RETURNING l_arr_rec_salesperson 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("REASSIGN AND REPORT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_salesperson.getSize())
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REASSIGN AND REPORT"	#ON KEY (F5) --reassign salesperson TO different area
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN 
				IF l_arr_rec_salesperson[l_idx].sale_code IS NOT NULL THEN 
					CALL AZ3_adjust_salesperson_rpt(l_arr_rec_salesperson[l_idx].sale_code) 
				END IF 
	
				CALL l_arr_rec_salesperson.clear()
				CALL AZ3_sales_datasource(AZ3_rpt_query(TRUE)) RETURNING l_arr_rec_salesperson #return TO TABLE AND refresh 
			END IF
			
		ON ACTION ("EDIT","doubleClick","ACCEPT")
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN		 
				IF l_arr_rec_salesperson[l_idx].sale_code IS NOT NULL THEN 
					IF edit_sale(l_arr_rec_salesperson[l_idx].sale_code) THEN 
						SELECT 
							name_text, 
							city_text, 
							terri_code, 
							sale_type_ind 
						INTO 
							l_arr_rec_salesperson[l_idx].name_text, 
							l_arr_rec_salesperson[l_idx].city_text, 
							l_arr_rec_salesperson[l_idx].terri_code, 
							l_arr_rec_salesperson[l_idx].sale_type_ind 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 
	
						IF l_arr_rec_salesperson[l_idx].city_text IS NULL THEN 
							SELECT addr2_text 
							INTO l_arr_rec_salesperson[l_idx].city_text 
							FROM salesperson 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 
						END IF 
	
						IF l_arr_rec_salesperson[l_idx].sale_type_ind = "2" THEN #huho.. hmm NOT sure what this IS about 
							LET l_arr_rec_salesperson[l_idx].sale_type_ind = "*" 
						ELSE 
							LET l_arr_rec_salesperson[l_idx].sale_type_ind = NULL 
						END IF 
	
					END IF 
	
				END IF 
	
				RETURN 0 
			END IF
			
		ON ACTION "ADD"
			LET l_idx = arr_curr()
			LET l_rowid = edit_sale("") 
			IF l_idx > 0 THEN
				SELECT 
					sale_code, 
					name_text, 
					city_text, 
					terri_code, 
					sale_type_ind 
				INTO 
					l_arr_rec_salesperson[l_idx].sale_code, 
					l_arr_rec_salesperson[l_idx].name_text, 
					l_arr_rec_salesperson[l_idx].city_text, 
					l_arr_rec_salesperson[l_idx].terri_code, 
					l_arr_rec_salesperson[l_idx].sale_type_ind 
				FROM salesperson 
				WHERE rowid = l_rowid 
	
				IF status <> NOTFOUND THEN 
					IF l_arr_rec_salesperson[l_idx].city_text IS NULL THEN 
						SELECT addr2_text 
						INTO l_arr_rec_salesperson[l_idx].city_text 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 
					END IF 
	
					IF l_arr_rec_salesperson[l_idx].sale_type_ind = "2" THEN 
						LET l_arr_rec_salesperson[l_idx].sale_type_ind = "*" 
					ELSE 
						LET l_arr_rec_salesperson[l_idx].sale_type_ind = NULL 
					END IF 
				END IF 
			END IF

		ON ACTION "DELETE" 
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN
				IF l_arr_rec_salesperson[l_idx].sale_code IS NOT NULL THEN 
					IF NOT saleperson_active(l_arr_rec_salesperson[l_idx].sale_code) THEN 
	
	
						LET l_del_qty = 1 
						IF kandoomsg("A",8008,l_del_qty) = "Y" THEN 	#8008 Confirm TO Delete ",l_del_qty,"Sales persons(s)? (Y/N)"
							IF NOT saleperson_active(l_arr_rec_salesperson[l_idx].sale_code) THEN 
								DELETE FROM salesperson 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 

								DELETE FROM salestrct 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 
							END IF 
						END IF 
	
						RETURN 0 
	
					END IF 
				END IF 
			END IF
			
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("REASSIGN AND REPORT",NOT l_arr_rec_salesperson.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_salesperson.getSize())
	
	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	END IF 

END FUNCTION 
##################################################################
# END FUNCTION AZ3_sales_maintenance()
##################################################################


##################################################################
# FUNCTION edit_sale(p_sale_code)
#
#
##################################################################
FUNCTION edit_sale(p_sale_code) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_sale_cnt SMALLINT 

	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*
	
	IF l_rec_salesperson.sale_code IS NULL THEN
		LET l_rec_salesperson.sale_type_ind = "3" 
		LET l_rec_salesperson.country_code = trim(get_ku_country_code())  --trim(glob_rec_country.country_code) 
		LET l_rec_salesperson.language_code = trim(get_ku_language_code())  --trim(glob_rec_country.language_code) 
	END IF 

	OPEN WINDOW A610 with FORM "A610" 
	CALL windecoration_a("A610") 

	MESSAGE kandoomsg2("A",1016,"") #1016 Enter salesperson details - ESC TO Continue
	--DISPLAY BY NAME glob_rec_country.state_code_text, 
	--glob_rec_country.post_code_text 
	#ATTRIBUTE(white)
	CALL db_country_localize(l_rec_salesperson.country_code) #Localize
	
	IF l_rec_salesperson.terri_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_territory.desc_text 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = l_rec_salesperson.terri_code 
		IF status = NOTFOUND THEN 
			LET l_rec_territory.desc_text = "**********" 
		END IF 
		DISPLAY l_rec_territory.desc_text TO territory.desc_text 

	END IF 
	IF l_rec_salesperson.mgr_code IS NOT NULL THEN 
		SELECT name_text INTO l_rec_salesmgr.name_text 
		FROM salesmgr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND mgr_code = l_rec_salesperson.mgr_code 
		IF status = NOTFOUND THEN 
			LET l_rec_salesmgr.name_text = "**********" 
		END IF 
		DISPLAY l_rec_salesmgr.name_text TO salesmgr.name_text 

	END IF 
	IF l_rec_salesperson.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_warehouse.desc_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_rec_salesperson.ware_code 
		IF status = NOTFOUND THEN 
			LET l_rec_warehouse.desc_text = "**********" 
		END IF 
		DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 

	END IF 

	INPUT BY NAME 
		l_rec_salesperson.sale_code, 
		l_rec_salesperson.name_text, 
		l_rec_salesperson.addr1_text, 
		l_rec_salesperson.addr2_text, 
		l_rec_salesperson.city_text, 
		l_rec_salesperson.state_code, 
		l_rec_salesperson.post_code, 
		l_rec_salesperson.country_code, 
		l_rec_salesperson.language_code, 
		l_rec_salesperson.terri_code, 
		l_rec_salesperson.mgr_code, 
		l_rec_salesperson.ware_code, 
		l_rec_salesperson.tele_text, 
		l_rec_salesperson.fax_text, 
		l_rec_salesperson.mobile_phone,
		l_rec_salesperson.email,		
		l_rec_salesperson.alt_tele_text, 
		l_rec_salesperson.comm_per, 
		l_rec_salesperson.comm_ind, 
		l_rec_salesperson.sale_type_ind, 
		l_rec_salesperson.com1_text, 
		l_rec_salesperson.com2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ3","inp-salesperson") 
			CALL db_country_localize(l_rec_salesperson.country_code) #Localize 
		
		ON CHANGE country_code
			CALL db_country_localize(l_rec_salesperson.country_code) #Localize

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (country_code) 
			LET glob_temp_text = show_country() 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.country_code = glob_temp_text 
				NEXT FIELD country_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (language_code) 
			LET glob_temp_text = show_language() 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.language_code = glob_temp_text 
				NEXT FIELD language_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (terri_code) 
			LET glob_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.terri_code = glob_temp_text 
				NEXT FIELD terri_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (mgr_code) 
			LET glob_temp_text = show_salesmgr(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.mgr_code = glob_temp_text 
				NEXT FIELD mgr_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (ware_code) 
			LET glob_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.ware_code = glob_temp_text 
				NEXT FIELD ware_code 
			END IF 

		BEFORE FIELD sale_code 
			IF p_sale_code IS NOT NULL THEN 
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD sale_code 
			IF l_rec_salesperson.sale_code IS NULL THEN 
				ERROR kandoomsg2("A",9031,"") 			#9031" Salesperson must be entered
				NEXT FIELD sale_code 

			ELSE 

				SELECT unique 1 FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_rec_salesperson.sale_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9090,"") 				#9090" Salesperson already exists - Please Re Enter "
					NEXT FIELD sale_code 
				END IF 
			END IF 

		AFTER FIELD name_text 
			IF l_rec_salesperson.name_text IS NULL THEN 
				ERROR kandoomsg2("A",9079,"") 			#9079 Salesperson name OR description must be Entered
				NEXT FIELD name_text 
			END IF 


		BEFORE FIELD state_code
			CALL db_country_localize(l_rec_salesperson.country_code) #Localize  

		AFTER FIELD country_code 
			IF l_rec_salesperson.country_code IS NULL THEN 
				ERROR kandoomsg2("A",9047,"") 
				#9047 country must be entered
				NEXT FIELD country_code 
			END IF 
			#Language code has changed - lanuage IS no longer = country
			#ELSE
			#
			#            SELECT language_code
			#              INTO l_rec_salesperson.language_code
			#              FROM language
			#             WHERE country_code = l_rec_salesperson.language_code
			#            IF STATUS = NOTFOUND THEN
			#               ERROR kandoomsg2("A",9047,"")
			#               #9047 country NOT found - try window
			#               NEXT FIELD country_code
			#            END IF
			#         END IF

		AFTER FIELD terri_code 
			CLEAR territory.desc_text 
			IF l_rec_salesperson.terri_code IS NOT NULL THEN 
				SELECT * INTO l_rec_territory.* 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = l_rec_salesperson.terri_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9084,"") 				#9084 Sales territory NOT found - try window
					NEXT FIELD terri_code 
				END IF 

				IF l_rec_territory.sale_code IS NOT NULL 
				AND l_rec_salesperson.sale_code IS NOT NULL 
				AND l_rec_territory.sale_code != l_rec_salesperson.sale_code THEN 
					ERROR kandoomsg2("A",7044,l_rec_territory.sale_code) 				#7044 This territory has salesperson
					NEXT FIELD terri_code 
				END IF 

				DISPLAY l_rec_territory.desc_text 
				TO territory.desc_text 

			END IF 

		AFTER FIELD mgr_code 
			CLEAR salesmgr.name_text 
			IF l_rec_salesperson.mgr_code IS NOT NULL THEN 
				#ERROR kandoomsg2("A",9011,"")			##9011 sales manager must be entered
				#NEXT FIELD mgr_code
				#ELSE
				SELECT * INTO l_rec_salesmgr.* 
				FROM salesmgr 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND mgr_code = l_rec_salesperson.mgr_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9085,"") 				#9085 Sales manager NOT found - try window
					NEXT FIELD mgr_code 
				ELSE 
					DISPLAY l_rec_salesmgr.name_text 
					TO salesmgr.name_text 

				END IF 
			END IF 

		AFTER FIELD ware_code 
			CLEAR warehouse.desc_text 
			IF l_rec_salesperson.ware_code IS NULL THEN 
				#ERROR kandoomsg2("A",9092,"") ##9092 Warehouse must be entered  #HuHo 19.11.19 - Wareshouse code should be optional ->docs
				
				#NEXT FIELD ware_code
			ELSE 
				SELECT * INTO l_rec_warehouse.* 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_salesperson.ware_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9091,"") 	#9091 Warehouse NOT found - try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text 
					TO warehouse.desc_text 

				END IF 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM country 
				WHERE country_code = l_rec_salesperson.country_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9047,"") 		#9047 country NOT found - try window
					NEXT FIELD country_code 
				END IF 

				SELECT unique 1 FROM language 
				WHERE language_code = l_rec_salesperson.language_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9037,"") 		#9037" Language does NOT Exist - Try Window"
					NEXT FIELD language_code 
				END IF 

				IF l_rec_salesperson.mgr_code IS NOT NULL THEN 
					SELECT unique 1 FROM salesmgr 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND mgr_code = l_rec_salesperson.mgr_code 


					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9085,"")#9085" Sales Manager does NOT Exist - Try Window" #removed because docs statest, this IS optional 
						
						NEXT FIELD mgr_code 
					END IF 
				END IF 

				IF l_rec_salesperson.ware_code IS NOT NULL THEN 
					SELECT unique 1 FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = l_rec_salesperson.ware_code 

					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9091,"")			#9091" Warehouse does NOT Exist - Try Window"
						NEXT FIELD ware_code 
					END IF 
				END IF 

				#sales persons commission in percent
				IF l_rec_salesperson.comm_per IS NULL THEN 
					LET l_rec_salesperson.comm_per = 0 
				END IF 

				IF l_rec_salesperson.sale_type_ind = "2" THEN 
					SELECT unique 1 FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code != l_rec_salesperson.sale_code 
					AND terri_code = l_rec_salesperson.terri_code 
					AND sale_type_ind = "2" 
					IF status = 0 THEN 
						ERROR kandoomsg2("A",7018,l_rec_salesperson.terri_code) 			#7018 This sales territory has an existing primary
						LET l_rec_salesperson.sale_type_ind = "3" 
						NEXT FIELD sale_type_ind 
					END IF 
				END IF 

				IF l_rec_salesperson.terri_code IS NOT NULL THEN 
					SELECT count(*) INTO l_sale_cnt 
					FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = l_rec_salesperson.sale_code 

					CASE l_sale_cnt 
						WHEN "0" 
							EXIT CASE 
						WHEN "1" 
							SELECT terr_code INTO glob_temp_text 
							FROM territory 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND sale_code = l_rec_salesperson.sale_code 
							IF l_rec_salesperson.terri_code != glob_temp_text THEN 
								ERROR kandoomsg2("A",7046,glob_temp_text) 							#7046 This salesalesperson has an territory
								LET l_rec_salesperson.terri_code = glob_temp_text 
								NEXT FIELD terri_code 
							END IF 
						OTHERWISE 
							ERROR kandoomsg2("A",7047,"") 						#7047 This salesalesperson has many territory
							NEXT FIELD terri_code 
					END CASE 

				END IF 

			ELSE 

				IF p_sale_code IS NULL THEN 
					IF l_rec_salesperson.sale_code IS NOT NULL THEN 
						IF kandoomsg("A",8004,"") = "N" THEN 
							CONTINUE INPUT 
						END IF 
					END IF 
				END IF 
				LET quit_flag = true 
			END IF 

	END INPUT 
	#########################


	CLOSE WINDOW A610 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		IF p_sale_code IS NULL THEN 
			LET l_rec_salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO salesperson VALUES (l_rec_salesperson.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE salesperson 
			SET salesperson.* = l_rec_salesperson.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_sale_code 
			RETURN sqlca.sqlerrd[3] 
		END IF 
	END IF 
END FUNCTION 
##################################################################
# END FUNCTION edit_sale(p_sale_code)
##################################################################


##################################################################
# FUNCTION saleperson_active(p_sale_code)
#
#
##################################################################
FUNCTION saleperson_active(p_sale_code) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	
	SELECT unique 1 FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = p_sale_code 

	IF sqlca.sqlcode = 0 THEN 
		MESSAGE kandoomsg2("A",7017,p_sale_code) 	#7017 Sales Person assigned TO Customer, No Deletion
		RETURN true 
	ELSE 
		SELECT unique 1 FROM quotehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sales_code = p_sale_code 
		AND status_ind in ("O","Q") 

		IF sqlca.sqlcode = 0 THEN 
			MESSAGE kandoomsg2("A",7019,p_sale_code) 		#7019 Sales Person appears on quotation, No Deletion
			RETURN true 
		ELSE 
			SELECT unique 1 FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sales_code = p_sale_code 
			AND status_ind in ("U","P") 

			IF sqlca.sqlcode = 0 THEN 
				MESSAGE kandoomsg2("A",7020,p_sale_code) 			#7020 Sales Person appears on sales ORDER, No Deletion
				RETURN true 
			ELSE 
				SELECT unique 1 FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = p_sale_code 
				AND paid_amt != total_amt 
				AND posted_flag = "N" 

				IF sqlca.sqlcode = 0 THEN 
					MESSAGE kandoomsg2("A",7021,p_sale_code) 				#7021 Sales Person appears on invoice, No Deletion
					RETURN true 
				ELSE 
					RETURN false 
				END IF 

			END IF 
		END IF 
	END IF 
END FUNCTION 
##################################################################
# END FUNCTION saleperson_active(p_sale_code)
##################################################################


##################################################################
# FUNCTION AZ3_adjust_salesperson_rpt(p_sale_code)
#
#
##################################################################
FUNCTION AZ3_adjust_salesperson_rpt(p_sale_code) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_rpt_idx SMALLINT #report array index
	#DEFINE modu_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_name_text LIKE salesperson.name_text 
	DEFINE l_addr1_text LIKE salesperson.addr1_text 
	DEFINE l_addr2_text LIKE salesperson.addr2_text 
	DEFINE l_city_text LIKE salesperson.city_text 
	DEFINE l_state_code LIKE salesperson.state_code 
	DEFINE l_post_code LIKE salesperson.post_code 
	DEFINE l_terri_code LIKE salesperson.terri_code 
	DEFINE l_success_cnt SMALLINT 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_error_text CHAR(80) 
	DEFINE l_err_message CHAR(80) 
	DEFINE l_temp_text CHAR(40) 
	DEFINE l_page_no SMALLINT #huho moved FROM GLOBALS 

	OPEN WINDOW A694 with FORM "A694" 
	CALL windecoration_a("A694") 

	MESSAGE kandoomsg2("U",1020,"Salesperson") 
	
	CALL db_salesperson_get_rec(UI_ON,p_sale_code) RETURNING l_rec_salesperson.*

	LET l_name_text = l_rec_salesperson.name_text 
	LET l_addr1_text = l_rec_salesperson.addr1_text 
	LET l_addr2_text = l_rec_salesperson.addr2_text 
	LET l_state_code = l_rec_salesperson.state_code 
	LET l_city_text = l_rec_salesperson.city_text 
	LET l_post_code = l_rec_salesperson.post_code 
	LET l_terri_code = l_rec_salesperson.terri_code 
	
	DISPLAY p_sale_code TO sale_code
	DISPLAY l_name_text TO name_text 
	DISPLAY l_addr1_text TO addr1_text 
	DISPLAY l_addr2_text TO addr2_text
	DISPLAY l_state_code TO state_code 
	DISPLAY l_city_text TO city_text 
	DISPLAY l_post_code TO post_code 
	DISPLAY l_terri_code TO terri_code 

	INITIALIZE l_rec_salesperson.* TO NULL 

	INPUT BY NAME l_rec_salesperson.sale_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ3","inp-sale_code") 
			CALL db_country_localize(l_rec_salesperson.country_code) #Localize  

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (sale_code)	#ON KEY (control-b) infield (sale_code) 
			LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_salesperson.sale_code = l_temp_text 
				NEXT FIELD sale_code 
			END IF 

		ON ACTION ("TO-Sales-Person-Preview","Preview") 
			IF l_rec_salesperson.sale_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD sale_code 
			END IF 

			#get sales person record
			CALL db_salesperson_get_rec(UI_OFF,l_rec_salesperson.sale_code) RETURNING l_rec_salesperson.*
			
			IF l_rec_salesperson.sale_code IS NULL THEN
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD Not Found; Try Window.
				NEXT FIELD sale_code 
			END IF

			IF p_sale_code = l_rec_salesperson.sale_code THEN 
				ERROR kandoomsg2("A",9528,"") 			#9528 TO salesperson IS same as FROM salesperson
				NEXT FIELD sale_code 
			END IF 

			DISPLAY BY NAME 
				l_rec_salesperson.name_text, 
				l_rec_salesperson.addr1_text, 
				l_rec_salesperson.addr2_text, 
				l_rec_salesperson.state_code, 
				l_rec_salesperson.city_text, 
				l_rec_salesperson.post_code, 
				l_rec_salesperson.terri_code 

		AFTER FIELD sale_code 
			IF l_rec_salesperson.sale_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD sale_code 
			END IF 

			#get sales person record
			CALL db_salesperson_get_rec(UI_OFF,l_rec_salesperson.sale_code) RETURNING l_rec_salesperson.*
			
			IF l_rec_salesperson.sale_code IS NULL THEN
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD Not Found; Try Window.
				NEXT FIELD sale_code 
			END IF

			IF p_sale_code = l_rec_salesperson.sale_code THEN 
				ERROR kandoomsg2("A",9528,"") 			#9528 TO salesperson IS same as FROM salesperson
				NEXT FIELD sale_code 
			END IF 

			CLEAR name_text, addr1_text, addr2_text, state_code, city_text, post_code, terri_code 

			DISPLAY BY NAME 
				l_rec_salesperson.name_text, 
				l_rec_salesperson.addr1_text, 
				l_rec_salesperson.addr2_text, 
				l_rec_salesperson.state_code, 
				l_rec_salesperson.city_text, 
				l_rec_salesperson.post_code, 
				l_rec_salesperson.terri_code 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_salesperson.sale_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"")		#9102 Value must be entered
					NEXT FIELD sale_code 
				END IF 

				IF kandoomsg("A",8042,"") = "N" THEN 
					NEXT FIELD sale_code 
				END IF 

				ERROR kandoomsg2("U",1005,"") 

				GOTO bypass 

				LABEL recovery: 
				IF error_recover(l_err_message,status) != "Y" THEN 
					EXIT INPUT 
				END IF 

				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--				IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--					LET int_flag = false 
--					LET quit_flag = false
--			
--					RETURN FALSE
--				END IF
			
				LET l_rpt_idx = rpt_start(getmoduleid(),"AZ3_rpt_sale_except"," 1=1 ", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT AZ3_rpt_sale_except TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				DECLARE c2_customer CURSOR with HOLD FOR 
				SELECT * FROM customer 
				WHERE sale_code = p_sale_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
				LET l_success_cnt = 0 
				LET l_err_cnt = 0 

				FOREACH c2_customer INTO modu_rec_customer.* 
					BEGIN WORK 
						DECLARE c3_customer CURSOR FOR 
						SELECT * FROM customer 
						WHERE cust_code = modu_rec_customer.cust_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						FOR UPDATE
						 
						OPEN c3_customer 
						FETCH c3_customer INTO modu_rec_customer.* 
						INITIALIZE l_rec_territory.* TO NULL 
						
						SELECT * INTO l_rec_territory.* FROM territory 
						WHERE terr_code = modu_rec_customer.territory_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 

						IF l_rec_salesperson.sale_code != l_rec_territory.sale_code	AND l_rec_territory.sale_code IS NOT NULL THEN 
							ROLLBACK WORK 
							LET l_error_text = 
							"Customer territory ",l_rec_territory.terr_code clipped, 
							" has already been assigned the salesperson ", 
							l_rec_territory.sale_code clipped,"." 


							#---------------------------------------------------------
							OUTPUT TO REPORT AZ3_rpt_sale_except(l_rpt_idx,modu_rec_customer.cust_code, l_error_text,l_page_no)
							#IF NOT rpt_int_flag_handler2("Customer:",modu_rec_customer.cust_code, modu_rec_customer.name_text,l_rpt_idx) THEN
							#	EXIT FOREACH 
							#END IF 
							#---------------------------------------------------------
					
							 
							LET l_err_cnt = l_err_cnt + 1 
							CONTINUE FOREACH 
						END IF 

						IF l_rec_salesperson.terri_code != modu_rec_customer.territory_code 
						AND l_rec_salesperson.terri_code IS NOT NULL THEN 
							ROLLBACK WORK 
							LET l_error_text = 
							"Salesperson ",l_rec_salesperson.sale_code clipped, 
							" does NOT operate within the customer territory ", 
							modu_rec_customer.territory_code clipped, "." 

							#---------------------------------------------------------
							OUTPUT TO REPORT AZ3_rpt_sale_except(l_rpt_idx,modu_rec_customer.cust_code, l_error_text,l_page_no)
							#IF NOT rpt_int_flag_handler2("Customer:",modu_rec_customer.cust_code, modu_rec_customer.name_text,l_rpt_idx) THEN
							#	EXIT FOREACH 
							#END IF 
							#---------------------------------------------------------							
							
							 
							LET l_err_cnt = l_err_cnt + 1 
							CONTINUE FOREACH 
						END IF 

						LET l_err_message = "AZ3 - Update Customer Sale Code" 
						
						UPDATE customer 
						SET sale_code = l_rec_salesperson.sale_code 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = modu_rec_customer.cust_code 
					
					COMMIT WORK 
					LET l_success_cnt = l_success_cnt + 1 
				END FOREACH 

				LET int_flag = false 
				LET quit_flag = false 
			END IF 


	END INPUT 
	###########################


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		CLOSE WINDOW A694 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		RETURN 
	END IF 
	  
	IF l_err_cnt > 0 THEN 
		IF l_success_cnt = 0 THEN 
			ERROR kandoomsg2("A",7098,l_err_cnt)	#7098 Salesperson UPDATE failed.
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].printnow_flag = "Y"
		ELSE 
			ERROR kandoomsg2("A",7096,l_success_cnt) #7096 Salesperson UPDATE partially successful.
			LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].printnow_flag = "Y" 
		END IF 
	ELSE 
		MESSAGE kandoomsg2("A",7097,l_success_cnt) #7096 Salesperson UPDATE successful.
		--LET glob_arr_rec_rpt_rmsreps[l_rpt_idx].printnow_flag = "N"
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AZ3_rpt_sale_except
	CALL rpt_finish("AZ3_rpt_sale_except")
	#------------------------------------------------------------

	CLOSE WINDOW A694 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION 
##################################################################
# END FUNCTION AZ3_adjust_salesperson_rpt(p_sale_code)
##################################################################


##################################################################
# REPORT AZ3_rpt_sale_except(p_cust_code,p_reason,p_page_no)
#
#
##################################################################
REPORT AZ3_rpt_sale_except(p_rpt_idx,p_reason,p_page_no)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_cust_code LIKE customer.cust_code 
	#DEFINE modu_rec_customer RECORD LIKE customer.*
	DEFINE p_reason CHAR(80) 
	DEFINE p_page_no SMALLINT #huho moved FROM GLOBALS 

	OUTPUT 
 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, today USING "dd/mm/yyyy", 46 spaces, "Sales Exception Report", 45 spaces, "Page: ",p_page_no USING "##&" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Customer Reason" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
		ON EVERY ROW 
			SELECT * INTO modu_rec_customer.* FROM customer 
			WHERE cust_code = p_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 01,modu_rec_customer.cust_code, 
			COLUMN 10,modu_rec_customer.name_text, 
			COLUMN 50,p_reason 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
##################################################################
# END REPORT AZ3_rpt_sale_except(p_cust_code,p_reason,p_page_no)
##################################################################