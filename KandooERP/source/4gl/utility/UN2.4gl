{
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

	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module UN2 - Notes - REPORT which shows rejected customer notes
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE where_text CHAR(500) 
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("UN2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW U531 with FORM "U531" 
	CALL windecoration_u("U531") 

	MENU " Notes" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","UN2","menu-notes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			CALL UN2_rpt_query_select_notes() 

		ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW U531 
END MAIN 


FUNCTION UN2_rpt_query_select_notes() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_notehead RECORD 
		note_code LIKE notes.note_code, 
		note_num LIKE notes.note_num 
	END RECORD, 
	query_text CHAR(2000), 
	glob_rpt_output CHAR(50) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	#CALL rpt_rmsreps_set_page_num(0) 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_msgresp=kandoomsg("W",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME where_text ON notes.note_code, 
	notes.note_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","UN2","construct-notes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF
		
	LET l_rpt_idx = rpt_start(getmoduleid(),"UN2_rpt_list_H22_notes",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT UN2_rpt_list_H22_notes TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	
	LET query_text = "SELECT notes.note_code,", 
	"notes.note_num ", 
	"FROM notes ", 
	"WHERE notes.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", where_text clipped," ", 
	"ORDER BY notes.note_code,notes.note_num" 
	PREPARE s_notehead FROM query_text 
	DECLARE c_notehead CURSOR FOR s_notehead 

	FOREACH c_notehead INTO pr_notehead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT UN2_rpt_list_H22_notes(l_rpt_idx,pr_notehead.*) 
		IF NOT rpt_int_flag_handler2("Note:",pr_notehead.note_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF		
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT UN2_rpt_list_H22_notes
	CALL rpt_finish("UN2_rpt_list_H22_notes")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	 
END FUNCTION 


REPORT UN2_rpt_list_H22_notes(p_rpt_idx,pr_notehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_notes 
	RECORD LIKE notes.*, 
	pr_notehead RECORD 
		note_code LIKE notes.note_code, 
		note_num LIKE notes.note_num 
	END RECORD, 
	glob_rpt_line1 CHAR(80), 
	glob_rpt_offset1, glob_rpt_offset2 SMALLINT 

	OUTPUT 
	left margin 1 
	ORDER external BY pr_notehead.note_code, 
	pr_notehead.note_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_notehead.note_code 
			NEED 2 LINES 
			PRINT COLUMN 03, "Note:", 
			COLUMN 10, pr_notehead.note_code 
		ON EVERY ROW 
			INITIALIZE pr_notes.* TO NULL 
			SELECT * INTO pr_notes.* FROM notes 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND note_code = pr_notehead.note_code 
			AND note_num = pr_notehead.note_num 
			PRINT COLUMN 07, pr_notes.note_text 
		AFTER GROUP OF pr_notehead.note_code 
			SKIP 2 LINES 
		ON LAST ROW 
			SKIP TO top OF PAGE 
			SKIP 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			 
END REPORT 