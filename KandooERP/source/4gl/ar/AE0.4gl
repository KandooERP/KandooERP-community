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

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_prg_name CHAR(7)
######################################################################
# MAIN
#
#
######################################################################
MAIN 
	--DEFINE l_tempchar CHAR --huho 
	DEFINE l_menuchoice VARCHAR(3) 
	DEFINE l_inpmenuchoice VARCHAR(3)
	
	CALL setModuleId("AE00") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	LET l_menuchoice = "AE1" 
	LET l_inpmenuchoice = l_menuchoice 

	WHILE true 
		LET int_flag = false 
		#huho
		OPEN WINDOW w1_ar with FORM "AE00" 
		CALL windecoration_a("AE00") 

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
		LET modu_prg_name[1,3] = l_menuchoice 
		EXIT dialog 

	ON ACTION "CANCEL" 
		EXIT dialog 
		END dialog 

		CLOSE WINDOW w1_ar 

		IF int_flag = true THEN 
			LET int_flag = false 
			EXIT WHILE 
		ELSE 
			LET modu_prg_name[1,3] = l_menuchoice 
		END IF 

		CASE l_menuchoice 
			WHEN "AE1" 
				CALL AE1_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE2" 
				CALL AE2_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE3" 
				CALL AE3_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE4" 
				CALL AE4_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE6" 
				CALL AE6_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE7" 
				CALL AE7_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE8" 
				CALL AE8_main() 
				CALL droptemptableshuffle()
				 
			WHEN "AE9" 
				CALL AE9_main() 
				CALL droptemptableshuffle() 

			WHEN "AEC" 
				CALL AEC_main()
				 
			WHEN "AED" 
				CALL AED_main()
				
			WHEN "AEE" 
				CALL AEE_main()
				
			WHEN "AEF" 
				CALL AEF_main()

			OTHERWISE # 
				CALL fgl_winmessage("Invalid Menu Option in AE","Invalid Menu Option choosen","error") 

		END CASE 

	END WHILE 
END MAIN 


##################################################################################
# FUNCTION dropTempTableShuffle()
#
#
##################################################################################
FUNCTION droptemptableshuffle() 
	WHENEVER ERROR CONTINUE 

	IF fgl_find_table("shuffle") THEN
		DROP TABLE shuffle 
	END IF 	 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
