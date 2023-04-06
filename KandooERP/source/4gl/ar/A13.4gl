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
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A13_GLOBALS.4gl" 
#####################################################################
# FUNCTION A13_main()
#
# A13 - allows the user TO enter AND maintain notes on each customer
# by date
#####################################################################
FUNCTION A13_main() 
	DEFINE l_arg_customer_code LIKE customer.cust_code
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A13") 

	CALL create_table("customernote","t_customernote","","Y") 
	LET l_arg_customer_code = get_url_cust_code()  
	IF l_arg_customer_code IS NOT NULL THEN 
		CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_arg_customer_code) 
	ELSE 
		OPEN WINDOW A620 with FORM "A620" 
		CALL windecoration_a("A620") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		CALL scan_cust() 

		CLOSE WINDOW A620 
	END IF 

END FUNCTION 
#####################################################################
# END FUNCTION A13_main()
#####################################################################


#####################################################################
# FUNCTION select_cust(p_filter)
#
#
#####################################################################
FUNCTION select_cust(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_outer_text CHAR(5) 
	DEFINE x SMALLINT 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF 
		RECORD 
			scroll_flag CHAR(1), 
			cust_code LIKE customer.cust_code, 
			name_text LIKE customer.name_text, 
			contact_text LIKE customer.contact_text, 
			note_date LIKE customernote.note_date 
		END RECORD 
		DEFINE l_idx SMALLINT 

	IF p_filter THEN
		#HuHo 16.09.2018 Added form for the construct
		OPEN WINDOW wcustomerfilter with FORM "A620S" 
		CALL windecoration_a("A620S") 
		#CLEAR FORM
	
		MESSAGE kandoomsg2("A",1001,"") 
	
		CONSTRUCT BY NAME l_where_text ON 
			customer.cust_code, 
			customer.name_text, 
			customer.contact_text, 
			customernote.note_date 
	
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A13","construct-customer") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		CLOSE WINDOW wcustomerfilter 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF
	ELSE
			LET l_where_text = " 1=1 "
	END IF		
			 

	MESSAGE kandoomsg2("A",1002,"") 
	LET l_outer_text = "outer" 
	FOR x = 1 TO (length(l_where_text) -11) 
		IF l_where_text[x,x+11] = "customernote" THEN 
			LET l_outer_text = NULL 
			EXIT FOR 
		END IF 
	END FOR 

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = 
			"SELECT unique customer.* ", 
			"FROM customer,",l_outer_text," ", 
			"customernote ", 
			"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customer.delete_flag='N' ", 
			"AND customernote.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customernote.cust_code = customer.cust_code ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY cust_code" 

	ELSE 

		LET l_query_text = 
			"SELECT unique customer.* ", 
			"FROM customer,",l_outer_text," ", 
			"customernote ", 
			"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customer.delete_flag='N' ", 
			"AND customernote.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customernote.cust_code = customer.cust_code ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY name_text, cust_code" 
	END IF 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	LET l_idx = 0 
	FOREACH c_customer INTO l_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].contact_text = l_rec_customer.contact_text 

		SELECT max(note_date) INTO l_arr_rec_customer[l_idx].note_date 
		FROM customernote 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 

		IF l_arr_rec_customer[l_idx].note_date = "31/12/99" THEN 
			LET l_arr_rec_customer[l_idx].note_date = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_arr_rec_customer.getSize() = 0 THEN
		ERROR "No Customers found"
	END IF
	
	RETURN l_arr_rec_customer
END FUNCTION 
#####################################################################
# END FUNCTION select_cust(p_filter)
#####################################################################


#####################################################################
# FUNCTION scan_cust()
#
#
#####################################################################
FUNCTION scan_cust() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD #array[100] OF RECORD 
			scroll_flag CHAR(1), 
			cust_code LIKE customer.cust_code, 
			name_text LIKE customer.name_text, 
			contact_text LIKE customer.contact_text, 
			note_date LIKE customernote.note_date 
		END RECORD 
		DEFINE l_idx SMALLINT 
 		DEFINE l_rows_count SMALLINT

		CALL select_cust(FALSE) RETURNING l_arr_rec_customer
		LET l_rows_count = l_arr_rec_customer.getSize()
	
		MESSAGE kandoomsg2("A",1031,"") 

		DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A13","inp-arr-customer") 
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
				CALL l_arr_rec_customer.clear()
				CALL select_cust(TRUE) RETURNING l_arr_rec_customer
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())
			
			ON ACTION "REFRESH"
				CALL l_arr_rec_customer.clear()
				CALL select_cust(FALSE) RETURNING l_arr_rec_customer
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_customer.getSize())

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION ("EDIT","DOUBLECLICK") 
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN 
					CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code) 

					SELECT max(note_date) INTO l_arr_rec_customer[l_idx].note_date 
					FROM customernote 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_arr_rec_customer[l_idx].cust_code 

					IF l_arr_rec_customer[l_idx].note_date = "31/12/99" THEN 
						LET l_arr_rec_customer[l_idx].note_date = NULL 
					END IF 
				END IF 

				#NEXT FIELD scroll_flag


				#      BEFORE FIELD cust_code
				#         CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code)
				#
				#         SELECT max(note_date) INTO l_arr_rec_customer[l_idx].note_date
				#           FROM customernote
				#          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#            AND cust_code = l_arr_rec_customer[l_idx].cust_code
				#
				#         IF l_arr_rec_customer[l_idx].note_date = "31/12/99" THEN
				#            LET l_arr_rec_customer[l_idx].note_date = NULL
				#         END IF
				#

		END DISPLAY 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION
#####################################################################
# END FUNCTION scan_cust()
#####################################################################