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

	Source code beautified by beautify.pl on 2020-01-03 14:28:29	Source code beautified by beautify.pl on 2019-11-01 09:53:16	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G1B scans the account ledger details

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	#DEFINE l_rec_accountledger RECORD LIKE accountledger.*
	#DEFINE l_rec_company RECORD LIKE company.*
	#DEFINE l_rec_coa RECORD LIKE coa.*
	#DEFINE l_cnt SMALLINT
	DEFINE glob_rec_rec_kandoouser RECORD LIKE kandoouser.* DEFINE glob_user_scan_code LIKE kandoouser.acct_mask_code 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("G1B") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING glob_rec_kandoouser.acct_mask_code, glob_user_scan_code 

	OPEN WINDOW g104 with FORM "G104" 
	CALL windecoration_g("G104") 

	WHILE getledg() 
	END WHILE 

	CLOSE WINDOW g104 
END MAIN 


############################################################
# FUNCTION getledg()
#
#
############################################################
FUNCTION getledg() 
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_cnt SMALLINT 

	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1037,"") 
	#1037 Enter Account Details - ESC TO Continue
	LET l_rec_accountledger.period_num = 0 
	INPUT BY NAME l_rec_accountledger.cmpy_code, 
	l_rec_accountledger.acct_code, 
	l_rec_accountledger.year_num, 
	l_rec_accountledger.period_num WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G1B","input-accountledger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_rec_accountledger.acct_code = showuaccts(l_rec_accountledger.cmpy_code, glob_user_scan_code) 
			DISPLAY BY NAME l_rec_accountledger.acct_code 

			NEXT FIELD acct_code 

		BEFORE FIELD cmpy_code 
			IF l_rec_accountledger.cmpy_code IS NULL THEN 
				LET l_rec_accountledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME l_rec_accountledger.cmpy_code 
				SELECT * 
				INTO l_rec_company.* 
				FROM company 
				WHERE cmpy_code = l_rec_accountledger.cmpy_code 
				IF status != NOTFOUND THEN 
					DISPLAY BY NAME l_rec_company.name_text 
				END IF 
			END IF 

		AFTER FIELD cmpy_code 
			SELECT * 
			INTO l_rec_company.* 
			FROM company 
			WHERE cmpy_code = l_rec_accountledger.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",5000,"") 
				NEXT FIELD cmpy_code 
			ELSE 
				DISPLAY BY NAME l_rec_company.name_text 

			END IF 

		AFTER FIELD acct_code 
			IF l_rec_accountledger.acct_code 
			NOT matches glob_user_scan_code THEN 
				LET l_msgresp = kandoomsg("G",9031,"") 
				NEXT FIELD acct_code 
			ELSE 
				SELECT * 
				INTO l_rec_coa.* 
				FROM coa 
				WHERE coa.acct_code = l_rec_accountledger.acct_code 
				AND coa.cmpy_code = l_rec_accountledger.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",9112,"") 
					NEXT FIELD acct_code 
				ELSE 
					DISPLAY BY NAME l_rec_coa.desc_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			SELECT count(*) 
			INTO l_cnt 
			FROM period 
			WHERE cmpy_code = l_rec_accountledger.cmpy_code 
			AND year_num = l_rec_accountledger.year_num 
			AND period_num = l_rec_accountledger.period_num 
			IF l_cnt = 0 THEN 
				LET l_msgresp = kandoomsg("U",9020,"") 
				NEXT FIELD year_num 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	LET l_rec_accountledger.seq_num = 0 
	CALL ac_detl_scan(l_rec_accountledger.cmpy_code, 
	l_rec_accountledger.acct_code, 
	l_rec_accountledger.year_num, 
	l_rec_accountledger.period_num, 
	l_rec_accountledger.seq_num) 
	LET int_flag = false 
	LET quit_flag = false 

	RETURN true 
END FUNCTION 
