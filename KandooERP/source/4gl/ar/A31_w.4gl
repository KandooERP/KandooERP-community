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
#  Module :       A31_w
#  Parameters:    None
#  Description:   Window FOR viewing batches of cash receipts
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
### FUNCTION:   Window FOR viewing AND selecting
### Parameters: none
### Usage:      CALL view_batch() RETURNING receiving_variable
###########################################################################


###########################################################################
# FUNCTION view_batch(p_cmpy_code)
#
#
###########################################################################
FUNCTION view_batch(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_arr_rec_browse_rec array[100] OF RECORD 
		batch_no LIKE cashrcphdr.batch_no, 
		batch_date LIKE cashrcphdr.batch_date, 
		batch_total LIKE cashrcphdr.batch_total 
	END RECORD 
	DEFINE l_idx SMALLINT
	DEFINE l_cnt SMALLINT
	DEFINE l_another_selection CHAR(1) 
	DEFINE l_construct_fields CHAR(200) 
	DEFINE l_win_query_text CHAR(200) 

	OPEN WINDOW A31_w with FORM "A31_w" 
	CALL windecoration_a("A31_w") 

	WHILE true 

		LABEL reselect: 

		LET l_another_selection = "N" 

		CLEAR FORM 
		MESSAGE " Enter your search criteria, press ESCAPE TO commence search " 


		CONSTRUCT BY NAME l_construct_fields ON batch_no, batch_date, batch_total 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A31_w","construct-batch") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			CALL interrupt_handler() 
			CLOSE WINDOW A31_w 
			RETURN "" 
		END IF 

		LET l_win_query_text = 
		"SELECT batch_no, batch_date, batch_total FROM cashrcphdr", 
		" WHERE ", l_construct_fields clipped, 
		" AND cashrcphdr.batch_posted IS NULL", 
		" AND cmpy_code = '",p_cmpy_code,"' ", 
		" ORDER BY batch_no DESC" 

		PREPARE browse_id FROM l_win_query_text 
		DECLARE browse_curs CURSOR FOR browse_id 
		OPEN browse_curs 

		LET l_idx = 1 

		FOREACH browse_curs INTO l_arr_rec_browse_rec[l_idx].* 

			LET l_idx = l_idx + 1 
			IF l_idx > 100 THEN 

				### Restrict the selection of records TO 100 as the ARRAY has been declared
				### as 100 FOR system resource reasons

				MESSAGE 
				" Only the first 100 records selected: please limit your selections" 
				attribute (RED) 
				EXIT FOREACH 
			END IF 

		END FOREACH 

		CLOSE browse_curs 

		LET l_idx = l_idx -1 

		IF l_idx > 0 THEN 
			EXIT WHILE 
		END IF 

		### ELSE IF no records selected

		MESSAGE " No records matched your selection" attribute (RED) 
		SLEEP 2 
		GOTO reselect 

	END WHILE 

	LET l_cnt = l_idx 
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_rec_browse_rec WITHOUT DEFAULTS FROM sa_browse_rec.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A31_w","inp-arr-browse_rec") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (F9) 
			CLEAR FORM 
			LET l_another_selection = "Y" 
			EXIT INPUT 

		BEFORE ROW 

			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
--			IF l_idx <= l_cnt THEN 
--				#   DISPLAY l_arr_rec_browse_rec[l_idx].* TO sa_browse_rec[scrn].*
--				#   ATTRIBUTE(RED, REVERSE)
--			END IF 

		AFTER ROW 

--			IF l_idx <= l_cnt THEN 
--				#DISPLAY l_arr_rec_browse_rec[l_idx].* TO sa_browse_rec[scrn].*
--				#ATTRIBUTE(GREEN, NORMAL)
--			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CALL interrupt_handler() 
		CLOSE WINDOW A31_w 
		RETURN "" 
	END IF 

	IF l_another_selection = "Y" THEN 
		GOTO reselect 
	END IF 

	LET l_idx = arr_curr() 

	CLOSE WINDOW A31_w 

	RETURN l_arr_rec_browse_rec[l_idx].batch_no 

END FUNCTION 
###########################################################################
# END FUNCTION view_batch(p_cmpy_code)
###########################################################################