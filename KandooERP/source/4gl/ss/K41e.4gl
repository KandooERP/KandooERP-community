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

	Source code beautified by beautify.pl on 2019-12-31 14:28:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 


DEFINE check_tax, chepay_amt, check_mat, total_tax DECIMAL(16,2), 
count2 SMALLINT, 
prefixed_num LIKE credithead.cred_num 

FUNCTION write_cred() 
	DEFINE 
	i SMALLINT, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_new_sub SMALLINT 


	INITIALIZE pr_araudit.* TO NULL 

	LET check_tax = 0 
	LET chepay_amt = 0 
	LET check_mat = 0 


	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		CALL out_stat() 
		EXIT program 
	END IF 
	LABEL bypass: 
	LET noerror = 1 
	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 


		# UPDATE AR paramaters RECORD AND get credit number...

		IF f_type = "C" 
		THEN 
			LET err_message = "K41e - next credit number" 
			LET pr_credithead.cred_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,"") 
		ELSE 

		# a credit edit

		# get the latest appl_amt, disc_amt in CASE changed, FOR UPDATE TO lock
		DECLARE appl_curs CURSOR FOR 
		SELECT appl_amt, disc_amt, rev_num 
		INTO ps_credithead.appl_amt, 
		ps_credithead.disc_amt, 
		ps_credithead.rev_num 
		FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = pr_credithead.cred_num 
		FOR UPDATE 

		OPEN appl_curs 
		FETCH appl_curs 

		# copy across credit static details
		LET pr_credithead.appl_amt = ps_credithead.appl_amt 
		LET pr_credithead.disc_amt = ps_credithead.disc_amt 
		LET pr_credithead.on_state_flag = ps_credithead.on_state_flag 
		LET pr_credithead.posted_flag = ps_credithead.posted_flag 
		LET pr_credithead.rev_date = today 
		IF pr_credithead.rev_num IS NULL THEN 
			LET pr_credithead.rev_num = 0 
		END IF 
		LET pr_credithead.rev_num = pr_credithead.rev_num + 1 
		INITIALIZE pr_araudit.* TO NULL 
		LET err_message = "A47 Customer update" 
		DECLARE cm1_curs CURSOR FOR 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = ps_credithead.cust_code 
		FOR UPDATE 

		FOREACH cm1_curs 
			LET pr_customer.bal_amt = pr_customer.bal_amt + ps_credithead.total_amt 
			LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
			LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_araudit.tran_date = pr_credithead.cred_date 
			LET pr_araudit.cust_code = pr_credithead.cust_code 
			LET pr_araudit.seq_num = pr_customer.next_seq_num 
			LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET pr_araudit.source_num = pr_credithead.cred_num 
			LET pr_araudit.tran_text = "Backout Credit " 
			LET pr_araudit.tran_amt = ps_credithead.total_amt 
			LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_araudit.sales_code = ps_credithead.sale_code 
			LET pr_araudit.year_num = pr_credithead.year_num 
			LET pr_araudit.period_num = pr_credithead.period_num 
			LET pr_araudit.bal_amt = pr_customer.bal_amt 
			LET err_message = "A47 - Daily log insert" 
			INSERT INTO araudit VALUES (pr_araudit.*) 
			LET pr_customer.curr_amt = pr_customer.curr_amt + 
			ps_credithead.total_amt 
			LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - 
			(pr_customer.bal_amt + 
			pr_customer.onorder_amt) 
			LET pr_customer.ytds_amt = pr_customer.ytds_amt + 
			ps_credithead.total_amt 
			LET pr_customer.mtds_amt = pr_customer.mtds_amt + 
			ps_credithead.total_amt 
			LET err_message = "A47 - Customer update" 
			UPDATE customer 
			SET next_seq_num = pr_customer.next_seq_num, 
			bal_amt = pr_customer.bal_amt, 
			curr_amt = pr_customer.curr_amt, 
			highest_bal_amt = pr_customer.highest_bal_amt, 
			cred_bal_amt = pr_customer.cred_bal_amt, 
			ytds_amt = pr_customer.ytds_amt, 
			mtds_amt = pr_customer.mtds_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = ps_credithead.cust_code 
		END FOREACH 
		#  now delete the credit lines
		#
		FOR i = 1 TO ps_credithead.line_num 
			SELECT * INTO pr_creditdetl.* 
			FROM creditdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = ps_credithead.cust_code 
			AND cred_num = ps_credithead.cred_num 
			AND line_num = i 
			IF pr_creditdetl.part_code IS NULL 
			OR pr_creditdetl.ship_qty = 0 THEN 
			ELSE 
			DECLARE ps_curs CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE part_code = pr_creditdetl.part_code 
			AND ware_code = pr_creditdetl.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			FOREACH ps_curs INTO pr_prodstatus.* 
				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				LET pr_creditdetl.seq_num = pr_prodstatus.seq_num 
				IF pr_prodstatus.onhand_qty IS NULL THEN 
					LET pr_prodstatus.onhand_qty = 0 
				END IF 
				# do NOT adjust onhnd VALUES FOR non-stocked inventory items
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty - 
					pr_creditdetl.ship_qty 
					LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty - 
					pr_creditdetl.ship_qty 
				END IF 
				UPDATE prodstatus 
				SET onhand_qty = pr_prodstatus.onhand_qty, 
				reserved_qty = pr_prodstatus.reserved_qty, 
				last_sale_date = pr_credithead.cred_date, 
				seq_num = pr_prodstatus.seq_num 
				WHERE part_code = pr_creditdetl.part_code 
				AND ware_code = pr_creditdetl.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END FOREACH 

			LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodledg.part_code = pr_creditdetl.part_code 
			LET pr_prodledg.ware_code = pr_creditdetl.ware_code 
			LET pr_prodledg.tran_date = pr_credithead.cred_date 
			LET pr_prodledg.seq_num = pr_creditdetl.seq_num 
			LET pr_prodledg.trantype_ind = "C" 
			LET pr_prodledg.year_num = pr_credithead.year_num 
			LET pr_prodledg.period_num = pr_credithead.period_num 
			LET pr_prodledg.source_text = pr_creditdetl.cust_code 
			LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
			LET pr_prodledg.source_num = pr_creditdetl.cred_num 
			LET pr_prodledg.tran_qty = (0 - pr_creditdetl.ship_qty) + 0 
			LET pr_prodledg.cost_amt =conv_currency(pr_creditdetl.unit_cost_amt, 
			glob_rec_kandoouser.cmpy_code, 
			pr_customer.currency_code, 
			"F", 
			pr_credithead.cred_date, 
			"L") 
			LET pr_prodledg.sales_amt = conv_currency( 
			pr_creditdetl.unit_sales_amt, 
			glob_rec_kandoouser.cmpy_code, 
			pr_customer.currency_code, 
			"F", 
			pr_credithead.cred_date,"L") 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET pr_prodledg.hist_flag = "N" 
			ELSE 
			LET pr_prodledg.hist_flag = "Y" 
		END IF 
		LET pr_prodledg.post_flag = "N" 
		LET err_message = "A47 - Itemledg insert" 
		INSERT INTO prodledg VALUES (pr_prodledg.*) 
		# UPDATE subdetl
		DECLARE c_subdetl CURSOR FOR 
		SELECT * INTO pr_subdetl.* 
		FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		AND part_code = pr_creditdetl.part_code 
		AND issue_qty > 0 
		OPEN c_subdetl 
		FETCH c_subdetl 
		IF status = 0 THEN 
			UPDATE subdetl SET return_qty = 
			return_qty - pr_creditdetl.ship_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			AND sub_line_num = pr_subdetl.sub_line_num 
		END IF 
		# UPDATE subcustomer
		DECLARE sub_curs CURSOR FOR 
		SELECT * INTO pr_subcustomer.* 
		FROM subcustomer 
		WHERE cmpy_code = pr_creditdetl.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		AND ship_code = pr_subhead.ship_code 
		AND part_code = pr_creditdetl.part_code 
		AND sub_type_code = pr_subhead.sub_type_code 
		AND comm_date = pr_subhead.start_date 
		AND end_date = pr_subhead.end_date 
		FOR UPDATE 
		FOREACH sub_curs 
			UPDATE subcustomer 
			SET sub_qty = sub_qty + pr_creditdetl.ship_qty, 
			total_amt = total_amt + (pr_creditdetl.ship_qty * 
			(unit_amt + unit_tax_amt)), 
			next_seq_num = next_seq_num + 1 
			WHERE cmpy_code = pr_creditdetl.cmpy_code 
			AND cust_code = pr_subhead.cust_code 
			AND ship_code = pr_subhead.ship_code 
			AND sub_type_code = pr_subhead.sub_type_code 
			AND comm_date = pr_subhead.start_date 
			AND end_date = pr_subhead.end_date 
			AND part_code = pr_creditdetl.part_code 
			EXIT FOREACH 
		END FOREACH 
		# INSERT subaudit
		LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subaudit.part_code = pr_creditdetl.part_code 
		LET pr_subaudit.cust_code = pr_subhead.cust_code 
		LET pr_subaudit.ship_code = pr_subhead.ship_code 
		LET pr_subaudit.start_date = pr_subhead.start_date 
		LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
		LET pr_subaudit.end_date = pr_subhead.end_date 
		LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num + 1 
		LET pr_subaudit.tran_date = pr_credithead.cred_date 
		LET pr_subaudit.entry_date = today 
		LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_subaudit.tran_qty = pr_creditdetl.ship_qty 
		LET pr_subaudit.unit_amt = pr_creditdetl.unit_sales_amt 
		LET pr_subaudit.unit_tax_amt = pr_creditdetl.unit_tax_amt 
		LET pr_subaudit.currency_code = pr_credithead.currency_code 
		LET pr_subaudit.conv_qty = pr_credithead.conv_qty 
		LET pr_subaudit.sub_num = pr_subhead.sub_num 
		LET pr_subaudit.tran_type_ind = "EDT" 
		LET pr_subaudit.source_num = pr_credithead.cred_num 
		LET pr_subaudit.comm_text = "Credit edit" 
		INSERT INTO subaudit VALUES (pr_subaudit.*) 
	END IF 
END FOR 

LET err_message = "A47 - Credline deletion" 
DELETE FROM creditdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = ps_credithead.cust_code 
AND cred_num = ps_credithead.cred_num 
#
# delete out the credithead
#
LET err_message = "A47 - Credhead deletion" 
DELETE FROM credithead 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = ps_credithead.cust_code 
AND cred_num = ps_credithead.cred_num 
END IF 

LET err_message = "K41e - Customer update" 
DECLARE curr_amts CURSOR FOR 
SELECT * INTO pr_customer.* 
FROM customer 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_credithead.cust_code 
FOR UPDATE 
FOREACH curr_amts 
LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
LET pr_customer.bal_amt = pr_customer.bal_amt - pr_credithead.total_amt 
LET pr_customer.curr_amt = pr_customer.curr_amt - pr_credithead.total_amt 
LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_araudit.tran_date = pr_credithead.cred_date 
LET pr_araudit.cust_code = pr_credithead.cust_code 
LET pr_araudit.seq_num = pr_customer.next_seq_num 
LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
LET pr_araudit.source_num = pr_credithead.cred_num 
LET pr_araudit.tran_text = "Enter credit" 
LET pr_araudit.tran_amt = (-1*(pr_credithead.total_amt)) 
LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_araudit.year_num = pr_credithead.year_num 
LET pr_araudit.period_num = pr_credithead.period_num 
LET pr_araudit.bal_amt = pr_customer.bal_amt 
LET err_message = "K41e - Araudit insert" 
INSERT INTO araudit VALUES (pr_araudit.*) 

LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - 
(pr_customer.bal_amt + 
pr_customer.onorder_amt) 
LET pr_customer.ytds_amt = pr_customer.ytds_amt - 
pr_credithead.total_amt 
LET pr_customer.mtds_amt = pr_customer.mtds_amt - 
pr_credithead.total_amt 
LET err_message = "K41e - Customer update" 
UPDATE customer 
SET next_seq_num = pr_customer.next_seq_num, 
bal_amt = pr_customer.bal_amt, 
curr_amt = pr_customer.curr_amt, 
cred_bal_amt = pr_customer.cred_bal_amt, 
ytds_amt = pr_customer.ytds_amt, 
mtds_amt = pr_customer.mtds_amt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_customer.cust_code 
END FOREACH 

#  now add in the credit lines
#

FOR i = 1 TO arr_size 
LET pr_creditdetl.* = st_creditdetl[i].* 
IF pr_creditdetl.ext_tax_amt IS NULL THEN 
	LET pr_creditdetl.ext_tax_amt = 0 
END IF 
IF pr_creditdetl.ext_sales_amt IS NULL THEN 
	LET pr_creditdetl.ext_sales_amt = 0 
END IF 
IF pr_creditdetl.line_total_amt IS NULL THEN 
	LET pr_creditdetl.line_total_amt = 0 
END IF 
LET pr_creditdetl.cred_num = pr_credithead.cred_num 
LET pr_creditdetl.line_num = i 
IF pr_creditdetl.part_code IS NULL 
OR pr_creditdetl.ship_qty = 0 THEN 
ELSE 
DECLARE ps1_curs CURSOR FOR 
SELECT * FROM prodstatus 
WHERE part_code = pr_creditdetl.part_code 
AND ware_code = pr_creditdetl.ware_code 
AND cmpy_code = glob_rec_kandoouser.cmpy_code 
FOR UPDATE 
FOREACH ps1_curs INTO pr_prodstatus.* 
	LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
	LET pr_creditdetl.seq_num = pr_prodstatus.seq_num 
	IF pr_prodstatus.onhand_qty IS NULL THEN 
		LET pr_prodstatus.onhand_qty = 0 
	END IF 
	# do NOT adjust onhnd VALUES FOR non-stocked inventory items
	IF pr_prodstatus.stocked_flag = "Y" THEN 
		LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty + 
		pr_creditdetl.ship_qty 
		LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty + 
		pr_creditdetl.ship_qty 
	END IF 
	UPDATE prodstatus 
	SET onhand_qty = pr_prodstatus.onhand_qty, 
	reserved_qty = pr_prodstatus.reserved_qty, 
	back_qty = pr_prodstatus.back_qty, 
	last_sale_date = pr_credithead.cred_date, 
	seq_num = pr_prodstatus.seq_num 
	WHERE part_code = pr_creditdetl.part_code 
	AND ware_code = pr_creditdetl.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FOREACH 
# patch up the line_acct_code
CALL account_patch(glob_rec_kandoouser.cmpy_code, pr_creditdetl.line_acct_code, patch_code) 
RETURNING pr_creditdetl.line_acct_code 
END IF 
#  now add the line
LET err_message = "K41e - Credline insert" 
IF (pr_creditdetl.part_code IS NULL 
AND pr_creditdetl.line_text IS NULL 
AND (pr_creditdetl.line_total_amt = 0 
OR pr_creditdetl.line_total_amt IS null)) THEN 
ELSE 
INSERT INTO creditdetl VALUES (pr_creditdetl.*) 
END IF 
# now add ledger records

IF pr_creditdetl.part_code IS NULL 
OR pr_creditdetl.part_code = " " 
OR pr_creditdetl.ship_qty = 0 THEN 
ELSE 
INITIALIZE pr_prodledg.* TO NULL 
LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_prodledg.part_code = pr_creditdetl.part_code 
LET pr_prodledg.ware_code = pr_creditdetl.ware_code 
LET pr_prodledg.tran_date = pr_credithead.cred_date 
LET pr_prodledg.seq_num = pr_creditdetl.seq_num 
LET pr_prodledg.trantype_ind = "C" 
LET pr_prodledg.year_num = pr_credithead.year_num 
LET pr_prodledg.period_num = pr_credithead.period_num 
LET pr_prodledg.source_text = pr_creditdetl.cust_code 
LET pr_prodledg.source_num = pr_creditdetl.cred_num 
LET pr_prodledg.tran_qty = pr_creditdetl.ship_qty 
LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
LET pr_prodledg.cost_amt = conv_currency(pr_creditdetl.unit_cost_amt,glob_rec_kandoouser.cmpy_code, pr_customer.currency_code, "F", pr_credithead.cred_date,"L") 
LET pr_prodledg.sales_amt = conv_currency(pr_creditdetl.unit_sales_amt,glob_rec_kandoouser.cmpy_code, pr_customer.currency_code, "F", pr_credithead.cred_date,"L") 
IF pr_inparms.hist_flag = "Y" THEN 
LET pr_prodledg.hist_flag = "N" 
ELSE 
LET pr_prodledg.hist_flag = "Y" 
END IF 
LET pr_prodledg.post_flag = "N" 
LET err_message = "K41e - Itemledg insert" 
INSERT INTO prodledg VALUES (pr_prodledg.*) 
LET pr_new_sub = true 
# UPDATE subdetl
DECLARE c2_subdetl CURSOR FOR 
SELECT * INTO pr_subdetl.* 
FROM subdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND part_code = pr_creditdetl.part_code 
AND issue_qty > 0 
OPEN c2_subdetl 
FETCH c2_subdetl 
IF status = 0 THEN 
UPDATE subdetl SET return_qty = 
return_qty + pr_creditdetl.ship_qty 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND sub_line_num = pr_subdetl.sub_line_num 
### Need TO also include subaudit transactions TO counteract###
### the subs AND the issues FOR this part_code              ###
DECLARE sub0_curs CURSOR FOR 
SELECT * INTO pr_subcustomer.* 
FROM subcustomer 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
FOR UPDATE 
FOREACH sub0_curs 
LET pr_new_sub = false 
UPDATE subcustomer 
SET next_seq_num = next_seq_num + 1 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
EXIT FOREACH 
END FOREACH 
# INSERT subaudit the issue transaction
LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_subaudit.part_code = pr_creditdetl.part_code 
LET pr_subaudit.cust_code = pr_subhead.cust_code 
LET pr_subaudit.ship_code = pr_subhead.ship_code 
LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
LET pr_subaudit.start_date = pr_subhead.start_date 
LET pr_subaudit.end_date = pr_subhead.end_date 
LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num + 1 
LET pr_subaudit.tran_date = pr_credithead.cred_date 
LET pr_subaudit.entry_date = today 
LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_subaudit.tran_qty = pr_creditdetl.ship_qty * -1 
LET pr_subaudit.unit_amt = pr_creditdetl.unit_sales_amt 
LET pr_subaudit.unit_tax_amt = pr_creditdetl.unit_tax_amt 
LET pr_subaudit.currency_code = pr_credithead.currency_code 
LET pr_subaudit.conv_qty = pr_credithead.conv_qty 
LET pr_subaudit.sub_num = pr_subhead.sub_num 
LET pr_subaudit.tran_type_ind = "ISS" 
LET pr_subaudit.source_num = pr_credithead.cred_num 
LET pr_subaudit.comm_text = "Credit iss" 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
END IF 
DECLARE sub1_curs CURSOR FOR 
SELECT * INTO pr_subcustomer.* 
FROM subcustomer 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
FOR UPDATE 
FOREACH sub1_curs 
LET pr_new_sub = false 
UPDATE subcustomer 
SET next_seq_num = next_seq_num + 1 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
EXIT FOREACH 
END FOREACH 
# INSERT subaudit the SUB transaction
LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_subaudit.part_code = pr_creditdetl.part_code 
LET pr_subaudit.cust_code = pr_subhead.cust_code 
LET pr_subaudit.ship_code = pr_subhead.ship_code 
LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
LET pr_subaudit.start_date = pr_subhead.start_date 
LET pr_subaudit.end_date = pr_subhead.end_date 
LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num + 1 
LET pr_subaudit.tran_date = pr_credithead.cred_date 
LET pr_subaudit.entry_date = today 
LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_subaudit.tran_qty = pr_creditdetl.ship_qty * -1 
LET pr_subaudit.unit_amt = pr_creditdetl.unit_sales_amt 
LET pr_subaudit.unit_tax_amt = pr_creditdetl.unit_tax_amt 
LET pr_subaudit.currency_code = pr_credithead.currency_code 
LET pr_subaudit.conv_qty = pr_credithead.conv_qty 
LET pr_subaudit.sub_num = pr_subhead.sub_num 
LET pr_subaudit.tran_type_ind = "SUB" 
LET pr_subaudit.source_num = pr_credithead.cred_num 
LET pr_subaudit.comm_text = "Credit sub" 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
# UPDATE  subcustomer
DECLARE sub2_curs CURSOR FOR 
SELECT * INTO pr_subcustomer.* 
FROM subcustomer 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
FOR UPDATE 
FOREACH sub2_curs 
LET pr_new_sub = false 
UPDATE subcustomer 
SET sub_qty = sub_qty - pr_creditdetl.ship_qty, 
total_amt = total_amt - (pr_creditdetl.ship_qty * 
(unit_amt + unit_tax_amt)), 
next_seq_num = next_seq_num + 1 
WHERE cmpy_code = pr_creditdetl.cmpy_code 
AND cust_code = pr_subhead.cust_code 
AND ship_code = pr_subhead.ship_code 
AND part_code = pr_creditdetl.part_code 
AND sub_type_code = pr_subhead.sub_type_code 
AND comm_date = pr_subhead.start_date 
AND end_date = pr_subhead.end_date 
EXIT FOREACH 
END FOREACH 
IF pr_new_sub THEN # ERROR situation 
ELSE 
# INSERT subaudit
LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_subaudit.part_code = pr_creditdetl.part_code 
LET pr_subaudit.cust_code = pr_subhead.cust_code 
LET pr_subaudit.ship_code = pr_subhead.ship_code 
LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
LET pr_subaudit.start_date = pr_subhead.start_date 
LET pr_subaudit.end_date = pr_subhead.end_date 
LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num + 1 
LET pr_subaudit.tran_date = pr_credithead.cred_date 
LET pr_subaudit.entry_date = today 
LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_subaudit.tran_qty = pr_creditdetl.ship_qty * -1 
LET pr_subaudit.unit_amt = pr_creditdetl.unit_sales_amt 
LET pr_subaudit.unit_tax_amt = pr_creditdetl.unit_tax_amt 
LET pr_subaudit.currency_code = pr_credithead.currency_code 
LET pr_subaudit.conv_qty = pr_credithead.conv_qty 
LET pr_subaudit.sub_num = pr_subhead.sub_num 
LET pr_subaudit.tran_type_ind = "CRD" 
LET pr_subaudit.source_num = pr_credithead.cred_num 
LET pr_subaudit.comm_text = "Credit entry" 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
END IF 
END IF 
# now IF we have serial items THEN get the serial info
SELECT * INTO pr_product.* FROM product 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND part_code = pr_prodledg.part_code 
IF pr_product.serial_flag = "Y" THEN 
CALL serial_ret(glob_rec_kandoouser.cmpy_code, 
pr_product.vend_code, 
pr_prodledg.tran_qty, 
pr_prodledg.part_code, 
pr_prodledg.cost_amt, 
0, 
pr_prodledg.tran_date, 
pr_prodledg.desc_text, 
pr_prodledg.ware_code) 
END IF 
LET check_tax = check_tax + pr_creditdetl.ext_tax_amt 
LET check_mat = check_mat + pr_creditdetl.ext_sales_amt 
LET chepay_amt = chepay_amt + pr_creditdetl.line_total_amt 
END FOR 
IF pr_credithead.freight_amt IS NULL THEN 
LET pr_credithead.freight_amt = 0 
END IF 
IF pr_credithead.hand_amt IS NULL THEN 
LET pr_credithead.hand_amt = 0 
END IF 
LET check_tax = check_tax + ((pr_tax.freight_per 
* pr_credithead.freight_amt)/100) 
+ ((pr_tax.hand_per * pr_credithead.hand_amt)/100) 
IF (check_tax != pr_credithead.tax_amt 
OR check_tax IS NULL 
OR pr_credithead.tax_amt IS null) THEN 
ERROR "Audit on tax figures NOT correct" 
CALL errorlog("K41 - tax total amount incorrect") 
CALL display_error() 
LET noerror = 0 
END IF 
IF check_mat != pr_credithead.goods_amt 
OR check_mat IS NULL 
OR pr_credithead.goods_amt IS NULL THEN 
ERROR "Audit on material figures NOT correct" 
CALL errorlog("A41 - material total amount incorrect") 
CALL display_error() 
LET noerror = 0 
END IF 

LET total_tax = pr_credithead.hand_tax_amt + pr_credithead.freight_tax_amt 
LET chepay_amt = chepay_amt + pr_credithead.hand_amt 
+ pr_credithead.freight_amt 
+ total_tax 
IF chepay_amt != pr_credithead.total_amt 
OR chepay_amt IS NULL 
OR pr_credithead.total_amt IS NULL THEN 
ERROR "Audit on total amount figures NOT correct" 
CALL errorlog("A41 - credit total amount incorrect") 
CALL display_error() 
LET noerror = 0 
END IF 

#
# check that the credit doesnt already exist
#
SELECT count(*) 
INTO count2 
FROM credithead 
WHERE cred_num = pr_credithead.cred_num 
AND cmpy_code = pr_credithead.cmpy_code 
IF count2 > 0 THEN 
ERROR " Credit already exists , use AZP TO correct" 
SLEEP 5 
LET noerror = 0 
END IF 
#
# write out the credithead
#
LET pr_credithead.line_num = arr_size 
LET pr_credithead.cost_ind = pr_arparms.costings_ind 
# no discount worked out on credits - IF paid handled there
LET pr_credithead.disc_amt = 0 
IF f_type = "C" THEN 
LET pr_credithead.appl_amt = 0 
ELSE 
LET pr_credithead.appl_amt = ps_credithead.appl_amt 
END IF 
LET err_message = "K41e - Credhead insert" 
IF noerror != 0 THEN 
INSERT INTO credithead VALUES (pr_credithead.*) 
IF pr_credheadaddr.addr1_text IS NOT NULL 
OR pr_credheadaddr.addr2_text IS NOT NULL 
OR pr_credheadaddr.city_text IS NOT NULL 
OR pr_credheadaddr.state_code IS NOT NULL 
OR pr_credheadaddr.post_code IS NOT NULL THEN 
LET pr_credheadaddr.cred_num = pr_credithead.cred_num 
INSERT INTO credheadaddr VALUES (pr_credheadaddr.*) 
END IF 
END IF 
IF noerror = 0 THEN 
ROLLBACK WORK 
CALL out_stat() 
ELSE 
COMMIT WORK 
END IF 
WHENEVER ERROR stop 
END FUNCTION 


FUNCTION out_stat() 
	DEFINE ro_num INTEGER, 
	which CHAR(3) 

	LET back_out = 1 
	LET ro_num = 0 

	DECLARE statab_curs CURSOR FOR 
	SELECT rowid, statab.* 
	INTO ro_num, pr_statab.* 
	FROM statab 
	WHERE rowid > ro_num 
	ORDER BY 1 

	FOREACH statab_curs 
		IF pr_statab.which = TRAN_TYPE_INVOICE_IN THEN 
			LET which = "OUT" 
		ELSE 
		LET which = TRAN_TYPE_INVOICE_IN 
	END IF 
	DELETE FROM statab WHERE rowid = ro_num 
	LET pr_creditdetl.seq_num = stat_res(pr_statab.cmpy, 
	pr_statab.ware, 
	pr_statab.part, 
	pr_statab.ship, 
	which) 
	OPEN statab_curs 
END FOREACH 
END FUNCTION 


############################################################
# FUNCTION display_error()
#
#
############################################################
FUNCTION display_error() 
	CALL out_stat() 
	DISPLAY "Error occurred" at 2,3 
	DISPLAY "Credit Total ",pr_credithead.total_amt at 3,3 
	DISPLAY "Check Amt ", chepay_amt at 4,3 
	DISPLAY "Credit Tax ",pr_credithead.tax_amt at 5,3 
	DISPLAY "Check Tax ", check_tax at 6,3 
	DISPLAY "Credit Materials ", pr_credithead.goods_amt at 7,3 
	DISPLAY "Check Materials ", check_mat at 8,3 
	DISPLAY "Array size ",arr_size at 9,3 
	FOR i=1 TO arr_size 
		DISPLAY "Product ",st_creditdetl[i].part_code,"Price ",st_creditdetl[i].line_total_amt AT 11,3 
		SLEEP 3 
	END FOR 
	LET noerror = 0 
END FUNCTION 

FUNCTION alloc_cred() 
	DEFINE cnt SMALLINT 

	OPEN WINDOW A203 at 10,12 WITH FORM "A203" 
	attribute (border, white, MESSAGE line first) 
	DISPLAY "Credit number...." at 6,5 
	INPUT prefixed_num FROM inv_num 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD inv_num 
			IF prefixed_num IS NULL THEN 
				ERROR " A credit number must be entered " 
				NEXT FIELD inv_num 
			END IF 
			SELECT count(*) INTO cnt 
			FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = prefixed_num 
			IF cnt > 0 THEN 
				ERROR " Credit number must be unique " 
				NEXT FIELD inv_num 
			END IF 
		AFTER INPUT 
			IF prefixed_num IS NULL THEN 
				ERROR " A credit number must be entered " 
				NEXT FIELD inv_num 
			END IF 
			SELECT count(*) INTO cnt 
			FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = prefixed_num 
			IF cnt > 0 THEN 
				ERROR " Credit number must be unique " 
				NEXT FIELD inv_num 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW A203 
	RETURN(prefixed_num) 
END FUNCTION 

FUNCTION accpt_apply(applied_status) 
	DEFINE 
	applied_status SMALLINT, 
	applied_text CHAR(50), 
	ok_flag CHAR(1) 

	IF applied_status = 0 THEN 
		LET applied_text = " Credit fully applied " 
	END IF 
	IF applied_status = 1 THEN 
		LET applied_text = " Credit partially applied " 
	END IF 
	IF applied_status = 2 THEN 
		LET applied_text = " Unable TO apply credit. Invoice fully paid " 
	END IF 
	LET ok_flag = kandoomsg("K",7,applied_text) 
END FUNCTION 


FUNCTION direct_appl(p_cmpy, pr_credithead) 
	DEFINE 
	pr_credithead RECORD LIKE credithead.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_invoicepay RECORD LIKE invoicepay.*, 
	pr_pay_amt LIKE invoicepay.pay_amt, 
	applied_status SMALLINT, 
	p_cmpy LIKE company.cmpy_code 

	SELECT * INTO pr_invoicehead.* FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = pr_credithead.cust_code 
	AND inv_num = pr_credithead.rma_num 

	LET applied_status = 0 
	IF pr_invoicehead.total_amt = pr_invoicehead.paid_amt THEN 
		LET applied_status = 2 
		CALL accpt_apply(applied_status) 
		RETURN 
	END IF 

	LET pr_pay_amt = pr_credithead.total_amt - pr_credithead.appl_amt 
	IF pr_pay_amt > pr_invoicehead.total_amt - pr_invoicehead.paid_amt THEN 
		LET applied_status = 1 
		LET pr_pay_amt = pr_invoicehead.total_amt - pr_invoicehead.paid_amt 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "A48a - Credhead update" 

		DECLARE mo_curs CURSOR FOR 
		SELECT * INTO pr_credithead.* FROM credithead 
		WHERE cred_num = pr_credithead.cred_num 
		AND cmpy_code = p_cmpy 
		FOR UPDATE 

		FOREACH mo_curs 
			LET pr_credithead.next_num = pr_credithead.next_num + 1 

			IF pr_pay_amt != 0 THEN 
				DECLARE in_curs CURSOR FOR 
				SELECT invoicehead.* INTO pr_invoicehead.* FROM invoicehead 
				WHERE inv_num = pr_credithead.rma_num 
				AND cust_code = pr_credithead.cust_code 
				AND cmpy_code = p_cmpy 
				FOR UPDATE 
				FOREACH in_curs 
					LET pr_invoicehead.paid_amt = pr_invoicehead.paid_amt + pr_pay_amt 
					LET pr_invoicehead.seq_num = pr_invoicehead.seq_num + 1 
					IF pr_invoicehead.total_amt = pr_invoicehead.paid_amt THEN 
						LET pr_invoicehead.paid_date = pr_credithead.cred_date 
					END IF 
					UPDATE invoicehead 
					SET invoicehead.paid_amt = pr_invoicehead.paid_amt, 
					invoicehead.paid_date = pr_invoicehead.paid_date, 
					invoicehead.seq_num = pr_invoicehead.seq_num 
					WHERE inv_num = pr_credithead.rma_num 
					AND cust_code = pr_credithead.cust_code 
					AND cmpy_code = p_cmpy 

					LET pr_invoicepay.apply_num = pr_credithead.next_num 
					LET pr_invoicepay.cmpy_code = p_cmpy 
					LET pr_invoicepay.cust_code = pr_credithead.cust_code 
					LET pr_invoicepay.inv_num = pr_invoicehead.inv_num 
					LET pr_invoicepay.ref_num = pr_credithead.cred_num 
					LET pr_invoicepay.pay_text = pr_credithead.cred_text 
					LET pr_invoicepay.appl_num = pr_invoicehead.seq_num 
					LET pr_invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
					LET pr_invoicepay.pay_date = today 
					LET pr_invoicepay.pay_amt = pr_pay_amt 
					LET pr_invoicepay.disc_amt = 0 
					LET err_message = "A48 - Invpay insert" 
					INSERT INTO invoicepay VALUES (pr_invoicepay.*) 
				END FOREACH 
			END IF 
			LET err_message = "A48 - Credhead update" 
			LET pr_credithead.appl_amt = pr_pay_amt 
			UPDATE credithead 
			SET credithead.* = pr_credithead.* 
			WHERE cred_num = pr_credithead.cred_num 
			AND cmpy_code = p_cmpy 
		END FOREACH 
	COMMIT WORK 
	CALL accpt_apply(applied_status) 
END FUNCTION 
