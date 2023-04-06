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

# \brief module G1A allows user TO view Ledger Detail based on any selection

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

#FIXME: pass globals to modular and rename
GLOBALS 
	DEFINE glob_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 
END GLOBALS 


###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, glob_user_scan_code 

	OPEN WINDOW G103 with FORM "G103" 
	CALL windecoration_g("G103") 

	CALL query() 
	CLOSE WINDOW G103 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


############################################################
# FUNCTION select_them(p_filter)
#
#
############################################################
FUNCTION select_them(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_where_part STRING 
	DEFINE l_query_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT l_where_part ON 
			accountledger.acct_code, 
			accountledger.year_num, 
			accountledger.period_num, 
			accountledger.jour_code, 
			accountledger.jour_num, 
			accountledger.jour_seq_num, 
			accountledger.seq_num, 
			accountledger.ref_text, 
			accountledger.desc_text, 
			accountledger.tran_date, 
			accountledger.ref_num, 
			accountledger.debit_amt, 
			accountledger.credit_amt, 
			accountledger.stats_qty, 
			coa.uom_code 
		FROM 
			accountledger.acct_code, 
			accountledger.year_num, 
			accountledger.period_num, 
			accountledger.jour_code, 
			accountledger.jour_num, 
			accountledger.jour_seq_num, 
			accountledger.seq_num, 
			accountledger.ref_text, 
			accountledger.desc_text, 
			accountledger.tran_date, 
			accountledger.ref_num, 
			accountledger.debit_amt, 
			accountledger.credit_amt, 
			accountledger.stats_qty, 
			coa.uom_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G1A","construct-accountledger") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	ELSE 
		LET l_where_part = " 1=1 " 
	END IF 
	LET l_query_text = 
		"SELECT accountledger.* FROM accountledger, coa ", 
		"WHERE accountledger.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND coa.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND coa.acct_code = accountledger.acct_code ", 
		"AND accountledger.acct_code matches '",glob_user_scan_code,"' ", 
		" AND ", l_where_part clipped, 
		" ORDER BY 2,3,4,5" 
	PREPARE statement_1 FROM l_query_text 
	DECLARE accountledger_set SCROLL CURSOR FOR statement_1 

	OPEN accountledger_set 
	FETCH FIRST accountledger_set INTO glob_rec_accountledger.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",9101,"") 
		RETURN false 
	ELSE 
		CALL show_it() 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_them(p_filter)
############################################################


############################################################
# FUNCTION query()
#
#
############################################################
FUNCTION query() 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Ledger detail" 
		BEFORE MENU 
			IF select_them(false) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
			CALL publish_toolbar("kandoo","G1A","menu-ledger-detail") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Filter" 
			#      COMMAND "Query" "Search FOR ledger detail"
			IF select_them(true) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 

		ON ACTION "REFRESH" 
			#      COMMAND "Query" "Search FOR ledger detail"
			IF select_them(false) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 


		ON ACTION "Next" 		#      COMMAND KEY ("N",f21) "Next" "DISPLAY next selected ledger detail"
			FETCH NEXT accountledger_set INTO glob_rec_accountledger.* 
			IF status <> NOTFOUND THEN 
				CALL show_it() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"")			#9157 You have reached the END of the entries selected"
				NEXT option "Previous" 
			END IF 

		ON ACTION "Previous"		#COMMAND KEY ("P",f19) "Previous" "DISPLAY previous selected ledger detail"
			FETCH previous accountledger_set INTO glob_rec_accountledger.* 
			IF status <> NOTFOUND THEN 
				CALL show_it() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"")				#9156 You have reached the start of the entries selected"
			END IF 

		ON ACTION "Detail"		#COMMAND KEY ("D",f20) "Detail" "View ledger details"
			CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, glob_rec_accountledger.jour_num) 

		ON ACTION "First"		#COMMAND KEY ("F",f18) "First" "DISPLAY first  ledger detail in the selected list"
			FETCH FIRST accountledger_set INTO glob_rec_accountledger.* 
			CALL show_it() 
			NEXT option "Next" 

		ON ACTION "Last"	#COMMAND KEY ("L",f22) "Last" "DISPLAY last ledger detail in the selected list"
			FETCH LAST accountledger_set INTO glob_rec_accountledger.* 
			CALL show_it() 
			NEXT option "Previous" 

		ON ACTION "Exit"		#COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu"
			EXIT MENU 

			--      COMMAND KEY (control-w)
			--         CALL kandoohelp("")
	END MENU 
END FUNCTION 
############################################################
# END FUNCTION query()
############################################################


############################################################
# FUNCTION show_it()
#
#
############################################################
FUNCTION show_it() 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	SELECT * INTO l_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_accountledger.cmpy_code 
	AND jour_code = glob_rec_accountledger.jour_code 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_accountledger.cmpy_code 
	AND acct_code = glob_rec_accountledger.acct_code 

	DISPLAY l_rec_coa.desc_text	TO coa.desc_text 
	DISPLAY l_rec_journal.desc_text TO journal.desc_text 
	DISPLAY glob_rec_accountledger.desc_text TO accountledger.desc_text  

	DISPLAY BY NAME 
		glob_rec_accountledger.acct_code, 
		glob_rec_accountledger.year_num, 
		glob_rec_accountledger.period_num, 
		glob_rec_accountledger.seq_num, 
		glob_rec_accountledger.ref_text, 
		glob_rec_accountledger.ref_num, 
		glob_rec_accountledger.tran_date, 
		glob_rec_accountledger.jour_code, 
		glob_rec_accountledger.jour_num, 
		glob_rec_accountledger.jour_seq_num, 
		glob_rec_accountledger.debit_amt, 
		glob_rec_accountledger.credit_amt, 
		glob_rec_accountledger.stats_qty, 
		l_rec_coa.uom_code 

END FUNCTION 
############################################################
# END FUNCTION show_it()
############################################################