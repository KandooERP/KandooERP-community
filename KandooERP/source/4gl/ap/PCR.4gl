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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION PCR_main()
# RETURN VOID
#
# PCR - Remittance Advice Interface Program
############################################################
FUNCTION PCR_main()

	CALL setModuleId("PCR") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
		
			OPEN WINDOW P238 with FORM "P238" 
			CALL winDecoration_p("P238") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Remittance Advice" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCR","menu-remittance_advice-1") 
					CALL PCR_rpt_process(PCR_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PCR_rpt_process(PCR_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P238

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCR_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P238 with FORM "P238" 
			CALL winDecoration_p("P238") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCR_rpt_query()
			CALL set_url_sel_text(PCR_rpt_query()) #save where clause in env 
			CLOSE WINDOW P238

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCR_rpt_process(get_url_sel_text())
	END CASE 
 
END FUNCTION 
############################################################
# END FUNCTION PCR_main()
############################################################


############################################################
# FUNCTION PCR_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCR_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") #1001 "Enter selection criteria - ESC TO Continue"

	CONSTRUCT BY NAME l_where_text ON bank_code, 
		cheq_date, 
		cheq_code, 
		pay_meth_ind, 
		eft_run_num, 
		vend_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCR","construct-bank-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL
	END IF 

	RETURN l_where_text
END FUNCTION 
############################################################
# END FUNCTION PCR_rpt_query() 
############################################################


############################################################
# FUNCTION PCR_rpt_process()
# RETURN rpt_finish("PCR_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCR_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_arg1 STRING
	DEFINE l_arg2 STRING
	DEFINE l_arg3 STRING
	
IF p_where_text IS NOT NULL THEN
	LET l_arg1 = "PROG_CHILD=", "PCR"  #????
	LET l_arg2 = "MODULE_CHILD=", "PCR" #????
	LET l_arg3 = "QUERY_WHERE_TEXT=", trim(p_where_text) #get_url_query_where_text()
	CALL run_prog("PX2",l_arg1,l_arg2,l_arg3,"")
	RETURN TRUE
ELSE 
	RETURN NULL 
END IF

END FUNCTION 
############################################################
# END FUNCTION PCR_rpt_process()
############################################################