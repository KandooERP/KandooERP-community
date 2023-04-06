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
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M51_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	rpt_note CHAR(80), 
	pv_non_part_desc LIKE shoporddetl.desc_text, 
	pv_mps_plan LIKE mps.plan_code, 
	pv_mrp_plan LIKE mrp.plan_code, 
	pv_mps_desc LIKE mps.desc_text, 
	pv_mrp_desc LIKE mrp.desc_text, 
	pv_end_date DATE, 
	pv_background SMALLINT, 
	pv_found_error SMALLINT, 
	pv_errormsg CHAR(100), 
	pv_tot_sel SMALLINT, 
	pv_tot_left SMALLINT, 

	rpt_pageno SMALLINT, 
	rpt_pageno1 SMALLINT, 
	rpt_length SMALLINT, 
	rpt_length1 SMALLINT, 
	pr_kandooreport1 RECORD LIKE kandooreport.* 

END GLOBALS 

DEFINE 
pr_output_e CHAR(100), 
pr_output_p CHAR(100), 
rpt_pageno_e SMALLINT, 
rpt_pageno_p SMALLINT, 
line1 CHAR(132), 
line2 CHAR(132), 
offset1 SMALLINT, 
offset2 SMALLINT 

###########################################################################
# FUNCTION drop_table()
#
# FUNCTION TO create a tempory table FOR the REPORT 
###########################################################################
FUNCTION drop_table() 
	WHENEVER ERROR CONTINUE 
	DROP TABLE mpstable 
END FUNCTION 
###########################################################################
# END FUNCTION drop_table()
###########################################################################


###########################################################################
# FUNCTION create_table() 
#
#  
###########################################################################
FUNCTION create_table() 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE mpstable 
	( ware_code CHAR(3), 
	desc_text CHAR(30), 
	part_code CHAR(15), 
	part_desc_text CHAR(30), 
	reference_num INTEGER, 
	type_code CHAR(3), 
	required_qty FLOAT, 
	due_date DATE, 
	start_date DATE, 
	on_hand_qty FLOAT, 
	ordered_qty FLOAT, 
	seq_num INTEGER, 
	lead_time integer) 
	WHENEVER ERROR stop 
END FUNCTION 
###########################################################################
# END FUNCTION create_table() 
###########################################################################


###########################################################################
# FUNCTION print_report(pv_fence_ind,pv_scrap_ind) 
#
# FUNCTION TO generate the REPORT FOR MPS pegging
###########################################################################
FUNCTION print_report(pv_fence_ind,pv_scrap_ind)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	fr_report RECORD 
		ware_code CHAR(3), 
		ware_desc_text CHAR(30), 
		part_code CHAR(15), 
		part_desc_text CHAR(30), 
		reference_num INTEGER, 
		type_code CHAR(3), 
		required_qty FLOAT, 
		due_date DATE, 
		start_date DATE, 
		on_hand_qty FLOAT, 
		ordered_qty FLOAT, 
		seq_num INTEGER, 
		lead_time INTEGER 
	END RECORD, 

	fr1_report RECORD 
		ware_code CHAR(3), 
		ware_desc_text CHAR(30), 
		part_code CHAR(15), 
		part_desc_text CHAR(30), 
		reference_num INTEGER, 
		type_code CHAR(3), 
		required_qty FLOAT, 
		due_date DATE, 
		start_date DATE, 
		on_hand_qty FLOAT, 
		ordered_qty FLOAT, 
		seq_num INTEGER, 
		lead_time INTEGER 
	END RECORD, 

	pv_fence_ind CHAR(1), 
	pv_scrap_ind CHAR(1), 
	fv_old_part LIKE product.part_code, 
	fv_min_order LIKE product.min_ord_qty, 
	fv_order_qty LIKE prodstatus.onhand_qty, 
	fv_difference LIKE prodstatus.onhand_qty, 
	fv_new_onhand LIKE prodstatus.onhand_qty, 

	fv_lead_time LIKE product.days_lead_num 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("M51-MPS","M51_rpt_list_mps_pegging","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M51_rpt_list_mps_pegging TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("M51-ERROR" ,"M51_rpt_list_mps_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M51_rpt_list_mps_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE report_cursor CURSOR FOR 
	SELECT * 
	FROM mpstable 
	ORDER BY ware_code,part_code,due_date,seq_num 

	LET fv_old_part = "@@@@@@" 
	LET fv_old_part = NULL 


	FOREACH report_cursor INTO fr_report.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT M51_rpt_list_mps_pegging(l_rpt_idx,
		glob_rec_kandoouser.cmpy_code,pv_fence_ind,pv_scrap_ind,fr_report.*) 
		#---------------------------------------------------------
	END FOREACH 

	DECLARE report1_cursor CURSOR FOR 
	SELECT * 
	FROM mpstable 
	WHERE type_code = "RO" 
	ORDER BY ware_code,part_code,due_date,seq_num 

	LET fr1_report.part_code = NULL 

	FOREACH report1_cursor INTO fr_report.* 

		IF fr1_report.part_code IS NULL THEN 
			LET fr1_report.* = fr_report.* 
			LET fr1_report.on_hand_qty = 0 
			LET fr1_report.ordered_qty = 0 
			LET fr1_report.required_qty = 0 
		END IF 

		IF fr1_report.part_code = fr_report.part_code 
		AND fr_report.start_date = fr1_report.start_date 
		AND fr_report.due_date = fr1_report.due_date THEN 
			LET fr1_report.on_hand_qty = fr1_report.on_hand_qty 
			+ fr_report.on_hand_qty 
			LET fr1_report.ordered_qty = fr1_report.ordered_qty 
			+ fr_report.ordered_qty 
			LET fr1_report.required_qty = fr1_report.required_qty 
			+ fr_report.required_qty 
		END IF 

		IF (fr1_report.part_code != fr_report.part_code) 
		OR ((fr1_report.part_code = fr_report.part_code) 
		AND ((fr1_report.due_date != fr_report.due_date) 
		OR (fr1_report.start_date != fr_report.start_date))) 
		THEN 

			#---------------------------------------------------------
			OUTPUT TO REPORT M51_rpt_list_mps_exception(l_rpt_idx,
			glob_rec_kandoouser.cmpy_code,pv_fence_ind,pv_scrap_ind,fr1_report.*) 
			#---------------------------------------------------------
			LET fr1_report.* = fr_report.* 
		END IF 

	END FOREACH 

	#---------------------------------------------------------
	OUTPUT TO REPORT M51_rpt_list_mps_exception(l_rpt_idx,
	glob_rec_kandoouser.cmpy_code,pv_fence_ind,pv_scrap_ind,fr1_report.*) 
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT M51_rpt_list_mps_pegging
	CALL rpt_finish("M51_rpt_list_mps_pegging")
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT M51_rpt_list_mps_exception
	CALL rpt_finish("M51_rpt_list_mps_exception")
	#------------------------------------------------------------

END FUNCTION 
###########################################################################
# END FUNCTION print_report(pv_fence_ind,pv_scrap_ind) 
###########################################################################



###########################################################################
# FUNCTION lookup_cmpy_code()
#
# FUNCTION TO RETURN the name of the specified company  
###########################################################################
FUNCTION lookup_cmpy_code() 
	DEFINE fv_company_name LIKE company.name_text 

	SELECT company.name_text 
	INTO fv_company_name 
	FROM company 
	WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status <> 0 THEN 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("M",9551,"") 
			#ERROR "Company does NOT exist in the database"
			LET fv_company_name = NULL 
		ELSE 
			LET msgresp = kandoomsg("M",9552,"") 
			# ERROR "Duplicate company codes exist in the database"
			LET fv_company_name = NULL 
		END IF 
	END IF 
	RETURN fv_company_name 
END FUNCTION 
###########################################################################
# END FUNCTION lookup_cmpy_code()
###########################################################################


###########################################################################
# FUNCTION get_cal_date(fv_date, fv_num, fv_direction)
#
#
###########################################################################
FUNCTION get_cal_date(fv_date, fv_num, fv_direction) 
	DEFINE 
	fv_old_date DATE, 
	fv_date DATE, 
	fv_date2 DATE, 
	fv_num INTEGER, 
	fv_direction CHAR(1), 
	fv_extra_days INTEGER 

	IF fv_direction = "F" THEN 
		LET fv_date2 = fv_date + fv_num units day 
		LET fv_extra_days = num_days(fv_date,fv_date2) 
	ELSE 
		LET fv_date2 = fv_date - fv_num units day 
		LET fv_extra_days = num_days(fv_date2,fv_date) 
	END IF 

	WHILE fv_extra_days > 0 
		IF fv_direction = "F" THEN 
			LET fv_old_date = fv_date2 
			LET fv_date2 = fv_date2 + (fv_extra_days units day) 
			IF fv_num = 0 THEN 
				LET fv_old_date = fv_date2 
			END IF 
			LET fv_extra_days = num_days(fv_old_date,fv_date2) 
		ELSE 
			LET fv_old_date = fv_date2 
			LET fv_date2 = fv_date2 - (fv_extra_days units day) 
			IF fv_num = 0 THEN 
				LET fv_old_date = fv_date2 
			END IF 
			LET fv_extra_days = num_days(fv_date2,fv_old_date) 
		END IF 
	END WHILE 
	RETURN fv_date2 
END FUNCTION 
###########################################################################
# END FUNCTION get_cal_date(fv_date, fv_num, fv_direction)
###########################################################################


###########################################################################
# FUNCTION num_days(fp_start_date, fp_end_date)
#
#
###########################################################################
FUNCTION num_days(fp_start_date, fp_end_date) 
	DEFINE 
	fp_start_date DATE, 
	fp_end_date DATE, 
	fv_num_days INTEGER 

	IF fp_start_date = fp_end_date THEN 
		SELECT count(*) 
		INTO fv_num_days 
		FROM calendar 
		WHERE calendar_date = fp_start_date 
		AND available_ind = "N" 
	ELSE 
		SELECT count(*) 
		INTO fv_num_days 
		FROM calendar 
		WHERE calendar_date >= fp_start_date 
		AND calendar_date < fp_end_date 
		AND available_ind = "N" 
	END IF 
	RETURN fv_num_days 
END FUNCTION 
###########################################################################
# END FUNCTION num_days(fp_start_date, fp_end_date)
###########################################################################

###########################################################################
# REPORT M51_rpt_list_mps_pegging(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
#	rp_ware_desc, rp_part_code, rp_part_desc, 
#	rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
#	rp_seq, rp_lead_time) 
#
# REPORT TO list out the details of how the MPS came about 
###########################################################################
REPORT M51_rpt_list_mps_pegging(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
	rp_ware_desc, rp_part_code, rp_part_desc, 
	rp_reference, rp_type, rp_required, 
	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
	rp_seq, rp_lead_time) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	fv_uom_code LIKE prodmfg.man_uom_code, 
	rp_cmpy CHAR(2), 
	rp_ware_code CHAR(3), 
	rp_ware_desc LIKE warehouse.desc_text, 
	rp_part_code LIKE mps.part_code, 
	rp_part_desc CHAR(20), 
	rp_reference LIKE mps.reference_num, 
	rp_type LIKE mps.type_text, 
	rp_demand_fence LIKE mps.due_date, 
	rp_plan_fence LIKE mps.due_date, 
	rp_required LIKE shoporddetl.required_qty, 
	rp_due_date LIKE mps.due_date, 
	rp_start_date LIKE mps.start_date, 
	rp_soh LIKE prodstatus.onhand_qty, 
	rp_critical_qty LIKE prodstatus.critical_qty, 
	rp_min_ord_qty LIKE product.min_ord_qty, 
	rp_ordered LIKE mps.required_qty, 
	rp_seq INTEGER, 
	rp_lead_time INTEGER, 
	rv_fence_ind CHAR(1), 
	rv_scrap_ind CHAR(1), 
--	rv_cmpy_name LIKE company.name_text, 
--	rv_title CHAR(132), 
--	rpt_line1 CHAR(132), 
--	rpt_line2 CHAR(132), 
--	rpt_line3 CHAR(132), 
--	rpt_line4 CHAR(132), 
	rv_position SMALLINT, 
	rv_bal_amt LIKE mps.required_qty, 
	rv_job_length INTEGER , 
	rv_act CHAR(8), 
	rv_type_code LIKE prodmfg.part_type_ind, 
	rv_demand_fence LIKE prodmfg.demand_fence_num, 
	rv_plan_fence LIKE prodmfg.plan_fence_num, 
	rv_onhand LIKE mps.required_qty, 
	rv_order_qty LIKE mps.required_qty 

	OUTPUT 

	ORDER external BY rp_ware_code,rp_part_code,rp_due_date,rp_reference,rp_seq 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, "Plan: ", pv_mps_plan," ", pv_mps_desc 
			PRINT COLUMN 4, "Time Fence (O=Orders,F=Forecasts): ",rv_fence_ind, 
			" Scrap/Yield (S=Scrap,Y=Yield,B=Both,N=None): ",rv_scrap_ind, 
			" END Date ", pv_end_date USING "dd/mm/yyyy" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 4, "Item", 
			COLUMN 32, "Ref.", 
			COLUMN 45, "Due", 
			COLUMN 55, "Scheduled ", 
			COLUMN 67, " Job Length ", 
			COLUMN 80, "Required", 
			COLUMN 98, "Quantity", 
			COLUMN 114, "Projected", 
			COLUMN 124, "Action" 
			PRINT COLUMN 4, "Code", 
			COLUMN 16, "Description", 
			COLUMN 32, "Number", 
			COLUMN 39, "Type", 
			COLUMN 45, "Date ", 
			COLUMN 55, "Start Date", 
			COLUMN 67, "- Lead Time ", 
			COLUMN 80, "Quantity", 
			COLUMN 98, "TO ORDER", 
			COLUMN 116, "Stock" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rp_part_code 

			SELECT part_type_ind, demand_fence_num, 
			plan_fence_num, man_uom_code 
			INTO rv_type_code, rv_demand_fence, 
			rv_plan_fence, fv_uom_code 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			IF status = notfound THEN 
				LET rv_type_code = "X" 
			END IF 

			LET rp_demand_fence = today + rv_demand_fence 
			LET rp_plan_fence = today + rv_plan_fence 

			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO rv_onhand, rp_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			SELECT sum(min_ord_qty) 
			INTO rp_min_ord_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			SKIP 1 line 
			PRINT COLUMN 1, rp_part_code clipped, 
			COLUMN 17, rp_part_desc clipped, 
			COLUMN 37, " UoM:" clipped, 
			COLUMN 42, fv_uom_code clipped, 
			COLUMN 46, "Critical Stock:" clipped, 
			COLUMN 61, rp_critical_qty USING "---------&.&&&&", 
			COLUMN 77, "Minimum Reorder:" clipped, 
			COLUMN 93, rp_min_ord_qty USING "--------&.&&&&", 
			COLUMN 108, rv_onhand USING "---------&.&&&&" 

			LET rv_order_qty = 0 
			LET rv_bal_amt = rv_onhand 

		ON EVERY ROW 
			LET rv_job_length = num_days(rp_start_date,rp_due_date) 
			LET rv_job_length = rv_job_length - rp_lead_time 

			IF rv_job_length < 0 
			OR (rp_start_date < today 
			OR rp_due_date < today) THEN 
				LET rv_act = "Expedite" 
			ELSE 
				IF rp_start_date > today 
				OR rv_job_length > 0 THEN 
					LET rv_act = "Delay" 
				ELSE 
					LET rv_act = "Today" 
				END IF 
			END IF 

			IF rp_type = "CO" 
			AND rv_type_code IS NULL THEN 
				LET rv_act = "Purchase" 
			END IF 

			IF rp_type = "AO" THEN 
				LET rp_type = "SO" 
			END IF 

			IF rp_type = "ZM" THEN 
				LET rp_type = "RO" 
			END IF 

			IF rp_ordered = 0 
			OR rp_ordered IS NULL THEN 
				LET rv_act = " " 
			END IF 

			IF rp_ordered <> 0 THEN 
				LET rv_bal_amt = rv_bal_amt + rp_ordered 
			ELSE 
				IF rp_type = "SO" THEN 
					LET rv_bal_amt = rv_bal_amt + rp_required 
				ELSE 
					LET rv_bal_amt = rv_bal_amt - rp_required 
				END IF 
			END IF 

			IF rp_start_date > rp_plan_fence THEN 
				PRINT COLUMN 26,"*** PLANNING FENCE ***", 
				COLUMN 55,rp_plan_fence USING "dd/mm/yyyy" 
				LET rp_plan_fence = 999999 
			END IF 

			IF rp_start_date > rp_demand_fence THEN 
				PRINT COLUMN 26,"*** DEMAND FENCE ***", 
				COLUMN 55,rp_demand_fence USING "dd/mm/yyyy" 
				LET rp_demand_fence = 999999 
			END IF 

			IF rp_required <> 0 THEN 
				PRINT COLUMN 32, rp_reference USING "#####&", 
				COLUMN 39, rp_type clipped, 
				COLUMN 44, rp_due_date USING "dd/mm/yyyy", 
				COLUMN 55, rp_start_date USING "dd/mm/yyyy", 
				COLUMN 66, rv_job_length USING "------&", 
				COLUMN 74, rp_required USING "---------&.&&&&", 
				COLUMN 92, rp_ordered USING "##########.####", 
				COLUMN 108, rv_bal_amt USING "---------&.&&&&", 
				COLUMN 124, rv_act 
			END IF 

		ON LAST ROW 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT M51_rpt_list_mps_pegging(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
#	rp_ware_desc, rp_part_code, rp_part_desc, 
#	rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
#	rp_seq, rp_lead_time) 
###########################################################################


###########################################################################
# REPORT M51_rpt_list_mps_exception(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
#	rp_ware_desc, rp_part_code, rp_part_desc, 
#	rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
#	rp_seq, rp_lead_time)
#
#  
###########################################################################
REPORT M51_rpt_list_mps_exception(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
	rp_ware_desc, rp_part_code, rp_part_desc, 
	rp_reference, rp_type, rp_required, 
	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
	rp_seq, rp_lead_time) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	fv_uom_code LIKE prodmfg.man_uom_code, 
	rp_cmpy CHAR(2), 
	rp_ware_code CHAR(3), 
	rp_ware_desc LIKE warehouse.desc_text, 
	rp_part_code LIKE mps.part_code, 
	rp_part_desc CHAR(20), 
	rp_reference LIKE mps.reference_num, 
	rp_type LIKE mps.type_text, 
	rp_required LIKE shoporddetl.required_qty, 
	rp_demand_fence LIKE mps.due_date, 
	rp_critical_qty LIKE prodstatus.critical_qty, 
	rp_min_ord_qty LIKE product.min_ord_qty, 
	rp_plan_fence LIKE mps.due_date, 
	rp_due_date LIKE mps.due_date, 
	rp_start_date LIKE mps.start_date, 
	rp_soh LIKE prodstatus.onhand_qty, 
	rp_ordered LIKE mps.required_qty, 
	rp_seq INTEGER, 
	rp1_required LIKE shoporddetl.required_qty, 
	rp1_due_date LIKE mps.due_date, 
	rp1_start_date LIKE mps.start_date, 
	rp1_soh LIKE prodstatus.onhand_qty, 
	rp1_ordered LIKE mps.required_qty, 
	rp_lead_time INTEGER, 
	rv_scrap_ind CHAR(1), 
	rv_fence_ind CHAR(1), 
	rv_cmpy_name LIKE company.name_text, 
	rv_title CHAR(132), 
	rpt_line1 CHAR(132), 
	rpt_line2 CHAR(132), 
	rpt_line3 CHAR(132), 
	rpt_line4 CHAR(132), 
	rv_position SMALLINT, 
	rv_bal_amt LIKE mps.required_qty, 
	rv_job_length INTEGER , 
	rv_act CHAR(8), 
	rv_type_code LIKE prodmfg.part_type_ind, 
	rv_demand_fence LIKE prodmfg.demand_fence_num, 
	rv_plan_fence LIKE prodmfg.plan_fence_num, 
	rv_onhand LIKE mps.required_qty, 
	rv_order_qty LIKE mps.required_qty 

	OUTPUT 

	ORDER external BY rp_ware_code,rp_part_code,rp_due_date,rp_seq 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Plan: ", pv_mps_plan," ", pv_mps_desc 
			PRINT COLUMN 4, "Time Fence (O=Orders,F=Forecasts): ",rv_fence_ind, 
			" Scrap/Yield (S=Scrap,Y=Yield,B=Both,N=None): ",rv_scrap_ind, 
			" END Date ", pv_end_date USING "dd/mm/yyyy" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 2, "Product", 
			COLUMN 32, "Ref.", 
			COLUMN 45, "Due", 
			COLUMN 55, "Scheduled ", 
			COLUMN 67, " Job Length ", 
			COLUMN 80, "Required", 
			COLUMN 98, "Quantity", 
			COLUMN 114, "Projected", 
			COLUMN 124, "Action" 
			PRINT COLUMN 4, "Code", 
			COLUMN 16, "Description", 
			COLUMN 32, "Number", 
			COLUMN 39, "Type", 
			COLUMN 45, "Date ", 
			COLUMN 55, "Start Date", 
			COLUMN 67, "- Lead Time ", 
			COLUMN 80, "Quantity", 
			COLUMN 98, "TO ORDER", 
			COLUMN 114, "Stock" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 


		BEFORE GROUP OF rp_part_code 

			SELECT part_type_ind, demand_fence_num, 
			plan_fence_num, man_uom_code 
			INTO rv_type_code, rv_demand_fence, 
			rv_plan_fence, fv_uom_code 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_part_code 

			IF status = notfound THEN 
				LET rv_type_code = "X" 
			END IF 

			LET rp_demand_fence = today + rv_demand_fence 
			LET rp_plan_fence = today + rv_plan_fence 

			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO rv_onhand, rp_critical_qty 
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
			COLUMN 42, fv_uom_code clipped, 
			COLUMN 46, "Critical Stock:" clipped, 
			COLUMN 61, rp_critical_qty USING "---------&.&&&&", 
			COLUMN 77, "Minimum Reorder:" clipped, 
			COLUMN 93, rp_min_ord_qty USING "--------&.&&&&", 
			COLUMN 108, rv_onhand USING "---------&.&&&&" 

			LET rv_order_qty = 0 
			LET rv_bal_amt = rp_soh 

		ON EVERY ROW 
			LET rv_job_length = num_days(rp_start_date,rp_due_date) 
			LET rv_job_length = rv_job_length - rp_lead_time 

			IF rv_job_length < 0 
			OR (rp_start_date < today 
			OR rp_due_date < today) THEN 
				LET rv_act = "Expedite" 
			ELSE 
				IF rv_job_length > 0 THEN 
					LET rv_act = "Delay" 
				ELSE 
					CASE 
						WHEN rp_start_date = today 
							LET rv_act = "Today" 
						WHEN rp_start_date < today 
							LET rv_act = "Expedite" 
						WHEN rp_start_date > today 
							LET rv_act = NULL 
					END CASE 
				END IF 
			END IF 

			IF rp_type = "ZM" THEN 
				LET rp_type = "RO" 
			END IF 

			IF rp_type = "CO" 
			AND rv_type_code = "X" THEN 
				LET rv_act = "Purchase" 
			END IF 

			IF rp_ordered = 0 
			OR rp_ordered IS NULL THEN 
				LET rv_act = " " 
			END IF 

			IF rp_start_date > rp_plan_fence THEN 
				PRINT COLUMN 26,"*** PLANNING FENCE ***", 
				COLUMN 55,rp_plan_fence USING "dd/mm/yyyy" 
				LET rp_plan_fence = 999999 
			END IF 

			IF rp_start_date > rp_demand_fence THEN 
				PRINT COLUMN 26,"*** DEMAND FENCE ***", 
				COLUMN 55,rp_demand_fence USING "dd/mm/yyyy" 
				LET rp_demand_fence = 999999 
			END IF 

			PRINT COLUMN 32, rp_reference USING "#####&", 
			COLUMN 39, rp_type clipped, 
			COLUMN 44, rp_due_date USING "dd/mm/yyyy", 
			COLUMN 55, rp_start_date USING "dd/mm/yyyy", 
			COLUMN 66, rv_job_length USING "------&", 
			COLUMN 74, rp_required USING "#########&.&&&&", 
			COLUMN 92, rp_ordered USING "##########.####", 
			COLUMN 108, rp_soh USING "---------&.&&&&", 
			COLUMN 124, rv_act 

		AFTER GROUP OF rp_part_code 
			PRINT 

		ON LAST ROW 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT M51_rpt_list_mps_exception(p_rpt_idx,rp_cmpy, rv_fence_ind, rv_scrap_ind, rp_ware_code, 
#	rp_ware_desc, rp_part_code, rp_part_desc, 
#	rp_reference, rp_type, rp_required, 
#	rp_due_date, rp_start_date, rp_soh, rp_ordered, 
#	rp_seq, rp_lead_time)
#
#  
###########################################################################