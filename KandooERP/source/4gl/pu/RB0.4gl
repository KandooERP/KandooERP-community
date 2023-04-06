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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../pu/RB_GROUP_GLOBALS.4gl" 
--GLOBALS "../pu/RB0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION RB0_main()
#
# Invoice REPORT
#
############################################################
FUNCTION RB0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 
--	DEFINE l_prg_name STRING

	DEFER quit 
	DEFER interrupt
		
	CALL setModuleId("RB00")

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL RB0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "RB1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW RB0 with FORM "RB00" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL  windecoration_r("RB00") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DIALOG ATTRIBUTES(UNBUFFERED) 

		#ListBox Menu
		INPUT l_list_menuchoice WITHOUT DEFAULTS FROM list_menuchoice 

		ON CHANGE list_menuchoice 
		LET l_inp_menuchoice = l_list_menuchoice 
		DISPLAY l_list_menuchoice TO tf_menuChoice 

		END INPUT 


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
			CALL RB0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW RB0 

END FUNCTION 


############################################################
# FUNCTION RB0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION RB0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "RB1" 
			CALL RB1_main()

		WHEN "RB2" 
			CALL RB2_main()
		
		WHEN "RB3" 
			CALL RB3_main()
			 
		WHEN "RB4" 
			CALL RB4_main()
			 
		WHEN "RB5" 
			CALL RB5_main()
			 
		WHEN "RB6" 
			CALL RB6_main()
			 
		WHEN "RB7" 
			CALL RB7_main()
			 
		WHEN "RB8" 
			CALL RB8_main()
			 
		WHEN "RB9" 
			CALL RB9_main()
			 
		WHEN "RBA" 
			CALL RBA_main()

		WHEN "RBC" 
			CALL RBC_main()
		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in RB","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("RB00") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION	