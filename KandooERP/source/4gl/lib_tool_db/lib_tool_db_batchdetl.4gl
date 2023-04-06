##############################################################################################
#TABLE batchdetl and t_batchdetl (static temp working table copy)
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_t_batchdetl_get_count()
#
# Return total number of rows in t_batchdetl FROM current company
############################################################
FUNCTION db_t_batchdetl_get_count()
	DEFINE ret INT
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM t_batchdetl 
		WHERE t_batchdetl.cmpy_code = $glob_rec_kandoouser.cmpy_code
		AND t_batchdetl.username = $glob_rec_kandoouser.sign_on_code
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_t_batchdetl_delete_all()
#
# Return total number of rows in t_batchdetl FROM current company
############################################################
FUNCTION db_t_batchdetl_delete_all()

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	SQL
		DELETE FROM t_batchdetl 
		WHERE t_batchdetl.cmpy_code = $glob_rec_kandoouser.cmpy_code
		AND t_batchdetl.username = $glob_rec_kandoouser.sign_on_code
	END SQL
	

END FUNCTION


############################################################
# FUNCTION batchdetl_to_t_batchdetl_rec_data_morphing(p_rec_batchdetl,l_rec_t_batchdetl)
#
# Morphs the data of a batchdet table record to t_batchdetl
############################################################
FUNCTION batchdetl_to_t_batchdetl_rec_data_morphing(p_rec_batchdetl)
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_t_batchdetl RECORD LIKE t_batchdetl.*
	DEFINE l_sign_on_code LIKE kandoouser.sign_on_code

		LET l_sign_on_code = glob_rec_kandoouser.sign_on_code
		
		LET l_rec_t_batchdetl.cmpy_code = p_rec_batchdetl.cmpy_code
		LET l_rec_t_batchdetl.jour_code = p_rec_batchdetl.jour_code
		LET l_rec_t_batchdetl.jour_num = p_rec_batchdetl.jour_num
		LET l_rec_t_batchdetl.seq_num = p_rec_batchdetl.seq_num
		LET l_rec_t_batchdetl.tran_type_ind = p_rec_batchdetl.tran_type_ind
		LET l_rec_t_batchdetl.analysis_text = p_rec_batchdetl.analysis_text
		LET l_rec_t_batchdetl.tran_date = p_rec_batchdetl.tran_date
		LET l_rec_t_batchdetl.ref_text = p_rec_batchdetl.ref_text
		LET l_rec_t_batchdetl.ref_num = p_rec_batchdetl.ref_num		
		LET l_rec_t_batchdetl.acct_code = p_rec_batchdetl.acct_code
		LET l_rec_t_batchdetl.desc_text = p_rec_batchdetl.desc_text
		LET l_rec_t_batchdetl.debit_amt = p_rec_batchdetl.debit_amt
		LET l_rec_t_batchdetl.credit_amt = p_rec_batchdetl.credit_amt
		LET l_rec_t_batchdetl.currency_code = p_rec_batchdetl.currency_code
		LET l_rec_t_batchdetl.conv_qty = p_rec_batchdetl.conv_qty
		LET l_rec_t_batchdetl.for_debit_amt = p_rec_batchdetl.for_debit_amt
		LET l_rec_t_batchdetl.for_credit_amt = p_rec_batchdetl.for_credit_amt
		LET l_rec_t_batchdetl.stats_qty = p_rec_batchdetl.stats_qty
		
		LET l_rec_t_batchdetl.username = glob_rec_kandoouser.sign_on_code

		 
		#LET l_rec_t_batchdetl.uom_code = l_rec_t_batchdetl.uom_code #uom needs to selected from coa             
	
--		SELECT uom_code INTO  l_rec_t_batchdetl.uom_code 
--		FROM coa 
--		WHERE coa.cmpy_code = l_sign_on_code
--		AND coa.acct_code = p_rec_batchdetl.acct_code
		
	
	RETURN 	l_rec_t_batchdetl.*	
END FUNCTION

FUNCTION get_batchdetl_arr_rec(p_jour_num)
	DEFINE p_jour_num LIKE batchhead.jour_num 
	
END FUNCTION