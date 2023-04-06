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
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION AC0_main()
#
# Invoice REPORT
############################################################
FUNCTION AC0_main() 
	DEFINE l_menuchoice VARCHAR(3) 
	DEFINE l_inpmenuchoice VARCHAR(3) 
	DEFINE l_prg_name STRING
	
	CALL setModuleId("AC00")

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL AC0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_menuchoice = "AC1"
	END IF
	 
	LET l_inpmenuchoice = l_menuchoice 

	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW AC00 with FORM "AC00" 
		CALL windecoration_a("AC00") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		#---------------------------------------------------------------------
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
			LET l_prg_name[1,3] = l_menuchoice 
			EXIT dialog 
	
		ON ACTION "CANCEL" 
			EXIT dialog 

	END dialog
	#--------------------------------------------------------------------- 

		CLOSE WINDOW AC00 

		IF int_flag = true THEN 
			LET int_flag = false 
			EXIT WHILE 
		ELSE 
			#LET l_prg_name[1,3] = l_menuchoice
			LET l_prg_name = l_menuchoice
		END IF 

		#LET l_test = "1" 
		#LET glob_itis = today 

		CALL AC0_run_module(l_prg_name)

	END WHILE 
END FUNCTION 
############################################################
# END FUNCTION AC0_main()
############################################################


############################################################
# FUNCTION AC0_run_module(p_option)
#
#
############################################################
FUNCTION AC0_run_module(p_option)
	DEFINE p_option STRING

	CASE p_option.toUpperCase()
		WHEN "AC1" 
			CALL setModuleId("AC1")
			CALL AC1_main()

		WHEN "AC2" 
			--RUN "AC2" 
			CALL setModuleId("AC2")
			CALL AC2_main()
		
		WHEN "AC3" 
			CALL setModuleId("AC3")
			CALL AC3_main()
			 
		WHEN "AC4" 
			CALL setModuleId("AC4")
			CALL AC4_main()
			 
		WHEN "AC5" 
			CALL setModuleId("AC5")
			CALL AC5_main()

		WHEN "AC6" 
			CALL setModuleId("AC6")
			CALL AC6_main()

		WHEN "AC8" 
			CALL setModuleId("AC8")
			CALL AC8_main()


		WHEN "AC9" 
			CALL setModuleId("AC9")
			CALL AC9_main()


		WHEN "ACA" 
			CALL setModuleId("ACA")
			CALL ACA_main()
			 
		WHEN "ACB" 
			CALL setModuleId("ACB")
			CALL ACb_main() 
		
		OTHERWISE  
			CALL fgl_winmessage("Invalid Menu Option in AC","Invalid Menu Option choosen","error") 

	END CASE

	LET int_flag = FALSE
		 	
	CALL setModuleId("AC00") #Reset program module id
	CALL glob_arr_rmsreps_idx.clear()
	CALL glob_arr_rec_rpt_kandooreport.clear()
	CALL glob_arr_rec_rpt_rmsreps.clear()
	CALL glob_arr_rec_rpt_printcodes.clear()
	CALL glob_arr_rec_rpt_header_footer.clear()
	INITIALIZE glob_rec_rpt_selector.* TO NULL

END FUNCTION	
############################################################
# END FUNCTION AC0_run_module(p_option)
############################################################