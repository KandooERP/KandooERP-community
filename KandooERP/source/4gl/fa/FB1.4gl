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

# Purpose    :   Batch detail REPORT

GLOBALS 

	DEFINE 

	pr_famast RECORD LIKE famast.*, 
	pr_fabatch RECORD LIKE fabatch.*, 
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
	pr_page_break CHAR(1) 

END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("FB1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 

	OPEN WINDOW w187 with FORM "F187" -- alch kd-757 
	CALL  windecoration_f("F187") -- alch kd-757 
	MENU " Batch Detail" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","FB1","menu-batch_det-1") -- alch kd-504 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL report_fb1() 
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
			-- prompt " " FOR rpt_note  -- albo
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



FUNCTION report_fb1() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE no_rows SMALLINT 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.

	CONSTRUCT BY NAME where_part ON fabatch.batch_num, 
	fabatch.year_num, 
	fabatch.period_num, 
	fabatch.com1_text, 
	fabatch.com2_text, 
	fabatch.actual_asset_amt, 
	fabatch.actual_depr_amt, 
	fabatch.cleared_flag, 
	fabatch.post_asset_flag, 
	fabatch.post_gl_flag, 
	fabatch.jour_num, 
	faaudit.trans_ind 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","FB1","const-fabatch-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	LET pr_page_break = kandoomsg("F",8010,"") 
	#8010 New page each batch? (Y/N):

	LET select_text = "SELECT faaudit.* ", 
	"FROM fabatch, faaudit ", 
	"WHERE fabatch.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_part clipped," ", 
	"AND fabatch.cmpy_code = faaudit.cmpy_code ", 
	"AND fabatch.batch_num = faaudit.batch_num ", 
	"ORDER BY faaudit.batch_num,faaudit.batch_line_num " 

	PREPARE faaudit_sel FROM select_text 
	DECLARE faaudit_curs CURSOR FOR faaudit_sel 

	LET no_rows = true 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"FB1_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT FB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	#OPEN WINDOW showit AT 10,10 with 1 rows, 30 columns ATTRIBUTE(border)  -- alch KD-757

	FOREACH faaudit_curs INTO pr_faaudit.* 

		LET no_rows = false 

		DISPLAY "Printing Batch : ",pr_faaudit.batch_num at 1,1 

		#---------------------------------------------------------
		OUTPUT TO REPORT FB1_rpt_list(l_rpt_idx,
		pr_faaudit.*) 
		#---------------------------------------------------------

	END FOREACH 

	#CLOSE WINDOW showit  -- alch KD-757



	IF no_rows THEN 
		LET msgresp = kandoomsg("U",9101,"") 	#9101 No records satisfied selection criteria.
		LET int_flag = true 
		RETURN FALSE
	END IF 

	#------------------------------------------------------------
	FINISH REPORT FB1_rpt_list
	CALL rpt_finish("FB1_rpt_list")
	#------------------------------------------------------------


	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



REPORT FB1_rpt_list(rr_faaudit) 

	DEFINE 
	rr_fabatch RECORD LIKE fabatch.*, 
	rr_faaudit RECORD LIKE faaudit.*, 
	rr_famast RECORD LIKE famast.*, 
	rr_fastatus RECORD LIKE fastatus.*, 
	rr_wid SMALLINT, 
	rr_book_code LIKE fabookdep.book_code, 
	rr_tmp_print CHAR(100), 
	rr_print CHAR(100), 
	rr_sort_desc CHAR(40), 
	rr_line1, 
	rr_line2, 
	rr_line3 CHAR(131), 
	done_lines SMALLINT, 
	capital_gain, 
	gain, 
	loss DECIMAL(9,2), 
	rr_depn_code LIKE fastatus.depr_code 

	OUTPUT 
	PAGE length 66 

	ORDER external BY rr_faaudit.batch_num, 
	rr_faaudit.trans_ind 

	FORMAT 

		PAGE HEADER 
			LET rr_wid = rpt_wid 

			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text 

			IF rpt_note IS NULL THEN 
				LET rpt_note = "Batch Detail" 
			END IF 

			LET line2 = rpt_note clipped," (Menu - FB1)" 
			LET offset1 = (rr_wid - length(line1))/2 
			LET offset2 = (rr_wid - length(line2))/2 
			PRINT COLUMN 1,today USING "dd/mm/yy", 
			COLUMN offset1, line1 clipped, 
			COLUMN 118,"Page : ", pageno USING "<<<<" 
			PRINT COLUMN offset2, line2 clipped 

			PRINT COLUMN 1, "----------------------------------------", 
			"-------------------------------------------", 
			"------------------------------------------------" 

			SELECT * 
			INTO rr_fabatch.* 
			FROM fabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND batch_num = rr_faaudit.batch_num 

			PRINT COLUMN 1,"Batch : ",rr_fabatch.batch_num USING "<<<<<", 
			COLUMN 30,"Transaction Total : ",rr_fabatch.actual_asset_amt 
			USING "--,---,---,---,-$&.&&", 
			COLUMN 73,"Cleared : ",rr_fabatch.cleared_flag, 
			COLUMN 100,"Posted TO GL : ",rr_fabatch.post_gl_flag 

			PRINT COLUMN 1,"Year : ",rr_fabatch.year_num USING "<<<<", 
			COLUMN 30,"Depreciation Total : ",rr_fabatch.actual_depr_amt 
			USING "--,---,---,---,-$&.&&", 
			COLUMN 73,"Posted TO Asset : ",rr_fabatch.post_asset_flag, 
			COLUMN 100,"GL Journal Number : ", 
			rr_fabatch.jour_num USING "<<<<<" 
			PRINT COLUMN 1,"Period : ",rr_fabatch.period_num USING "<<<" 

			PRINT COLUMN 1, "----------------------------------------", 
			"-------------------------------------------", 
			"------------------------------------------------" 

			CASE rr_faaudit.trans_ind 
				WHEN "A" 
					LET rr_line1 = "Additions" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					"Authority Code ", 
					" Net Book Value ", 
					" Accumulated Depn ", 
					" Salvage Value ", 
					"Life ", 
					"Location ", 
					"Responsibility ", 
					"Cat" 

				WHEN "J" 
					LET rr_line1 = "Adjustments" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					"Authority Code ", 
					" Cost Adjustment ", 
					" Depn Adjustment ", 
					" Salvage Adjustment " 

				WHEN "T" 
					LET rr_line1 = "Transfers" 

					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description ", 
					"Book " 

					LET rr_line3 = " ", 
					"Location ", 
					"Cat ", 
					" ", 
					" Net Book Value ", 
					" Transfer Amount ", 
					" Accumulated Depn ", 
					" Salvage Value " 

				WHEN "R" 
					LET rr_line1 = "Retirements" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					" ", 
					" ", 
					" Current Cost ", 
					" Accumulated Depn ", 
					" Salvage Value ", 
					" Retirement Amount " 

				WHEN "V" 
					LET rr_line1 = "Revaluations" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					" ", 
					" ", 
					" New Net Book Value ", 
					" Accumulated Depn ", 
					" Salvage Value ", 
					" Revaluation Amount " 

				WHEN "S" 
					LET rr_line1 = "Sales" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					" ", 
					" Current Cost ", 
					" Accumulated Depn ", 
					" Sale Amount ", 
					"Capital Gain ", 
					" Gain ", 
					" Loss " 

				WHEN "L" 
					LET rr_line1 = "Life Adjustments" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					" ", 
					" Current Cost ", 
					" Accumulated Depn ", 
					" Salvage Value ", 
					" New Life" 

				WHEN "C" 
					LET rr_line1 = "Depn Code Change" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					"Authority Code ", 
					" Current Cost ", 
					" Accumulated Depn ", 
					" Salvage Value ", 
					"Life" 
				WHEN "D" 
					LET rr_line1 = "Depreciation Calculation" 
					LET rr_line2 = "Line ", 
					"Asset Code ", 
					"Add on ", 
					"Description" 

					LET rr_line3 = "Book ", 
					"Authority Code ", 
					" ", 
					"Life ", 
					"Depn Code ", 
					" Current Cost ", 
					"Depreciation Charge " 
			END CASE 

			PRINT COLUMN 1,rr_line1 
			PRINT COLUMN 1,rr_line2 
			PRINT COLUMN 8,rr_line3 

			PRINT COLUMN 1, "----------------------------------------", 
			"-------------------------------------------", 
			"------------------------------------------------" 
			LET done_lines = false 

		BEFORE GROUP OF rr_faaudit.batch_num 
			IF pr_page_break = "Y" THEN 
				SKIP TO top OF PAGE 
			END IF 

		BEFORE GROUP OF rr_faaudit.trans_ind 
			NEED 12 LINES 
			IF done_lines THEN 
				SKIP 1 LINES 
				PRINT COLUMN 1, "----------------------------------------", 
				"-------------------------------------------", 
				"------------------------------------------------" 

				SELECT * 
				INTO rr_fabatch.* 
				FROM fabatch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND batch_num = rr_faaudit.batch_num 

				PRINT COLUMN 1,"Batch : ",rr_fabatch.batch_num USING "<<<<<", 
				COLUMN 30,"Transaction Total : ",rr_fabatch.actual_asset_amt 
				USING "--,---,---,---,-$&.&&", 
				COLUMN 73,"Cleared : ",rr_fabatch.cleared_flag, 
				COLUMN 100,"Posted TO GL : ",rr_fabatch.post_gl_flag 
				PRINT COLUMN 1,"Year : ",rr_fabatch.year_num USING "<<<<", 
				COLUMN 30,"Depreciation Total : ",rr_fabatch.actual_depr_amt 
				USING "--,---,---,---,-$&.&&", 
				COLUMN 73,"Posted TO Asset : ",rr_fabatch.post_asset_flag, 
				COLUMN 100,"GL Journal Number : ", 
				rr_fabatch.jour_num USING "<<<<<" 
				PRINT COLUMN 1,"Period : ",rr_fabatch.period_num USING "<<<" 

				PRINT COLUMN 1, "----------------------------------------", 
				"-------------------------------------------", 
				"------------------------------------------------" 

				CASE rr_faaudit.trans_ind 
					WHEN "A" 
						PRINT COLUMN 1,"Additions" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 13,"Authority Code ", 
						COLUMN 34," Net Book Value", 
						COLUMN 54," Accumulated Depn", 
						COLUMN 74," Salvage Value", 
						COLUMN 94,"Life", 
						COLUMN 99,"Location ", 
						COLUMN 110,"Responsibility ", 
						COLUMN 129,"Cat" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "J" 
						PRINT COLUMN 1,"Adjustments" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 13,"Authority Code ", 
						COLUMN 34," Cost Adjustment", 
						COLUMN 54," Depn Adjustment", 
						COLUMN 74," Salvage Adjustment" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "T" 
						PRINT COLUMN 1,"Transfers" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description", 
						COLUMN 65,"Book" 

						PRINT COLUMN 14,"Location ", 
						COLUMN 25,"Cat", 
						COLUMN 49," Net Book Value", 
						COLUMN 69," Transfer Amount", 
						COLUMN 89," Accumulated Depn", 
						COLUMN 109," Salvage Value" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "R" 
						PRINT COLUMN 1,"Retirements" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 53," Current Cost", 
						COLUMN 73," Accumulated Depn", 
						COLUMN 93," Salvage Value", 
						COLUMN 113," Retirement Amount" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "V" 
						PRINT COLUMN 1,"Revaluations" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 49," New Net Book Value", 
						COLUMN 69," Accumulated Depn", 
						COLUMN 89," Salvage Value", 
						COLUMN 109," Revaluation Amount" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "S" 
						PRINT COLUMN 1,"Sales" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 34," Current Cost", 
						COLUMN 54," Accumulated Depn", 
						COLUMN 74," Sale Amount", 
						COLUMN 94,"Capital Gain", 
						COLUMN 107," Gain", 
						COLUMN 120," Loss" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "L" 
						PRINT COLUMN 1,"Revaluations" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 13,"Authority Code ", 
						COLUMN 34," Current Cost", 
						COLUMN 54," Accumulated Depn", 
						COLUMN 74," Salvage Value", 
						COLUMN 94,"New Life" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "C" 
						PRINT COLUMN 1,"Depn Code Change" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 13,"Authority Code ", 
						COLUMN 34," Current Cost", 
						COLUMN 54," Accumulated Depn", 
						COLUMN 74," Salvage Value", 
						COLUMN 94,"Life" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

					WHEN "D" 
						PRINT COLUMN 1,"Depreciation Calculation" 
						PRINT COLUMN 1,"Line ", 
						COLUMN 9,"Asset Code", 
						COLUMN 20,"Add on ", 
						COLUMN 31,"Description" 

						PRINT COLUMN 8,"Book", 
						COLUMN 13,"Authority Code ", 
						COLUMN 64,"Life", 
						COLUMN 69,"Depn Code", 
						COLUMN 79," Current Cost", 
						COLUMN 99,"Depreciation Charge" 

						PRINT COLUMN 1, "----------------------------------------", 
						"-------------------------------------------", 
						"------------------------------------------------" 

				END CASE 
			END IF 


		ON EVERY ROW 
			LET done_lines = true 
			CASE rr_faaudit.trans_ind 
				WHEN "A" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 34,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 94,rr_faaudit.rem_life_num USING "####", 
					COLUMN 99,rr_faaudit.location_code, 
					COLUMN 110,rr_faaudit.faresp_code, 
					COLUMN 129,rr_faaudit.facat_code 

				WHEN "J" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 34,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "T" 
					IF rr_faaudit.desc_text != "Transfer - FROM" THEN 
						LET rr_faaudit.desc_text = "Transfer - TO" 
					END IF 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text, 
					COLUMN 65,rr_faaudit.book_code, 
					COLUMN 70,rr_faaudit.auth_code 

					PRINT COLUMN 14,rr_faaudit.location_code, 
					COLUMN 25,rr_faaudit.facat_code, 
					COLUMN 49,rr_faaudit.net_book_val_amt 
					USING "----,---,---,-$&.&&", 
					COLUMN 69,rr_faaudit.asset_amt 
					USING "----,---,---,-$&.&&", 
					COLUMN 89,rr_faaudit.depr_amt 
					USING "----,---,---,-$&.&&", 
					COLUMN 109,rr_faaudit.salvage_amt 
					USING "----,---,---,-$&.&&" 

				WHEN "R" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 53,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 73,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 93,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 113,rr_faaudit.sale_amt 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "V" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 49,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 69,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 89,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 109,rr_faaudit.sale_amt 
					USING "----,---,---,-$&.&&" 

				WHEN "S" 
					SELECT * 
					INTO rr_fastatus.* 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = rr_faaudit.asset_code 
					AND add_on_code = rr_faaudit.add_on_code 
					AND book_code = rr_faaudit.book_code 

					# determine the type of sale we are dealing with
					# 1. sold AT net book value
					# 2. sold below net book value
					# 3. sold above nbv - no capital gain (ie below orig cost)
					# 4. sold above nbv - capital gain (ie over orig cost)

					CASE 
					{type 1.}
						WHEN (rr_faaudit.sale_amt = rr_fastatus.net_book_val_amt) 
							LET capital_gain = 0 
							LET gain = 0 
							LET loss = 0 
							{type 2.}
						WHEN (rr_faaudit.sale_amt < rr_fastatus.net_book_val_amt) 
							LET capital_gain = 0 
							LET gain = 0 
							LET loss = rr_fastatus.net_book_val_amt - 
							rr_faaudit.sale_amt 
							{type 3. & type 4}
						WHEN (rr_faaudit.sale_amt > rr_fastatus.net_book_val_amt) 
							IF rr_faaudit.sale_amt <= 
							rr_fastatus.cur_depr_cost_amt THEN 

								# type 3
								# no capital gain

								LET capital_gain = 0 
								LET loss = 0 
								LET gain = rr_faaudit.sale_amt - 
								rr_fastatus.net_book_val_amt 

							ELSE 
								# type 4
								# capital gain

								LET capital_gain = rr_faaudit.sale_amt - 
								rr_fastatus.cur_depr_cost_amt 

								LET gain = rr_faaudit.depr_amt 

							END IF 
					END CASE 

					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 34,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74,rr_faaudit.sale_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 94,capital_gain 
					USING "$$$$$,$$&.&&", 
					COLUMN 107,gain 
					USING "$$$$$,$$&.&&", 
					COLUMN 120,loss 
					USING "$$$$$,$$&.&&" 

				WHEN "L" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 34,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 94,rr_faaudit.rem_life_num USING "####" 

				WHEN "C" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 34,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74,rr_faaudit.salvage_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 94,rr_faaudit.rem_life_num USING "####" 

				WHEN "D" 
					PRINT COLUMN 1,rr_faaudit.batch_line_num USING "####", 
					COLUMN 9,rr_faaudit.asset_code, 
					COLUMN 20,rr_faaudit.add_on_code, 
					COLUMN 31,rr_faaudit.desc_text 
					SELECT depr_code 
					INTO rr_depn_code 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = rr_faaudit.asset_code 
					AND add_on_code = rr_faaudit.add_on_code 
					AND book_code = rr_faaudit.book_code 

					PRINT COLUMN 8,rr_faaudit.book_code, 
					COLUMN 13,rr_faaudit.auth_code, 
					COLUMN 64,rr_faaudit.rem_life_num USING "####", 
					COLUMN 69,rr_depn_code, 
					COLUMN 79,rr_faaudit.asset_amt 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 99,rr_faaudit.depr_amt 
					USING "$$$$,$$$,$$$,$$&.&&" 

			END CASE 

		AFTER GROUP OF rr_faaudit.trans_ind 
			NEED 3 LINES 
			CASE rr_faaudit.trans_ind 
				WHEN "A" 
					PRINT COLUMN 34, "-------------------", 
					COLUMN 54, "-------------------" 
					PRINT COLUMN 34, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 
				WHEN "J" 
					PRINT COLUMN 34, "-------------------", 
					COLUMN 54, "-------------------" 
					PRINT COLUMN 34, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "T" 
					PRINT COLUMN 49, "-------------------", 
					COLUMN 69,"-------------------", 
					COLUMN 89, "-------------------" 
					PRINT COLUMN 49, GROUP sum(rr_faaudit.net_book_val_amt) 
					USING "----,---,---,-$&.&&", 
					COLUMN 69, GROUP sum(rr_faaudit.asset_amt) 
					USING "----,---,---,-$&.&&", 
					COLUMN 89, GROUP sum(rr_faaudit.depr_amt) 
					USING "----,---,---,-$&.&&" 

				WHEN "R" 
					PRINT COLUMN 53, "-------------------", 
					COLUMN 73, "-------------------", 
					COLUMN 113, "-------------------" 
					PRINT COLUMN 53, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 73, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 113, GROUP sum(rr_faaudit.sale_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "V" 
					PRINT COLUMN 49, "-------------------", 
					COLUMN 69, "-------------------", 
					COLUMN 109, "-------------------" 
					PRINT COLUMN 49, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 69, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 109, GROUP sum(rr_faaudit.sale_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "S" 
					PRINT COLUMN 34, "-------------------", 
					COLUMN 54, "-------------------", 
					COLUMN 74, "-------------------" 
					PRINT COLUMN 34, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 74, GROUP sum(rr_faaudit.sale_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 
				WHEN "L" 
					PRINT COLUMN 34, "-------------------", 
					COLUMN 54, "-------------------" 
					PRINT COLUMN 34, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "C" 
					PRINT COLUMN 34, "-------------------", 
					COLUMN 54, "-------------------" 
					PRINT COLUMN 34, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 54, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

				WHEN "D" 
					PRINT COLUMN 79, "-------------------", 
					COLUMN 99, "-------------------" 
					PRINT COLUMN 79, GROUP sum(rr_faaudit.asset_amt) 
					USING "$$$$,$$$,$$$,$$&.&&", 
					COLUMN 99, GROUP sum(rr_faaudit.depr_amt) 
					USING "$$$$,$$$,$$$,$$&.&&" 

			END CASE 
			IF pr_page_break = "N" THEN 
				PRINT COLUMN 1, "----------------------------------------", 
				"-------------------------------------------", 
				"------------------------------------------------" 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Selection Criteria : ", 
			COLUMN 25, where_part clipped wordwrap right margin 120 
			SKIP 2 LINES 
			LET rpt_pageno = pageno 
			LET rpt_length = 66 
			PRINT COLUMN 50, "******** END OF REPORT FB1 ********" 
END REPORT 

