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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASL_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_ar_cnt INTEGER 
DEFINE modu_prof_ar_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_kandoo_ar_cnt INTEGER
####################################################################
# FUNCTION ASL_profit_load()
#
# Speed's Invoice Load
####################################################################
FUNCTION ASL_profit_load() 
	DEFINE l_rec_profit RECORD 
		ar_cm_code CHAR(10) , ## customer code 
		ar_trans_type CHAR(8) , ## transaction type 
		ar_tref DECIMAL(8,0) , ## invoice / credit no. 
		ar_date DATE , ## transaction DATE 
		ar_amount DECIMAL(10,2), ## transaction amount 
		ar_acct CHAR(12) , ## gl account 
		ar_store CHAR(3) ## profit store no. 
	END RECORD 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	LET modu_prof_ar_cnt = 0 
	LET modu_kandoo_ar_cnt = 0 
	#
	#
	# NB. Require 'WHENEVER ERROR CONTINUE / stop' because of Informix problem
	#     with continuous CREATE  / DROP table.
	#
	#
	# Create PROFIT temporary table
	#
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_profit 
	( 
	ar_cm_code CHAR(8) , ## customer code 
	ar_trans_type CHAR(8) , ## transaction type 
	ar_tref DECIMAL(8,0) , ## invoice / credit no. 
	ar_date DATE , ## transaction DATE 
	ar_amount DECIMAL(10,2), ## transaction amount 
	ar_acct CHAR(12) , ## gl account 
	ar_store CHAR(3) ## profit store no. 
	) with no LOG 

	IF fgl_find_table("t_trancnt") THEN
		DROP TABLE t_trancnt 
	END IF
		
	WHENEVER ERROR CONTINUE 
	DELETE FROM t_profit WHERE 1 = 1 
	#
	# Commence LOAD
	#
	LET glob_load_file = glob_load_file clipped 
	WHENEVER ERROR CONTINUE 
	LOAD FROM glob_load_file INSERT INTO t_profit 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF sqlca.sqlcode = 0 THEN 
		#
		# Null Test's on data fields
		#
		DECLARE c1_profit CURSOR FOR 
		SELECT * FROM t_profit 
		WHERE ar_cm_code IS NULL 
		OR ar_trans_type IS NULL 
		OR ar_tref IS NULL 
		OR ar_date IS NULL 
		OR ar_amount IS NULL 
		OR ar_acct IS NULL 
		OR ar_cm_code = ' ' 
		OR ar_trans_type = ' ' 
		OR ar_acct = ' ' 
		FOREACH c1_profit INTO l_rec_profit.* 
			IF l_rec_profit.ar_cm_code IS NULL 
			OR l_rec_profit.ar_cm_code = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Customer Code detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
				glob_err_message )
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_profit.ar_trans_type IS NULL 
			OR l_rec_profit.ar_trans_type = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Transaction Type detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_profit.ar_tref IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Invoice No. detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_profit.ar_date IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null date field detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
				glob_err_message )
				#--------------------------------------------------------- 

			END IF 
			IF l_rec_profit.ar_amount IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null transaction amount detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
				glob_err_message )
				#--------------------------------------------------------- 
 
			END IF 
			IF l_rec_profit.ar_acct IS NULL 
			OR l_rec_profit.ar_acct = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null GL Account detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				glob_rec_kandoouser.cmpy_code, 
				l_rec_profit.ar_cm_code, 
				l_rec_profit.ar_tref, 
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
		CALL ASL_create_ar_entry() 
		IF glob_verbose_indv THEN 
			CLOSE WINDOW A638 
		END IF 
		#
		# All unsuccessful invoices will be re-inserted INTO load-file
		#
		# UNLOAD causes a core dump AT SPEEDS
		# ( implement temporary fix by comment out unload )
		#
		# unload TO glob_load_file SELECT * FROM t_profit
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
		OUTPUT TO REPORT ASL_rpt_list_4_prof(rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw"),
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
			OUTPUT TO REPORT ASL_rpt_list_4_prof(rpt_rmsreps_idx_get_idx("ASL_rpt_list_2_saw"),
			'', '', '', '', '', '', '', '' )  
			#--------------------------------------------------------- 		

		END IF 
		RETURN modu_kandoo_ar_cnt 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION ASL_create_ar_entry()
#
#
####################################################################
FUNCTION ASL_create_ar_entry() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_trans_type CHAR(1) 
	DEFINE l_ar_per DECIMAL(6,3) 
	DEFINE l_setup_head_ind SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_rec_profit 
	RECORD 
		ar_cm_code CHAR(10) , ## customer code 
		ar_trans_type CHAR(8) , ## transaction type 
		ar_tref DECIMAL(8,0) , ## invoice / credit no. 
		ar_date DATE , ## transaction DATE 
		ar_amount DECIMAL(10,2), ## transaction amount 
		ar_acct CHAR(12) , ## gl account 
		ar_store CHAR(3) ## profit store no. 
	END RECORD 
	DEFINE l_conv_qty LIKE rate_exchange.conv_buy_qty 
	DEFINE l_acct_text CHAR(50) ## status OF coa account 

	LET modu_ar_cnt = 0 
	LET l_ar_per = 0 
	#
	# count total no. of records
	#
	SELECT count(*) INTO modu_process_cnt 
	FROM t_profit 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	#
	# count total no. of invoices / credits TO be generated
	#
	SELECT count(*) tran_cnt 
	FROM t_profit 
	WHERE ar_cm_code IS NOT NULL 
	AND ar_trans_type IS NOT NULL 
	AND ar_tref IS NOT NULL 
	AND ar_date IS NOT NULL 
	AND ar_amount IS NOT NULL 
	AND ar_acct IS NOT NULL 
	AND ar_cm_code != ' ' 
	AND ar_trans_type != ' ' 
	AND ar_acct != ' ' 
	GROUP BY ar_cm_code, 
	ar_trans_type, 
	ar_tref 
	INTO temp t_trancnt 
	SELECT count(*) INTO modu_prof_ar_cnt 
	FROM t_trancnt 
	IF modu_prof_ar_cnt IS NULL THEN 
		LET modu_prof_ar_cnt = 0 
	END IF 
	IF NOT modu_prof_ar_cnt THEN 
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
	IF glob_verbose_indv THEN 
		DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt 
		DISPLAY l_ar_per TO ar_per
	END IF 
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
	#
	#
	# Create AR Invoices / Credits
	#
	#
	DECLARE c2_profit CURSOR with HOLD FOR 
	SELECT unique ar_cm_code, 
	ar_trans_type, 
	ar_tref 
	FROM t_profit 
	WHERE ar_cm_code IS NOT NULL 
	AND ar_trans_type IS NOT NULL 
	AND ar_tref IS NOT NULL 
	AND ar_date IS NOT NULL 
	AND ar_amount IS NOT NULL 
	AND ar_acct IS NOT NULL 
	AND ar_cm_code != ' ' 
	AND ar_trans_type != ' ' 
	AND ar_acct != ' ' 
	ORDER BY 1, 2, 3 
	FOREACH c2_profit INTO l_cust_code, 
		l_trans_type, 
		l_inv_num 
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
		LET l_ar_per = ( modu_ar_cnt / modu_prof_ar_cnt ) * 100 
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
				#
				# Indicate that header needs TO be setup
				#
				LET l_setup_head_ind = false 

				DECLARE c_profit CURSOR FOR 
				SELECT * FROM t_profit 
				WHERE ar_cm_code = l_cust_code 
				AND ar_trans_type = l_trans_type 
				AND ar_tref = l_inv_num 
				OPEN c_profit 
				WHILE true 
					FETCH c_profit INTO l_rec_profit.* 
					IF sqlca.sqlcode = NOTFOUND THEN 
						EXIT WHILE 
					END IF 
					IF NOT l_setup_head_ind THEN 
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
								DISPLAY l_rec_customer.name_text TO name_text

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

						CASE l_rec_profit.ar_trans_type 
							WHEN 'I' 
								#
								# Set up Invoicehead
								#
								INITIALIZE glob_rec_invoicehead.* TO NULL 
								LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET glob_rec_invoicehead.cust_code = l_rec_profit.ar_cm_code 
								LET glob_rec_invoicehead.org_cust_code = 
								l_rec_customer.corp_cust_code 
								IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
									SELECT unique 1 FROM customer 
									WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
									AND cust_code = glob_rec_invoicehead.org_cust_code 
									IF sqlca.sqlcode = 0 THEN 
										LET glob_rec_invoicehead.org_cust_code = 
										glob_rec_invoicehead.cust_code 
										LET glob_rec_invoicehead.cust_code = 
										l_rec_customer.corp_cust_code 
									END IF 
								END IF 
								LET glob_rec_invoicehead.inv_num = l_rec_profit.ar_tref 
								SELECT 1 FROM invoicehead 
								WHERE inv_num = glob_rec_invoicehead.inv_num 
								AND cmpy_code = glob_rec_invoicehead.cmpy_code 
								IF sqlca.sqlcode = 0 THEN 
									LET glob_err_cnt = glob_err_cnt + 1 
									LET glob_err_message = "Invoice no. already in use" 
			
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
								LET glob_rec_invoicehead.ord_num = NULL 
								LET glob_rec_invoicehead.purchase_code = NULL 
								LET glob_rec_invoicehead.job_code = NULL 
								LET glob_rec_invoicehead.inv_date = l_rec_profit.ar_date 
								LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
								LET glob_rec_invoicehead.entry_date = today 
								LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
								LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
								LET glob_rec_invoicehead.disc_per = 0 
								LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
								LET glob_rec_invoicehead.tax_per = 0 
								LET glob_rec_invoicehead.goods_amt = 0 
								LET glob_rec_invoicehead.hand_amt = 0 
								LET glob_rec_invoicehead.hand_tax_code = l_rec_customer.tax_code 
								LET glob_rec_invoicehead.hand_tax_amt = 0 
								LET glob_rec_invoicehead.freight_amt = 0 
								LET glob_rec_invoicehead.freight_tax_code = l_rec_customer.tax_code 
								LET glob_rec_invoicehead.freight_tax_amt = 0 
								LET glob_rec_invoicehead.tax_amt = 0 
								LET glob_rec_invoicehead.disc_amt = 0 
								LET glob_rec_invoicehead.total_amt = 0 
								LET glob_rec_invoicehead.cost_amt = 0 
								LET glob_rec_invoicehead.paid_amt = 0 
								LET glob_rec_invoicehead.paid_date = NULL 
								LET glob_rec_invoicehead.disc_taken_amt = 0 
								LET glob_rec_invoicehead.expected_date = NULL 
								LET glob_rec_invoicehead.on_state_flag = 'N' 
								LET glob_rec_invoicehead.posted_flag = 'N' 
								LET glob_rec_invoicehead.seq_num = 0 
								LET glob_rec_invoicehead.line_num = 0 
								LET glob_rec_invoicehead.printed_num = 1 
								LET glob_rec_invoicehead.story_flag = 'N' 
								LET glob_rec_invoicehead.rev_date = 
								glob_rec_invoicehead.inv_date 
								LET glob_rec_invoicehead.rev_num = 0 
								LET glob_rec_invoicehead.ship_code = NULL 
								LET glob_rec_invoicehead.name_text = NULL 
								LET glob_rec_invoicehead.addr1_text = NULL 
								LET glob_rec_invoicehead.addr2_text = NULL 
								LET glob_rec_invoicehead.city_text = NULL 
								LET glob_rec_invoicehead.state_code = NULL 
								LET glob_rec_invoicehead.post_code = NULL 
								LET glob_rec_invoicehead.country_code = NULL --@db-patch_2020_10_04--
								LET glob_rec_invoicehead.ship1_text = NULL 
								LET glob_rec_invoicehead.ship2_text = NULL 
								LET glob_rec_invoicehead.ship_date = NULL 
								LET glob_rec_invoicehead.fob_text = NULL 
								LET glob_rec_invoicehead.prepaid_flag = NULL 
								LET glob_rec_invoicehead.com1_text = NULL 
								LET glob_rec_invoicehead.com2_text = NULL 
								LET glob_rec_invoicehead.cost_ind = 'L' 
								LET glob_rec_invoicehead.currency_code = 'AUD' 
								LET glob_rec_invoicehead.conv_qty = 1 
								
								CALL get_conv_rate( 
									glob_rec_kandoouser.cmpy_code, 
									glob_rec_invoicehead.currency_code, 
									glob_rec_invoicehead.inv_date, CASH_EXCHANGE_BUY ) 
								RETURNING l_conv_qty 
								
								IF l_conv_qty != glob_rec_invoicehead.conv_qty THEN 
									LET glob_err_cnt = glob_err_cnt + 1 
									LET glob_err_message = "Exchange rate FOR AUD Currency ",		"invalid on ",glob_rec_invoicehead.inv_date 
			
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
								LET glob_rec_invoicehead.invoice_to_ind = 
								l_rec_customer.invoice_to_ind 
								LET glob_rec_invoicehead.territory_code = 
								l_rec_customer.territory_code 
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
								INITIALIZE l_rec_credithead.* TO NULL 
								LET l_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_rec_credithead.cust_code = l_rec_profit.ar_cm_code 
								LET l_rec_credithead.org_cust_code = 
								l_rec_customer.corp_cust_code 
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
								LET l_rec_credithead.cred_num = l_rec_profit.ar_tref 
								SELECT 1 FROM credithead 
								WHERE cred_num = l_rec_credithead.cred_num 
								AND cmpy_code = l_rec_credithead.cmpy_code 
								IF sqlca.sqlcode = 0 THEN 
									LET glob_err_cnt = glob_err_cnt + 1 
									LET glob_err_message = "Credit no. already in use" 

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
								LET l_rec_credithead.rma_num = 0 
								LET l_rec_credithead.cred_text = NULL 
								LET l_rec_credithead.job_code = NULL 
								LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
								LET l_rec_credithead.entry_date = today 
								LET l_rec_credithead.cred_date = 
								l_rec_profit.ar_date 
								LET l_rec_credithead.sale_code = l_rec_customer.sale_code 
								LET l_rec_credithead.tax_code = l_rec_customer.tax_code 
								LET l_rec_credithead.tax_per = 0 
								LET l_rec_credithead.goods_amt = 0 
								LET l_rec_credithead.hand_amt = 0 
								LET l_rec_credithead.hand_tax_code = l_rec_customer.tax_code 
								LET l_rec_credithead.hand_tax_amt = 0 
								LET l_rec_credithead.freight_amt = 0 
								LET l_rec_credithead.freight_tax_code = l_rec_customer.tax_code 
								LET l_rec_credithead.freight_tax_amt = 0 
								LET l_rec_credithead.tax_amt = 0 
								LET l_rec_credithead.total_amt = 0 
								LET l_rec_credithead.cost_amt = 0 
								LET l_rec_credithead.appl_amt = 0 
								LET l_rec_credithead.disc_amt = 0 
								LET l_rec_credithead.on_state_flag = 'N' 
								LET l_rec_credithead.posted_flag = 'N' 
								LET l_rec_credithead.next_num = 0 
								LET l_rec_credithead.line_num = 0 
								LET l_rec_credithead.printed_num = 0 
								LET l_rec_credithead.com1_text = NULL 
								LET l_rec_credithead.com2_text = NULL 
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
								l_rec_profit.ar_trans_type, " detected" 
									
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
						#
						#
						#
						LET l_setup_head_ind = true 
					END IF 

					IF l_rec_profit.ar_trans_type = 'I' THEN 
						#
						# Invoicedetl
						#
						INITIALIZE l_rec_invoicedetl.* TO NULL 
						LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
						LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
						LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
						LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
						LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
						LET l_rec_invoicedetl.part_code = NULL 
						LET l_rec_invoicedetl.ware_code = NULL 
						LET l_rec_invoicedetl.cat_code = NULL 
						LET l_rec_invoicedetl.ord_qty = 1 
						LET l_rec_invoicedetl.ship_qty = 1 
						LET l_rec_invoicedetl.prev_qty = 0 
						LET l_rec_invoicedetl.back_qty = 0 
						LET l_rec_invoicedetl.ser_flag = 'N' 
						LET l_rec_invoicedetl.ser_qty = 0 
						LET l_rec_invoicedetl.line_text = 'profit invoice' 
						LET l_rec_invoicedetl.uom_code = NULL 
						LET l_rec_invoicedetl.unit_cost_amt = 0 
						LET l_rec_invoicedetl.ext_cost_amt = 0 
						LET l_rec_invoicedetl.disc_amt = 0 
						LET l_rec_invoicedetl.disc_per = 0 
						LET l_rec_invoicedetl.unit_sale_amt = l_rec_profit.ar_amount 
						LET l_rec_invoicedetl.ext_sale_amt = l_rec_profit.ar_amount 
						LET l_rec_invoicedetl.unit_tax_amt = 0 
						LET l_rec_invoicedetl.ext_tax_amt = 0 
						LET l_rec_invoicedetl.line_total_amt = l_rec_profit.ar_amount 
						LET l_rec_invoicedetl.seq_num = NULL 
						CALL ASL_verify_acct( l_rec_profit.ar_acct, 
						glob_rec_invoicehead.year_num, 
						glob_rec_invoicehead.period_num ) 
						RETURNING l_acct_text 
						IF l_acct_text != l_rec_profit.ar_acct THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = l_acct_text 
									
							#---------------------------------------------------------
							OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
							glob_rec_kandoouser.cmpy_code, 
							l_cust_code , 
							l_inv_num , 
							glob_err_message )  
							#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						ELSE 
							LET l_rec_invoicedetl.line_acct_code = l_rec_profit.ar_acct 
						END IF 
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
						LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt	+ l_rec_invoicedetl.ext_cost_amt 
						LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt	+ l_rec_invoicedetl.ext_sale_amt 
						LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt + l_rec_invoicedetl.ext_tax_amt 
					ELSE 
					
						#----------------------------------------------------
						# Creditdetl
						#
						INITIALIZE l_rec_creditdetl.* TO NULL 
						
						LET l_rec_credithead.line_num = l_rec_credithead.line_num + 1 
						LET l_rec_creditdetl.cmpy_code = l_rec_credithead.cmpy_code 
						LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
						LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
						LET l_rec_creditdetl.line_num = l_rec_credithead.line_num 
						LET l_rec_creditdetl.part_code = NULL 
						LET l_rec_creditdetl.ware_code = NULL 
						LET l_rec_creditdetl.cat_code = NULL 
						LET l_rec_creditdetl.ship_qty = 1 
						LET l_rec_creditdetl.ser_ind = 'N' 
						LET l_rec_creditdetl.line_text = 'profit credit' 
						LET l_rec_creditdetl.uom_code = NULL 
						LET l_rec_creditdetl.unit_cost_amt = 0 
						LET l_rec_creditdetl.ext_cost_amt = 0 
						LET l_rec_creditdetl.disc_amt = 0 
						LET l_rec_creditdetl.unit_sales_amt = l_rec_profit.ar_amount 
						LET l_rec_creditdetl.ext_sales_amt = l_rec_profit.ar_amount 
						LET l_rec_creditdetl.unit_tax_amt = 0 
						LET l_rec_creditdetl.ext_tax_amt = 0 
						LET l_rec_creditdetl.line_total_amt = l_rec_profit.ar_amount 
						LET l_rec_creditdetl.seq_num = NULL 
						LET l_rec_creditdetl.job_code = NULL 
						CALL ASL_verify_acct( l_rec_profit.ar_acct, 
						l_rec_credithead.year_num, 
						l_rec_credithead.period_num ) 
						RETURNING l_acct_text 
						IF l_acct_text != l_rec_profit.ar_acct THEN 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = l_acct_text 
							
							#---------------------------------------------------------
							OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
							glob_rec_kandoouser.cmpy_code, 
							l_cust_code , 
							l_inv_num , 
							glob_err_message )  
							#--------------------------------------------------------- 

							ROLLBACK WORK 
							CONTINUE FOREACH 
						ELSE 
							LET l_rec_creditdetl.line_acct_code = l_rec_profit.ar_acct 
						END IF 
						LET l_rec_creditdetl.level_code = 'L' 
						LET l_rec_creditdetl.comm_amt = 0 
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
						LET l_rec_credithead.goods_amt = l_rec_credithead.goods_amt 
						+ l_rec_creditdetl.ext_sales_amt 
						LET l_rec_credithead.cost_amt = l_rec_credithead.cost_amt 
						+ l_rec_creditdetl.ext_cost_amt 
						LET l_rec_credithead.tax_amt = l_rec_credithead.tax_amt 
						+ l_rec_creditdetl.ext_tax_amt 
					END IF 
				END WHILE 

				IF l_rec_profit.ar_trans_type = 'I' THEN 
					#---------------------------------------------------
					# Araudit / Customer dependant upon Invoicehead
					
					LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt	+ glob_rec_invoicehead.tax_amt 
					LET glob_err_message = "ASL - Error inserting Invoice" 
					
					#INSERT invoicehead Record
					IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
						INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
					ELSE
						DISPLAY glob_rec_invoicehead.*
						CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
					END IF 
					
					#---------------------------------------------------
					# Araudit
					
					INITIALIZE l_rec_araudit.* TO NULL 
					
					LET l_rec_araudit.cmpy_code = glob_rec_invoicehead.cmpy_code 
					LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
					LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_araudit.tran_type_ind = 'IN' 
					LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
					LET l_rec_araudit.tran_text = 'profit invoice' 
					LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
					LET l_rec_araudit.entry_code = glob_rec_invoicehead.entry_code 
					LET l_rec_araudit.sales_code = glob_rec_invoicehead.sale_code 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					+ glob_rec_invoicehead.total_amt 
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
					LET l_rec_araudit.tran_text = "PROFIT Credit" 
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
				DELETE FROM t_profit 
				WHERE ar_cm_code = l_cust_code 
				AND ar_trans_type = l_trans_type 
				AND ar_tref = l_inv_num 
			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + 1 
			
			IF glob_verbose_indv THEN 
				DISPLAY modu_kandoo_ar_cnt TO andoo_ar_cnt 
			END IF 
			
			IF l_rec_profit.ar_trans_type = 'I' THEN 
			
				#---------------------------------------------------------
				#Positive/Sucess Output (not error/exception)
				OUTPUT TO REPORT ASL_rpt_list_4_prof(rpt_rmsreps_idx_get_idx("ASL_rpt_list_4_prof"),
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
				OUTPUT TO REPORT ASL_rpt_list_4_prof(rpt_rmsreps_idx_get_idx("ASL_rpt_list_4_prof"),
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
# FUNCTION ASL_verify_acct( p_account_code, p_year_num, p_period_num )
#
# - FUNCTION ASL_verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
#
####################################################################
FUNCTION ASL_verify_acct( p_account_code, p_year_num, p_period_num ) 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE p_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 

	SELECT * INTO p_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_account_code 
	IF status = NOTFOUND THEN 
		LET l_err_message = "Account: ",p_account_code clipped," NOT SET up ", 
		"FOR ", p_year_num USING "####", 
		"/", p_period_num USING "###" 
		RETURN ( l_err_message clipped ) 
	ELSE 
		CASE 
			WHEN ( p_rec_coa.start_year_num > p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( p_rec_coa.end_year_num < p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( p_rec_coa.start_year_num = p_year_num AND 
				p_rec_coa.start_period_num > p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( p_rec_coa.end_year_num = p_year_num AND 
				p_rec_coa.end_period_num < p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			OTHERWISE 
				RETURN p_rec_coa.acct_code 
		END CASE 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION ASL_rpt_start_4_prof()
#
#
#
####################################################################
FUNCTION ASL_rpt_start_4_prof()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_tmp_str STRING
	#------------------------------------------------------------	
	#Report for success
	LET l_rpt_idx = rpt_start("ASL-PROF","ASL_rpt_list_prof","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASL_rpt_list_prof TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_prof")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_prof")].sel_text
	#------------------------------------------------------------

	#LET l_tmp_str = " - (Load No:", glob_rec_loadparms.seq_num using "<<<<<",")"
	#CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str) #append load seq number to the right of header line 2
	#------------------------------------------------------------

END FUNCTION 


####################################################################
# FUNCTION ASL_rpt_finish_4_prof()
#
#
#
####################################################################
FUNCTION ASL_rpt_finish_4_prof()

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASL_rpt_list_4_prof
	CALL rpt_finish("ASL_rpt_list_4_prof")
	#------------------------------------------------------------
	
END FUNCTION 



####################################################################
# REPORT ASL_rpt_list_4_prof( p_cmpy_code, p_cust_code, p_name_text,
#                  p_inv_num  , p_cred_num , p_tran_date,
#                  p_line_num , p_total_amt  )
#
#
####################################################################
REPORT ASL_rpt_list_4_prof(p_rpt_idx,p_cmpy_code, p_cust_code, p_name_text, 
	p_inv_num , p_cred_num , p_tran_date, 
	p_line_num , p_total_amt ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE p_tran_date LIKE invoicehead.inv_date 
	DEFINE p_line_num LIKE invoicehead.line_num 
	DEFINE p_total_amt LIKE invoicehead.total_amt 

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
			PRINT COLUMN 10, "Total PROFIT records TO be processed : ", 
			modu_process_cnt 
			PRINT COLUMN 10, "Total PROFIT Invoices / Credits : ", 
			modu_prof_ar_cnt 
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

