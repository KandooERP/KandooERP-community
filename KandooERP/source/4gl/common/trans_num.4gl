###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
# \brief module - trans_num.4gl
# Purpose -
#
#   FUNCTION next_trans_num.4gl
#               generates a transaction number depending upon the
#               VALUES stored in arparms.nextinv_num
#
#   Accepts 3 Formal Parameters
#    1. p_cmpy_code
#    2. trans_type  TRAN_TYPE_INVOICE_IN Invoice,
#                   TRAN_TYPE_RECEIPT_CA Cashreceipt,
#                   TRAN_TYPE_CREDIT_CR Credit Note
#                   TRAN_TYPE_LOAD_LNO Loads
#                   TRAN_TYPE_DELIVERY_DLV Delivery Dockets
#                   TRAN_TYPE_TRANSPORT_TRN Manual Transport Transactions
#                   TRAN_TYPE_CUSTOMER_CUS Customer Codes
#                   TRAN_TYPE_ORDER_ORD Orders
#                   "SS"  Subscriptions
#                   TRAN_TYPE_BATCH_BAT Batches
#    3. acct_code - Used FOR segment prefixed transaction numbering
#    4. program   - "PROGRAM" Default next number FOR a particular
#                   trans_type
#                   "<program-name>" WHERE program_name IS the name
#                   of the program
#


###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"

###########################################################################
# FUNCTION next_trans_num(p_cmpy_code,p_tran_type,p_acct_code)
#
#
###########################################################################
FUNCTION next_trans_num(p_cmpy_code,p_tran_type,p_acct_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_acct_code LIKE invoicehead.acct_override_code 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_ssparms RECORD LIKE ssparms.* 
	DEFINE l_position_num LIKE nextnumber.next_num 
	DEFINE l_trans_num LIKE nextnumber.next_num 
	DEFINE l_numtype_ind INTEGER 
	DEFINE l_retry_num INTEGER 
	DEFINE l_progname CHAR(18) 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER QUIT 
	DEFER INTERRUPT 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*

	CASE p_tran_type 
		WHEN TRAN_TYPE_RECEIPT_CA 
			LET l_numtype_ind = l_rec_arparms.nextcash_num 

		WHEN TRAN_TYPE_CREDIT_CR 
			LET l_numtype_ind = l_rec_arparms.nextcredit_num 

		WHEN TRAN_TYPE_INVOICE_IN 
			LET l_numtype_ind = l_rec_arparms.nextinv_num 

		WHEN TRAN_TYPE_LOAD_LNO 
			LET l_numtype_ind = 1 

		WHEN TRAN_TYPE_DELIVERY_DLV 
			LET l_numtype_ind = 1 

		WHEN TRAN_TYPE_TRANSPORT_TRN 
			LET l_numtype_ind = 1 

		WHEN TRAN_TYPE_CUSTOMER_CUS 
			LET l_numtype_ind = 1 

		WHEN TRAN_TYPE_ORDER_ORD 
			LET l_numtype_ind = 1 

		WHEN "SS" 
			SELECT * INTO l_rec_ssparms.* 
			FROM ssparms 
			WHERE cmpy_code = p_cmpy_code 
			LET l_numtype_ind = l_rec_ssparms.next_sub_num 

		WHEN TRAN_TYPE_BATCH_BAT 
			LET l_numtype_ind = 1 
	END CASE 

	LET l_retry_num = 0 

	WHILE true 

		CASE l_numtype_ind 
			WHEN 0 #0 is not valid -> user get's prompted to specify the start transaction number i.e. invoiced number .-. after that, it will be incremented by one with each transaction
				LET l_trans_num = next_manual(p_cmpy_code,p_tran_type) 

			WHEN 1 
				LET l_trans_num = next_sequent(p_cmpy_code,p_tran_type) 

			WHEN 2 
				SELECT next_num INTO l_position_num 
				FROM nextnumber 
				WHERE cmpy_code = p_cmpy_code 
				AND flex_code = "POSITIONS" 
				AND tran_type_ind = p_tran_type 
				IF status = notfound THEN 
					LET l_trans_num = next_sequent(p_cmpy_code,p_tran_type) 
				ELSE 
					LET l_trans_num = next_prefixed(p_cmpy_code,p_tran_type,p_acct_code, 
					l_position_num) 
				END IF 

			WHEN 3 
				LET l_trans_num = next_prog(p_cmpy_code,p_tran_type) 

			OTHERWISE 
				LET l_trans_num = next_sequent(p_cmpy_code,p_tran_type) 
		END CASE 

		IF l_trans_num < 0 THEN 
			EXIT WHILE 
		END IF 

		IF NOT num_exists(p_cmpy_code,p_tran_type,l_trans_num) THEN 
			EXIT WHILE 
		END IF 

		IF l_retry_num = 25 THEN 
			ERROR kandoomsg2("G",7011,"")	#7011 Automatic numbering has exceeded the retry limit
			LET l_numtype_ind = 0 
			LET l_retry_num = 0 
		ELSE 
			LET l_retry_num = l_retry_num + 1 
		END IF 

	END WHILE 

	RETURN l_trans_num 
END FUNCTION 
###########################################################################
# END FUNCTION next_trans_num(p_cmpy_code,p_tran_type,p_acct_code)
###########################################################################


###################################################################################
# FUNCTION next_manual(p_cmpy_code,p_tran_type)
#
#
###################################################################################
FUNCTION next_manual(p_cmpy_code,p_tran_type) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE l_next_number LIKE arparms.nextinv_num 
	DEFINE l_prompt_text CHAR(40) 
	DEFINE l_trans_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_trans_text = kandooword("nextnumber.tran_type_ind",p_tran_type) 
	IF l_trans_text IS NULL THEN 
		ERROR kandoomsg2("U",9007,"") 
		LET l_trans_text = "Next ",p_tran_type clipped," Number" 
	END IF 
	LET l_prompt_text = l_trans_text clipped,"............." 

	OPEN WINDOW A203 with FORM "A203" 
	CALL windecoration_a("A203") 

	DISPLAY l_prompt_text TO prompt_text   

	INPUT l_next_number FROM next_number
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","trans_num","input-l_next_number") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 

				MENU "Abandon Transaction" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","trans_num","menu-Abandon_Transaction-1") -- albo kd-505 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND KEY(interrupt,"E")"Yes"			" EXIT PROGRAM" 
						EXIT program 

					COMMAND "No" " Re Enter transaction Number" 
						LET int_flag = false 
						LET quit_flag = false 
						EXIT MENU 

				END MENU 

				NEXT FIELD next_number 
			END IF 

			IF l_next_number IS NULL THEN 
				ERROR kandoomsg2("G",9025,l_trans_text)			#9025 l_trans_text clipped, " must be entered "
				NEXT FIELD next_number 
			END IF 

			IF l_next_number < 0 THEN 
				ERROR kandoomsg2("G",9026,l_trans_text)	#9026 l_trans_text clipped, " Must be Greater than Zero"
				NEXT FIELD next_number 
			END IF 

			IF num_exists(p_cmpy_code,p_tran_type,l_next_number) THEN 
				ERROR kandoomsg2("G",9027,l_trans_text)		#9027 l_trans_text clipped, already exists "
				NEXT FIELD next_number 
			END IF 

	END INPUT 

	CLOSE WINDOW A203 
	RETURN l_next_number 
END FUNCTION 
###################################################################################
# END FUNCTION next_manual(p_cmpy_code,p_tran_type)
###################################################################################


###################################################################################
# FUNCTION next_sequent(p_cmpy_code,p_tran_type)
#
#
###################################################################################
FUNCTION next_sequent(p_cmpy_code,p_tran_type) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE l_rec_nextnumber RECORD LIKE nextnumber.* 
	DEFINE l_line CHAR(80) 
	DEFINE l_msg STRING
	
	WHENEVER ERROR GOTO recovery 
	DECLARE c1_nextnum CURSOR FOR 
	SELECT * FROM nextnumber 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = "NEXTNUMBER" 

	FOR UPDATE 
	OPEN c1_nextnum 
	FETCH c1_nextnum INTO l_rec_nextnumber.* 

	IF l_rec_nextnumber.next_num >= 99999999 THEN #?? hard coded limit ? 
		ERROR kandoomsg2("G",7012,"") 
		LET l_line =" Next sequential number exceeds maximum length - (8)" 
		CALL error_disp(l_line)
		LET l_msg = l_line CLIPPED, "\Exit Program" 
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
		EXIT program 
	END IF 

	#make sure the table nextnumber was populated using GZD

	IF l_rec_nextnumber.next_num < 1 THEN #can not be 0 or negative		  
		LET l_line =" Sequential number can not be 0 - RUN GZD to setup"
		ERROR l_line 
		CALL error_disp(l_line)
		LET l_msg = l_line CLIPPED, "\Exit Program" 
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
		EXIT program 
	END IF 

	UPDATE nextnumber 
	SET next_num = l_rec_nextnumber.next_num + 1 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = "NEXTNUMBER" 
	RETURN l_rec_nextnumber.next_num 

	LABEL recovery: 
	RETURN status 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION 
###################################################################################
# END FUNCTION next_sequent(p_cmpy_code,p_tran_type)
###################################################################################


###################################################################################
# FUNCTION next_prog(p_cmpy_code,p_tran_type)
#
#
###################################################################################
FUNCTION next_prog(p_cmpy_code,p_tran_type) 
	## Gets next number FROM 1 of four places
	## flex code = program name "A21"
	## flex code = program group name "A2"
	## flex code = program module name "A2"
	## flex code = literial "PROGRAM"
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_nextnumber RECORD LIKE nextnumber.* 
	DEFINE l_line CHAR(80) 
	DEFINE l_temp_text CHAR(250) 
	DEFINE l_program CHAR(20) 
	DEFINE i SMALLINT 
	DEFINE l_len SMALLINT 
	DEFINE l_num_retry_cnt SMALLINT 

	INITIALIZE l_program TO NULL 

	LET l_temp_text = get_baseprogname() 

	#LET l_temp_text = l_temp_text clipped
	LET l_len = length(l_temp_text) 
	FOR i = 1 TO l_len 
		IF l_temp_text[i] = "." THEN 
			EXIT FOR 
		END IF 
		LET l_program = l_program clipped,l_temp_text[i] 
	END FOR 

	WHENEVER ERROR GOTO recovery 

	LET l_program = l_program clipped 
	LET l_temp_text = " SELECT * FROM nextnumber ", 
	" WHERE cmpy_code = '",p_cmpy_code,"' ", 
	" AND tran_type_ind = '",p_tran_type clipped,"' ", 
	" AND flex_code = ? ", 
	" FOR UPDATE " 
	PREPARE s_nextnum FROM l_temp_text 
	DECLARE c2_nextnum CURSOR FOR s_nextnum 

	FOR l_num_retry_cnt = 1 TO 4 
		OPEN c2_nextnum USING l_program 
		FETCH c2_nextnum INTO l_rec_nextnumber.* 

		IF sqlca.sqlcode = notfound THEN 
			CASE l_num_retry_cnt 
				WHEN "1" 
					LET l_program = l_program[1,2] 
				WHEN "2" 
					LET l_program = l_program[1,1] 
				WHEN "3" 
					LET l_program = "PROGRAM" 
				OTHERWISE 
					ERROR kandoomsg2("G",9187,"") 
					LET l_line ="Default nextnumber NOT SET up FOR PROGRAM " 
					CALL error_disp(l_line) 
					EXIT program 
			END CASE 
		ELSE 
			EXIT FOR 
		END IF 
	END FOR 

	CLOSE c2_nextnum 

	IF l_rec_nextnumber.alloc_ind IS NOT NULL 
	AND l_rec_nextnumber.alloc_ind = "Y" THEN 
		LET l_rec_nextnumber.next_num = next_manual(p_cmpy_code,p_tran_type) 
	ELSE 
		UPDATE nextnumber 
		SET next_num = next_num + 1 
		WHERE cmpy_code = p_cmpy_code 
		AND tran_type_ind = p_tran_type 
		AND flex_code = l_program 
	END IF 
	RETURN(l_rec_nextnumber.next_num) 

	LABEL recovery: 
	RETURN status 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
###################################################################################
# END FUNCTION next_prog(p_cmpy_code,p_tran_type)
###################################################################################


###################################################################################
# FUNCTION next_prefixed(p_cmpy_code,p_tran_type,p_acct_code,p_position_num)
#
#
###################################################################################
FUNCTION next_prefixed(p_cmpy_code,p_tran_type,p_acct_code,p_position_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_acct_code LIKE invoicehead.acct_override_code 
	DEFINE p_position_num LIKE nextnumber.next_num
	DEFINE l_rec_nextnumber RECORD LIKE nextnumber.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_nextnum_text CHAR(8) 
	DEFINE l_flex_code LIKE invoicehead.acct_override_code 
	DEFINE l_prefix LIKE invoicehead.acct_override_code 
	DEFINE l_arr_start_num array[3] OF INTEGER 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 

	WHENEVER ERROR GOTO recovery 
	LET l_idx = 1 
	LET p_position_num = 0 - p_position_num 

	FOR i = 2 TO 0 step -1 
		LET l_arr_start_num[l_idx] = p_position_num/(100 ** i) 
		IF l_arr_start_num[l_idx] > 0 THEN 
			SELECT * INTO l_rec_structure.* 
			FROM structure 
			WHERE cmpy_code = p_cmpy_code 
			AND start_num = l_arr_start_num[l_idx] 
			AND type_ind = "S" 
			IF sqlca.sqlcode = 0 THEN 
				LET x = l_rec_structure.start_num 
				LET y = l_rec_structure.length_num 
				LET l_prefix = l_prefix clipped,p_acct_code[x,x+y-1] 
				LET l_flex_code[x,x+y-1] = p_acct_code[x,x+y-1] 
				LET l_idx = l_idx + 1 
			END IF 
		END IF 
		LET p_position_num = p_position_num mod(100 ** i) 
	END FOR 

	DECLARE c0_nextnum CURSOR FOR 
	SELECT * FROM nextnumber 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = l_flex_code 
	FOR UPDATE 

	OPEN c0_nextnum 
	FETCH c0_nextnum INTO l_rec_nextnumber.* 
	IF status = notfound THEN 
		return(next_sequent(p_cmpy_code,p_tran_type)) 
	END IF 

	LET l_nextnum_text = l_rec_nextnumber.next_num USING "<<<<<<<<" 
	LET x = length(l_prefix) 
	LET y = length(l_nextnum_text) 
	IF x + y > 8 THEN 
		return(next_sequent(p_cmpy_code,p_tran_type)) 
	END IF 

	UPDATE nextnumber 
	SET next_num = l_rec_nextnumber.next_num + 1 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = l_flex_code 

	LET l_nextnum_text = l_rec_nextnumber.next_num USING "&&&&&&&&" 
	LET l_nextnum_text[1,x] = l_prefix 
	RETURN l_nextnum_text 

	LABEL recovery: 
	RETURN status 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION 
###################################################################################
# END FUNCTION next_prefixed(p_cmpy_code,p_tran_type,p_acct_code,p_position_num)
###################################################################################


###################################################################################
# FUNCTION valid_trans_num(p_cmpy_code,p_tran_type,p_acct_code)
#
#
###################################################################################
FUNCTION valid_trans_num(p_cmpy_code,p_tran_type,p_acct_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_acct_code LIKE invoicehead.acct_override_code 
	DEFINE l_position_num LIKE nextnumber.next_num 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_ssparms RECORD LIKE ssparms.* 
	DEFINE l_rec_nextnumber RECORD LIKE nextnumber.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_flex_code, l_prefix LIKE invoicehead.acct_override_code 
	DEFINE l_nextnum_text CHAR(8) 
	DEFINE l_arr_start_num array[3] OF INTEGER 
	DEFINE l_numtype_ind INTEGER 
	DEFINE l_line CHAR(80) 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 


	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	CASE p_tran_type 
		WHEN TRAN_TYPE_RECEIPT_CA 
			LET l_numtype_ind = l_rec_arparms.nextcash_num 
		WHEN TRAN_TYPE_CREDIT_CR 
			LET l_numtype_ind = l_rec_arparms.nextcredit_num 
		WHEN TRAN_TYPE_INVOICE_IN 
			LET l_numtype_ind = l_rec_arparms.nextinv_num 
		WHEN TRAN_TYPE_LOAD_LNO 
			LET l_numtype_ind = 1 
		WHEN TRAN_TYPE_DELIVERY_DLV 
			LET l_numtype_ind = 1 
		WHEN TRAN_TYPE_TRANSPORT_TRN 
			LET l_numtype_ind = 1 
		WHEN TRAN_TYPE_CUSTOMER_CUS 
			LET l_numtype_ind = 1 
		WHEN TRAN_TYPE_ORDER_ORD 
			LET l_numtype_ind = 1 
		WHEN "SS" 
			SELECT * INTO l_rec_ssparms.* 
			FROM ssparms 
			WHERE cmpy_code = p_cmpy_code 
			LET l_numtype_ind = l_rec_ssparms.next_sub_num 
		WHEN TRAN_TYPE_BATCH_BAT 
			LET l_numtype_ind = 1 
	END CASE 

	CASE l_numtype_ind 
		WHEN 0 
			RETURN true 

		WHEN 1 
			SELECT unique 1 FROM nextnumber 
			WHERE cmpy_code = p_cmpy_code 
			AND tran_type_ind = p_tran_type 
			AND flex_code = "NEXTNUMBER" 
			IF status = notfound THEN 
				INSERT INTO nextnumber VALUES (p_cmpy_code,p_tran_type,"NEXTNUMBER",1,"N") #last argument was missing, i added "N".. but have no idea what IS expected huho 20.08.2019 
			END IF 
			RETURN true 

		WHEN 2 
			SELECT * INTO l_rec_nextnumber.* 
			FROM nextnumber 
			WHERE cmpy_code = p_cmpy_code 
			AND flex_code = "POSITIONS" 
			AND tran_type_ind = p_tran_type 
			IF status = notfound THEN 
				LET l_line= 
				" Auto Transaction Numbering Not Set Up - No segments " 
				CALL error_disp(l_line) 
				RETURN false 

			ELSE 

				LET l_idx = 1 
				LET l_position_num = 0 - l_rec_nextnumber.next_num 

				FOR i = 2 TO 0 step -1 
					LET l_arr_start_num[l_idx] = l_position_num/(100 ** i) 
					IF l_arr_start_num[l_idx] > 0 THEN 
						SELECT * INTO l_rec_structure.* 
						FROM structure 
						WHERE cmpy_code = p_cmpy_code 
						AND start_num = l_arr_start_num[l_idx] 
						AND type_ind = "S" 
						IF sqlca.sqlcode = 0 THEN 
							LET x = l_rec_structure.start_num 
							LET y = l_rec_structure.length_num 
							LET l_prefix = l_prefix clipped,p_acct_code[x,x+y-1] 
							LET l_flex_code[x,x+y-1] = p_acct_code[x,x+y-1] 
							LET l_idx = l_idx + 1 
						END IF 
					END IF 
					LET l_position_num = l_position_num mod(100 ** i) 
				END FOR 

				SELECT * INTO l_rec_nextnumber.* 
				FROM nextnumber 
				WHERE cmpy_code = p_cmpy_code 
				AND tran_type_ind = p_tran_type 
				AND flex_code = l_flex_code 
				IF status = notfound THEN 
					LET l_line = "Account flex codes:",l_flex_code clipped, 
					": NOT SET up FOR prefixed Numbering" 
					CALL error_disp(l_line) 
					RETURN false 
				END IF 

				LET l_rec_nextnumber.next_num = l_rec_nextnumber.next_num + 1 
				LET l_nextnum_text = l_rec_nextnumber.next_num USING "<<<<<<<<" 
				LET x = length(l_prefix) 
				LET y = length(l_nextnum_text) 
				IF x + y > 8 THEN 
					LET l_line="Transaction Number exceeds maximum length -", 
					" Flex code:",l_flex_code clipped 
					CALL error_disp(l_line) 
					RETURN false 
				ELSE 
					RETURN true 
				END IF 
			END IF 

		WHEN 3 
			SELECT * INTO l_rec_nextnumber.* 
			FROM nextnumber 
			WHERE cmpy_code = p_cmpy_code 
			AND tran_type_ind = p_tran_type 
			AND flex_code = "PROGRAM" 
			IF sqlca.sqlcode = notfound THEN 
				RETURN false 
			ELSE 
				RETURN true 
			END IF 

		OTHERWISE 
			LET l_line= " Auto Transaction Numbering Not Set Up" 
			CALL error_disp(l_line) 
			RETURN false 
	END CASE 

END FUNCTION 
###################################################################################
# END FUNCTION valid_trans_num(p_cmpy_code,p_tran_type,p_acct_code)
###################################################################################


###################################################################################
# FUNCTION num_exists(p_cmpy_code,p_tran_type,p_doc_num)
#
#
###################################################################################
FUNCTION num_exists(p_cmpy_code,p_tran_type,p_doc_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_doc_num LIKE arparms.nextinv_num 
	DEFINE l_doc_code LIKE customer.cust_code 
	DEFINE l_query_text CHAR(2200) 

	CASE p_tran_type 
		WHEN TRAN_TYPE_INVOICE_IN 
			LET l_query_text = "SELECT 1 FROM invoicehead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND inv_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_CREDIT_CR 
			LET l_query_text = "SELECT 1 FROM credithead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND cred_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_RECEIPT_CA 
			LET l_query_text = "SELECT 1 FROM cashreceipt ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND cash_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_LOAD_LNO 
			LET l_query_text = "SELECT 1 FROM loadhead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND load_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_DELIVERY_DLV 
			LET l_query_text = "SELECT 1 FROM delivhead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND pick_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_TRANSPORT_TRN 
			LET l_query_text = "SELECT 1 FROM driverledger ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND ref_num = '",p_doc_num,"' ", 
			"AND trans_type_code = 'AD' " 

		WHEN TRAN_TYPE_CUSTOMER_CUS 
			LET l_doc_code = p_doc_num 
			LET l_query_text = "SELECT 1 FROM customer ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND cust_code = '",l_doc_code,"' " 

		WHEN TRAN_TYPE_ORDER_ORD 
			LET l_query_text = "SELECT 1 FROM ordhead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND order_num = '",p_doc_num,"' " 

		WHEN "SS" 
			LET l_query_text = "SELECT 1 FROM subhead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND sub_num = '",p_doc_num,"' " 

		WHEN TRAN_TYPE_BATCH_BAT 
			LET l_query_text = "SELECT unique 1 FROM voucher ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND batch_num = '",p_doc_num,"' " 
	END CASE 

	PREPARE s_number FROM l_query_text 
	DECLARE c_number CURSOR FOR s_number 
	OPEN c_number 
	FETCH c_number 

	IF status = notfound THEN 
		CLOSE c_number 
		IF p_tran_type = TRAN_TYPE_BATCH_BAT THEN 
			SELECT unique 1 FROM debithead 
			WHERE cmpy_code = p_cmpy_code 
			AND batch_num = p_doc_num 
			IF status = notfound THEN 
				RETURN false 
			ELSE 
				RETURN true 
			END IF 
		END IF 
		RETURN false 
	ELSE 
		CLOSE c_number 
		RETURN true 
	END IF 

END FUNCTION 
###################################################################################
# END FUNCTION num_exists(p_cmpy_code,p_tran_type,p_doc_num)
###################################################################################


###################################################################################
# FUNCTION error_disp(p_line1)
#
#
###################################################################################
FUNCTION error_disp(p_line1) 
	DEFINE p_line1 CHAR(80) 
	DEFINE l_errmsg CHAR(240) 

	DEFINE prg_name STRING --prog base NAME 

	LET l_errmsg[001,080]="Auto Transaction Numbering Error Occurred in ",	"program:",get_baseprogname() clipped 
	LET l_errmsg[081,160]= p_line1 
	LET l_errmsg[161,240]="Refer Transaction Numbering Program - Menu GZD" 
	CALL errorlog(l_errmsg) 

END FUNCTION 
###################################################################################
# END FUNCTION error_disp(p_line1)
###################################################################################