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

	Source code beautified by beautify.pl on 2020-01-03 09:12:43	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module ISR Creates new products FROM old based on csv file

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "ISR_GLOBALS.4gl" 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("ISR") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CREATE temp TABLE t_rates (o_part_code CHAR(15), 
	o_ware_code CHAR(3), 
	n_part_code CHAR(15), 
	n_ware_code CHAR(3)) with no LOG 
	LET pr_window_name = "Bulk Product Recode" 
	LET pr_report_name = "Product Recode Error Report" 
	LET pr_menu_path = "ISR" 
	CALL menu_details() 
END MAIN 


FUNCTION validate_file() 
	DEFINE 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	pr_part RECORD 
		o_part_code CHAR(15), 
		o_ware_code CHAR(3), 
		n_part_code CHAR(15), 
		n_ware_code CHAR(3) 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_category RECORD LIKE category.*, 
	pr_trans_flag CHAR(1), 
	idx SMALLINT, 
	query_text CHAR(100) 
	DEFINE msgresp LIKE language.yes_flag 

	LET idx = 0 
	LET pr_inserted_rows = 0 
	LET pr_err_cnt = 0 
	INITIALIZE pr_quaderr.* TO NULL 
	LET query_text = "SELECT * FROM t_rates" 
	PREPARE s_rates FROM query_text 
	DECLARE c_rates CURSOR with HOLD FOR s_rates 
	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.
	LET pr_trans_flag = kandoomsg("I",8045,"") 
	## 8045 Transfer onhand stock TO new product Y/N?
	--   OPEN WINDOW w1 AT 8,17 with 3 rows, 40 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	DISPLAY "Updating Product..." at 1,1 
	FOREACH c_rates INTO pr_part.* 
		LET idx = idx + 1 
		CASE 
			WHEN pr_part.o_part_code IS NULL 
				LET pr_quaderr.error_text = "Old Part code must be entered" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				CONTINUE FOREACH 
			WHEN pr_part.o_ware_code IS NULL 
				LET pr_quaderr.error_text = "Old Ware code must be entered" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				CONTINUE FOREACH 
			WHEN pr_part.n_part_code IS NULL 
				LET pr_quaderr.error_text = "New Part code must be entered" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				CONTINUE FOREACH 
			WHEN pr_part.n_ware_code IS NULL 
				LET pr_quaderr.error_text = "New Ware code must be entered" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				CONTINUE FOREACH 
		END CASE 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part.o_part_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Product ", 
			pr_part.o_part_code clipped, " does NOT exist - unable TO UPDATE" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT * INTO pr_prodstatus.* FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part.o_part_code 
		AND ware_code = pr_part.o_ware_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Product Status ", 
			pr_part.o_part_code clipped," ", 
			pr_part.o_ware_code, " does NOT exist - unable TO UPDATE" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part.n_part_code 
		IF status != notfound THEN 
			LET pr_quaderr.error_text = "New Product ", 
			pr_part.n_part_code clipped, " already exists - unable TO UPDATE" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_part.n_ware_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Warehouse ", 
			pr_part.n_ware_code, " does NOT exist - unable TO UPDATE" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		DISPLAY pr_part.o_part_code at 2,10 

		DISPLAY pr_part.n_part_code at 3,10 

		LET pr_inserted_rows = pr_inserted_rows + 1 
		WHENEVER ERROR CONTINUE 
		BEGIN WORK 
			#### Create adjustment entry TO reduce old stock TO zero
			IF pr_prodstatus.onhand_qty <> 0 AND 
			pr_trans_flag = "Y" THEN 
				SELECT * INTO pr_category.* 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pr_product.cat_code 
				LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodledg.part_code = pr_part.o_part_code 
				LET pr_prodledg.ware_code = pr_part.o_ware_code 
				LET pr_prodledg.tran_date = today 
				LET pr_prodledg.seq_num = pr_prodstatus.seq_num + 1 
				LET pr_prodledg.trantype_ind = "A" 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING 
				pr_prodledg.year_num, 
				pr_prodledg.period_num 
				LET pr_prodledg.source_text = NULL 
				LET pr_prodledg.source_num = 0 
				LET pr_prodledg.tran_qty = pr_prodstatus.onhand_qty * -1 
				LET pr_prodledg.cost_amt = pr_prodstatus.wgted_cost_amt 
				LET pr_prodledg.sales_amt = 0 
				LET pr_prodledg.hist_flag = "N" 
				LET pr_prodledg.post_flag = "N" 
				LET pr_prodledg.jour_num = NULL 
				LET pr_prodledg.desc_text = "Product Recode ",pr_part.n_part_code 
				LET pr_prodledg.acct_code = pr_category.adj_acct_code 
				LET pr_prodledg.bal_amt = 0 
				LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_prodledg.entry_date = today 
				INSERT INTO prodledg VALUES (pr_prodledg.*) 
				IF status < 0 THEN 
					LET pr_quaderr.error_text = pr_part.o_part_code, 
					" ", "Failed prodledg INSERT " 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				UPDATE prodstatus SET onhand_qty = 0, 
				seq_num = seq_num + 1 
				WHERE part_code = pr_part.o_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_part.o_ware_code 
				IF status < 0 THEN 
					LET pr_quaderr.error_text = pr_part.o_part_code, 
					" ", "Failed prodstat UPDATE " 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				#### Create starting balance entry FOR new prod
				LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodledg.part_code = pr_part.n_part_code 
				LET pr_prodledg.ware_code = pr_part.n_ware_code 
				LET pr_prodledg.tran_date = today 
				LET pr_prodledg.seq_num = 1 
				LET pr_prodledg.trantype_ind = "A" 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) RETURNING 
				pr_prodledg.year_num, 
				pr_prodledg.period_num 
				LET pr_prodledg.source_text = NULL 
				LET pr_prodledg.source_num = 0 
				LET pr_prodledg.tran_qty = pr_prodstatus.onhand_qty 
				LET pr_prodledg.cost_amt = pr_prodstatus.wgted_cost_amt 
				LET pr_prodledg.sales_amt = 0 
				LET pr_prodledg.hist_flag = "N" 
				LET pr_prodledg.post_flag = "N" 
				LET pr_prodledg.jour_num = NULL 
				LET pr_prodledg.desc_text = "Product Recode" 
				LET pr_prodledg.acct_code = pr_category.adj_acct_code 
				LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
				LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_prodledg.entry_date = today 
				INSERT INTO prodledg VALUES (pr_prodledg.*) 
				IF status < 0 THEN 
					LET pr_quaderr.error_text = pr_part.n_part_code, 
					" ", "Failed prodledg INSERT " 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				IF pr_product.serial_flag = "Y" THEN 
					UPDATE serialinfo 
					SET part_code = pr_part.n_part_code, 
					ware_code = pr_part.n_part_code 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_part.o_part_code 
					AND ware_code = pr_part.o_ware_code 
					AND inv_num = 0 
				END IF 
			END IF 
			LET pr_product.part_code = pr_part.n_part_code 
			LET pr_product.ware_code = pr_part.n_ware_code 
			LET pr_prodstatus.part_code = pr_part.n_part_code 
			LET pr_prodstatus.ware_code = pr_part.n_ware_code 
			LET pr_prodstatus.reserved_qty = 0 
			LET pr_prodstatus.back_qty = 0 
			LET pr_prodstatus.transit_qty = 0 
			LET pr_prodstatus.forward_qty = 0 
			LET pr_prodstatus.onord_qty = 0 
			LET pr_prodstatus.seq_num = 1 
			LET pr_prodstatus.status_date = today 
			INSERT INTO product VALUES (pr_product.*) 
			IF status < 0 THEN 
				LET pr_quaderr.error_text = pr_part.n_part_code, 
				" ", "Failed product INSERT " 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				ROLLBACK WORK 
				CONTINUE FOREACH 
			END IF 
			INSERT INTO prodstatus VALUES (pr_prodstatus.*) 
			IF status < 0 THEN 
				LET pr_quaderr.error_text = pr_part.n_part_code, 
				" ", "Failed prodstatus INSERT" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				ROLLBACK WORK 
				CONTINUE FOREACH 
			END IF 
		COMMIT WORK 
	END FOREACH 
	WHENEVER ERROR stop 
	--   CLOSE WINDOW w1  -- albo  KD-758
END FUNCTION 
