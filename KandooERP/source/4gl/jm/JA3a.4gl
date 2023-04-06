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

	Source code beautified by beautify.pl on 2020-01-02 19:48:17	$Id: $
}




# Purpose - QBE contract enquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA3_GLOBALS.4gl" 

FUNCTION contractdisp(fv_enq) # true = qbe, false = DISPLAY only 
	DEFINE fv_enq SMALLINT 
	OPEN WINDOW wja00 with FORM "JA00" -- alch kd-747 
	CALL winDecoration_j("JA00") -- alch kd-747 
	IF fv_enq THEN 
		CALL contractqbe() 
	ELSE 
		CALL contractshow() 
	END IF 
	CLOSE WINDOW wja00 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 
END FUNCTION 

FUNCTION select_them() 

	LET msgresp = kandoomsg("A",1001,"") 
	# Enter selection criteria - Esc TO continue

	CONSTRUCT BY NAME where_part ON 
	contract_code, 
	desc_text, 
	cust_code, 
	status_code, 
	user1_text, 
	last_billed_date, 
	bill_type_code, 
	start_date, 
	entry_code, 
	bill_int_ind, 
	end_date, 
	entry_date, 
	sale_code, 
	cons_inv_flag, 
	comm1_text, 
	comm2_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA3a","const-contract_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET query_text = "SELECT * FROM contracthead " , 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" ", 
	" AND ", where_part clipped, 
	" ORDER BY contract_code" 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 

	PREPARE statement_1 FROM query_text 
	DECLARE s_contracthead SCROLL CURSOR FOR statement_1 
	OPEN s_contracthead 

	FETCH s_contracthead INTO pr_contracthead.* 

	IF status != notfound THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 



FUNCTION contractqbe() 
	DEFINE fv_exist SMALLINT 
	CLEAR FORM 
	LET fv_exist = false 
	MENU "Contracts" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA3a","menu-contracts-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Search FOR contracts" 
			LET fv_exist = select_them() 
			IF fv_exist THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("A",3512,"") 
				# No contracts satisfies the selection criteria
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected contract" 
			IF fv_exist THEN 
				FETCH NEXT s_contracthead INTO pr_contracthead.* 
				IF status != notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("A",3514,"") 
					# You have reached the END of the contracts selected
				END IF 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected contract" 
			IF fv_exist THEN 
				FETCH previous s_contracthead INTO pr_contracthead.* 
				IF status != notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("A",3516,"") 
					# You have reached the start of the contracts selected
				END IF 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 

		COMMAND KEY ("F",f18) "First" " DISPLAY first selected contract" 
			IF fv_exist THEN 
				FETCH FIRST s_contracthead INTO pr_contracthead.* 
				IF status != notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("A",3516,"") 
					# You have reached the start of the contracts selected
				END IF 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 

		COMMAND KEY ("L",f22) "Last" " DISPLAY last selected contract" 
			IF fv_exist THEN 
				FETCH LAST s_contracthead INTO pr_contracthead.* 
				IF status != notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("A",3514,"") 
					# You have reached the END of the contracts selected
				END IF 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 

		COMMAND "Invoices" " DISPLAY contract invoice schedule" 
			IF fv_exist THEN 
				CALL contractinvs() 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 

		COMMAND KEY ("D",f20) "Detail" " DISPLAY contract detail lines" 
			IF fv_exist THEN 
				CALL contractlines() 
			ELSE 
				LET msgresp = kandoomsg("A",3515,"") 
				# You have TO make a selection first
			END IF 

		COMMAND "Exit" " Exit FROM this program" 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 

END FUNCTION 



FUNCTION contractshow() 

	SELECT * 
	INTO pr_contracthead.* 
	FROM contracthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND contract_code = pr_contracthead.contract_code 
	AND cust_code = pr_contracthead.cust_code 

	CALL show_it() 

	MENU "Contracts" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA3a","menu-contracts-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Invoice" " DISPLAY contract invoice schedule" 
			CALL contractinvs() 

		COMMAND KEY ("D",f20) "Detail" " DISPLAY contract detail lines" 
			CALL contractlines() 

		COMMAND "Exit" " RETURN TO contract scan SCREEN" 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 

END FUNCTION 



FUNCTION show_it() 

	DEFINE fv_status_text CHAR(40), 
	fv_name_text LIKE customer.name_text 


	SELECT name_text 
	INTO fv_name_text 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_contracthead.cust_code 

	CASE 
		WHEN pr_contracthead.status_code = "A" 
			LET fv_status_text = "Active" 
		WHEN pr_contracthead.status_code = "Q" 
			LET fv_status_text = "Quote" 
		WHEN pr_contracthead.status_code = "H" 
			LET fv_status_text = "Hold (no billing)" 
		WHEN pr_contracthead.status_code = "C" 
			LET fv_status_text = "Complete (no billing)" 
		OTHERWISE 
			LET fv_status_text = "Status Code NOT recognized" 
	END CASE 

	DISPLAY BY NAME pr_contracthead.contract_code, 
	pr_contracthead.desc_text , 
	pr_contracthead.cust_code , 
	pr_contracthead.status_code , 
	pr_contracthead.user1_text , 
	pr_contracthead.last_billed_date , 
	pr_contracthead.bill_type_code , 
	pr_contracthead.start_date , 
	pr_contracthead.entry_code , 
	pr_contracthead.bill_int_ind , 
	pr_contracthead.end_date , 
	pr_contracthead.entry_date , 
	pr_contracthead.contract_value_amt , 
	pr_contracthead.sale_code , 
	pr_contracthead.cons_inv_flag, 
	pr_contracthead.comm1_text , 
	pr_contracthead.comm2_text 

	DISPLAY fv_status_text TO status_text 
	DISPLAY fv_name_text TO name_text 

END FUNCTION 



FUNCTION contractinvs() 

	DEFINE fa_contractdate array[600] OF RECORD 
		invoice_date LIKE contractdate.invoice_date, 
		inv_num LIKE contractdate.inv_num, 
		invoice_total_amt LIKE contractdate.invoice_total_amt, 
		inv_type CHAR(7) 
	END RECORD, 
	fr_contractdate RECORD LIKE contractdate.*, 
	fv_inv_num LIKE contractdate.inv_num, 
	fv_org_name_text LIKE customer.name_text, 
	fv_sp_name_text LIKE salesperson.name_text, 
	fv_idx INTEGER 

	OPEN WINDOW wja01 with FORM "JA01" -- alch kd-747 
	CALL winDecoration_j("JA01") -- alch kd-747 
	LET msgresp = kandoomsg("A",1550,"") 
	# MESSAGE "CTRL-V TO view Invoice - DEL TO EXIT"
	LET fv_idx = 0 

	DECLARE c_contractdate CURSOR FOR 
	SELECT * 
	FROM contractdate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND contract_code = pr_contracthead.contract_code 
	ORDER BY invoice_date 

	FOREACH c_contractdate INTO fr_contractdate.* 
		LET fv_idx = fv_idx + 1 

		LET fa_contractdate[fv_idx].invoice_date = fr_contractdate.invoice_date 
		LET fa_contractdate[fv_idx].inv_num = fr_contractdate.inv_num 
		LET fa_contractdate[fv_idx].invoice_total_amt = 
		fr_contractdate.invoice_total_amt 

		SELECT inv_ind 
		INTO fa_contractdate[fv_idx].inv_type 
		FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = fr_contractdate.inv_num 

		CASE fa_contractdate[fv_idx].inv_type 
			WHEN "5" 
				LET fa_contractdate[fv_idx].inv_type = "Contrac" 
			WHEN "3" 
				LET fa_contractdate[fv_idx].inv_type = TRAN_TYPE_JOB_JOB 
			WHEN "1" 
				LET fa_contractdate[fv_idx].inv_type = "Gen/Inv" 
		END CASE 

		IF fv_idx = 600 THEN 
			LET msgresp = kandoomsg("A",3517,"600") 
			# First 600 invoices selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(fv_idx) 

	IF fv_idx = 0 THEN 
		LET msgresp = kandoomsg("A",3518,"") 
		# No invoices were found FOR this contract
	END IF 

	DISPLAY ARRAY fa_contractdate TO sr_cont_dates.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","JA3a","display-arr-contractdate") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (control-v) 
			LET fv_idx = arr_curr() 

			IF fa_contractdate[fv_idx].inv_num IS NULL THEN 
			ELSE 
				OPEN WINDOW wa192 with FORM "A192" -- alch kd-747 
				CALL winDecoration_a("A192") -- alch kd-747 
				SELECT * 
				INTO pr_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = fa_contractdate[fv_idx].inv_num 

				DISPLAY BY NAME pr_invoicehead.cust_code, 
				pr_invoicehead.name_text, 
				pr_invoicehead.org_cust_code, 
				pr_invoicehead.inv_num, 
				pr_invoicehead.ord_num, 
				pr_invoicehead.job_code, 
				pr_invoicehead.currency_code, 
				pr_invoicehead.goods_amt, 
				pr_invoicehead.tax_amt, 
				pr_invoicehead.hand_amt, 
				pr_invoicehead.freight_amt, 
				pr_invoicehead.total_amt, 
				pr_invoicehead.paid_amt, 
				pr_invoicehead.inv_date, 
				pr_invoicehead.due_date, 
				pr_invoicehead.disc_date, 
				pr_invoicehead.paid_date, 
				pr_invoicehead.disc_amt, 
				pr_invoicehead.disc_taken_amt, 
				pr_invoicehead.year_num, 
				pr_invoicehead.period_num, 
				pr_invoicehead.posted_flag, 
				pr_invoicehead.entry_code, 
				pr_invoicehead.entry_date, 
				pr_invoicehead.sale_code, 
				pr_invoicehead.inv_ind, 
				pr_invoicehead.purchase_code, 
				pr_invoicehead.com1_text, 
				pr_invoicehead.com2_text, 
				pr_invoicehead.on_state_flag, 
				pr_invoicehead.rev_date, 
				pr_invoicehead.rev_num 


				IF pr_invoicehead.org_cust_code IS NOT NULL THEN 
					SELECT name_text 
					INTO fv_org_name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_invoicehead.org_cust_code 

					DISPLAY fv_org_name_text TO org_name_text 

				END IF 

				IF pr_invoicehead.paid_date != "31/12/1899" THEN 
					DISPLAY BY NAME pr_invoicehead.paid_date 

				END IF 

				SELECT name_text 
				INTO fv_sp_name_text 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = pr_invoicehead.sale_code 

				DISPLAY fv_sp_name_text TO salesperson.name_text 


				LET func_type = "View Invoice" 

				MENU "Invoice" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","JA3a","menu-invoice-1") -- alch kd-506 
					ON ACTION "WEB-HELP" -- albo kd-373 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND KEY ("D",f20) "Detail" " View invoice details" 
						IF fa_contractdate[fv_idx].inv_type = TRAN_TYPE_JOB_JOB THEN 
							CALL lineshow(glob_rec_kandoouser.cmpy_code, pr_invoicehead.cust_code, 
							pr_invoicehead.inv_num, func_type) 
							NEXT option "Exit" 
						ELSE 
							CALL ar_detail_menu() 
							NEXT option "Exit" 
						END IF 

					COMMAND "Exit" " Exit FROM this program" 
						EXIT MENU 

					COMMAND KEY (interrupt) 
						LET int_flag = false 
						LET quit_flag = false 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 

				CLOSE WINDOW wa192 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 

	CLOSE WINDOW wja01 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION 



FUNCTION ar_detail_menu() 

	DEFINE ref_text LIKE arparms.inv_ref1_text, 
	temp_text CHAR(32), 
	pr_option CHAR(1), 
	fv_inv_num LIKE invoicehead.inv_num, 
	fv_cust_code LIKE invoicehead.cust_code, 
	fv_name_text LIKE invoicehead.name_text 

	SELECT inv_ref1_text 
	INTO ref_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	LET temp_text = ref_text clipped, "................" 
	LET ref_text = temp_text 
	LET fv_inv_num = pr_invoicehead.inv_num 
	LET fv_cust_code = pr_invoicehead.cust_code 
	LET fv_name_text = pr_invoicehead.name_text 
	OPEN WINDOW ja15 with FORM "JA15" -- alch kd-747 
	CALL winDecoration_j("JA15") -- alch kd-747 
	DISPLAY BY NAME pr_invoicehead.inv_num, 
	pr_invoicehead.name_text 
	INPUT BY NAME pr_option WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA3a","input-pr_option-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 
			CASE pr_option 
				WHEN "1" 
					CALL lineshow(glob_rec_kandoouser.cmpy_code, pr_invoicehead.cust_code, 
					pr_invoicehead.inv_num, func_type) 
					NEXT FIELD pr_option 
				WHEN "2" 
					CALL show_inv_entry(glob_rec_kandoouser.cmpy_code, pr_invoicehead.inv_num) 
					NEXT FIELD pr_option 
				WHEN "3" 
					CALL show_inv_ship(glob_rec_kandoouser.cmpy_code, pr_invoicehead.inv_num) 
					NEXT FIELD pr_option 
				WHEN "C" 
					IF change_invoice() THEN 
						DISPLAY BY NAME pr_invoicehead.inv_num, 
						pr_invoicehead.name_text 
					END IF 
					NEXT FIELD pr_option 
				WHEN "E" 
					EXIT CASE 
				OTHERWISE 
					NEXT FIELD pr_option 
			END CASE 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	LET pr_invoicehead.inv_num = fv_inv_num 
	LET pr_invoicehead.cust_code = fv_cust_code 
	LET pr_invoicehead.name_text = fv_name_text 

	CLOSE WINDOW ja15 

END FUNCTION 



FUNCTION contractlines() 

	DEFINE fa_line_num array[500] OF SMALLINT, 
	fa_contractdetl array[500] OF RECORD 
		type_code LIKE contractdetl.type_code, 
		desc_text LIKE contractdetl.desc_text 
	END RECORD, 
	fr_contractdetl RECORD LIKE contractdetl.*, 
	fv_idx INTEGER 
	OPEN WINDOW wja07 with FORM "JA07" -- alch kd-747 
	CALL winDecoration_j("JA07") -- alch kd-747 
	LET msgresp = kandoomsg("A",1550,"") 
	# MESSAGE "RETURN TO view - DEL TO EXIT"

	LET fv_idx = 0 
	LET pr_contractdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_contractdetl.contract_code = pr_contracthead.contract_code 
	LET pr_contractdetl.cust_code = pr_contracthead.cust_code 

	DECLARE c_contractdetl CURSOR FOR 

	SELECT * 
	FROM contractdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND contract_code = pr_contracthead.contract_code 
	ORDER BY line_num 

	FOREACH c_contractdetl INTO fr_contractdetl.* 
		LET fv_idx = fv_idx + 1 

		LET fa_line_num[fv_idx] = fr_contractdetl.line_num 
		LET fa_contractdetl[fv_idx].type_code = fr_contractdetl.type_code 
		LET fa_contractdetl[fv_idx].desc_text = fr_contractdetl.desc_text 

		IF fv_idx = 500 THEN 
			LET msgresp = kandoomsg("A",3519,"500") 
			# First 500 detail lines selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(fv_idx) 

	IF fv_idx = 0 THEN 
		LET msgresp = kandoomsg("A",3520,"") 
		# No detail lines were found FOR this contract
	END IF 

	INPUT ARRAY fa_contractdetl WITHOUT DEFAULTS FROM sr_cont_dtls.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA3a","input_arr-fa_contractdetl-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 

		BEFORE FIELD desc_text 
			LET pr_contractdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_contractdetl.line_num = fa_line_num[fv_idx] 

			CALL condetldisp() 
			NEXT FIELD type_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wja07 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION 



FUNCTION change_invoice() 

	LET msgresp = kandoomsg("A",1524,"") 
	# MESSAGE " Enter New Invoice Number"

	INPUT BY NAME pr_invoicehead.inv_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA3a","input-pr_invoicehead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			SELECT cust_code, name_text 
			INTO pr_invoicehead.cust_code, pr_invoicehead.name_text 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = pr_invoicehead.inv_num 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9551,"") 
				# " Invoice number invalid"
				NEXT FIELD inv_num 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	MESSAGE "" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
