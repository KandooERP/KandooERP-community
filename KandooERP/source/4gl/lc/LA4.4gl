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
GLOBALS "../lc/LA4_GLOBALS.4gl" 
# \brief module LA4 Shipments   By Voucher Report

GLOBALS 
--	DEFINE 
--	pr_company RECORD LIKE company.*, 
--	rpt_note LIKE rmsreps.report_text, 
--	rpt_wid LIKE rmsreps.report_width_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	rpt_pageno LIKE rmsreps.page_num, 
	DEFINE pr_tot_dist LIKE voucherdist.dist_amt 
	DEFINE pr_lines_printed SMALLINT 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
END GLOBALS 

###########################################################################
# MAIN 
#
#
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA4") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW l109 with FORM "L109" 
	CALL windecoration_l("L109") -- albo kd-763 

	LET pr_tot_dist = 0 
	LET pr_lines_printed = 0 
	MENU " Shipments By Voucher Report" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			IF LA4_rpt_query() THEN 
			END IF 

		ON ACTION "Print" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog('URS','','','','') 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
			
	END MENU 
	CLOSE WINDOW l109 
END MAIN 
###########################################################################
# END MAIN 
###########################################################################


###########################################################################
# FUNCTION LA4_rpt_query()  
#
#
###########################################################################
FUNCTION LA4_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_output CHAR(20) 

	LET msgresp = kandoomsg("U",1001,"") #U1001 " Enter Selection Criteria - ESC TO Continue"

	CONSTRUCT BY NAME where_text ON voucher.vend_code, 
	vendor.name_text, 
	voucher.vouch_code, 
	voucherdist.job_code, 
	vendor.currency_code, 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"LA4_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LA4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = "SELECT voucher.*, ", 
	"voucherdist.* ", 
	"FROM voucher,", 
	"vendor, ", 
	"voucherdist ", 
	"WHERE voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucherdist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND voucherdist.vend_code = voucher.vend_code ", 
	"AND voucherdist.vouch_code = voucher.vouch_code ", 
	"AND voucherdist.type_ind = 'S' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY voucher.vend_code,", 
	"voucher.vouch_code,", 
	"voucherdist.line_num" 
	PREPARE s_voucher FROM query_text 
	--DISPLAY " Voucher: " at 1,5 attribute (yellow) 
	DECLARE c_voucher CURSOR FOR s_voucher 
	FOREACH c_voucher INTO pr_voucher.*, pr_voucherdist.*

	 	#---------------------------------------------------------
		OUTPUT TO REPORT LA4_rpt_list(l_rpt_idx,
		pr_voucher.*, pr_voucherdist.*) 
	 	#---------------------------------------------------------

		#DISPLAY pr_voucher.vouch_code at 1,15 attribute (yellow) 
	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT LA4_rpt_list
	CALL rpt_finish("LA4_rpt_list")
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
# END FUNCTION LA4_rpt_query()  
#
#
###########################################################################


###########################################################################
# REPORT LA4_rpt_list(p_rpt_idx,pr_voucher,pr_voucherdist) 
#
#
###########################################################################
REPORT LA4_rpt_list(p_rpt_idx,pr_voucher,pr_voucherdist)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	pr_voucher RECORD LIKE voucher.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_vend_name_text LIKE vendor.name_text, 
	cmpy_head CHAR(80), 
	col2, col SMALLINT 

	OUTPUT 
	left margin 0 

	ORDER external BY pr_voucher.vend_code, 
	pr_voucher.vouch_code, 
	pr_voucherdist.line_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Vendor", 
			COLUMN 9, "Voucher", 
			COLUMN 18, "Voucher", 
			COLUMN 28, "Vendor", 
			COLUMN 47, "Shipment", 
			COLUMN 57, "Cost", 
			COLUMN 68, "Amount" 
			PRINT COLUMN 10, "Code", 
			COLUMN 19, "Date", 
			COLUMN 26, "Invoice No", 
			COLUMN 49, "Code", 
			COLUMN 57, "Type" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_voucher.vend_code 
			SELECT name_text INTO pr_vend_name_text FROM vendor 
			WHERE cmpy_code = pr_voucher.cmpy_code 
			AND vend_code = pr_voucher.vend_code 
			PRINT COLUMN 1, pr_voucher.vend_code, 
			COLUMN 10, pr_vend_name_text 

		ON EVERY ROW 
			LET pr_lines_printed = pr_lines_printed + 1 
			PRINT COLUMN 8, pr_voucher.vouch_code USING "########", 
			COLUMN 17, pr_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 26, pr_voucher.inv_text, 
			COLUMN 47, pr_voucherdist.job_code, 
			COLUMN 56, pr_voucherdist.res_code, 
			COLUMN 65, pr_voucherdist.dist_amt USING "--------&.&&", 
			COLUMN 78, pr_voucher.currency_code 
			LET pr_tot_dist = pr_tot_dist + pr_voucherdist.dist_amt 

		AFTER GROUP OF pr_voucher.vouch_code 
			IF pr_lines_printed > 1 THEN 
				NEED 4 LINES 
				PRINT COLUMN 65, "------------" 
				PRINT COLUMN 65, pr_tot_dist USING "---------.&&" 
			END IF 
			LET pr_tot_dist = 0 
			LET pr_lines_printed = 0 
			SKIP 1 line 

		AFTER GROUP OF pr_voucher.vend_code 
			SKIP 1 LINES 

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
# END REPORT LA4_rpt_list(p_rpt_idx,pr_voucher,pr_voucherdist) 
###########################################################################