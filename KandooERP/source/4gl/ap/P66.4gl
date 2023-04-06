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
# \brief module P66 allows the user TO edit Debits

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P66_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# MODULE Scope Variables
############################################################

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P66") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp113 with FORM "P113" 
	CALL windecoration_p("P113") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL create_table("debitdist","t_debitdist","","N") 
	WHILE get_vendor() 
		CALL scan_vendor() 
	END WHILE 
	CLOSE WINDOW wp113 
END MAIN 


FUNCTION get_vendor() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("P",1043,"") 

	#1043 Enter Vendor Information
	INPUT BY NAME glob_rec_vendor.vend_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P66","inp-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			IF infield (vend_code) THEN 
				LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code) 
				DISPLAY BY NAME glob_rec_vendor.vend_code 

				NEXT FIELD vend_code 
			END IF 
		AFTER FIELD vend_code 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_vendor.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9043,"") 
				#9043 Vendor NOT found - Try Window
				NEXT FIELD vend_code 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_vendor() 
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_arr_debithead ARRAY[200] OF RECORD 
	scroll_flag CHAR(1), 
	debit_num LIKE debithead.debit_num, 
	debit_text LIKE debithead.debit_text, 
	debit_date LIKE debithead.debit_date, 
	year_num LIKE debithead.year_num, 
	period_num LIKE debithead.period_num, 
	total_amt LIKE debithead.total_amt, 
	apply_amt LIKE debithead.apply_amt 
	END RECORD
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, cnt, scrn INTEGER

	DISPLAY BY NAME glob_rec_vendor.vend_code, 
	glob_rec_vendor.name_text 

	DISPLAY BY NAME glob_rec_vendor.currency_code 
	attribute (green) 
	LET l_msgresp=kandoomsg("P",1001,"") 
	#1001 Enter Selection criteria - ESC TO continue"
	CONSTRUCT BY NAME l_where_text ON debit_num, 
	debit_text, 
	debit_date, 
	year_num, 
	period_num, 
	total_amt, 
	apply_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P66","construct-debit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_query_text = "SELECT debithead.* FROM debithead ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vend_code = \"",glob_rec_vendor.vend_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY debit_num" 
	PREPARE s_debithead FROM l_query_text 
	DECLARE c_debithead CURSOR FOR s_debithead 
	LET idx = 0 
	FOREACH c_debithead INTO l_rec_debithead.* 
		LET idx = idx + 1 
		LET l_arr_debithead[idx].scroll_flag = NULL 
		LET l_arr_debithead[idx].debit_num = l_rec_debithead.debit_num 
		LET l_arr_debithead[idx].debit_text = l_rec_debithead.debit_text 
		LET l_arr_debithead[idx].debit_date = l_rec_debithead.debit_date 
		LET l_arr_debithead[idx].year_num = l_rec_debithead.year_num 
		LET l_arr_debithead[idx].period_num = l_rec_debithead.period_num 
		LET l_arr_debithead[idx].total_amt = l_rec_debithead.total_amt 
		LET l_arr_debithead[idx].apply_amt = l_rec_debithead.apply_amt 
		IF idx = 200 THEN 
			LET l_msgresp=kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	CALL set_count (idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET l_msgresp=kandoomsg("P",1007,idx) 
	#1007 F3/F4 - RETURN on line TO Edit
	INPUT ARRAY l_arr_debithead WITHOUT DEFAULTS FROM sr_debithead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P66","inp-arr-debithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_scroll_flag = l_arr_debithead[idx].scroll_flag 
			DISPLAY l_arr_debithead[idx].* 
			TO sr_debithead[scrn].* 

		AFTER FIELD scroll_flag 
			LET l_arr_debithead[idx].scroll_flag = l_scroll_flag 
			DISPLAY l_arr_debithead[idx].scroll_flag 
			TO sr_debithead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_debithead[idx+1].debit_num IS NULL THEN 
						LET l_msgresp=kandoomsg("G",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD debit_num 
			CALL disp_dm_head(glob_rec_kandoouser.cmpy_code, l_arr_debithead[idx].debit_num) 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_debithead[idx].* TO sr_debithead[scrn].* 

	END INPUT 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 


