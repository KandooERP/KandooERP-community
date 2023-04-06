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
GLOBALS "../ar/ASA_C_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_where_part CHAR(700) 
--DEFINE modu_where_part2 CHAR(700) 
--DEFINE modu_query_text CHAR(700) 
--DEFINE modu_report_path CHAR(100) 
DEFINE modu_runtext CHAR(100) 
DEFINE modu_retcode INTEGER 
--DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
##############################################################################
# FUNCTION ASA_C_main()
#
# \brief module ASA Allows the user TO PRINT mailing labels FOR Customers
# AND optionally exclude customers based on existing subscriptions
##############################################################################
FUNCTION ASA_C_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler  
	
	CALL setModuleId("ASA_C")

	#Not sure where this report path is coming from ???? 
	#LET modu_report_path = "data/export/information/groups/business/vw" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode  

			OPEN WINDOW A651 with FORM "A651" 
			CALL windecoration_a("A651") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Mailing Labels" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ASA_C","menu-mailing-labels") 
					CALL ASA_C_rpt_process(ASA_C_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run Report" " SELECT criteria & PRINT REPORT" 
					CALL ASA_C_rpt_process(ASA_C_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				COMMAND KEY(interrupt,"E")"Exit" " Exit TO menu" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A651 
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ASA_C_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A651 with FORM "A651" 
			CALL windecoration_a("A651") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ASA_C_rpt_query()) #save where clause in env 
			CLOSE WINDOW A651 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ASA_C_rpt_process(get_url_sel_text())
	END CASE			
END FUNCTION

##############################################################################
# FUNCTION ASA_C_rpt_query()
#
#
##############################################################################
FUNCTION ASA_C_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where_text2 STRING
	
	#NOTE: I removed the custom-report path, as it does not fit into our cloud-framework
	#report can still be downloaded to the local client as usual... 

	{
	INPUT modu_report_path 	WITHOUT DEFAULTS FROM modu_report_path 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASA","inp-modu_report_path") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD report_path 
			IF modu_report_path IS NULL THEN 
				ERROR kandoomsg2("A",9175,"") 
				#9175 Valid Report path must be entered"
				NEXT FIELD report_path 
			END IF 
			#changed by huho 06.08.2018
			IF NOT os.path.exists(trim(modu_report_path)) THEN 
				ERROR kandoomsg2("A",9175,"") 
				#9175 Valid Report path must be entered"
				NEXT FIELD report_path 
			END IF 

			#LET modu_runtext = "[ -d ",modu_report_path clipped," ]"
			#run modu_runtext returning modu_retcode
			#IF modu_retcode <> 0 THEN
			#   LET l_msgresp = kandoomsg("A",9175,"")
			#   #9175 Valid Report path must be entered"
			#   NEXT FIELD report_path
			#END IF


	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
}
	MESSAGE kandoomsg2("A",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code, --@db-patch_2020_10_04--
	customer.type_code, 
	customer.sale_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ASA_C","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF
	 
	CONSTRUCT BY NAME l_where_text2 ON customersub.part_code,customersub.year_num 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE

	LET glob_rec_rpt_selector.sel_text = l_where_text
	LET glob_rec_rpt_selector.sel_option1 = l_where_text2
		
		RETURN l_where_text
	END IF
END FUNCTION


##############################################################################
# FUNCTION ASA_C_rpt_process(p_where_text)
#
#
##############################################################################
FUNCTION ASA_C_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  	
	DEFINE l_where_text2 STRING
	DEFINE l_rec_customer RECORD LIKE customer.*
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ASA_C_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASA_C_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASA_C_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_where_text2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASA_C_rpt_list")].sel_option1 
	
	IF l_where_text2.trim() = "1=1" THEN 
		LET l_query_text = "SELECT customer.* ", 
		" FROM customer ", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND ",p_where_text
		 clipped 
	ELSE 
		LET l_query_text = "SELECT customer.* ", 
		" FROM customer ", 
		" WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND customer.cust_code NOT in ", 
		" (SELECT cust_code FROM customersub ", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND ",l_where_text2 clipped,") ", 
		" AND ",p_where_text clipped 
	END IF 

	PREPARE statement_1 FROM l_query_text 
	DECLARE c_customer CURSOR FOR statement_1 

	FOREACH c_customer INTO l_rec_customer.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASA_C_rpt_list(l_rpt_idx,l_rec_customer.*)
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT ASA_C_rpt_list
		CALL rpt_finish("ASA_C_rpt_list")
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
# REPORT ASA_C_rpt_list(l_rec_customer)
#
#
##############################################################################
REPORT ASA_C_rpt_list(p_rpt_idx,l_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_customer RECORD LIKE customer.* 

	OUTPUT 
--	top margin 0 
--	bottom margin 0 
--	left margin 0 
--	PAGE length 1 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		ON EVERY ROW 
			PRINT "The Principal","|", 
			l_rec_customer.cust_code clipped,"|", 
			l_rec_customer.name_text clipped,"|", 
			l_rec_customer.addr1_text clipped,"|", 
			l_rec_customer.addr2_text clipped,"|", 
			l_rec_customer.city_text clipped,"|", 
			l_rec_customer.state_code clipped,"|", 
			l_rec_customer.post_code clipped,"|", 
			l_rec_customer.country_code clipped ,"|" --@db-patch_2020_10_04 report--
END REPORT 