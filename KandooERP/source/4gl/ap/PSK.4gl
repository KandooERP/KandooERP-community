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

	Source code beautified by beautify.pl on 2020-01-03 13:41:48	$Id: $
}



#Provide external payments interface TO Westpac.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
#GLOBALS "PSK_GLOBALS.4gl"
#GLOBALS "../common/loadfunc.4gl"

#Module Scope Variables
 
#############################################################
# MAIN
#
#
#############################################################
MAIN 
	DEFINE l_menu_path CHAR(10)
	DEFINE l_window_name CHAR(40)
	DEFINE l_report_name CHAR(60)

	DEFER interrupt 
	DEFER quit 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CREATE temp TABLE t_rates (vend_code CHAR(8), 
	addr1_text CHAR(40), 
	city_text CHAR(40), 
	state_code CHAR(6), 
	post_code CHAR(10), 
	bic_text CHAR(6), 
	bank_acct_code CHAR(20), 
	fax_text CHAR(20)) with no LOG 
	LET l_window_name = " Vendor Information" 
	LET l_report_name = "Vendor Load Update Error Report" 
	LET l_menu_path = "PSK" 
	CALL menu_details() 
END MAIN 

#############################################################
# FUNCTION validate_file()
#
#
#############################################################
FUNCTION validate_file() 
	DEFINE l_rec_quaderr 
	RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD 
	DEFINE l_rec_vend 
	RECORD 
		vend_code CHAR(8), 
		addr1_text CHAR(40), 
		city_text CHAR(40), 
		state_code CHAR(6), 
		post_code CHAR(10), 
		bic_text CHAR(6), 
		bank_acct_code CHAR(20), 
		fax_text CHAR(20) 
	END RECORD 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_err_cnt SMALLINT
	DEFINE l_inserted_rows SMALLINT
	DEFINE l_bank_acct_code CHAR(20) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	LET idx = 0 
	LET l_inserted_rows = 0 
	LET l_err_cnt = 0 

	INITIALIZE l_rec_quaderr.* TO NULL 
	LET l_query_text = "SELECT * FROM t_rates" 
	PREPARE s_rates FROM l_query_text 
	DECLARE c_rates CURSOR FOR s_rates 

	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.

	MESSAGE "Updating Vendor..." 

	FOREACH c_rates INTO l_rec_vend.* 
		LET idx = idx + 1 

		IF l_rec_vend.vend_code IS NULL THEN 
			LET l_rec_quaderr.error_text = "Vendor code must be entered" 
			LET l_rec_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (l_rec_quaderr.*) 
			INITIALIZE l_rec_quaderr.* TO NULL 
			CONTINUE FOREACH 
		ELSE 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_vend.vend_code 
			IF status = NOTFOUND THEN 
				LET l_rec_quaderr.error_text = "Vendor ", 
				l_rec_vend.vend_code, " does NOT exist - unable TO UPDATE" 
				LET l_rec_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (l_rec_quaderr.*) 
				INITIALIZE l_rec_quaderr.* TO NULL 
				CONTINUE FOREACH 
			END IF 

		END IF 

		CALL fgl_winmessage("display at 35434","display at", "info") 
		DISPLAY l_rec_vendor.vend_code at 2,10 

		DISPLAY l_rec_vendor.name_text at 3,10 

		LET l_inserted_rows = l_inserted_rows + 1 
		LET l_bank_acct_code[1,6] = l_rec_vend.bic_text 
		LET l_bank_acct_code[8,20] = l_rec_vend.bank_acct_code 

		UPDATE vendor 
		SET addr1_text = l_rec_vend.addr1_text, 
		city_text = l_rec_vend.city_text, 
		state_code = l_rec_vend.state_code, 
		post_code = l_rec_vend.post_code, 
		bank_acct_code = l_bank_acct_code, 
		fax_text = l_rec_vend.fax_text, 
		pay_meth_ind = "3" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vend.vend_code 

		IF status < 0 THEN 
			LET l_rec_quaderr.error_text = l_rec_vend.vend_code, 
			" ", "Failed UPDATE error" 

			LET l_rec_quaderr.line_num = idx 

			INSERT INTO t_quaderr VALUES (l_rec_quaderr.*) 
			INITIALIZE l_rec_quaderr.* TO NULL 
			CONTINUE FOREACH 

		END IF 

	END FOREACH 

END FUNCTION 


