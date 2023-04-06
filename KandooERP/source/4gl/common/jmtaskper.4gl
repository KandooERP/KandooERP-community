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

	Source code beautified by beautify.pl on 2020-01-02 10:35:16	$Id: $
}



#         jmtaskper.4gl - show_taskperiods
#                         window FUNCTION FOR finding taskperiod records
#                         returns task_period_ind
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_taskperiods(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_taskperiod RECORD LIKE taskperiod.* 
	DEFINE l_arr_taskperiod array[100] OF RECORD 
				scroll_flag CHAR(1), 
				task_period_ind LIKE taskperiod.task_period_ind, 
				task_period_text LIKE taskperiod.task_period_text, 
				days_qty LIKE taskperiod.days_qty, 
				avg_days_qty LIKE taskperiod.avg_days_qty 
			 END RECORD 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_idx SMALLINT
	DEFINE l_scrn SMALLINT	 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j194 with FORM "J194" 
	CALL windecoration_j("J194") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON task_period_ind, 
		task_period_text, 
		days_qty, 
		avg_days_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jmtaskper","construct-task") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_taskperiod.task_period_ind = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM taskperiod ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY task_period_ind" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_taskperiod FROM l_query_text 
		DECLARE c_taskperiod CURSOR FOR s_taskperiod 
		LET l_idx = 0 
		FOREACH c_taskperiod INTO l_rec_taskperiod.* 
			LET l_idx = l_idx + 1 
			LET l_arr_taskperiod[l_idx].task_period_ind = l_rec_taskperiod.task_period_ind 
			LET l_arr_taskperiod[l_idx].task_period_text = l_rec_taskperiod.task_period_text 
			LET l_arr_taskperiod[l_idx].days_qty = l_rec_taskperiod.days_qty 
			LET l_arr_taskperiod[l_idx].avg_days_qty = l_rec_taskperiod.avg_days_qty 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_taskperiod[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_taskperiod WITHOUT DEFAULTS FROM sr_taskperiod.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jmtaskper","input-arr-taskperiod") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_taskperiod[l_idx].task_period_ind IS NOT NULL THEN 
					DISPLAY l_arr_taskperiod[l_idx].* TO sr_taskperiod[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("JZ8","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_taskperiod[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD task_period_ind 
				LET l_rec_taskperiod.task_period_ind = l_arr_taskperiod[l_idx].task_period_ind 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_taskperiod[l_idx].* TO sr_taskperiod[l_scrn].* 

			AFTER INPUT 
				LET l_rec_taskperiod.task_period_ind = l_arr_taskperiod[l_idx].task_period_ind 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j194 
	RETURN l_rec_taskperiod.task_period_ind 
END FUNCTION 


