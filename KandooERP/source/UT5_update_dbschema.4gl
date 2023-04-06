--database kandoodb
GLOBALS "4gl/common/glob_DATABASE.4gl" 
DEFINE r_column_doc RECORD LIKE column_documentation.*
DEFINE r_table_doc RECORD LIKE table_documentation.*
DEFINE r_form_attributes RECORD LIKE form_attributes.*
DEFINE r_attributes_translation RECORD LIKE attributes_translation.*
DEFINE former_key,current_key,qry_stmt STRING
DEFINE a,total_MESSAGEs INTEGER

MAIN

	#Initial UI Init
	CALL setModuleId("UT5")
	CALL ui_init(0)		#Initial UI Init

	DEFER QUIT
	DEFER INTERRUPT

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module


	DECLARE crs_form_attributes CURSOR FOR
		SELECT f.table_name,f.widget_id,t.translation,t.language,t.modif_timestamp
        FROM form_attributes f,attributes_translation t
        WHERE t.attribute_id = f.attribute_id
           AND table_name IS NOT NULL
           AND lower(table_name) NOT MATCHES "formonly"
           AND f.attribute_type = "comment"
           AND t.language = "ENU"
        GROUP BY 1,2,3,4,5
        ORDER BY 1,2,3

	LET qry_stmt = "UPDATE column_documentation SET (documentation,mtime) = (?,?) WHERE tabname = ? and colname = ? and language_code = ?"
	PREPARE upd_stmt from qry_stmt
	
	LET former_key = "xxxxxxxxx"		
	FOREACH  crs_form_attributes 
	INTO r_form_attributes.table_name,r_form_attributes.widget_id,
	r_attributes_translation.translation,r_attributes_translation.language,r_attributes_translation.modif_timestamp
		LET current_key = r_form_attributes.table_name CLIPPED,":",r_form_attributes.widget_id
		IF current_key = former_key THEN
			CONTINUE FOREACH
		ELSE
			LET former_key = current_key
		END IF
		CALL util.REGEX.replace(r_attributes_translation.translation,/^\s+|^\s*Enter /i,"") returning r_column_doc.documentation
		LET r_column_doc.tabname = r_form_attributes.table_name
		LET r_column_doc.colname = r_form_attributes.widget_id
		LET r_column_doc.language_code = r_attributes_translation.language
		LET r_column_doc.mtime = r_attributes_translation.modif_timestamp
		
		DISPLAY r_column_doc.*
		EXECUTE upd_stmt USING r_column_doc.documentation,r_column_doc.tabname,r_column_doc.colname,r_column_doc.language_code,r_column_doc.mtime
		LET total_MESSAGEs = total_MESSAGEs + 1
		LET a=1 
	END FOREACH
	DISPLAY "TOtal MESSAGEs: ",total_MESSAGEs
END MAIN
		
