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

	Source code beautified by beautify.pl on 2020-01-02 10:35:20	$Id: $
}



# Order Audit Inquiry

GLOBALS "../common/glob_GLOBALS.4gl" 


DEFINE modu_order_num LIKE orderaudit.order_num, 
modu_rec_pr_orderaudit RECORD LIKE orderaudit.*, 
modu_rec_ps_orderaudit RECORD LIKE orderaudit.*,
modu_rec_pr_ordlineaudit RECORD LIKE ordlineaudit.*, 
modu_rec_ps_ordlineaudit RECORD LIKE ordlineaudit.*, 
modu_rec_pr_ordrateaudit RECORD LIKE ordrateaudit.*, 
modu_rec_ps_ordrateaudit RECORD LIKE ordrateaudit.*, 
modu_hide_flag SMALLINT 

FUNCTION show_aud(p_cmpy,p_order_num,p_hide_flag) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_order_num LIKE orderaudit.order_num 
	DEFINE p_hide_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	LET glob_rec_kandoouser.cmpy_code = p_cmpy 
	LET modu_order_num = p_order_num 
	LET modu_hide_flag = p_hide_flag 

	OPEN WINDOW w253 with FORM "W253" 
	CALL windecoration_w("W253") -- albo kd-767 

	CALL audit_menu() 

	CLOSE WINDOW w253 
END FUNCTION 

FUNCTION audit_query() 
	DEFINE l_msgresp LIKE language.yes_flag
   DEFINE l_audit_type CHAR(800)	
   DEFINE l_query_text CHAR(2200)
   DEFINE l_where_text CHAR(2048)      
	
	LET l_audit_type = NULL 
	DISPLAY l_audit_type TO audit_type  

	IF modu_hide_flag THEN 
		LET l_query_text = "SELECT * FROM orderaudit ", 
		"WHERE order_num = ",modu_order_num," ", 
		"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" ORDER BY order_num,audit_date" 
	ELSE 
		CONSTRUCT BY NAME l_where_text ON order_num, 
		ord_ind, 
		ship_addr1_text, 
		ship_addr2_text, 
		ship_city_text, 
		ship_state_code, 
		ship_post_code, 
		ship_country_code, 
		map_reference, 
		contact_text, 
		tele_text, 
		mobile_phone, 
		ord_text, 
		hold_code, 
		ship_date, 
		total_amt, 
		cart_area_code, 
		mgr_code, 
		territory_code, 
		area_code, 
		sale_code, 
		term_code, 
		tax_code, 
		com1_text, 
		com2_text, 
		super_code, 
		net_area_qty, 
		quote_num, 
		quote_amt, 
		quote_date, 
		print_date, 
		initials_text, 
		user_code, 
		audit_date, 
		audit_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","oraudwin","construct-orderaudit") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 



		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		LET l_query_text = "SELECT * FROM orderaudit ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text CLIPPED, 
		" ORDER BY order_num,audit_date" 
	END IF 

	PREPARE s_audit FROM l_query_text 
	DECLARE c_audit SCROLL CURSOR FOR s_audit 

	OPEN c_audit 
	FETCH FIRST c_audit INTO modu_rec_pr_orderaudit.* 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("W",9024,"") 
		#9024 No Records Found"
		RETURN false 
	END IF 

	CALL disp_record() 
	RETURN true 
END FUNCTION 

FUNCTION disp_record() 
   DEFINE l_audit_type CHAR(800)

	LET modu_rec_ps_orderaudit.* = modu_rec_pr_orderaudit.* 

	CASE 
		WHEN modu_rec_pr_orderaudit.audit_ind = "1" 
			LET l_audit_type = MODE_CLASSIC_INSERT 
		WHEN modu_rec_pr_orderaudit.audit_ind = "2" 
			LET l_audit_type = MODE_CLASSIC_MODIFY 
		WHEN modu_rec_pr_orderaudit.audit_ind = "3" 
			LET l_audit_type = MODE_CLASSIC_DELETE 
	END CASE 
	DISPLAY BY NAME modu_rec_pr_orderaudit.order_num, 
	modu_rec_pr_orderaudit.ord_text, 
	modu_rec_pr_orderaudit.ord_ind, 
	modu_rec_pr_orderaudit.user_code, 
	modu_rec_pr_orderaudit.audit_date, 
	modu_rec_pr_orderaudit.audit_ind, 
	modu_rec_pr_orderaudit.initials_text, 
	modu_rec_pr_orderaudit.term_code, 
	modu_rec_pr_orderaudit.sale_code, 
	modu_rec_pr_orderaudit.tax_code, 
	modu_rec_pr_orderaudit.hold_code, 
	modu_rec_pr_orderaudit.total_amt, 
	modu_rec_pr_orderaudit.area_code, 
	modu_rec_pr_orderaudit.com1_text, 
	modu_rec_pr_orderaudit.com2_text, 
	modu_rec_pr_orderaudit.contact_text, 
	modu_rec_pr_orderaudit.tele_text, 
	modu_rec_pr_orderaudit.mobile_phone, 
	modu_rec_pr_orderaudit.ship_addr1_text, 
	modu_rec_pr_orderaudit.ship_addr2_text, 
	modu_rec_pr_orderaudit.ship_city_text, 
	modu_rec_pr_orderaudit.ship_state_code, 
	modu_rec_pr_orderaudit.ship_post_code, 
	modu_rec_pr_orderaudit.ship_country_code, 
	modu_rec_pr_orderaudit.map_reference, 
	modu_rec_pr_orderaudit.cart_area_code, 
	modu_rec_pr_orderaudit.ship_date, 
	modu_rec_pr_orderaudit.print_date, 
	modu_rec_pr_orderaudit.territory_code, 
	modu_rec_pr_orderaudit.mgr_code, 
	modu_rec_pr_orderaudit.quote_num, 
	modu_rec_pr_orderaudit.quote_date, 
	modu_rec_pr_orderaudit.quote_amt, 
	modu_rec_pr_orderaudit.super_code, 
	modu_rec_pr_orderaudit.net_area_qty 
	DISPLAY l_audit_type TO audit_type

END FUNCTION 

FUNCTION disp_ordlineaudit_detail() 
	DEFINE l_msgresp LIKE language.yes_flag

	LET modu_rec_ps_ordlineaudit.* = modu_rec_pr_ordlineaudit.* 

	DISPLAY BY NAME modu_rec_pr_ordlineaudit.cust_code, 
	modu_rec_pr_ordlineaudit.order_num, 
	modu_rec_pr_ordlineaudit.line_num, 
	modu_rec_pr_ordlineaudit.part_code, 
	modu_rec_pr_ordlineaudit.ware_code, 
	modu_rec_pr_ordlineaudit.order_qty, 
	modu_rec_pr_ordlineaudit.desc_text, 
	modu_rec_pr_ordlineaudit.uom_code, 
	modu_rec_pr_ordlineaudit.unit_price_amt, 
	modu_rec_pr_ordlineaudit.unit_tax_amt, 
	modu_rec_pr_ordlineaudit.disc_per, 
	modu_rec_pr_ordlineaudit.level_ind, 
	modu_rec_pr_ordlineaudit.offer_code, 
	modu_rec_pr_ordlineaudit.prodgrp_code, 
	modu_rec_pr_ordlineaudit.maingrp_code, 
	modu_rec_pr_ordlineaudit.price_uom_code, 
	modu_rec_pr_ordlineaudit.km_qty, 
	modu_rec_pr_ordlineaudit.auth_code, 
	modu_rec_pr_ordlineaudit.user_code, 
	modu_rec_pr_ordlineaudit.audit_date, 
	modu_rec_pr_ordlineaudit.audit_ind, 
	modu_rec_pr_ordlineaudit.print_date 

END FUNCTION 

FUNCTION disp_rates() 

	LET modu_rec_ps_ordrateaudit.* = modu_rec_pr_ordrateaudit.* 
	DISPLAY BY NAME modu_rec_pr_ordrateaudit.order_num, 
	modu_rec_pr_ordrateaudit.line_num, 
	modu_rec_pr_ordrateaudit.order_rate_type, 
	modu_rec_pr_ordrateaudit.unit_price_amt, 
	modu_rec_pr_ordrateaudit.unit_tax_amt, 
	modu_rec_pr_ordrateaudit.user_code, 
	modu_rec_pr_ordrateaudit.audit_date, 
	modu_rec_pr_ordrateaudit.audit_ind, 
	modu_rec_pr_ordrateaudit.print_date 

END FUNCTION 

FUNCTION audit_menu() 
	DEFINE l_resp SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag	

	IF modu_hide_flag THEN 
		LET l_resp = audit_query() 
	END IF 

	MENU " Order Audit" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","oraudwin","menu-Order_Audit-1") -- albo 
			IF modu_hide_flag THEN 
				HIDE option "Query" 
			ELSE 
				SHOW option "Query" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
				HIDE option "Next" 
				HIDE option "Previous" 
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" " Enter Selection Criteria" 
			LET l_msgresp = kandoomsg ("W",1001,"") 
			#1001 Enter Selection Criteria - ESC Continue
			WHENEVER ERROR CONTINUE 
			CLOSE c_audit 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 
			HIDE option "Next" 
			HIDE option "Previous" 
			IF audit_query() THEN 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				SHOW option "Next" 
				SHOW option "Previous" 
			END IF 
		COMMAND KEY ("N",f21) "Next" " View Next Record" 
			WHILE true 
				FETCH NEXT c_audit INTO modu_rec_pr_orderaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9182,"") 
					#9182 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF audit_mods(modu_rec_ps_orderaudit.*,modu_rec_pr_orderaudit.*) THEN 
						CALL disp_record() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("P",f19) "Previous" " View Previous Record" 
			WHILE true 
				FETCH previous c_audit INTO modu_rec_pr_orderaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9183,"") 
					#9183 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF audit_mods(modu_rec_ps_orderaudit.*,modu_rec_pr_orderaudit.*) THEN 
						CALL disp_record() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("D",f20) "Detail" " View Order Detail Records" 
			CALL detail_menu() 
		COMMAND KEY ("F",f18) "First" " View First Record" 
			FETCH FIRST c_audit INTO modu_rec_pr_orderaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_record() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("L",f22) "Last" " View Last Record" 
			FETCH LAST c_audit INTO modu_rec_pr_orderaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_record() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY(interrupt,"E")"Exit" " Exit FROM Order Audit Inquiry" 
			EXIT MENU 

	END MENU 
END FUNCTION 

FUNCTION audit_mods(p_rec_ps_orderaudit,p_rec_pr_orderaudit) 
	DEFINE p_rec_ps_orderaudit RECORD LIKE orderaudit.* 
	DEFINE p_rec_pr_orderaudit RECORD LIKE orderaudit.* 

	IF p_rec_pr_orderaudit.audit_ind = 1 THEN 
		RETURN true 
	END IF 

	IF (p_rec_ps_orderaudit.ord_text IS NULL AND 
	p_rec_pr_orderaudit.ord_text IS NOT null) 
	OR (p_rec_pr_orderaudit.ord_text IS NULL AND 
	p_rec_ps_orderaudit.ord_text IS NOT null) 
	OR (p_rec_ps_orderaudit.ord_text != p_rec_pr_orderaudit.ord_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.sale_code IS NULL AND 
	p_rec_pr_orderaudit.sale_code IS NOT null) 
	OR (p_rec_pr_orderaudit.sale_code IS NULL AND 
	p_rec_ps_orderaudit.sale_code IS NOT null) 
	OR (p_rec_ps_orderaudit.sale_code != p_rec_pr_orderaudit.sale_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.term_code IS NULL AND 
	p_rec_pr_orderaudit.term_code IS NOT null) 
	OR (p_rec_pr_orderaudit.term_code IS NULL AND 
	p_rec_ps_orderaudit.term_code IS NOT null) 
	OR (p_rec_ps_orderaudit.term_code != p_rec_pr_orderaudit.term_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.tax_code IS NULL AND 
	p_rec_pr_orderaudit.tax_code IS NOT null) 
	OR (p_rec_pr_orderaudit.tax_code IS NULL AND 
	p_rec_ps_orderaudit.tax_code IS NOT null) 
	OR (p_rec_ps_orderaudit.tax_code != p_rec_pr_orderaudit.tax_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.total_amt IS NULL AND 
	p_rec_pr_orderaudit.total_amt IS NOT null) 
	OR (p_rec_pr_orderaudit.total_amt IS NULL AND 
	p_rec_ps_orderaudit.total_amt IS NOT null) 
	OR (p_rec_ps_orderaudit.total_amt != p_rec_pr_orderaudit.total_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.com1_text IS NULL AND 
	p_rec_pr_orderaudit.com1_text IS NOT null) 
	OR (p_rec_pr_orderaudit.com1_text IS NULL AND 
	p_rec_ps_orderaudit.com1_text IS NOT null) 
	OR (p_rec_ps_orderaudit.com1_text != p_rec_pr_orderaudit.com1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.com2_text IS NULL AND 
	p_rec_pr_orderaudit.com2_text IS NOT null) 
	OR (p_rec_pr_orderaudit.com2_text IS NULL AND 
	p_rec_ps_orderaudit.com2_text IS NOT null) 
	OR (p_rec_ps_orderaudit.com2_text != p_rec_pr_orderaudit.com2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.contact_text IS NULL AND 
	p_rec_pr_orderaudit.contact_text IS NOT null) 
	OR (p_rec_pr_orderaudit.contact_text IS NULL AND 
	p_rec_ps_orderaudit.contact_text IS NOT null) 
	OR (p_rec_ps_orderaudit.contact_text != p_rec_pr_orderaudit.contact_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.tele_text IS NULL AND 
	p_rec_pr_orderaudit.tele_text IS NOT null) 
	OR (p_rec_pr_orderaudit.tele_text IS NULL AND 
	p_rec_ps_orderaudit.tele_text IS NOT null) 
	OR (p_rec_ps_orderaudit.tele_text != p_rec_pr_orderaudit.tele_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_addr1_text IS NULL AND 
	p_rec_pr_orderaudit.ship_addr1_text IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_addr1_text IS NULL AND 
	p_rec_ps_orderaudit.ship_addr1_text IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_addr1_text != p_rec_pr_orderaudit.ship_addr1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_addr2_text IS NULL AND 
	p_rec_pr_orderaudit.ship_addr2_text IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_addr2_text IS NULL AND 
	p_rec_ps_orderaudit.ship_addr2_text IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_addr2_text != p_rec_pr_orderaudit.ship_addr2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_city_text IS NULL AND 
	p_rec_pr_orderaudit.ship_city_text IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_city_text IS NULL AND 
	p_rec_ps_orderaudit.ship_city_text IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_city_text != p_rec_pr_orderaudit.ship_city_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_state_code IS NULL AND 
	p_rec_pr_orderaudit.ship_state_code IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_state_code IS NULL AND 
	p_rec_ps_orderaudit.ship_state_code IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_state_code != p_rec_pr_orderaudit.ship_state_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_post_code IS NULL AND 
	p_rec_pr_orderaudit.ship_post_code IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_post_code IS NULL AND 
	p_rec_ps_orderaudit.ship_post_code IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_post_code != p_rec_pr_orderaudit.ship_post_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_country_code IS NULL AND 
	p_rec_pr_orderaudit.ship_country_code IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_country_code IS NULL AND 
	p_rec_ps_orderaudit.ship_country_code IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_country_code != p_rec_pr_orderaudit.ship_country_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.ship_date IS NULL AND 
	p_rec_pr_orderaudit.ship_date IS NOT null) 
	OR (p_rec_pr_orderaudit.ship_date IS NULL AND 
	p_rec_ps_orderaudit.ship_date IS NOT null) 
	OR (p_rec_ps_orderaudit.ship_date != p_rec_pr_orderaudit.ship_date) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.hold_code IS NULL AND 
	p_rec_pr_orderaudit.hold_code IS NOT null) 
	OR (p_rec_pr_orderaudit.hold_code IS NULL AND 
	p_rec_ps_orderaudit.hold_code IS NOT null) 
	OR (p_rec_ps_orderaudit.hold_code != p_rec_pr_orderaudit.hold_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.territory_code IS NULL AND 
	p_rec_pr_orderaudit.territory_code IS NOT null) 
	OR (p_rec_pr_orderaudit.territory_code IS NULL AND 
	p_rec_ps_orderaudit.territory_code IS NOT null) 
	OR (p_rec_ps_orderaudit.territory_code != p_rec_pr_orderaudit.territory_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.mgr_code IS NULL AND 
	p_rec_pr_orderaudit.mgr_code IS NOT null) 
	OR (p_rec_pr_orderaudit.mgr_code IS NULL AND 
	p_rec_ps_orderaudit.mgr_code IS NOT null) 
	OR (p_rec_ps_orderaudit.mgr_code != p_rec_pr_orderaudit.mgr_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.area_code IS NULL AND 
	p_rec_pr_orderaudit.area_code IS NOT null) 
	OR (p_rec_pr_orderaudit.area_code IS NULL AND 
	p_rec_ps_orderaudit.area_code IS NOT null) 
	OR (p_rec_ps_orderaudit.area_code != p_rec_pr_orderaudit.area_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.mobile_phone IS NULL AND 
	p_rec_pr_orderaudit.mobile_phone IS NOT null) 
	OR (p_rec_pr_orderaudit.mobile_phone IS NULL AND 
	p_rec_ps_orderaudit.mobile_phone IS NOT null) 
	OR (p_rec_ps_orderaudit.mobile_phone != p_rec_pr_orderaudit.mobile_phone) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.initials_text IS NULL AND 
	p_rec_pr_orderaudit.initials_text IS NOT null) 
	OR (p_rec_pr_orderaudit.initials_text IS NULL AND 
	p_rec_ps_orderaudit.initials_text IS NOT null) 
	OR (p_rec_ps_orderaudit.initials_text != p_rec_pr_orderaudit.initials_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.map_reference IS NULL AND 
	p_rec_pr_orderaudit.map_reference IS NOT null) 
	OR (p_rec_pr_orderaudit.map_reference IS NULL AND 
	p_rec_ps_orderaudit.map_reference IS NOT null) 
	OR (p_rec_ps_orderaudit.map_reference != p_rec_pr_orderaudit.map_reference) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.cart_area_code IS NULL AND 
	p_rec_pr_orderaudit.cart_area_code IS NOT null) 
	OR (p_rec_pr_orderaudit.cart_area_code IS NULL AND 
	p_rec_ps_orderaudit.cart_area_code IS NOT null) 
	OR (p_rec_ps_orderaudit.cart_area_code != p_rec_pr_orderaudit.cart_area_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.quote_num IS NULL AND 
	p_rec_pr_orderaudit.quote_num IS NOT null) 
	OR (p_rec_pr_orderaudit.quote_num IS NULL AND 
	p_rec_ps_orderaudit.quote_num IS NOT null) 
	OR (p_rec_ps_orderaudit.quote_num != p_rec_pr_orderaudit.quote_num ) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.quote_date IS NULL AND 
	p_rec_pr_orderaudit.quote_date IS NOT null) 
	OR (p_rec_pr_orderaudit.quote_date IS NULL AND 
	p_rec_ps_orderaudit.quote_date IS NOT null) 
	OR (p_rec_ps_orderaudit.quote_date != p_rec_pr_orderaudit.quote_date ) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.quote_amt IS NULL AND 
	p_rec_pr_orderaudit.quote_amt IS NOT null) 
	OR (p_rec_pr_orderaudit.quote_amt IS NULL AND 
	p_rec_ps_orderaudit.quote_amt IS NOT null) 
	OR (p_rec_ps_orderaudit.quote_amt != p_rec_pr_orderaudit.quote_amt ) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.super_code IS NULL AND 
	p_rec_pr_orderaudit.super_code IS NOT null) 
	OR (p_rec_pr_orderaudit.super_code IS NULL AND 
	p_rec_ps_orderaudit.super_code IS NOT null) 
	OR (p_rec_ps_orderaudit.super_code != p_rec_pr_orderaudit.super_code ) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_orderaudit.net_area_qty IS NULL AND 
	p_rec_pr_orderaudit.net_area_qty IS NOT null) 
	OR (p_rec_pr_orderaudit.net_area_qty IS NULL AND 
	p_rec_ps_orderaudit.net_area_qty IS NOT null) 
	OR (p_rec_ps_orderaudit.net_area_qty != p_rec_pr_orderaudit.net_area_qty ) THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 


FUNCTION detail_menu() 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW w255 with FORM "W255" 
	CALL windecoration_w("W255") -- albo kd-767 

	DECLARE c_lineaudit SCROLL CURSOR FOR 
	SELECT * 
	FROM ordlineaudit 
	WHERE order_num = modu_rec_pr_orderaudit.order_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY line_num,audit_date 

	WHENEVER ERROR CONTINUE 
	CLOSE c_lineaudit 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPEN c_lineaudit 
	FETCH FIRST c_lineaudit INTO modu_rec_pr_ordlineaudit.* 
	CALL disp_ordlineaudit_detail() 

	MENU " Order Detail Audit" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","oraudwin","menu-Order_Detail_Audit-1") -- albo 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY ("N",f21) "Next" " View Next Record" 
			WHILE true 
				FETCH NEXT c_lineaudit INTO modu_rec_pr_ordlineaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9182,"") 
					#9182 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF ordetl_mods(modu_rec_ps_ordlineaudit.*,modu_rec_pr_ordlineaudit.*) THEN 
						CALL disp_ordlineaudit_detail() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("P",f19) "Previous" " View Previous Record" 
			WHILE true 
				FETCH previous c_lineaudit INTO modu_rec_pr_ordlineaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9183,"") 
					#9183 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF ordetl_mods(modu_rec_ps_ordlineaudit.*,modu_rec_pr_ordlineaudit.*) THEN 
						CALL disp_ordlineaudit_detail() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("D",f20) "Detail" " View Order Line Rate Audits" 
			CALL rates_menu() 
		COMMAND KEY ("F",f18) "First" " View First Record" 
			FETCH FIRST c_lineaudit INTO modu_rec_pr_ordlineaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_ordlineaudit_detail() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("L",f22) "Last" " View Last Record" 
			FETCH LAST c_lineaudit INTO modu_rec_pr_ordlineaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_ordlineaudit_detail() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY(interrupt,"E")"Exit" " Exit Order Detail Audit" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW w255 
END FUNCTION 


FUNCTION rates_menu() 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW w256 with FORM "W256" 
	CALL windecoration_w("W256") -- albo kd-767 

	DECLARE c_rateaudit SCROLL CURSOR FOR 
	SELECT * 
	FROM ordrateaudit 
	WHERE order_num = modu_rec_pr_orderaudit.order_num 
	AND line_num = modu_rec_pr_ordlineaudit.line_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY order_rate_type,audit_date 

	WHENEVER ERROR CONTINUE 
	CLOSE c_rateaudit 
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	OPEN c_rateaudit 
	FETCH FIRST c_rateaudit INTO modu_rec_pr_ordrateaudit.* 
	CALL disp_rates() 

	MENU " Order Rate Audit" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","oraudwin","menu-Order_Rate_Audit-1") -- albo 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY ("N",f21) "Next" " View Next Record" 
			WHILE true 
				FETCH NEXT c_rateaudit INTO modu_rec_pr_ordrateaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9182,"") 
					#9182 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF rate_mods(modu_rec_ps_ordrateaudit.*,modu_rec_pr_ordrateaudit.*) THEN 
						CALL disp_rates() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("P",f19) "Previous" " View Previous Record" 
			WHILE true 
				FETCH previous c_rateaudit INTO modu_rec_pr_ordrateaudit.* 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9183,"") 
					#9183 No Records in this direction
					EXIT WHILE 
				ELSE 
					IF rate_mods(modu_rec_ps_ordrateaudit.*,modu_rec_pr_ordrateaudit.*) THEN 
						CALL disp_rates() 
						EXIT WHILE 
					END IF 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("F",f18) "First" " View First Record" 
			FETCH FIRST c_rateaudit INTO modu_rec_pr_ordrateaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_rates() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY ("L",f22) "Last" " View Last Record" 
			FETCH LAST c_rateaudit INTO modu_rec_pr_ordrateaudit.* 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("W",9024,"") 
				#9024 No Records in this direction
			ELSE 
				CALL disp_rates() 
			END IF 
			LET quit_flag = false 
			LET int_flag = false 
		COMMAND KEY(interrupt,"E")"Exit" " Exit Order Rate Audit" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW w256 
END FUNCTION 

FUNCTION ordetl_mods(p_rec_ps_ordlineaudit,p_rec_pr_ordlineaudit) 
	DEFINE p_rec_ps_ordlineaudit RECORD LIKE ordlineaudit.* 
	DEFINE p_rec_pr_ordlineaudit RECORD LIKE ordlineaudit.* 

	IF p_rec_pr_ordlineaudit.audit_ind = 1 THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.part_code IS NULL AND 
	p_rec_pr_ordlineaudit.part_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.part_code IS NULL AND 
	p_rec_ps_ordlineaudit.part_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.part_code != p_rec_pr_ordlineaudit.part_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.ware_code IS NULL AND 
	p_rec_pr_ordlineaudit.ware_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.ware_code IS NULL AND 
	p_rec_ps_ordlineaudit.ware_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.ware_code != p_rec_pr_ordlineaudit.ware_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.order_qty IS NULL AND 
	p_rec_pr_ordlineaudit.order_qty IS NOT null) 
	OR (p_rec_pr_ordlineaudit.order_qty IS NULL AND 
	p_rec_ps_ordlineaudit.order_qty IS NOT null) 
	OR (p_rec_ps_ordlineaudit.order_qty != p_rec_pr_ordlineaudit.order_qty) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.desc_text IS NULL AND 
	p_rec_pr_ordlineaudit.desc_text IS NOT null) 
	OR (p_rec_pr_ordlineaudit.desc_text IS NULL AND 
	p_rec_ps_ordlineaudit.desc_text IS NOT null) 
	OR (p_rec_ps_ordlineaudit.desc_text != p_rec_pr_ordlineaudit.desc_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.unit_price_amt IS NULL AND 
	p_rec_pr_ordlineaudit.unit_price_amt IS NOT null) 
	OR (p_rec_pr_ordlineaudit.unit_price_amt IS NULL AND 
	p_rec_ps_ordlineaudit.unit_price_amt IS NOT null) 
	OR (p_rec_ps_ordlineaudit.unit_price_amt != p_rec_pr_ordlineaudit.unit_price_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.unit_tax_amt IS NULL AND 
	p_rec_pr_ordlineaudit.unit_tax_amt IS NOT null) 
	OR (p_rec_pr_ordlineaudit.unit_tax_amt IS NULL AND 
	p_rec_ps_ordlineaudit.unit_tax_amt IS NOT null) 
	OR (p_rec_ps_ordlineaudit.unit_tax_amt != p_rec_pr_ordlineaudit.unit_tax_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.uom_code IS NULL AND 
	p_rec_pr_ordlineaudit.uom_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.uom_code IS NULL AND 
	p_rec_ps_ordlineaudit.uom_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.uom_code != p_rec_pr_ordlineaudit.uom_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.disc_per IS NULL AND 
	p_rec_pr_ordlineaudit.disc_per IS NOT null) 
	OR (p_rec_pr_ordlineaudit.disc_per IS NULL AND 
	p_rec_ps_ordlineaudit.disc_per IS NOT null) 
	OR (p_rec_ps_ordlineaudit.disc_per != p_rec_pr_ordlineaudit.disc_per) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.level_ind IS NULL AND 
	p_rec_pr_ordlineaudit.level_ind IS NOT null) 
	OR (p_rec_pr_ordlineaudit.level_ind IS NULL AND 
	p_rec_ps_ordlineaudit.level_ind IS NOT null) 
	OR (p_rec_ps_ordlineaudit.level_ind != p_rec_pr_ordlineaudit.level_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.offer_code IS NULL AND 
	p_rec_pr_ordlineaudit.offer_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.offer_code IS NULL AND 
	p_rec_ps_ordlineaudit.offer_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.offer_code != p_rec_pr_ordlineaudit.offer_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.prodgrp_code IS NULL AND 
	p_rec_pr_ordlineaudit.prodgrp_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.prodgrp_code IS NULL AND 
	p_rec_ps_ordlineaudit.prodgrp_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.prodgrp_code != p_rec_pr_ordlineaudit.prodgrp_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.maingrp_code IS NULL AND 
	p_rec_pr_ordlineaudit.maingrp_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.maingrp_code IS NULL AND 
	p_rec_ps_ordlineaudit.maingrp_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.maingrp_code != p_rec_pr_ordlineaudit.maingrp_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.price_uom_code IS NULL AND 
	p_rec_pr_ordlineaudit.price_uom_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.price_uom_code IS NULL AND 
	p_rec_ps_ordlineaudit.price_uom_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.price_uom_code != p_rec_pr_ordlineaudit.price_uom_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.km_qty IS NULL AND 
	p_rec_pr_ordlineaudit.km_qty IS NOT null) 
	OR (p_rec_pr_ordlineaudit.km_qty IS NULL AND 
	p_rec_ps_ordlineaudit.km_qty IS NOT null) 
	OR (p_rec_ps_ordlineaudit.km_qty != p_rec_pr_ordlineaudit.km_qty) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordlineaudit.auth_code IS NULL AND 
	p_rec_pr_ordlineaudit.auth_code IS NOT null) 
	OR (p_rec_pr_ordlineaudit.auth_code IS NULL AND 
	p_rec_ps_ordlineaudit.auth_code IS NOT null) 
	OR (p_rec_ps_ordlineaudit.auth_code != p_rec_pr_ordlineaudit.auth_code) THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 

FUNCTION rate_mods(p_rec_ps_ordrateaudit,p_rec_pr_ordrateaudit) 
	DEFINE p_rec_ps_ordrateaudit RECORD LIKE ordrateaudit.* 
	DEFINE p_rec_pr_ordrateaudit RECORD LIKE ordrateaudit.* 

	IF p_rec_pr_ordrateaudit.audit_ind = 1 THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordrateaudit.unit_price_amt IS NULL AND 
	p_rec_pr_ordrateaudit.unit_price_amt IS NOT null) 
	OR (p_rec_pr_ordrateaudit.unit_price_amt IS NULL AND 
	p_rec_ps_ordrateaudit.unit_price_amt IS NOT null) 
	OR (p_rec_ps_ordrateaudit.unit_price_amt != p_rec_pr_ordrateaudit.unit_price_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_ps_ordrateaudit.unit_tax_amt IS NULL AND 
	p_rec_pr_ordrateaudit.unit_tax_amt IS NOT null) 
	OR (p_rec_pr_ordrateaudit.unit_tax_amt IS NULL AND 
	p_rec_ps_ordrateaudit.unit_tax_amt IS NOT null) 
	OR (p_rec_ps_ordrateaudit.unit_tax_amt != p_rec_pr_ordrateaudit.unit_tax_amt) THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 


