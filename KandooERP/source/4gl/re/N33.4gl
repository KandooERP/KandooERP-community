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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N3_GROUP_GLOBALS.4gl"
GLOBALS "../re/N33_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_reqbackord RECORD LIKE reqbackord.* 
	DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N31 (N33!!!) - Requisition Back Order Product Allocation
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N33") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n127 with FORM "N127" 
	CALL windecoration_n("N127") -- albo kd-763 
	WHILE select_prod() 
		CALL scan_backords() 
	END WHILE 
	CLOSE WINDOW n127 

END MAIN 


FUNCTION select_prod() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_product RECORD LIKE product.* 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1020,"Product & Warehouse") 
	#1020 Enter Product & Warehouse Details; OK TO Continue.
	INPUT BY NAME pr_reqbackord.part_code, 
	pr_reqbackord.ware_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield (part_code) THEN 
				LET pr_reqbackord.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_reqbackord.part_code 

				NEXT FIELD part_code 
			ELSE 
				LET pr_reqbackord.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_reqbackord.ware_code 

				NEXT FIELD ware_code 
			END IF 
		AFTER FIELD part_code 
			IF pr_reqbackord.part_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD part_code 
			END IF 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_reqbackord.part_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD Not Found - Try Window
				CLEAR product.desc_text 
				NEXT FIELD part_code 
			END IF 
			DISPLAY pr_product.desc_text 
			TO product.desc_text 

		AFTER FIELD ware_code 
			IF pr_reqbackord.ware_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD ware_code 
			END IF 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_reqbackord.ware_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD Not Found - Try Window
				CLEAR warehouse.desc_text 
				NEXT FIELD ware_code 
			END IF 
			DISPLAY pr_warehouse.desc_text 
			TO warehouse.desc_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_reqbackord.ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ware_code 
				END IF 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_reqbackord.part_code 
				AND ware_code = pr_reqbackord.ware_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("A",9126,"") 
					#9126 "Product NOT Stocked AT this Warehouse"
					NEXT FIELD part_code 
				END IF 
				DISPLAY BY NAME pr_prodstatus.onhand_qty, 
				pr_prodstatus.reserved_qty 

			END IF 
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


FUNCTION scan_backords() 
	DEFINE 
	pr_reqbackord2 RECORD LIKE reqbackord.*, 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pa_reqbackord array[240] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE reqbackord.line_num, 
		req_num LIKE reqbackord.req_num, 
		person_code LIKE reqbackord.person_code, 
		req_date LIKE reqhead.req_date, 
		alloc_qty LIKE reqbackord.alloc_qty, 
		require_qty LIKE reqbackord.require_qty 
	END RECORD, 
	pr_alloc_qty LIKE reqbackord.alloc_qty, 
	tot_alloc_qty LIKE reqbackord.alloc_qty, 
	tot_unalloc_qty LIKE reqbackord.alloc_qty, 
	where_text CHAR(400), 
	query_text CHAR(600), 
	idx, scrn SMALLINT 

	WHILE true 
		LET tot_alloc_qty = 0 
		LET tot_unalloc_qty = 0 
		FOR idx = 1 TO 8 
			CLEAR sr_reqbackord[idx].* 
		END FOR 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 "Enter Selection Criteria;  OK TO Continue "
		CONSTRUCT BY NAME where_text ON reqbackord.line_num, 
		reqbackord.req_num, 
		reqbackord.person_code, 
		reqhead.req_date, 
		reqbackord.alloc_qty, 
		reqbackord.require_qty 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait "
		LET query_text = 
		"SELECT reqbackord.*, reqhead.req_date ", 
		"FROM reqbackord, reqhead ", 
		"WHERE reqbackord.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND reqbackord.cmpy_code = reqhead.cmpy_code ", 
		"AND reqbackord.req_num = reqhead.req_num ", 
		"AND reqbackord.part_code = \"",pr_prodstatus.part_code,"\" ", 
		"AND reqbackord.ware_code = \"",pr_prodstatus.ware_code,"\" ", 
		"AND ",where_text clipped," ", 
		"ORDER BY reqbackord.req_num, reqbackord.line_num" 
		PREPARE s_reqbackord FROM query_text 
		DECLARE c_reqbackord CURSOR FOR s_reqbackord 
		LET idx = 0 
		FOREACH c_reqbackord INTO pr_reqbackord2.*, pr_reqhead.req_date 
			LET idx = idx + 1 
			LET pa_reqbackord[idx].alloc_qty = pr_reqbackord2.alloc_qty 
			LET pa_reqbackord[idx].person_code = pr_reqbackord2.person_code 
			LET pa_reqbackord[idx].req_num = pr_reqbackord2.req_num 
			LET pa_reqbackord[idx].line_num = pr_reqbackord2.line_num 
			LET pa_reqbackord[idx].req_date = pr_reqhead.req_date 
			LET pa_reqbackord[idx].require_qty = pr_reqbackord2.require_qty 
			LET tot_alloc_qty = tot_alloc_qty + pr_reqbackord2.alloc_qty 
			LET tot_unalloc_qty = tot_unalloc_qty 
			- pr_reqbackord2.alloc_qty 
			+ pr_reqbackord2.require_qty 
			IF idx > 240 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				#6100 First idx RECORD selected
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET msgresp = kandoomsg("U",9113,idx) 
		#9113 idx records selected
		DISPLAY BY NAME tot_alloc_qty, 
		tot_unalloc_qty 

		LET msgresp = kandoomsg("R",1013,"") 
		#1013 "Edit Allocation Quantity as Required; F9 FOR Line Details "
		CALL set_count(idx) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INPUT ARRAY pa_reqbackord WITHOUT DEFAULTS FROM sr_reqbackord.* 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F9) 
				SELECT * INTO pr_reqdetl.* FROM reqdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_num = pa_reqbackord[idx].line_num 
				AND req_num = pa_reqbackord[idx].req_num 
				IF pa_reqbackord[idx].req_num IS NOT NULL THEN 
					CALL display_line(glob_rec_kandoouser.cmpy_code,pr_reqdetl.*,"1",pr_reqbackord.ware_code) 
				END IF 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
			BEFORE FIELD scroll_flag 
				DISPLAY pa_reqbackord[idx].* TO sr_reqbackord[scrn].* 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF pa_reqbackord[idx+1].person_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("nextpage") 
				AND pa_reqbackord[idx+9].person_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD alloc_qty 
				LET pr_alloc_qty = pa_reqbackord[idx].alloc_qty 
				DISPLAY pa_reqbackord[idx].* TO sr_reqbackord[scrn].* 

			AFTER FIELD alloc_qty 
				IF pa_reqbackord[idx].person_code IS NOT NULL THEN 
					IF pa_reqbackord[idx].alloc_qty IS NULL THEN 
						LET pa_reqbackord[idx].alloc_qty = pr_alloc_qty 
						NEXT FIELD alloc_qty 
					END IF 
					IF pr_alloc_qty != pa_reqbackord[idx].alloc_qty THEN 
						IF pa_reqbackord[idx].alloc_qty < 0 THEN 
							LET msgresp = kandoomsg("U",9907,"0") 
							#9907 "Value must NOT be greater than OR equal TO 0"
							LET pa_reqbackord[idx].alloc_qty = pr_alloc_qty 
							NEXT FIELD alloc_qty 
						END IF 
						IF pa_reqbackord[idx].alloc_qty 
						> pa_reqbackord[idx].require_qty THEN 
							LET msgresp = kandoomsg("U",9046, 
							pa_reqbackord[idx].require_qty) 
							#9046 "Value must be less than OR equal TO required qty"
							LET pa_reqbackord[idx].alloc_qty = pr_alloc_qty 
							NEXT FIELD alloc_qty 
						END IF 
						UPDATE reqbackord 
						SET alloc_qty = pa_reqbackord[idx].alloc_qty 
						WHERE reqbackord.part_code = pr_prodstatus.part_code 
						AND reqbackord.ware_code = pr_prodstatus.ware_code 
						AND reqbackord.req_num = pa_reqbackord[idx].req_num 
						AND reqbackord.line_num = pa_reqbackord[idx].line_num 
						IF status < 0 THEN 
							CALL errorlog("N33 - Back Order Allocation Update") 
							LET pa_reqbackord[idx].alloc_qty = pr_alloc_qty 
						END IF 
						LET tot_alloc_qty = tot_alloc_qty 
						- pr_alloc_qty 
						+ pa_reqbackord[idx].alloc_qty 
						LET tot_unalloc_qty = tot_unalloc_qty 
						+ pr_alloc_qty 
						- pa_reqbackord[idx].alloc_qty 
						DISPLAY BY NAME tot_alloc_qty, 
						tot_unalloc_qty 

						IF tot_alloc_qty > (pr_prodstatus.onhand_qty - 
						pr_prodstatus.reserved_qty) THEN 
							LET msgresp = kandoomsg("R",9514,"") 
							#9514 Total quantity allocated exceeds quantity available
						END IF 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY pa_reqbackord[idx].* TO sr_reqbackord[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 
END FUNCTION 
