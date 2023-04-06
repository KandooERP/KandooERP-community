############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/AR0_GLOBALS.4gl" 

############################################################
# FUNCTION AR_temp_tables_create()
#
#
############################################################
FUNCTION AR_temp_tables_create()
	DEFINE l_msg STRING
	
	WHENEVER SQLERROR CONTINUE
	
	CASE getmoduleid()
		WHEN "AR1"
			MESSAGE "Creating temp table shuffle for AR1 t_ar1_rpt_data_shuffle"
			CREATE temp TABLE t_ar1_rpt_data_shuffle 
			( tm_cust CHAR(8), 
			tm_name CHAR(30), 
			tm_cury CHAR(3), 
			tm_tele CHAR(20), 
			tm_date DATE, 
			tm_type CHAR(2), 
			tm_doc INTEGER, 
			tm_refer CHAR(20), 
			tm_late INTEGER, 
			tm_amount money(12,2), 
			tm_unpaid money(12,2), 
			tm_cur money(12,2), 
			tm_o30 money(12,2), 
			tm_o60 money(12,2), 
			tm_o90 money(12,2), 
			tm_plus money(12,2) ) with no LOG 

		WHEN "AR2"
			MESSAGE "Creating temp table shuffle for AR2"

		CREATE temp TABLE t_ar2_rpt_data_shuffle 
		( tm_cust CHAR(8), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_amount DECIMAL(16,2), 
		tm_paid DECIMAL(16,2), 
		tm_cred DECIMAL(16,2), 
		tm_dis DECIMAL(16,2), 
		tm_post CHAR(1) ) with no LOG 

		WHEN "AR3"
			MESSAGE "Creating temp table shuffle for AR2"
			CREATE temp TABLE t_ar3_rpt_data_shuffle 
			(tm_cust CHAR(8), 
			tm_name CHAR(30), 
			tm_date DATE, 
			tm_type CHAR(2), 
			tm_year SMALLINT, 
			tm_period SMALLINT, 
			tm_doc INTEGER, 
			tm_refer CHAR(20), 
			tm_amount money(12,2), 
			tm_paid money(12,2), 
			tm_cred money(12,2), 
			tm_dis money(12,2), 
			tm_post CHAR(1)) with no LOG 

		WHEN "AR5"

			CREATE temp TABLE t_ar5_rpt_data_shuffle 
			(tm_cust CHAR(8), 
			tm_name CHAR(30), 
			tm_date DATE, 
			tm_estdt DATE, 
			tm_story CHAR(1), 
			tm_select CHAR(3), 
			tm_doc INTEGER, 
			tm_type CHAR(2), 
			tm_refer CHAR(20), 
			tm_due INTEGER, 
			tm_slot SMALLINT, 
			tm_desc CHAR(40), 
			tm_amount money(12,2), 
			tm_dis money(12,2), 
			tm_unpaid money(12,2), 
			tm_past money(12,2), 
			tm_1t7 money(12,2), 
			tm_8t14 money(12,2), 
			tm_15t21 money(12,2), 
			tm_22t28 money(12,2), 
			tm_29t60 money(12,2), 
			tm_61t90 money(12,2), 
			tm_plus money(12,2)) with no LOG 

		WHEN "AR6"
			CREATE temp TABLE t_ar6_rpt_data_shuffle ( 
			tm_sale NCHAR(8), 
			tm_name NVARCHAR(30), 
			tm_cust NCHAR(8),
			tm_doc INTEGER, 
			tm_date DATE, 
			tm_per SMALLINT, 
			tm_amount money(12,2), 
			tm_paid money(12,2), 
			tm_prof money(12,2), 
			tm_comm money(12,2)) 
			with no LOG 

		WHEN "AR7"
			CREATE temp TABLE t_taxamts (ref_num INTEGER, 
			tran_date DATE, 
			cust_code CHAR(8), 
			tax_num_text CHAR(15), 
			currency_code CHAR(3), 
			total_amt DECIMAL(16,2), 
			tax_code CHAR(3), 
			ext_sale_amt DECIMAL(16,2), 
			ext_tax_amt DECIMAL(16,2), 
			conv_qty float) with no LOG 
		
			CREATE INDEX t_key ON t_taxamts (tran_date, ref_num, tax_code) 
		
			CREATE temp TABLE t_basetax(tax_code CHAR(3), 
			base_sale_amt DECIMAL(16,2), 
			base_tax_amt DECIMAL(16,2)) with no LOG 

			DELETE FROM t_taxamts WHERE 1=1 
			DELETE FROM t_basetax WHERE 1=1
						
		WHEN "AR8"
			#no temp table used
		WHEN "ARA"

		WHEN "ARB"
			CREATE temp TABLE t_arb_rpt_data_shuffle 
		( tm_sale CHAR(3), 
		tm_name CHAR(30), 
		tm_cust CHAR(8), 
		tm_doc INTEGER, 
		tm_date DATE, 
		tm_per SMALLINT, 
		tm_amount money(12,2), 
		tm_paid money(12,2), 
		tm_prof money(12,2), 
		tm_comm money(12,2) ) with no LOG 


		WHEN "ARC"
			CREATE temp TABLE t_posttemp 
			( 
			ref_num INTEGER, 
			ref_text CHAR(10), 
			post_acct_code CHAR(18), 
			desc_text CHAR(40), 
			debit_amt DECIMAL(14,2), 
			credit_amt DECIMAL(14,2), 
			base_debit_amt DECIMAL(14,2), 
			base_credit_amt DECIMAL(14,2), 
			currency_code CHAR(3), 
			conv_qty FLOAT, 
			tran_date DATE, 
			post_flag CHAR(1), 
			ar_acct_code CHAR(18) ) with no LOG 
		
			CREATE temp TABLE t_taxtemp 
			( 
			tax_acct_code CHAR(18), 
			tax_amt DECIMAL(12,2)) with no LOG 

		WHEN "ARD"
			CREATE temp TABLE t_doctab (d_cust CHAR(8), 
			d_date DATE, 
			d_ref INTEGER, 
			d_type CHAR(2), 
			d_age INTEGER, 
			d_bal money(12,2)) with no LOG 
			CREATE INDEX d_tmp_key ON t_doctab(d_ref) 

		WHEN "ARR"								

		WHEN "ART" #ART & ART_J are the same
		WHEN "ART_J" #ART & ART_J are the same

		OTHERWISE
			LET l_msg = "FUNCTION AR_temp_tables_create()\nInvalid Module ID =", trim(getmoduleid())
			CALL fgl_winmessage("Internal 4GL error",l_msg,"ERROR")
	END CASE

END FUNCTION

############################################################
# FUNCTION AR_temp_tables_drop()
#
#
############################################################
FUNCTION AR_temp_tables_drop()
	DEFINE l_msg STRING
	
	WHENEVER SQLERROR CONTINUE
	
	CASE getmoduleid()
		WHEN "AR1"
			MESSAGE "Dropping temp tables for AR1"
			
			IF fgl_find_table("t_ar1_rpt_data_shuffle") THEN
				DROP TABLE t_ar1_rpt_data_shuffle 
			END IF 	 

			
--				CALL droptemptableshuffle()
--				CALL droptemptabletaxamts() 
--				CALL droptemptablebasetax() 
--				CALL droptemptableshuffle() 
		
		WHEN "AR2"
			MESSAGE "Dropping temp tables for AR2"
			IF fgl_find_table("t_ar2_rpt_data_shuffle") THEN
				DROP TABLE t_ar2_rpt_data_shuffle 
			END IF 				
			
		WHEN "AR3"
			MESSAGE "Dropping temp tables for AR3"
			IF fgl_find_table("t_ar3_rpt_data_shuffle") THEN
				DROP TABLE t_ar3_rpt_data_shuffle
			END IF 				
			
		WHEN "AR5"
			MESSAGE "Dropping temp tables for AR5"
			IF fgl_find_table("t_ar5_rpt_data_shuffle") THEN
				DROP TABLE t_ar5_rpt_data_shuffle
			END IF 				
			
		WHEN "AR6"
			MESSAGE "Dropping temp tables for AR6"
			IF fgl_find_table("t_ar6_rpt_data_shuffle") THEN
				DROP TABLE t_ar6_rpt_data_shuffle
			END IF 				
			
		WHEN "AR7"
			MESSAGE "Dropping temp tables for AR7"
			IF fgl_find_table("t_taxamts") THEN
				DROP TABLE t_taxamts
			DROP TABLE t_basetax
			END IF 				
							
		WHEN "AR8"
			#MESSAGE "Dropping temp tables for AR8"
			#no temp table used
		WHEN "ARA"
			MESSAGE "Dropping temp tables for ARA"

		WHEN "ARB"
			MESSAGE "Dropping temp tables for ARB"

		WHEN "ARC"
			MESSAGE "Dropping temp tables for ARC"

		WHEN "ARD"
			MESSAGE "Dropping temp tables for ARD"

		WHEN "ARR"								
			MESSAGE "Dropping temp tables for ARR"

		WHEN "ART" #ART & ART_J are the same
			MESSAGE "Dropping temp tables for ART"

		WHEN "ART_J" #ART & ART_J are the same
			MESSAGE "Dropping temp tables for ART_J"

		OTHERWISE
			LET l_msg = "FUNCTION AR_temp_tables_create()\nInvalid Module ID =", trim(getmoduleid())
			CALL fgl_winmessage("Internal 4GL error",l_msg,"ERROR")
	END CASE

END FUNCTION


############################################################
# FUNCTION AR_temp_tables_delete()
#
#
############################################################
FUNCTION AR_temp_tables_delete()
	DEFINE l_msg STRING
	
	WHENEVER SQLERROR CONTINUE
	
	CASE getmoduleid()
		WHEN "AR1"
			MESSAGE "Delete contents of  temp tables for AR1"
				DELETE FROM t_ar1_rpt_data_shuffle WHERE 1=1
						
		WHEN "AR2"
			MESSAGE "Delete contents of  temp tables for AR2"
				DELETE FROM t_ar2_rpt_data_shuffle WHERE 1=1
		WHEN "AR3"
			MESSAGE "Delete contents of  temp tables for AR3"
				DELETE FROM t_ar3_rpt_data_shuffle WHERE 1=1
				
		WHEN "AR5"
			MESSAGE "Delete contents of  temp tables for AR5"
				DELETE FROM t_ar5_rpt_data_shuffle WHERE 1=1
				
		WHEN "AR6"
			MESSAGE "Delete contents of  temp tables for AR6"
				DELETE FROM t_ar6_rpt_data_shuffle WHERE 1=1
				
		WHEN "AR7"
			MESSAGE "Delete contents of  temp tables for AR7"
			DELETE FROM t_taxamts WHERE 1=1 
			DELETE FROM t_basetax WHERE 1=1 
		
		WHEN "AR8"
			#MESSAGE "Delete contents of  temp tables for AR8"
			#no temp table used
		WHEN "ARA"
			MESSAGE "Delete contents of  temp tables for ARA"

		WHEN "ARB"
			MESSAGE "Delete contents of  temp tables for ARB"

		WHEN "ARC"
			MESSAGE "Delete contents of  temp tables for ARC"

		WHEN "ARD"
			MESSAGE "Delete contents of  temp tables for ARD"

		WHEN "ARR"								
			MESSAGE "Delete contents of  temp tables for ARR"

		WHEN "ART" #ART & ART_J are the same
			MESSAGE "Delete contents of  temp tables for ART"

		WHEN "ART_J" #ART & ART_J are the same
			MESSAGE "Delete contents of  temp tables for ART_J"

		OTHERWISE
			LET l_msg = "FUNCTION AR_temp_tables_create()\nInvalid Module ID =", trim(getmoduleid())
			CALL fgl_winmessage("Internal 4GL error",l_msg,"ERROR")
	END CASE

END FUNCTION



##################################################################################
# FUNCTION dropTempTableShuffle()
#
#
##################################################################################
FUNCTION droptemptableshuffle() 

	IF fgl_find_table("shuffle") THEN
		DROP TABLE shuffle 
	END IF

END FUNCTION 
{
##################################################################################
# FUNCTION dropTempTableShuffle()
#
#
##################################################################################
FUNCTION droptemptableshuffle() 
	WHENEVER SQLERROR CONTINUE 
	MESSAGE "Drop Table shuffle"
	DROP TABLE shuffle 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
}


##################################################################################
# FUNCTION dropTempTableTaxamts()
#
#
##################################################################################
FUNCTION droptemptabletaxamts() 

	IF fgl_find_table("t_taxamts") THEN
		DROP TABLE t_taxamts 
	END IF

END FUNCTION 


##################################################################################
# FUNCTION dropTempTableBasetax()
#
#
##################################################################################
FUNCTION droptemptablebasetax() 

	IF fgl_find_table("t_basetax") THEN
		DROP TABLE t_basetax 
	END IF
	
END FUNCTION 
