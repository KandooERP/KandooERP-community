GLOBALS "lib_db_globals.4gl"

#Note: We only offer 3 OPTIONS
# create table with one record 
# delete-create table with one record
# view table


MAIN
	#DEFINE gl_setupRec_default_company_orig RECORD LIKE company.*
	DEFINE recClipboard RECORD LIKE clipboard.*

MENU

	ON ACTION "Create Table"
		CALL create_table_clipboard()

	ON ACTION "Drop Table"
		CALL drop_table_clipboard()
		
	ON ACTION "Add User"
		LET recClipboard.sign_on_code = fgl_winprompt(1,1,"Specify User Code","",8,0)
		INSERT INTO clipboard VALUES(recClipboard.*)
		
	ON ACTION "Exit"
		EXIT MENU
		
END MENU


END MAIN