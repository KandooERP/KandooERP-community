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



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G15 allows FOR the addition AND maintenance of Account Budgets
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_rec_accounthist RECORD LIKE accounthist.* 
--	DEFINE glob_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFINE glob_rec_gl_company RECORD LIKE company.* 
	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_rec_period RECORD LIKE period.* 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_arr_rec_accounthist array[366] OF 
	RECORD 
		period_num LIKE accounthist.period_num, 
		budg1_amt LIKE accounthist.budg1_amt, 
		ybudg_amt char(20), 
		yvar_amt char(20) 
	END RECORD 
	DEFINE glob_arr_rec_accounthist2 array[366] OF 
	RECORD 
		budget_amt LIKE accounthist.budg1_amt, 
		ybudg_amt LIKE accounthist.budg1_amt, 
		ytd_pre_close_amt LIKE accounthist.ytd_pre_close_amt 
	END RECORD 
	DEFINE glob_ytd_budg_amt LIKE accounthist.ytd_budg1_amt 
	DEFINE glob_budg1_amt char(20) 
	DEFINE glob_budget_num SMALLINT 
	#DEFINE glob_year_found SMALLINT #not used
	DEFINE glob_no_of_periods SMALLINT 
	DEFINE glob_idx SMALLINT 
	DEFINE glob_r SMALLINT 
	#DEFINE glob_i SMALLINT
	#DEFINE #scrn,
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_err_flag SMALLINT 
	DEFINE glob_try_again char(1) 
	DEFINE glob_ans char(1) 
	DEFINE glob_chgann char(1) 
	DEFINE glob_err_message char(40) 
	DEFINE glob_budget_text char(30) 
	DEFINE glob_balance money(15,2) 
	DEFINE glob_ytd_amt money(15,2) 
	DEFINE glob_period_amt money(15,2) 
	DEFINE glob_tot_budg_amt money(15,2) 
	DEFINE glob_temp_var_amt money(15,2) 
	DEFINE glob_tempamt money(15,2) 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFER quit 
	DEFER interrupt 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("G15") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	LET glob_ans = "Y" 
	WHILE glob_ans = "Y"
		CALL getledg() RETURNING l_rec_t_accounthist.*
		IF NOT int_flag THEN
		#IF getledg() THEN 
			CALL scanner(l_rec_t_accounthist.*) 
			IF not(int_flag OR quit_flag) THEN 
				CALL upd_ledg_n_hist() 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		END IF 
		CLOSE WINDOW wg102 
		LET glob_ans = "Y" 
	END WHILE 
END MAIN 



############################################################
# FUNCTION getledg()
#
#
############################################################
FUNCTION getledg() 
	DEFINE l_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg102 with FORM "G102" 
	CALL windecoration_g("G102") 

	#default init
	LET l_rec_t_accounthist.period_num = 0 
	LET l_rec_t_accounthist.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_t_accounthist.year_num = year(today) --make CURRENT year as the default entry 
	DISPLAY l_rec_t_accounthist.cmpy_code TO cmpy_code 
	DISPLAY l_rec_t_accounthist.acct_code TO acct_code 
	DISPLAY l_rec_t_accounthist.year_num TO year_num
	DISPLAY glob_budget_num TO budget_num

		DISPLAY l_rec_t_accounthist.acct_code #@debug	
	INPUT  #	l_rec_t_accounthist.cmpy_code, #Our plan is, to let users only work in the curently authenticated company 
	l_rec_t_accounthist.acct_code, 
	l_rec_t_accounthist.year_num, 
	glob_budget_num WITHOUT DEFAULTS 
	FROM #	cmpy_code, 
	acct_code, 
	year_num, 
	budget_num 
	ATTRIBUTE(UNBUFFERED)


		BEFORE INPUT 
		DISPLAY l_rec_t_accounthist.acct_code #@debug		
			CALL publish_toolbar("kandoo","G15","input-accounthist") 
			DISPLAY glob_rec_company.cmpy_code TO company.cmpy_code
			DISPLAY glob_rec_company.name_text TO company.name_text
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_t_accounthist.acct_code) TO coa.desc_text
		DISPLAY l_rec_t_accounthist.acct_code #@debug
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code)
			LET l_rec_t_accounthist.acct_code =	show_acct(l_rec_t_accounthist.cmpy_code) 
			DISPLAY BY NAME l_rec_t_accounthist.acct_code 

			NEXT FIELD acct_code 


#		AFTER FIELD cmpy_code 
#			SELECT * INTO glob_rec_gl_company.* FROM company 
#			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
#			IF status = NOTFOUND THEN 
#				ERROR kandoomsg2("G",5000,"") 
#				NEXT FIELD cmpy_code 
#			ELSE 
#				DISPLAY BY NAME glob_rec_gl_company.name_text 
#			END IF 
#			SELECT * INTO glob_rec_glparms.* FROM glparms 
#			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
#			AND key_code = "1" 
#			IF status = NOTFOUND THEN 
#				ERROR kandoomsg2("G",5007,"") 
#				NEXT FIELD cmpy_code 
#			END IF 


		BEFORE FIELD acct_code
			DISPLAY l_rec_t_accounthist.acct_code #@debug		

		ON CHANGE acct_code
		DISPLAY l_rec_t_accounthist.acct_code #@debug
			IF NOT db_coa_pk_exists(UI_OFF,MODE_UPDATE,l_rec_t_accounthist.acct_code) THEN 
				ERROR kandoomsg2("G",9031,"")		#9031 Account code NOT found
				NEXT FIELD acct_code 
			ELSE 
				DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_t_accounthist.acct_code) TO coa.desc_text 
			END IF 
		DISPLAY l_rec_t_accounthist.acct_code #@debug			

		AFTER FIELD acct_code
		DISPLAY l_rec_t_accounthist.acct_code #@debug		
			IF NOT db_coa_pk_exists(UI_OFF,MODE_UPDATE,l_rec_t_accounthist.acct_code) THEN 
				ERROR kandoomsg2("G",9031,"")		#9031 Account code NOT found
				NEXT FIELD acct_code 
			ELSE 
				DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_t_accounthist.acct_code) TO coa.desc_text 
			END IF 
		DISPLAY l_rec_t_accounthist.acct_code #@debug
		AFTER FIELD year_num 
			SELECT count(*) INTO glob_cnt FROM period 
			WHERE cmpy_code = l_rec_t_accounthist.cmpy_code 
			AND year_num = l_rec_t_accounthist.year_num 
			IF glob_cnt = 0 THEN 
				ERROR kandoomsg2("G",9011,l_rec_t_accounthist.year_num) 
				#9011 Fisc Year/Period IS gone
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
--			SELECT * INTO glob_rec_gl_company.* FROM company  #remove ????
--			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
--			IF status = NOTFOUND THEN 
--				ERROR kandoomsg2("G",5000,"") 
--				NEXT FIELD cmpy_code 
--			ELSE 
--				DISPLAY BY NAME glob_rec_gl_company.name_text 
--			END IF 
--			SELECT * INTO glob_rec_glparms.* FROM glparms 
--			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
--			AND key_code = "1" 
--			IF status = NOTFOUND THEN 
--				ERROR kandoomsg2("G",5007,"") 
--				NEXT FIELD cmpy_code 
--			END IF 

			#Get COA account record
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE coa.acct_code = l_rec_t_accounthist.acct_code 
			AND coa.cmpy_code = l_rec_t_accounthist.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9210,"") 
				#9210 Chart code NOT found
				NEXT FIELD acct_code 
			ELSE 
				DISPLAY BY NAME glob_rec_coa.desc_text 

			END IF 

			#Get number of periods for this fiscal year
			SELECT count(*) INTO glob_cnt FROM period 
			WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
			AND year_num = glob_rec_t_accounthist.year_num 
			IF glob_cnt = 0 THEN 
				ERROR kandoomsg2("G",9011,l_rec_t_accounthist.year_num) 
				#9011 Fisc Year/Period IS gone
				NEXT FIELD year_num 
			END IF 

			IF glob_budget_num >= 1 AND glob_budget_num <= 6 AND glob_budget_num IS NOT NULL THEN 
			ELSE 
				ERROR kandoomsg2("G",9008,"") 
				NEXT FIELD budget_num 
			END IF 

			CASE 
				WHEN (glob_budget_num = 1) 
					IF glob_rec_glparms.budg1_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 1 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg1_text 

				WHEN (glob_budget_num = 2) 
					IF glob_rec_glparms.budg2_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 2 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg2_text 

				WHEN (glob_budget_num = 3) 
					IF glob_rec_glparms.budg3_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 3 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg3_text 

				WHEN (glob_budget_num = 4) 
					IF glob_rec_glparms.budg4_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 4 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg4_text 

				WHEN (glob_budget_num = 5) 
					IF glob_rec_glparms.budg5_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 5 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg5_text 

				WHEN (glob_budget_num = 6) 
					IF glob_rec_glparms.budg6_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 
						#9153 " Budget 6 IS locked, use GZP TO unlock"
						NEXT FIELD budget_num 
					END IF 
					LET glob_budget_text = glob_rec_glparms.budg6_text 
			END CASE 

			DISPLAY glob_budget_text TO budget_text 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 


	IF int_flag OR quit_flag THEN
		MESSAGE "Program Aborted by User/ Changes were not saved" 
		INITIALIZE l_rec_t_accounthist.* TO NULL 
	ELSE 

		SELECT * INTO glob_rec_account.* FROM account 
		WHERE account.cmpy_code = l_rec_t_accounthist.cmpy_code 
		AND account.acct_code = l_rec_t_accounthist.acct_code 
		AND account.year_num = l_rec_t_accounthist.year_num 
	
		IF status = NOTFOUND THEN 
			IF promptTF("",kandoomsg2("G",3517,""),1)	THEN
				CALL ins_ledg_n_hist(l_rec_t_accounthist.*) 
			ELSE 
				RETURN false 
			END IF 
--			IF int_flag OR quit_flag THEN 
--				EXIT PROGRAM 
--			END IF 
		ELSE 
			CASE 
				WHEN (glob_budget_num = 2) 
					LET glob_rec_account.budg1_amt = glob_rec_account.budg2_amt 
				WHEN (glob_budget_num = 3) 
					LET glob_rec_account.budg1_amt = glob_rec_account.budg3_amt 
				WHEN (glob_budget_num = 4) 
					LET glob_rec_account.budg1_amt = glob_rec_account.budg4_amt 
				WHEN (glob_budget_num = 5) 
					LET glob_rec_account.budg1_amt = glob_rec_account.budg5_amt 
				WHEN (glob_budget_num = 6) 
					LET glob_rec_account.budg1_amt = glob_rec_account.budg6_amt 
			END CASE 
	
			LET glob_budg1_amt = ac_form(l_rec_t_accounthist.cmpy_code, 
			glob_rec_account.budg1_amt, 
			glob_rec_coa.type_ind, 
			glob_rec_glparms.style_ind) 
			DISPLAY glob_budg1_amt TO account.budg1_amt 
	
		END IF 
	END IF

	RETURN l_rec_t_accounthist.* 
END FUNCTION 



############################################################
# FUNCTION scanner(p_rec_t_accounthist)
#
#
############################################################
FUNCTION scanner(p_rec_t_accounthist) 
	DEFINE p_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFINE l_period SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL check_hist(p_rec_t_accounthist.*) 
	DECLARE dledg CURSOR FOR 
	SELECT * INTO glob_rec_accounthist.* FROM accounthist 
	WHERE cmpy_code = p_rec_t_accounthist.cmpy_code 
	AND acct_code = p_rec_t_accounthist.acct_code 
	AND year_num = p_rec_t_accounthist.year_num 
	ORDER BY period_num 

	LET glob_tot_budg_amt = 0 
	LET glob_idx = 0 
	FOREACH dledg 
		LET glob_idx = glob_idx + 1 
		LET glob_arr_rec_accounthist[glob_idx].period_num = glob_rec_accounthist.period_num 
		LET glob_arr_rec_accounthist2[glob_idx].ytd_pre_close_amt = 
		glob_rec_accounthist.ytd_pre_close_amt 
		CASE 
			WHEN (glob_budget_num = 1) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg1_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg1_amt 
			WHEN (glob_budget_num = 2) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg2_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg2_amt 
			WHEN (glob_budget_num = 3) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg3_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg3_amt 
			WHEN (glob_budget_num = 4) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg4_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg4_amt 
			WHEN (glob_budget_num = 5) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg5_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg5_amt 
			WHEN (glob_budget_num = 6) 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_rec_accounthist.budg6_amt 
				LET glob_tot_budg_amt = glob_tot_budg_amt + glob_rec_accounthist.budg6_amt 
		END CASE 
		LET glob_arr_rec_accounthist[glob_idx].budg1_amt = 
		glob_arr_rec_accounthist2[glob_idx].budget_amt 
		LET glob_arr_rec_accounthist[glob_idx].ybudg_amt = 
		ac_form(p_rec_t_accounthist.cmpy_code, 
		glob_tot_budg_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 
		LET glob_arr_rec_accounthist2[glob_idx].ybudg_amt = glob_tot_budg_amt 
		LET glob_temp_var_amt = calc_var(glob_idx) 
		LET glob_arr_rec_accounthist[glob_idx].yvar_amt = 
		ac_form(p_rec_t_accounthist.cmpy_code, 
		glob_temp_var_amt, 
		glob_rec_coa.type_ind, 
		glob_rec_glparms.style_ind) 

		#      IF glob_idx <= 12 THEN
		#         DISPLAY glob_arr_rec_accounthist [glob_idx].* TO sr_accounthist [glob_idx].*
		#      END IF
	END FOREACH 

	LET glob_no_of_periods = glob_idx 
	CALL set_count(glob_idx) 

	LET glob_chgann = false
	IF promptTF("",kandoomsg2("G",3518,""),1)	THEN 
		LET glob_chgann = true 

		INPUT BY NAME glob_rec_account.budg1_amt WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","G15","input-account") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END INPUT 

		IF glob_rec_account.budg1_amt IS NULL THEN 
			LET glob_rec_account.budg1_amt = 0 
		END IF 
		
		IF glob_rec_account.budg1_amt != 0 THEN 
			IF promptTF("",kandoomsg2("G",3519,""),1)	THEN
				LET glob_period_amt = glob_rec_account.budg1_amt / glob_no_of_periods 
				LET glob_ytd_amt = 0 
				FOR glob_idx = 1 TO glob_no_of_periods - 1 
					LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_period_amt 
					LET glob_ytd_amt = glob_ytd_amt + glob_period_amt 
					LET glob_arr_rec_accounthist2[glob_idx].ybudg_amt = glob_ytd_amt 
					LET glob_arr_rec_accounthist[glob_idx].budg1_amt = 
					glob_period_amt 
					LET glob_arr_rec_accounthist[glob_idx].ybudg_amt = 
					ac_form(p_rec_t_accounthist.cmpy_code, 
					glob_ytd_amt, 
					glob_rec_coa.type_ind, 
					glob_rec_glparms.style_ind) 
					LET glob_temp_var_amt = calc_var(glob_idx) 
					LET glob_arr_rec_accounthist[glob_idx].yvar_amt = 
					ac_form(p_rec_t_accounthist.cmpy_code, 
					glob_temp_var_amt, 
					glob_rec_coa.type_ind, 
					glob_rec_glparms.style_ind) 
				END FOR 
				LET glob_idx = glob_no_of_periods 
				LET glob_tempamt = glob_rec_account.budg1_amt - glob_ytd_amt 
				LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_tempamt 
				LET glob_ytd_amt = glob_ytd_amt + glob_tempamt 
				LET glob_arr_rec_accounthist2[glob_idx].ybudg_amt = glob_ytd_amt 
				LET glob_arr_rec_accounthist[glob_idx].budg1_amt = 	glob_tempamt 
				LET glob_arr_rec_accounthist[glob_idx].ybudg_amt = 	ac_form(p_rec_t_accounthist.cmpy_code, 
				glob_ytd_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
				LET glob_temp_var_amt = calc_var(glob_idx) 
				LET glob_arr_rec_accounthist[glob_idx].yvar_amt = 
				ac_form(p_rec_t_accounthist.cmpy_code, 
				glob_temp_var_amt, 
				glob_rec_coa.type_ind, 
				glob_rec_glparms.style_ind) 
			END IF 
		END IF 
	END IF 

	MESSAGE kandoomsg2("G",1045,"") 
	#1045 Enter Budget Information - F5 TO View Detail "

	INPUT ARRAY glob_arr_rec_accounthist WITHOUT DEFAULTS FROM sr_accounthist.* attributes(unbuffered, INSERT ROW = false, DELETE ROW = false, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G15","input-arr-accounthist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_period = glob_arr_rec_accounthist[glob_idx].period_num 
			IF arr_curr() > arr_count() THEN 
				ERROR kandoomsg2("G",9001,"") 
			END IF 

		ON ACTION "DETAILS" #ON KEY (f5) 
			IF glob_idx <= glob_no_of_periods THEN 
				CALL disp_hist(p_rec_t_accounthist.cmpy_code, 
				p_rec_t_accounthist.acct_code, 
				p_rec_t_accounthist.year_num, 
				l_period) 
			END IF 

		--HuHo Looks to me like a duplicated
		--ON ACTION "History" #ON KEY (control-v) 
		--	IF glob_idx <= glob_no_of_periods THEN 
		--		CALL disp_hist(p_rec_t_accounthist.cmpy_code, 
		--		p_rec_t_accounthist.acct_code, 
		--		p_rec_t_accounthist.year_num, 
		--		l_period) 
		--	END IF 

		BEFORE FIELD budg1_amt 
			LET glob_arr_rec_accounthist[glob_idx].budg1_amt = glob_arr_rec_accounthist2[glob_idx].budget_amt 
			#DISPLAY glob_arr_rec_accounthist[glob_idx].budg1_amt TO sr_accounthist[scrn].budg1_amt

		BEFORE FIELD ybudg_amt 
			NEXT FIELD budg1_amt 

		AFTER FIELD budg1_amt 
 
			LET glob_tempamt = glob_arr_rec_accounthist[glob_idx].budg1_amt 
			IF status = -1213 THEN 
				ERROR kandoomsg2("G",9009,"") 
				NEXT FIELD budg1_amt 
			END IF 

			IF status = -1226 THEN 
				ERROR kandoomsg2("G",9009,"") 
				NEXT FIELD budg1_amt 
			END IF 



			IF glob_idx > glob_no_of_periods THEN 
				INITIALIZE glob_arr_rec_accounthist[glob_idx].budg1_amt TO NULL 
				#DISPLAY glob_arr_rec_accounthist [glob_idx].budg1_amt
				#   TO sr_accounthist [scrn].budg1_amt
			ELSE 
				IF glob_arr_rec_accounthist[glob_idx].budg1_amt IS NULL THEN 
					#   LET glob_arr_rec_accounthist[scrn].budg1_amt = 0		#huho watch point.. Not sure how TO handle this with tables
				END IF 
				IF glob_tempamt IS NULL THEN 
					LET glob_tempamt = 0 
				END IF 
				IF glob_tempamt != glob_arr_rec_accounthist2[glob_idx].budget_amt THEN 
					IF glob_chgann = false THEN 
						LET glob_rec_account.budg1_amt = glob_rec_account.budg1_amt - 
						glob_arr_rec_accounthist2[glob_idx].budget_amt + glob_tempamt 
						DISPLAY glob_rec_account.budg1_amt TO account.budg1_amt 

					END IF 
					LET glob_arr_rec_accounthist2[glob_idx].ybudg_amt = 
					glob_arr_rec_accounthist2[glob_idx].ybudg_amt - 
					glob_arr_rec_accounthist2[glob_idx].budget_amt + glob_tempamt 
					LET glob_arr_rec_accounthist[glob_idx].budg1_amt = 
					glob_tempamt 
					LET glob_arr_rec_accounthist2[glob_idx].budget_amt = glob_tempamt 
					LET glob_arr_rec_accounthist[glob_idx].ybudg_amt = 
					ac_form(p_rec_t_accounthist.cmpy_code, 
					glob_arr_rec_accounthist2[glob_idx].ybudg_amt, 
					glob_rec_coa.type_ind, 
					glob_rec_glparms.style_ind) 
					LET glob_temp_var_amt = calc_var(glob_idx) 
					LET glob_arr_rec_accounthist[glob_idx].yvar_amt = 
					ac_form(p_rec_t_accounthist.cmpy_code, 
					glob_temp_var_amt, 
					glob_rec_coa.type_ind, 
					glob_rec_glparms.style_ind) 
					#DISPLAY glob_arr_rec_accounthist [glob_idx].*
					#   TO sr_accounthist [scrn].*
					LET glob_ytd_budg_amt = 0 
					FOR glob_r = 1 TO glob_no_of_periods 
						LET glob_ytd_budg_amt = glob_ytd_budg_amt + 
						glob_arr_rec_accounthist2[glob_r].budget_amt 
						LET glob_arr_rec_accounthist2[glob_r].ybudg_amt = glob_ytd_budg_amt 
						LET glob_arr_rec_accounthist[glob_r].ybudg_amt = 
						ac_form(p_rec_t_accounthist.cmpy_code, 
						glob_ytd_budg_amt, 
						glob_rec_coa.type_ind, 
						glob_rec_glparms.style_ind) 
						LET glob_temp_var_amt = calc_var(glob_r) 
						LET glob_arr_rec_accounthist[glob_r].yvar_amt = 
						ac_form(p_rec_t_accounthist.cmpy_code, 
						glob_temp_var_amt, 
						glob_rec_coa.type_ind, 
						glob_rec_glparms.style_ind) 
					END FOR 
					#LET glob_i = glob_idx
					# FOR glob_r = scrn TO 12   #huho - need TO remove these
					#    IF glob_i > glob_no_of_periods THEN
					#  EXIT FOR
					#    END IF
					#   DISPLAY glob_arr_rec_accounthist[glob_i].*
					#      TO sr_accounthist[glob_r].*
					#    LET glob_i = glob_i + 1
					# END FOR
				ELSE 
					LET glob_arr_rec_accounthist[glob_idx].budg1_amt = 
					glob_tempamt 
					LET glob_r = glob_idx 
					#DISPLAY glob_arr_rec_accounthist [glob_r].*
					#   TO sr_accounthist [scrn].*
				END IF 
			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

END FUNCTION 



############################################################
# FUNCTION disp_hist(p_cmpy, p_acct, p_acc_year, p_per)
#
#
############################################################
FUNCTION disp_hist(p_cmpy, p_acct, p_acc_year, p_per) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_accounthist.* FROM accounthist 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	AND period_num = p_per 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",9031,"") 
		#9031 Account code NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_account.* FROM account 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",9031,"") 
		#9031 Account code NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",9210,"") 
		#9210 Chart code NOT found
		RETURN 
	END IF 

	OPEN WINDOW histwind with FORM "G105" 
	CALL windecoration_g("G105") 

	DISPLAY BY NAME l_rec_accounthist.acct_code, 
	l_rec_coa.desc_text, 
	l_rec_account.bal_amt, 
	l_rec_accounthist.year_num, 
	l_rec_accounthist.period_num, 
	l_rec_accounthist.open_amt, 
	l_rec_accounthist.debit_amt, 
	l_rec_accounthist.credit_amt, 
	l_rec_accounthist.stats_qty, 
	l_rec_accounthist.close_amt, 
	l_rec_accounthist.pre_close_amt, 
	l_rec_accounthist.budg1_amt, 
	l_rec_accounthist.budg2_amt, 
	l_rec_accounthist.budg3_amt, 
	l_rec_accounthist.budg4_amt, 
	l_rec_accounthist.budg5_amt, 
	l_rec_accounthist.budg6_amt, 
	l_rec_accounthist.ytd_pre_close_amt 

	CALL eventsuspend()#let l_msgresp = kandoomsg("U",1,"") 
	#1 Any key TO Continue
	CLOSE WINDOW histwind 
	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 



############################################################
# FUNCTION ins_ledg_n_hist ()
#
#
############################################################
FUNCTION ins_ledg_n_hist(p_rec_t_accounthist) 
	DEFINE p_rec_t_accounthist RECORD LIKE accounthist.*
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 

	# first get chart structure FOR later account INSERT use

	SELECT * 
	INTO glob_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = p_rec_t_accounthist.cmpy_code 
	AND type_ind = "C" 

	LET l_start_chart = glob_rec_structure.start_num 
	LET l_end_chart = glob_rec_structure.start_num + glob_rec_structure.length_num - 1 

	# Get closing glob_balance FROM previous year IF it exists AND type IS
	# A)sset OR L)iability

	IF glob_rec_coa.type_ind matches "[AL]" THEN 
		SELECT bal_amt 
		INTO glob_balance 
		FROM account 
		WHERE cmpy_code = p_rec_t_accounthist.cmpy_code 
		AND acct_code = p_rec_t_accounthist.acct_code 
		AND year_num = p_rec_t_accounthist.year_num - 1 
		IF status = NOTFOUND THEN 
			LET glob_balance = 0 
		END IF 
	END IF 

	LET glob_rec_account.cmpy_code = p_rec_t_accounthist.cmpy_code 
	LET glob_rec_account.acct_code = p_rec_t_accounthist.acct_code 
	LET glob_rec_account.chart_code =	p_rec_t_accounthist.acct_code[l_start_chart, l_end_chart] 
	LET glob_rec_account.year_num = p_rec_t_accounthist.year_num 
	LET glob_rec_account.open_amt = glob_balance 
	LET glob_rec_account.bal_amt = glob_balance 
	LET glob_rec_account.stats_qty = 0 
	LET glob_rec_account.debit_amt = 0 
	LET glob_rec_account.credit_amt = 0 
	LET glob_rec_account.budg1_amt = 0 
	LET glob_rec_account.budg2_amt = 0 
	LET glob_rec_account.budg3_amt = 0 
	LET glob_rec_account.budg4_amt = 0 
	LET glob_rec_account.budg5_amt = 0 
	LET glob_rec_account.budg6_amt = 0 
	LET glob_rec_account.ytd_pre_close_amt = 0 


--	LET glob_try_again = error_recover (glob_err_message, status) 
--	IF glob_try_again != "Y" THEN 
--	EXIT PROGRAM 
--	END IF 

 

		INSERT INTO account 
		VALUES (glob_rec_account.*)

		CALL check_hist(p_rec_t_accounthist.*) 


END FUNCTION # ins_ledg_n_hist 



############################################################
# FUNCTION upd_ledg_n_hist ()
#
#
############################################################
FUNCTION upd_ledg_n_hist () 
	DEFINE l_total LIKE accounthist.ytd_budg1_amt 
	DEFINE l_msgresp LIKE language.yes_flag 


--	LET glob_try_again = error_recover (glob_err_message, status) 
--	IF glob_try_again != "Y" THEN 
--		EXIT PROGRAM 
--	END IF 


	BEGIN WORK 
		LET l_total = 0 
		FOR glob_r = 1 TO glob_no_of_periods 
			LET l_total = l_total + glob_arr_rec_accounthist2[glob_r].budget_amt 
			CASE 
				WHEN (glob_budget_num = 1) 
					UPDATE accounthist 
					SET budg1_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg1_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
				WHEN (glob_budget_num = 2) 
					UPDATE accounthist 
					SET budg2_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg2_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
				WHEN (glob_budget_num = 3) 
					UPDATE accounthist 
					SET budg3_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg3_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
				WHEN (glob_budget_num = 4) 
					UPDATE accounthist 
					SET budg4_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg4_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
				WHEN (glob_budget_num = 5) 
					UPDATE accounthist 
					SET budg5_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg5_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
				WHEN (glob_budget_num = 6) 
					UPDATE accounthist 
					SET budg6_amt = glob_arr_rec_accounthist2[glob_r].budget_amt, 
					ytd_budg6_amt = l_total 
					WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
					AND acct_code = glob_rec_t_accounthist.acct_code 
					AND year_num = glob_rec_t_accounthist.year_num 
					AND period_num = glob_arr_rec_accounthist[glob_r].period_num 
			END CASE 
		END FOR 
		CASE 
			WHEN (glob_budget_num = 1) 
				UPDATE account 
				SET budg1_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
			WHEN (glob_budget_num = 2) 
				UPDATE account 
				SET budg2_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
			WHEN (glob_budget_num = 3) 
				UPDATE account 
				SET budg3_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
			WHEN (glob_budget_num = 4) 
				UPDATE account 
				SET budg4_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
			WHEN (glob_budget_num = 5) 
				UPDATE account 
				SET budg5_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
			WHEN (glob_budget_num = 6) 
				UPDATE account 
				SET budg6_amt = l_total 
				WHERE cmpy_code = glob_rec_t_accounthist.cmpy_code 
				AND acct_code = glob_rec_t_accounthist.acct_code 
				AND year_num = glob_rec_t_accounthist.year_num 
		END CASE 
	COMMIT WORK 


	IF l_total != glob_rec_account.budg1_amt THEN 
		ERROR kandoomsg2("G",9010,l_total) 
	END IF 

END FUNCTION # upd_ledg_n_hist 



############################################################
# FUNCTION check_hist(p_rec_t_accounthist)
#
#
############################################################
FUNCTION check_hist(p_rec_t_accounthist) 
	DEFINE p_rec_t_accounthist RECORD LIKE accounthist.*
	# check that an accounthist exists FOR all declared periods
	DECLARE hist_curs CURSOR FOR 
	SELECT period.* 
	INTO glob_rec_period.* 
	FROM period 
	WHERE period.cmpy_code = p_rec_t_accounthist.cmpy_code 
	AND period.year_num = p_rec_t_accounthist.year_num 
	ORDER BY period_num 

	FOREACH hist_curs 
		DECLARE ach_curs CURSOR FOR 
		SELECT * 
		FROM accounthist 
		WHERE cmpy_code = p_rec_t_accounthist.cmpy_code 
		AND acct_code = p_rec_t_accounthist.acct_code 
		AND year_num = glob_rec_period.year_num 
		AND period_num = glob_rec_period.period_num 
		OPEN ach_curs 
		FETCH ach_curs 
		IF status = NOTFOUND THEN 
			LET glob_rec_accounthist.cmpy_code = p_rec_t_accounthist.cmpy_code 
			LET glob_rec_accounthist.acct_code = p_rec_t_accounthist.acct_code 
			LET glob_rec_accounthist.year_num = p_rec_t_accounthist.year_num 
			LET glob_rec_accounthist.period_num = glob_rec_period.period_num 
			LET glob_rec_accounthist.open_amt = 0 
			LET glob_rec_accounthist.debit_amt = 0 
			LET glob_rec_accounthist.credit_amt = 0 
			LET glob_rec_accounthist.close_amt = 0 
			LET glob_rec_accounthist.pre_close_amt = 0 
			LET glob_rec_accounthist.budg1_amt = 0 
			LET glob_rec_accounthist.budg2_amt = 0 
			LET glob_rec_accounthist.budg3_amt = 0 
			LET glob_rec_accounthist.budg4_amt = 0 
			LET glob_rec_accounthist.budg5_amt = 0 
			LET glob_rec_accounthist.budg6_amt = 0 
			LET glob_rec_accounthist.stats_qty = 0 
			LET glob_rec_accounthist.ytd_pre_close_amt = 0 
			LET glob_rec_accounthist.hist_flag = "N" 
			LET glob_rec_accounthist.ytd_pre_close_amt = 0 
			LET glob_rec_accounthist.pre_close_amt = 0 
			LET glob_err_message = "History INSERT: ", glob_rec_accounthist.acct_code
			INSERT INTO accounthist 
			VALUES (glob_rec_accounthist.*) 
		END IF 
	END FOREACH 

END FUNCTION 


############################################################
# FUNCTION calc_var(p_j)
#
#
############################################################
FUNCTION calc_var(p_j) 
	DEFINE p_j SMALLINT 
	DEFINE l_ytd_pre_close_amt LIKE accounthist.ytd_pre_close_amt 
	DEFINE l_ytd_budget LIKE accounthist.budg1_amt 
	DEFINE l_var_amt money(15,2) 

	# Reverse sign before calculating variance on accounts which
	# normally have a credit (-ve) glob_balance

	IF glob_rec_coa.type_ind matches "[INL]" THEN 
		LET l_ytd_pre_close_amt = 
		0 - glob_arr_rec_accounthist2[p_j].ytd_pre_close_amt + 0 
		LET l_ytd_budget = 
		0 - glob_arr_rec_accounthist2[p_j].ybudg_amt + 0 
		LET l_var_amt = l_ytd_pre_close_amt - l_ytd_budget 
	ELSE 
		LET l_var_amt = 
		glob_arr_rec_accounthist2[p_j].ytd_pre_close_amt - 
		glob_arr_rec_accounthist2[p_j].ybudg_amt 
	END IF 

	RETURN (l_var_amt) 
END FUNCTION 
