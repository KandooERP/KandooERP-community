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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl"
###########################################################################
# FUNCTION E52_M_main()
#
# E52 (E52_M !!!!) - Packing Slip / Picking List Print Program
#               Provides front END TO print_pickslip() (E52e.4gl).
###########################################################################
FUNCTION E52_M_main() 
	DEFINE i SMALLINT 
	DEFINE l_temp_text VARCHAR(200) 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E52") -- albo 
	CALL init_E5_GROUP()
	
	OPEN WINDOW E150 with FORM "E150" 
	 CALL windecoration_e("E150") -- albo kd-755 
	
	DECLARE c_pickhead cursor FOR 
	SELECT * FROM pickhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY pick_date desc,ware_code,pick_num 
	OPEN c_pickhead 
	
	FOR i = 1 TO 13 
		FETCH c_pickhead INTO l_rec_pickhead.* 
		IF sqlca.sqlcode = 0 THEN 
			SELECT name_text INTO l_temp_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_pickhead.cust_code 
			DISPLAY "", 
			l_rec_pickhead.pick_date, 
			l_rec_pickhead.ware_code, 
			l_rec_pickhead.pick_num, 
			l_rec_pickhead.cust_code, 
			l_temp_text, 
			l_rec_pickhead.status_ind, 
			l_rec_pickhead.con_status_ind 
			TO sr_pickhead[i].* 

		END IF 
	END FOR 
	
	MENU "Picking lists" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","E52_M","menu-Picking_Lists-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Scroll" " Scroll through selected picking lists" 
			SELECT count(*) INTO i FROM pickhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF i < 30 THEN 
				CALL scan_picklist(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"1=1") 
			ELSE 
				CALL scan_picklist(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,select_picklist()) 
			END IF 

		COMMAND "Generate" " SELECT criteria AND generate picking lists" 
			OPEN WINDOW E152 with FORM "E152" 
			 CALL windecoration_e("E152") -- albo kd-755 

			LET l_temp_text = select_criteria(glob_rec_kandoouser.cmpy_code) 

			IF generate_pick(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_temp_text) THEN 
				DECLARE c_picklist cursor with hold FOR 
				SELECT ware_code, delivery_ind FROM t_picklist 
				GROUP BY ware_code, delivery_ind 
				ORDER BY delivery_ind desc,	ware_code
				 
				FOREACH c_picklist INTO l_rec_orderhead.ware_code,	l_rec_orderhead.delivery_ind 
					CALL create_picklist(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_kandoouser.sign_on_code,
						l_rec_orderhead.ware_code, 
						l_rec_orderhead.delivery_ind, 
						TRUE,
						FALSE)
					SLEEP 3 
				END FOREACH 

				DROP TABLE t_picklist 
			END IF 
			CLOSE WINDOW E152 
 

		ON ACTION "PRINT MANAGER"			#COMMAND KEY ("P",f11) "Print"    " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" "Exit TO menus" 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT MENU 

	END MENU 
	
	CLOSE WINDOW E150 
END FUNCTION
###########################################################################
# END FUNCTION E52_M_main()
###########################################################################