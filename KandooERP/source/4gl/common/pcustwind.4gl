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

##############################################################
# FUNCTION view_partcust_code(p_cmpy, p_part_code)
#
# This FUNCTION allows the inquiry of customers that have customer
# part codes associated with a particular part.
#
# IF a part code IS NOT passed, THEN a prompt FOR one appears.
# Pre: cmpy_code, p_part_code
# Post: pr_cust_code
#############################################################
FUNCTION view_partcust_code(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_customerpart RECORD LIKE customerpart.* 
	DEFINE l_arr_rec_customerpart DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			cust_code LIKE customerpart.cust_code, 
			name_text LIKE customer.name_text, 
			custpart_code LIKE customerpart.custpart_code 
		END RECORD 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_wind_text CHAR(40) 
	DEFINE l_query_text CHAR(600) 
	DEFINE l_where_text STRING 

		OPEN WINDOW I684 with FORM "I684" 
		CALL windecoration_i("I684") 

		CLEAR FORM 
		IF p_part_code IS NULL THEN 

			MESSAGE kandoomsg2("U",1020,"Product")		#1020 Enter Product Details; OK TO Continue;
			INPUT BY NAME l_rec_customerpart.part_code WITHOUT DEFAULTS 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","pcustwind","input-customerpart")

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON ACTION "LOOKUP" #ON KEY (control-b) 
					LET l_wind_text = show_part(p_cmpy,"") 
					IF l_wind_text IS NOT NULL THEN 
						LET l_rec_customerpart.part_code = l_wind_text 
					END IF 
					NEXT FIELD part_code 

				AFTER FIELD part_code 
					IF l_rec_customerpart.part_code IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO l_rec_product.* 
					FROM product 
					WHERE part_code = l_rec_customerpart.part_code 
					AND cmpy_code = p_cmpy 
					IF status = notfound THEN 
						ERROR kandoomsg2("U",9105,"") 					#9105 RECORD NOT found;  Try Window.
						NEXT FIELD part_code 
					END IF 
					IF l_rec_product.status_ind = "3" THEN 
						ERROR kandoomsg2("A",9147,"") 					#9144 Product IS marked FOR deletion;  Unmark before ...
						NEXT FIELD part_code 
					END IF 

			END INPUT 

			LET p_part_code = l_rec_customerpart.part_code 
			DISPLAY BY NAME l_rec_product.desc_text 

		ELSE 
			SELECT * INTO l_rec_product.* 
			FROM product 
			WHERE part_code = p_part_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",7001,"Product") 			#7001 Logic Error: Product RECORD does NOT exist in database.
				CLOSE WINDOW I684 
				RETURN "" 
			END IF 
			DISPLAY BY NAME l_rec_product.part_code, l_rec_product.desc_text 

		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW I684 
			RETURN "" 
		END IF 

		MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			name_text, 
			custpart_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","pcustwind","construct-customerpart") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW I684 
			RETURN "" 
		END IF 

		MESSAGE kandoomsg2("U",1002,"") 		#1002 Searching Database;  Please Wait.
		LET l_query_text = "SELECT * FROM customerpart ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND part_code = '",p_part_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cust_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 

		PREPARE s_customerpart FROM l_query_text 
		DECLARE c_customerpart CURSOR FOR s_customerpart 

		LET l_idx = 0 
		FOREACH c_customerpart INTO l_rec_customerpart.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_customerpart[l_idx].cust_code = l_rec_customerpart.cust_code 
			SELECT name_text INTO l_arr_rec_customerpart[l_idx].name_text 
			FROM customer 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_customerpart.cust_code 
			LET l_arr_rec_customerpart[l_idx].custpart_code = l_rec_customerpart.custpart_code 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)		#U9113 l_idx records selected

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		MESSAGE kandoomsg2("U",1054,"")		#1054 F3/F4 TO Page Fwd/Bwd;  F9 Add Customer product;
		CALL set_count(l_idx) 
		LET l_del_cnt = 0 

		INPUT ARRAY l_arr_rec_customerpart WITHOUT DEFAULTS FROM sr_customerpart.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","pcustwind","input-arr-customerpart") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (f9) infield (scroll_flag) 
				CALL run_prog("A1F","","","","") #a1f customer product codes 
				NEXT FIELD scroll_flag 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				LET l_rec_customerpart.cust_code = l_arr_rec_customerpart[l_idx].cust_code 
				SELECT name_text INTO l_arr_rec_customerpart[l_idx].name_text 
				FROM customer 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = l_arr_rec_customerpart[l_idx].cust_code 
				#         DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

				LET l_rec_customerpart.custpart_code 
				= l_arr_rec_customerpart[l_idx].custpart_code 
				NEXT FIELD scroll_flag 

			BEFORE FIELD scroll_flag 
				LET l_scroll_flag = l_arr_rec_customerpart[l_idx].scroll_flag 
				#         DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

			AFTER FIELD scroll_flag 
				LET l_arr_rec_customerpart[l_idx].scroll_flag = l_scroll_flag 
				LET l_rec_customerpart.cust_code = l_arr_rec_customerpart[l_idx].cust_code 

			BEFORE FIELD cust_code 
				NEXT FIELD scroll_flag 

				#      AFTER ROW
				#         DISPLAY l_arr_rec_customerpart[l_idx].* TO sr_customerpart[scrn].*

		END INPUT 

		CLOSE WINDOW I684 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN "" 
		ELSE 
			RETURN l_rec_customerpart.cust_code 
		END IF 

END FUNCTION 
##############################################################
# END FUNCTION view_partcust_code(p_cmpy, p_part_code)
##############################################################