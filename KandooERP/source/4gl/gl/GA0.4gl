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
GLOBALS "../gl/GA_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION GA0_main()
#
# Invoice REPORT
#
############################################################
FUNCTION GA0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 
--	DEFINE l_prg_name STRING

	DEFER quit 
	DEFER interrupt
		
	CALL setModuleId("GA0")

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL GA0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "GA1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW GA00 with FORM "GA00" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL windecoration_g("GA00") 
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
			CALL GA0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW GA00 

END FUNCTION 


############################################################
# FUNCTION GA0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION GA0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "GA1" 
			CALL GA1_main()

		WHEN "GA2" 
			CALL GA2_main()
		
		WHEN "GA3" 
			CALL GA3_main()
			 
		WHEN "GA4" 
			CALL GA4_main()
			 
		WHEN "GA5" 
			CALL GA5_main()
			 
		WHEN "GA6" 
			CALL GA6_main()
			 
		WHEN "GA7" 
			CALL GA7_main() 

		WHEN "GA8" 
			CALL GA8_main()

		WHEN "GA9" 
			CALL GA9_main()

		WHEN "GAA" 
			CALL GAA_main()

		WHEN "GAC" 
			CALL GAC_main()

		WHEN "GAG" 
			CALL GAG_main()

		WHEN "GAH" 
			CALL GAH_main()

		WHEN "GAI" 
			CALL GAI_main()

				
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in GA","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("GA0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION