# Hold Pay Codes PZ3
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:51	$Id: $
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

FUNCTION PZ3_whenever_sqlerror ()
	# this code instanciates the default sql errors handling for all the code lines below this function
	# it is a compiler preprocessor instruction. It is not necessary to execute that function
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION


############################################################
# MAIN
#
#Program PZ3   Stop Payment Codes
############################################################
MAIN 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_arr_rec_holdpay DYNAMIC ARRAY OF 
		RECORD 
			hold_code LIKE holdpay.hold_code, 
			hold_text LIKE holdpay.hold_text 
		END RECORD 
	DEFINE l_msgtext STRING
	DEFINE idx SMALLINT
	DEFINE i SMALLINT	

	DEFER QUIT 
	DEFER INTERRUPT 

	#Initial UI Init
	CALL setModuleId("PZ3") 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_p_ap() #init p/ap module #PZ3 configurations is required for PZP  

	DECLARE c_pay CURSOR FOR 
		SELECT holdpay.* FROM holdpay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		ORDER BY hold_code

	OPEN WINDOW WP139 with FORM "P139" 
	CALL windecoration_p("P139") 
	CALL displaymoduletitle(NULL) 

	LET l_rec_holdpay.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET idx = 0 
	FOREACH c_pay INTO l_rec_holdpay.*
		LET idx = idx + 1 
		LET l_arr_rec_holdpay[idx].hold_code = l_rec_holdpay.hold_code 
		LET l_arr_rec_holdpay[idx].hold_text = l_rec_holdpay.hold_text 
	END FOREACH 

	OPTIONS INPUT NO WRAP
	INPUT ARRAY l_arr_rec_holdpay WITHOUT DEFAULTS FROM sr_holdpay.* ATTRIBUTE(APPEND ROW = TRUE,INSERT ROW = FALSE,AUTO APPEND = TRUE)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZ3","inp-arr-holdpay-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE DELETE
			LET idx = arr_curr()
			IF idx > 0 THEN
				IF l_arr_rec_holdpay[idx].hold_code IS NOT NULL OR 
				l_arr_rec_holdpay[idx].hold_text IS NOT NULL THEN
					LET l_msgtext = "Confirmation to delete Hold Pay Code?"
					IF NOT promptTF("",l_msgtext,0) THEN
						CANCEL DELETE
					END IF
				END IF
			END IF

		AFTER FIELD hold_code 
			LET idx = arr_curr()
			IF idx > 0 THEN
				FOR i = 1 TO arr_count() 
					IF i <> idx THEN 
						IF l_arr_rec_holdpay[idx].hold_code = 
						l_arr_rec_holdpay[i].hold_code THEN 
							ERROR "The Hold Pay Code must be unique." 
							NEXT FIELD hold_code 
						END IF 
					END IF
				END FOR
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN
				# "Apply" action activated.
				BEGIN WORK
					WHENEVER SQLERROR CONTINUE
					SQL SET CONSTRAINTS pk_holdpay DISABLED END SQL 
					DELETE FROM holdpay
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					SQL SET CONSTRAINTS pk_holdpay ENABLED END SQL
					WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

					FOR idx = 1 TO arr_count()
						LET l_rec_holdpay.cmpy_code = glob_rec_kandoouser.cmpy_code
						LET l_rec_holdpay.hold_code = l_arr_rec_holdpay[idx].hold_code
						LET l_rec_holdpay.hold_text = l_arr_rec_holdpay[idx].hold_text
						INSERT INTO holdpay VALUES(l_rec_holdpay.*)
					END FOR 
				COMMIT WORK
			END IF

	END INPUT 
	OPTIONS INPUT WRAP

	CLOSE WINDOW WP139 

END MAIN 
