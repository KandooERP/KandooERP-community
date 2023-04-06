############################################################
# GLOBAL SCOPE VARIABLES
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS
	DEFINE glob_from_date DATE 
	DEFINE glob_to_date DATE 
END GLOBALS
#####################################################################
# FUNCTION get_time_frame()
#
#
#####################################################################
FUNCTION get_time_frame() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_from_year_num LIKE period.year_num
	DEFINE l_from_period_num LIKE period.period_num
	DEFINE l_to_year_num LIKE period.year_num
	DEFINE l_to_period_num LIKE period.period_num
	DEFINE l_year_text CHAR(7) 

	
	OPEN WINDOW A705 with FORM "A705" 
	CALL windecoration_a("A705") 

	INITIALIZE glob_to_date TO NULL 
	INITIALIZE glob_from_date TO NULL 
	INITIALIZE l_from_year_num TO NULL 
	INITIALIZE l_from_period_num TO NULL 
	INITIALIZE l_to_year_num TO NULL 
	INITIALIZE l_to_period_num TO NULL 
	LET l_msgresp = kandoomsg("U",1020,"Time Frame") 
	#1020 Enter Time Frame Details; OK TO Continue.
	INPUT l_from_year_num, 
	l_from_period_num, 
	l_to_year_num, 
	l_to_period_num, 
	glob_from_date, 
	glob_to_date 
	FROM
	l_from_year_num, 
	l_from_period_num, 
	l_to_year_num, 
	l_to_period_num, 
	glob_from_date, 
	glob_to_date

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AED","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_from_year_num IS NULL 
				AND l_from_period_num IS NULL 
				AND l_to_year_num IS NULL 
				AND l_to_period_num IS NULL 
				AND glob_from_date IS NULL 
				AND glob_to_date IS NULL THEN 
					LET l_msgresp = kandoomsg("J",9616,"") 
					#9616 Enter either a period range OR a date range
					NEXT FIELD from_year_num 
				END IF 
				
				IF (l_from_year_num IS NOT NULL 
				OR l_from_period_num IS NOT NULL 
				OR l_to_year_num IS NOT NULL 
				OR l_to_period_num IS NOT null) 
				AND (glob_from_date IS NOT NULL 
				OR glob_to_date IS NOT null) THEN 
					LET l_msgresp = kandoomsg("J",9615,"") 
					#9615 Both year/period AND date ranges cannot be entered.
					NEXT FIELD from_year_num 
				END IF 
				
				IF l_from_year_num IS NOT NULL THEN 
					IF l_from_period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD from_period_num 
					END IF 
				END IF 
				
				IF l_to_year_num IS NOT NULL THEN 
					IF l_to_period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD to_period_num 
					END IF 
				END IF 
				
				IF l_from_period_num IS NOT NULL THEN 
					IF l_from_year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD from_year_num 
					END IF 
				END IF 
				
				IF l_to_period_num IS NOT NULL THEN 
					IF l_to_year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD to_year_num 
					END IF 
				END IF 
				
				IF l_to_year_num < l_from_year_num THEN 
					LET l_msgresp = kandoomsg("U",9907,l_from_year_num) 
					#9907 "Value must be >= FROM year"
					NEXT FIELD to_year_num 
				END IF 
				IF l_from_year_num = l_to_year_num 
				AND l_to_period_num < l_from_period_num THEN 
					LET l_msgresp = kandoomsg("U",9907,l_from_period_num) 
					#9907 "Value must be >= FROM period"
					NEXT FIELD to_period_num 
				END IF 
				IF glob_to_date < glob_from_date THEN 
					LET l_msgresp = kandoomsg("U",9907,glob_from_date) 
					#9907 "Value must be >= FROM date"
					NEXT FIELD to_date 
				END IF 
				IF l_from_year_num IS NOT NULL 
				AND l_from_period_num IS NOT NULL THEN 
					SELECT start_date INTO glob_from_date FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_from_year_num 
					AND period_num = l_from_period_num 
					IF status = notfound THEN 
						LET l_year_text = l_from_year_num USING "####","/", 
						l_from_period_num USING "##" 
						LET l_msgresp = kandoomsg("G",9201,l_year_text) 
						#9201 "Year AND Period NOT defined FOR yyyy/mm"
						NEXT FIELD from_year_num 
					END IF 
				END IF 
				
				IF l_to_year_num IS NOT NULL 
				AND l_to_period_num IS NOT NULL THEN 
					SELECT end_date INTO glob_to_date FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_to_year_num 
					AND period_num = l_to_period_num 
					IF status = notfound THEN 
						LET l_year_text = l_to_year_num USING "####","/", 
						l_to_period_num USING "##" 
						LET l_msgresp = kandoomsg("G",9201,l_year_text) 
						#9201 "Year AND Period NOT defined FOR yyyy/mm"
						INITIALIZE glob_to_date TO NULL 
						INITIALIZE glob_from_date TO NULL 
						NEXT FIELD to_year_num 
					END IF 
				END IF 
				IF l_from_year_num IS NULL 
				AND l_to_year_num IS NOT NULL THEN 
					LET glob_from_date = "1/1/1" 
				END IF 
				IF l_to_year_num IS NULL 
				AND l_from_year_num IS NOT NULL THEN 
					LET glob_to_date = "31/12/9999" 
				END IF 
				IF glob_from_date IS NULL THEN 
					LET glob_from_date = "1/1/1" 
				END IF 
				IF glob_to_date IS NULL THEN 
					LET glob_to_date = "31/12/9999" 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW A705 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET glob_rec_rpt_selector.ref1_date = glob_from_date 
	LET glob_rec_rpt_selector.ref2_date = glob_to_date 
	RETURN true 
END FUNCTION 