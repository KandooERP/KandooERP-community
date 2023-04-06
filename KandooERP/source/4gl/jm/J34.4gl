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
GLOBALS "../jm/J_JM_GLOBALS.4gl"
GLOBALS "../jm/J3_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J34_GLOBALS.4gl"

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J34.4gl Pre-invoice REPORT

 
--	DEFINE formname CHAR(15) 

--	DEFINE pr_menunames RECORD LIKE menunames.* 

DEFINE modu_rec_job RECORD LIKE job.* 
--DEFINE glob_rec_company RECORD LIKE company.* 
DEFINE pr_activity RECORD LIKE activity.* 
DEFINE pr_customer RECORD LIKE customer.* 
DEFINE pr_salesperson RECORD LIKE salesperson.* 
DEFINE modu_rec_jmparms RECORD LIKE jmparms.* 
DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
DEFINE pr_user_scan_code LIKE kandoouser.acct_mask_code 
DEFINE modu_resp_name_text LIKE responsible.name_text 
DEFINE ans CHAR(1) 
DEFINE modu_where_part STRING 
DEFINE modu_query_text STRING
DEFINE modu_rec_jobtype RECORD LIKE jobtype.* 
DEFINE where_text_2 STRING

DEFINE err_message CHAR(40) 
DEFINE this_bill_amt LIKE activity.act_bill_amt  
DEFINE this_cos_amt LIKE activity.act_bill_amt  
DEFINE acti_cost_amt_tot LIKE activity.act_bill_amt  
DEFINE acti_charge_amt_tot LIKE activity.act_bill_amt 
DEFINE this_bill_qty  LIKE activity.act_bill_qty 
DEFINE acti_cost_qty_tot LIKE activity.act_bill_qty 
DEFINE job_this_bill_amt LIKE activity.act_bill_amt  
DEFINE job_fcst_bill_amt LIKE activity.act_bill_amt  
DEFINE job_act_bill_amt LIKE activity.act_bill_amt  
DEFINE job_this_cos_amt LIKE activity.act_bill_amt  
DEFINE job_fcst_cos_amt LIKE activity.act_bill_amt  
DEFINE job_act_cos_amt LIKE activity.act_bill_amt 
DEFINE modu_job_this_bill_qty LIKE activity.act_bill_qty 
DEFINE job_fcst_bill_qty LIKE activity.act_bill_qty 
DEFINE job_act_bill_qty LIKE activity.act_bill_qty 
DEFINE job_markup_per LIKE job.markup_per 
--	glob_rec_rmsreps.report_width_num SMALLINT, 
--	glob_rec_rmsreps.page_num LIKE rmsreps.page_num, 
--	glob_rec_rmsreps.page_length_num LIKE rmsreps.page_length_num, 
DEFINE err_flag SMALLINT 
DEFINE scrn SMALLINT
DEFINE idx SMALLINT
DEFINE cnt SMALLINT			

DEFINE pv_type_code LIKE job.type_code 

DEFINE pv_wildcard CHAR(1) 
DEFINE pr_zero_tran_ind SMALLINT
DEFINE pr_zero_job_ind SMALLINT
DEFINE pr_zero_inv_ind SMALLINT
 
DEFINE pr_option1 CHAR(100)
DEFINE pr_option2 CHAR(100)
DEFINE pr_option3 CHAR(100)
 
DEFINE modu_tot_job_act_bill_amt LIKE activity.act_bill_amt  
DEFINE modu_tot_job_this_bill_amt LIKE activity.act_bill_amt  
DEFINE modu_tot_job_fcst_bill_amt LIKE activity.act_bill_amt  
DEFINE modu_tot_job_act_cos_amt LIKE activity.act_bill_amt  
DEFINE modu_tot_job_this_cos_amt LIKE activity.act_bill_amt  
DEFINE modu_tot_job_fcst_cos_amt LIKE activity.act_bill_amt 
DEFINE modu_tot_job_act_bill_qty LIKE activity.act_bill_qty 
DEFINE modu_tot_job_this_bill_qty LIKE activity.act_bill_qty 
DEFINE modu_tot_job_fcst_bill_qty LIKE activity.act_bill_qty 


###########################################################################
# MAIN 
#
#
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("J34") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code)
	RETURNING pr_rec_kandoouser.acct_mask_code, pr_user_scan_code
	 
	SELECT jmparms.* 
	INTO modu_rec_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
--	SELECT * 
--	INTO glob_rec_company.* 
--	FROM company 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 

	CLEAR screen 

	OPTIONS MENU line 1, MESSAGE line 1 

	OPEN WINDOW J131 with FORM "J131" -- alch kd-747 
	CALL winDecoration_j("J131") -- alch kd-747 

	MENU "Pre-invoice REPORT" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J34","menu-pre_invoice_rep-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REPORT" --COMMAND "Run Report" "SELECT criteria AND PRINT REPORT" 
			CALL J34_rpt_query() 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT option "Run Report" 
			ELSE 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E") "Exit" "Exit the program" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW J131 
	CLEAR screen 
END MAIN 
###########################################################################
# END MAIN 
#
#
###########################################################################

###########################################################################
# FUNCTION J34_rpt_query()
#
#
###########################################################################

FUNCTION J34_rpt_query() 
	DEFINE pr_output CHAR(60) 
	DEFINE pv_trans SMALLINT 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	# MESSAGE " Enter criteria FOR selection - ESC Continue "

	LET msgresp = kandoomsg("U",1001,"") 

	DISPLAY BY NAME modu_rec_jmparms.prompt1_text, 
	modu_rec_jmparms.prompt2_text, 
	modu_rec_jmparms.prompt3_text, 
	modu_rec_jmparms.prompt4_text, 
	modu_rec_jmparms.prompt5_text, 
	modu_rec_jmparms.prompt6_text, 
	modu_rec_jmparms.prompt7_text, 
	modu_rec_jmparms.prompt8_text 
	LET pv_type_code = NULL 
	LET pv_wildcard = "N" 
	CONSTRUCT BY NAME modu_where_part ON 
	job.job_code, 
	job.title_text, 
	job.type_code, 
	job.cust_code, 
	customer.name_text, 
	salesperson.sale_code, 
	salesperson.name_text, 
	job.est_start_date, 
	job.est_end_date, 
	job.review_date, 
	job.val_date, 
	job.act_start_date, 
	job.act_end_date, 
	job.contract_text, 
	job.contract_date, 
	job.contract_amt, 
	job.locked_ind, 
	job.finish_flag, 
	job.report_text, 
	job.resp_code, 
	job.report1_text, 
	job.report2_text, 
	job.report3_text, 
	job.report4_text, 
	job.report5_text, 
	job.report6_text, 
	job.report7_text, 
	job.report8_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J34","const-job_job_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD type_code 
			IF field_touched(type_code) THEN 
				LET pv_type_code = get_fldbuf(type_code) 
			END IF 
			IF pv_type_code IS NOT NULL THEN 
				CALL disp_report_codes() 
			END IF 

		BEFORE FIELD report1_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt1_ind = 5 THEN 
						NEXT FIELD report2_text 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt1_ind = 5 THEN 
						NEXT FIELD report2_text 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt1_ind = 5 THEN 
					NEXT FIELD report2_text 
				END IF 
			END IF 

		BEFORE FIELD report2_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt2_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report1_text 
						ELSE 
							NEXT FIELD report3_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt2_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report1_text 
						ELSE 
							NEXT FIELD report3_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt2_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report1_text 
					ELSE 
						NEXT FIELD report3_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD report3_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt3_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report2_text 
						ELSE 
							NEXT FIELD report4_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt3_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report2_text 
						ELSE 
							NEXT FIELD report4_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt3_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report2_text 
					ELSE 
						NEXT FIELD report4_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD report4_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt4_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report3_text 
						ELSE 
							NEXT FIELD report5_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt4_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report3_text 
						ELSE 
							NEXT FIELD report5_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt4_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report3_text 
					ELSE 
						NEXT FIELD report5_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD report5_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt5_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report4_text 
						ELSE 
							NEXT FIELD report6_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt5_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report4_text 
						ELSE 
							NEXT FIELD report6_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt5_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report4_text 
					ELSE 
						NEXT FIELD report6_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD report6_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt6_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report5_text 
						ELSE 
							NEXT FIELD report7_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt6_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report5_text 
						ELSE 
							NEXT FIELD report7_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt6_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report5_text 
					ELSE 
						NEXT FIELD report7_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD report7_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt7_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report6_text 
						ELSE 
							NEXT FIELD report8_text 
						END IF 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt7_ind = 5 THEN 
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD report6_text 
						ELSE 
							NEXT FIELD report8_text 
						END IF 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt7_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report6_text 
					ELSE 
						NEXT FIELD report8_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD report8_text 
			IF pv_type_code IS NOT NULL THEN 
				IF pv_wildcard != "Y" THEN 
					IF modu_rec_jobtype.prompt8_ind = 5 THEN 
						EXIT CONSTRUCT 
					END IF 
				ELSE 
					IF modu_rec_jmparms.prompt8_ind = 5 THEN 
						EXIT CONSTRUCT 
					END IF 
				END IF 
			ELSE 
				IF modu_rec_jmparms.prompt8_ind = 5 THEN 
					EXIT CONSTRUCT 
				END IF 
			END IF 

		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET modu_rec_job.job_code = showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
					SELECT title_text 
					INTO modu_rec_job.title_text 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					job_code = modu_rec_job.job_code 
					DISPLAY BY NAME modu_rec_job.job_code, modu_rec_job.title_text 
					NEXT FIELD type_code 
				WHEN infield (type_code) 
					LET modu_rec_job.type_code = show_type(glob_rec_kandoouser.cmpy_code) 
					SELECT jobtype.* 
					INTO modu_rec_jobtype.* 
					FROM jobtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					type_code = modu_rec_job.type_code 
					DISPLAY BY NAME modu_rec_job.type_code, 
					modu_rec_jobtype.type_text 
					NEXT FIELD cust_code 
				WHEN infield (cust_code) 
					LET modu_rec_job.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					cust_code = modu_rec_job.cust_code 
					DISPLAY BY NAME modu_rec_job.cust_code, 
					pr_customer.name_text 
					NEXT FIELD sale_code 
				WHEN infield (sale_code) 
					LET modu_rec_job.sale_code = show_salperson(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_salesperson.name_text 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					sale_code = modu_rec_job.sale_code 
					DISPLAY BY NAME modu_rec_job.sale_code 
					DISPLAY pr_salesperson.name_text TO salesperson.name_text 
					NEXT FIELD est_start_date 
				WHEN infield(resp_code) 
					LET modu_rec_job.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO modu_resp_name_text 
					FROM responsible 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					resp_code = modu_rec_job.resp_code 
					DISPLAY BY NAME modu_rec_job.resp_code 
					DISPLAY modu_resp_name_text TO resp_name_text 
					NEXT FIELD report1_text 
			END CASE 
	END CONSTRUCT 

--	IF int_flag 
--	OR quit_flag THEN 
--		EXIT program 
--	END IF 

 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (modu_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
		
	LET l_rpt_idx = rpt_start(getmoduleid(),"J34_rpt_list",modu_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J34_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET modu_where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("J34_rpt_list")].sel_text
	#------------------------------------------------------------


	LET modu_query_text = 
	"SELECT unique job.* , customer.*, salesperson.*", 
	" FROM job, customer, salesperson WHERE ", 
	modu_where_part clipped, 
	" AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND customer.cust_code = job.cust_code ", 
	" AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND salesperson.sale_code = job.sale_code ", 
	" AND salesperson.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND (job.acct_code matches \"",pr_user_scan_code,"\" OR locked_ind = \"1\" )", 
	" ORDER BY job_code " 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	LET modu_tot_job_this_bill_amt = 0 
	LET modu_tot_job_fcst_bill_amt = 0 
	LET modu_tot_job_act_bill_amt = 0 
	LET modu_tot_job_this_bill_qty = 0 
	LET modu_tot_job_fcst_bill_qty = 0 
	LET modu_tot_job_act_bill_qty = 0 
	LET modu_tot_job_this_cos_amt = 0 
	LET modu_tot_job_fcst_cos_amt = 0 
	LET modu_tot_job_act_cos_amt = 0 

	LET job_this_bill_amt = 0 
	LET job_fcst_bill_amt = 0 
	LET job_act_bill_amt = 0 
	LET modu_job_this_bill_qty = 0 
	LET job_fcst_bill_qty = 0 
	LET job_act_bill_qty = 0 
	LET job_this_cos_amt = 0 
	LET job_fcst_cos_amt = 0 
	LET job_act_cos_amt = 0 


	# Option TO exclude OPEN jobs with 00.00 invoice amount
	#   OPEN WINDOW w1 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)   -- alch KD-747
	# "Exclude Open Jobs With 00.00 Invoice Amount?"
	LET msgresp = kandoomsg("J",1558,"") 
	IF upshift(msgresp) <> "N" THEN 
		LET pr_zero_inv_ind = true 
	ELSE 
		LET pr_zero_inv_ind = false 
	END IF 
	#   CLOSE WINDOW w1    -- alch KD-747
	# Option TO PRINT jobs with no transaction
	#   OPEN WINDOW w2 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)   -- alch KD-747
	# "Print jobs with no transactions?"
	LET msgresp = kandoomsg("J",1557,"") 
	IF upshift(msgresp) <> "N" THEN 
		LET pr_zero_job_ind = true 
	ELSE 
		LET pr_zero_job_ind = false 
	END IF 
	#   CLOSE WINDOW w2   -- alch KD-747

	# Option TO PRINT activities with no transaction
	#   OPEN WINDOW w3 AT 10,10 with 2 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)    -- alch KD-747
	# "Print activities with no transaction?"
	LET msgresp = kandoomsg("J",1502,"") 
	IF upshift(msgresp) <> "N" THEN 
		LET pr_zero_tran_ind = true 
	ELSE 
		LET pr_zero_tran_ind = false 
	END IF 
	#   CLOSE WINDOW w3   -- alch KD-747
	# S T A R T R E P O R T J34_rpt_list TO pr_output 
	#   OPEN WINDOW wfJM AT 10,10 with 1 rows, 50 columns
	#      ATTRIBUTE(border, MESSAGE line first)   -- alch KD-747
	PREPARE q_1 FROM modu_query_text 
	DECLARE c_1 CURSOR FOR q_1 

	FOREACH c_1 INTO modu_rec_job.*, pr_customer.* 
		DISPLAY "Job...", modu_rec_job.title_text at 1,10 
		SLEEP 1 

		# IF exclude the jobs with zero invoice amount
		IF pr_zero_inv_ind THEN 
			DECLARE act_curs1 CURSOR FOR 
			SELECT activity.* 
			FROM activity 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 
			FOREACH act_curs1 INTO pr_activity.* 
				CALL get_bill() RETURNING this_bill_amt, 
				this_bill_qty, 
				this_cos_amt 
				LET job_this_bill_amt = job_this_bill_amt + this_bill_amt 
				LET modu_job_this_bill_qty = modu_job_this_bill_qty + this_bill_qty 
				LET job_this_cos_amt = job_this_cos_amt + this_cos_amt 
			END FOREACH 
			IF job_this_bill_amt >0 AND modu_job_this_bill_qty > 0 AND job_this_cos_amt > 0 THEN 
				# IF only PRINT jobs with transaction
				IF NOT pr_zero_job_ind THEN 
					SELECT count(*) INTO pv_trans 
					FROM jobledger 
					WHERE cmpy_code = modu_rec_job.cmpy_code 
					AND job_code = modu_rec_job.job_code 
					IF pv_trans > 0 AND NOT pr_zero_job_ind THEN 
						#---------------------------------------------------------
						OUTPUT TO REPORT J34_rpt_list(l_rpt_idx,
						modu_rec_job.*, pr_customer.name_text) 
						#---------------------------------------------------------					
					END IF 
				ELSE 
					#---------------------------------------------------------
					OUTPUT TO REPORT J34_rpt_list(l_rpt_idx,
					modu_rec_job.*, pr_customer.name_text) 
					#---------------------------------------------------------
				END IF 
			END IF 
		ELSE 
			# IF only PRINT jobs with transaction
			IF NOT pr_zero_job_ind THEN 
				SELECT count(*) INTO pv_trans 
				FROM jobledger 
				WHERE cmpy_code = modu_rec_job.cmpy_code 
				AND job_code = modu_rec_job.job_code 
				IF pv_trans > 0 AND NOT pr_zero_job_ind THEN 
					#---------------------------------------------------------
					OUTPUT TO REPORT J34_rpt_list(l_rpt_idx,
					modu_rec_job.*, pr_customer.name_text) 
					#---------------------------------------------------------
				END IF 
			ELSE 
				#OTHERWISE, PRINT all jobs
				#---------------------------------------------------------
				OUTPUT TO REPORT J34_rpt_list(l_rpt_idx,
				modu_rec_job.*, pr_customer.name_text) 
				#---------------------------------------------------------
			END IF 
		END IF 
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT J34_rpt_list
	CALL rpt_finish("J34_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION J34_rpt_query()
#
#
###########################################################################


###########################################################################
# FUNCTION disp_report_codes()
#
#
###########################################################################
FUNCTION disp_report_codes()
 
	SELECT jobtype.* 
	INTO modu_rec_jobtype.* 
	FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	type_code = pv_type_code 

	IF status <> notfound THEN 

		IF modu_rec_jobtype.prompt1_text IS NULL THEN 
			LET modu_rec_jobtype.prompt1_text = modu_rec_jmparms.prompt1_text 
			LET modu_rec_jobtype.prompt1_ind = modu_rec_jmparms.prompt1_ind 
		END IF 

		IF modu_rec_jobtype.prompt2_text IS NULL THEN 
			LET modu_rec_jobtype.prompt2_text = modu_rec_jmparms.prompt2_text 
			LET modu_rec_jobtype.prompt2_ind = modu_rec_jmparms.prompt2_ind 
		END IF 

		IF modu_rec_jobtype.prompt3_text IS NULL THEN 
			LET modu_rec_jobtype.prompt3_text = modu_rec_jmparms.prompt3_text 
			LET modu_rec_jobtype.prompt3_ind = modu_rec_jmparms.prompt3_ind 
		END IF 

		IF modu_rec_jobtype.prompt4_text IS NULL THEN 
			LET modu_rec_jobtype.prompt4_text = modu_rec_jmparms.prompt4_text 
			LET modu_rec_jobtype.prompt4_ind = modu_rec_jmparms.prompt4_ind 
		END IF 

		IF modu_rec_jobtype.prompt5_text IS NULL THEN 
			LET modu_rec_jobtype.prompt5_text = modu_rec_jmparms.prompt5_text 
			LET modu_rec_jobtype.prompt5_ind = modu_rec_jmparms.prompt5_ind 
		END IF 

		IF modu_rec_jobtype.prompt6_text IS NULL THEN 
			LET modu_rec_jobtype.prompt6_text = modu_rec_jmparms.prompt6_text 
			LET modu_rec_jobtype.prompt6_ind = modu_rec_jmparms.prompt6_ind 
		END IF 

		IF modu_rec_jobtype.prompt7_text IS NULL THEN 
			LET modu_rec_jobtype.prompt7_text = modu_rec_jmparms.prompt7_text 
			LET modu_rec_jobtype.prompt7_ind = modu_rec_jmparms.prompt7_ind 
		END IF 

		IF modu_rec_jobtype.prompt8_text IS NULL THEN 
			LET modu_rec_jobtype.prompt8_text = modu_rec_jmparms.prompt8_text 
			LET modu_rec_jobtype.prompt8_ind = modu_rec_jmparms.prompt8_ind 
		END IF 

		IF modu_rec_jobtype.prompt1_ind != 5 OR 
		modu_rec_jobtype.prompt2_ind != 5 OR 
		modu_rec_jobtype.prompt3_ind != 5 OR 
		modu_rec_jobtype.prompt4_ind != 5 OR 
		modu_rec_jobtype.prompt5_ind != 5 OR 
		modu_rec_jobtype.prompt6_ind != 5 OR 
		modu_rec_jobtype.prompt7_ind != 5 OR 
		modu_rec_jobtype.prompt8_ind != 5 THEN 

			DISPLAY modu_rec_jobtype.prompt1_text, 
			modu_rec_jobtype.prompt2_text, 
			modu_rec_jobtype.prompt3_text, 
			modu_rec_jobtype.prompt4_text, 
			modu_rec_jobtype.prompt5_text, 
			modu_rec_jobtype.prompt6_text, 
			modu_rec_jobtype.prompt7_text, 
			modu_rec_jobtype.prompt8_text 
			TO jobtype.prompt1_text, 
			jobtype.prompt2_text, 
			jobtype.prompt3_text, 
			jobtype.prompt4_text, 
			jobtype.prompt5_text, 
			jobtype.prompt6_text, 
			jobtype.prompt7_text, 
			jobtype.prompt8_text 

		END IF 
	ELSE 
		LET pv_wildcard = "Y" 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION disp_report_codes()
###########################################################################


###########################################################################
# FUNCTION get_bill()
#
#
###########################################################################
FUNCTION get_bill() 
	DEFINE comp_per DECIMAL(6,2) 
	DEFINE this_bill_amt  LIKE activity.act_bill_amt
	DEFINE this_cos_amt LIKE activity.act_bill_amt
	DEFINE this_bill_qty LIKE activity.act_bill_qty 

	CASE pr_activity.bill_way_ind 

		WHEN "C" 
			LET this_cos_amt = pr_activity.act_cost_amt 
			- pr_activity.post_cost_amt 
			LET this_bill_amt = this_cos_amt + (this_cos_amt * 
			modu_rec_job.markup_per / 100) 
			LET this_bill_qty = pr_activity.act_cost_qty 
			- pr_activity.act_bill_qty 

		WHEN "T" 
			LET this_bill_amt = pr_activity.post_revenue_amt 
			- pr_activity.act_bill_amt 
			LET this_bill_qty = pr_activity.act_cost_qty 
			- pr_activity.act_bill_qty 
			LET this_cos_amt = pr_activity.act_cost_amt 
			- pr_activity.post_cost_amt 

		WHEN "R" 
			LET this_bill_amt = pr_activity.post_revenue_amt 
			- pr_activity.act_bill_amt 
			LET this_bill_qty = pr_activity.act_cost_qty 
			LET this_cos_amt = pr_activity.act_cost_amt 
			- pr_activity.post_cost_amt 

		WHEN "F" 
			LET this_bill_amt = ((pr_activity.est_comp_per * 
			pr_activity.est_bill_amt / 100) 
			- pr_activity.act_bill_amt) 
			LET this_bill_qty = ((pr_activity.est_comp_per * 
			pr_activity.est_bill_qty /100) - 
			pr_activity.act_bill_qty) 
			CASE pr_activity.cost_alloc_flag 
				WHEN "1" 
					LET this_cos_amt = ((pr_activity.est_comp_per * 
					pr_activity.est_cost_amt / 100) 
					- pr_activity.post_cost_amt) 
				WHEN "2" 
					IF pr_activity.est_comp_per != 100 THEN 
						LET this_cos_amt = ((pr_activity.est_comp_per * 
						pr_activity.est_cost_amt / 100) 
						- pr_activity.post_cost_amt) 
					ELSE 
						LET this_cos_amt = pr_activity.act_cost_amt 
						- pr_activity.post_cost_amt 
					END IF 
				WHEN "3" 
					LET this_cos_amt = (pr_activity.act_cost_amt * 
					pr_activity.est_comp_per /100) 
					- pr_activity.post_cost_amt 
				WHEN "4" 
					LET this_cos_amt = pr_activity.act_cost_amt 
					- pr_activity.post_cost_amt 
				WHEN "5" 
					LET this_cos_amt = 0 
			END CASE 
	END CASE 
	RETURN this_bill_amt, this_bill_qty, this_cos_amt 
END FUNCTION 
###########################################################################
# FUNCTION get_bill()
###########################################################################


###########################################################################
# REPORT J34_rpt_list(p_rpt_idx,modu_rec_job, cust_name)
#
#
###########################################################################
REPORT J34_rpt_list(p_rpt_idx,modu_rec_job, cust_name) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE modu_rec_job RECORD LIKE job.* 
	DEFINE cust_name LIKE customer.name_text 
	DEFINE pr_jobledger RECORD LIKE jobledger.* 
	DEFINE line1 CHAR(132)
	DEFINE line2 CHAR(132)
	 
	DEFINE rpt_note CHAR(40) 
	DEFINE pv_person_code LIKE person.person_code 
	DEFINE offset1 SMALLINT
	DEFINE offset2 SMALLINT

	DEFINE pv_trans SMALLINT
	DEFINE num_trans SMALLINT
	 
	DEFINE str CHAR (3000) 

	OUTPUT 
	PAGE length 66 
	top margin 0 
	left margin 5 
	bottom margin 0 
	ORDER external BY modu_rec_job.job_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			 

		BEFORE GROUP OF modu_rec_job.job_code 
			SKIP TO top OF PAGE 

		ON EVERY ROW 

			PRINT "Job:", 
			COLUMN 9, modu_rec_job.job_code, 
			COLUMN 18, ": ", modu_rec_job.title_text, 
			COLUMN 60,"Job Type :", modu_rec_job.type_code 
			PRINT "Client:", 
			COLUMN 9, modu_rec_job.cust_code, 
			COLUMN 18, ": ", cust_name, 
			COLUMN 60, "Invoice Type :", modu_rec_job.bill_issue_ind 

			CASE modu_rec_job.bill_way_ind 
				WHEN "C" 
					PRINT "Billing Type : ", 
					COLUMN 20, "Cost plus Markup ",modu_rec_job.markup_per, "%",	" - ignore charges" 
				WHEN "F" 
					PRINT "Billing Type : ", 
					COLUMN 20, "Fixed Price job - Bill % complete of estimate", " - ignore charges" 
				WHEN "T" 
					PRINT "Billing Type : ", 	COLUMN 20, "Time AND Materials" 
				WHEN "R" 
					PRINT "Billing Type : ", 	COLUMN 20, "Time AND Materials - Recurring" 
			END CASE 

			# "Activity Details"
			DECLARE act_curs CURSOR FOR 
			SELECT activity.* 
			FROM activity 
			WHERE cmpy_code = modu_rec_job.cmpy_code 
			AND job_code = modu_rec_job.job_code 

			LET job_this_bill_amt = 0 
			LET job_fcst_bill_amt = 0 
			LET job_act_bill_amt = 0 
			LET modu_job_this_bill_qty = 0 
			LET job_fcst_bill_qty = 0 
			LET job_act_bill_qty = 0 
			LET job_this_cos_amt = 0 
			LET job_fcst_cos_amt = 0 
			LET job_act_cos_amt = 0 

			FOREACH act_curs INTO pr_activity.* 

				# Check IF the current activity has transactions
				SELECT count(*) INTO num_trans 
				FROM jobledger 
				WHERE cmpy_code = pr_activity.cmpy_code 
				AND job_code = pr_activity.job_code 
				AND var_code = pr_activity.var_code 
				AND activity_code = pr_activity.activity_code 

				# Only PRINT the activities with transaction
				IF NOT pr_zero_tran_ind AND num_trans = 0 THEN 
				ELSE 
					LET job_act_bill_amt = job_act_bill_amt + pr_activity.act_bill_amt 
					LET job_act_bill_qty = job_act_bill_qty + pr_activity.act_bill_qty 
					LET job_act_cos_amt = job_act_cos_amt + pr_activity.post_cost_amt 
					CALL get_bill() RETURNING this_bill_amt, 
					this_bill_qty, 
					this_cos_amt 
					LET job_this_bill_amt = job_this_bill_amt + this_bill_amt 
					LET modu_job_this_bill_qty = modu_job_this_bill_qty + this_bill_qty 
					LET job_this_cos_amt = job_this_cos_amt + this_cos_amt 
					#Exclude the activities with 00.00 invoice amount in activity section
					IF pr_zero_inv_ind AND (this_cos_amt = 0 AND this_bill_qty = 0 AND this_bill_amt = 0) THEN 
					ELSE 
						PRINT 
						PRINT "----------------------------------------", 
						"----------------------------------------", 
						"-----------------------------" 
						PRINT "Activity : ", pr_activity.activity_code," ", 
						"Description : ", pr_activity.title_text, 
						"Variation : ", pr_activity.var_code USING "-------", 
						" % Complete : ", pr_activity.est_comp_per USING "------.---" 
						PRINT 
						PRINT " : : Total : ", 
						" Billed : : " 
						PRINT " :--- Estimate ---:--- TO Date ----:-", 
						"-- TO Date ---:- This Invoice -:--- Proposed --" 
						PRINT "Costs.........:", 
						COLUMN 17, pr_activity.est_cost_amt USING "-----------.--", 
						COLUMN 32, ": ", pr_activity.act_cost_amt 
						USING "-----------.--", 
						COLUMN 49, ": ", pr_activity.post_cost_amt 
						USING "-----------.--", 
						COLUMN 65, ": ", this_cos_amt USING "-----------.--", 
						COLUMN 82, ":_______________" 
						PRINT "Charges.......: ", 
						COLUMN 17, pr_activity.est_bill_amt USING "-----------.--", 
						COLUMN 32, ": ", pr_activity.post_revenue_amt 
						USING "-----------.--", 
						COLUMN 49, ": ", pr_activity.act_bill_amt 
						USING "-----------.--", 
						COLUMN 65, ": ", this_bill_amt USING "-----------.--", 
						COLUMN 82, ":_______________" 
						PRINT "Usage..... ", pr_activity.unit_code, ": ", 
						COLUMN 17, pr_activity.est_cost_qty USING "-----------.--", 
						COLUMN 32, ": ", pr_activity.act_cost_qty 
						USING "-----------.--", 
						COLUMN 49, ": ", pr_activity.act_bill_qty 
						USING "-----------.--", 
						COLUMN 65, ": ", this_bill_qty USING "-----------.--", 
						COLUMN 82, ":_______________" 

						#   PRINT "Billing.......: ",
						#      COLUMN 17, pr_activity.est_bill_qty using "-----------.--",
						#   PRINT "Accumulated Charges :",
						#   PRINT "Cost of Sales.: (- NOT used -)",


						PRINT 
						PRINT "----------------------------------------------", 
						" TRANSACTIONS --------------------------------------------" 
						PRINT "Date Type No. Resource By Cost Amount ", 
						" Charge Amt Quantity Posted " 
						#        COLUMN 101, "\"Charge Amount\""

						DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
						DISPLAY "see jm/J34.4gl" 
						EXIT program (1) 


						# modify this CURSOR TO include the initial of consultant
						LET str = 
						" SELECT distinct JL.*, TH.person_code ", 
						" INTO pr_jobledger.*, pv_person_code ", 
						" FROM jobledger JL, OUTER (ts_detail TD, ts_head TH) ", 
						" WHERE JL.cmpy_code = ", pr_activity.cmpy_code, 
						" AND JL.job_code = ", pr_activity.job_code, 
						" AND JL.var_code = ", pr_activity.var_code, 
						" AND JL.activity_code = ", pr_activity.activity_code, 
						" AND TD.cmpy_code = ", pr_activity.cmpy_code, 
						" AND TD.job_code = ", pr_activity.job_code, 
						" AND TD.var_code = ", pr_activity.var_code, 
						" AND TD.activity_code = ", pr_activity.activity_code, 
						" AND JL.trans_source_num = TD.ts_num ", 
						" AND TH.ts_num = TD.ts_num ", 
						" AND TH.cmpy_code = ", pr_activity.cmpy_code, 
						" ORDER BY trans_source_text, trans_date " 



						PREPARE ert FROM str 
						DECLARE ledg_curs CURSOR FOR ert 

						LET acti_cost_amt_tot = 0 
						LET acti_cost_qty_tot = 0 
						LET acti_charge_amt_tot = 0 

						FOREACH ledg_curs 
							IF pr_jobledger.trans_amt IS NOT NULL THEN 
								LET acti_cost_amt_tot = acti_cost_amt_tot 
								+ pr_jobledger.trans_amt 
							END IF 
							IF pr_jobledger.trans_qty IS NOT NULL THEN 
								LET acti_cost_qty_tot = acti_cost_qty_tot 
								+ pr_jobledger.trans_qty 
							END IF 
							IF pr_jobledger.charge_amt IS NOT NULL THEN 
								LET acti_charge_amt_tot = acti_charge_amt_tot 
								+ pr_jobledger.charge_amt 
							END IF 

							PRINT pr_jobledger.trans_date USING "dd/mm/yy", 
							COLUMN 10, pr_jobledger.trans_type_ind, 
							COLUMN 15, pr_jobledger.trans_source_num USING "--------", 
							COLUMN 28, pr_jobledger.trans_source_text, 
							COLUMN 39, pv_person_code clipped, 
							COLUMN 45, pr_jobledger.trans_amt USING "--------.--", 
							COLUMN 65, pr_jobledger.charge_amt USING "--------.--", 
							COLUMN 80, pr_jobledger.trans_qty USING "--------.--", 
							COLUMN 95, pr_jobledger.posted_flag 
							PRINT COLUMN 10, "Description : ", pr_jobledger.desc_text clipped 
						END FOREACH 

						PRINT COLUMN 48, "-----------", 
						COLUMN 68, "-----------", 
						COLUMN 83, "-----------" 
						PRINT COLUMN 45, acti_cost_amt_tot USING "--------.--", 
						COLUMN 65, acti_charge_amt_tot USING "--------.--", 
						COLUMN 80, acti_cost_qty_tot USING "--------.--" 
					END IF 
				END IF 
			END FOREACH 

			# changed calculation of forecast amount
			LET job_fcst_bill_amt = job_this_bill_amt + job_act_bill_amt 
			IF modu_rec_job.bill_way_ind = "R" THEN 
				LET job_fcst_bill_qty = modu_job_this_bill_qty 
			ELSE 
				LET job_fcst_bill_qty = modu_job_this_bill_qty + job_act_bill_qty 
			END IF 
			LET job_fcst_cos_amt = job_this_cos_amt + job_act_cos_amt 


			PRINT "----------------------------------------", 
			"----------------------------------------", 
			"-------------------" 
			PRINT COLUMN 45, "JOB SUMMARY" 
			PRINT " TO Date This Invoice Forecast" 
			PRINT "Billing .........", job_act_bill_amt USING "---------.--", 
			COLUMN 35, job_this_bill_amt USING "---------.--", 
			COLUMN 54, job_fcst_bill_amt USING "---------.--" 
			PRINT "Quantities.......", job_act_bill_qty USING "---------.--", 
			COLUMN 35, modu_job_this_bill_qty USING "---------.--", 
			COLUMN 54, job_fcst_bill_qty USING "---------.--" 
			PRINT "Cost Of Sales....", job_act_cos_amt USING "---------.--", 
			COLUMN 35, job_this_cos_amt USING "---------.--", 
			COLUMN 54, job_fcst_cos_amt USING "---------.--" 

			# Calculate the total value FOR "All Jobs summary" section
			LET modu_tot_job_act_bill_amt = modu_tot_job_act_bill_amt + job_act_bill_amt 
			LET modu_tot_job_this_bill_amt = modu_tot_job_this_bill_amt + job_this_bill_amt 
			LET modu_tot_job_fcst_bill_amt = modu_tot_job_fcst_bill_amt + job_fcst_bill_amt 
			LET modu_tot_job_act_bill_qty = modu_tot_job_act_bill_qty + job_act_bill_qty 
			LET modu_tot_job_this_bill_qty = modu_tot_job_this_bill_qty + modu_job_this_bill_qty 
			LET modu_tot_job_fcst_bill_qty = modu_tot_job_fcst_bill_qty + job_fcst_bill_qty 
			LET modu_tot_job_act_cos_amt = modu_tot_job_act_cos_amt + job_act_cos_amt 
			LET modu_tot_job_this_cos_amt = modu_tot_job_this_cos_amt + job_this_cos_amt 
			LET modu_tot_job_fcst_cos_amt = modu_tot_job_fcst_cos_amt + job_fcst_cos_amt 

			LET job_this_bill_amt = 0 
			LET job_fcst_bill_amt = 0 
			LET job_act_bill_amt = 0 
			LET modu_job_this_bill_qty = 0 
			LET job_fcst_bill_qty = 0 
			LET job_act_bill_qty = 0 
			LET job_this_cos_amt = 0 
			LET job_fcst_cos_amt = 0 
			LET job_act_cos_amt = 0 

		ON LAST ROW 
			SKIP 1 line 


			PRINT 
			"----------------------------------------", 
			"----------------------------------------", 
			"-------------------" 
			PRINT COLUMN 45, "REPORT SUMMARY" 
			PRINT " TO Date Total Invoices Total Forecasted" 
			PRINT "Total Billing .........", modu_tot_job_act_bill_amt USING "---------.--", 
			COLUMN 35, modu_tot_job_this_bill_amt USING "---------.--", 
			COLUMN 54, modu_tot_job_fcst_bill_amt USING "---------.--" 
			PRINT "Total Quantities.......", modu_tot_job_act_bill_qty USING "---------.--", 
			COLUMN 35, modu_tot_job_this_bill_qty USING "---------.--", 
			COLUMN 54, modu_tot_job_fcst_bill_qty USING "---------.--" 
			PRINT "Total Cost Of Sales....", modu_tot_job_act_cos_amt USING "---------.--", 
			COLUMN 35, modu_tot_job_this_cos_amt USING "---------.--", 
			COLUMN 54, modu_tot_job_fcst_cos_amt USING "---------.--" 

			LET modu_tot_job_this_bill_amt = 0 
			LET modu_tot_job_fcst_bill_amt = 0 
			LET modu_tot_job_act_bill_amt = 0 
			LET modu_tot_job_this_bill_qty = 0 
			LET modu_tot_job_fcst_bill_qty = 0 
			LET modu_tot_job_act_bill_qty = 0 
			LET modu_tot_job_this_cos_amt = 0 
			LET modu_tot_job_fcst_cos_amt = 0 
			LET modu_tot_job_act_cos_amt = 0 
			LET modu_job_this_bill_qty = 0 

			SKIP 1 line 

			IF pr_zero_job_ind THEN 
				LET pr_option1 = "All selected jobs" 
			ELSE 
				LET pr_option1 = "All active jobs" 
			END IF 

			IF pr_zero_tran_ind THEN 
				LET pr_option2 = "All activities" 
			ELSE 
				LET pr_option2 = "Exclude no transaction activities" 
			END IF 

			IF pr_zero_inv_ind THEN 
				LET pr_option3 = "Exclude OPEN jobs with 00.00 invoice amount" 
			ELSE 
				LET pr_option3 = "Print OPEN jobs with 00.00 invoice amount" 
			END IF 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				PRINT COLUMN 25, pr_option1 clipped 
				PRINT COLUMN 25, pr_option2 clipped 
				PRINT COLUMN 25, pr_option3 clipped 

			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			

END REPORT 
###########################################################################
# END REPORT J34_rpt_list(p_rpt_idx,modu_rec_job, cust_name)
###########################################################################