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

# \brief module G13 provides Account/detail inquiry facilites FOR foreign
#             AND reporting currencies

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	--	DEFINE glob_arr_rec_account DYNAMIC ARRAY OF RECORD #array[250] OF RECORD
	--		scroll_flag char(1),
	--		cmpy_code LIKE account.cmpy_code,
	--		acct_code LIKE account.acct_code,
	--		year_num LIKE account.year_num,
	--		desc_text LIKE coa.desc_text,
	--		bal_amt char(20)
	--	END RECORD
	DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE glob_fisc_year SMALLINT 
	DEFINE glob_periods SMALLINT 
	DEFINE glob_idx SMALLINT 
	DEFINE glob_scroll_flag char(1) 
END GLOBALS 


###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	CALL setModuleId("G13") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, glob_user_scan_code 

	--	SELECT glparms.* INTO glob_rec_glparms.* FROM glparms
	--	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND glparms.key_code = "1"

	OPEN WINDOW G101 with FORM "G101" 
	CALL windecoration_g("G101") 

	CALL scan_ledg() 

	CLOSE WINDOW G101 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


############################################################
# FUNCTION get_scan_ledg_datasource()
#
#
############################################################
FUNCTION get_scan_ledg_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_account DYNAMIC ARRAY OF RECORD #array[250] OF RECORD 
		scroll_flag char(1), 
		cmpy_code LIKE account.cmpy_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE account.year_num, 
		desc_text LIKE coa.desc_text, 
		bal_amt char(20) 
	END RECORD 

	DEFINE l_idx SMALLINT 
	DEFINE l_where_part STRING
	DEFINE l_query_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("G",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_part ON 
			account.cmpy_code, 
			account.acct_code, 
			account.year_num, 
			coa.desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G13","construct-account") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


				DISPLAY glob_rec_kandoouser.cmpy_code TO account.cmpy_code 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_part = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_part = " 1=1 " 
	END IF 

	LET l_query_text = 
		"SELECT unique account.*,coa.* FROM account, coa WHERE ", 
		l_where_part clipped," ", 
		"AND coa.acct_code = account.acct_code ", 
		"AND coa.cmpy_code = account.cmpy_code ", 
		"AND account.acct_code matches \"", 
		glob_user_scan_code,"\" ", 
		"ORDER BY account.cmpy_code,", 
		"account.acct_code,", 
		"account.year_num" 

	PREPARE ledger FROM l_query_text 
	DECLARE c_ledg SCROLL CURSOR FOR ledger 
	OPEN c_ledg 
	CALL l_arr_rec_account.clear() 

	LET l_idx = 0 
	WHILE 1=1 
		FETCH c_ledg INTO glob_rec_account.*, glob_rec_coa.* 
		IF status = NOTFOUND THEN 
			EXIT WHILE 
		END IF 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_account[l_idx].scroll_flag = NULL 
		LET l_arr_rec_account[l_idx].cmpy_code = glob_rec_account.cmpy_code 
		LET l_arr_rec_account[l_idx].acct_code = glob_rec_account.acct_code 
		LET l_arr_rec_account[l_idx].year_num = glob_rec_account.year_num 
		LET l_arr_rec_account[l_idx].desc_text = glob_rec_coa.desc_text 
		LET l_arr_rec_account[l_idx].bal_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.bal_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 
		#      IF l_idx = 250 THEN
		#         LET l_msgresp = kandoomsg("G",9109,l_idx)
		#         #9109 " First ??? Ledgers Selected Only"
		#         EXIT WHILE
		#      END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT WHILE
		END IF	
	END WHILE 

	IF l_idx = 0 THEN 
		#Informix bug Workaround
		--INITIALIZE l_arr_rec_account[1].* TO NULL 
		LET l_msgresp = kandoomsg("G",9110,"") 	#9110" No ledgers satisfied selection criteria "
	END IF 

	RETURN l_arr_rec_account 
END FUNCTION 
############################################################
# END FUNCTION get_scan_ledg_datasource()
############################################################


############################################################
# FUNCTION scan_ledg()
#
#
############################################################
FUNCTION scan_ledg() 
	DEFINE l_arr_rec_account DYNAMIC ARRAY OF RECORD #array[250] OF RECORD 
		scroll_flag char(1), 
		cmpy_code LIKE account.cmpy_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE account.year_num, 
		desc_text LIKE coa.desc_text, 
		bal_amt char(20) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL l_arr_rec_account.clear() 
	CALL get_scan_ledg_datasource(false) RETURNING l_arr_rec_account 

	--   CALL set_count (glob_idx)
	LET l_msgresp = kandoomsg("G",1007,"")	#1007 F3/F4 - RETURN on line TO View
	--INPUT ARRAY l_arr_rec_account WITHOUT DEFAULTS FROM sr_account.*  ATTRIBUTES(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_account TO sr_account.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G13","input-arr-account") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_account.clear() 
			CALL get_scan_ledg_datasource(true) RETURNING l_arr_rec_account 

		ON ACTION "REFRESH" 
			CALL get_scan_ledg_datasource(false) RETURNING l_arr_rec_account 

		AFTER ROW --fore FIELD scroll_flag 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_idx > 0 THEN 
				LET glob_rec_account.cmpy_code = l_arr_rec_account[glob_idx].cmpy_code 
				LET glob_rec_account.acct_code = l_arr_rec_account[glob_idx].acct_code 
				LET glob_rec_account.year_num = l_arr_rec_account[glob_idx].year_num 
				LET glob_rec_coa.desc_text = l_arr_rec_account[glob_idx].desc_text 
				LET glob_scroll_flag = l_arr_rec_account[glob_idx].scroll_flag 
			END IF 
			--      AFTER FIELD scroll_flag
			--         LET l_arr_rec_account[glob_idx].scroll_flag = glob_scroll_flag
			--         IF fgl_lastkey() = fgl_keyval("down") THEN
			--            IF l_arr_rec_account[glob_idx+1].acct_code IS NULL
			--            OR arr_curr() >= arr_count() THEN
			--               LET l_msgresp=kandoomsg("P",9001,"")
			--               #9001 There no more rows...
			--               NEXT FIELD scroll_flag
			--            END IF
			--         END IF

		ON ACTION ("ACCEPT","DOUBLECLICK","DETAILS") --before FIELD cmpy_code 
			LET glob_idx = arr_curr() 
			IF glob_idx > 0 THEN 
				IF l_arr_rec_account[glob_idx].cmpy_code IS NOT NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
					RETURNING glob_fisc_year, glob_periods 
					CALL get_scan_ledg_datasource(false) RETURNING l_arr_rec_account 
					CALL show_acc(glob_idx) 

				END IF 
			END IF 
			--      NEXT FIELD scroll_flag
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END DISPLAY 

	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION scan_ledg()
############################################################


############################################################
# FUNCTION show_acc(p_idx)
#
#
############################################################
FUNCTION show_acc(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_debit_amt char(20) 
	DEFINE l_credit_amt char(20) 
	DEFINE l_open_amt char(20) 
	DEFINE l_bal_amt char(20) 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	FETCH absolute p_idx c_ledg INTO l_rec_account.*, l_rec_coa.* 
	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = l_rec_account.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		RETURN 
	END IF 

	OPEN WINDOW G196 with FORM "G196" 
	CALL windecoration_g("G196") 

	CALL show_account(l_rec_account.*, 
	l_rec_company.name_text, 
	l_rec_coa.desc_text, 
	glob_rec_glparms.base_currency_code)
	 
	CALL query(l_rec_account.*) 
	CLOSE WINDOW G196
	 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 
############################################################
# END FUNCTION show_acc(p_idx)
############################################################


############################################################
# FUNCTION query(p_rec_account)
#
#
############################################################
FUNCTION query(p_rec_account) 
	DEFINE p_rec_account RECORD LIKE account.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_glob_fisc_year SMALLINT 
	DEFINE l_glob_periods SMALLINT 
	DEFINE l_last_currency LIKE currency.currency_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_last_currency = NULL 
	MENU " account" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G13","menu-account") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Filter Currency"			#      COMMAND "Query" " Search FOR account currency details"
			CALL select_currency(p_rec_account.cmpy_code, l_last_currency) 
			RETURNING l_rec_currency.currency_code 
			
			LET l_last_currency = l_rec_currency.currency_code 
			IF l_rec_currency.currency_code IS NOT NULL THEN 
				
				CALL get_and_disp_acctcurr_rec(p_rec_account.cmpy_code, 
				p_rec_account.acct_code, 
				p_rec_account.year_num, 
				l_rec_currency.currency_code) 
			ELSE 
				CALL get_cmpy_and_parms_detl(p_rec_account.cmpy_code) 
				RETURNING l_rec_company.name_text, glob_rec_glparms.base_currency_code 
				
				CALL show_account(p_rec_account.*, 
				l_rec_company.name_text, 
				l_rec_coa.desc_text, 
				glob_rec_glparms.base_currency_code) 
			END IF 

		ON ACTION "NEXT" 
			#      COMMAND KEY ("N",f21) "Next" " DISPLAY next selected account"
			FETCH NEXT c_ledg INTO p_rec_account.*, l_rec_coa.* 
			IF status != NOTFOUND THEN 
				CALL get_cmpy_and_parms_detl(p_rec_account.cmpy_code) 
				RETURNING l_rec_company.name_text, glob_rec_glparms.base_currency_code 
				LET l_rec_currency.currency_code = NULL 
				CALL show_account(p_rec_account.*, 
				l_rec_company.name_text, 
				l_rec_coa.desc_text, 
				glob_rec_glparms.base_currency_code) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"") 
			END IF 

		ON ACTION "PREVIOUS"			#      COMMAND "Prior" " DISPLAY prior selected account"
			FETCH previous c_ledg INTO p_rec_account.*, l_rec_coa.* 
			IF status != NOTFOUND THEN 
				CALL get_cmpy_and_parms_detl(p_rec_account.cmpy_code) 
				RETURNING l_rec_company.name_text, glob_rec_glparms.base_currency_code
				 
				LET l_rec_currency.currency_code = NULL 
				
				CALL show_account(p_rec_account.*, 
				l_rec_company.name_text, 
				l_rec_coa.desc_text, 
				glob_rec_glparms.base_currency_code) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"") 
			END IF 

		ON ACTION "Detail" 
			#COMMAND KEY ("D",f20) "Detail" " View account details"
			CALL db_period_what_period(p_rec_account.cmpy_code, today) 
			RETURNING l_glob_fisc_year, l_glob_periods 
			CALL ac_hist_scan(p_rec_account.cmpy_code, p_rec_account.acct_code, 
			p_rec_account.year_num, l_glob_periods, 
			l_rec_currency.currency_code) 

		ON ACTION "First"		#COMMAND KEY ("F",f18) "First" " DISPLAY first account in the selected list"
			FETCH FIRST c_ledg INTO p_rec_account.*, l_rec_coa.* 
			IF status != NOTFOUND THEN 
				CALL get_cmpy_and_parms_detl(p_rec_account.cmpy_code) 
				RETURNING l_rec_company.name_text, glob_rec_glparms.base_currency_code
				 
				LET l_rec_currency.currency_code = NULL
				 
				CALL show_account(p_rec_account.*, 
				l_rec_company.name_text, 
				l_rec_coa.desc_text, 
				glob_rec_glparms.base_currency_code) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"") 
			END IF 

		ON ACTION "Last"			#COMMAND KEY ("L",f22) "Last" " DISPLAY last account in the selected list"
			FETCH LAST c_ledg INTO p_rec_account.*, l_rec_coa.* 
			IF status != NOTFOUND THEN 
				CALL get_cmpy_and_parms_detl(p_rec_account.cmpy_code) 
				RETURNING l_rec_company.name_text, glob_rec_glparms.base_currency_code
				 
				LET l_rec_currency.currency_code = NULL 
				
				CALL show_account(p_rec_account.*, 
				l_rec_company.name_text, 
				l_rec_coa.desc_text, 
				glob_rec_glparms.base_currency_code) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"") 
			END IF 

		ON ACTION "Summary" 		#COMMAND "Summary" " DISPLAY base currency account summary"
			CALL disp_base_curr_acct_sum(p_rec_account.cmpy_code, 
			p_rec_account.acct_code, 
			p_rec_account.year_num, 
			l_rec_currency.currency_code) 
			RETURNING l_rec_currency.currency_code 
			IF l_rec_currency.currency_code IS NOT NULL 
			AND l_rec_currency.currency_code != " " THEN 
				LET l_last_currency = l_rec_currency.currency_code 
				CALL get_and_disp_acctcurr_rec(p_rec_account.cmpy_code, 
				p_rec_account.acct_code, 
				p_rec_account.year_num, 
				l_rec_currency.currency_code) 
			END IF 

		ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit FROM this enquiry"
			EXIT MENU 

	END MENU 
END FUNCTION 
############################################################
# END FUNCTION query(p_rec_account)
############################################################