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
DEFINE modu_voyg_ar_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_kandoo_ar_cnt INTEGER 
####################################################################
# FUNCTION voyager_load()
#
# CC Voyager Invoice Load . This does NOT process credits
#            All transactions must be positive
####################################################################
FUNCTION voyager_load() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_tmpload RECORD 
		load_text CHAR(256) 
	END RECORD 
	DEFINE l_rec_voyager RECORD 
		cust_code CHAR(8) , ## customer code 
		ship_code CHAR(8) , ## additional user number 
		inv_date DATE , ## transaction DATE 
		part_code CHAR(15) , ## product id 
		inv_time CHAR(10) , ## time OF transaction 
		purchase_code CHAR(20) , ## customer ORDER no 
		stocked_flag CHAR(1) , ## indicates diminishing y/n 
		line_text CHAR(30) , ## 
		ship_qty INTEGER , ## quantity (In minutes FOR dialup) 
		ext_sale_amt DECIMAL(16,2) ,## total value OF line 
		load_row_num INTEGER 
	END RECORD 
	DEFINE l_year_num INTEGER 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	LET modu_voyg_ar_cnt = 0 
	LET modu_kandoo_ar_cnt = 0 
	
	# Check FOR valid warehouse AND year first.
	# No use going any further IF it IS NOT there
	SELECT unique 1 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = glob_rec_loadparms.ref1_text 
	IF status = NOTFOUND THEN 
		LET glob_err_message = " Specified Warehouse ", 
		glob_rec_loadparms.ref1_text clipped, 
		" does NOT exist" 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 

		LET glob_err_cnt = glob_err_cnt + 1 
		RETURN false 
	END IF 
	
	WHENEVER ERROR CONTINUE 
	LET l_year_num = glob_rec_loadparms.ref2_text USING "&&&&" 
	IF status < 0 THEN 
		LET glob_err_message = " Invalid Subscription Year ", 
		glob_rec_loadparms.ref2_text clipped 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 

		LET glob_err_cnt = glob_err_cnt + 1 
		RETURN false 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF l_year_num > year(today) + 1 OR 
	l_year_num < year(today) - 1 THEN 
		LET glob_err_message = " Invalid Subscription Year ", 
		glob_rec_loadparms.ref2_text clipped 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 		
		 
		LET glob_err_cnt = glob_err_cnt + 1 
		RETURN false 
	END IF 
	#
	#
	# NB. Require 'WHENEVER ERROR CONTINUE / stop' because of Informix problem
	#     with continuous CREATE  / DROP table.
	#
	#
	# Create VOYAGER temporary table
	#
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_tmpload 
	( load_text CHAR(256)) 
	CREATE temp TABLE t_voyager 
	( 
	cust_code CHAR(8) , ## customer code 
	ship_code CHAR(8) , ## additional user number 
	inv_date CHAR(20) , ## transaction DATE 
	part_code CHAR(15) , ## product id 
	inv_time CHAR(10) , ## time OF transaction 
	purchase_code CHAR(20) , ## customer ORDER no 
	stocked_flag CHAR(1) , ## indicates diminishing y/n 
	line_text CHAR(30) , ## 
	ship_qty INTEGER , ## quantity (In minutes FOR dialup) 
	ext_sale_amt DECIMAL(16,2), ## total value OF line 
	load_row_num INTEGER 
	) with no LOG 
	
	IF fgl_find_table("t_trancnt") THEN
		DROP TABLE t_trancnt 
	END IF

	WHENEVER ERROR CONTINUE 
	DELETE FROM t_tmpload WHERE 1 = 1 
	DELETE FROM t_voyager WHERE 1 = 1 
	#
	# Commence LOAD
	#
	LET glob_load_file = glob_load_file clipped 
	WHENEVER ERROR CONTINUE 
	IF glob_verbose_indv THEN 
		LET l_msgresp = kandoomsg("A",1076,"") 
		# Reading Load File.
	END IF 
	LOAD FROM glob_load_file INSERT INTO t_tmpload 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF sqlca.sqlcode = 0 THEN 
		# Strip csv delimiters AND INSERT INTO t_voyager table
		IF glob_verbose_indv THEN 
			LET l_msgresp = kandoomsg("A",1077,"") 
			# Formatting Load Data.
		END IF 
		IF NOT ASL_load_t_voyager() THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			RETURN false 
		END IF 
		DELETE FROM t_voyager WHERE ship_qty = 0 
		#
		# Null Test's on data fields
		#
		DECLARE c1_voyager CURSOR FOR 
		SELECT * FROM t_voyager 
		WHERE cust_code IS NULL 
		OR ship_code IS NULL 
		OR part_code IS NULL 
		OR inv_date IS NULL 
		OR ext_sale_amt IS NULL 
		OR ext_sale_amt < 0 
		OR ship_qty < 0 
		OR cust_code = ' ' 
		OR ship_code = ' ' 
		OR part_code = ' ' 

		FOREACH c1_voyager INTO l_rec_voyager.* 
			IF l_rec_voyager.cust_code IS NULL 
			OR l_rec_voyager.cust_code = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Customer Code detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_voyager.ship_code IS NULL 
			OR l_rec_voyager.ship_code = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Ship Code detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_voyager.part_code IS NULL 
			OR l_rec_voyager.ship_code = ' ' THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null Part Code detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
								
			END IF 
			IF l_rec_voyager.inv_date IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null date field detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_voyager.ext_sale_amt IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null transaction amount detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_voyager.ship_qty IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null transaction quantity detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				
			END IF 
			IF l_rec_voyager.ext_sale_amt < 0 THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Negative transaction amount detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				 
			END IF 
			IF l_rec_voyager.ship_qty < 0 THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Negative transaction quantity detected" 

				#---------------------------------------------------------
				OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
				l_rec_voyager.cust_code, 
				l_rec_voyager.inv_time, 
				glob_err_message ) 
				#--------------------------------------------------------- 
				 
			END IF 
		END FOREACH 
		#
		#
		#
		IF glob_verbose_indv THEN 
			OPEN WINDOW A655 with FORM "A655" 
			CALL windecoration_a("A655") 

		END IF 
		CALL ASL_create_invoice() 
		IF glob_verbose_indv THEN 
			CLOSE WINDOW A655 
		END IF 
		#
		# All unsuccessful invoices will be re-inserted INTO load-file
		#
		UNLOAD TO glob_load_file SELECT * FROM t_tmpload 
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
		OUTPUT TO REPORT ASL_rpt_list_3_voyg( '', '', '', '', '', '', '' ) 
		RETURN modu_ar_cnt 
	ELSE 
		IF NOT modu_kandoo_ar_cnt THEN 
			#
			# Dummy line in REPORT TO force DISPLAY of Control Totals
			#
			OUTPUT TO REPORT ASL_rpt_list_3_voyg( '', '', '', '', '', '', '' ) 
		END IF 
		RETURN modu_kandoo_ar_cnt 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION ASL_create_invoice()
#
#
####################################################################
FUNCTION ASL_create_invoice() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_substype RECORD LIKE substype.* 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_subdetl RECORD LIKE subdetl.* 
	DEFINE l_rec_subcustomer RECORD LIKE subcustomer.* 
	DEFINE l_rec_subaudit RECORD LIKE subaudit.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_mask_code LIKE coa.acct_code 
	DEFINE l_year_num SMALLINT 
	DEFINE l_sub_type_code LIKE substype.type_code 
	DEFINE l_ar_per DECIMAL(6,3) 
	DEFINE l_ship_code CHAR(8) 
	DEFINE l_inv_date DATE 
	--DEFINE l_inv_time CHAR(10) 
	DEFINE l_start_year,l_end_year SMALLINT 
	DEFINE l_setup_head_ind SMALLINT 
	DEFINE l_query_text CHAR(500) 

	DEFINE l_rec_voyager 
	RECORD 
		cust_code CHAR(8) , ## customer code 
		ship_code CHAR(8) , ## additional user number 
		inv_date CHAR(20) , ## transaction DATE 
		part_code CHAR(15) , ## product id 
		inv_time CHAR(10) , ## time OF transaction 
		purchase_code CHAR(20) , ## customer ORDER no 
		stocked_flag CHAR(1) , ## indicates diminishing y/n 
		line_text CHAR(30) , ## 
		ship_qty INTEGER , ## quantity (In minutes FOR dialup) 
		ext_sale_amt DECIMAL(16,2), ## total value OF line 
		load_row_num INTEGER 
	END RECORD 
	DEFINE l_rowid INTEGER 
	--DEFINE l_conv_qty LIKE rate_exchange.conv_buy_qty 
	--DEFINE l_acct_text CHAR(50) ## status OF coa account 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.*

	IF l_rec_inparms.parm_code IS NULL AND l_rec_inparms.cmpy_code IS NULL THEN 
		LET glob_err_message = "Inventory Parameters Not Set Up" 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 
						
		RETURN 
	END IF 

	LET modu_ar_cnt = 0 
	LET l_ar_per = 0 
	LET l_year_num = glob_rec_loadparms.ref2_text USING "&&&&" 
	LET l_ware_code = glob_rec_loadparms.ref1_text 
	LET l_sub_type_code = glob_rec_loadparms.ref3_text 

	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = l_ware_code 
	IF status = NOTFOUND THEN 
		LET glob_err_message = "Warehouse does NOT exist " 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 

		RETURN 
	END IF 

	SELECT * INTO l_rec_substype.* 
	FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_sub_type_code 
	IF status = NOTFOUND THEN 
		LET glob_err_message = "Subscription Type does NOT exist " 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 
						
		RETURN 
	END IF 
	#
	# count total no. of records
	#
	SELECT count(*) INTO modu_process_cnt 
	FROM t_voyager 
	IF modu_process_cnt IS NULL THEN 
		LET modu_process_cnt = 0 
	END IF 
	#
	# count total no. of invoices  TO be generated
	#
	SELECT count(*) tran_cnt 
	FROM t_voyager 
	WHERE cust_code IS NOT NULL 
	AND ship_code IS NOT NULL 
	AND part_code IS NOT NULL 
	AND inv_date IS NOT NULL 
	AND ext_sale_amt IS NOT NULL 
	AND ship_qty IS NOT NULL 
	AND ext_sale_amt >= 0 
	AND ship_qty >= 0 
	AND cust_code != ' ' 
	AND ship_code != ' ' 
	AND part_code != ' ' 
	GROUP BY cust_code, 
	ship_code, 
	inv_date 
	INTO temp t_trancnt 
	SELECT count(*) INTO modu_voyg_ar_cnt 
	FROM t_trancnt 
	IF modu_voyg_ar_cnt IS NULL THEN 
		LET modu_voyg_ar_cnt = 0 
	END IF 
	IF NOT modu_voyg_ar_cnt THEN 
		LET glob_err_message = "No AR Invoices TO be generated" 

		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message ) 
		#--------------------------------------------------------- 
						
		RETURN 
	END IF 
	#
	IF glob_verbose_indv THEN 
		DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt 
		DISPLAY l_ar_per TO ar_per 

	END IF 
	#
	# Declare dynamic cursors
	#
	# Customers
	#
	LET l_query_text = " SELECT * FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND delete_flag = 'N' ", 
	" FOR UPDATE " 
	PREPARE s1_customer FROM l_query_text 
	DECLARE c1_customer CURSOR with HOLD FOR s1_customer 
	#
	# Shipping Codes
	#
	LET l_query_text = " SELECT * FROM customership ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND ship_code = ? " 
	PREPARE s1_customership FROM l_query_text 
	DECLARE c1_customership CURSOR FOR s1_customership 
	#
	# Subscriptions
	#
	LET l_query_text = " SELECT * FROM subcustomer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND ship_code = ? ", 
	" AND part_code = ? ", 
	" AND sub_type_code = ? ", 
	" AND comm_date = ? " 
	PREPARE s1_subcustomer FROM l_query_text 
	DECLARE c1_subcustomer CURSOR FOR s1_subcustomer 
	#
	# Products
	#
	LET l_query_text = " SELECT * FROM product ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND part_code = ? " 
	PREPARE s1_product FROM l_query_text 
	DECLARE c1_product CURSOR FOR s1_product 
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
	# Unique Invoice
	#
	LET l_query_text = " SELECT * FROM invoicehead ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cust_code = ? ", 
	" AND ship_code = ? ", 
	" AND inv_date = ? ", 
	" AND inv_ind = 'X' " 
	PREPARE s1_invoicehead FROM l_query_text 
	DECLARE c1_invoicehead CURSOR FOR s1_invoicehead 
	#
	#
	# Create AR Invoices
	#
	#
	DECLARE c2_voyager CURSOR with HOLD FOR 
	SELECT unique cust_code, 
	ship_code, 
	inv_date 
	FROM t_voyager 
	WHERE cust_code IS NOT NULL 
	AND ship_code IS NOT NULL 
	AND inv_date IS NOT NULL 
	AND part_code IS NOT NULL 
	AND ext_sale_amt IS NOT NULL 
	AND ship_qty IS NOT NULL 
	AND ext_sale_amt >= 0 
	AND ship_qty >= 0 
	AND cust_code != ' ' 
	AND ship_code != ' ' 
	AND part_code != ' ' 
	ORDER BY 1, 2, 3 
	FOREACH c2_voyager INTO l_cust_code, 
		l_ship_code, 
		l_inv_date 
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
		LET l_ar_per = ( modu_ar_cnt / modu_voyg_ar_cnt ) * 100 
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
						l_rec_voyager.inv_time , 
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
						l_rec_voyager.inv_time , 
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

				DECLARE c_voyager CURSOR FOR 
				SELECT *,rowid FROM t_voyager 
				WHERE cust_code = l_cust_code 
				AND ship_code = l_ship_code 
				AND inv_date = l_inv_date 
				OPEN c_voyager 
				WHILE true 
					FETCH c_voyager INTO l_rec_voyager.*,l_rowid 
					IF sqlca.sqlcode = NOTFOUND THEN 
						EXIT WHILE 
					END IF 
					#
					# Validate Line
					#
					OPEN c1_product USING l_rec_voyager.part_code 
					FETCH c1_product INTO l_rec_product.* 
					IF status = NOTFOUND THEN 
						CLOSE c1_product 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Product Code NOT SET up ", 
						l_rec_voyager.part_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_rec_voyager.inv_time , 
						glob_err_message ) 
						#--------------------------------------------------------- 

						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					CLOSE c1_product 

					OPEN c1_prodstatus USING l_rec_voyager.part_code, 
					l_ware_code 
					FETCH c1_prodstatus INTO l_rec_prodstatus.* 
					IF status = NOTFOUND THEN 
						CLOSE c1_prodstatus 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Product Status NOT SET up ", 
						l_rec_voyager.part_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_rec_voyager.inv_time , 
						glob_err_message ) 
						#--------------------------------------------------------- 
						
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 

					#
					# Setup Header IF first time through cust/ship/date combination
					#
					# Also create subhead RECORD as there will be one TO one
					# relationship FOR voyager invoice TO subhead
					#
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
								DISPLAY BY NAME l_rec_customer.name_text 

							END IF 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Customer code NOT SET up" 

							#---------------------------------------------------------
							OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
							glob_rec_kandoouser.cmpy_code, 
							l_cust_code , 
							l_rec_voyager.inv_time , 
							glob_err_message ) 
							#--------------------------------------------------------- 
							
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 

						IF glob_verbose_indv THEN 
							DISPLAY BY NAME l_rec_customer.cust_code, 
							l_rec_customer.name_text 

						END IF 

						OPEN c1_customership USING l_cust_code, 
						l_ship_code 
						FETCH c1_customership INTO l_rec_customership.* 
						IF status = NOTFOUND THEN 
							CLOSE c1_customership 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Customer Shipping Code NOT SET up ", 
							l_rec_voyager.ship_code 

						#---------------------------------------------------------
						OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
						glob_rec_kandoouser.cmpy_code, 
						l_cust_code , 
						l_rec_voyager.inv_time , 
						glob_err_message ) 
						#--------------------------------------------------------- 
						 
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						CLOSE c1_customership 
						# Check FOR existing cust/ship/date invoice
						OPEN c1_invoicehead USING l_cust_code, 
						l_ship_code, 
						l_inv_date 
						FETCH c1_invoicehead 
						IF status = 0 THEN 
							CLOSE c1_invoicehead 
							LET glob_err_cnt = glob_err_cnt + 1 
							LET glob_err_message = "Invoice already exists FOR cust/ship/date", 
							" combination " 

							#---------------------------------------------------------
							OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
							glob_rec_kandoouser.cmpy_code, 
							l_cust_code , 
							l_rec_voyager.inv_time , 
							glob_err_message ) 
							#--------------------------------------------------------- 
						
							ROLLBACK WORK 
							CONTINUE FOREACH 
						END IF 
						CLOSE c1_invoicehead 
						#
						# Set up Invoicehead
						#
						INITIALIZE glob_rec_invoicehead.* TO NULL 
						LET glob_rec_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,"") 
						IF glob_rec_invoicehead.inv_num < 0 THEN 
							LET status = glob_rec_invoicehead.inv_num 
							GOTO recovery 
						END IF 
						LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET glob_rec_invoicehead.cust_code = l_rec_voyager.cust_code 
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
						LET glob_rec_invoicehead.ord_num = NULL 
						LET glob_rec_invoicehead.purchase_code = l_rec_voyager.purchase_code 
						LET glob_rec_invoicehead.ref_num = l_year_num 
						LET glob_rec_invoicehead.inv_date = l_rec_voyager.inv_date 
						LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
						LET glob_rec_invoicehead.entry_date = today 
						LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
						LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
						LET glob_rec_invoicehead.disc_per = 0 
						LET glob_rec_invoicehead.tax_code = "EX" 
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
						LET glob_rec_invoicehead.printed_num = 0 
						LET glob_rec_invoicehead.story_flag = 'N' 
						LET glob_rec_invoicehead.rev_date = today 
						LET glob_rec_invoicehead.rev_num = 0 
						LET glob_rec_invoicehead.ship_code = l_rec_voyager.ship_code 
						LET glob_rec_invoicehead.name_text = l_rec_customership.name_text 
						LET glob_rec_invoicehead.addr1_text = l_rec_customership.addr_text 
						LET glob_rec_invoicehead.addr2_text = l_rec_customership.addr2_text 
						LET glob_rec_invoicehead.city_text = l_rec_customership.city_text 
						LET glob_rec_invoicehead.state_code = l_rec_customership.state_code 
						LET glob_rec_invoicehead.post_code = l_rec_customership.post_code 
						LET glob_rec_invoicehead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
						LET glob_rec_invoicehead.ship1_text = l_rec_customership.ship1_text 
						LET glob_rec_invoicehead.ship2_text = l_rec_customership.ship2_text 
						LET glob_rec_invoicehead.ship_date = l_inv_date 
						LET glob_rec_invoicehead.fob_text = NULL 
						LET glob_rec_invoicehead.prepaid_flag = NULL 
						LET glob_rec_invoicehead.com1_text = NULL 
						LET glob_rec_invoicehead.com2_text = NULL 
						LET glob_rec_invoicehead.cost_ind = 'L' 
						LET glob_rec_invoicehead.currency_code = l_rec_customer.currency_code 
						LET glob_rec_invoicehead.conv_qty = get_conv_rate(
							glob_rec_kandoouser.cmpy_code, 
							glob_rec_invoicehead.currency_code, 
							glob_rec_invoicehead.inv_date,
							CASH_EXCHANGE_SELL) 
						
						LET glob_rec_invoicehead.inv_ind = "X" 
						LET glob_rec_invoicehead.prev_paid_amt = 0 
						
						SELECT acct_mask_code INTO l_mask_code 
						FROM customertype, customer 
						WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND customer.cust_code = glob_rec_invoicehead.cust_code 
						AND customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND customertype.type_code = customer.type_code 
						AND customertype.acct_mask_code IS NOT NULL 
						
						IF status = 0 THEN 
							LET glob_rec_invoicehead.acct_override_code = 
							build_mask( glob_rec_kandoouser.cmpy_code, glob_rec_invoicehead.acct_override_code, 
							l_mask_code ) 
						END IF 
						
						LET glob_rec_invoicehead.acct_override_code =	build_mask( 
							glob_rec_kandoouser.cmpy_code, 
							glob_rec_invoicehead.acct_override_code, 
							glob_rec_kandoouser.acct_mask_code ) 
						
						LET glob_rec_invoicehead.price_tax_flag = NULL 
						LET glob_rec_invoicehead.contact_text = NULL 
						LET glob_rec_invoicehead.tele_text = NULL						 
						LET glob_rec_invoicehead.mobile_phone = NULL
						LET glob_rec_invoicehead.email = NULL												
						LET glob_rec_invoicehead.invoice_to_ind = "1" 
						LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
						LET glob_rec_invoicehead.territory_code = l_rec_customer.territory_code 
						LET glob_rec_invoicehead.cond_code = NULL 
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
								l_part_code , 
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
								l_part_code , 
								glob_err_message ) 
							#--------------------------------------------------------- 
																					 
							LET glob_rec_invoicehead.due_date = glob_rec_invoicehead.inv_date 
							LET glob_rec_invoicehead.disc_date = glob_rec_invoicehead.inv_date 
						END IF 
						#
						## SUBHEAD
						#
						INITIALIZE l_rec_subhead.* TO NULL 
						LET glob_err_message = " Next Subscription Number Update" 
						LET l_rec_subhead.sub_num = next_trans_num(glob_rec_kandoouser.cmpy_code,"SS","") 
						IF l_rec_subhead.sub_num < 0 THEN 
							LET glob_err_message = "K11 - Error Obtaining Next Trans No." 
							LET status = l_rec_subhead.sub_num 
							GOTO recovery 
						END IF 
						LET l_rec_subhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_subhead.ware_code = l_ware_code 
						LET l_rec_subhead.cust_code = glob_rec_invoicehead.cust_code 
						LET l_rec_subhead.ship_code = glob_rec_invoicehead.ship_code 
						LET l_rec_subhead.sub_type_code = l_sub_type_code 
						LET l_rec_subhead.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_subhead.entry_date = today 
						LET l_rec_subhead.rev_date = today 
						LET l_rec_subhead.sub_date = glob_rec_invoicehead.inv_date 
						LET l_rec_subhead.ship_date = glob_rec_invoicehead.inv_date 
						LET l_start_year = year(l_rec_subhead.sub_date) 
						IF month(l_rec_subhead.sub_date) < l_rec_substype.start_mth_num THEN 
							LET l_start_year = l_start_year - 1 
						END IF 
						LET l_end_year = l_start_year 
						IF l_rec_substype.start_mth_num > l_rec_substype.end_mth_num THEN 
							LET l_end_year = l_end_year + 1 
						END IF 
						LET l_rec_subhead.start_date = mdy(l_rec_substype.start_mth_num, 
						l_rec_substype.start_day_num, 
						l_start_year) 
						LET l_rec_subhead.end_date = mdy(l_rec_substype.end_mth_num, 
						l_rec_substype.end_day_num, 
						l_end_year) 
						LET l_rec_subhead.goods_amt = 0 
						LET l_rec_subhead.freight_amt = 0 
						LET l_rec_subhead.hand_amt = 0 
						LET l_rec_subhead.freight_tax_amt = 0 
						LET l_rec_subhead.hand_tax_amt = 0 
						LET l_rec_subhead.tax_amt = 0 
						LET l_rec_subhead.disc_amt = 0 
						LET l_rec_subhead.total_amt = 0 
						LET l_rec_subhead.cost_amt = 0 
						LET l_rec_subhead.status_ind = "C" 
						LET l_rec_subhead.line_num = 0 
						LET l_rec_subhead.rev_num = 0 
						LET l_rec_subhead.prepaid_flag = "N" 
						LET l_rec_subhead.freight_inv_amt = 0 
						LET l_rec_subhead.hand_inv_amt = 0 
						LET l_rec_subhead.frttax_inv_amt = 0 
						LET l_rec_subhead.hndtax_inv_amt = 0 
						LET l_rec_subhead.corp_flag = "N" 
						LET l_rec_subhead.term_code = l_rec_customer.term_code 
						LET l_rec_subhead.tax_code = l_rec_customer.tax_code 
						LET l_rec_subhead.hand_tax_code = l_rec_customer.tax_code 
						LET l_rec_subhead.freight_tax_code = l_rec_customer.tax_code 
						LET l_rec_subhead.sales_code = l_rec_customer.sale_code 
						LET l_rec_subhead.territory_code = l_rec_customer.territory_code 
						LET l_rec_subhead.cond_code = l_rec_customer.cond_code 
						LET l_rec_subhead.invoice_to_ind = l_rec_customer.invoice_to_ind 
						LET l_rec_subhead.currency_code = l_rec_customer.currency_code 
						LET l_rec_subhead.conv_qty = glob_rec_invoicehead.conv_qty 
						LET l_rec_subhead.ship_code = l_rec_customership.ship_code 
						LET l_rec_subhead.ware_code = l_ware_code 
						LET l_rec_subhead.ship_name_text = l_rec_customership.name_text 
						LET l_rec_subhead.ship_addr1_text = l_rec_customership.addr_text 
						LET l_rec_subhead.ship_addr2_text = l_rec_customership.addr2_text 
						LET l_rec_subhead.ship_city_text = l_rec_customership.city_text 
						LET l_rec_subhead.state_code = l_rec_customership.state_code 
						LET l_rec_subhead.post_code = l_rec_customership.post_code 
						LET l_rec_subhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
						LET l_rec_subhead.contact_text = l_rec_customership.contact_text 
						LET l_rec_subhead.tele_text = l_rec_customership.tele_text 
						LET l_rec_subhead.mobile_phone = l_rec_customership.mobile_phone
						LET l_rec_subhead.email = l_rec_customership.email												
						INITIALIZE l_rec_subdetl.* TO NULL 
						#
						LET l_setup_head_ind = true 
					END IF 

					#
					# Invoicedetl
					#
					INITIALIZE l_rec_invoicedetl.* TO NULL 
					LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
					LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
					LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
					LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
					LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
					LET l_rec_invoicedetl.part_code = l_rec_voyager.part_code 
					LET l_rec_invoicedetl.ware_code = l_ware_code 
					LET l_rec_invoicedetl.cat_code = l_rec_product.cat_code 
					LET l_rec_invoicedetl.ord_qty = l_rec_voyager.ship_qty 
					LET l_rec_invoicedetl.ship_qty = l_rec_voyager.ship_qty 
					LET l_rec_invoicedetl.prev_qty = 0 
					LET l_rec_invoicedetl.back_qty = 0 
					LET l_rec_invoicedetl.ser_flag = 'N' 
					LET l_rec_invoicedetl.ser_qty = 0 
					LET l_rec_invoicedetl.line_text = l_rec_voyager.line_text 
					LET l_rec_invoicedetl.uom_code = l_rec_product.sell_uom_code 
					LET l_rec_invoicedetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt 
					LET l_rec_invoicedetl.ext_cost_amt = l_rec_invoicedetl.unit_cost_amt * 
					l_rec_invoicedetl.ship_qty 
					LET l_rec_invoicedetl.disc_amt = 0 
					LET l_rec_invoicedetl.disc_per = 0 
					LET l_rec_invoicedetl.unit_sale_amt = l_rec_voyager.ext_sale_amt / 
					l_rec_invoicedetl.ship_qty 
					LET l_rec_invoicedetl.ext_sale_amt = l_rec_voyager.ext_sale_amt 
					LET l_rec_invoicedetl.unit_tax_amt = 0 
					LET l_rec_invoicedetl.ext_tax_amt = 0 
					LET l_rec_invoicedetl.line_total_amt = l_rec_voyager.ext_sale_amt 
					LET l_rec_invoicedetl.seq_num = NULL 
					LET l_rec_invoicedetl.level_code = 'L' 
					LET l_rec_invoicedetl.comm_amt = 0 
					LET l_rec_invoicedetl.comp_per = NULL 
					LET l_rec_invoicedetl.tax_code = l_rec_customer.tax_code 
					LET l_rec_invoicedetl.order_line_num = NULL 
					LET l_rec_invoicedetl.order_num = NULL 
					LET l_rec_invoicedetl.offer_code = NULL 
					LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ship_qty 
					LET l_rec_invoicedetl.bonus_qty = 0 
					LET l_rec_invoicedetl.ext_bonus_amt = 0 
					LET l_rec_invoicedetl.ext_stats_amt = l_rec_invoicedetl.ext_sale_amt 
					LET l_rec_invoicedetl.list_price_amt = l_rec_prodstatus.list_amt 
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
					IF l_rec_inparms.hist_flag = 'Y' THEN 
						LET l_rec_prodledg.hist_flag = 'N' 
					ELSE 
						LET l_rec_prodledg.hist_flag = 'Y' 
					END IF 
					LET l_rec_prodledg.post_flag = 'N' 
					LET l_rec_prodledg.acct_code = NULL 
					LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
					- l_rec_invoicedetl.ship_qty 
					LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_prodledg.entry_date = glob_rec_loadparms.load_date 
					LET glob_err_message = "ASL - Error inserting product ledger entry" 
					INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
					#
					# Subscriptions
					#
					# SUBDETL
					#
					IF l_rec_subdetl.sub_line_num IS NULL THEN 
						LET l_rec_subdetl.sub_line_num = 1 
					ELSE 
						LET l_rec_subdetl.sub_line_num = l_rec_subdetl.sub_line_num + 1 
					END IF 
					LET l_rec_subdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_subdetl.sub_num = l_rec_subhead.sub_num 
					LET l_rec_subdetl.ware_code = l_rec_invoicedetl.ware_code 
					LET l_rec_subdetl.part_code = l_rec_invoicedetl.part_code 
					LET l_rec_subdetl.line_text = l_rec_invoicedetl.line_text 
					LET l_rec_subdetl.unit_amt = l_rec_invoicedetl.unit_sale_amt 
					LET l_rec_subdetl.sub_qty = l_rec_invoicedetl.ship_qty 
					LET l_rec_subdetl.cust_code = l_rec_subhead.cust_code 
					LET l_rec_subdetl.ship_code = l_rec_subhead.ship_code 
					LET l_rec_subdetl.issue_qty = l_rec_invoicedetl.ship_qty 
					LET l_rec_subdetl.inv_qty = l_rec_invoicedetl.ship_qty 
					LET l_rec_subdetl.return_qty = 0 
					LET l_rec_subdetl.unit_tax_amt = l_rec_invoicedetl.unit_tax_amt 
					LET l_rec_subdetl.level_code = l_rec_invoicedetl.level_code 
					LET l_rec_subdetl.tax_code = l_rec_subhead.tax_code 
					LET l_rec_subdetl.line_total_amt = l_rec_subdetl.sub_qty 
					* (l_rec_subdetl.unit_tax_amt+l_rec_subdetl.unit_amt) 
					# SUBCUSTOMER
					OPEN c1_subcustomer USING glob_rec_invoicehead.cust_code, 
					glob_rec_invoicehead.ship_code, 
					l_rec_invoicedetl.part_code, 
					l_rec_subhead.sub_type_code, 
					l_rec_subhead.start_date 
					FETCH c1_subcustomer INTO l_rec_subcustomer.* 
					IF status = 0 THEN 
						LET l_rec_subcustomer.next_seq_num = l_rec_subcustomer.next_seq_num + 2 
						UPDATE subcustomer 
						SET sub_qty = sub_qty + l_rec_invoicedetl.ship_qty, 
						issue_qty = issue_qty + l_rec_invoicedetl.ship_qty, 
						last_issue_num = last_issue_num + 1, 
						unit_amt = l_rec_invoicedetl.unit_sale_amt, 
						unit_tax_amt = l_rec_invoicedetl.unit_tax_amt, 
						total_amt = l_rec_invoicedetl.line_total_amt, 
						next_seq_num = l_rec_subcustomer.next_seq_num 
						WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
						AND cust_code= l_rec_subhead.cust_code 
						AND ship_code= l_rec_subhead.ship_code 
						AND sub_type_code = l_rec_subhead.sub_type_code 
						AND part_code= l_rec_subdetl.part_code 
						AND comm_date= l_rec_subhead.start_date 
					ELSE 
						LET l_rec_subcustomer.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_subcustomer.cust_code = l_rec_subhead.cust_code 
						LET l_rec_subcustomer.ship_code = l_rec_subhead.ship_code 
						LET l_rec_subcustomer.sub_type_code = l_rec_subhead.sub_type_code 
						LET l_rec_subcustomer.part_code = l_rec_subdetl.part_code 
						LET l_rec_subcustomer.comm_date = l_rec_subhead.start_date 
						LET l_rec_subcustomer.end_date = l_rec_subhead.end_date 
						LET l_rec_subcustomer.entry_date = today 
						LET l_rec_subcustomer.entry_code = glob_rec_kandoouser.sign_on_code 
						LET l_rec_subcustomer.currency_code =l_rec_subhead.currency_code 
						LET l_rec_subcustomer.conv_qty = l_rec_subhead.conv_qty 
						LET l_rec_subcustomer.bonus_ind = "N" 
						LET l_rec_subcustomer.status_ind = "0" 
						LET l_rec_subcustomer.next_seq_num = 1 
						LET l_rec_subcustomer.last_issue_num = 0 
						LET l_rec_subcustomer.sub_qty = l_rec_invoicedetl.ship_qty 
						LET l_rec_subcustomer.issue_qty = l_rec_invoicedetl.ship_qty 
						LET l_rec_subcustomer.last_issue_num = 1 
						LET l_rec_subcustomer.unit_amt = l_rec_invoicedetl.unit_sale_amt 
						LET l_rec_subcustomer.unit_tax_amt = l_rec_invoicedetl.unit_tax_amt 
						LET l_rec_subcustomer.total_amt = l_rec_invoicedetl.line_total_amt 
						INSERT INTO subcustomer VALUES (l_rec_subcustomer.*) 
					END IF 
					CLOSE c1_subcustomer 
					LET l_rec_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_subaudit.part_code = l_rec_subdetl.part_code 
					LET l_rec_subaudit.cust_code = l_rec_subhead.cust_code 
					LET l_rec_subaudit.ship_code = l_rec_subhead.ship_code 
					LET l_rec_subaudit.start_date = l_rec_subhead.start_date 
					LET l_rec_subaudit.end_date = l_rec_subhead.end_date 
					LET l_rec_subaudit.seq_num = l_rec_subcustomer.next_seq_num - 1 
					LET l_rec_subaudit.tran_date = l_rec_subhead.sub_date 
					LET l_rec_subaudit.entry_date = today 
					LET l_rec_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_subaudit.tran_qty = l_rec_subdetl.sub_qty 
					LET l_rec_subaudit.unit_amt = l_rec_subdetl.unit_amt 
					LET l_rec_subaudit.unit_tax_amt = l_rec_subdetl.unit_tax_amt 
					LET l_rec_subaudit.currency_code = l_rec_subhead.currency_code 
					LET l_rec_subaudit.conv_qty = l_rec_subhead.conv_qty 
					LET l_rec_subaudit.tran_type_ind = "SUB" 
					LET l_rec_subaudit.sub_num = l_rec_subhead.sub_num 
					LET l_rec_subaudit.source_num = l_rec_subhead.sub_num 
					LET l_rec_subaudit.comm_text = "Sub Entry (Voyager)" 
					LET l_rec_subaudit.sub_type_code = l_rec_subhead.sub_type_code 
					INSERT INTO subaudit VALUES (l_rec_subaudit.*) 
					LET l_rec_subaudit.seq_num = l_rec_subcustomer.next_seq_num 
					LET l_rec_subaudit.tran_type_ind = "ISS" 
					LET l_rec_subaudit.source_num = glob_rec_invoicehead.inv_num 
					LET l_rec_subaudit.comm_text = "Voyager Issue" 
					INSERT INTO subaudit VALUES (l_rec_subaudit.*) 
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
					LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt		+ l_rec_invoicedetl.ext_cost_amt 
					LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt	+ l_rec_invoicedetl.ext_sale_amt 
					LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt + l_rec_invoicedetl.ext_tax_amt 
					LET l_rec_subhead.cost_amt = glob_rec_invoicehead.cost_amt + l_rec_invoicedetl.ext_cost_amt 
					LET l_rec_subhead.goods_amt = glob_rec_invoicehead.goods_amt + l_rec_invoicedetl.ext_sale_amt 
					LET l_rec_subhead.tax_amt = glob_rec_invoicehead.tax_amt + l_rec_invoicedetl.ext_tax_amt 
					
					DELETE FROM t_tmpload 
					WHERE rowid = l_rec_voyager.load_row_num 

				END WHILE 

				LET l_rec_subhead.total_amt = glob_rec_invoicehead.goods_amt+ glob_rec_invoicehead.tax_amt 
				LET glob_err_message = "ASL - Error inserting subhead" 
				
				INSERT INTO subhead VALUES ( l_rec_subhead.* ) 
				
				#---------------------------------
				# Araudit / Customer dependant upon Invoicehead
				#
				LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt	+ glob_rec_invoicehead.tax_amt 
				LET glob_err_message = "ASL - Error inserting Invoice" 

				#INSERT invoicehead Record
				IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
					INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
				ELSE
					DISPLAY glob_rec_invoicehead.*
					CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
				END IF 	

				#------------------------------------------------------
				# Araudit
				#
				INITIALIZE l_rec_araudit.* TO NULL 
				
				LET l_rec_araudit.cmpy_code = glob_rec_invoicehead.cmpy_code 
				LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
				LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
				LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_araudit.tran_type_ind = 'IN' 
				LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
				LET l_rec_araudit.tran_text = 'voyager invoice' 
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

			COMMIT WORK 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET modu_kandoo_ar_cnt = modu_kandoo_ar_cnt + 1 
			IF glob_verbose_indv THEN 
				DISPLAY modu_kandoo_ar_cnt TO kandoo_ar_cnt  

			END IF 

		#---------------------------------------------------------
		#Positive/Sucess Output (not error/exception)
		OUTPUT TO REPORT ASL_rpt_list_3_voyg(rpt_rmsreps_idx_get_idx("ASL_rpt_list_3_voyg"),
		glob_rec_invoicehead.cmpy_code, 
			glob_rec_invoicehead.cust_code, 
			l_rec_customer.name_text , 
			glob_rec_invoicehead.inv_num , 
			glob_rec_invoicehead.inv_date , 
			glob_rec_invoicehead.line_num , 
			glob_rec_invoicehead.total_amt )
		#--------------------------------------------------------- 
			
		END FOREACH 
END FUNCTION 


####################################################################
# FUNCTION ASL_defaults_3_voyg()
#
#
####################################################################
FUNCTION ASL_defaults_3_voyg() 
{
	LET glob_rec_kandooreport.header_text = "Voyager Invoice Load - ", 
	today USING "dd/mm/yy" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "ASL" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Company" , 5 spaces, 
	"Customer" , 36 spaces, 
	"Invoice No.", 22 spaces, 
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
# FUNCTION verify3_acct( p_account_code, p_year_num, p_period_num )
#
#
# - FUNCTION verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
####################################################################
FUNCTION verify3_acct( p_account_code, p_year_num, p_period_num ) 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 

	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 

	SELECT * INTO l_rec_coa.* 
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
			WHEN ( l_rec_coa.start_year_num > p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num < p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.start_year_num = p_year_num AND 
				l_rec_coa.start_period_num > p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num = p_year_num AND 
				l_rec_coa.end_period_num < p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			OTHERWISE 
				RETURN l_rec_coa.acct_code 
		END CASE 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION ASL_rpt_start_3_voyg()
#
#
#
####################################################################
FUNCTION ASL_rpt_start_3_voyg()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_tmp_str STRING
	#------------------------------------------------------------	
	#Report for success
	LET l_rpt_idx = rpt_start("ASL-VOYG","ASL_rpt_list_3_voyg","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASL_rpt_list_3_voyg TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_3_voyg")].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = 0
	#LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_3_voyg")].sel_text
	#------------------------------------------------------------

	LET l_tmp_str = " - (Load No:", glob_rec_loadparms.seq_num using "<<<<<",")"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str) #append load seq number to the right of header line 2
	#------------------------------------------------------------
	 
END FUNCTION 


####################################################################
# FUNCTION rpt_aslc_finish_3_voyg()
#
#
#
####################################################################
FUNCTION rpt_aslc_finish_3_voyg()

	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASL_rpt_list_3_voyg
	CALL rpt_finish("ASL_rpt_list_3_voyg")
	#------------------------------------------------------------
	
END FUNCTION 


####################################################################
# FUNCTION ASL_load_t_voyager()
#
#
#
####################################################################
FUNCTION ASL_load_t_voyager() 
	DEFINE l_rec_tmpload RECORD 
		load_text CHAR(256) 
	END RECORD 
	DEFINE l_rec_voyager RECORD 
		cust_code CHAR(8) , ## customer code 
		ship_code CHAR(8) , ## additional user number 
		inv_date DATE , ## transaction DATE 
		part_code CHAR(15) , ## product id 
		inv_time CHAR(10) , ## time OF transaction 
		purchase_code CHAR(20) , ## customer ORDER no 
		stocked_flag CHAR(1) , ## indicates diminishing y/n 
		line_text CHAR(30) , ## 
		ship_qty INTEGER , ## quantity (In minutes FOR dialup) 
		ext_sale_amt DECIMAL(16,2), ## total value OF line 
		load_row_num INTEGER 
	END RECORD 

	DEFINE l_rowid INTEGER 
	DEFINE l_line_num INTEGER 
	DEFINE l_i SMALLINT 
	DEFINE l_j SMALLINT 
	DEFINE l_h SMALLINT 
	DEFINE l_rec_cnt SMALLINT 
	DEFINE l_rec_len SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_field_text CHAR(40) 


	GOTO bypass1 
	LABEL recovery1: 
	LET glob_err_message = "Error in load file line ",l_line_num USING "########" 
	
	#---------------------------------------------------------
	OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
	'', '', '', glob_err_message ) 
	#--------------------------------------------------------- 
															
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN false 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 

	DECLARE c_tmpload CURSOR FOR 
	SELECT *,rowid FROM t_tmpload 

	LET l_line_num = 0 
	FOREACH c_tmpload INTO l_rec_tmpload.*,l_rowid 
		LET l_line_num = l_line_num + 1 
		INITIALIZE l_rec_voyager.* TO NULL 
		LET l_rec_cnt = 1 
		LET l_rec_len = length(l_rec_tmpload.load_text) 
		LET l_start_pos = 2 
		FOR l_i = 1 TO l_rec_len 
			IF l_i = 1 THEN # START OF FIRST FIELD 
				CONTINUE FOR 
			END IF 
			IF l_i = l_rec_len THEN # must be LAST FIELD 
				IF l_rec_tmpload.load_text[l_i-1,l_i] = "\"\"" THEN # NULL FIELD 
					LET l_rec_voyager.ext_sale_amt = NULL 
				ELSE 
					LET l_field_text = l_rec_tmpload.load_text[l_start_pos,l_i - 1] 
					LET l_rec_voyager.ext_sale_amt = l_field_text clipped 
				END IF 
				EXIT FOR 
			END IF 
			IF l_rec_tmpload.load_text[l_i,l_i+2] = "\"\,\"" THEN # FIELD delimiter 
				IF l_rec_tmpload.load_text[l_i-1,l_i] = "\"\"" THEN # NULL FIELD 
					LET l_field_text = NULL 
				ELSE 
					LET l_field_text = l_rec_tmpload.load_text[l_start_pos,l_i - 1] 
					LET l_h = length(l_field_text) 
					FOR l_j = 1 TO l_h 
						IF l_field_text[l_j,l_j+1] = "\\\"" THEN 
							IF l_j = 1 THEN 
								LET l_field_text = l_field_text[l_j+1,l_h] 
								CONTINUE FOR 
							END IF 
							IF l_j = l_h THEN 
								LET l_field_text = l_field_text[1,l_h-1] 
								EXIT FOR 
							END IF 
							LET l_field_text = l_field_text[1,l_j-1], 
							l_field_text[l_j+1,l_h] 
						END IF 
					END FOR 
				END IF 
				LET l_start_pos = l_i + 3 
				CASE 
					WHEN l_rec_cnt = 1 # cust code 
						LET l_rec_voyager.cust_code = l_field_text clipped 
					WHEN l_rec_cnt = 2 # ship code 
						LET l_rec_voyager.ship_code = l_field_text clipped 
					WHEN l_rec_cnt = 3 # inv_date 
						LET l_rec_voyager.inv_date = l_field_text[1,8] 
						LET l_rec_voyager.inv_time = l_field_text[10,17] 
					WHEN l_rec_cnt = 4 # part_code 
						LET l_rec_voyager.part_code = l_field_text clipped 
					WHEN l_rec_cnt = 5 # purchase code 
						LET l_rec_voyager.purchase_code = l_field_text clipped 
					WHEN l_rec_cnt = 6 # stocked flag 
						LET l_rec_voyager.stocked_flag = l_field_text clipped 
					WHEN l_rec_cnt = 7 # description 
						LET l_rec_voyager.line_text = l_rec_voyager.inv_time clipped," ", 
						l_field_text clipped 
					WHEN l_rec_cnt = 8 # ship quantity 
						LET l_rec_voyager.ship_qty = l_field_text clipped 
					WHEN l_rec_cnt = 9 # ext sale amount 
						LET l_rec_voyager.ext_sale_amt = l_field_text clipped 
					OTHERWISE 
						EXIT FOR 
				END CASE 
				LET l_rec_cnt = l_rec_cnt + 1 
			END IF 
		END FOR 
		LET l_rec_voyager.load_row_num = l_rowid 
		INSERT INTO t_voyager VALUES (l_rec_voyager.*) 
	END FOREACH 
	
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN true 
END FUNCTION



####################################################################
# REPORT ASL_rpt_list_3_voyg(p_rpt_idx, p_cmpy_code, p_cust_code, p_name_text,
#                  p_inv_num  , p_tran_date,
#                  p_line_num , p_total_amt  )
#
#
####################################################################
REPORT ASL_rpt_list_3_voyg(p_rpt_idx,p_cmpy_code, p_cust_code, p_name_text, 
	p_inv_num , p_tran_date, 
	p_line_num , p_total_amt) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_name_text LIKE customer.name_text 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_tran_date LIKE invoicehead.inv_date 
	DEFINE p_line_num LIKE invoicehead.line_num 
	DEFINE p_total_amt LIKE invoicehead.total_amt 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_cmpy_code, 
	p_cust_code, 
	p_inv_num 
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
			COLUMN 88, p_tran_date USING "dd/mm/yy" , 
			COLUMN 104, p_line_num USING "#####" , 
			COLUMN 117, p_total_amt USING "############&.&&" 
		ON LAST ROW 
			NEED 11 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total VOYAGER records TO be processed : ", 
			modu_process_cnt 
			PRINT COLUMN 10, "Total VOYAGER Invoices / Credits : ", 
			modu_voyg_ar_cnt 
			PRINT COLUMN 10, "Total Invoices / Credits Loaded : ", 
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
 