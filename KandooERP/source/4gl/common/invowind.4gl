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
# DISPLAY invoice ext

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION inv_other(p_cmpy_code, p_cust_code, p_inv_num)
#
#
###########################################################################
FUNCTION inv_other(p_cmpy_code,p_cust_code,p_inv_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invheadext RECORD LIKE invheadext.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_s_customer RECORD LIKE customer.* 
	DEFINE l_rec_cartarea RECORD LIKE cartarea.* 
	DEFINE l_rec_transptype RECORD LIKE transptype.* 
	DEFINE l_rec_vehicletype RECORD LIKE vehicletype.* 
	DEFINE l_rec_driver RECORD LIKE driver.* 

	OPEN WINDOW W261 with FORM "W261" 
	CALL windecoration_w("W261") -- albo kd-752 

	SELECT * INTO l_rec_invoicehead.* FROM invoicehead 
	WHERE inv_num = p_inv_num 
	AND cust_code = p_cust_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_invheadext.* FROM invheadext 
	WHERE inv_num = l_rec_invoicehead.inv_num 
	AND cust_code = l_rec_invoicehead.cust_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = l_rec_invoicehead.cust_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_s_customer.* FROM customer 
	WHERE cust_code = l_rec_invheadext.org_cust_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_cartarea.* FROM cartarea 
	WHERE cart_area_code = l_rec_invheadext.cart_area_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_transptype.* FROM transptype 
	WHERE transp_type_code = l_rec_invheadext.transp_type_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_vehicletype.* FROM vehicletype 
	WHERE veh_type_code = l_rec_invheadext.veh_type_code 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_driver.* FROM driver 
	WHERE driver_code = l_rec_invheadext.driver_code 
	AND cmpy_code = p_cmpy_code 

	DISPLAY BY NAME 
		l_rec_invheadext.inv_num, 
		l_rec_invheadext.initials_text, 
		l_rec_invheadext.cust_code, 
		l_rec_invheadext.org_cust_code, 
		l_rec_invoicehead.ord_num, 
		l_rec_invheadext.del_num, 
		l_rec_invheadext.cart_area_code, 
		l_rec_invheadext.transp_type_code, 
		l_rec_invheadext.veh_type_code, 
		l_rec_invheadext.vehicle_code, 
		l_rec_invheadext.driver_code, 
		l_rec_invheadext.km_qty, 
		l_rec_invheadext.map_gps_coordinates 

	DISPLAY l_rec_customer.name_text TO cust_name_text 
	DISPLAY l_rec_s_customer.name_text TO org_cust_name_text 
	DISPLAY l_rec_cartarea.desc_text TO cart_area_text 
	DISPLAY l_rec_transptype.desc_text TO trans_type_text 
	DISPLAY l_rec_vehicletype.desc_text TO vehicle_type_text 
	DISPLAY l_rec_driver.name_text TO driver_text

	CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 

	CLOSE WINDOW W261 

END FUNCTION 
###########################################################################
# END FUNCTION inv_other(p_cmpy_code, p_cust_code, p_inv_num)
###########################################################################