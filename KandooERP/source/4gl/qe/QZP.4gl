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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/QZ_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/QZP_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# Allows the user TO maintain Quotation Parameters
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("QZP") -- albo 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) 
	#CALL init_q_qe() 

	SELECT * INTO glob_rec_qpparms.* 
	FROM qpparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		ERROR kandoomsg2("Q",5002,"") #5002 " Quotation Parameters are NOT found"
		sleep 2
	END IF 
	

	OPEN WINDOW Q117 with FORM "Q117" -- alch kd-747 
	CALL windecoration_q("Q117") -- alch kd-747 

	MENU " Parameters" 
		BEFORE MENU 
			IF display_qparm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 


		COMMAND "Add" " Add Parameters" 
			IF add_qparm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF display_qparm() THEN 
			END IF 

		COMMAND "Change" " Change Parameters" 
			CALL change_parm() 
			IF display_qparm() THEN 
			END IF 

		COMMAND KEY (interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW Q117 
END MAIN 


#######################################################################
# FUNCTION add_qparm()
#
#
#######################################################################
FUNCTION add_qparm() 
	DEFINE l_rec_qpparms RECORD LIKE qpparms.* 

	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue
	INPUT BY NAME l_rec_qpparms.min_margin_per, 
	l_rec_qpparms.max_margin_per, 
	l_rec_qpparms.security_ind, 
	l_rec_qpparms.days_validity_num, 
	l_rec_qpparms.quote_std_text, 
	l_rec_qpparms.quote_user_text, 
	l_rec_qpparms.stockout_lead_text, 
	l_rec_qpparms.quote_lead_text, 
	l_rec_qpparms.quote_lead_text2, 
	l_rec_qpparms.footer1_text, 
	l_rec_qpparms.footer2_text, 
	l_rec_qpparms.footer3_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","QZP","inp-l_rec_qpparms-3") -- alch kd-501 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD min_margin_per 
			IF l_rec_qpparms.min_margin_per IS NULL THEN 
				LET l_rec_qpparms.min_margin_per = 0 
			END IF 

		AFTER FIELD max_margin_per 
			IF l_rec_qpparms.max_margin_per IS NULL THEN 
				LET l_rec_qpparms.max_margin_per = 0 
			END IF 

		AFTER FIELD security_ind 
			IF l_rec_qpparms.security_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD security_ind 
			END IF 

		AFTER FIELD days_validity_num 
			IF l_rec_qpparms.days_validity_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD days_validity_num 
			END IF 
			IF l_rec_qpparms.days_validity_num < 0 THEN 
				LET msgresp = kandoomsg("U",9907,"0") 
				#9907 Value must be greater than OR equal TO 0
				NEXT FIELD days_validity_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_qpparms.min_margin_per IS NULL THEN 
					LET l_rec_qpparms.min_margin_per = 0 
				END IF 
				IF l_rec_qpparms.max_margin_per IS NULL THEN 
					LET l_rec_qpparms.max_margin_per = 0 
				END IF 
				IF l_rec_qpparms.security_ind IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD security_ind 
				END IF 
				IF l_rec_qpparms.days_validity_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD days_validity_num 
				END IF 
			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_rec_qpparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_qpparms.key_num = "1" 

	INSERT INTO qpparms VALUES (l_rec_qpparms.*) 

	RETURN true 
END FUNCTION 


#######################################################################
# FUNCTION change_parm()
#
#
#######################################################################
FUNCTION change_parm() 
	DEFINE l_rec_qpparms RECORD LIKE qpparms.* 
	DEFINE l_err_message CHAR(60) 

	SELECT * INTO l_rec_qpparms.* FROM qpparms 
	WHERE qpparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue

	INPUT BY NAME l_rec_qpparms.min_margin_per, 
	l_rec_qpparms.max_margin_per, 
	l_rec_qpparms.security_ind, 
	l_rec_qpparms.days_validity_num, 
	l_rec_qpparms.quote_std_text, 
	l_rec_qpparms.quote_user_text, 
	l_rec_qpparms.stockout_lead_text, 
	l_rec_qpparms.quote_lead_text, 
	l_rec_qpparms.quote_lead_text2, 
	l_rec_qpparms.footer1_text, 
	l_rec_qpparms.footer2_text, 
	l_rec_qpparms.footer3_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","QZP","inp-l_rec_qpparms-4") -- alch kd-501 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD min_margin_per 
			IF l_rec_qpparms.min_margin_per IS NULL THEN 
				LET l_rec_qpparms.min_margin_per = 0 
			END IF 

		AFTER FIELD max_margin_per 
			IF l_rec_qpparms.max_margin_per IS NULL THEN 
				LET l_rec_qpparms.max_margin_per = 0 
			END IF 

		AFTER FIELD security_ind 
			IF l_rec_qpparms.security_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD security_ind 
			END IF 

		AFTER FIELD days_validity_num 
			IF l_rec_qpparms.days_validity_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD days_validity_num 
			END IF 
			IF l_rec_qpparms.days_validity_num < 0 THEN 
				LET msgresp = kandoomsg("U",9907,"0") 
				#9907 Value must be greater than OR equal TO 0
				NEXT FIELD days_validity_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_qpparms.min_margin_per IS NULL THEN 
					LET l_rec_qpparms.min_margin_per = 0 
				END IF 
				IF l_rec_qpparms.max_margin_per IS NULL THEN 
					LET l_rec_qpparms.max_margin_per = 0 
				END IF 
				IF l_rec_qpparms.security_ind IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD security_ind 
				END IF 
				IF l_rec_qpparms.days_validity_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD days_validity_num 
				END IF 
			END IF 
			#		ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "QZP - Locking Parameters Record" 

		DECLARE c_qpparms CURSOR FOR 
		SELECT * FROM qpparms 
		WHERE key_num = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_qpparms 
		FETCH c_qpparms 

		UPDATE qpparms 
		SET * = l_rec_qpparms.* 
		WHERE key_num = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 



#######################################################################
# FUNCTION display_qparm()
#
#
#######################################################################
FUNCTION display_qparm() 
	DEFINE l_rec_qpparms RECORD LIKE qpparms.* 

	SELECT * INTO l_rec_qpparms.* FROM qpparms 
	WHERE qpparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	DISPLAY BY NAME l_rec_qpparms.min_margin_per, 
	l_rec_qpparms.max_margin_per, 
	l_rec_qpparms.security_ind, 
	l_rec_qpparms.days_validity_num, 
	l_rec_qpparms.quote_std_text, 
	l_rec_qpparms.quote_user_text, 
	l_rec_qpparms.stockout_lead_text, 
	l_rec_qpparms.quote_lead_text, 
	l_rec_qpparms.quote_lead_text2, 
	l_rec_qpparms.footer1_text, 
	l_rec_qpparms.footer2_text, 
	l_rec_qpparms.footer3_text 

	RETURN true 
END FUNCTION 
