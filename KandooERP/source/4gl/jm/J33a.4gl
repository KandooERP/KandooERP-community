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
GLOBALS "../jm/J3_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J33_GLOBALS.4gl"
###########################################################################
# Purpose - Print Job Invoice.
#           The same as an ar invoice except FOR the detail line
#           FUNCTION in_cr_print prints only invoices
###########################################################################
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_temp RECORD 
	cust_code LIKE invoicehead.cust_code, 
	inv_num LIKE invoicehead.inv_num, 
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
	inv_date LIKE invoicehead.inv_date, 
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
	inv_ind LIKE invoicehead.inv_ind, 
	line_num LIKE invoicedetl.line_num, 
	ord_qty LIKE invoicedetl.ord_qty, 
	ship_qty LIKE invoicedetl.ship_qty, 
	back_qty LIKE invoicedetl.back_qty, 
	var_code LIKE invoicedetl.var_code, 
	activity_code LIKE invoicedetl.activity_code, 
	line_text CHAR(30), 
	unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
	uom_code LIKE invoicedetl.uom_code, 
	ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
	discd_amt LIKE invoicedetl.disc_amt, 
	contract_line_num LIKE invoicedetl.contract_line_num 
END RECORD 

DEFINE modu_comp_on CHAR(30) 
DEFINE modu_file_name CHAR(30) 
DEFINE modu_row_cnt, modu_prnt_cmpy, modu_prnt_mess SMALLINT 
DEFINE modu_rec_invoicehead RECORD LIKE invoicehead.* 
DEFINE modu_rec_contracthead RECORD LIKE contracthead.* 
DEFINE modu_query_text CHAR(1000) 

###########################################################################
# FUNCTION jm_inv_print(p_rec_prnt_optns)
#
#
###########################################################################
FUNCTION jm_inv_print(p_rec_prnt_optns) 
	DEFINE p_rec_prnt_optns RECORD 
		cmpy_prnt CHAR(1), 
		docm_prnt CHAR(1), 
		prt_message CHAR(1), 
		start_inv INTEGER, 
		end_inv INTEGER 
	END RECORD 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	#------------------------------------------------------------
{
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
}
	LET l_rpt_idx = rpt_start(getmoduleid(),"J33_rpt_list_invoicer","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J33_rpt_list_invoicer TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	SELECT * 
	INTO glob_rec_usermsg.* 
	FROM usermsg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF p_rec_prnt_optns.prt_message = "Y" THEN 
		LET modu_prnt_mess = true 
	ELSE 
		LET modu_prnt_mess= false 
	END IF 

	IF p_rec_prnt_optns.cmpy_prnt = "Y" THEN 
		LET modu_prnt_cmpy = true 
	ELSE 
		LET modu_prnt_cmpy = false 
	END IF 

	IF p_rec_prnt_optns.docm_prnt = "N" THEN 
		LET modu_query_text = 
		"SELECT", 
		" I.cust_code,", 
		" I.inv_num,", 
		" I.name_text,", 
		" I.addr1_text,", 
		" I.addr2_text,", 
		" I.city_text,", 
		" I.state_code,", 
		" I.post_code,", 
		" I.sale_code,", 
		" I.job_code,", 
		" I.ship1_text,", 
		" I.ship2_text,", 
		" I.prepaid_flag,", 
		" I.ship_date,", 
		" I.term_code,", 
		" I.inv_date,", 
		" I.disc_amt,", 
		" I.disc_per,", 
		" I.disc_date,", 
		" I.com1_text,", 
		" I.com2_text,", 
		" I.tax_amt,", 
		" I.hand_amt,", 
		" I.freight_amt,", 
		" I.goods_amt,", 
		" I.total_amt,", 
		" I.rev_num,", 
		" I.rev_date,", 
		" I.contract_code,", 
		" I.inv_ind,", 
		" L.line_num,", 
		" L.ord_qty,", 
		" L.ship_qty,", 
		" L.back_qty,", 
		" L.var_code,", 
		" L.activity_code,", 
		" L.line_text,", 
		" L.unit_sale_amt,", 
		" L.uom_code,", 
		" L.ext_sale_amt,", 
		" L.disc_amt,", 
		" L.contract_line_num ", 
		"FROM invoicehead I, invoicedetl L", 
		" WHERE I.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND I.cmpy_code = L.cmpy_code ", 
		"AND I.cust_code = L.cust_code ", 
		"AND I.inv_num = L.inv_num ", 
		"AND I.inv_num >= \"",p_rec_prnt_optns.start_inv,"\" ", 
		"AND I.inv_num <= \"",p_rec_prnt_optns.end_inv,"\" ", 
		"AND (I.inv_ind = '3' OR I.inv_ind = 'D') ", 
		"AND I.printed_num < 2 ", 
		"ORDER BY I.inv_num, L.line_num " 
	ELSE 
		LET modu_query_text = 
		"SELECT ", 
		" I.cust_code,", 
		" I.inv_num,", 
		" I.name_text,", 
		" I.addr1_text,", 
		" I.addr2_text,", 
		" I.city_text,", 
		" I.state_code,", 
		" I.post_code,", 
		" I.sale_code,", 
		" I.job_code,", 
		" I.ship1_text,", 
		" I.ship2_text,", 
		" I.prepaid_flag,", 
		" I.ship_date,", 
		" I.term_code,", 
		" I.inv_date,", 
		" I.disc_amt,", 
		" I.disc_per,", 
		" I.disc_date,", 
		" I.com1_text,", 
		" I.com2_text,", 
		" I.tax_amt,", 
		" I.hand_amt,", 
		" I.freight_amt,", 
		" I.goods_amt,", 
		" I.total_amt,", 
		" I.rev_num,", 
		" I.rev_date,", 
		" I.contract_code,", 
		" I.inv_ind,", 
		" L.line_num,", 
		" L.ord_qty,", 
		" L.ship_qty,", 
		" L.back_qty,", 
		" L.var_code,", 
		" L.activity_code,", 
		" L.line_text,", 
		" L.unit_sale_amt,", 
		" L.uom_code,", 
		" L.ext_sale_amt,", 
		" L.disc_amt,", 
		" L.contract_line_num ", 
		"FROM invoicehead I, invoicedetl L", 
		" WHERE I.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND I.cmpy_code = L.cmpy_code ", 
		"AND I.cust_code = L.cust_code ", 
		"AND I.inv_num = L.inv_num ", 
		"AND I.inv_num >= \"",p_rec_prnt_optns.start_inv,"\" ", 
		"AND I.inv_num <= \"",p_rec_prnt_optns.end_inv,"\" ", 
		"AND (I.inv_ind = '3' OR inv_ind = 'D') ", 
		"ORDER BY I.inv_num, L.line_num " 
	END IF 

	PREPARE invoice FROM modu_query_text 
	DECLARE ninvs CURSOR FOR invoice 

{
	CALL upd_rms(glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	" ", 
	glob_rec_rmsreps.report_width_num, 
	"AS1", 
	"JM Invoices") 
	RETURNING pr_output 
}
	
	LET modu_row_cnt = 0 

	FOREACH ninvs INTO modu_rec_temp.* 
		LET modu_row_cnt = modu_row_cnt + 1
		#---------------------------------------------------------
		OUTPUT TO REPORT J33_rpt_list_invoicer(l_rpt_idx,
		modu_row_cnt, modu_rec_temp.*)  
		IF NOT rpt_int_flag_handler2("Invoice:",modu_rec_temp.inv_num , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 

	END FOREACH 

	IF modu_row_cnt = 0 THEN 
		ERROR " No Invoices Selected FOR Printing" 
		SLEEP 3 
	END IF 


	#------------------------------------------------------------
	FINISH REPORT J33_rpt_list_invoicer
	CALL rpt_finish("J33_rpt_list_invoicer")
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
# END FUNCTION jm_inv_print(p_rec_prnt_optns)
#
#
###########################################################################


###########################################################################
# FUNCTION note_line(p_line_text)
#
#
###########################################################################
FUNCTION note_line(p_line_text) 
	DEFINE p_line_text LIKE invoicedetl.line_text 

	IF p_line_text[1,3] = "###" 

	AND p_line_text[16,18] = "###" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 
###########################################################################
# FUNCTION note_line(l_line_text)
###########################################################################

###########################################################################
# REPORT J33_rpt_list_invoicer(p_inv_cnt, p_rec_temp)
#
#
###########################################################################
REPORT J33_rpt_list_invoicer(p_rpt_idx,p_inv_cnt, p_rec_temp)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_inv_cnt SMALLINT 
	DEFINE p_rec_temp RECORD 
		cust_code LIKE invoicehead.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
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
		inv_date LIKE invoicehead.inv_date, 
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
		inv_ind LIKE invoicehead.inv_ind, 
		line_num LIKE invoicedetl.line_num, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		var_code LIKE invoicedetl.var_code, 
		activity_code LIKE invoicedetl.activity_code, 
		line_text CHAR(30), 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		uom_code LIKE invoicedetl.uom_code, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		discd_amt LIKE invoicedetl.disc_amt, 
		contract_line_num LIKE invoicedetl.contract_line_num 
	END RECORD 

	DEFINE l_cnt SMALLINT 
	DEFINE l_linecnt SMALLINT	
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_actiunit RECORD LIKE actiunit.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
--	DEFINE l_rec_contractdetl RECORD LIKE contractdetl.* 
	DEFINE l_rec_term RECORD 
		desc_text CHAR(20) 
	END RECORD 
--	DEFINE l_note_mark1, l_note_mark2 CHAR(3)
	DEFINE l_temp_text LIKE notes.note_code 
	DEFINE l_note_info CHAR(60) 
	DEFINE l_lab_frt money(12,2) 
	DEFINE l_pagcount INTEGER 
	DEFINE l_str STRING --CHAR(2000) 


	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 66 
	ORDER external BY p_rec_temp.inv_num,p_rec_temp.line_num 

	FORMAT 
		BEFORE GROUP OF p_rec_temp.inv_num 
			SKIP TO top OF PAGE 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			
			 

		
			LET l_pagcount = l_pagcount + 1 
			--SKIP 1 line 

			IF modu_prnt_cmpy THEN 
				PRINT COLUMN 10, glob_rec_company.name_text clipped 
				PRINT COLUMN 10, glob_rec_company.addr1_text 

				IF glob_rec_company.addr2_text IS NOT NULL THEN 
					PRINT COLUMN 10, glob_rec_company.addr2_text 
				ELSE 
					SKIP 1 line 
				END IF 

				PRINT COLUMN 10, glob_rec_company.city_text clipped, " ", 
				glob_rec_company.state_code, " ", 
				glob_rec_company.post_code clipped 
				PRINT COLUMN 10, glob_rec_company.tele_text 
			ELSE 
				SKIP 5 LINES 
			END IF 

			SKIP 1 line 

			SELECT customer.* 
			INTO l_rec_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_temp.cust_code 

			IF p_rec_temp.ship1_text = "Credit" THEN 
				############## Code relates TO the future implementation
				############## of JM Credit Note Print
				#        SELECT credithead.*
				#           INTO pr_credithead.*
				#           FROM credithead
				#           WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#             AND cust_code = p_rec_temp.cust_code
				#             AND cred_num = p_rec_temp.inv_num
			ELSE 
				SELECT * 
				INTO modu_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_temp.cust_code 
				AND inv_num = p_rec_temp.inv_num 
			END IF 

			PRINT COLUMN 10, "Invoice No. ",p_rec_temp.inv_num USING "########" 
			PRINT COLUMN 10, "Invoice Date: ",	p_rec_temp.inv_date USING "ddd dd mmm yy" 
			SKIP 4 LINES 
			PRINT COLUMN 10, l_rec_customer.name_text, 
			COLUMN 44, p_rec_temp.name_text 
			PRINT COLUMN 10, l_rec_customer.addr1_text, 
			COLUMN 44, p_rec_temp.addr1_text 

			IF l_rec_customer.addr2_text IS NOT NULL 
			OR p_rec_temp.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 10, l_rec_customer.addr2_text, 
				COLUMN 44, p_rec_temp.addr2_text 
				PRINT COLUMN 10, l_rec_customer.city_text clipped, " ", 
				l_rec_customer.state_code, 2 spaces, 
				l_rec_customer.post_code, 
				COLUMN 44, p_rec_temp.city_text clipped, " ", 
				p_rec_temp.state_code, 
				2 spaces, p_rec_temp.post_code 
				SKIP 1 line 
			ELSE 
				PRINT COLUMN 10, l_rec_customer.city_text clipped, " ", 
				l_rec_customer.state_code, 
				2 spaces, l_rec_customer.post_code, 
				COLUMN 44, p_rec_temp.city_text clipped, " ", 
				p_rec_temp.state_code, 
				2 spaces, p_rec_temp.post_code 
				SKIP 2 LINES 
			END IF 

			SELECT term.desc_text 
			INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = p_rec_temp.term_code 

			IF modu_prnt_mess THEN 
				PRINT COLUMN 10, glob_rec_usermsg.line1_text[1,58] clipped 
				PRINT COLUMN 10, glob_rec_usermsg.line2_text[1,58] clipped 
			ELSE 
				SKIP 2 LINES 
			END IF 

			IF p_rec_temp.inv_ind = "D" THEN 
				SELECT * 
				INTO modu_rec_contracthead.* 
				FROM contracthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND contract_code = p_rec_temp.contract_code 

				SKIP 2 LINES 
				PRINT COLUMN 3, "Contract: ", modu_rec_contracthead.desc_text, 
				COLUMN 60, "Page: ", l_pagcount USING "###" 
				SKIP 3 LINES 
			ELSE 

				LET l_rec_job.job_code = p_rec_temp.job_code[1,8] 

				SELECT * 
				INTO l_rec_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = l_rec_job.job_code 

				SKIP 2 LINES 

				PRINT COLUMN 8, "Job: ", l_rec_job.title_text, 
				COLUMN 60, "Page: ", l_pagcount USING "###" 
				SKIP 3 LINES 
			END IF 

		ON EVERY ROW 

			IF p_rec_temp.inv_ind = "D" THEN 
				SELECT job_code 
				INTO l_rec_job.job_code 
				FROM contractdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND contract_code = p_rec_temp.contract_code 
				AND line_num = p_rec_temp.contract_line_num 

				SELECT * 
				INTO l_rec_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = l_rec_job.job_code 
			END IF 


			IF note_line(p_rec_temp.line_text) THEN 

				LET l_temp_text = p_rec_temp.line_text[4,15] 

				DECLARE c_note CURSOR FOR 
				SELECT note_text, note_num 
				INTO l_note_info, l_cnt 
				FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = l_temp_text 
				ORDER BY note_num 

				FOREACH c_note 
					PRINT COLUMN 8, l_note_info 
				END FOREACH 
			ELSE 
				LET l_rec_activity.activity_code = p_rec_temp.activity_code[1,8] 


				DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
				DISPLAY "see jm/J33a.4gl" 
				EXIT program (1) 

				LET l_str = 
				" SELECT activity.*, ", 
				" jobvars.* ", 
				" INTO l_rec_activity.*, ", 
				" l_rec_jobvars.* ", 
				" FROM activity, ", 
				" outer jobvars ", 
				" WHERE activity.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
				" AND activity.job_code = ", l_rec_job.job_code, 
				" AND activity.var_code = ", p_rec_temp.var_code, 
				" AND activity.activity_code = ", l_rec_activity.activity_code, 
				" AND jobvars.cmpy_code = activity.cmpy_code ", 
				" AND jobvars.job_code = activity.job_code ", 
				" AND jobvars.var_code = activity.var_code " 

				EXECUTE immediate l_str 

				IF status = notfound THEN 
					SKIP 1 line 

					PRINT COLUMN 8, p_rec_temp.line_text; 


					IF p_rec_temp.inv_ind = "D" 
					AND p_rec_temp.var_code IS NULL THEN 
						IF p_rec_temp.ship_qty IS NOT NULL 
						AND p_rec_temp.ship_qty != 0 THEN 
							PRINT COLUMN 50, p_rec_temp.ext_sale_amt/p_rec_temp.ship_qty 
							USING "-,---,--$.&&"; 
						END IF 

						PRINT COLUMN 65, p_rec_temp.ext_sale_amt USING "-,---,--$.&&" 
					ELSE 
						PRINT 
					END IF 

				ELSE 
					IF l_rec_jobvars.title_text IS NOT NULL THEN 
						SKIP 1 line 
						PRINT COLUMN 8, "Variation: ", l_rec_jobvars.title_text 
					END IF 

					PRINT COLUMN 8, p_rec_temp.line_text; 

					IF p_rec_temp.ship_qty IS NOT NULL 
					AND p_rec_temp.ship_qty != 0 THEN 
						PRINT COLUMN 50, p_rec_temp.ext_sale_amt/p_rec_temp.ship_qty 
						USING "-,---,--$.&&"; 
					END IF 

					PRINT COLUMN 65, p_rec_temp.ext_sale_amt USING "-,---,--$.&&" 
				END IF 
			END IF 

			SKIP 1 line 

		AFTER GROUP OF p_rec_temp.inv_num 
			IF p_rec_temp.ship1_text = "Credit" THEN 
				############## Code relates TO the future implementation
				############## of JM Credit Note Print
				#        LET l_lab_frt = pr_credithead.freight_amt
				#                    + pr_credithead.hand_amt
				#        skip 2 lines
				#        PRINT COLUMN 32, pr_credithead.job_code,
				#              COLUMN 61, pr_credithead.tax_amt
				#                         using "-,---,--$.&&"
				#        skip 1 line
				#        PRINT COLUMN 32, l_rec_customer.tax_num_text,
				#              COLUMN 61, l_lab_frt using "-,---,--$.&&"
				#        skip 1 line
				#        PRINT COLUMN 25, l_rec_term.desc_text,
				#              COLUMN 61, pr_credithead.total_amt
				#                         using "-,---,--$.&&"
				SKIP 9 LINES 
			ELSE 
				LET l_lab_frt = modu_rec_invoicehead.freight_amt 
				+ modu_rec_invoicehead.hand_amt 
				SKIP 5 LINES 


				IF p_rec_temp.inv_ind = "D" THEN 
					PRINT COLUMN 15, "Contract Code: ", p_rec_temp.contract_code, 
					COLUMN 50, "Frght & Hndlng", 
					COLUMN 65, l_lab_frt USING "-,---,--$.&&" 
				ELSE 

					PRINT COLUMN 15, "Job Code: ", l_rec_job.job_code, 
					COLUMN 50, "Frght & Hndlng", 
					COLUMN 65, l_lab_frt USING "-,---,--$.&&" 
				END IF 

				PRINT COLUMN 15,"Job Code: ", l_rec_job.job_code, 
				COLUMN 50,"Frght & Hndlng", 
				COLUMN 65, l_lab_frt USING "-,---,--$.&&" 

				SKIP 1 line 
				PRINT COLUMN 15,"Tax Number:", l_rec_customer.tax_num_text, 
				COLUMN 50,"Tax Amount", 
				COLUMN 65, modu_rec_invoicehead.tax_amt USING "-,---,--$.&&" 
				SKIP 1 line 
				PRINT COLUMN 15,"Terms: ", l_rec_term.desc_text, 
				COLUMN 50,"Total Amount", 
				COLUMN 65, modu_rec_invoicehead.total_amt USING "-,---,--$.&&" 
				SKIP 2 LINES 
			END IF 

			LET l_pagcount = 0 

			UPDATE invoicehead 
			SET printed_num = 3 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = p_rec_temp.inv_num 

			PAGE TRAILER 
				SKIP 2 LINES 

END REPORT 
###########################################################################
# END REPORT J33_rpt_list_invoicer(p_inv_cnt, p_rec_temp)
#
#
###########################################################################