# Project: KandooERP
# Filename: z_test_cursor_methods.4gl
# Created By: begooden-it
# Creation Date: 2 mai 2020
database kandoodb
DEFINE m_crs_customer CURSOR
DEFINE m_sql_statement STRING
DEFINE m_cmpy_code LIKE customer.cmpy_code

MAIN
	LET m_cmpy_code = "KA"
	CALL cursor_with_placeholders()
	CALL update_with_placeholders()
	CALL cursor_with_placeholders_fetch_into_values()
	CALL temptative_fetchall_into_array ()
END MAIN

FUNCTION cursor_with_placeholders ()
	# singleton (returns only one value) query with place holders. 
	# uses a cursor Directly declared from the query statement variable
	DEFINE l_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_crs_customer CURSOR
	DEFINE l_sql_statement STRING

	LET l_cust_code = fgl_winprompt(10,10,"Please enter customer code",NULL,10,0)
	LET l_sql_statement = "SELECT * FROM customer WHERE cmpy_code = ? AND cust_code = ?"
	CALL l_crs_customer.declare(l_sql_statement)

	CALL l_crs_customer.SetParameters(m_cmpy_code,l_cust_code)   # Supported method for now
	CALL l_crs_customer.open()
	
	# How we would like to have the open method below
	#CALL l_crs_customer.open(m_cmpy_code,l_cust_code)	
	
	CALL l_crs_customer.fetchNext()
	IF sqlca.sqlcode = NOTFOUND THEN
		ERROR "Did not find this client ",m_cmpy_code," ",l_cust_code
	ELSE
		CALL l_crs_customer.setresults(l_rec_customer.*) 	# Watch out: If I have closed and freed this cursor previously, setResults keeps former values... not good 
		# CALL l_crs_customer.fetchNext(l_rec_customer.*)	# LIKE fetch into ...
		DISPLAY l_rec_customer.cmpy_code,l_rec_customer.cust_code,l_rec_customer.name_text
	END IF
	CALL l_crs_customer.Close()
	CALL l_crs_customer.Free() 
END FUNCTION # cursor_with_placeholders

FUNCTION update_with_placeholders ()			
# singleton with no cursor
# replicates the ESQL/C PREPARE SELECT / EXECUTE INTO , i.e no need to declare a cursor for a singleton
# nevertheless, either this way of doing is not expected, or SetResults does not work as expected
# => this does not work
	DEFINE l_cust_code LIKE customer.cust_code
	DEFINE l_cmpy_code LIKE customer.cmpy_code
	DEFINE l_name_text LIKE customer.name_text	
	DEFINE l_prp_customer PREPARED

	LET l_cust_code = fgl_winprompt(10,10,"Please enter a New customer code",NULL,10,0)
	LET l_name_text = fgl_winprompt(10,10,"Please enter a new name for customer",NULL,10,0)
	LET m_sql_statement = "UPDATE customer SET name_text = ? WHERE cmpy_code = ? AND cust_code = ?"
	CALL l_prp_customer.Prepare(m_sql_statement)
	
	# Get rid of SetParameters
	# CALL l_prp_customer.SetParameters(m_cmpy_code,l_cust_code)
	
	# How we would like to have the execute method below
	# do the execute with the new syntax below, bound values become arguments of the execute method
	CALL l_prp_customer.Execute(l_name_text,l_cmpy_code,l_cust_code)
	IF sqlca.sqlcode = 0 THEN
		MESSAGE "UPDATE OK"
	ELSE						# the engine receives the correct query and executes OK
		ERROR "UPDATE Not OK"
	END IF
	CALL l_prp_customer.Free() 
END FUNCTION # singleton_select_with_placeholders

FUNCTION cursor_with_placeholders_fetch_into_values ()
	# singleton (returns only one value) query with place holders. 
	# uses a cursor Directly declared from the query statement variable
	DEFINE l_cust_code LIKE customer.cust_code
	DEFINE l_crs_customer CURSOR
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_sql_statement STRING

	LET l_cust_code = fgl_winprompt(10,10,"Please enter customer code",NULL,10,0)
	LET l_sql_statement = "SELECT * FROM customer WHERE cmpy_code = ? AND cust_code = ?"
	CALL l_crs_customer.declare(l_sql_statement)
	CALL l_crs_customer.open(m_cmpy_code,l_cust_code)	
	
	# How I would like to use fetchnext returning the data
	CALL l_crs_customer.fetchNext() RETURNING l_rec_customer.*
	IF sqlca.sqlcode = NOTFOUND THEN
		ERROR "Did not find this client ",m_cmpy_code," ",l_cust_code
	ELSE
		DISPLAY l_rec_customer.cmpy_code,l_rec_customer.cust_code,l_rec_customer.name_text
	END IF
	CALL l_crs_customer.Close()
	CALL l_crs_customer.Free() 
END FUNCTION # end cursor_with_placeholders_fetch_into_values

FUNCTION temptative_fetchall_into_array()
# Here I am dreaming, but some languages (php, perl and java AFAIK) do this: in one command, (foreach), fills in the array
DEFINE l_crs_customer CURSOR
DEFINE l_sql_statement STRING
DEFINE l_cust_array DYNAMIC ARRAY OF RECORD LIKE customer.*
	# LET l_sql_statement = "SELECT * FROM customer ORDER BY city"
	LET l_sql_statement = "SELECT * FROM customer ORDER BY city_text"
	WHENEVER ERROR CONTINUE
	CALL l_crs_customer.declare(l_sql_statement) 		# declare with wrong column name should give an error

	CALL l_crs_customer.open()							#  
	
	# not possible to compile this syntax yet because the method does not exist
	# showing the syntax though
	# CALL l_crs_customer.FetchAll() RETURNING l_cust_array	# fetchall would return all the rows caught by the cursor
	
	DISPLAY l_cust_array[1].cmpy_code,l_cust_array[1].cust_code,l_cust_array[1].name_text
	CALL l_crs_customer.close()
	CALL l_crs_customer.free()	
	 
END FUNCTION # no_whereclause_into_array