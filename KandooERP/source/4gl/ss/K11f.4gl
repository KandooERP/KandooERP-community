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

	Source code beautified by beautify.pl on 2019-12-31 14:28:28	$Id: $
}




#  K11f.4gl:FUNCTION auto_apply(pr_cash_num,pr_inv_num)
#           checks receipt AND invoice TO see IF application IS possible
#           IF application can be made THEN calls
#           FUNCTION receipt_apply (A31c.4gl)
#  K11f.4gl:FUNCTION cancel_sub(pr_sub_num)
#           reduces subs TO already issued qty so no further processing will
#           take place. IF sub IS invoiced THEN credit will be created FOR
#           non issued quantity

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 


FUNCTION auto_apply(pr_cash_num,pr_inv_num) 
	DEFINE 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_cash_num,pr_inv_num INTEGER, 
	pr_payable,pr_appable,pr_payamt DECIMAL(16,2) 

	SELECT * INTO pr_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_inv_num 
	IF status = notfound THEN 
		LET err_message = "Auto Apply error - Invoice NOT found" 
		RETURN false 
	END IF 
	SELECT * INTO pr_cashreceipt.* 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_num = pr_cash_num 
	IF status = notfound THEN 
		LET err_message = "Auto Apply error - Receipt NOT found" 
		RETURN false 
	END IF 
	LET pr_payable = pr_invoicehead.total_amt - pr_invoicehead.paid_amt 
	LET pr_appable = pr_cashreceipt.cash_amt - pr_cashreceipt.applied_amt 
	IF pr_payable > 0 
	AND pr_appable > 0 THEN 
		IF pr_payable >= pr_appable THEN 
			LET pr_payamt = pr_appable 
		ELSE 
		LET pr_payamt = pr_payable 
	END IF 
END IF 
IF pr_payamt > 0 THEN 
	IF NOT receipt_apply(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,pr_cash_num, 
	pr_inv_num, 
	pr_payamt, 
	0) THEN 
		RETURN false 
	END IF 
END IF 
RETURN true 
END FUNCTION 


FUNCTION cancel_sub(pr_sub_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_sub_num INTEGER, 
	pr_subhead RECORD LIKE subhead.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_subschedule RECORD LIKE subschedule.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_credheadaddr RECORD LIKE credheadaddr.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	total_cost,total_sale,total_tax DECIMAL(16,2), 
	pr_subproduct RECORD LIKE subproduct.*, 
	idx,invalid_period SMALLINT 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 

	INITIALIZE pr_credithead.* TO NULL 
	SELECT * INTO pr_subhead.* 
	FROM subhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_sub_num 
	##################################
	# INPUT credit info IF required
	##################################
	IF pr_credit THEN 
		LET msgresp = kandoomsg("K",1,"") 
		OPEN WINDOW k138 at 11,20 WITH FORM "K138" 
		attribute(border,white) 
		LET msgresp = kandoomsg("U",1020,"Credit") 
		#1020 Enter details - ESC TO continue
		INITIALIZE pr_credithead.* TO NULL 
		LET pr_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_credithead.cred_date = today 
		LET pr_credithead.hand_amt = 0 
		LET pr_credithead.freight_amt = 0 
		LET pr_credithead.com1_text = pr_subhead.com1_text 
		LET pr_credithead.com2_text = pr_subhead.com2_text 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
		RETURNING pr_credithead.year_num, 
		pr_credithead.period_num 
		INPUT BY NAME pr_credithead.freight_amt, 
		pr_credithead.hand_amt, 
		pr_credithead.cred_date, 
		pr_credithead.year_num, 
		pr_credithead.period_num, 
		pr_credithead.com1_text, 
		pr_credithead.com2_text WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-374 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD freight_amt 
				IF pr_credithead.freight_amt IS NULL THEN 
					LET pr_credithead.freight_amt = 0 
					DISPLAY BY NAME pr_credithead.freight_amt 

				END IF 
			AFTER FIELD hand_amt 
				IF pr_credithead.hand_amt IS NULL THEN 
					LET pr_credithead.hand_amt = 0 
					DISPLAY BY NAME pr_credithead.hand_amt 

				END IF 
			AFTER FIELD cred_date 
				IF pr_credithead.cred_date IS NULL THEN 
					LET pr_credithead.cred_date = today 
					NEXT FIELD cred_date 
				ELSE 
				IF NOT field_touched(year_num) THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
					RETURNING pr_credithead.year_num, 
					pr_credithead.period_num 
					DISPLAY BY NAME pr_credithead.period_num, 
					pr_credithead.year_num 

				END IF 
			END IF 
			AFTER FIELD year_num 
				IF pr_credithead.year_num IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
					RETURNING pr_credithead.year_num, 
					pr_credithead.period_num 
					DISPLAY BY NAME pr_credithead.period_num 

					NEXT FIELD year_num 
				END IF 
			AFTER FIELD period_num 
				IF pr_credithead.period_num IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
					RETURNING pr_credithead.year_num, 
					pr_credithead.period_num 
					DISPLAY BY NAME pr_credithead.period_num 

					NEXT FIELD year_num 
				END IF 
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF pr_credithead.freight_amt IS NULL THEN 
						LET pr_credithead.freight_amt = 0 
					END IF 
					IF pr_credithead.hand_amt IS NULL THEN 
						LET pr_credithead.hand_amt = 0 
					END IF 
					IF pr_credithead.cred_date IS NULL THEN 
						LET pr_credithead.cred_date = today 
					END IF 
					IF pr_credithead.year_num IS NULL THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
						RETURNING pr_credithead.year_num, 
						pr_credithead.period_num 
					END IF 
					IF pr_credithead.period_num IS NULL THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_credithead.cred_date) 
						RETURNING pr_credithead.year_num, 
						pr_credithead.period_num 
					END IF 
					CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_credithead.year_num, 
					pr_credithead.period_num,"AR") 
					RETURNING pr_credithead.year_num, 
					pr_credithead.period_num, 
					invalid_period 
					IF invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW k138 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		LET msgresp = kandoomsg("U",1005,"") 
		#1005 Updating Database - pls. wait
	END IF 
	##################################
	# Begin UPDATE of data
	##################################
	DELETE FROM t_subdetl WHERE 1=1 
	DELETE FROM t_subschedule WHERE 1=1 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		DECLARE c_subhead CURSOR FOR 
		SELECT * FROM subhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_sub_num 
		FOR UPDATE 
		DECLARE c_subdetl CURSOR FOR 
		SELECT * FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_sub_num 
		FOR UPDATE 
		DECLARE c_subschedule CURSOR FOR 
		SELECT * FROM subschedule 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_sub_num 
		FOR UPDATE 
		OPEN c_subhead 
		FETCH c_subhead INTO pr_subhead.* 
		LET pr_subhead.rev_num = pr_subhead.rev_num + 1 
		LET pr_subhead.status_ind = "C" 
		LET pr_subhead.rev_date = today 
		FOREACH c_subdetl INTO pr_subdetl.* 
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
			LET pr_subaudit.tran_qty = 0 - (pr_subdetl.sub_qty - 
			pr_subdetl.issue_qty) + 0 
			LET pr_subaudit.unit_amt = pr_subdetl.unit_amt 
			LET pr_subaudit.unit_tax_amt = pr_subdetl.unit_tax_amt 
			LET pr_subaudit.currency_code = pr_subhead.currency_code 
			LET pr_subaudit.conv_qty = pr_subhead.conv_qty 
			LET pr_subaudit.tran_type_ind = "SUB" 
			LET pr_subaudit.sub_num = pr_subhead.sub_num 
			LET pr_subaudit.source_num = pr_subhead.sub_num 
			LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
			LET pr_subaudit.comm_text = "Subscription Cancel " 
			INSERT INTO subaudit VALUES (pr_subaudit.*) 
			IF pr_subdetl.inv_qty > pr_subdetl.issue_qty THEN 
				INSERT INTO t_subdetl VALUES (pr_subdetl.*) 
				LET pr_subdetl.inv_qty = pr_subdetl.issue_qty 
			END IF 
			LET pr_subdetl.sub_qty = pr_subdetl.issue_qty 
			LET pr_subdetl.line_total_amt = pr_subdetl.sub_qty * 
			(pr_subdetl.unit_amt + 
			pr_subdetl.unit_tax_amt) 
			LET pr_subdetl.status_ind = "4" 
			UPDATE subdetl SET sub_qty = pr_subdetl.sub_qty, 
			inv_qty = pr_subdetl.inv_qty, 
			line_total_amt = pr_subdetl.line_total_amt, 
			status_ind = pr_subdetl.status_ind 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			AND sub_line_num = pr_subdetl.sub_line_num 
			FOREACH c_subschedule INTO pr_subschedule.* 
				IF pr_subschedule.inv_qty > pr_subschedule.issue_qty THEN 
					INSERT INTO t_subschedule VALUES (pr_subschedule.*) 
					LET pr_subschedule.inv_qty = pr_subschedule.issue_qty 
				END IF 
				UPDATE subschedule SET sched_qty = pr_subschedule.issue_qty, 
				inv_qty = pr_subschedule.inv_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
				AND issue_num = pr_subschedule.issue_num 
			END FOREACH 
		END FOREACH 
		SELECT sum(unit_amt * sub_qty), 
		sum(unit_tax_amt * sub_qty), 
		sum(line_total_amt) 
		INTO pr_subhead.goods_amt, 
		pr_subhead.tax_amt, 
		pr_subhead.total_amt 
		FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
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
		LET pr_subhead.hand_tax_amt = 0 
		LET pr_subhead.freight_tax_amt = 0 
		LET pr_subhead.total_amt = pr_subhead.goods_amt 
		+ pr_subhead.tax_amt 
		+ pr_subhead.hand_amt 
		+ pr_subhead.hand_tax_amt 
		+ pr_subhead.freight_amt 
		+ pr_subhead.freight_tax_amt 
		UPDATE subhead SET * = pr_subhead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 

		########################################################
		# Check TO see IF credit needs TO be raised FOR invoiced
		# but NOT issued amounts
		########################################################
		SELECT unique 1 FROM t_subdetl 
		WHERE inv_qty > issue_qty 
		IF status = 0 THEN 
			IF pr_subhead.corp_flag = "Y" THEN 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.corp_cust_code 
			ELSE 
			SELECT * INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_subhead.cust_code 
		END IF 
		LET err_message = "K41e - next credit number" 
		LET pr_credithead.cred_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,"") 
		IF pr_credithead.cred_num < 0 THEN 
			LET status = pr_credithead.cred_num 
			GOTO recovery 
		END IF 
		IF pr_customer.corp_cust_code IS NOT NULL 
		AND pr_customer.corp_cust_ind = "1" THEN 
			LET pr_credithead.cust_code = pr_customer.corp_cust_code 
			LET pr_credithead.org_cust_code = pr_customer.cust_code 
		ELSE 
		LET pr_credithead.cust_code = pr_customer.cust_code 
		LET pr_credithead.org_cust_code = pr_customer.cust_code 
	END IF 
	DECLARE c_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_credithead.cust_code 
	FOR UPDATE 
	OPEN c_customer 
	FETCH c_customer INTO pr_customer.* 
	LET pr_credithead.ref_num = pr_subhead.sub_num 
	LET pr_credithead.entry_code = pr_subhead.entry_code 
	LET pr_credithead.entry_date = pr_subhead.entry_date 
	LET pr_credithead.sale_code = pr_subhead.sales_code 
	LET pr_credithead.tax_code = pr_subhead.tax_code 
	LET pr_credheadaddr.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_credheadaddr.cred_num = pr_credithead.cred_num 
	LET pr_credheadaddr.addr1_text = pr_subhead.ship_addr1_text 
	LET pr_credheadaddr.addr2_text = pr_subhead.ship_addr2_text 
	LET pr_credheadaddr.city_text = pr_subhead.ship_city_text 
	LET pr_credheadaddr.state_code = pr_subhead.state_code 
	LET pr_credheadaddr.post_code = pr_subhead.post_code 
	SELECT tax_per INTO pr_credithead.tax_per FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_credithead.tax_code 
	LET pr_credithead.on_state_flag = "N" 
	LET pr_credithead.posted_flag = "N" 
	LET pr_credithead.next_num = 0 
	LET pr_credithead.printed_num = 0 
	LET pr_credithead.rev_date = today 
	LET pr_credithead.rev_num = 0 
	LET pr_credithead.cred_text = pr_subhead.ship_code 
	LET pr_credithead.cost_ind = pr_subhead.cost_ind 
	LET pr_credithead.currency_code = pr_subhead.currency_code 
	LET pr_credithead.conv_qty = pr_subhead.conv_qty 
	LET pr_credithead.cred_ind = "7" 
	LET pr_credithead.acct_override_code =pr_subhead.acct_override_code 
	LET pr_credithead.price_tax_flag = pr_subhead.price_tax_flag 
	LET pr_credithead.address_to_ind = pr_subhead.invoice_to_ind 
	LET pr_credithead.territory_code = pr_subhead.territory_code 
	LET pr_credithead.mgr_code = pr_subhead.mgr_code 
	LET pr_credithead.area_code = pr_subhead.area_code 
	LET pr_credithead.cond_code = pr_subhead.cond_code 
	LET pr_credithead.jour_num = NULL 
	LET pr_credithead.post_date = NULL 
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
	DECLARE c_t_subdetl CURSOR FOR 
	SELECT * FROM t_subdetl 
	LET total_cost = 0 
	LET total_sale = 0 
	LET total_tax = 0 
	LET idx = 0 
	FOREACH c_t_subdetl INTO pr_subdetl.* 
		SELECT * INTO pr_subproduct.* 
		FROM subproduct 
		WHERE part_code = pr_subdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_subhead.sub_type_code 
		LET idx = idx + 1 
		INITIALIZE pr_creditdetl.* TO NULL 
		LET pr_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_creditdetl.cred_num = pr_credithead.cred_num 
		LET pr_creditdetl.cust_code = pr_credithead.cust_code 
		LET pr_creditdetl.line_num = idx 
		LET pr_creditdetl.part_code = pr_subdetl.part_code 
		LET pr_creditdetl.ware_code = pr_subdetl.ware_code 
		LET pr_creditdetl.line_text = pr_subdetl.line_text 
		LET pr_creditdetl.ship_qty = pr_subdetl.inv_qty - pr_subdetl.issue_qty 
		LET pr_creditdetl.unit_sales_amt = pr_subdetl.unit_amt 
		LET pr_creditdetl.unit_tax_amt = pr_subdetl.unit_tax_amt 
		LET pr_creditdetl.ext_sales_amt = pr_subdetl.unit_amt * 
		pr_creditdetl.ship_qty 
		LET pr_creditdetl.ext_tax_amt = pr_subdetl.unit_tax_amt * 
		pr_creditdetl.ship_qty 
		LET pr_creditdetl.line_total_amt= 
		pr_creditdetl.ext_sales_amt + 
		pr_creditdetl.ext_tax_amt 
		SELECT * INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_creditdetl.part_code 
		LET pr_creditdetl.cat_code = pr_product.cat_code 
		IF pr_creditdetl.line_text IS NULL THEN 
			LET pr_creditdetl.line_text = pr_product.desc_text 
		END IF 
		LET pr_creditdetl.uom_code = pr_product.sell_uom_code 
		LET pr_creditdetl.prodgrp_code = pr_product.prodgrp_code 
		LET pr_creditdetl.maingrp_code = pr_product.maingrp_code 
		IF pr_subproduct.linetype_ind = "1" THEN 
			SELECT subacct_code INTO pr_creditdetl.line_acct_code 
			FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subhead.sub_type_code 
			AND subacct_code IS NOT NULL 
			IF status = notfound THEN 
				SELECT sub_acct_code INTO pr_creditdetl.line_acct_code 
				FROM ssparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
		ELSE 
		SELECT sale_acct_code INTO pr_creditdetl.line_acct_code 
		FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cat_code = pr_creditdetl.cat_code 
	END IF 
	SELECT * INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_creditdetl.ware_code 
	AND part_code = pr_creditdetl.part_code 
	LET pr_creditdetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
	* pr_subhead.conv_qty 
	LET pr_creditdetl.ext_cost_amt = 
	pr_creditdetl.unit_cost_amt * 
	pr_creditdetl.ship_qty 
	LET pr_creditdetl.disc_amt = 0 
	LET total_cost = total_cost + pr_creditdetl.ext_cost_amt 
	LET total_sale = total_sale + pr_creditdetl.ext_sales_amt 
	LET total_tax = total_tax + pr_creditdetl.ext_tax_amt 
	IF pr_creditdetl.ship_qty > 0 THEN 
		INSERT INTO creditdetl VALUES (pr_creditdetl.*) 
	END IF 
	OPEN c2_subcustomer USING pr_subhead.cust_code, 
	pr_credithead.cred_text, 
	pr_subhead.sub_type_code, 
	pr_creditdetl.part_code, 
	pr_subhead.start_date, 
	pr_subhead.end_date 
	FETCH c2_subcustomer INTO pr_subcustomer.* 
	IF status = 0 THEN 
		LET pr_subcustomer.next_seq_num=pr_subcustomer.next_seq_num +1 
		UPDATE subcustomer 
		SET inv_qty = inv_qty - pr_creditdetl.ship_qty, 
		next_seq_num = pr_subcustomer.next_seq_num 
		WHERE cmpy_code = pr_creditdetl.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		AND ship_code = pr_credithead.cred_text 
		AND sub_type_code = pr_subhead.sub_type_code 
		AND part_code = pr_creditdetl.part_code 
		AND comm_date= pr_subhead.start_date 
		AND end_date= pr_subhead.end_date 
	END IF 
	LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_subaudit.part_code = pr_creditdetl.part_code 
	LET pr_subaudit.cust_code = pr_subhead.cust_code 
	LET pr_subaudit.ship_code = pr_credithead.cred_text 
	LET pr_subaudit.start_date = pr_subhead.start_date 
	LET pr_subaudit.end_date = pr_subhead.end_date 
	LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
	LET pr_subaudit.tran_date = pr_credithead.cred_date 
	LET pr_subaudit.entry_date = today 
	LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_subaudit.tran_qty = 0 - pr_creditdetl.ship_qty + 0 
	LET pr_subaudit.unit_amt = pr_creditdetl.unit_sales_amt 
	LET pr_subaudit.unit_tax_amt = pr_creditdetl.unit_tax_amt 
	LET pr_subaudit.currency_code = pr_credithead.currency_code 
	LET pr_subaudit.conv_qty = pr_credithead.conv_qty 
	LET pr_subaudit.sub_num = pr_subhead.sub_num 
	LET pr_subaudit.tran_type_ind = "CRD" 
	LET pr_subaudit.source_num = pr_credithead.cred_num 
	LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
	LET pr_subaudit.comm_text = "Cancel Sub (crd)" 
	INSERT INTO subaudit VALUES (pr_subaudit.*) 
END FOREACH 
LET pr_credithead.line_num = idx 
LET pr_credithead.goods_amt = total_sale 
LET pr_credithead.hand_tax_amt = 0 
LET pr_credithead.hand_tax_code = pr_subhead.freight_tax_code 
LET pr_credithead.freight_tax_code = pr_subhead.freight_tax_code 
LET pr_credithead.freight_tax_amt = 0 
LET pr_credithead.tax_amt = total_tax 
LET pr_credithead.disc_amt= 0 
LET pr_credithead.total_amt = pr_credithead.goods_amt 
+ pr_credithead.tax_amt 
+ pr_credithead.hand_amt 
+ pr_credithead.hand_tax_amt 
+ pr_credithead.freight_amt 
+ pr_credithead.freight_tax_amt 
LET pr_credithead.cost_amt = total_cost 
LET pr_credithead.appl_amt = 0 
INSERT INTO credithead VALUES (pr_credithead.*) 
IF pr_credheadaddr.addr1_text IS NOT NULL 
OR pr_credheadaddr.addr2_text IS NOT NULL 
OR pr_credheadaddr.city_text IS NOT NULL 
OR pr_credheadaddr.state_code IS NOT NULL 
OR pr_credheadaddr.post_code IS NOT NULL THEN 
	INSERT INTO credheadaddr VALUES (pr_credheadaddr.*) 
END IF 
################################################
## Now TO UPDATE customer
################################################
LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
LET pr_customer.bal_amt = pr_customer.bal_amt 
- pr_credithead.total_amt 
LET err_message = "K21 - Unable TO add TO AR log table " 
INITIALIZE pr_araudit.* TO NULL 
LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_araudit.tran_date = pr_credithead.cred_date 
LET pr_araudit.cust_code = pr_credithead.cust_code 
LET pr_araudit.seq_num = pr_customer.next_seq_num 
LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
LET pr_araudit.source_num = pr_credithead.cred_num 
LET pr_araudit.tran_text = "Enter Credit (sub)" 
LET pr_araudit.tran_amt = 0 - pr_credithead.total_amt + 0 
LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_araudit.sales_code = pr_credithead.sale_code 
LET pr_araudit.year_num = pr_credithead.year_num 
LET pr_araudit.period_num = pr_credithead.period_num 
LET pr_araudit.bal_amt = pr_customer.bal_amt 
LET pr_araudit.currency_code = pr_customer.currency_code 
LET pr_araudit.conv_qty = pr_credithead.conv_qty 
LET pr_araudit.entry_date = today 
INSERT INTO araudit VALUES (pr_araudit.*) 
LET pr_customer.curr_amt = pr_customer.curr_amt 
- pr_credithead.total_amt 
IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
	LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
END IF 
LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
- pr_customer.bal_amt 
IF year(pr_credithead.cred_date) > year(pr_customer.last_inv_date) THEN 
	LET pr_customer.ytds_amt = 0 
	LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.ytds_amt = pr_customer.ytds_amt 
- pr_credithead.total_amt 
IF month(pr_credithead.cred_date)>month(pr_customer.last_inv_date) THEN 
	LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.mtds_amt = pr_customer.mtds_amt 
- pr_credithead.total_amt 
LET err_message = "K21 - Customer actual UPDATE " 
UPDATE customer 
SET next_seq_num = pr_customer.next_seq_num, 
bal_amt = pr_customer.bal_amt, 
curr_amt = pr_customer.curr_amt, 
highest_bal_amt = pr_customer.highest_bal_amt, 
cred_bal_amt = pr_customer.cred_bal_amt, 
ytds_amt = pr_customer.ytds_amt, 
mtds_amt = pr_customer.mtds_amt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_customer.cust_code 
LET l_tmp_text = "Credit : ",pr_credithead.cred_num 
LET msgresp = kandoomsg("K",7003,l_tmp_text) 
#7003 successful generation of
END IF 
COMMIT WORK 
WHENEVER ERROR stop 
RETURN true 
END FUNCTION 
