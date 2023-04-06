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





{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J36, Edit a JM invoice - culled FROM J31
#
# This program calls Four Major Functions
#          - J36_header()       J36a.4gl
#          - jobitems()     J36b.4gl
#          - get_new_line() J36c.4gl
#          - summup()       J36e.4gl
#          - write_inv()    J36f.4gl
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 
MAIN 

	DEFINE 
	pa_invoicehead array[600] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD, 
	pt_invoicehead RECORD LIKE invoicehead.*, 
	tmp_idx SMALLINT 

	#Initial UI Init
	CALL setModuleId("J36") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 

	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 

	SELECT glparms.* 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up GL Parameters first in GZP" 
		SLEEP 5 
		EXIT program 
	END IF 

	SELECT arparms.* 
	INTO pr_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up AR Parameters first in AZP" 
		SLEEP 5 
		EXIT program 
	END IF 

	CALL create_temp1() 

	LET pv_corp_cust = false 
	LET display_inv_num = "N" 
	OPEN WINDOW wj180 with FORM "J180" -- alch kd-747 
	CALL winDecoration_j("J180") -- alch kd-747 
	WHILE (true) 
		CLEAR FORM 
		INPUT BY NAME pt_invoicehead.job_code, 
		pt_invoicehead.cust_code, 
		pt_invoicehead.org_cust_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J36","input-pr_prpt_invoiceheadnt_optns-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (control-b) 
				CASE 
					WHEN infield (job_code) 
						LET pt_invoicehead.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.job_code 
						NEXT FIELD job_code 
					WHEN infield (cust_code) 
						LET pt_invoicehead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.cust_code 
						NEXT FIELD cust_code 
					WHEN infield (org_cust_code) 
						LET pt_invoicehead.org_cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.org_cust_code 
						NEXT FIELD org_cust_code 
				END CASE 
			BEFORE FIELD job_code 
				MESSAGE 
				"Enter Job AND Customer details FOR scan" attribute (yellow) 
			AFTER FIELD job_code 
				IF pt_invoicehead.job_code IS NOT NULL THEN 
					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pt_invoicehead.job_code 

					IF status = notfound THEN 
						ERROR "Job NOT found, try window" 
						NEXT FIELD job_code 
					END IF 
				END IF 

			AFTER FIELD cust_code 
				IF pt_invoicehead.cust_code IS NOT NULL THEN 
					SELECT * 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pt_invoicehead.cust_code 

					IF status = notfound THEN 
						ERROR "Customer NOT found, try window" 
						NEXT FIELD cust_code 
					END IF 
				END IF 

			AFTER FIELD org_cust_code 
				IF pt_invoicehead.org_cust_code IS NOT NULL THEN 
					SELECT * 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pt_invoicehead.org_cust_code 

					IF status = notfound THEN 
						ERROR "Original Customer NOT found, try window" 
						NEXT FIELD org_cust_code 
					END IF 
				END IF 

			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF pt_invoicehead.job_code IS NULL THEN 
						LET pt_invoicehead.job_code = "*" 
					END IF 
					IF pt_invoicehead.cust_code IS NULL THEN 
						LET pt_invoicehead.cust_code = "*" 
					END IF 
					IF pt_invoicehead.org_cust_code IS NULL THEN 
						LET pt_invoicehead.org_cust_code = "*" 
					END IF 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW wj180 
			EXIT program 
		END IF 

		MESSAGE "Enter criteria FOR invoice - ESC TO search" attribute(yellow) 

		CONSTRUCT BY NAME where_part ON 
		inv_num, 
		inv_date, 
		year_num, 
		period_num, 
		total_amt, 
		paid_amt, 
		posted_flag 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","J36","const-inv_num-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 

		LET select_text = "SELECT * ", 
		"FROM invoicehead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND job_code matches \"", 
		pt_invoicehead.job_code,"\" ", 
		"AND cust_code matches \"", 
		pt_invoicehead.cust_code,"\" ", 
		"AND (org_cust_code matches \"", 
		pt_invoicehead.org_cust_code,"\" ", 
		" OR org_cust_code IS NULL) ", 
		"AND ",where_part clipped," ", 
		"AND inv_ind = \"3\" ", 
		"ORDER BY inv_num " 

		PREPARE get_inv FROM select_text 
		DECLARE c_cust CURSOR FOR get_inv 

		LET idx = 0 
		FOREACH c_cust INTO pr_invoicehead.* 
			LET idx = idx + 1 
			IF idx > 600 THEN 
				EXIT FOREACH 
			END IF 
			LET pa_invoicehead[idx].inv_num = pr_invoicehead.inv_num 
			LET pa_invoicehead[idx].inv_date = pr_invoicehead.inv_date 
			LET pa_invoicehead[idx].year_num = pr_invoicehead.year_num 
			LET pa_invoicehead[idx].period_num = pr_invoicehead.period_num 
			LET pa_invoicehead[idx].total_amt = pr_invoicehead.total_amt 
			LET pa_invoicehead[idx].paid_amt = pr_invoicehead.paid_amt 
			LET pa_invoicehead[idx].posted_flag = pr_invoicehead.posted_flag 
		END FOREACH 
		IF idx = 0 THEN 
			MESSAGE " No JM invoices found FOR criteria " 
			attribute(yellow) 
			SLEEP 3 
			CONTINUE WHILE 
		END IF 

		CALL set_count (idx) 

		MESSAGE "" 
		MESSAGE "ESC-Reselect, RETURN-Edit Invoice, DEL-Cancel" 
		attribute (yellow) 

		INPUT ARRAY pa_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J36","input_arr-pa_invoicehead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_invoicehead.inv_num = pa_invoicehead[idx].inv_num 
				IF idx > arr_count() THEN 
					ERROR "There are no more invoices in the direction you are going" 
				END IF 

			BEFORE FIELD inv_num 
				IF pa_invoicehead[idx].inv_num IS NOT NULL THEN 
					SELECT * 
					INTO pr_invoicehead.* 
					FROM invoicehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_num = pa_invoicehead[idx].inv_num 
					IF (status = notfound) THEN 
						ERROR "Sorry cannot find this customers invoice" 
						SLEEP 1 
					END IF 

					DISPLAY BY NAME pr_invoicehead.job_code, 
					pr_invoicehead.cust_code, 
					pr_invoicehead.org_cust_code 
				END IF 

			BEFORE FIELD inv_date 
				LET allow_update = true 
				IF pr_invoicehead.posted_flag = "Y" THEN 
					IF post_err() THEN 
						NEXT FIELD inv_num 
					END IF 
				END IF 
				IF pr_invoicehead.paid_amt != 0 THEN 
					IF paid_err() THEN 
						NEXT FIELD inv_num 
					END IF 
				END IF 

				SELECT * 
				INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_invoicehead.job_code 

				IF status THEN 
					ERROR "Cannot find job details FOR Invoice...Cannot Edit" 
					SLEEP 5 
					NEXT FIELD inv_num 
				END IF 
				IF pr_job.bill_way_ind = "F" THEN 
					ERROR "Cannot edit fixed price invoices - credit only" 
					SLEEP 5 
					NEXT FIELD inv_num 
				END IF 
				LET tmp_idx = idx 
				LET first_time = true 
				CALL edit_invoice(pa_invoicehead[idx].inv_num) 
				IF allow_update THEN 
					LET idx = tmp_idx 
					LET pa_invoicehead[idx].inv_num = pr_invoicehead.inv_num 
					LET pa_invoicehead[idx].inv_date = pr_invoicehead.inv_date 
					LET pa_invoicehead[idx].year_num = pr_invoicehead.year_num 
					LET pa_invoicehead[idx].period_num = pr_invoicehead.period_num 
					LET pa_invoicehead[idx].total_amt = pr_invoicehead.total_amt 
					LET pa_invoicehead[idx].paid_amt = pr_invoicehead.paid_amt 
					LET pa_invoicehead[idx].posted_flag = pr_invoicehead.posted_flag 
					DISPLAY pa_invoicehead[idx].* TO sr_invoicehead[scrn].* 
				END IF 
				NEXT FIELD inv_num 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wj180 
		EXIT program 
	END IF 

END MAIN 



FUNCTION edit_invoice(invoice_num) 

	DEFINE 
	pr_menunames RECORD LIKE menunames.*, 
	pr_menunames2 RECORD LIKE menunames.*, 
	ans CHAR(1), 
	pr_exit SMALLINT, 
	invoice_num LIKE invoicehead.inv_num 



	DEFINE fv_cust_currency LIKE customer.currency_code, 
	fv_base_currency LIKE glparms.base_currency_code, 
	fv_xchange LIKE invoicehead.conv_qty, 
	fv_use_currency SMALLINT 
	LET pr_exit = false 
	OPEN WINDOW j169 with FORM "J169" -- alch kd-747 
	CALL winDecoration_j("J169") -- alch kd-747 
	SELECT * 
	INTO pr_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = invoice_num 

	IF status THEN 
		ERROR "Invoice selected NOT found - Aborting" 
		SLEEP 2 
		EXIT program 
	END IF 


	# Need TO convert invoice TO base currency IF it IS a foreign
	#            currency invoice.

	SELECT customer.currency_code 
	INTO fv_cust_currency 
	FROM customer 
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = pr_invoicehead.cust_code 

	SELECT glparms.base_currency_code 
	INTO fv_base_currency 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = '1' 

	IF fv_cust_currency <> pr_invoicehead.currency_code THEN 
		ERROR ' invoice NOT the same currency as the customer ! ' 
		SLEEP 002 
		EXIT program 
	END IF 

	LET pr_saved_inv.* = pr_invoicehead.* 

	IF fv_cust_currency <> fv_base_currency THEN 
		LET fv_use_currency = true 
	ELSE 
		LET fv_use_currency = false 
	END IF 

	IF fv_use_currency THEN 
		LET fv_xchange = pr_invoicehead.conv_qty 
		IF fv_xchange IS NULL OR fv_xchange = 0 THEN 
			LET fv_xchange = 1 
		END IF 
		LET pr_invoicehead.goods_amt = pr_invoicehead.goods_amt / fv_xchange 
		LET pr_invoicehead.hand_amt = pr_invoicehead.hand_amt / fv_xchange 
		LET pr_invoicehead.hand_tax_amt = 
		pr_invoicehead.hand_tax_amt / fv_xchange 
		LET pr_invoicehead.freight_amt = pr_invoicehead.freight_amt / fv_xchange 
		LET pr_invoicehead.freight_tax_amt = 
		pr_invoicehead.freight_tax_amt / fv_xchange 
		LET pr_invoicehead.tax_amt = pr_invoicehead.tax_amt / fv_xchange 
		LET pr_invoicehead.disc_amt = pr_invoicehead.disc_amt / fv_xchange 
		LET pr_invoicehead.total_amt = pr_invoicehead.total_amt / fv_xchange 
		LET pr_invoicehead.cost_amt = pr_invoicehead.cost_amt / fv_xchange 
		LET pr_invoicehead.paid_amt = pr_invoicehead.paid_amt / fv_xchange 
		LET pr_invoicehead.disc_taken_amt = 
		pr_invoicehead.disc_taken_amt / fv_xchange 
	END IF 
	WHILE J36_header() 
		OPEN WINDOW j127c with FORM "J127c" -- alch kd-747 
		CALL winDecoration_j("J127c") -- alch kd-747 
		WHILE select_lines() 
			WHILE disp_lineitems() 
				IF summup() THEN 
					CALL write_inv() 
					CASE glob_password 
					# normal invoice
						WHEN " " 
							OPEN WINDOW j181 with FORM "J181" -- alch kd-747 
							CALL winDecoration_j("J181") -- alch kd-747 
							IF NOT allow_update THEN 
								DISPLAY "No changes TO Invoice -"," VIEW ONLY " at 4,1 
							ELSE 
								DISPLAY BY NAME pr_invoicehead.inv_num 
							END IF 
							MENU "Invoice Edit" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","J36","menu-invoice_edit-2") -- alch kd-506 
								ON ACTION "WEB-HELP" -- albo kd-373 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND "Invoice" " Edit another Invoice" 
									LET pr_exit = true 
									LET quit_flag = true 
									EXIT MENU 
								COMMAND KEY(interrupt,"E")"Exit" " Exit JM Invoice Edit" 
									LET pr_exit = true 
									LET int_flag = false 
									LET quit_flag = false 
									EXIT program 
								COMMAND KEY (control-w) 
									CALL kandoohelp("") 
							END MENU 
							CLOSE WINDOW j181 
							# WHEN blank invoice IS created
						WHEN "BLKINV" 
							OPEN WINDOW j181 with FORM "J181" -- alch kd-747 
							CALL winDecoration_j("J181") -- alch kd-747 
							DISPLAY "Blank Invoice created -"," Edit discarded " at 4,1 
							MENU "Job Invoicing" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","J36","menu-job_invoicing-4") -- alch kd-506 
								ON ACTION "WEB-HELP" -- albo kd-373 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND "Invoice" " Edit another Invoice" 
									LET pr_exit = true 
									LET quit_flag = true 
									EXIT MENU 
								COMMAND KEY(interrupt,"E")"Exit" " Exit Invoice Edit" 
									LET pr_exit = true 
									LET int_flag = false 
									LET quit_flag = false 
									EXIT program 
								COMMAND KEY (control-w) 
									CALL kandoohelp("") 
							END MENU 
							CLOSE WINDOW j181 
					END CASE 
					EXIT WHILE 
				ELSE 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
			END WHILE 
			CALL setup_invhead() 
			IF pr_exit THEN 
				LET pr_exit = false 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE WINDOW j127c 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j169 

END FUNCTION 

FUNCTION post_err() 
	LET allow_update = false 
	#               OPEN WINDOW sorry AT 10,10 with 4 rows, 43 columns
	#                                 ATTRIBUTE(border)     -- alch KD-747
	DISPLAY "Cannot edit posted invoices. Raise credit instead" 
	at 3,1 
	DISPLAY "View only allowed FOR this invoice" at 4,1 
	--ATTRIBUTE(yellow) -- albo
	--               prompt "Any key TO view - Del TO cancel" FOR CHAR ans  -- albo
	CALL eventsuspend() --LET ans = AnyKey("Any key TO view OR Break TO cancel",16,15) -- albo 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#                   CLOSE WINDOW sorry     -- alch KD-747
		RETURN true 
	ELSE 
		#                   CLOSE WINDOW sorry     -- alch KD-747
		RETURN false 
	END IF 
END FUNCTION 

FUNCTION paid_err() 
	LET allow_update = false 
	#               OPEN WINDOW sorry AT 10,10 with 4 rows, 43 columns
	#                                 ATTRIBUTE(border)     -- alch KD-747
	DISPLAY "Unapply the invoice before you edit " at 3,1 
	DISPLAY "View only allowed FOR this invoice" at 4,1 
	--ATTRIBUTE(yellow) -- albo
	--               prompt "Any key TO view - Del TO cancel" FOR CHAR ans -- albo
	CALL eventsuspend() --LET ans = AnyKey("Any key TO view OR Break TO cancel",16,15) -- albo 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#                   CLOSE WINDOW sorry     -- alch KD-747
		RETURN true 
	ELSE 
		#                   CLOSE WINDOW sorry     -- alch KD-747
		RETURN false 
	END IF 
END FUNCTION 
