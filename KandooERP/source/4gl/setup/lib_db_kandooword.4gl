--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
FUNCTION libkandoowordLoad(pOverwrite)
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM kandooword WHERE 1=1
	END IF

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM kandooword)
	IF STATUS <> NOTFOUND THEN
		IF fgl_winquestion("Delete DB info", "Massages catalog (kandooword table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF
	END IF
	
	DELETE FROM kandooword WHERE 1=1	--delete table data
	LOAD FROM "unl/kandooword.unl" INSERT INTO kandooword
END FUNCTION 