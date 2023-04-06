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

	Source code beautified by beautify.pl on 2020-01-03 09:12:37	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"

#   IK2 - Product Kit Compilation/Decomplilation
# TODO: check if the error -703 still occurs in lib_report_reptfunc.4gl after merge
# TODO: clean code priority 1
# TODO: clean code priority 2
# TODO: clean code priority 3

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#Module Scope Variables

DEFINE 
pr_kithead RECORD LIKE kithead.*, 
pr_product RECORD LIKE product.*, 
pr_productdetl RECORD LIKE product.*, 
pr_serialinfo RECORD LIKE serialinfo.*, 
pr_inparms RECORD LIKE inparms.*, 
ps_prodledg RECORD LIKE prodledg.*, 
pr_prodstatus RECORD LIKE prodstatus.*, 
err_message CHAR(60), 
pa_serialinfo array[320] OF RECORD 
	pick_flag CHAR(1), 
	serial_code LIKE serialinfo.serial_code, 
	receipt_date LIKE serialinfo.receipt_date, 
	vend_code LIKE serialinfo.vend_code, 
	ware_code LIKE serialinfo.ware_code, 
	po_num LIKE serialinfo.po_num, 
	trantype_ind LIKE serialinfo.trantype_ind 
END RECORD, 
pa_kitdetl array[100] OF RECORD 
	part_code LIKE kitdetl.part_code, 
	desc_text LIKE product.desc_text, 
	kit_qty LIKE kitdetl.kit_qty, 
	avail_qty LIKE kitdetl.kit_qty, 
	serial_flag LIKE product.serial_flag, 
	serial_entered CHAR(1) 
END RECORD, 
pr_serial_qty LIKE kitdetl.kit_qty, 
pr_serial_product LIKE kithead.serial_product, 
pr_kitdetl RECORD LIKE kitdetl.*, 
pr_kitserial RECORD LIKE kitserial.*, 
pr_kit_serial LIKE serialinfo.serial_code, 
pr_prodledg RECORD LIKE prodledg.*, 
pr_ibthead RECORD LIKE ibthead.*, 
pr_ibtdetl RECORD LIKE ibtdetl.*, 
try_again CHAR(1), 
query_text, sel_text CHAR(200), 
pick_idx, idx, id_flag, scrn, cnt SMALLINT, 
err_flag,s_idx, s_scrn, serial_idx SMALLINT, 
serial_choosen CHAR(1), 
rpt_val CHAR(1), 
pr_kit_warehouse LIKE warehouse.ware_code, 
pr_kit_ware_desc LIKE warehouse.desc_text, 
pr_temp_text CHAR(200), 
pr_kit_lines SMALLINT , 
pr_kit_code LIKE kithead.kit_code, 
pr_serial_check SMALLINT, 
pr_doc_num INTEGER, 
pr_trans_num LIKE ibthead.trans_num 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IK2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL rpt_kandooreport_init(glob_rec_kandoouser.cmpy_code,getmoduleid(),"IK2") 
	RETURNING rpt_val 
	IF report1_no_io(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,0) THEN 
	END IF 
	CALL set_cursors() 

	OPEN WINDOW i159 with FORM "I159" 
	 CALL windecoration_i("I159") -- albo kd-758 
	#------------------------------------------------------------
	CALL report2()
	MESSAGE "Process Report - ", trim(glob_rec_rmsreps.report_text), ": ", trim(glob_rec_rmsreps.file_text)	
	START REPORT IK2_rpt_list TO glob_rec_rmsreps.file_text
	#------------------------------------------------------------
	CLOSE WINDOW w1_rpt 

	MENU "Compile Kitsets " 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IK2","menu-Compile_Kitsets-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Kitsets" "Compile a kitset" 
			IF select_kithead() THEN 
				CALL scan_kithead() 
			END IF 

			LET int_flag = false 
			LET quit_flag = false 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" "View OR Print REPORT using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY (interrupt, "E") "Exit" "Exit back TO menus" 
			EXIT MENU 

	END MENU 

	OPEN WINDOW w1_rpt at 10,10 with 3 ROWS, 60 COLUMNS 
	attribute(border) 
	#------------------------------------------------------------
	CALL report4()
	FINISH REPORT IK2_rpt_list
	MESSAGE "Completed Report: ", trim(glob_rec_rmsreps.file_text) 
	#------------------------------------------------------------ 
	CLOSE WINDOW i159 
END MAIN 

FUNCTION set_cursors() 

	##
	## Due TO nested AND repeated selects we have SET up cursors
	##

	LET pr_temp_text = "SELECT * FROM kitdetl ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND kit_code=?", 
	"ORDER BY kit_code,line_num" 
	PREPARE s_kitdetl FROM pr_temp_text 
	DECLARE c_kitdetl CURSOR FOR s_kitdetl 
	LET pr_temp_text = "SELECT desc_text, serial_flag FROM product ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND part_code=?" 
	PREPARE s_product FROM pr_temp_text 
	DECLARE c_product CURSOR FOR s_product 
	LET pr_temp_text = "SELECT (onhand_qty-reserved_qty-back_qty) ", 
	"FROM prodstatus ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ware_code=? AND part_code=?" 
	PREPARE s_prodstatus FROM pr_temp_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 
END FUNCTION 


FUNCTION select_kithead() 
	DEFINE 
	where_text CHAR(100), 
	query_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag

	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 Enter Selection Criteria
	CONSTRUCT BY NAME where_text ON kit_code, 
	kit_text, 
	type_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IK2","construct-kit_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 Searching Database
		LET query_text = "SELECT * FROM kithead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY kit_code" 
		PREPARE s_kithead FROM query_text 
		DECLARE c_kithead CURSOR FOR s_kithead 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_kithead() 
	DEFINE 
	pa_kithead array[100] OF RECORD 
		scroll_flag CHAR(1), 
		kit_code LIKE kithead.kit_code, 
		kit_text LIKE kithead.kit_text, 
		type_ind LIKE kithead.type_ind 
	END RECORD, 
	del_cnt,idx,scrn,pr_curr,pr_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	LET idx = 0 
	FOREACH c_kithead INTO pr_kithead.* 
		LET idx = idx + 1 
		LET pa_kithead[idx].kit_code = pr_kithead.kit_code 
		LET pa_kithead[idx].kit_text = pr_kithead.kit_text 
		LET pa_kithead[idx].type_ind = pr_kithead.type_ind 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("I",9172,idx) 
			#9172 First 'idx' entries selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET l_msgresp = kandoomsg("I",1122,"") 
	#1122 Kit Compilation - RETURN on line TO Compile
	INPUT ARRAY pa_kithead WITHOUT DEFAULTS FROM sr_kithead.* 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET l_msgresp = kandoomsg("I",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD kit_code 
			LET pr_kit_code = pa_kithead[idx].kit_code 
			LET pr_doc_num = compile_kithead() 
			IF fgl_lastkey() != fgl_keyval("interrupt") THEN 
				IF pr_doc_num > 0 THEN 
					LET l_msgresp = kandoomsg("I",7048,pr_doc_num) 
					#7048 Adjustment Successfull
					LET pr_trans_num = 0 
					IF pr_prodledg.ware_code <> pr_kit_warehouse THEN 
						IF transfer_kit() THEN 
							LET l_msgresp = kandoomsg("I",1045,pr_ibthead.trans_num) 
							LET pr_trans_num = pr_ibthead.trans_num 
						END IF 
					END IF 
				END IF 
				CALL write_report() 
			ELSE 
				LET int_flag = false 
			END IF 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_kithead[idx].* TO sr_kithead[scrn].* 

			#   NEXT FIELD scroll_flag
		ON KEY (control-c) 
			LET int_flag = true 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION compile_kithead() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pa_kitqty array[100] OF FLOAT, 
	pr_line_cnt LIKE kitdetl.line_num, 
	pr_no_stock CHAR(1), 
	pr_save_date DATE, 
	invalid_period INTEGER, 
	err_message CHAR(100), 
	idx,scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag


	SELECT * INTO pr_kithead.* 
	FROM kithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND kit_code = pr_kit_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	OPEN WINDOW i258 with FORM "I258" 
	 CALL windecoration_i("I258") -- albo kd-758 

	BEGIN WORK 

		LET pr_kit_serial = " " 
		LET pr_serial_product = pr_kithead.serial_product 

		DISPLAY BY NAME pr_kithead.kit_code, 
		pr_kithead.kit_text, 
		pr_serial_product 

		LET idx = 0 
		LET serial_idx = 0 
		LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		OPEN c_kitdetl USING pr_kit_code 
		FOREACH c_kitdetl INTO pr_kitdetl.* 
			LET idx = idx + 1 
			LET pa_kitdetl[idx].part_code = pr_kitdetl.part_code 
			IF pr_kitdetl.part_code = pr_serial_product THEN 
				LET serial_idx = idx 
			END IF 
			OPEN c_product USING pr_kitdetl.part_code 
			FETCH c_product INTO pa_kitdetl[idx].desc_text, 
			pa_kitdetl[idx].serial_flag 
			IF pr_kithead.qtyper_ind = "1" THEN 
				LET pa_kitdetl[idx].kit_qty = pr_kitdetl.kit_qty 
			ELSE 
				LET pa_kitdetl[idx].kit_qty = pr_kitdetl.kit_per 
			END IF 
			LET pa_kitqty[idx] = pa_kitdetl[idx].kit_qty 
			LET pa_kitdetl[idx].avail_qty = NULL 
			IF pa_kitdetl[idx].serial_flag = "N" THEN 
				LET pa_kitdetl[idx].serial_entered = " " 
			ELSE 
				LET pa_kitdetl[idx].serial_entered = "N" 
			END IF 
			IF idx <= 8 THEN 
				DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[idx].* 

			END IF 
		END FOREACH 
		CLOSE c_kitdetl 
		LET pr_line_cnt = idx 
		LET pr_prodledg.tran_date = today 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_prodledg.tran_date) 
		RETURNING pr_prodledg.year_num, 
		pr_prodledg.period_num 
		WHILE true 
			LET l_msgresp = kandoomsg("I",1123,"") 
			#1123 Kit Compilation - RETURN on line TO Compile
			INPUT BY NAME pr_prodledg.ware_code, 
			pr_kit_warehouse, 
			pr_prodledg.tran_qty, 
			pr_prodledg.tran_date, 
			pr_prodledg.source_code, 
			pr_prodledg.source_text, 
			pr_serial_product, 
			pr_prodledg.year_num, 
			pr_prodledg.period_num WITHOUT DEFAULTS 

				ON KEY (control-b) 
					IF infield(ware_code) THEN 
						LET pr_prodledg.ware_code= show_ware(glob_rec_kandoouser.cmpy_code) 
						NEXT FIELD ware_code 
					END IF 
					IF infield(pr_kit_warehouse) THEN 
						LET pr_kit_warehouse = show_ware(glob_rec_kandoouser.cmpy_code) 
						NEXT FIELD pr_kit_warehouse 
					END IF 
					IF infield(source_text) THEN 
						LET pr_prodledg.source_text = show_job(glob_rec_kandoouser.cmpy_code) 
						NEXT FIELD source_text 
					END IF 
				AFTER FIELD ware_code 
					IF pr_prodledg.ware_code IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9029,"") 
						#I9029 Warehouse must be entered
						NEXT FIELD ware_code 
					END IF 
					SELECT * INTO pr_warehouse.* 
					FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_prodledg.ware_code 
					IF sqlca.sqlcode = notfound THEN 
						LET l_msgresp = kandoomsg("I",9030,"") 
						# I9030 warehouse IS NOT found, try window
						NEXT FIELD ware_code 
					END IF 
					DISPLAY BY NAME pr_warehouse.desc_text 

					FOR idx = 1 TO pr_line_cnt 
						OPEN c_prodstatus USING pr_prodledg.ware_code, 
						pa_kitdetl[idx].part_code 
						FETCH c_prodstatus INTO pa_kitdetl[idx].avail_qty 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9104,"") 
							#9104 Product IS NOT stocked AT this warehouse
							NEXT FIELD ware_code 
						END IF 
						IF idx <= 8 THEN 
							DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[idx].* 

						END IF 
					END FOR 

					# Allow new warehouse code FOR the assembled kit & check exists, image it

				AFTER FIELD pr_kit_warehouse 
					IF pr_kit_warehouse IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9029,"") 
						#I9029 Warehouse must be entered
						NEXT FIELD pr_kit_warehouse 
					END IF 
					SELECT * INTO pr_warehouse.* 
					FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_kit_warehouse 
					IF sqlca.sqlcode = notfound THEN 
						LET l_msgresp = kandoomsg("I",9030,"") 
						# I9030 warehouse IS NOT found, try window
						NEXT FIELD pr_kit_warehouse 
					END IF 
					OPEN c_prodstatus USING pr_kit_warehouse, 
					pr_kit_code 
					FETCH c_prodstatus 
					IF status = notfound THEN 
						OPEN WINDOW w1 at 10,5 with 3 rows,70 COLUMNS 
						attribute(border) 
						MENU " Product NOT stocked AT destination warehouse" 

							BEFORE MENU 
								CALL publish_toolbar("kandoo","IK2","menu-Product_not_stocked-1") -- albo kd-505 

							ON ACTION "WEB-HELP" -- albo kd-372 
								CALL onlinehelp(getmoduleid(),null) 

							COMMAND "Image" " Image existing product stocking STATUS" 
								SELECT * 
								INTO pr_product.* 
								FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pr_kit_code 
								LET pr_temp_text = image_product(glob_rec_kandoouser.cmpy_code, pr_product.*,pr_kit_warehouse) 
								CLOSE c_prodstatus 
								OPEN c_prodstatus USING pr_kit_warehouse, 
								pr_kit_code 
								FETCH c_prodstatus 
								IF status <> notfound THEN 
									EXIT MENU 
								END IF 
							COMMAND KEY("E",interrupt)"Exit" " Re-enter destination warehouse" 
								LET quit_flag = true 
								EXIT MENU 
							COMMAND KEY (control-w) 
								CALL kandoohelp("") 
						END MENU 
						CLOSE WINDOW w1 
					END IF 
					CLOSE c_prodstatus 
					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						LET l_msgresp = kandoomsg("I",9104,"") 
						#9104 Kit Product IS NOT stocked AT this warehouse
						NEXT FIELD pr_kit_warehouse 
					END IF 

					LET pr_kit_ware_desc = pr_warehouse.desc_text 
					DISPLAY BY NAME pr_kit_ware_desc 


					# Set compile qty TO 1 FOR now
				BEFORE FIELD tran_qty 
					LET pr_prodledg.tran_qty = 1 
					DISPLAY BY NAME pr_prodledg.tran_qty 
					NEXT FIELD tran_date 
				AFTER FIELD tran_qty 
					IF pr_prodledg.tran_qty IS NULL 
					OR pr_prodledg.tran_qty = 0 THEN 
						ERROR " Value must be greater than zero" 
						NEXT FIELD tran_qty 
					END IF 
					#           IF pr_prodledg.tran_qty < 0 THEN
					#              ERROR " Value must be greater than zero"
					#              NEXT FIELD tran_qty
					#           END IF
					LET pr_no_stock = false 
					FOR idx = 1 TO pr_line_cnt 
						IF pr_kithead.qtyper_ind = "1" THEN 
							LET pa_kitdetl[idx].kit_qty = pa_kitqty[idx] 
							* pr_prodledg.tran_qty 
						ELSE 
							LET pa_kitdetl[idx].kit_qty = (pa_kitqty[idx]/100) 
							* pr_prodledg.tran_qty 
						END IF 
						IF pa_kitdetl[idx].kit_qty > pa_kitdetl[idx].avail_qty THEN 
							LET pr_no_stock = true 
						END IF 
						IF idx <= 8 THEN 
							DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[idx].* 

						END IF 
					END FOR 
					IF pr_no_stock = true THEN 
						LET l_msgresp = kandoomsg("I",9009,"") 
						#I9009 Stock NOT available FOR creating kitsets
						IF l_msgresp = "N" THEN 
							NEXT FIELD tran_qty 
						ELSE 
							NEXT FIELD tran_date 
						END IF 
					END IF 
				BEFORE FIELD tran_date 
					LET pr_save_date = pr_prodledg.tran_date 
				AFTER FIELD tran_date 
					IF pr_prodledg.tran_date != pr_save_date THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_prodledg.tran_date) 
						RETURNING pr_prodledg.year_num, 
						pr_prodledg.period_num 
						DISPLAY BY NAME pr_prodledg.period_num, 
						pr_prodledg.year_num 

					END IF 
				AFTER FIELD source_text 
					IF pr_prodledg.source_text = " " 
					OR pr_prodledg.source_text IS NULL THEN 
						LET l_msgresp = kandoomsg("J",9570,"") 
						NEXT FIELD source_text 
					END IF 

					# REVIEW: one more fuzzy relationship of source_text with one more table: to be checked
					SELECT * FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_prodledg.source_text 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("J",9570,"") 
						NEXT FIELD source_text 
					END IF 
				AFTER FIELD pr_serial_product 
					IF pr_kithead.serial_product IS NOT NULL 
					AND pr_kithead.serial_product != " " THEN 
						LET pr_serial_product = pr_kithead.serial_product 
					ELSE 
						IF pr_serial_product IS NULL 
						OR pr_serial_product = " " THEN 
							LET l_msgresp = kandoomsg("J",9570,"") 
							NEXT FIELD pr_serial_product 
						END IF 
					END IF 
				AFTER INPUT 
					IF NOT (int_flag OR quit_flag) THEN 
						IF pr_prodledg.ware_code IS NULL THEN 
							LET l_msgresp = kandoomsg("I",9029,"") 
							#I9029 warehouse IS NOT found, try window
							NEXT FIELD ware_code 
						END IF 
						IF pr_kit_warehouse IS NULL THEN 
							LET l_msgresp = kandoomsg("I",9029,"") 
							#I9029 warehouse IS NOT found, try window
							NEXT FIELD pr_kit_warehouse 
						END IF 
						CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_prodledg.year_num, 
						pr_prodledg.period_num,TRAN_TYPE_INVOICE_IN) 
						RETURNING pr_prodledg.year_num, 
						pr_prodledg.period_num, 
						invalid_period 
						IF invalid_period THEN 
							NEXT FIELD year_num 
						END IF 
						IF pr_prodledg.ware_code IS NULL THEN 
							LET l_msgresp = kandoomsg("I",9029,"") 
							#I9029 Warehouse must be entered
							NEXT FIELD ware_code 
						END IF 
						IF pr_prodledg.tran_qty != 1 THEN 
							LET pr_prodledg.tran_qty = 1 
						END IF 
						##             IF pr_prodledg.tran_qty IS NULL
						##                OR pr_prodledg.tran_qty = 0 THEN
						##                   ERROR " Value must be greater than zero"
						##                   NEXT FIELD tran_qty
						##             END IF
						IF pr_prodledg.tran_date != pr_save_date THEN 
							CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_prodledg.tran_date) 
							RETURNING pr_prodledg.year_num, 
							pr_prodledg.period_num 
							DISPLAY BY NAME pr_prodledg.period_num, 
							pr_prodledg.year_num 

						END IF 
						IF pr_prodledg.source_text = " " 
						OR pr_prodledg.source_text IS NULL THEN 
							LET l_msgresp = kandoomsg("J",9570,"") 
							NEXT FIELD source_text 
						END IF 
						IF pr_kithead.serial_product IS NOT NULL 
						AND pr_kithead.serial_product != " " THEN 
							LET pr_serial_product = pr_kithead.serial_product 
						ELSE 
							IF pr_serial_product IS NULL 
							OR pr_serial_product = " " THEN 
								LET l_msgresp = kandoomsg("J",9570,"") 
								NEXT FIELD pr_serial_product 
							END IF 
						END IF 
					END IF 

				ON KEY (control-c) 
					LET int_flag = true 
					EXIT INPUT 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT WHILE 
			END IF 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET l_msgresp = kandoomsg("I",1003,"") 
			#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

			SELECT * INTO pr_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_prodledg.ware_code 

			IF NOT update_masterserial() THEN 
				LET int_flag = true 
			ELSE 

				CALL set_count(pr_line_cnt) 

				INPUT ARRAY pa_kitdetl WITHOUT DEFAULTS FROM sr_kitdetl.* 

					BEFORE ROW 
						LET idx = arr_curr() 
						LET scrn = scr_line() 
					AFTER FIELD kit_qty 
						IF pa_kitdetl[idx].kit_qty IS NULL THEN 
							LET pa_kitdetl[idx].kit_qty = 0 
						END IF 
						IF (pa_kitdetl[idx].kit_qty IS NULL 
						OR pa_kitdetl[idx].kit_qty = 0) THEN 
							IF pa_kitdetl[idx].part_code IS NOT NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								NEXT FIELD kit_qty 
							END IF 
						ELSE 
							### Detail product + serial no
							LET err_message = "IK2 = Serial No Update" 
							SELECT * INTO pr_productdetl.* 
							FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pa_kitdetl[idx].part_code 
							IF pa_kitdetl[idx].serial_flag = "Y" 
							AND pa_kitdetl[idx].serial_entered = "N" THEN 
								LET pr_serial_qty = pa_kitdetl[idx].kit_qty 
								LET serial_choosen = serial_number() 
								IF serial_choosen = false THEN 
									LET l_msgresp = kandoomsg("I",9299,"") 
									NEXT FIELD kit_qty 
								ELSE 
									FOR s_idx = 1 TO arr_count() 
										IF pa_serialinfo[s_idx].pick_flag = "*" THEN 
											CALL update_kitserial() 
										END IF 
									END FOR 
									LET pa_kitdetl[idx].serial_entered = "Y" 
								END IF 
							END IF 
							DISPLAY pa_kitdetl[idx].* TO sr_kitdetl[scrn].* 
						END IF 
						IF arr_curr() >= arr_count() THEN 
							IF fgl_lastkey() = fgl_keyval("down") 
							OR fgl_lastkey() = fgl_keyval("tab") 
							OR fgl_lastkey() = fgl_keyval("RETURN") THEN 
								LET l_msgresp = kandoomsg("I",9001,"") 
								#9001 No more Rows in direction
								NEXT FIELD kit_qty 
							END IF 
						END IF 
					ON KEY (control-w) 
						CALL kandoohelp("") 

					ON KEY (control-c) 
						LET int_flag = true 

					AFTER INPUT 
						## Check serial number entered before trying TO UPDATE
						IF int_flag = false THEN 
							FOR idx = 1 TO pr_line_cnt 
								IF pa_kitdetl[idx].serial_flag = "Y" 
								AND pa_kitdetl[idx].serial_entered = "N" THEN 
									NEXT FIELD kit_qty 
								END IF 
							END FOR 
						END IF 
				END INPUT 
			END IF #ends IF NOT update_masterserial() 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				#################################################
				##
				##    Database UPDATE IS as follows:
				##
				## 1. obtain adjustments a/c FOR kithead.kit_code product
				## 2. work through each line in ARRAY performing an adjustment
				##    out TO the a/c ontained in step 1.
				## 3. As each line IS processed sum the wgted costs
				## 4. On completion of the line processing create an adjustment in
				##    using the a/c FROM step 1 AND the cost FROM step 3
				##
				#################################################

				LET l_msgresp = kandoomsg("I",1005,"") 
				#1005 Updating database - please wait
				GOTO bypass 
				LABEL recovery: 
				IF error_recover(err_message, status) = "N" THEN 
					LET pr_prodledg.source_num = 0 
					EXIT WHILE 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				LET err_message = "Deleting Previous Lines" 
				DECLARE c_inparms CURSOR FOR 
				SELECT * FROM inparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parm_code = "1" 
				FOR UPDATE 
				OPEN c_inparms 
				FETCH c_inparms INTO pr_inparms.* 
				IF status = notfound THEN 
					LET err_message = "Logic error: Inventroy parameters NOT found" 
					GOTO recovery 
				END IF 
				SELECT adj_acct_code INTO pr_prodledg.acct_code 
				FROM category, 
				product 
				WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND product.part_code = pr_kithead.kit_code 
				AND category.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND category.cat_code = product.cat_code 
				IF status = notfound THEN 
					LET err_message = "Logic error: product category NOT found" 
					GOTO recovery 
				END IF 
				##### SET up the rest of the master prodledg record
				LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodledg.part_code = pr_kithead.kit_code 
				LET pr_prodledg.trantype_ind = "A" 
				LET pr_prodledg.source_num = pr_inparms.next_adjust_num + 1 
				LET pr_prodledg.cost_amt = 0 
				LET pr_prodledg.sales_amt = 0 
				LET pr_prodledg.hist_flag = "N" 
				LET pr_prodledg.post_flag = "N" 
				LET pr_prodledg.jour_num = NULL 
				LET pr_prodledg.desc_text = "Assemble Kit - ",pr_kithead.kit_text 
				LET pr_prodledg.acct_code = 
				build_mask(glob_rec_kandoouser.cmpy_code,pr_warehouse.acct_mask_code, 
				pr_prodledg.acct_code) 
				LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_prodledg.entry_date = today 
				##### process each line
				FOR idx = 1 TO pr_line_cnt 
					### Source prodstatus
					LET err_message = "IK2 - Lock Status FOR Line",idx 
					DECLARE c1_prodstatus CURSOR FOR 
					SELECT * FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_prodledg.ware_code 
					AND part_code = pa_kitdetl[idx].part_code 
					FOR UPDATE 
					OPEN c1_prodstatus 
					FETCH c1_prodstatus INTO pr_prodstatus.* 
					IF status = notfound THEN 
						LET err_message = "Logic error: product STATUS NOT found" 
						GOTO recovery 
					END IF 
					IF pr_prodstatus.stocked_flag = "Y" THEN 
						LET pr_prodstatus.onhand_qty = 
						pr_prodstatus.onhand_qty - pa_kitdetl[idx].kit_qty 
					ELSE 
						LET pr_prodstatus.onhand_qty = 0 
					END IF 
					IF pr_prodstatus.wgted_cost_amt < 0 
					OR pr_prodstatus.wgted_cost_amt IS NULL THEN 
						LET pr_prodstatus.wgted_cost_amt = 0 
					END IF 
					LET err_message = "IK2 - Insert ledger FOR line",idx 
					LET ps_prodledg.* = pr_prodledg.* 
					LET ps_prodledg.part_code = pa_kitdetl[idx].part_code 
					LET ps_prodledg.seq_num = pr_prodstatus.seq_num+1 
					LET ps_prodledg.tran_qty = 0 - pa_kitdetl[idx].kit_qty 
					LET ps_prodledg.bal_amt = pr_prodstatus.onhand_qty 
					LET ps_prodledg.cost_amt = pr_prodstatus.wgted_cost_amt 
					INSERT INTO prodledg VALUES (ps_prodledg.*) 
					UPDATE prodstatus 
					SET seq_num = pr_prodstatus.seq_num+1, 
					onhand_qty = pr_prodstatus.onhand_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pa_kitdetl[idx].part_code 
					AND ware_code = pr_prodledg.ware_code 
					IF sqlca.sqlerrd[3] != 1 THEN 
						LET err_message = "Logic error: product STATUS NOT updated" 
						GOTO recovery 
					END IF 
					## accumalate cost FOR kit product
					LET pr_prodledg.cost_amt = pr_prodledg.cost_amt 
					+ (ps_prodledg.cost_amt * pa_kitdetl[idx].kit_qty) 
				END FOR 
				## convert header product cost INTO unit cost
				IF pr_prodledg.tran_qty != 0 THEN 
					LET pr_prodledg.cost_amt = pr_prodledg.cost_amt 
					/ pr_prodledg.tran_qty 
				END IF 
				LET err_message = "IK2 - Lock Status FOR Kit " 
				DECLARE c2_prodstatus CURSOR FOR 
				SELECT * FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_kithead.kit_code 
				AND ware_code = pr_prodledg.ware_code 
				FOR UPDATE 
				OPEN c2_prodstatus 
				FETCH c2_prodstatus INTO pr_prodstatus.* 
				IF status = notfound THEN 
					LET err_message = "Logic error: product STATUS NOT found" 
					GOTO recovery 
				END IF 
				IF pr_prodstatus.wgted_cost_amt IS NULL THEN 
					LET pr_prodstatus.wgted_cost_amt = 0 
				END IF 
				IF (pr_prodstatus.onhand_qty+pr_prodledg.tran_qty) != 0 THEN 
					LET pr_prodstatus.wgted_cost_amt = 
					((pr_prodstatus.wgted_cost_amt*pr_prodstatus.onhand_qty) 
					+(pr_prodledg.tran_qty*pr_prodledg.cost_amt)) 
					/(pr_prodledg.tran_qty+pr_prodstatus.onhand_qty) 
				ELSE 
					LET pr_prodstatus.wgted_cost_amt = pr_prodstatus.wgted_cost_amt 
				END IF 
				LET err_message = "IK2 - Insert ledger FOR line",idx 
				LET pr_prodledg.seq_num = pr_prodstatus.seq_num + 1 
				LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
				+ pr_prodledg.tran_qty 
				INSERT INTO prodledg VALUES (pr_prodledg.*) 
				LET err_message = "IK2 - Update STATUS FOR kit head" 
				UPDATE prodstatus 
				SET seq_num = pr_prodstatus.seq_num + 1, 
				onhand_qty = pr_prodstatus.onhand_qty 
				+ pr_prodledg.tran_qty, 
				wgted_cost_amt = pr_prodstatus.wgted_cost_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodstatus.part_code 
				AND ware_code = pr_prodstatus.ware_code 
				IF sqlca.sqlerrd[3] != 1 THEN 
					LET err_message = "Logic error: product STATUS NOT updated" 
					GOTO recovery 
				END IF 
				LET err_message = "IK2 - Update next adjustment number" 
				UPDATE inparms SET next_adjust_num = next_adjust_num + 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parm_code = "1" 

			COMMIT WORK 
			WHENEVER ERROR stop 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF fgl_lastkey() = fgl_keyval("interrupt") 
	OR int_flag = true THEN 
		LET int_flag = false 
		ROLLBACK WORK 
	END IF 
	CLOSE WINDOW i258 
	RETURN pr_prodledg.source_num 
END FUNCTION 


FUNCTION transfer_kit() 

	DEFINE pr_compile_qty LIKE prodledg.tran_qty
	DEFINE l_msgresp LIKE language.yes_flag

	LET l_msgresp = kandoomsg("I",1005,"") 
	#1005 Updating database - please wait
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		LET pr_prodledg.source_num = 0 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET err_message = "Kit Transfer records being written" 
		SELECT * 
		INTO pr_inparms.* 
		FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 

		LET pr_compile_qty = pr_prodledg.tran_qty 
		LET err_message = "Writing IBTHEAD record" 
		LET pr_ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_ibthead.trans_num = pr_inparms.next_trans_num 
		LET pr_ibthead.from_ware_code = pr_prodledg.ware_code 
		LET pr_ibthead.to_ware_code = pr_kit_warehouse 
		LET pr_ibthead.trans_date = today 
		LET pr_ibthead.desc_text = "Transfer Assembled Kit" 
		LET pr_ibthead.km_qty = 0 
		LET pr_ibthead.cart_area_code = " " 
		LET pr_ibthead.entry_date = today 
		LET pr_ibthead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_ibthead.year_num = pr_prodledg.year_num 
		LET pr_ibthead.period_num = pr_prodledg.period_num 
		LET pr_ibthead.del_num = 0 
		LET pr_ibthead.rev_num = 0 
		LET pr_ibthead.amend_code = NULL 
		LET pr_ibthead.amend_date = NULL 
		LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
		LET pr_ibthead.sched_ind = "0" 
		INSERT INTO ibthead VALUES (pr_ibthead.*) 

		LET err_message = "Writing IBTDETL record" 
		LET pr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_ibtdetl.trans_num = pr_ibthead.trans_num 
		LET pr_ibtdetl.line_num = 1 
		LET pr_ibtdetl.part_code = pr_kithead.kit_code 
		LET pr_ibtdetl.trf_qty = pr_compile_qty 
		LET pr_ibtdetl.picked_qty = 0 
		LET pr_ibtdetl.sched_qty = 0 
		LET pr_ibtdetl.conf_qty = 0 
		LET pr_ibtdetl.rec_qty = pr_compile_qty 
		LET pr_ibtdetl.back_qty = 0 
		LET pr_ibtdetl.amend_code = NULL 
		LET pr_ibtdetl.amend_date = NULL 
		LET pr_ibtdetl.status_ind = IBTDETL_STATUS_IND_NEW_0 
		LET pr_ibtdetl.req_num = NULL 
		LET pr_ibtdetl.req_line_num = NULL 
		INSERT INTO ibtdetl VALUES (pr_ibtdetl.*) 

		LET err_message = "Updating INPARMS record" 
		UPDATE inparms 
		SET next_trans_num = next_trans_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 

		## SOURCE
		LET err_message = "Source PRODSTATUS record" 
		DECLARE c4_prodstatus CURSOR FOR 
		SELECT * FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_ibthead.from_ware_code 
		AND part_code = pr_kithead.kit_code 
		FOR UPDATE 
		OPEN c4_prodstatus 
		FETCH c4_prodstatus INTO pr_prodstatus.* 
		IF status = notfound THEN 
			LET err_message = "Logic error: product STATUS NOT found" 
			GOTO recovery 
		END IF 
		IF pr_prodstatus.stocked_flag = "Y" THEN 
			LET pr_prodstatus.onhand_qty = 
			pr_prodstatus.onhand_qty - pr_compile_qty 
		ELSE 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 
		IF pr_prodstatus.wgted_cost_amt < 0 
		OR pr_prodstatus.wgted_cost_amt IS NULL THEN 
			LET pr_prodstatus.wgted_cost_amt = 0 
		END IF 
		LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
		UPDATE prodstatus 
		SET seq_num = pr_prodstatus.seq_num, 
		onhand_qty = pr_prodstatus.onhand_qty, 
		wgted_cost_amt = pr_prodstatus.wgted_cost_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_kithead.kit_code 
		AND ware_code = pr_ibthead.from_ware_code 
		IF sqlca.sqlerrd[3] != 1 THEN 
			LET err_message = "Logic error: product STATUS NOT updated" 
			GOTO recovery 
		END IF 

		LET err_message = "Source PRODLEDG record" 
		LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodledg.part_code = pr_kithead.kit_code 
		LET pr_prodledg.ware_code = pr_ibthead.from_ware_code 
		LET pr_prodledg.tran_date = today 
		LET pr_prodledg.tran_qty = 0 - pr_compile_qty 
		LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
		LET pr_prodledg.trantype_ind = "T"
		#  REVIEW: check which value should be set for source_code in that case
		LET pr_prodledg.source_code = ""
		LET pr_prodledg.source_text = pr_ibthead.to_ware_code 
		LET pr_prodledg.source_num = pr_ibthead.trans_num 
		LET pr_prodledg.jour_num = NULL 
		LET pr_prodledg.desc_text = "Transfer Kit - ",pr_kithead.kit_text 
		LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
		INSERT INTO prodledg VALUES (pr_prodledg.*) 


		## DESTINATION
		LET err_message = "Destination PRODSTATUS record" 
		DECLARE c3_prodstatus CURSOR FOR 
		SELECT * FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_ibthead.to_ware_code 
		AND part_code = pr_kithead.kit_code 
		FOR UPDATE 
		OPEN c3_prodstatus 
		FETCH c3_prodstatus INTO pr_prodstatus.* 
		IF status = notfound THEN 
			LET err_message = "Logic error: product STATUS NOT found" 
			GOTO recovery 
		END IF 
		IF pr_prodstatus.stocked_flag = "Y" THEN 
			LET pr_prodstatus.onhand_qty = 
			pr_prodstatus.onhand_qty + pr_compile_qty 
		ELSE 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 
		IF pr_prodstatus.wgted_cost_amt < 0 
		OR pr_prodstatus.wgted_cost_amt IS NULL THEN 
			LET pr_prodstatus.wgted_cost_amt = 0 
		END IF 
		LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
		UPDATE prodstatus 
		SET seq_num = pr_prodstatus.seq_num, 
		onhand_qty = pr_prodstatus.onhand_qty, 
		wgted_cost_amt = pr_prodstatus.wgted_cost_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_kithead.kit_code 
		AND ware_code = pr_ibthead.to_ware_code 
		IF sqlca.sqlerrd[3] != 1 THEN 
			LET err_message = "Logic error: product STATUS NOT updated" 
			GOTO recovery 
		END IF 

		LET err_message = "Destination PRODLEDG record" 
		LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodledg.part_code = pr_kithead.kit_code 
		LET pr_prodledg.ware_code = pr_ibthead.to_ware_code 
		LET pr_prodledg.tran_date = today 
		LET pr_prodledg.tran_qty = pr_compile_qty 
		LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
		LET pr_prodledg.trantype_ind = "T" 
		#  REVIEW: check which value should be set for source_code in that case
		LET pr_prodledg.source_code = ""
		LET pr_prodledg.source_text = pr_ibthead.from_ware_code 
		LET pr_prodledg.source_num = pr_ibthead.trans_num 
		LET pr_prodledg.jour_num = NULL 
		LET pr_prodledg.desc_text = "Transfer Kit - ",pr_kithead.kit_text 
		LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
		INSERT INTO prodledg VALUES (pr_prodledg.*) 

		## Serialinfo
		LET err_message = "SERIALINFO record" 
		UPDATE serialinfo 
		SET ware_code = pr_ibthead.to_ware_code, 
		trans_num = pr_ibthead.trans_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_kithead.kit_code 
		AND ware_code = pr_ibthead.from_ware_code 
		AND serial_code = pr_kit_serial 

		LET pr_kit_warehouse = pr_ibthead.to_ware_code 
		LET pr_prodledg.ware_code = pr_ibthead.from_ware_code 
	COMMIT WORK 
	RETURN true 
	WHENEVER ERROR stop 
END FUNCTION 


FUNCTION write_report() 

	LET err_message = "IK2 - Printing REPORT details" 

	SELECT count(*) 
	INTO pr_kit_lines 
	FROM kitdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND kit_code = pr_kithead.kit_code 

	OPEN c_kitdetl USING pr_kit_code 
	FOREACH c_kitdetl INTO pr_kitdetl.* 
		SELECT count(*) 
		INTO pr_serial_check 
		FROM kitserial 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND kit_code = pr_kithead.kit_code 
		AND kit_serial = pr_kit_serial 
		AND part_code = pr_kitdetl.part_code 

		IF pr_serial_check = 0 THEN 
			LET pr_kitserial.part_serial = NULL 
			OUTPUT TO REPORT IK2_rpt_list(pr_kithead.*, 
			pr_kitdetl.*, 
			pr_kitserial.*, 
			pr_kit_serial, 
			pr_kit_warehouse, 
			pr_kit_lines, 
			pr_doc_num, 
			pr_trans_num) 
		ELSE 
			DECLARE c1_kitserial CURSOR FOR 
			SELECT * 
			INTO pr_kitserial.* 
			FROM kitserial 
			WHERE kitserial.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND kitserial.kit_code = pr_kithead.kit_code 
			AND kitserial.kit_serial = pr_kit_serial 
			AND kitserial.part_code = pr_kitdetl.part_code 
			FOREACH c1_kitserial INTO pr_kitserial.* 
				OUTPUT TO REPORT IK2_rpt_list(pr_kithead.*, 
				pr_kitdetl.*, 
				pr_kitserial.*, 
				pr_kit_serial, 
				pr_kit_warehouse, 
				pr_kit_lines, 
				pr_doc_num, 
				pr_trans_num) 
			END FOREACH 
			CLOSE c1_kitserial 
		END IF 
	END FOREACH 
	CLOSE c_kitdetl 
END FUNCTION 


FUNCTION serial_number() 
	OPEN WINDOW i261 with FORM "I261" 
	 CALL windecoration_i("I261") -- albo kd-758 
	IF select_serial() THEN 
		IF NOT scan_serial() THEN 
			CLOSE WINDOW i261 
			RETURN false 
		ELSE 
			CLOSE WINDOW i261 
			RETURN true 
		END IF 
	ELSE 
		CLOSE WINDOW i261 
		RETURN false 
	END IF 
END FUNCTION 


FUNCTION select_serial() 
	DEFINE 
	pr_serial_flag LIKE product.serial_flag, 
	query_text CHAR(300), 
	where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag

	CLEAR FORM 
	LET l_msgresp=kandoomsg("I",1001,"") 
	#1001 Enter selection criteria - ESC TO Continue

	LET pr_serialinfo.serial_code = 0 

	DISPLAY BY NAME pr_productdetl.part_code, 
	pr_productdetl.desc_text, 
	pr_productdetl.desc2_text, 
	pr_prodledg.tran_qty, 
	pr_serial_qty 


	CONSTRUCT BY NAME where_text ON serial_code, 
	receipt_date, 
	vend_code , 
	ware_code, 
	po_num , 
	trantype_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IK2","construct-serial_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp=kandoomsg("I",1002,"") 
		LET query_text = "SELECT * FROM serialinfo ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND ware_code = '",pr_prodledg.ware_code,"' ", 
		" AND part_code = '",pr_productdetl.part_code, 
		"' AND trantype_ind = '0' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY serial_code" 
		PREPARE s_serial FROM query_text 
		DECLARE c_serial CURSOR FOR s_serial 
		RETURN true 
	END IF 
END FUNCTION 



FUNCTION scan_serial() 
	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_sto_serial_code LIKE serialinfo.serial_code, 
	pick_count SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	LET s_idx = 0 
	FOREACH c_serial INTO pr_serialinfo.* 
		LET s_idx = s_idx + 1 
		LET pa_serialinfo[s_idx].pick_flag = " " 
		LET pa_serialinfo[s_idx].serial_code = pr_serialinfo.serial_code 
		LET pa_serialinfo[s_idx].receipt_date = pr_serialinfo.receipt_date 
		LET pa_serialinfo[s_idx].vend_code = pr_serialinfo.vend_code 
		LET pa_serialinfo[s_idx].ware_code = pr_serialinfo.ware_code 
		LET pa_serialinfo[s_idx].po_num = pr_serialinfo.po_num 
		LET pa_serialinfo[s_idx].trantype_ind = pr_serialinfo.trantype_ind 
		IF s_idx > 300 THEN 
			LET l_msgresp = kandoomsg("U",6100,s_idx) 
			#6100 Only s_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(s_idx) 

	LET l_msgresp = kandoomsg("W",1102,'') 
	#1102 Enter on line TO assign serial no TO kit
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 

		BEFORE ROW 
			LET s_idx = arr_curr() 
			LET s_scrn = scr_line() 

		AFTER FIELD serial_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("I",9001,"") 
					#9001"There are no more rows in the direction you are go
					NEXT FIELD serial_code 
				END IF 
			END IF 

		ON KEY (tab) 
			IF pa_serialinfo[s_idx].pick_flag = " " THEN 
				LET pa_serialinfo[s_idx].pick_flag = "*" 
			ELSE 
				LET pa_serialinfo[s_idx].pick_flag = " " 
			END IF 
			DISPLAY pa_serialinfo[s_idx].pick_flag 
			TO sr_serialinfo[s_scrn].pick_flag 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON KEY (control-c) 
			LET int_flag = true 
			EXIT INPUT 
		AFTER INPUT 
			IF int_flag = false THEN 
				LET pick_count = 0 
				LET pick_idx = 0 
				FOR s_idx = 1 TO arr_count() 
					IF pa_serialinfo[s_idx].pick_flag = "*" THEN 
						LET pick_idx = s_idx 
						LET pick_count = pick_count + 1 
					END IF 
				END FOR 
				IF pick_count != pr_serial_qty THEN 
					LET l_msgresp = kandoomsg("I",9299,"") 
					NEXT FIELD pick_flag 
				END IF 
			END IF 
	END INPUT 

	LET int_flag = 0 
	LET quit_flag = 0 

	IF fgl_lastkey() = fgl_keyval("interrupt") THEN 
		RETURN false 
	END IF 

	IF fgl_lastkey() = fgl_keyval("accept") THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 

FUNCTION update_masterserial() 

	IF pr_serial_product = pr_kithead.serial_product THEN 
		SELECT * 
		INTO pr_productdetl.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_serial_product 
		LET pr_serial_qty = pr_prodledg.tran_qty 
		IF serial_number() THEN 
			SELECT * 
			INTO pr_serialinfo.* 
			FROM serialinfo 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_kithead.serial_product 
			AND serial_code = pa_serialinfo[pick_idx].serial_code 
			IF status = notfound THEN 
				RETURN false 
			ELSE 
				LET pr_kit_serial = pa_serialinfo[pick_idx].serial_code 
				LET pr_kitserial.cmpy_code = pr_serialinfo.cmpy_code 
				LET pr_kitserial.kit_code = pr_kithead.kit_code 
				LET pr_kitserial.kit_serial = pr_kit_serial 
				LET pr_kitserial.part_code = pr_serialinfo.part_code 
				LET pr_kitserial.part_serial = pr_serialinfo.serial_code 
				LET pr_kitserial.asset_num = pr_serialinfo.asset_num 
				LET pr_kitserial.vend_code = pr_serialinfo.vend_code 
				LET pr_kitserial.po_num = pr_serialinfo.po_num 
				LET pr_kitserial.receipt_date = pr_serialinfo.receipt_date 
				LET pr_kitserial.receipt_num = pr_serialinfo.receipt_num 
				INSERT INTO kitserial VALUES (pr_kitserial.*) 
				LET pr_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_serialinfo.part_code = pr_kithead.kit_code 
				LET pr_serialinfo.vend_code = pr_product.vend_code 
				LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
				LET pr_serialinfo.po_num = 0 
				LET pr_serialinfo.receipt_date = NULL 
				LET pr_serialinfo.receipt_num = 0 
				LET pr_serialinfo.cust_code = " " 
				LET pr_serialinfo.trans_num = 0 
				LET pr_serialinfo.ref_num = 0 
				LET pr_serialinfo.ship_date = NULL 
				LET pr_serialinfo.desc_text = "Assembled Kit FROM components" 
				LET pr_serialinfo.credit_num = 0 
				LET pr_serialinfo.trantype_ind = "0" 
				LET pr_serialinfo.asset_num = " " 
				LET pr_serialinfo.kit_code = pr_kithead.kit_code 
				INSERT INTO serialinfo VALUES (pr_serialinfo.*) 
				UPDATE serialinfo 
				SET trantype_ind = "K", 
				kit_code = pr_kithead.kit_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_productdetl.part_code 
				AND serial_code = pa_serialinfo[pick_idx].serial_code 
				LET pa_kitdetl[serial_idx].serial_entered = "Y" 
				DISPLAY pa_kitdetl[serial_idx].* TO sr_kitdetl[serial_idx].* 
			END IF 
		ELSE 
			RETURN false 
		END IF 
	ELSE 
		LET pr_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_serialinfo.part_code = pr_kithead.kit_code 
		LET pr_serialinfo.serial_code = pr_serial_product 
		LET pr_serialinfo.vend_code = pr_product.vend_code 
		LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
		LET pr_serialinfo.po_num = 0 
		LET pr_serialinfo.receipt_date = NULL 
		LET pr_serialinfo.receipt_num = 0 
		LET pr_serialinfo.cust_code = " " 
		LET pr_serialinfo.trans_num = 0 
		LET pr_serialinfo.ref_num = 0 
		LET pr_serialinfo.ship_date = NULL 
		LET pr_serialinfo.desc_text = "Assembled Kit FROM components" 
		LET pr_serialinfo.credit_num = 0 
		LET pr_serialinfo.trantype_ind = "0" 
		LET pr_serialinfo.asset_num = " " 
		LET pr_serialinfo.kit_code = pr_kithead.kit_code 
		INSERT INTO serialinfo VALUES (pr_serialinfo.*) 
		LET pr_kit_serial = pr_serialinfo.serial_code 
	END IF 
	RETURN true 

END FUNCTION 

FUNCTION update_kitserial() 

	# New kitserial records FOR the component poducts

	SELECT * INTO pr_serialinfo.* 
	FROM serialinfo 
	WHERE serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND serialinfo.part_code = pr_productdetl.part_code 
	AND serialinfo.serial_code = pa_serialinfo[s_idx].serial_code 

	LET pr_kitserial.cmpy_code = pr_serialinfo.cmpy_code 
	LET pr_kitserial.kit_code = pr_kithead.kit_code 
	LET pr_kitserial.kit_serial = pr_kit_serial 
	LET pr_kitserial.part_code = pr_serialinfo.part_code 
	LET pr_kitserial.part_serial = pr_serialinfo.serial_code 
	LET pr_kitserial.asset_num = pr_serialinfo.asset_num 
	LET pr_kitserial.vend_code = pr_serialinfo.vend_code 
	LET pr_kitserial.po_num = pr_serialinfo.po_num 
	LET pr_kitserial.receipt_date = pr_serialinfo.receipt_date 
	LET pr_kitserial.receipt_num = pr_serialinfo.receipt_num 

	INSERT INTO kitserial VALUES (pr_kitserial.*) 

	# Flag component serial numbers as belonging TO a kit

	UPDATE serialinfo 
	SET trantype_ind = "K", 
	kit_code = pr_kithead.kit_code 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_productdetl.part_code 
	AND serial_code = pa_serialinfo[s_idx].serial_code 

END FUNCTION 

REPORT IK2_rpt_list(pr_kithead, 
	pr_kitdetl, 
	pr_kitserial, 
	pr_kit_serial, 
	pr_kit_warehouse, 
	pr_kit_lines, 
	pr_doc_num, 
	pr_trans_num) 

	DEFINE pr_kithead RECORD LIKE kithead.* , 
	pr_kitdetl RECORD LIKE kitdetl.*, 
	pr_kitserial RECORD LIKE kitserial.*, 
	pr_kit_serial CHAR(20), 
	pr_kit_warehouse LIKE warehouse.ware_code, 
	pr_kit_lines SMALLINT, 
	pr_product RECORD LIKE product.*, 
	pa_line array[4] OF CHAR(132), 
	pr_doc_num INTEGER, 
	pr_trans_num LIKE ibthead.trans_num 

	OUTPUT left margin 1 

	ORDER external BY pr_kit_serial, 
	pr_kitdetl.kit_code, 
	pr_kitdetl.part_code, 
	pr_kitdetl.line_num 

	FORMAT 

		PAGE HEADER 

			LET glob_rec_rmsreps.page_num = pageno 
			CALL report5() 
			RETURNING pa_line[1], pa_line[2], pa_line[3], pa_line[4] 
			PRINT COLUMN 01, pa_line[1] 
			PRINT COLUMN 01, pa_line[2] 
			PRINT COLUMN 01, pa_line[3] 

		BEFORE GROUP OF pr_kit_serial 
			NEED pr_kit_lines LINES 
			SKIP 1 line 
			PRINT COLUMN 01,"Kit: ",pr_kithead.kit_code, 
			COLUMN 22, pr_kithead.kit_text, 
			COLUMN 53,"Warehouse: Parts ", 
			pr_prodledg.ware_code, 
			1 space, "Kit ", 
			pr_kit_warehouse, 
			COLUMN 82,"Adj No: ", 
			pr_doc_num USING "<<<<<<<&", 
			COLUMN 99, "Tfr No: ", 
			pr_trans_num USING "<<<<<<<&", 
			COLUMN 115,"Serial: ", pr_kit_serial 
			SKIP 1 line 

		ON EVERY ROW 

			SELECT * INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_kitdetl.part_code 

			IF pr_kitserial.part_serial IS NOT NULL 
			AND pr_kitserial.part_serial != " " THEN 
				LET pr_kitdetl.kit_qty = 1.00 
			END IF 

			PRINT COLUMN 15,pr_kitdetl.kit_qty USING "-&.&&"," x ", 
			COLUMN 24,pr_kitdetl.part_code, 
			2 spaces, pr_product.desc_text clipped, 
			2 spaces, pr_product.desc2_text clipped, 
			COLUMN 115,pr_kitserial.part_serial 

END REPORT