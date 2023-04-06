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
############################################################
# FUNCTION PA1_main()
#
# Vendor List Report
############################################################
FUNCTION PA1_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PA1") 	#Initial UI Init

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 			
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Vendor Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PA1","menu-vendor-1")
		 			CALL rpt_rmsreps_reset(NULL)
					CALL PA1_rpt_process(PA1_rpt_query()) 					 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PA1_rpt_process(PA1_rpt_query()) 
		
				ON ACTION "Print Manager" #COMMAND KEY("P", f11) "Print" " Print OR View using RMS"
					CALL run_prog("URS", "", "", "", "") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			
			CLOSE WINDOW P105
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA1_rpt_query()) #save where clause in env 
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA1_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
############################################################
#END FUNCTION PA1_main()
############################################################


############################################################
# FUNCTION PA1_rpt_query()
#
#
############################################################
FUNCTION PA1_rpt_query() 
	DEFINE l_where_text STRING 

	CLEAR FORM 
	MESSAGE kandoomsg2("W", 1001, "") #1001 " Enter criteria FOR selection - ESC TO begin search"
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
			CALL publish_toolbar("kandoo","PA1","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR "Report generation was aborted"  
		RETURN NULL	 
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION
############################################################
# END FUNCTION PA1_rpt_query()
############################################################


############################################################
# FUNCTION PA1_rpt_query(p_where_text)
#
#
############################################################
FUNCTION PA1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_vendor RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
		term_code LIKE vendor.term_code, 
		addr1_text LIKE vendor.addr1_text, 
		addr2_text LIKE vendor.addr2_text, 
		city_text LIKE vendor.city_text, 
		state_code LIKE vendor.state_code, 
		post_code LIKE vendor.post_code, 
		fax_text LIKE vendor.fax_text, 
		contact_text LIKE vendor.contact_text, 
		tele_text LIKE vendor.tele_text, 
		extension_text LIKE vendor.extension_text, 
		curr_amt LIKE vendor.curr_amt, 
		highest_bal_amt LIKE vendor.highest_bal_amt, 
		over1_amt LIKE vendor.over1_amt, 
		bal_amt LIKE vendor.bal_amt, 
		over30_amt LIKE vendor.over30_amt, 
		onorder_amt LIKE vendor.onorder_amt, 
		over60_amt LIKE vendor.over60_amt, 
		limit_amt LIKE vendor.limit_amt, 
		over90_amt LIKE vendor.over90_amt, 
		hold_code LIKE vendor.hold_code, 
		avg_day_paid_num LIKE vendor.avg_day_paid_num, 
		currency_code LIKE vendor.currency_code, 
		last_vouc_date LIKE vendor.last_vouc_date, 
		setup_date LIKE vendor.setup_date, 
		last_payment_date LIKE vendor.last_payment_date, 
		last_mail_date LIKE vendor.last_mail_date 
	END RECORD 
	DEFINE l_output STRING #report output file name inc. path
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	IF glob_rec_apparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT vend_code,", 
		"name_text,", 
		"term_code,", 
		"addr1_text,", 
		"addr2_text,", 
		"city_text,", 
		"state_code,", 
		"post_code,", 
		"fax_text,", 
		"contact_text,", 
		"tele_text,", 
		"extension_text,", 
		"curr_amt,", 
		"highest_bal_amt,", 
		"over1_amt,", 
		"bal_amt,", 
		"over30_amt,", 
		"onorder_amt,", 
		"over60_amt,", 
		"limit_amt,", 
		"over90_amt,", 
		"hold_code,", 
		"avg_day_paid_num,", 
		"currency_code,", 
		"last_vouc_date,", 
		"setup_date,", 
		"last_payment_date ", 
		"FROM vendor WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" ", 
		"AND ", 
		p_where_text clipped, 
		" ORDER BY vend_code " 
	ELSE 
		LET l_query_text = "SELECT vend_code,", 
		"name_text,", 
		"term_code,", 
		"addr1_text,", 
		"addr2_text,", 
		"city_text,", 
		"state_code,", 
		"post_code,", 
		"fax_text,", 
		"contact_text,", 
		"tele_text,", 
		"extension_text,", 
		"curr_amt,", 
		"highest_bal_amt,", 
		"over1_amt,", 
		"bal_amt,", 
		"over30_amt,", 
		"onorder_amt,", 
		"over60_amt,", 
		"limit_amt,", 
		"over90_amt,", 
		"hold_code,", 
		"avg_day_paid_num,", 
		"currency_code,", 
		"last_vouc_date,", 
		"setup_date,", 
		"last_payment_date ", 
		"FROM vendor WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" ", 
		"AND ", 
		p_where_text clipped, 
		" ORDER BY name_text, vend_code " 
	END IF 
	
	PREPARE s_vendor 
	FROM l_query_text 
	
	DECLARE c_vendor CURSOR FOR s_vendor 

	FOREACH c_vendor INTO l_rec_vendor.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PA1_rpt_list(l_rpt_idx,
		l_rec_vendor.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendor.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PA1_rpt_list
	CALL rpt_finish("PA1_rpt_list")
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
# REPORT PA1_rpt_list(p_rpt_idx,p_vendor)
#
#
############################################################
REPORT PA1_rpt_list(p_rpt_idx,p_vendor) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_vendor RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
		term_code LIKE vendor.term_code, 
		addr1_text LIKE vendor.addr1_text, 
		addr2_text LIKE vendor.addr2_text, 
		city_text LIKE vendor.city_text, 
		state_code LIKE vendor.state_code, 
		post_code LIKE vendor.post_code, 
		fax_text LIKE vendor.fax_text, 
		contact_text LIKE vendor.contact_text, 
		tele_text LIKE vendor.tele_text, 
		extension_text LIKE vendor.extension_text, 
		curr_amt LIKE vendor.curr_amt, 
		highest_bal_amt LIKE vendor.highest_bal_amt, 
		over1_amt LIKE vendor.over1_amt, 
		bal_amt LIKE vendor.bal_amt, 
		over30_amt LIKE vendor.over30_amt, 
		onorder_amt LIKE vendor.onorder_amt, 
		over60_amt LIKE vendor.over60_amt, 
		limit_amt LIKE vendor.limit_amt, 
		over90_amt LIKE vendor.over90_amt, 
		hold_code LIKE vendor.hold_code, 
		avg_day_paid_num LIKE vendor.avg_day_paid_num, 
		currency_code LIKE vendor.currency_code, 
		last_vouc_date LIKE vendor.last_vouc_date, 
		setup_date LIKE vendor.setup_date, 
		last_payment_date LIKE vendor.last_payment_date, 
		last_mail_date LIKE vendor.last_mail_date 
	END RECORD 
--	DEFINE l_line1 CHAR(80)
--	DEFINE l_line2 CHAR(80) 
--	DEFINE l_offset1 SMALLINT
--	DEFINE l_offset2 SMALLINT 
--	DEFINE len INTEGER
--	DEFINE s INTEGER
	
	 
	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, 
			"Vendor", COLUMN 25, 
			"Vendor", COLUMN 40, 
			"Term" 
			PRINT COLUMN 25, 
			"Name", COLUMN 40, 
			"Code", COLUMN 45, 
			"Address", COLUMN 106, 
			"City", COLUMN 123, 
			"State", COLUMN 129, 
			"Post" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1, 
			p_vendor.vend_code, COLUMN 10, 
			p_vendor.name_text, COLUMN 41, 
			p_vendor.term_code, COLUMN 45, 
			p_vendor.addr1_text[1, 30], COLUMN 76, 
			p_vendor.addr2_text[1, 29], COLUMN 106, 
			p_vendor.city_text[1, 18], COLUMN 125, 
			p_vendor.state_code[1, 3], COLUMN 129, 
			p_vendor.post_code[1, 4] 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, 
			"Total Vendors: ", 
			count(*) USING "#####" 
			SKIP 4 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
############################################################
# END REPORT PA1_rpt_list(p_rpt_idx,p_vendor)
############################################################