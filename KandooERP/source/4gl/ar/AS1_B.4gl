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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS1_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_nrof_detlines SMALLINT 
DEFINE modu_rec_print array[4] OF RECORD 
	msg_text NCHAR(70) 
END RECORD 
DEFINE modu_arr_rec_tax array[4] OF RECORD 
	tax_code LIKE invoicedetl.tax_code, 
	tax_per LIKE tax.tax_per, 
	gross_amt LIKE invoicedetl.line_total_amt, 
	tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 
DEFINE modu_arr_rec_tax2 array[4] OF RECORD 
	tax_code LIKE invoicedetl.tax_code, 
	tax_per LIKE tax.tax_per, 
	gross_amt LIKE invoicedetl.line_total_amt, 
	tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 

################################################################################
# FUNCTION AS1_rpt_process_invoice_credit(glob_rec_company.cmpy_code,p_kandoouser_sign_on_code,l_inv_text, l_cred_text, p_verbose_ind,l_inv_printer)
# RETURN TRUE/FALSE
# PRINT invoice
# Plain Paper Invoice Print - Generic
# FUNCTION inv_cred_print prints both invoices AND credits notes
#      Custom invoice/credit note PRINT FUNCTION
################################################################################
FUNCTION AS1_rpt_process_invoice_credit(p_where_text) #(l_inv_text,	l_cred_text, p_verbose_ind, l_inv_printer) 
--	DEFINE glob_rec_company.cmpy_code LIKE company.cmpy_code 
--	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_where_text STRING
	DEFINE p_verbose_ind CHAR(1)
	DEFINE l_inv_text STRING  #where selector for invoice
	DEFINE l_cred_text STRING #where selector for credit
	 
	DEFINE l_inv_printer LIKE printcodes.print_code #may be no longer used 
	DEFINE l_type_ind CHAR(1) 
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* #no longer used
	DEFINE l_query_text STRING 

#	DEFINE l_rec_dochead OF dt_rec_dochead
#	DEFINE l_rec_docdetl OF dt_rec_docdetl	
	
	DEFINE l_rec_dochead RECORD 
		doc_type CHAR(1), 
		cmpy_code LIKE invoicehead.cmpy_code, 
		doc_num LIKE invoicehead.inv_num, 
		doc_ind LIKE invoicehead.inv_ind, 
		cust_code LIKE invoicehead.cust_code, 
		org_cust_code LIKE invoicehead.org_cust_code, 
		doc_date LIKE invoicehead.inv_date, 
		cond_code LIKE invoicehead.cond_code, 
		tax_code LIKE invoicehead.tax_code, 
		carrier_code LIKE invoicehead.carrier_code, 
		term_code LIKE invoicehead.term_code, 
		territory_code LIKE invoicehead.territory_code, 
		sale_code LIKE invoicehead.sale_code, 
		ord_num LIKE invoicehead.ord_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		goods_amt LIKE invoicehead.goods_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		total_amt LIKE invoicehead.total_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		hand_tax_amt LIKE invoicehead.hand_tax_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		freight_tax_amt LIKE invoicehead.freight_tax_amt, 
		invoice_to_ind LIKE invoicehead.invoice_to_ind, 
		name_text LIKE invoicehead.name_text, 
		addr1_text LIKE invoicehead.addr1_text, 
		addr2_text LIKE invoicehead.addr2_text, 
		city_text LIKE invoicehead.city_text, 
		state_code LIKE invoicehead.state_code, 
		post_code LIKE invoicehead.post_code, 
		country_code LIKE invoicehead.country_code, --@db-patch_2020_10_04--
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		conv_qty LIKE invoicehead.conv_qty,
		printed_num LIKE invoicehead.printed_num  
	END RECORD 
	DEFINE l_rec_docdetl RECORD 
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		order_num LIKE invoicedetl.order_num, 
		offer_code LIKE invoicedetl.offer_code, 
		tax_code LIKE invoicedetl.tax_code, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		unit_tax_amt LIKE invoicedetl.unit_tax_amt, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		sold_qty LIKE invoicedetl.sold_qty, 
		line_text LIKE invoicedetl.line_text, 
		ware_code LIKE invoicedetl.ware_code, 
		level_code LIKE invoicedetl.level_code, 
		disc_amt LIKE invoicedetl.disc_amt 
	END RECORD 

	DEFINE l_prev_doc LIKE invoicehead.inv_num 
	--DEFINE l_days_num LIKE termdetl.days_num 
	--DEFINE l_disc_per LIKE termdetl.disc_per 
	--DEFINE l_disc_amt LIKE invoicehead.disc_amt 
	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_select RECORD #Note: It seems, this is no longer required 4.6.2020 (if it's still the case in 6 months, remove anything with this varible record 
		inv_flag NCHAR(1), 
		inv_start_num LIKE invoicehead.inv_num, 
		inv_last_num LIKE invoicehead.inv_num, 
		inv_start_date LIKE invoicehead.inv_date, 
		inv_last_date LIKE invoicehead.inv_date, 
		inv_start_cust LIKE invoicehead.cust_code, 
		inv_last_cust LIKE invoicehead.cust_code, 
		inv_prev_prnt_ind CHAR(1), 
		inv_ind LIKE invoicehead.inv_ind, 
		cred_flag CHAR(1), 
		cred_start_num LIKE credithead.cred_num, 
		cred_last_num LIKE credithead.cred_num, 
		cred_start_date LIKE credithead.cred_date, 
		cred_last_date LIKE credithead.cred_date, 
		cred_start_cust LIKE credithead.cust_code, 
		cred_last_cust LIKE credithead.cust_code, 
		cred_prev_prnt_ind CHAR(1), 
		cred_ind LIKE credithead.cred_ind 
	END RECORD 
	
	IF get_debug() THEN 
		DISPLAY "DEBUG" 
		DISPLAY "FUNCTION AS1_rpt_process_invoice_credit()" 
		DISPLAY "l_inv_text=", l_inv_text 
		DISPLAY "arg3 = l_inv_text = ", l_inv_text 
		DISPLAY "arg4 = l_cred_text = ", l_cred_text 
		DISPLAY "arg5 = p_verbose_ind = ", p_verbose_ind 
--		DISPLAY "arg6 = l_inv_printer = ", l_inv_printer 
	END IF 

	#Original code.. but really not sure if we will keep this
	LET p_verbose_ind = FALSE #This was hard coded in original kandoo argument
	SELECT rmsparm.inv_print_text INTO l_inv_printer FROM rmsparm 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("Missing Printer Configuration",kandoomsg2("E",5008,""),"ERROR")	#5008 Print Parameters NOT SET up
		EXIT PROGRAM 
	END IF
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AS1_rpt_list_invoice_credit",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AS1_rpt_list_invoice_credit TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].sel_text
	#------------------------------------------------------------
	
	LET l_inv_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref1_text 
	LET l_cred_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_text 
	LET l_rec_select.inv_flag =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref1_ind

	LET l_rec_select.inv_start_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref1_num	
	LET l_rec_select.inv_last_num  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_num 
	LET l_rec_select.inv_start_date  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref1_date
	LET l_rec_select.inv_last_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_date 
	 
	LET l_rec_select.inv_start_cust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref1_code   
	LET l_rec_select.inv_last_cust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_code
	 
	LET l_rec_select.inv_prev_prnt_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_ind 
	LET l_rec_select.inv_ind  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref3_ind
	LET l_rec_select.cred_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref4_ind 
	 
	LET l_rec_select.cred_start_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref3_num  
	LET l_rec_select.cred_last_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref4_num 
	 
	LET l_rec_select.cred_start_date   = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref2_date
	LET l_rec_select.cred_last_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref3_date
	 
	LET l_rec_select.cred_start_cust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref3_code   
	LET l_rec_select.cred_last_cust = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref4_code
	LET l_rec_select.cred_prev_prnt_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref5_ind   
	LET l_rec_select.cred_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].ref5_code


--	SELECT * INTO l_rec_printcodes.* 
--	FROM printcodes 
--	WHERE print_code = l_inv_printer 
--	IF status = NOTFOUND THEN 
--		INITIALIZE l_rec_printcodes.* TO NULL 
--	END IF 

	DECLARE c_kandoomsg CURSOR FOR 
	SELECT * FROM kandoomsg 
	WHERE source_ind = "A" 
	AND msg_num between 6400 AND 6401 
	AND language_code = "ENG" 

	FOR l_idx = 1 TO 4 
		INITIALIZE modu_rec_print[l_idx].* TO NULL 
	END FOR 

	LET l_idx = 0 
	FOREACH c_kandoomsg INTO l_rec_kandoomsg.* 
		LET l_idx = l_idx + 1 
		IF l_idx = 1 THEN 
			LET modu_rec_print[1].msg_text = l_rec_kandoomsg.msg1_text 
			LET modu_rec_print[2].msg_text = l_rec_kandoomsg.msg2_text 
		ELSE 
			LET modu_rec_print[3].msg_text = l_rec_kandoomsg.msg1_text 
			LET modu_rec_print[4].msg_text = l_rec_kandoomsg.msg2_text 
		END IF 
	END FOREACH 

	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_applictax (
		tax_code CHAR(3), 
		tax_per DECIMAL(6,3), 
		gross_amt DECIMAL(16,2), 
		tax_amt DECIMAL(16,2)) with no LOG 
	CREATE temp TABLE t2_applictax (
		tax_code CHAR(3), 
		tax_per DECIMAL(6,3), 
		gross_amt DECIMAL(16,2), 
		tax_amt DECIMAL(16,2)) with no LOG 
	
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	#Read Arguments if we have received invoice or credit note code
	#This would bypass the user query construct
	#These arguments were already validated/prepared in AS1_B_rpt_query()	 
	IF get_url_invoice_text() IS NOT NULL THEN
		LET l_inv_text = get_url_invoice_text()
	END IF
	IF get_url_credit_text() IS NOT NULL THEN 
		LET l_cred_text = get_url_credit_text()
	END IF 
	
	IF l_inv_text IS NOT NULL THEN 
		LET l_query_text =
			"SELECT 'I', ",
			"invoicehead.cmpy_code,", 
			"invoicehead.inv_num, ", 
			"invoicehead.inv_ind, ", 
			"invoicehead.cust_code, ", 
			"invoicehead.org_cust_code, ", 
			"invoicehead.inv_date, ", 
			"invoicehead.cond_code, ", 
			"invoicehead.tax_code, ", 
			"invoicehead.carrier_code, ", 
			"invoicehead.term_code, ", 
			"invoicehead.territory_code, ", 
			"invoicehead.sale_code, ", 
			"invoicehead.ord_num, ", 
			"invoicehead.purchase_code, ", 
			"invoicehead.goods_amt, ", 
			"invoicehead.tax_amt, ", 
			"invoicehead.total_amt, ", 
			"invoicehead.hand_amt, ", 
			"invoicehead.hand_tax_amt, ", 
			"invoicehead.freight_amt, ", 
			"invoicehead.freight_tax_amt, ", 
			"invoicehead.invoice_to_ind, ", 
			"invoicehead.name_text, ", 
			"invoicehead.addr1_text, ", 
			"invoicehead.addr2_text, ", 
			"invoicehead.city_text, ", 
			"invoicehead.state_code, ", 
			"invoicehead.post_code, ", 
			"invoicehead.country_code, ", --@db-patch_2020_10_04--
			"invoicehead.com1_text, ", 
			"invoicehead.com2_text, ", 
			"invoicehead.conv_qty, ",
			"invoicehead.printed_num, ", 
			"invoicedetl.line_num, ", 
			"invoicedetl.part_code, ", 
			"invoicedetl.order_num, ", 
			"invoicedetl.offer_code, ", 
			"invoicedetl.tax_code, ", 
			"invoicedetl.unit_sale_amt, ", 
			"invoicedetl.unit_tax_amt, ", 
			"invoicedetl.ext_sale_amt, ", 
			"invoicedetl.ext_tax_amt, ", 
			"invoicedetl.ord_qty,", 
			"invoicedetl.ship_qty,", 
			"invoicedetl.back_qty,", 
			"invoicedetl.sold_qty,", 
			"invoicedetl.line_text,", 
			"invoicedetl.ware_code,", 
			"invoicedetl.level_code,", 
			"invoicedetl.disc_amt ",
			"FROM invoicehead, invoicedetl ", 
			"WHERE invoicehead.cmpy_code= '",glob_rec_company.cmpy_code clipped,"' ", 
			"AND invoicedetl.cmpy_code= '",glob_rec_company.cmpy_code clipped,"' ", 
			"AND invoicehead.inv_num = invoicedetl.inv_num ",			 
			glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].sel_text clipped," ", 
			#"AND invoicehead.inv_num = ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].sel_text clipped," ",
			"ORDER BY invoicehead.inv_num,", 
			"invoicedetl.order_num,", 
			"invoicedetl.offer_code,", 
			"invoicedetl.line_num" 
		--LET glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].sel_text = l_query_text #store query for report record
		PREPARE s_invoice FROM l_query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 

		IF p_verbose_ind THEN #hidden/background ?
			LET l_prev_doc = 99999999 #what is this ?

			MESSAGE kandoomsg2("E",1046,"") #1046 Printing Invoice No:
		END IF 

		FOREACH c_invoice INTO l_rec_dochead.*, l_rec_docdetl.* 
			IF p_verbose_ind AND l_rec_dochead.doc_num != l_prev_doc THEN 
				LET l_prev_doc = l_rec_dochead.doc_num 
			END IF 

			#----------------------------------------------------------------			
			OUTPUT TO REPORT AS1_rpt_list_invoice_credit(rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit"),
			l_rec_dochead.*, 
			l_rec_docdetl.*, 
			l_rec_printcodes.*) #no longer used 
			IF NOT rpt_int_flag_handler2("Invoice",l_rec_dochead.doc_num, NULL,rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")) THEN
				EXIT FOREACH 
			END IF 			
			#----------------------------------------------------------------			
			
		END FOREACH 

		IF p_verbose_ind THEN 
			--CLOSE WINDOW w1 
		END IF 
	END IF 

	IF l_cred_text IS NOT NULL THEN 
		LET l_query_text =
			"SELECT 'C', ",
			"credithead.cmpy_code, ", 
			"credithead.cred_num, ", 
			"credithead.cred_ind, ", 
			"credithead.cust_code, ", 
			"credithead.org_cust_code, ", 
			"credithead.cred_date, ", 
			"'',", 
			"credithead.tax_code, ", 
			"'',", 
			"'',", 
			"'',", 
			"credithead.sale_code, ", 
			"0, ", 
			"credithead.cred_text, ", 
			"credithead.goods_amt, ", 
			"credithead.tax_amt, ", 
			"credithead.total_amt, ", 
			"credithead.hand_amt, ", 
			"credithead.hand_tax_amt, ", 
			"credithead.freight_amt, ", 
			"credithead.freight_tax_amt, ",
			"'1',", 
			"'',", 
			"'',", 
			"'',", 
			"'',", 
			"'',", 
			"'',", 
			"'',", 
			"credithead.com1_text, ", 
			"credithead.com2_text, ", 
			"credithead.conv_qty, ",
			"credithead.printed_num, ",
			"creditdetl.line_num, ", 
			"creditdetl.part_code, ", 
			"0, ", 
			"'',", 
			"creditdetl.tax_code, ", 
			"creditdetl.unit_sales_amt, ", 
			"creditdetl.unit_tax_amt, ", 
			"creditdetl.ext_sales_amt, ", 
			"creditdetl.ext_tax_amt,", 
			"'',", 
			"creditdetl.ship_qty,", 
			"'',", 
			"'',", 
			"creditdetl.line_text,", 
			"creditdetl.ware_code,", 
			"creditdetl.level_code,", 
			"creditdetl.disc_amt ", 
			"FROM credithead, creditdetl ", 
			"WHERE credithead.cmpy_code= '",glob_rec_company.cmpy_code,"' ", 
			"AND creditdetl.cmpy_code= '",glob_rec_company.cmpy_code,"' ", 
			"AND credithead.cred_num = creditdetl.cred_num ", 
			"AND ",l_cred_text clipped," ", 
			"ORDER BY credithead.cred_num,", 
			"creditdetl.line_num" 

		PREPARE s_crednote FROM l_query_text 
		DECLARE c_crednote CURSOR FOR s_crednote 

		IF p_verbose_ind THEN 
			LET l_prev_doc = 99999999 
			--OPEN WINDOW w1 with FORM "U999" 
			--CALL windecoration_u("U999") 

			#MESSAGE kandoomsg2("E",1056,"") 
			#1056 Printing Credit note No:
		END IF 

		FOREACH c_crednote INTO l_rec_dochead.*, l_rec_docdetl.* 
			IF p_verbose_ind AND l_rec_dochead.doc_num != l_prev_doc THEN 
				#DISPLAY "" AT 1,24
				#DISPLAY l_rec_dochead.doc_num AT 1,30
				MESSAGE l_rec_dochead.doc_num 

				LET l_prev_doc = l_rec_dochead.doc_num 
			END IF 

			#----------------------------------------------------------------			
			OUTPUT TO REPORT AS1_rpt_list_invoice_credit(rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit"),
			l_rec_dochead.*, 
			l_rec_docdetl.*, 
			l_rec_printcodes.*)  #no longer used
			IF NOT rpt_int_flag_handler2("Invoice",l_rec_dochead.doc_num, NULL,rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")) THEN
				EXIT FOREACH 
			END IF 			
			#----------------------------------------------------------------			

		END FOREACH 
		IF p_verbose_ind THEN 
			CLOSE WINDOW w1 
		END IF 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AS1_rpt_list_invoice_credit
	RETURN rpt_finish("AS1_rpt_list_invoice_credit")
	#------------------------------------------------------------

	#Not sure, what we should return
	--RETURN rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")
	--RETURN glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].file_text 
	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF
END FUNCTION 
################################################################################
# END FUNCTION AS1_rpt_process_invoice_credit(glob_rec_company.cmpy_code,p_kandoouser_sign_on_code,l_inv_text, l_cred_text, p_verbose_ind,l_inv_printer)
################################################################################


################################################################################
# REPORT AS1_rpt_list_invoice_credit(p_rpt_idx,glob_rec_company.cmpy_code,p_rec_dochead,p_rec_docdetl,p_rec_printcodes)
#
#
################################################################################
REPORT AS1_rpt_list_invoice_credit(p_rpt_idx,p_rec_dochead,p_rec_docdetl,p_rec_printcodes)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 

	DEFINE p_rec_dochead OF dt_rec_dochead
	DEFINE p_rec_docdetl OF dt_rec_docdetl

	DEFINE p_rec_printcodes RECORD LIKE printcodes.* #no longer used
	DEFINE l_page LIKE rmsreps.page_num 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_tax_code LIKE tax.tax_code
	DEFINE l_start_tax_code LIKE tax.tax_code
	DEFINE l_tax_calc_method LIKE tax.calc_method_flag 
	DEFINE l_line_sale_amt LIKE invoicedetl.ext_sale_amt 
	DEFINE l_tot_amt LIKE invoicehead.total_amt 
	DEFINE l_tot_fh_amt LIKE invoicehead.freight_amt 
	DEFINE l_need_num SMALLINT 
	DEFINE l_taxes_to_print SMALLINT 
	--DEFINE l_cnt SMALLINT 
	DEFINE l_end_of_doc SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_h SMALLINT 
	DEFINE l_j SMALLINT 

	DEFINE l_condsale_text LIKE condsale.desc_text 
	DEFINE l_territory_text LIKE territory.desc_text 
	DEFINE l_salesperson_text LIKE salesperson.name_text 
	DEFINE l_carrier_text LIKE carrier.name_text 
	DEFINE l_term_text LIKE term.desc_text 
	DEFINE l_doc_text NVARCHAR(13) 
	DEFINE l_ind_text NVARCHAR(3) 
	DEFINE l_code_and_text NVARCHAR(20) 
	DEFINE l_comment_text NVARCHAR(55) 
	DEFINE l_line_text NVARCHAR(115) 
	DEFINE l_note_code LIKE notes.note_code 
	DEFINE l_note_text LIKE notes.note_text 
	DEFINE l_arr_inv_addr array[5] OF LIKE customer.addr1_text 
	DEFINE l_arr_del_addr array[5] OF LIKE customer.addr1_text 
	--DEFINE l_days_num LIKE termdetl.days_num 
	--DEFINE l_disc_per LIKE termdetl.disc_per 
	--DEFINE l_disc_amt LIKE invoicehead.disc_amt 
	--DEFINE l_due_date LIKE invoicehead.due_date 
	DEFINE l_price_amt LIKE prodstatus.list_amt 
	DEFINE l_offer_text LIKE offersale.desc_text 
	DEFINE l_print_line_flag NCHAR(1) 
	DEFINE l_idx SMALLINT 

	OUTPUT 
--	left margin 0 
--	top margin 0 
--	bottom margin 0 
	ORDER external BY 
		p_rec_dochead.doc_num, 
		p_rec_docdetl.order_num, 
		p_rec_docdetl.offer_code, 
		p_rec_docdetl.line_num 

	FORMAT 

		BEFORE GROUP OF p_rec_dochead.doc_num 
			# IF trailer left over FROM previous document, skip a line TO force
			# another page throw (REPORT formatter knows nothing was printed
			# AND does NOT throw a new page even though we want it TO)
			IF pageno > 1 OR modu_nrof_detlines < 22 THEN 
				LET l_page = 0 
			END IF 

			IF l_taxes_to_print > 0 AND modu_nrof_detlines = 22 THEN 
				SKIP 1 line 
			END IF 
			SKIP TO top OF PAGE 

			# Reset tax totals FOR this invoice
			DELETE FROM t2_applictax 
			LET l_end_of_doc = false 
			LET l_tot_amt = 0 

			# Determine tax type FOR this invoice
			SELECT calc_method_flag 
			INTO l_tax_calc_method 
			FROM tax 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND tax_code = p_rec_dochead.tax_code 
			IF status = NOTFOUND THEN 
				LET l_tax_calc_method = NULL 
			END IF 

			# Store page trailer data
			# Comments
			LET l_comment_text =p_rec_dochead.com1_text clipped," ",p_rec_dochead.com2_text 

			# Carrier
			SELECT name_text INTO l_carrier_text 
			FROM carrier 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND carrier_code = p_rec_dochead.carrier_code 
			IF status = NOTFOUND THEN 
				INITIALIZE l_carrier_text TO NULL 
			END IF 

			# Payment terms
			SELECT desc_text INTO l_term_text 
			FROM term 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND term_code = p_rec_dochead.term_code 
			IF status = NOTFOUND THEN 
				INITIALIZE l_term_text TO NULL 
			END IF 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			PRINT COLUMN 4, ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_1), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_2), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_3), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_4), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_5), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_6), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_7), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_8), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_9), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_10) 
			LET l_page = l_page + 1 
			
			CASE p_rec_dochead.doc_type 
				WHEN "I" 
					IF p_rec_dochead.printed_num = 0 THEN
						LET l_doc_text = "I N V O I C E"
					ELSE
						LET l_doc_text = "INVOICE-COPY", trim(p_rec_dochead.printed_num)
					END IF 
				WHEN "C" 
					IF p_rec_dochead.printed_num = 0 THEN
						LET l_doc_text = " C R E D I T "
					ELSE
						LET l_doc_text = "CREDIT-COPY", trim(p_rec_dochead.printed_num)
					END IF 
			END CASE

			LET l_arr_del_addr[1] = p_rec_dochead.addr1_text 
			LET l_arr_del_addr[2] = p_rec_dochead.addr2_text 
			IF p_rec_dochead.city_text IS NULL THEN 
				LET l_arr_del_addr[3] = p_rec_dochead.state_code clipped," ", p_rec_dochead.post_code 
			ELSE 
				LET l_arr_del_addr[3] = p_rec_dochead.city_text clipped," ", p_rec_dochead.state_code clipped," ", p_rec_dochead.post_code 
			END IF 
			LET l_arr_del_addr[4] = p_rec_dochead.country_code --@db-patch_2020_10_04--

			FOR l_i = 1 TO 4 
				LET l_j = 1 
				WHILE ((l_arr_del_addr[l_i] IS NULL OR l_arr_del_addr[l_i] = " ") AND l_i+l_j < 6) 
					LET l_arr_del_addr[l_i] = l_arr_del_addr[l_i+l_j] 
					INITIALIZE l_arr_del_addr[l_i+l_j] TO NULL 
					LET l_j = l_j+1 
				END WHILE 
				IF l_i + l_j > 4 THEN 
					EXIT FOR 
				END IF 
			END FOR 

			IF p_rec_dochead.invoice_to_ind = 1 THEN 
				CALL db_customer_get_rec(UI_OFF,p_rec_dochead.cust_code) RETURNING l_rec_customer.*
--				SELECT * INTO l_rec_customer.* 
--				FROM customer 
--				WHERE cmpy_code = glob_rec_company.cmpy_code 
--				AND cust_code = p_rec_dochead.cust_code 
				IF l_rec_customer.cust_code IS NULL THEN			
--				IF status = NOTFOUND THEN 
					INITIALIZE l_rec_customer.* TO NULL 
				END IF 

				IF p_rec_dochead.org_cust_code IS NOT NULL AND l_rec_customer.inv_addr_flag = "O" THEN 
					CALL db_customer_get_rec(UI_OFF,p_rec_dochead.org_cust_code) RETURNING l_rec_customer.*
--					SELECT * INTO l_rec_customer.* 
--					FROM customer 
--					WHERE cmpy_code = glob_rec_company.cmpy_code 
--					AND cust_code = p_rec_dochead.org_cust_code 
				IF l_rec_customer.cust_code IS NULL THEN			
--				IF status = NOTFOUND THEN 
						INITIALIZE l_rec_customer.* TO NULL 
					END IF 
				END IF 
				LET l_arr_inv_addr[1] = l_rec_customer.addr1_text 
				LET l_arr_inv_addr[2] = l_rec_customer.addr2_text 

				IF l_rec_customer.city_text IS NULL THEN 
					LET l_arr_inv_addr[3] = l_rec_customer.state_code clipped," ", l_rec_customer.post_code 
				ELSE 
					LET l_arr_inv_addr[3] = l_rec_customer.city_text clipped," ", l_rec_customer.state_code clipped," ",l_rec_customer.post_code 
				END IF 

				LET l_arr_inv_addr[4] = l_rec_customer.country_code --@db-patch_2020_10_04--

				FOR l_i = 1 TO 4 
					LET l_j = 1 
					WHILE ((l_arr_inv_addr[l_i] IS NULL OR l_arr_inv_addr[l_i] = " ") AND l_i+l_j < 6) 
						LET l_arr_inv_addr[l_i] = l_arr_inv_addr[l_i+l_j] 
						INITIALIZE l_arr_inv_addr[l_i+l_j] TO NULL 
						LET l_j = l_j+1 
					END WHILE 
					IF l_i + l_j > 4 THEN 
						EXIT FOR 
					END IF 
				END FOR 
			ELSE 
				LET l_rec_customer.name_text = p_rec_dochead.name_text 
				FOR l_i = 1 TO 5 
					LET l_arr_inv_addr[l_i] = l_arr_del_addr[l_i] 
				END FOR 
			END IF 

			PRINT COLUMN 55, l_doc_text, 
			COLUMN 78, p_rec_dochead.doc_date USING "dd/mmm/yy", 
			COLUMN 90, l_page USING "####&" 
			SKIP 1 line 
			PRINT COLUMN 45,"CLIENT:", 
			COLUMN 55, p_rec_dochead.cust_code, 
			COLUMN 75,"ORD:", 
			COLUMN 79, p_rec_dochead.ord_num USING "########" 
			SKIP 1 LINES 

			SELECT desc_text INTO l_condsale_text 
			FROM condsale 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND cond_code = p_rec_dochead.cond_code 

			IF status = NOTFOUND THEN 
				LET l_condsale_text = NULL 
			END IF 
			LET l_code_and_text = p_rec_dochead.cond_code clipped," ",l_condsale_text 

			IF p_rec_dochead.doc_type = "I" THEN 
				CASE p_rec_dochead.doc_ind 
					WHEN "1" 
						LET l_ind_text = "A-R" 
					WHEN "2" 
						LET l_ind_text = "NOR" 
					WHEN "3" 
						LET l_ind_text = TRAN_TYPE_JOB_JOB 
					WHEN "4" 
						LET l_ind_text = "ADJ" 
					WHEN "5" 
						LET l_ind_text = "PRE" 
					OTHERWISE 
						LET l_ind_text = "NOR" 
				END CASE 
			ELSE 
				CASE p_rec_dochead.doc_ind 
					WHEN "1" 
						LET l_ind_text = "NOR" 
					WHEN "2" 
						LET l_ind_text = "NOR" 
					WHEN "3" 
						LET l_ind_text = TRAN_TYPE_JOB_JOB 
					WHEN "4" 
						LET l_ind_text = "ADJ" 
					WHEN "5" 
						LET l_ind_text = "TRD" 
					OTHERWISE 
						LET l_ind_text = "NOR" 
				END CASE 
			END IF 

			PRINT COLUMN 45,"DOCUMENT:", p_rec_dochead.doc_num USING "########", 
			COLUMN 67, l_ind_text, 
			COLUMN 75, l_code_and_text 
			SKIP 1 LINES 
			PRINT COLUMN 13,"INVOICE TO", 
			COLUMN 44, "DELIVER TO" 
			SELECT desc_text INTO l_territory_text 
			FROM territory 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND terr_code = p_rec_dochead.territory_code 
			IF status = NOTFOUND THEN 
				LET l_territory_text = NULL 
			END IF 

			LET l_code_and_text = p_rec_dochead.territory_code clipped," ", l_territory_text 
			PRINT COLUMN 75, l_code_and_text 

			SELECT name_text INTO l_salesperson_text 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND sale_code = p_rec_dochead.sale_code 
			IF status = NOTFOUND THEN 
				LET l_salesperson_text = NULL 
			END IF 
			LET l_code_and_text = p_rec_dochead.sale_code clipped, " ",	l_salesperson_text 

			PRINT COLUMN 13, l_rec_customer.name_text, 
			COLUMN 44, p_rec_dochead.name_text 
			PRINT COLUMN 13, l_arr_inv_addr[1], 
			COLUMN 44, l_arr_del_addr[1] 
			PRINT COLUMN 13, l_arr_inv_addr[2], 
			COLUMN 44, l_arr_del_addr[2], 
			COLUMN 75, l_code_and_text 
			PRINT COLUMN 13, l_arr_inv_addr[3], 
			COLUMN 44, l_arr_del_addr[3] 
			PRINT COLUMN 13, l_arr_inv_addr[4], 
			COLUMN 44, l_arr_del_addr[4], 
			COLUMN 75, p_rec_dochead.purchase_code 
			PRINT COLUMN 13, l_arr_inv_addr[5], 
			COLUMN 44, l_arr_del_addr[5] 
			PRINT COLUMN 1, ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_1), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_2), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_3), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_4), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_5), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_6), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_7), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_8), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_9), 
			ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].compress_10) 
			PRINT COLUMN 6, "PRODUCT", 
			COLUMN 27, "DESCRIPTION", 
			COLUMN 80, " ORDERED", 
			COLUMN 90, "SUPPLIED", 
			COLUMN 101, "BACK ORD.", 
			COLUMN 112, " CHARGED", 
			COLUMN 122, " PRICE", 
			COLUMN 132, "TAX", 
			COLUMN 136, " DISCOUNT", 
			COLUMN 149, " AMOUNT" 
			SKIP 1 line 
			LET modu_nrof_detlines = 22 

		BEFORE GROUP OF p_rec_docdetl.order_num 
			IF p_rec_dochead.doc_type = "I" AND p_rec_docdetl.order_num != p_rec_dochead.ord_num THEN 
				NEED 4 LINES 
				SKIP 1 line 
				PRINT COLUMN 27, "Order Number:", 
				COLUMN 41, p_rec_docdetl.order_num USING "<<<<<<<<" 
				PRINT COLUMN 27, "----------------------" 
				LET modu_nrof_detlines = modu_nrof_detlines - 3 
			END IF 

		BEFORE GROUP OF p_rec_docdetl.offer_code 
			IF p_rec_dochead.doc_type = "I" AND p_rec_docdetl.offer_code IS NOT NULL THEN 
				NEED 4 LINES 
				SKIP 1 line 
				PRINT COLUMN 27, "Special Offer:", 
				COLUMN 42, p_rec_docdetl.offer_code; 
				SELECT desc_text INTO l_offer_text 
				FROM offersale 
				WHERE cmpy_code = glob_rec_company.cmpy_code 
				AND offer_code = p_rec_docdetl.offer_code 
				IF sqlca.sqlcode = 0 THEN 
					PRINT COLUMN 46, l_offer_text 
				ELSE 
					SKIP 1 line 
				END IF 
				PRINT COLUMN 27, "------------------" 
				LET modu_nrof_detlines = modu_nrof_detlines - 3 
			END IF 

		ON EVERY ROW 
			LET modu_nrof_detlines = modu_nrof_detlines - 1 
			LET l_line_sale_amt = p_rec_docdetl.ext_sale_amt + p_rec_docdetl.ext_tax_amt 
			LET l_tot_amt = l_tot_amt + p_rec_docdetl.ext_sale_amt 

			CASE l_tax_calc_method 
				WHEN "P" 
					UPDATE t2_applictax 
					SET gross_amt = gross_amt + l_line_sale_amt, tax_amt = tax_amt + p_rec_docdetl.ext_tax_amt 
					WHERE tax_code = p_rec_docdetl.tax_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						SELECT * INTO l_rec_tax.* 
						FROM tax 
						WHERE cmpy_code = glob_rec_company.cmpy_code 
						AND tax_code = p_rec_docdetl.tax_code 
						IF status = NOTFOUND THEN 
							LET l_rec_tax.tax_per = 0 
						END IF 
						INSERT INTO t2_applictax VALUES (p_rec_docdetl.tax_code, 
						l_rec_tax.tax_per, 
						l_line_sale_amt, 
						p_rec_docdetl.ext_tax_amt) 
					END IF 
					LET l_tax_code = p_rec_docdetl.tax_code 

				WHEN "D" 
					UPDATE t2_applictax 
					SET gross_amt = gross_amt + l_line_sale_amt, 
					tax_amt = tax_amt + p_rec_docdetl.ext_tax_amt 
					WHERE tax_code = "*" 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO t2_applictax VALUES ("*", 
						"", 
						l_line_sale_amt, 
						p_rec_docdetl.ext_tax_amt) 
					END IF 
					LET l_tax_code = "*" 

				OTHERWISE 
					UPDATE t2_applictax 
					SET gross_amt = gross_amt + l_line_sale_amt, tax_amt = tax_amt + p_rec_docdetl.ext_tax_amt 
					WHERE tax_code = p_rec_dochead.tax_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						SELECT * INTO l_rec_tax.* 
						FROM tax 
						WHERE cmpy_code = glob_rec_company.cmpy_code 
						AND tax_code = p_rec_dochead.tax_code 
						IF status = NOTFOUND THEN 
							LET l_rec_tax.tax_per = 0 
						END IF 

						INSERT INTO t2_applictax VALUES (p_rec_dochead.tax_code, 
						l_rec_tax.tax_per, 
						l_line_sale_amt, 
						p_rec_docdetl.ext_tax_amt) 
					END IF 
					LET l_tax_code = p_rec_dochead.tax_code 

			END CASE 

			IF p_rec_docdetl.part_code IS NOT NULL THEN 
				LET l_price_amt=p_rec_docdetl.unit_sale_amt 
				SELECT * INTO l_rec_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_company.cmpy_code 
				AND ware_code = p_rec_docdetl.ware_code 
				AND part_code = p_rec_docdetl.part_code 
				IF sqlca.sqlcode = 0 THEN 
					CASE p_rec_docdetl.level_code 
						WHEN "1" 
							LET l_price_amt=l_rec_prodstatus.price1_amt*p_rec_dochead.conv_qty 
						WHEN "2" 
							LET l_price_amt=l_rec_prodstatus.price2_amt*p_rec_dochead.conv_qty 
						WHEN "3" 
							LET l_price_amt=l_rec_prodstatus.price3_amt*p_rec_dochead.conv_qty 
						WHEN "4" 
							LET l_price_amt=l_rec_prodstatus.price4_amt*p_rec_dochead.conv_qty 
						WHEN "5" 
							LET l_price_amt=l_rec_prodstatus.price5_amt*p_rec_dochead.conv_qty 
						WHEN "6" 
							LET l_price_amt=l_rec_prodstatus.price6_amt*p_rec_dochead.conv_qty 
						WHEN "7" 
							LET l_price_amt=l_rec_prodstatus.price7_amt*p_rec_dochead.conv_qty 
						WHEN "8" 
							LET l_price_amt=l_rec_prodstatus.price8_amt*p_rec_dochead.conv_qty 
						WHEN "9" 
							LET l_price_amt=l_rec_prodstatus.price9_amt*p_rec_dochead.conv_qty 
						WHEN "L" 
							LET l_price_amt=l_rec_prodstatus.list_amt*p_rec_dochead.conv_qty 
						WHEN "C" 
							LET l_price_amt=l_rec_prodstatus.wgted_cost_amt*p_rec_dochead.conv_qty 
						OTHERWISE 
							LET l_price_amt=l_rec_prodstatus.list_amt*p_rec_dochead.conv_qty 
					END CASE 
				END IF 
			END IF 

			LET l_print_line_flag = "Y" 
			IF p_rec_docdetl.line_text[1,3] = "###" AND p_rec_docdetl.line_text[16,18] = "###" THEN 
				LET l_note_code = p_rec_docdetl.line_text[4,15] 

				IF p_rec_docdetl.part_code IS NOT NULL THEN 
					SELECT desc_text INTO l_line_text 
					FROM product 
					WHERE cmpy_code = glob_rec_company.cmpy_code 
					AND part_code = p_rec_docdetl.part_code 
				ELSE 
					IF p_rec_docdetl.ship_qty != 0 AND p_rec_docdetl.ext_sale_amt != 0 THEN 
						LET l_line_text = "Description:" 
					ELSE 
						LET l_print_line_flag = "N" 
					END IF 
				END IF 
			ELSE 
				LET l_note_code = NULL 
				LET l_line_text = p_rec_docdetl.line_text 
			END IF 

			IF l_print_line_flag = "Y" THEN 
				IF p_rec_docdetl.level_code != "L" THEN 
					LET p_rec_docdetl.disc_amt = NULL 
				END IF 
				PRINT COLUMN 6, p_rec_docdetl.part_code, 
				COLUMN 27, l_line_text, 
				COLUMN 80, p_rec_docdetl.ord_qty USING "-------&", 
				COLUMN 90, p_rec_docdetl.ship_qty USING "-------&", 
				COLUMN 101, p_rec_docdetl.back_qty USING "-------&", 
				COLUMN 112, p_rec_docdetl.sold_qty USING "-------&", 
				COLUMN 122, l_price_amt USING "-----&.&&", 
				COLUMN 132, l_tax_code, 
				COLUMN 136, p_rec_docdetl.disc_amt USING "------&.&&", 
				COLUMN 149, p_rec_docdetl.ext_sale_amt USING "---,---,--&.&&" 
			END IF 

			IF l_note_code IS NOT NULL THEN 
				DECLARE c2_notes CURSOR FOR 
				SELECT note_text, note_num 
				INTO l_note_text, l_i 
				FROM notes 
				WHERE cmpy_code = glob_rec_company.cmpy_code 
				AND note_code = l_note_code 
				ORDER BY note_num 
				FOREACH c2_notes 
					PRINT COLUMN 27, l_note_text 
					LET modu_nrof_detlines = modu_nrof_detlines - 1 
				END FOREACH 
			END IF 

		ON LAST ROW 
			LET l_page = 0 

		AFTER GROUP OF p_rec_dochead.doc_num 
			IF p_rec_dochead.doc_type = "I" THEN 
				UPDATE invoicehead 
				SET printed_num = printed_num + 1 
				WHERE cmpy_code = glob_rec_company.cmpy_code 
				AND inv_num = p_rec_dochead.doc_num 
			ELSE 
				UPDATE credithead 
				SET printed_num = printed_num + 1 
				WHERE cmpy_code = glob_rec_company.cmpy_code 
				AND cred_num = p_rec_dochead.doc_num 
			END IF 

			LET l_tot_fh_amt = p_rec_dochead.hand_amt 
			+ p_rec_dochead.hand_tax_amt 
			+ p_rec_dochead.freight_amt 
			+ p_rec_dochead.freight_tax_amt 

			## Print totals & discount box together
			LET l_need_num = 4 # 1 SKIP line & 3 total LINES 
			SELECT count(*) INTO l_idx 
			FROM termdetl 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			AND term_code = p_rec_dochead.term_code 
			IF l_idx > 2 THEN 
				LET l_need_num = l_need_num + (l_idx - 2) 
			END IF 

			### Allow room FOR MESSAGE IF it exists
			LET l_i = 0 
			FOR l_j = 1 TO 4 
				IF modu_rec_print[l_j].msg_text IS NULL THEN 
					EXIT FOR 
				END IF 
				LET l_i = l_j 
			END FOR 
			IF l_i > 0 THEN 
				LET l_need_num = l_need_num + l_i + 1 
			END IF 
			LET l_h = l_i 
			NEED l_need_num LINES 

			LET l_tot_amt = p_rec_dochead.total_amt 

			# Set up invoice/credit tax trailer data in an array. Print tax
			# code trailers until no more than 4 codes are left TO PRINT. Final
			# tax summary will THEN be printed WHEN going TO top of next page
			# FOR next document.
			SELECT count(*) 
			INTO l_taxes_to_print 
			FROM t2_applictax 

			LET l_start_tax_code = " " 

			CALL fill_tax2_array(l_start_tax_code) 
			RETURNING l_start_tax_code 

			LET l_end_of_doc = true 
			SKIP 1 line 
			PRINT COLUMN 27, "Total Goods Amount:", 
			COLUMN 149, p_rec_dochead.goods_amt USING "---,---,--&.&&" 
			PRINT COLUMN 27, "Total Freight AND Handling:", 
			COLUMN 149, l_tot_fh_amt USING "---,---,--&.&&" 
			PRINT COLUMN 27, "Total Tax:", 
			COLUMN 149, p_rec_dochead.tax_amt USING "---,---,--&.&&" 
			IF l_h > 0 THEN 
				SKIP 1 line 
				FOR l_j = 1 TO l_h 
					PRINT COLUMN 27, modu_rec_print[l_j].msg_text clipped 
				END FOR 
			END IF 
			WHILE l_taxes_to_print > 4 
				SKIP TO top OF PAGE 
				SKIP 1 line 
				CALL fill_tax2_array(l_start_tax_code) 
				RETURNING l_start_tax_code 
			END WHILE 

			PAGE TRAILER 
				IF l_end_of_doc THEN 
					SKIP 1 line 
				ELSE 
					PRINT COLUMN 27, "CARRIED FORWARD:", 
					COLUMN 149, l_tot_amt USING "---,---,--&.&&" 
				END IF 
				PRINT COLUMN 4, ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_1), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_2), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_3), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_4), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_5), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_6), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_7), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_8), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_9), 
				ascii(glob_arr_rec_rpt_printcodes[p_rpt_idx].normal_10) 
				# Note that all trailer details are stored VALUES.  Final invoice
				# details are printed via the "before group" section AND therefore the
				# document RECORD contains the next invoice OR credit header
				IF l_end_of_doc THEN 
					PRINT COLUMN 4, "COMMENTS", 
					COLUMN 58, "TAX%", 
					COLUMN 64, " PRODUCTS", 
					COLUMN 74, " TAX INC", 
					COLUMN 86, " TOTAL" 
					SKIP 1 line 
					PRINT COLUMN 4, l_comment_text, 
					COLUMN 59, modu_arr_rec_tax2[1].tax_per USING "#&.&", 
					COLUMN 64, modu_arr_rec_tax2[1].gross_amt USING "-----&.&&", 
					COLUMN 74, modu_arr_rec_tax2[1].tax_amt USING "----,--&.&&", 
					COLUMN 86, l_tot_amt USING "-----&.&&" 
					PRINT COLUMN 59, modu_arr_rec_tax2[2].tax_per USING "#&.&", 
					COLUMN 64, modu_arr_rec_tax2[2].gross_amt USING "-----&.&&", 
					COLUMN 74, modu_arr_rec_tax2[2].tax_amt USING "----,--&.&&" 
					PRINT COLUMN 12, l_carrier_text, 
					COLUMN 59, modu_arr_rec_tax2[3].tax_per USING "#&.&", 
					COLUMN 64, modu_arr_rec_tax2[3].gross_amt USING "-----&.&&", 
					COLUMN 74, modu_arr_rec_tax2[3].tax_amt USING "----,--&.&&" 
					PRINT COLUMN 12, l_term_text, 
					COLUMN 59, modu_arr_rec_tax2[4].tax_per USING "#&.&", 
					COLUMN 64, modu_arr_rec_tax2[4].gross_amt USING "-----&.&&", 
					COLUMN 74, modu_arr_rec_tax2[4].tax_amt USING "----,--&.&&" 
					LET l_taxes_to_print = l_taxes_to_print - 4 
					SKIP 3 LINES 
				ELSE 
					SKIP 5 LINES 
					PRINT COLUMN 79, "../", (l_page + 1) USING "<<<" 
					SKIP 3 LINES 
				END IF 
END REPORT 
################################################################################
# END REPORT AS1_rpt_list_invoice_credit(p_rpt_idx,glob_rec_company.cmpy_code,p_rec_dochead,p_rec_docdetl,p_rec_printcodes)
################################################################################


################################################################################
# FUNCTION fill_tax_array(p_start_tax_code)
#
#
################################################################################
FUNCTION fill_tax_array(p_start_tax_code) 
	DEFINE p_start_tax_code LIKE tax.tax_code
	DEFINE l_next_tax_code LIKE tax.tax_code
	DEFINE l_rec_t_applictax	RECORD 
		tax_code LIKE invoicedetl.tax_code, 
		tax_per LIKE tax.tax_per, 
		gross_amt LIKE invoicedetl.line_total_amt, 
		tax_amt LIKE invoicedetl.ext_tax_amt 
	END RECORD 
	DEFINE l_i SMALLINT 
	DEFINE l_j SMALLINT 

	DECLARE c_taxcodes CURSOR FOR 
	SELECT * INTO l_rec_t_applictax.* 
	FROM t_applictax 
	WHERE tax_code >= p_start_tax_code 
	AND tax_amt > 0 
	ORDER BY tax_code 
	LET l_i = 0 

	FOREACH c_taxcodes 
		# Only 4 codes TO be printed AT the bottom of each page
		IF l_i = 4 THEN 
			LET l_next_tax_code = l_rec_t_applictax.tax_code 
			EXIT FOREACH 
		END IF 
		LET l_i = l_i + 1 
		LET modu_arr_rec_tax[l_i].tax_code = l_rec_t_applictax.tax_code 
		LET modu_arr_rec_tax[l_i].tax_per = l_rec_t_applictax.tax_per 
		LET modu_arr_rec_tax[l_i].gross_amt = l_rec_t_applictax.gross_amt 
		LET modu_arr_rec_tax[l_i].tax_amt = l_rec_t_applictax.tax_amt * 1 
	END FOREACH 

	IF l_i < 4 THEN 
		FOR l_j = l_i+1 TO 4 
			INITIALIZE modu_arr_rec_tax[l_j].* TO NULL 
		END FOR 
	END IF 

	RETURN l_next_tax_code 
END FUNCTION 
################################################################################
# END FUNCTION fill_tax_array(p_start_tax_code)
################################################################################


################################################################################
# FUNCTION fill_tax2_array(p_start_tax_code)
#
#
################################################################################
FUNCTION fill_tax2_array(p_start_tax_code) 
	DEFINE p_start_tax_code LIKE tax.tax_code
	DEFINE l_next_tax_code LIKE tax.tax_code
	DEFINE l_rec_t_applictax RECORD 
		tax_code LIKE invoicedetl.tax_code, 
		tax_per LIKE tax.tax_per, 
		gross_amt LIKE invoicedetl.line_total_amt, 
		tax_amt LIKE invoicedetl.ext_tax_amt 
	END RECORD 
	DEFINE l_i SMALLINT 
	DEFINE l_j SMALLINT 

	DECLARE c2_taxcodes CURSOR FOR 
	SELECT * INTO l_rec_t_applictax.* 
	FROM t2_applictax 
	WHERE tax_code >= p_start_tax_code 
	AND tax_amt > 0 
	ORDER BY tax_code 
	LET l_i = 0 

	FOREACH c2_taxcodes 
		# Only 4 codes TO be printed AT the bottom of each page
		IF l_i = 4 THEN 
			LET l_next_tax_code = l_rec_t_applictax.tax_code 
			EXIT FOREACH 
		END IF 
		LET l_i = l_i + 1 
		LET modu_arr_rec_tax2[l_i].tax_code = l_rec_t_applictax.tax_code 
		LET modu_arr_rec_tax2[l_i].tax_per = l_rec_t_applictax.tax_per 
		LET modu_arr_rec_tax2[l_i].gross_amt = l_rec_t_applictax.gross_amt 
		LET modu_arr_rec_tax2[l_i].tax_amt = l_rec_t_applictax.tax_amt * 1 
	END FOREACH 

	IF l_i < 4 THEN 
		FOR l_j = l_i+1 TO 4 
			INITIALIZE modu_arr_rec_tax2[l_j].* TO NULL 
		END FOR 
	END IF 

	RETURN l_next_tax_code 
END FUNCTION 
################################################################################
# END FUNCTION fill_tax2_array(p_start_tax_code)
################################################################################