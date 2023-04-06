GLOBALS "../common/glob_GLOBALS.4gl" 



######################################
# validate_vat_registration_code(p_vat_code,p_country_code)
#
# This is the starting point for future VAT registration code / number validations
#
# Validate VAT registration number
# currently for Australia ABN (Australian Business Number)
# HuHo 23.08.2018 - I'll disable it for now TO test none-australians/any dummy vat reg number
#
# Note ! This is a protoType (initial state) to loosly couple vat registration code validation in the future)
# vat_code (vat_registration code is currently hard coded for Australia 11 CHAR and DB also CHAR(11))
######################################

FUNCTION validate_vat_registration_code(p_vat_code,p_country_code) 
	DEFINE p_vat_code LIKE company.vat_code
	DEFINE p_country_code LIKE country.country_code
	DEFINE l_ret BOOLEAN #Return Value
	DEFINE l_abn_string STRING
	DEFINE l_msg STRING

	LET l_abn_string = trim(p_vat_code)  #String offers more methods
	LET l_ret = FALSE

	#arguments must never be NULL
	IF (p_vat_code IS NULL) OR (p_country_code IS NULL) THEN
		LET l_msg = "Function validate_vat_registration_code(p_vat_code=", trim(p_vat_code), ",p_country_code=", trim(p_country_code), "\nArguments can not be empty !!" 
		CALL fgl_winmessage("Internal 4gl code error",l_msg,"ERROR") 
	END IF

	CASE p_country_code
		WHEN "UA" #Ukraine
			IF l_abn_string.getLength() != 12 THEN
				ERROR "VAT Registration Code for ", db_country_get_country_text(UI_OFF,p_country_code), " Must be 12 characters long"
				LET l_ret = FALSE
			ELSE
				LET l_ret = TRUE
			END IF

		WHEN "DE" #Germany/Deutschland
			IF l_abn_string.getLength() != 12 THEN
				ERROR "VAT Registration Code for ", db_country_get_country_text(UI_OFF,p_country_code), " Must be 12 characters long"
				LET l_ret = FALSE
			ELSE
				LET l_ret = TRUE
			END IF

		WHEN "FR" #France
			IF l_abn_string.getLength() != 12 THEN
				ERROR "VAT Registration Code for ", db_country_get_country_text(UI_OFF,p_country_code), " Must be 12 characters long"
				LET l_ret = FALSE
			ELSE
				LET l_ret = TRUE
			END IF

		WHEN "UK" #United Kingdom
			IF l_abn_string.getLength() != 12 THEN
				ERROR "VAT Registration Code for ", db_country_get_country_text(UI_OFF,p_country_code), " Must be 12 characters long"
				LET l_ret = FALSE
			ELSE
				LET l_ret = TRUE
			END IF


		WHEN "US" #USA
			IF l_abn_string.getLength() != 12 THEN
				ERROR "VAT Registration Code for ", db_country_get_country_text(UI_OFF,p_country_code), " Must be 12 characters long"
				LET l_ret = FALSE
			ELSE
				LET l_ret = TRUE
			END IF

		OTHERWISE
			LET l_msg = "Error! ",
			"Function validate_vat_registration_code(p_vat_code=", trim(p_vat_code), ",p_country_code=", trim(p_country_code), "\n",
			"Country ", db_country_get_country_text(UI_OFF,p_country_code), " has not been localized yet !"
			CALL fgl_winmessage("Internal 4gl code error",l_msg,"ERROR")
				LET l_ret = FALSE
	END CASE
	
	RETURN l_ret
END FUNCTION


{
###############################################################
# FUNCTION validate_vat_registration_code_old(p_compregno, p_country_code)
#
# ACN = Australian Company Number UK: Company Registration DE:
###############################################################
FUNCTION validate_vat_registration_code_old(p_compregno, p_country_code) 
	DEFINE p_compregno LIKE vendor.vat_code 
	DEFINE l_compregno LIKE vendor.vat_code 

	DEFINE p_country_code LIKE company.country_code 
	DEFINE st_object base.stringtokenizer 
	DEFINE cnt,i,strlength SMALLINT 
	DEFINE valid boolean 

	LET valid = false 

	IF (p_compregno IS NOT null) AND (p_country_code IS NOT null) THEN 

		LET i = 1 
		FOR cnt = 1 TO length(p_compRegNo) 
			IF p_compregno[cnt] <> " " THEN 
				LET l_compregno[i] = p_compregno[cnt] 
				LET i = i + 1 
			END IF 
		END FOR 

		LET strlength = length(l_compregno) 

		CASE p_country_code 
			WHEN "GB" --uk/great britain 
				IF strlength = 8 THEN 
					LET valid = true 
				ELSE 
					ERROR "Your CRN has got an incorrect Length of ", trim(strLength)," characters AND should be 8 FOR great Britain" 
					#Need TO add AA123456 AND 12345678 validation for UK CRN specification
					LET l_compregno = "<invalid CRN (", trim(p_country_code), ")>" 
				END IF 
				#if we talk about tax numbers  (NOT sure why we need the company registration number)
				#https://www.bzst.de/DE/Steuern_International/USt_Identifikationsnummer/Merkblaetter/Aufbau_USt_IdNr.pdf?__blob=publicationFile
				#UK = value added tax registration number
				#VAT Reg.No. GB neun oder zwölf, nur Ziffern;
				#für Verwaltungen und Gesundheitswesen: fünf, die ersten zwei Stellen GD oder HA

			WHEN "DE" --germany 
				IF strlength = 7 THEN 
					LET valid = true 
				ELSE 
					ERROR "Your CRN has got an incorrect Length of ", trim(strLength)," characters AND should be 7 FOR Germany" 
					#Need TO add AA123456 AND 12345678 validation for UK CRN specification
					LET l_compregno = "<invalid CRN (", trim(p_country_code), ")>" 
				END IF 

			WHEN "UA" --ukraine 
				IF strlength = 12 THEN 
					LET valid = true 
				ELSE 
					ERROR "Your CRN has got an incorrect Length of ", trim(strLength)," characters AND should be 12 FOR Ukraine" 
					#Need TO add AA123456 AND 12345678 validation for UK CRN specification
					LET l_compregno = "<invalid CRN (", trim(p_country_code), ")>" 
				END IF 


			WHEN "AU" --australia 
				IF validate_vat_registration_code(l_compregno) THEN 
					LET valid = true 
				ELSE 
					CALL kandoomsg("G",9538,"") 
				END IF 

			OTHERWISE 
				LET valid = true 
		END CASE 


	END IF 

	RETURN valid 
END FUNCTION 


######################################
# Validate VAT registration number
# currently for Australia ABN (Australian Business Number)
# HuHo 23.08.2018 - I'll disable it for now TO test none-australians/any dummy vat reg number
######################################

FUNCTION validate_vat_registration_code(pr_vat_code) 
	DEFINE pr_vat_code CHAR(11), 
	pr_abn_num array[11] OF INTEGER, 
	pr_weight_num array[11] OF INTEGER, 
	pr_check_digit,i INTEGER 

	IF length(pr_vat_code) <> 11 THEN 
		RETURN false 
	END IF 
	FOR i = 1 TO 11 
		LET pr_abn_num[i] = pr_vat_code[i] 
		IF pr_abn_num[i] IS NULL THEN 
			LET pr_abn_num[i] = 0 
		END IF 
	END FOR 
	LET pr_weight_num[1] = 10 
	LET pr_weight_num[2] = 1 
	LET pr_weight_num[3] = 3 
	LET pr_weight_num[4] = 5 
	LET pr_weight_num[5] = 7 
	LET pr_weight_num[6] = 9 
	LET pr_weight_num[7] = 11 
	LET pr_weight_num[8] = 13 
	LET pr_weight_num[9] = 15 
	LET pr_weight_num[10] = 17 
	LET pr_weight_num[11] = 19 
	LET pr_abn_num[1] = pr_abn_num[1] - 1 
	LET pr_check_digit = 0 
	FOR i = 1 TO 11 
		LET pr_check_digit = pr_check_digit + (pr_abn_num[i] * 
		pr_weight_num[i]) 
	END FOR 
	IF pr_check_digit mod 89 <> 0 THEN 
		RETURN true --false @this IS an australian abn validation 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


}