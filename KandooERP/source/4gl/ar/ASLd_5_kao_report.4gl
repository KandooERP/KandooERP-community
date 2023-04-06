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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASL_GLOBALS.4gl"
###########################################################################
# Module Scope Variables
###########################################################################
DEFINE modu_ar_cnt INTEGER 
DEFINE modu_kao_ar_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_kandoo_ar_cnt INTEGER 
####################################################################
# FUNCTION kao_load()
#
# Goldwell Invoice Load
####################################################################
FUNCTION kao_load() 
	DEFINE l_rec_kao RECORD 
		cust_code CHAR(10) , ## customer code 
		trans_type CHAR(1) , ## transaction type 
		doc_num CHAR(10) , ## invoice / credit no. 
		ord_num CHAR(5) , 
		doc_date DATE , ## transaction DATE 
		goods_amt DECIMAL(16,2), 
		hand_amt DECIMAL(16,2), 
		freight_amt DECIMAL(16,2), 
		tax_amt DECIMAL(16,2), 
		inv_amt DECIMAL(16,2), 
		ship_date DATE, 
		ship_code CHAR(5), ## customer store_code 
		ware_code CHAR(3), ## customer store_code 
		ref_text CHAR(10), ## customer reference 
		tax_text CHAR(10) ## customer reference 
	END RECORD 
	DEFINE l_rec_kaodetl RECORD 
		doc_num CHAR(10), 
		line_num CHAR(3), 
		part_code CHAR(15), 
		desc_text CHAR(30), 
		ord_qty FLOAT, 
		ship_qty FLOAT, 
		back_qty FLOAT, 
		unit_cost_amt DECIMAL(16,4), 
		disc1_amt DECIMAL(16,4), 
		disc2_amt DECIMAL(16,4), 
		disc3_amt DECIMAL(16,4), 
		unit_price_amt DECIMAL(16,4), 
		ext_price_amt DECIMAL(16,4), 
		ext_tax_amt DECIMAL(16,4), 
		comm_amt DECIMAL(16,4), 
		list_amt DECIMAL(16,4) 
	END RECORD 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	LET modu_kao_ar_cnt = 0 
	LET modu_kandoo_ar_cnt = 0 
	#
	#
	# NB. Require 'WHENEVER ERROR CONTINUE / stop' because of Informix problem
	#     with continuous CREATE  / DROP table.
	#
	#
	# Create KAO temporary table
	#
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_tmpload 
	(load_text CHAR(256)) 
	CREATE temp TABLE t_kao 
	( 
	cust_code CHAR(10) , ## customer code 
	trans_type CHAR(1) , ## transaction type 
	doc_num CHAR(10) , ## invoice / credit no. 
	ord_num CHAR(5) , 
	doc_date DATE , ## transaction DATE 
	goods_amt DECIMAL(16,2), 
	hand_amt DECIMAL(16,2), 
	freight_amt DECIMAL(16,2), 
	tax_amt DECIMAL(16,2), 
	inv_amt DECIMAL(16,2), 
	ship_date DATE, 
	ship_code CHAR(5), ## customer store_code 
	ware_code CHAR(3), ## customer store_code 
	ref_text CHAR(10), ## customer reference 
	tax_text CHAR(10) ## customer reference 
	) with no LOG 
	CREATE temp TABLE t_kaodetl 
	( 
	doc_num CHAR(10), 
	line_num CHAR(3), 
	part_code CHAR(15), 
	desc_text CHAR(30), 
	ord_qty FLOAT, 
	ship_qty FLOAT, 
	back_qty FLOAT, 
	unit_cost_amt DECIMAL(16,4), 
	disc1_amt DECIMAL(16,4), 
	disc2_amt DECIMAL(16,4), 
	disc3_amt DECIMAL(16,4), 
	unit_price_amt DECIMAL(16,4), 
	ext_price_amt DECIMAL(16,4), 
	ext_tax_amt DECIMAL(16,4), 
	comm_amt DECIMAL(16,4), 
	list_amt DECIMAL(16,4) 
	) with no LOG 
	CREATE INDEX t_kaodetl_key ON t_kaodetl(doc_num,line_num) 
	
	IF fgl_find_table("t_trancnt") THEN
		DROP TABLE t_trancnt 
	END IF	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	DELETE FROM t_tmpload WHERE 1 = 1 
	DELETE FROM t_kao WHERE 1 = 1 
	#
	# Commence LOAD
	#
	LET glob_load_file = glob_load_file clipped 
	LOAD FROM glob_load_file INSERT INTO t_tmpload 
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	IF sqlca.sqlcode = 0 THEN 
		IF NOT load_t_kao() THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			RETURN false 
		END IF 
		#
		# Null Test's on data fields
		#
		DECLARE c1_kao CURSOR FOR 
		SELECT * FROM t_kao 
		WHERE cust_code IS NULL 
		OR trans_type IS NULL 
		OR doc_num IS NULL 
		OR doc_date IS NULL 
		OR inv_amt IS NULL 
		OR cust_code = ' ' 
		OR trans_type = ' ' 
		OR doc_num = ' ' 
		OR doc_date = ' ' 
		OR inv_amt = ' ' 
		FOREACH c1_kao INTO l_rec_kao.* 
			IF l_rec_kao.cust_code IS NULL 
			OR l_rec_kao.cust_code = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Customer Code detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_kao.cust_code, 
				l_rec_kao.doc_num, 
				glob_err_message )
				#--------------------------------------------------------- 

				 
			END IF 
			IF l_rec_kao.trans_type IS NULL 
			OR l_rec_kao.trans_type = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Transaction Type detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_kao.cust_code, 
				l_rec_kao.doc_num, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_kao.doc_num IS NULL 
			OR l_rec_kao.doc_num = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Invoice No. detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_kao.cust_code, 
				l_rec_kao.doc_num, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_kao.doc_date IS NULL 
			OR l_rec_kao.doc_date = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null date field detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_kao.cust_code, 
				l_rec_kao.doc_num, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_kao.inv_amt IS NULL 
			OR l_rec_kao.inv_amt = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null transaction amt detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_kao.cust_code, 
				l_rec_kao.doc_num, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
		END FOREACH 
		#
		#
		#
		IF glob_verbose_indv THEN 
			OPEN WINDOW A638 with FORM "A638" 
			CALL windecoration_a("A638") 

		END IF 
		CALL create_kao_entry() 
		IF glob_verbose_indv THEN 
			CLOSE WINDOW A638 
		END IF 
		#
		# All unsuccessful invoices will be re-inserted INTO load-file
		#
		#
		LET glob_load_file = glob_load_file clipped,".err" 
		UNLOAD TO glob_load_file SELECT * FROM t_kao 
	ELSE 
		LET modu_ar_cnt = status 
	END IF 
	#
	# RETURN no. of successfully generated invoices /credits
	#
	IF modu_ar_cnt < 0 THEN 
		#
		# Dummy line in REPORT TO force DISPLAY of Control Totals
		#
		#---------------------------------------------------------
		#Positive/Sucess Output (not error/exception)
		OUTPUT TO REPORT ASL_rpt_list_5_kao(rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao"),
		'', '', '', '', '', '', '', '' ) 
		#--------------------------------------------------------- 

		RETURN modu_ar_cnt 
	ELSE 
		IF NOT modu_kandoo_ar_cnt THEN 
			#
			# Dummy line in REPORT TO force DISPLAY of Control Totals
			#
		#---------------------------------------------------------
		#Positive/Sucess Output (not error/exception)
		OUTPUT TO REPORT ASL_rpt_list_5_kao(rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao"),
		'', '', '', '', '', '', '', '' ) 
		#--------------------------------------------------------- 
 
		END IF 
		RETURN modu_kandoo_ar_cnt 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION create_kao_entry()
#
#
####################################################################
FUNCTION create_kao_entry() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_mask_code CHAR(18) 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_trans_type CHAR(1) 
	DEFINE l_error SMALLINT 
	DEFINE l_ar_per DECIMAL(6,3) 
	--DEFINE l_setup_head_ind SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_rec_kao RECORD 
		cust_code CHAR(10) , ## customer code 
		trans_type CHAR(1) , ## transaction type 
		doc_num CHAR(10) , ## invoice / credit no. 
		ord_num CHAR(5) , 
		doc_date DATE , ## transaction DATE 
		goods_amt DECIMAL(16,2), 
		hand_amt DECIMAL(16,2), 
		freight_amt DECIMAL(16,2), 
		tax_amt DECIMAL(16,2), 
		inv_amt DECIMAL(16,2), 
		ship_date DATE, 
		ship_code CHAR(5), ## customer store_code 
		ware_code CHAR(3), ## customer store_code 
		ref_text CHAR(10), ## customer reference 
		tax_text CHAR(10) ## customer reference 
	END RECORD 

	DEFINE l_rec_kaodetl RECORD 
		doc_num CHAR(10), 
		line_num CHAR(3), 
		part_code CHAR(15), 
		desc_text CHAR(30), 
		ord_qty FLOAT, 
		ship_qty FLOAT, 
		back_qty FLOAT, 
		unit_cost_amt DECIMAL(16,4), 
		disc1_amt DECIMAL(16,4), 
		disc2_amt DECIMAL(16,4), 
		disc3_amt DECIMAL(16,4), 
		unit_price_amt DECIMAL(16,4), 
		ext_price_amt DECIMAL(16,4), 
		ext_tax_amt DECIMAL(16,4), 
		comm_amt DECIMAL(16,4), 
		list_amt DECIMAL(16,4) 
	END RECORD 
	DEFINE l_conv_qty LIKE rate_exchange.conv_buy_qty 
	DEFINE l_acct_text CHAR(50) ## status OF coa account 

	LET modu_ar_cnt = 0 
	LET l_ar_per = 0 
	#
	# count total no. of records
	#
	SELECT count(*) INTO modu_process_cnt 
	FROM t_kao 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	#
	# count total no. of invoices / credits TO be generated
	#
	SELECT count(*) tran_cnt 
	FROM t_kao 
	WHERE cust_code IS NOT NULL 
	AND trans_type IS NOT NULL 
	AND doc_num IS NOT NULL 
	AND doc_date IS NOT NULL 
	AND inv_amt IS NOT NULL 
	AND cust_code != ' ' 
	AND trans_type != ' ' 
	AND doc_num != ' ' 
	AND doc_date != ' ' 
	AND inv_amt != ' ' 
	GROUP BY cust_code, 
	trans_type, 
	doc_num 
	INTO temp t_trancnt 
	SELECT count(*) INTO modu_kao_ar_cnt 
	FROM t_trancnt 
	IF modu_kao_ar_cnt IS NULL THEN 
		LET modu_kao_ar_cnt = 0 
	END IF 
	IF NOT modu_kao_ar_cnt THEN 
		LET glob_err_message = "No AR Invoices / Credits TO be generated" 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 

		RETURN 
	END IF 
	#
	# IF currency AUD NOT SET up THEN do NOT perform load
	#
	SELECT 1 FROM currency 
	WHERE currency_code = 'AUD' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET glob_err_cnt = glob_err_cnt + 1 
		LET glob_err_message = "Currency: AUD NOT SET up" 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 

		RETURN 
	END IF 
	#
	#
	#
	#
	# Declare dynamic CURSOR
	#
	LET l_query_text = " SELECT * FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND delete_flag = 'N' ", 
	" FOR UPDATE " 
	PREPARE s1_customer FROM l_query_text 
	DECLARE c1_customer CURSOR with HOLD FOR s1_customer 
	LET l_query_text = " SELECT * FROM invoicehead ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND purchase_code = ? " 
	PREPARE s1_invoice FROM l_query_text 
	DECLARE c1_invoice CURSOR FOR s1_invoice 
	LET l_query_text = " SELECT * FROM credithead ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND cred_text = ? " 
	PREPARE s1_credit FROM l_query_text 
	DECLARE c1_credit CURSOR FOR s1_credit 
	#
	# Product Status
	#
	LET l_query_text = " SELECT * FROM prodstatus ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND part_code = ? ", 
	" AND ware_code = ? ", 
	" FOR UPDATE " 
	PREPARE s1_prodstatus FROM l_query_text 
	DECLARE c1_prodstatus CURSOR FOR s1_prodstatus 
	#
	# Create AR Invoices / Credits
	#
	#
	DECLARE c2_kao CURSOR with HOLD FOR 
	SELECT * FROM t_kao 
	WHERE cust_code IS NOT NULL 
	AND trans_type IS NOT NULL 
	AND doc_num IS NOT NULL 
	AND doc_date IS NOT NULL 
	AND inv_amt IS NOT NULL 
	AND cust_code != ' ' 
	AND trans_type != ' ' 
	AND doc_num != ' ' 
	AND doc_date != ' ' 
	AND inv_amt != ' ' 
	ORDER BY 1, 2, 3 
	DECLARE c_kaodetl CURSOR FOR 
	SELECT * FROM t_kaodetl 
	WHERE doc_num = l_rec_kao.doc_num 
	FOREACH c2_kao INTO l_rec_kao.* 
		LET l_cust_code = l_rec_kao.cust_code 
		LET l_inv_num = l_rec_kao.doc_num 
		LET l_trans_type = l_rec_kao.trans_type 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF glob_verbose_indv THEN 
				#8004 Do you wish TO quit (Y/N) ?
				IF kandoomsg("A",8004,"") = 'Y' THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
		END IF 
		#
		# Calculate percentage complete
		#
		LET modu_ar_cnt = modu_ar_cnt + 1 
		LET l_ar_per = ( modu_ar_cnt / modu_kao_ar_cnt ) * 100 
		IF glob_verbose_indv THEN 
			DISPLAY l_ar_per TO ar_per 

		END IF 
		#
		#
		#
		IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
			GOTO bypass 
			LABEL recovery: 
			IF retry_lock(glob_rec_kandoouser.cmpy_code,status) > 0 THEN 
				ROLLBACK WORK 
			ELSE 
				IF glob_verbose_indv THEN 
					IF error_recover(glob_err_message,status) != 'Y' THEN 
						LET glob_err_cnt = glob_err_cnt + 1 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
						
						CONTINUE FOREACH 
					END IF 
				ELSE 
					LET glob_err_cnt = glob_err_cnt + 1 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
 
					LET glob_err_text = "ASL - ",err_get(STATUS) 
					CALL errorlog( glob_err_text ) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				INITIALIZE l_rec_customer.* TO NULL 
				OPEN c1_customer USING l_cust_code 
				LET glob_err_message = "Error retrieving customer ",l_cust_code 
				FETCH c1_customer INTO l_rec_customer.* 
				IF sqlca.sqlcode = NOTFOUND THEN 
					#
					# all related detail lines will be skipped
					#
					IF glob_verbose_indv THEN 
						#
						# Hide previous descriptions
						#
						DISPLAY BY NAME l_rec_customer.name_text 

					END IF 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Customer code NOT SET up" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				IF glob_verbose_indv THEN 
					DISPLAY BY NAME l_rec_customer.cust_code, 
					l_rec_customer.name_text 

				END IF 

				CASE l_rec_kao.trans_type 
					WHEN 'I' 
						#
						# Set up Invoicehead
						#
						OPEN c1_invoice USING l_rec_kao.cust_code,l_rec_kao.doc_num 
						FETCH c1_invoice INTO glob_rec_invoicehead.* 
						IF status = 0 THEN 
							CLOSE c1_invoice 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Invoice already exists FOR ref:",l_rec_kao.doc_num 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						CLOSE c1_invoice 
						INITIALIZE glob_rec_invoicehead.* TO NULL 
						LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET glob_rec_invoicehead.cust_code = l_rec_kao.cust_code 
						LET glob_rec_invoicehead.inv_num = 
						next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,"" ) 
						IF glob_rec_invoicehead.inv_num < 0 THEN 
							LET status = glob_rec_invoicehead.inv_num 
							GOTO recovery 
						END IF 
						LET glob_rec_invoicehead.org_cust_code = l_rec_customer.corp_cust_code 
						IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
							SELECT unique 1 FROM customer 
							WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
							AND cust_code = glob_rec_invoicehead.org_cust_code 
							IF sqlca.sqlcode = 0 THEN 
								LET glob_rec_invoicehead.org_cust_code = glob_rec_invoicehead.cust_code 
								LET glob_rec_invoicehead.cust_code = l_rec_customer.corp_cust_code 
							END IF 
						END IF 
						LET glob_rec_invoicehead.ord_num = l_rec_kao.ord_num 
						LET glob_rec_invoicehead.purchase_code = l_rec_kao.doc_num 
						LET glob_rec_invoicehead.job_code = NULL 
						LET glob_rec_invoicehead.inv_date = l_rec_kao.doc_date 
						LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
						LET glob_rec_invoicehead.entry_date = today 
						LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
						LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
						LET glob_rec_invoicehead.disc_per = 0 
						LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
						LET glob_rec_invoicehead.tax_per = 0 
						LET glob_rec_invoicehead.goods_amt = l_rec_kao.goods_amt 
						IF glob_rec_invoicehead.goods_amt IS NULL THEN 
							LET glob_rec_invoicehead.goods_amt = 0 
						END IF 
						LET glob_rec_invoicehead.hand_amt = l_rec_kao.hand_amt 
						IF glob_rec_invoicehead.hand_amt IS NULL THEN 
							LET glob_rec_invoicehead.hand_amt = 0 
						END IF 
						LET glob_rec_invoicehead.hand_tax_code = l_rec_customer.tax_code 
						LET glob_rec_invoicehead.hand_tax_amt = 0 
						LET glob_rec_invoicehead.freight_amt = l_rec_kao.freight_amt 
						IF glob_rec_invoicehead.freight_amt IS NULL THEN 
							LET glob_rec_invoicehead.freight_amt = 0 
						END IF 
						LET glob_rec_invoicehead.freight_tax_code = l_rec_customer.tax_code 
						LET glob_rec_invoicehead.freight_tax_amt = 0 
						LET glob_rec_invoicehead.tax_amt = l_rec_kao.tax_amt 
						IF glob_rec_invoicehead.tax_amt IS NULL THEN 
							LET glob_rec_invoicehead.tax_amt = 0 
						END IF 
						LET glob_rec_invoicehead.disc_amt = 0 
						LET glob_rec_invoicehead.total_amt = l_rec_kao.inv_amt 
						LET glob_rec_invoicehead.cost_amt = 0 
						LET glob_rec_invoicehead.paid_amt = 0 
						LET glob_rec_invoicehead.paid_date = NULL 
						LET glob_rec_invoicehead.disc_taken_amt = 0 
						LET glob_rec_invoicehead.expected_date = NULL 
						LET glob_rec_invoicehead.on_state_flag = 'Y' 
						LET glob_rec_invoicehead.posted_flag = 'N' 
						LET glob_rec_invoicehead.seq_num = 0 
						LET glob_rec_invoicehead.line_num = 0 
						LET glob_rec_invoicehead.printed_num = 1 
						LET glob_rec_invoicehead.story_flag = 'N' 
						LET glob_rec_invoicehead.rev_date = glob_rec_invoicehead.inv_date 
						LET glob_rec_invoicehead.rev_num = 0 
						LET glob_rec_invoicehead.ship_code = l_rec_kao.cust_code 
						LET glob_rec_invoicehead.name_text = NULL 
						LET glob_rec_invoicehead.addr1_text = NULL 
						LET glob_rec_invoicehead.addr2_text = NULL 
						LET glob_rec_invoicehead.city_text = NULL 
						LET glob_rec_invoicehead.state_code = NULL 
						LET glob_rec_invoicehead.post_code = NULL 
						LET glob_rec_invoicehead.country_code = l_rec_customer.country_code 
						LET glob_rec_invoicehead.ship1_text = NULL 
						LET glob_rec_invoicehead.ship2_text = NULL 
						LET glob_rec_invoicehead.ship_date = l_rec_kao.ship_date 
						LET glob_rec_invoicehead.fob_text = NULL 
						LET glob_rec_invoicehead.prepaid_flag = "N" 
						LET glob_rec_invoicehead.com1_text = l_rec_kao.ship_code 
						LET glob_rec_invoicehead.com2_text = l_rec_kao.ref_text 
						LET glob_rec_invoicehead.tax_cert_text = l_rec_kao.tax_text 
						LET glob_rec_invoicehead.cost_ind = 'L' 
						LET glob_rec_invoicehead.currency_code = 'AUD' 
						LET glob_rec_invoicehead.conv_qty = 1 
						
						CALL get_conv_rate( 
							glob_rec_kandoouser.cmpy_code, 
							glob_rec_invoicehead.currency_code, 
							glob_rec_invoicehead.inv_date, 
							CASH_EXCHANGE_BUY ) 
						RETURNING l_conv_qty 
						
						IF l_conv_qty != glob_rec_invoicehead.conv_qty THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Exchange rate FOR AUD Currency ", 
							"invalid on ",glob_rec_invoicehead.inv_date 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
 
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						LET glob_rec_invoicehead.inv_ind = "X" 
						LET glob_rec_invoicehead.prev_paid_amt = 0 
						LET glob_rec_invoicehead.acct_override_code = NULL 
						LET glob_rec_invoicehead.price_tax_flag = '0' 
						LET glob_rec_invoicehead.contact_text = NULL 
						LET glob_rec_invoicehead.tele_text = NULL 
						LET glob_rec_invoicehead.mobile_phone = NULL
						LET glob_rec_invoicehead.email = NULL
						LET glob_rec_invoicehead.invoice_to_ind = l_rec_customer.invoice_to_ind 
						LET glob_rec_invoicehead.territory_code = l_rec_customer.territory_code 
						LET glob_rec_invoicehead.cond_code = l_rec_customer.cond_code 
						LET glob_rec_invoicehead.scheme_amt = 0 
						LET glob_rec_invoicehead.jour_num = NULL 
						LET glob_rec_invoicehead.post_date = NULL 
						LET glob_rec_invoicehead.carrier_code = NULL 
						LET glob_rec_invoicehead.manifest_num = NULL 
						LET glob_rec_invoicehead.stat_date = NULL 
						SELECT mgr_code INTO glob_rec_invoicehead.mgr_code 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
						AND sale_code = l_rec_customer.sale_code 
						SELECT area_code INTO glob_rec_invoicehead.area_code 
						FROM territory 
						WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
						AND terr_code = l_rec_customer.territory_code 
						CALL get_fiscal_year_period_for_date( glob_rec_invoicehead.cmpy_code, 
						glob_rec_invoicehead.inv_date ) 
						RETURNING glob_rec_invoicehead.year_num, 
						glob_rec_invoicehead.period_num 
						IF glob_rec_invoicehead.year_num IS NULL 
						OR glob_rec_invoicehead.period_num IS NULL THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = 
							"Fiscal Year/Period NOT SET up ", 
							"FOR Inv. Date:",glob_rec_invoicehead.inv_date 
							USING "dd/mm/yy" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						SELECT * INTO l_rec_term.* 
						FROM term 
						WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
						AND term_code = glob_rec_invoicehead.term_code 
						IF sqlca.sqlcode = 0 THEN 
							CALL get_due_and_discount_date( l_rec_term.*, glob_rec_invoicehead.inv_date ) 
							RETURNING glob_rec_invoicehead.due_date, 
							glob_rec_invoicehead.disc_date 
						ELSE 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Term code: ",glob_rec_invoicehead.term_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET glob_rec_invoicehead.due_date = glob_rec_invoicehead.inv_date 
							LET glob_rec_invoicehead.disc_date = glob_rec_invoicehead.inv_date 
						END IF 
					WHEN 'C' 
						#
						# Set up Credithead
						#
						SELECT * INTO l_rec_credithead.* 
						FROM credithead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_rec_kao.cust_code 
						AND cred_text = l_rec_kao.doc_num 
						IF status = 0 THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Credit already exists FOR ref:",l_rec_kao.doc_num 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						INITIALIZE l_rec_credithead.* TO NULL 
						LET l_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_credithead.cust_code = l_rec_kao.cust_code 
						LET l_rec_credithead.cred_num = 
						next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,"" ) 
						IF l_rec_credithead.cred_num < 0 THEN 
							LET status = l_rec_credithead.cred_num 
							GOTO recovery 
						END IF 
						LET l_rec_credithead.org_cust_code = l_rec_customer.corp_cust_code 
						IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
							SELECT unique 1 FROM customer 
							WHERE cmpy_code = l_rec_credithead.cmpy_code 
							AND cust_code = l_rec_credithead.org_cust_code 
							IF sqlca.sqlcode = 0 THEN 
								LET l_rec_credithead.org_cust_code = 
								l_rec_credithead.cust_code 
								LET l_rec_credithead.cust_code = 
								l_rec_customer.corp_cust_code 
							END IF 
						END IF 
						LET l_rec_credithead.rma_num = l_rec_kao.ord_num 
						LET l_rec_credithead.cred_text = l_rec_kao.doc_num 
						LET l_rec_credithead.job_code = NULL 
						LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_credithead.entry_date = today 
						LET l_rec_credithead.cred_date = l_rec_kao.doc_date 
						LET l_rec_credithead.sale_code = l_rec_customer.sale_code 
						LET l_rec_credithead.tax_code = l_rec_customer.tax_code 
						LET l_rec_credithead.tax_per = 0 
						LET l_rec_credithead.goods_amt = l_rec_kao.goods_amt 
						IF l_rec_credithead.goods_amt IS NULL THEN 
							LET l_rec_credithead.goods_amt = 0 
						END IF 
						LET l_rec_credithead.hand_amt = l_rec_kao.hand_amt 
						IF l_rec_credithead.hand_amt IS NULL THEN 
							LET l_rec_credithead.hand_amt = 0 
						END IF 
						LET l_rec_credithead.hand_tax_code = l_rec_customer.tax_code 
						LET l_rec_credithead.hand_tax_amt = 0 
						LET l_rec_credithead.freight_amt = l_rec_kao.freight_amt 
						IF l_rec_credithead.freight_amt IS NULL THEN 
							LET l_rec_credithead.freight_amt = 0 
						END IF 
						LET l_rec_credithead.freight_tax_code = l_rec_customer.tax_code 
						LET l_rec_credithead.freight_tax_amt = 0 
						LET l_rec_credithead.tax_amt = l_rec_kao.tax_amt 
						IF l_rec_credithead.tax_amt IS NULL THEN 
							LET l_rec_credithead.tax_amt = 0 
						END IF 
						LET l_rec_credithead.total_amt = l_rec_kao.inv_amt 
						LET l_rec_credithead.cost_amt = 0 
						LET l_rec_credithead.appl_amt = 0 
						LET l_rec_credithead.disc_amt = 0 
						LET l_rec_credithead.on_state_flag = 'Y' 
						LET l_rec_credithead.posted_flag = 'N' 
						LET l_rec_credithead.next_num = 0 
						LET l_rec_credithead.line_num = 0 
						LET l_rec_credithead.printed_num = 0 
						LET l_rec_credithead.com1_text = l_rec_kao.ship_code 
						LET l_rec_credithead.com2_text = l_rec_kao.ref_text 
						LET l_rec_credithead.rev_date = today 
						LET l_rec_credithead.rev_num = 0 
						LET l_rec_credithead.cost_ind = NULL 
						LET l_rec_credithead.currency_code = 'AUD' 
						LET l_rec_credithead.conv_qty = 1 
						CALL get_conv_rate( 
							glob_rec_kandoouser.cmpy_code, 
							l_rec_credithead.currency_code, 
							l_rec_credithead.cred_date, 
							CASH_EXCHANGE_BUY ) 
						RETURNING l_conv_qty 
						
						IF l_conv_qty != l_rec_credithead.conv_qty THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Exchange rate FOR AUD Currency ",	"invalid on ",l_rec_credithead.cred_date 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						LET l_rec_credithead.cred_ind = 'X' 
						LET l_rec_credithead.acct_override_code = NULL 
						LET l_rec_credithead.price_tax_flag = '0' 
						LET l_rec_credithead.reason_code = NULL 
						LET l_rec_credithead.jour_num = NULL 
						LET l_rec_credithead.post_date = NULL 
						LET l_rec_credithead.stat_date = NULL 
						LET l_rec_credithead.address_to_ind = NULL 
						LET l_rec_credithead.cond_code = NULL 
						CALL get_fiscal_year_period_for_date( l_rec_credithead.cmpy_code, 
						l_rec_credithead.cred_date ) 
						RETURNING l_rec_credithead.year_num, 
						l_rec_credithead.period_num 
						IF l_rec_credithead.year_num IS NULL 
						OR l_rec_credithead.period_num IS NULL THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = 
							"Fiscal Year/Period NOT SET up ", 
							"FOR Cred. Date:",l_rec_credithead.cred_date 
							USING "dd/mm/yy" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						SELECT mgr_code INTO l_rec_credithead.mgr_code 
						FROM salesperson 
						WHERE cmpy_code = l_rec_credithead.cmpy_code 
						AND sale_code = l_rec_customer.sale_code 
						SELECT area_code INTO l_rec_credithead.area_code 
						FROM territory 
						WHERE cmpy_code = l_rec_credithead.cmpy_code 
						AND terr_code = l_rec_customer.territory_code 
					OTHERWISE 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Invalid Transaction Type: ", 
						l_rec_kao.trans_type, " detected" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
 
						ROLLBACK WORK 
						CONTINUE FOREACH 
				END CASE 
				FOREACH c_kaodetl INTO l_rec_kaodetl.* 
					LET l_error = false 
					IF l_rec_kao.trans_type = 'I' THEN 
						#
						# Invoicedetl
						#
						INITIALIZE l_rec_invoicedetl.* TO NULL 
						LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
						LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
						LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
						LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
						LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
						LET l_rec_invoicedetl.part_code = l_rec_kaodetl.part_code 
						SELECT * INTO l_rec_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_kaodetl.part_code 
						IF status = NOTFOUND THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Product ", 
							l_rec_kaodetl.part_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET l_error = true 
							EXIT FOREACH 
						END IF 
						LET l_rec_invoicedetl.ware_code = l_rec_kao.ware_code 
						SELECT * INTO l_rec_warehouse.* 
						FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = l_rec_kao.ware_code 
						IF status = NOTFOUND THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Ware ", 
							l_rec_kao.ware_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET l_error = true 
							EXIT FOREACH 
						END IF 
						OPEN c1_prodstatus USING l_rec_kaodetl.part_code, 
						l_rec_kao.ware_code 
						FETCH c1_prodstatus INTO l_rec_prodstatus.* 
						IF status = NOTFOUND THEN 
							CLOSE c1_prodstatus 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Prodstat ", 
							l_rec_kaodetl.part_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET l_error = true 
							EXIT FOREACH 
						END IF 
						LET l_rec_invoicedetl.cat_code = l_rec_product.cat_code 
						LET l_rec_invoicedetl.ord_qty = l_rec_kaodetl.ord_qty 
						LET l_rec_invoicedetl.ship_qty = l_rec_kaodetl.ship_qty 
						LET l_rec_invoicedetl.prev_qty = 0 
						LET l_rec_invoicedetl.back_qty = l_rec_kaodetl.back_qty 
						LET l_rec_invoicedetl.ser_flag = 'N' 
						LET l_rec_invoicedetl.ser_qty = 0 
						IF length(l_rec_kaodetl.desc_text) > 0 THEN 
							LET l_rec_invoicedetl.line_text = l_rec_kaodetl.desc_text 
						ELSE 
							LET l_rec_invoicedetl.line_text = l_rec_product.desc_text 
						END IF 
						LET l_rec_invoicedetl.uom_code = "EA" 
						LET l_rec_invoicedetl.unit_cost_amt = l_rec_kaodetl.unit_cost_amt 
						LET l_rec_invoicedetl.ext_cost_amt = l_rec_kaodetl.unit_cost_amt * 
						l_rec_kaodetl.ship_qty 
						LET l_rec_invoicedetl.disc_amt = l_rec_kaodetl.disc1_amt + 
						l_rec_kaodetl.disc2_amt + 
						l_rec_kaodetl.disc3_amt 
						LET l_rec_invoicedetl.disc_per = 0 
						LET l_rec_invoicedetl.unit_sale_amt = l_rec_kaodetl.unit_price_amt 
						LET l_rec_invoicedetl.ext_sale_amt = l_rec_kaodetl.ext_price_amt 
						LET l_rec_invoicedetl.unit_tax_amt = l_rec_kaodetl.ext_tax_amt / 
						l_rec_kaodetl.ship_qty 
						LET l_rec_invoicedetl.ext_tax_amt = l_rec_kaodetl.ext_tax_amt 
						LET l_rec_invoicedetl.line_total_amt = l_rec_kaodetl.ext_price_amt 
						LET l_rec_invoicedetl.seq_num = NULL 
						LET l_rec_invoicedetl.level_code = 'L' 
						LET l_rec_invoicedetl.comm_amt = 0 
						LET l_rec_invoicedetl.comp_per = NULL 
						LET l_rec_invoicedetl.tax_code = l_rec_customer.tax_code 
						LET l_rec_invoicedetl.order_line_num = NULL 
						LET l_rec_invoicedetl.order_num = NULL 
						LET l_rec_invoicedetl.offer_code = NULL 
						LET l_rec_invoicedetl.sold_qty = 1 
						LET l_rec_invoicedetl.bonus_qty = 0 
						LET l_rec_invoicedetl.ext_bonus_amt = 0 
						LET l_rec_invoicedetl.ext_stats_amt = 0 
						LET l_rec_invoicedetl.list_price_amt = 0 
						LET l_rec_invoicedetl.prodgrp_code = l_rec_product.prodgrp_code 
						LET l_rec_invoicedetl.maingrp_code = l_rec_product.maingrp_code 
						SELECT dept_code INTO l_rec_invoicedetl.proddept_code 
						FROM maingrp 
						WHERE maingrp_code = l_rec_invoicedetl.maingrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						SELECT acct_mask_code INTO l_mask_code 
						FROM warehouse 
						WHERE ware_code = l_rec_invoicedetl.ware_code 
						AND cmpy_code = l_rec_invoicedetl.cmpy_code 
						LET l_rec_invoicedetl.line_acct_code = 
						build_mask( glob_rec_kandoouser.cmpy_code, l_rec_invoicedetl.line_acct_code, 
						l_mask_code ) 
						SELECT sale_acct_code INTO l_mask_code 
						FROM category, product 
						WHERE part_code = l_rec_invoicedetl.part_code 
						AND category.cat_code = product.cat_code 
						AND product.cmpy_code = l_rec_invoicedetl.cmpy_code 
						AND category.cmpy_code = l_rec_invoicedetl.cmpy_code 
						LET l_rec_invoicedetl.line_acct_code = 
						build_mask( glob_rec_kandoouser.cmpy_code, l_rec_invoicedetl.line_acct_code, 
						l_mask_code ) 
						#
						# Update Product Status record
						#
						LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
						LET l_rec_invoicedetl.seq_num = l_rec_prodstatus.seq_num 
						LET glob_err_message = "ASL - Error Updating Prodstatus" 
						IF l_rec_prodstatus.stocked_flag = "Y" THEN 
							UPDATE prodstatus 
							SET seq_num = l_rec_prodstatus.seq_num, 
							onhand_qty = onhand_qty 
							- l_rec_invoicedetl.ship_qty, 
							last_sale_date = glob_rec_invoicehead.inv_date 
							WHERE cmpy_code = l_rec_invoicedetl.cmpy_code 
							AND part_code = l_rec_invoicedetl.part_code 
							AND ware_code = l_rec_invoicedetl.ware_code 
						ELSE 
							UPDATE prodstatus 
							SET seq_num = l_rec_prodstatus.seq_num, 
							last_sale_date = glob_rec_invoicehead.inv_date 
							WHERE cmpy_code = l_rec_invoicedetl.cmpy_code 
							AND part_code = l_rec_invoicedetl.part_code 
							AND ware_code = l_rec_invoicedetl.ware_code 
						END IF 
						CLOSE c1_prodstatus 
						INITIALIZE l_rec_prodledg.* TO NULL 
						LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
						LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
						LET l_rec_prodledg.tran_date = glob_rec_invoicehead.inv_date 
						LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
						LET l_rec_prodledg.trantype_ind= 'S' 
						LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
						LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
						LET l_rec_prodledg.source_text = glob_rec_invoicehead.cust_code 
						LET l_rec_prodledg.source_num = glob_rec_invoicehead.inv_num 
						LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty 
						LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt 
						/ glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt 
						/ glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.hist_flag = 'Y' 
						LET l_rec_prodledg.post_flag = 'N' 
						LET l_rec_prodledg.acct_code = NULL 
						LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
						- l_rec_invoicedetl.ship_qty 
						LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_prodledg.entry_date = glob_rec_loadparms.load_date 
						LET glob_err_message = "ASL - Error inserting product ledger entry" 
						INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
						#
						# Invoicedetl INSERT
						#
						LET glob_err_message = "ASL - Error inserting Invoice detail"

						#INSERT invoiceDetl Record
						IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
							INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
						ELSE
							DISPLAY l_rec_invoicedetl.*
							CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
						END IF 

						#
					ELSE 

						#------------------
						# Creditdetl
						#
						INITIALIZE l_rec_creditdetl.* TO NULL
						 
						LET l_rec_credithead.line_num = l_rec_credithead.line_num + 1 
						LET l_rec_creditdetl.cmpy_code = l_rec_credithead.cmpy_code 
						LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
						LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
						LET l_rec_creditdetl.line_num = l_rec_credithead.line_num 
						LET l_rec_creditdetl.part_code = l_rec_kaodetl.part_code 
						
						SELECT * INTO l_rec_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_kaodetl.part_code 
						IF status = NOTFOUND THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Product ", 
							l_rec_kaodetl.part_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET l_error = true 
							EXIT FOREACH 
						END IF 
						LET l_rec_creditdetl.ware_code = l_rec_kao.ware_code 
						SELECT * INTO l_rec_warehouse.* 
						FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = l_rec_kao.ware_code 
						IF status = NOTFOUND THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Ware ", 
							l_rec_kao.ware_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 
 
							LET l_error = true 
							EXIT FOREACH 
						END IF 
						OPEN c1_prodstatus USING l_rec_kaodetl.part_code, 
						l_rec_kao.ware_code 
						FETCH c1_prodstatus INTO l_rec_prodstatus.* 
						IF status = NOTFOUND THEN 
							CLOSE c1_prodstatus 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Prodstat ", 
							l_rec_kaodetl.part_code clipped, " NOT setup" 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

							LET l_error = true 
							EXIT FOREACH 
						END IF 
						LET l_rec_creditdetl.cat_code = l_rec_product.cat_code 
						LET l_rec_creditdetl.ship_qty = l_rec_kaodetl.ship_qty 
						IF length(l_rec_kaodetl.desc_text) > 0 THEN 
							LET l_rec_creditdetl.line_text = l_rec_kaodetl.desc_text 
						ELSE 
							LET l_rec_creditdetl.line_text = l_rec_product.desc_text 
						END IF 
						LET l_rec_creditdetl.uom_code = "EA" 
						LET l_rec_creditdetl.unit_cost_amt = l_rec_kaodetl.unit_cost_amt 
						LET l_rec_creditdetl.ext_cost_amt = l_rec_kaodetl.unit_cost_amt * 
						l_rec_kaodetl.ship_qty 
						LET l_rec_creditdetl.disc_amt = l_rec_kaodetl.disc1_amt + 
						l_rec_kaodetl.disc2_amt + 
						l_rec_kaodetl.disc3_amt 
						LET l_rec_creditdetl.unit_sales_amt = l_rec_kaodetl.unit_price_amt 
						LET l_rec_creditdetl.ext_sales_amt = l_rec_kaodetl.ext_price_amt 
						LET l_rec_creditdetl.unit_tax_amt = l_rec_kaodetl.ext_tax_amt / 
						l_rec_kaodetl.ship_qty 
						LET l_rec_creditdetl.ext_tax_amt = l_rec_kaodetl.ext_tax_amt 
						LET l_rec_creditdetl.line_total_amt = l_rec_kaodetl.ext_price_amt 
						LET l_rec_creditdetl.seq_num = NULL 
						LET l_rec_creditdetl.level_code = 'L' 
						LET l_rec_creditdetl.comm_amt = 0 
						LET l_rec_creditdetl.tax_code = l_rec_customer.tax_code 
						LET l_rec_creditdetl.prodgrp_code = l_rec_product.prodgrp_code 
						LET l_rec_creditdetl.maingrp_code = l_rec_product.maingrp_code 
						SELECT dept_code INTO l_rec_creditdetl.proddept_code 
						FROM maingrp 
						WHERE maingrp_code = l_rec_creditdetl.maingrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						SELECT acct_mask_code INTO l_mask_code 
						FROM warehouse 
						WHERE ware_code = l_rec_creditdetl.ware_code 
						AND cmpy_code = l_rec_creditdetl.cmpy_code 
						LET l_rec_creditdetl.line_acct_code = 
						build_mask( glob_rec_kandoouser.cmpy_code, l_rec_creditdetl.line_acct_code, 
						l_mask_code ) 
						SELECT sale_acct_code INTO l_mask_code 
						FROM category, product 
						WHERE part_code = l_rec_creditdetl.part_code 
						AND category.cat_code = product.cat_code 
						AND product.cmpy_code = l_rec_creditdetl.cmpy_code 
						AND category.cmpy_code = l_rec_creditdetl.cmpy_code 
						LET l_rec_creditdetl.line_acct_code = 
						build_mask( glob_rec_kandoouser.cmpy_code, l_rec_creditdetl.line_acct_code, 
						l_mask_code ) 
						#
						# Update Product Status record
						#
						LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
						LET l_rec_creditdetl.seq_num = l_rec_prodstatus.seq_num 
						LET glob_err_message = "ASL - Error Updating Prodstatus" 
						IF l_rec_prodstatus.stocked_flag = "Y" THEN 
							UPDATE prodstatus 
							SET seq_num = l_rec_prodstatus.seq_num, 
							onhand_qty = onhand_qty 
							- l_rec_creditdetl.ship_qty, 
							last_sale_date = l_rec_credithead.cred_date 
							WHERE cmpy_code = l_rec_creditdetl.cmpy_code 
							AND part_code = l_rec_creditdetl.part_code 
							AND ware_code = l_rec_creditdetl.ware_code 
						ELSE 
							UPDATE prodstatus 
							SET seq_num = l_rec_prodstatus.seq_num, 
							last_sale_date = l_rec_credithead.cred_date 
							WHERE cmpy_code = l_rec_creditdetl.cmpy_code 
							AND part_code = l_rec_creditdetl.part_code 
							AND ware_code = l_rec_creditdetl.ware_code 
						END IF 
						CLOSE c1_prodstatus 
						INITIALIZE l_rec_prodledg.* TO NULL 
						LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_prodledg.part_code = l_rec_creditdetl.part_code 
						LET l_rec_prodledg.ware_code = l_rec_creditdetl.ware_code 
						LET l_rec_prodledg.tran_date = l_rec_credithead.cred_date 
						LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
						LET l_rec_prodledg.trantype_ind= 'S' 
						LET l_rec_prodledg.year_num = l_rec_credithead.year_num 
						LET l_rec_prodledg.period_num = l_rec_credithead.period_num 
						LET l_rec_prodledg.source_text = l_rec_credithead.cust_code 
						LET l_rec_prodledg.source_num = l_rec_credithead.cred_num 
						LET l_rec_prodledg.tran_qty = l_rec_creditdetl.ship_qty 
						LET l_rec_prodledg.cost_amt = l_rec_creditdetl.unit_cost_amt 
						/ l_rec_credithead.conv_qty 
						LET l_rec_prodledg.sales_amt = l_rec_creditdetl.unit_sales_amt 
						/ l_rec_credithead.conv_qty 
						LET l_rec_prodledg.hist_flag = 'Y' 
						LET l_rec_prodledg.post_flag = 'N' 
						LET l_rec_prodledg.acct_code = NULL 
						LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
						- l_rec_creditdetl.ship_qty 
						LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_prodledg.entry_date = glob_rec_loadparms.load_date 
						LET glob_err_message = "ASL - Error inserting product ledger entry" 
						INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
						LET l_rec_creditdetl.tax_code = l_rec_customer.tax_code 
						LET l_rec_creditdetl.reason_code = NULL 
						LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
						LET l_rec_creditdetl.invoice_num = 0 
						LET l_rec_creditdetl.inv_line_num = 0 
						LET l_rec_creditdetl.price_uom_code = NULL 
						LET l_rec_creditdetl.km_qty = 0 
						#
						# Creditdetl INSERT
						#
						LET glob_err_message = "ASL - Error inserting Credit detail" 
						INSERT INTO creditdetl VALUES ( l_rec_creditdetl.* ) 
						#
						#
						#
					END IF 
				END FOREACH 
				IF l_error = true THEN 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				IF l_rec_kao.trans_type = 'I' THEN 
					#
					# Araudit / Customer dependant upon Invoicehead
					#
					IF glob_rec_invoicehead.line_num = 0 OR 
					glob_rec_invoicehead.line_num IS NULL THEN 
						LET glob_err_message = "Invoice has no details lines " 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

						LET glob_err_cnt = glob_err_cnt + 1 
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 

					LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt	+ glob_rec_invoicehead.tax_amt 
					LET glob_err_message = "ASL - Error inserting Invoice" 


					#INSERT invoicehead Record
					IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
						INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
					ELSE
						DISPLAY glob_rec_invoicehead.*
						CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
					END IF 

					#------------------------------------
					# Araudit
					
					INITIALIZE l_rec_araudit.* TO NULL
					 
					LET l_rec_araudit.cmpy_code = glob_rec_invoicehead.cmpy_code 
					LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
					LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_araudit.tran_type_ind = 'IN' 
					LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
					LET l_rec_araudit.tran_text = 'kao invoice' 
					LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
					LET l_rec_araudit.entry_code = glob_rec_invoicehead.entry_code 
					LET l_rec_araudit.sales_code = glob_rec_invoicehead.sale_code 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt + glob_rec_invoicehead.total_amt 
					LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
					LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
					LET l_rec_araudit.currency_code = glob_rec_invoicehead.currency_code 
					LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
					LET l_rec_araudit.entry_date = glob_rec_invoicehead.entry_date 
					LET glob_err_message = "ASL - Error inserting AR audit entry"
					 
					INSERT INTO araudit VALUES (l_rec_araudit.*) 
					#
					# Update customer details
					#
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
					IF year( glob_rec_invoicehead.inv_date ) 
					> year( l_rec_customer.last_inv_date ) THEN 
						LET l_rec_customer.ytds_amt = 0 
						LET l_rec_customer.mtds_amt = 0 
					END IF 
					IF month( glob_rec_invoicehead.inv_date ) 
					> month( l_rec_customer.last_inv_date ) THEN 
						LET l_rec_customer.mtds_amt = 0 
					END IF 
					LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
					+ glob_rec_invoicehead.total_amt 
					LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
					+ glob_rec_invoicehead.total_amt 
					LET l_rec_customer.last_inv_date = glob_rec_invoicehead.inv_date 
					LET glob_err_message = "ASL - Error updating Customer" 
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
					AND cust_code = l_cust_code 
				ELSE 
					#
					# Araudit / Customer dependent upon Credithead
					#
					IF l_rec_credithead.line_num = 0 OR 
					l_rec_credithead.line_num IS NULL THEN 
						LET glob_err_message = "Credit has no details lines " 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_inv_num , 
						glob_err_message ) 
						#--------------------------------------------------------- 

						LET glob_err_cnt = glob_err_cnt + 1 
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
					+ l_rec_credithead.tax_amt 
					LET glob_err_message = "ASL - Error inserting Credit" 
					INSERT INTO credithead VALUES ( l_rec_credithead.* ) 
					#
					# Araudit
					#
					INITIALIZE l_rec_araudit.* TO NULL 
					LET l_rec_araudit.cmpy_code = l_rec_credithead.cmpy_code 
					LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
					LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_araudit.tran_type_ind = 'CR' 
					LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
					LET l_rec_araudit.tran_text = "KAO Credit" 
					LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
					LET l_rec_araudit.entry_code = l_rec_credithead.entry_code 
					LET l_rec_araudit.year_num = l_rec_credithead.year_num 
					LET l_rec_araudit.period_num = l_rec_credithead.period_num 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
					LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
					LET l_rec_araudit.entry_date = l_rec_credithead.entry_date 
					LET glob_err_message = "ASI - Error inserting AR audit entry" 
					INSERT INTO araudit VALUES ( l_rec_araudit.* ) 
					#
					# Update customer details
					#
					LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
					- l_rec_customer.bal_amt 
					LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
					- l_rec_credithead.total_amt 
					LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
					- l_rec_credithead.total_amt 
					IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
						LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
					END IF 
					LET glob_err_message = "ASL - Error updating Customer" 
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
					AND cust_code = l_cust_code 
				END IF 
				DELETE FROM t_kao 
				WHERE cust_code = l_cust_code 
				AND trans_type = l_trans_type 
				AND doc_num = l_inv_num 
			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + 1 
			IF glob_verbose_indv THEN 
				DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt  

			END IF 
			IF l_rec_kao.trans_type = 'I' THEN 
				#---------------------------------------------------------
				#Positive/Sucess Output (not error/exception)
				OUTPUT TO REPORT ASL_rpt_list_5_kao(rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao"),
				glob_rec_invoicehead.cmpy_code, 
				glob_rec_invoicehead.cust_code, 
				l_rec_customer.name_text , 
				glob_rec_invoicehead.inv_num , 
				'' , 
				glob_rec_invoicehead.inv_date , 
				glob_rec_invoicehead.line_num , 
				glob_rec_invoicehead.total_amt )  
				#--------------------------------------------------------- 
 
			ELSE
				#---------------------------------------------------------
				#Positive/Sucess Output (not error/exception)
				OUTPUT TO REPORT ASL_rpt_list_5_kao(rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao"),
				l_rec_credithead.cmpy_code , 
				l_rec_credithead.cust_code , 
				l_rec_customer.name_text , 
				'' , 
				l_rec_credithead.cred_num , 
				l_rec_credithead.cred_date , 
				l_rec_credithead.line_num , 
				l_rec_credithead.total_amt ) 
				#---------------------------------------------------------
 			 
			END IF
		END FOREACH 
END FUNCTION 


####################################################################
# FUNCTION set4_defaults()
#
#
####################################################################
FUNCTION set4_defaults() 
{

	LET glob_rec_kandooreport.header_text = "Invoice Load - LBS TO database - ", 
	today USING "dd/mm/yy" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "ASL" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Company" , 5 spaces, 
	"Customer" , 36 spaces, 
	"Invoice No.", 5 spaces, 
	"Credit No." , 7 spaces, 
	"Date" , 7 spaces, 
	"Total Lines", 9 spaces, 
	"Total Amount" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code
} 
END FUNCTION 



####################################################################
# FUNCTION ASL_rpt_start_5_kao() 
#
#
####################################################################
FUNCTION ASL_rpt_start_5_kao() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_tmp_str STRING
	#------------------------------------------------------------	
	#Report for success
	LET l_rpt_idx = rpt_start("ASL-KAO","ASL_rpt_list_5_kao","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASL_rpt_list_5_kao TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_5_kao")].sel_text
	#------------------------------------------------------------

	LET l_tmp_str = " - (Load No:", glob_rec_loadparms.seq_num using "<<<<<",")"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str) #append load seq number to the right of header line 2
	#------------------------------------------------------------

END FUNCTION 


####################################################################
# FUNCTION ASL_rpt_finish_5_kao() 
#
#
####################################################################
FUNCTION ASL_rpt_finish_5_kao() 

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASL_rpt_list_5_kao
	CALL rpt_finish("ASL_rpt_list_5_kao")
	#------------------------------------------------------------
	
END FUNCTION 


####################################################################
# FUNCTION load_t_kao()
#
#
####################################################################
FUNCTION load_t_kao() 
	DEFINE l_rec_kao RECORD 
		cust_code CHAR(10) , ## customer code 
		trans_type CHAR(1) , ## transaction type 
		doc_num CHAR(10) , ## invoice / credit no. 
		ord_num CHAR(5) , 
		doc_date DATE , ## transaction DATE 
		goods_amt DECIMAL(16,2), 
		hand_amt DECIMAL(16,2), 
		freight_amt DECIMAL(16,2), 
		tax_amt DECIMAL(16,2), 
		inv_amt DECIMAL(16,2), 
		ship_date DATE, 
		ship_code CHAR(5), ## customer store_code 
		ware_code CHAR(3), ## customer store_code 
		ref_text CHAR(10), ## customer reference 
		tax_text CHAR(10) ## customer reference 
	END RECORD 

	DEFINE l_rec_kaodetl RECORD 
		doc_num CHAR(10), 
		line_num CHAR(3), 
		part_code CHAR(15), 
		desc_text CHAR(30), 
		ord_qty FLOAT, 
		ship_qty FLOAT, 
		back_qty FLOAT, 
		unit_cost_amt DECIMAL(16,4), 
		disc1_amt DECIMAL(16,4), 
		disc2_amt DECIMAL(16,4), 
		disc3_amt DECIMAL(16,4), 
		unit_price_amt DECIMAL(16,4), 
		ext_price_amt DECIMAL(16,4), 
		ext_tax_amt DECIMAL(16,4), 
		comm_amt DECIMAL(16,4), 
		list_amt DECIMAL(16,4) 
	END RECORD 
	DEFINE l_count INTEGER 
	DEFINE l_load_text CHAR(256) 
	DEFINE l_rec_rec RECORD 
		t_code CHAR(3), 
		t_type CHAR(1), 
		t_ind CHAR(1) 
	END RECORD 
	DEFINE l_length INTEGER 

	WHENEVER any ERROR GOTO errorhand 
	DECLARE c_load CURSOR FOR 
	SELECT * FROM t_tmpload 
	LET l_count = 0 
	FOREACH c_load INTO l_load_text 
		LET l_count = l_count + 1 
		LET l_rec_rec.t_code = l_load_text[1,3] 
		LET l_rec_rec.t_type = l_load_text[4] 
		LET l_length = length(l_load_text) 
		CASE 
			WHEN l_rec_rec.t_type = "H" #header 
				INITIALIZE l_rec_kao.* TO NULL 
				LET l_rec_kao.cust_code = l_load_text[162,l_length - 1] 
				LET l_rec_kao.trans_type = l_load_text[14] 
				LET l_rec_kao.doc_num = l_load_text[16,25] 
				LET l_rec_kao.ord_num = l_load_text[5,9] 
				LET l_rec_kao.doc_date = conv_date(l_load_text[26,31]) 
				LET l_rec_kao.goods_amt = l_load_text[114,124] 
				LET l_rec_kao.hand_amt = l_load_text[135,142] 
				LET l_rec_kao.freight_amt = l_load_text[143,150] 
				LET l_rec_kao.tax_amt = l_load_text[125,134] 
				LET l_rec_kao.inv_amt = l_load_text[151,161] 
				LET l_rec_kao.ship_date = conv_date(l_load_text[81,86]) 
				LET l_rec_kao.ship_code = l_load_text[40,44] 
				LET l_rec_kao.ware_code = l_load_text[87,89] 
				LET l_rec_kao.ref_text = l_load_text[45,54] 
				LET l_rec_kao.tax_text = l_load_text[65,74] 
				INSERT INTO t_kao VALUES (l_rec_kao.*) 
			WHEN l_rec_rec.t_type = "M" # memo 
				INITIALIZE l_rec_kaodetl.* TO NULL 
				LET l_rec_kaodetl.doc_num = l_load_text[5,14] 
				LET l_rec_kaodetl.line_num = l_load_text[15,17] 
				LET l_rec_kaodetl.desc_text = l_load_text[19,48] 
				UPDATE t_kaodetl SET desc_text = l_rec_kaodetl.desc_text 
				WHERE doc_num = l_rec_kaodetl.doc_num 
				AND line_num = l_rec_kaodetl.line_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO t_kaodetl VALUES (l_rec_kaodetl.*) 
				END IF 
			WHEN l_rec_rec.t_type = "L" # detail 
				INITIALIZE l_rec_kaodetl.* TO NULL 
				LET l_rec_kaodetl.doc_num = l_load_text[5,14] 
				LET l_rec_kaodetl.line_num = l_load_text[15,17] 
				LET l_rec_kaodetl.part_code = l_load_text[21,35] 
				LET l_rec_kaodetl.ord_qty = l_load_text[36,45] 
				IF l_rec_kaodetl.ord_qty IS NULL THEN 
					LET l_rec_kaodetl.ord_qty = 0 
				END IF 
				LET l_rec_kaodetl.ship_qty = l_load_text[46,55] 
				IF l_rec_kaodetl.ship_qty IS NULL THEN 
					LET l_rec_kaodetl.ship_qty = 0 
				END IF 
				LET l_rec_kaodetl.back_qty = l_load_text[56,65] 
				IF l_rec_kaodetl.back_qty IS NULL THEN 
					LET l_rec_kaodetl.back_qty = 0 
				END IF 
				LET l_rec_kaodetl.unit_cost_amt = l_load_text[83,92] 
				IF l_rec_kaodetl.unit_cost_amt IS NULL THEN 
					LET l_rec_kaodetl.unit_cost_amt = 0 
				END IF 
				LET l_rec_kaodetl.disc1_amt = l_load_text[151,159] 
				IF l_rec_kaodetl.disc1_amt IS NULL THEN 
					LET l_rec_kaodetl.disc1_amt = 0 
				END IF 
				LET l_rec_kaodetl.disc2_amt = l_load_text[160,168] 
				IF l_rec_kaodetl.disc2_amt IS NULL THEN 
					LET l_rec_kaodetl.disc2_amt = 0 
				END IF 
				LET l_rec_kaodetl.disc3_amt = l_load_text[169,177] 
				IF l_rec_kaodetl.disc3_amt IS NULL THEN 
					LET l_rec_kaodetl.disc3_amt = 0 
				END IF 
				LET l_rec_kaodetl.unit_price_amt = l_load_text[75,82] 
				IF l_rec_kaodetl.unit_price_amt IS NULL THEN 
					LET l_rec_kaodetl.unit_price_amt = 0 
				END IF 
				LET l_rec_kaodetl.ext_price_amt = l_load_text[196,206] 
				IF l_rec_kaodetl.ext_price_amt IS NULL THEN 
					LET l_rec_kaodetl.ext_price_amt = 0 
				END IF 
				LET l_rec_kaodetl.ext_tax_amt = l_load_text[187,195] 
				IF l_rec_kaodetl.ext_tax_amt IS NULL THEN 
					LET l_rec_kaodetl.ext_tax_amt = 0 
				END IF 
				LET l_rec_kaodetl.comm_amt = l_load_text[207,216] 
				IF l_rec_kaodetl.comm_amt IS NULL THEN 
					LET l_rec_kaodetl.comm_amt = 0 
				END IF 
				LET l_rec_kaodetl.list_amt = l_load_text[67,74] 
				IF l_rec_kaodetl.list_amt IS NULL THEN 
					LET l_rec_kaodetl.list_amt = 0 
				END IF 
				UPDATE t_kaodetl 
				SET part_code = l_rec_kaodetl.part_code, 
				ord_qty = l_rec_kaodetl.ord_qty, 
				ship_qty = l_rec_kaodetl.ship_qty, 
				back_qty = l_rec_kaodetl.back_qty, 
				unit_cost_amt = l_rec_kaodetl.unit_cost_amt, 
				disc1_amt = l_rec_kaodetl.disc1_amt, 
				disc2_amt = l_rec_kaodetl.disc2_amt, 
				disc3_amt = l_rec_kaodetl.disc3_amt, 
				unit_price_amt = l_rec_kaodetl.unit_price_amt, 
				ext_price_amt = l_rec_kaodetl.ext_price_amt, 
				ext_tax_amt = l_rec_kaodetl.ext_tax_amt, 
				comm_amt = l_rec_kaodetl.comm_amt, 
				list_amt = l_rec_kaodetl.list_amt 
				WHERE doc_num = l_rec_kaodetl.doc_num 
				AND line_num = l_rec_kaodetl.line_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO t_kaodetl VALUES (l_rec_kaodetl.*) 
				END IF 
		END CASE 
		LET l_rec_rec.t_ind = l_load_text[14] 

	END FOREACH 
	RETURN true 
	LABEL errorhand: 
	WHENEVER ERROR CONTINUE 
	DELETE FROM t_kao WHERE 1=1; 
	DELETE FROM t_kaodetl WHERE 1=1; 
	LET glob_err_cnt = glob_err_cnt + 1 
	LET glob_err_message = "Error in load file line: ",l_count USING "<<<<<", 
	" Error STATUS: ",STATUS USING "-<<<<<<" 

	#---------------------------------------------------------
	OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
	glob_rec_kandoouser.cmpy_code, 
	l_rec_kao.cust_code , 
	l_rec_kao.doc_num , 
	glob_err_message ) 
	#--------------------------------------------------------- 
	
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN false 
END FUNCTION 




####################################################################
# FUNCTION conv_date(p_date)
#
#
####################################################################
FUNCTION conv_date(p_date) 
	DEFINE p_date CHAR(6) 
	DEFINE l_retdate DATE 
	DEFINE l_date_string CHAR(8) 

	LET l_date_string = p_date[5,6],"/",p_date[3,4],"/",p_date[1,2] 
	LET l_retdate = l_date_string 
	RETURN l_retdate 
END FUNCTION



####################################################################
# REPORT ASL_rpt_list_5_kao(p_rpt_idx,p_cmpy_code, p_cust_code, p_name_text,
#                  p_inv_num  , p_cred_num , p_tran_date,
#                  p_line_num , p_total_amt)
#
#
####################################################################
REPORT ASL_rpt_list_5_kao(p_rpt_idx,p_cmpy_code, p_cust_code, p_name_text, 
	p_inv_num , p_cred_num , p_tran_date, 
	p_line_num , p_total_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE p_tran_date LIKE invoicehead.inv_date 
	DEFINE p_line_num LIKE invoicehead.line_num 
	DEFINE p_total_amt LIKE invoicehead.total_amt 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_cmpy_code, 
	p_cust_code, 
	p_inv_num, 
	p_cred_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
			SKIP 3 LINES 
		ON EVERY ROW 
			PRINT COLUMN 01, p_cmpy_code, 
			COLUMN 13, p_cust_code, 
			COLUMN 22, p_name_text, 
			COLUMN 57, p_inv_num USING "########" , 
			COLUMN 73, p_cred_num USING "########" , 
			COLUMN 88, p_tran_date USING "dd/mm/yy" , 
			COLUMN 104, p_line_num USING "#####" , 
			COLUMN 117, p_total_amt USING "############&.&&" 
		ON LAST ROW 
			NEED 11 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total KAO records TO be processed : ", 
			modu_process_cnt 
			PRINT COLUMN 10, "Total KAO Invoices / Credits : ", 
			modu_kao_ar_cnt 
			PRINT COLUMN 10, "Total Invoices / Credits Loaded: ", 
			modu_kandoo_ar_cnt 
			SKIP 1 line 
			PRINT COLUMN 10, "Total Errors : ",glob_err_cnt 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 

