GLOBALS "lib_db_globals.4gl"


########################################################################################
# FUNCTION arparmextMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION arparmextMenu()
	MENU
		ON ACTION "Populate Table"
			CALL populate_table_arparmext()
			
		#ON ACTION "Import"
		#	CALL import_arparmext()
		ON ACTION "Export"
			CALL unload_arparmext(gl_setupRec.silentMode,gl_setupRec.unl_file_extension)
		ON ACTION "Delete All"
			CALL delete_arparmext_all()
		ON ACTION "Count"
			CALL getArparmextCount() --Count all aRParms rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION



###############################################################
# FUNCTION populate_table_arparmext()
#
#
###############################################################
FUNCTION populate_table_arparmext()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM arparmext 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code


			IF recCount = 1 THEN  --table data does exist in DB AND we will load it
				LET retState = 1

				SELECT * INTO gl_arparmext.*  #global record 
				FROM temp_arparmext
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code


			ELSE	#Assign Default VALUES AND store in temp table
				LET gl_arparmext.cmpy_code = gl_setupRec_default_company.cmpy_code
				LET gl_arparmext.last_int_date = gl_setupRec.fiscal_startDate
				LET gl_arparmext.int_acct_code = "4010"
				LET gl_arparmext.writeoff_acct_code ="8100"
				LET gl_arparmext.last_writeoff_date = gl_setupRec.fiscal_startDate
					
			  INSERT INTO arparmext	#Insert record TO temp table 
				VALUES (gl_arparmext.*)

				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION



###############################################################
# FUNCTION unload_aRParmExt(p_silentMode,p_fileExtension)
###############################################################
FUNCTION unload_aRParmExt(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING

	LET unloadFile = "unl/arparmext"	
	LET unloadFile1 = trim(unloadFile), "-" ,trim(gl_setupRec_default_company.country_code), "_", trim(getCurrentUser_cmpy_code()), ".", p_fileExtension
	UNLOAD TO unloadFile1
		SELECT  
			#cmpy_code,
	    last_int_date,
	    int_acct_code,
	    writeoff_acct_code,
	    last_writeoff_date

		FROM arparmext
		WHERE cmpy_code = currentCompany
		ORDER BY last_int_date ASC
		
	LET unloadFile2 = 	trim(unloadFile), ".", trim(p_fileExtension)
	UNLOAD TO unloadFile2 
	SELECT * FROM arparmext ORDER BY cmpy_code,last_int_date ASC	
		
	
	LET tmpMsg = "All arparmext (ORDER processing parameter extension) data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("arparmext Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION


