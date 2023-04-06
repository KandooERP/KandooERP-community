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
# Purpose - MRP
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M53_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE pr_mrp RECORD LIKE mrp.* 
DEFINE pr_product RECORD LIKE product.* 
DEFINE rpt_length_e SMALLINT 
DEFINE rpt_length_p SMALLINT 
DEFINE rpt_wid_e SMALLINT 
DEFINE rpt_wid_p SMALLINT 
DEFINE rpt_pageno_e SMALLINT 
DEFINE rpt_pageno_p SMALLINT 
DEFINE fv_output_e CHAR(60) 
DEFINE fv_output_p CHAR(60) 
############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M53") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET rpt_wid = 132 

	OPEN WINDOW wm135 with FORM "M135" 
	CALL  windecoration_m("M135") -- albo kd-762 

	LET pv_mrp_plan = arg_val(1) 
	LET pv_scrap_ind = arg_val(2) 

	CALL work_out_ros() 
	CALL print_report(pv_scrap_ind) 

END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION work_out_ros()
#
#
############################################################
FUNCTION work_out_ros() 

	DEFINE 
	fv_old_part LIKE prodmfg.part_code, 
	fv_due_date LIKE mrp.due_date, 
	fv_to_order LIKE prodstatus.onhand_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_critical_qty LIKE prodstatus.critical_qty, 
	fv_seq SMALLINT 


	DECLARE mrp_curs CURSOR FOR 
	SELECT * 
	FROM mrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mrp_plan 
	ORDER BY part_code, due_date 

	LET fv_old_part = "XXXXXXXXXX" 

	OPEN WINDOW w1_m35 at 14,8 with 3 ROWS, 56 COLUMNS 
	attributes (white,border) 

	FOREACH mrp_curs INTO pr_mrp.* 
		IF NOT pv_background THEN 
			CALL working("Work out ROs",pr_mrp.part_code) 
		END IF 

		IF pr_mrp.part_code != fv_old_part THEN 
			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO fv_onhand_qty, fv_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mrp.part_code 

			IF status = notfound THEN 
				LET fv_onhand_qty = 0 
				LET fv_critical_qty = 0 
			END IF 

			IF fv_onhand_qty IS NULL THEN 
				LET fv_onhand_qty = 0 
			END IF 

			IF fv_critical_qty IS NULL THEN 
				LET fv_critical_qty = 0 
			END IF 

			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mrp.part_code 

			IF status = notfound THEN 
				LET pr_product.min_ord_qty = 0 
			END IF 

			LET fv_due_date = pr_mrp.due_date 
			LET fv_old_part = pr_mrp.part_code 
			LET fv_seq = 0 
		END IF 

		IF pr_mrp.type_text = "PO" THEN 
			LET fv_onhand_qty = fv_onhand_qty + pr_mrp.required_qty 
			LET fv_seq = fv_seq + 1 
			CALL insert_into_report(pr_mrp.*, fv_seq, fv_onhand_qty,0) 
			CONTINUE FOREACH 
		END IF 

		LET fv_onhand_qty = fv_onhand_qty - pr_mrp.required_qty 
		LET fv_seq = fv_seq + 1 

		CALL insert_into_report(pr_mrp.*, fv_seq, fv_onhand_qty,0) 

		IF fv_onhand_qty < 0 
		OR fv_onhand_qty < fv_critical_qty THEN 
			LET fv_due_date = pr_mrp.due_date 
			LET pr_mrp.type_text = "RP" 

			IF fv_onhand_qty < fv_critical_qty THEN 
				LET pr_mrp.required_qty = fv_critical_qty - fv_onhand_qty 
			END IF 

			IF pr_mrp.required_qty < 0 THEN 
				LET pr_mrp.required_qty = fv_onhand_qty * -1 
			END IF 

			LET fv_to_order = pr_mrp.required_qty 
			LET pr_product.min_ord_qty = pr_product.min_ord_qty * 
			pr_product.pur_stk_con_qty 

			IF pr_product.min_ord_qty > pr_mrp.required_qty THEN 
				LET fv_to_order = pr_product.min_ord_qty 
			END IF 

			LET fv_onhand_qty = fv_onhand_qty + fv_to_order 
			LET pr_mrp.start_date = get_cal_date( pr_mrp.due_date, 
			pr_product.days_lead_num, 
			"B") 

			### ****** M U S T   D O   O R D E R   I N C R E M E N T S *******

			LET fv_seq = fv_seq + 1 

			CALL insert_into_report(pr_mrp.*, fv_seq, fv_onhand_qty,fv_to_order) 
		END IF 
	END FOREACH 
	FREE mrp_curs 

END FUNCTION 
############################################################
# END FUNCTION work_out_ros()
############################################################


############################################################
# FUNCTION insert_into_report(fr_mrp, fv_seq, fv_onhand_qty, fv_to_order)
#
#
############################################################
FUNCTION insert_into_report(fr_mrp, fv_seq, fv_onhand_qty, fv_to_order) 

	DEFINE 
	fr_mrp RECORD LIKE mrp.*, 
	fv_seq SMALLINT, 
	fv_part_desc LIKE product.desc_text, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_to_order LIKE prodstatus.onhand_qty, 
	fv_order_qty LIKE prodstatus.onhand_qty, 
	fv_lead_time LIKE product.days_lead_num 


	SELECT desc_text 
	INTO fv_part_desc 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_mrp.part_code 

	IF status = notfound THEN 
		LET fv_part_desc = "No Product RECORD Found" 
	END IF 

	IF fr_mrp.type_text = "RP" THEN 
		LET fv_order_qty = fv_to_order 

		SELECT * 
		FROM mrptable 
		WHERE part_code = fr_mrp.part_code 
		AND reference_num = fr_mrp.reference_num 
		AND due_date = fr_mrp.due_date 
		AND type_text = "ZP" 

		IF status != 0 THEN 
			INSERT INTO mrptable VALUES ("", 
			"", 
			fr_mrp.part_code, 
			fv_part_desc, 
			fr_mrp.reference_num, 
			"ZP", 
			fr_mrp.required_qty, 
			fr_mrp.due_date, 
			fr_mrp.start_date, 
			fv_onhand_qty, 
			fv_order_qty, 
			fv_seq, 
			fv_lead_time) 
		ELSE 
			UPDATE mrptable 
			SET required_qty = required_qty + fr_mrp.required_qty, 
			ordered_qty = ordered_qty + fv_order_qty, 
			on_hand_qty = on_hand_qty + fv_onhand_qty 
			WHERE part_code = fr_mrp.part_code 
			AND reference_num = fr_mrp.reference_num 
			AND due_date = fr_mrp.due_date 
			AND type_text = "ZP" 
		END IF 

		SELECT * 
		FROM mpsdemand 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mrp_plan 
		AND parent_part_code = fr_mrp.part_code 
		AND part_code = fr_mrp.part_code 
		AND due_date = fr_mrp.due_date 
		AND type_text = "RP" 

		IF status != 0 THEN 
			INSERT INTO mpsdemand VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mrp_plan, 
			fr_mrp.part_code, 
			fr_mrp.part_code, 
			fr_mrp.start_date, 
			fr_mrp.due_date, 
			"RP", 
			fv_order_qty, 
			fr_mrp.reference_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 

		ELSE 
			UPDATE mpsdemand 
			SET required_qty = required_qty + fv_order_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mrp_plan 
			AND parent_part_code = fr_mrp.part_code 
			AND part_code = fr_mrp.part_code 
			AND due_date = fr_mrp.due_date 
			AND type_text = "RP" 
		END IF 
	ELSE 
		LET fv_order_qty = 0 

		SELECT * 
		FROM mrptable 
		WHERE part_code = fr_mrp.part_code 
		AND due_date = fr_mrp.due_date 
		AND type_text = fr_mrp.type_text 
		AND reference_num = fr_mrp.reference_num 

		IF status != 0 THEN 
			INSERT INTO mrptable VALUES ("", 
			"", 
			fr_mrp.part_code, 
			fv_part_desc, 
			fr_mrp.reference_num, 
			fr_mrp.type_text, 
			fr_mrp.required_qty, 
			fr_mrp.due_date, 
			fr_mrp.start_date, 
			fv_onhand_qty, 
			fv_order_qty, 
			fv_seq, 
			fv_lead_time) 
		ELSE 
			UPDATE mrptable 
			SET required_qty = required_qty + fr_mrp.required_qty, 
			ordered_qty = ordered_qty + fv_order_qty, 
			on_hand_qty = on_hand_qty + fv_onhand_qty 
			WHERE part_code = fr_mrp.part_code 
			AND reference_num = fr_mrp.reference_num 
			AND due_date = fr_mrp.due_date 
			AND type_text = fr_mrp.type_text 
		END IF 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION insert_into_report(fr_mrp, fv_seq, fv_onhand_qty, fv_to_order)
############################################################


############################################################
# FUNCTION print_report(fv_scrap_ind)
#
#
############################################################
FUNCTION print_report(fv_scrap_ind) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_scrap_ind CHAR(1), 
	fv_security LIKE kandoouser.security_ind, 
	fr_report RECORD 
		ware_code CHAR(3), 
		ware_desc_text CHAR(30), 
		part_code CHAR(15), 
		part_desc_text CHAR(20), 
		reference_num INTEGER, 
		type_text CHAR(3), 
		required_qty FLOAT, 
		due_date DATE, 
		start_date DATE, 
		on_hand_qty FLOAT, 
		ordered_qty FLOAT, 
		seq_num INTEGER, 
		lead_time INTEGER 
	END RECORD 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("M53-PEGGING","M53_rpt_list_mrp_pegging","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M53_rpt_list_mrp_pegging TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("M53-ERROR","M53_rpt_list_mrp_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M53_rpt_list_mrp_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE report_cursor CURSOR FOR 
	SELECT * 
	FROM mrptable --> mrptable TABLE IS NOT in the kandoodb DATABASE -- albo 
	ORDER BY ware_code, part_code, 
	seq_num, due_date, 
	start_date, type_text 

	FOREACH report_cursor INTO fr_report.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT M53_rpt_list_mrp_pegging(l_rpt_idx,
		glob_rec_kandoouser.cmpy_code,fv_scrap_ind,fr_report.*) 
		#---------------------------------------------------------		

		IF fr_report.ordered_qty != 0	AND fr_report.ordered_qty IS NOT NULL THEN 
 
			#---------------------------------------------------------
			OUTPUT TO REPORT M53_rpt_list_mrp_exception(l_rpt_idx,
			glob_rec_kandoouser.cmpy_code,fv_scrap_ind,fr_report.*) 
			#---------------------------------------------------------	

		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M53_rpt_list_mrp_pegging
	CALL rpt_finish("M53_rpt_list_mrp_pegging")
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT M53_rpt_list_mrp_exception
	CALL rpt_finish("M53_rpt_list_mrp_exception")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION print_report(fv_scrap_ind)
############################################################


############################################################
# REPORT M53_rpt_list_mrp_pegging(p_rpt_idx, rp_cmpy, fv_scrap_ind, rp_ware_code, rp_ware_desc, 
#	rp_part_code, rp_part_desc, rp_reference, rp_type, 
#	rp_required, rp_due_date, rp_start_date, rp_soh, 
#	rp_ordered,rp_seq_num, rp_lead_time) 
#
# REPORT TO list out the details of how the MPS came about
############################################################
REPORT M53_rpt_list_mrp_pegging(p_rpt_idx, rp_cmpy, fv_scrap_ind, rp_ware_code, rp_ware_desc, 
	rp_part_code, rp_part_desc, rp_reference, rp_type, 
	rp_required, rp_due_date, rp_start_date, rp_soh, 
	rp_ordered,rp_seq_num, rp_lead_time) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rp_cmpy CHAR(2), 
	rp_ware_code CHAR(3), 
	fv_scrap_ind CHAR(1), 
	rp_ware_desc LIKE warehouse.desc_text, 
	rp_part_code LIKE mrp.part_code, 
	rp_part_desc CHAR(20), 
	rpt_line1 CHAR(132), 
	rpt_line2 CHAR(132), 
	rpt_line3,dummy CHAR(132), 
	rp_reference LIKE mrp.reference_num, 
	rp_type CHAR(3), 
	rp_required LIKE shoporddetl.required_qty, 
	rp_due_date LIKE mrp.due_date, 
	rp_start_date LIKE mrp.start_date, 
	rp_soh LIKE prodstatus.onhand_qty, 
	rp_critical_qty LIKE prodstatus.critical_qty, 
	rp_min_ord_qty LIKE product.min_ord_qty, 
	rp_ordered LIKE mrp.required_qty, 
	rp_seq_num INTEGER, 
	rp_lead_time INTEGER, 
	rv_cmpy_name LIKE company.name_text, 
	rv_title CHAR(132), 
	rv_position SMALLINT, 
	rv_act CHAR(10), 
	rv_stk_uom LIKE product.stock_uom_code, 
	rv_onhand LIKE prodstatus.onhand_qty 

	OUTPUT 
	top margin 2 
	left margin 0 
	bottom margin 6 

	ORDER external BY rp_cmpy, rp_ware_code, rp_part_code, rp_start_date, 
	rp_due_date, rp_type 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 1, "Plan : ", pv_mrp_plan," ", pv_mrp_desc, 
			COLUMN 60, "MPS : ", pv_mps_plan, 
			COLUMN 80, "Scrap/Yield (S=Scrap,Y=Yield,B=Both,N=None): ", 
			fv_scrap_ind 
		
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 4, "Item", 
			COLUMN 52, "Ref.", 
			COLUMN 64, "Due", 
			COLUMN 75, "Recommended", 
			COLUMN 92, "Required", 
			COLUMN 108, "Qty TO", 
			COLUMN 124, "Projected" 
			PRINT COLUMN 4, "Code", 
			COLUMN 21, "Description", 
			COLUMN 52, "Number", 
			COLUMN 59, "Type", 
			COLUMN 64, "Date", 
			COLUMN 75, "Purch Date", 
			COLUMN 92, "Quantity", 
			COLUMN 108, "Purchase", 
			COLUMN 127, "Stock" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT 


		BEFORE GROUP OF rp_part_code 

			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO rv_onhand, rp_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			SELECT stock_uom_code 
			INTO rv_stk_uom 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			SELECT sum(min_ord_qty) 
			INTO rp_min_ord_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			PRINT COLUMN 1, rp_part_code clipped, 
			COLUMN 17, rp_part_desc clipped, 
			COLUMN 37, " UoM:" clipped, 
			COLUMN 42, rv_stk_uom clipped, 
			COLUMN 50, " Critical Stock:" clipped, 
			COLUMN 68, rp_critical_qty USING "---------&.&&&&", 
			COLUMN 85, " Minimum Reorder:" clipped, 
			COLUMN 102, rp_min_ord_qty USING "---------&.&&&&", 
			COLUMN 118, rv_onhand USING "---------&.&&&&" 

		ON EVERY ROW 
			IF rp_start_date < today THEN 
				LET rv_act = "Expedite" 
			END IF 
			IF rp_start_date > today THEN 
				LET rv_act = "Delay" 
			END IF 
			IF rp_start_date = today THEN 
				LET rv_act = "Purchase" 
			END IF 

			IF rp_type = "ZP" THEN 
				LET rp_type = "RP" 
			END IF 

			IF rp_type = "PO" THEN 
				LET rv_act = " " 
				IF rp_due_date < today THEN 
					LET rv_act = "Past Due" 
				END IF 
			END IF 

			PRINT COLUMN 52, rp_reference USING "#####&", 
			COLUMN 59, rp_type clipped, 
			COLUMN 64, rp_due_date USING "dd/mm/yyyy", 
			COLUMN 75, rp_start_date USING "dd/mm/yyyy", 
			COLUMN 87, rp_required USING "---------&.&&&&", 
			COLUMN 102, rp_ordered USING "---------&.&&&&", 
			COLUMN 118, rp_soh USING "---------&.&&&&" 

		AFTER GROUP OF rp_part_code 
			PRINT 

		ON LAST ROW 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
############################################################
# REPORT M53_rpt_list_mrp_pegging(p_rpt_idx, rp_cmpy, fv_scrap_ind, rp_ware_code, rp_ware_desc, 
#	rp_part_code, rp_part_desc, rp_reference, rp_type, 
#	rp_required, rp_due_date, rp_start_date, rp_soh, 
#	rp_ordered,rp_seq_num, rp_lead_time) 
#
# REPORT TO list out the details of how the MPS came about
############################################################


############################################################
# REPORT M53_rpt_list_mrp_exception(p_rpt_idx,rp_cmpy,fv_scrap_ind,rp_ware_code,rp_ware_desc, 
#	rp_part_code, 
#	rp_part_desc, rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, rp_seq_num, 
#	rp_lead_time) 
#
# REPORT TO list out the exception details
############################################################
REPORT M53_rpt_list_mrp_exception(p_rpt_idx,rp_cmpy,fv_scrap_ind,rp_ware_code,rp_ware_desc, 
	rp_part_code, 
	rp_part_desc, rp_reference, rp_type, rp_required, 
	rp_due_date, rp_start_date, rp_soh, rp_ordered, rp_seq_num, 
	rp_lead_time) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rp_cmpy CHAR(2), 
	rp_ware_code CHAR(3), 
	fv_scrap_ind CHAR(1), 
	rp_ware_desc LIKE warehouse.desc_text, 
	rp_part_code LIKE mrp.part_code, 
	rpt_line1 CHAR(132), 
	rpt_line2 CHAR(132), 
	rpt_line3,dummy CHAR(132), 
	rp_part_desc CHAR(20), 
	rp_reference LIKE mrp.reference_num, 
	rp_type CHAR(3), 
	rp_critical_qty LIKE prodstatus.critical_qty, 
	rp_min_ord_qty LIKE product.min_ord_qty, 
	rp_required LIKE shoporddetl.required_qty, 
	rp_due_date LIKE mrp.due_date, 
	rp_start_date LIKE mrp.start_date, 
	rp_soh LIKE prodstatus.onhand_qty, 
	rp_ordered LIKE mrp.required_qty, 
	rp_seq_num INTEGER, 
	rp_lead_time INTEGER, 
	rv_act CHAR(8), 
	rv_job_length INTEGER, 
	rv_stk_uom LIKE product.stock_uom_code, 
	rv_lead_time LIKE product.days_lead_num, 
	rv_cmpy_name LIKE company.name_text, 
	rv_title CHAR(132), 
	rv_position SMALLINT 

	OUTPUT 


	ORDER external BY rp_cmpy,rp_ware_code,rp_part_code,rp_start_date, rp_due_date,rp_type 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT 
			PRINT COLUMN 1, "Plan : ", pv_mrp_plan," ", pv_mrp_desc, 
			COLUMN 60, "MPS : ", pv_mps_plan, 
			COLUMN 80, "Scrap/Yield (S=Scrap,Y=Yield,B=Both,N=None): ", 
			fv_scrap_ind 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 4, "Item", 
			COLUMN 52, "Ref.", 
			COLUMN 64, "Due", 
			COLUMN 75, "Scheduled", 
			COLUMN 90, "Required", 
			COLUMN 108, "Qty TO " 
			PRINT COLUMN 4, "Code", 
			COLUMN 21, "Description", 
			COLUMN 52, "Number", 
			COLUMN 59, "Type", 
			COLUMN 64, "Date", 
			COLUMN 75, "Start Date", 
			COLUMN 90, "Quantity", 
			COLUMN 108, "Purchase", 
			COLUMN 118, "Action" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 

		BEFORE GROUP OF rp_part_code 
			SELECT days_lead_num, stock_uom_code 
			INTO rv_lead_time, rv_stk_uom 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			IF status = notfound THEN 
				LET rv_lead_time = 0 
				LET rv_stk_uom = "EA " 
			END IF 

			SELECT sum(critical_qty) 
			INTO rp_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			SELECT sum(min_ord_qty) 
			INTO rp_min_ord_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			PRINT COLUMN 1, rp_part_code clipped, 
			COLUMN 17, rp_part_desc clipped, 
			COLUMN 37, " UoM:" clipped, 
			COLUMN 42, rv_stk_uom clipped, 
			COLUMN 50, " Critical Stock:" clipped, 
			COLUMN 68, rp_critical_qty USING "---------&.&&&&", 
			COLUMN 85, " Minimum Reorder:" clipped, 
			COLUMN 102, rp_min_ord_qty USING "---------&.&&&&" 

			IF rv_lead_time IS NULL THEN 
				LET rv_lead_time = 0 
			END IF 

		ON EVERY ROW 
			IF rp_start_date < today THEN 
				LET rv_act = "Expedite" 
			END IF 
			IF rp_start_date > today THEN 
				LET rv_act = "Delay" 
			END IF 
			IF rp_start_date = today THEN 
				LET rv_act = "Purchase" 
			END IF 

			IF rp_type = "ZP" THEN 
				LET rp_type = "RP" 
			END IF 

			IF rp_type = "PO" THEN 
				LET rv_act = " " 
				IF rp_due_date < today THEN 
					LET rv_act = "Past Due" 
				END IF 
			END IF 

			PRINT COLUMN 52, rp_reference USING "#####&", 
			COLUMN 59, rp_type clipped, 
			COLUMN 64, rp_due_date USING "dd/mm/yyyy", 
			COLUMN 75, rp_start_date USING "dd/mm/yyyy", 
			COLUMN 87, rp_required USING "---------&.&&&&", 
			COLUMN 102, rp_ordered USING "---------&.&&&&", 
			COLUMN 118, rv_act 

		AFTER GROUP OF rp_part_code 
			PRINT 

		ON LAST ROW 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
############################################################
# END REPORT M53_rpt_list_mrp_exception(p_rpt_idx,rp_cmpy,fv_scrap_ind,rp_ware_code,rp_ware_desc, 
#	rp_part_code, 
#	rp_part_desc, rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, rp_seq_num, 
#	rp_lead_time) 
#
# REPORT TO list out the exception details
############################################################