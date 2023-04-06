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

	Source code beautified by beautify.pl on 2020-01-02 10:35:17	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS 
	DEFINE glob_post_rpt_wid LIKE rmsreps.report_width_num 
	DEFINE glob_post_rpt_length LIKE rmsreps.page_length_num 
	DEFINE glob_post_rpt_pageno LIKE rmsreps.page_num 
	DEFINE glob_invalid_acct SMALLINT 
END GLOBALS 



# FUNCTION create_jnl_batch
#
# This FUNCTION creates a detailed OR summary journal batch based on
# completed batch detail entries in table f_batchdetl.  The FUNCTION
# has been created in response TO common processing requirements in
# Inventory Posting AND Shipment Finalise.  It therefore has the
# following rules AND restrictions:-
#
#    - The FUNCTION expects base currency VALUES AND does NOT collect
#      statistical quantities.
#
#    - The batch IS summarised by account code within transaction type
#      indicator only.
#
#    - The FUNCTION expects the batch TO be balanced (ie. total debit
#      entries equal total credit entries).  IF the FUNCTION detects
#      an imbalance, it will balance the batch TO the GL suspense
#      account.
#
#    - The FUNCTION expects that any multi-ledger entries will have
#      been resolved WHEN the batch details were SET up.  It does NOT
#      separate the data INTO batches with only one credit OR debit
#      entry.
#
#    - The FUNCTION must be called FROM within a transaction.  It
#      returns a calling STATUS AND the Informix STATUS in the event
#      of an error.
#
#    - The FUNCTION does NOT create a REPORT.  A posting REPORT FORMAT
#      IS defined within this module but should be invoked FROM the
#      calling program AND passed each batch detail RECORD FROM the
#      actual batch created.  Note the global definitions required
#      FOR the REPORT, defined above.
#


############################################################
#FUNCTION create_jnl_batch(p_cmpy_code,
#                          p_sign_on_code,
#                          p_jour_code,
#                          p_year_num,
#                          p_period_num,
#                          p_source_ind,
#                          p_module_text,
#                          p_com1_text,
#                          p_com2_text,
#                          p_detail_req)
#
############################################################
FUNCTION create_jnl_batch(p_cmpy_code, 
	p_sign_on_code, 
	p_jour_code, 
	p_year_num, 
	p_period_num, 
	p_source_ind, 
	p_module_text, 
	p_com1_text, 
	p_com2_text, 
	p_detail_req) 

	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_jour_code LIKE batchhead.jour_code 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_period_num LIKE batchhead.period_num 
	DEFINE p_source_ind LIKE batchhead.source_ind 
	DEFINE p_module_text CHAR(16) 
	DEFINE p_com1_text LIKE batchhead.com1_text 
	DEFINE p_com2_text LIKE batchhead.com2_text 
	DEFINE p_detail_req SMALLINT 

	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_err_message CHAR(80) 

	GOTO jnl_bypass 
	LABEL jnl_status: 
	RETURN false, status, 0, l_err_message 
	LABEL jnl_bypass: 
	WHENEVER ERROR GOTO jnl_status 

	LET l_err_message = "jourfunc - updating glparms next journal number" 
	DECLARE c_glparms CURSOR FOR 
	SELECT * 
	FROM glparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = "1" 
	FOR UPDATE 
	OPEN c_glparms 
	FETCH c_glparms INTO l_rec_glparms.* 
	LET l_rec_glparms.next_jour_num = l_rec_glparms.next_jour_num + 1 
	UPDATE glparms 
	SET next_jour_num = l_rec_glparms.next_jour_num 
	WHERE cmpy_code = p_cmpy_code 
	AND key_code = '1' 
	#
	# Set up static details in batch header
	#
	LET l_rec_batchhead.cmpy_code = p_cmpy_code 
	LET l_rec_batchhead.jour_code = p_jour_code 
	LET l_rec_batchhead.jour_num = l_rec_glparms.next_jour_num 
	LET l_rec_batchhead.entry_code = p_sign_on_code 
	LET l_rec_batchhead.jour_date = today 
	LET l_rec_batchhead.year_num = p_year_num 
	LET l_rec_batchhead.period_num = p_period_num 
	LET l_rec_batchhead.control_amt = 0 
	LET l_rec_batchhead.debit_amt = 0 
	LET l_rec_batchhead.credit_amt = 0 
	LET l_rec_batchhead.for_debit_amt = 0 
	LET l_rec_batchhead.for_credit_amt = 0 
	LET l_rec_batchhead.control_qty = 0 
	LET l_rec_batchhead.stats_qty = 0 
	LET l_rec_batchhead.currency_code = l_rec_glparms.base_currency_code 
	LET l_rec_batchhead.conv_qty = 1.0 
	LET l_rec_batchhead.source_ind = p_source_ind 
	IF l_rec_glparms.use_clear_flag = "Y" THEN 
		LET l_rec_batchhead.cleared_flag = "N" 
	ELSE 
		LET l_rec_batchhead.cleared_flag = "Y" 
	END IF 
	LET l_rec_batchhead.post_flag = "N" 
	LET l_rec_batchhead.seq_num = 0 
	LET l_rec_batchhead.com1_text = p_com1_text 
	LET l_rec_batchhead.com2_text = p_com2_text 
	IF p_detail_req THEN 
		LET l_err_message = "jourfunc - Inserting batchdetl records - detail batch" 
		DECLARE c1_batchdetl CURSOR FOR 
		SELECT * 
		FROM f_batchdetl 
		FOREACH c1_batchdetl INTO l_rec_batchdetl.* 
			# Do a last minute check on sign TO trap -ve debits OR credits
			IF l_rec_batchdetl.debit_amt < 0 THEN 
				LET l_rec_batchdetl.credit_amt = 0 - l_rec_batchdetl.debit_amt 
				LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
				LET l_rec_batchdetl.for_debit_amt = 0 
			END IF 
			IF l_rec_batchdetl.credit_amt < 0 THEN 
				LET l_rec_batchdetl.debit_amt = 0 - l_rec_batchdetl.credit_amt 
				LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
				LET l_rec_batchdetl.for_credit_amt = 0 
			END IF 
			# Add TO batch header totals AND SET up next sequence
			# number AND journal number before inserting
			LET l_rec_batchhead.debit_amt = 
			l_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = 
			l_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.credit_amt = 
			l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.for_credit_amt = 
			l_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
		END FOREACH 
	ELSE 
		#
		# Set up static fields in the batch detail RECORD AND create
		# one summary entry per combination of transaction type AND
		# GL account code.  Need TO determine whether the result IS
		# a debit OR a credit
		#
		LET l_err_message = "jourfunc - Inserting batchdetl records - summary batch" 
		INITIALIZE l_rec_batchdetl.* TO NULL 
		LET l_rec_batchdetl.cmpy_code = p_cmpy_code 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.tran_date = today 
		LET l_rec_batchdetl.currency_code = l_rec_glparms.base_currency_code 
		LET l_rec_batchdetl.conv_qty = 1.0 
		LET l_rec_batchdetl.stats_qty = 0 
		LET l_rec_batchdetl.ref_text = "Summary" 
		LET l_rec_batchdetl.ref_num = 0 
		DECLARE c2_batchdetl CURSOR FOR 
		SELECT tran_type_ind, 
		acct_code, 
		sum(debit_amt), 
		sum(credit_amt) 
		FROM f_batchdetl 
		GROUP BY tran_type_ind, acct_code 
		FOREACH c2_batchdetl INTO l_rec_batchdetl.tran_type_ind, 
			l_rec_batchdetl.acct_code, 
			l_rec_batchdetl.debit_amt, 
			l_rec_batchdetl.credit_amt 
			LET l_rec_batchdetl.desc_text = 
			"Summary ",l_rec_batchdetl.tran_type_ind, " : ", 
			p_module_text clipped 
			IF l_rec_batchdetl.debit_amt > l_rec_batchdetl.credit_amt THEN 
				LET l_rec_batchdetl.debit_amt = 
				l_rec_batchdetl.debit_amt - l_rec_batchdetl.credit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
			ELSE 
				LET l_rec_batchdetl.credit_amt = 
				l_rec_batchdetl.credit_amt - l_rec_batchdetl.debit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
			END IF 
			LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
			LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
			# Add TO batch header totals AND SET up next sequence
			# number AND journal number before inserting
			# Don't INSERT zero value (NULL effect) postings
			IF l_rec_batchdetl.debit_amt <> 0 OR 
			l_rec_batchdetl.credit_amt <> 0 THEN 
				LET l_rec_batchhead.debit_amt = 
				l_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
				LET l_rec_batchhead.for_debit_amt = 
				l_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
				LET l_rec_batchhead.credit_amt = 
				l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
				LET l_rec_batchhead.for_credit_amt = 
				l_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
				LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
				LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
				LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
				INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
			END IF 
		END FOREACH 
	END IF 
	# Determine whether the batch IS in balance OR NOT.  IF NOT,
	# balance TO GL suspense
	IF l_rec_batchhead.debit_amt <> l_rec_batchhead.credit_amt THEN 
		INITIALIZE l_rec_batchdetl.* TO NULL 
		LET l_rec_batchdetl.cmpy_code = p_cmpy_code 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.tran_date = today 
		LET l_rec_batchdetl.currency_code = l_rec_glparms.base_currency_code 
		LET l_rec_batchdetl.conv_qty = 1.0 
		LET l_rec_batchdetl.stats_qty = 0 
		LET l_rec_batchdetl.tran_type_ind = "CO" 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.desc_text = p_module_text clipped, 
		" bal. suspense" 
		LET l_rec_batchdetl.acct_code = l_rec_glparms.susp_acct_code 
		IF l_rec_batchhead.debit_amt > l_rec_batchhead.credit_amt THEN 
			LET l_rec_batchdetl.credit_amt = 
			l_rec_batchhead.debit_amt - l_rec_batchhead.credit_amt 
			LET l_rec_batchdetl.debit_amt = 0 
		ELSE 
			LET l_rec_batchdetl.debit_amt = 
			l_rec_batchhead.credit_amt - l_rec_batchhead.debit_amt 
			LET l_rec_batchdetl.credit_amt = 0 
		END IF 
		LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
		LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
		LET l_rec_batchhead.debit_amt = 
		l_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
		LET l_rec_batchhead.for_debit_amt = 
		l_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
		LET l_rec_batchhead.credit_amt = 
		l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
		LET l_rec_batchhead.for_credit_amt = 
		l_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
		LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
		LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
		LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
		LET l_err_message = "jourfunc - Inserting balancing batchdetl record" 
		INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 
	END IF 
	LET l_rec_batchhead.control_amt = l_rec_batchhead.for_debit_amt 
	# Flag batch as posted IF there are no detail lines AT all - posting
	# skips these batches.
	IF l_rec_batchhead.seq_num = 0 THEN 
		LET l_rec_batchhead.post_flag = "Y" 
	END IF 
	# Not CLEAR whether the batchhead seq_num IS next sequence number
	# TO use OR last number used.  Assume the former TO keep compatible
	# with previous post version.
	LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
	LET l_err_message = "jourfunc - Inserting batchhead record" 

	CALL fgl_winmessage("3 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
	INSERT INTO batchhead VALUES (l_rec_batchhead.*) 

	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN true, 0, l_rec_batchhead.jour_num, l_err_message 
END FUNCTION 


############################################################
# REPORT post_report(p_rec_batchdetl, p_entry_code, p_year_num,
#                   p_period_num, p_curr_code, p_rpt_note)
#
#
############################################################
REPORT post_report(p_rec_batchdetl, p_entry_code, p_year_num, 
	p_period_num, p_curr_code, p_rpt_note) 

	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_entry_code LIKE batchhead.entry_code 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_period_num LIKE batchhead.period_num 
	DEFINE p_curr_code LIKE batchhead.currency_code 
	DEFINE p_rpt_note CHAR(60) 

	--	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_line2 CHAR(132) 
	DEFINE l_start_period LIKE batchhead.period_num 
	DEFINE l_end_period LIKE batchhead.period_num 
	DEFINE l_start_year LIKE batchhead.year_num 
	DEFINE l_end_year LIKE batchhead.year_num 

	DEFINE l_coa_not_found SMALLINT 
	DEFINE l_coa_not_open SMALLINT 
	DEFINE l_pr_prev_cmpy_code LIKE company.cmpy_code 

	OUTPUT 
	LEFT MARGIN 1 

	ORDER external BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.seq_num 

	FORMAT 
		PAGE HEADER 
			LET l_pr_prev_cmpy_code = glob_rec_company.cmpy_code 
			LET glob_post_rpt_wid = 132 
			LET l_line1 = today clipped, 10 spaces, glob_rec_company.cmpy_code, 
			2 spaces, glob_rec_company.name_text clipped, 10 spaces, 
			"Page :", pageno USING "####" 
			LET l_line2 = p_rpt_note clipped 
			LET l_offset1 = (glob_post_rpt_wid - length(l_line1))/2 
			LET l_offset2 = (glob_post_rpt_wid - length(l_line2))/2 
			PRINT COLUMN l_offset1, l_line1 clipped 
			PRINT COLUMN l_offset2, l_line2 clipped 
			SKIP 1 line 
			PRINT COLUMN 1, "Batch: ", 
			p_rec_batchdetl.jour_num USING "<<<<<<<<<", 
			COLUMN 18, "Year/Period: ", 
			p_year_num USING "&&&&","/", 
			p_period_num USING "<<<", 
			COLUMN 66, "Posted by: ", p_entry_code, 
			COLUMN 92, "Currency: ", p_curr_code 
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

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			# Check TO see IF the coa exists AND IS OPEN FOR this period.
			# IF NOT flag it AND PRINT MESSAGE
			LET l_coa_not_found = false 
			LET l_coa_not_open = false 
			SELECT start_year_num, 
			start_period_num, 
			end_year_num, 
			end_period_num 
			INTO l_start_year, 
			l_start_period, 
			l_end_year, 
			l_end_period 
			FROM coa 
			WHERE acct_code = p_rec_batchdetl.acct_code 
			AND cmpy_code = p_rec_batchdetl.cmpy_code 
			IF status = notfound THEN 
				LET l_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < p_year_num) OR 
				(l_end_year = p_year_num AND 
				l_end_period < p_period_num)) OR 
				((l_start_year > p_year_num) OR 
				(l_start_year = p_year_num AND 
				l_start_period > p_period_num))) THEN 
					LET l_coa_not_open = true 
				END IF 
			END IF 
			IF l_coa_not_found OR l_coa_not_open THEN 
				LET glob_invalid_acct = true 
			END IF 

			PRINT COLUMN 1, p_rec_batchdetl.seq_num USING "####", 
			COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 76, p_rec_batchdetl.credit_amt USING "-----------&.&&" 

			IF l_coa_not_found THEN 
				PRINT COLUMN 20, "** ERROR - Cannot find account : ", 
				p_rec_batchdetl.acct_code 
			END IF 
			IF l_coa_not_open THEN 
				PRINT COLUMN 20, "** ERROR - Account NOT OPEN : ", 
				p_rec_batchdetl.acct_code 
			END IF 

		AFTER GROUP OF p_rec_batchdetl.jour_num 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Batch Totals - Base Currency :", 
			COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt) 
			USING "-----------&.&&", 
			COLUMN 76, GROUP sum(p_rec_batchdetl.credit_amt) 
			USING "-----------&.&&" 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&", 
			COLUMN 76, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 

			LET glob_post_rpt_pageno = pageno 
			LET glob_post_rpt_length = 66 
			PRINT COLUMN l_offset2," ** END of ", p_rpt_note clipped, " **" 

END REPORT 



############################################################
# REPORT post_report(p_rec_batchdetl, p_entry_code, p_year_num,
#                   p_period_num, p_curr_code)
#
#
############################################################
REPORT post_report2(p_rpt_idx,p_rec_batchdetl, p_entry_code, p_year_num, 
	p_period_num, p_curr_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_entry_code LIKE batchhead.entry_code 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_period_num LIKE batchhead.period_num 
	DEFINE p_curr_code LIKE batchhead.currency_code 


	--	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_start_period LIKE batchhead.period_num 
	DEFINE l_end_period LIKE batchhead.period_num 
	DEFINE l_start_year LIKE batchhead.year_num 
	DEFINE l_end_year LIKE batchhead.year_num 

	DEFINE l_coa_not_found SMALLINT 
	DEFINE l_coa_not_open SMALLINT 
	DEFINE l_pr_prev_cmpy_code LIKE company.cmpy_code 

	OUTPUT 
--	LEFT MARGIN 1 

	ORDER external BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SKIP 1 line 
			PRINT COLUMN 1, "Batch: ", 
			p_rec_batchdetl.jour_num USING "<<<<<<<<<", 
			COLUMN 18, "Year/Period: ", 
			p_year_num USING "&&&&","/", 
			p_period_num USING "<<<", 
			COLUMN 66, "Posted by: ", p_entry_code, 
			COLUMN 92, "Currency: ", p_curr_code 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 2, "Seq", 
			COLUMN 6, "Type", 
			COLUMN 11, "Account", 
			COLUMN 30, "Description", 
			COLUMN 70, "Debit", 
			COLUMN 85, "Credit" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			# Check TO see IF the coa exists AND IS OPEN FOR this period.
			# IF NOT flag it AND PRINT MESSAGE
			LET l_coa_not_found = false 
			LET l_coa_not_open = false 
			SELECT start_year_num, 
			start_period_num, 
			end_year_num, 
			end_period_num 
			INTO l_start_year, 
			l_start_period, 
			l_end_year, 
			l_end_period 
			FROM coa 
			WHERE acct_code = p_rec_batchdetl.acct_code 
			AND cmpy_code = p_rec_batchdetl.cmpy_code 
			IF status = notfound THEN 
				LET l_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < p_year_num) OR 
				(l_end_year = p_year_num AND 
				l_end_period < p_period_num)) OR 
				((l_start_year > p_year_num) OR 
				(l_start_year = p_year_num AND 
				l_start_period > p_period_num))) THEN 
					LET l_coa_not_open = true 
				END IF 
			END IF 
			IF l_coa_not_found OR l_coa_not_open THEN 
				LET glob_invalid_acct = true 
			END IF 

			PRINT COLUMN 1, p_rec_batchdetl.seq_num USING "####", 
			COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 76, p_rec_batchdetl.credit_amt USING "-----------&.&&" 

			IF l_coa_not_found THEN 
				PRINT COLUMN 20, "** ERROR - Cannot find account : ", 
				p_rec_batchdetl.acct_code 
			END IF 
			IF l_coa_not_open THEN 
				PRINT COLUMN 20, "** ERROR - Account NOT OPEN : ", 
				p_rec_batchdetl.acct_code 
			END IF 

		AFTER GROUP OF p_rec_batchdetl.jour_num 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Batch Totals - Base Currency :", 
			COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt) 
			USING "-----------&.&&", 
			COLUMN 76, GROUP sum(p_rec_batchdetl.credit_amt) 
			USING "-----------&.&&" 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&", 
			COLUMN 76, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 