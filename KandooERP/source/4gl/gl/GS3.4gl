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

	Source code beautified by beautify.pl on 2020-01-03 14:28:51	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GS3 Copies coa over TO new coa accounts


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################

############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g170 with FORM "G170" 
	CALL windecoration_g("G170") 


	WHILE true 
		IF get_info() THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW g170 
END MAIN 


############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_s_coa RECORD LIKE coa.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_msgresp CHAR(1) 
	DEFINE l_ans CHAR(1) 

	DEFINE l_counter1 INTEGER 
	DEFINE l_counter INTEGER 

	DEFINE l_error_found SMALLINT 
	DEFINE l_starter SMALLINT 
	DEFINE l_lengther SMALLINT 
	DEFINE l_check_code LIKE account.acct_code 
	DEFINE l_source_acct LIKE account.acct_code 
	DEFINE l_target_acct LIKE account.acct_code 
	DEFINE l_errmsg CHAR(40) 
	DEFINE x SMALLINT 

	LET l_msgresp = kandoomsg("G",1063,"") 
	LET l_msgresp = kandoomsg("G",9101,"") 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = 0 
	DISPLAY l_rec_structure.default_text TO default_text 
	WHILE true 

		INPUT l_source_acct, l_target_acct WITHOUT DEFAULTS 
		FROM source_acct, target_acct ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GS3","inp-acct") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD source_acct 
				IF l_source_acct IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9012 Value must be entered
					NEXT FIELD source_acct 
				END IF 

			AFTER FIELD target_acct 
				IF l_target_acct IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9012 Value must be entered
					NEXT FIELD target_acct 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF l_target_acct IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9012,"") 
						#9012 Value must be entered
						NEXT FIELD target_acct 
					END IF 
				END IF 
				--        ON KEY (control-w)
				--           CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			RETURN true 
		END IF 
		# this just takes out blanks AT the end
		LET l_lengther = length(l_source_acct) 
		IF length(l_source_acct) = 18 THEN 
		ELSE 
			LET l_source_acct = l_source_acct [1,l_lengther] , "*" 
		END IF 

		LET l_counter = 0 
		SELECT count(*) INTO l_counter FROM coa 
		WHERE acct_code matches l_source_acct 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF l_counter > 0 THEN 
			EXIT WHILE 
		ELSE 
			LET l_msgresp = kandoomsg("U",9101,"") 
		END IF 


	END WHILE 

	LET l_counter1 = l_counter USING "<<<<<<<" 
	#8027 " Copying ", l_counter1 " accounts, continue (y/n)?:"
	IF kandoomsg("G",8027,l_counter1) != "Y" THEN 
		RETURN false 
	END IF 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#Updating Database
	DECLARE acc_curs CURSOR FOR 
	SELECT coa.* INTO l_rec_coa.* FROM coa 
	WHERE acct_code matches l_source_acct 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	FOREACH acc_curs 
		# Overwrite the acct code,verify it IS OK. IF NOT reject THEN check if
		# already there, IF so reject IF still ok add the account in
		FOR x = 1 TO 18 
			IF l_target_acct[x,x] != "?" THEN 
				LET l_rec_coa.acct_code[x,x] = l_target_acct[x,x] 
			END IF 
		END FOR 
		LET l_error_found = 0 
		
		DECLARE struc_curs CURSOR FOR 
		SELECT * INTO l_rec_structure.* FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = "S" 
		AND start_num > 0 
		ORDER BY start_num 
		
		FOREACH struc_curs 
			LET l_starter = l_rec_structure.start_num 
			LET l_lengther = l_rec_structure.start_num + 
			l_rec_structure.length_num - 1 
			LET l_check_code = l_rec_coa.acct_code[l_starter, l_lengther] 
			
			SELECT * INTO l_rec_validflex.* FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = l_rec_structure.start_num 
			AND flex_code = l_check_code 
			IF status = NOTFOUND THEN 
				LET l_error_found = 1 
				LET l_errmsg = " Valid Flex code ", l_check_code clipped , 
				" NOT found AT position ", l_starter USING "<<<<" 
				LET l_msgresp = kandoomsg("U",1,l_errmsg) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
		IF l_error_found THEN 
		ELSE 
			# looks OK so see IF already exists
			SELECT * INTO l_rec_s_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_coa.acct_code 
			IF status = NOTFOUND THEN 
				INSERT INTO coa VALUES (l_rec_coa.*) 
			ELSE 
				LET l_msgresp = kandoomsg("G",9027,l_rec_coa.acct_code) 
			END IF 
		END IF 
	END FOREACH 

	RETURN false 

END FUNCTION 