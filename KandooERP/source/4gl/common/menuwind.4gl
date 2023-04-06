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

	Source code beautified by beautify.pl on 2020-01-02 10:35:19	$Id: $
}

{HuHo 11.05.2019 We are planning to remove this program and 4gl sources

#          menuwind.4gl - show_menu
#                         Window FUNCTION FOR finding menu OPTIONS
GLOBALS "../common/glob_GLOBALS.4gl"

FUNCTION show_menu()
   DEFINE
      msgresp LIKE language.yes_flag,
      pr_menu3 RECORD LIKE menu3.*,
      pa_menu3 array[200] of record
         scroll_flag CHAR(1),
         run_text LIKE menu3.run_text,
         name_text LIKE menu3.name_text,
         security_ind LIKE menu3.security_ind,
         menu_path CHAR(3)
      END RECORD,
      idx,scrn SMALLINT,
      query_text  CHAR(800),
      where_text  CHAR(400),
      filter_text CHAR(200)

   OPTIONS form line 3,
#           accept key ESC,
           INSERT KEY F36,
           DELETE KEY F36
   OPEN WINDOW U525 WITH FORM "U525"

   WHILE TRUE
      CLEAR FORM
      LET msgresp = kandoomsg("U",1001,"")
#1001 " Enter Selection Criteria - ESC TO Continue"
      CONSTRUCT BY NAME where_text on run_text,
                                      name_text,
                                      security_ind

		BEFORE CONSTRUCT
			CALL publish_toolbar("kandoo","menuwind","construct-menu3")
		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()
		END CONSTRUCT


      IF int_flag OR quit_flag THEN
         LET int_flag = FALSE
         LET quit_flag = FALSE
         EXIT WHILE
      END IF
      LET msgresp = kandoomsg("U",1002,"")
#1002 " Searching database - please wait"
      LET query_text = "SELECT * FROM menu3 ",
                        "WHERE ",where_text clipped,
                        "ORDER BY 1,2,3"
      WHENEVER ERROR CONTINUE
      OPTIONS sql interrupt on
      PREPARE s_menu3 FROM query_text
      DECLARE c_menu3 CURSOR FOR s_menu3
      LET idx = 0
      FOREACH c_menu3 INTO pr_menu3.*
         LET idx = idx + 1
         LET pa_menu3[idx].run_text = pr_menu3.run_text
         LET pa_menu3[idx].name_text = pr_menu3.name_text
         LET pa_menu3[idx].security_ind = pr_menu3.security_ind
         LET pa_menu3[idx].menu_path = pr_menu3.menu1_code clipped,
                                       pr_menu3.menu2_code clipped,
                                       pr_menu3.menu3_code clipped
         IF idx = 200 THEN
            LET msgresp = kandoomsg("U",6100,idx)
            EXIT FOREACH
         END IF
      END FOREACH
      LET msgresp=kandoomsg("U",9113,idx)
#U9113 idx records selected
      IF idx = 0 THEN
         LET idx = 1
         INITIALIZE pa_menu3[1].* TO NULL
      END IF
      WHENEVER ERROR STOP
      OPTIONS sql interrupt off

      LET msgresp = kandoomsg("U",1046,"")
#1046 " Press OK TO Continue"
      CALL set_count(idx)
      INPUT ARRAY pa_menu3 WITHOUT DEFAULTS FROM sr_menu3.*
				BEFORE INPUT
					CALL publish_toolbar("kandoo","menuwind","input-arr-menu3")

				ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 			CALL setupToolbar()

         BEFORE ROW
            LET idx = arr_curr()
            LET scrn = scr_line()
            IF pa_menu3[idx].run_text IS NOT NULL THEN
               DISPLAY pa_menu3[idx].* TO sr_menu3[scrn].*

            END IF
            NEXT FIELD scroll_flag
         AFTER FIELD scroll_flag
            LET pa_menu3[idx].scroll_flag = NULL
            IF  fgl_lastkey() = fgl_keyval("down")
            AND arr_curr() >= arr_count() THEN
               LET msgresp = kandoomsg("U",9001,"")
               NEXT FIELD scroll_flag
            END IF
         AFTER ROW
            DISPLAY pa_menu3[idx].* TO sr_menu3[scrn].*

         BEFORE FIELD run_text
            NEXT FIELD scroll_flag
         ON KEY (F10)
            CALL run_prog(pa_menu3[idx].menu_path,"","","","")

      END INPUT
      IF int_flag OR quit_flag THEN
         LET int_flag = FALSE
         LET quit_flag = FALSE
      ELSE
         EXIT WHILE
      END IF
   END WHILE
   CLOSE WINDOW U525
END FUNCTION


}