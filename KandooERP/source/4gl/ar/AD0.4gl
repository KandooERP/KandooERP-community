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
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AD_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AD0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION ab_report_menu()
#
# Invoice REPORT
############################################################
FUNCTION ab_report_menu() 
	DEFINE l_myans CHAR(1) 
	DEFINE l_test CHAR(1) 
	DEFINE l_menuchoice VARCHAR(3) 
	DEFINE l_inpmenuchoice VARCHAR(3) 
	DEFINE l_prg_name STRING
	CALL setModuleId("AD0")
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	LET modu_report_run_once_code = get_url_module_child() 
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL run_AB0_report(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_menuchoice = "ADA"
	END IF
	 
	LET l_inpmenuchoice = l_menuchoice 

	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW AB0 with FORM "AB0" 
		CALL windecoration_a("AB0") 
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
			LET l_prg_name[1,3] = l_menuchoice 
			EXIT dialog 
	
		ON ACTION "CANCEL" 
			EXIT dialog 

	END dialog 

		CLOSE WINDOW AB0 

		IF int_flag = true THEN 
			LET int_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_prg_name[1,3] = l_menuchoice 
		END IF 

		LET l_test = "1" 
--		LET glob_itis = today 

		# LET l_prg_name = get_baseProgName()

		CALL run_AB0_report(l_prg_name[1,3] )

	END WHILE 
END FUNCTION 


############################################################
# FUNCTION run_AB0_report(p_option)
#
#
############################################################
FUNCTION run_AB0_report(p_option)
	DEFINE p_option STRING

	CASE p_option.toUpperCase()
		WHEN "ADA" 
			CALL ADA_main()

		WHEN "ADB" 
			CALL ADB_main()
		
		WHEN "ADC" 
			CALL ADC_main()
			 
		WHEN "ADD" 
			CALL ADD_main()
			 
		WHEN "ADE" 
			CALL ADE_main()
			 
		WHEN "ADF" 
			CALL ADF_main()
			 
		WHEN "ADR" 
			CALL ADR_main() 

		WHEN "ADU" 
			CALL ADU_main()
		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in AD","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("AD0") #Reset program module id
	CALL glob_arr_rmsreps_idx.clear()
	CALL glob_arr_rec_rpt_kandooreport.clear()
	CALL glob_arr_rec_rpt_rmsreps.clear()
	CALL glob_arr_rec_rpt_printcodes.clear()
	CALL glob_arr_rec_rpt_header_footer.clear()
	INITIALIZE glob_rec_rpt_selector.* TO NULL

END FUNCTION	