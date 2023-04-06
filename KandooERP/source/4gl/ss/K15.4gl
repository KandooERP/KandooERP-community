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
#  K15 Add corporate subscriptions. User must enter corporate cust THEN
#      subs can be created FOR other customers but single invoice will
#      be created FOR corporate customer. This can only be used FOR the
#      following sub_types inv_ind = ""
#      1 invoice now: creates subscription RECORD AND invoice
#      4 pre-paid : creates subscription , cashreceipt AND invoice
#
#  K15.4gl :FUNCTION input_corp()
#           INPUT corporate debtor details
#  K15.4gl :FUNCTION scan_subs()
#           INPUT ARRAY of subs
#  K15.4gl :FUNCTION process_sub(pr_mode,pr_sub_num)
#           pr_mode = "CORP"
#           Calls create & edit functions INITIALIZE_sub,
#                                         header_entry, lineitem_scan,
#                                         sub_summary,K11_enter_receipt,
#                                         K11_write_sub
#  K15.4gl :FUNCTION INITIALIZE_sub(pr_sub_num)
#           sets up subhead RECORD defaults
#  K11a.4gl:FUNCTION header_entry(pr_mode)
#           add/edit of subhead details
#  K11b.4gl:FUNCTION lineitem_scan()
#           ARRAY add/edit of subdetl records
#  K11b.4gl:FUNCTION insert_line()
#           INITIALIZE defaults AND INSERT new t_subdetl
#  K11b.4gl:FUNCTION update_line()
#           Update t_subdetl record
#  K11b.4gl:FUNCTION disp_total()
#           displays subhead totals WHILE in lineitem_scan
#  K11b.4gl:FUNCTION validate_field(pr_field_num)
#           Called FROM lineitem scan AND sub_detail TO validate data entry
#  K11b.4gl:FUNCTION sched_issue(pr_verbose_num)
#           Creates subschedule records AND Calculates
#           subscription quantity FOR scheduled type products
#           pr_verbose_num = TRUE - Allows editing of issue dates & qty
#           pr_verbose_num = FALSE - no DISPLAY OR INPUT - returns qty
#  K11c.4gl:FUNCTION sub_detail()
#           called by F8 key FROM lineitem_scan
#           form add/edit of subdetl records
#  K11c.4gl:FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind)
#           gets unit_amt (price) details FROM prodstatus according TO
#           customer price level
#  K11c.4gl:FUNCTION unit_tax(pr_ware_code,pr_part_code,pr_unit_amt)
#           calculates unit_tax_amt
#  K11d.4gl:FUNCTION sub_summary(pr_mode)
#           INPUT of freight AND carrier details
#  K11d.4gl:FUNCTION K11_subhead_disp_summ() 
#           called FROM sub_summary
#           recalculates AND displays subhead totals
#  K11e.4gl:FUNCTION insert_sub()
#           creates new subhead RECORD with appropriate defaults
#  K11e.4gl:FUNCTION K11_write_sub()
#           updates subhead, subdetl records
#           creates other transactions according TO subhead.inv_ind
#  K11f.4gl:FUNCTION auto_apply(pr_cash_num,pr_inv_num)
#           checks receipt AND invoice TO see IF application IS possible
#           IF application can be made THEN calls
#           FUNCTION receipt_apply (A31c.4gl)
#  K11f.4gl:FUNCTION cancel_sub(pr_sub_num)
#           reduces subs TO already issued qty so no further processing will
#           take place. IF sub IS invoiced THEN credit will be created FOR
#           non issued quantity
#  K11g.4gl:FUNCTION K11_enter_receipt()
#           enter cashreceipt details FOR prepaid subs.
#           Amount defaults TO unpaid amount of sub

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K1_GROUP_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 

MAIN 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num, 
	pr_prompt_text CHAR(60) 

	#Initial UI Init
	CALL setModuleId("K15") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET yes_flag = "Y" 
	LET no_flag = "N" 
	CALL create_table("subhead","t_subhead","","N") 
	CALL create_table("subdetl","t_subdetl","","N") 
	CALL create_table("subschedule","t_subschedule","","N") 
	CALL create_table("cashreceipt","t_cashreceipt","","N") 
	CALL create_table("invoicehead","t_invoicehead","","N") 
	CALL create_table("invoicedetl","t_invoicedetl","","N") 
	SELECT * INTO pr_rec_kandoouser.* 
	FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
	SELECT * INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("A",5001,"") 
		#A5001 GL Parameters are NOT found"
		EXIT program 
	END IF 
	SELECT * INTO pr_ssparms.* 
	FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("K",5001,"") 
		#5001 " SS Parameters are NOT found"
		EXIT program 
	END IF 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("A",5002,"") 
		#5002 " AR Parameters are NOT found"
		EXIT program 
	ELSE 
	LET pr_prompt_text = pr_arparms.inv_ref1_text clipped, 
	"......................" 
	LET pr_inv_prompt = pr_prompt_text clipped 
END IF 
SELECT country.* INTO pr_country.* 
FROM country, 
company 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND country.country_code = company.country_code 
LET pr_prompt_text = pr_country.state_code_text clipped, 
".................." 
LET pr_country.state_code_text = pr_prompt_text 
LET pr_prompt_text = pr_country.post_code_text clipped, 
".................." 
LET pr_country.post_code_text = pr_prompt_text 
OPEN WINDOW k143 at 2,3 WITH FORM "K143" 
attribute(border,white,MESSAGE line first) 

MENU " Corporate subscriptions" 
	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 
		
	COMMAND "Add" " Add Corporate subscriptions" 

		IF input_corp() THEN 
			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start(getmoduleid(),"K15_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	
			START REPORT K15_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			LET glob_rpt_idx = l_rpt_idx #temporary until we move it to local scope
			#------------------------------------------------------------

			OPEN WINDOW K144 WITH FORM "K144" --	attributes(border,white) 
			CALL scan_subs() 
			CLOSE WINDOW K144

			#------------------------------------------------------------
			FINISH REPORT K15_rpt_list
			CALL rpt_finish("K15_rpt_list")
			#------------------------------------------------------------
			 
		END IF 

	ON ACTION "PRINT MANAGER" 
		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
		CALL run_prog("URS","","","","") 

	COMMAND KEY("E",interrupt)"Exit" " EXIT TO menus" 
		EXIT MENU 
	COMMAND KEY (control-w) 
		CALL kandoohelp("") 
END MENU 
CLOSE WINDOW k143 
END MAIN 

FUNCTION input_corp() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_customership RECORD LIKE customership.*, 
	pr_corpcust RECORD LIKE customer.*, 
	pr_holdreas RECORD LIKE holdreas.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	ware_text LIKE warehouse.desc_text, 
	pr_substype RECORD LIKE substype.*, 
	pr_sub_type LIKE subhead.sub_type_code, 
	pr_start_year, pr_end_year INTEGER, 
	pr_save_char CHAR(1), 
	i SMALLINT 
	DEFINE l_temp_text CHAR(500) 
	DELETE FROM t_subhead WHERE 1=1 
	DELETE FROM t_subschedule WHERE 1=1 
	DELETE FROM t_subdetl WHERE 1=1 

	CLEAR FORM 
	DISPLAY pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_inv_prompt 
	TO sr_prompts.*, 
	inv_ref1_text 
	attribute(white) 
	LET msgresp = kandoomsg("U",1020,"Corporate Debtor") 
	#1020 Enter Details - ESC TO continue
	INITIALIZE pr_csubhead.* TO NULL 
	INITIALIZE pr_customer.* TO NULL 
	LET pr_paid_amt = 0 
	LET pr_csubhead.sub_date = today 
	INPUT BY NAME pr_csubhead.cust_code, 
	pr_csubhead.sub_date, 
	pr_csubhead.sub_type_code, 
	pr_csubhead.start_date, 
	pr_csubhead.end_date, 
	pr_csubhead.ord_text, 
	pr_csubhead.hold_code, 
	pr_csubhead.ware_code, 
	pr_csubhead.sales_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			DISPLAY BY NAME pr_customer.name_text 

			DISPLAY pr_customer.name_text, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(cust_code) 
					LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET pr_csubhead.cust_code = l_temp_text 
					END IF 
					NEXT FIELD cust_code 
				WHEN infield(hold_code) 
					LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_text IS NOT NULL THEN 
						LET pr_csubhead.hold_code = l_temp_text 
					END IF 
					NEXT FIELD hold_code 
				WHEN infield(sub_type_code) 
					LET l_temp_text = show_substype(glob_rec_kandoouser.cmpy_code,"inv_ind in ('1','4')") 
					IF l_temp_text IS NOT NULL THEN 
						LET pr_csubhead.sub_type_code = l_temp_text 
					END IF 
					NEXT FIELD sub_type_code 
				WHEN infield(sales_code) 
					LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET pr_csubhead.sales_code = l_temp_text 
					END IF 
					NEXT FIELD sales_code 
				WHEN infield(ware_code) 
					LET l_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET pr_csubhead.ware_code = l_temp_text 
					END IF 
					NEXT FIELD ware_code 
			END CASE 

		ON KEY (F8) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_csubhead.cust_code) --customer details / customer invoice submenu 

		ON KEY (F9) 
			IF pr_csubhead.cust_code IS NOT NULL THEN 
				LET pr_subhead.tax_code = pr_csubhead.tax_code 
				LET pr_subhead.term_code = pr_csubhead.term_code 
				LET pr_subhead.sub_date = pr_csubhead.sub_date 
				LET pr_subhead.currency_code = pr_csubhead.currency_code 
				LET pr_subhead.conv_qty = pr_csubhead.conv_qty 
				IF pay_detail() THEN 
					LET pr_csubhead.tax_code = pr_subhead.tax_code 
					LET pr_csubhead.term_code = pr_subhead.term_code 
					LET pr_csubhead.sub_date = pr_subhead.sub_date 
					LET pr_csubhead.currency_code = pr_subhead.currency_code 
					LET pr_csubhead.conv_qty = pr_subhead.conv_qty 
				END IF 
			END IF 
		AFTER FIELD cust_code 
			IF pr_csubhead.cust_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102" Cust. must be Entered"
				LET pr_csubhead.cust_code = pr_customer.cust_code 
				CLEAR name_text 
				NEXT FIELD cust_code 
			ELSE 
			IF pr_customer.cust_code != pr_csubhead.cust_code 
			OR pr_customer.cust_code IS NULL THEN 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_csubhead.cust_code 
				AND delete_flag = "N" 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105" Cust NOT found - Try Window"
					NEXT FIELD cust_code 
				ELSE 
				IF pr_customer.hold_code IS NOT NULL THEN 
					SELECT reason_text INTO l_temp_text 
					FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = pr_customer.hold_code 
					LET msgresp=kandoomsg("E",7018,l_temp_text) 
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
							SELECT reason_text INTO l_temp_text 
							FROM holdreas 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND hold_code = pr_corpcust.hold_code 
							LET msgresp=kandoomsg("E",7040,l_temp_text) 
							#7040 Warning :Corporate Customer 'On Hold'"
						END IF 
						IF pr_corpcust.cred_bal_amt < 0 THEN 
							LET msgresp=kandoomsg("E",7041,"") 
							#7041 Warning: Corporate Customer has exceeded credit
						END IF 
					END IF 
				END IF 
				SELECT count(*) INTO i 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_csubhead.cust_code 
				CASE 
					WHEN i = 0 
					WHEN i = 1 
						SELECT ship_code 
						INTO pr_csubhead.ship_code 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_csubhead.cust_code 
					OTHERWISE 
						SELECT unique 1 FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = pr_csubhead.cust_code 
						AND ship_code = pr_csubhead.cust_code 
						IF sqlca.sqlcode = notfound THEN 
							DECLARE c_custship CURSOR FOR 
							SELECT ship_code FROM customership 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = pr_csubhead.cust_code 
							OPEN c_custship 
							FETCH c_custship INTO pr_csubhead.ship_code 
						ELSE 
						LET pr_csubhead.ship_code = pr_csubhead.cust_code 
					END IF 
				END CASE 
				SELECT * INTO pr_customership.* 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_csubhead.cust_code 
				AND ship_code = pr_csubhead.ship_code 
				LET pr_csubhead.ware_code = pr_customership.ware_code 
				LET pr_csubhead.term_code = pr_customer.term_code 
				LET pr_csubhead.tax_code = pr_customer.tax_code 
				LET pr_csubhead.hand_tax_code = pr_customer.tax_code 
				LET pr_csubhead.freight_tax_code = pr_customer.tax_code 
				LET pr_csubhead.sales_code = pr_customer.sale_code 
				LET pr_csubhead.territory_code = pr_customer.territory_code 
				LET pr_csubhead.cond_code = pr_customer.cond_code 
				LET pr_csubhead.invoice_to_ind = pr_customer.invoice_to_ind 
				LET pr_csubhead.currency_code = pr_customer.currency_code 
				SELECT desc_text INTO ware_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_csubhead.ware_code 
				IF status = notfound THEN 
					LET ware_text = "**********" 
				END IF 
				DISPLAY BY NAME ware_text 

				SELECT * INTO pr_salesperson.* 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = pr_csubhead.sales_code 
				IF status = notfound THEN 
					LET pr_salesperson.name_text = "**********" 
				END IF 
				DISPLAY pr_salesperson.name_text TO sale_text 

			END IF 
		END IF 
	END IF 
		BEFORE FIELD sub_date 
			DISPLAY BY NAME pr_csubhead.sub_date, 
			pr_csubhead.cust_code, 
			pr_customer.name_text, 
			pr_csubhead.ware_code, 
			pr_csubhead.sales_code 

			DISPLAY pr_customer.name_text, 
			pr_customer.addr1_text, 
			pr_customer.addr2_text, 
			pr_customer.city_text, 
			pr_customer.state_code, 
			pr_customer.post_code, 
			pr_customer.country_code --@db-patch_2020_10_04--
			TO sr_cust_addr.* 

		AFTER FIELD sub_date 
			IF pr_csubhead.sub_date IS NULL THEN 
				LET pr_csubhead.sub_date = today 
				NEXT FIELD sub_date 
			END IF 
			IF pr_csubhead.currency_code = pr_glparms.base_currency_code THEN 
				LET pr_csubhead.conv_qty = 1 
			ELSE 
			
			IF pr_csubhead.conv_qty IS NULL OR pr_csubhead.conv_qty = 0 THEN 
				LET pr_csubhead.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					pr_csubhead.currency_code, 
					pr_csubhead.sub_date,
					CASH_EXCHANGE_SELL) 
			END IF 
		END IF 
		
		AFTER FIELD hold_code 
			CLEAR reason_text 
			IF pr_csubhead.hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO pr_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = pr_csubhead.hold_code 
				
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9045,"")	#9045 Sales Hold Code NOT found - Try Window "
					NEXT FIELD hold_code 
				ELSE 
				DISPLAY BY NAME pr_holdreas.reason_text 

			END IF 
		END IF 
		BEFORE FIELD sub_type_code 
			LET pr_sub_type = pr_csubhead.sub_type_code
			 
		AFTER FIELD sub_type_code 
			IF pr_csubhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered
				NEXT FIELD sub_type_code 
			END IF 
			
			SELECT * INTO pr_substype.* 
			FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_csubhead.sub_type_code 
			AND inv_ind in ("1","4") 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9112,"Subscription Type")	#9105 RECORD NOT found - try window
				NEXT FIELD sub_type_code 
			ELSE 
			DISPLAY BY NAME pr_substype.desc_text 

		END IF
		 
		IF pr_sub_type IS NULL OR pr_sub_type != pr_csubhead.sub_type_code THEN 
			LET pr_start_year = year(pr_csubhead.sub_date) 
			IF month(pr_csubhead.sub_date) < pr_substype.start_mth_num THEN 
				LET pr_start_year = pr_start_year - 1 
			END IF 
		
			LET pr_end_year = pr_start_year 
		
			IF pr_substype.start_mth_num > pr_substype.end_mth_num THEN 
				LET pr_end_year = pr_end_year + 1 
			END IF 
			LET pr_csubhead.start_date = mdy(pr_substype.start_mth_num, 
			pr_substype.start_day_num, 
			pr_start_year) 
			LET pr_csubhead.end_date = mdy(
				pr_substype.end_mth_num, 
				pr_substype.end_day_num, 
				pr_end_year) 
			
			DISPLAY BY NAME 
				pr_csubhead.start_date, 
				pr_csubhead.end_date 

		END IF
		 
		AFTER FIELD start_date 
			IF pr_csubhead.start_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered
				NEXT FIELD start_date 
			END IF 
		
		AFTER FIELD end_date 
			IF pr_csubhead.end_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD end_date 
			END IF 
			IF pr_csubhead.end_date < pr_csubhead.start_date THEN 
				LET msgresp = kandoomsg("K",9105,"")	#9105 Value must be entered
				NEXT FIELD start_date 
			END IF 
		
		AFTER FIELD ware_code 
			CLEAR ware_text 
			IF pr_csubhead.ware_code IS NULL THEN 
				LET msgresp=kandoomsg("U",9102,"") 
				#9102 Warehouse code must be entered "
				NEXT FIELD ware_code 
			ELSE 
			SELECT desc_text 
			INTO ware_text 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_csubhead.ware_code 
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
			IF pr_csubhead.sales_code IS NULL THEN 
				LET msgresp=kandoomsg("E",9062,"") 
				#9062 Saelsperson code must be entered "
				NEXT FIELD sales_code 
			END IF 
			SELECT * INTO pr_salesperson.* 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = pr_csubhead.sales_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("E",9050,"") 
				#9050 Sales ORDER salesperson NOT found - Try Window "
				NEXT FIELD sales_code 
			END IF 
			DISPLAY pr_salesperson.name_text TO sale_text 

			LET pr_csubhead.mgr_code = pr_salesperson.mgr_code 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_csubhead.sub_type_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD sub_type_code 
				END IF 
				IF pr_csubhead.start_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD start_date 
				END IF 
				IF pr_csubhead.end_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD end_date 
				END IF 
				IF pr_csubhead.end_date < pr_csubhead.start_date THEN 
					LET msgresp = kandoomsg("K",9105,"") 
					#9105 END date must be greater than start date
					NEXT FIELD start_date 
				END IF 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_csubhead.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 Warehouse Code NOT found - Try Window "
					NEXT FIELD ware_code 
				END IF 
				IF pr_customer.ord_text_ind = "Y" THEN 
					IF pr_csubhead.ord_text IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD ord_text 
					END IF 
				END IF 
				SELECT * INTO pr_salesperson.* 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = pr_csubhead.sales_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("E",9050,"") 
					#9050 Sales ORDER salesperson NOT found - Try Window "
					NEXT FIELD sales_code 
				END IF 
				LET pr_csubhead.mgr_code = pr_salesperson.mgr_code 
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


FUNCTION scan_subs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num, 
	pr_scroll_flag CHAR(1), 
	pa_subhead array[500] OF RECORD 
		scroll_flag CHAR(1), 
		sub_num LIKE subhead.sub_num, 
		cust_code LIKE subhead.cust_code, 
		sub_type_code LIKE subhead.sub_type_code, 
		start_date LIKE subhead.start_date, 
		end_date LIKE subhead.end_date, 
		status_ind LIKE subhead.status_ind 
	END RECORD, 
	#      pa_subhead2 array[500] of record
	#         name_text LIKE customer.name_text
	#      END RECORD,
	pr_name_text LIKE customer.name_text, 
	corp_text LIKE customer.name_text, 
	pr_value,next_action SMALLINT, 
	i,j,del_cnt,idx,scrn SMALLINT 

	DECLARE c_subhead CURSOR FOR 
	SELECT * FROM t_subhead 
	WHERE corp_cust_code = pr_csubhead.cust_code 

	SELECT name_text INTO corp_text 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_csubhead.cust_code 

	DISPLAY pr_csubhead.cust_code, 
	corp_text 
	TO corp_cust_code, 
	corp_text 

	LET idx = 0 
	FOREACH c_subhead INTO pr_subhead.* 
		LET idx = idx + 1 
		LET pa_subhead[idx].scroll_flag = NULL 
		LET pa_subhead[idx].sub_num = pr_subhead.sub_num 
		LET pa_subhead[idx].cust_code = pr_subhead.cust_code 
		##      SELECT name_text
		#        INTO pa_subhead2[idx].name_text
		#        FROM customer
		#       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#         AND cust_code = pr_subhead.cust_code
		#      IF sqlca.sqlcode = NOTFOUND THEN
		#         LET pa_subhead2[idx].name_text = "**********"
		#      END IF
		LET pa_subhead[idx].start_date = pr_subhead.start_date 
		LET pa_subhead[idx].end_date = pr_subhead.end_date 
		LET pa_subhead[idx].sub_type_code = pr_subhead.sub_type_code 
		LET pa_subhead[idx].status_ind = pr_subhead.status_ind 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",9100,"200") 
			##First 500 orders selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_subhead[1].* TO NULL 
	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("U",1100,"") 
	#1100" F1 TO Add - F2 TO Cancel - RETURN TO Edit
	INPUT ARRAY pa_subhead WITHOUT DEFAULTS FROM sr_subhead.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_subhead[idx].scroll_flag 
			DISPLAY pa_subhead[idx].* 
			TO sr_subhead[scrn].* 

			SELECT name_text INTO pr_name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pa_subhead[idx].cust_code 
			IF sqlca.sqlcode = notfound THEN 
				LET pr_name_text = "**********" 
			END IF 
			DISPLAY pr_name_text TO name_text 

		AFTER FIELD scroll_flag 
			LET pa_subhead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_subhead[idx].scroll_flag 
			TO sr_subhead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_subhead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD sub_num 
			IF pa_subhead[idx].sub_num IS NOT NULL THEN 
				OPEN WINDOW k129 at 2,3 WITH FORM "K129" 
				attribute(border) 
				CALL process_sub("CORP",pa_subhead[idx].sub_num) 
				RETURNING pr_sub_num 
				CLOSE WINDOW k129 
				SELECT sub_num, 
				cust_code, 
				sub_type_code, 
				start_date, 
				end_date, 
				status_ind 
				INTO pa_subhead[idx].sub_num, 
				pa_subhead[idx].cust_code, 
				pa_subhead[idx].sub_type_code, 
				pa_subhead[idx].start_date, 
				pa_subhead[idx].end_date, 
				pa_subhead[idx].status_ind 
				FROM t_subhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_subhead[idx].sub_num 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN 
				CLEAR sr_subhead[scrn].* 
				NEXT FIELD scroll_flag #informix bug 
			END IF 
			OPEN WINDOW k127 at 2,3 WITH FORM "K127" 
			attribute(border) 
			LET pr_sub_num = process_sub("CORP","") 
			CLOSE WINDOW k127 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			SELECT sub_num, 
			cust_code, 
			sub_type_code, 
			start_date, 
			end_date, 
			status_ind 
			INTO pa_subhead[idx].sub_num, 
			pa_subhead[idx].cust_code, 
			pa_subhead[idx].sub_type_code, 
			pa_subhead[idx].start_date, 
			pa_subhead[idx].end_date, 
			pa_subhead[idx].status_ind 
			FROM t_subhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_sub_num 
			IF status = notfound THEN 
				FOR i = idx TO 499 
					LET pa_subhead[i].* = pa_subhead[i+1].* 
					IF pa_subhead[i].cust_code IS NULL THEN 
						LET pa_subhead[i].sub_num = "" 
						LET pa_subhead[i].start_date = "" 
						LET pa_subhead[i].end_date = "" 
					END IF 
					IF scrn <= 11 THEN 
						DISPLAY pa_subhead[i].* 
						TO sr_subhead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_subhead[i].cust_code IS NULL THEN 
						CALL set_count(i-1) 
						EXIT FOR 
					END IF 
				END FOR 
				#         ELSE
				#            SELECT name_text INTO pa_subhead2[idx].name_text
				#              FROM customer
				#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#               AND cust_code = pa_subhead[idx].cust_code
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF pa_subhead[idx].cust_code IS NOT NULL THEN 
				DELETE FROM t_subhead 
				WHERE sub_num = pa_subhead[idx].sub_num 
				DELETE FROM t_subdetl 
				WHERE sub_num = pa_subhead[idx].sub_num 
				DELETE FROM t_subschedule 
				WHERE sub_num = pa_subhead[idx].sub_num 
				FOR i = idx TO 499 
					LET pa_subhead[i].* = pa_subhead[i+1].* 
					IF pa_subhead[i].cust_code IS NULL THEN 
						LET pa_subhead[i].sub_num = NULL 
					END IF 
					IF scrn <= 11 THEN 
						DISPLAY pa_subhead[i].* TO sr_subhead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_subhead[i].cust_code IS NULL THEN 
						EXIT FOR 
					END IF 
				END FOR 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_subhead[idx].* 
			TO sr_subhead[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			LET next_action = ring_menu() 
			CASE 
				WHEN next_action = 1 # save details 
					LET msgresp = kandoomsg("E",1005,"") 
					#1005 Updating Database - pls. wait
					IF insert_sub() THEN 
						LET pr_sub_num = K11_write_sub("CORP") 
					ELSE 
					NEXT FIELD scroll_flag 
				END IF 
				WHEN next_action = 2 # discard details 
					EXIT INPUT 
				WHEN next_action = 3 # keep editing 
					NEXT FIELD scroll_flag 
			END CASE 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION process_sub(pr_mode,pr_sub_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_hold_sub CHAR(1), 
	pr_mask_code LIKE customertype.acct_mask_code, 
	pr_substype RECORD LIKE substype.*, 
	pr_sub_num LIKE subhead.sub_num 

	CALL initialize_sub(pr_sub_num) 
	LET pr_sub_num = NULL 
	DISPLAY pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_inv_prompt 
	TO sr_prompts.*, 
	inv_ref1_text 
	attribute(white) 
	WHILE header_entry(pr_mode) 
		IF pr_customer.corp_cust_code IS NOT NULL AND 
		pr_customer.corp_cust_ind = "1" THEN 
			SELECT type_code INTO pr_customer.type_code 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.corp_cust_code 
		END IF 
		SELECT acct_mask_code INTO pr_mask_code 
		FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_customer.type_code 
		AND acct_mask_code IS NOT NULL 
		IF status = notfound THEN 
			LET pr_subhead.acct_override_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code, 
			pr_rec_kandoouser.acct_mask_code) 
		ELSE 
		LET pr_subhead.acct_override_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code,pr_mask_code) 
	END IF 
	IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN, pr_subhead.acct_override_code) THEN 
		#7031Warning: Automatic Invoice Numbering NOT Set up"
		LET msgresp=kandoomsg("A",7031,"") 
	END IF 
	DELETE FROM t_subhead 
	WHERE sub_num = pr_subhead.sub_num 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
	OPEN WINDOW k130 at 2,3 WITH FORM "K130" 
	attribute(border,white) 
	WHILE lineitem_scan() 
		OPEN WINDOW k132 at 2,3 WITH FORM "K132" 
		attribute(border) 
		IF sub_summary(pr_mode) THEN 
			LET pr_sub_num = pr_subhead.sub_num 
			CLOSE WINDOW k132 
			EXIT WHILE 
		ELSE 
		LET pr_sub_num = NULL 
	END IF 
	CLOSE WINDOW k132 
	IF pr_sub_num IS NOT NULL THEN 
		EXIT WHILE 
	END IF 
END WHILE 
CLOSE WINDOW k130 
IF pr_sub_num IS NOT NULL THEN 
	EXIT WHILE 
END IF 
END WHILE 
RETURN pr_sub_num 
END FUNCTION 


FUNCTION initialize_sub(pr_sub_num) 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num 

	INITIALIZE pr_customer.* TO NULL 
	SELECT rowid,* INTO pr_growid,pr_subhead.* 
	FROM t_subhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_sub_num 
	IF status = notfound THEN 
		INITIALIZE pr_subhead.* TO NULL 
		LET pr_subhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subhead.ware_code = pr_csubhead.ware_code 
		LET pr_subhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_subhead.entry_date = today 
		LET pr_subhead.rev_date = today 
		LET pr_subhead.sub_date = pr_csubhead.sub_date 
		LET pr_subhead.sub_type_code = pr_csubhead.sub_type_code 
		LET pr_subhead.start_date = pr_csubhead.start_date 
		LET pr_subhead.end_date = pr_csubhead.end_date 
		LET pr_subhead.goods_amt = 0 
		LET pr_subhead.freight_amt = 0 
		LET pr_subhead.hand_amt = 0 
		LET pr_subhead.freight_tax_amt = 0 
		LET pr_subhead.hand_tax_amt = 0 
		LET pr_subhead.tax_amt = 0 
		LET pr_subhead.disc_amt = 0 
		LET pr_subhead.total_amt = 0 
		LET pr_subhead.cost_amt = 0 
		LET pr_subhead.status_ind = "U" 
		LET pr_subhead.line_num = 0 
		LET pr_subhead.rev_num = 0 
		LET pr_subhead.prepaid_flag = no_flag 
		LET pr_subhead.invoice_to_ind = "1" 
		LET pr_subhead.freight_inv_amt = 0 
		LET pr_subhead.hand_inv_amt = 0 
		LET pr_subhead.frttax_inv_amt = 0 
		LET pr_subhead.hndtax_inv_amt = 0 
		LET pr_currsub_amt = 0 
		LET pr_subhead.corp_flag = "Y" 
		LET pr_subhead.corp_cust_code = pr_csubhead.cust_code 
		INSERT INTO t_subhead VALUES (pr_subhead.*) 
		LET pr_growid = sqlca.sqlerrd[6] 
		LET pr_subhead.sub_num = pr_growid 
		UPDATE t_subhead SET sub_num = pr_subhead.sub_num 
		WHERE rowid = pr_subhead.sub_num 
	END IF 

END FUNCTION 

FUNCTION enter_hold() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_holdreas RECORD LIKE holdreas.* 
	DEFINE l_temp_text CHAR(500) #moved FROM GLOBALS 

	OPEN WINDOW k133 at 16,12 WITH FORM "K133" 
	attributes(border,white) 
	LET msgresp=kandoomsg("U",1020,"Hold Code") 
	#1020 Subscription Hold Code
	LET pr_holdreas.hold_code = pr_subhead.hold_code 
	INPUT BY NAME pr_holdreas.hold_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET pr_holdreas.hold_code = l_temp_text 
			END IF 
			NEXT FIELD hold_code 

		BEFORE FIELD hold_code 
			SELECT reason_text 
			INTO pr_holdreas.reason_text 
			FROM holdreas 
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
	CLOSE WINDOW k133 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	LET pr_subhead.hold_code = pr_holdreas.hold_code 
	RETURN true 
END IF 
END FUNCTION 

FUNCTION ring_menu() 
	DEFINE next_action SMALLINT 

	OPEN WINDOW w1_k15 at 8,6 WITH 2 rows,64 COLUMNS 
	attribute(border) 
	MENU " Corporate subscriptions" 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Save" " Save subscriptions TO database" 
			LET next_action = 1 
			EXIT MENU 
		COMMAND "Receipt" " Enter cash receipt FOR subscriptions" 
			LET pr_paid_amt = K11_enter_receipt("CORP") 
			NEXT option "Save" 
		COMMAND "Hold" " Hold subscription TO prevent further processing" 
			IF enter_hold() THEN 
			END IF 
		COMMAND "Discard" " Discard Corporate subscriptions" 
			LET next_action = 2 
			EXIT MENU 
		COMMAND KEY("E",interrupt)"Exit" 
			" RETURN TO editting subscriptions" 
			LET next_action = 3 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW w1_k15 

	RETURN next_action 

END FUNCTION 
