
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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../jm/J_JM_GLOBALS.4gl"
GLOBALS "../jm/J9_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J91_GLOBALS.4gl"

GLOBALS 

	DEFINE pr_coa RECORD LIKE coa.* 
	DEFINE pr_job RECORD LIKE job.* 
	DEFINE pr_jobvars RECORD LIKE jobvars.* 
	DEFINE pr_activity RECORD LIKE activity.* 
	DEFINE pr_jmparms RECORD LIKE jmparms.* 
	DEFINE pr_inparms RECORD LIKE inparms.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
	DEFINE pr_prodledg RECORD LIKE prodledg.* 
	DEFINE pr_jmresource RECORD LIKE jmresource.* 
	DEFINE pr_customer RECORD LIKE customer.* 
	DEFINE pr_customership RECORD LIKE customership.* 
	DEFINE pr_jobledger RECORD LIKE jobledger.* 
	DEFINE pr_warehouse RECORD LIKE warehouse.* 
	DEFINE ans CHAR(1) 
	DEFINE pr_bill_way_text CHAR(11) 
	DEFINE err_continue CHAR(1) 
	DEFINE err_message CHAR(40) 
	DEFINE pr_pricex_amt LIKE prodstatus.price1_amt 
	DEFINE pr_menu_return CHAR(1) 
	DEFINE pr_return_status SMALLINT 
	DEFINE pr_wgted_cost_amt LIKE prodstatus.wgted_cost_amt 

END GLOBALS 

###########################################################################
# MAIN
#
# J91 - Job Management Product Issue
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("J91") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL get_kandoo_user() RETURNING pr_rec_kandoouser.* 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 		
		LET msgresp = kandoomsg("J",1501," ") #ERROR "JM Parameters NOT SET up"
		SLEEP 5 
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
				LET msgresp = kandoomsg("I",5002," ") #ERROR "Inventory parameters NOT found - Refer Menu IZP"
		EXIT program 
	END IF 

	LET pr_jobledger.trans_date = today 
	LET pr_jobledger.trans_qty = 0 
	LET pr_jobledger.trans_amt = 0 
	LET pr_jobledger.charge_amt = 0 

	INITIALIZE pr_jmresource.* TO NULL 
	OPEN WINDOW j152 with FORM "J152" -- alch kd-747 
	CALL winDecoration_j("J152") -- alch kd-747 
	WHILE getitem() 
		#      OPEN WINDOW w1 AT 8,15 with 3 rows,55 columns
		#         attribute (border)      -- alch KD-747
		MENU " Stores Issue" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","J91","menu-stores_issues-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Save " "Save this stores issue TO the database" 
				IF write_issue() THEN 
					LET msgresp = kandoomsg("J",8901,pr_jobledger.trans_source_num) 
					IF msgresp = "Y" THEN 
						LET pr_menu_return = "A" 
					ELSE 
						LET pr_menu_return = "Q" 
					END IF 
					EXIT MENU 
				END IF 
			COMMAND "Edit" " Edit this stores issue before adding" 
				LET pr_menu_return = "E" 
				EXIT MENU 
			COMMAND "New" " Abandon this Issue AND enter another" 
				LET pr_menu_return = "A" 
				EXIT MENU 
			COMMAND KEY(interrupt) "Exit" " RETURN TO main menus" 
				LET pr_menu_return = "Q" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 

		#      CLOSE WINDOW w1      -- alch KD-747

		CASE pr_menu_return 
			WHEN "E" 
				EXIT CASE 
			WHEN "A" 
				INITIALIZE pr_jobledger.* TO NULL 
				INITIALIZE pr_prodledg.* TO NULL 
				INITIALIZE pr_jmresource.* TO NULL 
				LET pr_jobledger.trans_date = today 
				CLEAR FORM 
			WHEN "Q" 
				EXIT WHILE 
			OTHERWISE 
				EXIT CASE 
		END CASE 

		LET int_flag = false 
		LET quit_flag = false 
	END WHILE 

	CLOSE WINDOW j152 

END MAIN 

###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION getitem()
#
# 
###########################################################################
FUNCTION getitem() 
	DEFINE tmp_res_code LIKE jobledger.trans_source_text 
	DEFINE pr_return_status SMALLINT 
	DEFINE pr_save_ware_code LIKE warehouse.ware_code 
	DEFINE pr_save_part_code LIKE product.part_code 
	DEFINE str CHAR (3000) 


	INITIALIZE pr_save_ware_code TO NULL 
	WHILE true 
		INPUT BY NAME pr_jobledger.job_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J91","input-pr_jobledger-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				LET pr_jobledger.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_jobledger.job_code 

				NEXT FIELD job_code 

			AFTER FIELD job_code 
				IF pr_jobledger.job_code IS NULL THEN 
					#ERROR "Job Code must be entered"
					LET msgresp = kandoomsg("J",9508," ") 
					NEXT FIELD job_code 
				END IF 


				DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
				DISPLAY "see jm/J91.4gl" 
				EXIT program (1) 


				LET str = 
				" SELECT job.*, ", 
				" customer.*, ", 
				" customership.* ", 
				" INTO pr_job.*, ", 
				" pr_customer.*, ", 
				" pr_customership.* ", 
				" FROM job, ", 
				" customer, ", 
				" outer customership ", 
				" WHERE job.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
				" AND job.job_code = ", pr_jobledger.job_code, 
				" AND customer.cmpy_code = ",glob_rec_kandoouser.cmpy_code, 
				" AND customer.cust_code = job.cust_code ", 
				" AND customership.cmpy_code = ",glob_rec_kandoouser.cmpy_code, 
				" AND customership.cust_code = customer.cust_code ", 
				" AND customership.ship_code = customer.cust_code " 


				PREPARE dee FROM str 
				DECLARE j1_c CURSOR FOR dee 
				OPEN j1_c 
				FETCH j1_c 

				IF status = notfound THEN 
					#ERROR " Job NOT found - Use window FOR help"
					LET msgresp = kandoomsg("J",9509," ") 
					NEXT FIELD job_code 
				END IF 

				DISPLAY BY NAME 
				pr_job.title_text, 
				pr_job.cust_code, 
				pr_customer.name_text, 
				pr_customer.inv_level_ind, 
				pr_customership.ware_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 

		IF pr_save_ware_code IS NULL THEN 
			LET pr_prodledg.ware_code = pr_customership.ware_code 
		END IF 
		#LET pr_prodledg.part_code = " "
		LET msgresp = kandoomsg("J",1545,"") 
		# MESSAGE "F7 TO view stock STATUS, F8 TO alter Allocation Mode, ESC cont."

		INPUT BY NAME pr_jobledger.var_code, 
		pr_jobledger.activity_code, 
		pr_jobledger.trans_date, 
		pr_jobledger.year_num, 
		pr_jobledger.period_num, 
		pr_prodledg.ware_code, 
		pr_prodledg.part_code, 
		pr_jobledger.trans_source_text, 
		pr_jobledger.trans_qty, 
		pr_wgted_cost_amt, 
		pr_jobledger.trans_amt, 
		pr_jobledger.charge_amt 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J91","input-pr_jobledger-2") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield (part_code) 
						LET pr_prodledg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_prodledg.part_code 

						NEXT FIELD part_code 

					WHEN infield (ware_code) 
						LET pr_prodledg.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_prodledg.ware_code 

						NEXT FIELD ware_code 

					WHEN infield (var_code) 
						LET pr_jobledger.var_code = 
						show_jobvars(glob_rec_kandoouser.cmpy_code, pr_jobledger.job_code) 
						DISPLAY BY NAME pr_jobledger.var_code 

						NEXT FIELD var_code 

					WHEN infield (activity_code) 
						LET pr_jobledger.activity_code = 
						show_activity(glob_rec_kandoouser.cmpy_code, pr_jobledger.job_code, 
						pr_jobledger.var_code) 
						DISPLAY BY NAME pr_jobledger.activity_code 

						NEXT FIELD activity_code 

					WHEN infield (trans_source_text) 
						LET pr_jobledger.trans_source_text = show_res(glob_rec_kandoouser.cmpy_code) 

						SELECT desc_text 
						INTO pr_jmresource.desc_text 
						FROM jmresource 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND res_code = pr_jobledger.trans_source_text 

						DISPLAY BY NAME 
						pr_jobledger.trans_source_text 

						NEXT FIELD trans_source_text 
				END CASE 

			ON KEY (F7) 
				IF pr_prodledg.part_code IS NOT NULL THEN 
					CALL prsswind(glob_rec_kandoouser.cmpy_code, pr_prodledg.part_code) 
				ELSE 
					LET msgresp = kandoomsg("J",9596,"") 
					# ERROR "A product code must be entered FOR stock STATUS inq"
				END IF 

			AFTER FIELD var_code 
				IF pr_jobledger.var_code IS NULL 
				OR pr_jobledger.var_code = 0 THEN 
					LET pr_jobledger.var_code = 0 
					DISPLAY BY NAME pr_jobledger.var_code 

				ELSE 
					DECLARE jv_c CURSOR FOR 
					SELECT jobvars.* 
					INTO pr_jobvars.* 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_jobledger.job_code 
					AND var_code = pr_jobledger.var_code 
					OPEN jv_c 
					FETCH jv_c 
					IF status = notfound THEN 
						#ERROR " Variation NOT found - use window FOR help"
						LET msgresp = kandoomsg("J",9510," ") 
						NEXT FIELD var_code 
					ELSE 
						DISPLAY pr_jobvars.title_text 
						TO jobvars.title_text 

					END IF 
				END IF 

			AFTER FIELD activity_code 
				IF pr_jobledger.activity_code IS NULL THEN 
					#ERROR " Activity Code must be entered"
					LET msgresp = kandoomsg("J",9511," ") 
					NEXT FIELD activity_code 
				END IF 
				DECLARE act_c CURSOR FOR 
				SELECT * 
				INTO pr_activity.* 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_jobledger.job_code 
				AND var_code = pr_jobledger.var_code 
				AND activity_code = pr_jobledger.activity_code 
				OPEN act_c 
				FETCH act_c 

				CASE 
					WHEN status = notfound 
						#error
						#i"Activity NOT found FOR Job/Variation - Try Window"
						LET msgresp = kandoomsg("J",9512," ") 
						NEXT FIELD activity_code 

					WHEN pr_activity.finish_flag = "Y" 
						#error
						#"Activity IS Finished - No Costs may be Allocated"
						LET msgresp = kandoomsg("J",9513," ") 
						NEXT FIELD activity_code 

					OTHERWISE 
						SELECT response_text 
						INTO pr_bill_way_text 
						FROM kandooword 
						WHERE language_code = pr_rec_kandoouser.language_code 
						AND reference_text = "activity.bill_way_ind" 
						AND reference_code = pr_activity.bill_way_ind 
						IF status = notfound THEN 
							LET pr_bill_way_text = "Unknown" 
						END IF 
						DISPLAY pr_activity.title_text, 
						pr_activity.unit_code, 
						pr_bill_way_text 
						TO activity.title_text, 
						activity.unit_code, 
						bill_way_text 

				END CASE 

			BEFORE FIELD ware_code 
				LET pr_save_ware_code = pr_prodledg.ware_code 

			AFTER FIELD ware_code 
				SELECT * 
				INTO pr_warehouse.* 
				FROM warehouse 
				WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND warehouse.ware_code = pr_prodledg.ware_code 
				IF status = notfound THEN 
					#9091 "Warehouse NOT found - Try window"
					LET msgresp = kandoomsg("A",9091," ") 
					NEXT FIELD ware_code 
				END IF 

				IF pr_prodledg.ware_code <> pr_save_ware_code AND 
				(pr_prodledg.part_code <> " " AND 
				pr_prodledg.part_code IS NOT null) THEN 
					IF NOT get_stock_status() THEN 
						#9081 Product NOT stocked AT warehouse
						LET msgresp = kandoomsg("I",9081," ") 
						NEXT FIELD ware_code 
					END IF 
				END IF 

				DISPLAY pr_warehouse.desc_text, 
				pr_wgted_cost_amt, 
				pr_pricex_amt, 
				pr_jobledger.trans_amt, 
				pr_jobledger.charge_amt 
				TO warehouse.desc_text, 
				pr_wgted_cost_amt, 
				pricex_amt, 
				jobledger.trans_amt, 
				jobledger.charge_amt 


			BEFORE FIELD part_code 
				LET pr_save_part_code = pr_prodledg.part_code 

			AFTER FIELD part_code 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				END IF 
				SELECT product.* 
				INTO pr_product.* 
				FROM product 
				WHERE product.part_code = pr_prodledg.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					#9119 "Product NOT found - Try Window"
					LET msgresp = kandoomsg("A",9119," ") 
					NEXT FIELD part_code 
				END IF 
				IF pr_product.serial_flag = "Y" THEN 
					#ERROR "Serial Item - Not Permitted in Job Issue"
					LET msgresp = kandoomsg("J",9591," ") 
					NEXT FIELD part_code 
				END IF 
				IF pr_prodledg.part_code <> " " AND 
				pr_prodledg.part_code IS NOT NULL THEN 
					IF NOT get_stock_status() THEN 
						#9081 Product NOT stocked AT warehouse
						LET msgresp = kandoomsg("I",9081," ") 
						NEXT FIELD part_code 
					END IF 
				END IF 

				DISPLAY pr_product.desc_text, 
				pr_product.sell_uom_code, 
				pr_wgted_cost_amt, 
				pr_pricex_amt, 
				pr_jobledger.trans_amt, 
				pr_jobledger.charge_amt 
				TO product.desc_text, 
				product.sell_uom_code, 
				pr_wgted_cost_amt, 
				pricex_amt, 
				jobledger.trans_amt, 
				jobledger.charge_amt 


			ON KEY (F8) 
				IF pr_jmresource.res_code IS NOT NULL AND 
				pr_jmresource.res_code <> " " THEN 
					IF pr_jmresource.allocation_flag <> "1" THEN 
						LET msgresp = kandoomsg("J",9555,"") 
					ELSE 
						CALL adjust_allocflag(glob_rec_kandoouser.cmpy_code, 
						pr_jmresource.res_code, 
						pr_jmresource.allocation_ind) 
						RETURNING pr_jmresource.allocation_ind 
					END IF 
				END IF 


			BEFORE FIELD trans_source_text 
				LET tmp_res_code = pr_jobledger.trans_source_text 

			AFTER FIELD trans_source_text 
				IF pr_jobledger.trans_source_text IS NULL THEN 
					#ERROR " Resource Code must be entered "
					LET msgresp = kandoomsg("J",9514," ") 
					NEXT FIELD trans_source_text 
				END IF 
				IF pr_jobledger.trans_source_text <> tmp_res_code OR 
				pr_jmresource.desc_text IS NULL OR 
				pr_jmresource.acct_code IS NULL THEN 
					SELECT jmresource.* 
					INTO pr_jmresource.* 
					FROM jmresource 
					WHERE jmresource.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND res_code = pr_jobledger.trans_source_text 
					IF status = notfound THEN 
						#ERROR " No such Resource Code - Try Window"
						LET msgresp = kandoomsg("J",9515," ") 
						NEXT FIELD trans_source_text 
					END IF 
					# Resolve recovery TO revenue AND expense TO cos FROM activity
					CALL build_mask(glob_rec_kandoouser.cmpy_code, 
					pr_jmresource.acct_code, 
					pr_activity.acct_code) 
					RETURNING pr_jmresource.acct_code 
					CALL build_mask(glob_rec_kandoouser.cmpy_code, 
					pr_jmresource.exp_acct_code, 
					pr_activity.cos_acct_code) 
					RETURNING pr_jmresource.exp_acct_code 

				END IF 

				DISPLAY pr_jmresource.desc_text, 
				pr_jmresource.acct_code 
				TO jmresource.desc_text, 
				jmresource.acct_code 

				WHILE true 
					CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J91", 
					pr_jmresource.acct_code, 
					pr_jobledger.year_num, 
					pr_jobledger.period_num) 
					RETURNING pr_coa.* 
					IF pr_coa.acct_code IS NULL THEN 
						LET int_flag = true 
						LET quit_flag = true 
						EXIT WHILE 
					END IF 
					LET pr_jmresource.acct_code = pr_coa.acct_code 
					DISPLAY pr_jmresource.acct_code 
					TO jmresource.acct_code 

					IF pr_jmresource.acct_code NOT LIKE "%??%" THEN 
						EXIT WHILE 
					END IF 
				END WHILE 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD trans_source_text 
				END IF 

			AFTER FIELD trans_date 
				IF pr_jobledger.trans_date IS NULL THEN 
					#ERROR "Transaction date IS required"
					LET msgresp = kandoomsg("U",9547," ") 
					NEXT FIELD trans_date 
				END IF 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.trans_date) 
				RETURNING pr_jobledger.year_num, 
				pr_jobledger.period_num 
				DISPLAY BY NAME pr_jobledger.period_num, 
				pr_jobledger.year_num, 
				pr_jobledger.trans_date 


			AFTER FIELD period_num 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					LEDGER_TYPE_JM) 
				RETURNING 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					pr_return_status 
				
				IF pr_return_status THEN 
					NEXT FIELD year_num 
				END IF 

				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					TRAN_TYPE_INVOICE_IN) 
				RETURNING 
					pr_jobledger.year_num, 
					pr_jobledger.period_num, 
					pr_return_status 

				IF pr_return_status THEN 
					NEXT FIELD year_num 
				END IF 

			AFTER FIELD trans_qty 
				IF pr_jobledger.trans_qty IS NULL 
				OR pr_jobledger.trans_qty = 0 THEN 
					LET msgresp = kandoomsg("J",9651,0) 
					NEXT FIELD trans_qty 
				END IF 
				LET pr_jobledger.trans_amt = pr_jobledger.trans_qty 
				* pr_wgted_cost_amt 
				LET pr_jobledger.charge_amt = pr_jobledger.trans_qty 
				* pr_pricex_amt 

				DISPLAY BY NAME pr_jobledger.trans_amt, 
				pr_jobledger.charge_amt 

			BEFORE FIELD pr_wgted_cost_amt 
				# Only allow entry FOR -ve quantity (ie. a RETURN)
				IF pr_jobledger.trans_qty >= 0 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD trans_qty 
					ELSE 
						NEXT FIELD trans_amt 
					END IF 
				END IF 
			AFTER FIELD pr_wgted_cost_amt 
				IF pr_wgted_cost_amt IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# 9102 Value must be entered
					NEXT FIELD pr_wgted_cost_amt 
				END IF 
				IF pr_wgted_cost_amt <= 0 THEN 
					LET msgresp = kandoomsg("U",9927,"zero") 
					# 9927 Value must be greater than zero
					NEXT FIELD pr_wgted_cost_amt 
				END IF 
				LET pr_jobledger.trans_amt = pr_jobledger.trans_qty 
				* pr_wgted_cost_amt 
				DISPLAY BY NAME pr_jobledger.trans_amt 


			AFTER FIELD charge_amt 
				IF pr_jobledger.charge_amt IS NULL THEN 
					LET pr_jobledger.charge_amt = 0 
				END IF 
				DISPLAY BY NAME pr_jobledger.charge_amt 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF pr_jobledger.year_num IS NULL 
				OR pr_jobledger.period_num IS NULL THEN 
					#ERROR " Invalid Year & Period "
					LET msgresp = kandoomsg("U",9902," ") 
					NEXT FIELD year_num 
				END IF 

				IF pr_prodledg.part_code IS NULL OR 
				pr_prodledg.part_code = " " THEN 
					#ERROR " Product Code must be Entered"
					LET msgresp = kandoomsg("J",9592," ") 
					NEXT FIELD part_code 
				END IF 
				IF NOT get_stock_status() THEN 
					#9081 Product NOT stocked AT warehouse
					LET msgresp = kandoomsg("I",9081," ") 
					NEXT FIELD part_code 
				END IF 

				IF pr_jobledger.trans_qty IS NULL 
				OR pr_jobledger.trans_qty = 0 THEN 
					LET msgresp = kandoomsg("J",9651,0) 
					NEXT FIELD trans_qty 
				END IF 
				IF pr_jobledger.trans_source_text IS NULL THEN 
					#ERROR " Resource Code must be Entered"
					LET msgresp = kandoomsg("J",9514," ") 
					NEXT FIELD trans_source_text 
				END IF 
				IF pr_wgted_cost_amt IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# 9102 Value must be entered
					NEXT FIELD pr_wgted_cost_amt 
				END IF 
				IF pr_wgted_cost_amt <= 0 THEN 
					LET msgresp = kandoomsg("U",9927,"zero") 
					# 9927 Value must be greater than zero
					NEXT FIELD pr_wgted_cost_amt 
				END IF 
				LET pr_jobledger.trans_amt = pr_jobledger.trans_qty 
				* pr_wgted_cost_amt 
				DISPLAY BY NAME pr_jobledger.trans_amt 


				IF pr_jobledger.charge_amt IS NULL THEN 
					LET pr_jobledger.charge_amt = 0 
				END IF 
				DISPLAY BY NAME pr_jobledger.charge_amt 

				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J91", 
				pr_jmresource.acct_code, 
				pr_jobledger.year_num, 
				pr_jobledger.period_num) 
				RETURNING pr_coa.* 

				IF pr_coa.acct_code IS NULL THEN 



					NEXT FIELD trans_source_text 
				END IF 

				LET pr_jmresource.acct_code = pr_coa.acct_code 
				DISPLAY pr_jmresource.acct_code 
				TO jmresource.acct_code 



				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD trans_source_text 
				END IF 

				IF pr_jobledger.trans_qty IS NULL THEN 
					LET pr_jobledger.trans_qty = 0 
					LET pr_jobledger.trans_amt = 0 
					LET pr_jobledger.charge_amt = 0 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION getitem()
#
# 
###########################################################################


###########################################################################
# FUNCTION get_stock_status()
#
# 
###########################################################################
FUNCTION get_stock_status() 
	# Set up the price AND default cost FOR the product
	SELECT * 
	INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	AND ware_code = pr_prodledg.ware_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	CASE 
		WHEN pr_customer.inv_level_ind = "L" 
			LET pr_pricex_amt = pr_prodstatus.list_amt 
		WHEN pr_customer.inv_level_ind = "1" 
			LET pr_pricex_amt = pr_prodstatus.price1_amt 
		WHEN pr_customer.inv_level_ind = "2" 
			LET pr_pricex_amt = pr_prodstatus.price2_amt 
		WHEN pr_customer.inv_level_ind = "3" 
			LET pr_pricex_amt = pr_prodstatus.price3_amt 
		WHEN pr_customer.inv_level_ind = "4" 
			LET pr_pricex_amt = pr_prodstatus.price4_amt 
		WHEN pr_customer.inv_level_ind = "5" 
			LET pr_pricex_amt = pr_prodstatus.price5_amt 
		WHEN pr_customer.inv_level_ind = "6" 
			LET pr_pricex_amt = pr_prodstatus.price6_amt 
		WHEN pr_customer.inv_level_ind = "7" 
			LET pr_pricex_amt = pr_prodstatus.price7_amt 
		WHEN pr_customer.inv_level_ind = "8" 
			LET pr_pricex_amt = pr_prodstatus.price8_amt 
		WHEN pr_customer.inv_level_ind = "9" 
			LET pr_pricex_amt = pr_prodstatus.price9_amt 
		OTHERWISE 
			LET pr_pricex_amt = 0 
	END CASE 
	LET pr_wgted_cost_amt = pr_prodstatus.wgted_cost_amt 
	LET pr_jobledger.trans_amt = pr_jobledger.trans_qty * pr_wgted_cost_amt 
	LET pr_jobledger.charge_amt =	pr_jobledger.trans_qty * pr_pricex_amt 

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION get_stock_status()
#
# 
###########################################################################


###########################################################################
# FUNCTION write_issue() 
#
# 
###########################################################################
FUNCTION write_issue() 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET err_message = "J91 - SELECT JM parms " 
		DECLARE jm_upd CURSOR FOR 
		SELECT jmparms.* 
		INTO pr_jmparms.* 
		FROM jmparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		LET err_message = "J91 - JM Params Update" 
		OPEN jm_upd 
		FETCH jm_upd 
		LET pr_jobledger.trans_source_num = pr_jmparms.next_issue_num 
		UPDATE jmparms 
		SET next_issue_num = pr_jmparms.next_issue_num + 1 
		WHERE CURRENT OF jm_upd 
		CLOSE jm_upd 

		LET err_message = "J91 - Prodstatus UPDATE" 
		DECLARE c_prodstatus CURSOR FOR 

		SELECT prodstatus.* 
		INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE prodstatus.part_code = pr_prodledg.part_code 
		AND prodstatus.ware_code = pr_prodledg.ware_code 
		AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 

		OPEN c_prodstatus 
		FETCH c_prodstatus 
		IF status = notfound THEN 
			LET err_message = "J91 - prodstatus ", 
			pr_prodstatus.part_code clipped, " ", 
			pr_prodstatus.ware_code," Not Found" 
			GOTO recovery 
		END IF 

		IF pr_prodstatus.stocked_flag = "Y" THEN 
			LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty 
			- pr_jobledger.trans_qty 
		ELSE 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 
		LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
		LET pr_prodstatus.last_sale_date = pr_jobledger.trans_date 

		UPDATE prodstatus 
		SET seq_num = pr_prodstatus.seq_num, 
		onhand_qty = pr_prodstatus.onhand_qty, 
		last_sale_date = pr_prodstatus.last_sale_date 
		WHERE CURRENT OF c_prodstatus 
		CLOSE c_prodstatus 

		LET err_message = "J91 - Prodledg Row Insert" 
		LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodledg.part_code = pr_prodstatus.part_code 
		LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
		LET pr_prodledg.tran_date = pr_jobledger.trans_date 
		LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
		LET pr_prodledg.trantype_ind = "J" 
		LET pr_prodledg.year_num = pr_jobledger.year_num 
		LET pr_prodledg.period_num = pr_jobledger.period_num 
		LET pr_prodledg.source_text = "JM ISSUE" 
		LET pr_prodledg.source_num = pr_jobledger.trans_source_num 
		LET pr_prodledg.tran_qty = 0 - pr_jobledger.trans_qty + 0 

		# Cost can be entered FOR -ve issues (returns) so use entered value
		LET pr_prodledg.cost_amt = pr_wgted_cost_amt 
		LET pr_prodledg.sales_amt = pr_pricex_amt 

		IF pr_inparms.hist_flag = "Y" THEN 
			LET pr_prodledg.hist_flag = "N" 
		ELSE 
			LET pr_prodledg.hist_flag = "Y" 
		END IF 

		LET pr_prodledg.post_flag = "N" 
		LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
		LET pr_prodledg.desc_text = pr_jobledger.job_code, " ", 
		pr_jobledger.var_code USING "#####& ", 
		pr_jobledger.activity_code 
		LET pr_prodledg.acct_code = pr_jmresource.exp_acct_code 

		LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_prodledg.entry_date = today 

		INSERT INTO prodledg VALUES (pr_prodledg.*) 

		LET err_message = "J91 - Activity SELECT" 
		DECLARE c1_activity CURSOR FOR 
		SELECT * 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_jobledger.job_code 
		AND var_code = pr_jobledger.var_code 
		AND activity_code = pr_jobledger.activity_code 
		FOR UPDATE 

		OPEN c1_activity 
		FETCH c1_activity INTO pr_activity.* 

		LET pr_activity.seq_num = pr_activity.seq_num + 1 
		LET err_message = "J91 - Jobledger Insert" 
		LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_jobledger.trans_type_ind = "IS" 
		LET pr_jobledger.posted_flag = "N" 
		LET pr_jobledger.seq_num = pr_activity.seq_num 
		LET pr_jobledger.desc_text = pr_product.part_code, 
		pr_prodstatus.ware_code 
		IF pr_jobledger.trans_amt IS NULL THEN 
			LET pr_jobledger.trans_amt = 0 
		END IF 

		LET pr_jobledger.allocation_ind = pr_jmresource.allocation_ind 

		INSERT INTO jobledger VALUES (pr_jobledger.*) 
		# Update start date
		CALL set_start(pr_jobledger.job_code,pr_jobledger.trans_date) 

		LET err_message = "J91 - Activity Update" 
		IF pr_activity.unit_code = pr_product.sell_uom_code 
		OR pr_activity.unit_code IS NULL THEN 
			# Update activity start date
			IF pr_activity.act_start_date IS NULL 
			OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
				UPDATE activity 
				SET act_start_date = pr_jobledger.trans_date, 
				act_cost_amt = act_cost_amt 
				+ pr_jobledger.trans_amt, 
				post_revenue_amt = post_revenue_amt 
				+ pr_jobledger.charge_amt, 
				act_cost_qty = act_cost_qty + pr_jobledger.trans_qty, 
				seq_num = pr_activity.seq_num 
				WHERE CURRENT OF c1_activity 
			ELSE 
				UPDATE activity 
				SET act_cost_amt = act_cost_amt 
				+ pr_jobledger.trans_amt, 
				post_revenue_amt = post_revenue_amt 
				+ pr_jobledger.charge_amt, 
				act_cost_qty = act_cost_qty + pr_jobledger.trans_qty, 
				seq_num = pr_activity.seq_num 
				WHERE CURRENT OF c1_activity 
			END IF 
		ELSE 
			IF pr_activity.act_start_date IS NULL 
			OR pr_activity.act_start_date > pr_jobledger.trans_date THEN 
				UPDATE activity 
				SET act_start_date = pr_jobledger.trans_date, 
				act_cost_amt = act_cost_amt 
				+ pr_jobledger.trans_amt, 
				post_revenue_amt = post_revenue_amt 
				+ pr_jobledger.charge_amt, 
				act_cost_qty = act_cost_qty + pr_jobledger.trans_qty, 
				seq_num = pr_activity.seq_num 
				WHERE CURRENT OF c1_activity 
			ELSE 
				UPDATE activity 
				SET act_cost_amt = act_cost_amt 
				+ pr_jobledger.trans_amt, 
				post_revenue_amt = post_revenue_amt 
				+ pr_jobledger.charge_amt, 
				act_cost_qty = act_cost_qty + pr_jobledger.trans_qty, 
				seq_num = pr_activity.seq_num 
				WHERE CURRENT OF c1_activity 
			END IF 
		END IF 

		CLOSE c1_activity 
	COMMIT WORK 
	WHENEVER ERROR stop 
	
	LET msgresp = kandoomsg("J",8902,0) 
	IF msgresp = "Y" THEN 
		CALL print_issue() 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION write_issue() 
#
# 
###########################################################################


###########################################################################
# FUNCTION print_issue() 
#
# 
###########################################################################
FUNCTION print_issue() 
	DEFINE rpt_wid SMALLINT 
	DEFINE pr_output CHAR(20) 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"J91_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT J91_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	OUTPUT TO REPORT 
	J91_rpt_list(pr_job.job_code, 
	pr_job.title_text, 
	pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_jobledger.var_code, 
	pr_jobledger.activity_code, 
	pr_jobledger.trans_qty, 
	pr_prodstatus.ware_code, 
	pr_prodstatus.part_code, 
	pr_prodstatus.bin1_text, 
	pr_prodstatus.onhand_qty) 

		#---------------------------------------------------------
		OUTPUT TO REPORT J91_rpt_list(l_rpt_idx,
		pr_job.job_code, 
		pr_job.title_text, 
		pr_customer.cust_code, 
		pr_customer.name_text, 
		pr_jobledger.var_code, 
		pr_jobledger.activity_code, 
		pr_jobledger.trans_qty, 
		pr_prodstatus.ware_code, 
		pr_prodstatus.part_code, 
		pr_prodstatus.bin1_text, 
		pr_prodstatus.onhand_qty) 
		#---------------------------------------------------------	

	#------------------------------------------------------------
	FINISH REPORT J91_rpt_list
	CALL rpt_finish("J91_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 
###########################################################################
# END FUNCTION print_issue() 
###########################################################################


###########################################################################
#REPORT J91_rpt_list(job_code, 
#	title_text, 
#	cust_code, 
#	name_text, 
#	var_code, 
#	activity_code, 
#	trans_qty, 
#	ware_code, 
#	part_code, 
#	bin1_text, 
#	onhand_qty) 
# 
###########################################################################
REPORT J91_rpt_list(p_rpt_idx,
	job_code, 
	title_text, 
	cust_code, 
	name_text, 
	var_code, 
	activity_code, 
	trans_qty, 
	ware_code, 
	part_code, 
	bin1_text, 
	onhand_qty) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE job_code LIKE job.job_code 
	DEFINE title_text LIKE job.title_text 
	DEFINE cust_code LIKE customer.cust_code 
	DEFINE name_text LIKE customer.name_text 
	DEFINE var_code LIKE jobledger.var_code 
	DEFINE activity_code LIKE jobledger.activity_code 
	DEFINE trans_qty LIKE jobledger.trans_qty 
	DEFINE ware_code LIKE prodstatus.ware_code 
	DEFINE part_code LIKE prodstatus.part_code 
	DEFINE bin1_text LIKE prodstatus.bin1_text 
	DEFINE onhand_qty LIKE prodstatus.onhand_qty 
	DEFINE line1 CHAR(80) 
	DEFINE pr_picked_qty LIKE orderdetl.picked_qty 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			 
		ON EVERY ROW 
			SELECT sum(picked_qty) 
			INTO pr_picked_qty 
			FROM orderdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND orderdetl.part_code = part_code 
			AND orderdetl.ware_code = ware_code 
			IF pr_picked_qty IS NULL THEN 
				LET pr_picked_qty = 0 
			END IF 
			PRINT COLUMN 2, "Job:", 
			COLUMN 13, job_code, 
			COLUMN 23, title_text 
			PRINT COLUMN 2, "Customer:", 
			COLUMN 13, cust_code, 
			COLUMN 23, name_text 
			PRINT COLUMN 2, "Variation:", 
			COLUMN 13, var_code USING "####&", 
			COLUMN 22, "Activity:", 
			COLUMN 33, activity_code, 
			COLUMN 44, "Warehouse:", 
			COLUMN 55, ware_code 
			SKIP 1 line 
			PRINT COLUMN 2, "Product:", 
			COLUMN 11, part_code, 
			COLUMN 33, "Quantity:", 
			COLUMN 43, trans_qty USING "######&" 
			PRINT COLUMN 2, "Bin Location:", 
			COLUMN 16, bin1_text, 
			COLUMN 33, "Balance:", 
			COLUMN 43, onhand_qty - pr_picked_qty USING "######&"
			 
		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT
###########################################################################
# END REPORT J91_rpt_list(job_code, 
#	title_text, 
#	cust_code, 
#	name_text, 
#	var_code, 
#	activity_code, 
#	trans_qty, 
#	ware_code, 
#	part_code, 
#	bin1_text, 
#	onhand_qty) 
# 
###########################################################################