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
# FUNCTION disp_splits( p_cmpy_code, p_vend_code, p_vouch_num)
#
# FUNCTION disp_split allows the user TO view voucher splits
####################################################################
FUNCTION disp_splits( p_cmpy_code,p_vend_code,p_vouch_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_voucher array[100] OF 
	RECORD 
		vend_code LIKE voucher.vend_code, 
		vouch_code LIKE voucher.vouch_code, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		approved_by_code LIKE voucher.approved_by_code, 
		approved_date LIKE voucher.approved_date, 
		total_amt LIKE voucher.total_amt, 
		post_flag LIKE voucher.post_flag 
	END RECORD 
	DEFINE l_totaller MONEY(12,2) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor") 
		#7001 Logic Error: Vendor RECORD NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_voucher.* FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	AND vouch_code = p_vouch_num 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Voucher") 
		#7001 Logic Error: Voucher RECORD NOT found
		RETURN 
	END IF 

	CALL fgl_winmessage("HuHo Debug - Missing Form P156","Form P156 needs TO be created/fixed\nDebug this place AND adjust the form accordingly","error") 
	OPEN WINDOW wp156 with FORM "P156" 
	CALL windecoration_p("P156") 

	DISPLAY l_rec_voucher.vend_code, 
	l_rec_voucher.vouch_code 
	TO vend_code, 
	p_vouch_num 

	LET l_totaller = 0 
	DECLARE vouccurs CURSOR FOR 
	SELECT * INTO l_rec_voucher.* FROM voucher 
	WHERE cmpy_code = p_cmpy_code 
	AND split_from_num = l_rec_voucher.vouch_code 

	LET l_idx = 0 
	FOREACH vouccurs INTO l_rec_voucher.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_voucher[l_idx].vend_code = l_rec_voucher.vend_code 
		LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_rec_voucher[l_idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_rec_voucher[l_idx].year_num = l_rec_voucher.year_num 
		LET l_arr_rec_voucher[l_idx].period_num = l_rec_voucher.period_num 
		LET l_arr_rec_voucher[l_idx].post_flag = l_rec_voucher.post_flag 
		LET l_arr_rec_voucher[l_idx].approved_by_code = l_rec_voucher.approved_by_code 
		LET l_arr_rec_voucher[l_idx].approved_date = l_rec_voucher.approved_date 
		LET l_totaller = l_totaller + l_rec_voucher.total_amt 
	END FOREACH 
	CALL set_count(l_idx) 
	DISPLAY l_totaller TO total_amt 

	LET l_msgresp = kandoomsg("U",1008,"") 
	#1008 F3/F4 TO Page Fwd/Bwd; OK TO Continue.

	DISPLAY ARRAY l_arr_rec_voucher TO sr_voucher.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","vospwind","display-arr-voucher") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

	CLOSE WINDOW wp156 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 


