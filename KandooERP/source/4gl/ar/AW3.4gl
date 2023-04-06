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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AW_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AW3_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_where_text STRING 
DEFINE modu_query_text STRING 
######################################################################################
# FUNCTION AW3_main()
#
#   - Program AW3  - Allows the user TO generate a list of customers
#                    FOR balance write offs
######################################################################################
FUNCTION AW3_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AW3") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A660 with FORM "A660" 
			CALL windecoration_a("A660") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Customer Balance Write Off" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AW3","menu-customer-balance") 
					CALL AW3_rpt_process(AW3_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " Enter Report Selection Criteria" 
					CALL AW3_rpt_process(AW3_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print Service Fee Report using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " EXIT PROGRAM"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A660

	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AW3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A660 with FORM "A660" 
			CALL windecoration_a("A660") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AW3_rpt_query()) #save where clause in env 
			CLOSE WINDOW A660 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AW3_rpt_process(get_url_sel_text())
	END CASE 			 
END FUNCTION 


######################################################################################
# FUNCTION AW3_rpt_query()
#
#
######################################################################################
FUNCTION AW3_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter Selection criteria - ESC TO continue
	CONSTRUCT BY NAME l_where_text ON tentarbal.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	tentarbal.credit_amt, 
	tentarbal.debit_amt 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AW3","construct-writeoff") 

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
		RETURN l_where_text
	END IF 
 
END FUNCTION 



######################################################################################
# FUNCTION AW3_rpt_process()
#
#
######################################################################################
FUNCTION AW3_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE p_rec_tentarbal RECORD LIKE tentarbal.* 
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_rec_customer RECORD LIKE customer.*

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AW3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AW3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AW3_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM tentarbal,customer ", 
	"WHERE tentarbal.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND tentarbal.cust_code = customer.cust_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AW3_rpt_list")].sel_text clipped
	 
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		" customer.cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		" name_text,customer.cust_code" 
	END IF 
	
	PREPARE s_tentarbal FROM l_query_text 
	DECLARE c_tentarbal CURSOR with HOLD FOR s_tentarbal 

	

	FOREACH c_tentarbal INTO p_rec_tentarbal.*,l_rec_customer.* 
		#DISPLAY p_rec_tentarbal.cust_code," ",l_rec_customer.name_text at 2,2	attribute(yellow) 

		#---------------------------------------------------------
		OUTPUT TO REPORT AW3_rpt_list(l_rpt_idx,p_rec_tentarbal.*,l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH

	#------------------------------------------------------------
	FINISH REPORT AW3_rpt_list
	CALL rpt_finish("AW3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


######################################################################################
# REPORT AW3_rpt_list(p_rec_tentarbal,p_rec_customer)
# writeoff_summary
#
######################################################################################
REPORT AW3_rpt_list(p_rpt_idx,p_rec_tentarbal,p_rec_customer)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_tentarbal RECORD LIKE tentarbal.* 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 


	OUTPUT 
--	PAGE length 66 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 8,"Customer", 
			COLUMN 18,"Name", 
			COLUMN 68, "----- Write Off -----", 
			COLUMN 96,"Customer", 
			COLUMN 107,"Days Since" 
			PRINT COLUMN 68 ,"Credit", 
			COLUMN 84,"Debit", 
			COLUMN 96,"Balance", 
			COLUMN 108,"Activity" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_customer.currency_code 
			SELECT desc_text INTO l_rec_currency.desc_text FROM currency 
			WHERE currency_code = p_rec_customer.currency_code 
			PRINT COLUMN 1,"Currency:", 
			COLUMN 11,p_rec_customer.currency_code, 
			COLUMN 15,l_rec_currency.desc_text 
		ON EVERY ROW 
			PRINT COLUMN 8,p_rec_tentarbal.cust_code, 
			COLUMN 18,p_rec_customer.name_text, 
			COLUMN 61,p_rec_tentarbal.credit_amt USING "--,---,--&.&&", 
			COLUMN 76,p_rec_tentarbal.debit_amt USING "--,---,--&.&&", 
			COLUMN 91,p_rec_customer.bal_amt USING "--,---,--&.&&", 
			COLUMN 110,p_rec_tentarbal.days_old USING "--,---&" 
		AFTER GROUP OF p_rec_customer.currency_code 
			NEED 3 LINES 
			SKIP 1 line 
			PRINT COLUMN 60,"==============", 
			COLUMN 75,"==============" 
			PRINT COLUMN 1,"Currrency Total: ",p_rec_customer.currency_code, 
			COLUMN 60,group sum(p_rec_tentarbal.credit_amt) 
			USING "---,---,--&.&&", 
			COLUMN 75,group sum(p_rec_tentarbal.debit_amt) USING "---,---,--&.&&" 
			SKIP 1 line 
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 



