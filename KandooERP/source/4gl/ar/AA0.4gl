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
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AA0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
#######################################################################
# FUNCTION aa_menu()
#
# AA controls all other AA reports 
#######################################################################
FUNCTION AA0_main()
	DEFINE l_prg_name STRING 
	DEFINE l_menuchoice VARCHAR(3) 
	DEFINE l_inpmenuchoice VARCHAR(3) 

	CALL setModuleId("AA0")	

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL AA0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_menuchoice = "AA1"
	END IF
	
	LET l_inpmenuchoice = l_menuchoice 

	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW AA00 with FORM "AA00" 
		CALL windecoration_a("AA00") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		dialog attributes(UNBUFFERED) 

		INPUT l_menuchoice WITHOUT DEFAULTS FROM menuchoice 


		ON CHANGE menuchoice 
		LET l_inpmenuchoice = l_menuchoice 
		DISPLAY l_menuchoice TO inpmenuchoice 

		END INPUT 

		INPUT l_inpmenuchoice WITHOUT DEFAULTS FROM inpmenuchoice 
			ON CHANGE inpmenuchoice 
				LET l_menuchoice = l_inpmenuchoice 
				DISPLAY l_inpmenuchoice TO menuchoice 
		END INPUT 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	
		ON ACTION ("ACCEPT", "DoubleClickItem") 
			DISPLAY l_menuchoice TO inpmenuchoice 
			LET l_prg_name = l_menuchoice 
			EXIT dialog 
	
		ON ACTION "CANCEL" 
			EXIT dialog 

	END dialog 

		CLOSE WINDOW AA00 

		IF int_flag = true THEN 
			LET int_flag = false 
			EXIT WHILE 
		ELSE 
			#LET l_prg_name[1,3] = l_menuchoice
			LET l_prg_name = l_menuchoice
		END IF 

		#LET l_test = "1" 
		#LET glob_itis = today 

		CALL AA0_run_module(l_prg_name)

	END WHILE 
END FUNCTION 



############################################################
# FUNCTION AA0_run_module(p_option)
#
#
############################################################
FUNCTION AA0_run_module(p_option)
	DEFINE p_option STRING

	CASE p_option.toUpperCase()
			WHEN "AA1"
				CALL setModuleId("AA1") 
				CALL AA1_main()
				
			WHEN "AA2"
				CALL setModuleId("AA2") 
				CALL AA2_main()
				
			WHEN "AA3"
				CALL setModuleId("AA3") 
				CALL AA3_main()
				
			WHEN "AA5" 
				CALL setModuleId("AA5")
				CALL AA5_main()
				 
			WHEN "AA6"
				CALL setModuleId("AA6") 
				CALL AA6_main() 
				
			WHEN "AA7"
				CALL setModuleId("AA7") 
				CALL AA7_main() 
				
			WHEN "AA8"
				CALL setModuleId("AA8") 
				CALL AA8_main() 
				
			WHEN "AA9"
				CALL setModuleId("AA9") 
				CALL AA9_main() 
				
			WHEN "AAA"
				CALL setModuleId("AAA") 
				CALL AAA_main()
				 
			WHEN "AAB"
				CALL setModuleId("AAB") 
				CALL AAB_main() 
				
			WHEN "AAB_B"
				CALL setModuleId("AAB_B") 
				CALL AAB_B_main() 
				
			WHEN "AAC"
				CALL setModuleId("AAC") 
				CALL AAC_main() 
				
			WHEN "AAD"
				CALL setModuleId("AAD") 
				CALL AAD_main() 
				
			WHEN "AAE" 
				CALL setModuleId("AAE")
				CALL AAE_main()
				 
			WHEN "AAF"
				CALL setModuleId("AAF") 
				CALL AAF_main() 
				
			WHEN "AAG"
				CALL setModuleId("AAG") 
				CALL AAG_main() 
				
			WHEN "AAH"
				CALL setModuleId("AAH") 
				CALL AAH_main() 
				
			WHEN "AAI"
				CALL setModuleId("AAI") 
				CALL AAI_main() 
				
			WHEN "AAJ"
				CALL setModuleId("AAJ") 
				CALL AAJ_main() 
				
			WHEN "AAK"
				CALL setModuleId("AAK") 
				CALL AAK_main() 
				
			WHEN "AAL"
				CALL setModuleId("AAL") 
				CALL AAL_main() 
				
			WHEN "AAM"
				CALL setModuleId("AAM") 
				CALL AAM_main()
				 
			WHEN "AAP"
				CALL setModuleId("AAP") 
				CALL AAP_main() 
				
			WHEN "AAT" 
				CALL setModuleId("AAT")
				CALL AAT_main()
				 
			WHEN "AAT_J" 
				CALL setModuleId("AAT_J")
				CALL AAT_J_main() 
				
			WHEN "AAU"
				CALL setModuleId("AAU") 
				CALL AAU_main() 
								
			WHEN "AAZ"
				CALL setModuleId("AAZ") 
				CALL AAZ_main() 
		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in AA","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("AA0") #Reset program module id

END FUNCTION	