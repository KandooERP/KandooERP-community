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

	Source code beautified by beautify.pl on 2020-01-03 09:12:45	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#Stocktake Reversal Program
# This Program reverses posted stocktake adjustments FOR a selected
# stocktake cycle by inserting another adjustment entry INTO the prodledg
# table AND also adjusts the prodstatus table onhand quantity too.

GLOBALS 
	DEFINE 
	where_text CHAR(200), 
	query_text CHAR(500), 
	pr_fifo_lifo_ind LIKE inparms.cost_ind 

END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IT7") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT cost_ind INTO pr_fifo_lifo_ind 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = '1' 

	OPEN WINDOW i658 with FORM "I658" 
	 CALL windecoration_i("I658") -- albo kd-758 

	SELECT unique 1 FROM stktake 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND status_ind = "3" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",9262,"") 
		#9262 There are no stocktakes posted - Refer IT6
		EXIT program 
	END IF 
	WHILE select_cycle() 
		CALL scan_cycle() 
	END WHILE 
	CLOSE WINDOW i658 
END MAIN 


FUNCTION select_cycle() 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_text ON cycle_num, 
	desc_text, 
	completion_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT7","construct-cycle_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 Searching database - please wait
		LET query_text = "SELECT * FROM stktake ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND status_ind = '3' ", 
		"AND ", where_text clipped," ", 
		"ORDER BY cycle_num" 
		PREPARE s_stktake FROM query_text 
		DECLARE c_stktake CURSOR FOR s_stktake 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_cycle() 
	DEFINE 
	pa_stktake array[400] OF RECORD 
		scroll_flag CHAR(1), 
		cycle_num LIKE stktake.cycle_num, 
		desc_text LIKE stktake.desc_text, 
		completion_date LIKE stktake.completion_date 
	END RECORD, 
	pr_stktake RECORD LIKE stktake.*, 
	idx,scrn INTEGER 

	LET idx = 0 
	FOREACH c_stktake INTO pr_stktake.* 
		LET idx = idx + 1 
		LET pa_stktake[idx].cycle_num = pr_stktake.cycle_num 
		LET pa_stktake[idx].desc_text = pr_stktake.desc_text 
		LET pa_stktake[idx].completion_date = pr_stktake.completion_date 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	IF idx = 0 THEN 
		LET idx=1 
		INITIALIZE pa_stktake[idx].* TO NULL 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("I",1316,"") 
	#I1316 Press RETURN on line TO ....
	INPUT ARRAY pa_stktake WITHOUT DEFAULTS FROM sr_stktake.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT7","input-arr-pa_stktake-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			#IF arr_curr() > arr_count() THEN
			#   LET msgresp = kandoomsg("I",9001,"")
			#   #I9001 No more rows in the direction you are going
			#END IF
			IF pa_stktake[idx].cycle_num IS NOT NULL THEN 
				DISPLAY pa_stktake[idx].* TO sr_stktake[scrn].* 

			END IF 
		AFTER FIELD scroll_flag 
			DISPLAY pa_stktake[idx].* TO sr_stktake[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_stktake[idx+1].cycle_num IS NULL THEN 
					LET msgresp=kandoomsg("E",9001,"") 
					#9001 There are no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD desc_text 
			IF pa_stktake[idx].cycle_num IS NULL THEN 
				LET msgresp=kandoomsg("I",9263,"") 
				#9263 No stocktake cycle IS currently selected
			ELSE 
				### Do you wish TO reverse Stocktake Cycle 999 (Y/N)
				IF kandoomsg("I",8041,pa_stktake[idx].cycle_num) = "Y" THEN 
					LET msgresp = kandoomsg("I",1002,"") 
					#1002 Searching database - please wait
					CALL reverse_stocktake(pa_stktake[idx].cycle_num) 
					LET msgresp=kandoomsg("I",7065,pa_stktake[idx].cycle_num) 
					# 7065 Stocktake Cycle 999 Reversal Complete - AKTC
				ELSE 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


FUNCTION reverse_stocktake(pr_cycle_num) 
	DEFINE 
	pr_cycle_num LIKE stktake.cycle_num, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	err_message CHAR(100), 
	pr_calc_status SMALLINT, 
	pr_db_status INTEGER, 
	pr_fifo_lifo_cost LIKE prodledg.cost_amt 

	########################################################################
	# Process Description
	########################################################################
	# 1. SELECT each of the adjustment entries in the prodledg defined by
	#    the criteria of the stktake record
	# 2. FOREACH of 1. prodledg records retrieved
	#    - collect the next sequence number FOR the adjustment entry
	#      FROM the prodstatus table AND UPDATE
	#    - DISPLAY out TO errorlog the rows being processed
	#    - PREPARE the prodledg RECORD AND INSERT INTO the prodledg table
	#    - DISPLAY out TO errorlog the rows being processed
	########################################################################

	--   OPEN WINDOW w1 AT 10,10 with 2 rows, 40 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	DISPLAY "Warehouse : " at 1,1 
	DISPLAY "Product : " at 2,1 
	WHENEVER ERROR GOTO recovery 
	GOTO bypass 
	LABEL recovery: 
	LET msgresp = kandoomsg("I",9264,"") 
	#I9264 - Stocktake Reversal has been ...
	ROLLBACK WORK 
	SLEEP 4 
	EXIT program 
	LABEL bypass: 
	BEGIN WORK 
		DECLARE c_prodledg CURSOR with HOLD FOR 
		SELECT * FROM prodledg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND source_num = pr_cycle_num 
		AND source_text matches "Stck.Tak*" 
		AND trantype_ind = "A" 
		AND post_flag != "Y" 
		FOREACH c_prodledg INTO pr_prodledg.* 
			DISPLAY pr_prodledg.ware_code at 1,13 
			DISPLAY pr_prodledg.part_code at 2,13 
			###-Collect the next sequence number
			DECLARE c_prodstatus CURSOR FOR 
			SELECT * 
			FROM prodstatus 
			WHERE part_code = pr_prodledg.part_code 
			AND ware_code = pr_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			OPEN c_prodstatus 
			FETCH c_prodstatus INTO pr_prodstatus.* 
			###-Prepare AND INSERT the prodledg adjustment row
			LET pr_prodledg.seq_num = pr_prodstatus.seq_num + 1 
			LET pr_prodledg.source_text = "IT7-RevEntry" 
			LET pr_prodledg.tran_qty = 0 - pr_prodledg.tran_qty 
			LET pr_prodledg.hist_flag = "N" 
			LET pr_prodledg.post_flag = "N" 
			LET pr_prodledg.jour_num = 0 
			LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty + pr_prodledg.tran_qty 
			LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_prodledg.entry_date = today 
			LET pr_prodledg.tran_date = today 
			#
			# IF FIFO/LIFO costing IS implemented, CALL the fifo/lifo cost
			# calculation using UPDATE mode TO retrieve the cost AT which
			# this adjustment will be valued WHEN the adjustment IS posted AND TO
			# adjust the cost ledger entries.  IF the adjustment IS -ve, it will be
			# treated as an issue, IF +ve it will be treated as a receipt AND
			# valued AT last actual cost.
			#
			IF pr_fifo_lifo_ind matches "[FL]" THEN 
				IF pr_prodledg.tran_qty <= 0 THEN 
					CALL fifo_lifo_issue(glob_rec_kandoouser.cmpy_code, 
					pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pr_prodledg.tran_date, 
					pr_prodledg.seq_num, 
					pr_prodledg.trantype_ind, 
					(0 - pr_prodledg.tran_qty), 
					pr_fifo_lifo_ind, 
					true) 
					RETURNING pr_calc_status, 
					pr_db_status, 
					pr_fifo_lifo_cost 
					IF pr_calc_status = false THEN 
						LET status = pr_db_status 
						GO TO recovery 
					END IF 
					LET pr_prodledg.cost_amt = pr_fifo_lifo_cost 
				ELSE 
					LET pr_prodledg.cost_amt = pr_prodstatus.act_cost_amt 
					CALL fifo_lifo_receipt(glob_rec_kandoouser.cmpy_code, 
					pr_prodledg.part_code, 
					pr_prodledg.ware_code, 
					pr_prodledg.tran_date, 
					pr_prodledg.seq_num, 
					pr_prodledg.trantype_ind, 
					pr_prodledg.tran_qty, 
					pr_fifo_lifo_ind, 
					pr_prodledg.cost_amt) 
					RETURNING pr_calc_status, 
					pr_db_status 
					IF pr_calc_status = false THEN 
						LET status = pr_db_status 
						GO TO recovery 
					END IF 
				END IF 
			END IF 
			###-Insert the adjustment prodledg record
			LET err_message = "Insert INTO prodledg failed" 
			INSERT INTO prodledg VALUES (pr_prodledg.*) 
			LET err_message = "Update prodstatus failed" 
			UPDATE prodstatus 
			SET seq_num = seq_num + 1, 
			onhand_qty = onhand_qty + pr_prodledg.tran_qty 
			WHERE part_code = pr_prodledg.part_code 
			AND ware_code = pr_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END FOREACH 
		### Finally UPDATE the stocktake cycle TO indicate the reversal complete
		LET err_message = "Update stktake failed" 
		UPDATE stktake 
		SET status_ind = '4' 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = pr_cycle_num 
	COMMIT WORK 
	--   CLOSE WINDOW w1  -- albo  KD-758
END FUNCTION 
