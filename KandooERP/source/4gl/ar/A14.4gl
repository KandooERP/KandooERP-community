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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A14_GLOBALS.4gl" 

###########################################################################
# FUNCTION A14_main()
# allows the user TO enter AND maintain notes on each customer
# by date AND date text
###########################################################################
FUNCTION A14_main() 
	DEFER quit 
	DEFER interrupt 
	 
	CALL setModuleId("A14") #Initial Program Initialization 

	CALL create_table("customernote","t_customernote","","Y") 

	IF get_url_cust_code() IS NOT NULL THEN 
		CALL edit_notes(glob_rec_kandoouser.cmpy_code,get_url_cust_code()) 
	ELSE 
		OPEN WINDOW A654 with FORM "A654" 
		CALL windecoration_a("A654") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		CALL scan_note() 

		CLOSE WINDOW A654 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION A14_main()
###########################################################################


##############################################################
# FUNCTION customernote_get_datasource(p_filter)
#
#
##############################################################
FUNCTION customernote_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE x SMALLINT 
	DEFINE l_rec_custnote RECORD 
		note_date LIKE customernote.note_date, 
		note_text LIKE customernote.note_text, 
		cust_code LIKE customer.cust_code 
	END RECORD 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		note_date LIKE customernote.note_date, 
		note_text LIKE customernote.note_text, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text 
	END RECORD
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 
	
		CONSTRUCT BY NAME l_where_text ON 
			customernote.note_date, 
			customernote.note_text, 
			customernote.cust_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A14","construct-customernote") 
	
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
	 
		MESSAGE kandoomsg2("A",1002,"") 
		LET l_query_text = 
			"SELECT customernote.note_date,", 
			"customernote.note_text,", 
			"customernote.cust_code ", 
			"FROM customernote,customer ", 
			"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customernote.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND customernote.cust_code = customer.cust_code ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 3,1 desc" 

		PREPARE s_customer FROM l_query_text 
		DECLARE c_customer CURSOR FOR s_customer 

	LET l_idx = 0 
	FOREACH c_customer INTO l_rec_custnote.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_custnote.cust_code 
		LET l_arr_rec_customer[l_idx].note_date = l_rec_custnote.note_date 
		LET l_arr_rec_customer[l_idx].note_text = l_rec_custnote.note_text 

		SELECT name_text INTO l_arr_rec_customer[l_idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_custnote.cust_code
		 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_arr_rec_customer.getSize() = 0 THEN
		ERROR "No customer notes found!"
	END IF

	RETURN l_arr_rec_customer

END FUNCTION 
##############################################################
# END FUNCTION customernote_get_datasource(p_filter)
##############################################################


##############################################################
# FUNCTION scan_note()
#
#
##############################################################
FUNCTION scan_note() 
	DEFINE l_rec_custnote RECORD 
		note_date LIKE customernote.note_date, 
		note_text LIKE customernote.note_text, 
		cust_code LIKE customer.cust_code 
	END RECORD 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		note_date LIKE customernote.note_date, 
		note_text LIKE customernote.note_text, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text 
	END RECORD
	DEFINE l_idx SMALLINT 
{
	LET l_idx = 0 
	FOREACH c_customer INTO l_rec_custnote.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_custnote.cust_code 
		LET l_arr_rec_customer[l_idx].note_date = l_rec_custnote.note_date 
		LET l_arr_rec_customer[l_idx].note_text = l_rec_custnote.note_text 
		SELECT name_text INTO l_arr_rec_customer[l_idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_custnote.cust_code 
 
	END FOREACH 

	CALL set_count(l_idx)
} 
	
	CALL customernote_get_datasource(FALSE) RETURNING l_arr_rec_customer
	

	MESSAGE kandoomsg2("A",1031,"") 

	INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* ATTRIBUTE(UNBUFFERED, append row = false, insert row = false, delete row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A14","inp-arr-customer") 
			IF l_arr_rec_customer.getSize() = 0 THEN
				ERROR "No customer notes found!"
			END IF
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Refresh"
			CALL windecoration_a("A654")
			CALL l_arr_rec_customer.clear()
			CALL customernote_get_datasource(FALSE) RETURNING l_arr_rec_customer

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL customernote_get_datasource(TRUE) RETURNING l_arr_rec_customer

		BEFORE ROW 
			LET l_idx = arr_curr() 
 

		ON ACTION ("EDIT","doubleClick") 
			NEXT FIELD note_date 

		BEFORE FIELD note_date 
			CALL edit_notes(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code) 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 

	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	
END FUNCTION 
##############################################################
# END FUNCTION scan_note()
##############################################################