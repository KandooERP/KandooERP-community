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
# FUNCTION IC0_main()
#
# Purpose - Pricing Reports
############################################################
FUNCTION IC0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 

	DEFER QUIT 
	DEFER INTERRUPT
		
	CALL setModuleId("IC0")

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL IC0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "IC1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW IC00 WITH FORM "IC00" ATTRIBUTE(BORDER,STYLE="full-screen")
	 CALL windecoration_i("IC00") 
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
			CALL IC0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW IC00 

END FUNCTION 
############################################################
# END FUNCTION IC0_main()
############################################################

############################################################
# FUNCTION IC0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION IC0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "IC1" 
			CALL IC1_main()
		WHEN "IC2" 
			CALL IC2_main()
		WHEN "IC3" 
			CALL IC3_main()
		WHEN "IC5" 
			CALL IC5_main()
		WHEN "IC6" 
			CALL IC6_main()
		WHEN "IC7" 
			CALL IC7_main()
		WHEN "ICE" 
			CALL ICE_main()
		WHEN "ICF" 
			CALL ICF_main() 
		WHEN "ICG" 
			CALL ICG_main()
		WHEN "ICH" 
			CALL ICH_main()
		WHEN "ICI" 
			CALL ICI_main()
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in IC","Invalid Menu Option choosen","error") 
	END CASE
	 	
	CALL setModuleId("IC0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION
############################################################
# END FUNCTION IC0_run_module(p_module_id)
############################################################