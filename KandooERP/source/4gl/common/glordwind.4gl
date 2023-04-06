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
###########################################################################
# ONLY used in AZ4, AZP and IZ1
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_arparms RECORD LIKE arparms.* #note: this variable IS only used TO read a value which means, another module must SET it's VALUES 
	DEFINE glob_arr_rec_accounts array[5] OF RECORD 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text 
	END RECORD 
	DEFINE glob_req_flag CHAR(1) # flag FOR mandatory entry OF default account 
END GLOBALS 


####################################################################
#     glordwind.4gl - enter_ordacct
#                   Window FUNCTION FOR entering account codes FOR
#                   the default account AND the various ORDER type
#                   indicators.
#
#                   This FUNCTION can only be used IF the kandoooption "WOTA"
#                   has been activated in U1T.
#
#                   NOTE: The FUNCTION does NOT UPDATE any tables. This IS done
#                         by calling FUNCTION, AND any INSERT OR delete keys
#                         will have TO be re-defined.
####################################################################

####################################################################
# FUNCTION enter_ordacct(p_cmpy_code, p_ref_code, p_table_name, p_column_name,
#                       p_accounts, p_first_flag)
#
#
####################################################################
FUNCTION enter_ordacct(p_cmpy_code, p_ref_code, p_table_name, p_column_name, p_accounts, p_first_flag) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ref_code LIKE orderaccounts.ref_code 
	DEFINE p_table_name LIKE orderaccounts.table_name 
	DEFINE p_column_name LIKE orderaccounts.column_name 
	DEFINE p_accounts RECORD 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE p_first_flag SMALLINT # FIRST time that entry has occurred. 
	DEFINE l_reference_code LIKE kandooword.reference_code 
	DEFINE l_response_text LIKE kandooword.response_text 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_temp_text CHAR(50) 

	FOR l_counter = 1 TO 5 
		INITIALIZE glob_arr_rec_accounts[l_counter].* TO NULL 
	END FOR 

	OPEN WINDOW G556 with FORM "G556" 
	CALL windecoration_g("G556") -- albo kd-758 

	LET glob_req_flag = true 
	CASE p_column_name 
		WHEN "acct_code" 
			LET glob_req_flag = false 
			LET l_reference_code = TRAN_TYPE_RECEIPT_CA # cartage account 
		WHEN "cart_acct_code" 
			LET l_reference_code = TRAN_TYPE_RECEIPT_CA # cartage account 
		WHEN "cogs_acct_code" 
			LET l_reference_code = "COG" # cogs account 
		WHEN "freight_acct_code" 
			IF p_table_name = "customertype" THEN 
				LET l_reference_code = "FA" # freight account 
			ELSE 
				LET l_reference_code = "FOA" # freight out account 
			END IF 
		WHEN "int_cogs_acct_code" 
			LET l_reference_code = "ICO" # internal cost OF good sold acct 
		WHEN "int_rev_acct_code" 
			LET l_reference_code = "IRA" # internal revenue account 
		WHEN "rev_acct_code" 
			LET l_reference_code = "RA" # revenue account 
		WHEN "sale_acct_code" 
			LET l_reference_code = "SA" # sales account 
		OTHERWISE 
			ERROR kandoomsg2("U",7039,"Column name does NOT exist.")		#7039 Logic Error: Column name does NOT exist.
			CLOSE WINDOW G556 
			RETURN true, p_accounts.* 
	END CASE 

	MESSAGE kandoomsg2("U",1002,"")#1002 Searching database;  Please wait.
	SELECT response_text INTO l_response_text FROM kandooword 
	WHERE language_code = "ENG" 
	AND reference_code = l_reference_code 
	AND reference_text = "glordwind" 

	IF status = notfound THEN 
		LET l_response_text = NULL 
	END IF 

	LET glob_arr_rec_accounts[1].acct_code = p_accounts.def_acct_code 
	IF glob_arr_rec_accounts[1].acct_code IS NOT NULL THEN 
		LET glob_arr_rec_accounts[1].desc_text = db_coa_get_desc_text(ui_off,glob_arr_rec_accounts[1].acct_code) 
		#      SELECT desc_text INTO glob_arr_rec_accounts[1].desc_text FROM coa
		#       WHERE cmpy_code = p_cmpy_code
		#         AND acct_code = glob_arr_rec_accounts[1].acct_code

		IF glob_arr_rec_accounts[1].desc_text IS NULL THEN 
			#IF STATUS = NOTFOUND THEN
			LET glob_arr_rec_accounts[1].desc_text = NULL 
		END IF 
	END IF 

	IF p_first_flag = false THEN 
		LET glob_arr_rec_accounts[2].acct_code = p_accounts.ord6_acct_code 
		LET glob_arr_rec_accounts[3].acct_code = p_accounts.ord7_acct_code 
		LET glob_arr_rec_accounts[4].acct_code = p_accounts.ord8_acct_code 
		LET glob_arr_rec_accounts[5].acct_code = p_accounts.ord9_acct_code 
	ELSE 
		# Need TO get original entries FROM table
		FOR l_counter = 2 TO 5 
			SELECT acct_code INTO glob_arr_rec_accounts[l_counter].acct_code 
			FROM orderaccounts 
			WHERE cmpy_code = p_cmpy_code 
			AND table_name = p_table_name 
			AND column_name = p_column_name 
			AND ref_code = p_ref_code 
			AND ord_ind = (l_counter + 4) 
			IF status = notfound THEN 
				LET glob_arr_rec_accounts[l_counter].acct_code = NULL 
			END IF 
		END FOR 
	END IF 

	FOR l_counter = 2 TO 5 
		IF glob_arr_rec_accounts[l_counter].acct_code IS NOT NULL THEN 
			SELECT desc_text INTO glob_arr_rec_accounts[l_counter].desc_text FROM coa 
			WHERE cmpy_code = p_cmpy_code 
			AND acct_code = glob_arr_rec_accounts[l_counter].acct_code 
			IF status = notfound THEN 
				LET glob_arr_rec_accounts[l_counter].desc_text = NULL 
			END IF 
		ELSE 
			LET glob_arr_rec_accounts[l_counter].desc_text = NULL 
		END IF 
	END FOR 

	CALL set_count(5) 
	DISPLAY l_response_text TO response_text 

	FOR l_counter = 1 TO 5 
		CALL show_acct_detl(l_counter, glob_arr_rec_accounts[l_counter].*) 
	END FOR 

	MESSAGE kandoomsg2("U",1020,"Account") #1020 Enter Account Details;  OK TO Continue.
	INPUT 
		glob_arr_rec_accounts[1].acct_code, 
		glob_arr_rec_accounts[2].acct_code, 
		glob_arr_rec_accounts[3].acct_code, 
		glob_arr_rec_accounts[4].acct_code, 
		glob_arr_rec_accounts[5].acct_code WITHOUT DEFAULTS 
	FROM 
		def_acct_code, 
		ord6_acct_code, 
		ord7_acct_code, 
		ord8_acct_code, 
		ord9_acct_code ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","glordwind","input-accounts") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET l_temp_text = show_acct(p_cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				CASE l_idx 
					WHEN 1 
						LET p_accounts.def_acct_code = l_temp_text 
					WHEN 2 
						LET p_accounts.ord6_acct_code = l_temp_text 
					WHEN 3 
						LET p_accounts.ord7_acct_code = l_temp_text 
					WHEN 4 
						LET p_accounts.ord8_acct_code = l_temp_text 
					WHEN 5 
						LET p_accounts.ord9_acct_code = l_temp_text 
				END CASE 
				LET glob_arr_rec_accounts[l_idx].acct_code = l_temp_text 
				CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 
			END IF 

		BEFORE FIELD def_acct_code 
			LET l_idx = 1 

		AFTER FIELD def_acct_code 
			IF p_table_name = "customertype" 
			AND glob_arr_rec_accounts[l_idx].acct_code IS NULL THEN 
				LET glob_arr_rec_accounts[l_idx].acct_code = glob_rec_arparms.freight_acct_code 
			END IF 

			IF glob_req_flag 
			AND glob_arr_rec_accounts[l_idx].acct_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD def_acct_code 
			END IF 

			IF glob_arr_rec_accounts[l_idx].acct_code IS NOT NULL THEN 
				IF NOT check_acct(p_cmpy_code, l_idx, p_table_name) THEN 
					NEXT FIELD def_acct_code 
				END IF 
			ELSE 
				LET glob_arr_rec_accounts[l_idx].desc_text = NULL 
			END IF 
			CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 

		BEFORE FIELD ord6_acct_code 
			LET l_idx = 2 

		AFTER FIELD ord6_acct_code 
			IF glob_arr_rec_accounts[l_idx].acct_code IS NOT NULL THEN 
				IF NOT check_acct(p_cmpy_code, l_idx, p_table_name) THEN 
					NEXT FIELD ord6_acct_code 
				END IF 
			ELSE 
				LET glob_arr_rec_accounts[l_idx].desc_text = NULL 
				CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 
			END IF 

		BEFORE FIELD ord7_acct_code 
			LET l_idx = 3 

		AFTER FIELD ord7_acct_code 
			IF glob_arr_rec_accounts[l_idx].acct_code IS NOT NULL THEN 
				IF NOT check_acct(p_cmpy_code, l_idx, p_table_name) THEN 
					NEXT FIELD ord7_acct_code 
				END IF 
			ELSE 
				LET glob_arr_rec_accounts[l_idx].desc_text = NULL 
				CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 
			END IF 

		BEFORE FIELD ord8_acct_code 
			LET l_idx = 4 

		AFTER FIELD ord8_acct_code 
			IF glob_arr_rec_accounts[l_idx].acct_code IS NOT NULL THEN 
				IF NOT check_acct(p_cmpy_code, l_idx, p_table_name) THEN 
					NEXT FIELD ord8_acct_code 
				END IF 
			ELSE 
				LET glob_arr_rec_accounts[l_idx].desc_text = NULL 
				CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 
			END IF 

		BEFORE FIELD ord9_acct_code 
			LET l_idx = 5 

		AFTER FIELD ord9_acct_code 
			IF glob_arr_rec_accounts[l_idx].acct_code IS NOT NULL THEN 
				IF NOT check_acct(p_cmpy_code, l_idx, p_table_name) THEN 
					NEXT FIELD ord9_acct_code 
				END IF 
			ELSE 
				LET glob_arr_rec_accounts[l_idx].desc_text = NULL 
				CALL show_acct_detl(l_idx, glob_arr_rec_accounts[l_idx].*) 
			END IF 
			IF (fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("RETURN")) THEN 
				EXIT INPUT 
			END IF 

	END INPUT 

	CLOSE WINDOW G556 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE p_accounts.* TO NULL 
		RETURN true, p_accounts.* 
	END IF 
	LET p_accounts.def_acct_code = glob_arr_rec_accounts[1].acct_code 
	LET p_accounts.ord6_acct_code = glob_arr_rec_accounts[2].acct_code 
	LET p_accounts.ord7_acct_code = glob_arr_rec_accounts[3].acct_code 
	LET p_accounts.ord8_acct_code = glob_arr_rec_accounts[4].acct_code 
	LET p_accounts.ord9_acct_code = glob_arr_rec_accounts[5].acct_code 
	RETURN false, p_accounts.* 
END FUNCTION 


####################################################################
# FUNCTION show_acct_detl(p_idx, p_rec_account)
#
#
####################################################################
FUNCTION show_acct_detl(p_idx, p_rec_account) 
	DEFINE p_idx SMALLINT
	DEFINE p_rec_account RECORD 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text 
	END RECORD 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_desc_text LIKE coa.desc_text 
 

	CASE p_idx 
		WHEN 1 
			DISPLAY p_rec_account.acct_code, 
			p_rec_account.desc_text 
			TO def_acct_code, 
			desc_text1 

		WHEN 2 
			DISPLAY p_rec_account.acct_code, 
			p_rec_account.desc_text 
			TO ord6_acct_code, 
			desc_text2 

		WHEN 3 
			DISPLAY p_rec_account.acct_code, 
			p_rec_account.desc_text 
			TO ord7_acct_code, 
			desc_text3 

		WHEN 4 
			DISPLAY p_rec_account.acct_code, 
			p_rec_account.desc_text 
			TO ord8_acct_code, 
			desc_text4 

		WHEN 5 
			DISPLAY p_rec_account.acct_code, 
			p_rec_account.desc_text 
			TO ord9_acct_code, 
			desc_text5 

	END CASE 
END FUNCTION 
####################################################################
# END FUNCTION show_acct_detl(p_idx, p_rec_account)
####################################################################


####################################################################
# FUNCTION check_acct(p_cmpy_code, p_idx, p_table_name)
#
#
####################################################################
FUNCTION check_acct(p_cmpy_code, p_idx, p_table_name) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_idx SMALLINT 
	DEFINE p_table_name LIKE orderaccounts.table_name 

	IF p_idx = 1 
	AND glob_req_flag 
	AND glob_arr_rec_accounts[1].acct_code IS NULL THEN 
		ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered.
		RETURN false 
	END IF 

	SELECT desc_text INTO glob_arr_rec_accounts[p_idx].desc_text FROM coa 
	WHERE acct_code = glob_arr_rec_accounts[p_idx].acct_code 
	AND cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		ERROR kandoomsg2("W",9215,"")	#9215 Account code NOT found;  Try window.
		RETURN false 
	END IF
	 
	IF p_table_name = "mbparms" THEN 
		IF NOT acct_type(p_cmpy_code,glob_arr_rec_accounts[p_idx].acct_code, COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"") THEN 
			RETURN false 
		END IF 
	ELSE 
		IF NOT acct_type(p_cmpy_code,glob_arr_rec_accounts[p_idx].acct_code, COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
			RETURN false 
		END IF 
	END IF
	 
	CALL show_acct_detl(p_idx, glob_arr_rec_accounts[p_idx].*) 
	
	RETURN true 
END FUNCTION 
####################################################################
# END FUNCTION check_acct(p_cmpy_code, p_idx, p_table_name)
####################################################################