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

	Source code beautified by beautify.pl on 2020-01-02 10:35:44	$Id: $
}



#    wspoffwin.4gl - show_pricing
#                    window FUNCTION FOR finding pricing records
#                    returns offer_code AND start_date
GLOBALS "../common/glob_GLOBALS.4gl" 


####################################################################
# FUNCTION show_pricing(p_cmpy, filter_text)
#
#
#
####################################################################
FUNCTION show_pricing(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(100)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_pricing RECORD LIKE pricing.* 
	DEFINE l_arr_pricing ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE pricing.offer_code, 
		desc_text LIKE pricing.desc_text, 
		start_date LIKE pricing.start_date 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	OPEN WINDOW w154 with FORM "W154" 
	CALL windecoration_w("W154") 

	WHILE TRUE 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON offer_code, 
		desc_text, 
		start_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wspoffwin","construct-pricing") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_pricing.offer_code = NULL 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM pricing ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",p_filter_text CLIPPED," ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY offer_code, start_date" 
		WHENEVER ERROR CONTINUE 

		OPTIONS SQL interrupt ON 
		PREPARE s_pricing FROM l_query_text 
		DECLARE c_pricing CURSOR FOR s_pricing 

		LET l_idx = 0 
		FOREACH c_pricing INTO l_rec_pricing.* 
			LET l_idx = l_idx + 1 
			LET l_arr_pricing[l_idx].offer_code = l_rec_pricing.offer_code 
			LET l_arr_pricing[l_idx].desc_text = l_rec_pricing.desc_text 
			LET l_arr_pricing[l_idx].start_date = l_rec_pricing.start_date 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected

		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_pricing[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"

		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_pricing WITHOUT DEFAULTS FROM sr_pricing.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","wspoffwin","input-arr-pricing") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#IF l_arr_pricing[l_idx].offer_code IS NOT NULL THEN
				#   DISPLAY l_arr_pricing[l_idx].* TO sr_pricing[scrn].*
				#END IF
				#NEXT FIELD scroll_flag

				ON KEY (F10) --run izr - add new RECORD / list entry / promotion code RECORD 
					CALL run_prog("IZR","","","","") 
					NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_pricing[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD offer_code 
				LET l_rec_pricing.offer_code = l_arr_pricing[l_idx].offer_code 
				LET l_rec_pricing.start_date = l_arr_pricing[l_idx].start_date 
				EXIT INPUT 

				#AFTER ROW
				#  DISPLAY l_arr_pricing[l_idx].* TO sr_pricing[scrn].*

			AFTER INPUT 
				LET l_rec_pricing.offer_code = l_arr_pricing[l_idx].offer_code 
				LET l_rec_pricing.start_date = l_arr_pricing[l_idx].start_date 


		END INPUT 
		#########################

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w154 

	RETURN l_rec_pricing.offer_code, l_rec_pricing.start_date 
END FUNCTION 


