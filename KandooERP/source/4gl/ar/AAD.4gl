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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAD_GLOBALS.4gl" 

###########################################################################
# FUNCTION AAD_main()
#
# Purpose - Customer Ledger Report
###########################################################################
FUNCTION AAD_main()

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A187 with FORM "A187" 
			CALL windecoration_a("A187") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Customer Ledger Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAD","menu-customer-ledger-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAD_rpt_process(AAD_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AAD_rpt_process(AAD_rpt_query())
							
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A187 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAD_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A187 with FORM "A187" 
			CALL windecoration_a("A187") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAD_rpt_query()) #save where clause in env 
			CLOSE WINDOW A187 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAD_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
###########################################################################
# END FUNCTION AAD_main()
###########################################################################


#####################################################################
# FUNCTION AAD_rpt_query()
#
#
#####################################################################
FUNCTION AAD_rpt_query() 
	DEFINE r_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT BY NAME r_where_text ON
	araudit.tran_date, 
	araudit.cust_code, 
	araudit.seq_num, 
	araudit.tran_type_ind, 
	araudit.source_num, 
	araudit.tran_text, 
	araudit.currency_code, 
	araudit.tran_amt, 
	araudit.year_num, 
	araudit.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAD","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN r_where_text
	END IF	
END FUNCTION
#####################################################################
# END FUNCTION AAD_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAD_rpt_process()
#
#
#####################################################################
FUNCTION AAD_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_araudit RECORD LIKE araudit.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAD_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT AAD_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
		
	LET l_query_text = 
	"SELECT * FROM araudit ", 
	"WHERE araudit.cmpy_code='",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND ",p_where_text CLIPPED," ", 
	"ORDER BY araudit.cust_code,araudit.seq_num" 

	PREPARE s_araudit FROM l_query_text 
	DECLARE c_araudit CURSOR FOR s_araudit 

	FOREACH c_araudit INTO l_rec_araudit.* 
		IF l_rec_araudit.conv_qty IS NULL OR l_rec_araudit.conv_qty = 0 THEN 
			LET l_rec_araudit.conv_qty = 1 
		END IF 
		#------------------------------------------------------------
		OUTPUT TO REPORT AAD_rpt_list(l_rpt_idx,l_rec_araudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_araudit.cust_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AAD_rpt_list
	RETURN rpt_finish("AAD_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
#####################################################################
# END FUNCTION AAD_rpt_process()
#####################################################################


#####################################################################
# REPORT AAD_list(p_rpt_idx,p_rec_araudit) 
#
#
#####################################################################
REPORT AAD_rpt_list(p_rpt_idx,p_rec_araudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_customer RECORD LIKE customer.*

	ORDER EXTERNAL BY p_rec_araudit.cust_code,p_rec_araudit.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 

	BEFORE GROUP OF p_rec_araudit.cust_code 
		SKIP TO TOP OF PAGE 
		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customer.cust_code = p_rec_araudit.cust_code 
		IF l_rec_customer.cust_code IS NULL THEN			
				LET l_rec_customer.name_text = "**********" 
		END IF 
		PRINT COLUMN 01, p_rec_araudit.cust_code CLIPPED," ",l_rec_customer.name_text CLIPPED,"  ",l_rec_customer.city_text CLIPPED 
		SKIP 1 LINE 

	ON EVERY ROW 
		PRINT 
		COLUMN 07, p_rec_araudit.seq_num    USING "<<<<<<", 
		COLUMN 14, p_rec_araudit.tran_date  USING "dd/mm/yy", 
		COLUMN 24, p_rec_araudit.tran_type_ind CLIPPED, 
		COLUMN 27, p_rec_araudit.source_num USING "########", 
		COLUMN 36, p_rec_araudit.tran_text CLIPPED, 
		COLUMN 52, p_rec_araudit.tran_amt   USING "---,---,--&.&&", 
		COLUMN 67, p_rec_araudit.bal_amt    USING "---,---,--&.&&" 

	AFTER GROUP OF p_rec_araudit.cust_code 
		SKIP 1 LINE 
		PRINT COLUMN 52, "============ ",l_rec_customer.currency_code," ", 
		"============" 
		PRINT COLUMN 32, "Items: ",GROUP COUNT(*) USING "<<<<<<", 
		COLUMN 51, GROUP SUM(p_rec_araudit.tran_amt) USING "----,---,--&.&&"

	ON LAST ROW 
		SKIP 1 LINE 
		PRINT COLUMN 32, "Total Items: ",COUNT(*) USING "<<<<<<", 
		COLUMN 52, "============ ",glob_rec_arparms.currency_code," ", 
		"============" 
		PRINT COLUMN 51, SUM(p_rec_araudit.tran_amt/p_rec_araudit.conv_qty) USING "----,---,--&.&&" 
		SKIP 1 LINE
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT
#####################################################################
# END REPORT AAD_list(p_rpt_idx,p_rec_araudit) 
#####################################################################