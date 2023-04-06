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

	Source code beautified by beautify.pl on 2020-01-03 14:28:51	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GS2  Rolls up history & account detail

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_period RECORD LIKE period.* 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE glob_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE glob_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_seg_text CHAR(500) 
	DEFINE glob_count_curr INTEGER 
	DEFINE first_time CHAR(1) 

END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GS2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--   SELECT * INTO glob_rec_glparms.* FROM glparms
	--      WHERE key_code = "1"
	--        AND cmpy_code = glob_rec_kandoouser.cmpy_code

	IF NOT get_gl_setup_state() THEN 
		--   IF STATUS = NOTFOUND THEN
		LET l_msgresp = kandoomsg("G",5007,"") 
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g207 with FORM "G207" 
	CALL windecoration_g("G207") 

	IF get_url_fiscal_year_num() > 0 THEN 
		LET glob_period.year_num = get_url_fiscal_year_num() #arg_val(1) 
		DISPLAY glob_period.year_num TO year_num 

		CALL do_updating () 
	ELSE 
		WHILE get_info() 
			CALL do_updating () 
		END WHILE 
	END IF 

	CLOSE WINDOW g207 

END MAIN 


############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_year_text CHAR(6) 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHILE true 
		LET l_msgresp = kandoomsg("G",1070,"") 

		#1070 Enter Year; OK TO Continue
		INPUT BY NAME glob_period.year_num 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GS2","inp-period") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD year_num 
				IF glob_period.year_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9019,"") 
					#9019 Year must be entered.
					NEXT FIELD year_num 
				END IF 
				SELECT * INTO glob_period.* FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_period.year_num 
				AND period_num = 1 
				IF status = NOTFOUND THEN 
					LET l_year_text = glob_period.year_num USING "<<<<","/1" 
					LET l_msgresp = kandoomsg("U",7100,l_year_text) 
					#7100" Year AND period combination NOT found "
					NEXT FIELD year_num 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		CALL segment_con(glob_rec_kandoouser.cmpy_code,"accounthist") 
		RETURNING glob_seg_text 
		IF glob_seg_text IS NULL THEN 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION do_updating ()
#
#
############################################################
FUNCTION do_updating () 
	DEFINE l_ahrowid INTEGER 
	DEFINE l_acrowid INTEGER 

	DEFINE l_tot_bud1 money(15,2) 
	DEFINE l_tot_bud2 money(15,2) 
	DEFINE l_tot_bud3 money(15,2) 
	DEFINE l_tot_bud4 money(15,2) 
	DEFINE l_tot_bud5 money(15,2) 
	DEFINE l_tot_bud6 money(15,2) 

	DEFINE l_counter, i SMALLINT 
	DEFINE l_err_message CHAR (60) 
	DEFINE l_err_continue CHAR(1) 

	DEFINE l_query_text CHAR(800) 
	#DEFINE glob_seg_text CHAR(500)
	#DEFINE glob_count_curr INTEGER
	#DEFINE l_msgresp CHAR(1)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING 

	LET l_counter = 0 
	LET l_query_text = 
	"SELECT rowid, * FROM accounthist ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = '",glob_period.year_num,"' ", 
	glob_seg_text clipped," ", 
	"ORDER BY acct_code,year_num,period_num" 
	PREPARE s_accthst FROM l_query_text 
	DECLARE c_accthst CURSOR FOR s_accthst 
	BEGIN WORK 
		LOCK TABLE account in share MODE 
		LOCK TABLE accounthist in share MODE 
		LOCK TABLE accountcur in share MODE 
		LOCK TABLE accounthistcur in share MODE 

		#	OPEN WINDOW w1 WITH FORM "U999" ATTRIBUTES(BORDER)
		#	CALL windecoration_u("U999")

		GOTO bypass 
		LABEL recovery: 
		LET l_err_continue = error_recover(l_err_message, status) 
		IF l_err_continue = "N" THEN 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		LET first_time = "Y" 
		LET glob_rec_account.acct_code = "z" 
		MESSAGE "Processing Account...." 
		#DISPLAY "Processing Account...." TO lbLabel1

		FOREACH c_accthst INTO l_ahrowid, 
			glob_rec_accounthist.* 
			IF glob_rec_accounthist.acct_code != glob_rec_account.acct_code THEN 
				IF first_time = "Y" THEN 
					LET l_counter = 1 
					LET first_time = "N" # nothing TO UPDATE 
				ELSE 
					LET l_counter = l_counter + 1 
					LET l_err_message = " GS2 - Update account table" 
					LET glob_rec_account.budg1_amt = l_tot_bud1 
					LET glob_rec_account.budg2_amt = l_tot_bud2 
					LET glob_rec_account.budg3_amt = l_tot_bud3 
					LET glob_rec_account.budg4_amt = l_tot_bud4 
					LET glob_rec_account.budg5_amt = l_tot_bud5 
					LET glob_rec_account.budg6_amt = l_tot_bud6 
					UPDATE account 
					SET * = glob_rec_account.* 
					WHERE rowid = l_acrowid 
				END IF 

				MESSAGE glob_rec_accounthist.acct_code 
				#DISPLAY glob_rec_accounthist.acct_code TO lbLabel1b  -- 1,22

				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_accounthist.acct_code 
				IF status = NOTFOUND THEN 
					LET l_err_message = "GS2 - Missing COA row FOR glob_rec_kandoouser.cmpy_code ",glob_rec_kandoouser.cmpy_code, 
					", ",glob_rec_accounthist.acct_code 
					CALL errorlog (l_err_message) 

					--					OPEN WINDOW w2 WITH FORM "U999" ATTRIBUTES(BORDER)
					--					CALL windecoration_u("U999")

					LET l_msg = l_err_message clipped," Refer ", trim(get_settings_logFile()) 
					ERROR l_msg 					
					LET l_msgresp = kandoomsg("G",9089,"") 
					CALL fgl_winmessage("Error - Refer to",l_msg,"error") 
					--            CLOSE WINDOW w2
					EXIT PROGRAM 
				END IF 
				SELECT rowid, * INTO l_acrowid, glob_rec_account.* FROM account 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_accounthist.acct_code 
				AND year_num = glob_rec_accounthist.year_num 
				IF status = NOTFOUND THEN 
					LET l_err_message = " GS2 -Inserting Account" 
					CALL insert_account () 
					RETURNING l_acrowid 
				END IF 
				LET l_tot_bud1 = 0 
				LET l_tot_bud2 = 0 
				LET l_tot_bud3 = 0 
				LET l_tot_bud4 = 0 
				LET l_tot_bud5 = 0 
				LET l_tot_bud6 = 0 
				IF glob_rec_account.open_amt IS NULL THEN 
					LET glob_rec_account.open_amt = 0 
				END IF 
				LET glob_rec_account.debit_amt = 0 
				LET glob_rec_account.credit_amt = 0 
				LET glob_rec_account.stats_qty = 0 
				LET glob_rec_account.ytd_pre_close_amt = 0 
				LET glob_rec_account.bal_amt = glob_rec_account.open_amt 
			END IF 
			# account.open_amt IS untouchable (SET up by year END roll over)
			# accounthist.debit_amt
			# accounthist.credit_amt
			# accounthist.pre_close_amt are untouchable (SET up by GSD)
			CALL fix_nulls () 
			LET glob_rec_accounthist.open_amt = glob_rec_account.bal_amt 
			LET glob_rec_account.stats_qty = glob_rec_account.stats_qty + 
			glob_rec_accounthist.stats_qty 
			LET glob_rec_account.debit_amt = glob_rec_account.debit_amt + 
			glob_rec_accounthist.debit_amt 
			LET glob_rec_account.credit_amt = glob_rec_account.credit_amt + 
			glob_rec_accounthist.credit_amt 
			LET glob_rec_account.bal_amt = glob_rec_account.open_amt + 
			glob_rec_account.debit_amt - 
			glob_rec_account.credit_amt 
			LET glob_rec_account.ytd_pre_close_amt = glob_rec_account.ytd_pre_close_amt 
			+ glob_rec_accounthist.pre_close_amt 
			# save the closing balance FOR this period
			# FOR the opening balance of the next period
			LET glob_rec_accounthist.close_amt = glob_rec_accounthist.open_amt + 
			glob_rec_accounthist.debit_amt - 
			glob_rec_accounthist.credit_amt 
			LET glob_rec_accounthist.ytd_pre_close_amt = glob_rec_account.ytd_pre_close_amt 
			LET glob_rec_accounthist.hist_flag = "Y" 
			LET l_tot_bud1 = l_tot_bud1 + glob_rec_accounthist.budg1_amt 
			LET l_tot_bud2 = l_tot_bud2 + glob_rec_accounthist.budg2_amt 
			LET l_tot_bud3 = l_tot_bud3 + glob_rec_accounthist.budg3_amt 
			LET l_tot_bud4 = l_tot_bud4 + glob_rec_accounthist.budg4_amt 
			LET l_tot_bud5 = l_tot_bud5 + glob_rec_accounthist.budg5_amt 
			LET l_tot_bud6 = l_tot_bud6 + glob_rec_accounthist.budg6_amt 
			LET glob_rec_accounthist.ytd_budg1_amt = l_tot_bud1 
			LET glob_rec_accounthist.ytd_budg2_amt = l_tot_bud2 
			LET glob_rec_accounthist.ytd_budg3_amt = l_tot_bud3 
			LET glob_rec_accounthist.ytd_budg4_amt = l_tot_bud4 
			LET glob_rec_accounthist.ytd_budg5_amt = l_tot_bud5 
			LET glob_rec_accounthist.ytd_budg6_amt = l_tot_bud6 
			LET l_err_message = " GS2 - Update accounthist table" 

			UPDATE accounthist 
			SET * = glob_rec_accounthist.* 
			WHERE rowid = l_ahrowid 
		END FOREACH 

		IF l_counter > 0 THEN 
			LET glob_rec_account.budg1_amt = l_tot_bud1 
			LET glob_rec_account.budg2_amt = l_tot_bud2 
			LET glob_rec_account.budg3_amt = l_tot_bud3 
			LET glob_rec_account.budg4_amt = l_tot_bud4 
			LET glob_rec_account.budg5_amt = l_tot_bud5 
			LET glob_rec_account.budg6_amt = l_tot_bud6 
			LET l_err_message = " GS2 - Update account table" 

			UPDATE account 
			SET * = glob_rec_account.* 
			WHERE rowid = l_acrowid 
		END IF 

		# IF multi-currency GL, foreign currency accounts/history
		# must also be updated
		# FUNCTION called here TO keep all the table updating
		# within the one 'begin/commit'
		IF glob_rec_glparms.use_currency_flag = "Y" THEN 
			FOR i = 1 TO 489 
				IF glob_seg_text[i,i+10] = "accounthist" THEN 
					LET glob_seg_text = 
					glob_seg_text[1,i-1],"accounthistcur",glob_seg_text[i+11,500] clipped 
				END IF 
			END FOR 
			CALL curr_rollup() 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	#   CLEAR window w1
	#DISPLAY "Total Accounts Processed: ",l_counter AT 1,2
	MESSAGE "Total Accounts Processed: ", trim(l_counter) 
	SLEEP 3 

	#   CLOSE WINDOW w1

END FUNCTION 


############################################################
# FUNCTION insert_account()
#
#
############################################################
FUNCTION insert_account() 
	DEFINE l_acrowid INTEGER 
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 

	SELECT * INTO glob_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 
	LET l_start_chart = glob_rec_structure.start_num 
	LET l_end_chart = glob_rec_structure.start_num + glob_rec_structure.length_num - 1 
	LET glob_rec_account.cmpy_code = glob_rec_accounthist.cmpy_code 
	LET glob_rec_account.acct_code = glob_rec_accounthist.acct_code 
	LET glob_rec_account.chart_code = glob_rec_accounthist.acct_code[l_start_chart, l_end_chart] 
	LET glob_rec_account.year_num = glob_rec_accounthist.year_num 
	LET glob_rec_account.open_amt = 0 
	LET glob_rec_account.debit_amt = 0 
	LET glob_rec_account.credit_amt = 0 
	LET glob_rec_account.bal_amt = 0 
	LET glob_rec_account.stats_qty = 0 
	LET glob_rec_account.ytd_pre_close_amt = 0 
	LET glob_rec_account.budg1_amt = 0 
	LET glob_rec_account.budg2_amt = 0 
	LET glob_rec_account.budg3_amt = 0 
	LET glob_rec_account.budg4_amt = 0 
	LET glob_rec_account.budg5_amt = 0 
	LET glob_rec_account.budg6_amt = 0 
	INSERT INTO account VALUES (glob_rec_account.*) 
	SELECT rowid, * INTO l_acrowid, glob_rec_account.* FROM account 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_account.acct_code 
	AND year_num = glob_rec_account.year_num 
	RETURN l_acrowid 
END FUNCTION 



############################################################
# FUNCTION fix_nulls ()
#
#
############################################################
FUNCTION fix_nulls () 
	IF glob_rec_accounthist.open_amt IS NULL THEN 
		LET glob_rec_accounthist.open_amt = 0 
	END IF 
	IF glob_rec_accounthist.close_amt IS NULL THEN 
		LET glob_rec_accounthist.close_amt = 0 
	END IF 
	IF glob_rec_accounthist.credit_amt IS NULL THEN 
		LET glob_rec_accounthist.credit_amt = 0 
	END IF 
	IF glob_rec_accounthist.debit_amt IS NULL THEN 
		LET glob_rec_accounthist.debit_amt = 0 
	END IF 
	IF glob_rec_accounthist.stats_qty IS NULL THEN 
		LET glob_rec_accounthist.stats_qty = 0 
	END IF 
	IF glob_rec_accounthist.pre_close_amt IS NULL THEN 
		LET glob_rec_accounthist.pre_close_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_pre_close_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_pre_close_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg1_amt IS NULL THEN 
		LET glob_rec_accounthist.budg1_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg2_amt IS NULL THEN 
		LET glob_rec_accounthist.budg2_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg3_amt IS NULL THEN 
		LET glob_rec_accounthist.budg3_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg4_amt IS NULL THEN 
		LET glob_rec_accounthist.budg4_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg5_amt IS NULL THEN 
		LET glob_rec_accounthist.budg5_amt = 0 
	END IF 
	IF glob_rec_accounthist.budg6_amt IS NULL THEN 
		LET glob_rec_accounthist.budg6_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg1_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg1_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg2_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg2_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg3_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg3_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg4_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg4_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg5_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg5_amt = 0 
	END IF 
	IF glob_rec_accounthist.ytd_budg6_amt IS NULL THEN 
		LET glob_rec_accounthist.ytd_budg6_amt = 0 
	END IF 
END FUNCTION 




############################################################
# FUNCTION curr_rollup()
#
#
############################################################
FUNCTION curr_rollup() 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_acrow INTEGER 
	DEFINE l_achistrow INTEGER 
	DEFINE l_prev_accountcur LIKE accounthistcur.acct_code 
	DEFINE l_prev_currency LIKE accounthistcur.currency_code 
	DEFINE l_query_text CHAR(800) 
	#DEFINE glob_seg_text CHAR(500)
	#DEFINE glob_count_curr INTEGER
	#DEFINE l_msgresp CHAR(1)

	LET glob_count_curr = 0 

	LET l_prev_accountcur = NULL 
	LET l_prev_currency = NULL 
	LET l_query_text = 
	"SELECT rowid, * FROM accounthistcur ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = '",glob_period.year_num,"' ", 
	glob_seg_text clipped," ", 
	"ORDER BY acct_code,year_num,currency_code,period_num" 
	PREPARE s_accthistcur FROM l_query_text 
	DECLARE c_accthistcur CURSOR FOR s_accthistcur 
	FOREACH c_accthistcur INTO l_achistrow, 
		glob_rec_accounthistcur.* 
		IF l_prev_accountcur IS NULL THEN 
			LET l_acrow = new_accountcur() 
			LET l_prev_accountcur = glob_rec_accounthistcur.acct_code 
			LET l_prev_currency = glob_rec_accounthistcur.currency_code 
		ELSE 
			IF l_prev_accountcur != glob_rec_accounthistcur.acct_code OR 
			l_prev_currency != glob_rec_accounthistcur.currency_code THEN 
				# Update the last accountcur calculated
				LET l_err_message = " GS2 - UPDATE accountcur" 
				UPDATE accountcur 
				SET * = glob_rec_accountcur.* 
				WHERE rowid = l_acrow 
				LET l_acrow = new_accountcur() 
				LET l_prev_accountcur = glob_rec_accounthistcur.acct_code 
				LET l_prev_currency = glob_rec_accounthistcur.currency_code 
			END IF 
		END IF 
		CALL recalc_curr_hist() 
		# UPDATE the period history
		LET l_err_message = " GS2 - Update accounthistcur table" 
		UPDATE accounthistcur 
		SET * = glob_rec_accounthistcur.* 
		WHERE rowid = l_achistrow 
	END FOREACH 
	IF l_prev_accountcur IS NOT NULL THEN 
		# Update the last accountcur accessed
		LET l_err_message = " GS2 - UPDATE accountcur" 
		UPDATE accountcur 
		SET * = glob_rec_accountcur.* 
		WHERE rowid = l_acrow 
	END IF 
	IF glob_count_curr > 0 THEN 
		#DISPLAY "" AT 1,2
		#DISPLAY " Total Currency Accounts Processed: ",glob_count_curr AT 1,2
		MESSAGE " Total Currency Accounts Processed: ",trim(glob_count_curr) 
		SLEEP 2 
	END IF 
END FUNCTION 


############################################################
# FUNCTION recalc_curr_hist()
#
#
############################################################
FUNCTION recalc_curr_hist() 
	# Roll the previous balance amounts TO the history OPEN amounts
	LET glob_rec_accounthistcur.open_amt = glob_rec_accountcur.bal_amt 
	LET glob_rec_accounthistcur.base_open_amt = glob_rec_accountcur.base_bal_amt 
	# Add the period debit AND credit totals TO the account
	LET glob_rec_accountcur.debit_amt = glob_rec_accountcur.debit_amt + 
	glob_rec_accounthistcur.debit_amt 
	LET glob_rec_accountcur.credit_amt = glob_rec_accountcur.credit_amt + 
	glob_rec_accounthistcur.credit_amt 
	LET glob_rec_accountcur.bal_amt = glob_rec_accountcur.open_amt + 
	glob_rec_accountcur.debit_amt - 
	glob_rec_accountcur.credit_amt 
	LET glob_rec_accountcur.base_debit_amt = glob_rec_accountcur.base_debit_amt + 
	glob_rec_accounthistcur.base_debit_amt 
	LET glob_rec_accountcur.base_credit_amt = glob_rec_accountcur.base_credit_amt + 
	glob_rec_accounthistcur.base_credit_amt 
	LET glob_rec_accountcur.base_bal_amt = glob_rec_accountcur.base_open_amt + 
	glob_rec_accountcur.base_debit_amt - 
	glob_rec_accountcur.base_credit_amt 
	# Add the pre-closing amount TO the ytd total
	LET glob_rec_accountcur.ytd_pre_close_amt = glob_rec_accountcur.ytd_pre_close_amt + 
	glob_rec_accounthistcur.pre_close_amt 
	# Reset history closing amounts FROM recalculated opening
	# amounts AND period debit/credit totals
	LET glob_rec_accounthistcur.close_amt = glob_rec_accounthistcur.open_amt + 
	glob_rec_accounthistcur.debit_amt - 
	glob_rec_accounthistcur.credit_amt 
	LET glob_rec_accounthistcur.base_close_amt = glob_rec_accounthistcur.base_open_amt + 
	glob_rec_accounthistcur.base_debit_amt - 
	glob_rec_accounthistcur.base_credit_amt 
	# Reset period history ytd pre_closing FROM account ytd pre_closing
	LET glob_rec_accounthistcur.ytd_pre_close_amt = glob_rec_accountcur.ytd_pre_close_amt 
END FUNCTION 



############################################################
# FUNCTION new_accountcur()
#
#
############################################################
FUNCTION new_accountcur() 
	DEFINE l_curr_row INTEGER 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT rowid, * 
	INTO l_curr_row, 
	glob_rec_accountcur.* 
	FROM accountcur 
	WHERE cmpy_code = glob_rec_accounthistcur.cmpy_code 
	AND year_num = glob_rec_accounthistcur.year_num 
	AND acct_code = glob_rec_accounthistcur.acct_code 
	AND currency_code = glob_rec_accounthistcur.currency_code 

	IF status = NOTFOUND THEN 
		LET l_err_message = "GS2 - Missing accountcur row ", 
		", ",glob_rec_accounthistcur.acct_code, 
		", ", glob_rec_accounthistcur.currency_code 
		CALL errorlog (l_err_message) 

		LET l_msgresp = kandoomsg("U",9111,glob_rec_accounthistcur.acct_code) 

		OPEN WINDOW w2 with FORM "U999" attributes(BORDER) 
		CALL windecoration_u("U999") 

		ERROR l_err_message clipped,"- Refer to ", trim(get_settings_logFile()) 
		LET l_msgresp = kandoomsg("G",7021,"") 
		CLOSE WINDOW w2 
		EXIT PROGRAM 
	END IF 

	#DISPLAY "" AT 1,2
	MESSAGE " Currency Account: ",trim(glob_rec_accounthistcur.acct_code), 
	" Currency: ", trim(glob_rec_accounthistcur.currency_code) 

	#DISPLAY " Currency Account: ",glob_rec_accounthistcur.acct_code,
	#        " Currency: ", glob_rec_accounthistcur.currency_code TO lbLabel1  -- 1,2

	SELECT * INTO glob_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_accounthistcur.acct_code 

	IF status = NOTFOUND THEN 
		LET l_err_message = "GS2 - Missing COA row FOR glob_rec_kandoouser.cmpy_code ", glob_rec_kandoouser.cmpy_code, 
		", ",glob_rec_accounthistcur.acct_code 
		CALL errorlog (l_err_message) 
		LET l_msgresp = kandoomsg("U",9111,glob_rec_accounthistcur.acct_code) 

		OPEN WINDOW w2 with FORM "U999" attributes(BORDER) 
		CALL windecoration_u("U999") 

		ERROR l_err_message clipped,"- Refer ",trim(get_settings_logFile()) 
		LET l_msgresp = kandoomsg("G",7021,"") 
		EXIT PROGRAM 
	END IF 
	# Reset account balances AND debit/credit totals TO start of year
	# figures FOR recalculation FROM period history records
	LET glob_rec_accountcur.bal_amt = glob_rec_accountcur.open_amt 
	LET glob_rec_accountcur.base_bal_amt = glob_rec_accountcur.base_open_amt 
	LET glob_rec_accountcur.debit_amt = 0 
	LET glob_rec_accountcur.credit_amt = 0 
	LET glob_rec_accountcur.base_debit_amt = 0 
	LET glob_rec_accountcur.base_credit_amt = 0 
	LET glob_rec_accountcur.ytd_pre_close_amt = 0 
	LET glob_count_curr = glob_count_curr + 1 

	RETURN (l_curr_row) 
END FUNCTION 
