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
# Purpose - Forecast Listing

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M6_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M63_GLOBALS.4gl"

GLOBALS 

	DEFINE pr_menunames RECORD LIKE menunames.* 

END GLOBALS 

DEFINE select_text STRING 
DEFINE where_part STRING 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M63") -- albo 
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
# FUNCTION TO DISPLAY the SCREEN AND control program flow via a ring menu
###########################################################################
FUNCTION report_main() 

	DEFINE 
	fv_data_exists SMALLINT, 
	fv_where_part CHAR(1000) 



	OPEN WINDOW M190 with FORM "M190" 
	CALL  windecoration_m("M190") -- albo kd-762 

	CALL kandoomenu("M", 145) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			CALL report_query() 
			RETURNING fv_data_exists 
			IF fv_data_exists THEN 
				CALL print_report() 
				NEXT option pr_menunames.cmd2_code # "Print" 
			ELSE 
				LET msgresp = kandoomsg("M",9676,"") 
				# ERROR "There IS no data TO REPORT on"
			END IF 

		ON ACTION "Print Manager" 
			#command pr_menunames.cmd2_code pr_menunames.cmd2_text
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd4_code # "Exit" 


		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW M190 

END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# FUNCTION report_query() 
#
# FUNCTION TO query the SCREEN AND produce a CURSOR TO REPORT FROM 
###########################################################################
FUNCTION report_query() 

	DEFINE 
	fv_where_part CHAR(1000), 
	fv_query_text CHAR(3000), 
	fv_runtext CHAR(3000), 
	fv_query_ok SMALLINT 


	LET fv_query_ok = true 

	CONSTRUCT fv_where_part 
	ON shopordhead.shop_order_num, 
	shopordhead.part_code, 
	shopordhead.order_qty, 
	shopordhead.uom_code, 
	shopordhead.start_date, 
	shopordhead.end_date 
	FROM shop_order_num, 
	part_code, 
	order_qty, 
	uom_code, 
	start_date, 
	end_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_query_ok = false 
		LET msgresp = kandoomsg("M",9555,"") 
		# ERROR "Query Aborted"
	ELSE 
		LET fv_query_text= 
		"SELECT unique shopordhead.shop_order_num,", 
		"shopordhead.part_code,", 
		"shopordhead.order_qty,", 
		"product.desc_text,", 
		"shopordhead.uom_code,", 
		"shopordhead.start_date, ", 
		"shopordhead.end_date ", 
		"FROM shopordhead, product ", 
		"WHERE shopordhead.cmpy_code='",glob_rec_kandoouser.cmpy_code clipped,"' ", 
		" AND ", fv_where_part clipped, 
		" AND product.cmpy_code = shopordhead.cmpy_code ", 
		" AND product.part_code = shopordhead.part_code ", 
		" AND shopordhead.order_type_ind = 'F' ", 
		" AND shopordhead.status_ind <> 'C' ", 
		"ORDER BY shopordhead.part_code,", 
		"shopordhead.end_date,", 
		"shopordhead.shop_order_num" 

		LET fv_runtext="echo \"",fv_query_text clipped,"\" > x.sql" 
		RUN fv_runtext 
		PREPARE statement1 FROM fv_query_text 
		DECLARE schedule_cursor CURSOR FOR statement1 
	END IF 

	LET where_part = fv_where_part 
	RETURN fv_query_ok 
END FUNCTION 
###########################################################################
# END FUNCTION report_query() 
###########################################################################


###########################################################################
# FUNCTION print_report() 
#
# FUNCTION TO OUTPUT the data FOR the REPORT
###########################################################################
FUNCTION print_report() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_security LIKE kandoouser.security_ind, 
	fv_output CHAR(80), 
	fv_cust_code LIKE shopordhead.cust_code, 
	fv_customer LIKE customer.name_text, 
	fv_shop_order LIKE shopordhead.shop_order_num, 
	fv_part LIKE shopordhead.part_code, 
	fv_order_qty LIKE shopordhead.order_qty, 
	fv_uom_code LIKE shopordhead.uom_code, 
	fv_item_desc LIKE product.desc_text, 
	fv_start_date LIKE shopordhead.start_date, 
	fv_due_date LIKE shopordhead.end_date 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M63_rpt_list_schedule","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M63_rpt_list_schedule TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOREACH schedule_cursor INTO fv_shop_order, 
		fv_part,fv_order_qty,fv_item_desc, 
		fv_uom_code,fv_start_date,fv_due_date 

		#---------------------------------------------------------
		OUTPUT TO REPORT M63_rpt_list_schedule(l_rpt_idx,
		fv_shop_order,fv_part, 
		fv_item_desc,fv_uom_code,fv_order_qty, 
		fv_start_date,fv_due_date) 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M63_rpt_list_schedule
	CALL rpt_finish("M63_rpt_list_schedule")
	#------------------------------------------------------------

END FUNCTION 
###########################################################################
# END FUNCTION print_report() 
###########################################################################


###########################################################################
# REPORT M63_rpt_list_schedule(p_rpt_idx,rp_shop_order, 
#	rp_item,rp_item_desc,rp_uom,rp_quantity,rp_start_date, 
#	rp_due_date) 
#
# REPORT TO produce a production schedule   
###########################################################################
REPORT M63_rpt_list_schedule(p_rpt_idx, rp_shop_order, 
	rp_item,rp_item_desc,rp_uom,rp_quantity,rp_start_date,rp_due_date) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rp_shop_order LIKE shopordhead.shop_order_num, 
	rp_item LIKE shopordhead.part_code, 
	rp_item_desc LIKE product.desc_text, 
	rp_uom LIKE shopordhead.uom_code, 
	rp_quantity LIKE shopordhead.order_qty, 
	rp_start_date LIKE shopordhead.start_date, 
	rp_due_date LIKE shopordhead.end_date, 
	rv_string CHAR(80), 
	rv_cmpy_name CHAR(80), 
	rv_title CHAR(132), 
	rv_count SMALLINT, 
	rv_position SMALLINT 

	OUTPUT 


	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 10, "Product", 
			COLUMN 30, "Description", 
			COLUMN 62, "Unit Of", 
			COLUMN 75, "Forecast", 
			COLUMN 91, "Quantity", 
			COLUMN 111, "Start", 
			COLUMN 123, "Due" 
			PRINT COLUMN 62, "Measure", 
			COLUMN 75, "Order", 
			COLUMN 92, "Ordered", 
			COLUMN 111, "Date", 
			COLUMN 123, "Date" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rp_item 
			PRINT COLUMN 10, rp_item clipped, 
			COLUMN 30, rp_item_desc clipped, 
			COLUMN 65, rp_uom ; 

		ON EVERY ROW 
			PRINT COLUMN 75, rp_shop_order USING "<<<<<&", 
			COLUMN 87, rp_quantity USING "######&.&&&&", 
			COLUMN 111, rp_start_date USING "dd/mm/yyyy", 
			COLUMN 123, rp_due_date USING "dd/mm/yyyy" 

		AFTER GROUP OF rp_item 
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
# END REPORT M63_rpt_list_schedule(p_rpt_idx,rp_shop_order, 
#	rp_item,rp_item_desc,rp_uom,rp_quantity,rp_start_date, 
#	rp_due_date) 
###########################################################################