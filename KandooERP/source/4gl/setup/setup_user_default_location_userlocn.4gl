GLOBALS "lib_db_globals.4gl"

###############################################################
# FUNCTION addUserDefaultLocation()
# take the specified location of the admin user 
# AND stores it as the user default location
#
# PS: Not sure for what this userlocn table IS used yet.. but it IS processed by the app
###############################################################
FUNCTION addUserDefaultLocation()
	DEFINE recCount SMALLINT
	
	SELECT COUNT(*) INTO recCount FROM userlocn
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	AND sign_on_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
	AND locn_code = "DEF"
	
	IF recCount = 0 THEN
		INSERT INTO userlocn VALUES (gl_setupRec_default_company.cmpy_code,gl_setupRec_admin_rec_kandoouser.sign_on_code,"DEF")
	END IF
END FUNCTION

###############################################################
# FUNCTION addDefaultLocation()
# take the specified location of the admin user 
# AND stores it in the location table
###############################################################
FUNCTION addDefaultLocation()
	DEFINE recLocation RECORD LIKE location.*
	DEFINE recCount SMALLINT
		
	LET recLocation.cmpy_code = gl_setupRec_default_company.cmpy_code
	LET recLocation.locn_code = "DEF"
	LET recLocation.desc_text =	"Default Location"
	LET recLocation.addr1_text = gl_setupRec_default_company.addr1_text
	LET recLocation.addr2_text = gl_setupRec_default_company.addr2_text
	LET recLocation.city_text = gl_setupRec_default_company.city_text
	LET recLocation.state_code = gl_setupRec_default_company.state_code
	LET recLocation.post_code = gl_setupRec_default_company.post_code
	LET recLocation.country_code = gl_setupRec_default_company.country_code
	LET recLocation.tele_text = gl_setupRec_default_company.tele_text
	LET recLocation.fax_text = gl_setupRec_default_company.fax_text
	#LET recLocation.bank_code = gl_setupRec_default_company.bank_code


	SELECT COUNT(*) INTO recCount FROM location 
	WHERE recLocation.cmpy_code = gl_setupRec_default_company.cmpy_code
	AND recLocation.locn_code = "DEF"
	
	IF recCount = 0 THEN
		INSERT INTO location VALUES(recLocation.*)
	END IF 

END FUNCTION


