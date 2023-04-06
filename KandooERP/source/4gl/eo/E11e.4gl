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
# Requires
# common/dispgpfunc.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_prodstatus RECORD LIKE prodstatus.* 
DEFINE modu_error_ind INTEGER 
###########################################################################
# E11e -  Line Item Detailed Entry
###########################################################################

###########################################################################
# FUNCTION lineitem_entry(p_rec_orderdetl) 
#
# E11e -  Line Item Detailed Entry
###########################################################################
FUNCTION lineitem_entry(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_dummy char(15)
	DEFINE l_horizontal_code char(15)
	DEFINE l_suppl_flag char(1) 
	DEFINE l_errmsg char(60) 
	DEFINE l_temp_amt FLOAT 
	DEFINE l_valid_ind SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 

	LET l_rec_orderdetl.* = p_rec_orderdetl.*
	 
	## take copy of RECORD TO reinstate in CASE of back out
	OPEN WINDOW E115 with FORM "E115" 
	 CALL windecoration_e("E115") -- albo kd-755 
	MESSAGE kandoomsg2("E",1026,"") #1026 F5 Cust Inquiry - F8 Product Inquiry - ESC TO Continue

	CALL display_line(p_rec_orderdetl.*)
	 
	LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,TRUE) 
	IF p_rec_orderdetl.status_ind = "1" THEN 
		LET l_suppl_flag = glob_yes_flag 
	ELSE 
		LET l_suppl_flag = glob_no_flag 
	END IF 
	
	INPUT 
		p_rec_orderdetl.part_code, 
		p_rec_orderdetl.desc_text, 
		l_suppl_flag, 
		p_rec_orderdetl.sold_qty, 
		p_rec_orderdetl.bonus_qty, 
		p_rec_orderdetl.order_qty, 
		p_rec_orderdetl.sched_qty, 
		p_rec_orderdetl.back_qty, 
		p_rec_orderdetl.inv_qty, 
		p_rec_orderdetl.level_ind, 
		p_rec_orderdetl.disc_allow_flag, 
		p_rec_orderdetl.disc_per, 
		p_rec_orderdetl.unit_price_amt, 
		p_rec_orderdetl.unit_tax_amt WITHOUT DEFAULTS 
	FROM
		part_code, 
		desc_text, 
		suppl_flag, 
		sold_qty, 
		bonus_qty, 
		order_qty, 
		sched_qty, 
		back_qty, 
		inv_qty, 
		level_ind, 
		disc_allow_flag, 
		disc_per, 
		unit_price_amt, 
		unit_tax_amt ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11e","input-p_rec_orderdetl-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(part_code)  
				LET glob_temp_text= "status_ind!='3' AND part_code =", 
				"(SELECT part_code FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND ware_code='",p_rec_orderdetl.ware_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND status_ind!='3')" 
				IF p_rec_orderdetl.offer_code IS NOT NULL THEN 
					LET glob_temp_text=glob_temp_text clipped," AND exists ", 
					"(SELECT 1 FROM offerprod ", 
					"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND offer_code='",p_rec_orderdetl.offer_code,"' ", 
					"AND maingrp_code=product.maingrp_code ", 
					"AND (prodgrp_code =product.prodgrp_code ", 
					"OR prodgrp_code IS null)", 
					"AND (part_code =product.part_code ", 
					"OR part_code IS null))" 
				END IF 
				LET glob_temp_text = show_part(glob_rec_kandoouser.cmpy_code,glob_temp_text) 
				IF glob_temp_text IS NOT NULL THEN 
					LET p_rec_orderdetl.part_code = glob_temp_text 
					NEXT FIELD part_code 
				END IF 


		ON KEY (control-e) 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_orderdetl.part_code 
			AND serial_flag = 'Y' 
			IF status <> NOTFOUND THEN 
				LET l_cnt = serial_count(p_rec_orderdetl.part_code, 
				glob_rec_orderhead.ware_code) 
				LET l_cnt = serial_input(p_rec_orderdetl.part_code, 
				glob_rec_orderhead.ware_code, 
				l_cnt) 
				IF l_cnt < 0 THEN 
					LET l_errmsg = 'unexpected ERROR in e11e. err=', l_cnt 
					CALL errorlog(l_errmsg) 
					LET l_errmsg = trim(l_errmsg), "\nExit Program"
					CALL fgl_winmessage("ERROR",l_errmsg,"ERROR") 					
					EXIT PROGRAM 
				ELSE 
					IF l_cnt > p_rec_orderdetl.sold_qty THEN 
						LET p_rec_orderdetl.sold_qty = l_cnt 
						CALL validate_field("sold_qty",p_rec_orderdetl.*) 
						RETURNING l_valid_ind,p_rec_orderdetl.* 
						IF l_valid_ind THEN 
							LET p_rec_orderdetl.required_qty 
							= calc_avail(p_rec_orderdetl.*,TRUE) 
						END IF 
						CALL display_line(p_rec_orderdetl.*) 
					END IF 
				END IF 
			END IF 

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				OPTIONS DELETE KEY f2 
				LET p_rec_orderdetl.desc_text =	sys_noter(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.desc_text) 
				OPTIONS DELETE KEY f36 
				NEXT FIELD desc_text 

		ON KEY (control-p) 
			CALL dispgpfunc(
				glob_rec_orderhead.currency_code, 
				p_rec_orderdetl.ext_cost_amt, 
				p_rec_orderdetl.ext_price_amt) 

		ON KEY (f5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) --customer details / customer invoice submenu 

		ON KEY (f8) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code) 

		BEFORE FIELD part_code 
			IF p_rec_orderdetl.inv_qty != 0 ## invoiced 
			OR p_rec_orderdetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD part_code 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = p_rec_orderdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = 0 THEN 
				CALL matrix_break_prod(
					glob_rec_kandoouser.cmpy_code, 
					l_rec_product.part_code, 
					l_rec_product.class_code, 0) 
				RETURNING 
					l_dummy, 
					l_horizontal_code, 
					l_dummy, 
					l_dummy 
				
				IF l_rec_product.serial_flag = "Y" 
				OR (l_horizontal_code IS NOT NULL 
				AND l_horizontal_code != " ") THEN 
					SELECT count(*) INTO l_cnt FROM t_orderdetl 
					WHERE part_code = p_rec_orderdetl.part_code 
					AND line_num <> p_rec_orderdetl.line_num 
					IF l_cnt > 0 THEN 
						IF l_rec_product.serial_flag = "Y" THEN 
							ERROR kandoomsg2("I",9292,"") 					#9292 Serial Products can only occur once.
						ELSE 
							ERROR kandoomsg2("E",9270,"") 			#9270 Matrix products can only be entered once.
						END IF 
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 
			
			IF p_rec_orderdetl.part_code IS NULL THEN 
				IF l_rec_orderdetl.part_code IS NOT NULL THEN 
					LET p_rec_orderdetl.acct_code = NULL 
				END IF 
				LET p_rec_orderdetl.status_ind = "3" 
				LET p_rec_orderdetl.cost_ind = "N" 
				LET p_rec_orderdetl.offer_code = NULL 
				LET p_rec_orderdetl.trade_in_flag = "N" 
				LET p_rec_orderdetl.required_qty=calc_avail(p_rec_orderdetl.*,TRUE) 
			ELSE 
				IF l_rec_orderdetl.part_code IS NULL THEN 
					IF glob_rec_sales_order_parameter.suppl_flag IS NULL OR 
					glob_rec_sales_order_parameter.suppl_flag = "N" THEN 
						LET p_rec_orderdetl.status_ind = "0" 
						LET l_suppl_flag = "N" 
					ELSE 
						LET p_rec_orderdetl.status_ind = "1" 
						LET l_suppl_flag = "Y" 
					END IF
					 
					DISPLAY p_rec_orderdetl.status_ind TO status_ind 
					DISPLAY l_suppl_flag TO suppl_flag  
					
				ELSE 
					IF l_rec_orderdetl.part_code != p_rec_orderdetl.part_code THEN 
						#----------------------------------------------
						# force change of lineinfo on change of partcode
						LET p_rec_orderdetl.order_qty = 0 
						LET p_rec_orderdetl.sold_qty = 0 
						LET p_rec_orderdetl.bonus_qty = 0 
						LET p_rec_orderdetl.sched_qty = 0 
						LET p_rec_orderdetl.back_qty = 0 
						LET p_rec_orderdetl.unit_price_amt = NULL 
						LET p_rec_orderdetl.desc_text = NULL 
					END IF 
				END IF 
				
				CALL validate_field("part_code",p_rec_orderdetl.*)	RETURNING l_valid_ind,p_rec_orderdetl.*
				 
				IF NOT l_valid_ind THEN 
					NEXT FIELD part_code 
				ELSE 
					LET p_rec_orderdetl.required_qty=calc_avail(p_rec_orderdetl.*,TRUE) 
				END IF 
			END IF
			 
		BEFORE FIELD desc_text 
			IF p_rec_orderdetl.part_code IS NOT NULL 
			AND NOT (p_rec_orderdetl.desc_text[1,3] = "###" 
			AND p_rec_orderdetl.desc_text[16,18] = "###") THEN 
				SELECT * INTO l_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_orderdetl.part_code 
				LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
				IF l_suppl_flag IS NULL THEN 
					LET l_suppl_flag = glob_rec_sales_order_parameter.suppl_flag 
				END IF 
			END IF 
			CALL display_line(p_rec_orderdetl.*)
			 
		BEFORE FIELD l_suppl_flag 
			IF p_rec_orderdetl.status_ind = "3" ## non-inventory 
			OR p_rec_orderdetl.inv_qty != 0 THEN ## invoiced 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF
			 
		AFTER FIELD l_suppl_flag 
			CASE 
				WHEN l_suppl_flag = "Y" 
					IF p_rec_orderdetl.status_ind != "1" THEN 
						IF p_rec_orderdetl.part_code IS NOT NULL 
						AND p_rec_orderdetl.ware_code != glob_rec_sales_order_parameter.supp_ware_code THEN 
							IF valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
							glob_rec_sales_order_parameter.supp_ware_code, 
							0,2,0,"","","") THEN 
								--                        OPEN WINDOW w1 AT 8,25 with 2 rows,40 columns  -- albo  KD-755
								--                           ATTRIBUTE(border)
								menu" Supplying warehouse" 
									BEFORE MENU 
										CALL publish_toolbar("kandoo","E11","menu-Supplying_Warehouse-1") -- albo kd-502 
									ON ACTION "WEB-HELP" -- albo kd-370 
										CALL onlinehelp(getmoduleid(),null) 
									COMMAND p_rec_orderdetl.ware_code 
										" Customer warehouse " 
										EXIT MENU 
									COMMAND glob_rec_sales_order_parameter.supp_ware_code 
										" Salesperson warehouse " 
										LET p_rec_orderdetl.ware_code = 
										glob_rec_sales_order_parameter.supp_ware_code 
										EXIT MENU 
									COMMAND KEY (control-w) 
										CALL kandoohelp("") 
								END MENU 

							ELSE 
								ERROR kandoomsg2("E",9080,"") 							#9080 Product NOT available AT ORDER warehouse"
								LET l_suppl_flag = glob_no_flag 
								NEXT FIELD l_suppl_flag 
							END IF 
						END IF 
						LET p_rec_orderdetl.status_ind = "1" 
						LET p_rec_orderdetl.cost_ind = "N" 
					END IF 

				WHEN l_suppl_flag = "N" 
					IF p_rec_orderdetl.status_ind = "1" THEN 
						## CALL valid part TO see IF product exists AT ORDER warehouse
						IF p_rec_orderdetl.part_code IS NULL 
						OR valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
						glob_rec_orderhead.ware_code, 
						0,2,0,"","","") THEN 
							LET p_rec_orderdetl.ware_code = glob_rec_orderhead.ware_code 
							LET p_rec_orderdetl.status_ind = "0" 
							LET p_rec_orderdetl.cost_ind = 
							permit_backordering(p_rec_orderdetl.ware_code, 
							p_rec_orderdetl.part_code) 
						ELSE 
							
							ERROR kandoomsg2("E",9080,"") #9080" Product NOT available AT ORDER Warehouse"
							LET l_suppl_flag = "Y" 
							NEXT FIELD l_suppl_flag 
						END IF 
					END IF 

				OTHERWISE 
					ERROR kandoomsg2("U",3,"") 
					LET l_suppl_flag = glob_rec_sales_order_parameter.suppl_flag 
					NEXT FIELD l_suppl_flag 

			END CASE #END CASE ------------------------------ 

			CALL validate_field("suppl_flag",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 

			IF l_valid_ind THEN 
				LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,TRUE) 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD l_suppl_flag 
			END IF 

		BEFORE FIELD sold_qty 
			IF p_rec_orderdetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD sold_qty 
			CALL validate_field("sold_qty",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				LET p_rec_orderdetl.required_qty=calc_avail(p_rec_orderdetl.*,TRUE) 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD sold_qty 
			END IF 
		BEFORE FIELD bonus_qty 
			IF glob_rec_orderhead.cond_code IS NULL 
			AND p_rec_orderdetl.offer_code IS NULL THEN 
				LET p_rec_orderdetl.bonus_qty = 0 
				LET l_rec_product.bonus_allow_flag = "N" 
			END IF 
			
			IF p_rec_orderdetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				IF p_rec_orderdetl.status_ind = "3" ## non-inventory 
				OR p_rec_orderdetl.trade_in_flag = "Y" ## trade-ins 
				OR l_rec_product.bonus_allow_flag = "N" THEN ## no bonus 
					LET p_rec_orderdetl.bonus_qty = 0 
					IF fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			END IF 

		AFTER FIELD bonus_qty 
			CALL validate_field("bonus_qty",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				CALL display_line(p_rec_orderdetl.*) 
				LET p_rec_orderdetl.required_qty=calc_avail(p_rec_orderdetl.*,TRUE) 
			ELSE 
				NEXT FIELD bonus_qty 
			END IF 

		BEFORE FIELD order_qty 
			IF p_rec_orderdetl.inv_qty = 0 
			AND p_rec_orderdetl.status_ind != "3" 
			AND p_rec_orderdetl.status_ind != "1" THEN 
				## Prompt TO sellup
				IF l_rec_product.stock_uom_code != l_rec_product.sell_uom_code 
				AND l_rec_product.stk_sel_con_qty > 1 THEN 
					LET i =(p_rec_orderdetl.order_qty/l_rec_product.stk_sel_con_qty)+0.5 
					LET j =(i * l_rec_product.stk_sel_con_qty) 
					IF p_rec_orderdetl.order_qty < j 
					AND p_rec_orderdetl.order_qty > (glob_rec_opparms.sellup_per/100)*j THEN 
						IF  kandoomsg("E",8014,j) = "Y" THEN 
							LET p_rec_orderdetl.sold_qty = p_rec_orderdetl.sold_qty + j  - p_rec_orderdetl.order_qty 
							NEXT FIELD sold_qty 
						END IF 
					END IF 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD previous 
			ELSE 
				NEXT FIELD NEXT 
			END IF 

		BEFORE FIELD sched_qty 
			IF p_rec_orderdetl.status_ind = "3" ## non-inventory 
			OR p_rec_orderdetl.status_ind = "1" ## pre-delivered 
			OR p_rec_orderdetl.trade_in_flag = "Y" THEN ## trade-ins 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD sched_qty 
			CALL validate_field("sched_qty",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD sched_qty 
			END IF 

		BEFORE FIELD back_qty 
			LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,TRUE) 
			IF p_rec_orderdetl.status_ind = "3" ## non-inventory 
			OR p_rec_orderdetl.status_ind = "1" ## pre-delivered 
			OR p_rec_orderdetl.trade_in_flag = "Y" ## trade-ins 
			OR p_rec_orderdetl.cost_ind = "N" THEN ## no backords 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD back_qty 
			CALL validate_field("back_qty",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD back_qty 
			END IF 

		BEFORE FIELD level_ind 
			LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,TRUE) 
			IF glob_rec_orderhead.cond_code IS NULL 
			AND p_rec_orderdetl.offer_code IS NULL 
			AND p_rec_orderdetl.trade_in_flag = "N" 
			AND p_rec_orderdetl.part_code IS NOT NULL THEN 
				LET glob_temp_text = p_rec_orderdetl.level_ind 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD level_ind 
			IF p_rec_orderdetl.level_ind IS NULL THEN 
				LET p_rec_orderdetl.level_ind = glob_rec_customer.inv_level_ind 
				NEXT FIELD level_ind 
			END IF 
			IF p_rec_orderdetl.level_ind != glob_temp_text clipped THEN 
				LET p_rec_orderdetl.unit_price_amt = 
				unit_price(p_rec_orderdetl.ware_code, 
				p_rec_orderdetl.part_code, 
				p_rec_orderdetl.level_ind) 
				CALL validate_field("unit_price_amt",p_rec_orderdetl.*) 
				RETURNING l_valid_ind,p_rec_orderdetl.* 
				IF l_valid_ind THEN 
					CALL display_line(p_rec_orderdetl.*) 
				ELSE 
					NEXT FIELD unit_price_amt 
				END IF 
			END IF 
			CALL display_line(p_rec_orderdetl.*) 

		BEFORE FIELD disc_per 
			IF p_rec_orderdetl.offer_code IS NOT NULL 
			OR p_rec_orderdetl.disc_allow_flag = glob_no_flag 
			OR p_rec_orderdetl.trade_in_flag = "Y" 
			OR p_rec_orderdetl.status_ind = "3" 
			OR p_rec_orderdetl.inv_qty != 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD disc_per 
			CALL validate_field("disc_per",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD disc_per 
			END IF 

		BEFORE FIELD unit_price_amt 
			IF p_rec_orderdetl.offer_code IS NOT NULL 
			OR p_rec_orderdetl.disc_allow_flag = glob_no_flag 
			OR p_rec_orderdetl.inv_qty != 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD unit_price_amt 
			CALL validate_field("unit_price_amt",p_rec_orderdetl.*) 
			RETURNING l_valid_ind,p_rec_orderdetl.* 
			IF l_valid_ind THEN 
				CALL display_line(p_rec_orderdetl.*) 
			ELSE 
				NEXT FIELD unit_price_amt 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_rec_orderdetl.status_ind = "3" AND p_rec_orderdetl.line_tot_amt > 0 THEN 
					LET p_rec_orderdetl.acct_code = enter_acct(p_rec_orderdetl.acct_code) 
					IF p_rec_orderdetl.acct_code IS NULL THEN 
						NEXT FIELD part_code 
					END IF 
				ELSE 
					CALL validate_field("sold_qty",p_rec_orderdetl.*) RETURNING l_valid_ind,p_rec_orderdetl.* 
					IF NOT l_valid_ind THEN 
						NEXT FIELD sold_qty 
					END IF 
					IF fgl_lastkey() != fgl_keyval("accept") THEN 
						IF kandoomsg("E",8006,"") = "N" THEN 		#8006 Line Entry Complete. (Y/N)?
							NEXT FIELD part_code 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW E115 
	
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 
		RETURN FALSE 
	ELSE 
		CALL db_t_orderdetl_update_line(p_rec_orderdetl.*) 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION lineitem_entry(p_rec_orderdetl) 
###########################################################################


###########################################################################
# FUNCTION display_line(p_rec_orderdetl) 
#
# 
###########################################################################
FUNCTION display_line(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_disc_flag char(1) ### auto-dosc calc TRUE/FALSE 

	DISPLAY glob_rec_orderhead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
	
	#------------------------------
	# mod of disc_per excludes line FROM autodisc calc
	IF p_rec_orderdetl.serial_qty THEN 
		LET l_disc_flag = "*" 
	ELSE 
		LET l_disc_flag = NULL 
	END IF 
	
	DISPLAY
		p_rec_orderdetl.part_code, 
		p_rec_orderdetl.desc_text, 
		p_rec_orderdetl.status_ind, 
		p_rec_orderdetl.uom_code, 
		p_rec_orderdetl.sold_qty, 
		p_rec_orderdetl.bonus_qty, 
		p_rec_orderdetl.order_qty, 
		p_rec_orderdetl.sched_qty, 
		p_rec_orderdetl.back_qty, 
		p_rec_orderdetl.inv_qty, 
		p_rec_orderdetl.conf_qty, 
		p_rec_orderdetl.disc_allow_flag, 
		l_disc_flag, 
		p_rec_orderdetl.level_ind, 
		p_rec_orderdetl.disc_per, 
		p_rec_orderdetl.list_price_amt, 
		p_rec_orderdetl.unit_price_amt, 
		p_rec_orderdetl.ext_price_amt, 
		p_rec_orderdetl.unit_tax_amt, 
		p_rec_orderdetl.ext_tax_amt, 
		p_rec_orderdetl.line_tot_amt 
	TO
		part_code, 
		desc_text, 
		status_ind, 
		uom_code, 
		sold_qty, 
		bonus_qty, 
		order_qty, 
		sched_qty, 
		back_qty, 
		inv_qty, 
		conf_qty, 
		disc_allow_flag, 
		disc_flag, 
		level_ind, 
		disc_per, 
		list_price_amt, 
		unit_price_amt, 
		ext_price_amt, 
		unit_tax_amt, 
		ext_tax_amt, 
		line_tot_amt 
	
END FUNCTION 
###########################################################################
# END FUNCTION display_line(p_rec_orderdetl) 
###########################################################################


###########################################################################
# FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind) 
#
#
###########################################################################
FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind) 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_part_code LIKE prodstatus.part_code 
	DEFINE p_level_ind LIKE customer.inv_level_ind 
	DEFINE l_price_amt LIKE orderdetl.unit_price_amt 
	DEFINE l_rate_per FLOAT 

	IF glob_rec_orderhead.currency_code = glob_rec_sales_order_parameter.base_curr_code THEN 
		LET l_rate_per = 1 
	ELSE 
		LET l_rate_per = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_orderhead.currency_code,
			glob_rec_orderhead.order_date,
			CASH_EXCHANGE_SELL) 
	END IF 
	
	CALL prod_price(glob_rec_kandoouser.cmpy_code,p_part_code,glob_rec_customer.cust_code, p_ware_code,1,today) 
	RETURNING l_price_amt,modu_error_ind 

	IF l_price_amt = 0 THEN 
		CALL prod_price(glob_rec_kandoouser.cmpy_code,p_part_code,glob_rec_customer.cust_code,p_ware_code,2,today) 
		RETURNING l_price_amt,modu_error_ind 

		IF l_price_amt <> 0 THEN 
			RETURN (l_price_amt * l_rate_per) 
		END IF 

	ELSE 
		RETURN (l_price_amt * l_rate_per) 
	END IF 

	SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = p_ware_code 
	AND part_code = p_part_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN 0 
	ELSE 
		CASE 
			WHEN p_level_ind = "1" RETURN (modu_rec_prodstatus.price1_amt*l_rate_per) 
			WHEN p_level_ind = "2" RETURN (modu_rec_prodstatus.price2_amt*l_rate_per) 
			WHEN p_level_ind = "3" RETURN (modu_rec_prodstatus.price3_amt*l_rate_per) 
			WHEN p_level_ind = "4" RETURN (modu_rec_prodstatus.price4_amt*l_rate_per) 
			WHEN p_level_ind = "5" RETURN (modu_rec_prodstatus.price5_amt*l_rate_per) 
			WHEN p_level_ind = "6" RETURN (modu_rec_prodstatus.price6_amt*l_rate_per) 
			WHEN p_level_ind = "7" RETURN (modu_rec_prodstatus.price7_amt*l_rate_per) 
			WHEN p_level_ind = "8" RETURN (modu_rec_prodstatus.price8_amt*l_rate_per) 
			WHEN p_level_ind = "9" RETURN (modu_rec_prodstatus.price9_amt*l_rate_per) 
			WHEN p_level_ind = "L" RETURN (modu_rec_prodstatus.list_amt*l_rate_per) 
			WHEN p_level_ind = "C" RETURN (modu_rec_prodstatus.wgted_cost_amt*l_rate_per) 
			OTHERWISE RETURN (modu_rec_prodstatus.list_amt*l_rate_per) 
		END CASE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind) 
###########################################################################


###########################################################################
# FUNCTION allocate_stock(p_rec_orderdetl,p_back_ind)
#
# Allocates quantity of stocked item TO sched,backorder & conf
###########################################################################
FUNCTION allocate_stock(p_rec_orderdetl,p_back_ind) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE p_back_ind INTEGER 

	LET p_rec_orderdetl.order_qty = p_rec_orderdetl.sold_qty + p_rec_orderdetl.bonus_qty 
	LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,FALSE) 
	IF glob_rec_opparms.cal_available_flag = "N" THEN 
		LET p_rec_orderdetl.required_qty = p_rec_orderdetl.required_qty + p_rec_orderdetl.sched_qty + p_rec_orderdetl.conf_qty 
	ELSE 
		LET p_rec_orderdetl.required_qty = p_rec_orderdetl.required_qty 
		+ p_rec_orderdetl.back_qty 
		+ p_rec_orderdetl.sched_qty 
		+ p_rec_orderdetl.conf_qty 
	END IF 
	IF p_rec_orderdetl.required_qty IS NOT NULL THEN 
		IF p_rec_orderdetl.sched_qty > 0 
		AND p_rec_orderdetl.sched_qty > p_rec_orderdetl.required_qty THEN 
			LET p_rec_orderdetl.required_qty = p_rec_orderdetl.sched_qty 
		END IF 
		IF p_rec_orderdetl.required_qty < 0 THEN 
			LET p_rec_orderdetl.required_qty = 0 
		END IF 
	END IF 

	CASE #CASE 1 ----------------------------------- 
		WHEN p_rec_orderdetl.status_ind = "1" 
			LET p_rec_orderdetl.sched_qty = 0 
			LET p_rec_orderdetl.back_qty = 0 
			LET p_rec_orderdetl.conf_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 

		WHEN p_rec_orderdetl.status_ind = "3" 
			LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
			LET p_rec_orderdetl.back_qty = 0 
			LET p_rec_orderdetl.conf_qty = 0 

		OTHERWISE 

			CASE #CASE 2 ------------------------------------
				WHEN (p_rec_orderdetl.required_qty IS null) 
					### Not Stocked
					LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty 
					- p_rec_orderdetl.inv_qty 
					LET p_rec_orderdetl.back_qty = 0 
					LET p_rec_orderdetl.conf_qty = 0 

				WHEN (p_rec_orderdetl.required_qty >= 
					(p_rec_orderdetl.order_qty-p_rec_orderdetl.inv_qty)) 
					### Stock Available
					IF p_rec_orderdetl.back_qty > 0 THEN 
						IF p_rec_orderdetl.back_qty > 
						(p_rec_orderdetl.order_qty-p_rec_orderdetl.inv_qty) THEN 
							LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
							LET p_rec_orderdetl.conf_qty = 0 
						END IF 
						LET p_rec_orderdetl.status_ind = "2" 
					ELSE 
						LET p_rec_orderdetl.back_qty = 0 
						LET p_rec_orderdetl.status_ind = "0" 
					END IF 
					LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty 
					- p_rec_orderdetl.inv_qty 
					- p_rec_orderdetl.back_qty 

				OTHERWISE 
					IF get_kandoooption_feature_state("EO","BA") THEN 
						IF p_rec_orderdetl.cost_ind = "Y" THEN 
							#Delay Back Order Validation
							LET p_rec_orderdetl.status_ind = "2" 
							LET p_rec_orderdetl.sched_qty = 0 
							LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
							LET p_rec_orderdetl.conf_qty = 0 
						ELSE 
							IF p_rec_orderdetl.sold_qty >= p_rec_orderdetl.inv_qty THEN 
								LET p_rec_orderdetl.sold_qty = p_rec_orderdetl.inv_qty 
								LET p_rec_orderdetl.bonus_qty = 0 
							ELSE 
								LET p_rec_orderdetl.bonus_qty = p_rec_orderdetl.inv_qty	- p_rec_orderdetl.sold_qty 
							END IF 

							LET p_rec_orderdetl.sched_qty = 0 
							LET p_rec_orderdetl.back_qty = 0 
							LET p_rec_orderdetl.status_ind = "4" 
							ERROR kandoomsg2("E",9086,"") 	#9086 Insufficent Stock Available - Back Orders Not Permit
						END IF 

					ELSE 

						### Stock Unavailable
						IF p_rec_orderdetl.cost_ind = "Y"	OR glob_rec_orderhead.ord_ind = '3' THEN 
							## (cost_ind used as backorder allowed flag)
							IF p_back_ind THEN 
								### DISPLAY backorder window

								ERROR kandoomsg2("E",1185,p_rec_orderdetl.part_code) 						#1185 Product ??? has insufficient stock
								MENU " Insufficent stock" 
									BEFORE MENU 
										CALL publish_toolbar("kandoo","E11","menu-Insufficent_Stock-1") -- albo kd-502 
										IF p_rec_orderdetl.required_qty <= 0 THEN 
											HIDE option "Partial" 
										END IF 

									ON ACTION "WEB-HELP" -- albo kd-370 
										CALL onlinehelp(getmoduleid(),null) 

									COMMAND "Backorder" " Place all required stock on backorder" 
										LET p_rec_orderdetl.status_ind = "2" 
										LET p_rec_orderdetl.sched_qty = 0 
										LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
										LET p_rec_orderdetl.conf_qty = 0 
										EXIT MENU 

									COMMAND "Partial" " Place unavailable stock on backorder" 
										LET p_rec_orderdetl.status_ind = "2" 
										LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.required_qty 
										LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty 
											- p_rec_orderdetl.inv_qty 
											- p_rec_orderdetl.sched_qty 
										LET p_rec_orderdetl.conf_qty = 0 
										EXIT MENU 

									COMMAND KEY("E",INTERRUPT)"Exit" " Cancel ORDER line" 
										LET p_rec_orderdetl.order_qty = p_rec_orderdetl.inv_qty 
										LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty 
										LET p_rec_orderdetl.sold_qty = 0 
										LET p_rec_orderdetl.bonus_qty = 0 
										LET p_rec_orderdetl.status_ind = "4" 
										EXIT MENU 

								END MENU 

							ELSE 
								LET p_rec_orderdetl.status_ind = "2" 
								LET p_rec_orderdetl.sched_qty = 0 
								LET p_rec_orderdetl.back_qty = 0 
								LET p_rec_orderdetl.conf_qty = 0 
								ERROR kandoomsg2("E",9087,"") 			#9087 Insufficent Stock Available
							END IF 

						ELSE 

							IF p_rec_orderdetl.sold_qty >= p_rec_orderdetl.inv_qty THEN 
								LET p_rec_orderdetl.sold_qty = p_rec_orderdetl.inv_qty 
								LET p_rec_orderdetl.bonus_qty = 0 
							ELSE 
								LET p_rec_orderdetl.bonus_qty = p_rec_orderdetl.inv_qty	- p_rec_orderdetl.sold_qty 
							END IF 

							LET p_rec_orderdetl.sched_qty = 0 
							LET p_rec_orderdetl.back_qty = 0 
							LET p_rec_orderdetl.status_ind = "4" 
							ERROR kandoomsg2("E",9086,"") 			#9086 Insufficent Stock Available - Back Orders Not Permit
						END IF 
					END IF 
			END CASE #END CASE 2 ----------------

	END CASE #END CASE 1 ------------------------

	RETURN p_rec_orderdetl.* 
END FUNCTION 
###########################################################################
# END FUNCTION calc_avail(p_rec_orderdetl,p_display_ind) 
###########################################################################


###########################################################################
# FUNCTION calc_avail(p_rec_orderdetl,p_display_ind) 
#
#
###########################################################################
FUNCTION calc_avail(p_rec_orderdetl,p_display_ind) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE p_display_ind SMALLINT 
	DEFINE l_oldback_qty SMALLINT  
	DEFINE l_oldres_qty SMALLINT  
	DEFINE l_cur_avail_qty SMALLINT  
	DEFINE l_fut_avail_qty LIKE prodstatus.onhand_qty 

	SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_orderdetl.part_code 
	AND ware_code = p_rec_orderdetl.ware_code 
	IF status = NOTFOUND THEN 
		IF p_display_ind THEN 
			LET modu_rec_prodstatus.ware_code = p_rec_orderdetl.ware_code 
			LET modu_rec_prodstatus.onhand_qty = 0 
			LET modu_rec_prodstatus.reserved_qty = 0 
			LET modu_rec_prodstatus.back_qty = 0 
			LET l_cur_avail_qty = 0 
			LET modu_rec_prodstatus.onord_qty = 0 
			LET l_fut_avail_qty = 0
			 
			DISPLAY 
				modu_rec_prodstatus.ware_code, 
				modu_rec_prodstatus.onhand_qty, 
				modu_rec_prodstatus.reserved_qty, 
				modu_rec_prodstatus.back_qty, 
				l_cur_avail_qty, 
				modu_rec_prodstatus.onord_qty, 
				l_fut_avail_qty 
			TO
				orderdetl.ware_code, 
				prodstatus.onhand_qty, 
				prodstatus.reserved_qty, 
				prodstatus.back_qty, 
				current_qty, 
				prodstatus.onord_qty, 
				future_qty attribute(yellow) 
		END IF
		 
		RETURN "" 
	END IF 
	
	IF modu_rec_prodstatus.stocked_flag = "Y" THEN 
		SELECT back_qty, (sched_qty+conf_qty) INTO l_oldback_qty, l_oldres_qty 
		FROM t_orderdetl 
		WHERE line_num = p_rec_orderdetl.line_num 

		IF l_oldres_qty IS NULL THEN 
			LET l_oldres_qty = 0 
		END IF 

		IF l_oldback_qty IS NULL THEN 
			LET l_oldback_qty = 0 
		END IF 

		LET modu_rec_prodstatus.reserved_qty = modu_rec_prodstatus.reserved_qty 
		- l_oldres_qty 
		+ p_rec_orderdetl.sched_qty 
		+ p_rec_orderdetl.conf_qty 

		LET modu_rec_prodstatus.back_qty = modu_rec_prodstatus.back_qty 
		- l_oldback_qty 
		+ p_rec_orderdetl.back_qty 

		IF glob_rec_opparms.cal_available_flag = "N" THEN 
			LET l_cur_avail_qty = modu_rec_prodstatus.onhand_qty 
			- modu_rec_prodstatus.reserved_qty 
			- modu_rec_prodstatus.back_qty 
		ELSE 
			LET l_cur_avail_qty = modu_rec_prodstatus.onhand_qty - modu_rec_prodstatus.reserved_qty 
			LET modu_rec_prodstatus.back_qty = NULL 
		END IF 

		LET l_fut_avail_qty = l_cur_avail_qty + modu_rec_prodstatus.onord_qty 

		IF p_display_ind THEN 
			DISPLAY 
				modu_rec_prodstatus.ware_code, 
				modu_rec_prodstatus.onhand_qty, 
				modu_rec_prodstatus.reserved_qty, 
				modu_rec_prodstatus.back_qty, 
				l_cur_avail_qty, 
				modu_rec_prodstatus.onord_qty, 
				l_fut_avail_qty 
			TO 
				orderdetl.ware_code, 
				prodstatus.onhand_qty, 
				prodstatus.reserved_qty, 
				prodstatus.back_qty, 
				current_qty, 
				prodstatus.onord_qty, 
				future_qty attribute(yellow) 
		END IF 

		IF l_cur_avail_qty <= 0 THEN
			ERROR "Product is out of stock"
		END IF
		RETURN l_cur_avail_qty 
	ELSE 
		IF p_display_ind THEN 
			--DISPLAY " NOT STOCKED " at 7,44 
			ERROR "Not Stocked !" SLEEP 2
		END IF 
		RETURN NULL 
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION allocate_stock(p_rec_orderdetl,p_back_ind) 
###########################################################################


###########################################################################
# FUNCTION enter_acct(p_acct_code) 
#
#
###########################################################################
FUNCTION enter_acct(p_acct_code) 
	DEFINE p_acct_code LIKE orderdetl.acct_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	LET l_rec_coa.acct_code = p_acct_code 
	OPEN WINDOW A672 with FORM "A672" 
	 CALL windecoration_a("A672") -- albo kd-755
 
	MESSAGE kandoomsg2("E",1025,"") #1025 Enter G.L. Account - ESC TO Continue
	INPUT BY NAME l_rec_coa.acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11e","input-l_rec_coa-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL 
			AND glob_temp_text != " " THEN 
				LET l_rec_coa.acct_code = glob_temp_text 
			END IF 
			NEXT FIELD acct_code 
			
		AFTER FIELD acct_code 
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("E",9077,"") #9077" Account Code IS required FOR Non-Inventory Lines"
				NEXT FIELD acct_code 
			ELSE 
				SELECT unique 1 FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9078,"") 		#9078" Invoice Line Account code NOT found"
					NEXT FIELD acct_code 
				END IF 
			END IF 

	END INPUT 
	
	CLOSE WINDOW A672 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN p_acct_code 
	ELSE 
		RETURN l_rec_coa.acct_code 
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION enter_acct(p_acct_code) 
###########################################################################


###########################################################################
# FUNCTION validate_row_generic(p_rec_orderdetl) 
#
# Generic row validation i.e. if user presses Append/insert during input array
#
###########################################################################
FUNCTION validate_row_generic(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 

	IF (db_prodstatus_pk_exists("UI_OFF",p_rec_orderdetl.part_code,p_rec_orderdetl.ware_code) AND	p_rec_orderdetl.sold_qty > 0 ) THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF

END FUNCTION
###########################################################################
# END FUNCTION validate_row_generic(p_rec_orderdetl) 
###########################################################################

###########################################################################
# FUNCTION validate_field(p_field_name,p_rec_orderdetl) 
#
# Common validation routines are NOT usual in max but has
# been included here TO avoid gross duplication of code
# This FUNCTION now uses validation based on whether the line
# IS being added OR editted.
#
###########################################################################
FUNCTION validate_field(p_field_name,p_rec_orderdetl) 
	DEFINE p_field_name char(15) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 

	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_t_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_disc_per LIKE orderdetl.disc_per 
--	DEFINE l_unit_price_amt LIKE orderdetl.unit_price_amt 
	DEFINE l_status INTEGER 
	DEFINE l_msg char(60) 
	DEFINE l_future_available LIKE prodstatus.onhand_qty 
	DEFINE l_available LIKE prodstatus.onhand_qty 
	DEFINE l_check_price LIKE orderdetl.line_tot_amt 
	DEFINE l_super_ind SMALLINT 
	DEFINE l_valid_ind SMALLINT 
	DEFINE i SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_part_code LIKE orderdetl.part_code 

	SELECT * INTO l_rec_orderdetl.* #copy full row-record details from DB tempTable 
	FROM t_orderdetl 
	WHERE line_num = p_rec_orderdetl.line_num 

	CASE 
		WHEN p_field_name = "offer_code" 
			IF p_rec_orderdetl.offer_code IS NOT NULL THEN
						 
				SELECT unique 1 FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = p_rec_orderdetl.offer_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9070,"") 		#9070 Special Offer code does NOT exist - Try Window"
					RETURN FALSE, p_rec_orderdetl.* 
				END IF 
				
				SELECT unique 1 FROM t_orderpart 
				WHERE offer_code = p_rec_orderdetl.offer_code			 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9072,"") 			#9072 offer code NOT nominated FOR this sales ORDER"
					RETURN FALSE, p_rec_orderdetl.* 
				END IF
				 
				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_orderdetl.part_code 
					
					SELECT unique 1 FROM offerprod 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code= p_rec_orderdetl.offer_code 
					AND maingrp_code = l_rec_product.maingrp_code 
					AND (prodgrp_code = l_rec_product.prodgrp_code 
					OR prodgrp_code IS null) 
					AND (part_code=l_rec_product.part_code OR part_code IS null) 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9073,l_rec_product.part_code) 				#9073" product IS NOT available as part of offer
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 
				LET p_rec_orderdetl.level_ind = "L" 
			END IF 
		# suppl_flag
		WHEN p_field_name = "suppl_flag" 
			CALL allocate_stock(p_rec_orderdetl.*,1) 
			RETURNING p_rec_orderdetl.* 
			IF p_rec_orderdetl.status_ind = "4" THEN 
				RETURN FALSE,p_rec_orderdetl.* 
			END IF 
		# part_code 
		WHEN p_field_name = "part_code" 
			IF l_rec_orderdetl.part_code IS NULL 
			OR l_rec_orderdetl.part_code != p_rec_orderdetl.part_code THEN 

				#### Check FOR exclusions
				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
					glob_rec_customer.cust_code, 
					p_rec_orderdetl.ware_code, 
					5, 
					today) THEN 
						ERROR kandoomsg2("E",9261,"") 				#9261" product can NOT be sold
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
					IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
					glob_rec_customer.cust_code, 
					p_rec_orderdetl.ware_code, 
					6, 
					today) THEN 
						ERROR kandoomsg2("E",9261,"") 		#9261" product can NOT be sold
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 

				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					LET l_super_ind = FALSE 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_orderdetl.part_code 
					IF l_rec_product.super_part_code IS NOT NULL THEN 
						LET l_idx = 0 
						WHILE l_rec_product.super_part_code IS NOT NULL 
							LET l_idx = l_idx + 1 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_product.super_part_code, 
							p_rec_orderdetl.ware_code, 
							0,2,0,"","","") THEN 
								ERROR kandoomsg2("E",9263,"") 					#9263 Product has been superseded with invalid part
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
							IF get_kandoooption_feature_state("EO","SP") THEN 
								LET l_future_available = 0 
								SELECT onhand_qty - reserved_qty - back_qty + onord_qty 
								INTO l_future_available FROM prodstatus 
								WHERE part_code = l_rec_product.part_code 
								AND ware_code = glob_rec_orderhead.ware_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								IF l_future_available > 0 THEN 
									LET l_msg = "Product ",l_rec_product.part_code clipped, " has been superseded by ",	l_rec_product.super_part_code clipped,"." 
									IF kandoomsg("E",8036,l_msg) = "N" THEN #8036 Change product selection (Y/N).
										#8036 Product ? been superseded by ?.
										LET l_super_ind = TRUE 
										EXIT WHILE 
									END IF 
								END IF 
							END IF 

							SELECT * INTO l_rec_product.* FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = l_rec_product.super_part_code 
							IF l_idx > 20 THEN 
								ERROR kandoomsg2("E",9183,"") 					#9183 Product code supercession limit exceeded
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
						END WHILE 

						LET p_rec_orderdetl.part_code = l_rec_product.part_code 
						LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
						IF NOT l_super_ind THEN 
							ERROR kandoomsg2("E",7060,l_rec_product.part_code) 			#7060 Product replaced by superceded product .....
						ELSE 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code,
							p_rec_orderdetl.ware_code, 
							0,2,0,"","","") THEN 
								ERROR kandoomsg2("E",9263,"") 					#9263 Product has been superseded with invalid part
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
							IF p_rec_orderdetl.part_code IS NOT NULL THEN 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
								glob_rec_customer.cust_code, 
								p_rec_orderdetl.ware_code, 
								5, 
								today) THEN 
									ERROR kandoomsg2("E",9263,"") 								#9263 Product has been superseded with invalid part
									LET p_rec_orderdetl.part_code = NULL 
									LET p_rec_orderdetl.desc_text = NULL 
									RETURN FALSE,p_rec_orderdetl.* 
								END IF 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
								glob_rec_customer.cust_code, 
								p_rec_orderdetl.ware_code, 
								6, 
								today) THEN 
									ERROR kandoomsg2("E",9263,"") 						#9263 Product has been superseded with invalid part
									LET p_rec_orderdetl.part_code = NULL 
									LET p_rec_orderdetl.desc_text = NULL 
									RETURN FALSE,p_rec_orderdetl.* 
								END IF 
							END IF 
						END IF 

					ELSE 

						IF NOT valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code,p_rec_orderdetl.ware_code,1,2,0,"","","") 
						THEN 
							RETURN FALSE,p_rec_orderdetl.* 
						END IF 
						LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
						LET p_rec_orderdetl.trade_in_flag = l_rec_product.trade_in_flag 
						LET p_rec_orderdetl.disc_allow_flag = l_rec_product.disc_allow_flag 
					END IF 
					
					### Stock availability ###
					SELECT prodstatus.*, (onhand_qty - reserved_qty - back_qty) 
					INTO 
						modu_rec_prodstatus.*, 
						l_available 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = p_rec_orderdetl.ware_code 
					AND part_code = l_rec_product.part_code 
					LET l_status = status 

					IF l_status = NOTFOUND OR l_available <= 0 THEN 

						IF check_alternate(l_rec_product.part_code,	l_rec_product.alter_part_code) THEN 
							IF promptTF("",kandoomsg2("N",8020,""),1) THEN	#N8020 Product NOT currently stocked.Choose Alternate?
								LET l_part_code =	display_alternates(l_rec_product.part_code,	l_rec_product.alter_part_code) 
								IF l_part_code IS NOT NULL THEN 
									LET p_rec_orderdetl.part_code = l_part_code 
									SELECT * INTO l_rec_product.* FROM product 
									WHERE part_code = p_rec_orderdetl.part_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
									CALL validate_field("part_code",p_rec_orderdetl.*) RETURNING l_valid_ind,p_rec_orderdetl.*
									 
									IF NOT l_valid_ind THEN 
										RETURN FALSE, p_rec_orderdetl.* 
									END IF 
								END IF 
							ELSE 
								IF l_status = NOTFOUND THEN 
									LET p_rec_orderdetl.part_code = l_rec_orderdetl.part_code 
									RETURN FALSE, p_rec_orderdetl.* 
								END IF 
							END IF 
						ELSE 
							IF l_status = NOTFOUND THEN 
								ERROR kandoomsg2("I",9104,"") 						#I9104 Product NOT Stocked AT this Warehouse
								LET p_rec_orderdetl.part_code = l_rec_orderdetl.part_code 
								RETURN FALSE, p_rec_orderdetl.* 
							END IF 
						END IF 
					END IF 

					IF p_rec_orderdetl.offer_code IS NOT NULL THEN 
						SELECT unique 1 FROM offerprod 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code= p_rec_orderdetl.offer_code 
						AND maingrp_code = l_rec_product.maingrp_code 
						AND (prodgrp_code = l_rec_product.prodgrp_code 
						OR prodgrp_code IS null) 
						AND (part_code=l_rec_product.part_code OR part_code IS null) 
						IF sqlca.sqlcode = NOTFOUND THEN 
							ERROR kandoomsg2("E",9073,l_rec_product.part_code) 		#9073" product IS NOT available as part of offer
							RETURN FALSE,p_rec_orderdetl.* 
						END IF 
					END IF 

					## Unit Price always calc. b/c in Add Mode
					LET p_rec_orderdetl.unit_price_amt = unit_price(p_rec_orderdetl.ware_code,p_rec_orderdetl.part_code,p_rec_orderdetl.level_ind) 

					## Calc. disc always b/c in Add Mode
					LET p_rec_orderdetl.disc_per = NULL 
					IF p_rec_orderdetl.status_ind = "3" THEN 
						IF glob_rec_sales_order_parameter.suppl_flag IS NULL 
						OR glob_rec_sales_order_parameter.suppl_flag = "N" THEN 
							LET p_rec_orderdetl.status_ind = "0" 
						ELSE 
							LET p_rec_orderdetl.status_ind = "1" 
						END IF 
					END IF 
					CALL allocate_stock(p_rec_orderdetl.*,0) 
					RETURNING p_rec_orderdetl.* 
				END IF 
			END IF 

		WHEN p_field_name = "sold_qty" 
			IF p_rec_orderdetl.sold_qty <= 0 THEN
				ERROR "Quantity can not be 0 or negative"
				RETURN FALSE,p_rec_orderdetl.*
			END IF
			
			IF glob_rec_orderhead.ord_ind = '3' THEN 
				INITIALIZE l_rec_t_orderdetl.* TO NULL 
				SELECT * INTO l_rec_t_orderdetl.* FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = p_rec_orderdetl.order_num 
				AND line_num = p_rec_orderdetl.line_num 
				IF status = 0 THEN 
					IF p_rec_orderdetl.sold_qty > l_rec_t_orderdetl.sold_qty AND l_rec_t_orderdetl.sold_qty IS NOT NULL THEN 
						ERROR kandoomsg2("E",9256,l_rec_t_orderdetl.sold_qty) 	#9256 Quantity may NOT be increased above VALUE
						LET p_rec_orderdetl.sold_qty = l_rec_t_orderdetl.sold_qty 
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 
			END IF 

			CASE 
				WHEN p_rec_orderdetl.sold_qty = 0 OR p_rec_orderdetl.sold_qty IS NULL
					ERROR "Quantity can not be 0"
					SLEEP 1  
					LET p_rec_orderdetl.sold_qty = p_rec_orderdetl.inv_qty 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.trade_in_flag = "Y" 
					IF p_rec_orderdetl.sold_qty > 0 THEN 
						ERROR kandoomsg2("E",9181,"") 				#9181 Trade-in products can be entered negative only
						LET p_rec_orderdetl.sold_qty = 0 - p_rec_orderdetl.sold_qty 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					IF p_rec_orderdetl.sold_qty > p_rec_orderdetl.inv_qty THEN 
						ERROR kandoomsg2("E",9074,"") 			#9074 Cannot Decrease stock qty < that prev.invoiced
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					
					WHENEVER any ERROR CONTINUE 
					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt + p_rec_orderdetl.unit_tax_amt) 
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 		#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					WHENEVER any ERROR stop 


				OTHERWISE 
					IF p_rec_orderdetl.sold_qty <= 0 THEN 
						ERROR kandoomsg2("E",9180,"") 			#9180 Quantity may NOT be negative
						LET p_rec_orderdetl.sold_qty = 0 - p_rec_orderdetl.sold_qty 
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
					
					IF (p_rec_orderdetl.sold_qty + p_rec_orderdetl.bonus_qty) < p_rec_orderdetl.inv_qty THEN 
						ERROR kandoomsg2("E",9074,"") 			#9074 Cannot Decrease stock qty < that prev.invoiced
						
						SELECT sold_qty 
						INTO p_rec_orderdetl.sold_qty 
						FROM t_orderdetl 
						WHERE line_num = p_rec_orderdetl.line_num
						 
						RETURN  #RETURN------------------------------
							FALSE,
							p_rec_orderdetl.*   
					END IF 
					
					WHENEVER any ERROR CONTINUE
					 
					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt + p_rec_orderdetl.unit_tax_amt) 
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 			#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					
					WHENEVER any ERROR stop 

			END CASE 

			CALL allocate_stock(p_rec_orderdetl.*,0)	RETURNING p_rec_orderdetl.* 

		WHEN p_field_name = "bonus_qty" 
			CASE 
				WHEN p_rec_orderdetl.bonus_qty IS NULL 
					LET p_rec_orderdetl.bonus_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.sold_qty < 0 
					ERROR kandoomsg2("E",9180,"") 		#9180 Quantity may NOT be negative
					LET p_rec_orderdetl.bonus_qty = 0 - p_rec_orderdetl.bonus_qty 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN (p_rec_orderdetl.sold_qty+p_rec_orderdetl.bonus_qty)	< p_rec_orderdetl.inv_qty 
					ERROR kandoomsg2("E",9074,"") 		#9074 Cannot Decrease stock qty < that prev.invoiced
					
					SELECT bonus_qty 
					INTO p_rec_orderdetl.sold_qty 
					FROM t_orderdetl 
					WHERE line_num = p_rec_orderdetl.line_num
					 
					RETURN  #RETURN ---------------------- 
						FALSE,
						p_rec_orderdetl.* 
			END CASE 

			CALL allocate_stock(p_rec_orderdetl.*,0) RETURNING p_rec_orderdetl.* 

		WHEN p_field_name = "sched_qty" 
			CASE 
				WHEN p_rec_orderdetl.sched_qty IS NULL 
					LET p_rec_orderdetl.sched_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.sched_qty < 0 
					ERROR kandoomsg2("E",9081,"") 		#9081" Scheduled Quantity Must Not be Negative"
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.sched_qty > (p_rec_orderdetl.order_qty	- p_rec_orderdetl.inv_qty) 
					ERROR kandoomsg2("E",9082,"") 		#9082" Scheduled Quantity Exceeds Required Qty"
					RETURN FALSE,p_rec_orderdetl.* 

				OTHERWISE 
					IF p_rec_orderdetl.cost_ind = "Y" THEN 
						LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty 
						- p_rec_orderdetl.sched_qty 
						- p_rec_orderdetl.inv_qty 
					ELSE 
						IF p_rec_orderdetl.sched_qty > (p_rec_orderdetl.order_qty-p_rec_orderdetl.inv_qty) THEN 
							ERROR kandoomsg2("E",9191,"") 					#9191 Backorders NOT allowed
							LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
						END IF 
					END IF 
			END CASE 
		WHEN p_field_name = "back_qty" 
			CASE 
				WHEN p_rec_orderdetl.back_qty IS NULL 
					LET p_rec_orderdetl.back_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.back_qty < 0 
					ERROR kandoomsg2("E",9083,"") 	#9083" Back Ordered Quantity Must Not be Negative"
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.back_qty > (p_rec_orderdetl.order_qty 	- p_rec_orderdetl.inv_qty) 
					ERROR kandoomsg2("E",9084,"") 		#9084" Back Ordered Quantity Exceeds Required Qty"
					RETURN FALSE,p_rec_orderdetl.* 

				OTHERWISE 
					LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.back_qty - p_rec_orderdetl.inv_qty 

			END CASE
			 
		WHEN p_field_name = "disc_per" 
			IF p_rec_orderdetl.disc_per IS NULL THEN 
				LET p_rec_orderdetl.disc_per = 0 
				RETURN FALSE,p_rec_orderdetl.* 
			ELSE 
				IF p_rec_orderdetl.list_price_amt > 0 THEN 
					IF l_rec_orderdetl.disc_per IS NOT NULL 
					AND ( l_rec_orderdetl.disc_per < (p_rec_orderdetl.disc_per-0.1) 
					OR l_rec_orderdetl.disc_per > (p_rec_orderdetl.disc_per+0.1) ) THEN 
						##### 0.1 TO avoid rounding error
						## IF disc changed THEN recalc price
						LET p_rec_orderdetl.unit_price_amt = NULL 
						LET p_rec_orderdetl.serial_qty = FALSE 
						## IF discount changed THEN auto_disc = FALSE
					END IF 
				END IF 
			END IF 

		WHEN p_field_name = "unit_price_amt" 
			IF p_rec_orderdetl.unit_price_amt IS NULL THEN 
				LET p_rec_orderdetl.unit_price_amt =	unit_price(
					p_rec_orderdetl.ware_code, 
					p_rec_orderdetl.part_code, 
					p_rec_orderdetl.level_ind) 
				RETURN 
					FALSE,
					p_rec_orderdetl.* 

			ELSE 

				IF p_rec_orderdetl.unit_price_amt < 0 THEN 
					ERROR kandoomsg2("E",9239,"") 	#9239 Selling price cannot be negative
					RETURN FALSE,p_rec_orderdetl.* 
				ELSE 
					IF p_rec_orderdetl.list_price_amt = 0 THEN 
						LET p_rec_orderdetl.list_price_amt = p_rec_orderdetl.unit_price_amt 
						LET p_rec_orderdetl.disc_per = 0 
					ELSE 
						IF l_rec_orderdetl.unit_price_amt IS NOT NULL 
						AND ( l_rec_orderdetl.unit_price_amt < (p_rec_orderdetl.unit_price_amt-0.1) 
						OR l_rec_orderdetl.unit_price_amt > (p_rec_orderdetl.unit_price_amt+0.1) ) THEN 
							##### +/-0.1 TO avoid rounding error
							## IF price changed THEN recalc disc
							LET p_rec_orderdetl.disc_per = NULL 
							LET p_rec_orderdetl.serial_qty = FALSE 
							## IF price changed THEN auto_disc = FALSE
						END IF 
					END IF 

					CALL calc_line_tax(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_orderhead.tax_code, 
						p_rec_orderdetl.tax_code, 
						modu_rec_prodstatus.sale_tax_amt, 
						p_rec_orderdetl.sold_qty, 
						p_rec_orderdetl.unit_cost_amt, 
						p_rec_orderdetl.unit_price_amt) 
					RETURNING 
						p_rec_orderdetl.unit_tax_amt,
						p_rec_orderdetl.ext_tax_amt
					 
					WHENEVER any ERROR CONTINUE 

					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt 	+ p_rec_orderdetl.unit_tax_amt) 
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 	#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 

					WHENEVER any ERROR stop 
				END IF 

			END IF

######################
		WHEN "ALL" #do we need this
			IF p_rec_orderdetl.part_code IS NULL THEN #part_code can never be NULL
				RETURN FALSE,p_rec_orderdetl.*
			END IF

#		WHEN p_field_name = "offer_code" 
			IF p_rec_orderdetl.offer_code IS NOT NULL THEN
						 
				SELECT unique 1 FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = p_rec_orderdetl.offer_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9070,"") 		#9070 Special Offer code does NOT exist - Try Window"
					RETURN FALSE, p_rec_orderdetl.* 
				END IF 
				
				SELECT unique 1 FROM t_orderpart 
				WHERE offer_code = p_rec_orderdetl.offer_code			 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9072,"") 			#9072 offer code NOT nominated FOR this sales ORDER"
					RETURN FALSE, p_rec_orderdetl.* 
				END IF
				 
				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_orderdetl.part_code 
					
					SELECT unique 1 FROM offerprod 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code= p_rec_orderdetl.offer_code 
					AND maingrp_code = l_rec_product.maingrp_code 
					AND (prodgrp_code = l_rec_product.prodgrp_code 
					OR prodgrp_code IS null) 
					AND (part_code=l_rec_product.part_code OR part_code IS null) 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9073,l_rec_product.part_code) 				#9073" product IS NOT available as part of offer

						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 
				LET p_rec_orderdetl.level_ind = "L" 
			END IF 

#		WHEN p_field_name = "suppl_flag" 
			CALL allocate_stock(p_rec_orderdetl.*,1)			RETURNING p_rec_orderdetl.*
			 
			IF p_rec_orderdetl.status_ind = "4" THEN 
				RETURN FALSE,p_rec_orderdetl.* 
			END IF 

#		WHEN p_field_name = "part_code" 
			IF l_rec_orderdetl.part_code IS NULL	OR l_rec_orderdetl.part_code != p_rec_orderdetl.part_code THEN 

				#### Check FOR exclusions
				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
					glob_rec_customer.cust_code, 
					p_rec_orderdetl.ware_code, 
					5, 
					today) THEN 
						ERROR kandoomsg2("E",9261,"") 				#9261" product can NOT be sold
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
					IF prod_exclude(
						glob_rec_kandoouser.cmpy_code,
						p_rec_orderdetl.part_code, 
						glob_rec_customer.cust_code, 
						p_rec_orderdetl.ware_code, 
						6, 
						today)
					THEN 
						ERROR kandoomsg2("E",9261,"") 		#9261" product can NOT be sold
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 

				IF p_rec_orderdetl.part_code IS NOT NULL THEN 
					LET l_super_ind = FALSE 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_orderdetl.part_code 
					IF l_rec_product.super_part_code IS NOT NULL THEN 
						LET l_idx = 0 
						WHILE l_rec_product.super_part_code IS NOT NULL 
							LET l_idx = l_idx + 1 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_product.super_part_code, 
							p_rec_orderdetl.ware_code, 
							0,2,0,"","","") THEN 
								ERROR kandoomsg2("E",9263,"") 					#9263 Product has been superseded with invalid part
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
							IF get_kandoooption_feature_state("EO","SP") THEN 
								LET l_future_available = 0 
								SELECT onhand_qty - reserved_qty - back_qty + onord_qty 
								INTO l_future_available FROM prodstatus 
								WHERE part_code = l_rec_product.part_code 
								AND ware_code = glob_rec_orderhead.ware_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								IF l_future_available > 0 THEN 
									LET l_msg = "Product ",l_rec_product.part_code clipped, " has been superseded by ",	l_rec_product.super_part_code clipped,"." 
									IF kandoomsg("E",8036,l_msg) = "N" THEN #8036 Change product selection (Y/N).
										#8036 Product ? been superseded by ?.
										LET l_super_ind = TRUE 
										EXIT WHILE 
									END IF 
								END IF 
							END IF 

							SELECT * INTO l_rec_product.* FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = l_rec_product.super_part_code 
							IF l_idx > 20 THEN 
								ERROR kandoomsg2("E",9183,"") 					#9183 Product code supercession limit exceeded
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
						END WHILE 

						LET p_rec_orderdetl.part_code = l_rec_product.part_code 
						LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
						IF NOT l_super_ind THEN 
							ERROR kandoomsg2("E",7060,l_rec_product.part_code) 			#7060 Product replaced by superceded product .....
						ELSE 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code,
							p_rec_orderdetl.ware_code, 
							0,2,0,"","","") THEN 
								ERROR kandoomsg2("E",9263,"") 					#9263 Product has been superseded with invalid part
								LET p_rec_orderdetl.part_code = NULL 
								LET p_rec_orderdetl.desc_text = NULL 
								RETURN FALSE,p_rec_orderdetl.* 
							END IF 
							IF p_rec_orderdetl.part_code IS NOT NULL THEN 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
								glob_rec_customer.cust_code, 
								p_rec_orderdetl.ware_code, 
								5, 
								today) THEN 
									ERROR kandoomsg2("E",9263,"") 								#9263 Product has been superseded with invalid part
									LET p_rec_orderdetl.part_code = NULL 
									LET p_rec_orderdetl.desc_text = NULL 
									RETURN FALSE,p_rec_orderdetl.* 
								END IF 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code, 
								glob_rec_customer.cust_code, 
								p_rec_orderdetl.ware_code, 
								6, 
								today) THEN 
									ERROR kandoomsg2("E",9263,"") 						#9263 Product has been superseded with invalid part
									LET p_rec_orderdetl.part_code = NULL 
									LET p_rec_orderdetl.desc_text = NULL 
									RETURN FALSE,p_rec_orderdetl.* 
								END IF 
							END IF 
						END IF 

					ELSE 

						IF NOT valid_part(glob_rec_kandoouser.cmpy_code,p_rec_orderdetl.part_code,p_rec_orderdetl.ware_code,1,2,0,"","","") 
						THEN 
							RETURN FALSE,p_rec_orderdetl.* 
						END IF 
						LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
						LET p_rec_orderdetl.trade_in_flag = l_rec_product.trade_in_flag 
						LET p_rec_orderdetl.disc_allow_flag = l_rec_product.disc_allow_flag 
					END IF 
					
					### Stock availability ###
					SELECT prodstatus.*, (onhand_qty - reserved_qty - back_qty) 
					INTO 
						modu_rec_prodstatus.*, 
						l_available 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = p_rec_orderdetl.ware_code 
					AND part_code = l_rec_product.part_code 
					LET l_status = status 

					IF l_status = NOTFOUND OR l_available <= 0 THEN 

						IF check_alternate(l_rec_product.part_code,	l_rec_product.alter_part_code) THEN 
							IF promptTF("",kandoomsg2("N",8020,""),1) THEN	#N8020 Product NOT currently stocked.Choose Alternate?
								LET l_part_code =	display_alternates(l_rec_product.part_code,	l_rec_product.alter_part_code) 
								IF l_part_code IS NOT NULL THEN 
									LET p_rec_orderdetl.part_code = l_part_code 
									SELECT * INTO l_rec_product.* FROM product 
									WHERE part_code = p_rec_orderdetl.part_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
									CALL validate_field("part_code",p_rec_orderdetl.*) RETURNING l_valid_ind,p_rec_orderdetl.*
									 
									IF NOT l_valid_ind THEN 
										RETURN FALSE, p_rec_orderdetl.* 
									END IF 
								END IF 
							ELSE 
								IF l_status = NOTFOUND THEN 
									LET p_rec_orderdetl.part_code = l_rec_orderdetl.part_code 
									RETURN FALSE, p_rec_orderdetl.* 
								END IF 
							END IF 
						ELSE 
							IF l_status = NOTFOUND THEN 
								ERROR kandoomsg2("I",9104,"") 						#I9104 Product NOT Stocked AT this Warehouse
								LET p_rec_orderdetl.part_code = l_rec_orderdetl.part_code 
								RETURN FALSE, p_rec_orderdetl.* 
							END IF 
						END IF 
					END IF 

					IF p_rec_orderdetl.offer_code IS NOT NULL THEN 
						SELECT unique 1 FROM offerprod 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code= p_rec_orderdetl.offer_code 
						AND maingrp_code = l_rec_product.maingrp_code 
						AND (prodgrp_code = l_rec_product.prodgrp_code 
						OR prodgrp_code IS null) 
						AND (part_code=l_rec_product.part_code OR part_code IS null) 
						IF sqlca.sqlcode = NOTFOUND THEN 
							ERROR kandoomsg2("E",9073,l_rec_product.part_code) 		#9073" product IS NOT available as part of offer
							RETURN FALSE,p_rec_orderdetl.* 
						END IF 
					END IF 

					## Unit Price always calc. b/c in Add Mode
					LET p_rec_orderdetl.unit_price_amt = unit_price(p_rec_orderdetl.ware_code,p_rec_orderdetl.part_code,p_rec_orderdetl.level_ind) 

					## Calc. disc always b/c in Add Mode
					LET p_rec_orderdetl.disc_per = NULL 
					IF p_rec_orderdetl.status_ind = "3" THEN 
						IF glob_rec_sales_order_parameter.suppl_flag IS NULL 
						OR glob_rec_sales_order_parameter.suppl_flag = "N" THEN 
							LET p_rec_orderdetl.status_ind = "0" 
						ELSE 
							LET p_rec_orderdetl.status_ind = "1" 
						END IF 
					END IF 
					CALL allocate_stock(p_rec_orderdetl.*,0) 
					RETURNING p_rec_orderdetl.* 
				END IF 
			END IF 

#		WHEN p_field_name = "sold_qty" 
			IF glob_rec_orderhead.ord_ind = '3' THEN 
				INITIALIZE l_rec_t_orderdetl.* TO NULL 
				SELECT * INTO l_rec_t_orderdetl.* FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = p_rec_orderdetl.order_num 
				AND line_num = p_rec_orderdetl.line_num 
				IF status = 0 THEN 
					IF p_rec_orderdetl.sold_qty > l_rec_t_orderdetl.sold_qty AND l_rec_t_orderdetl.sold_qty IS NOT NULL THEN 
						ERROR kandoomsg2("E",9256,l_rec_t_orderdetl.sold_qty) 	#9256 Quantity may NOT be increased above VALUE
						LET p_rec_orderdetl.sold_qty = l_rec_t_orderdetl.sold_qty 
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
				END IF 
			END IF 

			CASE 
				WHEN p_rec_orderdetl.sold_qty = 0 OR p_rec_orderdetl.sold_qty IS NULL
					ERROR "Quantity can not be 0"
					LET p_rec_orderdetl.sold_qty = p_rec_orderdetl.inv_qty 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.trade_in_flag = "Y" 
					IF p_rec_orderdetl.sold_qty > 0 THEN 
						ERROR kandoomsg2("E",9181,"") 				#9181 Trade-in products can be entered negative only
						LET p_rec_orderdetl.sold_qty = 0 - p_rec_orderdetl.sold_qty 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					IF p_rec_orderdetl.sold_qty > p_rec_orderdetl.inv_qty THEN 
						ERROR kandoomsg2("E",9074,"") 			#9074 Cannot Decrease stock qty < that prev.invoiced
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					WHENEVER any ERROR CONTINUE 
					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt + p_rec_orderdetl.unit_tax_amt) 
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 		#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					WHENEVER any ERROR stop 


				OTHERWISE 
					IF p_rec_orderdetl.sold_qty < 0 THEN 
						ERROR kandoomsg2("E",9180,"") 			#9180 Quantity may NOT be negative
						LET p_rec_orderdetl.sold_qty = 0 - p_rec_orderdetl.sold_qty 
						RETURN FALSE,p_rec_orderdetl.* 
					END IF 
					
					IF (p_rec_orderdetl.sold_qty + p_rec_orderdetl.bonus_qty) < p_rec_orderdetl.inv_qty THEN 
						ERROR kandoomsg2("E",9074,"") 			#9074 Cannot Decrease stock qty < that prev.invoiced
						
						SELECT sold_qty 
						INTO p_rec_orderdetl.sold_qty 
						FROM t_orderdetl 
						WHERE line_num = p_rec_orderdetl.line_num
						 
						RETURN  #RETURN ----------------------- 
							FALSE,
							p_rec_orderdetl.* 
					END IF 
					
					WHENEVER any ERROR CONTINUE
					 
					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt + p_rec_orderdetl.unit_tax_amt) 
					
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 			#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					WHENEVER any ERROR stop 

			END CASE 

			CALL allocate_stock(p_rec_orderdetl.*,0)	RETURNING p_rec_orderdetl.* 

#		WHEN p_field_name = "bonus_qty" 
			CASE 
				WHEN p_rec_orderdetl.bonus_qty IS NULL 
					LET p_rec_orderdetl.bonus_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 
					
				WHEN p_rec_orderdetl.sold_qty < 0 
					ERROR kandoomsg2("E",9180,"") 		#9180 Quantity may NOT be negative
					LET p_rec_orderdetl.bonus_qty = 0 - p_rec_orderdetl.bonus_qty 
					RETURN FALSE,p_rec_orderdetl.*
					 
				WHEN (p_rec_orderdetl.sold_qty+p_rec_orderdetl.bonus_qty)	< p_rec_orderdetl.inv_qty 
					ERROR kandoomsg2("E",9074,"") 		#9074 Cannot Decrease stock qty < that prev.invoiced
					
					SELECT bonus_qty 
					INTO p_rec_orderdetl.sold_qty 
					FROM t_orderdetl 
					WHERE line_num = p_rec_orderdetl.line_num 
					
					RETURN  #RETURN -------------------- 
						FALSE,
						p_rec_orderdetl.* 
			END CASE 

			CALL allocate_stock(p_rec_orderdetl.*,0)	RETURNING p_rec_orderdetl.* 


#		WHEN p_field_name = "sched_qty" 
			CASE 
				WHEN p_rec_orderdetl.sched_qty IS NULL 
					LET p_rec_orderdetl.sched_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.sched_qty < 0 
					ERROR kandoomsg2("E",9081,"") 		#9081" Scheduled Quantity Must Not be Negative"
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.sched_qty > (p_rec_orderdetl.order_qty	- p_rec_orderdetl.inv_qty) 
					ERROR kandoomsg2("E",9082,"") 		#9082" Scheduled Quantity Exceeds Required Qty"
					RETURN FALSE,p_rec_orderdetl.* 

				OTHERWISE 
					IF p_rec_orderdetl.cost_ind = "Y" THEN 
						LET p_rec_orderdetl.back_qty = p_rec_orderdetl.order_qty 
						- p_rec_orderdetl.sched_qty 
						- p_rec_orderdetl.inv_qty 
					ELSE 
						IF p_rec_orderdetl.sched_qty > (p_rec_orderdetl.order_qty-p_rec_orderdetl.inv_qty) THEN 
							ERROR kandoomsg2("E",9191,"") 					#9191 Backorders NOT allowed
							LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.inv_qty 
						END IF 
					END IF 
			END CASE 
#		WHEN p_field_name = "back_qty" 
			CASE 
				WHEN p_rec_orderdetl.back_qty IS NULL 
					LET p_rec_orderdetl.back_qty = 0 
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.back_qty < 0 
					ERROR kandoomsg2("E",9083,"") 	#9083" Back Ordered Quantity Must Not be Negative"
					RETURN FALSE,p_rec_orderdetl.* 

				WHEN p_rec_orderdetl.back_qty > (p_rec_orderdetl.order_qty 	- p_rec_orderdetl.inv_qty) 
					ERROR kandoomsg2("E",9084,"") 		#9084" Back Ordered Quantity Exceeds Required Qty"
					RETURN FALSE,p_rec_orderdetl.* 

				OTHERWISE 
					LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.order_qty - p_rec_orderdetl.back_qty - p_rec_orderdetl.inv_qty 

			END CASE
			 
#		WHEN p_field_name = "disc_per" 
			IF p_rec_orderdetl.disc_per IS NULL THEN 
				LET p_rec_orderdetl.disc_per = 0 
				RETURN FALSE,p_rec_orderdetl.* 
			ELSE 
				IF p_rec_orderdetl.list_price_amt > 0 THEN 
					IF l_rec_orderdetl.disc_per IS NOT NULL 
					AND ( l_rec_orderdetl.disc_per < (p_rec_orderdetl.disc_per-0.1) 
					OR l_rec_orderdetl.disc_per > (p_rec_orderdetl.disc_per+0.1) ) THEN 
						##### 0.1 TO avoid rounding error
						## IF disc changed THEN recalc price
						LET p_rec_orderdetl.unit_price_amt = NULL 
						LET p_rec_orderdetl.serial_qty = FALSE 
						## IF discount changed THEN auto_disc = FALSE
					END IF 
				END IF 
			END IF 

#		WHEN p_field_name = "unit_price_amt" 
			IF p_rec_orderdetl.unit_price_amt IS NULL THEN 
				LET p_rec_orderdetl.unit_price_amt = 
				unit_price(p_rec_orderdetl.ware_code, 
				p_rec_orderdetl.part_code, 
				p_rec_orderdetl.level_ind) 
				RETURN FALSE,p_rec_orderdetl.* 

			ELSE 

				IF p_rec_orderdetl.unit_price_amt < 0 THEN 
					ERROR kandoomsg2("E",9239,"") 	#9239 Selling price cannot be negative

					RETURN FALSE,p_rec_orderdetl.*  #RETURN -------------------------------------------- 

				ELSE 
					IF p_rec_orderdetl.list_price_amt = 0 THEN 
						LET p_rec_orderdetl.list_price_amt = p_rec_orderdetl.unit_price_amt 
						LET p_rec_orderdetl.disc_per = 0 
					ELSE 
						IF l_rec_orderdetl.unit_price_amt IS NOT NULL 
						AND ( l_rec_orderdetl.unit_price_amt < (p_rec_orderdetl.unit_price_amt-0.1) 
						OR l_rec_orderdetl.unit_price_amt > (p_rec_orderdetl.unit_price_amt+0.1) ) THEN 
							##### +/-0.1 TO avoid rounding error
							## IF price changed THEN recalc disc
							LET p_rec_orderdetl.disc_per = NULL 
							LET p_rec_orderdetl.serial_qty = FALSE 
							## IF price changed THEN auto_disc = FALSE
						END IF 
					END IF 

					CALL calc_line_tax(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_orderhead.tax_code, 
						p_rec_orderdetl.tax_code, 
						modu_rec_prodstatus.sale_tax_amt, 
						p_rec_orderdetl.sold_qty, 
						p_rec_orderdetl.unit_cost_amt, 
						p_rec_orderdetl.unit_price_amt) 
					RETURNING 
						p_rec_orderdetl.unit_tax_amt,
						p_rec_orderdetl.ext_tax_amt
					 
					WHENEVER any ERROR CONTINUE 
					LET l_check_price = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_price_amt 	+ p_rec_orderdetl.unit_tax_amt) 
					IF status = -1226 THEN 
						ERROR kandoomsg2("E",9271,"") 	#9271 Numeric value exceeds 9 billion.
						WHENEVER any ERROR stop 
						RETURN FALSE, p_rec_orderdetl.* 
					END IF 
					WHENEVER any ERROR stop 
				END IF 
			END IF
######################

		OTHERWISE
			CALL fgl_winmessage("Internal 4gl error","you miss-spelled/typed the field name","error")
						 
	END CASE 
	#############################################################################################################################	
	#-------------------------- END CASE ----------------------------------------------------------------------------------------
	############################################################################################################################# 
	
	CALL db_t_orderdetl_update_line(p_rec_orderdetl.*)
	CALL db_t_orderdetl_get_rec(p_rec_orderdetl.line_num) RETURNING p_rec_orderdetl.*  
--	SELECT * INTO p_rec_orderdetl.* 
--	FROM t_orderdetl 
--	WHERE line_num = p_rec_orderdetl.line_num
	 
	RETURN TRUE,p_rec_orderdetl.* 
END FUNCTION 
###########################################################################
# END FUNCTION validate_field(p_field_name,p_rec_orderdetl) 
###########################################################################


###########################################################################
# FUNCTION validate_backorder()
#
# 
###########################################################################
FUNCTION validate_backorder() 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		line_num LIKE orderdetl.line_num, 
		offer_code LIKE orderdetl.offer_code, 
		part_code LIKE orderdetl.part_code, 
		sold_qty LIKE orderdetl.sold_qty, 
		back_qty LIKE orderdetl.back_qty, 
		required_qty LIKE orderdetl.required_qty, 
		status_ind LIKE orderdetl.status_ind 
	END RECORD 
	DEFINE l_available_qty LIKE orderdetl.back_qty
	DEFINE l_back_qty LIKE orderdetl.back_qty
	DEFINE l_arr_partial DYNAMIC ARRAY OF FLOAT 
	DEFINE l_arr_other array[200] OF RECORD 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text, 
		required_qty LIKE orderdetl.required_qty, 
		back_qty LIKE orderdetl.back_qty 
	END RECORD 
	DEFINE l_sched_qty LIKE orderdetl.back_qty
	DEFINE l_temp_back_qty LIKE orderdetl.back_qty
	DEFINE l_upd_flag SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 

	
	OPEN WINDOW E455 with FORM "E455" 
	 CALL windecoration_e("E455") -- albo kd-755 

	CLEAR FORM 
	SELECT * INTO glob_rec_customer.* FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_orderhead.cust_code 

	IF glob_rec_customer.back_order_flag = "N" THEN 
		IF kandoomsg("E",8035,"") = "N" THEN 
			ERROR kandoomsg2("U",1005,"") 	#1005 " Updating Database - Please Wait"
			LABEL tryagain: 

			BEGIN WORK 
				LET l_upd_flag = 1 

				DECLARE c3_orderdetl cursor with hold FOR 
				SELECT * FROM t_orderdetl 
				WHERE status_ind = "2" 
				AND back_qty > 0 

				FOREACH c3_orderdetl INTO l_rec_orderdetl.* 
					IF l_rec_orderdetl.autoinsert_flag = "Y" 
					OR l_rec_orderdetl.autoinsert_flag = "*" THEN 

						DELETE FROM t_orderpart 
						WHERE offer_code = l_rec_orderdetl.offer_code 

						DECLARE c4_orderdetl cursor with hold FOR 
						SELECT * FROM t_orderdetl 
						WHERE (autoinsert_flag = "Y" 
						OR autoinsert_flag = "*") 
						AND offer_code = l_rec_orderdetl.offer_code 

						FOREACH c4_orderdetl INTO l_rec_orderdetl.* 
							LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 
							IF l_upd_flag <= 0 THEN 
								EXIT FOREACH 
							END IF 
							DELETE FROM t_orderdetl 
							WHERE line_num = l_rec_orderdetl.line_num 
						END FOREACH 

						CLOSE c4_orderdetl 

						IF l_upd_flag = -1 THEN 
							GOTO tryagain 
						END IF 

						IF l_upd_flag = 0 THEN 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							CLOSE WINDOW E455 
							RETURN FALSE 
						END IF 

						CONTINUE FOREACH 

					END IF 

					LET l_rec_orderdetl.status_ind = "4" 
					LET l_rec_orderdetl.sold_qty = 0 
					LET l_rec_orderdetl.required_qty = l_rec_orderdetl.required_qty	- (l_rec_orderdetl.back_qty	- l_rec_orderdetl.inv_qty) 
					LET l_rec_orderdetl.back_qty = l_rec_orderdetl.inv_qty 
					LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 

					IF l_upd_flag = -1 THEN 
						GOTO tryagain 
					END IF 

					IF l_upd_flag = 0 THEN 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						CLOSE WINDOW E455 
						RETURN FALSE 
					END IF
					 
					UPDATE t_orderdetl 
					SET 
						back_qty = l_rec_orderdetl.back_qty, 
						status_ind = l_rec_orderdetl.status_ind, 
						sold_qty = l_rec_orderdetl.sold_qty, 
						bonus_qty = 0, 
						order_qty = l_rec_orderdetl.inv_qty 
					WHERE line_num = l_rec_orderdetl.line_num 

					SELECT * INTO l_rec_orderdetl.* FROM t_orderdetl 
					WHERE line_num = l_rec_orderdetl.line_num 
					LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,"OUT",1) 
					IF l_upd_flag = -1 THEN 
						GOTO tryagain 
					END IF 
					IF l_upd_flag = 0 THEN 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						CLOSE WINDOW E455 
						RETURN FALSE 
					END IF 
				END FOREACH 
			COMMIT WORK 
			
			CLOSE WINDOW E455
			 
			RETURN FALSE 
		END IF 
	END IF 
	
	WHILE TRUE 
		MESSAGE kandoomsg2("U",1002,"") 	#1002 " Searching database - please wait"

		DECLARE c2_orderdetl cursor FOR 
		SELECT * FROM t_orderdetl 
		WHERE status_ind = "2" 
		AND back_qty > 0
		 
		LET l_idx = 0 
		FOREACH c2_orderdetl INTO l_rec_orderdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl.line_num 
			LET l_arr_rec_orderdetl[l_idx].offer_code = l_rec_orderdetl.offer_code 
			LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl.part_code 
			LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl.sold_qty 
			LET l_arr_rec_orderdetl[l_idx].back_qty = l_rec_orderdetl.back_qty 
			LET l_arr_other[l_idx].back_qty = 0 
			LET l_arr_partial[l_idx] = 0
			 
			IF glob_rec_opparms.cal_available_flag = "N" THEN 
				SELECT sum(back_qty) INTO l_back_qty FROM t_orderdetl 
				WHERE part_code = l_rec_orderdetl.part_code 
				LET l_arr_rec_orderdetl[l_idx].required_qty = 
					calc_avail(l_rec_orderdetl.*,0)	+ l_back_qty	- l_arr_partial[l_idx] 
			ELSE 
				LET l_arr_rec_orderdetl[l_idx].required_qty = 
					calc_avail(l_rec_orderdetl.*,0)- l_arr_partial[l_idx] 
			END IF 
			
			LET l_arr_rec_orderdetl[l_idx].status_ind = l_rec_orderdetl.status_ind
			 
			SELECT desc_text, desc2_text 
			INTO l_arr_other[l_idx].desc_text, l_arr_other[l_idx].desc2_text 
			FROM product 
			WHERE part_code = l_rec_orderdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_arr_other[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0) 
			LET l_arr_partial[l_idx] = 0 
		END FOREACH 

		ERROR kandoomsg2("U",9113,l_idx) #U9113 l_idx records selected

		IF l_idx = 0 THEN 
			LET l_idx = 1 
--			INITIALIZE l_arr_rec_orderdetl[l_idx].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		OPTIONS SQL INTERRUPT off 

		MESSAGE kandoomsg2("E",1167,"") #1167 " F2 Cancel Line;  F6 Partial Ship"
		INPUT ARRAY l_arr_rec_orderdetl WITHOUT DEFAULTS FROM sr_orderdetl.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11e","input-l_arr_rec_orderdetl-2") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

				DISPLAY l_arr_other[l_idx].desc_text TO desc_text
				DISPLAY l_arr_other[l_idx].desc2_text TO desc2_text 

				NEXT FIELD scroll_flag 
				
			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_orderdetl[l_idx].scroll_flag = NULL 

				IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("U",9001,"") 		#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 

				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_rec_orderdetl[l_idx+1].line_num IS NULL OR l_arr_rec_orderdetl[l_idx+1].line_num = 0 THEN 
						ERROR kandoomsg2("U",9001,"") 		#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

				IF fgl_lastkey() = fgl_keyval("nextpage")	
				AND (l_arr_rec_orderdetl[l_idx+12].line_num IS NULL	OR l_arr_rec_orderdetl[l_idx+12].line_num = 0) THEN 
					ERROR kandoomsg2("U",9001,"") 		#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 

			ON KEY (f2) #DELETE 
				IF l_arr_rec_orderdetl[l_idx].sold_qty <= 0 THEN 
					NEXT FIELD scroll_flag 
				END IF 
				
				INITIALIZE l_rec_orderdetl.* TO NULL 
				SELECT * INTO l_rec_orderdetl.* FROM t_orderdetl 
				WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 

				IF l_rec_orderdetl.autoinsert_flag = "Y" OR l_rec_orderdetl.autoinsert_flag = "*" THEN 
					ERROR kandoomsg2("E",9075,"") 		#9075 Not permitted TO delete automatic INSERT items
					NEXT FIELD scroll_flag 
				END IF 

				IF l_rec_orderdetl.inv_qty != 0 THEN 
					ERROR kandoomsg2("E",9076,"") 		#9076" Orderline has been Delivered - Deletion IS NOT Permitted "
					NEXT FIELD scroll_flag 
				END IF 

				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					SELECT sum(back_qty) INTO l_back_qty FROM t_orderdetl 
					WHERE part_code = l_rec_orderdetl.part_code 
					LET l_arr_rec_orderdetl[l_idx].required_qty = 
						calc_avail(l_rec_orderdetl.*,0)	+ l_back_qty - l_arr_partial[l_idx] 
				ELSE 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0)	- l_arr_partial[l_idx] 
				END IF 

				LET l_arr_partial[l_idx] = l_arr_partial[l_idx] 
				- (l_arr_rec_orderdetl[l_idx].sold_qty 
				- (l_rec_orderdetl.inv_qty 
				+ l_arr_rec_orderdetl[l_idx].back_qty)) 

				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					SELECT sum(back_qty) INTO l_back_qty FROM t_orderdetl 
					WHERE part_code = l_rec_orderdetl.part_code 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0)	+ l_back_qty	- l_arr_partial[l_idx] 
				ELSE 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0)- l_arr_partial[l_idx] 
				END IF 
				
				LET l_arr_rec_orderdetl[l_idx].status_ind = "4" 
				LET l_arr_rec_orderdetl[l_idx].sold_qty = 0 
				LET l_arr_rec_orderdetl[l_idx].back_qty = 0 
--
--				FOR i = 1 TO 200 
--					LET scrn = scrn + 1 
--					IF l_arr_rec_orderdetl[i].line_num IS NULL 
--					OR l_arr_rec_orderdetl[i].line_num = 0 THEN 
--						EXIT FOR 
--					END IF 
--					IF l_arr_rec_orderdetl[i].part_code = l_arr_rec_orderdetl[l_idx].part_code THEN 
--						IF i != l_idx THEN 
--							LET l_arr_rec_orderdetl[i].required_qty = 
--							l_arr_rec_orderdetl[l_idx].required_qty 
--							LET l_arr_partial[i] = l_arr_partial[l_idx] 
--						END IF 
--						IF scrn <= 12 THEN 
--							DISPLAY l_arr_rec_orderdetl[i].* TO sr_orderdetl[scrn].* 
--
--						END IF 
--					END IF 
--				END FOR 
				NEXT FIELD scroll_flag 

			ON KEY (f6) 
				IF l_arr_rec_orderdetl[l_idx].back_qty <= 0 THEN 
					NEXT FIELD scroll_flag 
				END IF 
				
				SELECT * 
				INTO l_rec_orderdetl.* 
				FROM t_orderdetl 
				WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num
				 
				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					SELECT sum(back_qty) 
					INTO l_back_qty 
					FROM t_orderdetl 
					WHERE part_code = l_rec_orderdetl.part_code 
					
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0) + l_back_qty - l_arr_partial[l_idx] 
				ELSE 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0)	- l_arr_partial[l_idx] 
				END IF
				 
				IF l_arr_rec_orderdetl[l_idx].required_qty <= 0 THEN 
					NEXT FIELD scroll_flag 
				END IF 
				LET l_sched_qty = l_arr_rec_orderdetl[l_idx].back_qty	- l_arr_rec_orderdetl[l_idx].required_qty
				 
				IF l_sched_qty <= 0 THEN 
					LET l_arr_rec_orderdetl[l_idx].status_ind = "0" 
					LET l_sched_qty = 0 
				ELSE 
					LET l_arr_rec_orderdetl[l_idx].status_ind = "2" 
				END IF
				 
				LET l_arr_rec_orderdetl[l_idx].back_qty = l_sched_qty 
				IF l_arr_other[l_idx].back_qty != 0 THEN 
					LET l_back_qty = l_arr_other[l_idx].back_qty 
				ELSE 
					LET l_back_qty = l_rec_orderdetl.back_qty 
				END IF 

				LET l_arr_partial[l_idx] = l_arr_partial[l_idx]	+ (l_back_qty	- l_arr_rec_orderdetl[l_idx].back_qty) 
				LET l_arr_other[l_idx].back_qty = l_arr_rec_orderdetl[l_idx].back_qty 

				IF glob_rec_opparms.cal_available_flag = "N" THEN 
					SELECT sum(back_qty) 
					INTO l_back_qty 
					FROM t_orderdetl 
					WHERE part_code = l_rec_orderdetl.part_code
					 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0) + l_back_qty - l_arr_partial[l_idx] 
				ELSE 
					LET l_arr_rec_orderdetl[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0) - l_arr_partial[l_idx] 
				END IF 

--				LET scrn = 0 
--				LET l_arr_other[l_idx].required_qty = calc_avail(l_rec_orderdetl.*,0) 
--				FOR i = 1 TO 200 
--					LET scrn = scrn + 1 
--					IF l_arr_rec_orderdetl[i].line_num IS NULL 
--					OR l_arr_rec_orderdetl[i].line_num = 0 THEN 
--						EXIT FOR 
--					END IF 
--					IF l_arr_rec_orderdetl[i].part_code = l_arr_rec_orderdetl[l_idx].part_code THEN 
--						IF i != l_idx THEN 
--							LET l_arr_rec_orderdetl[i].required_qty = 
--							l_arr_rec_orderdetl[l_idx].required_qty 
--							LET l_arr_partial[i] = l_arr_partial[l_idx] 
--							LET l_arr_other[i].required_qty = l_arr_other[l_idx].required_qty 
--						END IF 
--						IF scrn <= 12 THEN 
--							DISPLAY l_arr_rec_orderdetl[i].* TO sr_orderdetl[scrn].* 
--
--						END IF 
--					END IF 
--				END FOR 

				NEXT FIELD scroll_flag 

			BEFORE FIELD line_num 
				NEXT FIELD scroll_flag 

--			AFTER ROW 
--				DISPLAY l_arr_rec_orderdetl[l_idx].* TO sr_orderdetl[scrn].* 

	
		END INPUT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			CLOSE WINDOW E455 
			RETURN FALSE 
		END IF 
	
		MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please Wait.

		BEGIN WORK 
			FOR i = 1 TO arr_count() 
				INITIALIZE l_rec_orderdetl.* TO NULL 
				SELECT * INTO l_rec_orderdetl.* FROM t_orderdetl 
				WHERE line_num = l_arr_rec_orderdetl[i].line_num 
				IF l_arr_rec_orderdetl[i].back_qty != l_rec_orderdetl.back_qty THEN 
					IF l_arr_rec_orderdetl[i].status_ind = "4" THEN 
						### CANCELLED BACK ORDER LINES
						IF stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) = -1 THEN 
							CONTINUE WHILE 
						END IF 
						
						UPDATE t_orderdetl 
						SET 
							back_qty = l_arr_rec_orderdetl[i].back_qty, 
							status_ind = l_arr_rec_orderdetl[i].status_ind, 
							sold_qty = l_arr_rec_orderdetl[i].sold_qty, 
							bonus_qty = 0, 
							order_qty = l_rec_orderdetl.inv_qty 
						WHERE line_num = l_arr_rec_orderdetl[i].line_num 

						SELECT * 
						INTO l_rec_orderdetl.* 
						FROM t_orderdetl 
						WHERE line_num = l_arr_rec_orderdetl[i].line_num 

						IF stock_line(l_rec_orderdetl.line_num,"OUT",1) = -1 THEN 
							CONTINUE WHILE 
						END IF 
					ELSE 
						### PARTIALLY SHIPPED BACKORDER LINES
						### Check that the original available quantity still exists
						### IF NOT THEN rollback allwork
						LET l_available_qty = calc_avail(l_rec_orderdetl.*,0)
						 
						IF glob_rec_opparms.cal_available_flag = "N" THEN 
							SELECT sum(back_qty) INTO l_back_qty FROM t_orderdetl 
							WHERE part_code = l_rec_orderdetl.part_code
							 
							LET l_available_qty = l_available_qty	+ l_back_qty 
						END IF 

						IF l_available_qty < (l_rec_orderdetl.back_qty- l_arr_rec_orderdetl[i].back_qty) THEN 
							ROLLBACK WORK 
							ERROR kandoomsg2("E",7097,"") 		#7097 Stock qty have been reduced below required partial qty
							CONTINUE WHILE 
						END IF 
						
						LET l_arr_rec_orderdetl[i].required_qty = l_available_qty 
						LET l_sched_qty = l_arr_rec_orderdetl[i].sold_qty	- l_arr_rec_orderdetl[i].back_qty	- l_rec_orderdetl.inv_qty 

						IF stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) = -1 THEN 
							CONTINUE WHILE 
						END IF 

						UPDATE t_orderdetl 
						SET 
							back_qty = l_arr_rec_orderdetl[i].back_qty, 
							status_ind = l_arr_rec_orderdetl[i].status_ind, 
							sched_qty = l_sched_qty, 
							required_qty = l_arr_rec_orderdetl[i].required_qty 
						WHERE line_num = l_arr_rec_orderdetl[i].line_num 

						SELECT * 
						INTO l_rec_orderdetl.* 
						FROM t_orderdetl 
						WHERE line_num = l_arr_rec_orderdetl[i].line_num 

						IF stock_line(l_rec_orderdetl.line_num,"OUT",1) = -1 THEN 
							CONTINUE WHILE 
						END IF 

					END IF 
				END IF 
			END FOR 

		COMMIT WORK 

		EXIT WHILE 
	END WHILE 
	
	CLOSE WINDOW E455
	 
	RETURN TRUE 
END FUNCTION
###########################################################################
# END FUNCTION validate_backorder() 
###########################################################################