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

# Purpose - Contract Print

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA5_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("JA5") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CREATE temp TABLE details ( 
	cmpy_code CHAR(2) , 
	contract_code CHAR(10) , 
	cust_code CHAR(8) , 
	line_num SMALLINT , 
	ship_code CHAR(8) , 
	type_code CHAR(1) , 
	job_code CHAR(8) , 
	var_code SMALLINT , 
	activity_code CHAR(8) , 
	part_code CHAR(15) , 
	desc_text CHAR(40) , 
	bill_qty FLOAT , 
	bill_price DECIMAL(16,4) , 
	acct_mask CHAR(18) , 
	revenue_acct_code CHAR(18) , 
	user1_text CHAR(20) , 
	user2_text CHAR(20) , 
	status_code CHAR(1) ) 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW wja00 with FORM "JA00" -- alch kd-747 
	CALL winDecoration_j("JA00") -- alch kd-747 

	MENU " Contract Details" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA5","menu-contract_details-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REPORT" --COMMAND "Report" " Selection Criteria AND PRINT REPORT" 
			IF JA5_rpt_query() THEN 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW wja00 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION JA5_rpt_query()
#
#
############################################################
FUNCTION JA5_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE fv_cnt SMALLINT 
	LET msgresp = kandoomsg("A",1001,"") 
	# Enter selection criteria - Esc TO continue
	CONSTRUCT BY NAME where_part ON 
	contract_code, 
	desc_text, 
	cust_code, 
	status_code, 
	user1_text, 
	last_billed_date, 
	bill_type_code, 
	start_date, 
	entry_code, 
	bill_int_ind, 
	end_date, 
	entry_date, 
	sale_code, 
	cons_inv_flag, 
	comm1_text, 
	comm2_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA5","const-contract_code-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET query_text = "SELECT * FROM contracthead " , 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND ", where_part clipped, 
	" ORDER BY contract_code" 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET pv_date_flag = false 
	LET pv_first_flag = true 
	LET msgresp = kandoomsg("A",3551,"") 
	# Must Invoice Dates Schedule be included in REPORT? Y/N
	IF msgresp = "Y" THEN 
		LET pv_date_flag = true 
	END IF 
	LET msgresp = kandoomsg("A",1002,"") 
	# "Searching database - please wait"
	#    OPEN WINDOW w1_JA5 AT 10,10 with 2 rows, 50 columns
	#        ATTRIBUTE(border,white)      -- alch KD-747


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"JA5_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JA5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JA5_rpt_list")].sel_text
	#------------------------------------------------------------

	PREPARE statement_1 FROM query_text 
	DECLARE s_curs1 CURSOR FOR statement_1 
	LET fv_cnt = 0 
	
	FOREACH s_curs1 INTO pr_contracthead.* 
		DECLARE s_curs2 CURSOR FOR 
		SELECT * FROM contractdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pr_contracthead.contract_code 

		FOREACH s_curs2 INTO pr_contractdetl.* 
			LET fv_cnt = fv_cnt + 1 
			INSERT INTO details VALUES (pr_contractdetl.*) 
		END FOREACH 
	END FOREACH 

	IF fv_cnt = 0 THEN 
		#        CLOSE WINDOW w1_JA5      -- alch KD-747
		LET msgresp=kandoomsg("A",3512,"") 
		RETURN false 
	END IF 

	DECLARE s_curs3 CURSOR FOR 
	SELECT * FROM details 
	ORDER BY contract_code, type_code desc, line_num 

	
	
	
	
		FOREACH s_curs3 INTO pr_contractdetl.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT AC1_rpt_list(l_rpt_idx,
		pr_contractdetl.*) 
		#---------------------------------------------------------			
	END FOREACH 
	#    CLOSE WINDOW w1_JA5      -- alch KD-747

	DELETE FROM details 
	 
	#------------------------------------------------------------
	FINISH REPORT JA5_rpt_list
	CALL rpt_finish("JA5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION JA5_rpt_query()
#
#
############################################################

############################################################
# REPORT JA5_rpt_list(rr_contractdetl)
#
#
############################################################
REPORT JA5_rpt_list(p_rpt_idx,rr_contractdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pa_line array[4] OF CHAR(132) 
	DEFINE rr_contractdetl RECORD LIKE contractdetl.* 
	DEFINE rr_notes RECORD LIKE notes.* 
	DEFINE rv_note_code LIKE notes.note_code 

	DEFINE pr_eof_text CHAR(50) 
	DEFINE pr_selection_text CHAR(24) 
	DEFINE rv_status_text CHAR(21) 
	DEFINE rv_bill_type_text CHAR(12) 
	DEFINE offset1 SMALLINT 
	DEFINE rv_cont_flag SMALLINT 
	DEFINE rv_cnt SMALLINT 
	DEFINE rv_pos SMALLINT 
	DEFINE len INTEGER 
	DEFINE s INTEGER 

	ORDER external BY rr_contractdetl.contract_code, 
	rr_contractdetl.type_code 

	FORMAT 

		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		
			LET rv_cont_flag = false 

			SKIP 1 line 
			PRINT COLUMN 1, "Contract : ", pr_contractdetl.contract_code, 
			COLUMN 24, pr_contracthead.desc_text 
			SKIP 1 line 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
			
			SKIP 1 line 
			IF rv_cont_flag THEN 
				PRINT COLUMN 1, "Contract : ",rr_contractdetl.contract_code, 
				" continued" 
				SKIP 1 line 
			ELSE 
				PRINT COLUMN 1, "Contract : ", pr_contractdetl.contract_code, 
				COLUMN 24, pr_contracthead.desc_text 
				SKIP 1 line 
			END IF 

		BEFORE GROUP OF rr_contractdetl.contract_code 
			SELECT * 
			INTO pr_contracthead.* 
			FROM contracthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = rr_contractdetl.contract_code 

			IF pv_first_flag THEN 
				LET pv_first_flag = false 
			ELSE 
				SKIP TO top OF PAGE 
			END IF 
			LET rv_cont_flag = true 

			SELECT * 
			INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = rr_contractdetl.cust_code 

			LET rv_status_text = NULL 
			LET rv_bill_type_text = NULL 

			CASE pr_contracthead.status_code 
				WHEN "A" LET rv_status_text = "Active" 
				WHEN "Q" LET rv_status_text = "Quote" 
				WHEN "H" LET rv_status_text = "Hold (no billing)" 
				WHEN "C" LET rv_status_text = "Complete (no billing)" 
			END CASE 

			CASE pr_contracthead.bill_type_code 
				WHEN "D" LET rv_bill_type_text = "Daily" 
				WHEN "W" LET rv_bill_type_text = "Weekly" 
				WHEN "M" LET rv_bill_type_text = "Monthly" 
				WHEN "E" LET rv_bill_type_text = "END of Month" 
				WHEN "A" LET rv_bill_type_text = "Annually" 
			END CASE 

			PRINT COLUMN 1, "Customer : ", rr_contractdetl.cust_code, 
			COLUMN 24, pr_customer.name_text 
			PRINT COLUMN 1, "Status : ", rv_status_text, 
			COLUMN 56, "Start Date : ", pr_contracthead.start_date 
			PRINT COLUMN 1, "Billing", 
			COLUMN 58, "END Date : ", pr_contracthead.end_date 
			PRINT COLUMN 1, "Type : ", rv_bill_type_text, 
			COLUMN 24, "Value : ", pr_contracthead.contract_value_amt 
			USING "<<,<<<,<<&.&&", 
			COLUMN 50, "Last Billed Date : ", 
			pr_contracthead.last_billed_date 
			PRINT COLUMN 1, "Interval : ", pr_contracthead.bill_int_ind 
			USING "<<<", 
			COLUMN 38, "Entered By : ", pr_contracthead.entry_code, 
			COLUMN 62, "Date : ", pr_contracthead.entry_date 

			PRINT COLUMN 1, "Consolidate Invoices : "; 

			IF pr_contracthead.cons_inv_flag = "Y" THEN 
				PRINT "Yes" 
			ELSE 
				PRINT "No" 
			END IF 

			SKIP 1 line 

			IF pv_date_flag THEN 

				PRINT COLUMN 33, "Invoice Schedule" 
				SKIP 1 line 
				PRINT COLUMN 5, "Invoice", 
				COLUMN 17, "Date", 
				COLUMN 34, "Amount", 
				COLUMN 44, "Invoice", 
				COLUMN 56, "Date", 
				COLUMN 73, "Amount" 

				DECLARE s_curs4 CURSOR FOR 
				SELECT * 
				FROM contractdate 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND contract_code = pr_contracthead.contract_code 
				ORDER BY invoice_date 

				LET rv_cnt = 1 
				FOREACH s_curs4 INTO pr_contractdate.* 

					IF rv_cnt = 1 THEN 
						LET rv_pos = 0 
						LET rv_cnt = 2 
					ELSE 
						LET rv_pos = 39 
						LET rv_cnt = 1 
					END IF 

					PRINT COLUMN rv_pos , pr_contractdate.inv_num, 
					COLUMN rv_pos + 14, pr_contractdate.invoice_date, 
					COLUMN rv_pos + 22, pr_contractdate.invoice_total_amt; 

					IF rv_cnt = 1 THEN 
						PRINT 
					END IF 
				END FOREACH 

				IF rv_cnt = 2 THEN 
					PRINT 
				END IF 
				SKIP 1 line 

			END IF 

		BEFORE GROUP OF rr_contractdetl.type_code 
			CASE rr_contractdetl.type_code 
				WHEN "J" PRINT COLUMN 35, "Job Details" 
				WHEN "I" PRINT COLUMN 32, "Inventory Details" 
				WHEN "G" PRINT COLUMN 33, "General Details" 
			END CASE 
			SKIP 1 line 

		ON EVERY ROW 
			NEED 4 LINES 

			SELECT * 
			INTO pr_customership.* 
			FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = rr_contractdetl.cust_code 
			AND ship_code = rr_contractdetl.ship_code 

			LET rv_note_code = rr_contractdetl.desc_text[4,15] 

			PRINT COLUMN 1, "Location ID : ", rr_contractdetl.ship_code, 
			COLUMN 34, pr_customership.name_text 

			CASE rr_contractdetl.type_code 
				WHEN "J" 
					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = rr_contractdetl.job_code 

					SELECT * 
					INTO pr_jobvars.* 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = rr_contractdetl.job_code 
					AND var_code = rr_contractdetl.var_code 

					PRINT COLUMN 1, "Job : ", rr_contractdetl.job_code, 
					COLUMN 34, pr_job.title_text 
					PRINT COLUMN 1, "Variation : ", rr_contractdetl.var_code 
					USING "<<<&", 
					COLUMN 34, pr_jobvars.title_text 
					PRINT COLUMN 1, "Activity : ", 
					rr_contractdetl.activity_code, 
					COLUMN 34, rr_contractdetl.desc_text 

					IF rr_contractdetl.desc_text[1,3] = "###" THEN 
						DECLARE s_curs5 CURSOR FOR 
						SELECT * 
						FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = rv_note_code 
						ORDER BY note_num 

						FOREACH s_curs5 INTO rr_notes.* 
							PRINT COLUMN 22, rr_notes.note_text 
						END FOREACH 
					END IF 
					SKIP 1 line 


				WHEN "I" 
					PRINT COLUMN 1, "Product Code : ", rr_contractdetl.part_code, 
					COLUMN 34, rr_contractdetl.desc_text 

					IF rr_contractdetl.desc_text[1,3] = "###" THEN 
						DECLARE s_curs6 CURSOR FOR 
						SELECT * 
						FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = rv_note_code 
						ORDER BY note_num 

						FOREACH s_curs6 INTO rr_notes.* 
							PRINT COLUMN 22, rr_notes.note_text 
						END FOREACH 
					END IF 

					PRINT COLUMN 1, "Price : ", rr_contractdetl.bill_price 
					USING "<<,<<<,<<&.&&", 
					COLUMN 34, "Quantity : ", rr_contractdetl.bill_qty 
					USING "<<<<<<<<<<&.&&" 
					PRINT COLUMN 1, "GL Acct Mask : ", rr_contractdetl.acct_mask 

					SKIP 1 line 


				WHEN "G" 
					PRINT COLUMN 1, "Description : ", rr_contractdetl.desc_text 

					IF rr_contractdetl.desc_text[1,3] = "###" THEN 
						DECLARE s_curs7 CURSOR FOR 
						SELECT * 
						FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = rv_note_code 
						ORDER BY note_num 

						FOREACH s_curs7 INTO rr_notes.* 
							PRINT COLUMN 22, rr_notes.note_text 
						END FOREACH 
					END IF 

					PRINT COLUMN 1, "Price : ", rr_contractdetl.bill_price 
					USING "<<,<<<,<<&.&&", 
					COLUMN 34, "Quantity : ", rr_contractdetl.bill_qty 
					PRINT COLUMN 1, "GL Acct Code : ", 
					rr_contractdetl.revenue_acct_code 

					SKIP 1 line 


			END CASE 
			SKIP 1 line 

		AFTER GROUP OF rr_contractdetl.contract_code 
			LET rv_cont_flag = false 

		ON LAST ROW 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			 
END REPORT 