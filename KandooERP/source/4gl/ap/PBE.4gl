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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# MAIN
#
# PBE  -  Voucher Document Printing
############################################################
FUNCTION PBE_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PBE") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P168 with FORM "P168" 
			CALL windecoration_p("P168") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Voucher Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PBE","menu-voucher_rep-1") 
					CALL PBE_rpt_process(PBE_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT"
					CALL PBE_rpt_process(PBE_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P168 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PBE_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW R124 with FORM "P168" 
			CALL windecoration_p("P168") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PBE_rpt_query()) #save where clause in env 
			CLOSE WINDOW P168 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PBE_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION



############################################################
# FUNCTION PBE_rpt_query()
#
#
############################################################
FUNCTION PBE_rpt_query() 
	DEFINE l_where_text STRING 

	CLEAR FORM 
 
	MESSAGE kandoomsg2("G",1001,"") 
	#1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON voucher.vend_code, 
	vendor.name_text, 
	vendor.currency_code, 
	voucher.vouch_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.entry_date, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.total_amt, 
	voucher.paid_amt, 
	voucher.post_flag 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PBE","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR " Printing was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 


FUNCTION PBE_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_rec_vendor RECORD LIKE vendor.*
--	DEFINE l_query_line CHAR(2200)
	DEFINE l_endforeach SMALLINT 
--	DEFINE l_pr_output CHAR(60)

	DEFINE l_msgresp LIKE language.yes_flag 
--	DEFINE l_output STRING #report output file name inc. path

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PBE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PBE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_endforeach = false
	
	LET l_query_text = "SELECT voucher.*, vendor.* ", 
	"FROM voucher, vendor ", 
	"WHERE voucher.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND voucher.approved_code = 'N' ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PBE_rpt_list")].sel_text clipped," ",  
	"ORDER BY voucher.vouch_code" 
	
	PREPARE s_vouchvend FROM l_query_text 
	DECLARE c_vouchvend CURSOR FOR s_vouchvend 
	
	#- SET up the DECLARE FOR the voucherdist -#
	LET l_query_text = "SELECT * FROM voucherdist v ", 
	"WHERE v.cmpy_code = ? ", 
	"AND v.vend_code = ? ", 
	"AND v.vouch_code = ? ", 
	"ORDER BY v.vend_code, v.vouch_code,", 
	" v.line_num, v.cmpy_code" 
	PREPARE p_voucherdist FROM l_query_text 
	DECLARE c_voucherdist SCROLL CURSOR FOR p_voucherdist 


	FOREACH c_vouchvend INTO l_rec_voucher.*, l_rec_vendor.* 

		#- collect the voucherdist records -#
		OPEN c_voucherdist USING l_rec_voucher.cmpy_code, 
		l_rec_voucher.vend_code, 
		l_rec_voucher.vouch_code 
		WHILE true 
			FETCH NEXT c_voucherdist INTO l_rec_voucherdist.* 
			IF status = NOTFOUND THEN 
				EXIT WHILE 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT PBE_rpt_list(l_rpt_idx,
			l_rec_voucher.*, l_rec_voucherdist.*, l_rec_vendor.*) 
			IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
				EXIT WHILE 
			END IF 
			#---------------------------------------------------------			

		END WHILE 
		CLOSE c_voucherdist 
		IF l_endforeach THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH
	

	#------------------------------------------------------------
	FINISH REPORT PBE_rpt_list
	CALL rpt_finish("PBE_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# REPORT PBE_rpt_list(p_rpt_idx,p_rec_voucher, p_rec_voucherdist, p_rec_vendor)
#
#
############################################################
REPORT PBE_rpt_list(p_rpt_idx,p_rec_voucher,p_rec_voucherdist,p_rec_vendor)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_voucher RECORD LIKE voucher.*
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE p_rec_vendor RECORD LIKE vendor.*
	DEFINE l_tot_dist_amt DECIMAL(16,2) 
	DEFINE l_offset1, l_offset2 SMALLINT 
	DEFINE l_flag_newvouch SMALLINT
	DEFINE l_line SMALLINT	
	DEFINE i, cnt SMALLINT
	DEFINE l_line1 NCHAR(80) 
	DEFINE l_line2 NCHAR(80) 
	
	OUTPUT 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT COLUMN 058, "Voucher No: ", p_rec_voucher.vouch_code 
			PRINT COLUMN 059, "Cheque No: " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 002, p_rec_vendor.name_text, 
			COLUMN 043, "|", 
			COLUMN 045, p_rec_voucher.com1_text clipped 
			PRINT COLUMN 002, p_rec_vendor.addr1_text clipped, 
			COLUMN 043, "|", 
			COLUMN 044, "-------------------------------------" 
			IF p_rec_vendor.addr2_text IS NULL THEN 
				PRINT COLUMN 002, p_rec_vendor.city_text clipped, " ", 
				p_rec_vendor.state_code clipped, " ", 
				p_rec_vendor.post_code clipped, 
				COLUMN 043, "|", 
				COLUMN 045, "Due Date:", 
				COLUMN 060, p_rec_voucher.due_date USING "dd/mm/yy" 
				PRINT COLUMN 043, "|", 
				COLUMN 045, "Discount Date: ", 
				p_rec_voucher.disc_date USING "dd/mm/yy" 
			ELSE 
				PRINT COLUMN 002, p_rec_vendor.addr2_text clipped, 
				COLUMN 043, "|", 
				COLUMN 045, "Due Date:", 
				COLUMN 060, p_rec_voucher.due_date USING "dd/mm/yy" 
				PRINT COLUMN 002, p_rec_vendor.city_text clipped, " ", 
				p_rec_vendor.state_code clipped, " ", 
				p_rec_vendor.post_code clipped, 
				COLUMN 043, "|", 
				COLUMN 045, "Discount Date: ", 
				p_rec_voucher.disc_date USING "dd/mm/yy" 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
			PRINT COLUMN 002, "Dissection of Expenditure", 
			COLUMN 066, "|", 
			COLUMN 074, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]


		BEFORE GROUP OF p_rec_voucher.vouch_code 
			LET l_tot_dist_amt = 0 
			LET l_flag_newvouch = false 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			PRINT COLUMN 002, p_rec_voucherdist.desc_text clipped, 
			COLUMN 043, "|", 
			COLUMN 045, p_rec_voucherdist.acct_code, 
			COLUMN 066, "|", 
			COLUMN 070, p_rec_voucherdist.dist_amt USING "$$$,$$&.&&" 

			LET l_tot_dist_amt = l_tot_dist_amt + p_rec_voucherdist.dist_amt 

			IF lineno = 40 THEN 
				SKIP TO top OF PAGE 
			END IF 

		AFTER GROUP OF p_rec_voucher.vouch_code 
			#- IF the current l_line number IS less than 40 THEN insure -#
			#- TO file in blank lines up TO line 40.                  -#
			LET l_flag_newvouch = true 
			LET l_line = lineno 
			IF l_line < 40 THEN 
				FOR cnt = 1 TO (40 - l_line) 
					PRINT COLUMN 043, "|", 
					COLUMN 066, "|" 
				END FOR 
			END IF 

			PAGE TRAILER 
				PRINT COLUMN 001, "========================================", 
				"========================================" 
				IF l_flag_newvouch THEN 
					PRINT COLUMN 036, "| Total Amount Appropriated", 
					COLUMN 066, "|", 
					COLUMN 070, l_tot_dist_amt USING "$$$,$$&.&&" 
				ELSE 
					PRINT COLUMN 036, "| Total Amount Appropriated", 
					COLUMN 066, "|", 
					COLUMN 067, "Balance C/Fwd" 
				END IF 
				PRINT COLUMN 001, "========================================", 
				"========================================" 
				PRINT COLUMN 002, "Date", 
				COLUMN 011, "|", 
				COLUMN 013, "Invoice", 
				COLUMN 034, "|", 
				COLUMN 036, "Particulars", 
				COLUMN 066, "|" 
				PRINT COLUMN 001, "----------------------------------------", 
				"----------------------------------------" 
				PRINT COLUMN 002, p_rec_voucher.vouch_date USING "dd/mm/yy", 
				COLUMN 011, "|", 
				COLUMN 013, p_rec_voucher.inv_text clipped, 
				COLUMN 034, "|", 
				COLUMN 036, p_rec_voucher.com2_text clipped, 
				COLUMN 066, "|", 
				COLUMN 070, p_rec_voucher.total_amt USING "$$$,$$&.&&" 
				PRINT COLUMN 011, "|", 
				COLUMN 034, "|", 
				COLUMN 066, "|" 
				PRINT COLUMN 011, "|", 
				COLUMN 034, "|", 
				COLUMN 066, "|" 
				PRINT COLUMN 011, "|", 
				COLUMN 034, "|", 
				COLUMN 066, "|" 
				PRINT COLUMN 011, "|", 
				COLUMN 034, "|", 
				COLUMN 066, "|" 
				PRINT COLUMN 001, "----------------------------------------", 
				"----------------------------------------" 
				PRINT COLUMN 002, " ", 
				COLUMN 041, "| Less Discount Allowed", 
				COLUMN 070, p_rec_voucher.poss_disc_amt USING "$$$,$$&.&&" 
				PRINT COLUMN 002, " ", 
				COLUMN 041, "| ===============" 
				PRINT COLUMN 002, " ", 
				COLUMN 041, "| Total Amount Payable ", 
				COLUMN 067, p_rec_voucher.total_amt - p_rec_voucher.poss_disc_amt 
				USING "$$,$$$,$$&.&&" 
				PRINT COLUMN 002, "Entered in Voucher Register............", 
				COLUMN 041, "|=======================================" 
				PRINT COLUMN 002, "Checked FOR double payment.............", 
				COLUMN 041, "| I authorise payment of this account" 
				PRINT COLUMN 002, "Marked off against ORDER...............", 
				COLUMN 041, "| " 
				PRINT COLUMN 002, "Appropriation correct..................", 
				COLUMN 041, "| " 
				PRINT COLUMN 002, "Performance of Service.................", 
				COLUMN 041, "|" 
				PRINT COLUMN 002, "Checked FOR discounts..................", 
				COLUMN 041, "|" 
				PRINT COLUMN 002, "Rates of charge........................", 
				COLUMN 041, "| ______________________________" 
				PRINT COLUMN 002, "Computations...........................", 
				COLUMN 041, "|", 
				COLUMN 051, "Authorising Office" 
				PRINT COLUMN 041, "|---------------------------------------" 
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 




