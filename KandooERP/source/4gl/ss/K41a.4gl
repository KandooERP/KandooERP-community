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

	Source code beautified by beautify.pl on 2019-12-31 14:28:29	$Id: $
}


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K41  allows the user TO enter Accounts Receivable Credits
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 

FUNCTION K41_header() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE failed_it, err_flag, cnt, chosen, exist, idx, id_flag SMALLINT, 
	mask_code LIKE account.acct_code, 
	pr_temp_text CHAR(200) 

	IF first_time = 1 THEN 
		LET first_time = 0 
	ELSE 
	GOTO second_window 
END IF 
# INITIALIZE variables IF new invoice
LET imaging_used = false 
IF f_type = "C" THEN 
	INITIALIZE pr_customer.* TO NULL 
	LET pr_credithead.entry_date = today 
	LET pr_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
	OPEN WINDOW wa127 at 2,3 WITH FORM "A127" 
	attribute(border) 
	LABEL first_window: 

	INPUT BY NAME pr_customer.cust_code 
		ON KEY (F5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
			NEXT FIELD cust_code 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (cust_code) 
			LET pr_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME pr_customer.cust_code 

			NEXT FIELD cust_code 

		BEFORE FIELD cust_code 
			IF display_cred_num = "Y" THEN 
				LET msgresp = kandoomsg("E",7061,temp_cred_num) 
				#7061 Successful addition of Credit Note Number: temp_cred_num
				LET display_cred_num = "N" 
			ELSE 
			LET msgresp = kandoomsg("W",1159,"") 
			#1159 Enter Credit Details;  OK TO Continue.
		END IF 
		AFTER FIELD cust_code 
			SELECT * INTO pr_customer.* FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.cust_code 
			IF (status = notfound) THEN 
				LET msgresp = kandoomsg("A",9009,"") 
				#9009 Customer code NOT found;  Try Window.
				NEXT FIELD cust_code 
			END IF 
			CALL display_customer() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF goon = "N" THEN 
		CLOSE WINDOW wa127 
		RETURN 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET ans = "N" 
		CLOSE WINDOW wa127 
		RETURN 
	END IF 
	# just DISPLAY IF invoice edit
ELSE 
OPEN WINDOW wa127 at 2,3 WITH FORM "A127" 
attribute (border) 
LET save_ship = pr_credithead.cred_text 
CALL display_customer() 
END IF 
DISPLAY BY NAME pr_customer.currency_code 
attribute(green) 
LET pr_credithead.cust_code = pr_customer.cust_code 
SELECT * INTO pr_arparms.* FROM arparms 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND parm_code = "1" 
IF status = notfound THEN 
LET msgresp = kandoomsg("K",5002,"") 
#5002 AR Parameters are NOT setup;  Refer Menu AZP.
EXIT program 
END IF 
IF f_type = "C" THEN 
LET pr_credithead.cred_date = today 
CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_credithead.cred_date) 
RETURNING pr_credithead.year_num, pr_credithead.period_num 
END IF 
OPEN WINDOW wk155 at 14,3 WITH FORM "K155" 
attribute (border) 
LABEL second_window: 
IF f_type = "C" THEN 
LET pr_credithead.sale_code = pr_customer.sale_code 
LET pr_credithead.tax_code = pr_customer.tax_code 
###
### obtain default shipping address
###
SELECT count(*) INTO i FROM customership 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_credithead.cust_code 
CASE 
	WHEN i = 0 ## no ship adresses SET up - use billing address 
	WHEN i = 1 ## one shipping address SET up. this becomes default 
		SELECT ship_code INTO pr_credithead.cred_text 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
	OTHERWISE 
		###
		### IF multiple addresses SET up THEN try FOR one with same code
		### as customer.  IF NOT SET up THEN SELECT any as default.
		SELECT unique 1 FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		AND ship_code = pr_credithead.cust_code 
		IF sqlca.sqlcode = notfound THEN 
			DECLARE c_custship CURSOR FOR 
			SELECT ship_code FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_credithead.cust_code 
			OPEN c_custship 
			FETCH c_custship INTO pr_credithead.cred_text 
		ELSE 
		LET pr_credithead.cred_text = pr_credithead.cust_code 
	END IF 
END CASE 
ELSE 
LET pr_customer.cred_bal_amt = pr_customer.cred_bal_amt + pr_credithead.total_amt 
DECLARE w_curs CURSOR FOR 
SELECT ware_code INTO pr_warehouse.ware_code FROM creditdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_credithead.cust_code 
AND cred_num = pr_credithead.cred_num 
AND ware_code IS NOT NULL 
OPEN w_curs 
FETCH w_curs 
END IF 
SELECT * INTO pr_salesperson.* FROM salesperson 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sale_code = pr_credithead.sale_code 
SELECT * INTO pr_tax.* FROM tax 
WHERE tax.tax_code = pr_credithead.tax_code 
AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
SELECT * INTO pr_warehouse.* FROM warehouse 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND ware_code = pr_warehouse.ware_code 
LET pr_creditdetl.ware_code = pr_warehouse.ware_code 
DISPLAY BY NAME pr_creditdetl.ware_code, 
pr_credithead.ref_num, 
pr_credithead.cred_date, 
pr_credithead.entry_code, 
pr_credithead.year_num, 
pr_credithead.period_num, 
pr_credithead.cred_text, 
pr_credithead.sale_code, 
pr_salesperson.name_text, 
pr_credithead.tax_code, 
pr_tax.desc_text 

LET msgresp = kandoomsg("W",1082,"") 
#1146 Enter Credit Details;  F5 FOR Customer Query;  OK TO Contniue.
INPUT BY NAME pr_creditdetl.ware_code, 
pr_credithead.ref_num, 
pr_credithead.cred_text, 
pr_credithead.cred_date, 
pr_credithead.year_num, 
pr_credithead.period_num, 
pr_credithead.sale_code, 
pr_credithead.tax_code WITHOUT DEFAULTS 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	ON KEY (control-b) infield (ware_code) 
		LET pr_creditdetl.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
		DISPLAY BY NAME pr_creditdetl.ware_code 

		NEXT FIELD ware_code 

	ON KEY (control-b) infield(ref_num) 
		LET pr_temp_text = "(cust_code = '",pr_credithead.cust_code,"'", 
		" OR (corp_flag = 'Y' AND corp_cust_code = '", 
		pr_credithead.cust_code,"')) " 
		LET pr_credithead.ref_num = show_subhead(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
		DISPLAY BY NAME pr_credithead.ref_num 

		NEXT FIELD ref_num 

	ON KEY (control-b) infield (sale_code) 
		LET pr_credithead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
		DISPLAY BY NAME pr_credithead.sale_code 

		NEXT FIELD sale_code 

	ON KEY (control-b) infield (tax_code) 
		LET pr_credithead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
		DISPLAY BY NAME pr_credithead.tax_code 

		NEXT FIELD tax_code 

	ON KEY (control-b) infield (cred_text) 
		LET pr_credithead.cred_text = show_ship(glob_rec_kandoouser.cmpy_code, 
		pr_credithead.cust_code) 
		DISPLAY BY NAME pr_credithead.cred_text 

		NEXT FIELD cred_text 


	ON KEY (F5) --customer details / customer invoice submenu 
		CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_customer.cust_code) --customer details / customer invoice submenu 
		NEXT FIELD ware_code 

	AFTER FIELD ware_code 
		IF pr_creditdetl.ware_code IS NOT NULL THEN 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE ware_code = pr_creditdetl.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				LET msgresp = kandoomsg("A",9091,"") 
				#9091 Warehouse NOT found; Try Window.
				NEXT FIELD ware_code 
			END IF 
		END IF 

	AFTER FIELD cred_date 
		CALL db_period_what_period(
			glob_rec_kandoouser.cmpy_code, 
			pr_credithead.cred_date) 
		RETURNING 
			pr_credithead.year_num, 
			pr_credithead.period_num 
		
		DISPLAY BY NAME 
			pr_credithead.period_num, 
			pr_credithead.year_num 

	AFTER FIELD period_num 
		CALL valid_period(
			glob_rec_kandoouser.cmpy_code, 
			pr_credithead.year_num, 
			pr_credithead.period_num, 
			LEDGER_TYPE_AR) 
		RETURNING 
			pr_credithead.year_num, 
			pr_credithead.period_num, 
			failed_it 
		IF failed_it = 1 THEN 
			NEXT FIELD year_num 
		END IF
		 
	AFTER FIELD cred_text 
		IF pr_credithead.cred_text IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"")#9102 Value must be entered.
			NEXT FIELD cred_text 
		END IF 
		
		IF save_ship != pr_credithead.cred_text THEN 
			IF cred_type = "C" THEN {new credit} 
				SELECT * INTO pr_customership.* FROM customership 
				WHERE cust_code = pr_customer.cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ship_code = pr_credithead.cred_text 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("U",9111,"Customer shipping") 
					#9111 Customer shipping NOT found.
					NEXT FIELD cred_text 
				END IF 
			ELSE 
			LET msgresp = kandoomsg("K",9121,"") 
			#9121 Unable TO edit Shipping Code.
			LET pr_credithead.cred_text = save_ship 
			NEXT FIELD cred_text 
		END IF 
	END IF 
	AFTER FIELD sale_code 
		SELECT name_text INTO pr_salesperson.name_text FROM salesperson 
		WHERE sale_code = pr_credithead.sale_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (status = notfound) THEN 
			LET msgresp = kandoomsg("A",9032,"") 
			#9032 Salesperson code NOT found;  Try Window.
			NEXT FIELD sale_code 
		ELSE 
		DISPLAY BY NAME pr_salesperson.name_text 

	END IF 
	LET ret_flag = ret_flag + 1 
	AFTER FIELD tax_code 
		SELECT * INTO pr_tax.* FROM tax 
		WHERE tax.tax_code = pr_credithead.tax_code 
		AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (status = notfound) THEN 
			LET msgresp = kandoomsg("P",9106,"") 
			#9106 Tax Code NOT found; Try Window.
			NEXT FIELD tax_code 
		ELSE 
		DISPLAY BY NAME pr_tax.desc_text 

	END IF 
	LET ret_flag = ret_flag + 1 
	BEFORE FIELD ref_num 
		IF f_type = "C" THEN ELSE 
			NEXT FIELD NEXT 
		END IF 
	AFTER FIELD ref_num 
		IF pr_credithead.ref_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD ref_num 
		END IF 
		SELECT * INTO pr_subhead.* FROM subhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_credithead.ref_num 
		AND (cust_code = pr_credithead.cust_code OR 
		(corp_flag = 'Y' AND corp_cust_code = pr_credithead.cust_code)) 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9105,"") 
			#9105 RECORD NOT found;  Try Window.
			NEXT FIELD ref_num 
		END IF 
	AFTER INPUT 
		IF not(int_flag OR quit_flag) THEN 
			IF pr_creditdetl.ware_code IS NOT NULL THEN 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE ware_code = pr_creditdetl.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("A",9091,"") 
					#9091 Warehouse NOT found; Try Window.
					NEXT FIELD ware_code 
				END IF 
			END IF 
			IF pr_credithead.cred_date IS NULL THEN 
				LET pr_credithead.cred_date = today 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_credithead.cred_date) 
				RETURNING pr_credithead.year_num, pr_credithead.period_num 
			END IF 
			
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				pr_credithead.year_num, 
				pr_credithead.period_num, 
				LEDGER_TYPE_AR) 
			RETURNING 
				pr_credithead.year_num, 
				pr_credithead.period_num, 
				failed_it 
			
			IF failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 
			
			IF pr_credithead.cred_text IS NULL THEN 
				ERROR " Must enter a shipping code " 
				NEXT FIELD cred_text 
			END IF 
			
			IF save_ship != pr_credithead.cred_text THEN 
				IF cred_type = "C" THEN {new credit} 
					SELECT * INTO pr_customership.* FROM customership 
					WHERE cust_code = pr_customer.cust_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = pr_credithead.cred_text 
					IF (status = notfound) THEN 
						ERROR "Customer shipping NOT found" 
						NEXT FIELD cred_text 
					END IF 
				ELSE 
				LET msgresp = kandoomsg("K",9121,"")		#9121 Unable TO edit Shipping Code.
				LET pr_credithead.cred_text = save_ship 
				NEXT FIELD cred_text 
			END IF 
		END IF 
		IF pr_credithead.ref_num IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered.
			NEXT FIELD ref_num 
		END IF 
		SELECT name_text INTO pr_salesperson.name_text FROM salesperson 
		WHERE sale_code = pr_credithead.sale_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (status = notfound) THEN 
			LET msgresp = kandoomsg("A",9032,"") 
			#9032 Salesperson code NOT found;  Try Window.
			NEXT FIELD sale_code 
		ELSE 
		DISPLAY BY NAME pr_salesperson.name_text 

	END IF 
	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE tax.tax_code = pr_credithead.tax_code 
	AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF (status = notfound) THEN 
		LET msgresp = kandoomsg("P",9106,"") 
		#9106 Tax Code NOT found; Try Window.
		NEXT FIELD tax_code 
	ELSE 
	DISPLAY BY NAME pr_tax.desc_text 

END IF 
LET pr_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
IF f_type = "C" THEN 
	LET pr_credithead.entry_date = today 
END IF 
LET pr_credithead.tax_per = pr_tax.tax_per 
END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag 
		AND f_type = "C" THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW wk155 
			LET imaging_used = false 
			GOTO first_window 
		END IF 
		LET pr_credithead.currency_code = pr_customer.currency_code 
		LET pr_credithead.territory_code = pr_customer.territory_code 
		LET pr_credithead.cond_code = pr_customer.cond_code 
		LET pr_credithead.mgr_code = pr_salesperson.mgr_code 
		LET pr_credithead.cred_ind = 7 
		LET pr_credithead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			pr_credithead.currency_code, 
			pr_credithead.cred_date,
			CASH_EXCHANGE_SELL) 
		
		LET pr_credheadaddr.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_credheadaddr.addr1_text = pr_subhead.ship_addr1_text 
		LET pr_credheadaddr.addr2_text = pr_subhead.ship_addr2_text 
		LET pr_credheadaddr.city_text = pr_subhead.ship_city_text 
		LET pr_credheadaddr.state_code = pr_subhead.state_code 
		LET pr_credheadaddr.post_code = pr_subhead.post_code 
		
		SELECT area_code INTO pr_credithead.area_code FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = pr_credithead.sale_code 
		AND terr_code = pr_credithead.territory_code 
		# get default of patch code FROM creditdetl
		DECLARE cd_curs CURSOR FOR 
		SELECT line_acct_code INTO patch_code FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		AND cred_num = pr_credithead.cred_num 
		AND part_code IS NOT NULL 
		FOREACH cd_curs 
			EXIT FOREACH 
		END FOREACH 
		SELECT acct_mask_code INTO mask_code FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_customer.type_code 
		IF status = notfound OR mask_code IS NULL OR mask_code = " " THEN 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
			RETURNING mask_code 
		END IF 
		CALL build_mask(glob_rec_kandoouser.cmpy_code, mask_code, pr_credithead.acct_override_code) 
		RETURNING pr_credithead.acct_override_code 
		LET patch_code = pr_credithead.acct_override_code 
		IF int_flag OR quit_flag THEN 
			LET ans = "N" 
			CLOSE WINDOW wk155 
			CLOSE WINDOW wa127 
			RETURN 
		END IF 
END FUNCTION 

FUNCTION display_customer() 
	DEFINE balance_amt, 
	cred_avail_amt LIKE customer.bal_amt 

	SELECT * INTO pr_term.* FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_customer.term_code 

	LET balance_amt = pr_customer.bal_amt 
	LET cred_avail_amt = pr_customer.cred_limit_amt - pr_customer.bal_amt - 
	pr_customer.onorder_amt 
	DISPLAY BY NAME pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_customer.addr1_text, 
	pr_customer.addr2_text, 
	pr_customer.city_text, 
	pr_customer.state_code, 
	pr_customer.post_code, 
	pr_customer.country_code, --@db-patch_2020_10_04--
	pr_customer.hold_code, 
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
