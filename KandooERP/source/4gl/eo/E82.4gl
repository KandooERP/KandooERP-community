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
GLOBALS "../eo/E8_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E82_GLOBALS.4gl"
###########################################################################
#  FUNCTION E82_main() 
#
# E82 Allows the user TO enter AND maintain salesperson's commission structure
###########################################################################
FUNCTION E82_main() 
	DEFER QUIT 
	DEFER INTERRUPT
	
	CALL setModuleId("E82") -- albo 
 
	CALL scan_salesperson() 

END FUNCTION 
###########################################################################
#  FUNCTION E82_main() 
#
# E82 Allows the user TO enter AND maintain salesperson's commission structure
###########################################################################


###########################################################################
#  FUNCTION select_salesperson_datasource() 
#
# 
###########################################################################
FUNCTION select_salesperson_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD --array[50] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		terri_code LIKE salesperson.terri_code, 
		sale_type_ind LIKE salesperson.sale_type_ind 
	END RECORD
	DEFINE l_idx SMALLINT
	 
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") #1001 Enter selection criteria - ESC TO continue
	
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			city_text, 
			terri_code, 
			sale_type_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E82","construct-sale_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 
	
	MESSAGE kandoomsg2("E",1002,"")	#1002 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"sale_code" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	RETURN TRUE 

	LET l_idx = 0 
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesperson[l_idx].scroll_flag = NULL 
		LET l_arr_rec_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
		LET l_arr_rec_salesperson[l_idx].name_text = l_rec_salesperson.name_text 
		LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.city_text 
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
		ERROR kandoomsg2("E",9171,"") 	#9171 No salespersons satisfied the selection criteria
	END IF 

	RETURN l_arr_rec_salesperson
END FUNCTION 
###########################################################################
# END FUNCTION select_salesperson_datasource() 
###########################################################################


###########################################################################
#  FUNCTION scan_salesperson()  
#
# 
###########################################################################
FUNCTION scan_salesperson() 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD --array[50] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		terri_code LIKE salesperson.terri_code, 
		sale_type_ind LIKE salesperson.sale_type_ind 
	END RECORD 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW E164 with FORM "E164" 
	 CALL windecoration_e("E164") -- albo kd-755 

	CALL select_salesperson_datasource(FALSE) RETURNING l_arr_rec_salesperson

	MESSAGE kandoomsg2("E",1043,"") #1043 RETURN TO Edit - ESC TO Continue
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E82","input-arr-l_arr_rec_salesperson-1") -- albo kd-502
			IF NOT l_arr_rec_salesperson.getSize() THEN 
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				--CALL dialog.setActionHidden("EDIT",TRUE)			
			END IF

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesperson.clear()
			CALL select_salesperson_datasource(TRUE) RETURNING l_arr_rec_salesperson

		ON ACTION "REFRESH"
			CALL l_arr_rec_salesperson.clear()
			CALL select_salesperson_datasource(TRUE) RETURNING l_arr_rec_salesperson

		BEFORE ROW --FIELD scroll_flag 
			LET l_idx = arr_curr() 

--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_salesperson[l_idx].scroll_flag = NULL 
--			IF fgl_lastkey() = fgl_keyval("down") THEN 
--				IF l_arr_rec_salesperson[l_idx+1].sale_code IS NULL 
--				OR arr_curr() >= arr_count() THEN 
--					ERROR kandoomsg2("E",9001,"")	# There are no more rows in the direction you are going.
--					NEXT FIELD scroll_flag 
--				END IF 
--			END IF 
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD sale_code 
			IF l_arr_rec_salesperson[l_idx].sale_code IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 

			OPEN WINDOW E165 with FORM "E165"  
			 CALL windecoration_e("E165")

			DISPLAY l_arr_rec_salesperson[l_idx].sale_code TO sale_code 
			DISPLAY l_arr_rec_salesperson[l_idx].name_text TO name_text

			MENU " commission" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E82","menu-Commission-1") -- albo kd-502 

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Offer" " Commission FOR special offers" 
					IF select_strct(l_arr_rec_salesperson[l_idx].sale_code,"1") THEN 
						CALL edit_strct(l_arr_rec_salesperson[l_idx].sale_code,"1") 
					END IF 

				COMMAND "Condition" " Commission FOR sales conditions" 
					IF select_strct(l_arr_rec_salesperson[l_idx].sale_code,"2") THEN 
						CALL edit_strct(l_arr_rec_salesperson[l_idx].sale_code,"2") 
					END IF
					 
				COMMAND "Product" " Commission FOR products" 
					IF select_strct(l_arr_rec_salesperson[l_idx].sale_code,"3") THEN 
						CALL edit_strct(l_arr_rec_salesperson[l_idx].sale_code,"3") 
					END IF
					 
				COMMAND "Prodgrp" " Commission FOR product groups" 
					IF select_strct(l_arr_rec_salesperson[l_idx].sale_code,"4") THEN 
						CALL edit_strct(l_arr_rec_salesperson[l_idx].sale_code,"4") 
					END IF
					 
				COMMAND "Maingrp" " Commission FOR main product groups" 
					IF select_strct(l_arr_rec_salesperson[l_idx].sale_code,"5") THEN 
						CALL edit_strct(l_arr_rec_salesperson[l_idx].sale_code,"5") 
					END IF
					 
				COMMAND "Image" " Image structure FROM another salesperson" 
					CALL image_salestrct(l_arr_rec_salesperson[l_idx].sale_code)
					 
				COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO salespersons" 
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					EXIT MENU
					 
			END MENU 

			CLOSE WINDOW E165 
			NEXT FIELD scroll_flag

	END DISPLAY

	CLOSE WINDOW E164 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_salesperson()  
###########################################################################


###########################################################################
#  FUNCTION select_strct(p_sale_code,p_type_ind) 
#
# 
###########################################################################
FUNCTION select_strct(p_sale_code,p_type_ind) 
	DEFINE p_sale_code LIKE salestrct.sale_code 
	DEFINE p_type_ind LIKE salestrct.type_ind 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE i SMALLINT 

	FOR i = 1 TO 10 #??? 
		CLEAR sr_salestrct[i].* 
	END FOR 

	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON 
		type_code, 
		comm_per, 
		comm_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E82","construct-type_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "
		LET l_query_text = 
			"SELECT * FROM salestrct ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND sale_code = \"",p_sale_code,"\" ", 
			"AND type_ind = \"",p_type_ind,"\" ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 1,2,3,4" 
		PREPARE s_salestrct FROM l_query_text 
		DECLARE c_salestrct cursor FOR s_salestrct 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_strct(p_sale_code,p_type_ind) 
###########################################################################


###########################################################################
#  FUNCTION edit_strct(p_sale_code,p_type_ind)  
#
# 
###########################################################################
FUNCTION edit_strct(p_sale_code,p_type_ind) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_type_ind LIKE salestrct.type_ind 
	DEFINE l_rec_salestrct RECORD LIKE salestrct.* 
	DEFINE l_arr_rec_salestrct DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		type_code LIKE salestrct.type_code, 
		type_text LIKE product.desc_text, 
		comm_per LIKE salestrct.comm_per, 
		comm_amt LIKE salestrct.comm_amt 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_temp_text char(15) 
	DEFINE l_status_ind LIKE product.status_ind 
	DEFINE l_end_date LIKE offersale.end_date 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	FOREACH c_salestrct INTO l_rec_salestrct.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salestrct[l_idx].type_code = l_rec_salestrct.type_code 
		
		CASE p_type_ind 
			WHEN "1" 
				SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
				FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = l_rec_salestrct.type_code 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_salestrct[l_idx].type_text = "**********" 
				END IF 
				
			WHEN "2" 
				SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
				FROM condsale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cond_code = l_rec_salestrct.type_code 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_salestrct[l_idx].type_text = "**********" 
				END IF 
				
			WHEN "3" 
				SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_salestrct.type_code 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_salestrct[l_idx].type_text = "**********" 
				END IF 
				
			WHEN "4" 
				SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_salestrct.type_code 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_salestrct[l_idx].type_text = "**********" 
				END IF
				 
			WHEN "5" 
				SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_rec_salestrct.type_code 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_salestrct[l_idx].type_text = "**********" 
				END IF 
		END CASE 

		LET l_arr_rec_salestrct[l_idx].comm_per = l_rec_salestrct.comm_per 
		LET l_arr_rec_salestrct[l_idx].comm_amt = l_rec_salestrct.comm_amt 
--		IF l_idx = 100 THEN 
--			CASE p_type_ind 
--				WHEN "1" 
--					ERROR kandoomsg2("E",9035,"100") 	#9035 First ??? sales conditions selected only
--				WHEN "2" 
--					ERROR kandoomsg2("E",9010,"100") 	#9010 First ??? special offers selected only
--				WHEN "3" 
--					ERROR kandoomsg2("E",9157,"100") 	#9157 First ??? products selected only
--				WHEN "4" 
--					ERROR kandoomsg2("E",9159,"100") #9159 First ??? product groups selected only
--				WHEN "5" 
--					ERROR kandoomsg2("E",9160,"100") 	#9160 First ??? main product groups selected only
--			END CASE 
--			EXIT FOREACH 
--		END IF 
	END FOREACH 
	
--	CALL set_count(l_idx) 

	IF l_idx = 0 THEN 
		CASE p_type_ind 
			WHEN "1" 
				MESSAGE kandoomsg2("E",9011,"")#9011 No special offers satisfied selection criteria
			WHEN "2" 
				MESSAGE kandoomsg2("E",9036,"")#9036 No sales conditions satisfied selection criteria
			WHEN "3" 
				MESSAGE kandoomsg2("E",9156,"")#9156 No products satisfied selection criteria
			WHEN "4" 
				MESSAGE kandoomsg2("E",9165,"")#9165 No product groups satisfied selection criteria
			WHEN "5" 
				MESSAGE kandoomsg2("E",9166,"")#9166 No main product groups satisfied selection criteria
		END CASE 
	END IF 
	
	MESSAGE kandoomsg2("E",1003,"") 	#1003 F1 TO Add - F2 TO Delete - RETURN TO Edit

	OPTIONS DELETE KEY f36, 
	INSERT KEY f1
	 
	INPUT ARRAY l_arr_rec_salestrct WITHOUT DEFAULTS FROM sr_salestrct.* ATTRIBUTE(UNBUFFERED,DELETE ROW = FALSE,INSERT ROW = FALSE, AUTO APPEND = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E82","input-arr-l_arr_rec_salestrct-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(type_code)
				CASE p_type_ind 
					WHEN "1" 
						LET l_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,"end_date >= today") 
					WHEN "2" 
						LET l_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "3" 
						LET l_temp_text = show_part(glob_rec_kandoouser.cmpy_code,"status_ind = '1'") 
					WHEN "4" 
						LET l_temp_text = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "5" 
						LET l_temp_text = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
				END CASE 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				IF l_temp_text IS NOT NULL THEN 
					LET l_arr_rec_salestrct[l_idx].type_code = l_temp_text 
					NEXT FIELD type_code 
				END IF 
 
		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_salestrct[l_idx].scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_salestrct[l_idx].scroll_flag = l_scroll_flag 

			
		AFTER FIELD type_code 
			CASE p_type_ind 
				WHEN "1" 
					SELECT desc_text, end_date 
					INTO l_arr_rec_salestrct[l_idx].type_text, l_end_date 
					FROM offersale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = l_arr_rec_salestrct[l_idx].type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9161,"")		#9161 Special offer does NOT exist - Try Window
						LET l_arr_rec_salestrct[l_idx].type_code = NULL 
						NEXT FIELD type_code 
					END IF 
					IF l_end_date < today THEN 
						ERROR kandoomsg2("E",9174,"") 	#9174 Special offer IS NOT longer valid
						NEXT FIELD type_code 
					END IF
					 
				WHEN "2" 
					SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
					FROM condsale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cond_code = l_arr_rec_salestrct[l_idx].type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9055,"") 			#9055 Sales condition does NOT exist - Try Window
						LET l_arr_rec_salestrct[l_idx].type_code = NULL 
						NEXT FIELD type_code 
					END IF
					 
				WHEN "3" 
					SELECT desc_text, status_ind 
					INTO l_arr_rec_salestrct[l_idx].type_text, l_status_ind 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_arr_rec_salestrct[l_idx].type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9162,"") 			#9162 Product does NOT exist - Try Window
						LET l_arr_rec_salestrct[l_idx].type_code = NULL 
						NEXT FIELD type_code 
					END IF 
					
					IF l_status_ind = "2" THEN 
						ERROR kandoomsg2("E",9172,"") 		#9172 Product IS put on hold - Release before proceeding
						NEXT FIELD type_code 
					END IF
					 
					IF l_status_ind = "3" THEN 
						ERROR kandoomsg2("E",9173,"")	#9173 Product IS marked FOR deletion -Unmark before proceeding
						NEXT FIELD type_code 
					END IF 
					
				WHEN "4" 
					SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
					FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = l_arr_rec_salestrct[l_idx].type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9163,"")	#9163 Product group does NOT exist - Try Window
						LET l_arr_rec_salestrct[l_idx].type_code = NULL 
						NEXT FIELD type_code 
					END IF 
					
				WHEN "5" 
					SELECT desc_text INTO l_arr_rec_salestrct[l_idx].type_text 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_arr_rec_salestrct[l_idx].type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9164,"")	#9164 Main product group does NOT exist - Try Window
						LET l_arr_rec_salestrct[l_idx].type_code = NULL 
						NEXT FIELD type_code 
					END IF 
			END CASE 

			NEXT FIELD comm_per 

		AFTER FIELD comm_per 
			IF l_arr_rec_salestrct[l_idx].comm_per < 0 THEN 
				ERROR kandoomsg2("E",9169,"")		#9169 Commission percentage may NOT be negative
				NEXT FIELD comm_per 
			END IF 
			
			IF l_arr_rec_salestrct[l_idx].comm_per IS NOT NULL THEN 
				LET l_arr_rec_salestrct[l_idx].comm_amt = NULL 
				NEXT FIELD scroll_flag 
			END IF 
			NEXT FIELD comm_amt
			 
		AFTER FIELD comm_amt 
			IF l_arr_rec_salestrct[l_idx].comm_amt < 0 THEN 
				ERROR kandoomsg2("E",9170,"")	#9170 Commission amount may NOT be negative
				NEXT FIELD comm_amt 
			END IF
			 
			IF l_arr_rec_salestrct[l_idx].comm_amt IS NULL 
			AND l_arr_rec_salestrct[l_idx].comm_per IS NULL THEN 
				ERROR kandoomsg2("E",9167,"")	#9167 Either commiss. percentage OR commiss. amount must be entered
				NEXT FIELD comm_amt 
			END IF 
			
			IF l_arr_rec_salestrct[l_idx].comm_amt IS NOT NULL 
			AND l_arr_rec_salestrct[l_idx].comm_per IS NOT NULL THEN 
				ERROR kandoomsg2("E",9167,"")	#9167 Either commiss. percentage OR commiss. amount must be entered
				NEXT FIELD comm_amt 
			END IF 
			IF l_arr_rec_salestrct[l_idx+1].type_code IS NULL 
			OR arr_curr() >= arr_count() THEN 
				NEXT FIELD scroll_flag 
			END IF

		ON KEY (f2) 
			IF l_arr_rec_salestrct[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_salestrct[l_idx].scroll_flag = "*" 
			ELSE 
				LET l_arr_rec_salestrct[l_idx].scroll_flag = NULL 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET l_idx = arr_curr() 
				INITIALIZE l_arr_rec_salestrct[l_idx].* TO NULL 
				NEXT FIELD type_code 
			ELSE 
				IF l_idx > 1 THEN 
					ERROR kandoomsg2("E",9001,"")	#9001There are no more rows in the direction you are going
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		
		IF error_recover(glob_err_message,status) != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 

			LET glob_err_message = "Deleting tagged sales commission structure rows" 
			FOR l_idx = 1 TO arr_count() 
				IF l_arr_rec_salestrct[l_idx].scroll_flag = "*" THEN 
					DELETE FROM salestrct 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = p_sale_code 
					AND type_ind = p_type_ind 
					AND type_code = l_arr_rec_salestrct[l_idx].type_code 
				END IF 
			END FOR 

			LET glob_err_message = "Inserting/updating sales commission structure rows" 
			FOR l_idx = 1 TO arr_count() 
				IF l_arr_rec_salestrct[l_idx].scroll_flag IS NULL 
				AND l_arr_rec_salestrct[l_idx].type_code IS NOT NULL THEN 
					UPDATE salestrct 
					SET comm_amt = l_arr_rec_salestrct[l_idx].comm_amt, 
					comm_per = l_arr_rec_salestrct[l_idx].comm_per 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = p_sale_code 
					AND type_ind = p_type_ind 
					AND type_code = l_arr_rec_salestrct[l_idx].type_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET l_rec_salestrct.cmpy_code =glob_rec_kandoouser.cmpy_code 
						LET l_rec_salestrct.sale_code =p_sale_code 
						LET l_rec_salestrct.type_ind = p_type_ind 
						LET l_rec_salestrct.type_code= l_arr_rec_salestrct[l_idx].type_code 
						LET l_rec_salestrct.comm_per = l_arr_rec_salestrct[l_idx].comm_per 
						LET l_rec_salestrct.comm_amt = l_arr_rec_salestrct[l_idx].comm_amt 
						INSERT INTO salestrct VALUES (l_rec_salestrct.*) 
					END IF 
				END IF 
			END FOR 

		COMMIT WORK 

		WHENEVER ERROR stop 
	END IF 

END FUNCTION
###########################################################################
#  END FUNCTION edit_strct(p_sale_code,p_type_ind)  
###########################################################################


###########################################################################
# FUNCTION image_salestrct(p_sale_code)  
#
# 
###########################################################################
FUNCTION image_salestrct(p_sale_code) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_salestrct RECORD LIKE salestrct.* 
	DEFINE l_offer_flag char(1) 
	DEFINE l_condition_flag char(1) 
	DEFINE l_product_flag char(1) 
	DEFINE l_prodgrp_flag char(1) 
	DEFINE l_maingrp_flag char(1) 
	DEFINE l_temp_text char(15) 
	DEFINE l_where_text char(50) 
	DEFINE l_query_text char(150) 
	DEFINE i SMALLINT 

	OPEN WINDOW E166 with FORM "E166" 
	 CALL windecoration_e("E166") -- albo kd-755
 
	MESSAGE kandoomsg2("E",1044,"") #1044 Enter Image criteria - F9 TO toggle - ESC TO Continue
	INITIALIZE 
		l_condition_flag, 
		l_offer_flag, 
		l_product_flag, 
		l_prodgrp_flag, 
		l_maingrp_flag TO NULL 

	INPUT 
		l_rec_salesperson.sale_code, 
		l_offer_flag, 
		l_condition_flag, 
		l_product_flag, 
		l_prodgrp_flag, 
		l_maingrp_flag WITHOUT DEFAULTS 
	FROM
		sale_code, 
		l_offer_flag, 
		condition_flag, 
		product_flag, 
		prodgrp_flag, 
		maingrp_flag ATTRIBUTE(UNBUFFERED)
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E82","input-l_rec_salesperson-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(sale_code) 
				LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
				IF l_temp_text IS NOT NULL THEN 
					LET l_rec_salesperson.sale_code = l_temp_text 
					NEXT FIELD sale_code 
				END IF 

		ON KEY (f9) infield(l_offer_flag) 
					IF l_offer_flag IS NULL THEN 
						LET l_offer_flag = "*" 
					ELSE 
						LET l_offer_flag = NULL 
					END IF 
					DISPLAY BY NAME l_offer_flag 

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(l_condition_flag) 
					IF l_condition_flag IS NULL THEN 
						LET l_condition_flag = "*" 
					ELSE 
						LET l_condition_flag = NULL 
					END IF 
					DISPLAY BY NAME l_condition_flag 

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(l_product_flag) 
					IF l_product_flag IS NULL THEN 
						LET l_product_flag = "*" 
					ELSE 
						LET l_product_flag = NULL 
					END IF 
					DISPLAY BY NAME l_product_flag 

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(l_prodgrp_flag) 
					IF l_prodgrp_flag IS NULL THEN 
						LET l_prodgrp_flag = "*" 
					ELSE 
						LET l_prodgrp_flag = NULL 
					END IF 
					DISPLAY BY NAME l_prodgrp_flag 

					NEXT FIELD NEXT 

		ON KEY (f9) infield(l_maingrp_flag) 
					IF l_maingrp_flag IS NULL THEN 
						LET l_maingrp_flag = "*" 
					ELSE 
						LET l_maingrp_flag = NULL 
					END IF 
					DISPLAY BY NAME l_maingrp_flag 

					NEXT FIELD l_offer_flag 
 
		AFTER FIELD sale_code 
			IF l_rec_salesperson.sale_code = p_sale_code THEN 
				ERROR kandoomsg2("E",9168,"") 	#9168 Source salesperson may NOT be = destination salesperson
				NEXT FIELD sale_code 
			END IF

			#get sales person record	 
			CALL db_salesperson_get_rec(UI_OFF,l_rec_salesperson.sale_code) RETURNING l_rec_salesperson.*			 
			
			IF l_rec_salesperson.sale_code IS NULL THEN
				ERROR kandoomsg2("E",9050,"") 		#9050 Salesperson does NOT exist - Try window
				NEXT FIELD sale_code 
			ELSE 
				DISPLAY BY NAME l_rec_salesperson.name_text 

			END IF 
			FOR i = 1 TO 5 
				SELECT unique 1 FROM salestrct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_rec_salesperson.sale_code 
				AND type_ind = i 
				IF sqlca.sqlcode = 0 THEN 
					CASE i 
						WHEN 1 
							LET l_offer_flag = "*" 
							DISPLAY BY NAME l_offer_flag 

						WHEN 2 
							LET l_condition_flag = "*" 
							DISPLAY BY NAME l_condition_flag 

						WHEN 3 
							LET l_product_flag = "*" 
							DISPLAY BY NAME l_product_flag 

						WHEN 4 
							LET l_prodgrp_flag = "*" 
							DISPLAY BY NAME l_prodgrp_flag 

						WHEN 5 
							LET l_maingrp_flag = "*" 
							DISPLAY BY NAME l_maingrp_flag 

					END CASE 
				END IF 
			END FOR 

		AFTER INPUT 
			IF l_offer_flag = "*" THEN 
				LET l_where_text = " '1'" 
			END IF 
			IF l_condition_flag = "*" THEN 
				LET l_where_text = l_where_text clipped,",'2'" 
			END IF 
			IF l_product_flag = "*" THEN 
				LET l_where_text = l_where_text clipped,",'3'" 
			END IF 
			IF l_prodgrp_flag = "*" THEN 
				LET l_where_text = l_where_text clipped,",'4'" 
			END IF 
			IF l_maingrp_flag = "*" THEN 
				LET l_where_text = l_where_text clipped,",'5'" 
			END IF 
			LET l_where_text[1,1] = " " 
	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		IF l_condition_flag = "*" 
		OR l_offer_flag = "*" 
		OR l_product_flag = "*" 
		OR l_prodgrp_flag = "*" 
		OR l_maingrp_flag = "*" THEN
			IF promptTF("",kandoomsg2("E",8018,""),1)	THEN	#8018 Image sales commission structure (Y/N)?
				GOTO bypass 
				LABEL recovery:
				 
				IF error_recover(glob_err_message,status) != "Y" THEN 
					EXIT PROGRAM 
				END IF 
				
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 

				BEGIN WORK 

					LET glob_err_message = "Deleting tagged sales commission structure types" 
					LET l_query_text = 
						"DELETE FROM salestrct ", 
						"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
						"AND sale_code = \"",p_sale_code,"\" ", 
						"AND type_ind in (",l_where_text clipped,")" 
					PREPARE s1_salestrct FROM l_query_text 
					EXECUTE s1_salestrct 
					LET glob_err_message ="Inserting tagged sales commission structure types" 
					LET l_query_text = 
						"SELECT * FROM salestrct ", 
						"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
						"AND sale_code = \"",l_rec_salesperson.sale_code,"\" ", 
						"AND type_ind in (",l_where_text clipped,")" 
					PREPARE s2_salestrct FROM l_query_text 
					DECLARE c2_salestrct cursor FOR s2_salestrct 
					FOREACH c2_salestrct INTO l_rec_salestrct.* 
						LET l_rec_salestrct.sale_code = p_sale_code 
						INSERT INTO salestrct VALUES (l_rec_salestrct.*) 
					END FOREACH 

				COMMIT WORK 

				WHENEVER ERROR stop 
			END IF 
		END IF 
	END IF 
	
	CLOSE WINDOW E166 
END FUNCTION 
###########################################################################
# END FUNCTION image_salestrct(p_sale_code)  
###########################################################################