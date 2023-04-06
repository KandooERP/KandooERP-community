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
# CUSTOMER PARTS
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# This FUNCTION allows the enquiry of customer part code.
# IF a customer code IS NOT passed, THEN prompt FOR one appears.
# Pre: cmpy_code, p_cust_code
# Post: part_code
###########################################################################

#########################################################################
# FUNCTION view_custpart_code(p_cmpy_code, p_cust_code)
#
#
#########################################################################
FUNCTION view_custpart_code(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_cust_code LIKE customer.cust_code
--	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.* 
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		custpart_code LIKE customerpart.custpart_code, 
		desc_text LIKE product.desc_text, 
		part_code LIKE customerpart.part_code 
	END RECORD 
	DEFINE l_counter SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_del_cnt SMALLINT		 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_wind_text CHAR(40) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_run_arg1 STRING
	DEFINE l_run_arg2 STRING
	
	OPEN WINDOW A699 with FORM "A699" 
	CALL windecoration_a("A699") 

	#menu if cust_code parameter was not used
	IF p_cust_code IS NULL THEN 
		MESSAGE kandoomsg2("U",1020,"Customer")		#1020 Enter Customer Details; OK TO Continue;
		INPUT BY NAME l_rec_customerpart.cust_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","cpartwind","input-customerpart") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			#Lookup for customer
			ON ACTION "LOOKUP" infield(cust_code) 
				LET l_wind_text = show_clnt(p_cmpy_code) 
				IF l_wind_text IS NOT NULL THEN 
					LET l_rec_customerpart.cust_code = l_wind_text 
				END IF 
				NEXT FIELD cust_code 

			AFTER FIELD cust_code 
				IF l_rec_customerpart.cust_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
					NEXT FIELD cust_code 
				END IF 

				SELECT * INTO l_rec_customer.* 
				FROM customer 
				WHERE cust_code = l_rec_customerpart.cust_code 
				AND cmpy_code = p_cmpy_code 

				IF status = notfound THEN 
					ERROR kandoomsg2("U",9105,"") 					#9105 RECORD NOT found;  Try Window.
					NEXT FIELD cust_code 
				END IF 

				IF l_rec_customer.delete_flag = "Y" THEN 
					ERROR kandoomsg2("A",9144,"") 					#9144 Customer has been marked FOR deletion
					NEXT FIELD cust_code 
				END IF 



		END INPUT 
		#######################
		LET p_cust_code = l_rec_customerpart.cust_code 
		DISPLAY BY NAME l_rec_customer.name_text 

	#------------------------------------------------------------------------------
	ELSE #Using argument p_cust_code
		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cust_code = p_cust_code 
		AND cmpy_code = p_cmpy_code 

		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"Customer") 		#7001 Customer RECORD NOT found
			CLOSE WINDOW A699 
			RETURN "" 
		END IF 

		DISPLAY l_rec_customer.cust_code TO customer.cust_code
		DISPLAY l_rec_customer.name_text TO customer.name_text 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		CLOSE WINDOW A699 

		RETURN NULL 
	END IF 
	
	IF l_rec_customerpart.cust_code IS NULL THEN
		LET l_rec_customerpart.cust_code = l_rec_customer.cust_code
	END IF
	
	CALL db_customerpart_get_datasource(FALSE,l_rec_customerpart.cust_code) RETURNING l_arr_rec_customerpart
	
	MESSAGE kandoomsg2("U",1054,"")	#1054 F3/F4 TO Page Fwd/Bwd;  F9 Add Customer Product.
	LET l_del_cnt = 0 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	DISPLAY ARRAY l_arr_rec_customerpart TO sr_customerpart.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY
			CALL publish_toolbar("kandoo","cpartwind","input-arr-customerpart") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_customerpart.clear()
			CALL db_customerpart_get_datasource(TRUE,l_rec_customerpart.cust_code) RETURNING l_arr_rec_customerpart
			
		ON ACTION "A1F-CUST PROD CODE SETUP" 			#ON KEY(f9) infield(scroll_flag)
			LET l_run_arg1 = "COMPANY_CODE=", trim(p_cmpy_code)
			LET l_run_arg2 = "CUSTOMER_CODE=", trim(p_cust_code) 
			CALL run_prog("A1F",l_run_arg1,l_run_arg2,"","") #a1f customer product codes 
			
			CALL l_arr_rec_customerpart.clear()
			CALL db_customerpart_get_datasource(FALSE,l_rec_customerpart.cust_code) RETURNING l_arr_rec_customerpart
			
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			--NEXT FIELD scroll_flag 

		BEFORE ROW 
			LET l_idx = arr_curr()
			LET l_scroll_flag = l_arr_rec_customerpart[l_idx].scroll_flag
						 
			#DISPLAY l_arr_rec_customerpart[l_idx].*
			#LET scrn = scr_line()
			LET l_rec_customerpart.custpart_code = l_arr_rec_customerpart[l_idx].custpart_code 
			LET l_rec_customerpart.part_code = l_arr_rec_customerpart[l_idx].part_code 

			SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
			FROM product 
			WHERE cmpy_code = p_cmpy_code 
			AND part_code = l_arr_rec_customerpart[l_idx].part_code 
			#DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

			--NEXT FIELD scroll_flag 

--		BEFORE FIELD scroll_flag 
--			LET l_scroll_flag = l_arr_rec_customerpart[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_customerpart[l_idx].scroll_flag = l_scroll_flag 
--			LET l_rec_customerpart.part_code = l_arr_rec_customerpart[l_idx].part_code 


--		BEFORE FIELD custpart_code 
--			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*



	END DISPLAY 
	#############################

	CLOSE WINDOW A699 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_customerpart.part_code 
	END IF 

END FUNCTION 
#########################################################################
# END FUNCTION view_custpart_code(p_cmpy_code, p_cust_code)
#########################################################################


#########################################################################
# FUNCTION db_customerpart_get_datasource(p_filter, p_cust_code)
#
#
#########################################################################
FUNCTION db_customerpart_get_datasource(p_filter, p_cust_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cust_code LIKE customer.cust_code
--	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.* 
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		custpart_code LIKE customerpart.custpart_code, 
		desc_text LIKE product.desc_text, 
		part_code LIKE customerpart.part_code 
	END RECORD 
	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	
	IF p_filter THEN
		CLEAR SCREEN
		MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter Selection Criteria;  OK TO Continue.		
		CONSTRUCT BY NAME l_where_text ON custpart_code,desc_text,part_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","cpartwind","construct-custpart") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false
			#???? window is locked error reported by Alex K.
			WHENEVER ERROR Continue 
			CLOSE WINDOW A699			 
			WHENEVER ERROR STOP
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE
		LET l_where_text = " 1=1 " 
	END IF

	MESSAGE kandoomsg2("U",1002,"")	#1002 Searching Database;  Please Wait.

	LET l_query_text = 
		"SELECT * FROM customerpart ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",p_cust_code CLIPPED,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY custpart_code, part_code" 

	WHENEVER ERROR CONTINUE 

	PREPARE s_customerpart FROM l_query_text 
	DECLARE c_customerpart CURSOR FOR s_customerpart 

	LET l_idx = 0 
	FOREACH c_customerpart INTO l_rec_customerpart.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customerpart[l_idx].custpart_code = l_rec_customerpart.custpart_code 
		LET l_arr_rec_customerpart[l_idx].part_code = l_rec_customerpart.part_code 

		SELECT desc_text INTO l_arr_rec_customerpart[l_idx].desc_text 
		FROM product 
		WHERE cmpy_code = p_cmpy_code 
		AND part_code = l_rec_customerpart.part_code 

	END FOREACH 

	ERROR kandoomsg2("U",9113,l_idx) #U9113 l_idx records selected

	WHENEVER ERROR stop 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN l_arr_rec_customerpart
END FUNCTION
#########################################################################
# END FUNCTION db_customerpart_get_datasource(p_filter, p_cust_code)
#########################################################################