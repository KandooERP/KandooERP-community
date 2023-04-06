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


#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G28  allows the user create reverse journals of any
#              posted OR unposted  GJ journal
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_old_jour_num LIKE batchhead.jour_num 
	DEFINE glob_old_jour_code LIKE batchhead.jour_code 
	DEFINE glob_successful SMALLINT 
	DEFINE glob_mess CHAR(60) 
END GLOBALS 


############################################################
# GLOBAL Scope Variables
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("G28") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wg463 with FORM "G463" 
	CALL windecoration_g("G463") 

	--   SELECT * INTO glob_rec_glparms.* FROM glparms
	--      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	--        AND key_code = '1'
	--   IF STATUS = NOTFOUND THEN

	IF NOT get_gl_setup_state() THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 " General Ledger Parameters Not Set Up"
		EXIT PROGRAM 
	END IF 

	CALL fgl_winmessage("Program takes arguments","If you can find the time, please find out if this is just a verbose argument","info") 
	#IF num_args() > 0 THEN
	IF get_url_verbose() THEN 
		CALL auto_run() 
	ELSE 
		LET glob_successful = false 
		WHILE true 
			IF glob_successful THEN 
				LET glob_mess = "Batch ", glob_old_jour_num USING "<<<<<", 
				" reversed by batch ", 
				glob_rec_batchhead.jour_num USING "<<<<<", " successfully" 
				LET l_msgresp = kandoomsg("U",1,glob_mess) 
				LET glob_successful = false 
			END IF 
			LET l_msgresp = kandoomsg("G",1041,"") 
			#1041  Enter Batch Information - ESC TO Continue"
			IF G28_header() THEN 
				IF rev_header() THEN 
					CALL rev_insertit() 
				END IF 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
	END IF 
	CLOSE WINDOW wg463 
END MAIN 


############################################################
# FUNCTION G28_header()
#
#
############################################################
FUNCTION G28_header() 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	INITIALIZE glob_rec_batchhead.* TO NULL 

	INPUT BY NAME glob_rec_batchhead.jour_code, glob_rec_batchhead.jour_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G28","input-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_batchhead.jour_code = l_temp_text 
			END IF 
			NEXT FIELD jour_code 

		BEFORE FIELD jour_code 
			IF glob_rec_glparms.rj_code IS NULL THEN 
				SELECT * INTO glob_rec_journal.* FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_glparms.gj_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",5007,"") 
					#5007 " General Ledger Parameters Not Set Up"
					RETURN false 
				END IF 
				LET glob_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
				DISPLAY BY NAME glob_rec_batchhead.jour_code, glob_rec_journal.desc_text 

				NEXT FIELD jour_num 
			END IF 

		AFTER FIELD jour_code 
			SELECT * INTO glob_rec_journal.* FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = glob_rec_batchhead.jour_code 
			AND gl_flag = "Y" 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029 " Journal NOT found - Try Window"
				NEXT FIELD jour_code 
			END IF 
			DISPLAY BY NAME glob_rec_journal.desc_text 
			CALL comboList_journalNum("jour_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_batchhead.jour_code,COMBO_NULL_SPACE) 

		AFTER FIELD jour_num 
			SELECT * INTO glob_rec_batchhead.* FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = glob_rec_batchhead.jour_code 
			AND jour_num = glob_rec_batchhead.jour_num 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9053,"") 
				#9053 Batch number NOT found"
				NEXT FIELD jour_num 
			ELSE 
				IF glob_rec_batchhead.source_ind != "G" THEN 
					LET l_msgresp = kandoomsg("G",9524,"") 
					NEXT FIELD jour_code 
				END IF 
				SELECT * INTO l_rec_currency.* FROM currency 
				WHERE currency_code = glob_rec_batchhead.currency_code 
				DISPLAY BY NAME glob_rec_batchhead.jour_date, 
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				glob_rec_batchhead.currency_code, 
				glob_rec_batchhead.rate_type_ind, 
				glob_rec_batchhead.conv_qty, 
				glob_rec_batchhead.control_qty, 
				glob_rec_batchhead.control_amt, 
				glob_rec_batchhead.stats_qty, 
				glob_rec_batchhead.for_debit_amt, 
				glob_rec_batchhead.for_credit_amt, 
				glob_rec_batchhead.com1_text, 
				glob_rec_batchhead.com2_text, 
				glob_rec_batchhead.entry_code, 
				glob_rec_batchhead.jour_date 

				DISPLAY l_rec_currency.desc_text 
				TO currency.desc_text 

			END IF 
			IF glob_rec_glparms.control_tot_flag = "N" THEN 
				IF glob_rec_batchhead.for_debit_amt != glob_rec_batchhead.for_credit_amt THEN 
					LET l_msgresp = kandoomsg("G",9055,"") 
					#9055 Cannot reverse out of balance batch
					NEXT FIELD jour_num 
				END IF 
			ELSE 
				IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt 
				AND glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.control_amt 
				AND glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty 
				AND glob_rec_batchhead.for_debit_amt > 0 THEN 
				ELSE 
					LET l_msgresp = kandoomsg("G",9055,"") 
					#9055 Cannot reverse out of balance batch
					NEXT FIELD jour_num 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION rev_header()
#
#
############################################################
FUNCTION rev_header() 
	DEFINE l_failed_it SMALLINT 

	LET glob_rec_batchhead.post_flag = "N" 
	LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_batchhead.jour_date = today 
	IF glob_rec_batchhead.com2_text IS NOT NULL THEN 
		LET glob_rec_batchhead.com2_text[32,40] = "ORIG", 
		glob_rec_batchhead.jour_num USING "#####" 
	ELSE 
		LET glob_rec_batchhead.com2_text = "ORIG", glob_rec_batchhead.jour_num USING "#####" 
	END IF 
	# Need TO keep the previous journal number cos we're goin' TO
	# UPDATE that one's com2_text with the cross ref TO this one
	LET glob_old_jour_num = glob_rec_batchhead.jour_num 
	LET glob_old_jour_code = glob_rec_batchhead.jour_code 
	LET glob_rec_batchhead.jour_num = 0 
	DISPLAY BY NAME glob_rec_batchhead.jour_code, 
	glob_rec_batchhead.entry_code, 
	glob_rec_batchhead.jour_date, 
	glob_rec_batchhead.currency_code, 
	glob_rec_batchhead.conv_qty, 
	glob_rec_batchhead.for_debit_amt, 
	glob_rec_batchhead.for_credit_amt 


	INPUT BY NAME glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_rec_batchhead.com1_text, 
	glob_rec_batchhead.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G28","input-batchhead2") 

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
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
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
				NEXT FIELD year_num 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# FUNCTION rev_insertit()
#
#
############################################################
FUNCTION rev_insertit() 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	--	DEFINE l_tempcred money(15,2)
	DEFINE l_tempdebit money(15,2) 
	DEFINE l_stats_qty_flag SMALLINT 
	DEFINE l_err_message CHAR (40) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",1005,"") 
	#1005 " Updating database - Please wait
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
		#SET CONSTRAINTS DEFERRED #Eric Tip
		EXECUTE immediate "SET CONSTRAINTS ALL deferred" 

		DECLARE update_gl1 CURSOR FOR 
		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND glparms.key_code = "1" 
		FOR UPDATE OF next_jour_num 
		OPEN update_gl1 
		FETCH update_gl1 INTO glob_rec_glparms.* 
		LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
		LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 

		UPDATE glparms SET next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE CURRENT OF update_gl1 

		CLOSE update_gl1 

		LET l_stats_qty_flag = false 
		LET glob_rec_batchhead.debit_amt = 0 
		LET glob_rec_batchhead.credit_amt = 0 
		LET glob_rec_batchhead.for_debit_amt = 0 
		LET glob_rec_batchhead.for_credit_amt = 0 
		LET glob_rec_batchhead.control_amt = 0 
		LET glob_rec_batchhead.control_qty = 0 
		LET glob_rec_batchhead.stats_qty = 0 

		DECLARE curser_item CURSOR FOR 
		SELECT * INTO l_rec_batchdetl.* FROM batchdetl 
		WHERE batchdetl.jour_num = glob_old_jour_num 
		AND batchdetl.jour_code = glob_old_jour_code 
		AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batchdetl.tran_type_ind != "ML" 
		# Do NOT reverse Posted Multi-Ledger detail lines because Posting (GP2)
		# will execute the reversal as it works out Multi Ledger relationships...
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
				LET l_rec_batchdetl.stats_qty = 0 - l_rec_batchdetl.stats_qty + 0 
				LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty 
				+ l_rec_batchdetl.stats_qty 
				LET l_stats_qty_flag = true 
			END IF 

			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

		END FOREACH 

		LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
		LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 

		CALL fgl_winmessage("8 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 
		#
		#Now UPDATE original batch header with the cross reference TO this one
		DECLARE batch_curs CURSOR FOR 
		SELECT com2_text FROM batchhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_old_jour_code 
		AND jour_num = glob_old_jour_num 
		FOR UPDATE OF com2_text 
		OPEN batch_curs 
		FETCH batch_curs INTO glob_rec_batchhead.com2_text 
		IF glob_rec_batchhead.com2_text IS NOT NULL THEN 
			LET glob_rec_batchhead.com2_text[33,40] = 
			"REV", glob_rec_batchhead.jour_num USING "#####" 
		ELSE 
			LET glob_rec_batchhead.com2_text = 
			"REV", glob_rec_batchhead.jour_num USING "#####" 
		END IF 
		UPDATE batchhead SET com2_text = glob_rec_batchhead.com2_text 
		WHERE CURRENT OF batch_curs 
		CLOSE batch_curs 
		#
		# dont add zero value batches
		IF glob_rec_batchhead.for_debit_amt = 0 
		AND glob_rec_batchhead.for_credit_amt = 0 
		AND l_stats_qty_flag = false THEN 
			ROLLBACK WORK 
		ELSE 
		COMMIT WORK 
		LET glob_successful = true 
	END IF 
	WHENEVER ERROR stop 

END FUNCTION 


############################################################
# FUNCTION auto_run()
#
#
############################################################
FUNCTION auto_run() 
	DEFINE l_query_text CHAR(512) 

	LET l_query_text = get_url_query_text() 


	LET l_query_text = parmunset(l_query_text) 
	PREPARE getbatc FROM l_query_text 
	DECLARE c_batc CURSOR FOR getbatc 
	OPEN c_batc 

	FOREACH c_batc INTO glob_rec_batchhead.* 
		LET glob_old_jour_num = glob_rec_batchhead.jour_num 
		LET glob_old_jour_code = glob_rec_batchhead.jour_code 
		CALL rev_insertit() 
	END FOREACH 

END FUNCTION 
