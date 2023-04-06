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

	Source code beautified by beautify.pl on 2019-12-31 14:28:27	$Id: $
}




#  K11d.4gl:FUNCTION sub_summary(pr_mode)
#           INPUT of freight AND carrier details
#  K11d.4gl:FUNCTION K11_subhead_disp_summ()
#           called FROM sub_summary
#           recalculates AND displays subhead totals
#  K11d.4gl:FUNCTION pay_detail()
#           called FROM header_entry() allows user TO change default term
#           AND tax codes
#  K11d.4gl:FUNCTION view_cust()
#           Opens a window showing customer balance details


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


FUNCTION sub_summary(pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_carrier RECORD LIKE carrier.*, 
	pr_term RECORD LIKE term.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_save_carr_code LIKE subhead.carrier_code, 
	pr_freight_amt LIKE subhead.freight_amt, 
	pr_weight_qty LIKE product.weight_qty, 
	pr_save_freight_ind LIKE customership.freight_ind, 
	query_text CHAR(200) 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 


	LET query_text = 
	"SELECT part_code,sum(sub_qty) FROM t_subdetl group by 1" 
	INITIALIZE pr_carrier.* TO NULL 
	IF pr_subhead.carrier_code IS NOT NULL THEN 
		SELECT * INTO pr_carrier.* 
		FROM carrier 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND carrier_code = pr_subhead.carrier_code 
		IF status = 0 THEN 
			DISPLAY pr_carrier.name_text TO carrier.name_text 

		END IF 
	END IF 
	IF pr_mode = "ADD" OR pr_mode = "CORP" THEN 
		SELECT * INTO pr_customership.* 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		AND ship_code = pr_subhead.ship_code 
		IF status = 0 THEN 
			LET pr_subhead.carrier_code = pr_customership.carrier_code 
			LET pr_subhead.ship1_text = pr_customership.ship1_text 
			LET pr_subhead.ship2_text = pr_customership.ship2_text 
			LET pr_subhead.freight_amt = 
			calc_freight_charges(glob_rec_kandoouser.cmpy_code,pr_subhead.carrier_code, 
			pr_customership.freight_ind, 
			pr_subhead.state_code, 
			pr_customer.country_code, 
			pr_weight_qty) 
		END IF 
		LET pr_subhead.hand_amt = calc_handling_charges(glob_rec_kandoouser.cmpy_code,query_text) 
		SELECT * INTO pr_term.* 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = pr_subhead.term_code 
		LET pr_subhead.disc_amt= 
		(pr_subhead.total_amt*pr_term.disc_per/100) 
		LET pr_subhead.ship_date = pr_subhead.sub_date 
		LET pr_subhead.prepaid_flag = "P" 
		SELECT * INTO pr_substype.* 
		FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_subhead.sub_type_code 
		CASE 
			WHEN pr_substype.inv_ind = "1" 
				LET pr_subhead.inv_date = pr_subhead.sub_date 
			WHEN pr_substype.inv_ind = "2" 
				IF month(pr_subhead.end_date) > pr_substype.inv_mth_num THEN 
					LET pr_subhead.inv_date = mdy(pr_substype.inv_mth_num, 
					pr_substype.inv_day_num, 
					year(pr_subhead.end_date)) 
				ELSE 
				LET pr_subhead.inv_date = mdy(pr_substype.inv_mth_num, 
				pr_substype.inv_day_num, 
				year(pr_subhead.start_date)) 
			END IF 
			WHEN pr_substype.inv_ind = "3" 
				LET pr_subhead.inv_date = pr_subhead.end_date 
			WHEN pr_substype.inv_ind = "4" 
				LET pr_subhead.inv_date = pr_subhead.sub_date 
		END CASE 
	END IF 
	LET msgresp=kandoomsg("A",1067,"") 
	#A1067" Order Shipping & Summary Details - ESC TO Continue"
	DISPLAY BY NAME pr_subhead.cust_code, 
	pr_customer.name_text 

	CALL K11_subhead_disp_summ() 
	INPUT BY NAME pr_subhead.carrier_code, 
	pr_customership.freight_ind, 
	pr_subhead.ship1_text, 
	pr_subhead.ship2_text, 
	pr_subhead.fob_text, 
	pr_subhead.prepaid_flag, 
	pr_subhead.com1_text, 
	pr_subhead.com2_text, 
	pr_subhead.hand_amt, 
	pr_subhead.freight_amt, 
	pr_subhead.sub_date, 
	pr_subhead.inv_date, 
	pr_subhead.ship_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(carrier_code) THEN 
				LET l_tmp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
				IF l_tmp_text IS NOT NULL THEN 
					LET pr_subhead.carrier_code = l_tmp_text clipped 
					NEXT FIELD carrier_code 
				END IF 
			END IF 

		BEFORE FIELD carrier_code 
			LET pr_save_carr_code = pr_subhead.carrier_code 

		AFTER FIELD carrier_code 
			IF pr_subhead.carrier_code IS NOT NULL THEN 
				SELECT * INTO pr_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = pr_subhead.carrier_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("A",9042,"") 
					#9042" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 
				IF pr_save_carr_code != pr_subhead.carrier_code 
				OR pr_save_carr_code IS NULL THEN 
					IF pr_carrier.charge_ind = 2 THEN 
						IF pr_weight_qty = 0 THEN 
							SELECT sum(p.weight_qty * o.sub_qty ) 
							INTO pr_weight_qty 
							FROM t_subdetl o, product p 
							WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND o.part_code = p.part_code 
							AND p.weight_qty IS NOT NULL 
						END IF 
					END IF 
					LET pr_subhead.freight_amt = 
					calc_freight_charges(glob_rec_kandoouser.cmpy_code,pr_subhead.carrier_code, 
					pr_customership.freight_ind, 
					pr_subhead.state_code, 
					pr_customer.country_code, 
					pr_weight_qty) 
				END IF 
				DISPLAY pr_carrier.name_text TO carrier.name_text 

				CALL K11_subhead_disp_summ() 
			ELSE 
			CLEAR carrier.name_text 
		END IF 
		BEFORE FIELD freight_ind 
			LET pr_save_freight_ind = pr_customership.freight_ind 
		AFTER FIELD freight_ind 
			IF pr_save_freight_ind != pr_customership.freight_ind 
			OR pr_save_freight_ind IS NULL THEN 
				IF pr_carrier.charge_ind = 2 THEN 
					IF pr_weight_qty = 0 THEN 
						SELECT sum(p.weight_qty * o.sub_qty ) 
						INTO pr_weight_qty 
						FROM t_subdetl o, product p 
						WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND o.part_code = p.part_code 
						AND p.weight_qty IS NOT NULL 
						AND (o.sub_num IS NULL OR o.sub_num = pr_subhead.sub_num) 
					END IF 
				END IF 
				LET pr_subhead.freight_amt = 
				calc_freight_charges(glob_rec_kandoouser.cmpy_code,pr_subhead.carrier_code, 
				pr_customership.freight_ind, 
				pr_subhead.state_code, 
				pr_customer.country_code, 
				pr_weight_qty) 
				CALL K11_subhead_disp_summ() 
			END IF 
		AFTER FIELD freight_amt 
			CALL K11_subhead_disp_summ() 
		AFTER FIELD hand_amt 
			CALL K11_subhead_disp_summ() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	DELETE FROM t_subhead 
	WHERE rowid = pr_growid 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION K11_subhead_disp_summ() 
	DEFINE 
	pr_tax RECORD LIKE tax.*, 
	pr_tot_tax DECIMAL(16,2) 

	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_subhead.tax_code 
	IF pr_tax.freight_per IS NULL THEN 
		LET pr_tax.freight_per = 0 
	END IF 
	IF pr_tax.hand_per IS NULL THEN 
		LET pr_tax.hand_per = 0 
	END IF 
	SELECT sum(unit_amt * sub_qty), 
	sum(unit_tax_amt * sub_qty), 
	sum(line_total_amt) 
	INTO pr_subhead.goods_amt, 
	pr_subhead.tax_amt, 
	pr_subhead.total_amt 
	FROM t_subdetl 
	WHERE (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	IF pr_subhead.goods_amt IS NULL THEN 
		LET pr_subhead.goods_amt = 0 
	END IF 
	IF pr_subhead.tax_amt IS NULL THEN 
		LET pr_subhead.tax_amt = 0 
	END IF 
	IF pr_subhead.hand_amt IS NULL THEN 
		LET pr_subhead.hand_amt = 0 
	ELSE 
	LET pr_subhead.hand_tax_amt = 
	pr_tax.hand_per*pr_subhead.hand_amt/100 
END IF 
IF pr_subhead.freight_amt IS NULL THEN 
	LET pr_subhead.freight_amt = 0 
ELSE 
LET pr_subhead.freight_tax_amt = 
(pr_tax.freight_per*pr_subhead.freight_amt)/100 
END IF 
LET pr_tot_tax = pr_subhead.tax_amt 
+ pr_subhead.hand_tax_amt 
+ pr_subhead.freight_tax_amt 
LET pr_subhead.total_amt = pr_subhead.goods_amt 
+ pr_subhead.tax_amt 
+ pr_subhead.hand_amt 
+ pr_subhead.hand_tax_amt 
+ pr_subhead.freight_amt 
+ pr_subhead.freight_tax_amt 
DISPLAY BY NAME pr_subhead.freight_amt, 
pr_subhead.hand_amt, 
pr_subhead.goods_amt, 
pr_subhead.total_amt, 
pr_subhead.rev_num, 
pr_subhead.rev_date 
attribute(yellow) 
DISPLAY pr_tot_tax TO tax_amt 
attribute(yellow) 
DISPLAY BY NAME pr_subhead.currency_code 
attribute(green) 
END FUNCTION 



FUNCTION pay_detail() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_term RECORD LIKE term.*, 
	pr_tax RECORD LIKE tax.* 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 

	SELECT desc_text 
	INTO pr_term.desc_text 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_subhead.term_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp=kandoomsg("E",9056,"") 
		#9056" Payment Terms do NOT exist - try window"
		LET pr_term.desc_text = "**********" 
	END IF 
	SELECT desc_text 
	INTO pr_tax.desc_text 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_subhead.tax_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp=kandoomsg("E",9057,"") 
		#9057" Taxation Code do NOT exist "
		LET pr_tax.desc_text = "**********" 
	END IF 
	IF pr_subhead.conv_qty IS NULL OR pr_subhead.conv_qty = 0 THEN 
		LET pr_subhead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			pr_subhead.currency_code, 
			pr_subhead.sub_date,
			CASH_EXCHANGE_SELL) 
	END IF
	 
	OPEN WINDOW K159 at 14,8 WITH FORM "K159" attribute(border,white,MESSAGE line first) 
	LET msgresp=kandoomsg("E",1016,"") #1016 Enter Payment Details - F8 Customer Inquiry - F9 Credit Details
	
	DISPLAY pr_term.desc_text, 
	pr_tax.desc_text 
	TO term.desc_text, 
	tax.desc_text 

	DISPLAY BY NAME pr_subhead.currency_code 
	attribute(green) 
	INPUT BY NAME pr_subhead.term_code, 
	pr_subhead.tax_code, 
	pr_subhead.conv_qty 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(term_code) 
					LET l_tmp_text = show_term(glob_rec_kandoouser.cmpy_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.term_code = l_tmp_text 
					END IF 
					NEXT FIELD term_code 
				WHEN infield(tax_code) 
					LET l_tmp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.tax_code = l_tmp_text 
					END IF 
					NEXT FIELD tax_code 
			END CASE 

		ON KEY (F8) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_subhead.cust_code) --customer details / customer invoice submenu 

		ON KEY (F9) 
			CALL view_cust(pr_subhead.cust_code) 

		AFTER FIELD term_code 
			CLEAR term.desc_text 
			IF pr_subhead.term_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9058,"") 
				#9058" Payment Term must be Entered"
				LET pr_subhead.term_code = pr_customer.term_code 
				NEXT FIELD term_code 
			ELSE 
			SELECT * INTO pr_term.* 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = pr_subhead.term_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp=kandoomsg("E",9056,"") 
				#9056" Sales Conditions does NOT exist "
				NEXT FIELD term_code 
			ELSE 
			DISPLAY pr_term.desc_text 
			TO term.desc_text 

		END IF 
	END IF 
		AFTER FIELD tax_code 
			CLEAR tax.desc_text 
			IF pr_subhead.tax_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9059,"") 
				#9059" Taxation Code must be Entered"
				LET pr_subhead.tax_code = pr_customer.tax_code 
				NEXT FIELD tax_code 
			ELSE 
			SELECT * INTO pr_tax.* 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_subhead.tax_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp=kandoomsg("E",9057,"") 
				#9057" Taxation Code do NOT exist "
				NEXT FIELD tax_code 
			ELSE 
			DISPLAY pr_tax.desc_text 
			TO tax.desc_text 

		END IF 
	END IF 
		AFTER FIELD conv_qty 
			IF pr_subhead.conv_qty IS NULL OR pr_subhead.conv_qty = 0 THEN 
				LET msgresp=kandoomsg("E",9060,"")	#9060" Currency Exchange Rate must have a value "
				LET pr_subhead.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					pr_subhead.currency_code, 
					pr_subhead.sub_date,
					CASH_EXCHANGE_SELL) 
				NEXT FIELD conv_qty 
			END IF
			 
			IF pr_subhead.conv_qty < 0 THEN 
				LET msgresp=kandoomsg("E",9061,"")	#9061 " Exchange Rate must be greater than zero "
				NEXT FIELD conv_qty 
			END IF 
			
			IF pr_subhead.conv_qty != get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				pr_subhead.currency_code, 
				pr_subhead.sub_date,CASH_EXCHANGE_SELL) THEN 
				
				LET msgresp = kandoomsg("E",8012,"")	#8012 Exchange Rate IS NOT current. Do you wish TO Update.Y/N
				IF msgresp = "Y" THEN 
					LET pr_subhead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						pr_subhead.currency_code, 
						pr_subhead.sub_date,CASH_EXCHANGE_SELL) 
					
					NEXT FIELD conv_qty 
				END IF 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = pr_subhead.term_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9056,"") 
					#9056 Payment Terms do NOT exist try window
					NEXT FIELD term_code 
				END IF 
				SELECT unique 1 FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = pr_subhead.tax_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9057,"") 
					#9057" Taxation Code do NOT exist "
					NEXT FIELD tax_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW k159 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION view_cust(pr_cust_code) 
	DEFINE 
	pr_cust_code LIKE customer.cust_code, 
	pr_customer RECORD LIKE customer.*, 
	pr_availcr_amt LIKE customer.bal_amt 

	SELECT * INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_cust_code 
	IF sqlca.sqlcode = 0 THEN 
		LET pr_availcr_amt = pr_customer.cred_limit_amt 
		- pr_customer.bal_amt 
		- pr_customer.onorder_amt 
		OPEN WINDOW e113 at 10,8 WITH FORM "E113" 
		attribute(border,white,MESSAGE line first) 
		DISPLAY BY NAME pr_customer.currency_code 
		attribute(green) 
		DISPLAY BY NAME pr_customer.curr_amt, 
		pr_customer.over1_amt, 
		pr_customer.over30_amt, 
		pr_customer.over60_amt, 
		pr_customer.over90_amt, 
		pr_customer.cred_limit_amt, 
		pr_customer.onorder_amt, 
		pr_customer.last_pay_date 

		DISPLAY pr_customer.bal_amt, 
		pr_customer.bal_amt, 
		pr_availcr_amt 
		TO sr_balance[1].bal_amt, 
		sr_balance[2].bal_amt, 
		availcr_amt 

		CALL eventsuspend() # LET msgresp = kandoomsg("U",1,"") 
		CLOSE WINDOW e113 
	END IF 
END FUNCTION 
