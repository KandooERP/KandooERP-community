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

	Source code beautified by beautify.pl on 2019-12-31 14:28:27	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K11e - Updates Database with new OR Amended subscription
#                 - N.B. Insert CURSOR's have been used FOR efficiency
#  K11e.4gl:FUNCTION insert_sub()
#           creates new subhead RECORD with appropriate defaults
#  K11e.4gl:FUNCTION K11_write_sub()
#           updates subhead, subdetl records
#           creates other transactions according TO subhead.inv_ind


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K1_GROUP_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


FUNCTION insert_sub() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pt_subhead RECORD LIKE subhead.*, 
	pr_save_num LIKE subhead.sub_num 

	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message,status) != "Y" THEN 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			DECLARE c_tsubhead CURSOR FOR 
			SELECT * FROM t_subhead 
			FOREACH c_tsubhead INTO pr_subhead.* 
				LET pr_save_num = pr_subhead.sub_num 
				LET err_message = "K11 - Next Subscription Number update" 
				LET pr_subhead.sub_num = next_trans_num(glob_rec_kandoouser.cmpy_code,"SS","") 
				IF pr_subhead.sub_num < 0 THEN 
					LET err_message = "K11 - Error Obtaining Next Trans no." 
					LET status = pr_subhead.sub_num 
					RETURN status 
				END IF 
				SELECT area_code INTO pr_subhead.area_code 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = pr_subhead.territory_code 
				LET pr_subhead.sub_ind = "2" 
				LET pt_subhead.* = pr_subhead.* 
				LET pt_subhead.goods_amt = 0 
				LET pt_subhead.hand_amt = 0 
				LET pt_subhead.paid_amt = 0 
				LET pt_subhead.hand_tax_amt = 0 
				LET pt_subhead.freight_amt = 0 
				LET pt_subhead.freight_tax_amt = 0 
				LET pt_subhead.tax_amt = 0 
				LET pt_subhead.disc_amt = 0 
				LET pt_subhead.total_amt = 0 
				LET pt_subhead.cost_amt = 0 
				LET pt_subhead.line_num = 0 
				LET pt_subhead.status_ind = "I" 
				LET err_message = " K11 - Adding subscription Header row" 
				INSERT INTO subhead VALUES (pt_subhead.*) 
				IF pr_save_num IS NULL THEN 
					UPDATE t_subhead SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
					UPDATE t_subdetl SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
					UPDATE t_subschedule SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
				ELSE 
				UPDATE t_subhead SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = pr_save_num 
				UPDATE t_subdetl SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = pr_save_num 
				UPDATE t_subschedule SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = pr_save_num 
			END IF 
		END FOREACH 
	COMMIT WORK 
	WHENEVER ERROR CONTINUE 
	RETURN true 
END FUNCTION 


FUNCTION K11_write_sub(pr_mode) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	ps_subhead RECORD LIKE subhead.*, 
	pt_subhead RECORD LIKE subhead.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_customertype RECORD LIKE customertype.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_term RECORD LIKE term.*, 
	pr_save_line_num LIKE subdetl.sub_line_num, 
	pr_inv_num CHAR(4), 
	pr2_paid_amt DECIMAL(16,2), 
	total_cost,total_sale,total_tax DECIMAL(16,2), 
	pr_mode CHAR(4), 
	prg_name CHAR(8), 
	idx SMALLINT, 
	pr_float FLOAT, 
	pr_subschedule RECORD LIKE subschedule.* 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 


	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
		GOTO bypass 
		LABEL recovery: 
		LET pr_subhead.* = ps_subhead.* 
		IF error_recover(err_message,status) != "Y" THEN 
			RETURN 0 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			DECLARE c2_tsubhead CURSOR FOR 
			SELECT * FROM t_subhead 
			LET idx = 0 
			LET total_cost = 0 
			LET total_sale = 0 
			LET total_tax = 0 
			IF pr_paid_amt IS NULL THEN 
				LET pr_paid_amt = 0 
			END IF 
			LET pr2_paid_amt = pr_paid_amt 
			FOREACH c2_tsubhead INTO pr_subhead.* 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				## Declare Insert Cursor's
				## Subdetl
				DECLARE c_subdetl CURSOR FOR 
				INSERT INTO subdetl VALUES (pr_subdetl.*) 
				OPEN c_subdetl 
				## subschedule
				DECLARE c_subschedule CURSOR FOR 
				INSERT INTO subschedule VALUES (pr_subschedule.*) 
				OPEN c_subschedule 
				##
				LET ps_subhead.* = pr_subhead.* 
				LET err_message = "K11 - Locking Subscription Header record" 
				DECLARE c_subhead CURSOR FOR 
				SELECT * FROM subhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pr_subhead.sub_num 
				FOR UPDATE 
				OPEN c_subhead 
				FETCH c_subhead INTO pt_subhead.* 
				IF pt_subhead.rev_num != pr_subhead.rev_num THEN 
					LET err_message = "K11 - Subscription has changed during edit" 
					GOTO recovery 
				END IF 
				IF pt_subhead.last_inv_num != pr_subhead.last_inv_num THEN 
					LET err_message = "K11 - Subscription has been invoiced during edit" 
					GOTO recovery 
				END IF 
				SELECT * INTO pr_substype.* 
				FROM substype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				LET err_message = "K11 - Removing Existing Sub Line items" 
				DECLARE c1_subdetl CURSOR FOR 
				SELECT * FROM subdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND sub_num = pr_subhead.sub_num 
				FOR UPDATE 
				FOREACH c1_subdetl INTO pr_subdetl.* 
					SELECT * INTO pr_subcustomer.* 
					FROM subcustomer 
					WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
					AND cust_code= pr_subhead.cust_code 
					AND ship_code= pr_subhead.ship_code 
					AND sub_type_code = pr_subhead.sub_type_code 
					AND part_code= pr_subdetl.part_code 
					AND comm_date= pr_subhead.start_date 
					AND end_date= pr_subhead.end_date 
					IF status = 0 THEN 
						LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
						UPDATE subcustomer 
						SET next_seq_num = pr_subcustomer.next_seq_num, 
						unit_amt = pr_subdetl.unit_amt, 
						unit_tax_amt = pr_subdetl.unit_tax_amt 
						WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
						AND cust_code= pr_subhead.cust_code 
						AND ship_code= pr_subhead.ship_code 
						AND sub_type_code = pr_subhead.sub_type_code 
						AND part_code= pr_subdetl.part_code 
						AND comm_date= pr_subhead.start_date 
						AND end_date= pr_subhead.end_date 
					ELSE 
					LET pr_subcustomer.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_subcustomer.cust_code = pr_subhead.cust_code 
					LET pr_subcustomer.ship_code = pr_subhead.ship_code 
					LET pr_subcustomer.sub_type_code = pr_subhead.sub_type_code 
					LET pr_subcustomer.part_code = pr_subdetl.part_code 
					LET pr_subcustomer.comm_date = pr_subhead.start_date 
					LET pr_subcustomer.end_date = pr_subhead.end_date 
					LET pr_subcustomer.entry_date = today 
					LET pr_subcustomer.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_subcustomer.unit_amt = pr_subdetl.unit_amt 
					LET pr_subcustomer.unit_tax_amt = pr_subdetl.unit_tax_amt 
					LET pr_subcustomer.currency_code =pr_subhead.currency_code 
					LET pr_subcustomer.conv_qty = pr_subhead.conv_qty 
					LET pr_subcustomer.bonus_ind = "N" 
					LET pr_subcustomer.status_ind = "0" 
					LET pr_subcustomer.next_seq_num = 1 
					LET pr_subcustomer.last_issue_num = 0 
					INSERT INTO subcustomer VALUES (pr_subcustomer.*) 
				END IF 
				LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subaudit.part_code = pr_subdetl.part_code 
				LET pr_subaudit.cust_code = pr_subhead.cust_code 
				LET pr_subaudit.ship_code = pr_subhead.ship_code 
				LET pr_subaudit.start_date = pr_subhead.start_date 
				LET pr_subaudit.end_date = pr_subhead.end_date 
				LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
				LET pr_subaudit.tran_date = pr_subhead.sub_date 
				LET pr_subaudit.entry_date = today 
				LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_subaudit.tran_qty = 0 - pr_subdetl.sub_qty + 0 
				LET pr_subaudit.unit_amt = pr_subdetl.unit_amt 
				LET pr_subaudit.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_subaudit.currency_code = pr_subhead.currency_code 
				LET pr_subaudit.conv_qty = pr_subhead.conv_qty 
				LET pr_subaudit.tran_type_ind = "SUB" 
				LET pr_subaudit.sub_num = pr_subhead.sub_num 
				LET pr_subaudit.source_num = pr_subhead.sub_num 
				LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
				LET pr_subaudit.comm_text = "Subscription Edit " 
				INSERT INTO subaudit VALUES (pr_subaudit.*) 
				DELETE FROM subdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
				DELETE FROM subschedule 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
			END FOREACH 
			LET pr_subhead.line_num = 0 
			DECLARE c_t_subdetl CURSOR FOR 
			SELECT * FROM t_subdetl 
			WHERE sub_num = pr_subhead.sub_num 
			ORDER BY sub_line_num 
			DECLARE c_t_subschedule CURSOR FOR 
			SELECT * FROM t_subschedule 
			WHERE sub_line_num = pr_save_line_num 
			AND sub_num = pr_subhead.sub_num 
			ORDER BY issue_num 
			FOREACH c_t_subdetl INTO pr_subdetl.* 
				LET pr_save_line_num = pr_subdetl.sub_line_num 
				LET pr_subhead.line_num = pr_subhead.line_num + 1 
				LET pr_subdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subdetl.cust_code = pr_subhead.cust_code 
				LET pr_subdetl.sub_num = pr_subhead.sub_num 
				LET pr_subdetl.sub_line_num = pr_subhead.line_num 
				IF pr_subdetl.status_ind IS NULL THEN 
					LET pr_subdetl.status_ind = "1" 
				END IF 
				SELECT * INTO pr_subcustomer.* 
				FROM subcustomer 
				WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
				AND cust_code= pr_subhead.cust_code 
				AND ship_code= pr_subhead.ship_code 
				AND sub_type_code = pr_subhead.sub_type_code 
				AND part_code= pr_subdetl.part_code 
				AND comm_date= pr_subhead.start_date 
				AND end_date= pr_subhead.end_date 
				IF status = 0 THEN 
					LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
					UPDATE subcustomer 
					SET next_seq_num = pr_subcustomer.next_seq_num, 
					unit_amt = pr_subdetl.unit_amt, 
					unit_tax_amt = pr_subdetl.unit_tax_amt 
					WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
					AND cust_code= pr_subhead.cust_code 
					AND ship_code= pr_subhead.ship_code 
					AND sub_type_code = pr_subhead.sub_type_code 
					AND part_code= pr_subdetl.part_code 
					AND comm_date= pr_subhead.start_date 
					AND end_date= pr_subhead.end_date 
				ELSE 
				LET pr_subcustomer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subcustomer.cust_code = pr_subhead.cust_code 
				LET pr_subcustomer.ship_code = pr_subhead.ship_code 
				LET pr_subcustomer.sub_type_code = pr_subhead.sub_type_code 
				LET pr_subcustomer.part_code = pr_subdetl.part_code 
				LET pr_subcustomer.comm_date = pr_subhead.start_date 
				LET pr_subcustomer.end_date = pr_subhead.end_date 
				LET pr_subcustomer.entry_date = today 
				LET pr_subcustomer.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_subcustomer.unit_amt = pr_subdetl.unit_amt 
				LET pr_subcustomer.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_subcustomer.currency_code =pr_subhead.currency_code 
				LET pr_subcustomer.conv_qty = pr_subhead.conv_qty 
				LET pr_subcustomer.bonus_ind = "N" 
				LET pr_subcustomer.status_ind = "0" 
				LET pr_subcustomer.next_seq_num = 1 
				LET pr_subcustomer.last_issue_num = 0 
				INSERT INTO subcustomer VALUES (pr_subcustomer.*) 
			END IF 
			LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_subaudit.part_code = pr_subdetl.part_code 
			LET pr_subaudit.cust_code = pr_subhead.cust_code 
			LET pr_subaudit.ship_code = pr_subhead.ship_code 
			LET pr_subaudit.start_date = pr_subhead.start_date 
			LET pr_subaudit.end_date = pr_subhead.end_date 
			LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
			LET pr_subaudit.tran_date = pr_subhead.sub_date 
			LET pr_subaudit.entry_date = today 
			LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_subaudit.tran_qty = pr_subdetl.sub_qty 
			LET pr_subaudit.unit_amt = pr_subdetl.unit_amt 
			LET pr_subaudit.unit_tax_amt = pr_subdetl.unit_tax_amt 
			LET pr_subaudit.currency_code = pr_subhead.currency_code 
			LET pr_subaudit.conv_qty = pr_subhead.conv_qty 
			LET pr_subaudit.tran_type_ind = "SUB" 
			LET pr_subaudit.sub_num = pr_subhead.sub_num 
			LET pr_subaudit.source_num = pr_subhead.sub_num 
			LET pr_subaudit.comm_text = "Subscription entry" 
			LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
			INSERT INTO subaudit VALUES (pr_subaudit.*) 
			#################################################
			# are there any invoice lines
			#################################################
			IF pr_substype.inv_ind = "1" OR 
			pr_substype.inv_ind = "4" THEN 
				SELECT * INTO pr_subproduct.* 
				FROM subproduct 
				WHERE part_code = pr_subdetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				IF status = notfound THEN 
					LET err_message = "Subscription NOT setup" 
					LET status = -1 
					GOTO recovery 
				END IF 
				INITIALIZE pr_invoicedetl.* TO NULL 
				LET idx = idx + 1 
				LET pr_invoicedetl.line_num = idx 
				LET pr_invoicedetl.cust_code = pr_subdetl.cust_code 
				LET pr_invoicedetl.part_code = pr_subdetl.part_code 
				LET pr_invoicedetl.ware_code = pr_subdetl.ware_code 
				LET pr_invoicedetl.line_text = pr_subdetl.line_text 
				LET pr_invoicedetl.ship_qty = pr_subdetl.sub_qty - 
				pr_subdetl.inv_qty 
				LET pr_invoicedetl.unit_sale_amt = pr_subdetl.unit_amt 
				LET pr_invoicedetl.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_invoicedetl.ext_sale_amt = pr_subdetl.unit_amt * 
				pr_invoicedetl.ship_qty 
				LET pr_invoicedetl.ext_tax_amt = pr_subdetl.unit_tax_amt * 
				pr_invoicedetl.ship_qty 
				LET pr_invoicedetl.line_total_amt= 
				pr_invoicedetl.ext_sale_amt + 
				pr_invoicedetl.ext_tax_amt 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_invoicedetl.part_code 
				LET pr_invoicedetl.cat_code = pr_product.cat_code 
				LET pr_invoicedetl.ser_flag = pr_product.serial_flag 
				IF pr_invoicedetl.line_text IS NULL THEN 
					LET pr_invoicedetl.line_text = pr_product.desc_text 
				END IF 
				IF pr_mode = "CORP" THEN 
					LET pr_invoicedetl.line_text = pr_subhead.cust_code clipped," ", 
					pr_invoicedetl.line_text 
				END IF 
				LET pr_invoicedetl.uom_code = pr_product.sell_uom_code 
				LET pr_invoicedetl.order_num = pr_subhead.sub_num 
				LET pr_invoicedetl.order_line_num = pr_subdetl.sub_line_num 
				LET pr_invoicedetl.uom_code = pr_product.sell_uom_code 
				LET pr_invoicedetl.prodgrp_code = pr_product.prodgrp_code 
				LET pr_invoicedetl.maingrp_code = pr_product.maingrp_code 
				IF pr_subproduct.linetype_ind = "1" THEN 
					SELECT subacct_code INTO pr_invoicedetl.line_acct_code 
					FROM substype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = pr_subhead.sub_type_code 
					AND subacct_code IS NOT NULL 
					IF status = notfound THEN 
						SELECT sub_acct_code INTO pr_invoicedetl.line_acct_code 
						FROM ssparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
				SELECT sale_acct_code INTO pr_invoicedetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pr_invoicedetl.cat_code 
			END IF 
			SELECT * INTO pr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_invoicedetl.ware_code 
			AND part_code = pr_invoicedetl.part_code 
			LET pr_invoicedetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
			* pr_subhead.conv_qty 
			LET pr_invoicedetl.ext_cost_amt = 
			pr_invoicedetl.unit_cost_amt * 
			pr_invoicedetl.ship_qty 
			LET pr_invoicedetl.list_price_amt = pr_prodstatus.list_amt 
			* pr_subhead.conv_qty 
			IF pr_invoicedetl.list_price_amt = 0 THEN 
				LET pr_invoicedetl.list_price_amt = 
				pr_invoicedetl.unit_sale_amt 
				LET pr_invoicedetl.disc_per = 0 
			END IF 
			IF pr_invoicedetl.disc_per IS NULL THEN 
				## calc disc_per based on price
				LET pr_float = 100 * 
				(pr_invoicedetl.list_price_amt 
				-pr_invoicedetl.unit_sale_amt) 
				/pr_invoicedetl.list_price_amt 
				IF pr_float <= 0 THEN 
					LET pr_invoicedetl.disc_per = 0 
					LET pr_invoicedetl.list_price_amt = 
					pr_invoicedetl.unit_sale_amt 
				ELSE 
				LET pr_invoicedetl.disc_per = pr_float 
			END IF 
		END IF 
		LET pr_invoicedetl.disc_amt = 
		pr_invoicedetl.list_price_amt 
		- pr_invoicedetl.unit_sale_amt 
		LET total_cost = total_cost + pr_invoicedetl.ext_cost_amt 
		LET total_sale = total_sale + pr_invoicedetl.ext_sale_amt 
		LET total_tax = total_tax + pr_invoicedetl.ext_tax_amt 
		IF pr_invoicedetl.ship_qty > 0 THEN 
			INSERT INTO t_invoicedetl VALUES (pr_invoicedetl.*) 
		END IF 
		LET pr_subdetl.inv_qty = pr_subdetl.inv_qty+ pr_invoicedetl.ship_qty 
		IF pr_subproduct.linetype_ind = "1" THEN 
			UPDATE t_subschedule SET inv_qty = sched_qty 
			WHERE sub_line_num = pr_save_line_num 
		ELSE 
		LET pr_subdetl.issue_qty = pr_subdetl.inv_qty 
	END IF 
END IF 
LET err_message = "K11 - Sub Line Item insert" 
PUT c_subdetl 
FOREACH c_t_subschedule INTO pr_subschedule.* 
	LET pr_subschedule.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_subschedule.sub_num = pr_subhead.sub_num 
	LET pr_subschedule.sub_line_num = pr_subdetl.sub_line_num 
	LET err_message = "K11 - Sub Line Item insert" 
	PUT c_subschedule 
END FOREACH 
END FOREACH 
FLUSH c_subdetl 
CLOSE c_subdetl 
LET pr_subhead.rev_num = pr_subhead.rev_num + 1 
LET pr_subhead.rev_date = today 
LET pr_subhead.cost_ind = pr_arparms.costings_ind 
LET err_message = "K11 - Update Subscription Header record" 
IF pr_subhead.line_num = 0 THEN 
## No lines exist THEN sub IS cancelled
LET pr_subhead.status_ind = "C" 
ELSE 
SELECT unique 1 FROM subdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND (inv_qty != 0 
OR issue_qty != 0) 
IF sqlca.sqlcode = notfound THEN 
## No lines shipped THEN sub IS unshipped
LET pr_subhead.status_ind = "U" 
ELSE 
SELECT unique 1 FROM subdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND (inv_qty != sub_qty 
OR inv_qty != issue_qty 
OR issue_qty != sub_qty) 
IF sqlca.sqlcode = 0 THEN 
## Incomplete lines exists so sub IS partial shipped
LET pr_subhead.status_ind = "P" 
ELSE 
LET pr_subhead.status_ind = "C" 
END IF 
END IF 
END IF 
IF pr_subhead.sales_code IS NULL THEN 
LET pr_subhead.sales_code = pr_customer.sale_code 
END IF 
IF pr_subhead.territory_code IS NULL THEN 
LET pr_subhead.territory_code = pr_customer.territory_code 
END IF 
IF pr_subhead.delivery_ind IS NULL THEN 
LET pr_subhead.delivery_ind = "1" 
END IF 
IF pr_subhead.paid_amt IS NULL THEN 
LET pr_subhead.paid_amt = 0 
END IF 
IF (pr_subhead.total_amt - pr_subhead.paid_amt) < pr2_paid_amt THEN 
LET pr2_paid_amt = pr2_paid_amt - (pr_subhead.total_amt 
- pr_subhead.paid_amt) 
LET pr_subhead.paid_amt = pr_subhead.total_amt 
ELSE 
LET pr_subhead.paid_amt = pr_subhead.paid_amt + pr2_paid_amt 
LET pr2_paid_amt = 0 
END IF 
UPDATE subhead SET * = pr_subhead.* 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
IF pr_mode = "CORP" THEN 
	#---------------------------------------------------------
	OUTPUT TO REPORT K15_rpt_list(glob_rpt_idx,pr_subhead.*) 
	#---------------------------------------------------------
END IF 
END FOREACH 
###################################################
## Does Invoice need TO be created
###################################################
IF pr_mode = "CORP" 
OR pr_subhead.corp_flag = "Y" THEN 
IF pr_subhead.corp_cust_code IS NOT NULL THEN 
LET pr_subhead.cust_code = pr_subhead.corp_cust_code 
END IF 
IF pr_mode = "CORP" THEN 
LET pr_subhead.* = pr_csubhead.* 
END IF 
SELECT * INTO pr_customer.* 
FROM customer 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_subhead.cust_code 
IF pr_subhead.sales_code IS NULL THEN 
LET pr_subhead.sales_code = pr_customer.sale_code 
END IF 
IF pr_subhead.territory_code IS NULL THEN 
LET pr_subhead.territory_code = pr_customer.territory_code 
END IF 
IF pr_subhead.delivery_ind IS NULL THEN 
LET pr_subhead.delivery_ind = "1" 
END IF 
IF pr_subhead.paid_amt IS NULL THEN 
LET pr_subhead.paid_amt = 0 
END IF 
IF pr_paid_amt IS NULL THEN 
LET pr_paid_amt = 0 
END IF 
SELECT sum(goods_amt), 
sum(tax_amt), 
sum(hand_amt), 
sum(freight_amt), 
sum(hand_tax_amt), 
sum(freight_tax_amt) 
INTO pr_subhead.goods_amt, 
pr_subhead.tax_amt, 
pr_subhead.hand_amt, 
pr_subhead.freight_amt, 
pr_subhead.hand_tax_amt, 
pr_subhead.freight_tax_amt 
FROM t_subhead 
IF pr_subhead.goods_amt IS NULL THEN 
LET pr_subhead.goods_amt = 0 
END IF 
IF pr_subhead.tax_amt IS NULL THEN 
LET pr_subhead.tax_amt = 0 
END IF 
IF pr_subhead.hand_amt IS NULL THEN 
LET pr_subhead.hand_amt = 0 
END IF 
IF pr_subhead.freight_amt IS NULL THEN 
LET pr_subhead.freight_amt = 0 
END IF 
IF pr_subhead.hand_tax_amt IS NULL THEN 
LET pr_subhead.hand_tax_amt = 0 
END IF 
IF pr_subhead.freight_tax_amt IS NULL THEN 
LET pr_subhead.freight_tax_amt = 0 
END IF 
LET pr_subhead.total_amt = pr_subhead.goods_amt 
+ pr_subhead.tax_amt 
+ pr_subhead.hand_amt 
+ pr_subhead.hand_tax_amt 
+ pr_subhead.freight_amt 
+ pr_subhead.freight_tax_amt 
END IF 
IF pr_subhead.hand_inv_amt IS NULL THEN 
LET pr_subhead.hand_inv_amt = 0 
END IF 
IF pr_subhead.hndtax_inv_amt IS NULL THEN 
LET pr_subhead.hndtax_inv_amt = 0 
END IF 
IF pr_subhead.freight_inv_amt IS NULL THEN 
LET pr_subhead.freight_inv_amt = 0 
END IF 
IF pr_subhead.frttax_inv_amt IS NULL THEN 
LET pr_subhead.frttax_inv_amt = 0 
END IF 
LET pr_invoicehead.inv_num = 0 
SELECT unique 1 FROM t_invoicedetl 
WHERE ship_qty > 0 
IF status = 0 THEN 
IF pr_customer.corp_cust_code IS NOT NULL 
AND pr_customer.corp_cust_ind = "1" THEN 
LET pr_invoicehead.cust_code = pr_customer.corp_cust_code 
LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
ELSE 
LET pr_invoicehead.cust_code = pr_subhead.cust_code 
LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
END IF 
DECLARE c_customer CURSOR FOR 
SELECT * FROM customer 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_invoicehead.cust_code 
FOR UPDATE 
OPEN c_customer 
FETCH c_customer INTO pr_customer.* 
LET pr_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_invoicehead.ord_num = NULL 
LET pr_invoicehead.purchase_code = pr_subhead.ord_text 
LET pr_invoicehead.ref_num = NULL 
LET pr_invoicehead.inv_date = pr_subhead.sub_date 
LET pr_invoicehead.entry_code = pr_subhead.entry_code 
LET pr_invoicehead.entry_date = pr_subhead.entry_date 
LET pr_invoicehead.sale_code = pr_subhead.sales_code 
LET pr_invoicehead.term_code = pr_subhead.term_code 
LET pr_invoicehead.tax_code = pr_subhead.tax_code 
SELECT tax_per INTO pr_invoicehead.tax_per FROM tax 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND tax_code = pr_invoicehead.tax_code 
LET pr_invoicehead.goods_amt = total_sale 
LET pr_invoicehead.hand_amt = pr_subhead.hand_amt - 
pr_subhead.hand_inv_amt 
LET pr_invoicehead.hand_tax_code = pr_subhead.hand_tax_code 
LET pr_invoicehead.hand_tax_amt = pr_subhead.hand_tax_amt - 
pr_subhead.hndtax_inv_amt 
LET pr_invoicehead.freight_amt = pr_subhead.freight_amt - 
pr_subhead.freight_inv_amt 
LET pr_invoicehead.freight_tax_code = pr_subhead.freight_tax_code 
LET pr_invoicehead.freight_tax_amt = pr_subhead.freight_tax_amt - 
pr_subhead.frttax_inv_amt 
LET pr_invoicehead.tax_amt = total_tax 
LET pr_invoicehead.disc_amt= 
(pr_invoicehead.total_amt*pr_term.disc_per/100) 
LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt 
+ pr_invoicehead.tax_amt 
+ pr_invoicehead.hand_amt 
+ pr_invoicehead.hand_tax_amt 
+ pr_invoicehead.freight_amt 
+ pr_invoicehead.freight_tax_amt 
LET pr_invoicehead.cost_amt = total_cost 
LET pr_invoicehead.paid_amt = 0 
LET pr_invoicehead.paid_date = NULL 
LET pr_invoicehead.disc_taken_amt = 0 
SELECT * INTO pr_term.* 
FROM term 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND term_code = pr_invoicehead.term_code 
CALL get_due_and_discount_date(pr_term.*,pr_invoicehead.inv_date) 
RETURNING pr_invoicehead.due_date, 
pr_invoicehead.disc_date 
LET pr_invoicehead.disc_amt= 
(pr_invoicehead.total_amt*pr_term.disc_per/100) 
LET pr_invoicehead.expected_date = NULL 
CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_invoicehead.inv_date) 
RETURNING pr_invoicehead.year_num, 
pr_invoicehead.period_num 
LET pr_invoicehead.on_state_flag = "N" 
LET pr_invoicehead.posted_flag = "N" 
LET pr_invoicehead.seq_num = 0 
LET pr_invoicehead.line_num = idx 
LET pr_invoicehead.printed_num = 0 
LET pr_invoicehead.story_flag = NULL 
LET pr_invoicehead.rev_date = today 
LET pr_invoicehead.rev_num = 0 
LET pr_invoicehead.ship_code = pr_subhead.ship_code 
LET pr_invoicehead.name_text = pr_subhead.ship_name_text 
LET pr_invoicehead.addr1_text = pr_subhead.ship_addr1_text 
LET pr_invoicehead.addr2_text = pr_subhead.ship_addr2_text 
LET pr_invoicehead.city_text = pr_subhead.ship_city_text 
LET pr_invoicehead.state_code = pr_subhead.state_code 
LET pr_invoicehead.post_code = pr_subhead.post_code 
LET pr_invoicehead.country_code = pr_subhead.country_code --@db-patch_2020_10_04--
LET pr_invoicehead.ship1_text = pr_subhead.ship1_text 
LET pr_invoicehead.ship2_text = pr_subhead.ship2_text 
LET pr_invoicehead.ship_date = pr_subhead.ship_date 
LET pr_invoicehead.fob_text = pr_subhead.fob_text 
LET pr_invoicehead.prepaid_flag = pr_subhead.prepaid_flag 
LET pr_invoicehead.com1_text = pr_subhead.com1_text 
LET pr_invoicehead.com2_text = pr_subhead.com2_text 
LET pr_invoicehead.cost_ind = pr_subhead.cost_ind 
LET pr_invoicehead.currency_code = pr_subhead.currency_code 
LET pr_invoicehead.conv_qty = pr_subhead.conv_qty 
LET pr_invoicehead.inv_ind = "7" 
LET pr_invoicehead.prev_paid_amt = 0 
LET pr_invoicehead.acct_override_code =pr_subhead.acct_override_code 
LET pr_invoicehead.price_tax_flag = pr_subhead.price_tax_flag 
LET pr_invoicehead.contact_text = pr_subhead.contact_text 
LET pr_invoicehead.tele_text = pr_subhead.tele_text 
LET pr_invoicehead.invoice_to_ind = pr_subhead.invoice_to_ind 
LET pr_invoicehead.territory_code = pr_subhead.territory_code 
LET pr_invoicehead.mgr_code = pr_subhead.mgr_code 
LET pr_invoicehead.area_code = pr_subhead.area_code 
LET pr_invoicehead.cond_code = pr_subhead.cond_code 
LET pr_invoicehead.scheme_amt = pr_subhead.scheme_amt 
LET pr_invoicehead.jour_num = NULL 
LET pr_invoicehead.post_date = NULL 
LET pr_invoicehead.carrier_code = pr_subhead.carrier_code 
LET pr_invoicehead.manifest_num = NULL 
LET pr_invoicehead.stat_date = NULL 
LET pr_invoicehead.country_code = pr_customer.country_code 

LET l_tmp_text = "SELECT * FROM prodstatus ", 
" WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
" AND part_code = ? AND ware_code = ? " 
PREPARE s_prodstatus FROM l_tmp_text 
DECLARE c_prodstatus CURSOR FOR s_prodstatus 
LET l_tmp_text = "SELECT * FROM subcustomer ", 
"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
"AND cust_code= ? ", 
"AND ship_code= ? ", 
"AND sub_type_code = ? ", 
"AND part_code= ? ", 
"AND comm_date= ? ", 
"AND end_date= ? " 
PREPARE s2_subcustomer FROM l_tmp_text 
DECLARE c2_subcustomer CURSOR FOR s2_subcustomer 

	#INSERT invoiceDetl Record
	DECLARE c1_invoicedetl CURSOR FOR
	INSERT INTO invoicedetl VALUES (pr_invoicedetl.*)		

OPEN c1_invoicedetl 
DECLARE c_prodledg CURSOR FOR 
INSERT INTO prodledg VALUES (pr_prodledg.*) 
OPEN c_prodledg 

DECLARE c_subaudit CURSOR FOR 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
OPEN c_subaudit 

LET err_message = "K11 - Next invoice number update" 
LET pr_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,pr_invoicehead.acct_override_code) 

IF pr_invoicehead.inv_num < 0 THEN 
	LET err_message = "K11 - Error Obtaining Next Trans no." 
	LET status = pr_invoicehead.inv_num 
	RETURN status 
END IF 

DECLARE c_t_invoicedetl CURSOR FOR 
SELECT * FROM t_invoicedetl 
FOREACH c_t_invoicedetl INTO pr_invoicedetl.* 
SELECT * INTO pt_subhead.* 
FROM subhead 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_invoicedetl.order_num 
LET pr_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 
LET pr_invoicedetl.cust_code = pr_invoicehead.cust_code 
##################################################
## Adjust product AND create prodledger FOR On demand product
##################################################
SELECT * INTO pr_subproduct.* 
FROM subproduct 
WHERE part_code = pr_invoicedetl.part_code 
AND cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pt_subhead.sub_type_code 
IF pr_subproduct.linetype_ind = "2" THEN 
IF pr_invoicedetl.part_code IS NOT NULL 
AND pr_invoicedetl.ship_qty != 0 THEN 
OPEN c_prodstatus USING pr_invoicedetl.part_code, 
pr_invoicedetl.ware_code 
FETCH c_prodstatus INTO pr_prodstatus.* 
IF pr_prodstatus.stocked_flag = "Y" THEN 
LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
LET pr_invoicedetl.seq_num = pr_prodstatus.seq_num 
IF pr_prodstatus.onhand_qty IS NULL THEN 
LET pr_prodstatus.onhand_qty = 0 
END IF 
LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty 
- pr_invoicedetl.ship_qty 
INITIALIZE pr_prodledg.* TO NULL 
LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_prodledg.part_code = pr_invoicedetl.part_code 
LET pr_prodledg.ware_code = pr_invoicedetl.ware_code 
LET pr_prodledg.tran_date = pr_invoicehead.inv_date 
LET pr_prodledg.seq_num = pr_invoicedetl.seq_num 
LET pr_prodledg.trantype_ind = "S" 
LET pr_prodledg.year_num = pr_invoicehead.year_num 
LET pr_prodledg.period_num = pr_invoicehead.period_num 
LET pr_prodledg.source_text = pr_invoicedetl.cust_code 
LET pr_prodledg.source_num = pr_invoicedetl.inv_num 
LET pr_prodledg.tran_qty = 
0 - pr_invoicedetl.ship_qty + 0 
LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
LET pr_prodledg.cost_amt = pr_invoicedetl.unit_cost_amt 
/ pr_invoicehead.conv_qty 
LET pr_prodledg.sales_amt=pr_invoicedetl.unit_sale_amt 
/ pr_invoicehead.conv_qty 
LET pr_prodledg.hist_flag = "N" 
LET pr_prodledg.post_flag = "N" 
LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_prodledg.entry_date = today 
PUT c_prodledg 
END IF 
UPDATE prodstatus 
SET onhand_qty = pr_prodstatus.onhand_qty, 
reserved_qty = pr_prodstatus.reserved_qty, 
last_sale_date = pr_invoicehead.inv_date, 
seq_num = pr_prodstatus.seq_num 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND part_code = pr_invoicedetl.part_code 
AND ware_code = pr_invoicedetl.ware_code 
END IF 
END IF 
LET pr_invoicedetl.line_acct_code = 
account_patch(glob_rec_kandoouser.cmpy_code,pr_invoicedetl.line_acct_code, 
pr_invoicehead.acct_override_code) 
PUT c1_invoicedetl 
OPEN c2_subcustomer USING pt_subhead.cust_code, 
pt_subhead.ship_code, 
pt_subhead.sub_type_code, 
pr_invoicedetl.part_code, 
pt_subhead.start_date, 
pt_subhead.end_date 
FETCH c2_subcustomer INTO pr_subcustomer.* 
IF status = 0 THEN 
LET pr_subcustomer.next_seq_num=pr_subcustomer.next_seq_num +1 
UPDATE subcustomer 
SET inv_qty = inv_qty + pr_invoicedetl.ship_qty, 
next_seq_num = pr_subcustomer.next_seq_num 
WHERE cmpy_code = pr_invoicedetl.cmpy_code 
AND cust_code = pt_subhead.cust_code 
AND ship_code = pt_subhead.ship_code 
AND sub_type_code = pt_subhead.sub_type_code 
AND part_code = pr_invoicedetl.part_code 
AND comm_date= pt_subhead.start_date 
AND end_date= pt_subhead.end_date 
END IF 
LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_subaudit.part_code = pr_invoicedetl.part_code 
LET pr_subaudit.cust_code = pt_subhead.cust_code 
LET pr_subaudit.ship_code = pt_subhead.ship_code 
LET pr_subaudit.start_date = pt_subhead.start_date 
LET pr_subaudit.end_date = pt_subhead.end_date 
LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
LET pr_subaudit.tran_date = pr_invoicehead.inv_date 
LET pr_subaudit.entry_date = today 
LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_subaudit.tran_qty = pr_invoicedetl.ship_qty 
LET pr_subaudit.unit_amt = pr_invoicedetl.unit_sale_amt 
LET pr_subaudit.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
LET pr_subaudit.currency_code = pr_invoicehead.currency_code 
LET pr_subaudit.conv_qty = pr_invoicehead.conv_qty 
LET pr_subaudit.tran_type_ind = "INV" 
LET pr_subaudit.sub_num = pt_subhead.sub_num 
LET pr_subaudit.source_num = pr_invoicehead.inv_num 
LET pr_subaudit.sub_type_code = pt_subhead.sub_type_code 
LET pr_subaudit.comm_text = "Invoice Entry (sub)" 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
END FOREACH 
LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 
LET pr_invoicehead.total_amt = pr_invoicehead.tax_amt 
+ pr_invoicehead.goods_amt 
+ pr_invoicehead.freight_amt 
+ pr_invoicehead.freight_tax_amt 
+ pr_invoicehead.hand_amt 
+ pr_invoicehead.hand_tax_amt 

#INSERT invoicehead Record
IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,pr_invoicehead.*) THEN
	INSERT INTO invoicehead VALUES (pr_invoicehead.*)			
ELSE
	DISPLAY pr_invoicehead.*
	CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
END IF 

IF pr_mode = "CORP" THEN 
LET pr_csubhead.last_inv_num = pr_invoicehead.inv_num 
LET pr_csubhead.total_amt = pr_invoicehead.total_amt 
END IF 
DECLARE c3_tsubhead CURSOR FOR 
SELECT * FROM t_subhead 
FOREACH c3_tsubhead INTO pr_subhead.* 
UPDATE subhead SET last_inv_num = pr_invoicehead.inv_num 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
END FOREACH 
################################################
## Now TO UPDATE customer
################################################
LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
LET pr_customer.bal_amt = pr_customer.bal_amt 
+ pr_invoicehead.total_amt 
LET err_message = "K21 - Unable TO add TO AR log table " 
INITIALIZE pr_araudit.* TO NULL 
LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_araudit.tran_date = pr_invoicehead.inv_date 
LET pr_araudit.cust_code = pr_invoicehead.cust_code 
LET pr_araudit.seq_num = pr_customer.next_seq_num 
LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
LET pr_araudit.source_num = pr_invoicehead.inv_num 
LET pr_araudit.tran_text = "Enter invoice" 
LET pr_araudit.tran_amt = pr_invoicehead.total_amt 
LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_araudit.sales_code = pr_invoicehead.sale_code 
LET pr_araudit.year_num = pr_invoicehead.year_num 
LET pr_araudit.period_num = pr_invoicehead.period_num 
LET pr_araudit.bal_amt = pr_customer.bal_amt 
LET pr_araudit.currency_code = pr_customer.currency_code 
LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
LET pr_araudit.entry_date = today 
INSERT INTO araudit VALUES (pr_araudit.*) 
LET pr_customer.curr_amt = pr_customer.curr_amt 
+ pr_invoicehead.total_amt 
IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
END IF 
LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
- pr_customer.bal_amt 
IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
LET pr_customer.ytds_amt = 0 
LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.ytds_amt = pr_customer.ytds_amt 
+ pr_invoicehead.total_amt 
IF month(pr_invoicehead.inv_date)>month(pr_customer.last_inv_date) THEN 
LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.mtds_amt = pr_customer.mtds_amt 
+ pr_invoicehead.total_amt 
LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
LET err_message = "K21 - Customer actual UPDATE " 

UPDATE customer 
SET 
	next_seq_num = pr_customer.next_seq_num, 
	bal_amt = pr_customer.bal_amt, 
	curr_amt = pr_customer.curr_amt, 
	highest_bal_amt = pr_customer.highest_bal_amt, 
	cred_bal_amt = pr_customer.cred_bal_amt, 
	last_inv_date = pr_customer.last_inv_date, 
	ytds_amt = pr_customer.ytds_amt, 
	mtds_amt = pr_customer.mtds_amt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_customer.cust_code 
END IF 

#############################################
### Is there a receipt
#############################################
LET pr_cashreceipt.cash_num = 0 
SELECT * INTO pr_cashreceipt.* 
FROM t_cashreceipt 
WHERE cash_amt IS NOT NULL 
IF status = 0 THEN 
SELECT * INTO pr_customertype.* 
FROM customertype 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pr_customer.type_code 
LET err_message = "K11g - Next Transaction Number generater" 
LET pr_cashreceipt.cash_num = 
next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,pr_customertype.acct_mask_code) 
IF pr_cashreceipt.cash_num < 0 THEN 
LET status = pr_cashreceipt.cash_num 
GOTO recovery 
END IF 

LET err_message = "K11g - Cash Receipt insert" 
LET pr_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_cashreceipt.applied_amt = 0 
LET pr_cashreceipt.disc_amt = 0 
LET pr_cashreceipt.on_state_flag = "N" 
LET pr_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
LET pr_cashreceipt.next_num = 0 
LET pr_cashreceipt.banked_flag = "N" 

SELECT unique 1 FROM cashreceipt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cash_num = pr_cashreceipt.cash_num 

IF status = 0 THEN 
LET msgresp=kandoomsg("A",9114,"") #9114 "transaction number exists - allocating new number
LET pr_cashreceipt.cash_num = next_trans_num(
	glob_rec_kandoouser.cmpy_code,
	TRAN_TYPE_RECEIPT_CA,
	pr_customertype.acct_mask_code) 
END IF 

INSERT INTO cashreceipt VALUES (pr_cashreceipt.*) 
LET err_message =" K11g - Customer Table update" 
DECLARE c1_customer CURSOR FOR 
SELECT * FROM customer 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_cashreceipt.cust_code 
FOR UPDATE 

OPEN c1_customer 
FETCH c1_customer INTO pr_customer.* 
LET pr_customer.bal_amt = pr_customer.bal_amt - pr_cashreceipt.cash_amt 
LET pr_customer.curr_amt = pr_customer.curr_amt - pr_cashreceipt.cash_amt 
LET pr_customer.last_pay_date = pr_cashreceipt.cash_date 
LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - pr_customer.bal_amt 
LET pr_customer.ytdp_amt = pr_customer.ytdp_amt + pr_cashreceipt.cash_amt 
LET pr_customer.mtdp_amt = pr_customer.mtdp_amt + pr_cashreceipt.cash_amt 

UPDATE customer 
SET 
	bal_amt = pr_customer.bal_amt, 
	last_pay_date = pr_customer.last_pay_date, 
	curr_amt = pr_customer.curr_amt, 
	next_seq_num = pr_customer.next_seq_num, 
	cred_bal_amt = pr_customer.cred_bal_amt, 
	ytdp_amt = pr_customer.ytdp_amt, 
	mtdp_amt = pr_customer.mtdp_amt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_cashreceipt.cust_code 

LET err_message = "K11g - AR Audit Row insert" 
LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_araudit.tran_date = pr_cashreceipt.cash_date 
LET pr_araudit.cust_code = pr_cashreceipt.cust_code 
LET pr_araudit.seq_num = pr_customer.next_seq_num 
LET pr_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
LET pr_araudit.source_num = pr_cashreceipt.cash_num 
LET pr_araudit.tran_text = "Cash receipt" 
LET pr_araudit.tran_amt = 0 - pr_cashreceipt.cash_amt 
LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_araudit.year_num = pr_cashreceipt.year_num 
LET pr_araudit.period_num = pr_cashreceipt.period_num 
LET pr_araudit.bal_amt = pr_customer.bal_amt 
LET pr_araudit.currency_code = pr_customer.currency_code 
LET pr_araudit.conv_qty = pr_cashreceipt.conv_qty 
LET pr_araudit.entry_date = today 

INSERT INTO araudit VALUES (pr_araudit.*) 
END IF 

COMMIT WORK 

IF pr_invoicehead.inv_num > 0 
AND pr_cashreceipt.cash_num > 0 THEN 
IF NOT auto_apply(pr_cashreceipt.cash_num,pr_invoicehead.inv_num) THEN 

LET msgresp = kandoomsg("K",7002,"") #7002 Receipt Not Applied
END IF 
END IF 

WHENEVER ERROR stop 
LET prg_name = get_baseprogname() 

IF prg_name[1,3] = "KA1" THEN 
RETURN pr_subhead.sub_num 
END IF 

LET msgresp = kandoomsg("K",1,"") 

IF pr_mode = "CORP" THEN 
SELECT count(*) INTO idx 
FROM t_subhead 
WHERE sub_num IS NOT NULL 
LET l_tmp_text = idx USING "<<<"," corporate subs : " 
ELSE 
LET l_tmp_text = "Subscription : ",pr_subhead.sub_num USING "<<<<<<<<<" 
END IF 

IF pr_invoicehead.inv_num > 0 THEN 
LET l_tmp_text = l_tmp_text clipped,", Invoice : ", pr_invoicehead.inv_num USING "<<<<<<<<<" 
END IF 

IF pr_cashreceipt.cash_num > 0 THEN 
LET l_tmp_text = l_tmp_text clipped,", Receipt : ", pr_cashreceipt.cash_num USING "<<<<<<<<<" 
END IF 

LET msgresp = kandoomsg("K",7003,l_tmp_text) #7003 successful generation of
RETURN pr_subhead.sub_num 
END FUNCTION 

REPORT K15_rpt_list(p_rpt_idx,pr_subhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_subhead RECORD LIKE subhead.*, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	pr_company RECORD LIKE company.*, 
	pr_customer RECORD LIKE customer.*, 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 2, "Sub", 
			COLUMN 12, "Customer", 
			COLUMN 25, "Name", 
			COLUMN 83, "Total" 
			PRINT COLUMN 2, "Number", 
			COLUMN 12, "Code", 
			COLUMN 82, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			SELECT * INTO pr_customer.* 
			FROM customer 
			WHERE cust_code = pr_csubhead.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 1, "Bill TO :", 
			COLUMN 15, pr_customer.cust_code, 
			COLUMN 25, pr_customer.name_text, 
			COLUMN 75, "Subscription: ",pr_csubhead.sub_type_code, 
			pr_csubhead.start_date USING "dd/mm/yy"," TO ", 
			pr_csubhead.end_date USING "dd/mm/yy" 
			PRINT COLUMN 25, pr_customer.addr1_text 
			PRINT COLUMN 25, pr_customer.addr2_text 
			PRINT COLUMN 25, pr_customer.city_text clipped," ", 
			pr_customer.state_code clipped," ", 
			pr_customer.post_code 
			SKIP 1 line 

		ON EVERY ROW 
			SELECT * INTO pr_customer.* 
			FROM customer 
			WHERE cust_code = pr_subhead.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 1,pr_subhead.sub_num USING "#########", 
			COLUMN 12,pr_subhead.cust_code , 
			COLUMN 25,pr_customer.name_text clipped, 
			COLUMN 75,pr_subhead.total_amt USING "--,---,--$.&&" 
			PRINT COLUMN 1, "Ship TO :", 
			COLUMN 12, pr_subhead.ship_code, 
			COLUMN 25, pr_subhead.ship_name_text 
			PRINT COLUMN 25, pr_subhead.ship_addr1_text 
			PRINT COLUMN 25, pr_subhead.ship_addr2_text 
			PRINT COLUMN 25, pr_subhead.ship_city_text clipped," ", 
			pr_subhead.state_code clipped," ", 
			pr_subhead.post_code 
			SKIP 1 line 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 75,"-------------" 
			PRINT COLUMN 1,"Invoice Number: ", 
			pr_csubhead.last_inv_num USING "<<<<<<<<<", 
			COLUMN 30, "Date: ",pr_csubhead.sub_date USING "dd/mm/yy", 
			COLUMN 75,pr_csubhead.total_amt USING "--,---,--$.&&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
