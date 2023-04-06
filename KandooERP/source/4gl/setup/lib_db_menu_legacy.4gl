--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
###########################################################
# FUNCTION libCountryLoad()
# LOAD data FROM unl TO country table
###########################################################
FUNCTION libMenuLegacyLoad(pOverwrite)
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM menu1 WHERE 1=1
			DELETE FROM menu2 WHERE 1=1
			DELETE FROM menu3 WHERE 1=1
			DELETE FROM menu4 WHERE 1=1

	END IF
	

#Note: There are 4 menu tables FROM the legacy menu. The legacy security uses these tables TO allow/dissallow a program launch

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu1)
	IF STATUS <> NOTFOUND THEN

		IF fgl_winquestion("Delete (legacy) Menu 1-4", "At least one menu table (menu1-4 IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF

	
			DELETE FROM menu1 WHERE 1=1
		#IF fgl_winquestion("Delete DB Table menu1", "menu1 catalog (menu1 table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 		#	RETURN
 		#ELSE
		#	DELETE FROM menu1 WHERE 1=1
 		#END IF
	END IF
		LOAD FROM "unl/menu1.unl" INSERT INTO menu1 			


	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu2)
	IF STATUS <> NOTFOUND THEN
		DELETE FROM menu2 WHERE 1=1
		#IF fgl_winquestion("Delete DB Table menu2", "menu2 catalog (menu2 table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 		#	RETURN
 		#END IF
	END IF

	LOAD FROM "unl/menu2.unl" INSERT INTO menu2


	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu3)
	IF STATUS <> NOTFOUND THEN
		DELETE FROM menu3 WHERE 1=1

		#IF fgl_winquestion("Delete DB Table menu3", "menu3 catalog (menu3 table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 		#	RETURN
 		#END IF
	END IF
	LOAD FROM "unl/menu3.unl" INSERT INTO menu3


	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM menu4)
	IF STATUS <> NOTFOUND THEN
		DELETE FROM menu4 WHERE 1=1
		#IF fgl_winquestion("Delete DB Table menu4", "menu4 catalog (menu4 table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 		#	RETURN
 		#END IF
	END IF

	LOAD FROM "unl/menu4.unl" INSERT INTO menu4

	
END FUNCTION