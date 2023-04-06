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
# FUNCTION PCFk_main()
# RETURN VOID
#
# PCF - Remittance Advices Report
############################################################
FUNCTION PCFk_main() 
	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("PCFk") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
		
			OPEN WINDOW P504 with FORM "P504" 
			CALL windecoration_p("P504") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Remittance Advices" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCF","menu-remittance_advice-1") 
					CALL PCFk_rpt_process(PCFk_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PCFk_rpt_process(PCFk_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P504

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCFk_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P504 with FORM "P504" 
			CALL windecoration_p("P504") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCFk_rpt_query()
			CALL set_url_sel_text(PCFk_rpt_query()) #save where clause in env 
			CLOSE WINDOW P504

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCFk_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCFk_main()
############################################################


############################################################
# FUNCTION PCFk_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCFk_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") #1001 "Enter selection criteria - ESC TO Continue"

	CONSTRUCT BY NAME l_ret_sql_sel_text ON cheque.bank_code, 
	cheque.cheq_code, 
	cheque.pay_meth_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCF","construct-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_sql_sel_text = NULL
	END IF 

	RETURN l_ret_sql_sel_text
END FUNCTION 
############################################################
# END FUNCTION PCFk_rpt_query() 
############################################################


############################################################
# FUNCTION PCFk_rpt_process()
# RETURN rpt_finish("PCF_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCFk_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_cheque RECORD LIKE cheque.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCFk_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCFk_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCFk_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM cheque ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY bank_code,", 
	"pay_meth_ind,", 
	"cheq_code" 

	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque 


	#------------------------------------------------------------

	FOREACH c_cheque INTO l_rec_cheque.* 
		OUTPUT TO REPORT PCFk_rpt_list(rpt_rmsreps_idx_get_idx("PCFk_rpt_list"), l_rec_cheque.*) 
		IF NOT rpt_int_flag_handler2("Cheque: ", l_rec_cheque.cheq_code, "" , rpt_rmsreps_idx_get_idx("PCFk_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
	END FOREACH 
	#------------------------------------------------------------
	FINISH REPORT PCFk_rpt_list
	RETURN rpt_finish("PCFk_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCFk_rpt_process()
############################################################
