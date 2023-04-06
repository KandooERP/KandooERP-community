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
GLOBALS "../eo/E55_GLOBALS.4gl"
###########################################################################
# FUNCTION E55_main()
#
# E55 - Scanning shipment FOR printing shipping labels
#               Provides front END TO E55_rpt_list_print_labels (E55a.4gl).
###########################################################################
FUNCTION E55_main() 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_temp_text char(30) 
	DEFINE i SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E55") 
	CALL init_E5_GROUP()
	
	OPEN WINDOW E156 with FORM "E156" 
	 CALL windecoration_e("E156") -- albo kd-755 

	DECLARE c_despatchhead cursor FOR 
	SELECT * FROM despatchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY despatch_date desc, ware_code,	carrier_code,	manifest_num desc
	 
	OPEN c_despatchhead 
	FOR i = 1 TO 13 
		FETCH c_despatchhead INTO l_rec_despatchhead.* 
		IF sqlca.sqlcode = 0 THEN 
			SELECT name_text INTO l_temp_text 
			FROM carrier 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_despatchhead.carrier_code 
			DISPLAY 
				"", 
				l_rec_despatchhead.despatch_date, 
				l_rec_despatchhead.ware_code, 
				l_rec_despatchhead.carrier_code, 
				l_temp_text, 
				l_rec_despatchhead.manifest_num 
			TO sr_despatchhead[i].* 

		END IF 
	END FOR 

	MENU " Shipping labels" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","E55","menu-Shipping_Labels-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Scroll" " Scroll through selected shipments" 
			SELECT count(*) 
			INTO i FROM despatchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF i < 30 THEN 
				CALL scan_shipments("1=1") 
			ELSE 
				CALL scan_shipments(select_shipments()) 
			END IF 
			NEXT option "PRINT MANAGER" 

		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print"    " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW E156 
END FUNCTION 
###########################################################################
# END FUNCTION E55_main()
###########################################################################


###########################################################################
# FUNCTION select_shipments()
#
# E55 - Scanning shipment FOR printing shipping labels
#               Provides front END TO E55_rpt_list_print_labels (E55a.4gl).
###########################################################################
FUNCTION select_shipments() 
	DEFINE where_text char(200) 

	CLEAR FORM 
	MESSAGE kandoomsg2("E",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME where_text ON 
		despatch_date, 
		ware_code, 
		carrier_code, 
		manifest_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E55","construct-despatch_date-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_shipments()
###########################################################################


###########################################################################
# FUNCTION scan_shipments(p_where_text)
#
# 
###########################################################################
FUNCTION scan_shipments(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_query_text STRING 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_arr_rec_despatchhead DYNAMIC ARRAY OF RECORD  
		scroll_flag char(1), 
		despatch_date LIKE despatchhead.despatch_date, 
		ware_code LIKE despatchhead.ware_code, 
		carrier_code LIKE despatchhead.carrier_code, 
		name_text LIKE carrier.name_text, 
		manifest_num LIKE despatchhead.manifest_num 
	END RECORD 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_scroll_flag char(1) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_tmp_str STRING

	IF p_where_text IS NULL THEN 
		RETURN 
	END IF 
	MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "

	LET l_query_text = "SELECT * ", 
	"FROM despatchhead ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY despatch_date desc,", 
	"ware_code,", 
	"carrier_code,", 
	"manifest_num desc" 
	LET l_idx = 0 
	PREPARE s_despatchhead FROM l_query_text 
	DECLARE c1_despatchhead cursor FOR s_despatchhead 

	FOREACH c1_despatchhead INTO l_rec_despatchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_despatchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_despatchhead[l_idx].despatch_date = l_rec_despatchhead.despatch_date 
		LET l_arr_rec_despatchhead[l_idx].ware_code = l_rec_despatchhead.ware_code 
		LET l_arr_rec_despatchhead[l_idx].carrier_code = l_rec_despatchhead.carrier_code 

		SELECT name_text 
		INTO l_arr_rec_despatchhead[l_idx].name_text 
		FROM carrier 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND carrier_code = l_rec_despatchhead.carrier_code 

		LET l_arr_rec_despatchhead[l_idx].manifest_num = l_rec_despatchhead.manifest_num 

	END FOREACH 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9128,"")		#9128 No shipments satisfied selection criteria "
	ELSE 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		CALL set_count(l_idx) 
		MESSAGE kandoomsg2("E",1037,"") 	#1037 RETURN on line TO View - F9 TO Print labels
		INPUT ARRAY l_arr_rec_despatchhead WITHOUT DEFAULTS FROM sr_despatchhead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E55","input-arr-l_arr_rec_despatchhead-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 

				LET l_scroll_flag = l_arr_rec_despatchhead[l_idx].scroll_flag 
				
			AFTER FIELD scroll_flag 
				LET l_arr_rec_despatchhead[l_idx].scroll_flag = l_scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD despatch_date 
				OPEN WINDOW E159 with FORM "E159" 
				 CALL windecoration_e("E159") -- albo kd-755 
				SELECT * INTO l_rec_despatchhead.* 
				FROM despatchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_arr_rec_despatchhead[l_idx].carrier_code 
				AND manifest_num = l_arr_rec_despatchhead[l_idx].manifest_num 
				SELECT * 
				INTO l_rec_warehouse.* 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_despatchhead.ware_code 
				SELECT * 
				INTO l_rec_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_despatchhead.carrier_code
				 
				DISPLAY BY NAME l_rec_despatchhead.carrier_code, 
				l_rec_carrier.name_text, 
				l_rec_despatchhead.ware_code, 
				l_rec_warehouse.desc_text, 
				l_rec_despatchhead.manifest_num, 
				l_rec_despatchhead.com1_text, 
				l_rec_despatchhead.com2_text, 
				l_rec_despatchhead.despatch_date, 
				l_rec_despatchhead.despatch_time, 
				l_rec_despatchhead.amend_code 

				SELECT count(*) 
				INTO i FROM despatchdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_arr_rec_despatchhead[l_idx].carrier_code 
				AND manifest_num = l_arr_rec_despatchhead[l_idx].manifest_num 
				IF i < 30 THEN 
					CALL scan_despatchdetails("1=1",l_rec_despatchhead.*) 
				ELSE 
					CALL scan_despatchdetails(select_despatchdetails(),l_rec_despatchhead.*) 
				END IF 
				CLOSE WINDOW E159 
				NEXT FIELD scroll_flag 

			ON KEY (f9) 
				MESSAGE kandoomsg2("E",1041,"") 	# 1041 Printing shipping labels - Please Wait

				LET p_where_text = 
				"carrier_code = \"",l_arr_rec_despatchhead[l_idx].carrier_code,"\" ", 
				"AND manifest_num = \"",l_arr_rec_despatchhead[l_idx].manifest_num,"\" "

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"E55_rpt_list_print_labels",p_where_text, RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				LET l_tmp_str = l_arr_rec_despatchhead[l_idx].ware_code, " - Carrier: ",l_arr_rec_despatchhead[l_idx].carrier_code
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)

				START REPORT E55_rpt_list_print_labels TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------


				#---------------------------------------------------------
				OUTPUT TO REPORT E55_rpt_list_print_labels(l_rpt_idx,
				glob_rec_kandoouser.cmpy_code,
				glob_rec_kandoouser.sign_on_code,
				p_where_text) 
				#---------------------------------------------------------		

##################################################
# Not sure why there is so much code regarding the page number
# needs more investigation
#				SELECT sum(despatch_qty) 
#				INTO rpt_pageno 
#				FROM despatchdetl 
#				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
#				AND carrier_code = l_arr_rec_despatchhead[l_idx].carrier_code 
#				AND manifest_num = l_arr_rec_despatchhead[l_idx].manifest_num 
#
#				IF rpt_pageno IS NULL THEN 
#					LET rpt_pageno = 0 
#				END IF 
#				#Calculate rpt_pageno by dividing number of labels by 2
#				LET rpt_pageno = (rpt_pageno / 2) + 1 
#				CALL upd_reports(l_output,rpt_pageno,rpt_width,rpt_length) 
##################################################

				#------------------------------------------------------------
				FINISH REPORT E55_rpt_list_print_labels
				CALL rpt_finish("E55_rpt_list_print_labels")
				#------------------------------------------------------------

--				MESSAGE kandoomsg2("E",1037,"") 		#1037 RETURN on line TO View - F9 TO Print labels

		END INPUT
		 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION scan_shipments(p_where_text)
###########################################################################


###########################################################################
# FUNCTION select_despatchdetails() 
#
# 
###########################################################################
FUNCTION select_despatchdetails() 
	DEFINE where_text char(300) 

	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME where_text ON 
		invoice_num, 
		despatch_code, 
		despatch_qty 
	
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E55","construct-invoice_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN where_text 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION scan_despatchdetails(p_where_text,p_rec_despatchhead)  
#
# 
###########################################################################
FUNCTION scan_despatchdetails(p_where_text,p_rec_despatchhead) 
	DEFINE p_where_text STRING
	DEFINE p_rec_despatchhead RECORD LIKE despatchhead.*
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
 	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_arr_rec_despatchdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		invoice_num LIKE despatchdetl.invoice_num, 
		despatch_code LIKE despatchdetl.despatch_code, 
		nett_wgt_qty LIKE despatchdetl.nett_wgt_qty, 
		gross_wgt_qty LIKE despatchdetl.gross_wgt_qty, 
		nett_cubic_qty LIKE despatchdetl.nett_cubic_qty, 
		gross_cubic_qty LIKE despatchdetl.gross_cubic_qty, 
		despatch_qty LIKE despatchdetl.despatch_qty 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_prt_qty SMALLINT
	DEFINE l_inv_qty SMALLINT
	DEFINE l_tmp_str STRING
	
	IF p_where_text IS NULL THEN 
		RETURN 
	END IF
	 
	LET l_prt_qty = 0 
	MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "
	
	LET l_query_text = 
	"SELECT * ", 
	"FROM despatchdetl ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND carrier_code = \"",p_rec_despatchhead.carrier_code,"\" ", 
	"AND manifest_num = \"",p_rec_despatchhead.manifest_num,"\" ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY invoice_num, despatch_code" 
	PREPARE s_despatchdetl FROM l_query_text 
	DECLARE c_despatchdetl cursor FOR s_despatchdetl 

	LET l_idx = 0 
	FOREACH c_despatchdetl INTO l_rec_despatchdetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_despatchdetl[l_idx].scroll_flag = NULL 
		LET l_arr_rec_despatchdetl[l_idx].invoice_num = l_rec_despatchdetl.invoice_num 
		LET l_arr_rec_despatchdetl[l_idx].despatch_code = l_rec_despatchdetl.despatch_code 
		LET l_arr_rec_despatchdetl[l_idx].nett_wgt_qty = l_rec_despatchdetl.nett_wgt_qty 
		LET l_arr_rec_despatchdetl[l_idx].gross_wgt_qty = l_rec_despatchdetl.gross_wgt_qty 
		LET l_arr_rec_despatchdetl[l_idx].nett_cubic_qty = l_rec_despatchdetl.nett_cubic_qty 
		LET l_arr_rec_despatchdetl[l_idx].gross_cubic_qty = l_rec_despatchdetl.gross_cubic_qty 
		LET l_arr_rec_despatchdetl[l_idx].despatch_qty = l_rec_despatchdetl.despatch_qty 
 
	END FOREACH 
 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9142,"") 	#9142 No invoices satisfied selection criteria "
	ELSE 
		MESSAGE kandoomsg2("E",1038,"") 	#1038 RETURN TO alter label quantity - F9 TO tag FOR printing
	END IF 
	
	OPTIONS 
		DELETE KEY f36, 	
		INSERT KEY f36
		 
	INPUT ARRAY l_arr_rec_despatchdetl WITHOUT DEFAULTS FROM sr_despatchdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E55","input-arr-l_arr_rec_despatchdetl-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 

			LET l_scroll_flag = l_arr_rec_despatchdetl[l_idx].scroll_flag 
			
		AFTER FIELD scroll_flag 
			LET l_arr_rec_despatchdetl[l_idx].scroll_flag = l_scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF (l_arr_rec_despatchdetl[l_idx+1].invoice_num IS NULL AND 
				l_arr_rec_despatchdetl[l_idx+1].despatch_code IS NULL ) 
				OR arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 		# 9001 There are no more rows in the direction you are going
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			
		AFTER FIELD despatch_qty 
			IF l_arr_rec_despatchdetl[l_idx].despatch_qty IS NULL THEN 
				ERROR kandoomsg2("E",9133,"") 				#9133 Quantity must be entered
				NEXT FIELD despatch_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].despatch_qty < 0 THEN 
				ERROR kandoomsg2("E",9134,"") #9134 Quantity may NOT be negative
				NEXT FIELD despatch_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx+1].invoice_num IS NULL 
			OR arr_curr() >= arr_count() THEN 
				NEXT FIELD scroll_flag 
			END IF 

		ON KEY (f9) 
			IF l_arr_rec_despatchdetl[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_despatchdetl[l_idx].scroll_flag = "*" 
				LET l_prt_qty = l_prt_qty + l_arr_rec_despatchdetl[l_idx].despatch_qty 
				LET l_inv_qty = l_inv_qty + 1 
			ELSE 
				LET l_arr_rec_despatchdetl[l_idx].scroll_flag = NULL 
				LET l_prt_qty = l_prt_qty - l_arr_rec_despatchdetl[l_idx].despatch_qty 
				LET l_inv_qty = l_inv_qty - 1 
			END IF 
			NEXT FIELD scroll_flag 

	END INPUT 
	
	IF not(int_flag OR quit_flag) THEN 
		FOR l_idx = 1 TO arr_count() 
			UPDATE despatchdetl 
			SET despatch_qty = l_arr_rec_despatchdetl[l_idx].despatch_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = p_rec_despatchhead.carrier_code 
			AND manifest_num = p_rec_despatchhead.manifest_num 
			#AND invoice_num = l_arr_rec_despatchdetl[l_idx].invoice_num
			AND despatch_code = l_arr_rec_despatchdetl[l_idx].despatch_code 
		END FOR 
		
		IF l_inv_qty != 0 THEN 
			IF promptTF("PRINT shipping label(s)",kandoomsg2("A",8005,""),1) THEN  #8005 Confirmation TO PRINT shipping label(s)? (Y/N)"
				IF l_inv_qty > 1 THEN 
					LET glob_rec_rpt_selector.rpt_note = 
					"EO - Shipping labels FOR selected invoices",	" - Carrier: ",p_rec_despatchhead.carrier_code
					LET glob_rec_rpt_selector.rpt_header = glob_rec_rpt_selector.rpt_note
				ELSE 
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_despatchdetl[l_idx].scroll_flag = "*" THEN 
							EXIT FOR 
						END IF 
					END FOR 

					#LET l_rpt_note = 
					#"EO - Shipping labels FOR invoice: ", 
					#l_arr_rec_despatchdetl[l_idx].invoice_num, 
					#" - Carrier: ",p_rec_despatchhead.carrier_code 
				END IF 

				LET p_where_text = 
				"carrier_code = \"",p_rec_despatchhead.carrier_code,"\" ", 
				"AND manifest_num = \"",p_rec_despatchhead.manifest_num,"\" "

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start(getmoduleid(),"E55_rpt_list_print_labels",p_where_text, RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	

				--LET l_rpt_note = 
				--"EO - Shipping labels FOR invoice: ", 
				--l_arr_rec_despatchdetl[l_idx].invoice_num, 
				--" - Carrier: ",p_rec_despatchhead.carrier_code 
				LET l_tmp_str = p_rec_despatchhead.ware_code , " - Carrier: ",p_rec_despatchhead.carrier_code
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)

				START REPORT E55_rpt_list_print_labels TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				 
 
				LET p_where_text = p_where_text clipped, "AND despatch_code in ("
				 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_despatchdetl[l_idx].scroll_flag = "*" THEN 
						LET p_where_text = p_where_text clipped, 
						"'", 
						l_arr_rec_despatchdetl[l_idx].despatch_code clipped, 
						"'", 
						", " 
					END IF 
				END FOR 
				
				LET i = length(p_where_text) 
				LET p_where_text[i,i] = ")" 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT E55_rpt_list_print_labels(l_rpt_idx,
				glob_rec_kandoouser.cmpy_code,
				glob_rec_kandoouser.sign_on_code,
				p_where_text) 
				#---------------------------------------------------------		
				
#				#Calculate rpt_pageno by dividing number of labels by 2
#				LET rpt_pageno = (l_prt_qty / 2) + 1 

				#------------------------------------------------------------
				FINISH REPORT E55_rpt_list_print_labels
				CALL rpt_finish("E55_rpt_list_print_labels")
				#------------------------------------------------------------

				LET l_prt_qty = 0 
			END IF 
		END IF 

	ELSE 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

END FUNCTION
###########################################################################
# END FUNCTION select_despatchdetails() 
###########################################################################