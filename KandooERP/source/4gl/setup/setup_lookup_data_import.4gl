GLOBALS "lib_db_globals.4gl"


#####################################################
# FUNCTION chooseImportLookupData()					--Step 06
#####################################################
FUNCTION chooseImportLookupData()
	DEFINE retNavigation SMALLINT
	
	OPEN WINDOW wLookupData WITH FORM "per/setup/setup_lookup_data"
	CALL updateConsole()

	INPUT BY NAME setupLookupDataRecord.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
			ON ACTION "Previous"
				LET mdNavigatePrevious = TRUE
				EXIT INPUT	
	END INPUT
		
	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
		IF mdNavigatePrevious THEN
			LET step_num = step_num - 1
			LET mdNavigatePrevious = FALSE
			LET retNavigation = -1
		ELSE
			LET step_num = step_num + 1
			LET retNavigation = 1
			
		END IF
	END IF
				
	CLOSE WINDOW wLookupData		
	RETURN retNavigation		
END FUNCTION


#####################################################
# FUNCTION initLookupDataSelection()        --Utility
#####################################################	
FUNCTION initLookupDataSelection()
	LET setupLookupDataRecord.coa = 1					--COA Chart of Accounts
	LET setupLookupDataRecord.journal = 1 		--Journal
	LET setupLookupDataRecord.uom = 1					--UOM = Units of Meassurements
	LET setupLookupDataRecord.banktype = 1		--bankType = Different bank types
	LET setupLookupDataRecord.credreas = 1		--redreas = Reasons TO give credit
	LET setupLookupDataRecord.holdpay = 1			--holdpay = Reasons TO hold back payments


END FUNCTION

