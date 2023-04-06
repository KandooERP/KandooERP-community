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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E62_GLOBALS.4gl"
###########################################################################
# FUNCTION scan_prods(p_cmpy,p_offer_code)
#
# E62a - Automated Product Insertion Scan
###########################################################################
FUNCTION scan_prods(p_cmpy,p_offer_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_offer_code LIKE offersale.offer_code 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.*
	DEFINE l_arr_rec_offerauto DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE offerauto.part_code, 
		desc_text LIKE product.desc_text, 
		sold_qty LIKE offerauto.sold_qty, 
		bonus_qty LIKE offerauto.bonus_qty 
	END RECORD 
	DEFINE l_idx SMALLINT 
 
	LET l_idx = 0 

	DECLARE c_offerauto cursor FOR 
	SELECT * FROM offerauto 
	WHERE cmpy_code = p_cmpy 
	AND offer_code = p_offer_code 
	ORDER BY part_code 

	FOREACH c_offerauto INTO l_rec_offerauto.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_offerauto[l_idx].scroll_flag = NULL 
		LET l_arr_rec_offerauto[l_idx].part_code = l_rec_offerauto.part_code 
		LET l_arr_rec_offerauto[l_idx].sold_qty = l_rec_offerauto.sold_qty 
		LET l_arr_rec_offerauto[l_idx].bonus_qty = l_rec_offerauto.bonus_qty 
		SELECT desc_text INTO l_arr_rec_offerauto[l_idx].desc_text 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = l_arr_rec_offerauto[l_idx].part_code 
	END FOREACH 

	MESSAGE kandoomsg2("E",1007,"") #1007 F3/F4 Page Fwd/Bwd .. RETURN TO View
	DISPLAY ARRAY l_arr_rec_offerauto TO sr_offerauto.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E62a","display-arr-offerauto") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (tab) 
			LET l_idx = arr_curr() 
			CALL autoline(p_offer_code,l_arr_rec_offerauto[l_idx].part_code) 

		ON KEY (return) 
			LET l_idx = arr_curr() 
			CALL autoline(p_offer_code,l_arr_rec_offerauto[l_idx].part_code) 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 


###########################################################################
# FUNCTION autoline(p_offer_code,p_part_code)
#
# 
###########################################################################
FUNCTION autoline(p_offer_code,p_part_code) 
	DEFINE p_offer_code LIKE offersale.offer_code 
	DEFINE p_part_code LIKE offerauto.part_code 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_list_amt LIKE prodstatus.list_amt 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_offerauto.* 
	FROM offerauto 
	WHERE cmpy_code = p_cmpy 
	AND offer_code = p_offer_code 
	AND part_code = p_part_code 

	SELECT desc_text INTO l_desc_text 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_offerauto.part_code
	 
	SELECT list_amt INTO l_list_amt 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_offerauto.part_code 
	AND ware_code = (select mast_ware_code FROM inparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1") 
	
	IF status = NOTFOUND THEN 
		LET l_list_amt = 0 
	END IF 
	
	OPEN WINDOW E127 with FORM "E127" 
	 CALL windecoration_e("E127") -- albo kd-755
 
	DISPLAY BY NAME l_rec_offerauto.part_code, 
	l_rec_offerauto.sold_qty, 
	l_rec_offerauto.bonus_qty, 
	l_rec_offerauto.disc_allow_flag, 
	l_rec_offerauto.price_amt, 
	l_rec_offerauto.disc_per, 
	l_rec_offerauto.status_ind 

	DISPLAY l_desc_text TO product.desc_text 
	DISPLAY l_list_amt TO prodstatus.list_amt 

	CALL eventsuspend()#ERROR kandoomsg2("U",1,"") 

	#U1 Any Key TO Continue
	CLOSE WINDOW E127
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION