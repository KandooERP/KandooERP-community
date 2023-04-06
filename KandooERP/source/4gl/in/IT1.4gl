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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IT1 - Create count file FOR stock take
#                This program inserts stock data INTO stktakedetl
#                FROM prodstatus AND UPDATE stktake with one header
#                FOR each cycle.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IT1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i224 with FORM "I224" 
	 CALL windecoration_i("I224") -- albo kd-758 

	MENU " Create Stocktake Entry File" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","IT1","menu-Create_Stocktake-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Run" " Create File" 
			CALL it1_query() 
			NEXT option "Exit" 
		COMMAND KEY("E",interrupt)"Exit" " Exit TO Menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW i224 
END MAIN 

FUNCTION it1_query() 
	DEFINE 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.*, 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_stktake RECORD LIKE stktake.*, 
	pr_inparms RECORD LIKE inparms.*, 
	sav_bin_text LIKE stktakedetl.bin_text, 
	err_message CHAR(60), 
	where_text CHAR(500), 
	query_text CHAR(1200), 
	pr_count_num INTEGER, 
	pr_error_num INTEGER, 
	pr_bin_select_text CHAR(80), 
	where_text1 CHAR(500), 
	i, j, x SMALLINT 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1312,"") 
	#1312 Enter Cycle Description
	INPUT BY NAME pr_stktake.desc_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT1","input-pr_stktake-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD desc_text 
			IF pr_stktake.desc_text = "" OR 
			pr_stktake.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("I",9084,"") 
				#9084 Description must be Entered
				NEXT FIELD desc_text 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET msgresp=kandoomsg("I",1001,"") 
	#I1001 Enter Selection Criteria - ESC TO run "
	##
	## CAUTION: there IS code below that will only work if
	## bin1_text IS the last field in the CONSTRUCT - do NOT move it!
	## (Check references TO pr_bin_select_text).
	##
	CONSTRUCT BY NAME where_text1 ON prodstatus.ware_code, 
	product.maingrp_code, 
	product.prodgrp_code, 
	prodstatus.part_code, 
	prodstatus.bin1_text, 
	prodstatus.onhand_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT1","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER CONSTRUCT 
			IF field_touched(prodstatus.bin1_text) THEN 
				LET pr_bin_select_text = get_fldbuf(prodstatus.bin1_text) 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END CONSTRUCT 
	##
	## CAUTION - see note above
	##
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET pr_count_num = 0 
	LET pr_error_num = 0 
	LET msgresp=kandoomsg("I",1002,"") 
	#I1002 Searching database please wait
	--   OPEN WINDOW w1_IT1 AT 16,15 with 1 rows,50 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	##
	## Extend any bin selection criteria TO all bin locations
	## Look FOR the string bin1_text AND assume all text AFTER that IS
	## the selection criteria TO be applied TO the other locations
	## CAUTION: this only works IF bin1_text IS the last field in the
	## construct.
	##
	IF pr_bin_select_text IS NOT NULL THEN 
		LET x = length(where_text1) 
		LET j = 0 
		IF x > 20 THEN 
			FOR i = 1 TO (x - 20) 
				IF where_text1[i,i+19] = "prodstatus.bin1_text" THEN 
					LET j = i+20 ## criteria START point 
					IF i > 1 THEN 
						LET where_text = where_text1[1,i-1], " (", 
						where_text1[i,x] 
					ELSE 
						LET where_text = "(", where_text1 clipped 
					END IF 
					LET where_text = where_text clipped, 
					" OR prodstatus.bin2_text", where_text1[j,x] clipped, 
					" OR prodstatus.bin3_text", where_text1[j,x] clipped, ")" 
					EXIT FOR 
				END IF 
			END FOR 
		END IF 
		IF j= 0 THEN ## bin location criteria NOT found 
			LET where_text = where_text1 
		END IF 
	ELSE 
		LET where_text = where_text1 
	END IF 
	LET query_text = "SELECT prodstatus.*,product.maingrp_code,", 
	"product.prodgrp_code ", 
	"FROM prodstatus, product ", 
	"WHERE prodstatus.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.serial_flag = 'N' ", 
	"AND prodstatus.stocked_flag='Y' ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND prodstatus.ware_code IS NOT NULL ", 
	"AND prodstatus.status_ind != '3' ", 
	"AND ",where_text clipped," " 
	PREPARE s_prodstatus FROM query_text 
	DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
	GOTO bypass1 
	LABEL recovery1: 
	IF error_recover(err_message,status) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 
	BEGIN WORK 
		SELECT cycle_num INTO pr_stktake.cycle_num FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		UPDATE inparms 
		SET cycle_num = cycle_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_stktake.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_stktake.status_ind = "0" 
		LET pr_stktake.cycle_num = pr_stktake.cycle_num + 1 
		LET pr_stktake.start_date = today 
		LET pr_stktake.total_parts_num = 0 
		LET pr_stktake.total_onhand_qty = 0 
		INSERT INTO stktake VALUES (pr_stktake.*) 
	COMMIT WORK 
	WHENEVER ERROR stop 
	FOREACH c_prodstatus INTO pr_prodstatus.*, 
		pr_product.maingrp_code, 
		pr_product.prodgrp_code 
		SELECT unique 1 FROM stktakedetl 
		WHERE cmpy_code = pr_prodstatus.cmpy_code 
		AND ware_code = pr_prodstatus.ware_code 
		AND part_code = pr_prodstatus.part_code 
		IF status = 0 THEN 
			LET pr_error_num = pr_error_num + 1 
			CONTINUE FOREACH 
		END IF 
		LET pr_count_num = pr_count_num + 1 
		DISPLAY " Product: ",pr_prodstatus.part_code at 1,1 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET pr_count_num = 0 
				LET pr_error_num = 0 
				LET msgresp=kandoomsg("U",9501,"") 
				DELETE FROM stktakedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = pr_stktake.cycle_num 
				UPDATE stktake 
				SET status_ind = "0" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = pr_stktake.cycle_num 
				EXIT FOREACH 
			END IF 
		END IF 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message,status) != "Y" THEN 
			EXIT FOREACH 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET pr_stktakedetl.cmpy_code = pr_prodstatus.cmpy_code 
			LET pr_stktakedetl.cycle_num = pr_stktake.cycle_num 
			LET pr_stktakedetl.part_code = pr_prodstatus.part_code 
			LET pr_stktakedetl.ware_code = pr_prodstatus.ware_code 
			LET pr_stktakedetl.maingrp_code = pr_product.maingrp_code 
			LET pr_stktakedetl.prodgrp_code = pr_product.prodgrp_code 
			IF pr_prodstatus.onhand_qty IS NULL THEN 
				LET pr_prodstatus.onhand_qty = 0 
			END IF 
			LET pr_stktakedetl.onhand_qty = pr_prodstatus.onhand_qty 
			LET pr_stktakedetl.count_qty = 0 
			LET pr_stktakedetl.posted_flag = "N" 
			LET pr_stktakedetl.entry_person = glob_rec_kandoouser.sign_on_code 
			LET pr_stktakedetl.entered_date = today 
			LET pr_stktakedetl.posted_date = NULL 
			LET sav_bin_text = " " 
			IF pr_prodstatus.bin1_text IS NOT NULL THEN 
				IF pr_prodstatus.bin1_text != " " THEN 
					LET sav_bin_text = pr_prodstatus.bin1_text 
					LET pr_stktakedetl.bin_text = pr_prodstatus.bin1_text 
					INSERT INTO stktakedetl VALUES (pr_stktakedetl.*) 
					LET pr_stktakedetl.onhand_qty = 0 
				END IF 
			END IF 
			IF pr_prodstatus.bin2_text IS NOT NULL THEN 
				IF pr_prodstatus.bin2_text != " " 
				AND (pr_prodstatus.bin1_text IS NULL 
				OR pr_prodstatus.bin2_text != pr_prodstatus.bin1_text) THEN 
					LET sav_bin_text = pr_prodstatus.bin2_text 
					LET pr_stktakedetl.bin_text = pr_prodstatus.bin2_text 
					INSERT INTO stktakedetl VALUES (pr_stktakedetl.*) 
					LET pr_stktakedetl.onhand_qty = 0 
				END IF 
			END IF 
			IF pr_prodstatus.bin3_text IS NOT NULL THEN 
				IF pr_prodstatus.bin3_text != " " 
				AND (pr_prodstatus.bin1_text IS NULL OR 
				pr_prodstatus.bin3_text != pr_prodstatus.bin1_text) 
				AND (pr_prodstatus.bin2_text IS NULL OR 
				pr_prodstatus.bin3_text != pr_prodstatus.bin2_text) THEN 
					LET sav_bin_text = pr_prodstatus.bin3_text 
					LET pr_stktakedetl.bin_text = pr_prodstatus.bin3_text 
					INSERT INTO stktakedetl VALUES (pr_stktakedetl.*) 
					LET pr_stktakedetl.onhand_qty = 0 
				END IF 
			END IF 
			IF sav_bin_text = " " THEN 
				LET pr_stktakedetl.bin_text = sav_bin_text 
				INSERT INTO stktakedetl VALUES (pr_stktakedetl.*) 
				LET pr_stktakedetl.onhand_qty = 0 
			END IF 
			LET pr_prodstatus.phys_count_qty = pr_prodstatus.onhand_qty 
			UPDATE prodstatus 
			SET phys_count_qty = pr_prodstatus.phys_count_qty 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			UPDATE stktake 
			SET status_ind = "1", 
			total_parts_num = total_parts_num + 1, 
			total_onhand_qty = total_onhand_qty + 
			pr_prodstatus.phys_count_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = pr_stktake.cycle_num 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END FOREACH 
	--   CLOSE WINDOW w1_IT1  -- albo  KD-758
	IF pr_error_num != 0 THEN 
		LET msgresp=kandoomsg("I",7051,pr_error_num) 
		#I7051 Products that exist in another stock take cycle:
	END IF 
	IF pr_count_num != 0 THEN 
		LET msgresp=kandoomsg("I",7050,pr_stktake.cycle_num) 
		#I7050 Successful generation of stock take cycle number:
		CALL run_prog("IT2","","","","") 
	END IF 
END FUNCTION 
