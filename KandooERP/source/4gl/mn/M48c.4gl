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

	Source code beautified by beautify.pl on 2020-01-02 17:31:30	$Id: $
}


# Purpose - Shop Order Receipt - Close shop ORDER FUNCTION
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M48.4gl" 


FUNCTION close_order() 

	DEFINE fv_recpt_per FLOAT, 
	fv_failed SMALLINT, 
	fv_runner CHAR(10), 
	fv_issued_qty LIKE shoporddetl.issued_qty, 
	fv_stk_iss_qty LIKE shoporddetl.issued_qty, 
	fv_receipt_qty LIKE shoporddetl.receipted_qty, 
	fv_stk_recpt_qty LIKE shoporddetl.receipted_qty, 
	fv_tran_date LIKE prodledg.tran_date, 
	fv_year_num LIKE prodledg.year_num, 
	fv_period_num LIKE prodledg.period_num, 
	fv_reserve_qty LIKE prodstatus.reserved_qty, 
	fv_onord_qty LIKE prodstatus.onord_qty, 
	fv_status LIKE prodstatus.status_ind, 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodledg RECORD LIKE prodledg.* 


	IF pr_shopordhead.order_qty > pr_shopordhead.receipted_qty + 
	pr_shopordhead.rejected_qty THEN 

		LET msgresp = kandoomsg("M", 8500, "") 
		# prompt "WARNING: This shop ORDER has NOT been fully receipted"
		#        "Do you still want TO close it (Y/N)?"

		IF msgresp = "N" THEN 
			RETURN 
		END IF 
	END IF 

	###
	### INPUT the close date AND the year & period
	###

	LET fv_tran_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) RETURNING fv_year_num, fv_period_num 

	INPUT fv_tran_date, fv_year_num, fv_period_num 
	WITHOUT DEFAULTS FROM tran_date, year_num, period_num 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD tran_date 
			IF fv_tran_date IS NULL THEN 
				ERROR "Shop ORDER close date must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD tran_date 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, fv_tran_date) 
			RETURNING fv_year_num, fv_period_num 

			DISPLAY fv_year_num, fv_period_num TO year_num, period_num 

		AFTER FIELD year_num 
			IF fv_year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF fv_period_num IS NULL THEN 
				ERROR "Period number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD period_num 
			END IF 

			CALL valid_period(glob_rec_kandoouser.cmpy_code, fv_year_num, fv_period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING fv_year_num, fv_period_num, fv_failed 

			IF fv_failed THEN 
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	LET fr_shopordhead.* = pr_shopordhead.* 
	LET fv_recpt_per = (pr_shopordhead.receipted_qty + 
	pr_shopordhead.rejected_qty) / pr_shopordhead.order_qty 

	GOTO bypass4 

	LABEL recovery4: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass4: 
	WHENEVER ERROR GOTO recovery4 

	BEGIN WORK 

		###
		### Issue any components that are backflush items
		###

		DECLARE c_cmpbkflush CURSOR FOR 
		SELECT * 
		FROM shoporddetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_shopordhead.shop_order_num 
		AND suffix_num = pr_shopordhead.suffix_num 
		AND type_ind = "C" 
		AND issued_qty < required_qty * fv_recpt_per 
		ORDER BY sequence_num 

		FOREACH c_cmpbkflush INTO fr_shoporddetl.* 
			LET err_message = "M48 - SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 

			IF fr_prodmfg.part_type_ind = "P" THEN 
				CONTINUE FOREACH 
			END IF 

			IF fr_prodmfg.backflush_ind = "N" THEN 
				CONTINUE FOREACH 
			END IF 

			###
			### Update reserved & onhand qtys on prodstatus
			###

			LET err_message = "M48 - SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 

			LET err_message = "M48 - SELECT FROM prodstatus failed" 

			SELECT * 
			INTO fr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 
			AND ware_code = fr_shoporddetl.issue_ware_code 

			IF fr_prodstatus.status_ind matches "[23]" 
			OR fr_prodstatus.stocked_flag = "N" THEN 
				ROLLBACK WORK 
				LET msgresp = kandoomsg("M", 9200, fr_shoporddetl.part_code) 
				# ERROR "CANNOT CLOSE: Invalid warehouse FOR product "
				RETURN 
			END IF 

			LET fv_issued_qty = (fr_shoporddetl.required_qty * fv_recpt_per) - 
			fr_shoporddetl.issued_qty 
			LET fv_stk_iss_qty = fv_issued_qty 

			CALL uom_convert(fr_shoporddetl.uom_code, fv_stk_iss_qty, 
			fr_product.*, fr_prodmfg.*) 
			RETURNING fv_stk_iss_qty 

			LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty - fv_stk_iss_qty 
			LET fr_prodstatus.reserved_qty = fr_prodstatus.reserved_qty - 
			fv_stk_iss_qty 

			IF fr_prodstatus.onhand_qty < 0 
			AND pr_mnparms.neg_issue_flag = "N" THEN 
				ROLLBACK WORK 
				LET msgresp = kandoomsg("M", 9204, fr_shoporddetl.part_code) 
				# MESSAGE "Issue qty exceeds on hand qty FOR product ", <part_code>
				RETURN 
			END IF 

			LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 
			LET fr_prodstatus.last_sale_date = fv_tran_date 
			LET err_message = "M48 - Update of prodstatus failed" 

			UPDATE prodstatus 
			SET * = fr_prodstatus.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 
			AND ware_code = fr_shoporddetl.issue_ware_code 

			###
			### Update shoporddetl table
			###

			LET fr_shoporddetl.act_est_cost_amt = fr_prodstatus.est_cost_amt 
			LET fr_shoporddetl.act_wgted_cost_amt = fr_prodstatus.wgted_cost_amt 
			LET fr_shoporddetl.act_act_cost_amt = fr_prodstatus.act_cost_amt 
			LET fr_shoporddetl.act_price_amt = fr_prodstatus.list_amt 

			CASE 
				WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
					LET fr_shoporddetl.act_est_cost_amt = fr_prodmfg.man_stk_con_qty 
					* fr_shoporddetl.act_est_cost_amt 

					LET fr_shoporddetl.act_wgted_cost_amt = 
					fr_shoporddetl.act_wgted_cost_amt 
					* fr_prodmfg.man_stk_con_qty 

					LET fr_shoporddetl.act_act_cost_amt = fr_prodmfg.man_stk_con_qty 
					* fr_shoporddetl.act_act_cost_amt 

					LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt 
					* fr_prodmfg.man_stk_con_qty 

				WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
					LET fr_shoporddetl.act_est_cost_amt = 
					fr_shoporddetl.act_est_cost_amt / fr_product.stk_sel_con_qty 

					LET fr_shoporddetl.act_wgted_cost_amt = 
					fr_shoporddetl.act_wgted_cost_amt 
					/ fr_product.stk_sel_con_qty 

					LET fr_shoporddetl.act_act_cost_amt = 
					fr_shoporddetl.act_act_cost_amt / fr_product.stk_sel_con_qty 

					LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt 
					/ fr_product.stk_sel_con_qty 

				WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
					LET fr_shoporddetl.act_est_cost_amt = 
					fr_shoporddetl.act_est_cost_amt * fr_product.pur_stk_con_qty 

					LET fr_shoporddetl.act_wgted_cost_amt = 
					fr_shoporddetl.act_wgted_cost_amt 
					* fr_product.pur_stk_con_qty 

					LET fr_shoporddetl.act_act_cost_amt = 
					fr_shoporddetl.act_act_cost_amt * fr_product.pur_stk_con_qty 

					LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt 
					* fr_product.pur_stk_con_qty 
			END CASE 

			IF fr_shoporddetl.actual_start_date IS NULL THEN 
				LET fr_shoporddetl.actual_start_date = fv_tran_date 
			END IF 

			LET fr_shoporddetl.issued_qty =fr_shoporddetl.issued_qty + fv_issued_qty 
			LET fr_shoporddetl.last_change_date = today 
			LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_shoporddetl.last_program_text = "M48" 
			LET err_message = "M48 - Update of shoporddetl failed" 

			UPDATE shoporddetl 
			SET * = fr_shoporddetl.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pr_shopordhead.shop_order_num 
			AND suffix_num = pr_shopordhead.suffix_num 
			AND sequence_num = fr_shoporddetl.sequence_num 

			LET pr_shopordhead.act_est_cost_amt = pr_shopordhead.act_est_cost_amt + 
			(fr_shoporddetl.act_est_cost_amt * fv_issued_qty) 

			LET pr_shopordhead.act_wgted_cost_amt = 
			pr_shopordhead.act_wgted_cost_amt + 
			(fr_shoporddetl.act_wgted_cost_amt * fv_issued_qty) 

			LET pr_shopordhead.act_act_cost_amt = pr_shopordhead.act_act_cost_amt + 
			(fr_shoporddetl.act_act_cost_amt * fv_issued_qty) 

			LET pr_shopordhead.act_price_amt = pr_shopordhead.act_price_amt + 
			(fr_shoporddetl.act_price_amt * fv_issued_qty) 

			###
			### Insert row INTO prodledg table
			###

			LET fr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_prodledg.part_code = fr_shoporddetl.part_code 
			LET fr_prodledg.ware_code = fr_shoporddetl.issue_ware_code 
			LET fr_prodledg.tran_date = fv_tran_date 
			LET fr_prodledg.seq_num = fr_prodstatus.seq_num 
			LET fr_prodledg.trantype_ind = "I" 
			LET fr_prodledg.year_num = fv_year_num 
			LET fr_prodledg.period_num = fv_period_num 
			LET fr_prodledg.source_text = "SO Recpt" 
			LET fr_prodledg.source_num = pr_shopordhead.shop_order_num 
			LET fr_prodledg.tran_qty = - fv_stk_iss_qty 
			LET fr_prodledg.sales_amt = fr_prodstatus.list_amt 
			LET fr_prodledg.hist_flag = "N" 
			LET fr_prodledg.post_flag = "N" 
			LET fr_prodledg.jour_num = 0 
			LET fr_prodledg.desc_text = pr_shopordhead.suffix_num 
			LET fr_prodledg.acct_code = pr_mnparms.inv_exp_acct_code 
			LET fr_prodledg.bal_amt = fr_prodstatus.onhand_qty 
			LET fr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET fr_prodledg.entry_date = today 

			CASE pr_inparms.cost_ind 
				WHEN "W" 
					LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
				WHEN "F" 
					LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
				WHEN "S" 
					LET fr_prodledg.cost_amt = fr_prodstatus.est_cost_amt 
				WHEN "L" 
					LET fr_prodledg.cost_amt = fr_prodstatus.act_cost_amt 
			END CASE 

			LET err_message = "M48 - Insert INTO prodledg failed" 

			INSERT INTO prodledg VALUES (fr_prodledg.*) 

			IF fr_product.serial_flag = "Y" THEN 
				LET fv_status = ser_update(glob_rec_kandoouser.cmpy_code, fr_shoporddetl.part_code, 
				fr_shoporddetl.issue_ware_code, 
				"SO Recpt", -1, fv_tran_date, 
				fv_stk_iss_qty) 
			END IF 
		END FOREACH 

		###
		### Receipt any by-products that are backflush items
		###

		DECLARE c_bpbkflush CURSOR FOR 
		SELECT * 
		FROM shoporddetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_shopordhead.shop_order_num 
		AND suffix_num = pr_shopordhead.suffix_num 
		AND type_ind = "B" 
		AND receipted_qty + rejected_qty > required_qty * fv_recpt_per 
		ORDER BY sequence_num 

		FOREACH c_bpbkflush INTO fr_shoporddetl.* 
			LET err_message = "M48 - Second SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 

			IF fr_prodmfg.backflush_ind = "N" THEN 
				CONTINUE FOREACH 
			END IF 

			###
			### Update on ORDER & onhand qtys on prodstatus
			###

			LET err_message = "M48 - Second SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 

			LET err_message = "M48 - Second SELECT FROM prodstatus failed" 

			SELECT * 
			INTO fr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 
			AND ware_code = fr_shoporddetl.issue_ware_code 

			IF fr_prodstatus.status_ind matches "[23]" 
			OR fr_prodstatus.stocked_flag = "N" THEN 
				ROLLBACK WORK 
				LET pr_shopordhead.* = fr_shopordhead.* 
				LET msgresp = kandoomsg("M", 9201, fr_shoporddetl.part_code) 
				# ERROR "CANNOT CLOSE: Invalid ware/hs FOR by-product "
				RETURN 
			END IF 

			LET fv_receipt_qty = (fr_shoporddetl.required_qty * fv_recpt_per) - 
			fr_shoporddetl.receipted_qty - 
			fr_shoporddetl.rejected_qty 
			LET fv_stk_recpt_qty = fv_receipt_qty 

			CALL uom_convert(fr_shoporddetl.uom_code, fv_stk_recpt_qty, 
			fr_product.*, fr_prodmfg.*) 
			RETURNING fv_stk_recpt_qty 

			LET fr_prodstatus.last_receipt_date = fv_tran_date 
			LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty - 
			fv_stk_recpt_qty 
			LET fr_prodstatus.onord_qty = fr_prodstatus.onord_qty + fv_stk_recpt_qty 

			IF fr_prodstatus.onhand_qty <= 0 THEN 
				LET fr_prodstatus.wgted_cost_amt = 0 
			ELSE 
				LET fr_prodstatus.wgted_cost_amt = (fr_prodstatus.wgted_cost_amt * 
				(fr_prodstatus.onhand_qty + fv_stk_recpt_qty)) 
				/ fr_prodstatus.onhand_qty 

				IF fr_prodstatus.wgted_cost_amt < 0 THEN 
					LET fr_prodstatus.wgted_cost_amt = 0 
				END IF 
			END IF 

			LET err_message = "M48 - Second UPDATE of prodstatus failed" 

			UPDATE prodstatus 
			SET * = fr_prodstatus.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shoporddetl.part_code 
			AND ware_code = fr_shoporddetl.issue_ware_code 

			###
			### Update shoporddetl table
			###

			LET fr_shoporddetl.receipted_qty = fr_shoporddetl.receipted_qty + 
			fv_receipt_qty 
			LET fr_shoporddetl.last_change_date = today 
			LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_shoporddetl.last_program_text = "M48" 
			LET err_message = "M48 - Second UPDATE of shoporddetl failed" 

			UPDATE shoporddetl 
			SET * = fr_shoporddetl.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pr_shopordhead.shop_order_num 
			AND suffix_num = pr_shopordhead.suffix_num 
			AND sequence_num = fr_shoporddetl.sequence_num 

			IF fr_product.serial_flag = "Y" THEN 
				CALL serial_in(glob_rec_kandoouser.cmpy_code, fr_product.vend_code, - fv_stk_recpt_qty, 
				fr_shoporddetl.part_code, 0, 0, fv_tran_date, 
				fr_shoporddetl.part_code, 
				fr_shoporddetl.issue_ware_code) 
			END IF 
		END FOREACH 

		###
		### Reverse reserved/onorder qtys on prodstatus FOR components/by-products which
		### are NOT fully issued/receipted
		###

		DECLARE c_reverse CURSOR FOR 
		SELECT * 
		FROM shoporddetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_shopordhead.shop_order_num 
		AND suffix_num = pr_shopordhead.suffix_num 
		AND type_ind matches "[CB]" 
		ORDER BY sequence_num 

		FOREACH c_reverse INTO fr_shoporddetl.* 

			IF fr_shoporddetl.type_ind = "C" THEN 
				IF fr_shoporddetl.issued_qty >= fr_shoporddetl.required_qty THEN 
					CONTINUE FOREACH 
				END IF 

				LET err_message = "M48 - Third SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				LET err_message = "M48 - Third SELECT FROM product failed" 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				LET fv_reserve_qty = fr_shoporddetl.required_qty - 
				fr_shoporddetl.issued_qty 

				CALL uom_convert(fr_shoporddetl.uom_code, fv_reserve_qty, 
				fr_product.*, fr_prodmfg.*) 
				RETURNING fv_reserve_qty 

				LET err_message = "M48 - Third SELECT FROM prodstatus failed" 

				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 
				AND ware_code = fr_shoporddetl.issue_ware_code 

				IF fr_prodstatus.status_ind matches "[23]" 
				OR fr_prodstatus.stocked_flag = "N" THEN 
					ROLLBACK WORK 
					LET pr_shopordhead.* = fr_shopordhead.* 
					LET msgresp = kandoomsg("M", 9200, fr_shoporddetl.part_code) 
					# ERROR "CANNOT CLOSE: Invalid warehouse FOR product "
					RETURN 
				END IF 

				LET err_message = "M48 - Third UPDATE of prodstatus failed" 

				UPDATE prodstatus 
				SET reserved_qty = reserved_qty - fv_reserve_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 
				AND ware_code = fr_shoporddetl.issue_ware_code 

				IF fr_shoporddetl.issued_qty = 0 THEN 
					CONTINUE FOREACH 
				END IF 

				LET fr_shoporddetl.actual_end_date = fv_tran_date 
				LET fr_shoporddetl.last_change_date = today 
				LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_shoporddetl.last_program_text = "M48" 
				LET err_message = "M48 - Third UPDATE of shoporddetl failed" 

				UPDATE shoporddetl 
				SET * = fr_shoporddetl.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = pr_shopordhead.shop_order_num 
				AND suffix_num = pr_shopordhead.suffix_num 
				AND sequence_num = fr_shoporddetl.sequence_num 

			ELSE 
				IF fr_shoporddetl.receipted_qty + fr_shoporddetl.rejected_qty <= 
				fr_shoporddetl.required_qty THEN 
					CONTINUE FOREACH 
				END IF 

				LET err_message = "M48 - Third SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				LET err_message = "M48 - Third SELECT FROM product failed" 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				LET fv_onord_qty = fr_shoporddetl.required_qty - 
				fr_shoporddetl.receipted_qty - 
				fr_shoporddetl.rejected_qty 

				CALL uom_convert(fr_shoporddetl.uom_code, fv_onord_qty, 
				fr_product.*, fr_prodmfg.*) 
				RETURNING fv_onord_qty 

				LET err_message = "M48 - Third SELECT FROM prodstatus failed" 

				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 
				AND ware_code = fr_shoporddetl.issue_ware_code 

				IF fr_prodstatus.status_ind matches "[23]" 
				OR fr_prodstatus.stocked_flag = "N" THEN 
					ROLLBACK WORK 
					LET pr_shopordhead.* = fr_shopordhead.* 
					LET msgresp = kandoomsg("M", 9201, fr_shoporddetl.part_code) 
					# ERROR "CANNOT CLOSE: Invalid ware/hs FOR by-product "
					RETURN 
				END IF 

				LET err_message = "M48 - Third UPDATE of prodstatus failed" 

				UPDATE prodstatus 
				SET onord_qty = onord_qty + fv_onord_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 
				AND ware_code = fr_shoporddetl.issue_ware_code 

				IF fr_shoporddetl.receipted_qty + fr_shoporddetl.rejected_qty = 0 
				THEN 
					CONTINUE FOREACH 
				END IF 

				LET fr_shoporddetl.actual_end_date = fv_tran_date 
				LET fr_shoporddetl.last_change_date = today 
				LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_shoporddetl.last_program_text = "M48" 
				LET err_message = "M48 - Third UPDATE of shoporddetl failed" 

				UPDATE shoporddetl 
				SET * = fr_shoporddetl.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = pr_shopordhead.shop_order_num 
				AND suffix_num = pr_shopordhead.suffix_num 
				AND sequence_num = fr_shoporddetl.sequence_num 
			END IF 
		END FOREACH 

		###
		### Update shopordhead table
		###

		LET pr_shopordhead.status_ind = "C" 
		LET pr_shopordhead.actual_end_date = fv_tran_date 
		LET pr_shopordhead.last_change_date = today 
		LET pr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
		LET pr_shopordhead.last_program_text = "M48" 
		LET err_message = "M48 - Update of shopordhead failed" 

		UPDATE shopordhead 
		SET * = pr_shopordhead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_shopordhead.shop_order_num 
		AND suffix_num = pr_shopordhead.suffix_num 

	COMMIT WORK 
	WHENEVER ERROR stop 

	CLEAR tran_date, year_num, period_num 

	IF pr_shopordhead.order_type_ind = "S" THEN 
		LET msgresp = kandoomsg("M", 8501, "") 
		# prompt "Do you want TO generate a sales ORDER picking list (Y/N)?"

		IF msgresp = "Y" THEN 
			CALL run_prog("O52", "", "", "", "") 
		END IF 
	END IF 

END FUNCTION 



FUNCTION uom_convert(fv_uom_code, fv_qty, fr_product, fr_prodmfg) 

	DEFINE fv_uom_code LIKE shoporddetl.uom_code, 
	fv_qty LIKE shoporddetl.required_qty, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.* 


	CASE 
		WHEN fv_uom_code = fr_prodmfg.man_uom_code 
			LET fv_qty = fv_qty * fr_prodmfg.man_stk_con_qty 

		WHEN fv_uom_code = fr_product.sell_uom_code 
			LET fv_qty = fv_qty / fr_product.stk_sel_con_qty 

		WHEN fv_uom_code = fr_product.pur_uom_code 
			LET fv_qty = fv_qty * fr_product.pur_stk_con_qty 
	END CASE 

	RETURN fv_qty 

END FUNCTION 
