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
# \brief module P73 Recurring Voucher Report

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_where_text CHAR(2048) 
END GLOBALS 

############################################################
# MODULE SCOPE VARIABLES
############################################################

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P73") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	#LET glob_rec_kandooreport.report_code = "P731" 

	OPEN WINDOW P197 with FORM "P197" 
	CALL windecoration_p("P197") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#DISPLAY glob_rec_kandooreport.header_text TO kandooreport.header_text 

	MENU " Recurring Voucher Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P73","menu-rec_voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL P73_rpt_query()

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 


		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW P197 
END MAIN 


FUNCTION P73_rpt_query() 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
--	DEFINE l_query_text CHAR(2048) 
	DEFINE l_base_currency LIKE glparms.base_currency_code 
	DEFINE l_conv_rate FLOAT 
	DEFINE l_rpt_output CHAR(50) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("P",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME glob_where_text ON 
		recur_code, 
		desc_text, 
		vend_code, 
		group_text, 
		int_ind, 
		int_num, 
		max_run_num, 
		start_date, 
		end_date, 
		last_vouch_date, 
		next_vouch_date, 
		total_amt, 
		curr_code, 
		conv_qty, 
		inv_text, 
		term_code, 
		hold_code, 
		tax_code, 
		rev_num, 
		rev_code, 
		rev_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P73","construct-recurhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_msgresp = kandoomsg("P",1042,"") #1042 Reporting on Recurring Voucher...

--	LET l_rpt_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
--	START REPORT P73_rpt_list TO l_rpt_output 	
--	LET l_msgresp = kandoomsg("P",1002,"")	#1002 Searching database - please wait

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"P73_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P73_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("P73_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT * FROM recurhead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_where_text clipped," ", 
	"ORDER BY cmpy_code,vend_code,recur_code" 
	PREPARE s_recurhead FROM l_query_text 
	DECLARE c_recurhead CURSOR FOR s_recurhead 



	FOREACH c_recurhead INTO l_rec_recurhead.* 
		DISPLAY "" at 1,36 
		DISPLAY l_rec_recurhead.recur_code at 1,36 

		SELECT * INTO l_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = l_rec_recurhead.cmpy_code 
		AND vend_code = l_rec_recurhead.vend_code 
		SELECT base_currency_code INTO l_base_currency 
		FROM glparms 
		WHERE cmpy_code = l_rec_recurhead.cmpy_code 
		AND key_code = "1" 
		IF l_rec_recurhead.conv_qty IS NULL THEN 
			LET l_conv_rate = get_conv_rate( glob_rec_kandoouser.cmpy_code, l_rec_recurhead.curr_code, 
			today,"S") 
		ELSE 
			LET l_conv_rate = l_rec_recurhead.conv_qty 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT P73_rpt_list(l_rpt_idx,
		l_rec_vendor.name_text, 
		l_rec_recurhead.*, 
		l_base_currency, 
		l_rec_vendor.currency_code, 
		l_conv_rate) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendor.name_text ,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
		 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT P73_rpt_list
	CALL rpt_finish("P73_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT P73_rpt_list(p_rpt_idx,p_name_text,p_recurhead,p_base_currency,p_curr_code,p_conv_rate)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_name_text LIKE vendor.name_text 
	DEFINE p_recurhead RECORD LIKE recurhead.*
	DEFINE p_base_currency LIKE glparms.base_currency_code
	DEFINE p_curr_code LIKE vendor.currency_code 
	DEFINE p_conv_rate LIKE recurhead.conv_qty 
	DEFINE l_temp_text CHAR(90)
	DEFINE l_rec_recurdetl RECORD LIKE recurdetl.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_vend_total FLOAT
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE i,x SMALLINT	 

	OUTPUT 
	left margin 0 
	PAGE length 66 
	ORDER external BY p_recurhead.cmpy_code, 
	p_recurhead.vend_code, 
	p_recurhead.recur_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_recurhead.vend_code 
			NEED 60 LINES 
			PRINT COLUMN 01, p_recurhead.vend_code, 
			COLUMN 10, p_name_text clipped 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 10, p_recurhead.recur_code, 
			COLUMN 19, p_recurhead.desc_text, 
			COLUMN 52, p_recurhead.group_text, 
			COLUMN 61, p_recurhead.start_date USING "dd/mm/yy", 
			COLUMN 70, p_recurhead.end_date USING "dd/mm/yy", 
			COLUMN 79, p_recurhead.inv_text[1,17] 
			LET l_temp_text = kandooword("recurhead.int_ind",p_recurhead.int_ind) 
			PRINT COLUMN 19, "Interval:", 
			COLUMN 34, p_recurhead.int_num USING "<<<"," ",l_temp_text clipped 
			PRINT COLUMN 19, "Progress:", 
			COLUMN 34, "Voucher ", 
			COLUMN 42, p_recurhead.run_num USING "<<&", " of ", 
			p_recurhead.max_run_num USING "<<<" 
			PRINT COLUMN 19, "Last Run:", 
			COLUMN 34, "Date: ", p_recurhead.run_date USING "dd/mm/yy", 
			COLUMN 50, "User: ", p_recurhead.run_code 
			LET l_temp_text = p_recurhead.inv_text clipped, ".", 
			p_recurhead.run_num USING "&&&" 
			SELECT * INTO l_rec_voucher.* 
			FROM voucher 
			WHERE cmpy_code = p_recurhead.cmpy_code 
			AND source_ind = "2" 
			AND source_text = p_recurhead.recur_code 
			AND vend_code = p_recurhead.vend_code 
			AND inv_text = l_temp_text 
			IF sqlca.sqlcode = NOTFOUND THEN 
				INITIALIZE l_rec_voucher.* TO NULL 
			END IF 
			PRINT COLUMN 19, "Last Voucher:", 
			COLUMN 34, "Date: ", l_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 50, "Voucher: ", l_rec_voucher.vouch_code USING "<<<<<<<<<<<<", 
			COLUMN 73, "Year/Period: "; 
			IF l_rec_voucher.year_num IS NOT NULL THEN 
				PRINT COLUMN 86, l_rec_voucher.year_num USING "####", "/", 
				l_rec_voucher.period_num USING "&&" 
			ELSE 
				SKIP 1 line 
			END IF 
			PRINT COLUMN 19, "Next Voucher:", 
			COLUMN 34, "Date: ", p_recurhead.next_vouch_date USING "dd/mm/yy" 
			SELECT unique 1 FROM recurdetl 
			WHERE cmpy_code = p_recurhead.cmpy_code 
			AND recur_code = p_recurhead.recur_code 

			IF sqlca.sqlcode = 0 THEN 
				SKIP 1 line 
				PRINT COLUMN 19, "Line--Type-Account------------", 
				"Description--------------------Analysis--------" 
				DECLARE c_recurdetl CURSOR FOR 
				SELECT * FROM recurdetl 
				WHERE cmpy_code = p_recurhead.cmpy_code 
				AND recur_code = p_recurhead.recur_code 
				ORDER BY line_num 

				FOREACH c_recurdetl INTO l_rec_recurdetl.* 
					PRINT COLUMN 17, l_rec_recurdetl.line_num, 
					COLUMN 26, l_rec_recurdetl.type_ind, 
					COLUMN 30, l_rec_recurdetl.acct_code, 
					COLUMN 49, l_rec_recurdetl.desc_text[1,29], 
					COLUMN 80, l_rec_recurdetl.analysis_text, 
					COLUMN 97, (l_rec_recurdetl.dist_amt * p_conv_rate) 
					USING "########&.&&", 
					COLUMN 110, l_rec_recurdetl.dist_amt USING "########&.&&" 

					CASE l_rec_recurdetl.type_ind 
						WHEN "J" 
							PRINT COLUMN 26, "Job : ", l_rec_recurdetl.job_code, 
							COLUMN 46, "Variation: ", l_rec_recurdetl.var_code 
							USING "<<<<<&", 
							COLUMN 65, "Quantity : ", l_rec_recurdetl.trans_qty 
							USING "<<<<<<<<<<<&.&&" 
							PRINT COLUMN 26, "Resource: ", l_rec_recurdetl.res_code, 
							COLUMN 65, "Cost Amt : ", l_rec_recurdetl.cost_amt 
							USING "<<<<<<<<<<<&.&&" 
							PRINT COLUMN 26, "Activity: ", l_rec_recurdetl.act_code, 
							COLUMN 65, "Charge Amt: ", l_rec_recurdetl.charge_amt 
							USING "<<<<<<<<<<<&.&&" 
						WHEN "P" 
							PRINT COLUMN 26, "Purchase Order: ", l_rec_recurdetl.po_num 
							USING "<<<<<<<<<<<<", 
							COLUMN 65, "Cost Amt:", l_rec_recurdetl.cost_amt 
							USING "<<<<<<<<<<&.&&" 
							PRINT COLUMN 26, "Line No.:", l_rec_recurdetl.po_line_num 
							USING "<<<<<<", 
							COLUMN 65, "Charge Amt:", l_rec_recurdetl.charge_amt 
							USING "<<<<<<<<<<&.&&" 
					END CASE 
				END FOREACH 
			END IF 

			PRINT COLUMN 97, "---- ", p_curr_code, " ---", 
			COLUMN 110, "---- ", p_base_currency, " ---" 
			IF sqlca.sqlcode = 0 THEN 
				PRINT COLUMN 77, "Distributed Total:", 
				COLUMN 97, (p_recurhead.dist_amt * p_conv_rate) 
				USING "########&.&&", 
				COLUMN 110, p_recurhead.dist_amt USING "########&.&&" 
			END IF 
			PRINT COLUMN 77, " Voucher Total:", 
			COLUMN 97, (p_recurhead.total_amt * p_conv_rate) 
			USING "########&.&&", 
			COLUMN 110, p_recurhead.total_amt USING "########&.&&", 
			COLUMN 123, p_conv_rate USING "######&.&&" 
			SKIP 2 LINES 

		AFTER GROUP OF p_recurhead.vend_code 
			PRINT COLUMN 97, "============", 
			COLUMN 110, "============" 
			LET l_vend_total = GROUP sum(p_recurhead.total_amt) 
			PRINT COLUMN 77, p_recurhead.vend_code, " Total:", 
			COLUMN 97, (l_vend_total * p_conv_rate) USING "########&.&&", 
			COLUMN 110, l_vend_total USING "########&.&&" 
			PRINT COLUMN 97, "============", 
			COLUMN 110, "============" 

		ON LAST ROW 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
