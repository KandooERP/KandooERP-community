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
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E14_GLOBALS.4gl"

###########################################################################
# FUNCTION E14_main()
#
# Inquiry Program TO DISPLAY ORDER amendment logging rows
###########################################################################
FUNCTION E14_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E14") 

	CALL scan_orderlog() 
	 
END FUNCTION 
###########################################################################
# END FUNCTION E14_main()
###########################################################################


###########################################################################
# FUNCTION db_orderlog_get_datasource() 
#
# Inquiry Program TO DISPLAY ORDER amendment logging rows
###########################################################################
FUNCTION db_orderlog_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_orderlog RECORD LIKE orderlog.* 
	DEFINE l_arr_rec_orderlog DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		order_num LIKE orderlog.order_num, 
		amend_date LIKE orderlog.amend_date, 
		amend_time LIKE orderlog.amend_time, 
		amend_code LIKE orderlog.amend_code, 
		event_text LIKE orderlog.event_text, 
		curr_text LIKE orderlog.curr_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN

		CLEAR FORM 
		ERROR kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	
		CONSTRUCT BY NAME l_where_text ON order_num, 
		amend_date, 
		amend_time, 
		amend_code, 
		event_text, 
		curr_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E14","construct-order_num-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
				
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF
	 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	 
	MESSAGE kandoomsg2("E",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * ", 
	"FROM orderlog ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY cmpy_code, order_num, log_num " 
	PREPARE s_orderlog FROM l_query_text 
	DECLARE c_orderlog cursor FOR s_orderlog 

	LET l_idx = 0 
	FOREACH c_orderlog INTO l_rec_orderlog.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderlog[l_idx].order_num = l_rec_orderlog.order_num 
		LET l_arr_rec_orderlog[l_idx].amend_date = l_rec_orderlog.amend_date 
		LET l_arr_rec_orderlog[l_idx].amend_time = l_rec_orderlog.amend_time 
		LET l_arr_rec_orderlog[l_idx].amend_code = l_rec_orderlog.amend_code 
		LET l_arr_rec_orderlog[l_idx].event_text = l_rec_orderlog.event_text 
		LET l_arr_rec_orderlog[l_idx].curr_text = l_rec_orderlog.curr_text
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		 
	END FOREACH 
	
	RETURN l_arr_rec_orderlog 
END FUNCTION 
###########################################################################
# END FUNCTION db_orderlog_get_datasource()
###########################################################################


###########################################################################
# FUNCTION scan_orderlog()  
#
# Inquiry Program TO DISPLAY ORDER amendment logging rows
###########################################################################
FUNCTION scan_orderlog() 

	DEFINE l_arr_rec_orderlog DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		order_num LIKE orderlog.order_num, 
		amend_date LIKE orderlog.amend_date, 
		amend_time LIKE orderlog.amend_time, 
		amend_code LIKE orderlog.amend_code, 
		event_text LIKE orderlog.event_text, 
		curr_text LIKE orderlog.curr_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	 
	OPEN WINDOW E161 with FORM "E161" 
	 CALL windecoration_e("E161") -- albo kd-755 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
 
	CALL db_orderlog_get_datasource(FALSE) RETURNING l_arr_rec_orderlog

	DISPLAY ARRAY l_arr_rec_orderlog TO  sr_orderlog.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E14","input-l_arr_rec_orderlog-1") -- albo kd-502 
			IF l_arr_rec_orderlog.getSize() = 0 THEN
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				CALL dialog.setActionHidden("FILTER",TRUE)
				CALL dialog.setActionHidden("REFRESH",TRUE)
			END IF
			ERROR kandoomsg2("E",9150,"") 	#9150" No ORDER amendments selection criteria "

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Refresh"
			 CALL windecoration_e("E161")
			CALL l_arr_rec_orderlog.clear()
			CALL db_orderlog_get_datasource(FALSE) RETURNING l_arr_rec_orderlog

		ON ACTION "FILTER"
			CALL l_arr_rec_orderlog.clear()
			CALL db_orderlog_get_datasource(TRUE) RETURNING l_arr_rec_orderlog

			IF l_arr_rec_orderlog.getSize() = 0 THEN
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				CALL dialog.setActionHidden("FILTER",TRUE)
				CALL dialog.setActionHidden("REFRESH",TRUE)
			ELSE
				CALL dialog.setActionHidden("ACCEPT",FALSE)
				CALL dialog.setActionHidden("FILTER",FALSE)
				CALL dialog.setActionHidden("REFRESH",FALSE)
			END IF

		BEFORE ROW
			LET l_idx = arr_curr()
			
	END DISPLAY

	CLOSE WINDOW E161	 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN NULL
	ELSE
		RETURN l_arr_rec_orderlog[l_idx].order_num
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION scan_orderlog()
###########################################################################