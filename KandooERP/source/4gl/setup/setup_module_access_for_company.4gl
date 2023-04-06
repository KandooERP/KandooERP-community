GLOBALS "lib_db_globals.4gl"

#####################################################
# FUNCTION enableCompanyKandooModules()       
#####################################################
FUNCTION enableCompanyKandooModules()
	DEFINE l_module_text LIKE company.module_text
	
	SELECT module_text INTO l_module_text FROM COMPANY WHERE cmpy_code = gl_setupRec_default_company.cmpy_code

	CALL copy_module_string_to_checkBox(l_module_text)
CALL fgl_winmessage("NEEDS checking!","Disoverd, that company.module_text was empty in my database.\nCheck it AFTER the installation/now","info")
	OPEN WINDOW wModuleChoice WITH FORM "per/setup/setup_module"
	CALL updateConsole()
	
	INPUT BY NAME setupModuleRecord.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
		ON ACTION "Previous"
		LET mdNavigatePrevious = TRUE
		EXIT INPUT				
		ON ACTION "Select All"
			CALL selectAllsetupModuleRecord()
		ON ACTION "Select All OFF"
			CALL selectAllOFFsetupModuleRecord()
	END INPUT
	
	LET l_module_text =  writeModuleRecordToString()
	
	CLOSE WINDOW wModuleChoice
	
	LET gl_setupRec_default_company.module_text = l_module_text
	
	IF mdNavigatePrevious THEN
		LET step_num = step_num - 1
		LET mdNavigatePrevious = FALSE
	ELSE
		LET step_num = step_num + 1
	END IF
		
	RETURN l_module_text
				
END FUNCTION


#####################################################
# FUNCTION copy_module_string_to_checkBox(p_module_text) --Utility
#####################################################	
FUNCTION copy_module_string_to_checkBox(p_module_text)
	DEFINE p_module_text LIKE company.module_text
	DEFINE i SMALLINT
		
	FOR i = 1 TO length(p_module_text)
	
	CASE p_module_text[i]
		WHEN "A"
			LET setupModuleRecord.a = TRUE

		WHEN "C"
			LET setupModuleRecord.c = TRUE

		WHEN "E"
			LET setupModuleRecord.e = TRUE
		WHEN "F"
			LET setupModuleRecord.f = TRUE
		WHEN "G"
			LET setupModuleRecord.g = TRUE
		WHEN "I"
			LET setupModuleRecord.i = TRUE
		WHEN "J"
			LET setupModuleRecord.j = TRUE
		WHEN "K"
			LET setupModuleRecord.k = TRUE
		WHEN "L"
			LET setupModuleRecord.l = TRUE
		WHEN "M"
			LET setupModuleRecord.m = TRUE
		WHEN "N"
			LET setupModuleRecord.n = TRUE
		WHEN "P"
			LET setupModuleRecord.p = TRUE
		WHEN "Q"
			LET setupModuleRecord.q = TRUE
		WHEN "R"
			LET setupModuleRecord.r = TRUE
		WHEN "T"
			LET setupModuleRecord.t = TRUE
		WHEN "U"
			LET setupModuleRecord.u = TRUE
		WHEN "W"
			LET setupModuleRecord.w = TRUE

		END CASE
	END FOR
	
	END FUNCTION


#####################################################
# FUNCTION selectAllsetupModuleRecord()     --Utility
#####################################################	
FUNCTION selectAllsetupModuleRecord()
	LET setupModuleRecord.a = TRUE
	LET setupModuleRecord.c = TRUE
	LET setupModuleRecord.e = TRUE
	LET setupModuleRecord.f = TRUE
	LET setupModuleRecord.g = TRUE
	LET setupModuleRecord.i = TRUE
	LET setupModuleRecord.j = TRUE
	LET setupModuleRecord.k = TRUE
	LET setupModuleRecord.l = TRUE
	LET setupModuleRecord.m = TRUE
	LET setupModuleRecord.n = TRUE
	LET setupModuleRecord.p = TRUE
	LET setupModuleRecord.q = TRUE
	LET setupModuleRecord.r = TRUE
	LET setupModuleRecord.t = TRUE
	LET setupModuleRecord.u = TRUE
	LET setupModuleRecord.w = TRUE
END FUNCTION


#####################################################
# FUNCTION selectAllOffsetupModuleRecord()  --Utility
#####################################################	
FUNCTION selectAllOffsetupModuleRecord()
	LET setupModuleRecord.a = FALSE
	LET setupModuleRecord.c = FALSE
	LET setupModuleRecord.e = FALSE
	LET setupModuleRecord.f = FALSE
	LET setupModuleRecord.g = FALSE
	LET setupModuleRecord.i = FALSE
	LET setupModuleRecord.j = FALSE
	LET setupModuleRecord.k = FALSE
	LET setupModuleRecord.l = FALSE
	LET setupModuleRecord.m = FALSE
	LET setupModuleRecord.n = FALSE
	LET setupModuleRecord.p = FALSE
	LET setupModuleRecord.q = FALSE
	LET setupModuleRecord.r = FALSE
	LET setupModuleRecord.t = FALSE
	LET setupModuleRecord.u = FALSE
	LET setupModuleRecord.w = FALSE
END FUNCTION


#####################################################
# FUNCTION writeModuleRecordToString()      --Utility
#####################################################	
FUNCTION writeModuleRecordToString()
	DEFINE i SMALLINT
	DEFINE l_module_text LIKE company.module_text
		
	LET i = 1
	
	IF setupModuleRecord.a = TRUE THEN
		LET l_module_text[i] = "A"
		LET i=i+1
	END IF
	IF setupModuleRecord.c = TRUE THEN
		LET l_module_text[i] = "C"
		LET i=i+1
	END IF
	IF setupModuleRecord.e = TRUE THEN
		LET l_module_text[i] = "E"
		LET i=i+1
	END IF
	IF setupModuleRecord.f = TRUE THEN
		LET l_module_text[i] = "F"
		LET i=i+1
	END IF
	IF setupModuleRecord.g = TRUE THEN
		LET l_module_text[i] = "G"
		LET i=i+1
	END IF

	IF setupModuleRecord.i = TRUE THEN
		LET l_module_text[i] = "I"
		LET i=i+1
	END IF
	IF setupModuleRecord.j = TRUE THEN
		LET l_module_text[i] = "J"
		LET i=i+1
	END IF
	IF setupModuleRecord.k = TRUE THEN
		LET l_module_text[i] = "K"
		LET i=i+1
	END IF
	IF setupModuleRecord.l = TRUE THEN
		LET l_module_text[i] = "L"
		LET i=i+1
	END IF
	IF setupModuleRecord.m = TRUE THEN
		LET l_module_text[i] = "M"
		LET i=i+1
	END IF
	IF setupModuleRecord.n = TRUE THEN
		LET l_module_text[i] = "N"
		LET i=i+1
	END IF
	IF setupModuleRecord.p = TRUE THEN
		LET l_module_text[i] = "P"
		LET i=i+1
	END IF
	IF setupModuleRecord.q = TRUE THEN
		LET l_module_text[i] = "Q"
		LET i=i+1
	END IF
	IF setupModuleRecord.r = TRUE THEN
		LET l_module_text[i] = "R"
		LET i=i+1
	END IF
	IF setupModuleRecord.t = TRUE THEN
		LET l_module_text[i] = "T"
		LET i=i+1
	END IF
	IF setupModuleRecord.u = TRUE THEN
		LET l_module_text[i] = "U"
		LET i=i+1
	END IF
	IF setupModuleRecord.w = TRUE THEN
		LET l_module_text[i] = "W"
		LET i=i+1
	END IF
	
	RETURN l_module_text

END FUNCTION


