
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

	Source code beautified by beautify.pl on 2020-01-03 11:19:28	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ8_GLOBALS.4gl"  

############################################################
# Module Scope Variables
############################################################
--GLOBALS 
	DEFINE modu_rec_stnd_parms RECORD LIKE stnd_parms.* 
	--DEFINE counter SMALLINT 
	--DEFINE idx SMALLINT 
	--DEFINE cnt SMALLINT 
	--DEFINE err_flag SMALLINT 
	--DEFINE domore CHAR(1) 
	DEFINE modu_menu_path CHAR(3) 
--END GLOBALS 


#############################################################################
# MAIN
#
# Group Parameters  ??? Warehouse ? NOT documented
#############################################################################
MAIN 
	DEFINE l_program CHAR(25) 

	CALL setModuleId("AZ8") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	# huho what the xxxx are the next 2 lines ????
	LET modu_menu_path = get_baseprogname() 
	LET modu_menu_path = l_program[1,3] 

	INITIALIZE modu_rec_stnd_parms.* TO NULL 

	CALL fgl_winmessage("@Ali/@Anna - homework for you","Transaction Types\nCan you please investigate, what we need here\nand send me a list","info") 


	OPEN WINDOW wa923 with FORM "A923" 
	CALL windecoration_a("A923") 

	SELECT * 
	INTO modu_rec_stnd_parms.* 
	FROM stnd_parms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF modu_rec_stnd_parms.cmpy_code IS NULL THEN 
		CALL parms_inpt() 
		LET modu_rec_stnd_parms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO stnd_parms VALUES (modu_rec_stnd_parms.*) 
	ELSE 
		DISPLAY BY NAME modu_rec_stnd_parms.ware_code, 
		modu_rec_stnd_parms.level_code, 
		modu_rec_stnd_parms.tax_code, 
		modu_rec_stnd_parms.currency_code 
		CALL parms_inpt() 
		LET modu_rec_stnd_parms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		UPDATE stnd_parms 
		SET * = modu_rec_stnd_parms.* 
		WHERE cmpy_code = modu_rec_stnd_parms.cmpy_code 
	END IF 

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 

	CLOSE WINDOW wa923 
END MAIN 


#############################################################################
# FUNCTION parms_inpt() 
#
#
#############################################################################
FUNCTION parms_inpt() 

	INPUT BY NAME modu_rec_stnd_parms.ware_code, 
	modu_rec_stnd_parms.level_code, 
	modu_rec_stnd_parms.tax_code, 
	modu_rec_stnd_parms.currency_code WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ8","inp-stnd_parms") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (ware_code) 
					LET modu_rec_stnd_parms.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME modu_rec_stnd_parms.ware_code 

					NEXT FIELD ware_code 
		
		ON ACTION "LOOKUP" infield (tax_code) 
					LET modu_rec_stnd_parms.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME modu_rec_stnd_parms.tax_code 

					NEXT FIELD tax_code 
					
		ON ACTION "LOOKUP" infield (currency_code) 
					LET modu_rec_stnd_parms.currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME modu_rec_stnd_parms.currency_code 

					DISPLAY BY NAME modu_rec_stnd_parms.currency_code 
					NEXT FIELD currency_code 


			IF int_flag OR quit_flag THEN 
				EXIT PROGRAM 
			END IF 

		AFTER FIELD ware_code 
			SELECT * 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_stnd_parms.ware_code 

			IF status = NOTFOUND THEN 
				ERROR " This IS an invalid warehouse try window(W)" 
				NEXT FIELD ware_code 
			END IF 

		AFTER FIELD tax_code 
			SELECT * 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = modu_rec_stnd_parms.tax_code 

			IF status = NOTFOUND THEN 
				ERROR " This IS an invalid Tax Code try window(W)" 
				NEXT FIELD tax_code 
			END IF 

		AFTER FIELD currency_code 
			SELECT * 
			FROM currency 
			WHERE currency_code = modu_rec_stnd_parms.currency_code 

			IF status = NOTFOUND THEN 
				ERROR " This IS an invalid Currency Code try window(W)" 
				NEXT FIELD currency_code 
			END IF 

			NEXT FIELD ware_code 

	END INPUT 
END FUNCTION 


