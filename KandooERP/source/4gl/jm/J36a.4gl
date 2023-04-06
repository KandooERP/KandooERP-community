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

	Source code beautified by beautify.pl on 2020-01-02 19:48:05	$Id: $
}




# Purpose - Used FOR JM invoice edit, Invoice header detail entry.

GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 


FUNCTION J36_header() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	return_status, 
	cnt, idx INTEGER, 
	newyear INTEGER, 
	saved_date LIKE invoicehead.inv_date, 
	pr_tmp_ship_code LIKE invoicehead.ship_code, 
	addr_cnt INTEGER 

	# reset all arrays AND pr_invoicedetl.*
	CALL setup_invhead() 

	SELECT customer.* 
	INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_invoicehead.cust_code 

	IF pr_customer.corp_cust_code IS NOT NULL THEN 
		LET pv_corp_cust = true 
		SELECT * 
		INTO pr_corp_cust.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.corp_cust_code 
		IF (status = notfound) THEN 
			ERROR "Corporate customer NOT found, setup using A15" 
			RETURN false 
		END IF 
		IF pr_customer.currency_code != 
		pr_corp_cust.currency_code THEN 
			ERROR 
			"Corporate AND Originating customer's currencies differ" 
			RETURN false 
		END IF 
	ELSE 
		LET pv_corp_cust = false 
	END IF 

	IF pv_corp_cust THEN 
		IF pr_corp_cust.hold_code IS NOT NULL THEN 
			#              OPEN WINDOW w1 AT 10,4 with 1 rows, 70 columns
			#              attribute (border, reverse)     -- alch KD-747
			MESSAGE "Corporate customer IS on hold, ", 
			"get release before proceeding " 
			SLEEP 3 
			#              CLOSE WINDOW w1     -- alch KD-747
			RETURN false 
		END IF 
	END IF 

	IF pr_customer.hold_code IS NOT NULL THEN 
		#         OPEN WINDOW w1 AT 10,4 with 2 rows, 60 columns
		#             attribute (border, reverse)     -- alch KD-747
		MESSAGE "Client ",pr_customer.cust_code clipped, 
		" IS on hold get release before", 
		" proceeding " 
		SLEEP 5 
		#         CLOSE WINDOW w1     -- alch KD-747
		RETURN false 
	END IF 
	CALL display_customer() 

	IF pr_invoicehead.org_cust_code IS NOT NULL THEN 
		LET pr_customership.cust_code = pr_invoicehead.org_cust_code 
	END IF 
	OPEN WINDOW A138 with FORM "A138" -- alch kd-747 
	CALL winDecoration_a("A138") -- alch kd-747 
	#ComboList needs double key lookup filter (company AND cust_code
	CALL comboList_customership_DOUBLE("ship_code",pr_customer.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
	LET pr_customership.ship_code = pr_invoicehead.ship_code 
	WHILE true 
		LET msgresp = kandoomsg("A",1035,"") 
		# MESSAGE "CTRL-C FOR Customer Inquiry"

		INPUT BY NAME pr_invoicehead.ship_code, 
		pr_invoicehead.name_text, 
		pr_invoicehead.addr1_text, 
		pr_invoicehead.addr2_text, 
		pr_invoicehead.city_text, 
		pr_invoicehead.state_code, 
		pr_invoicehead.post_code, 
		pr_invoicehead.country_code, --@db-patch_2020_10_04--
		pr_invoicehead.contact_text, 
		pr_invoicehead.tele_text WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J36a","input-pr_invoicehead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				IF infield (ship_code) THEN 
					LET pr_invoicehead.ship_code = 
					show_ship(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) 
					DISPLAY BY NAME pr_invoicehead.ship_code 

					NEXT FIELD ship_code 
				END IF 

			ON KEY (control-c) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
				NEXT FIELD ship_code 

			BEFORE FIELD ship_code 
				LET pr_tmp_ship_code = pr_customership.ship_code 

			AFTER FIELD ship_code 
				IF (pr_tmp_ship_code IS NULL 
				OR pr_tmp_ship_code != pr_invoicehead.ship_code) 
				OR pr_invoicehead.ship_code THEN 
					IF pr_invoicehead.ship_code IS NULL THEN 
						IF kandoomsg("A",8018,"") = "Y" THEN 
							## use billing address
							LET pr_invoicehead.ship_code = NULL 
							LET pr_invoicehead.name_text = pr_customer.name_text 
							LET pr_invoicehead.addr1_text = pr_customer.addr1_text 
							LET pr_invoicehead.addr2_text = pr_customer.addr2_text 
							LET pr_invoicehead.city_text = pr_customer.city_text 
							LET pr_invoicehead.state_code = pr_customer.state_code 
							LET pr_invoicehead.post_code = pr_customer.post_code 
							LET pr_invoicehead.country_code = pr_customer.country_code --@db-patch_2020_10_04--
							LET pr_invoicehead.contact_text = pr_customer.contact_text 
							LET pr_invoicehead.tele_text = pr_customer.tele_text 
						END IF 
					ELSE 
						SELECT * INTO pr_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_invoicehead.cust_code 
						AND ship_code = pr_invoicehead.ship_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("U",9105,"") 
							#9105 "Record Not Found; Try Window"
							NEXT FIELD ship_code 
						END IF 
						LET pr_invoicehead.ship_code = pr_customership.ship_code 
						LET pr_invoicehead.name_text = pr_customership.name_text 
						LET pr_invoicehead.addr1_text = pr_customership.addr_text 
						LET pr_invoicehead.addr2_text = pr_customership.addr2_text 
						LET pr_invoicehead.city_text = pr_customership.city_text 
						LET pr_invoicehead.state_code = pr_customership.state_code 
						LET pr_invoicehead.post_code = pr_customership.post_code 
						LET pr_invoicehead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
						LET pr_invoicehead.contact_text = pr_customership.contact_text 
						LET pr_invoicehead.tele_text = pr_customership.tele_text 
					END IF 
					DISPLAY BY NAME pr_invoicehead.name_text, 
					pr_invoicehead.addr1_text, 
					pr_invoicehead.addr2_text, 
					pr_invoicehead.city_text, 
					pr_invoicehead.state_code, 
					pr_invoicehead.post_code, 
					pr_invoicehead.country_code, --@db-patch_2020_10_04--
					pr_invoicehead.contact_text, 
					pr_invoicehead.tele_text 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		MESSAGE "" 
		OPEN WINDOW j128 with FORM "J128" -- alch kd-747 
		CALL winDecoration_j("J128") -- alch kd-747 
		LET msgresp = kandoomsg("A",1035,"") 
		# MESSAGE "CTRL-C FOR Customer Inquiry"
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_invoicehead.inv_date) 
		RETURNING pr_invoicehead.year_num,pr_invoicehead.period_num 
		SELECT * 
		INTO pr_tax.* 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = pr_invoicehead.tax_code 

		SELECT * 
		INTO pr_term.* 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = pr_invoicehead.term_code 

		DISPLAY BY NAME 
		pr_invoicehead.bill_issue_ind, 
		pr_invoicehead.inv_date, 
		pr_invoicehead.entry_code, 
		pr_invoicehead.year_num, 
		pr_invoicehead.period_num, 
		pr_invoicehead.sale_code, 
		pr_salesperson.name_text, 
		pr_invoicehead.term_code, 
		pr_invoicehead.tax_code 

		DISPLAY pr_term.desc_text, 
		pr_tax.desc_text 
		TO term.desc_text, 
		tax.desc_text 

		INPUT BY NAME pr_invoicehead.bill_issue_ind, 
		pr_invoicehead.inv_date, 
		pr_invoicehead.year_num, 
		pr_invoicehead.period_num, 
		pr_invoicehead.sale_code, 
		pr_invoicehead.term_code, 
		pr_invoicehead.tax_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J36","input_arr-pr_invoicehead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield (sale_code) 
						LET pr_invoicehead.sale_code = 
						show_sale(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_invoicehead.sale_code 

						NEXT FIELD sale_code 
					WHEN infield (term_code) 
						LET pr_invoicehead.term_code = 
						show_term(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_invoicehead.term_code 

						NEXT FIELD term_code 
					WHEN infield (tax_code) 
						LET pr_invoicehead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_invoicehead.tax_code 

						NEXT FIELD tax_code 
				END CASE 

			ON KEY (control-c) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) 
				NEXT FIELD inv_date 

			AFTER FIELD bill_issue_ind --customer details / customer invoice submenu 
				CASE pr_invoicehead.bill_issue_ind 
					WHEN "1" 
						DISPLAY "Summary " 
						TO bill_issue_text 

					WHEN "2" 
						DISPLAY "Detailed" 
						TO bill_issue_text 


					WHEN "3" 
						DISPLAY "Summary/Descrpt" 
						TO bill_issue_text 

					WHEN "4" 
						DISPLAY "Detail/Descript" 
						TO bill_issue_text 


					OTHERWISE 
						error" Billing Issue Indicator Must be (1),(2),(3) OR (4)" 
						CLEAR bill_issue_text 
						NEXT FIELD bill_issue_ind 
				END CASE 

			BEFORE FIELD inv_date 
				LET saved_date = pr_invoicehead.inv_date 

			AFTER FIELD inv_date 
				IF pr_invoicehead.inv_date IS NULL THEN 
					LET pr_invoicehead.inv_date = today 
				END IF 
				IF pr_invoicehead.inv_date != saved_date THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_invoicehead.inv_date) 
					RETURNING pr_invoicehead.year_num, 
					pr_invoicehead.period_num 
				END IF 
				DISPLAY BY NAME pr_invoicehead.period_num 

			AFTER FIELD period_num 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, 
				pr_invoicehead.year_num, 
				pr_invoicehead.period_num, "JM") 
				RETURNING pr_invoicehead.year_num, 
				pr_invoicehead.period_num, 
				return_status 
				IF return_status THEN 
					NEXT FIELD inv_date 
				END IF 
			AFTER FIELD sale_code 
				SELECT name_text 
				INTO pr_salesperson.name_text 
				FROM salesperson 
				WHERE sale_code = pr_invoicehead.sale_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Salesperson NOT found, try window" 
					NEXT FIELD sale_code 
				ELSE 
					DISPLAY BY NAME pr_salesperson.name_text 

				END IF 
			AFTER FIELD term_code 
				SELECT term.* 
				INTO pr_term.* 
				FROM term 
				WHERE term.term_code = pr_invoicehead.term_code 
				AND term.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Term Code NOT found, try window" 
					NEXT FIELD term_code 
				ELSE 
					DISPLAY pr_term.desc_text TO term.desc_text 

				END IF 
			AFTER FIELD tax_code 
				SELECT tax.* 
				INTO pr_tax.* 
				FROM tax 
				WHERE tax.tax_code = pr_invoicehead.tax_code 
				AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Tax Code NOT found, try window" 
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY pr_tax.desc_text TO tax.desc_text 

				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					IF pr_invoicehead.inv_date IS NULL THEN 
						LET pr_invoicehead.inv_date = today 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, 
						pr_invoicehead.inv_date) 
						RETURNING pr_invoicehead.year_num, 
						pr_invoicehead.period_num 
						DISPLAY BY NAME pr_invoicehead.period_num 

					END IF 
					SELECT name_text 
					INTO pr_salesperson.name_text 
					FROM salesperson 
					WHERE sale_code = pr_invoicehead.sale_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						ERROR "Salesperson NOT found, try window" 
						NEXT FIELD sale_code 
					END IF 
					SELECT term.* 
					INTO pr_term.* 
					FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term.term_code = pr_invoicehead.term_code 
					IF status = notfound THEN 
						ERROR "Term Code NOT found - Try Window" 
						NEXT FIELD term_code 
					END IF 
					IF saved_date != pr_invoicehead.inv_date THEN 
						IF pr_term.day_date_ind = "D" THEN 
							LET pr_invoicehead.due_date = 
							pr_invoicehead.inv_date + 
							pr_term.due_day_num 
							LET pr_invoicehead.disc_date = 
							pr_invoicehead.inv_date + 
							pr_term.disc_day_num 
						ELSE 
							CALL check_feb(pr_invoicehead.inv_date, 
							pr_term.due_day_num) 
							RETURNING pr_invoicehead.due_date 











							LET pr_invoicehead.disc_date = 
							pr_invoicehead.due_date 
						END IF 
					END IF 
					IF pr_invoicehead.due_date IS NULL THEN 
						LET pr_invoicehead.due_date = 
						pr_invoicehead.inv_date 
					END IF 
					IF pr_invoicehead.disc_date IS NULL THEN 
						LET pr_invoicehead.disc_date = 
						pr_invoicehead.inv_date 
					END IF 
					LET pr_invoicehead.ship_date = pr_invoicehead.inv_date 
					SELECT * 
					INTO pr_tax.* 
					FROM tax 
					WHERE tax.tax_code = pr_invoicehead.tax_code 
					AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (status = notfound) THEN 
						ERROR "Tax Code NOT found, try window" 
						NEXT FIELD tax_code 
					END IF 
					LET pr_invoicehead.tax_per = pr_tax.tax_per 
					CALL valid_period(glob_rec_kandoouser.cmpy_code, 
					pr_invoicehead.year_num, 
					pr_invoicehead.period_num, 
					"JM") 
					RETURNING pr_invoicehead.year_num, 
					pr_invoicehead.period_num, 
					return_status 
					IF return_status THEN 
						NEXT FIELD inv_date 
					END IF 
					
					CALL get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						pr_invoicehead.currency_code, 
						pr_invoicehead.inv_date, 
						CASH_EXCHANGE_SELL) 
					RETURNING pr_invoicehead.conv_qty 
				END IF
				 
		END INPUT 
		#------------------------------------
		

		CLOSE WINDOW j128 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	#----------------------------------------------------

	CLOSE WINDOW A138 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION display_customer() 
	DEFINE 
	cred_avail_amt, 
	balance_amt money(12,2), 
	p1_overdue, p1_baddue LIKE customer.over1_amt, 
	fr_customer RECORD LIKE customer.* 

	IF pv_corp_cust AND pr_customer.inv_addr_flag = "C" THEN 
		LET fr_customer.* = pr_corp_cust.* 
	ELSE 
		LET fr_customer.* = pr_customer.* 
	END IF 

	LET p1_overdue = (fr_customer.over1_amt + 
	fr_customer.over30_amt + 
	fr_customer.over60_amt + 
	fr_customer.over90_amt) 
	LET p1_baddue = (fr_customer.over30_amt + 
	fr_customer.over60_amt + 
	fr_customer.over90_amt) 
	SELECT * 
	INTO pr_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_customer.term_code 

	LET balance_amt = pr_customer.bal_amt 
	LET cred_avail_amt = pr_customer.cred_limit_amt - 
	pr_customer.bal_amt - 
	pr_customer.onorder_amt 

	DISPLAY pr_job.job_code, 
	pr_job.title_text, 
	pr_customer.cust_code, 
	fr_customer.name_text, 
	fr_customer.name_text, 
	fr_customer.addr1_text, 
	fr_customer.addr2_text, 
	fr_customer.city_text, 
	fr_customer.state_code, 
	fr_customer.post_code, 
	fr_customer.country_code --@db-patch_2020_10_04--
	TO job.job_code, 
	job.title_text, 
	customer.cust_code, 
	customer.name_text, 
	cust_name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	customer.country_code --@db-patch_2020_10_04--

	IF p1_overdue > 0 THEN 
		IF p1_baddue > 0 THEN 
			DISPLAY BY NAME pr_customer.cred_limit_amt, 
			fr_customer.name_text, 
			fr_customer.addr1_text, 
			fr_customer.addr2_text, 
			fr_customer.city_text, 
			fr_customer.state_code, 
			fr_customer.post_code, 
			fr_customer.country_code, --@db-patch_2020_10_04--
			pr_customer.curr_amt, 
			pr_customer.over1_amt, 
			pr_customer.over30_amt, 
			pr_customer.over60_amt, 
			pr_customer.over90_amt, 
			pr_customer.bal_amt, 
			pr_customer.cred_limit_amt, 
			balance_amt, 
			pr_customer.onorder_amt, 
			cred_avail_amt, 
			pr_term.desc_text 
			attribute(red) 
		ELSE 
			DISPLAY BY NAME pr_customer.cred_limit_amt, 
			fr_customer.name_text, 
			fr_customer.addr1_text, 
			fr_customer.addr2_text, 
			fr_customer.city_text, 
			fr_customer.state_code, 
			fr_customer.post_code, 
			fr_customer.country_code, --@db-patch_2020_10_04--
			pr_customer.curr_amt, 
			pr_customer.over1_amt, 
			pr_customer.over30_amt, 
			pr_customer.over60_amt, 
			pr_customer.over90_amt, 
			pr_customer.bal_amt, 
			pr_customer.cred_limit_amt, 
			balance_amt, 
			pr_customer.onorder_amt, 
			cred_avail_amt, 
			pr_term.desc_text 
			attribute(yellow) 
		END IF 
	ELSE 
		DISPLAY BY NAME pr_customer.cred_limit_amt, 
		fr_customer.name_text, 
		fr_customer.addr1_text, 
		fr_customer.addr2_text, 
		fr_customer.city_text, 
		fr_customer.state_code, 
		fr_customer.post_code, 
		fr_customer.country_code, --@db-patch_2020_10_04--
		pr_customer.curr_amt, 
		pr_customer.over1_amt, 
		pr_customer.over30_amt, 
		pr_customer.over60_amt, 
		pr_customer.over90_amt, 
		pr_customer.bal_amt, 
		pr_customer.cred_limit_amt, 
		balance_amt, 
		pr_customer.onorder_amt, 
		cred_avail_amt, 
		pr_term.desc_text 
		attribute(green) 
	END IF 
END FUNCTION 


FUNCTION setup_invhead() 
	DEFINE 
	cnt INTEGER 

	INITIALIZE pr_invoicedetl.* TO NULL 
	LET note_size = 0 
	FOR cnt = 1 TO 600 
		INITIALIZE pa_invoicedetl[cnt].* TO NULL 
		INITIALIZE pa_notes[cnt].* TO NULL 
	END FOR 
END FUNCTION 


FUNCTION create_temp1() 

	CREATE temp TABLE tempbill 
	( 
	trans_invoice_flag CHAR(1), 
	trans_date DATE NOT null, 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt money(16,2), # \ 

	trans_qty FLOAT, # - total OF transaction 
	charge_amt money(16,2), # / 

	apply_qty FLOAT, # \ 
	apply_amt DECIMAL(16,2), # - this invoice line 
	apply_cos_amt DECIMAL(16,2), # / 
	desc_text CHAR(40), # -who PUT this FIELD here?? 
	prev_apply_qty DECIMAL(15,3), # \ 
	prev_apply_amt DECIMAL(16,2), # - previous invoice LINES 
	prev_apply_cos_amt DECIMAL(16,2),# / 
	allocation_ind CHAR(1) 
	) with no LOG 
	CREATE unique INDEX tempbill ON tempbill(var_code, 
	activity_code, 
	seq_num) 

	# editbill holds a copy of tempbill before any edits done so
	# comparison can be made AND the differences written TO resbill

	CREATE temp TABLE editbill 
	( 
	trans_invoice_flag CHAR(1), 
	trans_date DATE NOT null, 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt money(16,2), # \ 

	trans_qty FLOAT, # - total OF transaction 
	charge_amt money(16,2), # / 

	apply_qty FLOAT, # \ 
	apply_amt DECIMAL(16,2), # - this invoice line 
	apply_cos_amt DECIMAL(16,2), # / 
	desc_text CHAR(40), # -who PUT this FIELD here?? 
	prev_apply_qty DECIMAL(15,3), # \ 
	prev_apply_amt DECIMAL(16,2), # - previous invoice LINES 
	prev_apply_cos_amt DECIMAL(16,2),# / 
	allocation_ind CHAR(1) 
	) with no LOG 

	CREATE unique INDEX editbill ON editbill(var_code, 
	activity_code, 
	seq_num) 

	CREATE temp TABLE addbill 
	( 
	trans_invoice_flag CHAR(1), 
	trans_date DATE NOT null, 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt money(16,2), # \ 

	trans_qty FLOAT, # - total OF transaction 
	charge_amt money(16,2), # / 

	apply_qty FLOAT, # \ 
	apply_amt DECIMAL(16,2), # - this invoice line 
	apply_cos_amt DECIMAL(16,2), # / 
	desc_text CHAR(40), # -who PUT this FIELD here?? 
	prev_apply_qty DECIMAL(15,3), # \ 
	prev_apply_amt DECIMAL(16,2), # - previous invoice LINES 
	prev_apply_cos_amt DECIMAL(16,2),# / 
	allocation_ind CHAR(1) 
	) with no LOG 

	CREATE unique INDEX addbill ON addbill(var_code, 
	activity_code, 
	seq_num) 

END FUNCTION 


FUNCTION cc_credit_chk(fv_cust_code,fv_corp_cust, fv_cred_limit, fv_extra) 

	DEFINE fv_cust_code LIKE customer.cust_code, 
	fv_corp_cust LIKE customer.cust_code, 
	fv_cred_limit LIKE customer.cred_limit_amt, 
	fv_inv_tot LIKE customer.cred_limit_amt, 
	fv_cred_tot LIKE customer.cred_limit_amt, 

	# fv_extra records the extra credit requested
	fv_extra LIKE customer.bal_amt 

	# This FUNCTION assumes that fv_cust_code has the original customer information
	# AND that fv_corp_cust has the corporate customer information

	SELECT sum(total_amt - paid_amt) 
	INTO fv_inv_tot 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = fv_corp_cust 
	AND org_cust_code = fv_cust_code 
	AND total_amt != paid_amt 

	IF fv_inv_tot IS NULL THEN 
		LET fv_inv_tot = 0 
	END IF 

	# Do this here TO save having TO check credits
	IF (fv_inv_tot + fv_extra) < fv_cred_limit THEN 
		RETURN true 
	END IF 

	SELECT sum(total_amt - appl_amt) 
	INTO fv_cred_tot 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = fv_corp_cust 
	AND org_cust_code = fv_cust_code 
	AND total_amt != appl_amt 

	IF fv_cred_tot IS NULL THEN 
		LET fv_cred_tot = 0 
	END IF 

	LET fv_inv_tot = fv_inv_tot - fv_cred_tot 

	RETURN ( (fv_inv_tot + fv_extra) < fv_cred_limit ) 

END FUNCTION 
