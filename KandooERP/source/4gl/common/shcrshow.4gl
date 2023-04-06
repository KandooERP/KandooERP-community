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
# FUNCTION ship_cred_show(p_cmpy,p_cust,p_ship_code,p_func_type)
#
# \brief module show_cred_ship - displays credit shipment header AND allows the user
###########################################################################
FUNCTION ship_cred_show(p_cmpy,p_cust,p_ship_code,p_func_type) 
	DEFINE p_cmpy LIKE vendor.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE p_func_type CHAR(14)
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_shipstatus RECORD LIKE shipstatus.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_arr_shipdetl DYNAMIC ARRAY OF RECORD 
		part_code LIKE shipdetl.part_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		desc_text LIKE shipdetl.desc_text, 
		landed_cost LIKE shipdetl.landed_cost, 
		line_total_amt LIKE shipdetl.line_total_amt 
	END RECORD 
	DEFINE l_idx SMALLINT
	
	INITIALIZE l_rec_shipdetl.* TO NULL 
	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	SELECT * INTO l_rec_shiphead.* FROM shiphead 
	WHERE shiphead.cmpy_code = p_cmpy 
	AND shiphead.vend_code = p_cust 
	AND shiphead.ship_code = p_ship_code 
	CASE 
		WHEN l_rec_shiphead.ship_type_ind = 1 
			LET p_func_type = " Import " 
		WHEN l_rec_shiphead.ship_type_ind = 2 
			LET p_func_type = " PO RETURN " 
		WHEN l_rec_shiphead.ship_type_ind = 3 
			LET p_func_type = "Credit Returns" 
	END CASE 

	WHENEVER ERROR CONTINUE 
	IF (status = notfound) THEN 
		ERROR "Shipment header NOT found" 
	END IF 

	SELECT * INTO l_rec_shipstatus.* FROM shipstatus 
	WHERE cmpy_code = p_cmpy 
	AND ship_status_code = l_rec_shiphead.ship_status_code 
	IF (status = notfound) THEN 
		ERROR "Shipment STATUS NOT found" 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF (status = notfound) THEN 
		ERROR "Customer master NOT found" 
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPEN WINDOW L155 with FORM "L155" 
	CALL windecoration_l("L155") -- albo kd-767 

	DECLARE curser_item CURSOR FOR 
	SELECT shipdetl.* 
	INTO l_rec_shipdetl.* 
	FROM shipdetl 
	WHERE shipdetl.ship_code = l_rec_shiphead.ship_code 
	AND shipdetl.cmpy_code = p_cmpy 
	ORDER BY line_num 

	LET l_idx = 0 
	FOREACH curser_item 
		LET l_idx = l_idx + 1 
		LET l_arr_shipdetl[l_idx].part_code = l_rec_shipdetl.part_code 
		LET l_arr_shipdetl[l_idx].desc_text = l_rec_shipdetl.desc_text 
		LET l_arr_shipdetl[l_idx].ship_inv_qty = l_rec_shipdetl.ship_inv_qty 
		LET l_arr_shipdetl[l_idx].landed_cost = l_rec_shipdetl.landed_cost 
		IF l_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_shipdetl[l_idx].line_total_amt = l_rec_shipdetl.line_total_amt 
		ELSE 
			LET l_arr_shipdetl[l_idx].line_total_amt = l_rec_shipdetl.landed_cost	* l_rec_shipdetl.ship_inv_qty 
		END IF 
	END FOREACH 
 
	MESSAGE "ESC TO EXIT,CTRL V view STATUS,CTRL N view notes,RETURN details " attribute(yellow) 
	DISPLAY BY NAME 
		l_rec_shiphead.vend_code, 
		l_rec_customer.currency_code, 
		l_rec_customer.name_text, 
		l_rec_shiphead.ware_code, 
		l_rec_shiphead.tax_code 

	DISPLAY BY NAME 
		l_rec_shiphead.fob_ent_cost_amt, 
		l_rec_shiphead.duty_ent_amt, 
		l_rec_shiphead.total_amt attribute (magenta)

	DISPLAY p_func_type TO func attribute(green) 

	DISPLAY ARRAY l_arr_shipdetl TO sr_shipdetl.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","shcrshow","input-arr-shipdetl")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
 			CALL dialog.setActionHidden("NOTES",NOT l_arr_shipdetl.getSize())
 			CALL dialog.setActionHidden("DETAIL",NOT l_arr_shipdetl.getSize())
 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "SHIPPING STATUS" --ON KEY (F5) 
			CALL ship_stat(p_cmpy, l_rec_shiphead.vend_code, l_rec_shiphead.ship_code) 
		
		ON ACTION "NOTES" --ON KEY (control-n)
			IF (l_idx > 0) AND (l_idx <= l_arr_shipdetl.getSize()) THEN
				SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
				WHERE shipdetl.cmpy_code = p_cmpy 
				AND shipdetl.ship_code = p_ship_code 
				AND shipdetl.line_num = l_idx 
				IF status = notfound THEN 
					ERROR "Shipment line NOT found" 
					SLEEP 3 
					EXIT program 
				END IF 
				
				IF l_rec_shipdetl.desc_text[1,3] = "###"	AND l_rec_shipdetl.desc_text[14,16] = "###" THEN 
					CALL note_disp(p_cmpy,l_rec_shipdetl.desc_text[4,13]) 
				ELSE 
					ERROR "No notes TO view" 
					SLEEP 2 
				END IF 
			END IF
			
		BEFORE ROW 
			LET l_idx = arr_curr() # SET up ARRAY variables 
			
		ON ACTION ("DETAIL","DOUBLECLICK") --BEFORE FIELD ship_inv_qty 
			IF (l_idx > 0) AND (l_idx <= l_arr_shipdetl.getSize()) THEN
				SELECT * INTO l_rec_shipdetl.* FROM shipdetl 
				WHERE cmpy_code = p_cmpy 
				AND shipdetl.ship_code = l_rec_shiphead.ship_code 
				AND shipdetl.line_num = l_idx 
				
				CALL detl_show(p_cmpy, l_rec_shipdetl.*, l_rec_shiphead.*) # pop up the window AND show the info... 
	
				CURRENT WINDOW IS L155 
			END IF
			
		AFTER ROW 
			INITIALIZE l_rec_shipdetl.* TO NULL 

	END DISPLAY 
	
	CLOSE WINDOW L155 

END FUNCTION 
###########################################################################
# END FUNCTION ship_cred_show(p_cmpy,p_cust,p_ship_code,p_func_type)
###########################################################################


###########################################################################
# FUNCTION detl_show(p_cmpy,p_shipdetl,p_shiphead)
#
#
###########################################################################
FUNCTION detl_show(p_cmpy,p_shipdetl,p_shiphead) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_shipdetl RECORD LIKE shipdetl.*
	DEFINE p_shiphead RECORD LIKE shiphead.* 

	OPEN WINDOW L157 with FORM "L157" 
	CALL windecoration_l("L157") -- albo kd-767 

	DISPLAY BY NAME 
		p_shipdetl.part_code, 
		p_shiphead.ware_code, 
		p_shipdetl.desc_text, 
		p_shipdetl.ship_inv_qty, 
		p_shipdetl.landed_cost, 
		p_shipdetl.line_total_amt, 
		p_shipdetl.duty_unit_ent_amt 

	IF p_shipdetl.part_code IS NULL THEN 
		OPEN WINDOW L142 with FORM "L142" 
		CALL windecoration_l("L142") -- albo kd-767 

		DISPLAY BY NAME p_shipdetl.acct_code 

		CALL eventsuspend()
		CLOSE WINDOW L142 
	ELSE 
		CALL eventsuspend()
	END IF 
	CLOSE WINDOW L157 
END FUNCTION 
###########################################################################
# END FUNCTION detl_show(p_cmpy,p_shipdetl,p_shiphead)
###########################################################################