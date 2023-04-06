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
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A15_GLOBALS.4gl" 

###########################################################################
# FUNCTION A15_main()
#
# Purpose - Allows the user TO enter AND maintain cust
#           noncredit AND non-shipping information only
#
# Accepts as an argument a customer code FOR editting. IF the argument
# exists THEN the initial scan SCREEN IS bypassed.
###########################################################################
FUNCTION A15_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A15") 

	CALL create_table("customernote","t_customernote","","Y") 
	CALL create_table("stnd_custgrp","t1_stnd_custgrp","","N") 

	IF get_url_cust_code() IS NOT NULL THEN 
		CALL A15_edit(get_url_cust_code()) #CUSTOMER_CODE
	ELSE 
		OPEN WINDOW A106 with FORM "A106" 
		CALL windecoration_a("A106") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		CALL scan_cust() 

		CLOSE WINDOW A106 
	END IF 
	
END FUNCTION
###########################################################################
# END FUNCTION A15_main()
###########################################################################


#######################################################################
# FUNCTION get_customer_datasource(p_filter,p_hide_delete_customers) 
#
#
#######################################################################
FUNCTION get_customer_datasource(p_filter,p_hide_delete_customers) 
	DEFINE p_filter boolean 
	DEFINE p_hide_delete_customers boolean 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		contact_text LIKE customer.contact_text, 
		delete_date LIKE customer.delete_date, 
		delete_flag LIKE customer.delete_flag
	END RECORD 

	DEFINE l_where_text STRING 
	DEFINE l_where2_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_where2_text = NULL 
		MESSAGE kandoomsg2("A",1078,"") 

		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			name_text, 
			contact_text, 
			delete_date 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A15","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F8) 
				LET l_where2_text = report_criteria(glob_rec_kandoouser.cmpy_code,"AR") 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF l_where2_text IS NULL THEN 
		LET l_where2_text = " 1=1 " 
	END IF 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped, " ", 
	"AND ",l_where2_text clipped , " " 

	IF p_hide_delete_customers THEN 
		LET l_query_text = trim(l_query_text), " AND (delete_flag != 'Y' OR delete_flag IS NULL) ", " " 
	END IF 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY name_text,cust_code" 
	END IF 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	LET l_idx = 0 
	FOREACH c_customer INTO glob_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
		LET l_arr_rec_customer[l_idx].cust_code = glob_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = glob_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].contact_text = glob_rec_customer.contact_text 
		LET l_arr_rec_customer[l_idx].delete_flag = glob_rec_customer.delete_flag
		LET l_arr_rec_customer[l_idx].delete_date = glob_rec_customer.delete_date 

		IF l_arr_rec_customer[l_idx].delete_date = "31/12/1899" THEN 
			LET l_arr_rec_customer[l_idx].delete_date = NULL 
		END IF 
		
		IF l_arr_rec_customer[l_idx].delete_date IS NOT NULL THEN 
			LET l_arr_rec_customer[l_idx].scroll_flag = "*" 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH 
	
	RETURN l_arr_rec_customer 
END FUNCTION 
#######################################################################
# FUNCTION get_customer_datasource(p_filter,p_hide_delete_customers) 
#######################################################################


#######################################################################
# FUNCTION A15_scan_cust_event_manager(p_size,p_rec_customer)
#
#
#######################################################################
FUNCTION A15_scan_cust_event_manager(p_size,p_rec_customer)
	DEFINE p_size SMALLINT
	DEFINE p_rec_customer RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		contact_text LIKE customer.contact_text, 
		delete_date LIKE customer.delete_date,
		delete_flag LIKE customer.delete_flag 
	END RECORD 
		
	IF p_size THEN
		CALL dialog.setActionHidden("EDIT",FALSE)
		CALL dialog.setActionHidden("Delete_Record",    (p_rec_customer.delete_flag = 'Y'))
		CALL dialog.setActionHidden("UN-Delete_Record", (p_rec_customer.delete_flag = 'N'))
	ELSE
		CALL dialog.setActionHidden("EDIT",TRUE)
		CALL dialog.setActionHidden("Delete_Record",    TRUE)
		CALL dialog.setActionHidden("UN-Delete_Record", TRUE)
	END IF
END FUNCTION			
#######################################################################
# END FUNCTION A15_scan_cust_event_manager(p_size,p_idx)
#######################################################################

#######################################################################
# FUNCTION scan_cust()
#
#
#######################################################################
FUNCTION scan_cust() 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		contact_text LIKE customer.contact_text, 
		delete_date LIKE customer.delete_date,
		delete_flag LIKE customer.delete_flag 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE l_customer_can_not_be_deleted BOOLEAN

	#HuHo Remove this line after the settings table is implemented	
	LET glob_rec_settings.hideDeletedCustomers = TRUE #This is just temporary until we have a settings table

	CALL l_arr_rec_customer.clear() 
	CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 

	MESSAGE kandoomsg2("A",1010,"")	#1010 ENTER on line TO Edit;  F2 TO Delete.

	#INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A15","inp-arr-customer") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			IF l_arr_rec_customer.getSize() THEN
				CALL dialog.setActionHidden("EDIT",FALSE)
			ELSE
				CALL dialog.setActionHidden("EDIT",TRUE)
			END IF
						
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_customer.clear() 
			CALL get_customer_datasource(true,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())
			
		ON ACTION "REFRESH" 
			CALL l_arr_rec_customer.clear() 
			CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())

		ON ACTION "Show/Hide Del Cust"
			IF glob_rec_settings.hideDeletedCustomers THEN
				LET glob_rec_settings.hideDeletedCustomers = FALSE
			ELSE
				LET glob_rec_settings.hideDeletedCustomers = TRUE
			END IF
			CALL l_arr_rec_customer.clear() 
			CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())
			
		ON ACTION "NEW" 
			CALL run_prog("A11","","","","") 
			CALL l_arr_rec_customer.clear() 
			CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 

--		ON ACTION "NEW 2" 
--			OPEN WINDOW A205 WITH FORM "A205"
--			CALL windecoration_a("A205")
--			
--			CALL customer_edit_1(MODE_CLASSIC_ADD) 
--
--			IF customer_edit_2() THEN # mandatory WINDOW 
--
--				IF glob_show_rep_ind THEN 
--					--            IF NOT customer_edit_6() THEN # Mandatory window
--					CALL customer_edit_6() 
--					--               continue WHILE
--					--            END IF
--				END IF 
--
--				IF process_customer(MODE_CLASSIC_ADD) THEN 
--					CALL INITIALIZE_globals(MODE_CLASSIC_ADD,"") #what IS this ???? 
--				END IF 
--
--			END IF 
--			CLOSE WINDOW A205
			
		BEFORE ROW 
			LET l_idx = arr_curr()
			CALL A15_scan_cust_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].*)			
			
		AFTER ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","doubleClick","ACCEPT")
			IF l_idx > 0 THEN  #make sure, array is not empty  
			#  	NEXT FIELD cust_code
			#
			#BEFORE FIELD cust_code  --Edit
			IF l_arr_rec_customer[l_idx].delete_date IS NOT NULL THEN --customer IS already deleted 
				ERROR kandoomsg2("A",9073,"") 	#9073" Customer Tagged FOR Deletion - Untag Before Edit"
				#NEXT FIELD scroll_flag
			END IF 

			CALL A15_edit(l_arr_rec_customer[l_idx].cust_code) 

			LET l_arr_rec_customer[l_idx].cust_code = glob_rec_customer.cust_code 
			LET l_arr_rec_customer[l_idx].name_text = glob_rec_customer.name_text 
			LET l_arr_rec_customer[l_idx].contact_text = glob_rec_customer.contact_text 

			CALL l_arr_rec_customer.clear() 
			CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer 

			#NEXT FIELD scroll_flag
			END IF


		ON ACTION "UN-Delete_Record" --key(F2) --delete marker
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) AND (l_arr_rec_customer[l_idx].delete_flag = "Y") THEN 
				IF promptTF("Undelete Customer","Are you sure you want to undelete this customer?",FALSE) THEN
					IF l_arr_rec_customer[l_idx].delete_date IS NOT NULL THEN #customer is deleted 
						LET l_arr_rec_customer[l_idx].scroll_flag = NULL #can not delete him again, remove selection
						LET l_arr_rec_customer[l_idx].delete_date = NULL #
						LET l_arr_rec_customer[l_idx].delete_flag = "N"
						UPDATE customer 
						SET 
							delete_flag = "N", 
							delete_date = NULL 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_arr_rec_customer[l_idx].cust_code 
					END IF
				END IF
			END IF			

			CALL A15_scan_cust_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].*)
			
		ON ACTION "Delete_Record" --key(F2) --delete marker
			IF l_idx > 0 THEN 
				IF promptTF("Delete Customer","Are you sure you want to delete this customer?",FALSE) THEN
					IF customer_activity_state(l_arr_rec_customer[l_idx].cust_code) THEN
						CALL fgl_winmessage("ERROR",kandoomsg2("A",9074,""),"ERROR") 		#9074 Customer has Activity - Deletion NOT Permitted"
					ELSE #delete customer
						SELECT delete_date 
						INTO l_arr_rec_customer[l_idx].delete_date 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_arr_rec_customer[l_idx].cust_code 
		
						IF l_arr_rec_customer[l_idx].delete_date IS NULL OR l_arr_rec_customer[l_idx].delete_date = "31/12/1899" THEN 
							LET l_arr_rec_customer[l_idx].delete_date = today
							 
							UPDATE customer 
							SET 
								delete_flag = "Y", 
								delete_date =today 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = l_arr_rec_customer[l_idx].cust_code 
						END IF 
		
					END IF 
					#After delete, refresh datasource for display array
					CALL l_arr_rec_customer.clear() 
					CALL get_customer_datasource(false,glob_rec_settings.hideDeletedCustomers) RETURNING l_arr_rec_customer   #(p_filter,p_hide_delete_customers)
					LET l_idx = arr_curr()
			
					IF l_arr_rec_customer.getSize() < l_idx THEN #reset cursor location
						LET l_idx = l_arr_rec_customer.getSize()
					END IF
		
					CALL A15_scan_cust_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].*)
					
				END IF
			END IF
	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
#######################################################################
# END FUNCTION scan_cust()
#######################################################################


#######################################################################
# FUNCTION customer_activity_state(p_cust_code)
#
#
#######################################################################
FUNCTION customer_activity_state(p_cust_code)
	DEFINE p_cust_code LIKE customer.cust_code
	
					IF glob_rec_company.module_text[23] = "W" THEN
						#ordhead 
						SELECT unique 1 FROM ordhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = p_cust_code 
						AND status_ind in ("U","P") 
					ELSE 
						#orderhead
						SELECT unique 1 FROM orderhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = p_cust_code 
						AND status_ind in ("U","P") 
					END IF 
	
					IF status != NOTFOUND THEN
						ERROR "Activity in orderhead"
						RETURN TRUE 
					END IF

					#cashreceipt
					SELECT unique 1 FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in orderdetl"
						RETURN TRUE 
					END IF

					#customer
					SELECT unique 1 FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND org_cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in orderdetl"
						RETURN TRUE 
					END IF
					
					#orderdetl
					SELECT unique 1 FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in orderdetl"
						RETURN TRUE 
					END IF

					#backorder
					SELECT unique 1 FROM backorder 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in backorder"
						RETURN TRUE 
					END IF
					
					#credithead
					SELECT unique 1 FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in credithead"
						RETURN TRUE 
					END IF
					
					#credithead
					SELECT unique 1 FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND org_cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in credithead"
						RETURN TRUE 
					END IF

					#job
					SELECT unique 1 FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in job"
						RETURN TRUE 
					END IF

					#contact
					SELECT unique 1 FROM contact 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in contact"
						RETURN TRUE 
					END IF

					#quotehead
					SELECT unique 1 FROM quotehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in quotehead"
						RETURN TRUE 
					END IF

					#salesanly
					SELECT unique 1 FROM salesanly 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in salesanly"
						RETURN TRUE 
					END IF

					#postcredhead
					SELECT unique 1 FROM postcredhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in postcredhead"
						RETURN TRUE 
					END IF				
					
					#postcredhead
					SELECT unique 1 FROM postcredhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND org_cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in postcredhead"
						RETURN TRUE 
					END IF							
										
					#tentinvhead
					SELECT unique 1 FROM tentinvhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in tentinvhead"
						RETURN TRUE 
					END IF						
					
					#tentinvhead
					SELECT unique 1 FROM tentinvhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND org_cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in tentinvhead"
						RETURN TRUE 
					END IF

					#poseodhead
					SELECT unique 1 FROM poseodhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in poseodhead"
						RETURN TRUE 
					END IF

					#orderledg
					SELECT unique 1 FROM orderledg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in orderledg"
						RETURN TRUE 
					END IF
						
					#rates
					SELECT unique 1 FROM rates 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in rates"
						RETURN TRUE 
					END IF
					
					#posporide
					SELECT unique 1 FROM posporide 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in posporide"
						RETURN TRUE 
					END IF					

					#orderinst
					SELECT unique 1 FROM orderinst 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = p_cust_code 
					
					IF status != NOTFOUND THEN
						ERROR "Activity in orderinst"
						RETURN TRUE 
					END IF							

END FUNCTION
#######################################################################
# END FUNCTION customer_activity_state(p_cust_code)
#######################################################################

#######################################################################
# FUNCTION A15_edit(p_cust_code)
#
#
#######################################################################
FUNCTION A15_edit(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code 

	OPEN WINDOW A205 with FORM "A205" 
	CALL windecoration_a("A205") 

	CALL INITIALIZE_globals(MODE_CLASSIC_EDIT,p_cust_code) 
	
	CALL db_country_localize(glob_rec_customer.country_code) #Localize	

	WHILE customer_edit_1(MODE_CLASSIC_EDIT) 
		IF process_customer(MODE_CLASSIC_EDIT) THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW A205 

END FUNCTION 
#######################################################################
# END FUNCTION A15_edit(p_cust_code)
#######################################################################