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
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZH_GLOBALS.4gl" 

FUNCTION AZH_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

##################################################################
# MAIN
#
# \brief module AZH.4gl  - Hold Sales Reason Maintainence Facility
# Hold Sales Reason (hold ORDER) Maintenance
##################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("AZH") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A606 with FORM "A606" 
	CALL windecoration_a("A606") 

	WHILE manage_hold_reason()	END WHILE 

	CLOSE WINDOW A606 
END MAIN 
##################################################################
# END MAIN
##################################################################


##################################################################
# FUNCTION db_holdreas_get_datasource(p_filter) 
#
#
##################################################################
FUNCTION db_holdreas_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_arr_rec_holdreas DYNAMIC ARRAY OF RECORD 
		hold_code LIKE holdreas.hold_code, 
		reason_text LIKE holdreas.reason_text 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue."
		CONSTRUCT BY NAME l_where_text ON hold_code,	reason_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZH","construct-hold") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag = 1 OR quit_flag = 1 THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = "1=1" 
		END IF 
	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	LET l_query_text = 
	"SELECT * FROM holdreas ", 
	"WHERE cmpy_code = \"",  glob_rec_kandoouser.cmpy_code CLIPPED,"\" AND ",l_where_text CLIPPED, " ", 
	"ORDER BY hold_code" 

	PREPARE s_holdreas FROM l_query_text 
	DECLARE c_holdreas CURSOR FOR s_holdreas

	LET l_idx = 0 
	FOREACH c_holdreas INTO l_rec_holdreas.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_holdreas[l_idx].hold_code = l_rec_holdreas.hold_code 
		LET l_arr_rec_holdreas[l_idx].reason_text = l_rec_holdreas.reason_text

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	LET l_msgresp=kandoomsg("U",9113,l_idx) 
	
	RETURN l_arr_rec_holdreas,l_where_text 

END FUNCTION 
##################################################################
# END FUNCTION db_holdreas_get_datasource(p_filter) 
##################################################################


##################################################################
# FUNCTION manage_hold_reason()
#
#
##################################################################
FUNCTION manage_hold_reason() 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_arr_rec_holdreas DYNAMIC ARRAY OF RECORD 
		hold_code LIKE holdreas.hold_code, 
		reason_text LIKE holdreas.reason_text 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_old_hold_code LIKE holdreas.hold_code
	DEFINE l_where_text STRING
	DEFINE l_stmt_text STRING
	DEFINE l_msgtext STRING
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	CALL db_holdreas_get_datasource(FALSE) RETURNING l_arr_rec_holdreas,l_where_text

	LET l_msgresp=kandoomsg("A",1003,"100") #1003 F1 TO Add;  F2 TO delete;  ENTER on line TO Edit.

	OPTIONS INPUT NO WRAP
	INPUT ARRAY l_arr_rec_holdreas WITHOUT DEFAULTS FROM sr_holdreas.* ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZH","inp-arr-holdreas") 
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_holdreas.getSize())
			CALL dialog.setActionHidden("APPEND",TRUE)

      BEFORE DELETE
         LET l_idx = arr_curr()
         IF l_idx > 0 THEN
            IF l_arr_rec_holdreas[l_idx].hold_code IS NOT NULL OR 
               l_arr_rec_holdreas[l_idx].reason_text IS NOT NULL THEN 
               IF hold_inuse(l_arr_rec_holdreas[l_idx].hold_code) THEN 
                  LET l_msgtext = "Customer, Order or Quotation exists on Hold with this Hold Code.\nDeletion is not Permitted."
                  CALL msgerror("",l_msgtext)	
  				      # LET l_msgresp=kandoomsg("A",7012,l_arr_rec_holdreas[l_idx].hold_code) 
				      #     NOT permitted.  Any key TO continue.
				      CANCEL DELETE
               ELSE 
                  LET l_msgtext = "Confirmation to delete Sales Hold Reason code?"
                  IF NOT promptTF("",l_msgtext,0) THEN
                     CANCEL DELETE
                  END IF
               END IF
            END IF
         END IF

      BEFORE FIELD hold_code
         LET l_idx = arr_curr()
         LET l_old_hold_code = l_arr_rec_holdreas[l_idx].hold_code

		ON ACTION "FILTER" 
			CALL l_arr_rec_holdreas.clear()
			CALL db_holdreas_get_datasource(TRUE) RETURNING l_arr_rec_holdreas,l_where_text

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD hold_code
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN
				FOR i = 1 TO arr_count() 
			      IF i <> l_idx THEN 
				      IF l_arr_rec_holdreas[l_idx].hold_code = 
				         l_arr_rec_holdreas[i].hold_code THEN 
					      LET l_msgresp=kandoomsg("A",9021,"") 
					      #9021 Sales Hold Reason Code already exists;  Please Re Enter.
                     LET l_old_hold_code = NULL
					      NEXT FIELD hold_code 
                  ELSE
                     IF hold_inuse(l_old_hold_code) THEN 
                        # LET l_msgresp=kandoomsg("A",7013,"")
                        #7013 Customer, Order or Quotation exists on Hold with ...
                        LET l_old_hold_code = NULL
					      END IF
				      END IF 
               ELSE 
                  IF FIELD_TOUCHED(sr_holdreas.hold_code) THEN
                     IF hold_inuse(l_old_hold_code) THEN 
                        LET l_msgresp=kandoomsg("A",7013,"")
                        #7013 Customer, Order or Quotation exists on Hold with ...
                        LET l_arr_rec_holdreas[l_idx].hold_code = l_old_hold_code
                        LET l_old_hold_code = NULL
					      END IF
                  END IF
				   END IF 
			   END FOR
         END IF 

	END INPUT 
   OPTIONS INPUT WRAP

	IF int_flag = 1 OR quit_flag = 1 THEN 
      # "Cancel" action activated.
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
      # "Apply" action activated.
      BEGIN WORK
         WHENEVER SQLERROR CONTINUE
         SQL SET CONSTRAINTS pk_holdreas DISABLED END SQL 
         LET l_stmt_text = "DELETE FROM holdreas ",
                        	"WHERE cmpy_code = \"",  glob_rec_kandoouser.cmpy_code CLIPPED,"\" AND ",l_where_text 
         PREPARE p_delete FROM l_stmt_text
         EXECUTE p_delete
         SQL SET CONSTRAINTS pk_holdreas ENABLED END SQL
         WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

         FOR l_idx = 1 TO arr_count()
            LET l_rec_holdreas.cmpy_code = glob_rec_kandoouser.cmpy_code
            LET l_rec_holdreas.hold_code = l_arr_rec_holdreas[l_idx].hold_code
            LET l_rec_holdreas.reason_text = l_arr_rec_holdreas[l_idx].reason_text
            INSERT INTO holdreas VALUES(l_rec_holdreas.*)
         END FOR 
      COMMIT WORK

		RETURN TRUE 
	END IF 

END FUNCTION 
##################################################################
# END FUNCTION manage_hold_reason()
##################################################################


##################################################################
# FUNCTION hold_inuse(p_hold_code)
#
#
##################################################################
FUNCTION hold_inuse(p_hold_code) 
	DEFINE p_hold_code LIKE holdreas.hold_code 
	DEFINE l_cnt INTEGER

   LET l_cnt = 0
	SELECT COUNT(*) INTO l_cnt FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      hold_code = p_hold_code 

	IF l_cnt <> 0 THEN 
		RETURN TRUE 
	END IF 

	SELECT COUNT(*) INTO l_cnt FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      hold_code = p_hold_code 

	IF l_cnt <> 0 THEN 
		RETURN TRUE 
	END IF
	
	SELECT COUNT(*) INTO l_cnt FROM quotehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
	      hold_code = p_hold_code 

	IF l_cnt <> 0 THEN 
		RETURN TRUE 
	END IF

	RETURN FALSE 
END FUNCTION 
##################################################################
# END FUNCTION hold_inuse(p_hold_code)
##################################################################