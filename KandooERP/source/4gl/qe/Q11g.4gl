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
# \brief module Q11g - Sales Order Summary Information
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

FUNCTION order_summary(pr_mode) 
	DEFINE 
	pr_mode CHAR(4), 
	pr_customer RECORD LIKE customer.*, 
	pr_carrier RECORD LIKE carrier.*, 
	pr_save_carr_code LIKE quotehead.carrier_code, 
	pr_save_freight LIKE quotehead.freight_amt, 
	pr_save_hand LIKE quotehead.hand_amt, 
	pr_freight_amt LIKE quotehead.freight_amt, 
	pr_save_freight_ind LIKE quotehead.freight_ind 

	LET msgresp = kandoomsg("E",1027,"") 
	#1027 Order Shipping & Summary Details - ESC TO Continue
	SELECT * INTO pr_customer.* FROM customer 
	WHERE cust_code = pr_quotehead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT unique 1 FROM t_quotedetl 
	WHERE margin_ind IS NOT NULL 
	IF status = notfound THEN 
		LET pr_quotehead.approved_by = glob_rec_kandoouser.sign_on_code 
		LET pr_quotehead.approved_date = today 
	END IF 
	DISPLAY BY NAME 
		pr_quotehead.entry_code, 
		pr_quotehead.entry_date, 
		pr_quotehead.rev_num, 
		pr_quotehead.rev_date, 
		pr_quotehead.approved_by, 
		pr_quotehead.approved_date, 
		pr_quotehead.hold_code 

	IF pr_quotehead.carrier_code IS NULL 
	AND pr_mode = "ADD" THEN 
		SELECT carrier_code, 
		freight_ind, 
		ship1_text, 
		ship2_text 
		INTO pr_quotehead.carrier_code, 
		pr_quotehead.freight_ind, 
		pr_quotehead.ship1_text, 
		pr_quotehead.ship2_text 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
		AND ship_code = pr_quotehead.ship_code 
	END IF 
	IF pr_quotehead.freight_ind IS NULL THEN 
		LET pr_quotehead.freight_ind = "1" 
	END IF 
	CALL Q11_quotehead_disp_summ() 
	INPUT BY NAME 
		pr_quotehead.carrier_code, 
		pr_quotehead.fob_text, 
		pr_quotehead.freight_ind, 
		pr_quotehead.delivery_ind, 
		pr_quotehead.ship_date, 
		pr_quotehead.freight_amt, 
		pr_quotehead.hand_amt, 
		pr_quotehead.ship1_text, 
		pr_quotehead.ship2_text, 
		pr_quotehead.approved_by, 
		pr_quotehead.approved_date WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11g","inp-carrier_code-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (F5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) --customer details / customer invoice submenu 

		ON KEY (control-b) 
			IF infield(carrier_code) THEN 
				LET pr_temp_text = "state_code =\"",pr_quotehead.state_code,"\"" 
				LET pr_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_quotehead.carrier_code = pr_temp_text clipped 
					NEXT FIELD carrier_code 
				END IF 
			END IF 

		BEFORE FIELD carrier_code 
			LET pr_save_freight = pr_quotehead.freight_amt 
			IF pr_save_freight IS NULL THEN 
				LET pr_save_freight = 0 
			END IF 
			LET pr_save_hand = pr_quotehead.hand_amt 
			IF pr_save_hand IS NULL THEN 
				LET pr_save_hand = 0 
			END IF 
			IF pr_quotehead.carrier_code IS NOT NULL THEN 
				IF pr_mode = "ADD" THEN 
					SELECT name_text, charge_ind 
					INTO pr_carrier.name_text, pr_carrier.charge_ind 
					FROM carrier 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND carrier_code = pr_quotehead.carrier_code 
					IF sqlca.sqlcode = 0 THEN 
						DISPLAY BY NAME pr_carrier.name_text 

						#### No country on ORDER so use customer country
						SELECT country_code INTO pr_carrier.country_code 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_quotehead.cust_code 
						##
						SELECT freight_amt 
						INTO pr_quotehead.freight_amt 
						FROM carriercost 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = pr_quotehead.carrier_code 
						AND state_code = pr_quotehead.state_code 
						AND country_code = pr_carrier.country_code 
						AND freight_ind = pr_quotehead.freight_ind 
						IF status = 0 THEN 
							IF pr_carrier.charge_ind = 2 THEN 
								SELECT sum(p.weight_qty*o.order_qty) 
								INTO pr_freight_amt 
								FROM t_quotedetl o, product p 
								WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND o.part_code = p.part_code 
								AND o.trade_in_flag = "N" 
								AND o.status_ind in ("0","2") 
								AND p.weight_qty IS NOT NULL 
								IF pr_quotehead.freight_amt = 0 THEN 
									IF pr_freight_amt IS NOT NULL THEN 
										LET pr_quotehead.freight_amt = pr_freight_amt * 
										pr_quotehead.freight_amt 
									ELSE 
										LET pr_quotehead.freight_amt = 0 
									END IF 
								END IF 
							END IF 
							CALL Q11_quotehead_disp_summ() 
						END IF 
					END IF 
				END IF 
			END IF 
			LET pr_save_carr_code = pr_quotehead.carrier_code 
		AFTER FIELD carrier_code 
			IF pr_quotehead.carrier_code IS NULL THEN 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_quotehead.ware_code 
				AND connote_flag = "Y" 
				IF status = 0 THEN 
					LET msgresp = kandoomsg("E",9088,"") 
					#9088" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 
			ELSE 
				SELECT * INTO pr_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = pr_quotehead.carrier_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9088,"") 
					#9088" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 
				IF pr_save_carr_code != pr_quotehead.carrier_code 
				OR pr_save_carr_code IS NULL THEN 
					CLEAR name_text 
					SELECT * INTO pr_carrier.* 
					FROM carrier 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND carrier_code = pr_quotehead.carrier_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9088,"") 
						#9088" Carrier does NOT exist - Try Window"
						NEXT FIELD carrier_code 
					ELSE 
						#### No country on ORDER so use customer country
						SELECT country_code INTO pr_carrier.country_code 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_quotehead.cust_code 
						##
						DISPLAY BY NAME pr_carrier.name_text 

						SELECT freight_amt 
						INTO pr_quotehead.freight_amt 
						FROM carriercost 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = pr_carrier.carrier_code 
						AND state_code = pr_quotehead.state_code 
						AND country_code = pr_carrier.country_code 
						AND freight_ind = pr_quotehead.freight_ind 
						IF status = 0 THEN 
							IF pr_carrier.charge_ind = 2 THEN 
								SELECT sum(p.weight_qty * o.order_qty ) 
								INTO pr_freight_amt 
								FROM t_quotedetl o, product p 
								WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND o.part_code = p.part_code 
								AND o.trade_in_flag = "N" 
								AND o.status_ind = "0" 
								AND p.weight_qty IS NOT NULL 
								IF pr_quotehead.freight_amt = 0 THEN 
									IF pr_freight_amt IS NOT NULL THEN 
										LET pr_quotehead.freight_amt = pr_freight_amt * 
										pr_quotehead.freight_amt 
									ELSE 
										LET pr_quotehead.freight_amt = 0 
									END IF 
								END IF 
							END IF 
							CALL Q11_quotehead_disp_summ() 
						END IF 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD freight_ind 
			LET pr_save_freight_ind = pr_quotehead.freight_ind 
		AFTER FIELD freight_ind 
			IF pr_save_freight_ind != pr_quotehead.freight_ind THEN 
				#### No country on ORDER so use customer country
				SELECT country_code INTO pr_carrier.country_code 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_quotehead.cust_code 
				##
				SELECT freight_amt 
				INTO pr_quotehead.freight_amt 
				FROM carriercost 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = pr_quotehead.carrier_code 
				AND state_code = pr_quotehead.state_code 
				AND country_code = pr_carrier.country_code 
				AND freight_ind = pr_quotehead.freight_ind 
				IF sqlca.sqlcode = notfound THEN 
					IF pr_quotehead.carrier_code IS NOT NULL THEN 
						LET msgresp=kandoomsg("E",9091,"") 
						#9091 Automatic Freight calculation failed
					END IF 
				ELSE 
					IF pr_carrier.charge_ind = 2 THEN 
						SELECT sum(p.weight_qty * o.order_qty ) 
						INTO pr_freight_amt 
						FROM t_quotedetl o, product p 
						WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND o.part_code = p.part_code 
						AND o.status_ind = "0" 
						AND o.trade_in_flag = "N" 
						AND p.weight_qty IS NOT NULL 
						IF pr_freight_amt IS NOT NULL THEN 
							LET pr_quotehead.freight_amt = pr_freight_amt * 
							pr_quotehead.freight_amt 
						ELSE 
							LET pr_quotehead.freight_amt = 0 
						END IF 
					END IF 
					CALL Q11_quotehead_disp_summ() 
				END IF 
			END IF 
		AFTER FIELD ship_date 
			IF pr_quotehead.ship_date IS NULL THEN 
				LET pr_quotehead.ship_date = pr_quotehead.quote_date 
				DISPLAY BY NAME pr_quotehead.ship_date 

			ELSE 
				IF pr_quotehead.ship_date < pr_quotehead.quote_date THEN 
					LET pr_quotehead.ship_date = pr_quotehead.quote_date 
					LET msgresp = kandoomsg("E",9090,"") 
					#9090 Delivery date cannot preceed ORDER date
					NEXT FIELD ship_date 
				END IF 
			END IF 
		AFTER FIELD freight_amt 
			IF pr_quotehead.freight_amt IS NULL THEN 
				LET pr_quotehead.freight_amt = pr_save_freight 
			END IF 
			CALL Q11_quotehead_disp_summ() 
		AFTER FIELD hand_amt 
			IF pr_quotehead.hand_amt IS NULL THEN 
				LET pr_quotehead.hand_amt = pr_save_hand 
			END IF 
			CALL Q11_quotehead_disp_summ() 
		AFTER FIELD approved_by 
			IF pr_quotehead.approved_by IS NOT NULL THEN 
				SELECT unique 1 FROM t_quotedetl 
				WHERE margin_ind IS NOT NULL 
				IF status = 0 THEN 
					IF pr_rec_kandoouser.security_ind < glob_rec_qpparms.security_ind THEN 
						LET msgresp = kandoomsg("Q",9240,"") 
						#9240 Pricing margins exceeded by user without proper security
						LET pr_quotehead.approved_by = NULL 
						NEXT FIELD approved_by 
					END IF 
				END IF 
				IF pr_quotehead.approved_date IS NULL THEN 
					NEXT FIELD approved_date 
				END IF 
			END IF 
		AFTER FIELD approved_date 
			IF pr_quotehead.approved_date IS NOT NULL THEN 
				SELECT unique 1 FROM t_quotedetl 
				WHERE margin_ind IS NOT NULL 
				IF status = 0 THEN 
					IF pr_rec_kandoouser.security_ind < glob_rec_qpparms.security_ind THEN 
						LET msgresp = kandoomsg("Q",9240,"") 			#9240 Pricing margins exceeded by user without proper security
						LET pr_quotehead.approved_date = NULL 
						NEXT FIELD approved_date 
					END IF 
				END IF 
			END IF 
			IF pr_quotehead.approved_by IS NOT NULL THEN 
				IF pr_quotehead.approved_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
					NEXT FIELD approved_date 
				END IF 
			ELSE 
				IF pr_quotehead.approved_date IS NOT NULL THEN 
					LET msgresp = kandoomsg("Q",9093,"") 		#9093 Approval Code must have been entered
					LET pr_quotehead.approved_date = NULL 
					NEXT FIELD approved_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION Q11_quotehead_disp_summ() 
	DEFINE 
	pr_non_inv_amt LIKE quotehead.total_amt, 
	pr_sub_total_amt LIKE quotehead.total_amt, 
	pr_gross_amt LIKE quotehead.total_amt, 
	pr_tottax_amt LIKE quotehead.total_amt, 
	pr_tax RECORD LIKE tax.* 

	SELECT * 
	INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_quotehead.tax_code 
	IF pr_tax.freight_per IS NULL THEN 
		LET pr_tax.freight_per = 0 
	END IF 
	IF pr_tax.hand_per IS NULL THEN 
		LET pr_tax.hand_per = 0 
	END IF 
	SELECT sum(list_price_amt*order_qty), 
	sum(ext_price_amt), 
	sum(ext_tax_amt), 
	sum(line_tot_amt) 
	INTO pr_gross_amt, 
	pr_quotehead.goods_amt, 
	pr_quotehead.tax_amt, 
	pr_quotehead.total_amt 
	FROM t_quotedetl 
	IF pr_gross_amt IS NULL THEN 
		LET pr_gross_amt = 0 
	END IF 
	IF pr_quotehead.goods_amt IS NULL THEN 
		LET pr_quotehead.goods_amt = 0 
	END IF 
	IF pr_quotehead.tax_amt IS NULL THEN 
		LET pr_quotehead.tax_amt = 0 
	END IF 
	LET pr_quotehead.disc_amt = pr_gross_amt - pr_quotehead.goods_amt 
	IF pr_quotehead.hand_amt IS NULL THEN 
		LET pr_quotehead.hand_amt = 0 
	ELSE 
		LET pr_quotehead.hand_tax_amt = pr_tax.hand_per*pr_quotehead.hand_amt/100 
	END IF 
	IF pr_quotehead.freight_amt IS NULL THEN 
		LET pr_quotehead.freight_amt = 0 
	ELSE 
		LET pr_quotehead.freight_tax_amt = 
		(pr_tax.freight_per*pr_quotehead.freight_amt)/100 
	END IF 
	LET pr_non_inv_amt = pr_quotehead.hand_amt 
	+ pr_quotehead.freight_amt 
	LET pr_tottax_amt = pr_quotehead.tax_amt 
	+ pr_quotehead.hand_tax_amt 
	+ pr_quotehead.freight_tax_amt 
	LET pr_quotehead.total_amt = pr_quotehead.goods_amt 
	+ pr_quotehead.tax_amt 
	+ pr_quotehead.hand_amt 
	+ pr_quotehead.hand_tax_amt 
	+ pr_quotehead.freight_amt 
	+ pr_quotehead.freight_tax_amt 
	LET pr_sub_total_amt = pr_quotehead.total_amt 
	- pr_tottax_amt 
	DISPLAY pr_quotehead.freight_amt, 
	pr_quotehead.hand_amt, 
	pr_gross_amt, 
	pr_quotehead.disc_amt, 
	pr_sub_total_amt, 
	pr_tottax_amt, 
	pr_non_inv_amt, 
	pr_quotehead.total_amt 
	TO quotehead.freight_amt, 
	quotehead.hand_amt, 
	quotehead.goods_amt, 
	quotehead.disc_amt, 
	pr_sub_total_amt, 
	quotehead.tax_amt, 
	pr_non_inv_amt, 
	quotehead.total_amt 
	attribute(yellow) 
END FUNCTION 


FUNCTION enter_hold() 
	DEFINE 
	pr_customer RECORD LIKE customer.*, 
	pr_holdreas RECORD LIKE holdreas.*, 
	l_overdue_amt LIKE customer.bal_amt, 
	pr_cust_hold_code LIKE customer.hold_code, 
	pr_prev_hold_code LIKE quotehead.hold_code, 
	pr_cust_reason_text LIKE holdreas.reason_text 

	OPEN WINDOW e105 with FORM "E105" -- alch kd-747 
	CALL winDecoration_e("E105") -- alch kd-747 
	LET msgresp = kandoomsg("E",1013,"") #1013 Sales Order Hold Code
	SELECT * INTO pr_customer.* FROM customer 
	WHERE cust_code = pr_quotehead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_customer.hold_code IS NOT NULL THEN 
		LET pr_cust_hold_code = pr_customer.hold_code 
		SELECT reason_text INTO pr_cust_reason_text FROM holdreas 
		WHERE hold_code = pr_cust_hold_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DISPLAY BY NAME pr_cust_hold_code, 
		pr_cust_reason_text 

	END IF 
	LET l_overdue_amt = pr_customer.bal_amt - pr_customer.curr_amt 
	IF l_overdue_amt < 0 THEN 
		LET l_overdue_amt = 0 
	END IF 
	DISPLAY l_overdue_amt TO overdue_amt

	LET pr_holdreas.hold_code = pr_quotehead.hold_code 
	DISPLAY BY NAME pr_holdreas.hold_code 

	LET pr_prev_hold_code = pr_holdreas.hold_code 
	INPUT BY NAME pr_holdreas.hold_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11g","inp-hold_code-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (control-b) 
			LET pr_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_holdreas.hold_code = pr_temp_text 
			END IF 
			NEXT FIELD hold_code 
		BEFORE FIELD hold_code 
			SELECT reason_text INTO pr_holdreas.reason_text FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = pr_holdreas.hold_code 
			DISPLAY BY NAME pr_holdreas.reason_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_holdreas.hold_code IS NOT NULL THEN 
					SELECT unique 1 FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = pr_holdreas.hold_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("E",9045,"") 
						#9045" Sales ORDER hold code NOT found"
						NEXT FIELD hold_code 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW e105 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET pr_quotehead.hold_code = pr_holdreas.hold_code 
	RETURN true 
END FUNCTION 


FUNCTION enter_defaults() 
	DEFINE 
	pr_defaults RECORD 
		quote_date DATE, 
		ship_date DATE, 
		paydetl_flag CHAR(1), 
		owner_text CHAR(8) 
	END RECORD 

	OPEN WINDOW q125 with FORM "Q125" -- alch kd-747 
	CALL windecoration_q("Q125") -- alch kd-747 
	LET msgresp = kandoomsg("E",1028,"") 
	#1028 Enter Session Defaults
	LET pr_defaults.quote_date = pr_globals.quote_date 
	LET pr_defaults.ship_date = pr_globals.ship_date 
	LET pr_defaults.paydetl_flag = pr_globals.def_paydetl_flag 
	LET pr_defaults.owner_text = pr_globals.owner_text
	 
	INPUT BY NAME 
	pr_defaults.quote_date, 
	pr_defaults.ship_date, 
	pr_defaults.paydetl_flag, 
	pr_defaults.owner_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11g","inp-quote_date-1") -- alch kd-501 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_defaults.quote_date IS NULL THEN 
					LET pr_defaults.quote_date = today 
				END IF 
				IF pr_defaults.ship_date IS NULL THEN 
					LET pr_defaults.ship_date = today 
				END IF 
				IF pr_defaults.ship_date < pr_defaults.quote_date THEN 
					LET pr_defaults.ship_date = pr_defaults.quote_date 
					LET msgresp = kandoomsg("E",9090,"") 	#9090 Delivery date cannot preceed ORDER date
					NEXT FIELD quote_date 
				END IF 
				IF pr_defaults.paydetl_flag = no_flag 
				AND pr_globals.paydetl_flag = yes_flag THEN 
					LET msgresp = kandoomsg("E",7037,"") 	#7037 Warnin' all term,taxes,conds willbe cust VALUES
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW q125 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET pr_globals.quote_date = pr_defaults.quote_date 
		LET pr_globals.ship_date = pr_defaults.ship_date 
		LET pr_globals.def_paydetl_flag = pr_defaults.paydetl_flag 
		LET pr_globals.owner_text = pr_defaults.owner_text 
	END IF 
END FUNCTION 
