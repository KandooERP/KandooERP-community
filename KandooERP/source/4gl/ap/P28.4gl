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
	Source code beautified by beautify.pl on 2020-01-03 13:41:19	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
#move all down TO local scope
#GLOBALS
#	#DEFINE pr_vendor RECORD LIKE vendor.*
#	DEFINE pr_voucher RECORD LIKE voucher.*
#	DEFINE pr_vendorinvs RECORD LIKE vendorinvs.*
#	DEFINE pt_vendorinvs RECORD LIKE vendorinvs.*
#	DEFINE pa_vendorinvs array[200] OF
#		RECORD
#			vend_code LIKE vendorinvs.vend_code,
#			inv_text LIKE vendorinvs.inv_text,
#			vouch_code LIKE vendorinvs.vouch_code,
#			entry_date LIKE vendorinvs.entry_date
#		END RECORD
#	DEFINE idx SMALLINT
#	DEFINE id_flag SMALLINT
#	DEFINE cnt SMALLINT
#	DEFINE err_flag SMALLINT
#	DEFINE ans CHAR(2)
#	#huho 14.03.2019 pr_rec_kandoouser RECORD LIKE kandoouser.*,
#	DEFINE answer CHAR(1)
#END GLOBALS
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P28 allows the user TO look AT vouchers FROM invoice numbers
############################################################
MAIN 
	DEFINE l_answer CHAR(1) 

	#Initial UI Init
	CALL setModuleId("P28") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp122 with FORM "P122" 
	CALL windecoration_p("P122") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET l_answer = "Y" 
	#WHILE l_answer = "Y"
	CALL doit() 
	#END WHILE
	CLOSE WINDOW wp122 
END MAIN 


####################################################################
# FUNCTION select_vendorinvs(p_return_query_type)
# CONSTRUCT
# RETURN l_query_text OR l_where_text
####################################################################
FUNCTION select_vendorinvs(p_return_query_type) 
	DEFINE p_return_query_type SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	MESSAGE " Enter selection criteria - press ESC TO begin search" 

	CONSTRUCT BY NAME l_where_text ON vend_code, inv_text, vouch_code, entry_date 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P28","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,null) 
			DISPLAY BY NAME glob_rec_vendor.vend_code 
			NEXT FIELD inv_text 

	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		LET l_query_text = "SELECT vend_code,inv_text,vouch_code,entry_date ", 
		"FROM vendorinvs ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		#"AND ",	where_part clipped,
		"ORDER BY vend_code, inv_text " 
	ELSE 
		LET l_query_text = "SELECT vend_code,inv_text,vouch_code,entry_date ", 
		"FROM vendorinvs ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ", l_where_text clipped, " ", 
		"ORDER BY vend_code, inv_text " 
	END IF 

	IF p_return_query_type = filter_query_select THEN 
		RETURN l_query_text 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION doit()
#
#
############################################################
FUNCTION doit() 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendorinvs RECORD LIKE vendorinvs.* 
	DEFINE l_rec_t_vendorinvs RECORD LIKE vendorinvs.* 
	DEFINE l_arr_rec_vendorinvs DYNAMIC ARRAY OF t_rec_vendorinvs # array[200] OF 
	#		RECORD
	#			vend_code LIKE vendorinvs.vend_code,
	#			inv_text LIKE vendorinvs.inv_text,
	#			vouch_code LIKE vendorinvs.vouch_code,
	#			entry_date LIKE vendorinvs.entry_date
	#		END RECORD
	DEFINE l_id_flag SMALLINT 
	DEFINE l_err_flag SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	#huho 14.03.2019 pr_rec_kandoouser RECORD LIKE kandoouser.*,
	{

		OPEN WINDOW wP122 WITH FORM "P122"
		CALL windecoration_p("P122")
	  CALL displaymoduletitle(NULL)  --first form of the module get's the title

	   MESSAGE " Enter selection criteria - press ESC TO begin search"
	   attribute (yellow)

	   CONSTRUCT BY NAME where_part on vend_code, inv_text, vouch_code, entry_date

			BEFORE CONSTRUCT
				CALL publish_toolbar("kandoo","P28","construct-vendor-1")

			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)

				ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

				ON ACTION "LOOKUP" infield (vend_code)
	                    LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,NULL)
	                    DISPLAY BY NAME glob_rec_vendor.vend_code
	                    NEXT FIELD inv_text

		END CONSTRUCT


	   IF int_flag != 0
	   OR quit_flag != 0
	   THEN
	      EXIT PROGRAM
	   END IF

	   LET sel_text =
	   "SELECT * ",
	   "FROM vendorinvs ",
	   "WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ",
	   where_part clipped,
	   "ORDER BY vend_code, inv_text "

	   PREPARE getvouch FROM sel_text



	   DECLARE c_vend CURSOR FOR getvouch
	   OPEN c_vend
	   IF int_flag != 0
	      OR quit_flag != 0
	   THEN
	      EXIT PROGRAM
	   END IF

	   LET idx = 0

	   FOREACH c_vend INTO l_rec_vendorinvs.*
	      LET idx = idx + 1
	      LET l_arr_rec_vendorinvs[idx].vend_code = l_rec_vendorinvs.vend_code
	      LET l_arr_rec_vendorinvs[idx].inv_text = l_rec_vendorinvs.inv_text
	      LET l_arr_rec_vendorinvs[idx].vouch_code = l_rec_vendorinvs.vouch_code
	      LET l_arr_rec_vendorinvs[idx].entry_date = l_rec_vendorinvs.entry_date
	      IF idx > 198 THEN
	         MESSAGE "Only first 200 selected"
	         ATTRIBUTE(yellow)
	         sleep 5
	         EXIT FOREACH
	         END IF
	      END FOREACH
	      CALL set_count (idx)
	}
	IF db_vendorinvs_get_count() > 1000 THEN 
		LET l_where_text = select_vendorinvs(filter_query_where) 
	END IF 

	#	IF l_where_text IS NOT NULL THEN
	CALL db_vendorinvs_get_arr_rec(filter_query_where,l_where_text) RETURNING l_arr_rec_vendorinvs 
	#	END IF
	MESSAGE "" 
	MESSAGE " Press RETURN on line TO view voucher detail" 
	attribute (yellow) 

	#INPUT ARRAY l_arr_rec_vendorinvs WITHOUT DEFAULTS FROM sr_vendorinvs.*  ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_vendorinvs TO sr_vendorinvs.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P28","inp-arr-vendorinvs-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			LET l_where_text = select_vendorinvs(filter_query_where) 

			IF l_where_text IS NOT NULL THEN 
				CALL l_arr_rec_vendorinvs.clear() 
				CALL db_vendorinvs_get_arr_rec(filter_query_where,l_where_text) RETURNING l_arr_rec_vendorinvs 
			END IF 

		BEFORE ROW 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_vendorinvs.vend_code = l_arr_rec_vendorinvs[idx].vend_code 
			LET l_rec_vendorinvs.inv_text = l_arr_rec_vendorinvs[idx].inv_text 
			LET l_rec_vendorinvs.vouch_code = l_arr_rec_vendorinvs[idx].vouch_code 
			LET l_rec_vendorinvs.entry_date = l_arr_rec_vendorinvs[idx].entry_date 
			LET l_id_flag = 0 

			#      IF (arr_curr() > arr_count()) THEN
			#         ERROR "There are no more invoices in the direction you are going"
			#      END IF


		ON ACTION "doubleClick" 
			#      BEFORE FIELD inv_text

			#     MESSAGE ""
			CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, l_arr_rec_vendorinvs[idx].vouch_code) 
			#NEXT FIELD vend_code

			#NEXT FIELD vend_code


	END DISPLAY 

	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 


