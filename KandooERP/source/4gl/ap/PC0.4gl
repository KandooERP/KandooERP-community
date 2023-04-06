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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
GLOBALS "../ap/PC0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION PC0_main()
#
# PC0 - Cheque & Debit Reports Sub-system 
#
############################################################
FUNCTION PC0_main() 
	DEFINE l_list_menuchoice VARCHAR(4) # moduleID will be the first char(3) of the program name   - FORM name first char(4) will be the identifier
	DEFINE l_inp_menuchoice VARCHAR(4) 
--	DEFINE l_prg_name STRING

	DEFER quit 
	DEFER interrupt
		
	CALL setModuleId("PC0")

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL PC0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "PC1"
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF
	 
	OPEN WINDOW PC00 with FORM "PC00" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL windecoration_p("PC00") 
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
			CALL PC0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
	
		ON ACTION "CANCEL" 
			EXIT DIALOG 

	END DIALOG 

	CLOSE WINDOW PC00 

END FUNCTION 


############################################################
# FUNCTION PC0_run_module(p_module_id)
#
# Calls corresponding report module function 
############################################################
FUNCTION PC0_run_module(p_module_id)
	DEFINE p_module_id STRING

	CASE p_module_id.toUpperCase()
		WHEN "PC1" 
			CALL PC1_main()

		WHEN "PC2" 
			CALL PC2_main()
		
		WHEN "PC3" 
			CALL PC3_main()
			 
		WHEN "PC4" 
			CALL PC4_main()
			 
		WHEN "PC5" 
			CALL PC5_main()

		WHEN "PC7" 
			CALL PC7_main()

		WHEN "PC8" 
			CALL PC8_main()

		WHEN "PC9" 
			CALL PC9_main()

		WHEN "PCA" 
			CALL PCA_main()

		WHEN "PCB" 
			CALL PCB_main() 

		WHEN "PCC" 
			CALL PCC_main() 

		WHEN "PCD" 
			CALL PCd_main()

		WHEN "PCE" 
			CALL PCE_main() 

		WHEN "PCF" 
			CALL PCF_main() 

		WHEN "PCFB" 
			CALL PCFb_main() 

		WHEN "PCFK" 
			CALL PCFk_main() 

		WHEN "PCG" 
			CALL PCG_main() 

		WHEN "PCH" 
			CALL PCH_main() 

		WHEN "PCJ" 
			CALL PCJ_main() 

		WHEN "PCK" 
			CALL PCK_main() 

		WHEN "PCL" 
			CALL PCL_main() 

		WHEN "PCR" 
			CALL PCR_main() 

		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in PC","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("PC0") #Reset program module id
	CALL rpt_rmsreps_reset(NULL)

END FUNCTION	