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
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E72_GLOBALS.4gl"
###########################################################################
# FUNCTION E72_main()
#
# E72 - Inquiry program FOR Sales Conditions
###########################################################################
FUNCTION E72_main() 
	DEFER QUIT 
	DEFER INTERRUPT
	
	CALL setModuleId("E72") 

	LET glob_yes_flag = xlate_from("Y") 
	LET glob_no_flag = xlate_from("N")
	 
	OPEN WINDOW E131 with FORM "E131" 
	 CALL windecoration_e("E131") 
 
	CALL scan_condsale() 
	 
	CLOSE WINDOW E131
	 
END FUNCTION 
###########################################################################
# END FUNCTION E72_main()
###########################################################################


###########################################################################
# FUNCTION db_condsale_get_datasource() 
#
#
###########################################################################
FUNCTION db_condsale_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1), 
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		tier_disc_flag LIKE condsale.tier_disc_flag 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 	#" Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cond_code, 
			desc_text, 
			prodline_disc_flag, 
			tier_disc_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E72","construct-cond_code-1") -- albo kd-502 
	
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
	
	MESSAGE kandoomsg2("E",1002,"") 	#MESSAGE " Searching database - please wait "

	LET l_query_text = "SELECT * FROM condsale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY cond_code" 
	PREPARE s_condsale FROM l_query_text 
	DECLARE c_condsale cursor FOR s_condsale 

	LET l_idx = 0 
	FOREACH c_condsale INTO l_rec_condsale.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_condsale[l_idx].scroll_flag = NULL 
		LET l_arr_rec_condsale[l_idx].cond_code = l_rec_condsale.cond_code 
		LET l_arr_rec_condsale[l_idx].desc_text = l_rec_condsale.desc_text 
		LET l_arr_rec_condsale[l_idx].tier_disc_flag = l_rec_condsale.tier_disc_flag 
		LET l_arr_rec_condsale[l_idx].prodline_disc_flag = l_rec_condsale.prodline_disc_flag 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 
	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected

 	RETURN l_arr_rec_condsale
END FUNCTION 
###########################################################################
# END FUNCTION db_condsale_get_datasource() 
###########################################################################


###########################################################################
# FUNCTION scan_condsale() 
#
#
###########################################################################
FUNCTION scan_condsale() 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1), 
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		tier_disc_flag LIKE condsale.tier_disc_flag 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale
	MESSAGE kandoomsg2("E",1007,"") #1007 F3/F4 TO PAge - RETURN on line TO View
	DISPLAY ARRAY l_arr_rec_condsale TO l_arr_rec_condsale.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E72","input-arr-l_arr_rec_condsale-1") -- albo kd-502 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_condsale.getSize())

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_condsale.clear()
			CALL db_condsale_get_datasource(TRUE) RETURNING l_arr_rec_condsale		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E131") 
			CALL l_arr_rec_condsale.clear()
			CALL db_condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale		
			
		BEFORE ROW 
			LET l_idx = arr_curr() 
	
		ON ACTION ("ACCEPT","DOUBLECLICK") --	BEFORE FIELD cond_code 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_condsale.getSize()) THEN

				SELECT * INTO l_rec_condsale.* 
				FROM condsale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cond_code = l_arr_rec_condsale[l_idx].cond_code 
				
				IF status = NOTFOUND THEN 
					IF l_arr_rec_condsale[l_idx].cond_code IS NOT NULL THEN 
						ERROR kandoomsg2("E",7011,l_arr_rec_condsale[l_idx].cond_code)	#7011 sales condition ??? has been deleted"
					END IF 
	
				ELSE 
	
					OPEN WINDOW E132 with FORM "E132" 
					 CALL windecoration_e("E132") -- albo kd-755
	 
					DISPLAY BY NAME 
						l_rec_condsale.cond_code, 
						l_rec_condsale.desc_text, 
						l_rec_condsale.scheme_amt 
	
					MENU " inquiry" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","E72","menu-Inquiry-1") -- albo kd-502
	
							SHOW option all 
							IF l_rec_condsale.tier_disc_flag = "N" THEN 
								HIDE option "Tiered" 
							END IF 
							IF l_rec_condsale.prodline_disc_flag = "N" THEN 
								HIDE option "Line" 
							END IF 
	 
						ON ACTION "WEB-HELP" -- albo kd-370 
							CALL onlinehelp(getmoduleid(),null)
	
						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 
										 
						COMMAND "Tiered"			" Inquiry on sales condition discount lines " 
							CALL lineitem_scan(l_rec_condsale.cond_code) 
	
						COMMAND "Line"	" Inquiry on product discount lines " 
							CALL proddisc_scan(glob_rec_kandoouser.cmpy_code,l_rec_condsale.cond_code) 
	
						COMMAND "Customer"		" Inquiry on customers assigned this sales condition" 
							CALL scan_customer(glob_rec_kandoouser.cmpy_code,l_rec_condsale.cond_code) 
	
						ON ACTION "CANCEL" --COMMAND KEY("E",INTERRUPT)"Exit" " RETURN TO scan screen" 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							EXIT MENU 
	
					END MENU 
					CLOSE WINDOW E132 
				END IF 
				 
			END IF
			 
--		AFTER ROW 
--			DISPLAY l_arr_rec_condsale[l_idx].* TO sr_condsale[scrn].* 
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
			
END FUNCTION 
###########################################################################
# END FUNCTION scan_condsale() 
###########################################################################


###########################################################################
# FUNCTION lineitem_scan(p_cond_code) 
#
#
###########################################################################
FUNCTION lineitem_scan(p_cond_code) 
	DEFINE p_cond_code LIKE condsale.cond_code 
	DEFINE l_arr_rec_conddisc array[30] OF RECORD 
		scroll_flag char(1), 
		reqd_amt LIKE conddisc.reqd_amt, 
		bonus_check_per LIKE conddisc.bonus_check_per, 
		disc_check_per LIKE conddisc.disc_check_per, 
		disc_per LIKE conddisc.disc_per 
	END RECORD 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW E136 with FORM "E136" 
	 CALL windecoration_e("E136") -- albo kd-755 

	DECLARE c2_conddisc cursor FOR 
	SELECT "", 
	reqd_amt, 
	bonus_check_per, 
	disc_check_per, 
	disc_per 
	FROM conddisc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cond_code = p_cond_code 
	ORDER BY reqd_amt 

	LET l_idx = 1 
	FOREACH c2_conddisc INTO l_arr_rec_conddisc[l_idx].* 
		IF l_idx = 30 THEN 
			EXIT FOREACH 
		ELSE 
			LET l_idx = l_idx + 1 
		END IF 
	END FOREACH 

	MESSAGE kandoomsg2("E",1008,"")  #1008 F3/F4 TO Page Fwd/Bwd - ESC TO Continue
	DISPLAY ARRAY l_arr_rec_conddisc TO sr_conddisc.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E72","display-arr-conddisc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	LET quit_flag = FALSE 
	LET int_flag = FALSE 
	CLOSE WINDOW E136
	 
END FUNCTION 
###########################################################################
# END FUNCTION lineitem_scan(p_cond_code) 
###########################################################################