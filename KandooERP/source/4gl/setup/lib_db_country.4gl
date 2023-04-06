--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
###########################################################
# FUNCTION libCountryLoad()
# LOAD data FROM unl TO country table
###########################################################
FUNCTION libCountryLoad(pOverwrite)
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM country WHERE 1=1
	END IF
	
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM country)
	IF STATUS <> NOTFOUND THEN
		IF fgl_winquestion("Delete DB info", "Country catalog (country table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF
	END IF
	DELETE FROM country WHERE 1=1
	LOAD FROM "unl/country.unl" INSERT INTO country
END FUNCTION

#########################################################
# FUNCTION libPopulateCountryCombo()
# - widget_id - IS ID of combobox widget in the form
# Gets all counties FROM DB AND put it in combobox widget
#########################################################
FUNCTION libPopulateCountryCombo(widget_id)
	DEFINE widget_id STRING
	DEFINE t_country_text LIKE country.country_text
	DEFINE cb ui.Combobox
		LET cb = ui.Combobox.Forname(widget_id)
		DECLARE cntry CURSOR FOR SELECT country_text FROM country ORDER BY country_text
		FOREACH cntry INTO t_country_text
			CALL cb.AddItem(t_country_text,t_country_text)
		END FOREACH
		CLOSE cntry		
END FUNCTION

FUNCTION libPopulateCountry2Combo(widget_id)
	DEFINE widget_id STRING
	DEFINE i SMALLINT
	DEFINE recCountry DYNAMIC ARRAY OF RECORD 
			 country_code LIKE country.country_code,	
			 country_text LIKE country.country_text
		END RECORD
		
	DEFINE cb ui.Combobox
		LET cb = ui.Combobox.Forname(widget_id)
		DECLARE cntry2 CURSOR FOR SELECT country_code, country_text FROM country ORDER BY country_text
		
		LET i = 1
		FOREACH cntry2 INTO recCountry[i].*
			CALL cb.AddItem(recCountry[i].country_code,recCountry[i].country_text)
			LET i = i+1
		END FOREACH
		CLOSE cntry2		
END FUNCTION

FUNCTION libGetCountryCodeByText(cntry_text)
	DEFINE cntry_text LIKE country.country_text
	DEFINE cntry_code LIKE country.country_code
		SELECT country_code INTO cntry_code FROM country WHERE country_text = cntry_text
	RETURN cntry_code
END FUNCTION

FUNCTION libGetCountryTextByCode(cntry_code)
	DEFINE cntry_text LIKE country.country_text
	DEFINE cntry_code LIKE country.country_code
		SELECT country_text INTO cntry_text FROM country WHERE country_code = cntry_code
	RETURN cntry_text
END FUNCTION

FUNCTION getCountryBankFormatCode(cntry_code)
	DEFINE ret_bank_acc_format LIKE country.bank_acc_format
	DEFINE cntry_code LIKE country.country_code
		SELECT bank_acc_format INTO ret_bank_acc_format FROM country WHERE country_code = cntry_code
	RETURN ret_bank_acc_format
END FUNCTION


FUNCTION getCountryBankFormatText(cntry_code)
	DEFINE ret_bank_acc_format LIKE country.bank_acc_format
	DEFINE cntry_code LIKE country.country_code
	SELECT bank_acc_format INTO ret_bank_acc_format FROM country WHERE country_code = cntry_code
		
	CASE	ret_bank_acc_format
		WHEN 0
			RETURN "ISBN/BIC"

		WHEN 1
			RETURN "US Format"

		WHEN 2
			RETURN "Australian Format"

		OTHERWISE
			RETURN "Unknown Bank Format"
		
	END CASE

	RETURN ret_bank_acc_format
END FUNCTION


