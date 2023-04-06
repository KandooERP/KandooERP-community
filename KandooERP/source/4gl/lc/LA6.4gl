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
# LA6 - Shipment Summary REPORT.  List in syummary form details of all shipments
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LA_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LA6_GLOBALS.4gl"

GLOBALS 
--	DEFINE 
--	rpt_note LIKE rmsreps.report_text, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_pageno LIKE rmsreps.page_num, 
--	pr_output CHAR(20), 
--	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
--	pr_company RECORD LIKE company.*, 
	DEFINE where_part STRING
	DEFINE query_text STRING 
--	rpt_date LIKE rmsreps.report_date, 
--	rpt_time CHAR(8), 
--	line1, line2 CHAR(120), 
	DEFINE ret_code INTEGER 
	DEFINE i SMALLINT 
--	DEFINE i,offset1, offset2 SMALLINT
--	rpt_head SMALLINT, 
--	col, col2 SMALLINT, 
--	cmpy_head CHAR(130), 
	DEFINE passed_receipt_text LIKE shiprec.goods_receipt_text 
	DEFINE pr_temp RECORD 
		dest LIKE printcodes.print_code 
	END RECORD 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE destination LIKE printcodes.print_code 
END GLOBALS 

###########################################################################
# MAIN 
#
# LA6 - Shipment Summary REPORT.  List in syummary form details of all shipments
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("LA6") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW l168 with FORM "L168" 
	CALL windecoration_l("L168") -- albo kd-763 

	MENU "Shipment Summary" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 

			IF LA6_rpt_query() THEN 
				NEXT option "Print Manager" 
 
			END IF 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW l168 
END MAIN 
###########################################################################
# END MAIN 
###########################################################################


###########################################################################
# FUNCTION LA6_rpt_query()  
#
# 
###########################################################################
FUNCTION LA6_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_ship_num DECIMAL(8,0) {numeric shipment number FOR sort sequence } 

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
		shiphead.finalised_flag, 
		shipdetl.part_code, 
		shipdetl.desc_text 

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
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"LA6_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT LA6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
		#------------------------------------------------------------

		LET query_text = "SELECT ", 
		" shiphead.cmpy_code,shiphead.ship_code ", 
		" FROM shiphead, shipdetl ", 
		" WHERE shiphead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shipdetl.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND shiphead.ship_code = shipdetl.ship_code ", 
		" AND shiphead.ship_type_ind = 1 ", 
		" AND ", where_part clipped, 
		" group by shiphead.cmpy_code, shiphead.ship_code ", 
		" ORDER BY shiphead.cmpy_code, ", 
		" shiphead.ship_code" 
		PREPARE s_invoice FROM query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 
		{
		      OPEN WINDOW w1_LA6 AT 19,16 with 2 rows,46 columns     -- albo  KD-763
		         ATTRIBUTE(border)
		}
		DISPLAY " Reporting on Shipment..." at 1,1 
		FOREACH c_invoice INTO pr_shiphead.cmpy_code, pr_shiphead.ship_code 
			SELECT * 
			INTO pr_shiphead.* 
			FROM shiphead 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND ship_code = pr_shiphead.ship_code 
			AND ship_type_ind = 1 
			LET pr_ship_num = pr_shiphead.ship_code USING "&&&&&&&&" 
			--DISPLAY pr_shiphead.ship_code at 1,25 
			#---------------------------------------------------------
			OUTPUT TO REPORT LA6_rpt_list(l_rpt_idx,
			pr_shiphead.*,pr_ship_num) 
			#---------------------------------------------------------
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT LA6_rpt_list
		CALL rpt_finish("LA6_rpt_list")
		#------------------------------------------------------------		

		EXIT WHILE
		 
	END WHILE
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 
###########################################################################
# FUNCTION LA6_rpt_query()  
#
# 
###########################################################################



###########################################################################
# FUNCTION LA6_rpt_query()  
#
# 
###########################################################################
REPORT LA6_rpt_list(p_rpt_idx,pr_shiphead, pr_ship_num) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_vend_name LIKE vendor.name_text, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pr_ship_num DECIMAL(8,0), 
	pr_total_cost_amt LIKE shiphead.total_amt, 
	s, len, pr_inv_count, pr_inv_line SMALLINT 

	OUTPUT 

	ORDER BY pr_shiphead.cmpy_code, 
	pr_ship_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 1, "--Shipment--", 
			COLUMN 14, "Vendor", 
			COLUMN 25, "FOB", 
			COLUMN 33, "Curr", 
			COLUMN 38, "Exchange", 
			COLUMN 50, "Duty", 
			COLUMN 60, "FOB", 
			COLUMN 71, "Invoiced", 
			COLUMN 84, "Duty", 
			COLUMN 96, "Other", 
			COLUMN 107, "Late", 
			COLUMN 118, "Total", 
			COLUMN 125, "Status" 
			PRINT COLUMN 1, "Code", 
			COLUMN 9, "Type", 
			COLUMN 15, "Code", 
			COLUMN 25, "Entered", 
			COLUMN 40, "Rate", 
			COLUMN 50, "Entered", 
			COLUMN 60, "Invoiced", 
			COLUMN 73, "Base", 
			COLUMN 82, "Invoiced", 
			COLUMN 96, "Costs", 
			COLUMN 107, "Costs", 
			COLUMN 118, "Costs", 
			COLUMN 125, "Final" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		AFTER GROUP OF pr_ship_num 
			SKIP 1 LINES 
			LET pr_total_cost_amt = pr_shiphead.fob_inv_cost_amt 
			+ pr_shiphead.duty_inv_amt 
			+ pr_shiphead.other_cost_amt 
			+ pr_shiphead.late_cost_amt 
			PRINT COLUMN 1, pr_shiphead.ship_code, 
			COLUMN 9, pr_shiphead.ship_type_code, 
			COLUMN 13, pr_shiphead.vend_code, 
			COLUMN 22, pr_shiphead.fob_ent_cost_amt USING "------&.&&", 
			COLUMN 33, pr_shiphead.curr_code, 
			COLUMN 37, pr_shiphead.conversion_qty USING "###&.&&&&", 
			COLUMN 47, pr_shiphead.duty_ent_amt USING "------&.&&", 
			COLUMN 58, pr_shiphead.fob_curr_cost_amt USING "------&.&&", 
			COLUMN 69, pr_shiphead.fob_inv_cost_amt USING "------&.&&", 
			COLUMN 81, pr_shiphead.duty_inv_amt USING "-----&.&&", 
			COLUMN 91, pr_shiphead.other_cost_amt USING "------&.&&", 
			COLUMN 102, pr_shiphead.late_cost_amt USING "------&.&&", 
			COLUMN 113, pr_total_cost_amt USING "------&.&&", 
			COLUMN 125, pr_shiphead.ship_status_code, 
			COLUMN 130, pr_shiphead.finalised_flag 


		ON LAST ROW 
			NEED 4 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 31, "----------------------------------------", 
			"-----------------------------------------", 
			"---------------------" 
			PRINT COLUMN 1 , "Report Totals: ", 
			COLUMN 67 ,sum(pr_shiphead.fob_inv_cost_amt) using"--------&.&&", 
			COLUMN 81 ,sum(pr_shiphead.duty_inv_amt) USING "-----&.&&", 
			COLUMN 91 ,sum(pr_shiphead.other_cost_amt) USING "------&.&&", 
			COLUMN 102,sum(pr_shiphead.late_cost_amt) USING "------&.&&", 
			COLUMN 113, sum(pr_shiphead.fob_inv_cost_amt) 
			+ sum(pr_shiphead.duty_inv_amt) 
			+ sum(pr_shiphead.other_cost_amt) 
			+ sum(pr_shiphead.late_cost_amt) USING "------&.&&" 
			NEED 9 LINES
			 
			SKIP 3 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT