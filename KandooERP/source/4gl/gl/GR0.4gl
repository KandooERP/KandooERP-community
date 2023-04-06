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
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GR0_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
 DEFINE modu_report_run_once_code STRING
############################################################
# FUNCTION GR0_main()
#
# Invoice REPORT
############################################################
FUNCTION GR0_main() 
--	DEFINE l_myans CHAR(1) 
	DEFINE l_menuchoice VARCHAR(5) 
	DEFINE l_inpmenuchoice VARCHAR(5) 
	DEFINE l_prg_name STRING


	DEFER quit 
	DEFER interrupt

	CALL setModuleId("GR0") 

	LET modu_report_run_once_code = get_url_module_child()
	IF modu_report_run_once_code IS NOT NULL THEN 
		CALL GR0_run_module(modu_report_run_once_code)
		RETURN 
	ELSE
		LET l_menuchoice = "GR1"
	END IF
	 
	LET l_inpmenuchoice = l_menuchoice 

	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW GR00 with FORM "GR00" 
		CALL windecoration_g("GR00") 
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

		CLOSE WINDOW GR00 

		IF int_flag = true THEN 
			LET int_flag = false 
			EXIT WHILE 
		ELSE 
			#LET l_prg_name[1,3] = l_menuchoice
			LET l_prg_name = l_menuchoice
		END IF 

		#LET l_test = "1" 
		#LET glob_itis = today 

		CALL GR0_run_module(l_prg_name)

	END WHILE 
END FUNCTION 


############################################################
# FUNCTION GR0_run_module(p_option)
#
#
############################################################
FUNCTION GR0_run_module(p_option)
	DEFINE p_option STRING

	CASE p_option.toUpperCase()
		WHEN "GR1" 
			CALL GR1_main()

		WHEN "GR2" 
			--RUN "GR2" 
			CALL GR2_main()
		
		WHEN "GR3" 
			CALL GR3_main()
			 
		WHEN "GR4" 
			CALL GR4_main()


		WHEN "GR9" 
			CALL GR9_main()


		WHEN "GRA" 
			CALL GRA_main()
			 
			 
		WHEN "GRC" 
			CALL GRC_main()

		WHEN "GRD" 
			CALL GRD_main()

		WHEN "GRF" 
			CALL GRF_main()

		WHEN "GRG" 
			CALL GRG_main() 


		WHEN "GRH" 
			CALL GRH_main() 


		WHEN "GRI" 
			CALL GRI_main() 

		WHEN "GRJ" 
			CALL GRJ_main() 


		WHEN "GRK" 
			CALL GRK_main() 


		WHEN "GRL" 
			CALL GRL_main() 

		
		OTHERWISE # 
			CALL fgl_winmessage("Invalid Menu Option in GR","Invalid Menu Option choosen","error") 

	END CASE
	 	
	CALL setModuleId("GR0") #Reset program module id
	CALL glob_arr_rmsreps_idx.clear()
	CALL glob_arr_rec_rpt_kandooreport.clear()
	CALL glob_arr_rec_rpt_rmsreps.clear()
	CALL glob_arr_rec_rpt_printcodes.clear()
	CALL glob_arr_rec_rpt_header_footer.clear()
	INITIALIZE glob_rec_rpt_selector.* TO NULL

END FUNCTION	