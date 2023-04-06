GLOBALS "lib_db_globals.4gl"


#######################################################
# FUNCTION kandoouserInstall()
#######################################################
FUNCTION kandoouserInstall()
	DEFINE rkandoouser RECORD LIKE kandoouser.*
	DEFINE countkandoouser SMALLINT

		#NOTE: We need TO check if an administrator account already exists
		#Outstanding Task

	LET rkandoouser.sign_on_code = gl_setupRec_admin_rec_kandoouser.sign_on_code --"Admin"
	LET rkandoouser.name_text = gl_setupRec_admin_rec_kandoouser.name_text --"Kandoo Administrator"
	LET rkandoouser.cmpy_code = gl_setupRec_default_company.cmpy_code

	LET rkandoouser.language_code = gl_setupRec_default_company.language_code  --"ENG"
	LET rkandoouser.sign_on_date = CURRENT
	LET rkandoouser.security_ind = "Z"		
	LET rkandoouser.passwd_ind = 1		
	LET rkandoouser.access_ind = "1"	--possible VALUES 1,2,3 --no user documentation - states, this IS NOT used yet
	LET rkandoouser.profile_code = "MAX"
	LET rkandoouser.acct_mask_code = gl_setupRec_admin_rec_kandoouser.acct_mask_code
		
#check if record already exists (happens if the user navigates back/previous)
	SELECT COUNT(*) INTO countkandoouser FROM temp_rec_kandoouser
	#if exists, load the data
	IF countkandoouser = 1 THEN
		SELECT * INTO rkandoouser.* FROM temp_rec_kandoouser WHERE sign_on_code = gl_setupRec_admin_rec_kandoouser.sign_on_code
	END IF

	
	OPEN WINDOW kandoouser WITH FORM "per/setup/setup_admin" 
	CALL updateConsole()

	DISPLAY BY NAME rkandoouser.sign_on_code
	DISPLAY BY NAME rkandoouser.name_text

	INPUT BY NAME rkandoouser.password_text, rkandoouser.email WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		ON ACTION CANCEL
			CALL interrupt_installation()

		ON ACTION "Previous"
			LET mdNavigatePrevious = TRUE
			EXIT INPUT	
			
	END INPUT
	CLOSE WINDOW kandoouser

	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
		#check if it exists
	#check if record already exists (happens if the user navigates back/previous)
		#LET gl_setupRec_admin_rec_kandoouser.sign_on_code = rkandoouser.sign_on_code
		#Does any record exist ?
		SELECT COUNT(*) INTO countkandoouser FROM temp_rec_kandoouser
		IF countkandoouser <> 0 THEN
			DELETE FROM temp_rec_kandoouser
		END IF
		#Write latest company setup data TO temp table
		INSERT INTO temp_rec_kandoouser VALUES(rkandoouser.*)
	
		IF mdNavigatePrevious THEN
			LET step_num = step_num - 1
			LET mdNavigatePrevious = FALSE
		ELSE
			LET step_num = step_num + 1
		END IF
	END IF


		RETURN rkandoouser.sign_on_code
END FUNCTION 

