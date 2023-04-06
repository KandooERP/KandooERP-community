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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl" 
###########################################################################
# E11g - Sales Order Summary Information
###########################################################################

###########################################################################
# FUNCTION order_summary(p_mode)
#
# 
###########################################################################
FUNCTION order_summary(p_mode) 
	DEFINE p_mode char(4) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_save_carr_code LIKE orderhead.carrier_code 
	DEFINE l_save_freight LIKE orderhead.freight_amt 
	DEFINE l_save_hand LIKE orderhead.hand_amt 
	DEFINE l_freight_amt LIKE orderhead.freight_amt 
	DEFINE l_save_freight_ind LIKE orderhead.freight_ind 

	MESSAGE kandoomsg2("E",1027,"") #1027 Order Shipping & Summary Details - ESC TO Continue

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = glob_rec_orderhead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	DISPLAY 
		l_rec_customer.curr_amt, 
		l_rec_customer.over1_amt, 
		l_rec_customer.over30_amt, 
		l_rec_customer.over60_amt, 
		l_rec_customer.over90_amt, 
		l_rec_customer.bal_amt, 
		glob_rec_orderhead.hold_code 
	TO
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		hold_code 
	
	IF glob_rec_orderhead.carrier_code IS NULL THEN 
		SELECT 
			carrier_code, 
			freight_ind, 
			ship1_text, 
			ship2_text 
		INTO 
			glob_rec_orderhead.carrier_code, 
			glob_rec_orderhead.freight_ind, 
			glob_rec_orderhead.ship1_text, 
			glob_rec_orderhead.ship2_text 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_orderhead.cust_code 
		AND ship_code = glob_rec_orderhead.ship_code 
	END IF
	 
	IF glob_rec_orderhead.freight_ind IS NULL THEN 
		LET glob_rec_orderhead.freight_ind = "1" 
	END IF 

	CALL E11_orderhead_disp_summ() 

	INPUT BY NAME 
		glob_rec_orderhead.carrier_code, 
		glob_rec_orderhead.fob_text, 
		glob_rec_orderhead.freight_ind, 
		glob_rec_orderhead.delivery_ind, 
		glob_rec_orderhead.ship_date, 
		glob_rec_orderhead.freight_amt, 
		glob_rec_orderhead.hand_amt, 
		glob_rec_orderhead.ship1_text, 
		glob_rec_orderhead.ship2_text, 
		glob_rec_orderhead.com1_text, 
		glob_rec_orderhead.com2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11g","input-glob_rec_orderhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "DETAILS" --ON KEY (f5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) --customer details / customer invoice submenu 

		ON ACTION "LOOKUP" infield(carrier_code)  
			LET glob_temp_text = "state_code =\"",glob_rec_orderhead.state_code,"\"" 
			LET glob_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,glob_temp_text) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_orderhead.carrier_code = glob_temp_text clipped 
				NEXT FIELD carrier_code 
			END IF 
 

		BEFORE FIELD carrier_code 
			LET l_save_freight = glob_rec_orderhead.freight_amt 
			IF l_save_freight IS NULL THEN 
				LET l_save_freight = 0 
			END IF 

			LET l_save_hand = glob_rec_orderhead.hand_amt 
			IF l_save_hand IS NULL THEN 
				LET l_save_hand = 0 
			END IF 

			IF glob_rec_orderhead.carrier_code IS NOT NULL THEN 
				IF p_mode = "ADD" THEN 
					SELECT name_text, charge_ind 
					INTO l_rec_carrier.name_text, l_rec_carrier.charge_ind 
					FROM carrier 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND carrier_code = glob_rec_orderhead.carrier_code 
					IF sqlca.sqlcode = 0 THEN 
						DISPLAY BY NAME l_rec_carrier.name_text 

						#-------------------------------------------
						# No country on ORDER so use customer country
						SELECT country_code INTO l_rec_carrier.country_code 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						#-------------------------------------------
						SELECT unique 1 FROM t_orderdetl 
						WHERE inv_qty != 0 
						IF status = NOTFOUND THEN 
							SELECT freight_amt 
							INTO glob_rec_orderhead.freight_amt 
							FROM carriercost 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND carrier_code = glob_rec_orderhead.carrier_code 
							AND state_code = glob_rec_orderhead.state_code 
							AND country_code = l_rec_carrier.country_code 
							AND freight_ind = glob_rec_orderhead.freight_ind 
							IF sqlca.sqlcode = 0 THEN 
								IF l_rec_carrier.charge_ind = 2 THEN 
									SELECT sum(p.weight_qty*o.order_qty) 
									INTO l_freight_amt 
									FROM t_orderdetl o, product p 
									WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND o.part_code = p.part_code 
									AND o.trade_in_flag = "N" 
									AND o.status_ind in ("0","2") 
									AND p.weight_qty IS NOT NULL 
									IF glob_rec_orderhead.freight_amt = 0 THEN 
										IF l_freight_amt IS NOT NULL THEN 
											LET glob_rec_orderhead.freight_amt = l_freight_amt * 
											glob_rec_orderhead.freight_amt 
										ELSE 
											LET glob_rec_orderhead.freight_amt = 0 
										END IF 
									END IF 
								END IF 
								CALL E11_orderhead_disp_summ() 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 

			LET l_save_carr_code = glob_rec_orderhead.carrier_code 

		AFTER FIELD carrier_code 
			IF glob_rec_orderhead.carrier_code IS NULL THEN 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_orderhead.ware_code 
				AND connote_flag = "Y" 
				IF status = 0 THEN 
					ERROR kandoomsg2("E",9088,"") 					#9088" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 
			ELSE 
				SELECT * INTO l_rec_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = glob_rec_orderhead.carrier_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9088,"") 	#9088" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 

				IF l_save_carr_code != glob_rec_orderhead.carrier_code 
				OR l_save_carr_code IS NULL THEN 
					CLEAR name_text 
					SELECT * INTO l_rec_carrier.* 
					FROM carrier 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND carrier_code = glob_rec_orderhead.carrier_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9088,"") 	#9088" Carrier does NOT exist - Try Window"
						NEXT FIELD carrier_code 
					ELSE 
						
						#-------------------------------------------
						# No country on ORDER so use customer country
						SELECT country_code INTO l_rec_carrier.country_code 
						FROM customer 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						#-------------------------------------------

						DISPLAY BY NAME l_rec_carrier.name_text 

						SELECT unique 1 FROM t_orderdetl 
						WHERE inv_qty != 0 

						IF status = NOTFOUND THEN 
							SELECT freight_amt 
							INTO glob_rec_orderhead.freight_amt 
							FROM carriercost 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND carrier_code = l_rec_carrier.carrier_code 
							AND state_code = glob_rec_orderhead.state_code 
							AND country_code = l_rec_carrier.country_code 
							AND freight_ind = glob_rec_orderhead.freight_ind 
							IF sqlca.sqlcode = 0 THEN 
								IF l_rec_carrier.charge_ind = 2 THEN 
									SELECT sum(p.weight_qty * o.order_qty ) 
									INTO l_freight_amt 
									FROM t_orderdetl o, product p 
									WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND o.part_code = p.part_code 
									AND o.trade_in_flag = "N" 
									AND o.status_ind = "0" 
									AND p.weight_qty IS NOT NULL 

									IF glob_rec_orderhead.freight_amt = 0 THEN 
										IF l_freight_amt IS NOT NULL THEN 
											LET glob_rec_orderhead.freight_amt = l_freight_amt * 
											glob_rec_orderhead.freight_amt 
										ELSE 
											LET glob_rec_orderhead.freight_amt = 0 
										END IF 
									END IF 

								END IF 

								CALL E11_orderhead_disp_summ() 

							END IF 
						END IF 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD freight_ind 
			LET l_save_freight_ind = glob_rec_orderhead.freight_ind 
			
		AFTER FIELD freight_ind
			IF l_save_freight_ind != glob_rec_orderhead.freight_ind THEN 
				
				#-------------------------------------------
				# No country on ORDER so use customer country
				SELECT country_code INTO l_rec_carrier.country_code 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_orderhead.cust_code 
				#-------------------------------------------

				SELECT unique 1 FROM t_orderdetl 
				WHERE inv_qty != 0
				 
				IF status = NOTFOUND THEN 
					SELECT freight_amt 
					INTO glob_rec_orderhead.freight_amt 
					FROM carriercost 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND carrier_code = glob_rec_orderhead.carrier_code 
					AND state_code = glob_rec_orderhead.state_code 
					AND country_code = l_rec_carrier.country_code 
					AND freight_ind = glob_rec_orderhead.freight_ind 
					IF sqlca.sqlcode = NOTFOUND THEN 
						IF glob_rec_orderhead.carrier_code IS NOT NULL THEN 
							ERROR kandoomsg2("E",9091,"") 						#9091 Automatic Freight calculation failed
						END IF 
					ELSE 
						IF l_rec_carrier.charge_ind = 2 THEN 
							SELECT sum(p.weight_qty * o.order_qty ) 
							INTO l_freight_amt 
							FROM t_orderdetl o, product p 
							WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND o.part_code = p.part_code 
							AND o.status_ind = "0" 
							AND o.trade_in_flag = "N" 
							AND p.weight_qty IS NOT NULL 
							IF l_freight_amt IS NOT NULL THEN 
								LET glob_rec_orderhead.freight_amt = l_freight_amt * 
								glob_rec_orderhead.freight_amt 
							ELSE 
								LET glob_rec_orderhead.freight_amt = 0 
							END IF 
						END IF 
						CALL E11_orderhead_disp_summ() 
					END IF 
				END IF 
			END IF 

		AFTER FIELD ship_date 
			IF glob_rec_orderhead.ship_date IS NULL THEN 
				LET glob_rec_orderhead.ship_date = glob_rec_orderhead.order_date 
				DISPLAY BY NAME glob_rec_orderhead.ship_date 

			ELSE 
				IF glob_rec_orderhead.ship_date < glob_rec_orderhead.order_date THEN 
					LET glob_rec_orderhead.ship_date = glob_rec_orderhead.order_date 
					ERROR kandoomsg2("E",9090,"") 				#9090 Delivery date cannot preceed ORDER date
					NEXT FIELD ship_date 
				END IF 
			END IF 

		AFTER FIELD freight_amt 
			IF glob_rec_orderhead.freight_amt IS NULL THEN 
				LET glob_rec_orderhead.freight_amt = l_save_freight 
			END IF 

			IF glob_rec_orderhead.freight_amt != l_save_freight AND glob_rec_orderhead.freight_inv_amt > glob_rec_orderhead.freight_amt THEN 
				ERROR kandoomsg2("E",9251,glob_rec_orderhead.freight_inv_amt) 			#9251 cannot reduce freight beyond $xx invoiced
				NEXT FIELD freight_amt 
			END IF 
			CALL E11_orderhead_disp_summ() 

		AFTER FIELD hand_amt 
			IF glob_rec_orderhead.hand_amt IS NULL THEN 
				LET glob_rec_orderhead.hand_amt = l_save_hand 
			END IF 
			IF glob_rec_orderhead.hand_amt != l_save_hand AND glob_rec_orderhead.hand_inv_amt > glob_rec_orderhead.hand_amt THEN 
				ERROR kandoomsg2("E",9252,glob_rec_orderhead.hand_inv_amt) 		#9152 cannot reduce hand beyond $xx invoiced
				NEXT FIELD hand_amt 
			END IF 
			CALL E11_orderhead_disp_summ() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION order_summary(p_mode)
###########################################################################


###########################################################################
# FUNCTION E11_orderhead_disp_summ() 
#
#
###########################################################################
FUNCTION E11_orderhead_disp_summ() 
	DEFINE l_non_inv_amt LIKE orderhead.total_amt
	DEFINE l_sub_total_amt LIKE orderhead.total_amt 
	DEFINE l_gross_amt LIKE orderhead.total_amt 
	DEFINE l_tottax_amt LIKE orderhead.total_amt 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	SELECT * 
	INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_orderhead.tax_code 

	IF l_rec_tax.freight_per IS NULL THEN 
		LET l_rec_tax.freight_per = 0 
	END IF 

	IF l_rec_tax.hand_per IS NULL THEN 
		LET l_rec_tax.hand_per = 0 
	END IF 

	SELECT sum(list_price_amt*order_qty), 
	sum(ext_price_amt), 
	sum(ext_tax_amt), 
	sum(line_tot_amt) 
	INTO l_gross_amt, 
	glob_rec_orderhead.goods_amt, 
	glob_rec_orderhead.tax_amt, 
	glob_rec_orderhead.total_amt 
	FROM t_orderdetl 

	IF l_gross_amt IS NULL THEN 
		LET l_gross_amt = 0 
	END IF 

	IF glob_rec_orderhead.goods_amt IS NULL THEN 
		LET glob_rec_orderhead.goods_amt = 0 
	END IF 

	IF glob_rec_orderhead.tax_amt IS NULL THEN 
		LET glob_rec_orderhead.tax_amt = 0 
	END IF 

	LET glob_rec_orderhead.disc_amt = l_gross_amt - glob_rec_orderhead.goods_amt 

	IF glob_rec_orderhead.hand_amt IS NULL THEN 
		LET glob_rec_orderhead.hand_amt = 0 
	ELSE 
		LET glob_rec_orderhead.hand_tax_amt = l_rec_tax.hand_per*glob_rec_orderhead.hand_amt/100 
	END IF 

	IF glob_rec_orderhead.freight_amt IS NULL THEN 
		LET glob_rec_orderhead.freight_amt = 0 
	ELSE 
		LET glob_rec_orderhead.freight_tax_amt = (l_rec_tax.freight_per*glob_rec_orderhead.freight_amt)/100 
	END IF 

	LET l_non_inv_amt = glob_rec_orderhead.hand_amt + glob_rec_orderhead.freight_amt 
	
	LET l_tottax_amt = glob_rec_orderhead.tax_amt	+ glob_rec_orderhead.hand_tax_amt	+ glob_rec_orderhead.freight_tax_amt 
	
	LET glob_rec_orderhead.total_amt = glob_rec_orderhead.goods_amt 
	+ glob_rec_orderhead.tax_amt 
	+ glob_rec_orderhead.hand_amt 
	+ glob_rec_orderhead.hand_tax_amt 
	+ glob_rec_orderhead.freight_amt 
	+ glob_rec_orderhead.freight_tax_amt 
	
	LET l_sub_total_amt = glob_rec_orderhead.total_amt - l_tottax_amt 
	
	DISPLAY glob_rec_orderhead.freight_amt TO freight_amt	attribute(yellow)
	DISPLAY glob_rec_orderhead.hand_amt TO hand_amt	attribute(yellow)
	DISPLAY l_gross_amt TO goods_amt attribute(yellow)
	DISPLAY glob_rec_orderhead.disc_amt TO disc_amt attribute(yellow)  
	DISPLAY l_sub_total_amt TO sub_total_amt attribute(yellow)  
	DISPLAY l_tottax_amt TO tax_amt	attribute(yellow)
	DISPLAY l_non_inv_amt TO non_inv_amt attribute(yellow) 
	DISPLAY glob_rec_orderhead.total_amt TO total_amt attribute(yellow)
 
END FUNCTION 
###########################################################################
# END FUNCTION E11_orderhead_disp_summ()
###########################################################################


###########################################################################
# FUNCTION enter_hold() 
#
#
###########################################################################
FUNCTION enter_hold() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_orderlog RECORD LIKE orderlog.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_overdue_amt LIKE customer.bal_amt 
	DEFINE l_cust_hold_code LIKE customer.hold_code 
	DEFINE l_prev_hold_code LIKE orderhead.hold_code 
	DEFINE l_cust_reason_text LIKE holdreas.reason_text 

	OPEN WINDOW E105 with FORM "E105" 
	 CALL windecoration_e("E105") -- albo kd-755 
	ERROR kandoomsg2("E",1013,"") #1013 Sales Order Hold Code

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = glob_rec_orderhead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF l_rec_customer.hold_code IS NOT NULL THEN 
		LET l_cust_hold_code = l_rec_customer.hold_code 
		SELECT reason_text INTO l_cust_reason_text FROM holdreas 
		WHERE hold_code = l_cust_hold_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		DISPLAY l_cust_hold_code TO cust_hold_code
		DISPLAY l_cust_reason_text TO cust_reason_text

	END IF 

	LET l_overdue_amt = l_rec_customer.bal_amt - l_rec_customer.curr_amt 
	IF l_overdue_amt < 0 THEN 
		LET l_overdue_amt = 0 
	END IF 

	DISPLAY l_overdue_amt TO overdue_amt

	LET l_rec_holdreas.hold_code = glob_rec_orderhead.hold_code 

	DISPLAY l_rec_holdreas.hold_code TO hold_code 

	LET l_prev_hold_code = l_rec_holdreas.hold_code 
	INPUT BY NAME l_rec_holdreas.hold_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11g","input-l_rec_holdreas-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" 
			LET glob_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_holdreas.hold_code = glob_temp_text 
			END IF 
			NEXT FIELD hold_code 

		BEFORE FIELD hold_code 
			SELECT reason_text INTO l_rec_holdreas.reason_text FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = l_rec_holdreas.hold_code 
			DISPLAY BY NAME l_rec_holdreas.reason_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_holdreas.hold_code IS NOT NULL THEN 
					SELECT unique 1 FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = l_rec_holdreas.hold_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9045,"") 		#9045" Sales ORDER hold code NOT found"
						NEXT FIELD hold_code 
					END IF 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW E105
	 
	IF l_prev_hold_code != l_rec_holdreas.hold_code 
	OR (l_prev_hold_code IS NULL AND l_rec_holdreas.hold_code IS NOT null) 
	OR (l_rec_holdreas.hold_code IS NULL AND l_prev_hold_code IS NOT null) THEN 
		LET l_rec_orderlog.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_orderlog.order_num = NULL 
		LET l_rec_orderlog.amend_date = today 
		LET l_rec_orderlog.amend_time = time 
		LET l_rec_orderlog.amend_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_orderlog.event_text = "26" 
		LET l_rec_orderlog.prev_text = l_prev_hold_code 
		LET l_rec_orderlog.curr_text = l_rec_holdreas.hold_code 
		INSERT INTO t_orderlog VALUES (l_rec_orderlog.*) 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET glob_rec_orderhead.hold_code = l_rec_holdreas.hold_code 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_hold()
###########################################################################


###########################################################################
# FUNCTION enter_defaults() 
#
#
###########################################################################
FUNCTION enter_defaults() 
	DEFINE l_rec_defaults RECORD 
		order_date DATE, 
		ship_date DATE, 
		suppl_flag char(1), 
		paydetl_flag char(1), 
		complete_flag char(1), 
		owner_text char(8) 
	END RECORD 

	OPEN WINDOW E102 with FORM "E102" 
	 CALL windecoration_e("E102") -- albo kd-755
 
	ERROR kandoomsg2("E",1028,"") #1028 Sales Order Hold Code
	LET l_rec_defaults.order_date = glob_rec_sales_order_parameter.order_date 
	LET l_rec_defaults.ship_date = glob_rec_sales_order_parameter.ship_date 
	LET l_rec_defaults.suppl_flag = glob_rec_sales_order_parameter.def_suppl_flag 
	LET l_rec_defaults.paydetl_flag = glob_rec_sales_order_parameter.def_paydetl_flag 
	LET l_rec_defaults.complete_flag = glob_rec_sales_order_parameter.complete_flag 
	LET l_rec_defaults.owner_text = glob_rec_sales_order_parameter.owner_text 

	INPUT BY NAME l_rec_defaults.order_date, 
	l_rec_defaults.ship_date, 
	l_rec_defaults.suppl_flag, 
	l_rec_defaults.paydetl_flag, 
	l_rec_defaults.complete_flag, 
	l_rec_defaults.owner_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11g","input-l_rec_defaults-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF l_rec_defaults.order_date IS NULL THEN 
					LET l_rec_defaults.order_date = today 
				END IF 

				IF l_rec_defaults.ship_date IS NULL THEN 
					LET l_rec_defaults.ship_date = today 
				END IF 

				IF l_rec_defaults.ship_date < l_rec_defaults.order_date THEN 
					LET l_rec_defaults.ship_date = l_rec_defaults.order_date 
					ERROR kandoomsg2("E",9090,"") 			#9090 Delivery date cannot preceed ORDER date
					NEXT FIELD order_date 
				END IF 

				IF l_rec_defaults.paydetl_flag = glob_no_flag 
				AND glob_rec_sales_order_parameter.paydetl_flag = glob_yes_flag THEN 
					ERROR kandoomsg2("E",7037,"") 		#7037 Warnin' all term,taxes,conds willbe cust VALUES
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW E102 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		LET glob_rec_sales_order_parameter.order_date = l_rec_defaults.order_date 
		LET glob_rec_sales_order_parameter.ship_date = l_rec_defaults.ship_date 
		LET glob_rec_sales_order_parameter.def_suppl_flag = l_rec_defaults.suppl_flag 
		LET glob_rec_sales_order_parameter.def_paydetl_flag = l_rec_defaults.paydetl_flag 
		LET glob_rec_sales_order_parameter.complete_flag = l_rec_defaults.complete_flag 
		LET glob_rec_sales_order_parameter.owner_text = l_rec_defaults.owner_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_defaults()
###########################################################################


###########################################################################
# FUNCTION backorder(p_cust_code) 
#
#
###########################################################################
FUNCTION backorder(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_arr_rec_backorder DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		order_num LIKE orderhead.order_num, 
		order_date LIKE orderhead.order_date, 
		back_amt LIKE orderhead.total_amt, 
		sched_amt LIKE orderhead.total_amt, 
		onhand_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	DECLARE c_orderhead cursor FOR 
	SELECT order_num, 
	order_date 
	FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_cust_code 
	AND order_num != glob_rec_orderhead.order_num 
	AND order_date <= today 
	AND status_ind != "C" 
	LET l_idx = 1 

	FOREACH c_orderhead INTO l_arr_rec_backorder[l_idx].order_num,	l_arr_rec_backorder[l_idx].order_date 
		SELECT sum(back_qty*unit_price_amt), 
		sum(sched_qty*unit_price_amt) 
		INTO l_arr_rec_backorder[l_idx].back_amt,	l_arr_rec_backorder[l_idx].sched_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = l_arr_rec_backorder[l_idx].order_num 

		IF l_arr_rec_backorder[l_idx].back_amt IS NULL THEN 
			LET l_arr_rec_backorder[l_idx].back_amt = 0 
		END IF 

		IF l_arr_rec_backorder[l_idx].sched_amt IS NULL THEN 
			LET l_arr_rec_backorder[l_idx].sched_amt = 0 
		END IF 

		IF l_arr_rec_backorder[l_idx].back_amt > 0 OR l_arr_rec_backorder[l_idx].sched_amt > 0 THEN 
			SELECT unique 1 FROM orderdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_arr_rec_backorder[l_idx].order_num 
			AND back_qty > 0 
			AND exists (select 1 FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = orderdetl.part_code 
			AND ware_code = orderdetl.ware_code 
			AND (onhand_qty - reserved_qty) > orderdetl.back_qty) 
			IF sqlca.sqlcode = 0 THEN 
				LET l_arr_rec_backorder[l_idx].onhand_flag = "*" 
			ELSE 
				LET l_arr_rec_backorder[l_idx].onhand_flag = NULL 
			END IF 
			LET l_idx = l_idx + 1 
			IF l_idx = 100 THEN 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH
	 
	MESSAGE kandoomsg2("E",1029,"") #1029 RETURN TO Release Backorders - ESC TO Continue
 
	DISPLAY ARRAY l_arr_rec_backorder TO sr_backorder.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E11g","input-l_arr_rec_backorder-1") -- albo kd-502
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_backorder.getSize()) 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD order_num
			IF (l_idx > 0) AND (l_arr_rec_backorder.getSize() > 0) THEN  
				IF l_arr_rec_backorder[l_idx].onhand_flag = "*" THEN 
					ERROR kandoomsg2("E",1005,"") 		#1005 Updating Database - Please Wait
	
					CALL release_stock(l_arr_rec_backorder[l_idx].order_num) 
	
					SELECT sum(back_qty*unit_price_amt), sum(sched_qty*unit_price_amt) 
					INTO l_arr_rec_backorder[l_idx].back_amt, l_arr_rec_backorder[l_idx].sched_amt 
					FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_arr_rec_backorder[l_idx].order_num 
	
					IF l_arr_rec_backorder[l_idx].back_amt IS NULL THEN 
						LET l_arr_rec_backorder[l_idx].back_amt = 0 
					END IF 
	
					IF l_arr_rec_backorder[l_idx].sched_amt IS NULL THEN 
						LET l_arr_rec_backorder[l_idx].sched_amt = 0 
					END IF 
					LET l_arr_rec_backorder[l_idx].onhand_flag = NULL 
	
				END IF 
			END IF

		BEFORE ROW 
			LET l_idx = arr_curr()
			
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
###########################################################################
# END FUNCTION backorder(p_cust_code)
###########################################################################


###########################################################################
# FUNCTION release_stock(p_order_num) 
#
#
###########################################################################
FUNCTION release_stock(p_order_num) 
	DEFINE p_order_num LIKE orderhead.order_num 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_err_message char(60) 
	DEFINE l_err_continue char(1) 

	CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,p_order_num,30,"","") 
	DECLARE c_orderdetl cursor with hold FOR 
	SELECT * 
	FROM orderdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = p_order_num 
	AND back_qty > 0 
	ORDER BY back_qty 

	FOREACH c_orderdetl INTO l_rec_orderdetl.* 
		GOTO bypass 
		LABEL recovery: 
		LET l_err_continue = error_recover(l_err_message, status) 
		IF l_err_continue != "Y" THEN 
			EXIT FOREACH 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 

			DECLARE c_prodstatus cursor FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_orderdetl.ware_code 
			AND part_code = l_rec_orderdetl.part_code 
			AND (onhand_qty - reserved_qty) >= l_rec_orderdetl.back_qty 
			FOR UPDATE 
			OPEN c_prodstatus 
			FETCH c_prodstatus 
			IF sqlca.sqlcode = 0 THEN 
				LET l_err_message = "E11 - Backorder release - UPDATE ordetl" 
				UPDATE orderdetl 
				SET back_qty = 0, 
				sched_qty = sched_qty + l_rec_orderdetl.back_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rec_orderdetl.order_num 
				AND line_num = l_rec_orderdetl.line_num 
				LET l_err_message = "O34_C - Prodstatus Update " 
				UPDATE prodstatus 
				SET reserved_qty = reserved_qty + l_rec_orderdetl.back_qty, 
				back_qty = back_qty - l_rec_orderdetl.back_qty 
				WHERE CURRENT OF c_prodstatus 
			END IF 

		COMMIT WORK 

	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION release_stock(p_order_num)
###########################################################################