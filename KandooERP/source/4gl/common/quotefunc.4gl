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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# module quotefunc - Allows user TO view quote lines
###########################################################################

###########################################################################
# FUNCTION lquoshow(p_cmpy,p_order_num)
#
#
###########################################################################
FUNCTION lquoshow(p_cmpy,p_order_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_order_num LIKE quotehead.order_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_quotedetl RECORD LIKE quotedetl.* 
	DEFINE l_rec_quotehead RECORD LIKE quotehead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_quotedetl DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE quotedetl.line_num, 
			offer_code LIKE quotedetl.offer_code, 
			part_code LIKE quotedetl.part_code, 
			sold_qty LIKE quotedetl.sold_qty, 
			bonus_qty LIKE quotedetl.bonus_qty, 
			disc_per LIKE quotedetl.disc_per, 
			unit_price_amt LIKE quotedetl.unit_price_amt, 
			line_tot_amt LIKE quotedetl.line_tot_amt, 
			autoinsert_flag LIKE quotedetl.autoinsert_flag 
		END RECORD 
	DEFINE l_arr_quotedetl2 DYNAMIC ARRAY OF RECORD 
			desc_text LIKE quotedetl.desc_text, 
			margin_ind LIKE quotedetl.margin_ind, 
			lead_text CHAR(62) 
		END RECORD 
	DEFINE l_ware_text LIKE warehouse.desc_text 
	DEFINE l_tax_text LIKE tax.desc_text 
	DEFINE l_non_product LIKE quotehead.freight_amt 
	DEFINE l_idx, l_scrn SMALLINT 

	INITIALIZE l_rec_quotedetl.* TO NULL 
	INITIALIZE l_rec_tax.* TO NULL 
	INITIALIZE l_rec_warehouse.* TO NULL 
	INITIALIZE l_rec_quotehead.* TO NULL 
	INITIALIZE l_rec_customership.* TO NULL 

	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*
	
	IF l_rec_arparms.parm_code IS NULL THEN #notfound 
		ERROR kandoomsg2("A",7005,"") #7005 AR Parms do NOT exist
		RETURN 
	END IF 
	
	OPEN WINDOW q114 with FORM "Q114" 
	CALL windecoration_q("Q114") 
	
	SELECT * INTO l_rec_quotehead.* FROM quotehead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = p_order_num 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_quotehead.cust_code 

	SELECT * INTO l_rec_customership.* FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_quotehead.cust_code 
	AND ship_code = l_rec_quotehead.ship_code 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_quotehead.tax_code 

	SELECT * INTO l_rec_warehouse.* FROM warehouse 
	WHERE ware_code = l_rec_quotehead.ware_code 
	AND cmpy_code = p_cmpy 
	DECLARE c_quotedetl CURSOR FOR 

	SELECT * FROM quotedetl 
	WHERE order_num = l_rec_quotehead.order_num 
	AND cust_code = l_rec_quotehead.cust_code 
	AND cmpy_code = p_cmpy 

	LET l_idx = 0 

	FOREACH c_quotedetl INTO l_rec_quotedetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_quotedetl[l_idx].line_num = l_rec_quotedetl.line_num 
		LET l_arr_quotedetl[l_idx].offer_code = l_rec_quotedetl.offer_code 
		LET l_arr_quotedetl[l_idx].part_code = l_rec_quotedetl.part_code 
		LET l_arr_quotedetl[l_idx].sold_qty = l_rec_quotedetl.sold_qty 
		LET l_arr_quotedetl[l_idx].bonus_qty = l_rec_quotedetl.bonus_qty 
		LET l_arr_quotedetl[l_idx].disc_per = l_rec_quotedetl.disc_per 
		LET l_arr_quotedetl[l_idx].unit_price_amt = l_rec_quotedetl.unit_price_amt 
		LET l_arr_quotedetl[l_idx].line_tot_amt = l_rec_quotedetl.line_tot_amt 
		IF l_rec_quotedetl.autoinsert_flag = "N" THEN 
			LET l_arr_quotedetl[l_idx].autoinsert_flag = NULL 
		ELSE 
			LET l_arr_quotedetl[l_idx].autoinsert_flag = "*" 
		END IF 
		LET l_arr_quotedetl2[l_idx].desc_text = l_rec_quotedetl.desc_text 
		LET l_arr_quotedetl2[l_idx].margin_ind = l_rec_quotedetl.margin_ind 
		LET l_arr_quotedetl2[l_idx].lead_text = l_rec_quotedetl.quote_lead_text clipped, 
		" ",l_rec_quotedetl.quote_lead_text2 

		IF l_idx = 500 THEN 
			ERROR kandoomsg2("U",6100,l_idx) 		#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	
	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_quotedetl[l_idx].* TO NULL 
		INITIALIZE l_arr_quotedetl2[l_idx].* TO NULL 
	END IF 
	
	CALL set_count(l_idx) 
	
	ERROR kandoomsg2("R",1020,"") #1020 ENTER on Line TO Edit; CTRL+N FOR Notes; OK TO Continue.
	LET l_ware_text = l_rec_warehouse.desc_text 
	LET l_tax_text = l_rec_tax.desc_text 

	DISPLAY BY NAME 
		l_rec_quotehead.cust_code, 
		l_rec_customer.name_text, 
		l_rec_quotedetl.ware_code, 
		l_rec_quotehead.tax_code, 
		l_rec_quotedetl.level_ind 

	DISPLAY l_ware_text,l_tax_text TO pr_ware_text,pr_tax_text

	DISPLAY BY NAME l_rec_quotehead.currency_code attribute (green) 

	LET l_non_product = l_rec_quotehead.freight_amt 
	+ l_rec_quotehead.freight_tax_amt 
	+ l_rec_quotehead.hand_amt 
	+ l_rec_quotehead.hand_tax_amt 

	IF l_non_product IS NULL THEN 
		LET l_non_product = 0 
	END IF 

	DISPLAY BY NAME 
		l_rec_quotehead.goods_amt, 
		l_rec_quotehead.tax_amt, 
		l_rec_quotehead.total_amt	attribute (magenta) 

	DISPLAY l_non_product TO	pr_non_product 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY l_arr_quotedetl WITHOUT DEFAULTS FROM sr_quotedetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","quotefunc","input-arr-quotedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			DISPLAY l_arr_quotedetl[l_idx].* TO sr_quotedetl[l_scrn].* 

			DISPLAY BY NAME 
				l_arr_quotedetl2[l_idx].desc_text, 
				l_arr_quotedetl2[l_idx].lead_text, 
				l_arr_quotedetl2[l_idx].margin_ind 

		AFTER FIELD scroll_flag 
			LET l_arr_quotedetl[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down")	AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("U",9001,"") 			#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_quotedetl[l_idx+1].line_num IS NULL 
				OR l_arr_quotedetl[l_idx+1].line_num = 0 THEN 
					ERROR kandoomsg2("U",9001,"") 				#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND (l_arr_quotedetl[l_idx+6].line_num IS NULL 
			OR l_arr_quotedetl[l_idx+6].line_num = 0) THEN 
				ERROR kandoomsg2("U",9001,"") 			#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 

		ON ACTION "NOTES" --ON KEY (control-n) 
			IF l_arr_quotedetl2[l_idx].desc_text[1,3] = "###" 
			AND l_arr_quotedetl2[l_idx].desc_text[16,18] = "###" THEN 
				CALL note_disp(p_cmpy,l_arr_quotedetl2[l_idx].desc_text[4,15]) 
			END IF 

		BEFORE FIELD line_num 
			CALL show_line_detail(
				p_cmpy, 
				p_order_num, 
				l_idx) 

			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY l_arr_quotedetl[l_idx].* TO sr_quotedetl[l_scrn].* 


	END INPUT 
	CLOSE WINDOW q114 
END FUNCTION 
###########################################################################
# END FUNCTION lquoshow(p_cmpy,p_order_num)
###########################################################################


###########################################################################
# FUNCTION lquoshow(p_cmpy,p_order_num)
#
#
###########################################################################
FUNCTION show_line_detail(p_cmpy,p_order_num,p_line_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_order_num LIKE quotehead.order_num 
	DEFINE p_line_num LIKE quotedetl.line_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_quotedetl RECORD LIKE quotedetl.* 
	DEFINE l_rec_quotehead RECORD LIKE quotehead.* 
	DEFINE l_disc_flag CHAR(1) 

	SELECT * INTO l_rec_quotedetl.* FROM quotedetl 
	WHERE order_num = p_order_num 
	AND cmpy_code = p_cmpy 
	AND line_num = p_line_num 

	SELECT * INTO l_rec_quotehead.* FROM quotehead 
	WHERE order_num = p_order_num 
	AND cmpy_code = p_cmpy 

	OPEN WINDOW q115 with FORM "Q115" 

	CALL windecoration_q("Q115") -- albo kd-767 
	CALL display_available(l_rec_quotedetl.*,p_cmpy) 

	## IF disc_per IS modified the line will be excluded FROM autodisc calc
	IF l_rec_quotedetl.serial_qty THEN 
		LET l_disc_flag = "*" 
	ELSE 
		LET l_disc_flag = NULL 
	END IF 

	DISPLAY BY NAME 
		l_rec_quotedetl.part_code, 
		l_rec_quotedetl.desc_text, 
		l_rec_quotedetl.sold_qty, 
		l_rec_quotedetl.bonus_qty, 
		l_rec_quotedetl.order_qty, 
		l_rec_quotedetl.reserved_qty, 
		l_rec_quotedetl.level_ind, 
		l_rec_quotedetl.uom_code, 
		l_rec_quotedetl.unit_price_amt, 
		l_rec_quotedetl.unit_tax_amt, 
		l_rec_quotedetl.line_tot_amt, 
		l_rec_quotedetl.quote_lead_text, 
		l_rec_quotedetl.quote_lead_text2, 
		l_rec_quotedetl.ware_code, 
		l_rec_quotedetl.disc_per, 
		l_rec_quotedetl.margin_ind, 
		l_rec_quotedetl.list_price_amt, 
		l_rec_quotedetl.ext_price_amt, 
		l_rec_quotedetl.ext_tax_amt, 
		l_rec_quotedetl.line_tot_amt, 
		l_rec_quotedetl.status_ind, 
		l_rec_quotedetl.disc_allow_flag 

	DISPLAY l_disc_flag TO pr_disc_flag

	DISPLAY BY NAME l_rec_quotehead.currency_code attribute(green) 

	CALL eventsuspend() 
	#ERROR kandoomsg2("U",1,"")

	CLOSE WINDOW q115 
END FUNCTION 
###########################################################################
# END FUNCTION lquoshow(p_cmpy,p_order_num)
###########################################################################


###########################################################################
# FUNCTION display_available(p_quotedetl,p_cmpy)
#
#
###########################################################################
FUNCTION display_available(p_quotedetl,p_cmpy) 
	DEFINE p_quotedetl RECORD LIKE quotedetl.* 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_cur_avail_qty LIKE prodstatus.onhand_qty
	DEFINE l_fut_avail_qty LIKE prodstatus.onhand_qty 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING l_rec_opparms.*
	
	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_quotedetl.part_code 
	AND ware_code = p_quotedetl.ware_code 
	IF status = notfound THEN 
		LET l_rec_prodstatus.ware_code = p_quotedetl.ware_code 
		LET l_rec_prodstatus.onhand_qty = 0 
		LET l_rec_prodstatus.reserved_qty = 0 
		LET l_rec_prodstatus.back_qty = 0 
		LET l_cur_avail_qty = 0 
		LET l_rec_prodstatus.onord_qty = 0 
		LET l_fut_avail_qty = 0 
		
		DISPLAY 
			l_rec_prodstatus.ware_code, 
			l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.reserved_qty, 
			l_rec_prodstatus.back_qty, 
			l_cur_avail_qty, 
			l_rec_prodstatus.onord_qty, 
			l_fut_avail_qty 
		TO 
			quotedetl.ware_code, 
			prodstatus.onhand_qty, 
			pr_reserved_qty, 
			prodstatus.back_qty, 
			current_qty, 
			prodstatus.onord_qty, 
			future_qty	attribute(yellow) 
	ELSE 
		IF l_rec_prodstatus.stocked_flag = "Y" THEN 
			LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty	+ p_quotedetl.reserved_qty 
			IF l_rec_opparms.cal_available_flag = "N" THEN 
				LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty 
				- l_rec_prodstatus.reserved_qty 
				- l_rec_prodstatus.back_qty 
			ELSE 
				LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty	- l_rec_prodstatus.reserved_qty 
				LET l_rec_prodstatus.back_qty = "" 
			END IF 
			LET l_fut_avail_qty = l_cur_avail_qty + l_rec_prodstatus.onord_qty 

			DISPLAY 
				l_rec_prodstatus.ware_code, 
				l_rec_prodstatus.onhand_qty, 
				l_rec_prodstatus.reserved_qty, 
				l_rec_prodstatus.back_qty, 
				l_cur_avail_qty, 
				l_rec_prodstatus.onord_qty, 
				l_fut_avail_qty 
			TO 
				quotedetl.ware_code, 
				prodstatus.onhand_qty, 
				pr_reserved_qty, 
				prodstatus.back_qty, 
				current_qty, 
				prodstatus.onord_qty, 
				future_qty		attribute(yellow) 
		ELSE 
			DISPLAY " NOT STOCKED " at 7,44 
		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION display_available(p_quotedetl,p_cmpy)
###########################################################################