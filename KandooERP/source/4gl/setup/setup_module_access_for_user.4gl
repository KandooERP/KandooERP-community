GLOBALS "lib_db_globals.4gl"

# Note: Each user must have a configuration in the kandoomodule table
# which defines, what modules the user IS allowed TO use
# AND TO what extend (security level)
# Setup only installs the Admin user - so, ACCESS will be "Z" (highest level)

#####################################################
# FUNCTION setUserkandoomoduleEntries()      
#####################################################
FUNCTION setUserkandoomoduleEntries()
	DEFINE rowCount SMALLINT
	DEFINE l_module_code CHAR

	LET l_module_code = "A"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF
	LET rowCount = 0


	LET l_module_code = "C"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0

	LET l_module_code = "E"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "F"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF



#-------------------------
	LET rowCount = 0
	LET l_module_code = "G"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF



#-------------------------
	LET rowCount = 0
	LET l_module_code = "I"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "J"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "K"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "L"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "M"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "N"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF




#-------------------------
	LET rowCount = 0
	LET l_module_code = "P"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF



#-------------------------
	LET rowCount = 0
	LET l_module_code = "Q"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF



#-------------------------
	LET rowCount = 0
	LET l_module_code = "R"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF




#-------------------------
	LET rowCount = 0
	LET l_module_code = "T"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF


#-------------------------
	LET rowCount = 0
	LET l_module_code = "U"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF




#-------------------------
	LET rowCount = 0
	LET l_module_code = "W"
	SELECT COUNT(*) 
		INTO rowCount
		FROM kandoomodule
		WHERE cmpy_code = gl_setupRec_default_company.cmpy_code 
		AND user_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
		AND module_code = l_module_code
	
	IF rowCount = 0 THEN
		INSERT INTO kandoomodule VALUES(gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,l_module_code,"Z")
	END IF

END FUNCTION


