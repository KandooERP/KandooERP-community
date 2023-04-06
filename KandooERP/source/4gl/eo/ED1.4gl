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
GLOBALS "../eo/ED_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ED1_GLOBALS.4gl"
###########################################################################
# FUNCTION ED1_main()
#
# Allows the user TO scan Sales Manager Information
###########################################################################
FUNCTION ED1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ED1") 

	OPEN WINDOW E226 with FORM "E226" 
	 CALL windecoration_e("E226") 

	CALL show_salesmgr_list() 

	CLOSE WINDOW E226 
END FUNCTION 
###########################################################################
# END FUNCTION ED1_main()
###########################################################################


###########################################################################
# FUNCTION get_salesmgr_datasource() 
#
# 
###########################################################################
FUNCTION get_salesmgr_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_arr_rec_salesmgr DYNAMIC ARRAY OF RECORD -- 
		scroll_flag char(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN
		ERROR kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON mgr_code,	name_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ED1","construct-mgr_code-1") -- albo kd-502 
	
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
		"SELECT * FROM salesmgr ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"mgr_code" 
	PREPARE s_salesmgr FROM l_query_text 
	DECLARE c_salesmgr cursor FOR s_salesmgr 

	LET l_idx = 0 

	FOREACH c_salesmgr INTO l_rec_salesmgr.* 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesmgr[l_idx].scroll_flag = NULL 
		LET l_arr_rec_salesmgr[l_idx].mgr_code = l_rec_salesmgr.mgr_code 
		LET l_arr_rec_salesmgr[l_idx].name_text = l_rec_salesmgr.name_text 

		SELECT unique 1 FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code IS NULL 
		AND mgr_code = l_rec_salesmgr.mgr_code 

		IF status = 0 THEN 
			LET l_arr_rec_salesmgr[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salesmgr[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	IF l_arr_rec_salesmgr.getSize() = 0 THEN
		ERROR kandoomsg2("A",9082,"")
	END IF
	
	RETURN l_arr_rec_salesmgr
END FUNCTION 
###########################################################################
# END FUNCTION get_salesmgr_datasource(p_filter) 
###########################################################################


###########################################################################
# FUNCTION show_salesmgr_list() 
#
# 
###########################################################################
FUNCTION show_salesmgr_list() 
	DEFINE l_arr_rec_salesmgr DYNAMIC ARRAY OF RECORD -- 
		scroll_flag char(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL get_salesmgr_datasource(FALSE) RETURNING l_arr_rec_salesmgr

	MESSAGE kandoomsg2("E",1086,"") 	#1086 " Sales Manager Statistics - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_salesmgr TO sr_salesmgr.* ATTRIBUTE(UNBUFFERED)

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","ED1","input-arr-l_arr_rec_salesmgr-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesmgr.clear()
			CALL get_salesmgr_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())	
			
		ON ACTION "REFRESH"
			 CALL windecoration_e("E226")
			CALL l_arr_rec_salesmgr.clear()
			CALL get_salesmgr_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())		

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD mgr_code 
			IF l_idx > 0 THEN
				CALL salesmgr_stats(glob_rec_kandoouser.cmpy_code, l_arr_rec_salesmgr[l_idx].mgr_code)
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION show_salesmgr_list() 
###########################################################################


###########################################################################
# FUNCTION salesmgr_stats(p_cmpy_code,p_mgr_code) 
#
# 
###########################################################################
FUNCTION salesmgr_stats(p_cmpy_code,p_mgr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_mgr_code LIKE salesmgr.mgr_code 
	DEFINE l_arr_rec_mgrmenu array[9] OF RECORD 
		scroll_flag char(1), 
		option_num char(1), 
		option_text char(30) 
	END RECORD 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_runner STRING 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	LET l_idx = 0 
	SELECT * INTO l_rec_salesmgr.* 
	FROM salesmgr 
	WHERE cmpy_code = p_cmpy_code 
	AND mgr_code = p_mgr_code 
	IF status = 0 THEN 
		FOR l_idx = 1 TO 4 
			LET l_arr_rec_mgrmenu[l_idx].option_num = l_idx 
			LET l_arr_rec_mgrmenu[l_idx].option_text = kandooword("mgrwind",l_idx) 
		END FOR 

		CALL set_count(4) 

		OPEN WINDOW E228 with FORM "E228" 
		 CALL windecoration_e("E228") -- albo kd-755
 
		DISPLAY BY NAME l_rec_salesmgr.mgr_code 
		DISPLAY BY NAME l_rec_salesmgr.name_text 

		MESSAGE kandoomsg2("A",1030,"") 
		DISPLAY ARRAY l_arr_rec_mgrmenu TO sr_mgrmenu.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","ED1","input-arr-l_arr_rec_mgrmenu-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD option_num
				IF l_idx > 0 THEN 

					CASE l_idx
						WHEN "1" ## monthly turnover 
							CALL run_prog("ED2",p_mgr_code,"","","") 
						WHEN "2" ## monthly turnover BY salesperson 
							CALL run_prog("ED3",p_mgr_code,"","","") 
						WHEN "3" ## distribution 
							CALL run_prog("ED4",p_mgr_code,"","","") 
						WHEN "4" ## profit figures 
							CALL run_prog("ED5",p_mgr_code,"","","") 
					END CASE 
				END IF
				
		END DISPLAY 

		CLOSE WINDOW E228 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION salesmgr_stats(p_cmpy_code,p_mgr_code) 
###########################################################################