--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 

FUNCTION libToolbarLoad(pOverwrite)
	DEFINE retCount SMALLINT
	DEFINE pOverwrite BOOLEAN
	DEFINE dt DATETIME YEAR TO SECOND
	DEFINE backupFileName STRING
	
	LET backupFileName = "unl/qxt_toolbar-", trim(dt), ".bak"
	
	
	IF pOverwrite = TRUE THEN
			DELETE FROM qxt_toolbar WHERE 1=1
	END IF
		
	SELECT COUNT(*) INTO retCount FROM qxt_toolbar
	
	IF retCount = 0 THEN
		LOAD FROM "unl/qxt_toolbar.unl" 
		INSERT INTO qxt_toolbar
	END IF
	
	RETURN retCount

END FUNCTION


