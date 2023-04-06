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

	Source code beautified by beautify.pl on 2020-01-02 10:35:44	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


############################################################
# FUNCTION show_part(p_cmpy,l_filter_text)
#
#     wpartwind.4gl - show_part
#                     Window FUNCTION FOR finding product records
#                     FUNCTION will RETURN part_code TO calling program
############################################################
FUNCTION show_part_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_pc_mc_with_scrollflag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			desc_text, 
			prodgrp_code, 
			maingrp_code, 
			desc2_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wpartwind","construct-product") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_product.part_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM product ", 
		"WHERE cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		"AND status_ind <> '3' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY part_code" 
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	LET l_idx = 0 
	FOREACH c_product INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[l_idx].prodgrp_code = l_rec_product.prodgrp_code 
		LET l_arr_rec_product[l_idx].maingrp_code = l_rec_product.maingrp_code 
		#         IF l_idx = 100 THEN
		#            LET l_msgresp = kandoomsg("U",6100,l_idx)
		#            EXIT FOREACH
		#         END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_product.getLength()) 
	#9113 "l_idx records selected"
	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_product[1].* TO NULL
	#      END IF

	RETURN l_arr_rec_product 

END FUNCTION 
############################################################
# END FUNCTION show_part(p_cmpy,l_filter_text)
############################################################


############################################################
# FUNCTION show_part(p_cmpy,p_filter_text)
#
#     wpartwind.4gl - show_part
#                     Window FUNCTION FOR finding product records
#                     FUNCTION will RETURN part_code TO calling program
############################################################
FUNCTION show_part(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_pc_mc_with_scrollflag 
	#	 #array[100] of record
	#			RECORD
	#         scroll_flag CHAR(1),
	#         part_code LIKE product.part_code,
	#         desc_text LIKE product.desc_text,
	#         prodgrp_code LIKE product.prodgrp_code,
	#         maingrp_code LIKE product.maingrp_code
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
 

	#   IF p_filter_text IS NULL THEN
	#      LET p_filter_text = " 1=1 "
	#   END IF
	#   OPTIONS INSERT KEY F36,
	#           DELETE KEY F36
	#


	OPEN WINDOW W282 with FORM "W282" 
	CALL windecoration_w("W282") -- albo kd-758 

	CALL show_part_filter_datasource(FALSE) RETURNING l_arr_rec_product 

	WHENEVER ERROR STOP 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET l_msgresp = kandoomsg("U",1006,"") 
	#1006 " ESC on line TO SELECT - F10 TO Add"

	#      CALL set_count(l_idx)
	#INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wpartwind","input-arr-product") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL show_part_filter_datasource(TRUE) RETURNING l_arr_rec_product 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#            LET scrn = scr_line()
			IF l_arr_rec_product[l_idx].part_code IS NOT NULL THEN 
				SELECT * INTO l_rec_product.* 
				FROM product 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_arr_rec_product[l_idx].part_code 
				DISPLAY BY NAME l_rec_product.desc2_text 
				#               DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*

			END IF 
			LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code 

			#            NEXT FIELD scroll_flag

		ON KEY (F10) 
			CALL run_prog("I11","","","","") 
			#            NEXT FIELD scroll_flag

			#        AFTER FIELD scroll_flag
			#           LET l_arr_rec_product[l_idx].scroll_flag = NULL
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               NEXT FIELD scroll_flag
			#            END IF

			#         BEFORE FIELD part_code
			#            LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code
			#            EXIT INPUT

			#         AFTER ROW
			#            DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*

			#         AFTER INPUT
			#            LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_rec_product.part_code = NULL 
	END IF 


	CLOSE WINDOW w282 

	RETURN l_rec_product.part_code 
END FUNCTION 
############################################################
# END FUNCTION show_part(p_cmpy,p_filter_text)
############################################################