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
GLOBALS "../fa/F65_GLOBALS.4gl"

#  Report on category

GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	offset1, 
	offset2, 
	rpt_wid SMALLINT, 

	pr_output CHAR(80), 
	line1, line2 CHAR(130), 
	where_part CHAR(800), 
	query_text CHAR(890), 
	rpt_note CHAR(50), 
	rpt_date DATE 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("F65") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 
	LET rpt_note = NULL 
	OPEN WINDOW f163 with FORM "F163" -- alch kd-757 
	CALL  windecoration_f("F163") -- alch kd-757 
	MENU " Category Master Listing" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F65","menu-cat_mast_list-1") -- alch kd-504 
		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			CALL f65_query() 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
	CLOSE WINDOW f163 
END MAIN 

FUNCTION f65_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_facat RECORD 
		facat_code LIKE facat.facat_code, 
		facat_text LIKE facat.facat_text, 
		cost_limit_amt LIKE facat.cost_limit_amt, 
		class_text LIKE facat.class_text, 
		deprec_flag LIKE facat.deprec_flag 
	END RECORD 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.
	CONSTRUCT BY NAME where_part ON facat_code, 
	facat_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F65","const-facat-2") -- alch kd-504 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	LET msgresp = kandoomsg("U",1002,"") #1002 Searching database; Please wait.

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F65_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F65_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = "SELECT facat_code, facat_text, cost_limit_amt ", 
	" class_text, deprec_flag ", 
	" FROM facat WHERE ", 
	" cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ", 
	where_part clipped, 
	"ORDER BY facat_code" 

	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 


	#---------------------------------------------------------
	FOREACH selcurs INTO pr_facat.* 
		OUTPUT TO REPORT F65_rpt_list(l_rpt_idx,
		pr_facat.*) 
	END FOREACH 
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT F65_rpt_list
	CALL rpt_finish("F65_rpt_list")
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
# REPORT F65_rpt_list(p_rpt_idx,pr_facat) 
#
#
###########################################################################
REPORT F65_rpt_list(p_rpt_idx,pr_facat) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_facat RECORD 
		facat_code LIKE facat.facat_code, 
		facat_text LIKE facat.facat_text, 
		cost_limit_amt LIKE facat.cost_limit_amt, 
		class_text LIKE facat.class_text, 
		deprec_flag LIKE facat.deprec_flag 
	END RECORD 

	OUTPUT 
	left margin 2 
	right margin 130 
	PAGE length 66 

	ORDER external BY pr_facat.cost_limit_amt 

	FORMAT 
		PAGE HEADER 
			PRINT COLUMN 20, today, 
			COLUMN 35, glob_rec_kandoouser.cmpy_code, 
			COLUMN 44, pr_company.name_text clipped, 
			COLUMN 90, "Page : ", pageno USING "<<<<<" 
			PRINT COLUMN 35, " Category Report (Menu-F65) " 
			PRINT COLUMN 35, "Sorted by Company / by Category" 
			PRINT "----------------------------------------------------------------------------------------------------------------------------------" 
			PRINT " Class Cost Limit Depreciation " 
			PRINT " Text Amount Flag " 
			PRINT "----------------------------------------------------------------------------------------------------------------------------------" 
			SKIP 1 LINES 

		ON EVERY ROW 

			PRINT COLUMN 3, pr_facat.class_text, 
			COLUMN 35, pr_facat.cost_limit_amt USING "$$$,$$$,$$$.&&", 
			COLUMN 75, pr_facat.deprec_flag clipped 

			SKIP 1 line 

		BEFORE GROUP OF pr_facat.cost_limit_amt 
			SELECT facat_code, facat_text, cost_limit_amt, class_text, 
			deprec_flag 
			INTO pr_facat.* 
			FROM facat 
			WHERE facat.facat_code = pr_facat.facat_code 
			AND facat.facat_text = pr_facat.facat_text 

			IF status = notfound THEN 
				PRINT COLUMN 1, "Category Code: " ,pr_facat.facat_code, "- Unknown" 
				SKIP 1 line 
			ELSE 
				PRINT COLUMN 1, "Category Code: " ,pr_facat.facat_code, "- ", 
				pr_facat.facat_text 
				SKIP 1 line 
			END IF 

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
