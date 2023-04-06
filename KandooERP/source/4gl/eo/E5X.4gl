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
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E5X_GLOBALS.4gl" 
###########################################################################
# \brief module E5X - Performs the automatical delivery cycle.
#                This cycle consiste of five steps:
#                Step 1: Generating of picking lists
#                Step 2: Confirming orders/generating invoices/credit notes
#                Step 3: Printing invoices
#                Step 4: Generating/printing consignment notes
#                Step 5: Printing shipping labels
###########################################################################
# FUNCTION E5X_main()
#
# Scheduler TO control the proceeding of the automated delivery cycle
###########################################################################
FUNCTION E5X_main()
	DEFINE l_rpt_pageno LIKE rmsreps.page_num #do not remove this.. needs investigating
	DEFINE l_rec_carrier RECORD LIKE carrier.*
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_ware_code LIKE warehouse.ware_code
--	DEFINE l_output char(50)
	DEFINE l_err_message char(60)
	DEFINE l_event_text char(60)
	DEFINE l_where_text char(200)
	DEFINE l_str char(200)
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_spaces char(100)
	DEFINE l_pick_date LIKE pickhead.pick_date
	DEFINE l_rowid INTEGER
	DEFINE l_count INTEGER
	DEFINE l_inv_ind LIKE invoicehead.inv_ind
	DEFINE l_trans_num LIKE invoicehead.inv_num
	DEFINE l_carrier_code LIKE carrier.carrier_code
	DEFINE l_manifest_num LIKE invoicehead.manifest_num
	DEFINE l_order_num LIKE invoicehead.ord_num
	DEFINE x LIKE warehouse.next_pick_num
	DEFINE y LIKE warehouse.next_pick_num
	DEFINE l_skip_flag char(1)
	DEFINE l_cnt INTEGER
	DEFINE l_part_code LIKE orderdetl.part_code
	DEFINE l_picked_qty LIKE pickdetl.part_code
	DEFINE l_credn_cnt SMALLINT 
	DEFINE l_prein_cnt SMALLINT 
	DEFINE l_trans_cnt SMALLINT 
	DEFINE l_header_appendix STRING
	DEFINE l_msg STRING
	DEFINE l_arg_ware_code STRING #argument URL for warehouse ware_code
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E5X") 
	
	LET l_arg_ware_code = get_url_warehouse_code()
	IF l_arg_ware_code IS NOT NULL THEN 
		LET l_ware_code = l_arg_ware_code 
	ELSE
		CALL fgl_winmessage ("E5X is a child application","E5X is a child application which requires a valid warehouse code!\nExit Application","error")
	END IF 
	
	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = l_ware_code 
	IF status = NOTFOUND THEN 
		LET l_spaces = "Warehouse ",l_ware_code," NOT found ", "Calling Program = ",get_baseProgName()," " 
		CALL errorlog(l_spaces)
		LET l_msg = "Warehouse configuration with the code ", trim(l_ware_code), " does not exist.\nExit Program"
		CALL fgl_winmessage("ERROR - Invalid warehouse URL argument", l_msg, "ERROR")
		EXIT PROGRAM 
	END IF 

	IF NOT warehouse_free(l_ware_code) THEN
		CALL fgl_winmessage("ERROR - Warehouse not found", "Warehouse is not free\nExit Program", "ERROR") 
		EXIT PROGRAM 
	END IF 
	
	WHENEVER ERROR GOTO recovery 
	ERROR kandoomsg2("E",1052,l_rec_warehouse.desc_text) #1052 Currently processing warehouse ...
	LET l_err_message = "Error E5A MESSAGE 014 - Refer to ", trim(get_settings_logFile()) 

	CREATE temp TABLE t_document (
		trans_num INTEGER, 
		carrier_code char(3), 
		manifest_num integer) 

	#--------------------------------------------------------
	# Create the temporary tables FOR the connote processing
	#
	CREATE temp TABLE tmp_danger (dg_code char(8), 
	nett_wgt_qty FLOAT, 
	nett_cubic_qty FLOAT, 
	despatch_qty float) 
	CREATE temp TABLE tmp_carry (main_dg_code char(8),	carry_dg_code char(8)) 

	#--------------------------------------------------------
	# Generating/Printing Picking Lists ###
	IF l_rec_warehouse.pick_flag = "Y" THEN 
		ERROR kandoomsg2("E",1052,l_rec_warehouse.desc_text) 	#1052 Currently processing warehouse ...
		IF l_rec_warehouse.pick_print_code IS NULL THEN			
			# check on picking slip printer
			SELECT order_print_text INTO l_rec_warehouse.pick_print_code 
			FROM rmsparm 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
		LET l_where_text = "ware_code = '",l_ware_code,"' " 
		LET l_err_message = "Error E5A MESSAGE 002 - Refer to ", trim(get_settings_logFile())

		IF generate_pick(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_where_text) THEN 
			DECLARE c_picklist cursor with hold FOR 
			SELECT ware_code,	delivery_ind 
			FROM t_picklist 
			GROUP BY ware_code,	delivery_ind 
			ORDER BY delivery_ind desc,	ware_code 
			
			FOREACH c_picklist INTO l_rec_orderhead.ware_code,l_rec_orderhead.delivery_ind 
				SELECT next_pick_num INTO x 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_ware_code 
---------------------------------------------------

				--LET l_output = 
				CALL create_picklist(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_kandoouser.sign_on_code,
					l_rec_orderhead.ware_code, 
					l_rec_orderhead.delivery_ind, 
					FALSE,
					FALSE) 
--------------------------------------
				SELECT next_pick_num INTO y 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_ware_code 
				LET l_trans_cnt = y - x 
{
				IF l_trans_cnt > 0 THEN 
				
					IF rms_print(glob_rec_kandoouser.cmpy_code,l_output,l_rec_warehouse.pick_print_code) THEN 
						LET l_event_text = "Printed ",l_trans_cnt USING "<<<", " picking lists" 
						CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
					ELSE 
						LET l_event_text = "Picking list PRINT failed " 
						CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,7089, 
						l_rec_warehouse.pick_print_code) 
					END IF 
				END IF 
}
			END FOREACH 
		END IF 
	END IF 
	
	### Confirming Orders/Generating Invoices/Credit Notes ###
	IF l_rec_warehouse.confirm_flag = "Y" THEN 
		LET l_err_message = "Error E5A MESSAGE 003 - Refer to ", trim(get_settings_logFile())
		MESSAGE kandoomsg2("E",1052,l_rec_warehouse.desc_text) 	#1052 Currently processing warehouse ...
		LET l_trans_cnt = 0 
		LET l_prein_cnt = 0 
		LET l_credn_cnt = 0
		 
		CALL cr_inv_tables() 

		LET l_where_text = "ware_code = '",l_ware_code,"' " 

		CALL load_tables(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_kandoouser.sign_on_code,
			FALSE,
			l_where_text,
			l_where_text) 

		DECLARE c_inv_head cursor with hold FOR 
		SELECT rowid, invoice_ind, pick_date FROM t_inv_head 
		WHERE hold_code IS NULL 
		ORDER BY pick_date 

		FOREACH c_inv_head INTO l_rowid, l_inv_ind, l_pick_date 
			DECLARE c_serial_check cursor FOR 
			SELECT t.order_num, t.part_code, t.picked_qty 
			FROM t_inv_detl t, product p 
			WHERE t.part_code = p.part_code 
			AND t.inv_rowid = l_rowid 
			AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND p.serial_flag = 'Y' 
			LET l_skip_flag = 'N' 

			FOREACH c_serial_check INTO l_order_num, l_part_code,	l_picked_qty 
				SELECT count(*) INTO l_cnt FROM serialinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_part_code 
				AND ware_code = l_ware_code 
				AND trantype_ind = '1' 
				AND trans_num = l_order_num 
				IF l_cnt <> l_picked_qty THEN 
					LET l_skip_flag = 'Y' 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			
			IF l_skip_flag = 'Y' THEN 
				CONTINUE FOREACH 
			END IF 

			IF l_inv_ind = 4 THEN 
				LET l_trans_num = generate_cred(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rowid,FALSE) 
			ELSE 
				LET l_trans_num = generate_inv(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rowid,FALSE) 
			END IF 

			IF l_trans_num > 0 THEN 
				CASE l_inv_ind 
					WHEN 1 
						LET l_event_text = "70" #automatic invoice 
						LET l_trans_cnt = l_trans_cnt + 1 
					WHEN 2 
						LET l_event_text = "70" #automatic invoice 
						LET l_trans_cnt = l_trans_cnt + 1 
					WHEN 3 
						LET l_event_text = "80" #automatic pre-delivered invoice 
						LET l_prein_cnt = l_prein_cnt + 1 
					WHEN 4 
						LET l_event_text = "60" #automatic credit note trade in 
						LET l_credn_cnt = l_credn_cnt + 1 
				END CASE 

				DECLARE c_inv_detl cursor FOR 
				SELECT order_num FROM t_inv_detl 
				WHERE inv_rowid = l_rowid 
				GROUP BY order_num 

				FOREACH c_inv_detl INTO l_order_num 
					CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_order_num, 
					l_event_text,l_trans_num,"") 
				END FOREACH 

			END IF 
		END FOREACH 

		IF l_trans_cnt > 0 THEN 
			LET l_event_text = 
			"Generated ",l_trans_cnt USING "<<<"," Invoices" 
			CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
		END IF 

		IF l_prein_cnt > 0 THEN 
			LET l_event_text = 
			"Generated ",l_prein_cnt USING "<<<"," predelivered Invoices" 
			CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
		END IF 

		IF l_credn_cnt > 0 THEN 
			LET l_event_text = 
			"Generated ",l_credn_cnt USING "<<<"," credit Notes" 
			CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
		END IF 
	END IF 

	#--------------------------------------------------------
	# Printing Invoices/Credit Notes ###
	IF l_rec_warehouse.inv_flag = "Y" THEN 
		MESSAGE kandoomsg2("E",1052,l_rec_warehouse.desc_text)		#1052 Currently processing warehouse ...
		IF l_rec_warehouse.inv_print_code IS NULL THEN 
			## check on invoice/credit note printer
			SELECT inv_print_text INTO l_rec_warehouse.inv_print_code 
			FROM rmsparm 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
		LET l_err_message = "Error E5A MESSAGE 005 - Refer to ", trim(get_settings_logFile())
		DELETE FROM t_document 
		LET l_err_message = "Error E5A MESSAGE 006 - Refer to ", trim(get_settings_logFile())

		## New INSERT clause
		INSERT INTO t_document(trans_num,carrier_code) 
		SELECT invoicehead.inv_num,	invoicehead.carrier_code 
		FROM invoicehead, invoicedetl 
		WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND invoicehead.inv_num = invoicedetl.inv_num 
		AND invoicehead.printed_num = 0 
		AND invoicehead.inv_ind in ("5","6") 
		AND invoicedetl.ware_code = l_ware_code 
		GROUP BY 1,2 
		
		SELECT count(*) INTO l_trans_cnt 
		FROM t_document 
		IF l_trans_cnt IS NULL THEN 
			LET l_trans_cnt = 0 
		END IF 

		IF l_trans_cnt > 0 THEN 
			LET l_where_text =	"invoicehead.inv_num in (SELECT trans_num FROM t_document)"

			#The global selector properties for report engine / will be stored in arr_rec_rmsreps
			LET glob_rec_rpt_selector.sel_text = l_where_text
			LET glob_rec_rpt_selector.ref1_text = l_where_text
			LET glob_rec_rpt_selector.ref2_text = NULL #"1!=1"
			 
			--LET l_output = 
			#CALL --AS1_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_where_text,"1!=1",	FALSE,l_rec_warehouse.inv_print_code) --print invoice 
			IF AS1_rpt_process_invoice_credit(l_where_text) THEN --print invoice
--			IF rms_print(glob_rec_kandoouser.cmpy_code,l_output,l_rec_warehouse.inv_print_code) THEN 
				LET l_event_text="Printed ",l_trans_cnt USING "<<<<"," Invoices" 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
			ELSE 
				LET l_event_text = "Invoice PRINT failed " 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,7089,l_rec_warehouse.inv_print_code) 
			END IF 
		END IF 

		LET l_err_message = "Error E5A MESSAGE 007 - Refer to ", trim(get_settings_logFile())
		DELETE FROM t_document 
		LET l_err_message = "Error E5A MESSAGE 008 - Refer to ", trim(get_settings_logFile())

		#  INSERT INTO t_document
		#  SELECT cred_num,"","" FROM credithead
		#   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#     AND printed_num = 0
		#     AND cred_num in(SELECT cred_num FROM creditdetl
		#                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                        AND cred_num = credithead.cred_num
		#                        AND ware_code = l_ware_code)
		
		#--------------------------------------------------------
		# New restructured SELECT
		INSERT INTO t_document(trans_num) 
		SELECT credithead.cred_num 
		FROM credithead,creditdetl 
		WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND credithead.cred_num = creditdetl.cred_num 
		AND credithead.printed_num = 0 
		AND credithead.cred_ind in ("5","1") 
		AND creditdetl.ware_code = l_ware_code 
		GROUP BY 1 
		
		SELECT count(*) INTO l_trans_cnt 
		FROM t_document 
		IF l_trans_cnt IS NULL THEN 
			LET l_trans_cnt = 0 
		END IF 

		IF l_trans_cnt > 0 THEN 
			LET l_where_text =	"credithead.cred_num in(SELECT trans_num FROM t_document)" 

			#The global selector properties for report engine / will be stored in arr_rec_rmsreps
			LET glob_rec_rpt_selector.sel_text = l_where_text
			LET glob_rec_rpt_selector.ref1_text =  NULL #"1!=1"
			LET glob_rec_rpt_selector.ref2_text = l_where_text

			--LET l_output = 
			#CALL --AS1_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"1!=1",l_where_text,	FALSE,l_rec_warehouse.inv_print_code) --print invoice
 			IF AS1_rpt_process_invoice_credit(l_where_text) THEN --print invoice
			--IF rms_print(glob_rec_kandoouser.cmpy_code,l_output,l_rec_warehouse.inv_print_code) THEN 
				LET l_event_text=	"Printed ",l_trans_cnt USING "<<<<"," credit Notes" 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
			ELSE 
				LET l_event_text = "Credit Note PRINT failed " 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,7089,	l_rec_warehouse.inv_print_code) 
			END IF 
		END IF 
	END IF 

	###  Generating/Printing Consignment Notes ###
	IF l_rec_warehouse.connote_flag = "Y" THEN 
		LET l_err_message = "Error E5A MESSAGE 010 - Refer to ", trim(get_settings_logFile()) 
		DELETE FROM t_document 
		LET l_err_message = "Error E5A MESSAGE 011 - Refer to ", trim(get_settings_logFile()) 
		#      INSERT INTO t_document
		#        SELECT inv_num,carrier_code,"" FROM invoicehead
		#         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#           AND inv_num in(SELECT inv_num FROM invoicedetl
		#                           WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                             AND inv_num = invoicehead.inv_num
		#                             AND ware_code = l_ware_code)
		## New INSERT clause
		INSERT INTO t_document(trans_num,carrier_code) 
		SELECT pickhead.pick_num, pickhead.carrier_code 
		FROM pickhead, pickdetl 
		WHERE pickhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pickdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pickhead.pick_num = pickdetl.pick_num 
		AND pickdetl.ware_code = l_ware_code 
		AND con_status_ind = "0" 
		GROUP BY 1,2 

		LET l_trans_cnt = 0 
		IF sqlca.sqlerrd[3] > 0 THEN 
			MESSAGE kandoomsg2("E",1052,l_rec_warehouse.desc_text) #1052 Currently processing warehouse ...

			DECLARE c0_document cursor with hold FOR 
			SELECT unique carrier_code FROM t_document 
			WHERE carrier_code IS NOT NULL
			 
			FOREACH c0_document INTO l_carrier_code 
				SELECT * INTO l_rec_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_carrier_code 
				LET l_rec_despatchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_despatchhead.despatch_date = today 
				LET l_rec_despatchhead.despatch_time = time 
				LET l_rec_despatchhead.amend_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_despatchhead.amend_date = today 
				LET l_rec_despatchhead.ware_code = l_ware_code 
				LET l_rec_despatchhead.carrier_code = l_rec_carrier.carrier_code 
				LET l_rec_despatchhead.com1_text = NULL 
				LET l_rec_despatchhead.com2_text = NULL 
				LET l_where_text = " pick_num in(SELECT trans_num FROM t_document ", 	"WHERE carrier_code='",l_rec_carrier.carrier_code,"')" 

				DELETE FROM tmp_danger WHERE 1=1 
				DELETE FROM tmp_carry WHERE 1=1 
				
				IF generate_connote(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_kandoouser.sign_on_code,
					l_where_text,
					l_rec_despatchhead.*, 
					"",
					TRUE,
					FALSE) THEN 
					
					LET l_err_message = "Error E5A MESSAGE 012 - Refer to ", trim(get_settings_logFile())
					UPDATE t_document 
					SET manifest_num = l_rec_carrier.next_manifest 
					WHERE carrier_code = l_rec_carrier.carrier_code 
					
					IF prepare_connote(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_kandoouser.sign_on_code, 
						l_rec_carrier.carrier_code, 
						l_ware_code, 
						l_rec_carrier.next_manifest, 
						"",
						"",
						FALSE) THEN #returns TRUE/FALSE 

--					IF rms_print(glob_rec_kandoouser.cmpy_code,l_output, l_rec_warehouse.connote_print_code)then 
						LET l_trans_cnt = l_trans_cnt + 1 
					ELSE 
						LET l_event_text = "Consignment Note PRINT failed " 
						CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,7089,l_rec_warehouse.connote_print_code) 
					END IF 
				END IF 
			END FOREACH 

			LET l_count = 0 
			SELECT count(*) INTO l_count 
			FROM t_document 
			WHERE carrier_code IS NOT NULL 
			AND manifest_num IS NOT NULL 

			IF l_count > 0 THEN 
				LET l_event_text = "Generated Consignment notes" 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
			END IF 

			LET l_err_message = "Error E5A MESSAGE 013 - Refer to ", trim(get_settings_logFile())

			IF l_trans_cnt > 0 THEN 
				LET l_event_text = "Printed consignment notes" 
				CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
			END IF 

			IF l_count > 0 THEN 
				##
				### Printing Shipping Labels ###
				## Shipping labels are printed FOR consignments
				##
				IF l_rec_warehouse.ship_label_flag = "Y" THEN 
					MESSAGE kandoomsg2("E",1052,l_rec_warehouse.desc_text) 				#1052 Currently processing warehouse ...
					LET l_trans_cnt = 0 
					DECLARE c1_document cursor with hold FOR 
					SELECT carrier_code,manifest_num FROM t_document 
					WHERE carrier_code IS NOT NULL 
					AND manifest_num IS NOT NULL 
					GROUP BY 1,2 

					FOREACH c1_document INTO l_carrier_code,l_manifest_num  #create a report for each iteration !? 
						SELECT * INTO l_rec_carrier.* 
						FROM carrier 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = l_carrier_code
						
						 
						--LET rpt_note = "EO - Shipping labels - Warehouse: ", 
						--l_ware_code," - Carrier: ",l_carrier_code

						LET l_where_text = "carrier_code = \"",l_carrier_code,"\" ", 
						"AND manifest_num = \"",l_manifest_num,"\" " 
						
						#------------------------------------------------------------
						LET l_rpt_idx = rpt_start(getmoduleid(),"E55_rpt_list_print_labels",l_where_text, RPT_SHOW_RMS_DIALOG)

						IF l_rpt_idx = 0 THEN #User pressed CANCEL
							RETURN FALSE
						END IF

						LET l_header_appendix = l_ware_code," - Carrier: ",l_carrier_code
						CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_header_appendix)
							
						START REPORT E55_rpt_list_print_labels TO rpt_get_report_file_with_path2(l_rpt_idx)
						WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
						TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
						BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
						LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
						RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
						#------------------------------------------------------------				 


						#---------------------------------------------------------
						OUTPUT TO REPORT AB5_rpt_list(l_rpt_idx,
						glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_where_text) 

						#---------------------------------------------------------		
 

						SELECT sum(despatch_qty) INTO l_rpt_pageno 
						FROM despatchdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = l_carrier_code 
						AND manifest_num = l_manifest_num
						 
--						IF l_rpt_pageno IS NULL THEN 
--							LET l_rpt_pageno = 0 
--						ELSE 
--							LET l_trans_cnt = l_trans_cnt + l_rpt_pageno 
--						END IF
-- ***************************** ---------------------						 
						#Calculate l_rpt_pageno by dividing number of labels by 2   <---- needs investigating
						--LET l_rpt_pageno = (l_rpt_pageno/2) + 1 
						--CALL upd_reports(l_output,l_rpt_pageno,rpt_width,rpt_length) 
						--FINISH REPORT E55_rpt_list_print_labels
						#------------------------------------------------------------
						FINISH REPORT E55_rpt_list_print_labels
						IF rpt_finish("E55_rpt_list_print_labels") < 1 THEN
						#------------------------------------------------------------						
-- ***************************** ---------------------
						--IF l_rpt_pageno > 0 THEN 
							--IF NOT rms_print(glob_rec_kandoouser.cmpy_code,l_output,		l_rec_warehouse.ship_print_code) THEN 
								LET l_event_text = "Shipping label PRINT failed " 
								CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,7089,	l_rec_warehouse.ship_print_code) 
							--END IF 
						END IF 
					END FOREACH 

					IF l_trans_cnt > 0 THEN
						LET l_event_text = 	"Printed ",l_trans_cnt USING "<<<<"," shipping labels" 
						CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
					END IF 
				END IF 
			END IF 
		END IF 
	END IF 

	IF NOT delete_pickslips(
		glob_rec_kandoouser.cmpy_code,
		l_ware_code, 
		l_rec_warehouse.pick_reten_num) 
	THEN
		LET l_event_text = "Warning: locking error occurred deleting old pickslips" 
		CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_event_text,"","") 
	END IF 
	LET l_err_message = "Error re-scheduling warehouse :",l_ware_code 

	--DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with UNITS minute" 
	--DISPLAY "see eo/e5x.4gl" 
	--EXIT PROGRAM (1) 

	LET l_str = 
		"UPDATE warehouse ", 
		" SET next_sched_date = current + auto_run_num units minute ", 
		" WHERE cmpy_code = glob_rec_kandoouser.cmpy_code ", 
		" AND ware_code = l_ware_code" 

	EXECUTE immediate l_str 



	WHENEVER ERROR stop 
	--   CLOSE WINDOW w1_E5X  -- albo  KD-755
	--EXIT PROGRAM 
	LABEL recovery: 
	CALL delivery_msg(glob_rec_kandoouser.cmpy_code,l_ware_code,l_err_message,"","") 
END FUNCTION 
###########################################################################
# END FUNCTION E5X_main()
###########################################################################


###########################################################################
# FUNCTION warehouse_free(p_ware_code) 
#
#
###########################################################################
FUNCTION warehouse_free(p_ware_code) 
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_next_sched_date DATETIME year TO minute 
	DEFINE l_datetime DATETIME year TO minute 

	WHENEVER ERROR CONTINUE 
	BEGIN WORK 
		#Moved INTO variables, because non-Informix
		#RDBMS do NOT have server-side current year TO minute OR
		#units minute functionality, but <Anton Dickinson> does
		LET l_datetime = CURRENT year TO minute 

		DECLARE c_warehouse cursor FOR 
		SELECT * 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		#AND next_sched_date <= current year TO minute
		AND next_sched_date <= l_datetime 
		FOR UPDATE 

		OPEN c_warehouse 
		FETCH c_warehouse INTO l_rec_warehouse.* 
		IF sqlca.sqlcode = 0 THEN 
			IF l_rec_warehouse.auto_run_num IS NULL THEN 
				LET l_rec_warehouse.auto_run_num = 0 
			END IF 

			LET l_next_sched_date = CURRENT + 240 units minute 

			UPDATE warehouse 
			#SET next_sched_date = current + 240 units minute
			SET next_sched_date = l_next_sched_date 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_ware_code 
		COMMIT WORK 
		RETURN TRUE 
	ELSE 
		ROLLBACK WORK 
		RETURN FALSE 
	END IF 

	WHENEVER ERROR stop 

END FUNCTION 
###########################################################################
# END FUNCTION warehouse_free(p_ware_code) 
###########################################################################


###########################################################################
# FUNCTION delivery_msg(p_cmpy,p_ware_code,p_event_text,p_msg_num,p_msg_text) 
#
#
###########################################################################
FUNCTION delivery_msg(p_cmpy,p_ware_code,p_event_text,p_msg_num,p_msg_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_ware_code char(3) 
	DEFINE l_time char(5) 
	DEFINE p_event_text char(40) 
	DEFINE p_msg_num INTEGER 
	DEFINE p_msg_text nchar(60) 

	LET l_time = time 
	INSERT INTO delivmsg VALUES (
		p_cmpy,
		0,
		p_ware_code,
		today,
		l_time, 
		p_event_text, 
		p_msg_num, 
		p_msg_text) 
END FUNCTION 
###########################################################################
# END FUNCTION delivery_msg(p_cmpy,p_ware_code,p_event_text,p_msg_num,p_msg_text) 
###########################################################################


###########################################################################
# FUNCTION delete_pickslips(p_cmpy,p_ware_code,p_reten_num)  
#
#
###########################################################################
FUNCTION delete_pickslips(p_cmpy,p_ware_code,p_reten_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_reten_num LIKE warehouse.pick_reten_num 
	DEFINE x LIKE pickhead.pick_num 

	IF p_reten_num IS NOT NULL THEN 
		GOTO bypass 
		LABEL recovery: 
		ROLLBACK WORK 
		RETURN FALSE 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery
		 
		BEGIN WORK 
			DECLARE c_pickhead cursor FOR 
			SELECT pick_num FROM pickhead 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = p_ware_code 
			AND status_ind != "0" 
			AND con_status_ind != "0" 
			AND pick_date < (today - p_reten_num) 
			FOR UPDATE 

			FOREACH c_pickhead INTO x 
				DELETE FROM pickdetl 
				WHERE cmpy_code = p_cmpy 
				AND ware_code = p_ware_code 
				AND pick_num = x 
				DELETE FROM pickhead 
				WHERE cmpy_code = p_cmpy 
				AND ware_code = p_ware_code 
				AND pick_num = x 
			END FOREACH 

		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
	
	RETURN TRUE 
END FUNCTION
###########################################################################
# END FUNCTION delivery_msg(p_cmpy,p_ware_code,l_event_text,l_msg_num,l_msg_text) 
###########################################################################