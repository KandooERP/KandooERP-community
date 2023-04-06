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
}
# This module contains the global declarations AND main
# functions FOR the definitions REPORT programs.
{
FUNCTION            :   main
Description         :   This IS the main FUNCTION of the def_maint
                        module. It contains the code TO DISPLAY the
                        def_maint form AND menu of OPTIONS TO the
                        SCREEN, AND administer the user's choice of
                        these OPTIONS
perform screens     :   def_maint
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW5_GLOBALS.4gl" 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("GW5") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 


	LET gv_colline = "N" 


	SELECT * INTO gr_mrwparms.* 
	FROM mrwparms 

	OPEN WINDOW g575 with FORM "TG575" 
	CALL windecoration_t("TG575") -- albo kd-768 

	MENU "REPORTS" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW5","menu-REPORTS-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND key(h) "Header" "Report on header definitions" 
			OPEN WINDOW g509 with FORM "TG509" 
			CALL windecoration_t("TG509") -- albo kd-768 
			MESSAGE "" 
			CALL header_qry() 
			CLOSE WINDOW g509 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT option "Header" 
			END IF 
			IF gv_scurs_def_open THEN 
				NEXT option "Print Manager" 
			ELSE 
				ERROR "No records selected" 
				NEXT option "Header" 
			END IF 

		COMMAND key(c) "Columns" "Report on COLUMN definitions" 
			OPEN WINDOW g576 with FORM "TG576" 
			CALL windecoration_t("TG576") -- albo kd-768 
			MESSAGE "" 
			CALL column_qry() 
			CLOSE WINDOW g576 

			IF gv_scurs_def_open THEN 
				NEXT option "Print Manager" 
			ELSE 
				ERROR "No records selected" 
				NEXT option "Columns" 
			END IF 

		COMMAND key(l) "Lines" "Report on line definitions" 
			OPEN WINDOW g577 with FORM "TG577" 
			CALL windecoration_t("TG577") -- albo kd-768 
			CALL line_qry() 
			CLOSE WINDOW g577 
			IF gv_scurs_def_open THEN 
				NEXT option "Print Manager" 
			ELSE 
				ERROR "No records selected" 
				NEXT option "Lines" 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY(F10,P) "Print" "DISPLAY OR View using RMS"
			CALL run_prog("URS", "", "", "", "") 
			NEXT option "DEL TO Exit" 

		COMMAND KEY(E,interrupt) "DEL TO Exit" "Exit this menu TO calling process" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW g575 

END MAIN 
