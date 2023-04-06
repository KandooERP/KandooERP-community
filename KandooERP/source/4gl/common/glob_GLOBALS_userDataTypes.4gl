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

#This file IS proccessed by Aubotconf 'configure' script, TO create .4gl file

#database should be defined ONLY in glob_DATABASE.4gl
#but we have TO include it here TO, since this varibles use DEFINE ... LIKE
#so WHEN this file IS compiled, compiler would NOT have a database name OTHERWISE

#but I4gl does NOT LIKE chaining of GLOBALS files, so we must DECLARE
#DATABASE explicitly here
#GLOBALS "../common/glob_DATABASE.4gl"

#Actual name of the database will be SET FROM 'configure'

######################################################################
# huho Common goal - let's keep the global scope variable countable/short/limited/in range

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS 

	############################################################################################
	# Custom DataTypes / Structures/Records
	############################################################################################
	##############################################
	# DataTypes with A
	##############################################
	DEFINE t_rec_audit_td_vc_cc_sn_ti_sn_tt_ta TYPE AS RECORD    # used in one module! 
		tran_date LIKE apaudit.tran_date, 
		vend_code LIKE apaudit.vend_code, 
		currency_code LIKE vendor.currency_code, 
		seq_num LIKE apaudit.seq_num, 
		trantype_ind LIKE apaudit.trantype_ind, 
		source_num LIKE apaudit.source_num, 
		tran_text LIKE apaudit.tran_text, 
		tran_amt LIKE apaudit.tran_amt 
	END RECORD 

	##############################################
	# DataTypes with B
	##############################################
	DEFINE t_rec_bank_bc_na_ac TYPE AS 	RECORD		# used in 1 module! 
		bank_code LIKE bank.bank_code, 
		name_acct_text LIKE bank.name_acct_text, 
		acct_code LIKE bank.acct_code 
	END RECORD 

	DEFINE t_rec_vic_bc_dt_pc_br TYPE AS RECORD 	# used in 1 module!
		bic_code LIKE bic.bic_code, 
		desc_text LIKE bic.desc_text, 
		post_code LIKE bic.post_code, 
		bank_ref LIKE bic.bank_ref 
	END RECORD 

	DEFINE t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_with_scrollflag TYPE AS RECORD # used in 1 module!	
		scroll_flag CHAR(1), 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		jour_date LIKE batchhead.jour_date, 
		year_num LIKE batchhead.year_num, 
		period_num LIKE batchhead.period_num, 
		for_debit_amt LIKE batchhead.for_debit_amt, 
		for_credit_amt LIKE batchhead.for_credit_amt, 
		currency_code LIKE batchhead.currency_code 
	END RECORD 

	DEFINE t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_bf_with_scrollflag TYPE AS RECORD # used in 1 module!
		scroll_flag CHAR(1), 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		jour_date LIKE batchhead.jour_date, 
		year_num LIKE batchhead.year_num, 
		period_num LIKE batchhead.period_num, 
		for_debit_amt LIKE batchhead.for_debit_amt, 
		for_credit_amt LIKE batchhead.for_credit_amt, 
		currency_code LIKE batchhead.currency_code, 
		balanced_flag LIKE batchhead.post_flag 
	END RECORD 

	DEFINE t_rec_batchhead_jc_cn_cd_ec_si_yn_pn_da_ca_pf TYPE AS RECORD 	# used in 1 module
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		entry_code LIKE batchhead.entry_code, 
		source_ind LIKE batchhead.source_ind, 
		year_num LIKE batchhead.year_num, 
		period_num LIKE batchhead.period_num, 
		for_debit_amt LIKE batchhead.for_debit_amt, 
		for_credit_amt LIKE batchhead.for_credit_amt, 
		post_flag LIKE batchhead.post_flag 
	END RECORD 

	DEFINE t_rec_batchdetl2 TYPE AS RECORD 					# used in 0 module
		cmpy_code LIKE t_batchdetl.cmpy_code, 
		jour_code LIKE t_batchdetl.jour_code, 
		jour_num LIKE t_batchdetl.jour_num, 
		seq_num LIKE t_batchdetl.seq_num, 
		tran_type_ind LIKE t_batchdetl.tran_type_ind, 
		analysis_text LIKE t_batchdetl.analysis_text, 
		tran_date LIKE t_batchdetl.tran_date, 
		ref_text LIKE t_batchdetl.ref_text, 
		ref_num LIKE t_batchdetl.ref_num, 
		acct_code LIKE t_batchdetl.acct_code, 
		desc_text LIKE t_batchdetl.desc_text, 
		debit_amt LIKE t_batchdetl.debit_amt, 
		credit_amt LIKE t_batchdetl.credit_amt, 
		currency_code LIKE t_batchdetl.currency_code, 
		conv_qty LIKE t_batchdetl.conv_qty, 
		for_debit_amt LIKE t_batchdetl.for_debit_amt, 
		for_credit_amt LIKE t_batchdetl.for_credit_amt, 
		stats_qty LIKE t_batchdetl.stats_qty 
	END RECORD 
	
	#ask Vlad if we can simplify this
	DEFINE t_rec_batchdetl_username TYPE AS RECORD 		# used in 0 module
		cmpy_code LIKE t_batchdetl.cmpy_code, 
		jour_code LIKE t_batchdetl.jour_code, 
		jour_num LIKE t_batchdetl.jour_num, 
		seq_num LIKE t_batchdetl.seq_num, 
		tran_type_ind LIKE t_batchdetl.tran_type_ind, 
		analysis_text LIKE t_batchdetl.analysis_text, 
		tran_date LIKE t_batchdetl.tran_date, 
		ref_text LIKE t_batchdetl.ref_text, 
		ref_num LIKE t_batchdetl.ref_num, 
		acct_code LIKE t_batchdetl.acct_code, 
		desc_text LIKE t_batchdetl.desc_text, 
		debit_amt LIKE t_batchdetl.debit_amt, 
		credit_amt LIKE t_batchdetl.credit_amt, 
		currency_code LIKE t_batchdetl.currency_code, 
		conv_qty LIKE t_batchdetl.conv_qty, 
		for_debit_amt LIKE t_batchdetl.for_debit_amt, 
		for_credit_amt LIKE t_batchdetl.for_credit_amt, 
		stats_qty LIKE t_batchdetl.stats_qty, 
		username LIKE t_batchdetl.username 
	END RECORD 

# this type matches one main ARRAY element
	DEFINE t_rec_batchdetl TYPE AS RECORD 		# defined in 2 modules wow!   ( joswind.4gl, G21a.4gl
		scroll_flag char(1), 
		seq_num LIKE batchdetl.seq_num, 
		acct_code LIKE batchdetl.acct_code, 
		analysis_text LIKE batchdetl.analysis_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		stats_qty LIKE batchdetl.stats_qty, 
		uom_code LIKE coa.uom_code, 
		ref_text LIKE batchdetl.ref_text, # #ali feature request 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 

	#SELECT .... c.uom_code,b.ref_text,b.desc_text  FROM t_batchdetl b,  OUTER coa c WHERE b.acct_code = c.acct_code  AND b.cmpy_code = c.cmpy_code AND 1=1 AND b.username = ''AnBl'' ORDER BY b.seq_num
	DEFINE t_rec_temp_batchdetl TYPE AS RECORD 		# used in 1 module G21a
		seq_num LIKE t_batchdetl.seq_num, 
		acct_code LIKE t_batchdetl.acct_code, 
		analysis_text LIKE t_batchdetl.analysis_text, 
		for_debit_amt LIKE t_batchdetl.for_debit_amt, 
		for_credit_amt LIKE t_batchdetl.for_credit_amt, 
		stats_qty LIKE t_batchdetl.stats_qty, 
		uom_code LIKE coa.uom_code, #huho @eric, are you sure we should NOT keep the uom_code in your new static temp TABLE ? in program logice, the value can be changed 
		ref_text LIKE t_batchdetl.ref_text, # #ali feature request 
		desc_text LIKE t_batchdetl.desc_text 
	END RECORD 


	##############################################
	# DataTypes with C
	##############################################
	DEFINE t_rec_cmpy_access_cc_ct_lc_am_with_scrollflag TYPE AS RECORD 	# used in 1 module U12a
		scroll_flag CHAR (1), 
		curr_code LIKE company.cmpy_code,
		cmpy_text LIKE company.name_text, 
		locn_code LIKE userlocn.locn_code, 
		acct_mask_code LIKE kandoousercmpy.acct_mask_code 
	END RECORD 

	DEFINE t_rec_customer_cc_nt_tt_with_scrollflag TYPE AS RECORD 			# used in 1 module clntwind.4gl
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		tele_text LIKE customer.tele_text 
	END RECORD 

	DEFINE t_rec_customertype_tc_tt TYPE AS	RECORD 							# used in 1 module AZ4.4gl
		#scroll_flag CHAR(1),
		type_code LIKE customertype.type_code, 
		type_text LIKE customertype.type_text 
	END RECORD 

	DEFINE t_rec_cart_area_cc_dt_with_scrollflag TYPE AS RECORD			# used in 1 module wcartwin.4gl 
		scroll_flag CHAR(1), 
		cart_area_code LIKE cartarea.cart_area_code, 
		desc_text LIKE cartarea.desc_text 
	END RECORD 

	DEFINE t_rec_currency_cd_dt_st TYPE AS RECORD 					# used in 1 module currwind.4gl
		currency_code LIKE currency.currency_code, 
		desc_text LIKE currency.desc_text, 
		symbol_text LIKE currency.symbol_text 
	END RECORD 

	DEFINE t_rec_company_c_n_c_t TYPE AS RECORD 
		cmpy_code LIKE company.cmpy_code, 
		name_text LIKE company.name_text, 
		city_text LIKE company.city_text, 
		tele_text LIKE company.tele_text 
	END RECORD 

	DEFINE t_rec_company_c_n_c_c_t_t_a_c_m TYPE AS 
	RECORD 
		cmpy_code LIKE company.cmpy_code, 
		name_text LIKE company.name_text, 
		country_code LIKE company.country_code, 
		city_text LIKE company.city_text, 
		tele_text LIKE company.tele_text, 
		tax_text LIKE company.tax_text, 
		vat_code LIKE company.vat_code, 
		curr_code LIKE company.curr_code, 
		module_text LIKE company.module_text 
	END RECORD 


	DEFINE t_rec_class_c_d TYPE AS 
	RECORD 
		class_code LIKE class.class_code, 
		desc_text LIKE class.desc_text 
	END RECORD 



	DEFINE t_rec_carrier_cd_na_cy TYPE AS 
	RECORD 
		carrier_code LIKE carrier.carrier_code, 
		name_text LIKE carrier.name_text, 
		city_text LIKE carrier.city_text 
	END RECORD 

	DEFINE t_rec_carriercost_co_st_fi_fa TYPE AS 
	RECORD 
		country_code LIKE carriercost.country_code, 
		state_code LIKE carriercost.state_code, 
		freight_ind LIKE carriercost.freight_ind, 
		freight_amt LIKE carriercost.freight_amt 
	END RECORD 

	DEFINE t_rec_carriercost_no_ccode_cmpy TYPE AS 
	RECORD 
		country_code LIKE carriercost.country_code, 
		state_code LIKE carriercost.state_code, 
		freight_ind LIKE carriercost.freight_ind, 
		freight_amt LIKE carriercost.freight_amt 
	END RECORD 


	##############################################
	# DataTypes with D
	##############################################
	DEFINE t_rec_debitdist_vc_nt_cc_dc_ln_ac_dt_da_dq_cq_bd TYPE AS 
	RECORD 
		vend_code LIKE debitdist.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_code LIKE debitdist.debit_code, 
		line_num LIKE debitdist.line_num, 
		acct_code LIKE debitdist.acct_code, 
		desc_text LIKE debitdist.desc_text, 
		dist_amt LIKE debitdist.dist_amt, 
		dist_qty LIKE debitdist.dist_qty, 
		conv_qty LIKE debithead.conv_qty, 
		base_dist_amt LIKE debitdist.dist_amt 
	END RECORD 
	##############################################
	# DataTypes with E
	##############################################

	##############################################
	# DataTypes with F
	##############################################

	##############################################
	# DataTypes with G
	##############################################
	DEFINE t_rec_groupinfo_no_cmpy_code TYPE AS 
	RECORD 
		group_code LIKE groupinfo.group_code, 
		desc_text LIKE groupinfo.desc_text 
	END RECORD 

	##############################################
	# DataTypes with H
	##############################################

	##############################################
	# DataTypes with I
	##############################################
	DEFINE t_rec_ingroup_i_d_t TYPE AS 
	RECORD 
		ingroup_code LIKE ingroup.ingroup_code, 
		desc_text LIKE ingroup.desc_text, 
		type_ind LIKE ingroup.type_ind 
	END RECORD 

	DEFINE t_rec_ingroup_i_d TYPE AS 
	RECORD 
		ingroup_code LIKE ingroup.ingroup_code, 
		desc_text LIKE ingroup.desc_text 
	END RECORD 



	DEFINE t_rec_invoicedetl_ln_lt_sq_lt_lc_with_lineflag TYPE AS RECORD 
		line_flag CHAR(1), 
		line_num LIKE invoicedetl.line_num, 
		line_text LIKE invoicedetl.line_text, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		line_cred_amt LIKE invoicedetl.line_total_amt 
	END RECORD 

	DEFINE t_rec_invoicehead_in_id_pc_ia_ca_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_amt LIKE invoicehead.total_amt, 
		credit_amt LIKE invoicehead.total_amt 
	END RECORD 

	DEFINE dt_rec_invoicedetl_list TYPE AS RECORD
		scroll_flag CHAR(1), 
		line_num LIKE invoicedetl.line_num, 
		ware_code LIKE invoicedetl.ware_code,
		part_code LIKE invoicedetl.part_code, 
		line_text LIKE invoicedetl.line_text, 
		line_acct_code LIKE invoicedetl.line_acct_code,
		tax_code LIKE invoicedetl.tax_code,
		tax_per LIKE tax.tax_per,
		ship_qty LIKE invoicedetl.ship_qty, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		disc_amt LIKE invoicedetl.disc_amt,
		unit_tax_amt LIKE invoicedetl.unit_tax_amt,
		ext_sale_amt LIKE invoicedetl.ext_sale_amt,
		ext_tax_amt LIKE invoicedetl.ext_tax_amt,
		line_total_amt LIKE invoicedetl.line_total_amt		 
	END RECORD 

	##############################################
	# DataTypes with J
	##############################################
	DEFINE t_rec_jmpo_pd_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		po_description LIKE jmpo_description.po_description 
	END RECORD 



	##############################################
	# DataTypes with K
	##############################################
	DEFINE t_rec_kandoouser TYPE AS 
	RECORD 
		sign_on_code LIKE kandoouser.sign_on_code, 
		name_text LIKE kandoouser.name_text, 
		security_ind LIKE kandoouser.security_ind, 
		password_text LIKE kandoouser.password_text, 
		language_code LIKE kandoouser.language_code, 
		cmpy_code LIKE kandoouser.cmpy_code, 
		acct_mask_code LIKE kandoouser.acct_mask_code, 
		profile_code LIKE kandoouser.profile_code, 
		access_ind LIKE kandoouser.access_ind, 
		sign_on_date LIKE kandoouser.sign_on_date, 
		print_text LIKE kandoouser.print_text, 
		act_spawn_num LIKE kandoouser.act_spawn_num, 
		max_spawn_num LIKE kandoouser.max_spawn_num, 
		group_code LIKE kandoouser.group_code, 
		signature_text LIKE kandoouser.signature_text, 
		passwd_ind LIKE kandoouser.passwd_ind, 
		memo_pri_ind LIKE kandoouser.memo_pri_ind, 
		email LIKE kandoouser.email, 
		login_name LIKE kandoouser.login_name, 
		user_role_code LIKE kandoouser.user_role_code, 
		cheque_group_code LIKE kandoouser.cheque_group_code, 
		pwchdate LIKE kandoouser.pwchdate, 
		pwchange LIKE kandoouser.pwchange 
	END RECORD 

	DEFINE t_rec_kandoouser_ord TYPE AS 
	RECORD 
		login_name LIKE kandoouser.login_name, 
		sign_on_code LIKE kandoouser.sign_on_code, 
		name_text LIKE kandoouser.name_text, 
		security_ind LIKE kandoouser.security_ind, 
		password_text LIKE kandoouser.password_text, 
		language_code LIKE kandoouser.language_code, 
		cmpy_code LIKE kandoouser.cmpy_code, 
		acct_mask_code LIKE kandoouser.acct_mask_code, 
		profile_code LIKE kandoouser.profile_code, 
		access_ind LIKE kandoouser.access_ind, 
		sign_on_date LIKE kandoouser.sign_on_date, 
		print_text LIKE kandoouser.print_text, 
		act_spawn_num LIKE kandoouser.act_spawn_num, 
		max_spawn_num LIKE kandoouser.max_spawn_num, 
		group_code LIKE kandoouser.group_code, 
		signature_text LIKE kandoouser.signature_text, 
		passwd_ind LIKE kandoouser.passwd_ind, 
		memo_pri_ind LIKE kandoouser.memo_pri_ind, 
		email LIKE kandoouser.email, 
		user_role_code LIKE kandoouser.user_role_code, 
		cheque_group_code LIKE kandoouser.cheque_group_code, 
		pwchdate LIKE kandoouser.pwchdate, 
		pwchange LIKE kandoouser.pwchange 
	END RECORD 

	DEFINE t_rec_kandoouser_sc_nt_si_am TYPE AS 
	RECORD 
		#scroll_flag CHAR(1),
		sign_on_code LIKE kandoouser.sign_on_code, 
		name_text LIKE kandoouser.name_text, 
		security_ind LIKE kandoouser.security_ind, 
		acct_mask_code LIKE kandoouser.acct_mask_code 
	END RECORD 

	DEFINE t_rec_kandoousercmpy TYPE AS 
	RECORD 
		sign_on_code LIKE kandoousercmpy.sign_on_code, 
		cmpy_code LIKE kandoousercmpy.cmpy_code, 
		acct_mask_code LIKE kandoousercmpy.acct_mask_code 
	END RECORD 

	DEFINE t_rec_kandoomask_am_at_with_scrollflag TYPE AS 
	RECORD 
		delete_flag CHAR(1), 
		acct_mask_code LIKE kandoomask.acct_mask_code, 
		access_type_code LIKE kandoomask.access_type_code 
	END RECORD 

	DEFINE t_rec_kandoomemo_fc_st_sd_rf_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		from_code LIKE kandoomemo.from_code, 
		subject_text LIKE kandoomemo.subject_text, 
		sent_datetime LIKE kandoomemo.sent_datetime, 
		read_flag LIKE kandoomemo.read_flag 
	END RECORD 

	DEFINE t_rec_kandooword_rc_rt_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		reference_code LIKE kandooword.reference_code, 
		response_text LIKE kandooword.response_text 
	END RECORD 

	##############################################
	# DataTypes with L
	##############################################

	DEFINE t_rec_location_lc_dt_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		locn_code LIKE location.locn_code, 
		desc_text LIKE location.desc_text 
	END RECORD 

	DEFINE t_rec_location_cc_lc_dt_ad,ci,co TYPE AS 

	RECORD 
		cmpy_code char(2), 
		locn_code nchar(3), 
		desc_text nvarchar(40,0), 
		addr1_text nvarchar(40,0), 
		city_text nvarchar(40,0), 
		country_code nchar(3) 
	END RECORD 

	##############################################
	# DataTypes with M
	##############################################

	##############################################
	# DataTypes with N
	##############################################

	##############################################
	# DataTypes with O
	##############################################

	##############################################
	# DataTypes with P
	##############################################

	DEFINE t_rec_priv_access_df_gd_pc_sm_spg TYPE AS 
	RECORD 
		delete_flag CHAR(1), 
		grant_deny_flag CHAR(1), 
		path_code CHAR(3), 
		security_module_ind CHAR(1), 
		security_prog_ind CHAR(1) 
	END RECORD 



	DEFINE t_rec_product_pc_dt_wc_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD 

	DEFINE t_rec_product_pc_dt_gc_mc_nt_rs_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		prodgrp_code LIKE product.prodgrp_code, 
		maingrp_code LIKE product.maingrp_code, 
		notes CHAR(1), 
		relationship CHAR(1) 
	END RECORD 


	DEFINE t_rec_prodadjtype_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag char, 
		vend_code LIKE vendorinvs.vend_code, 
		inv_text LIKE vendorinvs.inv_text, 
		vouch_code LIKE vendorinvs.vouch_code, 
		entry_date LIKE vendorinvs.entry_date 

	END RECORD 


	DEFINE t_rec_prodadjtype_ac_dt_ac TYPE AS 
	RECORD 
		source_code LIKE prodadjtype.adj_type_code, 
		desc_text LIKE prodadjtype.desc_text, 
		adj_acct_code LIKE prodadjtype.adj_acct_code 

	END RECORD 

	DEFINE t_rec_prodadjtype_ac_dt_ac_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		source_code LIKE prodadjtype.adj_type_code, 
		desc_text LIKE prodadjtype.desc_text, 
		adj_acct_code LIKE prodadjtype.adj_acct_code 

	END RECORD 


	DEFINE t_rec_product_alter_p_d TYPE AS 
	RECORD 
		part_code LIKE product.part_code, 
		product_text CHAR(54) 
	END RECORD 

	DEFINE t_rec_product_pc_dt_pc_mc_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		prodgrp_code LIKE product.prodgrp_code, 
		maingrp_code LIKE product.maingrp_code 
	END RECORD 

	DEFINE t_rec_product_pc_dt_pc_mc TYPE AS 
	RECORD 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		prodgrp_code LIKE product.prodgrp_code, 
		maingrp_code LIKE product.maingrp_code 
	END RECORD 


	DEFINE t_rec_printcodes_pc_dt_wn_ln TYPE AS 
	RECORD 
		print_code LIKE printcodes.print_code, 
		desc_text LIKE printcodes.desc_text, 
		width_num LIKE printcodes.width_num, 
		length_num LIKE printcodes.length_num 
	END RECORD 

	##############################################
	# DataTypes with Q
	##############################################

	##############################################
	# DataTypes with R
	##############################################

	DEFINE t_rec_resgrp_rc_rt_rt_with_scrollflag TYPE AS 
	RECORD 
		scroll_flag CHAR(1), 
		resgrp_code LIKE resgrp.resgrp_code, 
		resgrp_text LIKE resgrp.resgrp_text, 
		res_type_ind LIKE resgrp.res_type_ind 
	END RECORD 

	DEFINE t_rec_rptpos_id_de TYPE AS 
	RECORD 
		rptpos_id LIKE rptpos.rptpos_id, 
		rptpos_desc LIKE rptpos.rptpos_desc 
	END RECORD 

	DEFINE t_rec_rpttype_id_de TYPE AS 
	RECORD 
		rpttype_id LIKE rpttype.rpttype_id, 
		rpttype_desc LIKE rpttype.rpttype_desc 
	END RECORD 

	DEFINE t_rec_rndcode_id_de TYPE AS 
	RECORD 
		rnd_code LIKE rndcode.rnd_code, 
		rnd_desc LIKE rndcode.rnd_desc, 
		rnd_value LIKE rndcode.rnd_value 
	END RECORD 



	##############################################
	# DataTypes with S
	##############################################
	DEFINE t_rec_securitye_mc_nt_si TYPE AS 
	RECORD 
		module_code LIKE kandoomodule.module_code, 
		name_text LIKE menu1.name_text, 
		security_ind LIKE kandoomodule.security_ind 
	END RECORD 


	DEFINE t_rec_structure_ti_sn_ln_dt TYPE AS RECORD 
		type_ind LIKE structure.type_ind, 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		default_text LIKE structure.default_text 
	END RECORD 


	DEFINE t_rec_salesperson_sc_nt_tc_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		terri_code LIKE salesperson.terri_code 
	END RECORD 


	DEFINE t_rec_street_st_ty_su_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		street_text LIKE street.street_text, 
		st_type_text LIKE street.st_type_text, 
		suburb_text LIKE suburb.suburb_text 
	END RECORD 

	DEFINE t_rec_suburb_ri_mn_rt_si_sc TYPE AS RECORD 
		row_id INTEGER, 					# FIXME: this table has a horrible unique key  
		map_number LIKE street.map_number, 
		ref_text LIKE street.ref_text, 
		source_ind LIKE street.source_ind, 
		suburb_code LIKE suburb.suburb_code 
	END RECORD 


	DEFINE t_rec_suburb_st_sc_pc_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		suburb_text LIKE suburb.suburb_text, 
		state_code LIKE suburb.state_code, 
		post_code LIKE suburb.post_code 
	END RECORD 

	DEFINE t_rec_suburb_sc_st_sc_pc TYPE AS RECORD 
		suburb_code LIKE suburb.suburb_code, 
		suburb_text LIKE suburb.suburb_text, 
		state_code LIKE suburb.state_code, 
		post_code LIKE suburb.post_code 
	END RECORD 

	DEFINE t_rec_supply_wc_dt_kq_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		ware_code LIKE supply.ware_code, 
		desc_text LIKE warehouse.desc_text, 
		km_qty LIKE supply.km_qty 
	END RECORD 


	DEFINE t_rec_suburbarea_wc_nt_ca_tc_sc_with_scrollflag TYPE AS 	RECORD 
		scroll_flag CHAR(1), 
		waregrp_code LIKE suburbarea.waregrp_code, 
		name_text LIKE waregrp.name_text, 
		cart_area_code LIKE suburbarea.cart_area_code, 
		terr_code LIKE suburbarea.terr_code, 
		sale_code LIKE suburbarea.sale_code 
	END RECORD 

	##############################################
	# DataTypes with T
	##############################################

	DEFINE t_rec_territorytax_tc_dt_ac_with_scrollflag TYPE AS 	RECORD 
		scroll_flag CHAR(1), 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code 
	END RECORD 

	DEFINE t_rec_tax_tc_dt_cm_tp_with_scrollflag TYPE AS 	RECORD 
		scroll_flag CHAR(1), 
		tax_code LIKE tax.tax_code, 
		desc_text LIKE tax.desc_text, 
		calc_method_flag LIKE tax.calc_method_flag, 
		tax_per LIKE tax.tax_per 
	END RECORD 

	DEFINE t_rec_tax_tc_dt_cm_tp TYPE AS RECORD 
		tax_code LIKE tax.tax_code, 
		desc_text LIKE tax.desc_text, 
		calc_method_flag LIKE tax.calc_method_flag, 
		tax_per LIKE tax.tax_per 
	END RECORD 

	DEFINE t_rec_term_tc_dt_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		term_code LIKE term.term_code, 
		desc_text LIKE term.desc_text 
	END RECORD 


	DEFINE t_rec_signcode_co_de_ch_ba TYPE AS RECORD 
		sign_code LIKE signcode.sign_code, 
		sign_desc LIKE signcode.sign_desc, 
		sign_change LIKE signcode.sign_change, 
		sign_base LIKE signcode.sign_base 
	END RECORD 

	##############################################
	# DataTypes with U
	##############################################


	DEFINE t_rec_userlocn_cc_lc_dt_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		cmpy_code LIKE userlocn.cmpy_code, 
		locn_code LIKE userlocn.locn_code, 
		desc_text LIKE location.desc_text 
	END RECORD 

	##############################################
	# DataTypes with V
	##############################################

	DEFINE t_rec_validflex_fc_dt_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		flex_code LIKE validflex.flex_code, 
		desc_text LIKE validflex.desc_text 
	END RECORD 


	DEFINE t_rec_voucher_ve_vc_pn_vd_ec_ed_ta_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE voucher.vend_code, 
		vouch_code LIKE voucher.vouch_code, 
		po_num LIKE voucher.po_num, 
		vouch_date LIKE voucher.vouch_date, 
		entry_code LIKE voucher.entry_code, 
		entry_date LIKE voucher.entry_date, 
		total_amt LIKE voucher.total_amt 
	END RECORD 


	DEFINE t_rec_voucher_vo_ve_da_ye_pe_ta_da TYPE AS RECORD 
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		dist_amt LIKE voucher.dist_amt 
	END RECORD 

	DEFINE t_rec_voucher_vo_ve_da_ye_pe_ta_da_with_scrollflag TYPE AS RECORD 
		scroll_flag char, 
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		dist_amt LIKE voucher.dist_amt 
	END RECORD 


	DEFINE t_rec_voucher_vo_it_vd_yn_pn_pf_ta_pa_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		post_flag LIKE voucher.post_flag , 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt 
	END RECORD 


	DEFINE t_rec_vendortype_tc_tt_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE vendortype.type_code, 
		type_text LIKE vendortype.type_text 
	END RECORD 

	DEFINE t_rec_vendorinvs TYPE AS RECORD 
		vend_code LIKE vendorinvs.vend_code, 
		inv_text LIKE vendorinvs.inv_text, 
		vouch_code LIKE vendorinvs.vouch_code, 
		entry_date LIKE vendorinvs.entry_date 

	END RECORD 




	DEFINE t_rec_vendor_vc_nt_ct TYPE AS RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
		contact_text LIKE vendor.contact_text 
	END RECORD 

	DEFINE t_rec_vendor_vc_nt_ad TYPE AS RECORD 
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 


	DEFINE t_rec_vendorgrp_mv_dt TYPE AS RECORD 
		mast_vend_code LIKE vendorgrp.mast_vend_code, 
		desc_text LIKE vendorgrp.desc_text 
	END RECORD 

	DEFINE t_rec_vendornote_nd_nt TYPE AS RECORD 
		note_date LIKE vendornote.note_date, 
		note_text LIKE vendornote.note_text 
	END RECORD 


	DEFINE t_rec_vendor_vc_nt TYPE AS RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text 
	END RECORD 

	DEFINE t_rec_vendor_filter TYPE AS RECORD 
		filter_vend_code LIKE vendor.vend_code, 
		filter_name_text LIKE vendor.name_text 
	END RECORD 

	DEFINE t_rec_vendor_search TYPE AS RECORD 
		filter_any_field STRING 
	END RECORD 

	DEFINE t_rec_vendor_nocmpyid TYPE AS RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text, 
		addr2_text LIKE vendor.addr2_text, 
		addr3_text LIKE vendor.addr3_text, 
		city_text LIKE vendor.city_text, 
		state_code LIKE vendor.state_code, 
		post_code LIKE vendor.post_code, 
--@db-patch_2020_10_04 		country_text LIKE vendor.country_text, 
		country_code LIKE vendor.country_code, 
		language_code LIKE vendor.language_code, 
		type_code LIKE vendor.type_code, 
		term_code LIKE vendor.term_code, 
		tax_code LIKE vendor.tax_code, 
		setup_date LIKE vendor.setup_date, 
		last_mail_date LIKE vendor.last_mail_date, 
		tax_text LIKE vendor.tax_text, 
		our_acct_code LIKE vendor.our_acct_code, 
		contact_text LIKE vendor.contact_text, 
		tele_text LIKE vendor.tele_text, 
		extension_text LIKE vendor.extension_text, 
		acct_text LIKE vendor.acct_text, 
		limit_amt LIKE vendor.limit_amt, 
		bal_amt LIKE vendor.bal_amt, 
		highest_bal_amt LIKE vendor.highest_bal_amt, 
		curr_amt LIKE vendor.curr_amt, 
		over1_amt LIKE vendor.over1_amt, 
		over30_amt LIKE vendor.over30_amt, 
		over60_amt LIKE vendor.over60_amt, 
		over90_amt LIKE vendor.over90_amt, 
		onorder_amt LIKE vendor.onorder_amt, 
		avg_day_paid_num LIKE vendor.avg_day_paid_num, 
		last_debit_date LIKE vendor.last_debit_date, 
		last_po_date LIKE vendor.last_po_date, 
		last_vouc_date LIKE vendor.last_vouc_date, 
		last_payment_date LIKE vendor.last_payment_date, 
		next_seq_num LIKE vendor.next_seq_num, 
		hold_code LIKE vendor.hold_code, 
		usual_acct_code LIKE vendor.usual_acct_code, 
		ytd_amt LIKE vendor.ytd_amt, 
		min_ord_amt LIKE vendor.min_ord_amt, 
		drop_flag LIKE vendor.drop_flag, 
		finance_per LIKE vendor.finance_per, 
		fax_text LIKE vendor.fax_text, 
		currency_code LIKE vendor.currency_code, 
		bank_acct_code LIKE vendor.bank_acct_code, 
		bank_code LIKE vendor.bank_code, 
		pay_meth_ind LIKE vendor.pay_meth_ind, 
		bkdetls_mod_flag LIKE vendor.bkdetls_mod_flag, 
		purchtype_code LIKE vendor.purchtype_code, 
		po_var_per LIKE vendor.po_var_per, 
		po_var_amt LIKE vendor.po_var_amt, 
		def_exp_ind LIKE vendor.def_exp_ind, 
		backorder_flag LIKE vendor.backorder_flag, 
		contra_cust_code LIKE vendor.contra_cust_code, 
		contra_meth_ind LIKE vendor.contra_meth_ind, 
		vat_code LIKE vendor.vat_code, 
		tax_incl_flag LIKE vendor.tax_incl_flag 
	END RECORD 

	##############################################
	# DataTypes with W
	##############################################
	DEFINE t_rec_warehouse_w_d_c_t TYPE AS RECORD 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text, 
		contact_text LIKE warehouse.contact_text, 
		tele_text LIKE warehouse.tele_text,
		mobile_phone LIKE warehouse.mobile_phone,
		email LIKE warehouse.email 
	END RECORD 

	DEFINE t_rec_waregrp_wc_nt_with_scrollflag TYPE AS RECORD 
		scroll_flag CHAR(1), 
		waregrp_code LIKE waregrp.waregrp_code, 
		name_text LIKE waregrp.name_text 
	END RECORD 

	# this type serves for scan arrays of coa displayed in tree table
	DEFINE t_rec_coa_for_tree TYPE AS RECORD
		description LIKE coa.desc_text,
		id LIKE coa.acct_code,
		parentId LIKE coa.parentId,
		isnominal LIKE coa.is_nominalcode
	END RECORD
	##############################################
	# DataTypes with X
	##############################################

	##############################################
	# DataTypes with Y
	##############################################
	##############################################
	# DataTypes with Z
	##############################################
	----------
END GLOBALS 
