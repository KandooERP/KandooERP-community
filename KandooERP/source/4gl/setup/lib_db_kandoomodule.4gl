{
GLOBALS "lib_db_globals.4gl"

FUNCTION libkandoomoduleLoadAdministrator()
	#DEFINE p_cmpy_code LIKE kandoomodule.cmpy_code
	#DEFINE p_user_code LIKE kandoomodule.user_code
	DEFINE entryCheck SMALLINT
	
	SELECT COUNT(*) INTO entryCheck FROM kandoomodule 
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
     
	IF entryCheck = 0 THEN --lazy approach
	
		WHENEVER ERROR CONTINUE 
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"A","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"B","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"C","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"D","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"E","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"F","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"G","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"H","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"I","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"J","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"K","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"L","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"M","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"N","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"O","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"P","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"Q","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"R","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"S","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"T","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"U","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"V","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"W","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"X","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"Y","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"Z","Z")
		WHENEVER ERROR STOP
	END IF
END FUNCTION


FUNCTION libkandoomoduleLoadDemoUsers()
	CALL libkandoomoduleLoadDemoUser("HuHo")
	CALL libkandoomoduleLoadDemoUser("AlAf")
	CALL libkandoomoduleLoadDemoUser("MeAf")
	CALL libkandoomoduleLoadDemoUser("ErVe")
	CALL libkandoomoduleLoadDemoUser("ElSv")
	CALL libkandoomoduleLoadDemoUser("AlCh")
	CALL libkandoomoduleLoadDemoUser("APAf")
	CALL libkandoomoduleLoadDemoUser("ViAk")
	CALL libkandoomoduleLoadDemoUser("NiTo")
	CALL libkandoomoduleLoadDemoUser("Guest")

END FUNCTION

FUNCTION libkandoomoduleLoadDemoUser(p_user_code)
	#DEFINE p_cmpy_code LIKE kandoomodule.cmpy_code
	DEFINE p_user_code LIKE kandoomodule.user_code
	DEFINE entryCheck SMALLINT
	
	SELECT COUNT(*) INTO entryCheck FROM kandoomodule 
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	AND user_code = p_user_code
     
	IF entryCheck = 0 THEN --lazy approach
	
		WHENEVER ERROR CONTINUE 
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"A","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"B","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"C","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"D","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"E","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"F","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"G","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"H","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"I","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"J","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"K","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"L","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"M","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"N","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"O","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"P","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"Q","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"R","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"S","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"T","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"U","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"V","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"W","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"X","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"Y","Z")
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,p_user_code,"Z","Z")
		WHENEVER ERROR STOP
	END IF
END FUNCTION
}