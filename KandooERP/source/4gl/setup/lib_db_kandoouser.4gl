GLOBALS "lib_db_globals.4gl"

FUNCTION exist_user(usr_code)
	DEFINE usr_code LIKE kandoouser.sign_on_code
	DEFINE usr_cnt INTEGER
		SELECT COUNT(*) INTO usr_cnt FROM kandoouser WHERE sign_on_code MATCHES usr_code
		RETURN usr_cnt
END FUNCTION


FUNCTION addDemoUser()
	DEFINE l_companyCode LIKE company.cmpy_code   
	
	LET l_companyCode = getCurrentUser_cmpy_code()


	INSERT INTO kandoouser VALUES(
	"JoSm","John Smith","U", "JoSm", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",
	0,0,"","",1,"",
	"j.smith@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"JoSm", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)

		INSERT INTO userlocn VALUES(
			"JoSm",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

-------------------------------------


	INSERT INTO kandoouser VALUES(
	
	"BrWi","Brian Williams","U", "BrWi", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"b.williams@kandooerp.org"
	)
		INSERT INTO kandoousercmpy VALUES(
			"BrWi", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"BrWi",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

----------------------------------------------

	INSERT INTO kandoouser VALUES(
	
	"MiBa","Mike Banger","U", "MiBa", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"m.banger@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"MiBa", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)

		INSERT INTO userlocn VALUES(
			"MiBa",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

-------------------------------------------------

	INSERT INTO kandoouser VALUES(
	
	"HuHo","Henry Holgate","U", "HuHo", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"h.holgate@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"HuHo", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"HuHo",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------------------

	INSERT INTO kandoouser VALUES(
	"AlAf","Adrian Adams","U", "AlAf", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"a.adams@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"AlAf", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"AlAf",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"MeAf","Martin Anderson","U", "MeAf", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"m.anderson@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"MeAf", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"MeAf",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"ErVe","Eric Vercelletto","U", "ErVe", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"e.vercelletto@kandooerp.org"
	)


		INSERT INTO kandoousercmpy VALUES(
			"ErVe", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"ErVe",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"AlPr","Alexa Princess","U", "AlPr", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"a.princess@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"AlPr", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"AlPr",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		


	INSERT INTO kandoouser VALUES(

	"ElSv","Elton Swanka","U", "ElSv", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"e.swanka@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"ElSv", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"ElSv",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"AlCh","Alexander Chive","U", "AlCh", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"a.chive@kandooerp.org"
	)


		INSERT INTO kandoousercmpy VALUES(
			"AlCh", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"AlCh",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"ViAk","Vitaliy Aktora","U", "ViAk", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"v.aktora@kandooerp.org"
	)


		INSERT INTO kandoousercmpy VALUES(
			"ViAk", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"ViAk",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		


	INSERT INTO kandoouser VALUES(

	"NiTo","Nima Toores","U", "NiTo", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"n.toores@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"NiTo", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"NiTo",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)

---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"AnBl","Anna Bliznetsova","A", "AnBl", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"a.bliznetsova@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"AnBl", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"AnBl",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)
---------------------------------------		

	INSERT INTO kandoouser VALUES(

	"Guest","Guest","A", "Guest", 
	"ENG",l_companyCode,"????","MAX", 
	1, gl_setupRec.fiscal_startDate,"PRINT-DEVICE-01",0,0,"","",1,"",
	"guest@kandooerp.org"
	)

		INSERT INTO kandoousercmpy VALUES(
			"Guest", 
			gl_setupRec_default_company.cmpy_code, 
			gl_setupRec_admin_rec_kandoouser.acct_mask_code
		)


		INSERT INTO userlocn VALUES(
			"Guest",
			gl_setupRec_admin_rec_kandoouser.acct_mask_code,
			"DEF"
		)
---------------------------------------		


END FUNCTION

#########################################################################
# Create an online demo user account
# This can be called FROM the webSite / published-available as a Webservice
#########################################################################
FUNCTION addOnlineDemoUser(pUserId,pUserName,pUserPw,pCompanyCode,pSign_on_date,pEmailAddress)
	DEFINE l_companyCode LIKE company.cmpy_code   
	DEFINE pUserId LIKE kandoouser.sign_on_code
	DEFINE pUserName LIKE kandoouser.name_text
	DEFINE pUserPw LIKE kandoouser.password_text
	DEFINE pCompanyCode LIKE kandoouser.cmpy_code
	DEFINE pSign_on_date LIKE kandoouser.sign_on_date
	DEFINE pEmailAddress LIKE kandoouser.email


	IF (pUserId IS NULL) THEN
		ERROR "UserID must NOT be empty/NULL"
		RETURN -1
	END IF
	
	IF exist_user(pUserId) > 0 THEN
		ERROR "UserId ", trim(pUserId), " already exists"
		RETURN -2
	END IF
	
	IF pUserName IS NULL THEN
		ERROR "UserName must NOT be empty/NULL"
		RETURN -3
	END IF

	IF pUserPw IS NULL THEN
		ERROR "Password must NOT be empty/NULL"
		RETURN -4
	END IF


	IF length(pUserPw) < 4 THEN
		ERROR "Password must be at least 4 characters long"
		RETURN -5
	END IF
	
	IF (pCompanyCode IS NULL) THEN
		ERROR "CompanyCode must NOT be empty/NULL"
		RETURN -6
	END IF	

	IF NOT db_company_pk_exists(UI_OFF,pCompanyCode) THEN
	#IF exist_company(pCompanyCode) = 0 THEN
		ERROR "CompanyCode ", trim(pCompanyCode), " does NOT exist"
		RETURN -7	
	END IF
	
	IF pSign_on_date IS NULL THEN
		LET pSign_on_date = TODAY
	END IF
	
		IF (pEmailAddress IS NULL) THEN
		ERROR "EmailAddress must NOT be empty/NULL"
		RETURN -8
	END IF	
	
	call fgl_winmessage("needs fixing","uses ??.???? for account code mask by default","error")
	INSERT INTO kandoouser VALUES
		(
			pUserId,pUserName,"U", pUserPw, "ENG",pCompanyCode,"??.????","MAX",1, pSign_on_date,"",0,0,"","",1,"",pEmailAddress
		)
		
	IF sqlca.sqlcode = 0 THEN
		MESSAGE "User Acccount created"
		RETURN 0
	ELSE
		ERROR "User Account could NOT be created (DB/SQL Error)"
		RETURN sqlca.sqlcode 
	END IF
		
END FUNCTION

{
FUNCTION setupAdministratorAccount()
   DEFINE
       fv_cmpy_code LIKE company.cmpy_code

   OPEN WINDOW U101 WITH FORM "U101"
   CALL winDecoration_u("U101") 
      
   LET msgresp = kandoomsg("U", 1053, "")
   #1053 Enter User Details; OK TO Continue 
   LET pr_rec_kandoouser.sign_on_code = "administrator"
   LET pr_rec_kandoouser.name_text = "Administrator"
   LET pr_rec_kandoouser.security_ind = "9"
   LET pr_rec_kandoouser.password_text = NULL
   #LET pr_rec_kandoouser.cmpy_code = cmpy 
   LET pr_rec_kandoouser.profile_code = "MAX"
   LET pr_rec_kandoouser.language_code = "ENG"
   LET pr_rec_kandoouser.access_ind = "1"
   LET pr_rec_kandoouser.print_text = NULL
   LET pr_rec_kandoouser.acct_mask_code = NULL
   LET pr_userlocn.locn_code = NULL
   LET pr_rec_kandoouser.sign_on_date = NULL
   LET pr_rec_kandoouser.passwd_ind = "2"
   LET pr_rec_kandoouser.signature_text = NULL
   LET pr_rec_kandoouser.group_code = NULL
   LET pr_rec_kandoouser.memo_pri_ind = "1"
   LET pr_rec_kandoouser.email = NULL
   SELECT * INTO pr_company.* FROM company
    WHERE cmpy_code = pr_rec_kandoouser.cmpy_code
   SELECT * INTO pr_kandooprofile.* FROM kandooprofile
    WHERE cmpy_code = pr_rec_kandoouser.cmpy_code
      AND profile_code = pr_rec_kandoouser.profile_code
   SELECT * INTO pr_language.* FROM language
    WHERE language_code = pr_rec_kandoouser.language_code
   SELECT * INTO pr_userlocn.* FROM userlocn
    WHERE sign_on_code = pr_rec_kandoouser.sign_on_code
    AND cmpy_code = pr_rec_kandoouser.cmpy_code   DISPLAY pr_company.name_text
        TO company.name_text 
        
   DISPLAY BY NAME pr_kandooprofile.profile_text,
                   pr_language.language_text 
     
   INPUT BY NAME pr_rec_kandoouser.sign_on_code,
                 pr_rec_kandoouser.name_text,
                 pr_rec_kandoouser.security_ind,
                 pr_rec_kandoouser.passwd_ind,
                 pr_rec_kandoouser.password_text,
                 pr_rec_kandoouser.group_code,
                 pr_rec_kandoouser.signature_text,
                 pr_rec_kandoouser.cmpy_code,
                 pr_rec_kandoouser.profile_code,
                 pr_rec_kandoouser.language_code,
                 pr_rec_kandoouser.memo_pri_ind,
                 pr_rec_kandoouser.access_ind,
                 pr_rec_kandoouser.print_text,
                 pr_rec_kandoouser.acct_mask_code,
                 pr_rec_kandoouser.email WITHOUT DEFAULTS
		BEFORE INPUT
		  CALL publish_toolbar("kandoo","U12","input-kandoouser-1") 
		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()

      AFTER FIELD sign_on_code
         IF pr_rec_kandoouser.sign_on_code IS NULL THEN
            LET msgresp = kandoomsg("U", 9102, "")
            #9102 Value Must be Entered 
         END IF
         SELECT count(*) INTO cnt FROM kandoouser
          WHERE sign_on_code = pr_rec_kandoouser.sign_on_code
         IF cnt != 0 THEN
            LET msgresp = kandoomsg("U",9104,"")
            #9104 Already exists
            NEXT FIELD sign_on_code
         END IF
      AFTER FIELD name_text
         IF pr_rec_kandoouser.name_text IS NULL THEN
            LET msgresp = kandoomsg("U", 9102, "")
            #9102 Value Must be Entered 
            NEXT FIELD name_text
         END IF
      AFTER FIELD security_ind
         IF pr_rec_kandoouser.security_ind IS NULL THEN
            LET msgresp = kandoomsg("U", 9102, "")
            #9102 Value Must be Entered 
            NEXT FIELD security_ind
         END IF
         IF pr_rec_kandoouser.security_ind NOT matches "[1-9,A-Z,a-z]" THEN
            LET msgresp = kandoomsg("U",9026,"")
            NEXT FIELD security_ind
         END IF
      AFTER FIELD passwd_ind
         IF pr_rec_kandoouser.passwd_ind NOT matches "[0,1,2]" THEN
            LET msgresp = kandoomsg("A",9075,"")
            NEXT FIELD passwd_ind
         END IF
         IF pr_rec_kandoouser.passwd_ind IS NULL THEN
            LET msgresp = kandoomsg("U", 9102, "")
            #9102 Value Must be Entered 
            NEXT FIELD passwd_ind
         END IF
         IF pr_rec_kandoouser.passwd_ind = "1" THEN              
            NEXT FIELD password_text                      
         ELSE                                             
            NEXT FIELD group_code                         
         END IF                                           
      AFTER FIELD cmpy_code
         SELECT * INTO pr_company.* FROM company
          WHERE cmpy_code = pr_rec_kandoouser.cmpy_code
         IF STATUS = NOTFOUND THEN
            LET msgresp = kandoomsg("U",9502,"")
            NEXT FIELD cmpy_code
         ELSE
            CALL build_mask(pr_rec_kandoouser.cmpy_code, "??????????????????", " ")
               returning pr_rec_kandoouser.acct_mask_code
            DISPLAY BY NAME pr_rec_kandoouser.acct_mask_code
               
            DISPLAY pr_company.name_text TO company.name_text 
              
         END IF
      AFTER FIELD profile_code
         IF pr_rec_kandoouser.profile_code IS NULL THEN
            LET pr_kandooprofile.profile_text = "Super user profile"
            DISPLAY BY NAME pr_kandooprofile.profile_text 
               
         ELSE
            SELECT * INTO pr_kandooprofile.* FROM kandooprofile
             WHERE cmpy_code = pr_rec_kandoouser.cmpy_code
               AND profile_code = pr_rec_kandoouser.profile_code
            IF STATUS = NOTFOUND THEN
               LET msgresp = kandoomsg("U",9910,"")
               #9910 RECORD NOT found
               NEXT FIELD profile_code
            ELSE
               DISPLAY BY NAME pr_kandooprofile.profile_text 
                
            END IF
         END IF
      AFTER FIELD language_code
         SELECT * INTO pr_language.* FROM language
          WHERE language_code = pr_rec_kandoouser.language_code
         IF STATUS = NOTFOUND THEN
            LET msgresp = kandoomsg("U",9910,"")
            #9910 RECORD NOT found
            NEXT FIELD language_code
         ELSE
            DISPLAY BY NAME pr_language.language_text 
             
         END IF
      AFTER FIELD access_ind
         IF pr_rec_kandoouser.access_ind IS NULL THEN
            LET msgresp = kandoomsg("U", 9102, "")
            #9102 Value Must be Entered 
            NEXT FIELD access_ind
         END IF
         IF pr_rec_kandoouser.access_ind NOT matches "[123]" THEN
            LET msgresp = kandoomsg("U",9530,"")
            NEXT FIELD access_ind
         END IF
      AFTER FIELD print_text
         IF pr_rec_kandoouser.print_text IS NOT NULL THEN
            SELECT * INTO pr_printcodes.* FROM printcodes
             WHERE print_code = pr_rec_kandoouser.print_text
            IF STATUS = NOTFOUND THEN
               LET msgresp = kandoomsg("U",9910,"")
               #9910 RECORD NOT found
               NEXT FIELD print_text
            END IF
         END IF
      AFTER FIELD email                                     
         IF pr_rec_kandoouser.email IS NOT NULL THEN
            IF pr_rec_kandoouser.email NOT matches "*@*" THEN
               LET msgresp = kandoomsg("U",9947,pr_rec_kandoouser.email)
               #9948 Invalid Email Address .....
               NEXT FIELD email
            END IF
         END IF

      ON KEY(control-b)
         CASE   
            WHEN infield(print_text)
               LET pr_rec_kandoouser.print_text = show_print(cmpy)
               NEXT FIELD print_text
         END CASE
      AFTER INPUT
         ##
         ## Cheque Print & KandooERP Check
         IF NOT(int_flag OR quit_flag) THEN
            IF pr_rec_kandoouser.group_code IS NOT NULL THEN
               IF pr_rec_kandoouser.signature_text IS NOT NULL THEN
                  IF pr_rec_kandoouser.password_text IS NULL THEN
                     LET msgresp = kandoomsg("U", 9102, "")
                     #9102 Value Must be Entered 
                     NEXT FIELD password_text
                  END IF
               ELSE
                  LET msgresp = kandoomsg("U",9102,"")
                  #9102 Value Must be Entered 
                  NEXT FIELD signature_text
               END IF
            ELSE
               IF pr_rec_kandoouser.signature_text IS NOT NULL THEN
                  LET msgresp = kandoomsg("U",9102,"")
                  #9102 Value Must be Entered 
                  NEXT FIELD group_code
               ELSE
                  IF pr_rec_kandoouser.password_text IS NULL THEN
                     CASE
                        WHEN pr_rec_kandoouser.passwd_ind = '1'
                           LET msgresp = kandoomsg("U",9102,"")
                           #9102 Value Must be Entered 
                           NEXT FIELD password_text
                     END CASE 
                  ELSE
                     CASE 
                        WHEN pr_rec_kandoouser.passwd_ind = '2'
                           LET msgresp = kandoomsg("A",9075,"")
                           NEXT FIELD passwd_ind
                     END CASE
                  END IF
               END IF
            END IF
         END IF
      ON KEY (control-w)
         CALL kandoohelp("")
   END INPUT
   IF int_flag OR quit_flag THEN
      CLOSE WINDOW U101
      LET int_flag = FALSE
      LET quit_flag = FALSE
      FOR i = idx TO arr_count()
         IF i = arr_count() THEN
            LET pa_rec_kandoouser[i].sign_on_code = NULL
            LET pa_rec_kandoouser[i].name_text = NULL
            LET pa_rec_kandoouser[i].acct_mask_code = NULL
            LET pa_rec_kandoouser[i].security_ind = NULL
         ELSE
            LET pa_rec_kandoouser[i].sign_on_code = pa_rec_kandoouser[i+1].sign_on_code
            LET pa_rec_kandoouser[i].name_text = pa_rec_kandoouser[i+1].name_text
            LET pa_rec_kandoouser[i].acct_mask_code = pa_rec_kandoouser[i+1].acct_mask_code
            LET pa_rec_kandoouser[i].security_ind = pa_rec_kandoouser[i+1].security_ind
         END IF
      END FOR
      LET pr_rec_kandoouser.sign_on_code = pa_rec_kandoouser[idx].sign_on_code
      LET pr_rec_kandoouser.name_text = pa_rec_kandoouser[idx].name_text
      LET pr_rec_kandoouser.acct_mask_code = pa_rec_kandoouser[idx].acct_mask_code
      LET pr_rec_kandoouser.security_ind = pa_rec_kandoouser[idx].security_ind
      FOR i = 0 TO 14-scrn
         DISPLAY pa_rec_kandoouser[idx+i].* TO sr_rec_kandoouser[scrn+i].*
      END FOR
   ELSE
      LET msgresp = kandoomsg("U",1005,"")
      #1005 Updating Database;  Please Wait.
      INSERT INTO kandoouser VALUES (pr_rec_kandoouser.*)
      #
      # HANDLE NEW SECURITY ENHANCEMENT MODIFICATIONS
      # INSERT MODULE SECURITY - DEFAULTING TO kandoouser SECURITY LEVEL
      # Only INSERT FOR the current company
      #
      DECLARE company_curs CURSOR FOR
       SELECT cmpy_code INTO fv_cmpy_code FROM company
        WHERE cmpy_code = pr_rec_kandoouser.cmpy_code
      FOREACH company_curs
          LET pr_kandoomodule.cmpy_code = fv_cmpy_code
          LET pr_kandoomodule.user_code = pr_rec_kandoouser.sign_on_code
          FOR pv_cnt = 1 TO length(pr_company.module_text)
             IF pr_company.module_text[pv_cnt, pv_cnt] IS NOT NULL AND
                pr_company.module_text[pv_cnt, pv_cnt] != " " THEN 
                   LET pr_kandoomodule.module_code =
                       pr_company.module_text[pv_cnt, pv_cnt] 
                   LET pr_kandoomodule.security_ind = pr_rec_kandoouser.security_ind
                   INSERT INTO kandoomodule VALUES (pr_kandoomodule.*)
             END IF
          END FOR
      END FOREACH
      INITIALIZE pr_kandoousercmpy.* TO NULL
      
      

      #Dont INSERT here... Force entry via U151 so that locn_code IS 
      #forced FOR those who have TO enter one.
      CALL change_cmpy_access()
      SELECT * INTO pr_rec_kandoouser.* FROM kandoouser
       WHERE sign_on_code = pr_rec_kandoouser.sign_on_code
      CLOSE WINDOW U101
   END IF	
	

END FUNCTION

}