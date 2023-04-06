############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION get_next_incremented_value (p_business_module,p_number_name,p_isolation)
# This function reads all the incrementing numbers. It is used a a transition from the xxparms tables to the increment_number table with one row per cmpy,business module and number
# This function just reads the value with no lock
DEFINE p_business_module LIKE increment_numbers.business_module
DEFINE p_isolation STRING
DEFINE p_number_name LIKE increment_numbers.number_name
DEFINE l_value LIKE increment_numbers.last_value
IF p_isolation = "REPEATABLE" THEN
	SET ISOLATION TO REPEATABLE READ
END IF
CASE
	WHEN p_business_module = "GL" AND p_number_name = "next_jour_num"
		WHENEVER SQLERROR CONTINUE
		SELECT next_jour_num INTO l_value 
		FROM glparms 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = "1"
		IF sqlca.sqlcode < 0 THEN
			RETURN sqlca.sqlcode
		END IF

	WHEN p_business_module = "GL" AND p_number_name = "next_post_num"
		SELECT next_post_num INTO l_value 
		FROM glparms 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = "1"
		IF sqlca.sqlcode < 0 THEN
			RETURN sqlca.sqlcode
		END IF

	WHEN p_business_module = "GL" AND p_number_name = "next_load_num"
		SELECT next_load_num INTO l_value 
		FROM glparms 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = "1"
		IF sqlca.sqlcode < 0 THEN
			RETURN sqlca.sqlcode
		END IF
END CASE
RETURN l_value 
END FUNCTION # get_next_incremented_value 

FUNCTION set_next_incremented_value (p_business_module,p_number_name)
# This function reads the last value of the number, sets it to +1 and returns the new value
DEFINE p_business_module LIKE increment_numbers.business_module
DEFINE p_number_name LIKE increment_numbers.number_name
DEFINE l_value LIKE increment_numbers.last_value

SET ISOLATION TO REPEATABLE READ
SET LOCK MODE TO WAIT 3

# First read the value
LET l_value = get_next_incremented_value (p_business_module,p_number_name,"REPEATABLE")
IF l_value >= 0 THEN
	LET l_value = l_value + 1
ELSE
	RETURN -1	# we had an error (probably lock ?)
END IF
CASE
	WHEN p_business_module = "GL" AND p_number_name = "next_jour_num"
		UPDATE glparms 
		SET next_jour_num = l_value 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = '1'
		IF sqlca.sqlerrd[3] <> 1 THEN
			RETURN -1		# no row has been updated
		END IF
	WHEN p_business_module = "GL" AND p_number_name = "next_post_num"
		UPDATE glparms 
		SET next_post_num = l_value 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = '1'
		IF sqlca.sqlerrd[3] <> 1 THEN
			RETURN -1		# no row has been updated
		END IF
	WHEN p_business_module = "GL" AND p_number_name = "next_load_num"
		UPDATE glparms 
		SET next_load_num = l_value 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND key_code = '1'
		IF sqlca.sqlerrd[3] <> 1 THEN
			RETURN -1		# no row has been updated
		END IF
END CASE
RETURN l_value 
END FUNCTION # get_next_incremented_value 
		

############################################################################
# FUNCTION get_deposit_num()
#
#
############################################################################
FUNCTION get_deposit_num() 
	DEFINE
		r_bank_dep_num LIKE cashreceipt.bank_dep_num

	DECLARE c_arparms CURSOR FOR 
	SELECT arparms.next_bank_dep_num FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	FOR UPDATE 

	OPEN c_arparms 
	FETCH c_arparms INTO r_bank_dep_num 
	IF STATUS = 0 THEN
		IF r_bank_dep_num IS NULL OR r_bank_dep_num = 0 THEN 
			LET r_bank_dep_num = 1 
		END IF 

		# UPDATE ------------------------------
		UPDATE arparms 
		SET arparms.next_bank_dep_num = r_bank_dep_num + 1 
		WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND arparms.parm_code = "1" 
	ELSE
		LET r_bank_dep_num = 0
	END IF

	RETURN r_bank_dep_num 

END FUNCTION 
############################################################################
# END FUNCTION get_deposit_num()
############################################################################
		
		
		