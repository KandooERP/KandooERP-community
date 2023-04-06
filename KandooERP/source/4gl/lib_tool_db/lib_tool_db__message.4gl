##############################################################################################
# MESSAGES FOR TABLE ACCESSOR Functions
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


CONSTANT DB_MSG_Exist_LEFT STRING = "invoicehead"
CONSTANT DB_MSG_Exist_RIGHT STRING = "invoicehead"
CONSTANT DB_MSG_Exist1 STRING = "invoicehead"

FUNCTION lib_tool_db_get_message(p_ui_mode,p_op_mode,p_table,p_column,p_val1,p_val2)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_table STRING
	DEFINE p_column STRING
	DEFINE p_val1 STRING
	DEFINE p_val2 STRING
	DEFINE l_ret_msg STRING

	CASE p_ui_mode	
		WHEN UI_OFF#no message

		WHEN UI_ON #Default message
			CASE p_op_mode
				 
				
				WHEN MODE_INSERT 
				 
				WHEN MODE_UPDATE 
				 
				WHEN MODE_DELETE
				
				OTHERWISE # MODE_SELECT is default
				 
			END CASE
			 
		WHEN UI_PK #MESSAGE FOR PK Handling
			CASE p_op_mode
				 
				
				WHEN MODE_INSERT 
				 
				WHEN MODE_UPDATE 
				 
				WHEN MODE_DELETE
				
				OTHERWISE # MODE_SELECT is default
				 
			END CASE
			
		WHEN UI_FK #MESSAGE FOR FK Handling
			CASE p_op_mode
				 
				
				WHEN MODE_INSERT 
				 
				WHEN MODE_UPDATE 
				 
				WHEN MODE_DELETE
				
				OTHERWISE # MODE_SELECT is default
				 
			END CASE
					
	END CASE
	
	RETURN l_ret_msg
END FUNCTION


#	CONSTANT UI_OFF SMALLINT = 0 #without UI messages
#	CONSTANT UI_ON SMALLINT = 1 #messages turned on
#	CONSTANT UI_FK SMALLINT = 2  #message validation for Primary Key
#	CONSTANT UI_PK SMALLINT = 3 #message validation for Foreign Key

##############################################################################
# FUNCTION lib_tool_db_get_NULL_message(p_ui_mode,p_table,p_column)
#
#
##############################################################################
FUNCTION lib_tool_db_get_msg_NULL(p_ui_mode,p_table,p_column)
	DEFINE p_ui_mode STRING
	DEFINE p_table STRING
	DEFINE p_column STRING
	DEFINE l_ret_msg STRING

	IF p_ui_mode != 0 THEN
		IF p_table IS NULL THEN
			LET l_ret_msg = p_column, " can not be empty/null!"
		ELSE
			LET l_ret_msg = p_table, "/", p_column, " can not be empty/null!"
		END IF
	END IF
	
	RETURN l_ret_msg
END FUNCTION
##############################################################################
# END FUNCTION lib_tool_db_get_NULL_message(p_ui_mode,p_table,p_column)
##############################################################################