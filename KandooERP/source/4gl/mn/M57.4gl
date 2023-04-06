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
# Purpose - MRP by Due Date
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M57_GLOBALS.4gl"

GLOBALS 

	DEFINE 

	formname CHAR(10), 
	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	rpt_note CHAR(80), 
	rpt_wid SMALLINT, 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 


###########################################################################
# MAIN
#
# Purpose - MRP by Due Date
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M57") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL report_main() 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main()
#
# FUNCTION TO DISPLAY SCREEN, get data, AND start the REPORT
###########################################################################
FUNCTION report_main() 
	DEFINE 
	fv_plan_code LIKE mrp.plan_code, 
	fv_count INTEGER, 
	fv_data_exists SMALLINT 

	OPEN WINDOW w0_report with FORM "M138" 
	CALL  windecoration_m("M138") -- albo kd-762 

	LET fv_data_exists = true 

	CALL kandoomenu("M", 144) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			LET msgresp = kandoomsg("M",1505,"") 
			# MESSAGE "ESC TO Accept - DEL TO Exit"

			INPUT fv_plan_code 
			FROM plan_code 

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

		ON ACTION "Print Manager"			#command pr_menunames.cmd2_code pr_menunames.cmd2_text
			CALL run_prog("URS", "", "", "", "") 
			#run "fglgo URS.4gi"
			NEXT option pr_menunames.cmd4_code # "Exit" 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 
END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# FUNCTION print_mrp(fp_plan_code)
#
# FUNCTION TO get data AND send it out TO the REPORT
###########################################################################
FUNCTION print_mrp(fp_plan_code) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fp_plan_code LIKE mrp.plan_code, 
	fv_plan_desc LIKE mrp.desc_text, 
	fv_min_date LIKE mrp.due_date, 
	fv_kandoo_date LIKE mrp.due_date, 
	fv_ware_code CHAR(3), 
	fv_warehouse LIKE warehouse.desc_text, 
	fv_due_date LIKE mrp.due_date, 
	fv_part_code LIKE mrp.part_code, 
	fv_desc_text LIKE product.desc_text, 
	fv_quantity LIKE mrp.required_qty, 
	fv_start_date LIKE mrp.start_date, 
	fv_type_text LIKE mrp.type_text, 
	fv_reference LIKE mrp.reference_num, 
	fv_cmpy_code LIKE mrp.cmpy_code, 
	fv_security LIKE kandoouser.security_ind, 
	fv_output CHAR(80) 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M57_rpt_list_mrp","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M57_rpt_list_mrp TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE smrp_cursor CURSOR FOR 
	SELECT mrp.due_date,mrp.part_code,mrp.required_qty, 
	mrp.start_date,mrp.type_text,mrp.reference_num,mrp.cmpy_code, 
	mrp.desc_text 
	FROM mrp 
	WHERE mrp.plan_code = fp_plan_code 
	AND mrp.required_qty > 0 
	ORDER BY mrp.due_date,mrp.start_date,mrp.part_code 

	SELECT min(mrp.due_date),max(mrp.due_date) 
	INTO fv_min_date,fv_kandoo_date 
	FROM mrp 
	WHERE mrp.plan_code=fp_plan_code 

	FOREACH smrp_cursor INTO fv_due_date,fv_part_code,fv_quantity, 
		fv_start_date,fv_type_text,fv_reference, 
		fv_cmpy_code,fv_plan_desc 

		LET fv_ware_code = NULL 
		LET fv_warehouse = NULL 

		SELECT product.desc_text 
		INTO fv_desc_text 
		FROM product 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = fv_part_code 

		IF fv_type_text = "P" THEN 
			LET fv_reference = NULL 
		END IF 

		CALL working("MRP Item",fv_part_code) 

		#---------------------------------------------------------
		OUTPUT TO REPORT M57_rpt_list_mrp(l_rpt_idx,
		fp_plan_code,fv_plan_desc,fv_min_date, 
		fv_kandoo_date,fv_ware_code,fv_warehouse, 
		fv_due_date,fv_part_code,fv_desc_text, 
		fv_quantity,fv_start_date,fv_reference) 
		#---------------------------------------------------------	
		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M57_rpt_list_mrp
	CALL rpt_finish("M57_rpt_list_mrp")
	#------------------------------------------------------------

END FUNCTION 
###########################################################################
# END FUNCTION print_mrp(fp_plan_code)
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
		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "esc TO accept del TO EXIT"

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
			LET msgresp = kandoomsg("M",1521,"") 
			# MESSAGE "f3 fwd f4 bwd f9 reselect f10 add del EXIT esc accept"

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
					LET msgresp = kandoomsg("M",9671,"") 
					#ERROR "Only the first 500 MRP plans have been selected"
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
				LET msgresp = kandoomsg("M",9672,"") 
				# error"There are no material requirement plans in the database"
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
		LET msgresp = kandoomsg("M",9666,"") 
		# ERROR "Schedule Lookup Aborted"
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

	DISPLAY fp_text clipped,": ",fp_value clipped,"" at 2,2	attribute(normal,white) 
END FUNCTION 
###########################################################################
# END FUNCTION working(fp_text,fp_value)
###########################################################################

###########################################################################
# REPORT M57_rpt_list_mrp(p_rpt_idx,rp_plan_code,rp_plan_desc,rp_min_date,rp_kandoo_date, 
#	rp_ware_code,rp_warehouse,rp_due_date,rp_part_code, 
#	rp_desc_text,rp_quantity,rp_start_date,rp_po) 
#
# REPORT TO list the planned purchase orders FROM the MRP
###########################################################################
REPORT M57_rpt_list_mrp(p_rpt_idx,rp_plan_code,rp_plan_desc,rp_min_date,rp_kandoo_date, 
	rp_ware_code,rp_warehouse,rp_due_date,rp_part_code, 
	rp_desc_text,rp_quantity,rp_start_date,rp_po) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rp_plan_code LIKE mrp.plan_code, 
	rp_plan_desc LIKE mrp.desc_text, 
	rp_min_date LIKE mrp.due_date, 
	rp_kandoo_date LIKE mrp.due_date, 
	rp_ware_code CHAR(3), 
	rp_warehouse LIKE warehouse.desc_text, 
	rp_due_date LIKE mrp.due_date, 
	rp_part_code LIKE mrp.part_code, 
	rp_desc_text LIKE product.desc_text, 
	rp_quantity LIKE mrp.required_qty, 
	rp_start_date LIKE mrp.start_date, 
	rp_po LIKE mrp.reference_num, 
	rv_string CHAR(80), 
	rv_cmpy_name CHAR(80), 
	rv_title CHAR(132), 
	rv_count SMALLINT, 
	rv_position SMALLINT, 
	rr_wid SMALLINT 

	OUTPUT 


	ORDER external BY rp_due_date,rp_start_date,rp_part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			LET rv_title = "Production due between ", 
			rp_min_date USING "dd/mm/yyyy", 
			" AND ",rp_kandoo_date USING "dd/mm/yyyy"," FOR ", 
			rp_plan_code clipped," ",rp_plan_desc clipped 
			
			LET rv_position = (rr_wid-length(rv_title))/2 

			PRINT COLUMN rv_position,rv_title clipped 
			PRINT 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 5, "Due Date", 
			COLUMN 17, "Item", 
			COLUMN 33, "Description", 
			COLUMN 71, "Quantity", 
			COLUMN 81, "Start Date", 
			COLUMN 93, "PO Num" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 

		BEFORE GROUP OF rp_due_date 
			PRINT COLUMN 5,rp_due_date USING "dd/mm/yyyy"; 

		ON EVERY ROW 
			PRINT COLUMN 17, rp_part_code clipped, 
			COLUMN 33, rp_desc_text clipped, 
			COLUMN 64, rp_quantity USING "#########&.&&&&", 
			COLUMN 81, rp_start_date USING "dd/mm/yyyy", 
			COLUMN 93, rp_po USING "<<<<<<<<<&" 
		AFTER GROUP OF rp_due_date 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT M57_rpt_list_mrp(p_rpt_idx,rp_plan_code,rp_plan_desc,rp_min_date,rp_kandoo_date, 
###########################################################################

