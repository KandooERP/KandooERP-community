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

	Source code beautified by beautify.pl on 2020-01-02 10:35:39	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


####################################################################
# FUNCTION show_vend(p_cmpy)
#
#     vendwind.4gl - show_vend
#                    Window FUNCTION FOR finding vendor records
#                    FUNCTION will RETURN vend_code TO calling program
####################################################################
FUNCTION show_vend(p_cmpy,p_vend_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF t_rec_vendor_vc_nt_ct 
	#DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF
	#	RECORD --array[100] of record
	#		vend_code LIKE vendor.vend_code,
	#		name_text LIKE vendor.name_text,
	#		contact_text LIKE vendor.contact_text
	#	END RECORD
	DEFINE l_idx SMALLINT --programarrayindex --scrn 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_where_text = "1=1" 

	OPEN WINDOW p102 with FORM "P102" 
	CALL winDecoration_p("P102") 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	SET LOCK MODE TO WAIT 2

	WHILE TRUE 

		CALL l_arr_rec_vendor.clear() 
		CALL db_vendor_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_vendor 

		#      LET l_msgresp = kandoomsg("U",1002,"")
		#      #1002 " Searching database - please wait"
		#      LET l_query_text = "SELECT * FROM vendor ",
		#                        "WHERE cmpy_code = '",p_cmpy,"' ",
		#                          "AND ",l_where_text clipped," ",
		#                        "ORDER BY vend_code"
		#      WHENEVER ERROR CONTINUE
		#      OPTIONS sql interrupt on
		#      PREPARE s_vendor FROM l_query_text
		#      DECLARE c_vendor CURSOR FOR s_vendor
		#
		#      CALL l_arr_rec_vendor.CLEAR()
		#      LET l_idx = 0
		#      FOREACH c_vendor INTO l_rec_vendor.*
		#         LET l_idx = l_idx + 1
		#         LET l_arr_rec_vendor[l_idx].vend_code = l_rec_vendor.vend_code
		#         LET l_arr_rec_vendor[l_idx].name_text = l_rec_vendor.name_text
		#         LET l_arr_rec_vendor[l_idx].contact_text = l_rec_vendor.contact_text
		#         #IF l_idx = 100 THEN
		#         #   LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         #   EXIT FOREACH
		#         #END IF
		#      END FOREACH

		LET l_msgresp=kandoomsg("U",9113,l_arr_rec_vendor.getSize()) 
		#U9113 l_idx records selected

		#      IF l_idx = 0 THEN
		#         LET l_idx = 1
		#         INITIALIZE l_arr_rec_vendor[1].* TO NULL
		#      END IF

		#      WHENEVER ERROR STOP
		#      OPTIONS sql interrupt off

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		DISPLAY ARRAY l_arr_rec_vendor TO sr_vendor.* ATTRIBUTE(UNBUFFERED) --huho INPUT ARRAY l_arr_rec_vendor WITHOUT DEFAULTS FROM sr_vendor.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","vendwind","display-arr-vendor") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Filter" 
				CALL db_vendor_query_filter() RETURNING l_where_text 
				CALL db_vendor_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_vendor 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#DISPLAY l_arr_rec_vendor[l_idx].* TO sr_vendor[scrn].*

				INITIALIZE l_rec_vendor.* TO NULL 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = l_arr_rec_vendor[l_idx].vend_code 
				DISPLAY 
				l_rec_vendor.cmpy_code, 
				l_rec_vendor.cmpy_code, 
				l_rec_vendor.vend_code, 
				l_rec_vendor.name_text, 
				l_rec_vendor.tax_code, 
				l_rec_vendor.language_code, 
				l_rec_vendor.term_code, 
				l_rec_vendor.tax_code, 
				l_rec_vendor.type_code, 
				l_rec_vendor.term_code, 
				l_rec_vendor.tax_code, 
				l_rec_vendor.vat_code, 
				l_rec_vendor.addr1_text, 
				l_rec_vendor.addr2_text, 
				l_rec_vendor.addr3_text, 
				l_rec_vendor.city_text, 
				l_rec_vendor.state_code, 
				l_rec_vendor.post_code, 
				l_rec_vendor.country_code, 
--@db-patch_2020_10_04--				l_rec_vendor.country_text, 
				l_rec_vendor.contact_text 
				TO srec_rec_vendor.* 

				#NEXT FIELD scroll_flag

			ON KEY (F10) -- RUN p11-> vendor information 
				CALL run_prog("P11","","","","") 
				#NEXT FIELD scroll_flag

				#AFTER FIELD scroll_flag
				#   LET l_arr_rec_vendor[l_idx].scroll_flag = NULL
				#   IF  fgl_lastkey() = fgl_keyval("down")
				#   AND arr_curr() >= arr_count() THEN
				#      LET l_msgresp = kandoomsg("U",9001,"")
				#      NEXT FIELD scroll_flag
				#   END IF

			ON ACTION ("ACCEPT","DOUBLECLICK") 
				#BEFORE FIELD vend_code
				LET l_rec_vendor.vend_code = l_arr_rec_vendor[l_idx].vend_code 
				EXIT DISPLAY 

				#AFTER ROW
				#   DISPLAY l_arr_rec_vendor[l_idx].* TO sr_vendor[scrn].*

			AFTER DISPLAY 
				LET l_rec_vendor.vend_code = l_arr_rec_vendor[l_idx].vend_code 



		END DISPLAY 
		# ------------------------------------------------------------------------------------------

		IF int_flag THEN 
			LET int_flag = FALSE 
			LET l_rec_vendor.vend_code = p_vend_code 
			EXIT WHILE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW p102 

	RETURN l_rec_vendor.vend_code 
END FUNCTION 



FUNCTION db_vendor_query_filter() 
	#	DEFINE l_query_text  CHAR(800)
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON vend_code, 
	name_text, 
	contact_text, 
	type_code, 
	term_code, 
	tax_code, 
	vat_code, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","vendwind","construct-vendor") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 


	IF int_flag THEN 
		LET int_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
