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
GLOBALS "../ar/A1F_GLOBALS.4gl"
###########################################################################
# MODULEL Scope Variables
###########################################################################
DEFINE modu_cust_code LIKE customer.cust_code  #I think we can remove this - minor code changes 
###########################################################################
# FUNCTION A1F_main()
#
# Customer Part Code
###########################################################################
FUNCTION A1F_main()
	DEFINE l_rec_customer RECORD LIKE customer.*

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A1F") 	#Initial UI Init 

	OPEN WINDOW A696 with FORM "A696" 
	CALL windecoration_a("A696") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET modu_cust_code = get_url_cust_code()
	
	IF modu_cust_code IS NOT NULL THEN
		CALL db_customer_get_rec(UI_OFF,modu_cust_code) RETURNING l_rec_customer.*
		CALL custpart_code_list(l_rec_customer.*)
	ELSE
		INITIALIZE l_rec_customer.* TO NULL
		CALL select_customer() RETURNING l_rec_customer.*
		WHILE l_rec_customer.cust_code IS NOT NULL
			IF custpart_code_list(l_rec_customer.*) = FALSE THEN
				EXIT WHILE
			END IF
		END WHILE
	END IF

	--CALL select_customer() RETURNING l_rec_customer.*
	--CALL custpart_code_list(l_rec_customer.*)
	--IF l_rec_customer IS NULL THEN
	--	MESSAGE "Customer Entry aborted"
--		RETURN NULL
--	END IF


--	CALL custpart_code_list(NULL)

	CLOSE WINDOW A696 
END FUNCTION
###########################################################################
# END FUNCTION A1F_main()
###########################################################################

#######################################################
# FUNCTION db_customerpart_part_and_custpart_get_datasource(p_filter)
#
#
#######################################################
FUNCTION db_customerpart_part_and_custpart_get_datasource(p_filter,p_cust_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.*
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF RECORD --array[500] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE customerpart.part_code, 
		desc_text LIKE product.desc_text, 
		custpart_code LIKE customerpart.custpart_code 
	END RECORD
	DEFINE l_counter SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_del_cnt SMALLINT
	
	--DEFINE l_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	--DEFINE l_scroll_flag CHAR(1) 
	--DEFINE l_wind_text CHAR(40)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	
---------------------

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"") 		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON #query FOR particular product/part (customer filter was SET prior) 
			part_code, 
			desc_text, 
			custpart_code 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A1F","construct-part") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
--			IF get_url_cust_code() IS NOT NULL THEN #this makes no sense - endless loop
				--RETURN 
--			END IF 
			--CONTINUE WHILE
			LET l_where_text = " 1=1 " 
		END IF 
		
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF
		
	CALL l_arr_rec_customerpart.clear() #huho replaced INITIALIZE FOR loop 
	#FOR l_counter = 1 TO 500
	#   INITIALIZE l_arr_rec_customerpart[l_counter] TO NULL
	#END FOR

	MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching Database;  Please Wait.
	LET l_query_text = 
		"SELECT * FROM customerpart ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",p_cust_code CLIPPED,"' ",      --modu_cust_code
		"AND ",l_where_text clipped," ", 
		"ORDER BY part_code" 
	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 
	PREPARE s_customerpart FROM l_query_text 
	DECLARE c_customerpart CURSOR FOR s_customerpart 

	LET l_idx = 0 
	FOREACH c_customerpart INTO l_rec_customerpart.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customerpart[l_idx].part_code = l_rec_customerpart.part_code 
		SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_customerpart.part_code 
		LET l_arr_rec_customerpart[l_idx].custpart_code = l_rec_customerpart.custpart_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)  #xxx records founds.... 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN l_arr_rec_customerpart

END FUNCTION	
#######################################################
# END FUNCTION db_customerpart_part_and_custpart_get_datasource(p_filter)
#######################################################


#######################################################
# FUNCTION customer_cust_part_code_preview(p_rec_customer)
#
# 
#
#######################################################
FUNCTION customer_cust_part_code_preview(p_rec_customer)
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		part_code LIKE customerpart.part_code, 
		desc_text LIKE product.desc_text, 
		custpart_code LIKE customerpart.custpart_code 
	END RECORD

	DISPLAY p_rec_customer.name_text TO name_text

	CALL l_arr_rec_customerpart.clear()
	CALL db_customerpart_part_and_custpart_get_datasource(FALSE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart

	DISPLAY ARRAY l_arr_rec_customerpart TO sr_customerpart.* WITHOUT SCROLL

END FUNCTION
#######################################################
# END FUNCTION customer_cust_part_code_preview(p_rec_customer)
#######################################################


#######################################################
# FUNCTION select_customer()
#
# 
#
#######################################################
FUNCTION select_customer()
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_wind_text CHAR(40)

		CLEAR FORM 
		LET l_rec_customer.cust_code = get_url_cust_code() 
		IF l_rec_customer.cust_code IS NULL THEN 
			MESSAGE kandoomsg2("U",1020,"Customer") 		#1020 Enter Customer Details; OK TO Continue;
			INPUT BY NAME l_rec_customer.cust_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) #set customer query 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","A1F","inp-customerpart")
					CALL dialog.setActionHidden("ACCEPT",FALSE) 
					CALL dialog.setActionHidden("EDIT",TRUE)

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "LOOKUP" --ON KEY (control-b) 
					LET l_wind_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF l_wind_text IS NOT NULL THEN 
						LET l_rec_customer.cust_code = l_wind_text 
					END IF 
					NEXT FIELD cust_code 

				ON ACTION "EDIT"
					IF l_rec_customer.cust_code IS NOT NULL THEN #to be sure it's there..
						CALL custpart_code_list(l_rec_customer.*)
					END IF


				ON CHANGE cust_code --AFTER FIELD cust_code 
					IF l_rec_customer.cust_code IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 						#9102 Value must be entered
						CALL dialog.setActionHidden("EDIT",TRUE)	
						NEXT FIELD cust_code 
					END IF 

					CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.*

					IF l_rec_customer.cust_code IS NULL THEN
						ERROR kandoomsg2("U",9105,"")				#9105 RECORD NOT found;  Try Window.
						CALL dialog.setActionHidden("EDIT",TRUE)	

						NEXT FIELD cust_code 
					END IF 

					IF l_rec_customer.delete_flag = "Y" THEN 
						ERROR kandoomsg2("A",9144,"") 		#9144 Customer has been marked FOR deletion
						CALL dialog.setActionHidden("EDIT",TRUE)	

						#Preview
						CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.*
					
						CALL customer_cust_part_code_preview(l_rec_customer.*)
						NEXT FIELD cust_code 
					END IF 

					CALL dialog.setActionHidden("EDIT",FALSE)
					LET modu_cust_code = l_rec_customer.cust_code 
					DISPLAY l_rec_customer.name_text TO name_text

					CALL customer_cust_part_code_preview(l_rec_customer.*)

				AFTER INPUT
					IF int_flag THEN
						#??? aynthing
					ELSE
						IF l_rec_customer.cust_code IS NULL THEN 
							ERROR kandoomsg2("U",9102,"") 						#9102 Value must be entered
							SLEEP 2
							NEXT FIELD cust_code #CONTINUE INPUT
						END IF
					END IF

			END INPUT 

			LET modu_cust_code = l_rec_customer.cust_code 
			DISPLAY l_rec_customer.name_text TO name_text
			

		ELSE 
--			IF get_url_cust_code() IS NOT NULL THEN 
--				LET modu_cust_code = get_url_cust_code() 
				
				CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.*
				IF l_rec_customer.cust_code IS NULL THEN
				--IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",7001,"Customer") 				#7001 Customer RECORD NOT found
					RETURN 
				END IF 

			DISPLAY l_rec_customer.cust_code TO cust_code 
			DISPLAY l_rec_customer.name_text TO name_text 

		END IF 

	IF int_flag THEN
		LET int_flag = FALSE
		RETURN NULL
	ELSE
		RETURN 	l_rec_customer.*
	END IF
	
---------------------------------------		 
END FUNCTION
#######################################################
# END FUNCTION select_customer()
#######################################################


#######################################################
# FUNCTION custpart_code_list(p_rec_customer)
#
# 
#
#######################################################
FUNCTION custpart_code_list(p_rec_customer) 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.*
	DEFINE l_rec_orig_customerpart RECORD LIKE customerpart.*
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		part_code LIKE customerpart.part_code, 
		desc_text LIKE product.desc_text, 
		custpart_code LIKE customerpart.custpart_code 
	END RECORD
	DEFINE l_counter SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_del_cnt SMALLINT
	
--	DEFINE l_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_wind_text CHAR(40)
	DEFINE l_query_text CHAR(600)
	DEFINE l_where_text CHAR(300) 

--	WHILE true 
{
-----------------------------------

		CLEAR FORM 
		IF get_url_cust_code() IS NULL THEN 
			MESSAGE kandoomsg2("U",1020,"Customer")	#1020 Enter Customer Details; OK TO Continue;

			INPUT BY NAME l_rec_customerpart.cust_code WITHOUT DEFAULTS #set customer query 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","A1F","inp-customerpart") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "LOOKUP" #ON KEY (control-b) 
					LET l_wind_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF l_wind_text IS NOT NULL THEN 
						LET l_rec_customerpart.cust_code = l_wind_text 
					END IF 
					NEXT FIELD cust_code 

				AFTER FIELD cust_code 
					IF l_rec_customerpart.cust_code IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
						NEXT FIELD cust_code 
					END IF 

					SELECT * INTO p_rec_customer.* 
					FROM customer 
					WHERE l_rec_customerpart.cust_code = customer.cust_code 
					AND glob_rec_kandoouser.cmpy_code = customer.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("U",9105,"") 		#9105 RECORD NOT found;  Try Window.
						NEXT FIELD cust_code 
					END IF 

					IF p_rec_customer.delete_flag = "Y" THEN 
						ERROR kandoomsg2("A",9144,"") 				#9144 Customer has been marked FOR deletion
						NEXT FIELD cust_code 
					END IF 

			END INPUT 

			LET modu_cust_code = l_rec_customerpart.cust_code 
			DISPLAY p_rec_customer.name_text TO name_text

		ELSE 
			IF get_url_cust_code() IS NOT NULL THEN 
				LET modu_cust_code = get_url_cust_code() 
				SELECT * INTO p_rec_customer.* 
				FROM customer 
				WHERE cust_code = modu_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",7001,"Customer") 			#7001 Customer RECORD NOT found
					RETURN 
				END IF 

			END IF 

			DISPLAY p_rec_customer.cust_code TO cust_code 
			DISPLAY p_rec_customer.name_text TO name_text 

		END IF 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN --EXIT WHILE 
		END IF 
---------------------------------------
}

{
---------------------
		MESSAGE kandoomsg2("U",1001,"") 		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON part_code, #query FOR particular product/part (customer filter was SET prior) 
		desc_text, 
		custpart_code 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A1F","construct-part") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
--			IF get_url_cust_code() IS NOT NULL THEN #this makes no sense - endless loop
				RETURN 
--			END IF 
			CONTINUE WHILE 
		END IF 
		CALL l_arr_rec_customerpart.clear() #huho replaced INITIALIZE FOR loop 
		#FOR l_counter = 1 TO 500
		#   INITIALIZE l_arr_rec_customerpart[l_counter] TO NULL
		#END FOR

		MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching Database;  Please Wait.
		LET l_query_text = "SELECT * FROM customerpart ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cust_code = '",modu_cust_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY part_code" 
		WHENEVER ERROR CONTINUE 

		OPTIONS SQL interrupt ON 
		PREPARE s_customerpart FROM l_query_text 
		DECLARE c_customerpart CURSOR FOR s_customerpart 

		LET l_idx = 0 
		FOREACH c_customerpart INTO l_rec_customerpart.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_customerpart[l_idx].part_code = l_rec_customerpart.part_code 
			SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_customerpart.part_code 
			LET l_arr_rec_customerpart[l_idx].custpart_code = l_rec_customerpart.custpart_code 
		END FOREACH 

		ERROR kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected
--		IF l_idx = 0 THEN 
--			LET l_idx = 1 
--			INITIALIZE l_arr_rec_customerpart[1].* TO NULL 
	--	END IF
 
		WHENEVER ERROR stop 
		OPTIONS SQL interrupt off 

-----------------------
}
--	CALL select_customer() RETURNING p_rec_customer.*
--	IF p_rec_customer IS NULL THEN
--		MESSAGE "Customer Entry aborted"
--		RETURN NULL
--	END IF
	
	CALL l_arr_rec_customerpart.clear()
	CALL db_customerpart_part_and_custpart_get_datasource(FALSE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart
	
		MESSAGE kandoomsg2("U",1003,"") 
		#1003 F1 TO Add; F2 TO Delete;  ENTER on Line TO Edit.
--		CALL set_count(l_idx) 
		LET l_del_cnt = 0 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 

		INPUT ARRAY l_arr_rec_customerpart WITHOUT DEFAULTS FROM sr_customerpart.* attribute(UNBUFFERED, AUTO APPEND = TRUE, INSERT ROW = FALSE, APPEND ROW = TRUE,DELETE ROW = FALSE) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A1F","inp-arr-customerpart") 
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())
				
				DISPLAY p_rec_customer.cust_code TO customerpart.cust_code
				DISPLAY p_rec_customer.name_text TO customer.name_text
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

--			ON ACTION "CUSTOMER"
--				INITIALIZE p_rec_customer.* TO NULL
--				CALL select_customer() RETURNING p_rec_customer.*
--				IF p_rec_customer.cust_code IS NOT NULL THEN
--					CALL custpart_code_list(p_rec_customer.*)
--					CALL l_arr_rec_customerpart.clear()
--					CALL db_customerpart_part_and_custpart_get_datasource(TRUE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart
--					CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())
--					DISPLAY p_rec_customer.cust_code TO customerpart.cust_code
--					DISPLAY p_rec_customer.name_text TO customer.name_text
--				ELSE
--					ERROR "Customer not found"
--				END IF
				
			ON ACTION "FILTER"
				CALL l_arr_rec_customerpart.clear()
				CALL db_customerpart_part_and_custpart_get_datasource(TRUE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())
				
			ON ACTION "REFRESH"
				CALL windecoration_a("A696") 
				CALL l_arr_rec_customerpart.clear()
				CALL db_customerpart_part_and_custpart_get_datasource(FALSE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())

			ON ACTION "LOOKUP" infield (part_code)
				LET l_wind_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
				IF l_wind_text IS NOT NULL THEN 
					LET l_arr_rec_customerpart[l_idx].part_code = l_wind_text 
				END IF 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				NEXT FIELD part_code 

			BEFORE ROW 
				LET l_idx = arr_curr()
				IF l_idx > 0 THEN
					LET l_rec_orig_customerpart.part_code 		= l_arr_rec_customerpart[l_idx].part_code
					--LET l_rec_orig_customerpart.desc_text 		= l_arr_rec_customerpart[l_idx].desc_text
					LET l_rec_orig_customerpart.custpart_code = l_arr_rec_customerpart[l_idx].custpart_code
				END IF 
				#DISPLAY "l_idx/arr_curr()=", trim(l_idx)
				#LET scrn = scr_line()
--				NEXT FIELD scroll_flag 
				#AFTER ROW
				#   DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

			AFTER ROW
--				MESSAGE "after row" 
			
				IF (NOT get_is_screen_navigation_forward()) OR (int_flag = TRUE) THEN #move backwards/out or Cancel will delete current EMPTY line
					IF l_arr_rec_customerpart[l_idx].part_code IS NULL THEN
						CALL l_arr_rec_customerpart.delete(l_idx)
						IF l_arr_rec_customerpart.getSize() = 0 THEN  #cancel or navigate back on single empty row is exit input array
							EXIT INPUT
						END IF
					END IF
				ELSE
					IF l_arr_rec_customerpart[l_idx].part_code IS NULL THEN
						ERROR "Part code can not be empty"
						NEXT FIELD part_code
					END IF
					IF l_arr_rec_customerpart[l_idx].desc_text IS NULL THEN
						ERROR "Description can not be empty"
						NEXT FIELD desc_text
					END IF
					IF l_arr_rec_customerpart[l_idx].custpart_code IS NULL THEN
						ERROR "Customer-Part code can not be empty"
						NEXT FIELD custpart_code
					END IF			
				END IF
				
			BEFORE INSERT
--				MESSAGE "before insert" 
				#CALL fgl_winmessage("BEFORE INSERT","BEFORE INSERT","info")
				--INITIALIZE l_rec_customerpart.* TO NULL 
				--INITIALIZE l_arr_rec_customerpart[l_idx].* TO NULL 
--				NEXT FIELD part_code 

				#AFTER INSERT
				#	CALL fgl_winmessage("AFTER INSERT","AFTER INSERT","info")

			AFTER INSERT
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())
--				MESSAGE "after insert" 
			

			ON CHANGE scroll_flag
				IF l_arr_rec_customerpart[l_idx].scroll_flag = '*' THEN
					LET l_del_cnt = l_del_cnt + 1
				ELSE
					LET l_del_cnt = l_del_cnt - 1
				END IF
				
			BEFORE FIELD scroll_flag
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_customerpart.getSize()) THEN
					IF l_arr_rec_customerpart[l_idx].part_code IS NULL THEN
						NEXT FIELD part_code
					ELSE
--				IF l_idx > 0 THEN
						LET l_scroll_flag = l_arr_rec_customerpart[l_idx].scroll_flag 
						LET l_rec_customerpart.part_code = l_arr_rec_customerpart[l_idx].part_code 
						LET l_rec_customerpart.custpart_code = l_arr_rec_customerpart[l_idx].custpart_code 
	
					END IF
				END IF
				
			AFTER FIELD part_code			  
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_customerpart.getSize()) THEN
					IF l_arr_rec_customerpart[l_idx].part_code IS NULL THEN
						IF get_is_screen_navigation_forward() THEN 
							ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
							NEXT FIELD part_code
						ELSE
							CALL l_arr_rec_customerpart.delete(l_idx) 
						END IF 
					ELSE
					 
						IF l_rec_orig_customerpart.part_code != l_arr_rec_customerpart[l_idx].part_code THEN
						--IF NOT fgl_buffertouched() THEN	
							SELECT unique 1 
							FROM customerpart 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = modu_cust_code 
							AND part_code = l_arr_rec_customerpart[l_idx].part_code 
			
							IF status != NOTFOUND THEN 
								ERROR kandoomsg2("U",9104,"")				#9104 RECORD already exists.
								NEXT FIELD part_code 
							END IF 
							# Check ARRAY next IF part exists
							FOR l_counter = 1 TO l_arr_rec_customerpart.getSize() 
								IF l_arr_rec_customerpart[l_idx].part_code = l_arr_rec_customerpart[l_counter].part_code 
								AND l_idx != l_counter THEN 
									ERROR kandoomsg2("U",9104,"") 							#9104 RECORD already exists.
									NEXT FIELD part_code 
								END IF 
							END FOR 
						END IF
						
						IF get_is_screen_navigation_forward() THEN
								SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
								FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = l_arr_rec_customerpart[l_idx].part_code 
								IF status = NOTFOUND THEN 
									ERROR kandoomsg2("U",9105,"") 						#9105 RECORD NOT found;  Try Window.
									NEXT FIELD part_code 
								END IF 
		
								NEXT FIELD custpart_code 
--					ELSE 
--							NEXT FIELD part_code 
						END IF 
					END IF
				END IF
								
			AFTER FIELD custpart_code
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_customerpart.getSize()) THEN 
					IF l_arr_rec_customerpart[l_idx].custpart_code IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered.
						NEXT FIELD custpart_code 
					END IF 
				END IF

			ON ACTION "DELETE"
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_customerpart.getSize()) THEN
					IF l_del_cnt > 0 THEN 
						IF kandoomsg("U",8000,l_del_cnt) = "Y" THEN #8000 Confirm TO Delete ",del_cnt," rows.
							FOR l_idx = 1 TO l_arr_rec_customerpart.getSize() 
								IF l_arr_rec_customerpart[l_idx].scroll_flag = "*" THEN 
									DELETE FROM customerpart 
									WHERE cust_code = l_rec_customerpart.cust_code 
									AND part_code = l_rec_customerpart.part_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								END IF 
							END FOR 
						END IF 
					CALL l_arr_rec_customerpart.clear()
					CALL db_customerpart_part_and_custpart_get_datasource(FALSE,p_rec_customer.cust_code) RETURNING l_arr_rec_customerpart
					ELSE
						ERROR "Select Rows to delete prior"
					END IF 
	
					CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_customerpart.getSize())
				END IF

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
--					IF NOT (infield(scroll_flag)) THEN 
--						IF l_rec_customerpart.part_code IS NULL THEN 
--							LET int_flag = false 
--							LET quit_flag = false 
--							NEXT FIELD scroll_flag 
--						ELSE 
--							LET l_arr_rec_customerpart[l_idx].part_code = l_rec_customerpart.part_code 
--							SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
--							FROM product 
--							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--							AND part_code = l_rec_customerpart.part_code 
--							LET l_arr_rec_customerpart[l_idx].custpart_code = l_rec_customerpart.custpart_code 
--							LET int_flag = false 
--							LET quit_flag = false 
--							NEXT FIELD scroll_flag 
--						END IF 
--					END IF 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
 			RETURN FALSE
		ELSE 
			FOR l_idx = 1 TO l_arr_rec_customerpart.getSize() 
				IF l_arr_rec_customerpart[l_idx].part_code IS NOT NULL THEN 
					LET l_rec_customerpart.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_customerpart.cust_code = modu_cust_code #customer code
					LET l_rec_customerpart.part_code = l_arr_rec_customerpart[l_idx].part_code 
					LET l_rec_customerpart.custpart_code = l_arr_rec_customerpart[l_idx].custpart_code 
					UPDATE customerpart 
					SET * = l_rec_customerpart.* 
					WHERE cust_code = l_rec_customerpart.cust_code 
					AND part_code = l_rec_customerpart.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO customerpart VALUES (l_rec_customerpart.*) 
					END IF 
				END IF 
			END FOR 
			RETURN TRUE
		END IF 

END FUNCTION
#######################################################
# END FUNCTION custpart_code_list(p_rec_customer)
#######################################################