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
GLOBALS "../eo/EE_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EE1_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_temp_text char(10) 
###########################################################################
# FUNCTION EE1_main()
#
# Allows the user TO view Sales Territory Information
###########################################################################
FUNCTION EE1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EE1") -- albo 

	OPEN WINDOW E247 with FORM "E247" 
	 CALL windecoration_e("E247") -- albo kd-755 
	
	CALL scan_territory() 

	CLOSE WINDOW E247
	 
END FUNCTION
###########################################################################
# END FUNCTION EE1_main()
###########################################################################


###########################################################################
# FUNCTION db_territory_get_datasource(p_filter) 
#
# 
###########################################################################
FUNCTION db_territory_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory  DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code, 
		sale_code LIKE territory.sale_code, 
		terr_type_ind LIKE territory.terr_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			terr_code, 
			desc_text, 
			area_code, 
			sale_code, 
			terr_type_ind 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EE1","construct-terr_code-1") 
	
			ON ACTION "WEB-HELP"
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
	
	MESSAGE kandoomsg2("A",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * ", 
	"FROM territory ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY 1,2" 
	PREPARE s_territory FROM l_query_text 
	DECLARE c_territory cursor FOR s_territory 

	LET l_idx = 0 
	FOREACH c_territory INTO l_rec_territory.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_territory[l_idx].terr_code = l_rec_territory.terr_code 
		LET l_arr_rec_territory[l_idx].desc_text = l_rec_territory.desc_text 
		LET l_arr_rec_territory[l_idx].area_code = l_rec_territory.area_code 
		LET l_arr_rec_territory[l_idx].sale_code = l_rec_territory.sale_code 
		LET l_arr_rec_territory[l_idx].terr_type_ind = l_rec_territory.terr_type_ind
		 
		SELECT unique 1 FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_rec_territory.area_code 
		AND terr_code = l_rec_territory.terr_code 
		IF status = 0 THEN 
			LET l_arr_rec_territory[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_territory[l_idx].stat_flag = NULL 
		END IF

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		 
	END FOREACH
	 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9081,"")	#9081" No Sales Territories Satsified Selection Criteria "
	END IF
	
	RETURN l_arr_rec_territory
END FUNCTION 
###########################################################################
# END FUNCTION db_territory_get_datasource(p_filter) 
###########################################################################


###########################################################################
# FUNCTION scan_territory()  
#
# 
###########################################################################
FUNCTION scan_territory() 
	DEFINE l_arr_rec_territory  DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code, 
		sale_code LIKE territory.sale_code, 
		terr_type_ind LIKE territory.terr_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_territory_get_datasource(FALSE) RETURNING l_arr_rec_territory
	 
	MESSAGE kandoomsg2("E",1115,"") #" Sales Territory Statistics - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_territory TO sr_territory.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EE1","input-arr-l_arr_rec_territory-1") -- albo kd-502 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_territory.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_territory.clear()
			CALL db_territory_get_datasource(TRUE) RETURNING l_arr_rec_territory
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_territory.getSize())
			
		ON ACTION "REFRESH"
			 CALL windecoration_e("E247")
			CALL l_arr_rec_territory.clear()
			CALL db_territory_get_datasource(FALSE) RETURNING l_arr_rec_territory
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_territory.getSize())
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD terr_code
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_territory.getSize()) THEN 
				CALL terr_stats(glob_rec_kandoouser.cmpy_code, l_arr_rec_territory[l_idx].terr_code)
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_territory()  
###########################################################################


###########################################################################
# FUNCTION terr_stats(p_cmpy_code,p_terr_code)  
#
# 
###########################################################################
FUNCTION terr_stats(p_cmpy_code,p_terr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_terr_code LIKE territory.terr_code 
	DEFINE l_arr_rec_terrmenu array[9] OF RECORD 
		scroll_flag char(1), 
		option_num char(1), 
		option_text char(30) 
	END RECORD 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_runner STRING 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	DEFINE l_arg_terr_code STRING
	LET l_idx = 0 
	SELECT * INTO l_rec_territory.* 
	FROM territory 
	WHERE cmpy_code = p_cmpy_code 
	AND terr_code = p_terr_code 
	IF status = 0 THEN 
		FOR l_idx = 1 TO 2 
			LET l_arr_rec_terrmenu[l_idx].option_num = l_idx 
			LET l_arr_rec_terrmenu[l_idx].option_text = kandooword("terrwind",l_idx) 
		END FOR
		 
		CALL set_count(2) 
		
		OPEN WINDOW E248 with FORM "E248" 
		 CALL windecoration_e("E248") -- albo kd-755
 
		DISPLAY BY NAME l_rec_territory.terr_code 
		DISPLAY BY NAME l_rec_territory.desc_text 

		MESSAGE kandoomsg2("A",1030,"") 
		INPUT ARRAY l_arr_rec_terrmenu WITHOUT DEFAULTS FROM sr_terrmenu.* ATTRIBUTE(UNBUFFERED,APPEND ROW = FALSE,AUTO APPEND = FALSE,COUNT = 2) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","EE1","input-arr-l_arr_rec_terrmenu-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			BEFORE FIELD option_num 
				IF l_arr_rec_terrmenu[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_rec_terrmenu[l_idx].scroll_flag = l_arr_rec_terrmenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_arr_rec_terrmenu[l_idx].scroll_flag IS NOT null) 
						IF l_arr_rec_terrmenu[i].option_num IS NULL THEN 
							LET l_arr_rec_terrmenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_arr_rec_terrmenu[l_idx].scroll_flag= 
							l_arr_rec_terrmenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 
				END IF 

				CASE l_arr_rec_terrmenu[l_idx].scroll_flag 
					#----------------------------------------
					# monthly turnover 
					WHEN "1" 
						LET l_arg_terr_code = "TERR_CODE=", trim(p_terr_code)
						CALL run_prog("EE2",l_arg_terr_code,"","","") 
					#----------------------------------------
					# distribution
					WHEN "2"  
						CALL run_prog("EE3",l_arg_terr_code,"","","") 
				END CASE 

				LET l_arr_rec_terrmenu[l_idx].scroll_flag = NULL 
 
		END INPUT 

		CLOSE WINDOW E248 
	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION terr_stats(p_cmpy_code,p_terr_code)  
###########################################################################