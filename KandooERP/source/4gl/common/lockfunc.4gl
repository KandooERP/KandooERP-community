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
# error_recover :
#    - Recovers Programs FROM lock out situations AND various other
#         anticipated problems.
#    - Rollback Transactions etc
#
#  retry_lock   :
#    - Determines IF a locking error has occurred AND IF a retry
#         IS required
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# Module Scope Variables
###########################################################################
DEFINE modu_num_retry SMALLINT 

#################################################################################
# FUNCTION error_recover(p_message1, p_save_status)
# RETURN (l_msgresp)
#
#
#################################################################################
FUNCTION error_recover(p_message1,p_save_status) 
	DEFINE p_message1 CHAR(40) 
	DEFINE p_save_status INTEGER 
	DEFINE l_save_sqlerrd INTEGER 
	DEFINE l_err_display CHAR(55) 
	DEFINE l_error_message CHAR(55) 
	DEFINE l_msgresp LIKE language.yes_flag 
	
	DEFINE btdone STRING #huho

	LET l_save_sqlerrd = sqlca.sqlerrd[2] 

	WHENEVER ERROR CONTINUE 

	ROLLBACK WORK 

	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CASE 
		WHEN l_save_sqlerrd = -107 {record IS locked} 
			OR l_save_sqlerrd = -113 {the file IS locked} 
			OR l_save_sqlerrd = -115 {cannot CREATE LOCK file} 
			OR l_save_sqlerrd = -134 {no more locks} 
			OR l_save_sqlerrd = -143 {deadlock detected} 
			OR l_save_sqlerrd = -144 {key value locked} 
			OR l_save_sqlerrd = -154 {deadlock timeout expired - possible deadlock} 
			##
			## code below added TO globally include retry locking
			IF retry_lock("",l_save_sqlerrd) > 0 THEN 
				LET l_msgresp = "Y" 
			ELSE 
				LET l_error_message = err_get(p_save_status) 
				LET l_err_display = p_save_status USING "<<<<<<"," ", 
				l_error_message[1,45] 
				LET l_msgresp=kandoomsg("U",8003,l_err_display) ##U8003 Lock try again y/n
				IF retry_lock("",0) > 0 THEN END IF 
				END IF 
		WHEN p_save_status = -78 {deadlock situation detected/avoided} 
			OR p_save_status = -79 {no RECORD locks available} 
			OR p_save_status = -233 {record loced BY another user} 
			OR p_save_status = -250 {cannot read RECORD FROM file FOR update} 
			OR p_save_status = -263 {cannot LOCK ROW FOR update} 
			OR p_save_status = -288 {table NOT locked BY CURRENT user} 
			OR p_save_status = -289 {cannot LOCK TABLE in requested mode} 
			OR p_save_status = -291 {cannot change LOCK MODE OF table} 
			OR p_save_status = -327 {cannot UNLOCK TABLE (%s) within a transaction.} 
			OR p_save_status = -378 {record currently locked BY another user.} 
			OR p_save_status = -503 {too many tables locked.} 
			OR p_save_status = -504 {cannot LOCK a view.} 
			OR p_save_status = -521 {cannot LOCK system catalog (%s).} 
			OR p_save_status = -563 {cannot acquire exclusive LOCK FOR db conversion} 
			OR p_save_status = -621 {unable TO UPDATE new LOCK level.} 
			OR p_save_status = -3011 {a TABLE IS locked -- no reading OR writing} 
			OR p_save_status = -3460 {this ROW has been locked BY another user} 
			##
			## code below added TO globally include retry locking
			IF retry_lock("",p_save_status) > 0 THEN 
				LET l_msgresp = "Y" 
			ELSE 
				LET l_error_message = err_get(p_save_status) 
				LET l_err_display = p_save_status USING "<<<<<<"," ", 
				l_error_message[1,45] 
				LET l_msgresp=kandoomsg("U",8003,l_err_display) ##U8003 Lock try again y/n
				IF retry_lock("",0) > 0 THEN END IF 
				END IF 

		WHEN p_save_status = -104 
			OR l_save_sqlerrd = -104 
			LET l_msgresp=kandoomsg("U",8004,l_err_display) #U8004 " Too many files OPEN under UNIX - Try again? (y/n) "

		OTHERWISE 
			LET l_error_message = err_get(p_save_status) 

			OPEN WINDOW bad1 with FORM "U998_old" 
			CALL winDecoration_u("U998") -- albo kd-758 
			#DISPLAY "SQL Error Report" AT 2,26

			#DISPLAY "Status Code: ", p_save_status,"  ",l_error_message AT 4,4

			DISPLAY p_save_status TO errstatus 
			DISPLAY l_error_message TO errmessage 
			#DISPLAY "Problem location : ", p_message1 AT 6,4
			DISPLAY p_message1 TO problemlocation 
			#DISPLAY "Isam error / Serial value : ", l_save_sqlerrd using "-------" AT 7,4
			DISPLAY l_save_sqlerrd TO isamerror 

			#DISPLAY "You will be returned TO the menu. Please Check",
			#        " error before continuing" AT 9,4
			#DISPLAY "transaction. The latest work has NOT been added",
			#        " TO the database." AT 10,4

			CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 

			INPUT BY NAME btdone 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","lockfunc","input-btDone-1") -- albo kd-505 
				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 
			END INPUT 
			CLOSE WINDOW bad1 
			LET l_msgresp = "N" 
	END CASE 
	LET int_flag = false 
	LET quit_flag = false 

	RETURN (l_msgresp) 
END FUNCTION 
#################################################################################
# END FUNCTION error_recover(p_message1, p_save_status)
#################################################################################


#################################################################################
# FUNCTION retry_lock(p_cmpy,p_stat_code)
#
# RETURN ret_int_status which is either modu_num_retry OR RETURN p_stat_code
#
#################################################################################
FUNCTION retry_lock(p_cmpy,p_stat_code) 
	DEFINE p_cmpy LIKE kandoouser.cmpy_code 
	DEFINE p_stat_code SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_current_prog CHAR(10) 
	DEFINE l_current_mod CHAR(10) 
	DEFINE l_mod_code CHAR(10) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE ret_int_status SMALLINT # RETURN ret_int_status which is either modu_num_retry OR RETURN p_stat_code

	## CALL FROM error recover does NOT know p_cmpy
	LET p_cmpy = glob_rec_kandoouser.cmpy_code 
	## CALL FROM error recover does NOT know p_cmpy
	IF p_stat_code THEN 
		IF modu_num_retry > 0 THEN 
			LET modu_num_retry = modu_num_retry - 1 
			RETURN modu_num_retry 
		END IF 
	ELSE 
		LET modu_num_retry = 0 
		RETURN modu_num_retry 
	END IF 


	LET l_current_prog = get_baseprogname() 

	LET l_length = length(l_current_prog) #huho - 4 
	#HuHo I have removed the -4
	#Original was length(l_current_prog) - 4  which always lead TO a negative array index .. bang out
	#guess, this was due TO some .EXE as part of the current prog name


	LET l_current_prog = l_current_prog[1,l_length] 
	LET l_mod_code = l_current_prog[1,1] 
	LET l_mod_code = upshift(l_mod_code) 

	IF p_stat_code = -78 OR {deadlock situation detected/avoided} 
	p_stat_code = -79 OR {no RECORD locks available} 
	p_stat_code = -107 OR {isam error: RECORD IS locked.} 
	p_stat_code = -113 OR {isam error: the file IS locked.} 
	p_stat_code = -115 OR {isam error: cannot CREATE LOCK file.} 
	p_stat_code = -134 OR {isam error: no more locks} 
	p_stat_code = -143 OR {isam error: deadlock detected} 
	p_stat_code = -144 OR {isam error: KEY value locked} 
	p_stat_code = -154 OR 

	{ISAM error: Deadlock Timeout Expired - Possible Deadlock.}
	p_stat_code = -233 OR 

	{Cannot read RECORD that IS locked by another user.}
	p_stat_code = -243 OR {table locked } 
	p_stat_code = -246 OR {table locked } 
	p_stat_code = -250 OR {cannot read RECORD FROM file FOR update} 
	p_stat_code = -263 OR {could NOT LOCK ROW FOR update.} 
	p_stat_code = -288 OR {table (%s) NOT locked BY CURRENT user.} 
	p_stat_code = -289 OR {cannot LOCK TABLE (%s) in requested mode.} 
	p_stat_code = -291 OR {cannot change LOCK MODE OF table.} 
	p_stat_code = -327 OR 

	{Cannot unlock table (%s) within a transaction.}
	p_stat_code = -378 OR {record currently locked BY another user.} 
	p_stat_code = -503 OR {too many tables locked.} 
	p_stat_code = -504 OR {cannot LOCK a view.} 
	p_stat_code = -521 OR {cannot LOCK system catalog (%s).} 
	p_stat_code = -563 OR 

	{Cannot acquire exclusive lock FOR database conversion.}
	p_stat_code = -621 OR {unable TO UPDATE new LOCK level.} 
	p_stat_code = -3011 OR 
	{A table IS locked -- no reading OR writing IS permitted.}
	p_stat_code = -3460 THEN 

		{This row has been locked by another user - try again later}
		# look FOR program specific number of retrys

		DECLARE c1_syslocks CURSOR FOR 
		SELECT retry_num FROM syslocks 
		WHERE cmpy_code = p_cmpy 
		AND module_code = l_current_mod 
		AND program_name_text = l_current_prog 
		OPEN c1_syslocks 
		FETCH c1_syslocks INTO modu_num_retry 

		IF status != 0 THEN 
			DECLARE c4_syslocks CURSOR FOR 
			SELECT retry_num FROM syslocks 
			WHERE cmpy_code = p_cmpy 
			AND module_code IS NULL 
			AND program_name_text = l_current_prog 
			OPEN c4_syslocks 
			FETCH c4_syslocks INTO modu_num_retry 
			
			IF status != 0 THEN 
				DECLARE c2_syslocks CURSOR FOR 
				SELECT retry_num FROM syslocks 
				WHERE cmpy_code = p_cmpy 
				AND module_code = l_current_mod 
				AND program_name_text IS NULL 
				OPEN c2_syslocks 
				FETCH c2_syslocks INTO modu_num_retry
				 
				IF status != 0 THEN 
					DECLARE c3_syslocks CURSOR FOR 
					SELECT retry_num FROM syslocks 
					WHERE cmpy_code = p_cmpy 
					AND module_code IS NULL 
					AND program_name_text IS NULL 
					OPEN c3_syslocks 
					FETCH c3_syslocks INTO modu_num_retry 
					IF status != 0 THEN 
						LET modu_num_retry = 1 
					END IF 
				END IF 
			END IF 
		END IF 
		LET modu_num_retry = modu_num_retry - 1 
		LET ret_int_status = modu_num_retry
	ELSE 
		LET ret_int_status = p_stat_code 
	END IF
	
	RETURN ret_int_status 
END FUNCTION 
#################################################################################
# END FUNCTION retry_lock(p_cmpy,p_stat_code)
#################################################################################


#################################################################################
# FUNCTION unattended_recover(p_message1, p_save_status)
#
# RETURN (l_msgresp)
#
#################################################################################
FUNCTION unattended_recover(p_message1,p_save_status) 
	DEFINE p_message1 CHAR(40) #not used 
	DEFINE p_save_status INTEGER 
	DEFINE l_save_sqlerrd INTEGER 
	DEFINE l_err_display CHAR(55) 
	DEFINE l_error_message CHAR(55) 
	DEFINE ret_msgresp LIKE language.yes_flag 

	LET l_save_sqlerrd = sqlca.sqlerrd[2] 
	WHENEVER ERROR CONTINUE 
	ROLLBACK WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	CASE 
		WHEN l_save_sqlerrd = -107 {record IS locked} 
			OR l_save_sqlerrd = -113 {the file IS locked} 
			OR l_save_sqlerrd = -115 {cannot CREATE LOCK file} 
			OR l_save_sqlerrd = -134 {no more locks} 
			OR l_save_sqlerrd = -143 {deadlock detected} 
			OR l_save_sqlerrd = -144 {key value locked} 
			OR l_save_sqlerrd = -154 {deadlock timeout expired - possible deadlock} 
			##
			## code below added TO globally include retry locking
			IF retry_lock("",l_save_sqlerrd) > 0 THEN 
				LET ret_msgresp = "Y" 
			ELSE 
				LET l_error_message = err_get(p_save_status) 
				LET l_err_display = p_save_status USING "<<<<<<"," ", 
				l_error_message[1,45] 
				#LET ret_msgresp=kandoomsg("U",8003,l_err_display)
				##U8003 Lock try again y/n
				LET ret_msgresp = "N" 
				IF retry_lock("",0) > 0 THEN END IF 
				END IF 
		WHEN p_save_status = -78 {deadlock situation detected/avoided} 
			OR p_save_status = -79 {no RECORD locks available} 
			OR p_save_status = -233 {record loced BY another user} 
			OR p_save_status = -250 {cannot read RECORD FROM file FOR update} 
			OR p_save_status = -263 {cannot LOCK ROW FOR update} 
			OR p_save_status = -288 {table NOT locked BY CURRENT user} 
			OR p_save_status = -289 {cannot LOCK TABLE in requested mode} 
			OR p_save_status = -291 {cannot change LOCK MODE OF table} 
			OR p_save_status = -327 {cannot UNLOCK TABLE (%s) within a transaction.} 
			OR p_save_status = -378 {record currently locked BY another user.} 
			OR p_save_status = -503 {too many tables locked.} 
			OR p_save_status = -504 {cannot LOCK a view.} 
			OR p_save_status = -521 {cannot LOCK system catalog (%s).} 
			OR p_save_status = -563 {cannot acquire exclusive LOCK FOR db conversion} 
			OR p_save_status = -621 {unable TO UPDATE new LOCK level.} 
			OR p_save_status = -3011 {a TABLE IS locked -- no reading OR writing} 
			OR p_save_status = -3460 {this ROW has been locked BY another user} 
			##
			## code below added TO globally include retry locking
			IF retry_lock("",p_save_status) > 0 THEN 
				LET ret_msgresp = "Y" 
			ELSE 
				LET l_error_message = err_get(p_save_status) 
				LET l_err_display = p_save_status USING "<<<<<<"," ", 
				l_error_message[1,45] 
				#LET ret_msgresp=kandoomsg("U",8003,l_err_display)
				##U8003 Lock try again y/n
				LET ret_msgresp = "N" 
				IF retry_lock("",0) > 0 THEN END IF 
				END IF 
		WHEN p_save_status = -104 
			OR l_save_sqlerrd = -104 
			#LET ret_msgresp=kandoomsg("U",8004,l_err_display)		#U8004 " Too many files OPEN under UNIX - Try again? (y/n) "
			LET ret_msgresp = "N" 
		OTHERWISE 
			LET l_error_message = err_get(p_save_status) 
	END CASE 

	LET int_flag = false 
	LET quit_flag = false 

	RETURN (ret_msgresp) 
END FUNCTION 
#################################################################################
# END FUNCTION unattended_recover(p_message1, p_save_status)
#################################################################################