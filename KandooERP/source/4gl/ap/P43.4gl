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

	Source code beautified by beautify.pl on 2020-01-03 13:41:29	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P43 allows the user TO enter a cheque THEN AND distribute
# the associated Payables Voucher
#
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("P43") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 
	##now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.*
	#  FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND parm_code = "1"
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp=kandoomsg("P",5016,"")
	#   EXIT PROGRAM
	#END IF
	CALL create_table("voucherdist","t_voucherdist","","Y") 
	WHILE true 
		CALL enter_cheq(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"","","","") 
		RETURNING l_rec_cheque.cheq_code, 
		l_rec_cheque.bank_acct_code 
		SELECT * INTO l_rec_cheque.* 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cheq_code = l_rec_cheque.cheq_code 
		AND bank_acct_code = l_rec_cheque.bank_acct_code 
		AND pay_meth_ind = "1" 
		IF status = 0 THEN 

			OPEN WINDOW P125 with FORM "P125" 
			CALL windecoration_p("P125") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			CLEAR FORM 
			CALL input_voucher(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_kandoouser.sign_on_code,
				l_rec_cheque.vend_code,
				"", 
				l_rec_cheque.cheq_code) 
			RETURNING l_rec_voucher.*, l_rec_vouchpayee.* 
			
			IF l_rec_voucher.vend_code IS NOT NULL THEN 

				MENU " Voucher" 
					BEFORE MENU 
						#Re-selected TO ensure latest value
						SELECT * INTO glob_rec_apparms.* FROM apparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","P43","menu-voucher-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					COMMAND "Save" " Save voucher AND generate payment" 
						LET l_rec_voucher.vouch_code = update_voucher_related_tables(
							glob_rec_kandoouser.cmpy_code,
							glob_rec_kandoouser.sign_on_code,
							"1",
							l_rec_voucher.*, 
							l_rec_vouchpayee.*) 
						
						CASE 
							WHEN l_rec_voucher.vouch_code < 0 
								LET l_rec_voucher.vouch_code = 0 - l_rec_voucher.vouch_code 
								LET l_msgresp=kandoomsg("P",7016,l_rec_voucher.vouch_code)				#P7016" Voucher added - error with dist lines
							WHEN l_rec_voucher.vouch_code = 0 
								LET l_msgresp=kandoomsg("P",7012,"") 			#P7012 Errors occurred during voucher add
							WHEN l_rec_voucher.vouch_code > 0 
								LET l_msgresp=kandoomsg("P",7011,l_rec_voucher.vouch_code)					#P7011" Voucher crested successfully"
						END CASE 
						
						IF l_rec_voucher.vouch_code > 0 THEN 
							CALL auto_cheq_appl(
								glob_rec_kandoouser.cmpy_code,
								l_rec_cheque.cheq_code, 
								l_rec_voucher.vouch_code, 
								l_rec_cheque.bank_acct_code) 
						END IF 
						EXIT MENU 
						
					COMMAND "Distribution" 
						OPEN WINDOW P169 with FORM "P169" 
						CALL windecoration_p("P169") 
						#dist_vouch
						IF NOT distribute_voucher_to_accounts(
							glob_rec_kandoouser.cmpy_code,
							glob_rec_kandoouser.sign_on_code,
							l_rec_voucher.*) THEN 
							
							# DELETE
							DELETE FROM t_voucherdist 
						END IF 
						
						CLOSE WINDOW P169 
					
					COMMAND KEY(interrupt,"E")"Exit" 
						LET int_flag = false 
						LET quit_flag = false 
						EXIT MENU 

				END MENU 

			END IF 
			CLOSE WINDOW P125 
			
			#DELETE ----------------------
			DELETE FROM t_voucherdist 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE
	 
END MAIN 
############################################################
# END MAIN
############################################################