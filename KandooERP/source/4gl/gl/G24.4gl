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

# \brief module G24 scans FOR batches out of balance

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###########################################################################
# MAIN
#
# module G24 scans FOR batches out of balance
###########################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("G24") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	IF NOT get_gl_setup_state() THEN 
		LET l_msgresp = kandoomsg("G",5007,"")	#5007 " General Ledger Parameters Not Set Up"
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW G464 with FORM "G464" 
	CALL windecoration_g("G464") 

	CALL scan_jour() 

	CLOSE WINDOW G464 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION select_jour()
#
#
###########################################################################
FUNCTION get_batchhead_g24_datasource(p_filter) --select_jour() 
	DEFINE p_filter boolean 
	DEFINE l_where_text STRING 
	DEFINE l_query_text char(980) 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_with_scrollflag 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("G",1001,"")		#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_text ON 
			jour_code, 
			jour_num, 
			jour_date, 
			year_num, 
			period_num, 
			for_debit_amt, 
			for_credit_amt, 
			currency_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G24","construct-jour") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("G",1002,"")	#1002 " Searching database - please wait "
	IF glob_rec_glparms.control_tot_flag = "Y" THEN 
		LET l_where_text = 
			l_where_text clipped, 
			" AND (debit_amt != credit_amt or", 
			" debit_amt != control_amt or", 
			" stats_qty != control_qty)" 
	ELSE 
		LET l_where_text = 
			l_where_text clipped, 
			" AND debit_amt != credit_amt" 
	END IF 

	LET l_query_text = 
		"SELECT * FROM batchhead ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND post_flag='N' ", 
		"AND source_ind='G' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY jour_code,jour_num" 
	PREPARE s_batchhead FROM l_query_text 
	DECLARE c_batchhead CURSOR FOR s_batchhead 

	LET l_idx = 0 
	FOREACH c_batchhead INTO l_rec_batchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_batchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_batchhead[l_idx].jour_code = l_rec_batchhead.jour_code 
		LET l_arr_rec_batchhead[l_idx].jour_num = l_rec_batchhead.jour_num 
		LET l_arr_rec_batchhead[l_idx].jour_date = l_rec_batchhead.jour_date 
		LET l_arr_rec_batchhead[l_idx].year_num = l_rec_batchhead.year_num 
		LET l_arr_rec_batchhead[l_idx].period_num = l_rec_batchhead.period_num 
		LET l_arr_rec_batchhead[l_idx].for_debit_amt = l_rec_batchhead.for_debit_amt 
		LET l_arr_rec_batchhead[l_idx].for_credit_amt = l_rec_batchhead.for_credit_amt 
		LET l_arr_rec_batchhead[l_idx].currency_code = l_rec_batchhead.currency_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("G",9043,"")		#9036 No Journal Selected
		SLEEP 2
	END IF 

	RETURN l_arr_rec_batchhead 
END FUNCTION 
###########################################################################
# END FUNCTION select_jour()
###########################################################################


############################################################
# FUNCTION scan_jour()
#
#
############################################################
FUNCTION scan_jour() 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_with_scrollflag 
	--	RECORD -- array[200] OF RECORD
	--			scroll_flag char(1),
	--			jour_code LIKE batchhead.jour_code,
	--			jour_num LIKE batchhead.jour_num,
	--			jour_date LIKE batchhead.jour_date,
	--			year_num LIKE batchhead.year_num,
	--			period_num LIKE batchhead.period_num,
	--			for_debit_amt LIKE batchhead.for_debit_amt,
	--			for_credit_amt LIKE batchhead.for_credit_amt,
	--			currency_code LIKE batchhead.currency_code
	--		END RECORD
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF db_batchhead_get_count_post_flag_source_ind("N","G") < get_settings_maxListArraySizeSwitch() THEN
		CALL get_batchhead_g24_datasource(FALSE) RETURNING l_arr_rec_batchhead
	ELSE
		CALL get_batchhead_g24_datasource(TRUE) RETURNING l_arr_rec_batchhead
	END IF 

	MESSAGE kandoomsg2("G",1043,l_idx) #1021 Journal - RETURN TO View"
	DISPLAY ARRAY l_arr_rec_batchhead TO sr_batchhead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G24","input-arr-batchhead") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
 			CALL dialog.setActionHidden("DETAIL",NOT l_arr_rec_batchhead.getSize())
 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_batchhead.clear()
			CALL get_batchhead_g24_datasource(TRUE) RETURNING l_arr_rec_batchhead 

		ON ACTION "REFRESH"
			CALL windecoration_g("G464") 
			CALL l_arr_rec_batchhead.clear()
			CALL get_batchhead_g24_datasource(FALSE) RETURNING l_arr_rec_batchhead 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("DETAIL","DOUBLECLICK","ACCEPT") #was BEFORE FIELD jour_code 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_batchhead.getSize()) THEN
				OPEN WINDOW G109 with FORM "G109" 
				CALL windecoration_g("G109") 
	
				CALL disp_journal(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchhead[l_idx].jour_num) 
				LET l_msgresp = kandoomsg("G",8015,"")			#8015 " View batch details (y/n) ?"
	
				IF l_msgresp = "Y"	OR l_msgresp = "y" THEN 
					CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, l_arr_rec_batchhead[l_idx].jour_num) 
				END IF 
				CLOSE WINDOW G109
				 
				CALL get_batchhead_g24_datasource(FALSE) RETURNING l_arr_rec_batchhead
			END IF
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
############################################################
# END FUNCTION scan_jour()
############################################################