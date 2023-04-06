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
GLOBALS 
	DEFINE glob_tot_amt DECIMAL(16,2) 
	DEFINE glob_tot_limit DECIMAL(16,2) 
	DEFINE glob_tot_onord DECIMAL(16,2) 
END GLOBALS 

###########################################################################
# FUNCTION PA5_main()
#
# Vendor Credit Status
###########################################################################
FUNCTION PA5_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PA5")  

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Credit Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PA5","menu-credit-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA5_rpt_query() 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " Selection Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL PA5_rpt_query() 
		
				ON ACTION "Print Manager"			#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS", "", "", "", "") 
		
				ON ACTION "CANCEL" 			#COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA5_rpt_query()) #save where clause in env 
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA5_rpt_process(get_url_sel_text())
	END CASE
	
END FUNCTION 
###########################################################################
# END FUNCTION PA5_main()
###########################################################################


############################################################
# FUNCTION PA5_rpt_query()
#
#
############################################################
FUNCTION PA5_rpt_query() 
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
			CALL publish_toolbar("kandoo","PA5","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR "Report Generation was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF
END FUNCTION 
############################################################
# END FUNCTION PA5_rpt_query()
############################################################

############################################################
# FUNCTION PA5_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PA5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_vendor RECORD 
				vend_code LIKE vendor.vend_code, 
				name_text LIKE vendor.name_text, 
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
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET glob_tot_amt = 0 
	LET glob_tot_onord = 0 
	LET glob_tot_limit = 0 

	IF glob_rec_apparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT vend_code, name_text, ", 
		"addr1_text, addr2_text, ", 
		"city_text, state_code, ", 
		"post_code, fax_text, ", 
		"contact_text, tele_text, ", 
		"extension_text, curr_amt, ", 
		"highest_bal_amt, ", 
		" over1_amt, bal_amt, ", 
		"over30_amt, onorder_amt, ", 
		"over60_amt, limit_amt, ", 
		"over90_amt, hold_code, ", 
		"avg_day_paid_num, currency_code, ", 
		"last_vouc_date, ", 
		"setup_date, last_payment_date ", 
		"FROM vendor ", 
		"WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		p_where_text clipped, 
		"ORDER BY vend_code " 
	ELSE 
		LET l_query_text = "SELECT vend_code, name_text, ", 
		"addr1_text, addr2_text, ", 
		"city_text, state_code, ", 
		"post_code, fax_text, ", 
		"contact_text, tele_text, ", 
		"extension_text, curr_amt, ", 
		"highest_bal_amt, ", 
		" over1_amt, bal_amt, ", 
		"over30_amt, onorder_amt, ", 
		"over60_amt, limit_amt, ", 
		"over90_amt, hold_code, ", 
		"avg_day_paid_num, currency_code, ", 
		"last_vouc_date, ", 
		"setup_date, last_payment_date ", 
		"FROM vendor ", 
		"WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		p_where_text clipped, 
		"ORDER BY name_text, vend_code " 
	END IF 

	PREPARE choice 
	FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_vendor.*
		#---------------------------------------------------------
		OUTPUT TO REPORT PA5_rpt_list(l_rpt_idx,
		l_rec_vendor.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendor.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT PA5_rpt_list
	CALL rpt_finish("PA5_rpt_list")
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
# REPORT PA5_rpt_list(p_rpt_idx,p_rec_vendor)
#
#
############################################################
REPORT PA5_rpt_list(p_rpt_idx,p_rec_vendor) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_vendor RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
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

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, 
			"Vendor", COLUMN 20, 
			"Name", COLUMN 45, 
			"Credit", COLUMN 60, 
			"Balance", COLUMN 75, 
			"Highest", COLUMN 90, 
			"On", COLUMN 102, 
			"Last", COLUMN 112, 
			"Last", COLUMN 123, 
			"Currency" 
			PRINT COLUMN 1, 
			" ID ", COLUMN 45, 
			"Limit", COLUMN 75, 
			"Balance", COLUMN 90, 
			"Order", COLUMN 102, 
			"Sale", COLUMN 112, 
			"Payment" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
		ON EVERY ROW 
			PRINT COLUMN 1, 
			p_rec_vendor.vend_code clipped, COLUMN 12, 
			p_rec_vendor.name_text[1, 25], COLUMN 40, 
			p_rec_vendor.limit_amt USING "-------,---.&&", COLUMN 55, 
			p_rec_vendor.bal_amt USING "-------,---.&&", COLUMN 70, 
			p_rec_vendor.highest_bal_amt USING "-------,---.&&", COLUMN 85, 
			p_rec_vendor.onorder_amt USING "-------,---.&&", COLUMN 100, 
			p_rec_vendor.last_vouc_date USING "dd/mm/yy", COLUMN 110, 
			p_rec_vendor.last_payment_date USING "dd/mm/yy", COLUMN 125, 
			p_rec_vendor.currency_code 
			LET glob_tot_onord = glob_tot_onord + conv_currency(p_rec_vendor.onorder_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_vendor.currency_code , "F", today, "B") 
			LET glob_tot_limit = glob_tot_limit + conv_currency(p_rec_vendor.limit_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_vendor.currency_code , "F", today, "B") 
			LET glob_tot_amt = glob_tot_amt + conv_currency(p_rec_vendor.bal_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_vendor.currency_code , "F", today, "B") 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, 
			"Totals In Base Currency: ", COLUMN 40, 
			"----------------------------------------", 
			"--------------------" 
			PRINT COLUMN 1, 
			"Total Vendors: ", 
			count(*) USING "###", 
			2 spaces, 
			"Totals: ", COLUMN 38, 
			glob_tot_limit USING "---------,---.&&", COLUMN 52, 
			glob_tot_amt USING "---------,---.&&", COLUMN 83, 
			glob_tot_onord USING "---------,---.&&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
############################################################
# REPORT PA5_rpt_list(p_rpt_idx,p_rec_vendor)
############################################################