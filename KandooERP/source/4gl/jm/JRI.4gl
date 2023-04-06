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
#  JRI - Job Cost Material/Labour Report.
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JRI_GLOBALS.4gl"

#Module Scope Variables
DEFINE 
pr_jmparms RECORD LIKE jmparms.*, 
pr_jobtype RECORD LIKE jobtype.*, 
pr_wildcard CHAR(1), 
pr_total_lab_amt, 
pr_total_mat_amt, 
pr_total_oth_amt, 
pr_total_inv_amt DECIMAL(16,2) 
DEFINE modu_load_filename STRING

MAIN 
	#Initial UI Init
	CALL setModuleId("JRI") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 Job Management Parameters Not Found
		EXIT program 
	END IF 
	CREATE temp TABLE t_cost(job_code CHAR(8), 
	activity_code CHAR(8), 
	var_code INTEGER, 
	res_code CHAR(8), 
	cost_amt DECIMAL(16, 2), 
	inv_amt DECIMAL(16,2), 
	title_text CHAR(30)) with no LOG 
	
	CREATE temp TABLE t_testdir(file CHAR (10)) with no LOG
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW J320 with FORM "J320" -- alch kd-747 
			CALL winDecoration_j("J320") -- alch kd-747 

			MENU " JM Costing Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRI","menu-jm_costing_rep-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRI_rpt_process(JRI_rpt_query()) 				

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" --COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRI_rpt_process(JRI_rpt_query()) 				

				ON ACTION "Print Manager"				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW J320 

	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRI_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J320 with FORM "J320" 
			CALL winDecoration_j("J320") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRI_rpt_query()) #save where clause in env 
			CLOSE WINDOW J320 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRI_rpt_process(get_url_sel_text())
	END CASE 
	
END MAIN 


FUNCTION JRI_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE 
	pr_type_code LIKE job.type_code 
	CLEAR FORM 
	LET modu_load_filename = NULL 
	LET pr_wildcard = "N" 
	INITIALIZE pr_jobtype.* TO NULL 

	DISPLAY BY NAME pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 

	LET msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue.

	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.type_code, 
	job.cust_code, 
	jobledger.var_code, 
	jobledger.activity_code, 
	jobledger.year_num, 
	jobledger.period_num, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRI","const-job_job_code-10") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD type_code 
			INITIALIZE pr_jobtype.* TO NULL 
			IF field_touched(type_code) THEN 
				LET pr_type_code = get_fldbuf(type_code) 
			END IF 
			IF pr_type_code IS NOT NULL THEN 
				CALL disp_report_codes(pr_type_code) 
			END IF 
		BEFORE FIELD report1_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt1_ind = 5 THEN 
						NEXT FIELD report2_text 
					END IF 
				ELSE 
					IF pr_jmparms.prompt1_ind = 5 THEN 
						NEXT FIELD report2_text 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt1_ind = 5 THEN 
					NEXT FIELD report2_text 
				END IF 
			END IF 
		BEFORE FIELD report2_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt2_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report1_text 
						ELSE 
							NEXT FIELD report3_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt2_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report1_text 
						ELSE 
							NEXT FIELD report3_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt2_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report1_text 
					ELSE 
						NEXT FIELD report3_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report3_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt3_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report2_text 
						ELSE 
							NEXT FIELD report4_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt3_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report2_text 
						ELSE 
							NEXT FIELD report4_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt3_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report2_text 
					ELSE 
						NEXT FIELD report4_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report4_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt4_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report3_text 
						ELSE 
							NEXT FIELD report5_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt4_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report3_text 
						ELSE 
							NEXT FIELD report5_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt4_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report3_text 
					ELSE 
						NEXT FIELD report5_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report5_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt5_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report4_text 
						ELSE 
							NEXT FIELD report6_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt5_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report4_text 
						ELSE 
							NEXT FIELD report6_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt5_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report4_text 
					ELSE 
						NEXT FIELD report6_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report6_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt6_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report5_text 
						ELSE 
							NEXT FIELD report7_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt6_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report5_text 
						ELSE 
							NEXT FIELD report7_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt6_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report5_text 
					ELSE 
						NEXT FIELD report7_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report7_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt7_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report6_text 
						ELSE 
							NEXT FIELD report8_text 
						END IF 
					END IF 
				ELSE 
					IF pr_jmparms.prompt7_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report6_text 
						ELSE 
							NEXT FIELD report8_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt7_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report6_text 
					ELSE 
						NEXT FIELD report8_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report8_text 
			IF pr_type_code IS NOT NULL THEN 
				IF pr_wildcard != "Y" THEN 
					IF pr_jobtype.prompt8_ind = 5 THEN 
						EXIT CONSTRUCT 
					END IF 
				ELSE 
					IF pr_jmparms.prompt8_ind = 5 THEN 
						EXIT CONSTRUCT 
					END IF 
				END IF 
			ELSE 
				IF pr_jmparms.prompt8_ind = 5 THEN 
					EXIT CONSTRUCT 
				END IF 
			END IF 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
	
	LET msgresp = kandoomsg("U",1020,"OUTPUT File")	#1020 Enter Ouput File Details; OK TO Continue
	INPUT BY NAME modu_load_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRI","input-pr_filename-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD filename 
			IF modu_load_filename IS NOT NULL THEN 
				WHENEVER ERROR CONTINUE 
				LOAD FROM modu_load_filename delimiter "\^j" INSERT INTO t_testdir 
				IF status = 0 THEN 
					IF kandoomsg("J",8010,"") = "N" THEN					#8010 This file already exists confirm TO overwrite
						NEXT FIELD filename 
					END IF 
				END IF 
				
				DELETE FROM t_testdir WHERE 1=1
				 
				UNLOAD TO modu_load_filename SELECT * FROM t_testdir 
				IF status = -806 THEN 
					LET msgresp = kandoomsg("U",9128,"")				#9128 The unload directory does NOT exist
					NEXT FIELD filename 
				END IF 
				WHENEVER ERROR stop 
			END IF 
 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION 


FUNCTION JRI_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
	DEFINE 
--	modu_load_filename CHAR(100), 
	pr_cost RECORD 
		job_code LIKE job.job_code, 
		activity_code LIKE activity.activity_code, 
		var_code LIKE jobvars.var_code, 
		res_code LIKE jmresource.res_code, 
		cost_amt LIKE jobledger.trans_amt, 
		inv_amt LIKE jobledger.trans_amt, 
		title_text LIKE job.title_text 
	END RECORD, 
	i, pr_length, pr_continue SMALLINT 

	LET pr_continue = true 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRI_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	
	START REPORT JRI_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRI_rpt_list")].sel_text
	#------------------------------------------------------------

 
	LET l_query_text = "SELECT job.job_code, jobledger.activity_code, ", 
	" jobledger.var_code, jobledger.trans_source_text, ", 
	" sum(jobledger.trans_amt), 0, job.title_text ", 
	" FROM job, jobledger ", 
	" WHERE job.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND jobledger.cmpy_code = job.cmpy_code ", 
	" AND job.job_code = jobledger.job_code ", 
	" AND ", p_where_text clipped, 
	" group by job.job_code, jobledger.activity_code, ", 
	" jobledger.var_code, trans_source_text, ", 
	" job.title_text " 
	PREPARE s_jobledger FROM l_query_text 
	DECLARE c_jobledger CURSOR FOR s_jobledger
	 
	FOREACH c_jobledger INTO pr_cost.*
			IF NOT rpt_int_flag_handler2("Job:",pr_cost.job_code, pr_cost.title_text,l_rpt_idx) THEN
				LET pr_continue = false
				EXIT FOREACH 
			END IF 
		INSERT INTO t_cost VALUES (pr_cost.*) 
	END FOREACH

	#NOTE: This needs investigating.. and cleaning up.. shitty string segments	 
	IF pr_continue THEN 
		LET p_where_text = p_where_text #???
		LET pr_length = length(p_where_text)
		 
		FOR i = 1 TO pr_length 
			IF p_where_text[i, i + 24] = "jobledger.trans_source_text" THEN 
				LET p_where_text[i, i + 24] = " resbill.res_code" 
				CONTINUE FOR 
			END IF 
			IF p_where_text[i, i + 17] = "jobledger.year_num" THEN 
				LET p_where_text[i, i + 17] = " i.year_num" 
				CONTINUE FOR 
			END IF 
			IF p_where_text[i, i + 19] = "jobledger.period_num" THEN 
				LET p_where_text[i, i + 19] = " i.period_num" 
				CONTINUE FOR 
			END IF 
			IF p_where_text[i, i + 8] = "jobledger" THEN 
				LET p_where_text[i, i + 8] = " resbill" 
				CONTINUE FOR 
			END IF 
		END FOR
		 
		LET l_query_text = "SELECT job.job_code, resbill.activity_code, ", 
		" resbill.var_code, resbill.res_code, 0, ", 
		" sum(resbill.apply_amt), job.title_text ", 
		" FROM job, resbill, invoicehead i", 
		" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		" AND resbill.cmpy_code = job.cmpy_code ", 
		" AND i.cmpy_code = job.cmpy_code ", 
		" AND job.job_code = resbill.job_code ", 
		" AND i.inv_num = resbill.inv_num ", 
		" AND i.cust_code = job.cust_code ", 
		" AND resbill.tran_type_ind in ('1','2') ", 
		" AND ", p_where_text clipped, 
		" group by job.job_code, resbill.activity_code, ", 
		" resbill.var_code, resbill.res_code, ", 
		" job.title_text " 
		PREPARE s_invoice FROM l_query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 

		FOREACH c_invoice INTO pr_cost.* 

			#---------------------------------------------------------
			IF NOT rpt_int_flag_handler2("Job:",pr_cost.job_code, pr_cost.title_text,l_rpt_idx) THEN
				LET pr_continue = false 
				EXIT FOREACH 
			END IF 
			INSERT INTO t_cost VALUES (pr_cost.*) 
			#---------------------------------------------------------

		END FOREACH 

	END IF 

	IF pr_continue THEN 
		LET l_query_text = "SELECT job.job_code, resbill.activity_code, ", 
		" resbill.var_code, resbill.res_code, 0, ", 
		" sum(resbill.apply_amt), job.title_text ", 
		" FROM job, resbill, credithead i ", 
		" WHERE job.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		" AND resbill.cmpy_code = job.cmpy_code ", 
		" AND i.cmpy_code = job.cmpy_code ", 
		" AND job.job_code = resbill.job_code ", 
		" AND i.cred_num = resbill.inv_num ", 
		" AND i.cust_code = job.cust_code ", 
		" AND resbill.tran_type_ind in ('3') ", 
		" AND ", p_where_text clipped," ", 
		" group by job.job_code, resbill.activity_code, ", 
		" resbill.var_code, resbill.res_code, ", 
		" job.title_text " 
		PREPARE s_credit FROM l_query_text 
		DECLARE c_credit CURSOR FOR s_credit 
		FOREACH c_credit INTO pr_cost.*
			IF NOT rpt_int_flag_handler2("Job:",pr_cost.job_code, pr_cost.title_text,l_rpt_idx) THEN
				LET pr_continue = false
				EXIT FOREACH 
			END IF 
			INSERT INTO t_cost VALUES (pr_cost.*) 
		END FOREACH 
	END IF 

	IF pr_continue THEN 
		DECLARE c_t_cost CURSOR FOR 
		SELECT * FROM t_cost 
		ORDER BY job_code, activity_code, var_code, res_code 

		START REPORT JRI_rpt_list_spreadsheet TO modu_load_filename 

		FOREACH c_t_cost INTO pr_cost.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT JRI_rpt_list_spreadsheet(l_rpt_idx,
			pr_cost.*)  
			IF NOT rpt_int_flag_handler2("Job:",pr_cost.job_code, pr_cost.title_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 

		#------------------------------------------------------------
		FINISH REPORT JRI_rpt_list_spreadsheet
		CALL rpt_finish("JRI_rpt_list_spreadsheet")
		#------------------------------------------------------------

	END IF 

	IF pr_continue THEN 
		LET pr_total_lab_amt = 0 
		LET pr_total_mat_amt = 0 
		LET pr_total_oth_amt = 0 
		LET pr_total_inv_amt = 0 
		FOREACH c_t_cost INTO pr_cost.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT JRI_rpt_list(l_rpt_idx,
			pr_cost.*)  
			IF NOT rpt_int_flag_handler2("Job:",pr_cost.job_code, pr_cost.title_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT JRI_rpt_list
	CALL rpt_finish("JRI_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION disp_report_codes(pr_type_code) 
	DEFINE 
	pr_type_code LIKE job.type_code 

	SELECT * INTO pr_jobtype.* FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_type_code 
	IF status <> notfound THEN 
		IF pr_jobtype.prompt1_text IS NULL THEN 
			LET pr_jobtype.prompt1_text = pr_jmparms.prompt1_text 
			LET pr_jobtype.prompt1_ind = pr_jmparms.prompt1_ind 
		END IF 
		IF pr_jobtype.prompt2_text IS NULL THEN 
			LET pr_jobtype.prompt2_text = pr_jmparms.prompt2_text 
			LET pr_jobtype.prompt2_ind = pr_jmparms.prompt2_ind 
		END IF 
		IF pr_jobtype.prompt3_text IS NULL THEN 
			LET pr_jobtype.prompt3_text = pr_jmparms.prompt3_text 
			LET pr_jobtype.prompt3_ind = pr_jmparms.prompt3_ind 
		END IF 
		IF pr_jobtype.prompt4_text IS NULL THEN 
			LET pr_jobtype.prompt4_text = pr_jmparms.prompt4_text 
			LET pr_jobtype.prompt4_ind = pr_jmparms.prompt4_ind 
		END IF 
		IF pr_jobtype.prompt5_text IS NULL THEN 
			LET pr_jobtype.prompt5_text = pr_jmparms.prompt5_text 
			LET pr_jobtype.prompt5_ind = pr_jmparms.prompt5_ind 
		END IF 
		IF pr_jobtype.prompt6_text IS NULL THEN 
			LET pr_jobtype.prompt6_text = pr_jmparms.prompt6_text 
			LET pr_jobtype.prompt6_ind = pr_jmparms.prompt6_ind 
		END IF 
		IF pr_jobtype.prompt7_text IS NULL THEN 
			LET pr_jobtype.prompt7_text = pr_jmparms.prompt7_text 
			LET pr_jobtype.prompt7_ind = pr_jmparms.prompt7_ind 
		END IF 
		IF pr_jobtype.prompt8_text IS NULL THEN 
			LET pr_jobtype.prompt8_text = pr_jmparms.prompt8_text 
			LET pr_jobtype.prompt8_ind = pr_jmparms.prompt8_ind 
		END IF 
		IF pr_jobtype.prompt1_ind != 5 
		OR pr_jobtype.prompt2_ind != 5 
		OR pr_jobtype.prompt3_ind != 5 
		OR pr_jobtype.prompt4_ind != 5 
		OR pr_jobtype.prompt5_ind != 5 
		OR pr_jobtype.prompt6_ind != 5 
		OR pr_jobtype.prompt7_ind != 5 
		OR pr_jobtype.prompt8_ind != 5 THEN 
			DISPLAY BY NAME pr_jobtype.prompt1_text, 
			pr_jobtype.prompt2_text, 
			pr_jobtype.prompt3_text, 
			pr_jobtype.prompt4_text, 
			pr_jobtype.prompt5_text, 
			pr_jobtype.prompt6_text, 
			pr_jobtype.prompt7_text, 
			pr_jobtype.prompt8_text 
		END IF 
	ELSE 
		LET pr_wildcard = "Y" 
	END IF 
END FUNCTION 


REPORT JRI_rpt_list(p_rpt_idx,pr_cost) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_cost RECORD 
		job_code LIKE job.job_code, 
		activity_code LIKE activity.activity_code, 
		var_code LIKE jobvars.var_code, 
		res_code LIKE jmresource.res_code, 
		cost_amt LIKE jobledger.trans_amt, 
		inv_amt LIKE jobledger.trans_amt, 
		title_text LIKE job.title_text 
	END RECORD, 
	pr_resgrp RECORD LIKE resgrp.*, 
	pr_job_lab_amt, 
	pr_job_oth_amt, 
	pr_job_mat_amt, 
	pr_job_gp, 
	pr_total_gp, 
	pr_job_inv_amt DECIMAL(16,2), 
	pr_job_lab_per, 
	pr_job_mat_per, 
	pr_job_oth_per, 
	pr_tot_lab_per, 
	pr_tot_mat_per, 
	pr_tot_oth_per DECIMAL(7,1), 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
 
	ORDER external BY pr_cost.job_code, 
	pr_cost.activity_code, 
	pr_cost.var_code, 
	pr_cost.res_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		AFTER GROUP OF pr_cost.job_code 
			IF pr_job_inv_amt = 0 THEN 
				LET pr_job_gp = 0 
			ELSE 
				LET pr_job_gp = ((pr_job_inv_amt 
				- (pr_job_lab_amt + pr_job_mat_amt + pr_job_oth_amt)) 
				/ pr_job_inv_amt) 
				* 100 
			END IF 
			IF (pr_job_lab_amt + pr_job_mat_amt + pr_job_oth_amt) = 0 THEN 
				LET pr_job_lab_per = 0 
				LET pr_job_mat_per = 0 
				LET pr_job_oth_per = 0 
			ELSE 
				LET pr_job_lab_per = pr_job_lab_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
				LET pr_job_mat_per = pr_job_mat_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
				LET pr_job_oth_per = pr_job_oth_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
			END IF 
			PRINT COLUMN 001, pr_cost.job_code, 
			COLUMN 010, pr_cost.title_text 
			PRINT COLUMN 020, pr_job_inv_amt USING "-------,--&.&&", 
			COLUMN 035, pr_job_lab_amt USING "------,--&.&&", 
			COLUMN 048, pr_job_lab_per USING "---&.&", 
			COLUMN 055, pr_job_mat_amt USING "-------,--&.&&", 
			COLUMN 069, pr_job_mat_per USING "---&.&", 
			COLUMN 076, pr_job_oth_amt USING "-------,--&.&&", 
			COLUMN 090, pr_job_oth_per USING "---&.&", 
			COLUMN 097, pr_job_mat_amt + pr_job_lab_amt + pr_job_oth_amt 
			USING "-------,--&.&&", 
			COLUMN 112, pr_job_inv_amt - (pr_job_lab_amt + pr_job_mat_amt 
			+ pr_job_oth_amt) USING "-------,--&.&&", 
			COLUMN 127, pr_job_gp USING "---&.&" 
			LET pr_total_lab_amt = pr_total_lab_amt + pr_job_lab_amt 
			LET pr_total_mat_amt = pr_total_mat_amt + pr_job_mat_amt 
			LET pr_total_oth_amt = pr_total_oth_amt + pr_job_oth_amt 
			LET pr_total_inv_amt = pr_total_inv_amt + pr_job_inv_amt 
		BEFORE GROUP OF pr_cost.job_code 
			LET pr_job_lab_amt = 0 
			LET pr_job_mat_amt = 0 
			LET pr_job_oth_amt = 0 
			LET pr_job_inv_amt = 0 
		ON EVERY ROW 
			INITIALIZE pr_resgrp.* TO NULL 
			SELECT * INTO pr_resgrp.* FROM resgrp 
			WHERE resgrp_code = (SELECT resgrp_code FROM jmresource 
			WHERE res_code = pr_cost.res_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code) 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_resgrp.res_type_ind = "2" THEN 
				LET pr_job_lab_amt = pr_job_lab_amt + pr_cost.cost_amt 
			ELSE 
				IF pr_resgrp.res_type_ind = "1" THEN 
					LET pr_job_mat_amt = pr_job_mat_amt + pr_cost.cost_amt 
				ELSE 
					LET pr_job_oth_amt = pr_job_oth_amt + pr_cost.cost_amt 
				END IF 
			END IF 
			LET pr_job_inv_amt = pr_job_inv_amt + pr_cost.inv_amt 
		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 020, "--------------", 
			COLUMN 035, "-------------------", 
			COLUMN 055, "--------------------", 
			COLUMN 076, "--------------------", 
			COLUMN 097, "--------------", 
			COLUMN 112, "---------------------" 
			IF pr_total_inv_amt != 0 THEN 
				LET pr_total_gp = ((pr_total_inv_amt 
				- (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt)) 
				/ pr_total_inv_amt) * 100 
			ELSE 
				LET pr_total_gp = 0 
			END IF 
			IF (pr_total_lab_amt + pr_total_mat_amt + pr_total_oth_amt) = 0 THEN 
				LET pr_tot_lab_per = 0 
				LET pr_tot_mat_per = 0 
				LET pr_tot_oth_per = 0 
			ELSE 
				LET pr_tot_lab_per = pr_total_lab_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
				LET pr_tot_mat_per = pr_total_mat_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
				LET pr_tot_oth_per = pr_total_oth_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
			END IF 
			PRINT COLUMN 010, "Total:", 
			COLUMN 020, pr_total_inv_amt USING "-------,--&.&&", 
			COLUMN 035, pr_total_lab_amt USING "------,--&.&&", 
			COLUMN 048, pr_tot_lab_per USING "---&.&", 
			COLUMN 055, pr_total_mat_amt USING "-------,--&.&&" , 
			COLUMN 069, pr_tot_mat_per USING "---&.&" , 
			COLUMN 076, pr_total_oth_amt USING "-------,--&.&&", 
			COLUMN 090, pr_tot_oth_per USING "---&.&", 
			COLUMN 097, pr_total_mat_amt + pr_total_lab_amt + pr_total_oth_amt 
			USING "-------,--&.&&", 
			COLUMN 112, pr_total_inv_amt - (pr_total_lab_amt + pr_total_mat_amt 
			+ pr_total_oth_amt) USING "-------,--&.&&" , 
			COLUMN 127, pr_total_gp USING "---&.&"
			 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 


REPORT JRI_rpt_list_spreadsheet(p_rpt_idx,pr_cost) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_cost RECORD 
		job_code LIKE job.job_code, 
		activity_code LIKE activity.activity_code, 
		var_code LIKE jobvars.var_code, 
		res_code LIKE jmresource.res_code, 
		cost_amt LIKE jobledger.trans_amt, 
		inv_amt LIKE jobledger.trans_amt, 
		title_text LIKE job.title_text 
	END RECORD, 
	pr_resgrp RECORD LIKE resgrp.*, 
	pr_job_lab_amt, 
	pr_job_oth_amt, 
	pr_job_mat_amt, 
	pr_job_gp, 
	pr_total_gp, 
	pr_job_inv_amt DECIMAL(16,2), 
	pr_job_lab_per, 
	pr_job_mat_per, 
	pr_job_oth_per, 
	pr_tot_lab_per, 
	pr_tot_mat_per, 
	pr_tot_oth_per DECIMAL(7,1), 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 2 
	ORDER external BY pr_cost.job_code, 
	pr_cost.activity_code, 
	pr_cost.var_code, 
	pr_cost.res_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		FIRST PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
		 
			LET pr_total_lab_amt = 0 
			LET pr_total_mat_amt = 0 
			LET pr_total_oth_amt = 0 
			LET pr_total_inv_amt = 0 
			PRINT COLUMN 001, "JM Costing Report created ", 
			today USING "dd/mm/yyyy", 
			" ", time 
		AFTER GROUP OF pr_cost.job_code 
			IF pr_job_inv_amt != 0 THEN 
				LET pr_job_gp = ((pr_job_inv_amt 
				- (pr_job_lab_amt + pr_job_mat_amt)) 
				/ pr_job_inv_amt) 
				* 100 
			ELSE 
				LET pr_job_gp = 0 
			END IF 
			IF (pr_job_lab_amt + pr_job_mat_amt + pr_job_oth_amt) = 0 THEN 
				LET pr_job_lab_per = 0 
				LET pr_job_mat_per = 0 
				LET pr_job_oth_per = 0 
			ELSE 
				LET pr_job_lab_per = pr_job_lab_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
				LET pr_job_mat_per = pr_job_mat_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
				LET pr_job_oth_per = pr_job_oth_amt 
				/ (pr_job_lab_amt + pr_job_mat_amt 
				+ pr_job_oth_amt) * 100 
			END IF 
			PRINT COLUMN 001, pr_cost.job_code,",", 
			COLUMN 010, pr_cost.title_text,",", 
			COLUMN 040, pr_job_inv_amt USING "---------&.&&",",", 
			COLUMN 055, pr_job_lab_amt USING "--------&.&&", ",", 
			COLUMN 069, pr_job_lab_per USING "---&.&",",", 
			COLUMN 075, pr_job_mat_amt USING "---------&.&&", 
			COLUMN 090, pr_job_mat_per USING "---&.&",",", 
			COLUMN 096, pr_job_oth_amt USING "---------&.&&",",", 
			COLUMN 100, pr_job_oth_per USING "---&.&",",", 
			COLUMN 096, pr_job_mat_amt + pr_job_lab_amt + pr_job_oth_amt 
			USING "---------&.&&",",", 
			COLUMN 112, pr_job_inv_amt - (pr_job_lab_amt + pr_job_mat_amt 
			+ pr_job_oth_amt) USING "---------&.&&",",", 
			COLUMN 126, pr_job_gp USING "---&.&" 
			LET pr_total_lab_amt = pr_total_lab_amt + pr_job_lab_amt 
			LET pr_total_mat_amt = pr_total_mat_amt + pr_job_mat_amt 
			LET pr_total_oth_amt = pr_total_oth_amt + pr_job_oth_amt 
			LET pr_total_inv_amt = pr_total_inv_amt + pr_job_inv_amt 

		BEFORE GROUP OF pr_cost.job_code 
			LET pr_job_lab_amt = 0 
			LET pr_job_mat_amt = 0 
			LET pr_job_oth_amt = 0 
			LET pr_job_inv_amt = 0 

		ON EVERY ROW 
			INITIALIZE pr_resgrp.* TO NULL 
			SELECT * INTO pr_resgrp.* FROM resgrp 
			WHERE resgrp_code = (SELECT resgrp_code FROM jmresource 
			WHERE res_code = pr_cost.res_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code) 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_resgrp.res_type_ind = "2" THEN 
				LET pr_job_lab_amt = pr_job_lab_amt + pr_cost.cost_amt 
			ELSE 
				IF pr_resgrp.res_type_ind = "1" THEN 
					LET pr_job_mat_amt = pr_job_mat_amt + pr_cost.cost_amt 
				ELSE 
					LET pr_job_oth_amt = pr_job_oth_amt + pr_cost.cost_amt 
				END IF 
			END IF 
			LET pr_job_inv_amt = pr_job_inv_amt + pr_cost.inv_amt 

		ON LAST ROW 
			IF pr_total_inv_amt != 0 THEN 
				LET pr_total_gp = ((pr_total_inv_amt 
				- (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt)) 
				/ pr_total_inv_amt) * 100 
			ELSE 
				LET pr_total_gp = 0 
			END IF 
			IF (pr_total_lab_amt + pr_total_mat_amt + pr_total_oth_amt) = 0 THEN 
				LET pr_tot_lab_per = 0 
				LET pr_tot_mat_per = 0 
				LET pr_tot_oth_per = 0 
			ELSE 
				LET pr_tot_lab_per = pr_total_lab_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
				LET pr_tot_mat_per = pr_total_mat_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
				LET pr_tot_oth_per = pr_total_oth_amt 
				/ (pr_total_lab_amt + pr_total_mat_amt 
				+ pr_total_oth_amt) * 100 
			END IF 
			PRINT COLUMN 010, "Total:",",", 
			COLUMN 040, pr_total_inv_amt USING "---------&.&&",",", 
			COLUMN 055, pr_total_lab_amt USING "--------&.&&",",", 
			COLUMN 069, pr_tot_lab_per USING "---&.&",",", 
			COLUMN 075, pr_total_mat_amt USING "---------&.&&" ,",", 
			COLUMN 090, pr_tot_mat_per USING "---&.&" ,",", 
			COLUMN 096, pr_total_oth_amt USING "---------&.&&",",", 
			COLUMN 100, pr_tot_oth_per USING "---&.&",",", 
			COLUMN 096, pr_total_mat_amt + pr_total_lab_amt + pr_total_oth_amt 
			USING "---------&.&&", ",", 
			COLUMN 112, pr_total_inv_amt - (pr_total_lab_amt + pr_total_mat_amt 
			+ pr_total_oth_amt) USING "---------&.&&",",", 
			COLUMN 126, pr_total_gp USING "---&.&" 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT