
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
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JS_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JS4_GLOBALS.4gl"

# FUNCTION inv_cred_print prints both invoices AND credits notes

DEFINE modu_tot_units LIKE invoicedetl.ship_qty  
--rpt_note LIKE rmsreps.report_text, 
--rpt_width LIKE rmsreps.report_width_num, 
--rpt_length LIKE rmsreps.page_length_num, 
--rpt_pageno LIKE rmsreps.page_num, 

###########################################################################
# PRINT invoice  ????
###########################################################################

###########################################################################
# FUNCTION JS4_rpt_process_invoice_credit(
# p_cmpy_code,p_kandoouser_sign_on_code,p_where_text_inv_text,	p_cred_text,	p_verbose_ind) 
#
#
###########################################################################
FUNCTION JS4_rpt_process_invoice_credit(
p_cmpy_code,p_kandoouser_sign_on_code,p_where_text_inv_text,	p_cred_text,	p_verbose_ind) 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	p_cmpy_code LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	p_where_text_inv_text CHAR(400), 
	p_cred_text CHAR(400), 
	pr_type_ind CHAR(1), 
	p_verbose_ind CHAR(1), 
	pr_prev_doc LIKE invoicehead.inv_num, 
	msgresp LIKE language.yes_flag, 
	pr_temp RECORD 
		cmpy_code LIKE invoicehead.cmpy_code, 
		cust_code LIKE invoicehead.cust_code, 
		doc_num LIKE invoicehead.inv_num, 
		name_text LIKE invoicehead.name_text, 
		addr1_text LIKE invoicehead.addr1_text, 
		addr2_text LIKE invoicehead.addr2_text, 
		city_text LIKE invoicehead.city_text, 
		state_code LIKE invoicehead.state_code, 
		post_code LIKE invoicehead.post_code, 
		sale_code LIKE invoicehead.sale_code, 
		job_code LIKE invoicehead.job_code, 
		ship1_text LIKE invoicehead.ship1_text, 
		ship2_text LIKE invoicehead.ship2_text, 
		prepaid_flag LIKE invoicehead.prepaid_flag, 
		ship_date LIKE invoicehead.ship_date, 
		term_code LIKE invoicehead.term_code, 
		tax_code LIKE invoicehead.tax_code, 
		currency_code LIKE invoicehead.currency_code, 
		doc_date LIKE invoicehead.inv_date, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_per LIKE invoicehead.disc_per, 
		disc_date LIKE invoicehead.disc_date, 
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		tax_amt LIKE invoicehead.tax_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		goods_amt LIKE invoicehead.goods_amt, 
		total_amt LIKE invoicehead.total_amt, 
		rev_num LIKE invoicehead.rev_num, 
		rev_date LIKE invoicehead.rev_date, 
		contract_code LIKE invoicehead.contract_code, 
		doc_ind LIKE invoicehead.inv_ind, 
		line_num LIKE invoicedetl.line_num, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		var_code LIKE invoicedetl.var_code, 
		activity_code LIKE invoicedetl.activity_code, 
		line_text CHAR(40), 
		seq_num LIKE invoicedetl.jobledger_seq_num, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		uom_code LIKE invoicedetl.uom_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		discd_amt LIKE invoicedetl.disc_amt, 
		contract_line_num LIKE invoicedetl.contract_line_num, 
		doc_total_amt LIKE invoicedetl.line_total_amt, 
		bill_issue_ind LIKE invoicehead.bill_issue_ind 
	END RECORD, 

	--rpt_wid SMALLINT, 
	row_cnt SMALLINT,
	prnt_cmpy, prnt_mess SMALLINT,
--	pr_output CHAR(50), 
	pr_printcodes RECORD LIKE printcodes.*, 
	query_text STRING 

	WHENEVER ERROR stop 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text_inv_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JS4_rpt_list_print_document",p_where_text_inv_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JS4_rpt_list_print_document TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text_inv_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JS4_rpt_list_print_document")].sel_text
	#------------------------------------------------------------


	LET modu_tot_units = 0 

	IF p_where_text_inv_text IS NOT NULL THEN #should be save to be removed
		LET pr_type_ind = "I" 
		LET query_text = 
		"SELECT ", 
		" invoicehead.cmpy_code,", 
		" invoicehead.cust_code,", 
		" invoicehead.inv_num,", 
		" invoicehead.name_text,", 
		" invoicehead.addr1_text,", 
		" invoicehead.addr2_text,", 
		" invoicehead.city_text,", 
		" invoicehead.state_code,", 
		" invoicehead.post_code,", 
		" invoicehead.sale_code,", 
		" invoicehead.job_code,", 
		" invoicehead.ship1_text,", 
		" invoicehead.ship2_text,", 
		" invoicehead.prepaid_flag,", 
		" invoicehead.ship_date,", 
		" invoicehead.term_code,", 
		" invoicehead.tax_code,", 
		" invoicehead.currency_code,", 
		" invoicehead.inv_date,", 
		" invoicehead.disc_amt,", 
		" invoicehead.disc_per,", 
		" invoicehead.disc_date,", 
		" invoicehead.com1_text,", 
		" invoicehead.com2_text,", 
		" invoicehead.tax_amt,", 
		" invoicehead.hand_amt,", 
		" invoicehead.freight_amt,", 
		" invoicehead.goods_amt,", 
		" invoicehead.total_amt,", 
		" invoicehead.rev_num,", 
		" invoicehead.rev_date,", 
		" invoicehead.contract_code,", 
		" invoicehead.inv_ind,", 
		" invoicedetl.line_num,", 
		" invoicedetl.ord_qty,", 
		" invoicedetl.ship_qty,", 
		" invoicedetl.back_qty,", 
		" invoicedetl.var_code,", 
		" invoicedetl.activity_code,", 
		" invoicedetl.line_text,", 
		" invoicedetl.jobledger_seq_num,", 
		" invoicedetl.unit_sale_amt,", 
		" invoicedetl.uom_code,", 
		" invoicedetl.ext_sale_amt,", 
		" invoicedetl.disc_amt,", 
		" invoicedetl.contract_line_num,", 
		" invoicedetl.line_total_amt,", 
		" invoicehead.bill_issue_ind ", 
		"FROM invoicehead, invoicedetl ", 
		" WHERE invoicehead.cmpy_code = \"",p_cmpy_code,"\" ", 
		"AND invoicehead.cmpy_code = invoicedetl.cmpy_code ", 
		"AND invoicehead.cust_code = invoicedetl.cust_code ", 
		"AND invoicehead.inv_num = invoicedetl.inv_num ", 
		"AND ",p_where_text_inv_text clipped," ", 
		##           "AND (invoicehead.inv_ind = '3' OR inv_ind = 'D') ",
		"ORDER BY invoicehead.inv_num, invoicedetl.activity_code, invoicedetl.line_num " 

		PREPARE s_invoice FROM query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 
		IF p_verbose_ind THEN 
			LET pr_prev_doc = 99999999 
			#         OPEN WINDOW w1 AT 12,21 with 2 rows,40 columns
			#            ATTRIBUTE(border,white)      -- alch KD-747
			LET msgresp = kandoomsg("E",1046,"") 
			#1046 Printing Invoice No:
		END IF 
		LET row_cnt = 0 
		FOREACH c_invoice INTO pr_temp.* 
			LET row_cnt = row_cnt + 1 
			OUTPUT TO REPORT JS4_rpt_list_print_document(p_cmpy_code,pr_type_ind,pr_temp.*) 
			#         MESSAGE " Reporting on Invoice Number: "
			#
			MESSAGE " Reporting on Invoice Number: ", pr_temp.doc_num 

		END FOREACH 
		IF row_cnt = 0 THEN 
			ERROR " No Invoices Selected FOR Printing" 
			SLEEP 3 
		END IF 
		IF p_verbose_ind THEN 
			#         CLOSE WINDOW w1      -- alch KD-747
		END IF 
	END IF 
	IF p_cred_text IS NOT NULL THEN 
		LET pr_type_ind = "C" 
		LET query_text = 
		"SELECT ", 
		" credithead.cmpy_code,", 
		" credithead.cust_code,", 
		" credithead.cred_num,", 
		"'',", 
		"'',", 
		"'',", 
		"'',", 
		"'',", 
		"'',", 
		" credithead.sale_code,", 
		" credithead.job_code,", 
		"'',", 
		"'',", 
		"'',", 
		"'',", 
		"'',", 
		" credithead.tax_code,", 
		" credithead.currency_code,", 
		" credithead.cred_date,", 
		"'',", 
		"'',", 
		"'',", 
		" credithead.com1_text,", 
		" credithead.com2_text,", 
		" credithead.tax_amt,", 
		" credithead.hand_amt,", 
		" credithead.freight_amt,", 
		" credithead.goods_amt,", 
		" credithead.total_amt,", 
		" credithead.rev_num,", 
		" credithead.rev_date,", 
		"'',", 
		" credithead.cred_ind,", 
		" creditdetl.line_num,", 
		"'',", 
		" creditdetl.ship_qty,", 
		"'',", 
		" creditdetl.var_code,", 
		" creditdetl.activity_code,", 
		" creditdetl.line_text,", 
		" creditdetl.jobledger_seq_num,", 
		" creditdetl.unit_sales_amt,", 
		" creditdetl.uom_code,", 
		" creditdetl.ext_sales_amt,", 
		" creditdetl.disc_amt,", 
		"'',", 
		" creditdetl.line_total_amt ", 
		"FROM credithead, creditdetl ", 
		" WHERE credithead.cmpy_code = \"",p_cmpy_code,"\" ", 
		"AND credithead.cmpy_code = creditdetl.cmpy_code ", 
		"AND credithead.cust_code = creditdetl.cust_code ", 
		"AND credithead.cred_num = creditdetl.cred_num ", 
		"AND ",p_cred_text clipped," ", 
		"ORDER BY credithead.cred_num, creditdetl.activity_code, creditdetl.line_num " 
		PREPARE s_crednote FROM query_text 
		DECLARE c_crednote CURSOR FOR s_crednote 
		IF p_verbose_ind THEN 
			LET pr_prev_doc = 99999999 
			#         OPEN WINDOW w1 AT 12,21 with 2 rows,40 columns
			#            ATTRIBUTE(border,white)      -- alch KD-747
			LET msgresp = kandoomsg("E",1046,"")		#1046 Printing Credit note No:
		END IF 

		LET row_cnt = 0 
		FOREACH c_crednote INTO pr_temp.* 
			LET row_cnt = row_cnt + 1 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT JS4_rpt_list_print_document(l_rpt_idx,
			p_cmpy_code, pr_type_ind, pr_temp.*) 
			IF NOT rpt_int_flag_handler2("Credit Note Number:",pr_temp.doc_num, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
			
		END FOREACH 

		IF row_cnt = 0 THEN 
			ERROR " No Credit Notes Selected FOR Printing" 
			SLEEP 3 
		END IF 
		--IF p_verbose_ind THEN 
		--	CLOSE WINDOW w1      -- alch KD-747
		--END IF 
	END IF 


	#------------------------------------------------------------
	FINISH REPORT JS4_rpt_list_print_document
	CALL rpt_finish("JS4_rpt_list_print_document")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION JS4_rpt_process_invoice_credit(
# p_cmpy_code,p_kandoouser_sign_on_code,p_where_text_inv_text,	p_cred_text,	p_verbose_ind) 
#
#
###########################################################################


###########################################################################
# REPORT JS4_rpt_list_print_document(p_cmpy,pr_type_ind,pr_temp) 
#
#
###########################################################################
REPORT JS4_rpt_list_print_document(p_rpt_idx,p_cmpy,pr_type_ind,pr_temp)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_type_ind CHAR(1), 
	pr_temp RECORD 
		cmpy_code LIKE invoicehead.cmpy_code, 
		cust_code LIKE invoicehead.cust_code, 
		doc_num LIKE invoicehead.inv_num, 
		name_text LIKE invoicehead.name_text, 
		addr1_text LIKE invoicehead.addr1_text, 
		addr2_text LIKE invoicehead.addr2_text, 
		city_text LIKE invoicehead.city_text, 
		state_code LIKE invoicehead.state_code, 
		post_code LIKE invoicehead.post_code, 
		sale_code LIKE invoicehead.sale_code, 
		job_code LIKE invoicehead.job_code, 
		ship1_text LIKE invoicehead.ship1_text, 
		ship2_text LIKE invoicehead.ship2_text, 
		prepaid_flag LIKE invoicehead.prepaid_flag, 
		ship_date LIKE invoicehead.ship_date, 
		term_code LIKE invoicehead.term_code, 
		tax_code LIKE invoicehead.tax_code, 
		currency_code LIKE invoicehead.currency_code, 
		doc_date LIKE invoicehead.inv_date, 
		disc_amt LIKE invoicehead.disc_amt, 
		disc_per LIKE invoicehead.disc_per, 
		disc_date LIKE invoicehead.disc_date, 
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		tax_amt LIKE invoicehead.tax_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		goods_amt LIKE invoicehead.goods_amt, 
		total_amt LIKE invoicehead.total_amt, 
		rev_num LIKE invoicehead.rev_num, 
		rev_date LIKE invoicehead.rev_date, 
		contract_code LIKE invoicehead.contract_code, 
		doc_ind LIKE invoicehead.inv_ind, 
		line_num LIKE invoicedetl.line_num, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		var_code LIKE invoicedetl.var_code, 
		activity_code LIKE invoicedetl.activity_code, 
		line_text CHAR(40), 
		seq_num LIKE invoicedetl.jobledger_seq_num, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		uom_code LIKE invoicedetl.uom_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		discd_amt LIKE invoicedetl.disc_amt, 
		contract_line_num LIKE invoicedetl.contract_line_num, 
		doc_total_amt LIKE invoicedetl.line_total_amt, 
		bill_issue_ind LIKE invoicehead.bill_issue_ind 
	END RECORD, 
	doc_cnt SMALLINT, 
	cnt, linecnt SMALLINT, 
	pr_job RECORD LIKE job.*, 
	pr_job_desc RECORD LIKE job_desc.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_actiunit RECORD LIKE actiunit.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_term RECORD 
		desc_text CHAR(25) 
	END RECORD, 
	note_mark1, note_mark2 CHAR(3), 
	pr_temp_text LIKE notes.note_code, 
	note_info CHAR(60), 
	lab_frt money(12,2), 
	pagcount INTEGER, 
	pv_tax_text CHAR(20), 
	pr_jobledger RECORD LIKE jobledger.*, 
	pv_person_code LIKE person.person_code, 
	text_ln1 CHAR(25), 
	text_ln2 CHAR(30), 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_contracthead RECORD LIKE contracthead.*, 
	inv_trans_flag CHAR(1), 
	pr_inv_num, pr_doc_num LIKE invoicedetl.inv_num, 
	pr_length SMALLINT, 
	pr_cmpy_code LIKE company.cmpy_code, 
	str STRING 

	OUTPUT 

	ORDER external BY pr_temp.doc_num, 
	pr_temp.activity_code, 
	pr_temp.line_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
		
			LET pagcount = pagcount + 1 #needs to be removed/merged
			 
			IF pr_type_ind = "C" THEN 
				SELECT credithead.* 
				INTO pr_credithead.* 
				FROM credithead 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = pr_temp.cust_code 
				AND cred_num = pr_temp.doc_num 
			ELSE 
				SELECT * 
				INTO pr_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = pr_temp.cust_code 
				AND inv_num = pr_temp.doc_num 
			END IF 

			## Get tax_text FROM table Invoicehead
			SELECT tax_text 
			INTO pv_tax_text 
			FROM company 
			WHERE cmpy_code = pr_temp.cmpy_code 
			IF pr_temp.tax_code = "NST" THEN 
				LET text_ln1 = "GST Registration Number:" 
				LET text_ln2 = pv_tax_text 
			END IF 
			IF pr_temp.tax_code = "AST" THEN 
				LET text_ln1 = "ABN 16 059 197 910" 
				LET text_ln2 = NULL 
			END IF 
			IF pr_temp.tax_code = "EX" THEN 
				LET text_ln1 = NULL 
				LET text_ln2 = NULL 
			END IF 
			IF pr_type_ind = "C" THEN 
				PRINT COLUMN 5, "Credit No. "; 
			ELSE 
				PRINT COLUMN 5, "Tax Invoice No. "; 
			END IF 
			IF pagcount > 1 THEN 
				LET text_ln1 = NULL 
				LET text_ln2 = NULL 
			END IF 
			PRINT pr_temp.doc_num USING "########", COLUMN 60,text_ln1 
			IF pr_type_ind = "C" THEN 
				PRINT COLUMN 5, "Credit Date: "; 
			ELSE 
				PRINT COLUMN 5, "Invoice Date: "; 
			END IF 
			PRINT pr_temp.doc_date, COLUMN 60, text_ln2 
			IF pagcount > 1 THEN 
				PRINT COLUMN 5, "Page :", pagcount 
			ELSE 
				PRINT 
			END IF 
			SKIP 2 LINES 

		BEFORE GROUP OF pr_temp.doc_num 
			SKIP TO top OF PAGE 
			LET pr_length = length(pr_temp.com1_text) 
			LET inv_trans_flag = false 
			LET pr_inv_num = NULL 
			LET pr_doc_num = NULL 

			#     PRINT COLUMN 5, pr_customer.name_text
			#     PRINT COLUMN 5, pr_customer.addr1_text
			#     IF pr_customer.addr2_text IS NOT NULL
			#     OR pr_temp.addr2_text IS NOT NULL THEN
			#        PRINT COLUMN 5, pr_customer.addr2_text
			#        PRINT COLUMN 5, pr_customer.city_text clipped, "  ",
			#                         pr_customer.state_code, 2 spaces,
			#                         pr_customer.post_code
			#        skip 1 line
			#     ELSE
			#        PRINT COLUMN 5, pr_customer.city_text clipped, "  ",
			#                         pr_customer.state_code,
			#               2 spaces, pr_customer.post_code
			#        skip 2 lines
			#     END IF
			#     PRINT COLUMN 5, "Attention : ", pr_customer.contact_text
			IF pr_type_ind = "I" AND pr_temp.com1_text[1,21] = "Transfered FROM Inv: " THEN 
				LET inv_trans_flag = true 
				LET pr_inv_num = pr_temp.com1_text[21,pr_length] 
			END IF 
			IF pr_type_ind = "I" AND NOT inv_trans_flag THEN 
				PRINT COLUMN 5, pr_invoicehead.name_text 
				PRINT COLUMN 5, pr_invoicehead.addr1_text 
				IF pr_invoicehead.addr2_text IS NOT NULL 
				OR pr_temp.addr2_text IS NOT NULL THEN 
					PRINT COLUMN 5, pr_invoicehead.addr2_text 
					PRINT COLUMN 5, pr_invoicehead.city_text clipped, " ", 
					pr_invoicehead.state_code, 2 spaces, 
					pr_invoicehead.post_code 
					SKIP 1 line 
				ELSE 
					PRINT COLUMN 5, pr_invoicehead.city_text clipped, " ", 
					pr_invoicehead.state_code, 
					2 spaces, pr_invoicehead.post_code 
					SKIP 2 LINES 
				END IF 
			ELSE 
				SELECT customer.* 
				INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = pr_temp.cust_code 

				PRINT COLUMN 5, pr_customer.name_text 
				PRINT COLUMN 5, pr_customer.addr1_text 
				IF pr_customer.addr2_text IS NOT NULL 
				OR pr_temp.addr2_text IS NOT NULL THEN 
					PRINT COLUMN 5, pr_customer.addr2_text 
					PRINT COLUMN 5, pr_customer.city_text clipped, " ", 
					pr_customer.state_code, 2 spaces, 
					pr_customer.post_code 
					SKIP 1 line 
				ELSE 
					PRINT COLUMN 5, pr_customer.city_text clipped, " ", 
					pr_customer.state_code, 
					2 spaces, pr_customer.post_code 
					SKIP 2 LINES 
				END IF 
			END IF
			 
			PRINT COLUMN 5, "Attention : ", pr_invoicehead.contact_text 
			SELECT term.desc_text 
			INTO pr_term.desc_text 
			FROM term 
			WHERE cmpy_code = p_cmpy 
			AND term_code = pr_temp.term_code 
			IF pr_temp.doc_ind = "D" THEN 
				SELECT * 
				INTO pr_contracthead.* 
				FROM contracthead 
				WHERE cmpy_code = p_cmpy 
				AND contract_code = pr_temp.contract_code 
			ELSE 
				LET pr_job.job_code = pr_temp.job_code[1,8] 
				SELECT * 
				INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = pr_job.job_code 
			END IF
			 
			PRINT COLUMN 5, "______________________________________________________", 
			"_______________________________"
			 
			PRINT 
			IF pr_temp.doc_ind != "1" THEN 
				PRINT COLUMN 5, "DATE"; 
				IF pr_type_ind = "I" THEN 
					PRINT COLUMN 11, "BY",COLUMN 15, "DESCRIPTION"; 
				ELSE 
					PRINT COLUMN 11, "DESCRIPTION"; 
				END IF 
			ELSE 
				PRINT COLUMN 5, "DESCRIPTION"; 
			END IF 
			PRINT COLUMN 57, "QTY", COLUMN 64, "UNIT PRICE"; 
			PRINT COLUMN 75, "TOTAL PRICE"
			 
			PRINT COLUMN 5, "______________________________________________________", 
			"_______________________________" 
			IF pr_temp.doc_ind != "1" THEN 
				PRINT COLUMN 5, "Job Code: ", pr_job.job_code, " ", pr_job.title_text 
			END IF
			 
			SKIP 1 line 



			IF pr_temp.bill_issue_ind = "3" OR 
			pr_temp.bill_issue_ind = "4" THEN 
				DECLARE c_job_desc CURSOR FOR 
				SELECT * 
				FROM job_desc 
				WHERE job_desc.cmpy_code = p_cmpy 
				AND job_desc.job_code = pr_temp.job_code 
				ORDER BY job_desc.seq_num 
				FOREACH c_job_desc INTO pr_job_desc.* 
					PRINT COLUMN 25, pr_job_desc.desc_text 
				END FOREACH 
				SKIP 1 line 
			END IF 



		BEFORE GROUP OF pr_temp.activity_code 
			SELECT * 
			INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = p_cmpy 
			AND job_code =pr_temp.job_code 
			AND var_code = pr_temp.var_code 
			AND activity_code = pr_temp.activity_code 
			IF status = 0 THEN 
				PRINT COLUMN 5, pr_activity.title_text 
			END IF
			 
		ON EVERY ROW 
			##      IF pr_temp.doc_ind = "D" THEN
			SELECT job_code 
			INTO pr_job.job_code 
			FROM contractdetl 
			WHERE cmpy_code = p_cmpy 
			AND contract_code = pr_temp.contract_code 
			AND line_num = pr_temp.contract_line_num 
			SELECT * 
			INTO pr_job.* 
			FROM job 
			WHERE cmpy_code = p_cmpy 
			AND job_code = pr_job.job_code 
			##      END IF
			IF inv_trans_flag THEN 
				LET pr_doc_num = pr_inv_num 
			ELSE 
				LET pr_doc_num = pr_temp.doc_num 
			END IF 



			#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
			#DISPLAY "see jm/JS4c.4gl" 
			#EXIT program (1) 


			LET str = 
			" SELECT distinct JL.*, TH.person_code ", 
			" FROM jobledger JL, OUTER (ts_detail TD, ts_head TH), resbill R ", 
			" WHERE R.cmpy_code = ", p_cmpy, 
			" AND R.job_code = ", pr_temp.job_code, 
			" AND R.var_code = ", pr_temp.var_code, 
			" AND R.activity_code = ",pr_temp.activity_code, 
			" AND R.inv_num = ",pr_doc_num, 
			" AND R.line_num = ", pr_temp.line_num, 
			" AND R.seq_num = ", pr_temp.seq_num, 
			" AND JL.cmpy_code = ", p_cmpy, 
			" AND JL.job_code = ", pr_temp.job_code, 
			" AND JL.var_code = ", pr_temp.var_code, 
			" AND JL.activity_code = ",pr_temp.activity_code, 
			" AND JL.seq_num = R.seq_num ", 
			" AND JL.trans_source_text = R.res_code ", 
			" AND TD.cmpy_code = ", p_cmpy, 
			" AND TD.job_code = ", pr_temp.job_code, 
			" AND TD.var_code = ", pr_temp.var_code, 
			" AND TD.activity_code = ", pr_temp.activity_code, 
			" AND TD.ts_num = JL.trans_source_num ", 
			" AND TH.ts_num = TD.ts_num " 

			PREPARE tret FROM str 
			DECLARE c_jobledger CURSOR FOR tret 


			IF pr_type_ind = "I" THEN 
				IF pr_temp.doc_ind != "1" THEN 
					FOREACH c_jobledger INTO pr_jobledger.*, pv_person_code 
						PRINT COLUMN 5, pr_jobledger.trans_date USING "dd/mm", " ", pv_person_code clipped; 
						IF NOT note_line(pr_temp.line_text) THEN 
							PRINT COLUMN 15, pr_temp.line_text clipped; 
						END IF 
						IF pr_temp.ship_qty IS NOT NULL 
						AND pr_temp.ship_qty != 0 THEN 
							PRINT COLUMN 57, pr_temp.ship_qty USING "<<<,<<&.&&" clipped, 
							COLUMN 62, pr_temp.unit_sale_amt USING "--,---,--$.&&" clipped; 
							LET modu_tot_units = modu_tot_units + pr_temp.ship_qty 
						END IF 
						PRINT COLUMN 75, pr_temp.ext_sale_amt USING "--,---,--$.&&" 
					END FOREACH 
				ELSE 
					IF NOT note_line(pr_temp.line_text) THEN 
						PRINT COLUMN 5, pr_temp.line_text clipped; 
					END IF 
					IF pr_temp.ship_qty IS NOT NULL 
					AND pr_temp.ship_qty != 0 THEN 
						PRINT COLUMN 57, pr_temp.ship_qty USING "<<<,<<&.&&" clipped, 
						COLUMN 62, pr_temp.unit_sale_amt USING "--,---,--$.&&" clipped; 
						LET modu_tot_units = modu_tot_units + pr_temp.ship_qty 
					END IF 
					PRINT COLUMN 75, pr_temp.ext_sale_amt USING "--,---,--$.&&" 
				END IF 
			ELSE 
				PRINT COLUMN 5, pr_temp.doc_date USING "dd/mm", COLUMN 15; 
				IF NOT note_line(pr_temp.line_text) THEN 
					PRINT pr_temp.line_text clipped; 
				END IF 
				IF pr_temp.ship_qty IS NOT NULL 
				AND pr_temp.ship_qty != 0 THEN 
					PRINT COLUMN 57, pr_temp.ship_qty USING "<<<,<<&.&&" clipped, 
					COLUMN 62, pr_temp.unit_sale_amt USING "--,---,--$.&&" clipped; 
					LET modu_tot_units = modu_tot_units + pr_temp.ship_qty 
				END IF 
				PRINT COLUMN 75, pr_temp.ext_sale_amt USING "--,---,--$.&&" 
			END IF 
			IF note_line(pr_temp.line_text) THEN 
				LET pr_temp_text = pr_temp.line_text[4,15] 
				DECLARE c_note CURSOR FOR 
				SELECT note_text, 
				note_num 
				INTO note_info, 
				cnt 
				FROM notes 
				WHERE cmpy_code = p_cmpy 
				AND note_code = pr_temp_text 
				ORDER BY note_num 
				SKIP 1 line 
				PRINT COLUMN 5, "NB : " 
				FOREACH c_note 
					PRINT COLUMN 5, note_info 
				END FOREACH 
			END IF 

		AFTER GROUP OF pr_temp.doc_num 
			IF pr_type_ind = "C" THEN 
				LET lab_frt = pr_credithead.freight_amt 
				+ pr_credithead.hand_amt 
				PRINT COLUMN 56, "------" 
				PRINT COLUMN 40, "Total Units", 
				COLUMN 57, modu_tot_units USING "<<<,<<&.&&" 
				SKIP 2 LINES 
				PRINT COLUMN 5, pr_temp.com1_text 
				PRINT COLUMN 48, "Freight & Handling", 
				COLUMN 75, lab_frt USING "-,---,--$.&&" 
				PRINT COLUMN 73, "--------------" 
				PRINT COLUMN 48,"Total Excl G.S.T", 
				COLUMN 73, (pr_credithead.goods_amt + 
				pr_credithead.hand_amt + 
				pr_credithead.freight_amt) USING "---,---,--$.&&" 


				PRINT COLUMN 48,"G.S.T", 
				COLUMN 73, (pr_credithead.tax_amt + 
				pr_credithead.hand_tax_amt + 
				pr_credithead.freight_tax_amt) USING "---,---,--$.&&" 

				PRINT COLUMN 73, "--------------" 
				SKIP 1 line 
				PRINT COLUMN 48,"Total Incl G.S.T ", pr_temp.currency_code, 
				COLUMN 73, pr_credithead.total_amt USING "---,---,--$.&&" 
				PRINT COLUMN 73, "==============" 
				SKIP 3 LINES 
			ELSE 
				LET lab_frt = pr_invoicehead.freight_amt 
				+ pr_invoicehead.hand_amt 
				PRINT COLUMN 56, "------" 
				PRINT COLUMN 40, "Total Units", 
				COLUMN 57, modu_tot_units USING "<<<,<<&.&&" 
				SKIP 2 LINES 
				IF pr_temp.doc_ind = "D" THEN 
					PRINT COLUMN 5, "Contract Code: ", pr_temp.contract_code, 
					COLUMN 48, "Freight & Handling", 
					COLUMN 75, lab_frt USING "-,---,--$.&&" 
				ELSE 
					PRINT COLUMN 5, pr_temp.com1_text 
					PRINT 
					PRINT COLUMN 48, "Freight & Handling", 
					COLUMN 75, lab_frt USING "-,---,--$.&&" 
				END IF 
				PRINT COLUMN 73, "--------------" 
				PRINT COLUMN 48,"Total Excl G.S.T", 
				COLUMN 73, (pr_invoicehead.goods_amt + 
				pr_invoicehead.hand_amt + 
				pr_invoicehead.freight_amt) USING "---,---,--$.&&" 


				PRINT COLUMN 48,"G.S.T", 
				COLUMN 73, (pr_invoicehead.tax_amt + 
				pr_invoicehead.hand_tax_amt + 
				pr_invoicehead.freight_tax_amt) USING "---,---,--$.&&" 

				PRINT COLUMN 73, "--------------" 
				SKIP 1 line 
				PRINT COLUMN 48,"Total Incl G.S.T ", pr_temp.currency_code, 
				COLUMN 73, pr_invoicehead.total_amt USING "---,---,--$.&&" 
				PRINT COLUMN 73, "==============" 
				SKIP 2 LINES 
				IF pr_type_ind = "I" THEN 
					PRINT COLUMN 25, "-----", "Terms : ", pr_term.desc_text,"-----" 
				END IF 
			END IF 
			LET modu_tot_units = 0 
			LET pagcount = 0 
			UPDATE invoicehead 
			SET printed_num = 3 
			WHERE cmpy_code = p_cmpy 
			AND inv_num = pr_temp.doc_num 
			
			
		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
						
END REPORT 
###########################################################################
# END REPORT JS4_rpt_list_print_document(p_cmpy,pr_type_ind,pr_temp) 
###########################################################################


###########################################################################
# FUNCTION note_line(pr_line_text) 
#
#
###########################################################################
FUNCTION note_line(pr_line_text) 
	DEFINE pr_line_text LIKE invoicedetl.line_text
	 
	IF pr_line_text[1,3] = "###" AND pr_line_text[16,18] = "###" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION note_line(pr_line_text) 
###########################################################################