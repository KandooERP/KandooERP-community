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

	Source code beautified by beautify.pl on 2020-01-02 10:35:10	$Id: $
}



#     custwind.4gl - show_cust
#                    Window FUNCTION FOR finding customer records
#                    returns cust_code
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_cust(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_arr_customer ARRAY[100] OF RECORD 
					scroll_flag CHAR(1), 
					cust_code LIKE customer.cust_code, 
					name_text LIKE customer.name_text, 
					tele_text LIKE customer.tele_text, 
					city_text LIKE customer.city_text 
			 END RECORD 
	DEFINE l_idx  SMALLINT 
	DEFINE l_scrn SMALLINT
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = p_cmpy 
	AND arparms.parm_code = "1" 
	OPEN WINDOW A124 with FORM "A124" 
	CALL windecoration_a("A124") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		MESSAGE "Enter Selection Criteria - Apply TO Continue"
		CONSTRUCT BY NAME l_where_text ON cust_code, 
		name_text, 
		tele_text, 
		city_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","custwind","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_customer.cust_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE "Searching database - please wait"
		LET l_query_text = "SELECT * FROM customer ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," " 
		IF l_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = l_query_text CLIPPED," ORDER BY cust_code" 
		ELSE 
			LET l_query_text = l_query_text CLIPPED," ORDER BY name_text" 
		END IF 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_customer FROM l_query_text 
		DECLARE c_customer CURSOR FOR s_customer 
		LET l_idx = 0 
		FOREACH c_customer INTO l_rec_customer.* 
			LET l_idx = l_idx + 1 
			LET l_arr_customer[l_idx].cust_code = l_rec_customer.cust_code 
			LET l_arr_customer[l_idx].name_text = l_rec_customer.name_text 
			LET l_arr_customer[l_idx].tele_text = l_rec_customer.tele_text 
			IF l_rec_customer.city_text IS NULL THEN 
				LET l_arr_customer[l_idx].city_text = l_rec_customer.addr2_text 
			ELSE 
				LET l_arr_customer[l_idx].city_text = l_rec_customer.city_text 
			END IF 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		MESSAGE l_idx CLIPPED, " records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_customer[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		MESSAGE "Select line, Cancel or Add (F10)"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_customer WITHOUT DEFAULTS FROM sr_customer.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","custwind","input-arr-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_customer[l_idx].cust_code IS NOT NULL THEN 
					DISPLAY l_arr_customer[l_idx].* TO sr_customer[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("A11","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_customer[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD cust_code 
				LET l_rec_customer.cust_code = l_arr_customer[l_idx].cust_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_customer[l_idx].* TO sr_customer[l_scrn].* 

			AFTER INPUT 
				LET l_rec_customer.cust_code = l_arr_customer[l_idx].cust_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW A124 

	RETURN l_rec_customer.cust_code 
END FUNCTION 


