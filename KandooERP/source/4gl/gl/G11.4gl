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
#Program G11 allows the user TO inquire on an account ledger
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_where_part STRING 
	DEFINE glob_query_text STRING #char(1050) 
	DEFINE glob_ytd_pre_close_amt char(20) 
	DEFINE glob_bal_amt char(20) 
	DEFINE glob_budg1_amt char(20) 
	DEFINE glob_debit_amt char(20) 
	DEFINE glob_credit_amt char(20) 

	DEFINE glob_budg2_amt char(20) 
	DEFINE glob_budg3_amt char(20) 

	DEFINE glob_budg4_amt char(20) 
	DEFINE glob_budg5_amt char(20) 
	DEFINE glob_budg6_amt char(20) 
	DEFINE glob_open_amt char(20) 

	DEFINE glob_budg1_text char(30) 
	DEFINE glob_budg2_text char(30) 

	DEFINE glob_budg3_text char(30) 
	DEFINE glob_budg4_text char(30) 
	DEFINE glob_budg5_text char(30) 
	DEFINE glob_budg6_text char(30) 

	DEFINE glob_big_bud_text char(70) 
	DEFINE glob_fisc_year SMALLINT 
	DEFINE glob_periods SMALLINT 

	DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 

	DEFINE glob_datasource_exist boolean 
END GLOBALS 


#############################################################################
# MAIN
#
#Program G11 allows the user TO inquire on an account ledger
#############################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("G11") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, glob_user_scan_code 

	OPEN WINDOW g100 with FORM "G100" 
	CALL windecoration_g("G100")
	 
	IF get_debug() THEN
		CALL fgl_winmessage("from HuHo; Check HIDE/SHOW approved","Check if the Approve budget button is shown/hidden depending on the current nominal code / account","info") 
	END IF
	
	CALL query() 
	CLOSE WINDOW G100 
END MAIN 
#############################################################################
# END MAIN
#############################################################################


#############################################################################
# FUNCTION select_them(p_filter)
#
#
#############################################################################
FUNCTION select_them(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_counter SMALLINT 
	DEFINE l_funds_flag char(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	LET l_msgresp = kandoomsg("G",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	IF glob_rec_glparms.budg1_text IS NULL THEN 
		LET glob_budg1_text = "Budget one...................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg1_text clipped, ".............................." 
		LET glob_budg1_text = glob_big_bud_text[1,30] 
	END IF 

	IF glob_rec_glparms.budg2_text IS NULL THEN 
		LET glob_budg2_text = "Budget two...................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg2_text clipped, ".............................." 
		LET glob_budg2_text = glob_big_bud_text[1,30] 
	END IF 

	IF glob_rec_glparms.budg3_text IS NULL THEN 
		LET glob_budg3_text = "Budget three................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg3_text clipped, ".............................." 
		LET glob_budg3_text = glob_big_bud_text[1,30] 
	END IF 

	IF glob_rec_glparms.budg4_text IS NULL THEN 
		LET glob_budg4_text = "Budget four.................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg4_text clipped, ".............................." 
		LET glob_budg4_text = glob_big_bud_text[1,30] 
	END IF 

	IF glob_rec_glparms.budg5_text IS NULL THEN 
		LET glob_budg5_text = "Budget five.................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg5_text clipped, ".............................." 
		LET glob_budg5_text = glob_big_bud_text[1,30] 
	END IF 

	IF glob_rec_glparms.budg6_text IS NULL THEN 
		LET glob_budg6_text = "Budget six..................." 
	ELSE 
		LET glob_big_bud_text = glob_rec_glparms.budg6_text clipped, ".............................." 
		LET glob_budg6_text = glob_big_bud_text[1,30] 
	END IF 

	CLEAR FORM 

	DISPLAY glob_budg1_text TO budg1_text 
	DISPLAY glob_budg2_text TO budg2_text 
	DISPLAY glob_budg3_text TO budg3_text 
	DISPLAY glob_budg4_text TO budg4_text 
	DISPLAY glob_budg5_text TO budg5_text 
	DISPLAY glob_budg6_text TO budg6_text 

	IF p_filter THEN 

		CONSTRUCT BY NAME glob_where_part ON 
			account.cmpy_code, 
			account.acct_code, 
			coa.type_ind, 
			account.year_num, 
			account.open_amt, 
			account.debit_amt, 
			account.credit_amt, 
			account.bal_amt, 
			account.ytd_pre_close_amt, 
			account.stats_qty, 
			coa.uom_code, 
			fundsapproved.limit_amt, 
			fundsapproved.fund_type_ind, 
			account.budg1_amt, 
			account.budg2_amt, 
			account.budg3_amt, 
			account.budg4_amt, 
			account.budg5_amt, 
			account.budg6_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G11","construct-account") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


	ELSE 
		LET glob_where_part = " 1=1 " 
	END IF 

	#---------------------------------------------------------------------------------------------------

	DISPLAY glob_rec_kandoouser.cmpy_code TO account.cmpy_code 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_funds_flag = false 

	FOR l_counter = 1 TO length(glob_where_part) 
		IF glob_where_part[l_counter,l_counter+12] = "fundsapproved" THEN 
			LET l_funds_flag = true 
			EXIT FOR 
		END IF 
	END FOR 

	IF l_funds_flag THEN 
		LET glob_query_text = 
			"SELECT account.*, coa.* ", 
			"FROM account, coa, fundsapproved ", 
			"WHERE coa.acct_code = account.acct_code ", 
			"AND coa.cmpy_code = fundsapproved.cmpy_code ", 
			"AND coa.acct_code = fundsapproved.acct_code " 
	ELSE 
		LET glob_query_text = 
			"SELECT account.*, coa.* ", 
			"FROM account, coa ", 
			"WHERE coa.acct_code = account.acct_code " 
	END IF 

	LET glob_query_text = 
		glob_query_text clipped," ", 
		"AND account.acct_code matches '",glob_user_scan_code,"' ", 
		"AND coa.cmpy_code = account.cmpy_code ", 
		"AND ", glob_where_part clipped, 
		" ORDER BY account.cmpy_code,", 
		"account.acct_code,", 
		"account.year_num" 

	PREPARE statement_1 FROM glob_query_text 
	DECLARE account_set SCROLL CURSOR FOR statement_1 

	OPEN account_set 
	FETCH FIRST account_set INTO glob_rec_account.*, glob_rec_coa.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9110,"")	#9110 No Ledgers satisfied Selection Criteria
		RETURN false 
	ELSE 
		LET glob_datasource_exist = true 
	END IF 

	CALL disp_ledger() 

	RETURN true 
END FUNCTION 
#############################################################################
# END FUNCTION select_them(p_filter)
#############################################################################


#############################################################################
# FUNCTION hide_navigation_menu()
#
# show/hide Record (DB-Cursor) navigation menu items
#############################################################################
FUNCTION hide_navigation_menu() 
	IF glob_datasource_exist = true THEN 
		SHOW option "Next" 
		SHOW option "Previous" 
		SHOW option "Detail" 
		SHOW option "Approved" 
		SHOW option "First" 
		SHOW option "Last" 
	ELSE 
		HIDE option "Next" 
		HIDE option "Previous" 
		HIDE option "Detail" 
		HIDE option "Approved" 
		HIDE option "First" 
		HIDE option "Last" 
	END IF 
END FUNCTION 
#############################################################################
# END FUNCTION hide_navigation_menu()
#############################################################################

#############################################################################
# FUNCTION query()
#
#
#############################################################################
FUNCTION query() 
	DEFINE l_msgresp LIKE language.yes_flag 


	CALL select_them(false) 

	MENU " Account ledger" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G11","menu-query") 
			CALL hide_navigation_menu() 
			IF fundsapproved_get_count(glob_rec_kandoouser.cmpy_code,glob_rec_account.acct_code) THEN 
				SHOW option "Approved" 
				#CALL fgl_dialog_setkeylabel("Approved","Approved")
			ELSE 
				HIDE option "Approved" 
				CALL fgl_dialog_setkeylabel("Approved","") 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " SELECT Criteria FOR Account Ledgers"
			#COMMAND "Query" " SELECT Criteria FOR Account Ledgers"
			IF select_them(true) THEN 
				CALL hide_navigation_menu() 
				#            show option "Next"
				#            show option "Previous"
				#            show option "First"
				#            show option "Last"
				#            show option "Detail"

				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				NEXT option "Next" 
			ELSE 
				CALL hide_navigation_menu() 
				#
				#            hide option "Next"
				#            hide option "Previous"
				#            hide option "First"
				#            hide option "Last"
				#            hide option "Detail"
				#            hide option "Approved"
			END IF 

		ON ACTION "Next" 
			#COMMAND "Next" " DISPLAY next selected account ledger"
			#huho COMMAND KEY ("N",f21) "Next" " DISPLAY next selected account ledger"
			FETCH NEXT account_set INTO glob_rec_account.*, glob_rec_coa.* 
			IF status <> NOTFOUND THEN 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_ledger() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"") 
				#9157 You have reached the END of the entries selected"
				NEXT option "Previous" 
			END IF 

		ON ACTION "Previous" 
			#COMMAND "Previous" " DISPLAY previous selected account ledger"
			#COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected account ledger"
			FETCH previous account_set INTO glob_rec_account.*, glob_rec_coa.* 
			IF status <> NOTFOUND THEN 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_ledger() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected"
				NEXT option "Next" 
			END IF 

		ON ACTION "Detail"		#COMMAND "Detail" " View account ledger details"	#COMMAND KEY ("D",f20) "Detail" " View account ledger details"
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today)	RETURNING glob_fisc_year, glob_periods 
			CALL ac_detl_scan(
				glob_rec_account.cmpy_code, 
				glob_rec_account.acct_code, 
				glob_rec_account.year_num, 
				glob_periods, 
				0) 

		ON ACTION "Approved"			#COMMAND "Approved" " View Approved Funds details"
			IF disp_cab(glob_rec_kandoouser.cmpy_code, glob_rec_coa.acct_code) THEN 
			END IF 

		ON ACTION "First"			#COMMAND "First" " DISPLAY first account ledger in the selected list"		#COMMAND KEY ("F",f18) "First" " DISPLAY first account ledger in the selected list"
			FETCH FIRST account_set INTO glob_rec_account.*, glob_rec_coa.* 
			IF status != NOTFOUND THEN 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 

				CALL disp_ledger() 
			END IF 

			NEXT option "Next" 

		ON ACTION "Last"			#COMMAND "Last" " DISPLAY last account ledger in the selected list"		#COMMAND KEY ("L",f22) "Last" " DISPLAY last account ledger in the selected list"
			FETCH LAST account_set INTO glob_rec_account.*, glob_rec_coa.* 
			SELECT unique(1) FROM fundsapproved 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_coa.acct_code 
			IF status = NOTFOUND THEN 
				HIDE option "Approved" 
			ELSE 
				SHOW option "Approved" 
			END IF 

			CALL disp_ledger() 
			NEXT option "Previous" 

		ON ACTION "REFRESH" 
			CALL select_them(false) 

		ON ACTION "Exit" 		#COMMAND "Exit" " Exit TO menus"		#COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

END FUNCTION 
#############################################################################
# END FUNCTION query()
#############################################################################


#############################################################################
# FUNCTION disp_ledger()
#
#
#############################################################################
FUNCTION disp_ledger() 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_fund_type_desc LIKE kandooword.response_text 

	SELECT * INTO l_rec_fundsapproved.* FROM fundsapproved 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_coa.acct_code 

	IF status = NOTFOUND THEN 
		LET l_rec_fundsapproved.limit_amt = 0 
	ELSE 
		SELECT response_text INTO l_fund_type_desc FROM kandooword 
		WHERE reference_code = l_rec_fundsapproved.fund_type_ind 
		AND reference_text = "fundsapproved.fund_type_ind" 
		IF status = NOTFOUND THEN 
			LET l_fund_type_desc = NULL 
		END IF 
	END IF 

	LET glob_budg1_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg1_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_budg2_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg2_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_budg3_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg3_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 
	
	LET glob_budg4_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg4_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_budg5_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg5_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_budg6_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.budg6_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_bal_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.bal_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_open_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.open_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_ytd_pre_close_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.ytd_pre_close_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

	LET glob_debit_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.debit_amt, 
		glob_rec_coa.type_ind, 
		4) 

	LET glob_credit_amt = ac_form(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.credit_amt, 
		glob_rec_coa.type_ind, 
		4) 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_account.cmpy_code 

	DISPLAY glob_rec_account.cmpy_code TO cmpy_code 
	DISPLAY glob_rec_company.name_text TO name_text 
	DISPLAY glob_rec_account.acct_code TO acct_code 
	DISPLAY glob_rec_coa.desc_text TO desc_text 
	DISPLAY glob_rec_coa.type_ind TO type_ind 
	DISPLAY glob_rec_account.year_num TO year_num 
	DISPLAY glob_open_amt TO open_amt 
	DISPLAY glob_debit_amt TO debit_amt 
	DISPLAY glob_credit_amt TO credit_amt 
	DISPLAY l_rec_fundsapproved.limit_amt TO limit_amt 
	DISPLAY glob_bal_amt TO bal_amt 
	DISPLAY l_rec_fundsapproved.fund_type_ind TO fund_type_ind 
	DISPLAY l_fund_type_desc TO fund_type_desc 
	DISPLAY glob_ytd_pre_close_amt TO ytd_pre_close_amt 
	DISPLAY glob_rec_account.stats_qty TO stats_qty 
	DISPLAY glob_rec_coa.uom_code TO uom_code 
	DISPLAY glob_budg1_amt TO budg1_amt 
	DISPLAY glob_budg2_amt TO budg2_amt 
	DISPLAY glob_budg3_amt TO budg3_amt 
	DISPLAY glob_budg4_amt TO budg4_amt 
	DISPLAY glob_budg5_amt TO budg5_amt 
	DISPLAY glob_budg6_amt TO budg6_amt 

END FUNCTION 
#############################################################################
# END FUNCTION disp_ledger()
#############################################################################