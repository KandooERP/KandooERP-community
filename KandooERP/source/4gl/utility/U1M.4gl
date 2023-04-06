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

	Source code beautified by beautify.pl on 2020-01-03 18:54:42	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

#HuHo removed the lazy code....
#GLOBALS
#	DEFINE glob_rec_country RECORD LIKE country.*
#	DEFINE glob_arr_rec_country DYNAMIC ARRAY OF  --huho array[120] of record
#		RECORD
#         country_code LIKE country.country_code,
#         country_text LIKE country.country_text,
#         language_code LIKE country.language_code
#      END RECORD
#	DEFINE glob_rec_language RECORD LIKE language.*
#	DEFINE l_idx SMALLINT
#	DEFINE glob_i SMALLINT
#	DEFINE l_count SMALLINT
#	DEFINE glob_insert_flag SMALLINT
#
#END GLOBALS


###################################################################
# MAIN
#
# This Program allows the user TO enter AND
#              maintain Country Codes
###################################################################
MAIN 

	CALL setModuleId("U1M") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW g193 with FORM "G193" 
	CALL windecoration_g("G193") 

	#   WHILE select_country()
	CALL maintain_country() 
	#   END WHILE

	CLOSE WINDOW g193 

END MAIN 

###################################################################
# FUNCTION select_country()
#
#
###################################################################
FUNCTION select_country(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_arr_rec_country DYNAMIC ARRAY OF --huho array[120] OF RECORD 
		RECORD 
			country_code LIKE country.country_code, 
			country_text LIKE country.country_text, 
			language_code LIKE country.language_code 
		END RECORD 
		DEFINE l_query_text STRING 
		DEFINE l_where_text STRING 
		DEFINE l_msgresp LIKE language.yes_flag 
		DEFINE l_idx SMALLINT 

		IF p_filter THEN 

			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			CONSTRUCT BY NAME l_where_text ON country_code, 
			country_text, 
			language_code 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","U1M","construct-country") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_where_text = " 1=1 " 
			END IF 

		ELSE 
			LET l_where_text = " 1=1 " 
		END IF 

		LET l_query_text = 
		"SELECT country.* ", 
		"FROM country ", 
		"WHERE ",l_where_text clipped, 
		" ORDER BY country_text" 

		PREPARE country_query FROM l_query_text 
		DECLARE c_country CURSOR FOR country_query 

		CALL l_arr_rec_country.clear() 

		LET l_idx = 0 
		FOREACH c_country INTO l_rec_country.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_country[l_idx].country_code = l_rec_country.country_code 
			LET l_arr_rec_country[l_idx].country_text = l_rec_country.country_text 
			LET l_arr_rec_country[l_idx].language_code = l_rec_country.language_code 
			#IF l_idx = 120 THEN
			#   LET l_msgresp = kandoomsg("U",6100,l_idx)
			#   EXIT FOREACH
			#END IF
		END FOREACH 

		RETURN l_arr_rec_country 
END FUNCTION 


###################################################################
# FUNCTION maintain_country()
#
#
###################################################################
FUNCTION maintain_country() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_arr_rec_country DYNAMIC ARRAY OF --huho array[120] OF RECORD 
		RECORD 
			country_code LIKE country.country_code, 
			country_text LIKE country.country_text, 
			language_code LIKE country.language_code 
		END RECORD 
		DEFINE l_idx SMALLINT 

		LET l_msgresp = kandoomsg("U",1003,"") 
		#   LET glob_insert_flag = l_idx
		#   CALL set_count(l_idx)


		CALL select_country(false) RETURNING l_arr_rec_country 

		#INPUT ARRAY l_arr_rec_country WITHOUT DEFAULTS FROM sr_country.* ATTRIBUTE(UNBUFFERED,append row = false, auto append = false)
		DISPLAY ARRAY l_arr_rec_country TO sr_country.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","U1M","input-arr-country") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER" 
				CALL select_country(true) RETURNING l_arr_rec_country 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_idx > 0 THEN 
					LET l_rec_country.* = l_arr_rec_country[l_idx].* 
				END IF 
				#         LET l_rec_country.country_code = l_arr_rec_country[l_idx].country_code
				#         LET l_rec_country.country_text = l_arr_rec_country[l_idx].country_text
				#         LET l_rec_country.language_code = l_arr_rec_country[l_idx].language_code
				#         IF l_idx > arr_count()
				#         AND arr_count() > 0 THEN
				#            LET l_msgresp = kandoomsg("U",9001,"")
				#         ELSE
				#         #   DISPLAY l_arr_rec_country[l_idx].*        TO sr_country[scrn].*
				#
				#         END IF
				#      AFTER ROW
				#         LET l_arr_rec_country[l_idx].country_code = l_rec_country.country_code
				#         LET l_arr_rec_country[l_idx].country_text = l_rec_country.country_text
				#         LET l_arr_rec_country[l_idx].language_code = l_rec_country.language_code
				#         #DISPLAY l_arr_rec_country[l_idx].*   TO sr_country[scrn].*

			ON ACTION ("EDIT","ACCEPT","DOUBLECLICK") 
				IF l_idx > 0 THEN 
					IF l_rec_country.country_code IS NOT NULL THEN 
						CALL change_country(l_arr_rec_country[l_idx].country_code) 
						#            LET l_arr_rec_country[l_idx].country_code = l_rec_country.country_code
						#            LET l_arr_rec_country[l_idx].country_text = l_rec_country.country_text
						#            LET l_arr_rec_country[l_idx].language_code = l_rec_country.language_code
						# DISPLAY l_arr_rec_country[l_idx].*           TO sr_country[scrn].*
						CALL select_country(false) RETURNING l_arr_rec_country 
					END IF 
				END IF 

				#         NEXT FIELD country_code


				#      BEFORE FIELD country_text
				#         IF l_rec_country.country_code IS NOT NULL THEN
				#            CALL change_country()
				#            LET l_arr_rec_country[l_idx].country_code = l_rec_country.country_code
				#            LET l_arr_rec_country[l_idx].country_text = l_rec_country.country_text
				#            LET l_arr_rec_country[l_idx].language_code = l_rec_country.language_code
				#            # DISPLAY l_arr_rec_country[l_idx].*           TO sr_country[scrn].*
				#         END IF
				#         NEXT FIELD country_code

			ON ACTION "DELETE" 
				#      BEFORE DELETE
				DELETE FROM country 
				WHERE country_code = l_arr_rec_country[l_idx].country_code #l_rec_country.country_code 
				CALL select_country(false) RETURNING l_arr_rec_country 

				#         IF l_arr_rec_country.getLength() = 1 THEN
				#            LET glob_insert_flag = FALSE
				#         END IF
				#         IF l_idx != l_arr_rec_country.getLength() THEN
				#         #   INITIALIZE l_arr_rec_country[l_idx].* TO NULL
				#         #ELSE
				#            LET l_rec_country.country_code = l_arr_rec_country[l_idx+1].country_code
				#            LET l_rec_country.country_text = l_arr_rec_country[l_idx+1].country_text
				#            LET l_rec_country.language_code = l_arr_rec_country[l_idx+1].language_code
				#         END IF

			ON ACTION "NEW" 
				#BEFORE INSERT
				#         IF l_idx < l_arr_rec_country.getLength()
				#         OR ( NOT glob_insert_flag )
				#         OR (l_idx = l_arr_rec_country.getLength()
				#             AND l_rec_country.country_code IS NOT NULL) THEN
				CALL add_country() 
				#            LET l_arr_rec_country[l_idx].country_code = l_rec_country.country_code
				#            LET l_arr_rec_country[l_idx].country_text = l_rec_country.country_text
				#            LET l_arr_rec_country[l_idx].language_code = l_rec_country.language_code
				CALL select_country(false) RETURNING l_arr_rec_country 
				#DISPLAY l_arr_rec_country[l_idx].* TO sr_country[scrn].*
				#         END IF

				#         LET glob_insert_flag = TRUE
				CALL select_country(false) RETURNING l_arr_rec_country 
				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
END FUNCTION 


###################################################################
# FUNCTION add_country()
#
#
###################################################################
FUNCTION add_country() 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_count SMALLINT 
	DEFINE l_rec_language RECORD LIKE language.* 

	OPEN WINDOW g195 with FORM "G195" 
	CALL windecoration_g("G195") 

	CALL ui.interface.refresh() 

	INITIALIZE l_rec_country.* TO NULL 
	LET l_rec_country.post_code_text = "Post Code" 
	LET l_rec_country.post_code_min_num = 0 
	LET l_rec_country.post_code_max_num = 10 
	LET l_rec_country.state_code_text = "State" 
	LET l_rec_country.state_code_min_num = 0 
	LET l_rec_country.state_code_max_num = 6 
	LET l_msgresp = kandoomsg("U",1020,"Country") 

	INPUT BY NAME l_rec_country.country_code, 
	l_rec_country.country_text, 
	l_rec_country.language_code, 
	l_rec_country.post_code_text, 
	l_rec_country.post_code_min_num, 
	l_rec_country.post_code_max_num, 
	l_rec_country.state_code_text, 
	l_rec_country.state_code_min_num, 
	l_rec_country.state_code_max_num, 
	l_rec_country.bank_acc_format WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1M","input-country-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON ACTION "LOOKUP" infield(language_code) 
			LET l_rec_country.language_code = show_language() 
			NEXT FIELD language_code 

		AFTER FIELD country_code 
			IF l_rec_country.country_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD country_code 
			END IF 
			SELECT count(*) INTO l_count FROM country 
			WHERE country_code = l_rec_country.country_code 
			IF l_count > 0 THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				NEXT FIELD country_code 
			END IF 

		AFTER FIELD country_text 
			IF l_rec_country.country_text IS NULL OR 
			l_rec_country.country_text = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD country_text 
			END IF 

		AFTER FIELD language_code 
			IF l_rec_country.language_code IS NOT NULL THEN 
				SELECT language.* INTO l_rec_language.* FROM language 
				WHERE language_code = l_rec_country.language_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9037,"") 
					NEXT FIELD language_code 
				ELSE 
					DISPLAY BY NAME l_rec_language.language_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF l_rec_country.country_text IS NULL OR 
			l_rec_country.country_text = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD country_text 
			END IF 

			IF l_rec_country.language_code IS NOT NULL THEN 
				SELECT language.* INTO l_rec_language.* FROM language 
				WHERE language_code = l_rec_country.language_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9037,"") 
					NEXT FIELD language_code 
				ELSE 
					DISPLAY BY NAME l_rec_language.language_text 

				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	CLOSE WINDOW g195 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#      FOR glob_i = l_idx TO arr_count()
		#         IF glob_i = arr_count() THEN
		#            LET glob_arr_rec_country[glob_i].country_code = NULL
		#            LET glob_arr_rec_country[glob_i].country_text = NULL
		#            LET glob_arr_rec_country[glob_i].language_code = NULL
		#         ELSE
		#            LET glob_arr_rec_country[glob_i].country_code = glob_arr_rec_country[glob_i+1].country_code
		#            LET glob_arr_rec_country[glob_i].country_text = glob_arr_rec_country[glob_i+1].country_text
		#            LET glob_arr_rec_country[glob_i].language_code = glob_arr_rec_country[glob_i+1].language_code
		#         END IF
		#      END FOR
		#      LET glob_rec_country.country_code = glob_arr_rec_country[l_idx].country_code
		#      LET glob_rec_country.country_text = glob_arr_rec_country[l_idx].country_text
		#      LET glob_rec_country.language_code = glob_arr_rec_country[l_idx].language_code
		#  FOR glob_i = 0 TO 6-scrn
		#     DISPLAY glob_arr_rec_country[l_idx+glob_i].* TO sr_country[scrn+glob_i].*
		#  END FOR
		RETURN false 
	ELSE 
		INSERT INTO country VALUES (l_rec_country.*) 
		RETURN true 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION change_country(p_country_code)
#
#
###################################################################
FUNCTION change_country(p_country_code) 
	DEFINE p_country_code LIKE country.country_code 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_language RECORD LIKE language.* 
	OPEN WINDOW g195 with FORM "G195" 
	CALL windecoration_g("G195") 

	SELECT * INTO l_rec_country.* FROM country 
	WHERE country_code = p_country_code 

	IF status < 0 THEN 
		ERROR "Could not load country data for modification" 
		RETURN false 
	END IF 

	SELECT language.* INTO l_rec_language.* FROM language 
	WHERE language_code = l_rec_country.language_code 

	IF status = notfound THEN 
		LET l_rec_language.language_text = NULL 
	END IF 

	DISPLAY BY NAME l_rec_country.country_code, 
	l_rec_country.country_text, 
	l_rec_country.language_code, 
	l_rec_language.language_text, 
	l_rec_country.post_code_text, 
	l_rec_country.post_code_min_num, 
	l_rec_country.post_code_max_num, 
	l_rec_country.state_code_text, 
	l_rec_country.state_code_min_num, 
	l_rec_country.state_code_max_num, 
	l_rec_country.bank_acc_format 

	LET l_msgresp = kandoomsg("U",1020,"Country") 
	INPUT BY NAME l_rec_country.country_text, 
	l_rec_country.language_code, 
	l_rec_country.post_code_text, 
	l_rec_country.post_code_min_num, 
	l_rec_country.post_code_max_num, 
	l_rec_country.state_code_text, 
	l_rec_country.state_code_min_num, 
	l_rec_country.state_code_max_num, 
	l_rec_country.bank_acc_format WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1M","input-country-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(language_code) 
			LET l_rec_country.language_code = show_language() 
			NEXT FIELD language_code 


			#      AFTER FIELD country_text
			#         IF l_rec_language.country_text IS NULL OR
			#            l_rec_language.country_text = " " THEN
			#            LET l_msgresp = kandoomsg("U",9102,"")
			#            NEXT FIELD country_text
			#         END IF

		AFTER FIELD language_code 
			IF l_rec_country.language_code IS NOT NULL THEN 
				SELECT language.* INTO l_rec_language.* FROM language 
				WHERE language_code = l_rec_country.language_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9037,"") 
					NEXT FIELD language_code 
				ELSE 
					DISPLAY BY NAME l_rec_language.language_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF l_rec_country.country_text IS NULL OR 
			l_rec_country.country_text = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD country_text 
			END IF 
			IF l_rec_country.language_code IS NOT NULL THEN 
				SELECT language.* INTO l_rec_language.* FROM language 
				WHERE language_code = l_rec_country.language_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9037,"") 
					NEXT FIELD language_code 
				ELSE 
					DISPLAY BY NAME l_rec_language.language_text 

				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#      LET l_rec_country.country_code = glob_arr_rec_country[l_idx].country_code
		#      LET l_rec_country.country_text = glob_arr_rec_country[l_idx].country_text
		#      LET l_rec_country.language_code = glob_arr_rec_country[l_idx].language_code
	ELSE 
		UPDATE country 
		SET * = l_rec_country.* 
		WHERE country_code = l_rec_country.country_code 
	END IF 
	CLOSE WINDOW g195 


END FUNCTION 


