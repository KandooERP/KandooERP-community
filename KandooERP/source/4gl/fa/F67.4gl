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
GLOBALS "../fa/F67_GLOBALS.4gl"

# Report on auth

GLOBALS 

	DEFINE pr_company RECORD LIKE company.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE offset1, offset2, rpt_wid SMALLINT 
	DEFINE pr_output CHAR(80) 
	DEFINE line1 , line2 CHAR(130) 
	DEFINE where_part CHAR(800) 
	DEFINE query_text CHAR(890) 
	DEFINE rpt_note CHAR(50) 
	DEFINE rpt_date DATE 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("F67") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET rpt_wid = 132 
	LET rpt_note = NULL 
	CLEAR screen 

	MENU " Authority Master Listing" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","F67","menu-auth_mast_list-1") -- alch kd-504 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL f67_query() 
			CLOSE WINDOW f165 
			CLEAR screen 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 
			EXIT program 

		COMMAND "Exit" "Exit TO Menus" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
	CLEAR screen 

END MAIN 


FUNCTION f67_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_faauth RECORD 
		auth_code LIKE faauth.auth_code, 
		auth_text LIKE faauth.auth_text 
	END RECORD 

	CLEAR screen 
	OPEN WINDOW f165 with FORM "F165" -- alch kd-757 
	CALL  windecoration_f("F165") -- alch kd-757 
	MESSAGE "Enter Criteria FOR selection - Press ESC TO Begin" 
	CONSTRUCT BY NAME where_part ON auth_code, 
	auth_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F67","const-auth_code-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"F67_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT F67_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	
	LET query_text = "SELECT auth_code, auth_text FROM faauth WHERE ", 
	" cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ", 
	where_part clipped, 
	"ORDER BY auth_code" 

	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 



	FOREACH selcurs INTO pr_faauth.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT F67_rpt_list(l_rpt_idx,
		pr_faauth.*) 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT F67_rpt_list
	CALL rpt_finish("F67_rpt_list")
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
# REPORT F67_rpt_list(p_rpt_idx,pr_faauth) 
#
#
###########################################################################
REPORT F67_rpt_list(p_rpt_idx,pr_faauth) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_faauth RECORD 
		auth_code LIKE faauth.auth_code, 
		auth_text LIKE faauth.auth_text 
	END RECORD 

	OUTPUT 
	left margin 2 
	PAGE length 66 

	ORDER external BY pr_faauth.auth_code 

	FORMAT 
		PAGE HEADER 
			PRINT COLUMN 20, today, 
			COLUMN 35, "Company Code: ",glob_rec_kandoouser.cmpy_code, 
			COLUMN 60, pr_company.name_text clipped, 
			COLUMN 110, "Page", pageno USING "<<<<<" 
			PRINT COLUMN 35, " Authority Report (Menu-F67)" 
			PRINT COLUMN 35, "Sorted by Company / by Authority" 
			PRINT "----------------------------------------------------------------------------------------------------------------------------------" 
			PRINT COLUMN 5,"Authority Code", 
			COLUMN 25,"Authority Description" 
			PRINT "----------------------------------------------------------------------------------------------------------------------------------" 
			SKIP 1 LINES 

		ON EVERY ROW 
			PRINT COLUMN 5, pr_faauth.auth_code, 
			COLUMN 25, pr_faauth.auth_text 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 

