############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

###################################################################
# FUNCTION getMenuItemLabel(p_moduleid)
# Returns the module title/label - TO be used for the form title AND the mdi menu
# argument IS the module/program name
###################################################################
FUNCTION getmenuitemlabel(p_moduleid) 
	DEFINE p_moduleid VARCHAR(5) 
	DEFINE l_ret_prognamelabel VARCHAR(30) 
	DEFINE qry_string VARCHAR(200) 

	#Note: The same program can exist multiple times in the menu
	# We don't care, which menu label we will get
	# DISTINCT does NOT work in this CASE...

	LET qry_string = "SELECT qxt_menu_item_txt.mb_label ", 
	" FROM qxt_menu_item, qxt_menu_item_txt ", 
	" WHERE qxt_menu_item.r_command = ? ", 
	" AND qxt_menu_item.mb_id = qxt_menu_item_txt.mb_id" 

	PREPARE p_my_query FROM qry_string 
	DECLARE crs_my_query CURSOR FOR p_my_query 

	IF p_moduleid IS NULL THEN
		LET p_moduleid = getmoduleid()
	END IF
	
	OPEN crs_my_query USING p_moduleid	 
	FETCH crs_my_query INTO l_ret_prognamelabel 

	RETURN l_ret_prognamelabel 

END FUNCTION 


###################################################################
# FUNCTION getmenuitemlabels(pprogname)
#
#
###################################################################
FUNCTION getmenuitemlabels(pprogname) 
	DEFINE pprogname VARCHAR(4) 
	DEFINE lprognamelabel VARCHAR(30) 
	DEFINE qry_string VARCHAR(200) 
	DEFINE l_cursor_menuitem CURSOR 
	DEFINE err_code STRING 
	DEFINE larr_prognamelabel DYNAMIC ARRAY OF VARCHAR(30) 
	DEFINE i SMALLINT 

	#Note: The same program can exist multiple times in the menu
	# We don't care, which menu label we will get
	# DISTINCT does NOT work in this CASE...

	LET qry_string = "SELECT qxt_menu_item_txt.mb_label ", 
	" FROM qxt_menu_item, qxt_menu_item_txt ", 
	" WHERE qxt_menu_item.r_command = ? ", 
	" AND qxt_menu_item.mb_id = qxt_menu_item_txt.mb_id" 

	CALL l_cursor_menuitem.declare(qry_string,1) RETURNING err_code 
	CALL l_cursor_menuitem.setresults(lprognamelabel) 
	CALL l_cursor_menuitem.setparameters(pprogname) -- setting the parameter FOR the placeholder 
	CALL l_cursor_menuitem.open() 

	LET i = 1 
	WHILE l_cursor_menuitem.fetchnext() = 0 
		#DISPLAY "lProgNameLabel=", lProgNameLabel
		LET larr_prognamelabel[i] = lprognamelabel 
		LET i = i+1 
	END WHILE 
	LET i = i-1 

	RETURN larr_prognamelabel 
END FUNCTION 






###################################################################
# FUNCTION getMenuItemName(pProgNameLabel)
# Returns the module/program base name - useful for user feedback (I select AP-> xxx -> "New Invoice"
# argument IS the module/program title/label
###################################################################

FUNCTION getmenuitemprogramname(pprognamelabel) 
	DEFINE pprognamelabel VARCHAR(30) 
	DEFINE retprogname VARCHAR(4) 
	DEFINE qry_string VARCHAR(200) 

	#Note: The same program can exist multiple times in the menu
	# We don't care, which menu label we will get
	# DISTINCT does NOT work in this CASE...

	LET qry_string = 
	"SELECT qxt_menu_item.r_command ", 
	"FROM qxt_menu_item, qxt_menu_item_txt ", 
	"WHERE qxt_menu_item.mb_id = qxt_menu_item_txt.mb_id ", 
	"AND qxt_menu_item_txt.mb_label = ? " 

	PREPARE p_my_query2 FROM qry_string 
	DECLARE crs_my_query2 CURSOR FOR p_my_query2 

	OPEN crs_my_query2 USING pprognamelabel 
	FETCH crs_my_query2 INTO retprogname 

	RETURN retprogname 

END FUNCTION 



###################################################################
# FUNCTION getMenuItemName(pProgNameLabel)
# Returns the module/program base name - useful for user feedback (I select AP-> xxx -> "New Invoice"
# argument IS the module/program title/label
###################################################################

FUNCTION getmenuitemprogramfilenames(pprognamelabel) 
	DEFINE lprogfilename VARCHAR(4) 
	DEFINE pprognamelabel VARCHAR(30) 
	DEFINE qry_string VARCHAR(200) 
	DEFINE larr_progfilename DYNAMIC ARRAY OF VARCHAR(30) 
	DEFINE l_cursor_menuitem CURSOR 
	DEFINE err_code STRING 
	DEFINE i SMALLINT 


	#Note: The same program can exist multiple times in the menu
	# We don't care, which menu label we will get
	# DISTINCT does NOT work in this CASE...

	LET qry_string = 
	"SELECT qxt_menu_item.r_command ", 
	"FROM qxt_menu_item, qxt_menu_item_txt ", 
	"WHERE qxt_menu_item.mb_id = qxt_menu_item_txt.mb_id ", 
	"AND qxt_menu_item_txt.mb_label = ? " 

	CALL l_cursor_menuitem.declare(qry_string,1) RETURNING err_code 
	CALL l_cursor_menuitem.setresults(lprogfilename) 
	CALL l_cursor_menuitem.setparameters(pprognamelabel) -- setting the parameter FOR the placeholder 
	CALL l_cursor_menuitem.open() 

	LET i = 1 
	WHILE l_cursor_menuitem.fetchnext() = 0 
		DISPLAY "pProgNameLabel=", pprognamelabel 
		LET larr_progfilename[i] = lprogfilename 
		LET i = i+1 
	END WHILE 
	LET i = i-1 

	RETURN larr_progfilename 

END FUNCTION 

