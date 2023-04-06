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
GLOBALS "../eo/EC_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EC1_GLOBALS.4gl" 
###########################################################################
# FUNCTION EC1_main()
#
# Purpose  Allows the user TO view Salesperson Information
###########################################################################
FUNCTION EC1_main() 
	DEFINE l_temp_text char(30) 

	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EC1")  

	CALL salesperson_inquiry() 

END FUNCTION 
###########################################################################
# END FUNCTION EC1_main()
###########################################################################


###########################################################################
# FUNCTION db_salesperson_get_datasource() 
#
#
###########################################################################
FUNCTION db_salesperson_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_sale_code LIKE salesperson.sale_code 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 

	CLEAR FORM 

	IF p_filter THEN	
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			addr1_text, 
			addr2_text, 
			city_text, 
			state_code, 
			post_code, 
			country_code, 
			language_code, 
			terri_code, 
			mgr_code, 
			ware_code, 
			tele_text, 
			mobile_phone,
			fax_text, 	
			email,
			alt_tele_text, 
			comm_per, 
			comm_ind, 
			sale_type_ind, 
			com1_text, 
			com2_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EC1","construct-sale_code-1") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text =  " 1=1 "
		END IF 
	ELSE
		LET l_where_text =  " 1=1 "
	END IF
		
	LET l_query_text = 
		"SELECT sale_code ", 
		"FROM salesperson ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY sale_code" 
	
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson SCROLL cursor FOR s_salesperson 
	
	OPEN c_salesperson 
	FETCH c_salesperson INTO l_rec_sale_code
	 
	IF status = NOTFOUND THEN 
		RETURN FALSE 
	ELSE 
		CALL display_sale(l_rec_sale_code) 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION db_salesperson_get_datasource() 
###########################################################################


###########################################################################
# FUNCTION salesperson_inquiry()  
#
#
###########################################################################
FUNCTION salesperson_inquiry() 
	DEFINE l_rec_sale_code LIKE salesperson.sale_code 
	DEFINE l_datasource_state BOOLEAN
	OPEN WINDOW E182 with FORM "E182" 
	 CALL windecoration_e("E182")
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET l_datasource_state = db_salesperson_get_datasource(FALSE)
			
	MENU "Salesperson" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","EC1","menu-Salesperson-1") -- albo kd-502 
			IF l_datasource_state THEN
 				FETCH FIRST c_salesperson INTO l_rec_sale_code 
				SHOW option "NEXT" 
				SHOW option "PREVIOUS" 
				SHOW option "FIRST" 
				SHOW option "LAST" 
				SHOW option "DETAIL" 
			ELSE 
				MESSAGE kandoomsg2("E",9171,"") 
				HIDE option "NEXT" 
				HIDE option "PREVIOUS" 
				HIDE option "FIRST" 
				HIDE option "LAST" 
				HIDE option "DETAIL" 
			END IF
			
			--HIDE option "NEXT" 
			--HIDE option "PREVIOUS" 
			--HIDE option "FIRST" 
			--HIDE option "LAST" 
			--HIDE option "DETAIL" 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "FILTER" " Enter selection criteria FOR salespersons " 
			IF db_salesperson_get_datasource(TRUE) THEN 
				FETCH FIRST c_salesperson INTO l_rec_sale_code 
				SHOW option "NEXT" 
				SHOW option "PREVIOUS" 
				SHOW option "FIRST" 
				SHOW option "LAST" 
				SHOW option "DETAIL" 
			ELSE 
				MESSAGE kandoomsg2("E",9171,"") 
				HIDE option "NEXT" 
				HIDE option "PREVIOUS" 
				HIDE option "FIRST" 
				HIDE option "LAST" 
				HIDE option "DETAIL" 
			END IF 

		COMMAND KEY ("N",f21) "NEXT" " DISPLAY next selected salesperson" 
			FETCH NEXT c_salesperson INTO l_rec_sale_code 
			IF status <> NOTFOUND THEN 
				CALL display_sale(l_rec_sale_code) 
			ELSE 
				ERROR kandoomsg2("E",9230,"") 		#9071 You have reached the END of the salespersons selected"
			END IF 

		COMMAND KEY ("P",f19) "PREVIOUS" " DISPLAY previous selected salesperson" 
			FETCH previous c_salesperson INTO l_rec_sale_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9229,"") 		#9070 You have reached the start of the salespersons selected"
			ELSE 
				CALL display_sale(l_rec_sale_code) 
			END IF 

		COMMAND KEY ("D",f20) "DETAIL" " View salesperson details" 
			CALL salesperson_inq(glob_rec_kandoouser.cmpy_code,l_rec_sale_code) 

		COMMAND KEY ("F",f18) "FIRST" " DISPLAY first salesperson in the selected list" 
			FETCH FIRST c_salesperson INTO l_rec_sale_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9229,"") 		#9070 You have reached the start of the salespersons selected"
			ELSE 
				CALL display_sale(l_rec_sale_code) 
			END IF 

		COMMAND KEY ("L",f22) "LAST" " DISPLAY last salesperson in the selected list" 
			FETCH LAST c_salesperson INTO l_rec_sale_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9230,"") 		#9071 You have reached the END of the salespersons selected"
			ELSE 
				CALL display_sale(l_rec_sale_code) 
			END IF 

		COMMAND KEY(INTERRUPT,"E") "EXIT" " RETURN TO the menu" 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW E182 
END FUNCTION 
###########################################################################
# END FUNCTION salesperson_inquiry() 
###########################################################################


###########################################################################
# FUNCTION display_sale(l_rec_sale_code) 
#
#
###########################################################################
FUNCTION display_sale(l_rec_sale_code) 
	DEFINE l_rec_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_desc_text array[3] OF char(30) 

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,l_rec_sale_code) RETURNING l_rec_salesperson.*	
	IF l_rec_salesperson.sale_code IS NULL THEN
		ERROR kandoomsg2("E",9231,l_rec_sale_code) 
	END IF 

	IF l_rec_salesperson.terri_code IS NOT NULL THEN 
		SELECT desc_text INTO l_arr_desc_text[1] 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = l_rec_salesperson.terri_code 
		IF status = NOTFOUND THEN 
			LET l_arr_desc_text[1] = "**********" 
		END IF 
	END IF 

	IF l_rec_salesperson.mgr_code IS NOT NULL THEN 
		SELECT name_text INTO l_arr_desc_text[2] 
		FROM salesmgr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND mgr_code = l_rec_salesperson.mgr_code 
		IF status = NOTFOUND THEN 
			LET l_arr_desc_text[2] = "**********" 
		END IF 
	END IF 

	IF l_rec_salesperson.ware_code IS NOT NULL THEN 
		SELECT desc_text INTO l_arr_desc_text[3] 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_rec_salesperson.ware_code 
		IF status = NOTFOUND THEN 
			LET l_arr_desc_text[3] = "**********" 
		END IF 
	END IF 

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
		l_rec_salesperson.tele_text, 
		l_rec_salesperson.mobile_phone,	
		l_rec_salesperson.fax_text, 
		l_rec_salesperson.email, 	
		l_rec_salesperson.alt_tele_text, 
		l_rec_salesperson.comm_per, 
		l_rec_salesperson.comm_ind, 
		l_rec_salesperson.sale_type_ind, 
		l_rec_salesperson.com1_text, 
		l_rec_salesperson.com2_text 

END FUNCTION 
###########################################################################
# END FUNCTION display_sale(l_rec_sale_code) 
###########################################################################