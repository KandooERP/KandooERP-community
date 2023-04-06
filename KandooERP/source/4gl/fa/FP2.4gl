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
GLOBALS "../fa/F_FA_GLOBALS.4gl" 

# Purpose    :    Depreciation Calculation - creates batch TO be posted

GLOBALS 
	DEFINE 
	try_again CHAR(1), 
	err_message CHAR(60), 
	pr_fabatch RECORD LIKE fabatch.*, 
	p_fastatus RECORD LIKE fastatus.*, 
	p_faparms RECORD LIKE faparms.*, 
	p_faaudit RECORD LIKE faaudit.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_company RECORD LIKE company.*, 
	p_fabatch RECORD LIKE fabatch.*, 
	this_batch SMALLINT, 
	curr_line_num SMALLINT, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	p_fabook RECORD LIKE fabook.*, 
	p_fabookdep RECORD LIKE fabookdep.*, 
	p_fadepmethod RECORD LIKE fadepmethod.*, 
	repstarted CHAR(1), 
	w_bookid CHAR(2), 
	w_year SMALLINT, 
	w_period SMALLINT, 
	w_proceed CHAR(1), 
	book_desc CHAR(20), 
	total_depr, 
	total_asset MONEY, 
	security_ind CHAR(1), 
	pr_output CHAR(100), 
	rpt_wind CHAR(100), 

	pr_famast RECORD LIKE famast.*, 
	runner CHAR(80), 
	ans CHAR(1), 
	err_msg CHAR(80) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("FP2") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW wf176 with FORM "F176" -- alch kd-757 
	CALL  windecoration_f("F176") -- alch kd-757 
	WHILE true 
		INPUT BY NAME w_bookid 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","FP2","inp-w_bookid-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		SELECT * 
		INTO p_fabook.* 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = w_bookid 
		IF status = notfound THEN 
			ERROR "Book code NOT found, try again" 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	LET w_year = p_fabook.curr_year_num 
	LET w_period = p_fabook.curr_period_num 
	DISPLAY BY NAME w_year, w_period 
	DISPLAY p_fabook.book_text TO book_desc 
	INPUT BY NAME w_proceed 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FP2","inp-w_proceed-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF w_proceed = "Y" THEN 
		DECLARE check_curs CURSOR FOR 
		SELECT * 
		FROM fabatch,faaudit 
		WHERE fabatch.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_asset_flag = "N" 
		AND fabatch.cmpy_code = faaudit.cmpy_code 
		AND fabatch.batch_num = faaudit.batch_num 
		AND faaudit.book_code = w_bookid 
		OPEN check_curs 
		FETCH check_curs INTO pr_fabatch.* 
		IF NOT status THEN 
			ERROR "Unposted batches exist - please post ", 
			"before depreciation calc - Book : ",w_bookid 
			SLEEP 5 
			EXIT program 
		END IF 

		CALL update_data() 
	END IF 


END MAIN 

REPORT FP2_rpt_list(r_fabookdep, r_cmpy, r_error) 
	DEFINE r_fabookdep RECORD LIKE fabookdep.* 
	DEFINE r_cmpy LIKE fabookdep.cmpy_code
	DEFINE r_company RECORD LIKE company.* 
	DEFINE r_error SMALLINT 

	FORMAT 
		PAGE HEADER 
			SELECT * INTO r_company.* 
			FROM company 
			WHERE cmpy_code = r_cmpy 

			PRINT COLUMN 10, today USING "dd/mm/yy", 
			COLUMN 30, r_cmpy clipped, " ", r_company.name_text, 
			COLUMN 60, "Page ", pageno USING "####" 
			PRINT COLUMN 20, "Depreciation Exception Report (Menu-FP2)" 
			SKIP 1 line 
			PRINT "----------------------------------------", 
			"---------------------------------------" 
			PRINT COLUMN 8, "Asset", 
			COLUMN 28, "Error" 
			PRINT "----------------------------------------", 
			"---------------------------------------" 
			PRINT "Book Code: ", r_fabookdep.book_code 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 8, r_fabookdep.asset_code; 
			IF r_error = 1 THEN 
				PRINT COLUMN 28, "Depreciation code \"", 
				r_fabookdep.depn_code clipped, 
				"\" NOT SET up." 
			END IF 
			IF r_error = 2 THEN 
				PRINT COLUMN 28, "fastatus RECORD NOT found ", 
				"FOR this asset/book combination" 
				PRINT COLUMN 28, "This means the asset has NOT been added", 
				" OR the add batch posted TO assets" 
			END IF 
END REPORT 


# Audit REPORT


REPORT FP2_rpt_list_audit(r_faaudit, r_status, goodbad,mess) 
	DEFINE 
	r_faaudit RECORD LIKE faaudit.*, 
	r_status CHAR(35) , 
	r_cmpy CHAR(2), 
	r_compname CHAR(40), 
	goodbad CHAR(1), #good OR bad batch 
	mess CHAR(80) 

	OUTPUT 
	PAGE length 66 

	FORMAT 
		PAGE HEADER 
			SELECT name_text 
			INTO pr_company.name_text 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			PRINT COLUMN 12, today USING "DD/MM/YY", 
			COLUMN 40, glob_rec_kandoouser.cmpy_code, " ", 
			pr_company.name_text, 
			COLUMN 80, "Page ", 
			pageno 

			PRINT COLUMN 40, "FA - Depreciation Audit (Menu FP2)" 
			PRINT COLUMN 42, "Sorted by Batch Number" 
			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------" 

			PRINT COLUMN 1, "Batch", 
			COLUMN 11, "Line", 
			COLUMN 22, "Asset", 
			COLUMN 35, "Book", 
			COLUMN 40, "Year", 
			COLUMN 50, "Period", 
			COLUMN 63, "Trans", 
			COLUMN 73, "Asset", 
			COLUMN 89, "Depr", 
			COLUMN 105," Salvage" 

			PRINT COLUMN 1, "Num", 
			COLUMN 11, "Num", 
			COLUMN 22, "Code", 
			COLUMN 35, "ID", 
			COLUMN 40, "Num", 
			COLUMN 50, "Num", 
			COLUMN 63, "Type", 
			COLUMN 73, "Amount", 
			COLUMN 89, "Amount", 
			COLUMN 105," Amount", 
			COLUMN 120, "Status" 

			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------" 

		ON EVERY ROW 
			IF r_status = "CREATED" THEN 
				LET r_status = NULL 
			END IF 
			PRINT COLUMN 1, r_faaudit.batch_num USING "#####", 
			COLUMN 11, r_faaudit.batch_line_num USING "####", 
			COLUMN 22, r_faaudit.asset_code, 
			COLUMN 35, r_faaudit.book_code, 
			COLUMN 40, r_faaudit.year_num USING "####", 
			COLUMN 50, r_faaudit.period_num USING "####", 
			COLUMN 64, r_faaudit.trans_ind, 
			COLUMN 68, r_faaudit.asset_amt USING "---,---,--$.##", 
			COLUMN 83, r_faaudit.depr_amt USING "---,---,--$.##", 
			COLUMN 105,r_faaudit.salvage_amt USING "---,---,--$.##", 
			COLUMN 120, r_status clipped 
			IF goodbad = "N" {bad} THEN 
				PRINT COLUMN 1, "***WARNING ",mess 
			END IF 

END REPORT 



FUNCTION update_data() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	lines_inserted SMALLINT, 
	tmp_flag CHAR(1), 
	tmp_seq LIKE faaudit.status_seq_num 

	LET lines_inserted = false 

	IF p_fabook.curr_per_depn_flag = "Y" THEN 
		#OPEN WINDOW w_end AT 10,15 with 2 rows, 41 columns
		#attribute (reverse, border)  -- alch KD-757

		DISPLAY "Depreciation has already been calculated" at 1,1 
		DISPLAY " AND posted FOR this period " at 2,1 

		SLEEP 4 
		EXIT program 
	END IF 

	LET repstarted = "N" 
	DECLARE c_bookdep CURSOR with HOLD FOR 
	SELECT * 
	INTO p_fabookdep.* 
	FROM fabookdep 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND book_code = w_bookid 
	ORDER BY asset_code, add_on_code 

	OPEN c_bookdep 
	FETCH c_bookdep 
	IF status THEN 
		ERROR "No Asset/Book records found - see (F1B)" 
		SLEEP 4 
		RETURN 
	END IF 

	#OPEN WINDOW w_val AT 10,15 with 3 rows, 30 columns
	#attribute (border)  -- alch KD-757

	DISPLAY "Validating assets...." at 1,1 

	FOREACH c_bookdep 
		SELECT * 
		INTO p_fadepmethod.* 
		FROM fadepmethod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND depn_code = p_fabookdep.depn_code 

		IF status = notfound THEN 
			IF repstarted = "N" THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("FP2-STATUS","FP2_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT FP2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				--LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
				#------------------------------------------------------------
				
				 
				LET repstarted = "Y" 
			END IF 
			#---------------------------------------------------------
			OUTPUT TO REPORT F61_rpt_list(l_rpt_idx,
			p_fabookdep.*, glob_rec_kandoouser.cmpy_code, 1) 
			#---------------------------------------------------------			 
		END IF 

		SELECT * 
		FROM fastatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = p_fabookdep.asset_code 
		AND add_on_code = p_fabookdep.add_on_code 
		AND book_code = p_fabookdep.book_code 

		IF status = notfound THEN 
			IF repstarted = "N" THEN 
				
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("FP2-CALC","FP2_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT FP2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				--LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
				#------------------------------------------------------------				
				 
				LET repstarted = "Y" 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT F61_rpt_list(l_rpt_idx,
			p_fabookdep.*, glob_rec_kandoouser.cmpy_code, 2) 
			#---------------------------------------------------------					
		END IF 
	END FOREACH 

	IF repstarted = "Y" THEN 

		#------------------------------------------------------------
		FINISH REPORT FP2_rpt_list
		CALL rpt_finish("FP2_rpt_list")
		#------------------------------------------------------------		 
		CALL fgl_winmessage("Error","Errors in data. See REPORT.","ERROR")		
		EXIT program 
		
	END IF 

	DISPLAY "Calculating Depn.." at 1,1 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("FP2-AUDIT","FP2_rpt_list_audit","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT FP2_rpt_list_audit TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------		

	GOTO bypass 

	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LOCK TABLE faparms in share MODE 
		LOCK TABLE fabatch in share MODE 
		LOCK TABLE faaudit in share MODE 

		LET curr_line_num = 0 
		LET total_depr = 0 
		LET total_asset = 0 

		SELECT * 
		INTO p_faparms.* 
		FROM faparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET repstarted = "N" 

		SELECT * 
		INTO p_fabook.* 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = w_bookid 

		# UPDATE of fabook but VALUES of p_fabook remain ie current period
		# remain as before UPDATE
		IF p_fabook.curr_period_num = p_faparms.asset_period_num THEN 
			UPDATE fabook SET curr_period_num = 1, 
			curr_year_num = curr_year_num + 1, 
			curr_per_depn_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND book_code = w_bookid 
		ELSE 
			UPDATE fabook SET curr_period_num = curr_period_num + 1, 
			curr_per_depn_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND book_code = w_bookid 
		END IF 

		FOREACH c_bookdep 

			# SET these variables up FOR the audit REPORT
			LET p_faaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET p_faaudit.asset_code = p_fabookdep.asset_code 
			LET p_faaudit.add_on_code = p_fabookdep.add_on_code 
			LET p_faaudit.book_code = p_fabookdep.book_code 
			LET p_faaudit.year_num = w_year 
			LET p_faaudit.period_num = w_period 
			LET p_faaudit.asset_amt = 0 
			LET p_faaudit.depr_amt = 0 

			DISPLAY "Asset : ",p_fabookdep.asset_code at 3,1 

			# check IF the asset has been sold OR retired

			LET tmp_flag = " " 
			SELECT bal_chge_appl_flag 
			INTO tmp_flag 
			FROM fastatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_fabookdep.asset_code 
			AND add_on_code = p_fabookdep.add_on_code 
			AND book_code = p_fabookdep.book_code 
			IF tmp_flag = "R" THEN 
				CONTINUE FOREACH {retired asset} 
			END IF 
			IF tmp_flag = "S" THEN {sold asset} 
				CONTINUE FOREACH 
			END IF 

			# check IF this asset should be depreciated
			# ie its operate date start year AND period are equal TO
			# OR AFTER the period about TO be depreciated
			SELECT start_year_num,start_period_num 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_fabookdep.asset_code 
			AND add_on_code = p_fabookdep.add_on_code 
			AND ((start_year_num = p_fabook.curr_year_num AND 
			start_period_num <= p_fabook.curr_period_num) OR 
			start_year_num < p_fabook.curr_year_num) 
			IF status THEN 
				LET err_msg = "Asset non depreciating in current period", 
				" check start year AND period in menu F11" 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
				p_faaudit.*, 
					"PROBLEM", 
					"N", 
					err_msg) 
				#---------------------------------------------------------		
				
				CONTINUE FOREACH 
			END IF 

			# check IF the asset category allows depreciation
			SELECT deprec_flag 
			FROM facat,famast 
			WHERE famast.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND famast.asset_code = p_fabookdep.asset_code 
			AND famast.add_on_code = p_fabookdep.add_on_code 
			AND famast.cmpy_code = facat.cmpy_code 
			AND famast.facat_code = facat.facat_code 
			AND facat.deprec_flag = "Y" 
			IF status THEN 
				LET err_msg = "Asset category doesn't allow depn. Asset :",		p_fabookdep.asset_code 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
				p_faaudit.*, 
					"PROBLEM", 
					"N", 
					err_msg) 
				#---------------------------------------------------------					

				CONTINUE FOREACH 
			END IF 

			IF repstarted = "N" THEN 
				LET repstarted = "Y" 
				LET this_batch = p_faparms.next_batch_num + 1 
				UPDATE faparms SET next_batch_num = this_batch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			DISPLAY "Batch created : ",this_batch at 2,1 

			INITIALIZE p_faaudit.* TO NULL 

			SELECT * 
			INTO p_fastatus.* 
			FROM fastatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_fabookdep.asset_code 
			AND add_on_code = p_fabookdep.add_on_code 
			AND book_code = p_fabookdep.book_code 

			IF status = notfound THEN 
				LET err_msg = "fastatus NOT found" 

				#---------------------------------------------------------
				OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
				p_faaudit.*, 
					"PROBLEM", 
					"N", 
					err_msg) 
				#---------------------------------------------------------	
				
				CONTINUE FOREACH 
			END IF 

			IF p_fastatus.net_book_val_amt <= 0 THEN 
				CONTINUE FOREACH 
			END IF 

			IF p_fastatus.net_book_val_amt <= p_fastatus.salvage_amt THEN 
				CONTINUE FOREACH 
			END IF 

			LET pr_faaudit.depr_amt = 0 

			SELECT * 
			INTO p_fadepmethod.* 
			FROM fadepmethod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND depn_code = p_fabookdep.depn_code 

			SELECT * 
			INTO pr_famast.* 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_fastatus.asset_code 
			AND add_on_code = p_fastatus.add_on_code 


			#
			#    SLL
			#


			IF p_fadepmethod.depn_method_code = "SLL" THEN 
				IF p_fastatus.life_period_num > 0 THEN 
					LET pr_faaudit.depr_amt = (p_fastatus.cur_depr_cost_amt - 
					p_fastatus.salvage_amt) / 
					p_fastatus.life_period_num 
				ELSE 
					LET pr_faaudit.depr_amt = 0 
				END IF 
			END IF 


			#
			#    SL%
			#


			IF p_fadepmethod.depn_method_code = "SL%" THEN 
				IF p_faparms.asset_period_num > 0 THEN 
					LET pr_faaudit.depr_amt = (p_fastatus.cur_depr_cost_amt - 
					p_fastatus.salvage_amt) * 
					(p_fadepmethod.depn_method_rate / 
					100) / p_faparms.asset_period_num 
				ELSE 
					LET err_msg = "Check faparms - Periods in Year NOT > 0" 

					#---------------------------------------------------------
					OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
					p_faaudit.*, 
						"PROBLEM", 
						"N", 
						err_msg) 
					#---------------------------------------------------------	
					
					LET pr_faaudit.depr_amt = 0 
				END IF 
			END IF 


			#
			#    DVL
			#


			IF p_fadepmethod.depn_method_code = "DVL" THEN 
				IF p_fastatus.net_book_val_amt > 0 THEN 
					IF p_fastatus.rem_life_num > 0 THEN 
						LET pr_faaudit.depr_amt = (p_fastatus.net_book_val_amt - 
						p_fastatus.salvage_amt) / 
						p_fastatus.rem_life_num 
					ELSE 
						LET pr_faaudit.depr_amt = 0 
					END IF 
				ELSE 
					LET pr_faaudit.depr_amt = 0 
				END IF 
			END IF 


			#
			#    DV%
			#


			IF p_fadepmethod.depn_method_code = "DV%" THEN 
				IF p_fastatus.net_book_val_amt > 0 THEN 
					LET pr_faaudit.depr_amt = (p_fastatus.net_book_val_amt - 
					p_fastatus.salvage_amt ) * 
					((p_fadepmethod.depn_method_rate / 100) / 12) 
				END IF 
			END IF 

			IF pr_faaudit.depr_amt IS NULL THEN 
				LET pr_faaudit.depr_amt = 0 
			END IF 
			IF p_faaudit.depr_amt < 0 THEN 
				LET p_faaudit.depr_amt = 0 
			END IF 
			IF pr_faaudit.depr_amt < 0 THEN 
				LET pr_faaudit.depr_amt = 0 
			END IF 

			LET p_faaudit.asset_amt = p_fastatus.cur_depr_cost_amt 
			LET total_asset = total_asset + p_faaudit.asset_amt 
			LET total_depr = total_depr + pr_faaudit.depr_amt 

			# cannot depreciate TO more that original cost less
			# salvage value
			IF (p_fastatus.depr_amt + pr_faaudit.depr_amt) > 
			(p_fastatus.cur_depr_cost_amt - p_fastatus.salvage_amt) THEN 
				LET total_depr = total_depr - pr_faaudit.depr_amt 
				LET pr_faaudit.depr_amt = (p_fastatus.cur_depr_cost_amt - 
				p_fastatus.salvage_amt) - 
				p_fastatus.depr_amt 
				LET total_depr = total_depr + pr_faaudit.depr_amt 
			END IF 

			LET p_faaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET p_faaudit.asset_code = p_fabookdep.asset_code 
			LET p_faaudit.add_on_code = p_fabookdep.add_on_code 
			LET p_faaudit.book_code = p_fabookdep.book_code 
			LET p_faaudit.year_num = w_year 
			LET p_faaudit.period_num = w_period 
			LET curr_line_num = curr_line_num + 1 
			LET p_faaudit.batch_line_num = curr_line_num 
			LET p_faaudit.trans_ind = "D" 
			LET p_faaudit.entry_text = glob_rec_kandoouser.sign_on_code 
			LET p_faaudit.entry_date = today 
			LET p_faaudit.depr_amt = pr_faaudit.depr_amt 
			LET p_faaudit.net_book_val_amt = p_fastatus.net_book_val_amt - 
			p_faaudit.depr_amt 

			LET p_faaudit.salvage_amt = p_fastatus.salvage_amt 
			LET p_faaudit.rem_life_num = p_fastatus.rem_life_num - 1 
			LET p_faaudit.batch_num = this_batch 
			LET p_faaudit.desc_text = "Automatic Depreciation Calc" 

			SELECT location_code, 
			facat_code, 
			faresp_code, 
			orig_auth_code 
			INTO p_faaudit.location_code, 
			p_faaudit.facat_code, 
			p_faaudit.faresp_code, 
			p_faaudit.auth_code 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 


			IF status OR (p_faaudit.location_code IS NULL OR 
			p_faaudit.facat_code IS NULL OR 
			p_faaudit.faresp_code IS null) THEN 
				LET err_msg = "Cannot get location,responsibility AND category" 

				#---------------------------------------------------------
				OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
				p_faaudit.*, 
					"PROBLEM", 
					"N", 
					err_msg) 
				#---------------------------------------------------------	
				 
			ELSE 
				IF p_faaudit.depr_amt > 0 THEN 
					DECLARE seq_curs CURSOR FOR 
					SELECT seq_num 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = p_faaudit.asset_code 
					AND add_on_code = p_faaudit.add_on_code 
					AND book_code = p_faaudit.book_code 
					FOR UPDATE 

					OPEN seq_curs 
					FETCH seq_curs INTO tmp_seq 

					LET p_faaudit.status_seq_num = tmp_seq + 1 

					UPDATE fastatus SET seq_num = p_faaudit.status_seq_num 
					WHERE CURRENT OF seq_curs 

					INSERT INTO faaudit VALUES (p_faaudit.*) 
					LET lines_inserted = true 
					LET err_msg = " " 

					#---------------------------------------------------------
					OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
					p_faaudit.*,"CREATED","Y",err_msg) 
					#---------------------------------------------------------	
					

				ELSE 
					LET err_msg = "Depreciation NOT > 0 FOR this asset"

					#---------------------------------------------------------
					OUTPUT TO REPORT FP2_rpt_list_audit(l_rpt_idx,
					p_faaudit.*,"NO DEPR","N",err_msg) 
					#---------------------------------------------------------
					 
				END IF 
			END IF 
		END FOREACH 


		IF repstarted = "Y" THEN 
			INITIALIZE p_fabatch.* TO NULL 
			LET p_fabatch.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET p_fabatch.batch_num = this_batch 
			LET p_fabatch.year_num = w_year 
			LET p_fabatch.period_num = w_period 
			LET p_fabatch.control_asset_amt = total_asset 
			LET p_fabatch.control_depr_amt = total_depr 
			LET p_fabatch.actual_asset_amt = total_asset 
			LET p_fabatch.actual_depr_amt = total_depr 
			LET p_fabatch.post_asset_flag = "N" 
			LET p_fabatch.post_gl_flag = "N" 
			LET p_fabatch.control_line_num = curr_line_num 
			LET p_fabatch.actual_line_num = curr_line_num 
			LET p_fabatch.cleared_flag = "N" 
			LET p_fabatch.jour_num = 0 
			LET p_fabatch.com1_text = "Depreciation Calculation" 

			IF lines_inserted THEN 
				INSERT INTO fabatch VALUES (p_fabatch.*) 
			END IF 
		END IF 

		IF lines_inserted THEN 
		COMMIT WORK 
	ELSE 
		--        prompt "No batch created <Enter>" FOR CHAR ans -- albo
		LET ans = promptYN("","No batch created <Enter>","Y") -- albo 
		ROLLBACK WORK 
	END IF 


	ERROR "Check your audit REPORT FOR details of depreciation calculation" 
	SLEEP 2 

	IF lines_inserted THEN 
		CLEAR screen 
		#OPEN WINDOW showit AT 10,15 with 1 rows, 30 columns ATTRIBUTE(border)  -- alch KD-757
		DISPLAY "Posting Depreciation TO Assets" at 1,1 attribute(yellow) 
		SLEEP 2 
		#CLOSE WINDOW showit  -- alch KD-757
		CALL run_prog("FP1","p_fabatch.year_num"," p_fabatch.period_num"," p_fabatch.batch_num","") 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT FP2_rpt_list_audit
	CALL rpt_finish("FP2_rpt_list_audit")
	#------------------------------------------------------------	
 
END FUNCTION 
