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

	Source code beautified by beautify.pl on 2020-01-03 09:12:27	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#Stock Transfer Sub-Module

GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	from_ware_text,to_ware_text LIKE warehouse.desc_text, 
	where_text,query_text CHAR(500), 
	frm_label CHAR(12), 
	pr_resp,tr_cnt INTEGER 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I55") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET frm_label = "Inquiry" 
	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL query_menu() 
END MAIN 


FUNCTION select_transfer() 
	CLEAR FORM 
	DISPLAY BY NAME frm_label 
	IF num_args() != 0 THEN 
		LET where_text = " ibthead.trans_num = '", arg_val(1), "' " 
	ELSE 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter criteria FOR selection - ESC TO begin search"
		CONSTRUCT BY NAME where_text ON ibthead.trans_num, 
		ibthead.desc_text, 
		ibthead.from_ware_code, 
		ibthead.to_ware_code, 
		ibthead.trans_date, 
		ibthead.year_num, 
		ibthead.period_num, 
		ibthead.sched_ind, 
		ibthead.status_ind, 
		ibtdetl.line_num, 
		ibtdetl.part_code, 
		ibtdetl.trf_qty, 
		ibtdetl.sched_qty, 
		ibtdetl.picked_qty, 
		ibtdetl.conf_qty, 
		ibtdetl.rec_qty, 
		ibtdetl.back_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","I55","construct-ibthead-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	END IF 
	LET query_text = "SELECT ibthead.*,ibtdetl.* FROM ibthead,ibtdetl ", 
	" WHERE ibtdetl.trans_num = ibthead.trans_num ", 
	" AND ibtdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ibthead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ", where_text clipped , " ", 
	" ORDER BY ibthead.trans_num, ibtdetl.line_num" 
	PREPARE s_transfer FROM query_text 
	DECLARE c_transfer SCROLL CURSOR FOR s_transfer 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait
	OPEN c_transfer 
	FETCH FIRST c_transfer INTO pr_ibthead.*,pr_ibtdetl.* 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9024,"") 
		#9024 No Records Found"
		RETURN false 
	END IF 
	RETURN display_ibthead_record(pr_ibthead.*,pr_ibtdetl.*) 
END FUNCTION 


FUNCTION query_menu() 
	OPEN WINDOW i663 with FORM "I663" 
	 CALL windecoration_i("I663") -- albo kd-758 
	DISPLAY BY NAME frm_label 
	MENU " Stock Transfers" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","I55","menu-Stock_Transfers-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			IF num_args() != 0 THEN 
				IF select_transfer() THEN 
					FETCH FIRST c_transfer INTO pr_ibthead.*, pr_ibtdetl.* 
					HIDE option "Query" 
				END IF 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "Detail" 
				HIDE option "First" 
				HIDE option "Last" 
			END IF 

		COMMAND "Query" " SELECT criteria" 
			WHENEVER ERROR CONTINUE 
			CLOSE c_transfer 
			WHENEVER ERROR stop 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Detail" 
			HIDE option "First" 
			HIDE option "Last" 
			IF select_transfer() THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "Detail" 
				SHOW option "First" 
				SHOW option "Last" 
				NEXT option "Next" 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("N",f21) "Next" " View Next Record" 
			FETCH NEXT c_transfer INTO pr_ibthead.*,pr_ibtdetl.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9157,"") 
				#9157 You have reached the END of entries selected.
			ELSE 
				LET pr_resp = display_ibthead_record(pr_ibthead.*,pr_ibtdetl.*) 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("P",f19) "Previous" " View Previous Record" 
			FETCH previous c_transfer INTO pr_ibthead.*,pr_ibtdetl.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected.
			ELSE 
				LET pr_resp = display_ibthead_record(pr_ibthead.*,pr_ibtdetl.*) 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("D",f20) "Detail" " View Delivery Details" 
			CALL transdet() 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("F",f18) "First" " View First Record" 
			FETCH FIRST c_transfer INTO pr_ibthead.*,pr_ibtdetl.* 
			LET pr_resp = display_ibthead_record(pr_ibthead.*,pr_ibtdetl.*) 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("L",f22) "Last" " View Last Record" 
			FETCH LAST c_transfer INTO pr_ibthead.*,pr_ibtdetl.* 
			LET pr_resp = display_ibthead_record(pr_ibthead.*,pr_ibtdetl.*) 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW i663 
END FUNCTION 


FUNCTION transdet() 
	DEFINE 
	pa_ordmenu array[20] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD, 
	runner CHAR(100), 
	idx,scrn,i SMALLINT 

	LET idx = 0 
	FOR i = 1 TO 2 
		CASE i 
			WHEN "1" ## delivery details 
				IF pr_company.module_text[23] = 'W' THEN 
					LET idx = 1 
					LET pa_ordmenu[idx].option_num = "1" 
					LET pa_ordmenu[idx].option_text = "Deliveries" 
				END IF 
			WHEN "2" ## receipt details 
				LET idx = idx + 1 
				LET pa_ordmenu[idx].option_num = "2" 
				LET pa_ordmenu[idx].option_text = "Receipts" 
		END CASE 
	END FOR 
	OPEN WINDOW i675 with FORM "I675" 
	 CALL windecoration_i("I675") -- albo kd-758 
	DISPLAY BY NAME pr_ibthead.trans_num, 
	pr_ibthead.to_ware_code, 
	pr_ibthead.from_ware_code 

	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET msgresp=kandoomsg("W",1054,"") 
	#1054 Enter TO SELECT option.
	INPUT ARRAY pa_ordmenu WITHOUT DEFAULTS FROM sr_ordmenu.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I55","input-pa_ordmenu-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_ordmenu[idx].* 
			TO sr_ordmenu[scrn].* 

		AFTER FIELD scroll_flag 
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD option_num
			--#END IF
			IF pa_ordmenu[idx].scroll_flag IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD option_num 
			IF pa_ordmenu[idx].scroll_flag IS NULL THEN 
				LET pa_ordmenu[idx].scroll_flag = pa_ordmenu[idx].option_num 
			ELSE 
				LET i = 1 
				WHILE (pa_ordmenu[idx].scroll_flag IS NOT null) 
					IF pa_ordmenu[i].option_num IS NULL THEN 
						LET pa_ordmenu[idx].scroll_flag = NULL 
					ELSE 
						IF pa_ordmenu[idx].scroll_flag= 
						pa_ordmenu[i].option_num THEN 
							EXIT WHILE 
						END IF 
					END IF 
					LET i = i + 1 
				END WHILE 
			END IF 
			CASE pa_ordmenu[idx].scroll_flag 
				WHEN "1" 
					CALL disp_trdeliv(glob_rec_kandoouser.cmpy_code, pr_ibthead.trans_num) 
				WHEN "2" 
					CALL disp_trrecp() 
			END CASE 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET pa_ordmenu[idx].scroll_flag = NULL 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ordmenu[idx].* 
			TO sr_ordmenu[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i675 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION disp_trdeliv(p_cmpy, pr_trans_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_trans_num LIKE ibthead.trans_num, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pa_delivhead array[500] OF RECORD 
		del_num LIKE delivhead.del_num, 
		pick_date LIKE delivhead.pick_date, 
		del_type CHAR(3), 
		pick_num LIKE delivhead.pick_num, 
		cancel_ind CHAR(1) 
	END RECORD, 
	idx SMALLINT 

	SELECT * INTO pr_ibthead.* FROM ibthead 
	WHERE trans_num = pr_trans_num 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW i676 with FORM "I676" 
	 CALL windecoration_i("I676") -- albo kd-758 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait.
	DISPLAY BY NAME pr_ibthead.from_ware_code, 
	pr_ibthead.to_ware_code, 
	pr_ibthead.trans_num 

	DECLARE c_delivhead CURSOR FOR 
	SELECT * FROM delivhead 
	WHERE trans_num = pr_ibthead.trans_num 
	AND del_type_ind = 3 
	AND cmpy_code = p_cmpy 
	ORDER BY del_num 
	LET idx = 0 
	FOREACH c_delivhead INTO pr_delivhead.* 
		LET idx = idx + 1 
		LET pa_delivhead[idx].del_num = pr_delivhead.del_num 
		LET pa_delivhead[idx].pick_date = pr_delivhead.pick_date 
		LET pa_delivhead[idx].del_type = pr_delivhead.transp_type_code 
		LET pa_delivhead[idx].pick_num = pr_delivhead.pick_num 
		IF pr_delivhead.status_ind = "9" THEN 
			LET pa_delivhead[idx].cancel_ind = "*" 
		END IF 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1007,"") 
	#1007  RETURN on line TO view
	DISPLAY ARRAY pa_delivhead TO sr_delivhead.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I55","display-arr-delivhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (tab) 
			LET idx = arr_curr() 
			IF pa_delivhead[idx].del_num <> 0 
			AND pa_delivhead[idx].del_num IS NOT NULL THEN 
				CALL disp_unconf(pa_delivhead[idx].pick_num) 
			END IF 
		ON KEY (RETURN) 
			LET idx = arr_curr() 
			IF pa_delivhead[idx].del_num <> 0 
			AND pa_delivhead[idx].del_num IS NOT NULL THEN 
				CALL disp_unconf(pa_delivhead[idx].pick_num) 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	CLOSE WINDOW i676 
END FUNCTION 


FUNCTION disp_unconf(pr_pick_num) 
	DEFINE 
	pr_pick_num LIKE delivhead.del_num, 
	pr_product RECORD LIKE product.*, 
	pr_delivdetl RECORD LIKE delivdetl.*, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pr_transptype RECORD LIKE transptype.*, 
	pa_delivdetl array[500] OF RECORD 
		pick_line_num LIKE delivdetl.pick_line_num, 
		part_code LIKE delivdetl.part_code, 
		desc_text LIKE product.desc_text, 
		picked_qty LIKE delivdetl.picked_qty, 
		desc2_text LIKE product.desc2_text 
	END RECORD, 
	idx SMALLINT 

	SELECT * INTO pr_delivhead.* FROM delivhead 
	WHERE pick_num = pr_pick_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN WINDOW i677 with FORM "I677" 
	 CALL windecoration_i("I677") -- albo kd-758 
	DISPLAY "Delivery" TO detail_type 
	attribute(white) 
	DISPLAY BY NAME pr_ibthead.from_ware_code, 
	pr_ibthead.to_ware_code, 
	pr_delivhead.trans_num, 
	pr_delivhead.pick_num, 
	pr_delivhead.del_num, 
	pr_delivhead.pick_date, 
	pr_delivhead.transp_type_code, 
	pr_delivhead.vehicle_code, 
	pr_delivhead.driver_code 

	SELECT * INTO pr_transptype.* FROM transptype 
	WHERE transp_type_code = pr_delivhead.transp_type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY pr_transptype.desc_text TO transp_text 

	IF pr_delivhead.status_ind = "9" THEN 
		DISPLAY "CANCELLED" TO cancel_text 

	END IF 
	IF pr_delivhead.pallet_qty != 0 THEN 
		DISPLAY "Pallets..........." 
		TO pallet_text 
		attribute(white) 
		DISPLAY BY NAME pr_delivhead.pallet_qty 

	END IF 
	LET idx = 0 
	DECLARE c_delivdetl CURSOR FOR 
	SELECT * FROM delivdetl 
	WHERE pick_num = pr_delivhead.pick_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY pick_line_num 
	FOREACH c_delivdetl INTO pr_delivdetl.* 
		LET idx = idx + 1 
		LET pa_delivdetl[idx].pick_line_num = pr_delivdetl.pick_line_num 
		LET pa_delivdetl[idx].part_code = pr_delivdetl.part_code 
		LET pa_delivdetl[idx].picked_qty = pr_delivdetl.picked_qty 
		SELECT * INTO pr_product.* FROM product 
		WHERE part_code = pr_delivdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pa_delivdetl[idx].desc_text = pr_product.desc_text 
		LET pa_delivdetl[idx].desc2_text = pr_product.desc2_text 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1008,"") 
	#1008  F3/F4 ESC TO cont
	DISPLAY ARRAY pa_delivdetl TO sr_delivdetl.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I55","display-arr-delivdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 
	CLOSE WINDOW i677 
END FUNCTION 


FUNCTION disp_trrecp() 
	DEFINE 
	pr_prodledg RECORD LIKE prodledg.*, 
	pa_prodledg array[500] OF RECORD 
		tran_date LIKE prodledg.tran_date, 
		part_code LIKE prodledg.part_code, 
		desc_text LIKE product.desc_text, 
		tran_qty LIKE prodledg.tran_qty, 
		desc2_text LIKE product.desc_text 
	END RECORD, 
	idx, scrn SMALLINT 

	DECLARE c_prodledg CURSOR FOR 
	SELECT * FROM prodledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trantype_ind = "T" 
	AND source_num = pr_ibthead.trans_num 
	AND ware_code = pr_ibthead.to_ware_code 
	AND part_code = pr_ibtdetl.part_code 
	OPEN WINDOW i678 with FORM "I678" 
	 CALL windecoration_i("I678") -- albo kd-758 
	DISPLAY BY NAME pr_ibthead.trans_num, 
	pr_ibthead.from_ware_code, 
	pr_ibthead.to_ware_code 

	LET msgresp = kandoomsg("U",1002,"") 
	#1506 Searching Database; Please Wait
	LET idx = 0 
	FOREACH c_prodledg INTO pr_prodledg.* 
		LET idx = idx + 1 
		LET pa_prodledg[idx].tran_date = pr_prodledg.tran_date 
		LET pa_prodledg[idx].part_code = pr_prodledg.part_code 
		LET pa_prodledg[idx].tran_qty = pr_prodledg.tran_qty 
		SELECT desc_text,desc2_text INTO pa_prodledg[idx].desc_text, 
		pa_prodledg[idx].desc2_text 
		FROM product 
		WHERE part_code = pr_prodledg.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1008,"") 
	#1008  F3/F4 ESC TO cont
	DISPLAY ARRAY pa_prodledg TO sr_prodledg.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I55","display-arr-prodledg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END DISPLAY 

	CLOSE WINDOW i678 
END FUNCTION 


FUNCTION display_ibthead_record(pr_ibthead,pr_ibtdetl) 
	DEFINE 
	l_cmpy LIKE company.cmpy_code, 
	pr_product RECORD LIKE product.*, 
	from_ware_text, to_ware_text CHAR(30), 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.* 

	LET l_cmpy = pr_ibthead.cmpy_code 
	SELECT desc_text INTO from_ware_text FROM warehouse 
	WHERE ware_code = pr_ibthead.from_ware_code 
	AND cmpy_code = l_cmpy 
	SELECT desc_text INTO to_ware_text FROM warehouse 
	WHERE ware_code = pr_ibthead.to_ware_code 
	AND cmpy_code = l_cmpy 
	SELECT * INTO pr_product.* FROM product 
	WHERE part_code = pr_ibtdetl.part_code 
	AND cmpy_code = l_cmpy 
	DISPLAY pr_ibthead.from_ware_code, 
	pr_ibthead.to_ware_code, 
	from_ware_text, 
	to_ware_text, 
	pr_ibthead.trans_num, 
	pr_ibthead.desc_text, 
	pr_ibthead.trans_date, 
	pr_ibthead.year_num, 
	pr_ibthead.period_num, 
	pr_ibthead.sched_ind, 
	pr_ibthead.status_ind, 
	pr_ibtdetl.line_num, 
	pr_ibtdetl.part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_ibtdetl.trf_qty, 
	pr_ibtdetl.sched_qty, 
	pr_ibtdetl.picked_qty, 
	pr_ibtdetl.conf_qty, 
	pr_ibtdetl.rec_qty, 
	pr_ibtdetl.back_qty, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code 
	TO ibthead.from_ware_code, 
	ibthead.to_ware_code, 
	from_ware_text, 
	to_ware_text, 
	ibthead.trans_num, 
	ibthead.desc_text, 
	ibthead.trans_date, 
	ibthead.year_num, 
	ibthead.period_num, 
	ibthead.sched_ind, 
	ibthead.status_ind, 
	ibtdetl.line_num, 
	ibtdetl.part_code, 
	prod_desc, 
	product.desc2_text, 
	ibtdetl.trf_qty, 
	ibtdetl.sched_qty, 
	ibtdetl.picked_qty, 
	ibtdetl.conf_qty, 
	ibtdetl.rec_qty, 
	ibtdetl.back_qty, 
	sr_uomcode[1].*, 
	sr_uomcode[2].*, 
	sr_uomcode[3].*, 
	sr_uomcode[4].*, 
	sr_uomcode[5].*, 
	sr_uomcode[6].* 

	RETURN true 
END FUNCTION 
