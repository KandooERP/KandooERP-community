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
# \brief module GSA  Create journal batch closing networth TO accumlated profits
#              AND updating next years accounts (adding new ones WHERE
#              required), Hence closing off the year

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 

END GLOBALS 

############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_coa RECORD LIKE coa.* 
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE modu_rec_structure RECORD LIKE structure.* 
	DEFINE modu_rec_period RECORD LIKE period.* 
	DEFINE modu_rec_account RECORD LIKE account.* 
	DEFINE modu_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE modu_arr_rec_coa DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		flex_code LIKE validflex.flex_code, 
		prof_code LIKE coa.acct_code, 
		acct_code LIKE coa.acct_code, 
		acct_ind CHAR(1) 
	END RECORD 

--	DEFINE modu_runner CHAR(80)
DEFINE modu_err_message CHAR(80) 
DEFINE modu_sel_text CHAR(800) 
DEFINE modu_accum_profit_acct LIKE account.acct_code 
DEFINE modu_net_worth_acct LIKE account.acct_code 
DEFINE modu_acct1_code LIKE coa.acct_code 
DEFINE modu_desc1_text LIKE coa.desc_text 
DEFINE modu_acct2_code LIKE coa.acct_code 
DEFINE modu_desc2_text LIKE coa.desc_text 
DEFINE modu_ofs_debit LIKE batchdetl.debit_amt 
DEFINE modu_ofs_credit LIKE batchdetl.debit_amt 
DEFINE modu_fisc_year LIKE period.year_num 
DEFINE modu_end_period LIKE period.period_num 
DEFINE modu_next_year_open_amt LIKE account.open_amt 
DEFINE modu_start_num SMALLINT 
DEFINE modu_length SMALLINT 
DEFINE modu_multiledger_ind SMALLINT 
DEFINE modu_ledg_cnt SMALLINT 
############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GSA") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wcg162 with FORM "G162" 
	CALL windecoration_g("G162") 


	LET modu_rec_period.year_num = NULL 
	LET modu_multiledger_ind = true 
	SELECT * INTO modu_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET modu_multiledger_ind = false 
	ELSE 
		LET modu_start_num = modu_rec_structure.start_num 
		LET modu_length = modu_rec_structure.start_num 
		+ modu_rec_structure.length_num 
		- 1 
	END IF 
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 " General Ledger Parametere Not Set Up"
	ELSE 
		WHILE get_info() 
		END WHILE 
	END IF 

	CLOSE WINDOW wcg162 

END MAIN 



############################################################
# FUNCTION rollover()
#
#
############################################################
FUNCTION rollover() 
	DEFINE start_chart, end_chart SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO modu_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 
	LET start_chart = modu_rec_structure.start_num 
	LET end_chart = modu_rec_structure.start_num 
	+ modu_rec_structure.length_num 
	- 1 
	GOTO bypass 
	LABEL recovery: 
	LET l_msgresp = error_recover (modu_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 
		LOCK TABLE account in share MODE 
		LOCK TABLE accounthist in share MODE 
		LOCK TABLE accountcur in share MODE 
		LOCK TABLE accounthistcur in share MODE 

		# UPDATE next years opening balances TO zero
		# also the first period of accounthist
		UPDATE account 
		SET open_amt = 0 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = modu_fisc_year + 1 

		# SELECT all asset AND liabilty accounts FOR rolling forward
		# AND equity account JP 310795
		DECLARE tacctcurs CURSOR FOR 
		SELECT account.* FROM account, coa 
		WHERE account.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND account.year_num = modu_fisc_year 
		AND coa.cmpy_code = account.cmpy_code 
		AND coa.acct_code = account.acct_code 
		AND coa.type_ind in ("A", "L" , "N") 
		FOREACH tacctcurs INTO modu_rec_account.* 
			#
			# now see IF the next year IS already SET up
			# IF so UPDATE IF required, INSERT IF NOT there
			# ie. account rows may exist FOR next year IF forward
			# posting has taken place, so the balances are rolled
			# forward INTO the existing row
			SELECT open_amt INTO modu_next_year_open_amt FROM account 
			WHERE cmpy_code = modu_rec_account.cmpy_code 
			AND acct_code = modu_rec_account.acct_code 
			AND year_num = (modu_rec_account.year_num + 1) 
			IF status != NOTFOUND THEN 
				IF modu_next_year_open_amt != modu_rec_account.bal_amt 
				OR modu_next_year_open_amt IS NULL THEN 
					LET modu_err_message = "Updating account: ", modu_rec_account.acct_code 
					UPDATE account 
					SET open_amt = modu_rec_account.bal_amt 
					WHERE cmpy_code = modu_rec_account.cmpy_code 
					AND acct_code = modu_rec_account.acct_code 
					AND year_num = (modu_rec_account.year_num + 1) 
				END IF 
			ELSE 
				# create an account entry FOR the next year AND a history entry FOR
				# each defined period of the next year
				LET modu_rec_account.year_num = modu_fisc_year + 1 
				LET modu_rec_account.open_amt = modu_rec_account.bal_amt 
				LET modu_rec_account.chart_code = modu_rec_account.acct_code[start_chart,end_chart] 
				LET modu_rec_account.debit_amt = 0 
				LET modu_rec_account.credit_amt = 0 
				LET modu_rec_account.stats_qty = 0 
				LET modu_rec_account.budg1_amt = 0 
				LET modu_rec_account.budg2_amt = 0 
				LET modu_rec_account.budg3_amt = 0 
				LET modu_rec_account.budg4_amt = 0 
				LET modu_rec_account.budg5_amt = 0 
				LET modu_rec_account.budg6_amt = 0 
				LET modu_rec_account.ytd_pre_close_amt = 0 
				LET modu_err_message = "Account INSERT: ", modu_rec_account.acct_code 
				INSERT INTO account VALUES (modu_rec_account.*) 

				DECLARE per_curs CURSOR FOR 
				SELECT * INTO modu_rec_period.* FROM period 
				WHERE cmpy_code = modu_rec_account.cmpy_code 
				AND year_num = modu_rec_account.year_num 
				FOREACH per_curs 
					SELECT * INTO modu_rec_accounthist.* FROM accounthist 
					WHERE cmpy_code = modu_rec_account.cmpy_code 
					AND acct_code = modu_rec_account.acct_code 
					AND year_num = modu_rec_account.year_num 
					AND period_num = modu_rec_period.period_num 
					IF status = NOTFOUND THEN 
						LET modu_rec_accounthist.cmpy_code = modu_rec_account.cmpy_code 
						LET modu_rec_accounthist.acct_code = modu_rec_account.acct_code 
						LET modu_rec_accounthist.year_num = modu_rec_account.year_num 
						LET modu_rec_accounthist.period_num = modu_rec_period.period_num 
						LET modu_rec_accounthist.open_amt = 0 
						LET modu_rec_accounthist.debit_amt = 0 
						LET modu_rec_accounthist.credit_amt = 0 
						LET modu_rec_accounthist.stats_qty = 0 
						LET modu_rec_accounthist.close_amt = 0 
						LET modu_rec_accounthist.pre_close_amt = 0 
						LET modu_rec_accounthist.budg1_amt = 0 
						LET modu_rec_accounthist.budg2_amt = 0 
						LET modu_rec_accounthist.budg3_amt = 0 
						LET modu_rec_accounthist.budg4_amt = 0 
						LET modu_rec_accounthist.budg5_amt = 0 
						LET modu_rec_accounthist.budg6_amt = 0 
						LET modu_rec_accounthist.ytd_pre_close_amt = 0 
						LET modu_rec_accounthist.hist_flag = "N" 
						LET modu_err_message = "Account history INSERT: ", 
						modu_rec_accounthist.acct_code 
						INSERT INTO accounthist VALUES (modu_rec_accounthist.*) 
					END IF 
				END FOREACH 
			END IF 
		END FOREACH 
		#
		# IF multi-currency GL IS in use, repeat the roll forward process
		# FOR each asset/liability currency account
		# AND equity account
		#
		IF glob_rec_glparms.use_currency_flag = "Y" THEN 
			DECLARE curr_curs CURSOR FOR 
			SELECT accountcur.* FROM accountcur, coa 
			WHERE accountcur.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND accountcur.year_num = modu_fisc_year 
			AND coa.cmpy_code = accountcur.cmpy_code 
			AND coa.acct_code = accountcur.acct_code 
			AND coa.type_ind in ("A", "L", "N") 

			FOREACH curr_curs INTO modu_rec_accountcur.* 
				#
				# Check that a row does NOT already exist FOR this account/currency
				# ie. accountcur rows may exist FOR next year IF forward
				# posting has taken place.  IF so the balances are rolled
				# forward INTO the existing row, OTHERWISE a new row IS created
				# FOR the new year with all opening amounts SET TO the previous
				# year's balance amounts AND ytd debits AND credits SET TO 0
				SELECT open_amt INTO modu_next_year_open_amt FROM accountcur 
				WHERE cmpy_code = modu_rec_accountcur.cmpy_code 
				AND acct_code = modu_rec_accountcur.acct_code 
				AND year_num = (modu_rec_accountcur.year_num + 1) 
				AND currency_code = modu_rec_accountcur.currency_code 
				IF status != NOTFOUND THEN 
					LET modu_err_message = "Updating accountcur: ", modu_rec_accountcur.acct_code, 
					" currency: ", modu_rec_accountcur.currency_code 
					UPDATE accountcur 
					SET open_amt = modu_rec_accountcur.bal_amt, 
					base_open_amt = modu_rec_accountcur.base_bal_amt 
					WHERE cmpy_code = modu_rec_accountcur.cmpy_code 
					AND acct_code = modu_rec_accountcur.acct_code 
					AND year_num = (modu_rec_accountcur.year_num + 1) 
					AND currency_code = modu_rec_accountcur.currency_code 
				ELSE 
					# create an accountcur entry FOR the next year
					# by moving the old balances TO the new opening amounts AND
					# zeroing the ytd debit AND credit totals
					LET modu_rec_accountcur.year_num = modu_fisc_year + 1 
					LET modu_rec_accountcur.open_amt = modu_rec_accountcur.bal_amt 
					LET modu_rec_accountcur.debit_amt = 0 
					LET modu_rec_accountcur.credit_amt = 0 
					LET modu_rec_accountcur.ytd_pre_close_amt = 0 
					LET modu_rec_accountcur.base_open_amt = modu_rec_accountcur.base_bal_amt 
					LET modu_rec_accountcur.base_debit_amt = 0 
					LET modu_rec_accountcur.base_credit_amt = 0 
					LET modu_err_message = "Accountcurr INSERT: ", modu_rec_accountcur.acct_code, 
					" currency: ", modu_rec_accountcur.currency_code 
					INSERT INTO accountcur VALUES (modu_rec_accountcur.*) 

					DECLARE curr_per_curs CURSOR FOR 
					SELECT * INTO modu_rec_period.* FROM period 
					WHERE cmpy_code = modu_rec_accountcur.cmpy_code 
					AND year_num = modu_rec_accountcur.year_num 
					FOREACH curr_per_curs 
						SELECT * INTO modu_rec_accounthistcur.* FROM accounthistcur 
						WHERE cmpy_code = modu_rec_accountcur.cmpy_code 
						AND acct_code = modu_rec_accountcur.acct_code 
						AND year_num = modu_rec_accountcur.year_num 
						AND period_num = modu_rec_period.period_num 
						AND currency_code = modu_rec_accountcur.currency_code 
						IF status = NOTFOUND THEN 
							LET modu_rec_accounthistcur.cmpy_code = modu_rec_accountcur.cmpy_code 
							LET modu_rec_accounthistcur.acct_code = modu_rec_accountcur.acct_code 
							LET modu_rec_accounthistcur.year_num = modu_rec_accountcur.year_num 
							LET modu_rec_accounthistcur.period_num = modu_rec_period.period_num 
							LET modu_rec_accounthistcur.currency_code = 
							modu_rec_accountcur.currency_code 
							LET modu_rec_accounthistcur.open_amt = 0 
							LET modu_rec_accounthistcur.debit_amt = 0 
							LET modu_rec_accounthistcur.credit_amt = 0 
							LET modu_rec_accounthistcur.close_amt = 0 
							LET modu_rec_accounthistcur.pre_close_amt = 0 
							LET modu_rec_accounthistcur.ytd_pre_close_amt = 0 
							LET modu_rec_accounthistcur.base_open_amt = 0 
							LET modu_rec_accounthistcur.base_debit_amt = 0 
							LET modu_rec_accounthistcur.base_credit_amt = 0 
							LET modu_rec_accounthistcur.base_close_amt = 0 
							LET modu_err_message = "Account history INSERT: ", 
							modu_rec_accounthistcur.acct_code, 
							" currency: ", 
							modu_rec_accounthistcur.currency_code 
							INSERT INTO accounthistcur VALUES (modu_rec_accounthistcur.*) 
						END IF 
					END FOREACH 
				END IF 
			END FOREACH 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 

END FUNCTION 



############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE max_year LIKE period.year_num 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg_str1 STRING 
	DEFINE l_arg_str2 STRING 

	LET l_msgresp=kandoomsg("G",1037,"") 

	#1037 Enter Account Details - ESC TO Continue
	INPUT 
	modu_acct1_code, 
	modu_acct2_code, 
	modu_rec_period.year_num WITHOUT DEFAULTS 
	FROM 
	acct1_code, 
	acct2_code, 
	year_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSA","inp-acct") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (modu_acct1_code) 
			LET modu_acct1_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			DISPLAY modu_acct1_code TO acct1_code 

			NEXT FIELD acct1_code 

		ON ACTION "LOOKUP" infield (modu_acct2_code) 
			LET modu_acct2_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			DISPLAY modu_acct2_code TO acct2_code 

			NEXT FIELD acct2_code 

		AFTER FIELD acct1_code 
			IF NOT modu_multiledger_ind THEN 
				IF modu_acct1_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9138,"") 
					#9138 Accumulated Profit Account code does NOT exist - Try Window
					NEXT FIELD acct1_code 
				END IF 
			END IF 
			IF modu_acct1_code IS NULL THEN 
				LET modu_desc1_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_acct1_code 
				AND type_ind in ("L","N") 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9138,"") 
					#9138 Accumulated Profit Account code does NOT exist - Try Window
					NEXT FIELD acct1_code 
				ELSE 
					LET modu_desc1_text = modu_rec_coa.desc_text 
				END IF 
			END IF 
			DISPLAY modu_desc1_text TO desc1_text 

		AFTER FIELD acct2_code 
			IF modu_acct2_code IS NULL THEN 
				LET modu_desc2_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_acct2_code 
				AND type_ind = "N" 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9132,"") 
					#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct2_code 
				ELSE 
					LET modu_desc2_text = modu_rec_coa.desc_text 
				END IF 
			END IF 
			DISPLAY modu_desc2_text TO desc2_text 

		BEFORE FIELD year_num 
			LET l_msgresp=kandoomsg("G",1037,"") 
			#1037 Enter Account Details - ESC TO Continue

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF NOT modu_multiledger_ind THEN 
				IF modu_acct1_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9138,"") 
					#9138 Accumulated Profit Account code does NOT exist - Try Window
					NEXT FIELD acct1_code 
				END IF 
			END IF 
			IF modu_acct1_code IS NULL THEN 
				LET modu_desc1_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_acct1_code 
				AND type_ind in ("L","N") 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9138,"") 
					#9138 Accumulated Profit Account code does NOT exist - Try Window
				ELSE 
					LET modu_desc1_text = modu_rec_coa.desc_text 
				END IF 
			END IF 

			LET modu_accum_profit_acct = modu_acct1_code 
			IF modu_acct2_code IS NULL THEN 
				LET modu_desc2_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_acct2_code 
				AND type_ind = "N" 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9132,"") 
					#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct2_code 
				ELSE 
					LET modu_desc2_text = modu_rec_coa.desc_text 
				END IF 
			END IF 

			LET modu_net_worth_acct = modu_acct2_code 
			DISPLAY modu_desc1_text TO desc1_text 
			DISPLAY modu_desc2_text TO desc2_text 

			SELECT unique year_num INTO modu_fisc_year FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_period.year_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9020,"") 
				#9020 "Fiscal Year NOT SET up"
				NEXT FIELD year_num 
			END IF 
			SELECT max(year_num) INTO max_year FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF max_year > (modu_fisc_year + 1) THEN 
				LET l_msgresp = kandoomsg("G",8006,"") 
				#8006 "More than one forward year OPEN - ok TO close?"
				IF l_msgresp = "N" THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 
			LET l_msgresp = kandoomsg("G",1002,"") 
			#1002 " Searching database - please wait"
			# check any journals NOT yet posted IF so get TO post
			SELECT unique 1 FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_fisc_year 
			AND post_flag = "N" 
			IF status <> NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",7002,"") 
				#7002 "Batches still need posting, going TO post program"
				CALL run_prog("GP2","","","","") 
				NEXT FIELD year_num 
			END IF 
			SELECT unique 1 FROM account, coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND account.year_num = modu_fisc_year 
			AND account.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.type_ind in ("I","E") 
			AND coa.acct_code = account.acct_code 
			AND account.bal_amt != 0 
			IF status <> NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",7003,"") 
				#7003 "Income OR expense accounts active this year-Run Close Period"
				CALL run_prog("GP4","","","","") 
				NEXT FIELD year_num 
			END IF 
			#
			SELECT max(period_num) INTO modu_end_period FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_fisc_year 
			#
			# SET up the batch
			# TO shift FROM YTD TO accumulated profits (i.e. networth TO liability)
			# (liability TO shareholders)
			# Close muliti-currency accounts IF in use, OTHERWISE use base
			# currency accounts
			IF glob_rec_glparms.use_currency_flag = "Y" THEN 
				IF modu_multiledger_ind THEN 
					IF NOT setup_ledg() THEN 
						# Deleted out of Networth Ledger setup
						NEXT FIELD year_num 
					ELSE 
						FOR i = 1 TO modu_ledg_cnt 
							LET modu_accum_profit_acct = modu_arr_rec_coa[i].prof_code 
							LET modu_net_worth_acct = modu_arr_rec_coa[i].acct_code 
							CALL close_currency() 
						END FOR 
					END IF 
				ELSE 
					CALL close_currency() 
				END IF 
			ELSE 
				IF modu_multiledger_ind THEN 
					IF NOT setup_ledg() THEN 
						# Deleted out of Networth Ledger setup
						NEXT FIELD acct1_code 
					ELSE 
						FOR i = 1 TO modu_ledg_cnt 
							LET modu_accum_profit_acct = modu_arr_rec_coa[i].prof_code 
							LET modu_net_worth_acct = modu_arr_rec_coa[i].acct_code 
							CALL do_close() 
						END FOR 
					END IF 
				ELSE 
					CALL do_close() 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_arg_str1 = "FISCAL_YEAR_NUM=", trim(modu_fisc_year) 
	LET l_arg_str2 = "TEMPPER=", trim(modu_end_period) 

	--CALL run_prog("GP2","y",modu_fisc_year,modu_end_period,"")
	CALL run_prog("GP2","AUTOPOST=y",l_arg_str1,l_arg_str2,"") 

	# Roll Assets AND Liabilities TO next year
	CALL rollover() 

	# now run History Rollup in the new year
	LET max_year = modu_fisc_year + 1 
	CALL run_prog("GS2",max_year,"","","") 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION do_close()
#
#
############################################################
FUNCTION do_close() 
	DEFINE sum_bal LIKE batchdetl.debit_amt 
	DEFINE counter INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	LET l_msgresp = error_recover (modu_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	BEGIN WORK 
		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		INITIALIZE modu_rec_batchhead.* TO NULL 

		LET modu_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
		LET modu_rec_batchhead.entry_code = "GL" 
		LET modu_rec_batchhead.cleared_flag = "Y" 
		LET modu_rec_batchhead.jour_date = today 
		LET modu_rec_batchhead.period_num = modu_end_period 
		LET modu_rec_batchhead.post_flag = "N" 
		LET modu_rec_batchhead.com1_text = "Year END Closing Entries" 
		LET modu_rec_batchhead.control_amt = 0 
		LET modu_rec_batchhead.debit_amt = 0 
		LET modu_rec_batchhead.control_qty = 0 
		LET modu_rec_batchhead.stats_qty = 0 
		LET modu_rec_batchhead.credit_amt = 0 
		LET modu_rec_batchhead.for_debit_amt = 0 
		LET modu_rec_batchhead.for_credit_amt = 0 
		LET modu_rec_batchhead.year_num = modu_fisc_year 
		LET modu_rec_batchhead.seq_num = 1 
		LET modu_rec_batchhead.source_ind = "G" 
		LET modu_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 

		LET modu_ofs_debit = 0 
		LET modu_ofs_credit = 0 
		LET counter = 0 
		LET modu_sel_text = "SELECT account.*, coa.* FROM account, coa", 
		" WHERE account.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
		" AND coa.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
		" AND account.year_num = '",modu_fisc_year,"'", 
		" AND account.acct_code = coa.acct_code", 
		" AND coa.type_ind = 'N'" 
		IF modu_multiledger_ind 
		OR modu_net_worth_acct IS NOT NULL THEN 
			LET modu_sel_text = modu_sel_text clipped, 
			" AND coa.acct_code = '",modu_net_worth_acct,"'" 
		END IF 

		PREPARE acct_state FROM modu_sel_text 
		DECLARE acctcurs CURSOR FOR acct_state 
		FOREACH acctcurs INTO modu_rec_account.*, modu_rec_coa.* 
			LET sum_bal = modu_rec_account.bal_amt 
			IF sum_bal != 0 THEN 
				IF counter = 0 THEN 
					#ie Found an account FOR this ledger with non zero balance
					#   Therefore, allocate next batch number...
					LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
					LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
					UPDATE glparms 
					SET next_jour_num = glob_rec_glparms.next_jour_num, 
					last_close_date = today 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
				END IF 
				IF sum_bal < 0 THEN 
					LET modu_ofs_debit = modu_ofs_debit - sum_bal 
				ELSE 
					LET modu_ofs_credit = modu_ofs_credit + sum_bal 
				END IF 
				LET modu_rec_batchdetl.tran_type_ind = "CL" 
				IF sum_bal < 0 THEN 
					LET modu_rec_batchdetl.debit_amt = 0 - sum_bal 
					LET modu_rec_batchdetl.credit_amt = 0 
				ELSE 
					LET modu_rec_batchdetl.credit_amt = sum_bal 
					LET modu_rec_batchdetl.debit_amt = 0 
				END IF 
				IF modu_rec_batchdetl.credit_amt IS NULL THEN 
					LET modu_rec_batchdetl.credit_amt = 0 
				END IF 
				IF modu_rec_batchdetl.debit_amt IS NULL THEN 
					LET modu_rec_batchdetl.debit_amt = 0 
				END IF 
				LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_batchdetl.acct_code = modu_rec_account.acct_code 
				LET modu_rec_batchdetl.desc_text = "Closing Entry" 
				LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.debit_amt 
				LET modu_rec_batchdetl.for_credit_amt = modu_rec_batchdetl.credit_amt 
				CALL setup() 
				INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
				LET counter = counter + 1 
			END IF 
		END FOREACH 

		IF counter > 0 THEN 
			IF modu_ofs_debit <> modu_ofs_credit THEN 
				CALL setup_offset() 
				CALL setup() 
				INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
			END IF 

			IF modu_rec_batchhead.debit_amt <> modu_rec_batchhead.credit_amt THEN 
				DISPLAY "" at 12,10 
				DISPLAY "Debit: ", modu_rec_batchhead.debit_amt, " Credits:", 
				modu_rec_batchhead.credit_amt at 12,10 
				LET l_msgresp = kandoomsg("G",8016,"") 
				#8016 "Batch IS out of balance, Continue ?"
				IF l_msgresp = "N" THEN 
					ROLLBACK WORK 
					RETURN 
				ELSE 
					CALL fgl_winmessage("19 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
					INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
				END IF 
			ELSE 
				LET modu_rec_batchhead.control_amt = modu_rec_batchhead.debit_amt 
				CALL fgl_winmessage("20 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
				INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
			END IF 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR 

	CONTINUE 

END FUNCTION 


############################################################
# FUNCTION setup()
#
#
############################################################
FUNCTION setup() 
	LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchdetl.stats_qty = 0 
	LET modu_rec_batchhead.debit_amt = modu_rec_batchhead.debit_amt 
	+ modu_rec_batchdetl.debit_amt 
	LET modu_rec_batchhead.credit_amt = modu_rec_batchhead.credit_amt 
	+ modu_rec_batchdetl.credit_amt 
	LET modu_rec_batchhead.for_debit_amt = modu_rec_batchhead.for_debit_amt 
	+ modu_rec_batchdetl.for_debit_amt 
	LET modu_rec_batchhead.for_credit_amt = modu_rec_batchhead.for_credit_amt 
	+ modu_rec_batchdetl.for_credit_amt 
	LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
	LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
	LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 
	LET modu_rec_batchdetl.tran_date = today 
	LET modu_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
	LET modu_rec_batchdetl.conv_qty = 1.0 
END FUNCTION 




############################################################
# FUNCTION setup_offset ()
#
#
############################################################
FUNCTION setup_offset () 
	LET modu_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchdetl.tran_type_ind = "CL" 
	LET modu_rec_batchdetl.acct_code = modu_accum_profit_acct 
	LET modu_rec_batchdetl.desc_text = "Year END Closing Entry Offset" 
	IF modu_ofs_credit > modu_ofs_debit THEN 
		LET modu_rec_batchdetl.debit_amt = modu_ofs_credit - modu_ofs_debit 
		LET modu_rec_batchdetl.credit_amt = 0 
	ELSE 
		LET modu_rec_batchdetl.credit_amt = modu_ofs_debit - modu_ofs_credit 
		LET modu_rec_batchdetl.debit_amt = 0 
	END IF 
	LET modu_rec_batchdetl.for_debit_amt = modu_rec_batchdetl.debit_amt 
	LET modu_rec_batchdetl.for_credit_amt = modu_rec_batchdetl.credit_amt 

END FUNCTION 


############################################################
# FUNCTION close_currency()
#
#
############################################################
FUNCTION close_currency() 
	DEFINE prev_currency LIKE batchhead.currency_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	LET l_msgresp = error_recover (modu_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 

	LET modu_sel_text = "SELECT A.* FROM accountcur A, coa C", 
	" WHERE A.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND A.year_num = '",modu_fisc_year,"'", 
	" AND A.acct_code = C.acct_code", 
	" AND C.type_ind = 'N'", 
	" AND (A.bal_amt != 0 OR A.base_bal_amt != 0)" 
	IF modu_multiledger_ind 
	OR modu_net_worth_acct IS NOT NULL THEN 
		LET modu_sel_text = modu_sel_text clipped, 
		" AND C.acct_code = '",modu_net_worth_acct,"'", 
		" ORDER BY A.currency_code " 
	ELSE 
		LET modu_sel_text = modu_sel_text clipped, 
		" ORDER BY A.currency_code " 
	END IF 
	PREPARE close_curr FROM modu_sel_text 
	DECLARE close_curr_curs CURSOR FOR close_curr 
	BEGIN WORK 
		LOCK TABLE glparms in share MODE 
		LOCK TABLE accountcur in share MODE 
		LOCK TABLE batchhead in share MODE 
		LOCK TABLE batchdetl in share MODE 

		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		CALL set_up_header() 
		CALL set_up_detail() 
		LET prev_currency = NULL 

		FOREACH close_curr_curs INTO modu_rec_accountcur.* 
			IF prev_currency IS NULL THEN 
				CALL new_batch(modu_rec_accountcur.currency_code) 
				LET prev_currency = modu_rec_accountcur.currency_code 
			ELSE 
				IF modu_rec_accountcur.currency_code != prev_currency THEN 
					CALL finish_batch() 
					CALL new_batch(modu_rec_accountcur.currency_code) 
					LET prev_currency = modu_rec_accountcur.currency_code 
				END IF 
			END IF 
			CALL set_detl_amts(modu_rec_accountcur.bal_amt, 
			modu_rec_accountcur.base_bal_amt) 
			LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
			LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 
			LET modu_rec_batchdetl.acct_code = modu_rec_accountcur.acct_code 
			INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
		END FOREACH 
		IF prev_currency IS NOT NULL THEN 
			CALL finish_batch() 
			UPDATE glparms 
			SET next_jour_num = glob_rec_glparms.next_jour_num, 
			last_close_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR CONTINUE 

END FUNCTION 



############################################################
# FUNCTION set_up_header()
#
#
############################################################
FUNCTION set_up_header() 
	INITIALIZE modu_rec_batchhead.* TO NULL 
	LET modu_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
	LET modu_rec_batchhead.entry_code = "GL" 
	LET modu_rec_batchhead.cleared_flag = "Y" 
	LET modu_rec_batchhead.jour_date = today 
	LET modu_rec_batchhead.period_num = modu_end_period 
	LET modu_rec_batchhead.post_flag = "N" 
	LET modu_rec_batchhead.com1_text = "Year END Closing Entries" 
	LET modu_rec_batchhead.year_num = modu_fisc_year 
	LET modu_rec_batchhead.source_ind = "G" 

END FUNCTION 



############################################################
# FUNCTION set_up_detail()
#
#
############################################################
FUNCTION set_up_detail() 
	INITIALIZE modu_rec_batchdetl.* TO NULL 
	LET modu_rec_batchdetl.cmpy_code = modu_rec_batchhead.cmpy_code 
	LET modu_rec_batchdetl.jour_code = modu_rec_batchhead.jour_code 
	LET modu_rec_batchdetl.tran_type_ind = "CL" 
	LET modu_rec_batchdetl.tran_date = today 
	LET modu_rec_batchdetl.desc_text = "Closing Entry" 
	LET modu_rec_batchdetl.stats_qty = 0 
END FUNCTION 


############################################################
# FUNCTION new_batch(p_currency)
#
#
############################################################
FUNCTION new_batch(p_currency) 
	DEFINE p_currency LIKE batchhead.currency_code 

	LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
	LET modu_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET modu_rec_batchhead.currency_code = p_currency 
	LET modu_rec_batchhead.control_amt = 0 
	LET modu_rec_batchhead.debit_amt = 0 
	LET modu_rec_batchhead.credit_amt = 0 
	LET modu_rec_batchhead.control_qty = 0 
	LET modu_rec_batchhead.stats_qty = 0 
	LET modu_rec_batchhead.for_debit_amt = 0 
	LET modu_rec_batchhead.for_credit_amt = 0 
	LET modu_rec_batchhead.seq_num = 1 
	LET modu_rec_batchdetl.jour_num = modu_rec_batchhead.jour_num 
	LET modu_rec_batchdetl.currency_code = modu_rec_batchhead.currency_code 
	LET modu_rec_batchdetl.desc_text = "Closing Entry" 
END FUNCTION 


############################################################
# FUNCTION set_detl_amts(p_for_amt, p_base_amt)
#
# Amounts posted should close the account TO zero FOR the period
# Closing amounts > 0 (DR balance) result in a Credit posting AND
# closing amounts < 0 (CR balance) result in a Debit posting (sign reversed)
############################################################
FUNCTION set_detl_amts(p_for_amt, p_base_amt) 
	DEFINE p_for_amt LIKE batchdetl.debit_amt 
	DEFINE p_base_amt LIKE batchdetl.debit_amt 

	CASE 
		WHEN (p_for_amt = 0) 
			LET modu_rec_batchdetl.for_debit_amt = 0 
			LET modu_rec_batchdetl.for_credit_amt = 0 
		WHEN (p_for_amt > 0) 
			LET modu_rec_batchdetl.for_credit_amt = p_for_amt 
			LET modu_rec_batchdetl.for_debit_amt = 0 
			LET modu_rec_batchhead.for_credit_amt = 
			modu_rec_batchhead.for_credit_amt + modu_rec_batchdetl.for_credit_amt 
		OTHERWISE 
			LET modu_rec_batchdetl.for_debit_amt = 0 - p_for_amt 
			LET modu_rec_batchdetl.for_credit_amt = 0 
			LET modu_rec_batchhead.for_debit_amt = 
			modu_rec_batchhead.for_debit_amt + modu_rec_batchdetl.for_debit_amt 
	END CASE 
	CASE 
		WHEN (p_base_amt = 0) 
			LET modu_rec_batchdetl.debit_amt = 0 
			LET modu_rec_batchdetl.credit_amt = 0 
		WHEN (p_base_amt > 0) 
			LET modu_rec_batchdetl.credit_amt = p_base_amt 
			LET modu_rec_batchdetl.debit_amt = 0 
			LET modu_rec_batchhead.credit_amt = 
			modu_rec_batchhead.credit_amt + modu_rec_batchdetl.credit_amt 
		OTHERWISE 
			LET modu_rec_batchdetl.debit_amt = 0 - p_base_amt 
			LET modu_rec_batchdetl.credit_amt = 0 
			LET modu_rec_batchhead.debit_amt = 
			modu_rec_batchhead.debit_amt + modu_rec_batchdetl.debit_amt 
	END CASE 
END FUNCTION 



############################################################
# FUNCTION finish_batch()
#
#
############################################################
FUNCTION finish_batch() 
	DEFINE bal_for_amt LIKE batchhead.debit_amt 
	DEFINE bal_base_amt LIKE batchhead.debit_amt 


	LET bal_for_amt = modu_rec_batchhead.for_debit_amt 
	- modu_rec_batchhead.for_credit_amt 
	LET bal_base_amt = modu_rec_batchhead.debit_amt 
	- modu_rec_batchhead.credit_amt 
	IF bal_for_amt != 0 OR bal_base_amt != 0 THEN 
		CALL set_detl_amts(bal_for_amt, 
		bal_base_amt) 
		LET modu_rec_batchdetl.acct_code = modu_accum_profit_acct 
		LET modu_rec_batchdetl.seq_num = modu_rec_batchhead.seq_num 
		LET modu_rec_batchhead.seq_num = modu_rec_batchhead.seq_num + 1 
		LET modu_rec_batchdetl.desc_text = "Year END Closing Entry Offset" 
		INSERT INTO batchdetl VALUES (modu_rec_batchdetl.*) 
	END IF 
	LET modu_rec_batchhead.control_amt = modu_rec_batchhead.for_debit_amt 
	CALL fgl_winmessage("21 Learning batch head codes - tell Hubert",modu_rec_batchhead.source_ind,"info") 
	INSERT INTO batchhead VALUES (modu_rec_batchhead.*) 
END FUNCTION 



############################################################
# FUNCTION setup_ledg()
#
#
############################################################
FUNCTION setup_ledg() 
	DEFINE modu_rec_coa RECORD LIKE coa.* 
	DEFINE query_text CHAR(300) 
	DEFINE l_flex_code LIKE validflex.flex_code 
	DEFINE i SMALLINT 
	DEFINE idx2 SMALLINT 
	DEFINE post_ind SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg455 with FORM "G455" 
	CALL windecoration_g("G455") 

	DECLARE c_validflex CURSOR FOR 
	SELECT flex_code FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = modu_rec_structure.start_num 
	ORDER BY flex_code 
	LET idx2 = 0 
	LET query_text = " SELECT unique 1 FROM coa ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND acct_code[?,?] = '",l_flex_code,"' ", 
	" AND type_ind in ('I','E') " 
	PREPARE s_coa FROM query_text 
	DECLARE c_coa CURSOR FOR s_coa 
	FOREACH c_validflex INTO l_flex_code 
		OPEN c_coa USING modu_start_num,modu_length 
		FETCH c_coa 
		IF status = NOTFOUND THEN 
			CLOSE c_coa 
			CONTINUE FOREACH 
		END IF 
		CLOSE c_coa 
		LET idx2 = idx2 + 1 
		LET modu_arr_rec_coa[idx2].flex_code = l_flex_code 
		LET modu_arr_rec_coa[idx2].acct_ind = " " 
		IF modu_accum_profit_acct IS NULL THEN 
			LET modu_arr_rec_coa[idx2].prof_code = NULL 
			LET modu_arr_rec_coa[idx2].acct_ind = "*" 
		ELSE 
			LET modu_arr_rec_coa[idx2].prof_code = modu_accum_profit_acct 
			LET modu_arr_rec_coa[idx2].prof_code[modu_start_num,modu_length] = 
			l_flex_code[modu_start_num,modu_length] 
			SELECT unique 1 FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_arr_rec_coa[idx2].prof_code 
			AND type_ind in ("N","L") 
			IF status = NOTFOUND THEN 
				LET modu_arr_rec_coa[idx2].acct_ind = "*" 
			END IF 
		END IF 

		IF modu_net_worth_acct IS NULL THEN 
			LET modu_arr_rec_coa[idx2].acct_code = NULL 
			LET modu_arr_rec_coa[idx2].acct_ind = "*" 
		ELSE 
			LET modu_arr_rec_coa[idx2].acct_code = modu_net_worth_acct 
			LET modu_arr_rec_coa[idx2].acct_code[modu_start_num,modu_length] = 
			l_flex_code[modu_start_num,modu_length] 
			SELECT unique 1 FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_arr_rec_coa[idx2].acct_code 
			AND type_ind = "N" 
			IF status = NOTFOUND THEN 
				LET modu_arr_rec_coa[idx2].acct_ind = "*" 
			END IF 
		END IF 

		IF idx2 = 200 THEN 
			LET l_msgresp = kandoomsg("G",9109,idx2) 
			#9109 " First ??? Ledgers Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx2 = 0 THEN 
		LET l_msgresp = kandoomsg("G",9110,"") 
		#9110" No ledgers satisfied selection criteria "
		RETURN false 
	END IF 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(idx2) 
	LET modu_ledg_cnt = idx2 
	LET l_msgresp = kandoomsg("G",1035,"") 

	#1035 " RETURN on line TO Edit "
	INPUT ARRAY modu_arr_rec_coa WITHOUT DEFAULTS FROM sr_coa.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSA","inp-arr-coa") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (prof_code) 
			LET modu_arr_rec_coa[idx2].prof_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD acct_code 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET modu_arr_rec_coa[idx2].acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD acct_code 

		BEFORE ROW 
			LET idx2 = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY modu_arr_rec_coa[idx2].*
			#     TO sr_coa[scrn].*

		AFTER FIELD prof_code 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("prevpage")) THEN 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 " No more rows in the direction you are going"
					NEXT FIELD prof_code 
				END IF 
				IF modu_arr_rec_coa[idx2].prof_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD prof_code 
				END IF 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_arr_rec_coa[idx2].prof_code 
				AND type_ind in ("N","L") 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9138,"") 
					#9138 Accumulated Profit Account code does NOT exist - Try Window
					NEXT FIELD prof_code 
				END IF 
				IF modu_arr_rec_coa[idx2].prof_code[modu_start_num,modu_length] != 
				modu_arr_rec_coa[idx2].flex_code THEN 
					LET l_msgresp=kandoomsg("G",9117,"") 
					#9117 Account code does NOT exist FOR this Ledger - Try Window
					NEXT FIELD prof_code 
				END IF 
			END IF 

		AFTER FIELD acct_code 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("prevpage")) THEN 
			ELSE 
				IF (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("RETURN")) 
				AND fgl_lastkey() != fgl_keyval("accept") 
				AND arr_curr() = arr_count() THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001 " No more rows in the direction you are going"
					NEXT FIELD acct_code 
				END IF 
				IF modu_arr_rec_coa[idx2].acct_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct_code 
				END IF 
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_arr_rec_coa[idx2].acct_code 
				AND type_ind = "N" 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("G",9132,"") 
					#9132 Networth Account code does NOT exist - Try Window
					NEXT FIELD acct_code 
				END IF 
				IF modu_arr_rec_coa[idx2].acct_code[modu_start_num,modu_length] != 
				modu_arr_rec_coa[idx2].flex_code THEN 
					LET l_msgresp=kandoomsg("G",9117,"") 
					#9117 Account code does NOT exist FOR this Ledger - Try Window
					NEXT FIELD acct_code 
				END IF 
			END IF 
			#AFTER ROW
			#   DISPLAY modu_arr_rec_coa[idx2].*
			#        TO sr_coa[scrn].*

		AFTER INPUT 
			LET post_ind = true 
			IF int_flag OR quit_flag THEN 
				LET post_ind = false 
				EXIT INPUT 
			ELSE 
				FOR i = 1 TO modu_ledg_cnt 
					LET modu_arr_rec_coa[i].acct_ind = " " 
					IF modu_arr_rec_coa[i].prof_code IS NULL THEN 
						LET modu_arr_rec_coa[i].acct_ind = "*" 
						LET post_ind = false 
					END IF 
					SELECT unique 1 FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = modu_arr_rec_coa[i].prof_code 
					AND type_ind in ("N","L") 
					IF status = NOTFOUND THEN 
						LET modu_arr_rec_coa[i].acct_ind = "*" 
						LET post_ind = false 
					END IF 
					IF modu_arr_rec_coa[i].acct_code IS NULL THEN 
						LET modu_arr_rec_coa[i].acct_ind = "*" 
						LET post_ind = false 
					END IF 
					SELECT unique 1 FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = modu_arr_rec_coa[i].acct_code 
					AND type_ind = "N" 
					IF status = NOTFOUND THEN 
						LET modu_arr_rec_coa[i].acct_ind = "*" 
						LET post_ind = false 
					END IF 
				END FOR 
				IF NOT post_ind THEN 
					LET l_msgresp=kandoomsg("G",9139,"") 
					#9139 "Profit Account code(s) do NOT exist - Try Window"
					NEXT FIELD prof_code 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW wg455 

	RETURN post_ind 
END FUNCTION 
