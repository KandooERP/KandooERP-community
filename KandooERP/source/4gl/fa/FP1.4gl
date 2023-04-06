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

# Purpose    :    Post the batches back INTO famast AND fastatus

GLOBALS 

	DEFINE 
	try_again CHAR(1), 
	err_message CHAR(60), 
	compname CHAR(30), 
	tempper SMALLINT, 
	fisc_year SMALLINT, 
	where_text CHAR(700), 
	query_text CHAR(800), 
	counter SMALLINT, 
	runner CHAR(256), 

	pr_output CHAR(60), 
	bbatch INTEGER, 
	ebatch INTEGER, 
	bd_rowid INTEGER, 
	bh_rowid INTEGER, 

	p_fastatus RECORD LIKE fastatus.*, 
	p_famast RECORD LIKE famast.*, 
	pr_famast RECORD LIKE famast.*, 
	p_fabatch RECORD LIKE fabatch.*, 
	p_faaudit RECORD LIKE faaudit.*, 
	p_fabookdep RECORD LIKE fabookdep.*, 
	p_fadepmethod RECORD LIKE fadepmethod.*, 
	kandoouser_trn RECORD LIKE kandoouser.*, 
	pr_period RECORD LIKE period.*, 
	pa_period array[301] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD, 

	pr_faparms RECORD LIKE faparms.*, 
	pr_fabatch RECORD LIKE fabatch.*, 
	ans CHAR(1), 
	val1,val2,val3 INTEGER, 
	tmp_faaudit RECORD LIKE faaudit.* 
END GLOBALS 
DEFINE modu_rpt_idx SMALLINT

MAIN 
	#Initial UI Init
	CALL setModuleId("FP1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET val1 = arg_val(1) 
	LET val2 = arg_val(2) 
	LET val3 = arg_val(3) 

	SELECT name_text 
	INTO compname 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF (val1 IS NOT null) AND (val2 IS NOT null) 
	AND (val3 IS NOT null) THEN 
		LET fisc_year = val1 
		LET tempper = val2 
		LET bbatch = val3 
		LET ebatch = val3 
		UPDATE fabatch SET cleared_flag = "Y" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batch_num = ebatch 
		AND year_num = fisc_year 
		AND period_num = tempper 
		CALL post_batches() 
	ELSE 
		WHILE (true) 
			IF int_flag OR quit_flag THEN 
				EXIT program 
			END IF 
			CALL get_info() 
		END WHILE 
	END IF 

END MAIN 

FUNCTION get_info() 
	OPEN WINDOW wf157 with FORM "F157" -- alch kd-757 
	CALL  windecoration_f("F157") -- alch kd-757 
	MESSAGE "Enter selection - ESC TO search" attribute (yellow) 
	CONSTRUCT BY NAME where_text ON 
	year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","FP1","const-year_num-3") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 

	LET query_text = "SELECT unique year_num, period_num ", 
	"FROM fabatch ", 
	"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND post_asset_flag = \"N\" ", 
	"AND ",where_text clipped," ", 
	"ORDER BY year_num , period_num " 

	PREPARE getper FROM query_text 
	DECLARE c_per CURSOR FOR getper 

	LET counter = 0 
	FOREACH c_per INTO pr_period.year_num, pr_period.period_num 
		LET counter = counter + 1 
		LET pa_period[counter].year_num = pr_period.year_num 
		LET pa_period[counter].period_num = pr_period.period_num 
		IF counter > 300 THEN 
			MESSAGE "Only first 300 selected" 
			attribute (yellow) 
			SLEEP 3 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(counter) 


	IF counter = 0 THEN 
		MESSAGE "No batches TO post FOR year/period entered" 
		attribute (yellow) 
		ERROR "ESC TO reselect, DEL TO EXIT" 
	ELSE 
		MESSAGE "Press RETURN on line TO post, CTRL-V TO view" 
		attribute (yellow) 
	END IF 
	DISPLAY ARRAY pa_period TO sr_period.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","FP1","display-arr-fabatch") 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
		ON KEY (control-v) 
			IF counter != 0 THEN 
				LET counter = arr_curr() 
				LET query_text = " SELECT * FROM fabatch ", 
				"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND year_num = ", pa_period[counter].year_num, 
				" AND period_num = ", pa_period[counter].period_num, 
				" AND post_asset_flag = 'N' ", 
				" ORDER BY jour_num, batch_num " 
				CALL run_prog("FBC",query_text clipped,"","","") 
			END IF 
		ON KEY (control-m) 
			IF counter != 0 THEN 
				LET counter = arr_curr() 
				LET tempper = pa_period[counter].period_num 
				LET fisc_year = pa_period[counter].year_num 
				CALL post_what_jour() 
				CALL post_batches() 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END DISPLAY 


	CLOSE WINDOW wf157 

END FUNCTION 

FUNCTION post_what_jour() 

	#OPEN WINDOW getinfo AT 12,5 with 1 rows, 68 columns
	#attribute (border, reverse, MESSAGE line last)  -- alch KD-757

	--    prompt "Enter beginning batch number OR RETURN FOR all: "  -- albo
	--       FOR bbatch
	LET bbatch = promptInput("Enter beginning batch number OR RETURN FOR all: ","",11) -- albo 

	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 

	IF bbatch IS NULL THEN 
		LET bbatch = 0 
		LET ebatch = 999999999 
	ELSE 
		--       prompt "Enter ending batch number OR RETURN FOR last: "  -- albo
		--          FOR ebatch
		LET ebatch = promptInput("Enter ending batch number OR RETURN FOR last: ","",11) -- albo 
		IF int_flag OR quit_flag THEN 
			EXIT program 
		END IF 
		IF ebatch IS NULL THEN 
			LET ebatch = 999999999 
		END IF 
	END IF 

	#CLOSE WINDOW getinfo  -- alch KD-757

END FUNCTION 

FUNCTION post_batches() 
	DEFINE modu_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	proceed CHAR(1), 
	doit CHAR(1), 
	trans_select CHAR(1), 
	cnt1 SMALLINT, 
	fixprob CHAR(1), 
	mess_prompt CHAR(60) -- albo 


	#------------------------------------------------------------
	LET modu_rpt_idx = rpt_start(getmoduleid(),"FP1_rpt_list_audit","N/A", RPT_SHOW_RMS_DIALOG)
	IF modu_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT FP1_rpt_list_audit TO rpt_get_report_file_with_path2(modu_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].report_width_num
	--LET where_part = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].sel_text
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


		SELECT * 
		INTO pr_faparms.* 
		FROM faparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status THEN 
			ERROR "Fixed asset parameters NOT found - Use FZP" 
			SLEEP 2 
			EXIT program 
		END IF 

		# IF they are using clearance - warn them IF batches won't be posted
		IF pr_faparms.use_clear_flag = "Y" THEN 
			DECLARE check_curs1 CURSOR FOR 
			SELECT rowid 
			FROM fabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cleared_flag != "Y" 
			AND fabatch.year_num = fisc_year 
			AND fabatch.period_num = tempper 
			AND fabatch.batch_num between bbatch AND ebatch 
			AND fabatch.post_asset_flag = "N" 
			OPEN check_curs1 
			FETCH check_curs1 
			IF NOT status THEN 
				#OPEN WINDOW wcheck_1 AT 11,10 with 1 rows, 50 columns
				#ATTRIBUTE(border)  -- alch KD-757

				--            prompt "Batches exist that are NOT cleared. Clear (y/n) "  -- albo
				--                FOR CHAR ans
				LET ans = promptYN("","Batches exist that are NOT cleared. Clear (y/n) ","Y") -- albo 
				#CLOSE WINDOW wcheck_1  -- alch KD-757
				IF ans matches "[Yy]" THEN 
					LET query_text = " SELECT * FROM fabatch ", 
					"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
					"AND year_num = ", fisc_year, 
					" AND period_num = ", tempper, 
					" AND post_asset_flag = 'N' ", 
					" ORDER BY jour_num, batch_num " 
					CALL run_prog("FBC",query_text,"","","") 
				END IF 
			END IF 
		END IF 


		# IF they are using control totals
		# warn them IF batches don't balance
		IF pr_faparms.control_tot_flag = "Y" THEN 
			DECLARE check_curs2 CURSOR FOR 
			SELECT * 
			INTO pr_fabatch.* 
			FROM fabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND fabatch.year_num = fisc_year 
			AND fabatch.period_num = tempper 
			AND (control_asset_amt != actual_asset_amt 
			OR control_depr_amt != actual_depr_amt 
			OR control_line_num != actual_line_num) 
			AND fabatch.batch_num between bbatch AND ebatch 
			AND fabatch.post_asset_flag = "N" 
			OPEN check_curs2 
			FETCH check_curs2 
			IF NOT status THEN 
				#OPEN WINDOW wcheck_2 AT 11,10 with 1 rows, 50 columns
				#ATTRIBUTE(border)  -- alch KD-757

				--            prompt "Batches exist that are NOT balanced. Edit (y/n) "
				--                FOR CHAR ans
				LET ans = promptYN("","Batches exist that are NOT balanced. Edit (y/n) ","Y") -- albo 
				#CLOSE WINDOW wcheck_2  -- alch KD-757
				IF ans matches "[Yy]" THEN 
					FOREACH check_curs2 
						CALL run_prog("F28","pr_fabatch.batch_num","pr_fabatch.year_num","pr_fabatch.period_num","") 
					END FOREACH 
				END IF 
			END IF 
		END IF 

		LOCK TABLE fabatch in share MODE 
		LOCK TABLE faaudit in share MODE 
		LOCK TABLE faparms in share MODE 

		FOR cnt1 = 1 TO 9 
			CASE cnt1 
				WHEN 1 
					LET trans_select = "A" {addition} 
				WHEN 2 
					LET trans_select = "V" {revaluation} 
				WHEN 3 
					LET trans_select = "J" {adjustment} 
				WHEN 4 
					LET trans_select = "L" {life adjustment} 
				WHEN 5 
					LET trans_select = "T" {internal transfer} 
				WHEN 6 
					LET trans_select = "S" {sale} 
				WHEN 7 
					LET trans_select = "R" {retirement} 
				WHEN 8 
					LET trans_select = "D" {depreciation} 
				WHEN 9 
					LET trans_select = "C" {depn code change} 
			END CASE 

			# Cursor FOR the batch table

			DECLARE batch_curs CURSOR FOR 
			SELECT unique fabatch.* 
			INTO p_fabatch.* 
			FROM fabatch,faaudit 
			WHERE fabatch.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND fabatch.post_asset_flag = "N" 
			AND ((pr_faparms.use_clear_flag = "Y" AND 
			fabatch.cleared_flag = "Y") 
			OR pr_faparms.use_clear_flag != "Y") 
			AND ((pr_faparms.control_tot_flag = "Y" 
			AND (control_asset_amt = actual_asset_amt) 
			AND (control_depr_amt = actual_depr_amt) 
			AND (control_line_num = actual_line_num)) OR 
			(pr_faparms.control_tot_flag != "Y")) 
			AND fabatch.year_num = fisc_year 
			AND fabatch.period_num = tempper 
			AND fabatch.cmpy_code = faaudit.cmpy_code 
			AND fabatch.batch_num = faaudit.batch_num 
			AND faaudit.trans_ind = trans_select 
			AND fabatch.batch_num between bbatch AND ebatch 

			# Cursor FOR the audit (transaction table)
			DECLARE audit_curs CURSOR FOR 
			SELECT rowid, * 
			INTO bd_rowid, p_faaudit.* 
			FROM faaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = fisc_year 
			AND period_num = tempper 
			AND batch_num = p_fabatch.batch_num 


			#     Loop thru the batches AND write data INTO
			#     famast AND fastatus

			FOREACH batch_curs 

				DISPLAY " " at 2,1 
				DISPLAY "Processing Batch : ",p_fabatch.batch_num at 2,1 
				attribute (yellow) 



				#  .....AND loop thru the lines FOR the batch AND UPDATE.....

				FOREACH audit_curs 

					# check IF the asset has been sold OR retired
					CASE p_faaudit.trans_ind 
						WHEN "S" {this IS a sale line} 
							SELECT bal_chge_appl_flag 
							FROM fastatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = p_faaudit.asset_code 
							AND add_on_code = p_faaudit.add_on_code 
							AND book_code = p_faaudit.book_code 
							AND bal_chge_appl_flag = "R" 
							IF NOT status THEN 
								MESSAGE "Asset :",p_fabookdep.asset_code clipped, 
								" has been retired" 
								CONTINUE FOREACH 
							END IF 
						WHEN "R" {is IS a retirement} 
							SELECT bal_chge_appl_flag 
							FROM fastatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = p_faaudit.asset_code 
							AND add_on_code = p_faaudit.add_on_code 
							AND book_code = p_faaudit.book_code 
							AND bal_chge_appl_flag = "S" 
							IF NOT status THEN 
								MESSAGE "Asset :",p_fabookdep.asset_code clipped, 
								" has been sold" 
								CONTINUE FOREACH 
							END IF 
						OTHERWISE 
							SELECT bal_chge_appl_flag 
							FROM fastatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = p_faaudit.asset_code 
							AND add_on_code = p_faaudit.add_on_code 
							AND book_code = p_faaudit.book_code 
							AND (bal_chge_appl_flag = "S" OR 
							bal_chge_appl_flag = "R") 
							IF NOT status THEN 
								MESSAGE "Asset :",p_fabookdep.asset_code clipped, 
								" sold/retired" 
								CONTINUE FOREACH 
							END IF 
					END CASE 

					DISPLAY " " at 3,1 
					DISPLAY "Line Number : ", p_faaudit.batch_line_num at 3,1 
					attribute (yellow) 
					CASE p_faaudit.trans_ind 
						WHEN "A" 
							CALL add_trans("Y") RETURNING proceed 
						WHEN "J" 
							CALL adj_trans("Y") RETURNING proceed 
						WHEN "T" 
							CALL tr_trans("Y") RETURNING proceed 
						WHEN "R" 
							CALL ret_trans("Y") RETURNING proceed 
						WHEN "L" 
							CALL life_adj("Y") RETURNING proceed 
						WHEN "I" 
							CALL add_trans("Y") RETURNING proceed 
						WHEN "S" 
							CALL sell_trans("Y") RETURNING proceed 
						WHEN "D" {depreciation} 
							CALL depr_trans() 
							LET proceed = "Y" 

						WHEN "V" {asset revaluation} 
							CALL rev_trans("Y") RETURNING proceed 

						WHEN "C" {depn code change} 
							CALL dcode_trans("Y") RETURNING proceed 
					END CASE 
					IF proceed = "Y" THEN 
						UPDATE fabatch 
						SET post_asset_flag = "Y" 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND batch_num = p_fabatch.batch_num 
					ELSE 
						#OPEN WINDOW showit AT 10,15 with 1 rows, 55 columns  -- alch KD-757
						--                    prompt "Batch ",p_fabatch.batch_num," could NOT be posted ",
						--                           "<Enter>"
						--                           FOR CHAR ans
						LET mess_prompt = "Batch ",p_fabatch.batch_num," could NOT be posted ","<Enter>" 
						LET ans = promptInput(mess_prompt,"",1) -- albo 
						#CLOSE WINDOW showit  -- alch KD-757
					END IF 
				END FOREACH 
			END FOREACH 
		END FOR 
		#CLOSE WINDOW w2  -- alch KD-757

		#OPEN WINDOW w1 AT 12,14 with 1 rows, 44 columns
		#ATTRIBUTE(white,border)  -- alch KD-757

		--    prompt "RETURN TO accept posting, DEL TO cancel" FOR CHAR doit -- albo
		LET doit = promptInput("RETURN TO accept posting, BREAK TO cancel","",1) -- albo 
		#CLOSE WINDOW w1  -- alch KD-757
		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			ROLLBACK WORK 
		ELSE 
		COMMIT WORK 
	END IF 

	WHENEVER ERROR stop 
	#------------------------------------------------------------
	FINISH REPORT FP1_rpt_list_audit
	CALL rpt_finish("FP1_rpt_list_audit")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 



# Add a specific book TO the fastatus table.


# Values of dowhat:
# note that only the "Y" IS used currently
#     C - Check that the row IS valid OR NOT do NOT PRINT
#     Y - Do everything including PRINT
#     N - (Asset/Book already added) Just PRINT the RECORD - no UPDATE
#     I - (Loc, resp, OR cat do NOT agree with famast)
#         Just PRINT the RECORD - no UPDATE

FUNCTION add_trans(dowhat) 

	DEFINE dowhat CHAR(1) 


	IF p_faaudit.book_code IS NULL THEN 
		ERROR "FATAL ERROR : book code IS blank in transaction record" 
		SLEEP 10 
		ERROR "CONTACT YOUR SUPPORT ORGANISATION" 
		SLEEP 5 
	END IF 


	SELECT * 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status <> notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" {line IS NOT valid} 
		ELSE 

			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, "Error: Asset/Book already exists",glob_rec_kandoouser.cmpy_code, compname, dowhat)  
			#---------------------------------------------------------		

			RETURN "Y" {no UPDATE but still flag as posted} 
		END IF 
	ELSE 
		SELECT * 
		INTO pr_famast.* 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = p_faaudit.asset_code 
		AND add_on_code = p_faaudit.add_on_code 


		# check the asset category TO see IF the asset IS depreciable
		SELECT deprec_flag 
		FROM facat 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND facat_code = p_faaudit.facat_code 
		AND deprec_flag = "N" 

		IF status THEN 
			SELECT * 
			INTO p_fabookdep.* 
			FROM fabookdep 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
			IF status THEN 
				ERROR "FATAL ERROR book/rate (F1B) NOT found asset ", 
				p_faaudit.asset_code," add on ",p_faaudit.add_on_code, 
				" book : ",p_faaudit.book_code 
				SLEEP 10 
				ROLLBACK WORK 
				EXIT program 
			END IF 
		ELSE 
			INITIALIZE p_fabookdep.* TO NULL 
		END IF 

		IF dowhat = "Y" THEN 
			LET p_fastatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET p_fastatus.asset_code = p_faaudit.asset_code 
			LET p_fastatus.add_on_code = p_faaudit.add_on_code 
			LET p_fastatus.book_code = p_faaudit.book_code 

			# addition always creates seq 1 in faaudit
			LET p_fastatus.seq_num = 1 
			LET p_fastatus.depr_code = p_fabookdep.depn_code 
			LET p_fastatus.purchase_date = pr_famast.acquist_date 
			LET p_fastatus.last_depr_year_num = 0 
			LET p_fastatus.last_depr_per_num = 0 
			LET p_fastatus.life_period_num = p_faaudit.rem_life_num 
			LET p_fastatus.rem_life_num = p_faaudit.rem_life_num 
			LET p_fastatus.cur_depr_cost_amt = pr_famast.orig_cost_amt 
			LET p_fastatus.depr_amt = p_faaudit.depr_amt 
			LET p_fastatus.net_book_val_amt = p_faaudit.net_book_val_amt 
			LET p_fastatus.salvage_amt = p_faaudit.salvage_amt 
			LET p_fastatus.priv_use_per = 0 
			LET p_fastatus.accum_priv_amt = 0 
			LET p_fastatus.bal_chge_appl_flag = "A" #bal charge applied flag 
			LET p_fastatus.bal_chge_amt = 0 #bal charge amount 
			LET p_fastatus.bal_chg_app_code = "" #bal charge applied code 
			LET p_fastatus.sale_amt = p_faaudit.sale_amt 

			INSERT INTO fastatus VALUES (p_fastatus.*) 

			# store the original life in periods FOR
			# depreciation calculations
			UPDATE famast 
			SET famast.location_code = p_faaudit.location_code, 
			famast.facat_code = p_faaudit.facat_code, 
			famast.faresp_code = p_faaudit.faresp_code, 
			famast.orig_life_num = p_faaudit.rem_life_num, 
			famast.orig_auth_code = p_faaudit.auth_code 
			WHERE famast.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND famast.asset_code = p_faaudit.asset_code 
			AND famast.add_on_code = p_faaudit.add_on_code 

		END IF 

		IF dowhat <> "C" THEN 
			CASE dowhat 
				WHEN "Y" 
					#---------------------------------------------------------
					OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
					p_faaudit.*, "Posted", glob_rec_kandoouser.cmpy_code, compname, dowhat)   
					#---------------------------------------------------------		
				
				WHEN "N" 
					#---------------------------------------------------------
					OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
					p_faaudit.*, "O.K but NOT posted", glob_rec_kandoouser.cmpy_code, compname, dowhat)   
					#---------------------------------------------------------		

				WHEN "I" 
					#---------------------------------------------------------
					OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
					p_faaudit.*, "Loc/Resp/Cat inconsistent with master file", glob_rec_kandoouser.cmpy_code, compname, dowhat)   
					#---------------------------------------------------------		

			END CASE 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		IF pr_famast.location_code <> p_faaudit.location_code OR 
		pr_famast.faresp_code <> p_faaudit.faresp_code OR 
		pr_famast.facat_code <> p_faaudit.facat_code THEN 
			RETURN "I" # line IS NOT valid 
		ELSE 
			RETURN "Y" 
		END IF 
	ELSE 
		RETURN "Y" 
	END IF 

END FUNCTION 


# Adjust the value of an asset/book in the fastatus table


FUNCTION adj_trans(dowhat) 
	DEFINE dowhat CHAR(1) 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 

			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*,"Error: Asset/Book does NOT exist",	glob_rec_kandoouser.cmpy_code, compname, dowhat)   
			#---------------------------------------------------------		
			 
			RETURN "N" {don't UPDATE post flag - they may add AND repost} 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 

			# fastatus UPDATE
			LET p_fastatus.cur_depr_cost_amt = p_fastatus.cur_depr_cost_amt + 
			p_faaudit.asset_amt 

			LET p_fastatus.depr_amt = p_fastatus.depr_amt + p_faaudit.depr_amt 

			LET p_fastatus.net_book_val_amt = p_fastatus.cur_depr_cost_amt - 
			p_fastatus.depr_amt 

			LET p_fastatus.salvage_amt = p_fastatus.salvage_amt + 
			p_faaudit.salvage_amt 

			# salvage amount cannot be SET TO < 0
			IF p_fastatus.salvage_amt < 0 THEN 
				LET p_fastatus.salvage_amt = 0 
			END IF 

			UPDATE fastatus 
			SET cur_depr_cost_amt = p_fastatus.cur_depr_cost_amt, 
			depr_amt = p_fastatus.depr_amt, 
			net_book_val_amt = p_fastatus.net_book_val_amt, 
			salvage_amt = p_fastatus.salvage_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 

		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", glob_rec_kandoouser.cmpy_code, compname, dowhat)    
				#---------------------------------------------------------		
				RETURN "Y" 
			ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "O.K but NOT posted", glob_rec_kandoouser.cmpy_code, compname, dowhat)    
				#---------------------------------------------------------		
				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 



# Revalue a certain asset/book in the fastatus table


FUNCTION rev_trans(dowhat) 
	DEFINE dowhat CHAR(1) 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, "Error: Asset/Book does NOT exist",glob_rec_kandoouser.cmpy_code, compname, dowhat)  
			#---------------------------------------------------------		
		
			RETURN "N" {don't UPDATE post flag - they may add AND repost} 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 
			# fastatus UPDATE

			LET p_fastatus.net_book_val_amt = p_faaudit.asset_amt 
			LET p_fastatus.cur_depr_cost_amt = p_faaudit.asset_amt 
			LET p_fastatus.depr_amt = 0 

			UPDATE fastatus 
			SET cur_depr_cost_amt = p_fastatus.cur_depr_cost_amt, 
			net_book_val_amt = p_fastatus.net_book_val_amt, 
			depr_amt = p_fastatus.depr_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 
		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, "Posted", 
			glob_rec_kandoouser.cmpy_code, compname, dowhat)   
			#---------------------------------------------------------		
				RETURN "Y" 
			ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, 
			"O.K but NOT posted", 
			glob_rec_kandoouser.cmpy_code, compname, dowhat) 
			#---------------------------------------------------------		
				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Transfer an asset TO another location/category


FUNCTION tr_trans(dowhat) 
	DEFINE dowhat CHAR(1), 
	tmp_depn_code LIKE fadepmethod.depn_code 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
		p_faaudit.*, 
		"Error: Asset/Book does NOT exist", 
		glob_rec_kandoouser.cmpy_code, compname, dowhat) 
		#---------------------------------------------------------	
		RETURN "N" 
	ELSE 
		IF dowhat = "Y" THEN 

			# don't UPDATE using the FROM part
			IF p_faaudit.desc_text != "Transfer - FROM" THEN 

				SELECT deprec_flag 
				FROM facat 
				WHERE facat.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat.facat_code = p_faaudit.facat_code 
				AND facat.deprec_flag = "N" 

				IF status THEN 
					# check that fastatus has a depreciation code
					SELECT depr_code 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = p_faaudit.asset_code 
					AND add_on_code = p_faaudit.add_on_code 
					AND book_code = p_faaudit.book_code 
					AND depr_code IS NOT NULL 
					IF status THEN 
						ERROR "No depreciation code FOR destination ", 
						"category : ",p_faaudit.facat_code 
						SLEEP 2 
						OPEN WINDOW w184 with FORM "F184" -- alch kd-757 
						CALL  windecoration_f("F184") -- alch kd-757 

						DISPLAY "Asset : ",p_faaudit.asset_code clipped at 1,1 
						attribute(yellow) 
						DISPLAY "Add on : ",p_faaudit.add_on_code clipped, 
						" Book : ",p_faaudit.book_code at 2,1 
						attribute(yellow) 
						INPUT tmp_depn_code FROM depn_code 
							BEFORE INPUT 
								CALL publish_toolbar("kandoo","FP1","inp-tmp_depn_code-1") -- alch kd-504 
	
							ON ACTION "LOOKUP" infield (depn_code)  
									LET tmp_depn_code = lookup_dep_code(glob_rec_kandoouser.cmpy_code) 
									DISPLAY tmp_depn_code TO depn_code 
									NEXT FIELD depn_code 

							AFTER INPUT 
								IF not(int_flag OR quit_flag) THEN 
									IF tmp_depn_code IS NULL THEN 
										ERROR "You must enter a valid code" 
										NEXT FIELD depn_code 
									ELSE 
										SELECT depn_code 
										FROM fadepmethod 
										WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
										AND depn_code = tmp_depn_code 
										IF status THEN 
											ERROR "Depreciation code NOT valid" 
											NEXT FIELD depn_code 
										END IF 
									END IF 
								END IF 
							ON KEY (control-w) 
								CALL kandoohelp("") 
							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
						END INPUT 
						CLOSE WINDOW w184 
						IF int_flag OR quit_flag THEN 
							ERROR "Aborting program ... " 
							SLEEP 2 
							ROLLBACK WORK 
							EXIT program 
						END IF 
						UPDATE fastatus SET depr_code = tmp_depn_code 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND asset_code = p_faaudit.asset_code 
						AND add_on_code = p_faaudit.add_on_code 
						AND book_code = p_faaudit.book_code 
					END IF 
				END IF 


				UPDATE famast SET location_code = p_faaudit.location_code, 
				facat_code = p_faaudit.facat_code, 
				faresp_code = p_faaudit.faresp_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = p_faaudit.asset_code 
				AND add_on_code = p_faaudit.add_on_code 

				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	
				
			END IF 
			RETURN "Y" 
		ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, 
				"O.K but NOT posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat)  
				#---------------------------------------------------------	
 
			RETURN "N" 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Retire an asset/book


FUNCTION ret_trans(dowhat) 
	DEFINE dowhat CHAR(1) 

	SELECT * 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, 
				"Error: Asset/Book does NOT exist", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	

			RETURN "N" 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 
			# SET fastatus TO retired
			UPDATE fastatus SET bal_chge_appl_flag = "R" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 
		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	
			
				RETURN "Y" 
			ELSE 

				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, 
				"O.K but NOT posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	

				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Transfer an asset/book TO another asset/book


FUNCTION sell_trans(dowhat) 
	DEFINE dowhat CHAR(1) 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, 
			"Error: Asset/Book does NOT exist", 
			glob_rec_kandoouser.cmpy_code, compname, dowhat) 
			#---------------------------------------------------------	
			RETURN "N" 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 
			UPDATE fastatus SET bal_chge_appl_flag = "S", 
			sale_amt = p_faaudit.sale_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 
		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	
				RETURN "Y" 
			ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, 
				"O.K but NOT posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	

				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Adjust the life of an asset


FUNCTION life_adj(dowhat) 

	DEFINE 
	dowhat CHAR(1) 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, 
			"Error: Asset/Book does NOT exist", 
			glob_rec_kandoouser.cmpy_code, compname, dowhat)  
			#---------------------------------------------------------	

			RETURN "N" 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 
			# both original life periods AND remaining life periods are
			# updated since a change in life periods affects both
			# straight line AND diminishing calculations
			LET p_fastatus.life_period_num = p_fastatus.life_period_num + 
			(p_faaudit.rem_life_num - 
			p_fastatus.rem_life_num) 
			UPDATE fastatus SET rem_life_num = p_faaudit.rem_life_num, 

			life_period_num = p_fastatus.life_period_num 

			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 
		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	
				RETURN "Y" 
			ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "O.K but NOT posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------
				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Change the depreciation code of an asset/book


FUNCTION dcode_trans(dowhat) 

	DEFINE 
	dowhat CHAR(1), 
	dpn_code LIKE fabookdep.depn_code 

	IF status = notfound THEN 
		IF dowhat = "C" THEN 
			RETURN "N" #batch failed in CHECK mode. 
		ELSE 
			#---------------------------------------------------------
			OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
			p_faaudit.*, "Error: Asset/Book does NOT exist", 
			glob_rec_kandoouser.cmpy_code, compname, dowhat) 
			#---------------------------------------------------------		
			RETURN "N" 
		END IF 
	ELSE 
		IF dowhat = "Y" THEN 
			LET dpn_code = p_faaudit.desc_text[27,29] 
			UPDATE fabookdep SET depn_code = dpn_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
			UPDATE fastatus SET depr_code = dpn_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_faaudit.asset_code 
			AND add_on_code = p_faaudit.add_on_code 
			AND book_code = p_faaudit.book_code 
		END IF 
		IF dowhat <> "C" THEN 
			IF dowhat = "Y" THEN 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, "Posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------		
				RETURN "Y" 
			ELSE 
				#---------------------------------------------------------
				OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
				p_faaudit.*, 
				"O.K but NOT posted", 
				glob_rec_kandoouser.cmpy_code, compname, dowhat) 
				#---------------------------------------------------------	
			
				RETURN "N" 
			END IF 
		END IF 
	END IF 

	IF dowhat = "C" THEN 
		RETURN "Y" 
	END IF 
END FUNCTION 


# Calculates depreciation of a certain asset


FUNCTION depr_trans() 

	SELECT * 
	INTO p_fastatus.* 
	FROM fastatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	IF status = notfound THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
		p_faaudit.*, "Asset STATUS NOT found", 
		glob_rec_kandoouser.cmpy_code, compname, "Y") 
		#---------------------------------------------------------	
		RETURN 
	END IF 

	SELECT * 
	INTO p_fabookdep.* 
	FROM fabookdep 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 
	IF status = notfound THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
		p_faaudit.*, "Dep code NOT found", 
		glob_rec_kandoouser.cmpy_code, compname, "Y")
		#---------------------------------------------------------	

		RETURN 
	END IF 

	SELECT * 
	INTO p_fadepmethod.* 
	FROM fadepmethod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND depn_code = p_fabookdep.depn_code 

	IF status = notfound THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
		p_faaudit.*, "Dep method NOT found", 
		glob_rec_kandoouser.cmpy_code, compname, "Y") 
		#---------------------------------------------------------	
		RETURN 
	END IF 


	SELECT * 
	INTO p_famast.* 
	FROM famast 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_fastatus.asset_code 
	AND add_on_code = p_fastatus.add_on_code 
	IF status = notfound THEN 
		#---------------------------------------------------------
		OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
		p_faaudit.*, "Asset Master NOT found", 
		glob_rec_kandoouser.cmpy_code, compname, "Y") 
		#---------------------------------------------------------	
		RETURN 
	END IF 



	LET p_fastatus.depr_code = p_fadepmethod.depn_code 
	LET p_fastatus.last_depr_year_num = p_faaudit.year_num 
	LET p_fastatus.last_depr_per_num = p_faaudit.period_num 
	LET p_fastatus.rem_life_num = p_faaudit.rem_life_num 

	LET p_fastatus.depr_amt = p_fastatus.depr_amt + p_faaudit.depr_amt 

	# IF depreciation will be greater than original cost - salvage
	# SET depr TO orig_cost less salvage
	IF p_fastatus.depr_amt > (p_fastatus.cur_depr_cost_amt - 
	p_fastatus.salvage_amt) THEN 
		LET p_fastatus.depr_amt = (p_fastatus.cur_depr_cost_amt - 
		p_fastatus.salvage_amt) 
	END IF 

	LET p_fastatus.net_book_val_amt = p_fastatus.cur_depr_cost_amt - 
	p_fastatus.depr_amt 

	UPDATE fastatus SET * = p_fastatus.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = p_faaudit.asset_code 
	AND add_on_code = p_faaudit.add_on_code 
	AND book_code = p_faaudit.book_code 

	#---------------------------------------------------------
	OUTPUT TO REPORT FP1_rpt_list_audit(modu_rpt_idx,
	p_faaudit.*, "Posted", 
	glob_rec_kandoouser.cmpy_code, compname, "Y") 
	#---------------------------------------------------------	

END FUNCTION 



# Audit REPORT


REPORT FP1_rpt_list_audit(r_faaudit, r_status, r_cmpy, r_compname, goodbad) 
	DEFINE r_faaudit RECORD LIKE faaudit.* 
	DEFINE r_status CHAR(35) 
	DEFINE r_cmpy LIKE faaudit.cmpy_code 
	DEFINE r_compname CHAR(40) 
	DEFINE goodbad CHAR(1) #good OR bad batch 

	OUTPUT 
	PAGE length 66 

	FORMAT 
		PAGE HEADER 
			PRINT COLUMN 12, today USING "DD/MM/YY", 
			COLUMN 40, r_cmpy, " ", 
			r_compname, 
			COLUMN 80, "Page ", 
			pageno 

			PRINT COLUMN 40, "FA Posting Audit Trail (Menu FP1)" 
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
			COLUMN 89, "Depr" 

			PRINT COLUMN 1, "Num", 
			COLUMN 11, "Num", 
			COLUMN 22, "Code", 
			COLUMN 35, "ID", 
			COLUMN 40, "Num", 
			COLUMN 50, "Num", 
			COLUMN 63, "Type", 
			COLUMN 73, "Amount", 
			COLUMN 89, "Amount", 
			COLUMN 98, "Status" 

			PRINT "----------------------------------------------------", 
			"----------------------------------------------------", 
			"----------------------" 

		ON EVERY ROW 
			PRINT COLUMN 1, r_faaudit.batch_num USING "#####", 
			COLUMN 11, r_faaudit.batch_line_num USING "####", 
			COLUMN 22, r_faaudit.asset_code, 
			COLUMN 35, r_faaudit.book_code, 
			COLUMN 40, r_faaudit.year_num USING "####", 
			COLUMN 50, r_faaudit.period_num USING "####", 
			COLUMN 64, r_faaudit.trans_ind, 
			COLUMN 68, r_faaudit.asset_amt USING "---,---,--$.##", 
			COLUMN 83, r_faaudit.depr_amt USING "---,---,--$.##", 
			COLUMN 98, r_status clipped 



END REPORT 

