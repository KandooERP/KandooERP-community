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

#  Requisition Generator
#
#  NOTE:   This module requires a temporary table TO have been created by
#  the calling routine. The table IS called t_reqdetl AND should be
#  created using tablefunc.4gl. (See IB5 FOR an example CALL TO this
#  routine).
#          This module ONLY creates type '0' requisitions AND any
#  exceptions reported should be added via requisition edit.
#
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
############################################################
# FUNCTION create_req(p_cmpy,p_kandoouser_sign_on_code)
#
# Purpose - Automatic creation of Requisitions.
############################################################
FUNCTION create_req(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_reqparms RECORD LIKE reqparms.* 
	DEFINE l_rec_reqperson RECORD LIKE reqperson.* 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_rec_pr_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_ps_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_puparms RECORD LIKE puparms.* 
	DEFINE l_rec_prodquote RECORD LIKE prodquote.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ware_code LIKE reqhead.ware_code 
	DEFINE l_total_sales_amt LIKE reqhead.total_sales_amt 
	DEFINE l_first_num LIKE reqhead.req_num 
	DEFINE l_last_num LIKE reqhead.req_num 
	DEFINE l_err_message STRING 
	DEFINE l_conv_rate FLOAT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_cnt_row SMALLINT
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	MESSAGE kandoomsg2("N",1012,"")	#U1005 Generating Requisitions

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(trim(getmoduleid())||".","reqbox_rpt_list_exception","N/A",RPT_HIDE_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT reqbox_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	BEGIN WORK 
		SELECT * INTO l_rec_reqparms.* FROM reqparms 
		WHERE cmpy_code = p_cmpy AND key_code = "1" 
		LET l_first_num = l_rec_reqparms.next_req_num 
		LET l_last_num = 0 
		DECLARE c_t_reqdetl CURSOR FOR 
		SELECT UNIQUE vend_code FROM t_reqdetl 
		LET l_cnt_row = 0
		
		FOREACH c_t_reqdetl INTO l_ware_code 
			LET l_cnt = 1 
			LET l_total_sales_amt = 0 
			DECLARE c1_t_reqdetl CURSOR FOR 
			SELECT * FROM t_reqdetl 
			WHERE vend_code = l_ware_code 
			ORDER BY part_code 

			FOREACH c1_t_reqdetl INTO l_rec_ps_reqdetl.* 
				INITIALIZE l_rec_pr_reqdetl.* TO NULL 
				LET l_rec_pr_reqdetl.cmpy_code = p_cmpy 
				LET l_rec_pr_reqdetl.req_num = l_rec_reqparms.next_req_num 
				LET l_rec_pr_reqdetl.line_num = l_cnt 
				LET l_rec_pr_reqdetl.seq_num = 1 
				LET l_rec_pr_reqdetl.part_code = l_rec_ps_reqdetl.part_code 
				LET l_rec_pr_reqdetl.reserved_qty = 0 
				LET l_rec_pr_reqdetl.back_qty = 0 
				LET l_rec_pr_reqdetl.picked_qty = 0 
				LET l_rec_pr_reqdetl.confirmed_qty = 0 
				LET l_rec_pr_reqdetl.po_qty = 0 
				LET l_rec_pr_reqdetl.po_rec_qty = 0 
				LET l_rec_pr_reqdetl.unit_tax_amt = 0 
				LET l_rec_pr_reqdetl.level_ind = "C" 

				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = p_cmpy AND 
						part_code = l_rec_ps_reqdetl.part_code 
				IF STATUS = NOTFOUND THEN 
					LET l_err_message = "Product NOT found ",l_rec_ps_reqdetl.part_code 
					OUTPUT TO REPORT reqbox_rpt_list_exception(l_rpt_idx,p_cmpy,l_err_message) 
					LET l_cnt_row = l_cnt_row + 1
					CONTINUE FOREACH 
				END IF 

				SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = p_cmpy AND 
						part_code = l_rec_ps_reqdetl.part_code	AND 
						ware_code = l_ware_code 
				IF STATUS = NOTFOUND THEN 
					LET l_err_message = "Product ",l_rec_ps_reqdetl.part_code CLIPPED," NOT found AT Warehouse ",l_ware_code 
					OUTPUT TO REPORT reqbox_rpt_list_exception(l_rpt_idx,p_cmpy,l_err_message) 
					LET l_cnt_row = l_cnt_row + 1
					CONTINUE FOREACH 
				END IF 

				SELECT * INTO l_rec_category.* FROM category 
				WHERE cmpy_code = p_cmpy AND 
						cat_code = l_rec_product.cat_code 
				IF STATUS = NOTFOUND THEN 
					LET l_err_message = "Product Category NOT found ",l_rec_product.cat_code CLIPPED," FOR Product ",l_rec_product.part_code 
					OUTPUT TO REPORT reqbox_rpt_list_exception(l_rpt_idx,p_cmpy,l_err_message) 
					LET l_cnt_row = l_cnt_row + 1
					CONTINUE FOREACH 
				END IF 

				LET l_rec_pr_reqdetl.acct_code = l_rec_category.sale_acct_code 
				LET l_rec_pr_reqdetl.vend_code = l_rec_product.vend_code 
				LET l_rec_pr_reqdetl.uom_code = l_rec_product.sell_uom_code 
				LET l_rec_pr_reqdetl.desc_text = l_rec_product.desc_text 
				LET l_rec_pr_reqdetl.required_date = TODAY + l_rec_product.days_lead_num 
				LET l_rec_pr_reqdetl.replenish_ind = l_rec_prodstatus.replenish_ind 
				IF l_rec_prodstatus.replenish_ind IS NULL THEN 
					LET l_rec_pr_reqdetl.replenish_ind = "P" 
				END IF 

				IF l_rec_pr_reqdetl.replenish_ind != "S" THEN 
					DECLARE c_prodquote CURSOR FOR 
					SELECT * FROM prodquote 
					WHERE cmpy_code = p_cmpy 
					AND part_code = l_rec_pr_reqdetl.part_code 
					AND status_ind = "1" 
					AND expiry_date >= TODAY 
					ORDER BY cost_amt 
					OPEN c_prodquote 
					FETCH c_prodquote INTO l_rec_prodquote.* 
					IF STATUS = NOTFOUND THEN 
						LET l_rec_pr_reqdetl.unit_sales_amt = l_rec_prodstatus.for_cost_amt 
					ELSE 
						LET l_conv_rate = get_conv_rate(
							p_cmpy,
							l_rec_prodquote.curr_code,
							TODAY,
							CASH_EXCHANGE_SELL) 
						
						LET l_rec_pr_reqdetl.unit_sales_amt = l_rec_prodquote.cost_amt / l_conv_rate 
						LET l_rec_pr_reqdetl.vend_code = l_rec_prodquote.vend_code 
						LET l_rec_pr_reqdetl.required_date = TODAY + l_rec_prodquote.lead_time_qty 
					END IF 
					
					CLOSE c_prodquote 

				ELSE 

					SELECT * INTO l_rec_puparms.* FROM puparms 
					WHERE cmpy_code = p_cmpy 
					
					LET l_rec_pr_reqdetl.unit_sales_amt = l_rec_prodstatus.wgted_cost_amt 
					LET l_rec_pr_reqdetl.vend_code = l_rec_puparms.usual_ware_code 
					
					IF l_ware_code = l_rec_puparms.usual_ware_code THEN 
						LET l_err_message = "Stock Transfer attempted FROM ", 
						l_ware_code CLIPPED, " TO ", l_ware_code CLIPPED," FOR Product ",l_rec_product.part_code 
						OUTPUT TO REPORT reqbox_rpt_list_exception(l_rpt_idx,p_cmpy,l_err_message) 
						LET l_cnt_row = l_cnt_row + 1
						CONTINUE FOREACH 
					END IF 
				END IF 

				IF l_rec_pr_reqdetl.unit_sales_amt IS NULL THEN 
					LET l_rec_pr_reqdetl.unit_sales_amt = 0 
				END IF 
				LET l_rec_pr_reqdetl.unit_cost_amt = l_rec_pr_reqdetl.unit_sales_amt 

				IF l_rec_ps_reqdetl.req_qty IS NOT NULL THEN 
					#use the one passed FROM the calling program
					LET l_rec_pr_reqdetl.req_qty = l_rec_ps_reqdetl.req_qty 
				ELSE 
					LET l_rec_pr_reqdetl.req_qty = l_rec_prodstatus.reorder_qty 
				END IF 

				LET l_cnt = l_cnt + 1 
				LET l_err_message = "Requisition Detail Insert - reqbox" 
				# Deleting records with the same primary key.
            DELETE FROM reqdetl WHERE  cmpy_code = l_rec_pr_reqdetl.cmpy_code AND
													req_num = l_rec_pr_reqdetl.req_num AND
													line_num = l_rec_pr_reqdetl.line_num
				INSERT INTO reqdetl VALUES (l_rec_pr_reqdetl.*) 
				LET l_total_sales_amt = l_total_sales_amt + (l_rec_pr_reqdetl.unit_sales_amt * l_rec_pr_reqdetl.req_qty) 
			END FOREACH 

			IF l_cnt = 1 THEN 
				# No requisition lines were added therefore skip the header AND
				# re-use the requisition number again
				CONTINUE FOREACH 
			END IF 

			INITIALIZE l_rec_reqhead.* TO NULL 
			LET l_rec_reqhead.cmpy_code = p_cmpy 
			LET l_rec_reqhead.req_num = l_rec_pr_reqdetl.req_num 
			LET l_rec_reqhead.person_code = p_kandoouser_sign_on_code 
			SELECT * INTO l_rec_reqperson.* FROM reqperson 
			WHERE cmpy_code = p_cmpy AND 
					person_code = p_kandoouser_sign_on_code 
			IF STATUS = NOTFOUND THEN 
				######  SOMETHING MAJOR WENT WRONG  ############
				LET l_err_message = "User """,p_kandoouser_sign_on_code CLIPPED,""" does not have access to Internal Requisitions.\nPress OK to exit." 
				CALL msgerror("",l_err_message)
				#ERROR kandoomsg2("U",1531,p_kandoouser_sign_on_code)
				#1531 User does NOT have access TO Internal Requisitions
				EXIT PROGRAM 
			END IF 

			LET l_rec_reqhead.del_dept_text = l_rec_reqperson.dept_text 
			LET l_rec_reqhead.del_name_text = l_rec_reqperson.name_text 
			LET l_rec_reqhead.del_addr1_text = l_rec_reqperson.addr1_text 
			LET l_rec_reqhead.del_addr2_text = l_rec_reqperson.addr2_text 
			LET l_rec_reqhead.del_addr3_text = l_rec_reqperson.addr3_text 
			LET l_rec_reqhead.del_city_text = l_rec_reqperson.city_text 
			LET l_rec_reqhead.del_state_code = l_rec_reqperson.state_code 
			LET l_rec_reqhead.del_country_code = l_rec_reqperson.country_code 
			LET l_rec_reqhead.del_post_code = l_rec_reqperson.post_code 
			LET l_rec_reqhead.stock_ind = "0" 
			LET l_rec_reqhead.ware_code = l_ware_code 
			LET l_rec_reqhead.req_date = TODAY 
			LET l_rec_reqhead.entry_date = TODAY 
			LET l_rec_reqhead.last_mod_date = TODAY 
			LET l_rec_reqhead.last_mod_code = p_kandoouser_sign_on_code 
			LET l_rec_reqhead.rev_num = 1 
			LET l_rec_reqhead.entry_code = p_kandoouser_sign_on_code 
			LET l_rec_reqhead.com1_text = "Automatically Generated" 
			CALL db_period_what_period(p_cmpy,TODAY)RETURNING l_rec_reqhead.year_num,l_rec_reqhead.period_num 
			LET l_rec_reqhead.part_flag = "Y" 
			LET l_rec_reqhead.line_num = l_cnt - 1 
			LET l_rec_reqhead.total_sales_amt = l_total_sales_amt 
			IF l_rec_reqhead.total_sales_amt IS NULL THEN 
				LET l_rec_reqhead.total_sales_amt = 0 
			END IF 
			LET l_rec_reqhead.total_cost_amt = l_rec_reqhead.total_sales_amt 
			LET l_rec_reqhead.total_tax_amt = 0 
			LET l_rec_reqhead.type_ind = 1 
			IF l_rec_reqperson.dr_limit_amt > 0 
			AND l_rec_reqhead.total_sales_amt > l_rec_reqperson.dr_limit_amt THEN 
				LET l_rec_reqhead.status_ind = 0 
			ELSE 
				LET l_rec_reqhead.status_ind = 1 
			END IF 
			LET l_err_message = "Requisition Header Insert - reqbox" 

			# Deleting records with the same primary key.
			DELETE FROM reqhead WHERE  cmpy_code = l_rec_reqhead.cmpy_code AND
												req_num = l_rec_reqhead.req_num
			INSERT INTO reqhead VALUES (l_rec_reqhead.*) 
			LET l_last_num = l_rec_reqparms.next_req_num 
			LET l_rec_reqparms.next_req_num = l_rec_reqparms.next_req_num + 1 
		END FOREACH 

		LET l_err_message = "Parameter Update - reqbox" 
		UPDATE reqparms SET next_req_num = l_rec_reqparms.next_req_num 
		WHERE cmpy_code = p_cmpy AND key_code = "1" 
	COMMIT WORK 

	IF l_last_num != 0 THEN 
		LET l_err_message = " Requisition ",l_first_num USING "<<<<<<<&"," TO ",l_last_num USING "<<<<<<<&"," added successfully.\nPress OK to continue." 
		CALL msgcontinue("",l_err_message)
		#LET l_err_message = kandoomsg("N",7023,l_err_message)
		#7023 " added successfully"
	END IF 

	IF l_cnt_row > 0 THEN
		#------------------------------------------------------------
		FINISH REPORT reqbox_rpt_list_exception
		RETURN rpt_finish("reqbox_rpt_list_exception")
		#------------------------------------------------------------
	END IF

END FUNCTION 
############################################################
# END FUNCTION create_req()
############################################################

#####################################################################
# REPORT reqbox_rpt_list_exception(p_rpt_idx,p_cmpy,p_comments)
#
# Report Definition/Layout
#####################################################################
REPORT reqbox_rpt_list_exception(p_rpt_idx,p_cmpy,p_comments) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_comments CHAR(120)
	DEFINE l_date_time DATETIME YEAR TO SECOND 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	ON EVERY ROW 
		LET l_date_time = CURRENT 
		PRINT COLUMN 01,l_date_time,COLUMN 26,p_comments CLIPPED 

	ON LAST ROW 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report CLIPPED			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
#####################################################################
# END REPORT reqbox_rpt_list_exception(p_rpt_idx,p_cmpy,p_comments)
#####################################################################