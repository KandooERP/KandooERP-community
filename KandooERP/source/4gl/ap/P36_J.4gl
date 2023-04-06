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
	Source code beautified by beautify.pl on 2020-01-03 13:41:26	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_load_file CHAR(100) 
	DEFINE glob_cheque_date LIKE cheque.cheq_date 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P36_J") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW p219 with FORM "P219" 
	CALL windecoration_p("P219") 

	OPTIONS MESSAGE line FIRST 
	CALL create_table("cheque","t_cheque","vend_code com1_text cheq_code cheq_date","Y") 
	WHILE enter_details() 
		CALL unload_cheq() 
	END WHILE 
	CLOSE WINDOW p219 
END MAIN 


FUNCTION enter_details() 
	DEFINE l_file_text CHAR(20) 
	DEFINE l_path_text CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT last_chq_prnt_date 
	INTO glob_cheque_date 
	FROM apparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = '1' 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",5016,"") 
		#5016 AP Parameters NOT SET up
		RETURN false 
	END IF 
	MESSAGE " Enter Cheque Unload Details - ESC TO Continue" 

	INPUT l_file_text,l_path_text,glob_cheque_date WITHOUT DEFAULTS FROM file_text,path_text,cheque_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P36_J","inp-file-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD file_text 
			IF l_file_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9166,"") 
				#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 
		AFTER FIELD path_text 
			IF l_path_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",8015,"") 
				#8015 Warning: Current directory will be defaulted
			END IF 
		AFTER FIELD cheque_date 
			IF glob_cheque_date IS NULL THEN 
				ERROR "Must enter a cheque date" 
				NEXT FIELD cheque_date 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9166,"") 
					#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF NOT create_load_file( l_path_text, l_file_text ) THEN 
					NEXT FIELD file_text 
				END IF 
				IF glob_cheque_date IS NULL THEN 
					ERROR "Must enter a cheque date" 
					NEXT FIELD cheque_date 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION unload_cheq() 
	DEFINE l_err_message CHAR(200) 

	MESSAGE " Unloading Cheque Details - please wait" 
	WHENEVER ERROR CONTINUE 
	DELETE FROM t_cheque 
	INSERT INTO t_cheque SELECT v.vend_code, 
	c.cheq_code, 
	c.cheq_date, 
	v.com1_text 
	FROM cheque c, 
	voucher v, 
	voucherpays p 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cheq_date = glob_cheque_date 
	AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.vend_code = c.vend_code 
	AND p.pay_type_code = 'CH' 
	AND p.pay_num = c.cheq_code 
	AND p.pay_date = glob_cheque_date 
	AND v.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND v.vouch_code = p.vouch_code 
	AND v.vend_code = p.vend_code 
	AND v.com1_text[1,5]= 'WORK ' 
	IF sqlca.sqlcode <> 0 THEN 
		LET l_err_message = "P36_J - Load - ",err_get(STATUS) 
		CALL errorlog( l_err_message ) 
		LET l_err_message = " Load - Refer to ", trim(get_settings_logFile()), " FOR SQL Error: ", 
		sqlca.sqlcode USING "----&" 
		ERROR l_err_message clipped 
		SLEEP 3 
	END IF 
	UNLOAD TO glob_load_file 
	SELECT vend_code,com1_text,cheq_code,cheq_date FROM t_cheque 
	IF sqlca.sqlcode = 0 THEN 
		ERROR " Cheque Detail unload completed successfully" 
	ELSE 
		LET l_err_message = "P36_J - Unload - ",err_get(STATUS) 
		CALL errorlog( l_err_message ) 
		LET l_err_message = " Unload - Refer to ", trim(get_settings_logFile()), "FOR SQL Error: ", 
		sqlca.sqlcode USING "----&" 
		ERROR l_err_message clipped 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 


FUNCTION create_load_file(p_path_text,p_file_text) 
	DEFINE p_path_text CHAR(60) 
	DEFINE p_file_text CHAR(20) 
	DEFINE l_slash_text char 
	DEFINE l_len_num INTEGER 

	IF valid_dir( p_path_text ) THEN 
		LET l_len_num = length( p_path_text ) 
		INITIALIZE l_slash_text TO NULL 
		IF l_len_num > 0 THEN 
			IF p_path_text[l_len_num,l_len_num] != "\/" THEN 
				LET l_slash_text = "\/" 
			END IF 
		END IF 
		LET glob_load_file = p_path_text clipped, 
		l_slash_text clipped, 
		p_file_text clipped 
		LET glob_load_file = glob_load_file clipped 
		LET glob_load_file = valid_load_file( glob_load_file ) 
		IF glob_load_file IS NULL THEN 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


FUNCTION valid_dir(p_path_text) 
	DEFINE 
	p_path_text CHAR(60) --, 
	#runner       CHAR(100),
	#ret_code     INTEGER

	#huho changed TO os.path() method
	IF os.path.exists(p_path_text) THEN 
		RETURN true 
	ELSE 
		ERROR "Invalid Directory name" 
		RETURN false 
	END IF 


	#   LET runner = " [ -d ",p_path_text clipped," ] 2>>", trim(get_settings_logFile())
	#   run runner returning ret_code
	#   IF ret_code THEN
	#      ERROR "Invalid Directory name"
	#      RETURN FALSE
	#   ELSE
	#      RETURN TRUE
	#   END IF
END FUNCTION 


FUNCTION valid_load_file(p_file_name) 
	#
	#        1. File already exists
	#        2. No write permission
	#        3. File IS Empty
	#        4. OTHERWISE
	#

	#huho changed TO os.path() method
	DEFINE 
	#  runner,
	p_file_name CHAR(100), 
	ret_code INTEGER 
	LET ret_code = os.path.exists(p_file_name) 
	#LET runner = " [ -f ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run runner returning ret_code
	IF NOT ret_code THEN 
		ERROR "Target file already exists" 
		RETURN "" 
	ELSE 
		RETURN p_file_name 
	END IF 
END FUNCTION 


