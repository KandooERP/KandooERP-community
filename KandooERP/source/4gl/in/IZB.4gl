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

	Source code beautified by beautify.pl on 2020-01-03 09:12:48	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZB - Inventory Product Schedule Parameters
#                   allows the user TO enter AND maintain Product Schedule
#                   parameters

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_no_flag LIKE language.yes_flag #not used 
	DEFINE glob_yes_flag LIKE language.yes_flag #not used 
	DEFINE glob_sqlerrd INTEGER 
	DEFINE glob_rec_ipparms RECORD LIKE ipparms.* 
END GLOBALS 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZB") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i633 with FORM "I633" 
	 CALL windecoration_i("I633") -- albo kd-758 

	MENU " Product Schedule" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","IZB","menu-Product_Schedule-1") -- albo kd-505 

			IF do_parms(3) THEN 
				HIDE option "NEW" 
				SHOW option "EDIT" 
			ELSE 
				SHOW option "NEW" 
				HIDE option "EDIT" 
			END IF 


		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 


		ON ACTION "NEW" 
			#COMMAND "Add" " Add Product Schedule Parameters"
			IF do_parms(1) THEN 
				HIDE option "NEW" 
				SHOW option "EDIT" 
			END IF 

		ON ACTION "EDIT" 
			#COMMAND "Change" " Change Product Schedule Parameters"
			IF do_parms(2) THEN 
			END IF 

		ON ACTION "CANCEL" 
			#COMMAND KEY(interrupt,"E") "Exit " " RETURN TO Menus"
			EXIT MENU 

			#      COMMAND KEY (control-w)
			#         CALL kandoohelp("")
	END MENU 

	CLOSE WINDOW i633 

END MAIN 

####################################################################
# FUNCTION do_parms(p_action)
#
#
####################################################################
FUNCTION do_parms(p_action) 
	DEFINE p_action SMALLINT #1 add 
	#2 Update
	#3 Display
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO glob_rec_ipparms.* 
	FROM ipparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = 1 

	IF status = notfound THEN 
		CASE 
			WHEN p_action = 1 
				INITIALIZE glob_rec_ipparms.* TO NULL 
				LET glob_rec_ipparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET glob_rec_ipparms.key_num = 1 
			WHEN p_action = 2 
				LET l_msgresp = kandoomsg("I",9177,"") 
				#9177 Parameters Not Found Use Add
				RETURN false 
			WHEN p_action = 3 
				RETURN false 
		END CASE 

	ELSE 

		DISPLAY BY NAME glob_rec_ipparms.ref1_text, 
		glob_rec_ipparms.ref1_shrt_text, 
		glob_rec_ipparms.ref2_text, 
		glob_rec_ipparms.ref2_shrt_text, 
		glob_rec_ipparms.ref3_text, 
		glob_rec_ipparms.ref3_shrt_text, 
		glob_rec_ipparms.ref4_text, 
		glob_rec_ipparms.ref4_shrt_text, 
		glob_rec_ipparms.ref5_text, 
		glob_rec_ipparms.ref5_shrt_text, 
		glob_rec_ipparms.ref6_text, 
		glob_rec_ipparms.ref6_shrt_text, 
		glob_rec_ipparms.ref7_text, 
		glob_rec_ipparms.ref7_shrt_text, 
		glob_rec_ipparms.ref8_text, 
		glob_rec_ipparms.ref8_shrt_text, 
		glob_rec_ipparms.ref9_text, 
		glob_rec_ipparms.ref9_shrt_text, 
		glob_rec_ipparms.refa_text, 
		glob_rec_ipparms.refa_shrt_text 

	END IF 

	IF p_action = 3 THEN 
		RETURN true 
	END IF 

	INPUT BY NAME glob_rec_ipparms.ref1_text, 
	glob_rec_ipparms.ref1_shrt_text, 
	glob_rec_ipparms.ref2_text, 
	glob_rec_ipparms.ref2_shrt_text, 
	glob_rec_ipparms.ref3_text, 
	glob_rec_ipparms.ref3_shrt_text, 
	glob_rec_ipparms.ref4_text, 
	glob_rec_ipparms.ref4_shrt_text, 
	glob_rec_ipparms.ref5_text, 
	glob_rec_ipparms.ref5_shrt_text, 
	glob_rec_ipparms.ref6_text, 
	glob_rec_ipparms.ref6_shrt_text, 
	glob_rec_ipparms.ref7_text, 
	glob_rec_ipparms.ref7_shrt_text, 
	glob_rec_ipparms.ref8_text, 
	glob_rec_ipparms.ref8_shrt_text, 
	glob_rec_ipparms.ref9_text, 
	glob_rec_ipparms.ref9_shrt_text, 
	glob_rec_ipparms.refa_text, 
	glob_rec_ipparms.refa_shrt_text 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZB","input-glob_rec_ipparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD ref1_text 
			IF glob_rec_ipparms.ref1_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref1_text 
			END IF 
		AFTER FIELD ref1_shrt_text 
			IF glob_rec_ipparms.ref1_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref1_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref1_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref2_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref2_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref2_text 
			END IF 
		AFTER FIELD ref2_shrt_text 
			IF glob_rec_ipparms.ref2_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref2_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref2_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref3_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref3_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref3_text 
			END IF 
		AFTER FIELD ref3_shrt_text 
			IF glob_rec_ipparms.ref3_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref3_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref3_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref4_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref4_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref4_text 
			END IF 
		AFTER FIELD ref4_shrt_text 
			IF glob_rec_ipparms.ref4_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref4_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref4_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref5_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref5_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref5_text 
			END IF 
		AFTER FIELD ref5_shrt_text 
			IF glob_rec_ipparms.ref5_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref5_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref5_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref6_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref6_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref6_text 
			END IF 
		AFTER FIELD ref6_shrt_text 
			IF glob_rec_ipparms.ref6_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref6_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref6_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref7_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref7_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref7_text 
			END IF 
		AFTER FIELD ref7_shrt_text 
			IF glob_rec_ipparms.ref7_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref7_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref7_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref8_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref8_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref8_text 
			END IF 
		AFTER FIELD ref8_shrt_text 
			IF glob_rec_ipparms.ref8_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref8_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref8_shrt_text 
				END IF 
			END IF 

		AFTER FIELD ref9_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.ref9_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD ref9_text 
			END IF 
		AFTER FIELD ref9_shrt_text 
			IF glob_rec_ipparms.ref9_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.ref9_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD ref9_shrt_text 
				END IF 
			END IF 

		AFTER FIELD refa_text 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF glob_rec_ipparms.refa_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9178,"") 
				#9178 A Label Description must be Entered Before Proceeding
				NEXT FIELD refa_text 
			END IF 
		AFTER FIELD refa_shrt_text 
			IF glob_rec_ipparms.refa_shrt_text IS NULL THEN 
				IF glob_rec_ipparms.refa_text IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("I",9179,"") 
					#9179 A Short Heading Must Be Entered
					NEXT FIELD refa_shrt_text 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET glob_sqlerrd = 0 

	IF p_action = 1 THEN # INSERT 
		INSERT INTO ipparms 
		VALUES (glob_rec_ipparms.*) 
		LET glob_sqlerrd = sqlca.sqlerrd[6] 
	ELSE # p_action must be 2 
		UPDATE ipparms 
		SET * = glob_rec_ipparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = 1 
		LET glob_sqlerrd = sqlca.sqlerrd[3] 
	END IF 

	RETURN glob_sqlerrd 
END FUNCTION 
