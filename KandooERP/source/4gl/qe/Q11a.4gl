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
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 
FUNCTION header_entry(pr_mode) 
	DEFINE 
	pr_mode CHAR(4), 
	pr_customership RECORD LIKE customership.*, 
	pr_customership2 RECORD LIKE customership.*, 
	pr_corporate RECORD LIKE customer.*, 
	pr_corp_name_text LIKE customer.name_text, 
	pr_corpcust RECORD LIKE customer.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_supp_ware_text LIKE warehouse.desc_text, 
	pr_ship_cust_code LIKE customership.cust_code, 
	pr_ship_code LIKE customership.ship_code, 
	pr_save_char CHAR(1), 
	pr_save_date DATE, 
	i SMALLINT 

	IF pr_quotehead.cust_code IS NOT NULL THEN 
		SELECT * INTO pr_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("E",9052,"") 
			#9052 Sales Order Customer NOT found"
			LET pr_customer.name_text = "**********" 
		END IF 
		IF pr_customer.delete_flag = "Y" THEN 
			LET msgresp = kandoomsg("A",7022,pr_customer.name_text) 
			#7022 Customer ???? has been marked FOR deletion
			LET pr_customer.name_text = "**********" 
		END IF 
		LET pr_customership.ship_code = pr_quotehead.ship_code 
	END IF 
	IF pr_quotehead.sales_code IS NOT NULL THEN 
		SELECT name_text INTO pr_salesperson.name_text 
		FROM salesperson 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = pr_quotehead.sales_code 
		IF status = notfound THEN 
			LET pr_salesperson.name_text = "**********" 
		END IF 
		DISPLAY pr_salesperson.name_text TO sale_text 

	END IF 
	IF pr_quotehead.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO pr_warehouse.desc_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_quotehead.ware_code 
		IF status = notfound THEN 
			LET pr_warehouse.desc_text = "**********" 
		END IF 
		DISPLAY BY NAME pr_warehouse.desc_text 

	END IF 
	LET msgresp = kandoomsg("E",1015,"") 
	#1015 Enter Sales Order Details - F5 Customer Inquiry - F9 Account Details "
	INPUT BY NAME pr_quotehead.cust_code, 
	pr_quotehead.quote_date, 
	pr_quotehead.valid_date, 
	pr_quotehead.invoice_to_ind, 
	pr_quotehead.ship_code, 
	pr_quotehead.ship_name_text, 
	pr_quotehead.ship_addr1_text, 
	pr_quotehead.ship_addr2_text, 
	pr_quotehead.ship_city_text, 
	pr_quotehead.state_code, 
	pr_quotehead.post_code, 
	pr_quotehead.country_code,--@db-patch_2020_10_04-- 
	pr_quotehead.ord_text, 
	pr_quotehead.sales_code, 
	pr_quotehead.ware_code, 
	pr_quotehead.com1_text, 
	pr_quotehead.com2_text, 
	pr_quotehead.com3_text, 
	pr_quotehead.com4_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			DISPLAY BY NAME pr_customer.name_text 

			INITIALIZE pr_corporate.* TO NULL 
			IF pr_customer.corp_cust_code IS NOT NULL THEN 
				SELECT * INTO pr_corporate.* FROM customer 
				WHERE cust_code = pr_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			LET pr_corp_name_text = pr_corporate.name_text 
			DISPLAY pr_customer.name_text, 
			pr_customer.corp_cust_code, 
			pr_corp_name_text, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

			IF pr_mode = "EDIT" THEN 
				DISPLAY BY NAME pr_quotehead.order_num 

				SELECT count(*) INTO i 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_quotehead.cust_code 
				DISPLAY i TO ship_count 

			END IF 
			CALL publish_toolbar("kandoo","Q11a","inp-cust_code-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (control-b) 
			CASE 
				WHEN infield(cust_code) 
					LET pr_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_quotehead.cust_code = pr_temp_text 
					END IF 
					NEXT FIELD cust_code 
				WHEN infield(ship_code) 
					LET pr_temp_text = show_ship(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_quotehead.ship_code = pr_temp_text 
						SELECT * INTO pr_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_quotehead.cust_code 
						AND ship_code = pr_quotehead.ship_code 
						LET pr_quotehead.ship_code = pr_customership.ship_code 
						LET pr_quotehead.ware_code = pr_customership.ware_code 
						LET pr_quotehead.ship_name_text = pr_customership.name_text 
						LET pr_quotehead.ship_addr1_text = pr_customership.addr_text 
						LET pr_quotehead.ship_addr2_text = pr_customership.addr2_text 
						LET pr_quotehead.ship_city_text = pr_customership.city_text 
						LET pr_quotehead.state_code = pr_customership.state_code 
						LET pr_quotehead.post_code = pr_customership.post_code 
						LET pr_quotehead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
						LET pr_quotehead.contact_text = pr_customership.contact_text 
						LET pr_quotehead.tele_text = pr_customership.tele_text 
						LET pr_quotehead.mobile_phone = pr_customership.mobile_phone
						LET pr_quotehead.email = pr_customership.email
					END IF 
					NEXT FIELD ship_code 
				WHEN infield(sales_code) 
					LET pr_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_quotehead.sales_code = pr_temp_text 
					END IF 
					NEXT FIELD sales_code 
				WHEN infield(ware_code) 
					LET pr_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_quotehead.ware_code = pr_temp_text 
					END IF 
					NEXT FIELD ware_code 
				WHEN infield(ship_name_text) 
					CALL show_cust_ship(glob_rec_kandoouser.cmpy_code) 
					RETURNING pr_ship_cust_code, 
					pr_ship_code 
					IF pr_ship_cust_code IS NOT NULL 
					AND pr_ship_code IS NOT NULL THEN 
						SELECT * INTO pr_customership2.* FROM customership 
						WHERE cust_code = pr_ship_cust_code 
						AND ship_code = pr_ship_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = 0 THEN 
							LET pr_quotehead.ship_name_text = 
							pr_customership2.name_text 
							LET pr_quotehead.ship_addr1_text = 
							pr_customership2.addr_text 
							LET pr_quotehead.ship_addr2_text = 
							pr_customership2.addr2_text 
							LET pr_quotehead.ship_city_text = 
							pr_customership2.city_text 
							LET pr_quotehead.state_code = pr_customership2.state_code 
							LET pr_quotehead.post_code = pr_customership2.post_code 
							LET pr_quotehead.country_code = pr_customership2.country_code --@db-patch_2020_10_04--
							LET pr_quotehead.contact_text = pr_customership.contact_text 
							LET pr_quotehead.tele_text = pr_customership2.tele_text
							LET pr_quotehead.mobile_phone = pr_customership2.mobile_phone 
							LET pr_quotehead.email = pr_customership2.email
							LET pr_quotehead.ship_code = NULL 
							LET pr_quotehead.ware_code = pr_customership2.ware_code 
							INITIALIZE pr_warehouse.desc_text TO NULL 
							SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = pr_quotehead.ware_code 
							DISPLAY BY NAME pr_quotehead.ship_code, 
							pr_warehouse.desc_text, 
							pr_quotehead.ship_name_text, 
							pr_quotehead.ship_addr1_text, 
							pr_quotehead.ship_addr2_text, 
							pr_quotehead.ship_city_text, 
							pr_quotehead.state_code, 
							pr_quotehead.post_code, 
							pr_quotehead.country_code, --@db-patch_2020_10_04--
							pr_quotehead.ware_code 

						END IF 
					END IF 
					NEXT FIELD ship_name_text 
			END CASE 

		ON KEY (F5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) --customer details / customer invoice submenu 

		ON KEY (F9) 
			IF pr_quotehead.cust_code IS NOT NULL THEN 
				LET pr_save_char = pr_globals.paydetl_flag 
				LET pr_globals.paydetl_flag = yes_flag 
				IF pay_detail() THEN 
				END IF 
				LET pr_globals.paydetl_flag = pr_save_char 
			END IF 

		AFTER FIELD cust_code 
			IF pr_quotehead.cust_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9051,"") 
				#9051" Cust. must be Entered"
				LET pr_quotehead.cust_code = pr_customer.cust_code 
				CLEAR name_text 
				NEXT FIELD cust_code 
			ELSE 
				IF (pr_customer.cust_code != pr_quotehead.cust_code) OR 
				(pr_customer.cust_code IS null) 
				THEN 
					SELECT * INTO pr_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_quotehead.cust_code 
					AND delete_flag = "N" 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("E",9052,"") 
						#9052" Cust NOT found - Try Window"
						NEXT FIELD cust_code 
					ELSE 
						IF pr_customer.hold_code IS NOT NULL THEN 
							SELECT reason_text INTO pr_temp_text FROM holdreas 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND hold_code = pr_customer.hold_code 
							LET pr_quotehead.hold_code = pr_customer.hold_code 
							LET msgresp = kandoomsg("E",7018,pr_temp_text) 
							#7018" Warning : Nominated Customer 'On Hold'"
						END IF 
						IF pr_customer.corp_cust_code IS NOT NULL AND 
						pr_customer.corp_cust_ind = "1" THEN 
							SELECT * INTO pr_corpcust.* 
							FROM customer 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = pr_customer.corp_cust_code 
							IF sqlca.sqlcode = 0 THEN 
								IF pr_corpcust.hold_code IS NOT NULL THEN 
									SELECT reason_text INTO pr_temp_text 
									FROM holdreas 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND hold_code = pr_corpcust.hold_code 
									LET pr_quotehead.hold_code = pr_corpcust.hold_code 
									LET msgresp = kandoomsg("E",7040,pr_temp_text) 
									#7040 Warning :Corporate Customer 'On Hold'"
								END IF 
								IF pr_corpcust.cred_override_ind = 0 THEN 
									IF pr_corpcust.cred_bal_amt < 0 THEN 
										LET pr_quotehead.hold_code = 
										glob_rec_opparms.lim_hold_code 
										LET msgresp=kandoomsg("E",7041,"") 
										#7041 Warning: Corp Customer has exceeded credit
									END IF 
								END IF 
							END IF 
						END IF 
						IF pr_customer.cred_override_ind = 0 THEN 
							IF pr_customer.cred_bal_amt < 0 THEN 
								LET pr_quotehead.hold_code = glob_rec_opparms.lim_hold_code 
								LET msgresp = kandoomsg("E",7019,"") 
								#7019 Warning : Nominated Customer has exceeded credit
							END IF 
						END IF 
						LET pr_quotehead.term_code = pr_customer.term_code 
						LET pr_quotehead.tax_code = pr_customer.tax_code 
						LET pr_quotehead.hand_tax_code = pr_customer.tax_code 
						LET pr_quotehead.freight_tax_code = pr_customer.tax_code 
						LET pr_quotehead.sales_code = pr_customer.sale_code 
						LET pr_quotehead.territory_code = pr_customer.territory_code 
						LET pr_quotehead.cond_code = pr_customer.cond_code 
						LET pr_quotehead.invoice_to_ind = pr_customer.invoice_to_ind 
						LET pr_quotehead.currency_code = pr_customer.currency_code 
						SELECT count(*) INTO i 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_quotehead.cust_code 
						DISPLAY i TO ship_count 

						CASE 
							WHEN i = 0 
								LET msgresp=kandoomsg("E",9053,"") 
								#9053 No shipping addresses exist FOR this customer"
								LET pr_quotehead.ship_code = NULL 
							WHEN i = 1 
								SELECT ship_code 
								INTO pr_quotehead.ship_code 
								FROM customership 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code = pr_quotehead.cust_code 
							OTHERWISE 
								SELECT unique 1 FROM customership 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code = pr_quotehead.cust_code 
								AND ship_code = pr_quotehead.cust_code 
								IF sqlca.sqlcode = notfound THEN 
									DECLARE c_custship CURSOR FOR 
									SELECT ship_code FROM customership 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND cust_code = pr_quotehead.cust_code 
									OPEN c_custship 
									FETCH c_custship INTO pr_quotehead.ship_code 
								ELSE 
									LET pr_quotehead.ship_code = pr_quotehead.cust_code 
								END IF 
						END CASE 
						INITIALIZE pr_customership.* TO NULL 
						SELECT * INTO pr_customership.* 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_quotehead.cust_code 
						AND ship_code = pr_quotehead.ship_code 
						LET pr_quotehead.ship_code = pr_customership.ship_code 
						LET pr_quotehead.ware_code = pr_customership.ware_code 
						LET pr_quotehead.ship_name_text = pr_customership.name_text 
						LET pr_quotehead.ship_addr1_text = pr_customership.addr_text 
						LET pr_quotehead.ship_addr2_text = pr_customership.addr2_text 
						LET pr_quotehead.ship_city_text = pr_customership.city_text 
						LET pr_quotehead.state_code = pr_customership.state_code 
						LET pr_quotehead.post_code = pr_customership.post_code 
						LET pr_quotehead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
						LET pr_quotehead.contact_text = pr_customership.contact_text 
						LET pr_quotehead.tele_text = pr_customership.tele_text 
						LET pr_quotehead.mobile_phone = pr_customership.mobile_phone
						LET pr_quotehead.email = pr_customership.email
						SELECT desc_text INTO pr_warehouse.desc_text 
						FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pr_quotehead.ware_code 
						IF status = notfound THEN 
							LET pr_warehouse.desc_text = "**********" 
						END IF 
						SELECT * INTO pr_salesperson.* 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND sale_code = pr_quotehead.sales_code 
						IF status = notfound THEN 
							LET pr_salesperson.name_text = "**********" 
						END IF 
						DISPLAY pr_salesperson.name_text TO sale_text 

					END IF 
				END IF 
			END IF 
			DISPLAY BY NAME pr_quotehead.quote_date, 
			pr_quotehead.cust_code, 
			pr_customer.name_text, 
			pr_quotehead.ship_code, 
			pr_quotehead.ship_name_text, 
			pr_quotehead.ship_addr1_text, 
			pr_quotehead.ship_addr2_text, 
			pr_quotehead.ship_city_text, 
			pr_quotehead.state_code, 
			pr_quotehead.post_code, 
			pr_quotehead.country_code, --@db-patch_2020_10_04--
			pr_quotehead.invoice_to_ind, 
			pr_quotehead.sales_code, 
			pr_quotehead.ware_code, 
			pr_quotehead.valid_date, 
			pr_quotehead.com1_text, 
			pr_quotehead.com2_text, 
			pr_quotehead.com3_text, 
			pr_quotehead.com4_text, 
			pr_warehouse.desc_text 

			INITIALIZE pr_corporate.* TO NULL 
			IF pr_customer.corp_cust_code IS NOT NULL THEN 
				SELECT * INTO pr_corporate.* FROM customer 
				WHERE cust_code = pr_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			LET pr_corp_name_text = pr_corporate.name_text 
			DISPLAY pr_customer.name_text, 
			pr_customer.corp_cust_code, 
			pr_corp_name_text, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

		BEFORE FIELD quote_date 
			LET pr_save_date = pr_quotehead.quote_date 
		AFTER FIELD quote_date 
			IF pr_quotehead.quote_date IS NULL THEN 
				LET pr_quotehead.quote_date = pr_globals.quote_date 
				LET pr_save_date = NULL 
			END IF 
			IF pr_quotehead.quote_date != pr_save_date 
			OR pr_save_date IS NULL THEN 
				LET pr_quotehead.valid_date = pr_quotehead.quote_date	+ glob_rec_qpparms.days_validity_num 
				DISPLAY BY NAME pr_quotehead.valid_date 

				NEXT FIELD quote_date 
			END IF 
		AFTER FIELD ship_code 
			IF pr_quotehead.ship_code IS NOT NULL THEN 
				IF pr_quotehead.ship_code != pr_customership.ship_code 
				OR pr_customership.ship_code IS NULL THEN 
					SELECT * INTO pr_customership.* 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_quotehead.cust_code 
					AND ship_code = pr_quotehead.ship_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("E",9054,"") 
						#9054" shipping NOT found, try window"
						LET pr_quotehead.ship_code = pr_customership.ship_code 
						NEXT FIELD ship_code 
					ELSE 
						LET pr_quotehead.ship_code = pr_customership.ship_code 
						LET pr_quotehead.ware_code = pr_customership.ware_code 
						INITIALIZE pr_warehouse.desc_text TO NULL 
						SELECT desc_text INTO pr_warehouse.desc_text FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pr_quotehead.ware_code 
						DISPLAY BY NAME pr_quotehead.ware_code, 
						pr_warehouse.desc_text 

						LET pr_quotehead.ship_name_text = pr_customership.name_text 
						LET pr_quotehead.ship_addr1_text = pr_customership.addr_text 
						LET pr_quotehead.ship_addr2_text = pr_customership.addr2_text 
						LET pr_quotehead.ship_city_text = pr_customership.city_text 
						LET pr_quotehead.state_code = pr_customership.state_code 
						LET pr_quotehead.post_code = pr_customership.post_code 
						LET pr_quotehead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
						LET pr_quotehead.contact_text = pr_customership.contact_text 
						LET pr_quotehead.tele_text = pr_customership.tele_text 
						LET pr_quotehead.mobile_phone = pr_customership.mobile_phone
						LET pr_quotehead.email = pr_customership.email
					END IF 
				END IF 
			ELSE 
				IF pr_quotehead.ship_code IS NULL THEN 
					IF kandoomsg("E",8032,"") = "Y" THEN 
						## No ship address entered - use customer address
						LET pr_quotehead.ship_name_text = pr_customer.name_text 
						LET pr_quotehead.ship_addr1_text = pr_customer.addr1_text 
						LET pr_quotehead.ship_addr2_text = pr_customer.addr2_text 
						LET pr_quotehead.ship_city_text = pr_customer.city_text 
						LET pr_quotehead.state_code = pr_customer.state_code 
						LET pr_quotehead.post_code = pr_customer.post_code 
						LET pr_quotehead.country_code = pr_customer.country_code --@db-patch_2020_10_04--
						NEXT FIELD ship_addr1_text 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD ship_addr1_text 
			IF pr_quotehead.ship_name_text IS NOT NULL THEN 
				DISPLAY BY NAME pr_quotehead.ship_code, 
				pr_quotehead.ship_name_text, 
				pr_quotehead.ship_addr1_text, 
				pr_quotehead.ship_addr2_text, 
				pr_quotehead.ship_city_text, 
				pr_quotehead.state_code, 
				pr_quotehead.post_code, 
				pr_quotehead.country_code, 
				pr_quotehead.ware_code 

			END IF 
		AFTER FIELD sales_code 
			CLEAR sale_text 
			IF pr_quotehead.sales_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9062,"") 
				#9062 Saelsperson code must be entered "
				NEXT FIELD sales_code 
			END IF 
			SELECT * INTO pr_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = pr_quotehead.sales_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("E",9050,"") 
				#9050 Sales ORDER salesperson NOT found - Try Window "
				NEXT FIELD sales_code 
			END IF 
			DISPLAY pr_salesperson.name_text TO sale_text 

			LET pr_quotehead.mgr_code = pr_salesperson.mgr_code 
		AFTER FIELD ware_code 
			CLEAR desc_text 
			IF pr_quotehead.ware_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9046,"") 
				#9046 Warehouse code must be entered "
				NEXT FIELD ware_code 
			ELSE 
				SELECT desc_text 
				INTO pr_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_quotehead.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9047,"") 
					#9047 Warehouse Code NOT found - Try Window "
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY BY NAME pr_warehouse.desc_text 

				END IF 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_quotehead.ship_date IS NULL THEN 
					LET pr_quotehead.ship_date = pr_quotehead.quote_date 
				END IF 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_quotehead.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9047,"") 
					#9047 Warehouse Code NOT found - Try Window "
					NEXT FIELD ware_code 
				END IF 
				SELECT * INTO pr_salesperson.* 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = pr_quotehead.sales_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9050,"") 
					#9050 Sales ORDER salesperson NOT found - Try Window "
					NEXT FIELD sales_code 
				END IF 
				LET pr_quotehead.mgr_code = pr_salesperson.mgr_code 
				IF pr_quotehead.ord_text IS NULL THEN 
					IF pr_customer.ord_text_ind = "Y" THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						NEXT FIELD ord_text 
					END IF 
				END IF 
				IF NOT pay_detail() THEN 
					NEXT FIELD cust_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		IF pr_mode = "EDIT" THEN 
			SELECT * INTO pr_quotehead.* 
			FROM quotehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_quotehead.order_num 
			IF pr_quotehead.status_ind = "X" THEN 
				SELECT unique 1 FROM quotedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_quotehead.order_num 
				IF status = notfound THEN 
					LET pr_quotehead.status_ind = "D" 
				ELSE 
					SELECT unique 1 FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pr_quotehead.order_num 
					IF status = notfound THEN 
						LET pr_quotehead.status_ind = "U" 
					ELSE 
						LET pr_quotehead.status_ind = "C" 
					END IF 
				END IF 
				UPDATE quotehead 
				SET status_ind = pr_quotehead.status_ind 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_quotehead.order_num 
			END IF 
		END IF 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
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
		OPEN WINDOW e113 with FORM "E113" -- alch kd-747 
		CALL winDecoration_e("E113") -- alch kd-747 
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
