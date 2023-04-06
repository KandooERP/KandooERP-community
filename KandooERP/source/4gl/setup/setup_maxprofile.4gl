GLOBALS "lib_db_globals.4gl"

###############################################################
# FUNCTION addkandooprofile()
# write kandooprofile TO DB
###############################################################
FUNCTION addkandooprofile()
	DEFINE recCount SMALLINT
	
	LET gl_setupRec_kandooprofile.cmpy_code = gl_setupRec_default_company.cmpy_code
	LET gl_setupRec_kandooprofile.profile_code = gl_setupRec_default_company.cmpy_code  #use company code as the default profile code
	LET gl_setupRec_kandooprofile.profile_text = trim(gl_setupRec_default_company.cmpy_code), " - Default Profile" 
	LET gl_setupRec_kandooprofile.access_ind = "2"  --no idea - have TO investigate what value it needs AND what it's meaning IS 
	LET gl_setupRec_kandooprofile.acct_mask_code = gl_setupRec_admin_rec_kandoouser.acct_mask_code #specified in setup 
	LET gl_setupRec_kandooprofile.acct_access_code = "" #no idea CHAR(18)
	LET gl_setupRec_kandooprofile.quote_print_text = "" 
	LET gl_setupRec_kandooprofile.order_print_text =  ""
	LET gl_setupRec_kandooprofile.inv_print_text =  ""
	LET gl_setupRec_kandooprofile.order_print_text =  ""
	LET gl_setupRec_kandooprofile.chq_print_text =  ""
	

	
	SELECT COUNT(*) INTO recCount FROM kandooprofile
	WHERE cmpy_code = gl_setupRec_kandooprofile.cmpy_code
	AND profile_code = gl_setupRec_kandooprofile.profile_code
 
	IF recCount = 0 THEN
		INSERT INTO kandooprofile VALUES(gl_setupRec_kandooprofile.*)
	END IF

END FUNCTION
