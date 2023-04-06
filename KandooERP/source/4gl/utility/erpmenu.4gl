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

	Source code beautified by beautify.pl on 2020-01-03 18:54:54	$Id: $
}

{HuHo 11.05.2019 We are planning to remove this program and 4gl sources

GLOBALS "../common/glob_GLOBALS.4gl"

   DEFINE modu_rec_kandooinfo RECORD LIKE kandooinfo.*,
      glob_rec_company RECORD LIKE company.*,
      modu_rec_period RECORD LIKE period.*,
      modu_rec_control record
         maxi_text CHAR(20),
         software_text CHAR(20),
         date_text CHAR(20),
         period_text CHAR(20)
      END RECORD,
      modu_company_text LIKE company.name_text,
      modu_kandoouser_text LIKE kandoouser.name_text,
      modu_kandoouser_passwd LIKE kandoouser.passwd_ind,
      modu_rec_menu1 RECORD LIKE menu1.*,
      modu_rec_menu2 RECORD LIKE menu2.*,
      modu_rec_menu3 RECORD LIKE menu3.*,
      modu_menupath_text CHAR(9),
      modu_temp_text CHAR(200),
      modu_update_num, modu_wind2_open, modu_wind3_open, modu_spaces_cnt SMALLINT,
      modu_close1_flag, modu_close2_flag, modu_close3_flag SMALLINT,
      modu_menu_form CHAR(8),
      modu_menu3_form CHAR(8),
      modu_msgresp LIKE language.yes_flag

main
   DEFINE
		KANDOOVER  CHAR(120), x string

  CALL ui.Interface.setType("container")

#CALL ui.Interface.LoadStartMenu("startmenu/00_menu_program_launcher_static_startmenu")
#  CALL ui.Application.GetCurrent().setMenuType("Tree")   # DEFINE menu type (TreeMenu)
  CALL ui.Application.GetCurrent().SetClassNames(["tabbed_container"])

	IF get_debug() = TRUE THEN
		LET modu_rec_menu1.name_text = "A"
		LET x = modu_rec_menu1.name_text
		DISPLAY "modu_rec_menu1.name_text=", modu_rec_menu1.name_text
		DISPLAY "x=", x
		DISPLAY "I can NOT access this module variable modu_rec_menu1 FROM the debugger, it's shown as an INT ?????"
	END IF
# The logic below traps incorrect terminal types
# OR <Suse> WTK server NOT started (the most common
# error WHEN first starting.
   WHENEVER ERROR CALL terminal_MESSAGE
   CLEAR SCREEN
   WHENEVER ERROR STOP

   defer quit
   defer interrupt
   OPTIONS form line 1,
           INSERT KEY F36,
           DELETE KEY F36
   LET modu_menupath_text = get_baseProgName()
#   LET modu_menupath_text = modu_menupath_text[1,8]
#FIXME: remove this once we rename it in database

   LET modu_menupath_text = "TOPMENUR"
   CALL authenticate(modu_menupath_text)
      returning glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code

  IF get_kandoooption_feature_state("UT","AA") = "Y" THEN
      CALL check_cmpy_access()
   END IF
   SELECT * INTO glob_rec_company.* FROM company
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

   IF STATUS = NOTFOUND THEN
#U5100"  User Company NOT found - Refer system administrator  "
      LET modu_msgresp=kandoomsg("U",5100,glob_rec_kandoouser.cmpy_code)
      LET glob_rec_company.name_text = "** Not Set Up ** "
   END IF
   LET modu_company_text = glob_rec_company.name_text

   SELECT * INTO glob_rec_kandoouser.* FROM kandoouser
      WHERE sign_on_code = glob_rec_kandoouser.sign_on_code
   UPDATE kandoouser
      SET sign_on_date = today,
          cmpy_code = glob_rec_kandoouser.cmpy_code
    WHERE sign_on_code = glob_rec_kandoouser.sign_on_code
##
## Logic checks that the Software Vers. (FROM file kandoo_ver.txt)
## equals the database Vers. FROM kandooinfo table.
##
   CREATE TEMP TABLE t_KANDOOVER (v_num INTEGER) with no log

   INITIALIZE KANDOOVER TO NULL
   LET KANDOOVER=fgl_getenv("KANDOOVER")
    IF KANDOOVER IS NULL THEN
        LET KANDOOVER="kandoo_ver.txt"
    END IF

   load FROM KANDOOVER INSERT INTO t_KANDOOVER

   DECLARE c_kandooinfo CURSOR FOR
      SELECT * FROM kandooinfo
   OPEN c_kandooinfo
   FETCH c_kandooinfo INTO modu_rec_kandooinfo.*
   close c_kandooinfo


      OPEN WINDOW wcontrol WITH FORM "U524"
		CALL winDecoration("U524")
      DISPLAY "!" TO bt
      DISPLAY "!" TO bt2
      LET modu_menu_form = "U158"

   CALL display_control()

   SELECT * INTO modu_update_num FROM t_KANDOOVER
   IF STATUS = NOTFOUND
   OR modu_update_num != modu_rec_kandooinfo.update_num THEN
      LET modu_msgresp=kandoomsg("U",5005,"")
#U5005" Database & Software are different product releases "
      CLOSE WINDOW wcontrol
      EXIT PROGRAM
   END IF

   OPEN WINDOW lev1 WITH FORM modu_menu_form
  CALL winDecoration(modu_menu_form)

   WHILE topmenu()
      CALL redraw()
   END WHILE

   CLOSE WINDOW lev1

   CLOSE WINDOW wcontrol
END MAIN

FUNCTION topmenu()
   DEFINE
      l_arr_rec_menu1 array[30] of record
         answer CHAR(1),
         menu1_code LIKE menu1.menu1_code,
         name_text LIKE menu1.name_text
      END RECORD,
      l_idx,scrn, l_arr_size, x, success SMALLINT

   LET modu_temp_text = modu_company_text clipped," - Main Menu"
   LET x = (46 - length(modu_temp_text))/2
   IF x < 1 THEN LET x = 1 END IF
   LET modu_temp_text = x spaces,modu_temp_text[1,46 -x]
   LET modu_temp_text = upshift(modu_temp_text)

   DISPLAY modu_temp_text TO lbInfo1
   LET l_idx = 0
   DECLARE c_menu1 CURSOR FOR
      SELECT * FROM menu1
   ORDER BY 1

	  	IF get_debug() THEN
	  		DISPLAY "#### BEGIN FOR EACH ######-> l_idx = ", trim(l_idx), " <-###############################"
	  	END IF


   FOREACH c_menu1 INTO modu_rec_menu1.*
	  	IF get_debug() THEN
	  		DISPLAY "#### Menu Item ######-> l_idx = ", trim(l_idx), " <-############# Loop FOREACH ##################"
	  		DISPLAY "1 - modu_rec_menu1.menu1_code=", modu_rec_menu1.menu1_code, " <-> ", modu_rec_menu1.name_text
	  	END IF

      LET success = menu_check("1",modu_rec_menu1.menu1_code,"","",modu_rec_menu1.security_ind)

	  	IF get_debug() THEN
	  		DISPLAY "2 - modu_rec_menu1.menu1_code=", modu_rec_menu1.menu1_code, " <-> ", modu_rec_menu1.name_text
	  	END IF

	  IF success THEN
	  	IF get_debug() THEN
	  		DISPLAY "3 - modu_rec_menu1.menu1_code=", modu_rec_menu1.menu1_code, " <-> ", modu_rec_menu1.name_text
	  	END IF

         LET l_idx = l_idx + 1
         LET l_arr_rec_menu1[l_idx].answer = NULL
         LET l_arr_rec_menu1[l_idx].menu1_code = modu_rec_menu1.menu1_code
         LET l_arr_rec_menu1[l_idx].name_text = modu_rec_menu1.name_text

	  	IF get_debug() THEN
	  		DISPLAY "4 - ", trim(l_idx), "l_arr_rec_menu1[l_idx].menu1_code=", l_arr_rec_menu1[l_idx].menu1_code, " <-> l_arr_rec_menu1[l_idx].name_text", l_arr_rec_menu1[l_idx].name_text
	  	END IF


         IF l_idx = 30 THEN
            ERROR "No space left in array"
            sleep 3
			EXIT FOREACH
         END IF
	  ELSE
	  END IF

	  	IF get_debug() THEN
	  		DISPLAY "#### END OF LOOP Iteration FOR EACH ######-> l_idx = ", trim(l_idx), " <-###############################"
	  	END IF


   END FOREACH
	  	IF get_debug() THEN
	  		DISPLAY "#### END FOR EACH ######-> Total Count (l_idx) = ", trim(l_idx), " <-###############################"
	  	END IF



--# CALL fgl_keysetlabel("f11","RMS")
--# CALL fgl_keysetlabel("control-t","Calendar")
--# CALL fgl_keysetlabel("control-u","Detail")

--# CALL fgl_keysetlabel("control-y","About")
--# CALL fgl_keysetlabel("control-z","Setup")
   LET l_arr_size = l_idx
   CALL set_count(l_arr_size)
   LET modu_close1_flag = FALSE
   WHILE NOT modu_close1_flag
      CALL check_for_memo()

      INPUT ARRAY l_arr_rec_menu1 WITHOUT DEFAULTS FROM sa_levmenu.*
		BEFORE INPUT
			CALL publish_toolbar("kandoo","erpmenu","input-arr-menu1")
		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()


         ON KEY(control-y) 	#Show licensing info - obsolete
				CALL show_lic()


			ON ACTION "Print Manager"
#ON KEY(F11)        #URS IS the Report Management System
            CALL run_prog("URS","","","","")
            NEXT FIELD answer

         ON KEY(F12)        #run Program U17 - Memo Facility
            CALL run_prog("U17","","","","")
            NEXT FIELD answer
#On Linux terminal, CTRL-Z have the effect of susspending running program:
#[1]+  Stopped
#Tested on <Anton Dickinson> AND <Suse>
#ON KEY(control-z)
         ON KEY(control-e)      #U16 IS missing
            CALL run_prog("U16","S","","","")
            NEXT FIELD answer
         ON KEY(control-w)  #help menu
ERROR "Traped explicit CTRL-W"
sleep 3
            LET modu_menupath_text = l_arr_rec_menu1[l_idx].menu1_code
            CALL kandoohelp(modu_menupath_text)
            NEXT FIELD answer
         ON KEY(control-t)
            CALL display_calendar()
            NEXT FIELD answer
         ON KEY(control-b)
            CALL show_menu()
            OPTIONS form line 1,
                    INSERT KEY F36,
                    DELETE KEY F36
            NEXT FIELD answer

#VERY INTERESTING - this ON KEY will be detected ONLY using Querix!
#ON KEY(control-c)
#ERROR "Traped explicit CTRL-C"
#sleep 3
#LET modu_close1_flag = TRUE

ON KEY(control-q)
ERROR "Traped explicit CTRL-Q"
sleep 3
LET modu_close1_flag = TRUE


ON KEY(F10)
ERROR "Traped F10"
sleep 3

ON KEY(F9)
ERROR "Traped F9"
sleep 3
LET modu_close1_flag = TRUE

         BEFORE ROW
            LET l_idx = arr_curr()
            LET scrn = scr_line()
#CALL f_more(l_arr_size,l_idx,scrn)
            LET modu_rec_menu1.menu1_code = l_arr_rec_menu1[l_idx].menu1_code
            DISPLAY l_arr_rec_menu1[l_idx].* TO sa_levmenu[scrn].*

         BEFORE FIELD answer
            IF modu_close1_flag THEN
               EXIT INPUT
            END IF
         AFTER FIELD answer
            IF  arr_curr() = arr_count()
            AND fgl_lastkey() = fgl_keyval("down") THEN
               LET modu_msgresp=kandoomsg("U",9001,"")
               NEXT FIELD answer
            END IF
         BEFORE FIELD id
            CALL selection1(l_arr_rec_menu1[l_idx].*)
            LET l_arr_rec_menu1[l_idx].answer = NULL
            NEXT FIELD answer
         BEFORE FIELD name
            CALL selection1(l_arr_rec_menu1[l_idx].*)
            LET l_arr_rec_menu1[l_idx].answer = NULL
            NEXT FIELD answer
         AFTER ROW
            LET l_arr_rec_menu1[l_idx].answer = NULL
            IF l_idx <= l_arr_size THEN
               DISPLAY l_arr_rec_menu1[l_idx].* TO sa_levmenu[scrn].*

            END IF
         AFTER INPUT
            IF fgl_lastkey() = fgl_keyval("accept") THEN
               CALL selection1(l_arr_rec_menu1[l_idx].*)
               LET l_arr_rec_menu1[l_idx].answer = NULL
               NEXT FIELD answer
            END IF
      END INPUT
      IF int_flag OR quit_flag OR modu_close1_flag THEN
         LET modu_close1_flag = TRUE
      ELSE
         LET l_idx = arr_curr()
         CALL selection1(l_arr_rec_menu1[l_idx].*)
         LET l_arr_rec_menu1[l_idx].answer = NULL
      END IF
   END WHILE
   IF int_flag OR quit_flag THEN
      LET int_flag = FALSE
      LET quit_flag = FALSE
			IF promptTF("",kandoomsg2("U",8002,""),1)	THEN
         RETURN FALSE
      ELSE
         RETURN TRUE
      END IF
   ELSE
      RETURN TRUE
   END IF
END FUNCTION


FUNCTION selection1(l_arr_rec_menu1)
   DEFINE
      l_arr_rec_menu1 record
         answer CHAR(1),
         menu1_code LIKE menu1.menu1_code,
         name_text LIKE menu1.name_text
      END RECORD

   IF l_arr_rec_menu1.answer = "X" THEN
      CALL direct()
      CURRENT WINDOW IS lev1
      LET l_arr_rec_menu1.answer = NULL
   ELSE
      LET modu_rec_menu1.menu1_code = l_arr_rec_menu1.answer
      IF modu_rec_menu1.menu1_code IS NULL
      OR modu_rec_menu1.menu1_code  = " " THEN
         LET modu_rec_menu1.menu1_code = l_arr_rec_menu1.menu1_code
      END IF
      SELECT * INTO modu_rec_menu1.* FROM menu1
        WHERE menu1_code = modu_rec_menu1.menu1_code
		IF get_debug() = TRUE THEN
			DISPLAY "####################################"
			DISPLAY "SELECT * INTO modu_rec_menu1.* FROM menu1
        WHERE menu1_code = modu_rec_menu1.menu1_code"
			DISPLAY "modu_rec_menu1.menu1_code=", modu_rec_menu1.menu1_code
			DISPLAY "####################################"
		END IF
      IF STATUS = 0 THEN
         IF menu_check("1",modu_rec_menu1.menu1_code,"","",
                           modu_rec_menu1.security_ind) THEN
            IF secu_passwd(modu_rec_menu1.name_text,modu_rec_menu1.password_text) THEN
			IF get_debug() = TRUE THEN
				DISPLAY "Debug - CALL menu2(modu_rec_menu1.menu1_code,modu_rec_menu1.name_text)"
				DISPLAY "modu_rec_menu1.menu1_code=", modu_rec_menu1.menu1_code
				DISPLAY "modu_rec_menu1.name_text=", modu_rec_menu1.name_text
				DISPLAY "modu_rec_menu1.*=", modu_rec_menu1.*
			END IF

               CALL menu2(modu_rec_menu1.menu1_code,modu_rec_menu1.name_text)
            END IF
         END IF
      END IF
   END IF
END FUNCTION


FUNCTION menu2(p_menu1_code,p_menu1_text)
   DEFINE
      p_menu1_code LIKE menu2.menu1_code,
      p_menu1_text LIKE menu1.name_text,
      l_arr_rec_menu2 array[30] of record
         answer CHAR(1),
         menu2_code LIKE menu2.menu2_code,
         name_text LIKE menu2.name_text
      END RECORD,
      x, l_idx,scrn,l_arr_size SMALLINT

		IF get_debug() = TRUE THEN
			DISPLAY "!!!!!!!!!!!!!!!!!!!!!!"
			DISPLAY "Menu 2"
			CALL fgl_winmessage("why IS modu_temp_text a INT in debugger","why IS modu_temp_text a INT in debugger","error")
		END IF

   LET modu_temp_text = p_menu1_text clipped," Menu (",p_menu1_code,")"
   LET x = (46 - length(modu_temp_text))/2
   IF x < 1 THEN LET x = 1 END IF
   LET modu_temp_text = x spaces,modu_temp_text[1,46 -x]
   LET modu_wind2_open = TRUE

   OPEN WINDOW lev2 AT 5,8 WITH FORM modu_menu_form
	CALL winDecoration(modu_menu_form)

     LET modu_temp_text = upshift(modu_temp_text)
   DISPLAY modu_temp_text TO lbInfo1

   DECLARE c_menu2 CURSOR FOR
      SELECT * FROM menu2
       WHERE menu1_code = p_menu1_code
         AND menu2_code != "X"
       ORDER BY 1,2

   LET l_idx = 0
   FOREACH c_menu2 INTO modu_rec_menu2.*
      IF menu_check("2",modu_rec_menu2.menu1_code,
                        modu_rec_menu2.menu2_code,"",
                        modu_rec_menu2.security_ind) THEN
         LET l_idx = l_idx + 1
         LET l_arr_rec_menu2[l_idx].answer = NULL
         LET l_arr_rec_menu2[l_idx].menu2_code = modu_rec_menu2.menu2_code
         LET l_arr_rec_menu2[l_idx].name_text = modu_rec_menu2.name_text
         IF l_idx = 30 THEN
            EXIT FOREACH
         END IF
      END IF
   END FOREACH
   LET l_arr_size = l_idx
   CALL set_count(l_arr_size)
   LET modu_close2_flag = FALSE
   WHILE NOT modu_close2_flag
      CALL check_for_memo()
      INPUT ARRAY l_arr_rec_menu2 WITHOUT DEFAULTS FROM sa_levmenu.*
		BEFORE INPUT
			CALL publish_toolbar("kandoo","erpmenu","input-arr-menu2")
		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()


         ON KEY(control-y)
					CALL show_lic()


			ON ACTION "Print Manager"
#ON KEY(F11)
            CALL run_prog("URS","","","","")
            NEXT FIELD answer

         ON KEY(F12)
            CALL run_prog("U17","","","","")
            NEXT FIELD answer
         ON KEY(control-z)
            CALL run_prog("U16","S","","","")
            NEXT FIELD answer
         ON KEY(control-w)
            LET modu_menupath_text = p_menu1_code,
                                   l_arr_rec_menu2[l_idx].menu2_code
            CALL kandoohelp(modu_menupath_text)
            NEXT FIELD answer
         ON KEY(control-t)
            CALL display_calendar()
            NEXT FIELD answer
         ON KEY(control-b)
            CALL show_menu()
            OPTIONS form line 1,
                    INSERT KEY F36,
                    DELETE KEY F36
            NEXT FIELD answer
         BEFORE ROW
            LET l_idx = arr_curr()
            LET scrn = scr_line()
#CALL f_more(l_arr_size, l_idx, scrn)
            LET modu_rec_menu2.menu2_code = l_arr_rec_menu2[l_idx].menu2_code
            LET modu_rec_menu2.name_text = l_arr_rec_menu2[l_idx].name_text
            DISPLAY l_arr_rec_menu2[l_idx].* TO sa_levmenu[scrn].*

         BEFORE FIELD answer
            IF modu_close2_flag THEN
               EXIT INPUT
            END IF
         AFTER FIELD answer
            IF  arr_curr() = arr_count()
            AND fgl_lastkey() = fgl_keyval("down") THEN
               LET modu_msgresp=kandoomsg("U",9001,"")
               NEXT FIELD answer
            END IF
         BEFORE FIELD id
            CALL selection2(l_arr_rec_menu2[l_idx].*)
            LET l_arr_rec_menu2[l_idx].answer = NULL
            NEXT FIELD answer
         BEFORE FIELD name
            CALL selection2(l_arr_rec_menu2[l_idx].*)
            LET l_arr_rec_menu2[l_idx].answer = NULL
            NEXT FIELD answer
         AFTER ROW
            LET l_arr_rec_menu2[l_idx].answer = NULL
            IF l_idx <= l_arr_size THEN
               DISPLAY l_arr_rec_menu2[l_idx].* TO sa_levmenu[scrn].*

            END IF
         AFTER INPUT
            IF fgl_lastkey() = fgl_keyval("accept") THEN
               CALL selection2(l_arr_rec_menu2[l_idx].*)
               LET l_arr_rec_menu2[l_idx].answer = NULL
               NEXT FIELD answer
            END IF
      END INPUT
      IF int_flag OR quit_flag OR modu_close2_flag THEN
         LET int_flag = FALSE
         LET quit_flag = FALSE
         LET modu_close2_flag = TRUE
      ELSE
         LET l_idx = arr_curr()
         CALL selection2(l_arr_rec_menu2[l_idx].*)
         LET l_arr_rec_menu2[l_idx].answer = NULL
      END IF
   END WHILE
   CLOSE WINDOW lev2
   LET modu_wind2_open = FALSE
END FUNCTION


FUNCTION selection2(l_arr_rec_menu2)
   DEFINE
      l_arr_rec_menu2 record
         answer CHAR(1),
         menu2_code LIKE menu2.menu2_code,
         name_text LIKE menu2.name_text
      END RECORD

   IF l_arr_rec_menu2.answer = "X" THEN
      CALL direct()
      CURRENT WINDOW IS lev2
      LET l_arr_rec_menu2.answer = NULL
   ELSE
      LET modu_rec_menu2.menu2_code = l_arr_rec_menu2.answer
      IF modu_rec_menu2.menu2_code IS NULL
      OR modu_rec_menu2.menu2_code  = " " THEN
         LET modu_rec_menu2.menu2_code = l_arr_rec_menu2.menu2_code
      END IF
      SELECT * INTO modu_rec_menu2.* FROM menu2
       WHERE menu1_code = modu_rec_menu2.menu1_code
         AND menu2_code = modu_rec_menu2.menu2_code
      IF STATUS = 0 THEN
         IF menu_check("2",modu_rec_menu2.menu1_code,
                           modu_rec_menu2.menu2_code,"",
                           modu_rec_menu2.security_ind) THEN
            IF secu_passwd(modu_rec_menu2.name_text,modu_rec_menu2.password_text) THEN
               LET modu_wind3_open = TRUE
               CALL menu3(modu_rec_menu2.menu1_code,
                          modu_rec_menu2.menu2_code,
                          modu_rec_menu2.name_text)
               LET modu_wind3_open = FALSE
            END IF
         END IF
      END IF
   END IF
END FUNCTION


FUNCTION menu3(p_menu1_code,p_menu2_code,p_menu2_text)
   DEFINE
      p_menu1_code LIKE menu2.menu1_code,
      p_menu2_code LIKE menu2.menu2_code,
      p_menu2_text LIKE menu2.name_text,
      pa_menu3 array[30] of record
         answer CHAR(1),
         menu3_code LIKE menu3.menu3_code,
         name_text LIKE menu3.name_text,
         run_text LIKE menu3.run_text
      END RECORD,
      l_idx,scrn,l_arr_size SMALLINT,
      l_run_text CHAR(9),
      x, i SMALLINT

   LET modu_temp_text = p_menu2_text clipped," Menu (",
                      p_menu1_code,
                      p_menu2_code,")"
   LET x = (46 - length(modu_temp_text))/2
   IF x < 1 THEN LET x = 1 END IF
   LET modu_temp_text = x spaces,modu_temp_text[1, 46 - x]


      OPEN WINDOW lev3 WITH FORM "U520a"
      CALL winDecoration("U520a")

   LET modu_temp_text = upshift(modu_temp_text)
   DISPLAY modu_temp_text TO lbInfo1

   LET l_idx = 0
   DECLARE c_menu3 CURSOR FOR
      SELECT * FROM menu3
       WHERE menu1_code = p_menu1_code
         AND menu2_code != "X"
         AND menu2_code = p_menu2_code
         AND menu3_code != "X"
       ORDER BY 1,2,3
   FOREACH c_menu3 INTO modu_rec_menu3.*
      IF menu_check("3",modu_rec_menu3.menu1_code,
                        modu_rec_menu3.menu2_code,
                        modu_rec_menu3.menu3_code,
                        modu_rec_menu3.security_ind) THEN
         LET l_run_text = NULL
         FOR i = 1 TO length(modu_rec_menu3.run_text)
            IF modu_rec_menu3.run_text[i] IS NULL
            OR modu_rec_menu3.run_text[i]  = " "
            OR modu_rec_menu3.run_text[i]  = "." THEN
               EXIT FOR
            ELSE
               LET l_run_text = l_run_text clipped, modu_rec_menu3.run_text[i]
            END IF
         END FOR
         LET l_idx = l_idx + 1
         LET pa_menu3[l_idx].answer = NULL
         LET pa_menu3[l_idx].menu3_code = modu_rec_menu3.menu3_code
         LET pa_menu3[l_idx].name_text = modu_rec_menu3.name_text
         LET pa_menu3[l_idx].run_text = l_run_text
         IF l_idx = 30 THEN
            EXIT FOREACH
         END IF
      END IF
   END FOREACH
   LET l_arr_size = l_idx
   CALL set_count(l_arr_size)
   LET modu_close3_flag = FALSE
   WHILE NOT modu_close3_flag
      CALL check_for_memo()
      INPUT ARRAY pa_menu3 WITHOUT DEFAULTS FROM sa_levmenu.*
		BEFORE INPUT
			CALL publish_toolbar("kandoo","erpmenu","input-arr-menu3")
		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()


         ON KEY(control-y) 		#Show licensing info - obsolete
				CALL show_lic()


			ON ACTION "Print Manager"
#ON KEY(F11) 			#URS IS the Report Management System
            CALL run_prog("URS","","","","")
            NEXT FIELD answer

         ON KEY(F12)    		#run Program U17 - Memo Facility
            CALL run_prog("U17","","","","")
            NEXT FIELD answer

#On Linux terminal, CTRL-Z have the effect of susspending running program:
#[1]+  Stopped
#Tested on <Anton Dickinson> AND <Suse>
#ON KEY(control-z)
         ON KEY(control-e)      #U16 IS missing
            CALL run_prog("U16","S","","","")
            NEXT FIELD answer
         ON KEY(control-w)
            CALL kandoohelp(pa_menu3[l_idx].run_text)
            NEXT FIELD answer
         ON KEY(control-t)
            CALL display_calendar()
            NEXT FIELD answer
         ON KEY(control-u)
            SELECT * INTO modu_rec_menu3.* FROM menu3
             WHERE menu1_code = p_menu1_code
               AND menu2_code = p_menu2_code
               AND menu3_code = pa_menu3[l_idx].menu3_code
            LET modu_temp_text = "Program :",modu_rec_menu3.run_text
            LET modu_msgresp=kandoomsg("U",1,modu_temp_text)
            NEXT FIELD answer
         ON KEY(control-b)
            CALL show_menu()
            OPTIONS form line 1,
                    INSERT KEY F36,
                    DELETE KEY F36
            NEXT FIELD answer
         BEFORE ROW
            LET l_idx = arr_curr()
            LET scrn = scr_line()
#CALL f_more(l_arr_size,l_idx,scrn)
            DISPLAY pa_menu3[l_idx].* TO sa_levmenu[scrn].*

         BEFORE FIELD answer
            IF modu_close3_flag THEN
               EXIT INPUT
            END IF
         AFTER FIELD answer
            IF  arr_curr() = arr_count()
            AND fgl_lastkey() = fgl_keyval("down") THEN
               LET modu_msgresp=kandoomsg("U",9001,"")
               NEXT FIELD answer
            END IF
         BEFORE FIELD id
            CALL selection3(pa_menu3[l_idx].*)
            LET pa_menu3[l_idx].answer = NULL
            NEXT FIELD answer
         BEFORE FIELD name
            CALL selection3(pa_menu3[l_idx].*)
            LET pa_menu3[l_idx].answer = NULL
            NEXT FIELD answer
         BEFORE FIELD prg
            CALL selection3(pa_menu3[l_idx].*)
            LET pa_menu3[l_idx].answer = NULL
            NEXT FIELD answer
         AFTER ROW
            LET pa_menu3[l_idx].answer = NULL
            IF l_idx <= l_arr_size THEN
               DISPLAY pa_menu3[l_idx].* TO sa_levmenu[scrn].*

            END IF
      END INPUT
      IF int_flag OR quit_flag OR modu_close3_flag THEN
         LET int_flag = FALSE
         LET quit_flag = FALSE
         LET modu_close3_flag = TRUE
      ELSE
         LET l_idx = arr_curr()
         CALL selection3(pa_menu3[l_idx].*)
         LET pa_menu3[l_idx].answer = NULL
      END IF
   END WHILE
   CLOSE WINDOW lev3
END FUNCTION


FUNCTION selection3(pa_menu3)
   DEFINE
      pa_menu3 record
         answer CHAR(1),
         menu3_code LIKE menu3.menu3_code,
         name_text LIKE menu3.name_text,
         run_text LIKE menu3.run_text
      END RECORD

   IF pa_menu3.answer = "X" THEN
      CALL direct()
   ELSE
      LET modu_rec_menu3.menu3_code = pa_menu3.answer
      IF modu_rec_menu3.menu3_code IS NULL
      OR modu_rec_menu3.menu3_code  = " " THEN
         LET modu_rec_menu3.menu3_code = pa_menu3.menu3_code
      END IF
      CALL run_menupath(modu_rec_menu3.menu1_code,
                        modu_rec_menu3.menu2_code,
                        modu_rec_menu3.menu3_code)
   END IF
   CURRENT WINDOW IS lev3
END FUNCTION


FUNCTION direct()
   DEFINE
      l_prog_text CHAR(3),
      p_menu1_code, p_menu2_code, p_menu3_code CHAR(1),
      l_continue SMALLINT,
      l_rec_s_menu1 RECORD LIKE menu1.*,
      l_rec_s_menu2 RECORD LIKE menu2.*,
      l_rec_s_menu3 RECORD LIKE menu3.*

   CALL check_for_memo()
# -- albo
#  OPEN WINDOW wdirect WITH FORM "U999" ATTRIBUTES(BORDER)
#  CALL winDecoration("U999")
#
#  prompt " Direct Menu: " FOR l_prog_text
#  CLOSE WINDOW wdirect

   LET l_prog_text = promptInput(" Direct Menu: ","",3,1,1) -- albo
   LET l_prog_text = upshift(l_prog_text)
   CASE
      WHEN l_prog_text IS NULL
         EXIT CASE
      WHEN l_prog_text = "X"
         EXIT PROGRAM
      OTHERWISE
         LET p_menu1_code = l_prog_text[1]
         LET p_menu2_code = l_prog_text[2]
         LET p_menu3_code = l_prog_text[3]
         SELECT * INTO l_rec_s_menu1.* FROM menu1
           WHERE menu1_code = p_menu1_code
         IF STATUS = 0 THEN
            IF menu_check("1",l_rec_s_menu1.menu1_code,"","",
                              l_rec_s_menu1.security_ind)
            OR modu_rec_menu1.menu1_code = p_menu1_code THEN
               LET l_continue = FALSE
               IF modu_rec_menu1.menu1_code = p_menu1_code THEN
                  LET l_continue = TRUE
               ELSE
                  IF secu_passwd(l_rec_s_menu1.name_text,l_rec_s_menu1.password_text) THEN
                     LET l_continue = TRUE
                  END IF
               END IF
               IF l_continue THEN
                  SELECT * INTO l_rec_s_menu2.* FROM menu2
                   WHERE menu1_code = p_menu1_code
                     AND menu2_code = p_menu2_code
                  IF STATUS = 0 THEN
                     IF menu_check("2",l_rec_s_menu2.menu1_code,
                                       l_rec_s_menu2.menu2_code,"",
                                       l_rec_s_menu2.security_ind)
                     OR (modu_rec_menu1.menu1_code = p_menu1_code
                     AND modu_rec_menu2.menu2_code = p_menu2_code) THEN
                        LET l_continue = FALSE
                        IF (modu_rec_menu1.menu1_code = p_menu1_code
                        AND modu_rec_menu2.menu2_code = p_menu2_code) THEN
                           LET l_continue = TRUE
                        ELSE
                           IF secu_passwd(l_rec_s_menu2.name_text,
                                          l_rec_s_menu2.password_text) THEN
                              LET l_continue = TRUE
                           END IF
                        END IF
                        IF l_continue THEN
                           SELECT * INTO l_rec_s_menu3.* FROM menu3
                            WHERE menu1_code = p_menu1_code
                              AND menu2_code = p_menu2_code
                              AND menu3_code = p_menu3_code
                           IF STATUS = 0 THEN
                              IF menu_check("3",l_rec_s_menu3.menu1_code,
                                             l_rec_s_menu3.menu2_code,
                                             l_rec_s_menu3.menu3_code,
                                             l_rec_s_menu3.security_ind) THEN
                                 CALL run_menupath(l_prog_text[1],
                                                   l_prog_text[2],
                                                   l_prog_text[3])
                              END IF
                           END IF
                        END IF
                     END IF
                  END IF
               END IF
            END IF
         END IF
   END CASE
END FUNCTION


FUNCTION run_menupath(p_menu1_code, p_menu2_code, p_menu3_code)
   DEFINE
      p_menu1_code,p_menu2_code,p_menu3_code CHAR(1),
      modu_rec_menu3 RECORD LIKE menu3.*

   SELECT * INTO modu_rec_menu3.* FROM menu3
    WHERE menu1_code = p_menu1_code
      AND menu2_code = p_menu2_code
      AND menu3_code = p_menu3_code

   IF STATUS = 0 THEN
      IF menu_check("3",modu_rec_menu3.menu1_code,
                     modu_rec_menu3.menu2_code,
                     modu_rec_menu3.menu3_code,
                     modu_rec_menu3.security_ind)
   	  THEN
         CALL run_prog(modu_rec_menu3.run_text,"","","","")
         IF modu_rec_menu3.run_text matches "*U11*" THEN
            CALL authenticate("TOPMENUR")
              returning glob_rec_kandoouser.cmpy_code,
                        glob_rec_kandoouser.sign_on_code
         END IF
         IF modu_rec_menu3.run_text matches "*U11*"
         OR modu_rec_menu3.run_text matches "*U12*"
         OR modu_rec_menu3.run_text matches "*U21*"
         OR modu_rec_menu3.run_text matches "*GZA*"
         OR modu_rec_menu3.run_text matches "*GZC*" THEN
            SELECT * INTO glob_rec_company.* FROM company
               WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
            IF STATUS = NOTFOUND THEN
#U5100" User Company NOT found - Refer system administrator"
               LET modu_msgresp=kandoomsg("U",5100,glob_rec_kandoouser.cmpy_code)
               LET glob_rec_company.name_text = "** Not Set Up ** "
            END IF
            LET modu_company_text = glob_rec_company.name_text
            LET modu_close3_flag = TRUE
            LET modu_close2_flag = TRUE
            LET modu_close1_flag = TRUE
         END IF
      END IF
   END IF
END FUNCTION


#UNCTION f_more(l_arr_size,l_idx,scrn)
#  DEFINE
#     more CHAR(3),
#     l_arr_size, l_idx, scrn SMALLINT
#
#  IF prXXXX remove XXXX_gui_flag = FALSE THEN # only in text mode
#     LET more = "..."
#     IF l_arr_size > (l_idx - scrn + 10) THEN
#        DISPLAY BY NAME more
#
#     ELSE
#        CLEAR more
#     END IF
#  END IF
# END FUNCTION


FUNCTION menu_check(p_level_ind,
                    p_menu1_code,
                    p_menu2_code,
                    p_menu3_code,
                    p_menusec_ind)
   DEFINE
      p_level_ind,
      p_menu1_code,
      p_menu2_code,
      p_menu3_code,
      p_menusec_ind,
      l_modsec_ind CHAR(1)

   SELECT security_ind INTO l_modsec_ind
     FROM kandoomodule
    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
      AND user_code = glob_rec_kandoouser.sign_on_code
      AND module_code = p_menu1_code
		IF get_debug() = TRUE THEN
			DISPLAY "############################"
			DISPLAY "l_modsec_ind=", l_modsec_ind
			DISPLAY "glob_rec_kandoouser.cmpy_code=", glob_rec_kandoouser.cmpy_code
			DISPLAY "glob_rec_kandoouser.sign_on_code=", glob_rec_kandoouser.sign_on_code
			DISPLAY "p_menu1_code=", p_menu1_code
			DISPLAY "############################"
		END IF
   IF l_modsec_ind IS NULL THEN
      LET l_modsec_ind = glob_rec_kandoouser.security_ind
   END IF

   IF get_debug() = TRUE THEN
		DISPLAY "LET l_modsec_ind = glob_rec_kandoouser.security_ind"
		DISPLAY "LET l_modsec_ind =", l_modsec_ind
	END IF

   IF p_menusec_ind > l_modsec_ind THEN
##
## IF security levels do NOT permit THEN check
## IF permission has been individually granted.
##
      CASE p_level_ind
         WHEN "1"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND grant_deny_flag = "G"
         WHEN "2"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND menu2_code = p_menu2_code
               AND grant_deny_flag = "G"
         WHEN "3"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND menu2_code = p_menu2_code
               AND menu3_code = p_menu3_code
               AND grant_deny_flag = "G"
      END CASE
      IF STATUS = NOTFOUND THEN
         RETURN FALSE
      ELSE
         RETURN TRUE
      END IF
   ELSE
##
## IF security levels do permit THEN check
## IF permission has been individually denied.
##
			IF get_debug() = TRUE THEN
				DISPLAY "##########################"
				DISPLAY "LEVEL CASE"
				DISPLAY "p_level_ind=", p_level_ind
				DISPLAY "##########################"
			END IF
      CASE p_level_ind
         WHEN "1"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND menu2_code IS NULL
               AND menu3_code IS NULL
               AND grant_deny_flag = "D"
         WHEN "2"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND menu2_code = p_menu2_code
               AND menu3_code IS NULL
               AND grant_deny_flag = "D"
         WHEN "3"
            SELECT unique 1 FROM grant_deny_access
             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
               AND sign_on_code = glob_rec_kandoouser.sign_on_code
               AND menu1_code = p_menu1_code
               AND menu2_code = p_menu2_code
               AND menu3_code = p_menu3_code
               AND grant_deny_flag = "D"
      END CASE
      IF STATUS = NOTFOUND THEN
         RETURN TRUE
      ELSE
         RETURN FALSE
      END IF
   END IF
END FUNCTION


FUNCTION terminal_MESSAGE()
DEFINE
   l_status INTEGER,
   l_value CHAR(20),
   l_cmd_line CHAR(300)

   LET l_status = STATUS 				# save it - it can get overwritten
   LET l_value = fgl_getenv("FGLGUI") 	# can't use gui_flag
   IF l_value = "1" THEN 				# Trying TO run GUI
      LET l_value = fgl_getenv("FGLSERVER")
      LET l_cmd_line =
      "echo;echo;",
      "echo ' ERROR ", l_status using "<<<<<"," has occurred.';",
      "echo ' -------------------------------';",
      "echo ' Windows Client <",
              l_value clipped,
              "> IS probably NOT started.';",
      "echo ' Please start your <Suse> WTK server THEN logon again.  IF the same ';",
      "echo ' error re-occurs THEN contact your System Administrator.';",
      "echo;echo;sleep 10"
   ELSE
      LET l_value = fgl_getenv("TERM")
      LET l_cmd_line =
      "echo;echo;",
      "echo ' ERROR ", l_status using "<<<<<"," has occurred.';",
      "echo ' -------------------------------';",
      "echo ' Terminal Type <",
              l_value clipped,
              "> IS probably invalid.';",
      "echo ' Please Log in again with a valid Terminal Type.  IF the same ';",
      "echo ' error re-occurs THEN contact your System Administrator.';",
      "echo;echo;sleep 10"
   END IF

   run l_cmd_line
   EXIT PROGRAM
END FUNCTION


FUNCTION redraw()
   CALL display_control()
   CURRENT WINDOW IS lev1

END FUNCTION

FUNCTION display_control()
DEFINE comp_name CHAR(20)

   CURRENT WINDOW IS wcontrol
   LET modu_rec_control.maxi_text= "KandooERP"
   LET modu_rec_control.date_text = "  ",today using "ddd dd mmm yyyy"
   LET modu_rec_control.software_text = "     ",modu_rec_kandooinfo.version_num using "##.&&",
                                  ".", modu_rec_kandooinfo.update_num using "&&"



#DISPLAY "1 >",modu_rec_kandooinfo.version_num clipped ,"<"
#DISPLAY "2 >",modu_rec_kandooinfo.update_num clipped ,"<"
#DISPLAY "3 >",modu_rec_control.software_text clipped ,"<"
#sleep 20


   SELECT * INTO glob_rec_company.* FROM company
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
   SELECT * INTO modu_rec_period.* FROM period
    WHERE start_date <= today
      AND end_date >= today
      AND cmpy_code = glob_rec_company.cmpy_code
   IF STATUS = NOTFOUND THEN
      LET modu_rec_control.period_text = "????/??"
   ELSE
      LET modu_rec_control.period_text = "  ",modu_rec_period.year_num using "####","/",
                                   modu_rec_period.period_num using "<&&"
   END IF
   LET modu_rec_control.period_text = modu_rec_control.period_text clipped," ",
                                glob_rec_company.curr_code," ",
                                glob_rec_company.language_code

		DISPLAY BY NAME modu_rec_control.*



END FUNCTION



FUNCTION display_control2()
      CURRENT WINDOW IS wcontrol2
      LET modu_spaces_cnt = 32 - length(glob_rec_kandoouser.name_text)
      LET modu_kandoouser_text = modu_spaces_cnt spaces, glob_rec_kandoouser.name_text
      DISPLAY BY NAME modu_company_text,
                      modu_kandoouser_text

END FUNCTION



FUNCTION show_lic()
   DEFINE
      l_secure SMALLINT,
      l_ans CHAR(8),
      l_arr_rec_splash array[4] of record
         licence_text LIKE kandooinfo.licensed_user_text
      END RECORD,
      p_licence LIKE kandooinfo.licence_text,
      p_text,logon_text,expiry_text LIKE kandooinfo.licensed_user_text,
      l_rec_kandooinfo RECORD LIKE kandooinfo.*,
      l_key1_code CHAR(4)

   DECLARE secure_c CURSOR FOR
    SELECT * FROM kandooinfo
   OPEN secure_c
   FETCH secure_c INTO l_rec_kandooinfo.*
   close secure_c




       OPEN WINDOW U118 AT 4,15 WITH FORM "U523"
   		CALL winDecoration("U523")


       LET l_key1_code = l_rec_kandooinfo.key1_code using "<<<"
       LET l_arr_rec_splash[1].licence_text = l_rec_kandooinfo.licensed_user_text
       LET l_arr_rec_splash[2].licence_text = l_rec_kandooinfo.licence_text
       LET l_arr_rec_splash[3].licence_text = "Licensed FOR use of ",
                         l_rec_kandooinfo.key1_code using "<<<",
                         " concurrent users"
       LET l_arr_rec_splash[4].licence_text = "Licence expires on ",
                          l_rec_kandooinfo.expiry_date using "dd-mmm-yyyy"
       DISPLAY l_arr_rec_splash[1].licence_text TO sa_splash[1].licence_text
       DISPLAY l_arr_rec_splash[2].licence_text TO sa_splash[2].licence_text
       DISPLAY l_arr_rec_splash[3].licence_text TO sa_splash[3].licence_text
       DISPLAY l_arr_rec_splash[4].licence_text TO sa_splash[4].licence_text

       INPUT l_ans FROM bt
       CLOSE WINDOW U118

END FUNCTION


FUNCTION display_calendar()
   DEFINE
      l_input_date date

   OPTIONS form line 3
   LET l_input_date = today
   LET l_input_date = showdate(l_input_date)
   OPTIONS form line 1
END FUNCTION

FUNCTION check_cmpy_access()
   DEFINE
       l_counter       SMALLINT,
       l_fv_user_cmpy  CHAR(2),
       fv_valid_flag CHAR(1),
       fv_old_cmpy   LIKE company.cmpy_code,
       fv_text       CHAR(30)

   LET l_counter = 0
   LET fv_old_cmpy = glob_rec_kandoouser.cmpy_code

   SELECT count(*)
     INTO l_counter
     FROM kandoousercmpy
    WHERE sign_on_code = glob_rec_kandoouser.sign_on_code

   IF l_counter > 1 THEN

      OPEN WINDOW wU153 AT 17,49 WITH FORM "U153"
      CALL winDecoration("U153")

      LET fv_text = kandooword("Company Logon","1")

      DISPLAY fv_text TO lbInfo1

      LET l_fv_user_cmpy = glob_rec_kandoouser.cmpy_code
      LET fv_valid_flag = FALSE

      WHILE fv_valid_flag = FALSE
        INPUT l_fv_user_cmpy WITHOUT DEFAULTS FROM cc
			BEFORE INPUT
				CALL publish_toolbar("kandoo","erpmenu","input-user_cmpy")
			ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

		END INPUT
        IF int_flag OR quit_flag THEN
           EXIT PROGRAM
        END IF

        SELECT *
          FROM kandoousercmpy
         WHERE cmpy_code    = l_fv_user_cmpy
           AND sign_on_code = glob_rec_kandoouser.sign_on_code
        IF (STATUS = NOTFOUND) THEN
           LET fv_valid_flag = FALSE
           ERROR "Not allowed TO use specified company code"
           sleep 2
        ELSE
           LET fv_valid_flag = TRUE
        END IF
      END WHILE
      LET glob_rec_kandoouser.cmpy_code = l_fv_user_cmpy
      CLOSE WINDOW wU153
   END IF

END FUNCTION


}
