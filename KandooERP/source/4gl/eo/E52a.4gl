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
GLOBALS "../eo/E52_GLOBALS.4gl" 
###########################################################################
# FUNCTION select_picklist() 
#
# E52a - Packing Slip / Picking List Generation Program
#                FUNCTION print_pickslip()
###########################################################################
FUNCTION select_picklist() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	MESSAGE kandoomsg2("E",1001,"")#1001 " Enter Selection Criteria - ESC TO Continue "

	CONSTRUCT BY NAME l_where_text ON 
		pick_date, 
		ware_code, 
		pick_num, 
		cust_code, 
		status_ind, 
		con_status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E52a","construct-pick_date-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_picklist() 
###########################################################################


###########################################################################
# FUNCTION scan_picklist(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text)  
#
# 
###########################################################################
FUNCTION scan_picklist(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[l_rpt_idx]	
	DEFINE l_rec_pickhead RECORD LIKE pickhead.*
	DEFINE l_arr_rec_pickhead DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		pick_date LIKE pickhead.pick_date, 
		ware_code LIKE pickhead.ware_code, 
		pick_num LIKE pickhead.pick_num, 
		cust_code LIKE pickhead.cust_code, 
		name_text LIKE customer.name_text, 
		status_ind LIKE pickhead.status_ind, 
		con_status_ind LIKE pickhead.con_status_ind 
	END RECORD
	DEFINE l_scroll_flag char(1)
	DEFINE l_query_text char(300)
	DEFINE l_idx SMALLINT 
	DEFINE l_del_qty SMALLINT 

	IF p_where_text IS NULL THEN 
		RETURN 
	END IF 

	MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "

	LET l_query_text = 
		"SELECT * ", 
		"FROM pickhead ", 
		"WHERE cmpy_code = \"",p_cmpy_code,"\" ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"pick_date desc,", 
		"ware_code,", 
		"pick_num" 
 
	PREPARE s_pickhead FROM l_query_text 
	DECLARE c1_pickhead cursor FOR s_pickhead
	 
	LET l_idx = 0
	FOREACH c1_pickhead INTO l_rec_pickhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_pickhead[l_idx].pick_date = l_rec_pickhead.pick_date 
		LET l_arr_rec_pickhead[l_idx].ware_code = l_rec_pickhead.ware_code 
		LET l_arr_rec_pickhead[l_idx].pick_num = l_rec_pickhead.pick_num 
		LET l_arr_rec_pickhead[l_idx].cust_code = l_rec_pickhead.cust_code 

		SELECT name_text 
		INTO l_arr_rec_pickhead[l_idx].name_text 
		FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_pickhead.cust_code 

		LET l_arr_rec_pickhead[l_idx].status_ind = l_rec_pickhead.status_ind 
		LET l_arr_rec_pickhead[l_idx].con_status_ind = l_rec_pickhead.con_status_ind 
	END FOREACH 

	IF l_idx = 0 THEN 
		CALL fgl_winmessage("No Data Selected",kandoomsg2("E",9119,""),"ERROR") 		#9119" No picking lists satisfied Selection Criteria "
	ELSE 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
 
		MESSAGE kandoomsg2("E",1030,"")		#1030 F2 TO Delete - RETURN on line TO View - F9 TO Reprint
		INPUT ARRAY l_arr_rec_pickhead WITHOUT DEFAULTS FROM sr_pickhead.* ATTRIBUTE(auto append = false, insert row = false, append row = false, delete row = false)  
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E52a","input-l_arr_rec_pickhead-1")  

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "RE-PRINT" --ON KEY (f9) 
				SELECT * INTO l_rec_pickhead.* 
				FROM pickhead 
				WHERE cmpy_code = p_cmpy_code 
				AND ware_code = l_arr_rec_pickhead[l_idx].ware_code 
				AND pick_num = l_arr_rec_pickhead[l_idx].pick_num 
				
				ERROR kandoomsg2("E",1032,"") 
				LET l_rec_pickhead.printed_num = l_rec_pickhead.printed_num + 1 

				#------------------------------------------------------------
				#User pressed CANCEL = p_where_text IS NULL 
			
				LET l_rpt_idx = rpt_start(getmoduleid(),"E52_rpt_list_picklist",p_where_text, RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT E52_rpt_list_picklist TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
				#------------------------------------------------------------

				
				LET glob_arr_rec_rpt_kandooreport[l_rpt_idx].header_text = "E52 Pick-List Reprint ", 
				"-Warehouse:",l_rec_pickhead.ware_code," ", 
				"-List#:",l_rec_pickhead.pick_num USING "<<<<< ", 
				"-Reprint#:",l_rec_pickhead.printed_num USING "<<" 
				
				--LET l__output = init_report(p_cmpy_code,p_kandoouser_sign_on_code,rpt_note) 
				--START REPORT E52_rpt_list_picklist TO l__output 
				--LET l_page_num = 0 

				#---------------------------------------------------------
				OUTPUT TO REPORT E52_rpt_list_picklist(l_rpt_idx,
				l_rec_pickhead.*)
				#---------------------------------------------------------

				
				#------------------------------------------------------------
				FINISH REPORT E52_rpt_list_picklist
				CALL rpt_finish("E52_rpt_list_picklist")
				#------------------------------------------------------------
				 
				UPDATE pickhead 
				SET printed_num = l_rec_pickhead.printed_num, 
				printed_date = today 
				WHERE cmpy_code = p_cmpy_code 
				AND ware_code = l_arr_rec_pickhead[l_idx].ware_code 
				AND pick_num = l_arr_rec_pickhead[l_idx].pick_num 
				ERROR kandoomsg2("E",1030,"")
				 
			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 

				LET l_scroll_flag = l_arr_rec_pickhead[l_idx].scroll_flag
				 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_pickhead[l_idx].scroll_flag = l_scroll_flag 

				IF fgl_lastkey() = fgl_keyval("down")		AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF
				 
			BEFORE FIELD pick_date 
				CALL disp_picklist(
					p_cmpy_code,
					l_arr_rec_pickhead[l_idx].ware_code, 
					l_arr_rec_pickhead[l_idx].pick_num)
					 
				NEXT FIELD scroll_flag
				 
			ON KEY (f2) 
				IF l_arr_rec_pickhead[l_idx].scroll_flag IS NULL THEN 
					IF l_arr_rec_pickhead[l_idx].status_ind = "0" THEN 
						ERROR kandoomsg2("E",7043,l_arr_rec_pickhead[l_idx].pick_num)		#7043 Warning: Picking Slip IS still Active
					ELSE 
						LET l_arr_rec_pickhead[l_idx].scroll_flag = "*" 
						LET l_del_qty = l_del_qty + 1 
					END IF 
				ELSE 
					LET l_arr_rec_pickhead[l_idx].scroll_flag = NULL 
					LET l_del_qty = l_del_qty - 1 
				END IF 
				NEXT FIELD scroll_flag
				 
--			AFTER ROW 
--				DISPLAY l_arr_rec_pickhead[l_idx].* 
--				TO sr_pickhead[scrn].* 

		END INPUT 

		IF not(int_flag OR quit_flag) THEN 
			IF l_del_qty != 0 THEN 
				IF promptTF("View Line Details",kandoomsg2("E",8003,""),1) THEN  #8003 Confirm TO Delete ",l_del_qty,"Picking Slips(s)? (Y/N)"

					FOR l_idx = 1 TO arr_count() 

						IF l_arr_rec_pickhead[l_idx].scroll_flag = "*" THEN 
							DELETE FROM pickhead 
							WHERE cmpy_code = p_cmpy_code 
							AND ware_code = l_arr_rec_pickhead[l_idx].ware_code 
							AND pick_num = l_arr_rec_pickhead[l_idx].pick_num 

							DELETE FROM pickdetl 
							WHERE cmpy_code = p_cmpy_code 
							AND ware_code = l_arr_rec_pickhead[l_idx].ware_code 
							AND pick_num = l_arr_rec_pickhead[l_idx].pick_num 
						END IF 

					END FOR 

				END IF 
			END IF 
		END IF 
	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_picklist(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text)  
###########################################################################


###########################################################################
# FUNCTION disp_picklist(p_cmpy_code,p_ware_code,p_pick_num) 
#
# 
###########################################################################
FUNCTION disp_picklist(p_cmpy_code,p_ware_code,p_pick_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ware_code LIKE pickhead.ware_code 
	DEFINE p_pick_num LIKE pickhead.pick_num 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_arr_rec_pickdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		part_code LIKE pickdetl.part_code, 
		bin1_text LIKE prodstatus.bin1_text, 
		picked_qty LIKE pickdetl.picked_qty, 
		order_num LIKE pickdetl.order_num, 
		order_date LIKE pickdetl.order_date 
	END RECORD 
	DEFINE l_arr_description array[4] OF char(30) 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_pickhead.* 
	FROM pickhead 
	WHERE cmpy_code = p_cmpy_code 
	AND ware_code = p_ware_code 
	AND pick_num = p_pick_num 
	
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("E",7044,l_rec_pickhead.pick_num)	#7044 Picking List has been deleted
	ELSE 
		OPEN WINDOW E151 with FORM "E151" 
		 CALL windecoration_e("E151") -- albo kd-755 
		MESSAGE kandoomsg2("E",1008,"")	#1008 " F3 /F4 Esc TO continue

		SELECT desc_text INTO l_arr_description[1] 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy_code 
		AND ware_code = p_ware_code 

		SELECT name_text INTO l_arr_description[2] 
		FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_pickhead.cust_code 

		SELECT name_text INTO l_arr_description[3] 
		FROM customership 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_pickhead.cust_code 
		AND ship_code = l_rec_pickhead.ship_code 

		SELECT name_text INTO l_arr_description[4] 
		FROM carrier 
		WHERE cmpy_code = p_cmpy_code 
		AND carrier_code = l_rec_pickhead.carrier_code 

		DISPLAY BY NAME 
			l_rec_pickhead.pick_num, 
			l_rec_pickhead.pick_date, 
			l_rec_pickhead.status_ind, 
			l_rec_pickhead.ware_code, 
			l_rec_pickhead.cust_code, 
			l_rec_pickhead.ship_code, 
			l_rec_pickhead.carrier_code, 
			l_rec_pickhead.printed_num, 
			l_rec_pickhead.printed_date, 
			l_rec_pickhead.delivery_ind 

		FOR l_idx = 1 TO 4 
			DISPLAY l_arr_description[l_idx] TO sr_description[l_idx].* 

		END FOR 

		DECLARE c_pickdetl cursor FOR 
		SELECT * FROM pickdetl 
		WHERE cmpy_code = p_cmpy_code 
		AND ware_code = p_ware_code 
		AND pick_num = p_pick_num 
		ORDER BY 
			cmpy_code, 
			ware_code, 
			pick_num, 
			part_code, 
			order_num 

		LET l_idx = 0 
		FOREACH c_pickdetl INTO l_rec_pickdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_pickdetl[l_idx].part_code = l_rec_pickdetl.part_code 

			SELECT bin1_text 
			INTO l_arr_rec_pickdetl[l_idx].bin1_text 
			FROM prodstatus 
			WHERE cmpy_code = p_cmpy_code 
			AND ware_code = l_rec_pickdetl.ware_code 
			AND part_code = l_rec_pickdetl.part_code 

			LET l_arr_rec_pickdetl[l_idx].picked_qty = l_rec_pickdetl.picked_qty 
			LET l_arr_rec_pickdetl[l_idx].order_num = l_rec_pickdetl.order_num 
			LET l_arr_rec_pickdetl[l_idx].order_date = l_rec_pickdetl.order_date 
		END FOREACH 

		CALL set_count(l_idx) 

		DISPLAY ARRAY l_arr_rec_pickdetl TO sr_pickdetl.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","E52a","display-arr-pickdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		LET int_flag = FALSE 
		LET quit_flag = FALSE 

		CLOSE WINDOW E151 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION disp_picklist(p_cmpy_code,p_ware_code,p_pick_num) 
###########################################################################


###########################################################################
# FUNCTION select_criteria(p_cmpy_code) 
#
# 
###########################################################################
FUNCTION select_criteria(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_criteria RECORD 
		first_order_num LIKE orderhead.order_num, 
		last_order_num LIKE orderhead.order_num, 
		first_cust_code LIKE orderhead.cust_code, 
		last_cust_code LIKE orderhead.cust_code, 
		first_ware_code LIKE orderhead.ware_code, 
		last_ware_code LIKE orderhead.ware_code, 
		first_ord_text LIKE orderhead.ord_text, 
		last_ord_text LIKE orderhead.ord_text 
	END RECORD 
	DEFINE l_where_text STRING 
	DEFINE l_temp_text char(10) 

	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy_code 

	LET l_rec_criteria.first_order_num = NULL 
	LET l_rec_criteria.last_order_num = NULL 
	LET l_rec_criteria.first_ord_text = NULL 
	LET l_rec_criteria.last_ord_text = NULL 

	DISPLAY BY NAME l_rec_arparms.inv_ref1_text	attribute(white) 

	MESSAGE kandoomsg2("E",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue "
	INPUT BY NAME l_rec_criteria.* WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E52a","input-l_rec_criteria-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(first_cust_code) 
					LET l_temp_text = show_clnt(p_cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_criteria.first_cust_code = l_temp_text 
						NEXT FIELD first_cust_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(last_cust_code) 
					LET l_temp_text = show_clnt(p_cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_criteria.last_cust_code = l_temp_text 
						NEXT FIELD last_cust_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(first_ware_code) 
					LET l_temp_text = show_ware(p_cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_criteria.first_ware_code = l_temp_text 
						NEXT FIELD first_ware_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(last_ware_code) 
					LET l_temp_text = show_ware(p_cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_criteria.last_ware_code = l_temp_text 
						NEXT FIELD last_ware_code 
					END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN
				IF NOT promptTF("Generate Picking Lists",kandoomsg2("A",8015,""),1) THEN  #8015 Generate Picking Lists. (Y/N)?
					NEXT FIELD first_order_num 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		LET l_where_text = " 1=1 " 
		IF l_rec_criteria.first_order_num IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," AND orderhead.order_num >= ", l_rec_criteria.first_order_num USING "<<<<<<<<" 
		END IF 
		IF l_rec_criteria.last_order_num IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," AND orderhead.order_num <= ",	l_rec_criteria.last_order_num USING "<<<<<<<<" 
		END IF 
		IF l_rec_criteria.first_cust_code IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ",	" AND orderhead.cust_code >=\"",l_rec_criteria.first_cust_code,"\" " 
		END IF 
		IF l_rec_criteria.last_cust_code IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ", "AND orderhead.cust_code <=\"",l_rec_criteria.last_cust_code,"\"" 
		END IF 
		IF l_rec_criteria.first_ware_code IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ", "AND orderhead.ware_code >=\"",l_rec_criteria.first_ware_code,"\"" 
		END IF 
		IF l_rec_criteria.last_ware_code IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ", "AND orderhead.ware_code <=\"",l_rec_criteria.last_ware_code,"\"" 
		END IF 
		IF l_rec_criteria.first_ord_text IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ", "AND orderhead.ord_text >=\"",l_rec_criteria.first_ord_text,"\"" 
		END IF 
		IF l_rec_criteria.last_ord_text IS NOT NULL THEN 
			LET l_where_text = l_where_text clipped," ", "AND orderhead.ord_text <=\"",l_rec_criteria.last_ord_text,"\"" 
		END IF 
	END IF
	 
	RETURN l_where_text 
END FUNCTION 
###########################################################################
# END FUNCTION select_criteria(p_cmpy_code) 
###########################################################################


###########################################################################
# FUNCTION generate_pick(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text) 
#
# 
###########################################################################
FUNCTION generate_pick(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE p_where_text STRING --char(400)
	
	DEFINE l_query_text STRING --char(800)
	DEFINE l_rec_customer RECORD LIKE customer.*
--	DEFINE glob_rec_opparms RECORD LIKE opparms.*
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_commit_amt LIKE orderhead.total_amt
	DEFINE l_temp_text char(50)
	DEFINE l_valid_credit SMALLINT 
	DEFINE l_ship_ind SMALLINT 
	DEFINE l_kandoooption STRING
	
	IF p_where_text IS NOT NULL THEN 
		CREATE temp TABLE t_picklist(
			ware_code char(3), 
			delivery_ind char(1), 
			cust_code char(8), 
			ship_ind SMALLINT, 
			ship_code char(8), 
			term_code char(3), 
			tax_code char(3), 
			cond_code char(3), 
			sales_code char(8), 
			territory_code char(5), 
			invoice_to_ind char(1), 
			carrier_code char(3), 
			order_num INTEGER, 
			order_date DATE, 
			order_rev_num INTEGER, 
			order_line_num SMALLINT ) with no LOG

		LET l_query_text = 
			"SELECT * FROM orderhead ", 
			"WHERE cmpy_code = \"",p_cmpy_code,"\" ", 
			"AND hold_code IS NULL ", 
			"AND status_ind in ('U','P') ", 
			"AND ord_ind in ('2','3') ", 
			"AND ship_date <=(\"",today + glob_rec_opparms.days_pick_num,"\") ", 
			"AND ",p_where_text clipped," ", 
			"ORDER BY cust_code,ship_code" 
		PREPARE s_orderhead FROM l_query_text 
		DECLARE c_orderhead cursor with hold FOR s_orderhead 
		DECLARE c_edit_order cursor FOR 
		SELECT * FROM orderhead 
		WHERE order_num = l_rec_orderhead.order_num 
		AND cmpy_code = p_cmpy_code 
		FOR UPDATE 
		
		FOREACH c_orderhead INTO l_rec_orderhead.* 
			IF l_rec_orderhead.cust_code != l_rec_customer.cust_code OR l_rec_customer.cust_code IS NULL THEN
			 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = l_rec_orderhead.cust_code
				 
				LET l_ship_ind = 0 
			END IF 
			
			WHENEVER ERROR CONTINUE 
			BEGIN WORK 
				OPEN c_edit_order 
				IF status <> 0 THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				FETCH c_edit_order 
				IF status <> 0 THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				IF l_rec_orderhead.status_ind = "X" THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				UPDATE orderhead SET status_ind = "X" 
				WHERE cmpy_code = p_cmpy_code 
				AND order_num = l_rec_orderhead.order_num 
				IF status <> 0 THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				LET l_kandoooption = get_kandoooption_feature_state('EO','NP')
				IF l_kandoooption = "1" THEN  #kandoooption EO NP

					INSERT INTO t_picklist(
						ware_code, 
						cust_code, 
						order_num, 
						order_line_num) 

					SELECT 
						ware_code, 
						cust_code, 
						order_num, 
						line_num 
					FROM orderdetl 
					WHERE cmpy_code = p_cmpy_code 
					AND order_num = l_rec_orderhead.order_num 
					AND (pick_flag = "Y" OR part_code IS null) 
					AND sched_qty > 0 

				ELSE 

					INSERT INTO t_picklist(
						ware_code, 
						cust_code, 
						order_num, 
						order_line_num) 

					SELECT 
						ware_code, 
						cust_code, 
						order_num, 
						line_num 
					FROM orderdetl 
					WHERE cmpy_code = p_cmpy_code 
					AND order_num = l_rec_orderhead.order_num 
					AND pick_flag = "Y" 
					AND sched_qty > 0 
				END IF 
			
				IF sqlca.sqlerrd[3] = 0 THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			
			COMMIT WORK 
			
			WHENEVER ERROR stop 
			UPDATE t_picklist 
			SET 
				delivery_ind = l_rec_orderhead.delivery_ind, 
				ship_code = l_rec_orderhead.ship_code, 
				carrier_code = l_rec_orderhead.carrier_code, 
				cond_code = l_rec_orderhead.cond_code, 
				sales_code = l_rec_orderhead.sales_code, 
				territory_code = l_rec_orderhead.territory_code, 
				term_code = l_rec_orderhead.term_code, 
				tax_code = l_rec_orderhead.tax_code, 
				invoice_to_ind = l_rec_orderhead.invoice_to_ind, 
				order_date = l_rec_orderhead.order_date, 
				order_rev_num = l_rec_orderhead.rev_num, 
				ship_ind = l_ship_ind 
			WHERE order_num = l_rec_orderhead.order_num 
			
			IF l_rec_customer.consolidate_flag = "N" OR l_rec_orderhead.ship_code IS NULL THEN 
				LET l_ship_ind = l_ship_ind + 1 
			END IF
			 
		END FOREACH
		 
		RETURN TRUE 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION generate_pick(p_cmpy_code,p_kandoouser_sign_on_code,p_where_text) 
###########################################################################


###########################################################################
# FUNCTION create_picklist(p_cmpy_code, p_kandoouser_sign_on_code, p_ware_code, 
#	p_delivery_ind, p_verbose_ind, p_flat_file) 
#
# 
###########################################################################
FUNCTION create_picklist(p_cmpy_code, p_kandoouser_sign_on_code, p_ware_code, p_delivery_ind, l_verbose_ind, p_flat_file) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_delivery_ind LIKE orderhead.delivery_ind 
	DEFINE p_flat_file SMALLINT
	DEFINE l_rpt_idx SMALLINT  #report array index	 
--	DEFINE glob_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
--	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.*
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_pickdetl2 RECORD LIKE pickdetl.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_picklist RECORD 
		ware_code LIKE orderhead.ware_code, 
		delivery_ind LIKE orderhead.delivery_ind, 
		cust_code LIKE orderhead.cust_code, 
		ship_ind SMALLINT, 
		ship_code LIKE orderhead.ship_code, 
		term_code LIKE orderhead.term_code, 
		tax_code LIKE orderhead.tax_code, 
		cond_code LIKE orderhead.cond_code, 
		sales_code LIKE orderhead.sales_code, 
		territory_code LIKE orderhead.territory_code, 
		invoice_to_ind LIKE orderhead.invoice_to_ind, 
		carrier_code LIKE orderhead.carrier_code, 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		order_rev_num LIKE orderhead.rev_num, 
		order_line_num LIKE orderdetl.line_num 
	END RECORD 
	DEFINE l_pick_batch_num LIKE pickhead.batch_num 
	DEFINE l_verbose_ind SMALLINT 
	DEFINE l_time LIKE delivmsg.msg_time 
	DEFINE l_event_text LIKE delivmsg.event_text 
	DEFINE l_msg_num INTEGER 
	DEFINE l_msg_text char(60) 
	DEFINE query_text char(400) 
--	DEFINE rpt_note char(60)
	DEFINE l_err_message char(60)
	DEFINE l_class_code LIKE pickdetl.class_code 
	DEFINE l_file_name char(60) 
	DEFINE l_errmsg STRING #error message string

	LET glob_rec_rpt_selector.rpt_note = "EO - Picking Lists - warehouse:",p_ware_code, " - delivery:",p_delivery_ind
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"E52_rpt_list_picklist","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E52_rpt_list_picklist TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------	

	IF l_verbose_ind THEN 
		#OPEN WINDOW w1_E52 AT 20,12 with 2 rows,50 columns
		#   ATTRIBUTE(border,cyan)
		ERROR kandoomsg2("E",1031,p_ware_code) #1031 Generating picking slips FOR warehouse ????
	END IF 
	LET l_pick_batch_num = NULL 
	DECLARE c1_picklist cursor with hold FOR 
	SELECT cust_code, 
	ship_ind 
	FROM t_picklist 
	WHERE ware_code = p_ware_code 
	AND delivery_ind = p_delivery_ind 
	GROUP BY cust_code, 
	ship_ind 

	FOREACH c1_picklist INTO l_rec_picklist.cust_code,l_rec_picklist.ship_ind 
		DECLARE c2_picklist cursor with hold FOR 
		SELECT 
			ship_code, 
			carrier_code, 
			cond_code, 
			sales_code, 
			territory_code, 
			term_code, 
			tax_code, 
			invoice_to_ind , 
			delivery_ind 
		FROM t_picklist 
		WHERE ware_code = p_ware_code 
		AND delivery_ind = p_delivery_ind 
		AND cust_code = l_rec_picklist.cust_code 
		AND ship_ind = l_rec_picklist.ship_ind 
		GROUP BY 1,2,3,4,5,6,7,8,9 

		FOREACH c2_picklist INTO 
			l_rec_picklist.ship_code, 
			l_rec_picklist.carrier_code, 
			l_rec_picklist.cond_code, 
			l_rec_picklist.sales_code, 
			l_rec_picklist.territory_code, 
			l_rec_picklist.term_code, 
			l_rec_picklist.tax_code, 
			l_rec_picklist.invoice_to_ind, 
			l_rec_picklist.delivery_ind 

			IF retry_lock(p_cmpy_code,0) THEN END IF 
				GOTO bypass 
				LABEL recovery: 
				IF retry_lock(p_cmpy_code,status) > 0 THEN 
					ROLLBACK WORK 
				ELSE 
					IF l_verbose_ind THEN 
						IF error_recover(l_err_message,status)!= "Y" THEN 
							UPDATE orderhead 
							SET status_ind = "P" 
							WHERE status_ind = "X" 
							AND order_num in (select order_num FROM t_picklist) 
							AND cmpy_code = p_cmpy_code
							
							CALL fgl_winmessage("EXIT PROGRAM","Error Recovery - EXIT PROGRAM","INFO") 
							EXIT PROGRAM 
						END IF 

					ELSE 

						LET l_err_message = l_err_message clipped," " 

						ROLLBACK WORK 

						UPDATE orderhead 
						SET status_ind = "P" 
						WHERE status_ind = "X" 
						AND order_num in 
							(select order_num FROM t_picklist 
							WHERE ware_code = p_ware_code 
							AND delivery_ind = p_delivery_ind 
							AND cust_code = l_rec_picklist.cust_code 
							AND ship_ind = l_rec_picklist.ship_ind) 
						AND cmpy_code = p_cmpy_code 

						LET l_event_text = "Error generating pickslip ", l_err_message clipped 
						LET l_msg_num = 7101 
						LET l_msg_text = status USING "-<<<<<<" 
						LET l_time = time 

						INSERT INTO delivmsg VALUES (
							p_cmpy_code, 
							0, 
							"", 
							today, 
							l_time, 
							l_event_text, 
							l_msg_num, 
							l_msg_text) 

						CONTINUE FOREACH 
					END IF 
				END IF 

				LABEL bypass: 
				WHENEVER any ERROR GOTO recovery 
				BEGIN WORK 
					IF l_pick_batch_num IS NULL THEN 
						DECLARE c_opparms cursor FOR 
						SELECT * FROM opparms 
						WHERE cmpy_code = p_cmpy_code 
						FOR UPDATE 
						OPEN c_opparms 
						FETCH c_opparms INTO glob_rec_opparms.* 
						IF status = NOTFOUND THEN 
						END IF 

						IF glob_rec_opparms.pick_batch_num IS NULL OR glob_rec_opparms.pick_batch_num = 0 THEN 
							LET glob_rec_opparms.pick_batch_num = 1 
						END IF 

						LET l_pick_batch_num = glob_rec_opparms.pick_batch_num 
						UPDATE opparms 
						SET pick_batch_num = glob_rec_opparms.pick_batch_num + 1 
						WHERE cmpy_code = p_cmpy_code 
						CLOSE c_opparms 

						IF p_flat_file THEN 
							DECLARE c1_loadparms cursor FOR 
							SELECT * FROM loadparms 
							WHERE cmpy_code = p_cmpy_code 
							AND module_code = 'EO' 
							AND format_ind = "3"
							 
							OPEN c1_loadparms 
							FETCH c1_loadparms INTO l_rec_loadparms.* 
							CLOSE c1_loadparms 

							LET l_file_name = 
								l_rec_loadparms.path_text clipped, "/", 
								l_rec_loadparms.file_text clipped, 
								l_pick_batch_num USING "&&&&&&" 

							IF NOT is_path_valid(l_rec_loadparms.path_text) THEN 
								IF l_verbose_ind THEN 
									ERROR kandoomsg2("E",7102,"") 			#7102 Invalid Unix pathname SET up in parameter
								END IF 

								LET l_err_message = 
									"E52a - Invalid Path FOR Load Type ", 
									l_rec_loadparms.load_ind, 
									". Refer Menu Path ezi" 
								CALL errorlog(l_err_message) 

								ROLLBACK WORK 

								UPDATE orderhead 
								SET status_ind = "P" 
								WHERE status_ind = "X" 
								AND order_num in (select order_num FROM t_picklist) 
								AND cmpy_code = p_cmpy_code
								LET l_errmsg = trim(l_errmsg), "\nExit Program"
								CALL fgl_winmessage("ERROR",l_errmsg,"ERROR") 								 
								EXIT PROGRAM 
							END IF 

#??????????????????							
							START REPORT E52_rpt_list_flat_file TO l_file_name
#??????????????????

						END IF 
					END IF 

					INITIALIZE l_rec_pickhead.* TO NULL 
					LET l_rec_pickhead.cmpy_code = p_cmpy_code 
					LET l_rec_pickhead.ware_code = p_ware_code 
					LET l_rec_pickhead.batch_num = l_pick_batch_num 

					SELECT next_pick_num INTO l_rec_pickhead.pick_num 
					FROM warehouse 
					WHERE cmpy_code = p_cmpy_code 
					AND ware_code = p_ware_code 

					UPDATE warehouse 
					SET next_pick_num = next_pick_num + 1 
					WHERE cmpy_code = p_cmpy_code 
					AND ware_code = p_ware_code 

					LET l_rec_pickhead.pick_date = today 
					LET l_rec_pickhead.cust_code = l_rec_picklist.cust_code 
					LET l_rec_pickhead.ship_code = l_rec_picklist.ship_code 
					LET l_rec_pickhead.sale_code = l_rec_picklist.sales_code 
					LET l_rec_pickhead.terr_code = l_rec_picklist.territory_code 
					LET l_rec_pickhead.carrier_code = l_rec_picklist.carrier_code 
					LET l_rec_pickhead.delivery_ind = l_rec_picklist.delivery_ind 
					LET l_rec_pickhead.printed_num = 1 
					LET l_rec_pickhead.printed_date = today 
					LET l_rec_pickhead.status_ind = "0" 
					LET l_rec_pickhead.con_status_ind = "0" 

					LET query_text = 
						"SELECT * FROM t_picklist ", 
						"WHERE ware_code = \"",p_ware_code,"\" ", 
						"AND delivery_ind = \"",p_delivery_ind,"\" ", 
						"AND cust_code = \"",l_rec_picklist.cust_code,"\" ", 
						"AND ship_ind = \"",l_rec_picklist.ship_ind,"\" ", 
						"AND invoice_to_ind = \"",l_rec_picklist.invoice_to_ind,"\" ", 
						"AND sales_code = \"",l_rec_picklist.sales_code,"\" ", 
						"AND territory_code = \"",l_rec_picklist.territory_code,"\" ", 
						"AND term_code = \"",l_rec_picklist.term_code,"\" ", 
						"AND tax_code = \"",l_rec_picklist.tax_code,"\"" 

					IF l_rec_picklist.ship_code IS NULL THEN 
						LET query_text = query_text clipped," AND ship_code IS null" 
					ELSE 
						LET query_text = query_text clipped," ","AND ship_code = \"",l_rec_picklist.ship_code,"\"" 
					END IF 

					IF l_rec_picklist.carrier_code IS NULL THEN 
						LET query_text = query_text clipped," AND carrier_code IS null" 
					ELSE 
						LET query_text = query_text clipped," ","AND carrier_code = \"",l_rec_picklist.carrier_code,"\"" 
					END IF 

					IF l_rec_picklist.cond_code IS NULL THEN 
						LET query_text = query_text clipped," AND cond_code IS null" 
					ELSE 
						LET query_text = query_text clipped," ","AND cond_code = \"",l_rec_picklist.cond_code,"\"" 
					END IF 
					
					PREPARE s3_picklist FROM query_text 
					DECLARE c3_picklist cursor FOR s3_picklist 

					FOREACH c3_picklist INTO l_rec_picklist.* 
						INITIALIZE l_rec_pickdetl.* TO NULL 

						LET l_rec_pickdetl.cmpy_code = p_cmpy_code 
						LET l_rec_pickdetl.ware_code = p_ware_code 
						LET l_rec_pickdetl.pick_num = l_rec_pickhead.pick_num 
						LET l_rec_pickdetl.order_num = l_rec_picklist.order_num 
						LET l_rec_pickdetl.order_line_num = l_rec_picklist.order_line_num 
						LET l_rec_pickdetl.order_rev_num = l_rec_picklist.order_rev_num 
						LET l_rec_pickdetl.order_date = l_rec_picklist.order_date 

						LET query_text = 
							"SELECT * FROM orderdetl ", 
							" WHERE cmpy_code = '",p_cmpy_code,"' ", 
							" AND order_num = ",l_rec_pickdetl.order_num," ", 
							" AND line_num = ",l_rec_pickdetl.order_line_num," ", 
							" AND sched_qty > 0 " 

						IF get_kandoooption_feature_state('EO','NP') THEN 
							LET query_text =	query_text clipped, 
								" AND (pick_flag = 'Y' ", 
								" OR part_code IS null)", 
								" FOR UPDATE " 
						ELSE 
							LET query_text = query_text clipped, " AND pick_flag = 'Y' FOR UPDATE " 
						END IF 

						PREPARE s_orderdetl FROM query_text 
						DECLARE c_orderdetl cursor FOR s_orderdetl 
						OPEN c_orderdetl 
						FETCH c_orderdetl INTO l_rec_orderdetl.* 

						IF sqlca.sqlcode = 0 THEN 
							LET l_rec_pickdetl.part_code = l_rec_orderdetl.part_code 
							LET l_rec_pickdetl.picked_qty = l_rec_orderdetl.sched_qty 

							UPDATE orderdetl 
							SET 
								sched_qty = 0,	
								picked_qty = l_rec_pickdetl.picked_qty 
							WHERE cmpy_code = p_cmpy_code 
							AND order_num = l_rec_pickdetl.order_num 
							AND line_num = l_rec_pickdetl.order_line_num 

							INSERT INTO pickdetl VALUES (l_rec_pickdetl.*) 

						END IF 
					END FOREACH 

					###-Dangerous Goods Processing-###
					DECLARE c_danger cursor FOR 
					SELECT * FROM pickdetl 
					WHERE cmpy_code = p_cmpy_code 
					AND ware_code = l_rec_pickhead.ware_code 
					AND pick_num = l_rec_pickhead.pick_num 

					FOREACH c_danger INTO l_rec_pickdetl2.* 
						LET l_class_code = NULL 

						SELECT class_code INTO l_class_code 
						FROM proddanger 
						WHERE cmpy_code = p_cmpy_code 
						AND dg_code = 
							(select dg_code FROM product 
							WHERE cmpy_code = p_cmpy_code 
							AND part_code = l_rec_pickdetl2.part_code 
							AND dg_code IS NOT null) 

						IF l_class_code IS NOT NULL THEN 
							SELECT unique 1 FROM dangercarry 
							WHERE class1_code = l_class_code 
							AND class2_code in 
								(select unique(class_code) FROM proddanger 
								WHERE cmpy_code = p_cmpy_code 
								AND dg_code in 
									(select unique(dg_code) FROM product 
									WHERE cmpy_code = p_cmpy_code 
									AND part_code in 
									(select unique(part_code) FROM pickdetl 
									WHERE cmpy_code = p_cmpy_code 
									AND ware_code = l_rec_pickdetl2.ware_code 
									AND pick_num = l_rec_pickdetl2.pick_num 
									AND order_num = l_rec_pickdetl2.order_num))
								) 
							AND carry_ind IS NOT NULL 

							IF status != NOTFOUND THEN 
								UPDATE pickdetl 
								SET 
									class_code = l_class_code, 
									carry_ind = "*" 
								WHERE cmpy_code = p_cmpy_code 
								AND ware_code = l_rec_pickdetl2.ware_code 
								AND pick_num = l_rec_pickdetl2.pick_num 
								AND order_num = l_rec_pickdetl2.order_num 
								AND order_line_num = l_rec_pickdetl2.order_line_num 
							END IF 
						END IF 
					END FOREACH 

					INSERT INTO pickhead VALUES (l_rec_pickhead.*) 
					DECLARE c_picklist cursor FOR 
					SELECT unique order_num FROM pickdetl 
					WHERE cmpy_code = l_rec_pickhead.cmpy_code 
					AND ware_code = l_rec_pickhead.ware_code 
					AND pick_num = l_rec_pickhead.pick_num 

					FOREACH c_picklist INTO l_rec_picklist.order_num 
						LET l_err_message = l_rec_pickhead.ware_code,":",	l_rec_pickhead.pick_num USING "<<<<<<<" 

						IF l_verbose_ind THEN 
							CALL insert_log(p_cmpy_code,p_kandoouser_sign_on_code,l_rec_picklist.order_num,45, l_err_message,"") 
						ELSE 
							CALL insert_log(p_cmpy_code,p_kandoouser_sign_on_code,l_rec_picklist.order_num,40, l_err_message,"") 
						END IF 

						SELECT unique 1 FROM orderdetl 
						WHERE order_num = l_rec_picklist.order_num 
						AND cmpy_code = p_cmpy_code 
						AND inv_qty <> 0 
						IF status = NOTFOUND THEN 
							UPDATE orderhead SET status_ind = "U" 
							WHERE order_num = l_rec_picklist.order_num 
							AND cmpy_code = p_cmpy_code 
							AND status_ind = "X" 
						ELSE 
							UPDATE orderhead SET status_ind = "P" 
							WHERE order_num = l_rec_picklist.order_num 
							AND cmpy_code = p_cmpy_code 
							AND status_ind = "X" 
						END IF 
					END FOREACH
					 
				COMMIT WORK
				 
				WHENEVER ERROR stop 
				--LET l_page_num = 0 
				OUTPUT TO REPORT E52_rpt_list_picklist(l_rec_pickhead.*) 
				
				IF p_flat_file THEN 
					OUTPUT TO REPORT E52_rpt_list_flat_file(l_rec_pickhead.*) 
				END IF 
			END FOREACH 
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT E52_rpt_list_picklist
		CALL rpt_finish("E52_rpt_list_picklist")
		#------------------------------------------------------------		
		
		IF p_flat_file THEN 
			#------------------------------------------------------------
			FINISH REPORT E52_rpt_list_flat_file
			CALL rpt_finish("E52_rpt_list_flat_file")
			#------------------------------------------------------------
		END IF 

	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
--		RETURN l__output 
END FUNCTION
###########################################################################
# END FUNCTION create_picklist(p_cmpy_code, p_kandoouser_sign_on_code, p_ware_code, 
###########################################################################