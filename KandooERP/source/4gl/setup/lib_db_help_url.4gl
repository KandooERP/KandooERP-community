GLOBALS "lib_db_globals.4gl"

FUNCTION import_help_url()
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	

	
	LET load_file = "unl/qxt_help_page-",gl_setupRec_default_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The Help Context PAGE URL file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Group Info Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		WHENEVER ERROR CONTINUE
		LOAD FROM load_file INSERT INTO qxt_help_page
		WHENEVER ERROR STOP

	END IF
	

	LET load_file = "unl/qxt_help_fragment-",gl_setupRec_default_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The Help Context ELEMENT URL file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Group Info Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		WHENEVER ERROR CONTINUE		
		LOAD FROM load_file INSERT INTO qxt_help_fragment
		WHENEVER ERROR STOP		
	END IF
	
	
	
END FUNCTION


FUNCTION create_qxt_help_tables() 
	WHENEVER ERROR CONTINUE
	
	DROP TABLE qxt_help_fragment
	DROP TABLE qxt_help_page

# An optional fragment, separated FROM the preceding part by a hash (#). 
# The fragment contains a fragment identifier providing direction TO a 
# secondary resource, such as a section heading in an article identified 
# by the remainder of the URI. When the primary resource IS an HTML document, 
# the fragment IS often an id attribute of a specific element, 
# AND web browsers will scroll this element INTO view.
  CREATE TABLE qxt_help_fragment
  (
   hlp_page_Id VARCHAR(4),
   hlp_fragment_id     VARCHAR(10),
   hlp_fragment_text   VARCHAR(200),         
   PRIMARY KEY (hlp_page_Id,hlp_fragment_id) 
  )

	CREATE TABLE  qxt_help_page
		(
		hlp_pageId VARCHAR(4),
		hlp_baseFolderID1 VARCHAR(20),
		hlp_baseFolderID2 VARCHAR(20),
		hlp_pagePath VARCHAR(200),
   	PRIMARY KEY (hlp_pageId)
		)

WHENEVER ERROR STOP
END FUNCTION