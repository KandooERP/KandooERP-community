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

	Source code beautified by beautify.pl on 2020-01-03 11:19:29	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZS_GLOBALS.4gl" 

GLOBALS 
	DEFINE modu_rec_usermsg RECORD LIKE usermsg.* 
	DEFINE modu_disp_message CHAR(75) 
	DEFINE modu_ans CHAR(1) 
END GLOBALS 

#############################################################################
# MAIN
#
# maintain MESSAGE lines FOR invoices
#############################################################################
MAIN 

	CALL setModuleId("AZS") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	LET modu_ans = "Y" 

	WHILE modu_ans = "Y" 

		# INITIALIZE pr records


		CALL read_message() 
		CALL header() 

		IF modu_ans = "N" THEN 
			EXIT WHILE 
		END IF 

		CALL write_message() 

	END WHILE 

END MAIN 

#############################################################################
# FUNCTION header() 
#
# s
#############################################################################
FUNCTION header() 

	OPEN WINDOW wa915 with FORM "A915" 
	CALL windecoration_a("A915") 

	LET modu_disp_message = "Del TO EXIT" 
	MESSAGE modu_disp_message attribute(yellow) 
	LET modu_rec_usermsg.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT BY NAME modu_rec_usermsg.line1_text,modu_rec_usermsg.line2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZS","inp-usermsg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END INPUT 

	IF (int_flag OR quit_flag) THEN 
		LET modu_ans = "N" 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

	CLOSE WINDOW wa915 

END FUNCTION 


#############################################################################
# FUNCTION read_message() 
#
# 
#############################################################################
FUNCTION read_message() 

	SELECT * 
	INTO modu_rec_usermsg.* 
	FROM usermsg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

END FUNCTION 


#############################################################################
# FUNCTION write_message() 
#
# 
#############################################################################
FUNCTION write_message() 
	--DEFINE l_file_string CHAR(50) 

	BEGIN WORK 

		DELETE FROM usermsg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		INSERT INTO usermsg VALUES (modu_rec_usermsg.*) 

	COMMIT WORK 

END FUNCTION