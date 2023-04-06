##########################################################################
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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl"
GLOBALS "../ar/AS0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
##################################################################
# FUNCTION AS0_main()
#
# Menu to launch the different AR reports. User can select from 
# the list_menu OR enter directly into the text field.
##################################################################
FUNCTION AS0_main() 
--	DEFINE l_tempchar CHAR --huho 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_inp_menuchoice VARCHAR(3) 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AS0")

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL AS0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "AS1" 
		LET l_inp_menuchoice = l_list_menuchoice 
	END IF

	OPEN WINDOW AS0 with FORM "AS0" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL windecoration_a("AS0") 
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
			CALL AS0_run_module(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
			
		ON ACTION "CANCEL" 
			EXIT DIALOG
		 
	END DIALOG 

	CLOSE WINDOW AS0 

END FUNCTION


##################################################################
# FUNCTION AS0_run_module(p_module_id) 
#
# Calls corresponding report module function 
##################################################################
FUNCTION AS0_run_module(p_module_id)
	DEFINE p_module_id VARCHAR(3)

--	LET glob_rpt_time = time 
--	LET glob_rpt_date = today 

		CASE p_module_id 
			WHEN "AS1" #Invoice Print (AS1) 
				CALL AS1_main() 
				
			WHEN "AS5" #Account Aging (AS5) 
				CALL AS5_main() 

			WHEN "AS6" #Print Statements (AS6) 
				CALL AS6_main() 

			WHEN "AS7" #Post Period Activity (AS7) 
				CALL AS7_main() 

			WHEN "AS8" #Charge Interest and Service Fee (AS8)
				CALL AS8_main() 

			WHEN "ASA" #Generate Mailing Labels (ASA)
				CALL ASA_main() 

			WHEN "ASA_C" #Generate Mailing Labels (ASA_C)
				CALL ASA_C_main() 

			WHEN "ASAa" #Generate Mailing Labels (ASAa)
				CALL ASAa_main()
				#CALL run_prog("AR8","","","","")

			WHEN "ASB" #Mailing Labels - The Principal (ASB) 
				CALL ASB_main() 

			WHEN "ASD_J" #Load Customer List with Report (ASD_J)
				CALL ASD_J_main() 

			WHEN "ASI_J" #Transation Report (ASI_J)
				CALL ASI_J_main()

			WHEN "ASL" #Transaction Load (ASL)
				CALL ASL_main()

			WHEN "ASD_J" #???????????????? (ASD_J) 
				CALL ASD_J_main()

			WHEN "ASI_J" #?????????????? (ASI_J)
				CALL ASI_J_main()

			WHEN "ASU" #customer write-off 
				CALL ASU_main() #Transaction Purge by Fiscal Year (ASU)

			WHEN "ASV" #???????????????????? (ASV) 
				CALL ASV_main() 

			WHEN "ASV_J" #???????????????????? (ASV_J) 
				CALL ASV_J_main() 

			WHEN "ASW" #Transaction Purge by Fiscal Year (ASW) 
				CALL ASW_main() 

			WHEN "ASY_J" #???????????????????? (ASY_J) 
				CALL ASY_J_main() 

			WHEN "ASZ_J" #???????????????????? (ASZ_J)
				CALL ASZ_J_main() 


			OTHERWISE # 
				CALL fgl_winmessage("Invalid Menu Option in AS","Invalid Menu Option choosen","error") 

		END CASE
		 
		CALL setModuleId("AS0") #Reset program module id
		CALL rpt_rmsreps_reset(NULL)
		CALL droptemptableshuffle()
		CALL droptemptabletaxamts() 
		CALL droptemptablebasetax() 
		CALL droptemptableshuffle() 
		 		
END FUNCTION 

