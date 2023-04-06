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
GLOBALS "../eo/EF_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EF1_GLOBALS.4gl"
###########################################################################
# FUNCTION EF1_main()
#
# Allows the user TO scan Sales Area Information
# This is just a menu with run statements
###########################################################################
FUNCTION EF1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EF1")  
	 
	OPEN WINDOW E240 with FORM "E240" 
	 CALL windecoration_e("E240") -- albo kd-755
 
	CALL scan_area() 
	
	CLOSE WINDOW E240 
END FUNCTION 
###########################################################################
# END FUNCTION EF1_main()
###########################################################################


###########################################################################
# FUNCTION salearea_get_datasource()
#
#
###########################################################################
FUNCTION salearea_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN
		ERROR kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON area_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EF1","construct-area_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	 
	LET l_query_text = 
		"SELECT * FROM salearea ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"area_code" 
	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea cursor FOR s_salearea 

 	LET l_idx = 0 
	FOREACH c_salearea INTO l_rec_salearea.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salearea[l_idx].scroll_flag = NULL 
		LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code 
		LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
		 
		SELECT unique 1 FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_rec_salearea.area_code 
		IF status = 0 THEN 
			LET l_arr_rec_salearea[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salearea[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH
	 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9086,"") 
	END IF

	RETURN l_arr_rec_salearea 
END FUNCTION 
###########################################################################
# END FUNCTION salearea_get_datasource()
#
#
###########################################################################


###########################################################################
# FUNCTION scan_area()
#
#
###########################################################################
FUNCTION scan_area() 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL salearea_get_datasource(FALSE) RETURNING l_arr_rec_salearea
	 
	MESSAGE kandoomsg2("E",1106,"")	#1106 " Sales Area Statistics - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_salearea TO sr_salearea.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EF1","input-arr-l_arr_rec_salearea-1") -- albo kd-502 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salearea.clear()
			CALL salearea_get_datasource(TRUE) RETURNING l_arr_rec_salearea
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
					
		ON ACTION "REFRESH"
			 CALL windecoration_e("E240")
			CALL l_arr_rec_salearea.clear()
			CALL salearea_get_datasource(TRUE) RETURNING l_arr_rec_salearea
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salearea.getSize()) THEN 
				CALL area_stats(glob_rec_kandoouser.cmpy_code, l_arr_rec_salearea[l_idx].area_code) 
			END IF 
 			
		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
###########################################################################
# END FUNCTION scan_area()
###########################################################################


###########################################################################
# FUNCTION area_stats(p_cmpy_code,p_area_code)
#
#
###########################################################################
FUNCTION area_stats(p_cmpy_code,p_area_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_area_code LIKE salearea.area_code 
	DEFINE l_arr_rec_areamenu array[9] OF RECORD 
		scroll_flag char(1), 
		option_num char(1), 
		option_text char(30) 
	END RECORD 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT	

	LET l_idx = 0 
	SELECT * INTO l_rec_salearea.* 
	FROM salearea 
	WHERE cmpy_code = p_cmpy_code 
	AND area_code = p_area_code 

	IF status = 0 THEN 
		FOR l_idx = 1 TO 4 
			LET l_arr_rec_areamenu[l_idx].option_num = l_idx 
			LET l_arr_rec_areamenu[l_idx].option_text = kandooword("areawind",l_idx) 
		END FOR 
		CALL set_count(4) 

		OPEN WINDOW E241 with FORM "E241" 
		 CALL windecoration_e("E241") -- albo kd-755 

		DISPLAY BY NAME 
		l_rec_salearea.area_code, 
		l_rec_salearea.desc_text 

		MESSAGE kandoomsg2("A",1030,"")


#HuHO: Why so complicated ???? commented orignal menu code
		DISPLAY ARRAY l_arr_rec_areamenu TO sr_areamenu.*
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","EF1","input-arr-l_arr_rec_areamenu-1")

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				
			ON ACTION ("ACCEPT","DOUBLECLICK")
				CASE l_idx
					#-------------------------------------------
					# turnover figures
					WHEN "1"  
						CALL run_prog("EF2",p_area_code,"","","") 
					#-------------------------------------------
					# number OF customers
					WHEN "2"  
						CALL run_prog("EF3",p_area_code,"","","") 
					#-------------------------------------------
					# distribution
					WHEN "3"  
						CALL run_prog("EF4",p_area_code,"","","") 
					#-------------------------------------------
					# profit figures
					WHEN "4"  
						CALL run_prog("EF5",p_area_code,"","","") 
				END CASE 
		
		END DISPLAY
		 
{		 
		INPUT ARRAY l_arr_rec_areamenu WITHOUT DEFAULTS FROM sr_areamenu.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","EF1","input-arr-l_arr_rec_areamenu-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			BEFORE FIELD option_num 
				IF l_arr_rec_areamenu[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_rec_areamenu[l_idx].scroll_flag = l_arr_rec_areamenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_arr_rec_areamenu[l_idx].scroll_flag IS NOT null) 
						IF l_arr_rec_areamenu[i].option_num IS NULL THEN 
							LET l_arr_rec_areamenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_arr_rec_areamenu[l_idx].scroll_flag= 
							l_arr_rec_areamenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 
				END IF 

				CASE l_arr_rec_areamenu[l_idx].scroll_flag 
					WHEN "1" ## turnover figures 
						CALL run_prog("EF2",p_area_code,"","","") 
					WHEN "2" ## number OF customers 
						CALL run_prog("EF3",p_area_code,"","","") 
					WHEN "3" ## distribution 
						CALL run_prog("EF4",p_area_code,"","","") 
					WHEN "4" ## profit figures 
						CALL run_prog("EF5",p_area_code,"","","") 
				END CASE 
				LET l_arr_rec_areamenu[l_idx].scroll_flag = NULL 
				NEXT FIELD scroll_flag 

		END INPUT
} 
		CLOSE WINDOW E241 
	END IF
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION area_stats(p_cmpy_code,p_area_code)
###########################################################################