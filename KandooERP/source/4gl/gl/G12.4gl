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

# \brief module G12 allows the user view accounts FROM a scan start

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_arr_rec_account DYNAMIC ARRAY OF RECORD #array[250] OF RECORD 
		scroll_flag char(1), 
		cmpy_code LIKE account.cmpy_code, 
		acct_code LIKE account.acct_code, 
		year_num LIKE account.year_num, 
		desc_text LIKE coa.desc_text, 
		bal_amt char(20) 
	END RECORD 
	DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE glob_fisc_year SMALLINT --, scrn 
	DEFINE glob_periods SMALLINT 
	DEFINE glob_idx SMALLINT 
	DEFINE glob_scroll_flag char(1) 
END GLOBALS 


###########################################################################
# MAIN
#
# G12 allows the user view accounts FROM a scan start
###########################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("G12") 
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
	IF NOT get_gl_setup_state() THEN --status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5012,"") 
		#5012 Landed Costing Parameters NOT SET up; Refer Menu LZP.
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW G101 with FORM "G101" 
	CALL windecoration_g("G101") 

	CALL scan_ledg() 
	--	WHILE scan_ledg()
	--	END WHILE

	CLOSE WINDOW G101 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


############################################################
# FUNCTION get_scan_ledg_datasource(p_filter)
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

	DEFINE l_where_part STRING 
	DEFINE l_query_text char(600) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx int 
	IF p_filter = false THEN 
		LET l_where_part = " 1=1 " 
	ELSE 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_part ON 
			account.cmpy_code, 
			account.acct_code, 
			account.year_num, 
			coa.desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G12","construct-account") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			LET l_where_part = " 1=1 " 
		END IF 
	END IF 

	DISPLAY glob_rec_kandoouser.cmpy_code TO account.cmpy_code 
	#END construct

	LET l_query_text = 
		"SELECT unique account.* FROM account, coa WHERE ", 
		l_where_part clipped," ", 
		"AND coa.acct_code = account.acct_code ", 
		"AND coa.cmpy_code = account.cmpy_code ", 
		"AND account.acct_code matches \"", 
		glob_user_scan_code,"\" ", 
		"ORDER BY account.cmpy_code,", 
		"account.acct_code,", 
		"account.year_num" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 Searching database; Please wait.
	PREPARE ledger FROM l_query_text 
	DECLARE c_ledg CURSOR FOR ledger 

	LET l_idx = 0 
	FOREACH c_ledg INTO glob_rec_account.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_account[l_idx].scroll_flag = NULL 
		LET l_arr_rec_account[l_idx].cmpy_code = glob_rec_account.cmpy_code 
		LET l_arr_rec_account[l_idx].acct_code = glob_rec_account.acct_code 
		LET l_arr_rec_account[l_idx].year_num = glob_rec_account.year_num 

		SELECT * INTO glob_rec_coa.* FROM coa 
		WHERE cmpy_code = glob_rec_account.cmpy_code 
		AND acct_code = glob_rec_account.acct_code 

		LET l_arr_rec_account[l_idx].desc_text = glob_rec_coa.desc_text 
		LET l_arr_rec_account[l_idx].bal_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
		glob_rec_account.bal_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 
		--		IF l_idx = 250 THEN
		--			LET l_msgresp = kandoomsg("U",6100,l_idx)
		--			#9109 " First ??? Ledgers Selected Only"
		--			EXIT FOREACH
		--		END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		#INformix bug workaround
		--INITIALIZE l_arr_rec_account[1].* TO NULL 
		LET l_msgresp = kandoomsg("G",9110,"") 	#9110" No ledgers satisfied selection criteria "
	END IF 

	RETURN l_arr_rec_account 
END FUNCTION 
############################################################
# END FUNCTION get_scan_ledg_datasource(p_filter)
############################################################


############################################################
# FUNCTION scan_ledg()
#
#
############################################################
FUNCTION scan_ledg() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL glob_arr_rec_account.clear() 
	CALL get_scan_ledg_datasource(false) RETURNING glob_arr_rec_account 

	--	IF glob_idx = 0 THEN
	--		#INformix bug workaround
	--		INITIALIZE glob_arr_rec_account[1].* TO null
	--		LET l_msgresp = kandoomsg("G",9110,"")
	--		#9110" No ledgers satisfied selection criteria "
	--	END IF

	--   CALL set_count(glob_idx)
	LET l_msgresp = kandoomsg("U",1007,"")	#1007 F3/F4 - RETURN on line TO view
	--INPUT ARRAY glob_arr_rec_account WITHOUT DEFAULTS FROM sr_account.*  ATTRIBUTES(UNBUFFERED)
	DISPLAY ARRAY glob_arr_rec_account TO sr_account.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G12","inp-arr-account") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL glob_arr_rec_account.clear() 
			CALL get_scan_ledg_datasource(true) RETURNING glob_arr_rec_account 

		ON ACTION "REFRESH" 
			CALL get_scan_ledg_datasource(false) RETURNING glob_arr_rec_account 

		BEFORE ROW --field scroll_flag 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_idx > 0 THEN 
				LET glob_rec_account.cmpy_code = glob_arr_rec_account[glob_idx].cmpy_code 
				LET glob_rec_account.acct_code = glob_arr_rec_account[glob_idx].acct_code 
				LET glob_rec_account.year_num = glob_arr_rec_account[glob_idx].year_num 
				LET glob_rec_coa.desc_text = glob_arr_rec_account[glob_idx].desc_text 
				LET glob_scroll_flag = glob_arr_rec_account[glob_idx].scroll_flag 
			END IF 

			--			AFTER FIELD scroll_flag
			--        LET glob_arr_rec_account[glob_idx].scroll_flag = glob_scroll_flag
			--         IF fgl_lastkey() = fgl_keyval("down") THEN
			--            IF glob_arr_rec_account[glob_idx+1].acct_code IS NULL
			--            OR arr_curr() >= arr_count() THEN
			--               LET l_msgresp=kandoomsg("U",9001,"")
			--               #9001 There no more rows...
			--               NEXT FIELD scroll_flag
			--            END IF
			--         END IF

			--		ON ACTION "View"
			--			IF glob_idx > 0 THEN
			--				IF glob_arr_rec_account[glob_idx].cmpy_code is not null THEN
			--					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today)
			--					RETURNING glob_fisc_year, glob_periods
			--					CALL get_scan_ledg_datasource(false)
			--					CALL ac_detl_scan(glob_rec_account.cmpy_code,
			--					glob_rec_account.acct_code,
			--					glob_arr_rec_account[glob_idx].year_num,
			--					glob_periods,
			--					0)
			--					LET int_flag = 0
			--					LET quit_flag = 0
			--				END IF
			--			END IF


		ON ACTION ("ACCEPT","DOUBLECLICK","DETAILS") -- BEFORE FIELD cmpy_code 
			LET glob_idx = arr_curr() 
			IF glob_idx > 0 THEN 
				IF glob_arr_rec_account[glob_idx].cmpy_code IS NOT NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
					RETURNING glob_fisc_year, glob_periods 

					--CALL glob_arr_rec_account.clear()
					--CALL get_scan_ledg_datasource(false) RETURNING glob_arr_rec_account

					CALL ac_detl_scan(glob_rec_account.cmpy_code, 
					glob_rec_account.acct_code, 
					glob_arr_rec_account[glob_idx].year_num, 
					glob_periods, 
					0) 

					LET int_flag = 0 
					LET quit_flag = 0 
				END IF 
			END IF 

	END DISPLAY --input 

	LET int_flag = 0 
	LET quit_flag = 0 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION scan_ledg()
############################################################