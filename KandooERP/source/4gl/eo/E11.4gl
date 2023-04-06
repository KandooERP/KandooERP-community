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
# \brief module E11 - Maintainence program FOR Sales Orders
#                This program allows the addition AND editting of
#                sales orders entered FOR advanced ORDER entry.
#
#          E11.4gl
#              - main line structure
#              - process_order() FUNCTION that controls everything
#              - INITIALIZE_ord() FUNCTION which IS called between each
#                   ORDER add/edit TO reset GLOBALS & CLEAR temp tables.
#
#          E11a.4gl
#              - header_entry()  retrieves first SCREEN INPUT FOR add/edit.
#              - INITIALIZE_ord() resets all GLOBALS AND temp tables
#
#          E11b.4gl
#              - pay_detail() retrieves second SCREEN INPUT orders.
#                             Enter terms/tax/conditions etc...
#              - view_cust()  Allows user TO view customer account
#                             details. ie: balance, credit available
#              - commission() Allows user TO distribute sales commission
#                             TO salespersons (iff customer.share_flag = Y)
#              - stock_line() Updates ORDER warehouse reserving AND backordering
#                             stock as required.
#                                 Called FROM lineitems FOR detailed entry
#          E11c.4gl
#              - offer_scan() Allows user TO nominate offers AND quantities of
#
#          E11d.4gl
#              - lineitem_scan()  displays a scan of ORDER line item AND allows
#                                 add/edit/delete of such.
#
#          E11e.4gl
#              - lineitem_entry() Detailed line entry (window FOR 1 line).
#                                 Called FROM lineitems FOR detailed entry
#
#          E11f.4gl
#              - checkoffer() displays a scan of special offers used
#                             AND performs checking calculations on each.
#
#          E11g.4gl
#              - summary()    Allows user TO enter freight handling AND
#                             shipping instruction FOR this ORDER
#
#          E11h.4gl
#              - insert_order() Inserts a blank new ORDER INTO the database
#              - write_order()  Updates database with new data

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"
###########################################################################
# FUNCTION E11_main()
#
#
###########################################################################
FUNCTION E11_main() 
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_prompt_text char(40) 
	DEFINE l_where_text STRING
	
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E11") 

	LET glob_yes_flag = "Y" 
	LET glob_no_flag = "N" 
	LET glob_rec_sales_order_parameter.order_date = today 
	LET glob_rec_sales_order_parameter.ship_date = today 
	LET glob_rec_sales_order_parameter.def_suppl_flag = glob_no_flag 
	LET glob_rec_sales_order_parameter.def_paydetl_flag = glob_no_flag 
	LET glob_rec_sales_order_parameter.complete_flag = glob_no_flag 
	LET glob_rec_sales_order_parameter.owner_text = glob_rec_kandoouser.sign_on_code 

	CALL create_table("saleshare","t_saleshare","","N") 
	CALL create_table("orderlog","t_orderlog","","N") 
	CALL create_table("orderdetl","t_orderdetl","","Y") 
	CALL create_table("orderdetl","t2_orderdetl","","Y") 
	CALL create_table("orderdetl","t3_orderdetl","","Y") 
	CALL create_table("cashreceipt","t_cashreceipt","","N") 
	CALL create_matrix_table() 
	CALL cr_offer_tables()
	 
	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
	IF glob_rec_opparms.cmpy_code IS NULL THEN 
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program EZP)",kandoomsg2("E",5105,""),"ERROR") #5105 Order Entry Parameters NOT SET up; Refer Menu EZP. #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
		EXIT PROGRAM 
	END IF 
	
	LET l_prompt_text = glob_rec_arparms.inv_ref1_text clipped,	".................." 
	LET glob_rec_arparms.inv_ref1_text = l_prompt_text clipped 

	SELECT country.* INTO glob_rec_country.* 
	FROM country,	company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND country.country_code = company.country_code 
	
	LET l_prompt_text = glob_rec_country.state_code_text clipped, ".................." 
	LET glob_rec_country.state_code_text = l_prompt_text 
	LET l_prompt_text = glob_rec_country.post_code_text clipped, ".................." 
	LET glob_rec_country.post_code_text = l_prompt_text 

{
	MENU
		ON ACTION "NEW"
		
			OPEN WINDOW E111 with FORM "E111" 
			 CALL windecoration_e("E111")
		
			#Hubert: Original is always 1. add new item followed by the manager...
			#for me, this is confusing.. I add a menu to see, if this makes it clearer
			 
			#process_order
			LET l_order_num = process_order(MODE_CLASSIC_ADD,"") #get's only processsed ONCE ! add NEW order
		
			CLOSE WINDOW E111 

		ON ACTION "EDIT"
}
			OPEN WINDOW E110 with FORM "E110" 
			 CALL windecoration_e("E110")  

			IF l_order_num > 0 THEN 
				LET l_where_text = " order_num=",trim(l_order_num), " "  #form SQL WHERE part
				LET l_prompt_text = "order_num ='",l_order_num,"'" #I believe, this can may be removed
			ELSE 
				LET l_prompt_text = NULL 
				#HuHo Note: User cancel is not exit/quit (original program logic)
			END IF 
		
--		WHILE db_orderhead_get_datasource(l_prompt_text) 
				CALL scan_orders(l_where_text) #l_where_text = something like " order_num = 123 "
--			LET l_prompt_text = NULL 
--		END WHILE 

			CLOSE WINDOW E110
	{	
		ON ACTION "EXIT"
			EXIT MENU
			
	END MENU
}	 
END FUNCTION
############################################################
# END FUNCTION E11_main()
############################################################


###########################################################################
# FUNCTION db_orderhead_get_datasource(p_filter, p_where_text)
#
#
###########################################################################
FUNCTION db_orderhead_get_datasource(p_filter, p_where_text)
	DEFINE p_filter BOOLEAN 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD 
--		scroll_flag char(1), 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		hold_code LIKE orderhead.hold_code, 
		sales_code LIKE orderhead.sales_code, 
		status_ind LIKE orderhead.status_ind, 
		ship_date LIKE orderhead.ship_date 
	END RECORD 
	DEFINE l_arr_rec_orderhead2 DYNAMIC ARRAY OF RECORD 
		name_text LIKE customer.name_text, 
		cond_code LIKE orderhead.cond_code, 
		desc_text LIKE pricing.desc_text 
	END RECORD 
 
	CLEAR FORM 
	
	IF p_where_text IS NOT NULL THEN 
		LET p_filter = FALSE
	END IF
	
	IF p_filter = TRUE THEN 
		MESSAGE kandoomsg2("E",1054,"") 	#1054 Enter Selection - ESC TO Continue F8 Session Defs
		CONSTRUCT BY NAME p_where_text ON 
			order_num, 
			cust_code, 
			order_date, 
			total_amt, 
			hold_code, 
			sales_code, 
			status_ind, 
			ship_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E11","construct-order_num-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "DEFAULT" --KEY (f8) 
				CALL enter_defaults() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET p_where_text = " 1=1 " 
		END IF

	ELSE

		IF p_where_text IS NULL THEN 
			LET p_where_text = " 1=1 "
		END IF

	END IF
	
	IF get_kandoooption_feature_state("EO","SO") = 'N' THEN 
		IF glob_rec_sales_order_parameter.owner_text IS NOT NULL THEN 
			LET p_where_text = p_where_text clipped, " AND entry_code='",trim(glob_rec_sales_order_parameter.owner_text),"'" 
		END IF 
	END IF 
	
	IF glob_rec_sales_order_parameter.complete_flag = glob_no_flag THEN 
		LET p_where_text = p_where_text clipped," AND status_ind != 'C'" 
	END IF
	 
	MESSAGE kandoomsg2("U",1002,"") #1002 Searching database; Please wait.
	LET l_query_text = 
		"SELECT * FROM orderhead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ord_ind in ('2','3') ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY order_num" 
	PREPARE s_orderhead FROM l_query_text 
	DECLARE c_orderhead cursor FOR s_orderhead 

	LET l_idx = 0 
	FOREACH c_orderhead INTO glob_rec_orderhead.* 
		LET l_idx = l_idx + 1 
--		LET l_arr_rec_orderhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_orderhead[l_idx].order_num = glob_rec_orderhead.order_num 
		LET l_arr_rec_orderhead[l_idx].cust_code = glob_rec_orderhead.cust_code 

		SELECT name_text INTO l_arr_rec_orderhead2[l_idx].name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_orderhead.cust_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_arr_rec_orderhead2[l_idx].name_text = "" 
		END IF 

		LET l_arr_rec_orderhead2[l_idx].cond_code = glob_rec_orderhead.cond_code 
		SELECT desc_text INTO l_arr_rec_orderhead2[l_idx].desc_text FROM condsale 
		WHERE cond_code = l_arr_rec_orderhead2[l_idx].cond_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET l_arr_rec_orderhead[l_idx].order_date = glob_rec_orderhead.order_date 
		LET l_arr_rec_orderhead[l_idx].total_amt = glob_rec_orderhead.total_amt 
		LET l_arr_rec_orderhead[l_idx].hold_code = glob_rec_orderhead.hold_code 
		LET l_arr_rec_orderhead[l_idx].status_ind = glob_rec_orderhead.status_ind 
		LET l_arr_rec_orderhead[l_idx].ship_date = glob_rec_orderhead.ship_date 
		LET l_arr_rec_orderhead[l_idx].sales_code = glob_rec_orderhead.sales_code
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9049,"") #9049" No Orders Satisfied Selection Criteria "
		LET l_idx = 1 
--		INITIALIZE l_arr_rec_orderhead[1].* TO NULL 
--		INITIALIZE l_arr_rec_orderhead2[1].* TO NULL 
	END IF 

	RETURN l_arr_rec_orderhead  
END FUNCTION 
############################################################
# END FUNCTION db_orderhead_get_datasource(p_filter,p_where_text)
############################################################


###########################################################################
# FUNCTION scan_orders()
#
#
###########################################################################
FUNCTION scan_orders(p_where_text) #l_prompt_text char(40)
	DEFINE p_where_text STRING 
	DEFINE l_order_num LIKE orderhead.order_num 
--	DEFINE l_scroll_flag char(1) 
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD 
--		scroll_flag char(1), 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		hold_code LIKE orderhead.hold_code, 
		sales_code LIKE orderhead.sales_code, 
		status_ind LIKE orderhead.status_ind, 
		ship_date LIKE orderhead.ship_date 
	END RECORD 
	DEFINE l_arr_rec_orderhead2 DYNAMIC ARRAY OF RECORD 
		name_text LIKE customer.name_text, 
		cond_code LIKE orderhead.cond_code, 
		desc_text LIKE pricing.desc_text 
	END RECORD 
	DEFINE l_rec_orderlog RECORD LIKE orderlog.* 
	DEFINE l_change_status SMALLINT
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_count SMALLINT
	DEFINE l_filter BOOLEAN
	DEFINE l_status BOOLEAN
--	DEFINE l_pick_ind LIKE pickhead.status_ind 

	#-------------------
	#Get all records if there are not too many
	SELECT count(*) INTO l_count FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ord_ind in ('2','3') 
	
	IF l_count < get_settings_maxListArraySizeSwitch() THEN
		LET l_filter = FALSE
	ELSE
		LET l_filter = TRUE
	END IF

	CALL db_orderhead_get_datasource(l_filter, p_where_text) RETURNING l_arr_rec_orderhead

	LET p_where_text = NULL #reset where text
	#-----------------

	MESSAGE kandoomsg2("E",1014,"")	#1014 F1 Add; F2 Cancel Order; F5 Hold;F8 Session Params; TAB TO Edit line.
	--INPUT ARRAY l_arr_rec_orderhead WITHOUT DEFAULTS FROM sr_orderhead.* ATTRIBUTE(UNBUFFERED,delete row = FALSE, INSERT ROW = FALSE)
	DISPLAY ARRAY l_arr_rec_orderhead TO sr_orderhead.* ATTRIBUTE(UNBUFFERED)	
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E11","input-l_arr_rec_orderhead-1") 

		ON ACTION "WEB-HELP"
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "DEFAULT" --ON KEY (f8) 
			CALL enter_defaults() 

		ON ACTION "FILTER"
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_get_datasource(TRUE, NULL) RETURNING l_arr_rec_orderhead		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E110")
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_get_datasource(FALSE, NULL) RETURNING l_arr_rec_orderhead		


		ON ACTION "F5-Scan?" --ON KEY (f5) --infield(scroll_flag)  
				IF l_arr_rec_orderhead[l_idx].order_num IS NOT NULL THEN 
					DECLARE c_edithold cursor FOR 
					SELECT * INTO glob_rec_orderhead.* FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_orderhead[l_idx].order_num 
					FOR UPDATE 
					SELECT * INTO glob_rec_orderhead.* FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_orderhead[l_idx].order_num 
					IF glob_rec_orderhead.status_ind = "X" THEN 
						ERROR kandoomsg2("E",9254,"") 					#9254 "Order has been locked by another process"
						--NEXT FIELD scroll_flag 
					END IF 
					
					BEGIN WORK
					 
						WHENEVER ERROR CONTINUE
						 
						OPEN c_edithold 
						FETCH c_edithold 
						IF status <> 0 THEN 
							ERROR kandoomsg2("E",9253,"") 					#9253 "Unable TO lock ORDER FOR edit"
							ROLLBACK WORK 
							WHENEVER ERROR stop 
							--NEXT FIELD scroll_flag 
						ELSE --END IF 
						
							IF glob_rec_orderhead.status_ind = "X" THEN 
								ERROR kandoomsg2("E",9254,"") 					#9254 "Order has been locked by another process"
								ROLLBACK WORK 
								WHENEVER ERROR stop 
								--NEXT FIELD scroll_flag 
							ELSE --END IF 
							
								LET glob_status_ind = glob_rec_orderhead.status_ind 
								
								UPDATE orderhead SET status_ind = "X" 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND order_num = glob_rec_orderhead.order_num 
								IF status <> 0 THEN 
									ERROR kandoomsg2("E",9253,"") 					#9253 "Unable TO lock ORDER FOR edit"
									ROLLBACK WORK 
									WHENEVER ERROR stop 
									--NEXT FIELD scroll_flag 
								END IF
							END IF # 
						END IF #cursor status	status_ind = "X" = order has been locked				
					COMMIT WORK #------------------------------------------------- 
					
					WHENEVER ERROR stop 
					
					IF enter_hold() THEN 
						UPDATE orderhead 
						SET 
							hold_code = glob_rec_orderhead.hold_code, 
							status_ind = glob_status_ind 
						WHERE order_num = l_arr_rec_orderhead[l_idx].order_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_arr_rec_orderhead[l_idx].hold_code = glob_rec_orderhead.hold_code 
						DECLARE c_orderlog cursor FOR 
						SELECT * FROM t_orderlog 
					
						FOREACH c_orderlog INTO l_rec_orderlog.* 
							CALL insert_log(
								glob_rec_kandoouser.cmpy_code,
								glob_rec_kandoouser.sign_on_code, 
								glob_rec_orderhead.order_num, 
								l_rec_orderlog.event_text, 
								l_rec_orderlog.curr_text, 
								l_rec_orderlog.prev_text) 
						END FOREACH 
					
						DELETE FROM t_orderlog 
						WHERE 1=1 
					
					ELSE 
					
						UPDATE orderhead 
						SET 
							hold_code = glob_rec_orderhead.hold_code, 
							status_ind = glob_status_ind 
						WHERE order_num = l_arr_rec_orderhead[l_idx].order_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				--NEXT FIELD scroll_flag 
 
		BEFORE ROW --FIELD scroll_flag 
			LET l_idx = arr_curr() 
	--		LET l_scroll_flag = l_arr_rec_orderhead[l_idx].scroll_flag 
			
			INITIALIZE glob_rec_orderhead.* TO NULL 
			
			SELECT * INTO glob_rec_orderhead.* FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_arr_rec_orderhead[l_idx].order_num 
			
--			LET l_arr_rec_orderhead[l_idx].scroll_flag = NULL 
			LET l_arr_rec_orderhead[l_idx].order_num = glob_rec_orderhead.order_num 
			LET l_arr_rec_orderhead[l_idx].cust_code = glob_rec_orderhead.cust_code 
			
			SELECT name_text INTO l_arr_rec_orderhead2[l_idx].name_text FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_orderhead.cust_code 
			
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_arr_rec_orderhead2[l_idx].name_text = "" 
			END IF 
			
			LET l_arr_rec_orderhead2[l_idx].cond_code = glob_rec_orderhead.cond_code 
			
			SELECT desc_text INTO l_arr_rec_orderhead2[l_idx].desc_text FROM condsale 
			WHERE cond_code = l_arr_rec_orderhead2[l_idx].cond_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			LET l_arr_rec_orderhead[l_idx].order_date = glob_rec_orderhead.order_date 
			LET l_arr_rec_orderhead[l_idx].total_amt = glob_rec_orderhead.total_amt 
			LET l_arr_rec_orderhead[l_idx].hold_code = glob_rec_orderhead.hold_code 
			LET l_arr_rec_orderhead[l_idx].sales_code = glob_rec_orderhead.sales_code 
			LET l_arr_rec_orderhead[l_idx].status_ind = glob_rec_orderhead.status_ind 
			LET l_arr_rec_orderhead[l_idx].ship_date = glob_rec_orderhead.ship_date 

			DISPLAY l_arr_rec_orderhead2[l_idx].name_text TO name_text 
			DISPLAY l_arr_rec_orderhead2[l_idx].cond_code TO cond_code 
			DISPLAY l_arr_rec_orderhead2[l_idx].desc_text TO desc_text

--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_orderhead[l_idx].scroll_flag = l_scroll_flag 
--
--			IF fgl_lastkey() = fgl_keyval("down") THEN 
--				IF arr_curr() >= arr_count() 
--				OR l_arr_rec_orderhead[l_idx+1].cust_code IS NULL THEN 
--					ERROR kandoomsg2("E",9001,"") 
--					NEXT FIELD scroll_flag 
--				END IF 
--			END IF 

		ON ACTION ("EDIT","DOUBLECLICK")
--		BEFORE FIELD order_num 
			LET l_status = TRUE #init var.. will be FALSE in case of error/rollback
			
			IF l_arr_rec_orderhead[l_idx].order_num IS NOT NULL THEN 
				DECLARE c_editorder cursor FOR 
				SELECT * INTO glob_rec_orderhead.* 
				FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_arr_rec_orderhead[l_idx].order_num 
				FOR UPDATE 
				
				SELECT * INTO glob_rec_orderhead.* FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_arr_rec_orderhead[l_idx].order_num 
				IF glob_rec_orderhead.status_ind = "X" THEN 
					ERROR kandoomsg2("E",9254,"") 		#9254 "Order has been locked by another process"
					LET l_status = FALSE--NEXT FIELD scroll_flag 
				END IF 

				IF l_status THEN #check 1

					# BEGIN WORK --------------------------------
					BEGIN WORK 
	
					WHENEVER ERROR CONTINUE 
					OPEN c_editorder 
					FETCH c_editorder 
					IF status <> 0 THEN 
						ERROR kandoomsg2("E",9253,"") 		#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						LET l_status = FALSE --NEXT FIELD scroll_flag 
					END IF 
	
					IF l_status THEN #check 2
						IF glob_rec_orderhead.status_ind = "X" THEN 
							ERROR kandoomsg2("E",9254,"")	#9254 "Order has been locked by another process"
	
							ROLLBACK WORK 
							WHENEVER ERROR stop 
	
						LET l_status = FALSE --NEXT FIELD scroll_flag 
						END IF 
--					END IF
						
						
						IF l_status THEN #check 3
											
							LET glob_status_ind = glob_rec_orderhead.status_ind 
							
							UPDATE orderhead SET status_ind = "X" 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = glob_rec_orderhead.order_num 
							IF status <> 0 THEN 
								ERROR kandoomsg2("E",9253,"")		#9253 "Unable TO lock ORDER FOR edit"
		
								ROLLBACK WORK 
								WHENEVER ERROR stop 
		
								LET l_status = FALSE --NEXT FIELD scroll_flag 
							END IF 
--						END IF

							IF l_status THEN #check 4
								COMMIT WORK 
								WHENEVER ERROR stop 
								# COMMIT WORK -------------------------------------
							END IF #check 4					
						END IF #check 3
					END IF #check 2
--			END IF #check 1 is at the end of this event block
				
					OPEN WINDOW E120 with FORM "E120" 
					 CALL windecoration_e("E120") -- albo kd-755
	 
					CALL process_order("EDIT",l_arr_rec_orderhead[l_idx].order_num) 
					RETURNING l_order_num 
	
					CLOSE WINDOW E120 
	
					SELECT 
						total_amt, 
						status_ind, 
						ship_date, 
						sales_code 
					INTO 
						l_arr_rec_orderhead[l_idx].total_amt, 
						l_arr_rec_orderhead[l_idx].status_ind, 
						l_arr_rec_orderhead[l_idx].ship_date, 
						l_arr_rec_orderhead[l_idx].sales_code 
					FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_orderhead[l_idx].order_num 
				END IF 
				
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				--NEXT FIELD scroll_flag 

			END IF #check 1


		ON ACTION "NEW"
		
			OPEN WINDOW E111 with FORM "E111" 
			 CALL windecoration_e("E111")
		
			#Hubert: Original is always 1. add new item followed by the manager...
			#for me, this is confusing.. I add a menu to see, if this makes it clearer
			 
			#process_order
			LET glob_status_ind = "I"
			LET l_order_num = process_order(MODE_CLASSIC_ADD,"") #get's only processsed ONCE ! add NEW order
		
			CLOSE WINDOW E111 
			CALL db_orderhead_get_datasource(FALSE, p_where_text) RETURNING l_arr_rec_orderhead


{
		ON ACTION "NEW"
		#BEFORE INSERT --------------------------------------------------
--		BEFORE INSERT 
			OPEN WINDOW E111 with FORM "E111" 
			 CALL windecoration_e("E111") 

			LET glob_status_ind = "I" 
			LET l_order_num = process_order(MODE_CLASSIC_ADD,"") 

			CLOSE WINDOW E111 

			OPTIONS DELETE KEY f36, 
			INSERT KEY f1
			 
			SELECT 
				order_num, 
				cust_code, 
				order_date, 
				total_amt, 
				hold_code, 
				sales_code, 
				status_ind, 
				ship_date 
			INTO 
				l_arr_rec_orderhead[l_idx].order_num, 
				l_arr_rec_orderhead[l_idx].cust_code, 
				l_arr_rec_orderhead[l_idx].order_date, 
				l_arr_rec_orderhead[l_idx].total_amt, 
				l_arr_rec_orderhead[l_idx].hold_code, 
				l_arr_rec_orderhead[l_idx].sales_code, 
				l_arr_rec_orderhead[l_idx].status_ind, 
				l_arr_rec_orderhead[l_idx].ship_date 
			FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_order_num 

			IF status = NOTFOUND THEN 
--				FOR i = l_idx TO 199 
--					LET l_arr_rec_orderhead[i].* = l_arr_rec_orderhead[i+1].* 
--					IF l_arr_rec_orderhead[i].cust_code IS NULL THEN --
--						LET l_arr_rec_orderhead[i].order_num = "" 
--						LET l_arr_rec_orderhead[i].order_date = "" 
--						LET l_arr_rec_orderhead[i].total_amt = "" 
--					END IF 
--					IF scrn <= 12 THEN 
--						DISPLAY l_arr_rec_orderhead[i].* 
--						TO sr_orderhead[scrn].* 
--
--						LET scrn = scrn + 1 
--					END IF 
--					IF l_arr_rec_orderhead[i].cust_code IS NULL THEN 
--						INITIALIZE l_arr_rec_orderhead[i].* TO NULL 
--						CALL set_count(i-1) 
--						EXIT FOR 
--					END IF 
--				END FOR 
			
			ELSE 
			
				SELECT name_text INTO l_arr_rec_orderhead2[l_idx].name_text 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_arr_rec_orderhead[l_idx].cust_code 
				LET l_arr_rec_orderhead2[l_idx].cond_code = glob_rec_orderhead.cond_code 
	
				SELECT desc_text INTO l_arr_rec_orderhead2[l_idx].desc_text FROM condsale 
				WHERE cond_code = l_arr_rec_orderhead2[l_idx].cond_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			CALL db_orderhead_get_datasource(FALSE, p_where_text) RETURNING l_arr_rec_orderhead

			--NEXT FIELD scroll_flag
}			 
		ON ACTION "CANCEL ORDER" --ON KEY (f2)  --CANCEL/DELETE ORDER 
			IF (l_arr_rec_orderhead[l_idx].order_num IS NOT NULL)	AND (l_arr_rec_orderhead[l_idx].status_ind = "U") THEN 
				DECLARE c2_edithold cursor FOR 
				SELECT * INTO glob_rec_orderhead.* FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_arr_rec_orderhead[l_idx].order_num
				 
				FOR UPDATE 
				SELECT * INTO glob_rec_orderhead.* FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_arr_rec_orderhead[l_idx].order_num 
				
				IF glob_rec_orderhead.status_ind = "X" THEN 
					ERROR kandoomsg2("E",9254,"") 		#9254 "Order has been locked by another process"
					--NEXT FIELD scroll_flag 
				END IF 

				BEGIN WORK 

					WHENEVER ERROR CONTINUE 
					OPEN c2_edithold 
					FETCH c2_edithold 
					IF status <> 0 THEN 
						ERROR kandoomsg2("E",9253,"") 				#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						--NEXT FIELD scroll_flag 
					END IF 

					IF glob_rec_orderhead.status_ind = "X" THEN 
						ERROR kandoomsg2("E",9254,"") 			#9254 "Order has been locked by another process"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						--NEXT FIELD scroll_flag 
					END IF 

					LET glob_status_ind = glob_rec_orderhead.status_ind 
					UPDATE orderhead SET status_ind = "X" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = glob_rec_orderhead.order_num 
					IF status <> 0 THEN 
						ERROR kandoomsg2("E",9253,"") 			#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						--NEXT FIELD scroll_flag 
					END IF 
	
					SELECT unique 1 FROM pickhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND (status_ind = "0" 
					OR status_ind = "1" 
					OR con_status_ind = "1") 
					AND pick_num in (select unique pick_num FROM pickdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_orderhead[l_idx].order_num) 
					IF status = 0 THEN 
						ERROR kandoomsg2("E",9275,"") 				#9275 Order has been picked - cannot cancel
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						--NEXT FIELD scroll_flag 
					END IF 
	
					IF kandoomsg("E",8010,l_arr_rec_orderhead[l_idx].order_num) = "N" THEN				#8010 Confirm TO cancel ORDER
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						--NEXT FIELD scroll_flag 
					END IF 

				COMMIT WORK 
				WHENEVER ERROR stop 

				MESSAGE kandoomsg2("U",1005,"")		#1005 Updating Database - pls. wait

				CALL initialize_ord(l_arr_rec_orderhead[l_idx].order_num) 
				IF write_order(1) THEN 
					SELECT 
						total_amt, 
						status_ind 
					INTO 
						l_arr_rec_orderhead[l_idx].total_amt, 
						l_arr_rec_orderhead[l_idx].status_ind 
					FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_orderhead[l_idx].order_num 
				ELSE 
					UPDATE orderhead 
					SET status_ind = glob_status_ind 
					WHERE order_num = glob_rec_orderhead.order_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 

				MESSAGE kandoomsg2("E",1014,"")	#1014 F1 Add - F2 Cancel - RETURN Edit - F8 Session Defaults"

			END IF 
			--NEXT FIELD scroll_flag 

--		AFTER ROW 
--			DISPLAY l_arr_rec_orderhead[l_idx].* 
--			TO sr_orderhead[scrn].* 


	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE
	 
END FUNCTION 
############################################################
# END FUNCTION scan_orders()
############################################################


###########################################################################
# FUNCTION process_order(p_mode,p_order_num)
#
#
###########################################################################
FUNCTION process_order(p_mode,p_order_num) 
	DEFINE p_mode char(4) 
	DEFINE p_order_num LIKE orderhead.order_num
	
	DEFINE l_hold_order char(1) 
	DEFINE l_mask_code LIKE customertype.acct_mask_code 
	DEFINE l_cash_amt decimal(16,2) 
	DEFINE l_retry SMALLINT 

	CALL initialize_ord(p_order_num) #NULL argument for new orders, otherwise EDIT 
	CALL serial_init(glob_rec_kandoouser.cmpy_code,'1','0',p_order_num) 
	LET p_order_num = NULL 

#we need to move this to our localize function
--	DISPLAY 
--		glob_rec_country.state_code_text, 
--		glob_rec_country.post_code_text, 
--		glob_rec_country.state_code_text, 
--		glob_rec_country.post_code_text	
--	TO 
--		sr_prompts[1].*, #<ScreenRecord identifier="sr_prompts" fields="country.state_code_text,country.post_code_text" elements="2"/>
--		sr_prompts[2].* attribute(white) 
	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text attribute(white)

	#------------------------------ WHILE 1
	WHILE header_entry(p_mode) #While step 1 - choose customer etc..
		IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
			SELECT type_code INTO glob_rec_customer.type_code 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.corp_cust_code 
		END IF 

		SELECT acct_mask_code INTO l_mask_code 
		FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = glob_rec_customer.type_code 
		AND acct_mask_code IS NOT NULL 
		IF status = NOTFOUND THEN 
			LET glob_rec_orderhead.acct_override_code = build_mask(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_orderhead.acct_override_code, 
				glob_rec_kandoouser.acct_mask_code) 
		ELSE 
			LET glob_rec_orderhead.acct_override_code =	build_mask(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_orderhead.acct_override_code,
				l_mask_code) 
		END IF 

		IF glob_rec_opparms.show_seg_flag = "Y" THEN 
			LET glob_rec_orderhead.acct_override_code = segment_fill(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_kandoouser.acct_mask_code, 
				glob_rec_orderhead.acct_override_code)
				 
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				CONTINUE WHILE 
			END IF 
		END IF 

		IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN, glob_rec_orderhead.acct_override_code) THEN 
			ERROR kandoomsg2("A",7031,"") #7031Warning: Automatic Invoice Numbering NOT Set up"
		END IF 

		DELETE FROM t_orderpart WHERE 1=1 

		IF glob_rec_orderhead.cond_code IS NOT NULL THEN 
			## INSERT dummy entry in t_orderpart FOR condition
			INSERT INTO t_orderpart (offer_code,offer_qty) VALUES("###",1) 
		END IF
		 
		DELETE FROM t_orderdetl WHERE 1=1 
		INSERT INTO t_orderdetl #only for EDIT... 
		SELECT * FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = glob_rec_orderhead.order_num
		 
		UPDATE t_orderdetl #only for EDIT... 
		SET sched_qty = sched_qty + picked_qty 
		SELECT unique 1 FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_date <= glob_rec_orderhead.order_date 
		AND end_date >= glob_rec_orderhead.order_date
		 
		IF sqlca.sqlcode = 0 THEN 
			IF NOT offer_entry() THEN 
				CONTINUE WHILE 
			END IF 
		END IF 

		OPEN WINDOW E114 with FORM "E114" #Order Line item Information
		 CALL windecoration_e("E114") 

		IF glob_rec_orderhead.cond_code IS NOT NULL THEN 
			SELECT unique 1 FROM condsale 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cond_code = glob_rec_orderhead.cond_code 
			IF sqlca.sqlcode != NOTFOUND THEN 
				IF glob_rec_customer.inv_level_ind != "L" THEN 
					ERROR kandoomsg2("E",7031,"") #7031 Warning: In Nominating a sales condition customer prices will NOT be AT normal pricing level
					
					
				END IF 
			END IF 
		END IF 
		
		#------------------------------ WHILE Step 1.1 - NESTED WHILE
		WHILE lineitem_scan() #While step 1.1 - Create order Line Items 
			IF get_kandoooption_feature_state("EO","BA") THEN 
				SELECT unique 1 FROM t_orderdetl 
				WHERE back_qty != 0 
				IF status = 0 THEN 
					IF NOT validate_backorder() THEN 
						CONTINUE WHILE 
					END IF 
				END IF 
			END IF 
			
			SELECT unique 1 FROM t_orderpart 
			IF sqlca.sqlcode = 0 THEN 
			
				DECLARE c1_orderpart cursor FOR 
				SELECT offer_code FROM t_orderpart 
				WHERE offer_qty > 0 
				AND offer_code != "###" 
				AND offer_code NOT in (select offer_code FROM t_orderdetl 
				WHERE offer_code IS NOT NULL) 
				LET l_retry = FALSE 

				FOREACH c1_orderpart INTO glob_temp_text 					
					IF kandoomsg("E",7091,glob_temp_text) = "Y" THEN #7091 Warning: Offer ABC NOT included in line items
						LET l_retry = TRUE 
						EXIT FOREACH 
					END IF 
					DELETE FROM t_orderpart WHERE offer_code = glob_temp_text 
				END FOREACH 

				IF l_retry THEN 
					CONTINUE WHILE 
				END IF 
				IF NOT check_offer() THEN 
					CONTINUE WHILE 
				END IF 
			END IF 

			OPEN WINDOW E116 with FORM "E116" #Final Summary Page of this order
			 CALL windecoration_e("E116") -- albo kd-755 

			#------------------------------ WHILE Step 1.1.1 - SUMMARY PAGE
			WHILE order_summary(p_mode) #WHILE Step 1.1.1 - SUMMARY PAGE
				IF glob_rec_customer.pay_ind = "5" 
				AND p_mode = "ADD" THEN 
					LET l_hold_order = FALSE 
					LET l_cash_amt = enter_receipt(
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_kandoouser.sign_on_code, 
						glob_rec_orderhead.cust_code , 
						glob_rec_orderhead.total_amt, 
						0, 
						glob_rec_orderhead.order_num, 
						"EO") 
					IF l_cash_amt < glob_rec_orderhead.total_amt THEN 
						ERROR kandoomsg2("E",7093,"") 	#7093 Cash Before Delivery Customer must have receipt
						LET glob_rec_orderhead.hold_code = glob_rec_opparms.cr_hold_code 
						LET l_hold_order = TRUE 
					END IF 
				END IF 

				SELECT unique 1 FROM t_orderpart 
				WHERE disc_ind = "X" 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("E",7015,"") 			#7015 Order must be on Hold before Saving"
					LET glob_rec_orderhead.hold_code = glob_rec_opparms.so_hold_code 
					LET l_hold_order = TRUE 
				ELSE 
					SELECT unique 1 FROM t_orderdetl 
					WHERE back_qty != 0 
					IF sqlca.sqlcode = 0 AND glob_rec_customer.partial_ship_flag = "N" THEN 
						ERROR kandoomsg2("E",7047,"") #7047 Customer does NOT accept partial shipments
						LET glob_rec_orderhead.hold_code = glob_rec_opparms.ps_hold_code 
						LET l_hold_order = TRUE 
					END IF 
				END IF 

				LET l_retry = FALSE 

				MENU " Sales orders" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","E11","menu-Sales_Orders-1") -- albo kd-370 

						IF glob_rec_customer.back_order_flag = "Y" THEN 
							SELECT unique 1 FROM orderdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = glob_rec_orderhead.cust_code 
							AND order_num != glob_rec_orderhead.order_num 
							AND back_qty > 0 
							IF sqlca.sqlcode = NOTFOUND THEN 
								HIDE option "BackOrders" 
							END IF 
						ELSE 
							HIDE option "BackOrders" 
						END IF 
						
						IF glob_rec_customer.pay_ind != "5"	OR p_mode != "ADD" THEN 
							HIDE option "Receipt" 
						END IF 
						
						IF (glob_rec_customer.bal_amt - glob_rec_customer.curr_amt) > 0 THEN 
							ERROR kandoomsg2("E",1166,"") 					#1166 This customer account IS overdue
							NEXT option "Hold" 
						END IF 

					ON ACTION "WEB-HELP"  
						CALL onlinehelp(getmoduleid(),NULL) 

					COMMAND "Save" " Save sales ORDER TO database" 
						MESSAGE kandoomsg2("E",1005,"") 	#1005 Updating Database - pls. wait
						IF p_mode = "ADD" THEN 
							IF insert_order() THEN 
								LET p_order_num = write_order(0) 
								IF p_order_num = -1 THEN 
									LET p_order_num = NULL 
									LET l_retry = TRUE 
								ELSE 
									IF p_order_num = FALSE THEN
										CALL fgl_winmessage("Order Number is NULL/Empty/0","Exit program","ERROR") 
										EXIT PROGRAM 
									END IF 
								END IF 
							ELSE 
								LET l_retry = TRUE 
							END IF 
						
						ELSE 

							LET p_order_num = write_order(0) 
							IF p_order_num = -1 THEN 
								LET p_order_num = NULL 
								#LET p_order_num = glob_rec_orderhead.order_num
								LET l_retry = TRUE 
							ELSE 
								IF p_order_num = FALSE THEN 
									LET p_order_num = glob_rec_orderhead.order_num 
									EXIT MENU 
								END IF 
							END IF 
						END IF 
						
						EXIT MENU 

					COMMAND "Hold" " Hold sales ORDER TO prevent further processing" 
						IF enter_hold() THEN 
						END IF 

					COMMAND "Receipt" " Enter Cash Receipt FOR this order" 
						LET l_cash_amt = enter_receipt(
							glob_rec_kandoouser.cmpy_code, 
							glob_rec_kandoouser.sign_on_code, 
							glob_rec_orderhead.cust_code , 
							glob_rec_orderhead.total_amt, 
							0, 
							glob_rec_orderhead.order_num, 
							"EO") 

						IF l_cash_amt < glob_rec_orderhead.total_amt THEN 
							ERROR kandoomsg2("E",7093,"") 		#7093 Cash Before Delivery Customer must have receipt
							LET glob_rec_orderhead.hold_code = glob_rec_opparms.cr_hold_code 
							LET l_hold_order = TRUE 
						ELSE 
							IF glob_rec_orderhead.hold_code IS NOT NULL	AND glob_rec_orderhead.hold_code = glob_rec_opparms.cr_hold_code THEN 
								LET glob_rec_orderhead.hold_code = NULL 
								LET l_hold_order = FALSE 
							END IF 
						END IF 

					COMMAND "BackOrders" 	" Release previous backorders FOR this customer" 
						OPEN WINDOW E104 with FORM "E104" 
						 CALL windecoration_e("E104") -- albo kd-755 
						
						CALL backorder(glob_rec_orderhead.cust_code) 
						
						CLOSE WINDOW E104 

					COMMAND "Commission"	" Enter sales commission distribution " 
						IF commission() THEN 
						END IF 

					COMMAND KEY("E",Interrupt)"Exit"	" RETURN TO editting order" 
						LET l_retry = TRUE 
						EXIT MENU 

				END MENU 

				DELETE FROM t_cashreceipt WHERE 1=1 

				IF int_flag OR quit_flag THEN 
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
				END IF 
				
				IF l_retry = TRUE THEN 
					LET l_retry = FALSE 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			#------------------------------ END WHILE 3

			CLOSE WINDOW e116 

			IF p_order_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 

		END WHILE 
		#------------------------------ END WHILE 2

		CLOSE WINDOW E114 

		IF p_order_num IS NOT NULL THEN 
			EXIT WHILE 
		END IF
		 
	END WHILE 
	#------------------------------ END WHILE 1

	RETURN p_order_num 
END FUNCTION 
############################################################
# END FUNCTION process_order(p_mode,p_order_num)
############################################################


###########################################################################
# FUNCTION initialize_ord(p_order_num)
#
#
###########################################################################
FUNCTION initialize_ord(p_order_num) 
	DEFINE p_order_num LIKE orderhead.order_num 

	DELETE FROM t_orderdetl 
	DELETE FROM t_saleshare 
	DELETE FROM t_orderpart 
	DELETE FROM t_offerprod 
	DELETE FROM t_proddisc 

	INITIALIZE glob_rec_customer.* TO NULL 

	SELECT * INTO glob_rec_orderhead.* FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = p_order_num 

	IF status = NOTFOUND THEN #not found = new order 
		
		INITIALIZE glob_rec_orderhead.* TO NULL 
		
		LET glob_rec_orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_orderhead.ware_code = "" 
		LET glob_rec_orderhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_orderhead.entry_date = today 
		LET glob_rec_orderhead.rev_date = today 
		LET glob_rec_orderhead.order_date = glob_rec_sales_order_parameter.order_date 
		LET glob_rec_orderhead.ship_date = glob_rec_sales_order_parameter.ship_date 
		LET glob_rec_orderhead.goods_amt = 0 
		LET glob_rec_orderhead.freight_amt = 0 
		LET glob_rec_orderhead.hand_amt = 0 
		LET glob_rec_orderhead.freight_tax_amt = 0 
		LET glob_rec_orderhead.hand_tax_amt = 0 
		LET glob_rec_orderhead.tax_amt = 0 
		LET glob_rec_orderhead.disc_amt = 0 
		LET glob_rec_orderhead.total_amt = 0 
		LET glob_rec_orderhead.cost_amt = 0 
		LET glob_rec_orderhead.status_ind = "U" 
		LET glob_rec_orderhead.line_num = 0 
		LET glob_rec_orderhead.rev_num = 0 
		LET glob_rec_orderhead.prepaid_flag = glob_no_flag 
		LET glob_rec_orderhead.invoice_to_ind = "1" 
		LET glob_rec_orderhead.freight_inv_amt = 0 
		LET glob_rec_orderhead.hand_inv_amt = 0 
		LET glob_rec_sales_order_parameter.suppl_flag = glob_rec_sales_order_parameter.def_suppl_flag 
		LET glob_rec_orderhead.pre_delivery_ind = glob_rec_sales_order_parameter.suppl_flag 
		LET glob_currord_amt = 0 

	ELSE 

		LET glob_currord_amt = glob_rec_orderhead.total_amt
		 
		IF glob_rec_orderhead.pre_delivery_ind IS NOT NULL AND glob_rec_orderhead.pre_delivery_ind = "Y" THEN 
			LET glob_rec_sales_order_parameter.suppl_flag = "Y" 
			LET glob_rec_sales_order_parameter.supp_ware_code = glob_rec_orderhead.ware_code 
		ELSE 
			LET glob_rec_sales_order_parameter.suppl_flag = "" 
			LET glob_rec_sales_order_parameter.supp_ware_code = "" 
		END IF
		 
	END IF
	 
	LET glob_rec_sales_order_parameter.paydetl_flag = glob_rec_sales_order_parameter.def_paydetl_flag 
	LET glob_rec_sales_order_parameter.pick_ind = FALSE
	 
	SELECT base_currency_code 
	INTO glob_rec_sales_order_parameter.base_curr_code 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1"
	 
END FUNCTION
############################################################
# END FUNCTION initialize_ord(p_order_num)
############################################################