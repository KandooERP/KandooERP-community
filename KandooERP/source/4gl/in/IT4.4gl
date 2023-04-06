{
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

	Source code beautified by beautify.pl on 2020-01-03 09:12:45	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#  program IT4 :  Provides stock take reports on users querys

GLOBALS 
	DEFINE 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_company RECORD LIKE company.*, 
	rpt_width LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_output CHAR(80), 
	where_text CHAR(1200), 
	pr_cost_type, pr_fifo_lifo_ind CHAR(1) 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IT4") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT cost_ind INTO pr_fifo_lifo_ind 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = '1' 


	OPEN WINDOW i220 with FORM "I220" 
	 CALL windecoration_i("I220") -- albo kd-758 

	MENU " Stock Take Detail Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","IT4","menu-Stock_Take_Detail-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Run" " SELECT Criteria AND Print Report" 
			LET rpt_pageno = 0 
			CALL it4_query() 
			LET rpt_note = NULL 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 
 
		COMMAND KEY(interrupt,"E")"Exit" " Exit TO Menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW i220 
END MAIN 


FUNCTION it4_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	DEFINE 
	pr_userlocn RECORD LIKE userlocn.*, 
	pr_location RECORD LIKE location.*, 
	order_text CHAR(100), 
	query_text CHAR(1300), 
	pr_order1, pr_order2 CHAR(15) 

	LET msgresp=kandoomsg("I",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME where_text ON stktakedetl.cycle_num, 
	desc_text, 
	ware_code, 
	part_code, 
	prodgrp_code, 
	maingrp_code, 
	bin_text, 
	count_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT4","construct-stktakedetl-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	MENU " Cost" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","IT4","menu-Cost-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE MENU 
			IF pr_fifo_lifo_ind <> "F" THEN 
				HIDE option "FIFO" 
			END IF 
			IF pr_fifo_lifo_ind <> "L" THEN 
				HIDE option "LIFO" 
			END IF 
		COMMAND "Actual" " Use Last actual cost in calculations" 
			LET pr_cost_type = "A" 
			EXIT MENU 
		COMMAND "FIFO" " Use FIFO cost in calculations" 
			LET pr_cost_type = "F" 
			EXIT MENU 
		COMMAND "LIFO" " Use LIFO cost in calculations" 
			LET pr_cost_type = "L" 
			EXIT MENU 
		COMMAND "Standard" " Use Standard cost in calculations" 
			LET pr_cost_type = "S" 
			EXIT MENU 
		COMMAND "Weighted" " Use Weighted cost in calculations" 
			LET pr_cost_type = "W" 
			EXIT MENU 
		COMMAND KEY (interrupt) 
			EXIT MENU 

	END MENU 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	#------------------------------------------------------------
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IT4_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT IT4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	SELECT * INTO pr_userlocn.* FROM userlocn 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO pr_location.* FROM location 
	WHERE locn_code = pr_userlocn.locn_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound OR pr_location.stocktake_ind = 'B' THEN 
		LET order_text = "stktakedetl.bin_text,stktakedetl.part_code" 
	ELSE 
		LET order_text = "stktakedetl.part_code,stktakedetl.bin_text" 
	END IF 
	LET query_text = "SELECT stktakedetl.*,stktake.* ", 
	"FROM stktakedetl,stktake ", 
	"WHERE stktakedetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND stktake.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND stktakedetl.cycle_num = stktake.cycle_num ", 
	"AND ", where_text clipped, 
	"ORDER BY stktake.cycle_num,ware_code, ",order_text clipped 
	PREPARE s_stktakedetl FROM query_text 
	DECLARE c_stktakedetl CURSOR FOR s_stktakedetl 

#	DISPLAY " Reporting on Product: " at 1,2 

	FOREACH c_stktakedetl INTO pr_stktakedetl.* 
		IF pr_location.stocktake_ind = "P" THEN 
			LET pr_order1 = pr_stktakedetl.part_code 
			LET pr_order2 = pr_stktakedetl.bin_text 
		ELSE 
			LET pr_order1 = pr_stktakedetl.bin_text 
			LET pr_order2 = pr_stktakedetl.part_code 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IT4_rpt_list(l_rpt_idx,pr_stktakedetl.*,pr_order1,pr_order2)   
		IF NOT rpt_int_flag_handler2("Product:",pr_stktakedetl.part_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------				


		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IT4_rpt_list
	CALL rpt_finish("IT4_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT IT4_rpt_list(p_rpt_idx,pr_stktakedetl,pr_order1,pr_order2) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	DEFINE 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_desc_text LIKE product.desc_text, 
	pr_adjustment LIKE prodstatus.onhand_qty, 
	pr_wgted_cost LIKE prodstatus.wgted_cost_amt, 
	pr_est_cost LIKE prodstatus.est_cost_amt, 
	pr_act_cost LIKE prodstatus.act_cost_amt, 
	pr_order1, pr_order2 CHAR(15), 
	pr_unit_cost,pr_total_unit_cost DECIMAL(16,4), 
	pr_cost DECIMAL(16,4), 
	pa_line array[4] OF CHAR(132), 
	pr_fifo_lifo_cost LIKE prodledg.cost_amt, 
	pr_calc_status SMALLINT, 
	pr_db_status INTEGER 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 66 
	ORDER external BY pr_stktakedetl.cycle_num, 
	pr_stktakedetl.ware_code, 
	pr_order1, 
	pr_order2 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
		
			IF rpt_note IS NULL THEN 
				CASE 
					WHEN pr_cost_type = "W" 
						LET rpt_note = "Weighted Average" 
					WHEN pr_cost_type = "S" 
						LET rpt_note = "Standard Cost" 
					WHEN pr_cost_type = "A" 
						LET rpt_note = "Last Actual Cost" 
					WHEN pr_cost_type = "F" 
						LET rpt_note = "FIFO Cost" 
					WHEN pr_cost_type = "L" 
						LET rpt_note = "LIFO Cost" 
					OTHERWISE 
						LET rpt_note = "Unknown option using Weighted Average Cost" 
				END CASE 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text clipped," ",rpt_note clipped  
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_stktakedetl.cycle_num 
			LET pr_total_unit_cost = 0 
			PRINT COLUMN 1,"Cycle Number:",pr_stktakedetl.cycle_num USING "<<<<" 
		ON EVERY ROW 
			SELECT product.desc_text, 
			prodstatus.wgted_cost_amt, 
			prodstatus.est_cost_amt, 
			prodstatus.act_cost_amt 
			INTO pr_desc_text, 
			pr_wgted_cost, 
			pr_est_cost, 
			pr_act_cost 
			FROM product, prodstatus 
			WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodstatus.part_code = pr_stktakedetl.part_code 
			AND prodstatus.ware_code = pr_stktakedetl.ware_code 
			AND prodstatus.part_code = product.part_code 
			AND prodstatus.cmpy_code = product.cmpy_code 
			IF status = notfound THEN 
				LET pr_desc_text = "NOT FOUND - ERROR" 
				LET pr_wgted_cost = 0 
				LET pr_act_cost = 0 
				LET pr_est_cost = 0 
				LET pr_fifo_lifo_cost = 0 
			ELSE 
				#
				# IF FIFO/LIFO costing selected, CALL the cost calculation FOR issues,
				# without using UPDATE mode TO retrieve the cost AT which these items
				# will be valued WHEN thaey are issued.  IF there IS no count entered,
				# OR the count IS zero, a fifo/lifo cost cannot be calculated, so the
				# latest actual cost IS used instead.
				#
				IF pr_cost_type matches "[FL]" THEN 
					IF pr_stktakedetl.count_qty = 0 THEN 
						LET pr_fifo_lifo_cost = pr_act_cost 
					ELSE 
						CALL fifo_lifo_issue(glob_rec_kandoouser.cmpy_code, 
						pr_stktakedetl.part_code, 
						pr_stktakedetl.ware_code, 
						today, 
						1, 
						"A", 
						pr_stktakedetl.count_qty, 
						pr_fifo_lifo_ind, 
						false) 
						RETURNING pr_calc_status, 
						pr_db_status, 
						pr_fifo_lifo_cost 
						IF pr_calc_status = false THEN 
							LET pr_fifo_lifo_cost = pr_act_cost 
						END IF 
					END IF 
				END IF 
			END IF 

			CASE 
				WHEN pr_cost_type = "W" 
					LET pr_unit_cost = pr_wgted_cost 
				WHEN pr_cost_type = "S" 
					LET pr_unit_cost = pr_est_cost 
				WHEN pr_cost_type = "A" 
					LET pr_unit_cost = pr_act_cost 
				WHEN pr_cost_type matches "[FL]" 
					LET pr_unit_cost = pr_fifo_lifo_cost 
				OTHERWISE 
					LET pr_unit_cost = pr_wgted_cost 
			END CASE 
			IF pr_unit_cost IS NULL THEN 
				LET pr_unit_cost = 0 
			END IF 
			LET pr_cost = pr_unit_cost * pr_stktakedetl.count_qty 
			LET pr_total_unit_cost = pr_total_unit_cost + pr_unit_cost 
			PRINT COLUMN 1,pr_stktakedetl.ware_code clipped, 
			COLUMN 11,pr_stktakedetl.bin_text clipped, 
			COLUMN 27,pr_stktakedetl.part_code clipped, 
			COLUMN 43,pr_desc_text, 
			COLUMN 74,pr_stktakedetl.count_qty USING "---------&.&&&&", 
			COLUMN 91,pr_unit_cost USING "-----,---,--&.&&&&", 
			COLUMN 115,pr_cost USING "-----,---,--&.&&&&" 
		ON LAST ROW 
			PRINT COLUMN 71, "------------------", 
			COLUMN 91, "------------------", 
			COLUMN 113,"--------------------" 
			PRINT COLUMN 02, "Report Totals: ", 
			COLUMN 74, sum(pr_stktakedetl.count_qty) USING "---------&.&&&&", 
			COLUMN 91, pr_total_unit_cost USING "-----,---,--&.&&&&", 
			COLUMN 113, sum(pr_cost) USING "---,---,---,--&.&&&&" 
			PRINT COLUMN 71, "------------------", 
			COLUMN 91, "------------------", 
			COLUMN 113,"--------------------" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
 
END REPORT 