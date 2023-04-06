############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE dt_rec_dbschema_fix TYPE AS RECORD 
		fix_name LIKE dbschema_fix.fix_name, 
		fix_abstract LIKE dbschema_fix.fix_abstract, 
		fix_tableslist LIKE dbschema_fix.fix_tableslist, 
		fix_apply_date LIKE dbschema_fix.fix_apply_date, 
		fix_status LIKE dbschema_fix.fix_status 
END RECORD
	
	
--		DEFINE lr_dbschema_fix OF dt_rec_dbschema_fix 
--	RECORD 
--		fix_name LIKE dbschema_fix.fix_name, 
--		fix_abstract LIKE dbschema_fix.fix_abstract, 
--		fix_tableslist LIKE dbschema_fix.fix_tableslist, 
--		fix_apply_date LIKE dbschema_fix.fix_apply_date, 
--		fix_status LIKE dbschema_fix.fix_status 
--	END RECORD


--DEFINE mr_dbschema_fix OF dt_rec_dbschema_fix
--RECORD 
--	fix_name LIKE dbschema_fix.fix_name, 
--	fix_abstract LIKE dbschema_fix.fix_abstract, 
--	fix_tableslist LIKE dbschema_fix.fix_tableslist, 
--	fix_apply_date LIKE dbschema_fix.fix_apply_date, 
--	fix_status LIKE dbschema_fix.fix_status 
--END RECORD 


