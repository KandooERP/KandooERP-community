###########################################################################################################
# GLOBAL Scope Variables
###########################################################################################################
GLOBALS "../common/glob_GLOBALS.4gl"



#HuHo 11.05.2019 - NOT sure if we should keep this file - Open for removal
# Everything was moved to the corresponding table accesor files in lib_tool_db


###############################################################################
# Calculate, how many rows are currently selected in a display array table
#
# Needs checking if this also works in DIALOG statement with arr_count()
###############################################################################
FUNCTION getTableRowsSelected(p_screenRecordName)
	DEFINE p_screenRecordName STRING
	DEFINE l_size SMALLINT  --array size
	DEFINE idx SMALLINT
	DEFINE l_select_count SMALLINT --count total rows selected
	DEFINE l_arr_index DYNAMIC ARRAY OF SMALLINT
	LET l_size = DIALOG.getArrayLength(p_screenRecordName)
	
	FOR idx = 1 TO l_size
		IF dialog.isRowSelected(p_screenRecordName,idx) THEN
			LET l_select_count = l_select_count + 1
			CALL l_arr_index.append(idx)
		END IF
	END FOR
    	
	RETURN l_arr_index   	
END FUNCTION    	