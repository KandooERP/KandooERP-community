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

	Source code beautified by beautify.pl on 2020-01-03 14:28:46	$Id: $
}



# program TO load glrepdata information

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

##################################################################
# MAIN
#
#
##################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("GL5") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g550 with FORM "G550" 
	CALL windecoration_g("G550") 

	MENU " Load Extract" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GL5","menu-gl-extract") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Load" 
			#COMMAND "Load" " Enter file name AND load data"
			CALL data_load() 
			NEXT option "Exit" 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

		COMMAND KEY (control-w) --help 
			CALL kandoohelp("") 

	END MENU 

	CLOSE WINDOW g550 
END MAIN 


##################################################################
# FUNCTION data_load()
#
#
##################################################################
FUNCTION data_load() 
	DEFINE l_filename CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("U",1020,"File") 

	#1020 "Enter File Details - OK TO Continue"
	INPUT l_filename FROM filename ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL5","inp-filename") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER INPUT 
			# Exclusive OR
			# Lycia issue: Lycia SET's quit_flag = TRUE
			# whenever int_flag IS SET automatically.
			# IF NOT int_flag OR quit_flag THEN
			# huho - changed TO
			IF NOT (int_flag OR quit_flag) THEN 
				IF NOT valid_load_file(l_filename) THEN 
					NEXT FIELD filename 
				END IF 

				SELECT unique 1 FROM glrepdata 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("G",8024,"") 
					#8024 Confirm TO Delete AND load(Y/N)"
					IF l_msgresp = "N" THEN 
						EXIT INPUT 
					END IF 
				ELSE 
					LET l_msgresp = kandoomsg("G",8025,"") 
					#8024 Confirm load(Y/N)"
					IF l_msgresp = "N" THEN 
						EXIT INPUT 
					END IF 
				END IF 

			END IF 

	END INPUT 
	##################################################

	IF int_flag OR quit_flag 
	OR l_msgresp = "N" THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	#OPEN WINDOW w1 WITH FORM "U999" ATTRIBUTES(BORDER)
	#	CALL windecoration_u("U999")

	#DISPLAY "Loading extract data..." TO lbLabel2  -- 2,2
	MESSAGE "Loading extract data..." 

	DELETE FROM glrepdata 

	WHENEVER ERROR CONTINUE 
	LOAD FROM l_filename INSERT INTO glrepdata 
	WHENEVER ERROR stop 

	IF status != 0 THEN 
		LET l_msgresp=kandoomsg("G",9144,"") 
		MESSAGE l_msgresp 
		#9144 "Interface file does NOT exist - Check path AND file name"
		#CLOSE WINDOW w1
		RETURN 
	END IF 

	SELECT unique 1 FROM glrepdata 

	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("G",9146,"") 
		MESSAGE l_msgresp 
		#9146 "Interface file IS empty - Check PC Transfer"
		#CLOSE WINDOW w1
		RETURN 
	END IF 
	#CLOSE WINDOW w1

END FUNCTION 

##################################################################
# FUNCTION valid_load_file(p_file_name)
#
#
#        1. File NOT found
#        2. No read permission
#        3. File IS Empty
#        4. OTHERWISE
#
##################################################################
FUNCTION valid_load_file(p_file_name) 
	DEFINE p_file_name STRING
	DEFINE l_runner STRING 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_ret_code = os.path.exists(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -f ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9160,'') 
		#9160 Load file does NOT exist - check path AND filename
		RETURN false 
	END IF 

	LET l_ret_code = os.path.readable(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -r ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9162,'') 
		#9162 Unable TO read load file
		RETURN false 
	END IF 

	LET l_ret_code = os.path.writable(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -w ",p_file_name clipped," ] 2>>", trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9173,'') 
		#9173 Unable TO write TO load file
		RETURN false 
	END IF 

	LET l_ret_code = os.path.size(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -s ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9161,'') 
		#9161 Load file IS empty
		RETURN false 

	ELSE 
		RETURN true 
	END IF 
END FUNCTION