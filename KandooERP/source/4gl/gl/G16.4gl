{
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

	Source code beautified by beautify.pl on 2020-01-03 14:28:28	Source code beautified by beautify.pl on 2019-11-01 09:53:16	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G16 allows the user TO view ledger history

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE glob_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFINE glob_rec_period RECORD LIKE period.* 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_arr_rec_accounthist DYNAMIC ARRAY OF RECORD --array[50] OF RECORD 
		period_num LIKE accounthist.period_num, 
		open_amt char(20), 
		pre_close_amt char(20), 
		budg_amt char(20) 
	END RECORD 
	DEFINE glob_year_found SMALLINT 
	DEFINE glob_budg_num SMALLINT 
	DEFINE glob_idx SMALLINT 
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_ans char(1) 
	DEFINE glob_bal_amt char(20) 
	DEFINE glob_budg_text char(30) 
	DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 
	DEFINE glob_goon char(1) 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("G16") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, glob_user_scan_code 
	LET glob_ans = "Y" 

	WHILE glob_ans = "Y" 
		CALL getledg() 
		CLOSE WINDOW wg106 
	END WHILE 

END MAIN 


############################################################
# FUNCTION getledg()
#
#
############################################################
FUNCTION getledg() 
	DEFINE l_msgresp LIKE language.yes_flag 

	--	SELECT * INTO glob_rec_glparms.* FROM glparms
	--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND key_code = "1"

	OPEN WINDOW wg106 with FORM "G106" 
	CALL windecoration_g("G106") 

	LET l_msgresp = kandoomsg("G",1037,"") 
	#1037 Enter Account details - ESC TO Continue
	LET glob_rec_t_accounthist.period_num = 0 
	INPUT glob_rec_t_accounthist.cmpy_code, 
	glob_rec_t_accounthist.acct_code, 
	glob_rec_t_accounthist.year_num, 
	glob_budg_num 

	FROM 
	cmpy_code, 
	acct_code, 
	year_num, 
	budg_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G16","input-accounthist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (acct_code) 
			LET glob_rec_t_accounthist.acct_code = 
			showuaccts(glob_rec_t_accounthist.cmpy_code, glob_user_scan_code) 
			DISPLAY glob_rec_t_accounthist.acct_code TO acct_code 

			NEXT FIELD acct_code 

		BEFORE FIELD cmpy_code 
			IF glob_rec_t_accounthist.cmpy_code IS NULL THEN 
				LET glob_rec_t_accounthist.cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY glob_rec_t_accounthist.cmpy_code TO cmpy_code 
			END IF 

		AFTER FIELD cmpy_code 
			SELECT * 
			INTO glob_rec_company.* 
			FROM company 
			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
			IF (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("G",5000,"") 
				NEXT FIELD cmpy_code 
			ELSE 
				DISPLAY glob_rec_company.name_text TO name_text 

			END IF 

		AFTER FIELD acct_code 
			IF glob_rec_t_accounthist.acct_code 
			NOT matches glob_user_scan_code THEN 
				LET l_msgresp = kandoomsg("G",9031,"") 
				NEXT FIELD acct_code 
			ELSE 
				SELECT * 
				INTO glob_rec_coa.* 
				FROM coa 
				WHERE coa.acct_code = glob_rec_t_accounthist.acct_code 
				AND coa.cmpy_code = glob_rec_t_accounthist.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",9031,"") 
					NEXT FIELD acct_code 
				ELSE 
					DISPLAY glob_rec_coa.desc_text TO coa.desc_text 

				END IF 
			END IF 

		AFTER FIELD year_num 
			LET glob_year_found = 0 
			DECLARE per_curs CURSOR FOR 
			SELECT * 
			INTO glob_rec_period.* 
			FROM period 
			WHERE period.year_num = glob_rec_t_accounthist.year_num 
			AND period.cmpy_code = glob_rec_t_accounthist.cmpy_code 
			FOREACH per_curs 
				LET glob_year_found = true #what bullshit IS this ????? 
			END FOREACH 

			IF NOT glob_year_found THEN 
				LET l_msgresp = kandoomsg("E",9210,"") 
				NEXT FIELD acct_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT PROGRAM 
			ELSE 
				SELECT * 
				INTO glob_rec_account.* 
				FROM account 
				WHERE account.cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND account.acct_code = glob_rec_t_accounthist.acct_code 
				AND account.year_num = glob_rec_t_accounthist.year_num 
				IF (status = NOTFOUND) THEN 
					#LET l_msgresp = kandoomsg("I",9226,"") #record not found message was confusing for the tester Anna
					ERROR "No Ledger History found for this account ", trim(glob_rec_t_accounthist.acct_code) 
					NEXT FIELD acct_code 
				ELSE 
					LET glob_bal_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
					glob_rec_account.bal_amt, 
					glob_rec_coa.type_ind, 
					glob_rec_glparms.style_ind) 
					DISPLAY glob_bal_amt TO bal_amt --bal_amt 

				END IF 
			END IF 

			IF glob_budg_num < 1 
			OR glob_budg_num > 6 THEN 
				LET l_msgresp = kandoomsg("G",9008,"") 
				NEXT FIELD budg_num 
			ELSE 
				CASE 
					WHEN (glob_budg_num = 1) 
						LET glob_budg_text = glob_rec_glparms.budg1_text 
					WHEN (glob_budg_num = 2) 
						LET glob_budg_text = glob_rec_glparms.budg2_text 
					WHEN (glob_budg_num = 3) 
						LET glob_budg_text = glob_rec_glparms.budg3_text 
					WHEN (glob_budg_num = 4) 
						LET glob_budg_text = glob_rec_glparms.budg4_text 
					WHEN (glob_budg_num = 5) 
						LET glob_budg_text = glob_rec_glparms.budg5_text 
					WHEN (glob_budg_num = 6) 
						LET glob_budg_text = glob_rec_glparms.budg6_text 
				END CASE 

				DISPLAY glob_budg_num TO budg_num 
				DISPLAY glob_budg_text TO budg_text 

			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	DECLARE dledg CURSOR FOR 
	SELECT accounthist.* 
	INTO glob_rec_accounthist.* 
	FROM accounthist 
	WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
	AND acct_code = glob_rec_t_accounthist.acct_code 
	AND year_num = glob_rec_t_accounthist.year_num 
	ORDER BY period_num 

	LET glob_idx = 0 
	FOREACH dledg 
		LET glob_idx = glob_idx + 1 
		#LET scrn = scr_line()
		LET glob_arr_rec_accounthist[glob_idx].period_num = glob_rec_accounthist.period_num 
		LET glob_arr_rec_accounthist[glob_idx].open_amt = ac_form(glob_rec_kandoouser.cmpy_code, 
		glob_rec_accounthist.open_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 
		LET glob_arr_rec_accounthist[glob_idx].pre_close_amt = 
		ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.pre_close_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

		CASE 
			WHEN (glob_budg_num = 1) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg1_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			WHEN (glob_budg_num = 2) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg2_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			WHEN (glob_budg_num = 3) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg3_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			WHEN (glob_budg_num = 4) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg4_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			WHEN (glob_budg_num = 5) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg5_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			WHEN (glob_budg_num = 6) 
				LET glob_arr_rec_accounthist[glob_idx].budg_amt = 
				ac_form(glob_rec_kandoouser.cmpy_code, glob_rec_accounthist.budg6_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
		END CASE 
	END FOREACH 

	IF glob_idx = 0 THEN 
		LET l_msgresp = kandoomsg("G",9516,"") 
		CLOSE WINDOW wg106 
		CALL getledg() 
	END IF 

	#   CALL set_count(glob_idx)

	LET l_msgresp = kandoomsg("G",1046,"") 
	#1046 RETURN on line TO View History
	--INPUT ARRAY glob_arr_rec_accounthist WITHOUT DEFAULTS FROM sr_accounthist.* attributes(unbuffered)
	DISPLAY ARRAY glob_arr_rec_accounthist TO sr_accounthist.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G16","input-arr-accounthist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_idx > 0 THEN 
				LET glob_rec_accounthist.period_num = glob_arr_rec_accounthist[glob_idx].period_num 
			END IF 

			--BEFORE FIELD open_amt
		ON ACTION ("ACCEPT","DOUBLECLICK") 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_rec_accounthist.period_num = 0 
			OR glob_rec_accounthist.period_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#1037 " Value must be entered.
			ELSE 
				CALL ac_hist_disp(glob_rec_t_accounthist.cmpy_code, 
				glob_rec_t_accounthist.acct_code, 
				glob_rec_t_accounthist.year_num, 
				glob_rec_accounthist.period_num) 
			END IF 

			--			NEXT FIELD period_num
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
