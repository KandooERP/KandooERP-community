############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
MAIN 
	DEFINE l_language RECORD 
		language_code LIKE language.language_code, 
		language_text LIKE language.language_text, 
		national_text LIKE language.national_text 
	END RECORD
	DEFINE reply CHAR(1) 

	DECLARE c_language CURSOR FOR 
	SELECT language_code,language_text,national_text FROM language 
	ORDER BY 1 

	FOREACH c_language INTO l_language.* 
		DISPLAY l_language.language_code," ",l_language.language_text," ",l_language.national_text 
	END FOREACH 

	 LET reply = fgl_winprompt(5,5, "You should see all the languages used in Kandoo", "", 50, 0) 
END MAIN 
