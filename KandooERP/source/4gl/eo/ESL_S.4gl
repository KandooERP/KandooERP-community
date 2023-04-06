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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ESL_GLOBALS.4gl"
 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_orderhead RECORD LIKE orderhead.* 
DEFINE modu_rec_orderdetl RECORD LIKE orderdetl.* 
DEFINE modu_rec_orderdetlog RECORD LIKE orderdetlog.* 
###########################################################################
# FUNCTION ESL_S_main()
#
# ESL_S - Order Import
###########################################################################
FUNCTION ESL_S_main() 
	DEFINE l_loadparms_load_ind LIKE loadparms.load_ind 
	DEFINE l_arg_load_ind LIKE loadparms.load_ind #via URL
	DEFINE l_arg_cmpy_code LIKE company.cmpy_code #via URL
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ESL_S")  

	IF fgl_find_table("t_profit") THEN
		DELETE FROM t_profit
	ELSE
		CREATE temp TABLE t_profit (dept_code char(1), 
		cust_code char(3), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3)) with no LOG
	END IF
		 
	LET glob_update_ind = TRUE 

	#IF num_args() > 0 THEN
	
	LET l_arg_load_ind = get_url_load_ind() #from URL
	LET l_arg_cmpy_code = get_url_cmpy_code() #from URL
	IF l_arg_load_ind IS NOT NULL AND glob_rec_kandoouser.cmpy_code IS NOT NULL THEN  
		# CALL it with arguments so we know it called in background
		LET glob_rec_kandoouser.cmpy_code = l_arg_cmpy_code #cmpy_code 
		LET l_loadparms_load_ind = l_arg_load_ind #load_ind
 
		DECLARE c1_loadparms cursor FOR 
		SELECT * FROM loadparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = 'EO' 
		AND load_ind = l_loadparms_load_ind 
		OPEN c1_loadparms 
		FETCH c1_loadparms INTO glob_rec_loadparms.*
		 
		LET glob_gv_background = 'Y' 
		CALL load_routine() 
	ELSE 
		DECLARE c_loadparms cursor FOR 
		SELECT * FROM loadparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = 'EO' 
		AND format_ind = '1' 
		ORDER BY load_ind 
		OPEN c_loadparms 
		FETCH c_loadparms INTO glob_rec_loadparms.*
		 
		LET glob_gv_background = 'N' 
		CALL get_parameters() 
	END IF 

	EXIT PROGRAM(glob_err_cnt) 

END FUNCTION 
###########################################################################
# END FUNCTION ESL_S_main()
###########################################################################


###########################################################################
# FUNCTION load_routine() 
#
# 
###########################################################################
FUNCTION load_routine()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE l_loadparms_load_num LIKE loadparms.load_num 
	DEFINE l_loadparms_load_ind LIKE loadparms.load_ind
	DEFINE l_err_text char(200) 

	SELECT (seq_num + 1) INTO glob_rec_loadparms.seq_num FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "EO" 
	AND load_ind = glob_rec_loadparms.load_ind 
	WHENEVER ERROR CONTINUE 
	
	UPDATE loadparms 
	SET seq_num = glob_rec_loadparms.seq_num 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND load_ind = glob_rec_loadparms.load_ind 
	AND module_code = "EO" 
	WHENEVER ERROR stop 
	#   LET glob_err_cnt = 0

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("ESL_E","ESL_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ESL_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
--	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("ESL_D","ESL_rpt_list_detailed","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ESL_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
--	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	IF glob_rec_loadparms.path_text IS NULL 
	OR length(glob_rec_loadparms.path_text) = 0 THEN 
		LET glob_rec_loadparms.path_text = "." 
	END IF 

	IF list_files_to_process(glob_rec_loadparms.path_text, 
	glob_rec_loadparms.file_text) THEN 
		### Process list of files collected ###
		DECLARE c_filelist cursor with hold FOR 
		SELECT * FROM t_filelist 
		WHERE file_name NOT matches "*.tmp" 
		FOREACH c_filelist INTO glob_load_file 
			LET glob_err_cnt = 0 
			LET l_loadparms_load_num = speeds_load() 

			IF l_loadparms_load_num < 0 THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Refer ",trim(get_settings_logFile()), " FOR SQL Error: ", 
				l_loadparms_load_num USING "<<<<<<<<"," in LOAD file: ", 
				glob_load_file clipped 
				OUTPUT TO REPORT ESL_rpt_list_exception("","","",glob_err_message) 
				LET l_err_text = "ESL - ",err_get(l_loadparms_load_num) 
				CALL errorlog(l_err_text) 
				LET l_loadparms_load_num = 0 
			END IF 
			WHENEVER ERROR CONTINUE 
			LET glob_rec_loadparms.load_date = today 
			LET glob_rec_loadparms.load_num = l_loadparms_load_num 
			UPDATE loadparms 
			SET load_date = glob_rec_loadparms.load_date, 
			load_num = glob_rec_loadparms.load_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND load_ind = glob_rec_loadparms.load_ind 
			AND module_code = "EO" 
			AND seq_num = glob_rec_loadparms.seq_num 
			WHENEVER ERROR stop 
			
			IF glob_err_cnt THEN 
				IF glob_gv_background <> 'Y' THEN 
					CALL display_parms() 
					ERROR kandoomsg2("E",7095,glob_err_cnt) 			#7095 Load Complete.  ??? Errors Encountered.
				END IF 
			ELSE 
				IF glob_gv_background <> 'Y' THEN 
					CALL display_parms() 
					MESSAGE kandoomsg2("E",7096,"") 					#7096 Load Completed Successfully.
				END IF 
				#---------------------------------------------------------
				OUTPUT TO REPORT ESL_rpt_list_exception(l_rpt_idx,
				"","","", 
						"Order Load Completed successfully") 
				#---------------------------------------------------------

			END IF 
		END FOREACH 
		
	END IF
	 

	#------------------------------------------------------------
	FINISH REPORT ESL_rpt_list_exception
	CALL rpt_finish("ESL_rpt_list_exception")
	#------------------------------------------------------------
	#------------------------------------------------------------
	FINISH REPORT ESL_rpt_list_detailed
	CALL rpt_finish("ESL_rpt_list_detailed")
	#------------------------------------------------------------	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 
###########################################################################
# END FUNCTION load_routine() 
###########################################################################


###########################################################################
# FUNCTION create_orderdetl(l_rec_profit)   
#
# 
###########################################################################
FUNCTION create_orderdetl(l_rec_profit) 
	DEFINE l_rec_profit RECORD 
		dept_code char(1), 
		cust_code char(3), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3) 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_order_qty LIKE orderdetl.order_qty 
	DEFINE l_avail_qty LIKE orderdetl.order_qty 

	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE l_rec_product.* TO NULL 
	INITIALIZE l_rec_prodstatus.* TO NULL 
	INITIALIZE modu_rec_orderdetl.* TO NULL 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = l_rec_profit.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = l_rec_profit.part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE part_code = l_rec_profit.part_code 
	AND ware_code = l_rec_profit.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET modu_rec_orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_orderdetl.cust_code = l_rec_profit.cust_code 
	LET modu_rec_orderdetl.order_num = modu_rec_orderhead.order_num 
	LET modu_rec_orderdetl.part_code = l_rec_profit.part_code 
	LET modu_rec_orderdetl.ware_code = l_rec_profit.ware_code 
	LET modu_rec_orderdetl.cat_code = l_rec_product.cat_code 
	LET modu_rec_orderdetl.order_qty = l_rec_profit.suggested_stock
	 
	SELECT sum(order_qty - inv_qty) INTO l_order_qty FROM orderdetl 
	WHERE cust_code = l_rec_profit.cust_code 
	AND part_code = l_rec_profit.part_code 
	AND order_qty > inv_qty 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	IF l_order_qty IS NOT NULL 
	AND l_order_qty > 0 THEN 
		LET modu_rec_orderdetl.order_qty = modu_rec_orderdetl.order_qty - l_order_qty 
		IF modu_rec_orderdetl.order_qty <= 0 THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			LET glob_err_message = "Order quantity exceeded by previous order" 
			OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
			l_rec_profit.part_code, 
			l_rec_profit.order_ref, 
			glob_err_message) 
			RETURN FALSE 
		END IF 
	END IF 

	LET l_avail_qty = stock_status(l_rec_profit.part_code,l_rec_profit.ware_code) 
	IF l_avail_qty <= 0 THEN 
		LET glob_err_cnt = glob_err_cnt + 1 
		LET glob_err_message = "No stock available FOR this ORDER line" 
		OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
		l_rec_profit.part_code, 
		l_rec_profit.order_ref, 
		glob_err_message) 
		RETURN FALSE 
	END IF 

	IF l_avail_qty < modu_rec_orderdetl.order_qty THEN 
		LET modu_rec_orderdetl.order_qty = l_avail_qty 
	END IF 

	LET modu_rec_orderdetl.sched_qty = modu_rec_orderdetl.order_qty 
	LET modu_rec_orderdetl.inv_qty = 0 
	LET modu_rec_orderdetl.back_qty = 0 
	LET modu_rec_orderdetl.picked_qty = 0 
	LET modu_rec_orderdetl.conf_qty = 0 
	LET modu_rec_orderdetl.serial_flag = l_rec_product.serial_flag 
	LET modu_rec_orderdetl.serial_qty = 0 
	LET modu_rec_orderdetl.desc_text = l_rec_product.desc_text 
	LET modu_rec_orderdetl.uom_code = l_rec_product.sell_uom_code 

	CASE (l_rec_customer.inv_level_ind) 
		WHEN "1" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price1_amt 
		WHEN "2" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price2_amt 
		WHEN "3" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price3_amt 
		WHEN "4" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price4_amt 
		WHEN "5" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price5_amt 
		WHEN "6" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price6_amt 
		WHEN "7" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price7_amt 
		WHEN "8" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price8_amt 
		WHEN "9" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.price9_amt 
		WHEN "C" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.wgted_cost_amt 
		WHEN "L" LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.list_amt 
		OTHERWISE 
			LET modu_rec_orderdetl.unit_price_amt = l_rec_prodstatus.list_amt 
	END CASE 

	LET modu_rec_orderdetl.ext_price_amt = modu_rec_orderdetl.unit_price_amt	* modu_rec_orderdetl.order_qty 
	SELECT sale_acct_code INTO modu_rec_orderdetl.acct_code FROM category 
	WHERE cat_code = l_rec_product.cat_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	LET modu_rec_orderdetl.disc_per = 0 
	LET modu_rec_orderdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * modu_rec_orderhead.conv_qty 
	LET modu_rec_orderdetl.ext_cost_amt = modu_rec_orderdetl.unit_cost_amt * modu_rec_orderdetl.order_qty 
	LET modu_rec_orderdetl.job_code = FALSE 
	LET modu_rec_orderdetl.cost_ind = "N" 
	LET modu_rec_orderdetl.level_ind = l_rec_customer.inv_level_ind 
	LET modu_rec_orderdetl.tax_code = modu_rec_orderhead.tax_code 
	LET modu_rec_orderdetl.offer_code = NULL 
	LET modu_rec_orderdetl.required_qty = 0 
	LET modu_rec_orderdetl.sold_qty = modu_rec_orderdetl.order_qty 
	LET modu_rec_orderdetl.bonus_qty = 0 
	LET modu_rec_orderdetl.ext_bonus_amt = 0 
	LET modu_rec_orderdetl.disc_amt = 0 
	LET modu_rec_orderdetl.ext_stats_amt = 0 
	LET modu_rec_orderdetl.comm_amt = NULL 
	LET modu_rec_orderdetl.prodgrp_code = l_rec_product.prodgrp_code 
	LET modu_rec_orderdetl.maingrp_code = l_rec_product.maingrp_code 
	LET modu_rec_orderdetl.autoinsert_flag = "N" 
	LET modu_rec_orderdetl.status_ind = "0" 
	LET modu_rec_orderdetl.disc_allow_flag = "N" 
	LET modu_rec_orderdetl.bonus_disc_amt = 0 
	LET modu_rec_orderdetl.trade_in_flag = "N" 
	LET modu_rec_orderdetl.pick_flag = "Y" 
	LET modu_rec_orderdetl.list_price_amt = l_rec_prodstatus.list_amt 

	CALL calc_line_tax(glob_rec_kandoouser.cmpy_code, modu_rec_orderhead.tax_code, 
	l_rec_prodstatus.sale_tax_code, 
	l_rec_prodstatus.sale_tax_amt, 
	modu_rec_orderdetl.sold_qty, 
	modu_rec_orderdetl.unit_cost_amt, 
	modu_rec_orderdetl.unit_price_amt) 
	RETURNING modu_rec_orderdetl.unit_tax_amt,	modu_rec_orderdetl.ext_tax_amt 
	
	LET modu_rec_orderdetl.line_tot_amt = modu_rec_orderdetl.ext_price_amt	+ modu_rec_orderdetl.ext_tax_amt 
	LET modu_rec_orderdetlog.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_orderdetlog.order_num = modu_rec_orderdetl.order_num 
	LET modu_rec_orderdetlog.part_code = modu_rec_orderdetl.part_code 
	LET modu_rec_orderdetlog.pre_qty = 0 
	LET modu_rec_orderdetlog.post_qty = modu_rec_orderdetl.order_qty 
	LET modu_rec_orderdetlog.pre_price_amt = 0 
	LET modu_rec_orderdetlog.post_price_amt = modu_rec_orderdetl.unit_price_amt 
	LET modu_rec_orderdetlog.pre_tax_amt = 0 
	LET modu_rec_orderdetlog.post_tax_amt = modu_rec_orderdetl.unit_tax_amt 
	LET modu_rec_orderdetlog.ammend_date = today 
	LET modu_rec_orderdetlog.ammend_time = time 
	LET modu_rec_orderdetlog.ammend_code = glob_rec_kandoouser.sign_on_code 
	LET modu_rec_orderdetlog.update_ind = "U" 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION create_orderdetl(l_rec_profit)   
###########################################################################


###########################################################################
# FUNCTION stock_status(p_part_code,p_ware_code)   
#
# 
###########################################################################
FUNCTION stock_status(p_part_code,p_ware_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE l_rec_prodstat RECORD 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		avail_qty LIKE prodstatus.onhand_qty 
	END RECORD 

	IF p_part_code IS NULL THEN 
		RETURN FALSE 
	END IF 
	SELECT onhand_qty,reserved_qty,back_qty,0 INTO l_rec_prodstat.* 
	FROM prodstatus 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		RETURN FALSE 
	END IF 
	LET l_rec_prodstat.avail_qty = l_rec_prodstat.onhand_qty	- l_rec_prodstat.reserved_qty	- l_rec_prodstat.back_qty 
	
	RETURN l_rec_prodstat.avail_qty 
END FUNCTION 
###########################################################################
# END FUNCTION stock_status(p_part_code,p_ware_code)   
###########################################################################


###########################################################################
# FUNCTION unload_orderdetlog()   
#
# 
###########################################################################
FUNCTION unload_orderdetlog() 
	DEFINE l_rec_profit RECORD 
		dept_code char(1), 
		cust_code char(3), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3) 
	END RECORD 
	DEFINE l_seq_num char(10) 
	DEFINE l_ret_code INTEGER
	DEFINE l_runner char(120) 
	DEFINE l_unload_file char(120) 
	DEFINE l_unload_file2 char(120) 
	DEFINE l_time char(8) 

	DELETE FROM t_profit 
	WHERE 1=1 
	
	INITIALIZE modu_rec_orderdetlog.* TO NULL 
	INITIALIZE modu_rec_orderdetl.* TO NULL 
	LET l_seq_num = glob_rec_loadparms.seq_num 
	DECLARE c_orderdetlog cursor FOR 
	SELECT * FROM orderdetlog 
	WHERE order_num in (select order_num FROM orderhead 
	WHERE ord_ind = "3" 
	AND ord_text = l_seq_num) 
	AND update_ind <> "C" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOREACH c_orderdetlog INTO modu_rec_orderdetlog.* 
		SELECT * INTO modu_rec_orderdetl.* FROM orderdetl 
		WHERE order_num = modu_rec_orderdetlog.order_num 
		AND line_num = modu_rec_orderdetlog.line_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_profit.dept_code = NULL 
		LET l_rec_profit.cust_code = modu_rec_orderdetl.cust_code 
		LET l_rec_profit.part_code = modu_rec_orderdetl.part_code 
		LET l_rec_profit.soh = NULL 
		LET l_rec_profit.suggested_stock = NULL 
		LET l_rec_profit.maxstk = NULL 
		LET l_rec_profit.previous_stock = modu_rec_orderdetlog.pre_qty 
		LET l_rec_profit.actual_stock = modu_rec_orderdetlog.post_qty 
		LET l_rec_profit.order_ref = NULL 
		LET l_rec_profit.sales1 = NULL 
		LET l_rec_profit.sales2 = NULL 
		LET l_rec_profit.sales3 = NULL 
		LET l_rec_profit.sales4 = NULL 
		LET l_rec_profit.ware_code = modu_rec_orderdetl.ware_code 

		INSERT INTO t_profit VALUES (l_rec_profit.*) 

	END FOREACH
	 
	LET l_time = time 
	LET l_time = l_time[1,2],l_time[4,5],l_time[7,8] 

	LET l_unload_file = glob_rec_loadparms.path_text clipped,	"/MXO", today USING "yyyymmdd", l_time clipped 
	LET l_unload_file2 = l_unload_file clipped, '.tp' 

	UNLOAD TO l_unload_file2 SELECT * FROM t_profit 


	#!!!! runner needs adopting/migrating !!!!	
	LET l_runner = " mv ", l_unload_file2 clipped," ", 
	l_unload_file clipped," 2>> ",trim(get_settings_logFile()) 
	CALL fgl_winmessage("runner needs adopting",l_runner,"info")
	RUN l_runner RETURNING l_ret_code 
	#!!!! runner needs adopting/migrating !!!!	

	UPDATE orderdetlog 
	SET update_ind = "C" 
	WHERE order_num in (select order_num FROM orderhead 
	WHERE ord_ind = "3" 
	AND ord_text = l_seq_num) 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END FUNCTION 
###########################################################################
# END FUNCTION unload_orderdetlog()   
###########################################################################


###########################################################################
# FUNCTION create_orderhead(l_cust_code) 
#
# 
###########################################################################
FUNCTION create_orderhead(l_cust_code) 
	DEFINE l_rec_profit RECORD 
		dept_code char(1), 
		cust_code char(3), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3) 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE i SMALLINT 
	DEFINE l_use_bill_addr SMALLINT 
	DEFINE l_mask_code LIKE customertype.acct_mask_code 

	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE l_rec_customership.* TO NULL 
	INITIALIZE l_mask_code TO NULL 
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = l_cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_orderhead.cust_code = l_cust_code 
	LET modu_rec_orderhead.last_inv_num = NULL 
	LET modu_rec_orderhead.ord_text = glob_rec_loadparms.seq_num 
	LET modu_rec_orderhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET modu_rec_orderhead.entry_date = today 
	LET modu_rec_orderhead.order_date = today 
	LET modu_rec_orderhead.sales_code = l_rec_customer.sale_code 
	LET modu_rec_orderhead.term_code = l_rec_customer.term_code 
	LET modu_rec_orderhead.tax_code = l_rec_customer.tax_code 
	LET modu_rec_orderhead.hand_amt = 0 
	LET modu_rec_orderhead.hand_tax_code = l_rec_customer.tax_code 
	LET modu_rec_orderhead.hand_tax_amt = 0 
	LET modu_rec_orderhead.freight_amt = 0 
	LET modu_rec_orderhead.freight_tax_code = l_rec_customer.tax_code 
	LET modu_rec_orderhead.freight_tax_amt = 0 
	LET modu_rec_orderhead.cost_amt = 0 
	LET modu_rec_orderhead.status_ind = "I" 
	LET modu_rec_orderhead.line_num = 0 
	LET modu_rec_orderhead.com1_text = "Created by ESL - Order import" 
	LET modu_rec_orderhead.com2_text = "(Profit) on the ",today 
	LET modu_rec_orderhead.rev_date = today 
	LET modu_rec_orderhead.rev_num = 1 
	SELECT count(*) INTO i FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_rec_orderhead.cust_code
	 
	CASE 
		WHEN i = 0 
			LET l_use_bill_addr = TRUE 
		WHEN i = 1 
			SELECT ship_code INTO modu_rec_orderhead.ship_code FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_rec_orderhead.cust_code 
		OTHERWISE 
			SELECT unique 1 FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_rec_orderhead.cust_code 
			AND ship_code = modu_rec_orderhead.cust_code 
			IF status = NOTFOUND THEN 
				DECLARE c_custship cursor FOR 
				SELECT ship_code FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = modu_rec_orderhead.cust_code 
				OPEN c_custship 
				FETCH c_custship INTO modu_rec_orderhead.ship_code 
			ELSE 
				LET modu_rec_orderhead.ship_code = modu_rec_orderhead.cust_code 
			END IF 
	END CASE 

	IF l_use_bill_addr THEN 
		LET modu_rec_orderhead.ship_code = NULL 
		LET modu_rec_orderhead.ship_name_text = l_rec_customer.name_text 
		LET modu_rec_orderhead.ship_addr1_text = l_rec_customer.addr1_text 
		LET modu_rec_orderhead.ship_addr2_text = l_rec_customer.addr2_text 
		LET modu_rec_orderhead.ship_city_text = l_rec_customer.city_text 
		LET modu_rec_orderhead.state_code = l_rec_customer.state_code 
		LET modu_rec_orderhead.post_code = l_rec_customer.post_code 
		LET modu_rec_orderhead.country_code = l_rec_customer.country_code --@db-patch_2020_10_04--
		LET modu_rec_orderhead.contact_text = NULL 
		LET modu_rec_orderhead.tele_text = NULL 
		LET modu_rec_orderhead.mobile_phone = NULL		
		LET modu_rec_orderhead.email = NULL		
		LET modu_rec_orderhead.carrier_code = NULL 
		LET modu_rec_orderhead.freight_ind = NULL 
		LET modu_rec_orderhead.ship1_text = NULL 
		LET modu_rec_orderhead.ship2_text = NULL 
	ELSE 
		SELECT * INTO l_rec_customership.* FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_orderhead.cust_code 
		AND ship_code = modu_rec_orderhead.ship_code 
		LET modu_rec_orderhead.ship_code = l_rec_customership.ship_code 
		LET modu_rec_orderhead.ship_name_text = l_rec_customership.name_text 
		LET modu_rec_orderhead.ship_addr1_text = l_rec_customership.addr_text 
		LET modu_rec_orderhead.ship_addr2_text = l_rec_customership.addr2_text 
		LET modu_rec_orderhead.ship_city_text = l_rec_customership.city_text 
		LET modu_rec_orderhead.state_code = l_rec_customership.state_code 
		LET modu_rec_orderhead.post_code = l_rec_customership.post_code 
		LET modu_rec_orderhead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
		LET modu_rec_orderhead.contact_text = l_rec_customership.contact_text 
		LET modu_rec_orderhead.tele_text = l_rec_customership.tele_text 
		LET modu_rec_orderhead.mobile_phone = l_rec_customership.mobile_phone
		LET modu_rec_orderhead.email = l_rec_customership.email				
		LET modu_rec_orderhead.carrier_code = l_rec_customership.carrier_code 
		LET modu_rec_orderhead.freight_ind = l_rec_customership.freight_ind 
		LET modu_rec_orderhead.ship1_text = l_rec_customership.ship1_text 
		LET modu_rec_orderhead.ship2_text = l_rec_customership.ship2_text 
	END IF 

	LET modu_rec_orderhead.ship_date = modu_rec_orderhead.order_date 
	LET modu_rec_orderhead.fob_text = NULL 
	LET modu_rec_orderhead.prepaid_flag = "N" 
	LET modu_rec_orderhead.cost_ind = NULL 
	LET modu_rec_orderhead.hold_code = NULL 
	LET modu_rec_orderhead.currency_code = l_rec_customer.currency_code 
	LET modu_rec_orderhead.conv_qty = get_conv_rate(
		glob_rec_kandoouser.cmpy_code, 
		modu_rec_orderhead.currency_code, 
		modu_rec_orderhead.order_date, 
		CASH_EXCHANGE_SELL) 

	SELECT acct_mask_code INTO l_mask_code FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_rec_customer.type_code 
	AND acct_mask_code IS NOT NULL 

	IF status = NOTFOUND THEN 
		LET modu_rec_orderhead.acct_override_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,modu_rec_orderhead.acct_override_code, 
		glob_rec_kandoouser.acct_mask_code) 
	ELSE 
		LET modu_rec_orderhead.acct_override_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,modu_rec_orderhead.acct_override_code,l_mask_code) 
	END IF 

	LET modu_rec_orderhead.price_tax_flag = NULL 
	LET modu_rec_orderhead.ord_ind = "3" 
	LET modu_rec_orderhead.first_inv_num = NULL 
	LET modu_rec_orderhead.last_inv_num = NULL 
	LET modu_rec_orderhead.invoice_to_ind = l_rec_customer.invoice_to_ind 
	LET modu_rec_orderhead.territory_code = l_rec_customer.territory_code 
	
	SELECT mgr_code INTO modu_rec_orderhead.mgr_code FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = l_rec_customer.sale_code 

	SELECT area_code INTO modu_rec_orderhead.area_code FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terr_code = modu_rec_orderhead.territory_code 

	LET modu_rec_orderhead.cond_code = l_rec_customer.cond_code 
	LET modu_rec_orderhead.scheme_amt = NULL 
	LET modu_rec_orderhead.delivery_ind = "1" 
	LET modu_rec_orderhead.freight_inv_amt = 0 
	LET modu_rec_orderhead.hand_inv_amt = 0 
	LET modu_rec_orderhead.tax_cert_text = NULL 
	LET modu_rec_orderhead.disc_amt = 0 
	LET modu_rec_orderhead.tax_amt = 0 
	LET modu_rec_orderhead.total_amt = 0 
	LET modu_rec_orderhead.goods_amt = 0 
END FUNCTION 
###########################################################################
# END FUNCTION create_orderhead(l_cust_code) 
###########################################################################


###########################################################################
# FUNCTION speeds_load() 
#
# 
###########################################################################
FUNCTION speeds_load() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_profit RECORD 
		dept_code char(1), 
		cust_code char(3), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3) 
	END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_dept_code char(1) 
	DEFINE l_cust_code char(3) 
	DEFINE l_err_cnt INTEGER
	DEFINE l_status INTEGER
	DEFINE l_line_inserted INTEGER
	DEFINE l_load_file2 char(200) 
	DEFINE l_runner char(150) 
	DEFINE l_report_header char(60)
	DEFINE l_output2 char(60)
	DEFINE l_prod_desc char(60) 

	DELETE FROM t_profit 
	WHERE 1=1 
	WHENEVER ERROR CONTINUE 
	LET l_load_file2 = glob_load_file clipped,".tmp" 
	LET l_runner = " mv -f ", glob_load_file clipped, " ", 
	l_load_file2 clipped, " 2>> ", trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_status 
	LOAD FROM l_load_file2 INSERT INTO t_profit 
	IF status != 0 THEN 
		RETURN status 
	END IF 
	
	WHENEVER ERROR stop
	 
	INITIALIZE l_dept_code TO NULL 
	INITIALIZE l_cust_code TO NULL 
	LET l_line_inserted = 0 
	IF glob_gv_background <> 'Y' THEN 
		MESSAGE kandoomsg2("U",1002,"")		#1002 Searching Database; Please Wait
		--      OPEN WINDOW w1 AT 13,23 with 1 rows, 30 columns  -- albo  KD-755
		--         ATTRIBUTE(border)
		DISPLAY "Creating Order: " at 1,2 

	END IF 

	DECLARE c_profit cursor with hold FOR 
	SELECT unique dept_code,cust_code FROM t_profit 
	ORDER BY dept_code,cust_code 

	FOREACH c_profit INTO l_dept_code,l_cust_code 
		GOTO bypass 
		LABEL recovery: 
		LET l_status = status 

		IF error_recover(glob_err_message,status) != "Y" THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			LET glob_err_message = "Exited load process due TO database ERROR ", 
			l_status USING "<<<<<<<<" 

			OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
			l_rec_profit.part_code, 
			l_rec_profit.order_ref, 
			glob_err_message) 

			EXIT FOREACH 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		
		BEGIN WORK 
			INITIALIZE modu_rec_orderhead.* TO NULL 
			SELECT * INTO l_rec_customer.* FROM customer 
			WHERE cust_code = l_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				SELECT count(*) INTO l_err_cnt FROM t_profit 
				WHERE dept_code = l_dept_code 
				AND cust_code = l_cust_code 
				LET glob_err_cnt = glob_err_cnt + l_err_cnt 
				LET glob_err_message = "Customer RECORD NOT found" 
				OUTPUT TO REPORT ESL_rpt_list_exception (l_cust_code, 
				"", 
				"", 
				glob_err_message) 
				ROLLBACK WORK 
				CONTINUE FOREACH 
			ELSE 
				IF l_rec_customer.delete_flag = "Y" 
				OR l_rec_customer.hold_code IS NOT NULL THEN 
					SELECT count(*) INTO l_err_cnt FROM t_profit 
					WHERE dept_code = l_dept_code 
					AND cust_code = l_cust_code 
					LET glob_err_cnt = glob_err_cnt + l_err_cnt 
					LET glob_err_message = "Customer has been deleted OR put on hold" 
					OUTPUT TO REPORT ESL_rpt_list_exception (l_cust_code, 
					"", 
					"", 
					glob_err_message) 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
			END IF 

			DECLARE c_opparms cursor FOR 
			SELECT next_ord_num FROM opparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = "1" 
			FOR UPDATE 
			OPEN c_opparms 
			FETCH c_opparms INTO modu_rec_orderhead.order_num 
			UPDATE opparms 

			SET next_ord_num = modu_rec_orderhead.order_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = "1" 
			CLOSE c_opparms 
			CALL create_orderhead(l_cust_code) 
			LET glob_err_message = "ESL_S - INSERT INTO orderhead" 

			INSERT INTO orderhead VALUES (modu_rec_orderhead.*) 
			LET glob_err_message = "ESL_S - INSERT orderlog entry" 
			CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,modu_rec_orderhead.order_num,10,"","") 
			DECLARE c2_profit cursor with hold FOR 
			SELECT * FROM t_profit 
			WHERE dept_code = l_dept_code 
			AND cust_code = l_cust_code 

			FOREACH c2_profit INTO l_rec_profit.* 
				IF l_rec_profit.ware_code IS NULL THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Null warehouse code entered" 
					OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
					l_rec_profit.part_code, 
					l_rec_profit.order_ref, 
					glob_err_message) 
					CONTINUE FOREACH 
				END IF 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_profit.ware_code 
				IF status = NOTFOUND THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Warehouse entered does NOT exist." 
					OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
					l_rec_profit.part_code, 
					l_rec_profit.order_ref, 
					glob_err_message) 
					CONTINUE FOREACH 
				END IF 
				IF l_rec_profit.dept_code IS NULL THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Null Department Code detected" 
					OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
					l_rec_profit.part_code, 
					l_rec_profit.order_ref, 
					glob_err_message) 
					CONTINUE FOREACH 
				END IF 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = l_rec_profit.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Product RECORD NOT found" 
					OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
					l_rec_profit.part_code, 
					l_rec_profit.order_ref, 
					glob_err_message) 
					CONTINUE FOREACH 

				ELSE 

					IF l_rec_product.status_ind = "2" 
					OR l_rec_product.status_ind = "3" THEN 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Product has been deleted OR put on hold" 
						OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
						l_rec_profit.part_code, 
						l_rec_profit.order_ref, 
						glob_err_message) 
						CONTINUE FOREACH 
					END IF 

					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE part_code = l_rec_profit.part_code 
					AND ware_code = l_rec_profit.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Product does NOT exist AT selected warehouse" 
						OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
						l_rec_profit.part_code, 
						l_rec_profit.order_ref, 
						glob_err_message) 
						CONTINUE FOREACH 
					END IF 
					IF l_rec_prodstatus.status_ind = "2" 
					OR l_rec_prodstatus.status_ind = "3" THEN 
						LET glob_err_cnt = glob_err_cnt + 1 
						LET glob_err_message = "Product STATUS has been deleted OR put on hold" 
						OUTPUT TO REPORT ESL_rpt_list_exception (l_rec_profit.cust_code, 
						l_rec_profit.part_code, 
						l_rec_profit.order_ref, 
						glob_err_message) 
						CONTINUE FOREACH 
					END IF 
				END IF 

				IF create_orderdetl(l_rec_profit.*) THEN 
					IF glob_gv_background <> 'Y' THEN 
						DISPLAY modu_rec_orderhead.order_num at 1,18 

					END IF 
					LET modu_rec_orderhead.status_ind = "U" 
					LET modu_rec_orderhead.line_num = modu_rec_orderhead.line_num + 1 
					LET modu_rec_orderdetl.line_num = modu_rec_orderhead.line_num 
					LET modu_rec_orderdetlog.line_num = modu_rec_orderhead.line_num 
					LET glob_err_message = "ESL_S - INSERT INTO orderdetl2" 

					INSERT INTO orderdetl VALUES (modu_rec_orderdetl.*) 
					LET glob_err_message = "ESL_S - INSERT INTO orderdetlog2" 

					INSERT INTO orderdetlog VALUES (modu_rec_orderdetlog.*) 
					LET glob_err_message = "ESL_S - UPDATE INTO orderhead" 

					UPDATE orderhead 
					SET tax_amt = tax_amt + modu_rec_orderdetl.ext_tax_amt, 
					total_amt = total_amt + modu_rec_orderdetl.line_tot_amt, 
					goods_amt = goods_amt + modu_rec_orderdetl.ext_price_amt, 
					line_num = modu_rec_orderhead.line_num, 
					status_ind = modu_rec_orderhead.status_ind, 
					ware_code = l_rec_profit.ware_code 
					#                  job_code = l_rec_profit.order_ref
					WHERE order_num = modu_rec_orderhead.order_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					DECLARE c_prodstatus cursor FOR 
					SELECT * FROM prodstatus 
					WHERE part_code = l_rec_profit.part_code 
					AND ware_code = l_rec_profit.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					FOR UPDATE 

					OPEN c_prodstatus 
					FETCH c_prodstatus INTO l_rec_prodstatus.* 
					UPDATE prodstatus 

					SET reserved_qty = reserved_qty + modu_rec_orderdetl.order_qty 
					WHERE part_code = l_rec_profit.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = l_rec_profit.ware_code 
					DECLARE c_customer cursor FOR 
					SELECT * INTO l_rec_customer.* FROM customer 
					WHERE cust_code = l_rec_profit.cust_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					FOR UPDATE 
					OPEN c_customer 
					FETCH c_customer INTO l_rec_customer.* 
					UPDATE customer 

					SET onorder_amt = onorder_amt	+ modu_rec_orderdetl.line_tot_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_cust_code 
					LET l_line_inserted = l_line_inserted + 1 

					LET l_prod_desc = l_rec_product.desc_text , ' ',			l_rec_product.desc2_text

					#---------------------------------------------------------
					OUTPUT TO REPORT ESL_rpt_list_detailed(l_rpt_idx,
					modu_rec_orderdetl.*, l_prod_desc) 
					#---------------------------------------------------------

				END IF 
			END FOREACH 

			IF modu_rec_orderhead.line_num = 0 THEN 
				ROLLBACK WORK 
			ELSE 
			COMMIT WORK 
		END IF 
	END FOREACH 
	
	CALL unload_orderdetlog() 
	LET glob_rec_rpt_selector.ref1_text = "Profit Import Orders Summary (Load No: ", glob_rec_loadparms.seq_num USING "<<<<<",")" 
 
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"ESL_rpt_list_inserted","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ESL_rpt_list_inserted TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------	
	
	#---------------------------------------------------------
	OUTPUT TO REPORT ESL_rpt_list_inserted(l_rpt_idx,
	l_line_inserted) 
	#---------------------------------------------------------	

	#------------------------------------------------------------
	FINISH REPORT ESL_rpt_list_inserted
	CALL rpt_finish("ESL_rpt_list_inserted")
	#------------------------------------------------------------

	RETURN l_line_inserted 
END FUNCTION
###########################################################################
# END FUNCTION speeds_load() 
###########################################################################