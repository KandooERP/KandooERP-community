

FUNCTION getBankFormat(p_bankFormatId)
DEFINE p_bankFormatId SMALLINT

	CASE p_bankFormatId
		WHEN 1
			RETURN "US-Bank Account Format"
		WHEN 2
			RETURN "EBS Australian Bank Account Format"
		OTHERWISE
			RETURN "IBAN/BIC Bank Account Format"
	END CASE		

END FUNCTION