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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES5_GLOBALS.4gl" 
###########################################################################
# Order Confirmation Summary
###########################################################################
###########################################################################
# FUNCTION ES5_rpt_process(p_cmpy_code) 
#
# 
###########################################################################
FUNCTION ES5_rpt_process(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_query_text STRING 
	DEFINE l_rec_invhead RECORD	
		po_num char(15), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		ship_qty LIKE invoicedetl.ship_qty 
	END RECORD
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_ret_code INTEGER 
	DEFINE l_runner STRING
	DEFINE l_file_name STRING
	DEFINE l_file_name2 STRING 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"ES5_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ES5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

#	LET l_rec_select.path_name = glob_rec_rpt_selector.ref1_text 
#	LET l_rec_select.file_name = glob_rec_rpt_selector.ref2_text 
#	LET l_inv_text = p_invtext

	LET l_query_text ="SELECT * FROM invoicehead ", 
	" WHERE invoicehead.cmpy_code= '",p_cmpy_code,"' ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ES5_rpt_list")].sel_text clipped," " #, 
	#   LET l_query_text ="SELECT * FROM invoicehead,invoicedetl ",
	#                    "WHERE invoicehead.cmpy_code= '",p_cmpy_code,"' ",
	#                      "AND invoicedetl.cmpy_code= '",p_cmpy_code,"' ",
	#                      "AND invoicehead.inv_num = invoicedetl.inv_num ",
	#                      "AND ",glob_rec_rmsreps.sel_text clipped," "
	DELETE FROM t_invoicedetl 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice cursor FOR s_invoice 

	FOREACH c_invoice INTO l_rec_invoicehead.* 
		DECLARE c2_inv_detl cursor FOR 
		SELECT * FROM invoicedetl 
		WHERE cmpy_code = p_cmpy_code 
		AND inv_num = l_rec_invoicehead.inv_num 

		FOREACH c2_inv_detl INTO l_rec_invoicedetl.* 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE cmpy_code = p_cmpy_code 
			AND part_code = l_rec_invoicedetl.part_code 
			LET l_rec_invhead.po_num = l_rec_invoicedetl.part_code[10,15] 
			LET l_rec_invhead.part_code = l_rec_invoicedetl.part_code[1,8] 
			LET l_rec_invhead.desc_text = l_rec_product.desc_text 
			LET l_rec_invhead.ship_qty = l_rec_invoicedetl.ship_qty 

			#---------------------------------------------------------
			OUTPUT TO REPORT ES5_rpt_list(l_rpt_idx,
			l_rec_invhead.*) 
			IF NOT rpt_int_flag_handler2("Invoice:",l_rec_invoicehead.inv_num, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 			
			#---------------------------------------------------------				
			 
			INSERT INTO t_invoicedetl VALUES (l_rec_invoicedetl.cust_code, 
			l_rec_invoicedetl.part_code, 
			l_rec_invoicehead.ship_date, 
			l_rec_invoicedetl.ship_qty) 

		END FOREACH 

		UPDATE invoicehead 
		SET printed_num = printed_num + 1 
		WHERE cmpy_code = p_cmpy_code 
		AND inv_num = l_rec_invoicehead.inv_num 

	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ES5_rpt_list
	CALL rpt_finish("ES5_rpt_list")
	#MESSAGE "Completed Report: ", trim(glob_rec_rmsreps.file_text)
	#------------------------------------------------------------
	 
	LET l_file_name = 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ES5_rpt_list")].ref3_code clipped, 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ES5_rpt_list")].ref4_code clipped,"/", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ES5_rpt_list")].ref1_code clipped, 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ES5_rpt_list")].ref2_code clipped 
	
	LET l_file_name2 = l_file_name clipped, '.tp' 
	UNLOAD TO l_file_name2 delimiter "|" 
	SELECT * FROM t_invoicedetl 

	#!!!! l_runner stuff needs adopting/migrating !!!!
	LET l_runner = " mv ", l_file_name2 clipped," ", 
	l_file_name clipped," 2>> ",trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_ret_code 
	CALL fgl_winmessage("l_runner stuff needs adopting/migrating",l_runner,"info")
	#!!!! l_runner stuff needs adopting/migrating !!!!

END FUNCTION 
############################################################
# END FUNCTION ES5_rpt_process(p_cmpy_code)  
############################################################