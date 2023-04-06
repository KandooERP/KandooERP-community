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
# FUNCTION IB0_main()
#
# Purpose - Warehouse Reports
############################################################
FUNCTION IB0_main() 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 

	DEFER QUIT 
	DEFER INTERRUPT
		
	CALL setModuleId("IB0")

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL IB0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "IB1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW IB00 with FORM "IB00" ATTRIBUTE(BORDER,STYLE="full-screen")
	 CALL windecoration_i("IB00") 
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
			CALL IB0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW IB00 

END FUNCTION 
############################################################
# END FUNCTION IB0_main()
############################################################

############################################################
# FUNCTION IB0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION IB0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "IB1" 
			CALL IB1_main()
		WHEN "IB2" 
			CALL IB2_main()
		WHEN "IB3" 
			CALL IB3_main()
		WHEN "IB4" 
			CALL IB4_main()
		WHEN "IB5" 
			CALL IB5_main()
		WHEN "IB8" 
			CALL IB8_main()
		WHEN "IB9" 
			CALL IB9_main()
		WHEN "IBA" 
			CALL IBA_main()
		WHEN "IBC" 
			CALL IBC_main() 
		WHEN "IBD" 
			CALL IBD_main()
		WHEN "IBS" 
			CALL IBS_main()
		WHEN "IBT" 
			CALL IBT_main()
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in IB","Invalid Menu Option choosen","error") 
	END CASE
	 	
	CALL setModuleId("IB0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION
