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
	Source code beautified by beautify.pl on 2020-01-03 13:41:19	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P26  Voucher Scan Screen & Inquiry
#                allows the user TO Scan Client Voucher
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P26") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p121 with FORM "P121" 
	CALL windecoration_p("P121") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE enter_vendor() 
		CALL scan_voucher() 
	END WHILE 
	CLOSE WINDOW p121 
END MAIN 


############################################################
# FUNCTION enter_vendor()
#
#
############################################################
FUNCTION enter_vendor() 
	DEFINE l_msgresp LIKE language.yes_flag 

	#P1016 " Enter Vendor Code FOR Required Vendor"
	LET l_msgresp=kandoomsg("P",1016,"")
	
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME glob_rec_vendor.vend_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P26","inp-vend_code-1") 
			DISPLAY db_vendor_get_name_text(UI_OFF,glob_rec_vendor.vend_code) TO vendor.name_text
			DISPLAY db_vendor_get_currency_code(UI_OFF,glob_rec_vendor.vend_code) TO vendor.currency_code

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code) 
			NEXT FIELD vend_code 

		ON CHANGE vend_code
			DISPLAY db_vendor_get_name_text(UI_OFF,glob_rec_vendor.vend_code) TO vendor.name_text
			DISPLAY db_vendor_get_currency_code(UI_OFF,glob_rec_vendor.vend_code) TO vendor.currency_code
			
		AFTER FIELD vend_code 
			SELECT * INTO glob_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_vendor.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("U",9105,"") 
				#U9105 " Vendor NOT found - Try Window"
				NEXT FIELD vend_code 
			END IF 

			DISPLAY db_vendor_get_name_text(UI_OFF,glob_rec_vendor.vend_code) TO vendor.name_text
			DISPLAY db_vendor_get_currency_code(UI_OFF,glob_rec_vendor.vend_code) TO vendor.currency_code

	END INPUT 
	OPTIONS INPUT WRAP
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 




############################################################
# FUNCTION scan_voucher()
#
#
############################################################
FUNCTION db_voucher_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_vo_it_vd_yn_pn_pf_ta_pa_with_scrollflag 
	DEFINE l_msgresp LIKE language.yes_flag 

	#internal exception check/handling
	IF glob_rec_vendor.vend_code IS NULL THEN 
		CALL fgl_winmessage("Environment Problem","Vendor is not initialised!","error") 
		EXIT PROGRAM 
	END IF 

	IF p_filter THEN 
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_vendor.vend_code, 
		glob_rec_vendor.name_text 

		DISPLAY BY NAME glob_rec_vendor.currency_code 
		attribute(green) 

		LET l_msgresp=kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON vouch_code, 
		inv_text, 
		vouch_date, 
		year_num, 
		period_num, 
		post_flag, 
		total_amt, 
		paid_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P26","construct-voucher-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp=kandoomsg("U",1002,"") 
	LET l_query_text = "SELECT * FROM voucher ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vend_code = '",glob_rec_vendor.vend_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY vouch_code" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	LET idx = 0 
	FOREACH c_voucher INTO l_rec_voucher.* 
		LET idx = idx + 1 
		LET l_arr_rec_voucher[idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_rec_voucher[idx].inv_text = l_rec_voucher.inv_text 
		LET l_arr_rec_voucher[idx].vouch_date = l_rec_voucher.vouch_date 
		LET l_arr_rec_voucher[idx].year_num = l_rec_voucher.year_num 
		LET l_arr_rec_voucher[idx].period_num = l_rec_voucher.period_num 
		LET l_arr_rec_voucher[idx].post_flag = l_rec_voucher.post_flag 
		LET l_arr_rec_voucher[idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_rec_voucher[idx].paid_amt = l_rec_voucher.paid_amt 
		#         IF idx = 200 THEN
		#            LET l_msgresp=kandoomsg("U",6100,idx)
		#            #U6100 "Only first 200 Vouchers Selected"
		#            EXIT FOREACH
		#         END IF
	END FOREACH 

	RETURN l_arr_rec_voucher 
END FUNCTION 

############################################################
# FUNCTION scan_voucher()
#
#
############################################################
FUNCTION scan_voucher() 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_vo_it_vd_yn_pn_pf_ta_pa_with_scrollflag 
	#	DEFINE l_arr_rec_voucher array[200] OF RECORD
	#		scroll_flag CHAR(1),
	#		vouch_code LIKE voucher.vouch_code,
	#		inv_text LIKE voucher.inv_text,
	#		vouch_date LIKE voucher.vouch_date,
	#		year_num LIKE voucher.year_num,
	#		period_num LIKE voucher.period_num,
	#		post_flag LIKE voucher.post_flag  ,
	#		total_amt LIKE voucher.total_amt,
	#		paid_amt LIKE voucher.paid_amt
	#		END RECORD
	DEFINE l_msgresp LIKE language.yes_flag 

	IF db_voucher_get_count_by_vendor(glob_rec_vendor.vend_code) > 1000 THEN 
		CALL db_voucher_filter_datasource(true) RETURNING l_arr_rec_voucher 
	ELSE 
		CALL db_voucher_filter_datasource(false) RETURNING l_arr_rec_voucher 
	END IF 

	---------------

	IF l_arr_rec_voucher.getlength() = 0 THEN 
		LET l_msgresp=kandoomsg("U",9101,"") 
		#U9101" No Vouchers Selected FOR this Criteria - Re SELECT"
	END IF 
	LET l_msgresp=kandoomsg("U",9113,idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp=kandoomsg("U",1007,"") 

	#P1007 " RETURN on line TO View - ESC TO Continue"
	#INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* ATTRIBUTE(unbuffered, append row=false, auto append=false, insert row =false,delete row = false)
	DISPLAY ARRAY l_arr_rec_voucher TO sr_voucher.* 
		BEFORE DISPLAY #input 
			CALL publish_toolbar("kandoo","P26","inp-arr-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_voucher_filter_datasource(true) RETURNING l_arr_rec_voucher 

		BEFORE ROW 
			LET idx = arr_curr() 
			#               LET scrn = scr_line()
			#               IF idx > arr_count() THEN
			#                  LET l_msgresp=kandoomsg("U",9001,"")
			#9001 "There are no more rows in the direction you are going"
			#               ELSE
			#                  DISPLAY l_arr_rec_voucher[idx].* TO sr_voucher[scrn].*
			#
			#               END IF
			#            AFTER FIELD scroll_flag
			#               IF  arr_curr() = arr_count()
			#               AND fgl_lastkey() = fgl_keyval("down") THEN
			#                  LET l_msgresp=kandoomsg("U",9001,"")
			#                  #9001 "There are no more rows ...
			#                  NEXT FIELD scroll_flag
			#               END IF

			#            BEFORE FIELD vouch_code
			#CASE arg_val(1)

		ON ACTION "DOUBLECLICK" 
			CASE get_url_voucher_option()  
				WHEN "P" 
					IF l_arr_rec_voucher[idx].paid_amt = 0 THEN 
						error" No payments exist FOR this transaction" 
					ELSE 
						CALL disp_vo_pay(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code, 
						l_arr_rec_voucher[idx].vouch_code) 
					END IF 
				WHEN "D" 
					CALL disp_dist_amt(glob_rec_kandoouser.cmpy_code,l_arr_rec_voucher[idx].vouch_code) 
				WHEN "T" 
					CALL disp_splits(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code, 
					l_arr_rec_voucher[idx].vouch_code) 
				OTHERWISE 
					CALL display_voucher_header( glob_rec_kandoouser.cmpy_code, l_arr_rec_voucher[idx].vouch_code ) 
			END CASE 
			#              NEXT FIELD scroll_flag
			#            AFTER ROW
			#               DISPLAY l_arr_rec_voucher[idx].* TO sr_voucher[scrn].*

	END DISPLAY #input 

	#      END IF

	#  END IF

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
