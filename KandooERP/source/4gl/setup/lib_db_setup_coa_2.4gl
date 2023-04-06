--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
# Coa record types
	DEFINE t_recCoa  
		TYPE AS RECORD
			acct_code LIKE coa.acct_code,
			desc_text LIKE coa.desc_text,
			group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaFilter  
		TYPE AS RECORD
			filter_acct_code LIKE coa.acct_code,
			filter_desc_text LIKE coa.desc_text,
			filter_group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaSearch  
		TYPE AS RECORD
			filter_any_field STRING,
			filter_group_code LIKE coa.group_code
		END RECORD 		
{
########################################################################################
# FUNCTION db_coa_get_count_silent()
#-------------------------------------------------------
# Returns the number of Coa entries for the current company
########################################################################################
FUNCTION db_coa_get_count_silent()
	DEFINE ret_CoaCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Coa.DECLARE(sqlQuery) #CURSOR FOR getCoa
	CALL c_Coa.SetResults(ret_CoaCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CoaCount = -1
	ELSE
		CALL c_Coa.FetchNext()
	END IF

	RETURN ret_CoaCount
END FUNCTION
}

############################################
# FUNCTION db_coa_import(p_cmpy_code)
############################################
FUNCTION db_coa_import(p_cmpy_code)
	DEFINE msgString STRING
	DEFINE importReport STRING
		
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
  
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num  LIKE coa.end_year_num 
	DEFINE l_end_period_num  LIKE coa.end_period_num 
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	 
	DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_coa RECORD 
		acct_code            CHAR(18),
		desc_text            CHAR(40),
		type_ind             CHAR(1),
		group_code           CHAR(7),
		analy_req_flag       CHAR(1),
		analy_prompt_text    CHAR(20)--,
	END RECORD	
		
	CREATE TEMP TABLE temp_coa(
		acct_code            CHAR(18),
		desc_text            CHAR(40),
		type_ind             CHAR(1),
		group_code           CHAR(7),
		analy_req_flag       CHAR(1),
		analy_prompt_text    CHAR(20)--,
	)

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF p_cmpy_code IS NOT NULL THEN
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text
		CASE 
		WHEN p_country_code = "NUL"
			LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN p_country_code = "0"
			--company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	
		OPEN WINDOW wCoaImport WITH FORM "per/setup/db_coa_input"
		DISPLAY "Chart of Accounts Import" TO header_text
	
	
	IF cmpy_code_provided = FALSE THEN

			INPUT p_cmpy_code, p_country_code,p_language_code,l_start_year_num, l_start_period_num, l_end_year_num, l_end_period_num 
			WITHOUT DEFAULTS 
			FROM inputRec.*
			
			AFTER FIELD cmpy_code
				CALL get_company_info (p_cmpy_code)
				RETURNING p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text
				CASE 
				WHEN p_country_code = "NUL"
					LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN		
				WHEN p_country_code = "0"
					--company code comp_code does NOT exist
					LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN
				OTHERWISE
					LET cmpy_code_provided = TRUE
					DISPLAY p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text 
					TO desc_text,country_code,country_text,language_code,language_text
				END CASE 
		END INPUT

	ELSE
		DISPLAY p_cmpy_code TO cmpy_code
		INPUT p_cmpy_code, p_country_code,p_language_code,l_start_year_num, l_start_period_num, l_end_year_num, l_end_period_num
		WITHOUT DEFAULTS 
		FROM inputRec.*  
		END INPUT
	
	END IF

	let load_file = "unl/coa-",p_country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",p_country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_coa
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_coa
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_coa
			#DISPLAY rec_coa.*
			# IF NOT db_coa_pk_exists(p_cmpy_code,rec_coa.acct_code) THEN
			LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), "\n"
					
			INSERT INTO coa VALUES(
			p_cmpy_code,
			rec_coa.acct_code,
			rec_coa.desc_text,
			l_start_year_num, 
			l_start_period_num, 
			l_end_year_num, 
			l_end_period_num,
			rec_coa.group_code,
			rec_coa.analy_req_flag,
			rec_coa.analy_prompt_text,
			"",
			"",
			rec_coa.type_ind,  	 	
			""
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), " ->DUPLICATE = Ignored !\n"
				LET count_already_exist = count_already_exist +1
			OTHERWISE	
				LET count_insert_errors = count_insert_errors +1
			  	LET driver_error = fgl_driver_error()
			  	LET native_error = fgl_native_error()
			  	LET native_code = fgl_native_code()
			
				LET importReport = importReport, "ERROR STATUS:\t", trim(STATUS), "\n"
				LET importReport = importReport, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
				LET importReport = importReport, "driver_error:\t", trim(driver_error), "\n"
				LET importReport = importReport, "native_error:\t", trim(native_error), "\n"
				LET importReport = importReport, "native_code:\t",  trim(native_code), "\n"					
			END CASE
			LET count_rows_processed= count_rows_processed + 1
		
		END FOREACH
	END IF
	WHENEVER ERROR STOP


		
	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	INPUT BY NAME importReport WITHOUT DEFAULTS
		ON ACTION "Done"
			EXIT INPUT
	END INPUT
	
	RETURN count_rows_inserted
END FUNCTION
{
FUNCTION db_coa_pk_exists(p_cmpy_code, p_acct_code)
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM coa 
     WHERE cmpy_code = p_cmpy_code
     AND acct_code = p_acct_code

	DROP TABLE temp_coa
	CLOSE WINDOW wCoaImport
	
	RETURN recCount

END FUNCTION
}