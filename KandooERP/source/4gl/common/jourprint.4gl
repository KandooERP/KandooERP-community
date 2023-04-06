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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE glob_prob_found SMALLINT 
	DEFINE glob_coa_found_flag SMALLINT
END GLOBALS 
############################################################
# FUNCTION jourprint2(p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_jour_code,p_source_ind,p_currency_code,p_output,p_type)
# RETURN glob_coa_found_fla#
#
# This module "jourprint" creates a REPORT on all the accounts FROM
# the subsidiary ledgers. Just use the posting program but call
# jourprint with a different front end.
# NOTE: Duplicate of jourprint() but compatible with report 2.0
############################################################
FUNCTION jourprint2(p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_jour_code,p_source_ind,p_currency_code,p_type) 
	DEFINE p_sel_stmt CHAR (2200) 
	DEFINE p_cmpy LIKE batchhead.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code #huho a) NOT used AND b)????? now i'm getting confused.. why was this batchhead.entry_code, 
	DEFINE p_bal_rec RECORD 
				tran_type_ind LIKE batchdetl.tran_type_ind, 
				acct_code LIKE batchdetl.acct_code, 
				desc_text LIKE batchdetl.desc_text 
			END RECORD 
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_jour_code LIKE batchhead.jour_code 
	DEFINE p_source_ind LIKE batchhead.source_ind
	DEFINE p_currency_code LIKE batchhead.currency_code 
-- 	DEFINE p_output CHAR(60) 
	DEFINE p_type CHAR(4)
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_company RECORD LIKE company.* 
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
				currency_code LIKE batchdetl.currency_code, 
				conv_qty LIKE batchdetl.conv_qty, 
				tran_date DATE, 
				post_flag CHAR(1) 
			END RECORD 
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt
	DEFINE l_menu_item CHAR(3) 
	DEFINE l_next_seq INTEGER
	DEFINE l_line_count INTEGER	 
	DEFINE l_rpt_idx SMALLINT 
	
	# Determine menu path name FROM source indicator of batch
	#I don't understand this, we have got the program_id, why was it done this way ?
	CASE p_source_ind 
		WHEN ("A") 
			LET l_menu_item = "ARC" 
		WHEN ("P") 
			LET l_menu_item = "PR6" 
		WHEN ("I") 
			LET l_menu_item = "IR8" 
		OTHERWISE 
			LET l_menu_item = " " 
	END CASE 
	

	#------------------------------------------------------------
	IF (p_sel_stmt IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start("CJOURPRINT","COM_rpt_list_bdt2",p_sel_stmt, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT COM_rpt_list_bdt2 TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("COM_rpt_list_bdt2")].sel_text
	#------------------------------------------------------------

	LET l_line_count = 0 
	LET glob_prob_found = 0 
	LET glob_coa_found_flag = 1 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 
	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 

	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_2 CURSOR FOR prep_1 

	INITIALIZE l_rec_batchdetl.* TO NULL 
	FOREACH curs_2 INTO l_rec_data.* 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
		LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
		LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
		LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
		LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
		LET l_rec_batchdetl.currency_code = l_rec_data.currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
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
				LET l_rec_batchdetl.credit_amt = 0 
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

		# check that AT least one side has a value
		IF l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		THEN
			#? guess, this means NOT 
		ELSE 
			LET l_line_count = l_line_count + 1 

			#---------------------------------------------------------
			OUTPUT TO REPORT COM_rpt_list_bdt2(l_rpt_idx,
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_jour_code, 
			l_rec_data.post_flag, 
			l_rec_data.tran_date, 
			p_periods, 
			p_year_num, 
			l_menu_item, 
--			p_output, 
			p_type)  
			IF NOT rpt_int_flag_handler2("Journal Print:",l_rec_batchdetl.jour_code,l_rec_batchdetl.jour_num,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------					
		END IF
		
		INITIALIZE l_rec_batchdetl.* TO NULL 

	END FOREACH 

	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted

	IF l_line_count > 0 THEN 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = p_bal_rec.tran_type_ind 
		LET l_rec_batchdetl.acct_code = p_bal_rec.acct_code 
		LET l_rec_batchdetl.desc_text = p_bal_rec.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
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
		IF l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 THEN 
		ELSE
			#---------------------------------------------------------
			OUTPUT TO REPORT COM_rpt_list_bdt2(l_rpt_idx,
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_jour_code, 
			l_rec_data.post_flag, 
			l_rec_data.tran_date, 
			p_periods, 
			p_year_num, 
			l_menu_item, 
			p_type)  
			IF NOT rpt_int_flag_handler2("Journal Print:",l_rec_batchdetl.jour_code,l_rec_batchdetl.jour_num,l_rpt_idx) THEN
				RETURN FALSE #??? not sure false, NULL, or something else to say, CANCEL 
			END IF 
			#---------------------------------------------------------					

		END IF
	END IF 

	#------------------------------------------------------------
	FINISH REPORT COM_rpt_list_bdt2
	CALL rpt_finish("COM_rpt_list_bdt2")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN glob_coa_found_flag 
	END IF

	 
--	WHENEVER ERROR CONTINUE 

END FUNCTION # jourintf () 



############################################################
# REPORT COM_rpt_list_bdt2(p_rec_batchdetl,p_rec_company,p_jour_code,p_posted_flags,p_posted_date,p_periods,p_year_num,p_menu_item,p_output,p_type)
#
# This module "jourprint" creates a REPORT on all the accounts FROM
# the subsidiary ledgers. Just use the posting program but call
# jourprint with a different front end.
############################################################
REPORT COM_rpt_list_bdt2(p_rpt_idx,p_rec_batchdetl,p_rec_company,p_jour_code,p_posted_flags,p_posted_date,p_periods,p_year_num,p_menu_item,p_type)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE p_jour_code CHAR(3)
	DEFINE p_posted_flags CHAR(1)
	DEFINE p_posted_date DATE	
	DEFINE p_periods LIKE batchhead.period_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_menu_item CHAR(3)
--	DEFINE p_output CHAR(60)
	DEFINE p_type CHAR(4)
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_line1 NCHAR(132) 
	DEFINE l_line2 NCHAR(132) 
	DEFINE l_line3 NCHAR(132) 
	DEFINE l_rpt_note1 NCHAR(80) 
	DEFINE l_rpt_note2 NCHAR(80) 
	DEFINE l_rpt_length LIKE rmsreps.page_length_num 
--	DEFINE l_rpt_wid SMALLINT 
--	DEFINE l_offset1 SMALLINT 
--	DEFINE l_offset2 SMALLINT 
	DEFINE l_offset3 SMALLINT 
	DEFINE l_prob_message CHAR(30) 

	OUTPUT 

--	left margin 0 

	ORDER BY p_rec_batchdetl.acct_code, 
	p_rec_batchdetl.currency_code, 
	p_rec_batchdetl.jour_code, 
	p_rec_batchdetl.tran_type_ind, 
	p_rec_batchdetl.seq_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			LET l_rpt_note2 = "Year: ",p_year_num USING "####", " Period: ",p_periods USING "###" 
			CALL rpt_set_header_footer_line_2_append(p_rpt_idx,trim(l_rpt_note2),NULL)

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
--			LET l_line1 = p_rec_company.cmpy_code, 2 spaces, p_rec_company.name_text clipped 
--
--			LET l_rpt_note1 = " Subsidiary Ledger Period Posting Report ", "(Menu ", p_menu_item,")" 

--			LET l_line2 = l_rpt_note1 clipped 
--			LET l_line3 = l_rpt_note2 clipped 
--			LET l_offset1 = (l_rpt_wid - length(l_line1))/2 
--			LET l_offset2 = (l_rpt_wid - length(l_line2))/2 
--			LET l_offset3 = (l_rpt_wid - length(l_line3))/2 

--			PRINT COLUMN 1, today clipped, 
--			COLUMN rpt_get_center_start_pos(l_line1), l_line1 clipped, 
--			COLUMN (glob_rec_rmsreps.report_width_num - 9), "Page :", pageno USING "####"
			 
--			PRINT COLUMN rpt_get_center_start_pos(l_line2), l_line2 clipped 
--			PRINT COLUMN rpt_get_center_start_pos(l_line3), l_line3 clipped 



			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 6, "Description", 
				COLUMN 22, "Source", 
				COLUMN 31, "Source", 
				COLUMN 40, "Curr", 
				COLUMN 47, "Exch", 
				COLUMN 54, "---------Base Currency--------", 
				COLUMN 87, "-------Foreign Currency-------", 
				COLUMN 119, "Post", 
				COLUMN 127, "Trans" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 22, "Text", 
				COLUMN 33, "Num", 
				COLUMN 40, "Code", 
				COLUMN 47, "Rate", 
				COLUMN 61, "Debit", 
				COLUMN 78, "Credit", 
				COLUMN 95, "Debit", 
				COLUMN 111, "Credit", 
				COLUMN 119, "(?)", 
				COLUMN 128, "Date" 
			ELSE 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 10, "Source", 
				COLUMN 21, "Source", 
				COLUMN 33,"----------Base Currency---------", 
				COLUMN 70, "Post" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 10, "Text", 
				COLUMN 23, "Num", 
				COLUMN 42, "Debit", 
				COLUMN 59, "Credit", 
				COLUMN 71, "(?)" 
			END IF 

			PRINT 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			INITIALIZE l_prob_message TO NULL 
			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE

		BEFORE GROUP OF p_rec_batchdetl.acct_code 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 

			IF status = notfound THEN 
				LET glob_coa_found_flag = 0 
				LET l_rec_coa.desc_text = p_rec_batchdetl.ref_num clipped, 
				"** ERROR **" 
				LET glob_prob_found = 1 
			END IF 

			PRINT 
			COLUMN 1, "Account: ", p_rec_batchdetl.acct_code, 
			COLUMN 30, l_rec_coa.desc_text 

		ON EVERY ROW 
			IF p_posted_flags IS NULL THEN 
				LET p_posted_flags = "?" 
			END IF 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 1, p_jour_code, 
				COLUMN 6, p_rec_batchdetl.desc_text[1,15], 
				COLUMN 22, p_rec_batchdetl.ref_text[1,8] , 
				COLUMN 31, p_rec_batchdetl.ref_num USING "########", 
				COLUMN 40, p_rec_batchdetl.currency_code, 
				COLUMN 44, p_rec_batchdetl.conv_qty USING "##&.&&&", 
				COLUMN 52, p_rec_batchdetl.debit_amt 
				USING "---,---,--&.&&", 
				COLUMN 70, p_rec_batchdetl.credit_amt 
				USING "---,---,--&.&&", 
				COLUMN 86, p_rec_batchdetl.for_debit_amt 
				USING "---,---,--&.&&", 
				COLUMN 103, p_rec_batchdetl.for_credit_amt 
				USING "---,---,--&.&&", 
				COLUMN 120, p_posted_flags, 
				COLUMN 124, p_posted_date USING "dd/mm/yy" 
			ELSE 
				PRINT 
				COLUMN 1, p_jour_code, 
				COLUMN 10, p_rec_batchdetl.ref_text, 
				COLUMN 21, p_rec_batchdetl.ref_num USING "########", 
				COLUMN 33, p_rec_batchdetl.debit_amt 
				USING "---,---,--&.&&", 
				COLUMN 51, p_rec_batchdetl.credit_amt 
				USING "---,---,--&.&&", 
				COLUMN 72, p_posted_flags 
			END IF 


		AFTER GROUP OF p_rec_batchdetl.acct_code 
			NEED 3 LINES 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 49, "-----------------", 
				COLUMN 67, "-----------------" 
				PRINT 
				COLUMN 49, GROUP sum(p_rec_batchdetl.debit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 67, GROUP sum(p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 85, "Balance : ", 
				COLUMN 97, 
				GROUP sum(p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&" 
			ELSE 
				PRINT 
				COLUMN 30, "-----------------", 
				COLUMN 48, "-----------------" 
				PRINT 
				COLUMN 30, GROUP sum(p_rec_batchdetl.debit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 48, GROUP sum(p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 75, "Balance : ", 
				COLUMN 87, 
				GROUP sum(p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&" 
			END IF 

			SKIP 1 LINES 

		ON LAST ROW 
			NEED 4 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Report Totals:"; 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 49, "-----------------", 
				COLUMN 67, "-----------------" 
				PRINT 
				COLUMN 49, sum(p_rec_batchdetl.debit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 67, sum(p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&" 
			ELSE 
				PRINT 
				COLUMN 30, "-----------------", 
				COLUMN 48, "-----------------" 
				PRINT 
				COLUMN 30, sum(p_rec_batchdetl.debit_amt) 
				USING "--,---,---,--&.&&", 
				COLUMN 48, sum(p_rec_batchdetl.credit_amt) 
				USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 line 

			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 



############################################################
# FUNCTION jourprint(p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_jour_code,p_source_ind,p_currency_code,p_type)
# RETURN glob_coa_found_fla#
#
# This module "jourprint" creates a REPORT on all the accounts FROM
# the subsidiary ledgers. Just use the posting program but call
# jourprint with a different front end.
#
############################################################
FUNCTION jourprint(p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_jour_code,p_source_ind,p_currency_code,p_type) 
	DEFINE p_sel_stmt CHAR (2200) 
	DEFINE p_cmpy LIKE batchhead.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code #huho a) NOT used AND b)????? now i'm getting confused.. why was this batchhead.entry_code, 
	DEFINE p_bal_rec RECORD 
				tran_type_ind LIKE batchdetl.tran_type_ind, 
				acct_code LIKE batchdetl.acct_code, 
				desc_text LIKE batchdetl.desc_text 
			END RECORD 
	DEFINE p_periods LIKE batchhead.period_num 
	DEFINE p_year_num LIKE batchhead.year_num 
	DEFINE p_jour_code LIKE batchhead.jour_code 
	DEFINE p_source_ind LIKE batchhead.source_ind
	DEFINE p_currency_code LIKE batchhead.currency_code 
	DEFINE p_type CHAR(4)
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_company RECORD LIKE company.* 
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
				currency_code LIKE batchdetl.currency_code, 
				conv_qty LIKE batchdetl.conv_qty, 
				tran_date DATE, 
				post_flag CHAR(1) 
			END RECORD 
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt 
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt
	DEFINE l_menu_item CHAR(3) 
	DEFINE l_next_seq INTEGER
	DEFINE l_line_count INTEGER	 
	DEFINE l_rpt_idx SMALLINT 
	
	# Determine menu path name FROM source indicator of batch
	#I don't understand this, we have got the program_id, why was it done this way ?
	CASE p_source_ind 
		WHEN ("A") 
			LET l_menu_item = "ARC" 
		WHEN ("P") 
			LET l_menu_item = "PR6" 
		WHEN ("I") 
			LET l_menu_item = "IR8" 
		OTHERWISE 
			LET l_menu_item = " " 
	END CASE 

	#------------------------------------------------------------
	IF (p_sel_stmt IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start("CJOURPRINT","COM_rpt_list_bdt",p_sel_stmt, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT COM_rpt_list_bdt TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("COM_rpt_list_bdt")].sel_text
	#------------------------------------------------------------

	LET l_line_count = 0 
	LET glob_prob_found = 0 
	LET glob_coa_found_flag = 1 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 
	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 

	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_1 CURSOR FOR prep_1 

	INITIALIZE l_rec_batchdetl.* TO NULL 
	FOREACH curs_1 INTO l_rec_data.* 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
		LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
		LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
		LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
		LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
		LET l_rec_batchdetl.currency_code = l_rec_data.currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
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
				LET l_rec_batchdetl.credit_amt = 0 
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

		# check that AT least one side has a value
		IF l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		THEN
			#? guess, this means NOT 
		ELSE 
			LET l_line_count = l_line_count + 1 
			#---------------------------------------------------------
			OUTPUT TO REPORT COM_rpt_list_bdt(l_rpt_idx,
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_jour_code, 
			l_rec_data.post_flag, 
			l_rec_data.tran_date, 
			p_periods, 
			p_year_num, 
			l_menu_item, 
			p_type)  
			IF NOT rpt_int_flag_handler2("Journal Print:",l_rec_batchdetl.jour_code,l_rec_batchdetl.jour_num,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------					
		END IF
		
		INITIALIZE l_rec_batchdetl.* TO NULL 

	END FOREACH 

	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted

	IF l_line_count > 0 THEN 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_jour_code 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = p_bal_rec.tran_type_ind 
		LET l_rec_batchdetl.acct_code = p_bal_rec.acct_code 
		LET l_rec_batchdetl.desc_text = p_bal_rec.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
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
		IF l_rec_batchdetl.credit_amt = 0 
		AND l_rec_batchdetl.debit_amt = 0 
		AND l_rec_batchdetl.for_credit_amt = 0 
		AND l_rec_batchdetl.for_debit_amt = 0 THEN 
		ELSE
			#---------------------------------------------------------
			OUTPUT TO REPORT COM_rpt_list_bdt(l_rpt_idx,
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_jour_code, 
			l_rec_data.post_flag, 
			l_rec_data.tran_date, 
			p_periods, 
			p_year_num, 
			l_menu_item, 
			p_type)  
			IF NOT rpt_int_flag_handler2("Journal Print:",l_rec_batchdetl.jour_code,l_rec_batchdetl.jour_num,l_rpt_idx) THEN
				RETURN FALSE #??? not sure false, NULL, or something else to say, CANCEL 
			END IF 
			#---------------------------------------------------------					

		END IF
	END IF 

	#------------------------------------------------------------
	FINISH REPORT COM_rpt_list_bdt
	CALL rpt_finish("COM_rpt_list_bdt")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		RETURN FALSE 
	ELSE 
		RETURN glob_coa_found_flag 
	END IF

END FUNCTION # jourintf () 


############################################################
# REPORT COM_rpt_list_bdt(p_rec_batchdetl,p_rec_company,p_jour_code,p_posted_flags,p_posted_date,p_periods,p_year_num,p_menu_item,p_type)
#
# This module "jourprint" creates a REPORT on all the accounts FROM
# the subsidiary ledgers. Just use the posting program but call
# jourprint with a different front end.
############################################################
REPORT COM_rpt_list_bdt(p_rpt_idx,p_rec_batchdetl,p_rec_company,p_jour_code,p_posted_flags,p_posted_date,p_periods,p_year_num,p_menu_item,p_type)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE p_jour_code CHAR(3)
	DEFINE p_posted_flags CHAR(1)
	DEFINE p_posted_date DATE	
	DEFINE p_periods LIKE batchhead.period_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_menu_item CHAR(3)
	DEFINE p_type CHAR(4)
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_line NCHAR(132) 
	DEFINE l_rpt_note NCHAR(80) 
	DEFINE l_offset SMALLINT 
	DEFINE l_prob_message CHAR(30) 
	DEFINE stb base.StringBuffer

	ORDER BY p_rec_batchdetl.acct_code, 
	p_rec_batchdetl.currency_code, 
	p_rec_batchdetl.jour_code, 
	p_rec_batchdetl.tran_type_ind, 
	p_rec_batchdetl.seq_num 

	FORMAT 
		PAGE HEADER 
			IF pageno > 1 THEN
				SKIP 1 LINE
			END IF
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			LET l_rpt_note = "Year: ",p_year_num USING "####", " Period: ",p_periods USING "###" 
			LET stb = base.StringBuffer.Create()
			CALL stb.Append(glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2)
			CALL stb.Replace("CJOURPRINT",p_menu_item,0)
			LET glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 = stb.ToString() 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2]
			LET l_line = "Year: ",p_year_num USING "####", " Period: ",p_periods USING "###"
			LET l_offset = LENGTH(glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3)/2 - LENGTH(l_line)/2
			PRINT COLUMN l_offset, l_line CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 

			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 6, "Description", 
				COLUMN 22, "Source", 
				COLUMN 31, "Source", 
				COLUMN 40, "Curr", 
				COLUMN 47, "Exch", 
				COLUMN 54, "---------Base Currency--------", 
				COLUMN 87, "-------Foreign Currency-------", 
				COLUMN 119, "Post", 
				COLUMN 127, "Trans" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 22, "Text", 
				COLUMN 33, "Num", 
				COLUMN 40, "Code", 
				COLUMN 47, "Rate", 
				COLUMN 61, "Debit", 
				COLUMN 78, "Credit", 
				COLUMN 95, "Debit", 
				COLUMN 111, "Credit", 
				COLUMN 119, "(?)", 
				COLUMN 128, "Date" 
			ELSE 
				PRINT 
				COLUMN 1, "Jour", 
				COLUMN 10, "Source", 
				COLUMN 21, "Source", 
				COLUMN 33,"----------Base Currency---------", 
				COLUMN 70, "Post" 

				PRINT 
				COLUMN 1, "Code", 
				COLUMN 10, "Text", 
				COLUMN 23, "Num", 
				COLUMN 42, "Debit", 
				COLUMN 59, "Credit", 
				COLUMN 71, "(?)" 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			INITIALIZE l_prob_message TO NULL 
			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE

		BEFORE GROUP OF p_rec_batchdetl.acct_code 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 

			IF status = notfound THEN 
				LET glob_coa_found_flag = 0 
				LET l_rec_coa.desc_text = p_rec_batchdetl.ref_num clipped, 
				"** ERROR **" 
				LET glob_prob_found = 1 
			END IF 

			PRINT 
			COLUMN 1, "Account: ", p_rec_batchdetl.acct_code CLIPPED, 
			COLUMN 30, l_rec_coa.desc_text CLIPPED

		ON EVERY ROW 
			IF p_posted_flags IS NULL THEN 
				LET p_posted_flags = "?" 
			END IF 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 1, p_jour_code, 
				COLUMN 6, p_rec_batchdetl.desc_text[1,15], 
				COLUMN 22, p_rec_batchdetl.ref_text[1,8] , 
				COLUMN 31, p_rec_batchdetl.ref_num         USING "########", 
				COLUMN 40, p_rec_batchdetl.currency_code CLIPPED, 
				COLUMN 44, p_rec_batchdetl.conv_qty        USING "##&.&&&", 
				COLUMN 52, p_rec_batchdetl.debit_amt 		 USING "---,---,--&.&&", 
				COLUMN 70, p_rec_batchdetl.credit_amt		 USING "---,---,--&.&&", 
				COLUMN 86, p_rec_batchdetl.for_debit_amt	 USING "---,---,--&.&&", 
				COLUMN 103, p_rec_batchdetl.for_credit_amt USING "---,---,--&.&&", 
				COLUMN 120, p_posted_flags CLIPPED, 
				COLUMN 124, p_posted_date                  USING "dd/mm/yy" 
			ELSE 
				PRINT 
				COLUMN 1, p_jour_code, 
				COLUMN 10, p_rec_batchdetl.ref_text, 
				COLUMN 21, p_rec_batchdetl.ref_num         USING "########", 
				COLUMN 33, p_rec_batchdetl.debit_amt 		 USING "---,---,--&.&&", 
				COLUMN 51, p_rec_batchdetl.credit_amt 		 USING "---,---,--&.&&", 
				COLUMN 72, p_posted_flags 
			END IF 

		AFTER GROUP OF p_rec_batchdetl.acct_code 
			NEED 3 LINES 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 49, "-----------------", 
				COLUMN 67, "-----------------" 
				PRINT 
				COLUMN 49, GROUP sum(p_rec_batchdetl.debit_amt)                   USING "--,---,---,--&.&&", 
				COLUMN 67, GROUP sum(p_rec_batchdetl.credit_amt)                  USING "--,---,---,--&.&&", 
				COLUMN 85, "Balance : ", 
				COLUMN 97, 
				GROUP sum(p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt)	USING "--,---,---,--&.&&" 
			ELSE 
				PRINT 
				COLUMN 30, "-----------------", 
				COLUMN 48, "-----------------" 
				PRINT 
				COLUMN 30, GROUP sum(p_rec_batchdetl.debit_amt)       				USING "--,---,---,--&.&&", 
				COLUMN 48, GROUP sum(p_rec_batchdetl.credit_amt) 						USING "--,---,---,--&.&&", 
				COLUMN 75, "Balance : ", 
				COLUMN 87, 
				GROUP sum(p_rec_batchdetl.debit_amt - p_rec_batchdetl.credit_amt)	USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 LINES 

		ON LAST ROW 
			NEED 4 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Report Totals:"; 
			IF p_type = "FULL" THEN 
				PRINT 
				COLUMN 49, "-----------------", 
				COLUMN 67, "-----------------" 
				PRINT 
				COLUMN 49, sum(p_rec_batchdetl.debit_amt) 								USING "--,---,---,--&.&&", 
				COLUMN 67, sum(p_rec_batchdetl.credit_amt)								USING "--,---,---,--&.&&" 
			ELSE 
				PRINT 
				COLUMN 30, "-----------------", 
				COLUMN 48, "-----------------" 
				PRINT 
				COLUMN 30, sum(p_rec_batchdetl.debit_amt) 								USING "--,---,---,--&.&&", 
				COLUMN 48, sum(p_rec_batchdetl.credit_amt)								USING "--,---,---,--&.&&" 
			END IF 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT 
