FUNCTION lib_flatfiles_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

FUNCTION read_flat_file(fullpath,regexps,return_form) 
	# This function reads a flat file,with possibility or filtering line by regular expressions, and can return contents
	# either in a Dynamic array, or ONE variable(which is in fact a 1 element DYNAMIC array
	# Inbound parameters:
	# fullpath : full path of file name
	# grepexp : regular expression to filter line if any
	# return_form : "arr" to return a dynamic array, "var" to return a string variable (in fact return an array with 1 line or many lines)
	# Outbound:
	# Full Dynamic array or just one element of Dynamic array

	DEFINE fullpath STRING 
	DEFINE grepexp STRING 
	DEFINE return_form CHAR(3) 
	DEFINE file_handle base.channel 
	DEFINE regexp util.regex 
	DEFINE match util.match_results 
	DEFINE regexps STRING 
	DEFINE res boolean 
	DEFINE dir_handle,line_number,fdx,ddx INTEGER 
	DEFINE arr_file_contents DYNAMIC ARRAY OF STRING 
	DEFINE str_file_contents STRING 
	DEFINE line_contents STRING 

	# open the file
	IF NOT os.path.exists(fullpath) THEN 
		RETURN "File ",file_handle, " does not exist" 
	END IF 
	LET file_handle = base.channel.create() 

	CALL file_handle.openfile(fullpath, "r") 
	IF regexps = "" OR regexps IS NULL THEN 
		# if no regular expression, initialize to .* (all)
		LET regexps = "/.*/" 
	ELSE 
		LET regexps = "/",regexps,"/" 
	END IF 
	LET regexp = regexps 

	# read the script file
	LET line_number = 1 

	WHILE NOT file_handle.iseof() 
		LET line_contents = file_handle.readline() 
		LET match = util.regex.search(line_contents,regexp) 
		#
		IF (match = false ) THEN 
			# if the line does not match the regular expression
			CONTINUE WHILE 
		END IF 
		IF return_form = "arr" THEN 
			# one array element per line if 'arr' mode, else only 1 element
			LET arr_file_contents[line_number] = line_contents 
			LET line_number = line_number + 1 
		ELSE 
			LET arr_file_contents[line_number] = arr_file_contents[line_number],"\n",line_contents 
		END IF 
	END WHILE 
	CALL file_handle.close() 
	RETURN arr_file_contents 
END FUNCTION 
