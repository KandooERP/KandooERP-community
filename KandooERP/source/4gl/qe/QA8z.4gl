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
GLOBALS "../qe/Q_QE_GLOBALS.4gl" 
GLOBALS 
--	DEFINE rpt_wid LIKE rmsreps.report_width_num 
--	DEFINE rpt_length LIKE rmsreps.page_length_num 
--	DEFINE rpt_pageno LIKE rmsreps.page_num 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	#	DEFINE glob_rec_qpparms RECORD LIKE qpparms.*
	#	DEFINE pr_arparms RECORD LIKE arparms.*
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE where_part CHAR(1500) 
	DEFINE under_line CHAR(76) 
--	DEFINE rpt_note CHAR(60) 
	DEFINE description CHAR(20) 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
# QA8 Quotation Print
###########################################################################
MAIN 

	CALL setModuleId("QA8") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	LET under_line = "______________________________________", 
	"______________________________________" 

	SELECT * INTO glob_rec_qpparms.* FROM qpparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		CALL fgl_winmessage("Configuration Error",kandoomsg2("Q",5002,""),"ERROR") 		#5002 QE Parms do NOT exist
		EXIT program 
	END IF 

	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",7005,"")	#7005 AR Parms do NOT exist
		EXIT program 
	END IF 
	
	OPEN WINDOW Q100 with FORM "Q100"	attribute (BORDER) 

	LET pr_arparms.inv_ref1_text = pr_arparms.inv_ref1_text clipped,	"................" 
	DISPLAY BY NAME pr_arparms.inv_ref1_text 

	MENU " Print Quotation" 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REPORT" --COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			CALL QA8_rpt_query() 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW Q100 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION QA8_rpt_query() 
#
# 
###########################################################################
FUNCTION QA8_rpt_query() 
	DEFINE pr_quote RECORD 
		cust_code LIKE quotehead.cust_code, 
		name_text LIKE customer.name_text, 
		tax_num_text LIKE customer.tax_num_text, 
		ship1_text LIKE quotehead.ship1_text, 
		ship2_text LIKE quotehead.ship2_text, 
		line_tot_amt LIKE quotedetl.line_tot_amt, 
		order_num LIKE quotehead.order_num, 
		ord_text LIKE quotehead.ord_text, 
		total_amt LIKE quotehead.total_amt, 
		currency_code LIKE quotehead.currency_code, 
		com1_text LIKE quotehead.com1_text, 
		com2_text LIKE quotehead.com2_text, 
		com3_text LIKE quotehead.com3_text, 
		com4_text LIKE quotehead.com4_text, 
		entry_code LIKE quotehead.entry_code, 
		rev_num LIKE quotehead.rev_num, 
		rev_date LIKE quotehead.rev_date, 
		quote_date LIKE quotehead.quote_date, 
		line_num LIKE quotedetl.line_num, 
		part_text LIKE quotedetl.desc_text, 
		part_code LIKE quotedetl.part_code, 
		order_qty LIKE quotedetl.order_qty, 
		unit_price_amt LIKE quotedetl.unit_price_amt, 
		ext_price_amt LIKE quotedetl.ext_price_amt, 
		unit_tax_amt LIKE quotedetl.unit_tax_amt, 
		ext_tax_amt LIKE quotedetl.ext_tax_amt, 
		quote_lead_text LIKE quotedetl.quote_lead_text, 
		quote_lead_text2 LIKE quotedetl.quote_lead_text2, 
		uom_code LIKE quotedetl.uom_code 
	END RECORD 
	DEFINE save_cust_code LIKE quotehead.cust_code 
	DEFINE save_order_num LIKE quotehead.order_num 
	DEFINE pr_printer_text LIKE printcodes.print_code 
	DEFINE query_text STRING 
	DEFINE pr_output CHAR(60) 
	DEFINE report_open_ind CHAR(1) 
	DEFINE l_rpt_idx SMALLINT  #report array index

	--LET rpt_pageno = 0 
	LET save_cust_code = "zzzzzzzz" 
	LET save_order_num = 0 
	
	LET msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria
	CONSTRUCT BY NAME where_part ON quotehead.cust_code, 
	customer.name_text, 
	quotehead.order_num, 
	quotehead.currency_code, 
	quotehead.goods_amt, 
	quotehead.hand_amt, 
	quotehead.freight_amt, 
	quotehead.tax_amt, 
	quotehead.total_amt, 
	quotehead.cost_amt, 
	quotehead.disc_amt, 
	quotehead.approved_by, 
	quotehead.approved_date, 
	quotehead.ord_text, 
	quotehead.quote_date, 
	quotehead.valid_date, 
	quotehead.ship_date, 
	quotehead.status_ind, 
	quotehead.entry_code, 
	quotehead.entry_date, 
	quotehead.rev_date, 
	quotehead.rev_num, 
	quotehead.com1_text, 
	quotehead.com2_text, 
	quotehead.com3_text, 
	quotehead.com4_text 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET query_text = "SELECT quotehead.cust_code, customer.name_text, ", 
	"customer.tax_num_text, quotehead.ship1_text, ", 
	"quotehead.ship2_text, quotedetl.line_tot_amt, ", 
	"quotehead.order_num, quotehead.ord_text, ", 
	"quotehead.total_amt, quotehead.currency_code, ", 
	"quotehead.com1_text, quotehead.com2_text, ", 
	"quotehead.com3_text, quotehead.com4_text, ", 
	"quotehead.entry_code, quotehead.rev_num, ", 
	"quotehead.rev_date, quotehead.quote_date, ", 
	"quotedetl.line_num, quotedetl.desc_text, ", 
	"quotedetl.part_code, quotedetl.order_qty, ", 
	"quotedetl.unit_price_amt, ", 
	"quotedetl.ext_price_amt, ", 
	"quotedetl.unit_tax_amt, quotedetl.ext_tax_amt, ", 
	"quotedetl.quote_lead_text, ", 
	"quotedetl.quote_lead_text2, ", 
	"quotedetl.uom_code ", 
	"FROM quotehead, customer, quotedetl ", 
	"WHERE quotehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND customer.cmpy_code = quotehead.cmpy_code ", 
	"AND customer.cust_code = quotehead.cust_code ", 
	"AND quotedetl.cmpy_code = quotehead.cmpy_code ", 
	"AND quotedetl.order_num = quotehead.order_num ", 
	"AND quotehead.approved_by IS NOT NULL ", 
	"AND ", where_part clipped, " ", 
	"ORDER BY quotehead.cust_code, quotehead.order_num, ", 
	"quotedetl.line_num" 

	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR with HOLD FOR choice 

	OPEN WINDOW Q119 with FORM "Q119" attribute (border) 

	INPUT BY NAME glob_rec_qpparms.footer1_text, 
	glob_rec_qpparms.footer2_text, 
	glob_rec_qpparms.footer3_text, 
	glob_rec_qpparms.quote_std_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
	END INPUT 

	CLOSE WINDOW Q119 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	CALL get_print(glob_rec_kandoouser.cmpy_code,pr_printer_text)	RETURNING description
	 

	LET msgresp = kandoomsg("U",1002,"") 

	IF description IS NOT NULL THEN 
		SELECT * INTO pr_printcodes.* FROM printcodes 
		WHERE print_code = description 

		FOREACH selcurs INTO pr_quote.* 
			IF save_cust_code != pr_quote.cust_code 
			OR save_order_num != pr_quote.order_num THEN 
				IF report_open_ind = "Y" THEN 

					#------------------------------------------------------------
					FINISH REPORT QA8_rpt_list
					CALL rpt_finish("QA8_rpt_list")
					#------------------------------------------------------------
				
					LET report_open_ind = "N" 
				END IF 
						
				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"QA8_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, pr_quote.order_num USING "&&&&&&&")
				
				START REPORT QA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------
			 
				LET report_open_ind = "Y" 
				LET save_cust_code = pr_quote.cust_code 
				LET save_order_num = pr_quote.order_num 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT QA8_rpt_list(l_rpt_idx,
			pr_quote.*, pr_printcodes.*) 
			IF NOT rpt_int_flag_handler2("Quotation:",pr_quote.order_num, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			
		END FOREACH 
	END IF
	 
	IF report_open_ind = "Y" THEN

		#------------------------------------------------------------
		FINISH REPORT QA8_rpt_list
		CALL rpt_finish("QA8_rpt_list")
		#------------------------------------------------------------
 
	END IF 


	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION QA8_rpt_query() 
###########################################################################


###########################################################################
# REPORT QA8_rpt_list(p_rpt_idx,pr_quote, pr_printcodes)
#
# 
###########################################################################
REPORT QA8_rpt_list(p_rpt_idx,pr_quote, pr_printcodes) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rpt_idx SMALLINT  #report array index OF theCHILD REPORT QA8_rpt_list_out !!!!
	DEFINE pr_quote RECORD 
		cust_code LIKE quotehead.cust_code, 
		name_text LIKE customer.name_text, 
		tax_num_text LIKE customer.tax_num_text, 
		ship1_text LIKE quotehead.ship1_text, 
		ship2_text LIKE quotehead.ship2_text, 
		line_tot_amt LIKE quotedetl.line_tot_amt, 
		order_num LIKE quotehead.order_num, 
		ord_text LIKE quotehead.ord_text, 
		total_amt LIKE quotehead.total_amt, 
		currency_code LIKE quotehead.currency_code, 
		com1_text LIKE quotehead.com1_text, 
		com2_text LIKE quotehead.com2_text, 
		com3_text LIKE quotehead.com3_text, 
		com4_text LIKE quotehead.com4_text, 
		entry_code LIKE quotehead.entry_code, 
		rev_num LIKE quotehead.rev_num, 
		rev_date LIKE quotehead.rev_date, 
		quote_date LIKE quotehead.quote_date, 
		line_num LIKE quotedetl.line_num, 
		part_text LIKE quotedetl.desc_text, 
		part_code LIKE quotedetl.part_code, 
		order_qty LIKE quotedetl.order_qty, 
		unit_price_amt LIKE quotedetl.unit_price_amt, 
		ext_price_amt LIKE quotedetl.ext_price_amt, 
		unit_tax_amt LIKE quotedetl.unit_tax_amt, 
		ext_tax_amt LIKE quotedetl.ext_tax_amt, 
		quote_lead_text LIKE quotedetl.quote_lead_text, 
		quote_lead_text2 LIKE quotedetl.quote_lead_text2, 
		uom_code LIKE quotedetl.uom_code 
	END RECORD 
	DEFINE pr_first_page SMALLINT 
	DEFINE in_file STRING 
	DEFINE out_file STRING	
	DEFINE pr_notes RECORD LIKE notes.* 
	DEFINE pr_quotehead RECORD LIKE quotehead.* 
	DEFINE pr_customer RECORD LIKE customer.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE checkfile CHAR(110) 
	DEFINE exists_flag SMALLINT 

	OUTPUT 

	ORDER external BY pr_quote.cust_code,	pr_quote.order_num,	pr_quote.line_num
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
--			LET rpt_pageno = rpt_pageno + 1 
			PRINT ascii(12), 
			ascii(pr_printcodes.compress_11), 
			ascii(pr_printcodes.compress_12), 
			ascii(pr_printcodes.compress_13), 
			ascii(pr_printcodes.compress_14), 
			ascii(pr_printcodes.compress_15), 
			"QUOTE NO: ", pr_quote.order_num USING "&&&&&&&" 
			PRINT ascii(pr_printcodes.normal_1), 
			ascii(pr_printcodes.normal_2), 
			ascii(pr_printcodes.normal_3), 
			ascii(pr_printcodes.normal_4), 
			ascii(pr_printcodes.normal_5), 
			" " 
			SKIP 2 LINES 
			PRINT COLUMN 16, pr_quote.name_text 
			PRINT COLUMN 16, pr_quote.com1_text 
			PRINT COLUMN 16, pr_quote.com2_text 
			PRINT COLUMN 16, pr_quote.com3_text 
			PRINT COLUMN 16, pr_quote.com4_text 
			SKIP 2 LINES 
			PRINT COLUMN 01, "YOUR REF: ", pr_quote.ord_text 
			PRINT COLUMN 01, "OUR REF: ", pr_quote.entry_code, 
			COLUMN 23, "CUSTOMER CODE: ", pr_quote.cust_code 
			PRINT COLUMN 01, "SALES TAX NO: ", pr_quote.tax_num_text
			 
			IF pr_quote.rev_date IS NULL THEN 
				PRINT COLUMN 01, "REVISION: ", pr_quote.rev_num USING "####", 
				COLUMN 23, "DATE: ", pr_quote.quote_date USING "dd/mm/yy", 
				COLUMN 52, "A.C.N. 000 027 556" 
			ELSE 
				PRINT COLUMN 01, "REVISION: ", pr_quote.rev_num USING "####", 
				COLUMN 23, "DATE: ", pr_quote.rev_date USING "dd/mm/yy", 
				COLUMN 52, "A.C.N. 000 027 556" 
			END IF
			 
			PRINT COLUMN 01, "DESPATCH BY: ", pr_quote.ship1_text 
			PRINT COLUMN 01, " ", pr_quote.ship2_text 
			PRINT COLUMN 01, under_line 
			PRINT COLUMN 01, "Line",
			 
			COLUMN 06, "Product", 
			COLUMN 25, "Quantity", 
			COLUMN 35, "Unit", 
			COLUMN 41, "Unit Price", 
			COLUMN 55, "Unit Tax", 
			COLUMN 65, "Total Amount" 
			PRINT COLUMN 46, pr_quote.currency_code, 
			COLUMN 69, pr_quote.currency_code 
			PRINT COLUMN 01, under_line
			 
		BEFORE GROUP OF pr_quote.order_num 
			SKIP TO top OF PAGE 
			IF glob_rec_qpparms.quote_std_text IS NOT NULL THEN 
				LET in_file = glob_rec_qpparms.quote_std_text clipped, "/q", 
				pr_quote.order_num USING "&&&&&&&", ".let" 
				LET checkfile = "[ -f ",in_file clipped, 
				" ] && EXIT 0 || EXIT 1;" 
				RUN checkfile RETURNING exists_flag 
				IF exists_flag = 0 THEN 
					SKIP 1 line 
					PRINT file in_file 
					SKIP 1 line 
				END IF 
			END IF
			 
		ON EVERY ROW 
			NEED 4 LINES 
			IF pr_quote.unit_price_amt != 0 
			AND pr_quote.line_tot_amt != 0 THEN 
				PRINT COLUMN 01, pr_quote.line_num USING "####", 
				COLUMN 06, pr_quote.part_code, 
				COLUMN 25, pr_quote.order_qty USING "#####&.&", 
				COLUMN 35, pr_quote.uom_code, 
				COLUMN 40, pr_quote.unit_price_amt USING "----,--&.&&", 
				COLUMN 52, pr_quote.unit_tax_amt USING "----,--&.&&", 
				COLUMN 64, pr_quote.line_tot_amt USING "--,---,--&.&&" 
			ELSE 
				IF pr_quote.unit_price_amt = 0 
				AND pr_quote.line_tot_amt = 0 THEN 
					IF pr_quote.unit_tax_amt != 0 THEN 
						PRINT COLUMN 01, pr_quote.line_num USING "####", 
						COLUMN 06, pr_quote.part_code, 
						COLUMN 25, pr_quote.order_qty USING "#####&.&", 
						COLUMN 35, pr_quote.uom_code, 
						COLUMN 52, pr_quote.unit_tax_amt USING "----,--&.&&" 
					ELSE 
						SKIP 1 line 
						PRINT COLUMN 01, pr_quote.line_num USING "####"; 
					END IF 
				ELSE 
					IF pr_quote.unit_price_amt = 0 THEN 
						PRINT COLUMN 01, pr_quote.line_num USING "####", 
						COLUMN 06, pr_quote.part_code, 
						COLUMN 25, pr_quote.order_qty USING "#####&.&", 
						COLUMN 35, pr_quote.uom_code, 
						COLUMN 52, pr_quote.unit_tax_amt USING "----,--&.&&", 
						COLUMN 64, pr_quote.line_tot_amt USING "--,---,--&.&&" 
					ELSE 
						IF pr_quote.line_tot_amt = 0 THEN 
							PRINT COLUMN 01, pr_quote.line_num USING "####", 
							COLUMN 06, pr_quote.part_code, 
							COLUMN 25, pr_quote.order_qty USING "#####&.&", 
							COLUMN 35, pr_quote.uom_code, 
							COLUMN 40, pr_quote.unit_price_amt USING "----,--&.&&", 
							COLUMN 52, pr_quote.unit_tax_amt USING "----,--&.&&" 
						END IF 
					END IF 
				END IF 
			END IF
			 
			SELECT desc_text, desc2_text 
			INTO pr_product.desc_text, pr_product.desc2_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_quote.part_code
			 
			IF status = notfound THEN 
				IF not(pr_quote.part_text[1,3] = "###" AND 
				pr_quote.part_text[16,18] = "###") THEN 
					PRINT COLUMN 06, pr_quote.part_text 
				END IF 
			ELSE 
				IF pr_quote.part_text[1,3] = "###" 
				AND pr_quote.part_text[16,18] = "###" THEN 
					PRINT COLUMN 06, pr_product.desc_text 
					IF pr_product.desc2_text IS NOT NULL THEN 
						PRINT COLUMN 06, pr_product.desc2_text 
					END IF 
				ELSE 
					IF pr_quote.part_text != pr_product.desc_text THEN 
						PRINT COLUMN 06,pr_quote.part_text 
					ELSE 
						PRINT COLUMN 06, pr_product.desc_text 
						IF pr_product.desc2_text IS NOT NULL THEN 
							PRINT COLUMN 06, pr_product.desc2_text 
						END IF 
					END IF 
				END IF 
			END IF 
			
			IF pr_quote.part_text[1,3] = "###" 
			AND pr_quote.part_text[16,18] = "###" THEN 
				LET pr_notes.note_code = pr_quote.part_text[4,15] 
				DECLARE c_note CURSOR FOR 
				SELECT * FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = pr_notes.note_code 
				ORDER BY note_num 
				FOREACH c_note INTO pr_notes.* 
					PRINT COLUMN 06,pr_notes.note_text 
				END FOREACH 
			ELSE 
				IF pr_product.desc_text IS NULL THEN 
					PRINT COLUMN 06, pr_quote.part_text 
				END IF 
			END IF 
			PRINT COLUMN 01, "Available: ",pr_quote.quote_lead_text clipped," ",	pr_quote.quote_lead_text2 

		AFTER GROUP OF pr_quote.order_num 
			SELECT * INTO pr_quotehead.* FROM quotehead 
			WHERE quotehead.cmpy_code = cmpy_code 
			AND quotehead.order_num = pr_quote.order_num 
			IF (pr_quotehead.freight_amt + pr_quotehead.freight_tax_amt) = 0 
			AND (pr_quotehead.hand_amt + pr_quotehead.hand_tax_amt) = 0 THEN 
				NEED 2 LINES 
				PRINT COLUMN 64, "-------------" 
				PRINT COLUMN 53, "Total:", 
				COLUMN 64, GROUP sum(pr_quote.line_tot_amt) USING "--,---,--&.&&" 
			ELSE 
				NEED 6 LINES 
				PRINT COLUMN 64, "-------------" 
				PRINT COLUMN 64, GROUP sum(pr_quote.line_tot_amt) USING "--,---,--&.&&" 
				IF pr_quotehead.freight_amt > 0 THEN 
					PRINT COLUMN 53, "Freight:", 
					COLUMN 64, pr_quotehead.freight_tax_amt 
					+ pr_quotehead.freight_amt USING "--,---,--&.&&" 
				END IF 
				IF pr_quotehead.hand_amt > 0 THEN 
					PRINT COLUMN 53, "Insurance:", 
					COLUMN 64, pr_quotehead.hand_tax_amt 
					+ pr_quotehead.hand_amt USING "--,---,--&.&&" 
				END IF 
				PRINT COLUMN 64, "-------------" 
				PRINT COLUMN 53, "Total:", 
				COLUMN 64, GROUP sum (pr_quote.line_tot_amt) 
				+ pr_quotehead.freight_amt 
				+ pr_quotehead.freight_tax_amt 
				+ pr_quotehead.hand_tax_amt 
				+ pr_quotehead.hand_amt USING "--,---,--&.&&" 
			END IF 

			IF glob_rec_qpparms.quote_user_text IS NOT NULL THEN 

				#OUTPUT details of quote TO an ascii file FOR use in wp
				#Original file name = glob_rec_qpparms.quote_user_text clipped, "/q",		pr_quote.order_num USING "&&&&&&&", ".asc" 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("QA8-OUT","QA8_rpt_list_out","N/A - File export ?", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT QA8_rpt_list_out TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				
				#---------------------------------------------------------
				OUTPUT TO REPORT QA8_rpt_list_out(l_rpt_idx,
				pr_quotehead.*)
				#---------------------------------------------------------
				
				#------------------------------------------------------------
				FINISH REPORT QA8_rpt_list_out
				CALL rpt_finish("QA8_rpt_list_out")
				#------------------------------------------------------------

			END IF 

			PAGE TRAILER 
				PRINT under_line 
				PRINT COLUMN 1, glob_rec_qpparms.footer1_text 
				PRINT COLUMN 1, glob_rec_qpparms.footer2_text 
				PRINT COLUMN 1, glob_rec_qpparms.footer3_text 
				PRINT ascii(pr_printcodes.compress_1), 
				ascii(pr_printcodes.compress_2), 
				ascii(pr_printcodes.compress_3), 
				ascii(pr_printcodes.compress_4), 
				ascii(pr_printcodes.compress_5), 
				"This quotation OR supply includes AND IS made subject TO our ", 
				"standard conditions of sale form HSE 1 which has previously been " 
				PRINT " circulated TO you. Additional copies available on request." 
				PRINT ascii(pr_printcodes.normal_1), 
				ascii(pr_printcodes.normal_2), 
				ascii(pr_printcodes.normal_3), 
				ascii(pr_printcodes.normal_4), 
				ascii(pr_printcodes.normal_5), 
				COLUMN 29, "Page", COLUMN 34, pageno USING "####" 
END REPORT 
###########################################################################
# END REPORT QA8_rpt_list(p_rpt_idx,pr_quote, pr_printcodes)
###########################################################################


###########################################################################
# REPORT QA8_rpt_list_out(p_rpt_idx,pr_quote, pr_printcodes)
#
# 
###########################################################################
REPORT QA8_rpt_list_out(p_rpt_idx,p_rec_quotehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_quotehead RECORD LIKE quotehead.* 
	DEFINE pr_customer RECORD LIKE customer.* 

	OUTPUT 

	FORMAT 
 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		ON EVERY ROW 
			SELECT * INTO pr_customer.* FROM customer 
			WHERE cmpy_code = p_rec_quotehead.cmpy_code 
			AND cust_code = p_rec_quotehead.cust_code 

			IF p_rec_quotehead.rev_date IS NULL THEN 
				PRINT COLUMN 01, p_rec_quotehead.quote_date USING "dd/mm/yy", 
				COLUMN 15, p_rec_quotehead.order_num USING "&&&&&&&" 
			ELSE 
				PRINT COLUMN 01, p_rec_quotehead.rev_date USING "dd/mm/yy", 
				COLUMN 15, p_rec_quotehead.order_num USING "&&&&&&&" 
			END IF 

			PRINT p_rec_quotehead.cust_code 
			SKIP 1 line 

			PRINT pr_customer.name_text clipped 
			PRINT pr_customer.addr1_text clipped 
			PRINT pr_customer.addr2_text clipped 

			PRINT COLUMN 01, pr_customer.city_text clipped, 
			COLUMN 35, pr_customer.post_code USING "&&&&" 
			PRINT pr_customer.country_code --@db-patch_2020_10_04 report--
			SKIP 1 line 
			PRINT pr_customer.fax_text 
			PRINT p_rec_quotehead.entry_code 
			PRINT p_rec_quotehead.ord_text 
			
END REPORT 
###########################################################################
# END REPORT QA8_rpt_list_out(p_rpt_idx,pr_quote, pr_printcodes)
###########################################################################