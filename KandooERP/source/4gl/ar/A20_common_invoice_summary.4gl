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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl" 
########################################################################
# FUNCTION invoice_summary(p_mode)
#
#
########################################################################
FUNCTION invoice_summary(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_save_carr_code LIKE invoicehead.carrier_code 
	DEFINE l_freight_amt LIKE invoicehead.freight_amt 
	DEFINE l_weight_qty LIKE product.weight_qty 
	DEFINE l_save_freight_ind LIKE customership.freight_ind 
	DEFINE l_query_text CHAR(200) 
	DEFINE l_ret SMALLINT
	
	LET l_query_text = 
		"SELECT part_code,sum(ship_qty)", 
		" FROM t_invoicedetl",
		" group by 1"

	IF p_mode = MODE_CLASSIC_ADD THEN 
		#------------------------------------
		#get shipping deatails including cost
		SELECT * INTO l_rec_customership.* 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		AND ship_code = glob_rec_invoicehead.ship_code 
		IF status = 0 THEN 
			LET glob_rec_invoicehead.carrier_code = l_rec_customership.carrier_code 
			LET glob_rec_invoicehead.ship1_text = l_rec_customership.ship1_text 
			LET glob_rec_invoicehead.ship2_text = l_rec_customership.ship2_text
			#------------------------
			#shipping / freight cost 
			LET glob_rec_invoicehead.freight_amt = calc_freight_charges(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_invoicehead.carrier_code, 
				l_rec_customership.freight_ind, 
				glob_rec_invoicehead.state_code, 
				glob_rec_invoicehead.country_code, 
				l_weight_qty
				) * glob_rec_invoicehead.conv_qty 
		END IF 

		#------------------------
		# Handling charges
		LET glob_rec_invoicehead.hand_amt = calc_handling_charges(glob_rec_kandoouser.cmpy_code,l_query_text) * glob_rec_invoicehead.conv_qty 

		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = glob_rec_invoicehead.term_code 

		#------------------------
		# Due Date & discount
		CALL get_due_and_discount_date(l_rec_term.*,glob_rec_invoicehead.inv_date) 
			RETURNING 
			glob_rec_invoicehead.due_date,	
			glob_rec_invoicehead.disc_date 

		LET glob_rec_invoicehead.disc_amt=	(glob_rec_invoicehead.total_amt*l_rec_term.disc_per/100) 
		LET glob_rec_invoicehead.ship_date = glob_rec_invoicehead.inv_date 
		LET glob_rec_invoicehead.prepaid_flag = "P" 
	END IF 

	MESSAGE kandoomsg2("A",1067,"") #A1067" Order Shipping & Summary Details - ESC TO Continue"

	DISPLAY glob_rec_invoicehead.cust_code TO cust_code 
	DISPLAY glob_rec_invoicehead.name_text TO name_text 

	CALL A21_invoicehead_calc_and_disp_summ() 

	INPUT 
		glob_rec_invoicehead.carrier_code, 
		l_rec_customership.freight_ind, 
		glob_rec_invoicehead.ship1_text, 
		glob_rec_invoicehead.ship2_text, 
		glob_rec_invoicehead.fob_text, 
		glob_rec_invoicehead.ship_date, 
		glob_rec_invoicehead.prepaid_flag, 
		glob_rec_invoicehead.com1_text, 
		glob_rec_invoicehead.com2_text, 
		glob_rec_invoicehead.hand_amt, 
		glob_rec_invoicehead.freight_amt, 
		glob_rec_invoicehead.due_date, 
		glob_rec_invoicehead.disc_date WITHOUT DEFAULTS 
	FROM
		carrier_code, 
		freight_ind, 
		ship1_text, 
		ship2_text, 
		fob_text, 
		ship_date, 
		prepaid_flag, 
		com1_text, 
		com2_text, 
		hand_amt, 
		freight_amt, 
		due_date, 
		disc_date ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A21e","inp-invoicehead") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NAV_BACKWARD"
			LET l_ret = NAV_BACKWARD
			RETURN l_ret

		ON ACTION (ACCEPT,"NAV_FORWARD")
			LET l_ret = NAV_FORWARD
			ACCEPT INPUT
			
		ON ACTION "LOOKUP" infield (carrier_code) 
			LET glob_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_invoicehead.carrier_code = glob_temp_text clipped 
				NEXT FIELD carrier_code 
			END IF 

		BEFORE FIELD carrier_code 
			LET l_save_carr_code = glob_rec_invoicehead.carrier_code 

		AFTER FIELD carrier_code 
			IF glob_rec_invoicehead.carrier_code IS NOT NULL THEN 
				SELECT * INTO l_rec_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = glob_rec_invoicehead.carrier_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("A",9042,"") 				#9042" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 

				IF l_save_carr_code != glob_rec_invoicehead.carrier_code OR l_save_carr_code IS NULL THEN 
					IF l_rec_carrier.charge_ind = 2 THEN 
						IF l_weight_qty = 0 THEN 
							SELECT sum(p.weight_qty * o.ship_qty ) 
							INTO l_weight_qty 
							FROM t_invoicedetl o, product p 
							WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND o.part_code = p.part_code 
							AND p.weight_qty IS NOT NULL 
						END IF 
					END IF 

					LET glob_rec_invoicehead.freight_amt = calc_freight_charges(
						glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.carrier_code, 
						l_rec_customership.freight_ind, 
						glob_rec_invoicehead.state_code, 
						glob_rec_invoicehead.country_code, 
						l_weight_qty) * glob_rec_invoicehead.conv_qty 

				END IF 

				DISPLAY l_rec_carrier.name_text TO carrier.name_text 

				CALL A21_invoicehead_calc_and_disp_summ() 
			END IF 

		BEFORE FIELD freight_ind 
			LET l_save_freight_ind = l_rec_customership.freight_ind 

		AFTER FIELD freight_ind 
			IF l_save_freight_ind != l_rec_customership.freight_ind	OR l_save_freight_ind IS NULL THEN 
				IF l_rec_carrier.charge_ind = 2 THEN 
					IF l_weight_qty = 0 THEN 
						SELECT sum(p.weight_qty * o.ship_qty ) 
						INTO l_weight_qty 
						FROM t_invoicedetl o, product p 
						WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND o.part_code = p.part_code 
						AND p.weight_qty IS NOT NULL 
					END IF 
				END IF 

				LET glob_rec_invoicehead.freight_amt = calc_freight_charges(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_invoicehead.carrier_code, 
					l_rec_customership.freight_ind, 
					glob_rec_invoicehead.state_code, 
					glob_rec_invoicehead.country_code, 
					l_weight_qty) * glob_rec_invoicehead.conv_qty 
				CALL A21_invoicehead_calc_and_disp_summ() 
			END IF 

		AFTER FIELD freight_amt 
			CALL A21_invoicehead_calc_and_disp_summ() 

			IF glob_rec_invoicehead.freight_amt < 0 THEN 
				ERROR kandoomsg2("U",9109,"") 			#9109 Negative VALUES NOT permitted
				NEXT FIELD freight_amt 
			END IF 

		AFTER FIELD hand_amt 
			CALL A21_invoicehead_calc_and_disp_summ() 
			IF glob_rec_invoicehead.hand_amt < 0 THEN 
				ERROR kandoomsg2("U",9109,"") 			#9109 Negative VALUES NOT permitted
				NEXT FIELD hand_amt 
			END IF 

		AFTER FIELD due_date 
			IF glob_rec_invoicehead.due_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102" Value must be entered"
				NEXT FIELD due_date 
			END IF 



	END INPUT 
	###################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret = NAV_CANCEL 
	END IF 
	
	RETURN l_ret
END FUNCTION 
########################################################################
# END FUNCTION invoice_summary(p_mode)
########################################################################


########################################################################
# FUNCTION A21_invoicehead_calc_and_disp_summ()
#
#
########################################################################
FUNCTION A21_invoicehead_calc_and_disp_summ() 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_invoicehead.tax_code 

	IF l_rec_tax.freight_per IS NULL THEN 
		LET l_rec_tax.freight_per = 0 
	END IF 

	IF l_rec_tax.hand_per IS NULL THEN 
		LET l_rec_tax.hand_per = 0 
	END IF 

	SELECT sum(ext_sale_amt), 
	sum(ext_tax_amt), 
	sum(line_total_amt) 
	INTO 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.total_amt 
	FROM t_invoicedetl 

	IF glob_rec_invoicehead.goods_amt IS NULL THEN 
		LET glob_rec_invoicehead.goods_amt = 0 
	END IF 

	IF glob_rec_invoicehead.tax_amt IS NULL THEN 
		LET glob_rec_invoicehead.tax_amt = 0 
	END IF 

	IF glob_rec_invoicehead.hand_amt IS NULL THEN 
		LET glob_rec_invoicehead.hand_amt = 0 
	ELSE 
		LET glob_rec_invoicehead.hand_tax_amt = l_rec_tax.hand_per*glob_rec_invoicehead.hand_amt/100 
	END IF 

	IF glob_rec_invoicehead.freight_amt IS NULL THEN 
		LET glob_rec_invoicehead.freight_amt = 0 
	ELSE 
		LET glob_rec_invoicehead.freight_tax_amt = (l_rec_tax.freight_per*glob_rec_invoicehead.freight_amt)/100 
	END IF 

	LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt 
		+ glob_rec_invoicehead.tax_amt 
		+ glob_rec_invoicehead.hand_amt 
		+ glob_rec_invoicehead.hand_tax_amt 
		+ glob_rec_invoicehead.freight_amt 
		+ glob_rec_invoicehead.freight_tax_amt 

	DISPLAY BY NAME 
		glob_rec_invoicehead.freight_amt, 
		glob_rec_invoicehead.hand_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.total_amt, 
		glob_rec_invoicehead.rev_num, 
		glob_rec_invoicehead.rev_date	attribute(yellow) 

	DISPLAY BY NAME glob_rec_invoicehead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

END FUNCTION 
########################################################################
# END FUNCTION A21_invoicehead_calc_and_disp_summ()
########################################################################