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

# Purpose   :   Asset Non financial Detail Report

GLOBALS 
	DEFINE 

	pr_famast RECORD LIKE famast.*, 
	pr_faaudit RECORD LIKE faaudit.*, 
	pr_fastatus RECORD LIKE fastatus.*, 
	select_text, 
	where_part1, 
	where_part CHAR(1200), 
	pr_output CHAR(100), 
	type1,type2,type3 CHAR(20), 
	pr_company RECORD LIKE company.*, 
	line1,line2, 
	rpt_note CHAR(132), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_date DATE, 
	offset1,offset2 SMALLINT, 
	pr_book_code LIKE fabookdep.book_code, 
	pr_depn_code LIKE fabookdep.depn_code, 
	sort_code CHAR(1), 
	x,y,z SMALLINT, 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num 

END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("F81") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 

	CREATE temp TABLE rep_famast 
	( 
	cmpy_code CHAR(2) NOT null, 
	asset_code CHAR(10) NOT null, 
	add_on_code CHAR(10), 
	desc_text CHAR(40), 
	acquist_code CHAR(2), 
	acquist_date DATE, 
	asset_serial_text CHAR(30), 
	facat_code CHAR(3), 
	faresp_code CHAR(18), 
	location_code CHAR(10), 
	orig_auth_code CHAR(20), 
	orig_setup_date DATE, 
	orig_life_num SMALLINT, 
	orig_cost_amt money(14,2), 
	orig_po_num INTEGER, 
	vend_code CHAR(8), 
	currency_code CHAR(3), 
	orig_fcost_amt money(14,2), 
	operate_date DATE, 
	start_year_num SMALLINT, 
	start_period_num SMALLINT, 
	cgt_index_per DECIMAL(5,2), 
	tag_text CHAR(15), 
	cost_limit_amt money(14,2), 
	user1_code CHAR(5), 
	user2_code CHAR(10), 
	user3_code CHAR(20), 
	user1_amt money(14,2), 
	user2_amt money(14,2), 
	user3_amt money(14,2), 
	user1_qty DECIMAL(14,2), 
	disposal_date DATE, 
	balancing_amt money(14,2), 
	bal_chge_appl_flag CHAR(1), 
	sort1 CHAR(20), 
	desc_text1 CHAR(40), 
	sort2 CHAR(20), 
	desc_text2 CHAR(40), 
	sort3 CHAR(20), 
	desc_text3 CHAR(40), 
	book_code CHAR(2), 
	book_text CHAR(20), 
	depr_code CHAR(3) 
	) 

	CREATE unique INDEX check_asset ON rep_famast(cmpy_code, 
	asset_code, 
	add_on_code, 
	book_code, 
	facat_code, 
	location_code) 

	OPEN WINDOW w180 with FORM "F180" -- alch kd-757 
	CALL  windecoration_f("F180") -- alch kd-757 

	MENU " Asset Listing" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F81","menu-asset_list-1") -- alch kd-504 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL report_f81() 
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
			OPTIONS PROMPT line 1 
			--        prompt " " FOR rpt_note -- albo
			LET rpt_note = promptInput(" ","",132) -- albo 
			NEXT option "Report" 

		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 

END MAIN 



FUNCTION report_f81() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	famast_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_code CHAR(2), 
		book_text CHAR(20), 
		depr_code CHAR(3) 
	END RECORD, 
	no_rows SMALLINT, 
	all_assets,x,y SMALLINT, 
	word CHAR(100), 
	letter CHAR(1), 
	asset_status CHAR(15), 
	status_flag CHAR(1), 
	saved_facat_code LIKE faaudit.facat_code, 
	saved_location_code LIKE faaudit.location_code, 
	saved_faresp_code LIKE faaudit.faresp_code, 
	saved_sort1 CHAR(20), 
	saved_desc_text1 CHAR(40), 
	saved_sort2 CHAR(20), 
	saved_desc_text2 CHAR(40), 
	saved_sort3 CHAR(20), 
	saved_desc_text3 CHAR(40), 
	found_some,insert1,insert2 SMALLINT, 
	pr_acquist_year LIKE period.year_num, 
	pr_acquist_period LIKE period.period_num 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.

	CONSTRUCT BY NAME where_part ON famast.asset_code, 
	famast.add_on_code, 
	fastatus.book_code, 
	famast.desc_text, 
	famast.tag_text, 
	famast.asset_serial_text, 
	famast.acquist_code, 
	famast.orig_po_num, 
	famast.vend_code, 
	famast.currency_code, 
	famast.operate_date, 
	famast.start_year_num, 
	famast.user1_code, 
	famast.user2_code, 
	famast.user3_code, 
	famast.user1_qty, 
	famast.facat_code, 
	famast.faresp_code, 
	famast.location_code, 
	famast.orig_auth_code, 
	famast.orig_setup_date, 
	famast.acquist_date, 
	famast.cgt_index_per, 
	famast.orig_fcost_amt, 
	famast.orig_cost_amt, 
	famast.start_period_num, 
	famast.user1_amt, 
	famast.user2_amt, 
	famast.user3_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F81","const-famast-4") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	OPEN WINDOW w183 with FORM "F183" -- alch kd-757 
	CALL  windecoration_f("F183") -- alch kd-757 
	LET msgresp = kandoomsg("F",1511,"") 
	#1511 Enter year AND period.
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING pr_year_num, 
	pr_period_num 

	DISPLAY pr_year_num, pr_period_num 
	TO year_num, period_num 


	INPUT pr_year_num, pr_period_num WITHOUT DEFAULTS FROM year_num,period_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F81","inp-pr_period_num-1") -- alch kd-504 
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

	#OPEN WINDOW w_sort AT 10,10 with 11 rows, 45 columns
	#   ATTRIBUTE(border)   -- alch KD-757
	OPTIONS PROMPT line 10 
	DISPLAY " Sort Order Selection " at 2,1 
	DISPLAY " 1. Location/Category/Responsibility " at 3,1 
	DISPLAY " 2. Category/Location/Responsibility " at 4,1 
	DISPLAY " 3. Responsibility/Location/Category " at 5,1 
	DISPLAY " 4. Responsibility/Category/Location " at 6,1 
	DISPLAY " 5. Category/Authority " at 7,1 
	DISPLAY " 6. Authority/Category " at 8,1 
	DISPLAY " 7. Asset Number " at 9,1 

	WHILE (true) 
		--    prompt  "    Enter Sort Order : " FOR sort_code -- agb
		LET sort_code = promptInput(" Enter Sort Order : ","",1) -- albo 

		IF int_flag OR quit_flag THEN 
			#CLOSE WINDOW w_sort   -- alch KD-757
			RETURN 
		END IF 

		IF sort_code NOT matches "[1234567]" OR sort_code IS NULL THEN 
			LET msgresp = kandoomsg("F",9526,"") 
			#9526 Sort code must be 1,2,3,4,5,6 OR 7.
			CONTINUE WHILE 
		ELSE 
			#CLOSE WINDOW w_sort   -- alch KD-757
			EXIT WHILE 
		END IF 
	END WHILE 

	LET y = length(where_part) 

	LET word = "" 
	LET all_assets = true 

	FOR x = 1 TO y 
		LET letter = where_part[x,(x+1)] 
		IF letter = " " OR 
		letter = "=" OR 
		letter = "(" OR 
		letter = ")" OR 
		letter = "[" OR 
		letter = "]" OR 
		letter = "." OR 
		letter = "," THEN 
			LET word = "" 
		END IF 
		LET word = word clipped,letter 
		IF word = "fastatus" THEN 
			LET all_assets = false 
			EXIT FOR 
		END IF 
	END FOR 

	IF all_assets THEN {use outer join TO get all assets} 
		LET select_text = "SELECT famast.*,depr_code,book_code ", 
		"FROM famast, outer fastatus ", 
		"WHERE famast.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_part clipped," ", 
		"AND fastatus.cmpy_code = famast.cmpy_code ", 
		"AND fastatus.asset_code = famast.asset_code ", 
		"AND fastatus.add_on_code = famast.add_on_code " 
	ELSE {only get assets FOR the book selected} 
		LET select_text = "SELECT famast.*,depr_code,book_code ", 
		"FROM famast, fastatus ", 
		"WHERE famast.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_part clipped," ", 
		"AND fastatus.cmpy_code = famast.cmpy_code ", 
		"AND fastatus.asset_code = famast.asset_code ", 
		"AND fastatus.add_on_code = famast.add_on_code " 
	END IF 


	PREPARE famast_sel FROM select_text 
	DECLARE famast_curs CURSOR FOR famast_sel 

	LET no_rows = true 

	DELETE FROM rep_famast WHERE 1=1 

	FOREACH famast_curs INTO pr_famast.*,pr_depn_code,pr_book_code 

		LET no_rows = false 
		INITIALIZE famast_ext.* TO NULL 
		LET type1 = "" 
		LET type2 = "" 
		LET type3 = "" 
		CASE sort_code 
			WHEN "1" 
				LET type1 = "Location" 
				LET type2 = "Category" 
				LET type3 = "Responsibility" 

				LET famast_ext.sort1 = pr_famast.location_code 
				SELECT location_text 
				INTO famast_ext.desc_text1 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO famast_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET famast_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "2" 
				LET type1 = "Category" 
				LET type2 = "Location" 
				LET type3 = "Responsibility" 

				LET famast_ext.sort1 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.location_code 
				SELECT location_text 
				INTO famast_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO famast_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET famast_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "3" 
				LET type1 = "Responsibility" 
				LET type2 = "Location" 
				LET type3 = "Category" 

				LET famast_ext.sort1 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO famast_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.location_code 
				SELECT location_text 
				INTO famast_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text3 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "4" 
				LET type1 = "Responsibility" 
				LET type2 = "Category" 
				LET type3 = "Location" 

				LET famast_ext.sort1 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO famast_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = pr_famast.location_code 
				SELECT location_text 
				INTO famast_ext.desc_text3 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET famast_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "5" 
				LET type1 = "Category" 
				LET type2 = "Authority" 
				LET type3 = NULL 

				LET famast_ext.sort1 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.orig_auth_code 
				SELECT auth_text 
				INTO famast_ext.desc_text2 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_famast.orig_auth_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = NULL 
				LET famast_ext.desc_text3 = NULL 

			WHEN "6" 
				LET type1 = "Authority" 
				LET type2 = "Category" 
				LET type3 = NULL 

				LET famast_ext.sort1 = pr_famast.orig_auth_code 
				SELECT auth_text 
				INTO famast_ext.desc_text1 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_famast.orig_auth_code 
				IF status THEN 
					LET famast_ext.desc_text1 = "No Description on file" 
				END IF 

				LET famast_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO famast_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET famast_ext.desc_text2 = "No Description on file" 
				END IF 

				LET famast_ext.sort3 = NULL 
				LET famast_ext.desc_text3 = NULL 

			WHEN "7" 
				LET famast_ext.sort1 = NULL 
				LET famast_ext.desc_text1 = NULL 
				LET famast_ext.sort2 = NULL 
				LET famast_ext.desc_text2 = NULL 
				LET famast_ext.sort3 = NULL 
				LET famast_ext.desc_text3 = NULL 


		END CASE 

		LET famast_ext.depr_code = pr_depn_code 
		LET famast_ext.book_code = pr_book_code 

		SELECT book_text 
		INTO famast_ext.book_text 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = famast_ext.book_code 
		IF status THEN 
			LET famast_ext.book_text = "Not posted TO book" 
		END IF 

		LET saved_facat_code = pr_famast.facat_code 
		LET saved_location_code = pr_famast.location_code 
		LET saved_faresp_code = pr_famast.faresp_code 
		LET saved_sort1 = famast_ext.sort1 
		LET saved_desc_text1 = famast_ext.desc_text1 
		LET saved_sort2 = famast_ext.sort2 
		LET saved_desc_text2 = famast_ext.desc_text2 
		LET saved_sort3 = famast_ext.sort3 
		LET saved_desc_text3 = famast_ext.desc_text3 

		IF sort_code != 7 THEN 

			# SELECT all transfer records FOR year AND period selected
			# AND INSERT INTO REPORT temporary table - one only per category
			# location combination
			DECLARE trans_curs CURSOR FOR 
			SELECT * 
			FROM faaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = pr_famast.asset_code 
			AND add_on_code = pr_famast.add_on_code 
			AND book_code = pr_book_code 
			AND year_num = pr_year_num 
			AND period_num = pr_period_num 
			AND trans_ind = "T" 
			ORDER BY batch_num,status_seq_num 

			OPEN trans_curs 
			FETCH trans_curs INTO pr_faaudit.* 

			IF status THEN {no transfers FOR year AND period selected} 
				INSERT INTO rep_famast VALUES (pr_famast.*,famast_ext.*) 
			ELSE 
				FOREACH trans_curs INTO pr_faaudit.* 
					LET pr_famast.facat_code = pr_faaudit.facat_code 
					LET pr_famast.location_code = pr_faaudit.location_code 

					CALL sort_order(pr_famast.*,famast_ext.*) RETURNING famast_ext.* 

					WHENEVER ERROR CONTINUE 
					INSERT INTO rep_famast VALUES (pr_famast.*,famast_ext.*) 
					WHENEVER ERROR stop 
				END FOREACH 
			END IF 
		ELSE 
			INSERT INTO rep_famast VALUES (pr_famast.*,famast_ext.*) 
		END IF 

	END FOREACH 

	IF no_rows THEN 
		LET msgresp = kandoomsg("U",9101,"") 	#9101 No records satisfied selection criteria.
		LET int_flag = true 
		RETURN 
	END IF 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F81_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F81_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	DECLARE report_curs CURSOR FOR 
	SELECT * 
	FROM rep_famast 
	ORDER BY book_code,sort1,sort2,sort3,asset_code,add_on_code 

	#OPEN WINDOW showit AT 10,10 with 1 rows, 30 columns ATTRIBUTE(border)   -- alch KD-757

	FOREACH report_curs INTO pr_famast.*, famast_ext.* 

		# determine IF the asset IS acquired AFTER the year AND period entered
		# IF it IS THEN don't PRINT on REPORT
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_famast.acquist_date) RETURNING 
		pr_acquist_year, pr_acquist_period 
		IF pr_acquist_year > pr_year_num OR 
		(pr_acquist_year = pr_year_num AND 
		pr_acquist_period > pr_period_num) THEN 
			CONTINUE FOREACH 
		END IF 

		# determine asset STATUS sold retired OR transferred
		LET asset_status = " " 

		DECLARE chk_trn_curs CURSOR FOR 
		SELECT * 
		FROM faaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_famast.asset_code 
		AND add_on_code = pr_famast.add_on_code 
		AND book_code = famast_ext.book_code 
		AND year_num = pr_year_num 
		AND period_num = pr_period_num 
		AND trans_ind = "T" 

		OPEN chk_trn_curs 
		FETCH chk_trn_curs 
		IF NOT status THEN 
			LET asset_status = "TRANSFERRED" 
		END IF 


		SELECT * 
		INTO pr_faaudit.* 
		FROM faaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_famast.asset_code 
		AND add_on_code = pr_famast.add_on_code 
		AND book_code = famast_ext.book_code 
		AND trans_ind = "S" 
		IF NOT status THEN 
			IF pr_faaudit.year_num = pr_year_num AND 
			pr_faaudit.period_num = pr_period_num THEN 
				IF asset_status = "TRANSFERRED" THEN 
					LET asset_status = "TXFER,SOLD" 
				ELSE 
					LET asset_status = "SOLD" 
				END IF 
			END IF 

			# check IF sold previous TO year AND period entered
			IF pr_faaudit.year_num < pr_year_num OR 
			(pr_faaudit.year_num = pr_year_num AND 
			pr_faaudit.period_num < pr_period_num) THEN 
				CONTINUE FOREACH {don't REPORT IF sold previously} 
			END IF 
		END IF 

		SELECT * 
		INTO pr_faaudit.* 
		FROM faaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_famast.asset_code 
		AND add_on_code = pr_famast.add_on_code 
		AND book_code = famast_ext.book_code 
		AND trans_ind = "R" 
		IF NOT status THEN 
			IF pr_faaudit.year_num = pr_year_num AND 
			pr_faaudit.period_num = pr_period_num THEN 
				IF asset_status = "TRANSFERRED" THEN 
					LET asset_status = "TXFER,RETIRED" 
				ELSE 
					LET asset_status = "RETIRED" 
				END IF 
			END IF 

			IF pr_faaudit.year_num < pr_year_num OR 
			(pr_faaudit.year_num = pr_year_num AND 
			pr_faaudit.period_num < pr_period_num) THEN 
				CONTINUE FOREACH {don't REPORT IF retired previously} 
			END IF 
		END IF 


		DISPLAY "Printing Asset : ",pr_faaudit.asset_code at 1,1 


		#---------------------------------------------------------
		OUTPUT TO REPORT F81_rpt_list(l_rpt_idx,
		pr_famast.*,famast_ext.*,asset_status) 
		#---------------------------------------------------------

	END FOREACH 

	#CLOSE WINDOW showit   -- alch KD-757


	#------------------------------------------------------------
	FINISH REPORT F81_rpt_list
	CALL rpt_finish("F81_rpt_list")
	#------------------------------------------------------------


	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



REPORT F81_rpt_list(rr_famast,rr_famast_ext,rr_asset_status) 

	DEFINE 
	rr_faaudit RECORD LIKE faaudit.*, 
	rr_famast RECORD LIKE famast.*, 
	rr_famast_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_code CHAR(2), 
		book_text CHAR(20), 
		depn_code CHAR(2) 
	END RECORD, 
	rr_wid SMALLINT, 
	rr_book_code LIKE fabookdep.book_code, 
	rr_tmp_print CHAR(100), 
	rr_print CHAR(100), 
	rr_sort_desc CHAR(40), 
	rr_asset_status CHAR(15), 
	done_lines SMALLINT 

	OUTPUT 
	PAGE length 66 

	ORDER external BY rr_famast_ext.book_code, 
	rr_famast_ext.sort1, 
	rr_famast_ext.sort2, 
	rr_famast_ext.sort3 

	FORMAT 

		PAGE HEADER 
			IF done_lines IS NULL THEN 
				LET done_lines = false 
			END IF 
			LET rr_wid = rpt_wid 

			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text 

			IF rpt_note IS NULL THEN 
				LET rpt_note = "Asset Listing" 
			END IF 

			LET line2 = rpt_note clipped," (Menu - F81)" 
			LET offset1 = (rr_wid - length(line1))/2 
			LET offset2 = (rr_wid - length(line2))/2 
			PRINT COLUMN 1,today USING "dd/mm/yy", 
			COLUMN offset1, line1 clipped, 
			COLUMN 118,"Page : ", pageno USING "<<<<" 
			PRINT COLUMN offset2, line2 clipped 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

			PRINT COLUMN 1,"Asset Code", 
			COLUMN 15,"Add on", 
			COLUMN 30,"Description", 
			COLUMN 60,"Aq ", 
			COLUMN 66,"Aquisn ", 
			COLUMN 76,"Operate ", 
			COLUMN 86,"Depn" 

			PRINT COLUMN 1,"Tag ", 
			COLUMN 17,"Serial Number ", 
			COLUMN 49,"Vendor ", 
			COLUMN 60,"Code", 
			COLUMN 66,"Date ", 
			COLUMN 76,"Date ", 
			COLUMN 86,"Code", 
			COLUMN 95," Cost (Base Curr)", 
			COLUMN 115,"Status" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		BEFORE GROUP OF rr_famast_ext.book_code 
			SKIP TO top OF PAGE 
			CASE sort_code 
				WHEN "1" 
					LET rr_sort_desc = "Location/Category/Responsibility" 
				WHEN "2" 
					LET rr_sort_desc = "Category/Location/Responsibility" 
				WHEN "3" 
					LET rr_sort_desc = "Responsibility/Location/Category" 
				WHEN "4" 
					LET rr_sort_desc = "Responsibility/Category/Location" 
				WHEN "5" 
					LET rr_sort_desc = "Category/Authority" 
				WHEN "6" 
					LET rr_sort_desc = "Authority/Category" 
				WHEN "7" 
					LET rr_sort_desc = "Asset Number" 
			END CASE 
			LET rr_tmp_print = "Book : ",rr_famast_ext.book_code clipped," - ", 
			rr_famast_ext.book_text," Sorted by : ", 
			rr_sort_desc 
			LET x = length(rr_tmp_print) 
			PRINT COLUMN 1,rr_tmp_print 
			FOR y = 1 TO x 
				PRINT "="; 
			END FOR 
			PRINT 
			SKIP 1 LINES 
			PRINT COLUMN 1,"YEAR : ",pr_year_num USING "<<<<"," ", 
			"PERIOD : ",pr_period_num USING "<<<<" 

		BEFORE GROUP OF rr_famast_ext.sort1 
			IF type1 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type1 clipped," : ",rr_famast_ext.sort1 clipped, 
				" - ",rr_famast_ext.desc_text1 
				IF type2 IS NULL AND type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_famast_ext.sort2 
			IF type2 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type2 clipped," : ",rr_famast_ext.sort2 clipped, 
				" - ",rr_famast_ext.desc_text2 
				IF type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_famast_ext.sort3 
			IF type3 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type3 clipped," : ",rr_famast_ext.sort3 clipped, 
				" - ",rr_famast_ext.desc_text3 
				SKIP 1 LINES 
			END IF 

		ON EVERY ROW 
			LET done_lines = true 
			NEED 2 LINES 
			PRINT COLUMN 1,rr_famast.asset_code, 
			COLUMN 15,rr_famast.add_on_code, 
			COLUMN 30,rr_famast.desc_text 

			PRINT COLUMN 1,rr_famast.tag_text, 
			COLUMN 17,rr_famast.asset_serial_text, 
			COLUMN 49,rr_famast.vend_code, 
			COLUMN 60,rr_famast.acquist_code, 
			COLUMN 66,rr_famast.acquist_date USING "dd/mm/yy", 
			COLUMN 76,rr_famast.operate_date USING "dd/mm/yy", 
			COLUMN 86,rr_famast_ext.depn_code, 
			COLUMN 95,rr_famast.orig_cost_amt USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 115,rr_asset_status 

			IF rr_famast.user2_code IS NULL THEN 
				IF rr_famast.user3_code IS NOT NULL THEN 
					LET rr_famast.user2_code = rr_famast.user3_code 
					LET rr_famast.user3_code = NULL 
				END IF 
			END IF 
			IF rr_famast.user1_code IS NULL THEN 
				IF rr_famast.user2_code IS NOT NULL THEN 
					LET rr_famast.user1_code = rr_famast.user2_code 
					LET rr_famast.user2_code = NULL 
				END IF 
			END IF 

			IF rr_famast.user2_amt IS NULL OR rr_famast.user2_amt = 0 THEN 
				IF rr_famast.user3_amt IS NOT NULL THEN 
					LET rr_famast.user2_amt = rr_famast.user3_amt 
					LET rr_famast.user3_amt = NULL 
				END IF 
			END IF 
			IF rr_famast.user1_amt IS NULL OR rr_famast.user1_amt = 0 THEN 
				IF rr_famast.user2_amt IS NOT NULL AND rr_famast.user2_amt != 0 THEN 
					LET rr_famast.user1_amt = rr_famast.user2_amt 
					LET rr_famast.user2_amt = NULL 
				END IF 
			END IF 

			IF rr_famast.user1_code IS NOT NULL THEN 
				PRINT COLUMN 30,rr_famast.user1_code; 
			END IF 
			IF rr_famast.user1_amt IS NOT NULL AND rr_famast.user1_amt !=0 THEN 
				PRINT COLUMN 55,rr_famast.user1_amt USING "---,---,---,--$.&&" 
			END IF 

			IF rr_famast.user2_code IS NOT NULL THEN 
				PRINT COLUMN 30,rr_famast.user2_code; 
			END IF 
			IF rr_famast.user2_amt IS NOT NULL AND rr_famast.user2_amt !=0 THEN 
				PRINT COLUMN 55,rr_famast.user2_amt USING "---,---,---,--$.&&" 
			END IF 

			IF rr_famast.user3_code IS NOT NULL THEN 
				PRINT COLUMN 30,rr_famast.user3_code; 
			END IF 
			IF rr_famast.user3_amt IS NOT NULL AND rr_famast.user3_amt !=0 THEN 
				PRINT COLUMN 55,rr_famast.user3_amt USING "---,---,---,--$.&&" 
			END IF 

			IF rr_famast.user1_qty IS NOT NULL AND rr_famast.user1_qty !=0 THEN 
				PRINT COLUMN 30,rr_famast.user1_qty USING "---,---,---,---.&&" 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Selection Criteria : ", 
			COLUMN 25, where_part clipped wordwrap right margin 120 
			SKIP 2 LINES 
			LET rpt_pageno = pageno 
			LET rpt_length = 66 
			PRINT COLUMN 50, "******** END OF REPORT F81 ********" 

END REPORT 

FUNCTION sort_order(tmp_famast,tmp_famast_ext) 

	DEFINE 
	tmp_famast RECORD LIKE famast.*, 
	tmp_famast_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_code CHAR(2), 
		book_text CHAR(20), 
		depn_code CHAR(3) 
	END RECORD 

	CASE sort_code 
		WHEN "1" 

			LET tmp_famast_ext.sort1 = tmp_famast.location_code 
			SELECT location_text 
			INTO tmp_famast_ext.desc_text1 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_famast.location_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = tmp_famast.faresp_code 
			SELECT faresp_text 
			INTO tmp_famast_ext.desc_text3 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_famast.faresp_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "2" 

			LET tmp_famast_ext.sort1 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text1 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.location_code 
			SELECT location_text 
			INTO tmp_famast_ext.desc_text2 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_famast.location_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = tmp_famast.faresp_code 
			SELECT faresp_text 
			INTO tmp_famast_ext.desc_text3 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_famast.faresp_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "3" 

			LET tmp_famast_ext.sort1 = tmp_famast.faresp_code 
			SELECT faresp_text 
			INTO tmp_famast_ext.desc_text1 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_famast.faresp_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.location_code 
			SELECT location_text 
			INTO tmp_famast_ext.desc_text2 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_famast.location_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text3 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "4" 

			LET tmp_famast_ext.sort1 = tmp_famast.faresp_code 
			SELECT faresp_text 
			INTO tmp_famast_ext.desc_text1 
			FROM faresp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND faresp_code = tmp_famast.faresp_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = tmp_famast.location_code 
			SELECT location_text 
			INTO tmp_famast_ext.desc_text3 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_famast.location_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text3 = "No Description on file" 
			END IF 

		WHEN "5" 

			LET tmp_famast_ext.sort1 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text1 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.orig_auth_code 
			SELECT auth_text 
			INTO tmp_famast_ext.desc_text2 
			FROM faauth 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND auth_code = tmp_famast.orig_auth_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = NULL 
			LET tmp_famast_ext.desc_text3 = NULL 

		WHEN "6" 

			LET tmp_famast_ext.sort1 = tmp_famast.orig_auth_code 
			SELECT auth_text 
			INTO tmp_famast_ext.desc_text1 
			FROM faauth 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND auth_code = tmp_famast.orig_auth_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text1 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort2 = tmp_famast.facat_code 
			SELECT facat_text 
			INTO tmp_famast_ext.desc_text2 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_famast.facat_code 
			IF status THEN 
				LET tmp_famast_ext.desc_text2 = "No Description on file" 
			END IF 

			LET tmp_famast_ext.sort3 = NULL 
			LET tmp_famast_ext.desc_text3 = NULL 

		WHEN "7" 
			LET tmp_famast_ext.sort1 = NULL 
			LET tmp_famast_ext.desc_text1 = NULL 
			LET tmp_famast_ext.sort2 = NULL 
			LET tmp_famast_ext.desc_text2 = NULL 
			LET tmp_famast_ext.sort3 = NULL 
			LET tmp_famast_ext.desc_text3 = NULL 


	END CASE 

	RETURN tmp_famast_ext.* 

END FUNCTION 
