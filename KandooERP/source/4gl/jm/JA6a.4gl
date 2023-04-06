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

	Source code beautified by beautify.pl on 2020-01-02 19:48:18	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - VA6a
# Purpose - Used FOR JM invoicing, Invoice header detail entry.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 



FUNCTION inv_header() 

	DEFINE 
	cnt SMALLINT, 
	newyear SMALLINT 


	LET pv_invoice_present = true 
	LET pv_curr_idx = 0 
	LET pv_job_start_idx = 0 
	LET pv_prev_type_code = " " 

	INITIALIZE pr_tentinvhead.* TO NULL 

	LET pr_tentinvhead.goods_amt = 0 
	LET pr_tentinvhead.total_amt = 0 
	LET pr_tentinvhead.hand_amt = 0 
	LET pr_tentinvhead.hand_tax_amt = 0 
	LET pr_tentinvhead.freight_amt = 0 
	LET pr_tentinvhead.freight_tax_amt = 0 
	LET pr_tentinvhead.tax_amt = 0 
	LET pr_tentinvhead.disc_amt = 0 
	LET pr_tentinvhead.paid_amt = 0 
	LET pr_tentinvhead.disc_taken_amt = 0 
	LET pr_tentinvhead.disc_per = 0 
	LET pr_tentinvhead.cost_amt = 0 
	LET pr_tentinvhead.tax_per = 0 
	LET pr_tentinvhead.seq_num = 0 
	LET pr_tentinvhead.prev_paid_amt = 0 
	LET pr_tentinvhead.on_state_flag = "N" 
	LET pr_tentinvhead.posted_flag = "N" 
	LET pr_tentinvhead.printed_num = 1 
	LET pr_tentinvhead.inv_ind = "1" 
	LET pr_tentinvhead.prepaid_flag = "P" 
	LET pr_tentinvhead.bill_issue_ind = "2" 
	LET pr_tentinvhead.cost_ind = pr_arparms.costings_ind 

	SELECT max(inv_num) 
	INTO pr_tentinvhead.inv_num 
	FROM tentinvhead 

	IF status != 0 OR 
	pr_tentinvhead.inv_num IS NULL OR 
	pr_tentinvhead.inv_num = 0 THEN 
		LET pr_tentinvhead.inv_num = 1 
	ELSE 
		LET pr_tentinvhead.inv_num = pr_tentinvhead.inv_num + 1 
	END IF 

	LET pr_tentinvhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_tentinvhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_tentinvhead.entry_date = today 
	LET pr_tentinvhead.ship_date = today 


	LET pr_tentinvhead.inv_date = pr_contractdate.invoice_date 

	IF pr_contracthead.cons_inv_flag = "Y" THEN 
		LET pr_tentinvhead.inv_ind = "D" 
	ELSE 
		IF pr_contractdetl.type_code = "J" THEN 
			LET pr_tentinvhead.inv_ind = "3" 
			LET pr_tentinvhead.job_code = pr_contractdetl.job_code 

			SELECT job.* 
			INTO pr_job.* 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_contractdetl.job_code 

			IF status = 0 THEN 
				LET pr_tentinvhead.bill_issue_ind = pr_job.bill_issue_ind 
				LET pr_tentinvhead.com2_text = pr_job.title_text 
			ELSE 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = pr_contractdetl.job_code, " - Job NOT found" 

				OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
			END IF 
		END IF 
	END IF 

	IF pr_contracthead.cust_code IS NULL 
	OR pr_contracthead.cust_code = " " THEN 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = "Contract has no customer code" 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	SELECT * 
	INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_contracthead.cust_code 

	IF status = 0 THEN 
		IF pr_customer.hold_code IS NOT NULL THEN 
			LET pv_error = true 
			LET pv_error_run = true 
			LET pv_error_text = pr_customer.cust_code, " - Customer IS on hold" 

			OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
			pr_company.name_text, 
			pr_contractdate.contract_code, 
			pr_contractdate.inv_num, 
			pr_contractdate.invoice_date, 
			pr_contractdate.invoice_total_amt, 
			pv_error_text) 
		END IF 
	ELSE 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = pr_contracthead.cust_code, " Customer NOT found" 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	LET pv_corp_cust = false 

	IF pr_customer.corp_cust_code IS NOT NULL THEN 
		LET pv_corp_cust = true 
		SELECT * 
		INTO pr_corp_cust.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.corp_cust_code 

		IF status = 0 THEN 
			IF pr_customer.currency_code != pr_corp_cust.currency_code THEN 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = pr_customer.corp_cust_code, 
				" Corporate customer NOT found" 

				OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
			END IF 

			IF pr_corp_cust.hold_code IS NOT NULL THEN 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = pr_corp_cust.cust_code, 
				" Corp customer IS on hold" 

				OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
			END IF 

			IF pr_corp_cust.bal_amt > pr_corp_cust.cred_limit_amt THEN 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = " Corp customer ", pr_customer.corp_cust_code, 
				" IS over credit limit - ", pr_customer.bal_amt 

				OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
			END IF 
		ELSE 
			LET pv_error = true 
			LET pv_error_run = true 
			LET pv_error_text = pr_customer.corp_cust_code, 
			" Corp customer NOT found" 

			OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
			pr_company.name_text, 
			pr_contractdate.contract_code, 
			pr_contractdate.inv_num, 
			pr_contractdate.invoice_date, 
			pr_contractdate.invoice_total_amt, 
			pv_error_text) 
		END IF 

	ELSE 
		IF pr_customer.bal_amt > pr_customer.cred_limit_amt THEN 
			LET pv_error = true 
			LET pv_error_run = true 
			LET pv_error_text = " Customer ", pr_contracthead.cust_code, 
			" over credit limit - ", pr_customer.bal_amt 

			OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
			pr_company.name_text, 
			pr_contractdate.contract_code, 
			pr_contractdate.inv_num, 
			pr_contractdate.invoice_date, 
			pr_contractdate.invoice_total_amt, 
			pv_error_text) 
		END IF 
	END IF 

	IF pr_contracthead.sale_code IS NULL THEN 
		LET pr_tentinvhead.sale_code = pr_customer.sale_code 
	ELSE 
		LET pr_tentinvhead.sale_code = pr_contracthead.sale_code 
	END IF 

	LET pr_tentinvhead.term_code = pr_customer.term_code 
	LET pr_tentinvhead.tax_code = pr_customer.tax_code 

	IF pv_corp_cust THEN 
		LET pr_tentinvhead.cust_code = pr_customer.corp_cust_code 
		LET pr_tentinvhead.org_cust_code = pr_customer.cust_code 
		LET pr_tentinvhead.currency_code = pr_corp_cust.currency_code 
	ELSE 
		LET pr_tentinvhead.cust_code = pr_customer.cust_code 
		LET pr_tentinvhead.currency_code = pr_customer.currency_code 
	END IF 

	SELECT customership.* 
	INTO pr_customership.* 
	FROM customership 
	WHERE cust_code = pr_customer.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_code = pr_contractdetl.ship_code 

	IF status = notfound THEN 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = " Customer ", pr_contracthead.cust_code, 
		" shipping details NOT found" 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	IF pr_tentinvhead.inv_ind != "D" THEN 
		LET pr_tentinvhead.ship_code = pr_contractdetl.ship_code 
		LET pr_tentinvhead.name_text = pr_customership.name_text 
		LET pr_tentinvhead.addr1_text = pr_customership.addr_text 
		LET pr_tentinvhead.addr2_text = pr_customership.addr2_text 
		LET pr_tentinvhead.city_text = pr_customership.city_text 
		LET pr_tentinvhead.state_code = pr_customership.state_code 
		LET pr_tentinvhead.post_code = pr_customership.post_code 
		LET pr_tentinvhead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
		LET pr_tentinvhead.ship1_text = pr_customership.ship1_text 
		LET pr_tentinvhead.ship2_text = pr_customership.ship2_text 
		LET pr_tentinvhead.contact_text = pr_customership.contact_text 
		LET pr_tentinvhead.tele_text = pr_customership.tele_text 

	ELSE 
		IF pv_corp_cust 
		AND pr_customer.inv_addr_flag = "C" THEN # use corporate address 
			LET pr_tentinvhead.name_text = pr_corp_cust.name_text 
			LET pr_tentinvhead.addr1_text = pr_corp_cust.addr1_text 
			LET pr_tentinvhead.addr2_text = pr_corp_cust.addr2_text 
			LET pr_tentinvhead.city_text = pr_corp_cust.city_text 
			LET pr_tentinvhead.state_code = pr_corp_cust.state_code 
			LET pr_tentinvhead.post_code = pr_corp_cust.post_code 
			LET pr_tentinvhead.country_code = pr_corp_cust.country_code --@db-patch_2020_10_04--
			LET pr_tentinvhead.contact_text = pr_corp_cust.contact_text 
			LET pr_tentinvhead.tele_text = pr_corp_cust.tele_text 
		ELSE 
			LET pr_tentinvhead.name_text = pr_customer.name_text 
			LET pr_tentinvhead.addr1_text = pr_customer.addr1_text 
			LET pr_tentinvhead.addr2_text = pr_customer.addr2_text 
			LET pr_tentinvhead.city_text = pr_customer.city_text 
			LET pr_tentinvhead.state_code = pr_customer.state_code 
			LET pr_tentinvhead.post_code = pr_customer.post_code 
			LET pr_tentinvhead.country_code = pr_customer.country_code --@db-patch_2020_10_04--
			LET pr_tentinvhead.contact_text = pr_customer.contact_text 
			LET pr_tentinvhead.tele_text = pr_customer.tele_text 
		END IF 
	END IF 


	LET pr_tentinvhead.contract_code = pr_contractdetl.contract_code 
	LET pr_tentinvhead.year_num = pv_year_num 
	LET pr_tentinvhead.period_num = pv_period_num 




	SELECT name_text 
	INTO pr_salesperson.name_text 
	FROM salesperson 
	WHERE sale_code = pr_customer.sale_code 
	AND cmpy_code = pr_customer.cmpy_code 

	IF status = notfound THEN 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = "Sales person NOT found ", pr_customer.sale_code 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	SELECT * 
	INTO pr_tax.* 
	FROM tax 
	WHERE tax_code = pr_customer.tax_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = "Tax code NOT found ", pr_customer.tax_code 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	SELECT * 
	INTO pr_term.* 
	FROM term 
	WHERE term_code = pr_customer.term_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = "Term code NOT found ", pr_customer.term_code 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 

	LET pr_tentinvhead.disc_per = pr_term.disc_per 

























	IF pr_tentinvhead.due_date IS NULL THEN 
		LET pr_tentinvhead.due_date = pr_tentinvhead.inv_date 
	END IF 

	IF pr_tentinvhead.disc_date IS NULL THEN 
		LET pr_tentinvhead.disc_date = pr_tentinvhead.inv_date 
	END IF 

	LET pr_tentinvhead.tax_per = pr_tax.tax_per 

	CALL get_conv_rate(
		glob_rec_kandoouser.cmpy_code, 
		pr_tentinvhead.currency_code, 
		pr_tentinvhead.inv_date, 
		CASH_EXCHANGE_SELL) 
	RETURNING pr_tentinvhead.conv_qty 

	INITIALIZE pr_tentinvdetl.* TO NULL 
	INITIALIZE pa_tentinvdetl TO NULL 

END FUNCTION 



FUNCTION commit_invoice() 

	IF pv_error = false 
	AND pv_invoice_present = true 

	AND pv_curr_idx > 0 THEN 

		CALL invgen_inv_write() 
		LET pv_invoice_present = false 
		CALL inv_header() 
	END IF 

END FUNCTION 
