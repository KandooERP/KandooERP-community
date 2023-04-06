--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 

MAIN
	DEFINE p_cmpy_code LIKE credreas.cmpy_code 
	DEFINE menuChoice STRING
	LET p_cmpy_code = "01"  --needs TO be handled by arg AND input

	CALL fgl_winmessage("Setup","This will become the Setup program\nFor now, we collect information on what IS required (modules) AND in what ORDER","info")

#MENU

# Table IS there, but it doesn't seem TO be used
#	ON ACTION "Device Type"
#		CALL import_device_type()  --note: devicde_type has NOT company COLUMN

	LET p_cmpy_code = "01"

	WHILE TRUE
	
		OPEN WINDOW wTableSelector WITH FORM "setupTableSelector"
	
		INPUT BY NAME menuChoice WITHOUT DEFAULTS
			ON ACTION "CANCEL"
				EXIT WHILE
		END INPUT 
	
		IF menuChoice IS NOT NULL THEN
			CALL dbTableHandler(menuChoice,"01")
		END IF

	END WHILE

{
	ON ACTION "Language" 		
		CALL import_language(FALSE,p_cmpy_code)  --silent=FALSE company = 01

	ON ACTION "Currency" 		
		CALL import_currency(FALSE,p_cmpy_code)  --silent=FALSE company = 01

	ON ACTION "Period"
		CALL import_period()

	ON ACTION "Report Pos"
		CALL import_rptpos()

	ON ACTION "Report Type"
		CALL import_rpttype()

	ON ACTION "Round Code" 
		CALL import_rndcode()

	ON ACTION "Sign Code" 
		CALL import_signcode()

	ON ACTION "Journal Type" 		
		CALL import_journal(FALSE,p_cmpy_code)  --silent=FALSE company = 01

	ON ACTION "COA"
		CALL db_coa_import(NULL)  --NULL = company must be specified by operator
		-- it also calls import_groupinfo(NULL)  --NULL = company must be specified by operator

	ON ACTION "Tax" 		
		CALL import_tax(UI_OFF,p_cmpy_code)  --silent=FALSE company = 01

	ON ACTION "credreas" --Credit Reason
		
	ON ACTION "Exit"
		EXIT MENU 
END MENU

}
END MAIN


FUNCTION dbTableHandler(pTableName,p_cmpy_code)
	DEFINE pTableName STRING
	DEFINE p_cmpy_code LIKE credreas.cmpy_code 
	
	MENU
		ON ACTION "Import"
			CALL dbTableImportHandler(pTableName,p_cmpy_code)

		ON ACTION "Export"
			CALL dbTableExportHandler(pTableName,p_cmpy_code)
		
		ON ACTION "Delete Data"
			CALL dbTableDeleteHandler(pTableName,p_cmpy_code)

	END MENU
END FUNCTION

FUNCTION dbTableImportHandler(pTableName,p_cmpy_code)
	DEFINE pTableName STRING
	DEFINE p_cmpy_code LIKE credreas.cmpy_code 
	
			CASE pTableName
				WHEN "language"
					CALL import_language(FALSE,p_cmpy_code)  --silent=FALSE company = 01

				WHEN "currency"
					CALL import_currency(FALSE,p_cmpy_code)  --silent=FALSE company = 01

				OTHERWISE 
					CALL fgl_winmessage("invalid case argument dbTableImportHandler(pTableName)",pTableName,"error")	
			END CASE
END FUNCTION



FUNCTION dbTableDeleteHandler(pTableName,p_cmpy_code)
	DEFINE pTableName STRING
	DEFINE p_cmpy_code LIKE credreas.cmpy_code 
	
			CASE pTableName
				WHEN "language"
					CALL delete_language(FALSE)  --silent=FALSE company = 01

				WHEN "currency"
					CALL delete_currency(FALSE)  --silent=FALSE company = 01

				OTHERWISE 
					CALL fgl_winmessage("invalid case argument dbTableDeleteHandler(pTableName)",pTableName,"error")	
			END CASE
END FUNCTION

FUNCTION dbTableExportHandler(pTableName,p_cmpy_code)
	DEFINE pTableName STRING
	DEFINE p_cmpy_code LIKE credreas.cmpy_code 
	DEFINE l_fileExtension STRING
	
	LET l_fileExtension = ".unl"
			CASE pTableName
				WHEN "language"
					CALL unload_language(FALSE,l_fileExtension)  --silent=FALSE company = 01

				WHEN "currency"
					CALL unload_currency(FALSE,l_fileExtension)  --silent=FALSE company = 01

				OTHERWISE 
					CALL fgl_winmessage("invalid case argument dbTableUnloadHandler(pTableName)",pTableName,"error")	
			END CASE
END FUNCTION
