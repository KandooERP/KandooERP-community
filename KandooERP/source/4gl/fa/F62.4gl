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
GLOBALS "../fa/F62_GLOBALS.4gl"

# Purpose   :   Asset Detail Report

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
	x,y,z SMALLINT 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("F62") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 

	CREATE temp TABLE rep_faaudit 
	( 
	cmpy_code CHAR(2), 
	asset_code CHAR(10), 
	add_on_code CHAR(10), 
	book_code CHAR(2), 
	year_num SMALLINT, 
	period_num SMALLINT, 
	batch_line_num INTEGER, 
	trans_ind CHAR(1), 
	entry_text CHAR(8), 
	entry_date DATE, 
	asset_amt money(14,2), 
	depr_amt money(14,2), 
	net_book_val_amt money(14,2), 
	rem_life_num SMALLINT, 
	location_code CHAR(10), 
	faresp_code CHAR(18), 
	facat_code CHAR(3), 
	batch_num INTEGER, 
	status_seq_num INTEGER, 
	desc_text CHAR(30), 
	auth_code CHAR(20), 
	salvage_amt money(14,2), 
	sale_amt money(14,2), 

	sort1 CHAR(20), 
	desc_text1 CHAR(40), 
	sort2 CHAR(20), 
	desc_text2 CHAR(40), 
	sort3 CHAR(20), 
	desc_text3 CHAR(40), 
	book_text CHAR(20), 
	depr_code CHAR(3) 
	) 

	OPEN WINDOW f143 with FORM "F143" -- alch kd-757 
	CALL  windecoration_f("F143") -- alch kd-757 

	MENU " Asset Additions" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F62","menu-asset_add-1") -- alch kd-504 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL report_f62() 
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
			--        prompt " " FOR rpt_note  -- albo
			LET rpt_note = promptInput(" ","",132) -- albo 
			NEXT option "Report" 
		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
	CLOSE WINDOW f143 
END MAIN 



FUNCTION report_f62() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	faaudit_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_text CHAR(20), 
		depr_code CHAR(3) 
	END RECORD, 
	no_rows SMALLINT 

	DISPLAY "A" TO trans_ind 


	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.

	CONSTRUCT BY NAME where_part ON faaudit.asset_code, 
	faaudit.add_on_code, 
	faaudit.year_num, 
	faaudit.period_num, 
	faaudit.desc_text, 
	faaudit.asset_amt, 
	faaudit.depr_amt, 
	faaudit.net_book_val_amt, 
	faaudit.book_code, 
	faaudit.facat_code, 
	faaudit.location_code, 
	faaudit.faresp_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F62","const-faaudit-3") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	#OPEN WINDOW w_sort AT 10,10 with 11 rows, 45 columns ATTRIBUTE(border)   -- alch KD-757

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
		--    prompt  "    Enter Sort Order : " FOR sort_code -- albo
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


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F62_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F62_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET select_text = "SELECT faaudit.*,depr_code ", 
	"FROM faaudit, fastatus ", 
	"WHERE faaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND faaudit.trans_ind = \"A\" ", 
	"AND ",where_part clipped," ", 
	"AND fastatus.cmpy_code = faaudit.cmpy_code ", 
	"AND fastatus.asset_code = faaudit.asset_code ", 
	"AND fastatus.add_on_code = faaudit.add_on_code ", 
	"AND fastatus.book_code = faaudit.book_code " 


	PREPARE faaudit_sel FROM select_text 
	DECLARE faaudit_curs CURSOR FOR faaudit_sel 

	LET no_rows = true 

	DELETE FROM rep_faaudit WHERE 1=1 

	FOREACH faaudit_curs INTO pr_faaudit.*,pr_depn_code 
		LET no_rows = false 
		INITIALIZE faaudit_ext.* TO NULL 
		LET type1 = "" 
		LET type2 = "" 
		LET type3 = "" 
		CASE sort_code 
			WHEN "1" 
				LET type1 = "Location" 
				LET type2 = "Category" 
				LET type3 = "Responsibility" 

				LET faaudit_ext.sort1 = pr_faaudit.location_code 
				SELECT location_text 
				INTO faaudit_ext.desc_text1 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_faaudit.location_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = pr_faaudit.faresp_code 
				SELECT faresp_text 
				INTO faaudit_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_faaudit.faresp_code 
				IF status THEN 
					LET faaudit_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "2" 
				LET type1 = "Category" 
				LET type2 = "Location" 
				LET type3 = "Responsibility" 

				LET faaudit_ext.sort1 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.location_code 
				SELECT location_text 
				INTO faaudit_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_faaudit.location_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = pr_faaudit.faresp_code 
				SELECT faresp_text 
				INTO faaudit_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_faaudit.faresp_code 
				IF status THEN 
					LET faaudit_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "3" 
				LET type1 = "Responsibility" 
				LET type2 = "Location" 
				LET type3 = "Category" 

				LET faaudit_ext.sort1 = pr_faaudit.faresp_code 
				SELECT faresp_text 
				INTO faaudit_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_faaudit.faresp_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.location_code 
				SELECT location_text 
				INTO faaudit_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_faaudit.location_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text3 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "4" 
				LET type1 = "Responsibility" 
				LET type2 = "Category" 
				LET type3 = "Location" 

				LET faaudit_ext.sort1 = pr_faaudit.faresp_code 
				SELECT faresp_text 
				INTO faaudit_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_faaudit.faresp_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = pr_faaudit.location_code 
				SELECT location_text 
				INTO faaudit_ext.desc_text3 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_faaudit.location_code 
				IF status THEN 
					LET faaudit_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "5" 
				LET type1 = "Category" 
				LET type2 = "Authority" 
				LET type3 = NULL 

				LET faaudit_ext.sort1 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.auth_code 
				SELECT auth_text 
				INTO faaudit_ext.desc_text2 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_faaudit.auth_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = NULL 
				LET faaudit_ext.desc_text3 = NULL 

			WHEN "6" 
				LET type1 = "Authority" 
				LET type2 = "Category" 
				LET type3 = NULL 

				LET faaudit_ext.sort1 = pr_faaudit.auth_code 
				SELECT auth_text 
				INTO faaudit_ext.desc_text1 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_faaudit.auth_code 
				IF status THEN 
					LET faaudit_ext.desc_text1 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort2 = pr_faaudit.facat_code 
				SELECT facat_text 
				INTO faaudit_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_faaudit.facat_code 
				IF status THEN 
					LET faaudit_ext.desc_text2 = "No Description on file" 
				END IF 

				LET faaudit_ext.sort3 = NULL 
				LET faaudit_ext.desc_text3 = NULL 

			WHEN "7" 
				LET faaudit_ext.sort1 = NULL 
				LET faaudit_ext.desc_text1 = NULL 
				LET faaudit_ext.sort2 = NULL 
				LET faaudit_ext.desc_text2 = NULL 
				LET faaudit_ext.sort3 = NULL 
				LET faaudit_ext.desc_text3 = NULL 


		END CASE 

		LET faaudit_ext.depr_code = pr_depn_code 

		SELECT book_text 
		INTO faaudit_ext.book_text 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = pr_faaudit.book_code 
		IF status THEN 
			LET faaudit_ext.book_text = "No description on file" 
		END IF 

		INSERT INTO rep_faaudit VALUES (pr_faaudit.*,faaudit_ext.*) 

	END FOREACH 

	IF no_rows THEN 
		LET msgresp = kandoomsg("U",9101,"") 	#9101 No records satisfied selection criteria.
		LET int_flag = true 
		RETURN 
	END IF 



	DECLARE report_curs CURSOR FOR 
	SELECT * 
	FROM rep_faaudit 
	ORDER BY book_code,sort1,sort2,sort3,asset_code,add_on_code 

	#OPEN WINDOW showit AT 10,10 with 1 rows, 30 columns ATTRIBUTE(border)   -- alch KD-757

	FOREACH report_curs INTO pr_faaudit.*, faaudit_ext.* 

		DISPLAY "Printing Asset : ",pr_faaudit.asset_code at 1,1 

		SELECT * 
		INTO pr_famast.* 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 

		SELECT * 
		INTO pr_fastatus.* 
		FROM fastatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = pr_faaudit.asset_code 
		AND add_on_code = pr_faaudit.add_on_code 
		AND book_code = pr_faaudit.book_code 
		#---------------------------------------------------------
		OUTPUT TO REPORT F62_rpt_list(l_rpt_idx,
		pr_faaudit.*,faaudit_ext.*,pr_famast.*)
		#--------------------------------------------------------- 
	END FOREACH 

	#CLOSE WINDOW showit   -- alch KD-757
	#------------------------------------------------------------
	FINISH REPORT F62_rpt_list
	CALL rpt_finish("F62_rpt_list")
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
# REPORT F62_rpt_list(p_rpt_idx,rr_faaudit,rr_faaudit_ext,rr_famast) 
#
#
###########################################################################
REPORT F62_rpt_list(p_rpt_idx,rr_faaudit,rr_faaudit_ext,rr_famast) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rr_faaudit RECORD LIKE faaudit.*, 
	rr_famast RECORD LIKE famast.*, 
	rr_faaudit_ext RECORD 
		sort1 CHAR(20), 
		desc_text1 CHAR(40), 
		sort2 CHAR(20), 
		desc_text2 CHAR(40), 
		sort3 CHAR(20), 
		desc_text3 CHAR(40), 
		book_text CHAR(20), 
		depn_code CHAR(2) 
	END RECORD, 
	rr_wid SMALLINT, 
	rr_book_code LIKE fabookdep.book_code, 
	rr_tmp_print CHAR(100), 
	rr_print CHAR(100), 
	rr_sort_desc CHAR(40) 

	OUTPUT 
	PAGE length 66 

	ORDER external BY rr_faaudit.book_code, 
	rr_faaudit_ext.sort1, 
	rr_faaudit_ext.sort2, 
	rr_faaudit_ext.sort3 

	FORMAT 

		PAGE HEADER 
			LET rr_wid = rpt_wid 

			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text 

			IF rpt_note IS NULL THEN 
				LET rpt_note = "Asset Additions" 
			END IF 

			LET line2 = rpt_note clipped," (Menu - F62)" 
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
			COLUMN 30,"Description" 

			PRINT COLUMN 1,"Vendor", 
			COLUMN 12,"Aq", 
			COLUMN 17,"Op Date", 
			COLUMN 26,"Depn", 
			COLUMN 50," Orig Cost", 
			COLUMN 70," Accumulated Depn", 
			COLUMN 90," Nett Book Value", 
			COLUMN 110," Salvage Value" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		BEFORE GROUP OF rr_faaudit.book_code 
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
			LET rr_tmp_print = "Book : ",rr_faaudit.book_code clipped," - ", 
			rr_faaudit_ext.book_text," Sorted by : ", 
			rr_sort_desc 
			LET x = length(rr_tmp_print) 
			PRINT COLUMN 1,rr_tmp_print 
			FOR y = 1 TO x 
				PRINT "="; 
			END FOR 
			PRINT 
			SKIP 1 LINES 

		BEFORE GROUP OF rr_faaudit_ext.sort1 
			IF type1 IS NOT NULL THEN 
				PRINT COLUMN 1,type1 clipped," : ",rr_faaudit_ext.sort1 clipped, 
				" - ",rr_faaudit_ext.desc_text1 
				IF type2 IS NULL AND type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_faaudit_ext.sort2 
			IF type2 IS NOT NULL THEN 
				PRINT COLUMN 1,type2 clipped," : ",rr_faaudit_ext.sort2 clipped, 
				" - ",rr_faaudit_ext.desc_text2 
				IF type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_faaudit_ext.sort3 
			IF type3 IS NOT NULL THEN 
				PRINT COLUMN 1,type3 clipped," : ",rr_faaudit_ext.sort3 clipped, 
				" - ",rr_faaudit_ext.desc_text3 
				SKIP 1 LINES 
			END IF 

		ON EVERY ROW 
			NEED 2 LINES 
			PRINT COLUMN 1,rr_faaudit.asset_code, 
			COLUMN 15,rr_faaudit.add_on_code, 
			COLUMN 30,rr_famast.desc_text 

			PRINT COLUMN 1,rr_famast.vend_code, 
			COLUMN 12,rr_famast.acquist_code, 
			COLUMN 17,rr_famast.operate_date USING "dd/mm/yy", 
			COLUMN 26,rr_faaudit_ext.depn_code, 
			COLUMN 50,rr_famast.orig_cost_amt USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 70,rr_faaudit.depr_amt USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 90,rr_faaudit.net_book_val_amt 
			USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 110,rr_faaudit.salvage_amt USING "$$$$,$$$,$$$,$$&.&&" 


		AFTER GROUP OF rr_faaudit_ext.sort1 
			IF type1 IS NOT NULL THEN 
				IF type2 IS NULL AND type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
				PRINT COLUMN 1,type1 clipped," Sub Total ", 
				COLUMN 50,"-------------------", 
				COLUMN 70,"-------------------", 
				COLUMN 90,"-------------------", 
				COLUMN 110,"-------------------" 
				LET rr_print = rr_faaudit_ext.sort1 clipped," - ", 
				rr_faaudit_ext.desc_text1 
				PRINT COLUMN 1,rr_print[1,49], 
				COLUMN 50,group sum(rr_famast.orig_cost_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 70,group sum(rr_faaudit.depr_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 90,group sum(rr_faaudit.net_book_val_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 110,group sum(rr_faaudit.salvage_amt) 
				USING "$$$$,$$$,$$$,$$&.&&" 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF rr_faaudit_ext.sort2 
			IF type2 IS NOT NULL THEN 
				IF type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
				PRINT COLUMN 1,type2 clipped," Sub Total ", 
				COLUMN 50,"-------------------", 
				COLUMN 70,"-------------------", 
				COLUMN 90,"-------------------", 
				COLUMN 110,"-------------------" 
				LET rr_print = rr_faaudit_ext.sort2 clipped," - ", 
				rr_faaudit_ext.desc_text2 
				PRINT COLUMN 1,rr_print[1,49], 
				COLUMN 50,group sum(rr_famast.orig_cost_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 70,group sum(rr_faaudit.depr_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 90,group sum(rr_faaudit.net_book_val_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 110,group sum(rr_faaudit.salvage_amt) 
				USING "$$$$,$$$,$$$,$$&.&&" 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF rr_faaudit_ext.sort3 
			IF type3 IS NOT NULL THEN 
				SKIP 1 LINES 
				PRINT COLUMN 1,type3 clipped," Sub Total ", 
				COLUMN 50,"-------------------", 
				COLUMN 70,"-------------------", 
				COLUMN 90,"-------------------", 
				COLUMN 110,"-------------------" 
				LET rr_print = rr_faaudit_ext.sort3 clipped," - ", 
				rr_faaudit_ext.desc_text3 
				PRINT COLUMN 1,rr_print[1,49], 
				COLUMN 50,group sum(rr_famast.orig_cost_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 70,group sum(rr_faaudit.depr_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 90,group sum(rr_faaudit.net_book_val_amt) 
				USING "$$$$,$$$,$$$,$$&.&&", 
				COLUMN 110,group sum(rr_faaudit.salvage_amt) 
				USING "$$$$,$$$,$$$,$$&.&&" 
			END IF 
			SKIP 1 LINES 

		AFTER GROUP OF rr_faaudit.book_code 
			SKIP 1 LINES 
			NEED 2 LINES 
			PRINT "Book : ",rr_faaudit.book_code," TOTAL", 
			COLUMN 50,group sum(rr_famast.orig_cost_amt) 
			USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 70,group sum(rr_faaudit.depr_amt) 
			USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 90,group sum(rr_faaudit.net_book_val_amt) 
			USING "$$$$,$$$,$$$,$$&.&&", 
			COLUMN 110,group sum(rr_faaudit.salvage_amt) 
			USING "$$$$,$$$,$$$,$$&.&&" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
