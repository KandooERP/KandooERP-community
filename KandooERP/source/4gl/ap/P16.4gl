# Vendor Maintenance P104 -Full EDIT
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:18	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 
#GLOBALS "P11a.4gl"


############################################################
# MAIN
#
# Purpose - Maintains vendor credit information
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("P16") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p104 with FORM "P104" 
	CALL windecoration_p("P104") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_vendor_get_count() > 1000 THEN 
		LET l_withquery = true 
	END IF 

	WHILE select_vendor(l_withquery) 
		LET l_withquery = scan_vendor() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW p104 
END MAIN 


############################################################
# FUNCTION select_vendor()
#
#
############################################################
FUNCTION select_vendor(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter criteria FOR selection
		WHENEVER ERROR CONTINUE 

		CONSTRUCT BY NAME l_where_text ON vend_code, 
		limit_amt, 
		bal_amt, 
		onorder_amt, 
		currency_code, 
		avg_day_paid_num, 
		hold_code 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P16","construct-vendor-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (vend_code) 
				LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,null) 
				DISPLAY BY NAME glob_rec_vendor.vend_code 
				NEXT FIELD limit_amt 


		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	WHENEVER ERROR stop 


	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Seraching database - please wait
	LET l_query_text = "SELECT * FROM vendor ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped, 
	"ORDER BY vend_code " 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 

	RETURN 1 

END FUNCTION 


############################################################
# FUNCTION scan_vendor()
#
#
############################################################
FUNCTION scan_vendor() 
	DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF 
	RECORD --huho changed FROM [250] 
		vend_code LIKE vendor.vend_code, 
		limit_amt LIKE vendor.limit_amt, 
		bal_amt LIKE vendor.bal_amt, 
		onorder_amt LIKE vendor.onorder_amt, 
		currency_code LIKE vendor.currency_code, 
		avg_day_paid_num LIKE vendor.avg_day_paid_num, 
		hold_code LIKE vendor.hold_code 
	END RECORD 
	DEFINE l_idx SMALLINT --index FOR l_arr_rec_vendor --scrn 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_process_status BOOLEAN

	LET l_idx = 0 

	CALL l_arr_rec_vendor.clear() 
	FOREACH c_vendor INTO glob_rec_vendor.* 
		LET l_idx = l_idx + 1 
		CALL l_arr_rec_vendor.append([glob_rec_vendor.vend_code,glob_rec_vendor.limit_amt,glob_rec_vendor.bal_amt,glob_rec_vendor.onorder_amt,glob_rec_vendor.currency_code,glob_rec_vendor.avg_day_paid_num,glob_rec_vendor.hold_code]) 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("U",9101,"") 
		#9101 No entries satisfied selection criteria"
		LET l_idx = 1 
	END IF 

	LET l_msgresp = kandoomsg("P",1044,"") 

	#1044  RETURN on line TO change
	DISPLAY ARRAY l_arr_rec_vendor TO sr_vendor.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P16","inp-arr-vendor-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "ACCEPT" 
			IF l_arr_rec_vendor[l_idx].vend_code IS NOT NULL THEN 
				OPEN WINDOW p176 with FORM "P176" 
				CALL windecoration_p("P176") 
				CALL process_vendor("P16",MODE_CLASSIC_EDIT,l_arr_rec_vendor[l_idx].vend_code) 
				RETURNING l_process_status 
				IF l_process_status THEN
					LET l_arr_rec_vendor[l_idx].limit_amt = glob_rec_vendor.limit_amt 
					LET l_arr_rec_vendor[l_idx].bal_amt = glob_rec_vendor.bal_amt 
					LET l_arr_rec_vendor[l_idx].onorder_amt = glob_rec_vendor.onorder_amt 
					LET l_arr_rec_vendor[l_idx].currency_code = glob_rec_vendor.currency_code 
					LET l_arr_rec_vendor[l_idx].avg_day_paid_num = glob_rec_vendor.avg_day_paid_num 
					LET l_arr_rec_vendor[l_idx].hold_code = glob_rec_vendor.hold_code 
				END IF 
				CLOSE WINDOW p176 
			END IF 


	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	END IF 

END FUNCTION 
