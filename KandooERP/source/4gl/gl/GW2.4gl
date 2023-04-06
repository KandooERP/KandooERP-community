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

	Source code beautified by beautify.pl on 2020-01-03 14:28:55	$Id: $
}




# This module contains the global declarations AND main
# functions FOR the M.R.W. REPORT header maintenance programs.





{
FUNCTION            :   main
perform screens     :   hdr_maint
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GW2_GLOBALS.4gl" 


###########################################################
# MAIN
#
#Description         :   This IS the main FUNCTION of the hdr_maint
#                        module. It contains the code TO DISPLAY the
#                        hdr_maint form AND menu of OPTIONS TO the
#                        SCREEN, AND administer the user's choice of
#                        these OPTIONS
#
###########################################################
MAIN 
	DEFINE l_run_text CHAR(80) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg_str1 STRING 
	DEFINE l_arg_str2 STRING 

	CALL setModuleId("GW2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	#OPEN the maintenance window
	OPEN WINDOW g510 with FORM "G510" 
	CALL windecoration_g("G510") 

	#SET up the menu bar
	MENU "HEADER" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW2","menu-header-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Filter" 
			CALL hdr_qry() 

			IF glob_scurs_hdr_open THEN 
				CALL first_hdr() 
				CALL disp_hdr() 
			END IF 

			#COMMAND "Query" "SELECT Report headers"
			#    CALL hdr_qry()
			#    IF glob_scurs_hdr_open THEN
			#        CALL first_hdr()
			#        CALL disp_hdr()
			#    END IF

		ON ACTION "New" #command "ADD" "Add a Report header" 
			CALL hdr_add() 
			LET glob_scurs_hdr_open = false 

		ON ACTION "EDIT" #command "UPDATE" "Update selected Report header" 
			IF glob_scurs_hdr_open THEN 
				CALL hdr_updt () 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

		ON ACTION "DELETE" #command "Delete" "Delete selected Report header" 
			IF glob_scurs_hdr_open THEN 
				CALL hdr_dlte () 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

		ON ACTION "FIRST" #command KEY ("F",f18) "First" "SELECT the first RECORD in the queried SET" 
			IF glob_scurs_hdr_open THEN 
				CALL first_hdr() 
				CALL disp_hdr() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

		ON ACTION "LAST" #command KEY ("L",f22) "Last" "SELECT the last RECORD in the queried SET" 
			IF glob_scurs_hdr_open THEN 
				CALL last_hdr() 
				CALL disp_hdr() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

		ON ACTION "NEXT" #command KEY ("N",f21) "Next" "SELECT the next RECORD in the queried SET" 
			IF glob_scurs_hdr_open THEN 
				CALL next_hdr() 
				CALL disp_hdr() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

		ON ACTION "PREVIOUS" #command KEY ("P",f19) "Prev" "SELECT the previous RECORD in the queried SET" 
			IF glob_scurs_hdr_open THEN 
				CALL prev_hdr() 
				CALL disp_hdr() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected. Query first"
				NEXT option "Query" 
			END IF 

			--    COMMAND "More" "More menu OPTIONS"
			--
			--        menu "HEADER"
			--
			--		BEFORE MENU
			--      CALL publish_toolbar("kandoo","GW2","menu-header-2")
			--
			--			  ON ACTION "WEB-HELP"
			--			CALL onlineHelp(getModuleId(),NULL)
			--		ON ACTION "actToolbarManager"
			--			  	CALL setupToolbar()

		ON ACTION "Image" #command "Image" "Image an existing REPORT header" 
			CALL mrw_image() 

		ON ACTION "Columns" #command "Columns" "Maintain Column details" 
			LET l_arg_str1 = "CMPY_CODE=", trim(glob_rec_rpthead.cmpy_code) 
			LET l_arg_str2 = "REPORT_ID=", trim(glob_rec_rpthead.rpt_id) 

			CALL run_prog("GW3",l_arg_str1,l_arg_str2,"","") 

		ON ACTION "Lines" #command "Lines" "Maintain Line Details " 
			LET l_arg_str1 = "CMPY_CODE=", trim(glob_rec_rpthead.cmpy_code) 
			LET l_arg_str2 = "REPORT_ID=", trim(glob_rec_rpthead.rpt_id) 

			CALL run_prog("GW4 ",l_arg_str1,l_arg_str2,"","") 

		ON ACTION "Report" #command "Report" "Generate a REPORT of the definition details" 
			LET l_arg_str1 = "CMPY_CODE=", trim(glob_rec_rpthead.cmpy_code) 
			LET l_arg_str2 = "REPORT_ID=", trim(glob_rec_rpthead.rpt_id) 

			CALL run_prog("GW5",l_arg_str1,l_arg_str2,"","") 

		ON ACTION "Print Manager" #command KEY ("P",f11) "Print" "Print OR view REPORT in RMS" 
			CALL run_prog("URS","","","","") 

			--	        #ON ACTION "EXIT"
			--	        #COMMAND KEY(E,interrupt) "Exit" "Exit this menu"
			--	        #    EXIT MENU
			--
			--	 #          COMMAND KEY (control-w)
			--	 #             CALL kandoohelp("")
			--	 #
			--	 #       END MENU

		ON ACTION "Header" #command "Header" "Open REPORT header browse window" 
			LET glob_rec_rpthead.rpt_id = hdr_brws(glob_rec_rpthead.rpt_id) 
			IF glob_rec_rpthead.rpt_id IS NOT NULL THEN 
				SELECT * INTO glob_rec_rpthead.* FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
			END IF 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("K",9104,"") 
				#9104 "Customer NOT found"
			ELSE 
				CALL disp_hdr() 
			END IF 

		ON ACTION "EXIT" #command KEY(E,interrupt) "Exit" "Exit this menu TO calling process" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW g510 

END MAIN 


###########################################################
# FUNCTION disp_hdr()
#
#FUNCTION           :    disp-hdr
#Description        :    This FUNCTION selects info FROM the rpthead table AND
#                        hdrdetl table AND displays it TO the hdr_maint form
#Impact GLOBALS     :    gr_rowid  #HuHO ??? can't see this happening
#perform screens    :    hdr_maint
#
###########################################################
FUNCTION disp_hdr() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text, 
	glob_rec_rpthead.rpt_desc1, 
	glob_rec_rpthead.rpt_desc2, 
	glob_rec_rpthead.rpt_desc_position, 
	glob_rec_rpthead.rpt_type, 
	glob_rec_rpthead.rnd_code, 
	glob_rec_rpthead.sign_code, 
	glob_rec_rpthead.amt_picture, 
	glob_rec_rpthead.always_print_line, 
	glob_rec_rpthead.col_hdr_per_page, 
	glob_rec_rpthead.std_head_per_page 

	SELECT rptpos.* INTO glob_rec_rptpos.* FROM rptpos 
	WHERE rptpos_id = glob_rec_rpthead.rpt_desc_position 

	SELECT rpttype.* INTO glob_rec_rpttype.* FROM rpttype 
	WHERE rpttype_id = glob_rec_rpthead.rpt_type 

	SELECT rndcode.* INTO glob_rec_rndcode.* FROM rndcode 
	WHERE rnd_code = glob_rec_rpthead.rnd_code 

	SELECT signcode.* INTO glob_rec_signcode.* FROM signcode 
	WHERE sign_code = glob_rec_rpthead.sign_code 

	DISPLAY BY NAME glob_rec_rptpos.rptpos_desc, 
	glob_rec_rpttype.rpttype_desc, 
	glob_rec_rndcode.rnd_desc, 
	glob_rec_signcode.sign_desc 

END FUNCTION #disp_hdr() 
