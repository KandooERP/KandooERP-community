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

	Source code beautified by beautify.pl on 2019-12-31 14:28:32	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 

GLOBALS "KL2_GLOBALS.4gl" 

FUNCTION write_invs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_subschedule RECORD LIKE subschedule.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	pr_term RECORD LIKE term.*, 
	err_message CHAR(60), 
	pr_araudit RECORD LIKE araudit.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	idx SMALLINT 

	OPEN WINDOW wkl2 at 10,15 WITH 3 ROWS, 50 COLUMNS 
	attribute(border) 
	LET msgresp = kandoomsg("K",1017,"") 
	# Generating invoices please wait
	DISPLAY "Customer : " at 2,2 
	DISPLAY "Invoice : " at 3,2 

	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE c_tentinvhead CURSOR FOR 
	SELECT * FROM tentinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE c_tentinvdetl CURSOR FOR 
	SELECT * FROM tentinvdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_tentinvhead.inv_num 

	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
		GOTO bypass 
		LABEL recovery: 
		OUTPUT TO REPORT KL2_rpt_list_EXCEP(err_message,pr_subhead.*) 
		IF error_recover(err_message,status) != "Y" THEN 
			CLOSE WINDOW wkl2 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET query_text = " SELECT * FROM customer", 
			" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			" AND cust_code = ? ", 
			" FOR update" 
			PREPARE s_customer FROM query_text 
			DECLARE c_customer CURSOR FOR s_customer 
			DECLARE c_subhead CURSOR FOR 
			SELECT * INTO pr_subhead.* 
			FROM subhead 
			WHERE sub_num = pr_tentinvhead.inv_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			DECLARE c_subdetl CURSOR FOR 
			SELECT * FROM subdetl 
			WHERE sub_num = pr_tentinvhead.inv_num 
			AND sub_line_num = pr_tentinvdetl.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			DECLARE c_subschedule CURSOR FOR 
			SELECT * FROM subschedule 
			WHERE sub_num = pr_subhead.sub_num 
			AND sub_line_num = pr_subdetl.sub_line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			LET query_text = "SELECT * FROM subcustomer ", 
			"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND cust_code= ? ", 
			"AND ship_code= ? ", 
			"AND sub_type_code = ? ", 
			"AND part_code= ? ", 
			"AND comm_date= ? ", 
			"AND end_date= ? " 
			PREPARE s_subcustomer FROM query_text 
			DECLARE c_subcustomer CURSOR FOR s_subcustomer 
			#INSERT invoiceDetl Record
			DECLARE c_invoicedetl CURSOR FOR 
			INSERT INTO invoicedetl VALUES (pr_invoicedetl.*)		
			
			OPEN c_invoicedetl 
			DECLARE c_subaudit CURSOR FOR 
			INSERT INTO subaudit VALUES (pr_subaudit.*) 
			OPEN c_subaudit 
			
			FOREACH c_tentinvhead INTO pr_tentinvhead.* 
				IF int_flag OR quit_flag THEN 
					
					IF kandoomsg("U",8503,"") = "N" THEN #8503 Continue Report(Y/N) 
						
						LET msgresp=kandoomsg("U",9501,"") #9501 Report Terminated 
						EXIT FOREACH 
					END IF 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
				OPEN c_subhead 
				FETCH c_subhead INTO pr_subhead.*
				 
				IF pr_subhead.rev_num <> pr_tentinvhead.rev_num THEN 
					LET err_message = "Subscription has been edited" 
					OUTPUT TO REPORT KL2_rpt_list_EXCEP(err_message,pr_subhead.*) 
					CONTINUE FOREACH 
				END IF 
				
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_tentinvhead.cust_code 
				IF pr_customer.corp_cust_code IS NOT NULL 
				AND pr_customer.corp_cust_ind = "1" THEN 
					LET pr_invoicehead.cust_code = pr_customer.corp_cust_code 
					LET pr_invoicehead.org_cust_code = pr_tentinvhead.cust_code 
				ELSE 
				LET pr_invoicehead.cust_code = pr_tentinvhead.cust_code 
				LET pr_invoicehead.org_cust_code = pr_tentinvhead.cust_code 
			END IF 
			OPEN c_customer USING pr_invoicehead.cust_code 
			FETCH c_customer INTO pr_customer.* 
			LET err_message = "KL2 - Next invoice number update" 
			LET pr_invoicehead.inv_num = 
			next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,pr_invoicehead.acct_override_code) 
			IF pr_invoicehead.inv_num < 0 THEN 
				LET err_message = "KL2 - Error Obtaining Next Trans no." 
				LET status = pr_invoicehead.inv_num 
				GOTO recovery 
			END IF 
			DISPLAY pr_invoicehead.cust_code at 2,12 
			DISPLAY pr_invoicehead.inv_num at 3,12 
			LET pr_invoicehead.cmpy_code = pr_tentinvhead.cmpy_code 
			LET pr_invoicehead.ord_num = pr_tentinvhead.ord_num 
			LET pr_invoicehead.purchase_code = pr_tentinvhead.purchase_code 
			LET pr_invoicehead.ref_num = pr_tentinvhead.ref_num 
			LET pr_invoicehead.inv_date = pr_tentinvhead.inv_date 
			LET pr_invoicehead.sale_code = pr_tentinvhead.sale_code 
			LET pr_invoicehead.term_code = pr_tentinvhead.term_code 
			LET pr_invoicehead.disc_per = pr_tentinvhead.disc_per 
			LET pr_invoicehead.tax_code = pr_tentinvhead.tax_code 
			LET pr_invoicehead.tax_per = pr_tentinvhead.tax_per 
			LET pr_invoicehead.goods_amt = pr_tentinvhead.goods_amt 
			LET pr_invoicehead.hand_amt = pr_tentinvhead.hand_amt 
			LET pr_invoicehead.hand_tax_code = pr_tentinvhead.hand_tax_code 
			LET pr_invoicehead.hand_tax_amt = pr_tentinvhead.hand_tax_amt 
			LET pr_invoicehead.freight_amt = pr_tentinvhead.freight_amt 
			LET pr_invoicehead.freight_tax_code = pr_tentinvhead.freight_tax_code 
			LET pr_invoicehead.freight_tax_amt = pr_tentinvhead.freight_tax_amt 
			LET pr_invoicehead.tax_amt = pr_tentinvhead.tax_amt 
			LET pr_invoicehead.disc_amt = pr_tentinvhead.disc_amt 
			LET pr_invoicehead.total_amt = pr_tentinvhead.total_amt 
			LET pr_invoicehead.cost_amt = pr_tentinvhead.cost_amt 
			LET pr_invoicehead.due_date = pr_tentinvhead.due_date 
			LET pr_invoicehead.disc_date = pr_tentinvhead.disc_date 
			LET pr_invoicehead.year_num = pr_tentinvhead.year_num 
			LET pr_invoicehead.period_num = pr_tentinvhead.period_num 
			LET pr_invoicehead.line_num = pr_tentinvhead.line_num 
			LET pr_invoicehead.ship_code = pr_tentinvhead.ship_code 
			LET pr_invoicehead.name_text = pr_tentinvhead.name_text 
			LET pr_invoicehead.addr1_text = pr_tentinvhead.addr1_text 
			LET pr_invoicehead.addr2_text = pr_tentinvhead.addr2_text 
			LET pr_invoicehead.city_text = pr_tentinvhead.city_text 
			LET pr_invoicehead.state_code = pr_tentinvhead.state_code 
			LET pr_invoicehead.post_code = pr_tentinvhead.post_code 
			LET pr_invoicehead.country_code = pr_tentinvhead.country_code --@db-patch_2020_10_04--
			LET pr_invoicehead.ship1_text = pr_tentinvhead.ship1_text 
			LET pr_invoicehead.ship2_text = pr_tentinvhead.ship2_text 
			LET pr_invoicehead.fob_text = pr_tentinvhead.fob_text 
			LET pr_invoicehead.prepaid_flag = pr_tentinvhead.prepaid_flag 
			LET pr_invoicehead.com1_text = pr_tentinvhead.com1_text 
			LET pr_invoicehead.com2_text = pr_tentinvhead.com2_text 
			LET pr_invoicehead.currency_code = pr_tentinvhead.currency_code 
			LET pr_invoicehead.conv_qty = pr_tentinvhead.conv_qty 
			LET pr_invoicehead.acct_override_code = pr_tentinvhead.acct_override_code 
			LET pr_invoicehead.invoice_to_ind = pr_tentinvhead.invoice_to_ind 
			LET pr_invoicehead.territory_code = pr_tentinvhead.territory_code 
			LET pr_invoicehead.mgr_code = pr_tentinvhead.mgr_code 
			LET pr_invoicehead.area_code = pr_tentinvhead.area_code 
			LET pr_invoicehead.carrier_code = pr_tentinvhead.carrier_code 
			LET pr_invoicehead.country_code = pr_tentinvhead.country_code 
			LET pr_invoicehead.on_state_flag = "N" 
			LET pr_invoicehead.printed_num = 0 
			LET pr_invoicehead.posted_flag = "N" 
			LET pr_invoicehead.seq_num = 0 
			LET pr_invoicehead.printed_num = 0 
			LET pr_invoicehead.story_flag = NULL 
			LET pr_invoicehead.rev_date = today 
			LET pr_invoicehead.rev_num = 0 
			LET pr_invoicehead.inv_ind = "7" 
			LET pr_invoicehead.prev_paid_amt = 0 
			LET pr_invoicehead.jour_num = NULL 
			LET pr_invoicehead.post_date = NULL 
			LET pr_invoicehead.manifest_num = NULL 
			LET pr_invoicehead.stat_date = NULL 
			LET idx = 0 
			FOREACH c_tentinvdetl INTO pr_tentinvdetl.* 
				LET idx = idx + 1 
				OPEN c_subdetl 
				FETCH c_subdetl INTO pr_subdetl.* 
				LET pr_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_invoicedetl.cust_code = pr_invoicehead.cust_code 
				LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 
				LET pr_invoicedetl.line_num = idx 
				LET pr_invoicedetl.part_code = pr_tentinvdetl.part_code 
				LET pr_invoicedetl.ware_code = pr_tentinvdetl.ware_code 
				LET pr_invoicedetl.cat_code = pr_tentinvdetl.cat_code 
				LET pr_invoicedetl.ord_qty = pr_tentinvdetl.ord_qty 
				LET pr_invoicedetl.ship_qty = pr_tentinvdetl.ship_qty 
				LET pr_invoicedetl.line_text = pr_tentinvdetl.line_text 
				LET pr_invoicedetl.uom_code = pr_tentinvdetl.uom_code 
				LET pr_invoicedetl.unit_cost_amt = pr_tentinvdetl.unit_cost_amt 
				LET pr_invoicedetl.ext_cost_amt = pr_tentinvdetl.ext_cost_amt 
				LET pr_invoicedetl.disc_amt = pr_tentinvdetl.disc_amt 
				LET pr_invoicedetl.unit_sale_amt = pr_tentinvdetl.unit_sale_amt 
				LET pr_invoicedetl.ext_sale_amt = pr_tentinvdetl.ext_sale_amt 
				LET pr_invoicedetl.unit_tax_amt = pr_tentinvdetl.unit_tax_amt 
				LET pr_invoicedetl.ext_tax_amt = pr_tentinvdetl.ext_tax_amt 
				LET pr_invoicedetl.line_total_amt = pr_tentinvdetl.line_total_amt 
				LET pr_invoicedetl.line_acct_code = pr_tentinvdetl.line_acct_code 
				LET pr_invoicedetl.level_code = pr_tentinvdetl.level_code 
				LET pr_invoicedetl.tax_code = pr_tentinvdetl.tax_code 
				LET pr_invoicedetl.order_line_num = pr_tentinvdetl.order_line_num 
				LET pr_invoicedetl.order_num = pr_tentinvdetl.order_num 
				LET pr_invoicedetl.prodgrp_code = pr_tentinvdetl.prodgrp_code 
				LET pr_invoicedetl.maingrp_code = pr_tentinvdetl.maingrp_code 
				LET pr_invoicedetl.list_price_amt = pr_tentinvdetl.list_price_amt 
				LET pr_invoicedetl.return_qty = pr_tentinvdetl.return_qty 
				PUT c_invoicedetl 
				OPEN c_subcustomer USING pr_invoicehead.org_cust_code, 
				pr_invoicehead.ship_code, 
				pr_subhead.sub_type_code, 
				pr_invoicedetl.part_code, 
				pr_subhead.start_date, 
				pr_subhead.end_date 
				FETCH c_subcustomer INTO pr_subcustomer.* 
				IF status = 0 THEN 
					LET pr_subcustomer.next_seq_num=pr_subcustomer.next_seq_num +1 
					UPDATE subcustomer 
					SET inv_qty = inv_qty + pr_invoicedetl.ship_qty, 
					next_seq_num = pr_subcustomer.next_seq_num 
					WHERE cmpy_code = pr_invoicedetl.cmpy_code 
					AND cust_code = pr_invoicehead.org_cust_code 
					AND ship_code = pr_invoicehead.ship_code 
					AND sub_type_code = pr_subhead.sub_type_code 
					AND part_code = pr_invoicedetl.part_code 
					AND comm_date= pr_subhead.start_date 
					AND end_date= pr_subhead.end_date 
				END IF 
				LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subaudit.part_code = pr_invoicedetl.part_code 
				LET pr_subaudit.cust_code = pr_invoicehead.org_cust_code 
				LET pr_subaudit.ship_code = pr_invoicehead.ship_code 
				LET pr_subaudit.start_date = pr_subhead.start_date 
				LET pr_subaudit.end_date = pr_subhead.end_date 
				LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
				LET pr_subaudit.tran_date = pr_invoicehead.inv_date 
				LET pr_subaudit.entry_date = today 
				LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_subaudit.tran_qty = pr_invoicedetl.ship_qty 
				LET pr_subaudit.unit_amt = pr_invoicedetl.unit_sale_amt 
				LET pr_subaudit.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
				LET pr_subaudit.currency_code = pr_invoicehead.currency_code 
				LET pr_subaudit.conv_qty = pr_invoicehead.conv_qty 
				LET pr_subaudit.sub_num = pr_subhead.sub_num 
				LET pr_subaudit.tran_type_ind = "INV" 
				LET pr_subaudit.source_num = pr_invoicehead.inv_num 
				LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
				LET pr_subaudit.comm_text = "Invoice Generation (kl2)" 
				INSERT INTO subaudit VALUES (pr_subaudit.*) 
				UPDATE subdetl SET inv_qty = sub_qty 
				WHERE sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOREACH c_subschedule INTO pr_subschedule.* 
					UPDATE subschedule SET inv_qty = sched_qty 
					WHERE sub_num = pr_subschedule.sub_num 
					AND sub_line_num = pr_subschedule.sub_line_num 
					AND issue_num = pr_subschedule.issue_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END FOREACH 
				CLOSE c_subdetl 
				DELETE FROM tentinvdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = pr_tentinvdetl.inv_num 
				AND line_num = pr_tentinvdetl.line_num 
			END FOREACH 
			FLUSH c_invoicedetl 
			LET pr_invoicehead.line_num = idx 
			SELECT sum(ext_sale_amt), 
			sum(ext_tax_amt), 
			sum(ext_cost_amt) 
			INTO pr_invoicehead.goods_amt, 
			pr_invoicehead.tax_amt, 
			pr_invoicehead.cost_amt 
			FROM invoicedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = pr_invoicehead.inv_num 
			LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 
			LET pr_invoicehead.total_amt = pr_invoicehead.tax_amt 
			+ pr_invoicehead.goods_amt 
			+ pr_invoicehead.freight_amt 
			+ pr_invoicehead.freight_tax_amt 
			+ pr_invoicehead.hand_amt 
			+ pr_invoicehead.hand_tax_amt 

			#INSERT invoicehead Record
			IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,pr_invoicehead.*) THEN
				INSERT INTO invoicehead VALUES (pr_invoicehead.*)			
			ELSE
				DISPLAY pr_invoicehead.*
				CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
			END IF  

			SELECT unique 1 FROM subdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			AND (inv_qty != 0 
			OR issue_qty != 0) 
			IF sqlca.sqlcode = notfound THEN 
				## No lines shipped THEN sub IS unshipped
				LET pr_subhead.status_ind = "U" 
			ELSE 
			SELECT unique 1 FROM subdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			AND (inv_qty != sub_qty 
			OR inv_qty != issue_qty 
			OR issue_qty != sub_qty) 
			IF sqlca.sqlcode = 0 THEN 
				## Incomplete lines exists so sub IS partial shipped
				LET pr_subhead.status_ind = "P" 
			ELSE 
			LET pr_subhead.status_ind = "C" 
		END IF 
	END IF 
	UPDATE subhead SET last_inv_num = pr_invoicehead.inv_num, 
	hand_inv_amt = hand_inv_amt + pr_invoicehead.hand_amt, 
	hndtax_inv_amt = hndtax_inv_amt + 
	pr_invoicehead.hand_tax_amt, 
	freight_inv_amt = freight_inv_amt + 
	pr_invoicehead.freight_amt, 
	frttax_inv_amt = frttax_inv_amt + 
	pr_invoicehead.freight_tax_amt, 
	status_ind = pr_subhead.status_ind 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_subhead.sub_num 
	################################################
	## Now TO UPDATE customer
	################################################
	LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
	LET pr_customer.bal_amt = pr_customer.bal_amt 
	+ pr_invoicehead.total_amt 
	LET err_message = "KL2 - Unable TO add TO AR log table " 
	INITIALIZE pr_araudit.* TO NULL 
	LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_araudit.tran_date = pr_invoicehead.inv_date 
	LET pr_araudit.cust_code = pr_invoicehead.cust_code 
	LET pr_araudit.seq_num = pr_customer.next_seq_num 
	LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET pr_araudit.source_num = pr_invoicehead.inv_num 
	LET pr_araudit.tran_text = "Invoice (kl2)" 
	LET pr_araudit.tran_amt = pr_invoicehead.total_amt 
	LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_araudit.sales_code = pr_invoicehead.sale_code 
	LET pr_araudit.year_num = pr_invoicehead.year_num 
	LET pr_araudit.period_num = pr_invoicehead.period_num 
	LET pr_araudit.bal_amt = pr_customer.bal_amt 
	LET pr_araudit.currency_code = pr_customer.currency_code 
	LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
	LET pr_araudit.entry_date = today 
	INSERT INTO araudit VALUES (pr_araudit.*) 
	LET pr_customer.curr_amt = pr_customer.curr_amt 
	+ pr_invoicehead.total_amt 
	IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
		LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
	END IF 
	LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
	- pr_customer.bal_amt 
	IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
		LET pr_customer.ytds_amt = 0 
		LET pr_customer.mtds_amt = 0 
	END IF 
	LET pr_customer.ytds_amt = pr_customer.ytds_amt 
	+ pr_invoicehead.total_amt 
	IF month(pr_invoicehead.inv_date)>month(pr_customer.last_inv_date) THEN 
		LET pr_customer.mtds_amt = 0 
	END IF 
	LET pr_customer.mtds_amt = pr_customer.mtds_amt 
	+ pr_invoicehead.total_amt 
	LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
	LET err_message = "KL2 - Customer actual UPDATE " 
	UPDATE customer 
	SET next_seq_num = pr_customer.next_seq_num, 
	bal_amt = pr_customer.bal_amt, 
	curr_amt = pr_customer.curr_amt, 
	highest_bal_amt = pr_customer.highest_bal_amt, 
	cred_bal_amt = pr_customer.cred_bal_amt, 
	last_inv_date = pr_customer.last_inv_date, 
	ytds_amt = pr_customer.ytds_amt, 
	mtds_amt = pr_customer.mtds_amt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_customer.cust_code 
	OUTPUT TO REPORT KL2_rpt_list_SUCCESS(pr_invoicehead.*) 
	DELETE FROM tentinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_tentinvhead.inv_num 
END FOREACH 
CLOSE WINDOW wkl2 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	ROLLBACK WORK 
	RETURN 
END IF 
COMMIT WORK 
WHENEVER ERROR stop 
END FUNCTION 


REPORT KL2_rpt_list_EXCEP(err_message,pr_subhead) 
	DEFINE pr_subhead RECORD LIKE subhead.*, 
	err_message CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = "KL2 Invoice Generation Error log" 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 

			PRINT COLUMN 1, rpt_date, 
			COLUMN offset1, line1 clipped, 
			COLUMN 120, "Page: ", pageno USING "####" 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Subscription", 
			COLUMN 25,"Error message" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
		ON EVERY ROW 
			PRINT COLUMN 1, pr_subhead.cust_code, 
			COLUMN 10,pr_subhead.sub_num USING "#########", 
			COLUMN 25,err_message clipped 

		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KL2 ERROR LOG *****" 

END REPORT 

REPORT KL2_rpt_list_SUCCESS (pr_invoicehead) 
	DEFINE pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_desc CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = "KL2 Generated Invoice log" 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 

			PRINT COLUMN 1, rpt_date, 
			COLUMN offset1, line1 clipped, 
			COLUMN 120, "Page: ", pageno USING "####" 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Invoice", 
			COLUMN 25,"Description", 
			COLUMN 90,"Total" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
		ON EVERY ROW 
			PRINT COLUMN 1, pr_invoicehead.cust_code, 
			COLUMN 10,pr_invoicehead.inv_num USING "#########", 
			COLUMN 25,pr_invoicehead.name_text clipped, 
			COLUMN 85,pr_invoicehead.total_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KL2 INVOICE LOG *****" 
END REPORT 
