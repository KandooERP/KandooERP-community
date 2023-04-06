############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

DEFINE modu_load_file STRING #load/unl file NAME 
DEFINE modu_file_path STRING #file path 
DEFINE modu_file_name STRING #file NAME 
DEFINE modu_arr_file_list DYNAMIC ARRAY OF STRING 

###########################################################################
# FUNCTION set_url_load_file(p_load_file)
#
# Accessor Method for URL modu_load_file
###########################################################################
FUNCTION set_url_load_file(p_load_file) 
	DEFINE p_load_file STRING 
	#we need to add validations after we know, what load_file symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_load_file = p_load_file.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_load_file()
#
# Accessor Method for URL modu_load_file
###########################################################################
FUNCTION get_url_load_file() 
	RETURN modu_load_file 
END FUNCTION 

###########################################################################
# FUNCTION set_url_file_path(p_file_path)
#
# Accessor Method for URL modu_file_path
###########################################################################
FUNCTION set_url_file_path(p_file_path) 
	DEFINE p_file_path STRING 
	#we need to add validations after we know, what file_path symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_file_path = p_file_path.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_file_path()
#
# Accessor Method for URL modu_file_path
###########################################################################
FUNCTION get_url_file_path() 
	RETURN modu_file_path 
END FUNCTION 

###########################################################################
# FUNCTION set_url_file_name(p_file_name)
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION set_url_file_name(p_file_name) 
	DEFINE p_file_name STRING 
	#we need to add validations after we know, what file_name symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_file_name = p_file_name.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_file_name()
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION get_url_file_name() 
	RETURN modu_file_name 
END FUNCTION 

-------------------------------------------------------------

###########################################################################
# FUNCTION set_url_file_list(p_file_list)
#
# Accessor Method for URL modu_file_list
###########################################################################
FUNCTION set_url_file_list(p_file_list_string) 
	DEFINE p_file_list_string STRING 
	DEFINE l_file_list_element STRING 
	DEFINE i_fs SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE x SMALLINT 
	#DEFINE modu_arr_file_list DYNAMIC ARRAY OF STRING

	LET x = 0 
	LET idx = 0 
	FOR i_fs=1 TO p_file_list_string.getlength() 


		IF p_file_list_string[i_fs] != "," THEN 
			LET x = x +1 
			LET l_file_list_element[x]=p_file_list_string[i_fs] 
		ELSE 
			LET idx = idx + 1 
			LET modu_arr_file_list[idx] = l_file_list_element 
			LET x = 1 #reset FOR NEXT token 
		END IF 

	END FOR 

END FUNCTION 


###########################################################################
# FUNCTION get_url_file_list_count()
#
# Accessor Method for URL modu_file_list
###########################################################################
FUNCTION get_url_file_list_count() 
	RETURN modu_arr_file_list.getlength() 
END FUNCTION 


###########################################################################
# FUNCTION get_url_file_list_element()
#
# Accessor Method for URL modu_file_list
###########################################################################
FUNCTION get_url_file_list_element(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_msg STRING 

	LET l_msg = "Fatal error get_url_file_list_element(p_idx)\np_idx=",trim(p_idx) 
	IF p_idx = 0 THEN 
		CALL fgl_winmessage("Fatal error get_url_file_list_element(p_idx)",l_msg,"error") 

	END IF 

	IF p_idx > modu_arr_file_list.getlength() THEN 
		LET l_msg = "Fatal error get_url_file_list_element(p_idx)\np_idx=",trim(p_idx), " but the array size is only ", trim(modu_arr_file_list.getlength()) 
		CALL fgl_winmessage("Fatal error get_url_file_list_element(p_idx)",l_msg,"error") 

	END IF 

	RETURN modu_arr_file_list[p_idx] 
END FUNCTION 

------------------------------------------------------