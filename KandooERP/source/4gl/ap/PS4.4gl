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
# Purpose - Allows the user TO PRINT mailing labels FOR Vendors
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PS4") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 


	OPEN WINDOW P100 with FORM "P100" 
	CALL windecoration_p("P100") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Vendor Mailing Label" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PS4","menu-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
			IF query() THEN 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL"			#ON ACTION "Exit"
			EXIT MENU 
	
	END MENU 

	CLOSE WINDOW P100 
END MAIN 

############################################################
# FUNCTION query()
#
#
############################################################
FUNCTION query() 
	DEFINE l_where_part CHAR(2048)
	DEFINE l_query_text CHAR(2200)
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_vendor RECORD LIKE vendor.*
--	DEFINE l_rpt_output CHAR(60)
	DEFINE l_msgresp LIKE language.yes_flag 

	#CALL rpt_rmsreps_set_page_num(0) 
	LET l_msgresp = kandoomsg("U", 1001, "") 
	#1001 " Enter selection criteria AND press ESC TO begin search"
	CONSTRUCT BY NAME l_where_part ON vendor.vend_code, 
	vendor.name_text, 
	vendor.addr1_text, 
	vendor.addr2_text, 
	vendor.addr3_text, 
	vendor.city_text, 
	vendor.state_code, 
	vendor.post_code, 
	vendor.country_code, 
--@db-patch_2020_10_04--	vendor.country_text, 
	vendor.our_acct_code, 
	vendor.contact_text, 
	vendor.tele_text, 
	vendor.extension_text, 
	vendor.fax_text, 
	vendor.type_code, 
	vendor.term_code, 
	vendor.tax_code, 
	vendor.currency_code, 
	vendor.tax_text, 
	vendor.bank_acct_code, 
	vendor.drop_flag, 
	vendor.language_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PS4","construct-vendor-1") 

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
	#User pressed CANCEL = p_where_text IS NULL 
	IF (l_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PS4_rpt_list_make_label",l_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PS4_rpt_list_make_label TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET l_where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	
	LET l_query_text = "SELECT * ", 
	"FROM vendor ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	l_where_part clipped, 
	" ORDER BY vend_code " 
	PREPARE statement_1 FROM l_query_text 
	DECLARE contact CURSOR FOR statement_1 


	OPEN contact 
	FOREACH contact INTO l_rec_vendor.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT PS4_rpt_list_make_label(l_rpt_idx,
		l_rec_vendor.*)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendor.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------


		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U", 8503, "") = "N" THEN #8503 Continue Report (Y/N) ?
				LET l_msgresp = kandoomsg("U", 9501, "") #9501 Report terminated
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PS4_rpt_list_make_label
	CALL rpt_finish("PS4_rpt_list_make_label")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF		
END FUNCTION 

############################################################
# REPORT PS4_rpt_list_make_label(p_rpt_idx,p_rec_vendor)
#
#
############################################################
REPORT PS4_rpt_list_make_label(p_rpt_idx,p_rec_vendor)
 	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_vendor RECORD LIKE vendor.* 

	OUTPUT 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

		ON EVERY ROW 
			SKIP TO top OF PAGE 
 
			IF p_rec_vendor.addr2_text IS NOT NULL THEN 
				PRINT p_rec_vendor.vend_code clipped, 1 space, p_rec_vendor.contact_text 
				PRINT p_rec_vendor.name_text 
				PRINT p_rec_vendor.addr1_text 
				PRINT p_rec_vendor.addr2_text 
				IF p_rec_vendor.city_text IS NULL 
				THEN 
					PRINT p_rec_vendor.state_code clipped, 
					" ", p_rec_vendor.post_code clipped 
				ELSE 
					PRINT p_rec_vendor.city_text clipped, ", ", p_rec_vendor.state_code clipped, 
					" ", p_rec_vendor.post_code clipped 
				END IF 
				PRINT p_rec_vendor.country_code --@db-patch_2020_10_04 report--
			ELSE 
				PRINT p_rec_vendor.vend_code clipped, 1 space, p_rec_vendor.contact_text 
				PRINT p_rec_vendor.name_text 
				PRINT p_rec_vendor.addr1_text 
				IF p_rec_vendor.city_text IS NULL 
				THEN 
					PRINT p_rec_vendor.state_code clipped, 
					" ", p_rec_vendor.post_code clipped 
				ELSE 
					PRINT p_rec_vendor.city_text clipped, ", ", p_rec_vendor.state_code clipped, 
					" ", p_rec_vendor.post_code clipped 
				END IF 
				PRINT p_rec_vendor.country_code --@db-patch_2020_10_04 report--
			END IF 

		ON LAST ROW 
			SKIP 1 line 
			SKIP 1 line
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 		
 		
END REPORT 
