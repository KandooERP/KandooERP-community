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

	Source code beautified by beautify.pl on 2020-01-03 14:28:31	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G2R  allows END of period batches TO reversed as a group.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE glob_rev_year SMALLINT 
	DEFINE glob_rev_period SMALLINT 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("G2R") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wg423 with FORM "G423" 
	CALL windecoration_g("G423") 

	--   SELECT * INTO glob_rec_glparms.* FROM glparms
	--      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	--        AND key_code = '1'
	--   IF STATUS = NOTFOUND THEN

	IF NOT get_gl_setup_state() THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 " General Ledger Parameters Not Set Up"
		EXIT PROGRAM 
	END IF 
	WHILE G2R_header() 
	END WHILE 

	CLOSE WINDOW wg423 

END MAIN 


############################################################
# FUNCTION G2R_header()
#
#
############################################################
FUNCTION G2R_header() 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_jnl_ind SMALLINT 
	DEFINE l_err_ind SMALLINT 
	DEFINE l_failed_it SMALLINT 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1041,"") 
	#1041  Enter Batch Information - ESC TO Continue"
	DISPLAY BY NAME glob_rec_glparms.acrl_code, 
	glob_rec_glparms.rev_acrl_code, 
	glob_rec_glparms.last_acrl_yr_num, 
	glob_rec_glparms.last_acrl_per_num 

	LET l_query_text = "SELECT year_num, period_num FROM period ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND (year_num = ? AND period_num > ?) ", 
	"OR (year_num > ?) ", 
	"ORDER BY year_num, period_num" 
	PREPARE s_period FROM l_query_text 
	DECLARE c_period CURSOR FOR s_period 
	SELECT desc_text INTO l_rec_journal.desc_text FROM journal 
	WHERE jour_code = glob_rec_glparms.acrl_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 " General Ledger Parameters Not Set Up"
		RETURN false 
	ELSE 
		DISPLAY l_rec_journal.desc_text TO accdesc 

	END IF 
	SELECT desc_text INTO l_rec_journal.desc_text FROM journal 
	WHERE jour_code = glob_rec_glparms.rev_acrl_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 " General Ledger Parameters Not Set Up"
		RETURN false 
	ELSE 
		DISPLAY l_rec_journal.desc_text TO acrdesc 

	END IF 
	INITIALIZE glob_rec_batchhead.* TO NULL 
	IF glob_rec_glparms.last_acrl_yr_num = 0 
	AND glob_rec_glparms.last_acrl_per_num = 0 THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
		RETURNING glob_rec_batchhead.year_num, 
		glob_rec_batchhead.period_num 
	ELSE 
		OPEN c_period USING glob_rec_glparms.last_acrl_yr_num, 
		glob_rec_glparms.last_acrl_per_num, 
		glob_rec_glparms.last_acrl_yr_num 
		FETCH c_period INTO glob_rec_batchhead.year_num, 
		glob_rec_batchhead.period_num 
		IF status = NOTFOUND THEN 
			LET glob_rec_batchhead.year_num = NULL 
			LET glob_rec_batchhead.period_num = NULL 
		END IF 
	END IF 
	OPEN c_period USING glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_rec_batchhead.year_num 
	FETCH c_period INTO glob_rev_year, 
	glob_rev_period 
	IF status = NOTFOUND THEN 
		LET glob_rev_year = NULL 
		LET glob_rev_period = NULL 
	END IF 
	CLOSE c_period 

	INPUT glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_rev_year, 
	glob_rev_period, 
	glob_rec_batchhead.com1_text, 
	glob_rec_batchhead.com2_text WITHOUT DEFAULTS 
	FROM batchhead.year_num, 
	batchhead.period_num, 
	year, 
	period, 
	batchhead.com1_text, 
	batchhead.com2_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G2R","input-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				LEDGER_TYPE_GL) 
			RETURNING 
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				l_failed_it 
			IF l_failed_it THEN 
				NEXT FIELD batchhead.year_num 
			END IF 
			
			IF (glob_rec_batchhead.year_num = glob_rec_glparms.last_acrl_yr_num 
			AND glob_rec_batchhead.period_num = glob_rec_glparms.last_acrl_per_num) 
			OR glob_rec_batchhead.year_num < glob_rec_glparms.last_acrl_yr_num 
			OR (glob_rec_batchhead.year_num = glob_rec_glparms.last_acrl_yr_num 
			AND glob_rec_batchhead.period_num < glob_rec_glparms.last_acrl_per_num) THEN 
				LET l_msgresp = kandoomsg("G",9135,"")	# 9135 "This year AND period has already been reversed"
				NEXT FIELD batchhead.year_num 
			END IF 
			OPEN c_period USING glob_rec_batchhead.year_num, 
			glob_rec_batchhead.period_num, 
			glob_rec_batchhead.year_num 
			FETCH c_period INTO glob_rev_year, 
			glob_rev_period 
			IF status = NOTFOUND THEN 
				LET glob_rev_year = NULL 
				LET glob_rev_period = NULL 
			END IF 
			CLOSE c_period 
			DISPLAY glob_rev_year, 
			glob_rev_period 
			TO year, 
			period 

		AFTER FIELD period 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				glob_rev_year, 
				glob_rev_period, 
				LEDGER_TYPE_GL) 
			RETURNING 
				glob_rev_year, 
				glob_rev_period, 
				l_failed_it 
			
			IF l_failed_it THEN 
				NEXT FIELD year 
			END IF 
			
			IF (glob_rev_year = glob_rec_batchhead.year_num 
			AND	glob_rev_period = glob_rec_batchhead.period_num) 
			OR glob_rev_year < glob_rec_batchhead.year_num 
			OR (glob_rev_year = glob_rec_batchhead.year_num 
			AND glob_rev_period < glob_rec_batchhead.period_num) THEN 
				LET l_msgresp = kandoomsg("G",9136,"")# 9136 "Cannot reverse INTO source OR prior periods"
				NEXT FIELD year 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF (glob_rec_batchhead.year_num = glob_rec_glparms.last_acrl_yr_num AND 
				glob_rec_batchhead.period_num = glob_rec_glparms.last_acrl_per_num) 
				OR glob_rec_batchhead.year_num < glob_rec_glparms.last_acrl_yr_num 
				OR (glob_rec_batchhead.year_num = glob_rec_glparms.last_acrl_yr_num AND 
				glob_rec_batchhead.period_num < glob_rec_glparms.last_acrl_per_num) THEN 
					LET l_msgresp = kandoomsg("G",9135,"") 
					# 9135 "This year AND period has already been reversed"
					NEXT FIELD batchhead.year_num 
				END IF 
				IF (glob_rev_year = glob_rec_batchhead.year_num AND 
				glob_rev_period = glob_rec_batchhead.period_num) 
				OR glob_rev_year < glob_rec_batchhead.year_num 
				OR (glob_rev_year = glob_rec_batchhead.year_num AND 
				glob_rev_period < glob_rec_batchhead.period_num) THEN 
					LET l_msgresp = kandoomsg("G",9136,"") 
					# 9136 "Cannot reverse INTO source OR prior periods"
					NEXT FIELD year 
				END IF 
				LET l_jnl_ind = false 
				LET l_err_ind = false 
				DECLARE c_batchhead CURSOR FOR 
				SELECT * FROM batchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_glparms.acrl_code 
				AND year_num = glob_rec_batchhead.year_num 
				AND period_num = glob_rec_batchhead.period_num 

				FOREACH c_batchhead INTO l_rec_batchhead.* 
					IF glob_rec_glparms.control_tot_flag = "N" THEN 
						IF l_rec_batchhead.for_debit_amt != l_rec_batchhead.for_credit_amt THEN 
							LET l_msgresp = kandoomsg("G",9055,"") 
							#9055 Cannot reverse out of balance batch
							LET l_err_ind = true 
							EXIT FOREACH 
						END IF 
					ELSE 
						IF l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_credit_amt 
						AND l_rec_batchhead.for_debit_amt = l_rec_batchhead.control_amt 
						AND l_rec_batchhead.stats_qty = l_rec_batchhead.control_qty 
						AND l_rec_batchhead.for_debit_amt > 0 THEN 
						ELSE 
							LET l_msgresp = kandoomsg("G",9055,"") 
							#9055 Cannot reverse out of balance batch
							LET l_err_ind = true 
							EXIT FOREACH 
						END IF 
					END IF 
					LET l_jnl_ind = true 

				END FOREACH 

				IF l_err_ind THEN 
					#Out of balance batches
					NEXT FIELD batchhead.year_num 
				END IF 
				IF NOT l_jnl_ind THEN 
					LET l_msgresp = kandoomsg("G",9137,"") 
					#9137 "No END of period Accrual journals found TO reverse"
					NEXT FIELD batchhead.year_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		CALL rev_batches() 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION rev_batches()
#
#
############################################################
FUNCTION rev_batches() 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_tempcred money(15,2) 
	DEFINE l_tempdebit money(15,2) 
	DEFINE l_source_batch1 LIKE batchhead.jour_num 
	DEFINE l_source_batch2 LIKE batchhead.jour_num 
	DEFINE l_rev_batch1 LIKE batchhead.jour_num 
	DEFINE l_rev_batch2 LIKE batchhead.jour_num 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_mess CHAR(63) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",1005,"") 
	#1005 " Updating database - Please wait
	LET l_source_batch1 = 0 
	LET l_source_batch2 = 0 
	LET l_rev_batch1 = 0 
	LET l_rev_batch2 = 0 

	GOTO bypass 

	LABEL recovery: 
	LET l_msgresp = error_recover(l_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 
	BEGIN WORK 
		DECLARE c1_batchhead CURSOR FOR 
		SELECT * FROM batchhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_glparms.acrl_code 
		AND year_num = glob_rec_batchhead.year_num 
		AND period_num = glob_rec_batchhead.period_num 
		FOR UPDATE OF com2_text 
		FOREACH c1_batchhead INTO l_rec_batchhead.* 

			IF l_source_batch1 = 0 THEN 
				LET l_source_batch1 = l_rec_batchhead.jour_num 
			ELSE 
				LET l_source_batch2 = l_rec_batchhead.jour_num 
			END IF 
			DECLARE c_glparms CURSOR FOR 
			SELECT * INTO glob_rec_glparms.* FROM glparms 
			WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND glparms.key_code = "1" 
			FOR UPDATE 
			OPEN c_glparms 
			FETCH c_glparms INTO l_rec_glparms.* 
			LET l_rec_glparms.next_jour_num = l_rec_glparms.next_jour_num + 1 
			LET glob_rec_batchhead.jour_num = l_rec_glparms.next_jour_num 
			UPDATE glparms 
			SET next_jour_num = l_rec_glparms.next_jour_num, 
			last_acrl_yr_num = l_rec_batchhead.year_num, 
			last_acrl_per_num = l_rec_batchhead.period_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			CLOSE c_glparms 

			IF l_rev_batch1 = 0 THEN 
				LET l_rev_batch1 = glob_rec_batchhead.jour_num 
			ELSE 
				LET l_rev_batch2 = glob_rec_batchhead.jour_num 
			END IF 
			LET glob_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET glob_rec_batchhead.jour_code = glob_rec_glparms.rev_acrl_code 
			LET glob_rec_batchhead.year_num = glob_rev_year 
			LET glob_rec_batchhead.period_num = glob_rev_period 
			LET glob_rec_batchhead.post_flag = "N" 
			LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_batchhead.jour_date = today 
			LET glob_rec_batchhead.com2_text[1,12] = 
			"ORIG ", l_rec_batchhead.jour_num USING "######" 
			LET glob_rec_batchhead.debit_amt = 0 
			LET glob_rec_batchhead.credit_amt = 0 
			LET glob_rec_batchhead.for_debit_amt = 0 
			LET glob_rec_batchhead.for_credit_amt = 0 
			LET glob_rec_batchhead.control_amt = 0 
			LET glob_rec_batchhead.control_qty = 0 
			LET glob_rec_batchhead.stats_qty = 0 

			DECLARE curser_item CURSOR FOR 
			SELECT * INTO l_rec_batchdetl.* FROM batchdetl 
			WHERE jour_num = l_rec_batchhead.jour_num 
			AND jour_code = l_rec_batchhead.jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind != "ML" #####leave these FOR gp2 

			FOREACH curser_item 
				LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_batchdetl.ref_text = " " 
				LET l_rec_batchdetl.ref_num = 0 
				LET l_rec_batchdetl.jour_code = glob_rec_batchhead.jour_code 
				LET l_rec_batchdetl.jour_num = glob_rec_batchhead.jour_num 
				LET l_tempdebit = l_rec_batchdetl.for_debit_amt 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.for_credit_amt 
				LET l_rec_batchdetl.for_credit_amt = l_tempdebit 
				LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt 
				+ l_rec_batchdetl.for_debit_amt 
				LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt 
				+ l_rec_batchdetl.for_credit_amt 
				LET l_tempdebit = l_rec_batchdetl.debit_amt 
				LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.credit_amt 
				LET l_rec_batchdetl.credit_amt = l_tempdebit 
				LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt 
				+ l_rec_batchdetl.debit_amt 
				LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt 
				+ l_rec_batchdetl.credit_amt 
				IF l_rec_batchdetl.stats_qty IS NULL 
				OR l_rec_batchdetl.stats_qty = 0 THEN 
				ELSE 
					LET l_rec_batchdetl.stats_qty = 0 
					- l_rec_batchdetl.stats_qty 
					LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty 
					+ l_rec_batchdetl.stats_qty 
				END IF 

				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
			END FOREACH 

			LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
			LET glob_rec_batchhead.seq_num = l_rec_batchdetl.seq_num 
			LET glob_rec_batchhead.currency_code = l_rec_batchhead.currency_code 
			LET glob_rec_batchhead.conv_qty = l_rec_batchhead.conv_qty 
			LET glob_rec_batchhead.source_ind = l_rec_batchhead.source_ind 
			LET glob_rec_batchhead.cleared_flag = l_rec_batchhead.cleared_flag 
			LET glob_rec_batchhead.consol_num = l_rec_batchhead.consol_num 
			LET glob_rec_batchhead.rate_type_ind = l_rec_batchhead.rate_type_ind 
			LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 

			CALL fgl_winmessage("9 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
			INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 
			#
			#Now UPDATE original batch with the cross ref TO this reversal
			LET l_rec_batchhead.com2_text[1,12] = 
			"REV ", glob_rec_batchhead.jour_num USING "######" 
			UPDATE batchhead 
			SET com2_text = l_rec_batchhead.com2_text 
			WHERE CURRENT OF c1_batchhead 
		END FOREACH 

	COMMIT WORK 

	WHENEVER ERROR stop 
	IF l_source_batch1 = 0 
	AND l_source_batch2 = 0 THEN 
	ELSE 
		IF l_source_batch2 = 0 THEN 
			LET l_mess = "Batch ", l_source_batch1 USING "<<<<<<<", 
			" reversed by batch ", l_rev_batch1 USING "<<<<<<" 
		ELSE 
			LET l_mess = "Batch ", l_source_batch1 USING "<<<<<<<", " TO ", 
			l_source_batch2 USING "<<<<<<<", 
			" reversed by batch ", 
			l_rev_batch1 USING "<<<<<<", " TO ", l_rev_batch2 USING "<<<<<<" 
		END IF 
		LET l_msgresp = kandoomsg("G",7021,l_mess) 
		#7021 As Above
	END IF 

END FUNCTION 
