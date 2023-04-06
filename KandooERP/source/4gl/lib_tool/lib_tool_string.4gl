GLOBALS "../common/glob_GLOBALS.4gl" 

##############################################################
# FUNCTION getLangStr(p_id)
# Get the localized string (each language IS in a different table
# makes it easier TO add other languages
##############################################################

FUNCTION getlangstr(p_id) 
	DEFINE p_id LIKE langstr_gb.id 
	DEFINE retstr LIKE langstr_gb.langstr 
	DEFINE strcount SMALLINT 

	#We will add more language string tables later

	CASE glob_rec_kandoouser.language_code -- we NEED gl_language/country variable ... australia, us AND uk have got the language english, but use different terms 


		WHEN "AUS" --australia 
			SELECT count(*) INTO strcount FROM langstr_aus WHERE id = p_id 
			IF strcount = 1 THEN 
				SELECT langstr INTO retstr FROM langstr_aus WHERE id = p_id 
			END IF 

		OTHERWISE #when "GB" 
			SELECT count(*) INTO strcount FROM langstr_gb WHERE id = p_id 
			IF strcount = 1 THEN 
				SELECT langstr INTO retstr FROM langstr_gb WHERE id = p_id 
			END IF 

	END CASE 

	IF strcount <> 1 THEN 
		LET retstr = "notFound: id=", p_id 
	END IF 

	RETURN retstr 


END FUNCTION 

##############################################################
# FUNCTION setTitleGroupBox(cnt_id,str_id)
# Group Box Title
##############################################################
FUNCTION settitlegroupbox(cnt_id,p_str_id) 
	DEFINE p_id LIKE langstr_gb.id 
	DEFINE cnt_id STRING #groupbox identifier 
	DEFINE p_str_id STRING --string identifier 
	DEFINE l_string STRING --localized STRING value 
	DEFINE componentgroupbox ui.groupbox 

	LET l_string = getlangstr(p_str_id) 
	LET componentgroupbox = ui.groupbox.forname(cnt_id) 
	CALL componentgroupbox.settitle(l_string) 

END FUNCTION 


##############################################################
# FUNCTION kandooword(p_ref_text,p_ref_code)
#
#
##############################################################
FUNCTION kandooword(p_ref_text,p_ref_code) 
	DEFINE p_ref_text LIKE kandooword.reference_text 
	DEFINE p_ref_code LIKE kandooword.reference_code 
	DEFINE l_ret_response_text LIKE kandooword.response_text 
	DEFINE l_spaces CHAR(400) 

	SELECT response_text INTO l_ret_response_text FROM kandooword 
	WHERE language_code = glob_rec_kandoouser.language_code 
	AND reference_code = p_ref_code 
	AND reference_text = p_ref_text 

	IF status = notfound THEN 
		SELECT response_text INTO l_ret_response_text FROM kandooword 
		WHERE language_code = "ENG" 
		AND reference_code = p_ref_code 
		AND reference_text = p_ref_text 

		IF status = notfound THEN 
			LET l_spaces ="Missing kandooword ", 
			glob_rec_kandoouser.language_code clipped, 
			"-", 
			p_ref_text clipped, 
			"-", 
			p_ref_code clipped, 
			" in Program ",getModuleId() 
			CALL errorlog(l_spaces) 
			LET l_ret_response_text = NULL 
		END IF 
	END IF 

	RETURN l_ret_response_text 
END FUNCTION 




###########################################################################################################
# FUNCTION hideStringPartial(argStr)
#
# take string i.e. password AND only keep first AND last letter. remaining letters will be shown as asterix *
# i.e. Treehouse -> T*******e
###########################################################################################################
FUNCTION hidestringpartial(argstr) 
	DEFINE argstr STRING 
	DEFINE strlength, i SMALLINT 
	DEFINE retstr STRING 

	LET strlength = argstr.getlength() 
	IF strlength > 0 THEN 
		FOR i = 1 TO strlength 
			LET retstr = retStr.append("*") --[i] = "*" 
		END FOR 

		LET retstr[1] = argstr[1] 
		LET retstr[strlength] = argstr[strlength] 
	END IF 

	RETURN retstr 

END FUNCTION 
