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
###########################################################################

###########################################################################
# Requires
# common/invqwind.4gl
# common/dispgpfunc.4gl
# common/inhdwind.4gl
# common/note_disp.4gl
###########################################################################


###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################

####################################################################
# FUNCTION lineshow(p_cmpy, p_cust, p_invnum, p_func_type)
#
#        invdfunc.4gl - FUNCTION lineshow
#                       Invoice line item Display
####################################################################
FUNCTION lineshow(p_cmpy,p_cust,p_invnum,p_func_type) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_invnum LIKE invoicehead.inv_num 
	DEFINE p_func_type CHAR(14) 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_customership RECORD LIKE customership.* 

--	SELECT * INTO glob_rec_company.* 
--	FROM company 
--	WHERE cmpy_code = p_cmpy 
--
--	IF STATUS = NOTFOUND THEN 
--		CALL fgl_winmessage("ERROR",kandoomsg2("A",9003,""),"ERROR") #9003 Company NOT SET up -
--		RETURN 
--	END IF 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = '1' 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("A",9107,""),"ERROR") 	#9107 AR Parms NOT SET up -
		RETURN 
	END IF 

	SELECT * INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND inv_num = p_invnum 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("A",9155,p_invnum),"ERROR") 	#9155 Logic Error: Invoice does NOT exist
		RETURN 
	END IF 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("A",9067,p_cust),"ERROR") 	#9067 Logic Error: Customer does NOT exist
		RETURN 
	END IF 

	IF l_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		SELECT * INTO l_rec_customership.* 
		FROM customership 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_invoicehead.org_cust_code 
		AND ship_code = l_rec_invoicehead.ship_code 
	ELSE 
		SELECT * INTO l_rec_customership.* 
		FROM customership 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_invoicehead.cust_code 
		AND ship_code = l_rec_invoicehead.ship_code 
	END IF 

	IF glob_rec_company.module_text[5] = "E" THEN 
		CALL eo_lineshow(p_cmpy, 
		l_rec_arparms.*, 
		l_rec_invoicehead.*, 
		l_rec_customer.*, 
		l_rec_customership.* ) 
	ELSE 
		CALL inv_lineshow(p_cmpy, 
		l_rec_arparms.*, 
		l_rec_invoicehead.*, 
		l_rec_customer.*, 
		l_rec_customership.*) 
	END IF 

	RETURN 
END FUNCTION 
####################################################################
# END FUNCTION lineshow(p_cmpy, p_cust, p_invnum, p_func_type)
####################################################################


####################################################################
# FUNCTION inv_lineshow(p_cmpy,p_rec_arparms,p_rec_invoicehead,p_rec_customer,p_rec_customership)
#
#
####################################################################
FUNCTION inv_lineshow(p_cmpy,p_rec_arparms,p_rec_invoicehead,p_rec_customer,p_rec_customership) 
	DEFINE p_cmpy LIKE customer.cmpy_code
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_customership RECORD LIKE customership.*
	DEFINE A144 SMALLINT --silly window status variable based on terrible hand crafted window manager
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_invoicedetl DYNAMIC ARRAY OF RECORD 
				scroll_flag CHAR(1), 
				line_num LIKE invoicedetl.line_num, 
				part_code LIKE invoicedetl.part_code, 
				line_text LIKE invoicedetl.line_text, 
				ship_qty LIKE invoicedetl.ship_qty, 
				unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
				line_total_amt LIKE invoicedetl.line_total_amt 
			 END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_conversion_qty FLOAT 

	IF A144 < 1 THEN 
		LET A144 = A144 + 1 
		CALL open_window( 'A144', A144 ) 
	ELSE 
		CALL fgl_winmessage("ERROR",kandoomsg2("U",9917,""),"ERROR") 	#9917 Window IS already OPEN
		RETURN 
	END IF 

	DECLARE c_invdetl CURSOR FOR 
	SELECT invoicedetl.* FROM invoicedetl 
	WHERE inv_num = p_rec_invoicehead.inv_num 
	AND cust_code = p_rec_invoicehead.cust_code 
	AND cmpy_code = p_cmpy 
	LET l_idx = 0 

	FOREACH c_invdetl INTO l_rec_invoicedetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_invoicedetl[l_idx].line_num = l_rec_invoicedetl.line_num 
		LET l_arr_invoicedetl[l_idx].part_code = l_rec_invoicedetl.part_code 
		LET l_arr_invoicedetl[l_idx].line_text = l_rec_invoicedetl.line_text 
		LET l_arr_invoicedetl[l_idx].ship_qty = l_rec_invoicedetl.ship_qty 

		IF glob_rec_company.module_text[23] = "W" 
		AND l_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
			IF l_rec_invoicedetl.price_uom_code != l_rec_invoicedetl.uom_code THEN 
				LET l_conversion_qty = get_uom_conversion_factor(p_cmpy, l_rec_invoicedetl.part_code, l_rec_invoicedetl.uom_code, l_rec_invoicedetl.price_uom_code,1) 
				IF l_conversion_qty <= 0 THEN 
					LET l_rec_invoicedetl.unit_sale_amt = NULL 
				ELSE 
					LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
				END IF 
			END IF 
		END IF 

		LET l_arr_invoicedetl[l_idx].unit_sale_amt = l_rec_invoicedetl.unit_sale_amt 

		IF p_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.line_total_amt 
		ELSE 
			LET l_arr_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.ext_sale_amt 
		END IF 

	END FOREACH 

	LET p_rec_customer.name_text = p_rec_invoicehead.name_text 
	MESSAGE kandoomsg2("A",1037,"") #1037 " RETURN FOR line details - CTRL N FOR Notes"

	IF p_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		DISPLAY p_rec_invoicehead.org_cust_code TO invoicehead.cust_code 
	ELSE 
		DISPLAY BY NAME p_rec_invoicehead.cust_code 
	END IF 

	DISPLAY BY NAME 
		p_rec_customer.name_text, 
		l_rec_invoicedetl.ware_code, 
		p_rec_customer.currency_code, 
		p_rec_invoicehead.goods_amt, 
		p_rec_invoicehead.tax_amt, 
		p_rec_invoicehead.total_amt 

	DISPLAY ARRAY l_arr_invoicedetl TO sr_invoicedetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","invdfunc","display-arr-invoicedetl") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT l_arr_invoicedetl.getSize())
			CALL dialog.setActionHidden("FINANCIAL STATUS",NOT l_arr_invoicedetl.getSize())
			CALL dialog.setActionHidden("NOTES",NOT l_arr_invoicedetl.getSize())						
			CALL dialog.setActionHidden("GL_ACCOUNT",NOT l_arr_invoicedetl.getSize())						

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LINE AMOUNT" --ON KEY (control-t) # line amount DISPLAY 
			CALL dispgpfunc(
				p_rec_invoicehead.currency_code, 
				p_rec_invoicehead.cost_amt, 
				p_rec_invoicehead.goods_amt) 

		ON ACTION "NOTES" --ON KEY (control-n) --notes viewer 
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicedetl.getSize()) THEN
				SELECT line_text INTO l_rec_invoicedetl.line_text 
				FROM invoicedetl 
				WHERE inv_num = p_rec_invoicehead.inv_num 
				AND line_num = l_arr_invoicedetl[l_idx].line_num 
	
				IF l_rec_invoicedetl.line_text[1,3] = "###" 
				AND l_rec_invoicedetl.line_text[16,18] = "###" THEN 
					CALL note_disp(p_cmpy,l_rec_invoicedetl.line_text[4,15]) 
				ELSE 
					ERROR kandoomsg2("A",7027,"")		#7027 No Notes TO View
				END IF 
			END IF
			
		ON ACTION "FINANCIAL STATUS" --ON KEY (control-p) #?? dispgpfunc () some financial STATUS 
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicedetl.getSize()) THEN
				SELECT * INTO l_rec_invoicedetl.* 
				FROM invoicedetl 
				WHERE cmpy_code = p_cmpy 
				AND inv_num = p_rec_invoicehead.inv_num 
				AND line_num = l_arr_invoicedetl[l_idx].line_num 
				
				CALL dispgpfunc(p_rec_invoicehead.currency_code, l_rec_invoicedetl.ext_cost_amt, l_rec_invoicedetl.ext_sale_amt) 
			END IF
			
		ON ACTION "EDIT" 
			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicedetl.getSize()) THEN		 
				SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
				WHERE cmpy_code = p_cmpy 
				AND inv_num = p_rec_invoicehead.inv_num 
				AND line_num = l_arr_invoicedetl[l_idx].line_num
				 
				IF glob_rec_company.module_text[23] = "W" 
				AND l_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
					IF l_rec_invoicedetl.price_uom_code != l_rec_invoicedetl.uom_code THEN 
						LET l_conversion_qty = get_uom_conversion_factor(p_cmpy, l_rec_invoicedetl.part_code,l_rec_invoicedetl.uom_code,l_rec_invoicedetl.price_uom_code,1) 
						IF l_conversion_qty <= 0 THEN 
							LET l_rec_invoicedetl.unit_sale_amt = NULL 
						ELSE 
							LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
						END IF 
					END IF 
				END IF 
				CALL inv_show(l_rec_invoicedetl.*) 

				CALL dialog.setActionHidden("EDIT",NOT l_arr_invoicedetl.getSize())
				CALL dialog.setActionHidden("FINANCIAL STATUS",NOT l_arr_invoicedetl.getSize())
				CALL dialog.setActionHidden("NOTES",NOT l_arr_invoicedetl.getSize())						
				CALL dialog.setActionHidden("GL_ACCOUNT",NOT l_arr_invoicedetl.getSize())						

			END IF
{			
		ON KEY (tab) --duplicate TO edit 
			LET l_idx = arr_curr() 
			SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
			WHERE cmpy_code = p_cmpy 
			AND inv_num = p_rec_invoicehead.inv_num 
			AND line_num = l_arr_invoicedetl[l_idx].line_num 

			IF glob_rec_company.module_text[23] = "W" 
			AND l_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
				IF l_rec_invoicedetl.price_uom_code != l_rec_invoicedetl.uom_code THEN 
					LET l_conversion_qty = get_uom_conversion_factor(p_cmpy, l_rec_invoicedetl.part_code, 
					l_rec_invoicedetl.uom_code, 
					l_rec_invoicedetl.price_uom_code,1) 
					IF l_conversion_qty <= 0 THEN 
						LET l_rec_invoicedetl.unit_sale_amt = NULL 
					ELSE 
						LET l_rec_invoicedetl.unit_sale_amt 
						= l_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
					END IF 
				END IF 
			END IF 

			CALL inv_show(l_rec_invoicedetl.*) 
}
		ON ACTION "GL_ACCOUNT" #on KEY (RETURN) --show distribution account ? 
			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicedetl.getSize()) THEN			 
				SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
				WHERE cmpy_code = p_cmpy 
				AND inv_num = p_rec_invoicehead.inv_num 
				AND line_num = l_arr_invoicedetl[l_idx].line_num 
	
				IF glob_rec_company.module_text[23] = "W"	AND l_rec_invoicedetl.price_uom_code IS NOT NULL THEN 
					IF l_rec_invoicedetl.price_uom_code != l_rec_invoicedetl.uom_code THEN
						LET l_conversion_qty = get_uom_conversion_factor(p_cmpy, l_rec_invoicedetl.part_code,l_rec_invoicedetl.uom_code,l_rec_invoicedetl.price_uom_code,1) 
						IF l_conversion_qty <= 0 THEN 
							LET l_rec_invoicedetl.unit_sale_amt = NULL 
						ELSE 
							LET l_rec_invoicedetl.unit_sale_amt	= l_rec_invoicedetl.unit_sale_amt * l_conversion_qty 
						END IF 
					END IF 
				END IF 

				CALL inv_show(l_rec_invoicedetl.*) 

			END IF

	END DISPLAY 

	CALL close_win( 'A144', A144 ) 

	LET A144 = A144 - 1 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	RETURN 
END FUNCTION 
####################################################################
# END FUNCTION inv_lineshow(p_cmpy,p_rec_arparms,p_rec_invoicehead,p_rec_customer,p_rec_customership)
####################################################################


####################################################################
# FUNCTION inv_show(p_rec_invoicedetl)
####################################################################
FUNCTION inv_show(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_rec_invoicedetl.cmpy_code 
	AND part_code = p_rec_invoicedetl.part_code 
	AND ware_code = p_rec_invoicedetl.ware_code 

	OPEN WINDOW A145 with FORM "A145" 
	CALL windecoration_a("A145") 

	DISPLAY BY NAME 
		p_rec_invoicedetl.part_code, 
		p_rec_invoicedetl.line_text, 
		p_rec_invoicedetl.ship_qty, 
		p_rec_invoicedetl.level_code, 
		p_rec_invoicedetl.list_price_amt, 
		p_rec_invoicedetl.unit_sale_amt, 
		p_rec_invoicedetl.ext_sale_amt, 
		p_rec_invoicedetl.unit_tax_amt, 
		p_rec_invoicedetl.ext_tax_amt, 
		p_rec_invoicedetl.line_total_amt 

	DISPLAY BY NAME p_rec_invoicedetl.ware_code attribute(yellow) 

	OPEN WINDOW A104 with FORM "A104" 
	CALL windecoration_a("A104") 

	LET l_rec_coa.acct_code = p_rec_invoicedetl.line_acct_code 
	DISPLAY l_rec_coa.acct_code TO coa.acct_code
	DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text 

	CALL eventsuspend() 

	CLOSE WINDOW A104 
	CLOSE WINDOW A145 
END FUNCTION 
####################################################################
# END FUNCTION inv_show(p_rec_invoicedetl)
####################################################################


####################################################################
# FUNCTION eo_lineshow( p_cmpy, p_rec_arparms, p_rec_p_rec_invoicehead,
####################################################################
FUNCTION eo_lineshow(p_cmpy,p_rec_arparms,p_rec_invoicehead,p_rec_customer,p_rec_customership) 
	#   define tempStr STRING
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*	
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_customership RECORD LIKE customership.*
  DEFINE A630 SMALLINT #silly windows counter
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_ps_invoicedetl DYNAMIC ARRAY OF RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF RECORD 
				scroll_flag CHAR(1), 
				offer_code LIKE invoicedetl.offer_code, 
				part_code LIKE invoicedetl.part_code, 
				ship_qty LIKE invoicedetl.ship_qty, 
				back_ind CHAR(1), 
				sold_qty LIKE invoicedetl.sold_qty, 
				list_price_amt LIKE invoicedetl.list_price_amt, 
				disc_per LIKE invoicedetl.disc_per, 
				unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
				line_total_amt LIKE invoicedetl.line_total_amt 
			 END RECORD 
	DEFINE l_doc_ind_text CHAR(3) 
	DEFINE l_frght_hndl_amt LIKE invoicehead.hand_amt 
	DEFINE l_line_text LIKE invoicedetl.line_text 
	DEFINE l_ref_text CHAR(32) 
	DEFINE l_gross_dollar MONEY(12,2) 
	DEFINE l_gross_percent DECIMAL(8,3) 
	DEFINE l_markup_percent DECIMAL(8,3)
	DEFINE l_inv_desc CHAR(7) 
	DEFINE l_idx SMALLINT 
	DEFINE l_inv_query_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 

	#call fgl_winmessage("..",":.","info")

	LET l_ref_text = p_rec_arparms.inv_ref1_text CLIPPED, "................" 

	WHENEVER ERROR CONTINUE
	OPEN WINDOW A630 WITH FORM "A630"
	IF status < 0 THEN
		CURRENT WINDOW IS A630
	END IF
	
--	IF A630 < 1 THEN 
--		LET A630 = A630 + 1 
--		CALL open_window( 'A630', A630 ) #Open window with stupid  
--	ELSE 
--		MESSAGE kandoomsg2("A",9215,"") 	#9215 " Searching database - please wait"
--		RETURN 
--	END IF 

	#@debug
	#input tempStr FROM inv_ref1_text

	SELECT * INTO l_rec_orderhead.* 
	FROM orderhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_rec_invoicehead.cust_code 
	AND order_num = p_rec_invoicehead.ord_num 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_orderhead.order_date = NULL 
	END IF 

	CASE p_rec_invoicehead.inv_ind 
		WHEN "1" 
			LET l_doc_ind_text = "A-R" 
		WHEN "2" 
			LET l_doc_ind_text = "NOR" 
		WHEN "3" 
			LET l_doc_ind_text = TRAN_TYPE_JOB_JOB 
		WHEN "4" 
			LET l_doc_ind_text = "ADJ" 
		WHEN "5" 
			LET l_doc_ind_text = "PRE" 
		OTHERWISE 
			LET l_doc_ind_text = "NOR" 
	END CASE 

	SELECT * INTO l_rec_condsale.* 
	FROM condsale 
	WHERE cmpy_code = p_cmpy 
	AND cond_code = p_rec_invoicehead.cond_code 

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,p_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.*
	
	LET l_frght_hndl_amt = p_rec_invoicehead.hand_amt + p_rec_invoicehead.freight_amt 
--menu
--  on action "exit"
--  	exit menu
--end menu
 
	DISPLAY p_rec_invoicehead.cust_code TO  cust_code
	DISPLAY p_rec_customer.name_text TO name_text 
	DISPLAY p_rec_invoicehead.inv_num TO inv_num 
	DISPLAY p_rec_invoicehead.job_code TO job_code 
	DISPLAY p_rec_invoicehead.inv_date TO inv_date 
	DISPLAY p_rec_invoicehead.cond_code TO cond_code
	DISPLAY p_rec_invoicehead.sale_code TO sale_code 
	DISPLAY p_rec_invoicehead.ord_num TO ord_num
	DISPLAY l_rec_orderhead.order_date TO order_date
	DISPLAY p_rec_invoicehead.goods_amt TO goods_amt 
	DISPLAY p_rec_invoicehead.tax_amt TO tax_amt
	DISPLAY p_rec_invoicehead.total_amt TO total_amt 

	DISPLAY p_rec_invoicehead.currency_code TO currency_code ATTRIBUTE(GREEN)

	DISPLAY l_ref_text TO inv_ref1_text ATTRIBUTE(WHITE)

	DISPLAY l_doc_ind_text TO doc_ind_text 
	DISPLAY l_rec_condsale.desc_text TO cond_desc_text 
	DISPLAY l_rec_salesperson.name_text TO sale_name_text 
	DISPLAY l_frght_hndl_amt TO frght_hndl_amt

	WHILE TRUE 
		SELECT line_num 
		FROM invoicedetl 
		WHERE cmpy_code = p_cmpy 
		AND inv_num = p_rec_invoicehead.inv_num 
		AND line_num = 101 

		IF STATUS = NOTFOUND THEN 
			LET l_inv_query_text = "1=1" 
		ELSE 
			MESSAGE kandoomsg2("A",1001,"") 		#A1001 Enter selection etc.

			CONSTRUCT BY NAME l_inv_query_text ON 
				offer_code, 
				part_code, 
				ship_qty, 
				sold_qty, 
				list_price_amt, 
				disc_per, 
				unit_sale_amt, 
				line_total_amt 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","invdfunc","construct-invoicedetl") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				CALL close_win( 'A630', A630 ) 
				LET A630 = A630 - 1 
				RETURN 
			END IF 
		END IF 

		LET l_query_text = "SELECT * ", 
		"FROM invoicedetl ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		" AND cust_code = \"",p_rec_invoicehead.cust_code CLIPPED,"\" ", 
		" AND inv_num = ",p_rec_invoicehead.inv_num CLIPPED," ", 
		" AND ",l_inv_query_text CLIPPED," ", 
		" ORDER BY offer_code, line_num" 

		MESSAGE kandoomsg2("I",1002,"") 	#1002 " Searching database - please wait"
		PREPARE s_invdetl2 FROM l_query_text 
		DECLARE c_invdetl2 SCROLL CURSOR FOR s_invdetl2 
		LET l_idx = 0 

		FOREACH c_invdetl2 INTO l_rec_invoicedetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_ps_invoicedetl[l_idx].* = l_rec_invoicedetl.* 
			LET l_arr_rec_invoicedetl[l_idx].scroll_flag = NULL 
			LET l_arr_rec_invoicedetl[l_idx].offer_code = l_rec_invoicedetl.offer_code 
			LET l_arr_rec_invoicedetl[l_idx].part_code = l_rec_invoicedetl.part_code 
			LET l_arr_rec_invoicedetl[l_idx].ship_qty = l_rec_invoicedetl.ship_qty 

			IF l_arr_rec_invoicedetl[l_idx].ship_qty IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].ship_qty = 0 
			END IF 

			IF l_rec_invoicedetl.back_qty > 0 THEN 
				LET l_arr_rec_invoicedetl[l_idx].back_ind = "*" 
			END IF 
			LET l_arr_rec_invoicedetl[l_idx].sold_qty = l_rec_invoicedetl.sold_qty 
			IF l_arr_rec_invoicedetl[l_idx].sold_qty IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].sold_qty = 0 
			END IF 
			LET l_arr_rec_invoicedetl[l_idx].list_price_amt = l_rec_invoicedetl.list_price_amt 
			IF l_arr_rec_invoicedetl[l_idx].list_price_amt IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].list_price_amt = 0 
			END IF 
			LET l_arr_rec_invoicedetl[l_idx].disc_per = l_rec_invoicedetl.disc_per 
			IF l_arr_rec_invoicedetl[l_idx].disc_per IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].disc_per = 0 
			END IF 
			LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = l_rec_invoicedetl.unit_sale_amt 
			IF l_arr_rec_invoicedetl[l_idx].unit_sale_amt IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = 0 
			END IF 
			IF p_rec_arparms.show_tax_flag = "Y" THEN 
				LET l_arr_rec_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.line_total_amt 
			ELSE 
				LET l_arr_rec_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.ext_sale_amt 
			END IF 
			IF l_arr_rec_invoicedetl[l_idx].line_total_amt IS NULL THEN 
				LET l_arr_rec_invoicedetl[l_idx].line_total_amt = 0 
			END IF 

		END FOREACH 

		IF l_idx = 0 THEN 
			ERROR kandoomsg2("A",9004,"") 		#A9004 no entries matcjh etc
			#huho - so, if it's empty if loops for ever ????
			# I'll add an EXIT for now
			EXIT WHILE --huho @check 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	MESSAGE kandoomsg2("A",1053,"") #1053  RETURN - View Details  F8 - View Header; CTRL n Notes ...

	DISPLAY ARRAY l_arr_rec_invoicedetl TO sr_invoicedetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","invdfunc","input-arr-invoicedetl") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("SERIAL DETAILS",NOT l_arr_rec_invoicedetl.getSize())
			CALL dialog.setActionHidden("VIEW HEADER",NOT l_arr_rec_invoicedetl.getSize())						
			CALL dialog.setActionHidden("NOTES",NOT l_arr_rec_invoicedetl.getSize())						
			CALL dialog.setActionHidden("LINE TOTAL",NOT l_arr_rec_invoicedetl.getSize())
			CALL dialog.setActionHidden("TOTALS",NOT l_arr_rec_invoicedetl.getSize())
			CALL dialog.setActionHidden("GL DISTRIBUTION",NOT l_arr_rec_invoicedetl.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "SERIAL DETAILS"	--ON KEY (F9)
 			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN			 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_arr_rec_invoicedetl[l_idx].part_code 
				AND serial_flag = 'Y' 
				IF STATUS <> NOTFOUND THEN 
					CALL run_prog("I33", l_arr_rec_invoicedetl[l_idx].part_code, '', p_rec_invoicehead.inv_num, 'S' ) 
				ELSE 
					ERROR kandoomsg2("I",9288,"") 			#9288 This IS NOT a Serial Item
				END IF 
			END IF
			
		ON ACTION "VIEW HEADER"	--ON KEY (F8) -- 
 			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN		 
				IF l_arr_ps_invoicedetl[l_idx].line_num != 0 THEN 
					CALL disc_per_head( p_cmpy, p_rec_invoicehead.cust_code, p_rec_invoicehead.inv_num ) 
				END IF 
			END IF
			
		ON ACTION "NOTES"	--ON KEY (control-n)
 			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN		 
				IF l_arr_ps_invoicedetl[l_idx].line_text[1,3] = "###" AND l_arr_ps_invoicedetl[l_idx].line_text[16,18] = "###" THEN 
					CALL note_disp( p_cmpy, l_arr_ps_invoicedetl[l_idx].line_text[4,15] ) 
				ELSE 
					ERROR kandoomsg2("A",7027,"") 			#1002 "No notes TO view"
				END IF 
			END IF
						
		ON ACTION "LINE TOTAL"	--ON KEY (control-p)
 			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN	 
				LET l_inv_desc = "Line" 
				LET l_gross_dollar = l_arr_ps_invoicedetl[l_idx].ext_sale_amt - l_arr_ps_invoicedetl[l_idx].ext_cost_amt 
				IF l_arr_ps_invoicedetl[l_idx].ext_sale_amt = 0 OR l_arr_ps_invoicedetl[l_idx].ext_sale_amt IS NULL THEN 
					LET l_gross_percent = 0 
				ELSE 
					LET l_gross_percent = ( (l_gross_dollar * 100) / l_arr_ps_invoicedetl[l_idx].ext_sale_amt) 
				END IF 
	
				IF l_arr_ps_invoicedetl[l_idx].ext_cost_amt = 0 OR l_arr_ps_invoicedetl[l_idx].ext_cost_amt IS NULL THEN 
					LET l_markup_percent = 0 
				ELSE 
					LET l_markup_percent = ( (l_gross_dollar * 100) /	l_arr_ps_invoicedetl[l_idx].ext_cost_amt) 
				END IF 
	
				-----------------------------------------------
				OPEN WINDOW A142 with FORM "A142" 
				CALL windecoration_a("A142") 
	
				DISPLAY l_inv_desc TO inv_type 
				DISPLAY l_gross_dollar TO gp_dollar 
				DISPLAY l_gross_percent TO gp 
				DISPLAY l_markup_percent TO mu 
				DISPLAY l_arr_ps_invoicedetl[l_idx].ext_sale_amt TO mats 
				DISPLAY l_arr_ps_invoicedetl[l_idx].ext_cost_amt TO costs 
	
				CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 
				CLOSE WINDOW A142 
				-----------------------------------------------
			END IF
			
		ON ACTION "TOTALS"	--ON KEY (control-t) --view invoice totals 		# work out invoice totals
			LET l_inv_desc = "Total" 
			LET l_gross_dollar = p_rec_invoicehead.goods_amt - p_rec_invoicehead.cost_amt 

			IF p_rec_invoicehead.goods_amt = 0 OR p_rec_invoicehead.goods_amt IS NULL THEN 
				LET l_gross_percent = 0 
			ELSE 
				LET l_gross_percent = ((l_gross_dollar * 100)/ p_rec_invoicehead.goods_amt) 
			END IF 

			IF p_rec_invoicehead.cost_amt = 0 OR p_rec_invoicehead.cost_amt IS NULL THEN 
				LET l_markup_percent = 0 
			ELSE 
				LET l_markup_percent = ((l_gross_dollar * 100)/ p_rec_invoicehead.cost_amt) 
			END IF 

			-----------------------------------------------
			OPEN WINDOW A142 with FORM "A142" 
			CALL windecoration_a("A142") 

			DISPLAY l_inv_desc TO inv_type 
			DISPLAY l_gross_dollar TO gp_dollar 
			DISPLAY l_gross_percent TO gp 
			DISPLAY l_markup_percent TO mu 
			DISPLAY p_rec_invoicehead.goods_amt TO mats 
			DISPLAY p_rec_invoicehead.cost_amt TO costs 

			CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 

			CLOSE WINDOW A142 

		ON ACTION "GL DISTRIBUTION"
 			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN	 
			 
				#BEFORE FIELD offer_code
				IF l_arr_ps_invoicedetl[l_idx].line_num != 0 THEN 
					CALL expand_line( p_cmpy, l_arr_ps_invoicedetl[l_idx].*, p_rec_arparms.* ) --gl distribution account 
				END IF 
				#NEXT FIELD scroll_flag
			END IF

		BEFORE ROW 
			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicedetl.getSize()) THEN		 
				 
				#LET scrn = scr_line()
				#DISPLAY l_arr_rec_invoicedetl[l_idx].*
				#     TO sr_invoicedetl[scrn].*
	
				LET l_line_text = NULL 
				LET l_rec_offersale.desc_text = NULL 
				IF l_arr_ps_invoicedetl[l_idx].line_text[1,3] = "###" 
				AND l_arr_ps_invoicedetl[l_idx].line_text[16,18] = "###" THEN 
					IF l_arr_ps_invoicedetl[l_idx].part_code IS NOT NULL THEN 
						SELECT desc_text INTO l_line_text 
						FROM product 
						WHERE cmpy_code = p_cmpy 
						AND part_code = l_arr_ps_invoicedetl[l_idx].part_code 
					ELSE 
						LET l_line_text = l_arr_ps_invoicedetl[l_idx].line_text 
					END IF 
				ELSE 
					LET l_line_text = l_arr_ps_invoicedetl[l_idx].line_text 
				END IF 
	
				SELECT * INTO l_rec_offersale.* 
				FROM offersale 
				WHERE cmpy_code = p_cmpy 
				AND offer_code = l_arr_ps_invoicedetl[l_idx].offer_code 
	
				DISPLAY BY NAME 
					l_rec_offersale.desc_text, 
					l_arr_ps_invoicedetl[l_idx].ware_code, 
					l_arr_ps_invoicedetl[l_idx].tax_code, 
					l_arr_ps_invoicedetl[l_idx].ext_tax_amt 
					DISPLAY l_line_text	TO line_text 
			END IF
			
			#AFTER FIELD scroll_flag
			#   IF fgl_lastkey() = fgl_keyval("accept")
			#   AND fgl_fglgui() THEN
			#      NEXT FIELD offer_code
			#   END IF
			#
			#   LET l_arr_rec_invoicedetl[l_idx].scroll_flag = NULL
			#   IF fgl_lastkey() = fgl_keyval("down") THEN
			#      IF l_idx >300
			#      OR l_arr_ps_invoicedetl[l_idx+1].line_num = 0
			#      OR arr_curr() >= arr_count() THEN
			#         ERROR kandoomsg2("A",9001,"")		#         #9001 There no more rows...
			#     #          NEXT FIELD scroll_flag
			#      END IF
			#   END IF




	END DISPLAY 
	-----------------------------------------------
	
	#CALL open_window( 'A630', A630 )
	CALL close_win( 'A630', A630 ) 

	LET A630 = A630 - 1 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
####################################################################
# END FUNCTION eo_lineshow( p_cmpy, p_rec_arparms, p_rec_p_rec_invoicehead,
####################################################################


####################################################################
# FUNCTION expand_line( p_cmpy, p_rec_invoicedetl, p_rec_arparms )
####################################################################
FUNCTION expand_line(p_cmpy,p_rec_invoicedetl,p_rec_arparms) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE p_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_line_text LIKE invoicedetl.line_text 
	DEFINE l_ext_price_amt LIKE invoicedetl.line_total_amt 
	DEFINE l_cur_avail_qty LIKE prodstatus.onhand_qty 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING l_rec_opparms.*

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_rec_invoicedetl.part_code 
	AND ware_code = p_rec_invoicedetl.ware_code 

	IF p_rec_invoicedetl.disc_per IS NULL THEN 
		LET p_rec_invoicedetl.disc_per = 0 
	END IF 

	OPEN WINDOW A631 with FORM "A631" 
	CALL windecoration_a("A631") 

	DISPLAY BY NAME 
		p_rec_invoicedetl.part_code, 
		p_rec_invoicedetl.bonus_qty, 
		p_rec_invoicedetl.sold_qty, 
		p_rec_invoicedetl.ord_qty, 
		p_rec_invoicedetl.uom_code, 
		p_rec_invoicedetl.prev_qty, 
		p_rec_invoicedetl.ship_qty, 
		p_rec_invoicedetl.back_qty, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		p_rec_invoicedetl.level_code, 
		p_rec_invoicedetl.disc_per, 
		p_rec_invoicedetl.list_price_amt, 
		p_rec_invoicedetl.unit_sale_amt, 
		p_rec_invoicedetl.unit_tax_amt, 
		p_rec_invoicedetl.ext_tax_amt, 
		p_rec_invoicedetl.line_total_amt 

	IF p_rec_arparms.show_tax_flag = "Y" THEN 
		DISPLAY BY NAME p_rec_invoicedetl.line_total_amt 
	ELSE 
		DISPLAY p_rec_invoicedetl.ext_sale_amt TO line_total_amt 
	END IF 
	
	LET l_ext_price_amt = p_rec_invoicedetl.sold_qty * p_rec_invoicedetl.unit_sale_amt 
	
	DISPLAY l_ext_price_amt TO formonly.ext_price_amt 

	IF l_rec_opparms.cal_available_flag = "N" THEN 
		LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
	ELSE 
		LET l_cur_avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
	END IF 

	LET l_line_text = NULL 

	IF p_rec_invoicedetl.line_text[1,3] = "###" AND p_rec_invoicedetl.line_text[16,18] = "###" THEN 
		IF p_rec_invoicedetl.part_code IS NOT NULL THEN 
			SELECT desc_text INTO l_line_text 
			FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_rec_invoicedetl.part_code 
		END IF 
	ELSE 
		LET l_line_text = p_rec_invoicedetl.line_text 
	END IF 

	DISPLAY p_rec_invoicedetl.ware_code TO st_ware  ATTRIBUTE(yellow)

	DISPLAY l_line_text TO line_text 
	DISPLAY l_cur_avail_qty TO avail 

	OPEN WINDOW A104 with FORM "A104" 
	CALL windecoration_a("A104") 

	LET l_rec_coa.acct_code = p_rec_invoicedetl.line_acct_code 
	
	DISPLAY l_rec_coa.acct_code TO coa.acct_code
	DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text 

	CALL eventsuspend() 
	CLOSE WINDOW A104 
	CLOSE WINDOW A631 

END FUNCTION 
####################################################################
# END FUNCTION expand_line( p_cmpy, p_rec_invoicedetl, p_rec_arparms )
####################################################################