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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E53_GLOBALS.4gl" 
###########################################################################
# FUNCTION E53_main()
#
#Front END interface FOR E53a - Order Confirmation
###########################################################################
FUNCTION E53_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E53") 
	CALL init_E5_GROUP()

	OPEN WINDOW E153 with FORM "E153" 
	 CALL windecoration_e("E153")  

	DISPLAY BY NAME glob_rec_arparms.inv_ref1_text 

	CALL cr_inv_tables() 

--	WHILE db_t_inv_head_get_datasource() 
--		SELECT unique 1 FROM t_inv_head 
--		IF sqlca.sqlcode = 0 THEN 
			CALL E53_scan_invoice() 
--			DELETE FROM t_inv_head 
--			DELETE FROM t_inv_detl 
--			CLEAR FORM 
--			DISPLAY BY NAME glob_rec_arparms.inv_ref1_text 
--		ELSE 
--			ERROR kandoomsg2("E",9190,"") #9190 No proposed invoices satisfied the ...
--			SLEEP 2
--		END IF 
--	END WHILE 

	CLOSE WINDOW E153 

END FUNCTION 
###########################################################################
# END FUNCTION E53_main()
###########################################################################


###########################################################################
# FUNCTION db_t_inv_head_get_datasource() 
#
# Front END interface FOR E53a - Order Confirmation
###########################################################################
FUNCTION db_t_inv_head_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where1_text NCHAR(200) 
	DEFINE l_where2_text NCHAR(200) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT  
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_arr_rec_pickhead DYNAMIC ARRAY OF RECORD --array[250] OF RECORD 
		scroll_flag char(1), 
		pick_date LIKE pickhead.pick_date, 
		cust_code LIKE pickhead.cust_code, 
		name_text LIKE customer.name_text, 
		ware_code LIKE pickhead.ware_code, 
		pick_num LIKE pickhead.pick_num, 
		batch_num LIKE pickhead.batch_num, 
		reqd_flag char(1) 
	END RECORD 
	DEFINE l_rowid INTEGER
	DEFINE l_arr_rowid DYNAMIC ARRAY OF INTEGER -- array[250] OF INTEGER
	DEFINE l_hold_code LIKE holdreas.hold_code
		
	IF p_filter THEN		
		ERROR kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT l_where1_text ON 
			order_date, 
			cust_code, 
			ware_code, 
			order_num, 
			batch_num 
		FROM 
			pick_date, 
			cust_code, 
			ware_code, 
			pick_num, 
			batch_num 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E53","construct-order_date-1") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			LET l_where1_text = " 1=1 "
		END IF
	ELSE 
		LET l_where1_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("E",1002,"") 		#1002 Serching database - so wait
	LET l_where2_text = l_where1_text 
	FOR i = 1 TO (length(l_where2_text)-4) 
		IF l_where2_text[i,i+4] = "order" THEN 
			LET l_where2_text[i,i+4] = " pick" #uses it like LET l_where2_text[i,i+4] = "pick" or "pick " 
		END IF 
		
		IF l_where1_text[i,i+4] = "batch" THEN 
			IF i = 1 THEN 
				LET l_where1_text = " 1=1 " 
			ELSE 
				LET l_where1_text = l_where1_text[1,i-1]," 1=1 " 
			END IF 
		END IF 
	END FOR 

	CALL load_tables(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_kandoouser.sign_on_code,
		TRUE,
		l_where1_text,
		l_where2_text)
	 
	LET l_query_text = 
		"SELECT rowid,", 
		"pick_date,", 
		"cust_code,", 
		"ware_code,", 
		"pick_num,", 
		"batch_num,", 
		"hold_code ", 
		"FROM t_inv_head ", 
		"WHERE ",l_where2_text clipped," ", 
		"ORDER BY pick_date, pick_num " 
	PREPARE s_pickhead FROM l_query_text 
	
	LET l_idx = 0 
	DECLARE c_pickhead cursor FOR s_pickhead 
	
	FOREACH c_pickhead INTO 
		l_rowid, 
		l_rec_pickhead.pick_date, 
		l_rec_pickhead.cust_code, 
		l_rec_pickhead.ware_code, 
		l_rec_pickhead.pick_num, 
		l_rec_pickhead.batch_num, 
		l_hold_code
		 
		LET l_idx = l_idx + 1 
		LET l_arr_rowid[l_idx] = l_rowid 
		LET l_arr_rec_pickhead[l_idx].pick_date = l_rec_pickhead.pick_date 
		LET l_arr_rec_pickhead[l_idx].cust_code = l_rec_pickhead.cust_code 
		LET l_arr_rec_pickhead[l_idx].ware_code = l_rec_pickhead.ware_code 
		LET l_arr_rec_pickhead[l_idx].pick_num = l_rec_pickhead.pick_num 
		LET l_arr_rec_pickhead[l_idx].batch_num = l_rec_pickhead.batch_num
		 
		SELECT name_text 
		INTO l_arr_rec_pickhead[l_idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_pickhead.cust_code
		 
		IF l_hold_code IS NULL THEN 
			LET l_arr_rec_pickhead[l_idx].reqd_flag = "*" 
		ELSE 
			LET l_arr_rec_pickhead[l_idx].reqd_flag = NULL 
		END IF

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	RETURN l_arr_rec_pickhead , l_arr_rowid
END FUNCTION 
###########################################################################
# END FUNCTION db_t_inv_head_get_datasource() 
###########################################################################


###########################################################################
# FUNCTION E53_scan_invoice() 
#
# 
###########################################################################
FUNCTION E53_scan_invoice()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_arr_rec_pickhead DYNAMIC ARRAY OF RECORD --array[250] OF RECORD 
		scroll_flag char(1), 
		pick_date LIKE pickhead.pick_date, 
		cust_code LIKE pickhead.cust_code, 
		name_text LIKE customer.name_text, 
		ware_code LIKE pickhead.ware_code, 
		pick_num LIKE pickhead.pick_num, 
		batch_num LIKE pickhead.batch_num, 
		reqd_flag char(1) 
	END RECORD 
	DEFINE l_customer_name_text LIKE customer.name_text
	DEFINE l_rowid INTEGER 
	DEFINE l_arr_rowid DYNAMIC ARRAY OF INTEGER -- array[250] OF INTEGER 
	DEFINE l_hold_code LIKE holdreas.hold_code 
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_temp_text char(100) 
	DEFINE l_event_text char(20) 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_quit char(1) 
	DEFINE l_rec_cnt SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_event_num SMALLINT 
	DEFINE l_inv_ind SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_idx2 SMALLINT 
	DEFINE l_conf_cnt SMALLINT 
	DEFINE l_act_cnt SMALLINT 
	DEFINE h SMALLINT
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE x SMALLINT
	DEFINE y SMALLINT
	DEFINE l_err_message char(60) 
	
	CALL db_t_inv_head_get_datasource(FALSE) RETURNING l_arr_rec_pickhead, l_arr_rowid

	MESSAGE kandoomsg2("E",1033,"") 	#1033" ENTER TO View/Amend Order; F2 Cancel Pick Slip; F6 Conf
	INPUT ARRAY l_arr_rec_pickhead WITHOUT DEFAULTS FROM sr_pickhead.* ATTRIBUTE(UNBUFFERED,delete row = false, insert row = false, append row = false,auto append = false)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E53","input-l_arr_rec_pickhead-1") 
 			CALL dialog.setActionHidden("ACCEPT",TRUE)
 			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_pickhead.getSize())
 			CALL dialog.setActionHidden("CANCEL PICK SLIP",NOT l_arr_rec_pickhead.getSize())
 			CALL dialog.setActionHidden("CONFIRM INVOICE" ,NOT l_arr_rec_pickhead.getSize())
 			CALL dialog.setActionHidden("LINE TOGGLE",NOT l_arr_rec_pickhead.getSize())
 			CALL dialog.setActionHidden("BULK TOGGLE",NOT l_arr_rec_pickhead.getSize()) 			 			 			
 
		BEFORE ROW 
			LET l_idx = arr_curr() 
--		BEFORE FIELD scroll_flag 
			CALL order_lines(l_arr_rowid[l_idx],"DISP") 
			LET l_scroll_flag = l_arr_rec_pickhead[l_idx].scroll_flag 

 
		ON ACTION "WEB-HELP"  
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_pickhead.clear()
			CALL l_arr_rowid.clear()
			CALL db_t_inv_head_get_datasource(TRUE) RETURNING l_arr_rec_pickhead, l_arr_rowid
		
		ON ACTION "REFRESH"
			 CALL windecoration_e("E153")
			CALL l_arr_rowid.clear()
			CALL l_arr_rec_pickhead.clear()
			CALL db_t_inv_head_get_datasource(FALSE) RETURNING l_arr_rec_pickhead, l_arr_rowid


		ON ACTION ("EDIT","DOUBLECLICK")	--BEFORE FIELD pick_date
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_pickhead.getSize()) THEN 
				IF l_arr_rec_pickhead[l_idx].reqd_flag IS NOT NULL THEN 
					CALL order_lines(l_arr_rowid[l_idx],"EDIT") 
				END IF 
			END IF
			--NEXT FIELD scroll_flag 

		ON ACTION "CANCEL PICK SLIP" --ON KEY (f2) 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_pickhead.getSize()) THEN
				IF l_arr_rec_pickhead[l_idx].reqd_flag IS NOT NULL THEN 
	
					DECLARE c2_pickhead cursor FOR 
					SELECT * FROM pickhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = l_arr_rec_pickhead[l_idx].ware_code 
					AND pick_num = l_arr_rec_pickhead[l_idx].pick_num 
					AND status_ind = "0" 
					AND con_status_ind = "0" 
					OPEN c2_pickhead 
					FETCH c2_pickhead 
	
					IF status = NOTFOUND THEN 					
						ERROR kandoomsg2("E",9265,"") #9265 Cannot cancel pre-delivery
						NEXT FIELD scroll_flag 
					END IF 
	
					SELECT invoice_ind INTO l_inv_ind 
					FROM t_inv_head 
					WHERE rowid = l_arr_rowid[l_idx] 
	
					CASE l_inv_ind 
						WHEN 1 
							IF promptTF("",kandoomsg2("E",8020,""),1)	THEN	#8020 Confirm TO reject picking slip
							 
								## Begin / COMMIT WORK required b/c reject_pickslip
								## assumes it IS called within a transaction
								GOTO bypass 
								LABEL recovery: 
								IF error_recover(l_err_message,status) != 'Y' THEN 
									EXIT INPUT 
								END IF 
								LABEL bypass: 
								BEGIN WORK 
									IF reject_pickslip(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rec_pickhead[l_idx].ware_code, 
									l_arr_rec_pickhead[l_idx].pick_num) < 0 THEN 
										LET l_err_message = 'e53 - pickslip UPDATE failed' 
										GOTO recovery 
									ELSE 
										LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
									END IF 
								COMMIT WORK 
							END IF 
	
						WHEN 3 
							ERROR kandoomsg2("E",7049,"") #7049 Cannot cancel pre-delivery
	
						OTHERWISE 
							IF promptTF("",kandoomsg2("E",8021,""),1)	THEN		#8021 Confirm TO Hold sales ORDER
								DECLARE c2_inv_detl cursor FOR 
								SELECT order_num FROM t_inv_detl 
								WHERE inv_rowid = l_arr_rowid[l_idx] 
								GROUP BY order_num 
								FOREACH c2_inv_detl INTO l_order_num 
									UPDATE orderhead 
									SET hold_code = glob_rec_opparms.cf_hold_code 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND order_num = l_order_num 
									CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_order_num,28, 
									glob_rec_opparms.cf_hold_code,"") 
								END FOREACH 
								LET l_arr_rec_pickhead[l_idx].reqd_flag = NULL 
							END IF 
					END CASE 
				END IF 
				NEXT FIELD scroll_flag 
			END IF
			
		ON ACTION "CONFIRM INVOICE" --ON KEY (f6)
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_pickhead.getSize()) THEN 
				LET l_quit = 'N' 
				IF l_arr_rec_pickhead[l_idx].reqd_flag IS NOT NULL AND check_serial_products(l_arr_rowid[l_idx]) THEN 
					LET l_quit = enter_serial_codes(l_arr_rowid[l_idx], 
					l_arr_rec_pickhead[l_idx].cust_code, 
					l_arr_rec_pickhead[l_idx].ware_code, 
					l_arr_rec_pickhead[l_idx].pick_num) 
				END IF 
	
				IF l_quit = 'N' AND l_arr_rec_pickhead[l_idx].reqd_flag IS NOT NULL THEN 
					SELECT invoice_ind INTO l_inv_ind 
					FROM t_inv_head 
					WHERE rowid = l_arr_rowid[l_idx] 
	
					CASE l_inv_ind 
						WHEN 1 
							OPEN WINDOW E155 with FORM "E155" 
							 CALL windecoration_e("E155") -- albo kd-755 						
							ERROR kandoomsg2("E",1048,"") #1048 Inventory Invoice Details - ESC TO Continue
	
							IF enter_despatch(l_arr_rowid[l_idx]) THEN 
								ERROR kandoomsg2("E",1005,"") 
								LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
	
								IF l_inv_num > 0 THEN 								
									MESSAGE kandoomsg2("E",7048,l_inv_num) #7048 Successful generation of invoice #
									LET l_event_num = 75 ##manual inv 
									LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
								END IF 
	
							END IF 
							CLOSE WINDOW E155 
	
						WHEN 2 
							OPEN WINDOW E155 with FORM "E155" 
							 CALL windecoration_e("E155") -- albo kd-755 						
							MESSAGE kandoomsg2("E",1049,"") #1049 Non-Inventory Invoice Details - ESC TO Continue
	
							IF enter_despatch(l_arr_rowid[l_idx]) THEN 
								ERROR kandoomsg2("E",1005,"") 
								LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
								IF l_inv_num > 0 THEN 								
									MESSAGE kandoomsg2("E",7048,l_inv_num) #7048 Successful generation of invoice #
									LET l_event_num = 75 ##manual inv 
									LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
								END IF 
							END IF 
	
							CLOSE WINDOW E155 
	
						WHEN 3 
							OPEN WINDOW E155 with FORM "E155" 
							 CALL windecoration_e("E155") -- albo kd-755 						
							MESSAGE kandoomsg2("E",1050,"") #1050 Pre-delivery Invoice Details - ESC TO Continue
	
							IF enter_despatch(l_arr_rowid[l_idx]) THEN 
								ERROR kandoomsg2("E",1005,"") 
								LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
								IF l_inv_num > 0 THEN 								
									MESSAGE kandoomsg2("E",7048,l_inv_num) #7048 Successful generation of invoice #
									LET l_event_num = 85 ##manual predel inv 
									LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
								END IF 
							END IF 
	
							CLOSE WINDOW E155 
	
						WHEN 4 
							OPEN WINDOW E171 with FORM "E171" 
							 CALL windecoration_e("E171") -- albo kd-755 
							
							MESSAGE kandoomsg2("E",1051,"")#1051 Stock RETURN Credit Note - ESC TO Continue 
							IF enter_despatch(l_arr_rowid[l_idx]) THEN 
								ERROR kandoomsg2("E",1005,"") 
								LET l_inv_num =generate_cred(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
	
								IF l_inv_num > 0 THEN 
									
									MESSAGE kandoomsg2("E",7061,l_inv_num) #7061 Successful generation of credit note #
									LET l_event_num = 65 ##manual credit 
									LET l_arr_rec_pickhead[l_idx].reqd_flag = NULL 
								END IF 
							END IF 
							CLOSE WINDOW E171 
					END CASE 
	
					IF l_arr_rec_pickhead[l_idx].reqd_flag IS NULL THEN 
						IF l_arr_rec_pickhead[l_idx].scroll_flag IS NOT NULL THEN 
							LET l_conf_cnt = l_conf_cnt - 1 
							LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
						END IF 
						DECLARE c1_inv_detl cursor FOR 
						SELECT order_num FROM t_inv_detl 
						WHERE inv_rowid = l_arr_rowid[l_idx] 
						GROUP BY order_num 
	
						FOREACH c1_inv_detl INTO l_order_num 
							CALL insert_log(
								glob_rec_kandoouser.cmpy_code,
								glob_rec_kandoouser.sign_on_code,
								l_order_num,l_event_num, 
								l_inv_num,"") 
						END FOREACH 
					END IF 
				END IF 
	
				NEXT FIELD scroll_flag 
			END IF
			
		ON ACTION "LINE TOGGLE" --ON KEY (f8)
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_pickhead.getSize()) THEN 
				IF check_serial_products(l_arr_rowid[l_idx]) THEN 
					ERROR kandoomsg2("I",9290,"") 	#9290 Only manual confirm (F6) can be used FOR Orders with S
					NEXT FIELD scroll_flag 
				END IF 

				IF l_arr_rec_pickhead[l_idx].reqd_flag IS NULL THEN 
					IF l_arr_rec_pickhead[l_idx].scroll_flag IS NOT NULL THEN 
						LET l_conf_cnt = l_conf_cnt - 1 
						LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
					END IF 
				ELSE 
					IF l_arr_rec_pickhead[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_pickhead[l_idx].scroll_flag = "*" 
						LET l_conf_cnt = l_conf_cnt + 1 
					ELSE 
						LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
						LET l_conf_cnt = l_conf_cnt - 1 
					END IF 
				END IF 
	
				NEXT FIELD scroll_flag 
			END IF
			
		ON ACTION "BULK TOGGLE" --ON KEY (f10)
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_pickhead.getSize()) THEN 

				FOR i = 1 TO arr_count() 
					IF l_arr_rec_pickhead[i].reqd_flag IS NULL OR check_serial_products(l_arr_rowid[i]) THEN 

						IF l_arr_rec_pickhead[i].scroll_flag IS NOT NULL THEN 
							LET l_conf_cnt = l_conf_cnt - 1 
							LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
						END IF 

					ELSE 

						IF l_arr_rec_pickhead[i].scroll_flag IS NULL THEN 
							LET l_arr_rec_pickhead[i].scroll_flag = "*" 
							LET l_conf_cnt = l_conf_cnt + 1 
						ELSE 
							LET l_arr_rec_pickhead[i].scroll_flag = NULL 
							LET l_conf_cnt = l_conf_cnt - 1 
						END IF 

					END IF 
				END FOR 
				
				LET h = arr_curr() 
				LET x = scr_line() 
				LET j = 8 - x 
				LET y = (h - x) + 1 
	 
				NEXT FIELD scroll_flag 
			END IF


		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_conf_cnt > 0 THEN 
					OPEN WINDOW E453 with FORM "E453" 
					 CALL windecoration_e("E453") 

					IF enter_bulk_despatch(l_conf_cnt) THEN 
						MESSAGE kandoomsg2("E",1005,"") 				#1005 Updating database;  Please wait.

						LET glob_rec_rpt_selector.rpt_note = 'bulk CREATE summary' 
						LET glob_rec_rpt_selector.rpt_header = glob_rec_rpt_selector.rpt_note

						#------------------------------------------------------------
						LET l_rpt_idx = rpt_start(getmoduleid(),"E53_rpt_lit_bulk_sum","N/A", RPT_SHOW_RMS_DIALOG)
						IF l_rpt_idx = 0 THEN #User pressed CANCEL
							RETURN FALSE
						END IF	
						START REPORT E53_rpt_lit_bulk_sum TO rpt_get_report_file_with_path2(l_rpt_idx)
						WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
						TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
						BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
						LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
						RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
						#------------------------------------------------------------
						

						LET l_act_cnt = 0 

						FOR l_idx = 1 TO arr_count() 
							IF l_arr_rec_pickhead[l_idx].scroll_flag IS NOT NULL AND l_arr_rec_pickhead[l_idx].reqd_flag IS NOT NULL THEN 
								SELECT invoice_ind INTO l_inv_ind 
								FROM t_inv_head 
								WHERE rowid = l_arr_rowid[l_idx] 

								CASE l_inv_ind 
									WHEN 1 
										LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
										IF l_inv_num > 0 THEN 
											LET l_event_num = 75 ##manual inv 
											LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
										END IF 
									WHEN 2 
										LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
										IF l_inv_num > 0 THEN 
											LET l_event_num = 75 ##manual inv 
											LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
										END IF 
									WHEN 3 
										LET l_inv_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
										IF l_inv_num > 0 THEN 
											LET l_event_num = 85 ##manual predel inv 
											LET l_arr_rec_pickhead[l_idx].reqd_flag = "" 
										END IF 
									WHEN 4 
										LET l_inv_num =generate_cred(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rowid[l_idx],TRUE) 
										IF l_inv_num > 0 THEN 
											LET l_event_num = 65 ##manual credit 
											LET l_arr_rec_pickhead[l_idx].reqd_flag = NULL 
										END IF 
								END CASE 

								IF l_arr_rec_pickhead[l_idx].reqd_flag IS NULL THEN 
									LET l_act_cnt = l_act_cnt + 1
	
									#---------------------------------------------------------
									OUTPUT TO REPORT E53_rpt_lit_bulk_sum(l_rpt_idx,
									l_arr_rec_pickhead[l_idx].*,l_inv_num) 
									#---------------------------------------------------------
									
									 
									DECLARE c3_inv_detl cursor FOR 
									SELECT order_num FROM t_inv_detl 
									WHERE inv_rowid = l_arr_rowid[l_idx] 
									GROUP BY order_num 
									FOREACH c3_inv_detl INTO l_order_num 
										CALL insert_log(
											glob_rec_kandoouser.cmpy_code,
											glob_rec_kandoouser.sign_on_code,
											l_order_num, 
											l_event_num, 
											l_inv_num,
											"") 
									END FOREACH 
								END IF 
							END IF 
						END FOR 

						#------------------------------------------------------------
						FINISH REPORT E53_rpt_lit_bulk_sum
						CALL rpt_finish("E53_rpt_lit_bulk_sum")
						#------------------------------------------------------------
						 
						CLOSE WINDOW E453 

						--                  OPEN WINDOW word AT 11,22 with 4 rows, 41 columns  -- albo  KD-755
						--                     ATTRIBUTE(border,white,menu line 3)
						 CALL windecoration_e("E151")  
						MESSAGE kandoomsg2("E",1181,l_act_cnt) 		#1181   Invoices created.
						MENU " SELECT option " 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","E53","menu-SELECT_option-1") -- albo kd-502
 
							ON ACTION "WEB-HELP" -- albo kd-370 
								CALL onlinehelp(getmoduleid(),null) 
								
							ON ACTION "PRINT" --COMMAND KEY ("P",f11) "Print" " Print Invoice summary" 
								CALL run_prog("URS.4gi","","","","") 
								EXIT MENU 
								
							ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
								EXIT MENU 

						END MENU 
						--                  CLOSE WINDOW word  -- albo  KD-755
					ELSE 
						CLOSE WINDOW E453 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

	END INPUT 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION E53_scan_invoice() 
###########################################################################


###########################################################################
# FUNCTION order_lines(p_rowid,p_mode) 
#
# 
###########################################################################
FUNCTION order_lines(p_rowid,p_mode) 
	DEFINE p_rowid INTEGER 
	DEFINE p_mode char(4) 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD 
		order_flag char(1), 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		last_inv_date LIKE orderhead.last_inv_date, 
		status_ind LIKE orderhead.status_ind 
	END RECORD 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	DECLARE c_orderhead cursor FOR 
	SELECT 
		order_num, 
		order_date 
	FROM t_inv_detl 
	WHERE inv_rowid = p_rowid 
	GROUP BY 1,2 
	ORDER BY 1,2 
	
	FOREACH c_orderhead INTO 
		l_rec_orderhead.order_num, 
		l_rec_orderhead.order_date 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderhead[l_idx].order_num = l_rec_orderhead.order_num 
		LET l_arr_rec_orderhead[l_idx].order_date = l_rec_orderhead.order_date 

		SELECT 
			ord_text, 
			status_ind, 
			last_inv_num, 
			last_inv_date 
		INTO 
			l_arr_rec_orderhead[l_idx].ord_text, 
			l_arr_rec_orderhead[l_idx].status_ind, 
			l_arr_rec_orderhead[l_idx].last_inv_num, 
			l_arr_rec_orderhead[l_idx].last_inv_date 
		FROM orderhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = l_rec_orderhead.order_num 

		IF l_arr_rec_orderhead[l_idx].last_inv_num = 0 THEN 
			LET l_arr_rec_orderhead[l_idx].last_inv_num = "" 
			LET l_arr_rec_orderhead[l_idx].last_inv_date = "" 
		END IF 

	END FOREACH 
	IF p_mode = "DISP" THEN 
		FOR l_idx = 1 TO 3 
			IF l_arr_rec_orderhead[l_idx].order_num > 0 THEN 
				DISPLAY l_arr_rec_orderhead[l_idx].* TO sr_orderhead[l_idx].* 
			ELSE 
				CLEAR sr_orderhead[l_idx].* 
			END IF 
		END FOR 
	ELSE 

		DISPLAY ARRAY l_arr_rec_orderhead TO sr_orderhead.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","E53","input-l_arr_rec_orderhead-1") 
 				CALL dialog.setActionHidden("ACCEPT",TRUE)
 				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_orderhead.getSize())
 				
			ON ACTION "WEB-HELP"  
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION ("EDIT","DOUBLECLICK") 
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderhead.getSize()) THEN
					OPEN WINDOW E154 with FORM "E154" 
					 CALL windecoration_e("E154") -- albo kd-755 
					ERROR kandoomsg2("E",1047,"") 
					DISPLAY l_arr_rec_orderhead[l_idx].order_num TO order_num 
					DISPLAY l_arr_rec_orderhead[l_idx].order_date TO order_date
	
					CALL edit_order(p_rowid,l_arr_rec_orderhead[l_idx].order_num) 
					CLOSE WINDOW E154 
				END IF 

		END DISPLAY 

	END IF 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION order_lines(p_rowid,p_mode) 
###########################################################################


###########################################################################
# FUNCTION edit_order(l_rowid,l_order_num)
#
# 
###########################################################################
FUNCTION edit_order(l_rowid,l_order_num) 
	DEFINE l_rowid INTEGER 
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		inv_qty LIKE orderdetl.inv_qty, 
		picked_qty LIKE orderdetl.picked_qty, 
		sched_qty LIKE orderdetl.sched_qty, 
		order_qty LIKE orderdetl.order_qty 
	END RECORD 
	DEFINE l_arr_rec_orderdetl_2 DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		desc_text LIKE orderdetl.desc_text, 
		prod_desc_text LIKE product.desc_text, 
		prod_desc2_text LIKE product.desc_text 
	END RECORD 
	DEFINE l_arr_reduce_inv_flag DYNAMIC ARRAY OF CHAR --array[300] OF char(1) 
	DEFINE l_picked_qty LIKE orderdetl.picked_qty 
	DEFINE l_maxship_qty LIKE orderdetl.picked_qty 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	DECLARE c_pickdetl cursor FOR 
	SELECT 
		order_line_num, 
		picked_qty 
	FROM t_inv_detl 
	WHERE inv_rowid = l_rowid 
	AND order_num = l_order_num 
	ORDER BY order_line_num 
	
	FOREACH c_pickdetl INTO 
		l_rec_orderdetl.line_num, 
		l_picked_qty 

		SELECT * INTO l_rec_orderdetl.* 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = l_order_num 
		AND line_num = l_rec_orderdetl.line_num 

		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_orderdetl.part_code 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl.line_num 
		LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl.part_code 
		LET l_arr_rec_orderdetl[l_idx].inv_qty = l_rec_orderdetl.inv_qty 
		LET l_arr_rec_orderdetl[l_idx].picked_qty = l_picked_qty 
		LET l_arr_rec_orderdetl[l_idx].sched_qty = l_rec_orderdetl.order_qty 
		- l_rec_orderdetl.inv_qty 
		- l_picked_qty 
		LET l_arr_rec_orderdetl[l_idx].order_qty = l_rec_orderdetl.order_qty 
		LET l_arr_rec_orderdetl_2[l_idx].desc_text = l_rec_orderdetl.desc_text 
		LET l_arr_rec_orderdetl_2[l_idx].prod_desc_text = l_rec_product.desc_text 
		LET l_arr_rec_orderdetl_2[l_idx].prod_desc2_text = l_rec_product.desc2_text 
	END FOREACH 
	
	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = l_rec_orderdetl.cust_code 
	
	IF l_rec_customer.partial_ship_flag != "Y" THEN 
		LET l_rec_customer.partial_ship_flag = "*" 
	ELSE 
		LET l_rec_customer.partial_ship_flag = "" 
	END IF 

	IF l_rec_orderdetl.status_ind = "1" THEN 
		LET l_rec_orderdetl.status_ind = "*" 
	ELSE 
		LET l_rec_orderdetl.status_ind = "" 
	END IF 
	
	DISPLAY l_rec_customer.cust_code TO cust_code
	DISPLAY l_rec_customer.name_text TO name_text
	DISPLAY l_rec_customer.partial_ship_flag TO partial_ship_flag 
	DISPLAY l_rec_orderdetl.status_ind TO status_ind
 
	INPUT ARRAY l_arr_rec_orderdetl WITHOUT DEFAULTS FROM sr_orderdetl.* ATTRIBUTE(UNBUFFERED,auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E53","input-l_arr_rec_orderdetl-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			NEXT FIELD scroll_flag 

			DISPLAY BY NAME 
				l_arr_rec_orderdetl_2[l_idx].prod_desc_text, 
				l_arr_rec_orderdetl_2[l_idx].prod_desc2_text 

			IF l_arr_rec_orderdetl_2[l_idx].desc_text = l_arr_rec_orderdetl_2[l_idx].prod_desc_text THEN 
				DISPLAY '' TO desc_text 
			ELSE 
				DISPLAY BY NAME l_arr_rec_orderdetl_2[l_idx].desc_text 
			END IF 

		BEFORE FIELD picked_qty 
			CASE 
				WHEN l_rec_customer.partial_ship_flag IS NOT NULL 
					ERROR kandoomsg2("E",9187,"") 		#9187" Incomplete shipments are NOT permitted "
					NEXT FIELD scroll_flag 
					
				WHEN l_rec_orderdetl.status_ind IS NOT NULL 
					ERROR kandoomsg2("E",9188,"") 		#9188" pre-delivered Lines cannot be changed
					NEXT FIELD scroll_flag 
					
				OTHERWISE 
					LET l_picked_qty = l_arr_rec_orderdetl[l_idx].picked_qty 
					
					SELECT picked_qty 
					INTO l_maxship_qty 
					FROM t_inv_detl 
					WHERE inv_rowid = l_rowid 
					AND order_num = l_order_num 
					AND order_line_num = l_arr_rec_orderdetl[l_idx].line_num 
					IF sqlca.sqlcode = NOTFOUND THEN 
						NEXT FIELD scroll_flag 
					END IF 
			END CASE 

		AFTER FIELD picked_qty 
			CASE 
				WHEN l_arr_rec_orderdetl[l_idx].picked_qty IS NULL 
					ERROR kandoomsg2("E",9184,"") 					#9184" Quantity of line TO be shipped must be entered "
					LET l_arr_rec_orderdetl[l_idx].picked_qty = l_picked_qty 
					NEXT FIELD picked_qty 
				
				WHEN l_arr_rec_orderdetl[l_idx].picked_qty < 0 
					IF l_maxship_qty > 0 THEN 
						ERROR kandoomsg2("E",9185,"") 						#9185" Quantity of line TO be shipped must be > 0 "
						LET l_arr_rec_orderdetl[l_idx].picked_qty = l_picked_qty 
						NEXT FIELD picked_qty 
					ELSE 
						IF l_arr_rec_orderdetl[l_idx].picked_qty < l_maxship_qty THEN 							
							ERROR kandoomsg2("E",9186,"") #9186" Cannot RETURN more stock than scheduled"
							LET l_arr_rec_orderdetl[l_idx].picked_qty = l_picked_qty 
							NEXT FIELD picked_qty 
						END IF 
					END IF 
				
				WHEN l_arr_rec_orderdetl[l_idx].picked_qty > l_maxship_qty 
					ERROR kandoomsg2("E",9189,l_maxship_qty)	#9189" Shipment quantity must NOT exceed scheduled.
					LET l_arr_rec_orderdetl[l_idx].picked_qty = l_picked_qty 
					NEXT FIELD picked_qty 
				
				OTHERWISE 
					LET l_arr_rec_orderdetl[l_idx].sched_qty = l_arr_rec_orderdetl[l_idx].order_qty 
					- l_arr_rec_orderdetl[l_idx].inv_qty 
					- l_arr_rec_orderdetl[l_idx].picked_qty 
					IF l_rec_customer.back_order_flag = "N" 
					AND l_arr_rec_orderdetl[l_idx].picked_qty < l_maxship_qty THEN 
						IF promptTF("Back Ordering",kandoomsg2("E",8008,""),1) THEN  	#8008 Customer does NOT allow back ordering. Confirm
							LET l_arr_reduce_inv_flag[l_idx] = 'Y' 
						ELSE 
							LET l_arr_reduce_inv_flag[l_idx] = 'N' 
						END IF 
					ELSE 
						LET l_arr_reduce_inv_flag[l_idx] = 'N' 
					END IF 
					NEXT FIELD scroll_flag 
			END CASE 
		AFTER INPUT 

			IF not(int_flag OR quit_flag) THEN 
				FOR l_idx = 1 TO arr_count() 
					UPDATE t_inv_detl 
					SET picked_qty = l_arr_rec_orderdetl[l_idx].picked_qty, 
					sold_qty = l_arr_rec_orderdetl[l_idx].picked_qty, 
					reduce_inv_flag = l_arr_reduce_inv_flag[l_idx] 

					WHERE inv_rowid = l_rowid 
					AND order_num = l_order_num 
					AND order_line_num = l_arr_rec_orderdetl[l_idx].line_num 
				END FOR 
			END IF 

	END INPUT 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION edit_order(l_rowid,l_order_num)
###########################################################################

###########################################################################
# FUNCTION enter_serial_codes(l_rowid, l_cust_code, l_ware_code, l_pick_num )
#
# 
###########################################################################
FUNCTION enter_serial_codes(l_rowid, l_cust_code, l_ware_code, l_pick_num ) 
	DEFINE l_rowid INTEGER 
	DEFINE l_cust_code LIKE pickhead.cust_code 
	DEFINE l_ware_code LIKE pickhead.ware_code 
	DEFINE l_pick_num LIKE pickhead.pick_num 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_arr_rec_serial_prod DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		line_num INTEGER, 
		part_code LIKE orderdetl.part_code, 
		picked_qty LIKE orderdetl.inv_qty, 
		serial_qty LIKE orderdetl.inv_qty 
	END RECORD 
	DEFINE l_arr_rec_ser_prod2 DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		prod_desc_text LIKE product.desc_text, 
		prod_desc2_text LIKE product.desc_text, 
		desc_text LIKE orderdetl.desc_text 
	END RECORD 
	DEFINE l_rec_serial_prod RECORD 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		line_num LIKE orderdetl.line_num, 
		part_code LIKE orderdetl.part_code, 
		cust_code LIKE orderdetl.cust_code, 
		picked_qty LIKE orderdetl.inv_qty 
	END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_customer_name_text LIKE customer.name_text 
	DEFINE l_quit char(1) 
	DEFINE l_err_message char(60) 
	DEFINE l_temp_text char(100) 
	DEFINE l_rec_cnt SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx2 SMALLINT
	DEFINE l_conf_cnt SMALLINT 
	DEFINE l_errmsg STRING #error message string
	LET l_quit = 'N' 

	#   LET l_err_message = "E53 - lock pickhead "
	#   LET l_temp_text = "SELECT * FROM pickhead  ",
	#                      "WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
	#                        "AND pick_num = ? ",
	#                      "  FOR UPDATE"
	#   PREPARE s5_pickhead FROM l_temp_text
	#   DECLARE c5_pickhead CURSOR FOR s5_pickhead
	GOTO bypass 
	LABEL recovery1: 
	IF error_recover(l_err_message,status) != 'Y' THEN 
		RETURN 'Y' 
	END IF 
	LABEL bypass: 
	#      OPEN c5_pickhead using l_pick_num
	#      FETCH c5_pickhead INTO l_rec_pickhead.*

	DECLARE c5_inv_detl cursor FOR 
	SELECT 
		t_inv_detl.order_num, 
		t_inv_detl.picked_qty, 
		t_inv_detl.order_date, 
		product.*, 
		t_inv_detl.order_line_num 
	FROM t_inv_detl, product 
	WHERE t_inv_detl.inv_rowid = l_rowid 
	AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND product.part_code = t_inv_detl.part_code 
	AND product.serial_flag = 'Y' 

	FOREACH c5_inv_detl INTO 
			l_rec_serial_prod.order_num, 
			l_rec_serial_prod.picked_qty, 
			l_rec_serial_prod.order_date, 
			l_rec_product.*, 
			l_rec_serial_prod.line_num 

		LET l_idx2 = l_idx2 + 1 
		LET l_arr_rec_serial_prod[l_idx2].order_num = l_rec_serial_prod.order_num 
		LET l_arr_rec_serial_prod[l_idx2].order_date = l_rec_serial_prod.order_date 
		LET l_arr_rec_serial_prod[l_idx2].line_num = l_rec_serial_prod.line_num 
		LET l_arr_rec_serial_prod[l_idx2].part_code = l_rec_product.part_code 
		LET l_arr_rec_serial_prod[l_idx2].picked_qty = l_rec_serial_prod.picked_qty 
		LET l_arr_rec_ser_prod2[l_idx2].prod_desc_text = l_rec_product.desc_text 
		LET l_arr_rec_ser_prod2[l_idx2].prod_desc2_text = l_rec_product.desc2_text 

		SELECT desc_text INTO l_arr_rec_ser_prod2[l_idx2].desc_text 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = l_rec_serial_prod.order_num 
		AND line_num = l_rec_serial_prod.line_num 
		AND cust_code = l_cust_code 

		IF l_arr_rec_ser_prod2[l_idx2].desc_text	= l_arr_rec_ser_prod2[l_idx2].prod_desc_text THEN 
			LET l_arr_rec_ser_prod2[l_idx2].desc_text = NULL 
		END IF 
		
		CALL serial_init(glob_rec_kandoouser.cmpy_code,"1","0",l_arr_rec_serial_prod[l_idx2].order_num) 
		LET l_arr_rec_serial_prod[l_idx2].serial_qty =	serial_count(l_arr_rec_serial_prod[l_idx2].part_code,l_ware_code) 

		IF l_idx2 = 100 THEN #????? was this once a static array ?
			EXIT FOREACH 
		END IF 
	END FOREACH 

	OPTIONS INSERT KEY f35, 
	DELETE KEY f36 

--	CALL set_count(l_idx2) 
	LET l_rec_cnt = l_idx2 

	OPEN WINDOW E174 with FORM "E174" attribute(border) 

	SELECT name_text INTO l_customer_name_text 
	FROM customer 
	WHERE cust_code = l_cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	DISPLAY l_cust_code TO cust_code 
	DISPLAY l_customer_name_text TO name_text 
	DISPLAY l_pick_num TO pick_num 

	MESSAGE kandoomsg2("E",1168,"") #1168 ENTER TO View/Amend Serial Codes.
	
	INPUT ARRAY l_arr_rec_serial_prod WITHOUT DEFAULTS FROM sr_serial_prod.* ATTRIBUTE(UNBUFFERED,insert row=false, append row = false, auto append = false, delete row = false)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E53","input-pa_serial_prodl-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx2 = arr_curr() 
			NEXT FIELD scroll_flag 

			DISPLAY l_arr_rec_ser_prod2[l_idx2].prod_desc_text TO prod_desc_text 
			DISPLAY l_arr_rec_ser_prod2[l_idx2].prod_desc2_text TO prod_desc2_text 
			DISPLAY l_arr_rec_ser_prod2[l_idx2].desc_text TO desc_text 

		BEFORE FIELD serial_qty 
			CALL serial_init(
				glob_rec_kandoouser.cmpy_code,
				"1",
				"0",
				l_arr_rec_serial_prod[l_idx2].order_num)
				 
			LET l_cnt = serial_count(l_arr_rec_serial_prod[l_idx2].part_code,	l_ware_code) 

			LET l_cnt = serial_input( 
				l_arr_rec_serial_prod[l_idx2].part_code, 
				l_ware_code, 
				l_cnt) 

			OPTIONS INSERT KEY f35, 
			DELETE KEY f36 

			IF l_cnt < 0 THEN 
				CALL fgl_winmessage("ERROR","No Serials found","ERROR") 
				EXIT PROGRAM 
			END IF 

			LET l_arr_rec_serial_prod[l_idx2].serial_qty = l_cnt
			 
			DISPLAY BY NAME l_arr_rec_serial_prod[l_idx2].serial_qty 

			IF l_cnt <> l_arr_rec_serial_prod[l_idx2].picked_qty THEN 
				ERROR kandoomsg2("I",9296, l_arr_rec_serial_prod[l_idx2].part_code) #9296 Number of Serial codes needs TO equal Pick
			END IF 
			LET l_err_message = "E53 - serial_update " 

			LET l_rec_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_serialinfo.part_code = l_arr_rec_serial_prod[l_idx2].part_code 
			LET l_rec_serialinfo.ware_code = l_ware_code 
			LET l_rec_serialinfo.trans_num = l_arr_rec_serial_prod[l_idx2].order_num 
			LET l_rec_serialinfo.ref_num = l_arr_rec_serial_prod[l_idx2].order_num 
			LET l_rec_serialinfo.trantype_ind = "1" 

			BEGIN WORK 
				LET status = serial_update(l_rec_serialinfo.*, 1, "0") 
				IF status <> 0 THEN 
					GOTO recovery1 
					LET l_errmsg = "Serial Update status = ", trim(status)
					CALL fgl_winmessage("ERROR",l_errmsg,"ERROR") 
					EXIT PROGRAM 
				END IF 
			COMMIT WORK 

			NEXT FIELD scroll_flag 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				FOR l_idx2 = 1 TO l_rec_cnt 

					LET l_cnt = serial_count(l_arr_rec_serial_prod[l_idx2].part_code,		l_ware_code) 
					IF l_cnt <> l_arr_rec_serial_prod[l_idx2].picked_qty THEN 
						ERROR kandoomsg2("I",9296, l_arr_rec_serial_prod[l_idx2].part_code) #9296 Number of Serial codes needs TO equal Pick 
						NEXT FIELD scroll_flag 
					END IF 
				END FOR 
				LET l_quit = 'N' 
			ELSE 
				LET l_quit = 'Y' 
			END IF 
 
	END INPUT 

	CLOSE WINDOW E174 
	RETURN l_quit 
END FUNCTION 
###########################################################################
# END FUNCTION enter_serial_codes(l_rowid, l_cust_code, l_ware_code, l_pick_num )
###########################################################################


###########################################################################
# FUNCTION enter_despatch(l_rowid) 
#
# 
###########################################################################
FUNCTION enter_despatch(l_rowid) 
	DEFINE l_rowid INTEGER 
	DEFINE l_rec_inv_head RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		invoice_ind SMALLINT, 
		cust_code char(8), 
		order_num INTEGER, 
		pick_date DATE, 
		hold_code char(3), 
		calc_freight_amt decimal(16,2), 
		freight_amt decimal(16,2), 
		calc_hand_amt decimal(16,2), 
		hand_amt decimal(16,2), 
		ship_date DATE, 
		inv_date DATE, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		com1_text char(30), 
		com2_text char(30) 
	END RECORD 
	DEFINE l_invalid_period SMALLINT 

	SELECT * INTO l_rec_inv_head.* 
	FROM t_inv_head 
	WHERE rowid = l_rowid
	 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
		RETURNING l_rec_inv_head.year_num,	l_rec_inv_head.period_num
	 
	INPUT BY NAME 
		l_rec_inv_head.freight_amt, 
		l_rec_inv_head.hand_amt, 
		l_rec_inv_head.ship_date, 
		l_rec_inv_head.inv_date, 
		l_rec_inv_head.year_num, 
		l_rec_inv_head.period_num, 
		l_rec_inv_head.com1_text, 
		l_rec_inv_head.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E53","input-l_rec_inv_head-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD freight_amt 
			IF l_rec_inv_head.freight_amt IS NULL THEN 
				LET l_rec_inv_head.freight_amt = 0 
				DISPLAY BY NAME l_rec_inv_head.freight_amt 

			END IF 
			
		AFTER FIELD hand_amt 
			IF l_rec_inv_head.hand_amt IS NULL THEN 
				LET l_rec_inv_head.hand_amt = 0 
				DISPLAY BY NAME l_rec_inv_head.hand_amt 

			END IF
			 
		AFTER FIELD inv_date 
			IF l_rec_inv_head.inv_date IS NULL THEN 
				LET l_rec_inv_head.inv_date = today 
				NEXT FIELD inv_date 
			ELSE 
				IF NOT field_touched(year_num) THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
					RETURNING l_rec_inv_head.year_num, 
					l_rec_inv_head.period_num 
					DISPLAY BY NAME l_rec_inv_head.period_num, 
					l_rec_inv_head.year_num 

				END IF 
			END IF 

		AFTER FIELD year_num 
			IF l_rec_inv_head.year_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
				RETURNING l_rec_inv_head.year_num, 
				l_rec_inv_head.period_num 
				DISPLAY BY NAME l_rec_inv_head.period_num 

				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF l_rec_inv_head.period_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
				RETURNING l_rec_inv_head.year_num, 
				l_rec_inv_head.period_num 
				DISPLAY BY NAME l_rec_inv_head.period_num 

				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_inv_head.freight_amt IS NULL THEN 
					LET l_rec_inv_head.freight_amt = 0 
				END IF 
				
				IF l_rec_inv_head.hand_amt IS NULL THEN 
					LET l_rec_inv_head.hand_amt = 0 
				END IF 
				
				IF l_rec_inv_head.ship_date IS NULL THEN 
					LET l_rec_inv_head.ship_date = today 
				END IF 
				
				IF l_rec_inv_head.inv_date IS NULL THEN 
					LET l_rec_inv_head.inv_date = today 
				END IF 
				
				IF l_rec_inv_head.year_num IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
					RETURNING 
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num 
				END IF 
				
				IF l_rec_inv_head.period_num IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_inv_head.inv_date) 
					RETURNING 
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num 
				END IF
				 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					l_rec_inv_head.year_num, 
					l_rec_inv_head.period_num,
					"OE") 
				RETURNING 
					l_rec_inv_head.year_num, 
					l_rec_inv_head.period_num, 
					l_invalid_period 
				
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		UPDATE t_inv_head 
		SET 
			freight_amt = l_rec_inv_head.freight_amt, 
			hand_amt = l_rec_inv_head.hand_amt, 
			ship_date = l_rec_inv_head.ship_date, 
			inv_date = l_rec_inv_head.inv_date, 
			year_num = l_rec_inv_head.year_num, 
			period_num = l_rec_inv_head.period_num, 
			com1_text = l_rec_inv_head.com1_text, 
			com2_text = l_rec_inv_head.com2_text 
		WHERE rowid = l_rowid 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_despatch(l_rowid) 
###########################################################################


###########################################################################
# FUNCTION enter_bulk_despatch(p_conf_cnt)  
#
# 
###########################################################################
FUNCTION enter_bulk_despatch(p_conf_cnt) 
	DEFINE p_conf_cnt SMALLINT 
	DEFINE l_rec_inv_head RECORD 
		ship_date DATE, 
		inv_date DATE, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		com1_text char(30), 
		com2_text char(30) 
	END RECORD 
	DEFINE l_invalid_period SMALLINT 

	INITIALIZE l_rec_inv_head.* TO NULL 
	DISPLAY BY NAME p_conf_cnt 

	INPUT BY NAME 
		l_rec_inv_head.ship_date, 
		l_rec_inv_head.inv_date, 
		l_rec_inv_head.year_num, 
		l_rec_inv_head.period_num, 
		l_rec_inv_head.com1_text, 
		l_rec_inv_head.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E53","input-l_rec_inv_head-2") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD inv_date 
			IF l_rec_inv_head.inv_date IS NOT NULL THEN 
				IF l_rec_inv_head.year_num IS NULL OR l_rec_inv_head.period_num IS NULL THEN 
					CALL db_period_what_period(
						glob_rec_kandoouser.cmpy_code,
						l_rec_inv_head.inv_date) 
					RETURNING 
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num 

					CALL valid_period(
						glob_rec_kandoouser.cmpy_code,
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num,
						"OE") 
					RETURNING 
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num, 
						l_invalid_period 

					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 

					DISPLAY BY NAME 
						l_rec_inv_head.period_num, 
						l_rec_inv_head.year_num 

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF ( l_rec_inv_head.year_num IS NULL 
				AND l_rec_inv_head.period_num IS NOT NULL ) 
				OR ( l_rec_inv_head.year_num IS NOT NULL 
				AND l_rec_inv_head.period_num IS NULL ) THEN 
					ERROR kandoomsg2("E",9257,'') 		#9257  Enter both Year AND Period  OR don't enter either
					NEXT FIELD year_num 
				END IF 

				IF l_rec_inv_head.year_num IS NOT NULL 
				AND l_rec_inv_head.period_num IS NOT NULL THEN 
					CALL valid_period(
						glob_rec_kandoouser.cmpy_code,
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num,
						"OE") 
					RETURNING 
						l_rec_inv_head.year_num, 
						l_rec_inv_head.period_num, 
						l_invalid_period 

					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 

				END IF 
			END IF 
 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 

	ELSE 

		IF l_rec_inv_head.ship_date IS NOT NULL THEN 
			UPDATE t_inv_head 
			SET ship_date = l_rec_inv_head.ship_date 
			WHERE 1 = 1 
		END IF 

		IF l_rec_inv_head.inv_date IS NOT NULL THEN 
			UPDATE t_inv_head 
			SET inv_date = l_rec_inv_head.inv_date 
			WHERE 1 = 1 
		END IF 

		IF l_rec_inv_head.year_num IS NOT NULL THEN 
			UPDATE t_inv_head 
			SET 
				year_num = l_rec_inv_head.year_num, 
				period_num = l_rec_inv_head.period_num 
			WHERE 1 = 1 
		END IF 

		IF l_rec_inv_head.com1_text IS NOT NULL 
		OR l_rec_inv_head.com2_text IS NOT NULL THEN 
			UPDATE t_inv_head 
			SET 
				com1_text = l_rec_inv_head.com1_text, 
				com2_text = l_rec_inv_head.com2_text 
			WHERE 1 = 1 
		END IF
		 
		RETURN TRUE 
	END IF	 
END FUNCTION 
###########################################################################
# FUNCTION enter_bulk_despatch(p_conf_cnt)  
###########################################################################


###########################################################################
# FUNCTION check_serial_products(p_rowid)   
#
# 
###########################################################################
FUNCTION check_serial_products(p_rowid) 
	DEFINE p_rowid INTEGER 
--	DEFINE l_part_code LIKE product.part_code 
--	DEFINE l_ware_code LIKE warehouse.ware_code 
--	DEFINE l_picked_qty FLOAT 
--	DEFINE l_cnt INTEGER 

	SELECT unique 1 FROM t_inv_detl, product 
	WHERE inv_rowid = p_rowid 
	AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND product.part_code = t_inv_detl.part_code 
	AND product.serial_flag = 'Y' 

	IF status = NOTFOUND THEN 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION check_serial_products(p_rowid)   
###########################################################################


###########################################################################
# REPORT E53_rpt_lit_bulk_sum(p_rec_pickhead, p_inv_num)  
#
# 
###########################################################################
REPORT E53_rpt_lit_bulk_sum(p_rpt_idx,p_rec_pickhead, p_inv_num)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_pickhead RECORD 
		scroll_flag char(1), 
		pick_date LIKE pickhead.pick_date, 
		cust_code LIKE pickhead.cust_code, 
		name_text LIKE customer.name_text, 
		ware_code LIKE pickhead.ware_code, 
		pick_num LIKE pickhead.pick_num, 
		batch_num LIKE pickhead.batch_num, 
		reqd_flag char(1) 
	END RECORD 
	DEFINE p_inv_num LIKE invoicehead.inv_num
	 
	DEFINE i SMALLINT

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Date", 
			COLUMN 12, "Customer", 
			COLUMN 51, "Warehouse Pick No. batch", 
			COLUMN 82, "Invoice#/Credit#" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_pickhead.pick_date USING "dd/mm/yy", 
			COLUMN 12, p_rec_pickhead.cust_code, 
			COLUMN 21, p_rec_pickhead.name_text, 
			COLUMN 55, p_rec_pickhead.ware_code, 
			COLUMN 63, p_rec_pickhead.pick_num USING "########", 
			COLUMN 72, p_rec_pickhead.batch_num USING "########", 
			COLUMN 86, p_inv_num USING "########" 

		ON LAST ROW 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
###########################################################################
# END REPORT E53_rpt_lit_bulk_sum(p_rec_pickhead, p_inv_num)  
###########################################################################