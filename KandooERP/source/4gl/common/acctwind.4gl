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

############################################################
#
# COA - CHARTS OF ACCCOUNTS List
#
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
# FUNCTION acctwind_whenever_sqlerror ()
############################################################
FUNCTION acctwind_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
############################################################
# END FUNCTION acctwind_whenever_sqlerror ()
############################################################


#######################################################################
# FUNCTION show_acct(p_cmpy)
#
#         acctwind.4gl - show_acct
#                        Window FUNCTION FOR searching accounts
#                        returns acct_code
#######################################################################
FUNCTION show_acct(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_coa DYNAMIC ARRAY OF #array [200] OF 
	RECORD 
		scroll_flag CHAR(1), 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text, 
		type_ind LIKE coa.type_ind 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_withquery SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	OPEN WINDOW g123 with FORM "G123" 
	CALL winDecoration_g("G123") 

	WHILE true 
		IF l_withquery THEN 
			ERROR kandoomsg2("U", 1001, "") #1001 " Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON acct_code,desc_text,type_ind 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","acctwind","construct-account-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

			IF int_flag	OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_coa.acct_code = NULL 
				EXIT WHILE 
			END IF 

			MESSAGE kandoomsg2("U", 1002, "") 		#1002 " Searching database - please wait"
		ELSE 
			LET l_where_text = "1=1" #without filter CONSTRUCT 
		END IF 

		LET l_query_text = 
			"SELECT * FROM coa ", 
			"WHERE cmpy_code = '",p_cmpy,	"' ","AND ",l_where_text clipped," ", 
			"ORDER BY acct_code" 

		WHENEVER ERROR CONTINUE 
		OPTIONS 
		SQL interrupt ON 

		PREPARE s_coa1 
		FROM l_query_text 
		DECLARE c_coa1 CURSOR FOR s_coa1 

		CALL l_arr_rec_coa.CLEAR()
		LET l_idx = 0 
		FOREACH c_coa1 INTO l_rec_coa.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_coa[l_idx].acct_code = l_rec_coa.acct_code 
			LET l_arr_rec_coa[l_idx].desc_text = l_rec_coa.desc_text 
			LET l_arr_rec_coa[l_idx].type_ind = l_rec_coa.type_ind 
		END FOREACH 

		MESSAGE kandoomsg2("U", 9113, l_idx)		#U9113 l_idx records selected

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		OPTIONS 
		SQL interrupt off 
		MESSAGE kandoomsg2("U", 1006, "") 	#1006 " ESC on line TO SELECT - F10 TO Add"

		CALL SET_COUNT(l_idx)
		DISPLAY ARRAY l_arr_rec_coa TO sr_coa.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","acctwind","input-arr-coa1") 
				LET l_withquery = 0

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_coa.acct_code = l_arr_rec_coa[l_idx].acct_code 

			ON ACTION "FILTER" 
				LET l_withquery = 1 
				EXIT DISPLAY 

			ON ACTION "SETTINGS" --ON KEY (f10) 
				CALL run_prog("GZ1", "", "", "", "") 

		END DISPLAY 
		############################

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_coa.acct_code = NULL
			EXIT WHILE 
		ELSE 
			IF NOT l_withquery THEN 
				EXIT WHILE 
			END IF 
		END IF 

	END WHILE 

	CLOSE WINDOW G123 

	OPTIONS 
	INSERT KEY f1, 
	DELETE KEY f2 

	RETURN l_rec_coa.acct_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_acct(p_cmpy)
#######################################################################


#######################################################################
# FUNCTION showuaccts(p_cmpy, p_acct_mask_code)
#
#
#######################################################################
FUNCTION showuaccts(p_cmpy, p_acct_mask_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_mask_code LIKE coa.acct_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_coa DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text, 
		type_ind LIKE coa.type_ind 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPEN WINDOW G123 with FORM "G123" 
	CALL winDecoration_g("G123") 

	WHILE true 
		CLEAR FORM 
		MESSAGE kandoomsg2("U", 1001, "")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			acct_code, 
			desc_text, 
			type_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","acctwind","construct-coa") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_coa.acct_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U", 1002, "")	#1002 " Searching database - please wait"

		LET l_query_text = 
			"SELECT * FROM coa ", 
			"WHERE cmpy_code = '", 
			p_cmpy, 
			"' ", 
			"AND ", 
			l_where_text clipped, 
			" ", 
			"AND acct_code matches '", 
			p_acct_mask_code, 
			"' ", 
			"ORDER BY acct_code" 

		WHENEVER ERROR CONTINUE 

		PREPARE s_coa2 
		FROM l_query_text 
		DECLARE c_coa2 CURSOR FOR s_coa2 

		LET l_idx = 0 

		FOREACH c_coa2 INTO l_rec_coa.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_coa[l_idx].acct_code = l_rec_coa.acct_code 
			LET l_arr_rec_coa[l_idx].desc_text = l_rec_coa.desc_text 
			LET l_arr_rec_coa[l_idx].type_ind = l_rec_coa.type_ind 
		END FOREACH 

		MESSAGE kandoomsg2("U", 9113, l_idx)	#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_coa[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		MESSAGE kandoomsg2("U", 1006, "")		#1006 " ESC on line TO SELECT - F10 TO Add"
		DISPLAY ARRAY l_arr_rec_coa TO sr_coa.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","acctwind","input-arr-coa2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_coa.acct_code = l_arr_rec_coa[l_idx].acct_code 


			ON KEY (f10) 
				CALL run_prog("GZ1", "", "", "", "") 


		END DISPLAY 

		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW G123 

	OPTIONS 
	INSERT KEY f1, 
	DELETE KEY f2 

	RETURN l_rec_coa.acct_code 
END FUNCTION 
#######################################################################
# END FUNCTION showuaccts(p_cmpy, p_acct_mask_code)
#######################################################################


{
########################################################################
# FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
#
# FUNCTION acct_type  - Replaces bk_ac_ck - Checks FOR correct type of account
#          parameters - p_cmpy
#                       p_acct_code  (Account TO be checked)
#                       p_type_ind   (Type of account required -
#                                      "1" = Can Be Normal Transaction
#                                      "2" = Can Be Control Bank
#                                      "3" = Can Be Control Other
#                                      "4" = Is Control Bank
#                       p_verbose_flag ("Y" DISPLAY errors
#                                        "N" No Display
#          returns TRUE IF passed account IS correct FOR p_type_ind
#          returns FALSE OTHERWISE.
########################################################################
FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
	DEFINE p_cmpy               LIKE bank.cmpy_code
	DEFINE p_acct_code       LIKE bank.acct_code ## GL account we are checking
	DEFINE p_verbose_flag    CHAR(1) ## Y Display, N Don't Display
	DEFINE p_type_ind        CHAR(1)
	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_apparms RECORD LIKE apparms.*

#HuHo
	IF p_verbose_flag <> "Y" AND p_verbose_flag <> "N" THEN
		LET p_verbose_flag = "N"
	END IF

   CASE p_type_ind

-----------------------------------------------------------------------------------------------

# COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION = 1
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION # Can NOT be control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF STATUS = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9111, "")9111 Bank Acount Codes must NOT be used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF STATUS = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code
             OR p_acct_code = l_rec_arparms.cash_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF STATUS = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code
             OR p_acct_code = l_rec_apparms.bank_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "") #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "") #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"

         IF STATUS = 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code

            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9218, "") #9218 Inventory Account must NOT be used
               END IF

               RETURN FALSE
            END IF
         END IF

-------------------------------------------------------------------------------------------------------

# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK = 2
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK # Can NOT be non bank control account
         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF STATUS = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "") #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")#9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF STATUS = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")#9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")#9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"
         IF STATUS = 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9218, "")#9218 Inventory Account must NOT be used
               END IF
               RETURN FALSE
            END IF
         END IF

-----------------------------------------------------------------------------------------------

# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER= 3
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER # Can NOT be bank control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"

         IF STATUS = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF STATUS = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9111, "")#9111 Bank Acount Codes must NOT be used
               END IF
               RETURN FALSE
            END IF
         END IF

-----------------------------------------------------------------------------------------------
# COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK = 4

      WHEN COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK # Must Be control bank account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF STATUS = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF STATUS = 0 THEN
               RETURN TRUE
            END IF
         END IF
         IF p_verbose_flag = "Y"
          OR p_verbose_flag IS NULL THEN
            ERROR kandoomsg2("G", 9204, "")#9111 Bank Acount Codes NOT found
         END IF

         RETURN FALSE

   END CASE

   RETURN TRUE
END FUNCTION
########################################################################
# END FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
########################################################################

}
############################################################################
# FUNCTION verify_acct_code(p_cmpy, p_account_code, p_ver_year_num, p_ver_period)
#
# FUNCTION verify_acct_code - Verifies that account exists AND can be used
#                             FOR specified year AND period
#          IF account does NOT pass verification THEN the lookup procedure
#          IS invoked
#
############################################################################
FUNCTION verify_acct_code(p_cmpy, p_account_code, p_ver_year_num, p_ver_period) 
	DEFINE p_cmpy LIKE coa.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_ver_year_num LIKE coa.start_year_num 
	DEFINE p_ver_period LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure ARRAY [10] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		flex_code LIKE account.acct_code 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_chart_num SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_pos_cnt SMALLINT 
	DEFINE l_err_mess CHAR(40) 

	LABEL anothergo: 
	##  get the coa THEN check TO see IF it IS OPEN
	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 


	IF NOT status = notfound THEN 
			CASE 
			WHEN (l_rec_coa.start_year_num > p_ver_year_num) 
				LET l_err_mess = " Account NOT OPEN " 
			WHEN (l_rec_coa.end_year_num < p_ver_year_num) 
				LET l_err_mess = " Account closed " 
			WHEN (l_rec_coa.start_year_num = p_ver_year_num 
				AND l_rec_coa.start_period_num > p_ver_period) 
				LET l_err_mess = " Account NOT OPEN " 
			WHEN (l_rec_coa.end_year_num = p_ver_year_num 
				AND l_rec_coa.end_period_num < p_ver_period) 
				LET l_err_mess = " Account closed " 
			OTHERWISE 
			
				RETURN l_rec_coa.* 
		END CASE 
	END IF 
	# IF problem THEN should we read & DISPLAY the valid flex codes... probably
	# also put the account code thru a reformatter which will
	# be improved with time....

	OPEN WINDOW structurewind with FORM "G147" 
	CALL winDecoration_g("G147") 

	ERROR l_err_mess 
	DECLARE structurecurs CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind != "F" 
	ORDER BY start_num 

	LET l_pos_cnt = 1 
	LET l_idx = 0 

	FOREACH structurecurs 
		LET l_idx = l_idx + 1 
		
		IF l_rec_structure.type_ind = "C" THEN 
			LET l_chart_num = l_rec_structure.start_num 
		END IF
		 
		LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_pos_cnt = l_rec_structure.start_num 
		LET l_end_pos = l_pos_cnt + l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].flex_code = p_account_code[l_pos_cnt, l_end_pos -1] 
	END FOREACH 

	OPTIONS	INSERT KEY f36 

	LET l_cnt = l_idx 
	CALL set_count(l_idx) 
	ERROR kandoomsg2("U", 1006, "")	#1006 " ESC on line TO SELECT - F10 TO Add"
	INPUT ARRAY l_arr_rec_structure WITHOUT DEFAULTS	FROM sr_structure.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","acctwind","input-arr-coa3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" --ON KEY (control-b) 
			LET l_arr_rec_structure[l_idx].flex_code = show_flex(p_cmpy, l_arr_rec_structure[l_idx].start_num ) 
			#DISPLAY l_arr_rec_structure[l_idx].flex_code TO sr_structure[scrn].flex_code
			NEXT FIELD flex_code 

		ON ACTION "SETTINGS" --ON KEY (f10) 
			CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#IF l_idx <= cnt THEN
			#   DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*
			#
			#END IF
			IF l_arr_rec_structure[l_idx].desc_text IS NULL 
			OR l_arr_rec_structure[l_idx].start_num < 0 THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD flex_code 
			# Check the individuals AFTER every row
			# FROM validflex AND the complete AT the end
			# FROM the coa
			IF l_arr_rec_structure[l_idx].start_num != l_chart_num THEN 
				SELECT * INTO l_rec_validflex.* 
				FROM validflex 
				WHERE cmpy_code = p_cmpy 
				AND start_num = l_arr_rec_structure[l_idx].start_num 
				AND flex_code = l_arr_rec_structure[l_idx].flex_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("G", 9018, "") 				#9018 Acct flex code NOT found try window
					NEXT FIELD flex_code 
				END IF 
			END IF 

	END INPUT 

	LET l_idx = arr_curr() 

	CLOSE WINDOW structurewind 

	LET int_flag = 0 

	LET quit_flag = 0 
	# now PREPARE the account code FOR the trip home

	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num = 0 

	LET p_account_code = l_rec_structure.default_text 
	FOR l_idx = 1 TO arr_count() 
		LET l_end_pos = l_arr_rec_structure[l_idx].start_num + l_arr_rec_structure[l_idx].length_num - 1 
		LET l_start_pos = l_arr_rec_structure[l_idx].start_num 
		LET p_account_code[l_start_pos, l_end_pos] = l_arr_rec_structure[l_idx].flex_code 
	END FOR 

	LABEL once_again: 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 
	IF status = notfound THEN 
		ERROR kandoomsg2("G", 9112, "") #9018 Acct code NOT found try window
		SLEEP 3 
		LET p_account_code = show_acct(p_cmpy) 
		IF p_account_code != " " THEN 
			GOTO once_again 
		ELSE 
			RETURN l_rec_coa.* 
		END IF 
	ELSE 
		IF status != notfound THEN 
			CASE 
				WHEN (l_rec_coa.start_year_num > p_ver_year_num) 
					ERROR kandoomsg2("G", 9203, "") 	#9018 "Account NOT OPEN, opening search window"
					SLEEP 3 
					LET p_account_code = show_acct(p_cmpy) 
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
				
				WHEN (l_rec_coa.end_year_num < p_ver_year_num) 
					ERROR kandoomsg2("G", 9203, "") 	#9018 "Account NOT OPEN, opening search window"
					SLEEP 3 
					LET p_account_code = show_acct(p_cmpy) 
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
				
				WHEN (l_rec_coa.start_year_num = p_ver_year_num	AND l_rec_coa.start_period_num > p_ver_period) 
					ERROR kandoomsg2("G", 9203, "") 				#9018 "Account NOT OPEN, opening search window"
					SLEEP 3 
					LET p_account_code = show_acct(p_cmpy) 
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
				
				WHEN (l_rec_coa.end_year_num = p_ver_year_num	AND l_rec_coa.end_period_num < p_ver_period) 
					ERROR kandoomsg2("G", 9203, "") 				#9018 "Account NOT OPEN, opening search window"
					SLEEP 3 
					LET p_account_code = show_acct(p_cmpy) 
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
				OTHERWISE 
					RETURN l_rec_coa.* 
			END CASE 
		END IF 
	END IF 
END FUNCTION 
############################################################################
# END FUNCTION verify_acct_code(p_cmpy, p_account_code, p_ver_year_num, p_ver_period)
############################################################################


########################################################################
# FUNCTION filter_flex(p_filter, p_start_pos)
#
#    flexwind.4gl - show_flex
#                   Window FUNCTION FOR finding validflex records
#                   returns flex_code
# same FUNCTION in flexwind.4gl cc
########################################################################
FUNCTION filter_flex(p_filter, p_start_pos) 
	DEFINE p_filter boolean 
	DEFINE p_start_pos SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arr_rec_validflex DYNAMIC ARRAY OF t_rec_validflex_fc_dt_with_scrollflag 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U", 1001, "") 	#U1001 Enter selection criteria - ESC TO continue

		CONSTRUCT BY NAME l_where_text ON 
			flex_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","acctwind","construct-flex_code") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_validflex.flex_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U", 1002, "") #1002 "Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM validflex ", 
		"WHERE cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" ", 
#!!! ??? we need to reverse this changes after COA flexcode is configured correctly
		#validflex.start_num is of type SMALLINT.. changed sql from string to numeric selection
		"AND start_num = ", 
		p_start_pos, 
		" ", 
	#                       "AND start_num = \"",
	#                       p_start_pos CLIPPED,
	#                       "\" ",
		"AND ", 
		l_where_text clipped, 
		" ", 
		"ORDER BY flex_code" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_validflex FROM l_query_text 
	DECLARE c_validflex CURSOR FOR s_validflex 

	LET l_idx= 0 
	FOREACH c_validflex INTO l_rec_validflex.* 
		LET l_idx=l_idx+ 1 
		LET l_arr_rec_validflex[l_idx].flex_code = l_rec_validflex.flex_code 
		LET l_arr_rec_validflex[l_idx].desc_text = l_rec_validflex.desc_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 
	MESSAGE kandoomsg2("U", 9113, l_arr_rec_validflex.getlength())#U9113l_l_idxrecords selected

	RETURN l_arr_rec_validflex 
END FUNCTION 
########################################################################
# END FUNCTION filter_flex(p_filter, p_start_pos)
########################################################################


########################################################################
# FUNCTION show_flex(p_cmpy, p_start_pos)
#
#    flexwind.4gl - show_flex
#                   Window FUNCTION FOR finding validflex records
#                   returns flex_code
# same FUNCTION in flexwind.4gl cc
########################################################################
FUNCTION show_flex(p_cmpy, p_start_pos) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_start_pos SMALLINT 
	DEFINE l_arr_rec_validflex DYNAMIC ARRAY OF t_rec_validflex_fc_dt_with_scrollflag 
	#	DEFINE l_arr_rec_validflex ARRAY [250] OF
	#		RECORD
	#			scroll_flag        CHAR(1),
	#			flex_code          LIKE validflex.flex_code,
	#			desc_text          LIKE validflex.desc_text
	#      END RECORD
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_idx SMALLINT 
	#DEFINE       scrn               SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPEN WINDOW G129 with FORM "G129" --huho changed FORM FROM g422 TO g129 
	CALL winDecoration_g("G129") 

	CALL filter_flex(false, p_start_pos) RETURNING l_arr_rec_validflex 

	---------------
	{    -- albo KD-1194
	      IF l_idx = 0 THEN
	         LET l_idx = 1
	         INITIALIZE l_arr_rec_vaclidflex[1].* TO NULL
	      END IF
	}
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	MESSAGE kandoomsg2("U", 1006, "")	#U1006 ESC on line TO SELECT - F10 TO Add
	DISPLAY ARRAY l_arr_rec_validflex TO sr_validflex.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","acctwind","input-arr-validflexlist") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_validflex.flex_code = l_arr_rec_validflex[l_idx].flex_code 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL filter_flex(true, p_start_pos) RETURNING l_arr_rec_validflex 


		ON ACTION "SETTINGS" --KEY (f10) 
			CALL run_prog("GZ4", "", "", "", "") 
			CALL filter_flex(false, p_start_pos) RETURNING l_arr_rec_validflex 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW G129 

	RETURN l_rec_validflex.flex_code 
END FUNCTION 
########################################################################
# END FUNCTION show_flex(p_cmpy, p_start_pos)
########################################################################


#
#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - seg_fill
# Purpose - Set up the segment defaults FOR invoicing etc
#


############################################################
# FUNCTION setup_ar_override(p_cmpy, p_kandoouser_sign_on_code, p_tran_ind, p_cust_code, p_ware_code, p_show_flag )
#
##
## This FUNCTION sets up the corrct acct mask in the
## <sales>head.acct_mask_code COLUMN.  This mask IS created by
##
## 1. Create a dummy mask made up of "?"'s        ie: ???-??? = ???-???
## 2. Overlay warehouse type mask TO replace "?"    + 12?-??? = 12?-???
## 3. Overlay customer type mask TO replace "?"     + 45?-456 = 12?-456
## 4. Overlay kandoouser type mask TO replace "?"      + 987-654 = 127-456
## 5. IF show_seg="Y" THEN allow user TO edit mask.           = 127-456
##
## The mask IS used TO overlay the <sales>detl.line_acct_code so sales
## may be directed TO the other cost centres. The IN posting also uses the
## invoicedetl.acct_mask_code so COGS IS recorded in the same way as sales.
##
############################################################
FUNCTION setup_ar_override(p_cmpy, p_kandoouser_sign_on_code, p_tran_ind, p_cust_code, p_ware_code, p_show_flag ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_tran_ind CHAR(2) #not used 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_show_flag LIKE arparms.show_seg_flag 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	#	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_acct_mask_code LIKE invoicehead.acct_override_code 

	#-----------------------------
	# Create starting point
	
	LET l_acct_mask_code = build_mask(
		p_cmpy, 
		COA_MASK_CODE_FULL, #"??????????????????"
		" ")	

	#-----------------------------
	# SELECT & setup warehouse mask
	
	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 

	#----------------------------
	# TO fix any nulls override acct with "?"
	LET l_rec_warehouse.acct_mask_code = build_mask(
		p_cmpy, 
		COA_MASK_CODE_FULL, #"?????????????????????", 
		l_rec_warehouse.acct_mask_code ) 

	LET l_acct_mask_code = build_mask(
		p_cmpy, 
		l_acct_mask_code, 
		l_rec_warehouse.acct_mask_code ) 

	#---------------------------------
	# SELECT & setup customertype mask
	
	SELECT customertype.* INTO l_rec_customertype.* 
	FROM 
		customer, 
		customertype 
	WHERE 
		customer.cmpy_code = p_cmpy 
		AND customer.cust_code = p_cust_code 
		AND customertype.type_code = customer.type_code 
		AND customertype.cmpy_code = customer.cmpy_code 
	
	#-------------------------------------------
	# TO fix any nulls override acct with "?"
	LET l_rec_customertype.acct_mask_code = build_mask(
		p_cmpy, 
		COA_MASK_CODE_FULL, #"?????????????????????" 
		l_rec_customertype.acct_mask_code) 
	
	LET l_acct_mask_code = build_mask(
		p_cmpy, 
		l_acct_mask_code, 
		l_rec_customertype.acct_mask_code ) 
	
	#----------------------------
	# SELECT & setup user mask
	#
	SELECT * INTO l_rec_kandoouser.* 
	FROM kandoouser 
	WHERE cmpy_code = p_cmpy 
	AND sign_on_code = p_kandoouser_sign_on_code 
	
	LET l_rec_kandoouser.acct_mask_code = build_mask(
		p_cmpy, 
		COA_MASK_CODE_FULL, #"?????????????????????", 
		l_rec_kandoouser.acct_mask_code ) 
	
	LET l_acct_mask_code = build_mask(
		p_cmpy, 
		l_acct_mask_code, 
		l_rec_kandoouser.acct_mask_code ) 
	
	#-------------------------------------------------
	## IF configured TO do so - popup window TO allow edit of mask.
	
	IF p_show_flag = "Y" THEN 
		LET l_acct_mask_code = segment_fill(
			p_cmpy, 
			l_acct_mask_code, 
			l_acct_mask_code ) 
		IF int_flag	OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN "" 
		END IF 
	END IF 
	
	RETURN l_acct_mask_code 
END FUNCTION 
#######################################################################
# END FUNCTION setup_ar_override(p_cmpy, p_kandoouser_sign_on_code, p_tran_ind, p_cust_code, p_ware_code, p_show_flag )
#######################################################################


#######################################################################
# FUNCTION segment_fill(p_cmpy, p_mask_code, p_acct_code)
#
#
# JOB 87 - Amendment note
#          This FUNCTION TO be superseded by account_fill
#          Code added TO blank out chart portion of p_acct_code
#          Required as a result of changes TO build_mask
#######################################################################
FUNCTION segment_fill(p_cmpy, p_mask_code, p_acct_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_mask_code LIKE account.acct_code 
	DEFINE p_acct_code LIKE account.acct_code 
	DEFINE l_flex_segment_acct_code LIKE account.acct_code 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure ARRAY [18] OF RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		flex_code LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text, 
		mask_ind SMALLINT 
	END RECORD 
	DEFINE l_arr_rec_flex ARRAY [18] OF	RECORD 
		flex_seg LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_i SMALLINT 
	DEFINE l_idx SMALLINT 
	#DEFINE scrn,
	DEFINE l_flex_length SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_descript_text CHAR(40) 

	OPEN WINDOW U136 with FORM "U136" 
	CALL winDecoration_u("U136") 

	DECLARE structurcurs CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind <> "F" # albo kd-1388 
	ORDER BY start_num 
	LET l_idx = 0 

	FOREACH structurcurs 
		LET l_idx = l_idx + 1 
		LET l_descript_text = l_rec_structure.desc_text clipped,	"...................." 
		LET l_arr_rec_structure[l_idx].desc_text = l_descript_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_start_pos = l_rec_structure.start_num 
		LET l_end_pos = l_start_pos + l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].flex_code = p_acct_code[l_start_pos, l_end_pos -1] 

		IF mask_type(p_mask_code[l_start_pos, l_end_pos -1], l_rec_structure.length_num) = 2 THEN 
			LET l_arr_rec_structure[l_idx].mask_ind = true 
		ELSE 
			LET l_arr_rec_structure[l_idx].mask_ind = false 
		END IF 

		SELECT desc_text INTO l_arr_rec_structure[l_idx].flex_text 
		FROM validflex 
		WHERE cmpy_code = p_cmpy 
		AND start_num = l_start_pos 
		AND flex_code = l_arr_rec_structure[l_idx].flex_code 

		IF status = notfound THEN 
			LET l_arr_rec_structure[l_idx].flex_text = " " 
		END IF 
	END FOREACH 

	DECLARE chartcurs CURSOR FOR 
	SELECT 
		structure.start_num, 
		structure.length_num 
	INTO 
		l_start_pos, 
		l_rec_structure.length_num 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind = "C" 

	FOREACH chartcurs 
		LET l_end_pos = l_start_pos + l_rec_structure.length_num - 1 
		LET p_acct_code[l_start_pos, l_end_pos] = " " 
	END FOREACH 

	DISPLAY p_acct_code TO acct_code 

	FOR l_i = 1 TO 6 
		DISPLAY l_arr_rec_structure[l_i].flex_code TO sr_flex[l_i].flex_seg 
		DISPLAY l_arr_rec_structure[l_i].flex_text TO sr_flex[l_i].flex_text 
	END FOR 

	WHILE true 

		FOR l_i = 1 TO l_idx 
			IF l_arr_rec_structure[l_i].mask_ind THEN 
				LET l_flex_length = l_arr_rec_structure[l_i].length_num 
				LET l_start_pos = 31 + l_arr_rec_structure[l_i].start_num 

				IF mask_type(l_arr_rec_structure[l_i].flex_code, l_arr_rec_structure[l_i].length_num) = 0 THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment_acct_code = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment_acct_code = l_arr_rec_structure[l_i].flex_code[1, l_flex_length] 
				END IF 
				#DISPLAY l_flex_segment_acct_code clipped AT 6, l_start_pos

				DISPLAY BY NAME 
					l_arr_rec_structure[l_i].desc_text, 
					l_arr_rec_structure[l_i].flex_code 


				INPUT BY NAME l_arr_rec_structure[l_i].flex_code WITHOUT DEFAULTS 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","acctwind","input-coa4") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					ON ACTION "LOOKUP" --ON KEY (control-b) 
						LET l_arr_rec_structure[l_i].flex_code = show_flex(p_cmpy, l_arr_rec_structure[l_i].start_num ) 
						DISPLAY l_arr_rec_structure[l_i].flex_code TO validflex.flex_code 
						NEXT FIELD flex_code 

					ON ACTION "GZ4-CONFIG" --ON KEY (f10) 
						CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 
						#                  CALL run_prog("GZ4", l_arr_rec_structure[l_i].start_num, "", "", "")

					AFTER FIELD flex_code 
						IF mask_type(l_arr_rec_structure[l_i].flex_code, l_arr_rec_structure[l_i].length_num ) = 1 THEN 
							SELECT * INTO l_rec_validflex.* 
							FROM validflex 
							WHERE cmpy_code = p_cmpy 
							AND start_num = l_arr_rec_structure[l_i].start_num 
							AND flex_code = l_arr_rec_structure[l_i].flex_code 
							IF status = notfound THEN 
								ERROR kandoomsg2("U", 9105, "") 							#9105 RECORD Not Found - Try Window
								NEXT FIELD flex_code 
							ELSE 
								LET l_arr_rec_structure[l_i].flex_text = l_rec_validflex.desc_text 
							END IF 
						ELSE 
							LET l_flex_segment_acct_code = l_arr_rec_structure[l_i].flex_code[1, l_flex_length] 
							LET l_arr_rec_structure[l_i].flex_code = " " 
							LET l_arr_rec_structure[l_i].flex_code = l_flex_segment_acct_code 
							LET l_arr_rec_structure[l_i].flex_text = " " 
						END IF 

				END INPUT 

				IF int_flag OR quit_flag THEN 
					EXIT WHILE 
				END IF 

				IF mask_type(l_arr_rec_structure[l_i].flex_code, l_arr_rec_structure[l_i].length_num) = 0 
				THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment_acct_code = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment_acct_code = l_arr_rec_structure[l_i].flex_code[1, l_flex_length] 
				END IF 

				#DISPLAY l_flex_segment_acct_code clipped AT 6, l_start_pos
				IF l_idx<= 6 THEN 
					DISPLAY l_arr_rec_structure[l_i].flex_code TO sr_flex[l_i].flex_seg 
					DISPLAY l_arr_rec_structure[l_i].flex_text TO sr_flex[l_i].flex_text 
				END IF 
			END IF 

			LET l_arr_rec_flex[l_i].flex_seg = l_arr_rec_structure[l_i].flex_code 
			LET l_arr_rec_flex[l_i].flex_text = l_arr_rec_structure[l_i].flex_text 
		END FOR 

		DISPLAY " " TO structure.desc_text 
		DISPLAY " " TO validflex.flex_code 

		CALL set_count(l_idx) 
		MESSAGE kandoomsg2("U", 1512, "") #1512 Enter ESC TO continue OR DEL TO Exit
		DISPLAY ARRAY l_arr_rec_flex TO sr_flex.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","acctwind","display-arr-flex-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END DISPLAY 

		IF int_flag 
		OR quit_flag THEN 
		ELSE 
			FOR l_i = 1 TO l_idx 
				LET l_start_pos = l_arr_rec_structure[l_i].start_num 
				LET l_end_pos = l_arr_rec_structure[l_i].start_num + l_arr_rec_structure[l_i].length_num -	1 
				LET p_acct_code[l_start_pos, l_end_pos] = l_arr_rec_structure[l_i].flex_code 
			END FOR 
		END IF 
		EXIT WHILE 

	END WHILE 

	CLOSE WINDOW U136 

	RETURN (p_acct_code) 
END FUNCTION 
#######################################################################
# FUNCTION segment_fill(p_cmpy, p_mask_code, p_acct_code)
#######################################################################


#######################################################################
# FUNCTION account_fill(p_cmpy, p_mask_code, p_acct_code, p_validation_ind, p_mask_desc_text)
#
#
#  This FUNCTION TO supersede segment_fill in future release
#
#
#  Account Entry Validation Indication:
#     1 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION returns a fully resolved valid account
#     2 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account
#     3 - Only Segments may be entered (IF user mask allows),
#         The FUNCTION returns a fully resolved valid account
#     4 - Only Segments may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account
#     5 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account but it
#         will have a valid Chart portion
#
#######################################################################
FUNCTION account_fill(p_cmpy, p_mask_code, p_acct_code, p_validation_ind, p_mask_desc_text ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_mask_code LIKE account.acct_code 
	DEFINE p_acct_code LIKE account.acct_code 
	DEFINE p_validation_ind SMALLINT 
	DEFINE p_mask_desc_text CHAR(40) 

	DEFINE l_test_mask LIKE account.acct_code 

	DEFINE l_test_acct_code LIKE account.acct_code 
	DEFINE l_flex_segment LIKE account.acct_code 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure ARRAY [18] OF RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		type_ind LIKE structure.type_ind, 
		flex_code LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text, 
		mask_ind SMALLINT 
	END RECORD 
	DEFINE l_arr_rec_filler ARRAY [18] OF RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		default_text LIKE structure.default_text 
	END RECORD 
	
	DEFINE l_arr_rec_flex ARRAY [18] OF	RECORD 
		flex_seg LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_fdx SMALLINT 
	#DEFINE scrn,
	DEFINE l_flex_length SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_acct_end SMALLINT 
	DEFINE l_chart_idx SMALLINT 
	DEFINE l_last_seg_start SMALLINT 
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 
	DEFINE l_acct_valid_ind SMALLINT 
	DEFINE l_entry_allowed SMALLINT 
	DEFINE l_descript_text CHAR(40) 
	DEFINE l_field_desc_text CHAR(20) 
	DEFINE l_account_text LIKE coa.desc_text 
	DEFINE l_ans CHAR(1) 

	LET l_entry_allowed = false 
	LET l_chart_idx = 0 
	LET l_idx = 0 
	LET l_fdx = 0 

	OPEN WINDOW U136 with FORM "U136" 
	CALL winDecoration_u("U136") 

	IF p_mask_desc_text != " " THEN 
		LET l_descript_text = p_mask_desc_text clipped, "...................." 
		LET l_field_desc_text = l_descript_text 
		DISPLAY l_field_desc_text TO desc_text 
	END IF 

	#Part 1 Issue reproduction
	DECLARE structcurs CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	ORDER BY start_num 
	
	#Part 2 Issue reproduction

	FOREACH structcurs 
		#Part 3 Issue reproduction - check l_rec_structure

		LET l_start_pos = l_rec_structure.start_num 
		LET l_end_pos = l_start_pos + l_rec_structure.length_num - 1 ; 
		#      DISPLAY "@Debug: l_acct_end l_end_pos=", l_end_pos

		IF l_rec_structure.type_ind = "F" THEN 
			LET l_fdx = l_fdx + 1 
			LET l_arr_rec_filler[l_fdx].start_num = l_rec_structure.start_num 
			LET l_arr_rec_filler[l_fdx].length_num = l_rec_structure.length_num 
			LET l_arr_rec_filler[l_fdx].default_text = l_rec_structure.default_text 
		ELSE 
			IF l_rec_structure.type_ind = "C" 
			AND (p_validation_ind = 3 
			OR p_validation_ind = 4) THEN 
				CONTINUE FOREACH 
			END IF 
			
			LET l_idx = l_idx + 1 
			LET l_descript_text = l_rec_structure.desc_text clipped,		"...................." 
			LET l_arr_rec_structure[l_idx].desc_text = l_descript_text 
			LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
			LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
			LET l_arr_rec_structure[l_idx].type_ind = l_rec_structure.type_ind 
			
			IF l_rec_structure.type_ind = "C" THEN 
				LET l_start_chart = l_start_pos 
				LET l_end_chart = l_end_pos 
				LET l_chart_idx = l_idx 
			END IF
			 
			LET l_arr_rec_structure[l_idx].flex_code = p_acct_code[l_start_pos, l_end_pos] 
			
			IF mask_type(p_mask_code[l_start_pos, l_end_pos], l_rec_structure.length_num) =	2	THEN 
				LET l_arr_rec_structure[l_idx].mask_ind = true 
				LET l_entry_allowed = true 
			ELSE 
				LET l_arr_rec_structure[l_idx].mask_ind = false 
			END IF 
			
			SELECT desc_text INTO l_arr_rec_structure[l_idx].flex_text 
			FROM validflex 
			WHERE cmpy_code = p_cmpy 
			AND start_num = l_start_pos 
			AND flex_code = l_arr_rec_structure[l_idx].flex_code 
			IF status = notfound THEN 
				LET l_arr_rec_structure[l_idx].flex_text = " " 
			END IF 
		END IF 

	END FOREACH 

	LET l_last_seg_start = l_start_pos # the START & END positions OF the 
	LET l_acct_end = l_end_pos # LAST segment are saved FOR later use 

	DISPLAY p_acct_code TO acct_code 
	#DISPLAY "@Debug: l_acct_end l_end_pos=", l_acct_end

	FOR i = 1 TO 6 
		DISPLAY l_arr_rec_structure[i].flex_code TO sr_flex[i].flex_seg 
		DISPLAY l_arr_rec_structure[i].flex_text TO sr_flex[i].flex_text 
	END FOR 

	WHILE true 

		FOR i = 1 TO l_idx 
			IF l_arr_rec_structure[i].mask_ind THEN 
				LET l_flex_length = l_arr_rec_structure[i].length_num 
				LET l_start_pos = 31 + l_arr_rec_structure[i].start_num 
				
				IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i].length_num) = 0 THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
				END IF
				 
				DISPLAY l_flex_segment clipped at 6, l_start_pos 

				DISPLAY BY NAME 
					l_arr_rec_structure[i].desc_text, 
					l_arr_rec_structure[i].flex_code 


				INPUT BY NAME l_arr_rec_structure[i].flex_code WITHOUT DEFAULTS 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","acctwind","input-flex_code") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					ON ACTION "LOOKUP" --ON KEY (control-b) 
						IF l_arr_rec_structure[i].type_ind = "C" THEN 
							LET l_test_mask = p_mask_code
							 
							IF p_mask_code[l_acct_end, l_acct_end] = "?" THEN 
								LET l_test_mask[l_last_seg_start, l_acct_end] = "*" 
							END IF
							 
							LET l_test_acct_code = showuaccts(p_cmpy, l_test_mask) 
							LET l_arr_rec_structure[i].flex_code = l_test_acct_code[l_start_chart,l_end_chart ] 
							DISPLAY l_arr_rec_structure[i].flex_code TO validflex.flex_code 
							NEXT FIELD flex_code 
						ELSE 
							LET l_arr_rec_structure[i].flex_code = show_flex(p_cmpy, l_arr_rec_structure[i] .start_num) 
							DISPLAY l_arr_rec_structure[i].flex_code TO validflex.flex_code 
							NEXT FIELD flex_code 
						END IF 

					ON ACTION "GZ4 CONFIG" --ON KEY (f10) 
						CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 
						#CALL run_prog("GZ4", l_arr_rec_structure[i].start_num, "", "", "")

					AFTER FIELD flex_code 
						IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i].length_num ) = 1 THEN 
							IF l_arr_rec_structure[i].type_ind = "C" THEN 
								
								INITIALIZE l_test_acct_code TO NULL 
								
								LET l_test_acct_code[1, l_acct_end] = "??????????????????" 
								LET l_test_acct_code[l_start_chart, l_end_chart] = l_arr_rec_structure[i] .flex_code 
								
								IF l_test_acct_code[l_acct_end, l_acct_end] = "?" THEN 
									LET l_test_acct_code[l_last_seg_start, l_acct_end] = "*" 
								END IF 
								
								IF NOT matching_accts(p_cmpy, l_test_acct_code) THEN 
									ERROR kandoomsg2("U", 9105, "") 		#9105 RECORD Not Found - Try Window
									NEXT FIELD flex_code 
								ELSE 
									LET l_arr_rec_structure[i].flex_text = " " 
								END IF 
								
							ELSE 
								SELECT * INTO l_rec_validflex.* 
								FROM validflex 
								WHERE cmpy_code = p_cmpy 
								AND start_num = l_arr_rec_structure[i].start_num 
								AND flex_code = l_arr_rec_structure[i].flex_code 
								IF status = notfound THEN 
									ERROR kandoomsg2("U", 9105, "") 								#9105 RECORD Not Found - Try Window
									NEXT FIELD flex_code 
								ELSE 
									LET l_arr_rec_structure[i].flex_text = l_rec_validflex.desc_text 
								END IF 
								
							END IF 
						ELSE 
							IF l_arr_rec_structure[i].type_ind = "C" AND p_validation_ind = 5 THEN 
								ERROR kandoomsg2("U", 9102, "") 				#9102 "Value must be entered"
								NEXT FIELD flex_code 
							END IF 
							
							LET l_flex_segment = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
							LET l_arr_rec_structure[i].flex_code = " " 
							LET l_arr_rec_structure[i].flex_code = l_flex_segment 
							LET l_arr_rec_structure[i].flex_text = " " 
						END IF 


				END INPUT 

				IF int_flag OR quit_flag THEN 
					EXIT WHILE 
				END IF 

				IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i].length_num) = 0 THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
				END IF 
				
				DISPLAY l_flex_segment clipped at 6, l_start_pos
				 
				IF i <= 6 THEN 
					DISPLAY l_arr_rec_structure[i].flex_code TO sr_flex[i].flex_seg 
					DISPLAY l_arr_rec_structure[i].flex_text TO sr_flex[i].flex_text 
				END IF 
				
			END IF 
			
			LET l_arr_rec_flex[i].flex_seg = l_arr_rec_structure[i].flex_code 
			LET l_arr_rec_flex[i].flex_text = l_arr_rec_structure[i].flex_text 
		END FOR 

		LET l_test_acct_code = " " 
		
		IF p_validation_ind = 3 THEN 
			LET l_test_acct_code = p_acct_code 
		ELSE DISPLAY "l_acct_end=", l_acct_end 
			LET l_test_acct_code[1, l_acct_end] = "??????????????????" 
		END IF 

		FOR i = 1 TO l_idx 
			LET l_start_pos = l_arr_rec_structure[i].start_num 
			LET l_end_pos = l_arr_rec_structure[i].start_num + l_arr_rec_structure[i].length_num - 1 
			LET l_test_acct_code[l_start_pos, l_end_pos] = l_arr_rec_structure[i].flex_code 
			LET p_acct_code[l_start_pos, l_end_pos] = l_arr_rec_structure[i].flex_code 
		END FOR 

		FOR i = 1 TO l_fdx 
			LET l_start_pos = l_arr_rec_filler[i].start_num 
			LET l_end_pos = l_arr_rec_filler[i].start_num + l_arr_rec_filler[i].length_num - 1 
			LET l_test_acct_code[l_start_pos, l_end_pos] = l_arr_rec_filler[i].default_text 
			LET p_acct_code[l_start_pos, l_end_pos] = l_arr_rec_filler[i].default_text 
		END FOR 

		IF l_test_acct_code[l_acct_end, l_acct_end] = "?" THEN 
			LET l_test_acct_code[l_last_seg_start, l_acct_end] = "*" 
		END IF 

		CALL validate_acct(p_cmpy, l_test_acct_code) 
		RETURNING 
			l_acct_valid_ind, 
			l_account_text 

		IF l_chart_idx > 0 THEN 
			LET l_arr_rec_flex[l_chart_idx].flex_text = l_account_text 
		END IF 

		IF p_validation_ind = 1 
		OR p_validation_ind = 3 THEN 

			CASE l_acct_valid_ind 
				WHEN 9 
					ERROR kandoomsg2("U", 9910, "") 				#9910 "Record Not Found"
					IF l_entry_allowed THEN 
						CONTINUE WHILE 
					ELSE 
						ERROR kandoomsg2("G", 7028, "") 					#7028 "Valid account required"
						LET int_flag = true 
						LET quit_flag = true 
						EXIT WHILE 
					END IF 

				WHEN 2 
					ERROR kandoomsg2("G", 9525, "") 				#9525 "Cannot disburse TO a bank account"
					IF l_entry_allowed THEN 
						CONTINUE WHILE 
					ELSE 
						ERROR kandoomsg2("G", 7027, "") 					#7027 "This account type NOT allowed"
						LET int_flag = true 
						LET quit_flag = true 
						EXIT WHILE 
					END IF 

			END CASE 

		ELSE 
			IF l_acct_valid_ind = 2 THEN 
				ERROR kandoomsg2("G", 7029, "") 			#7029 "Warning: This IS a bank account"
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		DISPLAY " " TO structure.desc_text 
		DISPLAY " " TO validflex.flex_code 

		CALL set_count(l_idx) 

		IF l_entry_allowed THEN 
			ERROR kandoomsg2("U", 1032, "") 		#1032 ESC on line TO accept - DEL TO re-enter
		ELSE 
			ERROR kandoomsg2("U", 1034, "") 		#1034 Press ESC on line TO accept
		END IF 
		
		DISPLAY ARRAY l_arr_rec_flex TO sr_flex.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","acctwind","display-arr-flex-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END DISPLAY 

		IF (int_flag OR quit_flag)	AND l_entry_allowed THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 

	CLOSE WINDOW U136 

	RETURN 
		p_acct_code, 
		l_account_text, 
		l_entry_allowed 
END FUNCTION 
#######################################################################
# FUNCTION account_fill(p_cmpy, p_mask_code, p_acct_code, p_validation_ind, p_mask_desc_text)
#######################################################################


#######################################################################
# FUNCTION build_mask(p_cmpy, p_mask, p_override)
#
#
#######################################################################
FUNCTION build_mask(p_cmpy, p_mask, p_override) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_mask LIKE account.acct_code 
	DEFINE p_override LIKE account.acct_code 
	DEFINE l_acct_code LIKE account.acct_code 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_mtype SMALLINT 

	DECLARE struct_cur CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 

	FOREACH struct_cur 
		LET i = l_rec_structure.start_num 
		LET j = l_rec_structure.length_num 

		CASE 
			WHEN l_rec_structure.type_ind = "F" 
				LET l_acct_code[i, i + j -1] = l_rec_structure.default_text 

			OTHERWISE 
				LET l_mtype = mask_type(p_mask[i, i + j -1], j) 
				CASE 
					WHEN l_mtype = 1 
						LET l_acct_code[i, i + j -1] = p_mask[i, i + j -1] 

					WHEN l_mtype = 0 
						LET l_acct_code[i, i + j -1] = p_override[i, i + j -1] 

					OTHERWISE 
						LET l_mtype = mask_type(p_override[i, i + j -1], j) 

						CASE 
							WHEN l_mtype = 1 
								LET l_acct_code[i, i + j -1] = p_override[i, i + j -1] 

							OTHERWISE 
								LET l_acct_code[i, i + j -1] = p_mask[i, i + j -1] 
						END CASE 
				END CASE 
		END CASE 

	END FOREACH 

	RETURN (l_acct_code) 
END FUNCTION 
#######################################################################
# END FUNCTION build_mask(p_cmpy, p_mask, p_override)
#######################################################################


#######################################################################
# FUNCTION mask_type(p_seg_code, p_len)
#
#
#######################################################################
FUNCTION mask_type(p_seg_code, p_len) 
	DEFINE p_seg_code LIKE account.acct_code 
	DEFINE p_len SMALLINT 
	DEFINE l_blank SMALLINT 
	DEFINE l_question_mark SMALLINT 
	DEFINE l_idx SMALLINT 

	LET l_blank = true 
	LET l_question_mark = true 
	
	IF p_seg_code IS NULL THEN 
		RETURN (0) 
	END IF 
	
	FOR l_idx = 1 TO p_len 
		IF p_seg_code[l_idx, l_idx] != " " THEN 
			LET l_blank = false 
		END IF 
		IF p_seg_code[l_idx, l_idx] != "?" THEN 
			LET l_question_mark = false 
		END IF 
	END FOR 
	
	IF l_blank THEN 
		RETURN (0) 
	END IF 
	
	IF l_question_mark THEN 
		RETURN (2) 
	END IF 
	
	RETURN (1) 
END FUNCTION 
#######################################################################
# END FUNCTION mask_type(p_seg_code, p_len)
#######################################################################


#######################################################################
# FUNCTION validate_acct(p_cmpy_code, p_acct_code)
#
#
#######################################################################
FUNCTION validate_acct(p_cmpy_code, p_acct_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE coa.acct_code 

	DEFINE i SMALLINT 
	DEFINE l_valid_acct_flag SMALLINT 
	DEFINE l_acct_descript LIKE coa.desc_text 

	SELECT coa.desc_text INTO l_acct_descript 
	FROM coa 
	WHERE coa.cmpy_code = p_cmpy_code 
	AND coa.acct_code = p_acct_code 
	IF status = notfound THEN 
		LET l_valid_acct_flag = 9 
		LET l_acct_descript = " " 
	ELSE 
		SELECT count(*)INTO i 
		FROM bank 
		WHERE bank.cmpy_code = p_cmpy_code 
		AND bank.acct_code = p_acct_code 
		IF i = 0 THEN 
			LET l_valid_acct_flag = 1 
		ELSE 
			LET l_valid_acct_flag = 2 
		END IF 
	END IF 
	
	RETURN 
		l_valid_acct_flag, 
		l_acct_descript 
END FUNCTION 
#######################################################################
# END FUNCTION validate_acct(p_cmpy_code, p_acct_code)
#######################################################################


#######################################################################
# FUNCTION matching_accts(p_cmpy, p_acct_code)
#
#
#######################################################################
FUNCTION matching_accts(p_cmpy, p_acct_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE l_acct_found SMALLINT 
	DEFINE l_row INTEGER 

	LET l_acct_found = false 
	DECLARE c_coa CURSOR FOR 

	SELECT rowid 
	FROM coa 
	WHERE coa.cmpy_code = p_cmpy 
	AND coa.acct_code matches p_acct_code 

	FOREACH c_coa INTO l_row 
		LET l_acct_found = true 
		EXIT FOREACH 
	END FOREACH 
	
	RETURN (l_acct_found) 
END FUNCTION 
#  Copied FROM account_fill ()
#######################################################################
# END FUNCTION matching_accts(p_cmpy, p_acct_code)
#######################################################################


#######################################################################
# FUNCTION acct_fill(p_cmpy, p_kandoouser_sign_on_code, p_prog, p_mask_code, p_acct_code, p_validation_ind,        p_mask_desc_text )
#
#
#  This FUNCTION TO supersede account_fill in future release
#
#
#  Account Entry Validation Indication:
#     1 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION returns a fully resolved valid account
#     2 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account
#     3 - Only Segments may be entered (IF user mask allows),
#         The FUNCTION returns a fully resolved valid account
#     4 - Only Segments may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account
#     5 - All Segments & Charts may be entered (IF user mask allows),
#         The FUNCTION may RETURN an unresolved account but it
#         will have a valid Chart portion
#
#######################################################################
FUNCTION acct_fill(p_cmpy, p_kandoouser_sign_on_code, p_prog, p_mask_code, p_acct_code, p_validation_ind, p_mask_desc_text ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_prog CHAR(3) 
	DEFINE p_mask_code LIKE account.acct_code 
	DEFINE p_acct_code LIKE account.acct_code 
	DEFINE p_validation_ind SMALLINT 
	DEFINE p_mask_desc_text SMALLINT 
	DEFINE l_test_mask LIKE account.acct_code 
	DEFINE l_test_acct_code LIKE account.acct_code 
	DEFINE l_in_acct_code LIKE account.acct_code 
	DEFINE l_flex_segment_acct_code LIKE account.acct_code 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure ARRAY [18] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		type_ind LIKE structure.type_ind, 
		flex_code LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text, 
		mask_ind SMALLINT 
	END RECORD 
	DEFINE l_arr_pa_filler ARRAY [18] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		default_text LIKE structure.default_text 
	END RECORD 
	DEFINE l_arr_rec_flex ARRAY [18] OF 
	RECORD 
		flex_seg LIKE account.acct_code, 
		flex_text LIKE validflex.desc_text 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_fdx SMALLINT 
	#DEFINE scrn,
	DEFINE l_flex_length SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_acct_end SMALLINT 
	DEFINE l_chart_idx SMALLINT 
	DEFINE l_last_seg_start SMALLINT 
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 
	DEFINE l_acct_valid_ind SMALLINT 
	DEFINE l_entry_allowed SMALLINT 
	DEFINE l_descript_text CHAR(40) 
	DEFINE l_field_desc_text CHAR(20) 
	DEFINE l_account_text LIKE coa.desc_text 
	#DEFINE l_ans                CHAR(1) #not used
	#DEFINE l_runner             CHAR(50) #not used

	LET l_entry_allowed = false 
	LET l_chart_idx = 0 
	LET l_idx = 0 
	LET l_fdx = 0 

	OPEN WINDOW U136 with FORM "U136" 
	CALL winDecoration_u("U136") 

	IF p_mask_desc_text != " " THEN 
		LET l_descript_text = p_mask_desc_text clipped,	"...................." 
		LET l_field_desc_text = l_descript_text 
		DISPLAY l_field_desc_text at 6, 11 
	END IF 

	LET l_in_acct_code = p_acct_code #2687 

	DECLARE c_struct CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	ORDER BY start_num 

	FOREACH c_struct 
		LET l_start_pos = l_rec_structure.start_num 
		LET l_end_pos = l_start_pos + l_rec_structure.length_num - 1 

		IF l_rec_structure.type_ind = "F" THEN 
			LET l_fdx = l_fdx + 1 
			LET l_arr_pa_filler[l_fdx].start_num = l_rec_structure.start_num 
			LET l_arr_pa_filler[l_fdx].length_num = l_rec_structure.length_num 
			LET l_arr_pa_filler[l_fdx].default_text = l_rec_structure.default_text 
		ELSE 
			IF l_rec_structure.type_ind = "C" 
			AND (p_validation_ind = 3 
			OR p_validation_ind = 4) THEN 
				CONTINUE FOREACH 
			END IF
			 
			LET l_idx = l_idx + 1 
			LET l_descript_text = l_rec_structure.desc_text clipped,			"...................." 
			LET l_arr_rec_structure[l_idx].desc_text = l_descript_text 
			LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
			LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
			LET l_arr_rec_structure[l_idx].type_ind = l_rec_structure.type_ind
			 
			IF l_rec_structure.type_ind = "C" THEN 
				LET l_start_chart = l_start_pos 
				LET l_end_chart = l_end_pos 
				LET l_chart_idx = l_idx 
			END IF
			 
			LET l_arr_rec_structure[l_idx].flex_code = p_acct_code[l_start_pos, l_end_pos] 

			IF mask_type(p_mask_code[l_start_pos, l_end_pos], l_rec_structure.length_num) =	2	THEN 
				LET l_arr_rec_structure[l_idx].mask_ind = true 
				LET l_entry_allowed = true 
			ELSE 
				LET l_arr_rec_structure[l_idx].mask_ind = false 
			END IF 

			SELECT desc_text INTO l_arr_rec_structure[l_idx].flex_text 
			FROM validflex 
			WHERE cmpy_code = p_cmpy 
			AND start_num = l_start_pos 
			AND flex_code = l_arr_rec_structure[l_idx].flex_code 
			IF status = notfound THEN 
				LET l_arr_rec_structure[l_idx].flex_text = " " 
			END IF 

		END IF 

	END FOREACH 

	LET l_last_seg_start = l_start_pos # the START & END positions OF the 
	LET l_acct_end = l_end_pos # LAST segment are saved FOR later use 

	DISPLAY p_acct_code TO acct_code 

	FOR i = 1 TO 6 
		DISPLAY l_arr_rec_structure[i].flex_code TO sr_flex[i].flex_seg 
		DISPLAY l_arr_rec_structure[i].flex_text TO sr_flex[i].flex_text 
	END FOR 

	WHILE true 

		FOR i = 1 TO l_idx 
			IF l_arr_rec_structure[i].mask_ind THEN 
				LET l_flex_length = l_arr_rec_structure[i].length_num 
				LET l_start_pos = 31 + l_arr_rec_structure[i].start_num 
				
				IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i].length_num)	= 0 THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment_acct_code = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment_acct_code = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
				END IF
				 
				DISPLAY l_flex_segment_acct_code TO validflex.flex_code 

				DISPLAY BY NAME 
					l_arr_rec_structure[i].desc_text, 
					l_arr_rec_structure[i].flex_code 

				INPUT BY NAME l_arr_rec_structure[i].flex_code WITHOUT DEFAULTS 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","acctwind","input-structure-2") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					ON ACTION "LOOKUP" --ON KEY (control-b) 
						IF l_arr_rec_structure[i].type_ind = "C" THEN 
							LET l_test_mask = p_mask_code 

							IF p_mask_code[l_acct_end, l_acct_end] = "?" THEN 
								LET l_test_mask[l_last_seg_start, l_acct_end] = "*" 
							END IF 

							LET l_test_acct_code = showuaccts(p_cmpy, l_test_mask) 
							LET l_arr_rec_structure[i].flex_code = l_test_acct_code[l_start_chart,	l_end_chart ] 
							DISPLAY l_arr_rec_structure[i].flex_code TO validflex.flex_code 
							NEXT FIELD flex_code 
						ELSE 
							LET l_arr_rec_structure[i].flex_code = show_flex(p_cmpy, l_arr_rec_structure[i] .start_num) 
							DISPLAY l_arr_rec_structure[i].flex_code TO validflex.flex_code 
							NEXT FIELD flex_code 
						END IF 

					ON ACTION "GZ4-CONFIG" --ON KEY (f10) 
						CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 
						#                  CALL run_p_prog("GZ4", l_arr_rec_structure[i].start_num , "", "", "")

					AFTER FIELD flex_code 
						IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i]	.length_num ) = 1 THEN 
							IF l_arr_rec_structure[i].type_ind = "C" THEN 
								INITIALIZE l_test_acct_code TO NULL 
								LET l_test_acct_code[1, l_acct_end] = "??????????????????" 
								LET l_test_acct_code[l_start_chart, l_end_chart] = l_arr_rec_structure[i] .flex_code 
								
								IF l_test_acct_code[l_acct_end, l_acct_end] = "?" THEN 
									LET l_test_acct_code[l_last_seg_start, l_acct_end] = "*" 
								END IF 
								
								IF NOT matching_accts(p_cmpy, l_test_acct_code) THEN 
									ERROR kandoomsg2("U",9935,"") 								#9935 " Code does NOT Exist - Try Window "
									NEXT FIELD flex_code 
								ELSE 
									LET l_arr_rec_structure[i].flex_text = " " 
								END IF 
								
							ELSE
							 
								SELECT * INTO l_rec_validflex.* 
								FROM validflex 
								WHERE cmpy_code = p_cmpy 
								AND start_num = l_arr_rec_structure[i].start_num 
								AND flex_code = l_arr_rec_structure[i].flex_code 
								IF status = notfound THEN 
									ERROR kandoomsg2("U",9935,"")						#9935 " Code does NOT Exist - Try Window "
									NEXT FIELD flex_code 
								ELSE 
									LET l_arr_rec_structure[i].flex_text = l_rec_validflex.desc_text 
								END IF 
								
							END IF
							 
						ELSE 
							IF l_arr_rec_structure[i].type_ind = "C"	AND p_validation_ind = 5 THEN 
								ERROR kandoomsg2("G",9519,"") 				#9519 " Code does NOT Exist - Try Window "
								NEXT FIELD flex_code 
							END IF 

							LET l_flex_segment_acct_code = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
							LET l_arr_rec_structure[i].flex_code = " " 
							LET l_arr_rec_structure[i].flex_code = l_flex_segment_acct_code 
							LET l_arr_rec_structure[i].flex_text = " " 
						END IF 

				END INPUT 

				IF int_flag	OR quit_flag THEN 
					LET p_acct_code = l_in_acct_code 
					EXIT WHILE 
				END IF 

				IF mask_type(l_arr_rec_structure[i].flex_code, l_arr_rec_structure[i].length_num) = 0	THEN 
					LET l_descript_text = "__________________" 
					LET l_flex_segment_acct_code = l_descript_text[1, l_flex_length] 
				ELSE 
					LET l_flex_segment_acct_code = l_arr_rec_structure[i].flex_code[1, l_flex_length] 
				END IF 

				DISPLAY l_flex_segment_acct_code TO validflex.flex_code 
				IF i <= 6 THEN 
					DISPLAY l_arr_rec_structure[i].flex_code TO sr_flex[i].flex_seg 
					DISPLAY l_arr_rec_structure[i].flex_text TO sr_flex[i].flex_text 
				END IF 
			ELSE 
				ERROR kandoomsg2("U",9949,"")	#9949 "Can't edit - see job type code on menu JZ4"
			END IF 

			LET l_arr_rec_flex[i].flex_seg = l_arr_rec_structure[i].flex_code 
			LET l_arr_rec_flex[i].flex_text = l_arr_rec_structure[i].flex_text 

		END FOR 

		LET l_test_acct_code = " " 
		IF p_validation_ind = 3 THEN 
			LET l_test_acct_code = p_acct_code 
		ELSE 
			LET l_test_acct_code[1, l_acct_end] = "??????????????????" 
		END IF 

		FOR i = 1 TO l_idx 
			LET l_start_pos = l_arr_rec_structure[i].start_num 
			LET l_end_pos = l_arr_rec_structure[i].start_num + l_arr_rec_structure[i].length_num - 1 
			LET l_test_acct_code[l_start_pos, l_end_pos] = l_arr_rec_structure[i].flex_code 
			LET p_acct_code[l_start_pos, l_end_pos] = l_arr_rec_structure[i].flex_code 
		END FOR 

		FOR i = 1 TO l_fdx 
			LET l_start_pos = l_arr_pa_filler[i].start_num 
			LET l_end_pos = l_arr_pa_filler[i].start_num + l_arr_pa_filler[i].length_num - 1 
			LET l_test_acct_code[l_start_pos, l_end_pos] = l_arr_pa_filler[i].default_text 
			LET p_acct_code[l_start_pos, l_end_pos] = l_arr_pa_filler[i].default_text 
		END FOR 

		IF l_test_acct_code[l_acct_end, l_acct_end] = "?" THEN 
			LET l_test_acct_code[l_last_seg_start, l_acct_end] = "*" 
		END IF 

		CALL validate_acct(p_cmpy, l_test_acct_code) 
		RETURNING 
			l_acct_valid_ind, 
			l_account_text 

		IF l_chart_idx > 0 THEN 
			LET l_arr_rec_flex[l_chart_idx].flex_text = l_account_text 
		END IF 

		IF NOT verify_mask_access(p_cmpy, p_kandoouser_sign_on_code, p_prog, "1", l_test_acct_code) THEN 
			ERROR kandoomsg2("U",9941,"") 	#9941 "Access denied TO account mask structure"
			IF l_entry_allowed THEN 
				CONTINUE WHILE 
			ELSE 
				ERROR kandoomsg2("U",7102,"") 			#No further entry allowed
				LET int_flag = true 
				LET quit_flag = true 
				EXIT WHILE 
			END IF 
		END IF 

		IF p_validation_ind = 1	OR p_validation_ind = 3 THEN 

			CASE l_acct_valid_ind 
				WHEN 9 
					ERROR kandoomsg2("G",9031,"") 
					IF l_entry_allowed THEN 
						CONTINUE WHILE 
					ELSE 
						ERROR kandoomsg2("U",7103,"") 					#7103 " Valid account required - any key TO quit"
						LET int_flag = true 
						LET quit_flag = true 
						EXIT WHILE 
					END IF 

				WHEN 2 
					ERROR kandoomsg2("G",9525,"") 				#9525 "Cannot disburse TO a bank account"
					IF l_entry_allowed THEN 
						CONTINUE WHILE 
					ELSE 
						ERROR kandoomsg2("U",7103,"") 					#7103 " Valid account required - any key TO quit"
						LET int_flag = true 
						LET quit_flag = true 
						EXIT WHILE 
					END IF 
			END CASE 

		ELSE 
			IF l_acct_valid_ind = 2 THEN 
				ERROR kandoomsg2("G",9525,"") 			#9525 "Cannot disburse TO a bank account"
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		DISPLAY " " TO structure.desc_text 
		DISPLAY " " TO validflex.flex_code 

		CALL set_count(l_idx) 
		IF l_entry_allowed THEN 
			ERROR kandoomsg2("U",1111,"") 	#OK TO accept, Cancel TO re enter
		ELSE 
			ERROR kandoomsg2("U",1032,"") 	#OK TO accept
		END IF 

		DISPLAY ARRAY l_arr_rec_flex TO sr_flex.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","acctwind","display-arr-flex-3") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		IF (int_flag OR quit_flag) AND l_entry_allowed THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 
		
		EXIT WHILE 
	END WHILE 

	CLOSE WINDOW U136 

	RETURN 
		p_acct_code, 
		l_account_text, 
		l_entry_allowed 
END FUNCTION 
#######################################################################
# FUNCTION acct_fill(p_cmpy, p_kandoouser_sign_on_code, p_prog, p_mask_code, p_acct_code, p_validation_ind,        p_mask_desc_text )
#######################################################################


#######################################################################
# FUNCTION verify_mask_access(p_cmpy, p_kandoouser_sign_on_code, p_fv_prog_name, p_fv_access_code,       p_fv_acct_code )
#
#
#######################################################################
FUNCTION verify_mask_access(p_cmpy, p_kandoouser_sign_on_code, p_fv_prog_name, p_fv_access_code, p_fv_acct_code ) 
	DEFINE p_cmpy LIKE coa.cmpy_code 
	DEFINE p_kandoouser_sign_on_code CHAR(8) 
	DEFINE p_fv_prog_name CHAR(3) 
	DEFINE p_fv_access_code CHAR(1) 
	DEFINE p_fv_acct_code LIKE coa.acct_code 
	DEFINE l_fv_module_code CHAR(1) 
	#DEFINE l_fv_acct_mask_code  LIKE kandoomask.acct_mask_code #not used
	DEFINE l_rec_kandoomask RECORD LIKE kandoomask.* 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	#DEFINE l_fv_rowid           INTEGER
	DEFINE i SMALLINT 
	DEFINE l_fv_found_flag SMALLINT 
	DEFINE l_fv_valid_flag SMALLINT 
	#DEFINE l_test_text          CHAR(512) #not used

	LET l_fv_valid_flag = false 
	LET l_fv_found_flag = false 
	LET l_fv_module_code = p_fv_prog_name[1, 1] 

	DECLARE c_kandoomask CURSOR FOR 
	SELECT * INTO l_rec_kandoomask.* 
	FROM kandoomask 
	WHERE cmpy_code = p_cmpy 
	AND user_code = p_kandoouser_sign_on_code 
	AND module_code = l_fv_module_code 

	FOREACH c_kandoomask 
		LET l_fv_valid_flag = false 
		LET l_fv_found_flag = true 
		IF p_fv_access_code = "3" 
		OR l_rec_kandoomask.access_type_code = "3" 
		OR l_rec_kandoomask.access_type_code = p_fv_access_code THEN 

			FOR i = 1 TO length(p_fv_acct_code) 
				IF l_rec_kandoomask.acct_mask_code[i, i] = "?" 
				OR p_fv_acct_code[i, i] = l_rec_kandoomask.acct_mask_code[i, i] THEN 
					LET l_fv_valid_flag = true 
				ELSE 
					LET l_fv_valid_flag = false 
					EXIT FOR 
				END IF 
			END FOR 

			IF l_fv_valid_flag THEN 
				RETURN l_fv_valid_flag 
			END IF 
		END IF 
	END FOREACH 

	IF NOT l_fv_found_flag THEN 
		SELECT * INTO l_rec_kandoouser.* 
		FROM kandoouser 
		WHERE sign_on_code = p_kandoouser_sign_on_code 

		FOR i = 1 TO length(l_rec_kandoouser.acct_mask_code) 
			IF l_rec_kandoouser.acct_mask_code[i, i] = "?" 
			OR p_fv_acct_code[i, i] = l_rec_kandoouser.acct_mask_code[i, i] THEN 
				LET l_fv_valid_flag = true 
			ELSE 
				LET l_fv_valid_flag = false 
				EXIT FOR 
			END IF 
		END FOR 

	END IF 

	RETURN l_fv_valid_flag 
END FUNCTION { verify_mask_access } 
#######################################################################
# END FUNCTION verify_mask_access(p_cmpy, p_kandoouser_sign_on_code, p_fv_prog_name, p_fv_access_code,       p_fv_acct_code )
#######################################################################


#######################################################################
# FUNCTION v_acct_code(p_cmpy, p_kandoouser_sign_on_code, p_prg_name, p_account_code,
#                     p_ver_year_num, p_ver_period )
#
#
#######################################################################
FUNCTION v_acct_code(p_cmpy, p_kandoouser_sign_on_code, p_prg_name, p_account_code, p_ver_year_num, p_ver_period ) 
	DEFINE p_cmpy LIKE coa.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_ver_year_num LIKE coa.start_year_num 
	DEFINE p_ver_period LIKE coa.start_period_num
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_prg_name CHAR(3) 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure ARRAY [10] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		flex_code LIKE account.acct_code 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_chart_num SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_pos_cnt SMALLINT 
	#DEFINE l_runner CHAR(40) #not used
	DEFINE l_err_mess CHAR(40) 
	DEFINE l_cnt SMALLINT 
	#DEFINE scrn               SMALLINT

	IF p_account_code IS NOT NULL THEN 
		IF NOT verify_mask_access(p_cmpy, p_kandoouser_sign_on_code, p_prg_name, "1", p_account_code) THEN 

			ERROR kandoomsg2("U", 9204, " ") 

			LET l_rec_coa.acct_code = NULL 
			LET l_rec_coa.desc_text = NULL 
			RETURN l_rec_coa.* 
		END IF 
	END IF 

	LABEL anothergo: 
	##  get the coa THEN check TO see IF it IS OPEN
	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 

	IF status != notfound THEN 
		CASE 
			WHEN (l_rec_coa.start_year_num > p_ver_year_num) 
				LET l_err_mess = " Account NOT OPEN " 
			WHEN (l_rec_coa.end_year_num < p_ver_year_num) 
				LET l_err_mess = " Account closed " 
			WHEN (l_rec_coa.start_year_num = p_ver_year_num 
				AND l_rec_coa.start_period_num > p_ver_period) 
				LET l_err_mess = " Account NOT OPEN " 
			WHEN (l_rec_coa.end_year_num = p_ver_year_num 
				AND l_rec_coa.end_period_num < p_ver_period) 
				LET l_err_mess = " Account closed " 
			OTHERWISE 
				RETURN l_rec_coa.* 
		END CASE 
	END IF 
	# IF problem THEN should we read & DISPLAY the valid flex codes... probably
	# also put the account code thru a reformatter which will
	# be improved with time....

	OPEN WINDOW structurewind with FORM "G147" 
	CALL winDecoration_g("G147") 

	ERROR l_err_mess 

	DECLARE structure1curs CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind != "F" 
	ORDER BY start_num 

	LET l_pos_cnt = 1 
	LET l_idx = 0 

	FOREACH structure1curs 
		LET l_idx = l_idx + 1 

		IF l_rec_structure.type_ind = "C" THEN 
			LET l_chart_num = l_rec_structure.start_num 
		END IF 

		LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_pos_cnt = l_rec_structure.start_num 
		LET l_end_pos = l_pos_cnt + l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].flex_code = p_account_code[l_pos_cnt, l_end_pos -1] 
	END FOREACH 

	LET l_cnt = l_idx 
	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("U",1006,"") #1006 "F10 Add, OK TO SELECT"

	INPUT ARRAY l_arr_rec_structure WITHOUT DEFAULTS 
	FROM sr_structure.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","acctwind","input-arr-structure-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" --ON KEY (control-b) 
			LET l_arr_rec_structure[l_idx].flex_code = show_flex(p_cmpy, l_arr_rec_structure[l_idx].start_num ) 
			#DISPLAY l_arr_rec_structure[l_idx].flex_code TO sr_structure[scrn].flex_code
			NEXT FIELD flex_code 

		ON ACTION "RUN-GZ4" --ON KEY (f10) 
			#CALL run_prog("GZ4", l_arr_rec_structure[i].start_num , "", "", "")
			CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#IF l_idx <= l_cnt THEN
			#   DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*
			#
			#END IF
			IF l_arr_rec_structure[l_idx].desc_text IS NULL 
			OR l_arr_rec_structure[l_idx].start_num < 0 THEN 
				EXIT INPUT 
			END IF 

			#AFTER ROW
			#   IF l_idx <= l_cnt THEN
			#      DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*
			#
			#   END IF

		AFTER FIELD flex_code 
			# Check the individuals AFTER every row
			# FROM validflex AND the complete AT the end
			# FROM the coa
			IF l_arr_rec_structure[l_idx].start_num != l_chart_num THEN 
				SELECT * INTO l_rec_validflex.* 
				FROM validflex 
				WHERE cmpy_code = p_cmpy 
				AND start_num = l_arr_rec_structure[l_idx].start_num 
				AND flex_code = l_arr_rec_structure[l_idx].flex_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9935,"") 	#9935 " Cannot find the code, try window"
					NEXT FIELD flex_code 
				END IF 
			END IF 


	END INPUT 

	LET l_idx = arr_curr() 

	CLOSE WINDOW structurewind 

	LET int_flag = 0 

	LET quit_flag = 0 
	# now PREPARE the account code FOR the trip home

	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num = 0 

	LET p_account_code = l_rec_structure.default_text 
	FOR l_idx = 1 TO arr_count() 
		LET l_end_pos = l_arr_rec_structure[l_idx].start_num + l_arr_rec_structure[l_idx].length_num - 1 
		LET l_start_pos = l_arr_rec_structure[l_idx].start_num 
		LET p_account_code[l_start_pos, l_end_pos] = l_arr_rec_structure[l_idx].flex_code 
	END FOR 

	LABEL once_again: 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 

	IF status = notfound THEN 
		ERROR kandoomsg2("G",9203,"") 	#9203 "Account combination NOT found, opening search window"
		LET p_account_code = show_acct(p_cmpy)
		 
		IF p_account_code != " " THEN 
			GOTO once_again 
		ELSE 
			RETURN l_rec_coa.* 
		END IF
		 
	ELSE 
		IF status != notfound THEN 
			CASE 
				WHEN (l_rec_coa.start_year_num > p_ver_year_num) 
					ERROR kandoomsg2("G",9203,"") 			#9203 "Account combination NOT found, opening search window"
					LET p_account_code = show_acct(p_cmpy) 
		
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
					
				WHEN (l_rec_coa.end_year_num < p_ver_year_num) 
					ERROR kandoomsg2("G",9203,"")	#9203 "Account combination NOT found, opening search window"
					LET p_account_code = show_acct(p_cmpy) 
					
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF
					 
				WHEN (l_rec_coa.start_year_num = p_ver_year_num	AND l_rec_coa.start_period_num > p_ver_period) 
					ERROR kandoomsg2("G",9203,"")				#9203 "Account combination NOT found, opening search window"
					LET p_account_code = show_acct(p_cmpy) 
					
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF 
		
				WHEN (l_rec_coa.end_year_num = p_ver_year_num	AND l_rec_coa.end_period_num < p_ver_period) 
					ERROR kandoomsg2("G",9203,"") 				#9203 "Account combination NOT found, opening search window"
					LET p_account_code = show_acct(p_cmpy) 
					IF p_account_code != " " THEN 
						GOTO once_again 
					ELSE 
						# Returning nulls - checking done back in called program
						LET l_rec_coa.acct_code = NULL 
						LET l_rec_coa.desc_text = NULL 
						RETURN l_rec_coa.* 
					END IF
					 
				OTHERWISE 
					RETURN l_rec_coa.* 
			END CASE 
		END IF 
	END IF 

END FUNCTION 
#######################################################################
# END FUNCTION v_acct_code(p_cmpy, p_kandoouser_sign_on_code, p_prg_name, p_account_code,
#######################################################################