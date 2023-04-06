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
# Purpose - MRP by Item
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M56_GLOBALS.4gl"

GLOBALS 
	DEFINE pr_menunames RECORD LIKE menunames.* 

END GLOBALS 

DEFINE 
mv_order_total DECIMAL(16,4), 
mv_purch_total DECIMAL(16,4), 
pr_company RECORD LIKE company.*, 
select_text CHAR(1200), 
where_part1 CHAR(1200), 
where_part CHAR(1200) 

###########################################################################
# MAIN
#
# Purpose - MRP by Item
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M56") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CALL report_main() 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main() 
#
# FUNCTION TO DISPLAY the window on the SCREEN AND control progrm flow
###########################################################################
FUNCTION report_main() 

	DEFINE 
	fv_plan_code LIKE mrp.plan_code, 
	fv_count INTEGER, 
	fv_data_exists SMALLINT 


	OPEN WINDOW M138 with FORM "M138" 
	CALL  windecoration_m("M138") -- albo kd-762 

	LET fv_data_exists = true 

	CALL kandoomenu("M", 150) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			LET mv_order_total = 0 
			LET mv_purch_total = 0 

			LET msgresp = kandoomsg("M",1505,"") 
			# MESSAGE "ESC TO accept del TO EXIT"

			INPUT fv_plan_code FROM plan_code 
				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

				AFTER FIELD plan_code 
					SELECT unique count(*) 
					INTO fv_count 
					FROM mrp 
					WHERE mrp.plan_code = fv_plan_code 

					IF fv_count = 0 THEN 
						LET msgresp = kandoomsg("M",9669,"") 
						# ERROR "This plan does NOT exist in the database"
						NEXT FIELD plan_code 
					END IF 

				ON KEY (control-B) 
					LET fv_plan_code = show_plans() 
					DISPLAY fv_plan_code 
					TO plan_code 
			END INPUT 

			IF (int_flag 
			OR quit_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET fv_data_exists = false 
				LET msgresp = kandoomsg("M",9670,"") 
				# ERROR "No plan selected"
				NEXT option pr_menunames.cmd1_code # "Report" 
			ELSE 
				CALL print_mrp(fv_plan_code) 
				NEXT option pr_menunames.cmd2_code # "Print" 
			END IF 

		ON ACTION "Print Manager"		#command pr_menunames.cmd2_code pr_menunames.cmd2_text
			CALL run_prog("URS", "", "", "", "") 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU
	
	CLOSE WINDOW M138
	 
END FUNCTION 
###########################################################################
# END FUNCTION report_main() 
###########################################################################


###########################################################################
# FUNCTION print_mrp(fp_mrp)
#
# FUNCTION TO get the data AND send it out TO the REPORT 
###########################################################################
FUNCTION print_mrp(fp_mrp)
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	fp_mrp LIKE mrp.plan_code, 
	fv_security LIKE kandoouser.security_ind, 
	fv_output CHAR(80), 
	fv_plan LIKE mrp.plan_code, 
	fv_description LIKE mrp.desc_text, 
	fv_part LIKE mrp.part_code, 
	fv_part_desc LIKE product.desc_text, 
	fv_open_bal LIKE prodstatus.onhand_qty, 
	fv_supplier LIKE product.vend_code, 
	fv_vend_name LIKE vendor.name_text, 
	fv_start LIKE mrp.start_date, 
	fv_qty LIKE mrp.required_qty, 
	fv_number LIKE mrp.reference_num, 
	fv_type LIKE mrp.type_text, 
	fv_cost LIKE prodstatus.wgted_cost_amt, 
	fr_prodmfg RECORD LIKE prodmfg.* 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M56_rpt_list_mrp","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M56_rpt_list_mrp TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE mrp_cursor CURSOR FOR 
	SELECT plan_code, part_code, 
	start_date, required_qty, 
	reference_num, type_text, 
	desc_text 
	FROM mrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = fp_mrp 
	AND required_qty > 0 
	ORDER BY part_code,start_date 

	FOREACH mrp_cursor INTO fv_plan, fv_part, 
		fv_start, fv_qty, 
		fv_number, fv_type, 
		fv_description 

		SELECT * 
		INTO fr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_part 

		SELECT vend_code 
		INTO fv_supplier 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_part 

		SELECT name_text 
		INTO fv_vend_name 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = fv_supplier 

		SELECT sum(onhand_qty) 
		INTO fv_open_bal 
		FROM prodstatus 
		WHERE prodstatus.cmpy_code=fr_prodmfg.cmpy_code 
		AND prodstatus.part_code=fr_prodmfg.part_code 

		SELECT prodstatus.wgted_cost_amt 
		INTO fv_cost 
		FROM prodstatus 
		WHERE prodstatus.cmpy_code = fr_prodmfg.cmpy_code 
		AND prodstatus.part_code = fr_prodmfg.part_code 
		AND prodstatus.ware_code = fr_prodmfg.def_ware_code 

		IF fv_cost IS NULL THEN 
			LET fv_cost = 0 
		END IF 

		CALL working("MRP Part ",fv_part) 

		#---------------------------------------------------------
		OUTPUT TO REPORT M56_rpt_list_mrp(l_rpt_idx,
		fv_plan,fv_description,fv_part,fv_part_desc, 
		fv_open_bal,fv_supplier,fv_vend_name, 
		fv_start,fv_qty,fv_number,fv_type,fv_cost)
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M56_rpt_list_mrp
	CALL rpt_finish("M56_rpt_list_mrp")
	#------------------------------------------------------------

END FUNCTION 
###########################################################################
# END FUNCTION print_mrp(fp_mrp)
###########################################################################


###########################################################################
# FUNCTION show_plans()
#
# 
###########################################################################
FUNCTION show_plans() 
	DEFINE 
	fa_plan array[500] OF RECORD 
		plan_no LIKE mrp.plan_code, 
		desc_text LIKE mrp.desc_text 
	END RECORD, 
	fv_data_exists SMALLINT, 
	fv_count SMALLINT, 
	fv_curr_row SMALLINT, 
	fv_scr_line SMALLINT, 
	fv_plan LIKE mrp.plan_code, 
	fv_where_part CHAR(500), 
	fv_query_text CHAR(1000) 

	OPEN WINDOW w0_plans with FORM "mrpw" 
	CALL  windecoration_m("Mrpw") -- albo kd-762 

	WHILE true 
		LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE "esc TO accept del TO EXIT"

		LET fv_plan = NULL 
		FOR fv_curr_row = 1 TO 500 
			INITIALIZE fa_plan[fv_curr_row].* TO NULL 
		END FOR 

		CONSTRUCT fv_where_part 
		ON mrp.plan_code,mrp.desc_text 
		FROM plan[1].* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF NOT (int_flag 
		OR quit_flag) THEN 
			LET msgresp = kandoomsg("M",1521,"") 		# MESSAGE "f3 fwd f4 bwd f9 reselect f10 add esc accept del EXIT"

			LET fv_query_text="SELECT unique mrp.plan_code,mrp.desc_text ", 
			"FROM mrp ", 
			"WHERE mrp.cmpy_code='",glob_rec_kandoouser.cmpy_code clipped,"' AND ", 
			fv_where_part clipped, 
			" ORDER BY mrp.plan_code" 

			PREPARE statement1 FROM fv_query_text 
			DECLARE splans SCROLL CURSOR FOR statement1 

			LET fv_count = 1 
			LET fv_data_exists = false 

			FOREACH splans INTO fa_plan[fv_count].plan_no, 
				fa_plan[fv_count].desc_text 
				LET fv_data_exists = true 
				LET fv_count = fv_count + 1 

				IF fv_count > 500 THEN 
					LET msgresp = kandoomsg("M",9671,"") 			# ERROR "First 500 MRP Plans have been loaded"
					EXIT FOREACH 
				END IF 
			END FOREACH 

			IF fv_data_exists THEN 
				CALL set_count(fv_count) 

				INPUT ARRAY fa_plan WITHOUT DEFAULTS FROM plan.* 

					ON ACTION "WEB-HELP" -- albo kd-376 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET fv_curr_row = arr_curr() 
						LET fv_scr_line = scr_line() 

						DISPLAY fa_plan[fv_curr_row].* 
						TO plan[fv_scr_line].* 
						attribute(white,reverse) 

					AFTER ROW 
						LET fv_curr_row = arr_curr() 
						LET fv_scr_line = scr_line() 

						DISPLAY fa_plan[fv_curr_row].* 
						TO plan[fv_scr_line].* 
						attribute(white,normal) 

					ON KEY (F9) 
						CLEAR FORM 
						EXIT INPUT 

					ON KEY (F10) 
						CALL run_prog("M53", "", "", "", "") 

					ON KEY (interrupt) 
						EXIT INPUT 

					ON KEY (ESC) 
						EXIT INPUT 
				END INPUT 
			ELSE 
				LET msgresp = kandoomsg("M",9672,"")		#error"There are no material requirement plans in the database"
				LET fv_plan = NULL 
			END IF 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_plan = NULL 
		LET msgresp = kandoomsg("M",9666,"") # ERROR "Schedule Lookup Aborted"
	ELSE 
		LET fv_plan = fa_plan[fv_curr_row].plan_no 
	END IF 
	
	CLOSE WINDOW w0_plans 
	RETURN fv_plan 
END FUNCTION 
###########################################################################
# END FUNCTION show_plans()
###########################################################################


###########################################################################
# FUNCTION working(fp_text,fp_value) 
#
# FUNCTION TO do something on the SCREEN TO show that a program IS working
###########################################################################
FUNCTION working(fp_text,fp_value) 

	DEFINE 
	fp_text CHAR(20), 
	fp_value CHAR(30) 

	DISPLAY fp_text clipped,": ",fp_value clipped,"" at 2,2 
	attribute(normal,white) 
END FUNCTION 

###########################################################################
# END FUNCTION working(fp_text,fp_value) 
###########################################################################


###########################################################################
# REPORT M56_rpt_list_mrp(p_rpt_idx,rp_plan,rp_description,rp_part,rp_part_desc,rp_open_bal, 
#	rp_supplier,rp_vend_name,rp_start,rp_qty,rp_number,rp_type,rp_cost) 
#
# REPORT TO list out the results of the Material Production Requirements
###########################################################################
REPORT M56_rpt_list_mrp(p_rpt_idx,rp_plan,rp_description,rp_part,rp_part_desc,rp_open_bal, 
	rp_supplier,rp_vend_name,rp_start,rp_qty,rp_number,rp_type,rp_cost) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rp_plan LIKE mrp.plan_code, 
	rp_description LIKE mrp.desc_text, 
	rp_part LIKE mrp.part_code, 
	rp_part_desc LIKE product.desc_text, 
	rp_open_bal LIKE prodstatus.onhand_qty, 
	rp_supplier LIKE product.vend_code, 
	rp_vend_name LIKE vendor.name_text, 
	rp_start LIKE mrp.start_date, 
	rp_qty LIKE mrp.required_qty, 
	rp_number LIKE mrp.reference_num, 
	rp_type LIKE mrp.type_text, 
	rv_cmpy_name LIKE company.name_text, 
	rv_title CHAR(80), 
	rv_position SMALLINT, 
	rp_cost LIKE prodstatus.wgted_cost_amt, 
	rr_wid SMALLINT, 
	rr_tmp_print CHAR(100), 
	rr_print CHAR(100), 
	rr_sort_desc CHAR(40), 
	rr_line1 CHAR(131), 
	rr_line2 CHAR(131), 
	rr_line3 CHAR(131), 
	done_lines SMALLINT 

	OUTPUT 
	PAGE length 66 
	left margin 0 
	top margin 0 
	right margin 80 
	bottom margin 6 

	ORDER external BY rp_part,rp_start 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT 

		BEFORE GROUP OF rp_part 
			NEED 16 LINES 
			LET mv_order_total = 0 
			LET mv_purch_total = 0 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT 
			PRINT COLUMN 1, "Item:", 
			COLUMN 7, rp_part clipped, 
			COLUMN 23, rp_part_desc clipped, 
			COLUMN 55, "Start Bal:", 
			COLUMN 66, rp_open_bal USING "#########&.&&&&" 
			PRINT 
			PRINT COLUMN 1, "Vendor", 
			COLUMN 9, rp_supplier clipped, 
			COLUMN 18, rp_vend_name clipped, 
			COLUMN 53, "Unit Cost:", 
			COLUMN 64, rp_cost USING "$$$$,$$$,$$&.&&&&" 
			PRINT 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Date", 
			COLUMN 20, "Order Qty", 
			COLUMN 32, "SO Num", 
			COLUMN 50, "PO Qty", 
			COLUMN 59, "PO Num" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1,rp_start USING "dd/mm/yyyy"; 

			IF rp_type = "PO" THEN 
				PRINT COLUMN 41, rp_qty USING "#########&.&&&&", 
				COLUMN 59, rp_number USING "#####&" 
				LET mv_purch_total = mv_purch_total+rp_qty 
			ELSE 
				PRINT COLUMN 14, rp_qty USING "#########&.&&&&", 
				COLUMN 32, rp_number USING "#####&" 
				LET mv_order_total = mv_order_total+rp_qty 
			END IF 

		AFTER GROUP OF rp_part 
			NEED 4 LINES 
			PRINT COLUMN 13,"----------------",COLUMN 40,"----------------" 
			PRINT COLUMN 13,mv_order_total USING "##########&.&&&&", 
			COLUMN 40,mv_purch_total USING "##########&.&&&&" 
			PRINT COLUMN 13,"----------------",COLUMN 40,"----------------" 
			PRINT 
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
###########################################################################
# END REPORT M56_rpt_list_mrp(p_rpt_idx,rp_plan,rp_description,rp_part,rp_part_desc,rp_open_bal, 
#	rp_supplier,rp_vend_name,rp_start,rp_qty,rp_number,rp_type,rp_cost) 
###########################################################################