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
GLOBALS "../eo/ES1_GLOBALS.4gl" 
###########################################################################
# FUNCTION ES1_main()
#
# ES1 Management Information Statistics Extraction
###########################################################################
FUNCTION ES1_main() 
	DEFINE l_rec_stattrig RECORD LIKE stattrig.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rowid INTEGER 
	DEFINE l_trans_cnt INTEGER 
	DEFINE i INTEGER 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	

	#note, if this program is just a report, these options must be removed
	DEFINE l_arg_verbose BOOLEAN
	DEFINE l_arg_cmpy_code LIKE company.cmpy_code
	
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ES1") -- albo 
	

	#### The following code allows the program TO be run as a background task
	#### The command line must be as follows
	####
	####    fglgo|fglrun ES1 B [glob_rec_kandoouser.cmpy_code]
	####
	#### IF glob_rec_kandoouser.cmpy_code IS ommitted THEN it will be SET TO the company code of the user
	#### running the background process, usually root

	#this is original legacy way of background parameters... if it's a report, it must be romved !
	LET l_arg_verbose = get_url_verbose()
	LET l_arg_cmpy_code = get_url_cmpy_code()

	LET glob_backgrnd = FALSE 

	IF l_arg_verbose = TRUE THEN
			LET glob_backgrnd = TRUE 
			IF l_arg_cmpy_code IS NOT NULL THEN
				LET glob_rec_kandoouser.cmpy_code = l_arg_cmpy_code 
			END IF 
	END IF

	IF glob_rec_statparms.trans_limit_num IS NULL THEN 
		LET glob_rec_statparms.trans_limit_num = 100 
	END IF 

	IF NOT glob_backgrnd THEN 
		OPEN WINDOW E209 with FORM "E209" 
		 CALL windecoration_e("E209") -- albo kd-755 
		CALL disp_statinfo() 
	END IF 

	#----------------------------
	# invoicedetl
	LET l_query_text = 
		"SELECT * FROM invoicedetl ", 
		"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND inv_num=? ", 
		"AND part_code IS NOT null" 
	PREPARE s_invoicedetl FROM l_query_text 
	DECLARE c_invoicedetl cursor FOR s_invoicedetl 
	
	#----------------------------
	# creditdetl
	LET l_query_text = 
		"SELECT * FROM creditdetl ", 
		"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cred_num=? ", 
		"AND part_code IS NOT null" 
	PREPARE s_creditdetl FROM l_query_text 
	DECLARE c_creditdetl cursor FOR s_creditdetl 
	
	#----------------------------
	# Maingrp
	LET l_query_text = 
		" SELECT dept_code FROM maingrp ", 
		" WHERE maingrp_code = ? ", 
		" AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'" 
	PREPARE s_maingrp FROM l_query_text 
	DECLARE c_maingrp cursor with hold FOR s_maingrp 
	IF glob_backgrnd THEN 
		LET glob_dist_flag = "N" 
		--IF rpt_note IS NULL THEN 
		--	LET rpt_note = "EO Sales statistics extraction report" 
		--END IF 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"ES1_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ES1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

		CALL mod_indices("T","START") 
		SELECT unique 1 FROM statdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			CALL errorlog("Previous Post Incomplete.. continuing") 
			CALL post_tables() 
		ELSE 
			WHILE TRUE 
				DECLARE c_stattrig cursor with hold FOR 
				SELECT rowid,* FROM stattrig 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				ORDER BY tran_date 
				OPEN c_stattrig 
				FOR i = 1 TO glob_rec_statparms.trans_limit_num 
					FETCH c_stattrig INTO l_rowid, 
					l_rec_stattrig.* 
					IF status = NOTFOUND THEN 
						EXIT FOR 
					ELSE 
						LET l_trans_cnt = l_trans_cnt + 1 
						IF insert_data(l_rowid) THEN
							#---------------------------------------------------------
							OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
							1,
							l_rec_stattrig.trans_num, 
							l_rec_stattrig.tran_type_ind)  
							#---------------------------------------------------------						
						 
						ELSE 
							LET quit_flag = TRUE 
							#---------------------------------------------------------
							OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
							2,
							l_rec_stattrig.trans_num, 
							l_rec_stattrig.tran_type_ind)  
							#---------------------------------------------------------
						END IF 
					END IF 
				END FOR 
				CLOSE c_stattrig 
				CALL post_tables() 
				SELECT unique 1 FROM stattrig 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					EXIT WHILE 
				END IF 
			END WHILE 
		END IF 
		
		CALL mod_indices("T","STOP") 
		IF NOT quit_flag THEN 
			CALL mod_indices("I","START") 
			IF NOT post_intervals() THEN 
				LET quit_flag = TRUE 
			END IF 
			CALL mod_indices("I","STOP") 
		END IF
		 
		LET glob_rec_statparms.last_upd_date = today 
		UPDATE statparms SET * = glob_rec_statparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		
			
		#------------------------------------------------------------
		FINISH REPORT ES1_rpt_list
		CALL rpt_finish("ES1_rpt_list")
		#------------------------------------------------------------
		 
		IF int_flag THEN 
			LET int_flag = FALSE 
			ERROR " Printing was aborted" 
			RETURN FALSE 
		ELSE 
			RETURN TRUE 
		END IF 

	ELSE 

		MENU " Statistics update" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ES1","menu-Statistics_Update-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Distrib" " Toggle distributions FOR Update " 
				IF glob_dist_flag = "N" THEN 
					LET glob_dist_flag = "Y" 
				ELSE 
					LET glob_dist_flag = "N" 
				END IF 
				DISPLAY BY NAME glob_dist_flag 

			ON ACTION "UPDATE" #COMMAND "Update" " Commence UPDATE procedure"
				IF promptTF("",kandoomsg2("E",8030,""),1)	THEN	#8030 Confiw!rm TO start UPDATE
					OPEN WINDOW E215 with FORM "E215" 
					 CALL windecoration_e("E209") -- albo kd-755 
					
					--MESSAGE kandoomsg2("E",1005,"") 
					#------------------------------------------------------------
					LET l_rpt_idx = rpt_start(getmoduleid(),"ES1_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
					IF l_rpt_idx = 0 THEN #User pressed CANCEL
						RETURN FALSE
					END IF	
					START REPORT ES1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
					WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
					TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
					BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
					LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
					RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
					#------------------------------------------------------------
					
					CALL mod_indices("T","START") 
					SELECT unique 1 FROM statdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					 
					IF status = 0 THEN 
						IF kandoomsg("E",8033,"")= "Y" THEN 
							CALL post_tables() 
						ELSE 
							LET quit_flag = TRUE 
							NEXT option "Exit" 
						END IF 
					ELSE 
						WHILE TRUE 
							DECLARE c2_stattrig cursor with hold FOR 
							SELECT rowid,* FROM stattrig 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							ORDER BY tran_date 
							OPEN c2_stattrig 
							FOR i = 1 TO glob_rec_statparms.trans_limit_num 
								FETCH c2_stattrig INTO l_rowid, 
								l_rec_stattrig.* 
								IF status = NOTFOUND THEN 
									EXIT FOR 
								ELSE 
									LET l_trans_cnt = l_trans_cnt + 1 
									DISPLAY l_trans_cnt TO trans_cnt 

									IF insert_data(l_rowid) THEN 
										#---------------------------------------------------------
										OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
										1,
										l_rec_stattrig.trans_num, 
										l_rec_stattrig.tran_type_ind)  
										#---------------------------------------------------------										
									ELSE 
										LET quit_flag = TRUE 
										#---------------------------------------------------------
										OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
										2,
										l_rec_stattrig.trans_num, 
										l_rec_stattrig.tran_type_ind)  
										#---------------------------------------------------------		
									END IF 
								END IF 
							END FOR 
							
							CLOSE c2_stattrig 
							CALL post_tables() 
							SELECT unique 1 FROM stattrig 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status = NOTFOUND THEN 
								EXIT WHILE 
							END IF 
						END WHILE 
					END IF 
					
					CALL mod_indices("T","STOP") 
					IF NOT quit_flag THEN 
						CALL mod_indices("I","START") 
						IF NOT post_intervals() THEN 
							LET quit_flag = TRUE 
						END IF 
						CALL mod_indices("I","STOP") 
					END IF
					 
					IF glob_dist_flag = "Y" AND quit_flag = FALSE THEN 
						CALL mod_indices("D","START") 
						DECLARE c_distrib cursor FOR 
						SELECT * INTO l_rec_statint.* 
						FROM statint 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_code = glob_rec_statparms.mth_type_code 
						AND dist_flag = "Y" 
						AND end_date <= today 
						FOREACH c_distrib INTO l_rec_statint.* 
							IF upd_distribution(l_rec_statint.*) THEN 
								#---------------------------------------------------------
								OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
								5,
								l_rec_statint.year_num, 
								l_rec_statint.int_text) 
								#---------------------------------------------------------									
							ELSE 
								LET quit_flag = TRUE 
								#---------------------------------------------------------
								OUTPUT TO REPORT ES1_rpt_list(l_rpt_idx,
								5,
								l_rec_statint.year_num, 
								l_rec_statint.int_text) 
								#---------------------------------------------------------		
							END IF 
						END FOREACH 
						LET glob_rec_statparms.last_dist_date = today 
						CALL mod_indices("D","STOP") 
					END IF 

					LET glob_rec_statparms.last_upd_date = today 
					UPDATE statparms SET * = glob_rec_statparms.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 

					#------------------------------------------------------------
					FINISH REPORT ES1_rpt_list
					CALL rpt_finish("ES1_rpt_list")
					#------------------------------------------------------------
					 
					IF int_flag THEN 
						LET int_flag = FALSE 
						
						ERROR kandoomsg2("E",7085,"") #ERROR " Printing was aborted" 
					ELSE 
						MESSAGE kandoomsg2("E",7084,"") 
					END IF 

					CLOSE WINDOW E215 
				END IF 

			ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","")
				 
			ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E") "Exit" " Exit TO menus" 
				EXIT MENU 
		END MENU 

		CLOSE WINDOW E209 
	END IF 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END ES1_main()
###########################################################################


############################################################
# FUNCTION ES1_rpt_query()
#
# RETURN l_where_text
############################################################
FUNCTION ES1_rpt_query()
	DEFINE l_where_text STRING
	#Not Used YET ...f... m... c.....
END FUNCTION	
############################################################
# END FUNCTION ES1_rpt_query()
############################################################


###########################################################################
# FUNCTION insert_data(p_rowid)
#
# 
###########################################################################
FUNCTION insert_data(p_rowid) 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_stattrig RECORD LIKE stattrig.* 
	DEFINE l_rec_statorder RECORD LIKE statorder.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_stathead RECORD LIKE stathead.* 
	DEFINE l_rec_statdetl RECORD LIKE statdetl.* 
	DEFINE l_rec_s_statdetl RECORD LIKE statdetl.* 
	DEFINE l_rec_saleshare RECORD LIKE saleshare.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_rec_maingrp RECORD LIKE maingrp.* 
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_comm_amt LIKE invoicedetl.comm_amt 
	DEFINE l_share_per LIKE saleshare.share_per 
	DEFINE l_min_amt LIKE product.min_month_amt 

	#  WHENEVER ERROR GOTO recovery
	BEGIN WORK 
		DECLARE c_statdetl cursor FOR 
		INSERT INTO statdetl VALUES (l_rec_statdetl.*) 
		OPEN c_statdetl 
		DECLARE c_stathead cursor FOR 
		INSERT INTO stathead VALUES (l_rec_stathead.*) 
		OPEN c_stathead 
		DECLARE c_statorder cursor FOR 
		INSERT INTO statorder VALUES (l_rec_statorder.*) 
		OPEN c_statorder 
		DECLARE c1_stattrig cursor FOR 
		SELECT * FROM stattrig 
		WHERE rowid = p_rowid 
		
		FOR UPDATE 
		OPEN c1_stattrig 
		FETCH c1_stattrig INTO l_rec_stattrig.* 

		IF l_rec_stattrig.tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 

			#get invoiceHead record
			IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_rec_stattrig.trans_num) THEN
				CALL db_invoicehead_get_rec(UI_ON,l_rec_stattrig.trans_num) RETURNING  l_rec_invoicehead.*
			ELSE	#IF status = NOTFOUND THEN 
				GOTO recovery 
			END IF
			 
			#-------------------------------------------------
			# Check FOR corp cust AND determine which cust
			## will RECORD the statistics
			LET l_rec_stathead.cmpy_code = l_rec_invoicehead.cmpy_code 
			LET l_rec_stathead.trans_num = l_rec_invoicehead.inv_num 
			LET l_rec_stathead.trans_date = l_rec_invoicehead.inv_date 
			IF l_rec_invoicehead.org_cust_code IS NULL THEN 
				LET l_rec_stathead.cust_code = l_rec_invoicehead.cust_code 
			ELSE 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_invoicehead.org_cust_code 
				IF l_rec_customer.sales_anly_flag = "C" THEN 
					LET l_rec_stathead.cust_code = l_rec_invoicehead.cust_code 
				ELSE 
					LET l_rec_stathead.cust_code = l_rec_invoicehead.org_cust_code 
				END IF 
			END IF 
			OPEN c_invoicedetl USING l_rec_stattrig.trans_num 
		ELSE 
			SELECT * INTO l_rec_credithead.* FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = l_rec_stattrig.trans_num 
			IF status = NOTFOUND THEN 
				GOTO recovery 
			END IF 
			## Check FOR corp cust AND determine which cust
			## will RECORD the statistics
			LET l_rec_stathead.cmpy_code = l_rec_credithead.cmpy_code 
			LET l_rec_stathead.trans_num = l_rec_credithead.cred_num 
			LET l_rec_stathead.trans_date = l_rec_credithead.cred_date 
			IF l_rec_credithead.org_cust_code IS NULL THEN 
				LET l_rec_stathead.cust_code = l_rec_credithead.cust_code 
			ELSE 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_credithead.org_cust_code 
				IF l_rec_customer.sales_anly_flag = "C" THEN 
					LET l_rec_stathead.cust_code = l_rec_credithead.cust_code 
				ELSE 
					LET l_rec_stathead.cust_code = l_rec_credithead.org_cust_code 
				END IF 
			END IF 
			OPEN c_creditdetl USING l_rec_stattrig.trans_num 
		END IF
		 
		LET l_rec_stathead.gross_amt = 0 
		LET l_rec_stathead.net_amt = 0 
		LET l_rec_stathead.cost_amt = 0 
		LET l_rec_stathead.sales_qty = 0
		 
		WHILE TRUE 
			IF l_rec_stattrig.tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
				FETCH c_invoicedetl INTO l_rec_invoicedetl.* 
				IF status = NOTFOUND THEN 
					EXIT WHILE 
				END IF 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = l_rec_invoicedetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					CONTINUE WHILE 
				END IF 
				LET l_min_amt = l_rec_product.min_month_amt 
				IF l_rec_invoicedetl.ext_sale_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				LET l_rec_prodgrp.min_month_amt = 0 
				IF get_kandoooption_feature_state("EO","SD") = "1" THEN 
					SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
					WHERE prodgrp_code = l_rec_invoicedetl.prodgrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
						WHERE prodgrp_code = l_rec_product.prodgrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
					WHERE prodgrp_code = l_rec_product.prodgrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				LET l_min_amt = l_rec_prodgrp.min_month_amt 
				IF l_rec_invoicedetl.ext_sale_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				LET l_rec_maingrp.min_month_amt = 0 
				IF get_kandoooption_feature_state("EO","SD") = "1" THEN 
					SELECT * INTO l_rec_maingrp.* FROM maingrp 
					WHERE maingrp_code = l_rec_invoicedetl.maingrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_maingrp.* FROM maingrp 
						WHERE maingrp_code = l_rec_product.maingrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_maingrp.* FROM maingrp 
					WHERE maingrp_code = l_rec_product.maingrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				LET l_min_amt = l_rec_maingrp.min_month_amt 
				IF l_rec_invoicedetl.ext_sale_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				IF l_rec_invoicedetl.ext_stats_amt IS NULL 
				OR l_rec_invoicedetl.ext_stats_amt = 0 THEN 
					LET l_rec_invoicedetl.ext_stats_amt = l_rec_invoicedetl.ext_sale_amt 
				END IF 
				LET l_rec_statdetl.cond_code = l_rec_invoicehead.cond_code 
				LET l_rec_statdetl.sale_code = l_rec_invoicehead.sale_code 
				LET l_rec_statdetl.mgr_code = l_rec_invoicehead.mgr_code 
				LET l_rec_statdetl.terr_code = l_rec_invoicehead.territory_code 
				LET l_rec_statdetl.area_code = l_rec_invoicehead.area_code 
				OPEN c_maingrp USING l_rec_invoicedetl.maingrp_code 
				FETCH c_maingrp INTO l_rec_statdetl.dept_code 
				LET l_rec_statdetl.maingrp_code = l_rec_invoicedetl.maingrp_code 
				LET l_rec_statdetl.prodgrp_code = l_rec_invoicedetl.prodgrp_code 
				LET l_rec_statdetl.part_code = l_rec_invoicedetl.part_code 
				LET l_rec_statdetl.ware_code = l_rec_invoicedetl.ware_code 
				LET l_rec_statdetl.offer_code = l_rec_invoicedetl.offer_code 
				LET l_rec_statdetl.grs_amt = l_rec_invoicedetl.ship_qty 
				* l_rec_invoicedetl.list_price_amt 
				LET l_rec_statdetl.grs_inv_amt = l_rec_statdetl.grs_amt 
				LET l_rec_statdetl.grs_cred_amt = 0 
				LET l_rec_statdetl.net_amt = l_rec_invoicedetl.ext_stats_amt 
				LET l_rec_statdetl.net_inv_amt = l_rec_invoicedetl.ext_stats_amt 
				LET l_rec_statdetl.net_cred_amt = 0 
				LET l_rec_statdetl.cost_amt = l_rec_invoicedetl.ext_cost_amt 
				LET l_rec_statdetl.sales_qty = l_rec_invoicedetl.ship_qty 
				LET l_rec_statdetl.comm_amt = l_rec_invoicedetl.comm_amt 
				LET l_rec_statdetl.order_num = l_rec_invoicedetl.order_num 
			ELSE 
				FETCH c_creditdetl INTO l_rec_creditdetl.* 
				IF status = NOTFOUND THEN 
					EXIT WHILE 
				END IF 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = l_rec_creditdetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					CONTINUE WHILE 
				END IF 
				LET l_min_amt = l_rec_product.min_month_amt 
				IF l_rec_creditdetl.ext_sales_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				LET l_rec_prodgrp.min_month_amt = 0 
				IF get_kandoooption_feature_state("EO","SD") = "1" THEN 
					SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
					WHERE prodgrp_code = l_rec_creditdetl.prodgrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
						WHERE prodgrp_code = l_rec_product.prodgrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_prodgrp.* FROM prodgrp 
					WHERE prodgrp_code = l_rec_product.prodgrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				
				LET l_min_amt = l_rec_prodgrp.min_month_amt 
				IF l_rec_creditdetl.ext_sales_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				LET l_rec_maingrp.min_month_amt = 0 
				IF get_kandoooption_feature_state("EO","SD") = "1" THEN 
					SELECT * INTO l_rec_maingrp.* FROM maingrp 
					WHERE maingrp_code = l_rec_creditdetl.maingrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_maingrp.* FROM maingrp 
						WHERE maingrp_code = l_rec_product.maingrp_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
					SELECT * INTO l_rec_maingrp.* FROM maingrp 
					WHERE maingrp_code = l_rec_product.maingrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				LET l_min_amt = l_rec_maingrp.min_month_amt 
				IF l_rec_creditdetl.ext_sales_amt < l_min_amt THEN 
					CONTINUE WHILE 
				END IF 
				
				IF l_rec_creditdetl.invoice_num > 0	AND l_rec_creditdetl.inv_line_num > 0 THEN 
					IF l_rec_invoicehead.inv_num IS NULL	OR l_rec_invoicehead.inv_num != l_rec_creditdetl.invoice_num THEN 
						
						#get invoiceHead record
						IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_rec_creditdetl.invoice_num) THEN
							CALL db_invoicehead_get_rec(UI_ON,l_rec_creditdetl.invoice_num ) RETURNING  l_rec_invoicehead.*
										
						ELSE #	IF status = NOTFOUND THEN 
							LET l_rec_creditdetl.invoice_num = 0 
							LET l_rec_creditdetl.inv_line_num = 0 
						END IF 
					END IF 
					
					IF l_rec_creditdetl.invoice_num > 0	AND l_rec_creditdetl.inv_line_num > 0 THEN 
						SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_rec_creditdetl.invoice_num 
						AND line_num = l_rec_creditdetl.inv_line_num 
						AND part_code = l_rec_creditdetl.part_code 
						IF status = NOTFOUND THEN 
							LET l_rec_creditdetl.invoice_num = 0 
							LET l_rec_creditdetl.inv_line_num = 0 
						END IF 
					END IF 
				END IF 
				IF l_rec_creditdetl.invoice_num > 0 
				AND l_rec_creditdetl.inv_line_num > 0 THEN 
					### Invoice related Credit

					## Do NOT use creditdetl VALUES instead of invoicedetl VALUES
					## as these are used TO calculate commission VALUES
					## Use extreme caution!

					IF l_rec_invoicedetl.ext_stats_amt IS NULL OR l_rec_invoicedetl.ext_stats_amt = 0 THEN 
						LET l_rec_invoicedetl.ext_stats_amt = l_rec_invoicedetl.ext_sale_amt 
					END IF 
					
					IF l_rec_invoicedetl.ship_qty IS NULL OR l_rec_invoicedetl.ship_qty = 0 THEN 
						LET l_rec_invoicedetl.ship_qty = 1 
					END IF 
					
					LET l_rec_statdetl.net_amt = 0 -((l_rec_invoicedetl.ext_stats_amt /	l_rec_invoicedetl.ship_qty) *	l_rec_creditdetl.ship_qty) 
					LET l_rec_statdetl.cond_code = l_rec_credithead.cond_code 
					LET l_rec_statdetl.sale_code = l_rec_credithead.sale_code 
					LET l_rec_statdetl.mgr_code = l_rec_credithead.mgr_code 
					LET l_rec_statdetl.terr_code = l_rec_credithead.territory_code 
					LET l_rec_statdetl.area_code = l_rec_credithead.area_code 
					
					OPEN c_maingrp USING l_rec_creditdetl.maingrp_code
					 
					FETCH c_maingrp INTO l_rec_statdetl.dept_code 
					LET l_rec_statdetl.maingrp_code = l_rec_creditdetl.maingrp_code 
					LET l_rec_statdetl.prodgrp_code = l_rec_creditdetl.prodgrp_code 
					LET l_rec_statdetl.part_code = l_rec_creditdetl.part_code 
					LET l_rec_statdetl.ware_code = l_rec_creditdetl.ware_code 
					LET l_rec_statdetl.offer_code = l_rec_invoicedetl.offer_code 
					LET l_rec_statdetl.grs_amt = 0 - (l_rec_creditdetl.ship_qty * l_rec_invoicedetl.list_price_amt) 
					LET l_rec_statdetl.grs_inv_amt = 0 
					LET l_rec_statdetl.grs_cred_amt = 0 - l_rec_statdetl.grs_amt 
					LET l_rec_statdetl.net_inv_amt = 0 
					LET l_rec_statdetl.net_cred_amt = 0 - l_rec_statdetl.net_amt 
					LET l_rec_statdetl.cost_amt = 0 - l_rec_creditdetl.ext_cost_amt 
					LET l_rec_statdetl.sales_qty = 0 - l_rec_creditdetl.ship_qty 
					LET l_rec_statdetl.order_num = l_rec_invoicedetl.order_num 
					
					IF l_rec_invoicedetl.ship_qty > 0 THEN 
						LET l_rec_statdetl.comm_amt = 0 - (l_rec_creditdetl.comm_amt * (l_rec_creditdetl.ship_qty/l_rec_invoicedetl.ship_qty)) 
					ELSE 
						LET l_rec_statdetl.comm_amt = 0 
					END IF 
				ELSE 
					### Non Invoice related Credit
					LET l_rec_statdetl.cond_code = NULL 
					LET l_rec_statdetl.sale_code = l_rec_credithead.sale_code 
					LET l_rec_statdetl.mgr_code = NULL 
					LET l_rec_statdetl.terr_code = NULL 
					LET l_rec_statdetl.area_code = NULL 
					LET l_rec_statdetl.dept_code = NULL 
					LET l_rec_statdetl.maingrp_code = NULL 
					LET l_rec_statdetl.prodgrp_code = NULL 
					LET l_rec_statdetl.part_code = l_rec_creditdetl.part_code 
					LET l_rec_statdetl.ware_code = l_rec_creditdetl.ware_code 
					LET l_rec_statdetl.offer_code = NULL 
					LET l_rec_statdetl.grs_amt = 0 - l_rec_creditdetl.ext_sales_amt 
					LET l_rec_statdetl.grs_inv_amt = 0 
					LET l_rec_statdetl.grs_cred_amt = l_rec_creditdetl.ext_sales_amt 
					LET l_rec_statdetl.net_amt = 0 - l_rec_creditdetl.ext_sales_amt 
					LET l_rec_statdetl.net_inv_amt = 0 
					LET l_rec_statdetl.net_cred_amt = l_rec_creditdetl.ext_sales_amt 
					LET l_rec_statdetl.cost_amt = 0 - l_rec_creditdetl.ext_cost_amt 
					LET l_rec_statdetl.sales_qty = 0 - l_rec_creditdetl.ship_qty 
					LET l_rec_statdetl.comm_amt = 0 - l_rec_creditdetl.comm_amt 
					LET l_rec_statdetl.order_num = NULL 
				END IF 
			END IF 
			
			LET l_rec_statdetl.cmpy_code = l_rec_stathead.cmpy_code 
			LET l_rec_statdetl.trans_date = l_rec_stathead.trans_date 
			LET l_rec_statdetl.cust_code = l_rec_stathead.cust_code 
			
			IF l_rec_statdetl.net_amt IS NULL THEN 
				LET l_rec_statdetl.net_amt = 0 
			END IF 
			
			IF l_rec_statdetl.net_inv_amt IS NULL THEN 
				LET l_rec_statdetl.net_inv_amt = 0 
			END IF 
			
			IF l_rec_statdetl.net_cred_amt IS NULL THEN 
				LET l_rec_statdetl.net_cred_amt = 0 
			END IF 
			
			IF l_rec_statdetl.grs_amt IS NULL THEN 
				LET l_rec_statdetl.grs_amt = 0 
			END IF 
			
			IF l_rec_statdetl.grs_inv_amt IS NULL THEN 
				LET l_rec_statdetl.grs_inv_amt = 0 
			END IF 
			
			IF l_rec_statdetl.grs_cred_amt IS NULL THEN 
				LET l_rec_statdetl.grs_cred_amt = 0 
			END IF 
			
			IF l_rec_statdetl.cost_amt IS NULL THEN 
				LET l_rec_statdetl.cost_amt = 0 
			END IF 
			
			IF l_rec_statdetl.sales_qty IS NULL THEN 
				LET l_rec_statdetl.sales_qty = 0 
			END IF 
			
			IF l_rec_statdetl.comm_amt IS NULL THEN 
				LET l_rec_statdetl.comm_amt = 0 
			END IF 
			
			IF l_rec_statdetl.offer_code IS NULL THEN 
				LET l_rec_statdetl.grs_offer_amt = 0 
				LET l_rec_statdetl.net_offer_amt = 0 
				LET l_rec_statdetl.offer_qty = 0 
			ELSE 
				LET l_rec_statdetl.grs_offer_amt = l_rec_statdetl.grs_amt 
				LET l_rec_statdetl.net_offer_amt = l_rec_statdetl.net_amt 
				SELECT * INTO l_rec_orderoffer.* FROM orderoffer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rec_statdetl.order_num 
				AND offer_code = l_rec_statdetl.offer_code 
				IF l_rec_orderoffer.gross_amt > 0 THEN 
					LET l_rec_statdetl.offer_qty = l_rec_orderoffer.offer_qty 
					* l_rec_statdetl.grs_amt 
					/ l_rec_orderoffer.gross_amt 
				ELSE 
					LET l_rec_statdetl.offer_qty = 0 
				END IF 
			END IF 
			
			IF l_rec_statdetl.prodgrp_code IS NULL OR l_rec_statdetl.maingrp_code IS NULL THEN 
				LET l_rec_statdetl.prodgrp_code = l_rec_product.prodgrp_code 
				LET l_rec_statdetl.maingrp_code = l_rec_product.maingrp_code 
			END IF 
			
			IF l_rec_statdetl.dept_code IS NULL THEN 
				OPEN c_maingrp USING l_rec_statdetl.maingrp_code 
				FETCH c_maingrp INTO l_rec_statdetl.dept_code 
			END IF 
			
			IF l_rec_statdetl.mgr_code IS NULL THEN 
				SELECT mgr_code INTO l_rec_statdetl.mgr_code FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_rec_statdetl.sale_code 
				IF status = NOTFOUND 
				OR l_rec_statdetl.mgr_code IS NULL THEN 
					LET l_rec_statdetl.mgr_code = "NULL" 
				END IF 
			END IF 
			
			IF l_rec_statdetl.terr_code IS NULL THEN 
				SELECT territory_code INTO l_rec_statdetl.terr_code 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_statdetl.cust_code 
				IF status = NOTFOUND 
				OR l_rec_statdetl.terr_code IS NULL THEN 
					LET l_rec_statdetl.terr_code = "NULL" 
				END IF 
			END IF 
			
			IF l_rec_statdetl.area_code IS NULL THEN 
				SELECT area_code INTO l_rec_statdetl.area_code 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = l_rec_statdetl.terr_code 
				IF status = NOTFOUND 
				OR l_rec_statdetl.area_code IS NULL THEN 
					LET l_rec_statdetl.area_code = "NULL" 
				END IF 
			END IF 
			
			## Distribute sales commission TO salespersons
			SELECT unique 1 FROM saleshare 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_rec_statdetl.order_num 
			IF status = 0 THEN 
				## WHEN distributing commission,  create a ps_record which
				## zero sales but a non-zero commission
				LET l_comm_amt = l_rec_statdetl.comm_amt 
				LET l_rec_s_statdetl.* = l_rec_statdetl.* 
				LET l_rec_s_statdetl.grs_amt = 0 
				LET l_rec_s_statdetl.grs_inv_amt = 0 
				LET l_rec_s_statdetl.grs_cred_amt = 0 
				LET l_rec_s_statdetl.grs_offer_amt = 0 
				LET l_rec_s_statdetl.net_amt = 0 
				LET l_rec_s_statdetl.net_inv_amt = 0 
				LET l_rec_s_statdetl.net_cred_amt = 0 
				LET l_rec_s_statdetl.net_offer_amt = 0 
				LET l_rec_s_statdetl.cost_amt = 0 
				LET l_rec_s_statdetl.sales_qty = 0 
				
				# reset share of selling salesperson as it may receive none
				LET l_share_per = 0 
				DECLARE c_saleshare cursor FOR 
				SELECT * FROM saleshare 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rec_statdetl.order_num 
				
				FOREACH c_saleshare INTO l_rec_saleshare.* 
					IF l_rec_saleshare.sale_code = l_rec_statdetl.sale_code THEN 
						LET l_share_per = l_rec_saleshare.share_per 
					ELSE 
						LET l_rec_s_statdetl.sale_code = l_rec_saleshare.sale_code 
						SELECT mgr_code INTO l_rec_s_statdetl.mgr_code 
						FROM salesperson 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND sale_code = l_rec_s_statdetl.sale_code 
						LET l_rec_s_statdetl.comm_amt = 		l_comm_amt * (l_rec_saleshare.share_per/100) 
						INSERT INTO statdetl VALUES (l_rec_s_statdetl.*) 
					END IF 
					## Modify the initial entry TO relect TRUE commission
					LET l_rec_statdetl.comm_amt=l_comm_amt*(l_share_per/100) 
				END FOREACH 
			END IF 
			
			LET l_rec_stathead.gross_amt = l_rec_stathead.gross_amt + l_rec_statdetl.grs_amt 
			LET l_rec_stathead.net_amt = l_rec_stathead.net_amt + l_rec_statdetl.net_amt 
			LET l_rec_stathead.cost_amt = l_rec_stathead.cost_amt + l_rec_statdetl.cost_amt 
			LET l_rec_stathead.sales_qty = l_rec_stathead.sales_qty + l_rec_statdetl.sales_qty 
			PUT c_statdetl 
		END WHILE 
		PUT c_stathead 
		DELETE FROM stattrig WHERE rowid = p_rowid 
		LET l_rec_statorder.cmpy_code = l_rec_stathead.cmpy_code 
		LET l_rec_statorder.tran_type_ind = l_rec_stattrig.tran_type_ind 
		LET l_rec_statorder.trans_num = l_rec_stathead.trans_num 
		LET l_rec_statorder.trans_date = l_rec_stathead.trans_date 
		LET l_rec_statorder.cust_code = l_rec_stathead.cust_code 
		LET l_rec_statorder.sale_code = l_rec_statdetl.sale_code 
		LET l_rec_statorder.mgr_code = l_rec_statdetl.mgr_code 
		LET l_rec_statorder.terr_code = l_rec_statdetl.terr_code 
		LET l_rec_statorder.area_code = l_rec_statdetl.area_code 
		LET l_rec_statorder.cond_code = l_rec_statdetl.cond_code 
		LET l_rec_statorder.ord_num = l_rec_statdetl.order_num 
		PUT c_statorder 
		
	COMMIT WORK 
	RETURN TRUE 
	LABEL recovery: 
	ROLLBACK WORK 
	RETURN FALSE 
	WHENEVER ERROR stop 
END FUNCTION 
###########################################################################
# END FUNCTION insert_data(p_rowid)
###########################################################################


###########################################################################
# FUNCTION disp_status(p_stg_num,p_type_ind,p_text) 
#
# 
###########################################################################
FUNCTION disp_status(p_stg_num,p_type_ind,p_text) 
	DEFINE p_stg_num INTEGER 
	DEFINE p_type_ind char(1) 
	DEFINE p_text char(14) 

	IF NOT glob_backgrnd THEN 
		IF p_type_ind = "I" THEN 
			DISPLAY p_text TO sr_updstatus[p_stg_num].start_date 

		ELSE 
			DISPLAY p_text TO sr_updstatus[p_stg_num].tran_text 

		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION disp_status(p_stg_num,p_type_ind,p_text) 
###########################################################################


###########################################################################
# FUNCTION disp_statinfo() 
#
# 
###########################################################################
FUNCTION disp_statinfo() 
	DEFINE l_arr_rec_statint array[5] OF RECORD LIKE statint.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_invcnt_qty INTEGER 
	DEFINE l_credcnt_qty INTEGER 
	DEFINE i INTEGER 

	SELECT * INTO l_arr_rec_statint[1].* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.day_type_code 
	AND start_date <= today 
	AND end_date >= today 
	
	SELECT * INTO l_arr_rec_statint[2].* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.week_type_code 
	AND start_date <= today 
	AND end_date >= today 
	
	SELECT * INTO l_arr_rec_statint[3].* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.mth_type_code 
	AND start_date <= today 
	AND end_date >= today 
	
	SELECT * INTO l_arr_rec_statint[4].* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.qtr_type_code 
	AND start_date <= today 
	AND end_date >= today 
	
	SELECT * INTO l_arr_rec_statint[5].* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.year_type_code 
	AND start_date <= today 
	AND end_date >= today 
	DECLARE c2_statint cursor FOR 
	
	SELECT * FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_statparms.mth_type_code 
	AND end_date <= today 
	AND dist_flag = "Y" 
	
	ORDER BY start_date 
	OPEN c2_statint 
	FOR i = 1 TO 5 
		IF l_arr_rec_statint[i].int_text IS NULL THEN 
			LET l_arr_rec_statint[i].int_text = "******" 
		END IF 
		CASE i 
			WHEN "1" LET glob_rec_statparms.day_num = l_arr_rec_statint[i].int_num 
			WHEN "2" LET glob_rec_statparms.week_num = l_arr_rec_statint[i].int_num 
			WHEN "3" LET glob_rec_statparms.mth_num = l_arr_rec_statint[i].int_num 
			WHEN "4" LET glob_rec_statparms.qtr_num = l_arr_rec_statint[i].int_num 
			WHEN "5" LET glob_rec_statparms.year_num = l_arr_rec_statint[i].year_num 
		END CASE 
		## DISPLAY intervals requiring distributions
		FETCH c2_statint INTO l_rec_statint.* 
		IF status = 0 THEN 
			DISPLAY l_rec_statint.int_text TO sr_statint[i].* 

		END IF 
	END FOR 
	
	IF glob_rec_statparms.year_num IS NULL OR glob_rec_statparms.year_num = 0 THEN 
		LET glob_rec_statparms.year_num = year(today) 
	END IF 
	
	DISPLAY l_arr_rec_statint[1].int_text, 
	l_arr_rec_statint[2].int_text, 
	l_arr_rec_statint[3].int_text, 
	l_arr_rec_statint[4].int_text, 
	l_arr_rec_statint[5].int_text 
	TO day_text, 
	wk_text, 
	mth_text, 
	qtr_text, 
	yr_text 

	SELECT count(*) INTO l_invcnt_qty FROM stattrig 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = TRAN_TYPE_INVOICE_IN 
	IF l_invcnt_qty IS NULL THEN 
		LET l_invcnt_qty = 0 
	END IF 
	SELECT count(*) INTO l_credcnt_qty FROM stattrig 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
	IF l_credcnt_qty IS NULL THEN 
		LET l_credcnt_qty = 0 
	END IF 
	DISPLAY BY NAME glob_rec_statparms.last_upd_date, 
	glob_rec_statparms.last_dist_date, 
	l_invcnt_qty, 
	l_credcnt_qty 

	SELECT unique 1 FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND dist_flag = "Y" 
	AND type_code = glob_rec_statparms.mth_type_code 
	AND end_date <= today 
	IF status = 0 THEN 
		LET glob_dist_flag = "Y" 
	ELSE 
		LET glob_dist_flag = "N" 
	END IF 
	DISPLAY BY NAME glob_dist_flag 

END FUNCTION 
###########################################################################
# END FUNCTION disp_statinfo() 
###########################################################################


###########################################################################
# REPORT ES1_rpt_list(p_err_ind,p_ref_num,p_ref_text) 
#
# FOR triggers:       ref_num = trans_num
#                     ref_text= trans_type
# FOR intervals:      ref_num = year_num
#                     ref_text= int_text
# FOR distributions:  ref_num = year_num
#   
###########################################################################
REPORT ES1_rpt_list(p_rpt_idx,p_err_ind,p_ref_num,p_ref_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_err_ind char(1) 
	DEFINE p_ref_num INTEGER 
	DEFINE p_ref_text char(10) 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_line1 char(80)
	DEFINE l_line2 char(80)
--	DEFINE l_col INTEGER 

	OUTPUT 

	ORDER BY p_err_ind, 
	p_ref_num, 
	p_ref_text 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_err_ind 
			PRINT 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 1, "MIS Update Status Report - "; 
			CASE p_err_ind 
				WHEN "1" 
					PRINT COLUMN 28, "Transactions Update successful" 
				WHEN "2" 
					PRINT COLUMN 28, "Transactions Update failed" 
				WHEN "3" 
					PRINT COLUMN 28, "Interval Update successful" 
				WHEN "4" 
					PRINT COLUMN 28, "Interval Update failed" 
				WHEN "5" 
					PRINT COLUMN 28, "Distribution Update successful" 
				WHEN "6" 
					PRINT COLUMN 28, "Distribution Update failed" 
			END CASE 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------" 

		ON EVERY ROW 
			PRINT COLUMN 10, p_ref_text, 
			COLUMN 20, p_ref_num 

		ON LAST ROW 
			SKIP 1 line 
			SKIP 1 line			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
###########################################################################
# END REPORT ES1_rpt_list(p_err_ind,p_ref_num,p_ref_text) 
###########################################################################


###########################################################################
# FUNCTION mod_indices(p_stat_ind,p_mode)  
#
## This FUNCTION contains all database index AND table modification
## that are done in the statistics post process.  All are FOR
## efficiency purposes
###########################################################################
FUNCTION mod_indices(p_stat_ind,p_mode) 
	DEFINE p_stat_ind char(1) 
	DEFINE p_mode char(5) 
	DEFINE l_start_date DATE
	DEFINE l_end_date DATE 

	WHENEVER ERROR CONTINUE 
	CASE p_stat_ind 

		WHEN "T" ### transaction posting 
			IF p_mode = "START" THEN 
				CALL drop_index("statorder") 
			ELSE 
				CREATE INDEX statorder1_key ON statorder(trans_date,cmpy_code) 
				CREATE INDEX statorder2_key ON statorder(cust_code,cmpy_code) 
				CREATE INDEX statorder3_key ON statorder(area_code,trans_date) 
				CREATE INDEX statorder4_key ON statorder(mgr_code,trans_date) 
			END IF 

		WHEN "I" ### INTERVAL posting 
			IF p_mode = "START" THEN 
				CREATE INDEX customer3_key ON customer(sale_code) 
				CREATE INDEX customer4_key ON customer(territory_code) 
			ELSE 
				DROP INDEX customer3_key 
				DROP INDEX customer4_key 
				CALL drop_index("statorder") 
			END IF 

		WHEN "D" ### distribution posting 
			IF p_mode = "START" THEN 
			ELSE 
			END IF 
	END CASE 
	
	WHENEVER ERROR stop 
END FUNCTION 
###########################################################################
# END FUNCTION mod_indices(p_stat_ind,p_mode)  
###########################################################################


###########################################################################
# FUNCTION drop_index(p_table_name) 
#
# 
###########################################################################
FUNCTION drop_index(p_table_name) 
	DEFINE p_table_name char(20) 
	DEFINE l_idx_text char(20) 
	DEFINE l_query_text char(50) 
	DEFINE l_tabid INTEGER 

	SELECT tabid INTO l_tabid FROM systables 
	WHERE tabname = p_table_name 
	DECLARE c_sysindexes cursor FOR 
	SELECT idxname FROM sysindexes 
	WHERE tabid = l_tabid 
	FOREACH c_sysindexes INTO l_idx_text 
		LET l_query_text = "drop index ",l_idx_text 
		PREPARE x_index FROM l_query_text 
		EXECUTE x_index 
	END FOREACH 
END FUNCTION 
###########################################################################
# END FUNCTION drop_index(p_table_name) 
###########################################################################