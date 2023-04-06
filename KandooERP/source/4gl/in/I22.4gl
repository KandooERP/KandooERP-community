{
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

	Source code beautified by beautify.pl on 2020-01-03 09:12:24	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "I22_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I22 which allows the user TO issue items FROM inventory

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
-- GLOBALS "I22_GLOBALS.4gl" no globals justified

	DEFINE pr_product RECORD LIKE product.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodadjtype RECORD LIKE prodadjtype.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_company RECORD LIKE company.*, 
	pr_coa RECORD LIKE coa.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pa_stockissue DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code,
		source_code LIKE prodledg.source_code,
		source_text LIKE prodledg.source_text, 
		tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.sell_uom_code, 
		cost_amt LIKE prodledg.cost_amt 
	END RECORD, 
	pr_stockissue RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		source_text LIKE prodledg.source_text, 
		tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.sell_uom_code, 
		cost_amt LIKE prodledg.cost_amt 
	END RECORD, 
	pa_stockother DYNAMIC ARRAY OF RECORD 
		part_desc_text LIKE product.desc_text,
		source_code LIKE prodledg.source_code,
		source_type LIKE prodledg.source_type,
		source_desc_text LIKE prodledg.desc_text, 
		acct_code LIKE prodledg.acct_code, 
		coa_desc_text LIKE coa.desc_text, 
		note_entry SMALLINT 
	END RECORD, 
	pr_stockother RECORD 
		part_desc_text LIKE product.desc_text, 
		source_code LIKE prodledg.source_code,
		source_type LIKE prodledg.source_type,
		source_desc_text LIKE prodledg.desc_text, 
		acct_code LIKE prodledg.acct_code, 
		coa_desc_text LIKE coa.desc_text, 
		note_entry SMALLINT 
	END RECORD, 
	issue_text CHAR(8), 
	pr_wind_text CHAR(200), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	failed_it, bacheq_code SMALLINT, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_wid LIKE rmsreps.report_text, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 


	pr_tran_date LIKE prodledg.tran_date, 
	pr_source_num LIKE prodledg.source_num, 
	pr_year_num LIKE prodledg.year_num, 
	pr_period_num LIKE prodledg.period_num, 
	pr_continue, pr_first_time SMALLINT, 
	pr_bypass_menu char(1) # bypasses ring MENU IF user answers "N" 

MAIN 
	DEFINE 
	pr_saved_batch CHAR(1), pr_add_mode, 
	idx, scrn , pr_array_counter SMALLINT 

	#Initial UI Init
	CALL setModuleId("I22") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I",9002,"") 
		#9002 Inventory parameters missing, use IZP
		EXIT program 
	END IF 
	OPEN WINDOW i182 with FORM "I182" 
	 CALL windecoration_i("I182") -- albo kd-758 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, "", "0", "") 
	LET pr_tran_date = today 
	LET pr_source_num = 0 
	LET pr_year_num = NULL 
	LET pr_period_num = NULL 
	LET pr_saved_batch = "N" 
	LET pr_first_time = true 
	FOR pr_array_counter = 1 TO 1000 
		INITIALIZE pa_stockissue[pr_array_counter].* TO NULL 
	END FOR 
	LET pr_array_counter = 1 
	WHILE header() 
		IF line_entry(pr_array_counter, pr_add_mode) THEN 
			IF pr_bypass_menu = "N" THEN 
				LET pr_array_counter = arr_count() 
				LET pr_first_time = false 
				LET pr_continue = false 
				--            OPEN WINDOW wI182 AT 10,21 with 2 rows, 40 columns  -- albo  KD-758
				--               ATTRIBUTE(border)
				IF pr_saved_batch = "N" THEN 
					MENU " Issues" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","I22","menu-Issues-1") -- albo kd-505 
						ON ACTION "WEB-HELP" -- albo kd-372 
							CALL onlinehelp(getmoduleid(),null) 
						COMMAND "Save" " Save batch details TO database" 
							LET pr_saved_batch = "Y" 
							CALL save_details() 
							MENU " Issues" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","I22","menu-Issues-2") -- albo kd-505 
								ON ACTION "WEB-HELP" -- albo kd-372 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND KEY ("P",f11) "Print" " Print batch details" 
									CALL print_issues() 
									NEXT option "Exit" 
								COMMAND KEY(interrupt,"E")"Exit" " EXIT MENU" 
									EXIT MENU 
								COMMAND KEY (control-w) 
									CALL kandoohelp("") 
							END MENU 
							LET int_flag = true 
							EXIT MENU 
						COMMAND KEY(interrupt,"M")"Modify" " Modify batch details" 
							LET pr_continue = true 
							EXIT MENU 
						COMMAND KEY (control-w) 
							CALL kandoohelp("") 
					END MENU 
				END IF 
				--            CLOSE WINDOW wI182  -- albo  KD-758
				IF pr_continue THEN 
					CONTINUE WHILE 
				END IF 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
	END WHILE 
	--   CLOSE WINDOW I182  -- albo  KD-758
END MAIN 

FUNCTION print_issues()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
	DEFINE 
	pr_output CHAR(20), 
	pr_counter SMALLINT 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"I22_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT I22_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOR pr_counter = 1 TO arr_count() 
		IF pa_stockissue[pr_counter].part_code IS NULL THEN 
			CONTINUE FOR 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT I22_rpt_list(l_rpt_idx,pr_counter)
		#---------------------------------------------------------				 
	END FOR 

	#------------------------------------------------------------
	FINISH REPORT I22_rpt_list
	CALL rpt_finish("I22_rpt_list")
	#------------------------------------------------------------

END FUNCTION 



FUNCTION line_entry(pr_array_counter, pr_add_mode) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_array_counter, pr_add_mode SMALLINT, 
	pr_counter, pr_lastkey SMALLINT, 
	trial,idx, scrn SMALLINT, 
	pr_cnt SMALLINT 

	IF pr_first_time THEN 
		INITIALIZE pa_stockissue[1].* TO NULL 
		INITIALIZE pa_stockother[1].* TO NULL 
		LET pr_first_time = false 
		LET pr_add_mode = true 
		LET pr_array_counter = 1 
	END IF 
	LET pr_array_counter = pr_array_counter + 1 
	CALL set_count(pr_array_counter) 
	LET msgresp = kandoomsg("I",1049,"") 
	#1020 F1 TO Add;  F2 TO Delete;  ENTER on Line TO Edit;  F8 Stock Available.
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	INPUT ARRAY pa_stockissue WITHOUT DEFAULTS FROM sr_stockissue.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I22","input-pa_stockissue-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE DELETE 
			# dont delete records AFTER attempt TO reeneter prod/ware
			IF pr_cnt > 0 THEN 
				CALL serial_delete(pa_stockissue[idx].part_code, 
				pa_stockissue[idx].ware_code) 
			END IF 
			FOR idx = arr_curr() TO arr_count() 
				LET pa_stockother[idx].* 
				= pa_stockother[idx+1].* 
			END FOR 
			INITIALIZE pa_stockother[idx].* TO NULL 
			LET idx = arr_curr() 
			CALL display_stockother(idx) 

		BEFORE INSERT 
			IF fgl_lastkey() = fgl_keyval("delete") 
			OR trial 
			OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
				LET trial = false 
				NEXT FIELD scroll_flag 
			END IF 
			FOR idx = arr_count() TO arr_curr() step -1 
				LET pa_stockother[idx+1].* 
				= pa_stockother[idx].* 
			END FOR 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pa_stockother[idx].note_entry = false 
			INITIALIZE pa_stockother[idx].* TO NULL 
			INITIALIZE pr_stockissue.* TO NULL 
			INITIALIZE pr_stockother.* TO NULL 
			LET issue_text = "Issue" 
			CALL display_stockother(idx) 
			LET pr_add_mode = true 
			#NEXT FIELD part_code
		ON KEY (F8) 
			IF pa_stockissue[idx].part_code IS NOT NULL THEN 
				CALL prsswind(glob_rec_kandoouser.cmpy_code,pa_stockissue[idx].part_code) 
			END IF 
			IF NOT infield(scroll_flag) THEN 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
			END IF 
		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_wind_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF pr_wind_text IS NOT NULL THEN 
						LET pa_stockissue[idx].part_code = pr_wind_text 
						DISPLAY pa_stockissue[idx].part_code 
						TO prodstatus.part_code 

					END IF 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
					NEXT FIELD part_code 
				WHEN infield (ware_code) 
					LET pr_wind_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF pr_wind_text IS NOT NULL THEN 
						LET pa_stockissue[idx].ware_code = pr_wind_text 
						DISPLAY pa_stockissue[idx].ware_code 
						TO prodstatus.ware_code 

					END IF 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
					NEXT FIELD ware_code 
				WHEN infield (source_code) 
					IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
						LET pr_wind_text = show_adj_type_code(glob_rec_kandoouser.cmpy_code) 
						IF pr_wind_text IS NOT NULL THEN 
							LET pa_stockissue[idx].source_code 
							= pr_wind_text clipped 
							SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
							WHERE source_code = pa_stockissue[idx].source_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET pa_stockother[idx].source_type = "PADJ"			#the source is a product adjustement
							LET pa_stockother[idx].source_desc_text 
							= pr_prodadjtype.desc_text 
							LET pa_stockother[idx].acct_code 
							= pr_prodadjtype.adj_acct_code 
							DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

							CALL display_stockother(idx) 
						END IF 
						OPTIONS INSERT KEY f36, 
						DELETE KEY f36 
						NEXT FIELD source_code 
					END IF 
			END CASE 
		BEFORE ROW 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_stockissue.* = pa_stockissue[idx].* 
			LET pr_stockother.* = pa_stockother[idx].* 
			IF pr_add_mode THEN 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				NEXT FIELD part_code 
			ELSE 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
			END IF 
			IF fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") THEN 
				DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

				CALL display_stockother(idx) 
				NEXT FIELD part_code 
			END IF 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

			CALL display_stockother(idx) 
		AFTER FIELD scroll_flag 
			LET pa_stockissue[idx].scroll_flag = NULL 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

			CALL display_stockother(idx) 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_stockissue[idx].part_code IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF trial THEN 
				LET trial = false 
			END IF 
		BEFORE FIELD part_code 
			LET pr_part_code = pa_stockissue[idx].part_code 
			IF idx > 1 
			AND pa_stockissue[idx].ware_code IS NULL THEN 
				LET pa_stockissue[idx].ware_code = pa_stockissue[idx-1].ware_code 
			END IF 
			IF idx > 1 AND pa_stockissue[idx].part_code IS NULL THEN 
				LET pa_stockissue[idx].source_code=pa_stockissue[idx-1].source_code 
			END IF 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

			# disable the F1 - Insert key AND F2 - Delete key
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		AFTER FIELD part_code 
			IF pa_stockissue[idx].part_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD part_code 
			END IF 
			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = pa_stockissue[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				#9010 Product NOT found - Try Window
				NEXT FIELD part_code 
			END IF 
			IF pr_product.status_ind = "2" THEN 
				#8022 Product IS put on hold - Continue (Y/N)?
				IF kandoomsg("I",8022,"") = "N" THEN 
					NEXT FIELD part_code 
				END IF 
			END IF 
			IF pr_product.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9511,"") 
				#9511 This product has been deleted
				NEXT FIELD part_code 
			END IF 
			# check that enough segments have been entered.
			IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, 
			pa_stockissue[idx].part_code, 
			1) THEN 
				LET msgresp = kandoomsg("I",9536,"") 
				#9536 Must enter up TO Stock receipting segment
				NEXT FIELD part_code 
			END IF 
			LET pa_stockissue[idx].sell_uom_code = pr_product.sell_uom_code 
			IF (pr_stockother.note_entry = true) THEN 
				LET pa_stockother[idx].part_desc_text=pr_stockother.part_desc_text 
			ELSE 
				LET pa_stockother[idx].part_desc_text=pr_product.desc_text 
			END IF 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

			CALL display_stockother(idx) 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE part_code = pa_stockissue[idx].part_code 
				AND ware_code = pa_stockissue[idx].ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9104,"") 
					#9104 Product IS NOT stocked AT this warehouse
					NEXT FIELD ware_code 
				END IF 
				IF pr_prodstatus.status_ind = "2" THEN 
					#8022 Product IS in this warhouse put on hold - Continue (Y/N)?
					IF kandoomsg("I",8024,"") = "N" THEN 
						NEXT FIELD part_code 
					END IF 
				END IF 
				IF pr_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9510,"") 
					#9510 Product does NOT exist AT this warehouse
					NEXT FIELD part_code 
				END IF 
				LET pa_stockissue[idx].cost_amt = pr_prodstatus.wgted_cost_amt 
				* pr_product.stk_sel_con_qty 
				DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

				IF pa_stockissue[idx].source_code IS NOT NULL 
				AND pa_stockother[idx].acct_code IS NULL THEN 
					INITIALIZE pr_prodadjtype.* TO NULL 
					SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
					WHERE source_code = pa_stockissue[idx].source_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
							LET msgresp = kandoomsg("U",9910,"") 
							#9910 RECORD NOT found
							NEXT FIELD source_code 
						END IF 
					END IF 
					LET pa_stockother[idx].acct_code = pr_prodadjtype.adj_acct_code 
					LET pa_stockother[idx].source_desc_text=pr_prodadjtype.desc_text 
					SELECT * INTO pr_coa.* FROM coa 
					WHERE acct_code = pa_stockother[idx].acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = 0 THEN 
						IF acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
							LET pa_stockother[idx].coa_desc_text = pr_coa.desc_text 
						ELSE 
							NEXT FIELD source_code 
						END IF 
					ELSE 
						LET pa_stockother[idx].coa_desc_text = NULL 
					END IF 
				END IF 
				CALL display_stockother(idx) 
				IF pa_stockissue[idx].ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD ware_code 
				END IF 
				IF pa_stockissue[idx].tran_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_qty 
				END IF 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9542,"") 
					#9542 GL Account NOT entered.
					NEXT FIELD part_code 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		AFTER FIELD ware_code 
			IF pa_stockissue[idx].ware_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD ware_code 
			END IF 
			SELECT * INTO pr_prodstatus.* FROM prodstatus 
			WHERE part_code = pa_stockissue[idx].part_code 
			AND ware_code = pa_stockissue[idx].ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9104,"") 
				#9104 Product IS NOT stocked AT this warehouse
				NEXT FIELD ware_code 
			END IF 
			IF pr_prodstatus.status_ind = "2" THEN 
				#8022 Product IS in this warhouse put on hold - Continue (Y/N)?
				IF kandoomsg("I",8024,"") = "N" THEN 
					NEXT FIELD part_code 
				END IF 
			END IF 
			IF pr_prodstatus.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9510,"") 
				#9510 Product does NOT exist AT this warehouse
				NEXT FIELD part_code 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_stockissue[idx].ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD ware_code 
				END IF 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE part_code = pa_stockissue[idx].part_code 
				AND ware_code = pa_stockissue[idx].ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9104,"") 
					#9104 Product IS NOT stocked AT this warehouse
					NEXT FIELD ware_code 
				END IF 
				IF pr_prodstatus.status_ind = "2" THEN 
					#8022 Product IS in this warhouse put on hold - Continue (Y/N)?
					IF kandoomsg("I",8024,"") = "N" THEN 
						NEXT FIELD part_code 
					END IF 
				END IF 
				IF pr_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9510,"") 
					#9510 Product does NOT exist AT this warehouse
					NEXT FIELD part_code 
				END IF 
				LET pa_stockissue[idx].cost_amt = pr_prodstatus.wgted_cost_amt 
				* pr_product.stk_sel_con_qty 
				DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD part_code 
				END IF 
				IF pa_stockissue[idx].source_code IS NOT NULL 
				AND pa_stockother[idx].acct_code IS NULL THEN 
					INITIALIZE pr_prodadjtype.* TO NULL 
					SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
					WHERE source_code = pa_stockissue[idx].source_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
							LET msgresp = kandoomsg("U",9910,"") 
							#9910 RECORD NOT found
							NEXT FIELD source_code 
						END IF 
					END IF 
					LET pa_stockother[idx].acct_code = pr_prodadjtype.adj_acct_code 
					LET pa_stockother[idx].source_desc_text=pr_prodadjtype.desc_text 
					SELECT * INTO pr_coa.* FROM coa 
					WHERE acct_code = pa_stockother[idx].acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = 0 THEN 
						IF acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
							LET pa_stockother[idx].coa_desc_text = pr_coa.desc_text 
						ELSE 
							NEXT FIELD source_code 
						END IF 
					ELSE 
						LET pa_stockother[idx].coa_desc_text = NULL 
					END IF 
				END IF 
				CALL display_stockother(idx) 
				IF pa_stockissue[idx].part_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD part_code 
				END IF 
				IF pa_stockissue[idx].tran_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_qty 
				END IF 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9542,"") 
					#9542 GL Account NOT entered.
					NEXT FIELD ware_code 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
			LET pa_stockissue[idx].cost_amt = pr_prodstatus.wgted_cost_amt 
			* pr_product.stk_sel_con_qty 
			DISPLAY pa_stockissue[idx].* TO sr_stockissue[scrn].* 

		AFTER FIELD source_code 
			IF pa_stockissue[idx].source_code IS NOT NULL THEN 
				INITIALIZE pr_prodadjtype.* TO NULL 
				SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
				WHERE source_code = pa_stockissue[idx].source_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
						LET msgresp = kandoomsg("U",9910,"") 
						#9910 RECORD NOT found
						NEXT FIELD source_code 
					END IF 
				ELSE 
					LET pa_stockother[idx].acct_code = pr_prodadjtype.adj_acct_code 
					LET pa_stockother[idx].source_desc_text=pr_prodadjtype.desc_text 
				END IF 
				SELECT * INTO pr_coa.* FROM coa 
				WHERE acct_code = pa_stockother[idx].acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = 0 THEN 
					IF acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						LET pa_stockother[idx].coa_desc_text = pr_coa.desc_text 
					ELSE 
						NEXT FIELD source_code 
					END IF 
				ELSE 
					LET pa_stockother[idx].coa_desc_text = NULL 
				END IF 
				CALL display_stockother(idx) 
			ELSE 
				IF pr_part_code IS NULL THEN 
					LET pa_stockother[idx].acct_code = NULL 
					LET pa_stockother[idx].source_desc_text = NULL 
					LET pa_stockother[idx].coa_desc_text = NULL 
				END IF 
				CALL display_stockother(idx) 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
					LET msgresp = kandoomsg("U",9910,"") 
					#9910 RECORD NOT found
					NEXT FIELD source_code 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD ware_code 
				END IF 
				IF pa_stockissue[idx].part_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD part_code 
				END IF 
				IF pa_stockissue[idx].ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD ware_code 
				END IF 
				IF pa_stockissue[idx].tran_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_qty 
				END IF 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9542,"") 
					#9542 GL Account NOT entered.
					NEXT FIELD source_code 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD tran_qty 
			IF pr_product.serial_flag = 'Y' THEN 
				LET pr_cnt = serial_input(pa_stockissue[idx].part_code, 
				pa_stockissue[idx].ware_code, 
				pa_stockissue[idx].tran_qty) 
				IF pr_cnt < 0 THEN 
					IF pr_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("I22 - Fatal error in serial_input ") 
						EXIT program 
					END IF 
				ELSE 
					LET pa_stockissue[idx].tran_qty = pr_cnt 
					DISPLAY pa_stockissue[idx].tran_qty 
					TO sr_stockissue[scrn].tran_qty 

					IF pa_stockissue[idx].tran_qty = 0 THEN 
						LET msgresp = kandoomsg("I",9192,"") 
						#9927 Quantity must be greater than zero.
						NEXT FIELD part_code 
					END IF 
				END IF 
				LET pr_add_mode= line_detail(idx, scrn) 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD tran_qty 
			IF pa_stockissue[idx].tran_qty IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD tran_qty 
			END IF 
			IF pa_stockissue[idx].tran_qty < 0.01 THEN 
				LET msgresp = kandoomsg("I",9192,"") 
				#9927 Quantity must be greater than zero.
				NEXT FIELD tran_qty 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_stockissue[idx].tran_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_qty 
				END IF 
				IF pa_stockissue[idx].tran_qty < 0.01 THEN 
					LET msgresp = kandoomsg("I",9192,"") 
					#9927 Quantity must be greater than zero.
					NEXT FIELD tran_qty 
				END IF 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD source_code 
				END IF 
				IF pa_stockissue[idx].part_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD part_code 
				END IF 
				IF pa_stockissue[idx].ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD ware_code 
				END IF 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9542,"") 
					#9542 GL Account NOT entered.
					NEXT FIELD tran_qty 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
			LET pr_add_mode= line_detail(idx, scrn) 
			IF fgl_lastkey() = fgl_keyval("interrupt") 
			OR fgl_lastkey() = fgl_keyval("delete") THEN 
				#Within edit mode AND go TO start of line
				LET pr_add_mode = false 
				NEXT FIELD scroll_flag 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					# restore original VALUES
					IF pr_stockissue.part_code IS NOT NULL THEN 
						LET pa_stockissue[idx].* = pr_stockissue.* 
						LET pa_stockother[idx].* = pr_stockother.* 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						FOR idx = arr_curr() TO arr_count() 
							LET pa_stockissue[idx].* = pa_stockissue[idx+1].* 
							LET pa_stockother[idx].* = pa_stockother[idx+1].* 
							IF arr_curr() = arr_count() THEN 
								INITIALIZE pa_stockissue[idx].* TO NULL 
								INITIALIZE pa_stockother[idx].* TO NULL 
								EXIT FOR 
							END IF 
							IF scrn <= 8 THEN 
								DISPLAY pa_stockissue[idx].* TO 
								sr_stockissue[scrn].* 

								LET scrn = scrn + 1 
							END IF 
						END FOR 
						LET int_flag = false 
						LET quit_flag = false 
						LET pr_add_mode = false 
						LET trial = true 
						NEXT FIELD scroll_flag 
					END IF 
				ELSE 
					LET pr_bypass_menu = "Y" 
					IF int_flag OR quit_flag THEN 
						IF pa_stockissue[1].part_code IS NOT NULL THEN 
							LET msgresp = kandoomsg("U",8002,"") 
							# 8002 Do you wish TO quit?
							IF msgresp = "Y" THEN 
								FOR idx = 1 TO 1000 
									INITIALIZE pa_stockissue[idx].* TO NULL 
									INITIALIZE pa_stockother[idx].* TO NULL 
								END FOR 
								CALL serial_init(glob_rec_kandoouser.cmpy_code, "", "0", "") 
								CLEAR FORM 
								LET pr_first_time = true 
							ELSE 
								LET int_flag = false 
								LET quit_flag = false 
								LET trial = true 
								NEXT FIELD scroll_flag 
							END IF 
						ELSE 
							FOR idx = arr_curr() TO arr_count() 
								LET pa_stockissue[idx].* = pa_stockissue[idx+1].* 
								LET pa_stockother[idx].* = pa_stockother[idx+1].* 
								IF arr_curr() = arr_count() THEN 
									INITIALIZE pa_stockissue[idx].* TO NULL 
									INITIALIZE pa_stockother[idx].* TO NULL 
									EXIT FOR 
								END IF 
								IF scrn <= 8 THEN 
									DISPLAY pa_stockissue[idx].* TO 
									sr_stockissue[scrn].* 

									LET scrn = scrn + 1 
								END IF 
							END FOR 
							LET int_flag = false 
							LET quit_flag = false 
							LET pr_add_mode = false 
							LET trial = true 
							IF pa_stockissue[1].part_code IS NULL THEN 
								EXIT INPUT 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET trial = true 
		RETURN false 
	END IF 
	IF fgl_lastkey() = fgl_keyval("accept") THEN 
		IF pa_stockissue[1].part_code IS NOT NULL THEN 
			LET pr_bypass_menu = "N" 
		ELSE 
			LET pr_bypass_menu = "Y" 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 



FUNCTION line_detail(idx, scrn) 
	DEFINE idx, scrn, pr_add_mode SMALLINT 

	INPUT pa_stockother[idx].part_desc_text, 
	pa_stockother[idx].acct_code WITHOUT DEFAULTS 
	FROM product.desc_text, 
	prodledg.acct_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I22","input-pa_stockother-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F8) 
			IF pa_stockissue[idx].part_code IS NOT NULL THEN 
				CALL prsswind(glob_rec_kandoouser.cmpy_code,pa_stockissue[idx].part_code) 
			END IF 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		ON KEY (control-b) 
			CASE 
				WHEN infield (acct_code) 
					LET pr_wind_text = show_acct(glob_rec_kandoouser.cmpy_code) 
					IF pr_wind_text IS NOT NULL THEN 
						LET pa_stockother[idx].acct_code = pr_wind_text 
						DISPLAY pa_stockother[idx].acct_code 
						TO prodledg.acct_code 

					END IF 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
					NEXT FIELD acct_code 
			END CASE 
		ON KEY (control-n) 
			IF infield(desc_text) THEN 
				LET pr_wind_text = sys_noter(glob_rec_kandoouser.cmpy_code, 
				pa_stockother[idx].part_desc_text) 
				IF pr_wind_text IS NOT NULL THEN 
					LET pa_stockother[idx].note_entry = true 
					LET pa_stockother[idx].part_desc_text = pr_wind_text 
					DISPLAY pa_stockother[idx].part_desc_text 
					TO product.desc_text 

				END IF 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD desc_text 
			IF pa_stockother[idx].part_desc_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD product.desc_text 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD acct_code 
				END IF 
			END IF 
		AFTER FIELD acct_code 
			IF pa_stockother[idx].acct_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD acct_code 
			END IF 
			SELECT coa.* INTO pr_coa.* FROM coa 
			WHERE coa.acct_code = pa_stockother[idx].acct_code AND 
			coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found;  Try Window.
				NEXT FIELD acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
				LET pa_stockother[idx].coa_desc_text = pr_coa.desc_text 
			END IF 
			DISPLAY pa_stockother[idx].coa_desc_text 
			TO coa.desc_text 

			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD desc_text 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pa_stockother[idx].acct_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD acct_code 
				END IF 
				IF pa_stockother[idx].part_desc_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD product.desc_text 
				END IF 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					NEXT FIELD desc_text 
				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				# restore original VALUES
				IF pr_stockissue.part_code IS NOT NULL THEN 
					LET pa_stockissue[idx].* = pr_stockissue.* 
					LET pa_stockother[idx].* = pr_stockother.* 
				ELSE 
					FOR idx = arr_curr() TO arr_count() 
						LET pa_stockissue[idx].* = pa_stockissue[idx+1].* 
						LET pa_stockother[idx].* = pa_stockother[idx+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_stockissue[idx].* TO NULL 
							INITIALIZE pa_stockother[idx].* TO NULL 
							DISPLAY pa_stockissue[idx].* 
							TO sr_stockissue[scrn].* 

							CALL display_stockother(idx) 
							EXIT FOR 
						END IF 
						IF scrn <= 8 THEN 
							DISPLAY pa_stockissue[idx].* TO 
							sr_stockissue[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET pr_add_mode = false 
					LET idx = arr_curr() 
					CALL display_stockother(idx) 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN pr_add_mode 
END FUNCTION 



FUNCTION header() 
	IF pr_tran_date IS NOT NULL 
	AND pr_year_num IS NULL 
	AND pr_period_num IS NULL THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_tran_date) 
		RETURNING pr_year_num, pr_period_num 
	END IF 
	LET msgresp = kandoomsg("U",1020,"Product Issue Header") 
	#1020 Enter Product Issue Header Details;  OK TO Continue.
	INPUT pr_tran_date, 
	pr_year_num, 
	pr_period_num, 
	pr_source_num WITHOUT DEFAULTS 
	FROM prodledg.tran_date, 
	prodledg.year_num, 
	prodledg.period_num, 
	prodledg.source_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I22","input-pr_tran_date-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD tran_date 
			IF pr_tran_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD tran_date 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_tran_date) 
			RETURNING pr_year_num, pr_period_num 
			DISPLAY pr_tran_date, 
			pr_period_num, 
			pr_year_num 
			TO prodledg.tran_date, 
			prodledg.period_num, 
			prodledg.year_num 

		AFTER FIELD year_num 
			IF pr_year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD year_num 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pr_tran_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_date 
				END IF 
				IF pr_period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD period_num 
				END IF 
			END IF 
		AFTER FIELD period_num 
			IF pr_period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_year_num, 
			pr_period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING pr_year_num, 
			pr_period_num, 
			failed_it 
			IF failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") THEN 
				IF pr_tran_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tran_date 
				END IF 
				IF pr_year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD year_num 
				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_stockissue[1].part_code IS NOT NULL THEN 
					LET msgresp = kandoomsg("U",8002,"") 
					# 8002 Do you wish TO quit?
					IF msgresp = "Y" THEN 
						CLEAR FORM 
						LET int_flag = true 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD tran_date 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 



# displays fields in bottom half of SCREEN
FUNCTION display_stockother(idx) 
	DEFINE 
	idx SMALLINT 

	DISPLAY pa_stockother[idx].part_desc_text, 
	pa_stockother[idx].source_desc_text, 
	pa_stockother[idx].acct_code, 
	pa_stockother[idx].coa_desc_text 
	TO product.desc_text, 
	prodledg.desc_text, 
	prodledg.acct_code, 
	coa.desc_text 

END FUNCTION 



FUNCTION save_details() 
	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	err_message CHAR(40), 
	err_continue CHAR(1), 
	pr_counter SMALLINT 

	LET msgresp = kandoomsg("U",1005,"") 
	# Updating Database;  Please wait.
	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		FOR pr_counter = 1 TO arr_count() 
			LET err_message = "I22 - UPDATE prodstatus " 
			# done as the ARRAY count may reflect incorrect number
			# AND the part code will be NULL IF the CASE
			IF pa_stockissue[pr_counter].part_code IS NULL THEN 
				CONTINUE FOR 
			END IF 
			SELECT prodstatus.* INTO pr_prodstatus.* FROM prodstatus 
			WHERE part_code = pa_stockissue[pr_counter].part_code 
			AND ware_code = pa_stockissue[pr_counter].ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
			IF pr_prodstatus.stocked_flag = "Y" THEN 
				LET pr_prodstatus.onhand_qty = 
				pr_prodstatus.onhand_qty - pa_stockissue[pr_counter].tran_qty 
			ELSE 
				LET pr_prodstatus.onhand_qty = 0 
			END IF 
			LET pr_prodstatus.last_sale_date = pr_tran_date 
			UPDATE prodstatus SET seq_num = pr_prodstatus.seq_num, 
			onhand_qty = pr_prodstatus.onhand_qty, 
			last_sale_date = pr_prodstatus.last_sale_date 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_stockissue[pr_counter].part_code 
			AND ware_code = pa_stockissue[pr_counter].ware_code 
			LET err_message = "I22 - UPDATE prodledg " 
			LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodledg.tran_date = pr_tran_date 
			LET pr_prodledg.year_num = pr_year_num 
			LET pr_prodledg.period_num = pr_period_num 
			LET pr_prodledg.source_num = pr_source_num 
			LET pr_prodledg.part_code = pa_stockissue[pr_counter].part_code 
			LET pr_prodledg.ware_code = pa_stockissue[pr_counter].ware_code 
			
			# check IF user entered blank FOR source text AND default TO ISSUE ifso
			IF pa_stockissue[pr_counter].source_text IS NULL 
			OR pa_stockissue[pr_counter].source_text = " " THEN 
				LET pr_prodledg.source_text = "ISSUE" 
			ELSE 
				LET pr_prodledg.source_code = pa_stockissue[pr_counter].source_code 
				LET pr_prodledg.source_type = "PADJ"
			END IF 
			LET pr_prodledg.tran_qty = (0 - pa_stockissue[pr_counter].tran_qty) 
			LET pr_prodledg.cost_amt = pa_stockissue[pr_counter].cost_amt 
			LET pr_prodledg.acct_code = pa_stockother[pr_counter].acct_code 
			LET pr_prodledg.desc_text = pa_stockother[pr_counter].part_desc_text 
			LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
			LET pr_prodledg.trantype_ind = "I" 
			LET pr_prodledg.sales_amt = pr_prodstatus.list_amt 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET pr_prodledg.hist_flag = "N" 
			ELSE 
				LET pr_prodledg.hist_flag = "Y" 
			END IF 
			LET pr_prodledg.post_flag = "N" 
			LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
			LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_prodledg.entry_date = today 
			INSERT INTO prodledg VALUES (pr_prodledg.*) 
			# Now allocate the serial numbers as required
			IF pr_product.serial_flag = "Y" THEN 
				LET err_message = "I22 - serial_update " 
				LET pr_serialinfo.cmpy_code = pr_prodledg.cmpy_code 
				LET pr_serialinfo.part_code = pr_prodledg.part_code 
				LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
				LET pr_serialinfo.trans_num = pr_prodledg.seq_num 
				LET pr_serialinfo.trantype_ind = "I" 
				LET status = serial_update(pr_serialinfo.*, 
				pa_stockissue[pr_counter].tran_qty, '') 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END FOR 
	COMMIT WORK 
END FUNCTION 




REPORT I22_rpt_list(p_rpt_idx,pr_counter) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	DEFINE 
	line1, line2 CHAR(80), 
	pr_picked_qty LIKE orderdetl.picked_qty, 
	pr_counter, offset1, offset2 SMALLINT 

	OUTPUT 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 01, "Product", 
			COLUMN 17, "Description", 
			COLUMN 48, "Ware", 
			COLUMN 53, "Source No.", 
			COLUMN 71, "Qty" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		ON EVERY ROW 

			PRINT COLUMN 01, pa_stockissue[pr_counter].part_code, 
			COLUMN 17, pa_stockother[pr_counter].part_desc_text, 
			COLUMN 48, pa_stockissue[pr_counter].ware_code, 
			COLUMN 52, pr_source_num, 
			COLUMN 61, pa_stockissue[pr_counter].tran_qty 
		ON LAST ROW 
			SKIP 4 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
