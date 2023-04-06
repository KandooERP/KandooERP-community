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
# FUNCTION header_entry(p_mode)
#
#
###########################################################################
FUNCTION header_entry(p_mode) 
	DEFINE p_mode char(4) 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_customership2 RECORD LIKE customership.* 
	DEFINE l_rec_corporate RECORD LIKE customer.* 
	DEFINE l_rec_corp_name_text LIKE customer.name_text 
	DEFINE l_rec_corpcust RECORD LIKE customer.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_supp_ware_text LIKE warehouse.desc_text 
	DEFINE l_ship_code LIKE customership.ship_code 
	DEFINE l_ship_cust_code LIKE customership.cust_code 
	DEFINE l_save_char char(1) 
	DEFINE i SMALLINT 
	DEFINE l_inv_addr_for_ship BOOLEAN
	
	IF glob_rec_orderhead.cust_code IS NOT NULL THEN
		CALL db_customer_get_rec(UI_OFF,glob_rec_orderhead.cust_code) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* 
--		FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = glob_rec_orderhead.cust_code 
		IF glob_rec_customer.cust_code IS NULL THEN
			ERROR kandoomsg2("E",9052,"") 	#9052 Sales Order Customer NOT found"
			LET glob_rec_customer.name_text = "**********" 
		END IF 

		IF glob_rec_customer.delete_flag = "Y" THEN 
			ERROR kandoomsg2("A",7022,glob_rec_customer.name_text) 	#7022 Customer ???? has been marked FOR deletion
			LET glob_rec_customer.name_text = "**********" 
		END IF 

		LET l_rec_customership.ship_code = glob_rec_orderhead.ship_code 
	END IF 

	IF glob_rec_orderhead.sales_code IS NOT NULL THEN

		CALL db_salesperson_get_name_text(UI_OFF,glob_rec_orderhead.sales_code) RETURNING l_rec_salesperson.name_text
		IF sqlca.sqlcode != 0 THEN
			LET l_rec_salesperson.name_text = "**********" 
		END IF 
							 
		DISPLAY l_rec_salesperson.name_text TO sale_text 
	END IF 
	
	IF glob_rec_orderhead.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_warehouse.desc_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = glob_rec_orderhead.ware_code 
		IF status = NOTFOUND THEN 
			LET l_rec_warehouse.desc_text = "**********" 
		END IF 

		DISPLAY BY NAME l_rec_warehouse.desc_text 

	END IF 

	MESSAGE kandoomsg2("E",1015,"") #1015 Enter Sales Order Details - F5 Customer Inquiry - F9 Account Details "

	INPUT BY NAME 
		glob_rec_orderhead.cust_code, 
		glob_rec_orderhead.order_date, 
		glob_rec_orderhead.invoice_to_ind, 
		glob_rec_orderhead.ship_code, 
		glob_rec_orderhead.ship_name_text, 
		glob_rec_orderhead.ship_addr1_text, 
		glob_rec_orderhead.ship_addr2_text, 
		glob_rec_orderhead.ship_city_text, 
		glob_rec_orderhead.state_code, 
		glob_rec_orderhead.post_code, 
		glob_rec_orderhead.country_code, --@db-patch_2020_10_04--
		--glob_rec_customer.comment_text,  #Feature request from Anna
		glob_rec_orderhead.ord_text, 
		glob_rec_orderhead.sales_code, 
		glob_rec_orderhead.ware_code, 
		glob_rec_sales_order_parameter.suppl_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11a","input-glob_rec_orderhead-1") -- albo kd-502 
			
			DISPLAY BY NAME glob_rec_customer.name_text
			 
			CALL db_country_localize(glob_rec_orderhead.country_code) #Localize

			INITIALIZE l_rec_corporate.* TO NULL #???
			 
			IF glob_rec_customer.corp_cust_code IS NOT NULL THEN 
				SELECT * INTO l_rec_corporate.* FROM customer 
				WHERE cust_code = glob_rec_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			LET l_rec_corp_name_text = l_rec_corporate.name_text 

			DISPLAY 
				glob_rec_customer.name_text, 
				glob_rec_customer.corp_cust_code, 
				l_rec_corp_name_text, 
				glob_rec_customer.addr1_text, 
				glob_rec_customer.addr2_text, 
				glob_rec_customer.city_text, 
				glob_rec_customer.state_code, 
				glob_rec_customer.post_code, 
				glob_rec_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

			IF p_mode = "EDIT" THEN 
				SELECT count(*) INTO i 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_orderhead.cust_code 
				DISPLAY i TO ship_count 

				DISPLAY glob_rec_orderhead.order_num TO order_num
				DISPLAY glob_rec_orderhead.last_inv_date TO last_inv_date

			END IF 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
			 
		ON ACTION "REFRESH"
			 CALL windecoration_e("E111")
				
		ON ACTION "LOOKUP" infield(cust_code) #ON KEY (control-b) 
					LET glob_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.cust_code = glob_temp_text 
					END IF 
					NEXT FIELD cust_code
					 
		ON ACTION "LOOKUP" infield(ship_code) 
					LET glob_temp_text = show_ship(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.ship_code = glob_temp_text 
						SELECT * INTO l_rec_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						AND ship_code = glob_rec_orderhead.ship_code 
						LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						LET glob_rec_orderhead.ware_code = l_rec_customership.ware_code 
						LET glob_rec_orderhead.ship_name_text = l_rec_customership.name_text 
						LET glob_rec_orderhead.ship_addr1_text = l_rec_customership.addr_text 
						LET glob_rec_orderhead.ship_addr2_text = l_rec_customership.addr2_text 
						LET glob_rec_orderhead.ship_city_text = l_rec_customership.city_text 
						LET glob_rec_orderhead.state_code = l_rec_customership.state_code 
						LET glob_rec_orderhead.post_code = l_rec_customership.post_code 
						LET glob_rec_orderhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
						LET glob_rec_orderhead.contact_text = l_rec_customership.contact_text 
						LET glob_rec_orderhead.tele_text = l_rec_customership.tele_text 
						LET glob_rec_orderhead.mobile_phone = l_rec_customership.mobile_phone
						LET glob_rec_orderhead.email = l_rec_customership.email						
					END IF 
					NEXT FIELD ship_code 
					
		ON ACTION "LOOKUP" infield(sales_code) 
					LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.sales_code = glob_temp_text 
					END IF 
					NEXT FIELD sales_code 

		ON ACTION "LOOKUP" infield(ware_code) 
					LET glob_temp_text = show_ware(glob_rec_kandoouser.cmpy_code)
					 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.ware_code = glob_temp_text 
					END IF
					 
					NEXT FIELD ware_code 

		ON ACTION "LOOKUP" infield(ship_name_text) 
					CALL show_cust_ship(glob_rec_kandoouser.cmpy_code) RETURNING l_ship_cust_code,	l_ship_code 

					IF l_ship_cust_code IS NOT NULL 
					AND l_ship_code IS NOT NULL THEN 

						SELECT * INTO l_rec_customership2.* FROM customership 
						WHERE cust_code = l_ship_cust_code 
						AND ship_code = l_ship_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = 0 THEN 
							LET glob_rec_orderhead.ship_name_text = l_rec_customership2.name_text 
							LET glob_rec_orderhead.ship_addr1_text = l_rec_customership2.addr_text 
							LET glob_rec_orderhead.ship_addr2_text = l_rec_customership2.addr2_text 
							LET glob_rec_orderhead.ship_city_text =	l_rec_customership2.city_text 
							LET glob_rec_orderhead.state_code = l_rec_customership2.state_code 
							LET glob_rec_orderhead.post_code = l_rec_customership2.post_code 
							LET glob_rec_orderhead.country_code=	l_rec_customership2.country_code --@db-patch_2020_10_04-- 
							LET glob_rec_orderhead.contact_text =	l_rec_customership.contact_text 
							LET glob_rec_orderhead.tele_text = l_rec_customership2.tele_text 
							LET glob_rec_orderhead.mobile_phone = l_rec_customership2.mobile_phone
							LET glob_rec_orderhead.email = l_rec_customership2.email
							LET glob_rec_orderhead.ship_code = NULL 
							LET glob_rec_orderhead.ware_code = l_rec_customership2.ware_code 

							INITIALIZE l_rec_warehouse.* TO NULL 

							SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = glob_rec_orderhead.ware_code 

							DISPLAY BY NAME 
								glob_rec_orderhead.ship_code, 
								l_rec_warehouse.desc_text, 
								glob_rec_orderhead.ship_name_text, 
								glob_rec_orderhead.ship_addr1_text, 
								glob_rec_orderhead.ship_addr2_text, 
								glob_rec_orderhead.ship_city_text, 
								glob_rec_orderhead.state_code, 
								glob_rec_orderhead.post_code, 
								glob_rec_orderhead.country_code, --@db-patch_2020_10_04--
								glob_rec_orderhead.ware_code 

						END IF 
					END IF 
					NEXT FIELD ship_name_text 

		ON ACTION "DETAIL" --ON KEY (f5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) --customer details / customer invoice submenu 

		ON ACTION "PAYMENT DETAILS" --ON KEY (f9) 
			IF glob_rec_orderhead.cust_code IS NOT NULL THEN 
				LET l_save_char = glob_rec_sales_order_parameter.paydetl_flag 
				LET glob_rec_sales_order_parameter.paydetl_flag = glob_yes_flag
				 
				IF pay_detail() THEN 
				END IF
				 
				LET glob_rec_sales_order_parameter.paydetl_flag = l_save_char 
			END IF 

		ON CHANGE country_code
			CALL db_country_localize(glob_rec_orderhead.country_code) --@db-patch_2020_10_04-- #Localize
			
		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_orderhead.cust_code) TO customer.name_text 
			
		AFTER FIELD cust_code 
			IF glob_rec_orderhead.cust_code IS NULL THEN 
				ERROR kandoomsg2("E",9051,"")		#9051" Cust. must be Entered"
				LET glob_rec_orderhead.cust_code = glob_rec_customer.cust_code 
				CLEAR name_text 
				NEXT FIELD cust_code 
			ELSE 
				IF (glob_rec_customer.cust_code != glob_rec_orderhead.cust_code) OR (glob_rec_customer.cust_code IS null) THEN 

					SELECT * INTO glob_rec_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_orderhead.cust_code 
					AND delete_flag = "N"
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9052,"") 		#9052" Cust NOT found - Try Window"
						NEXT FIELD cust_code 
					ELSE 

						IF glob_rec_customer.delete_flag <> "N" THEN 
							ERROR kandoomsg2("E",9268,"") 			#9052" Cust has been deleted - Try Window"
							INITIALIZE glob_rec_customer.* TO NULL 

							NEXT FIELD cust_code 
						END IF 

						IF glob_rec_customer.hold_code IS NOT NULL THEN 
							SELECT reason_text INTO glob_temp_text FROM holdreas 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND hold_code = glob_rec_customer.hold_code 

							LET glob_rec_orderhead.hold_code = glob_rec_customer.hold_code 
							ERROR kandoomsg2("E",7018,glob_temp_text) 						#7018" Warning : Nominated Customer 'On Hold'"
						END IF 

						IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
							SELECT * INTO l_rec_corpcust.* 
							FROM customer 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = glob_rec_customer.corp_cust_code 

							IF sqlca.sqlcode = 0 THEN 
								IF l_rec_corpcust.hold_code IS NOT NULL THEN 
									SELECT reason_text INTO glob_temp_text 
									FROM holdreas 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND hold_code = l_rec_corpcust.hold_code 

									LET glob_rec_orderhead.hold_code = l_rec_corpcust.hold_code 
									ERROR kandoomsg2("E",7040,glob_temp_text) 				#7040 Warning :Corporate Customer 'On Hold'"
								END IF 

								IF l_rec_corpcust.cred_override_ind = 0 THEN 
									IF l_rec_corpcust.cred_bal_amt < 0 THEN 
										LET glob_rec_orderhead.hold_code =	glob_rec_opparms.lim_hold_code 
										ERROR kandoomsg2("E",7041,"") 				#7041 Warning: Corp Customer has exceeded credit
									END IF 
								END IF 

							END IF 

						END IF 

						IF glob_rec_customer.cred_override_ind = 0 THEN 
							IF glob_rec_customer.cred_bal_amt < 0 THEN 
								LET glob_rec_orderhead.hold_code = glob_rec_opparms.lim_hold_code 
								ERROR kandoomsg2("E",7019,"") 			#7019 Warning : Nominated Customer has exceeded credit
							END IF 
						END IF 

						LET glob_rec_orderhead.term_code = glob_rec_customer.term_code 
						LET glob_rec_orderhead.tax_code = glob_rec_customer.tax_code 
						LET glob_rec_orderhead.hand_tax_code = glob_rec_customer.tax_code 
						LET glob_rec_orderhead.freight_tax_code = glob_rec_customer.tax_code 
						LET glob_rec_orderhead.sales_code = glob_rec_customer.sale_code 
						LET glob_rec_orderhead.territory_code = glob_rec_customer.territory_code 
						LET glob_rec_orderhead.cond_code = glob_rec_customer.cond_code 
						LET glob_rec_orderhead.invoice_to_ind = glob_rec_customer.invoice_to_ind 
						LET glob_rec_orderhead.currency_code = glob_rec_customer.currency_code 

						SELECT count(*) INTO i 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						DISPLAY i TO ship_count 

						CASE 
							WHEN i = 0 
								MESSAGE kandoomsg2("E",9053,"") 			#9053 No shipping addresses exist FOR this customer"
								LET glob_rec_orderhead.ship_code = NULL 

							WHEN i = 1 
								SELECT ship_code 
								INTO glob_rec_orderhead.ship_code 
								FROM customership 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code = glob_rec_orderhead.cust_code 

							OTHERWISE 
								SELECT unique 1 FROM customership 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code = glob_rec_orderhead.cust_code 
								AND ship_code = glob_rec_orderhead.cust_code 
								IF sqlca.sqlcode = NOTFOUND THEN 
									DECLARE c_custship cursor FOR 
									SELECT ship_code FROM customership 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND cust_code = glob_rec_orderhead.cust_code 
									OPEN c_custship 
									FETCH c_custship INTO glob_rec_orderhead.ship_code 
								ELSE 
									LET glob_rec_orderhead.ship_code = glob_rec_orderhead.cust_code 
								END IF 
						END CASE 

						INITIALIZE l_rec_customership.* TO NULL 

						SELECT * INTO l_rec_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						AND ship_code = glob_rec_orderhead.ship_code 

						LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						LET glob_rec_orderhead.ware_code = l_rec_customership.ware_code 
						LET glob_rec_orderhead.ship_name_text = l_rec_customership.name_text 
						LET glob_rec_orderhead.ship_addr1_text = l_rec_customership.addr_text 
						LET glob_rec_orderhead.ship_addr2_text = l_rec_customership.addr2_text 
						LET glob_rec_orderhead.ship_city_text = l_rec_customership.city_text 
						LET glob_rec_orderhead.state_code = l_rec_customership.state_code 
						LET glob_rec_orderhead.post_code = l_rec_customership.post_code 
						LET glob_rec_orderhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
						LET glob_rec_orderhead.contact_text = l_rec_customership.contact_text 
						LET glob_rec_orderhead.tele_text = l_rec_customership.tele_text 
						LET glob_rec_orderhead.mobile_phone = l_rec_customership.mobile_phone 
						LET glob_rec_orderhead.email = l_rec_customership.email						

						SELECT desc_text INTO l_rec_warehouse.desc_text 
						FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = glob_rec_orderhead.ware_code 
						IF status = NOTFOUND THEN 
							LET l_rec_warehouse.desc_text = "**********" 
						END IF 

						#get sales person record	 
						CALL db_salesperson_get_rec(UI_OFF,glob_rec_orderhead.sales_code ) RETURNING l_rec_salesperson.*
				
						IF l_rec_salesperson.sale_code IS NULL THEN 
							LET l_rec_salesperson.name_text = "**********" 
						END IF 

						DISPLAY l_rec_salesperson.name_text TO sale_text 

						IF glob_rec_sales_order_parameter.suppl_flag = glob_yes_flag THEN 
							LET glob_rec_sales_order_parameter.supp_ware_code = l_rec_salesperson.ware_code 

							SELECT desc_text INTO l_supp_ware_text 
							FROM warehouse 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = glob_rec_sales_order_parameter.supp_ware_code 
							IF status = NOTFOUND THEN 
								LET l_supp_ware_text = "**********" 
							END IF 

							DISPLAY BY NAME 
								glob_rec_sales_order_parameter.supp_ware_code, 
								l_supp_ware_text 

						END IF 
					END IF 
				END IF 
			END IF 

			DISPLAY BY NAME 
				glob_rec_orderhead.order_date, 
				glob_rec_orderhead.cust_code, 
				glob_rec_customer.name_text, 
				glob_rec_orderhead.ship_code, 
				glob_rec_orderhead.ship_name_text, 
				glob_rec_orderhead.ship_addr1_text, 
				glob_rec_orderhead.ship_addr2_text, 
				glob_rec_orderhead.ship_city_text, 
				glob_rec_orderhead.state_code, 
				glob_rec_orderhead.post_code, 
				glob_rec_orderhead.country_code, --@db-patch_2020_10_04--
				glob_rec_orderhead.invoice_to_ind, 
				glob_rec_orderhead.sales_code, 
				glob_rec_orderhead.ware_code, 
				glob_rec_customer.comment_text, 
				l_rec_warehouse.desc_text 

			INITIALIZE l_rec_corporate.* TO NULL 

			IF glob_rec_customer.corp_cust_code IS NOT NULL THEN 
				SELECT * INTO l_rec_corporate.* FROM customer 
				WHERE cust_code = glob_rec_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			LET l_rec_corp_name_text = l_rec_corporate.name_text 

			DISPLAY 
				glob_rec_customer.name_text, 
				glob_rec_customer.corp_cust_code, 
				l_rec_corp_name_text, 
				glob_rec_customer.addr1_text, 
				glob_rec_customer.addr2_text, 
				glob_rec_customer.city_text, 
				glob_rec_customer.state_code, 
				glob_rec_customer.post_code, 
				glob_rec_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

		AFTER FIELD order_date 
			IF glob_rec_orderhead.order_date IS NULL THEN 
				LET glob_rec_orderhead.order_date = glob_rec_sales_order_parameter.order_date 
				NEXT FIELD order_date 
			END IF

		ON CHANGE ship_code
			IF glob_rec_orderhead.ship_code IS NOT NULL THEN 
				IF glob_rec_orderhead.ship_code != l_rec_customership.ship_code	OR l_rec_customership.ship_code IS NULL THEN 
					SELECT * INTO l_rec_customership.* 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_orderhead.cust_code 
					AND ship_code = glob_rec_orderhead.ship_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9054,"") 		#9054" shipping NOT found, try window"
						--LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						--NEXT FIELD ship_code 
					ELSE 
						LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						LET glob_rec_orderhead.ware_code = l_rec_customership.ware_code 

						INITIALIZE l_rec_warehouse.desc_text TO NULL 
						SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = glob_rec_orderhead.ware_code 

						DISPLAY glob_rec_orderhead.ware_code TO ware_code
						DISPLAY l_rec_warehouse.desc_text TO desc_text 

						DISPLAY l_rec_customership.name_text TO ship_name_text 
						DISPLAY l_rec_customership.addr_text TO ship_addr1_text 
						DISPLAY l_rec_customership.addr2_text TO ship_addr2_text 
						DISPLAY l_rec_customership.city_text TO ship_city_text 
						DISPLAY l_rec_customership.state_code TO state_code 
						DISPLAY l_rec_customership.post_code TO post_code 
						DISPLAY l_rec_customership.country_code TO country_code --@db-patch_2020_10_04--
						--DISPLAY l_rec_customership.contact_text TO contact_text 
						--DISPLAY l_rec_customership.tele_text TO tele_text 
						--DISPLAY l_rec_customership.mobile_phone TO mobile_phone						
						--DISPLAY l_rec_customership.email TO email						

					END IF 
				END IF
			END IF 
					 
		AFTER FIELD ship_code 
			IF glob_rec_orderhead.ship_code IS NOT NULL THEN 
				IF glob_rec_orderhead.ship_code != l_rec_customership.ship_code	OR l_rec_customership.ship_code IS NULL THEN 
					SELECT * INTO l_rec_customership.* 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_orderhead.cust_code 
					AND ship_code = glob_rec_orderhead.ship_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9054,"") 		#9054" shipping NOT found, try window"
						LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						NEXT FIELD ship_code 
					ELSE 
						LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
						LET glob_rec_orderhead.ware_code = l_rec_customership.ware_code 

						INITIALIZE l_rec_warehouse.desc_text TO NULL 
						SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = glob_rec_orderhead.ware_code 

						DISPLAY glob_rec_orderhead.ware_code TO ware_code
						DISPLAY l_rec_warehouse.desc_text TO desc_text 

						LET glob_rec_orderhead.ship_name_text = l_rec_customership.name_text 
						LET glob_rec_orderhead.ship_addr1_text = l_rec_customership.addr_text 
						LET glob_rec_orderhead.ship_addr2_text = l_rec_customership.addr2_text 
						LET glob_rec_orderhead.ship_city_text = l_rec_customership.city_text 
						LET glob_rec_orderhead.state_code = l_rec_customership.state_code 
						LET glob_rec_orderhead.post_code = l_rec_customership.post_code 
						LET glob_rec_orderhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
						LET glob_rec_orderhead.contact_text = l_rec_customership.contact_text 
						LET glob_rec_orderhead.tele_text = l_rec_customership.tele_text 
						LET glob_rec_orderhead.mobile_phone = l_rec_customership.mobile_phone						
						LET glob_rec_orderhead.email = l_rec_customership.email						

					END IF 
				END IF 

			ELSE 

				IF glob_rec_orderhead.ship_code IS NULL THEN
					IF promptTF("",kandoomsg2("E",8032,""),1) THEN ## No ship address entered - use customer address
						LET glob_rec_orderhead.ship_name_text = glob_rec_customer.name_text 
						LET glob_rec_orderhead.ship_addr1_text = glob_rec_customer.addr1_text 
						LET glob_rec_orderhead.ship_addr2_text = glob_rec_customer.addr2_text 
						LET glob_rec_orderhead.ship_city_text = glob_rec_customer.city_text 
						LET glob_rec_orderhead.state_code = glob_rec_customer.state_code 
						LET glob_rec_orderhead.post_code = glob_rec_customer.post_code 
						LET glob_rec_orderhead.country_code = glob_rec_customer.country_code --@db-patch_2020_10_04--

						NEXT FIELD ship_addr1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD ship_addr1_text 
			IF glob_rec_orderhead.ship_name_text IS NOT NULL THEN 
				DISPLAY BY NAME 
					glob_rec_orderhead.ship_code, 
					glob_rec_orderhead.ship_name_text, 
					glob_rec_orderhead.ship_addr1_text, 
					glob_rec_orderhead.ship_addr2_text, 
					glob_rec_orderhead.ship_city_text, 
					glob_rec_orderhead.state_code, 
					glob_rec_orderhead.post_code, 
					glob_rec_orderhead.country_code, --@db-patch_2020_10_04--
					glob_rec_orderhead.ware_code 

			END IF 

		AFTER FIELD sales_code 
			CLEAR sale_text 

			IF glob_rec_orderhead.sales_code IS NULL THEN 
				ERROR kandoomsg2("E",9062,"") 	#9062 Saelsperson code must be entered "
				NEXT FIELD sales_code 
			END IF 

			#get sales person record	 
			CALL db_salesperson_get_rec(UI_OFF,glob_rec_orderhead.sales_code ) RETURNING l_rec_salesperson.*
	
			IF l_rec_salesperson.sale_code IS NULL THEN 
				ERROR kandoomsg2("E",9050,"") 	#9050 Sales ORDER salesperson NOT found - Try Window "
				NEXT FIELD sales_code 
			END IF 

			DISPLAY l_rec_salesperson.name_text TO sale_text 

			LET glob_rec_orderhead.mgr_code = l_rec_salesperson.mgr_code 

		AFTER FIELD ware_code 
			CLEAR desc_text 

			IF glob_rec_orderhead.ware_code IS NULL THEN 
				ERROR kandoomsg2("E",9046,"") 		#9046 Warehouse code must be entered "
				NEXT FIELD ware_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_orderhead.ware_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9047,"") 			#9047 Warehouse Code NOT found - Try Window "
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY BY NAME l_rec_warehouse.desc_text 
				END IF 
			END IF 

		AFTER FIELD suppl_flag 
			LET glob_rec_orderhead.pre_delivery_ind = glob_rec_sales_order_parameter.suppl_flag 
			IF glob_rec_sales_order_parameter.suppl_flag = glob_yes_flag THEN 
				IF l_rec_salesperson.ware_code IS NULL THEN 
					IF glob_rec_orderhead.sales_code IS NULL THEN 
						ERROR kandoomsg2("E",7017,"") 		#7017"ORDER does NOT have a valid salesperson"
					ELSE 
						ERROR kandoomsg2("E",7016,"") 			#7016"salesperson doesn't have a valid warehouse
					END IF 
					LET glob_rec_sales_order_parameter.supp_ware_code = glob_rec_orderhead.ware_code 
				ELSE 
					LET glob_rec_sales_order_parameter.supp_ware_code = l_rec_salesperson.ware_code 
				END IF 

				SELECT desc_text 
				INTO l_supp_ware_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_sales_order_parameter.supp_ware_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",7016,"") 	#7016"Salesperson does NOT have a valid warehouse
					LET glob_rec_sales_order_parameter.supp_ware_code = glob_rec_orderhead.ware_code 
					LET l_supp_ware_text = l_rec_warehouse.desc_text 
				END IF 

				IF glob_rec_orderhead.ware_code != glob_rec_sales_order_parameter.supp_ware_code THEN 

					menu"Pre-Delivery warehouse" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","E11a","menu-Pre-Delivery-1") -- albo kd-370 

						ON ACTION "WEB-HELP" -- albo kd-370 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 
			
						COMMAND key(INTERRUPT) glob_rec_orderhead.ware_code	l_rec_warehouse.desc_text  #menu label and description text
							LET glob_rec_sales_order_parameter.supp_ware_code = glob_rec_orderhead.ware_code 
							LET l_supp_ware_text = l_rec_warehouse.desc_text 
							EXIT MENU 

						COMMAND glob_rec_sales_order_parameter.supp_ware_code l_supp_ware_text  #menu label and description text
							EXIT MENU 
					END MENU 

					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					--               CLOSE WINDOW w1  -- albo  KD-755
				END IF 

				DISPLAY glob_rec_sales_order_parameter.supp_ware_code TO supp_ware_code
				DISPLAY l_supp_ware_text TO supp_ware_text 

				SLEEP 1 
			ELSE 
				CLEAR supp_ware_code,l_supp_ware_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_orderhead.ship_date IS NULL THEN 
					LET glob_rec_orderhead.ship_date = glob_rec_orderhead.order_date 
				END IF
				
				#warehouse 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_orderhead.ware_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9047,"") 				#9047 Warehouse Code NOT found - Try Window "
					NEXT FIELD ware_code 
				END IF

				#delivery address
				IF glob_rec_orderhead.ship_code IS NOT NULL THEN 
					IF glob_rec_orderhead.ship_code != l_rec_customership.ship_code	OR l_rec_customership.ship_code IS NULL THEN 
						SELECT * INTO l_rec_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_orderhead.cust_code 
						AND ship_code = glob_rec_orderhead.ship_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("E",9054,"") 		#9054" shipping NOT found, try window"
							LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
							NEXT FIELD ship_code 
						ELSE 
							LET glob_rec_orderhead.ship_code = l_rec_customership.ship_code 
							LET glob_rec_orderhead.ware_code = l_rec_customership.ware_code 
	
							INITIALIZE l_rec_warehouse.desc_text TO NULL 
							SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = glob_rec_orderhead.ware_code 
	
							DISPLAY BY NAME 
								glob_rec_orderhead.ware_code, 
								l_rec_warehouse.desc_text 
	
							LET glob_rec_orderhead.ship_name_text = l_rec_customership.name_text 
							LET glob_rec_orderhead.ship_addr1_text = l_rec_customership.addr_text 
							LET glob_rec_orderhead.ship_addr2_text = l_rec_customership.addr2_text 
							LET glob_rec_orderhead.ship_city_text = l_rec_customership.city_text 
							LET glob_rec_orderhead.state_code = l_rec_customership.state_code 
							LET glob_rec_orderhead.post_code = l_rec_customership.post_code 
							LET glob_rec_orderhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
							LET glob_rec_orderhead.contact_text = l_rec_customership.contact_text 
							LET glob_rec_orderhead.tele_text = l_rec_customership.tele_text 
							LET glob_rec_orderhead.mobile_phone = l_rec_customership.mobile_phone						
							LET glob_rec_orderhead.email = l_rec_customership.email						
	
						END IF 
					END IF 
	
				ELSE 
	
					IF glob_rec_orderhead.ship_code IS NULL AND l_inv_addr_for_ship = FALSE THEN
						IF promptTF("",kandoomsg2("E",8032,""),1) THEN ## No ship address entered - use customer address
							LET l_inv_addr_for_ship = TRUE
							LET glob_rec_orderhead.ship_name_text = glob_rec_customer.name_text 
							LET glob_rec_orderhead.ship_addr1_text = glob_rec_customer.addr1_text 
							LET glob_rec_orderhead.ship_addr2_text = glob_rec_customer.addr2_text 
							LET glob_rec_orderhead.ship_city_text = glob_rec_customer.city_text 
							LET glob_rec_orderhead.state_code = glob_rec_customer.state_code 
							LET glob_rec_orderhead.post_code = glob_rec_customer.post_code 
							LET glob_rec_orderhead.country_code = glob_rec_customer.country_code --@db-patch_2020_10_04--
	
							--NEXT FIELD ship_addr1_text 
						END IF 
					ELSE
						#all fine.. using invoice address as delivery address
					END IF 
				END IF 
	
				#get sales person record	 
				CALL db_salesperson_get_rec(UI_OFF,glob_rec_orderhead.sales_code ) RETURNING l_rec_salesperson.*
		
				IF l_rec_salesperson.sale_code IS NULL THEN  
					ERROR kandoomsg2("E",9050,"") 			#9050 Sales ORDER salesperson NOT found - Try Window "
					NEXT FIELD sales_code 
				END IF
				 
				LET glob_rec_orderhead.mgr_code = l_rec_salesperson.mgr_code
				
				#supplier and again warehouse ? 
				IF glob_rec_sales_order_parameter.suppl_flag = glob_yes_flag THEN 
					SELECT unique 1 FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = glob_rec_sales_order_parameter.supp_ware_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9089,"") 		#9089 Pre delivered Warehouse Invalid
						NEXT FIELD suppl_flag 
					END IF 
				END IF
				
				#Order text 
				IF glob_rec_orderhead.ord_text IS NULL THEN 
					IF glob_rec_customer.ord_text_ind = "Y" THEN 
						ERROR kandoomsg2("U",9102,"") 
						NEXT FIELD ord_text 
					END IF 
				END IF
				 
				IF NOT pay_detail() THEN 
					NEXT FIELD cust_code 
				END IF 
			END IF 

	END INPUT #-------------------------------------------------------------------------------------------------------- 

	IF int_flag OR quit_flag THEN 
		IF p_mode = "EDIT" THEN 
			SELECT * INTO glob_rec_orderhead.* 
			FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = glob_rec_orderhead.order_num 
			IF glob_rec_orderhead.status_ind = "X" THEN 
				SELECT unique 1 FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = glob_rec_orderhead.order_num 
				AND order_qty <> inv_qty 
				AND status_ind <> "4" 
				IF status = NOTFOUND THEN 
					LET glob_rec_orderhead.status_ind = "C" 
				ELSE 
					SELECT unique 1 FROM orderdetl 
					WHERE order_num = glob_rec_orderhead.order_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_qty <> 0 
					IF status = 0 THEN 
						LET glob_rec_orderhead.status_ind = "P" 
					ELSE 
						LET glob_rec_orderhead.status_ind = "U" 
					END IF 
				END IF 
				UPDATE orderhead SET status_ind = glob_rec_orderhead.status_ind 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = glob_rec_orderhead.order_num 
			END IF 
		END IF 
		
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION header_entry(p_mode)
############################################################


###########################################################################
# FUNCTION view_cust(p_cust_code)
#
#
###########################################################################
FUNCTION view_cust(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_availcr_amt LIKE customer.bal_amt 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_cust_code 
	IF sqlca.sqlcode = 0 THEN 
		LET l_availcr_amt = l_rec_customer.cred_limit_amt 
		- l_rec_customer.bal_amt 
		- l_rec_customer.onorder_amt
		 
		OPEN WINDOW E113 with FORM "E113" 
		 CALL windecoration_e("E113") 
 
		DISPLAY BY NAME l_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

		DISPLAY BY NAME 
			l_rec_customer.curr_amt, 
			l_rec_customer.over1_amt, 
			l_rec_customer.over30_amt, 
			l_rec_customer.over60_amt, 
			l_rec_customer.over90_amt, 
			l_rec_customer.cred_limit_amt, 
			l_rec_customer.onorder_amt, 
			l_rec_customer.last_pay_date 

		DISPLAY l_rec_customer.bal_amt TO sr_balance[1].bal_amt 
		DISPLAY l_rec_customer.bal_amt TO sr_balance[2].bal_amt 
		DISPLAY l_availcr_amt TO availcr_amt 
		
		CALL eventsuspend() #("U",1,"")

		CLOSE WINDOW E113 
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION view_cust(p_cust_code)
############################################################

############################################################
# FUNCTION db_prodstatus_show_availability(p_cmpy_code,p_ware_code,p_part_code)
#
#
############################################################
FUNCTION db_prodstatus_show_availability(p_cmpy_code,p_ware_code,p_part_code,p_select_tab)
	DEFINE p_cmpy_code LIKE prodstatus.cmpy_code
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_part_code LIKE prodstatus.part_code
	DEFINE p_select_tab STRING
	DEFINE tab ui.Tab
	DEFINE tabPage ui.TabPage
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	
	CALL db_prodstatus_get_rec(UI_ON,p_ware_code,p_part_code) RETURNING l_rec_prodstatus.*
	
	IF l_rec_prodstatus.part_code IS NOT NULL THEN
		OPEN WINDOW E501_prodstatus_availability WITH FORM "E501_prodstatus_availability" ATTRIBUTE(BORDER,STYLE="CENTER")

		LET p_select_tab = p_select_tab.toUpperCase()
		LET p_select_tab = "tab_page_", trim(p_select_tab)
	
		LET tab = ui.Tab.forname("tab_prodstatus")		
		#LET tabPage = ui.TabPage.forname("tab_page_availability")
		LET tabPage = ui.TabPage.forname(p_select_tab) #tab_page_availability
		CALL tab.SetSelectedTabPage(tabPage)
				
		DISPLAY l_rec_prodstatus.cmpy_code TO prodstatus.cmpy_code
		DISPLAY l_rec_prodstatus.ware_code TO prodstatus.ware_code
		DISPLAY l_rec_prodstatus.part_code TO prodstatus.part_code
		DISPLAY l_rec_prodstatus.onhand_qty TO prodstatus.onhand_qty
		DISPLAY l_rec_prodstatus.onord_qty TO prodstatus.onord_qty
		DISPLAY l_rec_prodstatus.reserved_qty TO prodstatus.reserved_qty
		DISPLAY l_rec_prodstatus.back_qty TO prodstatus.back_qty
		DISPLAY l_rec_prodstatus.forward_qty TO prodstatus.forward_qty
		DISPLAY l_rec_prodstatus.reorder_point_qty TO prodstatus.reorder_point_qty
		DISPLAY l_rec_prodstatus.reorder_qty TO prodstatus.reorder_qty
		DISPLAY l_rec_prodstatus.max_qty TO prodstatus.max_qty
		DISPLAY l_rec_prodstatus.critical_qty TO prodstatus.critical_qty

		CALL eventsuspend()		

		CLOSE WINDOW E501_prodstatus_availability
	END IF
END FUNCTION
############################################################
# END FUNCTION db_prodstatus_show_availability(p_cmpy_code,p_ware_code,p_part_code)
############################################################