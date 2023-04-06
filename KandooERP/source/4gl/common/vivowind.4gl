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

	Source code beautified by beautify.pl on 2020-01-02 10:35:39	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file

#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#############################################################
# FUNCTION vinq_vouc(p_cmpy_code,p_vend_code)
#
# \brief module - vivowind.4gl Displays outstanding voucher details
#############################################################
FUNCTION vinq_vouc(p_cmpy_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF #array[200] OF 
	RECORD 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		hold_code LIKE voucher.hold_code 
	END RECORD 
	DEFINE l_query_text CHAR(2048) 
	DEFINE l_where_text CHAR(2200) 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014 Logic Error: Vendor NOT found
		RETURN 
	END IF 
	DISPLAY BY NAME l_rec_vendor.vend_code, 
	l_rec_vendor.name_text 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute (green) 
	LET l_msgresp=kandoomsg("P",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON vouch_code, 
	inv_text, 
	vouch_date, 
	year_num, 
	period_num, 
	total_amt, 
	paid_amt, 
	hold_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","vivowind","construct-voucher") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN 
	END IF 

	LET l_query_text = "SELECT * FROM voucher ", 
	"WHERE cmpy_code = \"",p_cmpy_code,"\" ", 
	"AND vend_code = \"",l_rec_vendor.vend_code,"\" ", 
	"AND total_amt != paid_amt ", 
	"AND ",l_where_text CLIPPED," ", 
	"ORDER BY vouch_code" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	LET l_idx = 0 
	FOREACH c_voucher INTO l_rec_voucher.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_rec_voucher[l_idx].inv_text = l_rec_voucher.inv_text 
		LET l_arr_rec_voucher[l_idx].vouch_date = l_rec_voucher.vouch_date 
		LET l_arr_rec_voucher[l_idx].year_num = l_rec_voucher.year_num 
		LET l_arr_rec_voucher[l_idx].period_num = l_rec_voucher.period_num 
		LET l_arr_rec_voucher[l_idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_rec_voucher[l_idx].paid_amt = l_rec_voucher.paid_amt 
		LET l_arr_rec_voucher[l_idx].hold_code = l_rec_voucher.hold_code 
		#      IF l_idx = 200 THEN
		#         LET l_msgresp=kandoomsg("P",9006,l_idx)
		#         #9006 First 200 Vouchers Selected"
		#         EXIT FOREACH
		#      END IF
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp=kandoomsg("P",9007,"") 
		#9007 No Vouchers Selected
		SLEEP 2 
		RETURN 
	END IF 
	CALL set_count(l_idx) 
	LET l_msgresp=kandoomsg("P",1034,"") 

	#1034 RETURN on line TO SELECT - ESC TO Continue"
	INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","vivowind","input-arr-voucher") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_voucher.vouch_code = l_arr_rec_voucher[l_idx].vouch_code 
			LET l_rec_voucher.inv_text = l_arr_rec_voucher[l_idx].inv_text 
			LET l_rec_voucher.vouch_date = l_arr_rec_voucher[l_idx].vouch_date 
			LET l_rec_voucher.year_num = l_arr_rec_voucher[l_idx].year_num 
			LET l_rec_voucher.period_num = l_arr_rec_voucher[l_idx].period_num 
			LET l_rec_voucher.total_amt = l_arr_rec_voucher[l_idx].total_amt 
			LET l_rec_voucher.paid_amt = l_arr_rec_voucher[l_idx].paid_amt 
			LET l_rec_voucher.hold_code = l_arr_rec_voucher[l_idx].hold_code 
			IF l_idx > arr_count() THEN 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#9001 There are no more rows in the direction you are going"
				#ELSE
				#   DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*

			END IF 

		ON ACTION ("EDIT","DoubleClick") 
			LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code 
			CALL display_voucher_header(p_cmpy_code, l_rec_voucher.vouch_code ) 
			NEXT FIELD vouch_code 


		AFTER FIELD vouch_code 
			LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code 

		BEFORE FIELD inv_text 
			CALL display_voucher_header(p_cmpy_code, l_rec_voucher.vouch_code ) 
			NEXT FIELD vouch_code 

			#AFTER ROW
			#   DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*



	END INPUT 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 


