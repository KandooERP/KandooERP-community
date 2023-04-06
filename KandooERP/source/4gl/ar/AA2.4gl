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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AA2_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"  
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE l_where1_text STRING
--DEFINE l_where2_text STRING 
DEFINE modu_temp_text VARCHAR(200)	
#####################################################################
# FUNCTION AA2_main()
#
# AA2 - Customer phone listing
#####################################################################
FUNCTION AA2_main() 
	CALL setModuleId("AA2") 	

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Customer Address Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AA2","menu-customer-address-rep")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AA2_rpt_process(AA2_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AA2_rpt_process(AA2_rpt_query()) 
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A112 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AA2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A112 with FORM "A112" 
			CALL windecoration_a("A112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AA2_rpt_query()) #save where clause in env 
			CLOSE WINDOW A112 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AA2_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
#####################################################################
# END FUNCTION AA2_main()
#####################################################################


#####################################################################
# FUNCTION AA2_rpt_query()
#
#
#####################################################################
FUNCTION AA2_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING

	LET l_where2_text = NULL 
	MESSAGE kandoomsg2("A",1078,"")
	 
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	currency_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	tele_text, 
	mobile_phone, 
	email,	
	comment_text, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	vat_code, 
	inv_level_ind, 
	cond_code, 
	avg_cred_day_num, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	cred_limit_amt, 
	onorder_amt, 
	last_inv_date, 
	last_pay_date, 
	setup_date, 
	delete_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AA2","construct-customer") 

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
		LET	l_where_text = NULL
	ELSE
		IF l_where2_text IS NOT NULL THEN
			LET	l_where_text = " ", l_where_text CLIPPED, " AND ", l_where2_text CLIPPED, " "
		END IF	
	END IF 

	RETURN l_where_text
END FUNCTION
#####################################################################
# END FUNCTION AA2_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AA2_rpt_query()
#
#
#####################################################################
FUNCTION AA2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AA2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AA2_rpt_list")].sel_text clipped," ", 
	"ORDER BY" 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," name_text,cust_code" 
	END IF 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		#------------------------------------------------------------
		OUTPUT TO REPORT AA2_rpt_list(l_rpt_idx,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AA2_rpt_list
	CALL rpt_finish("AA2_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 
#####################################################################
# END FUNCTION AA2_rpt_query()
#####################################################################


#####################################################################
# REPORT AA2_rpt_list(p_rec_customer)
#
#
#####################################################################
REPORT AA2_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		ON EVERY ROW 
			IF p_rec_customer.city_text IS NULL THEN 
				LET p_rec_customer.city_text = p_rec_customer.addr2_text 
			END IF 
			PRINT COLUMN 01, p_rec_customer.cust_code, 
			COLUMN 10, p_rec_customer.name_text[1,29], 
			COLUMN 40, p_rec_customer.city_text, 
			COLUMN 61, p_rec_customer.state_code[1,3], 
			COLUMN 65, p_rec_customer.tele_text[1,18], 
			COLUMN 84, p_rec_customer.fax_text[1,18], 
			COLUMN 103,p_rec_customer.mobile_phone[1,18], 
			COLUMN 122,p_rec_customer.vat_code 

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
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
					
END REPORT
#####################################################################
# END REPORT AA2_rpt_list(p_rec_customer)
#####################################################################