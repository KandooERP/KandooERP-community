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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING

############################################################
# FUNCTION IR0_main()
#
# Purpose - Inventory Reports
############################################################
FUNCTION IR0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 

	DEFER QUIT 
	DEFER INTERRUPT
		
	CALL setModuleId("IR0")

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL IR0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "IR1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW IR00 WITH FORM "IR00" ATTRIBUTE(BORDER,STYLE="full-screen")
	 CALL windecoration_i("IR00") 
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
	
		ON ACTION ("ACCEPT","DoubleClickItem") 
			DISPLAY l_list_menuchoice TO list_menuchoice
			DISPLAY l_list_menuchoice TO tf_menuChoice		
			CALL IR0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW IR00 

END FUNCTION 
############################################################
# END FUNCTION IR0_main()
############################################################

############################################################
# FUNCTION IR0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION IR0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "IR1" 
			CALL IR1_main()
		WHEN "IR2" 
			CALL IR2_main()
		WHEN "IR3" 
			CALL IR3_main()
		WHEN "IR4" 
			CALL IR4_main()
		WHEN "IR5" 
			CALL IR5_main()
		WHEN "IR6" 
			CALL IR6_main()
		WHEN "IR7" 
			CALL IR7_main()
		WHEN "IR8" 
			CALL IR8_main()
		WHEN "IR9" 
			CALL IR9_main()
		WHEN "IRA" 
			CALL IRA_main()
		WHEN "IRB" 
			CALL IRB_main() 
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in IR","Invalid Menu Option choosen","error") 
	END CASE
	 	
	CALL setModuleId("IR0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION
############################################################
# END FUNCTION IR0_run_module(p_module_id)
############################################################