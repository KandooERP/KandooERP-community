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

	Source code beautified by beautify.pl on 2020-01-03 13:41:32	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P6_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	#pr_apparms RECORD LIKE apparms.*,
	pr_ctl_linetotal, 
	pr_bat_linetotal SMALLINT, 
	pr_bat_amttotal, 
	pr_ctl_amttotal LIKE debithead.total_amt 
END GLOBALS 

#another one! see P21b.4gl
#FUNCTION my_menu(p_cmpy, p_kandoouser_sign_on_code, pr_voucher, pr_vouchpayee, pr_update_ind)
FUNCTION my_menu(p_cmpy, p_kandoouser_sign_on_code, pr_debithead, pr_update_ind) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	pr_debithead RECORD LIKE debithead.*, 
	pr_dist_amt LIKE voucher.dist_amt, 
	pr_exit_flag, pr_bal_flag, pr_update_ind CHAR(1) 
	DEFINE msgresp LIKE language.yes_flag 

	IF pr_debithead.vend_code IS NOT NULL THEN 


		MENU " Debits" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","P64a","menu-debits-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			COMMAND "Save" " Save new debit TO database" 
				LET pr_debithead.debit_num = 
				update_debit(p_cmpy,p_kandoouser_sign_on_code,pr_update_ind,pr_debithead.*) 
				IF pr_debithead.debit_num = 0 THEN 
					LET msgresp=kandoomsg("P",7022,"") 
					#7022 Errors occurred during debit add.
				ELSE 
					LET msgresp=kandoomsg("P",7021,pr_debithead.debit_num) 
					#7021 Debit successfully created.
				END IF 
				EXIT MENU 
			COMMAND "Distribution" " Enter account distribution FOR this debit" 
				OPEN WINDOW wp170 with FORM "P170" 
				CALL windecoration_p("P170") 

				IF NOT dist_debit(p_cmpy, p_kandoouser_sign_on_code, pr_debithead.*) THEN 
					DELETE FROM t_debitdist 
				END IF 
				CLOSE WINDOW wp170 
			COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
				LET quit_flag = true 
				EXIT MENU 

		END MENU 

		DELETE FROM t_debitdist 
		WHERE 1 = 1 
		IF int_flag OR quit_flag THEN 
			LET pr_debithead.debit_num = pr_debithead.debit_num * -1 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		RETURN pr_debithead.debit_num 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


