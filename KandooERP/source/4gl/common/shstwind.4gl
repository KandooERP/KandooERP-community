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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}



# Window FUNCTION FOR Shipment Status

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_shipst(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_shipstatus ARRAY[100] OF RECORD 
		ship_status_code LIKE shipstatus.ship_status_code, 
		desc_text LIKE shipstatus.desc_text 
	END RECORD 
	DEFINE l_idx, l_cnt, l_scrn SMALLINT
	DEFINE l_query_text CHAR(2200)
	DEFINE l_sel_text CHAR(2048) 

	OPEN WINDOW currwind with FORM "L115" 
	CALL windecoration_l("L115") -- albo kd-752 

	WHILE true 
		MESSAGE " Enter criteria - press ESC" attribute (yellow) 
		CONSTRUCT l_query_text ON ship_status_code, desc_text 
		FROM sr_shipstatus[1].* 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","shstwind","construct-shipstatus") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 



		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW currwind 
			RETURN "" 
		END IF 

		LET l_sel_text = "SELECT ship_status_code, desc_text ", 
		" FROM shipstatus WHERE cmpy_code = '",p_cmpy, 
		"' AND ", l_query_text CLIPPED, 
		" ORDER BY ship_status_code" 
		PREPARE shipstatuser FROM l_sel_text 
		DECLARE shipstatuscurs CURSOR FOR shipstatuser 
		LET l_idx = 1 
		FOREACH shipstatuscurs INTO l_arr_shipstatus[l_idx].* 
			LET l_idx = l_idx + 1 
			IF l_idx > 95 THEN 
				ERROR "Only first 95 selected" 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_idx = l_idx -1 
		IF l_idx > 0 THEN 
			EXIT WHILE 
		END IF 

		MESSAGE "No shipstatus satisfies query" attribute (yellow) 
		SLEEP 2 
		EXIT WHILE 
	END WHILE 
	LET l_cnt = l_idx 
	CALL set_count(l_idx) 

	MESSAGE "Cursor TO shipstatus - press ESC, F10 add" attribute (yellow) 
	INPUT ARRAY l_arr_shipstatus WITHOUT DEFAULTS FROM sr_shipstatus.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","shstwind","input-arr-shipstatus") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CALL run_prog("LZ2","","","","") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_shipstatus[l_idx].* TO sr_shipstatus[l_scrn].* 

			END IF 
		AFTER ROW 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_shipstatus[l_idx].* TO sr_shipstatus[l_scrn].* 

			END IF 

	END INPUT 
	LET l_idx = arr_curr() 
	CLOSE WINDOW currwind 

	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN l_arr_shipstatus[l_idx].ship_status_code 

END FUNCTION 


