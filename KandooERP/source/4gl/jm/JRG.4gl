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
# \brief module JRG.4gl Alternate Pre-invoice REPORT
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	formname CHAR(15), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_menunames RECORD LIKE menunames.*, 
	pr_job RECORD LIKE job.*, 
	pr_company RECORD LIKE company.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	ans CHAR(1), 
	where_part, query_text CHAR(3400), 

	pr_jobtype RECORD LIKE jobtype.*, 
	where_text_2 CHAR(800), 

	err_message CHAR(40), 
	this_bill_amt, 
	chg_cos_amt, 
	job_est_cos_amt, 
	job_est_bill_amt, 
	job_act_cos_amt, 
	job_act_bill_amt, 
	job_this_bill_amt, 
	job_to_bill_amt LIKE activity.act_bill_amt, 
	job_markup_per LIKE job.markup_per, 
	pv_completed CHAR(1), 
	pv_rep_type CHAR(1), 
	pv_pagebreak CHAR(1), 
	err_flag, idx, scrn, cnt SMALLINT 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JRG") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code,	pr_user_scan_code 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND	jmparms.key_code = "1" 
	IF status = notfound THEN 		
		LET msgresp = kandoomsg("J",1501," ") #ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 
	
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	CLEAR screen 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW J303 with FORM "J303" -- alch kd-747 
			CALL winDecoration_j("J303") -- alch kd-747 
		
			MENU " Pre Invoice Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","JRG","menu-pre_invoice_rep-1") -- alch kd-506 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRG_rpt_process(JRG_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" --COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL) 
					CALL JRG_rpt_process(JRG_rpt_query())
		
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Menu"		# Exit the program
					EXIT MENU 
			END MENU
			 
			CLOSE WINDOW J303 
			CLEAR screen 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL JRG_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW J303 with FORM "J303" 
			CALL winDecoration_j("J303") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(JRG_rpt_query()) #save where clause in env 
			CLOSE WINDOW J303 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL JRG_rpt_process(get_url_sel_text())
	END CASE 			
END MAIN 


FUNCTION JRG_rpt_query() 
	DEFINE l_where_text STRING

	
	LET msgresp = kandoomsg("U",1001," ") #   MESSAGE " Enter selection criteria - ESC Continue " attribute (yellow) 
	CONSTRUCT BY NAME l_where_text ON 
	job.job_code, 
	job.resp_code, 
	job.type_code, 
	job.est_start_date, 
	job.est_end_date, 
	job.cust_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JRG","const-job_job_code-8") -- alch kd-506
 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	END IF 

	LET pv_rep_type = "F" 
	LET pv_completed = "N" 
	LET pv_pagebreak = "Y" 

	INPUT pv_rep_type,pv_completed, pv_pagebreak WITHOUT DEFAULTS 
	FROM formonly.rep_type,formonly.completed, formonly.pagebreak 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JRG","input-pv_rep_type-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 


	IF int_flag OR quit_flag THEN
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"	 
		RETURN NULL
	ELSE

		LET glob_rec_rpt_selector.ref1_ind = pv_rep_type #= "F" 
		LET glob_rec_rpt_selector.ref2_ind = pv_completed #= "N" 
		LET glob_rec_rpt_selector.ref3_ind = pv_pagebreak #= "Y"
		
		RETURN l_where_text
	END IF 
END FUNCTION


FUNCTION JRG_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	fv_cnt SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_char CHAR(8), 
	fv_num INTEGER 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JRG_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JRG_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JRG_rpt_list")].sel_text
	#------------------------------------------------------------
	LET pv_rep_type = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	LET pv_completed = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_ind
	LET pv_pagebreak = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_ind
	#------------------------------------------------------------

	LET query_text = 
	"SELECT * ", 
	" FROM job WHERE ", 
	" job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", where_part clipped, 
	" AND (job.acct_code matches \"",pr_user_scan_code,"\"", 
	" OR locked_ind = \"1\" )" 

	IF pv_completed = "Y" THEN 
		LET query_text = query_text clipped, 
		" ORDER BY job_code " 
	ELSE 
		LET query_text = query_text clipped, 
		" AND act_end_date IS NULL ", 
		" AND locked_ind > \"0\"", 
		" ORDER BY job_code " 
	END IF 

	IF int_flag OR quit_flag THEN 		
		LET msgresp = kandoomsg("U",9501," ") #MESSAGE " Query aborted"
		RETURN 
	END IF 


	PREPARE q_1 FROM query_text 
	DECLARE c_1 CURSOR FOR q_1 
	FOREACH c_1 INTO pr_job.*, pr_customer.*
		#---------------------------------------------------------
		OUTPUT TO REPORT JRG_rpt_list(l_rpt_idx,
		pr_job.*, pv_pagebreak, fv_char, fv_num)   
		IF NOT rpt_int_flag_handler2("Job:",pr_job.title_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
	END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT JRG_rpt_list
	CALL rpt_finish("JRG_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



FUNCTION get_bill(fv_markup_pct) 
	DEFINE 
	fv_markup_pct LIKE job.markup_per, 
	fr_jobledger RECORD LIKE jobledger.*, 
	fv_inv_cnt SMALLINT, 
	this_bill_amt LIKE activity.act_bill_amt 

	LET this_bill_amt = 0 

	IF pr_activity.bill_way_ind = "C" 
	THEN 
		         {LET this_bill_amt = ( pr_activity.act_cost_amt *
		                               (1 + (fv_markup_pct / 100)))
		                                - pr_activity.act_bill_amt
		                                }


		DECLARE jl_curs CURSOR FOR 

		SELECT * FROM jobledger 
		WHERE cmpy_code = pr_activity.cmpy_code 
		AND job_code = pr_activity.job_code 
		AND activity_code = pr_activity.activity_code 

		FOREACH jl_curs INTO fr_jobledger.* 

			LET fv_inv_cnt = 0 

			SELECT count(*) INTO fv_inv_cnt 
			FROM resbill 
			WHERE cmpy_code = fr_jobledger.cmpy_code 
			AND job_code = fr_jobledger.job_code 
			AND var_code = fr_jobledger.var_code 
			AND activity_code = fr_jobledger.activity_code 
			AND seq_num = fr_jobledger.seq_num 

			IF fv_inv_cnt > 0 
			THEN 

				CONTINUE FOREACH 

			ELSE 

				LET this_bill_amt = this_bill_amt + 
				fr_jobledger.trans_amt * 
				(1 + fv_markup_pct / 100) 


			END IF 

		END FOREACH 

	ELSE 

		CASE pr_activity.bill_way_ind 

			WHEN "T" 

				LET this_bill_amt = pr_activity.post_revenue_amt 
				- pr_activity.act_bill_amt 
			WHEN "R" 
				LET this_bill_amt = pr_activity.post_revenue_amt 
				- pr_activity.act_bill_amt 
			WHEN "F" 
				IF pr_activity.est_comp_per = 0 THEN 
					RETURN 0 
				ELSE 
					return((pr_activity.est_comp_per * 
					pr_activity.est_bill_amt /100) - 
					pr_activity.act_bill_amt) 
				END IF 
			OTHERWISE 
				LET this_bill_amt = 0 
		END CASE 

	END IF 

	RETURN this_bill_amt 

END FUNCTION

REPORT JRG_rpt_list(p_rpt_idx,rr_job, rv_pagebreak, rv_char, rv_num) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rr_job RECORD LIKE job.*, 
	rv_pagebreak CHAR(1), 
	rv_char CHAR(8), 
	rv_num INTEGER, 
	rr_customer RECORD LIKE customer.*, 
	rr_jobtype RECORD LIKE jobtype.*, 
	rr_jobledger RECORD LIKE jobledger.*, 
	line1, line2 CHAR(132), 
	fv_invoiced , 
	ati_cost_amt , 
	ati_invd_amt , 
	ati_bill_amt LIKE activity.act_bill_amt, 
	offset1, offset2 SMALLINT, 
	rv_xfer_amt LIKE jobledger.trans_amt, 
	rv_cost_amt LIKE jobledger.trans_amt, 
	rv_bal_amt LIKE jobledger.trans_amt 

	OUTPUT 

	ORDER BY rv_char, rv_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			IF rpt_note IS NULL THEN 
				IF pv_rep_type = "S" THEN 
					LET rpt_note = "Pre Invoice Report - Summary (Menu JRG)" 
				ELSE 
					LET rpt_note = "Pre Invoice Report - Full (Menu JRG)" 
				END IF 
			END IF 

			IF pv_completed = "Y" THEN 
				LET line2 = rpt_note clipped, " (including Completed Jobs)" 
			ELSE 
				LET line2 = rpt_note clipped 
			END IF 


		ON EVERY ROW 

			IF rv_pagebreak = "Y" 
			THEN 

				SKIP TO top OF PAGE 

			ELSE 

				SKIP 3 LINES 

			END IF 

			SELECT * 
			INTO rr_customer.* 
			FROM customer 
			WHERE cmpy_code = rr_job.cmpy_code 
			AND cust_code = rr_job.cust_code 

			SELECT * 
			INTO rr_jobtype.* 
			FROM jobtype 
			WHERE cmpy_code = rr_job.cmpy_code 
			AND type_code = rr_job.type_code 

			PRINT COLUMN 6, "Job Type: ", rr_job.type_code, 
			COLUMN 30, ": ", rr_jobtype.type_text, 
			COLUMN 65, "Billing Method : ", rr_job.bill_way_ind; 

			CASE rr_job.bill_way_ind 
				WHEN "C" 
					PRINT COLUMN 84, "Cost Plus" 
				WHEN "F" 
					PRINT COLUMN 84, "Fixed Price" 
				WHEN "T" 
					PRINT COLUMN 84, "Time AND Materials" 
				WHEN "R" 
					PRINT COLUMN 84, "Time AND Materials - Recurring" 
			END CASE 

			PRINT COLUMN 4, "Job Number: ",rr_job.job_code, 
			COLUMN 30, ": ", rr_job.title_text 

			PRINT "Customer Code: ", rr_job.cust_code, 
			COLUMN 30, ": ", rr_customer.name_text, 
			COLUMN 65, "Address :", rr_customer.addr1_text 
			PRINT COLUMN 73, ":", rr_customer.addr2_text 
			PRINT COLUMN 73, ":", rr_customer.city_text 

			PRINT "Est start date : ", rr_job.est_start_date, 
			COLUMN 30, "Est END date : ", rr_job.est_end_date, 
			COLUMN 65, rr_job.est_comp_per USING "<<&", "% complete"; 

			IF rr_job.internal_flag = "Y" THEN 
				PRINT COLUMN 100, "Internal Job" 
			ELSE 
				PRINT COLUMN 100, "External Job" 
			END IF 

			PRINT "Act start date : ", rr_job.act_start_date, 
			COLUMN 30, "Act END date : ", rr_job.act_end_date, 
			COLUMN 65, rr_job.resp_code clipped, 
			COLUMN 100, "Markup ", rr_job.markup_per USING "<<<&.&&%" 

			SKIP 1 line 

			# PRINT "Activity Details"
			LET job_est_cos_amt = 0 
			LET job_est_bill_amt = 0 
			LET job_act_cos_amt = 0 
			LET job_act_bill_amt = 0 
			LET job_this_bill_amt = 0 
			LET job_to_bill_amt = 0 

			#   PRINT "Activity                      Resp      Est. Cost   ",
			PRINT "Activity Bill Cost Est %" 
			PRINT "Code Ind. Flag Comp. Resp Est. Cost ", 
			#       "Budget Charge    Actual Cost  Actual Charge      Invoiced",
			" Est. Charge Actual Cost Charge / COS Invoiced", 
			" TO be Invoiced" 

			DECLARE act_curs CURSOR FOR 
			SELECT activity.* 
			FROM activity 
			WHERE cmpy_code = rr_job.cmpy_code 
			AND job_code = rr_job.job_code 

			FOREACH act_curs INTO pr_activity.* 

				CALL get_bill(rr_job.markup_per) RETURNING this_bill_amt 


				IF pr_activity.bill_way_ind = "F" THEN 
					LET chg_cos_amt = pr_activity.post_cost_amt 
				ELSE 
					LET chg_cos_amt = pr_activity.act_bill_amt + this_bill_amt 
				END IF 


				#      PRINT pr_activity.title_text clipped,
				PRINT pr_activity.activity_code, 
				COLUMN 12, pr_activity.bill_way_ind, 
				COLUMN 19, pr_activity.cost_alloc_flag, 
				COLUMN 24, pr_activity.est_comp_per USING "<<&", "%", 
				COLUMN 32, pr_activity.resp_code clipped, 
				COLUMN 40, pr_activity.est_cost_amt USING "----------&.&&", 
				COLUMN 55, pr_activity.est_bill_amt USING "----------&.&&", 
				COLUMN 70, pr_activity.act_cost_amt USING "----------&.&&", 
				#        COLUMN 85, (pr_activity.act_bill_amt + this_bill_amt) using "------&.&&",
				COLUMN 85, chg_cos_amt USING "----------&.&&", 
				COLUMN 100, pr_activity.act_bill_amt USING "----------&.&&", 
				COLUMN 115, this_bill_amt USING "----------&.&&" 

				LET job_est_cos_amt = job_est_cos_amt + pr_activity.est_cost_amt 
				LET job_est_bill_amt = job_est_bill_amt + pr_activity.est_bill_amt 
				LET job_act_cos_amt = job_act_cos_amt + pr_activity.act_cost_amt 
				#       LET job_act_bill_amt = job_act_bill_amt + pr_activity.act_bill_amt
				#                                               + this_bill_amt
				LET job_act_bill_amt = job_act_bill_amt + chg_cos_amt 
				LET job_this_bill_amt = job_this_bill_amt + pr_activity.act_bill_amt 
				LET job_to_bill_amt = job_to_bill_amt + this_bill_amt 

			END FOREACH 

			SKIP 1 line 
			PRINT "Totals", 
			COLUMN 40, job_est_cos_amt USING "----------&.&&", 
			COLUMN 55, job_est_bill_amt USING "----------&.&&", 
			COLUMN 70, job_act_cos_amt USING "----------&.&&", 
			COLUMN 85, job_act_bill_amt USING "----------&.&&", 
			COLUMN 100, job_this_bill_amt USING "----------&.&&", 
			COLUMN 115, job_to_bill_amt USING "----------&.&&" 

			SKIP 1 line 

			LET rv_xfer_amt = 0 
			LET rv_bal_amt = 0 

			SELECT sum(trans_amt) INTO rv_xfer_amt 
			FROM jobledger 
			WHERE cmpy_code = rr_job.cmpy_code 
			AND job_code = rr_job.job_code 
			AND trans_type_ind = "CT" 

			IF rv_xfer_amt <> 0 THEN 
				LET rv_bal_amt = job_to_bill_amt - (rv_xfer_amt * -1) 
				LET rv_cost_amt = job_act_cos_amt - (rv_xfer_amt * -1) 

				PRINT COLUMN 45, "Previously Transferred:", 
				COLUMN 70, rv_xfer_amt USING "((((((((((&.&&)", 
				##            COLUMN 92, "Previously Transferred:",
				COLUMN 115, rv_xfer_amt USING "((((((((((&.&&)" 

				PRINT COLUMN 50, "Balance of Costs:", 
				COLUMN 70, rv_cost_amt USING "((((((((((&.&&)", 
				COLUMN 105, "Balance:", 
				COLUMN 115, rv_bal_amt USING "((((((((((&.&&)" 
			END IF 

			SKIP 1 line 


			IF pv_rep_type != "S" THEN 

				PRINT "TRANSACTIONS ----------------------------------------" 
				PRINT " Date Activity Type Ref Trans No. Description ", 
				" ", 
				" Quantity Cost Charge Amt Invoiced" 

				LET ati_cost_amt = 0 
				LET ati_bill_amt = 0 
				LET ati_invd_amt = 0 

				DECLARE ledg_curs CURSOR FOR 
				SELECT * 
				INTO rr_jobledger.* 
				FROM jobledger 
				WHERE cmpy_code = rr_job.cmpy_code 
				AND job_code = rr_job.job_code 
				AND trans_type_ind != "CT" 
				ORDER BY trans_date , trans_source_text 
				FOREACH ledg_curs 

					IF rr_jobledger.trans_type_ind = "TS" THEN 

						SELECT person_code 
						INTO rr_jobledger.trans_source_text 
						FROM ts_head 
						WHERE cmpy_code = rr_job.cmpy_code 
						AND ts_num = rr_jobledger.trans_source_num 

						IF status = 0 THEN 
							SELECT name_text 
							INTO rr_jobledger.desc_text 
							FROM person 
							WHERE cmpy_code = rr_job.cmpy_code 
							AND person_code = rr_jobledger.trans_source_text 
						END IF 

					END IF 

					IF rr_jobledger.trans_type_ind = "VO" THEN 

						SELECT vend_code 
						INTO rr_jobledger.trans_source_text 
						FROM voucher 
						WHERE cmpy_code = rr_job.cmpy_code 
						AND vouch_code = rr_jobledger.trans_source_num 

					END IF 

					IF rr_jobledger.trans_type_ind = "IS" THEN 

						LET rr_jobledger.trans_source_text = rr_jobledger.desc_text[1,15] clipped 
						SELECT product.desc_text 
						INTO rr_jobledger.desc_text 
						FROM product 
						WHERE cmpy_code = rr_job.cmpy_code 
						AND part_code = rr_jobledger.trans_source_text 

					END IF 

					IF rr_jobledger.activity_code != pr_activity.activity_code THEN 

						SELECT * 
						INTO pr_activity.* 
						FROM activity 
						WHERE cmpy_code = rr_jobledger.cmpy_code 
						AND job_code = rr_jobledger.job_code 
						AND var_code = rr_jobledger.var_code 
						AND activity_code = rr_jobledger.activity_code 

					END IF 
					IF pr_activity.bill_way_ind = "C" THEN 
						LET rr_jobledger.charge_amt = ( rr_jobledger.trans_amt * 
						(1 + (rr_job.markup_per / 100))) 

					END IF 

					PRINT rr_jobledger.trans_date USING "dd/mm/yy", 
					COLUMN 10, rr_jobledger.activity_code clipped, 
					COLUMN 19, rr_jobledger.trans_type_ind, 
					COLUMN 24, rr_jobledger.trans_source_text, 
					COLUMN 35, rr_jobledger.trans_source_num USING "--------", 
					COLUMN 45, rr_jobledger.desc_text clipped, 
					COLUMN 80, rr_jobledger.trans_qty USING "------.--", 
					COLUMN 92, rr_jobledger.trans_amt USING "--------.--"; 

					LET ati_cost_amt = ati_cost_amt + rr_jobledger.trans_amt 

					IF pr_activity.bill_way_ind != "F" THEN 

						SELECT sum(apply_amt) 
						INTO fv_invoiced 
						FROM resbill 
						WHERE cmpy_code = rr_jobledger.cmpy_code 
						AND job_code = rr_jobledger.job_code 
						AND var_code = rr_jobledger.var_code 
						AND activity_code = rr_jobledger.activity_code 
						AND seq_num = rr_jobledger.seq_num 

						IF fv_invoiced IS NULL THEN 
							LET fv_invoiced = 0 
						END IF 

						PRINT COLUMN 104, rr_jobledger.charge_amt USING "--------.--", 
						COLUMN 116, fv_invoiced USING "--------.--" 

						LET ati_bill_amt = ati_bill_amt + rr_jobledger.charge_amt 
						LET ati_invd_amt = ati_invd_amt + fv_invoiced 
					ELSE 
						PRINT 
					END IF 

				END FOREACH 

				PRINT COLUMN 92, "-----------", 
				COLUMN 104, "-----------", 
				COLUMN 116, "-----------" 
				PRINT COLUMN 92, ati_cost_amt USING "--------.--", 
				COLUMN 104, ati_bill_amt USING "--------.--", 
				COLUMN 116, ati_invd_amt USING "--------.--" 
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
