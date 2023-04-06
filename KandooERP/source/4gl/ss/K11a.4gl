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

	Source code beautified by beautify.pl on 2019-12-31 14:28:26	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


#  K11a.4gl:FUNCTION header_entry(pr_mode)
#           add/edit of subhead details

FUNCTION header_entry(pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_customership RECORD LIKE customership.*, 
	pr_corpcust RECORD LIKE customer.*, 
	pr_holdreas RECORD LIKE holdreas.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_cust_name LIKE customer.name_text, 
	ware_text LIKE warehouse.desc_text, 
	pr_substype RECORD LIKE substype.*, 
	pr_sub_type LIKE subhead.sub_type_code, 
	pr_start_year, pr_end_year INTEGER, 
	pr_save_char CHAR(1), 
	i SMALLINT 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 

	IF pr_subhead.cust_code IS NOT NULL THEN 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("A",9104,"") 
			#9104 Customer NOT found"
			LET pr_customer.name_text = "**********" 
		END IF 
		IF pr_customer.delete_flag = "Y" THEN 
			LET msgresp = kandoomsg("A",7022,pr_customer.name_text) 
			#7022 Customer ???? has been marked FOR deletion
			LET pr_customer.name_text = "**********" 
		END IF 
		LET pr_customership.ship_code = pr_subhead.ship_code 
	END IF 
	LET pr_cust_name = pr_customer.name_text 
	IF pr_subhead.hold_code IS NOT NULL THEN 
		SELECT reason_text INTO pr_holdreas.reason_text 
		FROM holdreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = pr_subhead.hold_code 
		IF status = notfound THEN 
			LET pr_holdreas.reason_text = "**********" 
		END IF 
	END IF 
	IF pr_subhead.sales_code IS NOT NULL THEN 
		SELECT name_text INTO pr_salesperson.name_text 
		FROM salesperson 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = pr_subhead.sales_code 
		IF status = notfound THEN 
			LET pr_salesperson.name_text = "**********" 
		END IF 
		DISPLAY pr_salesperson.name_text TO sale_text 

	END IF 
	IF pr_subhead.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO ware_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_subhead.ware_code 
		IF status = notfound THEN 
			LET ware_text = "**********" 
		END IF 
		DISPLAY BY NAME ware_text 

	END IF 
	IF pr_subhead.sub_type_code IS NOT NULL THEN 
		SELECT * INTO pr_substype.* 
		FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_subhead.sub_type_code 
		IF status = 0 THEN 
			DISPLAY BY NAME pr_substype.desc_text 

		END IF 
	END IF 
	IF pr_mode = "CORP" THEN 
		SELECT name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_text 
		INTO pr_cust_name, 
		pr_customer.addr1_text, 
		pr_customer.addr2_text, 
		pr_customer.city_text, 
		pr_customer.state_code, 
		pr_customer.post_code, 
		pr_customer.country_code --@db-patch_2020_10_04--
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_csubhead.cust_code 
	END IF 
	LET msgresp = kandoomsg("K",1018,"") 
	#1018 Enter Details - ESC TO continue
	INPUT BY NAME pr_subhead.cust_code, 
	pr_subhead.sub_date, 
	pr_subhead.ship_code, 
	pr_subhead.ship_name_text, 
	pr_subhead.ship_addr1_text, 
	pr_subhead.ship_addr2_text, 
	pr_subhead.ship_city_text, 
	pr_subhead.state_code, 
	pr_subhead.post_code, 
	pr_subhead.country_code, --@db-patch_2020_10_04--
	pr_subhead.invoice_to_ind, 
	pr_subhead.sub_type_code, 
	pr_subhead.start_date, 
	pr_subhead.end_date, 
	pr_subhead.ord_text, 
	pr_subhead.hold_code, 
	pr_subhead.ware_code, 
	pr_subhead.sales_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			DISPLAY BY NAME pr_customer.name_text 

			DISPLAY pr_cust_name, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

			IF pr_mode = "EDIT" THEN 
				DISPLAY BY NAME pr_subhead.sub_num, 
				pr_subhead.last_inv_date, 
				pr_subhead.hold_code, 
				pr_holdreas.reason_text 

			END IF 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(cust_code) 
					LET l_tmp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.cust_code = l_tmp_text 
					END IF 
					NEXT FIELD cust_code 
				WHEN infield(ship_code) 
					LET l_tmp_text = show_ship(glob_rec_kandoouser.cmpy_code,pr_subhead.cust_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.ship_code = l_tmp_text 
					END IF 
					NEXT FIELD ship_code 
				WHEN infield(hold_code) 
					LET l_tmp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.hold_code = l_tmp_text 
					END IF 
					NEXT FIELD hold_code 
				WHEN infield(sub_type_code) 
					LET l_tmp_text = show_substype(glob_rec_kandoouser.cmpy_code,"1=1") 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.sub_type_code = l_tmp_text 
					END IF 
					NEXT FIELD sub_type_code 
				WHEN infield(sales_code) 
					LET l_tmp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.sales_code = l_tmp_text 
					END IF 
					NEXT FIELD sales_code 
				WHEN infield(ware_code) 
					LET l_tmp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF l_tmp_text IS NOT NULL THEN 
						LET pr_subhead.ware_code = l_tmp_text 
					END IF 
					NEXT FIELD ware_code 
			END CASE 

		ON KEY (F8) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_subhead.cust_code) --customer details / customer invoice submenu 

		ON KEY (F9) 
			IF pr_subhead.cust_code IS NOT NULL THEN 
				IF pay_detail() THEN 
				END IF 
			END IF 

		AFTER FIELD cust_code 
			IF pr_subhead.cust_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102" Cust. must be Entered"
				LET pr_subhead.cust_code = pr_customer.cust_code 
				CLEAR name_text 
				NEXT FIELD cust_code 
			ELSE 
			IF pr_customer.cust_code != pr_subhead.cust_code 
			OR pr_customer.cust_code IS NULL THEN 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND delete_flag = "N" 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105" Cust NOT found - Try Window"
					NEXT FIELD cust_code 
				ELSE 
				IF pr_customer.hold_code IS NOT NULL THEN 
					SELECT reason_text INTO l_tmp_text 
					FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = pr_customer.hold_code 
					LET msgresp=kandoomsg("E",7018,l_tmp_text) 
					#7018" Warning : Nominated Customer 'On Hold'"
				END IF 
				IF pr_customer.cred_bal_amt < 0 THEN 
					LET msgresp=kandoomsg("E",7019,"") 
					#7019" Warning : Nominated Customer has exceeded credit"
				END IF 
				IF pr_customer.corp_cust_code IS NOT NULL AND 
				pr_customer.corp_cust_ind = "1" THEN 
					SELECT * INTO pr_corpcust.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_customer.corp_cust_code 
					IF sqlca.sqlcode = 0 THEN 
						IF pr_corpcust.hold_code IS NOT NULL THEN 
							SELECT reason_text INTO l_tmp_text 
							FROM holdreas 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND hold_code = pr_corpcust.hold_code 
							LET msgresp=kandoomsg("E",7040,l_tmp_text) 
							#7040 Warning :Corporate Customer 'On Hold'"
						END IF 
						IF pr_corpcust.cred_bal_amt < 0 THEN 
							LET msgresp=kandoomsg("E",7041,"") 
							#7041 Warning: Corporate Customer has exceeded credit
						END IF 
					END IF 
				END IF 
				LET pr_subhead.term_code = pr_customer.term_code 
				LET pr_subhead.tax_code = pr_customer.tax_code 
				LET pr_subhead.hand_tax_code = pr_customer.tax_code 
				LET pr_subhead.freight_tax_code = pr_customer.tax_code 
				LET pr_subhead.sales_code = pr_customer.sale_code 
				LET pr_subhead.territory_code = pr_customer.territory_code 
				LET pr_subhead.cond_code = pr_customer.cond_code 
				LET pr_subhead.invoice_to_ind = pr_customer.invoice_to_ind 
				LET pr_subhead.currency_code = pr_customer.currency_code 
				IF pr_mode = "CORP" THEN 
					LET pr_subhead.invoice_to_ind = "1" 
					LET pr_subhead.currency_code = pr_csubhead.currency_code 
					LET pr_subhead.ord_text = pr_csubhead.ord_text 
				END IF 
				SELECT count(*) INTO i 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				CASE 
					WHEN i = 0 
						LET msgresp=kandoomsg("E",9053,"") 
						#9053No shipping addresses exist FOR this customer"
					WHEN i = 1 
						SELECT ship_code 
						INTO pr_subhead.ship_code 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_subhead.cust_code 
					OTHERWISE 
						SELECT unique 1 FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_subhead.cust_code 
						AND ship_code = pr_subhead.cust_code 
						IF sqlca.sqlcode = notfound THEN 
							DECLARE c_custship CURSOR FOR 
							SELECT ship_code FROM customership 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = pr_subhead.cust_code 
							OPEN c_custship 
							FETCH c_custship INTO pr_subhead.ship_code 
						ELSE 
						LET pr_subhead.ship_code = pr_subhead.cust_code 
					END IF 
				END CASE 
				SELECT * INTO pr_customership.* 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND ship_code = pr_subhead.ship_code 
				LET pr_subhead.ship_code = pr_customership.ship_code 
				LET pr_subhead.ware_code = pr_customership.ware_code 
				LET pr_subhead.ship_name_text = pr_customership.name_text 
				LET pr_subhead.ship_addr1_text = pr_customership.addr_text 
				LET pr_subhead.ship_addr2_text = pr_customership.addr2_text 
				LET pr_subhead.ship_city_text = pr_customership.city_text 
				LET pr_subhead.state_code = pr_customership.state_code 
				LET pr_subhead.post_code = pr_customership.post_code 
				LET pr_subhead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
				LET pr_subhead.contact_text = pr_customership.contact_text 
				LET pr_subhead.tele_text = pr_customership.tele_text 
				IF pr_mode = "CORP" THEN 
					IF pr_subhead.ware_code IS NULL THEN 
						LET pr_subhead.ware_code = pr_csubhead.ware_code 
					END IF 
				END IF 
				SELECT desc_text INTO ware_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_subhead.ware_code 
				IF status = notfound THEN 
					LET ware_text = "**********" 
				END IF 
				DISPLAY BY NAME ware_text 

				SELECT * INTO pr_salesperson.* 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = pr_subhead.sales_code 
				IF status = notfound THEN 
					LET pr_salesperson.name_text = "**********" 
				END IF 
				DISPLAY pr_salesperson.name_text TO sale_text 

			END IF 
		END IF 
	END IF 
		BEFORE FIELD sub_date 
			LET pr_cust_name = pr_customer.name_text 
			IF pr_mode = "CORP" THEN 
				SELECT name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				state_code, 
				post_code, 
				country_text 
				INTO pr_cust_name, 
				pr_customer.addr1_text, 
				pr_customer.addr2_text, 
				pr_customer.city_text, 
				pr_customer.state_code, 
				pr_customer.post_code, 
				pr_customer.country_code --@db-patch_2020_10_04--
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_csubhead.cust_code 
			END IF 
			DISPLAY BY NAME pr_subhead.sub_date, 
			pr_subhead.cust_code, 
			pr_customer.name_text, 
			pr_subhead.ship_code, 
			pr_subhead.ship_name_text, 
			pr_subhead.ship_addr1_text, 
			pr_subhead.ship_addr2_text, 
			pr_subhead.ship_city_text, 
			pr_subhead.state_code, 
			pr_subhead.post_code, 
			pr_subhead.country_code, --@db-patch_2020_10_04--
			pr_subhead.invoice_to_ind, 
			pr_subhead.ware_code, 
			pr_subhead.sales_code 

			DISPLAY pr_cust_name, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

		AFTER FIELD sub_date 
			IF pr_subhead.sub_date IS NULL THEN 
				LET pr_subhead.sub_date = today 
				NEXT FIELD sub_date 
			END IF 
			
			IF pr_subhead.currency_code = pr_glparms.base_currency_code THEN 
				LET pr_subhead.conv_qty = 1 
			ELSE 
			
			IF pr_subhead.conv_qty IS NULL OR pr_subhead.conv_qty = 0 THEN 
				LET pr_subhead.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					pr_subhead.currency_code, 
					pr_subhead.sub_date,
					CASH_EXCHANGE_SELL) 
			END IF 
		END IF
		 
		AFTER FIELD ship_code 
			IF pr_subhead.ship_code IS NOT NULL THEN 
				IF pr_subhead.ship_code != pr_customership.ship_code 
				OR pr_customership.ship_code IS NULL THEN 
					SELECT * INTO pr_customership.* 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_subhead.cust_code 
					AND ship_code = pr_subhead.ship_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("U",9105,"") 
						#9105" shipping NOT found, try window"
						LET pr_subhead.ship_code = pr_customership.ship_code 
						NEXT FIELD ship_code 
					ELSE 
					LET pr_subhead.ship_code = pr_customership.ship_code 
					LET pr_subhead.ware_code = pr_customership.ware_code 
					LET pr_subhead.ship_name_text = pr_customership.name_text 
					LET pr_subhead.ship_addr1_text = pr_customership.addr_text 
					LET pr_subhead.ship_addr2_text = pr_customership.addr2_text 
					LET pr_subhead.ship_city_text = pr_customership.city_text 
					LET pr_subhead.state_code = pr_customership.state_code 
					LET pr_subhead.post_code = pr_customership.post_code 
					LET pr_subhead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
					LET pr_subhead.contact_text = pr_customership.contact_text 
					LET pr_subhead.tele_text = pr_customership.tele_text 
					DISPLAY BY NAME pr_subhead.ship_code, 
					pr_subhead.ship_name_text, 
					pr_subhead.ship_addr1_text, 
					pr_subhead.ship_addr2_text, 
					pr_subhead.ship_city_text, 
					pr_subhead.state_code, 
					pr_subhead.post_code, 
					pr_subhead.ware_code, 
					pr_subhead.country_code--@db-patch_2020_10_04--

				END IF 
			END IF 
		ELSE 
		IF pr_subhead.ship_code IS NULL THEN 
			IF kandoomsg("K",8014,"") = "Y" THEN 
				## No ship address entered - use customer address
				LET pr_subhead.ship_name_text = pr_customer.name_text 
				LET pr_subhead.ship_addr1_text = pr_customer.addr1_text 
				LET pr_subhead.ship_addr2_text = pr_customer.addr2_text 
				LET pr_subhead.ship_city_text = pr_customer.city_text 
				LET pr_subhead.state_code = pr_customer.state_code 
				LET pr_subhead.post_code = pr_customer.post_code 
				LET pr_subhead.country_code = pr_customer.country_code --@db-patch_2020_10_04--
				DISPLAY BY NAME pr_subhead.ship_code, 
				pr_subhead.ship_name_text, 
				pr_subhead.ship_addr1_text, 
				pr_subhead.ship_addr2_text, 
				pr_subhead.ship_city_text, 
				pr_subhead.state_code, 
				pr_subhead.post_code, 
				pr_subhead.ware_code, 
				pr_subhead.country_code --@db-patch_2020_10_04--

				NEXT FIELD ship_addr1_text 
			END IF 
		END IF 
	END IF 
		AFTER FIELD hold_code 
			CLEAR reason_text 
			IF pr_subhead.hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO pr_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = pr_subhead.hold_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9045,"") 
					#9045 Sales Hold Code NOT found - Try Window "
					NEXT FIELD hold_code 
				ELSE 
				DISPLAY BY NAME pr_holdreas.reason_text 

			END IF 
		END IF 
		BEFORE FIELD sub_type_code 
			LET pr_sub_type = pr_subhead.sub_type_code 
			IF pr_mode = "EDIT" OR pr_mode = "CORP" THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD sub_type_code 
			IF pr_subhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sub_type_code 
			END IF 
			SELECT * INTO pr_substype.* 
			FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subhead.sub_type_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found - try window
				NEXT FIELD sub_type_code 
			ELSE 
			DISPLAY BY NAME pr_substype.desc_text 

		END IF 
		IF pr_mode = "ADD" OR 
		pr_sub_type != pr_subhead.sub_type_code THEN 
			LET pr_start_year = year(pr_subhead.sub_date) 
			IF month(pr_subhead.sub_date) < pr_substype.start_mth_num THEN 
				LET pr_start_year = pr_start_year - 1 
			END IF 
			LET pr_end_year = pr_start_year 
			IF pr_substype.start_mth_num > pr_substype.end_mth_num THEN 
				LET pr_end_year = pr_end_year + 1 
			END IF 
			LET pr_subhead.start_date = mdy(pr_substype.start_mth_num, 
			pr_substype.start_day_num, 
			pr_start_year) 
			LET pr_subhead.end_date = mdy(pr_substype.end_mth_num, 
			pr_substype.end_day_num, 
			pr_end_year) 
			DISPLAY BY NAME pr_subhead.start_date, 
			pr_subhead.end_date 

		END IF 
		BEFORE FIELD start_date 
			IF pr_mode = "EDIT" OR pr_mode = "CORP" THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD start_date 
			IF pr_subhead.start_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD start_date 
			END IF 
		BEFORE FIELD end_date 
			IF pr_mode = "EDIT" OR pr_mode = "CORP" THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD end_date 
			IF pr_subhead.end_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD end_date 
			END IF 
			IF pr_subhead.end_date < pr_subhead.start_date THEN 
				LET msgresp = kandoomsg("K",9105,"") 
				#9105 Value must be entered
				NEXT FIELD start_date 
			END IF 
		AFTER FIELD ware_code 
			CLEAR ware_text 
			IF pr_subhead.ware_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Warehouse code must be entered "
				NEXT FIELD ware_code 
			ELSE 
			SELECT desc_text 
			INTO ware_text 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_subhead.ware_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("U",9105,"") 
				#9105 Warehouse Code NOT found - Try Window "
				NEXT FIELD ware_code 
			ELSE 
			DISPLAY BY NAME ware_text 

		END IF 
	END IF 
		AFTER FIELD sales_code 
			CLEAR sale_text 
			IF pr_subhead.sales_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9062,"") 
				#9062 Saelsperson code must be entered "
				NEXT FIELD sales_code 
			END IF 
			SELECT * INTO pr_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = pr_subhead.sales_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("E",9050,"") 
				#9050 Sales ORDER salesperson NOT found - Try Window "
				NEXT FIELD sales_code 
			END IF 
			DISPLAY pr_salesperson.name_text TO sale_text 

			LET pr_subhead.mgr_code = pr_salesperson.mgr_code 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_subhead.ship_date IS NULL THEN 
					LET pr_subhead.ship_date = pr_subhead.sub_date 
				ELSE 
				IF pr_subhead.ship_date < pr_subhead.sub_date THEN 
					LET pr_subhead.ship_date = pr_subhead.sub_date 
					LET msgresp = kandoomsg("E",9090,"") 
					#9090 Delivery date cannot preceed ORDER date
					NEXT FIELD ship_date 
				END IF 
			END IF 
			IF pr_subhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sub_type_code 
			END IF 
			IF pr_subhead.start_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD start_date 
			END IF 
			IF pr_subhead.end_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD end_date 
			END IF 
			IF pr_subhead.end_date < pr_subhead.start_date THEN 
				LET msgresp = kandoomsg("K",9105,"") 
				#9105 END date must be greater than start date
				NEXT FIELD start_date 
			END IF 
			SELECT unique 1 FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_subhead.ware_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("U",9105,"") 
				#9105 Warehouse Code NOT found - Try Window "
				NEXT FIELD ware_code 
			END IF 
			IF pr_customer.ord_text_ind = "Y" THEN 
				IF pr_subhead.ord_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ord_text 
				END IF 
			END IF 
			SELECT * INTO pr_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = pr_subhead.sales_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("E",9050,"") 
				#9050 Sales ORDER salesperson NOT found - Try Window "
				NEXT FIELD sales_code 
			END IF 
			LET pr_subhead.mgr_code = pr_salesperson.mgr_code 
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

