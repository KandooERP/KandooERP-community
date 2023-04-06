############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MOduLE Scope Variables
############################################################
DEFINE modu_formname STRING 


#######################################################################
# FUNCTION build_coa(p_cmpy, p_group_code)
#
#
#######################################################################
FUNCTION build_coa(p_cmpy,p_group_code) 
	DEFINE p_cmpy LIKE acctgrp.cmpy_code 
	DEFINE p_group_code LIKE acctgrp.group_code 
	DEFINE l_old_id LIKE acctgrpdetl.id_num 
	DEFINE l_first_time SMALLINT 
	DEFINE l_select_text STRING 
	DEFINE l_acctgrpdetl RECORD LIKE acctgrpdetl.* 
	DEFINE r_count SMALLINT

	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE tempcoa 
	( acct_code CHAR(18), 
	desc_text CHAR(40), 
	type_ind CHAR(1) ) 

	CREATE unique INDEX i0_tempcoa ON tempcoa(acct_code) 

	DELETE FROM tempcoa 
	WHENEVER ERROR STOP 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	DECLARE dtl_curs CURSOR FOR 
	SELECT * 
	FROM acctgrpdetl 
	WHERE cmpy_code = p_cmpy 
	AND group_code = p_group_code 
	ORDER BY group_code, id_num, subid_num 

	LET l_old_id = NULL 
	LET l_first_time = true 

	LET r_count = 0 
	FOREACH dtl_curs INTO l_acctgrpdetl.* 

		CASE 
			WHEN l_first_time = true 
				LET l_first_time = false 
				CALL build_text(p_cmpy, l_acctgrpdetl.*) 
				RETURNING l_select_text 

			WHEN l_old_id <> l_acctgrpdetl.id_num 
				CALL add_to_coa(l_select_text) 
				CALL build_text(p_cmpy, l_acctgrpdetl.*) 
				RETURNING l_select_text 

			OTHERWISE 
				CALL add_to_text(p_cmpy, l_select_text, l_acctgrpdetl.*) 
				RETURNING l_select_text 
		END CASE 

		LET l_old_id = l_acctgrpdetl.id_num 
		LET r_count = r_count + 1 
	END FOREACH 

	IF r_count > 0 THEN 
		CALL add_to_coa(l_select_text) 
	END IF 

	RETURN r_count 

END FUNCTION 


#######################################################################
# FUNCTION add_to_coa(p_select_text)
#
#
#######################################################################
FUNCTION add_to_coa(p_select_text) 
	DEFINE p_select_text STRING 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	WHENEVER ERROR CONTINUE 

	PREPARE fv_select FROM p_select_text 

	IF STATUS THEN 
		RETURN 
	END IF 

	DECLARE coa_curs CURSOR FOR fv_select 

	FOREACH coa_curs INTO l_rec_coa.* 
		SELECT * FROM tempcoa 
		WHERE acct_code = l_rec_coa.acct_code 

		IF STATUS = NOTFOUND THEN 
			INSERT INTO tempcoa VALUES (l_rec_coa.acct_code, 
			l_rec_coa.desc_text, 
			l_rec_coa.type_ind) 
		END IF 
	END FOREACH 

	WHENEVER ERROR STOP 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 


#######################################################################
# FUNCTION add_to_text(p_cmpy, p_select_text, p_acctgrpdetl)
#
#
#######################################################################
FUNCTION add_to_text(p_cmpy,p_select_text,p_acctgrpdetl) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_select_text STRING 
	DEFINE p_acctgrpdetl RECORD LIKE acctgrpdetl.* 
	DEFINE l_length SMALLINT 
	DEFINE l_end_pos SMALLINT 

	CASE 
		WHEN p_acctgrpdetl.sel_type = "R" 
			LET p_select_text = p_select_text clipped, 
			" AND acct_code >= \"", p_acctgrpdetl.start_acct clipped, 
			"\" ", "AND acct_code <= \"", 
			p_acctgrpdetl.end_acct clipped, "\" " 

		WHEN p_acctgrpdetl.sel_type = "S" 
			SELECT length_num 
			INTO l_length 
			FROM structure 
			WHERE cmpy_code = p_cmpy 
			AND start_num = p_acctgrpdetl.start_pos 
			LET l_end_pos = p_acctgrpdetl.start_pos + l_length - 1 

			IF p_acctgrpdetl.end_acct IS NULL 
			OR p_acctgrpdetl.end_acct = " " THEN 
				LET p_select_text = p_select_text clipped, 
				" AND acct_code[", p_acctgrpdetl.start_pos clipped, 
				",", l_end_pos clipped, "] matches \"", 
				p_acctgrpdetl.start_acct clipped, "\" " 
			ELSE 
				LET p_select_text = p_select_text clipped, 
				" AND acct_code[", p_acctgrpdetl.start_pos clipped, 
				",", l_end_pos clipped, "] >= \"", 
				p_acctgrpdetl.start_acct clipped, "\" ", 
				"AND acct_code[", p_acctgrpdetl.start_pos clipped, ",", 
				l_end_pos clipped, "] <= \"", 
				p_acctgrpdetl.end_acct clipped, "\" " 
			END IF 

		WHEN p_acctgrpdetl.sel_type = "M" 
			LET p_select_text = p_select_text clipped, 
			" AND acct_code matches \"", 
			p_acctgrpdetl.start_acct clipped, "\" " 
	END CASE 

	RETURN p_select_text 

END FUNCTION 


#######################################################################
# FUNCTION build_text(p_cmpy, p_acctgrpdetl)
#
#
#######################################################################
FUNCTION build_text(p_cmpy,p_acctgrpdetl) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acctgrpdetl RECORD LIKE acctgrpdetl.*
	DEFINE l_length SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE r_select_text STRING

	CASE 
		WHEN p_acctgrpdetl.sel_type = "R" 
			LET r_select_text = 
			"SELECT * FROM coa ", 
			"WHERE cmpy_code = \"", p_cmpy, "\" ", 
			"AND acct_code >= \"", p_acctgrpdetl.start_acct clipped, 
			"\" ", "AND acct_code <= \"", 
			p_acctgrpdetl.end_acct clipped, "\" " 

		WHEN p_acctgrpdetl.sel_type = "S" 
			SELECT length_num 
			INTO l_length 
			FROM structure 
			WHERE cmpy_code = p_cmpy 
			AND start_num = p_acctgrpdetl.start_pos 
			LET l_end_pos = p_acctgrpdetl.start_pos + l_length - 1 

			IF p_acctgrpdetl.end_acct IS NULL 
			OR p_acctgrpdetl.end_acct = " " THEN 
				LET r_select_text = "SELECT * FROM coa ", 
				"WHERE cmpy_code = \"", p_cmpy, "\" ", 
				"AND acct_code[", p_acctgrpdetl.start_pos clipped, 
				",", l_end_pos clipped, "] matches \"", 
				p_acctgrpdetl.start_acct clipped, "\" " 
			ELSE 
				LET r_select_text = "SELECT * FROM coa ", 
				"WHERE cmpy_code = \"", p_cmpy, "\" ", 
				"AND acct_code[", p_acctgrpdetl.start_pos clipped, 
				",", l_end_pos clipped, "] >= \"", 
				p_acctgrpdetl.start_acct clipped, "\" ", 
				"AND acct_code[", p_acctgrpdetl.start_pos clipped, ",", 
				l_end_pos clipped, "] <= \"", 
				p_acctgrpdetl.end_acct clipped, "\" " 
			END IF 

		WHEN p_acctgrpdetl.sel_type = "M" 
			LET r_select_text = "SELECT * FROM coa ", 
			"WHERE cmpy_code = \"", p_cmpy, "\" ", 
			"AND acct_code matches \"", 
			p_acctgrpdetl.start_acct clipped, "\" " 
	END CASE 

	RETURN r_select_text 
END FUNCTION 
