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

	Source code beautified by beautify.pl on 2020-01-02 10:35:36	$Id: $
}



#
# Status Code lookup window FOR finding STATUS codes WHEN adding Contracts.

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_status() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_pa_status ARRAY[4] OF RECORD 
		status_code LIKE contracthead.status_code, 
		status_text CHAR(21) 
	END RECORD 
	DEFINE l_arr_ps_status ARRAY[4] OF RECORD 
		status_code LIKE contracthead.status_code, 
		status_text CHAR(21) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_arr_size SMALLINT 
	DEFINE l_formname CHAR(15) 

	OPEN WINDOW wa908 with FORM "A908" 
	CALL windecoration_a("A908") -- albo kd-767 
	LET l_msgresp = kandoomsg("A",1513,"") # "ESC TO accept, DEL TO EXIT"

	LET l_arr_pa_status[1].status_code = "A" 
	LET l_arr_pa_status[2].status_code = "Q" 
	LET l_arr_pa_status[3].status_code = "H" 
	LET l_arr_pa_status[4].status_code = "C" 
	LET l_arr_pa_status[1].status_text = "Active " 
	LET l_arr_pa_status[2].status_text = "Quote " 
	LET l_arr_pa_status[3].status_text = "Hold (no billing)" 
	LET l_arr_pa_status[4].status_text = "Complete (no billing)" 

	LET l_idx = 4 
	LET l_arr_size = 4 
	CALL set_count(l_arr_size) 

	INPUT ARRAY l_arr_pa_status WITHOUT DEFAULTS FROM sr_status.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","sttswind","input-arr-STATUS") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			LET l_arr_ps_status[l_idx].* = l_arr_pa_status[l_idx].* 

		AFTER ROW 
			DISPLAY l_arr_ps_status[l_idx].* TO sr_status[l_scrn].* 
			LET l_arr_pa_status[l_idx].* = l_arr_ps_status[l_idx].* 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wa908 
		RETURN "" 
	END IF 

	CLOSE WINDOW wa908 
	LET l_idx = arr_curr() 
	RETURN l_arr_pa_status[l_idx].status_code 

END FUNCTION 


