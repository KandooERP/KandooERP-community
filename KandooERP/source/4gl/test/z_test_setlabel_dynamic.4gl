
MAIN
	DEFINE json_data STRING
	DEFINE json_obj util.JSONObject
	DEFINE input_class_num INTEGER

	--WHENEVER SQLERROR CONTINUE
	
	OPEN WINDOW mywindow WITH FORM "z_test_json" ATTRIBUTE(BORDER)
	Let json_data = '{"lvl1":"7","lvl2":"76","lvl3":"760"}'
	LET json_obj=util.JSONObject.parse(json_data)
	CALL display_json_as_array (json_obj)

END MAIN


FUNCTION display_json_as_array (p_json_obj)
	DEFINE p_json_obj util.JSONObject
	DEFINE json_data STRING
	DEFINE idx smallint
	DEFINE l_arr_NoSql_Data DYNAMIC ARRAY OF RECORD
		fld_label ui.Label,
		fld_value STRING
	END RECORD
	DEFINE l_fldName STRING

	CALL l_arr_NoSql_Data.Clear()
	FOR idx=1 TO p_json_obj.getLength()
		# Set the label for this field
		LET l_arr_NoSql_Data[idx].fld_label=p_json_obj.name(idx)
		LET l_arr_NoSql_Data[idx].fld_value = p_json_obj.get(p_json_obj.name(idx))
  		DISPLAY idx,": ",p_json_obj.name(idx),"=",p_json_obj.get(p_json_obj.name(idx))
	END FOR
	
	INPUT ARRAY l_arr_NoSql_Data WITHOUT DEFAULTS
	FROM NosqlTable.* 

END FUNCTION 	# display_json_fields