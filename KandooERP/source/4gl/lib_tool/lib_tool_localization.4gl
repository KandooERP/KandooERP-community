GLOBALS "../common/glob_GLOBALS.4gl" 
# CALL db_country_localize(glob_rec_orderhead.country_code) located in db country lib
#Moved FROM secufunc.4gl
##############################################################
# FUNCTION xlate_to(z)
##############################################################
FUNCTION xlate_to(z) 
	DEFINE z LIKE language.yes_flag #was CHAR(1) 
	DEFINE y LIKE language.yes_flag 
	DEFINE n LIKE language.no_flag 

	SELECT language.yes_flag INTO y 
	FROM language 
	WHERE language.language_code = glob_rec_kandoouser.language_code 

	SELECT language.no_flag INTO n 
	FROM language 
	WHERE language.language_code = glob_rec_kandoouser.language_code 

	CASE z 
		WHEN y 
			RETURN "Y" 
		WHEN n 
			RETURN "N" 
		OTHERWISE 
			RETURN "" 
	END CASE 
END FUNCTION 

# This function sets the values of local Y(es) and (N(o))
FUNCTION set_local_yes_no()
	SELECT "Y", language.yes_flag INTO g_rec_yes.* 
	FROM language 
	WHERE language.language_code = glob_rec_kandoouser.language_code 

	SELECT "N",language.no_flag INTO g_rec_no.*
	FROM language 
	WHERE language.language_code = glob_rec_kandoouser.language_code 
END FUNCTION 

FUNCTION local_yes()
	RETURN g_rec_yes.localized_val
END FUNCTION

FUNCTION local_no()
	RETURN g_rec_no.localized_val
END FUNCTION

FUNCTION global_yes()
	RETURN g_rec_yes.english_val
END FUNCTION

FUNCTION global_no()
	RETURN g_rec_no.english_val
END FUNCTION

# this function takes the global  Y or N and converts to local
FUNCTION xlate_to_local(p_flag)
	DEFINE p_flag NCHAR(1)
	DEFINE out_flag NCHAR(1)
	CASE
		WHEN p_flag = g_rec_yes.english_val
			RETURN g_rec_yes.localized_val
		WHEN p_flag = g_rec_no.english_val
			RETURN g_rec_no.localized_val
	END CASE
	RETURN NULL
END FUNCTION

# this function takes the local Y or N and converts to global
FUNCTION xlate_to_global(p_flag)
	DEFINE p_flag NCHAR(1)
	CASE
		WHEN p_flag = g_rec_yes.localized_val
			RETURN g_rec_yes.english_val
		WHEN p_flag = g_rec_no.localized_val
			RETURN g_rec_no.english_val
	END CASE
	RETURN NULL
END FUNCTION


############################################################
# FUNCTION set_authenticated_user_locale(p_language, p_country)
# RETURN VOID
#
############################################################
FUNCTION set_authenticated_user_locale(p_language, p_country)

	DEFINE p_language LIKE kandoouser.language_code
	DEFINE p_country LIKE kandoouser.country_code
	DEFINE l_locale STRING

	# Set translation language for the authenticated user. 
	# if language_code is not set for the user then use default - ENG

	IF p_language IS NOT NULL THEN
		LET l_locale = p_language
	ELSE
		LET l_locale = "ENG"
	END IF
	IF p_country IS NOT NULL THEN
		LET l_locale = l_locale, "_", p_country
	END IF
	
	CALL fgl_set_ui_locale(l_locale)

END FUNCTION


############################################################
# FUNCTION set_localize_any_string()
# RETURN VOID
#
############################################################
FUNCTION set_localize_any_string()

	CALL fgl_setenv("QX_LOCALIZE_ANY_STRING",1) #Variable must be set before program load

END FUNCTION
