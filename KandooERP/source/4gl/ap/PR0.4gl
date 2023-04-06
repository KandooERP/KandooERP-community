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
GLOBALS "../ap/P_PR_GROUP_GLOBALS.4gl"  

############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PR") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	--LET glob_name = get_baseprogname() 

--	LET glob_rpt_date = today 
	
	#What the xxxx - this IS doing nothing except authentication

	CALL PR0_main() 
END MAIN 



##################################################################
# FUNCTION pr0() 
#
# Menu to launch the different AR reports. User can select from 
# the list_menu OR enter directly into the text field.
##################################################################
FUNCTION PR0_main() 
	#DEFINE myans, test CHAR(1)
	DEFINE l_tempchar CHAR --huho 
	DEFINE l_list_menuchoice VARCHAR(3) 
	DEFINE l_tf_menuchoice VARCHAR(3) 

	LET l_list_menuchoice = "PR1" 
	LET l_tf_menuchoice = l_list_menuchoice 

--	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW w1_PR0 with FORM "PR0" ATTRIBUTE(BORDER,STYLE="full-SCREEN")
		CALL windecoration_p("PR0") 

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
			LET glob_name[1,3] = l_list_menuchoice
			CALL run_report(l_list_menuchoice)
			LET int_flag = FALSE	#in case, function set int_flag to exit it's sub-module report
			
		ON ACTION "CANCEL" 
			EXIT DIALOG
		 
	END DIALOG 

	CLOSE WINDOW w1_PR0


--	END WHILE 

END FUNCTION



##################################################################
# FUNCTION run_report(p_list_menuchoice) 
#
# Calls corresponding report module function 
##################################################################
FUNCTION run_report(p_list_menuchoice)
	DEFINE p_list_menuchoice VARCHAR(3)
	IF int_flag = true THEN #user pressed cancel -> EXIT PROGRAM
		LET int_flag = false 
		EXIT PROGRAM 
	ELSE 
		LET glob_name[1,3] = p_list_menuchoice 
	END IF 

--	#Required if AR0 was called with an argument for report file
--	LET l_report_code = get_url_report_code()
--	IF l_report_code IS NOT NULL THEN #report code was passed ot the program
--		LET l_url_arg = "REPORT_CODE=", trim(l_report_code)
--	ELSE
--		LET l_url_arg = NULL
--	END IF


		#CALL setModuleId(l_menuchoice)
		#CALL ui_init(0)
		#
		#   defer quit
		#   defer interrupt
		#
		#	CALL authenticate(getModuleId()) returning glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code

		CASE p_list_menuchoice 
			WHEN "PR1" #customer 
				CALL setModuleId("PR1")
				CALL ap_pr0(true) 
				--CALL droptemptableshuffle() 
{
			WHEN "AR2" #invoice 
				CALL setModuleId("AR2")
				CALL ar2(true) 
				CALL droptemptableshuffle() 

			WHEN "AR3" #receipt 
				CALL setModuleId("AR3")
				CALL ar3(true) 
				CALL droptemptableshuffle() 

			WHEN "AR4" #credit 
				CALL setModuleId("AR4")
				CALL fgl_winmessage("AR4 (Credit) does NOT exist in the sources","AR4 (Credit) does NOT exist in the sources!\n@huho @needsSorting","error") 
				#CALL AR4(TRUE)

			WHEN "AR5" #overdue collection
				CALL setModuleId("AR5")
				CALL ar5(true) 
				CALL droptemptableshuffle() 

			WHEN "AR6" #sales commissions 
				CALL setModuleId("AR6")
				CALL ar6(true) 
				CALL droptemptableshuffle() 

			WHEN "AR7" #sales tax billed
				CALL setModuleId("AR7")
				CALL ar7(true) 
				CALL droptemptabletaxamts() 
				CALL droptemptablebasetax() 
				CALL droptemptableshuffle() 

			WHEN "AR8" #ar snapshot HEADER
				CALL setModuleId("AR8")
				CALL run_prog("AR8","","","","")


			WHEN "ARA" #customer reports 
				CALL setModuleId("ARA")
				CALL ara(true) 
				CALL droptemptableshuffle() 

			WHEN "ARB" #invoice reports
				CALL setModuleId("ARB")
				CALL arb(true) 
				CALL droptemptableshuffle() 

			WHEN "ARC" #receipt reports 
				CALL setModuleId("ARC")
				CALL run_prog("ARC","","","","")

			WHEN "ARD" #credit reports 
				CALL setModuleId("ARD")
				CALL run_prog("ARD","","","","")

			WHEN "ARR" #accounts receivable reports 
				CALL setModuleId("ARR")
				CALL run_prog("ARR","","","","")

			WHEN "ART" #art_j aging REPORT a647 
				CALL setModuleId("ART_J")
				CALL run_prog("ART_J","","","","")

			WHEN "ARW" #customer write-off 
				CALL fgl_winmessage("Doesn't exist ARW","Doesn't exist ARW","info") 
				#CALL ARW() / RUN ARW

			WHEN "ARZ" 
				CALL fgl_winmessage("Doesn't exist ARZ","Doesn't exist ARZ","info") 
				#CALL ARZ() / RUN ARZ

			OTHERWISE # 
				CALL fgl_winmessage("Invalid Menu Option in AR","Invalid Menu Option choosen","error") 
		 }
		END CASE

		CALL setModuleId("PR0") #Reset program module id

END FUNCTION 
