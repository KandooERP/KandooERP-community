--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
###########################################################
# FUNCTION libCountryLoad(pOverwrite)
# LOAD data FROM unl TO country table
###########################################################
FUNCTION libkandooinfoLoad(pOverwrite)
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM kandooinfo WHERE 1=1
	END IF
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM kandooinfo)
	IF STATUS <> NOTFOUND THEN
		IF fgl_winquestion("Delete DB Table kandooinfo", "kandooinfo catalog (kandooinfo table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF
	END IF
	DELETE FROM kandooinfo WHERE 1=1	--delete table data
	LOAD FROM "unl/kandooinfo.unl" INSERT INTO kandooinfo



	
END FUNCTION