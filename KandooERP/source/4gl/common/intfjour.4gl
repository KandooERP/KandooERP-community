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

# NOTE: was only used by GBQ -> moved it to GBQ

{
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_batchhead RECORD LIKE batchhead.*
DEFINE modu_prob_found SMALLINT 

############################################################
# FUNCTION intfjour (p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)
#
# This function is a kind of a REPORT OUTPUT function which should be used by other programs.
# BUT I can only see it being called by GBQ. So, I have no idea why it's in common/shared
############################################################
FUNCTION intfjour2(p_rpt_idx,p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_sel_stmt STRING
	DEFINE p_cmpy LIKE batchhead.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE batchhead.entry_code
	DEFINE p_bal_rec RECORD 
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
	DEFINE p_jour LIKE batchhead.jour_num
	DEFINE p_acct_code LIKE batchdetl.acct_code
   DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE l_post_text CHAR(80)
	DEFINE l_err_text CHAR(80)
	DEFINE l_posted_journal LIKE batchhead.jour_num
	DEFINE l_msgresp LIKE language.yes_flag 
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
	DEFINE l_next_seq INTEGER 
	DEFINE l_line_count INTEGER
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_rpt_idx SMALLINT 


	LET l_line_count = 0 
	LET modu_prob_found = false 
	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_1 CURSOR FOR prep_1 
	INITIALIZE modu_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 
	IF l_posted_journal IS NULL THEN 
		LET l_rec_glparms.next_jour_num = 0 
		SELECT max(jour_num) INTO l_rec_glparms.next_jour_num FROM t_batchhead 
		IF l_rec_glparms.next_jour_num IS NULL 
		OR l_rec_glparms.next_jour_num = 0 THEN 
			LET l_rec_glparms.next_jour_num = 1 
		ELSE 
			LET l_rec_glparms.next_jour_num = l_rec_glparms.next_jour_num + 1 
		END IF 
		LET l_posted_journal = l_rec_glparms.next_jour_num 
		LET l_post_text = "Selected journal codes FROM glparms" 

	ELSE 
		# commenced t_batchdetl INSERT but did nay finish
		# so we must delete out what t_batchdetl AND t_batchhead it did do
		# IF the post died mid batch we double check that the batch has
		# NOT been posted somehow. IF it has THEN it needs TO be manually
		# reversed FROM the tables before repost
		SELECT post_flag 
		INTO l_tmp_flag 
		FROM t_batchhead 
		WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		IF l_tmp_flag = "Y" THEN #batch was somehow posted 
			LET l_err_text = "Batch ",l_posted_journal USING "####", 
			" has been posted - FATAL" 
		END IF 
		DELETE FROM t_batchdetl WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		AND username = glob_rec_kandoouser.sign_on_code 
		DELETE FROM t_batchhead WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		LET l_rec_glparms.next_jour_num = l_posted_journal 
	END IF 
	LET modu_batchhead.cmpy_code = p_cmpy 
	LET modu_batchhead.jour_code = p_sent_jour_code 
	LET modu_batchhead.jour_num = l_rec_glparms.next_jour_num 
	LET modu_batchhead.entry_code = p_kandoouser_sign_on_code 
	LET modu_batchhead.jour_date = today 
	LET modu_batchhead.year_num = p_year_num 
	LET modu_batchhead.period_num = p_periods 
	LET modu_batchhead.control_amt = 0 
	LET modu_batchhead.debit_amt = 0 
	LET modu_batchhead.credit_amt = 0 
	LET modu_batchhead.for_debit_amt = 0 
	LET modu_batchhead.for_credit_amt = 0 
	LET modu_batchhead.control_qty = 0 
	LET modu_batchhead.stats_qty = 0 
	LET modu_batchhead.currency_code = p_currency_code 
	LET modu_batchhead.source_ind = p_source_ind 
	IF l_rec_glparms.use_clear_flag = "Y" THEN 
		LET modu_batchhead.cleared_flag = "N" 
	ELSE 
		LET modu_batchhead.cleared_flag = "Y" 
	END IF 
	LET modu_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 
	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 
	LET l_post_text = "Commenced batch lines INSERT" 
	#IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
		#DISPLAY " Reporting on GL batch : " at 1,1attribute(yellow) 
		#DISPLAY " ", l_rec_glparms.next_jour_num at 2,1
	#END IF 
	FOREACH curs_1 INTO l_rec_data.* 
		LET modu_batchhead.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
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
		LET modu_batchhead.stats_qty = modu_batchhead.stats_qty + 
		l_rec_batchdetl.stats_qty 
		LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
		l_rec_batchdetl.debit_amt 
		LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
		l_rec_batchdetl.credit_amt 
		LET modu_batchhead.for_debit_amt = modu_batchhead.for_debit_amt + 
		l_rec_batchdetl.for_debit_amt 
		LET modu_batchhead.for_credit_amt = modu_batchhead.for_credit_amt + 
		l_rec_batchdetl.for_credit_amt 
		# check that AT least one side has a value
		IF l_rec_batchdetl.debit_amt = 0 AND 
		l_rec_batchdetl.credit_amt = 0 AND 
		l_rec_batchdetl.for_debit_amt = 0 AND 
		l_rec_batchdetl.for_credit_amt = 0 AND 
		l_rec_batchdetl.stats_qty = 0 THEN 
		ELSE 
			LET l_line_count = l_line_count + 1 
			LET l_err_text = " t_batchetl INSERT (lines) - intfjour.4gl " 
--			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
--				DISPLAY " Processing : " at 1,1 	attribute(yellow) 
--				DISPLAY " : ", l_rec_batchdetl.ref_text at 1,23
--				DISPLAY " : ",l_rec_batchdetl.ref_num at 2,1 
--			END IF 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
		END IF 
		INITIALIZE l_rec_batchdetl.* TO NULL 
	END FOREACH 
	LET l_post_text = "Inserted all t_batchdetl records" 
	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted
	IF l_line_count > 0 THEN 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = p_bal_rec.tran_type_ind 
		LET l_rec_batchdetl.tran_date = modu_batchhead.jour_date 
		LET l_rec_batchdetl.acct_code = p_bal_rec.acct_code 
		LET l_rec_batchdetl.desc_text = p_bal_rec.desc_text 
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
			LET l_err_text = "t_batchetl INSERT - (balancing entry)" 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			#  increment the batch header
			LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
			l_rec_batchdetl.debit_amt 
			LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
			l_rec_batchdetl.credit_amt 
			LET modu_batchhead.for_debit_amt = 
			modu_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET modu_batchhead.for_credit_amt = 
			modu_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
			LET modu_batchhead.seq_num = l_next_seq 
		END IF 
		# INSERT batch header
		# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
		#       I)nventory AND Buy rate OTHERWISE
		IF l_rec_glparms.use_currency_flag = "Y" AND 
		l_rec_glparms.base_currency_code IS NOT NULL AND 
		modu_batchhead.currency_code IS NOT NULL AND 
		modu_batchhead.currency_code != l_rec_glparms.base_currency_code THEN 
			IF modu_batchhead.source_ind matches "[AJI]" THEN 
				LET modu_batchhead.rate_type_ind = "S" 
			ELSE 
				LET modu_batchhead.rate_type_ind = "B" 
			END IF 
		ELSE 
			LET modu_batchhead.rate_type_ind = " " 
		END IF 
		IF modu_batchhead.currency_code IS NULL THEN 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
				ERROR kandoomsg2("G",7000,modu_batchhead.jour_num)	#7000 Warning: Rate Type will be updated as NULL.
				SLEEP 3
			END IF 
		END IF 
		LET l_err_text = "t_batchead Insert - intfjour.4gl" 
		LET modu_batchhead.control_amt = modu_batchhead.for_debit_amt 
		LET modu_batchhead.control_qty = modu_batchhead.stats_qty 
		INSERT INTO t_batchhead VALUES (modu_batchhead.*) 
		# now write the REPORT on this batch
		IF p_acct_code IS NULL THEN 
			LET l_where_text = "1=1" 
		ELSE 
			LET l_where_text = "acct_code matches '",p_acct_code CLIPPED,"'" 
		END IF 
		LET l_query_text = " SELECT * FROM t_batchdetl", 
		" WHERE cmpy_code = '",p_cmpy CLIPPED,"'", 
		" AND jour_code = '",p_sent_jour_code CLIPPED,"'", 
		" AND jour_num = ",l_rec_glparms.next_jour_num, 
		" AND ",l_where_text CLIPPED, 
		" ORDER BY seq_num" 
		PREPARE s_detl_curs FROM l_query_text 
		DECLARE detl_curs CURSOR FOR s_detl_curs 
		SELECT company.* INTO l_rec_company.* FROM company 
		WHERE company.cmpy_code = p_cmpy 
		FOREACH detl_curs INTO l_rec_batchdetl.* 
		
			OUTPUT TO REPORT CM2_rpt_list_intfjour(p_cmpy, 
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_sent_jour_code, 
			p_jour) 
		END FOREACH

			#---------------------------------------------------------
			OUTPUT TO REPORT CM2_rpt_list_intfjour(l_rpt_idx,
			p_cmpy, 
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_sent_jour_code, 
			p_jour) 
			IF NOT rpt_int_flag_handler2("Journal Batch Print:",p_sent_jour_code,l_rec_glparms.next_jour_num,l_rpt_idx) THEN
				RETURN FALSE #??? not sure false, NULL, or something else to say, CANCEL 
			END IF 
			#---------------------------------------------------------							
		 
	ELSE 
		# nothing posted
		# RETURN 0 IF no UPDATE done
		LET l_rec_glparms.next_jour_num = 0 
	END IF 
	# RETURN the batch number, negative IF suspense a/c used, ELSE positive
	# this enables batch number TO be recorded on the source table
	# IF required. Needed in purchasing TO allow FOR reconcilliation
	# of summary batch posting
	IF modu_prob_found THEN 
		# suspense a/c used, RETURN NEGATIVE jour_num
		RETURN ( 0 - l_rec_glparms.next_jour_num ) 
	ELSE 
		RETURN l_rec_glparms.next_jour_num 
	END IF 
--	WHENEVER ERROR CONTINUE 
	

END FUNCTION # intfjour () 

############################################################
# REPORT CM2_rpt_list_intfjour(p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour)
#
#
############################################################
REPORT CM2_rpt_list_intfjour(p_rpt_idx,p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE p_sent_jour_code LIKE batchdetl.jour_code
	DEFINE p_jour LIKE batchdetl.jour_num 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_start_period LIKE batchhead.period_num
	DEFINE l_end_period LIKE batchhead.period_num	 
	DEFINE l_start_year LIKE batchhead.year_num
	DEFINE l_end_year LIKE batchhead.year_num
	DEFINE l_coa_not_open SMALLINT
	DEFINE l_coa_not_found SMALLINT

	OUTPUT 
--	PAGE LENGTH 66 
--	LEFT MARGIN 0 
	ORDER BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.currency_code, 
	p_rec_batchdetl.conv_qty, 
	p_rec_batchdetl.acct_code, 
	p_rec_batchdetl.tran_date 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			 
			SELECT * INTO modu_batchhead.* FROM t_batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code
			 
			PRINT COLUMN 1, "Batch: ", p_jour, " - ",p_sent_jour_code 
			PRINT COLUMN 5, "Date: ", modu_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", modu_batchhead.year_num, 
			COLUMN 50, "Period: ", modu_batchhead.period_num, 
			COLUMN 70, "FROM : ", modu_batchhead.entry_code, 
			COLUMN 87, "Source : ", modu_batchhead.source_ind, 
			COLUMN 101, "Currency : ", modu_batchhead.currency_code 
			PRINT COLUMN 5, "Comments:", 
			COLUMN 16, modu_batchhead.com1_text 
			PRINT COLUMN 5, "Comments :", 
			COLUMN 16, modu_batchhead.com2_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 1, p_rec_batchdetl.acct_code , 
			COLUMN 20, p_rec_batchdetl.tran_date 

		ON EVERY ROW 
			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES
			# check that chart number IS valid AND live
			LET l_coa_not_found = false 
			LET l_coa_not_open = false 
			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO l_start_year,l_start_period,l_end_year,l_end_period 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 
			IF status THEN 
				LET l_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < modu_batchhead.year_num) OR 
				(l_end_year = modu_batchhead.year_num AND 
				l_end_period < modu_batchhead.period_num)) OR 
				((l_start_year > modu_batchhead.year_num) OR 
				(l_start_year = modu_batchhead.year_num AND 
				l_start_period > modu_batchhead.period_num))) THEN 
					LET l_coa_not_open = true 
				END IF 
			END IF 
			IF l_coa_not_found OR l_coa_not_open THEN 
				LET modu_prob_found = true 
			END IF 
			PRINT COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 94, p_rec_batchdetl.ref_num USING "###########", 
			COLUMN 114, p_rec_batchdetl.ref_text 

		AFTER GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 60,"-------------------------------" 
			PRINT COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt) 
			USING "-----------&.&&", 
			COLUMN 75, GROUP sum(p_rec_batchdetl.credit_amt) 
			USING "-----------&.&&" 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
}




{
# Leave this code there for now... and remove it, when kandooerp 2.0 is released
############################################################
# FUNCTION intfjour (p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)
#
#
############################################################
FUNCTION intfjour (p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code) 
	DEFINE p_sel_stmt CHAR (2048)
	DEFINE p_cmpy LIKE batchhead.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE batchhead.entry_code
	DEFINE p_bal_rec RECORD 
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
	DEFINE p_jour LIKE batchhead.jour_num
	DEFINE p_acct_code LIKE batchdetl.acct_code
   DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE l_post_text CHAR(80)
	DEFINE l_err_text CHAR(80)
	DEFINE l_posted_journal LIKE batchhead.jour_num
	DEFINE l_msgresp LIKE language.yes_flag 
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
	DEFINE l_next_seq INTEGER 
	DEFINE l_line_count INTEGER
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	LET l_line_count = 0 
	LET modu_prob_found = false 
	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_1 CURSOR FOR prep_1 
	INITIALIZE modu_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 
	IF l_posted_journal IS NULL THEN 
		LET l_rec_glparms.next_jour_num = 0 
		SELECT max(jour_num) INTO l_rec_glparms.next_jour_num FROM t_batchhead 
		IF l_rec_glparms.next_jour_num IS NULL 
		OR l_rec_glparms.next_jour_num = 0 THEN 
			LET l_rec_glparms.next_jour_num = 1 
		ELSE 
			LET l_rec_glparms.next_jour_num = l_rec_glparms.next_jour_num + 1 
		END IF 
		LET l_posted_journal = l_rec_glparms.next_jour_num 
		LET l_post_text = "Selected journal codes FROM glparms" 

	ELSE 
		# commenced t_batchdetl INSERT but did nay finish
		# so we must delete out what t_batchdetl AND t_batchhead it did do
		# IF the post died mid batch we double check that the batch has
		# NOT been posted somehow. IF it has THEN it needs TO be manually
		# reversed FROM the tables before repost
		SELECT post_flag 
		INTO l_tmp_flag 
		FROM t_batchhead 
		WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		IF l_tmp_flag = "Y" THEN #batch was somehow posted 
			LET l_err_text = "Batch ",l_posted_journal USING "####", 
			" has been posted - FATAL" 
		END IF 
		DELETE FROM t_batchdetl WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		AND username = glob_rec_kandoouser.sign_on_code 
		DELETE FROM t_batchhead WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		LET l_rec_glparms.next_jour_num = l_posted_journal 
	END IF 
	LET modu_batchhead.cmpy_code = p_cmpy 
	LET modu_batchhead.jour_code = p_sent_jour_code 
	LET modu_batchhead.jour_num = l_rec_glparms.next_jour_num 
	LET modu_batchhead.entry_code = p_kandoouser_sign_on_code 
	LET modu_batchhead.jour_date = today 
	LET modu_batchhead.year_num = p_year_num 
	LET modu_batchhead.period_num = p_periods 
	LET modu_batchhead.control_amt = 0 
	LET modu_batchhead.debit_amt = 0 
	LET modu_batchhead.credit_amt = 0 
	LET modu_batchhead.for_debit_amt = 0 
	LET modu_batchhead.for_credit_amt = 0 
	LET modu_batchhead.control_qty = 0 
	LET modu_batchhead.stats_qty = 0 
	LET modu_batchhead.currency_code = p_currency_code 
	LET modu_batchhead.source_ind = p_source_ind 
	IF l_rec_glparms.use_clear_flag = "Y" THEN 
		LET modu_batchhead.cleared_flag = "N" 
	ELSE 
		LET modu_batchhead.cleared_flag = "Y" 
	END IF 
	LET modu_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 
	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 
	LET l_post_text = "Commenced batch lines INSERT" 
	IF glob_rec_rmsreps.exec_ind = '1' THEN 
		DISPLAY " Reporting on GL batch : " at 1,1 
		attribute(yellow) 
		DISPLAY " ", l_rec_glparms.next_jour_num at 2,1 

	END IF 
	FOREACH curs_1 INTO l_rec_data.* 
		LET modu_batchhead.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
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
		LET modu_batchhead.stats_qty = modu_batchhead.stats_qty + 
		l_rec_batchdetl.stats_qty 
		LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
		l_rec_batchdetl.debit_amt 
		LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
		l_rec_batchdetl.credit_amt 
		LET modu_batchhead.for_debit_amt = modu_batchhead.for_debit_amt + 
		l_rec_batchdetl.for_debit_amt 
		LET modu_batchhead.for_credit_amt = modu_batchhead.for_credit_amt + 
		l_rec_batchdetl.for_credit_amt 
		# check that AT least one side has a value
		IF l_rec_batchdetl.debit_amt = 0 AND 
		l_rec_batchdetl.credit_amt = 0 AND 
		l_rec_batchdetl.for_debit_amt = 0 AND 
		l_rec_batchdetl.for_credit_amt = 0 AND 
		l_rec_batchdetl.stats_qty = 0 THEN 
		ELSE 
			LET l_line_count = l_line_count + 1 
			LET l_err_text = " t_batchetl INSERT (lines) - intfjour.4gl " 
			IF glob_rec_rmsreps.exec_ind = '1' THEN 
				DISPLAY " Processing : " at 1,1 
				attribute(yellow) 
				DISPLAY " : ", l_rec_batchdetl.ref_text at 1,23 

				DISPLAY " : ",l_rec_batchdetl.ref_num at 2,1 

			END IF 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
		END IF 
		INITIALIZE l_rec_batchdetl.* TO NULL 
	END FOREACH 
	LET l_post_text = "Inserted all t_batchdetl records" 
	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted
	IF l_line_count > 0 THEN 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = p_bal_rec.tran_type_ind 
		LET l_rec_batchdetl.tran_date = modu_batchhead.jour_date 
		LET l_rec_batchdetl.acct_code = p_bal_rec.acct_code 
		LET l_rec_batchdetl.desc_text = p_bal_rec.desc_text 
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
			LET l_err_text = "t_batchetl INSERT - (balancing entry)" 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code) 
			#  increment the batch header
			LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
			l_rec_batchdetl.debit_amt 
			LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
			l_rec_batchdetl.credit_amt 
			LET modu_batchhead.for_debit_amt = 
			modu_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET modu_batchhead.for_credit_amt = 
			modu_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
			LET modu_batchhead.seq_num = l_next_seq 
		END IF 
		# INSERT batch header
		# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
		#       I)nventory AND Buy rate OTHERWISE
		IF l_rec_glparms.use_currency_flag = "Y" AND 
		l_rec_glparms.base_currency_code IS NOT NULL AND 
		modu_batchhead.currency_code IS NOT NULL AND 
		modu_batchhead.currency_code != l_rec_glparms.base_currency_code THEN 
			IF modu_batchhead.source_ind matches "[AJI]" THEN 
				LET modu_batchhead.rate_type_ind = "S" 
			ELSE 
				LET modu_batchhead.rate_type_ind = "B" 
			END IF 
		ELSE 
			LET modu_batchhead.rate_type_ind = " " 
		END IF 
		IF modu_batchhead.currency_code IS NULL THEN 
			IF glob_rec_rmsreps.exec_ind = '1' THEN 
				LET l_msgresp = kandoomsg("G",7000,modu_batchhead.jour_num) 
				#7000 Warning: Rate Type will be updated as NULL.
			END IF 
		END IF 
		LET l_err_text = "t_batchead Insert - intfjour.4gl" 
		LET modu_batchhead.control_amt = modu_batchhead.for_debit_amt 
		LET modu_batchhead.control_qty = modu_batchhead.stats_qty 
		INSERT INTO t_batchhead VALUES (modu_batchhead.*) 
		# now write the REPORT on this batch
		IF p_acct_code IS NULL THEN 
			LET l_where_text = "1=1" 
		ELSE 
			LET l_where_text = "acct_code matches '",p_acct_code CLIPPED,"'" 
		END IF 
		LET l_query_text = " SELECT * FROM t_batchdetl", 
		" WHERE cmpy_code = '",p_cmpy CLIPPED,"'", 
		" AND jour_code = '",p_sent_jour_code CLIPPED,"'", 
		" AND jour_num = ",l_rec_glparms.next_jour_num, 
		" AND ",l_where_text CLIPPED, 
		" ORDER BY seq_num" 
		PREPARE s_detl_curs FROM l_query_text 
		DECLARE detl_curs CURSOR FOR s_detl_curs 
		SELECT company.* INTO l_rec_company.* FROM company 
		WHERE company.cmpy_code = p_cmpy 
		FOREACH detl_curs INTO l_rec_batchdetl.* 
			OUTPUT TO REPORT rpt_list(p_cmpy, 
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_sent_jour_code, 
			p_jour) 
		END FOREACH 
	ELSE 
		# nothing posted
		# RETURN 0 IF no UPDATE done
		LET l_rec_glparms.next_jour_num = 0 
	END IF 
	# RETURN the batch number, negative IF suspense a/c used, ELSE positive
	# this enables batch number TO be recorded on the source table
	# IF required. Needed in purchasing TO allow FOR reconcilliation
	# of summary batch posting
	IF modu_prob_found THEN 
		# suspense a/c used, RETURN NEGATIVE jour_num
		RETURN ( 0 - l_rec_glparms.next_jour_num ) 
	ELSE 
		RETURN l_rec_glparms.next_jour_num 
	END IF 
	WHENEVER ERROR CONTINUE 
END FUNCTION # intfjour () 

############################################################
# REPORT rpt_list(p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour)
#
#
############################################################
REPORT rpt_list(p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE p_sent_jour_code LIKE batchdetl.jour_code
	DEFINE p_jour LIKE batchdetl.jour_num 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_start_period LIKE batchhead.period_num
	DEFINE l_end_period LIKE batchhead.period_num	 
	DEFINE l_start_year LIKE batchhead.year_num
	DEFINE l_end_year LIKE batchhead.year_num
	DEFINE l_coa_not_open SMALLINT
	DEFINE l_coa_not_found SMALLINT

	OUTPUT 
	PAGE LENGTH 66 
	LEFT MARGIN 0 
	ORDER BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.currency_code, 
	p_rec_batchdetl.conv_qty, 
	p_rec_batchdetl.acct_code, 
	p_rec_batchdetl.tran_date 
	FORMAT 
		PAGE HEADER 
			LET glob_rec_rmsreps.page_num = pageno 
			CALL report5() 
			RETURNING l_arr_line[1], l_arr_line[2], l_arr_line[3], l_arr_line[4] 
			PRINT COLUMN 01, l_arr_line[1] 
			PRINT COLUMN 01, l_arr_line[2] 
			PRINT COLUMN 01, l_arr_line[3] 
			PRINT COLUMN 01, glob_rec_kandooreport.line1_text 
			PRINT COLUMN 01, glob_rec_kandooreport.line2_text 
			PRINT COLUMN 01, l_arr_line[3] 
			SELECT * INTO modu_batchhead.* FROM t_batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code 
			PRINT COLUMN 1, "Batch: ", p_jour, " - ",p_sent_jour_code 
			PRINT COLUMN 5, "Date: ", modu_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", modu_batchhead.year_num, 
			COLUMN 50, "Period: ", modu_batchhead.period_num, 
			COLUMN 70, "FROM : ", modu_batchhead.entry_code, 
			COLUMN 87, "Source : ", modu_batchhead.source_ind, 
			COLUMN 101, "Currency : ", modu_batchhead.currency_code 
			PRINT COLUMN 5, "Comments:", 
			COLUMN 16, modu_batchhead.com1_text 
			PRINT COLUMN 5, "Comments :", 
			COLUMN 16, modu_batchhead.com2_text 
		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 
		BEFORE GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 1, p_rec_batchdetl.acct_code , 
			COLUMN 20, p_rec_batchdetl.tran_date 
		ON EVERY ROW 
			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES
			# check that chart number IS valid AND live
			LET l_coa_not_found = false 
			LET l_coa_not_open = false 
			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO l_start_year,l_start_period,l_end_year,l_end_period 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 
			IF status THEN 
				LET l_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < modu_batchhead.year_num) OR 
				(l_end_year = modu_batchhead.year_num AND 
				l_end_period < modu_batchhead.period_num)) OR 
				((l_start_year > modu_batchhead.year_num) OR 
				(l_start_year = modu_batchhead.year_num AND 
				l_start_period > modu_batchhead.period_num))) THEN 
					LET l_coa_not_open = true 
				END IF 
			END IF 
			IF l_coa_not_found OR l_coa_not_open THEN 
				LET modu_prob_found = true 
			END IF 
			PRINT COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 94, p_rec_batchdetl.ref_num USING "###########", 
			COLUMN 114, p_rec_batchdetl.ref_text 
		AFTER GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 60,"-------------------------------" 
			PRINT COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt) 
			USING "-----------&.&&", 
			COLUMN 75, GROUP sum(p_rec_batchdetl.credit_amt) 
			USING "-----------&.&&" 
			SKIP 1 line 
		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 
			IF glob_rec_rmsreps.sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_rec_rmsreps.sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, l_arr_line[4] 
END REPORT 


}