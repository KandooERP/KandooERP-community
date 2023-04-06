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

	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

#Module Scope Variables


###################################################################################
# MAIN
#
#
###################################################################################
MAIN 

	CALL setModuleId("UR1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u107 with FORM "U107" 
	CALL windecoration_u("U107") 

	CALL rmsparms() 
	CLOSE WINDOW u107 
END MAIN 


###################################################################################
# FUNCTION rmsparms()
#
#
###################################################################################
FUNCTION rmsparms() 
	DEFINE l_rec_rmsparm RECORD LIKE rmsparm.* 
	DEFINE l_save_num LIKE rmsparm.next_report_num 
	DEFINE l_file_text CHAR(100) 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_report_no INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp = kandoomsg("U",1009,"") 
	SELECT * INTO l_rec_rmsparm.* FROM rmsparm 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET l_rec_rmsparm.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_rmsparm.order_print_text = " " 
		LET l_rec_rmsparm.inv_print_text = " " 
		LET l_rec_rmsparm.next_report_num = 1000 
		INSERT INTO rmsparm VALUES (l_rec_rmsparm.*) 
	END IF 
	LET l_save_num = l_rec_rmsparm.next_report_num 
	INPUT BY NAME l_rec_rmsparm.order_print_text, 
	l_rec_rmsparm.inv_print_text, 
	l_rec_rmsparm.next_report_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","UR1","input-rmsparm") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD next_report_num 
			IF l_rec_rmsparm.next_report_num < 0 THEN 
				LET l_msgresp = kandoomsg("U",9109,"") 
				#9019 Negatives NOT permitted
				LET l_rec_rmsparm.next_report_num = l_save_num 
				NEXT FIELD next_report_num 
			END IF 
			IF l_rec_rmsparm.next_report_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entereded
				LET l_rec_rmsparm.next_report_num = l_save_num 
				NEXT FIELD next_report_num 
			END IF 
			SELECT report_code FROM rmsreps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND report_code = l_rec_rmsparm.next_report_num 
			IF status != notfound THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				#9104 RECORD already exists
				LET l_rec_rmsparm.next_report_num = l_save_num 
				NEXT FIELD next_report_num 
			END IF 


		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_rmsparm.next_report_num < 0 THEN 
					LET l_msgresp = kandoomsg("U",9109,"") 
					#9109 Negatives NOT Permitted
					NEXT FIELD next_report_num 
				END IF 
				IF l_rec_rmsparm.next_report_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD next_report_num 
				END IF 
				GOTO bypass 
				LABEL recovery: 
				LET l_try_again = error_recover(l_err_message, status) 
				IF l_try_again != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					DECLARE c2_rmsparm CURSOR FOR 
					SELECT next_report_num FROM rmsparm 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					FOR UPDATE 
					OPEN c2_rmsparm 
					FETCH c2_rmsparm INTO l_save_num 
					# The FETCH INTO l_save_num IS simply notional TO allow the
					# FOR UPDATE TO take place.  The number that will be utilised
					# will originate FROM user entry AND be validated against.
					IF l_rec_rmsparm.next_report_num >= 99999000 THEN 
						LET l_rec_rmsparm.next_report_num = 1 
					END IF 
					WHILE true 
						SELECT unique 1 FROM rmsreps 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND report_code = l_rec_rmsparm.next_report_num 
						IF status = notfound THEN 
							EXIT WHILE 
						ELSE 
							LET l_rec_rmsparm.next_report_num = l_rec_rmsparm.next_report_num + 1 
							IF l_rec_rmsparm.next_report_num >= 99999000 THEN 
								LET l_rec_rmsparm.next_report_num = 1 
							END IF 
						END IF 
					END WHILE 
					UPDATE rmsparm 
					SET next_report_num = l_rec_rmsparm.next_report_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				COMMIT WORK 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION