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
GLOBALS "../jm/J7_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J7A_GLOBALS.4gl"

GLOBALS 

	DEFINE formname CHAR(15) 
	#DEFINE       err_message     CHAR(40)
	#DEFINE       err_continue    CHAR(1)
	DEFINE filename CHAR(50) 
	DEFINE pv_output CHAR(60) 
	DEFINE pv_output1 CHAR(60) 
	DEFINE err_rpt SMALLINT 
	DEFINE row_err SMALLINT 
	DEFINE pv_pageno SMALLINT 
	DEFINE pv_pageno1 SMALLINT 
	DEFINE old_trans_date DATE 
	DEFINE pr_jmparms RECORD LIKE jmparms.* 
	#DEFINE       pr_jmresource  RECORD LIKE jmresource.*
	DEFINE pr_jobledger RECORD LIKE jobledger.* 
	DEFINE pr_activity RECORD LIKE activity.* 
	DEFINE pr_kandooreport1 RECORD LIKE kandooreport.* 
	DEFINE pr_menunames RECORD LIKE menunames.* 
	DEFINE pr_load_res_all RECORD 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		job_code LIKE jobledger.job_code, 
		trans_date LIKE jobledger.trans_date, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		desc_text LIKE jobledger.desc_text, 
		activity_code LIKE jobledger.activity_code, 
		var_code LIKE jobledger.var_code, 
		allocation_ind LIKE jobledger.allocation_ind, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		trans_source_num LIKE jobledger.trans_source_num 
	END RECORD 
	DEFINE pr_lines RECORD 
		line1_text CHAR(132), 
		line2_text CHAR(132), 
		line3_text CHAR(132), 
		line4_text CHAR(132), 
		line5_text CHAR(132), 
		line6_text CHAR(132), 
		line7_text CHAR(132), 
		line8_text CHAR(132), 
		line9_text CHAR(132), 
		line10_text CHAR(132) 
	END RECORD 

END GLOBALS 

###########################################################################
# MAIN
#
# Purpose - Allows the user TO create resource allocations loaded FROM
#           external ascii files.
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("J7A") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7505,"") 
		# DISPLAY "Job Management parameters are NOT SET up - Refer menu JZP"
		EXIT program 
	END IF 

	CREATE temp TABLE load_res_all 
	(trans_qty FLOAT, 
	unit_cost_amt DECIMAL(12,4), 
	job_code CHAR(12), 
	trans_date DATE, 
	unit_bill_amt DECIMAL(12,4), 
	desc_text CHAR(40), 
	activity_code CHAR(8), 
	var_code SMALLINT, 
	allocation_ind CHAR(1)) 
	with no LOG 

	OPEN WINDOW wj201 with FORM "J201" -- alch kd-747 
	CALL winDecoration_j("J201") -- alch kd-747 

	MENU "Resource Allocation Load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J7A","menu-resource_alloc_load-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Load" " Load Details" 
			IF load_details() THEN 
				NEXT option "Print Manager" 
			ELSE 
				NEXT option "Exit" 
			END IF 

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E") "Exit" "RETURN TO Menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW wj201 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION load_details()
#
# 
###########################################################################
FUNCTION load_details() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	MESSAGE " ESC TO Accept - DEL TO Exit" 
	attribute (yellow) 
	DISPLAY "" at 2,1 

	INITIALIZE pr_jmresource, filename TO NULL 

	INPUT BY NAME pr_jmresource.res_code, filename 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7A","input-pr_jmresource-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield (res_code) THEN 
				LET pr_jmresource.res_code = show_res(glob_rec_kandoouser.cmpy_code) 

				SELECT desc_text 
				INTO pr_jmresource.desc_text 
				FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jmresource.res_code 

				DISPLAY BY NAME pr_jmresource.desc_text 

				NEXT FIELD res_code 
			END IF 

		AFTER FIELD res_code 
			IF pr_jmresource.res_code IS NULL THEN 
				ERROR " Resource code must be entered" 
				NEXT FIELD res_code 
			END IF 

			SELECT * 
			INTO pr_jmresource.* 
			FROM jmresource 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_jmresource.res_code 

			IF status = notfound THEN 
				ERROR " Resource code does NOT exist - Try Window" 
				NEXT FIELD res_code 
			END IF 

			DISPLAY BY NAME pr_jmresource.desc_text 


		AFTER FIELD filename 
			IF filename IS NULL THEN 
				ERROR " A file name must be entered" 
				NEXT FIELD filename 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF filename IS NULL THEN 
				ERROR " A file name must be entered" 
				NEXT FIELD filename 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLEAR FORM 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	MESSAGE " Please wait WHILE loading data FROM file ..." 
	attribute (yellow) 

	WHENEVER ERROR CONTINUE 

	LOAD FROM filename 
	INSERT INTO load_res_all 

	WHENEVER ERROR stop 

	IF status != 0 THEN 
		MESSAGE "" 
		ERROR " Problem loading data FROM specified file - Data NOT loaded" 
		CLEAR FORM 
		RETURN false 
	END IF 

	MESSAGE " Adding transactions now - please wait" 
	attribute (yellow) 

	LET err_rpt = false 
	LET old_trans_date = "01/01/1960" # old DATE that will change 
	# with the first record


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("J7A-SUC","J7A_rpt_list_post_suc","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J7A_rpt_list_post_suc TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("J7A_rpt_list_post_suc")].sel_text
	#------------------------------------------------------------


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("J7A-ERR","J7A_rpt_list_post_err","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J7A_rpt_list_post_err TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("J7A_rpt_list_post_err")].sel_text
	#------------------------------------------------------------

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 

	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		DECLARE loadcurs CURSOR FOR 
		SELECT * 
		INTO pr_load_res_all.* 
		FROM load_res_all 
		ORDER BY trans_date, job_code, activity_code, var_code 

		FOREACH loadcurs 
			LET row_err = false 

			SELECT year_num, period_num 
			INTO pr_jobledger.year_num, pr_jobledger.period_num 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_date <= pr_load_res_all.trans_date 
			AND end_date >= pr_load_res_all.trans_date 

			IF status = notfound THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Year AND period NOT SET up FOR transaction date") 
				#---------------------------------------------------------
			ELSE 
				SELECT year_num 
				FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = pr_jobledger.year_num 
				AND period_num = pr_jobledger.period_num 
				AND jm_flag = "Y" 

				IF status = notfound THEN 
					LET err_rpt = true 
					LET row_err = true 
					#---------------------------------------------------------
					OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
					pr_load_res_all.*, 
						"Year AND period NOT OPEN FOR job management")
					#---------------------------------------------------------
				END IF 
			END IF 

			SELECT job_code 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_load_res_all.job_code 

			IF status = notfound THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Job code IS NULL OR does NOT exist") 
				#---------------------------------------------------------
			END IF 

			IF pr_load_res_all.var_code IS NULL 
			OR pr_load_res_all.var_code != 0 THEN 
				SELECT var_code 
				FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_load_res_all.job_code 
				AND var_code = pr_load_res_all.var_code 

				IF status = notfound THEN 
					LET err_rpt = true 
					LET row_err = true 
					#---------------------------------------------------------
					OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
					pr_load_res_all.*, 
					"Variation code IS NULL OR does NOT exist") 
					#---------------------------------------------------------
				END IF 
			END IF 

			SELECT finish_flag 
			INTO pr_activity.finish_flag 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_load_res_all.job_code 
			AND var_code = pr_load_res_all.var_code 
			AND activity_code = pr_load_res_all.activity_code 

			IF status = notfound THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Activity code IS NULL OR does NOT exist") 
				#---------------------------------------------------------
			ELSE 
				IF pr_activity.finish_flag = "Y" THEN 
					LET err_rpt = true 
					LET row_err = true 
					#---------------------------------------------------------
					OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
					pr_load_res_all.*, 
						"Activity IS finished - No costs may be allocated") 
					#---------------------------------------------------------
				END IF 
			END IF 

			IF pr_load_res_all.allocation_ind IS NULL 
			OR pr_load_res_all.allocation_ind NOT matches "[ABCNQR]" THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Resource allocation indicator IS invalid") 
				#---------------------------------------------------------
			END IF 

			IF pr_load_res_all.trans_qty IS NULL THEN 
				LET pr_load_res_all.trans_qty = 0 
			END IF 

			IF pr_load_res_all.unit_cost_amt IS NULL THEN 
				LET pr_load_res_all.unit_cost_amt = 0 
			END IF 

			IF pr_load_res_all.unit_bill_amt IS NULL THEN 
				LET pr_load_res_all.unit_bill_amt = 0 
			END IF 

			LET pr_load_res_all.trans_amt = pr_load_res_all.unit_cost_amt * 
			pr_load_res_all.trans_qty 
			LET pr_load_res_all.charge_amt = pr_load_res_all.unit_bill_amt * 
			pr_load_res_all.trans_qty 

			IF pr_jmresource.cost_ind = "2" 
			AND pr_load_res_all.unit_cost_amt != pr_jmresource.unit_cost_amt THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Unit cost differs FROM fixed unit cost") 
				#---------------------------------------------------------
			END IF 

			IF pr_jmresource.bill_ind = "2" 
			AND pr_load_res_all.unit_bill_amt != pr_jmresource.unit_bill_amt THEN 
				LET err_rpt = true 
				LET row_err = true 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_err(l_rpt_idx,
				pr_load_res_all.*, 
				"Unit price differs FROM fixed charge amount") 
				#---------------------------------------------------------
			END IF 

			IF NOT row_err THEN 
				CALL upd_jobledg() 
				#---------------------------------------------------------
				OUTPUT TO REPORT J7A_rpt_list_post_suc(l_rpt_idx,
				pr_load_res_all.*) 
				#---------------------------------------------------------				
			END IF 
		END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT J7A_rpt_list_post_suc
	CALL rpt_finish("J7A_rpt_list_post_suc")
	#------------------------------------------------------------
	#------------------------------------------------------------
	FINISH REPORT J7A_rpt_list_post_err
	CALL rpt_finish("J7A_rpt_list_post_err")
	#------------------------------------------------------------
	 	 

		IF err_rpt THEN 
			ROLLBACK WORK 
			ERROR " Error adding transactions - Run RMS TO view error REPORT" 
		ELSE 
			MESSAGE" Transactions added successfully - Run RMS TO view success REPORT" 
			attribute (yellow) 
			SLEEP 1 
		COMMIT WORK 
	END IF 

	WHENEVER ERROR stop 
	DELETE FROM load_res_all 
	CLEAR FORM 

	IF err_rpt THEN 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION load_details()
#
# 
###########################################################################



###########################################################################
# FUNCTION upd_jobledg()
#
# 
###########################################################################
FUNCTION upd_jobledg() 

	IF old_trans_date != pr_load_res_all.trans_date THEN 
		SELECT * 
		INTO pr_jmparms.* 
		FROM jmparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 

		LET pr_jmparms.ra_num = pr_jmparms.ra_num + 1 
		LET err_message = "JA7 - Update of jmparms failed" 

		UPDATE jmparms 
		SET ra_num = pr_jmparms.ra_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 

		LET old_trans_date = pr_load_res_all.trans_date 
	END IF 

	LET pr_load_res_all.trans_source_num = pr_jmparms.ra_num 

	DECLARE act_upd CURSOR FOR 
	SELECT * 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_load_res_all.job_code 
	AND var_code = pr_load_res_all.var_code 
	AND activity_code = pr_load_res_all.activity_code 
	FOR UPDATE 

	OPEN act_upd 
	FETCH act_upd INTO pr_activity.* 

	LET pr_activity.seq_num = pr_activity.seq_num + 1 
	LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_jobledger.trans_date = pr_load_res_all.trans_date 
	LET pr_jobledger.job_code = pr_load_res_all.job_code 
	LET pr_jobledger.var_code = pr_load_res_all.var_code 
	LET pr_jobledger.activity_code = pr_load_res_all.activity_code 
	LET pr_jobledger.seq_num = pr_activity.seq_num 
	LET pr_jobledger.trans_type_ind = "RE" 
	LET pr_jobledger.trans_source_num = pr_jmparms.ra_num 
	LET pr_jobledger.trans_source_text = pr_jmresource.res_code 
	LET pr_jobledger.trans_amt = pr_load_res_all.trans_amt 
	LET pr_jobledger.trans_qty = pr_load_res_all.trans_qty 
	LET pr_jobledger.charge_amt = pr_load_res_all.charge_amt 
	LET pr_jobledger.posted_flag = "N" 
	LET pr_jobledger.desc_text = pr_load_res_all.desc_text 
	LET pr_jobledger.allocation_ind = pr_load_res_all.allocation_ind 
	LET pr_jobledger.entry_date = today 
	LET pr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
	LET err_message = "J7A - Insert INTO jobledger failed" 

	IF pr_jobledger.desc_text IS NULL THEN 
		LET pr_jobledger.desc_text = pr_jmresource.desc_text 
	END IF 

	INSERT INTO jobledger VALUES (pr_jobledger.*) 

	LET err_message = "J7A - Update of activity failed" 

	CALL set_start(pr_jobledger.job_code, pr_jobledger.trans_date) 

	LET pr_activity.act_cost_amt = pr_activity.act_cost_amt + 
	pr_load_res_all.trans_amt 
	LET pr_activity.post_revenue_amt = pr_activity.post_revenue_amt + 
	pr_load_res_all.charge_amt 
	LET pr_activity.act_cost_qty = pr_activity.act_cost_qty + 
	pr_load_res_all.trans_qty 

	IF pr_activity.act_start_date IS NULL 
	OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
		UPDATE activity 
		SET act_start_date = pr_jobledger.trans_date, 
		act_cost_amt = pr_activity.act_cost_amt, 
		act_cost_qty = pr_activity.act_cost_qty, 
		post_revenue_amt = pr_activity.post_revenue_amt, 
		seq_num = pr_activity.seq_num 
		WHERE CURRENT OF act_upd 
	ELSE 
		UPDATE activity 
		SET act_cost_amt = pr_activity.act_cost_amt, 
		act_cost_qty = pr_activity.act_cost_qty, 
		post_revenue_amt = pr_activity.post_revenue_amt, 
		seq_num = pr_activity.seq_num 
		WHERE CURRENT OF act_upd 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION upd_jobledg()
###########################################################################


###########################################################################
# REPORT J7A_rpt_list_post_err(p_rpt_idx,p_rec_load_res_all, p_error_desc)
#
# 
###########################################################################
REPORT J7A_rpt_list_post_err(p_rpt_idx,p_rec_load_res_all, p_error_desc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
--	DEFINE rv_line1 CHAR(132) 
--	DEFINE rv_line2 CHAR(132) 
--	DEFINE rv_line3 CHAR(132) 
--	DEFINE rv_line4 CHAR(132) 
	DEFINE p_error_desc CHAR(90) 
--	DEFINE rv_eof_text CHAR(50) 
--	DEFINE rv_offset SMALLINT 

	DEFINE p_rec_load_res_all RECORD 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		job_code LIKE jobledger.job_code, 
		trans_date LIKE jobledger.trans_date, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		desc_text LIKE jobledger.desc_text, 
		activity_code LIKE jobledger.activity_code, 
		var_code LIKE jobledger.var_code, 
		allocation_ind LIKE jobledger.allocation_ind, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		trans_source_num LIKE jobledger.trans_source_num 
	END RECORD 


	OUTPUT 
	top margin 0 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Trans Date", 
			COLUMN 13, TRAN_TYPE_JOB_JOB, 
			COLUMN 27, "Activity", 
			COLUMN 40, "Variation", 
			COLUMN 50, "Error Description" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_load_res_all.trans_date, 
			COLUMN 13, p_rec_load_res_all.job_code, 
			COLUMN 27, p_rec_load_res_all.activity_code, 
			COLUMN 40, p_rec_load_res_all.var_code, 
			COLUMN 50, p_error_desc 

		ON LAST ROW 
			NEED 2 LINES 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
###########################################################################
# END REPORT J7A_rpt_list_post_err(p_rec_load_res_all, p_error_desc)
###########################################################################


###########################################################################
# REPORT J7A_rpt_list_post_suc(p_rpt_idx,rr_load_res_all) 
#
# 
###########################################################################
REPORT J7A_rpt_list_post_suc(p_rpt_idx,rr_load_res_all) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE rv_line1 CHAR(132) 
	DEFINE rv_line2 CHAR(132) 
	DEFINE rv_line3 CHAR(132) 
	DEFINE rv_line4 CHAR(132) 
	DEFINE rv_eof_text CHAR(50) 
	DEFINE rv_offset SMALLINT 

	DEFINE rr_load_res_all RECORD 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		job_code LIKE jobledger.job_code, 
		trans_date LIKE jobledger.trans_date, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		desc_text LIKE jobledger.desc_text, 
		activity_code LIKE jobledger.activity_code, 
		var_code LIKE jobledger.var_code, 
		allocation_ind LIKE jobledger.allocation_ind, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		trans_source_num LIKE jobledger.trans_source_num 
	END RECORD 


	OUTPUT 
	top margin 0 
	left margin 0 

	ORDER external BY rr_load_res_all.trans_date, 
	rr_load_res_all.job_code, 
	rr_load_res_all.activity_code, 
	rr_load_res_all.var_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  


			PRINT COLUMN 1, TRAN_TYPE_JOB_JOB, 
			COLUMN 10, "Variation", 
			COLUMN 21, "Activity", 
			COLUMN 35, "Unit Qty", 
			COLUMN 53, "Cost Rate", 
			COLUMN 72, "Line Cost" 

			PRINT COLUMN 51, "Charge Rate", 
			COLUMN 70, "Line Charge" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF rr_load_res_all.trans_date 
			SKIP 1 line 
			PRINT COLUMN 1, "Resource Code: ", pr_jmresource.res_code, 
			COLUMN 57, "Trans. Date : ", rr_load_res_all.trans_date 
			PRINT COLUMN 16, pr_jmresource.desc_text, 
			COLUMN 57, "Res. All. # : ", rr_load_res_all.trans_source_num USING 
			"<<<<<<<<<<" 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 1, rr_load_res_all.job_code, 
			COLUMN 9, rr_load_res_all.var_code, 
			COLUMN 21, rr_load_res_all.activity_code, 
			COLUMN 29, rr_load_res_all.trans_qty, 
			COLUMN 48, rr_load_res_all.unit_cost_amt, 
			COLUMN 63, rr_load_res_all.trans_amt 

			PRINT COLUMN 2, "Comments:", 
			COLUMN 13, rr_load_res_all.desc_text clipped, 
			COLUMN 48, rr_load_res_all.unit_bill_amt, 
			COLUMN 63, rr_load_res_all.charge_amt 

		AFTER GROUP OF rr_load_res_all.trans_date 
			NEED 3 LINES 
			PRINT rv_line3 clipped 

			PRINT COLUMN 18, "Total Qty", 
			COLUMN 30, GROUP sum(rr_load_res_all.trans_qty) 
			USING "#########&.&&", 
			COLUMN 49, "Total Cost", 
			COLUMN 64, GROUP sum(rr_load_res_all.trans_amt) 
			USING "#############&.&&" 

			IF GROUP sum(rr_load_res_all.trans_qty) = 0 THEN 
				PRINT COLUMN 18, "Avg Rate", 
				COLUMN 39, 0.00; 
			ELSE 
				PRINT COLUMN 18, "Avg Rate", 
				COLUMN 30, GROUP sum(rr_load_res_all.trans_amt) / 
				GROUP sum(rr_load_res_all.trans_qty) 
				USING "#########&.&&"; 
			END IF 

			PRINT COLUMN 49, "Total Charge", 
			COLUMN 64, GROUP sum(rr_load_res_all.charge_amt) 
			USING "#############&.&&" 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT rv_line3 clipped 

			PRINT COLUMN 1, "GRAND TOTALS:", 
			COLUMN 18, "Total Qty", 
			COLUMN 30, sum(rr_load_res_all.trans_qty) USING "#########&.&&", 
			COLUMN 49, "Total Cost", 
			COLUMN 64, sum(rr_load_res_all.trans_amt) USING "#############&.&&" 

			IF sum(rr_load_res_all.trans_qty) = 0 THEN 
				PRINT COLUMN 18, "Avg Rate", 
				COLUMN 39, 0.00; 
			ELSE 
				PRINT COLUMN 18, "Avg Rate", 
				COLUMN 30, sum(rr_load_res_all.trans_amt) / 
				sum(rr_load_res_all.trans_qty) USING "#########&.&&"; 
			END IF 

			PRINT COLUMN 49, "Total Charge", 
			COLUMN 64, sum(rr_load_res_all.charge_amt) USING "#############&.&&" 

			PRINT rv_line3 clipped 

			IF err_rpt THEN 
				NEED 2 LINES 
				SKIP 1 line 
				PRINT "----- Resource Allocation Failed -----" 
			END IF 

			NEED 2 LINES 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 
###########################################################################
# END REPORT J7A_rpt_list_post_suc(p_rpt_idx,rr_load_res_all) 
###########################################################################