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
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LA_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LA7_GLOBALS.4gl"
GLOBALS 
--	DEFINE 
--	pr_company RECORD LIKE company.*, 
--	rpt_note LIKE rmsreps.report_text, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_pageno LIKE rmsreps.page_num, 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
END GLOBALS 

###########################################################################
# MAIN
#
# LA7 - Unpaid Vouchers By Shipment Report
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA7") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW l109a with FORM "L109a" 
	CALL windecoration_l("L109a") -- albo kd-763 

	MENU " Unpaid Vouchers By Shipment" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			IF LA7_rpt_query() THEN 
			END IF 

		ON ACTION "Print" 			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog('URS','','','','') 
 
		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW l109a 
END MAIN 
###########################################################################
# END MAIN
###########################################################################

###########################################################################
# FUNCTION LA7_rpt_query() 
#
# 
###########################################################################
FUNCTION LA7_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_status LIKE shiphead.ship_status_code, 
	pr_ware_code LIKE warehouse.desc_text, 
	pr_output CHAR(20) 

	LET msgresp = kandoomsg("U","1001","") #U1001 " Enter Selection Criteria - ESC TO Continue"

	CONSTRUCT BY NAME where_text ON voucher.vend_code, 
	voucher.vouch_code, 
	voucherdist.job_code, 
	shiphead.ship_status_code, 
	voucher.currency_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.due_date, 
	voucher.conv_qty, 
	voucher.total_amt, 
	voucher.dist_amt, 
	voucher.paid_amt, 
	voucher.paid_date, 
	voucher.term_code, 
	voucher.tax_code, 
	voucherdist.res_code, 
	voucher.disc_date, 
	voucher.taken_disc_amt, 
	voucher.poss_disc_amt, 
	voucher.post_flag, 
	voucher.period_num, 
	voucher.year_num, 
	voucher.entry_code, 
	voucher.entry_date 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"LA7_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LA7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET query_text = "SELECT voucher.*,", 
	"voucherdist.*,", 
	"shiphead.ship_status_code,", 
	"shiphead.ware_code ", 
	"FROM voucher,voucherdist,shiphead ", 
	"WHERE voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucherdist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND shiphead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND shiphead.ship_code = voucherdist.job_code ", 
	"AND voucherdist.type_ind = 'S' ", 
	"AND voucherdist.vend_code = voucher.vend_code ", 
	"AND voucherdist.vouch_code = voucher.vouch_code ", 
	"AND voucher.paid_amt != voucher.total_amt ", 
	"AND ",where_text clipped," ", 
	"ORDER BY voucherdist.job_code, ", 
	" voucherdist.vouch_code" 
	PREPARE s_voucher FROM query_text 


	#DISPLAY " Voucher: " at 1,5 attribute (yellow) 
	DECLARE c_voucher CURSOR FOR s_voucher 
	FOREACH c_voucher INTO pr_voucher.*, pr_voucherdist.*, 	pr_status, pr_ware_code

		#---------------------------------------------------------
		OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,	 
		pr_voucher.*, 
		pr_voucherdist.*, 
		pr_status, 
		pr_ware_code) 
		#---------------------------------------------------------		
		DISPLAY pr_voucher.vouch_code at 1,15 attribute (yellow) 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT LA7_rpt_list
	CALL rpt_finish("LA7_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 
###########################################################################
# FUNCTION LA7_rpt_query() 
#
# 
###########################################################################


###########################################################################
# REPORT LA7_rpt_list(p_rpt_idx, pr_voucher, pr_voucherdist, pr_status, pr_ware_code)
#
# 
###########################################################################
REPORT LA7_rpt_list(p_rpt_idx, pr_voucher, pr_voucherdist, pr_status, pr_ware_code)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_voucher RECORD LIKE voucher.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_status LIKE shiphead.ship_status_code, 
	pr_ware_code LIKE warehouse.desc_text, 
	pr_status_desc LIKE shipstatus.desc_text, 
	pr_ware_desc LIKE warehouse.desc_text, 
	cmpy_head CHAR(80), 
	col2, col SMALLINT 

	OUTPUT 
	left margin 0 

	ORDER external BY pr_voucherdist.job_code, pr_voucherdist.vouch_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 11, "Voucher", 
			COLUMN 19, "Vendor", 
			COLUMN 28, "Vendor", 
			COLUMN 54, "This", 
			COLUMN 72, "Voucher" 
			PRINT COLUMN 13, "Code", 
			COLUMN 20, "Code", 
			COLUMN 28, "Invoice No", 
			COLUMN 52, "Shipment", 
			COLUMN 63, "Curr", 
			COLUMN 73, "Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_voucherdist.job_code 
			NEED 3 LINES 
			LET pr_status_desc = NULL 
			SELECT desc_text INTO pr_status_desc FROM shipstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_status_code = pr_status 
			LET pr_ware_desc = NULL 
			SELECT desc_text INTO pr_ware_desc FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_ware_code 
			PRINT COLUMN 1, "Shipment:", pr_voucherdist.job_code, 
			COLUMN 19, "Status:", pr_status_desc[1,14], 
			COLUMN 41, "Warehouse:", pr_ware_desc 

		ON EVERY ROW 
			PRINT COLUMN 10, pr_voucher.vouch_code USING "########", 
			COLUMN 19, pr_voucher.vend_code, 
			COLUMN 28, pr_voucher.inv_text, 
			COLUMN 49, pr_voucherdist.dist_amt USING "---------&.&&", 
			COLUMN 63, pr_voucher.currency_code, 
			COLUMN 67, pr_voucher.total_amt USING "----------&.&&" 

		AFTER GROUP OF pr_voucherdist.job_code 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 9 LINES 
			SKIP 3 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT LA7_rpt_list(p_rpt_idx, pr_voucher, pr_voucherdist, pr_status, pr_ware_code)
###########################################################################