GLOBALS "lib_db_globals.4gl"

FUNCTION insertkandoousercmpy() 

	DEFINE cnt_kandoousercmpy SMALLINT
	
	IF (gl_setupRec_admin_rec_kandoouser.sign_on_code OR gl_setupRec_default_company.cmpy_code) IS NULL THEN
		CALL fgl_winmessage("User OR Company NOT specified","insertkandoousercmpy()\nUser OR Company NOT specified for acct_mask_code","error")
		RETURN -1
	END IF
	
#	IF gl_setupRec_admin_rec_kandoouser.acct_mask_code IS NULL THEN
#		CALL fgl_winmessage("p_gl_access AND p_acct_mask_code NOT specified","insertkandoousercmpy()\np_acct_mask_code AND p_gl_access NOT specified for acct_mask_code\nYou need one of the 2","error")
#		RETURN -1
#	END IF		
{
	IF gl_setupRec_admin_rec_kandoouser.acct_mask_code IS NULL THEN
		CASE gl_kandooprofile.access_code
			WHEN 1 
				LET gl_setupRec_admin_rec_kandoouser.acct_mask_code = "????"
			WHEN 2 
				LET gl_setupRec_admin_rec_kandoouser.acct_mask_code = "??.????"
			WHEN 3 
				LET gl_setupRec_admin_rec_kandoouser.acct_mask_code = "??.???.????"
			OTHERWISE
				CALL fgl_winmessage("Invalid argument for gl_setupRec.access","Invalid argument for gl_setupRec.access\nError","ERROR")
				RETURN -1
		END CASE		
				 
	END IF
}
	SELECT COUNT(*) INTO cnt_kandoousercmpy 
		FROM kandoousercmpy 
		WHERE sign_on_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND cmpy_code = gl_setupRec_default_company.cmpy_code
		
	IF cnt_kandoousercmpy = 0 THEN 	
		INSERT INTO kandoousercmpy VALUES(
			gl_setupRec_admin_rec_kandoouser.sign_on_code, 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)
	END IF
	
END FUNCTION