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

	Source code beautified by beautify.pl on 2020-01-02 10:35:22	$Id: $
}



# FUNCTION year_period shows those periods available FOR the ledger passed
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION year_period( p_cmpy,p_ledger_type) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_ledger_type CHAR(2)
	DEFINE l_msgresp LIKE language.yes_flag 
   DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_arr_period ARRAY[310] OF RECORD 
				year_num LIKE period.year_num, 
				period_num LIKE period.period_num 
			 END RECORD
	DEFINE l_scrn, l_idx SMALLINT
	DEFINE l_sel_text CHAR(2200)
   DEFINE l_where_part CHAR(2048)

	OPEN WINDOW wg171 with FORM "G171" 
	CALL windecoration_g("G171") 

	CASE 
		WHEN (p_ledger_type = LEDGER_TYPE_GL) 
			LET l_where_part = " gl_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = LEDGER_TYPE_AR) 
			LET l_where_part = " ar_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = "ap") 
			LET l_where_part = " ap_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = LEDGER_TYPE_IN) 
			LET l_where_part = " in_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = LEDGER_TYPE_OE) 
			LET l_where_part = " oe_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = LEDGER_TYPE_PU) 
			LET l_where_part = " pu_flag = ", "\"", "Y", "\"" 
		WHEN (p_ledger_type = LEDGER_TYPE_JM) 
			LET l_where_part = " jm_flag = ", "\"", "Y", "\"" 
		OTHERWISE 
			LET l_where_part = " 1=1 " 
	END CASE 

	LET l_sel_text = 
	"SELECT unique year_num, period_num ", 
	"FROM period WHERE cmpy_code = ? AND ", 
	l_where_part CLIPPED, 
	"ORDER BY year_num, period_num " 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		EXIT program 
	END IF 
	PREPARE getper FROM l_sel_text 
	DECLARE c_per CURSOR FOR getper 
	OPEN c_per USING p_cmpy 

	LET l_idx = 0 
	FOREACH c_per INTO l_rec_period.year_num, l_rec_period.period_num 
		LET l_idx = l_idx + 1 
		LET l_arr_period[l_idx].year_num = l_rec_period.year_num 
		LET l_arr_period[l_idx].period_num = l_rec_period.period_num 
		IF l_idx > 300 THEN 
			MESSAGE " Only first 300 selected " attribute(yellow) 
			SLEEP 4 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (l_idx) 

	MESSAGE "" 
	MESSAGE "Press RETURN on SELECT " 
	attribute (yellow) 

	WHILE true 
		INPUT ARRAY l_arr_period WITHOUT DEFAULTS FROM sr_period.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","periodfunc","input-arr-period") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 

				IF arr_curr() > arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 "No more rows in the direction you are going"
				END IF 

			BEFORE FIELD period_num 

				EXIT INPUT 


		END INPUT 
		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			LET quit_flag = 0 
			LET int_flag = 0 
			LET l_msgresp = kandoomsg("P",9520,"") 
			#9520 A valid year/period must be selected
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wg171 

	RETURN l_arr_period[l_idx].year_num, 
	l_arr_period[l_idx].period_num 
END FUNCTION 



