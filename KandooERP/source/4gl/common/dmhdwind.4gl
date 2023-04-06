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

	Source code beautified by beautify.pl on 2020-01-02 10:35:11	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION disp_dm_head( p_cmpy_code, p_deb_num)
#
# FUNCTION disp_dm_head displays debit header details
############################################################
FUNCTION disp_dm_head(p_cmpy_code,p_deb_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_deb_num LIKE debithead.debit_num 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_debithead.* FROM debithead 
	WHERE debithead.debit_num = p_deb_num 
	AND debithead.cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Debit") 
		#7001 Logic Error:  Debit RECORD does NOT exist in database.
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vend_code = l_rec_debithead.vend_code 
	AND cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("P",9060,l_rec_debithead.vend_code) 
		#9060 Logic Error: Vendor XXX does NOT exist.
		RETURN 
	END IF 

	OPEN WINDOW p112 with FORM "P112" 
	CALL windecoration_p("P112") 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute (green) 
	DISPLAY BY NAME l_rec_debithead.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_debithead.debit_num, 
	l_rec_debithead.batch_num, 
	l_rec_debithead.dist_amt, 
	l_rec_debithead.total_amt, 
	l_rec_debithead.apply_amt, 
	l_rec_debithead.disc_amt, 
	l_rec_debithead.entry_code, 
	l_rec_debithead.entry_date, 
	l_rec_debithead.debit_text, 
	l_rec_debithead.debit_date, 
	l_rec_debithead.year_num, 
	l_rec_debithead.period_num, 
	l_rec_debithead.post_flag, 
	l_rec_debithead.jour_num, 
	l_rec_debithead.conv_qty, 
	l_rec_debithead.com1_text, 
	l_rec_debithead.com2_text 

	MENU " View Debit Details" 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","dmhdwind","imenu-view-debit-details") 
			IF l_rec_debithead.dist_amt <= 0 THEN 
				HIDE option "Distribution" 
			END IF 
			SELECT unique 1 
			FROM wholdtax 
			WHERE cmpy_code = p_cmpy_code 
			AND tax_vend_code = l_rec_debithead.vend_code 
			AND tax_tran_type = "2" 
			AND tax_ref_num = l_rec_debithead.debit_num 
			IF status = notfound THEN 
				HIDE option "Tax Trans" 
			END IF 

		COMMAND "Distribution" " View debit distributions" 
			CALL disp_debit_dis(p_cmpy_code, l_rec_debithead.debit_num) 

		COMMAND "Tax Trans" " View associated tax transactions" 
			CALL dispwtax(p_cmpy_code,l_rec_debithead.vend_code,"2",l_rec_debithead.debit_num) 
		COMMAND KEY(interrupt,"E") "Exit" " Exit this menu" 
			EXIT MENU 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END MENU 

	CLOSE WINDOW p112 

	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 


