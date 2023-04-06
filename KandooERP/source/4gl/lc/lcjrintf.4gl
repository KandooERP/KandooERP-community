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
GLOBALS "../common/glob_GLOBALS_report.4gl"

# Module  : jourintf.4gl (lcjrintf !!)
# Purpose : GL interface FOR S/L
#

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

GLOBALS 
	DEFINE 
	pr_batchhead RECORD LIKE batchhead.*, 
	pr_glparms RECORD LIKE glparms.*, 
	try_again CHAR(1), 
	prob_found SMALLINT, 
	coa_not_open, 
	coa_not_found SMALLINT, 
	err_message CHAR(80) 

END GLOBALS 


########################################################################
# FUNCTION lcjourintf(p_rpt_idx,sel_stmt, 
#	p_cmpy, 
#	p_kandoouser_sign_on_code, 
#	bal_rec, 
#	periods, 
#	year_num, 
#	pr_jour_code, 
#	source_ind, 
#	currency_code) 
#
#
########################################################################
FUNCTION lcjourintf (p_rpt_idx,sel_stmt, 
	p_cmpy, 
	p_kandoouser_sign_on_code, 
	bal_rec, 
	periods, 
	year_num, 
	pr_jour_code, 
	source_ind, 
	currency_code) 

	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	sel_stmt CHAR (900), 
	p_cmpy LIKE batchhead.cmpy_code, 
	p_kandoouser_sign_on_code LIKE batchhead.entry_code, 
	end_period, 
	periods LIKE batchhead.period_num, 
	end_year, 
	year_num LIKE batchhead.year_num, 
	pr_jour_code LIKE batchhead.jour_code, 
	source_ind LIKE batchhead.jour_code, 
	currency_code LIKE batchhead.currency_code, 
	bal_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		ref_num LIKE batchdetl.ref_num 
	END RECORD, 
	--pr_output CHAR(60), 
	pr_batchdetl RECORD LIKE batchdetl.*, 
	pr_data RECORD 
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
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD, 
	tot_for_debit, 
	tot_for_credit, 
	tot_base_debit, 
	tot_base_credit LIKE batchhead.debit_amt, 
	pr_company RECORD LIKE company.*, 
	next_seq, line_count SMALLINT 


	LET line_count = 0 

	LET prob_found = false 
	PREPARE prep_1 FROM sel_stmt 
	DECLARE curs_1 CURSOR FOR prep_1 

	INITIALIZE pr_batchhead.* TO NULL 
	INITIALIZE pr_batchdetl.* TO NULL 

	DECLARE c1_glparms CURSOR FOR 
	SELECT glparms.* 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = p_cmpy 
	AND glparms.key_code = "1" 
	FOR UPDATE 

	FOREACH c1_glparms 
		LET pr_glparms.next_jour_num = pr_glparms.next_jour_num + 1 
		LET err_message = " GL Parms UPDATE - jourintf.4gl " 
		UPDATE glparms 
		SET next_jour_num = next_jour_num + 1 
		WHERE CURRENT OF c1_glparms 
	END FOREACH 

	LET pr_batchhead.cmpy_code = p_cmpy 
	LET pr_batchhead.jour_code = pr_jour_code 
	LET pr_batchhead.jour_num = pr_glparms.next_jour_num 
	LET pr_batchhead.entry_code = p_kandoouser_sign_on_code 
	LET pr_batchhead.jour_date = today 
	LET pr_batchhead.year_num = year_num 
	LET pr_batchhead.period_num = periods 
	LET pr_batchhead.debit_amt = 0 
	LET pr_batchhead.credit_amt = 0 
	LET pr_batchhead.for_debit_amt = 0 
	LET pr_batchhead.for_credit_amt = 0 
	LET pr_batchhead.currency_code = currency_code 
	LET pr_batchhead.source_ind = source_ind 

	IF pr_glparms.use_clear_flag = "Y" 
	THEN 
		LET pr_batchhead.cleared_flag = "N" 
	ELSE 
		LET pr_batchhead.cleared_flag = "Y" 
	END IF 

	LET pr_batchhead.post_flag = "N" 
	LET tot_base_debit = 0 
	LET tot_base_credit = 0 

	LET tot_for_debit = 0 
	LET tot_for_credit = 0 
	LET next_seq = 1 

	FOREACH curs_1 INTO pr_data.* 

		LET pr_batchhead.conv_qty = pr_data.conv_qty 

		LET pr_batchdetl.cmpy_code = p_cmpy 
		LET pr_batchdetl.jour_code = pr_jour_code 
		LET pr_batchdetl.jour_num = pr_glparms.next_jour_num 
		LET pr_batchdetl.seq_num = next_seq 
		LET next_seq = next_seq + 1 
		LET pr_batchdetl.tran_type_ind = pr_data.tran_type_ind 
		LET pr_batchdetl.tran_date = pr_data.tran_date 
		LET pr_batchdetl.ref_num = pr_data.ref_num 
		LET pr_batchdetl.ref_text = pr_data.ref_text 
		LET pr_batchdetl.acct_code = pr_data.acct_code 
		LET pr_batchdetl.desc_text = pr_data.desc_text 
		LET pr_batchdetl.currency_code = currency_code 
		LET pr_batchdetl.conv_qty = pr_data.conv_qty 
		LET pr_batchdetl.stats_qty = pr_data.stats_qty 
		CASE 
			WHEN (pr_data.base_debit_amt > 0) 
				LET pr_batchdetl.debit_amt = pr_data.base_debit_amt 
				LET pr_batchdetl.credit_amt = 0 

			WHEN (pr_data.base_debit_amt < 0) 
				LET pr_batchdetl.credit_amt = -pr_data.base_debit_amt 
				LET pr_batchdetl.debit_amt = 0 

			WHEN (pr_data.base_credit_amt > 0) 
				LET pr_batchdetl.credit_amt = pr_data.base_credit_amt 
				LET pr_batchdetl.debit_amt = 0 

			WHEN (pr_data.base_credit_amt < 0) 
				LET pr_batchdetl.debit_amt = - pr_data.base_credit_amt 
				LET pr_batchdetl.credit_amt = 0 
		END CASE 

		CASE 
			WHEN (pr_data.for_debit_amt > 0) 
				LET pr_batchdetl.for_debit_amt = pr_data.for_debit_amt 
				LET pr_batchdetl.for_credit_amt = 0 

			WHEN (pr_data.for_debit_amt < 0) 
				LET pr_batchdetl.for_credit_amt = -pr_data.for_debit_amt 
				LET pr_batchdetl.for_debit_amt = 0 

			WHEN (pr_data.for_credit_amt > 0) 
				LET pr_batchdetl.for_credit_amt = pr_data.for_credit_amt 
				LET pr_batchdetl.for_debit_amt = 0 

			WHEN (pr_data.for_credit_amt < 0) 
				LET pr_batchdetl.for_debit_amt = - pr_data.for_credit_amt 
				LET pr_batchdetl.credit_amt = 0 
		END CASE 

		IF pr_batchdetl.debit_amt IS NULL THEN 
			LET pr_batchdetl.debit_amt = 0 
		END IF 
		IF pr_batchdetl.credit_amt IS NULL THEN 
			LET pr_batchdetl.credit_amt = 0 
		END IF 
		IF pr_batchdetl.for_debit_amt IS NULL THEN 
			LET pr_batchdetl.for_debit_amt = 0 
		END IF 
		IF pr_batchdetl.for_credit_amt IS NULL THEN 
			LET pr_batchdetl.for_credit_amt = 0 
		END IF 

		# keep totals FOR balancing
		LET tot_base_debit = tot_base_debit + pr_batchdetl.debit_amt 
		LET tot_base_credit = tot_base_credit + pr_batchdetl.credit_amt 
		LET tot_for_debit = tot_for_debit + pr_batchdetl.for_debit_amt 
		LET tot_for_credit = tot_for_credit + pr_batchdetl.for_credit_amt 
		#  increment the batch header
		LET pr_batchhead.debit_amt = pr_batchhead.debit_amt + 
		pr_batchdetl.debit_amt 
		LET pr_batchhead.credit_amt = pr_batchhead.credit_amt + 
		pr_batchdetl.credit_amt 
		LET pr_batchhead.for_debit_amt = pr_batchhead.for_debit_amt + 
		pr_batchdetl.for_debit_amt 
		LET pr_batchhead.for_credit_amt = pr_batchhead.for_credit_amt + 
		pr_batchdetl.for_credit_amt 
		# check that AT least one side has a value
		IF pr_batchdetl.debit_amt = 0 
		AND pr_batchdetl.credit_amt = 0 
		AND pr_batchdetl.for_debit_amt = 0 
		AND pr_batchdetl.for_credit_amt = 0 
		THEN 
		ELSE 
			LET line_count = line_count + 1 
			LET err_message = " Batchdetl INSERT - jourintf.4gl " 
			INSERT INTO batchdetl 
			VALUES (pr_batchdetl.*) 
		END IF 

		INITIALIZE pr_batchdetl.* TO NULL 

	END FOREACH 

	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted

	IF line_count > 0 THEN 
		LET pr_batchdetl.ref_text = " " 
		LET pr_batchdetl.ref_num = 0 
		LET pr_batchdetl.cmpy_code = p_cmpy 
		LET pr_batchdetl.jour_code = pr_jour_code 
		LET pr_batchdetl.jour_num = pr_glparms.next_jour_num 
		LET pr_batchdetl.seq_num = next_seq 
		LET next_seq = next_seq + 1 
		LET pr_batchdetl.tran_type_ind = bal_rec.tran_type_ind 
		LET pr_batchdetl.tran_date = pr_batchhead.jour_date 
		LET pr_batchdetl.acct_code = bal_rec.acct_code 
		LET pr_batchdetl.desc_text = bal_rec.desc_text 
		LET pr_batchdetl.currency_code = currency_code 
		LET pr_batchdetl.ref_num = bal_rec.ref_num 
		LET pr_batchdetl.stats_qty = 0 
		LET pr_batchdetl.debit_amt = 0 
		LET pr_batchdetl.credit_amt = 0 
		LET pr_batchdetl.for_debit_amt = 0 
		LET pr_batchdetl.for_credit_amt = 0 
		IF tot_base_debit > tot_base_credit THEN 
			LET pr_batchdetl.credit_amt = tot_base_debit - tot_base_credit 
		ELSE 
			LET pr_batchdetl.debit_amt = tot_base_credit - tot_base_debit 
		END IF 
		IF tot_for_debit > tot_for_credit THEN 
			LET pr_batchdetl.for_credit_amt = tot_for_debit - tot_for_credit 
		ELSE 
			LET pr_batchdetl.for_debit_amt = tot_for_credit - tot_for_debit 
		END IF 

		# IF balancing entry IS zero THEN dont add it TO the batch
		IF pr_batchdetl.credit_amt = 0 
		AND pr_batchdetl.debit_amt = 0 
		AND pr_batchdetl.for_credit_amt = 0 
		AND pr_batchdetl.for_debit_amt = 0 THEN 
		ELSE 
			INSERT INTO batchdetl 
			VALUES (pr_batchdetl.*) 

			#  increment the batch header
			LET pr_batchhead.debit_amt = pr_batchhead.debit_amt + 
			pr_batchdetl.debit_amt 
			LET pr_batchhead.credit_amt = pr_batchhead.credit_amt + 
			pr_batchdetl.credit_amt 
			LET pr_batchhead.for_debit_amt = 
			pr_batchhead.for_debit_amt + pr_batchdetl.for_debit_amt 
			LET pr_batchhead.for_credit_amt = 
			pr_batchhead.for_credit_amt + pr_batchdetl.for_credit_amt 
			LET pr_batchhead.seq_num = next_seq 
		END IF 
		#  INSERT batch header

		# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
		#       I)nventory AND Buy rate OTHERWISE

		IF pr_glparms.use_currency_flag = "Y" AND 
		pr_glparms.base_currency_code IS NOT NULL AND 
		pr_batchhead.currency_code IS NOT NULL AND 
		pr_batchhead.currency_code != pr_glparms.base_currency_code THEN 

			IF pr_batchhead.source_ind matches "[AJI]" THEN 
				LET pr_batchhead.rate_type_ind = "S" 
			ELSE 
				LET pr_batchhead.rate_type_ind = "B" 
			END IF 

		ELSE 
			LET pr_batchhead.rate_type_ind = " " 
		END IF 

		IF pr_batchhead.currency_code IS NULL THEN 
			CALL warning() 
		END IF 

		LET pr_batchhead.control_amt = pr_batchhead.for_debit_amt 
		CALL fgl_winmessage("25 Learning batch head codes - tell Hubert",pr_batchhead.source_ind,"info") 
		INSERT INTO batchhead 
		VALUES (pr_batchhead.*) 

		# now write the REPORT on this batch

		DECLARE detl_curs CURSOR FOR 
		SELECT * 
		INTO pr_batchdetl.* 
		FROM batchdetl 
		WHERE cmpy_code = p_cmpy 
		AND jour_code = pr_jour_code 
		AND jour_num = pr_glparms.next_jour_num 
		ORDER BY seq_num 

		SELECT company.* 
		INTO pr_company.* 
		FROM company 
		WHERE company.cmpy_code = p_cmpy 

		FOREACH detl_curs 

			#---------------------------------------------------------
			OUTPUT TO REPORT LCJRINTF_rpt_list_bdt(p_rpt_idx,		
			pr_batchdetl.*) 
			#---------------------------------------------------------

		END FOREACH 

	ELSE 
		#  nothing posted so SET the next batch number back   

		DECLARE c2_glparms CURSOR FOR 
		SELECT glparms.* 
		INTO pr_glparms.* 
		FROM glparms 
		WHERE glparms.cmpy_code = p_cmpy 
		AND glparms.key_code = "1" 
		FOR UPDATE 
		FOREACH c2_glparms 
			LET err_message = " GL Parms UPDATE - jourintf.4gl " 
			UPDATE glparms 
			SET next_jour_num = next_jour_num - 1 
			WHERE CURRENT OF c2_glparms 
		END FOREACH 
		#  RETURN 0 IF no UPDATE done
		LET pr_glparms.next_jour_num = 0 
	END IF 
	# RETURN the batch number, negative if
	#  suspense a/c used, ELSE positive
	#  this enables batch number TO be recorded on the source table
	#  IF required. Needed in purchasing TO allow FOR reconcilliation
	#  of summary batch posting
	#

	IF prob_found THEN 
		# suspense a/c used, RETURN NEGATIVE jour_num
		RETURN ( 0 - pr_glparms.next_jour_num ) 
	ELSE 
		RETURN pr_glparms.next_jour_num 
	END IF 

	WHENEVER ERROR CONTINUE 

END FUNCTION # jourintf () 



########################################################################
# FUNCTION warning()
#
#
########################################################################
FUNCTION warning() 
	DEFINE msgstr STRING 
	LET msgstr = "Rate type indicator will be updated as blank, Batch number IS:", trim(pr_batchhead.jour_num) 
	CALL fgl_winmessage("Warning",msgStr,"warning") 
	#DEFINE
	#    answ CHAR(1)

	#         #OPEN WINDOW wrn AT 5,5
	#         #with 6 rows, 35 columns
	#         #attribute (border, reverse, prompt line last)
	#
	#         DISPLAY "WARNING : Rate type indicator    "
	#             AT 1,1
	#         DISPLAY "          will be updated as     "
	#             AT 2,1
	#         DISPLAY "          blank, Batch number IS :"
	#             AT 3,1
	#         DISPLAY "         ", pr_batchhead.jour_num," "
	#             AT 4,1

	#prompt " Press any key TO continue "
	#FOR CHAR answ

	#CLOSE WINDOW wrn
END FUNCTION 


########################################################################
# REPORT LCJRINTF_rpt_list_bdt(p_rpt_idx,pr_batchdetl)
#
#
########################################################################
REPORT LCJRINTF_rpt_list_bdt(p_rpt_idx,pr_batchdetl) #REPORT LCJRINTF_rpt_list_bdt(p_rpt_idx,pr_batchdetl,pr_company)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_batchdetl RECORD LIKE batchdetl.* 
	DEFINE pr_coa RECORD LIKE coa.* 
--	pr_company RECORD LIKE company.*, 
--	line1, line2 CHAR(132), 
--	rpt_note CHAR(60), 
--	rpt_wid, offset1, offset2 SMALLINT, 
	DEFINE start_period LIKE batchhead.period_num 
	DEFINE end_period LIKE batchhead.period_num 
	DEFINE periods LIKE batchhead.period_num 
	DEFINE start_year LIKE batchhead.year_num 
	DEFINE end_year LIKE batchhead.year_num 
	DEFINE year_num LIKE batchhead.year_num 

	OUTPUT 

	ORDER external BY pr_batchdetl.jour_num, 
	pr_batchdetl.tran_type_ind, 
	pr_batchdetl.seq_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
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
			INTO pr_batchhead.* 
			FROM batchhead 
			WHERE cmpy_code = pr_batchdetl.cmpy_code 
			AND jour_num = pr_batchdetl.jour_num 
			AND jour_code = pr_batchdetl.jour_code 

			PRINT 
			COLUMN 1, "Batch: ", pr_batchdetl.jour_num 
			PRINT 
			COLUMN 5, "Date: ", pr_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", pr_batchhead.year_num, 
			COLUMN 50, "Period: ", pr_batchhead.period_num, 
			COLUMN 70, "FROM : ", pr_batchhead.entry_code, 
			COLUMN 87, "Source : ", pr_batchhead.source_ind, 
			COLUMN 101, "Currency : ", pr_batchhead.currency_code 
			PRINT 
			COLUMN 5, "Comments:", 
			COLUMN 16, pr_batchhead.com1_text 
			PRINT 
			COLUMN 5, "Comments :", 
			COLUMN 16, pr_batchhead.com2_text 

		ON EVERY ROW 

			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES

			# check that chart number IS valid AND live
			LET coa_not_found = false 
			LET coa_not_open = false 

			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO start_year,start_period,end_year,end_period 
			FROM coa 
			WHERE cmpy_code = pr_batchdetl.cmpy_code 
			AND acct_code = pr_batchdetl.acct_code 

			IF status THEN 
				LET coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((end_year < pr_batchhead.year_num) OR 
				(end_year = pr_batchhead.year_num AND 
				end_period <= pr_batchhead.period_num)) OR 
				((start_year > pr_batchhead.year_num) OR 
				(start_year = pr_batchhead.year_num AND 
				start_period >= pr_batchhead.period_num))) THEN 
					LET coa_not_open = true 
				END IF 
			END IF 

			IF coa_not_found OR coa_not_open THEN 
				LET prob_found = true 
			END IF 

			PRINT 
			COLUMN 1, pr_batchdetl.seq_num USING "####", 
			COLUMN 6 , pr_batchdetl.tran_type_ind, 
			COLUMN 11, pr_batchdetl.acct_code , 
			COLUMN 30, pr_batchdetl.desc_text, 
			COLUMN 60, pr_batchdetl.debit_amt, 
			COLUMN 75, pr_batchdetl.credit_amt, 
			COLUMN 90, pr_batchdetl.for_debit_amt, 
			COLUMN 105, pr_batchdetl.for_credit_amt, 
			COLUMN 111, pr_batchdetl.conv_qty USING "-----&.&&&&" 

			# IF coa IS bad THEN change it TO the suspense account AND PRINT the error

			IF coa_not_found THEN 
				PRINT COLUMN 20, "** FIND ERROR - Suspense Account will be used : ", 
				pr_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Cannot find account : ",pr_batchdetl.acct_code 
			END IF 
			IF coa_not_open THEN 
				PRINT COLUMN 20, "** OPEN ERROR - Suspense Account will be used : ", 
				pr_batchdetl.ref_num clipped 
				PRINT COLUMN 20, "Account NOT OPEN : ",pr_batchdetl.acct_code 
			END IF 

		BEFORE GROUP OF pr_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT 
			COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(pr_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT 
			COLUMN 75, sum(pr_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]



END REPORT 

