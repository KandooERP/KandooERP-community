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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW5_GLOBALS.4gl" 

############################################################
# MAIN
#
# Description         :  This IS the main FUNCTION of the def_maint
#                        module. It contains the code TO DISPLAY the
#                        def_maint form AND menu of OPTIONS TO the
#                        SCREEN, AND administer the user's choice of
#                        these OPTIONS
# Perform screens     :  def_maint
# This module contains the global declarations AND main
# functions FOR the definitions REPORT programs.
############################################################
MAIN 
	DEFINE l_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GW5") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	SELECT * INTO glob_rec_mrwparms.* 
	FROM mrwparms 

	OPEN WINDOW g509 with FORM "G509" 
	CALL windecoration_g("G509") 

	#Check IF the rpthead.rpt_id has been passed
	LET glob_rec_rpthead.rpt_id = get_url_report_id() #arg_val(2) 
	IF glob_rec_rpthead.rpt_id IS NOT NULL 
	AND glob_rec_rpthead.rpt_id != " " THEN 
		LET glob_query_1 = "rpthead.rpt_id = '",glob_rec_rpthead.rpt_id,"'" 
		CALL def_curs() 
		IF glob_scurs_def_open THEN 
			CALL first_def() 
			# SELECT REPORT header information
			SELECT * INTO glob_rec_rpthead.* FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 

			CALL disp_def() 
		END IF 
	END IF 

	LET l_rpt_id = def_brws(glob_rec_rpthead.rpt_id, false) --get data / all ROWS 

	MENU " Definitions " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GW5","menu-definitions") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			IF glob_rec_rpthead.rpt_id IS NULL 
			OR glob_rec_rpthead.rpt_id = " " THEN 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "Header" 
				HIDE option "Column" 
				HIDE option "Line" 
			END IF 

		ON ACTION "actToolbarManager" 
			#COMMAND "Query" " SELECT Report headers"
			CALL def_qry() 
			IF glob_scurs_def_open THEN 
				CALL first_def() 
				CALL disp_def() 
				IF glob_rec_rpthead.rpt_id IS NOT NULL THEN 
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "Header" 
					SHOW option "Column" 
					SHOW option "Line" 
				ELSE 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "Header" 
					HIDE option "Column" 
					HIDE option "Line" 
				END IF 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " SELECT next selected record"
			IF glob_scurs_def_open THEN 
				CALL next_def() 
				CALL disp_def() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected, use Query option"
				NEXT option "Query" 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Previous" " SELECT previous selected record"
			IF glob_scurs_def_open THEN 
				CALL prev_def() 
				CALL disp_def() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected, use Query option"
				NEXT option "Query" 
			END IF #glob_scurs_def_open THEN 

		ON ACTION "Header" 
			#COMMAND "Header" " Report on header definitions"
			IF glob_scurs_def_open THEN 
				CALL GW5_rpt_def_rpthdr() 
				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected, use Query option"
				NEXT option "Query" 
			END IF 

		ON ACTION "Column" 
			#COMMAND "Column" " Report on COLUMN definitions"
			IF glob_scurs_def_open THEN 
				CALL GW5_rpt_def_rptcol() 
				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected, use Query option"
				NEXT option "Query" 
			END IF 

		ON ACTION "Line" 
			#COMMAND "Line" " Report on line definitions"
			IF glob_scurs_def_open THEN 
				CALL GW5_rpt_def_rptline() 
				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			ELSE 
				LET l_msgresp = kandoomsg("G",9206,"") 
				#9206 "No records selected, use Query option"
				NEXT option "Query" 
			END IF 

		ON ACTION "Browse" 
			#COMMAND "Browse" " Open REPORT header browse window"
			LET l_rpt_id = def_brws(glob_rec_rpthead.rpt_id, true) 
			IF l_rpt_id IS NOT NULL THEN 
				LET glob_rec_rpthead.rpt_id = l_rpt_id 
				SELECT * INTO glob_rec_rpthead.* FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",9116,"") 
					#9116 "This REPORT was NOT found"
				ELSE 
					CALL disp_def() 
				END IF 
			END IF 

			#ON ACTION "f11"
		ON ACTION "Print Manager" 
			#COMMAND KEY(f11)
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" 
			#COMMAND KEY("E",interrupt) "Exit" " Exit TO menus"
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 

	END MENU 

	CLOSE WINDOW g509 
END MAIN 


############################################################
# FUNCTION disp_def()
#
# Description        :    This FUNCTION selects info FROM the rpthead table AND
#                         defdetl table AND displays it TO the def_maint form
# Impact GLOBALS     :    gr_rowid
# Perform screens    :    def_maint
############################################################
FUNCTION disp_def() 

	CLEAR FORM 
	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text 


END FUNCTION 
