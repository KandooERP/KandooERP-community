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
#   prelawind.4gl - show_supersessions
#                   Window FUNCTION FOR showing superseded AND superseding
#                   products FOR a specific product.
#
#                 - show_alternates
#                   Window FUNCTION FOR showing alternate products FOR a
#                   specific product.
#
#                 - show_companions
#                   Window FUNCTION FOR showing companion products FOR a
#                   specific product.
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_supersessions(p_cmpy,p_product_part_code)
#
# prgdwind IS used TO DISPLAY general product details
############################################################
FUNCTION show_supersessions(p_cmpy,p_product_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD --array[21] OF RECORD 
		scroll_flag CHAR(1), 
		super_part_code LIKE product.super_part_code, 
		super_desc_text LIKE product.desc_text, 
		super_desc2_text LIKE product.desc2_text 
	END RECORD 
	DEFINE l_rec_temp_product RECORD 
		scroll_flag CHAR(1), 
		super_part_code LIKE product.super_part_code, 
		super_desc_text LIKE product.desc_text, 
		super_desc2_text LIKE product.desc2_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_pr_pass SMALLINT 
	DEFINE l_sorted CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW I701 with FORM "I701" 
	CALL windecoration_i("I701") 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 Searching Database;  Please Wait;

	SELECT * INTO l_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product_part_code 

	DISPLAY BY NAME 
		l_rec_product.part_code, 
		l_rec_product.desc_text 

	LET l_idx = 0 
	IF l_rec_product.super_part_code IS NOT NULL THEN 
		WHILE l_rec_product.super_part_code IS NOT NULL 
			LET l_idx = l_idx + 1 

			SELECT * INTO l_rec_product.* FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_rec_product.super_part_code 

			LET l_arr_rec_product[l_idx].scroll_flag = ">" 
			LET l_arr_rec_product[l_idx].super_part_code = l_rec_product.part_code 
			LET l_arr_rec_product[l_idx].super_desc_text = l_rec_product.desc_text 
			LET l_arr_rec_product[l_idx].super_desc2_text = l_rec_product.desc2_text 
		END WHILE 

		# Need TO reverse ORDER TO put most superseeeding product
		# first (using a bubble sort)
		LET l_pr_pass = 1 
		LET l_sorted = false 

		WHILE NOT l_sorted 
			LET l_sorted = true 
			FOR l_counter = 1 TO (l_idx - l_pr_pass) 
				IF l_arr_rec_product[l_counter].super_part_code IS NOT NULL 
				AND l_arr_rec_product[l_counter+1].super_part_code IS NOT NULL THEN 
					LET l_rec_temp_product.* = l_arr_rec_product[l_counter].* 
					LET l_arr_rec_product[l_counter].* = l_arr_rec_product[l_counter+1].* 
					LET l_arr_rec_product[l_counter+1].* = l_rec_temp_product.* 
					LET l_sorted = false 
				END IF 
			END FOR 
			LET l_pr_pass = l_pr_pass + 1 
		END WHILE 
	END IF 

	# Load ARRAY with parts the product supersedes
--	IF l_idx < 20 THEN 
		SELECT count(*) INTO l_counter FROM product 
		WHERE cmpy_code = p_cmpy 
		AND super_part_code = p_product_part_code 

		IF l_counter != 0 THEN 
			# Insert the actual product looking AT in ARRAY FOR DISPLAY purposes
			SELECT * INTO l_rec_product.* FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_product_part_code 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_product[l_idx].super_part_code = l_rec_product.part_code 
			LET l_arr_rec_product[l_idx].super_desc_text = l_rec_product.desc_text 
			LET l_arr_rec_product[l_idx].super_desc2_text = l_rec_product.desc2_text 
		END IF 

		DECLARE c1_superprod CURSOR FOR 
		SELECT * FROM product 
		WHERE cmpy_code = p_cmpy 
		AND super_part_code = p_product_part_code 

		FOREACH c1_superprod INTO l_rec_product.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_product[l_idx].scroll_flag = "<" 
			LET l_arr_rec_product[l_idx].super_part_code = l_rec_product.part_code 
			LET l_arr_rec_product[l_idx].super_desc_text = l_rec_product.desc_text 
			LET l_arr_rec_product[l_idx].super_desc2_text = l_rec_product.desc2_text 
		END FOREACH 
--	END IF 

	LET l_msgresp = kandoomsg("U",1008,"")	#1008 F3/F4  TO Page Fwd/Bwd;  OK TO Continue.
	LET l_msgresp = kandoomsg("U",9113,l_idx)	#9113 l_idx records selected
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_product[1].* TO NULL 
	END IF 

 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prelawind","input-arr-product-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			#         IF l_arr_rec_product[l_idx].super_part_code IS NOT NULL THEN
			#            DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*
			#
			#         END IF
			NEXT FIELD scroll_flag 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET l_msgresp = kandoomsg("W",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 

			IF l_arr_rec_product[l_idx+1].super_part_code IS NULL 
			AND (fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right")) THEN 
				LET l_msgresp = kandoomsg("W",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
			#      AFTER ROW
			#         DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW I701 
END FUNCTION 
############################################################
# END FUNCTION show_supersessions(p_cmpy,p_product_part_code)
############################################################


############################################################
# FUNCTION show_alternates(p_cmpy,p_product_part_code)
#
#
############################################################
FUNCTION show_alternates(p_cmpy,p_product_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF #array[50] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			alter_part_code LIKE product.alter_part_code, 
			alter_desc_text LIKE product.desc_text, 
			alter_desc2_text LIKE product.desc2_text 
		END RECORD 
	DEFINE l_alter_part_code LIKE product.alter_part_code 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW I702 with FORM "I702" 
		CALL windecoration_i("I702") 

		LET l_msgresp = kandoomsg("U",1002,"") 		#1002 Searching Database;  Please Wait;
		SELECT * INTO l_rec_product.* FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_product_part_code 
		DISPLAY BY NAME l_rec_product.part_code, 
		l_rec_product.desc_text 

		LET l_idx = 0 
		IF l_rec_product.alter_part_code IS NOT NULL THEN 
			LET l_alter_part_code = l_rec_product.alter_part_code 
			SELECT count(*) INTO l_counter FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_alter_part_code 
			IF l_counter > 0 THEN 
				# product does NOT belong TO alternate group
				DECLARE c_altprod CURSOR FOR 
				SELECT part_code, 
				desc_text, 
				desc2_text 
				FROM product 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_alter_part_code 
				FOREACH c_altprod INTO l_rec_product.part_code, 
					l_rec_product.desc_text, 
					l_rec_product.desc2_text 
					LET l_idx = l_idx + 1 
					IF l_idx > 50 THEN 
						LET l_idx = 50 
						EXIT FOREACH 
					END IF 
					LET l_arr_rec_product[l_idx].alter_part_code = l_rec_product.part_code 
					LET l_arr_rec_product[l_idx].alter_desc_text = l_rec_product.desc_text 
					LET l_arr_rec_product[l_idx].alter_desc2_text = l_rec_product.desc2_text 
				END FOREACH 
			ELSE 
				# check IF product belongs TO alternate group
				DECLARE c_altprod2 CURSOR FOR 
				SELECT part_code, 
				desc_text, 
				desc2_text 
				FROM product 
				WHERE cmpy_code = p_cmpy 
				AND alter_part_code = l_alter_part_code 
				AND part_code <> p_product_part_code 
				FOREACH c_altprod2 INTO l_rec_product.part_code, 
					l_rec_product.desc_text, 
					l_rec_product.desc2_text 
					LET l_idx = l_idx + 1 
					IF l_idx > 50 THEN 
						LET l_idx = 50 
						EXIT FOREACH 
					END IF 
					LET l_arr_rec_product[l_idx].alter_part_code = l_rec_product.part_code 
					LET l_arr_rec_product[l_idx].alter_desc_text = l_rec_product.desc_text 
					LET l_arr_rec_product[l_idx].alter_desc2_text = l_rec_product.desc2_text 
				END FOREACH 
			END IF 
		END IF 
		LET l_msgresp = kandoomsg("U",1008,"") 
		#1008 F3/F4  TO Page Fwd/Bwd;  OK TO Continue.
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_product[1].* TO NULL 
		END IF 

		#   CALL set_count(l_idx)
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","prelawind","input-arr-product-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				#         IF l_arr_rec_product[l_idx].alter_part_code IS NOT NULL THEN
				#            DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*
				#         END IF
				NEXT FIELD scroll_flag# 
			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
				IF l_arr_rec_product[l_idx+1].alter_part_code IS NULL 
				AND (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right")) THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END if# 
				#      AFTER ROW
				#         DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*


		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		CLOSE WINDOW i702 
END FUNCTION 
############################################################
# END FUNCTION show_alternates(p_cmpy,p_product_part_code)
############################################################


############################################################
# FUNCTION show_companions(p_cmpy,p_product_part_code)
#
#
############################################################
FUNCTION show_companions(p_cmpy,p_product_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_compn_part_code LIKE product.compn_part_code 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF #array[50] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			compn_part_code LIKE product.compn_part_code, 
			compn_desc_text LIKE product.desc_text, 
			compn_desc2_text LIKE product.desc2_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_cursor_text CHAR(10) 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW i703 with FORM "I703" 
		CALL windecoration_i("I703") 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database;  Please Wait;
		SELECT * INTO l_rec_product.* FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_product_part_code 
		DISPLAY BY NAME l_rec_product.part_code, 
		l_rec_product.desc_text 

		LET l_idx = 0 
		IF l_rec_product.compn_part_code IS NOT NULL THEN 
			LET l_compn_part_code = l_rec_product.compn_part_code 
			SELECT count(*) INTO l_counter FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_compn_part_code 

			IF l_counter > 0 THEN 
				# product does NOT belong TO companion group
				DECLARE c_compnprod CURSOR FOR 
				SELECT part_code, 
				desc_text, 
				desc2_text 
				FROM product 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_compn_part_code 

				FOREACH c_compnprod INTO l_rec_product.part_code, 
					l_rec_product.desc_text, 
					l_rec_product.desc2_text 
					LET l_idx = l_idx + 1 
					IF l_idx > 50 THEN 
						LET l_idx = 50 
						EXIT FOREACH 
					END IF 
					LET l_arr_rec_product[l_idx].compn_part_code = l_rec_product.part_code 
					LET l_arr_rec_product[l_idx].compn_desc_text = l_rec_product.desc_text 
					LET l_arr_rec_product[l_idx].compn_desc2_text = l_rec_product.desc2_text 
				END FOREACH 

			ELSE 
				# check IF product belongs TO companion group
				DECLARE c_compnprod2 CURSOR FOR 
				SELECT part_code, 
				desc_text, 
				desc2_text 
				FROM product 
				WHERE cmpy_code = p_cmpy 
				AND compn_part_code = l_compn_part_code 
				AND part_code <> p_product_part_code 
				FOREACH c_compnprod2 INTO l_rec_product.part_code, 
					l_rec_product.desc_text, 
					l_rec_product.desc2_text 
					LET l_idx = l_idx + 1 
					IF l_idx > 50 THEN 
						LET l_idx = 50 
						EXIT FOREACH 
					END IF 
					LET l_arr_rec_product[l_idx].compn_part_code = l_rec_product.part_code 
					LET l_arr_rec_product[l_idx].compn_desc_text = l_rec_product.desc_text 
					LET l_arr_rec_product[l_idx].compn_desc2_text = l_rec_product.desc2_text 
				END FOREACH 
			END IF 
		END IF 

		LET l_msgresp = kandoomsg("U",1008,"")		#1008 F3/F4  TO Page Fwd/Bwd;  OK TO Continue.
		LET l_msgresp = kandoomsg("U",9113,l_idx)		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_product[1].* TO NULL 
		END IF 
		
		#   CALL set_count(l_idx)
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","prelawind","input-arr-product-3") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				#         IF l_arr_rec_product[l_idx].compn_part_code IS NOT NULL THEN
				#            DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*
				#
				#         END IF
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
				IF l_arr_rec_product[l_idx+1].compn_part_code IS NULL 
				AND (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right")) THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 

				#      AFTER ROW
				#         DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*


		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		CLOSE WINDOW i703 
END FUNCTION 
############################################################
# END FUNCTION show_companions(p_cmpy,p_product_part_code)
############################################################