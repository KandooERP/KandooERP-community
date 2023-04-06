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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AA8_GLOBALS.4gl"
############################################################
# MODU Scope Variables
############################################################ 

#####################################################################
# FUNCTION AA8_main()
#
# Customer shipping address Listing
#####################################################################
FUNCTION AA8_main() 

	CALL setModuleId("AA8") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A206 with FORM "A206" 
			CALL windecoration_a("A206") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Shipping Address Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AA8","menu-shipping-address-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AA8_rpt_process(AA8_rpt_query())
							
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AA8_rpt_process(AA8_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 
					#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 

			CLOSE WINDOW A206
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AA8_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A206 with FORM "A206" 
			CALL windecoration_a("A206") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AA8_rpt_query()) #save where clause in env 
			CLOSE WINDOW A206 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AA8_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION
#####################################################################
# END FUNCTION AA8_main()
#####################################################################


#####################################################################
# FUNCTION AA8_rpt_query()
#
#
#####################################################################
FUNCTION AA8_rpt_query() 
	DEFINE l_where1_text STRING
	DEFINE l_where2_text STRING 

	LET l_where1_text = NULL 
	MESSAGE kandoomsg2("A",1078,"") 

	CONSTRUCT BY NAME l_where1_text ON customership.cust_code, 
	customership.ship_code, 
	customership.name_text, 
	customership.addr_text, 
	customership.addr2_text, 
	customership.city_text, 
	customership.state_code, 
	customership.post_code, 
	customership.country_code, --@db-patch_2020_10_04--
	customership.contact_text, 
	customership.tele_text, 
	customership.mobile_phone,
	customership.email,		
	customership.ware_code, 
	customership.carrier_code, 
	customership.ship1_text, 
	customership.ship2_text 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AA8","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REPORTING CODE" --ON KEY (F8) 
			LET l_where2_text = report_criteria(glob_rec_kandoouser.cmpy_code,"AR") 
			IF l_where2_text IS NULL OR l_where2_text = "1=1" THEN 
				CONTINUE CONSTRUCT 
			ELSE 
				EXIT CONSTRUCT 
			END IF 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET	l_where1_text = NULL
	ELSE
		IF l_where2_text IS NOT NULL THEN
			LET	l_where1_text = " ", l_where1_text CLIPPED, " AND ", l_where2_text CLIPPED, " "
		END IF	
	END IF 

	RETURN l_where1_text
END FUNCTION
#####################################################################
# END FUNCTION AA8_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AA8_rptprocess()
#
#
#####################################################################
FUNCTION AA8_rpt_process(p_where1_text) 
	DEFINE p_where1_text STRING
	DEFINE p_where2_text STRING
	DEFINE l_where_text STRING #p_where1_text+p_where2_text 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text CHAR(800)
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customership RECORD LIKE customership.* 

	#------------------------------------------------------------
	IF (p_where1_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_where_text = " ", p_where1_text CLIPPED, " ", p_where2_text CLIPPED, " "
	LET l_rpt_idx = rpt_start(getmoduleid(),"AA8_rpt_list",l_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	 
	LET l_query_text = "SELECT * FROM customer,", 
	"customership ", 
	"WHERE customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customership.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code=customership.cust_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AA8_rpt_list")].sel_text clipped," ", 
	"ORDER BY" 
	
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," customer.cust_code,", 
		"customership.ship_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," customer.name_text,", 
		"customer.cust_code,", 
		"customership.ship_code" 
	END IF
	 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.*,	l_rec_customership.* 

		OUTPUT TO REPORT AA8_rpt_list(l_rpt_idx,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
				
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AA8_rpt_list
	CALL rpt_finish("AA8_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AA8_rptprocess()
#####################################################################


#####################################################################
# REPORT AA8_rpt_list(p_rec_customer,p_rec_customership)
#
#
#####################################################################
REPORT AA8_rpt_list(p_rpt_idx,p_rec_customer,p_rec_customership) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_customership RECORD LIKE customership.*
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_customership.cust_code 
			SKIP 1 line 
			PRINT COLUMN 01,"Customer: ",p_rec_customership.cust_code, 
			COLUMN 21, p_rec_customership.name_text 

		ON EVERY ROW 
			PRINT COLUMN 03, p_rec_customership.ship_code, 
			COLUMN 12, p_rec_customership.name_text, 
			COLUMN 42, p_rec_customership.addr_text, 
			COLUMN 72, p_rec_customership.addr2_text, 
			COLUMN 102,p_rec_customership.city_text[1,20], 
			COLUMN 122,p_rec_customership.state_code[1,5], 
			COLUMN 128,p_rec_customership.post_code[1,5] 

		ON LAST ROW 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			 
END REPORT
#####################################################################
# END REPORT AA8_rpt_list(p_rec_customer,p_rec_customership)
#####################################################################