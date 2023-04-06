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

GLOBALS 
	DEFINE 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_company RECORD LIKE company.*, 
	pr_report RECORD 
		asset_code LIKE fastocklocn.asset_code, 
		desc_text LIKE famast.desc_text, 
		mast_locn LIKE famast.location_code, 
		stock_locn LIKE fastocklocn.location_code, 
		stktake_date LIKE fastocklocn.stktake_date, 
		wand_code LIKE fastocklocn.wand_code 
	END RECORD, 
	query_text, where_part CHAR(1500), 
	col, len, s, rpt_wid SMALLINT, 
	rpt_date DATE, 
	rpt_time CHAR(10), 
	rpt_note, cmpy_head CHAR(80), 
	pr_output CHAR(60), 
	details CHAR(8) 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("FL2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	MENU " Stock Location Print" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","FL2","menu-stock_loc_print-1") -- alch kd-504 

		COMMAND "Run Report" " SELECT criteria & generate REPORT " 
			CALL query() 
			CLEAR screen 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND "Exit" " RETURN TO menu" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
END MAIN 

FUNCTION query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	LET rpt_wid = 132 
	LET rpt_note = NULL 
	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN WINDOW wf178 with FORM "F178" -- alch kd-757 
	CALL  windecoration_f("F178") -- alch kd-757 
	MESSAGE " Enter selection criteria AND press ESC" 
	attribute (yellow) 
	CONSTRUCT BY NAME where_part ON year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","FL2","const-year_num-2") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	CLOSE WINDOW wf178 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET query_text = "SELECT fastocklocn.asset_code,", 
	" famast.desc_text,", 
	" famast.location_code,", 
	" fastocklocn.location_code,", 
	" fastocklocn.stktake_date,", 
	" fastocklocn.wand_code ", 
	"FROM fastocklocn, outer famast ", 
	"WHERE fastocklocn.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" fastocklocn.cmpy_code = famast.cmpy_code AND ", 
	" fastocklocn.asset_code = famast.asset_code AND ", 
	where_part clipped, 
	" ORDER BY fastocklocn.asset_code, stktake_date desc " 
	PREPARE query_stock FROM query_text 
	DECLARE stockitem CURSOR FOR query_stock 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"FL2_rpt_list_stktake",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT FL2_rpt_list_stktake TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	FOREACH stockitem INTO pr_report.* 
		DISPLAY "" at 12,18 
		DISPLAY "Asset: ", pr_report.asset_code at 12,18

		#---------------------------------------------------------
		OUTPUT TO REPORT FL2_rpt_list_stktake(l_rpt_idx,
		pr_report.*) 
		#---------------------------------------------------------
		 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT FL2_rpt_list_stktake
	CALL rpt_finish("FL2_rpt_list_stktake")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	 
END FUNCTION 

REPORT FL2_rpt_list_stktake(report_line) 
	DEFINE 
	report_line RECORD 
		asset_code LIKE fastocklocn.asset_code, 
		desc_text LIKE famast.desc_text, 
		mast_locn LIKE famast.location_code, 
		stock_locn LIKE fastocklocn.location_code, 
		stktake_date LIKE fastocklocn.stktake_date, 
		wand_code LIKE fastocklocn.wand_code 
	END RECORD 

	OUTPUT 
	left margin 0 
	ORDER external BY report_line.asset_code, report_line.stktake_date 
	FORMAT 
		PAGE HEADER 
			LET cmpy_head = pr_company.cmpy_code, " ", 
			pr_company.name_text clipped 
			LET col = 66 - (length (cmpy_head) / 2) + 1 
			PRINT COLUMN 1, today USING "DD MMM YYYY", 
			COLUMN col, cmpy_head clipped, 
			COLUMN 122, "Page :", 
			COLUMN 129, pageno USING "###" 
			IF rpt_note IS NULL THEN 
				LET rpt_note = "Stock Location Report (Menu - FL2)" clipped 
			END IF 
			LET col = 66 - (length (rpt_note) / 2) + 1 
			PRINT COLUMN 1, time, 
			COLUMN col, rpt_note 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 
			PRINT COLUMN 1, "Asset Code", 
			COLUMN 16, "Asset Description", 
			COLUMN 63, "Master", 
			COLUMN 78, "Stocktake", 
			COLUMN 94, "Stocktake", 
			COLUMN 109, "Wand ID", 
			COLUMN 123, "Mismatch" 
			PRINT COLUMN 62, "Location", 
			COLUMN 78, "Location", 
			COLUMN 96, "Date" 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 
		BEFORE GROUP OF report_line.asset_code 
			SKIP 1 line 
			IF report_line.mast_locn != report_line.stock_locn OR 
			report_line.mast_locn IS NULL OR 
			report_line.stock_locn IS NULL THEN 
				LET details = "********" 
			END IF 
			PRINT COLUMN 1, report_line.asset_code, 
			COLUMN 16, report_line.desc_text, 
			COLUMN 62, report_line.mast_locn; 
		ON EVERY ROW 
			PRINT COLUMN 78, report_line.stock_locn, 
			COLUMN 94, report_line.stktake_date, 
			COLUMN 109, report_line.wand_code, 
			COLUMN 123, details 
			LET details = "" 
		ON LAST ROW 
			SKIP 1 line 
			SKIP 5 LINES 
			PRINT COLUMN 10, "Report used the following selection criteria" 
			SKIP 2 LINES 
			PRINT COLUMN 10, "WHERE:-" 
			SKIP 1 LINES 
			LET len = length (where_part) 
			FOR s = 1 TO 1121 step 60 
				IF len > s THEN 
					PRINT COLUMN 10, "|", where_part [s, s + 59], "|" 
				ELSE 
					LET s = 32000 
				END IF 
			END FOR 
			# the last line doesnt have 60 characters of where_part TO display
			IF len > 1181 THEN 
				PRINT COLUMN 10, "|", where_part [1181, 1200], "|" 
			END IF 
			SKIP 1 line 
			PRINT COLUMN 50, "***** END OF REPORT FL2 *****" 
END REPORT 
