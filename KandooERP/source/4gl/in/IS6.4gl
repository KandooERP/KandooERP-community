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

	Source code beautified by beautify.pl on 2020-01-03 09:12:40	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS6.4gl Detailed Stock Re-Valuation
#                  This program works through the selected products
#                  retreiving all cost ledgers (tran_qty != 0) AND
#                  marks up/down (OR restore original) cost.

GLOBALS 
	DEFINE 
	rpt_note1, 
	rpt_note2 LIKE rmsreps.report_text, 
	pr_output1, 
	pr_output2 CHAR(25), 
	where_text CHAR(400), 
	pr_tran_rec RECORD 
		book_tax_ind CHAR(1), 
		start_date DATE, 
		end_date DATE, 
		revalue_ind CHAR(1), 
		revalue_per FLOAT, 
		tran_date LIKE prodledg.tran_date, 
		desc_text LIKE prodledg.desc_text, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num 
	END RECORD, 
	rpt_wid SMALLINT 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IS6") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET rpt_wid = 132 
	CREATE temp TABLE t_acctsumm(acct_code CHAR(18), 
	cost1_amt DECIMAL(16,4), 
	cost2_amt DECIMAL(16,4), 
	cost3_amt DECIMAL(16,4)) with no LOG 
	OPEN WINDOW i207 with FORM "I207" 
	 CALL windecoration_i("I207") -- albo kd-758 
	MENU " Stock Valuation" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IS6","menu-Stock Valuation-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			IF is6_query() THEN 
				CALL process_costledg(false) 
				NEXT option "Print Manager" 
			END IF 
		COMMAND "Update" " SELECT Criteria AND UPDATE database" 
			IF is6_query() THEN 
				IF get_tran_date() THEN 
					CALL process_costledg(true) 
					NEXT option "Print Manager" 
				END IF 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY("E",interrupt)"Exit" " Exit TO Menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW i207 
END MAIN 


FUNCTION is6_query() 
	DEFINE 
	query_text CHAR(500) 

	CLEAR FORM 
	LET pr_tran_rec.book_tax_ind = "B" 
	LET pr_tran_rec.start_date = mdy(1,1,year(today)) 
	LET pr_tran_rec.end_date = mdy(12,31,year(today)) 
	LET pr_tran_rec.revalue_ind = "U" 
	LET pr_tran_rec.revalue_per = 0 
	LET msgresp=kandoomsg("I",1314,"") 
	#1001 Enter Revaluation Info
	INPUT BY NAME pr_tran_rec.book_tax_ind, 
	pr_tran_rec.start_date, 
	pr_tran_rec.end_date, 
	pr_tran_rec.revalue_ind, 
	pr_tran_rec.revalue_per WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS6","input-pr_tran_rec-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD revalue_per 
			IF pr_tran_rec.revalue_ind = "O" THEN 
				EXIT INPUT 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	IF pr_tran_rec.start_date IS NULL THEN 
		LET pr_tran_rec.start_date = "01/01/0001" 
	END IF 
	IF pr_tran_rec.end_date IS NULL THEN 
		LET pr_tran_rec.end_date = "30/12/9999" 
	END IF 
	LET msgresp=kandoomsg("I",1001,"") 
	#1001 Enter Criteria FOR Selection - Press ESC TO Begin Report"
	CONSTRUCT BY NAME where_text ON product.cat_code, 
	product.class_code, 
	prodstatus.part_code, 
	prodstatus.ware_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IS6","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp=kandoomsg("I",1002,"") 
		#I1002 Searching database - please wait
		LET query_text = "SELECT product.*,", 
		"prodstatus.* ", 
		"FROM product,", 
		"prodstatus ", 
		"WHERE product.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND prodstatus.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.part_code=prodstatus.part_code ", 
		"AND ",where_text clipped," ", 
		"ORDER BY product.cat_code,", 
		"product.part_code,", 
		"prodstatus.ware_code" 
		PREPARE s_prodstatus FROM query_text 
		DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
		LET query_text="SELECT rowid,* FROM costledg ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND part_code= ? ", 
		"AND ware_code= ? ", 
		"AND costledg.tran_date>='",pr_tran_rec.start_date,"' ", 
		"AND costledg.tran_date<='",pr_tran_rec.end_date,"' ", 
		"AND costledg.onhand_qty != 0 " 
		PREPARE s_costledg FROM query_text 
		DECLARE c_costledg CURSOR FOR s_costledg 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION process_costledg(pr_update_ind) 
	DEFINE 
	pr_update_ind SMALLINT, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_old_costledg RECORD LIKE costledg.*, 
	pr_new_costledg RECORD LIKE costledg.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	err_message CHAR(80), 
	pr_tot_ext_wroff_amt LIKE costledg.curr_wo_amt, 
	pr_wgted_cost_amt LIKE prodstatus.wgted_cost_amt, 
	pr_mask_code LIKE warehouse.acct_mask_code, 
	err_cnt SMALLINT, 
	pr_rowid INTEGER 

	IF pr_tran_rec.book_tax_ind = "B" THEN 
		LET rpt_note1 = "IN Summary Stock (Book) Revaluation" 
		LET rpt_note2 = "IN Detailed Stock (Book) Revaluation" 
	ELSE 
		LET rpt_note1 = "IN Summary Stock (Tax) Revaluation" 
		LET rpt_note2 = "IN Detailed Stock (Tax) Revaluation" 
	END IF 
	LET pr_output1 = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,rpt_note1) 
	LET pr_output2 = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,rpt_note2) 
	START REPORT is6_list1 TO pr_output1 
	START REPORT is6_list2 TO pr_output2 
	--   OPEN WINDOW w1_IS6 AT 10,10 with 2 rows,50 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	LET msgresp=kandoomsg("I",1024,pr_product.part_code) 
	#I1024 Reporting Product
	FOREACH c_prodstatus INTO pr_product.*, 
		pr_prodstatus.* 
		DISPLAY "" at 1,30 
		DISPLAY pr_product.part_code at 1,30 

		##
		## Each prodstatus IS a separate transaction.
		##
		GOTO bypass 
		LABEL recovery: 
		###
		### As the REPORT OUTPUT IS generated FROM the same prgram loop
		### as the database UPDATE,  any lock retry outputs multiple entries
		### TO the reports FOR the one costledg entry.
		### (future work around IS TO use a temporary table)
		###
		ROLLBACK WORK 
		LET err_cnt = err_cnt + 1 
		LET err_message = "IS6 - Error occurred during UPDATE", 
		" - Product:",pr_product.part_code clipped, 
		" - Warehouse ",pr_prodstatus.ware_code clipped 
		CALL errorlog(err_message) 
		CONTINUE FOREACH 
		LABEL bypass: 
		IF pr_update_ind THEN 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "IS6 - Updating product cost ledger" 
			END IF 
			LET pr_tot_ext_wroff_amt = 0 
			OPEN c_costledg USING pr_prodstatus.part_code, 
			pr_prodstatus.ware_code 
			FOREACH c_costledg INTO pr_rowid, 
				pr_old_costledg.* 
				LET pr_new_costledg.* = pr_old_costledg.* 
				IF pr_tran_rec.book_tax_ind = "B" THEN 
					CASE pr_tran_rec.revalue_ind 
						WHEN "U" ### mark value up 
							LET pr_new_costledg.curr_cost_amt=pr_old_costledg.curr_cost_amt 
							+ ((pr_tran_rec.revalue_per*pr_old_costledg.curr_cost_amt)/100) 
						WHEN "D" ### mark value down 
							LET pr_new_costledg.curr_cost_amt=pr_old_costledg.curr_cost_amt 
							- ((pr_tran_rec.revalue_per*pr_old_costledg.curr_cost_amt)/100) 
						WHEN "O" ### restore value TO original 
							LET pr_new_costledg.curr_cost_amt=pr_old_costledg.act_cost_amt 
					END CASE 
					LET pr_new_costledg.curr_wo_amt = pr_old_costledg.curr_cost_amt 
					- pr_new_costledg.curr_cost_amt 
					LET pr_new_costledg.prev_wo_amt = pr_old_costledg.prev_wo_amt 
					+ pr_old_costledg.curr_wo_amt 
					LET pr_new_costledg.curr_tot_wo_amt = pr_new_costledg.curr_wo_amt 
					* pr_new_costledg.onhand_qty 
					LET pr_new_costledg.prev_tot_wo_amt=pr_old_costledg.prev_tot_wo_amt 
					+pr_old_costledg.curr_tot_wo_amt 
					##
					## Only sum the write off FOR Book revaluations as it IS used
					## TO initiate a product ledger entry
					##
					LET pr_tot_ext_wroff_amt = pr_tot_ext_wroff_amt 
					+ pr_new_costledg.curr_tot_wo_amt 
					IF pr_update_ind AND pr_tot_ext_wroff_amt != 0 THEN 
						UPDATE costledg 
						SET curr_cost_amt = pr_new_costledg.curr_cost_amt, 
						curr_wo_amt = pr_new_costledg.curr_wo_amt, 
						prev_wo_amt = pr_new_costledg.prev_wo_amt, 
						curr_tot_wo_amt = pr_new_costledg.curr_tot_wo_amt, 
						prev_tot_wo_amt = pr_new_costledg.prev_tot_wo_amt 
						WHERE rowid = pr_rowid 
					END IF 
				ELSE 
					CASE pr_tran_rec.revalue_ind 
						WHEN "U" ### mark value up 
							LET pr_new_costledg.tax_cost_amt=pr_old_costledg.tax_cost_amt 
							+ ((pr_tran_rec.revalue_per * pr_old_costledg.tax_cost_amt)/100) 
						WHEN "D" ### mark value down 
							LET pr_new_costledg.tax_cost_amt=pr_old_costledg.tax_cost_amt 
							- ((pr_tran_rec.revalue_per * pr_old_costledg.tax_cost_amt)/100) 
						WHEN "O" ### restore value TO original 
							LET pr_new_costledg.curr_cost_amt=pr_old_costledg.act_cost_amt 
					END CASE 
					LET pr_new_costledg.tax_wo_amt = pr_old_costledg.tax_cost_amt 
					- pr_new_costledg.tax_cost_amt 
					LET pr_new_costledg.prev_tax_wo_amt=pr_old_costledg.prev_tax_wo_amt 
					+pr_old_costledg.tax_wo_amt 
					LET pr_new_costledg.tax_tot_wo_amt = pr_new_costledg.tax_wo_amt 
					* pr_new_costledg.onhand_qty 
					LET pr_new_costledg.prv_tot_tax_wo_amt = 
					pr_old_costledg.prv_tot_tax_wo_amt+pr_old_costledg.tax_tot_wo_amt 
					LET pr_tot_ext_wroff_amt = pr_tot_ext_wroff_amt 
					+ pr_new_costledg.tax_tot_wo_amt 
					IF pr_update_ind AND pr_tot_ext_wroff_amt != 0 THEN 
						UPDATE costledg 
						SET tax_cost_amt = pr_new_costledg.tax_cost_amt, 
						tax_wo_amt = pr_new_costledg.tax_wo_amt, 
						prev_tax_wo_amt = pr_new_costledg.prev_tax_wo_amt, 
						tax_tot_wo_amt = pr_new_costledg.tax_tot_wo_amt, 
						prv_tot_tax_wo_amt = pr_new_costledg.prv_tot_tax_wo_amt 
						WHERE rowid = pr_rowid 
					END IF 
				END IF 
				IF pr_tot_ext_wroff_amt != 0 THEN 
					OUTPUT TO REPORT is6_list1(pr_product.*,pr_new_costledg.*) 
					OUTPUT TO REPORT is6_list2(pr_product.*,pr_new_costledg.*, 
					pr_prodstatus.onhand_qty) 
				END IF 
			END FOREACH 
			IF pr_update_ind THEN 
				IF pr_tot_ext_wroff_amt != 0 THEN 
					##
					## Only INSERT a prodledg IF the stock value has actually changed
					##
					LET err_message = "IS6 - Updating product STATUS" 
					IF pr_prodstatus.onhand_qty = 0 THEN 
						LET pr_wgted_cost_amt = 0 
					ELSE 
						LET pr_wgted_cost_amt = 
						(( pr_prodstatus.wgted_cost_amt * pr_prodstatus.onhand_qty) 
						- pr_tot_ext_wroff_amt) / pr_prodstatus.onhand_qty 
					END IF 
					UPDATE prodstatus 
					SET wgted_cost_amt = pr_wgted_cost_amt, 
					seq_num = pr_prodstatus.seq_num + 1 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_prodstatus.ware_code 
					AND part_code = pr_prodstatus.part_code 
					LET err_message = "IS6 - Creating product ledger entry" 
					INITIALIZE pr_prodledg.* TO NULL 
					LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_prodledg.part_code = pr_prodstatus.part_code 
					LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
					LET pr_prodledg.tran_date = pr_tran_rec.tran_date 
					LET pr_prodledg.seq_num = pr_prodstatus.seq_num+1 
					LET pr_prodledg.trantype_ind = "U" 
					LET pr_prodledg.year_num = pr_tran_rec.year_num 
					LET pr_prodledg.period_num = pr_tran_rec.period_num 
					LET pr_prodledg.source_text = "Revalue" 
					LET pr_prodledg.source_num = 0 
					LET pr_prodledg.tran_qty = pr_prodstatus.onhand_qty 
					IF pr_prodledg.tran_qty = 0 THEN 
						LET pr_prodledg.cost_amt = 0 
					ELSE 
						LET pr_prodledg.cost_amt = 0 
						- (pr_tot_ext_wroff_amt / pr_prodledg.tran_qty) 
					END IF 
					LET pr_prodledg.sales_amt = 0 
					LET pr_prodledg.hist_flag = "N" 
					LET pr_prodledg.post_flag = "Y" 
					LET pr_prodledg.desc_text = pr_tran_rec.desc_text 
					SELECT adj_acct_code INTO pr_prodledg.acct_code 
					FROM category 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cat_code = pr_product.cat_code 
					SELECT acct_mask_code INTO pr_mask_code 
					FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_prodledg.ware_code 
					LET pr_prodledg.acct_code = build_mask(pr_prodledg.cmpy_code, 
					pr_mask_code, 
					pr_prodledg.acct_code) 
					LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
					LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_prodledg.entry_date = today 
					INSERT INTO prodledg VALUES (pr_prodledg.*) 
				END IF 
				WHENEVER ERROR stop 
			COMMIT WORK 
		END IF 
	END FOREACH 
	--   CLOSE WINDOW w1_IS6  -- albo  KD-758
	FINISH REPORT is6_list1 
	FINISH REPORT is6_list2 
	IF err_cnt = 0 THEN 
		LET msgresp=kandoomsg("I",7059,err_cnt) 
		#I7060 Process complete
	ELSE 
		LET msgresp=kandoomsg("I",7060,err_cnt) 
		#I7060 Errors occurred refer get_settings_logFile()
	END IF 
END FUNCTION 


REPORT is6_list1(pr_product,pr_new_costledg) 
	##
	## Summary revaluation REPORT
	##
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_new_costledg RECORD LIKE costledg.*, 
	pr_acctsumm RECORD 
		acct_code LIKE category.stock_acct_code, 
		cost1_amt LIKE costledg.curr_cost_amt, 
		cost2_amt LIKE costledg.curr_cost_amt, 
		cost3_amt LIKE costledg.curr_cost_amt 
	END RECORD, 
	pr_category RECORD LIKE category.* 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_product.cat_code 
	FORMAT 
		PAGE HEADER 
			IF pageno <= 1 THEN 
				DELETE FROM t_acctsumm 
			END IF 
			LET rpt_wid = 132 
			PRINT COLUMN 43, rpt_note1 clipped," - (Menu IS6)", 
			COLUMN 122, "Page :", pageno USING "####" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"--------------------------------------------------", 
			"-------------------------------" 
			PRINT COLUMN 04, "Category", 
			COLUMN 68, "Qty", 
			COLUMN 75, "Curr Value", 
			COLUMN 90, "Curr W/off", 
			COLUMN 105, "Prev W/off" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"--------------------------------------------------", 
			"-------------------------------" 
		AFTER GROUP OF pr_product.cat_code 
			SELECT * INTO pr_category.* FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
			LET pr_acctsumm.acct_code = pr_category.stock_acct_code 
			IF pr_tran_rec.book_tax_ind = "B" THEN 
				LET pr_acctsumm.cost1_amt=group sum(pr_new_costledg.curr_cost_amt 
				*pr_new_costledg.onhand_qty) 
				LET pr_acctsumm.cost2_amt=group sum(pr_new_costledg.curr_tot_wo_amt) 
				LET pr_acctsumm.cost3_amt=group sum(pr_new_costledg.prev_tot_wo_amt) 
			ELSE 
				LET pr_acctsumm.cost1_amt=group sum(pr_new_costledg.tax_cost_amt 
				*pr_new_costledg.onhand_qty) 
				LET pr_acctsumm.cost2_amt=group sum(pr_new_costledg.tax_tot_wo_amt) 
				LET pr_acctsumm.cost3_amt=group sum(pr_new_costledg.prv_tot_tax_wo_amt) 
			END IF 
			PRINT COLUMN 02, pr_category.cat_code, 
			COLUMN 17, pr_category.desc_text, 
			COLUMN 63, GROUP sum(pr_new_costledg.onhand_qty) USING "-------&", 
			COLUMN 72, pr_acctsumm.cost1_amt USING "--,---,--&.&&", 
			COLUMN 87, pr_acctsumm.cost2_amt USING "--,---,--&.&&", 
			COLUMN 102,pr_acctsumm.cost3_amt USING "--,---,--&.&&" 
			INSERT INTO t_acctsumm VALUES (pr_acctsumm.*) 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 36, "Account Summary:"; 
			DECLARE c_acctsumm CURSOR FOR 
			SELECT acct_code,sum(cost1_amt),sum(cost2_amt),sum(cost3_amt) 
			FROM t_acctsumm 
			GROUP BY 1 ORDER BY 1 
			FOREACH c_acctsumm INTO pr_acctsumm.* 
				PRINT COLUMN 53, pr_acctsumm.acct_code, 
				COLUMN 72, pr_acctsumm.cost1_amt USING "--,---,--&.&&", 
				COLUMN 87, pr_acctsumm.cost2_amt USING "--,---,--&.&&", 
				COLUMN 102,pr_acctsumm.cost3_amt USING "--,---,--&.&&" 
			END FOREACH 
			SKIP 1 line 
			NEED 5 LINES 
			PRINT COLUMN 36, "Report Total:", 
			COLUMN 63, sum(pr_new_costledg.onhand_qty) USING "-------&"; 
			IF pr_tran_rec.book_tax_ind = "B" THEN 
				PRINT COLUMN 72,sum(pr_new_costledg.curr_cost_amt 
				*pr_new_costledg.onhand_qty) 
				USING "--,---,--&.&&", 
				COLUMN 87,sum(pr_new_costledg.curr_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 102,sum(pr_new_costledg.prev_tot_wo_amt) 
				USING "--,---,--&.&&" 
			ELSE 
				PRINT COLUMN 72,sum(pr_new_costledg.tax_cost_amt 
				*pr_new_costledg.onhand_qty) 
				USING "--,---,--&.&&", 
				COLUMN 87,sum(pr_new_costledg.tax_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 102,sum(pr_new_costledg.prv_tot_tax_wo_amt) 
				USING "--,---,--&.&&" 
			END IF 
			SKIP 4 LINES 
			PRINT COLUMN 50, "***** END OF REPORT IS6 *****" 
END REPORT 


REPORT is6_list2(pr_product,pr_new_costledg,pr_onhand_qty) 
	##
	## detailed revaluation REPORT
	##
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_new_costledg RECORD LIKE costledg.*, 
	pr_category RECORD LIKE category.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_onhand_qty LIKE prodstatus.onhand_qty, 
	print_cnt SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_product.cat_code, 
	pr_product.part_code, 
	pr_new_costledg.ware_code 
	FORMAT 
		PAGE HEADER 
			LET rpt_wid = 132 
			PRINT COLUMN 43, rpt_note2 clipped," - (Menu IS6)", 
			COLUMN 122, "Page :", pageno USING "####" 
			PRINT COLUMN 01,"--------------------------------------------------", 
			"--------------------------------------------------", 
			"-------------------------------" 
			PRINT COLUMN 04, "Product", 
			COLUMN 34, "Warehouse", 
			COLUMN 44, "Source Type", 
			COLUMN 57, "Date", 
			COLUMN 68, "Qty", 
			COLUMN 76, "Cost Price", 
			COLUMN 91, "Curr Value", 
			COLUMN 106, "Curr W/off", 
			COLUMN 121, "Prev W/off" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"--------------------------------------------------", 
			"-------------------------------" 
		BEFORE GROUP OF pr_product.cat_code 
			LET print_cnt = 0 
			SELECT * INTO pr_category.* FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
			PRINT COLUMN 01,"Category: ", 
			COLUMN 12,pr_category.cat_code, 
			COLUMN 17,pr_category.desc_text 
		BEFORE GROUP OF pr_product.part_code 
			PRINT COLUMN 04, pr_product.part_code, 
			COLUMN 20, pr_product.desc_text, 
			COLUMN 51, pr_product.desc2_text 
		ON EVERY ROW 
			LET print_cnt = print_cnt + 1 
			SELECT * INTO pr_prodledg.* FROM prodledg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_new_costledg.part_code 
			AND ware_code = pr_new_costledg.ware_code 
			AND tran_date = pr_new_costledg.tran_date 
			AND seq_num = pr_new_costledg.seq_num 
			PRINT COLUMN 38, pr_new_costledg.ware_code, 
			COLUMN 43, pr_prodledg.source_num USING "######&", 
			COLUMN 53, pr_new_costledg.trantype_ind, 
			COLUMN 56, pr_new_costledg.tran_date USING "mmm yy", 
			COLUMN 63, pr_new_costledg.onhand_qty USING "-------&", 
			COLUMN 73, pr_new_costledg.act_cost_amt USING "--,---,--&.&&"; 
			IF pr_tran_rec.book_tax_ind = "B" THEN 
				PRINT COLUMN 88,(pr_new_costledg.curr_cost_amt 
				*pr_new_costledg.onhand_qty) USING "--,---,--&.&&", 
				COLUMN 103,pr_new_costledg.curr_tot_wo_amt USING "--,---,--&.&&", 
				COLUMN 118,pr_new_costledg.prev_tot_wo_amt USING "--,---,--&.&&" 
			ELSE 
				PRINT COLUMN 88,(pr_new_costledg.tax_cost_amt 
				*pr_new_costledg.onhand_qty) USING "--,---,--&.&&", 
				COLUMN 103,pr_new_costledg.tax_tot_wo_amt USING "--,---,--&.&&", 
				COLUMN 118,pr_new_costledg.prv_tot_tax_wo_amt 
				USING "--,---,--&.&&" 
			END IF 
		AFTER GROUP OF pr_new_costledg.ware_code 
			###
			### This IS a warning only.  Obviously IF the date selection criteria
			### has omitted some current costledg entries (OR PU receipts exist
			### which have NOT been posted TO the GL) THEN it IS normal FOR
			### the costledg AND current prodstatus onhand qty's TO be different.
			###
			IF print_cnt > 0 THEN 
				IF pr_onhand_qty != GROUP sum(pr_new_costledg.onhand_qty) THEN 
					PRINT COLUMN 38, "** Current Onhand Qty.**", 
					COLUMN 63, pr_new_costledg.onhand_qty USING "-------&" 
				END IF 
			END IF 
		AFTER GROUP OF pr_product.part_code 
			IF print_cnt > 1 THEN 
				PRINT COLUMN 43, "Product Total:", 
				COLUMN 63, GROUP sum(pr_new_costledg.onhand_qty) 
				USING "-------&", 
				COLUMN 73,group sum(pr_new_costledg.act_cost_amt) 
				USING "--,---,--&.&&"; 
				IF pr_tran_rec.book_tax_ind = "B" THEN 
					PRINT COLUMN 88,group sum(pr_new_costledg.curr_cost_amt 
					*pr_new_costledg.onhand_qty) 
					USING "--,---,--&.&&", 
					COLUMN 103,group sum(pr_new_costledg.curr_tot_wo_amt) 
					USING "--,---,--&.&&", 
					COLUMN 118,group sum(pr_new_costledg.prev_tot_wo_amt) 
					USING "--,---,--&.&&" 
				ELSE 
					PRINT COLUMN 88,group sum(pr_new_costledg.tax_cost_amt 
					*pr_new_costledg.onhand_qty) 
					USING "--,---,--&.&&", 
					COLUMN 103,group sum(pr_new_costledg.tax_tot_wo_amt) 
					USING "--,---,--&.&&", 
					COLUMN 118,group sum(pr_new_costledg.prv_tot_tax_wo_amt) 
					USING "--,---,--&.&&" 
				END IF 
			END IF 
			SKIP 1 line 
			LET print_cnt = 0 
		AFTER GROUP OF pr_product.cat_code 
			PRINT COLUMN 43, "Category Total:"; 
			IF pr_tran_rec.book_tax_ind = "B" THEN 
				PRINT COLUMN 88,group sum(pr_new_costledg.curr_cost_amt 
				*pr_new_costledg.onhand_qty) 
				USING "--,---,--&.&&", 
				COLUMN 103,group sum(pr_new_costledg.curr_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 118,group sum(pr_new_costledg.prev_tot_wo_amt) 
				USING "--,---,--&.&&" 
			ELSE 
				PRINT COLUMN 88,group sum(pr_new_costledg.tax_cost_amt 
				*pr_new_costledg.onhand_qty) 
				USING "--,---,--&.&&", 
				COLUMN 103,group sum(pr_new_costledg.tax_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 118,group sum(pr_new_costledg.prv_tot_tax_wo_amt) 
				USING "--,---,--&.&&" 
			END IF 
		ON LAST ROW 
			NEED 10 LINES 
			SKIP 1 line 
			PRINT COLUMN 43, "Report Total:"; 
			IF pr_tran_rec.book_tax_ind = "B" THEN 
				PRINT COLUMN 88,sum(pr_new_costledg.curr_cost_amt 
				*pr_new_costledg.onhand_qty) USING "--,---,--&.&&", 
				COLUMN 103,sum(pr_new_costledg.curr_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 118,sum(pr_new_costledg.prev_tot_wo_amt) 
				USING "--,---,--&.&&" 
			ELSE 
				PRINT COLUMN 88,sum(pr_new_costledg.tax_cost_amt 
				*pr_new_costledg.onhand_qty) USING "--,---,--&.&&", 
				COLUMN 103,sum(pr_new_costledg.tax_tot_wo_amt) 
				USING "--,---,--&.&&", 
				COLUMN 118,sum(pr_new_costledg.prv_tot_tax_wo_amt) 
				USING "--,---,--&.&&" 
			END IF 
			SKIP 4 LINES 
			PRINT COLUMN 10, "Report used the following selection criteria" 
			PRINT COLUMN 10, "WHERE:-",where_text clipped 
			SKIP 1 line 
			PRINT COLUMN 50, "***** END OF REPORT IS6 *****" 
END REPORT 


FUNCTION get_tran_date() 
	OPEN WINDOW i645 with FORM "I645" -- albo kd-758 
	 CALL windecoration_i("I645") -- albo kd-758 
	LET msgresp=kandoomsg("I",1044,"") 
	#1044 Enter posting date details
	LET pr_tran_rec.tran_date = today 
	LET pr_tran_rec.desc_text = "Auto Stock Re-Valuation" 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
	RETURNING pr_tran_rec.year_num, 
	pr_tran_rec.period_num 
	INPUT BY NAME pr_tran_rec.tran_date, 
	pr_tran_rec.desc_text, 
	pr_tran_rec.year_num, 
	pr_tran_rec.period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS6","input-pr_tran_rec-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD tran_date 
			IF pr_tran_rec.tran_date IS NULL THEN 
				LET pr_tran_rec.tran_date = today 
				NEXT FIELD tran_date 
			ELSE 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num, 
				pr_tran_rec.year_num 

			END IF 
		AFTER FIELD year_num 
			IF pr_tran_rec.year_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num 

				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF pr_tran_rec.period_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.start_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num 

				NEXT FIELD year_num 
			END IF 
		AFTER INPUT 
			IF NOT valid_period2(glob_rec_kandoouser.cmpy_code,pr_tran_rec.year_num, 
			pr_tran_rec.period_num,TRAN_TYPE_INVOICE_IN) THEN 
				LET msgresp=kandoomsg("P",9024,"") 
				#P9024 " Accounting period IS closed OR NOT SET up "
				NEXT FIELD year_num 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i645 
	IF int_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
