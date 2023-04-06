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

	Source code beautified by beautify.pl on 2020-01-03 18:54:46	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module UT6_translation_mngr handle strings translation
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

DEFINE prp_crt_import PREPARED
DEFINE prp_insert_t_import PREPARED
###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFER interrupt 
	DEFER quit 
	CALL setModuleId("UT6") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 
	
--	OPEN WINDOW U528 with FORM "U528" 
--	CALL windecoration_u("U528") 

	MENU "Data Load" 
		BEFORE MENU 
			--CALL publish_toolbar("kandoo","U222","translate-data_load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		COMMAND "Load initial temp" " SELECT details TO load" 
			CALL create_temp_table()			
		COMMAND "Exit" " RETURN TO menus" 
			EXIT MENU 
 	END MENU 
--	CLOSE WINDOW u528 
END MAIN 

FUNCTION create_temp_table()
	DEFINE l_sql_statement STRING
	
	LET l_sql_statement = "CREATE TABLE IF NOT EXISTS application_strings (string_id integer,container VARCHAR(24),string_type CHAR(10),string_contents lvarchar(256)) "
	CALL prp_crt_import.Prepare(l_sql_statement)
	CALL prp_crt_import.Execute()
	LET l_sql_statement = "TRUNCATE TABLE application_strings "
	CALL prp_crt_import.Prepare(l_sql_statement)
	CALL prp_crt_import.Execute()

	LET l_sql_statement = "INSERT INTO application_strings ", 
	" SELECT min(a.attribute_id),",
	" trim(a.form_name)||'.fm2',",
	" FORMWIDGET",
	" trim(t.translation)  ",
	" FROM attributes_translation t,form_attributes a ", 
	" WHERE t.attribute_id = a.attribute_id ", 
	" AND modif_timestamp IS NOT NULL ", 
	" AND translation IS NOT NULL ", 
	" AND trim(translation) != '' ", 
	" AND language = 'ENU' ",  
	" AND widget_id != 'lbFormName' ",
	" group by 2,3 "
	CALL prp_insert_t_import.Prepare(l_sql_statement)
	CALL prp_insert_t_import.Execute()
	
	LET l_sql_statement = "CREATE TABLE IF NOT EXISTS programs_objects (program_name CHAR(16),container CHAR(24)) "
	--CALL prp_crt_import.Prepare(l_sql_statement)
	--CALL prp_crt_import.Execute()
	--LET l_sql_statement = "TRUNCATE TABLE programs_objects "
	--CALL prp_crt_import.Prepare(l_sql_statement)
	--CALL prp_crt_import.Execute()
	--LOAD FROM "H:/Eclipse/FormListPerProgram/P21.txt"
	--INSERT INTO programs_objects
	--LOAD FROM "H:/Eclipse/FormListPerProgram/P11.txt"
	--INSERT INTO programs_objects

	LET l_sql_statement = "CREATE RAW TABLE IF NOT EXISTS strings_translation (string_id integer,language_code CHAR(3), translation lvarchar(256))"
	LET l_sql_statement = "
SELECT trim(r.string_contents) || '   { \" ' || trim(t.translation) || '\"}'
from application_strings r,
attributes_translation t
WHERE r.string_id = t.attribute_id
AND t.language = "FRA"
AND t.modif_timestamp IS NOT NULL
group by 1,2

	ERROR "temporary data loaded OK"
END FUNCTION # create_temp_table()
