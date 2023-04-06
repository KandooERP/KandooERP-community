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

	Source code beautified by beautify.pl on 2020-01-02 10:35:27	$Id: $
}



#
# FUNCTION pohdwind displays the po header
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION pohdwind(p_cmpy_code,p_order_num)
#
#
############################################################
FUNCTION pohdwind(p_cmpy_code,p_order_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num LIKE purchhead.order_num 

	OPEN WINDOW r107 with FORM "R107" 
	CALL winDecoration_r("R107") 

	CALL display_vend(p_cmpy_code,p_order_num) 

	MENU " Purchase Order" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","pohdwind","menu-purchase-ORDER") 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Lines" " View purchase ORDER line information" 
			CALL podewind(p_cmpy_code,p_order_num) 

		COMMAND "Delivery" " View delivery information FOR purchase ORDER" 
			CALL disp_po_deliv(p_cmpy_code,p_order_num) 

		COMMAND KEY(interrupt,escape,"E") "Exit" " Exit FROM this query" 
			EXIT MENU 

	END MENU 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW r107 

END FUNCTION 


############################################################
# FUNCTION display_vend(p_cmpy_code,p_order_num)
#
#
############################################################
FUNCTION display_vend(p_cmpy_code,p_order_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num LIKE purchhead.order_num 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_total 
	RECORD 
		order_amt DECIMAL(16,2), 
		received_amt DECIMAL(16,2), 
		voucher_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_tmp_amt DECIMAL(16,2) 

	SELECT * INTO l_rec_purchhead.* 
	FROM purchhead 
	WHERE purchhead.order_num = p_order_num 
	AND cmpy_code = p_cmpy_code 
	SELECT name_text INTO l_rec_vendor.name_text 
	FROM vendor 
	WHERE vend_code = l_rec_purchhead.vend_code 
	AND cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		LET l_rec_vendor.name_text = "" 
	END IF 

	IF l_rec_purchhead.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_warehouse.desc_text 
		FROM warehouse 
		WHERE ware_code = l_rec_purchhead.ware_code 
		AND cmpy_code = p_cmpy_code 
		IF status = notfound THEN 
			LET l_rec_warehouse.desc_text = "" 
		END IF 
	END IF 

	CLEAR FORM 

	DISPLAY BY NAME l_rec_purchhead.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_purchhead.order_num, 
	l_rec_purchhead.order_text, 
	l_rec_purchhead.salesperson_text, 
	l_rec_purchhead.ware_code, 
	l_rec_warehouse.desc_text, 
	l_rec_purchhead.status_ind, 
	l_rec_purchhead.printed_flag, 
	l_rec_purchhead.confirm_ind, 
	l_rec_purchhead.confirm_text, 
	l_rec_purchhead.authorise_code, 
	l_rec_purchhead.order_date, 
	l_rec_purchhead.enter_code, 
	l_rec_purchhead.entry_date, 
	l_rec_purchhead.due_date, 
	l_rec_purchhead.confirm_date, 
	l_rec_purchhead.cancel_date, 
	l_rec_purchhead.com1_text, 
	l_rec_purchhead.com2_text, 
	l_rec_purchhead.year_num, 
	l_rec_purchhead.period_num, 
	l_rec_purchhead.conv_qty 

	DISPLAY BY NAME l_rec_purchhead.curr_code 
	attribute(green) 

	CALL po_head_info(p_cmpy_code,l_rec_purchhead.order_num) 
	RETURNING l_rec_total.*,l_tmp_amt 

	DISPLAY BY NAME l_rec_total.* 

END FUNCTION 


############################################################
# FUNCTION disp_po_deliv(p_cmpy_code,p_order_num)
#
#
############################################################
FUNCTION disp_po_deliv(p_cmpy_code,p_order_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num LIKE purchhead.order_num 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 

	SELECT * INTO l_rec_purchhead.* 
	FROM purchhead 
	WHERE purchhead.order_num = p_order_num 
	AND cmpy_code = p_cmpy_code 

	OPEN WINDOW r106 with FORM "R106" 
	CALL winDecoration_r("R106") 

	DISPLAY BY NAME 
		l_rec_purchhead.del_name_text, 
		l_rec_purchhead.del_addr1_text, 
		l_rec_purchhead.del_addr2_text, 
		l_rec_purchhead.del_addr3_text, 
		l_rec_purchhead.del_addr4_text, 
		l_rec_purchhead.del_country_code, --@db-patch_2020_10_04--
		l_rec_purchhead.contact_text, 
		l_rec_purchhead.tele_text 

	CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 
	CLOSE WINDOW r106 
END FUNCTION 
