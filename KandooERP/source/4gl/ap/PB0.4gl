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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION PB0_main()
#
# Invoice REPORT
#
############################################################
FUNCTION PB0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 

	DEFER quit 
	DEFER interrupt
		
	CALL setModuleId("PB0")

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL PB0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "PB1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW PB00 with FORM "PB00" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL windecoration_p("PB00") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DIALOG ATTRIBUTES(UNBUFFERED) 

		#-----------------------------------
		#ListBox Menu
		INPUT l_list_menuchoice WITHOUT DEFAULTS FROM list_menuchoice 

		ON CHANGE list_menuchoice 
		LET l_inp_menuchoice = l_list_menuchoice 
		DISPLAY l_list_menuchoice TO tf_menuChoice 

		END INPUT 

		#-----------------------------------
		#TextField direct input
		INPUT l_inp_menuchoice WITHOUT DEFAULTS FROM tf_menuChoice 
			ON CHANGE tf_menuChoice 
				LET l_list_menuchoice = l_inp_menuchoice 
				DISPLAY l_inp_menuchoice TO list_menuchoice 
		END INPUT 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	
		ON ACTION ("ACCEPT", "DoubleClickItem") 
			DISPLAY l_list_menuchoice TO list_menuchoice
			DISPLAY l_list_menuchoice TO tf_menuChoice		
			CALL PB0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW PB00

END FUNCTION 
############################################################
# END FUNCTION PB0_main()
############################################################


############################################################
# FUNCTION PB0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION PB0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "PB1" 
			CALL PB1_main()

		WHEN "PB2" 
			CALL PB2_main()
		
		WHEN "PB3" 
			CALL PB3_main()
			 
		WHEN "PB4" 
			CALL PB4_main()
			 
		WHEN "PB5" 
			CALL PB5_main()
			 
		WHEN "PB6" 
			CALL PB6_main()
						 			 
		WHEN "PB7" 
			CALL PB7_main()
			 
		WHEN "PB8" 
			CALL PB8_main()
			 
		WHEN "PB9" 
			CALL PB9_main()
									
		WHEN "PBA" 
			CALL PBa_main()
			 
		WHEN "PBC" 
			CALL PBC_main() 

		WHEN "PBD" 
			CALL PBD_main()

		WHEN "PBE" 
			CALL PBE_main()
		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in PB","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("PB0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION
############################################################
# END FUNCTION PB0_run_module(p_module_id)
############################################################