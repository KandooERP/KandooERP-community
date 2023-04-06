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

	Source code beautified by beautify.pl on 2020-01-02 17:31:27	$Id: $
}


# Purpose - Shop Order Forward Flush

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	err_continue CHAR(1), 
	err_message CHAR(50), 

	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M42") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 


	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	CALL input_flush() 

END MAIN 



FUNCTION input_flush() 

	DEFINE fv_wc_code LIKE workcentre.work_centre_code, 
	fv_wc_desc LIKE workcentre.desc_text, 
	fv_prod_desc LIKE product.desc_text, 
	fv_so_num LIKE shopordhead.shop_order_num, 
	fv_suffix_num LIKE shopordhead.suffix_num, 
	fv_failed SMALLINT, 
	fv_cnt SMALLINT, 

	fr_shopordhead RECORD LIKE shopordhead.*, 

	fr_fwdflush RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num 
	END RECORD 


	OPEN WINDOW w1_m169 with FORM "M169" 
	CALL  windecoration_m("M169") -- albo kd-762 

	WHILE true 

		LET msgresp = kandoomsg("M", 1505, "") 		# MESSAGE "ESC TO Accept - DEL TO Exit"

		CLEAR FORM 
		INITIALIZE fr_fwdflush TO NULL 
		LET fr_fwdflush.tran_date = today 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
		RETURNING fr_fwdflush.year_num, fr_fwdflush.period_num 

		INPUT BY NAME fr_fwdflush.shop_order_num, 
		fr_fwdflush.suffix_num, 
		fr_fwdflush.work_centre_code, 
		fr_fwdflush.tran_date, 
		fr_fwdflush.year_num, 
		fr_fwdflush.period_num 
		WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(shop_order_num) 
						CALL show_shopords(glob_rec_kandoouser.cmpy_code) 
						RETURNING fv_so_num, fv_suffix_num 

						IF fv_so_num IS NOT NULL THEN 
							LET fr_fwdflush.shop_order_num = fv_so_num 
							LET fr_fwdflush.suffix_num = fv_suffix_num 

							DISPLAY BY NAME fr_fwdflush.shop_order_num, 
							fr_fwdflush.suffix_num 
						END IF 

					WHEN infield(suffix_num) 
						CALL show_shopords(glob_rec_kandoouser.cmpy_code) 
						RETURNING fv_so_num, fv_suffix_num 

						IF fv_so_num IS NOT NULL THEN 
							LET fr_fwdflush.shop_order_num = fv_so_num 
							LET fr_fwdflush.suffix_num = fv_suffix_num 

							DISPLAY BY NAME fr_fwdflush.shop_order_num, 
							fr_fwdflush.suffix_num 
						END IF 

					WHEN infield(work_centre_code) 
						CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

						IF fv_wc_code IS NOT NULL THEN 
							LET fr_fwdflush.work_centre_code = fv_wc_code 
							DISPLAY BY NAME fr_fwdflush.work_centre_code 
						END IF 
				END CASE 

			AFTER FIELD shop_order_num 
				IF fr_fwdflush.shop_order_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9693, "") 
					# ERROR "Shop ORDER number must be entered"
					NEXT FIELD shop_order_num 
				END IF 

				SELECT unique shop_order_num 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_fwdflush.shop_order_num 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9694, "") 
					# ERROR "This shop ORDER does NOT exist - Try Window"
					NEXT FIELD shop_order_num 
				END IF 

				IF fr_fwdflush.suffix_num IS NULL THEN 
					LET fr_fwdflush.suffix_num = 0 
					DISPLAY BY NAME fr_fwdflush.suffix_num 
				END IF 

			AFTER FIELD suffix_num 
				IF fr_fwdflush.suffix_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9696, "") 
					# ERROR "Shop ORDER suffix number must be entered"
					NEXT FIELD suffix_num 
				END IF 

				SELECT * 
				INTO fr_shopordhead.* 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_fwdflush.shop_order_num 
				AND suffix_num = fr_fwdflush.suffix_num 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9698, "") 
					#ERROR "Incorrect suffix number FOR this shop ORDER-Try Win"
					NEXT FIELD suffix_num 
				END IF 

				IF fr_shopordhead.order_type_ind = "F" THEN 
					LET msgresp = kandoomsg("M", 9806, "") 
					# ERROR "This IS a forecast shop ORDER AND cannot be fwd fl"
					NEXT FIELD shop_order_num 
				END IF 

				IF fr_shopordhead.status_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 9807, "") 
					# ERROR "This shop ORDER IS closed"
					NEXT FIELD shop_order_num 
				END IF 

				SELECT desc_text 
				INTO fv_prod_desc 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shopordhead.part_code 

				DISPLAY BY NAME fr_shopordhead.part_code, 
				fr_shopordhead.order_qty 
				DISPLAY fv_prod_desc TO formonly.desc_text 

			AFTER FIELD work_centre_code 
				IF fr_fwdflush.work_centre_code IS NOT NULL THEN 
					SELECT desc_text 
					INTO fv_wc_desc 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_fwdflush.work_centre_code 

					DISPLAY fv_wc_desc TO workcentre.desc_text 

					SELECT count(*) 
					INTO fv_cnt 
					FROM shoporddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = fr_fwdflush.shop_order_num 
					AND suffix_num = fr_fwdflush.suffix_num 
					AND type_ind = "C" 
					AND work_centre_code = fr_fwdflush.work_centre_code 

					IF fv_cnt = 0 THEN 
						LET msgresp = kandoomsg("M", 9808, "") 
						#ERROR "There are no components with this wc on this so"
						NEXT FIELD work_centre_code 
					END IF 
				ELSE 
					DISPLAY "" TO workcentre.desc_text 
				END IF 

			AFTER FIELD tran_date 
				IF fr_fwdflush.tran_date IS NULL THEN 
					LET msgresp = kandoomsg("M", 9809, "") 
					# ERROR "Transaction date must be entered"
					NEXT FIELD tran_date 
				END IF 

				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, fr_fwdflush.tran_date) 
				RETURNING fr_fwdflush.year_num, fr_fwdflush.period_num 

				DISPLAY BY NAME fr_fwdflush.year_num, 
				fr_fwdflush.period_num 

			AFTER FIELD year_num 
				IF fr_fwdflush.year_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9810, "") 
					# ERROR "Year number must be entered"
					NEXT FIELD year_num 
				END IF 

			AFTER FIELD period_num 
				IF fr_fwdflush.period_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9811, "") 
					# ERROR "Period number must be entered"
					NEXT FIELD period_num 
				END IF 

				CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_fwdflush.year_num, 
				fr_fwdflush.period_num, TRAN_TYPE_INVOICE_IN) 
				RETURNING fr_fwdflush.year_num, fr_fwdflush.period_num, 
				fv_failed 

				IF fv_failed THEN 
					NEXT FIELD year_num 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				SELECT * 
				INTO fr_shopordhead.* 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_fwdflush.shop_order_num 
				AND suffix_num = fr_fwdflush.suffix_num 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9698, "") 
					#ERROR "Incorrect suffix number FOR this shop ORDER-Try Win"
					NEXT FIELD suffix_num 
				END IF 

				IF fr_shopordhead.status_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 9807, "") 
					# ERROR "This shop ORDER IS closed"
					NEXT FIELD shop_order_num 
				END IF 

				SELECT desc_text 
				INTO fv_prod_desc 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shopordhead.part_code 

				DISPLAY BY NAME fr_shopordhead.part_code, 
				fr_shopordhead.order_qty 
				DISPLAY fv_prod_desc TO formonly.desc_text 

				IF fr_fwdflush.work_centre_code IS NOT NULL THEN 
					SELECT count(*) 
					INTO fv_cnt 
					FROM shoporddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = fr_fwdflush.shop_order_num 
					AND suffix_num = fr_fwdflush.suffix_num 
					AND type_ind = "C" 
					AND work_centre_code = fr_fwdflush.work_centre_code 

					IF fv_cnt = 0 THEN 
						LET msgresp = kandoomsg("M", 9808, "") 
						#ERROR "There are no components with this wc on this so"
						NEXT FIELD work_centre_code 
					END IF 
				END IF 

				IF fr_fwdflush.year_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9810, "") 
					# ERROR "Year number must be entered"
					NEXT FIELD year_num 
				END IF 

				IF fr_fwdflush.period_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9811, "") 
					# ERROR "Period number must be entered"
					NEXT FIELD period_num 
				END IF 

				CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_fwdflush.year_num, 
				fr_fwdflush.period_num, TRAN_TYPE_INVOICE_IN) 
				RETURNING fr_fwdflush.year_num, fr_fwdflush.period_num, 
				fv_failed 

				IF fv_failed THEN 
					NEXT FIELD year_num 
				END IF 

				LET msgresp = kandoomsg("M", 1532, "") 
				# MESSAGE "Searching database - please wait"

				IF NOT input_qtys(fr_fwdflush.*, fr_shopordhead.order_qty) THEN 
					LET msgresp = kandoomsg("M", 1505, "") 
					# MESSAGE "ESC TO Accept - DEL TO Exit"

					LET msgresp = kandoomsg("M", 9812, "") 
					# ERROR "This shop ORDER has no components available FOR ff"
					NEXT FIELD shop_order_num 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m169 

END FUNCTION 



FUNCTION input_qtys(fr_fwdflush, fv_order_qty) 

	DEFINE fv_where_text CHAR(40), 
	fv_query_text CHAR(1000), 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_wc_code LIKE shoporddetl.work_centre_code, 
	fv_ware_code LIKE shoporddetl.issue_ware_code, 
	fv_old_ware LIKE shoporddetl.issue_ware_code, 
	fv_order_qty LIKE shopordhead.order_qty, 
	fv_ord_qty LIKE shopordhead.order_qty, 
	fv_avail_qty LIKE shopordhead.order_qty, 
	fv_remain_qty LIKE shopordhead.order_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_issued_qty LIKE shoporddetl.issued_qty, 
	fv_issue_qty LIKE shoporddetl.issued_qty, 
	fv_reserved_qty LIKE prodstatus.reserved_qty, 
	fv_status LIKE prodstatus.status_ind, 
	fv_stocked LIKE prodstatus.stocked_flag, 
	fv_act_est_cost_amt LIKE shoporddetl.act_est_cost_amt, 
	fv_act_wgted_cost_amt LIKE shoporddetl.act_wgted_cost_amt, 
	fv_act_act_cost_amt LIKE shoporddetl.act_act_cost_amt, 
	fv_act_price_amt LIKE shoporddetl.act_price_amt, 
	fv_tran_qty array[2000] OF LIKE shoporddetl.required_qty, 
	fv_count SMALLINT, 
	fv_dataindex SMALLINT, 
	fv_dispindex SMALLINT, 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_lastsodetl RECORD LIKE shoporddetl.*, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodledg RECORD LIKE prodledg.*, 
	fr_fwdflush RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num 
	END RECORD, 

	fa_sodetl array[2000] OF RECORD 
		bin1_text LIKE prodstatus.bin1_text, 
		part_code LIKE shoporddetl.part_code, 
		uom_code LIKE shoporddetl.uom_code, 
		required_qty LIKE shoporddetl.required_qty, 
		issued_qty LIKE shoporddetl.issued_qty, 
		ware_code LIKE shoporddetl.issue_ware_code 
	END RECORD, 

	fa_fwdflush array[2000] OF RECORD 
		part_code LIKE shoporddetl.part_code, 
		desc_text LIKE product.desc_text, 
		uom_code LIKE shoporddetl.uom_code, 
		tran_qty LIKE shoporddetl.required_qty, 
		issue_ware_code LIKE shoporddetl.issue_ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty 
	END RECORD 


	IF fv_wc_code IS NOT NULL THEN 
		LET fv_where_text = "work_centre_code = '", fv_wc_code, "' " 
	ELSE 
		LET fv_where_text = "1=1 " 
	END IF 

	LET fv_query_text = "SELECT bin1_text, shoporddetl.part_code, uom_code, ", 
	"sum(required_qty), sum(issued_qty), ", 
	"issue_ware_code ", 
	"FROM shoporddetl, prodstatus ", 
	"WHERE shoporddetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND shoporddetl.cmpy_code = prodstatus.cmpy_code", 
	" AND shoporddetl.part_code = prodstatus.part_code", 
	" AND issue_ware_code = ware_code", 
	" AND shop_order_num = ",fr_fwdflush.shop_order_num, 
	" AND suffix_num = ", fr_fwdflush.suffix_num, 
	" AND type_ind = 'C' ", 
	"AND ", fv_where_text, 
	"group by bin1_text, shoporddetl.part_code, uom_code, ", 
	"issue_ware_code ", 
	"having sum(issued_qty) < sum(required_qty) ", 
	"ORDER BY bin1_text, shoporddetl.part_code, uom_code, ", 
	"issue_ware_code" 

	PREPARE sl_stmt1 FROM fv_query_text 
	DECLARE c_shoporddetl CURSOR FOR sl_stmt1 

	LET fv_cnt = 1 
	LET fv_avail_qty = fv_order_qty 
	INITIALIZE fa_fwdflush, fa_sodetl TO NULL 

	FOREACH c_shoporddetl INTO fa_sodetl[fv_cnt].* 
		SELECT * 
		INTO fr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fa_sodetl[fv_cnt].part_code 

		IF fr_prodmfg.backflush_ind = "Y" 
		OR fr_prodmfg.part_type_ind = "P" THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO fr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fa_sodetl[fv_cnt].part_code 

		SELECT onhand_qty 
		INTO fa_fwdflush[fv_cnt].onhand_qty 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fa_sodetl[fv_cnt].part_code 
		AND ware_code = fa_sodetl[fv_cnt].ware_code 

		LET fa_fwdflush[fv_cnt].part_code = fa_sodetl[fv_cnt].part_code 
		LET fa_fwdflush[fv_cnt].desc_text = fr_product.desc_text 
		LET fa_fwdflush[fv_cnt].uom_code = fa_sodetl[fv_cnt].uom_code 
		LET fa_fwdflush[fv_cnt].tran_qty = fa_sodetl[fv_cnt].required_qty 
		- fa_sodetl[fv_cnt].issued_qty 
		LET fa_fwdflush[fv_cnt].issue_ware_code = fa_sodetl[fv_cnt].ware_code 

		IF fa_fwdflush[fv_cnt].tran_qty < 0 THEN 
			LET fa_fwdflush[fv_cnt].tran_qty = 0 
		END IF 

		CASE 
			WHEN fa_fwdflush[fv_cnt].uom_code = fr_prodmfg.man_uom_code 
				LET fa_fwdflush[fv_cnt].onhand_qty = 
				fa_fwdflush[fv_cnt].onhand_qty / fr_prodmfg.man_stk_con_qty 

			WHEN fa_fwdflush[fv_cnt].uom_code = fr_product.pur_uom_code 
				LET fa_fwdflush[fv_cnt].onhand_qty = 
				fa_fwdflush[fv_cnt].onhand_qty / fr_product.pur_stk_con_qty 

			WHEN fa_fwdflush[fv_cnt].uom_code = fr_product.sell_uom_code 
				LET fa_fwdflush[fv_cnt].onhand_qty = 
				fa_fwdflush[fv_cnt].onhand_qty * fr_product.stk_sel_con_qty 
		END CASE 

		IF pr_mnparms.neg_issue_flag = "N" 
		AND fa_fwdflush[fv_cnt].tran_qty > fa_fwdflush[fv_cnt].onhand_qty THEN 
			LET fa_fwdflush[fv_cnt].tran_qty = fa_fwdflush[fv_cnt].onhand_qty 

			IF fa_fwdflush[fv_cnt].onhand_qty < 0 THEN 
				LET fa_fwdflush[fv_cnt].tran_qty = 0 
			END IF 
		END IF 

		LET fv_ord_qty = ((fa_sodetl[fv_cnt].issued_qty + 
		fa_fwdflush[fv_cnt].tran_qty) / 
		fa_sodetl[fv_cnt].required_qty) * fv_order_qty 

		IF fv_ord_qty < fv_avail_qty THEN 
			LET fv_avail_qty = fv_ord_qty 
		END IF 

		LET fv_cnt = fv_cnt + 1 

		IF fv_cnt > 2000 THEN 
			LET msgresp = kandoomsg("M", 9760, "") 
			# ERROR "Only the first 2000 detail lines have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	FOR fv_count = 1 TO 2000 
		LET fv_tran_qty[fv_count] = 0 
	END FOR 

	LET fv_cnt = fv_cnt - 1 

	IF fv_cnt = 0 THEN 
		RETURN false 
	END IF 

	DISPLAY fv_avail_qty TO avail_qty 

	CALL set_count(fv_cnt) 

	OPTIONS 
	INSERT KEY f36, 
	DELETE KEY f36 

	LET msgresp = kandoomsg("M", 1541, "") 
	# MESSAGE "F3 Fwd, F4 Bwd, F7 Qty Toggle, ESC Accept - DEL Exit"

	INPUT ARRAY fa_fwdflush WITHOUT DEFAULTS FROM sr_fwdflush.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 

		ON KEY (control-b) 
			IF infield(issue_ware_code) THEN 
				CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, fa_fwdflush[fv_idx].part_code) 
				RETURNING fv_ware_code 

				IF fv_ware_code IS NOT NULL THEN 
					LET fa_fwdflush[fv_idx].issue_ware_code = fv_ware_code 
					DISPLAY BY NAME fa_fwdflush[fv_idx].issue_ware_code 
				END IF 
			END IF 
			# F7 - toggle flush OPTIONS
		ON KEY (F7) 
			FOR fv_count = 1 TO fv_cnt 
				IF fa_fwdflush[fv_count].tran_qty IS NOT NULL 
				AND fa_fwdflush[fv_count].tran_qty <> 0 THEN 
					LET fv_tran_qty[fv_count] = fa_fwdflush[fv_count].tran_qty 
					LET fa_fwdflush[fv_count].tran_qty = 0 
				ELSE 
					LET fa_fwdflush[fv_count].tran_qty = fv_tran_qty[fv_count] 
				END IF 
			END FOR 

			LET fv_dataindex = fv_idx - fv_scrn 
			FOR fv_count = 1 TO 8 
				LET fv_dispindex = fv_dataindex + fv_count 
				DISPLAY fa_fwdflush[fv_dispindex].tran_qty 
				TO sr_fwdflush[fv_count].tran_qty 
				IF fv_cnt = fv_dispindex THEN 
					EXIT FOR 
				END IF 
			END FOR 

		AFTER FIELD tran_qty 
			IF fa_fwdflush[fv_idx].tran_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9813, "") 
				# ERROR "Quantity TO be issued must be entered"
				NEXT FIELD tran_qty 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty < 0 THEN 
				LET msgresp = kandoomsg("M", 9814, "") 
				# ERROR "Quantity TO be issued cannot be less than zero"
				NEXT FIELD tran_qty 
			END IF 

			SELECT status_ind, stocked_flag 
			INTO fv_status, fv_stocked 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_fwdflush[fv_idx].part_code 
			AND ware_code = fa_fwdflush[fv_idx].issue_ware_code 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_stocked = "N" THEN 
				LET msgresp = kandoomsg("M", 9763, "") 
				# ERROR "This product IS NOT stocked AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_status = "2" THEN 
				LET msgresp = kandoomsg("M", 9764, "") 
				# ERROR "This product IS on hold AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_status = "3" THEN 
				LET msgresp = kandoomsg("M", 9765, "") 
				# ERROR "This product IS marked FOR deletion AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fa_fwdflush[fv_idx].tran_qty > fa_fwdflush[fv_idx].onhand_qty 
			AND pr_mnparms.neg_issue_flag = "N" THEN 
				LET msgresp = kandoomsg("M", 9815, "") 
				# ERROR "Quantity TO issue cannot be greater than stock on hand"
				NEXT FIELD tran_qty 
			END IF 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND fv_idx = fv_cnt THEN 
				LET msgresp = kandoomsg("M", 9530, "") 
				# ERROR "There are no more rows in the direction you are going"
				NEXT FIELD tran_qty 
			END IF 

		BEFORE FIELD issue_ware_code 
			LET fv_old_ware = fa_fwdflush[fv_idx].issue_ware_code 

		AFTER FIELD issue_ware_code 
			IF fa_fwdflush[fv_idx].issue_ware_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9762, "") 
				# ERROR "Warehouse code must be entered"
				NEXT FIELD issue_ware_code 
			END IF 

			SELECT status_ind, stocked_flag 
			INTO fv_status, fv_stocked 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_fwdflush[fv_idx].part_code 
			AND ware_code = fa_fwdflush[fv_idx].issue_ware_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9535, "") 
				# ERROR "This warehouse IS NOT SET up FOR this product"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_stocked = "N" THEN 
				LET msgresp = kandoomsg("M", 9763, "") 
				# ERROR "This product IS NOT stocked AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_status = "2" THEN 
				LET msgresp = kandoomsg("M", 9764, "") 
				# ERROR "This product IS on hold AT this warehouse"
				NEXT FIELD tran_qty 
			END IF 

			IF fa_fwdflush[fv_idx].tran_qty > 0 
			AND fv_status = "3" THEN 
				LET msgresp = kandoomsg("M", 9765, "") 
				# ERROR "This product IS marked FOR deletion AT this warehouse"
				NEXT FIELD tran_qty 
			END IF 

			IF fv_old_ware != fa_fwdflush[fv_idx].issue_ware_code THEN 
				SELECT onhand_qty 
				INTO fa_fwdflush[fv_idx].onhand_qty 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_fwdflush[fv_idx].part_code 
				AND ware_code = fa_fwdflush[fv_idx].issue_ware_code 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_fwdflush[fv_idx].part_code 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_fwdflush[fv_idx].part_code 

				CASE 
					WHEN fa_fwdflush[fv_idx].uom_code = fr_prodmfg.man_uom_code 
						LET fa_fwdflush[fv_idx].onhand_qty = 
						fa_fwdflush[fv_idx].onhand_qty / 
						fr_prodmfg.man_stk_con_qty 

					WHEN fa_fwdflush[fv_idx].uom_code = fr_product.pur_uom_code 
						LET fa_fwdflush[fv_idx].onhand_qty = 
						fa_fwdflush[fv_idx].onhand_qty / 
						fr_product.pur_stk_con_qty 

					WHEN fa_fwdflush[fv_idx].uom_code = fr_product.sell_uom_code 
						LET fa_fwdflush[fv_idx].onhand_qty = 
						fa_fwdflush[fv_idx].onhand_qty * 
						fr_product.stk_sel_con_qty 
				END CASE 

				DISPLAY fa_fwdflush[fv_idx].onhand_qty 
				TO sr_fwdflush[fv_scrn].onhand_qty 

				LET fv_avail_qty = fv_order_qty 

				FOR fv_cnt1 = 1 TO fv_cnt 
					LET fv_remain_qty = fa_sodetl[fv_cnt1].required_qty - 
					fa_sodetl[fv_cnt1].issued_qty 
					LET fv_onhand_qty = fa_fwdflush[fv_cnt1].onhand_qty 

					IF fv_remain_qty > 0 
					AND fv_remain_qty > fv_onhand_qty 
					AND pr_mnparms.neg_issue_flag = "N" THEN 
						IF fv_onhand_qty < 0 THEN 
							LET fv_onhand_qty = 0 
						END IF 

						LET fv_ord_qty = ((fa_sodetl[fv_cnt1].issued_qty + 
						fv_onhand_qty) / fa_sodetl[fv_cnt1].required_qty) * 
						fv_order_qty 

						IF fv_ord_qty < fv_avail_qty THEN 
							LET fv_avail_qty = fv_ord_qty 
						END IF 
					END IF 
				END FOR 

				DISPLAY fv_avail_qty TO avail_qty 

				IF fa_fwdflush[fv_idx].tran_qty > 0 
				AND fa_fwdflush[fv_idx].tran_qty >fa_fwdflush[fv_idx].onhand_qty 
				AND pr_mnparms.neg_issue_flag = "N" THEN 
					LET msgresp = kandoomsg("M", 9815, "") 
					# ERROR "Qty TO issue cannot be greater than stock on hand"
					NEXT FIELD tran_qty 
				END IF 
			END IF 

			IF (fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("right")) 
			AND fv_idx = fv_cnt THEN 
				LET msgresp = kandoomsg("M", 9530, "") 
				# ERROR "There are no more rows in the direction you are going"
				NEXT FIELD issue_ware_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			GOTO bypass 

			LABEL recovery: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 

			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 

				###
				### SELECT shopordhead record
				###

				LET err_message = "M42 - SELECT FROM shopordhead failed" 

				SELECT * 
				INTO fr_shopordhead.* 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_fwdflush.shop_order_num 
				AND suffix_num = fr_fwdflush.suffix_num 

				LET fv_cnt2 = 0 

				FOR fv_cnt1 = 1 TO fv_cnt 
					IF fa_fwdflush[fv_cnt1].tran_qty = 0 THEN 
						CONTINUE FOR 
					END IF 

					###
					### Reverse out the reserved qty on prodstatus
					###

					LET err_message = "M42 - SELECT FROM prodmfg failed" 

					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_fwdflush[fv_cnt1].part_code 

					LET err_message = "M42 - SELECT FROM product failed" 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_fwdflush[fv_cnt1].part_code 

					LET fv_reserved_qty = fa_sodetl[fv_cnt1].required_qty - 
					fa_sodetl[fv_cnt1].issued_qty 

					IF fv_reserved_qty > 0 THEN 
						IF fa_fwdflush[fv_cnt1].tran_qty < fv_reserved_qty THEN 
							LET fv_reserved_qty = fa_fwdflush[fv_cnt1].tran_qty 
						END IF 

						CASE 
							WHEN fa_fwdflush[fv_cnt1].uom_code = 
								fr_prodmfg.man_uom_code 
								LET fv_reserved_qty = fv_reserved_qty * 
								fr_prodmfg.man_stk_con_qty 

							WHEN fa_fwdflush[fv_cnt1].uom_code = 
								fr_product.sell_uom_code 
								LET fv_reserved_qty = fv_reserved_qty / 
								fr_product.stk_sel_con_qty 

							WHEN fa_fwdflush[fv_cnt1].uom_code = 
								fr_product.pur_uom_code 
								LET fv_reserved_qty = fv_reserved_qty * 
								fr_product.pur_stk_con_qty 
						END CASE 

						LET err_message = "M42 - Update of prodstatus failed" 

						UPDATE prodstatus 
						SET reserved_qty = reserved_qty - fv_reserved_qty 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fa_sodetl[fv_cnt1].part_code 
						AND ware_code = fa_sodetl[fv_cnt1].ware_code 
					END IF 

					###
					### Update onhand qty on prodstatus
					###

					LET err_message = "M42 - SELECT FROM prodstatus failed" 

					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_fwdflush[fv_cnt1].part_code 
					AND ware_code = fa_fwdflush[fv_cnt1].issue_ware_code 

					IF fr_prodstatus.status_ind matches "[23]" 
					OR fr_prodstatus.stocked_flag = "N" THEN 
						ROLLBACK WORK 
						LET msgresp =kandoomsg("M",9202,fa_fwdflush[fv_cnt1].part_code) 
						# ERROR "Invalid warehouse FOR product ", <part_code>
						NEXT FIELD tran_qty 
					END IF 

					LET fv_issued_qty = fa_fwdflush[fv_cnt1].tran_qty 

					CASE 
						WHEN fa_fwdflush[fv_cnt1].uom_code = fr_prodmfg.man_uom_code 
							LET fv_issued_qty = fv_issued_qty * 
							fr_prodmfg.man_stk_con_qty 

						WHEN fa_fwdflush[fv_cnt1].uom_code = 
							fr_product.sell_uom_code 
							LET fv_issued_qty = fv_issued_qty / 
							fr_product.stk_sel_con_qty 

						WHEN fa_fwdflush[fv_cnt1].uom_code = fr_product.pur_uom_code 
							LET fv_issued_qty = fv_issued_qty * 
							fr_product.pur_stk_con_qty 
					END CASE 

					LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty - 
					fv_issued_qty 

					IF fr_prodstatus.onhand_qty < 0 
					AND pr_mnparms.neg_issue_flag = "N" THEN 
						ROLLBACK WORK 
						LET msgresp =kandoomsg("M",9204,fa_fwdflush[fv_cnt1].part_code) 
						# MESSAGE "Issue qty exceeds on hand qty FOR product..."
						NEXT FIELD tran_qty 
					END IF 

					LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 
					LET fr_prodstatus.last_sale_date = fr_fwdflush.tran_date 
					LET err_message = "M42 - Second UPDATE of prodstatus failed" 

					UPDATE prodstatus 
					SET * = fr_prodstatus.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_fwdflush[fv_cnt1].part_code 
					AND ware_code = fa_fwdflush[fv_cnt1].issue_ware_code 

					###
					### Update shoporddetl table
					###

					LET fv_act_est_cost_amt = fr_prodstatus.est_cost_amt 
					LET fv_act_wgted_cost_amt = fr_prodstatus.wgted_cost_amt 
					LET fv_act_act_cost_amt = fr_prodstatus.act_cost_amt 
					LET fv_act_price_amt = fr_prodstatus.list_amt 

					CASE 
						WHEN fa_fwdflush[fv_cnt1].uom_code = fr_prodmfg.man_uom_code 
							LET fv_act_est_cost_amt = fv_act_est_cost_amt * 
							fr_prodmfg.man_stk_con_qty 

							LET fv_act_wgted_cost_amt = fv_act_wgted_cost_amt * 
							fr_prodmfg.man_stk_con_qty 

							LET fv_act_act_cost_amt = fv_act_act_cost_amt * 
							fr_prodmfg.man_stk_con_qty 

							LET fv_act_price_amt = fv_act_price_amt * 
							fr_prodmfg.man_stk_con_qty 

						WHEN fa_fwdflush[fv_cnt1].uom_code =fr_product.sell_uom_code 
							LET fv_act_est_cost_amt = fv_act_est_cost_amt / 
							fr_product.stk_sel_con_qty 

							LET fv_act_wgted_cost_amt = fv_act_wgted_cost_amt / 
							fr_product.stk_sel_con_qty 

							LET fv_act_act_cost_amt = fv_act_act_cost_amt / 
							fr_product.stk_sel_con_qty 

							LET fv_act_price_amt = fv_act_price_amt / 
							fr_product.stk_sel_con_qty 

						WHEN fa_fwdflush[fv_cnt1].uom_code = fr_product.pur_uom_code 
							LET fv_act_est_cost_amt = fv_act_est_cost_amt * 
							fr_product.pur_stk_con_qty 

							LET fv_act_wgted_cost_amt = fv_act_wgted_cost_amt * 
							fr_product.pur_stk_con_qty 

							LET fv_act_act_cost_amt = fv_act_act_cost_amt * 
							fr_product.pur_stk_con_qty 

							LET fv_act_price_amt = fv_act_price_amt * 
							fr_product.pur_stk_con_qty 
					END CASE 

					LET fv_query_text = "SELECT * ", 
					"FROM shoporddetl ", 
					"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
					"AND shop_order_num = ", 
					fr_fwdflush.shop_order_num, " ", 
					"AND suffix_num = ", 
					fr_fwdflush.suffix_num, " ", 
					"AND part_code = '", 
					fa_fwdflush[fv_cnt1].part_code,"' ", 
					"AND type_ind = 'C' ", 
					"AND uom_code = '", 
					fa_fwdflush[fv_cnt1].uom_code, "' ", 
					"AND issue_ware_code = '", 
					fa_fwdflush[fv_cnt1].issue_ware_code, "' ", 
					"AND ", fv_where_text, 
					"ORDER BY sequence_num" 

					PREPARE sl_stmt FROM fv_query_text 
					DECLARE c_shopordetl CURSOR FOR sl_stmt 

					LET fv_remain_qty = fa_fwdflush[fv_cnt1].tran_qty 
					LET err_message = "M42 - SELECT FROM shoporddetl failed" 

					FOREACH c_shopordetl INTO fr_shoporddetl.* 
						IF fr_shoporddetl.issued_qty >= fr_shoporddetl.required_qty 
						THEN 
							LET fr_lastsodetl.* = fr_shoporddetl.* 
							CONTINUE FOREACH 
						END IF 

						LET fv_issue_qty = fr_shoporddetl.required_qty - 
						fr_shoporddetl.issued_qty 

						IF fv_issue_qty > fv_remain_qty THEN 
							LET fv_issue_qty = fv_remain_qty 
						END IF 

						LET fr_shoporddetl.issued_qty = 
						fr_shoporddetl.issued_qty + fv_issue_qty 
						LET fv_remain_qty = fv_remain_qty - fv_issue_qty 

						LET fr_shoporddetl.act_est_cost_amt = fv_act_est_cost_amt 
						LET fr_shoporddetl.act_wgted_cost_amt= fv_act_wgted_cost_amt 
						LET fr_shoporddetl.act_act_cost_amt = fv_act_act_cost_amt 
						LET fr_shoporddetl.act_price_amt = fv_act_price_amt 

						IF fr_shoporddetl.issued_qty >= fr_shoporddetl.required_qty 
						THEN 
							LET fr_shoporddetl.issue_ware_code = 
							fa_fwdflush[fv_cnt1].issue_ware_code 
						END IF 

						IF fr_shoporddetl.actual_start_date IS NULL THEN 
							LET fr_shoporddetl.actual_start_date = 
							fr_fwdflush.tran_date 
						END IF 

						LET fr_shoporddetl.last_change_date = today 
						LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
						LET fr_shoporddetl.last_program_text = "M42" 
						LET err_message = "M42 - Update of shoporddetl failed" 

						UPDATE shoporddetl 
						SET * = fr_shoporddetl.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND shop_order_num = fr_fwdflush.shop_order_num 
						AND suffix_num = fr_fwdflush.suffix_num 
						AND sequence_num = fr_shoporddetl.sequence_num 

						LET fr_shopordhead.act_est_cost_amt = 
						fr_shopordhead.act_est_cost_amt + 
						(fr_shoporddetl.act_est_cost_amt * fv_issue_qty) 

						LET fr_shopordhead.act_wgted_cost_amt = 
						fr_shopordhead.act_wgted_cost_amt + 
						(fr_shoporddetl.act_wgted_cost_amt * fv_issue_qty) 

						LET fr_shopordhead.act_act_cost_amt = 
						fr_shopordhead.act_act_cost_amt + 
						(fr_shoporddetl.act_act_cost_amt * fv_issue_qty) 

						LET fr_shopordhead.act_price_amt = 
						fr_shopordhead.act_price_amt + 
						(fr_shoporddetl.act_price_amt * fv_issue_qty) 

						IF fv_remain_qty = 0 THEN 
							EXIT FOREACH 
						END IF 

						LET fr_lastsodetl.* = fr_shoporddetl.* 
					END FOREACH 

					IF fv_remain_qty > 0 THEN 
						LET fr_shoporddetl.* = fr_lastsodetl.* 
						LET fr_shoporddetl.issued_qty = fr_shoporddetl.issued_qty + 
						fv_remain_qty 
						LET fr_shoporddetl.act_est_cost_amt = fv_act_est_cost_amt 
						LET fr_shoporddetl.act_wgted_cost_amt= fv_act_wgted_cost_amt 
						LET fr_shoporddetl.act_act_cost_amt = fv_act_act_cost_amt 
						LET fr_shoporddetl.act_price_amt = fv_act_price_amt 

						IF fr_shoporddetl.issued_qty >= fr_shoporddetl.required_qty 
						THEN 
							LET fr_shoporddetl.issue_ware_code = 
							fa_fwdflush[fv_cnt1].issue_ware_code 
						END IF 

						IF fr_shoporddetl.actual_start_date IS NULL THEN 
							LET fr_shoporddetl.actual_start_date = 
							fr_fwdflush.tran_date 
						END IF 

						LET fr_shoporddetl.last_change_date = today 
						LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
						LET fr_shoporddetl.last_program_text = "M42" 
						LET err_message = "M42 - Update of shoporddetl failed" 

						UPDATE shoporddetl 
						SET * = fr_shoporddetl.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND shop_order_num = fr_fwdflush.shop_order_num 
						AND suffix_num = fr_fwdflush.suffix_num 
						AND sequence_num = fr_shoporddetl.sequence_num 

						LET fr_shopordhead.act_est_cost_amt = 
						fr_shopordhead.act_est_cost_amt + 
						(fr_shoporddetl.act_est_cost_amt * fv_remain_qty) 

						LET fr_shopordhead.act_wgted_cost_amt = 
						fr_shopordhead.act_wgted_cost_amt + 
						(fr_shoporddetl.act_wgted_cost_amt * fv_remain_qty) 

						LET fr_shopordhead.act_act_cost_amt = 
						fr_shopordhead.act_act_cost_amt + 
						(fr_shoporddetl.act_act_cost_amt * fv_remain_qty) 

						LET fr_shopordhead.act_price_amt = 
						fr_shopordhead.act_price_amt + 
						(fr_shoporddetl.act_price_amt * fv_remain_qty) 
					END IF 

					###
					### Insert row INTO prodledg table
					###

					LET fr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET fr_prodledg.part_code = fa_fwdflush[fv_cnt1].part_code 
					LET fr_prodledg.ware_code = fa_fwdflush[fv_cnt1].issue_ware_code 
					LET fr_prodledg.tran_date = fr_fwdflush.tran_date 
					LET fr_prodledg.seq_num = fr_prodstatus.seq_num 
					LET fr_prodledg.trantype_ind = "I" 
					LET fr_prodledg.year_num = fr_fwdflush.year_num 
					LET fr_prodledg.period_num = fr_fwdflush.period_num 
					LET fr_prodledg.source_text = "SO Fwdfl" 
					LET fr_prodledg.source_num = fr_fwdflush.shop_order_num 
					LET fr_prodledg.tran_qty = - fv_issued_qty 
					LET fr_prodledg.sales_amt = fr_prodstatus.list_amt 
					LET fr_prodledg.hist_flag = "N" 
					LET fr_prodledg.post_flag = "N" 
					LET fr_prodledg.jour_num = 0 
					LET fr_prodledg.desc_text = fr_fwdflush.suffix_num 
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

					LET err_message = "M42 - Insert INTO prodledg failed" 

					INSERT INTO prodledg VALUES (fr_prodledg.*) 

					IF fr_product.serial_flag = "Y" THEN 
						LET fv_status = ser_update(glob_rec_kandoouser.cmpy_code, 
						fa_fwdflush[fv_cnt1].part_code, 
						fa_fwdflush[fv_cnt1].issue_ware_code, 
						"SO Fwdfl", -1, fr_fwdflush.tran_date, 
						fv_issued_qty) 
					END IF 

					LET fv_cnt2 = fv_cnt2 + 1 
				END FOR 

				###
				### Update shopordhead table
				###

				IF fv_cnt2 > 0 THEN 
					IF fr_shopordhead.release_date IS NULL THEN 
						LET fr_shopordhead.release_date = fr_fwdflush.tran_date 
					END IF 

					IF fr_shopordhead.actual_start_date IS NULL THEN 
						LET fr_shopordhead.actual_start_date = fr_fwdflush.tran_date 
					END IF 

					LET fr_shopordhead.status_ind = "R" 
					LET fr_shopordhead.last_change_date = today 
					LET fr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
					LET fr_shopordhead.last_program_text = "M42" 
					LET err_message = "M42 - Update of shopordhead failed" 

					UPDATE shopordhead 
					SET * = fr_shopordhead.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = fr_fwdflush.shop_order_num 
					AND suffix_num = fr_fwdflush.suffix_num 

					LET msgresp = kandoomsg("M", 7507, "") 
					# prompt"Shop ORDER forward flushed successfully-Any key TO cont
				ELSE 
					LET msgresp = kandoomsg("M", 7508, "") 
					# prompt "No shop ORDER components were forward flushed"
					#        "Any key TO continue"
				END IF 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	RETURN true 

END FUNCTION 
