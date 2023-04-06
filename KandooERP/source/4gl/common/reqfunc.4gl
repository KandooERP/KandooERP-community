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
# Requires
# common/note_disp.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION requisition_inquiry(p_cmpy_code,p_req_num,p_header_flag)
#
#
############################################################
FUNCTION requisition_inquiry(p_cmpy_code,p_req_num,p_header_flag) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_req_num LIKE reqhead.req_num 
	DEFINE p_header_flag INTEGER 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_arr_rec_reqmenu ARRAY[6] OF 
	RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(24) 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 

	WHENEVER any ERROR CONTINUE 

	OPEN WINDOW n110 with FORM "N110" 
	CALL winDecoration_n("N110") 

	WHENEVER any ERROR stop 
	IF status != 0 THEN 
		LET l_msgresp = kandoomsg("U",9917,"") 
		RETURN 
	END IF 
	SELECT * INTO l_rec_reqhead.* FROM reqhead 
	WHERE cmpy_code = p_cmpy_code 
	AND req_num = p_req_num 
	DISPLAY BY NAME l_rec_reqhead.req_num 

	IF p_header_flag THEN 
		LET l_arr_rec_reqmenu[1].option_num = "1" 
		LET l_arr_rec_reqmenu[1].option_text = kandooword("reqwind","5") 
		LET l_arr_rec_reqmenu[2].option_num = "2" 
		LET l_arr_rec_reqmenu[2].option_text = kandooword("reqwind","1") 
		LET l_arr_rec_reqmenu[3].option_num = "3" 
		LET l_arr_rec_reqmenu[3].option_text = kandooword("reqwind","2") 
		LET l_arr_rec_reqmenu[4].option_num = "4" 
		LET l_arr_rec_reqmenu[4].option_text = kandooword("reqwind","3") 
		LET l_arr_rec_reqmenu[5].option_num = "5" 
		LET l_arr_rec_reqmenu[5].option_text = kandooword("reqwind","4") 
		CALL set_count(5) 
	ELSE 
		LET l_arr_rec_reqmenu[1].option_num = "1" 
		LET l_arr_rec_reqmenu[1].option_text = kandooword("reqwind","1") 
		LET l_arr_rec_reqmenu[2].option_num = "2" 
		LET l_arr_rec_reqmenu[2].option_text = kandooword("reqwind","2") 
		LET l_arr_rec_reqmenu[3].option_num = "3" 
		LET l_arr_rec_reqmenu[3].option_text = kandooword("reqwind","3") 
		LET l_arr_rec_reqmenu[4].option_num = "4" 
		LET l_arr_rec_reqmenu[4].option_text = kandooword("reqwind","4") 
		CALL set_count(4) 
	END IF 
	LET l_msgresp = kandoomsg("W",1153,"") 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY l_arr_rec_reqmenu WITHOUT DEFAULTS FROM sr_reqmenu.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","reqfunc","input-arr-reqmenu") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			NEXT FIELD scroll_flag 
			#      BEFORE FIELD scroll_flag
			#         DISPLAY l_arr_rec_reqmenu[l_idx].* TO sr_reqmenu[scrn].*

		AFTER FIELD scroll_flag 
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD option_num
			--#END IF
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF (l_idx + 1) = 6 #press down FROM LAST option 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			#      AFTER ROW
			#         DISPLAY l_arr_rec_reqmenu[l_idx].* TO sr_reqmenu[scrn].*

		BEFORE FIELD option_num 
			IF l_arr_rec_reqmenu[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_reqmenu[l_idx].scroll_flag = l_arr_rec_reqmenu[l_idx].option_num 
			END IF 

			IF p_header_flag THEN 
				CASE l_arr_rec_reqmenu[l_idx].scroll_flag 
					WHEN "1" 

						OPEN WINDOW n109 with FORM "N109" 
						CALL winDecoration_n("N109") 

						CALL display_requisition(p_cmpy_code,l_rec_reqhead.req_num) 
						CALL eventsuspend() 
						#LET l_msgresp = kandoomsg("U",1,"")
						#1 Any Key TO Continue
						CLOSE WINDOW n109 

					WHEN "2" 
						CALL show_req_ship(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "3" 
						CALL show_req_lines(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "4" 
						CALL show_line_status(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "5" 
						IF l_rec_reqhead.com1_text[1,3] = "###" 
						AND l_rec_reqhead.com1_text[16,18] = "###" THEN 
							CALL note_disp(p_cmpy_code,l_rec_reqhead.com1_text[4,15]) 
						ELSE 
							LET l_msgresp = kandoomsg("A",7027,"") 
							#7027 No Notes TO View
						END IF 
				END CASE 
			ELSE 
				CASE l_arr_rec_reqmenu[l_idx].scroll_flag 
					WHEN "1" 
						CALL show_req_ship(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "2" 
						CALL show_req_lines(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "3" 
						CALL show_line_status(p_cmpy_code,l_rec_reqhead.req_num) 
					WHEN "4" 
						IF l_rec_reqhead.com1_text[1,3] = "###" 
						AND l_rec_reqhead.com1_text[16,18] = "###" THEN 
							CALL note_disp(p_cmpy_code,l_rec_reqhead.com1_text[4,15]) 
						ELSE 
							LET l_msgresp = kandoomsg("A",7027,"") 
							#7027 No Notes TO View
						END IF 
				END CASE 
			END IF 
			LET l_arr_rec_reqmenu[l_idx].scroll_flag = NULL 
			NEXT FIELD scroll_flag 

	END INPUT 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	CLOSE WINDOW n110 

END FUNCTION 



############################################################
# FUNCTION display_requisition(p_cmpy_code,p_req_num)
#
#
############################################################
FUNCTION display_requisition(p_cmpy_code,p_req_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_req_num LIKE reqhead.req_num 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_rec_reqperson RECORD LIKE reqperson.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_trans_text CHAR(14) 
	DEFINE l_app_amt DECIMAL(10,2) 

	SELECT * INTO l_rec_reqhead.* FROM reqhead 
	WHERE cmpy_code = p_cmpy_code 
	AND req_num = p_req_num 
	SELECT name_text INTO l_rec_reqperson.name_text FROM reqperson 
	WHERE cmpy_code = p_cmpy_code 
	AND person_code = l_rec_reqhead.person_code 
	SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
	WHERE cmpy_code = p_cmpy_code 
	AND ware_code = l_rec_reqhead.ware_code 
	CASE l_rec_reqhead.stock_ind 
		WHEN 0 
			LET l_trans_text = kandooword("reqhead.stock_ind","0") 
		WHEN 1 
			LET l_trans_text = kandooword("reqhead.stock_ind","1") 
		WHEN 2 
			LET l_trans_text = kandooword("reqhead.stock_ind","2") 
	END CASE 

	IF l_rec_reqhead.last_del_no = 0 THEN 
		LET l_rec_reqhead.last_del_no = NULL 
	END IF 

	SELECT sum(po_qty * unit_sales_amt) INTO l_app_amt FROM reqdetl 
	WHERE cmpy_code = p_cmpy_code 
	AND req_num = l_rec_reqhead.req_num 

	IF l_app_amt IS NULL THEN 
		LET l_app_amt = 0 
	END IF 

	DISPLAY BY NAME l_rec_reqhead.person_code, 
	l_rec_reqperson.name_text, 
	l_rec_reqhead.req_num, 
	l_rec_reqhead.total_sales_amt, 
	l_rec_reqhead.del_dept_text, 
	l_rec_reqhead.del_name_text, 
	l_rec_reqhead.ware_code, 
	l_rec_warehouse.desc_text, 
	l_rec_reqhead.ref_text, 
	l_rec_reqhead.stock_ind, 
	l_rec_reqhead.status_ind, 
	l_rec_reqhead.last_del_no, 
	l_rec_reqhead.last_del_date, 
	l_rec_reqhead.req_date, 
	l_rec_reqhead.year_num, 
	l_rec_reqhead.period_num, 
	l_rec_reqhead.entry_date, 
	l_rec_reqhead.last_mod_date, 
	l_rec_reqhead.last_mod_code, 
	l_rec_reqhead.rev_num, 
	l_rec_reqhead.com1_text, 
	l_rec_reqhead.com2_text 
	DISPLAY l_app_amt,l_trans_text TO pr_app_amt,trans_text

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 




############################################################
# FUNCTION I55_disp_record(p_rec_ibthead,p_rec_ibtdetl)
#
#
############################################################
FUNCTION i55_disp_record(p_rec_ibthead,p_rec_ibtdetl) 
	DEFINE p_rec_ibthead RECORD LIKE ibthead.* 
	DEFINE p_rec_ibtdetl RECORD LIKE ibtdetl.* 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_from_ware_text CHAR(30) 
	DEFINE l_to_ware_text CHAR(30) 

	LET l_cmpy_code = p_rec_ibthead.cmpy_code 
	SELECT desc_text INTO l_from_ware_text FROM warehouse 
	WHERE ware_code = p_rec_ibthead.from_ware_code 
	AND cmpy_code = l_cmpy_code 
	SELECT desc_text INTO l_to_ware_text FROM warehouse 
	WHERE ware_code = p_rec_ibthead.to_ware_code 
	AND cmpy_code = l_cmpy_code 
	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_rec_ibtdetl.part_code 
	AND cmpy_code = l_cmpy_code 
	DISPLAY p_rec_ibthead.from_ware_code, 
	p_rec_ibthead.to_ware_code, 
	l_from_ware_text, 
	l_to_ware_text, 
	p_rec_ibthead.trans_num, 
	p_rec_ibthead.desc_text, 
	p_rec_ibthead.trans_date, 
	p_rec_ibthead.year_num, 
	p_rec_ibthead.period_num, 
	p_rec_ibthead.sched_ind, 
	p_rec_ibthead.status_ind, 
	p_rec_ibtdetl.line_num, 
	p_rec_ibtdetl.part_code, 
	l_rec_product.desc_text, 
	l_rec_product.desc2_text, 
	p_rec_ibtdetl.trf_qty, 
	p_rec_ibtdetl.sched_qty, 
	p_rec_ibtdetl.picked_qty, 
	p_rec_ibtdetl.conf_qty, 
	p_rec_ibtdetl.rec_qty, 
	p_rec_ibtdetl.back_qty, 
	l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code 
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

	RETURN TRUE 
END FUNCTION 
