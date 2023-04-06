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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

--GLOBALS 

--	DEFINE glob_rec_coa RECORD LIKE coa.* 
--	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
--	DEFINE glob_rec_batchdetl RECORD LIKE batchdetl.* 
--	DEFINE glob_rec_account RECORD LIKE account.* 
--	DEFINE glob_rec_accounthist RECORD LIKE accounthist.* 
--	DEFINE glob_rec_accountcur RECORD LIKE accountcur.* 
--	DEFINE glob_rec_accounthistcur RECORD LIKE accounthistcur.* 

	DEFINE glob_run_total LIKE account.bal_amt 
	DEFINE glob_total_debit LIKE account.bal_amt 
	DEFINE glob_total_credit LIKE account.bal_amt 
	#DEFINE runner, l_where_text CHAR(800)
	#DEFINE l_query_text, runner, l_where_text CHAR(800)
	DEFINE glob_err_message STRING 
	DEFINE glob_autopost char(1) 
	DEFINE glob_fisc_year_num SMALLINT 
	DEFINE glob_counter SMALLINT 
	DEFINE glob_fisc_period_num SMALLINT 
	DEFINE glob_entries_for_batch INTEGER 
	DEFINE glob_start_no INTEGER 
	DEFINE glob_end_no INTEGER 

-- GLOBALS 

###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_arr_rec_posting_report DYNAMIC ARRAY OF RECORD 
	jour_code LIKE journal.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	posting_status SMALLINT, #0=posted, 1-9 ERROR id 
	year_num LIKE coa.start_year_num, 
	period_num LIKE coa.start_period_num, 
	total_debit LIKE account.bal_amt, 
	total_credit LIKE account.bal_amt, 
	post_amt LIKE account.bal_amt, 
	post_flag boolean #double status - this one IS only FOR checkbox true/false status true = checked.. anything ELSE IS NOT checked.
END RECORD 
# This array is the main array on which one choose the batches to post, then it serves to display status
DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD 
	do_post BOOLEAN, 
	year_num LIKE period.year_num, 
	period_num LIKE period.period_num,
	jour_code LIKE batchhead.jour_code,
	jour_num LIKE batchhead.jour_num,
	jour_date LIKE batchhead.jour_date,
	jour_status NCHAR(15),
	credit_amt LIKE batchhead.credit_amt,
	debit_amt LIKE batchhead.debit_amt,
	com1_text LIKE batchhead.com1_text,
	first_date LIKE batchdetl.tran_date,
	last_date LIKE batchdetl.tran_date,
	entries_number INTEGER
END RECORD 
DEFINE modu_rec_glparms RECORD LIKE glparms.*
DEFINE modu_rep_idx SMALLINT
DEFINE modu_rec_postrun RECORD LIKE postrun.* 
DEFINE do_in_one_transaction BOOLEAN

# Module cursors and prepared
DEFINE mdl_prp_upd_main_batchhead PREPARED
DEFINE mdl_prp_ins_accountledger PREPARED
DEFINE mdl_prp_ins_account PREPARED
DEFINE mdl_prp_upd_account PREPARED
DEFINE mdl_prp_upd_accounthist PREPARED
DEFINE mdl_prp_ins_accounthist PREPARED
DEFINE mdl_prp_upd_accountcur PREPARED
DEFINE mdl_prp_ins_accountcur PREPARED
DEFINE mdl_prp_upd_accounthistcur PREPARED
DEFINE mdl_prp_ins_accounthistcur PREPARED
DEFINE mdl_prp_ins_postrun PREPARED
DEFINE mdl_prp_upd_postrun PREPARED
DEFINE mdl_crs_batchdetl CURSOR
DEFINE mdl_crs_accounthistcur_check CURSOR
DEFINE mdl_crs_accounthist_check CURSOR
DEFINE mdl_crs_multiledg_credits CURSOR
DEFINE mdl_crs_multiledg_debits CURSOR

###########################################################################
# FUNCTION GP2_main()
#
# Purpose :  Posts batches TO the account ledger,
#                                 account currency,
#                                 account currency history,
#                                 account history,
#                         AND the account table.
#
###########################################################################
FUNCTION GP2_main() 
	DEFINE l_run_arg STRING

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP2") 

	LET glob_run_total = 0 
	LET modu_rec_postrun.post_amt = 0 

	CREATE temp TABLE t_multiledg(
		flex_code char(18), 
		debit_amt decimal(16,2), 
		credit_amt decimal(16,2), 
		for_debit_amt decimal(16,2), 
		for_credit_amt decimal(16,2)) with no LOG 

	CALL initial_check_parameters() 
	CALL prepare_cursors_and_prepares_GP2()

	IF glob_autopost = "n" THEN 
		CALL construct_dataset_periods_to_post() 
	ELSE 
		CALL post_non_posted_batches() 
		
		IF glob_counter > 0 THEN
			LET l_run_arg = "POST_RUN_NUM=", trim(modu_rec_postrun.post_run_num) 
			CALL run_prog("GB7",l_run_arg,"","","") 
		END IF 
	END IF
	 
END FUNCTION 
###########################################################################
# END FUNCTION GP2_main()
###########################################################################


###########################################################################
# FUNCTION initial_check_parameters()
#
#
###########################################################################
FUNCTION initial_check_parameters() 
	SELECT * INTO modu_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR #5007", kandoomsg2("G",5007,""),"ERROR") #5007 " General Ledger Parametere Not Set Up"
		EXIT PROGRAM 
	END IF
	 
	LET glob_counter = 0 
	LET glob_autopost = get_url_autopost() #this needs TO change FROM arg_val(1) TO url 
	
	IF glob_autopost = "y" THEN 
		LET glob_fisc_period_num = get_url_tempper() #arg_val(3) #this needs TO change FROM arg_val(2) TO url 
		LET glob_fisc_year_num = get_url_fiscal_year_num() #arg_val(2) #this needs TO change FROM arg_val(3) TO url 
		LET glob_start_no = 0 
		LET glob_end_no = 999999999 
	ELSE 
		LET glob_autopost = "n" 
	END IF
	 
END FUNCTION  # initial_check_parameters

###########################################################################
# FUNCTION construct_dataset_periods_to_post()
#
#
###########################################################################
FUNCTION construct_dataset_periods_to_post() 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD 
		do_post BOOLEAN, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num,
		jour_code LIKE batchhead.jour_code,
		jour_num LIKE batchhead.jour_num,
		jour_date LIKE batchhead.jour_date,
		jour_status NCHAR(15),
		credit_amt LIKE batchhead.credit_amt,
		debit_amt LIKE batchhead.debit_amt,
		com1_text LIKE batchhead.com1_text,
		first_date LIKE batchdetl.tran_date,
		last_date LIKE batchdetl.tran_date,
		entries_number INTEGER
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_count_batches_to_post INTEGER
	DEFINE l_arr_curr INTEGER #, scrn 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_temptabname STRING
	DEFINE l_batchhead_filters_clause STRING
	DEFINE l_batch_ready_clause STRING
	DEFINE l_run_arg STRING 
	DEFINE l_start_journal_number,l_end_journal_number INTEGER
	DEFINE l_operation_status INTEGER
	DEFINE l_batches_number INTEGER
	DEFINE l_not_ready_batches INTEGER
	DEFINE crs_choose_periods CURSOR
	DEFINE crs_count_batchhead_notready CURSOR
	#	DEFINE l_str_tmp STRING

	OPEN WINDOW G155 with FORM "G155_new" 
	CALL windecoration_g("G155") 
	
	SELECT COUNT(*) 
	INTO l_count_batches_to_post
	FROM list_of_batches_to_post

	CALL modu_arr_rec_period.Clear()
	CLEAR FORM
	LET do_in_one_transaction = 1		#  we commit in one block by default
	ERROR "Please Choose AllTogether or Batch per Batch, then Accept"
	INPUT BY NAME do_in_one_transaction WITHOUT DEFAULTS
	
	WHILE true 
		 
		MESSAGE kandoomsg2("G",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		INITIALIZE l_batchhead_filters_clause TO NULL
		IF l_count_batches_to_post > 0 THEN		# last session did not post all requested batches, we first propose the list of remaining ones
			LET l_batchhead_filters_clause = " AND h.cmpy_code||h.jour_code||h.jour_num IN ( SELECT cmpy_code||jour_code||jour_num FROM list_of_batches_to_post ) "
			LET l_where_text = " 1 = 1 "
		ELSE
			CONSTRUCT BY NAME l_where_text ON year_num,period_num,jour_code,jour_num,jour_date,credit_amt,debit_amt,com1_text
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GP2","construct-year") 
					CALL DIALOG.SetFieldActive("year_num", TRUE)
					CALL DIALOG.SetFieldActive("period_num", TRUE)
					CALL DIALOG.SetFieldActive("jour_code", TRUE)
					CALL DIALOG.SetFieldActive("jour_num", TRUE)
					CALL DIALOG.SetFieldActive("jour_date", TRUE)
					CALL DIALOG.SetFieldActive("credit_amt", TRUE)
					CALL DIALOG.SetFieldActive("debit_amt", TRUE)
					CALL DIALOG.SetFieldActive("com1_text", TRUE)
	
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
	
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 
	
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN 
			END IF 
		END IF
		LET l_batch_ready_clause ="h.post_flag <> 'Y' ",
		" AND h.debit_amt = h.credit_amt ",
		" AND h.for_debit_amt = h.for_credit_amt ",
		" AND (h.currency_code != ? OR (h.currency_code = ? AND h.debit_amt = h.for_debit_amt)) "
		
		# Prepare where clause this will serve in this cursor and also in the post_non_posted_batches cursor
		LET l_batchhead_filters_clause = l_batchhead_filters_clause," AND " , l_batch_ready_clause
		
		IF modu_rec_glparms.control_tot_flag != 'Y' THEN
			LET l_batchhead_filters_clause = l_batchhead_filters_clause," AND h.for_debit_amt = h.control_amt ",
			" AND h.stats_qty = h.control_qty "
		END IF
		--IF modu_rec_glparms.use_clear_flag = 'Y' THEN
		# FIXME: set to Z for testing purpose
		IF modu_rec_glparms.use_clear_flag = 'Z' THEN
			LET l_batchhead_filters_clause = l_batchhead_filters_clause," AND h.cleared_flag = 'Y' "
		END IF

		MESSAGE kandoomsg2("G",1002,"")	#1002 " Searching database - please wait
		LET l_query_text = 
			"SELECT 't',year_num,period_num,h.jour_code,h.jour_num,jour_date,'To be posted',h.credit_amt,h.debit_amt,com1_text,min(d.tran_date),max(d.tran_date),count (*) ",
			" FROM batchhead h, ", 
			" batchdetl d ",
			"WHERE h.cmpy_code = ? ", 
			" AND h.cmpy_code = d.cmpy_code ",
			" AND h.jour_code = d.jour_code ",
			" AND h.jour_num = d.jour_num ",
			l_batchhead_filters_clause,
			" AND ",l_where_text clipped, " ",
			" GROUP BY 1,2,3,4,5,6,7,8,9,10",
			" ORDER BY year_num, period_num,jour_code,jour_num " 

		CALL crs_choose_periods.Declare(l_query_text)
		CALL crs_choose_periods.Open(glob_rec_kandoouser.cmpy_code,glob_rec_glparms.base_currency_code,glob_rec_glparms.base_currency_code)

		LET l_idx = 1 
		CALL modu_arr_rec_period.clear()

		WHILE crs_choose_periods.FetchNext (modu_arr_rec_period[l_idx].*) = 0
			LET l_idx = l_idx + 1 
		END WHILE
		 
		CALL modu_arr_rec_period.DeleteElement(l_idx)   # delete last element which is empty
		LET l_idx = l_idx -1
		DISPLAY l_idx TO batch_count
		IF l_idx = 0 THEN 
			CALL fgl_winmessage("Error",kandoomsg("G",9134,""),"ERROR") #9133 " No Periods satisfied selection criteria
			#give the user some time TO read the ERROR OF NOT found records 
			CONTINUE WHILE 
		END IF 

		LET l_query_text = "SELECT COUNT(*) FROM batchhead h",
		" WHERE h.cmpy_code = ? ",
		" AND NOT (",l_batch_ready_clause, ")"
		CALL crs_count_batchhead_notready.Declare(l_query_text)
		CALL crs_count_batchhead_notready.Open(glob_rec_kandoouser.cmpy_code,glob_rec_glparms.base_currency_code,glob_rec_glparms.base_currency_code)
		CALL crs_count_batchhead_notready.FetchNext(l_not_ready_batches)
		DISPLAY l_not_ready_batches TO not_ready_nbr

		MESSAGE kandoomsg2("G",1036,"")		#1036 " RETURN on line TO Post - CTRL-V TO View"
		INPUT ARRAY  modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.*  ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GP2","inp-arr-period") 
				--CALL dialog.setActionHidden("ACCEPT",TRUE) 
				CALL DIALOG.SetFieldActive("year_num", FALSE)
				CALL DIALOG.SetFieldActive("period_num", FALSE)
				CALL DIALOG.SetFieldActive("jour_code", FALSE)
				CALL DIALOG.SetFieldActive("jour_num", FALSE)
				CALL DIALOG.SetFieldActive("jour_date", FALSE)
				CALL DIALOG.SetFieldActive("credit_amt", FALSE)
				CALL DIALOG.SetFieldActive("debit_amt", FALSE)
				CALL DIALOG.SetFieldActive("com1_text", FALSE)

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_arr_curr = arr_curr() 

			ON ACTION ("POST BATCH") 	# Post the batch of THIS line
				LET glob_counter = 0 
				LET glob_fisc_period_num = modu_arr_rec_period[l_arr_curr].period_num 
				LET glob_fisc_year_num = modu_arr_rec_period[l_arr_curr].year_num 
				
				WHENEVER SQLERROR CONTINUE
				INSERT INTO list_of_batches_to_post VALUES (glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,modu_arr_rec_period[l_arr_curr].jour_code,modu_arr_rec_period[l_arr_curr].jour_num)
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				CASE
					WHEN sqlca.sqlcode = 0   #OK
					WHEN sqlca.sqlcode = -239    # record is already insert)
					OTHERWISE
						ERROR "INsert into batch list FAILED with errors!"
						RETURN 0
				END CASE
								
				CALL post_non_posted_batches(l_batchhead_filters_clause) 
				RETURNING l_operation_status
								
				IF glob_counter > 0 THEN 
					LET l_run_arg = "POST_RUN_NUM=", trim(modu_rec_postrun.post_run_num) 
					CALL run_prog("GB7",l_run_arg,"","","") 					
				END IF
				
				# Check if remaining batches to post
				CALL crs_choose_periods.Close()
				CALL crs_choose_periods.Open(glob_rec_kandoouser.cmpy_code)
				LET l_idx = 1 
				CALL modu_arr_rec_period.clear()
		
				WHILE crs_choose_periods.FetchNext (modu_arr_rec_period[l_idx].year_num,modu_arr_rec_period[l_idx].period_num) = 0
					LET l_idx = l_idx + 1 
				END WHILE
				CALL modu_arr_rec_period.DeleteElement(l_idx)   # delete last element which is empty
				LET l_idx = l_idx -1

				CALL modu_arr_rec_posting_report.clear() #reset report for next possible batch post job
				LET modu_rep_idx = 0

			ON ACTION "DETAILS" --view batch details - RUN g26			#ON KEY (F5) --View Batch Details - run G26
				IF (l_arr_curr > 0) OR (modu_arr_rec_period.getlength() > 0 ) THEN #don't do anything FOR empty arrays 
					IF modu_arr_rec_period[l_arr_curr].year_num IS NOT NULL	OR modu_arr_rec_period[l_arr_curr].period_num IS NOT NULL THEN 

						# SQL is going to be used as an argument for a program argument RUN - (reason for the \\\)
						# CALL run_prog("G26",l_query_text,"","","")
						#               LET l_query_text =
						#                       " SELECT * FROM batchhead ",
						#                       " WHERE cmpy_code = \\\"",glob_rec_kandoouser.cmpy_code,"\\\" ",
						#                       " AND year_num = ", trim(modu_arr_rec_period[l_arr_curr].year_num),
						#                       " AND period_num = ",trim(modu_arr_rec_period[l_arr_curr].period_num),
						#                       " AND post_flag = \\\"N\\\" ",
						#                       " ORDER BY jour_code, jour_num "

						LET l_query_text = 
							" SELECT * FROM batchhead ", 
							" WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code),"' ", 
							" AND year_num = ", trim(modu_arr_rec_period[l_arr_curr].year_num), 
							" AND period_num = ", trim(modu_arr_rec_period[l_arr_curr].period_num), 
							" AND post_flag = 'N' ", 
							" ORDER BY jour_code, jour_num " 

						#huho - change to url argument support
						IF l_query_text IS NOT NULL THEN 
							LET l_query_text = "\"QUERY_TEXT=", trim(l_query_text), " \" " 
						END IF 

						MESSAGE "Launching G26" 
						CALL run_prog("G26",l_query_text,"","","") 
					END IF 
				END IF 

				ON CHANGE "do_post"
					IF modu_arr_rec_period[l_arr_curr].do_post = FALSE THEN
						LET modu_arr_rec_period[l_arr_curr].jour_status = "Do no post"
					ELSE
						LET modu_arr_rec_period[l_arr_curr].jour_status = "To be posted"
					END IF
					DISPLAY modu_arr_rec_period[l_arr_curr].jour_status TO sr_period[l_arr_curr].jour_status
					CALL ui.Interface.refresh()
		END INPUT #----------------------------- 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			EXIT WHILE
		END IF 
		LET l_batches_number = 0
		FOR l_idx = 1 TO modu_arr_rec_period.GetSize()
			IF modu_arr_rec_period[l_idx].do_post = TRUE THEN
				WHENEVER SQLERROR CONTINUE
				INSERT INTO list_of_batches_to_post VALUES (glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,modu_arr_rec_period[l_idx].jour_code,modu_arr_rec_period[l_idx].jour_num)
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
				CASE
					WHEN sqlca.sqlcode = 0   #OK
						LET l_batches_number = l_batches_number + 1
					WHEN sqlca.sqlcode = -239    # record is already insert)
						LET l_batches_number = l_batches_number + 1
					OTHERWISE
						ERROR "Insert into batch list FAILED with errors!"
						CONTINUE FOR
				END CASE
			END IF
		END FOR

		--IF l_batches_number > 0 THEN
			--CALL post_non_posted_batches(l_batchhead_filters_clause) 
			--RETURNING l_operation_status
		--ELSE
			--EXIT WHILE
		--END IF
		LET l_count_batches_to_post = 0
	END WHILE 


	CLOSE WINDOW G155 

END FUNCTION  # construct_dataset_periods_to_post

###########################################################################
# FUNCTION post_non_posted_batches()
#
# l_status_ind
#    = 1     Continue... Not Multiledger OR already resolved
#    = 2     Unable TO resolve Multi-Ledger relationships
#    = 3     Undefined Multi-Ledger relationships
#    = 4     Multi-Ledger Coa NOT foundor OPEN
#    = 5     Exchange Rate NOT found FOR reporting currency
#    = 6     Insert INTO batchdetl failed
#    = 7     Coa NOT found OR NOT OPEN
#    = 8     **Multi-Ledger** DEBITS     (Process Multi-Ledger)
#    = 9     **Multi-Ledger** CREDITS    (Process Multi-Ledger)
###########################################################################
FUNCTION post_non_posted_batches(p_batchhead_filters_clause)
	DEFINE p_batchhead_filters_clause STRING
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE p_jour_code LIKE batchhead.jour_code
	DEFINE p_jour_num LIKE batchhead.jour_num
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_status_ind SMALLINT 
	DEFINE multiledger_ind SMALLINT 
	DEFINE currency_error SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_operation_status INTEGER
	DEFINE l_batch_post_status INTEGER
	DEFINE l_number_of_batches_to_post INTEGER
	DEFINE crs_main_batchhead CURSOR
--	DEFINE l_idx int 

	LET currency_error = false 
	LET modu_rec_postrun.post_amt = 0 
	
	# upd_postrun cursor for update replaced by read in repeatable read
	-- DECLARE upd_postrun CURSOR FOR 

	#----------------------------------------------
	# Note use of 'with hold' as transaction IS committed TO the database
	# AT the END of each batch
	# the selected batch list has been build in the construct_dataset function
	-- DECLARE upd_batc_curs CURSOR with HOLD FOR 
	-- INTO l_rec_batchhead.* 
	LET l_query_text = 	"SELECT h.* ", 
	" FROM batchhead h, list_of_batches_to_post l ",
	" WHERE h.cmpy_code = l.cmpy_code ",
	" AND h.jour_code = l.jour_code ",
	" AND h.jour_num = l.jour_num ",
	p_batchhead_filters_clause,
	" AND sign_on_code = ? ",
	"ORDER BY h.year_num,h.period_num,h.jour_code,h.jour_num"

	CALL modu_arr_rec_period.Clear()   # clear the main array, we use it to display operation progress and status
	CALL crs_main_batchhead.Declare(l_query_text,0,1)   # 0: no scroll,1:with hold
	#  cursor for update gone: we are in repeatable read

	--DECLARE detlcurs CURSOR FOR 
	--INTO l_rec_batchdetl.*
	LET l_query_text = "SELECT * FROM batchdetl d ", 
	" WHERE d.cmpy_code = ? ",
	" AND d.jour_code = ? ",
	" AND d.jour_num = ? "
	CALL mdl_crs_batchdetl.Declare(l_query_text)

	LET multiledger_ind = 1 
	SELECT count(*) INTO l_number_of_batches_to_post
	FROM list_of_batches_to_post 
	
	SELECT * 
	INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = "L" 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET multiledger_ind = 0 
	END IF 

	SELECT * INTO modu_rec_glparms.* 
	FROM glparms  
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1"
	# IF first time ever SET up next_post_num check initial value and eventually set them 
	IF modu_rec_glparms.next_post_num IS NULL OR modu_rec_glparms.next_post_num = 0 THEN 
		LET modu_rec_glparms.next_post_num = 1 
		UPDATE glparms 
		SET next_post_num = modu_rec_glparms.next_post_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
	END IF 

	IF modu_rec_glparms.post_total_amt IS NULL THEN 
		SELECT sum(debit_amt) INTO modu_rec_glparms.post_total_amt FROM account # IF no post has been done, set post_total_amt to zero
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF modu_rec_glparms.post_total_amt IS NULL THEN 
			LET modu_rec_glparms.post_total_amt = 0 
		END IF 

		UPDATE glparms 
		SET post_total_amt = modu_rec_glparms.post_total_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 

	END IF 

	LET glob_counter = 0 

	
	--OPEN upd_batc_curs 
	CALL crs_main_batchhead.Open(glob_rec_glparms.base_currency_code,glob_rec_glparms.base_currency_code,glob_rec_kandoouser.sign_on_code)

	CALL modu_arr_rec_posting_report.clear() #array RECORD TO keep information ON what batches were posted (for the user TO read) 
	LET modu_rep_idx = 0  #report array index 

	
	BEGIN WORK
	# Post starts here, we go REPEATABLE READ ISOLATION MODE ( any record read by this session from now on cannot by updated/deleted by another session
	SET ISOLATION TO REPEATABLE READ
	# read glparms after eventual set of values and put a RR lock on it
	SELECT * INTO modu_rec_glparms.* 
	FROM glparms  
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1"
	
	EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"	# all constraints will be checked at commit time, not before 
	WHILE crs_main_batchhead.FetchNext(l_rec_batchhead.*,glob_rec_kandoouser.sign_on_code)	= 0	# main cursor on batchhead
		IF sqlca.sqlcode < 0 THEN
			ERROR "There is a problem"
			ROLLBACK WORK
			EXIT WHILE
		END IF
		# only possible value for sqlca.sqlcode is 0: we continue OK
		
		# Read the GLPARMS record so that it gets a share lock to prevent other sessions to update it
		SELECT * INTO modu_rec_glparms.* 
		FROM glparms  
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1"
	
		LET glob_fisc_period_num = l_rec_batchhead.period_num
		LET glob_fisc_year_num = l_rec_batchhead.year_num

		
		LET modu_rep_idx = modu_rep_idx + 1 
		MESSAGE "Posting Journal ", trim(l_rec_batchhead.jour_code), " Batch ", trim(l_rec_batchhead.jour_num) # DISPLAY " Posting Journal: ", l_rec_batchhead.jour_code TO lblabel1 -- 1,2 

		# Status display
		LET modu_arr_rec_period[modu_rep_idx].do_post = TRUE
		LET modu_arr_rec_period[modu_rep_idx].year_num = l_rec_batchhead.year_num
		LET modu_arr_rec_period[modu_rep_idx].period_num = l_rec_batchhead.period_num
		LET modu_arr_rec_period[modu_rep_idx].jour_code = l_rec_batchhead.jour_code
		LET modu_arr_rec_period[modu_rep_idx].jour_num = l_rec_batchhead.jour_num
		LET modu_arr_rec_period[modu_rep_idx].jour_date = l_rec_batchhead.jour_date
		LET modu_arr_rec_period[modu_rep_idx].jour_status = 'Pending...'
		LET modu_arr_rec_period[modu_rep_idx].com1_text = l_rec_batchhead.com1_text
		DISPLAY modu_arr_rec_period[modu_rep_idx].* TO sr_period[modu_rep_idx].*
		CALL ui.Interface.refresh()

		LET modu_arr_rec_posting_report[modu_rep_idx].jour_code = trim(l_rec_batchhead.jour_code) 
		LET modu_arr_rec_posting_report[modu_rep_idx].jour_num = trim(l_rec_batchhead.jour_num) 

--		MESSAGE "Batch: ", trim(l_rec_batchhead.jour_num)
--		SLEEP 3 #display " Batch: " TO lblabel1 -- 2,2 
		#DISPLAY "           Batch: ", l_rec_batchhead.jour_num TO lbLabel1 -- 2,2
		
		DELETE FROM t_multiledg WHERE 1=1 
		LET glob_counter = glob_counter + 1 
		LET glob_entries_for_batch = 0 
		LET glob_total_debit = 0 
		LET glob_total_credit = 0 

		# open cursor on batchdetl for this jour_code,jour_num
		CALL mdl_crs_batchdetl.Open(glob_rec_kandoouser.cmpy_code,l_rec_batchhead.jour_code,l_rec_batchhead.jour_num)

--		FOREACH detlcurs INTO l_rec_batchdetl.* 
		WHILE mdl_crs_batchdetl.FetchNext(l_rec_batchdetl.*) = 0
			LET l_status_ind = validate_account(l_rec_batchdetl.acct_code,l_rec_batchhead.*) 
			LET modu_arr_rec_posting_report[modu_rep_idx].posting_status = l_status_ind #user REPORT 

			#report -> batch posted or not posted
			IF l_status_ind = 0 THEN 
				LET modu_arr_rec_posting_report[modu_rep_idx].post_flag = true #user REPORT -> posted 
			ELSE 
				LET modu_arr_rec_posting_report[modu_rep_idx].post_flag = false #user REPORT -> NOT posted 
			END IF 

			LET modu_arr_rec_posting_report[modu_rep_idx].period_num = glob_fisc_period_num 
			LET modu_arr_rec_posting_report[modu_rep_idx].year_num = glob_fisc_year_num 

			IF l_status_ind = 7 THEN # 7 coa NOT found OR NOT OPEN
				ROLLBACK WORK
				EXIT WHILE  
				--GOTO recovery 
			END IF 

			CALL fix_null_values(l_rec_batchdetl.*) RETURNING l_rec_batchdetl.*
			IF multiledger_ind THEN 
				CALL setup_multi_ledger(l_rec_structure.*) 
			END IF 

			CALL post_accountledger(l_rec_batchdetl.*) RETURNING l_operation_status
			IF l_operation_status < 0 THEN
				LET l_batch_post_status = -1
				ROLLBACK WORK
				EXIT WHILE
			END IF
			
			CALL post_account(l_rec_batchdetl.*,l_rec_batchhead.year_num) RETURNING l_operation_status 
			IF l_operation_status < 0 THEN
				LET l_batch_post_status = -2
				ROLLBACK WORK
				EXIT WHILE
			END IF
			
			CALL post_accounthist(l_rec_batchdetl.*,l_rec_batchhead.year_num,l_rec_batchhead.period_num) RETURNING l_operation_status
			IF l_operation_status < 0 THEN
				LET l_batch_post_status = -3
				ROLLBACK WORK
				EXIT WHILE
			END IF

			IF modu_rec_glparms.use_currency_flag = "Y" THEN 
				CALL post_accountcur(l_rec_batchdetl.*,l_rec_batchhead.year_num,l_rec_batchhead.currency_code) RETURNING l_operation_status
				IF l_operation_status < 0 THEN
					LET l_batch_post_status = -4
					ROLLBACK WORK
					EXIT WHILE
				END IF

				CALL post_accounthistcur(l_rec_batchdetl.*,l_rec_batchhead.year_num,l_rec_batchhead.period_num,l_rec_batchhead.currency_code) RETURNING l_operation_status
				IF l_operation_status < 0 THEN
					LET l_batch_post_status = -5
					ROLLBACK WORK
					EXIT WHILE
				END IF
			END IF 

			LET glob_total_debit = glob_total_debit + l_rec_batchdetl.debit_amt 
			LET modu_arr_rec_posting_report[modu_rep_idx].total_debit = glob_total_debit #user REPORT 

			LET glob_total_credit = glob_total_credit + l_rec_batchdetl.credit_amt 
			LET modu_arr_rec_posting_report[modu_rep_idx].total_credit = glob_total_credit #user REPORT 

			LET modu_rec_postrun.post_amt = modu_rec_postrun.post_amt + l_rec_batchdetl.debit_amt 
			LET modu_arr_rec_posting_report[modu_rep_idx].post_amt = modu_rec_postrun.post_amt #user REPORT 

		END WHILE # mdl_crs_batchdetl.FetchNext

		#
		IF multiledger_ind THEN 
			LET l_status_ind = get_multiledger_status() 

			IF l_status_ind = 2 THEN # 2 unable TO resolve ml rel's 
				ROLLBACK WORK
				EXIT WHILE
				--GOTO recovery 
			END IF 

			IF l_status_ind = 8 THEN # 8 working with debits 
				CALL insert_new_debits(l_status_ind,l_rec_batchhead.jour_code,l_rec_batchhead.jour_num,l_rec_batchhead.seq_num)  RETURNING l_status_ind
				IF l_status_ind = 3 
				OR l_status_ind = 4 
				OR l_status_ind = 5 
				OR l_status_ind = 6 THEN 
					LET l_batch_post_status = -6
					ROLLBACK WORK
					EXIT WHILE
				END IF
			END IF 

			IF l_status_ind = 9 THEN # 9 working with credits 
				CALL insert_new_credits(l_status_ind,l_rec_batchhead.jour_code,l_rec_batchhead.jour_num,l_rec_batchhead.seq_num) RETURNING l_status_ind
				IF l_status_ind = 3 
				OR l_status_ind = 4 
				OR l_status_ind = 5 
				OR l_status_ind = 6 THEN 
					LET l_batch_post_status = -7
					ROLLBACK WORK
					EXIT WHILE
				END IF
			END IF 
		END IF 

		#
		IF glob_total_debit != l_rec_batchhead.debit_amt THEN 
			LET glob_err_message = " Batch ", l_rec_batchhead.jour_num USING "<<<<<<<<", " header NOT = TO sum of lines in debits " 			
			ERROR kandoomsg2("G",7021,glob_err_message)
			ROLLBACK WORK
			EXIT while 
		END IF
		 
		IF glob_total_credit != l_rec_batchhead.credit_amt THEN 
			LET glob_err_message = " Batch ", l_rec_batchhead.jour_num USING "<<<<<<<<", " header <> sum of lines in credits " 
			ERROR kandoomsg2("G",7021,glob_err_message)
			ROLLBACK WORK
			exit while 
		END IF
		 
		LET glob_run_total = glob_run_total + l_rec_batchhead.debit_amt 
		# The batch is set as "POSTED"
		LET l_rec_batchhead.post_flag = "Y" 
		
		WHENEVER SQLERROR CONTINUE
		CALL mdl_prp_upd_main_batchhead.Execute(
			l_rec_batchhead.post_flag,
			modu_rec_glparms.next_post_num,
			l_rec_batchhead.seq_num, 
			l_rec_batchhead.debit_amt,
			l_rec_batchhead.credit_amt,
			l_rec_batchhead.control_amt,
			l_rec_batchhead.for_debit_amt,
			l_rec_batchhead.for_credit_amt,
			glob_rec_kandoouser.cmpy_code,
			l_rec_batchhead.jour_code,
			l_rec_batchhead.jour_num)
		
		IF sqlca.sqlcode < 0 THEN
			ERROR "Batch update has FAILED with errors!"
			ROLLBACK WORK
			EXIT WHILE
		END IF
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		# now write out the postrun row
		IF glob_counter = 1 THEN 
			LET modu_rec_postrun.cmpy_code =  glob_rec_kandoouser.cmpy_code
			LET modu_rec_postrun.post_run_num = modu_rec_glparms.next_post_num 
			LET modu_rec_postrun.post_date = today 
			LET modu_rec_postrun.post_by_text = glob_rec_kandoouser.sign_on_code 
			LET modu_rec_postrun.start_total_amt = modu_rec_glparms.post_total_amt 
			LET modu_rec_postrun.end_total_amt = modu_rec_postrun.start_total_amt +	modu_rec_postrun.post_amt 
			CALL mdl_prp_ins_postrun.Execute(modu_rec_postrun.*)
		ELSE 
			LET modu_rec_postrun.end_total_amt = modu_rec_postrun.start_total_amt +	modu_rec_postrun.post_amt 
			CALL mdl_prp_upd_postrun.Execute(modu_rec_postrun.post_amt,modu_rec_postrun.end_total_amt,glob_rec_kandoouser.cmpy_code,modu_rec_glparms.next_post_num)
		END IF
		
		WHENEVER SQLERROR CONTINUE
		UPDATE glparms 
		SET	post_total_amt = modu_rec_postrun.end_total_amt, 
			next_post_num = modu_rec_postrun.post_run_num + 1, 
			last_post_date = today, 
			next_seq_num = modu_rec_glparms.next_seq_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1"
		 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		# Delete this batch from the list of batches to proceed
		WHENEVER SQLERROR CONTINUE
		DELETE FROM list_of_batches_to_post 
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			AND jour_code = l_rec_batchhead.jour_code
			AND jour_num = l_rec_batchhead.jour_num
		
		LET modu_arr_rec_period[modu_rep_idx].credit_amt = 	l_rec_batchhead.credit_amt
		LET modu_arr_rec_period[modu_rep_idx].debit_amt = 	l_rec_batchhead.debit_amt
		IF NOT do_in_one_transaction THEN     # i.e we commit batch by batch
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF sqlca.sqlcode = 0 THEN
				COMMIT WORK			# COMMIT can fail, we have to test
				IF sqlca.sqlcode = 0 THEN
					LET modu_arr_rec_period[modu_rep_idx].jour_status = "Post ok"
					IF modu_rep_idx <  l_number_of_batches_to_post  THEN # there are more batches to post so we immediately start a new transaction
						BEGIN WORK 
					END IF
				ELSE
					LET modu_arr_rec_period[modu_rep_idx].jour_status = "POST KO:integr)"
				END IF
			ELSE
				LET modu_arr_rec_period[modu_rep_idx].jour_status = "POST KO"
				ROLLBACK WORK
			END IF
		ELSE 
			LET modu_arr_rec_period[modu_rep_idx].jour_status = "Ready for commit"
		END IF
		DISPLAY modu_arr_rec_period[modu_rep_idx].* TO sr_period[modu_rep_idx].*
		CALL ui.Interface.refresh()
	END WHILE  # mdl_crs_batchhead

	IF do_in_one_transaction THEN     # i.e we commit everything
		COMMIT WORK			# COMMIT can fail, we have to test
		IF sqlca.sqlcode = 0 THEN
			# look at all batches and set as OK
			FOR modu_rep_idx=1 TO modu_arr_rec_period.GetSize()
				LET modu_arr_rec_period[modu_rep_idx].jour_status = "Post ok"
				DISPLAY modu_arr_rec_period[modu_rep_idx].* TO sr_period[modu_rep_idx].*
			END FOR
		ELSE
			ROLLBACK WORK
			FOR modu_rep_idx=1 TO modu_arr_rec_period.GetSize()
				LET modu_arr_rec_period[modu_rep_idx].jour_status = "POST KO:integr)"
				DISPLAY modu_arr_rec_period[modu_rep_idx].* TO sr_period[modu_rep_idx].*
			END FOR
		END IF
		CALL ui.Interface.refresh()
	END IF
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	# DISPLAY a warning of foreign currency batches found unexpectedly
	IF currency_error THEN 
		ERROR kandoomsg2("G",9092,"") 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

--	#Final Batch Post report for the operator
--	OPEN WINDOW wbatchpostreport with FORM "G159" 

--	DISPLAY modu_arr_rec_posting_report.getlength() TO batch_count 
--	DISPLAY ARRAY modu_arr_rec_posting_report TO sr_batchreport.* ATTRIBUTE(UNBUFFERED) 

--	CLOSE WINDOW wbatchpostreport 

END FUNCTION  # post_non_posted_batches

###########################################################################
# FUNCTION get_journal_numbers_to_post()
#
# User can specify if all Journal numbers will be posted or only a range (start and end journal number)
###########################################################################
FUNCTION get_journal_numbers_to_post() 
	DEFINE l_ret_status BOOLEAN
	DEFINE l_start_journum,l_end_journum INTEGER

	OPEN WINDOW G548 with FORM "G548" 
	CALL windecoration_g("G548") 

	MESSAGE kandoomsg2("G",1079,"") 
	LET l_start_journum = NULL 
	LET l_end_journum = NULL 

	INPUT l_start_journum, l_end_journum WITHOUT DEFAULTS FROM start_no, end_no ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GP2","inp-start-end") 

		AFTER FIELD start_no 
			IF l_start_journum IS NULL THEN 
				LET l_start_journum = 0 
				LET l_end_journum = 999999999 
			ELSE 
				IF NOT dialog.getFieldTouched("end_no") THEN #if user has NOT already entered data in ending journal number... auto fill 
					LET l_end_journum = l_start_journum 
				END IF 
			END IF 

		AFTER FIELD end_no 
			IF l_end_journum IS NULL 
			AND l_start_journum IS NOT NULL THEN 
				LET l_end_journum = "999999999" --huho changed FROM LET l_end_journum = "9999999999" 
			END IF 

			IF l_end_journum < l_start_journum THEN 
				ERROR "Ending Journal Number can not be lower than Starting Journal number" 
				LET l_start_journum = l_end_journum 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_status = FALSE
	ELSE
		LET l_ret_status = TRUE	 
	END IF 

	CLOSE WINDOW G548 

	RETURN l_ret_status,l_start_journum,l_end_journum
END FUNCTION # get_journal_numbers_to_post

###########################################################################
# FUNCTION insert_accounthist()
# IF accounthist does not exist for this year/periods/account, then create 1 row per period for this year
# with initialized values
#
###########################################################################
FUNCTION insert_accounthist(p_cmpy_code,p_acct_code,p_year_num) 
	DEFINE p_cmpy_code LIKE accounthist.cmpy_code
	DEFINE p_acct_code LIKE accounthist.acct_code
	DEFINE p_year_num LIKE accounthist.year_num
	DEFINE l_period_num LIKE period.period_num
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*

	CALL mdl_crs_accounthist_check.Open(p_cmpy_code,p_year_num,p_cmpy_code,p_acct_code,p_year_num)

	WHILE mdl_crs_accounthist_check.FetchNext(l_period_num) = 0
		LET l_rec_accounthist.cmpy_code = p_cmpy_code
		LET l_rec_accounthist.acct_code = p_acct_code 
		LET l_rec_accounthist.year_num = p_year_num 
		LET l_rec_accounthist.period_num = l_period_num 
		LET l_rec_accounthist.open_amt = 0 
		LET l_rec_accounthist.debit_amt = 0 
		LET l_rec_accounthist.credit_amt = 0 
		LET l_rec_accounthist.close_amt = 0 
		LET l_rec_accounthist.pre_close_amt = 0 
		LET l_rec_accounthist.budg1_amt = 0 
		LET l_rec_accounthist.budg2_amt = 0 
		LET l_rec_accounthist.budg3_amt = 0 
		LET l_rec_accounthist.budg4_amt = 0 
		LET l_rec_accounthist.budg5_amt = 0 
		LET l_rec_accounthist.budg6_amt = 0 
		LET l_rec_accounthist.stats_qty = 0 
		LET l_rec_accounthist.ytd_pre_close_amt = 0 
		LET l_rec_accounthist.hist_flag = "N" 
		LET l_rec_accounthist.ytd_budg1_amt = 0 
		LET l_rec_accounthist.ytd_budg2_amt = 0 
		LET l_rec_accounthist.ytd_budg3_amt = 0 
		LET l_rec_accounthist.ytd_budg4_amt = 0 
		LET l_rec_accounthist.ytd_budg5_amt = 0 
		LET l_rec_accounthist.ytd_budg6_amt = 0 
		LET glob_err_message = "History INSERT: ", l_rec_accounthist.acct_code
		
		CALL mdl_prp_ins_accounthist.Execute(l_rec_accounthist.*)
		--INSERT INTO accounthist VALUES (l_rec_accounthist.*)
		 
	END WHILE 

END FUNCTION # insert_accounthist

###########################################################################
# FUNCTION insert_accounthistcur()
# insert blank records for accounthistcur ofr year period if not existing
#
###########################################################################
FUNCTION insert_accounthistcur(p_cmpy_code,p_acct_code,p_year_num,p_currency_code) 
	DEFINE p_cmpy_code LIKE accounthist.cmpy_code
	DEFINE p_acct_code LIKE accounthist.acct_code
	DEFINE p_year_num LIKE accounthist.year_num
	DEFINE p_currency_code LIKE accounthistcur.currency_code
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.*

	DECLARE mdl_crs_accounthistcur_check CURSOR FOR 
	SELECT period.* INTO l_rec_period.* 
	FROM period 
	WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period.year_num = p_year_num 
	AND period.period_num NOT in 
		(select period_num FROM accounthistcur 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = p_acct_code 
		AND year_num = p_year_num 
		AND currency_code = p_currency_code) 

	FOREACH mdl_crs_accounthistcur_check 
		LET l_rec_accounthistcur.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_accounthistcur.acct_code = p_acct_code 
		LET l_rec_accounthistcur.year_num = p_year_num 
		LET l_rec_accounthistcur.period_num = l_rec_period.period_num 
		LET l_rec_accounthistcur.currency_code = p_currency_code 
		LET l_rec_accounthistcur.open_amt = 0 
		LET l_rec_accounthistcur.debit_amt = 0 
		LET l_rec_accounthistcur.credit_amt = 0 
		LET l_rec_accounthistcur.close_amt = 0 
		LET l_rec_accounthistcur.base_open_amt = 0 
		LET l_rec_accounthistcur.base_debit_amt = 0 
		LET l_rec_accounthistcur.base_credit_amt = 0 
		LET l_rec_accounthistcur.base_close_amt = 0 
		LET l_rec_accounthistcur.pre_close_amt = 0 
		LET l_rec_accounthistcur.ytd_pre_close_amt = 0 
		LET glob_err_message = "History INSERT: ", l_rec_accounthistcur.acct_code 

		INSERT INTO accounthistcur VALUES (l_rec_accounthistcur.*) 

	END FOREACH 

END FUNCTION  # insert_accounthistcur

###########################################################################
# FUNCTION validate_account()
#
#
###########################################################################
FUNCTION validate_account(p_acct_code,p_rec_batchhead) 
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE p_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_status_ind SMALLINT 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_err_message STRING

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_acct_code 

	IF sqlca.sqlcode = 100 THEN # impossible due to referential integrity in Kandoo:will never happen
		LET l_err_message = 
			"Batch ", p_rec_batchhead.jour_num USING "<<<<<<<<", 
			" Acct ", p_acct_code clipped, 
			" NOT FOUND " 
		
		LET l_status_ind = 7 #reject 
		ERROR kandoomsg2("G",9031,"")		#9031 Account NOT found
	ELSE 
		#----------------------------------------------------
		# check that account IS OPEN FOR year AND period
		IF ((( l_rec_coa.end_year_num < p_rec_batchhead.year_num) OR 
		(l_rec_coa.end_year_num = p_rec_batchhead.year_num AND 
		l_rec_coa.end_period_num < p_rec_batchhead.period_num)) OR 
		((l_rec_coa.start_year_num > p_rec_batchhead.year_num) OR 
		(l_rec_coa.start_year_num = p_rec_batchhead.year_num AND 
		l_rec_coa.start_period_num > p_rec_batchhead.period_num))) THEN 
			LET l_err_message = "Batch ", p_rec_batchhead.jour_num USING "<<<<<<<<", " Acct ", p_acct_code clipped, " NOT OPEN " 
			LET l_status_ind = 7 #reject 
			ERROR kandoomsg2("G",9526," ")	#9526 Account NOT Open
		END IF 
	END IF 
	RETURN l_status_ind 
END FUNCTION # validate_account


###########################################################################
# FUNCTION fix_null_values()
#
#
###########################################################################
FUNCTION fix_null_values(p_rec_batchdetl) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	# FIXME: please pass argument and return values instead of using globals
	IF p_rec_batchdetl.stats_qty IS NULL THEN 
		LET p_rec_batchdetl.stats_qty = 0 
	END IF
	 
	IF p_rec_batchdetl.debit_amt IS NULL THEN 
		LET p_rec_batchdetl.debit_amt = 0 
	END IF
	 
	IF p_rec_batchdetl.credit_amt IS NULL THEN 
		LET p_rec_batchdetl.credit_amt = 0 
	END IF
	 
	IF p_rec_batchdetl.for_debit_amt IS NULL THEN 
		LET p_rec_batchdetl.for_debit_amt = 0 
	END IF
	 
	IF p_rec_batchdetl.for_credit_amt IS NULL THEN 
		LET p_rec_batchdetl.for_credit_amt = 0 
	END IF 
	RETURN p_rec_batchdetl.*
END FUNCTION 
###########################################################################
# END FUNCTION fix_null_values()
###########################################################################



###########################################################################
# FUNCTION setup_multi_ledger(l_rec_structure)
#
#
###########################################################################
FUNCTION setup_multi_ledger(p_rec_structure,p_acct_code,p_rec_batchdetl) 
	DEFINE p_rec_structure RECORD LIKE structure.* 
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_flex1_code LIKE validflex.flex_code 
	DEFINE l_start_num SMALLINT 
	DEFINE l_length SMALLINT 

	LET l_start_num = p_rec_structure.start_num 
	LET l_length = p_rec_structure.start_num + p_rec_structure.length_num	- 1 
	LET l_flex1_code = p_acct_code[l_start_num,l_length] 

	UPDATE t_multiledg SET 
		debit_amt = debit_amt	+ p_rec_batchdetl.debit_amt, 
		credit_amt = credit_amt	+ p_rec_batchdetl.credit_amt, 
		for_debit_amt = for_debit_amt	+ p_rec_batchdetl.for_debit_amt, 
		for_credit_amt = for_credit_amt	+ p_rec_batchdetl.for_credit_amt 
	WHERE flex_code = l_flex1_code 

	IF sqlca.sqlcode = 0 AND sqlca.sqlerrd[3] = 0 THEN
		# zero row has been updated, we need to insert th row
		INSERT INTO t_multiledg VALUES (
			l_flex1_code, 
			p_rec_batchdetl.debit_amt, 
			p_rec_batchdetl.credit_amt, 
			p_rec_batchdetl.for_debit_amt, 
			p_rec_batchdetl.for_credit_amt)  
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION setup_multi_ledger(l_rec_structure)
###########################################################################


###########################################################################
# FUNCTION post_accountledger()
#
#
###########################################################################
FUNCTION post_accountledger(p_rec_batchdetl) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
--	DEFINE l_msg STRING 

	# Do NOT UPDATE the ledger with zero details
	# (this may be a stats only batch)
	IF p_rec_batchdetl.debit_amt != 0 OR p_rec_batchdetl.credit_amt != 0 THEN 	# Normally other case is impossible due to check constraints
		LET l_rec_accountledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_accountledger.acct_code = p_rec_batchdetl.acct_code 
		LET l_rec_accountledger.year_num = glob_fisc_year_num 
		LET l_rec_accountledger.period_num = glob_fisc_period_num 
		LET modu_rec_glparms.next_seq_num = modu_rec_glparms.next_seq_num + 1 
		LET l_rec_accountledger.seq_num = modu_rec_glparms.next_seq_num 
		LET l_rec_accountledger.jour_code = p_rec_batchdetl.jour_code 
		LET l_rec_accountledger.jour_num = p_rec_batchdetl.jour_num 
		LET l_rec_accountledger.jour_seq_num = p_rec_batchdetl.seq_num 
		LET l_rec_accountledger.tran_type_ind = p_rec_batchdetl.tran_type_ind 
		LET l_rec_accountledger.analysis_text = p_rec_batchdetl.analysis_text 
		LET l_rec_accountledger.tran_date = p_rec_batchdetl.tran_date 
		LET l_rec_accountledger.ref_text = p_rec_batchdetl.ref_text 
		LET l_rec_accountledger.ref_num = p_rec_batchdetl.ref_num 
		LET l_rec_accountledger.desc_text = p_rec_batchdetl.desc_text 
		LET l_rec_accountledger.stats_qty = p_rec_batchdetl.stats_qty 
		LET l_rec_accountledger.debit_amt = p_rec_batchdetl.debit_amt 
		LET l_rec_accountledger.credit_amt = p_rec_batchdetl.credit_amt 
		#
		LET l_rec_accountledger.currency_code = p_rec_batchdetl.currency_code 
		LET l_rec_accountledger.conv_qty = p_rec_batchdetl.conv_qty 
		LET l_rec_accountledger.for_debit_amt = p_rec_batchdetl.for_debit_amt 
		LET l_rec_accountledger.for_credit_amt = p_rec_batchdetl.for_credit_amt 

		IF get_debug() THEN 
			DISPLAY "l_rec_accountledger.acct_code=", l_rec_accountledger.acct_code 
			DISPLAY "l_rec_accountledger.seq_num=", l_rec_accountledger.seq_num 
			DISPLAY "l_rec_accountledger.jour_code=", l_rec_accountledger.jour_code 
			DISPLAY "l_rec_accountledger.jour_num=", l_rec_accountledger.jour_num 
			DISPLAY "l_rec_accountledger.debit_amt=", l_rec_accountledger.debit_amt 
			DISPLAY "l_rec_accountledger.credit_amt=", l_rec_accountledger.credit_amt 
			DISPLAY "l_rec_accountledger.for_debit_amt=", l_rec_accountledger.for_debit_amt 
			DISPLAY "l_rec_accountledger.for_credit_amt=", l_rec_accountledger.for_credit_amt 
			DISPLAY "--Report on post attempts --", trim(modu_rep_idx), "---------------------------------------------------------------------"
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].jour_code=", modu_arr_rec_posting_report[modu_rep_idx].jour_code
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].jour_num=", modu_arr_rec_posting_report[modu_rep_idx].jour_num
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].posting_status=", modu_arr_rec_posting_report[modu_rep_idx].posting_status
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].year_num=", modu_arr_rec_posting_report[modu_rep_idx].year_num
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].period_num=", modu_arr_rec_posting_report[modu_rep_idx].period_num
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].total_debit=", modu_arr_rec_posting_report[modu_rep_idx].total_debit
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].total_credit=", modu_arr_rec_posting_report[modu_rep_idx].total_credit
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].post_amt=", modu_arr_rec_posting_report[modu_rep_idx].post_amt
			DISPLAY "modu_arr_rec_posting_report[modu_rep_idx].post_flag=", modu_arr_rec_posting_report[modu_rep_idx].post_flag
		END IF 
		--WHENEVER SQLERROR CONTINUE
		CALL mdl_prp_ins_accountledger.Execute(l_rec_accountledger.*)
		--WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF sqlca.sqlcode < 0 THEN
			ERROR " Ledger post FAILED with errors!"
			ROLLBACK WORK
			RETURN sqlca.sqlcode
		ELSE 
			LET glob_entries_for_batch = glob_entries_for_batch + 1
			RETURN 0
		END IF
	END IF 
	RETURN 0
END FUNCTION 
###########################################################################
# END FUNCTION post_accountledger()
###########################################################################

############################################################
# FUNCTION post_account()
#
#
############################################################
FUNCTION post_account(p_rec_batchdetl,p_year_num) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_account RECORD LIKE account.*
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 
	DEFINE l_ac_rowid INTEGER 

	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 
	LET l_start_chart = l_rec_structure.start_num 
	LET l_end_chart = l_rec_structure.start_num	+ l_rec_structure.length_num	- 1 
	
	SELECT * INTO l_rec_account.* 
	FROM account 
	WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
	AND acct_code = p_rec_batchdetl.acct_code 
	AND year_num = p_year_num 
	CASE
		WHEN sqlca.sqlcode = 0		# account exists, just update aggregate data
			LET l_rec_account.bal_amt = l_rec_account.bal_amt + p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
			LET l_rec_account.debit_amt = l_rec_account.debit_amt + p_rec_batchdetl.debit_amt 
			LET l_rec_account.credit_amt = l_rec_account.credit_amt + p_rec_batchdetl.credit_amt 
			LET l_rec_account.stats_qty = l_rec_account.stats_qty + p_rec_batchdetl.stats_qty 
			
			IF p_rec_batchdetl.tran_type_ind != "CL" THEN 
				LET l_rec_account.ytd_pre_close_amt = l_rec_account.ytd_pre_close_amt + p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
			END IF 

			CALL mdl_prp_upd_account.Execute(l_rec_account.*,p_rec_batchdetl.cmpy_code,p_rec_batchdetl.acct_code,p_year_num)		
			IF sqlca.sqlcode = 0 THEN
				RETURN 0
			ELSE	
				ROLLBACK WORK
				RETURN sqlca.sqlcode
			END IF
		WHEN sqlca.sqlcode = NOTFOUND	# account does not exist yet, create a new record
			LET l_rec_account.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_account.acct_code = p_rec_batchdetl.acct_code 
			LET l_rec_account.year_num = p_year_num 
			LET l_rec_account.chart_code = p_rec_batchdetl.acct_code[l_start_chart,l_end_chart] 
			LET l_rec_account.open_amt = 0 
			LET l_rec_account.debit_amt = p_rec_batchdetl.debit_amt 
			LET l_rec_account.credit_amt = p_rec_batchdetl.credit_amt 
			LET l_rec_account.bal_amt = p_rec_batchdetl.debit_amt	- p_rec_batchdetl.credit_amt 
			LET l_rec_account.stats_qty = p_rec_batchdetl.stats_qty 
			LET l_rec_account.ytd_pre_close_amt = 0 
			LET l_rec_account.budg1_amt = 0 
			LET l_rec_account.budg2_amt = 0 
			LET l_rec_account.budg3_amt = 0 
			LET l_rec_account.budg4_amt = 0 
			LET l_rec_account.budg5_amt = 0 
			LET l_rec_account.budg6_amt = 0 

			IF p_rec_batchdetl.tran_type_ind != "CL" THEN 
				LET l_rec_account.ytd_pre_close_amt = p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
			END IF 
			
			LET glob_err_message = "Account INSERT: ", p_rec_batchdetl.acct_code 
			
			CALL mdl_prp_ins_account.Execute(l_rec_account.*)		
		-- INSERT INTO account VALUES (l_rec_account.*)
		OTHERWISE
			ERROR "Update account FAILED with errors"
			ROLLBACK WORK
			RETURN sqlca.sqlcode
	END CASE

END FUNCTION 
############################################################
# END FUNCTION post_account()
############################################################


############################################################
# FUNCTION post_accounthist()
#
#
############################################################
FUNCTION post_accounthist(p_rec_batchdetl,p_year_num,p_period_num) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_period_num LIKE batchhead.period_num
 
	SELECT * INTO l_rec_accounthist.* 
	FROM accounthist 
	WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
	AND acct_code = p_rec_batchdetl.acct_code 
	AND year_num = p_year_num
	AND period_num = p_period_num 
	
	WHILE TRUE
		CASE 
			WHEN sqlca.sqlcode = 0		# accounthist exists for this record
				LET l_rec_accounthist.debit_amt = l_rec_accounthist.debit_amt +	p_rec_batchdetl.debit_amt 
				LET l_rec_accounthist.credit_amt = l_rec_accounthist.credit_amt +	p_rec_batchdetl.credit_amt 
				LET l_rec_accounthist.stats_qty = l_rec_accounthist.stats_qty +	p_rec_batchdetl.stats_qty 
				LET l_rec_accounthist.close_amt = l_rec_accounthist.close_amt +	p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
				IF p_rec_batchdetl.tran_type_ind <> "CL" THEN 	
					LET l_rec_accounthist.ytd_pre_close_amt = l_rec_accounthist.ytd_pre_close_amt + p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt
					LET l_rec_accounthist.pre_close_amt = l_rec_accounthist.pre_close_amt + p_rec_batchdetl.debit_amt -	p_rec_batchdetl.credit_amt 
				END IF 
				CALL mdl_prp_upd_accounthist.Execute(l_rec_accounthist.*,p_rec_batchdetl.cmpy_code,p_rec_batchdetl.acct_code,p_year_num,p_period_num) 
				IF sqlca.sqlcode < 0 THEN
					ERROR "Update accounthist FAILED with errors!"
					ROLLBACK WORK
					EXIT WHILE
				ELSE
					EXIT WHILE
				END IF
	
			WHEN sqlca.sqlcode = NOTFOUND
				CALL insert_accounthist(p_rec_batchdetl.cmpy_code,p_rec_batchdetl.acct_code,p_year_num) 
				IF sqlca.sqlcode < 0 THEN
					ERROR "Insert accounthist FAILED with errors!"
					ROLLBACK WORK
					RETURN sqlca.sqlcode
				END IF
	
				# now SET it up again
				SELECT * INTO l_rec_accounthist.* 
				FROM accounthist 
				WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
				AND acct_code = p_rec_batchdetl.acct_code 
				AND year_num = p_year_num
				AND period_num = p_period_num 
				--RETURN sqlca.sqlcode
		END CASE
	END WHILE
	RETURN sqlca.sqlcode
END FUNCTION 	# post_accounthist


############################################################
# FUNCTION post_accountcur()
#
#
############################################################
FUNCTION post_accountcur(p_rec_batchdetl,p_year_num,p_currency_code) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_currency_code LIKE batchhead.currency_code
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_start_chart SMALLINT 
	DEFINE l_end_chart SMALLINT 
	DEFINE l_cac_rowid INTEGER 

	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 
	LET l_start_chart = l_rec_structure.start_num 
	LET l_end_chart = l_rec_structure.start_num	+ l_rec_structure.length_num	- 1 

	SELECT * INTO l_rec_accountcur.* 
	FROM accountcur 
	WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
	AND acct_code = p_rec_batchdetl.acct_code 
	AND year_num = p_year_num 
	AND currency_code = p_currency_code 

	CASE
		WHEN sqlca.sqlcode = 0
			LET l_rec_accountcur.bal_amt = l_rec_accountcur.bal_amt + p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 
			LET l_rec_accountcur.debit_amt = l_rec_accountcur.debit_amt	+ p_rec_batchdetl.for_debit_amt 
			LET l_rec_accountcur.credit_amt = l_rec_accountcur.credit_amt	+ p_rec_batchdetl.for_credit_amt 
			IF p_rec_batchdetl.tran_type_ind != "CL" THEN 
				LET l_rec_accountcur.ytd_pre_close_amt = l_rec_accountcur.ytd_pre_close_amt + p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 
			END IF 
			LET l_rec_accountcur.base_bal_amt = l_rec_accountcur.base_bal_amt + p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
			LET l_rec_accountcur.base_debit_amt = l_rec_accountcur.base_debit_amt + p_rec_batchdetl.debit_amt 
			LET l_rec_accountcur.base_credit_amt = l_rec_accountcur.base_credit_amt + p_rec_batchdetl.credit_amt 
			CALL mdl_prp_upd_accountcur.Execute(l_rec_accountcur.*,p_rec_batchdetl.cmpy_code,p_rec_batchdetl.acct_code,p_year_num,p_currency_code)
			IF sqlca.sqlcode < 0 THEN
				ROLLBACK WORK
				RETURN sqlca.sqlcode
			END IF

		WHEN sqlca.sqlcode = NOTFOUND 
			LET l_rec_accountcur.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_accountcur.acct_code = p_rec_batchdetl.acct_code 
			LET l_rec_accountcur.year_num = p_year_num 
			LET l_rec_accountcur.currency_code = p_currency_code 
			LET l_rec_accountcur.chart_code = p_rec_batchdetl.acct_code[l_start_chart, l_end_chart] 
			LET l_rec_accountcur.open_amt = 0 
			LET l_rec_accountcur.bal_amt = p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 
			LET l_rec_accountcur.debit_amt = p_rec_batchdetl.for_debit_amt 
			LET l_rec_accountcur.credit_amt = p_rec_batchdetl.for_credit_amt 
			LET l_rec_accountcur.base_open_amt = 0 
			LET l_rec_accountcur.base_bal_amt = p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
			LET l_rec_accountcur.base_debit_amt = p_rec_batchdetl.debit_amt 
			LET l_rec_accountcur.base_credit_amt = p_rec_batchdetl.credit_amt 
			LET l_rec_accountcur.ytd_pre_close_amt = 0 

			IF p_rec_batchdetl.tran_type_ind != "CL" THEN 
				LET l_rec_accountcur.ytd_pre_close_amt = p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 
			END IF 

			LET glob_err_message = "Account Curr INSERT: ", p_rec_batchdetl.acct_code 

			CALL mdl_prp_ins_accountcur.Execute(l_rec_accountcur.*)
			IF sqlca.sqlcode < 0 THEN
				ROLLBACK WORK
			END IF
			RETURN sqlca.sqlcode
	END CASE
END FUNCTION # post_accountcur

############################################################
# FUNCTION post_accounthistcur()
#
#
############################################################
FUNCTION post_accounthistcur(p_rec_batchdetl,p_year_num,p_period_num,p_currency_code) 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_period_num LIKE batchhead.period_num
	DEFINE p_currency_code LIKE batchhead.currency_code
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.*

	SELECT * INTO l_rec_accounthistcur.* 
	FROM accounthistcur 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_rec_batchdetl.acct_code 
	AND year_num = p_year_num 
	AND period_num = p_period_num 
	AND currency_code = p_currency_code 

	IF sqlca.sqlcode = NOTFOUND THEN
		CALL insert_accounthistcur(glob_rec_kandoouser.cmpy_code,p_rec_batchdetl.acct_code,p_year_num,p_currency_code) 
		#--------------------
		# now SET it up again
		SELECT * INTO l_rec_accounthistcur.* 
		FROM accounthistcur 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = p_rec_batchdetl.acct_code 
		AND year_num = p_year_num 
		AND period_num = p_period_num 
		AND currency_code = p_currency_code 
	END IF
	 
	LET l_rec_accounthistcur.debit_amt = l_rec_accounthistcur.debit_amt	+ p_rec_batchdetl.for_debit_amt 
	LET l_rec_accounthistcur.credit_amt = l_rec_accounthistcur.credit_amt	+ p_rec_batchdetl.for_credit_amt 
	LET l_rec_accounthistcur.close_amt = l_rec_accounthistcur.close_amt	+ p_rec_batchdetl.for_debit_amt	- p_rec_batchdetl.for_credit_amt 

	IF p_rec_batchdetl.tran_type_ind <> "CL" THEN 
		LET l_rec_accounthistcur.ytd_pre_close_amt = l_rec_accounthistcur.ytd_pre_close_amt + p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 

		LET l_rec_accounthistcur.pre_close_amt = l_rec_accounthistcur.pre_close_amt + p_rec_batchdetl.for_debit_amt - p_rec_batchdetl.for_credit_amt 
	END IF 

	LET l_rec_accounthistcur.base_close_amt =l_rec_accounthistcur.base_close_amt + p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt 
	LET l_rec_accounthistcur.base_debit_amt = l_rec_accounthistcur.base_debit_amt + p_rec_batchdetl.debit_amt 
	LET l_rec_accounthistcur.base_credit_amt = l_rec_accounthistcur.base_credit_amt	+ p_rec_batchdetl.credit_amt 

	CALL mdl_prp_upd_accounthistcur.Execute(l_rec_accounthistcur.*,glob_rec_kandoouser.cmpy_code,p_rec_batchdetl.acct_code,p_year_num,p_period_num,p_currency_code)
	IF sqlca.sqlcode < 0 THEN
		ROLLBACK WORK
	END IF
	RETURN sqlca.sqlcode
END FUNCTION  # post_accounthistcur

############################################################
# FUNCTION get_multiledger_status()
#
#
############################################################
FUNCTION get_multiledger_status() 
	DEFINE l_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_cred_amt LIKE batchdetl.debit_amt 

	DEFINE l_row_cnt SMALLINT 
	DEFINE l_debit_cnt SMALLINT 
	DEFINE l_credit_cnt SMALLINT 
	DEFINE l_status_ind SMALLINT 

	DEFINE l_flex_code LIKE validflex.flex_code 
	DEFINE l_ledg_debit LIKE batchdetl.debit_amt 
	DEFINE l_ledg_credit LIKE batchdetl.debit_amt 

--	SELECT unique 1 FROM t_multiledg 
--	IF sqlca.sqlcode = NOTFOUND THEN 
--		LET l_status_ind = 1 
		#no batchdetl's                      ==> PRINT group totals only
	--ELSE 
	SELECT count(*) INTO l_row_cnt 
	FROM t_multiledg 

	CASE
		WHEN l_row_cnt = 0
			LET l_status_ind = 1 
		WHEN l_row_cnt = 1 
			LET l_status_ind = 1 
			#only one unique flex_code        ==> ie NOT Multi-Ledger
		OTHERWISE
			SELECT nvl(sum(debit_amt),0),nvl(sum(credit_amt),0) INTO l_deb_amt,l_cred_amt
			FROM t_multiledg 

			IF l_deb_amt = 0 AND l_cred_amt = 0 THEN 
				LET l_status_ind = 1 
				#debits AND credits = zero     ==> PRINT group totals only
			ELSE 
				SELECT count(*) INTO l_debit_cnt 
				FROM t_multiledg 
				WHERE debit_amt > 0 
				SELECT count(*) INTO l_credit_cnt 
				FROM t_multiledg 
				WHERE credit_amt > 0
				 
				IF l_debit_cnt > 1 AND l_credit_cnt > 1 THEN 
					# IF debits equal credits FOR each ledger, no
					# relationships need TO be resolved
					DECLARE crs_multiledg_sums CURSOR FOR 
					SELECT flex_code, sum(debit_amt), sum(credit_amt) 
					FROM t_multiledg 
					GROUP BY 1 
					having sum(debit_amt) <> sum(credit_amt) 
					OPEN crs_multiledg_sums
					 
					FETCH crs_multiledg_sums INTO 
						l_flex_code, 
						l_ledg_debit, 
						l_ledg_credit 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_status_ind = 1 
					ELSE 
						LET l_status_ind = 2 
						LET glob_err_message = "Multi-Ledger relationships - Run gb8" 
						ERROR kandoomsg2("G",9212," ") 
					END IF 

					CLOSE crs_multiledg_sums 

				ELSE 

					IF l_debit_cnt = 1 THEN 
						LET l_status_ind = 8 
					ELSE 
						LET l_status_ind = 9 
					END IF 

				END IF 
			END IF 
		--END IF 
	END CASE 

	RETURN l_status_ind 
END FUNCTION # get_multiledger_status

############################################################
# FUNCTION insert_new_debits(p_status_ind)
#
#
############################################################
FUNCTION insert_new_debits(p_status_ind,p_jour_code,p_jour_num,p_seq_num) 
	DEFINE p_status_ind SMALLINT 
	DEFINE p_jour_code LIKE batchhead.jour_code
	DEFINE p_jour_num LIKE batchhead.jour_num
	DEFINE p_seq_num LIKE batchdetl.seq_num
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_cred_amt LIKE batchdetl.debit_amt 
	DEFINE l_for_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_for_cred_amt LIKE batchdetl.debit_amt 
	DEFINE l_flex1_code LIKE validflex.flex_code 
	DEFINE l_flex2_code LIKE validflex.flex_code 
	DEFINE l_acct_code LIKE ledgerreln.acct1_code 

	SELECT flex_code INTO l_flex1_code 
	FROM t_multiledg 
	WHERE debit_amt > 0 
	
	CALL mdl_crs_multiledg_credits.Open()

	WHILE mdl_crs_multiledg_credits.FetchNext(l_flex2_code) = 0
		IF l_flex1_code = l_flex2_code THEN 
			CONTINUE WHILE 
			#loop around TO get others
		END IF 
		SELECT * INTO l_rec_ledgerreln.* 
		FROM ledgerreln 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND flex1_code = l_flex1_code 
		AND flex2_code = l_flex2_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			SELECT * INTO l_rec_ledgerreln.* 
			FROM ledgerreln 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex1_code = l_flex2_code 
			AND flex2_code = l_flex1_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET glob_err_message = "Ledger ", l_flex1_code clipped, " AND ",	l_flex2_code clipped," - Run gb8" 
				LET p_status_ind = 3 
				ERROR kandoomsg2("G",9213," ")
				# FIXME: next line : where does acct_code come from ?
				--LET glob_err_message = trim(glob_err_message), "\njour_num=",trim(p_jour_num), " jour_code=", trim(p_jour_code), "\nseq_num=", trim(p_seq_num), " acct_code=", trim(p_acct_code)
				CALL fgl_winmessage("#9212 Undefined Relationships",glob_err_message,"error")	#9212 Undefined Relationships
				EXIT WHILE
			END IF 
		END IF 
		
		IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
			LET l_acct_code = l_rec_ledgerreln.acct1_code 
		ELSE 
			LET l_acct_code = l_rec_ledgerreln.acct2_code 
		END IF 
		
		LET l_deb_amt = 0 
		LET l_for_deb_amt = 0 
		
		SELECT sum(credit_amt) INTO l_cred_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 
		
		SELECT sum(for_credit_amt) INTO l_for_cred_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 
		
		LET p_seq_num = p_seq_num + 1
		--insert_batchdetl(p_next_seq,p_acct_code,p_credit_amt,p_debit_amt,p_for_credit_amt,p_for_debit_amt,p_jour_code,p_jour_num,p_year_num,p_period_num,p_status_ind,p_jour_date,p_currency_code,p_conv_qty)  
		LET p_status_ind = insert_batchdetl(
			p_seq_num,
			l_acct_code, 
			l_deb_amt,
			l_cred_amt,
			l_for_deb_amt, 
			l_for_cred_amt,
			p_status_ind) 
		
		IF p_status_ind = 4 
		OR p_status_ind = 5 
		OR p_status_ind = 6 THEN 
			EXIT WHILE 
		END IF
		 
		IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
			LET l_acct_code = l_rec_ledgerreln.acct2_code 
		ELSE 
			LET l_acct_code = l_rec_ledgerreln.acct1_code 
		END IF
		 
		LET l_cred_amt = 0 
		LET l_for_cred_amt = 0
		 
		SELECT sum(credit_amt) INTO l_deb_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 

		SELECT sum(for_credit_amt) INTO l_for_deb_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 
		LET p_seq_num = p_seq_num + 1 

		LET p_status_ind = insert_batchdetl(
			p_seq_num,
			l_acct_code, 
			l_deb_amt,
			l_cred_amt,
			l_for_deb_amt, 
			l_for_cred_amt,
			p_status_ind) 

		IF p_status_ind = 4 
		OR p_status_ind = 5 
		OR p_status_ind = 6 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	RETURN p_status_ind 
END FUNCTION  # insert_new_debits

############################################################
# FUNCTION insert_new_credits(p_status_ind)
#
#
############################################################
FUNCTION insert_new_credits(p_status_ind,p_jour_code,p_jour_num,p_seq_num) 
	DEFINE p_status_ind SMALLINT 
	DEFINE p_jour_code LIKE batchhead.jour_code
	DEFINE p_jour_num LIKE batchhead.jour_num
	DEFINE p_seq_num LIKE batchhead.seq_num
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_cred_amt LIKE batchdetl.debit_amt 
	DEFINE l_for_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_for_cred_amt LIKE batchdetl.debit_amt 
	DEFINE l_flex1_code LIKE validflex.flex_code 
	DEFINE l_flex2_code LIKE validflex.flex_code 
	DEFINE l_acct_code LIKE ledgerreln.acct1_code 

	SELECT flex_code INTO l_flex1_code FROM t_multiledg 
	WHERE credit_amt > 0 

	DECLARE deb_curs CURSOR FOR 

	SELECT flex_code FROM t_multiledg 
	WHERE debit_amt > 0 
	ORDER BY flex_code 

	FOREACH deb_curs INTO l_flex2_code 
		IF l_flex1_code = l_flex2_code THEN 
			CONTINUE FOREACH 
			#loop around TO get others
		END IF 
		SELECT * INTO l_rec_ledgerreln.* FROM ledgerreln 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND flex1_code = l_flex1_code 
		AND flex2_code = l_flex2_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			SELECT * INTO l_rec_ledgerreln.* 
			FROM ledgerreln 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex1_code = l_flex2_code 
			AND flex2_code = l_flex1_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET glob_err_message = "Ledger ", l_flex1_code clipped, " AND ", l_flex2_code clipped," - Run gb8" 
				LET p_status_ind = 3				
				ERROR kandoomsg2("G",9213," ") #9213 Undefined Ledger Relationships
				EXIT FOREACH 
			END IF 
		END IF 
		
		IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
			LET l_acct_code = l_rec_ledgerreln.acct1_code 
		ELSE 
			LET l_acct_code = l_rec_ledgerreln.acct2_code 
		
		END IF 
		LET l_cred_amt = 0 
		LET l_for_cred_amt = 0 
		
		SELECT sum(debit_amt) INTO l_deb_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 
		
		SELECT sum(for_debit_amt) INTO l_for_deb_amt 
		FROM t_multiledg 
		WHERE flex_code = l_flex2_code 

		LET p_seq_num = p_seq_num + 1 

		LET p_status_ind = insert_batchdetl(
			p_seq_num,
			l_acct_code, 
			l_deb_amt,
			l_cred_amt,
			l_for_deb_amt, 
			l_for_cred_amt,
			p_status_ind) 

		IF p_status_ind = 4 
		OR p_status_ind = 5 
		OR p_status_ind = 6 THEN 
			EXIT FOREACH 
		END IF 

		# now create the other side of the multi ledger entry
		IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
			LET l_acct_code = l_rec_ledgerreln.acct2_code 
		ELSE 
			LET l_acct_code = l_rec_ledgerreln.acct1_code 
		END IF 

		LET l_deb_amt = 0 
		LET l_for_deb_amt = 0 

		SELECT sum(debit_amt) INTO l_cred_amt FROM t_multiledg 
		WHERE flex_code = l_flex2_code 

		SELECT sum(for_debit_amt) INTO l_for_cred_amt FROM t_multiledg 
		WHERE flex_code = l_flex2_code 

		LET p_seq_num = p_seq_num + 1 

		LET p_status_ind = insert_batchdetl(p_seq_num,
			l_acct_code, 
			l_deb_amt,
			l_cred_amt,
			l_for_deb_amt, 
			l_for_cred_amt,
			p_status_ind)
			 
		IF p_status_ind = 4 
		OR p_status_ind = 5 
		OR p_status_ind = 6 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	RETURN p_status_ind 
END FUNCTION  # insert_new_credits

############################################################
# FUNCTION insert_batchdetl(p_next_seq, p_acct_code, p_cred_amt, p_deb_amt, p_for_cred_amt, p_for_deb_amt, p_status_ind)
#
# The DR/CR parameters are accepted inversely on purpose TO complete
# NOTE  Multiledger transaction processing.
# ie debit_amt of $20.00 IS accepted in this FUNCTION as $20.00 credit_amt
# just as credit_amt $12.54 accepted as $12.54 debit
############################################################
FUNCTION insert_batchdetl(p_next_seq,p_acct_code,p_credit_amt,p_debit_amt,p_for_credit_amt,p_for_debit_amt,p_jour_code,p_jour_num,p_year_num,p_period_num,p_status_ind,p_jour_date,p_currency_code,p_conv_qty) 
--p_next_seq, p_acct_code, p_cred_amt, p_deb_amt, p_for_cred_amt, p_for_deb_amt, p_status_ind)
	DEFINE p_next_seq INTEGER 
	DEFINE p_acct_code LIKE batchdetl.acct_code
	DEFINE p_credit_amt LIKE batchdetl.credit_amt
	DEFINE p_debit_amt LIKE batchdetl.debit_amt
	DEFINE p_for_credit_amt LIKE batchdetl.for_credit_amt
	DEFINE p_for_debit_amt LIKE batchdetl.for_debit_amt
	DEFINE p_jour_code LIKE batchhead.jour_code
	DEFINE p_jour_num LIKE batchhead.jour_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_period_num LIKE batchhead.period_num
	DEFINE p_jour_date LIKE batchhead.jour_date
	DEFINE p_currency_code LIKE batchhead.currency_code
	DEFINE p_conv_qty LIKE batchhead.conv_qty
	DEFINE p_status_ind SMALLINT
	DEFINE l_operation_status INTEGER 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*  # local values of batchdetl, used for the insert statement

	INITIALIZE l_rec_batchdetl.* TO NULL 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_acct_code 
	
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET glob_err_message = "Batch ", p_jour_num USING "<<<<<<<<", " Acct ", p_acct_code clipped, " NOT FOUND " 
		LET p_status_ind = 4 
		ERROR kandoomsg2("G",9031," ") #9031 Account NOT found
		RETURN p_status_ind 
	ELSE 
	
		IF ((( l_rec_coa.end_year_num < p_year_num) OR 
		(l_rec_coa.end_year_num = p_year_num AND 
		l_rec_coa.end_period_num < p_period_num)) OR 
		((l_rec_coa.start_year_num > p_year_num) OR 
		(l_rec_coa.start_year_num = p_year_num AND 
		l_rec_coa.start_period_num > p_period_num))) THEN 

			LET p_status_ind = 4 
			LET glob_err_message = "Batch ", p_jour_num USING "<<<<<<<<", " Acct ", p_acct_code clipped, " NOT OPEN " 
			ERROR kandoomsg2("G",9526," ") #9526 Account NOT Open
			RETURN p_status_ind 

		END IF 
	END IF 

	LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_batchdetl.jour_code = p_jour_code 
	LET l_rec_batchdetl.jour_num = p_jour_num 
	LET l_rec_batchdetl.seq_num = p_next_seq 
	LET l_rec_batchdetl.tran_type_ind = "ML" 
	LET l_rec_batchdetl.analysis_text = " " 
	LET l_rec_batchdetl.tran_date = p_jour_date 
	LET l_rec_batchdetl.ref_text = " " 
	LET l_rec_batchdetl.ref_num = 0 
	LET l_rec_batchdetl.acct_code = p_acct_code 
	LET l_rec_batchdetl.desc_text = l_rec_coa.desc_text 
	LET l_rec_batchdetl.credit_amt = p_credit_amt 
	LET l_rec_batchdetl.debit_amt = p_debit_amt 
	LET l_rec_batchdetl.currency_code = p_currency_code 
	LET l_rec_batchdetl.conv_qty = p_conv_qty 
	LET l_rec_batchdetl.for_debit_amt = p_for_debit_amt 
	LET l_rec_batchdetl.for_credit_amt = p_for_credit_amt 
	LET l_rec_batchdetl.stats_qty = 0 

	INSERT INTO batchdetl VALUES (l_rec_batchdetl.*)
	
	IF status != 0 THEN 
		LET glob_err_message = " Insert INTO batchdetl failed" 
		LET p_status_ind = 6 
		ERROR kandoomsg2("G",7021,glob_err_message) 
		RETURN p_status_ind 
	END IF 
	
	{ #FIXME: not sure what to do with batchhead values
	LET glob_rec_batchhead.credit_amt = glob_rec_batchhead.credit_amt +	l_rec_batchdetl.credit_amt 
	LET glob_rec_batchhead.debit_amt = glob_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
	LET glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_debit_amt	+ l_rec_batchdetl.for_debit_amt 
	LET glob_rec_batchhead.for_credit_amt = glob_rec_batchhead.for_credit_amt	+ l_rec_batchdetl.for_credit_amt 

	LET glob_rec_batchhead.control_amt = glob_rec_batchhead.control_amt + l_rec_batchdetl.for_credit_amt 
	LET p_rec_batchdetl.* = l_rec_batchdetl.* 
	}

	CALL post_account(l_rec_batchdetl,p_year_num) RETURNING l_operation_status 
	CALL post_accountledger(l_rec_batchdetl.*) RETURNING l_operation_status

	CALL post_accounthist(l_rec_batchdetl.*,p_year_num,p_period_num) RETURNING l_operation_status

	IF modu_rec_glparms.use_currency_flag = "Y" THEN 
		CALL post_accountcur(l_rec_batchdetl.*,p_year_num,p_currency_code) RETURNING l_operation_status
		CALL post_accounthistcur(l_rec_batchdetl.*,p_year_num,p_period_num,p_currency_code) RETURNING l_operation_status
	END IF 

	LET glob_total_debit = glob_total_debit + p_debit_amt 
	LET glob_total_credit = glob_total_credit + p_credit_amt 
	LET modu_rec_postrun.post_amt = modu_rec_postrun.post_amt + p_debit_amt 

	RETURN p_status_ind 
END FUNCTION # insert_batchdetl

FUNCTION prepare_cursors_and_prepares_GP2()
	DEFINE l_query_text STRING
	# main update on batchhead prepare
	WHENEVER SQLERROR STOP
	LET l_query_text = "UPDATE batchhead SET ",
	" post_flag = ? ,",
	"post_run_num = ? ,",
	"seq_num = ?, ",
	"debit_amt = ? ,",
	"credit_amt = ?,",
	"control_amt = ?,",
	"for_debit_amt = ?,",
	"for_debit_amt = ? ",
	"WHERE cmpy_code = ? ",
	"AND jour_code = ? ",
	"AND jour_num = ? "
	CALL mdl_prp_upd_main_batchhead.Prepare(l_query_text)

	# cursor that reads batchdetl, may go to global batchhead cursor later
	LET l_query_text = "SELECT * FROM batchdetl d ", 
	" WHERE d.cmpy_code = ? ",
	" AND d.jour_code = ? ",
	" AND d.jour_num = ? "
	CALL mdl_crs_batchdetl.Declare(l_query_text)

	# prepare for insert into accountledger
	LET l_query_text = "INSERT INTO accountledger VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	CALL mdl_prp_ins_accountledger.Prepare(l_query_text)
	
	-- INSERT INTO account VALUES (l_rec_account.*)
	LET l_query_text = "INSERT INTO account VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	CALL mdl_prp_ins_account.Prepare(l_query_text)		
	
	--UPDATE account SET * = l_rec_account.* 
	LET l_query_text = "UPDATE account SET * = (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? "
	CALL mdl_prp_upd_account.Prepare(l_query_text)		
	
	# accounthist
	LET l_query_text = "UPDATE accounthist SET * = (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? AND period_num = ?"
	CALL mdl_prp_upd_accounthist.Prepare(l_query_text)
	
	# accounthist insert section
	LET l_query_text = " SELECT period_num FROM period ",
	" WHERE cmpy_code = ? ", 
	" AND year_num = ? ",
	" AND period_num NOT IN (SELECT period_num FROM accounthist WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? ) "
	CALL mdl_crs_accounthist_check.Declare(l_query_text) 

	LET l_query_text = "INSERT INTO accounthist VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	CALL mdl_prp_ins_accounthist.Prepare(l_query_text)

	# accountcur
	LET l_query_text = "UPDATE accountcur SET * = (?,?,?,?,?,?,?,?,?,?,?,?,?,?) WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? AND currency_code = ?"
	CALL mdl_prp_upd_accountcur.Prepare(l_query_text)
	LET l_query_text = "INSERT INTO accountcur VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	CALL mdl_prp_ins_accountcur.Prepare(l_query_text)

	# accounthistcur
	LET l_query_text = "SELECT period.* FROM period ",
	" WHERE cmpy_code = ? ",
	" AND year_num = ? ",
	" AND period.period_num NOT IN (SELECT period_num FROM accounthistcur WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? AND currency_code = ?) "
	CALL mdl_crs_accounthistcur_check.Declare(l_query_text) 
	LET l_query_text = "UPDATE accounthistcur SET * = (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) WHERE cmpy_code = ? AND acct_code = ? AND year_num = ? AND period_num = ? AND currency_code = ?"
	CALL mdl_prp_upd_accounthistcur.Prepare(l_query_text)
	
	# postrun
	LET l_query_text = "INSERT INTO postrun VALUES (?,?,?,?,?,?,?)"
	CALL mdl_prp_ins_postrun.Prepare(l_query_text)

	LET l_query_text = "UPDATE postrun SET post_amt = ?,end_total_amt = ? ",
	" WHERE cmpy_code = ? AND post_run_num = ?"
	CALL mdl_prp_upd_postrun.Prepare(l_query_text)

	# insert new debits
	LET l_query_text = "SELECT flex_code FROM t_multiledg WHERE credit_amt > 0 ORDER BY flex_code "
	CALL mdl_crs_multiledg_credits.Declare(l_query_text)

END FUNCTION
