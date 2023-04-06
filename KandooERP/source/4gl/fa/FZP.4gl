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

	Source code beautified by beautify.pl on 2020-01-03 10:37:01	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../fa/F_FA_GLOBALS.4gl" 
#GLOBALS
#	DEFINE glob_rec_faparms RECORD LIKE faparms.* #not used ??????
#END GLOBALS


############################################################
# MAIN
#
# Purpose   :   fixed asset parameter entry
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("FZP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	OPEN WINDOW f131 with FORM "F131" -- alch kd-757 
	CALL  windecoration_f("F131") -- alch kd-757 

	MENU " Parameters" 
		BEFORE MENU 
			IF display_parm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 
			CALL publish_toolbar("kandoo","FZP","menu-params-1") -- alch kd-504 
		COMMAND "Add" " Add Parameters" 
			IF add_fn() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF display_parm() THEN 
			END IF 
		COMMAND "Change" " Change Parameters" 
			CALL edit_fn() 
			IF display_parm() THEN 
			END IF 
		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT program 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
	CLOSE WINDOW f131 
END MAIN 



############################################################
# FUNCTION add_fn()
#
#
############################################################
FUNCTION add_fn() 
	DEFINE l_rec_faparms RECORD LIKE faparms.* 
	DEFINE l_temp_text CHAR(30) 
	DEFINE cnt SMALLINT 

	LET l_rec_faparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.

	INPUT BY NAME l_rec_faparms.next_batch_num, 
	l_rec_faparms.control_tot_flag, 
	l_rec_faparms.use_clear_flag, 
	l_rec_faparms.use_add_on_flag, 
	l_rec_faparms.asset_jnl_code, 
	l_rec_faparms.auto_start_num, 
	l_rec_faparms.asset_period_num WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FZP","inp-l_rec_faparms-2") -- alch kd-504 
		AFTER FIELD next_batch_num 
			IF l_rec_faparms.next_batch_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET l_rec_faparms.next_batch_num = 0 
				NEXT FIELD next_batch_num 
			END IF 
			IF l_rec_faparms.next_batch_num < 0 THEN 
				LET msgresp = kandoomsg("F",9541,"") 
				#9541 Batch number must be equal TO OR greater than zero.
				LET l_rec_faparms.next_batch_num = 0 
				NEXT FIELD next_batch_num 
			END IF 
		AFTER FIELD asset_jnl_code 
			IF l_rec_faparms.asset_jnl_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be enetered.
				NEXT FIELD asset_jnl_code 
			END IF 
			SELECT jour_code FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = l_rec_faparms.asset_jnl_code 
			IF status THEN 
				LET msgresp = kandoomsg("G",9029,"") 
				#9029 Journal code NOT found; Try Window.
				NEXT FIELD asset_jnl_code 
			END IF 

		ON ACTION "LOOKUP" infield (asset_jnl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_faparms.asset_jnl_code = show_jour(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME l_rec_faparms.asset_jnl_code 

			END IF 
			NEXT FIELD asset_jnl_code 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_faparms.next_batch_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_batch_num 
				END IF 
				IF l_rec_faparms.asset_jnl_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be enetered.
					NEXT FIELD asset_jnl_code 
				END IF 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 

	END INPUT 

	IF (int_flag OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	INSERT INTO faparms VALUES (l_rec_faparms.*) 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION display_parm()
#
#
############################################################
FUNCTION display_parm() 
	DEFINE l_rec_faparms RECORD LIKE faparms.* 

	CLEAR FORM 
	SELECT * INTO l_rec_faparms.* FROM faparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	DISPLAY BY NAME l_rec_faparms.next_batch_num, 
	l_rec_faparms.control_tot_flag, 
	l_rec_faparms.use_clear_flag, 
	l_rec_faparms.use_add_on_flag, 
	l_rec_faparms.asset_jnl_code, 
	l_rec_faparms.auto_start_num, 
	l_rec_faparms.asset_period_num 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION edit_fn()
#
#
############################################################
FUNCTION edit_fn() 
	DEFINE l_rec_faparms RECORD LIKE faparms.* 
	DEFINE l_rec_s_faparms RECORD LIKE faparms.* 
	DEFINE l_rec_t_faparms RECORD LIKE faparms.* 
	#DEFINE l_counter     SMALLINT #not used ???
	DEFINE l_batch_num LIKE faparms.next_batch_num 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_err_message CHAR(40) 

	SELECT * INTO l_rec_faparms.* FROM faparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_rec_s_faparms.* = l_rec_faparms.* 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.

	INPUT BY NAME l_rec_faparms.next_batch_num, 
	l_rec_faparms.control_tot_flag, 
	l_rec_faparms.use_clear_flag, 
	l_rec_faparms.use_add_on_flag, 
	l_rec_faparms.asset_jnl_code, 
	l_rec_faparms.auto_start_num, 
	l_rec_faparms.asset_period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FZP","inp-l_rec_faparms-3") -- alch kd-504 

		AFTER FIELD asset_jnl_code 
			SELECT jour_code FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = l_rec_faparms.asset_jnl_code 
			IF status THEN 
				LET msgresp = kandoomsg("G",9029,"") 
				#9029 Journal code NOT found; Try Window.
				NEXT FIELD asset_jnl_code 
			END IF 

		AFTER FIELD next_batch_num 
			IF l_rec_faparms.next_batch_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD next_batch_num 
			END IF 
			SELECT max(batch_num) INTO l_batch_num FROM fabatch 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_rec_faparms.next_batch_num < l_batch_num THEN 
				LET msgresp = kandoomsg("F",9525,l_batch_num) 
				#9525 Batch number must be equal TO OR greater than XXX.
				LET l_rec_faparms.next_batch_num = l_batch_num 
				NEXT FIELD next_batch_num 
			END IF 
			IF l_rec_faparms.next_batch_num < 0 THEN 
				LET msgresp = kandoomsg("F",9541,"") 
				#9541 Batch number must be equal TO OR greater than zero.
				LET l_rec_faparms.next_batch_num = 0 
				NEXT FIELD next_batch_num 
			END IF 

		ON ACTION "LOOKUP" infield (asset_jnl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_faparms.asset_jnl_code = show_jour(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME l_rec_faparms.asset_jnl_code 

			END IF 
			
			NEXT FIELD asset_jnl_code 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_faparms.next_batch_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_batch_num 
				END IF 
				SELECT max(batch_num) INTO l_batch_num FROM fabatch 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_faparms.next_batch_num < l_batch_num THEN 
					LET msgresp = kandoomsg("F",9525,l_batch_num) 
					#9525 Batch number must be equal TO OR greater than XXX.
					LET l_rec_faparms.next_batch_num = l_batch_num 
					NEXT FIELD next_batch_num 
				END IF 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 

	END INPUT 

	IF (int_flag OR quit_flag) THEN 
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
		LET l_err_message = "FZP - Locking Parameters Record" 
		DECLARE c_faparms CURSOR FOR 
		SELECT * FROM faparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 

		OPEN c_faparms 
		FETCH c_faparms INTO l_rec_t_faparms.* 

		IF l_rec_t_faparms.next_batch_num != l_rec_s_faparms.next_batch_num 
		OR l_rec_t_faparms.auto_start_num != l_rec_s_faparms.auto_start_num THEN 
			ROLLBACK WORK 
			LET msgresp = kandoomsg("U",7050,"") 
			#7050 Parameter VALUES have been updated since changes. Please review.
			RETURN 
		END IF 

		UPDATE faparms 
		SET * = l_rec_faparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 
