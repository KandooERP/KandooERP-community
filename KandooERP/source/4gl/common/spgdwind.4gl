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

###########################################################################
# FUNCTION sper_detls(p_cmpy_code,p_sale_code)
#
# \brief module spgdwind.4gl
# Purpose  Salesperson general details

###########################################################################
FUNCTION sper_detls(p_cmpy_code,p_sale_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_desc_text ARRAY[3] OF CHAR(30) 
	DEFINE l_pr_temp_text CHAR(30)
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW E182 with FORM "E182" 
	CALL windecoration_e("E182") -- albo kd-755 

	SELECT * INTO l_rec_salesperson.* 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy_code 
	AND sale_code = p_sale_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("E",9231,p_sale_code) 
	END IF 

	IF l_rec_salesperson.terri_code IS NOT NULL THEN 
		SELECT desc_text INTO l_arr_desc_text[1] 
		FROM territory 
		WHERE cmpy_code = p_cmpy_code 
		AND terr_code = l_rec_salesperson.terri_code 
		IF status = notfound THEN 
			LET l_arr_desc_text[1] = "**********" 
		END IF 
	END IF 

	IF l_rec_salesperson.mgr_code IS NOT NULL THEN 
		SELECT name_text INTO l_arr_desc_text[2] 
		FROM salesmgr 
		WHERE cmpy_code = p_cmpy_code 
		AND mgr_code = l_rec_salesperson.mgr_code 
		IF status = notfound THEN 
			LET l_arr_desc_text[2] = "**********" 
		END IF 
	END IF 

	IF l_rec_salesperson.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO l_arr_desc_text[3] 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy_code 
		AND ware_code = l_rec_salesperson.ware_code 
		IF status = notfound THEN 
			LET l_arr_desc_text[3] = "**********" 
		END IF 
	END IF 

	CALL db_country_localize(l_rec_salesperson.country_code) #Localize 

	DISPLAY l_arr_desc_text[1] TO territory.desc_text 
	DISPLAY l_arr_desc_text[2] TO salesmgr.name_text 
	DISPLAY l_arr_desc_text[3] TO warehouse.desc_text 

	DISPLAY BY NAME 
		l_rec_salesperson.sale_code, 
		l_rec_salesperson.name_text, 
		l_rec_salesperson.addr1_text, 
		l_rec_salesperson.addr2_text, 
		l_rec_salesperson.city_text, 
		l_rec_salesperson.state_code, 
		l_rec_salesperson.post_code, 
		l_rec_salesperson.country_code, 
		l_rec_salesperson.language_code, 
		l_rec_salesperson.terri_code, 
		l_rec_salesperson.mgr_code, 
		l_rec_salesperson.ware_code, 
		l_rec_salesperson.fax_text, 
		l_rec_salesperson.tele_text, 
		l_rec_salesperson.alt_tele_text, 
		l_rec_salesperson.comm_per, 
		l_rec_salesperson.comm_ind, 
		l_rec_salesperson.sale_type_ind, 
		l_rec_salesperson.com1_text, 
		l_rec_salesperson.com2_text 

	CALL eventsuspend() 
	--MESSAGE kandoomsg2("U",1,"")

	CLOSE WINDOW E182 
END FUNCTION 
###########################################################################
# END FUNCTION sper_detls(p_cmpy_code,p_sale_code)
###########################################################################