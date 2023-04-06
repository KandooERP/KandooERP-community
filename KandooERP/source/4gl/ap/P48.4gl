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

	Source code beautified by beautify.pl on 2020-01-03 13:41:30	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P48  Allows the user TO view cheques by number

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 

############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P48") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp134 with FORM "P134" 
	CALL windecoration_p("P134") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE get_check() 
	END WHILE 
	CLOSE WINDOW wp134 
END MAIN 


FUNCTION get_check() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_arr_cheque ARRAY[500] OF RECORD 
		cmpy_code LIKE cheque.cmpy_code, 
		vend_code LIKE cheque.vend_code, 
		bank_code LIKE cheque.bank_code,
		cheq_code LIKE cheque.cheq_code 
	END RECORD 
	DEFINE l_arr_check ARRAY[500] OF RECORD 
		cheq_code LIKE cheque.cheq_code, 
		name_text LIKE vendor.name_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		post_flag LIKE cheque.post_flag 
	END RECORD 
	DEFINE l_sel_text CHAR(2200) 
	DEFINE l_where_part CHAR(2048)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT

	CLEAR FORM 
	LET l_msgresp = kandoomsg("P", 1001, "") 
	#1001 Enter SELECT criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_part ON cheque.cheq_code, 
	vendor.name_text, 
	cheque.cheq_date, 
	cheque.pay_amt, 
	cheque.pay_meth_ind, 
	cheque.post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P48","construct-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN FALSE 
	END IF 
	LET l_sel_text = "SELECT cheque.* FROM cheque, vendor ", 
	"WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cheque.cheq_code != 0 ", 
	"AND cheque.cheq_code IS NOT NULL ", 
	"AND vendor.vend_code = cheque.vend_code ", 
	"AND ", l_where_part clipped, " ", 
	"ORDER BY pay_meth_ind,cheq_code " 

	PREPARE getcheck FROM l_sel_text 
	DECLARE chechcurs CURSOR FOR getcheck 
	LET idx = 0 
	FOREACH chechcurs INTO l_rec_cheque.* 
		LET idx = idx + 1 
		LET l_arr_cheque[idx].cmpy_code = l_rec_cheque.cmpy_code 
		LET l_arr_cheque[idx].vend_code = l_rec_cheque.vend_code 
		LET l_arr_cheque[idx].bank_code = l_rec_cheque.bank_code 
		LET l_arr_cheque[idx].cheq_code = l_rec_cheque.cheq_code 
		LET l_arr_check[idx].cheq_code = l_rec_cheque.cheq_code 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE vend_code = l_rec_cheque.vend_code 
		AND cmpy_code = l_rec_cheque.cmpy_code 
		LET l_arr_check[idx].name_text = l_rec_vendor.name_text 
		LET l_arr_check[idx].cheq_date = l_rec_cheque.cheq_date 
		LET l_arr_check[idx].pay_amt = l_rec_cheque.pay_amt 
		LET l_arr_check[idx].pay_meth_ind = l_rec_cheque.pay_meth_ind 
		LET l_arr_check[idx].post_flag = l_rec_cheque.post_flag 
		IF idx = 500 THEN 
			LET l_msgresp = kandoomsg("P", 9042, idx) 
			#9042 First 500 entries selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (idx) 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("P", 9044, "") 
		#9044 No entries satisfied selection criteria
		RETURN TRUE 
	END IF 
	LET l_msgresp = kandoomsg("P", 1007, "") 
	#1007 RETURN on line TO View
	OPTIONS INSERT KEY f36 
	OPTIONS DELETE KEY f36 

	INPUT ARRAY l_arr_check WITHOUT DEFAULTS FROM sr_cheque.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P48","inp-arr-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD name_text 
			IF l_arr_cheque[idx].cheq_code IS NULL 
			OR l_arr_cheque[idx].cheq_code = 0 THEN 
			ELSE 
				CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
				l_arr_cheque[idx].vend_code, 
				l_arr_cheque[idx].cheq_code, 
				l_arr_check[idx].pay_meth_ind, 
				l_arr_cheque[idx].bank_code, 
				0) 
			END IF 
			NEXT FIELD cheq_code 

	END INPUT 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN TRUE 
END FUNCTION 


