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
	DEFINE pa_formathelp array[9] OF 
	RECORD 
		scroll_num CHAR(1), 
		desc_text CHAR(40) 
	END RECORD 
	DEFINE pa_actionhelp array[9] OF 
	RECORD 
		scroll_num CHAR(1), 
		desc_text CHAR(40) 
	END RECORD 
END GLOBALS 


###################################################################
# MAIN
#
# U32 - Report program FOR Message Library
###################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("U32") 	
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 
	CALL init_help() 

	OPEN WINDOW U203 with FORM "U203" 
	CALL windecoration_u("U203") 

	MENU " Message Library Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U32","menu-MESSAGE_lib_rep") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Run" " SELECT Criteria AND Print Report" 
			MENU " Run Report ORDER BY" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","U32","menu-run") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				COMMAND "Language" 
					CALL U32_rpt_query("L")  
					EXIT MENU 

				COMMAND "Source Indicator" 
					CALL U32_rpt_query("S") 
					EXIT MENU 
					
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" 
					EXIT MENU 
					
			END MENU 

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "EXIT" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW u203 
END MAIN 


FUNCTION U32_rpt_query(pr_order_ind) 
	DEFINE pr_order_ind CHAR(1)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE pr_kandoomsg RECORD LIKE kandoomsg.*, 
	where_text CHAR(300), 
	query_text CHAR(500), 
	pr_delete_flag, 
	ans CHAR(1), 
	i,del_cnt, idx, scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME where_text ON language_code, 
	source_ind, 
	msg_num, 
	msg1_text, 
	msg2_text, 
	msg_ind, 
	format_ind, 
	help_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","U32","construct-kandoomsg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("U",1002,"") 
	END IF 

	LET query_text = "SELECT * ", 
	"FROM kandoomsg ", 
	"WHERE 1=1 ", 
	"AND ",where_text clipped 

	IF pr_order_ind = "L" THEN 
		LET query_text = query_text clipped," ", 
		"ORDER BY language_code,", 
		"source_ind,", 
		"msg_num" 
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("U32-L","U32_rpt_list_L","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U32_rpt_list_L TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	ELSE 
		LET query_text = query_text clipped," ", 
		"ORDER BY source_ind,", 
		"msg_num,", 
		"language_code" 
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("U32-S","U32_rpt_list_S","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U32_rpt_list_S TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	END IF 
	PREPARE s_kandoomsg FROM query_text 
	DECLARE c_kandoomsg CURSOR FOR s_kandoomsg 
	FOREACH c_kandoomsg INTO pr_kandoomsg.* 
		#      DISPLAY "" TO lbLabel1b
		#      DISPLAY "" TO lbLabel2b
		#      DISPLAY "" TO lbLabel3b

		IF pr_order_ind = "L" THEN 
			#DISPLAY pr_kandoomsg.language_code TO lblabel1b 
			#DISPLAY pr_kandoomsg.source_ind TO lblabel2b 
			#DISPLAY pr_kandoomsg.msg_num TO lblabel3b
			#---------------------------------------------------------
			OUTPUT TO REPORT AC4_rpt_list(rpt_rmsreps_idx_get_idx("U32_rpt_list_L"),pr_kandoomsg.*)   
		ELSE 
			#DISPLAY pr_kandoomsg.source_ind TO lblabel1b 
			#DISPLAY pr_kandoomsg.msg_num TO lblabel2b
			OUTPUT TO REPORT AC4_rpt_list(rpt_rmsreps_idx_get_idx("U32_rpt_list_S"),pr_kandoomsg.*)   

		END IF 
	END FOREACH 

	IF pr_order_ind = "L" THEN 
		#------------------------------------------------------------
		FINISH REPORT U32_rpt_list_L
		CALL rpt_finish("U32_rpt_list_L")
		#------------------------------------------------------------	
	ELSE 
		#------------------------------------------------------------
		FINISH REPORT U32_rpt_list_S
		CALL rpt_finish("U32_rpt_list_S")
		#------------------------------------------------------------	
	END IF 
	
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT U32_rpt_list_L(p_rpt_idx,pr_kandoomsg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_kandoomsg RECORD LIKE kandoomsg.*, 
	pr_language RECORD LIKE language.*, 
	col SMALLINT, 
	glob_rpt_line1 CHAR(130), 
	glob_rpt_line2 CHAR(130) 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_kandoomsg.language_code, 
	pr_kandoomsg.source_ind, 
	pr_kandoomsg.msg_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
		
			PRINT COLUMN 2, "Source Indicator: ",pr_kandoomsg.source_ind 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 6, "Message No.", 
			COLUMN 20, "Message Text", 
			COLUMN 104,"Action", 
			COLUMN 112,"Format", 
			COLUMN 120,"Help No." 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_kandoomsg.language_code 
			SKIP TO top OF PAGE 
		BEFORE GROUP OF pr_kandoomsg.source_ind 
			SKIP TO top OF PAGE 
		ON EVERY ROW 
			PRINT COLUMN 2, pr_kandoomsg.msg_num USING "##########", 
			COLUMN 20, pr_kandoomsg.msg1_text, 
			COLUMN 106, pr_kandoomsg.msg_ind, 
			COLUMN 114, pr_kandoomsg.format_ind, 
			COLUMN 117, pr_kandoomsg.help_num USING "########" 
			PRINT COLUMN 20, pr_kandoomsg.msg2_text 
		ON LAST ROW 
			WHILE lineno < 48 
				SKIP 1 line 
			END WHILE 
			NEED 15 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 1, "--------------------------------------------", 
			"------------------ Report Legend -----------", 
			"--------------------------------------------" 
			PRINT COLUMN 2, "Action Indicator:", 
			COLUMN 68, "Format Indicator:" 
			PRINT COLUMN 16, "(1)=>", 
			COLUMN 26, pa_actionhelp[1].desc_text, 
			COLUMN 82, "(1)=>", 
			COLUMN 92, pa_formathelp[1].desc_text 
			PRINT COLUMN 16, "(2)=>", 
			COLUMN 26, pa_actionhelp[2].desc_text, 
			COLUMN 82, "(2)=>", 
			COLUMN 92, pa_formathelp[2].desc_text 
			PRINT COLUMN 16, "(3)=>", 
			COLUMN 26, pa_actionhelp[3].desc_text, 
			COLUMN 82, "(3)=>", 
			COLUMN 92, pa_formathelp[3].desc_text 
			PRINT COLUMN 16, "(4)=>", 
			COLUMN 26, pa_actionhelp[4].desc_text, 
			COLUMN 82, "(4)=>", 
			COLUMN 92, pa_formathelp[4].desc_text 
			PRINT COLUMN 16, "(5)=>", 
			COLUMN 26, pa_actionhelp[5].desc_text, 
			COLUMN 82, "(5)=>", 
			COLUMN 92, pa_formathelp[5].desc_text 
			PRINT COLUMN 16, "(6)=>", 
			COLUMN 26, pa_actionhelp[6].desc_text, 
			COLUMN 82, "(6)=>", 
			COLUMN 92, pa_formathelp[6].desc_text 
			PRINT COLUMN 16, "(7)=>", 
			COLUMN 26, pa_actionhelp[7].desc_text, 
			COLUMN 82, "(7)=>", 
			COLUMN 92, pa_formathelp[7].desc_text 
			PRINT COLUMN 16, "(8)=>", 
			COLUMN 26, pa_actionhelp[8].desc_text, 
			COLUMN 82, "(8)=>", 
			COLUMN 92, pa_formathelp[8].desc_text 
			PRINT COLUMN 16, "(9)=>", 
			COLUMN 26, pa_actionhelp[9].desc_text, 
			COLUMN 82, "(9)=>", 
			COLUMN 92, pa_formathelp[9].desc_text 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 


REPORT U32_rpt_list_S(p_rpt_idx,pr_kandoomsg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_kandoomsg RECORD LIKE kandoomsg.*, 
	pr_language RECORD LIKE language.*, 
	col SMALLINT, 
	glob_rpt_line1 CHAR(130), 
	glob_rpt_line2 CHAR(130) 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_kandoomsg.source_ind, 
	pr_kandoomsg.msg_num, 
	pr_kandoomsg.language_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01,  "Source Indicator: ",pr_kandoomsg.source_ind
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 2, "Message No.", 
			COLUMN 13, "Language", 
			COLUMN 37, "Message Text", 
			COLUMN 106,"Action", 
			COLUMN 114,"Format", 
			COLUMN 120,"Help No." 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_kandoomsg.source_ind 
			SKIP TO top OF PAGE 
		BEFORE GROUP OF pr_kandoomsg.msg_num 
			PRINT COLUMN 1, pr_kandoomsg.msg_num USING "##########"; 
		ON EVERY ROW 
			SELECT * 
			INTO pr_language.* 
			FROM language 
			WHERE language_code = pr_kandoomsg.language_code 
			PRINT COLUMN 13, pr_kandoomsg.language_code, 
			COLUMN 17, pr_language.language_text clipped, 
			COLUMN 37, pr_kandoomsg.msg1_text, 
			COLUMN 108, pr_kandoomsg.msg_ind, 
			COLUMN 116, pr_kandoomsg.format_ind, 
			COLUMN 119, pr_kandoomsg.help_num USING "########" 
			PRINT COLUMN 37, pr_kandoomsg.msg2_text 
		ON LAST ROW 
			WHILE lineno < 48 
				SKIP 1 line 
			END WHILE 
			NEED 15 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 1, "--------------------------------------------", 
			"------------------ Report Legend -----------", 
			"--------------------------------------------" 
			PRINT COLUMN 2, "Action Indicator:", 
			COLUMN 68, "Format Indicator:" 
			PRINT COLUMN 16, "(1)=>", 
			COLUMN 26, pa_actionhelp[1].desc_text, 
			COLUMN 82, "(1)=>", 
			COLUMN 92, pa_formathelp[1].desc_text 
			PRINT COLUMN 16, "(2)=>", 
			COLUMN 26, pa_actionhelp[2].desc_text, 
			COLUMN 82, "(2)=>", 
			COLUMN 92, pa_formathelp[2].desc_text 
			PRINT COLUMN 16, "(3)=>", 
			COLUMN 26, pa_actionhelp[3].desc_text, 
			COLUMN 82, "(3)=>", 
			COLUMN 92, pa_formathelp[3].desc_text 
			PRINT COLUMN 16, "(4)=>", 
			COLUMN 26, pa_actionhelp[4].desc_text, 
			COLUMN 82, "(4)=>", 
			COLUMN 92, pa_formathelp[4].desc_text 
			PRINT COLUMN 16, "(5)=>", 
			COLUMN 26, pa_actionhelp[5].desc_text, 
			COLUMN 82, "(5)=>", 
			COLUMN 92, pa_formathelp[5].desc_text 
			PRINT COLUMN 16, "(6)=>", 
			COLUMN 26, pa_actionhelp[6].desc_text, 
			COLUMN 82, "(6)=>", 
			COLUMN 92, pa_formathelp[6].desc_text 
			PRINT COLUMN 16, "(7)=>", 
			COLUMN 26, pa_actionhelp[7].desc_text, 
			COLUMN 82, "(7)=>", 
			COLUMN 92, pa_formathelp[7].desc_text 
			PRINT COLUMN 16, "(8)=>", 
			COLUMN 26, pa_actionhelp[8].desc_text, 
			COLUMN 82, "(8)=>", 
			COLUMN 92, pa_formathelp[8].desc_text 
			PRINT COLUMN 16, "(9)=>", 
			COLUMN 26, pa_actionhelp[9].desc_text, 
			COLUMN 82, "(9)=>", 
			COLUMN 92, pa_formathelp[9].desc_text 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 


FUNCTION init_help() 
	DEFINE 
	i SMALLINT 

	FOR i = 1 TO 9 
		LET pa_formathelp[i].scroll_num = i 
		LET pa_actionhelp[i].scroll_num = i 
	END FOR 
	LET pa_actionhelp[1].desc_text = "DISPLAY on form lines 1 & 2. :No window" 
	LET pa_actionhelp[2].desc_text = "DISPLAY & sleep 3 seconds. :No window" 
	LET pa_actionhelp[3].desc_text = "DISPLAY & 'Any Key TO Cont..' :No window" 
	LET pa_actionhelp[4].desc_text = "DISPLAY & prompt (Y)es/(N)o. :No window" 
	LET pa_actionhelp[5].desc_text = "DISPLAY & sleep 10 seconds. :With window" 
	LET pa_actionhelp[6].desc_text = "WARNING: Requiring user acknowledgement " 
	LET pa_actionhelp[7].desc_text = "DISPLAY & 'Any Key TO Cont.':With window" 
	LET pa_actionhelp[8].desc_text = "DISPLAY & prompt (Y)es/(N)o.:With window" 
	LET pa_actionhelp[9].desc_text = "DISPLAY on error line with warning bell." 
	LET pa_formathelp[1].desc_text = "DISPLAY <VALUE> AT start of first line. " 
	LET pa_formathelp[2].desc_text = "DISPLAY <VALUE> AT END of first line. " 
	LET pa_formathelp[3].desc_text = "DISPLAY <VALUE> AT start of second line." 
	LET pa_formathelp[4].desc_text = "DISPLAY <VALUE> AT END of second line." 
	LET pa_formathelp[5].desc_text = "No Format allocated" 
	LET pa_formathelp[6].desc_text = "No Format allocated" 
	LET pa_formathelp[7].desc_text = "No Format allocated" 
	LET pa_formathelp[8].desc_text = "No Format allocated" 
	LET pa_formathelp[9].desc_text = "DISPLAY <VALUE> best fit. (append lines)" 
END FUNCTION 


