GLOBALS "lib_db_globals.4gl"

###############################################################
# FUNCTION addFiscalPeriods()
# take the fiscal start date AND populate the period table accordingly
# period requires one row for each fiscal period
###############################################################
FUNCTION addFiscalPeriods()
	DEFINE l_recPeriod RECORD LIKE period.*
	DEFINE fiscal_period_size_month SMALLINT 
	DEFINE y,m,p SMALLINT
	DEFINE periodCount SMALLINT

	LET l_recPeriod.cmpy_code =  gl_setupRec_default_company.cmpy_code
	LET fiscal_period_size_month = 12 / gl_setupRec.fiscal_period_size


	LET l_recPeriod.gl_flag = "Y"  --GL Module
	LET l_recPeriod.ar_flag = "Y"  --AR Module
	LET l_recPeriod.ap_flag = "Y"  --AP Module
	LET l_recPeriod.pu_flag = "Y"  --PU Module
	LET l_recPeriod.in_flag = "Y"  --IN Module
	LET l_recPeriod.jm_flag = "Y"  --JM Module
	LET l_recPeriod.oe_flag = "Y"	  --OE Module

	
	FOR y = gl_setupRec.start_year_num TO gl_setupRec.end_year_num

		LET l_recPeriod.year_num =  y
		LET l_recPeriod.period_num = 0 --will be incremented by 1
		
		FOR m = 1 TO 12 STEP fiscal_period_size_month
			LET l_recPeriod.period_num = l_recPeriod.period_num + 1  
				
			LET l_recPeriod.start_date = mdy(m,1,l_recPeriod.year_num)
			LET l_recPeriod.end_date = l_recPeriod.start_date + fiscal_period_size_month UNITS MONTH - 1 UNITS DAY; #mdy(m,1,y) - 1
			#DISPLAY "start_dDate=", l_recPeriod.start_date
			#DISPLAY "end_dDate=", l_recPeriod.end_date
			
			#Account can be setup during the year i.e. starting in Q3-2020
			IF NOT ((l_recPeriod.year_num = gl_setupRec.start_year_num)
				AND (l_recPeriod.period_num < gl_setupRec.start_period_num)) THEN
			
				SELECT COUNT(*) INTO periodCount FROM period 
				WHERE cmpy_code = l_recPeriod.cmpy_code 
				AND year_num = l_recPeriod.year_num
				AND period_num = l_recPeriod.period_num
				
				IF periodCount = 0 THEN
					INSERT INTO period VALUES (l_recPeriod.*)
				ELSE
					ERROR "Period Entry for this company already exists"
				END IF
									
			END IF	
		END FOR
	END FOR

END FUNCTION
