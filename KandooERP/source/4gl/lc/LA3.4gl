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
# Receipt REPORT FOR goods receipts in shipments
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LA_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LA3_GLOBALS.4gl" 
GLOBALS 
--	DEFINE 
--	rpt_note LIKE rmsreps.report_text, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_pageno LIKE rmsreps.page_num, 
--	pr_output CHAR(20), 
--	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
--	pr_company RECORD LIKE company.*, 
	DEFINE query_text STRING
	DEFINE where_part STRING 
--	rpt_date LIKE rmsreps.report_date, 
--	rpt_time CHAR(8), 
--	line1, line2 CHAR(120), 
	DEFINE ret_code INTEGER 
	DEFINE i SMALLINT 
	DEFINE loop_flag, col, col2 SMALLINT 
--	DEFINE cmpy_head CHAR(132) 
	DEFINE rec_count SMALLINT 
	DEFINE pr_last_ship_code LIKE shiphead.ship_code 
END GLOBALS 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA3") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW l143 with FORM "L143" 
	CALL windecoration_l("L143") -- albo kd-763 

	LET loop_flag = true 
	WHILE loop_flag 
		MENU " Shipment Receipts" 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
--				LET rpt_head = true 
				IF LA3_rpt_query() THEN 
					NEXT option "Print Manager" 
	--				LET rpt_note = NULL 
				END IF 

			ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 


			COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
				LET loop_flag = false 
				EXIT MENU 

		END MENU 

	END WHILE 
	CLOSE WINDOW l143 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION LA3_rpt_query() 
#
#
###########################################################################
FUNCTION LA3_rpt_query()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	pr_tempdoc RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		goods_receipt_text LIKE shiphead.goods_receipt_text, 
		receipt_date LIKE shiprec.recpt_date, 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num , 
		doc_line_num LIKE shipdetl.doc_line_num , 
		job_code LIKE shipdetl.job_code , 
		var_code LIKE shipdetl.var_code, 
		activity_code LIKE shipdetl.activity_code , 
		trans_qty LIKE shiprec.trans_qty, 
		trans_amt LIKE shiprec.trans_amt, 
		vend_code LIKE shiphead.vend_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE shipdetl.desc_text, 
		ship_type_ind LIKE shiphead.ship_type_ind 
	END RECORD 

	WHILE true # SET up loop 
		MESSAGE" Enter Selection Criteria - ESC TO Continue" 
		attribute(yellow) 
		CONSTRUCT BY NAME where_part ON 
		shiphead.vend_code, 
		shiphead.ship_code, 
		shiphead.ship_type_code, 
		shiphead.eta_curr_date, 
		shiphead.vessel_text, 
		shiphead.discharge_text, 
		shiphead.ware_code, 
		shiphead.ship_status_code, 
		shiprec.goods_receipt_text, 
		shiprec.recpt_date, 
		shipdetl.part_code, 
		shipdetl.desc_text, 
		shipdetl.ship_type_ind 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		
		#------------------------------------------------------------
		#User pressed CANCEL = p_where_text IS NULL
		IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
			LET int_flag = false 
			LET quit_flag = false
	
			RETURN FALSE
		END IF
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"LA3_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT LA3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
		#------------------------------------------------------------

		LET query_text = "SELECT ", 
		" shiphead.ship_code, ", 
		" shiphead.ship_type_code, ", 
		" shiprec.goods_receipt_text, ", 
		" shiprec.recpt_date, ", 
		" shipdetl.line_num, ", 
		" shipdetl.part_code, ", 
		" shipdetl.source_doc_num ,", 
		" shipdetl.doc_line_num ,", 
		" shipdetl.job_code ,", 
		" shipdetl.var_code ,", 
		" shipdetl.activity_code ,", 
		" shiprec.trans_qty, ", 
		" shiprec.trans_amt, ", 
		" shiphead.vend_code, ", 
		" shiphead.ware_code, ", 
		" shipdetl.desc_text, ", 
		" shiphead.ship_type_ind ", 
		" FROM shiphead, shipdetl, outer shiprec ", 
		" WHERE shiphead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiprec.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shipdetl.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiphead.ship_code = shipdetl.ship_code ", 
		" AND shiphead.ship_code = shiprec.ship_code ", 
		" AND shipdetl.line_num = shiprec.line_num ", 
		#" AND shiphead.ship_type_ind = 1 ",
		" AND ", where_part clipped, 
		" ORDER BY shiphead.ship_code, ", 
		" shiprec.goods_receipt_text, shipdetl.line_num " 
		PREPARE s_invoice FROM query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 

		DISPLAY " Reporting on Shipment..." at 1,1 
		DISPLAY " Receipt...." at 2,1 
		FOREACH c_invoice INTO pr_tempdoc.* 
			#DISPLAY pr_tempdoc.ship_code at 1,25 
			#DISPLAY pr_tempdoc.goods_receipt_text at 2,25 

			#---------------------------------------------------------
			OUTPUT TO REPORT LA3_rpt_list(l_rpt_idx,
			pr_tempdoc.*) 
			#---------------------------------------------------------

		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT LA3_rpt_list
		CALL rpt_finish("LA3_rpt_list")
		#------------------------------------------------------------
		
		EXIT WHILE 
		
	END WHILE
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION END LA3_rpt_query() 
###########################################################################


###########################################################################
# REPORT LA3_rpt_list(p_rpt_idx,pr_tempdoc)
#
#
###########################################################################
REPORT LA3_rpt_list(p_rpt_idx,pr_tempdoc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_tempdoc RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		goods_receipt_text LIKE shiphead.goods_receipt_text, 
		receipt_date LIKE shiprec.recpt_date, 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num , 
		doc_line_num LIKE shipdetl.doc_line_num , 
		job_code LIKE shipdetl.job_code , 
		var_code LIKE shipdetl.var_code, 
		activity_code LIKE shipdetl.activity_code , 
		trans_qty LIKE shiprec.trans_qty, 
		trans_amt LIKE shiprec.trans_amt, 
		vend_code LIKE shiphead.vend_code, 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE shipdetl.desc_text, 
		ship_type_ind LIKE shiphead.ship_type_ind 
	END RECORD, 
	pr_period RECORD LIKE period.*, 
	pr_vend_name LIKE vendor.name_text, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	idx, s, len, pr_inv_count, pr_inv_line SMALLINT, 
	pr_sum_amt, pr_total_amt LIKE shiprec.total_amt, 
	pr_sum_qty, pr_total_qty LIKE shiprec.total_qty, 
	pr_line_num LIKE shipdetl.line_num, 
	pr_unit_cost LIKE shipdetl.fob_unit_ent_amt, 
	str CHAR (4000) 

	OUTPUT 

	ORDER external BY pr_tempdoc.ship_code, 
	pr_tempdoc.goods_receipt_text, 
	pr_tempdoc.line_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
					
--			LET rpt_head = true 

			PRINT COLUMN 20, "Line", 
			COLUMN 85, "------- Receipt -------" 
			PRINT COLUMN 19, "Number", 
			COLUMN 29, "Details", 
			COLUMN 53, "Description", 
			COLUMN 85, "Quantity", 
			COLUMN 102, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_tempdoc.ship_code 
			SKIP 1 LINES 
			CASE 
				WHEN pr_tempdoc.ship_type_ind = 1 OR 
					pr_tempdoc.ship_type_ind = 2 
					LET pr_vend_name = " " 
					SELECT name_text 
					INTO pr_vend_name 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_tempdoc.vend_code 
					PRINT COLUMN 1, "Shipment: ", 
					COLUMN 12, pr_tempdoc.ship_code clipped, "/", 
					pr_tempdoc.ship_type_code, 
					COLUMN 23, "Vendor: ", 
					COLUMN 31, pr_tempdoc.vend_code, 
					COLUMN 44, pr_vend_name 
				WHEN pr_tempdoc.ship_type_ind = 3 
					LET pr_vend_name = " " 
					SELECT name_text 
					INTO pr_vend_name 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_tempdoc.vend_code 
					PRINT COLUMN 1, "Shipment: ", 
					COLUMN 12, pr_tempdoc.ship_code clipped, "/", 
					pr_tempdoc.ship_type_code, 
					COLUMN 23, "Customer: ", 
					COLUMN 31, pr_tempdoc.vend_code, 
					COLUMN 44, pr_vend_name 
			END CASE 
			SKIP 1 LINES 
			LET rec_count = 0 
			LET pr_last_ship_code = pr_tempdoc.ship_code 
		BEFORE GROUP OF pr_tempdoc.goods_receipt_text 
			NEED 2 LINES 
			PRINT COLUMN 10, "Receipt Number: ", 
			COLUMN 27, pr_tempdoc.goods_receipt_text, 
			COLUMN 38, "Date: ", 
			COLUMN 44, pr_tempdoc.receipt_date USING "DD/MM/YY" 
			LET rec_count = rec_count + 1 
		AFTER GROUP OF pr_tempdoc.goods_receipt_text 
			SKIP 1 LINES 
		AFTER GROUP OF pr_tempdoc.ship_code 
			IF rec_count > 1 THEN 
				LET idx = 1 


				DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
				DISPLAY "see lc/LA3.4gl" 
				EXIT program (1) 


				LET str = 
				" SELECT d.line_num, d.fob_unit_ent_amt, ", 
				" sum(r.trans_qty), sum(r.trans_amt) ", 
				" FROM shipdetl d, outer shiprec r ", 
				" WHERE d.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
				" AND d.ship_code = ", pr_last_ship_code, 
				" AND r.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
				" AND r.ship_code = ", pr_last_ship_code, 
				" AND d.cmpy_code = r.cmpy_code ", 
				" AND d.ship_code = r.ship_code ", 
				" AND d.line_num = r.line_num ", 
				" group by d.line_num, d.fob_unit_ent_amt ", 
				" ORDER BY d.line_num " 


				PREPARE ttt FROM str 
				DECLARE xcurs CURSOR FOR ttt 
				FOREACH xcurs INTO 
					pr_line_num, pr_unit_cost, pr_sum_qty, pr_sum_amt 
					IF idx = 1 THEN 
						SKIP 1 LINES 
						PRINT COLUMN 15, "Totals : " 
						LET idx = 2 
					END IF 
					IF pr_sum_amt IS NULL THEN 
						LET pr_sum_amt = 0 
					END IF 
					IF pr_sum_qty IS NULL THEN 
						LET pr_sum_qty = 0 
					END IF 
					IF pr_unit_cost = 0 THEN 
						LET pr_total_qty = pr_sum_qty 
					ELSE 
						LET pr_total_qty = pr_sum_qty + (pr_sum_amt / pr_unit_cost) 
					END IF 
					LET pr_total_amt = pr_sum_amt + (pr_sum_qty * pr_unit_cost) 
					PRINT COLUMN 20, pr_line_num USING "###", 
					COLUMN 85, pr_total_qty USING "------.&&", 
					COLUMN 95, pr_total_amt USING "-----------.&&" 
				END FOREACH 
			END IF 

		ON EVERY ROW 
			CASE 
				WHEN pr_tempdoc.part_code IS NOT NULL 
					PRINT COLUMN 20, pr_tempdoc.line_num USING "###", 
					COLUMN 28, pr_tempdoc.part_code, 
					COLUMN 53, pr_tempdoc.desc_text, 
					COLUMN 85, pr_tempdoc.trans_qty USING "------.&&", 
					COLUMN 95, pr_tempdoc.trans_amt USING "-----------.&&" 
				WHEN pr_tempdoc.job_code IS NOT NULL 
					PRINT COLUMN 20, pr_tempdoc.line_num USING "###", 
					COLUMN 28, pr_tempdoc.job_code, 
					COLUMN 38, pr_tempdoc.var_code USING "####", 
					COLUMN 43, pr_tempdoc.activity_code, 
					COLUMN 53, pr_tempdoc.desc_text, 
					COLUMN 85, pr_tempdoc.trans_qty USING "------.&&", 
					COLUMN 95, pr_tempdoc.trans_amt USING "-----------.&&" 
				OTHERWISE 
					PRINT COLUMN 20, pr_tempdoc.line_num USING "###", 
					COLUMN 53, pr_tempdoc.desc_text, 
					COLUMN 85, pr_tempdoc.trans_qty USING "------.&&", 
					COLUMN 95, pr_tempdoc.trans_amt USING "-----------.&&" 
			END CASE 

		ON LAST ROW 
			SKIP 5 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				

END REPORT 
###########################################################################
# END REPORT LA3_rpt_list(p_rpt_idx,pr_tempdoc)
###########################################################################