GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_tentpays RECORD LIKE tentpays.* 
	#DEFINE glob_rec_voucher     RECORD LIKE voucher.* NOT used
	DEFINE glob_rec_cheque RECORD LIKE cheque.* 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_rec_banktype RECORD LIKE banktype.* 
	DEFINE glob_arr_doc_nums array[3000] OF LIKE tentpays.pay_doc_num 
	DEFINE glob_arr_rec_tentpays array[3000] OF 
	RECORD 
		cheq_code LIKE cheque.cheq_code, 
		vend_code LIKE tentpays.vend_code, 
		vouch_code LIKE tentpays.vouch_code, 
		due_date LIKE tentpays.due_date, 
		vouch_amt LIKE tentpays.vouch_amt, 
		taken_disc_amt LIKE tentpays.taken_disc_amt, 
		withhold_tax_ind LIKE tentpays.withhold_tax_ind 
	END RECORD 
	DEFINE glob_year_num LIKE cheque.year_num 
	DEFINE glob_period_num LIKE cheque.period_num 
	DEFINE glob_pay_meth_ind CHAR(1) 
	DEFINE glob_user_text1 LIKE kandoouser.sign_on_code 
	DEFINE glob_user_text2 LIKE kandoouser.sign_on_code 
	DEFINE glob_total_to_pay DECIMAL(12,2) 
	DEFINE glob_path_name CHAR(60) 

	DEFINE glob_chq_prt_date DATE 
	DEFINE glob_print_all_ind CHAR(20) 
	#DEFINE glob_pass_text CHAR(20)
	#DEFINE glob_head_text          CHAR(30)
	DEFINE glob_arr_size, array_idx SMALLINT 
	DEFINE glob_cycle_num LIKE tentpays.cycle_num 
	DEFINE glob_arr_cheque_code array[100] OF LIKE cheque.cheq_code 

END GLOBALS 
