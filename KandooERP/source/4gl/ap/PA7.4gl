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
# FUNCTION PA7_main()
#
# Vendor History Report
############################################################
FUNCTION PA7_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PA7") 	#Initial UI Init 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

		OPEN WINDOW P107 with FORM "P107" 
		CALL windecoration_p("P107") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	
		MENU " History Report" 
	
			BEFORE MENU 
				CALL publish_toolbar("kandoo","PA7","menu-history_report-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA7_rpt_process(PA7_rpt_query()) 
						
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "Report" 				#COMMAND "Report" " Selection Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL PA7_rpt_process(PA7_rpt_query())  
	
			ON ACTION "Print Manager" 			#COMMAND "Print" " Print OR view using RMS"
				CALL run_prog("URS", "", "", "", "") 

			ON ACTION "CANCEL" 				#COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
				EXIT MENU 
	
		END MENU 
	
		CLOSE WINDOW P107 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P107 with FORM "P107" 
			CALL windecoration_p("P107") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA7_rpt_query()) #save where clause in env 
			CLOSE WINDOW P107 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA7_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
############################################################
# END FUNCTION PA7_main()
############################################################

############################################################
# FUNCTION PA7_rpt_query()
#
#
############################################################
FUNCTION PA7_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U", 1001, "") 
	CONSTRUCT BY NAME l_where_text	ON 
		vendorhist.vend_code, 
		vendorhist.year_num, 
		vendorhist.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PA7","construct-vendorhist-1") 

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
# END FUNCTION PA7_rpt_query()
############################################################


############################################################
# FUNCTION PA7_rpt_process(p_where_text))
#
#
############################################################
FUNCTION PA7_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_vendorhist RECORD 
				vend_code LIKE vendorhist.vend_code, 
				name_text LIKE vendor.name_text, 
				year_num LIKE vendorhist.year_num, 
				period_num LIKE vendorhist.period_num, 
				currency_code LIKE vendor.currency_code, 
				purchase_num LIKE vendorhist.purchase_num, 
				purchase_amt LIKE vendorhist.purchase_amt, 
				payment_num LIKE vendorhist.payment_num, 
				payment_amt LIKE vendorhist.payment_amt, 
				debit_num LIKE vendorhist.debit_num, 
				debit_amt LIKE vendorhist.debit_amt, 
				disc_amt LIKE vendorhist.disc_amt 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET l_query_text = "SELECT vendorhist.vend_code, ", 
	" vendor.name_text, ", 
	" vendorhist.year_num, ", 
	" vendorhist.period_num, ", 
	" vendor.currency_code, ", 
	" vendorhist.purchase_num, ", 
	" vendorhist.purchase_amt, ", 
	" vendorhist.payment_num, ", 
	" vendorhist.payment_amt, ", 
	" vendorhist.debit_num, ", 
	" vendorhist.debit_amt, ", 
	" vendorhist.disc_amt ", 
	" FROM vendorhist, vendor WHERE ", 
	" vendorhist.cmpy_code = \"", 
	glob_rec_kandoouser.cmpy_code, 
	"\" AND ", 
	"vendor.cmpy_code = vendorhist.cmpy_code ", 
	" AND vendor.vend_code = vendorhist.vend_code AND ", 
	p_where_text clipped, 
	"ORDER BY vendorhist.vend_code, ", 
	" vendorhist.year_num, ", 
	" vendorhist.period_num" 
	PREPARE choice 
	FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_vendorhist.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PA7_rpt_list(l_rpt_idx,
		l_rec_vendorhist.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendorhist.vend_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PA7_rpt_list
	CALL rpt_finish("PA7_rpt_list")
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
# END FUNCTION PA7_rpt_query()
############################################################


############################################################
# REPORT PA7_rpt_list(p_rpt_idx,p_vendorhist)
#
#
############################################################
REPORT PA7_rpt_list(p_rpt_idx,p_vendorhist)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_vendorhist RECORD 
		vend_code LIKE vendorhist.vend_code, 
		name_text LIKE vendor.name_text, 
		year_num LIKE vendorhist.year_num, 
		period_num LIKE vendorhist.period_num, 
		currency_code LIKE vendor.currency_code, 
		purchase_num LIKE vendorhist.purchase_num, 
		purchase_amt LIKE vendorhist.purchase_amt, 
		payment_num LIKE vendorhist.payment_num, 
		payment_amt LIKE vendorhist.payment_amt, 
		debit_num LIKE vendorhist.debit_num, 
		debit_amt LIKE vendorhist.debit_amt, 
		disc_amt LIKE vendorhist.disc_amt 
	END RECORD 
	DEFINE l_line1 CHAR(80)
	DEFINE l_line2 CHAR(80) 
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 5, 
			"Year", COLUMN 10, 
			"Period", COLUMN 25, 
			"Purchases", COLUMN 41, 
			"Payments", COLUMN 57, 
			"Debits" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 10, 
			p_vendorhist.period_num USING "###", COLUMN 17, 
			p_vendorhist.purchase_amt USING "-,---,---,---.&&", COLUMN 34, 
			p_vendorhist.payment_amt USING "-,---,---,---.&&", COLUMN 51, ( 
			p_vendorhist.debit_amt ) USING "-,---,---,---.&&" 


		BEFORE GROUP OF p_vendorhist.vend_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, 
			"Vendor ID :", 
			p_vendorhist.vend_code, COLUMN 25, 
			p_vendorhist.name_text, 
			p_vendorhist.currency_code 

		BEFORE GROUP OF p_vendorhist.year_num 
			SKIP 1 line 
			PRINT COLUMN 5, 
			p_vendorhist.year_num USING "####" 

		AFTER GROUP OF p_vendorhist.vend_code 
			PRINT COLUMN 1, 
			"Vendor Total:", COLUMN 17, 
			GROUP sum(p_vendorhist.purchase_amt) USING "-,---,---,---.&&", COLUMN 34, 
			GROUP sum(p_vendorhist.payment_amt) USING "-,---,---,---.&&", 
			COLUMN 51, 
			GROUP sum(p_vendorhist.debit_amt) USING "-,---,---,---.&&" 

		AFTER GROUP OF p_vendorhist.year_num 
			PRINT COLUMN 17, 
			"================", COLUMN 34, 
			"================", COLUMN 51, 
			"================" 
			PRINT COLUMN 1, 
			"Year TO Date:", COLUMN 17, 
			GROUP sum(p_vendorhist.purchase_amt) USING "-,---,---,---.&&", COLUMN 34, 
			GROUP sum(p_vendorhist.payment_amt) USING "-,---,---,---.&&", 
			COLUMN 51, 
			GROUP sum(p_vendorhist.debit_amt) USING "-,---,---,---.&&"

		ON LAST ROW 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
						 
END REPORT 
############################################################
# END REPORT PA7_rpt_list(p_rpt_idx,p_vendorhist)
#
#
############################################################