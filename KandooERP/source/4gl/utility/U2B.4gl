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
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS 
	DEFINE pr_company RECORD LIKE company.* 
	DEFINE cmpy_head CHAR(132) 
	DEFINE where1_text,where2_text,temp_text CHAR(900) 
	DEFINE where_part CHAR(1300) 
	DEFINE query_text CHAR(1500) 
END GLOBALS 
###################################################################
# MAIN
#
# U2B  -  User Security Report
###################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("U2B") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW U101 with FORM "U101" 
	CALL windecoration_u("U101") 

	MENU " User Security Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U2B","menu-user_security") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
			CALL U2B_rpt_query()

		ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW u101 

END MAIN 


###################################################################
# FUNCTION U2B_rpt_query()
#
#
###################################################################
FUNCTION U2B_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE glob_rpt_output CHAR(60) 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE query1_text STRING 
	DEFINE query2_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	LET l_msgresp = kandoomsg("P",1001,"") 
	#1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME where_part ON 
	sign_on_code, 
	name_text, 
	security_ind, 
	passwd_ind, 
	group_code, 
	signature_text, 
	password_text, 
	cmpy_code, 
	profile_code, 
	language_code, 
	access_ind, 
	print_text, 
	acct_mask_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","U2B","construct-kandoouser") 

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
	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF
	LET l_rpt_idx = rpt_start(getmoduleid(),"UB2_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT UB2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET query_text = "SELECT * FROM kandoouser", 
	" WHERE ", where_part clipped, 
	" ORDER BY kandoouser.sign_on_code " 
	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO pr_rec_kandoouser.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT AC4_rpt_list(l_rpt_idx,pr_rec_kandoouser.*)   
		IF NOT rpt_int_flag_handler2("User:",pr_rec_kandoouser.sign_on_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT UB2_rpt_list
	CALL rpt_finish("UB2_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



###################################################################
# REPORT UB2_rpt_list(pr_rec_kandoouser )
#
#
###################################################################
REPORT UB2_rpt_list(pr_rec_kandoouser ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_kandoomodule RECORD LIKE kandoomodule.* 
	DEFINE pr_grant_deny RECORD LIKE grant_deny_access.* 
	DEFINE cmpy_head CHAR(132) 
	DEFINE pr_trans_text CHAR(7) 
	DEFINE pr_grant SMALLINT 
	DEFINE col2 SMALLINT 
	DEFINE col SMALLINT 
	DEFINE len SMALLINT 
	DEFINE s SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY pr_rec_kandoouser.sign_on_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, "User", 
			COLUMN 47, "Security", 
			COLUMN 56, "Profile", 
			COLUMN 64, "Password", 
			COLUMN 73, "Company", 
			COLUMN 81, "Language", 
			COLUMN 90, "Account Mask" 
			PRINT COLUMN 01, "Code", 
			COLUMN 51, "Modules" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_rec_kandoouser.sign_on_code 
			SKIP 1 line 

		AFTER GROUP OF pr_rec_kandoouser.sign_on_code 
			NEED 4 LINES 
			PRINT COLUMN 01, pr_rec_kandoouser.sign_on_code, 
			COLUMN 10, pr_rec_kandoouser.name_text, 
			COLUMN 51, pr_rec_kandoouser.security_ind, 
			COLUMN 56, pr_rec_kandoouser.profile_code, 
			COLUMN 64, pr_rec_kandoouser.password_text, 
			COLUMN 73, pr_rec_kandoouser.cmpy_code, 
			COLUMN 81, pr_rec_kandoouser.language_code, 
			COLUMN 90, pr_rec_kandoouser.acct_mask_code 

			LET query_text = "SELECT * FROM kandoomodule", 
			" WHERE user_code = '", pr_rec_kandoouser.sign_on_code,"' ", 
			" AND cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			" ORDER BY module_code " 
			PREPARE uchoice FROM query_text 
			DECLARE uselcurs CURSOR FOR uchoice 
			FOREACH uselcurs INTO pr_kandoomodule.* 
				PRINT COLUMN 30, pr_kandoomodule.module_code, " ", 
				pr_kandoomodule.security_ind, "|"; 
			END FOREACH 
			PRINT 
			LET query_text = 
			"SELECT grant_deny_access.* ", 
			" FROM grant_deny_access", 
			" WHERE sign_on_code = '", pr_rec_kandoouser.sign_on_code,"' ", 
			" ORDER BY grant_deny_access.menu1_code, ", 
			" grant_deny_access.menu2_code, ", 
			" grant_deny_access.menu3_code " 
			PREPARE gchoice FROM query_text 
			DECLARE gselcurs CURSOR FOR gchoice 
			LET pr_grant = false 
			FOREACH gselcurs INTO pr_grant_deny.* 
				IF pr_grant THEN ELSE 
					PRINT COLUMN 20, "Grant/Deny Access:"; 
					LET pr_grant = true 
				END IF 
				PRINT COLUMN 50, pr_grant_deny.menu1_code, 
				pr_grant_deny.menu2_code, 
				pr_grant_deny.menu3_code, 
				" ", 
				pr_grant_deny.grant_deny_flag 
			END FOREACH 
		ON LAST ROW 
			SKIP 3 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 


