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

	Source code beautified by beautify.pl on 2020-01-03 09:12:44	$Id: $
}




# Verify the IN system, check all possibilities..........
#
# This Program Checks/Fixes AND outputs following error codes
#    - Error code 001 FOR corrupt prodstatus.back_qty
#    - Error code 002 FOR corrupt prodstatus.reserved_qty
#    - Error code 003 FOR corrupt prodstatus.onord_qty
#    - Error code 004 FOR corrupt prodstatus.onhand_qty
#    - Error code 005 FOR corrupt prodledg.tran_qty
#    - Error code 006 FOR corrupt prodledg.bal_amt
#
# All OUTPUT IS directed TO the RMS REPORT.
#
# IF a site IS performing a stocktake AND identify a product with a
# totally unreasonable variance it may be caused by a problem in the system.
# ie: running prodledg corrupted somehow,  ie: NULL transaction.  TO correct
# this problem but NOT invalidate the stocktake, this program checks TO see if
# a current stock take exists before doing the UPDATE. IF a current stock take
# does exist IS updates the before quantity of the stktakedetl.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	error_cnt INTEGER, 
	where_text CHAR(1000), 
	pr_page_num SMALLINT, 
	pr_output CHAR(80) 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("ISV") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	IF num_args() > 0 THEN 
		LET where_text = "1=1" 
		CALL verify(arg_val(1)) 
	ELSE 
		OPEN WINDOW i162 with FORM "I162" 
		 CALL windecoration_i("I162") -- albo kd-758 
		MENU " Verify IN " 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ISV","menu-Verify_IN-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Report" " Generate REPORT of inaccuracies" 
				CALL get_criteria("N") 
				NEXT option "Print Manager" 
			COMMAND "Complete" " Correct all inaccuracies" 
				CALL get_criteria("Y") 
				NEXT option "Print Manager" 
			COMMAND "Backorder" " Correct backorder AND reserve only " 
				CALL get_criteria("P") 
				NEXT option "Print Manager" 
			COMMAND "Sequence" " Correct product ledger sequence numbers" 
				CALL get_criteria("S") 
				NEXT option "Exit" 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print"  " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			COMMAND KEY("E",interrupt) "Exit" " Exit TO Menu" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW i162 
	END IF 
END MAIN 


FUNCTION get_criteria(pr_update_flag) 
	DEFINE 
	pr_update_flag CHAR(1) 

	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Seleciton Criteria; OK TO Continue
	CONSTRUCT BY NAME where_text ON prodstatus.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodstatus.status_ind, 
	prodstatus.ware_code, 
	prodstatus.onhand_qty, 
	prodstatus.reserved_qty, 
	prodstatus.back_qty, 
	prodstatus.forward_qty, 
	prodstatus.onord_qty, 
	prodstatus.bin1_text, 
	prodstatus.bin2_text, 
	prodstatus.bin3_text, 
	prodstatus.last_sale_date, 
	prodstatus.last_receipt_date, 
	prodstatus.stocked_flag, 
	prodstatus.stockturn_qty, 
	prodstatus.abc_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ISV","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	IF pr_update_flag = "S" THEN 
		CALL sequence_number() 
	ELSE 
		CALL verify(pr_update_flag) 
	END IF 
END FUNCTION 


FUNCTION verify(pr_update_flag) 
	DEFINE 
	pr_update_flag CHAR(1), 
	line_info CHAR(132), 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_rowid INTEGER, 
	onhand_bal_qty FLOAT, 
	query_text CHAR(2000), 
	pr_continue_flag SMALLINT, 
	check_back_qty,check_sched_qty,check_picked_qty, 
	b_check_back_qty,b_check_sched_qty,b_check_picked_qty, 
	t_check_back_qty,t_check_sched_qty,t_check_picked_qty, 
	check_conf_qty,check_qty FLOAT, 
	err_message CHAR(60) 

	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait
	LET error_cnt = 0 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"IN Verify Results") 
	LET pr_page_num = 0 
	START REPORT ver_list TO pr_output 
	########################
	###
	### Product Status
	###
	########################
	WHENEVER ERROR CONTINUE 
	CREATE INDEX isv_key ON orderdetl(part_code,ware_code,cmpy_code) 
	WHENEVER ERROR stop 
	LET query_text = 
	"SELECT prodstatus.* FROM prodstatus, product ", 
	" WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND prodstatus.cmpy_code = product.cmpy_code ", 
	" AND prodstatus.part_code = product.part_code ", 
	" AND ",where_text clipped," ", 
	" ORDER BY prodstatus.part_code" 
	--   OPEN WINDOW w1 AT 10,15 with 2 rows, 40 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	DISPLAY "Processing Product: " at 1,1 
	DISPLAY "Problems Found: " at 2,1 
	PREPARE s_prodstatus FROM query_text 
	DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
	FOREACH c_prodstatus INTO pr_prodstatus.* 
		DISPLAY "" at 1,21 
		DISPLAY pr_prodstatus.part_code at 1,21 

		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message, status) = "N" THEN 
			EXIT FOREACH 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			IF int_flag OR quit_flag THEN 
				IF kandoomsg("U",8503,"") = "N" THEN 
					#8503 Continue Report(Y/N)
					ROLLBACK WORK 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT FOREACH 
				END IF 
			END IF 
			###
			### Back Qty
			###
			IF pr_prodstatus.back_qty IS NULL THEN 
				LET pr_prodstatus.back_qty = 0 
				LET err_message = "Update Back Quantity (ISV)" 
				UPDATE prodstatus SET back_qty = 0 
				WHERE cmpy_code = pr_prodstatus.cmpy_code 
				AND part_code = pr_prodstatus.part_code 
				AND ware_code = pr_prodstatus.ware_code 
			END IF 
			SELECT sum(back_qty), 
			sum(sched_qty), 
			sum(picked_qty), 
			sum(conf_qty) 
			INTO check_back_qty, 
			check_sched_qty, 
			check_picked_qty, 
			check_conf_qty #not doing anything with this yet 
			FROM orderdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			AND (back_qty > 0 OR 
			sched_qty != 0 OR picked_qty != 0 OR conf_qty != 0) 
			IF check_back_qty IS NULL THEN 
				LET check_back_qty = 0 
			END IF 
			IF check_picked_qty IS NULL THEN 
				LET check_picked_qty = 0 
			END IF 
			IF check_sched_qty IS NULL THEN 
				LET check_sched_qty = 0 
			END IF 
			IF check_conf_qty IS NULL THEN 
				LET check_conf_qty = 0 
			END IF 
			SELECT sum(back_qty), 
			sum(sched_qty), 
			sum(picked_qty) 
			INTO b_check_back_qty, 
			b_check_sched_qty, 
			b_check_picked_qty 
			FROM orderline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			AND (back_qty > 0 OR 
			sched_qty != 0 OR picked_qty != 0 OR conf_qty != 0) 
			IF b_check_back_qty IS NULL THEN 
				LET b_check_back_qty = 0 
			END IF 
			IF b_check_picked_qty IS NULL THEN 
				LET b_check_picked_qty = 0 
			END IF 
			IF b_check_sched_qty IS NULL THEN 
				LET b_check_sched_qty = 0 
			END IF 
			SELECT sum(back_qty), 
			sum(sched_qty), 
			sum(picked_qty) 
			INTO t_check_back_qty, 
			t_check_sched_qty, 
			t_check_picked_qty 
			FROM ibtdetl, ibthead 
			WHERE ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ibtdetl.trans_num = ibthead.trans_num 
			AND part_code = pr_prodstatus.part_code 
			AND from_ware_code = pr_prodstatus.ware_code 
			AND (back_qty > 0 OR 
			sched_qty != 0 OR picked_qty != 0) 
			IF t_check_back_qty IS NULL THEN 
				LET t_check_back_qty = 0 
			END IF 
			IF t_check_picked_qty IS NULL THEN 
				LET t_check_picked_qty = 0 
			END IF 
			IF t_check_sched_qty IS NULL THEN 
				LET t_check_sched_qty = 0 
			END IF 
			LET check_qty = check_back_qty + b_check_back_qty+ t_check_back_qty 
			LET check_picked_qty = check_picked_qty + b_check_picked_qty 
			+ t_check_picked_qty 
			LET check_sched_qty = check_sched_qty + b_check_sched_qty 
			+ t_check_sched_qty 
			IF check_qty != pr_prodstatus.back_qty THEN 
				IF pr_update_flag <> "N" THEN 
					LET err_message = "Update Back Quantity 2 (ISV)" 
					UPDATE prodstatus SET back_qty = check_qty 
					WHERE cmpy_code = pr_prodstatus.cmpy_code 
					AND part_code = pr_prodstatus.part_code 
					AND ware_code = pr_prodstatus.ware_code 
				END IF 
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET line_info = 
					"Error 001 - Product:",pr_prodstatus.part_code," ", 
					"Ware:",pr_prodstatus.ware_code," - ", 
					"STATUS.back_qty != Sum(ORDER lines) - ", 
					pr_prodstatus.back_qty USING "<<<<<<.##"," != ", 
					check_qty USING "<<<<<<.##" 
					CALL prob(line_info) 
				END IF 
			END IF 
			IF int_flag OR quit_flag THEN 
				#8503 Continue Report(Y/N)
				IF kandoomsg("U",8503,"") = "N" THEN 
					ROLLBACK WORK 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT FOREACH 
				END IF 
			END IF 
			###
			### Reserved Qty
			###
			IF pr_prodstatus.reserved_qty IS NULL THEN 
				LET pr_prodstatus.reserved_qty = 0 
				LET err_message = "Update Reserved Quantity (ISV)" 
				UPDATE prodstatus SET reserved_qty = 0 
				WHERE cmpy_code = pr_prodstatus.cmpy_code 
				AND part_code = pr_prodstatus.part_code 
				AND ware_code = pr_prodstatus.ware_code 
			END IF 
			LET check_qty = check_sched_qty + check_picked_qty + check_conf_qty 
			IF check_qty != pr_prodstatus.reserved_qty THEN 
				IF pr_update_flag <> "N" THEN 
					LET err_message = "Update Reserved Quantity 2 (ISV)" 
					UPDATE prodstatus SET reserved_qty = check_qty 
					WHERE cmpy_code = pr_prodstatus.cmpy_code 
					AND part_code = pr_prodstatus.part_code 
					AND ware_code = pr_prodstatus.ware_code 
				END IF 
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET line_info = 
					"Error 002 - Product:",pr_prodstatus.part_code," ", 
					"Ware:",pr_prodstatus.ware_code," - ", 
					"STATUS.reserved_qty != Sum(ORDER lines) - ", 
					pr_prodstatus.reserved_qty USING "<<<<<<.##"," != ", 
					check_qty USING "<<<<<<.##" 
					CALL prob(line_info) 
				END IF 
			END IF 
			IF int_flag OR quit_flag THEN 
				#8503 Continue Report(Y/N)
				IF kandoomsg("U",8503,"") = "N" THEN 
					ROLLBACK WORK 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT FOREACH 
				END IF 
			END IF 
			IF pr_update_flag = "P" THEN 
			COMMIT WORK 
			CONTINUE FOREACH 
		END IF 
		###
		### Onord Qty
		###
		IF pr_prodstatus.onord_qty IS NULL THEN 
			LET pr_prodstatus.onord_qty = 0 
			LET err_message = "Update On Order Quantity (ISV)" 
			UPDATE prodstatus SET onord_qty = 0 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
		END IF 
		SELECT sum(poaudit.order_qty-poaudit.received_qty) INTO check_qty 
		FROM poaudit, purchdetl, purchhead 
		WHERE purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND purchhead.cmpy_code = purchdetl.cmpy_code 
		AND purchdetl.order_num = purchhead.order_num 
		AND purchdetl.ref_text = pr_prodstatus.part_code 
		AND purchdetl.type_ind = "I" 
		AND purchhead.ware_code = pr_prodstatus.ware_code 
		AND purchhead.cmpy_code = poaudit.cmpy_code 
		AND purchdetl.order_num = poaudit.po_num 
		AND purchdetl.line_num = poaudit.line_num 
		IF check_qty IS NULL THEN 
			LET check_qty = 0 
		END IF 
		IF check_qty != pr_prodstatus.onord_qty THEN 
			IF pr_update_flag = "Y" THEN 
				LET err_message = "Update On Order Quantity 2 (ISV)" 
				UPDATE prodstatus 
				SET onord_qty = check_qty 
				WHERE cmpy_code = pr_prodstatus.cmpy_code 
				AND part_code = pr_prodstatus.part_code 
				AND ware_code = pr_prodstatus.ware_code 
			END IF 
			IF pr_prodstatus.stocked_flag = "Y" THEN 
				LET line_info = 
				"Error 003 - Product:",pr_prodstatus.part_code," ", 
				"Ware:",pr_prodstatus.ware_code," - ", 
				"STATUS.onorded_qty != Sum(ORDER lines) - ", 
				pr_prodstatus.onord_qty USING "<<<<<<.##"," != ", 
				check_qty USING "<<<<<<.##" 
				CALL prob(line_info) 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				ROLLBACK WORK 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOREACH 
			END IF 
		END IF 
		###
		### Onhand Qty
		###
		IF pr_prodstatus.onhand_qty IS NULL THEN 
			LET pr_prodstatus.onhand_qty = 0 
			LET err_message = "Update On Hand Quantity (ISV)" 
			UPDATE prodstatus SET onhand_qty = 0 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
		END IF 
		########################
		###
		### Product Ledger
		###
		########################
		LET onhand_bal_qty = 0 
		DECLARE c_prodledg CURSOR FOR 
		SELECT rowid,prodledg.* 
		FROM prodledg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodstatus.part_code 
		AND ware_code = pr_prodstatus.ware_code 
		ORDER BY part_code,ware_code,seq_num 
		LET pr_continue_flag = true 
		FOREACH c_prodledg INTO pr_rowid, 
			pr_prodledg.* 
			IF int_flag OR quit_flag THEN 
				#8503 Continue Report(Y/N)
				IF kandoomsg("U",8503,"") = "N" THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET pr_continue_flag = false 
					EXIT FOREACH 
				END IF 
			END IF 
			IF onhand_bal_qty IS NULL THEN 
				LET onhand_bal_qty = 0 
			END IF 
			IF pr_prodledg.tran_qty IS NULL THEN 
				LET pr_prodledg.tran_qty = 0 
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET line_info = 
					"Error 004 - Product:",pr_prodstatus.part_code," ", 
					"Ware:",pr_prodstatus.ware_code," - ", 
					"Ledger transaction quantity IS NULL", 
					"Sequence :",pr_prodledg.seq_num 
					CALL prob(line_info) 
				END IF 
				IF pr_update_flag = "Y" THEN 
					LET err_message = "Update Transaction Quantity (ISV)" 
					UPDATE prodledg 
					SET tran_qty = pr_prodledg.tran_qty 
					WHERE rowid = pr_rowid 
				END IF 
			END IF 
			IF pr_prodledg.trantype_ind = "U" ## stock revaluation 
			OR pr_prodledg.trantype_ind = "W" ## wholesale tax value inclusion 
			OR pr_prodledg.trantype_ind IS NULL THEN 
				##
				## do NOT add qty FOR revaluation OR wholesale tax
				## as there IS no actual stock movement
				##
				LET onhand_bal_qty = onhand_bal_qty 
			ELSE 
				LET onhand_bal_qty = onhand_bal_qty + pr_prodledg.tran_qty 
			END IF 
			IF onhand_bal_qty != pr_prodledg.bal_amt 
			OR pr_prodledg.bal_amt IS NULL THEN 
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET line_info = 
					"Error 005 - Product:",pr_prodstatus.part_code," ", 
					"Ware:",pr_prodstatus.ware_code," - ", 
					"Running Ledger Balance Incorrect - ", 
					"Ledger Sequence:",pr_prodledg.seq_num," - ", 
					onhand_bal_qty USING "<<<<<<.##"," != ", 
					pr_prodledg.bal_amt USING "<<<<<<.##" 
					CALL prob(line_info) 
				END IF 
				IF pr_update_flag = "Y" THEN 
					LET err_message = "Update Balance Quantity (ISV)" 
					UPDATE prodledg 
					SET bal_amt = onhand_bal_qty 
					WHERE rowid = pr_rowid 
				END IF 
			END IF 
		END FOREACH 
		IF NOT pr_continue_flag THEN 
			ROLLBACK WORK 
			EXIT FOREACH 
		END IF 
		IF onhand_bal_qty != pr_prodstatus.onhand_qty THEN 
			IF pr_prodstatus.stocked_flag = "Y" THEN 
				LET line_info = 
				"Error 006 - Product:",pr_prodstatus.part_code," ", 
				"Ware:",pr_prodstatus.ware_code," - ", 
				"Onhand Quantity NOT equal Sum of Ledgers - ", 
				pr_prodstatus.onhand_qty USING "<<<<<<<<.##"," != ", 
				onhand_bal_qty USING "<<<<<<<<<<.##" 
				CALL prob(line_info) 
			END IF 
			IF pr_update_flag = "Y" THEN 
				LET err_message = "Update On Hand Quantity 2 (ISV)" 
				UPDATE prodstatus SET onhand_qty = onhand_bal_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_prodstatus.part_code 
				AND ware_code = pr_prodstatus.ware_code 
			END IF 
			##
			## This next UPDATE added FOR important reason.
			## Refer notes as start of source file.  SP.
			##
			##UPDATE stktakedetl
			##   SET onhand_qty = onhand_bal_qty
			## WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			##   AND part_code = pr_prodstatus.part_code
			##   AND ware_code = pr_prodstatus.ware_code
		END IF 
	COMMIT WORK 
END FOREACH 
--   CLOSE WINDOW w1  -- albo  KD-758
WHENEVER ERROR CONTINUE 
DROP INDEX isv_key 
WHENEVER ERROR stop 
CALL upd_reports(pr_output,pr_page_num,132,66) 
FINISH REPORT ver_list 
IF error_cnt > 0 THEN 
	IF pr_update_flag <> "N" THEN 
		LET msgresp = kandoomsg("I",7072,"") 
		#7072 Database Verified; Errors have been corrected.
	ELSE 
		LET msgresp = kandoomsg("I",7073,"") 
		#7073 Database Verified; Errors have been discovered.
	END IF 
ELSE 
	LET msgresp = kandoomsg("I",7074,"") 
	#7074 Database Verified;  No errors were discovered.
END IF 
END FUNCTION 


FUNCTION prob(line1) 
	DEFINE 
	line1 CHAR(132) 

	LET error_cnt = error_cnt + 1 
	DISPLAY error_cnt USING "<<<<<<" at 2,17 

	OUTPUT TO REPORT ver_list(line1) 
END FUNCTION 


REPORT ver_list(line_info) 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	rpt_note CHAR(100), 
	line_info CHAR(132), 
	offset1, offset2 SMALLINT, 
	line1 CHAR(132), 
	line2 CHAR(132) 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			LET pr_page_num = pageno 
			SELECT * INTO pr_company.* FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET line1 = pr_company.cmpy_code, " ", pr_company.name_text clipped 
			LET offset1 = (132 - length(line1))/2 
			PRINT COLUMN 1, today clipped, 
			COLUMN offset1, line1 clipped, 
			COLUMN (132 - 9), "Page: ", pageno USING "####" 
			LET rpt_note = "Inventory Verification Report (Menu ISV)" 
			LET line2 = rpt_note clipped 
			LET offset2 = (132 - length(line2))/2 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"------------" 
		ON EVERY ROW 
			PRINT COLUMN 1, line_info 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, "Total Problems: ", count(*) USING "###" 
			SKIP 1 line 
			PRINT COLUMN 50," ***** END OF REPORT ISV ***** " 
END REPORT 


FUNCTION sequence_number() 
	DEFINE 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	query_text CHAR(1500), 
	err_message CHAR(60), 
	idx, pr_rowid INTEGER, 
	pr_continue CHAR(1), 
	pr_bal_amt LIKE prodledg.bal_amt 

	OPEN WINDOW i704 with FORM "I704" 
	 CALL windecoration_i("I704") -- albo kd-758 
	LET msgresp = kandoomsg("U",1020,"Confirmation") 
	#1020 Enter Confirmation Details; OK TO Continue.
	INPUT BY NAME pr_continue 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISV","input-pr_continue-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 
	IF int_flag OR quit_flag 
	OR pr_continue = "N" THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW i704 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database, Please Wait.
	LET query_text = 
	"SELECT prodstatus.* FROM prodstatus, product ", 
	" WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND prodstatus.cmpy_code = product.cmpy_code ", 
	" AND prodstatus.part_code = product.part_code ", 
	" AND ",where_text clipped," ", 
	" ORDER BY prodstatus.part_code" 
	--   OPEN WINDOW w1 AT 10,15 with 2 rows, 40 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	DISPLAY "Processing Product: " at 1,1 
	PREPARE s2_prodstatus FROM query_text 
	DECLARE c2_prodstatus CURSOR with HOLD FOR s2_prodstatus 
	FOREACH c2_prodstatus INTO pr_prodstatus.* 
		GOTO bypass2 
		LABEL recovery2: 
		IF error_recover(err_message, status) = "N" THEN 
			EXIT FOREACH 
		END IF 
		LABEL bypass2: 
		BEGIN WORK 
			WHENEVER ERROR GOTO recovery2 
			DISPLAY "" at 1,21 
			DISPLAY pr_prodstatus.part_code at 1,21 

			LET err_message = "Error prevention UPDATE of sequence number" 
			UPDATE prodledg 
			SET seq_num = seq_num + 500000 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			DECLARE c2_prodledg CURSOR FOR 
			SELECT rowid,* FROM prodledg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			ORDER BY tran_date, seq_num 
			LET idx = 0 
			LET pr_bal_amt = 0 
			FOREACH c2_prodledg INTO pr_rowid,pr_prodledg.* 
				LET idx = idx + 1 
				IF pr_prodledg.tran_qty IS NULL THEN 
					LET pr_prodledg.tran_qty = 0 
				END IF 
				IF pr_prodledg.trantype_ind != "U" ## stock revaluation 
				AND pr_prodledg.trantype_ind != "W" ## wholesale tax value inclusion 
				AND pr_prodledg.trantype_ind IS NOT NULL THEN 
					LET pr_bal_amt = pr_bal_amt + pr_prodledg.tran_qty 
				END IF 
				LET err_message = "Updating prodledg sequence number" 
				UPDATE prodledg 
				SET seq_num = idx, 
				bal_amt = pr_bal_amt 
				WHERE rowid = pr_rowid 
			END FOREACH 
			UPDATE prodstatus 
			SET seq_num = idx 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			WHENEVER ERROR stop 
		COMMIT WORK 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF kandoomsg("U",8023,"") = "N" THEN 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-758
	CLOSE WINDOW i704 
END FUNCTION 
