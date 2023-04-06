# This program does "housekeeping" on REPORT writer tables which are
# permanent, although used in a "temporary" manner.  They should be
# cleared AFTER each run, although this doesn't always happen.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE fv_ans CHAR(1) 
	DEFINE nbr_deleted INTEGER
	DEFINE l_message STRING
	DEFINE global_status INTEGER

	CALL setModuleId("GWA") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	#WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET fv_ans = upshift(kandoomsg ("G", 1624, "")) 

	IF fv_ans = "Y" THEN 
		LET l_message = ""
		MESSAGE "Housekeeping in progress"
		LET  global_status = 0
		WHENEVER SQLERROR CONTINUE
		BEGIN WORK
		# one of the rare cases where LOCKING a table is allowed modif ericv 202004006
		LOCK TABLE rptslect IN EXCLUSIVE MODE
		LET global_status = global_status + sqlca.sqlcode
		LOCK TABLE colaccum IN EXCLUSIVE MODE
		LET global_status = global_status + sqlca.sqlcode
		LOCK TABLE rptargs IN EXCLUSIVE MODE
		LET global_status = global_status + sqlca.sqlcode
		IF global_status < 0 THEN
			# at least one table is not locked,but we want them all, ROLLBACK AND EXIT
			ROLLBACK WORK 
			CALL fgl_winmessage("Exiting Task","Cleanup:at least one of the tables is busy","error")
		ELSE
			LET  global_status = 0
			DELETE FROM rptslect 
			LET global_status = global_status + sqlca.sqlcode
			LET nbr_deleted = sqlca.sqlerrd[3]
			LET l_message = "rptslect:",nbr_deleted, " rows deleted "
			MESSAGE "DELETED ",nbr_deleted," ROWS FROM rptslect"
			DELETE FROM colaccum 
			LET global_status = global_status + sqlca.sqlcode
			LET nbr_deleted = sqlca.sqlerrd[3]
			LET l_message = l_message,"colaccum:",nbr_deleted, " rows deleted "
			MESSAGE "DELETED ",nbr_deleted," ROWS FROM colaccum"
			DELETE FROM rptargs 
			LET global_status = global_status + sqlca.sqlcode
			LET nbr_deleted = sqlca.sqlerrd[3]
			LET l_message = l_message,"colrptargs:",nbr_deleted, " rows deleted "
			IF global_status < 0 THEN
				# at least one table is not locked,but we want them all, ROLLBACK AND EXIT
				CALL fgl_winmessage("Exiting Task","Cleanup:Problems with tables delete","error")
				ROLLBACK WORK
			ELSE
				COMMIT WORK
				
				CALL fgl_winmessage("Task complete",l_message,"info")
			END IF 
		END IF
	ELSE 
		CALL fgl_winmessage("Task Cancelled","you cancelled the clean up","info") 

	END IF 

	SLEEP 1 

END MAIN 
