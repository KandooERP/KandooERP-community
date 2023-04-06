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

	Source code beautified by beautify.pl on 2020-01-03 09:12:22	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I19  Product Bin Location Maintenance
#     This program allows the user TO maintain only product bin location
#     information.
#

GLOBALS 
	DEFINE 
	pa_prodstatus array[500] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		avail LIKE prodstatus.onhand_qty, 
		status_date LIKE prodstatus.status_date, 
		status_ind LIKE prodstatus.status_ind 
	END RECORD, 
	pr_opparms RECORD LIKE opparms.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_globalrec RECORD 
		parent_part_code LIKE product.part_code, 
		avail_qty LIKE prodstatus.onhand_qty, 
		favail_qty LIKE prodstatus.onhand_qty 
	END RECORD, 
	pr_backreas RECORD LIKE backreas.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_temp_text CHAR(40) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("I19") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT cal_available_flag 
	INTO pr_opparms.cal_available_flag 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 

	IF status = notfound THEN 
		LET pr_opparms.cal_available_flag = "N" 
	END IF 

	OPEN WINDOW i613 with FORM "I613" 
	 CALL windecoration_i("I613") -- albo kd-758 

	WHILE select_status() 
		CALL scan_status() 
	END WHILE 

	CLOSE WINDOW i613 
END MAIN 


FUNCTION select_status() 
	DEFINE 
	query_text CHAR(1500), 
	where_text CHAR(1200) 

	CLEAR FORM 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME where_text ON part_code, 
	ware_code, 
	onhand_qty, 
	reserved_qty, 
	status_date, 
	status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I19","construct-part_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("I",1002,"") 
	#1002 Searching database;  Please wait.
	LET query_text = "SELECT * FROM prodstatus ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY part_code,", 
	"ware_code" 
	PREPARE s_prodstatus FROM query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 
	RETURN true 
END FUNCTION 


FUNCTION scan_status() 
	DEFINE 
	pr_class RECORD LIKE class.*, 
	idx,scrn SMALLINT, 
	ps_prodstatus RECORD LIKE prodstatus.*, 
	pt_prodstatus RECORD LIKE prodstatus.*, 
	pr_flex_part LIKE product.part_code, 
	pr_flex_num INTEGER, 
	pr_counter, pr_part_length SMALLINT, 
	pr_part_search, 
	pr_part_code LIKE product.part_code, 
	pr_match_part LIKE product.part_code, 
	pr_class_code LIKE class.class_code, 
	err_message CHAR(40) 

	LET idx = 0 
	OPTIONS SQL interrupt ON 
	WHENEVER ERROR CONTINUE 
	FOREACH c_prodstatus INTO pr_prodstatus.* 
		LET idx = idx + 1 
		LET pa_prodstatus[idx].part_code = pr_prodstatus.part_code 
		LET pa_prodstatus[idx].ware_code = pr_prodstatus.ware_code 
		LET pa_prodstatus[idx].onhand_qty = pr_prodstatus.onhand_qty 
		LET pa_prodstatus[idx].reserved_qty = pr_prodstatus.reserved_qty 
		IF pr_opparms.cal_available_flag = "N" THEN 
			LET pa_prodstatus[idx].avail = pr_prodstatus.onhand_qty 
			- pr_prodstatus.reserved_qty 
			- pr_prodstatus.back_qty 
		ELSE 
			LET pa_prodstatus[idx].avail = pr_prodstatus.onhand_qty 
			- pr_prodstatus.reserved_qty 
		END IF 
		LET pa_prodstatus[idx].status_date = pr_prodstatus.status_date 
		LET pa_prodstatus[idx].status_ind = pr_prodstatus.status_ind 
		IF idx = 500 THEN 
			LET msgresp=kandoomsg("U",6100,idx) 
			#6100 First XXX records selected only.  More may be available.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	WHENEVER ERROR stop 
	OPTIONS SQL interrupt off 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 idx records selected.
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101 No records satisfied selection criteria.
		RETURN 
	END IF 
	CALL set_count(idx) 
	LET msgresp=kandoomsg("U",1059,"") 
	#1059 ENTER on line TO Edit;  OK TO Continue.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_prodstatus WITHOUT DEFAULTS FROM sr_prodstatus.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I19","input-pa_prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_prodstatus[idx].* TO sr_prodstatus[scrn].* 

			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_prodstatus[idx].part_code 
			DISPLAY BY NAME pr_product.desc_text, 
			pr_product.desc2_text 

		AFTER FIELD scroll_flag 
			LET pa_prodstatus[idx].scroll_flag = NULL 
			DISPLAY pa_prodstatus[idx].scroll_flag 
			TO sr_prodstatus[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD part_code 
			CALL initialize_globals(pa_prodstatus[idx].part_code, 
			pa_prodstatus[idx].ware_code) 
			OPEN WINDOW i614 with FORM "I614" 
			 CALL windecoration_i("I614") 
			WHILE edit_status() 
				IF update_prodstatus() THEN 
					## MESSAGE UPDATE worked
					EXIT WHILE 
				ELSE 
					CALL initialize_globals(pa_prodstatus[idx].part_code, 
					pa_prodstatus[idx].ware_code) 
				END IF 
			END WHILE 
			CLOSE WINDOW i614 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_prodstatus[idx].* TO sr_prodstatus[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION initialize_globals(pr_part_code,pr_ware_code) 
	DEFINE 
	pr_part_code LIKE prodstatus.part_code, 
	pr_flex_part LIKE prodstatus.part_code, 
	pr_ware_code LIKE prodstatus.ware_code, 
	x FLOAT 

	##
	## Setup product RECORD - used FOR read only
	##
	IF pr_part_code IS NOT NULL THEN 
		SELECT * INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("I",5010,"") 
			#5010 Logic error: Product code does NOT exist.
		END IF 
		CALL break_prod(glob_rec_kandoouser.cmpy_code,pr_product.part_code, 
		pr_product.class_code,1) 
		RETURNING pr_globalrec.parent_part_code, 
		pr_flex_part, 
		pr_temp_text, # do NOT require other 
		pr_temp_text # VALUES returned 
	END IF 
	##
	## Setup prodstatus RECORD - used FOR INSERT OR UPDATE
	##
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND ware_code = pr_ware_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I",9116,"") 
		#9116 Logic Error: Product STATUS RECORD NOT found.
	END IF 
	##
	## Setup warehouse RECORD - used FOR read only
	##
	SELECT desc_text INTO pr_warehouse.desc_text 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_prodstatus.ware_code 
	##
	## Setup backread RECORD - used FOR INSERT OR UPDATE
	##
	SELECT * INTO pr_backreas.* FROM backreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND ware_code = pr_ware_code 
	IF status = notfound THEN 
		LET pr_backreas.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_backreas.part_code = pr_prodstatus.part_code 
		LET pr_backreas.ware_code = pr_prodstatus.ware_code 
		LET pr_backreas.exp_date = NULL 
		LET pr_backreas.reason_text = NULL 
	END IF 
	IF pr_opparms.cal_available_flag = "N" THEN 
		LET pr_globalrec.avail_qty = pr_prodstatus.onhand_qty 
		- pr_prodstatus.reserved_qty 
		- pr_prodstatus.back_qty 
	ELSE 
		LET pr_globalrec.avail_qty = pr_prodstatus.onhand_qty 
		- pr_prodstatus.reserved_qty 
	END IF 
	LET pr_globalrec.favail_qty = pr_globalrec.avail_qty 
	+ pr_prodstatus.onord_qty 
	- pr_prodstatus.forward_qty 
END FUNCTION 


FUNCTION update_prodstatus() 
	DEFINE 
	err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		UPDATE prodstatus 
		SET bin1_text = pr_prodstatus.bin1_text, 
		bin2_text = pr_prodstatus.bin2_text, 
		bin3_text = pr_prodstatus.bin3_text 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodstatus.part_code 
		AND ware_code = pr_prodstatus.ware_code 
		IF sqlca.sqlerrd[3] != 1 THEN 
			LET err_message = "I16 - Status Update Unsuccessfull" 
			GOTO recovery 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 


FUNCTION edit_status() 
	CLEAR FORM 
	DISPLAY pr_product.desc_text, 
	pr_warehouse.desc_text, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_globalrec.avail_qty, 
	pr_globalrec.avail_qty, 
	pr_globalrec.favail_qty 
	TO product.desc_text, 
	warehouse.desc_text, 
	sr_stock[1].stock_uom_code, 
	sr_stock[2].stock_uom_code, 
	sr_stock[3].stock_uom_code, 
	sr_avail[1].avail_qty, 
	sr_avail[2].avail_qty, 
	favail_qty 

	LET msgresp=kandoomsg("U",1060,"bin location") 
	#1060 Enter bin location details;  OK TO Continue.
	DISPLAY BY NAME pr_prodstatus.part_code, 
	pr_prodstatus.ware_code, 
	pr_prodstatus.onhand_qty, 
	pr_prodstatus.reserved_qty, 
	pr_prodstatus.onord_qty, 
	pr_prodstatus.back_qty, 
	pr_prodstatus.forward_qty, 
	pr_prodstatus.reorder_point_qty, 
	pr_prodstatus.reorder_qty, 
	pr_prodstatus.max_qty, 
	pr_prodstatus.critical_qty, 
	pr_prodstatus.stocked_flag, 
	pr_prodstatus.nonstk_pick_flag, 
	pr_prodstatus.abc_ind, 
	pr_prodstatus.replenish_ind, 
	pr_prodstatus.last_sale_date, 
	pr_prodstatus.last_receipt_date, 
	pr_prodstatus.last_stcktake_date, 
	pr_backreas.exp_date, 
	pr_backreas.reason_text, 
	pr_prodstatus.stockturn_qty, 
	pr_prodstatus.avg_qty 

	INPUT BY NAME pr_prodstatus.bin1_text, 
	pr_prodstatus.bin2_text, 
	pr_prodstatus.bin3_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
			--- modif ericv init # AFTER INPUT
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
