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

	Source code beautified by beautify.pl on 2020-01-02 18:38:32	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L61  allows the user TO enter Accounts Receivable Credits
#      as shipments

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 


FUNCTION L61_header() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_glparms RECORD LIKE glparms.*, 
	mask_code LIKE account.acct_code, 
	save_conv LIKE shiphead.conversion_qty, 
	temp_text CHAR(32), 
	ref_text LIKE arparms.credit_ref1_text, 
	pr_structure RECORD LIKE structure.*, 
	enter_seg CHAR(1), 
	i, j, x SMALLINT, 
	acct_override_code LIKE account.acct_code, 
	conv_flag, failed_it SMALLINT 

	LET conv_flag = false 
	IF first_time = 1 THEN 
		IF f_type = "C" THEN 
			LET conv_flag = true 
		END IF 
		LET first_time = 0 
		LET ins_line = 0 
		LET edit_line = 1 
	ELSE 
		GOTO second_window 
	END IF 
	SELECT * 
	INTO pr_smparms.* 
	FROM smparms WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		ERROR "SM Parameters NOT found" 
		SLEEP 4 
		EXIT program 
	END IF 
	# INITIALIZE variables IF new invoice

	IF f_type = "C" THEN 
		INITIALIZE pr_customer.* TO NULL 
		INITIALIZE pr_corp_cust.* TO NULL 
		LET pr_shiphead.entry_date = today 
		LET pr_shiphead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_shiphead.ship_type_ind = "3" 
		LET pr_shiphead.finalised_flag = "N" 

		OPEN WINDOW wl153 with FORM "L153" 
		CALL windecoration_l("L153") -- albo kd-763 
		LABEL first_window: 

		INPUT BY NAME pr_customer.cust_code 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F5) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
				NEXT FIELD cust_code 

			ON KEY (control-b) infield (cust_code) 
				LET pr_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_customer.cust_code 
				NEXT FIELD cust_code 

			BEFORE FIELD cust_code 
				IF display_ship_code = "Y" THEN 
					MESSAGE "Sucessful addition of shipment number ", temp_ship_code 
					attribute(yellow) 
					LET display_ship_code = "N" 
				ELSE 
					MESSAGE "F5 FOR customer query" attribute(yellow) 
				END IF 

			AFTER FIELD cust_code 
				MESSAGE " " 
				SELECT * INTO pr_customer.* FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_customer.cust_code 
				IF (status = notfound) THEN 
					ERROR "Customer NOT found, try again" 
					NEXT FIELD cust_code 
				END IF 
				#IF pr_customer.corp_cust_code IS NOT NULL THEN
				#LET pv_corp_cust = TRUE
				#SELECT * INTO pr_corp_cust.* FROM customer
				#WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#AND cust_code = pr_customer.corp_cust_code
				#IF (STATUS = NOTFOUND) THEN
				#ERROR "Corporate customer NOT found, setup using A15"
				#NEXT FIELD cust_code
				#
				#END IF
				#IF pr_customer.currency_code != pr_corp_cust.currency_code THEN
				#ERROR "Corporate AND Originating customer's currencies differ"
				#NEXT FIELD cust_code
				#END IF
				#ELSE
				LET pv_corp_cust = false 
				#END IF

				CALL display_customer() 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF goon = "N" THEN 
			CLOSE WINDOW wl153 
			RETURN 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			LET ans = "N" 
			CLOSE WINDOW wl153 
			RETURN 
		END IF 
		# just DISPLAY IF edit
	ELSE 
		OPEN WINDOW wl153 with FORM "L153" 
		CALL windecoration_l("L153") -- albo kd-763 

		CALL display_customer() 
	END IF 
	LET pr_shiphead.curr_code = pr_customer.currency_code 
	DISPLAY BY NAME pr_customer.currency_code attribute(green) 

	#IF pv_corp_cust THEN
	#    LET pr_shiphead.vend_code = pr_customer.corp_cust_code
	#    #LET pr_shiphead.org_cust_code = pr_customer.cust_code
	#    LET pr_shiphead.currency_code = pr_corp_cust.currency_code
	#ELSE
	LET pr_shiphead.vend_code = pr_customer.cust_code 
	#    LET pr_shiphead.org_cust_code = NULL
	LET pr_shiphead.curr_code = pr_customer.currency_code 
	#END IF

	SELECT * 
	INTO pr_arparms.* 
	FROM arparms WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		ERROR "AR Parameters NOT found" 
		SLEEP 4 
		EXIT program 
	END IF 
	LET temp_text = pr_arparms.credit_ref1_text clipped, "................" 
	LET ref_text = temp_text 

	IF f_type = "C" THEN 
		LET pr_shiphead.eta_init_date = today 
		LET pr_shiphead.eta_curr_date = today 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_shiphead.eta_init_date) 
		RETURNING pr_shiphead.year_num, pr_shiphead.period_num 
		
		CALL get_conv_rate(
		glob_rec_kandoouser.cmpy_code, 
		pr_shiphead.curr_code, 
		pr_shiphead.eta_curr_date, 
		CASH_EXCHANGE_SELL) 
		RETURNING pr_shiphead.conversion_qty 
	END IF 

	OPEN WINDOW wl154 with FORM "L154" 
	CALL windecoration_l("L154") -- albo kd-763 
	DISPLAY ref_text 
	TO credit_ref1_text 

	LABEL second_window: 
	IF f_type = "C" THEN 
		LET pr_shiphead.sale_code = pr_customer.sale_code 
		SELECT * 
		INTO pr_tax.* 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = pr_customer.tax_code 
		LET pr_shiphead.tax_code = pr_customer.tax_code 
		LET pr_warehouse.ware_code = save_ware 
	ELSE 
		LET pr_customer.cred_bal_amt = pr_customer.cred_bal_amt + 
		pr_shiphead.total_amt 

		#   IF NOT pv_corp_cust THEN
		#       LET sav_corp_code = pr_shiphead.cust_code
		#       IF sav_cust_code IS NOT NULL THEN
		#           LET pr_shiphead.cust_code = sav_cust_code
		#       END IF
		#   END IF

	END IF 

	SELECT * 
	INTO pr_salesperson.* 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = pr_shiphead.sale_code 
	INITIALIZE pr_tax.* TO NULL 
	SELECT * 
	INTO pr_tax.* 
	FROM tax 
	WHERE tax.tax_code = pr_shiphead.tax_code 
	AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT * 
	INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	ware_code = pr_shiphead.ware_code 

	LET save_conv = pr_shiphead.conversion_qty 
	LET pr_shiphead.ware_code = pr_warehouse.ware_code 

	SELECT * 
	INTO pr_shipstatus.* 
	FROM shipstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_status_code = pr_shiphead.ship_status_code 

	SELECT * 
	INTO pr_shiptype.* 
	FROM shiptype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_type_code = pr_shiphead.ship_type_code 

	DISPLAY pr_shiphead.ware_code, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.entry_code, 
	pr_shiphead.year_num, 
	pr_shiphead.period_num, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.curr_code, 
	pr_shiphead.ship_via_text, 
	pr_shiphead.sale_code, 
	pr_salesperson.name_text, 
	pr_shiphead.tax_code, 
	pr_tax.desc_text, 
	pr_shiphead.ship_status_code, 
	pr_shipstatus.desc_text, 
	pr_shiphead.ship_type_code, 
	pr_shiptype.desc_text 
	TO shiphead.ware_code, 
	shiphead.eta_curr_date, 
	shiphead.entry_code, 
	shiphead.year_num, 
	shiphead.period_num, 
	shiphead.conversion_qty, 
	shiphead.curr_code, 
	shiphead.ship_via_text, 
	shiphead.sale_code, 
	salesperson.name_text, 
	shiphead.tax_code, 
	tax.desc_text, 
	shiphead.ship_status_code, 
	shipstatus.desc_text, 
	shiphead.ship_type_code, 
	shiptype.desc_text 


	INPUT BY NAME pr_shiphead.ware_code, 
	pr_shiphead.ship_via_text, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.year_num, 
	pr_shiphead.period_num, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.sale_code, 
	pr_shiphead.tax_code, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.ship_type_code 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 

				WHEN infield (ware_code) 
					LET pr_shiphead.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.ware_code 

					NEXT FIELD ware_code 

				WHEN infield (sale_code) 
					LET pr_shiphead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.sale_code 

					NEXT FIELD sale_code 

				WHEN infield (tax_code) 
					LET pr_shiphead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.tax_code 

					NEXT FIELD tax_code 

				WHEN infield (ship_type_code) 
					LET pr_shiphead.ship_type_code = show_type(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.ship_type_code 

					NEXT FIELD ship_type_code 

				WHEN infield (ship_status_code) 
					LET pr_shiphead.ship_status_code = show_shipst(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_shiphead.ship_status_code 

					NEXT FIELD ship_status_code 

			END CASE 

		ON KEY (control-c) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
			NEXT FIELD ware_code 

		BEFORE FIELD ware_code 
			LET save_ware = pr_shiphead.ware_code 
		AFTER FIELD ware_code 
			# Edit
			IF f_type != "C" AND 
			save_ware != pr_shiphead.ware_code AND 
			edit_line = 1 THEN 
				ERROR " Warehouse cannot be changed in a edit, CLEAR lines THEN re-enter" 
					LET pr_shiphead.ware_code = save_ware 
					DISPLAY pr_shiphead.ware_code TO ware_code 
					NEXT FIELD ware_code 
				END IF 
				IF f_type = "C" AND 
				save_ware != pr_shiphead.ware_code AND 
				ins_line = 1 THEN 
					ERROR " Warehouse cannot be changed WHEN Shipment lines have been entered" 
					LET pr_shiphead.ware_code = save_ware 
					DISPLAY pr_shiphead.ware_code TO ware_code 
					NEXT FIELD ware_code 
				END IF 
				IF pr_shiphead.ware_code IS NULL THEN 
					ERROR "A Warehouse code must be entered." 
					LET pr_shiphead.ware_code = save_ware 
					DISPLAY pr_shiphead.ware_code TO ware_code 
					NEXT FIELD ware_code 
				ELSE 
					SELECT * 
					INTO pr_warehouse.* 
					FROM warehouse 
					WHERE ware_code = pr_shiphead.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (status = notfound) THEN 
						ERROR "Warehouse NOT found, try again" 
						NEXT FIELD ware_code 
					END IF 
				END IF 

		AFTER FIELD eta_curr_date 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_shiphead.eta_curr_date) 
			RETURNING pr_shiphead.year_num, pr_shiphead.period_num 
			IF conv_flag AND save_conv = pr_shiphead.conversion_qty THEN 
				CALL get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					pr_shiphead.curr_code, 
					pr_shiphead.eta_curr_date, 
					CASH_EXCHANGE_SELL) 
					RETURNING pr_shiphead.conversion_qty 
				LET save_conv = pr_shiphead.conversion_qty 
			END IF
			 
			DISPLAY BY NAME 
				pr_shiphead.year_num, 
				pr_shiphead.period_num, 
				pr_shiphead.conversion_qty 

		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				pr_shiphead.year_num, 
				pr_shiphead.period_num, 
				LEDGER_TYPE_AR) 
			RETURNING 
				pr_shiphead.year_num, 
				pr_shiphead.period_num, 
				failed_it 

			IF failed_it = 1 
			THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD conversion_qty 
			SELECT * 
			INTO pr_glparms.* 
			FROM glparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			IF pr_glparms.base_currency_code = pr_shiphead.curr_code AND 
			pr_shiphead.conversion_qty != 1.0 THEN 
				LET pr_shiphead.conversion_qty = 1.0 
				DISPLAY BY NAME pr_shiphead.conversion_qty 
				ERROR " Rate cannot be altered foreign currency does NOT apply " 
				NEXT FIELD conversion_qty 
			END IF 
			IF NOT conv_flag AND save_conv != pr_shiphead.conversion_qty THEN 
				LET pr_shiphead.conversion_qty = save_conv 
				DISPLAY BY NAME pr_shiphead.conversion_qty 
				ERROR " Rate cannot be altered " 
				NEXT FIELD conversion_qty 
			END IF 
			IF pr_shiphead.conversion_qty IS NULL THEN 
				ERROR " Exchange Rate must have a value " 
				NEXT FIELD conversion_qty 
			END IF 
			IF pr_shiphead.conversion_qty < 0 THEN 
				ERROR " Exchange Rate must be greater than zero " 
				NEXT FIELD conversion_qty 
			END IF 

		AFTER FIELD sale_code 
			SELECT name_text 
			INTO pr_salesperson.name_text 
			FROM salesperson 
			WHERE sale_code = pr_shiphead.sale_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				ERROR "Salesperson NOT found, try again" 
				NEXT FIELD sale_code 
			ELSE 
				DISPLAY BY NAME pr_salesperson.name_text 
			END IF 
			LET ret_flag = ret_flag + 1 

		AFTER FIELD tax_code 
			IF pr_shiphead.tax_code IS NULL THEN 
				ERROR " Must enter a tax code, try window" 
				NEXT FIELD tax_code 
			ELSE 
				SELECT * 
				INTO pr_tax.* 
				FROM tax 
				WHERE tax.tax_code = pr_shiphead.tax_code 
				AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR "Tax Code NOT found, try window" 
					NEXT FIELD tax_code 
				END IF 
			END IF 
			DISPLAY pr_tax.desc_text TO tax.desc_text 
			LET ret_flag = ret_flag + 1 

		AFTER FIELD ship_type_code 
			SELECT * INTO pr_shiptype.* FROM shiptype 
			WHERE shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shiptype.ship_type_code = pr_shiphead.ship_type_code 
			IF status = notfound THEN 
				ERROR "Shipment type NOT found, try window" 
				NEXT FIELD ship_type_code 
			ELSE 
				DISPLAY pr_shiptype.desc_text TO shiptype.desc_text 

			END IF 

		AFTER FIELD ship_status_code 
			SELECT * INTO pr_shipstatus.* FROM shipstatus 
			WHERE ship_status_code = pr_shiphead.ship_status_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				ERROR "Shipstatus NOT found, try window" 
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

			END IF 

		AFTER INPUT 

			IF int_flag OR quit_flag THEN 
			ELSE 
				SELECT * 
				INTO pr_warehouse.* 
				FROM warehouse 
				WHERE ware_code = pr_shiphead.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Warehouse NOT found, try again" 
					NEXT FIELD ware_code 
				END IF 

				IF pr_shiphead.eta_curr_date IS NULL THEN 
					LET pr_shiphead.eta_curr_date = today 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_shiphead.eta_curr_date) 
					RETURNING pr_shiphead.year_num, pr_shiphead.period_num 
				END IF 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					pr_shiphead.year_num, 
					pr_shiphead.period_num, 
					LEDGER_TYPE_AR) 
				RETURNING 
					pr_shiphead.year_num, 
					pr_shiphead.period_num, 
					failed_it 

				IF failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 

				SELECT name_text 
				INTO pr_salesperson.name_text 
				FROM salesperson 
				WHERE sale_code = pr_shiphead.sale_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Salesperson NOT found, try again" 
					NEXT FIELD sale_code 
				ELSE 
					DISPLAY BY NAME pr_salesperson.name_text 
				END IF 

				IF pr_shiphead.tax_code IS NULL THEN 
					ERROR " Must enter a tax code, try window" 
					NEXT FIELD tax_code 
				ELSE 
					SELECT * 
					INTO pr_tax.* 
					FROM tax 
					WHERE tax.tax_code = pr_shiphead.tax_code 
					AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						ERROR "Tax Code NOT found, try window" 
						NEXT FIELD tax_code 
					END IF 
				END IF 
				DISPLAY pr_tax.desc_text TO tax.desc_text 


				LET pr_shiphead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF f_type = "C" THEN 
					LET pr_shiphead.entry_date = today 
				END IF 
				LET pr_shiphead.tax_per = pr_tax.tax_per 

				SELECT * INTO pr_shiptype.* FROM shiptype 
				WHERE shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shiptype.ship_type_code = pr_shiphead.ship_type_code 
				IF status = notfound THEN 
					ERROR "Shipment type NOT found, try window" 
					NEXT FIELD ship_type_code 
				ELSE 
					DISPLAY pr_shiptype.desc_text TO shiptype.desc_text 

				END IF 
				SELECT * INTO pr_shipstatus.* FROM shipstatus 
				WHERE ship_status_code = pr_shiphead.ship_status_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					ERROR "Shipstatus NOT found, try window" 
					NEXT FIELD ship_status_code 
				ELSE 
					DISPLAY pr_shipstatus.desc_text TO shipstatus.desc_text 

				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		IF f_type = "C" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			CLOSE WINDOW wl154 
			GOTO first_window 
		ELSE 
			LET int_flag = 0 
			LET quit_flag = 0 
			CLOSE WINDOW wl154 
			CLOSE WINDOW wl153 
			LET ans = "N" 
			# LET first_time = 1
			RETURN 
		END IF 
	END IF 
	LET pr_shiphead.hand_tax_code = pr_shiphead.tax_code 
	LET pr_shiphead.freight_tax_code = pr_shiphead.tax_code 


	# get default of patch code FROM shipdetl

	IF f_type != "C" THEN 
		DECLARE cd_curs CURSOR FOR 
		SELECT shiphead.acct_override_code 
		INTO patch_code 
		FROM shiphead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_shiphead.vend_code 
		AND ship_code = pr_shiphead.ship_code 
		FOREACH cd_curs 
			EXIT FOREACH 
		END FOREACH 
	END IF 
	WHILE true 

		IF pv_corp_cust THEN 
			SELECT acct_mask_code 
			INTO mask_code 
			FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_corp_cust.type_code 
			IF status = notfound OR mask_code IS NULL OR mask_code = " " THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
				RETURNING mask_code 
			END IF 
		ELSE 
			SELECT acct_mask_code 
			INTO mask_code 
			FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_customer.type_code 
			IF status = notfound OR mask_code IS NULL OR mask_code = " " THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
				RETURNING mask_code 
			END IF 
		END IF 

		CALL build_mask(glob_rec_kandoouser.cmpy_code, mask_code, pr_shiphead.acct_override_code) 
		RETURNING pr_shiphead.acct_override_code 

		SELECT acct_mask_code 
		INTO acct_override_code 
		FROM kandoouser 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sign_on_code = glob_rec_kandoouser.sign_on_code 


		IF status = notfound OR acct_override_code IS NULL 
		OR acct_override_code = " " THEN 
			ERROR " User account mask code invalid, maintain menu U12" 
			SLEEP 5 
			EXIT program 
		END IF 

		CALL build_mask(glob_rec_kandoouser.cmpy_code, 
		pr_shiphead.acct_override_code, 
		acct_override_code) 
		RETURNING pr_shiphead.acct_override_code 


		LET enter_seg = "N" 

		DECLARE struct_cur CURSOR FOR 
		SELECT * 
		INTO pr_structure.* 
		FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num > 0 
		AND type_ind = "S" 

		FOREACH struct_cur 
			LET i = pr_structure.start_num 
			LET j = pr_structure.length_num 
			LET x = 0 

			FOR x = i TO (i + j) 
				IF pr_shiphead.acct_override_code[x] = "?" THEN 
					LET enter_seg = "Y" 
					EXIT FOR 
				END IF 
			END FOR 

			IF enter_seg = "Y" THEN 
				EXIT FOREACH 
			END IF 

		END FOREACH 

		IF enter_seg = "Y" THEN 
			CALL segment_fill(glob_rec_kandoouser.cmpy_code, mask_code, pr_shiphead.acct_override_code) 
			RETURNING pr_shiphead.acct_override_code 
		END IF 

		IF enter_seg = "N" AND 
		pr_arparms.show_seg_flag = "Y" THEN 
			CALL segment_fill(glob_rec_kandoouser.cmpy_code, pr_shiphead.acct_override_code, 
			pr_shiphead.acct_override_code) 
			RETURNING pr_shiphead.acct_override_code 
		END IF 

		LET patch_code = pr_shiphead.acct_override_code 
		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			GOTO second_window 
		END IF 

		WHENEVER ERROR CONTINUE 
		EXIT WHILE 
	END WHILE 
END FUNCTION 


FUNCTION display_customer() 
	DEFINE balance_amt, cred_avail_amt LIKE customer.bal_amt, 
	fr_customer RECORD LIKE customer.* 

	IF pv_corp_cust AND pr_customer.inv_addr_flag = "C" THEN 
		LET fr_customer.* = pr_corp_cust.* 
	ELSE 
		LET fr_customer.* = pr_customer.* 
	END IF 


	SELECT * 
	INTO pr_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_customer.term_code 

	LET balance_amt = pr_customer.bal_amt 
	LET cred_avail_amt = pr_customer.cred_limit_amt - pr_customer.bal_amt - 
	pr_customer.onorder_amt 

	DISPLAY BY NAME pr_customer.cust_code, 
	fr_customer.name_text, 
	fr_customer.addr1_text, 
	fr_customer.addr2_text, 
	fr_customer.city_text, 
	fr_customer.state_code, 
	fr_customer.post_code, 
	fr_customer.country_code, --@db-patch_2020_10_04--
	fr_customer.hold_code, 
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
END FUNCTION 
