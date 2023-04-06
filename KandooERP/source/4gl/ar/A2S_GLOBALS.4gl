############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

GLOBALS 
	--DEFINE	formname        CHAR(15),
	DEFINE glob_rec_save_inv_head RECORD LIKE invoicehead.*
	DEFINE glob_rec_temp RECORD LIKE invoicehead.*
	DEFINE glob_rec_corp_cust RECORD LIKE customer.*
	DEFINE glob_rec_customership RECORD LIKE customership.*
	DEFINE glob_rec_warehouse RECORD LIKE warehouse.*
	DEFINE glob_rec_tax RECORD LIKE tax.*
	DEFINE glob_rec_invoicedetl RECORD LIKE invoicedetl.*
	--DEFINE glob_rec_cred_plus_amtvline RECORD LIKE invoicedetl.*
	DEFINE glob_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE glob_rec_cat_codecat RECORD LIKE category.*
	DEFINE glob_rec_product RECORD LIKE product.*
	DEFINE glob_rec_term RECORD LIKE term.*
	--DEFINE glob_rec_salesperson RECORD LIKE salesperson.*
	DEFINE glob_rec_stnd_grp RECORD LIKE stnd_grp.*
	DEFINE glob_rec_stnd_parms RECORD LIKE stnd_parms.*
	DEFINE glob_arr_rec_st_invoicedetl array[300] OF RECORD LIKE invoicedetl.*
	DEFINE glob_arr_rec_customer array[1000] OF RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		incld_flg CHAR(1), 
		inv_num LIKE invoicehead.inv_num 
	END RECORD 

	DEFINE glob_arr_rec_statab RECORD 
		company_cmpy_code LIKE prodstatus.cmpy_code, 
		ware LIKE prodstatus.ware_code, 
		part LIKE prodstatus.part_code, 
		ship LIKE prodstatus.onhand_qty, 
		which CHAR(3) 
	END RECORD 
	DEFINE glob_arr_rec_taxamt array[300] OF RECORD 
		tax_code LIKE tax.tax_code, 
		tax_amt LIKE invoicedetl.ext_tax_amt 
	END RECORD 

	DEFINE glob_part_code LIKE invoicedetl.part_code
	--DEFINE glob_p1_overdue LIKE customer.over1_amt
	--DEFINE glob_p1_baddue LIKE customer.over1_amt
	DEFINE glob_available LIKE prodstatus.onhand_qty
	--DEFINE glob_f_taxper LIKE tax.tax_per
	--DEFINE glob_h_taxper LIKE tax.tax_per
	DEFINE glob_func_type CHAR(14)
	--DEFINE glob_err_message CHAR(40) 
	--DEFINE glob_dec_unpr DECIMAL(13,3)
	--DEFINE glob_dec_taxp DECIMAL(13,3)
	--DEFINE glob_dec_untax DECIMAL(13,3)

	DEFINE glob_dec2fix DECIMAL(11,3)
	DEFINE glob_matcat CHAR(2)
	DEFINE glob_prmt CHAR(1)
	DEFINE glob_i SMALLINT
	DEFINE glob_ret_flag SMALLINT
	DEFINE glob_idx SMALLINT
	
	--DEFINE glob_id_flag SMALLINT#scrn, 
	DEFINE glob_noerror SMALLINT
	DEFINE glob_back_out SMALLINT
	
	DEFINE glob_first_time SMALLINT
	DEFINE glob_image_inv INTEGER
	DEFINE glob_show_inv_det CHAR(1)
	DEFINE glob_arr_size SMALLINT
	DEFINE glob_nxtfld SMALLINT
	
	--DEFINE glob_priority SMALLINT
	DEFINE glob_firstime SMALLINT
	
	--DEFINE glob_counter SMALLINT
	--DEFINE glob_err_flag SMALLINT
	
	--DEFINE glob_chng_qty DECIMAL(10,4)
	DEFINE glob_matrix CHAR(1)
	DEFINE glob_matrix_key CHAR(1)
	
	DEFINE glob_goon CHAR(1)
	DEFINE glob_ans CHAR(1)
	
	DEFINE glob_inc_tax CHAR(1)
	DEFINE glob_f_type CHAR(1)
	--DEFINE glob_try_again CHAR(1)
	
	DEFINE glob_recalc CHAR(1)
	--DEFINE glob_apart_code LIKE product.part_code
	DEFINE glob_patch_code LIKE account.acct_code
	--DEFINE glob_cogs_costt MONEY
	--DEFINE glob_inv_cost MONEY
	
	DEFINE glob_temp_inv_num INTEGER
	DEFINE glob_tot_lines SMALLINT
	DEFINE glob_edit_line CHAR(1)
	DEFINE glob_menu_path CHAR(3)
	DEFINE glob_ins_line CHAR(1)
	DEFINE glob_group_code LIKE stnd_custgrp.group_code
	DEFINE glob_del_yes CHAR(1)
	DEFINE glob_rec_opparms RECORD LIKE opparms.*
	--DEFINE glob_corp_cust SMALLINT 
END GLOBALS 


