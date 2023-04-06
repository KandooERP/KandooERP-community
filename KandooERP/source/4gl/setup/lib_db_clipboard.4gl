
FUNCTION create_table_clipboard()

		CREATE TABLE clipboard
		(	    
	    sign_on_code  CHAR(8),
	    char_val CHAR,
	    string_val VARCHAR(200),
	    int_val INT,
	    date_val DATE
    )

END FUNCTION    


FUNCTION drop_table_clipboard()

		DROP TABLE clipboard	    

END FUNCTION




