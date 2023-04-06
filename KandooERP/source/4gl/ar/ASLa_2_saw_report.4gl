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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASL_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_progress RECORD 
	tran_cnt INTEGER, 
	tran_num INTEGER, 
	inv_cnt INTEGER, 
	cred_cnt INTEGER, 
	err_cnt INTEGER 
END RECORD 
####################################################################
# FUNCTION ASL_sawtrack_load()
#
# Sawtrack Invoice Load
####################################################################
FUNCTION ASL_sawtrack_load() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 	
	
	CALL create_table("invoicedetl","t_invoicedetl","","l_y") 
	CREATE temp TABLE t_sawtrack ( 
	cust_code CHAR(8), ## customer code 
	doc_num CHAR(8), ## st inv. no. 
	doc_date CHAR(10), ## inv. DATE 
	disc_amt DECIMAL(16,4), ## sett. disc. 
	disc_date CHAR(10), ## sett. disc. DATE 
	name_text CHAR(30), ## cust. NAME 
	addr1_text CHAR(30), ## del. addr. 1 
	addr2_text CHAR(30), ## del. addr. 2 
	addr3_text CHAR(30), ## del. addr. 3 
	instn1_text CHAR(60), ## spec. instr. 1 
	instn2_text CHAR(60), ## spec. instr. 2 
	ref_text CHAR(10), ## cust. ref. FIELD 
	ord_num CHAR(10), ## cust. ord. no. 
	pack_text CHAR(10), ## pack ref. OF timber 
	part_code CHAR(15), ## product code 
	ware_code CHAR(3), ## sale location 
	ship_qty FLOAT, ## lineal metres 
	length_text CHAR(200), ## line desc. ( pack spec. ) 
	line_text CHAR(30), ## line desc. ( FOR sundry items ) 
	uom_code CHAR(3), ## uom 
	disc_per FLOAT, ## disc. FROM normal listed price 
	ext_sale_amt DECIMAL(16,4)) ## extended line price 
	##
	## Load data INTO Sawtrack table prior TO index create.
	##
	WHENEVER ERROR CONTINUE 
	LOAD FROM glob_load_file INSERT INTO t_sawtrack 
	IF sqlca.sqlcode != 0 THEN 
		RETURN status 
	END IF 
	CREATE INDEX t_sawtrack_key ON t_sawtrack(doc_num); 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	##
	LET modu_rec_progress.tran_cnt = 0 
	LET modu_rec_progress.inv_cnt = 0 
	LET modu_rec_progress.cred_cnt = 0 
	LET modu_rec_progress.err_cnt = 0 
	SELECT count(unique doc_num) INTO modu_rec_progress.tran_num 
	FROM t_sawtrack 
	##
	##
	IF glob_verbose_indv THEN 
		OPEN WINDOW A633 with FORM "A633" 
		CALL windecoration_a("A633") 

		DISPLAY BY NAME modu_rec_progress.* 

		LET l_msgresp=kandoomsg("U",1005,"") 
		CALL start_load() 
		DISPLAY BY NAME modu_rec_progress.* 

		SLEEP 3 
		CLOSE WINDOW A633 
	ELSE 
		CALL start_load() 
	END IF 

	IF fgl_find_table("t_sawtrack") THEN
		DROP TABLE t_sawtrack 
	END IF

	IF fgl_find_table("t_invoicedetl") THEN
		DROP TABLE t_invoicedetl 
	END IF
			
	##
	## RETURN count of successfully generated transactions
	##
	LET glob_err_cnt = modu_rec_progress.err_cnt 
	IF modu_rec_progress.inv_cnt + modu_rec_progress.cred_cnt = 0 THEN 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_2_saw(rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw"),
		"","","","",0)  
		#--------------------------------------------------------- 
			
	END IF 
	RETURN (modu_rec_progress.inv_cnt+modu_rec_progress.cred_cnt) 
END FUNCTION 


####################################################################
# FUNCTION start_load()
#
#
####################################################################
FUNCTION start_load() 
	--DEFINE l_rec_tran_num RECORD LIKE invoicehead.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicedetl.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_x_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_stattrig RECORD LIKE stattrig.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_sawtrack RECORD 
		cust_code CHAR(8), ## customer code 
		doc_num CHAR(8), ## st inv. no. 
		doc_date CHAR(10), ## inv. DATE 
		disc_amt DECIMAL(16,4), ## sett. disc. 
		disc_date CHAR(10), ## sett. disc. DATE 
		name_text CHAR(30), ## cust. NAME 
		addr1_text CHAR(30), ## del. addr. 1 
		addr2_text CHAR(30), ## del. addr. 2 
		addr3_text CHAR(30), ## del. addr. 3 
		instn1_text CHAR(60), ## spec. instr. 1 
		instn2_text CHAR(60), ## spec. instr. 2 
		ref_text CHAR(10), ## cust. ref. FIELD 
		ord_num CHAR(10), ## cust. ord. no. 
		pack_text CHAR(10), ## pack ref. OF timber 
		part_code CHAR(15), ## product code 
		loc_code CHAR(3), ## sale location 
		line_qty FLOAT, ## lineal metres 
		length_text CHAR(200), ## line desc. ( pack spec. ) 
		line_text CHAR(30), ## line desc. ( FOR sundry items ) 
		uom_code CHAR(3), ## uom 
		disc_per FLOAT, ## disc. FROM normal listed price 
		ext_sales_amt DECIMAL(16,2) ## extended selling price. 
	END RECORD 
	DEFINE l_doc_num CHAR(8) 
	DEFINE l_pack_text CHAR(300) 
	DEFINE l_x SMALLINT 
	DEFINE l_y SMALLINT 
	DEFINE l_mode CHAR(4) 
	DEFINE l_query_text CHAR(500) 

	##
	## Declare CURSOR's dynamically FOR efficiency purposes
	##
	## 1. SELECT each sawtrack line item
	##
	LET l_query_text = "SELECT * FROM t_sawtrack WHERE doc_num = ?" 
	PREPARE s2_sawtrack FROM l_query_text 
	DECLARE c2_sawtrack CURSOR with HOLD FOR s2_sawtrack 
	##
	## 2. SELECT customer
	##
	LET l_query_text = " SELECT * FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND delete_flag = 'N'" 
	PREPARE s1_customer FROM l_query_text 
	DECLARE c1_customer CURSOR FOR s1_customer 
	##
	## 3. SELECT Warehouse
	##
	LET l_query_text = "SELECT * FROM warehouse ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' AND ware_code = ?" 
	PREPARE s1_warehouse FROM l_query_text 
	DECLARE c1_warehouse CURSOR with HOLD FOR s1_warehouse 
	##
	## 4. SELECT Warehouse based on Sawtrack Sales Location
	##
	LET l_query_text = "SELECT * FROM warehouse ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' AND cart_area_code=?" 
	PREPARE s2_warehouse FROM l_query_text 
	DECLARE c2_warehouse CURSOR with HOLD FOR s2_warehouse 
	##
	## 5. SELECT prodstatus FOR UPDATE
	##
	LET l_query_text = "SELECT * FROM prodstatus ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND part_code=? AND ware_code=? ", 
	"FOR UPDATE" 
	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
	##
	## 6. SELECT each temporary invoice line item.
	##
	DECLARE c_t_invoice CURSOR FOR 
	SELECT * FROM t_invoicedetl ORDER BY line_num 
	##
	## 7a. Checks TO ensure invoice NOT previously loaded.
	##
	LET l_query_text = "SELECT 1 FROM invoicehead ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code=? AND purchase_code=? " 
	PREPARE s1_checkdupl FROM l_query_text 
	DECLARE c1_checkdupl CURSOR FOR s1_checkdupl 
	##
	LET l_query_text = "SELECT 1 FROM credithead ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code=? AND cred_text=? " 
	PREPARE s2_checkdupl FROM l_query_text 
	DECLARE c2_checkdupl CURSOR FOR s2_checkdupl 
	##
	## 8. SELECT each unique Sawtrack document.
	##
	DECLARE c1_sawtrack CURSOR with HOLD FOR 
	SELECT doc_num FROM t_sawtrack GROUP BY 1 ORDER BY 1 
	##
	WHENEVER ERROR GOTO exception 
	LET glob_err_message = "Loadfile error: Data IS in invalid FORMAT" 
	FOREACH c1_sawtrack INTO l_doc_num 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		##
		LET modu_rec_progress.tran_cnt = modu_rec_progress.tran_cnt + 1 
		IF glob_verbose_indv THEN 
			DISPLAY BY NAME modu_rec_progress.* 

		END IF 
		DELETE FROM t_invoicedetl 
		##
		## Setup invoicehead RECORD using header fields FROM 1st line item
		##
		OPEN c2_sawtrack USING l_doc_num 
		FETCH c2_sawtrack INTO l_rec_sawtrack.* 
		CLOSE c2_sawtrack 
		##
		INITIALIZE glob_rec_invoicehead.* TO NULL 
		LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		##
		## Validate customer
		##
		LET l_rec_sawtrack.cust_code = upshift(l_rec_sawtrack.cust_code) 
		OPEN c1_customer USING l_rec_sawtrack.cust_code 
		FETCH c1_customer INTO l_rec_customer.* 
		IF status = NOTFOUND THEN 
			LET glob_err_message = "Customer RECORD does NOT exist in database" 
			GOTO exception 
		END IF 
		CLOSE c1_customer 
		LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
		LET glob_rec_invoicehead.org_cust_code = l_rec_customer.corp_cust_code 
		IF l_rec_customer.corp_cust_code IS NOT NULL THEN 
			OPEN c1_customer USING l_rec_customer.corp_cust_code 
			FETCH c1_customer 
			IF sqlca.sqlcode = 0 THEN 
				LET glob_rec_invoicehead.org_cust_code=l_rec_customer.cust_code 
				LET glob_rec_invoicehead.cust_code =l_rec_customer.corp_cust_code 
			END IF 
		END IF 
		LET l_rec_sawtrack.loc_code = upshift(l_rec_sawtrack.loc_code) 
		OPEN c2_warehouse USING l_rec_sawtrack.loc_code 
		FETCH c2_warehouse INTO l_rec_warehouse.* 
		IF status = NOTFOUND THEN 
			OPEN c1_warehouse USING l_rec_sawtrack.loc_code 
			FETCH c1_warehouse INTO l_rec_warehouse.* 
			IF status = NOTFOUND THEN 
				LET glob_err_message = "Location ",l_rec_sawtrack.loc_code," invalid " 
				GOTO exception 
			END IF 
		END IF 
		LET glob_rec_invoicehead.acct_override_code = 
		setup_ar_override(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,TRAN_TYPE_INVOICE_IN,l_rec_customer.cust_code, 
		l_rec_warehouse.ware_code,"N") 
		LET glob_rec_invoicehead.ord_num = NULL 
		LET glob_rec_invoicehead.purchase_code = 'ST',l_rec_sawtrack.doc_num 
		LET glob_rec_invoicehead.job_code = NULL 
		LET glob_rec_invoicehead.inv_date = l_rec_sawtrack.doc_date 
		IF glob_rec_invoicehead.inv_date IS NULL THEN 
			LET glob_rec_invoicehead.inv_date = today 
		END IF 
		LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_invoicehead.entry_date = today 
		LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
		LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicehead.tax_per = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.goods_amt= 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = l_rec_sawtrack.disc_amt 
		LET glob_rec_invoicehead.paid_amt = 0 
		LET glob_rec_invoicehead.paid_date = NULL 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		LET glob_rec_invoicehead.disc_date = l_rec_sawtrack.disc_date 
		IF glob_rec_invoicehead.disc_date IS NULL THEN 
			LET glob_rec_invoicehead.disc_date = glob_rec_invoicehead.inv_date 
		END IF 
		LET glob_rec_invoicehead.expected_date = NULL 
		LET glob_rec_invoicehead.on_state_flag = 'N' 
		LET glob_rec_invoicehead.posted_flag = 'N' 
		LET glob_rec_invoicehead.seq_num = 0 
		LET glob_rec_invoicehead.line_num = 0 
		LET glob_rec_invoicehead.printed_num = 0 
		LET glob_rec_invoicehead.story_flag = 'N' 
		LET glob_rec_invoicehead.rev_date = glob_rec_invoicehead.inv_date 
		LET glob_rec_invoicehead.rev_num = 0 
		LET glob_rec_invoicehead.ship_code = NULL 
		LET glob_rec_invoicehead.name_text = l_rec_sawtrack.name_text 
		LET glob_rec_invoicehead.addr1_text = l_rec_sawtrack.addr1_text 
		LET glob_rec_invoicehead.addr2_text = l_rec_sawtrack.addr2_text 
		LET glob_rec_invoicehead.city_text = l_rec_sawtrack.addr3_text 
		LET glob_rec_invoicehead.state_code = l_rec_customer.state_code 
		LET glob_rec_invoicehead.post_code = NULL 
--@db-patch_2020_10_04--		LET glob_rec_invoicehead.country_text = l_rec_customer.country_text 
		LET glob_rec_invoicehead.country_code = l_rec_customer.country_code 
		LET glob_rec_invoicehead.ship1_text = l_rec_sawtrack.instn1_text 
		LET glob_rec_invoicehead.ship2_text = l_rec_sawtrack.instn2_text 
		LET glob_rec_invoicehead.ship_date = glob_rec_invoicehead.inv_date 
		LET glob_rec_invoicehead.fob_text = NULL 
		LET glob_rec_invoicehead.prepaid_flag = NULL 
		LET glob_rec_invoicehead.com1_text = l_rec_sawtrack.ref_text 
		LET glob_rec_invoicehead.com2_text = l_rec_sawtrack.ord_num 
		LET glob_rec_invoicehead.cost_ind = NULL 
		LET glob_rec_invoicehead.currency_code = l_rec_customer.currency_code 
		LET glob_rec_invoicehead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_invoicehead.currency_code , 
			glob_rec_invoicehead.inv_date, 
			CASH_EXCHANGE_SELL ) 
		LET glob_rec_invoicehead.inv_ind = "l_x" 
		LET glob_rec_invoicehead.prev_paid_amt = 0 
		LET glob_rec_invoicehead.price_tax_flag = NULL 
		LET glob_rec_invoicehead.contact_text = NULL 
		LET glob_rec_invoicehead.tele_text = NULL 
		LET glob_rec_invoicehead.mobile_phone = NULL
		LET glob_rec_invoicehead.email = NULL
		LET glob_rec_invoicehead.invoice_to_ind = '1' 
		LET glob_rec_invoicehead.territory_code = l_rec_customer.territory_code 
		LET glob_rec_invoicehead.cond_code = NULL 
		LET glob_rec_invoicehead.scheme_amt = 0 
		LET glob_rec_invoicehead.jour_num = NULL 
		LET glob_rec_invoicehead.post_date = NULL 
		LET glob_rec_invoicehead.carrier_code = NULL 
		LET glob_rec_invoicehead.manifest_num = NULL 
		LET glob_rec_invoicehead.stat_date = NULL 
		
		CALL get_fiscal_year_period_for_date(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_invoicehead.inv_date ) 
		RETURNING 
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num 
		
		IF NOT valid_period2(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_invoicehead.year_num, 
			glob_rec_invoicehead.period_num,
			"AR") THEN 
			
			LET glob_err_message = "Fiscal year & period NOT valid FOR: ",	glob_rec_invoicehead.inv_date USING "dd/mm/yy" 
			GOTO exception 
		END IF 
		
		SELECT mgr_code INTO glob_rec_invoicehead.mgr_code 
		FROM salesperson 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_rec_customer.sale_code 
		
		SELECT area_code INTO glob_rec_invoicehead.area_code 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = l_rec_customer.territory_code 
		
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = glob_rec_invoicehead.term_code 
		
		IF sqlca.sqlcode = 0 THEN 
			CALL get_due_and_discount_date(l_rec_term.*,glob_rec_invoicehead.inv_date) 
			RETURNING glob_rec_invoicehead.due_date, 
			glob_rec_invoicehead.disc_date 
		ELSE 
			LET glob_rec_invoicehead.due_date = glob_rec_invoicehead.inv_date 
		END IF 
		
		OPEN c2_sawtrack USING l_doc_num 
		FOREACH c2_sawtrack INTO l_rec_sawtrack.* 
			LET l_rec_sawtrack.cust_code = upshift(l_rec_sawtrack.cust_code) 
			LET l_rec_sawtrack.part_code = upshift(l_rec_sawtrack.part_code) 
			LET l_rec_sawtrack.loc_code = upshift(l_rec_sawtrack.loc_code) 
			IF l_rec_sawtrack.disc_amt IS NULL THEN 
				LET l_rec_sawtrack.disc_amt = 0 
			END IF 
			IF l_rec_sawtrack.line_qty IS NULL THEN 
				LET l_rec_sawtrack.line_qty = 1 
			END IF 
			IF l_rec_sawtrack.line_qty = 0 THEN 
				LET l_rec_sawtrack.line_qty = 1 
			END IF 
			IF l_rec_sawtrack.disc_per IS NULL THEN 
				LET l_rec_sawtrack.disc_per = 0 
			END IF 
			IF l_rec_sawtrack.ext_sales_amt IS NULL THEN 
				LET l_rec_sawtrack.ext_sales_amt = 0 
			END IF 
			INITIALIZE l_rec_invoicedetl.* TO NULL 
			LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
			LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
			LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
			LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
			LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
			LET l_rec_invoicedetl.ware_code = l_rec_warehouse.ware_code 
			IF l_rec_sawtrack.part_code IS NOT NULL THEN 
				LET l_rec_invoicedetl.part_code = l_rec_sawtrack.part_code 
				SELECT * INTO l_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_invoicedetl.part_code 
				IF l_rec_product.super_part_code IS NOT NULL THEN 
					LET l_x = 0 
					WHILE l_rec_product.super_part_code IS NOT NULL 
						LET l_x = l_x + 1 
						IF l_x > 20 THEN 
							LET glob_err_message = 
							"Product supercession limit exceeded FOR:", 
							l_rec_sawtrack.part_code clipped 
							GOTO exception 
						END IF 
						SELECT * INTO l_rec_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_product.super_part_code 
					END WHILE 
					LET l_rec_invoicedetl.part_code = l_rec_product.part_code 
					LET l_rec_invoicedetl.line_text = l_rec_product.desc_text 
				END IF 
				IF NOT valid_part(glob_rec_kandoouser.cmpy_code,l_rec_invoicedetl.part_code, 
				l_rec_invoicedetl.ware_code, 
				FALSE,2,0,"","","") THEN 
					LET glob_err_message = "Product code NOT valid :", 
					l_rec_invoicedetl.part_code clipped 
					GOTO exception 
				END IF 
				#
				# Arms Length Transaction
				#
				IF l_rec_customer.ref2_code IS NOT NULL THEN 
					OPEN c2_warehouse USING l_rec_customer.ref2_code 
					FETCH c2_warehouse INTO l_rec_x_warehouse.* 
					IF status = NOTFOUND THEN 
						OPEN c1_warehouse USING l_rec_customer.ref2_code 
						FETCH c1_warehouse INTO l_rec_x_warehouse.* 
					END IF 
					IF status = 0 THEN 
						OPEN c_prodstatus USING l_rec_invoicedetl.part_code, 
						l_rec_x_warehouse.ware_code 
						FETCH c_prodstatus INTO l_rec_prodstatus.* 
						IF sqlca.sqlcode = NOTFOUND THEN 
							LET glob_err_message = "Product does NOT exist AT Location: ", 
							l_rec_x_warehouse.ware_code 
							GOTO exception 
						END IF 
					ELSE 
						LET glob_err_message = "Invalid Warehouse: ", 
						l_rec_x_warehouse.ware_code clipped 
						GOTO exception 
					END IF 
					IF NOT valid_part(glob_rec_kandoouser.cmpy_code, 
					l_rec_invoicedetl.part_code, 
					l_rec_x_warehouse.ware_code, 
					FALSE,2,0,"","","") THEN 
						LET glob_err_message = "Product: ", 
						l_rec_invoicedetl.part_code clipped, 
						" unavailable" 
						GOTO exception 
					END IF 
				END IF 
			END IF 
			LET l_rec_invoicedetl.ord_qty = l_rec_sawtrack.line_qty 
			LET l_rec_invoicedetl.ship_qty = l_rec_sawtrack.line_qty 
			LET l_rec_invoicedetl.prev_qty = 0 
			LET l_rec_invoicedetl.back_qty = 0 
			LET l_rec_invoicedetl.ser_flag = 'N' 
			LET l_rec_invoicedetl.ser_qty = 0 
			##
			## Check FOR Product / Sundry line
			##
			IF l_rec_sawtrack.pack_text[1,1] = 'T' THEN 
				##
				## Sundry line - retreive Income Account FROM userref table.
				##
				SELECT ref_desc_text INTO l_rec_invoicedetl.line_acct_code 
				FROM userref 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND source_ind = 'Z' 
				AND ref_ind = '1' 
				AND ref_code = l_rec_sawtrack.pack_text 
				LET l_rec_invoicedetl.line_text = l_rec_sawtrack.line_text 
				LET l_rec_invoicedetl.unit_cost_amt = 0 
			ELSE 
				##
				## Product line
				##
				IF l_rec_product.part_code IS NOT NULL THEN 
					SELECT sale_acct_code INTO l_rec_invoicedetl.line_acct_code 
					FROM category 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cat_code = l_rec_product.cat_code 
				END IF 
				LET l_pack_text = "Pk: ", l_rec_sawtrack.pack_text clipped, 
				": ", l_rec_sawtrack.length_text clipped 
				LET l_rec_invoicedetl.line_text = l_pack_text[1,30] 
				SELECT wgted_cost_amt INTO l_rec_invoicedetl.unit_cost_amt 
				FROM prodstatus 
				WHERE cmpy_code = l_rec_invoicedetl.cmpy_code 
				AND part_code = l_rec_invoicedetl.part_code 
				AND ware_code = l_rec_invoicedetl.ware_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_rec_invoicedetl.unit_cost_amt = 0 
				END IF 
			END IF 
			LET l_rec_invoicedetl.ext_cost_amt = l_rec_invoicedetl.unit_cost_amt 
			* l_rec_invoicedetl.ship_qty 
			LET l_rec_invoicedetl.disc_amt = 0 
			LET l_rec_invoicedetl.unit_sale_amt = l_rec_sawtrack.ext_sales_amt 
			/ l_rec_invoicedetl.ship_qty 
			LET l_rec_invoicedetl.ext_sale_amt = l_rec_sawtrack.ext_sales_amt 
			LET l_rec_invoicedetl.unit_tax_amt = 0 
			LET l_rec_invoicedetl.ext_tax_amt = 0 
			LET l_rec_invoicedetl.line_total_amt = l_rec_invoicedetl.ext_sale_amt 
			+ l_rec_invoicedetl.ext_tax_amt 
			LET l_rec_invoicedetl.seq_num = 0 
			IF l_rec_invoicedetl.line_total_amt != 0 
			AND l_rec_invoicedetl.line_acct_code IS NULL THEN 
				LET glob_err_message = "Sales A/C NOT valid : ",l_rec_sawtrack.pack_text 
				GOTO exception 
			END IF 
			LET l_rec_invoicedetl.line_acct_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.acct_override_code, 
			l_rec_invoicedetl.line_acct_code) 

			LET l_rec_invoicedetl.level_code = l_rec_customer.inv_level_ind 
			LET l_rec_invoicedetl.comm_amt = 0 
			LET l_rec_invoicedetl.comp_per = 0 
			LET l_rec_invoicedetl.tax_code = l_rec_customer.tax_code 
			LET l_rec_invoicedetl.order_line_num = NULL 
			LET l_rec_invoicedetl.order_num = NULL 
			LET l_rec_invoicedetl.disc_per = l_rec_sawtrack.disc_per 
			LET l_rec_invoicedetl.offer_code = NULL 
			LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ord_qty 
			LET l_rec_invoicedetl.bonus_qty = 0 
			LET l_rec_invoicedetl.ext_bonus_amt = 0 
			LET l_rec_invoicedetl.ext_stats_amt = l_rec_invoicedetl.ext_sale_amt 
			#
			# Changed the following line
			# LET l_rec_invoicedetl.list_price_amt = l_rec_sawtrack.ext_sales_amt TO
			# LET l_rec_invoicedetl.list_price_amt = l_rec_invoicedetl.unit_sale_amt
			# because the calculations WHEN running SawTrack External Transaction
			# Import (AS1) were printing invoices with different VALUES WHEN
			# compared with the VALUES of the customer ledger AND invoice VALUES
			#
			LET l_rec_invoicedetl.list_price_amt = l_rec_invoicedetl.unit_sale_amt 
			LET l_rec_invoicedetl.uom_code = l_rec_sawtrack.uom_code 
			LET l_rec_invoicedetl.cat_code = l_rec_product.cat_code 
			LET l_rec_invoicedetl.prodgrp_code = l_rec_product.prodgrp_code 
			LET l_rec_invoicedetl.maingrp_code = l_rec_product.maingrp_code 
			##
			INSERT INTO t_invoicedetl VALUES (l_rec_invoicedetl.*) 
			##
			## Accumalate header VALUES
			##
			LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt 
			+ l_rec_invoicedetl.ext_cost_amt 
			LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt 
			+ l_rec_invoicedetl.ext_sale_amt 
			LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt 
			+ l_rec_invoicedetl.ext_tax_amt 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt 
			+ glob_rec_invoicehead.tax_amt 
			+ glob_rec_invoicehead.freight_amt 
			+ glob_rec_invoicehead.hand_amt 
			#
			# Comment Line validation
			#
			IF l_rec_sawtrack.pack_text[1,1] != 'T' THEN 
				LET l_x = 31 ## points TO starting position 
				LET l_pack_text = l_pack_text[l_x,250] clipped 
				LET l_y = length(l_pack_text) 
				WHILE l_y 
					INITIALIZE l_rec_invoicedetl.* TO NULL 
					LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
					LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
					LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
					LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
					LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
					LET l_rec_invoicedetl.part_code = NULL 
					LET l_rec_invoicedetl.ware_code = NULL 
					LET l_rec_invoicedetl.ord_qty = 0 
					LET l_rec_invoicedetl.ship_qty = 0 
					LET l_rec_invoicedetl.prev_qty = 0 
					LET l_rec_invoicedetl.back_qty = 0 
					LET l_rec_invoicedetl.ser_flag = NULL 
					LET l_rec_invoicedetl.ser_qty = 0 
					LET l_rec_invoicedetl.line_text = l_pack_text[1,30] 
					LET l_rec_invoicedetl.uom_code = NULL 
					LET l_rec_invoicedetl.unit_cost_amt = 0 
					LET l_rec_invoicedetl.ext_cost_amt = 0 
					LET l_rec_invoicedetl.disc_amt = 0 
					LET l_rec_invoicedetl.unit_sale_amt = 0 
					LET l_rec_invoicedetl.ext_sale_amt = 0 
					LET l_rec_invoicedetl.unit_tax_amt = 0 
					LET l_rec_invoicedetl.ext_tax_amt = 0 
					LET l_rec_invoicedetl.line_total_amt = 0 
					LET l_rec_invoicedetl.seq_num = 0 
					LET l_rec_invoicedetl.line_acct_code = NULL 
					LET l_rec_invoicedetl.level_code = NULL 
					LET l_rec_invoicedetl.comm_amt = 0 
					LET l_rec_invoicedetl.comp_per = 0 
					LET l_rec_invoicedetl.tax_code = NULL 
					LET l_rec_invoicedetl.order_line_num = NULL 
					LET l_rec_invoicedetl.order_num = NULL 
					LET l_rec_invoicedetl.disc_per = 0 
					LET l_rec_invoicedetl.offer_code = NULL 
					LET l_rec_invoicedetl.sold_qty = 0 
					LET l_rec_invoicedetl.bonus_qty = 0 
					LET l_rec_invoicedetl.ext_bonus_amt = 0 
					LET l_rec_invoicedetl.ext_stats_amt = 0 
					LET l_rec_invoicedetl.list_price_amt = 0 
					LET l_rec_invoicedetl.cat_code = NULL 
					LET l_rec_invoicedetl.prodgrp_code = NULL 
					LET l_rec_invoicedetl.maingrp_code = NULL 
					INSERT INTO t_invoicedetl VALUES (l_rec_invoicedetl.*) 
					#
					#
					LET l_pack_text = l_pack_text[l_x,250] clipped 
					LET l_y = length(l_pack_text) 
				END WHILE 
			END IF 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				#8004 Do you wish TO quit (l_y/N) ?
				IF kandoomsg("A",8004,"") = 'l_y' THEN 
					RETURN 
				END IF 
			END IF 
		END FOREACH 
		CLOSE c2_sawtrack 
		IF glob_rec_invoicehead.total_amt >= 0 THEN 
			## Create Invoice
			LET l_mode = TRAN_TYPE_INVOICE_IN 
			OPEN c1_checkdupl USING glob_rec_invoicehead.cust_code, 
			glob_rec_invoicehead.purchase_code 
			FETCH c1_checkdupl 
		ELSE 
			## Create Credit
			LET l_mode = TRAN_TYPE_CREDIT_CR 
			OPEN c2_checkdupl USING glob_rec_invoicehead.cust_code, 
			glob_rec_invoicehead.purchase_code 
			FETCH c2_checkdupl 
		END IF 
		IF status = 0 THEN 
			LET glob_err_message = "Transaction already loaded - Ref:", 
			l_rec_sawtrack.doc_num 
			GOTO exception 
		END IF 
		IF glob_update_ind THEN 
			##
			## Database Update Section Starts Here.
			##
			GOTO bypass 
			LABEL recovery: 
			IF glob_verbose_indv THEN 
				IF error_recover(glob_err_message,status) != "l_y" THEN 
					EXIT PROGRAM 
				END IF 
			ELSE 
				ROLLBACK WORK 
				IF NOT retry_lock(glob_rec_kandoouser.cmpy_code,status) > 0 THEN 
					## Exception REPORT - Database Update Error.
					GOTO exception 
				END IF 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET glob_rec_invoicehead.inv_num = 
				next_trans_num(glob_rec_kandoouser.cmpy_code,l_mode,glob_rec_invoicehead.acct_override_code ) 
				IF glob_rec_invoicehead.inv_num < 0 THEN 
					LET status = glob_rec_invoicehead.inv_num 
					GOTO recovery 
				END IF 
				OPEN c_t_invoice 
				FOREACH c_t_invoice INTO l_rec_invoicedetl.* 
					LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
					IF l_rec_invoicedetl.part_code IS NOT NULL 
					AND l_rec_invoicedetl.ship_qty != 0 THEN 
						LET glob_err_message = "ASL Lock Error", 
						" P: ",l_rec_invoicedetl.part_code clipped, 
						" W: ",l_rec_invoicedetl.ware_code clipped 
						OPEN c_prodstatus USING l_rec_invoicedetl.part_code, 
						l_rec_invoicedetl.ware_code 
						FETCH c_prodstatus INTO l_rec_prodstatus.* 
						IF sqlca.sqlcode = NOTFOUND THEN 
							GOTO recovery 
						END IF 
						LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
						LET l_rec_invoicedetl.seq_num = l_rec_prodstatus.seq_num 
						LET glob_err_message = "ASL - Error Updating Prodstatus" 
						IF l_rec_prodstatus.stocked_flag = "l_y" THEN 
							LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty 
							- l_rec_invoicedetl.ship_qty 
						END IF 
						UPDATE prodstatus 
						SET seq_num = l_rec_prodstatus.seq_num, 
						onhand_qty = l_rec_prodstatus.onhand_qty, 
						last_sale_date = glob_rec_invoicehead.inv_date 
						WHERE cmpy_code = l_rec_invoicedetl.cmpy_code 
						AND part_code = l_rec_invoicedetl.part_code 
						AND ware_code = l_rec_invoicedetl.ware_code 
						INITIALIZE l_rec_prodledg.* TO NULL 
						LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
						LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
						LET l_rec_prodledg.tran_date = glob_rec_invoicehead.inv_date 
						LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
						IF l_mode = TRAN_TYPE_INVOICE_IN THEN 
							LET l_rec_prodledg.trantype_ind= 'S' 
						ELSE 
							LET l_rec_prodledg.trantype_ind= 'C' 
						END IF 
						LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty 
						LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
						LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
						LET l_rec_prodledg.source_text = glob_rec_invoicehead.cust_code 
						LET l_rec_prodledg.source_num = glob_rec_invoicehead.inv_num 
						LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt 
						/ glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt 
						/ glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.hist_flag = 'N' 
						LET l_rec_prodledg.post_flag = 'N' 
						LET l_rec_prodledg.acct_code = NULL 
						LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
						LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_prodledg.entry_date = today 
						LET glob_err_message = "ASL - Error inserting product ledger entry" 
						INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
						#
						# Arms Length Transaction
						#
						#
						IF l_rec_customer.ref2_code IS NOT NULL THEN 
							OPEN c2_warehouse USING l_rec_customer.ref2_code 
							FETCH c2_warehouse INTO l_rec_x_warehouse.* 
							IF status = NOTFOUND THEN 
								OPEN c1_warehouse USING l_rec_customer.ref2_code 
								FETCH c1_warehouse INTO l_rec_x_warehouse.* 
							END IF 
							IF status = 0 THEN 
								LET glob_err_message = "ASL Lock error", 
								" P: ", l_rec_invoicedetl.part_code clipped, 
								" W: ", l_rec_x_warehouse.ware_code clipped 
								OPEN c_prodstatus USING l_rec_invoicedetl.part_code, 
								l_rec_x_warehouse.ware_code 
								FETCH c_prodstatus INTO l_rec_prodstatus.* 
								IF sqlca.sqlcode = NOTFOUND THEN 
									GOTO recovery 
								END IF 
								LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
								LET glob_err_message = "ASL - Error Updating Prodstatus" 
								IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
									LET l_rec_prodstatus.wgted_cost_amt = 0 
								END IF 
								IF l_rec_prodstatus.act_cost_amt IS NULL THEN 
									LET l_rec_prodstatus.act_cost_amt = 0 
								END IF 
								INITIALIZE l_rec_prodledg.* TO NULL 
								LET l_rec_prodledg.tran_qty = l_rec_invoicedetl.ship_qty 
								LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_sale_amt 
								/ glob_rec_invoicehead.conv_qty 
								IF l_rec_prodledg.cost_amt IS NULL THEN 
									LET l_rec_prodledg.cost_amt = 0 
								END IF 
								CASE 
									WHEN l_rec_prodstatus.onhand_qty <= 0 
										LET l_rec_prodstatus.wgted_cost_amt = 
										l_rec_prodledg.cost_amt 
									WHEN (l_rec_prodstatus.onhand_qty + 
										l_rec_prodledg.tran_qty) <= 0 
										LET l_rec_prodstatus.wgted_cost_amt = 
										l_rec_prodledg.cost_amt 
									OTHERWISE 
										LET l_rec_prodstatus.wgted_cost_amt = 
										((l_rec_prodstatus.wgted_cost_amt * 
										l_rec_prodstatus.onhand_qty) + 
										(l_rec_prodledg.tran_qty * l_rec_prodledg.cost_amt)) 
										/ (l_rec_prodledg.tran_qty + 
										l_rec_prodstatus.onhand_qty) 
								END CASE 
								#
								# put actual TO latest cost amount
								#
								LET l_rec_prodstatus.act_cost_amt = l_rec_prodledg.cost_amt 
								IF l_rec_prodstatus.stocked_flag = "l_y" THEN 
									LET l_rec_prodstatus.onhand_qty = 
									l_rec_prodstatus.onhand_qty + l_rec_invoicedetl.ship_qty 
								END IF 
								UPDATE prodstatus 
								SET seq_num = l_rec_prodstatus.seq_num, 
								onhand_qty = l_rec_prodstatus.onhand_qty, 
								wgted_cost_amt = l_rec_prodstatus.wgted_cost_amt, 
								act_cost_amt = l_rec_prodstatus.act_cost_amt, 
								last_receipt_date = glob_rec_invoicehead.inv_date 
								WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
								AND part_code = l_rec_prodstatus.part_code 
								AND ware_code = l_rec_prodstatus.ware_code 
								LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
								LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
								LET l_rec_prodledg.tran_date = glob_rec_invoicehead.inv_date 
								LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
								LET l_rec_prodledg.trantype_ind= 'R' 
								LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
								LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
								LET l_rec_prodledg.source_text = glob_rec_invoicehead.cust_code 
								LET l_rec_prodledg.source_num = glob_rec_invoicehead.inv_num 
								LET l_rec_prodledg.sales_amt = l_rec_prodledg.cost_amt 
								LET l_rec_prodledg.hist_flag = 'N' 
								LET l_rec_prodledg.post_flag = 'N' 
								LET l_rec_prodledg.acct_code = l_rec_invoicedetl.line_acct_code 
								LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
								LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
								LET l_rec_prodledg.entry_date = today 
								LET glob_err_message ="Insert Inter-Comp product ledger receipt" 
								INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
							END IF 
						END IF 
					END IF 
					##
					## Invoicedetl INSERT
					##
					LET glob_err_message = "ASL - Error inserting line item info" 
					IF l_mode = TRAN_TYPE_CREDIT_CR THEN 
						CALL map_invdetl_to_creddetl(l_rec_invoicedetl.*) 
						RETURNING l_rec_creditdetl.* 
						
						INSERT INTO creditdetl VALUES (l_rec_creditdetl.*)
						 
					ELSE

						#INSERT invoiceDetl Record
						IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
							INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
						ELSE
							DISPLAY l_rec_invoicedetl.*
							CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
						END IF 
						 
					END IF 
					#-----------------------------------
					# Comment Line validation
					#
				END FOREACH 
				LET glob_err_message = "ASL - Error inserting invoice:",	glob_rec_invoicehead.inv_num 

				IF l_mode = TRAN_TYPE_CREDIT_CR THEN 
					CALL map_invhead_to_credhead(glob_rec_invoicehead.*) 
					RETURNING l_rec_credithead.* 
					INSERT INTO credithead VALUES (l_rec_credithead.*) 
				ELSE 
					#INSERT invoicehead Record
					IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
						INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
					ELSE
						DISPLAY glob_rec_invoicehead.*
						CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
					END IF 				

				END IF 

				#-------------------------------------
				# Stattrig
				
				LET glob_err_message = "ASL - Error inserting statistics information" 
				
				INITIALIZE l_rec_stattrig.* TO NULL 
				
				LET l_rec_stattrig.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_stattrig.tran_type_ind = l_mode 
				LET l_rec_stattrig.trans_num = glob_rec_invoicehead.inv_num 
				LET l_rec_stattrig.tran_date = glob_rec_invoicehead.inv_date
				 
				INSERT INTO stattrig VALUES ( l_rec_stattrig.* ) 
				#
				# Araudit
				#
				INITIALIZE l_rec_araudit.* TO NULL 
				LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
				LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
				LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_araudit.tran_type_ind = l_mode 
				LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
				LET l_rec_araudit.tran_text = glob_rec_loadparms.desc_text 
				LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
				LET l_rec_araudit.entry_code = glob_rec_invoicehead.entry_code 
				LET l_rec_araudit.sales_code = glob_rec_invoicehead.sale_code 
				LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
				+ glob_rec_invoicehead.total_amt 
				LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
				LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
				LET l_rec_araudit.currency_code = glob_rec_invoicehead.currency_code 
				LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
				LET l_rec_araudit.entry_date = today 
				LET glob_err_message = "ASL - Error inserting AR audit entry" 
				INSERT INTO araudit VALUES (l_rec_araudit.*) 
				##
				## Update customer details
				##
				LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
				+ glob_rec_invoicehead.total_amt 
				LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
				+ glob_rec_invoicehead.total_amt 
				LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
				- l_rec_customer.bal_amt 
				IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
					LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
				END IF 
				IF year(glob_rec_invoicehead.inv_date)>year(l_rec_customer.last_inv_date) THEN 
					LET l_rec_customer.ytds_amt = 0 
					LET l_rec_customer.mtds_amt = 0 
				END IF 
				IF month(glob_rec_invoicehead.inv_date)>month(l_rec_customer.last_inv_date) THEN 
					LET l_rec_customer.mtds_amt = 0 
				END IF 
				LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
				+ glob_rec_invoicehead.total_amt 
				LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
				+ glob_rec_invoicehead.total_amt 
				LET l_rec_customer.last_inv_date = glob_rec_invoicehead.inv_date 
				LET glob_err_message = "ASL - Error updating the customer master file" 
				UPDATE customer 
				SET next_seq_num = l_rec_customer.next_seq_num, 
				bal_amt = l_rec_customer.bal_amt, 
				curr_amt = l_rec_customer.curr_amt, 
				highest_bal_amt = l_rec_customer.highest_bal_amt, 
				cred_bal_amt = l_rec_customer.cred_bal_amt, 
				last_inv_date = l_rec_customer.last_inv_date, 
				ytds_amt = l_rec_customer.ytds_amt, 
				mtds_amt = l_rec_customer.mtds_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_sawtrack.cust_code 
				DELETE FROM t_invoicedetl WHERE 1=1 
				DELETE FROM t_sawtrack WHERE doc_num = l_rec_sawtrack.doc_num 
			COMMIT WORK 
		END IF 
		##
		## Unload rows NOT imported INTO load file.
		## This IS done AFTER each transaction TO handle CASE WHERE
		## prog crashes AND all transactions (even those committed)
		## still exist in load file TO be re-imported
		##
		UNLOAD TO glob_load_file SELECT * FROM t_sawtrack 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF l_mode = TRAN_TYPE_INVOICE_IN THEN 
			LET modu_rec_progress.inv_cnt = modu_rec_progress.inv_cnt + 1 
		ELSE 
			LET modu_rec_progress.cred_cnt = modu_rec_progress.cred_cnt + 1 
		END IF 

		#---------------------------------------------------------
		#Positive/Sucess Output (not error/exception)
		OUTPUT TO REPORT ASL_rpt_list_2_saw(rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw"),
		glob_rec_invoicehead.cust_code, 
		l_rec_sawtrack.doc_num, 
		l_mode, 
		glob_rec_invoicehead.inv_num, 
		glob_rec_invoicehead.total_amt ) 
		#--------------------------------------------------------- 
		
		CONTINUE FOREACH 
		LABEL exception: 
		LET modu_rec_progress.err_cnt = modu_rec_progress.err_cnt + 1 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		glob_rec_kandoouser.cmpy_code,l_rec_sawtrack.cust_code, 
		l_rec_sawtrack.doc_num,glob_err_message) 
		#--------------------------------------------------------- 
		
	END FOREACH 
	CLOSE c1_sawtrack 
	CLOSE c2_sawtrack 
END FUNCTION 


####################################################################
# FUNCTION map_invhead_to_credhead(p_rec_invoicehead)
#
#
####################################################################
FUNCTION map_invhead_to_credhead(p_rec_invoicehead) 
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 

	LET l_rec_credithead.cmpy_code = p_rec_invoicehead.cmpy_code 
	LET l_rec_credithead.cust_code = p_rec_invoicehead.cust_code 
	LET l_rec_credithead.org_cust_code = p_rec_invoicehead.org_cust_code 
	LET l_rec_credithead.cred_num = p_rec_invoicehead.inv_num 
	LET l_rec_credithead.cred_text = p_rec_invoicehead.purchase_code 
	LET l_rec_credithead.entry_code = p_rec_invoicehead.entry_code 
	LET l_rec_credithead.entry_date = p_rec_invoicehead.entry_date 
	LET l_rec_credithead.cred_date = p_rec_invoicehead.inv_date 
	LET l_rec_credithead.sale_code = p_rec_invoicehead.sale_code 
	LET l_rec_credithead.tax_code = p_rec_invoicehead.tax_code 
	LET l_rec_credithead.tax_per = p_rec_invoicehead.tax_per 
	LET l_rec_credithead.goods_amt = 0 - p_rec_invoicehead.goods_amt 
	LET l_rec_credithead.hand_amt = 0 - p_rec_invoicehead.hand_amt 
	LET l_rec_credithead.hand_tax_code = p_rec_invoicehead.hand_tax_code 
	LET l_rec_credithead.hand_tax_amt = 0 - p_rec_invoicehead.hand_tax_amt 
	LET l_rec_credithead.freight_amt = 0 - p_rec_invoicehead.freight_amt 
	LET l_rec_credithead.freight_tax_code = p_rec_invoicehead.freight_tax_code 
	LET l_rec_credithead.freight_tax_amt = 0 - p_rec_invoicehead.freight_tax_amt 
	LET l_rec_credithead.tax_amt = 0 - p_rec_invoicehead.tax_amt 
	LET l_rec_credithead.total_amt = 0 - p_rec_invoicehead.total_amt 
	LET l_rec_credithead.cost_amt = 0 - p_rec_invoicehead.cost_amt 
	LET l_rec_credithead.appl_amt = 0 
	LET l_rec_credithead.disc_amt = 0 
	LET l_rec_credithead.year_num = p_rec_invoicehead.year_num 
	LET l_rec_credithead.period_num = p_rec_invoicehead.period_num 
	LET l_rec_credithead.on_state_flag = "N" 
	LET l_rec_credithead.posted_flag = "N" 
	LET l_rec_credithead.next_num = 0 
	LET l_rec_credithead.line_num = p_rec_invoicehead.line_num 
	LET l_rec_credithead.printed_num = 0 
	LET l_rec_credithead.com1_text = p_rec_invoicehead.com1_text 
	LET l_rec_credithead.com2_text = p_rec_invoicehead.com2_text 
	LET l_rec_credithead.rev_date = today 
	LET l_rec_credithead.rev_num = 0 
	LET l_rec_credithead.currency_code = p_rec_invoicehead.currency_code 
	LET l_rec_credithead.conv_qty = p_rec_invoicehead.conv_qty 
	LET l_rec_credithead.cred_ind = p_rec_invoicehead.inv_ind 
	LET l_rec_credithead.acct_override_code = p_rec_invoicehead.acct_override_code 
	LET l_rec_credithead.territory_code = p_rec_invoicehead.territory_code 
	LET l_rec_credithead.mgr_code = p_rec_invoicehead.mgr_code 
	LET l_rec_credithead.area_code = p_rec_invoicehead.area_code 
	LET l_rec_credithead.cond_code = p_rec_invoicehead.cond_code 
	LET l_rec_credithead.tax_cert_text = p_rec_invoicehead.tax_cert_text 
	RETURN l_rec_credithead.* 
END FUNCTION 


####################################################################
# FUNCTION map_invdetl_to_creddetl(p_rec_invoicedetl)
#
#
####################################################################
FUNCTION map_invdetl_to_creddetl(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

	LET l_rec_creditdetl.cmpy_code = p_rec_invoicedetl.cmpy_code 
	LET l_rec_creditdetl.cust_code = p_rec_invoicedetl.cust_code 
	LET l_rec_creditdetl.cred_num = p_rec_invoicedetl.inv_num 
	LET l_rec_creditdetl.line_num = p_rec_invoicedetl.line_num 
	LET l_rec_creditdetl.part_code = p_rec_invoicedetl.part_code 
	LET l_rec_creditdetl.ware_code = p_rec_invoicedetl.ware_code 
	LET l_rec_creditdetl.cat_code = p_rec_invoicedetl.cat_code 
	LET l_rec_creditdetl.ship_qty = 0 - p_rec_invoicedetl.ship_qty 
	LET l_rec_creditdetl.line_text = p_rec_invoicedetl.line_text 
	LET l_rec_creditdetl.uom_code = p_rec_invoicedetl.uom_code 
	LET l_rec_creditdetl.line_text = p_rec_invoicedetl.line_text 
	LET l_rec_creditdetl.ser_ind = "N" 
	LET l_rec_creditdetl.line_text = p_rec_invoicedetl.line_text 
	LET l_rec_creditdetl.unit_cost_amt = p_rec_invoicedetl.unit_cost_amt 
	LET l_rec_creditdetl.ext_cost_amt = p_rec_invoicedetl.ext_cost_amt 
	LET l_rec_creditdetl.disc_amt = p_rec_invoicedetl.disc_amt 
	LET l_rec_creditdetl.unit_sales_amt = p_rec_invoicedetl.unit_sale_amt 
	LET l_rec_creditdetl.ext_sales_amt = 0 - p_rec_invoicedetl.ext_sale_amt 
	LET l_rec_creditdetl.unit_tax_amt = p_rec_invoicedetl.unit_tax_amt 
	LET l_rec_creditdetl.ext_tax_amt = 0 - p_rec_invoicedetl.ext_tax_amt 
	LET l_rec_creditdetl.line_total_amt = 0 - p_rec_invoicedetl.line_total_amt 
	LET l_rec_creditdetl.seq_num = 0 
	LET l_rec_creditdetl.line_acct_code = p_rec_invoicedetl.line_acct_code 
	LET l_rec_creditdetl.level_code = p_rec_invoicedetl.level_code 
	LET l_rec_creditdetl.tax_code = p_rec_invoicedetl.tax_code 
	LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
	LET l_rec_creditdetl.prodgrp_code = p_rec_invoicedetl.prodgrp_code 
	LET l_rec_creditdetl.maingrp_code = p_rec_invoicedetl.maingrp_code 
	LET l_rec_creditdetl.list_amt = 0 - p_rec_invoicedetl.list_price_amt 
	RETURN l_rec_creditdetl.* 
END FUNCTION 



####################################################################
# FUNCTION ASL_rpt_start_2_saw()
#
#
####################################################################
FUNCTION ASL_rpt_start_2_saw()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_tmp_str STRING
	#------------------------------------------------------------	
	#Report for success
	LET l_rpt_idx = rpt_start("ASL-SAW","ASL_rpt_list_2_saw","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASL_rpt_list_2_saw TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw")].sel_text
	#------------------------------------------------------------

	LET l_tmp_str = " - (Load No:", glob_rec_loadparms.seq_num using "<<<<<",")"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str) #append load seq number to the right of header line 2
	#------------------------------------------------------------

END FUNCTION 



####################################################################
# FUNCTION ASL_rpt_finish_2_saw() 
#
#
####################################################################
FUNCTION ASL_rpt_finish_2_saw() 

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASL_rpt_list_2_saw
	CALL rpt_finish("ASL_rpt_list_2_saw")
	#------------------------------------------------------------

END FUNCTION




####################################################################
# REPORT ASL_rpt_list_2_saw(p_cust_code,p_ref_text,p_tran_type,p_tran_num,p_total_amt)
#
#
####################################################################
REPORT ASL_rpt_list_2_saw(p_rpt_idx,p_cust_code,p_ref_text,p_tran_type,p_tran_num,p_total_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_ref_text CHAR(8) 
	DEFINE p_tran_type CHAR(2) 
	DEFINE p_tran_num LIKE invoicehead.inv_num 
	DEFINE p_total_amt LIKE invoicehead.total_amt 


	OUTPUT 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		ON EVERY ROW 
			IF glob_update_ind THEN 
				PRINT COLUMN 01, p_cust_code clipped, 
				COLUMN 13, p_ref_text clipped, 
				COLUMN 28, p_tran_type, 
				COLUMN 33, p_tran_num USING "########", 
				COLUMN 43, p_total_amt USING "##########&.&&" 
			ELSE 
				PRINT COLUMN 01, p_cust_code clipped, 
				COLUMN 13, p_ref_text clipped, 
				COLUMN 28, p_tran_type, 
				COLUMN 33, "Test Only", 
				COLUMN 43, p_total_amt USING "##########&.&&" 
			END IF 
		ON LAST ROW 
			NEED 18 LINES 
			SKIP 2 LINES 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			SKIP 1 line 
			PRINT COLUMN 15, "Transaction Load Summary" 
			PRINT COLUMN 15, "========================" 
			SKIP 1 line 
			PRINT COLUMN 05, "Transactions TO be Loaded :", 
			COLUMN 33, modu_rec_progress.tran_cnt USING "########" 
			PRINT COLUMN 05, "Transactions Loaded :", 
			COLUMN 33, count(*) WHERE p_tran_type IS NOT NULL USING "########", 
			COLUMN 43, sum(p_total_amt) USING "##########&.&&" 
			SKIP 1 line 
			PRINT COLUMN 05, " Consists of Invoices :", 
			COLUMN 33, count(*) WHERE p_tran_type = TRAN_TYPE_INVOICE_IN USING "########", 
			COLUMN 43, sum(p_total_amt) WHERE p_tran_type = TRAN_TYPE_INVOICE_IN 
			USING "##########&.&&" 
			PRINT COLUMN 05, " Credits :", 
			COLUMN 33, count(*) WHERE p_tran_type = TRAN_TYPE_CREDIT_CR USING "########", 
			COLUMN 43, sum(p_total_amt) WHERE p_tran_type = TRAN_TYPE_CREDIT_CR 
			USING "##########&.&&" 
			SKIP 1 line 
			PRINT COLUMN 05, "Transactions Not Loaded :", 
			COLUMN 33, modu_rec_progress.err_cnt USING "########" 
			IF modu_rec_progress.err_cnt > 0 THEN 
				PRINT COLUMN 05, " Errors Occurred - Refer TO Exception Report " 
			END IF 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
 