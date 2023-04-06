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

	Source code beautified by beautify.pl on 2020-01-02 10:35:40	$Id: $
}




############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


####################################################################
# FUNCTION disp_vo_pay(p_cmpy_code, p_vendor, p_vouch_num)
#
# FUNCTION disp_vo_pay allows the user TO view voucher payments applied
####################################################################
FUNCTION disp_vo_pay(p_cmpy_code,p_vendor,p_vouch_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vendor LIKE vendor.vend_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_bank DYNAMIC ARRAY OF #array[200] OF 
	RECORD 
		bank_code LIKE cheque.bank_code 
	END RECORD 
	DEFINE l_arr_rec_voucherpays DYNAMIC ARRAY OF #array[200] OF 
	RECORD 
		pay_type_code LIKE voucherpays.pay_type_code, 
		pay_date LIKE voucherpays.pay_date, 
		apply_num LIKE voucherpays.apply_num, 
		pay_num LIKE voucherpays.pay_num, 
		pay_meth_ind LIKE voucherpays.pay_meth_ind, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vendor 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor") 
		#7001 Vendor RECORD NOT found in database
		RETURN 
	END IF 

	#CALL fgl_winmessage("HuHo Debug - Missing Form P124","Form P124 needs TO be created/fixed\nDebug this place AND adjust the form accordingly","error")
	OPEN WINDOW p124 with FORM "P124" 
	CALL windecoration_p("P124") 

	DISPLAY BY NAME l_rec_vendor.name_text 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute (green) 
	SELECT * INTO l_rec_voucher.* FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vendor 
	AND vouch_code = p_vouch_num 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Voucher") 
		#7001 Voucher RECORD NOT found in database
		EXIT program 
	END IF 
	LET l_rec_voucherpays.vend_code = p_vendor 
	LET l_rec_voucherpays.vouch_code = p_vouch_num 
	DISPLAY BY NAME l_rec_voucher.due_date, 
	l_rec_voucherpays.vend_code, 
	l_rec_voucherpays.vouch_code, 
	l_rec_voucher.disc_date, 
	l_rec_voucher.total_amt, 
	l_rec_voucher.poss_disc_amt, 
	l_rec_voucher.paid_amt, 
	l_rec_voucher.taken_disc_amt 

	DECLARE vouccurs CURSOR FOR 
	SELECT * INTO l_rec_voucherpays.* FROM voucherpays 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_voucherpays.vend_code 
	AND vouch_code = l_rec_voucherpays.vouch_code 
	LET l_idx = 0 

	FOREACH vouccurs INTO l_rec_voucherpays.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_bank[l_idx].bank_code = l_rec_voucherpays.bank_code 
		LET l_arr_rec_voucherpays[l_idx].pay_type_code = l_rec_voucherpays.pay_type_code 
		LET l_arr_rec_voucherpays[l_idx].pay_num = l_rec_voucherpays.pay_num 
		LET l_arr_rec_voucherpays[l_idx].apply_num = l_rec_voucherpays.apply_num 
		LET l_arr_rec_voucherpays[l_idx].pay_date = l_rec_voucherpays.pay_date 
		LET l_arr_rec_voucherpays[l_idx].pay_meth_ind = l_rec_voucherpays.pay_meth_ind 
		LET l_arr_rec_voucherpays[l_idx].apply_amt = l_rec_voucherpays.apply_amt 
		LET l_arr_rec_voucherpays[l_idx].disc_amt = l_rec_voucherpays.disc_amt 
		IF l_idx = 195 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("P",1060,"") 
	#1060  Payment Detail - RETURN on line TO View

	INPUT ARRAY l_arr_rec_voucherpays WITHOUT DEFAULTS FROM sr_voucherpays.* attribute(UNBUFFERED, append ROW = FALSE, auto append = FALSE, DELETE ROW = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","vopawind","input-arr-voucherpays") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_voucherpays[l_idx].* TO sr_voucherpays[scrn].*

			### modif ericv init # AFTER FIELD pay_type_code
			#--#IF fgl_lastkey() = fgl_keyval("accept")
			#--#AND fgl_fglgui() THEN
			#--#   NEXT FIELD pay_date
			#--#END IF

		BEFORE FIELD pay_date 
			CASE (l_arr_rec_voucherpays[l_idx].pay_type_code) 
				WHEN "DB" 
					CALL disp_dm_head(p_cmpy_code, 
					l_arr_rec_voucherpays[l_idx].pay_num) 
				OTHERWISE 
					CALL disp_ck_head(p_cmpy_code, 
					p_vendor, 
					l_arr_rec_voucherpays[l_idx].pay_num, 
					l_arr_rec_voucherpays[l_idx].pay_meth_ind, 
					l_arr_rec_bank[l_idx].bank_code, 
					0) 
			END CASE 
			NEXT FIELD pay_type_code 

			#      AFTER ROW
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_voucherpays[l_idx+1].pay_type_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD pay_type_code
			#            END IF
			#         END IF
			#DISPLAY l_arr_rec_voucherpays[l_idx].* TO sr_voucherpays[scrn].*



	END INPUT 

	CLOSE WINDOW p124 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 


