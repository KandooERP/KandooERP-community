##########################################################################
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
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

################################################################
# FUNCTION A41_main()
#
# \brief module E5C - Maintainence program FOR EO Customer credit Notes
#                This program allows the addition AND editting of
#                credit notes based on invoices that originated
#                FROM EO confirmed sales orders.
################################################################
FUNCTION A41_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A41") 

	CALL create_table("creditdetl","t_creditdetl","","Y") 

	OPEN WINDOW A665 with FORM "A665" 
	CALL windecoration_a("A665") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#-------------------------------------
	#Step 1 - Initialize Credit
	IF A41_initialize_credit_for_invoice("") THEN   # "" = NULL

		OPEN WINDOW A666 with FORM "A666" 
		CALL windecoration_a("A666") 
		
		#-------------------------------------
		#Step 2 - Process Credit (Add)
		LET glob_rec_credithead.cred_num = process_credit(MODE_CLASSIC_ADD)  #add credit note ? 
		CLOSE WINDOW A666 
	END IF 

	#-------------------------------------
	#Step 3 - validate credit number
	IF glob_rec_credithead.cred_num > 0 THEN 
		LET glob_temp_text = "cred_num ='",glob_rec_credithead.cred_num CLIPPED,"'" 
	ELSE 
		LET glob_temp_text = NULL 
	END IF 

	#-------------------------------------
	#Step 4 - Scan Credit ? save and apply a Credit Note ?
	--   WHILE select_credit(glob_temp_text)
	CURRENT WINDOW IS A665
	CALL scan_credit(glob_temp_text) #check argument next time
	--      LET glob_temp_text = NULL
	--   END WHILE

	CALL fgl_winmessage("Credit Note","Credit Note Operation completed","info")

	CLOSE WINDOW A665 
END FUNCTION 
################################################################
# END FUNCTION A41_main()
################################################################


################################################################
# FUNCTION get_credit_where_text_construct() was part of select_credit(l_where_text)
#
#
################################################################
FUNCTION get_credit_where_text_construct(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 

	IF p_filter THEN
		CLEAR FORM 
		DISPLAY glob_rec_arparms.credit_ref1_text TO credit_ref1_text  attribute(white) 
	
		MESSAGE kandoomsg2("E",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cred_num, 
			cred_date, 
			cust_code, 
			cred_text, 
			year_num, 
			period_num, 
			appl_amt, 
			total_amt, 
			currency_code, 
			org_cust_code 
	
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A41","construct-credithead") 
	
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
################################################################
# END FUNCTION get_credit_where_text_construct() was part of select_credit(l_where_text)
################################################################


################################################################
# FUNCTION get_credit_datasource(p_where_text) was part of FUNCTION select_credit(p_where_text)
#
#
################################################################
FUNCTION get_credit_datasource(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			cred_num LIKE credithead.cred_num, 
			cred_date LIKE credithead.cred_date, 
			cust_code LIKE credithead.cust_code, 
			name_text LIKE customer.name_text, 
			cred_text LIKE credithead.cred_text 
		END RECORD 
		DEFINE l_idx SMALLINT 
		DEFINE l_rec_credithead RECORD LIKE credithead.* 
		DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

		MESSAGE kandoomsg2("E",1002,"")	#1002 " Searching database - please wait "
		LET l_query_text = 
			"SELECT * FROM credithead ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
			"AND credithead.total_amt >= 0 ", 
			"AND credithead.posted_flag = 'N' ", 
			"AND ",p_where_text clipped," ", 
			"ORDER BY cred_num" 
		PREPARE s_credithead FROM l_query_text 
		DECLARE c_credithead CURSOR FOR s_credithead 


		LET l_idx = 0 
		FOREACH c_credithead INTO l_rec_credithead.* 
			IF l_rec_credithead.cred_ind != "4" THEN 
				SELECT unique 1 FROM stattrig 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = l_rec_credithead.cred_num 
				AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
				IF status = NOTFOUND THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 

			LET l_idx = l_idx + 1 
			LET l_arr_rec_credithead[l_idx].scroll_flag = NULL 
			LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
			LET l_arr_rec_credithead[l_idx].cred_date = l_rec_credithead.cred_date 
			LET l_arr_rec_credithead[l_idx].cust_code = l_rec_credithead.cust_code 

			SELECT name_text INTO l_arr_rec_credithead[l_idx].name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_credithead.cust_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_arr_rec_credithead[l_idx].name_text = "**********" 
			END IF 
			LET l_arr_rec_credithead[l_idx].cred_text = l_rec_credithead.cred_text 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF	
		END FOREACH 

		IF l_arr_rec_credithead.getlength() = 0 THEN 
			ERROR kandoomsg2("E",9213,"") 		#9213" No Credits Satisfied Selection Criteria "
			-- LET l_idx = 1
			-- INITIALIZE l_arr_rec_credithead[l_idx].* TO NULL
		END IF 

		RETURN l_arr_rec_credithead 
END FUNCTION 
################################################################
# END FUNCTION get_credit_datasource(p_where_text) was part of FUNCTION select_credit(p_where_text)
################################################################


################################################################
# FUNCTION scan_credit()
#
#
################################################################
FUNCTION scan_credit(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_cred_num LIKE credithead.cred_num 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			cred_num LIKE credithead.cred_num, 
			cred_date LIKE credithead.cred_date, 
			cust_code LIKE credithead.cust_code, 
			name_text LIKE customer.name_text, 
			cred_text LIKE credithead.cred_text 
		END RECORD 
		DEFINE i SMALLINT 
		DEFINE j SMALLINT 
		DEFINE l_idx SMALLINT 

		#--------------------------------------------------------
		#NOTE: default/initial p_where_text =
		# IF glob_rec_credithead.cred_num > 0 THEN
		#    LET glob_temp_text = "cred_num ='",glob_rec_credithead.cred_num,"'"
		# ELSE
		#    LET glob_temp_text = NULL
		# END IF
		#
		#   WHILE select_credit(glob_temp_text)
		#    CALL scan_credit(glob_temp_text)
		#--------------------------------------------------------

		IF p_where_text IS NULL THEN 
			CALL l_arr_rec_credithead.clear() 
			CALL get_credit_datasource(filter_where_all) RETURNING l_arr_rec_credithead 
		ELSE 
			CALL l_arr_rec_credithead.clear() 
			CALL get_credit_where_text_construct(FALSE) RETURNING p_where_text 
			CALL get_credit_datasource(p_where_text) RETURNING l_arr_rec_credithead 
		END IF 

		{
		   LET l_idx = 0
		   FOREACH c_credithead INTO l_rec_credithead.*
		      IF l_rec_credithead.cred_ind != "4" THEN
		         SELECT unique 1 FROM stattrig
		           WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		             AND trans_num = l_rec_credithead.cred_num
		             AND tran_type_ind = TRAN_TYPE_CREDIT_CR
		         IF STATUS = NOTFOUND THEN
		            continue FOREACH
		         END IF
		      END IF

		      LET l_idx = l_idx + 1
		      LET l_arr_rec_credithead[l_idx].scroll_flag = NULL
		      LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num
		      LET l_arr_rec_credithead[l_idx].cred_date = l_rec_credithead.cred_date
		      LET l_arr_rec_credithead[l_idx].cust_code = l_rec_credithead.cust_code

		      SELECT name_text INTO l_arr_rec_credithead[l_idx].name_text
		        FROM customer
		       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		         AND cust_code = l_rec_credithead.cust_code

		      IF sqlca.sqlcode = NOTFOUND THEN
		         LET l_arr_rec_credithead[l_idx].name_text = "**********"
		      END IF
		      LET l_arr_rec_credithead[l_idx].cred_text = l_rec_credithead.cred_text

		   END FOREACH

		   IF l_arr_rec_credithead.getLength = 0 THEN
		      ERROR kandoomsg2("E",9213,"")	#9213" No Credits Satisfied Selection Criteria "
		-- LET l_idx = 1
		-- INITIALIZE l_arr_rec_credithead[l_idx].* TO NULL
		   END IF
		}
		OPTIONS DELETE KEY f36, 
		INSERT KEY f1 

		--   CALL set_count(l_idx)
		ERROR kandoomsg2("E",1068,"") 	#1068" F1 TO Add - F2 TO Cancel - RETURN TO Edit"
		--   INPUT ARRAY l_arr_rec_credithead WITHOUT DEFAULTS FROM sr_credithead.* ATTRIBUTE(UNBUFFERED, auto append = false,insert row =false, delete row=false)
		DISPLAY ARRAY l_arr_rec_credithead TO sr_credithead.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A41","inp-credithead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER" 
				CALL l_arr_rec_credithead.clear() 
				CALL get_credit_where_text_construct(TRUE) RETURNING p_where_text
				LET  p_where_text = " ", p_where_text CLIPPED, " "
				CALL get_credit_datasource(p_where_text) RETURNING l_arr_rec_credithead 

			ON ACTION "REFRESH" 
				CALL l_arr_rec_credithead.clear() 
				CALL get_credit_datasource(filter_where_all) RETURNING l_arr_rec_credithead 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_idx > 0 THEN 
					LET l_scroll_flag = l_arr_rec_credithead[l_idx].scroll_flag 
					LET l_arr_rec_credithead[l_idx].scroll_flag = l_scroll_flag 
					CALL disp_credit(l_arr_rec_credithead[l_idx].cred_num) 
				END IF 

				--     BEFORE FIELD scroll_flag
				--         LET l_idx = arr_curr()
				--         #LET scrn = scr_line()
				--         LET l_scroll_flag = l_arr_rec_credithead[l_idx].scroll_flag
				--         CALL disp_credit(l_arr_rec_credithead[l_idx].cred_num)
				--         #DISPLAY l_arr_rec_credithead[l_idx].*
				--         #     TO sr_credithead[scrn].*

				--      AFTER FIELD scroll_flag
				--         LET l_arr_rec_credithead[l_idx].scroll_flag = l_scroll_flag
				--         #DISPLAY l_arr_rec_credithead[l_idx].scroll_flag
				--         #     TO sr_credithead[scrn].scroll_flag
				--
				--         IF fgl_lastkey() = fgl_keyval("down") THEN
				--            IF arr_curr() >= arr_count()
				--            OR l_arr_rec_credithead[l_idx+1].cust_code IS NULL THEN
				--               ERROR kandoomsg2("E",9001,"")        #9001 There are no more rows...
				--               NEXT FIELD scroll_flag
				--            END IF
				--         END IF

				#EDIT ????
			ON ACTION "EDIT" 
				--  BEFORE FIELD cred_num
				IF l_arr_rec_credithead[l_idx].cred_num IS NOT NULL THEN 
					IF A41_initialize_credit_for_invoice(l_arr_rec_credithead[l_idx].cred_num) THEN 

						OPEN WINDOW A667 with FORM "A667" 
						CALL windecoration_a("A667") 

						IF process_credit(MODE_CLASSIC_EDIT) THEN 
							SELECT cred_text INTO l_arr_rec_credithead[l_idx].cred_text 
							FROM credithead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cred_num = l_arr_rec_credithead[l_idx].cred_num 
						END IF 
						CLOSE WINDOW A667 
					END IF 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 

				CALL l_arr_rec_credithead.clear() 
				CALL get_credit_datasource(filter_where_all) RETURNING l_arr_rec_credithead 

				NEXT FIELD scroll_flag 


			ON ACTION "NEW" 
				#      BEFORE INSERT
				--         IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN
				--            NEXT FIELD scroll_flag #informix bug
				--         END IF
				IF A41_initialize_credit_for_invoice("") THEN 

					OPEN WINDOW A666 with FORM "A666" 
					CALL windecoration_a("A666") 

					LET l_cred_num = process_credit(MODE_CLASSIC_ADD) 
					CLOSE WINDOW A666 
				END IF 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 

				IF l_idx > 0 THEN 
					SELECT 
						cred_num, 
						cust_code, 
						cred_date, 
						cred_text 
					INTO 
						l_arr_rec_credithead[l_idx].cred_num, 
						l_arr_rec_credithead[l_idx].cust_code, 
						l_arr_rec_credithead[l_idx].cred_date, 
						l_arr_rec_credithead[l_idx].cred_text 
					FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cred_num = l_cred_num 

					IF status = NOTFOUND THEN 
						FOR i = l_idx TO arr_count() 
							LET l_arr_rec_credithead[i].* = l_arr_rec_credithead[i+1].* 
							IF l_arr_rec_credithead[i].cust_code IS NULL THEN 
								LET l_arr_rec_credithead[i].cred_num = "" 
								LET l_arr_rec_credithead[i].cred_date = "" 
							END IF 
							#IF scrn <= 12 THEN
							#   DISPLAY l_arr_rec_credithead[i].*
							#        TO sr_credithead[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
					ELSE 
						SELECT name_text INTO l_arr_rec_credithead[l_idx].name_text 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_arr_rec_credithead[l_idx].cust_code 
					END IF 

					CALL l_arr_rec_credithead.clear() 
					CALL get_credit_datasource(filter_where_all) RETURNING l_arr_rec_credithead 
				END IF 
				--         NEXT FIELD scroll_flag

			ON KEY (F2) #credit note ???delete ???? 
				IF l_arr_rec_credithead[l_idx].cred_num IS NOT NULL 
				AND l_arr_rec_credithead[l_idx].scroll_flag IS NULL 
				AND A41_initialize_credit_for_invoice(l_arr_rec_credithead[l_idx].cred_num) THEN 

					SELECT unique 1 FROM creditdetl c, serialinfo s 
					WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND s.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND c.cred_num = l_arr_rec_credithead[l_idx].cred_num 
					AND s.credit_num = l_arr_rec_credithead[l_idx].cred_num 
					AND s.part_code = c.part_code 
					AND ( s.trantype_ind <> '0' 
					OR s.ware_code <> c.ware_code ) 
					IF status <> NOTFOUND THEN 
						LET status = kandoomsg("I",9289,'') 
						#8026 Can NOT cancel RETURN because serial items have bee
						--               NEXT FIELD scroll_flag
					ELSE --end IF 
						IF kandoomsg("E",8026,l_arr_rec_credithead[l_idx].cred_num) = "Y" THEN 
							#8026 Confirm TO cancel credit note 9999.
							##
							##
							WHENEVER ERROR CONTINUE 
							BEGIN WORK 
								CALL serial_init(glob_rec_kandoouser.cmpy_code,"C","S", l_arr_rec_credithead[l_idx].cred_num) 

								DECLARE c_creddetl_ser CURSOR FOR 
								SELECT * FROM creditdetl 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cred_num = l_rec_credithead.cred_num 

								FOREACH c_creddetl_ser INTO l_rec_creditdetl.* 
									CALL serial_delete(l_rec_creditdetl.part_code,l_rec_creditdetl.ware_code) 
									LET status = serial_return(l_rec_creditdetl.part_code,"S") 
								END FOREACH 

								IF backout_credit() > 0 THEN
									# DELETE FROM stattrig -------------------------------
									DELETE FROM stattrig 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
									AND trans_num = l_arr_rec_credithead[l_idx].cred_num 
								COMMIT WORK 
								LET l_arr_rec_credithead[l_idx].scroll_flag = "*" 
							ELSE 
								ROLLBACK WORK 
								ERROR kandoomsg2("E",7072,"") 
								LET l_arr_rec_credithead[l_idx].scroll_flag = "" 
							END IF 

							WHENEVER ERROR stop 
							WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

							CALL disp_credit(l_arr_rec_credithead[l_idx].cred_num) 
						END IF 
					END IF 
				END IF 

				CALL l_arr_rec_credithead.clear() 
				CALL get_credit_datasource(filter_where_all) RETURNING l_arr_rec_credithead 

				--         NEXT FIELD scroll_flag
				#AFTER ROW
				#   DISPLAY l_arr_rec_credithead[l_idx].*
				#        TO sr_credithead[scrn].*


		END DISPLAY 

		LET int_flag = false 
		LET quit_flag = false 
END FUNCTION 
################################################################
# FUNCTION scan_credit()
################################################################

############################################################
# FUNCTION FUNCTION db_show_creditdetl_arr_rec()
#
# This function is only used for debugging - temp table
############################################################
FUNCTION db_show_creditdetl_arr_rec()
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_creditdetl DYNAMIC ARRAY OF RECORD LIKE creditdetl.*
#	DEFINE l_rec_creditdetl t_rec_creditdetl_i_d_t
	DEFINE l_idx SMALLINT
	
	LET l_query_text = 
				"SELECT * FROM t_creditdetl ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY cred_num, line_num" 	

	PREPARE s_creditdetl FROM l_query_text
	DECLARE c_creditdetl CURSOR FOR s_creditdetl

	LET l_idx = 1
	FOREACH c_creditdetl INTO l_arr_rec_creditdetl[l_idx].*
		DISPLAY l_arr_rec_creditdetl[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH
	CALL l_arr_rec_creditdetl.delete(l_arr_rec_creditdetl.getSize())
	IF l_arr_rec_creditdetl.getSize() = 0 THEN
		CALL fgl_winmessage("temp tABLE IS EMPTY","Temp Table is emptyßnt_creditdetl","info")
	END IF
	
	MENU
		ON ACTION "ACCEPT"
			EXIT MENU
	END MENU 

END FUNCTION
############################################################
# END FUNCTION FUNCTION db_show_creditdetl_arr_rec()
############################################################

############################################################
# FUNCTION process_credit(p_mode)
#
#
################################################################
FUNCTION process_credit(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_cred_num LIKE credithead.cred_num 
	DEFINE l_where_text STRING
	DEFINE x SMALLINT 

	LET l_cred_num = NULL 
	--DISPLAY BY NAME glob_rec_country.state_code_text, 
	--glob_rec_country.post_code_text, 
	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text	attribute(white) 

	# WHILE ---------------------------------------------
	WHILE TRUE --A41_enter_credit_customer_detail(p_mode)
		
		CALL A41_enter_credit_customer_detail(p_mode) RETURNING glob_rec_customer.*
		
		IF  glob_rec_customer.cust_code IS NULL THEN
			EXIT WHILE
		END IF
		
		CALL A41_credit_total_calculation_display() 

-- we have already got the customer record
--		CALL db_customer_get_rec(UI_OFF,glob_rec_credithead.cust_code) RETURNING glob_rec_customer.* 

		SELECT unique 1 FROM t_creditdetl 
		IF sqlca.sqlcode = NOTFOUND THEN #empty temp table, no credit lines ?
			LET l_where_text = invoice_dataSource_query(FALSE) #was select_invoice()
--			IF l_where_text IS NULL OR l_where_text = FILTER_WHERE_ALL THEN
--				EXIT WHILE
--			END IF
		ELSE 
			LET l_where_text = 
				"invoicehead.inv_num in ", 
				"(SELECT unique invoice_num FROM t_creditdetl)" 
		END IF 

		# WHILE ---------------------------------------------
		WHILE A41_invoice_list_for_credit(l_where_text) 
			--CALL db_show_creditdetl_arr_rec() #huho-debug
			IF credit_for_invoice_details() THEN # Works with glob_rec_credithead.*
				IF glob_rec_credithead.acct_override_code IS NULL THEN 
					LET glob_rec_credithead.acct_override_code = setup_ar_override(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_kandoouser.sign_on_code,
						TRAN_TYPE_CREDIT_CR,
						glob_rec_customer.cust_code, 
						glob_rec_warehouse.ware_code, 
						glob_rec_arparms.show_seg_flag)
					IF glob_rec_credithead.acct_override_code IS NULL THEN 
						CONTINUE WHILE 
					END IF 
				END IF 

				OPEN WINDOW A668 with FORM "A668" 
				CALL windecoration_a("A668") 

				WHILE lineitem_scan() 
					--CALL db_show_creditdetl_arr_rec() #huho-debug
					OPEN WINDOW A669 with FORM "A669" 
					CALL windecoration_a("A669") 

					WHILE credit_summary() 
						# OPEN WINDOW w1_E5C  WITH FORM "U999"  ATTRIBUTE(border)
						#CALL windecoration_u("U999")

						MENU " Credit Note" 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","A41","menu-credit-note") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 


							COMMAND "Save"	" Save credit note TO Database" 
								MESSAGE kandoomsg2("E",1005,"") #1005 Updating Database
								GOTO bypass 
								LABEL recovery: 
								IF error_recover(glob_temp_text,status) != "Y" THEN 
									LET l_cred_num = false 
									EXIT MENU 
								END IF 

								LABEL bypass: 
								WHENEVER ERROR GOTO recovery 

								BEGIN WORK 
									IF p_mode = MODE_CLASSIC_ADD THEN 
										LET x = insert_credit() 
									ELSE 
										LET x = backout_credit() 
									END IF 
									CASE 
										WHEN x < 0 
											GOTO recovery 
										WHEN x > 0 
											LET l_cred_num = update_credit() 
											IF l_cred_num < 0 THEN 
												GOTO recovery 
											END IF 
										OTHERWISE 
											ERROR kandoomsg2("E",7072,"") #7072" credit note has changed during edit"
											LET l_cred_num = false 
											EXIT MENU 
									END CASE 
								COMMIT WORK 

								WHENEVER ERROR STOP 
								WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

								IF get_kandoooption_feature_state("AR","AC") = "Y" THEN 
									##
									## Attempt TO perform an automatic application
									##
									LET glob_temp_text = "inv_num in ", 
									"(SELECT invoice_num FROM creditdetl ", 
									"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
									"AND cred_num=",l_cred_num USING "<<<<<<<<",")" 
									LET x = auto_credit_apply(glob_rec_kandoouser.sign_on_code,l_cred_num, 
									glob_temp_text) 
								END IF 

								SELECT * FROM credithead 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cred_num = l_cred_num 
								AND appl_amt != total_amt 
								MESSAGE kandoomsg2("E","9276",l_cred_num) #9276, Credit note <value> has been successfully created

								IF sqlca.sqlcode = 0 THEN 
								MENU " Credit Application " 
										BEFORE MENU 
											CALL publish_toolbar("kandoo","A41","menu-credit-application") 

										ON ACTION "WEB-HELP" 
											CALL onlinehelp(getmoduleid(),null) 

										ON ACTION "actToolbarManager" 
											CALL setuptoolbar() 


										COMMAND "MANUAL" " Apply credit note TO invoices" 
											CALL run_prog("A48","","","","") 
											EXIT MENU 

										COMMAND "AUTO" " Apply credit note TO invoices in date sequence" 
											IF auto_credit_apply(glob_rec_kandoouser.sign_on_code,l_cred_num,"")then 
											END IF 
											EXIT MENU 

										ON ACTION "CANCEL" 
											CALL fgl_winmessage("Abbort","Credit Note was NOT applied to the invoice!\nHuHo: I have no idea what impact this has....","info")
											LET int_flag = false 
											LET quit_flag = false 
											EXIT MENU 


									END MENU 

								END IF 

								EXIT MENU 

							COMMAND "Discard" 
								" Discard (new credit/changed credit) changes" 
								LET l_cred_num = false 
								EXIT MENU 

							COMMAND KEY("E",interrupt)"Exit" 
								" RETURN TO editting credit" 
								LET quit_flag = true 
								EXIT MENU 

						END MENU 

						#CLOSE WINDOW w1_E5C

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
						ELSE 
							EXIT WHILE 
						END IF 

					END WHILE 

					CLOSE WINDOW A669 

					IF l_cred_num IS NOT NULL THEN 
						EXIT WHILE 
					END IF 
				END WHILE 

				CLOSE WINDOW A668 

			END IF 

			IF l_cred_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 
		END WHILE 

		IF p_mode = MODE_CLASSIC_EDIT THEN 
			EXIT WHILE 
		END IF 
		IF l_cred_num IS NOT NULL THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	RETURN l_cred_num 
END FUNCTION 
################################################################
# END FUNCTION process_credit(p_mode)
################################################################


################################################################
# FUNCTION A41_initialize_credit_for_invoice(p_cred_num)
#
# decides if it is new or edit invoice based on p_credit_num
################################################################
FUNCTION A41_initialize_credit_for_invoice(p_cred_num) 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE l_edit BOOLEAN
	
	INITIALIZE glob_rec_credithead.* TO NULL 
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_warehouse.* TO NULL 

	# DELETE FROM t_creditdetl 
	DELETE FROM t_creditdetl 
	
	IF p_cred_num = 0 OR p_cred_num IS NULL THEN #empty credit number - does not exist
		LET l_edit = FALSE
	ELSE
		LET l_edit = db_credithead_cred_num_exist(p_cred_num) #check if credit number exists 
	END IF
	
	# IF EDIT
	IF l_edit THEN
		MESSAGE "Edit existing Credit"
		CALL db_credithead_get_rec(UI_OFF,p_cred_num) RETURNING glob_rec_credithead.*

		LET glob_rec_orig_cred_amt = glob_rec_credithead.total_amt 

		IF glob_rec_credithead.appl_amt > 0 THEN
			IF kandoomsg("E",8027,"") = "N" THEN			#8027 Confirm TO Un apply credit
				RETURN FALSE #Abbort - user does not want to continue 
			END IF 
			
			CALL unapply_credit_from_invoice_receipt(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_credithead.cust_code, 
				glob_rec_credithead.cred_num,
				glob_rec_kandoouser.sign_on_code) 
			
			LET glob_rec_credithead.appl_amt = 0 
		END IF 

		CALL db_customer_get_rec(UI_OFF,glob_rec_credithead.cust_code) RETURNING glob_rec_customer.* 

		SELECT * INTO glob_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = 
			(SELECT unique ware_code 
			FROM creditdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = p_cred_num 
			AND ware_code IS NOT null) 

		--call fgl_winmessage("check INSERT INTO t_creditdetl",p_cred_num,"info")

		# INSERT row from creditdetl table INTO temp t_creditdetl ------------------------------
		INSERT INTO t_creditdetl 
		SELECT * FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = p_cred_num 

		--CALL db_show_creditdetl_arr_rec() #huho-debug

	
	# IF NEW Credit note ########################
	ELSE --IF status = NOTFOUND THEN
		MESSAGE "Create new Credit" 
		CALL init_rec_credithead_globals()		
	END IF 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, "C", "S", p_cred_num)
	 
	RETURN TRUE #continue process
END FUNCTION 
################################################################
# END FUNCTION A41_initialize_credit_for_invoice(p_cred_num)
################################################################

################################################################
# FUNCTION init_rec_credithead_globals()
#
#
################################################################
FUNCTION init_rec_credithead_globals()
		LET glob_rec_orig_cred_amt = 0 
		LET glob_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_credithead.cred_date = today 
		LET glob_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_credithead.entry_date = today 
		LET glob_rec_credithead.rev_date = today 
		LET glob_rec_credithead.rev_num = 0 
		LET glob_rec_credithead.goods_amt = 0 
		LET glob_rec_credithead.hand_amt = 0 
		LET glob_rec_credithead.hand_tax_amt = 0 
		LET glob_rec_credithead.freight_amt = 0 
		LET glob_rec_credithead.freight_tax_amt = 0 
		LET glob_rec_credithead.tax_amt = 0 
		LET glob_rec_credithead.total_amt = 0 
		LET glob_rec_credithead.cost_amt = 0 
		LET glob_rec_credithead.appl_amt = 0 
		LET glob_rec_credithead.disc_amt = 0 
		LET glob_rec_credithead.conv_qty = 0 
		LET glob_rec_credithead.on_state_flag = "N" 
		LET glob_rec_credithead.posted_flag = "N" 
		LET glob_rec_credithead.cred_ind = "1" 
		LET glob_rec_credithead.next_num = 0 
		LET glob_rec_credithead.line_num = 0 
		LET glob_rec_credithead.printed_num = 0 
		LET glob_rec_credithead.reason_code = glob_rec_arparms.reason_code 
		
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cred_date) 
		RETURNING	glob_rec_credithead.year_num,	glob_rec_credithead.period_num
		
END FUNCTION
################################################################
# END FUNCTION init_rec_credithead_globals()
################################################################


################################################################
# FUNCTION A41_credit_total_calculation_display()
#
# Displays AMOUNT data currency, goods, tax, total in the current form (A666 ?)
################################################################
FUNCTION A41_credit_total_calculation_display() 

	SELECT sum(ext_sales_amt), 
	sum(ext_tax_amt), 
	sum(line_total_amt) 
	INTO 
		glob_rec_credithead.goods_amt, 
		glob_rec_credithead.tax_amt, 
		glob_rec_credithead.total_amt 
	FROM t_creditdetl 

	DISPLAY glob_rec_credithead.goods_amt  TO  goods_amt #ATTRIBUTE(MAGENTA)
	DISPLAY glob_rec_credithead.tax_amt    TO  tax_amt   #ATTRIBUTE(MAGENTA) 
	DISPLAY glob_rec_credithead.total_amt  TO  total_amt #ATTRIBUTE(MAGENTA)
	 
	DISPLAY glob_rec_credithead.currency_code TO currency_code 
	--DISPLAY BY NAME glob_rec_cashreceipt.applied_amt ATTRIBUTE(GREEN) 

--	CALL db_show_creditdetl_arr_rec()

END FUNCTION 
################################################################
# END FUNCTION A41_initialize_credit_for_invoice(p_cred_num)
################################################################


################################################################
# FUNCTION disp_credit(l_cred_num)
#
#
################################################################
FUNCTION disp_credit(l_cred_num) 
	DEFINE l_cred_num LIKE credithead.cred_num 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_org_name_text LIKE customer.name_text 

	SELECT * INTO l_rec_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = l_cred_num 

	IF status = NOTFOUND THEN 
		CLEAR year_num, 
		period_num, 
		appl_amt, 
		total_amt, 
		currency_code, 
		org_cust_code, 
		org_name_text, 
		currency_code 
	ELSE 
		IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
			SELECT name_text INTO l_org_name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_credithead.org_cust_code 
			IF status = NOTFOUND THEN 
				LET l_org_name_text = "**********" 
			END IF 
		ELSE 
			LET l_org_name_text = NULL 
		END IF 

		DISPLAY BY NAME 
			l_rec_credithead.year_num, 
			l_rec_credithead.period_num, 
			l_rec_credithead.appl_amt, 
			l_rec_credithead.total_amt, 
			l_rec_credithead.currency_code, 
			l_rec_credithead.org_cust_code 

		DISPLAY l_org_name_text TO org_name_text 

		DISPLAY BY NAME l_rec_credithead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

	END IF 

END FUNCTION 
################################################################
# END FUNCTION disp_credit(l_cred_num)
################################################################