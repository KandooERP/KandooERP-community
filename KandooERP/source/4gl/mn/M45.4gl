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
# Purpose - Shop Order Shortages Listing
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M4_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M41_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	rpt_note CHAR(80), 
	formname CHAR(10), 
	pr_output CHAR(60), 
	fv_query_text CHAR(1000), 
	fv_do_stuff CHAR(1), 

	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	pr_menunames RECORD LIKE menunames.* 
END GLOBALS 


###########################################################################
# MAIN
#
# Purpose - Shop Order Shortages Listing
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("M45") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET fv_do_stuff = true 

	OPEN WINDOW w0_bor with FORM "M184" 
	CALL  windecoration_m("M184") -- albo kd-762 


	CALL kandoomenu("M", 161) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			CALL report_main() 
			RETURNING fv_do_stuff 

			IF fv_do_stuff = true THEN 
				NEXT option pr_menunames.cmd2_code #print 
			END IF 

		ON ACTION "Print Manager"			#command pr_menunames.cmd2_code pr_menunames.cmd2_text
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd1_code #report 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text #exit 
			EXIT MENU 

		COMMAND KEY(interrupt) 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW w0_bor 
END MAIN 
###########################################################################
# END MAIN
###########################################################################

###########################################################################
# FUNCTION report_main()
#
# 
###########################################################################
FUNCTION report_main()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	fv_where_part STRING, 
	fv_balance LIKE shoporddetl.required_qty, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.* 

	LET msgresp = kandoomsg("M",1505,"") 

	CONSTRUCT fv_where_part 
	ON shopordhead.shop_order_num, 
	shopordhead.suffix_num, 
	shopordhead.cust_code, 
	shopordhead.part_code, 
	shoporddetl.part_code, 
	shopordhead.status_ind, 
	shopordhead.start_date, 
	shopordhead.end_date, 
	shopordhead.actual_start, 
	shopordhead.actual_end 
	FROM shop_order_num, 
	suffix_num, 
	cust_code, 
	product, 
	component, 
	status_ind, 
	start_date, 
	end_date, 
	actual_start, 
	actual_end 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET fv_query_text = " SELECT * ", 
	" FROM shopordhead, shoporddetl ", 
	" WHERE shopordhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shopordhead.cmpy_code = ", 
	" shoporddetl.cmpy_code ", 
	" AND shopordhead.shop_order_num = ", 
	" shoporddetl.shop_order_num ", 
	" AND ", fv_where_part clipped," ", 
	" ORDER BY shoporddetl.part_code", 
	", shoporddetl.start_date", 
	", shoporddetl.shop_order_num" 

	PREPARE statement1 FROM fv_query_text 
	DECLARE ts_cur CURSOR FOR statement1 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M45_rpt_list_shortage","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M45_rpt_list_shortage TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOREACH ts_cur INTO fr_shopordhead.*, fr_shoporddetl.* 
		IF fr_shopordhead.order_type_ind matches "[OS]" THEN 
			IF fr_shoporddetl.type_ind matches "[CB]" THEN 
				LET fv_balance = 0 
				LET fv_balance = fr_shoporddetl.required_qty 
				- fr_shoporddetl.issued_qty 
				IF fv_balance > 0 THEN 
					OUTPUT TO REPORT M45_rpt_list_shortage(fr_shopordhead.*, 
					fr_shoporddetl.*) 
				END IF 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M45_rpt_list_shortage
	CALL rpt_finish("M45_rpt_list_shortage")
	#------------------------------------------------------------	

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# REPORT M45_rpt_list_shortage(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
#
# 
###########################################################################
REPORT M45_rpt_list_shortage(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rv_product_desc_text CHAR(30), 
	rv_cmpy_name CHAR(30), 
	rv_title CHAR(70), 
	rv_product_uom CHAR(4), 

	rv_position SMALLINT, 
	rv_cnt SMALLINT, 
	rv_first_item SMALLINT, 

	rv_balance LIKE shoporddetl.required_qty, 
	rv_total_balance LIKE shoporddetl.required_qty, 
	rv_total_onhand LIKE shoporddetl.required_qty, 

	rr_prodstatus RECORD LIKE prodstatus.*, 
	rr_notes RECORD LIKE notes.*, 
	rr_workcentre RECORD LIKE workcentre.*, 
	rr_shopordhead RECORD LIKE shopordhead.*, 
	rr_shoporddetl RECORD LIKE shoporddetl.* 

	OUTPUT 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

			PRINT COLUMN 1, "Product", 
			COLUMN 17, "Description", 
			COLUMN 37, "Shop ", 
			COLUMN 47, "Manufactured", 
			COLUMN 60, " Due Date", 
			COLUMN 73, "Total", 
			COLUMN 86, "Total", 
			COLUMN 95, "Shortage", 
			COLUMN 105, "UOM", 
			COLUMN 113, "Onhand", 
			COLUMN 120, "UOM", 
			COLUMN 125, "W/H" 

			PRINT COLUMN 37, "Order", 
			COLUMN 47, "Item", 
			COLUMN 73, "Required", 
			COLUMN 86, "Issued" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rr_shoporddetl.part_code 
			LET rv_first_item = 1 
			LET rv_total_balance = 0 
			LET rv_total_onhand = 0 

			SELECT stock_uom_code 
			INTO rv_product_uom 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shoporddetl.part_code 

		ON EVERY ROW 
			DECLARE ware_cur CURSOR FOR 
			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shoporddetl.part_code 

			SELECT desc_text 
			INTO rv_product_desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rr_shoporddetl.part_code 

			LET rv_cnt = 1 
			FOREACH ware_cur INTO rr_prodstatus.* 
				IF rv_cnt = 1 THEN 
					LET rv_balance = rr_shoporddetl.required_qty 
					- rr_shoporddetl.issued_qty 

					LET rv_total_balance = rv_total_balance + rv_balance 

					IF rv_first_item = 1 THEN 
						LET rv_total_onhand = rv_total_onhand 
						+ rr_prodstatus.onhand_qty 

						PRINT 
						NEED 4 LINES 
						PRINT COLUMN 1, rr_shoporddetl.part_code, 
						COLUMN 17, rv_product_desc_text [1,20], 
						COLUMN 38, rr_shoporddetl.shop_order_num 
						USING "<<<<<<<<", 
						COLUMN 47, rr_shoporddetl.parent_part_code , 
						COLUMN 62, rr_shoporddetl.start_date 
						USING "dd/mm/yy", 
						COLUMN 71, rr_shoporddetl.required_qty 
						USING "#######.##", 
						COLUMN 82, rr_shoporddetl.issued_qty 
						USING "#######.##", 
						COLUMN 93, rv_balance USING "#######.##", 
						COLUMN 105, rr_shoporddetl.uom_code, 
						COLUMN 109, rr_prodstatus.onhand_qty 
						USING "-------#.##", 
						COLUMN 120, rv_product_uom, 
						COLUMN 125, rr_prodstatus.ware_code 

						LET rv_first_item = 2 
					ELSE 
						LET rv_first_item = 3 
						NEED 4 LINES 
						PRINT COLUMN 38, rr_shoporddetl.shop_order_num 
						USING "<<<<<<<<", 
						COLUMN 47, rr_shoporddetl.parent_part_code, 
						COLUMN 62, rr_shoporddetl.start_date 
						USING "dd/mm/yy", 
						COLUMN 71, rr_shoporddetl.required_qty 
						USING "#######.##", 
						COLUMN 82, rr_shoporddetl.issued_qty 
						USING "#######.##", 
						COLUMN 93, rv_balance USING "#######.##", 
						COLUMN 105, rr_shoporddetl.uom_code 
					END IF 
					LET rv_cnt = rv_cnt + 1 
				ELSE 
					IF rv_first_item = 2 THEN 
						LET rv_total_onhand = rv_total_onhand 
						+ rr_prodstatus.onhand_qty 
					END IF 

					IF rv_first_item != 3 THEN 
						PRINT COLUMN 109, rr_prodstatus.onhand_qty 
						USING "-------#.##", 
						COLUMN 125, rr_prodstatus.ware_code 
					END IF 
				END IF 
			END FOREACH 

		AFTER GROUP OF rr_shoporddetl.part_code 
			PRINT COLUMN 93, "----------", 
			COLUMN 109, "----------" 
			PRINT COLUMN 86, "Totals", 
			COLUMN 93, rv_total_balance USING "#######.##", 
			COLUMN 109, rv_total_onhand USING "-------#.##" 
			PRINT COLUMN 93, "----------", 
			COLUMN 109, "----------" 

		ON LAST ROW 
			PRINT 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT M45_rpt_list_shortage(p_rpt_idx,rr_shopordhead, rr_shoporddetl) 
###########################################################################