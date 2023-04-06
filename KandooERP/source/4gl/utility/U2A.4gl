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
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE pr_menu1 RECORD LIKE menu1.*, 
	pr_menu2 RECORD LIKE menu2.*, 
	pr_menu3 RECORD LIKE menu3.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_start_menu, pr_end_menu CHAR(1), 
	query_text, where_part CHAR(500), 
--	print_option CHAR(1), 
	comp_on CHAR(30), 
	file_name CHAR(30), 
	default_file CHAR(30), 
	pr_printcodes RECORD LIKE printcodes.* 
END GLOBALS 
###################################################################
# MAIN
#
#  U2A Prints the menu OPTIONS
###################################################################
MAIN 
	#Initial UI Init	CALL setModuleId("U2A")
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL fgl_winmessage("This will be removed","This program will be replaced by the new menu manager","info") 


	OPEN WINDOW U127 with FORM "U127" 
	CALL windecoration_u("U127") 

	MENU " Menu Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U2A","menu-REPORT") 
			CALL U2A_rpt_query()
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL U2A_rpt_query() 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW u127 
END MAIN 

FUNCTION U2A_rpt_query()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	INPUT BY NAME pr_start_menu, 	pr_end_menu 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U2A","input-start-end-menu") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD pr_start_menu 
			IF pr_start_menu IS NULL THEN 
				LET pr_start_menu = "1" 
			END IF 
			
		AFTER FIELD pr_end_menu 
			IF pr_end_menu IS NULL THEN 
				LET pr_end_menu = "z" 
			END IF 
			
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_start_menu IS NULL THEN 
					LET pr_start_menu = "1" 
				END IF 
				IF pr_end_menu IS NULL THEN 
					LET pr_end_menu = "z" 
				END IF 
			END IF 
 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U2A_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U2A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
 
	DECLARE lev3curs CURSOR FOR 
	SELECT * INTO pr_menu3.* FROM menu3 
	WHERE menu1_code between pr_start_menu AND pr_end_menu 
	ORDER BY menu1_code, menu2_code, menu3_code 
	FOREACH lev3curs 
		#---------------------------------------------------------
		OUTPUT TO REPORT U2A_rpt_list(l_rpt_idx,pr_menu3.*)   
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT U2A_rpt_list
	CALL rpt_finish("U2A_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

REPORT U2A_rpt_list(p_rpt_idx,pr_menu3) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_menu3 RECORD LIKE menu3.*, 
	pr_menu2 RECORD LIKE menu2.*, 
	pr_menu1 RECORD LIKE menu1.* 


	OUTPUT 
--	left margin 0 


	ORDER external BY pr_menu3.menu1_code, pr_menu3.menu2_code, 
	pr_menu3.menu3_code 
	FORMAT 
		PAGE HEADER 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT COLUMN 5, "Level", 
			COLUMN 10, " Menu Option", 
			COLUMN 38, "Max", 
			COLUMN 45, "Passwd", 
			COLUMN 60, "User", 
			COLUMN 68, "Executable" 

			PRINT COLUMN 7, "3", 
			COLUMN 60, "Level", 
			COLUMN 70, "Name" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 5, pr_menu3.menu3_code, 
			COLUMN 10, pr_menu3.name_text, 
			COLUMN 40, pr_menu3.prosper_code, 
			COLUMN 45, pr_menu3.password_text, 
			COLUMN 60, pr_menu3.security_ind, 
			COLUMN 65, pr_menu3.run_text 

		BEFORE GROUP OF pr_menu3.menu1_code 
			SELECT * 
			INTO pr_menu1.* 
			FROM menu1 
			WHERE menu1_code = pr_menu3.menu1_code 

			PRINT COLUMN 1, 
			comp_on clipped, COLUMN 3, "Level 1: ", 
			COLUMN 12, pr_menu3.menu1_code, 
			COLUMN 15, pr_menu1.name_text, 
			COLUMN 45, pr_menu1.password_text, 
			COLUMN 60, pr_menu1.security_ind 


		BEFORE GROUP OF pr_menu3.menu2_code 
			SELECT * 
			INTO pr_menu2.* 
			FROM menu2 
			WHERE menu1_code = pr_menu3.menu1_code 
			AND menu2_code = pr_menu3.menu2_code 

			PRINT COLUMN 1, 
			comp_on clipped, COLUMN 3, "Level 2: ", 
			COLUMN 12, pr_menu3.menu2_code, 
			COLUMN 15, pr_menu2.name_text, 
			COLUMN 45, pr_menu2.password_text, 
			COLUMN 60, pr_menu2.security_ind 

		AFTER GROUP OF pr_menu3.menu1_code 
			SKIP TO top OF PAGE 

		AFTER GROUP OF pr_menu3.menu2_code 
			SKIP 2 LINES 

		ON LAST ROW 
			SKIP 1 line	
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
					
END REPORT 


