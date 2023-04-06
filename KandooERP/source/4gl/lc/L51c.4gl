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

	Source code beautified by beautify.pl on 2020-01-02 18:38:31	$Id: $
}




# This module accepts the shipment line details

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L51_GLOBALS.4gl" 


DEFINE 
which CHAR(3), 
go_on CHAR(1), 
unit_tax money(16,4), 
#computed_duty, duty_ext_ent_amt LIKE shipdetl.duty_ext_ent_amt,
pr_price, base_fob_cost_amt money(10,2), 
save_tariff_code LIKE product.tariff_code, 
save_duty_rate LIKE shipdetl.duty_rate_per 

FUNCTION ship_window() 
	DEFINE 
	no_specialprice SMALLINT, 
	runner CHAR(100), 
	fob_okay CHAR(1), 
	st_code SMALLINT, 
	pr_save_doc_num LIKE shipdetl.source_doc_num, 
	pr_save_line_num LIKE shipdetl.doc_line_num 

	OPEN WINDOW wl103 with FORM "L148" 
	CALL windecoration_l("L148") -- albo kd-761 

	#IF pr_shipdetl.part_code IS NULL THEN
	#ERROR "Product Id must NOT be NULL"
	#sleep 3
	#LET nxtfld = 1
	#CLOSE WINDOW wL103
	#RETURN
	#END IF

	DISPLAY BY NAME pr_shipdetl.part_code, 
	pr_shipdetl.desc_text, 
	pr_shipdetl.source_doc_num, 
	pr_shipdetl.doc_line_num, 
	pr_shipdetl.ship_inv_qty, 
	pr_shipdetl.ship_rec_qty, 
	pr_shipdetl.fob_unit_ent_amt, 
	pr_shipdetl.fob_ext_ent_amt, 
	pr_shiphead.curr_code 
	attribute(yellow) 

	MESSAGE "CTRL P TO view product details" attribute(yellow) 

	INPUT BY NAME pr_shipdetl.part_code, 
	pr_shipdetl.source_doc_num, 
	pr_shipdetl.doc_line_num, 
	pr_shipdetl.desc_text, 
	pr_shipdetl.ship_inv_qty, 
	pr_shipdetl.fob_unit_ent_amt, 
	go_on WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L51c","input-part_code-1") -- albo 
			LET pr_save_doc_num = pr_shipdetl.source_doc_num 
			LET pr_save_line_num = pr_shipdetl.doc_line_num 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 

				WHEN infield (source_doc_num) 
					LET pr_shipdetl.source_doc_num = find_po(glob_rec_kandoouser.cmpy_code,pr_shiphead.vend_code) 
					DISPLAY BY NAME pr_shipdetl.source_doc_num 
					NEXT FIELD source_doc_num 

				WHEN infield (doc_line_num) 
					IF pr_shipdetl.source_doc_num IS NOT NULL 
					AND pr_shipdetl.source_doc_num != 0 THEN 
						LET pr_shipdetl.doc_line_num = select_singlepo_lines(glob_rec_kandoouser.cmpy_code, 
						pr_shipdetl.source_doc_num,pr_shiphead.vend_code) 
						DISPLAY BY NAME pr_shipdetl.doc_line_num 
					END IF 

			END CASE 

		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
 
					LET pr_shipdetl.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,pr_shipdetl.desc_text) 
					DISPLAY BY NAME pr_shipdetl.desc_text 
					NEXT FIELD desc_text 

		ON KEY (control-p) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code, pr_shipdetl.part_code) 
			# product id has already been entered so carry on.....

		AFTER FIELD source_doc_num 
			IF fgl_lastkey() != fgl_keyval("delete") THEN 
				IF pr_save_doc_num IS NOT NULL 
				AND pr_shipdetl.source_doc_num != pr_save_doc_num THEN 
					LET pr_shipdetl.source_doc_num = 
					pr_save_doc_num 
					DISPLAY BY NAME pr_shipdetl.source_doc_num 
					NEXT FIELD source_doc_num 
				END IF 
				IF pr_shipdetl.source_doc_num IS NULL 
				OR pr_shipdetl.source_doc_num = 0 THEN 
					ERROR "Source document number required. Try window" 
					NEXT FIELD source_doc_num 
				END IF 
			END IF 

		AFTER FIELD doc_line_num 
			IF fgl_lastkey() != fgl_keyval("delete") 
			AND fgl_lastkey() != fgl_keyval("up") THEN 
				IF pr_save_line_num IS NOT NULL 
				AND pr_shipdetl.doc_line_num != pr_save_line_num THEN 
					LET pr_shipdetl.doc_line_num = 
					pr_save_line_num 
					DISPLAY BY NAME pr_shipdetl.doc_line_num 
					NEXT FIELD doc_line_num 
				END IF 
				IF pr_shipdetl.doc_line_num IS NULL 
				OR pr_shipdetl.doc_line_num = 0 THEN 
					ERROR "Source line number IS required" 
					NEXT FIELD doc_line_num 
				END IF 
			END IF 
			IF pr_save_line_num IS NULL 
			AND pr_shipdetl.doc_line_num > 0 THEN 
				CALL setup_po_line(pr_shipdetl.source_doc_num, pr_shipdetl.doc_line_num) 
				RETURNING st_code 
				IF st_code < 0 THEN 
					NEXT FIELD doc_line_num 
				END IF 
			END IF 

		AFTER FIELD ship_inv_qty 
			IF pr_shipdetl.ship_inv_qty IS NULL THEN 
				LET pr_shipdetl.ship_inv_qty = 0 
			END IF 
			IF pr_shipdetl.ship_inv_qty < pr_shipdetl.ship_rec_qty THEN 
				ERROR "Quantity shipped must be > quantity received" 
				SLEEP 3 
				NEXT FIELD ship_inv_qty 
			END IF 
			LET pr_shipdetl.fob_ext_ent_amt = pr_shipdetl.fob_unit_ent_amt * 
			pr_shipdetl.ship_inv_qty 
			LET pr_shipdetl.duty_ext_ent_amt = pr_shipdetl.duty_unit_ent_amt 
			* pr_shipdetl.ship_inv_qty 
			DISPLAY BY NAME pr_shipdetl.fob_ext_ent_amt 



		BEFORE FIELD fob_unit_ent_amt 
			LET fob_okay = "N" 

		AFTER FIELD fob_unit_ent_amt 
			IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN 
				ERROR "Net (FOB) Cost must NOT be NULL" 
				NEXT FIELD fob_unit_ent_amt 
			END IF 
			IF pr_shipdetl.fob_unit_ent_amt < 0 THEN 
				ERROR "Net (FOB) Cost must NOT be < 0" 
				NEXT FIELD fob_unit_ent_amt 
			END IF 
			IF pr_shipdetl.fob_unit_ent_amt = 0 THEN 
				CALL confirm_zero_fob() RETURNING fob_okay 
				IF fob_okay != "Y" THEN 
					NEXT FIELD fob_unit_ent_amt 
				END IF 
			END IF 

			LET base_fob_cost_amt = conv_shipcurr( 
			pr_shipdetl.fob_unit_ent_amt, 
			pr_shiphead.curr_code, "F", 
			pr_shiphead.conversion_qty) 
			LET pr_shipdetl.duty_unit_ent_amt = 0 
			LET pr_shipdetl.fob_ext_ent_amt = pr_shipdetl.fob_unit_ent_amt * 
			pr_shipdetl.ship_inv_qty 
			LET pr_shipdetl.duty_ext_ent_amt =pr_shipdetl.duty_unit_ent_amt 
			* pr_shipdetl.ship_inv_qty 
			DISPLAY BY NAME pr_shipdetl.fob_ext_ent_amt 


		BEFORE FIELD go_on 
			LET go_on = "Y" 
			DISPLAY go_on TO go_on 

		AFTER FIELD go_on 
			IF go_on != "Y" THEN 
				NEXT FIELD ship_inv_qty 
			END IF 

		AFTER INPUT 

			IF int_flag != 0 
			OR quit_flag != 0 THEN 
			ELSE 
				IF pr_shipdetl.source_doc_num IS NULL 
				OR pr_shipdetl.source_doc_num = 0 THEN 
					ERROR "Source document number required. Try window" 
					NEXT FIELD source_doc_num 
				END IF 
				IF pr_shipdetl.doc_line_num IS NULL 
				OR pr_shipdetl.doc_line_num = 0 THEN 
					ERROR "Source line number IS required" 
					NEXT FIELD doc_line_num 
				END IF 
				IF pr_shipdetl.ship_inv_qty IS NULL THEN 
					LET pr_shipdetl.ship_inv_qty = 0 
				END IF 
				IF pr_shipdetl.ship_inv_qty < pr_shipdetl.ship_rec_qty THEN 
					ERROR "Quantity shipped must be > quantity received" 
					SLEEP 3 
					NEXT FIELD ship_inv_qty 
				END IF 
				IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN 
					ERROR "Net (FOB) Cost must NOT be NULL" 
					SLEEP 3 
					NEXT FIELD fob_unit_ent_amt 
				END IF 
				IF pr_shipdetl.fob_unit_ent_amt = 0 
				AND fob_okay != "Y" THEN 
					CALL confirm_zero_fob() RETURNING fob_okay 
					IF fob_okay != "Y" THEN 
						NEXT FIELD fob_unit_ent_amt 
					END IF 
				END IF 
				IF pr_shipdetl.fob_unit_ent_amt < 0 THEN 
					ERROR "Net (FOB) Cost must NOT be < 0" 
					SLEEP 3 
					NEXT FIELD fob_unit_ent_amt 
				END IF 
				LET base_fob_cost_amt = conv_shipcurr( 
				pr_shipdetl.fob_unit_ent_amt, 
				pr_shiphead.curr_code, "F", 
				pr_shiphead.conversion_qty) 
				LET pr_shipdetl.fob_ext_ent_amt = pr_shipdetl.fob_unit_ent_amt 
				* pr_shipdetl.ship_inv_qty 
				IF pr_shipdetl.duty_unit_ent_amt IS NULL THEN 
					LET pr_shipdetl.duty_unit_ent_amt = 0 
				END IF 
				LET pr_shipdetl.duty_ext_ent_amt = pr_shipdetl.duty_unit_ent_amt 
				* pr_shipdetl.ship_inv_qty 
			END IF 
			IF pr_shipdetl.part_code IS NULL 
			AND (pr_shipdetl.source_doc_num IS NULL 
			OR pr_shipdetl.source_doc_num = 0) 
			AND pr_shipdetl.job_code IS NULL 
			AND pr_shipdetl.var_code IS NULL 
			AND pr_shipdetl.activity_code IS NULL 
			AND (pr_shipdetl.fob_ext_ent_amt <> 0 
			OR pr_shipdetl.duty_ext_ent_amt <> 0) THEN 
				CALL get_acct() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					NEXT FIELD fob_unit_ent_amt 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wl103 

	# has interrupt OR quit been hit

	#IF int_flag != 0
	#OR quit_flag != 0 THEN
	#LET int_flag = 0
	#LET quit_flag = 0
	#END IF
	RETURN 
END FUNCTION 


FUNCTION set_shipdetl() 
	# SET up the ORDER line

	LET pr_shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN 
		LET pr_shipdetl.fob_unit_ent_amt = 0 
	END IF 
	IF f_type = "O" THEN 
		LET pr_shipdetl.ship_rec_qty = 0 
	END IF 
	LET st_shipdetl[idx].* = pr_shipdetl.* 
	RETURN 
END FUNCTION 


FUNCTION conv_shipcurr(source_amt, curr, to_from, conversion_qty) 
	DEFINE 
	source_amt, conv_amt LIKE batchhead.debit_amt, 
	curr LIKE currency.currency_code, 
	to_from CHAR(1), 
	conversion_qty LIKE rate_exchange.conv_buy_qty, 
	ans CHAR(1) 


	IF to_from = "T" THEN 
		LET conv_amt = (source_amt * conversion_qty) 
	ELSE 
		LET conv_amt = (source_amt / conversion_qty) 
	END IF 

	RETURN conv_amt 
END FUNCTION 


FUNCTION confirm_zero_fob() 

	DEFINE answer CHAR(1) 
	{  -- albo
	      OPEN WINDOW w1 AT 10,15 with 1 rows, 48 columns ATTRIBUTE(white, border)
	      prompt "Free of charge item - OK TO continue (y/n)? " FOR CHAR answer
	}
	LET answer = promptYN("","Free of charge item - OK TO continue (y/n)? ","Y") -- albo 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET answer = "N" 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 
	LET answer = upshift(answer) 
	--      CLOSE WINDOW w1
	RETURN answer 
END FUNCTION 


FUNCTION get_acct() 
	DEFINE 
	pr_coa RECORD LIKE coa.*, 
	save_acct_code LIKE coa.acct_code 

	LET save_acct_code = pr_shipdetl.acct_code 
	OPEN WINDOW wl142 with FORM "L142" 
	CALL windecoration_l("L142") -- albo kd-761 
	DISPLAY BY NAME pr_shipdetl.acct_code 
	INPUT BY NAME pr_shipdetl.acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","L51c","input-acct_code-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (acct_code) 
					LET pr_shipdetl.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shipdetl.acct_code 
					NEXT FIELD acct_code 
			END CASE 
		AFTER FIELD acct_code 
			IF pr_shipdetl.acct_code IS NULL THEN 
				ERROR " Account Number IS required" 
				NEXT FIELD acct_code 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
			ELSE 
				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_shipdetl.acct_code 
				IF status = notfound THEN 
					ERROR " Account NOT found" 
					NEXT FIELD acct_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wl142 
	IF int_flag OR quit_flag THEN 
		LET pr_shipdetl.acct_code = save_acct_code 
	END IF 
END FUNCTION 


FUNCTION setup_po_line(source_doc_num, doc_line_num) 
	DEFINE 
	source_doc_num LIKE shipdetl.source_doc_num, 
	doc_line_num LIKE shipdetl.doc_line_num, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.* 

	SELECT * 
	INTO pr_purchdetl.* 
	FROM purchdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = source_doc_num 
	AND line_num = doc_line_num 
	IF status = notfound THEN 
		ERROR " PO Line missing " 
		RETURN -1 
	END IF 
	CALL po_line_info (glob_rec_kandoouser.cmpy_code, pr_purchdetl.order_num,pr_purchdetl.line_num) 
	RETURNING 
	pr_poaudit.order_qty, 
	pr_poaudit.received_qty, 
	pr_poaudit.voucher_qty, 
	pr_poaudit.unit_cost_amt, 
	pr_poaudit.ext_cost_amt, 
	pr_poaudit.unit_tax_amt, 
	pr_poaudit.ext_tax_amt, 
	pr_poaudit.line_total_amt 
	LET pr_shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_shipdetl.ship_inv_qty = pr_poaudit.order_qty - 
	pr_poaudit.received_qty 
	IF pr_shipdetl.ship_inv_qty < 0 THEN 
		LET pr_shipdetl.ship_inv_qty = 0 
	END IF 
	LET pr_shipdetl.fob_unit_ent_amt = pr_poaudit.unit_cost_amt 
	LET pr_shipdetl.fob_ext_ent_amt = pr_shipdetl.ship_inv_qty 
	* pr_shipdetl.fob_unit_ent_amt 
	CASE 
		WHEN pr_purchdetl.type_ind = "I" {inventory} 
			LET pr_shipdetl.part_code = pr_purchdetl.ref_text 
			LET pr_shipdetl.desc_text = pr_purchdetl.desc_text 
			LET pr_shipdetl.job_code = NULL 
			LET pr_shipdetl.var_code = NULL 
			LET pr_shipdetl.activity_code = NULL 
			LET pr_shipdetl.acct_code = pr_purchdetl.acct_code 
			LET pr_shipdetl.duty_rate_per = 0 
			LET pr_shipdetl.duty_unit_ent_amt = 0 
			LET pr_shipdetl.tariff_code = NULL 
			LET pr_shipdetl.duty_ext_ent_amt = 
			pr_poaudit.unit_tax_amt * 
			pr_shipdetl.ship_inv_qty 
		WHEN pr_purchdetl.type_ind = "G" {general} 
			LET pr_shipdetl.part_code = NULL 
			LET pr_shipdetl.desc_text = pr_purchdetl.desc_text 
			LET pr_shipdetl.job_code = NULL 
			LET pr_shipdetl.var_code = NULL 
			LET pr_shipdetl.activity_code = NULL 
			LET pr_shipdetl.acct_code = pr_purchdetl.acct_code 
			LET pr_shipdetl.duty_rate_per = 0 
			LET pr_shipdetl.tariff_code = NULL 
			LET pr_shipdetl.duty_unit_ent_amt = 0 
			LET pr_shipdetl.duty_ext_ent_amt = pr_poaudit.unit_tax_amt * 
			pr_shipdetl.ship_inv_qty 
		WHEN pr_purchdetl.type_ind = "J" {job management} 
			LET pr_shipdetl.part_code = NULL 
			LET pr_shipdetl.desc_text = pr_purchdetl.desc_text 
			LET pr_shipdetl.job_code = pr_purchdetl.job_code 
			LET pr_shipdetl.var_code = pr_purchdetl.var_num 
			LET pr_shipdetl.activity_code = pr_purchdetl.activity_code 
			LET pr_shipdetl.acct_code = pr_purchdetl.acct_code 
			LET pr_shipdetl.duty_rate_per = 0 
			LET pr_shipdetl.tariff_code = NULL 
			LET pr_shipdetl.duty_unit_ent_amt = 0 
			LET pr_shipdetl.duty_ext_ent_amt = 
			pr_poaudit.unit_tax_amt * 
			pr_shipdetl.ship_inv_qty 
	END CASE 
	DISPLAY BY NAME pr_shipdetl.part_code, 
	pr_shipdetl.desc_text, 
	pr_shipdetl.source_doc_num, 
	pr_shipdetl.doc_line_num, 
	pr_shipdetl.ship_inv_qty, 
	pr_shipdetl.ship_rec_qty, 
	pr_shipdetl.fob_unit_ent_amt, 
	pr_shipdetl.fob_ext_ent_amt, 
	pr_shiphead.curr_code 
	attribute(yellow) 
	RETURN 0 
END FUNCTION 

