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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"
###########################################################################
# FUNCTION PA2_main()
#
# Vendor Phone List
###########################################################################
FUNCTION PA2_main() 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("PA2") 	#Initial UI Init

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 			
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Vendor Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PA2","menu-vendor-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA2_rpt_process(PA2_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " Selection Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL PA2_rpt_process(PA2_rpt_query()) 
		
				ON ACTION "Print Manager" 		#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS", "", "", "", "") 
		
				ON ACTION "CANCEL" 		#COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA2_rpt_query()) #save where clause in env 
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA2_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
###########################################################################
# END FUNCTION PA2_main()
###########################################################################


############################################################
# FUNCTION PA2_rpt_query()
#
#
############################################################
FUNCTION PA2_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U", 1001, "") 
	CONSTRUCT BY NAME l_where_text	ON 
		vend_code, 
		name_text, 
		currency_code, 
		addr1_text, 
		addr2_text, 
		addr3_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		avg_day_paid_num, 
		type_code, 
		term_code, 
		tax_code, 
		hold_code, 
		pay_meth_ind, 
		usual_acct_code, 
		vat_code, 
		last_po_date, 
		last_vouc_date, 
		last_payment_date, 
		setup_date, 
		highest_bal_amt, 
		ytd_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PA2","construct-vendor-1") 

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
############################################################
# END FUNCTION PA2_rpt_query()
############################################################


############################################################
# FUNCTION PA2_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION PA2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	IF glob_rec_apparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT * ", 
		"FROM vendor ", 
		"WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		p_where_text clipped, 
		" ORDER BY vend_code " 
	ELSE 
		LET l_query_text = "SELECT * ", 
		"FROM vendor ", 
		"WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		p_where_text clipped, 
		" ORDER BY name_text, vend_code " 
	END IF 
	
	PREPARE choice 
	FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_vendor.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PA2_rpt_list(l_rpt_idx,
		l_rec_vendor.*)
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendor.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PA2_rpt_list
	CALL rpt_finish("PA2_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION PA2_rpt_query(p_where_text)
############################################################


############################################################
# REPORT PA2_rpt_list(p_rpt_idx,p_vendor)
#
#
############################################################
REPORT PA2_rpt_list(p_rpt_idx,p_vendor) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_vendor RECORD LIKE vendor.* 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			IF p_vendor.city_text IS NULL THEN 
				LET p_vendor.city_text = p_vendor.addr2_text 
			END IF 
			PRINT COLUMN 01, p_vendor.vend_code, 
			COLUMN 10, p_vendor.name_text[1,29], 
			COLUMN 40, p_vendor.city_text[1,20], 
			COLUMN 61, p_vendor.state_code[1,3], 
			COLUMN 65, p_vendor.tele_text[1,18], 
			COLUMN 84, p_vendor.fax_text[1,18], 
			COLUMN 103,p_vendor.contact_text[1,18], 
			COLUMN 122,p_vendor.vat_code 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, "Total Customers: ", count(*) USING "#####" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PA2_rpt_list(p_rpt_idx,p_vendor)
############################################################