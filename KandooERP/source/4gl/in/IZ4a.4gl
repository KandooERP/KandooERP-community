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

	Source code beautified by beautify.pl on 2020-01-03 09:12:47	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
 
GLOBALS "I_IN_GLOBALS.4gl" 
#used as GLOBALS FROM IZ4.4gl


#move code TO IZ4a TO fix security problem

GLOBALS 
	DEFINE glob_group_type CHAR(1) 
	DEFINE glob_err_message CHAR(40) 
END GLOBALS 


####################################################################
# FUNCTION maint_ingroup()
#
#
####################################################################
FUNCTION maint_ingroup() 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	OPEN WINDOW i100 with FORM "I100" 
	 CALL windecoration_i("I100") -- albo kd-758 

	#   WHILE select_ingroup()
	CALL scan_ingroup() 
	#   END WHILE

	CLOSE WINDOW i100 
END FUNCTION 


####################################################################
# FUNCTION select_ingroup()
#
#
####################################################################
FUNCTION select_ingroup() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text STRING 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON ingroup_code,desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZ4a","construct-ingroup_code-1") -- albo kd-505 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_query_text = NULL 
	ELSE 
		#LET l_msgresp = kandoomsg("U",1002,"")
		##1002 " Searching database - please wait"
		LET l_query_text = "SELECT ingroup_code, desc_text FROM ingroup ", 
		" WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		" AND type_ind = '",glob_group_type,"' ", 
		" AND ", l_where_text clipped," ", 
		" ORDER BY ingroup_code" 
	END IF 

	RETURN l_query_text 
END FUNCTION 


####################################################################
# FUNCTION scan_ingroup()
#
#
####################################################################
FUNCTION scan_ingroup() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_ingroup RECORD LIKE ingroup.* 
	DEFINE l_arr_rec_ingroup DYNAMIC ARRAY OF t_rec_ingroup_i_d 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msg_err STRING
	DEFINE l_do_while SMALLINT
	DEFINE l_cnt INTEGER
	DEFINE idx SMALLINT 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	LET l_do_while = 1
	WHILE l_do_while

	CALL db_ingroup_get_arr_rec_i_d(filter_query_off,glob_group_type,null) RETURNING l_arr_rec_ingroup
	LET l_msgresp = kandoomsg("U",1003,"") 

	DISPLAY ARRAY l_arr_rec_ingroup TO sr_ingroup.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZ4a","input-arr-l_arr_rec_ingroup-1") -- albo kd-505 
			LET l_do_while = 0

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER" 
			LET l_query_text = select_ingroup() 
			IF l_query_text IS NULL THEN 
				CALL db_ingroup_get_arr_rec_i_d(filter_query_off,glob_group_type,null) RETURNING l_arr_rec_ingroup 
			ELSE 
				CALL db_ingroup_get_arr_rec_i_d(filter_query_select,glob_group_type,l_query_text) RETURNING l_arr_rec_ingroup 
			END IF 

		ON ACTION ("EDIT","DOUBLECLICK") 
			LET idx = arr_curr()
			IF l_arr_rec_ingroup[idx].ingroup_code IS NOT NULL THEN 
				LET l_rec_ingroup.ingroup_code = edit_ingroup(l_arr_rec_ingroup[idx].ingroup_code)
			END IF 
			CALL db_ingroup_get_arr_rec_i_d(filter_query_off,glob_group_type,null) RETURNING l_arr_rec_ingroup 

		ON ACTION "NEW" 
			LET l_rec_ingroup.ingroup_code = edit_ingroup("") 
			CALL db_ingroup_get_arr_rec_i_d(filter_query_off,glob_group_type,null) RETURNING l_arr_rec_ingroup 

		ON ACTION "DELETE" 
			LET idx = arr_curr()
			IF l_arr_rec_ingroup[idx].ingroup_code IS NOT NULL THEN 
				LET l_msg_err = "Are you sure you want to delete?" 
				IF promptTF("",l_msg_err,TRUE) 
				THEN CASE 
				        WHEN glob_group_type = "A"
                       # Alternate Product Group
   					     SELECT COUNT(*) INTO l_cnt FROM product
					        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					              alter_part_code = l_arr_rec_ingroup[idx].ingroup_code
					        IF l_cnt <> 0 THEN
					           #LET l_msgresp = kandoomsg("I",9551,"") -- It remains from the original source code of MaxDev project (albo)
					           #9551 Group IS being used cannot delete.
					           #NEXT FIELD ingroup_code
				              LET l_msg_err = "This group is being used by a product. Delete this group?"
				              IF promptTF("",l_msg_err,FALSE) 
				              THEN BEGIN WORK
                                  # Deleting assigned Alternate Products
						                UPDATE product SET alter_part_code = NULL
                                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        alter_part_code = l_arr_rec_ingroup[idx].ingroup_code                            
                                  # Deleting Alternate Product Group
				                      DELETE FROM ingroup
			                         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        type_ind = glob_group_type AND
			                               ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
				                   COMMIT WORK
                               LET l_do_while = 1
                               EXIT DISPLAY
                          ELSE NEXT FIELD ingroup_code
                          END IF
                       ELSE # Deleting Alternate Product Group
                            DELETE FROM ingroup
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                  type_ind = glob_group_type AND
			                         ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
                            	    LET l_do_while = 1
                                  EXIT DISPLAY
					        END IF
				        WHEN glob_group_type = "S"
                       # Superseded Product Group
   					     SELECT COUNT(*) INTO l_cnt FROM product
					        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					              super_part_code = l_arr_rec_ingroup[idx].ingroup_code
					        IF l_cnt <> 0 THEN
					           #LET l_msgresp = kandoomsg("I",9551,"") -- It remains from the original source code of MaxDev project (albo)
					           #9551 Group IS being used cannot delete.
					           #NEXT FIELD ingroup_code
				              LET l_msg_err = "This group is being used by a product. Delete this group?"
				              IF promptTF("",l_msg_err,FALSE) 
				              THEN BEGIN WORK
                                  # Deleting assigned Superseded Products
						                UPDATE product SET super_part_code = NULL
                                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        super_part_code = l_arr_rec_ingroup[idx].ingroup_code                            
                                  # Deleting Superseded Product Group
				                      DELETE FROM ingroup
			                         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        type_ind = glob_group_type AND
			                               ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
				                   COMMIT WORK
                               LET l_do_while = 1
                               EXIT DISPLAY
                          ELSE NEXT FIELD ingroup_code
                          END IF
                       ELSE # Deleting Superseded Product Group
                            DELETE FROM ingroup
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                  type_ind = glob_group_type AND
			                         ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
                            	    LET l_do_while = 1
                                  EXIT DISPLAY
					        END IF
				        WHEN glob_group_type = "C"
                       # Companion Product Group
					        SELECT COUNT(*) INTO l_cnt FROM product
					        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
					              compn_part_code = l_arr_rec_ingroup[idx].ingroup_code
					        IF l_cnt <> 0 THEN
					           #LET l_msgresp = kandoomsg("I",9551,"") -- It remains from the original source code of MaxDev project (albo)
					           #9551 Group IS being used cannot delete.
					           #NEXT FIELD ingroup_code
				              LET l_msg_err = "This group is being used by a product. Delete this group?"
				              IF promptTF("",l_msg_err,FALSE) 
				              THEN BEGIN WORK
                                  # Deleting assigned Companion Products
						                UPDATE product SET compn_part_code = NULL
                                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        compn_part_code = l_arr_rec_ingroup[idx].ingroup_code                            
                                  # Deleting Companion Product Group
				                      DELETE FROM ingroup
			                         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                        type_ind = glob_group_type AND
			                               ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
				                   COMMIT WORK
                               LET l_do_while = 1
                               EXIT DISPLAY
                          ELSE NEXT FIELD ingroup_code
                          END IF
                       ELSE # Deleting Companion Product Group
                            DELETE FROM ingroup
			                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
                                  type_ind = glob_group_type AND
			                         ingroup_code = l_arr_rec_ingroup[idx].ingroup_code
                            LET l_do_while = 1
                            EXIT DISPLAY
					        END IF
			        END CASE
				END IF
			END IF

	END DISPLAY 

	END WHILE

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

END FUNCTION 


####################################################################
# FUNCTION edit_ingroup(p_ingroup_code)
#
#
####################################################################
FUNCTION edit_ingroup(p_ingroup_code) 
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code 
	DEFINE l_rec_ingroup RECORD LIKE ingroup.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_alter_p_d 
	DEFINE l_arr_old_part_code DYNAMIC ARRAY OF LIKE product.part_code
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_scr_line SMALLINT
	DEFINE l_old_part_code LIKE product.part_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msg_err STRING
	DEFINE l_cnt INTEGER
	DEFINE idx SMALLINT

	OPEN WINDOW i188 with FORM "I188" 
	 CALL windecoration_i("I188") -- albo kd-758 

	INITIALIZE l_rec_ingroup.* TO NULL 
	IF p_ingroup_code IS NOT NULL THEN 
		SELECT * INTO l_rec_ingroup.* FROM ingroup 
		WHERE ingroup_code = p_ingroup_code 
		AND type_ind = glob_group_type 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("U",7001,"Group") 
			#7001 Group RECORD does NOT exist
			RETURN "" 
		END IF 
	END IF 

	LET l_msgresp = kandoomsg("U",1020,"Group") 
	#1020 Enter Group Details; OK TO Continue
	OPTIONS INPUT NO WRAP
	INPUT BY NAME l_rec_ingroup.ingroup_code, l_rec_ingroup.desc_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ4a","input-arr-l_rec_ingroup-1") -- albo kd-505 

		BEFORE FIELD ingroup_code 
			IF p_ingroup_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD ingroup_code 
			IF l_rec_ingroup.ingroup_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD ingroup_code 
			END IF 
			SELECT COUNT(*) INTO l_cnt FROM ingroup 
			WHERE ingroup_code = l_rec_ingroup.ingroup_code 
			AND type_ind = glob_group_type 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_cnt <> 0 THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				#9104 RECORD already exists
				NEXT FIELD ingroup_code 
			END IF 
			SELECT COUNT(*) INTO l_cnt FROM product 
			WHERE part_code = l_rec_ingroup.ingroup_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_cnt <> 0 THEN 
				LET l_msgresp = kandoomsg("I",9554,"") 
				#9554 This code IS already used by an existing product.
				NEXT FIELD ingroup_code 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_ingroup.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
				IF l_rec_ingroup.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD desc_text 
				END IF 
			END IF 

	END INPUT 
	OPTIONS INPUT WRAP

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		CLOSE WINDOW i188 
		RETURN "" 
	END IF 
 
	IF p_ingroup_code IS NULL THEN 
		LET glob_err_message = "IZ4 - Creating New Warehouse Product Group (ingroup)" 
		MESSAGE glob_err_message 
		LET l_rec_ingroup.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_ingroup.type_ind = glob_group_type 
		INSERT INTO ingroup VALUES (l_rec_ingroup.*) 
	ELSE 
		LET glob_err_message = "IZ4 - Updating existing Warehouse Product Group (ingroup)" 
		MESSAGE glob_err_message 
		UPDATE ingroup 
		SET desc_text = l_rec_ingroup.desc_text 
		WHERE ingroup_code = p_ingroup_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = glob_group_type 
	END IF 

	LET p_ingroup_code = l_rec_ingroup.ingroup_code 
	CALL db_product_get_alter_arr_rec(glob_group_type, l_rec_ingroup.ingroup_code) RETURNING l_arr_rec_product 
 
	INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* attribute(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ4a","input-arr-l_arr_rec_product-1") -- albo kd-505 
         CALL fgl_setactionlabel("Append", "", "", 0, FALSE) -- Deactivation of Default Action "Append" (albo)
			CALL l_arr_old_part_code.clear()

		BEFORE FIELD part_code 
         LET idx = arr_curr()			
         LET l_old_part_code = l_arr_rec_product[idx].part_code

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

#		ON KEY (control-b) infield(part_code) -- It remains from the original source code of MaxDev project (albo)
#         LET idx = arr_curr()
#			LET l_winds_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
#			IF l_winds_text IS NOT NULL THEN 
#				LET l_arr_rec_product[idx].part_code = l_winds_text 
#			END IF 
#			NEXT FIELD part_code 

		ON ACTION "DELETE" 
         LET idx = arr_curr()
			IF l_arr_rec_product[idx].part_code IS NOT NULL THEN 
				LET l_msg_err = "Are you sure you want to delete?" 
				IF promptTF("",l_msg_err,TRUE) 
				THEN LET glob_err_message = "IZ4 - Updating ingroup" 
					  IF l_arr_rec_product[idx].part_code IS NOT NULL THEN 
                    CASE
                       WHEN glob_group_type = "A"
                          # Deleting Alternate Product
							     UPDATE product SET alter_part_code = NULL 
							     WHERE part_code = l_arr_rec_product[idx].part_code AND
							           cmpy_code = glob_rec_kandoouser.cmpy_code 
                       WHEN glob_group_type = "S"
                          # Deleting Superseded Product
							     UPDATE product SET super_part_code = NULL 
							     WHERE part_code = l_arr_rec_product[idx].part_code AND
							           cmpy_code = glob_rec_kandoouser.cmpy_code 
                       WHEN glob_group_type = "C"
                          # Deleting Companion Product
							     UPDATE product SET compn_part_code = NULL 
							     WHERE part_code = l_arr_rec_product[idx].part_code AND
							           cmpy_code = glob_rec_kandoouser.cmpy_code 
                    END CASE
					  END IF 
					  CALL db_product_get_alter_arr_rec(glob_group_type, l_rec_ingroup.ingroup_code) RETURNING l_arr_rec_product
				END IF
			END IF

		ON CHANGE part_code
         LET idx = arr_curr()
         LET l_scr_line = scr_line()
			IF l_old_part_code IS NOT NULL AND 
			   l_old_part_code <> l_arr_rec_product[idx].part_code
         THEN CALL l_arr_old_part_code.append(l_old_part_code) 
         END IF 

			SELECT product.desc_text,product.desc2_text INTO l_rec_product.desc_text,l_rec_product.desc2_text FROM product 
			WHERE part_code = l_arr_rec_product[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			LET l_arr_rec_product[idx].product_text = l_rec_product.desc_text clipped," ",l_rec_product.desc2_text 
         DISPLAY l_arr_rec_product[idx].product_text TO sr_product[l_scr_line].product_text

		ON CHANGE product_text
         LET idx = arr_curr()
         LET l_scr_line = scr_line()
			SELECT product.desc_text,product.desc2_text INTO l_rec_product.desc_text,l_rec_product.desc2_text FROM product 
			WHERE part_code = l_arr_rec_product[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			LET l_arr_rec_product[idx].product_text = l_rec_product.desc_text clipped," ",l_rec_product.desc2_text 
         DISPLAY l_arr_rec_product[idx].product_text TO sr_product[l_scr_line].product_text

		AFTER FIELD part_code 
         LET idx = arr_curr()			
			IF l_arr_rec_product[idx].part_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD part_code 
			END IF 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = l_arr_rec_product[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF STATUS = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found, Try Window
				NEXT FIELD part_code 
			END IF 

         CASE
            WHEN glob_group_type = "A"  
               # Alternate Product Group
				   IF l_rec_product.alter_part_code IS NOT NULL THEN 
					   IF l_rec_product.alter_part_code = p_ingroup_code THEN 
						   LET l_msgresp = kandoomsg("I",9553,"") 
						   #9553 The product entered already belongs TO this group
						   #NEXT FIELD part_code
					   ELSE 
				         LET l_msg_err = "This product already has an alternate part or group.",
                                     "\n    Confirm to modify the alternate part or group?" 
				         IF NOT promptTF("",l_msg_err,TRUE) 
				         THEN NEXT FIELD part_code
				         END IF
					   END IF 
               END IF
            WHEN glob_group_type = "S"  
               # Superseded Product Group
				   IF l_rec_product.super_part_code IS NOT NULL THEN 
					   IF l_rec_product.super_part_code = p_ingroup_code THEN 
						   LET l_msgresp = kandoomsg("I",9553,"") 
						   #9553 The product entered already belongs TO this group
						   #NEXT FIELD part_code
					   ELSE 
				         LET l_msg_err = "This product already has a superseded part or group.",
                                     "\n    Confirm to modify the superseded part or group?" 
				         IF NOT promptTF("",l_msg_err,TRUE) 
				         THEN NEXT FIELD part_code
				         END IF
					   END IF 
               END IF
            WHEN glob_group_type = "C" 
               # Companion Product Group
				   IF l_rec_product.compn_part_code IS NOT NULL THEN 
					   IF l_rec_product.compn_part_code = p_ingroup_code THEN 
						   LET l_msgresp = kandoomsg("I",9553,"") 
						   #9553 The product entered already belongs TO this group
						   #NEXT FIELD part_code 
					   ELSE 
				         LET l_msg_err = "This product already has a companion part or group.",
                                     "\n    Confirm to modify the companion part or group?" 
				         IF NOT promptTF("",l_msg_err,TRUE) 
				         THEN NEXT FIELD part_code
				         END IF
					   END IF 
				   END IF 
			END CASE 
			LET l_arr_rec_product[idx].product_text = l_rec_product.desc_text clipped," ",l_rec_product.desc2_text

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW i188 
		RETURN p_ingroup_code 
	END IF 

	BEGIN WORK 

		LET glob_err_message = "IZ4 - Updating ingroup" 
      # Deleting reassigned Products.
		FOR idx = 1 TO l_arr_old_part_code.getlength()
          CASE
             WHEN glob_group_type = "A"
                # Alternate Product Group
  	             UPDATE product 
	             SET alter_part_code = NULL 
	             WHERE part_code = l_arr_old_part_code[idx] AND
	                   cmpy_code = glob_rec_kandoouser.cmpy_code 
             WHEN glob_group_type = "S"
                # Superseded Product Group
  	             UPDATE product 
	             SET super_part_code = NULL 
	             WHERE part_code = l_arr_old_part_code[idx] AND
	                   cmpy_code = glob_rec_kandoouser.cmpy_code
             WHEN glob_group_type = "C" 
                # Companion Product Group
	             UPDATE product 
		          SET compn_part_code = NULL 
		          WHERE part_code = l_arr_old_part_code[idx] AND 
		                cmpy_code = glob_rec_kandoouser.cmpy_code 
          END CASE
		END FOR

      # Creating assigned Products.
		FOR idx = 1 TO l_arr_rec_product.getlength() 
			IF l_arr_rec_product[idx].part_code IS NULL THEN 
				EXIT FOR 
			END IF 
         CASE
            WHEN glob_group_type = "A"
               # Alternate Product Group
				   UPDATE product SET alter_part_code = p_ingroup_code 
				   WHERE part_code = l_arr_rec_product[idx].part_code AND
				         cmpy_code = glob_rec_kandoouser.cmpy_code 
            WHEN glob_group_type = "S"
               # Superseded Product Group
				   UPDATE product SET super_part_code = p_ingroup_code 
				   WHERE part_code = l_arr_rec_product[idx].part_code AND
				         cmpy_code = glob_rec_kandoouser.cmpy_code
            WHEN glob_group_type = "C"
               # Companion Product Group
				   UPDATE product SET compn_part_code = p_ingroup_code 
				   WHERE part_code = l_arr_rec_product[idx].part_code AND
				         cmpy_code = glob_rec_kandoouser.cmpy_code 
			END CASE 
		END FOR 

	COMMIT WORK 

	CLOSE WINDOW i188 

	RETURN p_ingroup_code 
END FUNCTION 
