##############################################################################################
# TABLE company
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION valid_period(p_cmpy,p_year_num,p_period_num, p_sub_text)
#
# FUNCTION valid_period validates the passed year AND period number
############################################################
FUNCTION valid_period(p_cmpy,p_year_num,p_period_num, p_sub_text)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_year_num LIKE period.year_num
	DEFINE p_period_num LIKE period.period_num
	DEFINE l_period RECORD LIKE period.*
	DEFINE p_sub_text CHAR(2)
	DEFINE l_query_stmt STRING
	DEFINE l_statement STRING
	DEFINE l_msgresp LIKE language.yes_flag   
	DEFINE l_crs_valid_period CURSOR

	IF (p_period_num <= 0 OR p_period_num IS NULL)
	OR (p_year_num <= 1980 OR p_year_num IS NULL) THEN
		LET l_msgresp=kandoomsg("G",9012,"")
		RETURN p_year_num,p_period_num,TRUE
	ELSE
		# we build up the query because the where clause contains a variable column name coming from p_sub_text
		# Weird logic .... 
		
		# Check if statement has already ever been declared or NOT
		LET l_statement = l_crs_valid_period.GetStatement()
		IF l_statement IS NULL THEN
			LET l_query_stmt = "SELECT * FROM period WHERE year_num = ? AND period_num = ? AND cmpy_code = ? "
			--			" AND ", downshift(p_sub_text) clipped,"_flag='Y'"
			CALL l_crs_valid_period.Declare(l_query_stmt)
			LET l_statement = l_crs_valid_period.GetStatement()
		END IF
		CALL l_crs_valid_period.SetParameters(p_year_num,p_period_num,p_cmpy)

		WHENEVER SQLERROR CONTINUE
		CALL l_crs_valid_period.open()
		CALL l_crs_valid_period.SetResults(l_period.*)
		CALL l_crs_valid_period.FetchNext()
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		CASE 
			WHEN  sqlca.sqlcode = 0
				CASE 
					WHEN (p_sub_text = LEDGER_TYPE_GL AND l_period.gl_flag = "Y")
					OR (p_sub_text = LEDGER_TYPE_AR AND l_period.ar_flag = "Y")
					OR (p_sub_text = LEDGER_TYPE_AP AND l_period.ap_flag = "Y")
					OR (p_sub_text = LEDGER_TYPE_PU AND l_period.pu_flag = "Y")	
					OR (p_sub_text = LEDGER_TYPE_IN AND l_period.in_flag = "Y")
					OR (p_sub_text = LEDGER_TYPE_JM AND l_period.jm_flag = "Y")
					OR (p_sub_text = LEDGER_TYPE_OE AND l_period.oe_flag = "Y")
						# the period is found and right flag set to Y: OK (return false)
						CALL l_crs_valid_period.Close()
						RETURN 
							p_year_num,
							p_period_num,
							FALSE
					
					OTHERWISE
						# the period exists but flag is not set to Y
						LET l_msgresp=kandoomsg("G",9013,"")
				END CASE
				
			WHEN  sqlca.sqlcode = NOTFOUND
				# This period does not exist
				--SELECT 1 FROM period
				--WHERE cmpy_code = p_cmpy
					--AND year_num = p_year_num
					--AND period_num = p_period_num
				--IF sqlca.sqlcode = NOTFOUND THEN
				LET l_query_stmt = p_year_num using "<<<<","|",p_period_num using "<<<"
				LET l_msgresp=kandoomsg("G",9011,l_query_stmt)
				--ELSE
					--LET l_msgresp=kandoomsg("G",9013,"")
				--END IF
				CALL l_crs_valid_period.Close()
				RETURN p_year_num,p_period_num,TRUE
		END CASE
	END IF
END FUNCTION

############################################################
# FUNCTION valid_period2(p_cmpy,p_year_num,p_period_num,p_sub_text)
#
############################################################
FUNCTION valid_period2(p_cmpy,p_year_num,p_period_num,p_sub_text)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_year_num LIKE period.year_num
	DEFINE p_period_num LIKE period.period_num
	DEFINE p_sub_text CHAR(2)
	DEFINE l_temp_text CHAR(150)
	DEFINE l_msgresp LIKE language.yes_flag   


   LET l_temp_text = "SELECT 1 FROM period ",
                       "WHERE year_num = '",p_year_num,"' ",
                         "AND period_num = '",p_period_num,"' ",
                         "AND cmpy_code = '",p_cmpy,"' ",
                         "AND ",downshift(p_sub_text) clipped,"_flag='Y'"
   PREPARE s2_period FROM l_temp_text
   DECLARE c2_period CURSOR FOR s2_period
   OPEN c2_period
   FETCH c2_period
   IF sqlca.sqlcode = 0 THEN
      close c2_period
      RETURN TRUE
   ELSE
      close c2_period
      RETURN FALSE
   END IF
END FUNCTION


############################################################
# Returns the period (year & period based on current company)
# FUNCTION db_period_what_period(p_cmpy,p_date)
#
#
# FUNCTION db_period_what_period()
#                      returns the associated fiscal period & year
#                      FOR the date passed.  IF none exists THEN
#                      the current period & year are returned.
#
# FUNCTION get_fiscal_year_period_for_date()
#                      identical TO what_period except that FUNCTION
#                      returns NULL year & period IF none exists.
#                      This allows error messaging TO be handled by
#                      calling program.
#
#   RETURN l_rec_period.year_num,
#          l_rec_period.period_num
############################################################
FUNCTION db_period_what_period(p_cmpy,p_date)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_date date
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_msgresp LIKE language.yes_flag   
	DEFINE l_msgtext STRING

	#Huho - so, NULL or none-initialized date is set to TODAY
	IF p_date IS NULL OR p_date = 0 THEN
		LET p_date = TODAY
	END IF

   WHILE TRUE
      SELECT year_num,
             period_num
        INTO l_rec_period.year_num,
             l_rec_period.period_num
        FROM period
       WHERE cmpy_code = p_cmpy
         AND start_date <= p_date
         AND end_date >= p_date
      IF STATUS = NOTFOUND THEN
         #LET l_msgresp=kandoomsg("U",7100,p_date)
         #7100 " GL Period FOR p_date IS NOT Set Up
         LET p_date = TODAY # IF entered date NOT found check todays date
         SELECT year_num,
                period_num
           INTO l_rec_period.year_num,
                l_rec_period.period_num
           FROM period
          WHERE cmpy_code = p_cmpy
            AND start_date <= p_date
            AND end_date >= p_date
         IF STATUS = NOTFOUND THEN
            #LET l_msgresp=kandoomsg("G",1020,TODAY)
            #1020 " GL Period FOR TODAY IS NOT Set Up
            LET l_msgtext = "WARNING\nFiscal Year and Period not set up for ",p_date,".\nRun Program GZA to set up Fiscal Periods."
            CALL msgerror("",l_msgtext)

            MENU " Invalid Period"
					BEFORE MENU
						CALL publish_toolbar("kandoo","vperfunc","menu-Invalid-Period")   
                  CALL fgl_dialog_setactionlabel("Set Up Period","Set Up Period","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",2,FALSE,"Run Program GZA to set up Fiscal Periods")
 
               ON ACTION "WEB-HELP"  -- albo  KD-370
               	CALL onlineHelp(getModuleId(),NULL)

               ON ACTION "Set Up Period"								         
               	#COMMAND "Set Up Period "
               	#        " Run Program GZA TO Set up current period"
                  CALL run_prog("GZA","","","","")
                  EXIT MENU

					ON ACTION "Exit"
               	#COMMAND "EXIT PROGRAM"
                	#       " RETURN TO Menu "
                  EXIT PROGRAM
            END MENU
            CONTINUE WHILE
         END IF
      END IF
      EXIT WHILE
   END WHILE
   
   RETURN l_rec_period.year_num, l_rec_period.period_num
END FUNCTION


############################################################
# FUNCTION get_fiscal_year_period_for_date(p_cmpy,p_date)
#
#
############################################################
FUNCTION get_fiscal_year_period_for_date(p_cmpy,p_date)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_date date
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_msgresp LIKE language.yes_flag   

   SELECT year_num,
          period_num
     INTO l_rec_period.year_num,
          l_rec_period.period_num
     FROM period
    WHERE cmpy_code = p_cmpy
      AND p_date BETWEEN start_date AND end_date

   IF sqlca.sqlcode != 0 THEN
      SELECT year_num,
             period_num
        INTO l_rec_period.year_num,
             l_rec_period.period_num
        FROM period
       WHERE cmpy_code = p_cmpy
         AND start_date <= TODAY
         AND end_date >= TODAY
      IF sqlca.sqlcode != 0 THEN
         LET l_rec_period.year_num = NULL
         LET l_rec_period.period_num = NULL
      END IF
   END IF
   RETURN l_rec_period.year_num,
          l_rec_period.period_num
END FUNCTION


############################################################
# FUNCTION change_period(p_cmpy, p_curr_year, p_curr_period, p_offset)
#
# FUNCTION change_period returns the associated period & year p_offset FROM a
# year & period AND p_offset passed
############################################################
FUNCTION change_period(p_cmpy, p_curr_year, p_curr_period, p_offset)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_offset SMALLINT
	DEFINE p_curr_year SMALLINT
	DEFINE p_curr_period SMALLINT
	DEFINE l_rec_period RECORD LIKE period.*

	DEFINE i SMALLINT

	DEFINE l_msgresp LIKE language.yes_flag   

   DECLARE period_set scroll CURSOR FOR
   SELECT period.*
   FROM period
   WHERE period.cmpy_code = p_cmpy
   ORDER BY year_num, period_num
   OPEN period_set

   # now position ourselves

   FETCH period_set INTO l_rec_period.*
   WHILE (l_rec_period.year_num != p_curr_year
        OR l_rec_period.period_num != p_curr_period)
      FETCH next period_set INTO l_rec_period.*
   END WHILE

   # ok now reposition AND go back

   CASE
      # why anyone would do this .....
      WHEN (p_offset = 0)
      # lets go back some periods.....
      WHEN (p_offset < 0)
         LET p_offset = 0 - p_offset + 0
         FOR i=1 TO p_offset
            FETCH previous period_set INTO l_rec_period.*
            IF STATUS = 100 THEN
               LET l_msgresp = kandoomsg("U",9926,"")
               #9926 " There are no more OPEN periods"
               EXIT FOR
            END IF
         END FOR
      # lets go forward some periods.....
      WHEN (p_offset > 0)
         FOR i=1 TO p_offset
            FETCH next period_set INTO l_rec_period.*
            IF STATUS = 100 THEN
               LET l_msgresp = kandoomsg("U",9926,"")
               #9926 " There are no more OPEN periods"
               EXIT FOR
            END IF
         END FOR
   END CASE

   RETURN l_rec_period.year_num, l_rec_period.period_num
END FUNCTION   # change_period

# FUNCTION check_prykey_exists_period: checks whether the primary key exists
# inbound: cmpy_code and part_code
# outbound: boolean true if exists, false if not exists
FUNCTION check_prykey_exists_period(p_cmpy_code,p_year_num,p_period_num)
	DEFINE p_cmpy_code LIKE period.cmpy_code
	DEFINE p_year_num LIKE period.year_num
  	DEFINE p_period_num LIKE period.period_num
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true', else, it remains as 'false'
	SELECT TRUE
	INTO prykey_exists
	FROM period
	WHERE cmpy_code = p_cmpy_code
		AND year_num = p_year_num
      AND period_num = p_period_num
	RETURN prykey_exists
END FUNCTION #check_prykey_exists_period()

