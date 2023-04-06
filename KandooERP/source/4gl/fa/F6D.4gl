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
GLOBALS "../fa/F_FA_GLOBALS.4gl"
GLOBALS "../fa/F6_GROUP_GLOBALS.4gl"  
GLOBALS "../fa/F6D_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_famast RECORD LIKE famast.*, 
	pr_fastatus RECORD LIKE fastatus.*, 
	pr2_fastatus RECORD LIKE fastatus.*, 
	pr_faparms RECORD LIKE faparms.*, 
	pr_fabatch RECORD LIKE fabatch.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	query_text, 
	where_part CHAR(1200), 
	pr_output CHAR(100), 
	rpt_note CHAR(132), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_date DATE, 
	try_again LIKE language.yes_flag, 
	err_message CHAR(80), 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num, 
	pr_asset_changed SMALLINT 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("F6D") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET rpt_wid = 132 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, pr_period_num 
	OPEN WINDOW f181 with FORM "F181" -- alch kd-757 
	CALL  windecoration_f("F181") -- alch kd-757 

	MENU " Depreciation Reconciliation" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F6D","menu-depr_recon-1") -- alch kd-504 
		COMMAND "Report" " Enter selection criteria AND generate REPORT" 
			IF f6d_query(false) THEN 
				LET rpt_note = NULL 
				NEXT option "Print Manager" 
			END IF 
		COMMAND "Update" " Generate REPORT AND UPDATE database" 
			IF f6d_query(true) THEN 
				LET rpt_note = NULL 
				NEXT option "Print Manager" 
			END IF 
		ON ACTION "Print Manager" 
			#COMMAND "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 
		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
END MAIN 

FUNCTION f6d_query(update_ind) 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_prev_book_code LIKE fastatus.book_code, 
	pr_prev_cat_code LIKE famast.facat_code, 
	pr_accum_depr_amt, 
	pr_initial_depr_amt, 
	pr_total_depr_amt LIKE faaudit.depr_amt, 
	pr_actual_nbv_amt LIKE fastatus.net_book_val_amt, 
	pr_nbv_diff_amt LIKE fastatus.net_book_val_amt, 
	pr_status_ind LIKE fastatus.bal_chge_appl_flag, 
	pr_start_seq_num LIKE faaudit.status_seq_num, 
	update_ind SMALLINT, 
	pr_db_status INTEGER 

	LET msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME where_part ON fastatus.asset_code, 
	fastatus.add_on_code, 
	famast.orig_auth_code, 
	famast.acquist_date, 
	famast.faresp_code, 
	fastatus.book_code, 
	famast.facat_code, 
	famast.location_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F6D","const-fastatus-6") -- alch kd-504 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F6D_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F6D_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	

	LET query_text = 
	"SELECT fastatus.*, famast.* ", 
	"FROM fastatus, famast ", 
	"WHERE fastatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND famast.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND fastatus.asset_code = famast.asset_code ", 
	"AND fastatus.add_on_code = famast.add_on_code ", 
	"AND ",where_part clipped, 
	" ORDER BY fastatus.book_code, famast.facat_code, ", 
	"fastatus.asset_code, fastatus.add_on_code" 
	
	PREPARE s_fastatus FROM query_text 
	DECLARE c_fastatus CURSOR with HOLD FOR s_fastatus 
	LET msgresp = kandoomsg("U",1005,"") 
	#OPEN WINDOW w1 AT 10,4 with 2 rows, 60 columns
	#ATTRIBUTE(border)   -- alch KD-757
	LET pr_prev_book_code = NULL 
	LET pr_prev_cat_code = NULL 
	DISPLAY "Book Code : " at 1,1 
	DISPLAY "Category Code : " at 2,1 
	FOREACH c_fastatus INTO pr_fastatus.*, pr_famast.* 
		IF pr_prev_book_code <> pr_fastatus.book_code OR 
		pr_prev_book_code IS NULL THEN 
			DISPLAY "" at 1,13 
			DISPLAY pr_fastatus.book_code at 1,13 

			LET pr_prev_book_code = pr_fastatus.book_code 
		END IF 
		IF pr_prev_cat_code <> pr_famast.facat_code OR 
		pr_prev_cat_code IS NULL THEN 
			DISPLAY "" at 2,17 
			DISPLAY pr_famast.facat_code at 2,17 

			LET pr_prev_cat_code = pr_famast.facat_code 
		END IF 
		# Assets can be added (trans_ind = A), adjusted (trans_ind = J) OR
		# revalued (trans_ind = "V").  WHEN any of these transactions occur,
		# the depreciation amount in the faaudit RECORD represents the
		# accumulated depreciation TO date corresponding TO the net book value
		# resulting FROM the transactions.  In the CASE of revaluation,
		# depreciation IS SET TO zero AND the new net book value IS re-entered.
		# The most recent of these records IS retrieved TO get a starting value
		# FOR depreciation, THEN the subsequent depreciation transactions are
		# summed TO arrive AT the total depreciation TO date.
		SELECT max(status_seq_num) INTO pr_start_seq_num FROM faaudit 
		WHERE asset_code = pr_fastatus.asset_code 
		AND add_on_code = pr_fastatus.add_on_code 
		AND book_code = pr_fastatus.book_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_ind in ("A","J","V") 
		IF pr_start_seq_num IS NULL THEN 
			LET pr_start_seq_num = 0 
			LET pr_initial_depr_amt = 0 
		ELSE 
			SELECT depr_amt INTO pr_initial_depr_amt FROM faaudit 
			WHERE asset_code = pr_fastatus.asset_code 
			AND add_on_code = pr_fastatus.add_on_code 
			AND book_code = pr_fastatus.book_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND status_seq_num = pr_start_seq_num 
		END IF 
		SELECT sum(depr_amt) INTO pr_accum_depr_amt FROM faaudit 
		WHERE asset_code = pr_fastatus.asset_code 
		AND add_on_code = pr_fastatus.add_on_code 
		AND book_code = pr_fastatus.book_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_ind = "D" 
		AND status_seq_num > pr_start_seq_num 
		IF pr_accum_depr_amt IS NULL THEN 
			LET pr_accum_depr_amt = 0 
		END IF 
		LET pr_total_depr_amt = pr_initial_depr_amt + 
		pr_accum_depr_amt 
		LET pr_actual_nbv_amt = 
		pr_fastatus.cur_depr_cost_amt - pr_total_depr_amt 
		LET pr_nbv_diff_amt = 
		pr_fastatus.net_book_val_amt - pr_actual_nbv_amt 
		IF pr_actual_nbv_amt <> pr_fastatus.net_book_val_amt OR 
		pr_fastatus.net_book_val_amt < 0 THEN 
			LET pr_status_ind = " " 
			IF pr_fastatus.bal_chge_appl_flag <> "A" THEN 
				LET pr_status_ind = pr_fastatus.bal_chge_appl_flag 
			END IF 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT F6D_rpt_list(l_rpt_idx,
			pr_fastatus.*, pr_famast.*, 
			pr_total_depr_amt, pr_actual_nbv_amt,pr_nbv_diff_amt, 
			pr_status_ind)
			#---------------------------------------------------------
			 
			IF update_ind AND 
			(pr_nbv_diff_amt <> 0 OR pr_actual_nbv_amt < 0) THEN 
				GOTO bypass 
				LABEL recovery: 
				LET try_again = error_recover(err_message,status) 
				IF try_again != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 

				BEGIN WORK 
					DECLARE c2_fastatus CURSOR FOR 
					SELECT * FROM fastatus 
					WHERE asset_code = pr_fastatus.asset_code 
					AND add_on_code = pr_fastatus.add_on_code 
					AND book_code = pr_fastatus.book_code 
					AND seq_num = pr_fastatus.seq_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					FOR UPDATE 
					OPEN c2_fastatus 
					FETCH c2_fastatus INTO pr2_fastatus.* 
					IF pr2_fastatus.seq_num <> pr_fastatus.seq_num OR 
					pr2_fastatus.net_book_val_amt <> pr_fastatus.net_book_val_amt THEN 
						LET pr_asset_changed = true 
						ROLLBACK WORK 
					ELSE 
						# Create a single entry batch TO correct the
						# over-depreciation, IF the asset IS NOT sold OR retired
						# AND the actual net book value IS negative
						IF pr_fastatus.bal_chge_appl_flag = "A" AND 
						pr_actual_nbv_amt < 0 THEN 
							LET pr2_fastatus.seq_num = 
							pr2_fastatus.seq_num + 1 
							CALL create_fabatch(pr_actual_nbv_amt) 
							RETURNING pr_db_status 
							IF pr_db_status <> 0 THEN 
								LET status = pr_db_status 
								GO TO recovery 
							END IF 
						END IF 
						UPDATE fastatus SET net_book_val_amt = pr_actual_nbv_amt, 
						depr_amt = pr_total_depr_amt, 
						seq_num = pr2_fastatus.seq_num 
						WHERE asset_code = pr_fastatus.asset_code 
						AND add_on_code = pr_fastatus.add_on_code 
						AND book_code = pr_fastatus.book_code 
						AND seq_num = pr_fastatus.seq_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					COMMIT WORK 
				END IF 
				WHENEVER ERROR stop 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END FOREACH 
	#CLOSE WINDOW w1   -- alch KD-757

	#------------------------------------------------------------
	FINISH REPORT F6D_rpt_list
	CALL rpt_finish("F6D_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION create_fabatch(pr_nbv_amt) 
	DEFINE 
	pr_nbv_amt LIKE fastatus.net_book_val_amt 

	GOTO bypass 
	LABEL recovery: 
	RETURN status 
	LABEL bypass: 

	INITIALIZE pr_fabatch.* TO NULL 
	INITIALIZE pr_faaudit.* TO NULL 
	DECLARE c_faparms CURSOR FOR 
	SELECT * FROM faparms WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOR UPDATE 
	OPEN c_faparms 
	FETCH c_faparms INTO pr_faparms.* 
	LET pr_fabatch.batch_num = pr_faparms.next_batch_num + 1 
	UPDATE faparms SET next_batch_num = next_batch_num + 1 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_fabatch.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_fabatch.year_num = pr_year_num 
	LET pr_fabatch.period_num = pr_period_num 
	LET pr_fabatch.control_asset_amt = pr_fastatus.cur_depr_cost_amt 
	LET pr_fabatch.control_depr_amt = pr_nbv_amt 
	LET pr_fabatch.actual_asset_amt = pr_fastatus.cur_depr_cost_amt 
	LET pr_fabatch.actual_depr_amt = pr_nbv_amt 
	LET pr_fabatch.post_asset_flag = "N" 
	LET pr_fabatch.post_gl_flag = "N" 
	LET pr_fabatch.control_line_num = 1 
	LET pr_fabatch.actual_line_num = 1 
	LET pr_fabatch.cleared_flag = "N" 
	LET pr_fabatch.jour_num = 0 
	LET pr_fabatch.com1_text = "Depreciation Correction" 
	LET err_message = "F6D - inserting fabatch record" 
	INSERT INTO fabatch VALUES (pr_fabatch.*) 
	LET pr_faaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_faaudit.asset_code = pr2_fastatus.asset_code 
	LET pr_faaudit.add_on_code = pr2_fastatus.add_on_code 
	LET pr_faaudit.book_code = pr2_fastatus.book_code 
	LET pr_faaudit.year_num = pr_year_num 
	LET pr_faaudit.period_num = pr_period_num 
	LET pr_faaudit.batch_line_num = 1 
	LET pr_faaudit.trans_ind = "D" 
	LET pr_faaudit.entry_text = glob_rec_kandoouser.sign_on_code 
	LET pr_faaudit.entry_date = today 
	LET pr_faaudit.asset_amt = pr2_fastatus.cur_depr_cost_amt 
	LET pr_faaudit.depr_amt = pr_nbv_amt 
	LET pr_faaudit.net_book_val_amt = pr2_fastatus.net_book_val_amt - 
	pr_faaudit.depr_amt 
	LET pr_faaudit.rem_life_num = pr2_fastatus.rem_life_num - 1 
	LET pr_faaudit.location_code = pr_famast.location_code 
	LET pr_faaudit.faresp_code = pr_famast.faresp_code 
	LET pr_faaudit.facat_code = pr_famast.facat_code 
	LET pr_faaudit.batch_num = pr_fabatch.batch_num 
	LET pr_faaudit.status_seq_num = pr2_fastatus.seq_num 
	LET pr_faaudit.desc_text = "Depreciation Correction" 
	LET pr_faaudit.auth_code = pr_famast.orig_auth_code 
	LET pr_faaudit.salvage_amt = pr2_fastatus.salvage_amt 
	LET err_message = "F6D - inserting faaudit record" 
	INSERT INTO faaudit VALUES (pr_faaudit.*) 
	WHENEVER ERROR stop 
	RETURN 0 
END FUNCTION 


###########################################################################
# REPORT F6D_rpt_list(p_rpt_idx,pr_fastatus,pr_famast,pr_total_depr_amt, pr_actual_nbv_amt,pr_nbv_diff_amt,pr_status_ind)
#
#
###########################################################################
REPORT F6D_rpt_list(p_rpt_idx,pr_fastatus,pr_famast,pr_total_depr_amt, pr_actual_nbv_amt,pr_nbv_diff_amt,pr_status_ind) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_fastatus RECORD LIKE fastatus.*, 
	pr_famast RECORD LIKE famast.*, 
	pr_total_depr_amt LIKE faaudit.depr_amt, 
	pr_actual_nbv_amt LIKE fastatus.net_book_val_amt, 
	pr_nbv_diff_amt LIKE fastatus.net_book_val_amt, 
	pr_status_ind LIKE fastatus.bal_chge_appl_flag, 
	pr_book_text LIKE fabook.book_text, 
	pr_facat_text LIKE facat.facat_text, 
	line1, line2 CHAR(132), 
	offset1,offset2 SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_fastatus.book_code, 
	pr_famast.facat_code, 
	pr_fastatus.asset_code, 
	pr_fastatus.add_on_code 
	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code,2 spaces,pr_company.name_text 
			IF rpt_note IS NULL THEN 
				LET rpt_note = "Asset Depreciation Reconciliation Report" 
			END IF 
			LET line2 = rpt_note clipped," (Menu - F6D)" 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 
			PRINT COLUMN 1,today USING "dd/mm/yy", 
			COLUMN offset1, line1 clipped, 
			COLUMN 118,"Page : ", pageno USING "<<<<" 
			PRINT COLUMN offset2, line2 clipped 

			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
			PRINT COLUMN 1,"Asset Code", 
			COLUMN 12,"Description", 
			COLUMN 43,"Location", 
			COLUMN 54,"Original Cost", 
			COLUMN 68,"Net Book Value", 
			COLUMN 84,"Depreciation" , 
			COLUMN 100,"Actual NBV", 
			COLUMN 115,"Difference", 
			COLUMN 127, "Status" 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
		BEFORE GROUP OF pr_fastatus.book_code 
			SKIP TO top OF PAGE 
			LET pr_book_text = NULL 
			SELECT book_text INTO pr_book_text FROM fabook 
			WHERE book_code = pr_fastatus.book_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 1, "Book ", pr_fastatus.book_code, " : ", 
			pr_book_text 
		BEFORE GROUP OF pr_famast.facat_code 
			SKIP 1 line 
			LET pr_facat_text = NULL 
			SELECT facat_text INTO pr_facat_text FROM facat 
			WHERE facat_code = pr_famast.facat_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 1, "Category ", pr_famast.facat_code clipped, 
			" : ", pr_facat_text 
			SKIP 1 line 
		ON EVERY ROW 
			NEED 2 LINES 
			PRINT COLUMN 1, pr_fastatus.asset_code, 
			COLUMN 12, pr_famast.desc_text[1,30], 
			COLUMN 43, pr_famast.location_code, 
			COLUMN 54, pr_fastatus.cur_depr_cost_amt 
			USING "--,---,--&.&&", 
			COLUMN 69, pr_fastatus.net_book_val_amt 
			USING "--,---,--&.&&", 
			COLUMN 83, pr_total_depr_amt 
			USING "--,---,--&.&&", 
			COLUMN 97, pr_actual_nbv_amt 
			USING "--,---,--&.&&", 
			COLUMN 112, pr_nbv_diff_amt USING "--,---,--&.&&", 
			COLUMN 129, pr_status_ind 
		AFTER GROUP OF pr_famast.facat_code 
			SKIP 1 LINES 
			PRINT COLUMN 54, "-------------", 
			COLUMN 69, "-------------", 
			COLUMN 83, "-------------", 
			COLUMN 97, "-------------", 
			COLUMN 112, "-------------" 
			PRINT COLUMN 1, "Category ",pr_famast.facat_code," : Totals", 
			COLUMN 54, GROUP sum(pr_fastatus.cur_depr_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 69, GROUP sum(pr_fastatus.net_book_val_amt) 
			USING "--,---,--&.&&", 
			COLUMN 83, GROUP sum (pr_total_depr_amt) 
			USING "--,---,--&.&&", 
			COLUMN 97, GROUP sum (pr_actual_nbv_amt) 
			USING "--,---,--&.&&", 
			COLUMN 112, GROUP sum (pr_nbv_diff_amt) 
			USING "--,---,--&.&&" 
		AFTER GROUP OF pr_fastatus.book_code 
			SKIP 1 LINES 
			PRINT COLUMN 54, "-------------", 
			COLUMN 69, "-------------", 
			COLUMN 83, "-------------", 
			COLUMN 97, "-------------", 
			COLUMN 112, "-------------" 
			PRINT COLUMN 1, "Book ",pr_fastatus.book_code," : Totals", 
			COLUMN 54, GROUP sum(pr_fastatus.cur_depr_cost_amt) 
			USING "--,---,--&.&&", 
			COLUMN 69, GROUP sum(pr_fastatus.net_book_val_amt) 
			USING "--,---,--&.&&", 
			COLUMN 83, GROUP sum (pr_total_depr_amt) 
			USING "--,---,--&.&&", 
			COLUMN 97, GROUP sum (pr_actual_nbv_amt) 
			USING "--,---,--&.&&", 
			COLUMN 112, GROUP sum (pr_nbv_diff_amt) 
			USING "--,---,--&.&&" 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
