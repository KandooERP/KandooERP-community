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

# Purpose   :   Asset summary REPORT

GLOBALS 
	DEFINE 
	pr_menunames RECORD LIKE menunames.*, 
	pr_famast RECORD LIKE famast.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_fastatus RECORD LIKE fastatus.*, 
	select_text, 
	where_part1, 
	faaudit_part, 
	where_part CHAR(1200), 
	pr_output CHAR(100), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_date DATE, 
	type1,type2,type3 CHAR(20), 
	pr_company RECORD LIKE company.*, 
	line1,line2 CHAR(132), 
	offset1,offset2 SMALLINT, 
	pr_book_code LIKE fabookdep.book_code, 
	pr_depn_code LIKE fabookdep.depn_code, 
	sort_code CHAR(1), 
	x,y,z SMALLINT, 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num, 
	pr_end_date, 
	pr_start_date DATE, 
	pr_start_year,pr_end_year LIKE period.year_num, 
	pr_start_period,pr_end_period LIKE period.period_num 

END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("F84") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 

	CREATE temp TABLE rep_fastatus 
	( 
	cmpy_code CHAR(2), 
	asset_code CHAR(10), 
	add_on_code CHAR(10), 
	book_code CHAR(2), 
	seq_num INTEGER, 
	depr_code CHAR(3), 
	purchase_date DATE, 
	last_depr_year_num SMALLINT, 
	last_depr_per_num SMALLINT, 
	life_period_num SMALLINT, 
	rem_life_num SMALLINT, 
	cur_depr_cost_amt DECIMAL(16,2), 
	depr_amt DECIMAL(16,2), 
	net_book_val_amt DECIMAL(16,2), 
	salvage_amt DECIMAL(16,2), 
	priv_use_per DECIMAL(6,3), 
	accum_priv_amt DECIMAL(16,2), 
	bal_chge_appl_flag CHAR(1), 
	bal_chge_amt DECIMAL(16,2), 
	bal_chg_app_code CHAR(10), 
	sale_amt DECIMAL(16,2), 
	open_nbv_amt DECIMAL(16,2), 
	sort1 CHAR(20), 
	desc_text1 CHAR(40), 
	sort2 CHAR(20), 
	desc_text2 CHAR(40), 
	sort3 CHAR(20), 
	desc_text3 CHAR(40), 
	book_text CHAR(20), 
	facat_code CHAR(3), 
	location_code CHAR(10), 
	faresp_code CHAR(18), 
	txfer_seq_num SMALLINT 
	) 

	OPEN WINDOW f181 with FORM "F181" -- alch kd-757 
	CALL  windecoration_f("F181") -- alch kd-757 

	MENU " Asset Summary" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F84","menu-asset_sum-1") -- alch kd-504 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL report_f84() 
			IF not(int_flag OR quit_flag) THEN 
				NEXT option "Print Manager" 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 


		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND "Message" " Enter heading MESSAGE FOR REPORT" 
			--        prompt " " FOR rpt_note -- albo
			LET rpt_note = promptInput(" ","",60) -- albo 
			NEXT option "Report" 

		COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 

END MAIN 



FUNCTION report_f84() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	fastatus_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_text CHAR(20), 
		facat_code LIKE facat.facat_code, 
		location_code CHAR(10), 
		faresp_code CHAR(18), 
		txfer_seq_num SMALLINT 
	END RECORD, 
	no_rows SMALLINT, 
	insert1,insert2, 
	found_some SMALLINT, 
	saved_facat_code LIKE faaudit.facat_code, 
	saved_location_code LIKE faaudit.location_code, 
	saved_faresp_code LIKE faaudit.faresp_code, 
	saved_sort1 CHAR(20), 
	saved_desc_text1 CHAR(40), 
	saved_sort2 CHAR(20), 
	saved_desc_text2 CHAR(40), 
	saved_sort3 CHAR(20), 
	saved_desc_text3 CHAR(40), 
	linerec RECORD 
		opening_cost LIKE fastatus.cur_depr_cost_amt, 
		adjustments LIKE fastatus.cur_depr_cost_amt, 
		transfers LIKE fastatus.cur_depr_cost_amt, 
		disposals LIKE fastatus.cur_depr_cost_amt, 
		adds LIKE fastatus.cur_depr_cost_amt, 
		revaluations LIKE fastatus.cur_depr_cost_amt, 

		opening_depr LIKE fastatus.depr_amt, 
		adjustments_depr LIKE fastatus.depr_amt, 
		transfers_depr LIKE fastatus.depr_amt, 
		disposals_depr LIKE fastatus.depr_amt, 
		adds_depr LIKE fastatus.depr_amt, 
		revaluations_depr LIKE fastatus.depr_amt, 
		depreciation LIKE fastatus.depr_amt 
	END RECORD, 
	tmp_seq_code SMALLINT, 
	num_trans SMALLINT, 
	tmp_depr, 
	tmp_asset LIKE faaudit.net_book_val_amt 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.
	CONSTRUCT BY NAME where_part ON fastatus.asset_code, 
	fastatus.add_on_code, 
	famast.orig_auth_code, 
	famast.acquist_date, 
	famast.faresp_code, 
	fastatus.book_code, 
	famast.facat_code, 
	famast.location_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F84","const-fastatus-6") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 
	OPEN WINDOW w183 with FORM "F183" -- alch kd-757 
	CALL  windecoration_f("F183") -- alch kd-757 
	MESSAGE "Year AND Period FOR YTD" attribute(yellow) 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING pr_year_num, 
	pr_period_num 

	DISPLAY pr_year_num TO year_num 

	DISPLAY pr_period_num TO period_num 

	INPUT pr_year_num, pr_period_num WITHOUT DEFAULTS FROM year_num,period_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F84","inp-pr_year_num-2") -- alch kd-504 
			--- modif ericv init # AFTER INPUT
		AFTER FIELD year_num 
			IF pr_year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9019,"") 
				#9019 Year must be entered.
				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF pr_period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD period_num 
			END IF 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9019,"") 
					#9019 Year must be entered.
					NEXT FIELD year_num 
				END IF 
				IF pr_period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD period_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	CLOSE WINDOW w183 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	#OPEN WINDOW w_sort AT 10,10 with 11 rows, 45 columns ATTRIBUTE(border)  -- alch KD-757

	OPTIONS PROMPT line 10 

	DISPLAY " Sort Order Selection " at 2,1 
	DISPLAY " 1. Location " at 3,1 
	DISPLAY " 2. Category " at 4,1 
	DISPLAY " 3. Responsibility " at 5,1 
	DISPLAY " 4. Authority " at 6,1 

	WHILE (true) 
		--    prompt  "    Enter Sort Order : " FOR sort_code -- albo
		LET sort_code = promptInput(" Enter Sort Order : ","",1) -- albo 

		IF int_flag OR quit_flag THEN 
			#CLOSE WINDOW w_sort  -- alch KD-757
			RETURN 
		END IF 

		IF sort_code NOT matches "[1234]" OR sort_code IS NULL THEN 
			LET msgresp = kandoomsg("F",9530,"") 
			#9530 Sort code must be 1,2,3 OR 7.
			CONTINUE WHILE 
		ELSE 
			#CLOSE WINDOW w_sort  -- alch KD-757
			EXIT WHILE 
		END IF 
	END WHILE 

	LET select_text = "SELECT unique fastatus.*,famast.* ", 
	"FROM fastatus,famast ", 
	"WHERE fastatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_part clipped," ", 
	"AND fastatus.cmpy_code = famast.cmpy_code ", 
	"AND fastatus.asset_code = famast.asset_code ", 
	"AND fastatus.add_on_code = famast.add_on_code " 


	PREPARE fastatus_sel FROM select_text 
	DECLARE fastatus_curs CURSOR FOR fastatus_sel 

	LET no_rows = true 

	DELETE FROM rep_fastatus WHERE 1=1 

	#OPEN WINDOW showit AT 14,10 with 2 rows, 50 columns ATTRIBUTE(border)  -- alch KD-757
	LET msgresp = kandoomsg("U",1506," ") 

	FOREACH fastatus_curs INTO pr_fastatus.*,pr_famast.* 

		LET no_rows = false 
		INITIALIZE fastatus_ext.* TO NULL 
		LET type1 = "" 
		LET type2 = "" 
		LET type3 = "" 

		LET fastatus_ext.facat_code = pr_famast.facat_code 
		LET fastatus_ext.location_code = pr_famast.location_code 
		LET fastatus_ext.faresp_code = pr_famast.faresp_code 

		CASE sort_code 
			WHEN "1" 
				LET type1 = "Location" 
				LET type2 = NULL 
				LET type3 = NULL 

				LET fastatus_ext.sort1 = pr_famast.location_code 
				SELECT location_text 
				INTO fastatus_ext.desc_text1 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET fastatus_ext.desc_text1 = "No Description on file" 
				END IF 

				LET fastatus_ext.sort2 = NULL 
				LET fastatus_ext.desc_text2 = NULL 

				LET fastatus_ext.sort3 = NULL 
				LET fastatus_ext.desc_text3 = NULL 

			WHEN "2" 
				LET type1 = "Category" 
				LET type2 = NULL 
				LET type3 = NULL 

				LET fastatus_ext.sort1 = pr_famast.facat_code 
				SELECT facat_text 
				INTO fastatus_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET fastatus_ext.desc_text1 = "No Description on file" 
				END IF 

				LET fastatus_ext.sort2 = NULL 
				LET fastatus_ext.desc_text2 = NULL 

				LET fastatus_ext.sort3 = NULL 
				LET fastatus_ext.desc_text3 = NULL 

			WHEN "3" 
				LET type1 = "Responsibility" 
				LET type2 = NULL 
				LET type3 = NULL 

				LET fastatus_ext.sort1 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO fastatus_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET fastatus_ext.desc_text1 = "No Description on file" 
				END IF 

				LET fastatus_ext.sort2 = NULL 
				LET fastatus_ext.desc_text2 = NULL 

				LET fastatus_ext.sort3 = NULL 
				LET fastatus_ext.desc_text3 = NULL 


			WHEN "4" 
				LET type1 = "Authority" 
				LET type2 = NULL 
				LET type3 = NULL 

				LET fastatus_ext.sort1 = pr_famast.orig_auth_code 
				SELECT auth_text 
				INTO fastatus_ext.desc_text1 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_famast.orig_auth_code 
				IF status THEN 
					LET fastatus_ext.desc_text1 = "No Description on file" 
				END IF 

				LET fastatus_ext.sort2 = NULL 
				LET fastatus_ext.desc_text2 = NULL 

				LET fastatus_ext.sort3 = NULL 
				LET fastatus_ext.desc_text3 = NULL 


		END CASE 

		SELECT book_text 
		INTO fastatus_ext.book_text 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = pr_fastatus.book_code 
		IF status THEN 
			LET fastatus_ext.book_text = "No description on file" 
		END IF 

		LET saved_facat_code = fastatus_ext.facat_code 
		LET saved_location_code = fastatus_ext.location_code 
		LET saved_faresp_code = fastatus_ext.faresp_code 
		LET saved_sort1 = fastatus_ext.sort1 
		LET saved_desc_text1 = fastatus_ext.desc_text1 
		LET saved_sort2 = fastatus_ext.sort2 
		LET saved_desc_text2 = fastatus_ext.desc_text2 
		LET saved_sort3 = fastatus_ext.sort3 
		LET saved_desc_text3 = fastatus_ext.desc_text3 

		IF sort_code != "7" THEN 
			#determine IF asset has been transferred during year AND period selected
			#AND IF so INSERT a RECORD TO REPORT on the 'FROM' part of the transfer

			DECLARE trans_curs CURSOR FOR 
			SELECT * 
			FROM faaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = pr_fastatus.asset_code 
			AND add_on_code = pr_fastatus.add_on_code 
			AND book_code = pr_fastatus.book_code 
			AND (year_num > pr_year_num OR 
			(year_num = pr_year_num AND 
			period_num >= pr_period_num)) 
			AND trans_ind = "T" 
			AND asset_amt < 0 
			ORDER BY batch_num,status_seq_num 

			OPEN trans_curs 
			FETCH trans_curs INTO pr_faaudit.* 

			IF status THEN {no transfers in OR AFTER year AND period selected} 
				# IF there are no transfer records THEN the current fastatus
				# reflects the correct location AND category so INSERT it AND
				# move on
				#check FOR transfers before period selected AND SET transfer_seq_num

				DECLARE before_curs CURSOR FOR 
				SELECT * 
				FROM faaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_fastatus.asset_code 
				AND add_on_code = pr_fastatus.add_on_code 
				AND book_code = pr_fastatus.book_code 
				AND (year_num = pr_year_num AND 
				period_num < pr_period_num) 
				AND trans_ind = "T" 
				AND asset_amt < 0 

				OPEN before_curs 
				FETCH before_curs INTO pr_faaudit.* 

				IF NOT status THEN 
					LET fastatus_ext.txfer_seq_num = 1 
				ELSE 
					LET fastatus_ext.txfer_seq_num = 0 
				END IF 

				INSERT INTO rep_fastatus VALUES (pr_fastatus.*,fastatus_ext.*) 

			ELSE {transfers have been done in OR AFTER y & p selected} 
				# INSERT info FROM each 'FROM' transfer in selected year AND period
				FOREACH trans_curs INTO pr_faaudit.* 
					# check IF category has changed FOR sort #5 OR #6
					IF sort_code matches "[56]" THEN 
						# SET resp AND location TO saved
						LET pr_faaudit.faresp_code = saved_faresp_code 
						LET pr_faaudit.location_code = saved_location_code 
					END IF 
					IF pr_faaudit.year_num > pr_year_num OR 
					(pr_faaudit.year_num = pr_year_num AND 
					pr_faaudit.period_num > pr_period_num) THEN 
						CONTINUE FOREACH 
					END IF 
					LET fastatus_ext.facat_code = pr_faaudit.facat_code 
					LET fastatus_ext.location_code = pr_faaudit.location_code 
					LET fastatus_ext.faresp_code = pr_faaudit.faresp_code 
					LET fastatus_ext.txfer_seq_num = pr_faaudit.status_seq_num 

					CALL sort_order(pr_fastatus.*,fastatus_ext.*) RETURNING 
					fastatus_ext.* 

					# aaaaagh! just WHEN you thought this was coming CLEAR
					# another complexity. we must now account FOR the CASE
					# WHEN the user transfers TO AND FROM the same category
					# OR location more than once in the same year - we only
					# want TO REPORT this category OR location once in the
					# REPORT - we sum the transactions later on - therefore
					# we check TO see IF the cat/location combination exists

					SELECT * 
					FROM rep_fastatus 
					WHERE cmpy_code = pr_fastatus.cmpy_code 
					AND asset_code = pr_fastatus.asset_code 
					AND add_on_code = pr_fastatus.add_on_code 
					AND book_code = pr_fastatus.book_code 
					AND facat_code = fastatus_ext.facat_code 
					AND location_code = fastatus_ext.location_code 
					AND faresp_code = fastatus_ext.faresp_code 

					IF status THEN {doesn't already exist} 
						INSERT INTO rep_fastatus VALUES (pr_fastatus.*, 
						fastatus_ext.*) 
					END IF 
				END FOREACH 
				# check FOR transfers AFTER year AND period selected
				DECLARE trans1_curs CURSOR FOR 
				SELECT * 
				FROM faaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_fastatus.asset_code 
				AND add_on_code = pr_fastatus.add_on_code 
				AND book_code = pr_fastatus.book_code 
				AND ((year_num = pr_year_num 
				AND period_num > pr_period_num) OR 
				(year_num > pr_year_num)) 
				AND trans_ind = "T" 
				AND asset_amt < 0 
				ORDER BY batch_num,status_seq_num 

				OPEN trans1_curs 
				FETCH trans1_curs INTO pr_faaudit.* 

				IF status THEN {no transfers AFTER year AND period} 
					LET fastatus_ext.faresp_code = saved_faresp_code 
					LET fastatus_ext.facat_code = saved_facat_code 
					LET fastatus_ext.location_code = saved_location_code 
					LET fastatus_ext.txfer_seq_num = 0 
					LET fastatus_ext.sort1 = saved_sort1 
					LET fastatus_ext.desc_text1 = saved_desc_text1 
					LET fastatus_ext.sort2 = saved_sort2 
					LET fastatus_ext.desc_text2 = saved_desc_text2 
					LET fastatus_ext.sort3 = saved_sort3 
					LET fastatus_ext.desc_text3 = saved_desc_text3 
					LET fastatus_ext.txfer_seq_num = 1 

					SELECT * 
					FROM rep_fastatus 
					WHERE facat_code = fastatus_ext.facat_code 
					AND location_code = fastatus_ext.location_code 
					AND cmpy_code = pr_faaudit.cmpy_code 
					AND asset_code = pr_faaudit.asset_code 
					AND add_on_code = pr_faaudit.add_on_code 
					AND book_code = pr_faaudit.book_code 
					AND facat_code = fastatus_ext.facat_code 
					AND location_code = fastatus_ext.location_code 
					AND faresp_code = fastatus_ext.faresp_code 

					IF status THEN {doesn't already exist} 
						INSERT INTO rep_fastatus VALUES (pr_fastatus.*, 
						fastatus_ext.*) 
					END IF 
				ELSE {transferred AFTER y+p selected so INSERT FROM the details} 
					LET fastatus_ext.facat_code = pr_faaudit.facat_code 
					LET fastatus_ext.location_code = pr_faaudit.location_code 
					LET fastatus_ext.faresp_code = pr_faaudit.faresp_code 
					LET fastatus_ext.txfer_seq_num = pr_faaudit.status_seq_num 

					CALL sort_order(pr_fastatus.*,fastatus_ext.*) RETURNING 
					fastatus_ext.* 

					SELECT * 
					FROM rep_fastatus 
					WHERE facat_code = fastatus_ext.facat_code 
					AND location_code = fastatus_ext.location_code 
					AND cmpy_code = pr_faaudit.cmpy_code 
					AND asset_code = pr_faaudit.asset_code 
					AND add_on_code = pr_faaudit.add_on_code 
					AND book_code = pr_faaudit.book_code 
					AND facat_code = fastatus_ext.facat_code 
					AND location_code = fastatus_ext.location_code 
					AND faresp_code = fastatus_ext.faresp_code 

					IF status THEN {doesn't already exist} 
						INSERT INTO rep_fastatus VALUES (pr_fastatus.*, 
						fastatus_ext.*) 
					END IF 
				END IF 
			END IF 
		ELSE 
			INSERT INTO rep_fastatus VALUES (pr_fastatus.*,fastatus_ext.*) 
		END IF 

	END FOREACH 

	IF no_rows THEN 
		LET msgresp = kandoomsg("U",9101,"") 	#9101 No records satisfied selection criteria.
		LET int_flag = true 
		RETURN 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F84_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F84_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	DECLARE report_curs CURSOR FOR 
	SELECT * 
	FROM rep_fastatus 
	ORDER BY book_code,sort1,sort2,sort3,asset_code,add_on_code,txfer_seq_num 

	FOREACH report_curs INTO pr_fastatus.*, fastatus_ext.* 

		# don't PRINT asset IF added AFTER year AND period selected
		SELECT year_num,period_num 
		FROM faaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_fastatus.asset_code 
		AND add_on_code = pr_fastatus.add_on_code 
		AND book_code = pr_fastatus.book_code 
		AND trans_ind = "A" 
		AND (year_num < pr_year_num OR 
		(year_num = pr_year_num AND 
		period_num <= pr_period_num)) 

		IF status THEN 
			CONTINUE FOREACH 
		END IF 

		DISPLAY "Printing Asset : ",pr_fastatus.asset_code at 2,1 

		SELECT * 
		INTO pr_famast.* 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_fastatus.asset_code 
		AND add_on_code = pr_fastatus.add_on_code 


		# determine opening cost AND depreciation

		LET tmp_seq_code = 0 
		LET linerec.opening_cost = 0 
		LET linerec.opening_depr = 0 

		# sum all transactions FOR previous years TO determine the years
		# opening cost AND depreciation

		# first get the addition
		LET tmp_asset = 0 
		LET tmp_depr = 0 
		SELECT asset_amt,depr_amt 
		INTO tmp_asset,tmp_depr 
		FROM faaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_fastatus.asset_code 
		AND add_on_code = pr_fastatus.add_on_code 
		AND book_code = pr_fastatus.book_code 
		AND facat_code matches fastatus_ext.facat_code 
		AND location_code matches fastatus_ext.location_code 
		AND faresp_code matches fastatus_ext.faresp_code 
		AND year_num < pr_year_num 
		AND trans_ind = "A" 

		IF tmp_asset IS NULL THEN LET tmp_asset = 0 END IF 
			IF tmp_depr IS NULL THEN LET tmp_depr = 0 END IF 

				LET linerec.opening_cost = linerec.opening_cost + tmp_asset + tmp_depr 
				LET linerec.opening_depr = linerec.opening_depr + tmp_depr 

				# now the depreciation
				LET tmp_depr = 0 
				SELECT sum(depr_amt) 
				INTO tmp_depr 
				FROM faaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_fastatus.asset_code 
				AND add_on_code = pr_fastatus.add_on_code 
				AND book_code = pr_fastatus.book_code 
				AND facat_code matches fastatus_ext.facat_code 
				AND location_code matches fastatus_ext.location_code 
				AND faresp_code matches fastatus_ext.faresp_code 
				AND year_num < pr_year_num 
				AND trans_ind = "D" 

				IF tmp_depr IS NULL THEN LET tmp_depr = 0 END IF 

					LET linerec.opening_depr = linerec.opening_depr + tmp_depr 

					# next sum all transfers AND adjustments transactions
					IF sort_code != "7" THEN 
						# get transfers as well FOR all other that option 7
						LET tmp_asset = 0 
						LET tmp_depr = 0 
						SELECT sum(asset_amt),sum(depr_amt) 
						INTO tmp_asset,tmp_depr 
						FROM faaudit 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND asset_code = pr_fastatus.asset_code 
						AND add_on_code = pr_fastatus.add_on_code 
						AND book_code = pr_fastatus.book_code 
						AND facat_code matches fastatus_ext.facat_code 
						AND location_code matches fastatus_ext.location_code 
						AND faresp_code matches fastatus_ext.faresp_code 
						AND (trans_ind = "J" OR (trans_ind = "T" AND asset_amt > 0)) 
						AND year_num < pr_year_num 
					ELSE 
						# ignore transfers FOR sort code option 7
						IF sort_code NOT matches "[56]" THEN 
							LET tmp_asset = 0 
							LET tmp_depr = 0 
							SELECT sum(asset_amt),sum(depr_amt) 
							INTO tmp_asset,tmp_depr 
							FROM faaudit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = pr_fastatus.asset_code 
							AND add_on_code = pr_fastatus.add_on_code 
							AND book_code = pr_fastatus.book_code 
							AND facat_code matches fastatus_ext.facat_code 
							AND location_code matches fastatus_ext.location_code 
							AND faresp_code matches fastatus_ext.faresp_code 
							AND trans_ind = "J" 
							AND year_num < pr_year_num 
						ELSE 
							# get transfers FOR facat as well FOR option 5 AND 6
							LET tmp_asset = 0 
							LET tmp_depr = 0 
							SELECT sum(asset_amt),sum(depr_amt) 
							INTO tmp_asset,tmp_depr 
							FROM faaudit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = pr_fastatus.asset_code 
							AND add_on_code = pr_fastatus.add_on_code 
							AND book_code = pr_fastatus.book_code 
							AND facat_code matches fastatus_ext.facat_code 
							AND (trans_ind = "J" OR (trans_ind = "T" AND asset_amt > 0)) 
							AND year_num < pr_year_num 
						END IF 
					END IF 


					IF tmp_asset IS NULL THEN LET tmp_asset = 0 END IF 
						IF tmp_depr IS NULL THEN LET tmp_depr = 0 END IF 

							LET linerec.opening_cost = linerec.opening_cost + tmp_asset 
							LET linerec.opening_depr = linerec.opening_depr + tmp_depr 

							# next sum all sales AND retirements transactions AND subtract
							LET tmp_asset = 0 
							LET tmp_depr = 0 
							SELECT sum(asset_amt),sum(depr_amt) 
							INTO tmp_asset,tmp_depr 
							FROM faaudit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND asset_code = pr_fastatus.asset_code 
							AND add_on_code = pr_fastatus.add_on_code 
							AND book_code = pr_fastatus.book_code 
							AND facat_code matches fastatus_ext.facat_code 
							AND location_code matches fastatus_ext.location_code 
							AND faresp_code matches fastatus_ext.faresp_code 
							AND (trans_ind = "S" OR trans_ind = "R") 
							AND year_num < pr_year_num 

							IF tmp_asset IS NULL THEN LET tmp_asset = 0 END IF 
								IF tmp_depr IS NULL THEN LET tmp_depr = 0 END IF 

									LET linerec.opening_cost = linerec.opening_cost - tmp_asset 
									LET linerec.opening_depr = linerec.opening_depr - tmp_depr 

									# next add in the revaluations
									LET tmp_asset = 0 
									LET tmp_depr = 0 
									SELECT sum(sale_amt),sum(depr_amt) 
									INTO tmp_asset,tmp_depr 
									FROM faaudit 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND asset_code = pr_fastatus.asset_code 
									AND add_on_code = pr_fastatus.add_on_code 
									AND book_code = pr_fastatus.book_code 
									AND facat_code matches fastatus_ext.facat_code 
									AND location_code matches fastatus_ext.location_code 
									AND faresp_code matches fastatus_ext.faresp_code 
									AND trans_ind = "V" 
									AND year_num < pr_year_num 

									IF tmp_asset IS NULL THEN LET tmp_asset = 0 END IF 
										IF tmp_depr IS NULL THEN LET tmp_depr = 0 END IF 

											LET linerec.opening_cost = linerec.opening_cost + tmp_asset 

											LET linerec.opening_depr = linerec.opening_depr - tmp_depr 

											IF linerec.opening_cost IS NULL THEN LET linerec.opening_cost = 0 END IF 
												IF linerec.opening_depr IS NULL THEN LET linerec.opening_depr = 0 END IF 




													# This years calcs


													# determine additions ytd

													LET linerec.adds = 0 
													LET linerec.adds_depr = 0 

													DECLARE add_curs CURSOR FOR 
													SELECT asset_amt,depr_amt 
													INTO linerec.adds,linerec.adds_depr 
													FROM faaudit 
													WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
													AND asset_code = pr_fastatus.asset_code 
													AND add_on_code = pr_fastatus.add_on_code 
													AND book_code = pr_fastatus.book_code 
													AND trans_ind = "A" 
													AND location_code matches fastatus_ext.location_code 
													AND facat_code matches fastatus_ext.facat_code 
													AND faresp_code matches fastatus_ext.faresp_code 
													AND year_num = pr_year_num 
													AND period_num <= pr_period_num 

													OPEN add_curs 
													FETCH add_curs 

													IF status THEN 
														LET linerec.adds = 0 
														LET linerec.adds_depr = 0 
													ELSE 
														LET linerec.adds = linerec.adds + linerec.adds_depr 
													END IF 

													IF linerec.adds IS NULL THEN LET linerec.adds = 0 END IF 
														IF linerec.adds_depr IS NULL THEN LET linerec.adds_depr = 0 END IF 


															# determine disposals - sales AND retirements

															LET linerec.disposals = 0 
															LET linerec.disposals_depr = 0 

															DECLARE disp_curs CURSOR FOR 
															SELECT sum(asset_amt),sum(depr_amt) 
															FROM faaudit 
															WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
															AND asset_code = pr_fastatus.asset_code 
															AND add_on_code = pr_fastatus.add_on_code 
															AND book_code = pr_fastatus.book_code 
															AND (trans_ind = "S" OR trans_ind = "R") 
															AND location_code matches fastatus_ext.location_code 
															AND facat_code matches fastatus_ext.facat_code 
															AND faresp_code matches fastatus_ext.faresp_code 
															AND year_num = pr_year_num 
															AND period_num <= pr_period_num 

															OPEN disp_curs 
															FETCH disp_curs INTO linerec.disposals,linerec.disposals_depr 

															IF status THEN 
																LET linerec.disposals = 0 
																LET linerec.disposals_depr = 0 
															ELSE 
																LET linerec.disposals = 0 - linerec.disposals 
																LET linerec.disposals_depr = 0 - linerec.disposals_depr 
															END IF 

															IF linerec.disposals IS NULL THEN LET linerec.disposals = 0 END IF 
																IF linerec.disposals_depr IS NULL THEN LET linerec.disposals_depr = 0 END IF 

																	# determine transfers

																	LET linerec.transfers = 0 
																	LET linerec.transfers_depr = 0 

																	IF fastatus_ext.txfer_seq_num != 0 THEN {transfers in y AND p} 
																		DECLARE tran_curs CURSOR FOR 
																		SELECT sum(asset_amt),sum(depr_amt) 
																		FROM faaudit 
																		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																		AND asset_code = pr_fastatus.asset_code 
																		AND add_on_code = pr_fastatus.add_on_code 
																		AND book_code = pr_fastatus.book_code 
																		AND trans_ind = "T" 
																		AND location_code matches fastatus_ext.location_code 
																		AND facat_code matches fastatus_ext.facat_code 
																		AND faresp_code matches fastatus_ext.faresp_code 
																		AND year_num = pr_year_num 
																		AND period_num <= pr_period_num 

																		OPEN tran_curs 
																		FETCH tran_curs INTO linerec.transfers,linerec.transfers_depr 

																		IF status THEN 
																			LET linerec.transfers = 0 
																			LET linerec.transfers_depr = 0 
																		END IF 
																		IF linerec.transfers IS NULL THEN 
																			LET linerec.transfers = 0 
																		END IF 
																		IF linerec.transfers_depr IS NULL THEN 
																			LET linerec.transfers_depr = 0 
																		END IF 
																	END IF 

																	# determine adjustments AND revaluations together

																	LET linerec.adjustments = 0 
																	LET linerec.adjustments_depr = 0 

																	DECLARE adj_curs CURSOR FOR 
																	SELECT sum(asset_amt),sum(depr_amt) 
																	FROM faaudit 
																	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																	AND asset_code = pr_fastatus.asset_code 
																	AND add_on_code = pr_fastatus.add_on_code 
																	AND book_code = pr_fastatus.book_code 
																	AND trans_ind = "J" 
																	AND location_code matches fastatus_ext.location_code 
																	AND facat_code matches fastatus_ext.facat_code 
																	AND faresp_code matches fastatus_ext.faresp_code 
																	AND year_num = pr_year_num 
																	AND period_num <= pr_period_num 


																	OPEN adj_curs 
																	FETCH adj_curs INTO linerec.adjustments,linerec.adjustments_depr 

																	IF status THEN 
																		LET linerec.adjustments = 0 
																		LET linerec.adjustments_depr = 0 
																	END IF 

																	IF linerec.adjustments IS NULL THEN 
																		LET linerec.adjustments = 0 
																	END IF 

																	IF linerec.adjustments_depr IS NULL THEN 
																		LET linerec.adjustments_depr = 0 
																	END IF 

																	# add in revaluations TO adjustments

																	LET linerec.revaluations = 0 
																	LET linerec.revaluations_depr = 0 

																	DECLARE rev1_curs CURSOR FOR 
																	SELECT sum(sale_amt),sum(depr_amt) 
																	FROM faaudit 
																	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																	AND asset_code = pr_fastatus.asset_code 
																	AND add_on_code = pr_fastatus.add_on_code 
																	AND book_code = pr_fastatus.book_code 
																	AND trans_ind = "V" 
																	AND location_code matches fastatus_ext.location_code 
																	AND facat_code matches fastatus_ext.facat_code 
																	AND faresp_code matches fastatus_ext.faresp_code 
																	AND year_num = pr_year_num 
																	AND period_num <= pr_period_num 

																	OPEN rev1_curs 
																	FETCH rev1_curs INTO linerec.revaluations,linerec.revaluations_depr 

																	IF NOT status THEN 
																		LET linerec.revaluations_depr = 0 - linerec.revaluations_depr 
																	END IF 

																	IF linerec.revaluations IS NULL THEN 
																		LET linerec.revaluations = 0 
																	END IF 

																	IF linerec.revaluations_depr IS NULL THEN 
																		LET linerec.revaluations_depr = 0 
																	END IF 

																	LET linerec.adjustments = linerec.adjustments + linerec.revaluations 
																	LET linerec.adjustments_depr = linerec.adjustments_depr + 
																	linerec.revaluations_depr 

																	# determine depreciation charged
																	LET linerec.depreciation = 0 

																	SELECT sum(depr_amt) 
																	INTO linerec.depreciation 
																	FROM faaudit 
																	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																	AND asset_code = pr_fastatus.asset_code 
																	AND add_on_code = pr_fastatus.add_on_code 
																	AND book_code = pr_fastatus.book_code 
																	AND trans_ind = "D" 
																	AND location_code matches fastatus_ext.location_code 
																	AND facat_code matches fastatus_ext.facat_code 
																	AND faresp_code matches fastatus_ext.faresp_code 
																	AND year_num = pr_year_num 
																	AND period_num <= pr_period_num 

																	IF status THEN 
																		LET linerec.depreciation = 0 
																	END IF 
																	IF linerec.depreciation IS NULL THEN 
																		LET linerec.depreciation = 0 
																	END IF 

																	# don't REPORT on assets with no opening bal OR closing bal OR transactions
																	IF linerec.opening_cost = 0 AND 
																	linerec.adjustments = 0 AND 
																	linerec.transfers = 0 AND 
																	linerec.disposals = 0 AND 
																	linerec.adds = 0 AND 
																	linerec.revaluations = 0 AND 
																	linerec.opening_depr = 0 AND 
																	linerec.adjustments_depr = 0 AND 
																	linerec.transfers_depr = 0 AND 
																	linerec.disposals_depr = 0 AND 
																	linerec.adds_depr = 0 AND 
																	linerec.revaluations_depr = 0 AND 
																	linerec.depreciation = 0 THEN 
																		CONTINUE FOREACH 
																	END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT F84_rpt_list(l_rpt_idx,
		pr_fastatus.*,fastatus_ext.*,pr_famast.*,linerec.*)
		#---------------------------------------------------------

																END FOREACH 


	#------------------------------------------------------------
	FINISH REPORT F84_rpt_list
	CALL rpt_finish("F84_rpt_list")
	#------------------------------------------------------------


	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



REPORT F84_rpt_list(rr_fastatus,rr_fastatus_ext,rr_famast,rr_linerec) 

	DEFINE 
	rr_famast RECORD LIKE famast.*, 
	rr_fastatus RECORD LIKE fastatus.*, 
	rr_fastatus_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_text CHAR(20), 
		facat_code LIKE facat.facat_code, 
		location_code CHAR(10), 
		faresp_code CHAR(18), 
		txfer_seq_num SMALLINT 
	END RECORD, 
	rr_wid SMALLINT, 
	rr_book_code LIKE fabookdep.book_code, 
	rr_tmp_print CHAR(100), 
	rr_print CHAR(100), 
	rr_sort_desc CHAR(40), 
	prev_period LIKE period.period_num, 
	prev_year LIKE period.year_num, 
	max_seq_num LIKE faaudit.status_seq_num, 
	tmp1_seq_num, 
	tmp_seq_code SMALLINT, 

	rr_linerec RECORD 
		opening_cost LIKE fastatus.cur_depr_cost_amt, 
		adjustments LIKE fastatus.cur_depr_cost_amt, 
		transfers LIKE fastatus.cur_depr_cost_amt, 
		disposals LIKE fastatus.cur_depr_cost_amt, 
		adds LIKE fastatus.cur_depr_cost_amt, 
		revaluations LIKE fastatus.cur_depr_cost_amt, 

		opening_depr LIKE fastatus.depr_amt, 
		adjustments_depr LIKE fastatus.depr_amt, 
		transfers_depr LIKE fastatus.depr_amt, 
		disposals_depr LIKE fastatus.depr_amt, 
		adds_depr LIKE fastatus.depr_amt, 
		revaluations_depr LIKE fastatus.depr_amt, 
		depreciation LIKE fastatus.depr_amt 
	END RECORD, 

	closing_cost LIKE fastatus.cur_depr_cost_amt, 
	closing_depr LIKE fastatus.depr_amt, 
	nbv LIKE fastatus.net_book_val_amt 


	OUTPUT 
	PAGE length 66 

	ORDER external BY rr_fastatus.book_code, 
	rr_fastatus_ext.sort1, 
	rr_fastatus_ext.sort2, 
	rr_fastatus_ext.sort3, 
	rr_fastatus.asset_code, 
	rr_fastatus.add_on_code 

	FORMAT 

		PAGE HEADER 
			LET rr_wid = rpt_wid 

			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text 

			IF rpt_note IS NULL THEN 
				LET rpt_note = "Asset Summary Report" 
			END IF 

			LET line2 = rpt_note clipped," (Menu - F84)" 
			LET offset1 = (rr_wid - length(line1))/2 
			LET offset2 = (rr_wid - length(line2))/2 
			PRINT COLUMN 1,today USING "dd/mm/yy", 
			COLUMN offset1, line1 clipped, 
			COLUMN 118,"Page : ", pageno USING "<<<<" 
			PRINT COLUMN offset2, line2 clipped 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

			PRINT COLUMN 109," Closing Cost" 
			PRINT COLUMN 1," Opening Cost", 
			COLUMN 19," Additions", 
			COLUMN 37," Transfers", 
			COLUMN 55," Adjustments", 
			COLUMN 91," Disposals", 
			COLUMN 109," Closing Depn" 
			PRINT COLUMN 1," Opening Depn", 
			COLUMN 73," Depn Charge", 
			COLUMN 109," Net Book Value" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		BEFORE GROUP OF rr_fastatus.book_code 
			SKIP TO top OF PAGE 
			CASE sort_code 
				WHEN "1" 
					LET rr_sort_desc = "Location" 
				WHEN "2" 
					LET rr_sort_desc = "Category" 
				WHEN "3" 
					LET rr_sort_desc = "Responsibility" 
				WHEN "4" 
					LET rr_sort_desc = "Authority" 
			END CASE 
			LET rr_tmp_print = "Book : ",rr_fastatus.book_code clipped," - ", 
			rr_fastatus_ext.book_text," Sorted by : ", 
			rr_sort_desc 
			LET x = length(rr_tmp_print) 
			PRINT COLUMN 1,rr_tmp_print 
			FOR y = 1 TO x 
				PRINT "="; 
			END FOR 
			PRINT 
			SKIP 1 LINES 
			PRINT "YTD - YEAR : ",pr_year_num USING "####"," ", 
			"PERIOD : ",pr_period_num USING "<<<" 
			SKIP 1 LINES 

		AFTER GROUP OF rr_fastatus_ext.sort1 
			IF type1 IS NOT NULL THEN 
				NEED 7 LINES 
				IF type2 IS NULL AND type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
				LET rr_print = "Total : ", rr_fastatus_ext.sort1 clipped," - ", 
				rr_fastatus_ext.desc_text1 
				PRINT COLUMN 1,rr_print[1,57] 
				PRINT COLUMN 1,"-----------------", 
				COLUMN 19,"-----------------", 
				COLUMN 37,"-----------------", 
				COLUMN 55,"-----------------", 
				COLUMN 73,"-----------------", 
				COLUMN 91,"-----------------", 
				COLUMN 109,"-----------------" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_cost) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals) 
				USING "--,---,---,--&.&&"; 
				LET closing_cost = GROUP sum(rr_linerec.opening_cost) + 
				GROUP sum(rr_linerec.adds) + 
				GROUP sum(rr_linerec.transfers) + 
				GROUP sum(rr_linerec.adjustments) + 
				GROUP sum(rr_linerec.disposals) 
				PRINT COLUMN 109,closing_cost USING "--,---,---,--&.&&" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 73,group sum(rr_linerec.depreciation) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals_depr) 
				USING "--,---,---,--&.&&"; 
				LET closing_depr = GROUP sum(rr_linerec.opening_depr) + 
				GROUP sum(rr_linerec.adds_depr) + 
				GROUP sum(rr_linerec.transfers_depr) + 
				GROUP sum(rr_linerec.adjustments_depr) + 
				GROUP sum(rr_linerec.depreciation) + 
				GROUP sum(rr_linerec.disposals_depr) 
				PRINT COLUMN 109,closing_depr USING "--,---,---,--&.&&" 
				LET nbv = closing_cost - closing_depr 
				PRINT COLUMN 109,nbv USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 LINES 
		AFTER GROUP OF rr_fastatus_ext.sort2 
			IF type2 IS NOT NULL THEN 
				NEED 7 LINES 
				IF type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
				PRINT COLUMN 1,type2 clipped," Sub Total " 
				LET rr_print = rr_fastatus_ext.sort2 clipped," - ", 
				rr_fastatus_ext.desc_text2 
				PRINT COLUMN 1,rr_print[1,49] 
				PRINT COLUMN 1,"-----------------", 
				COLUMN 19,"-----------------", 
				COLUMN 37,"-----------------", 
				COLUMN 55,"-----------------", 
				COLUMN 73,"-----------------", 
				COLUMN 91,"-----------------", 
				COLUMN 109,"-----------------" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_cost) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals) 
				USING "--,---,---,--&.&&"; 
				LET closing_cost = GROUP sum(rr_linerec.opening_cost) + 
				GROUP sum(rr_linerec.adds) + 
				GROUP sum(rr_linerec.transfers) + 
				GROUP sum(rr_linerec.adjustments) + 
				GROUP sum(rr_linerec.disposals) 
				PRINT COLUMN 109,closing_cost USING "--,---,---,--&.&&" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 73,group sum(rr_linerec.depreciation) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals_depr) 
				USING "--,---,---,--&.&&"; 
				LET closing_depr = GROUP sum(rr_linerec.opening_depr) + 
				GROUP sum(rr_linerec.adds_depr) + 
				GROUP sum(rr_linerec.transfers_depr) + 
				GROUP sum(rr_linerec.adjustments_depr) + 
				GROUP sum(rr_linerec.depreciation) + 
				GROUP sum(rr_linerec.disposals_depr) 
				PRINT COLUMN 109,closing_depr USING "--,---,---,--&.&&" 
				LET nbv = closing_cost - closing_depr 
				PRINT COLUMN 109,nbv USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF rr_fastatus_ext.sort3 
			IF type3 IS NOT NULL THEN 
				NEED 7 LINES 
				SKIP 1 LINES 
				PRINT COLUMN 1,type3 clipped," Sub Total " 
				LET rr_print = rr_fastatus_ext.sort3 clipped," - ", 
				rr_fastatus_ext.desc_text3 
				PRINT COLUMN 1,rr_print[1,49] 
				PRINT COLUMN 1,"-----------------", 
				COLUMN 19,"-----------------", 
				COLUMN 37,"-----------------", 
				COLUMN 55,"-----------------", 
				COLUMN 73,"-----------------", 
				COLUMN 91,"-----------------", 
				COLUMN 109,"-----------------" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_cost) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals) 
				USING "--,---,---,--&.&&"; 
				LET closing_cost = GROUP sum(rr_linerec.opening_cost) + 
				GROUP sum(rr_linerec.adds) + 
				GROUP sum(rr_linerec.transfers) + 
				GROUP sum(rr_linerec.adjustments) + 
				GROUP sum(rr_linerec.disposals) 
				PRINT COLUMN 109,closing_cost USING "--,---,---,--&.&&" 
				PRINT COLUMN 1,group sum(rr_linerec.opening_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 19,group sum(rr_linerec.adds_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 37,group sum(rr_linerec.transfers_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 55,group sum(rr_linerec.adjustments_depr) 
				USING "--,---,---,--&.&&", 
				COLUMN 73,group sum(rr_linerec.depreciation) 
				USING "--,---,---,--&.&&", 
				COLUMN 91,group sum(rr_linerec.disposals_depr) 
				USING "--,---,---,--&.&&"; 
				LET closing_depr = GROUP sum(rr_linerec.opening_depr) + 
				GROUP sum(rr_linerec.adds_depr) + 
				GROUP sum(rr_linerec.transfers_depr) + 
				GROUP sum(rr_linerec.adjustments_depr) + 
				GROUP sum(rr_linerec.depreciation) + 
				GROUP sum(rr_linerec.disposals_depr) 
				PRINT COLUMN 109,closing_depr USING "--,---,---,--&.&&" 
				LET nbv = closing_cost - closing_depr 
				PRINT COLUMN 109,nbv USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF rr_fastatus.book_code 
			SKIP 1 LINES 
			NEED 5 LINES 
			PRINT "Book : ",rr_fastatus.book_code," TOTAL" 
			PRINT COLUMN 1,group sum(rr_linerec.opening_cost) 
			USING "--,---,---,--&.&&", 
			COLUMN 19,group sum(rr_linerec.adds) 
			USING "--,---,---,--&.&&", 
			COLUMN 37,group sum(rr_linerec.transfers) 
			USING "--,---,---,--&.&&", 
			COLUMN 55,group sum(rr_linerec.adjustments) 
			USING "--,---,---,--&.&&", 
			COLUMN 91,group sum(rr_linerec.disposals) 
			USING "--,---,---,--&.&&"; 
			LET closing_cost = GROUP sum(rr_linerec.opening_cost) + 
			GROUP sum(rr_linerec.adds) + 
			GROUP sum(rr_linerec.transfers) + 
			GROUP sum(rr_linerec.adjustments) + 
			GROUP sum(rr_linerec.disposals) 
			PRINT COLUMN 109,closing_cost USING "--,---,---,--&.&&" 
			PRINT COLUMN 1,group sum(rr_linerec.opening_depr) 
			USING "--,---,---,--&.&&", 
			COLUMN 19,group sum(rr_linerec.adds_depr) 
			USING "--,---,---,--&.&&", 
			COLUMN 37,group sum(rr_linerec.transfers_depr) 
			USING "--,---,---,--&.&&", 
			COLUMN 55,group sum(rr_linerec.adjustments_depr) 
			USING "--,---,---,--&.&&", 
			COLUMN 73,group sum(rr_linerec.depreciation) 
			USING "--,---,---,--&.&&", 
			COLUMN 91,group sum(rr_linerec.disposals_depr) 
			USING "--,---,---,--&.&&"; 
			LET closing_depr = GROUP sum(rr_linerec.opening_depr) + 
			GROUP sum(rr_linerec.adds_depr) + 
			GROUP sum(rr_linerec.transfers_depr) + 
			GROUP sum(rr_linerec.adjustments_depr) + 
			GROUP sum(rr_linerec.depreciation) + 
			GROUP sum(rr_linerec.disposals_depr) 
			PRINT COLUMN 109,closing_depr USING "--,---,---,--&.&&" 
			LET nbv = closing_cost - closing_depr 
			PRINT COLUMN 109,nbv USING "--,---,---,--&.&&" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Selection Criteria : ", 
			COLUMN 25, where_part clipped wordwrap right margin 120 
			SKIP 2 LINES 
			LET rpt_pageno = pageno 
			LET rpt_length = 66 
			PRINT COLUMN 50, "******** END OF REPORT F84 ********" 

END REPORT 




FUNCTION sort_order(tmp_fastatus,tmp_fastatus_ext) 

	DEFINE 
	tmp_fastatus RECORD LIKE fastatus.*, 
	tmp_fastatus_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_text CHAR(20), 
		facat_code LIKE facat.facat_code, 
		location_code CHAR(10), 
		faresp_code CHAR(18), 
		txfer_seq_num SMALLINT 
	END RECORD 

	SELECT * 
	INTO pr_famast.* 
	FROM famast 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND asset_code = tmp_fastatus.asset_code 
	AND add_on_code = tmp_fastatus.add_on_code 

	CASE sort_code 
		WHEN "1" 

			LET tmp_fastatus_ext.sort1 = tmp_fastatus_ext.location_code 
			SELECT location_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_fastatus_ext.location_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = tmp_fastatus_ext.faresp_code 
			SELECT faresp_text 
			INTO tmp_fastatus_ext.desc_text3 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_fastatus_ext.faresp_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "2" 

			LET tmp_fastatus_ext.sort1 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = tmp_fastatus_ext.location_code 
			SELECT location_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_fastatus_ext.location_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = tmp_fastatus_ext.faresp_code 
			SELECT faresp_text 
			INTO tmp_fastatus_ext.desc_text3 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_fastatus_ext.faresp_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "3" 

			LET tmp_fastatus_ext.sort1 = tmp_fastatus_ext.faresp_code 
			SELECT faresp_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_fastatus_ext.faresp_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = tmp_fastatus_ext.location_code 
			SELECT location_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_fastatus_ext.location_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text3 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "4" 

			LET tmp_fastatus_ext.sort1 = tmp_fastatus_ext.faresp_code 
			SELECT faresp_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_fastatus_ext.faresp_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = tmp_fastatus_ext.location_code 
			SELECT location_text 
			INTO tmp_fastatus_ext.desc_text3 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_fastatus_ext.location_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "5" 

			LET tmp_fastatus_ext.sort1 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = pr_famast.orig_auth_code 
			SELECT auth_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM faauth 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND auth_code = pr_famast.orig_auth_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = NULL 
			LET tmp_fastatus_ext.desc_text3 = NULL 

		WHEN "6" 

			LET tmp_fastatus_ext.sort1 = pr_famast.orig_auth_code 
			SELECT auth_text 
			INTO tmp_fastatus_ext.desc_text1 
			FROM faauth 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND auth_code = pr_famast.orig_auth_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort2 = tmp_fastatus_ext.facat_code 
			SELECT facat_text 
			INTO tmp_fastatus_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_fastatus_ext.facat_code 
			IF status THEN 
				LET tmp_fastatus_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_fastatus_ext.sort3 = NULL 
			LET tmp_fastatus_ext.desc_text3 = NULL 

		WHEN "7" 
			LET tmp_fastatus_ext.sort1 = NULL 
			LET tmp_fastatus_ext.desc_text1 = NULL 
			LET tmp_fastatus_ext.sort2 = NULL 
			LET tmp_fastatus_ext.desc_text2 = NULL 
			LET tmp_fastatus_ext.sort3 = NULL 
			LET tmp_fastatus_ext.desc_text3 = NULL 


	END CASE 

	RETURN tmp_fastatus_ext.* 

END FUNCTION 
