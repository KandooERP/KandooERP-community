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
# common/orstfunc.4gl
# common/note_disp.4gl
###########################################################################


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
############################################################
# FUNCTION lordshow(p_cmpy ,p_cust ,p_ord_num ,p_func_type)
#
# module orddfunc -  FUNCTION TO access ORDER details
############################################################
FUNCTION lordshow(p_cmpy,p_cust,p_ord_num,p_func_type) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_ord_num LIKE orderhead.order_num 
	DEFINE p_func_type CHAR(14) 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_cat_codecat RECORD LIKE category.* 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD 
		part_code LIKE orderdetl.part_code, 
		order_qty LIKE orderdetl.order_qty, 
		desc_text LIKE orderdetl.desc_text, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		line_tot_amt LIKE orderdetl.line_tot_amt 
	END RECORD 
	DEFINE l_gross_dollar money(12,2) 
	DEFINE l_gross_percent DECIMAL(8,3) 
	DEFINE l_markup_percent DECIMAL(8,3) 
	DEFINE l_ord_desc CHAR(7) 
	DEFINE l_idx SMALLINT 
	DEFINE j SMALLINT	 

	LET p_func_type = "View Order"
	
	#Order Header Details 
	SELECT * 
	INTO l_rec_orderhead.* 
	FROM orderhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND order_num = p_ord_num 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("E",9250,"") 			#9250 "Order Header Details NOT found"
		RETURN 
	END IF 

	#Customer record
	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust) 			#9067 Logic Error: Customer XXXX was NOT found
	END IF 

	#Customer Shipping RECORD
	SELECT ware_code 
	INTO l_rec_customership.ware_code 
	FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_orderhead.cust_code 
	AND ship_code = l_rec_orderhead.ship_code 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("U",7001,"Customer Shipping") 		#7001 Logic Error:  NOT found --
	ELSE 
		LET l_rec_orderdetl.ware_code = l_rec_customership.ware_code 
	END IF 

	#Tax RECORD
	SELECT * 
	INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_orderhead.tax_code 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("U",7001,"Tax") 			#7001 Logic Error: Tax RECORD NOT found
	END IF 

	#AR Parameters
	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("#7001 Logic Error: AR Parameters RECORD does NOT exist",kandoomsg2("U",7001,"AR Parameters"),"ERROR") 			#7001 Logic Error: AR Parameters RECORD does NOT exist in database
		EXIT PROGRAM
	END IF 
	 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPEN WINDOW E419 with FORM "E419" 
	CALL windecoration_e("E419") 

	DECLARE c_orddetl CURSOR FOR 
	SELECT orderdetl.* 
	INTO l_rec_orderdetl.* 
	FROM orderdetl 
	WHERE order_num = l_rec_orderhead.order_num 
	AND cust_code = l_rec_orderhead.cust_code 
	AND cmpy_code = p_cmpy 
	
	LET l_idx = 0
	FOREACH c_orddetl 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl.part_code 
		LET l_arr_rec_orderdetl[l_idx].order_qty = l_rec_orderdetl.order_qty 
		LET l_arr_rec_orderdetl[l_idx].desc_text = l_rec_orderdetl.desc_text 
		LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl.unit_price_amt 
		
		IF l_rec_arparms.show_tax_flag = "N" THEN 
			LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl.ext_price_amt 
		ELSE 
			LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl.line_tot_amt 
		END IF 

	END FOREACH 

	#   CALL set_count(l_idx)

	--LET l_rec_customer.name_text = l_rec_orderhead.ship_name_text  #no shipping address.. no contact ? we need to address this 
	MESSAGE kandoomsg2("E",1180,"") 		#1180 CTRL V TO View Order - CTRL N TO View Notes...

	DISPLAY BY NAME 
		l_rec_orderhead.cust_code, 
		l_rec_customer.name_text, 
		l_rec_orderdetl.ware_code, 
		l_rec_orderhead.tax_code, 
		l_rec_tax.desc_text, 
		l_rec_customer.inv_level_ind 
	
	DISPLAY BY NAME 
		l_rec_orderhead.goods_amt, 
		l_rec_orderhead.tax_amt, 
		l_rec_orderhead.total_amt attribute (magenta) 
	
	DISPLAY l_rec_orderhead.cust_code TO orderhead.cust_code
	DISPLAY l_rec_customer.name_text TO customer.name_text
	 
	DISPLAY l_rec_orderhead.ship_code TO orderhead.ship_code
	DISPLAY l_rec_orderhead.ship_name_text TO orderhead.ship_name_text 
	
	DISPLAY l_rec_customer.cred_bal_amt TO customer.cred_bal_amt
	DISPLAY p_func_type TO func attribute(green) 

--	INPUT ARRAY l_arr_rec_orderdetl WITHOUT DEFAULTS FROM sr_orderdetl.* 
	DISPLAY ARRAY l_arr_rec_orderdetl TO sr_orderdetl.* ATTRIBUTE(UNBUFFERED)	
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","orddfunc.4gl","input-arr-orderdetl") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
 			CALL dialog.setActionHidden("ORDER NOTES",NOT l_arr_rec_orderdetl.getSize())
 			CALL dialog.setActionHidden("ORDER LINE TOTALS",NOT l_arr_rec_orderdetl.getSize())
 			CALL dialog.setActionHidden("ORDER SHOW",NOT l_arr_rec_orderdetl.getSize()) 			

		BEFORE ROW 
			LET l_idx = arr_curr() 

		AFTER ROW 
			#nothing 

		AFTER DISPLAY
			#nothing

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "ORDER STATISTIC"
			CALL ord_stat(p_cmpy, l_rec_orderhead.cust_code,	l_rec_orderhead.order_num)
{			
		#-------------
		#F5 the same as control-v because IBM-Informix bug under AIX
		ON KEY (F5)  
			CALL ord_stat(p_cmpy, l_rec_orderhead.cust_code,	l_rec_orderhead.order_num)
			 
		ON KEY (control-v) 
			CALL ord_stat(p_cmpy, l_rec_orderhead.cust_code,	l_rec_orderhead.order_num)
		#---------------- 
}	
		ON ACTION "ORDER NOTES"  --	ON KEY (control-n)
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN
				IF l_arr_rec_orderdetl[l_idx].desc_text[1,3] = "###" 
				AND l_arr_rec_orderdetl[l_idx].desc_text[16,18] = "###" THEN 
					CALL note_disp(p_cmpy,l_arr_rec_orderdetl[l_idx].desc_text[4,15]) 
				ELSE 
					ERROR kandoomsg2("A",7027,"") 		#No Notes TO View
				END IF 
			END IF
			
		ON ACTION "ORDER TOTAL" --		ON KEY (control-t)
 
			LET l_ord_desc = "Total" 
			LET l_gross_dollar = l_rec_orderhead.goods_amt - l_rec_orderhead.cost_amt 
			
			IF l_rec_orderhead.goods_amt = 0 
			OR l_rec_orderhead.goods_amt IS NULL THEN 
				LET l_gross_percent = 0 
			ELSE 
				LET l_gross_percent =  ((l_gross_dollar * 100)/ l_rec_orderhead.goods_amt) 
			END IF 
			
			IF l_rec_orderhead.cost_amt = 0 
			OR l_rec_orderhead.cost_amt IS NULL THEN 
				LET l_markup_percent = 0 
			ELSE 
				LET l_markup_percent = ((l_gross_dollar * 100)/ l_rec_orderhead.cost_amt) 
			END IF 

			OPEN WINDOW E426 with FORM "E426" 
			CALL windecoration_e("E426") 

			DISPLAY l_ord_desc TO ord_type 
			DISPLAY l_gross_dollar TO gp_dollar 
			DISPLAY l_gross_percent TO gp 
			DISPLAY l_markup_percent TO mu 
			DISPLAY l_rec_orderhead.goods_amt TO mats 
			DISPLAY l_rec_orderhead.cost_amt TO costs 
			CALL eventsuspend()

			CLOSE WINDOW E426 

		ON ACTION "ORDER LINE TOTALS" 	--ON KEY (control-p) # work out ORDER line totals
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN
				SELECT * 
				INTO l_rec_orderdetl.* 
				FROM orderdetl 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = p_cust 
				AND order_num = p_ord_num 
				AND line_num = l_idx 
				AND part_code = l_arr_rec_orderdetl[l_idx].part_code 
				AND order_qty = l_arr_rec_orderdetl[l_idx].order_qty 
				
				LET l_ord_desc = "Line" 
				LET l_gross_dollar = l_rec_orderdetl.ext_price_amt - l_rec_orderdetl.ext_cost_amt
				 
				IF l_rec_orderdetl.ext_price_amt = 0 OR l_rec_orderdetl.ext_price_amt IS NULL THEN 
					LET l_gross_percent = 0 
				ELSE 
					LET l_gross_percent = ((l_gross_dollar * 100)/ l_rec_orderdetl.ext_price_amt) 
				END IF 
				
				IF l_rec_orderdetl.ext_cost_amt = 0	OR l_rec_orderdetl.ext_cost_amt IS NULL THEN 
					LET l_markup_percent = 0 
				ELSE 
					LET l_markup_percent = ((l_gross_dollar * 100)/ l_rec_orderdetl.ext_cost_amt) 
				END IF 
	
				OPEN WINDOW E426 with FORM "E426" 
				CALL windecoration_e("E426") 
	
				DISPLAY l_ord_desc TO ord_type 
				DISPLAY l_gross_dollar TO gp_dollar 
				DISPLAY l_gross_percent TO gp 
				DISPLAY l_markup_percent TO mu 
				DISPLAY l_rec_orderdetl.ext_price_amt TO mats 
				DISPLAY l_rec_orderdetl.ext_cost_amt TO costs 
				
				CALL eventsuspend() 
				CLOSE WINDOW E426
			END IF
{			
			#Eric ??? what is this ??? 
			### modif ericv init # AFTER FIELD part_code
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD order_qty
			--#END IF
}
		ON ACTION ("ORDER SHOW","DOUBLECLICK","ACCEPT")	--BEFORE FIELD order_qty
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN
				SELECT * 
				INTO l_rec_orderdetl.* 
				FROM orderdetl 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = p_cust 
				AND order_num = p_ord_num 
				AND part_code = l_arr_rec_orderdetl[l_idx].part_code 
				AND order_qty = l_arr_rec_orderdetl[l_idx].order_qty 
				AND line_num = l_idx 
				CALL ord_show(l_rec_orderdetl.*) 
 
			END IF

	END DISPLAY 
	CLOSE WINDOW E419 

END FUNCTION 
############################################################
# END FUNCTION lordshow(p_cmpy ,p_cust ,p_ord_num ,p_func_type)
############################################################


############################################################
# FUNCTION ord_show(p_rec_orderdetl)
#
#
############################################################
FUNCTION ord_show(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_avail LIKE prodstatus.onhand_qty 
	DEFINE l_rec_opparms RECORD LIKE opparms.* 

	#AR Parameters
	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_rec_orderdetl.cmpy_code 
	AND parm_code = "1" 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("U",7001,"AR Parameters") 	#7001 Logic Error: AR Parameters RECORD does NOT exist in database
	END IF 

	OPEN WINDOW E445 with FORM "E445" 
	CALL windecoration_e("E445") 

	#prodstatus
	SELECT * 
	INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_rec_orderdetl.cmpy_code 
	AND ware_code = p_rec_orderdetl.ware_code 
	AND part_code = p_rec_orderdetl.part_code 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING l_rec_opparms.*
	IF l_rec_opparms.key_num IS NULL AND l_rec_opparms.cmpy_code IS NULL THEN  
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program EZP)",kandoomsg2("E",5003,""),"ERROR") #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP" 
		EXIT program 
	END IF 

	IF l_rec_opparms.cal_available_flag = "N" THEN 
		LET l_avail = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
	ELSE 
		LET l_avail = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
	END IF 

	DISPLAY l_rec_prodstatus.onhand_qty TO prodstatus.onhand_qty 
	DISPLAY l_rec_prodstatus.reserved_qty TO prodstatus.reserved_qty
	DISPLAY l_rec_prodstatus.back_qty TO prodstatus.back_qty
	DISPLAY l_avail TO formonly.avail  
	
	LET p_rec_orderdetl.sched_qty = p_rec_orderdetl.sched_qty + p_rec_orderdetl.picked_qty 
	IF l_rec_arparms.show_tax_flag = "Y" THEN 
		DISPLAY 
			p_rec_orderdetl.part_code, 
			p_rec_orderdetl.order_qty, 
			p_rec_orderdetl.back_qty, 
			p_rec_orderdetl.sched_qty, 
			p_rec_orderdetl.inv_qty, 
			p_rec_orderdetl.desc_text, 
			p_rec_orderdetl.uom_code, 
			p_rec_orderdetl.level_ind, 
			p_rec_orderdetl.unit_price_amt, 
			p_rec_orderdetl.unit_tax_amt, 
			p_rec_orderdetl.line_tot_amt 
		TO 
			orderdetl.part_code, 
			orderdetl.order_qty, 
			orderdetl.back_qty, 
			orderdetl.sched_qty, 
			orderdetl.inv_qty, 
			orderdetl.desc_text, 
			orderdetl.uom_code, 
			orderdetl.level_ind, 
			orderdetl.unit_price_amt, 
			orderdetl.unit_tax_amt, 
			orderdetl.line_tot_amt
		attribute(cyan)

	ELSE 
		DISPLAY 
			p_rec_orderdetl.part_code, 
			p_rec_orderdetl.order_qty, 
			p_rec_orderdetl.back_qty, 
			p_rec_orderdetl.sched_qty, 
			p_rec_orderdetl.inv_qty, 
			p_rec_orderdetl.desc_text, 
			p_rec_orderdetl.uom_code, 
			p_rec_orderdetl.level_ind, 
			p_rec_orderdetl.unit_price_amt, 
			p_rec_orderdetl.ext_price_amt 
		TO
			orderdetl.part_code, 
			orderdetl.order_qty, 
			orderdetl.back_qty, 
			orderdetl.sched_qty, 
			orderdetl.inv_qty, 
			orderdetl.desc_text, 
			orderdetl.uom_code, 
			orderdetl.level_ind, 
			orderdetl.unit_price_amt, 
			orderdetl.line_tot_amt attribute(cyan)
		
	END IF 

	CALL eventsuspend()
	CLOSE WINDOW E445 

END FUNCTION 
############################################################
# END FUNCTION ord_show(p_rec_orderdetl)
############################################################
{
############################################################
# FUNCTION hit_key()
#
#
############################################################
FUNCTION hit_key() 
	DEFINE l_ans CHAR(1) 

	CALL eventsuspend() # LET l_ans = kandoomsg("U",1,"") 
	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
############################################################
# END FUNCTION hit_key()
############################################################
}