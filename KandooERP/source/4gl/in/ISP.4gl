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

	Source code beautified by beautify.pl on 2020-01-03 09:12:43	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# Purpose : Inventory Posting Process                                  #

GLOBALS 
	DEFINE 
	pr_batchdetl RECORD LIKE batchdetl.*, 
	pr_batchhead RECORD LIKE batchhead.*, 
	pr_company RECORD LIKE company.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_journal RECORD LIKE journal.*, 
	pr_poststatus RECORD LIKE poststatus.*, 
	pr_postprodledg RECORD LIKE postprodledg.*, 
	pr_structure RECORD LIKE structure.*, 
	pr_period_num LIKE period.period_num, 
	pr_year_num LIKE period.year_num, 
	rpt1_note, 
	rpt2_note LIKE rmsreps.report_text, 
	rpt1_pageno, 
	rpt2_pageno LIKE rmsreps.page_num, 
	rpt1_length, 
	rpt2_length LIKE rmsreps.page_length_num, 
	rpt1_wid, 
	rpt2_wid LIKE rmsreps.report_width_num, 
	pr_output1, pr_output2, pr_error_text CHAR(60), 
	pr_record_count INTEGER, 
	pr_ready_for_fifo, pr_ready_for_post CHAR(1), 
	pr_insert_phase, pr_delete_phase, pr_complete SMALLINT, 
	pa_comments array[9] OF CHAR(60), 
	sel_text CHAR(900), 
	where_text CHAR(150), 
	pr_output CHAR(60), 
	try_again CHAR(1), 
	err_message CHAR(80), 
	pr_fifo_lifo, pr_multiledger, pr_invalid_acct SMALLINT, 
	pr_ledg_start LIKE structure.start_num, 
	pr_ledg_length LIKE structure.length_num 

END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("ISP") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * 
	INTO pr_poststatus.* 
	FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = TRAN_TYPE_INVOICE_IN 
	IF status = notfound THEN 
		# 3507 "Status cannot be found - cannot post - ABORTING!"
		LET msgresp = kandoomsg("U",3507,"") 
		EXIT program 
	END IF 
	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I", 5002, "") 
		#5002 "Inventory Parameters NOT SET up..."
		EXIT program 
	END IF 
	SELECT * 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U", 5107, "") 
		#5107 " GL Parameters NOT SET up...."
		EXIT program 
	END IF 
	# Check that the inventory/GL integration flag IS SET AND that the
	# journals are present
	IF pr_inparms.gl_post_flag != "Y" THEN 
		# 7075 Inventory/GL integration flag NOT SET - cannot post.
		LET msgresp = kandoomsg("I",7075,"") 
		EXIT program 
	END IF 
	SELECT * 
	INTO pr_journal.* 
	FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = pr_inparms.inv_journal_code 
	IF status = notfound THEN 
		#7038 "Inventory Journal NOT found"
		LET msgresp = kandoomsg("U",7038,"Inventory") 
		EXIT program 
	END IF 
	# Set up STATUS flags AND initialise global variables
	LET pr_record_count = 0 
	LET pr_insert_phase = 1 
	LET pr_delete_phase = 2 
	LET pr_complete = 99 
	LET pr_ready_for_fifo = "1" 
	LET pr_ready_for_post = "2" 
	IF pr_inparms.cost_ind matches "[FL]" THEN 
		LET pr_fifo_lifo = true 
	ELSE 
		LET pr_fifo_lifo = false 
	END IF 
	LET pr_multiledger = true 
	SELECT * 
	INTO pr_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = notfound THEN 
		LET pr_multiledger = false 
		LET pr_ledg_start = 0 
		LET pr_ledg_length = 0 
	ELSE 
		LET pr_ledg_start = pr_structure.start_num 
		LET pr_ledg_length = pr_structure.length_num 
	END IF 
	# IF restarting the post, complete the previous post
	# before opening the window FOR the QBE etc.
	OPEN WINDOW wi131 with FORM "I131" 
	 CALL windecoration_i("I131") -- albo kd-758 
	IF pr_poststatus.status_code < pr_complete THEN 
		LET msgresp = kandoomsg("I",7076,"") 
		#7076 Posting incomplete - restarting.  Any key ...
		LET pr_year_num = pr_poststatus.post_year_num 
		LET pr_period_num = pr_poststatus.post_period_num 
		SELECT count(*) INTO pr_record_count 
		FROM postprodledg WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF pr_record_count IS NULL THEN 
			LET pr_record_count = 0 
		END IF 
		IF update_status("Y") THEN 
			CALL post_in() 
			CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
		END IF 
	END IF 
	WHILE scan_period() 
	END WHILE 

	CLOSE WINDOW wi131 

END MAIN 

FUNCTION scan_period() 
	DEFINE 
	pr_period RECORD LIKE period.*, 
	pa_period array[300] OF RECORD 
		scroll_flag CHAR(1), 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		post_req CHAR(1) 
	END RECORD, 
	idx, scrn, i, per_post SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue."
	CONSTRUCT BY NAME where_text ON year_num, 
	period_num 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET sel_text = 
	"SELECT unique year_num, period_num ", 
	"FROM period WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	where_text clipped, 
	"ORDER BY year_num, period_num " 

	PREPARE s_period FROM sel_text 
	DECLARE c_period CURSOR FOR s_period 

	LET idx = 0 
	FOREACH c_period INTO pr_period.year_num, pr_period.period_num 
		LET idx = idx + 1 
		INITIALIZE pa_period[idx].* TO NULL 
		LET pa_period[idx].year_num = pr_period.year_num 
		LET pa_period[idx].period_num = pr_period.period_num 
		IF idx > 299 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#U9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_period[1].* TO NULL 
	END IF 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("U",1110,"") 
	#1110 Press Enter on line TO post; F10 TO check.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY pa_period WITHOUT DEFAULTS FROM sr_period.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISP","input-pa_period-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_period[idx].* TO sr_period[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_period[idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_period[idx+1].year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_period[idx+13].year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F10) 
			FOR i=1 TO arr_count() 
				LET pa_period[i].post_req = "N" 
				DECLARE postin CURSOR FOR 
				SELECT period_num 
				INTO per_post 
				FROM prodledg 
				WHERE period_num = pa_period[i].period_num 
				AND year_num = pa_period[i].year_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND post_flag = "N" 
				FOREACH postin 
					LET pa_period[i].post_req = "Y" 
					EXIT FOREACH 
				END FOREACH 
				IF i <= 12 THEN 
					DISPLAY pa_period[i].* TO sr_period[i].* 
				END IF 
			END FOR 
		BEFORE FIELD year_num 
			IF pa_period[idx].year_num IS NULL OR 
			pa_period[idx].period_num IS NULL THEN 
				LET msgresp=kandoomsg("U",3512,"") 
				#3512 You must SELECT a  valid year & period
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_period[idx].post_req IS NOT NULL THEN 
				IF pa_period[idx].post_req != 'Y' THEN 
					LET msgresp=kandoomsg("U",9933,"") 
					#3501 No rows found TO post
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			LET pr_period_num = pa_period[idx].period_num 
			LET pr_year_num = pa_period[idx].year_num 
			IF update_status("Y") THEN 
				CALL post_in() 
				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
				LET pa_period[idx].post_req = "P" 
				DISPLAY pa_period[idx].* TO sr_period[scrn].* 

				LET msgresp = kandoomsg("U",1110,"") 
				#1110 Press Enter on line TO post; F10 TO check.
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_period[idx].* TO sr_period[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION update_status(pr_mode) 
	DEFINE 
	pr_mode CHAR(1) 

	GOTO upd_bypass 
	LABEL upd_recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL upd_bypass: 
	WHENEVER ERROR GOTO upd_recovery 
	# Lock the poststatus RECORD WHILE updating TO ensure that
	# posting IS NOT running
	BEGIN WORK 
		DECLARE c_poststatus CURSOR FOR 
		SELECT * 
		FROM poststatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = TRAN_TYPE_INVOICE_IN 
		FOR UPDATE 
		OPEN c_poststatus 
		FETCH c_poststatus INTO pr_poststatus.* 
		IF status <> 0 THEN 
			# 7036 "Post STATUS NOT SET up - cannot run posting."
			LET msgresp = kandoomsg("U",7036,"") 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		IF pr_mode = "Y" AND pr_poststatus.post_running_flag = "Y" THEN 
			# 7037 "Post IS already running."
			LET msgresp = kandoomsg("U",7037,"") 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		# Set up STATUS flags according TO whether we are running, restarting
		# OR completing
		IF pr_mode = "Y" THEN 
			IF pr_poststatus.status_code < pr_complete THEN 
				LET pr_poststatus.post_running_flag = "Y" 
			ELSE 
				LET pr_poststatus.user_code = glob_rec_kandoouser.sign_on_code 
				LET pr_poststatus.status_code = pr_insert_phase 
				LET pr_poststatus.status_text = "ISP - commenced posting" 
				LET pr_poststatus.status_time = CURRENT year TO second 
				LET pr_poststatus.jour_num = NULL 
				LET pr_poststatus.post_running_flag = "Y" 
				LET pr_poststatus.post_year_num = pr_year_num 
				LET pr_poststatus.post_period_num = pr_period_num 
			END IF 
		ELSE 
			LET pr_poststatus.status_code = pr_complete 
			LET pr_poststatus.status_text = "ISP - completed posting" 
			LET pr_poststatus.status_time = CURRENT year TO second 
			LET pr_poststatus.post_running_flag = "N" 
		END IF 
		LET err_message = "ISP - Updating poststatus post running flag" 
		UPDATE poststatus 
		SET user_code = pr_poststatus.user_code, 
		status_code = pr_poststatus.status_code, 
		status_text = pr_poststatus.status_text, 
		status_time = pr_poststatus.status_time, 
		jour_num = pr_poststatus.jour_num, 
		post_running_flag = pr_poststatus.post_running_flag, 
		post_year_num = pr_poststatus.post_year_num, 
		post_period_num = pr_poststatus.post_period_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = TRAN_TYPE_INVOICE_IN 
		IF pr_mode = "Y" THEN 
			LET err_message = "ISP - Parameter table UPDATE " 
			UPDATE inparms 
			SET last_post_date = today 
			WHERE parm_code = "1" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 

FUNCTION post_in() 
	DEFINE 
	i, pr_status SMALLINT 

	#
	#  The posting proces consists of the following steps:
	#  1 - SELECT all the unposted product ledger transactions FOR the
	#      nominated year AND period AND INSERT the INTO the posting table
	#  2 - IF FIFO OR LIFO costing IS required, UPDATE the FIFO/LIFO details
	#  3 - Read through the posting table AND create the appropriate
	#      batch journal details in a temporaray batch detail table
	#  4 - Create a detailed OR summary journal batch FROM the batch detail
	#      table
	#  5 - OUTPUT the posting REPORT THEN UPDATE the source prodledg
	#      transactions with the journal number AND delete the records
	#      FROM the posting table
	#  IF the program detects that records already exist in the posting
	#  table, this indicates that the current posting IS being restarted
	#  AND the ledger selection step IS omitted.  IF the STATUS code on
	#  the post STATUS table indicates that the journal batch had been
	#  successfully created before the program failed, the program skips
	#  TO the deletion process TO complete the cycle.
	#
	#  Each step has a different locking strategy.  Steps 1,2 AND 5 lock
	#  AND release each RECORD as it IS processed.  Step 4 updates the
	#  glparms AND poststatus tables AND creates the journal in a single
	#  transaction.  Step 3 does no locking as there are no updates TO
	#  permanent tables, only inserts TO the temporary table.  IF the
	#  program fails in either step 3 OR step 4, both steps must be
	#  repeated.

	LET rpt1_note = "Inventory Posting Exception Report - (Menu ISP)" 
	LET pr_output1 = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, rpt1_note) 
	START REPORT exception_report TO pr_output1 

	FOR i = 1 TO 9 
		INITIALIZE pa_comments[i] TO NULL 
	END FOR 
	OPEN WINDOW wu157 with FORM "U157" 
	CALL winDecoration_u("U157") -- albo kd-758 
	# Only SELECT the product ledgers FOR posting IF NOT in restart mode
	IF pr_record_count = 0 THEN 
		CALL select_prodledg() 
	ELSE 
		LET pr_error_text = "Restarting posting FOR Year ", 
		pr_year_num USING "<<<<", 
		" Period ", pr_period_num USING "<<<<" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
	END IF 
	# Only do the batch journal posting IF that step was NOT completed
	# successfully before restart.
	IF pr_poststatus.status_code = pr_insert_phase THEN 
		IF pr_fifo_lifo THEN 
			CALL fifo_update() 
		END IF 
		CALL setup_jnl_detail() 
		CALL create_jnl_batch() 
	END IF 
	CALL del_postprodledg() 
	FINISH REPORT exception_report 
	CALL upd_reports(pr_output1, 
	rpt1_pageno, 
	rpt1_wid, 
	rpt1_length) 
	LET pr_status = update_status("N") 

	CLOSE WINDOW wu157 
END FUNCTION 



FUNCTION select_prodledg() 


	#  This step will lock each prodledg entry as it inserts INTO the table,
	#  UPDATE the prodledg as posted AND THEN commit the transaction. If
	#  a lock occurs AND the SELECT procedure IS restarted, the previously
	#  entered transactions will NOT be re-selected as they are marked as
	#  posted.  IF a restart IS required, the program will detect that
	#  records already exist in the posting table AND skip this funtion.

	DEFINE 
	pr_text_line CHAR(60), 
	pr_unknown_count INTEGER 

	LET pr_text_line = "Selecting ledger records FOR Year ", 
	pr_year_num USING "&&&&", 
	" Period ", pr_period_num USING "<<<" 
	CALL display_progress(pr_text_line) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		CALL isp_exit_program() 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	#
	# All ledgers are marked as posted but NOT all transaction types
	# have an effect on the General Ledger AND/OR FIFO-LIFO cost.
	# Only the items that are recognised by later processing are inserted
	# INTO postprodledg AND any records with an unknown transaction type
	# are ignored completely.
	# Recognised types are:-
	#-------------------------|-------|---------|-------------------------|
	#Type                     |GL Post|FIFO/LIFO|Comments                 |
	#-------------------------|-------|---------|-------------------------|
	#A - Adjustment           |   Y   |   N     | Quantities adjusted on  |
	#                         |       |         | cost ledger WHEN trans  |
	#                         |       |         | IS created.             |
	#-------------------------|-------|---------|-------------------------|
	#C - Sales Credit RETURN  |   Y   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#E - Maxbrick Export      |   Y   |   N     |                         |
	#-------------------------|-------|---------|-------------------------|
	#I - Stock Issue          |   Y   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#J - JM Stock Issue       |   Y   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#O - Opening Balance      |   N   |   N     | Refer IZ7               |
	#-------------------------|-------|---------|-------------------------|
	#P - Purchase Receipt     |   N   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#R - Stock Receipt        |  Y/N  |   Y     | Only posts TO GL IF flag|
	#                         |       |         | SET in inparms.         |
	#-------------------------|-------|---------|-------------------------|
	#S - Sale                 |   Y   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#T - Transfer             |   Y   |   Y     |                         |
	#-------------------------|-------|---------|-------------------------|
	#U - FIFO/LIFO Cost Update|   Y   |   N     | Costs adjusted on cost  |
	#                         |       |         | ledger WHEN tx created. |
	#-------------------------|-------|---------|-------------------------|
	#X - Reclassification     |  Y/N  |   N     | Only posts TO GL IF flag|
	#                         |       |         | SET in inparms.         |
	#-------------------------|-------|---------|-------------------------|
	#
	#
	# Retrieve unposted prodledg records AND INSERT INTO postprodledg
	#
	LET pr_unknown_count = 0 
	DECLARE c_prodledg CURSOR with HOLD FOR 
	SELECT * 
	FROM prodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = "N" 
	FOR UPDATE 
	FOREACH c_prodledg INTO pr_postprodledg.* 
		IF pr_postprodledg.trantype_ind NOT matches "[ACEIJOPRSTUX]" THEN 
			LET pr_unknown_count = pr_unknown_count + 1 
			CONTINUE FOREACH 
		END IF 
		BEGIN WORK 
			LET err_message = "ISP - Inserting posting transactions" 
			LET pr_record_count = pr_record_count + 1 
			IF pr_fifo_lifo AND pr_postprodledg.tran_qty <> 0 AND 
			pr_postprodledg.trantype_ind matches "[CIJPRST]" THEN 
				LET pr_postprodledg.post_flag = pr_ready_for_fifo 
			ELSE 
				LET pr_postprodledg.post_flag = pr_ready_for_post 
			END IF 
			INSERT INTO postprodledg VALUES (pr_postprodledg.*) 
			LET err_message = "ISP - Updating prodleg post flag" 
			UPDATE prodledg 
			SET post_flag = "Y" 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 

	IF pr_unknown_count > 0 THEN 
		LET pr_error_text = "WARNING: Invalid transaction type(s) found in ", 
		pr_unknown_count USING "<<<<<", " records" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
		CALL display_progress(pr_error_text) 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 



FUNCTION fifo_update() 


	#  This step will lock each postprodledg entry as it IS processed,
	#  UPDATE the post flag TO indicate that it IS ready TO post TO GL AND
	#  THEN commit the transaction. IF a lock occurs, the records will NOT
	#  be re-selected FOR FIFO/LIFO processing as the flag will have been
	#  changed.  IF a restart IS required, the FIFO/LIFO procedure will
	#  be restarted but again, only those records NOT yet updated will
	#  be selected FOR processing.
	DEFINE 
	pr_part_code LIKE prodledg.part_code, 
	pr_ware_code LIKE prodledg.ware_code, 
	pr_trantype_ind LIKE prodledg.trantype_ind, 
	pr_source_num LIKE prodledg.source_num, 
	pr_tran_qty LIKE prodledg.tran_qty, 
	pr_tran_cost LIKE prodledg.cost_amt, 
	pr_post_flag LIKE invoicehead.posted_flag, 
	pr_sale_tran_date LIKE invoicehead.inv_date, 
	pr_issue_qty LIKE prodledg.tran_qty, 
	pr_stocked_flag LIKE prodstatus.stocked_flag, 
	pr_fifo_cost_amt LIKE prodledg.cost_amt, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_act_seq_num LIKE activity.seq_num, 
	pr_act_cost_amt LIKE activity.act_cost_amt, 
	pr_job_code LIKE activity.job_code, 
	pr_var_code LIKE activity.var_code, 
	pr_activity_code LIKE activity.activity_code, 
	pr_call_status SMALLINT, 
	pr_db_status INTEGER, 
	pr_records_updated, 
	pr_records_skipped, 
	pr_jm_records SMALLINT 

	CALL display_progress("Updating FIFO/LIFO costs") 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		CALL isp_exit_program() 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET pr_records_updated = false 
	LET pr_records_skipped = false 
	LET pr_jm_records = false 
	#
	#  Transactions types of P (Purchase Order Receipt), R (Direct Receipt),
	#  I (Issues) AND J (Job Management Issues) all result in a matching
	#  cost ledger receipt entry IF the quantity IS positive.
	#  Product movements of these types with negative quantitis are dealt
	#  with in the UPDATE process FOR FIFO issues.
	#
	DECLARE c_fifo_receipt CURSOR with HOLD FOR 
	SELECT * 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_fifo 
	AND trantype_ind in ("I","J","P","R") 
	AND tran_qty > 0 
	FOR UPDATE 
	FOREACH c_fifo_receipt INTO pr_postprodledg.* 
		BEGIN WORK 
			LET err_message = "ISP - Creating FIFO/LIFO receipts" 
			LET pr_stocked_flag = NULL 
			SELECT stocked_flag 
			INTO pr_stocked_flag 
			FROM prodstatus 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			# Only RECORD cost ledger movements FOR stocked products
			IF pr_stocked_flag = "Y" THEN 
				LET pr_records_updated = true 
				CALL fifo_lifo_receipt(glob_rec_kandoouser.cmpy_code, 
				pr_postprodledg.part_code, 
				pr_postprodledg.ware_code, 
				pr_postprodledg.tran_date, 
				pr_postprodledg.seq_num, 
				pr_postprodledg.trantype_ind, 
				pr_postprodledg.tran_qty, 
				pr_inparms.cost_ind, 
				pr_postprodledg.cost_amt) 
				RETURNING pr_call_status, 
				pr_db_status 
				IF pr_call_status = false THEN 
					LET status = pr_db_status 
					GO TO recovery 
				END IF 
			END IF 
			LET err_message = "ISP - Updating postprodledg - FIFO/LIFO receipts" 
			UPDATE postprodledg 
			SET post_flag = pr_ready_for_post 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	#
	#  Transfers result in multiple cost ledger updates TO move each
	#  individual cost ledger comprising the total quantity transferred
	#  TO the destination warehouse.  Only the destination warehouse entries
	#  are selected FOR processing.  These point back TO the source entries
	#  via the source text (contains source warehouse) AND source number
	#  (contains transfer number).
	#
	DECLARE c_fifo_xfer CURSOR with HOLD FOR 
	SELECT * 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_fifo 
	AND trantype_ind = "T" 
	AND tran_qty > 0 
	FOR UPDATE 
	FOREACH c_fifo_xfer INTO pr_postprodledg.* 
		BEGIN WORK 
			LET err_message = "ISP - Creating FIFO/LIFO transfer" 
			LET pr_fifo_cost_amt = pr_postprodledg.cost_amt 
			LET pr_stocked_flag = NULL 
			SELECT stocked_flag 
			INTO pr_stocked_flag 
			FROM prodstatus 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			# Only RECORD cost ledger movements FOR stocked products
			IF pr_stocked_flag = "Y" THEN 
				LET pr_records_updated = true 
				CALL fifo_lifo_xfer(pr_postprodledg.cmpy_code, 
				pr_postprodledg.part_code, 
				pr_postprodledg.ware_code, 
				pr_postprodledg.tran_date, 
				pr_postprodledg.seq_num, 
				pr_postprodledg.trantype_ind, 
				pr_postprodledg.tran_qty, 
				pr_inparms.cost_ind, 
				pr_postprodledg.source_text) 
				RETURNING pr_call_status, pr_db_status, 
				pr_fifo_cost_amt 
				IF pr_call_status = false THEN 
					LET status = pr_db_status 
					GO TO recovery 
				END IF 
				IF pr_fifo_cost_amt <> pr_postprodledg.cost_amt THEN 
					LET err_message = "ISP - Updating xfer prodledg with FIFO cost" 
					UPDATE prodledg 
					SET cost_amt = pr_fifo_cost_amt 
					WHERE part_code = pr_postprodledg.part_code 
					AND ware_code = pr_postprodledg.ware_code 
					AND tran_date = pr_postprodledg.tran_date 
					AND seq_num = pr_postprodledg.seq_num 
					AND cmpy_code = pr_postprodledg.cmpy_code 
					LET err_message = "ISP - Updating source prodledg with FIFO cost" 
					UPDATE prodledg 
					SET cost_amt = pr_fifo_cost_amt 
					WHERE part_code = pr_postprodledg.part_code 
					AND ware_code = pr_postprodledg.source_text 
					AND tran_qty = (0 - pr_postprodledg.tran_qty) 
					AND source_num = pr_postprodledg.source_num 
					AND cmpy_code = pr_postprodledg.cmpy_code 
				END IF 
			END IF 
			UPDATE postprodledg 
			SET post_flag = pr_ready_for_post, 
			cost_amt = pr_fifo_cost_amt 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET err_message = "ISP - Updating source postprodledg with FIFO cost" 
			UPDATE postprodledg 
			SET post_flag = pr_ready_for_post, 
			cost_amt = pr_fifo_cost_amt 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.source_text 
			AND tran_qty = (0 - pr_postprodledg.tran_qty) 
			AND source_num = pr_postprodledg.source_num 
			AND cmpy_code = pr_postprodledg.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	#
	#  Sales AND credits result in both issues AND receipts in the cost
	#  ledger, depending on the sign of the quantity.  The quantity IS
	#  summed FOR each combination of warehouse, part code, transaction
	#  type AND source number TO get the net movement FOR that invoice OR
	#  credit.  This IS TO cater FOR situations in which there IS more
	#  than one invoice line FOR a given part AND FOR the effect of edits
	#  which result in reversal AND re-entry of the product ledgers even if
	#  there has been no actual change in the product movement.
	#  Both the posting ledger AND the original product ledger records are
	#  updated TO reflect the FIFO (OR LIFO) cost AND the invoice/credit
	#  cost amounts are also updated.  IF the movement results in a RETURN
	#  TO stock, the cost of the RETURN IS as recorded in the ledger entry.
	#  Note that the invoice/credit costs do NOT impact the GL through AR.
	#
	DECLARE c_fifo_cos CURSOR with HOLD FOR 
	SELECT part_code, 
	ware_code, 
	trantype_ind, 
	source_num, 
	sum(tran_qty), 
	sum(tran_qty * cost_amt) 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_fifo 
	AND trantype_ind in ("C","S") 
	GROUP BY 1,2,3,4 
	FOREACH c_fifo_cos INTO pr_part_code, 
		pr_ware_code, 
		pr_trantype_ind, 
		pr_source_num, 
		pr_tran_qty, 
		pr_tran_cost 
		LET pr_stocked_flag = NULL 
		SELECT stocked_flag 
		INTO pr_stocked_flag 
		FROM prodstatus 
		WHERE part_code = pr_postprodledg.part_code 
		AND ware_code = pr_postprodledg.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		# Only RECORD cost ledger movements FOR stocked products.
		# FOR non-stocked products, mark them ready TO post based
		# on standard cost.  Also, IF the tran qty IS zero
		# do no cost ledger movements, just flag FOR posting.
		IF pr_stocked_flag != "Y" OR pr_tran_qty = 0 THEN 
			BEGIN WORK 
				LET err_message = "ISP - Updating post flag in FIFO/LIFO" 
				UPDATE postprodledg 
				SET post_flag = pr_ready_for_post 
				WHERE part_code = pr_part_code 
				AND ware_code = pr_ware_code 
				AND trantype_ind = pr_trantype_ind 
				AND source_num = pr_source_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			COMMIT WORK 
		ELSE 
			# Do NOT attenpt FIFO/LIFO calculation until the invoice OR
			# credit IS posted AND no further edits are possible.  This
			# prevents phantom stock movements that distort FIFO/LIFO costs.
			LET pr_post_flag = NULL 
			IF pr_trantype_ind = "S" THEN 
				SELECT posted_flag, inv_date 
				INTO pr_post_flag, pr_sale_tran_date 
				FROM invoicehead 
				WHERE inv_num = pr_source_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				SELECT posted_flag, cred_date 
				INTO pr_post_flag, pr_sale_tran_date 
				FROM credithead 
				WHERE cred_num = pr_source_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			IF pr_post_flag IS NULL OR pr_post_flag <> "Y" THEN 
				LET pr_records_skipped = true 
				CONTINUE FOREACH 
			END IF 
			BEGIN WORK 
				LET err_message = "ISP - Updating FIFO/LIFO Cost of Sale" 
				LET pr_records_updated = true 
				# IF the net effect IS negative, this IS an issue
				IF pr_tran_qty < 0 THEN 
					LET pr_issue_qty = pr_tran_qty * -1 
					CALL fifo_lifo_issue(glob_rec_kandoouser.cmpy_code, 
					pr_part_code, 
					pr_ware_code, 
					pr_sale_tran_date, 
					0, 
					pr_trantype_ind, 
					pr_issue_qty, 
					pr_inparms.cost_ind, 
					true) 
					RETURNING pr_call_status, pr_db_status, 
					pr_fifo_cost_amt 
					IF pr_call_status = false THEN 
						LET status = pr_db_status 
						GO TO recovery 
					END IF 
					LET err_message = "ISP - Updating prodledg with FIFO cost" 
					UPDATE prodledg 
					SET cost_amt = pr_fifo_cost_amt 
					WHERE part_code = pr_part_code 
					AND ware_code = pr_ware_code 
					AND trantype_ind = pr_trantype_ind 
					AND source_num = pr_source_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF pr_trantype_ind = 'S' THEN 
						# Update invoice detail line
						LET err_message = "ISP - invoice detail UPDATE" 
						UPDATE invoicedetl 
						SET unit_cost_amt = pr_fifo_cost_amt, 
						ext_cost_amt = pr_fifo_cost_amt * ship_qty 
						WHERE inv_num = pr_source_num 
						AND part_code = pr_part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						# Update invoice header cost total
						LET err_message = "ISP - invoice header UPDATE" 
						UPDATE invoicehead 
						SET cost_amt = 
						(SELECT sum(ext_cost_amt) 
						FROM invoicedetl 
						WHERE invoicedetl.inv_num = pr_source_num 
						AND invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code) 
						WHERE inv_num = pr_source_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
					IF pr_trantype_ind = 'C' THEN 
						# Update credit detail line
						LET err_message = "ISP - credit detail UPDATE" 
						UPDATE creditdetl 
						SET unit_cost_amt = pr_fifo_cost_amt, 
						ext_cost_amt = pr_fifo_cost_amt * ship_qty 
						WHERE cred_num = pr_source_num 
						AND part_code = pr_part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						# Update credit header cost total
						LET err_message = "ISP - credit header UPDATE" 
						UPDATE credithead 
						SET cost_amt = 
						(SELECT sum(ext_cost_amt) 
						FROM creditdetl 
						WHERE creditdetl.cred_num = pr_source_num 
						AND creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code) 
						WHERE cred_num = pr_source_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
					# RETURN TO stock AT the average cost over all movements
					LET pr_fifo_cost_amt = pr_tran_cost / pr_tran_qty 
					CALL fifo_lifo_receipt(glob_rec_kandoouser.cmpy_code, 
					pr_part_code, 
					pr_ware_code, 
					pr_sale_tran_date, 
					0, 
					pr_trantype_ind, 
					pr_tran_qty, 
					pr_inparms.cost_ind, 
					pr_fifo_cost_amt) 
					RETURNING pr_call_status, 
					pr_db_status 
					IF pr_call_status = false THEN 
						LET status = pr_db_status 
						GO TO recovery 
					END IF 
				END IF 
				UPDATE postprodledg 
				SET post_flag = pr_ready_for_post, 
				cost_amt = pr_fifo_cost_amt 
				WHERE part_code = pr_part_code 
				AND ware_code = pr_ware_code 
				AND trantype_ind = pr_trantype_ind 
				AND source_num = pr_source_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			COMMIT WORK 
		END IF 
	END FOREACH 
	#
	#  Direct Issues (I),issues TO Job Management (J) AND negative Purchase
	#  Order receipts - ie. returns OR adjustments (P) result in issues
	#  FROM the cost ledger.  Both the posting ledger AND the original
	#  product ledger records are updated TO reflect the FIFO (OR LIFO)
	#  cost.  FOR Job Management issues, the associated job costs are
	#  also adjusted.  Note that the issues with positive transaction
	#  quantities are actually returns AND are dealt with as receipts.
	#
	DECLARE c_fifo_issue CURSOR with HOLD FOR 
	SELECT * 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_fifo 
	AND trantype_ind in ("I","J","P","R") 
	AND tran_qty < 0 
	FOR UPDATE 
	FOREACH c_fifo_issue INTO pr_postprodledg.* 
		BEGIN WORK 
			LET err_message = "ISP - Creating FIFO/LIFO issue" 
			LET pr_fifo_cost_amt = pr_postprodledg.cost_amt 
			LET pr_stocked_flag = NULL 
			SELECT stocked_flag 
			INTO pr_stocked_flag 
			FROM prodstatus 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			# Only RECORD cost ledger movements FOR stocked products
			IF pr_stocked_flag = "Y" THEN 
				LET pr_records_updated = true 
				LET pr_issue_qty = pr_postprodledg.tran_qty * -1 
				CALL fifo_lifo_issue(pr_postprodledg.cmpy_code, 
				pr_postprodledg.part_code, 
				pr_postprodledg.ware_code, 
				pr_postprodledg.tran_date, 
				pr_postprodledg.seq_num, 
				pr_postprodledg.trantype_ind, 
				pr_issue_qty, 
				pr_inparms.cost_ind, 
				true) 
				RETURNING pr_call_status, pr_db_status, 
				pr_fifo_cost_amt 
				IF pr_call_status = false THEN 
					LET status = pr_db_status 
					GO TO recovery 
				END IF 
				IF pr_fifo_cost_amt <> pr_postprodledg.cost_amt THEN 
					LET err_message = "ISP - Updating prodledg with FIFO cost - 2" 
					UPDATE prodledg 
					SET cost_amt = pr_fifo_cost_amt 
					WHERE part_code = pr_postprodledg.part_code 
					AND ware_code = pr_postprodledg.ware_code 
					AND tran_date = pr_postprodledg.tran_date 
					AND seq_num = pr_postprodledg.seq_num 
					AND cmpy_code = pr_postprodledg.cmpy_code 
					# IF this IS a Job Management issue, reverse the original
					# job ledger entry AND create a new one AT the revised
					# FIFO/LIFO cost.  Update the activity RECORD also.
					IF pr_postprodledg.trantype_ind = 'J' THEN 
						LET pr_jm_records = true 
						LET pr_job_code = pr_postprodledg.desc_text[1,8] 
						IF pr_postprodledg.desc_text[10,15] = " " OR 
						pr_postprodledg.desc_text[10,15] IS NULL THEN 
							LET pr_var_code = 0 
						ELSE 
							LET pr_var_code = pr_postprodledg.desc_text[10,15] 
							USING "&&&&&&" 
						END IF 
						LET pr_activity_code = pr_postprodledg.desc_text[17,24] 
						DECLARE c_jobledger CURSOR FOR 
						SELECT * FROM jobledger 
						WHERE job_code = pr_job_code 
						AND var_code = pr_var_code 
						AND activity_code = pr_activity_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND desc_text[1,15] = pr_postprodledg.part_code 
						AND desc_text[16,18] = pr_postprodledg.ware_code 
						AND trans_date = pr_postprodledg.tran_date 
						AND trans_qty = pr_issue_qty 
						AND trans_type_ind = 'IS' 
						# Retrieve the first match FOR this issue.  IF no match
						# IS found, the RECORD AND hence the job code will be
						# NULL - do no processing
						INITIALIZE pr_jobledger.* TO NULL 
						OPEN c_jobledger 
						FETCH c_jobledger INTO pr_jobledger.* 
						CLOSE c_jobledger 
						IF pr_jobledger.job_code IS NULL THEN 
							LET pr_error_text = "JM Issue FOR ", 
							pr_postprodledg.part_code clipped, 
							" Job ", pr_job_code clipped, 
							" Act. ", pr_activity_code clipped, 
							" NOT found" 
							OUTPUT TO REPORT exception_report(pr_error_text,false) 
						ELSE 
							DECLARE c_activity CURSOR FOR 
							SELECT seq_num, act_cost_amt FROM activity 
							WHERE job_code = pr_job_code 
							AND var_code = pr_var_code 
							AND activity_code = pr_activity_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							FOR UPDATE 
							OPEN c_activity 
							FETCH c_activity INTO pr_act_seq_num, 
							pr_act_cost_amt 

							# Reverse the jobledger entry
							LET pr_act_seq_num = pr_act_seq_num + 1 
							LET pr_act_cost_amt = 
							pr_act_cost_amt - pr_jobledger.trans_amt 
							LET pr_jobledger.seq_num = pr_act_seq_num 
							LET pr_jobledger.trans_qty = 
							pr_jobledger.trans_qty * -1 
							LET pr_jobledger.trans_amt = 
							pr_jobledger.trans_amt * -1 
							LET pr_jobledger.charge_amt = 
							pr_jobledger.charge_amt * -1 
							LET err_message = "ISP - job ledger reversal" 
							INSERT INTO jobledger VALUES (pr_jobledger.*) 
							# New jobledger entry reflecting the fifo cost.
							LET pr_act_seq_num = pr_act_seq_num + 1 
							LET pr_jobledger.seq_num = pr_act_seq_num 
							LET pr_jobledger.trans_qty = pr_issue_qty 
							LET pr_jobledger.trans_amt = 
							pr_issue_qty * pr_fifo_cost_amt 
							LET pr_jobledger.charge_amt = 
							pr_jobledger.charge_amt * -1 
							LET err_message = "ISP - job ledger INSERT" 
							INSERT INTO jobledger VALUES (pr_jobledger.*) 
							LET pr_act_cost_amt = 
							pr_act_cost_amt + pr_jobledger.trans_amt 
							LET err_message = "ISP - JM activity FIFO UPDATE" 
							UPDATE activity 
							SET seq_num = pr_act_seq_num, 
							act_cost_amt = pr_act_cost_amt 
							WHERE job_code = pr_job_code 
							AND var_code = pr_var_code 
							AND activity_code = pr_activity_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END IF 
				END IF 
			END IF 
			UPDATE postprodledg 
			SET post_flag = pr_ready_for_post, 
			cost_amt = pr_fifo_cost_amt 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	IF pr_records_updated THEN 
		LET pr_error_text = "FIFO/LIFO entries processed" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
	ELSE 
		LET pr_error_text = "No FIFO/LIFO entries FOR processing" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
	END IF 
	IF pr_records_skipped THEN 
		LET pr_error_text = 
		"Some invoices/credits NOT yet posted through AR" 
		OUTPUT TO REPORT exception_report(pr_error_text, true) 
		LET pr_error_text = 
		"Product ledger entries skipped - post again AFTER AR" 
		OUTPUT TO REPORT exception_report(pr_error_text, true) 
	END IF 
	IF pr_jm_records THEN 
		LET pr_error_text = 
		"Job Management entries created that require posting" 
		OUTPUT TO REPORT exception_report(pr_error_text, true) 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 




FUNCTION setup_jnl_detail() 


	#  This step only inserts details INTO a temporary table without
	#  logging.  There IS no locking as there are no updates TO permanent
	#  tables. IF a restart IS required, the temporary table will be
	#  recreated AND the processing will simply recommence.

	DEFINE 
	pr_category RECORD LIKE category.*, 
	pr_debitdetl RECORD LIKE batchdetl.*, 
	pr_creditdetl RECORD LIKE batchdetl.*, 
	pr_stock_acct_code LIKE category.stock_acct_code, 
	pr_cogs_acct_code LIKE category.cogs_acct_code, 
	pr_masked_acct_code LIKE prodledg.acct_code, 
	pr_debit_acct_code, pr_credit_acct_code LIKE batchdetl.acct_code, 
	pr_mask_code LIKE warehouse.acct_mask_code, 
	pr_ledg1_acct, pr_ledg2_acct LIKE ledgerreln.acct1_code, 
	pr_ord_ind LIKE ordhead.ord_ind, 
	pr_ord_num LIKE invoicehead.ord_num, 
	pr_rma_num LIKE credithead.rma_num, 
	pr_status_ind CHAR(1), 
	pr_tran_type CHAR(3) 

	CALL display_progress("Setting up journal details") 
	# Drop AND re-create a temporary table FOR the batch details
	# without logging
	WHENEVER ERROR CONTINUE 
	--   DROP TABLE t_batchdetl #changed to normal table
	--   CALL create_table("batchdetl", "t_batchdetl","","N") #changed to normal table
	WHENEVER ERROR stop 
	#
	# Set up static fields in the batch detail records
	#
	CALL init_batchdetl() 
	#
	DECLARE c1_postprodledg CURSOR FOR 
	SELECT * 
	FROM postprodledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_post 
	FOREACH c1_postprodledg INTO pr_postprodledg.* 
		#
		# Transaction types of "R" AND "X" may be present, but they
		# only post TO the General Ledger IF the flag IS SET in the
		# parameters AND the account IS NOT blank (indicating that
		# the flag was SET WHEN they were created also).  Types "O"
		# AND "P" may also be present but do NOT post TO GL. These records
		# will be skipped but the product ledger RECORD will be flagged
		# as posted.  Note that the type "P" AND "R" records must always
		# be updated TO cost ledgers IF FIFO/LIFO costing IS required,
		# regardless of the GL impact.
		#
		IF pr_postprodledg.trantype_ind matches "[RX]" AND 
		(pr_inparms.rec_post_flag <> "Y" OR 
		pr_postprodledg.acct_code IS NULL OR 
		pr_postprodledg.acct_code = " " OR 
		pr_postprodledg.source_text = "Shipment") THEN 
			CONTINUE FOREACH 
		END IF 
		IF pr_postprodledg.trantype_ind matches "[OP]" THEN 
			CONTINUE FOREACH 
		END IF 
		#
		# Fetch the category AND warehouse account mask
		# Set up the account codes required
		#
		INITIALIZE pr_category.* TO NULL 
		SELECT c.* 
		INTO pr_category.* 
		FROM category c, product p 
		WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND c.cat_code = p.cat_code 
		AND p.part_code = pr_postprodledg.part_code 
		LET pr_mask_code = NULL 
		SELECT acct_mask_code 
		INTO pr_mask_code 
		FROM warehouse 
		WHERE ware_code = pr_postprodledg.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_stock_acct_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_category.stock_acct_code) 

		# Get COGS ORDER indicator account code
		IF pr_postprodledg.acct_code IS NULL 
		OR pr_postprodledg.trantype_ind = "E" THEN 
			LET pr_status_ind = false 
			CASE pr_postprodledg.trantype_ind 
				WHEN "S" 
					SELECT ord_ind INTO pr_ord_ind FROM invheadext 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_num = pr_postprodledg.source_num 
					IF status = notfound 
					OR pr_ord_ind IS NULL THEN 
						SELECT ord_num INTO pr_ord_num FROM invoicehead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = pr_postprodledg.source_num 
						IF status != notfound THEN 
							SELECT ord_ind INTO pr_ord_ind FROM ordhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pr_ord_num 
							IF status != notfound THEN 
								LET pr_status_ind = true 
							END IF 
						END IF 
					ELSE 
						LET pr_status_ind = true 
					END IF 
				WHEN "C" 
					SELECT ord_ind INTO pr_ord_ind FROM creditheadext 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND credit_num = pr_postprodledg.source_num 
					IF status = notfound 
					OR pr_ord_ind IS NULL THEN 
						SELECT rma_num INTO pr_rma_num FROM credithead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cred_num = pr_postprodledg.source_num 
						IF status != notfound THEN 
							SELECT ord_ind INTO pr_ord_ind FROM ordhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pr_rma_num 
							IF status != notfound THEN 
								LET pr_status_ind = true 
							END IF 
						END IF 
					ELSE 
						LET pr_status_ind = true 
					END IF 
				WHEN "E" # maxbrick export 
					LET pr_ord_ind = "8" 
					LET pr_status_ind = true 
			END CASE 
			IF pr_status_ind THEN 
				CALL get_ordacct(glob_rec_kandoouser.cmpy_code,"category","cogs_acct_code", 
				pr_category.cat_code,pr_ord_ind) 
				RETURNING pr_cogs_acct_code 
				IF pr_cogs_acct_code IS NULL THEN 
					LET pr_cogs_acct_code = 
					build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_category.cogs_acct_code) 
				ELSE 
					LET pr_cogs_acct_code = 
					build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_cogs_acct_code) 
				END IF 
			ELSE 
				LET pr_cogs_acct_code = 
				build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_category.cogs_acct_code) 
			END IF 
		ELSE 
			LET pr_cogs_acct_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_postprodledg.acct_code) 
		END IF 
		LET pr_masked_acct_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,pr_mask_code,pr_postprodledg.acct_code) 
		#
		# Set up source information in CASE detailed posting IS required
		#
		CASE pr_postprodledg.trantype_ind 
			WHEN ("A") ## adjustments 
				LET pr_batchdetl.tran_type_ind = "ADJ" 
				LET pr_tran_type = "ADJ" 
			WHEN ("C") ## credits 
				LET pr_batchdetl.tran_type_ind = "COS" 
				LET pr_tran_type = "CRE" 
			WHEN ("E") ## maxbrick exports 
				IF pr_postprodledg.tran_qty < 0 THEN 
					LET pr_batchdetl.tran_type_ind = "ADJ" 
				ELSE 
					LET pr_batchdetl.tran_type_ind = "COS" 
				END IF 
				LET pr_tran_type = "MBE" 
			WHEN ("I") ## stock issues 
				LET pr_batchdetl.tran_type_ind = "ISS" 
				LET pr_tran_type = "ISS" 
			WHEN ("J") ## jm issue 
				LET pr_batchdetl.tran_type_ind = "JMI" 
				LET pr_tran_type = "JMI" 
			WHEN ("R") ## receipts 
				LET pr_batchdetl.tran_type_ind = "REC" 
				LET pr_tran_type = "REC" 
			WHEN ("S") ## sales 
				LET pr_batchdetl.tran_type_ind = "COS" 
				LET pr_tran_type = "INV" 
			WHEN ("T") ## transfers 
				LET pr_batchdetl.tran_type_ind = "TRF" 
				LET pr_tran_type = "TRF" 
			WHEN ("U") ## fifo/lifo cost adjustment 
				LET pr_batchdetl.tran_type_ind = "ADJ" 
				LET pr_tran_type = "ADJ" 
			WHEN ("X") ## reclassification 
				LET pr_batchdetl.tran_type_ind = "CLS" 
				LET pr_tran_type = "CLS" 
		END CASE 
		LET pr_batchdetl.ref_num = pr_postprodledg.source_num 
		LET pr_batchdetl.ref_text = pr_postprodledg.source_text 
		LET pr_batchdetl.desc_text[1,30] = 
		pr_postprodledg.part_code clipped, ",",pr_tran_type, ",", 
		pr_postprodledg.source_num USING "<<<<<<<<" 
		#
		# All postings result in both a debit AND a credit.
		#
		IF pr_postprodledg.tran_qty >= 0 THEN 
			#
			# All positive transaction quantities debit the stock account
			# FOR the product category AFTER it has been masked against the
			# warehouse with the following exceptions:
			# 1. Maxbrick exports (type E) debit COGS.
			#
			#
			# Debit Entry
			#
			IF pr_postprodledg.trantype_ind = "E" THEN 
				LET pr_debit_acct_code = pr_cogs_acct_code 
			ELSE 
				LET pr_debit_acct_code = pr_stock_acct_code 
			END IF 
			LET pr_batchdetl.debit_amt = 
			pr_postprodledg.tran_qty * pr_postprodledg.cost_amt 
			LET pr_batchdetl.for_debit_amt = pr_batchdetl.debit_amt 
			LET pr_batchdetl.credit_amt = 0 
			LET pr_batchdetl.for_credit_amt = 0 
			LET pr_batchdetl.acct_code = pr_debit_acct_code 
			INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			LET pr_debitdetl.* = pr_batchdetl.* 
			#
			# The credit entry FOR these transactions posts TO the
			# account in the product ledger entry AFTER it has been masked
			# against the warehouse, with the following exceptions:
			# 1. Accounts Receivable sales/credits (type "S", "C") credit
			#    COGS AFTER masking COGS against the warehouse.
			# 2. Transfers (type "T"), use the account as entered in the
			#    prodledg as the transfer procedure does the masking
			#    against the destination warehouse, TO allow automatic
			#    clearing WHEN the transfer IS completed
			# 3. Job Management Issues (type "J"), use the account as
			#    entered in the prodledg as JM does the masking.
			#
			# Credit Entry
			#
			CASE pr_postprodledg.trantype_ind 
				WHEN ("C") 
					LET pr_credit_acct_code = pr_cogs_acct_code 
				WHEN ("S") 
					LET pr_credit_acct_code = pr_cogs_acct_code 
				WHEN ("J") 
					LET pr_credit_acct_code = pr_postprodledg.acct_code 
				WHEN ("T") 
					LET pr_credit_acct_code = pr_postprodledg.acct_code 
				OTHERWISE 
					LET pr_credit_acct_code = pr_masked_acct_code 
			END CASE 
			LET pr_batchdetl.credit_amt = pr_batchdetl.for_debit_amt 
			LET pr_batchdetl.for_credit_amt = pr_batchdetl.credit_amt 
			LET pr_batchdetl.debit_amt = 0 
			LET pr_batchdetl.for_debit_amt = 0 
			LET pr_batchdetl.acct_code = pr_credit_acct_code 
			INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			LET pr_creditdetl.* = pr_batchdetl.* 
		ELSE 
			#
			# All negative transaction quantities credit the stock account
			# FOR the product category AFTER it has been masked against the
			# warehouse.
			#
			# The debit entry FOR these transactions posts TO the
			# account in the product ledger entry AFTER it has been masked
			# against the warehouse, with the following exceptions:
			# 1. Accounts Receivable sales/credits (type "S", "C") debit
			#    COGS AFTER masking COGS against the warehouse.
			# 2. Transfers (type "T"), use the account as entered in the
			#    prodledg as the transfer procedure does the masking
			#    against the destination warehouse, TO allow automatic
			#    clearing WHEN the transfer IS completed
			# 3. Job Management Issues (type "J"), use the account as
			#    entered in the prodledg as JM does the masking.
			#
			# Debit Entry
			#
			CASE pr_postprodledg.trantype_ind 
				WHEN ("C") 
					LET pr_debit_acct_code = pr_cogs_acct_code 
				WHEN ("S") 
					LET pr_debit_acct_code = pr_cogs_acct_code 
				WHEN ("J") 
					LET pr_debit_acct_code = pr_postprodledg.acct_code 
				WHEN ("T") 
					LET pr_debit_acct_code = pr_postprodledg.acct_code 
				OTHERWISE 
					LET pr_debit_acct_code = pr_masked_acct_code 
			END CASE 
			LET pr_batchdetl.debit_amt = 
			pr_postprodledg.tran_qty * pr_postprodledg.cost_amt * -1 
			LET pr_batchdetl.for_debit_amt = pr_batchdetl.debit_amt 
			LET pr_batchdetl.credit_amt = 0 
			LET pr_batchdetl.for_credit_amt = 0 
			LET pr_batchdetl.acct_code = pr_debit_acct_code 
			INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			LET pr_debitdetl.* = pr_batchdetl.* 
			#
			# Credit Entry
			#
			LET pr_batchdetl.credit_amt = pr_batchdetl.debit_amt 
			LET pr_batchdetl.for_credit_amt = pr_batchdetl.credit_amt 
			LET pr_batchdetl.debit_amt = 0 
			LET pr_batchdetl.for_debit_amt = 0 
			LET pr_batchdetl.acct_code = pr_stock_acct_code 
			INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			LET pr_creditdetl.* = pr_batchdetl.* 
		END IF 
		# IF multiledger applies, check TO see IF the debit/credit entries
		# cross ledger boundaries AND INSERT the appropriate inter-ledger
		# batch entries
		IF pr_multiledger THEN 
			CALL get_ledg_accts(glob_rec_kandoouser.cmpy_code, pr_debitdetl.acct_code, 
			pr_creditdetl.acct_code, pr_ledg_start, 
			pr_ledg_length) 
			RETURNING pr_ledg1_acct, pr_ledg2_acct 
			# Credit the debit entry inter_ledger account AND debit the
			# credit entry inter-ledger account
			IF pr_ledg1_acct IS NOT NULL AND pr_ledg2_acct IS NOT NULL THEN 
				LET pr_batchdetl.* = pr_creditdetl.* 
				LET pr_batchdetl.acct_code = pr_ledg1_acct 
				LET pr_batchdetl.tran_type_ind = "ML" 
				INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
				LET pr_batchdetl.* = pr_debitdetl.* 
				LET pr_batchdetl.acct_code = pr_ledg2_acct 
				LET pr_batchdetl.tran_type_ind = "ML" 
				INSERT INTO t_batchdetl VALUES (pr_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			END IF 
		END IF 
	END FOREACH 
END FUNCTION 



FUNCTION create_jnl_batch() 


	#  This step will UPDATE the next journal number AND the posting STATUS
	#  AND create the journal batch in a single transaction.  IF a restart
	#  IS required, the program will repeat the SET up of the temporary
	#  batch details table AND the creation of the GL journal  unless the
	#  posting STATUS indicates that the journal has been successfully
	#  updated in which CASE it will skip TO the deletion step.
	#  Note that a batch will ALWAYS be created, even in the (rare) CASE of
	#  all the debits cancelling the credits, TO provide an audit trail.

	DEFINE 
	pr_jour_num LIKE batchhead.jour_num, 
	pr_text_line CHAR(60) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		CALL isp_exit_program() 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	INITIALIZE pr_batchhead.* TO NULL 
	BEGIN WORK 
		LET err_message = "ISP - Updating glparms next journal number" 
		DECLARE c_jour_num CURSOR FOR 
		SELECT next_jour_num 
		FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_jour_num 
		FETCH c_jour_num INTO pr_jour_num 
		LET pr_jour_num = pr_jour_num + 1 
		UPDATE glparms 
		SET next_jour_num = next_jour_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = '1' 
		#
		LET pr_text_line = "Creating journal batch ", 
		pr_jour_num USING "<<<<<<<<" 
		CALL display_progress(pr_text_line) 
		#
		# Set up static details in batch header
		#
		LET pr_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_batchhead.jour_code = pr_inparms.inv_journal_code 
		LET pr_batchhead.jour_num = pr_jour_num 
		LET pr_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_batchhead.jour_date = today 
		LET pr_batchhead.year_num = pr_year_num 
		LET pr_batchhead.period_num = pr_period_num 
		LET pr_batchhead.control_amt = 0 
		LET pr_batchhead.debit_amt = 0 
		LET pr_batchhead.credit_amt = 0 
		LET pr_batchhead.for_debit_amt = 0 
		LET pr_batchhead.for_credit_amt = 0 
		LET pr_batchhead.control_qty = 0 
		LET pr_batchhead.stats_qty = 0 
		LET pr_batchhead.currency_code = pr_glparms.base_currency_code 
		LET pr_batchhead.conv_qty = 1.0 
		LET pr_batchhead.source_ind = "I" 
		IF pr_glparms.use_clear_flag = "Y" THEN 
			LET pr_batchhead.cleared_flag = "N" 
		ELSE 
			LET pr_batchhead.cleared_flag = "Y" 
		END IF 
		LET pr_batchhead.post_flag = "N" 
		LET pr_batchhead.seq_num = 0 
		LET pr_batchhead.com1_text = "Inventory Posting Journal - ISP" 
		#  Put in a comment TO show that FIFO/LIFO costing was used, just TO
		#  assist with problem solving IF the flag IS turned off OR on
		IF pr_fifo_lifo THEN 
			LET pr_batchhead.com2_text = "FIFO/LIFO Cost Method" 
		END IF 
		IF pr_inparms.gl_del_flag = "Y" THEN 
			LET err_message = "ISP - Inserting batchdetl records - detail batch" 
			DECLARE c1_batchdetl CURSOR FOR 
			SELECT * 
			FROM t_batchdetl 
			FOREACH c1_batchdetl INTO pr_batchdetl.* 
				# Do a last minute check on sign TO trap -ve debits OR credits
				# This should only ever happen IF the costs are negative but
				# we allows this, so we need TO stop -ve postings.
				IF pr_batchdetl.debit_amt < 0 THEN 
					LET pr_batchdetl.credit_amt = 0 - pr_batchdetl.debit_amt 
					LET pr_batchdetl.for_credit_amt = pr_batchdetl.credit_amt 
					LET pr_batchdetl.debit_amt = 0 
					LET pr_batchdetl.for_debit_amt = 0 
				END IF 
				IF pr_batchdetl.credit_amt < 0 THEN 
					LET pr_batchdetl.debit_amt = 0 - pr_batchdetl.credit_amt 
					LET pr_batchdetl.for_debit_amt = pr_batchdetl.debit_amt 
					LET pr_batchdetl.credit_amt = 0 
					LET pr_batchdetl.for_credit_amt = 0 
				END IF 
				# Add TO batch header totals AND SET up next sequence
				# number AND journal number before inserting
				CALL add_batch_totals() 
				INSERT INTO batchdetl VALUES (pr_batchdetl.*) 
			END FOREACH 
		ELSE 
			#
			# Set up static fields in the batch detail RECORD AND create
			# one summary entry per combination of transaction type AND
			# GL account code.  Need TO determine whether the result IS
			# a debit OR a credit
			#
			LET err_message = "ISP - Inserting batchdetl records - summary batch" 
			CALL init_batchdetl() 
			LET pr_batchdetl.ref_text = "Summary" 
			LET pr_batchdetl.ref_num = 0 
			DECLARE c2_batchdetl CURSOR FOR 
			SELECT tran_type_ind, 
			acct_code, 
			sum(debit_amt), 
			sum(credit_amt) 
			FROM t_batchdetl 
			GROUP BY tran_type_ind, acct_code 
			FOREACH c2_batchdetl INTO pr_batchdetl.tran_type_ind, 
				pr_batchdetl.acct_code, 
				pr_batchdetl.debit_amt, 
				pr_batchdetl.credit_amt 
				LET pr_batchdetl.desc_text = 
				"Summary ",pr_batchdetl.tran_type_ind, " FROM Inventory" 
				IF pr_batchdetl.debit_amt > pr_batchdetl.credit_amt THEN 
					LET pr_batchdetl.debit_amt = 
					pr_batchdetl.debit_amt - pr_batchdetl.credit_amt 
					LET pr_batchdetl.credit_amt = 0 
				ELSE 
					LET pr_batchdetl.credit_amt = 
					pr_batchdetl.credit_amt - pr_batchdetl.debit_amt 
					LET pr_batchdetl.debit_amt = 0 
				END IF 
				LET pr_batchdetl.for_debit_amt = pr_batchdetl.debit_amt 
				LET pr_batchdetl.for_credit_amt = pr_batchdetl.credit_amt 
				# Add TO batch header totals AND SET up next sequence
				# number AND journal number before inserting
				# Don't INSERT zero value (NULL effect) postings
				IF pr_batchdetl.debit_amt <> 0 OR 
				pr_batchdetl.credit_amt <> 0 THEN 
					CALL add_batch_totals() 
					INSERT INTO batchdetl VALUES (pr_batchdetl.*) 
				END IF 
			END FOREACH 
		END IF 
		# Determine whether the batch IS in balance OR NOT.  IF NOT,
		# balance TO GL suspense
		IF pr_batchhead.debit_amt <> pr_batchhead.credit_amt THEN 
			CALL init_batchdetl() 
			LET pr_batchdetl.tran_type_ind = "CO" 
			LET pr_batchdetl.ref_text = " " 
			LET pr_batchdetl.ref_num = 0 
			LET pr_batchdetl.desc_text = 
			" Inventory Post balancing entry TO suspense" 
			LET pr_batchdetl.acct_code = pr_glparms.susp_acct_code 
			IF pr_batchhead.debit_amt > pr_batchhead.credit_amt THEN 
				LET pr_batchdetl.debit_amt = 
				pr_batchhead.debit_amt - pr_batchhead.credit_amt 
				LET pr_batchdetl.credit_amt = 0 
			ELSE 
				LET pr_batchdetl.credit_amt = 
				pr_batchhead.credit_amt - pr_batchhead.debit_amt 
				LET pr_batchdetl.debit_amt = 0 
			END IF 
			LET pr_batchdetl.for_debit_amt = pr_batchdetl.debit_amt 
			LET pr_batchdetl.for_credit_amt = pr_batchdetl.credit_amt 
			CALL add_batch_totals() 
			LET err_message = "ISP - Inserting balancing batchdetl record" 
			INSERT INTO batchdetl VALUES (pr_batchdetl.*) 
		END IF 
		LET pr_batchhead.control_amt = pr_batchhead.for_debit_amt 
		# Flag batch as posted IF there are no detail lines AT all - posting
		# skips these batches.
		IF pr_batchhead.seq_num = 0 THEN 
			LET pr_batchhead.post_flag = "Y" 
		END IF 
		# Not CLEAR whether the batchhead seq_num IS next sequence number
		# TO use OR last number used.  Assume the former TO keep compatible
		# with previous post version.
		LET pr_batchhead.seq_num = pr_batchhead.seq_num + 1 
		LET err_message = "ISP - Inserting batchhead record" 
		CALL fgl_winmessage("25 Learning batch head codes - tell Hubert",pr_batchhead.source_ind,"info") 
		INSERT INTO batchhead VALUES (pr_batchhead.*) 
		# Set up AND UPDATE post STATUS fields FOR use in delete phase
		LET pr_poststatus.jour_num = pr_batchhead.jour_num 
		LET pr_poststatus.status_code = pr_delete_phase 
		LET err_message = "ISP - Updating poststatus journal number" 
		UPDATE poststatus 
		SET jour_num = pr_poststatus.jour_num, 
		status_code = pr_poststatus.status_code 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = TRAN_TYPE_INVOICE_IN 
		LET pr_error_text = "Inventory Journal ", 
		pr_batchhead.jour_num USING "<<<<<<<<", 
		" - Debit total = ", 
		pr_batchhead.debit_amt USING "---,---,--&.&&" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 



FUNCTION del_postprodledg() 


	#  This step first creates a posting REPORT FROM the inventory journal.
	#  It THEN locks each posting product ledger, updates the associated
	#  product ledger with the journal number AND deletes the associated
	#  posting RECORD AND commits the transaction.  IF a lock occurs, the
	#  previously updated records cannot be reprocessed as they have
	#  been deleted.  IF a restart IS required, the deletion process IS
	#  simply recommenced on the remaining posting transactions. The
	#  journal number created IS written onto the post STATUS table in
	#  the same transaction as the journal IS created, so that the number
	#  can be retrieved in the event of a restart AFTER step 4 completes.
	#

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		CALL isp_exit_program() 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	#
	# Note that pr_poststatus contains the relevant journal number, even in
	# a restart becuase the RECORD IS updated WHEN the journal IS created
	# AND retrieved AT the start of the program.
	#
	CALL display_progress("Creating posting REPORT") 
	LET rpt2_note = "Inventory Posting Batch Report - (Menu ISP)" 
	LET pr_output2 = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, rpt2_note) 
	START REPORT post_report TO pr_output2 
	SELECT * 
	INTO pr_batchhead.* 
	FROM batchhead 
	WHERE jour_num = pr_poststatus.jour_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET pr_error_text = "Inventory Journal ", 
		pr_poststatus.jour_num USING "<<<<<<<<", 
		" NOT found - ABORTING RUN" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
		CALL display_progress(pr_error_text) 
		LET msgresp = kandoomsg("U",7016,"") 
		#7016 Error Occurred. Refer TO REPORT FOR more information.
		EXIT program 
	END IF 
	LET pr_invalid_acct = false 
	DECLARE c3_batchdetl CURSOR FOR 
	SELECT * 
	FROM batchdetl 
	WHERE jour_num = pr_poststatus.jour_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY jour_num,seq_num 
	FOREACH c3_batchdetl INTO pr_batchdetl.* 
		OUTPUT TO REPORT post_report(pr_batchdetl.*) 
	END FOREACH 
	FINISH REPORT post_report 
	CALL upd_reports(pr_output2, 
	rpt2_pageno, 
	rpt2_wid, 
	rpt2_length) 
	IF pr_invalid_acct THEN 
		LET pr_error_text = "WARNING: Refer posting REPORT" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
		LET pr_error_text = "Journal ", 
		pr_poststatus.jour_num USING "<<<<<<<<", 
		" has accounts that are unknown OR", 
		" NOT OPEN" 
		OUTPUT TO REPORT exception_report(pr_error_text, true) 
	END IF 
	#
	CALL display_progress("Deleting posting details") 
	DECLARE c2_postprodledg CURSOR with HOLD FOR 
	SELECT * 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_post 
	FOR UPDATE 
	FOREACH c2_postprodledg INTO pr_postprodledg.* 
		BEGIN WORK 
			LET err_message = "ISP - updating prodledg journal number" 
			UPDATE prodledg 
			SET jour_num = pr_poststatus.jour_num 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET err_message = "ISP - deleting postprodledg record" 
			DELETE FROM postprodledg 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	# IF any prodledg entries could NOT be posted because FIFO/LIFO
	# calculation could NOT be completed, reset the post flag
	DECLARE c3_postprodledg CURSOR with HOLD FOR 
	SELECT * 
	FROM postprodledg 
	WHERE period_num = pr_period_num 
	AND year_num = pr_year_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND post_flag = pr_ready_for_fifo 
	AND trantype_ind in ("C","S") 
	FOR UPDATE 
	FOREACH c3_postprodledg INTO pr_postprodledg.* 
		BEGIN WORK 
			LET err_message = "ISP - reset flag on skipped prodledg entries" 
			UPDATE prodledg 
			SET post_flag = "N" 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET err_message = "ISP - deleting postprodledg RECORD - 2" 
			DELETE FROM postprodledg 
			WHERE part_code = pr_postprodledg.part_code 
			AND ware_code = pr_postprodledg.ware_code 
			AND tran_date = pr_postprodledg.tran_date 
			AND seq_num = pr_postprodledg.seq_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	#
	# Reset the RECORD count TO ensure that all records were correctly
	# processed.  Abort the run IF NOT, leaving the posting flag SET.
	#
	SELECT count(*) INTO pr_record_count 
	FROM postprodledg WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_record_count IS NULL THEN 
		LET pr_record_count = 0 
	END IF 
	IF pr_record_count <> 0 THEN 
		LET pr_error_text = "Posting records still in table ", 
		"- ABORTING RUN" 
		OUTPUT TO REPORT exception_report(pr_error_text, false) 
		CALL display_progress(pr_error_text) 
		LET msgresp = kandoomsg("U",7016,"") 
		#7016 Error Occurred. Refer TO REPORT FOR more information.
		EXIT program 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 



FUNCTION init_batchdetl() 


	#  The RECORD pr_batchdetl IS a global variable

	INITIALIZE pr_batchdetl.* TO NULL 
	LET pr_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_batchdetl.jour_code = pr_inparms.inv_journal_code 
	LET pr_batchdetl.tran_date = today 
	LET pr_batchdetl.currency_code = pr_glparms.base_currency_code 
	LET pr_batchdetl.conv_qty = 1.0 
	LET pr_batchdetl.stats_qty = 0 
END FUNCTION 



FUNCTION add_batch_totals() 


	#  The records pr_batchhead AND pr_batchdetl are global variables

	LET pr_batchhead.debit_amt = 
	pr_batchhead.debit_amt + pr_batchdetl.debit_amt 
	LET pr_batchhead.for_debit_amt = 
	pr_batchhead.for_debit_amt + pr_batchdetl.for_debit_amt 
	LET pr_batchhead.credit_amt = 
	pr_batchhead.credit_amt + pr_batchdetl.credit_amt 
	LET pr_batchhead.for_credit_amt = 
	pr_batchhead.for_credit_amt + pr_batchdetl.for_credit_amt 
	LET pr_batchhead.seq_num = pr_batchhead.seq_num + 1 
	LET pr_batchdetl.seq_num = pr_batchhead.seq_num 
	LET pr_batchdetl.jour_num = pr_batchhead.jour_num 
END FUNCTION 



FUNCTION display_progress(pr_text_line) 


	DEFINE 
	pr_text_line CHAR(60), 
	pr_idx SMALLINT 

	FOR pr_idx = 1 TO 9 
		IF pa_comments[pr_idx] IS NULL THEN 
			EXIT FOR 
		END IF 
	END FOR 
	# IF the comment ARRAY IS full, CLEAR AND start again AT the top
	IF pr_idx > 9 THEN 
		FOR pr_idx = 1 TO 9 
			INITIALIZE pa_comments[pr_idx] TO NULL 
		END FOR 
		LET pr_idx = 1 
	END IF 
	LET pa_comments[pr_idx] = pr_text_line 
	DISPLAY pa_comments[pr_idx] TO sr_comments[pr_idx].comments 

END FUNCTION 



FUNCTION isp_exit_program() 


	#  Allows the user TO abandon the posting IF there IS a lock AND
	#  restart later
	LET pr_error_text = "Post IS incomplete - restart required" 
	OUTPUT TO REPORT exception_report(pr_error_text, false) 
	CALL display_progress(pr_error_text) 
	LET msgresp = kandoomsg("U",7016,"") 
	#7016 Error Occurred. Refer TO REPORT FOR more information.
	WHENEVER ERROR CONTINUE 
	UPDATE poststatus 
	SET post_running_flag = "N" 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = TRAN_TYPE_INVOICE_IN 
	WHENEVER ERROR stop 
	EXIT program 
END FUNCTION 



REPORT exception_report(pr_error_text,pr_follow_line) 


	DEFINE 
	pr_error_text CHAR(60), 
	pr_follow_line, offset1, offset2 SMALLINT, 
	line1 CHAR(132), 
	pr_date_time DATETIME year TO second 

	OUTPUT 
	left margin 1 

	FORMAT 
		PAGE HEADER 
			IF rpt1_note IS NULL THEN 
				LET rpt1_note = "Inventory Posting Exception Report - (Menu ISP)" 
			END IF 
			LET rpt1_wid = 80 
			LET line1 = pr_company.cmpy_code, " ", pr_company.name_text clipped 
			LET offset1 = (rpt1_wid/2) - (length (line1) / 2) + 1 
			LET offset2 = (rpt1_wid/2) - (length (rpt1_note) / 2) + 1 
			PRINT COLUMN 01, today USING "DD MMM YYYY", 
			COLUMN offset1, line1 clipped, 
			COLUMN (rpt1_wid -10), "Page :", 
			COLUMN (rpt1_wid - 3), pageno USING "##&" 
			PRINT COLUMN 01, time, 
			COLUMN offset2, rpt1_note 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"-----------------------------" 
			PRINT COLUMN 01, "Date Time", 
			COLUMN 22, "Comments" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"-----------------------------" 
			LET rpt1_pageno = pageno 
		ON EVERY ROW 
			IF pr_follow_line THEN 
				PRINT COLUMN 022, pr_error_text clipped 
			ELSE 
				SKIP 1 line 
				LET pr_date_time = CURRENT 
				PRINT COLUMN 001, pr_date_time, 
				COLUMN 022, pr_error_text clipped 
			END IF 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 022, "Posting Complete FOR Year ", 
			pr_year_num USING "&&&&", 
			" Period ", pr_period_num USING "<<<<" 
			PRINT COLUMN 022, "***** END OF EXCEPTION REPORT *****" 
END REPORT 



REPORT post_report(pr_batchdetl) 


	DEFINE 
	pr_batchdetl RECORD LIKE batchdetl.*, 
	pr_coa RECORD LIKE coa.*, 
	offset1, offset2 SMALLINT, 
	line1, line2 CHAR(132), 
	pr_start_period, pr_end_period LIKE batchhead.period_num, 
	pr_start_year, pr_end_year LIKE batchhead.year_num, 
	coa_not_found, coa_not_open SMALLINT 

	OUTPUT 
	left margin 1 

	ORDER external BY pr_batchdetl.jour_num, 
	pr_batchdetl.seq_num 

	FORMAT 
		PAGE HEADER 
			LET rpt2_wid = 132 
			LET line1 = today clipped, 10 spaces, pr_company.cmpy_code, 
			2 spaces, pr_company.name_text clipped, 10 spaces, 
			"Page :", pageno USING "####" 
			LET line2 = rpt2_note clipped 
			LET offset1 = (rpt2_wid - length(line1))/2 
			LET offset2 = (rpt2_wid - length(line2))/2 
			PRINT COLUMN offset1, line1 clipped 
			PRINT COLUMN offset2, line2 clipped 
			SKIP 1 line 
			PRINT COLUMN 1, "Batch: ", 
			pr_batchhead.jour_num USING "<<<<<<<<<", 
			COLUMN 18, "Year/Period: ", 
			pr_batchhead.year_num USING "&&&&","/", 
			pr_batchhead.period_num USING "<<<", 
			COLUMN 66, "Posted by: ", pr_batchhead.entry_code, 
			COLUMN 92, "Currency: ", pr_batchhead.currency_code 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 
			PRINT COLUMN 2, "Seq", 
			COLUMN 6, "Type", 
			COLUMN 11, "Account", 
			COLUMN 30, "Description", 
			COLUMN 70, "Debit", 
			COLUMN 85, "Credit" 
			PRINT COLUMN 1, "--------------------------------------------", 
			"--------------------------------------------", 
			"-------------------------------------------" 

		ON EVERY ROW 
			# Check TO see IF the coa exists AND IS OPEN FOR this period.
			# IF NOT flag it AND PRINT MESSAGE
			LET coa_not_found = false 
			LET coa_not_open = false 
			SELECT start_year_num, 
			start_period_num, 
			end_year_num, 
			end_period_num 
			INTO pr_start_year, 
			pr_start_period, 
			pr_end_year, 
			pr_end_period 
			FROM coa 
			WHERE acct_code = pr_batchdetl.acct_code 
			AND cmpy_code = pr_batchdetl.cmpy_code 
			IF status = notfound THEN 
				LET coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((pr_end_year < pr_batchhead.year_num) OR 
				(pr_end_year = pr_batchhead.year_num AND 
				pr_end_period < pr_batchhead.period_num)) OR 
				((pr_start_year > pr_batchhead.year_num) OR 
				(pr_start_year = pr_batchhead.year_num AND 
				pr_start_period > pr_batchhead.period_num))) THEN 
					LET coa_not_open = true 
				END IF 
			END IF 
			IF coa_not_found OR coa_not_open THEN 
				LET pr_invalid_acct = true 
			END IF 

			PRINT COLUMN 1, pr_batchdetl.seq_num USING "####", 
			COLUMN 6 , pr_batchdetl.tran_type_ind, 
			COLUMN 11, pr_batchdetl.acct_code , 
			COLUMN 30, pr_batchdetl.desc_text, 
			COLUMN 60, pr_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 76, pr_batchdetl.credit_amt USING "-----------&.&&" 

			IF coa_not_found THEN 
				PRINT COLUMN 20, "** ERROR - Cannot find account : ", 
				pr_batchdetl.acct_code 
			END IF 
			IF coa_not_open THEN 
				PRINT COLUMN 20, "** ERROR - Account NOT OPEN : ", 
				pr_batchdetl.acct_code 
			END IF 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(pr_batchdetl.debit_amt) USING "-----------&.&&", 
			COLUMN 76, sum(pr_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 

			LET rpt2_pageno = pageno 
			LET rpt2_length = 66 
			PRINT COLUMN 50," ***** END OF INVENTORY POSTING REPORT ***** " 
END REPORT 
