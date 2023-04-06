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

# Purpose   :   Asset Lease Detail Report - culled FROM F81

GLOBALS 

	DEFINE 

	pr_falease RECORD LIKE falease.*, 
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
	CALL setModuleId("F83") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 

	CREATE temp TABLE rep_falease 
	( 
	cmpy_code CHAR(2), 
	asset_code CHAR(10), 
	add_on_code CHAR(10), 
	lease_value_amt money(14,2), 
	lease_tot_rent_amt money(14,2), 
	lease_st_date DATE, 
	lease_end_date DATE, 
	install_value_amt money(14,2), 
	lease_no_inst_num SMALLINT, 
	lease_residual_amt money(14,2), 
	lease_imp_per DECIMAL(5,2), 
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

	OPEN WINDOW w185 with FORM "F185" -- alch kd-757 
	CALL  windecoration_f("F185") -- alch kd-757 

	MENU " Lease Details" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F83","menu-leas_det-1") -- alch kd-504 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL report_f83() 
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
			--         prompt " " FOR rpt_note -- albo
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



FUNCTION report_f83() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	falease_ext RECORD 
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
	no_rows SMALLINT 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.
	CONSTRUCT BY NAME where_part ON falease.asset_code, 
	falease.add_on_code, 
	famast.facat_code, 
	famast.location_code, 
	falease.lease_value_amt, 
	falease.lease_tot_rent_amt, 
	falease.lease_st_date, 
	falease.lease_end_date, 
	falease.install_value_amt, 
	falease.lease_no_inst_num, 
	falease.lease_residual_amt, 
	falease.lease_imp_per 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F83","const-falease-3") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	#OPEN WINDOW w_sort AT 10,10 with 11 rows, 45 columns ATTRIBUTE(border)  -- alch KD-757

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
			#CLOSE WINDOW w_sort  -- alch KD-757
			RETURN 
		END IF 

		IF sort_code NOT matches "[1234567]" OR sort_code IS NULL THEN 
			LET msgresp = kandoomsg("F",9526,"") 
			#9526 Sort code must be 1,2,3,4,5,6 OR 7.
			CONTINUE WHILE 
		ELSE 
			#CLOSE WINDOW w_sort  -- alch KD-757
			EXIT WHILE 
		END IF 
	END WHILE 

	LET select_text = "SELECT falease.*,famast.* ", 
	"FROM falease,famast ", 
	"WHERE falease.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_part clipped," ", 
	"AND falease.cmpy_code = famast.cmpy_code ", 
	"AND falease.asset_code = famast.asset_code ", 
	"AND falease.add_on_code = famast.add_on_code " 

	PREPARE falease_sel FROM select_text 
	DECLARE falease_curs CURSOR FOR falease_sel 

	LET no_rows = true 

	DELETE FROM rep_falease WHERE 1=1 

	FOREACH falease_curs INTO pr_falease.*,pr_famast.* 

		LET no_rows = false 
		INITIALIZE falease_ext.* TO NULL 
		LET type1 = "" 
		LET type2 = "" 
		LET type3 = "" 
		CASE sort_code 
			WHEN "1" 
				LET type1 = "Location" 
				LET type2 = "Category" 
				LET type3 = "Responsibility" 

				LET falease_ext.sort1 = pr_famast.location_code 
				SELECT location_text 
				INTO falease_ext.desc_text1 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO falease_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET falease_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "2" 
				LET type1 = "Category" 
				LET type2 = "Location" 
				LET type3 = "Responsibility" 

				LET falease_ext.sort1 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.location_code 
				SELECT location_text 
				INTO falease_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO falease_ext.desc_text3 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET falease_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "3" 
				LET type1 = "Responsibility" 
				LET type2 = "Location" 
				LET type3 = "Category" 

				LET falease_ext.sort1 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO falease_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.location_code 
				SELECT location_text 
				INTO falease_ext.desc_text2 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text3 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "4" 
				LET type1 = "Responsibility" 
				LET type2 = "Category" 
				LET type3 = "Location" 

				LET falease_ext.sort1 = pr_famast.faresp_code 
				SELECT faresp_text 
				INTO falease_ext.desc_text1 
				FROM faresp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND faresp_code = pr_famast.faresp_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = pr_famast.location_code 
				SELECT location_text 
				INTO falease_ext.desc_text3 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_famast.location_code 
				IF status THEN 
					LET falease_ext.desc_text3 = "No Description on file" 
				END IF 

			WHEN "5" 
				LET type1 = "Category" 
				LET type2 = "Authority" 
				LET type3 = NULL 

				LET falease_ext.sort1 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text1 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.orig_auth_code 
				SELECT auth_text 
				INTO falease_ext.desc_text2 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_famast.orig_auth_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = NULL 
				LET falease_ext.desc_text3 = NULL 

			WHEN "6" 
				LET type1 = "Authority" 
				LET type2 = "Category" 
				LET type3 = NULL 

				LET falease_ext.sort1 = pr_famast.orig_auth_code 
				SELECT auth_text 
				INTO falease_ext.desc_text1 
				FROM faauth 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND auth_code = pr_famast.orig_auth_code 
				IF status THEN 
					LET falease_ext.desc_text1 = "No Description on file" 
				END IF 

				LET falease_ext.sort2 = pr_famast.facat_code 
				SELECT facat_text 
				INTO falease_ext.desc_text2 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_famast.facat_code 
				IF status THEN 
					LET falease_ext.desc_text2 = "No Description on file" 
				END IF 

				LET falease_ext.sort3 = NULL 
				LET falease_ext.desc_text3 = NULL 

			WHEN "7" 
				LET falease_ext.sort1 = NULL 
				LET falease_ext.desc_text1 = NULL 
				LET falease_ext.sort2 = NULL 
				LET falease_ext.desc_text2 = NULL 
				LET falease_ext.sort3 = NULL 
				LET falease_ext.desc_text3 = NULL 


		END CASE 

		INSERT INTO rep_falease VALUES (pr_falease.*,falease_ext.*) 

	END FOREACH 

	IF no_rows THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101 No records satisfied selection criteria.
		LET int_flag = true 
		RETURN 
	END IF 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F83_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F83_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	DECLARE report_curs CURSOR FOR 
	SELECT * 
	FROM rep_falease 
	ORDER BY book_code,sort1,sort2,sort3,asset_code,add_on_code 

	#OPEN WINDOW showit AT 10,10 with 1 rows, 30 columns ATTRIBUTE(border)  -- alch KD-757

	FOREACH report_curs INTO pr_falease.*, falease_ext.* 

		DISPLAY "Printing Asset : ",pr_faaudit.asset_code at 1,1 

		#---------------------------------------------------------
		OUTPUT TO REPORT F83_rpt_list(l_rpt_idx,
		pr_falease.*,falease_ext.*) 
		#---------------------------------------------------------
	END FOREACH 

	#CLOSE WINDOW showit  -- alch KD-757

	#------------------------------------------------------------
	FINISH REPORT F83_rpt_list
	CALL rpt_finish("F83_rpt_list")
	#------------------------------------------------------------


	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



REPORT F83_rpt_list(rr_falease,rr_falease_ext) 

	DEFINE 
	rr_faaudit RECORD LIKE faaudit.*, 
	rr_famast RECORD LIKE famast.*, 
	rr_falease RECORD LIKE falease.*, 
	rr_falease_ext RECORD 
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

	ORDER external BY rr_falease_ext.sort1, 
	rr_falease_ext.sort2, 
	rr_falease_ext.sort3 

	FORMAT 

		PAGE HEADER 
			IF done_lines IS NULL THEN 
				LET done_lines = false 
			END IF 
			LET rr_wid = rpt_wid 

			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text 

			IF rpt_note IS NULL THEN 
				LET rpt_note = "Asset Lease Listing" 
			END IF 

			LET line2 = rpt_note clipped," (Menu - F83)" 
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
			COLUMN 71,"Start Date", 
			COLUMN 82,"END Date ", 
			COLUMN 93,"No Instal.", 
			COLUMN 104,"Implicit Interest" 


			PRINT COLUMN 50," Lease Value", 
			COLUMN 70," Lease Total Rent", 
			COLUMN 90," Install Value", 
			COLUMN 110," Residual Value" 


			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"------------------------------------------------" 

		BEFORE GROUP OF rr_falease_ext.sort1 
			IF type1 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type1 clipped," : ",rr_falease_ext.sort1 clipped, 
				" - ",rr_falease_ext.desc_text1 
				IF type2 IS NULL AND type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_falease_ext.sort2 
			IF type2 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type2 clipped," : ",rr_falease_ext.sort2 clipped, 
				" - ",rr_falease_ext.desc_text2 
				IF type3 IS NULL THEN 
					SKIP 1 LINES 
				END IF 
			END IF 

		BEFORE GROUP OF rr_falease_ext.sort3 
			IF type3 IS NOT NULL THEN 
				IF done_lines THEN 
					SKIP 1 LINES 
					LET done_lines = false 
				END IF 
				PRINT COLUMN 1,type3 clipped," : ",rr_falease_ext.sort3 clipped, 
				" - ",rr_falease_ext.desc_text3 
				SKIP 1 LINES 
			END IF 

		ON EVERY ROW 
			LET rr_famast.desc_text = " " 
			SELECT desc_text 
			INTO rr_famast.desc_text 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = rr_falease.asset_code 
			AND add_on_code = rr_falease.add_on_code 

			LET done_lines = true 
			NEED 2 LINES 
			PRINT COLUMN 1,rr_falease.asset_code, 
			COLUMN 15,rr_falease.add_on_code, 
			COLUMN 30,rr_famast.desc_text, 
			COLUMN 71,rr_falease.lease_st_date USING "dd/mm/yy", 
			COLUMN 82,rr_falease.lease_end_date USING "dd/mm/yy", 
			COLUMN 93,rr_falease.lease_no_inst_num USING "<<<<<", 
			COLUMN 114,rr_falease.lease_imp_per USING "###.##%" 

			PRINT COLUMN 50,rr_falease.lease_value_amt USING "----,---,---,--$.&&", 
			COLUMN 70,rr_falease.lease_tot_rent_amt 
			USING "----,---,---,--$.&&", 
			COLUMN 90,rr_falease.install_value_amt 
			USING "----,---,---,--$.&&", 
			COLUMN 110,rr_falease.lease_residual_amt 
			USING "----,---,---,--$.&&" 
			SKIP 1 LINES 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Selection Criteria : ", 
			COLUMN 25, where_part clipped wordwrap right margin 120 
			SKIP 2 LINES 
			LET rpt_pageno = pageno 
			LET rpt_length = 66 
			PRINT COLUMN 50, "******** END OF REPORT F83 ********" 

END REPORT 

