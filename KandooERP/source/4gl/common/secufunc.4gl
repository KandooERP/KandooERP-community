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
############################################################
# GLOBAL SCOPE
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
##############################################################
# FUNCTION authenticate(p_module_id)
#
# NOTE: This function IS used for ALL PRORGRAMS
# BUT NOT USED by the main MENU application launcher (transformer menu)
##############################################################
FUNCTION authenticate(p_module_id) 
	DEFINE p_module_id NCHAR(5) 
	DEFINE l_rec_kandooinfo RECORD LIKE kandooinfo.* 
	DEFINE l_exit_on_start SMALLINT 
	DEFINE l_baseprogramid STRING 
	DEFINE l_msgstr STRING 
	DEFINE l_kandoo_log CHAR(120) 
	DEFINE l_login_user_method CHAR 
	DEFINE l_authentication_env_exists BOOLEAN 
	DEFINE l_security_role_status SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT
	#Check if user entered sign_on_code, user_code OR email address
	#Authenticate User with sign_on_code & password

	LET l_authentication_env_exists = FALSE 

	IF get_debug() = TRUE THEN 
		DISPLAY "########### authenticate(p_module_id) 1 ################" 
		DISPLAY "p_module_id = ", p_module_id 
	END IF 

	IF (get_ku_password_text() IS NOT null) AND ((get_ku_sign_on_code() IS NOT null) 
	OR (get_ku_login_name() IS NOT null) OR (get_ku_email() IS NOT null)) THEN 
		LET l_authentication_env_exists = TRUE 
	END IF 


	IF (l_authentication_env_exists = TRUE) THEN 

		IF authenticated_kandoouser_and_set_globals(get_ku_sign_on_code(),get_ku_password_text()) > 0 THEN --validate authentication 
			LET l_login_user_method = 1 #and SET globals/environment IF successful 

		ELSE #sign_on_code & password combination failed - try <user_code> 

			IF authenticated_kandoouser_and_set_globals(get_ku_login_name(),get_ku_password_text()) > 0 THEN --validate authentication 
				LET l_login_user_method = 2 #and SET globals/environment IF successful 

			ELSE #sign_on_code & user_code failed -> try email address 

				IF main_authenticated_kandoouser_and_set_globals(get_ku_email(),get_ku_password_text()) > 0 THEN --validate authentication 
					LET l_login_user_method = 3 #and SET globals/environment IF successful 
				END IF 
			END IF 
		END IF 

		#authentication in the choosen way/method
		CASE l_login_user_method 
			WHEN 1 --sign_on_code 
				MESSAGE "Authenticate with sign_on_code" 
				IF main_authenticated_kandoouser_and_set_globals(get_ku_sign_on_code(),get_ku_password_text()) > 0 THEN --validate authentication 
					CALL init_kandoouser_environment() #and SET globals/environment IF successful 
				END IF 

			WHEN 2 --user_code 
				MESSAGE "Authenticate with login_name" 
				IF main_authenticated_kandoouser_and_set_globals(get_ku_login_name(),get_ku_password_text()) > 0 THEN --validate authentication 
					CALL init_kandoouser_environment() #and SET globals/environment IF successful 
				END IF 
			WHEN 3 -- email address 
				MESSAGE "Authenticate with email" 
				IF main_authenticated_kandoouser_and_set_globals(get_ku_email(),get_ku_password_text()) > 0 THEN --validate authentication 
					CALL init_kandoouser_environment() #and SET globals/environment IF successful 
				END IF 
			OTHERWISE 
				ERROR "Authentication FROM URL OR Environment failed" 
				LET l_authentication_env_exists = FALSE 
				EXIT program 
		END CASE 
	END IF 

	#no environment OR url credentials.. leads TO login SCREEN
	IF l_authentication_env_exists = FALSE THEN 
		IF get_debug() = TRUE THEN 
			DISPLAY "########### authenticate(p_module_id) - secufunc.4gl ################" 
			DISPLAY "l_authentication_env_exists = FALSE" 
		END IF 

		MESSAGE "Authenticate with Login Dialog" 
		IF NOT login_rec_kandoouser() THEN --login dialog WINDOW TO enter authentication details 
			CALL fgl_winmessage("Authentication failed","Could NOT authenticate user!\nExit Application","error") 
			EXIT program 
		END IF 

	END IF 

	#original kandoo code
	INITIALIZE l_exit_on_start TO NULL 
	IF l_exit_on_start IS NOT NULL THEN 
		EXIT program (l_exit_on_start) 
	END IF 

	# TODO: do we want exit_program_global function ? ericv 2020-09-27
	# WHEN the application receives the SIGTERM signal (only available on UNIX).
	OPTIONS ON terminate signal CALL exit_program_global 

	# application window IS closed by a user action, FOR example, ALT-F4 on Windows clients:
	OPTIONS ON CLOSE application CALL exit_program_global #{stop|continue|call func} 

	CALL set_os_arch() 


	## The following SET stmt IS needed FOR ONLINE but causes a error on SE.
	## Uncomment WHENEVERs IF you really want TO run on SE as well.
	SET ISOLATION TO dirty read 

	LET l_security_role_status = verify_user_role_and_security_level_for_module() 

	CASE l_security_role_status 
		WHEN -1 #user has no access TO this module GROUP 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " but hasn't got access to this module group!" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 

		WHEN -21 #user has insufficient user role 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module! (requires A,M or S)" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 

		WHEN -22 #user has insufficient user role - needs a-administrator OR m-utilitis module manager 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module! (requires A or M)" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 


		WHEN -31 #user has insufficient security level 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module! (W or higher is required)" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 

		WHEN -32 #user has insufficient security level 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module! (X or higher is required)" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 


		WHEN -3 #user has insufficient security level 
			LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 


		WHEN -71 --gzc - company manager requires top security level 
			LET l_msgstr = "High Security risk program requires maximum permissions!\n","Permission Denied! Contact your Kandoo Administrator\n" , 
			"Your user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got user role ", trim(glob_rec_kandoouser.user_role_code), 
			" and the security level ", trim(glob_rec_kandoouser.security_ind), 
			" which are insufficient to operate this module!" 
			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
			EXIT program 

		OTHERWISE 
			IF l_security_role_status < 0 THEN 
				LET l_msgstr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got user role ", trim(glob_rec_kandoouser.user_role_code), 
				" and the security level ", trim(glob_rec_kandoouser.security_ind), 
				" which are insufficient to operate this module!" 
				CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR") 
				EXIT program 

			ELSE 
				MESSAGE "User security level and role validated" 
			END IF 

	END CASE 

	{
	#huho ONLY base name IS wanted without any windows .exe file extension
		LET l_baseProgramID = getModuleId() #get_baseProgName()

	#huho do we still need this ?
	#IF fgl_getenv("KANDOOEXPLAIN") = glob_callingprog THEN
	#   SET explain on
	#END IF

	#CALL set_match_ku_user_sign_on_code_user_code() #temp, until we are done with authentication

		IF get_debug() = TRUE THEN
			DISPLAY "########### authenticate(p_module_id) 50  ################"
			DISPLAY "l_baseProgramID=", trim(l_baseProgramID)
			DISPLAY "END OF FUNCTION"
			DISPLAY "-------------------------------------------------------"
		END IF


	#Beta / Temp / security process is not defined yet
	#Check if user is allowed to use this program modue
	#We may move this code to a different location
	# for now, we only check for the 2nd letter in the prog name "Z"
	#and some specific programs

	#This module must only be used by Administrators with MAX / Z security level
		IF l_baseProgramID[2] = 'Z' THEN #KandooERP config program
			IF (glob_rec_kandoouser.user_role_code != "S") AND (glob_rec_kandoouser.user_role_code != "A") THEN
				LET l_msgStr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has the got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module!"
				CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
				EXIT PROGRAM
			END IF

			IF glob_rec_kandoouser.security_ind < "W" THEN
				LET l_msgStr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!"
				CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
				EXIT PROGRAM
			END IF
		END IF

	#SPECIAL config programs which require superUser/Admin rights
	#Note: Utilities are only to be used by System Administrators
		IF l_baseProgramID[1] = 'U' THEN #OR l_baseProgram[1,3] = 'U12' THEN

			IF glob_rec_kandoouser.user_role_code != "A" THEN  --Admin only
				LET l_msgStr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has the got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module!"
				CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
				EXIT PROGRAM
			END IF

			IF glob_rec_kandoouser.security_ind != "Z" THEN
				LET l_msgStr = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!"
				CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
				EXIT PROGRAM
			END IF


		END IF

	}


	#Return VALUES are NOT really required anymore -
	# left them because of calling func RETURNIN clause
	# it will use cmpy_code with a modules specific GLOBALS
	RETURN 
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code 
END FUNCTION 
##############################################################
# END FUNCTION authenticate(p_module_id)
##############################################################


##############################################################
# FUNCTION verify_user_role_and_security_level_for_module()
#
#
##############################################################
FUNCTION verify_user_role_and_security_level_for_module() 
	DEFINE l_baseprogramid STRING 
	DEFINE l_msgstr STRING 

	## The following SET stmt IS needed FOR ONLINE but causes a error on SE.
	## Uncomment WHENEVERs IF you really want TO run on SE as well.
	WHENEVER ERROR CONTINUE 
	SET ISOLATION TO dirty read 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET l_baseprogramid = getmoduleid() #get_baseprogname() 

	IF get_debug() = TRUE THEN 
		DISPLAY "########### FUNCTION verify_user_role_and_security_level_for_module() ################" 
		DISPLAY "l_baseProgramID=", trim(l_baseProgramID) 
		DISPLAY "l_baseProgramID[1,3]=", trim(l_baseProgramID[1,3]) 
		DISPLAY "-------------------------------------------------------" 
	END IF 

	#Beta / Temp / security process is not defined yet
	#Check if user is allowed to use this program modue
	#We may move this code to a different location
	# for now, we only check for the 2nd letter in the prog name "Z"
	#and some specific programs


	#----------------------------------------#
	# First, we check/validate for all high risks / security programs
	#----------------------------------------#

	IF l_baseprogramid[1,3] matches "GZC" 
	OR l_baseprogramid[1,3] matches "GZ3" 
	OR l_baseprogramid[1,3] matches "GZ4" 
	OR l_baseprogramid[1,3] matches "U12"
	OR l_baseprogramid[1,3] matches "AZU" 
	THEN 
		IF (glob_rec_kandoouser.user_role_code != "A") OR (glob_rec_kandoouser.security_ind < "Z") THEN 
			RETURN -71 
		END IF 
	END IF 


	#This module must only be used by Administrators with MAX / Z security level
	IF l_baseprogramid[2] >= 'Z' THEN #kandooerp config program id uses second letter z i.e. gz1 
		IF (glob_rec_kandoouser.user_role_code != "S") AND (glob_rec_kandoouser.user_role_code != "A") THEN 
			RETURN -21 
		END IF 

		IF glob_rec_kandoouser.security_ind < "W" THEN 
			RETURN -31 #user requires security level higher than "W" 

			#			LET l_msgStr = "Your user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!"
			#			CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
			#			EXIT PROGRAM
		END IF 
	END IF 

	#SPECIAL config programs which require superUser/Admin rights
	#Note: Utilities are only to be used by System Administrators
	IF l_baseprogramid[1] = 'U' THEN #or l_baseprogram[1,3] = 'u12' THEN !!!! utilities !!!! 

		IF (glob_rec_kandoouser.user_role_code != "A") AND (glob_rec_kandoouser.user_role_code != "M") AND (glob_rec_kandoouser.user_role_code != "S")THEN --admin AND module manager only 
			RETURN -22 
			#LET l_msgStr = "Your user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has the got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module!"
			#CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
			#EXIT PROGRAM
		END IF 

		IF (glob_rec_kandoouser.security_ind < "X") THEN 
			RETURN -32 
			#LET l_msgStr = "Your user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!"
			#CALL fgl_winmessage("Insufficient rights",l_msgStr,"ERROR")
			#EXIT PROGRAM
		END IF 


	END IF 


END FUNCTION 
##############################################################
# END FUNCTION verify_user_role_and_security_level_for_module()
##############################################################


##############################################################
# FUNCTION verify_security(p_menu_code)
#
#
##############################################################
FUNCTION verify_security(p_menu_code) 
	DEFINE p_menu_code CHAR(8) #huho no longer used 
	#	DEFINE l_rec_menu3 RECORD LIKE menu3.*
	#	DEFINE l_rec_kandoomodule RECORD LIKE kandoomodule.*
	#	DEFINE l_rec_kandooinfo RECORD LIKE kandooinfo.*
	#	DEFINE x, y SMALLINT
	DEFINE l_tmpmsg STRING 

	#security changes - if the app IS launched with none-authentication, we will prompt a login"

	IF glob_rec_kandoouser.sign_on_code IS NULL THEN #app was launched WITHOUT authentication 
		LET l_tmpmsg = "User ", glob_rec_kandoouser.sign_on_code, " IS NOT authenticated" 
		MESSAGE l_tmpmsg 
		CALL login_rec_kandoouser() --noneauthenticatedlogin() LET sign_on_code = 

		IF glob_rec_kandoouser.sign_on_code IS NULL THEN 
			CALL fgl_winmessage("Could NOT authenticate","Could NOT authenticate user!\nExit Application","error") 
			EXIT program 
		ELSE 

		END IF 
	ELSE 
		LET l_tmpmsg = "User ", glob_rec_kandoouser.sign_on_code CLIPPED, " IS already authenticated" 
		MESSAGE l_tmpmsg 
	END IF 

	#	#HuHo: Note, l_rec_kandooinfo keeps/kept some kind of license information
	#	SELECT kandoo_type INTO l_rec_kandooinfo.kandoo_type FROM kandooinfo  #@huho, in my CASE, I have the value "g"


	RETURN TRUE 
END FUNCTION 
##############################################################
# END FUNCTION verify_security(p_menu_code)
##############################################################


##############################################################
# FUNCTION secu_passwd(p_head_text,p_passwd_text)
#
#
##############################################################
FUNCTION secu_passwd(p_head_text,p_passwd_text) 
	##
	## secu_pasword.
	## Generic FUNCTION which gives users three chances TO enter invisibly
	## a given password.  FUNCTION returns TRUE OR FALSE pending on result.
	## Used by security AND main menu program AND available FOR any others.
	##
	DEFINE p_head_text LIKE menu1.name_text
	DEFINE p_passwd_text CHAR(20) 
	DEFINE l_pmpt_text CHAR(32) 
	DEFINE l_resp_text CHAR(20) 
	DEFINE l_char CHAR(1) 
	DEFINE x,y SMALLINT
	DEFINE r_ret_ind SMALLINT 

	LET r_ret_ind = FALSE 

	IF p_passwd_text IS NULL OR length(p_passwd_text) = 0 THEN 
		LET r_ret_ind = TRUE 
	ELSE 

		OPEN WINDOW wpasswd with FORM "U130" #at 10,20 with 3 ROWS, 40 COLUMNS #attribute(border) 
		CALL winDecoration_u("U130") 

		#DISPLAY "Password Entry" AT 1,13 ATTRIBUTE(yellow)
		#LET x = (40-(length(p_head_text)))/2
		DISPLAY p_head_text TO pr_head_text #at 2,x 

		FOR y = 1 TO 3 
			LET l_resp_text = NULL 
			LET l_pmpt_text = " Password: " 

			#FOR x = 1 TO 20
			INPUT BY NAME l_resp_text WITHOUT DEFAULTS --l_char CHAR(1) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","secufunc","input-l_resp_text-1") -- albo kd-511 

				ON ACTION "WEB-HELP" -- albo kd-378 
					CALL onlinehelp(getmoduleid(),null) 

			END INPUT 

			#LET  l_char =  l_resp_text
			#  prompt l_pmpt_text CLIPPED FOR CHAR l_char
			IF l_char IS NOT NULL THEN 
				LET l_resp_text[x] = l_char 
				LET l_pmpt_text = l_pmpt_text CLIPPED,"*" 
			ELSE 
				EXIT FOR 
			END IF 
			#END FOR

			CASE 
				WHEN l_resp_text = p_passwd_text ## correct 
					LET r_ret_ind = TRUE 
					EXIT FOR 

				WHEN y = 3 ## RUN out OF permitted attempts 
					CALL set_msgresp(kandoomsg("U",5002,p_head_text)) 
					LET r_ret_ind = FALSE 
					EXIT FOR 

				OTHERWISE ## incorrect - try again 
					CALL set_msgresp(kandoomsg("U",9002,"")) 
			END CASE 

		END FOR 

		CLOSE WINDOW wpasswd 
	END IF 

	RETURN r_ret_ind 
END FUNCTION 
##############################################################
# END FUNCTION secu_passwd(p_head_text,p_passwd_text)
##############################################################


##############################################################
# FUNCTION xlate_from(p_z)
#
# huho 13.04.2019 changed so we no longer require the GLOBALS glob_language record
##############################################################
# FIXME: is this the right location ?? better would be in localisation ?
FUNCTION xlate_from(p_z) 
	DEFINE p_z CHAR(1) 
	DEFINE key_response LIKE language.yes_flag 

	CASE p_z 
		WHEN "Y" 
			SELECT language.yes_flag INTO key_response 
			FROM language 
			WHERE language.language_code = glob_rec_kandoouser.language_code 
			RETURN key_response 
			#RETURN glob_language.yes_flag
		WHEN "N" 
			SELECT language.no_flag INTO key_response 
			FROM language 
			WHERE language.language_code = glob_rec_kandoouser.language_code 
			RETURN key_response 
			# RETURN glob_language.no_flag
		OTHERWISE 
			RETURN "" 
	END CASE 
END FUNCTION 
##############################################################
# END FUNCTION xlate_from(p_z)
##############################################################

##############################################################
# FUNCTION run_prog_with_url_arg(p_prog_name,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
#	RETURN l_success BOOLEAN 
#
# Wrapper function for run_prog() which forms the 4 argumnents for URL token compatiblity
##############################################################
FUNCTION run_prog_with_url_arg(p_prog_name,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
	DEFINE p_prog_name STRING 
	DEFINE p_arg1_name STRING 
	DEFINE p_arg1_value STRING 
	DEFINE p_arg2_name STRING 
	DEFINE p_arg2_value STRING 
	DEFINE p_arg3_name STRING 
	DEFINE p_arg3_value STRING 
	DEFINE p_arg4_name STRING 
	DEFINE p_arg4_value STRING
	DEFINE l_prog_arg1 STRING
	DEFINE l_prog_arg2 STRING
	DEFINE l_prog_arg3 STRING
	DEFINE l_prog_arg4 STRING
	DEFINE l_success BOOLEAN #status if program could be executed

	IF p_arg1_name IS NOT NULL THEN
		LET l_prog_arg1 = trim(p_arg1_name), "=", trim(p_arg1_value)
	END IF 
	IF p_arg2_name IS NOT NULL THEN
		LET l_prog_arg2 = trim(p_arg2_name), "=", trim(p_arg2_value)
	END IF
	IF p_arg3_name IS NOT NULL THEN 
		LET l_prog_arg3 = trim(p_arg3_name), "=", trim(p_arg3_value)
	END IF
	IF p_arg4_name IS NOT NULL THEN 
		LET l_prog_arg4 = trim(p_arg4_name), "=", trim(p_arg4_value)
	END IF 

	CALL run_prog(p_prog_name,l_prog_arg1,l_prog_arg2,l_prog_arg3,l_prog_arg4) RETURNING l_success
	 
	RETURN l_success
END FUNCTION 
##############################################################
# END FUNCTION run_prog_with_url_arg(p_prog_name,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
##############################################################


##############################################################
# FUNCTION run_prog_with_url_arg(p_prog_name,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
#	RETURN l_success BOOLEAN 
#
# Wrapper function for run_prog() which forms the 4 argumnents for URL token compatiblity
##############################################################
FUNCTION run_prog_with_wait_status_and_url_arg(p_prog_name,p_wait_status,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
	DEFINE p_wait_status BOOLEAN
	DEFINE p_prog_name STRING 
	DEFINE p_arg1_name STRING 
	DEFINE p_arg1_value STRING 
	DEFINE p_arg2_name STRING 
	DEFINE p_arg2_value STRING 
	DEFINE p_arg3_name STRING 
	DEFINE p_arg3_value STRING 
	DEFINE p_arg4_name STRING 
	DEFINE p_arg4_value STRING
	DEFINE l_prog_arg1 STRING
	DEFINE l_prog_arg2 STRING
	DEFINE l_prog_arg3 STRING
	DEFINE l_prog_arg4 STRING
	DEFINE l_success BOOLEAN #status if program could be executed

	IF p_arg1_name IS NOT NULL THEN
		LET l_prog_arg1 = trim(p_arg1_name), "=", trim(p_arg1_value)
	END IF 
	IF p_arg2_name IS NOT NULL THEN
		LET l_prog_arg2 = trim(p_arg2_name), "=", trim(p_arg2_value)
	END IF
	IF p_arg3_name IS NOT NULL THEN 
		LET l_prog_arg3 = trim(p_arg3_name), "=", trim(p_arg3_value)
	END IF
	IF p_arg4_name IS NOT NULL THEN 
		LET l_prog_arg4 = trim(p_arg4_name), "=", trim(p_arg4_value)
	END IF 

	RETURN run_prog_with_wait_option(p_prog_name,p_wait_status,l_prog_arg1,l_prog_arg2,l_prog_arg3,l_prog_arg4)

END FUNCTION 
##############################################################
# END FUNCTION run_prog_with_url_arg(p_prog_name,p_arg1_name,p_arg1_value,p_arg2_name,p_arg2_value,p_arg3_name,p_arg3_value,p_arg4_name,p_arg4_value)
##############################################################


##############################################################
# FUNCTION run_prog(p_prog,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code)
# HuHo 22.04.2020
# Note: Have removed ANY kind of menu-security check for this function as it's total nonsense
##############################################################
FUNCTION run_prog(p_prog,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code)
	DEFINE p_prog STRING #char(15)  
	DEFINE p_arg1_code STRING #char(250) 
	DEFINE p_arg2_code STRING #char(250) 
	DEFINE p_arg3_code STRING #char(250) 
	DEFINE p_arg4_code STRING #char(250)
	
	RETURN run_prog_with_wait_option(p_prog,TRUE,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code) 

END FUNCTION

##############################################################
# FUNCTION run_prog_with_wait_option(p_prog,p_wait_status,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code) 
# HuHo 22.04.2020
# Note: Have removed ANY kind of menu-security check for this function as it's total nonsense
##############################################################
FUNCTION run_prog_with_wait_option(p_prog,p_wait_status,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code) 
	DEFINE p_prog STRING #char(15) 
	DEFINE p_wait_status BOOLEAN
	DEFINE p_arg1_code STRING #char(250) 
	DEFINE p_arg2_code STRING #char(250) 
	DEFINE p_arg3_code STRING #char(250) 
	DEFINE p_arg4_code STRING #char(250)
	DEFINE l_base_prg STRING 
	DEFINE l_run_text STRING 
--	DEFINE l_kandoodir_text CHAR(100) 
--	DEFINE l_infdir_text CHAR(100) 
--	DEFINE l_run_text_search CHAR(100) 
--	DEFINE l_save_text CHAR(10) 
	DEFINE l_cmd_line STRING 
--	DEFINE l_name_text CHAR(100) 
	DEFINE l_program_is_valid SMALLINT 
	DEFINE l_msg STRING 
--	DEFINE l_prog_name STRING 
	--DEFINE l_parent_module_id STRING
	DEFINE l_success BOOLEAN
	
	IF get_debug() THEN  
		DISPLAY "Launch External Program" 
		DISPLAY "Program Name:", trim(p_prog) 
		DISPLAY "Program Argument 1:", trim(p_arg1_code) 
		DISPLAY "Program Argument 2:", trim(p_arg2_code) 
		DISPLAY "Program Argument 3:", trim(p_arg3_code) 
		DISPLAY "Program Argument 4:", trim(p_arg4_code)
		DISPLAY "PROG_PARENT:", trim(get_prog_id())
		DISPLAY "MODULE_PARENT:", trim(get_module_id())		
	END IF 

	#LET l_parent_module_id = get_parent_module_id() #getmoduleid() --p_menu_code[1,3] 

	##
	## Sets up the command line
	##
	#LET p_prog = os.path.rootname(p_prog) 
	LET p_prog = os.path.basename(p_prog) 
	LET l_base_prg = p_prog
	# add .exe for windows programs
	IF get_os_arch() THEN 
		LET p_prog = trim(p_prog), ".exe" 
	ELSE 
		LET p_prog = trim(p_prog) 
	END IF 

	# check IF file.program exists
	# comment FOR now... LET l_file_is_valid = file_valid(l_run_text)
	LET l_program_is_valid = FALSE #if file exists AND IS executable, we will SET it TO TRUE 
	IF NOT os.path.exists(p_prog) THEN 
		LET l_msg = "The program file ", trim(p_prog), " does NOT exist on your application server!" 
		CALL fgl_winmessage("Program does NOT exist",l_msg,"error") 
	ELSE 
		#check if file IS executable
		IF NOT os.path.executable(p_prog) THEN 
			LET l_msg = "The program file ", trim(p_prog), " IS NOT executable ! Check your user/file permissions!" 
			CALL fgl_winmessage("Program does NOT executable",l_msg,"error") 
		ELSE 
			LET l_program_is_valid = TRUE 
		END IF 
	END IF 
	
	IF l_program_is_valid THEN 
		LET l_msg = getmenuitemlabel(l_base_prg[1,3]) 
		IF l_msg IS NOT NULL THEN 
			LET l_msg = "Launching ", l_msg 
			MESSAGE l_msg 
		END IF 

		#HuHo Add user authentication for sub-module
		IF get_os_arch() THEN 
			LET l_cmd_line = "SET KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && SET KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && SET KANDOODB=", trim(get_ku_database_name()), " && ", trim(p_prog) 
		ELSE 
			LET l_cmd_line = "export KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && export KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && export KANDOODB=", trim(get_ku_database_name()) ," && ", trim(p_prog) 
		END IF 
		
		IF get_debug() THEN 
			DISPLAY "RUN ", trim(l_cmd_line) 
		END IF 
		#Add calling (parent) program module_id
		#LET l_cmd_line = trim(l_cmd_line), " PROG_CHILD=", trim(l_parent_module_id) #append to all run prog calls the calling program name #old
		LET l_cmd_line = trim(l_cmd_line), " PROG_PARENT=", trim(get_prog_id()) #append to all run prog calls the calling program name
		LET l_cmd_line = trim(l_cmd_line), " MODULE_PARENT=", trim(get_module_id()) #append to all run prog calls the calling module name
		IF get_debug() THEN 
			DISPLAY "RUN ", trim(l_cmd_line) 
		END IF 

		#Add the optional 4 arguments

		IF p_arg1_code IS NOT NULL THEN
			LET l_cmd_line = l_cmd_line, " ", p_arg1_code
		END IF
		IF p_arg2_code IS NOT NULL THEN
			LET l_cmd_line = l_cmd_line, " ", p_arg2_code
		END IF
		IF p_arg3_code IS NOT NULL THEN
			LET l_cmd_line = l_cmd_line, " ", p_arg3_code
		END IF
		IF p_arg4_code IS NOT NULL THEN
			LET l_cmd_line = l_cmd_line, " ", p_arg4_code
		END IF
		 
		IF get_debug() THEN 
			DISPLAY "FINAL RUN ", trim(l_cmd_line) 
		END IF
		
		
	###############################################################################################
	# Actual RUN
		IF p_wait_status THEN #WITH WAITING
			RUN l_cmd_line
		ELSE
			RUN l_cmd_line WITHOUT WAITING		
		END IF  
		LET l_success = TRUE
		CALL displaymoduletitle(NULL) 
	# END OF Actual RUN
	###############################################################################################
		
	ELSE
		LET l_msg = "Could not launch program ", p_prog, "\n", l_cmd_line
		CALL fgl_winmessage("Error Launching",l_msg,"ERROR")
		LET l_success = FALSE
	END IF	
	#not required - child program/process can not manipulate parent module_id
	#CALL setmoduleid(l_parent_module_id) #Child application may update mdi program title - needs to be reset when we return to parent
	
	RETURN l_success
	
END FUNCTION 
##############################################################
# END FUNCTION run_prog(p_prog,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code)
##############################################################


{

##############################################################
# FUNCTION run_prog(p_menu_code,  p_arg1_code, p_arg2_code,p_arg3_code,p_arg4_code)
#
#
##############################################################
FUNCTION run_prog(p_menu_code,p_arg1_code,p_arg2_code,p_arg3_code,p_arg4_code) 
	DEFINE p_menu_code STRING #char(15) 
	DEFINE p_arg1_code STRING #char(250) 
	DEFINE p_arg2_code STRING #char(250) 
	DEFINE p_arg3_code STRING #char(250) 
	DEFINE p_arg4_code STRING #char(250) 
	DEFINE l_menu1_code CHAR(1) 
	DEFINE l_menu2_code CHAR(1) 
	DEFINE l_rec_menu3_code CHAR(1) 
	DEFINE l_arr2_run_text ARRAY[2,4] OF CHAR(250) 
	DEFINE l_run_text STRING 
	DEFINE l_kandoodir_text CHAR(100) 
	DEFINE l_infdir_text CHAR(100) 
	DEFINE l_run_text_search CHAR(100) 
	DEFINE l_save_text CHAR(10) 
	DEFINE l_cmd_line STRING 
	DEFINE l_runner CHAR(200) 
	DEFINE l_scwork CHAR(200) 
	DEFINE l_rec_menu4 RECORD LIKE menu4.* 
	DEFINE l_rec_menu3 RECORD LIKE menu3.* 
	DEFINE l_arg_cnt INTEGER 
	DEFINE l_suse_flag INTEGER 
	DEFINE l_status INTEGER 
	DEFINE l_idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_arr_size SMALLINT 
	DEFINE l_arr_run4_text ARRAY[30] OF LIKE menu4.run_text 
	DEFINE l_arr_rec_menu4 ARRAY[30] OF 
	RECORD 
		answer CHAR(1), 
		menu4_code LIKE menu4.menu4_code, 
		name_text LIKE menu4.name_text 
	END RECORD 
	DEFINE l_abbr_code CHAR(3) 
	DEFINE l_temp_text CHAR(100) 
	DEFINE l_name_text CHAR(100) 
	DEFINE l_program_is_valid SMALLINT 
	DEFINE l_msgstr STRING 
	DEFINE l_prog_name STRING 
	DEFINE i INTEGER 
	DEFINE j INTEGER 
	DEFINE x SMALLINT 
	
	IF get_kandooinfo() THEN 
		DISPLAY "Launch External Program" 
		DISPLAY "Program Name:", trim(p_menu_code) 
		DISPLAY "Program Argument 1:", trim(p_arg1_code) 
		DISPLAY "Program Argument 2:", trim(p_arg2_code) 
		DISPLAY "Program Argument 3:", trim(p_arg3_code) 
		DISPLAY "Program Argument 4:", trim(p_arg4_code) 
	END IF 

	LET l_abbr_code = getmoduleid() --p_menu_code[1,3] 

	DECLARE c_menu4 CURSOR FOR 
	SELECT * 
	FROM menu4 
	WHERE menu_code = l_abbr_code 
	ORDER BY menu4_code 
	LET l_idx=0 

	FOREACH c_menu4 INTO l_rec_menu4.* #athe 4th level MENU IS the execution ?? 
		LET l_idx=l_idx+1 
		##### Set up default name IF menu 3 entry IS non standard menu path
		IF l_idx = 1 THEN 
			LET l_name_text = l_rec_menu4.name_text CLIPPED, " (",p_menu_code[1,3] CLIPPED, ")" 
		END IF 
		LET l_arr_rec_menu4[l_idx].answer = NULL 
		LET l_arr_rec_menu4[l_idx].menu4_code = l_rec_menu4.menu4_code 
		LET l_arr_rec_menu4[l_idx].name_text = l_rec_menu4.name_text 
		LET l_arr_run4_text[l_idx] = l_rec_menu4.run_text 
		IF l_idx=30 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	INITIALIZE l_run_text TO NULL 

	IF l_idx>1 THEN #huho do NOT think we NEED this 
		## need TO DISPLAY the optional menu4 programs
		#		IF glob_callingprog = "TOPMENUR" THEN
		#		OPEN WINDOW wU156 WITH FORM "U156"
		#			ATTRIBUTE(border,white)
		#				CALL windecoration_u("U156")
		#		ELSE
		OPEN WINDOW wu156 with FORM "U156" 
		#			ATTRIBUTE(border,white,form line 1)
		CALL windecoration_u("U156") 
		#		END IF
		## Collect the Heading FOR this Window
		LET l_menu1_code = p_menu_code[1,1] 
		LET l_menu2_code = p_menu_code[2,2] 
		LET l_rec_menu3_code = p_menu_code[3,3] 
		SELECT * INTO l_rec_menu3.* 
		FROM menu3 
		WHERE menu1_code = l_menu1_code 
		AND menu2_code = l_menu2_code 
		AND menu3_code = l_rec_menu3_code 
		#		IF STATUS != NOTFOUND THEN
		#			IF glob_callingprog = "TOPMENUR" THEN
		#				LET l_name_text = l_rec_menu3.name_text CLIPPED, " (",p_menu_code[1,3] CLIPPED, ")"
		#			ELSE
		#				LET l_name_text = l_rec_menu3.name_text CLIPPED, " (",glob_callingprog[1,3] CLIPPED, ")"
		#			END IF
		#		END IF
		LET x = (43 - length(l_name_text))/2 
		IF x < 1 THEN 
			LET x = 1 
		END IF 
		LET l_name_text = x spaces,l_name_text[1, 43 - x] 
		DISPLAY l_name_text TO menu_name attribute(yellow) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET l_arr_size = l_idx 
		CALL set_count(l_arr_size) 
		#		CALL fgl_keysetlabel("control-u","Program Path") #huho: this needs fully changing...

		INPUT ARRAY l_arr_rec_menu4 WITHOUT DEFAULTS FROM sa_menu4.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","secufunc","input-arr-menu4")
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
				
			ON KEY (control-u) 
				LET l_temp_text = "Program :",l_arr_run4_text[l_idx] CLIPPED 
				CALL kandooDialog2("U",1,l_temp_text) 
				NEXT FIELD answer
				 
			BEFORE ROW 
				LET l_idx = arr_curr() 
				#				LET scrn = scr_line()
				#				DISPLAY l_arr_rec_menu4[l_idx].* TO sa_menu4[scrn].*

			AFTER FIELD answer 
				IF arr_curr() = arr_count() 
				AND fgl_lastkey() = fgl_keyval("down") 
				THEN 
					CALL set_msgresp(kandoomsg("U",9001,"")) 
					NEXT FIELD answer 
				END IF
				 
			BEFORE FIELD id 
				LET l_rec_menu4.menu4_code = l_arr_rec_menu4[l_idx].answer 
				IF l_rec_menu4.menu4_code IS NULL 
				OR l_rec_menu4.menu4_code = " " 
				THEN 
					LET l_rec_menu4.menu4_code = l_arr_rec_menu4[l_idx].menu4_code 
				END IF 
				SELECT * INTO l_rec_menu4.* 
				FROM menu4 
				WHERE menu_code = l_abbr_code 
				AND menu4_code = l_rec_menu4.menu4_code 
				IF status = 0 THEN 
					LET l_run_text = l_rec_menu4.run_text CLIPPED 
					EXIT INPUT 
				END IF 
			AFTER ROW 
				LET l_arr_rec_menu4[l_idx].answer = NULL 
				#				IF l_idx <= l_arr_size THEN
				#					DISPLAY l_arr_rec_menu4[l_idx].* TO sa_menu4[scrn].*
				#				END IF
		END INPUT 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			CLOSE WINDOW wu156 
			RETURN 
		ELSE 
			CLOSE WINDOW wu156 
		END IF 
	ELSE 
		IF l_idx=1 THEN 
			LET l_run_text = l_arr_run4_text[l_idx] CLIPPED 
		END IF 
	END IF 
	##
	## Sets up the 1st dimension
	##
	## This logic extracts any run time arguments
	## FROM the menu3.run_text COLUMN.  This IS peformed by searching
	## FOR a space AND inserting each value up TO the space INTO the
	## l_arr2_run_text ARRAY (1st dimension). Up TO four arguments are permitted.
	## The arguments passed TO the FUNCTION are stored in the 2nd dimension.
	##
	IF length(l_run_text) = 0 THEN 
		LET j = 0 
		FOR i = 1 TO length(p_menu_code) 
			IF p_menu_code[i,i] != " " THEN 
				IF j = 0 THEN 
					LET l_run_text = l_run_text CLIPPED,p_menu_code[i,i] 
				ELSE 
					LET l_arr2_run_text[1,j] = l_arr2_run_text[1,j] CLIPPED, p_menu_code[i,i] 
				END IF 
			ELSE 
				IF length(p_menu_code[i,10]) > 0 THEN 
					LET j = j + 1 
				END IF 
			END IF 
		END FOR 
	END IF 
	##
	## Sets up the 2nd dimension
	##
	LET l_arr2_run_text[2,1] = p_arg1_code 
	LET l_arr2_run_text[2,2] = p_arg2_code 
	LET l_arr2_run_text[2,3] = p_arg3_code 
	LET l_arr2_run_text[2,4] = p_arg4_code 
	##
	## Override the 1st Dim. with the second only IF 2nd contains a value
	##
	LET l_arg_cnt = 0 
	FOR i = 1 TO 4 
		IF l_arr2_run_text[2,i] IS NOT NULL THEN 
			LET l_arr2_run_text[1,i] = l_arr2_run_text[2,i] 
		END IF 
		IF l_arr2_run_text[1,i] IS NOT NULL THEN 
			LET l_arg_cnt = i 
		END IF 
	END FOR 
	##
	## Sets up the command line
	##
	LET l_kandoodir_text = fgl_getenv("KANDOODIR") 
	LET l_infdir_text = fgl_getenv("INFORMIXDIR") 
	LET i = length(l_run_text) 
	LET l_save_text = NULL 
	#	IF l_SUSE_flag THEN #### Must be running <Suse>
	#		IF length(l_run_text) > 3 THEN
	#	ELSE
	#		LET l_runner = fgl_getenv("FGLRUN")
	#		IF length(l_runner) = 0 THEN
	#			LET l_runner = "fglrun"
	#		END IF
	### FOR compatibility with pos
	#		LET l_save_text = l_run_text CLIPPED
	#		LET l_run_text =l_kandoodir_text CLIPPED,"/gprog/", l_run_text CLIPPED,".42r"
	#	END IF
	#	ELSE #NOT running <Suse> - Querix, <Anton Dickinson> OR Informix
	#@huho 27.08.2018 change TO base name function
	#LET l_run_text = l_run_text[1,length(l_run_text)-length(os.Path.extension(l_run_text))-1]  --additional -1 FOR the dot between base name AND extension
	LET l_run_text = os.path.rootname(l_run_text) 
	LET l_run_text = os.path.basename(l_run_text) 
	# add .exe for windows programs
	IF get_os_arch() THEN 
		LET l_run_text = trim(l_run_text), ".exe" 
		LET l_prog_name = trim(l_run_text) 
	ELSE 
		LET l_prog_name = trim(l_run_text) 
	END IF 
	FOR i = 1 TO 4 #huho: what IS this FOR ????? 
		LET l_run_text = trim(l_run_text), " ", trim(l_arr2_run_text[1,i]) 
	END FOR 
	#	END IF
	# check IF file.program exists
	# comment FOR now... LET l_file_is_valid = file_valid(l_run_text)
	LET l_program_is_valid = FALSE #if file exists AND IS executable, we will SET it TO TRUE 
	IF NOT os.path.exists(l_prog_name) THEN 
		LET l_msgstr = "The program file ", trim(l_prog_name), " does NOT exist on your application server!" 
		CALL fgl_winmessage("Program does NOT exist",l_msgStr,"error") 
	ELSE 
		#check if file IS executable
		IF NOT os.path.executable(l_prog_name) THEN 
			LET l_msgstr = "The program file ", trim(l_prog_name), " IS NOT executable ! Check your user/file permissions!" 
			CALL fgl_winmessage("Program does NOT executable",l_msgStr,"error") 
		ELSE 
			LET l_program_is_valid = TRUE 
		END IF 
	END IF 
	IF l_program_is_valid THEN 
		LET l_status = 0 
		LET l_cmd_line= trim(l_run_text) 
		LET l_msgstr = getmenuitemlabel(l_cmd_line[1,3]) 
		IF l_msgstr IS NOT NULL THEN 
			LET l_msgstr = "Launching ", l_msgstr 
			MESSAGE l_msgstr 
		END IF 
		#HuHo Add user authentication for sub-module
		IF get_os_arch() THEN 
			LET l_cmd_line = "SET KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && SET KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && SET KANDOODB=", trim(get_ku_database_name()), " && ", trim(l_cmd_line) 
		ELSE 
			LET l_cmd_line = "export KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && export KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && export KANDOODB=", trim(get_ku_database_name()) ," && ", trim(l_cmd_line) 
		END IF 
		IF get_debug() THEN 
			DISPLAY "RUN ", trim(l_cmd_line) 
		END IF 
		LET l_cmd_line = trim(l_cmd_line), " PROG_CHILD=", trim(os.Path.basename(base.Application.getProgramName())) #append to all run prog calls the calling program name
		--IF get_debug() THEN 
			DISPLAY "RUN ", trim(l_cmd_line) 
		--END IF 
		RUN trim(l_cmd_line) --huho removed WITHOUT waiting 
		LET status = 33280 --huho 
		#RUN trim(l_cmd_line) RETURNING l_status
		IF l_status = 33280 #hp 
		OR l_status = 32512 #hp 
		OR l_status = 53248 #sun 
		THEN 
			#			do nothing
		ELSE 
			IF l_status != 0 THEN 
				IF l_status / 256 = 4 THEN 
					EXIT program 
				END IF 
				LET l_msgstr = 'above ERROR in "',l_run_text CLIPPED, '" was encountered BY "', glob_rec_kandoouser.sign_on_code CLIPPED, '"' 
				CALL errorlog(l_msgstr) 
			END IF 
		END IF 
		#	ELSE
		#		ERROR trim(l_run_text), " does NOT exist OR IS NOT executable!"
		#		CALL set_msgresp(kandoomsg("U",9000,l_run_text))
		#		9000 OS file <l_run_text> NOT found
	END IF 
END FUNCTION 
}
##############################################################
# FUNCTION file_valid(p_file_name)
#
#
##############################################################
#FIXME: certainly not in the right place
FUNCTION file_valid(p_file_name) 
	DEFINE p_file_name CHAR(100) 
	DEFINE l_runner CHAR(400) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_kandoo_log CHAR(120) 

	#WARNING - RUN command using i4gl (at least) will stop working WHEN SHELL IS SET TO "sh"
	#RETURN code FOR all commands will be 32512. But I see we are using envirinment variable
	#called SHELL in other placae in 4gl code - invitation FOR trouble?

	#call fgl_winmessage("should no longer be used OR re-write","should no longer be used OR re-write","info")
	INITIALIZE l_kandoo_log TO NULL 

	LET l_kandoo_log=fgl_getenv("l_kandoo_log") 

	IF (l_kandoo_log IS null) OR (length(l_kandoo_log) < 2) THEN 
		LET l_kandoo_log ="data/reports/l_kandoo_log" 
	END IF 

	#   LET l_runner = " [  -f ",p_file_name CLIPPED,"",
	#                " -a -r ",p_file_name CLIPPED,"",
	#                " -a -s ",p_file_name CLIPPED," ] 2>> ",l_kandoo_log

	#  CALL fgl_winmessage("run","run4","info")

	#   run l_runner returning l_ret_code

	IF os.path.exists(p_file_name) THEN --huho added FOR program CHECK 
		IF os.path.executable(p_file_name) THEN 
			LET l_ret_code = TRUE 
		END IF 
	END IF #huho END OF my code 

	IF l_ret_code THEN 
		CALL fgl_winmessage(p_file_name,"File does NOT exist OR has no permission TO execute","error") 
		RETURN FALSE 

	ELSE 
		MESSAGE "Launching ", p_file_name 
		RUN p_file_name WITHOUT waiting 
		RETURN TRUE 
	END IF 
END FUNCTION 
##############################################################
# END FUNCTION file_valid(p_file_name)
##############################################################


##############################################################
# FUNCTION showdate (p_init_date)
#
#
##############################################################
FUNCTION showdate (p_init_date) 
	DEFINE p_init_date DATE # DATE as initially called 
	DEFINE l_edit_date DATE # DATE as entered OR editted 
	DEFINE l_editday_num SMALLINT # day number OF edit month 
	DEFINE l_first_date DATE # FIRST DATE OF edit month 
	DEFINE l_firstday_num SMALLINT # day OF week OF FIRST DATE 
	DEFINE l_last_date DATE # LAST DATE OF edit month 
	DEFINE l_lastday_num SMALLINT # number OF days in edit month 
	DEFINE l_day_num SMALLINT # day OF month in calendar 
	DEFINE l_day_text CHAR(4) # day OF month as text 
	DEFINE l_min_date DATE # minimum valid date: 01/01/0001 
	DEFINE l_kandoo_date DATE # maximum valid date: 31/12/9999 
	DEFINE l_row_num SMALLINT # ROW offset OF calendar DISPLAY 
	DEFINE l_col_num SMALLINT # col offset OF calendar DISPLAY 
	DEFINE l_gap_num SMALLINT # col spacing OF calendar DISPLAY 
	DEFINE l_change_ind CHAR(1) # change DATE COMMAND code 
	DEFINE l_month_date CHAR(8) # mmm yyyy FORMAT 
	DEFINE i, j, x, y SMALLINT # WORK variables FOR calendar

	OPEN WINDOW u526 with FORM "U526" 
	CALL winDecoration_u("U526") 

	CALL set_msgresp(kandoomsg("U",1020,"Date")) 
	LET l_min_date = mdy(01,01,0001) 
	LET l_kandoo_date = mdy(12,31,9999) 
	LET l_row_num = 10 
	LET l_col_num = 44 
	LET l_gap_num = 4 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	LET l_change_ind = "I" 

	IF p_init_date IS NULL THEN 
		LET p_init_date = today 
	END IF 

	LET l_edit_date = p_init_date 

	WHILE l_change_ind != "\\" AND NOT int_flag 
		CASE l_change_ind 
			WHEN "I" 
				LET l_edit_date = p_init_date 
			WHEN "T" 
				LET l_edit_date = today 
			WHEN "P" 
				LET l_edit_date = l_edit_date - 1 
			WHEN "N" 
				LET l_edit_date = l_edit_date + 1 
			WHEN "F" 
				LET l_edit_date = l_first_date 
			WHEN "L" 
				LET l_edit_date = l_last_date 
			WHEN "B" 
				LET l_edit_date = l_edit_date - weekday(l_edit_date) 
			WHEN "E" 
				LET l_edit_date = l_edit_date + 6 - weekday(l_edit_date) 
			WHEN "-" 
				LET l_edit_date = l_edit_date - 7 
			WHEN "+" 
				LET l_edit_date = l_edit_date + 7 
			WHEN "<" 
				LET l_edit_date = l_edit_date - 1 units month 
			WHEN ">" 
				LET l_edit_date = l_edit_date + 1 units month 
			WHEN "(" 
				LET l_edit_date = l_edit_date - 1 units year 
			WHEN ")" 
				LET l_edit_date = l_edit_date + 1 units year 
			WHEN " " 



				INPUT l_edit_date WITHOUT DEFAULTS FROM edit_date 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","secufunc","input-edit_date") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END INPUT 

				LET int_flag = FALSE 

			OTHERWISE 
				ERROR ""# just beep! 

		END CASE 


		CASE # ensure DATE IS still within valid range... 
			WHEN l_edit_date IS NULL 
				LET l_edit_date = null#i.e. 31/12/1899 
				ERROR "" 
			WHEN l_edit_date < l_min_date 
				LET l_edit_date = l_min_date 
				ERROR "" 
			WHEN l_edit_date > l_kandoo_date 
				LET l_edit_date = l_kandoo_date 
				ERROR "" 
		END CASE 

		LET l_editday_num = day(l_edit_date) 
		LET l_first_date = l_edit_date - l_editday_num + 1 
		LET l_firstday_num = weekday(l_first_date) 
		LET l_last_date = l_first_date + 1 units month 
		LET l_last_date = l_last_date - 1 
		LET l_lastday_num = day(l_last_date) 
		LET l_month_date = l_edit_date USING "mmm yyyy" 

		DISPLAY l_month_date TO month_date 

		FOR i = 0 TO 5 # weeks in calendar month ROWS 

			FOR j = 0 TO 6 # days in calendar week COLUMNS 
				# Compute day number FOR this position...
				LET l_day_num = (i * 7) + j - l_firstday_num + 1 
				# Bracket current day AND blank unused positions...

				CASE 
					WHEN l_day_num < 1 
						LET l_day_num = 0 
					WHEN l_day_num = l_editday_num 
						LET l_day_num = 0 - l_day_num 
					WHEN l_day_num > l_lastday_num 
						LET l_day_num = 0 
				END CASE 

				LET l_day_text = l_day_num USING "((#)" 
				# Determine position in window TO DISPLAY at...
				LET x = l_row_num + i 
				LET y = l_col_num + (j * l_gap_num) 

				IF l_day_num * -1 = l_editday_num THEN 
					#DISPLAY l_day_text AT x, y
					MESSAGE l_day_text 

				ELSE 
					IF j >= 1 AND j <= 5 THEN # its a weekday 
						#DISPLAY l_day_text AT x, y ATTRIBUTE(yellow)
						ERROR l_day_text 
					ELSE 
						#DISPLAY l_day_text AT x, y
						MESSAGE l_day_text 
					END IF 
				END IF 
			END FOR 

		END FOR 

		DISPLAY l_edit_date TO edit_date 

		INPUT l_change_ind WITHOUT DEFAULTS FROM change_ind 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","secufunc","input-change_ind") 


			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 



			AFTER FIELD change_ind# prevents NULL value 
				LET l_change_ind = get_fldbuf(change_ind) 
				IF l_change_ind IS NULL THEN 
					LET l_change_ind = " " 
				END IF 

			ON KEY (left) # previous day 
				LET l_change_ind = "P" 
				EXIT INPUT 

			ON KEY (right) # NEXT day 
				LET l_change_ind = "N" 
				EXIT INPUT 

			ON KEY (up) # previous week 
				LET l_change_ind = "-" 
				EXIT INPUT 

			ON KEY (down) # NEXT week 
				LET l_change_ind = "+" 
				EXIT INPUT 

			ON KEY (F3)#prevpage - previous month 
				LET l_change_ind = ">" 
				EXIT INPUT 

			ON KEY (F4)#nextpage - NEXT month 
				LET l_change_ind = "<" 
				EXIT INPUT 

			ON KEY (tab) # manually edit DATE 
				LET l_change_ind = " " 
				EXIT INPUT 

			ON KEY (accept)# EXIT - needed due TO autonext 
				LET l_change_ind = "\\" 
				EXIT INPUT 



		END INPUT 

		DISPLAY l_change_ind TO change_ind 

	END WHILE 

	CLOSE WINDOW u526 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_edit_date = p_init_date 
	END IF 

	RETURN l_edit_date 

END FUNCTION 
##############################################################
# END FUNCTION showdate (p_init_date)
##############################################################


##############################################################
# FUNCTION get_security_level()
#
#
##############################################################
FUNCTION get_security_level() 
	RETURN glob_rec_kandoouser.security_ind 
END FUNCTION 
##############################################################
# END FUNCTION get_security_level()
##############################################################


{
#Moved TO lib_tool -> lib_tool_MESSAGE.4gl

##############################################################
# FUNCTION show_manuals(entity_code)
##############################################################
}


##############################################################
# FUNCTION win_launch(p_filename)
#
# Using the file extension and windows registry to open a document
# with the OS-Associated editor/viewer
#
# Note: This is a client side function call / client side OS must be windows
#
# May be, someone can make this Apple / Chrome compatible as well
##############################################################
FUNCTION win_launch(p_filename) 
	# FUNCTION TO "fire up" a windows document
	DEFINE p_filename CHAR(512) 
	DEFINE l_cmd CHAR(600) 
	DEFINE l_length SMALLINT 
	DEFINE l_ret CHAR(256) 

	LET l_length = length(p_filename) 

	IF l_length = 0 THEN 
		RETURN 
	END IF 
	# Change any backslashes TO double backslashes.
	# Note that we have TO escape each backslash as the compiler
	# grabs one...
	CALL replace_string(p_filename, "\\", "\\\\") RETURNING p_filename 
	LET l_cmd = "shellexec \"", p_filename CLIPPED, "\"" 
	LET l_cmd = "SET reterror [ catch { ", l_cmd CLIPPED, " } msgerror ]" 

	CALL fgl_uisendcommand(l_cmd) 
	LET l_ret = fgl_uiretrieve("reterror") 

	IF l_ret = 1 THEN 
		ERROR "Windows 'shellexec' error occurred" 
	END IF 
END FUNCTION 
##############################################################
# END FUNCTION win_launch(p_filename)
##############################################################


##############################################################
# FUNCTION get_winfile(p_filter, p_file, p_title, p_dir)
#
#
##############################################################
FUNCTION get_winfile(p_filter,p_file,p_title,p_dir) 
	#
	#  FUNCTION TO initiate a "browse FOR file" style window which
	#  allows the user TO find a windows file.
	#  The arguments are used as follows:
	#
	#  filter - allows specific file filters TO be used, eg. text files,
	#           Word documents, etc.
	#
	#           The syntax IS as per following examples:
	#           {Text *.txt}
	#           {Dcouments *.doc}
	#           {\"Text Files\" *.txt}
	#
	#  file   - NOT used but originally intended as the default file
	#  title  - the title of the "browse" window
	#  dir    - NOT used - the default directory (TO start browsing FROM)
	#
	DEFINE p_filter CHAR(256) 
	DEFINE p_file CHAR(128) 
	DEFINE p_title CHAR(128) 
	DEFINE p_dir CHAR(128) 
	DEFINE l_cmd CHAR(512) 
	DEFINE l_ret CHAR(255) 
	DEFINE n, m INTEGER 
	DEFINE r_winfile CHAR(255)

	INITIALIZE r_winfile TO NULL 
	LET l_cmd = "SET reterror [ catch { pwd } workdir ]" 
	CALL fgl_uisendcommand(l_cmd) 
	   LET l_cmd = "SET reterror [ catch { chooseopenfile "
	# put in filter, title, AND directory IF they have been provided...

	   IF length(p_filter) > 0 THEN
	      LET l_cmd = l_cmd CLIPPED, " -filter \"", p_filter CLIPPED, "\""
	   END IF

	   IF length(p_title) > 0 THEN
	      LET l_cmd = l_cmd CLIPPED, " -title \"", p_title CLIPPED, "\""
	   END IF

	   LET l_cmd = l_cmd CLIPPED, " } wfilename ]"
	CALL fgl_uisendcommand(l_cmd) 
	LET l_ret = fgl_uiretrieve("reterror") 

	IF l_ret = 1 THEN # most likely CANCEL pressed 
		LET r_winfile = "" 
		RETURN r_winfile 
	END IF 

	LET r_winfile = fgl_uiretrieve("wfilename") 

	IF r_winfile[1,1] = "0" THEN 
		LET m = length ( r_winfile ) 
		LET n = 2 
		LET r_winfile = r_winfile[n,m] 
	END IF 
	LET l_cmd = "cd $workdir" 
	CALL fgl_uisendcommand(l_cmd) 

	RETURN r_winfile CLIPPED 
END FUNCTION 
##############################################################
# END FUNCTION get_winfile(p_filter, p_file, p_title, p_dir)
##############################################################


##############################################################
# FUNCTION replace_string(p_old_txt, p_old_sub, p_new_sub)
#
#  p_al012.4gl:  Search AND replace FUNCTION
#
#  Searches through a text string (p_old_txt) FOR occurrences of
#  a substring (p_old_sub). Each occurrence IS replaced with the
#  new substring (p_new_sub).
#
#  Things TO be wary of WHEN you use this FUNCTION:
#  1. spaces are CLIPPED FROM the right of both substrings before
#     any processing IS done.
#  2. IF the "replace with" substring IS longer than the "find"
#     substring there IS a possibility the result will come back
#     truncated.
##############################################################
# FIXME: what does a replace_string function has to do in a security library ????
FUNCTION replace_string(p_old_txt,p_old_sub,p_new_sub) 
	DEFINE p_old_txt CHAR(512) 
	DEFINE p_old_sub CHAR(128) 
	DEFINE p_new_sub CHAR(128) 
	DEFINE l_txt_len SMALLINT 
	DEFINE l_old_len SMALLINT 
	DEFINE l_new_len SMALLINT 
	DEFINE l_old_idx SMALLINT 
	DEFINE l_new_idx SMALLINT 
	DEFINE r_new_txt CHAR(512) 

	LET l_txt_len = length(p_old_txt) 
	LET l_old_len = length(p_old_sub) 
	LET l_new_len = length(p_new_sub) 
	IF l_txt_len = 0 
	OR l_old_len = 0 THEN 
		RETURN p_old_txt 
	END IF 
	LET r_new_txt = " " 
	LET l_old_idx = 1 
	LET l_new_idx = 1 

	WHILE l_old_idx <= l_txt_len 
		AND l_new_idx <= 512 
		IF l_old_idx + l_old_len - 1 > l_txt_len THEN 
			LET r_new_txt[l_new_idx, 512] = p_old_txt[l_old_idx, l_txt_len] 
			EXIT WHILE 
		END IF 
		IF p_old_txt[l_old_idx, l_old_idx + l_old_len - 1] = p_old_sub THEN 
			# we have found the old substring...
			LET r_new_txt[l_new_idx, 512] = p_new_sub 
			LET l_new_idx = l_new_idx + l_new_len 
			LET l_old_idx = l_old_idx + l_old_len 
			CONTINUE WHILE 
		END IF 
		# OTHERWISE, just another letter TO transfer...
		LET r_new_txt[l_new_idx] = p_old_txt[l_old_idx] 
		LET l_new_idx = l_new_idx + 1 
		LET l_old_idx = l_old_idx + 1 
		CONTINUE WHILE 
	END WHILE 

	RETURN r_new_txt 
END FUNCTION 
##############################################################
# END FUNCTION replace_string(p_old_txt, p_old_sub, p_new_sub)
##############################################################


##############################################################
# FUNCTION callingprog()
#
# HuHo, I believe, this IS no longer used... ask FGLAA
##############################################################
FUNCTION callingprog() 
	RETURN getmoduleid() 
END FUNCTION 
##############################################################
# END FUNCTION callingprog()
##############################################################


##############################################################
# FUNCTION show_kandooword(p_ref_text)
#
#
###############################################################
FUNCTION show_kandooword_filter_datasource(p_ref_text,p_filter) 
	DEFINE p_ref_text LIKE kandooword.reference_text 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_kandooword RECORD LIKE kandooword.* 
	DEFINE l_arr_rec_kandooword DYNAMIC ARRAY OF t_rec_kandooword_rc_rt_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
			reference_code, 
			response_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","secufunc","construct-kandooword") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_kandooword.reference_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM kandooword ", 
		"WHERE kandooword.language_code = \"", 
		glob_rec_kandoouser.language_code, "\"", 
		" AND reference_text = \"", p_ref_text CLIPPED,"\" ", 
		" AND ", l_where_text CLIPPED, " ", 
		"ORDER BY reference_code" 

	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 

	PREPARE s_word FROM l_query_text 
	DECLARE c_word CURSOR FOR s_word 
	LET l_idx = 0 

	FOREACH c_word INTO l_rec_kandooword.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_kandooword[l_idx].reference_code = l_rec_kandooword.reference_code 
		LET l_arr_rec_kandooword[l_idx].response_text = l_rec_kandooword.response_text 

		#         IF l_idx = 100 THEN
		#            LET l_msgresp = kandoomsg("U",6100,l_idx)
		#            EXIT FOREACH
		#         END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	LET l_msgresp=kandoomsg("U",9113,l_arr_rec_kandooword.getLength())	#U9113 l_idx records selected

	RETURN l_arr_rec_kandooword 

END FUNCTION
##############################################################
# END FUNCTION show_kandooword(p_ref_text)
###############################################################

 
##############################################################
# FUNCTION show_kandooword(p_ref_text)
#
#
###############################################################
FUNCTION show_kandooword(p_ref_text) 
	DEFINE p_ref_text LIKE kandooword.reference_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_kandooword RECORD LIKE kandooword.* 
	DEFINE l_arr_rec_kandooword DYNAMIC ARRAY OF t_rec_kandooword_rc_rt_with_scrollflag 
	#	#ARRAY[100] of record
	#		RECORD
	#         scroll_flag CHAR(1),
	#         reference_code LIKE kandooword.reference_code,
	#         response_text LIKE kandooword.response_text
	#      END RECORD
	DEFINE l_idx SMALLINT 

	OPEN WINDOW U163 with FORM "U163" 
	CALL winDecoration_u("U163") 

	#   WHILE TRUE
	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_kandooword[1].* TO NULL
	#      END IF

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL show_kandooword_filter_datasource(p_ref_text,FALSE) RETURNING l_arr_rec_kandooword 

	LET l_msgresp = kandoomsg("U",1019,"") 
	#1006 " ESC on line TO SELECT
	#      CALL set_count(l_idx)

	DISPLAY ARRAY l_arr_rec_kandooword TO sr_kandooword.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY l_arr_rec_kandooword WITHOUT DEFAULTS FROM sr_kandooword.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","secufunc","input-arr-kandooword") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_kandooword.clear() 
			CALL show_kandooword_filter_datasource(p_ref_text,TRUE) RETURNING l_arr_rec_kandooword 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_kandooword.reference_code = l_arr_rec_kandooword[l_idx].reference_code 
			#            LET scrn = scr_line()
			#            IF l_arr_rec_kandooword[l_idx].reference_code IS NOT NULL THEN
			#               DISPLAY l_arr_rec_kandooword[l_idx].*
			#                    TO sr_kandooword[scrn].*
			#
			#            END IF
			#            NEXT FIELD scroll_flag

			#         AFTER FIELD scroll_flag
			#            LET l_arr_rec_kandooword[l_idx].scroll_flag = NULL
			#            IF fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               NEXT FIELD scroll_flag
			#            END IF
			#
			#         BEFORE FIELD reference_code
			#            LET l_rec_kandooword.reference_code = l_arr_rec_kandooword[l_idx].reference_code
			#            EXIT INPUT

			#         AFTER ROW
			#            DISPLAY l_arr_rec_kandooword[l_idx].* TO sr_kandooword[scrn].*

			#         AFTER INPUT
			#            LET l_rec_kandooword.reference_code = l_arr_rec_kandooword[l_idx].reference_code



	END DISPLAY 
	######################

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_rec_kandooword.reference_code = NULL 
	END IF 

	CLOSE WINDOW U163 

	RETURN l_rec_kandooword.reference_code 
END FUNCTION  #  show_kandooword
##############################################################
# END FUNCTION show_kandooword(p_ref_text)
###############################################################


##############################################################
# FUNCTION get_kandoo_user()
##############################################################
FUNCTION get_kandoo_user() 
	RETURN glob_rec_kandoouser.* 
END FUNCTION 
##############################################################
# END FUNCTION get_kandoo_user()
##############################################################

##############################################################
# FUNCTION is_kandoo_SUSE()
##############################################################
#FUNCTION is_kandoo_SUSE()
#   RETURN glob_SUSE_flag
#END FUNCTION


##############################################################
# FUNCTION is_kandoo_windows()
##############################################################
#FUNCTION is_kandoo_windows()
#   RETURN glob_wtk_flag
#END FUNCTION


##############################################################
# FUNCTION is_kandoo_nt()
##############################################################
FUNCTION is_kandoo_nt() 
	RETURN get_os_arch() 
END FUNCTION 



##############################################################
# FUNCTION check_for_memo()
#
#
##############################################################
FUNCTION check_for_memo() 
	DEFINE l_unread INTEGER 
	DEFINE l_rec_kandooinfo RECORD LIKE kandooinfo.* 

	# IF current >= glob_time_last_checked THEN
	SELECT unique 1 FROM kandoomemo 
	WHERE read_flag = "N" 
	AND to_code = glob_rec_kandoouser.sign_on_code 
	AND priority_ind = 0 

	IF status = 0 THEN 
		CALL set_msgresp(kandoomsg("U",7043,"")) 
		#7043 Urgent Memo Received
		CALL run_prog("U17","","","","") 

	ELSE 

		SELECT count (*) INTO l_unread FROM kandoomemo 
		WHERE read_flag = "N" 
		AND to_code = glob_rec_kandoouser.sign_on_code 
		AND priority_ind = 1 

		IF l_unread > 0 THEN 
			#huho 23.02.2019
			#LET glob_title_desc = NULL
			#LET glob_msgresp = kandoomsg("U",8034,l_unread)
			SELECT kandoo_type INTO l_rec_kandooinfo.kandoo_type FROM kandooinfo 
			#huho 23.02.2019
			#
			#IF l_rec_kandooinfo.update_num = "00" THEN
			#   LET glob_title_desc = "ERP ", l_rec_kandooinfo.version_num using "&.&&",
			#                         " - ", glob_rec_kandoouser.name_text
			#ELSE
			#   LET glob_title_desc = "ERP ",
			#                         l_rec_kandooinfo.version_num using "&.&&",".",
			#                         l_rec_kandooinfo.update_num using "&&",
			#                " - ", glob_rec_kandoouser.name_text
			#END IF
			IF get_msgresp() = "Y" THEN 
				CALL run_prog("U17","","","","") 
			END IF 

		END IF 

	END IF 
	#LET glob_time_last_checked = current + 1 units minute

	#END IF

	RETURN 
END FUNCTION  # check_for_memo
##############################################################
# END FUNCTION get_kandoo_user()
##############################################################

##############################################################
# FUNCTION is_bas()
#
#
##############################################################
FUNCTION is_bas() 
	RETURN TRUE 
END FUNCTION 
##############################################################
# END FUNCTION is_bas()
##############################################################

{
##############################################################
# FUNCTION switch_user()
##############################################################
FUNCTION switch_user()
DEFINE
    cnt,
    tmp_len
        SMALLINT,
	ARGUMENT
			ARRAY[8] OF CHAR (20),
    prg_name,
    p_passw,
    ifxserver,
	new_dbname
        CHAR(20),
    new_uname
        CHAR(8),
    tmpstat
    	INTEGER,
    p_asp RECORD LIKE asp.*,
    g_msg CHAR (400)
	DEFINE tmpMsg STRING  --MESSAGE strings

#QueriX have problems with innitialisation of vaiables, so we better initialise
#them ourselves:
#
#HuHo - BULLSHIT.. this init IS a waste of resources you XXXX
#Hydra had compiler flag TO adjust the init behaviour i.e. Informix compatiblity.. you should have asked...

	INITIALIZE
	cnt,
    tmp_len,
    prg_name,
    p_passw,
    ifxserver,
	new_dbname,
    new_uname,
    tmpstat,
    g_msg
        TO NULL

    LET new_uname = fgl_getenv("REMOTEUSER") #SET by CJAC based on "$(FGL_AUTHUSER)"
#OR qrun.sh FOR Querix
                if
	                    new_uname IS NOT NULL
	                    AND
	                    length (new_uname) > 2
                THEN
#we are running <Suse> CLI-Java
						LET new_uname = downshift (new_uname)

#this are actualy passwords of operating system
#on whitch the database IS running. Since this box
#IS NOT reachable in any way, it IS OK IF all users have
#the same passwd FOR database server, they do NOT need
#TO know it anyway.

#BUT THIS IS SECURITY HOLE AT LEAST IN THEORY!!!!

						LET p_passw = "multipass"

#I must specify server since default IS using shared
# memory, AND there are no multiple connection on that
#connect TO 'databasename@myifxserver_on' user new_uname using p_passw
#I do NOT want TO specify database, since this can also
#be specified in environment. Also, there can be no explicit
#DATABASE statemant inside connection made with CONNECT

                        SELECT * INTO p_asp.* FROM asp WHERE tmp_loginname = new_uname

                        if
							STATUS <> NOTFOUND
						then
                            LET ifxserver=p_asp.server_instance

                            if
                                length(ifxserver) < 2
                            THEN
                                ERROR "no ifmx server in ASP table!"
								DISPLAY "no ifmx server in ASP table!"
								MESSAGE "no ifmx server in ASP table!"
								CALL fgl_winmessage("No ifmx server in ASP table!","No ifmx server in ASP table!","info")
#sleep 5
                                EXIT PROGRAM
                            END IF


							LET new_dbname=p_asp.max_db

                            if
                                length (new_dbname) < 2
                            THEN
                                ERROR "no db name in ASP table!"
                                DISPLAY "no db name in ASP table!"
                                MESSAGE "no db name in ASP table!"
																CALL fgl_winmessage("No db name in ASP table!","No db name in ASP table!","info")

#sleep 5
                                EXIT PROGRAM
                            END IF


#check valid_from, valid_to:


#check FROM asp_contract table IF users have purchased
#access TO this module:


                        ELSE
#IF we have no data about the user in the db, we should
#realy stop (in production system), but FOR testing, AND users
#that created logins before we created this sytem, we will
#try TO continue.

								LET new_dbname="defaultdbname-fixme"
#DISPLAY "Warning: user ",new_uname," NOT in ASP table."
#sleep 5

		                        LET ifxserver = fgl_GETENV("MAXIFXSERVER")

								if
			                            ifxserver IS NULL
			                            OR
			                            length (ifxserver) < 2
			                    THEN
				                        LET ifxserver=fgl_getenv("INFORMIXSERVER")
								END IF

								if
			                            ifxserver IS NULL
			                            OR
			                            length (ifxserver) < 2
			                    THEN
			                            DISPLAY "Don't have INFORMIXSERVER: stop."
																	CALL fgl_winmessage("Don't have INFORMIXSERVER: stop","Don't have INFORMIXSERVER: stop","error")
#sleep 2
			                            EXIT PROGRAM
			                    END IF

                        END IF

  	                    LET ifxserver="@", ifxserver CLIPPED

#LET g_msg = "using ", ifxserver CLIPPED, " TO connect user ",
#	new_uname CLIPPED, " with password ", p_passw CLIPPED, " TO the database !"
#DISPLAY g_msg CLIPPED
# MESSAGE g_msg
#error g_msg


#this will force us TO use tcp connection TO server
#anyway, since shm do NOT support multiple connections
#so, DEFINE INFORMIXSERVER always as connection TO TCP

#database NOT selected yet: close database
#@huho I'll comment this <Anton Dickinson> stuff
#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with CONNECT"
#DISPLAY "see common/secufunc.4gl"
#EXIT PROGRAM (1)

#all compilers support connect now
#DISABLED				connect TO ifxserver user new_uname using p_passw

						LET tmpstat = STATUS

						if
                            tmpstat <> 0
                        THEN
                        LET tmpMsg = "connect STATUS = ", tmpstat
							MESSAGE tmpMsg
							DISPLAY tmpMsg
							ERROR tmpMsg
							CALL fgl_winmessage(tmpMsg,tmpMsg,"error")

#	sleep 5
                            EXIT PROGRAM
#ELSE
# MESSAGE "Changed user TO ",new_uname CLIPPED
#sleep 2
                        END IF

                        database new_dbname

                        LET tmpstat = STATUS

						if
                            tmpstat <> 0
                        THEN
                        	LET tmpMsg = "database STATUS = ", tmpstat
                            DISPLAY tmpMsg
							MESSAGE tmpMsg
							ERROR tmpMsg
							CALL fgl_winmessage("Error - Abborting",tmpMsg,"error")
#sleep 5
                            EXIT PROGRAM
                        END IF
                ELSE
#we are NOT running CLI-Java

  					LET new_dbname=fgl_getenv("KANDOODB")

                    IF new_dbname IS NOT NULL
						AND new_dbname <> "defaultdbname-fixme" 	#TO prevent connecting twice TO the database
#that IS already a default as per DATABASE
#non-procedural declaration in glob_GLOBALS.4gl
#FIXME - do NOT hard-code kandoodb name - take it FROM Autoconf .. @huho: so WHERE IS Autoconf ????
						AND new_dbname <> "kandoodb"
					then
					LET tmpMsg = "Swithching TO ",new_dbname CLIPPED
DISPLAY tmpMsg
CALL fgl_winmessage("Error - Abborting",tmpMsg,"error")
	                    database new_dbname

	                    LET tmpstat = STATUS

						if
	                        tmpstat <> 0
	                    THEN
	                    	LET tmpMsg = "database STATUS = ", tmpstat
	                        DISPLAY tmpMsg
							MESSAGE tmpMsg
							ERROR tmpMsg
							CALL fgl_winmessage("Error - Abborting",tmpMsg,"error")

	                        EXIT PROGRAM
	                    END IF
                    ELSE
#IF KANDOODB was NOT specified, just keep connection based
#on default DATABASE directive, which IS the same as the
#compile-time database, which IS currrently a hard-coded?.
					END IF
				END IF


END FUNCTION #switch_user()

}
##############################################################
# FUNCTION exit_program_global()
#
#
##############################################################
FUNCTION exit_program_global() 
	DEFINE l_ans CHAR(1) 
	DEFINE l_spaces CHAR(240) 

	LET l_spaces = "Terminate program on users request ?" 

	#fallout: This should be implemented as kandoomsg call:
	#huho:hmmmm ?
	LET l_ans = fgl_winquestion ("Question:", l_spaces,"Yes", "Yes|No", "question",1 ) 

	IF l_ans = "Y"	OR	l_ans = "y"	THEN 
		WHENEVER ERROR CONTINUE 
		ROLLBACK WORK 
		CLOSE DATABASE 

		EXIT program 
	END IF 

END FUNCTION #exit_program_global 
##############################################################
# END FUNCTION exit_program_global()
##############################################################


# this bullshit FUNCTION needs removing
##############################################################
# FUNCTION fgl_uisendcommand (p_cmdstring)
#
#
##############################################################
FUNCTION fgl_uisendcommand (p_cmdstring) 
	DEFINE p_cmdstring STRING 
END FUNCTION 
##############################################################
# END FUNCTION fgl_uisendcommand (p_cmdstring)
##############################################################


##############################################################
# FUNCTION fgl_uiretrieve(p_cmdstring)
#
#
##############################################################
FUNCTION fgl_uiretrieve(p_cmdstring) 
	DEFINE p_cmdstring STRING 
	DEFINE r_returnstring STRING 

	RETURN r_returnstring 

END FUNCTION 
##############################################################
# END FUNCTION fgl_uiretrieve(p_cmdstring)
##############################################################
