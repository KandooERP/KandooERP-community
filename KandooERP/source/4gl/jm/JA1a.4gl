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

	Source code beautified by beautify.pl on 2020-01-02 19:48:15	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JA1a - Contract add
# Purpose - Contract addition, AND edit

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 



FUNCTION contracthead() 

	DEFINE 
	fv_cust_code LIKE contracthead.cust_code, 
	fv_status LIKE contracthead.status_code, 
	fv_bill_type LIKE contracthead.bill_type_code 


	SELECT * 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 


	IF pr_jmparms.nextcontract_num IS NULL THEN 
		LET msgresp = kandoomsg("A",7511,"") 
		# MESSAGE "Contract numbering IS NOT SET up - Use GZD"
		RETURN 
	END IF 
	OPEN WINDOW wja00 with FORM "JA00" -- alch kd-747 
	CALL winDecoration_j("JA00") -- alch kd-747 
	LET msgresp = kandoomsg("A",3521,"") 
	# "ESC TO Continue, DEL TO Exit,
	# "F7 TO Generate Inventory Details by Category"
	LET pv_finish_add = false 

	WHILE NOT pv_finish_add 
		LET pv_dtllne_cnt = 0 
		IF pv_add THEN 
			INITIALIZE pr_contracthead.* TO NULL 
			LET pr_contracthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_contracthead.status_code = "A"{ctive} 
			LET pr_contracthead.start_date = today 
			LET pr_contracthead.bill_type_code = "W"{eekly} 
			LET pr_contracthead.bill_int_ind = 1 
			LET pr_contracthead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_contracthead.entry_date = today 
			LET pr_contracthead.contract_value_amt = 0 
		ELSE 
			SELECT * 
			INTO pr_contracthead.* 
			FROM contracthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_contracthead.contract_code 
			AND cust_code = pr_contracthead.cust_code 

			IF status THEN 
				#LET msgresp = maxmesg("A",9200,pr_contracthead.contract_code)
				RETURN 
			ELSE 
				SELECT * 
				INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_contracthead.cust_code 

				DISPLAY BY NAME pr_customer.name_text 

				CASE pr_contracthead.status_code 
					WHEN "A" 
						DISPLAY "Active" TO status_text 
					WHEN "Q" 
						DISPLAY "Quote" TO status_text 
					WHEN "H" 
						DISPLAY "Hold (no billing)" TO status_text 
					WHEN "C" 
						DISPLAY "Complete (no billing)" TO status_text 
				END CASE 
			END IF 

		END IF 

		DISPLAY BY NAME pr_contracthead.last_billed_date, 
		pr_contracthead.entry_code, 
		pr_contracthead.entry_date, 
		pr_contracthead.contract_value_amt, 
		pr_customer.name_text, 
		pr_jmparms.cntrhd_prmpt_text 

		INPUT BY NAME pr_contracthead.contract_code, 
		pr_contracthead.desc_text, 
		pr_contracthead.cust_code, 
		pr_contracthead.status_code, 
		pr_contracthead.user1_text, 
		pr_contracthead.bill_type_code, 
		pr_contracthead.bill_int_ind, 
		pr_contracthead.start_date, 
		pr_contracthead.end_date, 
		pr_contracthead.sale_code, 
		pr_contracthead.cons_inv_flag, 
		pr_contracthead.comm1_text, 
		pr_contracthead.comm2_text WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JA1a","input_arr-pr_contracthead-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F7) 
				IF (pr_contracthead.contract_code IS NULL AND 
				((pv_add AND pr_jmparms.nextcontract_num = 0) OR 
				NOT pv_add)) OR 
				pr_contracthead.cust_code IS NULL OR 
				pr_contracthead.status_code IS NULL OR 
				pr_contracthead.bill_type_code IS NULL OR 
				pr_contracthead.bill_int_ind IS NULL OR 
				pr_contracthead.start_date IS NULL OR 
				pr_contracthead.end_date IS NULL THEN 
					LET msgresp = kandoomsg("A",3522,"") 
					# All necessary data must be entered before
					# generating contract details
				ELSE 
					CALL get_inv_cats() 
				END IF 

			ON KEY (control-B) 
				CASE 
					WHEN infield(cust_code) 
						CALL show_clnt(glob_rec_kandoouser.cmpy_code) RETURNING fv_cust_code 
						IF fv_cust_code IS NOT NULL THEN 
							LET pr_contracthead.cust_code = fv_cust_code 
						END IF 
						NEXT FIELD cust_code 

					WHEN infield(status_code) 
						CALL show_status() RETURNING fv_status 
						IF fv_status IS NOT NULL THEN 
							LET pr_contracthead.status_code = fv_status 
						END IF 
						NEXT FIELD status_code 

					WHEN infield(bill_type_code) 
						CALL show_bill_type() RETURNING fv_bill_type 
						IF fv_bill_type IS NOT NULL THEN 
							LET pr_contracthead.bill_type_code = fv_bill_type 
						END IF 
						NEXT FIELD bill_type_code 

					WHEN infield(user1_text) 
						IF pr_jmparms.cntrhd_prmpt_ind = "3" OR 
						pr_jmparms.cntrhd_prmpt_ind = "4" THEN 
							CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","A") RETURNING pv_ref_code 
							IF pv_ref_code IS NOT NULL THEN 
								LET pr_contracthead.user1_text = pv_ref_code 
							END IF 
							NEXT FIELD user1_text 
						END IF 


					WHEN infield (sale_code) 
						LET pr_contracthead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_contracthead.sale_code 

						NEXT FIELD sale_code 

				END CASE 

			BEFORE FIELD contract_code 
				IF NOT pv_add OR 
				(pv_add AND (pr_jmparms.nextcontract_num = 1 OR 
				pr_jmparms.nextcontract_num = 2)) THEN 
					NEXT FIELD desc_text 
				END IF 

			AFTER FIELD contract_code 
				IF pr_contracthead.contract_code IS NOT NULL THEN 
					SELECT * 
					FROM contracthead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pr_contracthead.contract_code 

					IF status != notfound THEN 
						LET msgresp = kandoomsg("A",3523,"") 
						# Contract Already Exists - Enter a unique contract code
						NEXT FIELD contract_code 
					END IF 
				END IF 

			BEFORE FIELD desc_text 

				IF pv_add AND pr_jmparms.nextcontract_num = 0 AND 
				pr_contracthead.contract_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# Value must be entered
					NEXT FIELD contract_code 
				END IF 

			AFTER FIELD desc_text 
				IF NOT pv_add AND fgl_lastkey() != fgl_keyval("accept") THEN 
					NEXT FIELD status_code 
				END IF 

			BEFORE FIELD cust_code 
				IF NOT pv_add THEN 
					NEXT FIELD desc_text 
				END IF 

			AFTER FIELD cust_code 
				IF pr_contracthead.cust_code IS NOT NULL THEN 
					SELECT * 
					INTO pr_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_contracthead.cust_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("A",9009,"") 
						# Customer code does NOT exist - try window
						NEXT FIELD cust_code 
					END IF 
					DISPLAY BY NAME pr_customer.name_text 
				END IF 

			BEFORE FIELD status_code 
				IF pr_contracthead.cust_code IS NULL THEN 
					LET msgresp = kandoomsg("A",9024,"") 
					# Customer code must be entered
					NEXT FIELD cust_code 
				END IF 

			AFTER FIELD status_code 
				IF pr_contracthead.status_code IS NOT NULL THEN 
					CASE WHEN pr_contracthead.status_code = "A" 
					DISPLAY "Active" TO status_text 
						WHEN pr_contracthead.status_code = "Q" 
							DISPLAY "Quote" TO status_text 
						WHEN pr_contracthead.status_code = "H" 
							DISPLAY "Hold (no billing)" TO status_text 
						WHEN pr_contracthead.status_code = "C" 
							DISPLAY "Complete (no billing)" TO status_text 
						OTHERWISE 
							LET msgresp = kandoomsg("U",9105,"") 
							# Enter a Valid Status Code - try window
							NEXT FIELD status_code 
					END CASE 
				END IF 

			BEFORE FIELD user1_text 
				IF pr_contracthead.status_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# Status code must be entered
					NEXT FIELD status_code 
				END IF 

				IF pr_jmparms.cntrhd_prmpt_ind = "5" THEN {skip this field} 
					NEXT FIELD bill_type_code 
				END IF 

			AFTER FIELD user1_text 
				IF pr_contracthead.user1_text IS NULL THEN 
					IF pr_jmparms.cntrhd_prmpt_ind = "2" 
					OR pr_jmparms.cntrhd_prmpt_ind = "4" THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						# "User Defined field must be entered"
						NEXT FIELD user1_text 
					END IF 
				ELSE 
					IF pr_jmparms.cntrhd_prmpt_ind = "3" 
					OR pr_jmparms.cntrhd_prmpt_ind = "4" THEN 
						SELECT ref_code 
						FROM userref 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND source_ind = "J" 
						AND ref_ind = "A" 
						AND ref_code = pr_contracthead.user1_text 

						IF status = notfound THEN 
							LET msgresp = kandoomsg("U",9105,"") 
							# "User Defined INPUT NOT valid - Try window"
							NEXT FIELD user1_text 
						END IF 
					END IF 
				END IF 

			AFTER FIELD bill_type_code 
				IF pr_contracthead.bill_type_code IS NOT NULL THEN 

					IF pr_contracthead.bill_type_code NOT matches "[DWMEA]" THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# Enter a Valid Billing Type - try window
						NEXT FIELD bill_type_code 
					END IF 
				END IF 

			BEFORE FIELD bill_int_ind 
				IF pr_contracthead.bill_type_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# A Billing Type code must be entered
					NEXT FIELD bill_type_code 
				END IF 

			BEFORE FIELD start_date 
				IF pr_contracthead.bill_int_ind IS NULL OR 
				pr_contracthead.bill_int_ind = 0 THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# A Billing Interval must be entered
					NEXT FIELD bill_int_ind 
				END IF 

			AFTER FIELD start_date 
				IF pr_contracthead.start_date IS NOT NULL THEN 
					# reasonablilty check
					IF year(pr_contracthead.start_date) < year(today) THEN 
						LET msgresp = kandoomsg("U",9522," ") 
					END IF 
					IF day(pr_contracthead.start_date) = 31 AND 
					pr_contracthead.bill_type_code = "M" THEN 
						LET msgresp = kandoomsg("A",3526,"") 
						# Contract starts AT END of Month -
						# Billing type should be END of Month NOT Monthly
						NEXT FIELD bill_type_code 
					END IF 
				END IF 

			BEFORE FIELD end_date 
				IF pr_contracthead.start_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# A start date AND END date must be entered
					NEXT FIELD start_date 
				END IF 

			AFTER FIELD end_date 
				IF pr_contracthead.end_date IS NOT NULL THEN 
					#reasonablilty check
					IF year(pr_contracthead.end_date) < year(today) THEN 
						LET msgresp = kandoomsg("U",9522," ") 
					END IF 
					IF pr_contracthead.end_date < 
					pr_contracthead.start_date THEN 
						LET msgresp = kandoomsg("A",9095,"") 
						# END date must be equal OR greater than Start date
						NEXT FIELD start_date 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("U",9102,"") 
					# A start date AND END date must be entered
					NEXT FIELD end_date 
				END IF 


			AFTER FIELD sale_code 
				IF pr_contracthead.sale_code IS NOT NULL THEN 
					SELECT name_text 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = pr_contracthead.sale_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# "Salesperson code NOT found - Try Window"
						NEXT FIELD sale_code 
					END IF 
				END IF 



			AFTER FIELD cons_inv_flag 
				IF pr_contracthead.cons_inv_flag IS NOT NULL 
				AND pr_contracthead.cons_inv_flag NOT matches "[YN ]" THEN 
					LET msgresp = kandoomsg("U",9909,"") 
					# Invoice consolidation flag must be either Y, N, blank
					NEXT FIELD cons_inv_flag 
				END IF 










			AFTER INPUT 
				# IF Del was pressed
				IF int_flag OR quit_flag THEN 
					LET pv_finish_add = true 
					EXIT INPUT 
				END IF 

				# IF Esc was pressed
				IF (pr_contracthead.contract_code IS NULL AND 
				pv_add AND pr_jmparms.nextcontract_num = 0) OR 
				pr_contracthead.cust_code IS NULL OR 
				pr_contracthead.status_code IS NULL OR 
				(pr_contracthead.user1_text IS NULL AND 
				(pr_jmparms.cntrhd_prmpt_ind = "2" OR 
				pr_jmparms.cntrhd_prmpt_ind = "4")) OR 
				pr_contracthead.bill_type_code IS NULL OR 
				pr_contracthead.bill_int_ind IS NULL OR 
				pr_contracthead.bill_int_ind = 0 OR 
				pr_contracthead.start_date IS NULL OR 
				pr_contracthead.end_date IS NULL THEN 
					LET msgresp = kandoomsg("A",3536,"") 
					# All necessary data must be entered before continuing
					NEXT FIELD contract_code 
				ELSE 
					IF pv_add THEN 
						# calculate schedule of invoice dates
						CALL calc_inv_dates() 
					ELSE 
						# get schedule of invoice dates
						CALL get_inv_dates() 
					END IF 

					# DISPLAY schedule of invoice dates
					IF NOT disp_inv_dates() THEN 
						NEXT FIELD contract_code 
					END IF 

					# add/edit detail lines
					IF NOT add_dtl_lines() THEN 
						NEXT FIELD contract_code 
					END IF 

					# write contracthead & invoicedate data
					IF NOT write_contract() THEN 
						NEXT FIELD contract_code 
					END IF 

					# INITIALIZE program records & ARRAY FOR next contract
					CALL init_contract() 

					IF NOT pv_add THEN 
						LET pv_finish_add = true 
					END IF 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	END WHILE 

	CLOSE WINDOW wja00 

END FUNCTION 


FUNCTION get_inv_cats() 

	DEFINE fv_cat_code LIKE category.cat_code, 
	fv_line_num LIKE contractdetl.line_num, 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT 

	LET fv_cat_code = show_pcat(glob_rec_kandoouser.cmpy_code) 

	IF fv_cat_code IS NULL THEN 
		RETURN 
	END IF 

	SELECT stock_acct_code 
	INTO pv_stock_acct_code 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = fv_cat_code 

	DECLARE s_curs1 CURSOR FOR 
	SELECT * 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = fv_cat_code 

	LET fv_idx = 0 
	LET fv_cnt = 0 

	FOREACH s_curs1 INTO pr_product.* 

		IF NOT pv_add THEN 
			SELECT count(*) 
			INTO fv_cnt 
			FROM contractdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_contracthead.contract_code 
			AND cust_code = pr_contracthead.cust_code 
			AND part_code = pr_product.part_code 
		END IF 

		IF fv_cnt > 0 THEN 
			CONTINUE FOREACH 
		END IF 

		LET fv_idx = fv_idx + 1 

		LET pa_details[fv_idx].type_code = "I" 
		LET pa_details[fv_idx].desc_text = pr_product.desc_text 

		LET pa_contractdetl[fv_idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pa_contractdetl[fv_idx].type_code = "I" 
		LET pa_contractdetl[fv_idx].acct_mask = pv_stock_acct_code 
		LET pa_contractdetl[fv_idx].contract_code = 
		pr_contracthead.contract_code 
		LET pa_contractdetl[fv_idx].cust_code = 
		pr_contracthead.cust_code 
		LET pa_contractdetl[fv_idx].part_code = pr_product.part_code 
		LET pa_contractdetl[fv_idx].desc_text = pr_product.desc_text 

	END FOREACH 

	LET pv_dtllne_cnt = fv_idx 

	LET msgresp = kandoomsg("A",3542,fv_idx) 
	# ## detail lines were added TO the contract - any key TO continue

END FUNCTION 
