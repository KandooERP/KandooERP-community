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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}



{ FUNCTION show_sched(p_cmpy,part,warehouse) shows caller production schedules
  FOR selected products

############################################################
# NOTE: Any programs calling this FUNCTION must also link TO partwind & wlocnwin}
############################################################


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION show_sched(p_cmpy,p_part,p_ware)
#
#
############################################################
FUNCTION show_sched(p_cmpy,p_part,p_ware)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_part LIKE product.part_code
	DEFINE p_ware LIKE warehouse.ware_code
	DEFINE l_rec_ipparms RECORD LIKE ipparms.*
	DEFINE l_rec_inproduction RECORD LIKE inproduction.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_kandoouser_sign_on_code LIKE kandoouser.sign_on_code #huho NOT used
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_msgresp LIKE language.yes_flag

	OPEN WINDOW I635 WITH FORM "I635"
	CALL windecoration_i("I635")

 SELECT * INTO l_rec_inproduction.*
 FROM inproduction
 WHERE part_code = p_part
 AND ware_code = p_ware
 AND cmpy_code = p_cmpy

 IF STATUS = NOTFOUND THEN
   LET l_rec_inproduction.part_code = p_part
   LET l_rec_inproduction.ware_code = p_ware

   LET l_msgresp = kandoomsg("I",9180,"")
#9180 Enter Product Code & Warehouse Code Required

    INPUT BY NAME l_rec_inproduction.part_code,
        l_rec_inproduction.ware_code
        WITHOUT DEFAULTS

				BEFORE INPUT
					CALL publish_toolbar("kandoo","schedfunc","input-inproduction")

		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
	
			ON ACTION "actToolbarManager"
		 			CALL setupToolbar()

		ON ACTION "LOOKUP" infield(part_code)
        LET l_rec_inproduction.part_code = show_part(p_cmpy,"")
        DISPLAY BY NAME l_rec_inproduction.part_code

		ON ACTION "LOOKUP" infield(ware_code)
        LET l_rec_inproduction.ware_code = show_wlocn(p_cmpy)
        DISPLAY BY NAME l_rec_inproduction.ware_code


     BEFORE FIELD part_code
         IF p_part IS NOT NULL THEN
       NEXT FIELD ware_code
              END IF

          AFTER FIELD part_code
       SELECT * INTO l_rec_product.*
       FROM product
       WHERE part_code = l_rec_inproduction.part_code
       AND cmpy_code = p_cmpy
       IF STATUS = NOTFOUND THEN
          LET l_msgresp = kandoomsg("I",9010,"")
#9010 Product NOT found - Try Window
          NEXT FIELD part_code
       ELSE
          DISPLAY l_rec_product.desc_text TO part_text

            END IF

          AFTER FIELD ware_code
       SELECT * INTO l_rec_warehouse.*
       FROM warehouse
       WHERE ware_code = l_rec_inproduction.ware_code
       AND cmpy_code = p_cmpy
       IF STATUS = NOTFOUND THEN
          LET l_msgresp = kandoomsg("I",9030,"")
#9030 Warehouse Not Found - Try Window
          NEXT FIELD ware_code
       ELSE
         DISPLAY l_rec_warehouse.desc_text TO ware_text

       END IF

     AFTER INPUT
           IF int_flag OR quit_flag THEN ELSE
       IF l_rec_inproduction.part_code IS NULL OR
          l_rec_inproduction.ware_code IS NULL THEN
          LET l_msgresp = kandoomsg("I",9181,"")
#9181 Product Code & Warehouse Code Must Both Be Entered
          NEXT FIELD part_code
             END IF

        SELECT * INTO l_rec_inproduction.*
        FROM inproduction
        WHERE part_code = l_rec_inproduction.part_code
        AND ware_code = l_rec_inproduction.ware_code
        AND cmpy_code = p_cmpy
        IF STATUS = NOTFOUND THEN
          LET l_msgresp = kandoomsg("I",9182,"")
#9182 No Production Schedules Exist FOR This Product/Warehouse
          NEXT FIELD part_code
        END IF
       END IF

           END INPUT

 END IF

 IF int_flag OR quit_flag THEN
   LET int_flag = FALSE
   LET quit_flag = FALSE
   CLOSE WINDOW I635
   RETURN
 END IF

 SELECT * INTO l_rec_product.*
 FROM product
 WHERE part_code = l_rec_inproduction.part_code
 AND cmpy_code = p_cmpy
 DISPLAY l_rec_product.desc_text TO part_text


 SELECT * INTO l_rec_warehouse.*
 FROM warehouse
 WHERE ware_code = l_rec_inproduction.ware_code
 AND cmpy_code = p_cmpy
 DISPLAY l_rec_warehouse.desc_text TO ware_text


 SELECT * INTO l_rec_ipparms.*
 FROM ipparms
 WHERE cmpy_code = p_cmpy
 AND key_num = 1

 DISPLAY BY NAME l_rec_ipparms.ref1_text,
       l_rec_ipparms.ref2_text,
       l_rec_ipparms.ref3_text,
       l_rec_ipparms.ref4_text,
       l_rec_ipparms.ref5_text,
       l_rec_ipparms.ref6_text,
       l_rec_ipparms.ref7_text,
       l_rec_ipparms.ref8_text,
       l_rec_ipparms.ref9_text,
       l_rec_ipparms.refa_text,
       l_rec_inproduction.part_code,
       l_rec_inproduction.ware_code,
       l_rec_inproduction.sched_qty,
       l_rec_inproduction.sched_date,
       l_rec_inproduction.field1_qty,
       l_rec_inproduction.field1_date,
       l_rec_inproduction.field2_qty,
       l_rec_inproduction.field2_date,
       l_rec_inproduction.field3_qty,
       l_rec_inproduction.field3_date,
       l_rec_inproduction.field4_qty,
       l_rec_inproduction.field4_date,
       l_rec_inproduction.field5_qty,
       l_rec_inproduction.field5_date,
       l_rec_inproduction.field6_qty,
       l_rec_inproduction.field6_date,
       l_rec_inproduction.field7_qty,
       l_rec_inproduction.field7_date,
       l_rec_inproduction.field8_qty,
       l_rec_inproduction.field8_date,
       l_rec_inproduction.field9_qty,
       l_rec_inproduction.field9_date,
       l_rec_inproduction.fielda_qty,
       l_rec_inproduction.fielda_date

			CALL eventSuspend()
#LET l_msgresp = kandoomsg("I",7001,"")
#7001 Press Any Key TO Continue
    IF int_flag OR quit_flag THEN
      LET int_flag = FALSE
      LET quit_flag = FALSE
    END IF
  CLOSE WINDOW I635
END FUNCTION