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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASA_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
#DEFINE modu_where_part CHAR(1200) 
#DEFINE modu_query_text CHAR(2000) 
--DEFINE modu_answer CHAR(1) 
--DEFINE modu_ans CHAR(1) 
--DEFINE modu_id_flag SMALLINT 
--DEFINE modu_cnt SMALLINT 
--DEFINE modu_idx SMALLINT 
--DEFINE modu_err_flag SMALLINT 
--DEFINE modu_mrow SMALLINT 
--DEFINE modu_chosen SMALLINT 
##############################################################################
# FUNCTION ASA_main()
#
# ASA Allows the user TO PRINT mailing labels FOR Customers
##############################################################################
FUNCTION ASA_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("ASA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Mailing Labels" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ASA","menu-mailing-labels") 
					CALL ASA_rpt_process(ASA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
							
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL ASA_rpt_process(ASA_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW A105 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ASA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ASA_rpt_query()) #save where clause in env 
			CLOSE WINDOW A105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ASA_rpt_process(get_url_sel_text())
	END CASE 	
	
END FUNCTION


##############################################################################
# FUNCTION ASA_rpt_query()
#
#
##############################################################################
FUNCTION ASA_rpt_query() 
	DEFINE l_where_text STRING 
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, --@db-patch_2020_10_04--
	customer.currency_code, 
	customer.corp_cust_code, 
	customer.inv_addr_flag, 
	customer.sales_anly_flag, 
	customer.credit_chk_flag, 
	customer.type_code, 
	customer.sale_code, 
	customer.term_code, 
	customer.tax_code, 
	customer.bank_acct_code, 
	customer.setup_date, 
	customer.contact_text, 
	customer.tax_num_text, 
	customer.int_chge_flag, 
	customer.registration_num, 
	customer.vat_code, 
	customer.tele_text, 
	customer.mobile_phone, 
	customer.fax_text ,
	customer.email
	
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ASA","construct-customer") 

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


##############################################################################
# FUNCTION ASA_rpt_process()
#
#
##############################################################################
FUNCTION ASA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_customer RECORD LIKE customer.*

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ASA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT * ", 
	"FROM customer ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASA_rpt_list")].sel_text clipped, 
	" ORDER BY cust_code " 
	PREPARE statement_1 FROM l_query_text 
	DECLARE contact CURSOR FOR statement_1

	OPEN contact 

	FOREACH contact INTO l_rec_customer.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASA_rpt_list(l_rpt_idx,	l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ASA_rpt_list
	CALL rpt_finish("ASA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


##############################################################################
# REPORT ASA_rpt_list(p_rpt_idx,p_rec_customer)
# make_label
#
##############################################################################
REPORT ASA_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_customer RECORD LIKE customer.* 

	OUTPUT 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 6 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

		ON EVERY ROW 
			SKIP TO top OF PAGE 
			IF p_rec_customer.addr2_text IS NOT NULL THEN 
				IF p_rec_customer.city_text IS NOT NULL THEN 
					PRINT p_rec_customer.contact_text 
					PRINT p_rec_customer.name_text 
					PRINT p_rec_customer.addr1_text 
					PRINT p_rec_customer.addr2_text 
					PRINT p_rec_customer.city_text clipped, ", ", p_rec_customer.state_code clipped, 
					" ", p_rec_customer.post_code clipped 
				ELSE 
					PRINT p_rec_customer.contact_text 
					PRINT p_rec_customer.name_text 
					PRINT p_rec_customer.addr1_text 
					PRINT p_rec_customer.addr2_text 
					PRINT p_rec_customer.state_code clipped, 
					" ", p_rec_customer.post_code clipped 
				END IF 
			ELSE 
				IF p_rec_customer.city_text IS NOT NULL THEN 
					PRINT p_rec_customer.contact_text 
					PRINT p_rec_customer.name_text 
					PRINT p_rec_customer.addr1_text 
					PRINT p_rec_customer.city_text clipped, ", ", p_rec_customer.state_code clipped, 
					" ", p_rec_customer.post_code clipped 
				ELSE 
					PRINT p_rec_customer.contact_text 
					PRINT p_rec_customer.name_text 
					PRINT p_rec_customer.addr1_text 
					PRINT p_rec_customer.state_code clipped, 
					" ", p_rec_customer.post_code clipped 
				END IF 
			END IF 
END REPORT 


