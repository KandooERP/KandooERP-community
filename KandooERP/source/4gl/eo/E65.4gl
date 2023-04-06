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
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E65_GLOBALS.4gl"

###########################################################################
# FUNCTION E65_main()
#
# E65 - allows users TO SELECT a special offer TO peruse
#       profit information FROM statistics tables.
###########################################################################
FUNCTION E65_main() 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E65") -- albo 

	LET glob_yes_flag = xlate_from("Y") 
	LET glob_no_flag = xlate_from("N")
	 
	OPEN WINDOW E253 with FORM "E253" 
	 CALL windecoration_e("E253") -- albo kd-755 

	CALL scan_offersale() 

	CLOSE WINDOW E253 
END FUNCTION 
###########################################################################
# END FUNCTION E65_main()
###########################################################################


###########################################################################
# FUNCTION db_offersale_get_datasource(p_filter)
#
# 
###########################################################################
FUNCTION db_offersale_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		start_date LIKE offersale.start_date, 
		end_date LIKE offersale.end_date, 
		prodline_disc_flag LIKE offersale.prodline_disc_flag, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"")	#MESSAGE " Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			offer_code, 
			desc_text, 
			start_date, 
			end_date, 
			prodline_disc_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E65","construct-offer_code-1") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 
	
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
	
	MESSAGE kandoomsg2("E",1002,"")	#MESSAGE " Searching database - please wait "
	LET l_query_text = 
		"SELECT * ", 
		"FROM offersale ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"offer_code" 
	PREPARE s_offersale FROM l_query_text 
	DECLARE c_offersale cursor FOR s_offersale 
	
	LET l_idx = 0 
	FOREACH c_offersale INTO l_rec_offersale.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_offersale[l_idx].scroll_flag = NULL 
		LET l_arr_rec_offersale[l_idx].offer_code = l_rec_offersale.offer_code 
		LET l_arr_rec_offersale[l_idx].desc_text = l_rec_offersale.desc_text 
		LET l_arr_rec_offersale[l_idx].start_date = l_rec_offersale.start_date 
		LET l_arr_rec_offersale[l_idx].end_date = l_rec_offersale.end_date 
		LET l_arr_rec_offersale[l_idx].prodline_disc_flag =	xlate_from(l_rec_offersale.prodline_disc_flag) 

		SELECT unique 1 FROM statoffer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = l_rec_offersale.offer_code 
		IF status = 0 THEN 
			LET l_arr_rec_offersale[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_offersale[l_idx].stat_flag = NULL 
		END IF 
--		IF l_idx = 200 THEN 
--			MESSAGE kandoomsg2("E",9010,l_idx) 
--			#9010 First 200 offers selected only
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9011,"") #9011 " No Special Offers Satisfied Selection Criteria "
--		INITIALIZE l_arr_rec_offersale[l_idx+1].start_date TO NULL 
--		INITIALIZE l_arr_rec_offersale[l_idx+1].end_date TO NULL 
	END IF 

	RETURN l_arr_rec_offersale 
END FUNCTION 
###########################################################################
# END FUNCTION db_offersale_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_offersale()
#
# 
###########################################################################
FUNCTION scan_offersale() 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		start_date LIKE offersale.start_date, 
		end_date LIKE offersale.end_date, 
		prodline_disc_flag LIKE offersale.prodline_disc_flag, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	#Populate dataArray with conditional construct, based on it's size 
	IF db_offersale_get_count() > get_settings_maxListArraySizeSwitch() THEN
		CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale
	ELSE
		CALL db_offersale_get_datasource(FALSE) RETURNING l_arr_rec_offersale
	END IF
	
	MESSAGE kandoomsg2("E",1148,"") #1148 Special Offer Profit Figures - RETURN TO View
	DISPLAY ARRAY l_arr_rec_offersale TO sr_offersale.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E65","input-arr-l_arr_rec_offersale-1") 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_offersale.getSize())
 			
		BEFORE ROW  
			LET l_idx = arr_curr() 

		AFTER ROW
			#nothing

		AFTER DISPLAY
			#nothing
		
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E253")
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(FALSE) RETURNING l_arr_rec_offersale		

		ON ACTION ("ACCEPT","DOBULECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_offersale.getSize()) THEN
				IF l_arr_rec_offersale[l_idx].offer_code IS NOT NULL THEN 
					CALL off_turnover(glob_rec_kandoouser.cmpy_code, l_arr_rec_offersale[l_idx].offer_code) 
				END IF
			END IF 

	END DISPLAY

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_offersale()
###########################################################################


###########################################################################
# FUNCTION off_turnover(p_cmpy,p_rec_offer_code)
#
# 
###########################################################################
FUNCTION off_turnover(p_cmpy,p_rec_offer_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_offer_code LIKE offersale.offer_code 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statoffer RECORD LIKE statoffer.* ## CURRENT year 
	DEFINE pa_statoffer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		start_date LIKE statint.start_date, 
		gross_amt LIKE statoffer.gross_amt, 
		net_amt LIKE statoffer.net_amt, 
		profit_amt LIKE statoffer.gross_amt, 
		disc_per FLOAT, 
		offers_num LIKE statoffer.offers_num 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[1] OF RECORD 
		tot_gross_amt LIKE statoffer.gross_amt, 
		tot_net_amt LIKE statoffer.net_amt, 
		tot_profit_amt LIKE statoffer.gross_amt, 
		tot_disc_per FLOAT, 
		tot_offers_num LIKE statoffer.offers_num 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36
	 
	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	SELECT * INTO l_rec_offersale.* 
	FROM offersale 
	WHERE cmpy_code = p_cmpy 
	AND offer_code = p_rec_offer_code 

	IF status = 0 THEN 
		OPEN WINDOW E256 with FORM "E256" 
		 CALL windecoration_e("E256") 
 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 

			DISPLAY BY NAME 
				l_rec_offersale.offer_code, 
				l_rec_offersale.desc_text, 
				l_rec_offersale.start_date, 
				l_rec_offersale.end_date 

			LET l_arr_rec_stattotal[1].tot_gross_amt = 0 
			LET l_arr_rec_stattotal[1].tot_net_amt = 0 
			LET l_arr_rec_stattotal[1].tot_disc_per = 0 
			LET l_arr_rec_stattotal[1].tot_profit_amt = 0 
			LET l_arr_rec_stattotal[1].tot_offers_num = 0 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy 
			AND type_code = l_rec_statparms.week_type_code 
			AND end_date >= l_rec_offersale.start_date 
			AND start_date <= l_rec_offersale.end_date 
			ORDER BY 1,2,3,4 

			LET l_idx = 0 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET pa_statoffer[l_idx].int_text = l_rec_statint.int_text 
				LET pa_statoffer[l_idx].start_date = l_rec_statint.start_date 

				## obtain gross,net AND disc%
				SELECT 
					sum(gross_amt),
					sum(net_amt),
					sum(cost_amt),
					sum(offers_num) 
				INTO 
					l_rec_cur_statoffer.gross_amt,
					l_rec_cur_statoffer.net_amt, 
					l_rec_cur_statoffer.cost_amt,
					l_rec_cur_statoffer.offers_num 
				FROM statoffer 
				WHERE cmpy_code = p_cmpy 
				AND offer_code = p_rec_offer_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 

				IF l_rec_cur_statoffer.gross_amt IS NULL THEN 
					LET l_rec_cur_statoffer.gross_amt = 0 
				END IF 
				IF l_rec_cur_statoffer.net_amt IS NULL THEN 
					LET l_rec_cur_statoffer.net_amt = 0 
				END IF 
				IF l_rec_cur_statoffer.cost_amt IS NULL THEN 
					LET l_rec_cur_statoffer.cost_amt = 0 
				END IF 
				IF l_rec_cur_statoffer.offers_num IS NULL THEN 
					LET l_rec_cur_statoffer.offers_num = 0 
				END IF 

				LET pa_statoffer[l_idx].gross_amt = l_rec_cur_statoffer.gross_amt 
				LET pa_statoffer[l_idx].net_amt = l_rec_cur_statoffer.net_amt 
				LET pa_statoffer[l_idx].offers_num = l_rec_cur_statoffer.offers_num 

				IF pa_statoffer[l_idx].gross_amt = 0 THEN 
					LET pa_statoffer[l_idx].disc_per = 0 
				ELSE 
					LET pa_statoffer[l_idx].disc_per = 
						100 * (1-(pa_statoffer[l_idx].net_amt/pa_statoffer[l_idx].gross_amt)) 
				END IF 
				LET pa_statoffer[l_idx].profit_amt = l_rec_cur_statoffer.net_amt	- l_rec_cur_statoffer.cost_amt 

				## increment totals
				LET l_arr_rec_stattotal[1].tot_gross_amt = l_arr_rec_stattotal[1].tot_gross_amt	+ l_rec_cur_statoffer.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statoffer.net_amt 
				LET l_arr_rec_stattotal[1].tot_profit_amt = l_arr_rec_stattotal[1].tot_profit_amt	+ pa_statoffer[l_idx].profit_amt 
				LET l_arr_rec_stattotal[1].tot_offers_num = l_arr_rec_stattotal[1].tot_offers_num	+ l_rec_cur_statoffer.offers_num 
			END FOREACH
			 
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")				#7086 No statistical information exists FOR this selection "
			ELSE 

				# calc total current year disc%
				IF l_arr_rec_stattotal[1].tot_gross_amt = 0 THEN 
					LET l_arr_rec_stattotal[1].tot_disc_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[1].tot_disc_per = 100	* (1-(l_arr_rec_stattotal[1].tot_net_amt / l_arr_rec_stattotal[1].tot_gross_amt)) 
				END IF 
				
				DISPLAY l_arr_rec_stattotal[1].* TO sr_stattotal[1].* 

				MESSAGE kandoomsg2("E",1149,"") 	#1149 " Special Offer Profit Figures - F3/F4
				DISPLAY ARRAY pa_statoffer TO sr_statoffer.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","E65","input-arr-pa_statoffer-1") 

					ON ACTION "WEB-HELP"
						CALL onlinehelp(getmoduleid(),NULL) 
			
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar()

					BEFORE ROW 
						LET l_idx = arr_curr() 

				END DISPLAY
				 
			END IF 
			EXIT WHILE
			 
		END WHILE 
		
		CLOSE WINDOW E256 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION off_turnover(p_cmpy,p_rec_offer_code)
###########################################################################