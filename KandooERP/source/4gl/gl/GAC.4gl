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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_budget_name_text CHAR(40) 
###############################################################
# FUNCTION GAC(p_Arg)
#
# AC  Account Budget Worksheet Report
###############################################################
FUNCTION GAC_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GAC")

	CREATE temp TABLE tempper 
	(tm_cmpy CHAR(2), 
	tm_acct CHAR(18), 
	tm_desc CHAR(40), 
	tm_year SMALLINT, 
	tm_per1 DECIMAL(15,0), 
	tm_per2 DECIMAL(15,0), 
	tm_per3 DECIMAL(15,0), 
	tm_per4 DECIMAL(15,0), 
	tm_per5 DECIMAL(15,0), 
	tm_per6 DECIMAL(15,0), 
	tm_per7 DECIMAL(15,0), 
	tm_per8 DECIMAL(15,0), 
	tm_per9 DECIMAL(15,0), 
	tm_per10 DECIMAL(15,0), 
	tm_per11 DECIMAL(15,0), 
	tm_per12 DECIMAL(15,0), 
	tm_per13 DECIMAL(15,0), 
	tm_tot DECIMAL(15,0)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Budget" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GAC","menu-budget") 
					CALL GAC_rpt_process(GAC_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL GAC_rpt_process(GAC_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G158 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GAC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G158 with FORM "G158" 
			CALL windecoration_g("G158") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GAC_rpt_query()) #save where clause in env 
			CLOSE WINDOW G158 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GAC_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


###############################################################
# FUNCTION GAC_rpt_query()
#
#
###############################################################
FUNCTION GAC_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING	
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.*  
	DEFINE l_rec_temp RECORD 
		tm_cmpy LIKE coa.cmpy_code, 
		tm_acct LIKE coa.acct_code, 
		tm_desc LIKE coa.desc_text, 
		tm_year LIKE accounthist.year_num, 
		tm_per1 DECIMAL(15,0), 
		tm_per2 DECIMAL(15,0), 
		tm_per3 DECIMAL(15,0), 
		tm_per4 DECIMAL(15,0), 
		tm_per5 DECIMAL(15,0), 
		tm_per6 DECIMAL(15,0), 
		tm_per7 DECIMAL(15,0), 
		tm_per8 DECIMAL(15,0), 
		tm_per9 DECIMAL(15,0), 
		tm_per10 DECIMAL(15,0), 
		tm_per11 DECIMAL(15,0), 
		tm_per12 DECIMAL(15,0), 
		tm_per13 DECIMAL(15,0), 
		tm_tot DECIMAL(15,0) 
	END RECORD 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 


	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT l_where_text ON coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	accounthist.year_num 
	FROM coa.desc_text, 
	coa.type_ind, 
	coa.group_code, 
	account.year_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GAC","construct-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE
		# add on the search dimension of segments.......
		LET l_where2_text = segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") 
		IF l_where2_text IS NOT NULL THEN
			LET l_where_text = l_where_text, " ", l_where2_text
		END IF
	END IF

	OPEN WINDOW G173 with FORM "G173" 
	CALL windecoration_g("G173") 

	INPUT
		glob_budg_num, 
		glob_z_supp, 
		glob_speriod, 
		glob_eperiod 
	FROM
		budg_num, 
		z_supp, 
		speriod, 
		eperiod ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GAC","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD budg_num 
			LET glob_ans = glob_budg_num 
			IF glob_ans NOT matches "[1-6]" 
			OR glob_ans IS NULL THEN 
				ERROR kandoomsg2("G",9008,"") 
				NEXT FIELD budg_num 
			END IF 

		AFTER FIELD z_supp 
			IF glob_z_supp <> "Y" THEN 
				LET glob_z_supp = "N" 
				DISPLAY glob_z_supp TO z_supp

			END IF 

		AFTER FIELD speriod 
			IF glob_speriod < 1 
			OR glob_speriod > 13 
			OR glob_speriod IS NULL THEN 
				ERROR kandoomsg2("G",9061,"") 
				NEXT FIELD speriod 
			END IF 

		AFTER FIELD eperiod 
			IF glob_eperiod < 1 
			OR glob_eperiod > 13 
			OR glob_eperiod IS NULL THEN 
				ERROR kandoomsg2("G",9061,"") 
				NEXT FIELD eperiod 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_ans IS NULL THEN 
					ERROR kandoomsg2("G",9008,"") 
					NEXT FIELD budg_num 
				END IF 

				IF glob_z_supp IS NULL THEN 
					LET glob_z_supp = "N" 
					DISPLAY glob_z_supp TO z_supp

				END IF 

				IF glob_speriod IS NULL THEN 
					ERROR kandoomsg2("G",9061,"") 
					NEXT FIELD speriod 
				END IF 

				IF glob_eperiod IS NULL THEN 
					ERROR kandoomsg2("G",9061,"") 
					NEXT FIELD eperiod 
				END IF 

			END IF 


	END INPUT 

	CLOSE WINDOW G173 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = glob_budg_num 
		LET glob_rec_rpt_selector.ref1_ind = glob_z_supp
		LET glob_rec_rpt_selector.ref2_num = glob_speriod
		LET glob_rec_rpt_selector.ref3_num = glob_eperiod
		RETURN l_where_text
	END IF 		
END FUNCTION


###############################################################
# FUNCTION GAC_rpt_process() 
#
#
###############################################################
FUNCTION GAC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_coa RECORD LIKE coa.*  
	DEFINE l_rec_temp RECORD 
		tm_cmpy LIKE coa.cmpy_code, 
		tm_acct LIKE coa.acct_code, 
		tm_desc LIKE coa.desc_text, 
		tm_year LIKE accounthist.year_num, 
		tm_per1 DECIMAL(15,0), 
		tm_per2 DECIMAL(15,0), 
		tm_per3 DECIMAL(15,0), 
		tm_per4 DECIMAL(15,0), 
		tm_per5 DECIMAL(15,0), 
		tm_per6 DECIMAL(15,0), 
		tm_per7 DECIMAL(15,0), 
		tm_per8 DECIMAL(15,0), 
		tm_per9 DECIMAL(15,0), 
		tm_per10 DECIMAL(15,0), 
		tm_per11 DECIMAL(15,0), 
		tm_per12 DECIMAL(15,0), 
		tm_per13 DECIMAL(15,0), 
		tm_tot DECIMAL(15,0) 
	END RECORD 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GAC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GAC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_budg_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].ref1_num
	LET glob_z_supp = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].ref1_ind
	LET glob_speriod = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].ref2_num
	LET glob_eperiod = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].ref3_num		 
 
	LET l_query_text = "SELECT * ", 
	"FROM accounthist , coa ", 
	"WHERE coa.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
	"AND accounthist.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
	"AND coa.acct_code = accounthist.acct_code ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GAC_rpt_list")].sel_text clipped, " ", 
	" ORDER BY accounthist.acct_code, ", 
	" accounthist.year_num, accounthist.period_num " 

	PREPARE s_accounthist FROM l_query_text 
	DECLARE c_accounthist CURSOR FOR s_accounthist 

	DELETE FROM tempper 

	FOR glob_idx = 1 TO 13 
		IF glob_idx < glob_speriod OR glob_idx > glob_eperiod THEN 
			LET glob_arr_per_num[glob_idx] = "N" 
		ELSE 
			LET glob_arr_per_num[glob_idx] = "Y" 
		END IF 
	END FOR 

	FOREACH c_accounthist INTO l_rec_accounthist.*,l_rec_coa.* 
		IF int_flag OR quit_flag THEN 
			ERROR kandoomsg2("U",9501,"") 			#9501 Printing was aborted.
			RETURN false 
		END IF 

		#DISPLAY "Formatting budget FOR ", l_rec_coa.acct_code TO lbInfo1  --at 1,5
		#MESSAGE "Formatting budget FOR ", l_rec_coa.acct_code 

		LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg1_text 

		# move over chosen budget
		CASE 
			WHEN (glob_budg_num = 2) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg2_amt 
				LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg2_text 
			WHEN (glob_budg_num = 3) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg3_amt 
				LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg3_text 
			WHEN (glob_budg_num = 4) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg4_amt 
				LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg4_text 
			WHEN (glob_budg_num = 5) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg5_amt 
				LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg5_text 
			WHEN (glob_budg_num = 6) 
				LET l_rec_accounthist.budg1_amt = l_rec_accounthist.budg6_amt 
				LET modu_budget_name_text = glob_budg_num, " ", glob_rec_glparms.budg6_text 
		END CASE 

		SELECT * 
		INTO l_rec_temp.* 
		FROM tempper 
		WHERE tm_cmpy = l_rec_accounthist.cmpy_code 
		AND tm_acct = l_rec_accounthist.acct_code 
		AND tm_year = l_rec_accounthist.year_num 

		IF status = NOTFOUND THEN 
			LET l_rec_temp.tm_cmpy = glob_rec_kandoouser.cmpy_code 
			LET l_rec_temp.tm_acct = l_rec_accounthist.acct_code 
			LET l_rec_temp.tm_desc = l_rec_coa.desc_text 
			LET l_rec_temp.tm_year = l_rec_accounthist.year_num 

			CASE (l_rec_accounthist.period_num) 
				WHEN 1 LET l_rec_temp.tm_per1 = l_rec_accounthist.budg1_amt 
				WHEN 2 LET l_rec_temp.tm_per2 = l_rec_accounthist.budg1_amt 
				WHEN 3 LET l_rec_temp.tm_per3 = l_rec_accounthist.budg1_amt 
				WHEN 4 LET l_rec_temp.tm_per4 = l_rec_accounthist.budg1_amt 
				WHEN 5 LET l_rec_temp.tm_per5 = l_rec_accounthist.budg1_amt 
				WHEN 6 LET l_rec_temp.tm_per6 = l_rec_accounthist.budg1_amt 
				WHEN 7 LET l_rec_temp.tm_per7 = l_rec_accounthist.budg1_amt 
				WHEN 8 LET l_rec_temp.tm_per8 = l_rec_accounthist.budg1_amt 
				WHEN 9 LET l_rec_temp.tm_per9 = l_rec_accounthist.budg1_amt 
				WHEN 10 LET l_rec_temp.tm_per10 = l_rec_accounthist.budg1_amt 
				WHEN 11 LET l_rec_temp.tm_per11 = l_rec_accounthist.budg1_amt 
				WHEN 12 LET l_rec_temp.tm_per12 = l_rec_accounthist.budg1_amt 
				WHEN 13 LET l_rec_temp.tm_per13 = l_rec_accounthist.budg1_amt 
			END CASE 

			IF l_rec_temp.tm_per1 IS NULL THEN LET l_rec_temp.tm_per1 = 0 END IF 
			IF l_rec_temp.tm_per2 IS NULL THEN LET l_rec_temp.tm_per2 = 0 END IF 
			IF l_rec_temp.tm_per3 IS NULL THEN LET l_rec_temp.tm_per3 = 0 END IF 
			IF l_rec_temp.tm_per4 IS NULL THEN LET l_rec_temp.tm_per4 = 0 END IF 
			IF l_rec_temp.tm_per5 IS NULL THEN LET l_rec_temp.tm_per5 = 0 END IF 
			IF l_rec_temp.tm_per6 IS NULL THEN LET l_rec_temp.tm_per6 = 0 END IF 
			IF l_rec_temp.tm_per7 IS NULL THEN LET l_rec_temp.tm_per7 = 0 END IF 
			IF l_rec_temp.tm_per8 IS NULL THEN LET l_rec_temp.tm_per8 = 0 END IF 
			IF l_rec_temp.tm_per9 IS NULL THEN LET l_rec_temp.tm_per9 = 0 END IF 
			IF l_rec_temp.tm_per10 IS NULL THEN LET l_rec_temp.tm_per10 = 0 END IF 
			IF l_rec_temp.tm_per11 IS NULL THEN LET l_rec_temp.tm_per11 = 0 END IF 
			IF l_rec_temp.tm_per12 IS NULL THEN LET l_rec_temp.tm_per12 = 0 END IF 
			IF l_rec_temp.tm_per13 IS NULL THEN LET l_rec_temp.tm_per13 = 0 END IF 
			INSERT INTO tempper VALUES (l_rec_temp.*) 

		ELSE 

			CASE (l_rec_accounthist.period_num) 
				WHEN 1 
					LET l_rec_temp.tm_per1 = l_rec_temp.tm_per1 + l_rec_accounthist.budg1_amt 
				WHEN 2 
					LET l_rec_temp.tm_per2 = l_rec_temp.tm_per2 + l_rec_accounthist.budg1_amt 
				WHEN 3 
					LET l_rec_temp.tm_per3 = l_rec_temp.tm_per3 + l_rec_accounthist.budg1_amt 
				WHEN 4 
					LET l_rec_temp.tm_per4 = l_rec_temp.tm_per4 + l_rec_accounthist.budg1_amt 
				WHEN 5 
					LET l_rec_temp.tm_per5 = l_rec_temp.tm_per5 + l_rec_accounthist.budg1_amt 
				WHEN 6 
					LET l_rec_temp.tm_per6 = l_rec_temp.tm_per6 + l_rec_accounthist.budg1_amt 
				WHEN 7 
					LET l_rec_temp.tm_per7 = l_rec_temp.tm_per7 + l_rec_accounthist.budg1_amt 
				WHEN 8 
					LET l_rec_temp.tm_per8 = l_rec_temp.tm_per8 + l_rec_accounthist.budg1_amt 
				WHEN 9 
					LET l_rec_temp.tm_per9 = l_rec_temp.tm_per9 + l_rec_accounthist.budg1_amt 
				WHEN 10 
					LET l_rec_temp.tm_per10 = l_rec_temp.tm_per10 + l_rec_accounthist.budg1_amt 
				WHEN 11 
					LET l_rec_temp.tm_per11 = l_rec_temp.tm_per11 + l_rec_accounthist.budg1_amt 
				WHEN 12 
					LET l_rec_temp.tm_per12 = l_rec_temp.tm_per12 + l_rec_accounthist.budg1_amt 
				WHEN 13 
					LET l_rec_temp.tm_per13 = l_rec_temp.tm_per13 + l_rec_accounthist.budg1_amt 
			END CASE 

			IF l_rec_temp.tm_per1 IS NULL THEN LET l_rec_temp.tm_per1 = 0 END IF 
			IF l_rec_temp.tm_per2 IS NULL THEN LET l_rec_temp.tm_per2 = 0 END IF 
			IF l_rec_temp.tm_per3 IS NULL THEN LET l_rec_temp.tm_per3 = 0 END IF 
			IF l_rec_temp.tm_per4 IS NULL THEN LET l_rec_temp.tm_per4 = 0 END IF 
			IF l_rec_temp.tm_per5 IS NULL THEN LET l_rec_temp.tm_per5 = 0 END IF 
			IF l_rec_temp.tm_per6 IS NULL THEN LET l_rec_temp.tm_per6 = 0 END IF 
			IF l_rec_temp.tm_per7 IS NULL THEN LET l_rec_temp.tm_per7 = 0 END IF 
			IF l_rec_temp.tm_per8 IS NULL THEN LET l_rec_temp.tm_per8 = 0 END IF 
			IF l_rec_temp.tm_per9 IS NULL THEN LET l_rec_temp.tm_per9 = 0 END IF 
			IF l_rec_temp.tm_per10 IS NULL THEN LET l_rec_temp.tm_per10 = 0 END IF 
			IF l_rec_temp.tm_per11 IS NULL THEN LET l_rec_temp.tm_per11 = 0 END IF 
			IF l_rec_temp.tm_per12 IS NULL THEN LET l_rec_temp.tm_per12 = 0 END IF 
			IF l_rec_temp.tm_per13 IS NULL THEN LET l_rec_temp.tm_per13 = 0 END IF 

			UPDATE tempper 
			SET tm_per1 = l_rec_temp.tm_per1, 
			tm_per2 = l_rec_temp.tm_per2, 
			tm_per3 = l_rec_temp.tm_per3, 
			tm_per4 = l_rec_temp.tm_per4, 
			tm_per5 = l_rec_temp.tm_per5, 
			tm_per6 = l_rec_temp.tm_per6, 
			tm_per7 = l_rec_temp.tm_per7, 
			tm_per8 = l_rec_temp.tm_per8, 
			tm_per9 = l_rec_temp.tm_per9, 
			tm_per10 = l_rec_temp.tm_per10, 
			tm_per11 = l_rec_temp.tm_per11, 
			tm_per12 = l_rec_temp.tm_per12, 
			tm_per13 = l_rec_temp.tm_per13 
			WHERE tm_cmpy = l_rec_temp.tm_cmpy 
			AND tm_acct = l_rec_temp.tm_acct 
			AND tm_year = l_rec_temp.tm_year 
		END IF 

		INITIALIZE l_rec_accounthist.* TO NULL 
		INITIALIZE l_rec_temp.* TO NULL 

	END FOREACH 

	DECLARE tempcurs CURSOR FOR 
	SELECT * 
	INTO l_rec_temp.* 
	FROM tempper 
	ORDER BY tm_cmpy, tm_year, tm_acct 

	FOREACH tempcurs 
		IF int_flag OR quit_flag THEN 
			ERROR kandoomsg2("U",9501,"")																													#9501 Printing was aborted.
			RETURN false 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GAC_rpt_list(l_rpt_idx,l_rec_temp.*)  
		IF NOT rpt_int_flag_handler2("Account:",l_rec_temp.tm_acct, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GAC_rpt_list
	CALL rpt_finish("GAC_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


###############################################################
# REPORT GAC_rpt_list(p_rpt_idx,p_rec_temp)
#
#
###############################################################
REPORT GAC_rpt_list(p_rpt_idx,p_rec_temp)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_temp RECORD 
		tm_cmpy LIKE accounthist.cmpy_code, 
		tm_acct LIKE accounthist.acct_code, 
		tm_desc LIKE coa.desc_text, 
		tm_year LIKE accounthist.year_num, 
		tm_per1 DECIMAL(15,0), 
		tm_per2 DECIMAL(15,0), 
		tm_per3 DECIMAL(15,0), 
		tm_per4 DECIMAL(15,0), 
		tm_per5 DECIMAL(15,0), 
		tm_per6 DECIMAL(15,0), 
		tm_per7 DECIMAL(15,0), 
		tm_per8 DECIMAL(15,0), 
		tm_per9 DECIMAL(15,0), 
		tm_per10 DECIMAL(15,0), 
		tm_per11 DECIMAL(15,0), 
		tm_per12 DECIMAL(15,0), 
		tm_per13 DECIMAL(15,0), 
		tm_tot DECIMAL(15,0) 
	END RECORD 
	DEFINE l_cmpy_tot DECIMAL(15,0) 
	DEFINE l_report_tot DECIMAL(15,0) 
	DEFINE l_year_tot DECIMAL(15,0) 

	OUTPUT 
	--left margin 0 
	#right margin
	#top margin
	#page length

	ORDER external BY p_rec_temp.tm_year, p_rec_temp.tm_acct 
	FORMAT 
		PAGE HEADER 
			IF pageno = 1 THEN 
				LET l_cmpy_tot = 0 
				LET l_year_tot = 0 
				LET l_report_tot = 0 
			END IF 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 10, "Starting Period: ", glob_speriod USING "##", 
			COLUMN 50, "Budget : ", modu_budget_name_text, 
			COLUMN 90, "Ending Period: ", glob_eperiod USING "##" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 3, "Period", 
			COLUMN 12, "Period", 
			COLUMN 21, "Period", 
			COLUMN 30, "Period", 
			COLUMN 39, "Period", 
			COLUMN 48, "Period", 
			COLUMN 57, "Period", 
			COLUMN 66, "Period", 
			COLUMN 75, "Period", 
			COLUMN 84, "Period", 
			COLUMN 93, "Period", 
			COLUMN 102, "Period", 
			COLUMN 111, "Period", 
			COLUMN 120, "Total" 

			PRINT COLUMN 3, " One", 
			COLUMN 12, "Two", 
			COLUMN 21, "Three", 
			COLUMN 30, " Four", 
			COLUMN 39, " Five", 
			COLUMN 48, " Six", 
			COLUMN 57, "Seven", 
			COLUMN 66, "Eight", 
			COLUMN 75, " Nine", 
			COLUMN 84, " Ten", 
			COLUMN 93, "Eleven", 
			COLUMN 102, "Twelve", 
			COLUMN 111, "Thirteen", 
			COLUMN 120, "Account" 



			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 

			LET p_rec_temp.tm_tot = 0 
			IF glob_arr_per_num[1] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per1 
			ELSE 
				LET p_rec_temp.tm_per1 = " " 
			END IF 
			IF glob_arr_per_num[2] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per2 
			ELSE 
				LET p_rec_temp.tm_per2 = " " 
			END IF 
			IF glob_arr_per_num[3] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per3 
			ELSE 
				LET p_rec_temp.tm_per3 = " " 
			END IF 
			IF glob_arr_per_num[4] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per4 
			ELSE 
				LET p_rec_temp.tm_per4 = " " 
			END IF 
			IF glob_arr_per_num[5] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per5 
			ELSE 
				LET p_rec_temp.tm_per5 = " " 
			END IF 
			IF glob_arr_per_num[6] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per6 
			ELSE 
				LET p_rec_temp.tm_per6 = " " 
			END IF 
			IF glob_arr_per_num[7] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per7 
			ELSE 
				LET p_rec_temp.tm_per7 = " " 
			END IF 
			IF glob_arr_per_num[8] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per8 
			ELSE 
				LET p_rec_temp.tm_per8 = " " 
			END IF 
			IF glob_arr_per_num[9] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per9 
			ELSE 
				LET p_rec_temp.tm_per9 = " " 
			END IF 
			IF glob_arr_per_num[10] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per10 
			ELSE 
				LET p_rec_temp.tm_per10 = " " 
			END IF 
			IF glob_arr_per_num[11] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per11 
			ELSE 
				LET p_rec_temp.tm_per11 = " " 
			END IF 
			IF glob_arr_per_num[12] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per12 
			ELSE 
				LET p_rec_temp.tm_per12 = " " 
			END IF 

			IF glob_arr_per_num[13] = "Y" THEN 
				LET p_rec_temp.tm_tot = p_rec_temp.tm_tot + p_rec_temp.tm_per13 
			ELSE 
				LET p_rec_temp.tm_per13 = " " 
			END IF 

			IF p_rec_temp.tm_tot = 0 AND 
			glob_z_supp = "Y" THEN 
			ELSE 
				PRINT COLUMN 1, p_rec_temp.tm_acct , 
				COLUMN 12, p_rec_temp.tm_desc 
				PRINT COLUMN 1, p_rec_temp.tm_per1 USING "--------&", 
				COLUMN 10, p_rec_temp.tm_per2 USING "--------&", 
				COLUMN 19, p_rec_temp.tm_per3 USING "--------&", 
				COLUMN 28, p_rec_temp.tm_per4 USING "--------&", 
				COLUMN 37, p_rec_temp.tm_per5 USING "--------&", 
				COLUMN 46, p_rec_temp.tm_per6 USING "--------&", 
				COLUMN 55, p_rec_temp.tm_per7 USING "--------&", 
				COLUMN 64, p_rec_temp.tm_per8 USING "--------&", 
				COLUMN 73, p_rec_temp.tm_per9 USING "--------&", 
				COLUMN 82, p_rec_temp.tm_per10 USING "--------&", 
				COLUMN 91, p_rec_temp.tm_per11 USING "--------&", 
				COLUMN 100, p_rec_temp.tm_per12 USING "--------&", 
				COLUMN 109, p_rec_temp.tm_per13 USING "--------&", 
				COLUMN 118, p_rec_temp.tm_tot USING "-,---,---,--&" 
				LET l_cmpy_tot = l_cmpy_tot + p_rec_temp.tm_tot 
				LET l_year_tot = l_year_tot + p_rec_temp.tm_tot 
				LET l_report_tot = l_report_tot + p_rec_temp.tm_tot 
			END IF 

		ON LAST ROW 
			PRINT COLUMN 1, "Report Total:" 
			IF glob_arr_per_num[1] = "Y" THEN 
				PRINT COLUMN 1, sum(p_rec_temp.tm_per1) USING "--------&"; 
			ELSE 
				PRINT COLUMN 1, " "; 
			END IF 
			IF glob_arr_per_num[2] = "Y" THEN 
				PRINT COLUMN 10, sum(p_rec_temp.tm_per2) USING "--------&"; 
			ELSE 
				PRINT COLUMN 10, " "; 
			END IF 
			IF glob_arr_per_num[3] = "Y" THEN 
				PRINT COLUMN 19, sum(p_rec_temp.tm_per3) USING "--------&"; 
			ELSE 
				PRINT COLUMN 19, " "; 
			END IF 
			IF glob_arr_per_num[4] = "Y" THEN 
				PRINT COLUMN 28, sum(p_rec_temp.tm_per4) USING "--------&"; 
			ELSE 
				PRINT COLUMN 28, " "; 
			END IF 
			IF glob_arr_per_num[5] = "Y" THEN 
				PRINT COLUMN 37, sum(p_rec_temp.tm_per5) USING "--------&"; 
			ELSE 
				PRINT COLUMN 37, " "; 
			END IF 
			IF glob_arr_per_num[6] = "Y" THEN 
				PRINT COLUMN 46, sum(p_rec_temp.tm_per6) USING "--------&"; 
			ELSE 
				PRINT COLUMN 46, " "; 
			END IF 
			IF glob_arr_per_num[7] = "Y" THEN 
				PRINT COLUMN 55, sum(p_rec_temp.tm_per7) USING "--------&"; 
			ELSE 
				PRINT COLUMN 55, " "; 
			END IF 
			IF glob_arr_per_num[8] = "Y" THEN 
				PRINT COLUMN 64, sum(p_rec_temp.tm_per8) USING "--------&"; 
			ELSE 
				PRINT COLUMN 64, " "; 
			END IF 
			IF glob_arr_per_num[9] = "Y" THEN 
				PRINT COLUMN 73, sum(p_rec_temp.tm_per9) USING "--------&"; 
			ELSE 
				PRINT COLUMN 73, " "; 
			END IF 
			IF glob_arr_per_num[10] = "Y" THEN 
				PRINT COLUMN 82, sum(p_rec_temp.tm_per10) USING "--------&"; 
			ELSE 
				PRINT COLUMN 82, " "; 
			END IF 
			IF glob_arr_per_num[11] = "Y" THEN 
				PRINT COLUMN 91, sum(p_rec_temp.tm_per11) USING "--------&"; 
			ELSE 
				PRINT COLUMN 91, " "; 
			END IF 
			IF glob_arr_per_num[12] = "Y" THEN 
				PRINT COLUMN 100, sum(p_rec_temp.tm_per12) USING "--------&"; 
			ELSE 
				PRINT COLUMN 100, " "; 
			END IF 
			IF glob_arr_per_num[13] = "Y" THEN 
				PRINT COLUMN 109, sum(p_rec_temp.tm_per13) USING "--------&"; 
			ELSE 
				PRINT COLUMN 109, " "; 
			END IF 
			PRINT COLUMN 118, l_report_tot USING "-,---,---,--&" 

			SKIP 1 line 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

		BEFORE GROUP OF p_rec_temp.tm_year 
			SKIP 1 line 
			PRINT COLUMN 1, "Year: ", p_rec_temp.tm_year USING "####" 

		AFTER GROUP OF p_rec_temp.tm_year 

			PRINT COLUMN 1, "========================================", 
			"========================================", 
			"========================================", 
			"==========" 
			PRINT COLUMN 1, "Year Total: " 
			IF glob_arr_per_num[1] = "Y" THEN 
				PRINT COLUMN 1, GROUP sum(p_rec_temp.tm_per1) USING "--------&"; 
			ELSE 
				PRINT COLUMN 1, " "; 
			END IF 
			IF glob_arr_per_num[2] = "Y" THEN 
				PRINT COLUMN 10, GROUP sum(p_rec_temp.tm_per2) USING "--------&"; 
			ELSE 
				PRINT COLUMN 10, " "; 
			END IF 
			IF glob_arr_per_num[3] = "Y" THEN 
				PRINT COLUMN 19, GROUP sum(p_rec_temp.tm_per3) USING "--------&"; 
			ELSE 
				PRINT COLUMN 19, " "; 
			END IF 
			IF glob_arr_per_num[4] = "Y" THEN 
				PRINT COLUMN 28, GROUP sum(p_rec_temp.tm_per4) USING "--------&"; 
			ELSE 
				PRINT COLUMN 28, " "; 
			END IF 
			IF glob_arr_per_num[5] = "Y" THEN 
				PRINT COLUMN 37, GROUP sum(p_rec_temp.tm_per5) USING "--------&"; 
			ELSE 
				PRINT COLUMN 37, " "; 
			END IF 
			IF glob_arr_per_num[6] = "Y" THEN 
				PRINT COLUMN 46, GROUP sum(p_rec_temp.tm_per6) USING "--------&"; 
			ELSE 
				PRINT COLUMN 46, " "; 
			END IF 
			IF glob_arr_per_num[7] = "Y" THEN 
				PRINT COLUMN 55, GROUP sum(p_rec_temp.tm_per7) USING "--------&"; 
			ELSE 
				PRINT COLUMN 55, " "; 
			END IF 
			IF glob_arr_per_num[8] = "Y" THEN 
				PRINT COLUMN 64, GROUP sum(p_rec_temp.tm_per8) USING "--------&"; 
			ELSE 
				PRINT COLUMN 64, " "; 
			END IF 
			IF glob_arr_per_num[9] = "Y" THEN 
				PRINT COLUMN 73, GROUP sum(p_rec_temp.tm_per9) USING "--------&"; 
			ELSE 
				PRINT COLUMN 73, " "; 
			END IF 
			IF glob_arr_per_num[10] = "Y" THEN 
				PRINT COLUMN 82, GROUP sum(p_rec_temp.tm_per10) USING "--------&"; 
			ELSE 
				PRINT COLUMN 82, " "; 
			END IF 
			IF glob_arr_per_num[11] = "Y" THEN 
				PRINT COLUMN 91, GROUP sum(p_rec_temp.tm_per11) USING "--------&"; 
			ELSE 
				PRINT COLUMN 91, " "; 
			END IF 
			IF glob_arr_per_num[12] = "Y" THEN 
				PRINT COLUMN 100, GROUP sum(p_rec_temp.tm_per12) USING "--------&"; 
			ELSE 
				PRINT COLUMN 100, " "; 
			END IF 
			IF glob_arr_per_num[13] = "Y" THEN 
				PRINT COLUMN 109, GROUP sum(p_rec_temp.tm_per13) USING "--------&"; 
			ELSE 
				PRINT COLUMN 109, " "; 
			END IF 

			PRINT COLUMN 118, l_year_tot USING "-,---,---,--&" 

			LET l_year_tot = 0 
END REPORT