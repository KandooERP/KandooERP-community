database kandoodb
DEFINE listbox_array DYNAMIC ARRAY OF STRING # the trick is to INPUT an ARRAY variable instead of string, for multi-select Listbox
DEFINE col1 CHAR(10)
DEFINE col2 INTEGER
DEFINE listbox_string CHAR(32)
DEFINE rep CHAR(1)

MAIN
 
 WHENEVER SQLERROR CONTINUE
 DROP TABLE listbox_test
 WHENEVER SQLERROR STOP
 --CREATE TABLE listbox_test (col1 CHAR(10),col2 INTEGER,listbox_string CHAR(32))
	OPEN WINDOW w1 WITH FORM "f_listbox_multi"

	CALL display_former_values()
	ERROR "Please input the 2 first value, then choose one or more values for listbox"
	CALL input_next_values()
END MAIN
 

FUNCTION  input_next_values ()
	--LET listbox_array[1] = "value2"
	--LET listbox_array[2] = "value4"
	--DISPLAY BY NAME listbox_array
	INITIALIZE col1 TO NULL
	INITIALIZE col2 TO NULL
	CALL listbox_array.clear()

	INPUT BY NAME col1,col2,listbox_array ATTRIBUTE(WITHOUT DEFAULTS)
 
	LET listbox_string = join(listbox_array,",")
	DISPLAY "joined array = ",listbox_string
	INSERT INTO listbox_test VALUES (col1,col2,listbox_string)
END FUNCTION

FUNCTION display_former_values()

	PROMPT "Now we select the value from the table and display it (type return) " FOR CHAR rep

	INITIALIZE col1 TO NULL
	INITIALIZE col2 TO NULL
	CALL listbox_array.clear()
	SELECT * 
	INTO col1,col2,listbox_string
	FROM listbox_test

	LET listbox_array = split (listbox_string,",")
	DISPLAY BY NAME col1,col2,listbox_array


PROMPT "done!t (type return) " FOR CHAR rep
END FUNCTION

FUNCTION join(in_array,separator)
DEFINE in_array DYNAMIC ARRAY OF STRING
DEFINE separator NCHAR(1)
DEFINE concat_string,out_string STRING
DEFINE i,arr_size INTEGER

FOR i = 1 TO in_array.getsize()
	LET concat_string = concat_string CLIPPED,in_array[i],separator
END FOR
LET out_string = util.REGEX.replace(concat_string,/,$/,//)
RETURN out_string
END FUNCTION
	
FUNCTION split(in_string,separator)
DEFINE in_string STRING
DEFINE out_array DYNAMIC ARRAY OF STRING
DEFINE separator NCHAR(1)
DEFINE concat_string,out_string STRING
DEFINE i,arr_size INTEGER
DEFINE match util.MATCH_RESULTS
LET i = 0
WHILE true
	LET match = util.regex.search(in_string,/(\w+)/)
	IF match THEN
		LET i = i+1
		LET out_array[i] = match.str(1)
		LET in_string = match.suffix()
	ELSE
		EXIT WHILE
	END IF
END WHILE

RETURN out_array
END FUNCTION


