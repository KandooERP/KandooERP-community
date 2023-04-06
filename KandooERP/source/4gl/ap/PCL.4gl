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
# FUNCTION PCL_main()
# RETURN VOID
#
# PCL - Cleansing Report Driver
############################################################
FUNCTION PCL_main()

	CALL setModuleId("PCL") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW WMENU with FORM "UmenuWindow" 
			CALL winDecoration_u("UmenuWindow") -- albo kd-752 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Cleansing Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCL","menu-cleansing_rep-1") 
					CALL PCL_rpt_process(PCL_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL PCL_rpt_process(PCL_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW WMENU

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCL_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW WMENU with FORM "UmenuWindow" 
			CALL winDecoration_u("UmenuWindow") -- albo kd-752 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCL_rpt_query()
			CALL set_url_sel_text(PCL_rpt_query()) #save where clause in env 
			CLOSE WINDOW WMENU

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCL_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCL_main()
############################################################


############################################################
# FUNCTION PCL_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCL_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	LET l_ret_sql_sel_text = "1=1"

	RETURN l_ret_sql_sel_text
END FUNCTION 
############################################################
# END FUNCTION PCL_rpt_query() 
############################################################

############################################################
# FUNCTION PCL_rpt_process()
# RETURN rpt_finish("PC9z_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCL_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_bic_code LIKE bic.bic_code 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_flag SMALLINT 
	-- DEFINE l_rpt_output CHAR(60) 
	-- DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PC9z_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC9z_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC9z_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT * ",
	"FROM vendor ",
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ",
	"AND bkdetls_mod_flag = 'Y' ", 
	"AND ", p_where_text clipped, " ", 
	"ORDER BY vendor.bank_acct_code, vendor.vend_code "

	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 

	BEGIN WORK 

		LET l_flag = false 
		FOREACH c_vendor INTO l_rec_vendor.* 

			LET l_bic_code = l_rec_vendor.bank_acct_code[1,6] 
			LET l_rec_cheque.vend_code = l_rec_vendor.vend_code 
			LET l_rec_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 

			#------------------------------------------------------------
			OUTPUT TO REPORT PC9z_rpt_list(rpt_rmsreps_idx_get_idx("PC9z_rpt_list"), l_bic_code,l_rec_cheque.*) 

			IF upd_vend(l_rec_vendor.vend_code) = false THEN 
				LET l_flag = true 
				EXIT FOREACH 
			END IF 

			IF NOT rpt_int_flag_handler2("Vendor: ",l_rec_vendor.name_text, l_rec_vendor.vend_code ,rpt_rmsreps_idx_get_idx("PC9z_rpt_list")) THEN
				EXIT FOREACH 
			END IF 
			#------------------------------------------------------------

		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT PC9z_rpt_list

		IF l_flag = true THEN 
			ROLLBACK WORK 
		ELSE 
			COMMIT WORK 
		END IF 

		RETURN rpt_finish("PC9z_rpt_list")
		#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCL_rpt_process()
############################################################

############################################################
# FUNCTION upd_vend(p_vend)
#
#
############################################################
FUNCTION upd_vend(p_vend) 
	DEFINE p_vend LIKE vendor.vend_code 
	DEFINE l_err_message CHAR(40)

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET l_err_message = "PCL - Updating Vendor" 

	UPDATE vendor SET bkdetls_mod_flag = "C" 
	WHERE vend_code = p_vend 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	WHENEVER ERROR stop 
	RETURN true 

END FUNCTION 
############################################################
# END FUNCTION upd_vend(p_vend) 
############################################################

