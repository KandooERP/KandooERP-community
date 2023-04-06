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
# ishpwind.4gl - FUNCTION show_inv_ship
#                Invoice Shipment details Display
#
GLOBALS "../common/glob_GLOBALS.4gl" 
###################################################################
# FUNCTION show_inv_ship(p_cmpy, p_inv_num)
###################################################################
FUNCTION show_inv_ship(p_cmpy,p_inv_num) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",7048,p_inv_num) 
		#7048 Logic Error: Invoice does NOT exist
		RETURN 
	END IF 

	SELECT * INTO l_rec_carrier.* FROM carrier 
	WHERE cmpy_code = p_cmpy 
	AND carrier_code = l_rec_invoicehead.carrier_code 

	SELECT * INTO l_rec_despatchhead.* FROM despatchhead 
	WHERE cmpy_code = p_cmpy 
	AND manifest_num = l_rec_invoicehead.manifest_num 
	AND carrier_code = l_rec_invoicehead.carrier_code 

	IF sqlca.sqlcode = notfound THEN 
		LET l_rec_despatchhead.despatch_date = NULL 
	END IF 

	SELECT * INTO l_rec_despatchdetl.* FROM despatchdetl 
	WHERE cmpy_code = p_cmpy 
	AND invoice_num = l_rec_invoicehead.inv_num 
	AND manifest_num = l_rec_invoicehead.manifest_num 
	AND carrier_code = l_rec_invoicehead.carrier_code 

	OPEN WINDOW A212 with FORM "A212" --attribute(border,white) 
	CALL windecoration_a("A212") 
	CALL comboList_customership_DOUBLE("ship_code",l_rec_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
	DISPLAY BY NAME l_rec_invoicehead.carrier_code, 
	l_rec_despatchhead.despatch_date, 
	l_rec_despatchhead.despatch_time, 
	l_rec_invoicehead.ship_code, 
	l_rec_invoicehead.addr1_text, 
	l_rec_invoicehead.addr2_text, 
	l_rec_invoicehead.city_text, 
	l_rec_invoicehead.state_code, 
	l_rec_invoicehead.post_code, 
	l_rec_invoicehead.country_code, --@db-patch_2020_10_04-- 
	l_rec_invoicehead.contact_text, 
	l_rec_invoicehead.tele_text, 
	l_rec_invoicehead.ship1_text, 
	l_rec_invoicehead.ship2_text, 
	l_rec_invoicehead.manifest_num, 
	l_rec_despatchdetl.despatch_code, 
	l_rec_invoicehead.prepaid_flag, 
	l_rec_invoicehead.fob_text 

	DISPLAY l_rec_carrier.name_text, 
	l_rec_invoicehead.name_text 
	TO carrier.name_text, 
	invoicehead.name_text 

	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 
	#1 Press Any Key TO Continue

	CLOSE WINDOW A212 

END FUNCTION 
