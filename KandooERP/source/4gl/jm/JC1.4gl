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

	Source code beautified by beautify.pl on 2020-01-02 19:48:19	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM JC1.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 
# Purpose: Credits a JM invoice

MAIN 
	DEFINE 
	pa_invoicehead ARRAY [300] OF RECORD 
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
	CALL setModuleId("JC1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	LET pr_kandoooption_sn = get_kandoooption_feature_state("JM","SN") 
	SELECT credit_ref2a_text, 
	credit_ref2b_text INTO pr_arparms.credit_ref2a_text, 
	pr_arparms.credit_ref2b_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	CREATE temp TABLE statab(cmpy_code CHAR(2), 
	ware CHAR(3), 
	part CHAR(15), 
	ship DECIMAL(12, 3), 
	which CHAR(3)) 
	with no LOG 
	SELECT jmparms.* INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,"") 
		#ERROR " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	SELECT glparms.* INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G",7006,"") 
		#ERROR " Must SET up GL Parameters first in GZP"
		EXIT program 
	END IF 
	SELECT arparms.* INTO pr_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up AR Parameters first in AZP"
		LET msgresp = kandoomsg("A",7005,"") 
		EXIT program 
	END IF 
	CALL create_temp1() 
	LET pv_corp_cust = false 
	LET display_inv_num = "N" 
	#   OPEN WINDOW wj183 AT 2, 3 WITH FORM "J183"
	#      attribute (border)      -- alch KD-747
	WHILE (true) 
		CLEAR FORM 
		INPUT BY NAME pt_invoicehead.job_code, 
		pt_invoicehead.cust_code, 
		pt_invoicehead.org_cust_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JC1","input-pt_invoicehead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(job_code) 
						LET pt_invoicehead.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.job_code 

						NEXT FIELD job_code 
					WHEN infield(cust_code) 
						LET pt_invoicehead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.cust_code 

						NEXT FIELD cust_code 
					WHEN infield(org_cust_code) 
						LET pt_invoicehead.org_cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pt_invoicehead.org_cust_code 

						NEXT FIELD org_cust_code 
				END CASE 
			BEFORE FIELD job_code 
				LET msgresp = kandoomsg("J",1010,"") 
				# MESSAGE "Enter Job AND Customer details FOR scan"
			AFTER FIELD job_code 
				IF pt_invoicehead.job_code IS NOT NULL THEN 
					SELECT * INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pt_invoicehead.job_code 
					IF status = notfound THEN 
						#ERROR "Job NOT found, try window"
						LET msgresp = kandoomsg("J",9558,"") 
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
						#ERROR "Customer NOT found, try window"
						LET msgresp = kandoomsg("J",9482,"") 
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
						LET msgresp = kandoomsg("J",9481,"") 
						#ERROR "Original Customer NOT found, try window"
						NEXT FIELD org_cust_code 
					END IF 
				END IF 
			AFTER INPUT 
				IF NOT (int_flag 
				OR quit_flag) THEN 
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
		IF int_flag 
		OR quit_flag THEN 
			#      CLOSE WINDOW wj183      -- alch KD-747
			EXIT program 
		END IF 
		LET msgresp = kandoomsg("J",1001,"") 
		# MESSAGE "Enter criteria FOR invoice - ESC TO search"
		CONSTRUCT BY NAME where_part ON 
		inv_num, 
		inv_date, 
		year_num, 
		period_num, 
		total_amt, 
		paid_amt, 
		posted_flag 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","JC1","const-inv_num-6") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		# MESSAGE " Searching Database - Please Wait"
		LET msgresp = kandoomsg("J",1002,"") 
		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 
		LET select_text = "SELECT * ", 
		"FROM invoicehead ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND job_code matches \"", pt_invoicehead.job_code, "\" ", 
		"AND cust_code matches \"", pt_invoicehead.cust_code, "\" ", 
		"AND (org_cust_code matches \"", pt_invoicehead.org_cust_code, "\" ", 
		" OR org_cust_code IS NULL) ", 
		"AND ", where_part clipped, 
		" ", "AND inv_ind = \"3\" ", 
		"ORDER BY inv_num " 
		PREPARE get_inv 
		FROM select_text 
		DECLARE c_cust CURSOR FOR get_inv 
		LET idx = 0 
		FOREACH c_cust INTO pr_invoicehead.* 
			LET idx = idx + 1 
			IF idx > 300 THEN 
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
			# MESSAGE " No JM invoices found FOR criteria "
			LET msgresp = kandoomsg("J",9480,"") 
			CONTINUE WHILE 
		END IF 
		CALL set_count(idx) 
		LET msgresp = kandoomsg("J",1429,"") 
		# MESSAGE "ESC-Reselect, RETURN-Create Credit, DEL-Cancel"
		INPUT ARRAY pa_invoicehead WITHOUT DEFAULTS 
		FROM sr_invoicehead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JC1","input_arr-pa_invoicehead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_invoicehead.inv_num = pa_invoicehead[idx].inv_num 
				IF idx > arr_count() THEN 
					#ERROR "There are no more invoices in the direction you are going"
					LET msgresp = kandoomsg("J",9001,"") 
				ELSE 
					DISPLAY pa_invoicehead[idx].* TO sr_invoicehead[scrn].* 

				END IF 
			AFTER ROW 
				DISPLAY pa_invoicehead[idx].* TO sr_invoicehead[scrn].* 

			BEFORE FIELD inv_num 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_invoicehead[idx].inv_num IS NOT NULL THEN 
					SELECT * INTO pr_invoicehead.* 
					FROM invoicehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_num = pa_invoicehead[idx].inv_num 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9003,"") 
						#ERROR "Sorry cannot find this customers invoice"
					END IF 
					DISPLAY BY NAME pr_invoicehead.job_code, 
					pr_invoicehead.cust_code, 
					pr_invoicehead.org_cust_code 

				END IF 
			BEFORE FIELD inv_date 
				LET allow_update = true 
				SELECT sum(total_amt)INTO pr_cred_sum 
				FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rma_num = pr_invoicehead.inv_num 
				LET pr_uncredited_amt = pr_invoicehead.total_amt - pr_cred_sum 
				IF pr_uncredited_amt <= 0 THEN 
					LET msgresp = kandoomsg("J", 9612, "") 
					#9612 "This invoice has already been fully credited"
					NEXT FIELD inv_num 
				END IF 
				IF pr_cred_sum > 0 THEN 
					LET msgresp = kandoomsg("J", 6000, "") 
					#6000 WARNING: Credit has already been created FOR this invoice"
				END IF 
				SELECT * INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_invoicehead.job_code 
				IF status THEN 
					#ERROR "Cannot find job details FOR Invoice...Cannot Edit"
					LET msgresp = kandoomsg("J",9004,"") 
					NEXT FIELD inv_num 
				END IF 
				IF pr_job.bill_way_ind = "F" THEN 
					#ERROR "Cannot jm credit fixed price invoices - ar credit only"
					LET msgresp = kandoomsg("J",9005,"") 
					NEXT FIELD inv_num 
				END IF 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_invoicehead.cust_code 
				IF status = notfound THEN 
					#ERROR "Customer NOT found, try window"
					LET msgresp = kandoomsg("J",9482,"") 
					NEXT FIELD inv_num 
				END IF 
				IF pr_customer.corp_cust_code IS NOT NULL THEN 
					LET pv_corp_cust = true 
					SELECT * INTO pr_corp_cust.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_customer.corp_cust_code 
					IF status = notfound THEN 
						#ERROR "Originating customer code NOT found, setup using A15"
						LET msgresp = kandoomsg("J",9481,"") 
						NEXT FIELD inv_num 
					END IF 
				ELSE 
					LET pv_corp_cust = false 
				END IF 
				LET tmp_idx = idx 
				LET func_type = "Credit Entry" 
				LET f_type = "J" {treat LIKE an edit} 
				LET first_time = 1 
				LET noerror = 1 
				LET display_cred_num = "N" 
				DELETE 
				FROM statab 
				WHERE 1 = 1 
				CALL credit_invoice(pa_invoicehead[idx].inv_num) 
				NEXT FIELD inv_num 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag 
		OR quit_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#   CLOSE WINDOW wj183      -- alch KD-747
		EXIT program 
	END IF 
END MAIN 



FUNCTION credit_invoice(invoice_num) 
	DEFINE 
	invoice_num LIKE invoicehead.inv_num 

	SELECT * INTO pr_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = invoice_num 
	IF status THEN 
		LET msgresp = kandoomsg("J",9003,"") 
		#ERROR "Invoice selected NOT found "
		#sleep 2
		#EXIT PROGRAM
		RETURN 
	END IF 
	INITIALIZE pr_credithead.* TO NULL 
	LET pr_credithead.cmpy_code = pr_invoicehead.cmpy_code 
	LET pr_credithead.cust_code = pr_invoicehead.cust_code 
	LET pr_credithead.org_cust_code = pr_invoicehead.org_cust_code 
	LET pr_credithead.rma_num = pr_invoicehead.inv_num 
	LET pr_credithead.job_code = pr_invoicehead.job_code 
	LET pr_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_credithead.entry_date = today 
	LET pr_credithead.cred_date = today 
	LET pr_credithead.sale_code = pr_invoicehead.sale_code 
	LET pr_credithead.tax_code = pr_invoicehead.tax_code 
	LET pr_credithead.tax_per = pr_invoicehead.tax_per 
	LET pr_credithead.goods_amt = pr_invoicehead.goods_amt 
	LET pr_credithead.hand_amt = pr_invoicehead.hand_amt 
	LET pr_credithead.hand_tax_code = pr_invoicehead.hand_tax_code 
	LET pr_credithead.hand_tax_amt = pr_invoicehead.hand_tax_amt 
	LET pr_credithead.freight_amt = pr_invoicehead.freight_amt 
	LET pr_credithead.freight_tax_code = pr_invoicehead.freight_tax_code 
	LET pr_credithead.freight_tax_amt = pr_invoicehead.freight_tax_amt 
	LET pr_credithead.tax_amt = pr_invoicehead.tax_amt 
	LET pr_credithead.total_amt = pr_invoicehead.total_amt 
	LET pr_credithead.cost_amt = pr_invoicehead.cost_amt 
	LET pr_credithead.appl_amt = 0 
	LET pr_credithead.disc_amt = pr_invoicehead.disc_amt 
	LET pr_credithead.year_num = pr_invoicehead.year_num 
	LET pr_credithead.period_num = pr_invoicehead.period_num 
	LET pr_credithead.on_state_flag = "N" 
	LET pr_credithead.posted_flag = "N" 
	LET pr_credithead.next_num = 0 
	LET pr_credithead.line_num = pr_invoicehead.line_num 
	LET pr_credithead.printed_num = 1 
	LET pr_credithead.com1_text = pr_invoicehead.com1_text 
	LET pr_credithead.com2_text = pr_invoicehead.com2_text 
	LET pr_credithead.rev_date = NULL 
	LET pr_credithead.rev_num = NULL 
	LET pr_credithead.cost_ind = pr_invoicehead.cost_ind 
	LET pr_credithead.currency_code = pr_invoicehead.currency_code 
	LET pr_credithead.conv_qty = pr_invoicehead.conv_qty 
	LET pr_credithead.cred_ind = pr_invoicehead.inv_ind 
	LET pr_credithead.acct_override_code = pr_invoicehead.acct_override_code 
	LET pr_credithead.price_tax_flag = pr_invoicehead.price_tax_flag 
	LET pr_credithead.bill_issue_ind = pr_invoicehead.bill_issue_ind 
	IF NOT get_jm_info() THEN 
		RETURN 
	END IF 
	LET ps_credithead.* = pr_credithead.* 
	IF cnt > 0 THEN 
		LET t = 1 
		FOR t = t TO cnt 
			INITIALIZE pa_nametext[t].* TO NULL 
		END FOR 
	END IF 
	INITIALIZE pr_creditdetl.* TO NULL 
	FOR i = 1 TO 300 
		INITIALIZE pa_taxamt[i].tax_code TO NULL 
	END FOR 
	OPEN WINDOW wa127 with FORM "A127" -- alch kd-747 
	CALL winDecoration_a("A127") -- alch kd-747 
	WHILE JC1_header() 
		WHILE lineitem(invoice_num) 
			IF summup() THEN 
				CALL write_cred() 
				LET msgresp = kandoomsg("J",1555,pr_credithead.cred_num) 
				CLOSE WINDOW wa127 
				RETURN 
			END IF 
		END WHILE 
	END WHILE 
	CLOSE WINDOW wa127 
END FUNCTION 


##FUNCTION post_err()
##   LET allow_update = FALSE
##   OPEN WINDOW sorry AT 10, 10 with 4 rows, 43 columns
##      attribute (border)
##   DISPLAY "Cannot edit posted invoices - raise credit instead" AT 3, 1
##   DISPLAY "View only allowed FOR this invoice" AT 4, 1
##      attribute (yellow)
##   prompt "Any key TO view - Del TO cancel"
##      FOR CHAR ans
##   IF int_flag
##    OR quit_flag THEN
##      LET int_flag = FALSE
##      LET quit_flag = FALSE
##      CLOSE WINDOW sorry
##      RETURN TRUE
##   ELSE
##      CLOSE WINDOW sorry
##      RETURN FALSE
##   END IF
##END FUNCTION


##FUNCTION paid_err()
##   LET allow_update = FALSE
##   OPEN WINDOW sorry AT 10, 10 with 4 rows, 43 columns
##      attribute (border)
##   DISPLAY "Unapply the invoice before you edit " AT 3, 1
##   DISPLAY "View only allowed FOR this invoice" AT 4, 1
##      attribute (yellow)
##   prompt "Any key TO view - Del TO cancel"
##      FOR CHAR ans
##   IF int_flag
##    OR quit_flag THEN
##     LET int_flag = FALSE
##     LET quit_flag = FALSE
##      CLOSE WINDOW sorry
##      RETURN TRUE
##   ELSE
##      CLOSE WINDOW sorry
##      RETURN FALSE
##   END IF
##END FUNCTION


FUNCTION create_temp1() 
	CREATE temp TABLE tempbill(trans_invoice_flag CHAR(1), 
	trans_date DATE NOT NULL , 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt DECIMAL(16, 2) , 
	trans_qty FLOAT, 
	charge_amt DECIMAL(16, 2), 
	apply_qty FLOAT, 
	apply_amt DECIMAL(16, 2), 
	apply_cos_amt DECIMAL(16, 2), 
	desc_text CHAR (40), 
	prev_apply_qty FLOAT, 
	prev_apply_amt DECIMAL(16, 2), 
	prev_apply_cos_amt DECIMAL(16, 2), 
	arr_line_num SMALLINT, 
	allocation_ind CHAR (1) , 
	goods_rec_num INTEGER, 
	part_code CHAR(25), 
	serial_flag CHAR(1), 
	stored_qty FLOAT 
	) 
	with no LOG 
	CREATE unique INDEX tempbill ON tempbill(var_code, activity_code, seq_num) 
END FUNCTION 
