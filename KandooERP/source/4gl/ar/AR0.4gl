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
#This file IS used as GLOBLAS file FROM AR1.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/AR0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
##################################################################
# FUNCTION AR0_main()
#
# Menu to launch the different AR reports. User can select from 
# the list_menu OR enter directly into the text field.
##################################################################
FUNCTION AR0_main()	
	DEFINE l_list_menuchoice STRING 
	DEFINE l_tf_menuchoice STRING 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AR0")

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL run_AR0_report(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_list_menuchoice = "AR1" 
		LET l_tf_menuchoice = l_list_menuchoice 
	END IF

	LET int_flag = false 

	OPEN WINDOW AR00 with FORM "AR00" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
	CALL windecoration_a("AR00") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DIALOG attributes(UNBUFFERED) 

		#ListBox Menu
		INPUT l_list_menuchoice WITHOUT DEFAULTS FROM list_menuchoice

			ON CHANGE list_menuchoice 
				LET l_tf_menuchoice = l_list_menuchoice 
				DISPLAY l_list_menuchoice TO tf_menuChoice 
		
		END INPUT 

		#TextField direct input
		INPUT l_tf_menuchoice WITHOUT DEFAULTS FROM tf_menuChoice
			ON CHANGE tf_menuChoice 
				LET l_list_menuchoice = l_tf_menuchoice 
				DISPLAY l_tf_menuchoice TO list_menuchoice 
			END INPUT 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	
		ON ACTION ("ACCEPT", "DoubleClickItem") 
			DISPLAY l_list_menuchoice TO list_menuchoice
			DISPLAY l_list_menuchoice TO tf_menuChoice
			--LET glob_name[1,3] = l_list_menuchoice
			CALL run_AR0_report(l_list_menuchoice)
			IF int_flag THEN
				LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			END IF
			
		ON ACTION "CANCEL" 
			EXIT DIALOG
		 
	END DIALOG 

	CLOSE WINDOW AR00 

END FUNCTION


##################################################################
# FUNCTION run_AR0_report(p_list_menuchoice) 
#
# Calls corresponding report module function 
##################################################################
FUNCTION run_AR0_report(p_list_menuchoice)
	DEFINE p_list_menuchoice STRING

		CASE p_list_menuchoice.toUpperCase()
			WHEN "AR1" #customer 
				CALL AR1_main() 
				
			WHEN "AR2" #invoice 
				CALL AR2_main() 

			WHEN "AR3" #receipt 
				CALL AR3_main() 

			WHEN "AR5" #overdue collection
				CALL AR5_main() 

			WHEN "AR6" #sales commissions 
				CALL AR6_main() 

			WHEN "AR7" #sales tax billed
				CALL AR7_main() 

			WHEN "AR8" #AR snapshot HEADER
				CALL AR8_main()
				#CALL run_prog("AR8","","","","")

			WHEN "ARA" #customer reports 
				CALL ARa_main() 

			WHEN "ARB" #invoice reports
				CALL ARb_main() 

			WHEN "ARC" #receipt reports 
				CALL ARc_main()
				#CALL run_prog("ARC","","","","")

			WHEN "ARD" #credit reports 
				CALL ARd_main()
				#CALL run_prog("ARD","","","","")

			WHEN "ARR" #accounts receivable reports 
				CALL ARr_main()
				#CALL run_prog("ARR","","","","")

			WHEN "ART_J" #ARt_j aging REPORT a647 
				CALL ART_J_main()
				#CALL run_prog("ART_J","","","","")

			WHEN "ARW" #customer write-off 
				CALL fgl_winmessage("Doesn't exist ARW","Doesn't exist ARW","info") 
				#CALL ARW() / RUN ARW

			OTHERWISE # 
				CALL fgl_winmessage("Invalid Menu Option in AR","Invalid Menu Option choosen","error") 

		END CASE
		 
		CALL setModuleId("AR0") #Reset program module id
--		INITIALIZE glob_rec_rmsreps.* TO NULL
--		INITIALIZE glob_rec_kandooreport.* TO NULL
		CALL droptemptableshuffle()
		CALL droptemptabletaxamts() 
		CALL droptemptablebasetax() 
		CALL droptemptableshuffle() 
		 		
END FUNCTION 

