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


# Module  : jourintf.4gl
# Purpose : GL interface FOR S/L
#
# This module "jourintf" creates one batch in the GL system FROM a
# SELECT constructed in any other program AND as such IS the multi
# purpose interface TO the GL system.
# It also looks AT the accounts AND verifies that they are there.
# IF NOT it uses the suspense account FROM glparms TO write TO
# the General Ledger batches (IF the 'use suspense' flag IS "Y") AND
# THEN reports on the batch AND problems.
# IF the account exists AND IS TO be reported in a special currency, the
# reporting currency amounts are calculated AND OUTPUT TO the batch
# detail.
# WHEN calling this program make sure you have started the REPORT.
#
# FIXME: revisit cursors (names) and executes
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../common/postfunc_GLOBALS.4gl"

GLOBALS 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	#DEFINE glob_try_again                    CHAR(1) #not used
	DEFINE glob_prob_found SMALLINT 
	DEFINE glob_coa_not_open SMALLINT 
	DEFINE glob_coa_not_found SMALLINT 
	#DEFINE glob_err_message                  CHAR(80) #not used
	--- modif ericv insit # pr_poststatus                RECORD LIKE poststatus.*
--	DEFINE glob_post_text CHAR(80) 
--	DEFINE glob_err_text CHAR(80) 
	#DEFINE glob_stat_code                    LIKE poststatus.status_code #not ued
--	DEFINE glob_posted_journal LIKE batchhead.jour_num 
--	DEFINE glob_one_trans SMALLINT 

END GLOBALS 
DEFINE prp_insert_batchhead PREPARED
DEFINE crs_batchdetl_this_journal CURSOR
DEFINE new_crs_batchdetl_this_journal CURSOR
DEFINE prp_insert_batchdetl PREPARED


############################################################
# MODULE Scope Variables
############################################################
#DEFINE modu_rec_poststatus                RECORD LIKE poststatus.*  #not used


############################################################
# FUNCTION jourintf2 (p_rpt_idx,
#										p_sel_stmt,
#                   p_rec_bal,
#                   p_periods,
#                   p_year_num,
#                   p_sent_jour_code,
#                   p_source_ind,
#                   p_currency_code,
#                   p_mod_code)
#
############################################################
FUNCTION jourintf2(p_rpt_idx,p_sel_stmt,p_rec_bal,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_sel_stmt STRING 
	DEFINE p_rec_bal RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_sent_jour_code LIKE batchhead.jour_code 
	DEFINE p_source_ind LIKE batchhead.jour_code 
	DEFINE p_currency_code LIKE batchhead.currency_code 
	DEFINE p_mod_code CHAR(2) 

	#DEFINE l_end_period LIKE batchhead.period_num #not used
	#DEFINE l_end_year LIKE batchhead.year_num #not used
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty, 
		analysis_text LIKE batchdetl.analysis_text 
	END RECORD 
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_next_seq SMALLINT 
	DEFINE l_line_count SMALLINT 
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	DEFINE l_sql_statement STRING
	DEFINE detl_curs CURSOR
	DEFINE curs_1 CURSOR

	
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		
	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jourintf *****" 
	END IF 

--	GOTO bypass 
--	LABEL recovery: 
--	CALL update_poststatus(true,status,p_mod_code) 
--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 

	LET l_line_count = 0 
	LET glob_prob_found = false 

--	PREPARE prep_1 FROM p_sel_stmt 
--	DECLARE curs_1 CURSOR with HOLD FOR prep_1 
	IF p_sel_stmt IS NOT NULL THEN  # we prepare all necessary prepares and cursors
		CALL curs_1.Declare(p_sel_stmt)
		CALL prp_insert_batchdetl.Prepare("INSERT INTO batchdetl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")

		LET l_sql_statement = "SELECT * ",
		" FROM batchdetl ",
		" WHERE cmpy_code = ? ",
		" AND jour_code = ? ",
		" AND jour_num = ? ",
		" ORDER BY seq_num "
		CALL crs_batchdetl_this_journal.Declare(l_sql_statement)

	END IF 

	INITIALIZE glob_rec_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 

	# check FOR zero also - calling routines do NOT always
	# initialise the global variabl posted_journal correctly AND the
	# default initial value IS zero
	IF glob_posted_journal IS NULL OR glob_posted_journal = 0 THEN 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				IF get_debug() THEN 
					DISPLAY "BEGIn WORK 1 - jourintf()" 
				END IF 
				LET glob_in_trans = true 
				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 

			DECLARE c1_glparms CURSOR FOR 
			SELECT glparms.* 
			INTO glob_rec_glparms.* 
			FROM glparms 
			WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 
			FOR UPDATE 

			FOREACH c1_glparms 
				LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
				LET glob_err_text = " GL Parms UPDATE - jourintf.4gl " 
				UPDATE glparms 
				SET next_jour_num = next_jour_num + 1 
				WHERE CURRENT OF c1_glparms 
			END FOREACH 

			LET glob_posted_journal = glob_rec_glparms.next_jour_num 
			LET glob_post_text = "Selected journal codes FROM glparms" 
			CALL update_poststatus(false,0,p_mod_code) 

			IF NOT glob_one_trans THEN 

				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 1 - jourintf()" 
				END IF 
			COMMIT WORK 
			LET glob_in_trans = false 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	ELSE 
		# commenced batchdetl INSERT but did nay finish
		# so we must delete out what batchdetl AND batchhead it did do
		IF NOT glob_one_trans THEN 
			IF get_debug() THEN 
				DISPLAY "BEGIn WORK 2 - jourintf()" 
			END IF 
			BEGIN WORK 
			LET glob_in_trans = true 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 

		# IF the post died mid batch we double check that the batch has
		# NOT been posted somehow. IF it has THEN it needs TO be manually
		# reversed FROM the tables before repost
		SELECT post_flag 
		INTO l_tmp_flag 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 
		IF l_tmp_flag = "Y" THEN {batch was somehow posted} 
			LET glob_err_text = "Batch ",glob_posted_journal USING "#######&", " has been posted - FATAL" 
			CALL update_poststatus(true,0,p_mod_code) 
		END IF 

		DELETE 
		FROM batchdetl 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 
		DELETE 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 

		LET glob_rec_glparms.next_jour_num = glob_posted_journal 
		IF NOT glob_one_trans THEN 
			IF get_debug() THEN 
				DISPLAY "COMMIT WORK 2 - jourintf()" 
			END IF 
			COMMIT WORK 
			LET glob_in_trans = false 
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	END IF 

	LET glob_rec_batchhead.cmpy_code = glob_rec_company.cmpy_code 
	LET glob_rec_batchhead.jour_code = p_sent_jour_code 
	LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_batchhead.jour_date = today 
	LET glob_rec_batchhead.year_num = p_year_num 
	LET glob_rec_batchhead.period_num = p_periods 
	LET glob_rec_batchhead.control_amt = 0 
	LET glob_rec_batchhead.debit_amt = 0 
	LET glob_rec_batchhead.credit_amt = 0 
	LET glob_rec_batchhead.for_debit_amt = 0 
	LET glob_rec_batchhead.for_credit_amt = 0 
	LET glob_rec_batchhead.control_qty = 0 
	LET glob_rec_batchhead.stats_qty = 0 
	LET glob_rec_batchhead.currency_code = p_currency_code 
	LET glob_rec_batchhead.source_ind = p_source_ind 

	IF glob_rec_glparms.use_clear_flag = "Y" THEN 
		LET glob_rec_batchhead.cleared_flag = "N" 
	ELSE 
		LET glob_rec_batchhead.cleared_flag = "Y" 
	END IF 

	LET glob_rec_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 

	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 

	LET glob_post_text = "Commenced batch lines INSERT" 
	CALL update_poststatus(false,0,p_mod_code) 
	MESSAGE "Creating GL batch: ", glob_rec_glparms.next_jour_num 
	-- DISPLAY " Creating GL batch  : ", glob_rec_glparms.next_jour_num AT 3,1  ATTRIBUTE(yellow)
	IF get_debug() THEN 
		DISPLAY "**** Creating GL batch : ", trim(glob_rec_glparms.next_jour_num) , " *****" 
	END IF 
	-- alch 2019.12.27 -- PP1 KD-1546
	IF NOT glob_one_trans THEN 
		IF get_debug() THEN 
			DISPLAY "BEGIn WORK 3 - jourintf()" 
		END IF 
		BEGIN WORK 
		LET glob_in_trans = true 
		IF get_debug() THEN 
			DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
		END IF 
	END IF 
	EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove WHEN ORDER OF INSERT TO batchdetl AND batchhead will be changed 
	--FOREACH curs_1 INTO l_rec_data.* 
	CALL curs_1.Open()
	WHILE curs_1.FetchNext(l_rec_data.* ) = 0
		LET glob_rec_batchhead.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.cmpy_code = glob_rec_company.cmpy_code 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
		LET l_rec_batchdetl.tran_date = l_rec_data.tran_date 
		LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
		LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
		LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
		LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.stats_qty = l_rec_data.stats_qty 
		LET l_rec_batchdetl.analysis_text = l_rec_data.analysis_text 
		LET l_rec_batchdetl.debit_amt = 0 
		LET l_rec_batchdetl.for_debit_amt = 0 
		LET l_rec_batchdetl.credit_amt = 0 
		LET l_rec_batchdetl.for_credit_amt = 0 
		CASE 
			WHEN (l_rec_data.base_debit_amt > 0) 
				LET l_rec_batchdetl.debit_amt = l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.credit_amt = 0 

			WHEN (l_rec_data.base_debit_amt < 0) 
				LET l_rec_batchdetl.credit_amt = -l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.debit_amt = 0 

			WHEN (l_rec_data.base_credit_amt > 0) 
				LET l_rec_batchdetl.credit_amt = l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.debit_amt = 0 

			WHEN (l_rec_data.base_credit_amt < 0) 
				LET l_rec_batchdetl.debit_amt = - l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
		END CASE 
		CASE 
			WHEN (l_rec_data.for_debit_amt > 0) 
				LET l_rec_batchdetl.for_debit_amt = l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_credit_amt = 0 

			WHEN (l_rec_data.for_debit_amt < 0) 
				LET l_rec_batchdetl.for_credit_amt = -l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 

			WHEN (l_rec_data.for_credit_amt > 0) 
				LET l_rec_batchdetl.for_credit_amt = l_rec_data.for_credit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 

			WHEN (l_rec_data.for_credit_amt < 0) 
				LET l_rec_batchdetl.for_debit_amt = - l_rec_data.for_credit_amt 
				LET l_rec_batchdetl.for_credit_amt = 0 
		END CASE 
		IF l_rec_batchdetl.debit_amt IS NULL THEN 
			LET l_rec_batchdetl.debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.credit_amt IS NULL THEN 
			LET l_rec_batchdetl.credit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_credit_amt = 0 
		END IF 

		# keep totals FOR balancing
		LET l_tot_base_debit = l_tot_base_debit + l_rec_batchdetl.debit_amt 
		LET l_tot_base_credit = l_tot_base_credit + l_rec_batchdetl.credit_amt 
		LET l_tot_for_debit = l_tot_for_debit + l_rec_batchdetl.for_debit_amt 
		LET l_tot_for_credit = l_tot_for_credit + l_rec_batchdetl.for_credit_amt 

		# increment the batch header
		LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 

		# check that AT least one side has a value
		IF NOT (l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		AND l_rec_batchdetl.stats_qty = 0 ) THEN 
			LET l_line_count = l_line_count + 1 
			LET glob_err_text = " Batchdetl INSERT (lines) - jourintf.4gl LINE 384" 
			--DISPLAY " Processing         : ",l_rec_batchdetl.ref_text AT 4,1
			--DISPLAY "                    : ",l_rec_batchdetl.ref_num AT 5,1
			MESSAGE "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
			IF get_debug() THEN 
				DISPLAY "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
				DISPLAY "glob_rec_batchhead.jour_code", glob_rec_batchhead.jour_code 
				DISPLAY "glob_rec_batchhead.jour_num", glob_rec_batchhead.jour_num 
				DISPLAY "glob_rec_batchhead.cmpy_code", glob_rec_batchhead.cmpy_code 
				DISPLAY "INSERT INTO batchdetl j-1 ****************************************************" 
			END IF 
			CALL prp_insert_batchdetl.Execute(l_rec_batchdetl.*) 
		END IF 

		INITIALIZE l_rec_batchdetl.* TO NULL 
	END WHILE #  curs_1

		LET glob_post_text = "Inserted all batchdetl records" 
		CALL update_poststatus(false,0,p_mod_code) 

		IF l_line_count > 0 THEN 
			LET l_rec_batchdetl.ref_text = " " 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.cmpy_code = glob_rec_company.cmpy_code 
			LET l_rec_batchdetl.jour_code = p_sent_jour_code 
			LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
			LET l_rec_batchdetl.seq_num = l_next_seq 
			LET l_next_seq = l_next_seq + 1 
			LET l_rec_batchdetl.tran_type_ind = p_rec_bal.tran_type_ind 
			LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
			LET l_rec_batchdetl.acct_code = p_rec_bal.acct_code 
			LET l_rec_batchdetl.desc_text = p_rec_bal.desc_text 
			LET l_rec_batchdetl.currency_code = p_currency_code 
			LET l_rec_batchdetl.analysis_text = "" 
			LET l_rec_batchdetl.stats_qty = 0 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 

			IF l_tot_base_debit > l_tot_base_credit THEN 
				LET l_rec_batchdetl.credit_amt = l_tot_base_debit - l_tot_base_credit 
			ELSE 
				LET l_rec_batchdetl.debit_amt = l_tot_base_credit - l_tot_base_debit 
			END IF 
			IF l_tot_for_debit > l_tot_for_credit THEN 
				LET l_rec_batchdetl.for_credit_amt = l_tot_for_debit - l_tot_for_credit 
			ELSE 
				LET l_rec_batchdetl.for_debit_amt = l_tot_for_credit - l_tot_for_debit 
			END IF 

			# IF balancing entry IS zero THEN dont add it TO the batch
			IF NOT (l_rec_batchdetl.credit_amt = 0 AND 
			l_rec_batchdetl.debit_amt = 0 AND 
			l_rec_batchdetl.for_credit_amt = 0 AND 
			l_rec_batchdetl.for_debit_amt = 0 AND 
			l_rec_batchdetl.stats_qty = 0 ) THEN 
				LET glob_err_text = "Batchdetl INSERT - (balancing entry)" 
				IF get_debug() THEN 
					DISPLAY glob_rec_batchhead.jour_code 
					DISPLAY glob_rec_batchhead.jour_num 
					DISPLAY glob_rec_batchhead.cmpy_code 
					DISPLAY "INSERT INTO batchdetl j-2" 
				END IF 
				--	EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove when order of INSERT to batchdetl and batchhead will be changed
				CALL prp_insert_batchdetl.Execute(l_rec_batchdetl.*) 

				#  increment the batch header
				LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
				LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
				LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
				LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
				LET glob_rec_batchhead.seq_num = l_next_seq 
			END IF 

			# INSERT batch header
			# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
			#       I)nventory AND Buy rate OTHERWISE

			IF glob_rec_glparms.use_currency_flag = "Y" AND 
			glob_rec_glparms.base_currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code != glob_rec_glparms.base_currency_code THEN 

				IF glob_rec_batchhead.source_ind matches "[AJI]" THEN 
					LET glob_rec_batchhead.rate_type_ind = "S" 
				ELSE 
					LET glob_rec_batchhead.rate_type_ind = "B" 
				END IF 
			ELSE 
				LET glob_rec_batchhead.rate_type_ind = " " 
			END IF 

			IF glob_rec_batchhead.currency_code IS NULL THEN 
				ERROR kandoomsg2("G",7000,glob_rec_batchhead.jour_num) 		#7000 Rate type indicator updated TO blank.
			END IF 

			LET glob_err_text = "Batchhead Insert - jourintf.4gl" 
			LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
			LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 
			IF get_debug() THEN 
				DISPLAY glob_rec_batchhead.jour_code 
				DISPLAY glob_rec_batchhead.jour_num 
				DISPLAY glob_rec_batchhead.cmpy_code 
				DISPLAY "INSERT INTO batchhead (only one instance)" 
			END IF 

			CASE glob_rec_batchhead.source_ind
				WHEN "G" #General/GL
					MESSAGE "GL/G - Posting General Ledger Batch"
					--SLEEP 1
				WHEN "C" # CashBook
					MESSAGE "GL/C (Cashbook) - Posting CashBook Batch"
					--SLEEP 1
				WHEN "R" # Purchasing System
					MESSAGE "PU/R - Posting Purchasing System Batch"
					--SLEEP 1
				WHEN "P" # Accounts Payable
					MESSAGE "AP/P - Posting Accounts Payable Batch"
					--SLEEP 1
				WHEN "A" # Accounts Receivable
					MESSAGE "AR/A - Posting Accounts Receivable Batch"
					--SLEEP 1
				WHEN "J" # Job Management ?
					MESSAGE "JM/J - Posting Job Management Batch"
					--SLEEP 1
				WHEN "I" # Warehouse IN
					MESSAGE "IN/I - Posting Warehouse Batch"
					--SLEEP 1
				
				OTHERWISE
					LET l_msg = "Unknown SOURCE_IND (main module group) source_ind=", trim(glob_rec_batchhead.source_ind), "\njourintf.4gl Function jourintf2() Line~554"
					CALL fgl_winmessage("Internal Knowledge Sharing",l_msg,"INFO")
			END CASE
 
			INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

			IF NOT glob_one_trans THEN 
				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 4 - jourintf()" 
				END IF 
				COMMIT WORK 
				LET glob_in_trans = false 

				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 
		-- alch 2019.12.27 -- PP1 KD-1546
		# now write the REPORT on this batch

		CALL crs_batchdetl_this_journal.Open(glob_rec_company.cmpy_code,p_sent_jour_code,glob_rec_glparms.next_jour_num) 

		SELECT company.* 
		INTO l_rec_company.* 
		FROM company 
		WHERE company.cmpy_code = glob_rec_company.cmpy_code 

		WHILE crs_batchdetl_this_journal.FetchNext(l_rec_batchdetl.*) = 0
			OUTPUT TO REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,l_rec_batchdetl.*,	l_rec_company.*)  
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_batchdetl.jour_code, l_rec_batchdetl.jour_num,p_rpt_idx) THEN
				EXIT WHILE 
			END IF 
		END WHILE # crs_batchdetl_this_journal
	ELSE 
		# nothing posted
		IF NOT glob_one_trans THEN 

			IF get_debug() THEN 
				DISPLAY "COMMIT WORK 5 - jourintf()" 
			END IF 

			COMMIT WORK 
			LET glob_in_trans = false 


			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 


		END IF 

		# RETURN 0 IF no UPDATE done
		LET glob_rec_glparms.next_jour_num = 0 
	END IF 

# RETURN the batch number, negative IF suspense a/c used, ELSE positive
# this enables batch number TO be recorded on the source table
# IF required. Needed in purchasing TO allow FOR reconcilliation
# of summary batch posting

IF glob_prob_found THEN 
	# suspense a/c used, RETURN NEGATIVE jour_num
	RETURN ( 0 - glob_rec_glparms.next_jour_num ) 
ELSE 
	RETURN glob_rec_glparms.next_jour_num 
END IF 

WHENEVER ERROR CONTINUE 

END FUNCTION # jourintf2

############################################################################
# use  jourintf2  OR split the entries between create_batchhead_entry + create_batchdetl_entry + report at the end

FUNCTION create_batchhead_entry(p_periods,p_year_num,p_jour_code,p_jour_num,p_source_ind,p_currency_code,p_postrun_num,p_mod_code)
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_jour_code LIKE batchhead.jour_code 
	DEFINE p_jour_num LIKE batchhead.jour_num 
	DEFINE p_source_ind LIKE batchhead.jour_code 
	DEFINE p_postrun_num LIKE batchhead.post_run_num
	DEFINE p_currency_code LIKE batchhead.currency_code 
	DEFINE p_mod_code CHAR(2) 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_sql_statement STRING

	IF prp_insert_batchhead.getStatement() IS NULL THEN
		LET l_sql_statement = "INSERT INTO batchhead VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
		CALL prp_insert_batchhead.Prepare(l_sql_statement)
	END IF
	LET l_rec_batchhead.cmpy_code = glob_rec_company.cmpy_code 
	LET l_rec_batchhead.jour_code = p_jour_code 
	LET l_rec_batchhead.jour_num = p_jour_num 
	LET l_rec_batchhead.post_run_num = p_postrun_num 
	LET l_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_batchhead.jour_date = today 
	LET l_rec_batchhead.year_num = p_year_num 
	LET l_rec_batchhead.period_num = p_periods 
	LET l_rec_batchhead.control_amt = 0 
	LET l_rec_batchhead.debit_amt = 0 
	LET l_rec_batchhead.credit_amt = 0 
	LET l_rec_batchhead.for_debit_amt = 0 
	LET l_rec_batchhead.for_credit_amt = 0 
	LET l_rec_batchhead.control_qty = 0 
	LET l_rec_batchhead.stats_qty = 0 
	LET l_rec_batchhead.currency_code = p_currency_code 
	LET l_rec_batchhead.source_ind = p_source_ind 

	IF glob_rec_glparms.use_clear_flag = "Y" THEN 
		LET l_rec_batchhead.cleared_flag = "N" 
	ELSE 
		LET l_rec_batchhead.cleared_flag = "Y" 
	END IF  

	LET l_rec_batchhead.post_flag = "N" 
	WHENEVER SQLERROR CONTINUE
	CALL prp_insert_batchhead.Execute(l_rec_batchhead.*)
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode
END FUNCTION # create_batchhead_entry()

# This function inserts one row in batchdetl
FUNCTION create_batchdetl_entry(p_jour_code,p_jour_num,p_seq_num,p_tran_type_ind,p_rec_document_basic,p_rec_batchdetl_data)
	DEFINE p_jour_code LIKE batchhead.jour_code 
	DEFINE p_jour_num LIKE batchhead.jour_num 
	DEFINE p_seq_num LIKE batchdetl.seq_num
	DEFINE p_tran_type_ind LIKE batchdetl.tran_type_ind
	DEFINE p_rec_document_basic RECORD 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		tran_date DATE, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty 
	END RECORD
	DEFINE p_rec_batchdetl_data RECORD 
		post_acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		stats_qty LIKE batchdetl.stats_qty, 
		analysis_text LIKE batchdetl.analysis_text, 
		debit_amt LIKE batchdetl.debit_amt, 
		credit_amt LIKE batchdetl.credit_amt 
	END RECORD 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_sql_statement STRING
	DEFINE prp_insert_batchdetl PREPARED

	IF prp_insert_batchdetl.getStatement() IS NULL THEN
		LET l_sql_statement = "INSERT INTO batchdetl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
		CALL prp_insert_batchdetl.Prepare(l_sql_statement)
	END IF
	LET l_rec_batchdetl.cmpy_code = glob_rec_company.cmpy_code 
	LET l_rec_batchdetl.jour_code = p_jour_code 
	LET l_rec_batchdetl.jour_num = p_jour_num
	LET l_rec_batchdetl.seq_num = p_seq_num 
	LET l_rec_batchdetl.tran_type_ind =  p_tran_type_ind 
	LET l_rec_batchdetl.tran_date =  p_rec_document_basic.tran_date
	LET l_rec_batchdetl.ref_num = p_rec_document_basic.ref_num
	LET l_rec_batchdetl.ref_text = p_rec_document_basic.ref_text 
	LET l_rec_batchdetl.acct_code = p_rec_batchdetl_data.post_acct_code 
	LET l_rec_batchdetl.desc_text = p_rec_batchdetl_data.desc_text 
	LET l_rec_batchdetl.currency_code = p_rec_document_basic.currency_code 
	LET l_rec_batchdetl.conv_qty = p_rec_document_basic.conv_qty 
	LET l_rec_batchdetl.stats_qty = p_rec_batchdetl_data.stats_qty 
	LET l_rec_batchdetl.analysis_text = p_rec_batchdetl_data.analysis_text 
	LET l_rec_batchdetl.debit_amt = 0 
	LET l_rec_batchdetl.for_debit_amt = 0 
	LET l_rec_batchdetl.credit_amt = 0 
	LET l_rec_batchdetl.for_credit_amt = 0 
	CASE 
		WHEN (p_rec_batchdetl_data.debit_amt > 0) 
			LET l_rec_batchdetl.debit_amt = p_rec_batchdetl_data.debit_amt 
			LET l_rec_batchdetl.credit_amt = 0 
		# If negative amount, we switch debit to credit and invert sign
		WHEN (p_rec_batchdetl_data.debit_amt < 0) 
			LET l_rec_batchdetl.credit_amt = -p_rec_batchdetl_data.debit_amt 
			LET l_rec_batchdetl.debit_amt = 0 

		WHEN (p_rec_batchdetl_data.credit_amt > 0) 
			LET l_rec_batchdetl.credit_amt = p_rec_batchdetl_data.credit_amt 
			LET l_rec_batchdetl.debit_amt = 0 

		WHEN (p_rec_batchdetl_data.credit_amt < 0) 
			LET l_rec_batchdetl.debit_amt = - p_rec_batchdetl_data.credit_amt 
			LET l_rec_batchdetl.credit_amt = 0 
	END CASE 
	
	IF glob_rec_glparms.use_currency_flag = "Y" THEN 
		LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt * p_rec_document_basic.conv_qty
		LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt * p_rec_document_basic.conv_qty
	ELSE
		LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt
		LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt
	END IF

	CASE 
		WHEN (l_rec_batchdetl.for_debit_amt > 0) 
			LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.for_debit_amt
			LET l_rec_batchdetl.for_credit_amt = 0 

		WHEN (l_rec_batchdetl.for_debit_amt < 0) 
			LET l_rec_batchdetl.for_credit_amt = -l_rec_batchdetl.for_debit_amt
			LET l_rec_batchdetl.for_debit_amt = 0 

		WHEN (l_rec_batchdetl.for_credit_amt > 0) 
			LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.for_credit_amt
			LET l_rec_batchdetl.for_debit_amt = 0 

		WHEN (l_rec_batchdetl.for_credit_amt < 0) 
			LET l_rec_batchdetl.for_debit_amt = - l_rec_batchdetl.for_credit_amt
			LET l_rec_batchdetl.for_credit_amt = 0 
	END CASE 
	IF l_rec_batchdetl.debit_amt IS NULL THEN 
		LET l_rec_batchdetl.debit_amt = 0 
	END IF 
	IF l_rec_batchdetl.credit_amt IS NULL THEN 
		LET l_rec_batchdetl.credit_amt = 0 
	END IF 
	IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
		LET l_rec_batchdetl.for_debit_amt = 0 
	END IF 
	IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
		LET l_rec_batchdetl.for_credit_amt = 0 
	END IF 

	WHENEVER SQLERROR CONTINUE
	CALL prp_insert_batchdetl.Execute(l_rec_batchdetl.*)
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode
END FUNCTION # create_batchdetl_entry

FUNCTION run_report_COM_jourintf_rpt_list_bd(p_rpt_idx,p_jour_code,p_jour_num)
	DEFINE p_rpt_idx INTEGER
	DEFINE p_jour_code LIKE batchdetl.jour_code
	DEFINE p_jour_num LIKE batchdetl.jour_num
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_sql_statement STRING
			
	IF crs_batchdetl_this_journal.getStatement() IS NULL THEN
		LET l_sql_statement = "SELECT * ",
		" FROM batchdetl ",
		" WHERE cmpy_code = ? ",
		" AND jour_code = ? ",
		" AND jour_num = ? ",
		" ORDER BY seq_num "
		CALL crs_batchdetl_this_journal.Declare(l_sql_statement)
	END IF

	CALL crs_batchdetl_this_journal.Open(glob_rec_company.cmpy_code,p_jour_code,p_jour_num) 
	SELECT company.* 
	INTO l_rec_company.* 
	FROM company 
	WHERE company.cmpy_code = glob_rec_company.cmpy_code 

	WHILE crs_batchdetl_this_journal.FetchNext(l_rec_batchdetl.*) = 0
		OUTPUT TO REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,l_rec_batchdetl.*,	l_rec_company.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_batchdetl.jour_code, l_rec_batchdetl.jour_num,p_rpt_idx) THEN
			EXIT WHILE 
		END IF 
	END WHILE # crs_batchdetl_this_journal
	FINISH REPORT COM_jourintf_rpt_list_bd

END FUNCTION # create_report_for journal


FUNCTION create_automatic_journal(p_rpt_idx,p_sel_stmt,p_rec_bal,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_sel_stmt STRING 
	DEFINE p_rec_bal RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_sent_jour_code LIKE batchhead.jour_code 
	DEFINE p_source_ind LIKE batchhead.jour_code 
	DEFINE p_currency_code LIKE batchhead.currency_code 
	DEFINE p_mod_code CHAR(2) 

	#DEFINE l_end_period LIKE batchhead.period_num #not used
	#DEFINE l_end_year LIKE batchhead.year_num #not used
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty, 
		analysis_text LIKE batchdetl.analysis_text 
	END RECORD 
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_next_seq SMALLINT 
	DEFINE l_line_count SMALLINT 
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg STRING
	DEFINE l_sql_statement STRING
	DEFINE new_prp_insert_batchdetl PREPARED
	DEFINE new_detl_curs CURSOR
	DEFINE new_curs_1 CURSOR

	
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		
	LET l_line_count = 0 
	LET glob_prob_found = false 

	IF p_sel_stmt IS NOT NULL THEN  # we prepare all necessary prepares and cursors
		CALL new_curs_1.Declare(p_sel_stmt)
		CALL new_prp_insert_batchdetl.Prepare("INSERT INTO batchdetl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
	
		LET l_sql_statement = "SELECT * ",
		" FROM batchdetl ",
		" WHERE cmpy_code = ? ",
		" AND jour_code = ? ",
		" AND jour_num = ? ",
		" ORDER BY seq_num "
		CALL new_crs_batchdetl_this_journal.Declare(l_sql_statement)

	END IF 

	INITIALIZE glob_rec_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 

	# check FOR zero also - calling routines do NOT always
	# initialise the global variabl posted_journal correctly AND the
	# default initial value IS zero
	IF glob_posted_journal IS NULL OR glob_posted_journal = 0 THEN 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				IF get_debug() THEN 
					DISPLAY "BEGIn WORK 1 - jourintf()" 
				END IF 
				LET glob_in_trans = true 
				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 

			DECLARE new_c1_glparms CURSOR FOR 
			SELECT glparms.* 
			INTO glob_rec_glparms.* 
			FROM glparms 
			WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 
			FOR UPDATE 

			FOREACH new_c1_glparms 
				LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
				LET glob_err_text = " GL Parms UPDATE - jourintf.4gl " 
				UPDATE glparms 
				SET next_jour_num = next_jour_num + 1 
				WHERE CURRENT OF new_c1_glparms 
			END FOREACH 

			LET glob_posted_journal = glob_rec_glparms.next_jour_num 
			LET glob_post_text = "Selected journal codes FROM glparms" 
			CALL update_poststatus(false,0,p_mod_code) 

			IF NOT glob_one_trans THEN 

				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 1 - jourintf()" 
				END IF 
			COMMIT WORK 
			LET glob_in_trans = false 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	ELSE 
		# commenced batchdetl INSERT but did nay finish
		# so we must delete out what batchdetl AND batchhead it did do
		IF NOT glob_one_trans THEN 
			IF get_debug() THEN 
				DISPLAY "BEGIn WORK 2 - jourintf()" 
			END IF 
			BEGIN WORK 
			LET glob_in_trans = true 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 

		# IF the post died mid batch we double check that the batch has
		# NOT been posted somehow. IF it has THEN it needs TO be manually
		# reversed FROM the tables before repost
		SELECT post_flag 
		INTO l_tmp_flag 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 
		IF l_tmp_flag = "Y" THEN {batch was somehow posted} 
			LET glob_err_text = "Batch ",glob_posted_journal USING "#######&", " has been posted - FATAL" 
			CALL update_poststatus(true,0,p_mod_code) 
		END IF 

		DELETE 
		FROM batchdetl 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 
		DELETE 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND jour_num = glob_posted_journal 

		LET glob_rec_glparms.next_jour_num = glob_posted_journal 
		IF NOT glob_one_trans THEN 
			IF get_debug() THEN 
				DISPLAY "COMMIT WORK 2 - jourintf()" 
			END IF 
			COMMIT WORK 
			LET glob_in_trans = false 
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	END IF 

	LET glob_rec_batchhead.cmpy_code = glob_rec_company.cmpy_code 
	LET glob_rec_batchhead.jour_code = p_sent_jour_code 
	LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_batchhead.jour_date = today 
	LET glob_rec_batchhead.year_num = p_year_num 
	LET glob_rec_batchhead.period_num = p_periods 
	LET glob_rec_batchhead.control_amt = 0 
	LET glob_rec_batchhead.debit_amt = 0 
	LET glob_rec_batchhead.credit_amt = 0 
	LET glob_rec_batchhead.for_debit_amt = 0 
	LET glob_rec_batchhead.for_credit_amt = 0 
	LET glob_rec_batchhead.control_qty = 0 
	LET glob_rec_batchhead.stats_qty = 0 
	LET glob_rec_batchhead.currency_code = p_currency_code 
	LET glob_rec_batchhead.source_ind = p_source_ind 

	IF glob_rec_glparms.use_clear_flag = "Y" THEN 
		LET glob_rec_batchhead.cleared_flag = "N" 
	ELSE 
		LET glob_rec_batchhead.cleared_flag = "Y" 
	END IF 

	LET glob_rec_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 

	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 

	LET glob_post_text = "Commenced batch lines INSERT" 
	CALL update_poststatus(false,0,p_mod_code) 
	MESSAGE "Creating GL batch: ", glob_rec_glparms.next_jour_num 
	-- DISPLAY " Creating GL batch  : ", glob_rec_glparms.next_jour_num AT 3,1  ATTRIBUTE(yellow)
	IF get_debug() THEN 
		DISPLAY "**** Creating GL batch : ", trim(glob_rec_glparms.next_jour_num) , " *****" 
	END IF 
	-- alch 2019.12.27 -- PP1 KD-1546
	IF NOT glob_one_trans THEN 
		IF get_debug() THEN 
			DISPLAY "BEGIn WORK 3 - jourintf()" 
		END IF 
		BEGIN WORK 
		LET glob_in_trans = true 
		IF get_debug() THEN 
			DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
		END IF 
	END IF 
	EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove WHEN ORDER OF INSERT TO batchdetl AND batchhead will be changed 
	--FOREACH new_curs_1 INTO l_rec_data.* 
	CALL new_curs_1.Open()
	WHILE new_curs_1.FetchNext(l_rec_data.* ) = 0
		LET glob_rec_batchhead.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.cmpy_code = glob_rec_company.cmpy_code 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
		LET l_rec_batchdetl.tran_date = l_rec_data.tran_date 
		LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
		LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
		LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
		LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.stats_qty = l_rec_data.stats_qty 
		LET l_rec_batchdetl.analysis_text = l_rec_data.analysis_text 
		LET l_rec_batchdetl.debit_amt = 0 
		LET l_rec_batchdetl.for_debit_amt = 0 
		LET l_rec_batchdetl.credit_amt = 0 
		LET l_rec_batchdetl.for_credit_amt = 0 
		CASE 
			WHEN (l_rec_data.base_debit_amt > 0) 
				LET l_rec_batchdetl.debit_amt = l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.credit_amt = 0 

			WHEN (l_rec_data.base_debit_amt < 0) 
				LET l_rec_batchdetl.credit_amt = -l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.debit_amt = 0 

			WHEN (l_rec_data.base_credit_amt > 0) 
				LET l_rec_batchdetl.credit_amt = l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.debit_amt = 0 

			WHEN (l_rec_data.base_credit_amt < 0) 
				LET l_rec_batchdetl.debit_amt = - l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
		END CASE 
		CASE 
			WHEN (l_rec_data.for_debit_amt > 0) 
				LET l_rec_batchdetl.for_debit_amt = l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_credit_amt = 0 

			WHEN (l_rec_data.for_debit_amt < 0) 
				LET l_rec_batchdetl.for_credit_amt = -l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 

			WHEN (l_rec_data.for_credit_amt > 0) 
				LET l_rec_batchdetl.for_credit_amt = l_rec_data.for_credit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 

			WHEN (l_rec_data.for_credit_amt < 0) 
				LET l_rec_batchdetl.for_debit_amt = - l_rec_data.for_credit_amt 
				LET l_rec_batchdetl.for_credit_amt = 0 
		END CASE 
		IF l_rec_batchdetl.debit_amt IS NULL THEN 
			LET l_rec_batchdetl.debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.credit_amt IS NULL THEN 
			LET l_rec_batchdetl.credit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_credit_amt = 0 
		END IF 

		# keep totals FOR balancing
		LET l_tot_base_debit = l_tot_base_debit + l_rec_batchdetl.debit_amt 
		LET l_tot_base_credit = l_tot_base_credit + l_rec_batchdetl.credit_amt 
		LET l_tot_for_debit = l_tot_for_debit + l_rec_batchdetl.for_debit_amt 
		LET l_tot_for_credit = l_tot_for_credit + l_rec_batchdetl.for_credit_amt 

		# increment the batch header
		LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
		LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
		LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
		LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
		LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 

		# check that AT least one side has a value
		IF NOT (l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		AND l_rec_batchdetl.stats_qty = 0 ) THEN 
			LET l_line_count = l_line_count + 1 
			LET glob_err_text = " Batchdetl INSERT (lines) - jourintf.4gl LINE 384" 
			--DISPLAY " Processing         : ",l_rec_batchdetl.ref_text AT 4,1
			--DISPLAY "                    : ",l_rec_batchdetl.ref_num AT 5,1
			MESSAGE "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
			IF get_debug() THEN 
				DISPLAY "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
				DISPLAY "glob_rec_batchhead.jour_code", glob_rec_batchhead.jour_code 
				DISPLAY "glob_rec_batchhead.jour_num", glob_rec_batchhead.jour_num 
				DISPLAY "glob_rec_batchhead.cmpy_code", glob_rec_batchhead.cmpy_code 
				DISPLAY "INSERT INTO batchdetl j-1 ****************************************************" 
			END IF 
			CALL new_prp_insert_batchdetl.Execute(l_rec_batchdetl.*) 
		END IF 

		INITIALIZE l_rec_batchdetl.* TO NULL 
	END WHILE #  new_curs_1

		LET glob_post_text = "Inserted all batchdetl records" 
		CALL update_poststatus(false,0,p_mod_code) 

		IF l_line_count > 0 THEN 
			LET l_rec_batchdetl.ref_text = " " 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.cmpy_code = glob_rec_company.cmpy_code 
			LET l_rec_batchdetl.jour_code = p_sent_jour_code 
			LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
			LET l_rec_batchdetl.seq_num = l_next_seq 
			LET l_next_seq = l_next_seq + 1 
			LET l_rec_batchdetl.tran_type_ind = p_rec_bal.tran_type_ind 
			LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
			LET l_rec_batchdetl.acct_code = p_rec_bal.acct_code 
			LET l_rec_batchdetl.desc_text = p_rec_bal.desc_text 
			LET l_rec_batchdetl.currency_code = p_currency_code 
			LET l_rec_batchdetl.analysis_text = "" 
			LET l_rec_batchdetl.stats_qty = 0 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 

			IF l_tot_base_debit > l_tot_base_credit THEN 
				LET l_rec_batchdetl.credit_amt = l_tot_base_debit - l_tot_base_credit 
			ELSE 
				LET l_rec_batchdetl.debit_amt = l_tot_base_credit - l_tot_base_debit 
			END IF 
			IF l_tot_for_debit > l_tot_for_credit THEN 
				LET l_rec_batchdetl.for_credit_amt = l_tot_for_debit - l_tot_for_credit 
			ELSE 
				LET l_rec_batchdetl.for_debit_amt = l_tot_for_credit - l_tot_for_debit 
			END IF 

			# IF balancing entry IS zero THEN dont add it TO the batch
			IF NOT (l_rec_batchdetl.credit_amt = 0 AND 
			l_rec_batchdetl.debit_amt = 0 AND 
			l_rec_batchdetl.for_credit_amt = 0 AND 
			l_rec_batchdetl.for_debit_amt = 0 AND 
			l_rec_batchdetl.stats_qty = 0 ) THEN 
				LET glob_err_text = "Batchdetl INSERT - (balancing entry)" 
				IF get_debug() THEN 
					DISPLAY glob_rec_batchhead.jour_code 
					DISPLAY glob_rec_batchhead.jour_num 
					DISPLAY glob_rec_batchhead.cmpy_code 
					DISPLAY "INSERT INTO batchdetl j-2" 
				END IF 
				--	EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove when order of INSERT to batchdetl and batchhead will be changed
				CALL new_prp_insert_batchdetl.Execute(l_rec_batchdetl.*) 

				#  increment the batch header
				LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
				LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
				LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
				LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
				LET glob_rec_batchhead.seq_num = l_next_seq 
			END IF 

			# INSERT batch header
			# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
			#       I)nventory AND Buy rate OTHERWISE

			IF glob_rec_glparms.use_currency_flag = "Y" AND 
			glob_rec_glparms.base_currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code != glob_rec_glparms.base_currency_code THEN 

				IF glob_rec_batchhead.source_ind matches "[AJI]" THEN 
					LET glob_rec_batchhead.rate_type_ind = "S" 
				ELSE 
					LET glob_rec_batchhead.rate_type_ind = "B" 
				END IF 
			ELSE 
				LET glob_rec_batchhead.rate_type_ind = " " 
			END IF 

			IF glob_rec_batchhead.currency_code IS NULL THEN 
				ERROR kandoomsg2("G",7000,glob_rec_batchhead.jour_num) 		#7000 Rate type indicator updated TO blank.
			END IF 

			LET glob_err_text = "Batchhead Insert - jourintf.4gl" 
			LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
			LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 
			IF get_debug() THEN 
				DISPLAY glob_rec_batchhead.jour_code 
				DISPLAY glob_rec_batchhead.jour_num 
				DISPLAY glob_rec_batchhead.cmpy_code 
				DISPLAY "INSERT INTO batchhead (only one instance)" 
			END IF 

			CASE glob_rec_batchhead.source_ind
				WHEN "G" #General/GL
					MESSAGE "GL/G - Posting General Ledger Batch"
					--SLEEP 1
				WHEN "C" # CashBook
					MESSAGE "GL/C (Cashbook) - Posting CashBook Batch"
					--SLEEP 1
				WHEN "R" # Purchasing System
					MESSAGE "PU/R - Posting Purchasing System Batch"
					--SLEEP 1
				WHEN "P" # Accounts Payable
					MESSAGE "AP/P - Posting Accounts Payable Batch"
					--SLEEP 1
				WHEN "A" # Accounts Receivable
					MESSAGE "AR/A - Posting Accounts Receivable Batch"
					--SLEEP 1
				WHEN "J" # Job Management ?
					MESSAGE "JM/J - Posting Job Management Batch"
					--SLEEP 1
				WHEN "I" # Warehouse IN
					MESSAGE "IN/I - Posting Warehouse Batch"
					--SLEEP 1
				
				OTHERWISE
					LET l_msg = "Unknown SOURCE_IND (main module group) source_ind=", trim(glob_rec_batchhead.source_ind), "\njourintf.4gl Function create_automatic_journal() Line~554"
					CALL fgl_winmessage("Internal Knowledge Sharing",l_msg,"INFO")
			END CASE
 
			INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

			IF NOT glob_one_trans THEN 
				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 4 - jourintf()" 
				END IF 
				COMMIT WORK 
				LET glob_in_trans = false 

				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 
		-- alch 2019.12.27 -- PP1 KD-1546
		# now write the REPORT on this batch

		CALL new_crs_batchdetl_this_journal.Open(glob_rec_company.cmpy_code,p_sent_jour_code,glob_rec_glparms.next_jour_num) 

		SELECT company.* 
		INTO l_rec_company.* 
		FROM company 
		WHERE company.cmpy_code = glob_rec_company.cmpy_code 

		WHILE new_crs_batchdetl_this_journal.FetchNext(l_rec_batchdetl.*) = 0
			OUTPUT TO REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,l_rec_batchdetl.*,	l_rec_company.*)  
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_batchdetl.jour_code, l_rec_batchdetl.jour_num,p_rpt_idx) THEN
				EXIT WHILE 
			END IF 
		END WHILE # new_crs_batchdetl_this_journal
	ELSE 
		# nothing posted
		IF NOT glob_one_trans THEN 

			IF get_debug() THEN 
				DISPLAY "COMMIT WORK 5 - jourintf()" 
			END IF 

			COMMIT WORK 
			LET glob_in_trans = false 


			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 


		END IF 

		# RETURN 0 IF no UPDATE done
		LET glob_rec_glparms.next_jour_num = 0 
	END IF 

# RETURN the batch number, negative IF suspense a/c used, ELSE positive
# this enables batch number TO be recorded on the source table
# IF required. Needed in purchasing TO allow FOR reconcilliation
# of summary batch posting

IF glob_prob_found THEN 
	# suspense a/c used, RETURN NEGATIVE jour_num
	RETURN ( 0 - glob_rec_glparms.next_jour_num ) 
ELSE 
	RETURN glob_rec_glparms.next_jour_num 
END IF 

WHENEVER ERROR CONTINUE 

END FUNCTION # create_automatic_journal

############################################################################

FUNCTION do_report_for_journal(p_rpt_idx,p_jour_code,p_jour_num)
	DEFINE p_rpt_idx SMALLINT
	DEFINE p_jour_code LIKE batchhead.jour_code
	DEFINE p_jour_num LIKE batchhead.jour_num
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_sql_statement STRING

	IF new_crs_batchdetl_this_journal.getStatement() IS NULL THEN
		LET l_sql_statement = "SELECT * ",
		" FROM batchdetl ",
		" WHERE cmpy_code = ? ",
		" AND jour_code = ? ",
		" AND jour_num = ? ",
		" ORDER BY seq_num "
		CALL new_crs_batchdetl_this_journal.Declare(l_sql_statement)
	END IF

	CALL new_crs_batchdetl_this_journal.Open(glob_rec_company.cmpy_code,p_jour_code,p_jour_num) 

	SELECT company.* 
	INTO l_rec_company.* 
	FROM company 
	WHERE company.cmpy_code = glob_rec_company.cmpy_code 

	WHILE new_crs_batchdetl_this_journal.FetchNext(l_rec_batchdetl.*) = 0
		OUTPUT TO REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,l_rec_batchdetl.*,	l_rec_company.*)  
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_batchdetl.jour_code, l_rec_batchdetl.jour_num,p_rpt_idx) THEN
			EXIT WHILE 
		END IF 
	END WHILE # new_crs_batchdetl_this_journal

END FUNCTION # do_report_for_journal()
############################################################
# REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,p_rec_batchdetl,p_rec_company) 
# Adjusted for lib_report report 2.0
#
############################################################
REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,p_rec_batchdetl,p_rec_company) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.* 

	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_line2 CHAR(132) 
	DEFINE l_rpt_note CHAR(50) 
	DEFINE l_rpt_length LIKE rmsreps.page_length_num 
	DEFINE l_rpt_wid SMALLINT 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_start_period LIKE batchhead.period_num 
	DEFINE l_end_period LIKE batchhead.period_num 
	#DEFINE l_periods LIKE batchhead.period_num #not used ?
	DEFINE l_start_year LIKE batchhead.year_num 
	DEFINE l_end_year LIKE batchhead.year_num 
	DEFINE l_year_num LIKE batchhead.year_num 


	OUTPUT 
	PAGE length 66 
	LEFT MARGIN 1 

	ORDER external BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.tran_type_ind, 
	p_rec_batchdetl.seq_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

--			LET l_rpt_wid = 132 
--			LET l_line1 = today clipped, 10 spaces, p_rec_company.cmpy_code, 
--			2 spaces, p_rec_company.name_text clipped, 10 spaces, 
--			"Page :", pageno USING "####" 
--
--			LET l_rpt_note = " Subsidiary Ledger Posting Journal Entries " 

--			LET l_line2 = l_rpt_note clipped 
--			LET l_offset1 = (l_rpt_wid - length(l_line1))/2 
--			LET l_offset2 = (l_rpt_wid - length(l_line2))/2 
--
--			PRINT 
--			COLUMN l_offset1, l_line1 clipped 
--			PRINT 
--			COLUMN l_offset2, l_line2 clipped 

			PRINT 
			COLUMN 1,"Date: ", today, 
			COLUMN 91, "** ERROR ** IF NOT found in GL " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 
			COLUMN 2, "Seq", 
			COLUMN 6, "Type", 
			COLUMN 11, "Account", 
			COLUMN 30, "Description", 
			COLUMN 73, "Base Currency", 
			COLUMN 101, "Foreign Currency", 
			COLUMN 127, "Conv" 

			PRINT 
			COLUMN 70, "Debit", 
			COLUMN 84, "Credit", 
			COLUMN 100, "Debit", 
			COLUMN 114, "Credit", 
			COLUMN 127, "Rate" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SELECT * 
			INTO glob_rec_batchhead.* 
			FROM batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code 

			PRINT 
			COLUMN 1, "Batch: ", p_rec_batchdetl.jour_num 
			PRINT 
			COLUMN 5, "Date: ", glob_rec_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", glob_rec_batchhead.year_num, 
			COLUMN 50, "Period: ", glob_rec_batchhead.period_num, 
			COLUMN 70, "FROM : ", glob_rec_batchhead.entry_code, 
			COLUMN 87, "Source : ", glob_rec_batchhead.source_ind, 
			COLUMN 101, "Currency : ", glob_rec_batchhead.currency_code 
			PRINT 
			COLUMN 5, "Comments:", 
			COLUMN 16, glob_rec_batchhead.com1_text 
			PRINT 
			COLUMN 5, "Comments :", 
			COLUMN 16, glob_rec_batchhead.com2_text 

		ON EVERY ROW 

			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES

			# check that chart number IS valid AND live
			LET glob_coa_not_found = false 
			LET glob_coa_not_open = false 

			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO l_start_year,l_start_period,l_end_year,l_end_period 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 

			IF status THEN 
				LET glob_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < glob_rec_batchhead.year_num) OR 
				(l_end_year = glob_rec_batchhead.year_num AND 
				l_end_period < glob_rec_batchhead.period_num)) OR 
				((l_start_year > glob_rec_batchhead.year_num) OR 
				(l_start_year = glob_rec_batchhead.year_num AND 
				l_start_period > glob_rec_batchhead.period_num))) THEN 
					LET glob_coa_not_open = true 
				END IF 
			END IF 

			IF glob_coa_not_found OR glob_coa_not_open THEN 
				LET glob_prob_found = true 
			END IF 

			PRINT 
			COLUMN 1, p_rec_batchdetl.seq_num USING "####", 
			COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 90, p_rec_batchdetl.for_debit_amt USING "-----------&.&&", 
			COLUMN 105, p_rec_batchdetl.for_credit_amt USING "-----------&.&&", 
			COLUMN 121, p_rec_batchdetl.conv_qty USING "---&.&&&" 

			# IF coa IS bad THEN change it TO the suspense account AND PRINT the error

			IF glob_coa_not_found THEN 
				PRINT COLUMN 20, "** FIND ERROR - Suspense Account will be used : ", 
				p_rec_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Cannot find account : ",p_rec_batchdetl.acct_code 
			END IF 
			IF glob_coa_not_open THEN 
				PRINT COLUMN 20, "** OPEN ERROR - Suspense Account will be used : ", 
				p_rec_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Account NOT OPEN : ",p_rec_batchdetl.acct_code 
			END IF 

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT 
			COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 

			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
				
			 
END REPORT 




############################################################
# FUNCTION jourintf (p_sel_stmt,
#                   p_cmpy,
#                   p_kandoouser_sign_on_code,
#                   p_rec_bal,
#                   p_periods,
#                   p_year_num,
#
#                   p_sent_jour_code,
#                   p_source_ind,
#                   p_currency_code,
#                   p_output,
#                   p_mod_code)
#
############################################################
FUNCTION jourintf(p_sel_stmt, 
	p_cmpy, 
	p_kandoouser_sign_on_code, 
	p_rec_bal, 
	p_periods, 
	p_year_num, 
	p_sent_jour_code, 
	p_source_ind, 
	p_currency_code, 
	p_output, 
	p_mod_code) 

	DEFINE p_sel_stmt CHAR (900) 
	DEFINE p_cmpy LIKE batchhead.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE batchhead.entry_code 
	DEFINE p_rec_bal 
		RECORD 
			tran_type_ind LIKE batchdetl.tran_type_ind, 
			acct_code LIKE batchdetl.acct_code, 
			desc_text LIKE batchdetl.desc_text 
		END RECORD 
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_sent_jour_code LIKE batchhead.jour_code 
	DEFINE p_source_ind LIKE batchhead.jour_code 
	DEFINE p_currency_code LIKE batchhead.currency_code 
	DEFINE p_output CHAR(60) 
	DEFINE p_mod_code CHAR(2) 

	#DEFINE l_end_period LIKE batchhead.period_num #not used
	#DEFINE l_end_year LIKE batchhead.year_num #not used
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_data 
		RECORD 
			tran_type_ind LIKE batchdetl.tran_type_ind, 
			ref_num LIKE batchdetl.ref_num, 
			ref_text LIKE batchdetl.ref_text, 
			acct_code LIKE batchdetl.acct_code, 
			desc_text LIKE batchdetl.desc_text, 
			for_debit_amt LIKE batchdetl.for_debit_amt, 
			for_credit_amt LIKE batchdetl.for_credit_amt, 
			base_debit_amt LIKE batchdetl.debit_amt, 
			base_credit_amt LIKE batchdetl.credit_amt, 
			currency_code LIKE currency.currency_code, 
			conv_qty LIKE rate_exchange.conv_buy_qty, 
			tran_date DATE, 
			stats_qty LIKE batchdetl.stats_qty, 
			analysis_text LIKE batchdetl.analysis_text 
		END RECORD 
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_next_seq SMALLINT 
	DEFINE l_line_count SMALLINT 
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION jourintf *****" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	CALL update_poststatus(true,status,p_mod_code) 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET l_line_count = 0 
	LET glob_prob_found = false 

	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_2 CURSOR with HOLD FOR prep_1 

	INITIALIZE glob_rec_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 

	# check FOR zero also - calling routines do NOT always
	# initialise the global variabl posted_journal correctly AND the
	# default initial value IS zero
	IF glob_posted_journal IS NULL OR glob_posted_journal = 0 THEN 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
				IF get_debug() THEN 
					DISPLAY "BEGIn WORK 1 - jourintf()" 
				END IF 
				LET glob_in_trans = true 
				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 

			DECLARE c2_glparms CURSOR FOR 
			SELECT glparms.* 
			INTO glob_rec_glparms.* 
			FROM glparms 
			WHERE glparms.cmpy_code = p_cmpy 
			AND glparms.key_code = "1" 
			FOR UPDATE 

			FOREACH c2_glparms 
				LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
				LET glob_err_text = " GL Parms UPDATE - jourintf.4gl " 
				UPDATE glparms 
				SET next_jour_num = next_jour_num + 1 
				WHERE CURRENT OF c2_glparms 
			END FOREACH 

			LET glob_posted_journal = glob_rec_glparms.next_jour_num 
			LET glob_post_text = "Selected journal codes FROM glparms" 
			CALL update_poststatus(false,0,p_mod_code) 

			IF NOT glob_one_trans THEN 

				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 1 - jourintf()" 
				END IF 
			COMMIT WORK 
			LET glob_in_trans = false 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	ELSE 
		# commenced batchdetl INSERT but did nay finish
		# so we must delete out what batchdetl AND batchhead it did do
		IF NOT glob_one_trans THEN 
			IF get_debug() THEN 
				DISPLAY "BEGIn WORK 2 - jourintf()" 
			END IF 
			BEGIN WORK 
				LET glob_in_trans = true 

				IF get_debug() THEN 
					DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
				END IF 
			END IF 

			# IF the post died mid batch we double check that the batch has
			# NOT been posted somehow. IF it has THEN it needs TO be manually
			# reversed FROM the tables before repost
			SELECT post_flag 
			INTO l_tmp_flag 
			FROM batchhead 
			WHERE cmpy_code = p_cmpy 
			AND jour_num = glob_posted_journal 
			IF l_tmp_flag = "Y" THEN {batch was somehow posted} 
				LET glob_err_text = "Batch ",glob_posted_journal USING "#######&", " has been posted - FATAL" 
				CALL update_poststatus(true,0,p_mod_code) 
			END IF 

			DELETE 
			FROM batchdetl 
			WHERE cmpy_code = p_cmpy 
			AND jour_num = glob_posted_journal 
			DELETE 
			FROM batchhead 
			WHERE cmpy_code = p_cmpy 
			AND jour_num = glob_posted_journal 

			LET glob_rec_glparms.next_jour_num = glob_posted_journal 
			IF NOT glob_one_trans THEN 
				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 2 - jourintf()" 
				END IF 
			COMMIT WORK 
			LET glob_in_trans = false 
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
	END IF 

	LET glob_rec_batchhead.cmpy_code = p_cmpy 
	LET glob_rec_batchhead.jour_code = p_sent_jour_code 
	LET glob_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
	LET glob_rec_batchhead.entry_code = p_kandoouser_sign_on_code 
	LET glob_rec_batchhead.jour_date = today 
	LET glob_rec_batchhead.year_num = p_year_num 
	LET glob_rec_batchhead.period_num = p_periods 
	LET glob_rec_batchhead.control_amt = 0 
	LET glob_rec_batchhead.debit_amt = 0 
	LET glob_rec_batchhead.credit_amt = 0 
	LET glob_rec_batchhead.for_debit_amt = 0 
	LET glob_rec_batchhead.for_credit_amt = 0 
	LET glob_rec_batchhead.control_qty = 0 
	LET glob_rec_batchhead.stats_qty = 0 
	LET glob_rec_batchhead.currency_code = p_currency_code 
	LET glob_rec_batchhead.source_ind = p_source_ind 

	IF glob_rec_glparms.use_clear_flag = "Y" THEN 
		LET glob_rec_batchhead.cleared_flag = "N" 
	ELSE 
		LET glob_rec_batchhead.cleared_flag = "Y" 
	END IF 

	LET glob_rec_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 

	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 

	LET glob_post_text = "Commenced batch lines INSERT" 
	CALL update_poststatus(false,0,p_mod_code) 
	MESSAGE "Creating GL batch: ", glob_rec_glparms.next_jour_num 
	-- DISPLAY " Creating GL batch  : ", glob_rec_glparms.next_jour_num AT 3,1  ATTRIBUTE(yellow)
	IF get_debug() THEN 
		DISPLAY "**** Creating GL batch : ", trim(glob_rec_glparms.next_jour_num) , " *****" 
	END IF 
	-- alch 2019.12.27 -- PP1 KD-1546
	IF NOT glob_one_trans THEN 
		IF get_debug() THEN 
			DISPLAY "BEGIn WORK 3 - jourintf()" 
		END IF 
		BEGIN WORK 
			LET glob_in_trans = true 
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
		EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove WHEN ORDER OF INSERT TO batchdetl AND batchhead will be changed 
		FOREACH curs_2 INTO l_rec_data.* 
			--		IF NOT glob_one_trans THEN
			--			IF get_debug() THEN
			--				DISPLAY "BEGIn WORK 3 - jourintf()"
			--			END IF
			--			BEGIN WORK
			--			LET glob_in_trans = TRUE
			--			IF get_debug() THEN
			--				DISPLAY "glob_in_trans = ",trim(glob_in_trans)
			--			END IF
			--		END IF

			LET glob_rec_batchhead.conv_qty = l_rec_data.conv_qty 

			LET l_rec_batchdetl.cmpy_code = p_cmpy 
			LET l_rec_batchdetl.jour_code = p_sent_jour_code 
			LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
			LET l_rec_batchdetl.seq_num = l_next_seq 
			LET l_next_seq = l_next_seq + 1 
			LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
			LET l_rec_batchdetl.tran_date = l_rec_data.tran_date 
			LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
			LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
			LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
			LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
			LET l_rec_batchdetl.currency_code = p_currency_code 
			LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
			LET l_rec_batchdetl.stats_qty = l_rec_data.stats_qty 
			LET l_rec_batchdetl.analysis_text = l_rec_data.analysis_text 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 
			CASE 
				WHEN (l_rec_data.base_debit_amt > 0) 
					LET l_rec_batchdetl.debit_amt = l_rec_data.base_debit_amt 
					LET l_rec_batchdetl.credit_amt = 0 

				WHEN (l_rec_data.base_debit_amt < 0) 
					LET l_rec_batchdetl.credit_amt = -l_rec_data.base_debit_amt 
					LET l_rec_batchdetl.debit_amt = 0 

				WHEN (l_rec_data.base_credit_amt > 0) 
					LET l_rec_batchdetl.credit_amt = l_rec_data.base_credit_amt 
					LET l_rec_batchdetl.debit_amt = 0 

				WHEN (l_rec_data.base_credit_amt < 0) 
					LET l_rec_batchdetl.debit_amt = - l_rec_data.base_credit_amt 
					LET l_rec_batchdetl.credit_amt = 0 
			END CASE 
			CASE 
				WHEN (l_rec_data.for_debit_amt > 0) 
					LET l_rec_batchdetl.for_debit_amt = l_rec_data.for_debit_amt 
					LET l_rec_batchdetl.for_credit_amt = 0 

				WHEN (l_rec_data.for_debit_amt < 0) 
					LET l_rec_batchdetl.for_credit_amt = -l_rec_data.for_debit_amt 
					LET l_rec_batchdetl.for_debit_amt = 0 

				WHEN (l_rec_data.for_credit_amt > 0) 
					LET l_rec_batchdetl.for_credit_amt = l_rec_data.for_credit_amt 
					LET l_rec_batchdetl.for_debit_amt = 0 

				WHEN (l_rec_data.for_credit_amt < 0) 
					LET l_rec_batchdetl.for_debit_amt = - l_rec_data.for_credit_amt 
					LET l_rec_batchdetl.for_credit_amt = 0 
			END CASE 
			IF l_rec_batchdetl.debit_amt IS NULL THEN 
				LET l_rec_batchdetl.debit_amt = 0 
			END IF 
			IF l_rec_batchdetl.credit_amt IS NULL THEN 
				LET l_rec_batchdetl.credit_amt = 0 
			END IF 
			IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
				LET l_rec_batchdetl.for_debit_amt = 0 
			END IF 
			IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
				LET l_rec_batchdetl.for_credit_amt = 0 
			END IF 

			# keep totals FOR balancing
			LET l_tot_base_debit = l_tot_base_debit + l_rec_batchdetl.debit_amt 
			LET l_tot_base_credit = l_tot_base_credit + l_rec_batchdetl.credit_amt 
			LET l_tot_for_debit = l_tot_for_debit + l_rec_batchdetl.for_debit_amt 
			LET l_tot_for_credit = l_tot_for_credit + l_rec_batchdetl.for_credit_amt 

			# increment the batch header
			LET glob_rec_batchhead.stats_qty = glob_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
			LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
			LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 

			# check that AT least one side has a value
			IF l_rec_batchdetl.debit_amt = 0 AND 
			l_rec_batchdetl.credit_amt = 0 AND 
			l_rec_batchdetl.for_debit_amt = 0 AND 
			l_rec_batchdetl.for_credit_amt = 0 AND 
			l_rec_batchdetl.stats_qty = 0 THEN 
			ELSE 
				LET l_line_count = l_line_count + 1 
				LET glob_err_text = " Batchdetl INSERT (lines) - jourintf.4gl LINE 384" 
				--DISPLAY " Processing         : ",l_rec_batchdetl.ref_text AT 4,1
				--DISPLAY "                    : ",l_rec_batchdetl.ref_num AT 5,1
				MESSAGE "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
				IF get_debug() THEN 
					DISPLAY "Processing: ",trim(l_rec_batchdetl.ref_text), "/", trim(l_rec_batchdetl.ref_num) 
					DISPLAY "glob_rec_batchhead.jour_code", glob_rec_batchhead.jour_code 
					DISPLAY "glob_rec_batchhead.jour_num", glob_rec_batchhead.jour_num 
					DISPLAY "glob_rec_batchhead.cmpy_code", glob_rec_batchhead.cmpy_code 
					DISPLAY "INSERT INTO batchdetl j-1 ****************************************************" 
				END IF 

				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
			END IF 

			--		IF NOT glob_one_trans THEN
			--			IF get_debug() THEN
			--				DISPLAY "COMMIT WORK 3 - jourintf()"
			--			END IF
			--			COMMIT WORK
			--			LET glob_in_trans = FALSE
			--			IF get_debug() THEN
			--				DISPLAY "glob_in_trans = ",trim(glob_in_trans)
			--			END IF
			--		END IF
			INITIALIZE l_rec_batchdetl.* TO NULL 
		END FOREACH 

		LET glob_post_text = "Inserted all batchdetl records" 
		CALL update_poststatus(false,0,p_mod_code) 

		--	IF NOT glob_one_trans THEN
		--		IF get_debug() THEN
		--			DISPLAY "BEGIN WORK 4 - jourintf()"
		--		END IF
		--		BEGIN WORK
		--		LET glob_in_trans = TRUE
		--		IF get_debug() THEN
		--			DISPLAY "glob_in_trans = ",trim(glob_in_trans)
		--		END IF
		--	END IF

		#  create the balancing journal detail entries
		#  IF some batch lines have been inserted

		IF l_line_count > 0 THEN 
			LET l_rec_batchdetl.ref_text = " " 
			LET l_rec_batchdetl.ref_num = 0 
			LET l_rec_batchdetl.cmpy_code = p_cmpy 
			LET l_rec_batchdetl.jour_code = p_sent_jour_code 
			LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
			LET l_rec_batchdetl.seq_num = l_next_seq 
			LET l_next_seq = l_next_seq + 1 
			LET l_rec_batchdetl.tran_type_ind = p_rec_bal.tran_type_ind 
			LET l_rec_batchdetl.tran_date = glob_rec_batchhead.jour_date 
			LET l_rec_batchdetl.acct_code = p_rec_bal.acct_code 
			LET l_rec_batchdetl.desc_text = p_rec_bal.desc_text 
			LET l_rec_batchdetl.currency_code = p_currency_code 
			LET l_rec_batchdetl.analysis_text = "" 
			LET l_rec_batchdetl.stats_qty = 0 
			LET l_rec_batchdetl.debit_amt = 0 
			LET l_rec_batchdetl.credit_amt = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 

			IF l_tot_base_debit > l_tot_base_credit THEN 
				LET l_rec_batchdetl.credit_amt = l_tot_base_debit - l_tot_base_credit 
			ELSE 
				LET l_rec_batchdetl.debit_amt = l_tot_base_credit - l_tot_base_debit 
			END IF 
			IF l_tot_for_debit > l_tot_for_credit THEN 
				LET l_rec_batchdetl.for_credit_amt = l_tot_for_debit - l_tot_for_credit 
			ELSE 
				LET l_rec_batchdetl.for_debit_amt = l_tot_for_credit - l_tot_for_debit 
			END IF 

			# IF balancing entry IS zero THEN dont add it TO the batch
			IF l_rec_batchdetl.credit_amt = 0 AND 
			l_rec_batchdetl.debit_amt = 0 AND 
			l_rec_batchdetl.for_credit_amt = 0 AND 
			l_rec_batchdetl.for_debit_amt = 0 AND 
			l_rec_batchdetl.stats_qty = 0 THEN 
			ELSE 
				LET glob_err_text = "Batchdetl INSERT - (balancing entry)" 

				IF get_debug() THEN 
					DISPLAY glob_rec_batchhead.jour_code 
					DISPLAY glob_rec_batchhead.jour_num 
					DISPLAY glob_rec_batchhead.cmpy_code 
					DISPLAY "INSERT INTO batchdetl j-2" 
				END IF 
				--	EXECUTE immediate "SET CONSTRAINTS ALL deferred" -- alch remove when order of INSERT to batchdetl and batchhead will be changed
				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

				#  increment the batch header
				LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
				LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
				LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
				LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
				LET glob_rec_batchhead.seq_num = l_next_seq 
			END IF 

			# INSERT batch header
			# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
			#       I)nventory AND Buy rate OTHERWISE

			IF glob_rec_glparms.use_currency_flag = "Y" AND 
			glob_rec_glparms.base_currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code IS NOT NULL AND 
			glob_rec_batchhead.currency_code != glob_rec_glparms.base_currency_code THEN 

				IF glob_rec_batchhead.source_ind matches "[AJI]" THEN 
					LET glob_rec_batchhead.rate_type_ind = "S" 
				ELSE 
					LET glob_rec_batchhead.rate_type_ind = "B" 
				END IF 
			ELSE 
				LET glob_rec_batchhead.rate_type_ind = " " 
			END IF 

			IF glob_rec_batchhead.currency_code IS NULL THEN 
				ERROR kandoomsg2("G",7000,glob_rec_batchhead.jour_num) 				#7000 Rate type indicator updated TO blank.
			END IF 

			LET glob_err_text = "Batchhead Insert - jourintf.4gl" 
			LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt 
			LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty 
			IF get_debug() THEN 
				DISPLAY glob_rec_batchhead.jour_code 
				DISPLAY glob_rec_batchhead.jour_num 
				DISPLAY glob_rec_batchhead.cmpy_code 
				DISPLAY "INSERT INTO batchhead (only one instance)" 
			END IF 

			CALL fgl_winmessage("4 Learning batch head codes - tell Hubert",glob_rec_batchhead.source_ind,"info") 
			INSERT INTO batchhead VALUES (glob_rec_batchhead.*) 

			IF NOT glob_one_trans THEN 
				IF get_debug() THEN 
					DISPLAY "COMMIT WORK 4 - jourintf()" 
				END IF 
			COMMIT WORK 
			LET glob_in_trans = false 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
		-- alch 2019.12.27 -- PP1 KD-1546
		# now write the REPORT on this batch

		DECLARE crs_rep_batchdetl_this_journal CURSOR FOR 
		SELECT * 
		INTO l_rec_batchdetl.* 
		FROM batchdetl 
		WHERE cmpy_code = p_cmpy 
		AND jour_code = p_sent_jour_code 
		AND jour_num = glob_rec_glparms.next_jour_num 
		ORDER BY seq_num 

		SELECT company.* 
		INTO l_rec_company.* 
		FROM company 
		WHERE company.cmpy_code = p_cmpy 

		FOREACH crs_rep_batchdetl_this_journal 
			OUTPUT TO REPORT rpt_list_bdt (p_output, l_rec_batchdetl.*, 
			l_rec_company.*) 
		END FOREACH 
	ELSE 
		# nothing posted 
		IF NOT glob_one_trans THEN 

			IF get_debug() THEN 
				DISPLAY "COMMIT WORK 5 - jourintf()" 
			END IF 

		COMMIT WORK 
		LET glob_in_trans = false 


		IF get_debug() THEN 
			DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
		END IF 


	END IF 

	# RETURN 0 IF no UPDATE done
	LET glob_rec_glparms.next_jour_num = 0 
END IF 

# RETURN the batch number, negative IF suspense a/c used, ELSE positive
# this enables batch number TO be recorded on the source table
# IF required. Needed in purchasing TO allow FOR reconcilliation
# of summary batch posting

IF glob_prob_found THEN 
	# suspense a/c used, RETURN NEGATIVE jour_num
	RETURN ( 0 - glob_rec_glparms.next_jour_num ) 
ELSE 
	RETURN glob_rec_glparms.next_jour_num 
END IF 

WHENEVER ERROR CONTINUE 

END FUNCTION # jourintf () 
############################################################
# END FUNCTION jourintf (p_sel_stmt,
#                   p_cmpy,
#                   p_kandoouser_sign_on_code,
#                   p_rec_bal,
#                   p_periods,
#                   p_year_num,
#
#                   p_sent_jour_code,
#                   p_source_ind,
#                   p_currency_code,
#                   p_output,
#                   p_mod_code)
#
############################################################






############################################################
# NOTE: Do not use this function with lib_report ! Use jourintf_rpt_list_bd() !!!
############################################################
# REPORT rpt_list_bdt(p_output,p_rec_batchdetl,p_rec_company)
#
############################################################
# NOTE: Do not use this function with lib_report ! Use jourintf_rpt_list_bd() !!!
############################################################
REPORT rpt_list_bdt(p_output,p_rec_batchdetl,p_rec_company) 
	DEFINE p_output CHAR(60) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.* 

	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_line2 CHAR(132) 
	DEFINE l_rpt_note CHAR(50) 
	DEFINE l_rpt_length LIKE rmsreps.page_length_num 
	DEFINE l_rpt_wid SMALLINT 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_start_period LIKE batchhead.period_num 
	DEFINE l_end_period LIKE batchhead.period_num 
	#DEFINE l_periods LIKE batchhead.period_num #not used ?
	DEFINE l_start_year LIKE batchhead.year_num 
	DEFINE l_end_year LIKE batchhead.year_num 
	DEFINE l_year_num LIKE batchhead.year_num 


	OUTPUT 
	PAGE length 66 
	LEFT MARGIN 1 

	ORDER external BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.tran_type_ind, 
	p_rec_batchdetl.seq_num 

	FORMAT 

		PAGE HEADER 

			LET l_rpt_wid = 132 
			LET l_line1 = today clipped, 10 spaces, p_rec_company.cmpy_code, 
			2 spaces, p_rec_company.name_text clipped, 10 spaces, 
			"Page :", pageno USING "####" 

			LET l_rpt_note = " Subsidiary Ledger Posting Journal Entries " 

			LET l_line2 = l_rpt_note clipped 
			LET l_offset1 = (l_rpt_wid - length(l_line1))/2 
			LET l_offset2 = (l_rpt_wid - length(l_line2))/2 

			PRINT 
			COLUMN l_offset1, l_line1 clipped 
			PRINT 
			COLUMN l_offset2, l_line2 clipped 

			PRINT 
			COLUMN 1,"Date: ", today, 
			COLUMN 91, "** ERROR ** IF NOT found in GL " 

			PRINT 
			COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 

			PRINT 
			COLUMN 2, "Seq", 
			COLUMN 6, "Type", 
			COLUMN 11, "Account", 
			COLUMN 30, "Description", 
			COLUMN 73, "Base Currency", 
			COLUMN 101, "Foreign Currency", 
			COLUMN 127, "Conv" 

			PRINT 
			COLUMN 70, "Debit", 
			COLUMN 84, "Credit", 
			COLUMN 100, "Debit", 
			COLUMN 114, "Credit", 
			COLUMN 127, "Rate" 

			PRINT 
			COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 

			SELECT * 
			INTO glob_rec_batchhead.* 
			FROM batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code 

			PRINT 
			COLUMN 1, "Batch: ", p_rec_batchdetl.jour_num 
			PRINT 
			COLUMN 5, "Date: ", glob_rec_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", glob_rec_batchhead.year_num, 
			COLUMN 50, "Period: ", glob_rec_batchhead.period_num, 
			COLUMN 70, "FROM : ", glob_rec_batchhead.entry_code, 
			COLUMN 87, "Source : ", glob_rec_batchhead.source_ind, 
			COLUMN 101, "Currency : ", glob_rec_batchhead.currency_code 
			PRINT 
			COLUMN 5, "Comments:", 
			COLUMN 16, glob_rec_batchhead.com1_text 
			PRINT 
			COLUMN 5, "Comments :", 
			COLUMN 16, glob_rec_batchhead.com2_text 

		ON EVERY ROW 

			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES

			# check that chart number IS valid AND live
			LET glob_coa_not_found = false 
			LET glob_coa_not_open = false 

			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO l_start_year,l_start_period,l_end_year,l_end_period 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 

			IF status THEN 
				LET glob_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF 
				(
					(
						(l_end_year < glob_rec_batchhead.year_num) OR 
						(l_end_year = glob_rec_batchhead.year_num AND l_end_period < glob_rec_batchhead.period_num)
					) OR 
					(
						(l_start_year > glob_rec_batchhead.year_num) OR 
						(l_start_year = glob_rec_batchhead.year_num AND	l_start_period > glob_rec_batchhead.period_num)
					)
				) THEN 
					LET glob_coa_not_open = true 
				END IF 
			END IF 

			IF glob_coa_not_found OR glob_coa_not_open THEN 
				LET glob_prob_found = true 
			END IF 

			PRINT 
			COLUMN 1, p_rec_batchdetl.seq_num USING "####", 
			COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 90, p_rec_batchdetl.for_debit_amt USING "-----------&.&&", 
			COLUMN 105, p_rec_batchdetl.for_credit_amt USING "-----------&.&&", 
			COLUMN 121, p_rec_batchdetl.conv_qty USING "---&.&&&" 

			# IF coa IS bad THEN change it TO the suspense account AND PRINT the error

			IF glob_coa_not_found THEN 
				PRINT COLUMN 20, "** FIND ERROR - Suspense Account will be used : ", 	p_rec_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Cannot find account : ",p_rec_batchdetl.acct_code 
			END IF 
			IF glob_coa_not_open THEN 
				PRINT COLUMN 20, "** OPEN ERROR - Suspense Account will be used : ", p_rec_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Account NOT OPEN : ",p_rec_batchdetl.acct_code 
			END IF 

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT 
			COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 


			 
--			CALL upd_reports(p_output, 
--			l_page_num, 
--			l_rpt_wid, 
--			l_rpt_length) 

			PRINT 
			COLUMN 50," ***** END OF POSTING REPORT ***** "
			
#			LET glob_rec_rmsreps.page_num = pageno			
#			CALL rpt_update_rmsreps()
#			CALL db_rmsreps_show_record(glob_rec_rmsreps.report_code)			
			 
END REPORT 
############################################################
# END REPORT rpt_list_bdt(p_output,p_rec_batchdetl,p_rec_company)
# NOTE: Do not use this function with lib_report ! Use jourintf_rpt_list_bd2() !!!
############################################################