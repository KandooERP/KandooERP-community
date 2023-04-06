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

	Source code beautified by beautify.pl on 2020-01-03 10:37:00	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# FL1 allows the loading of stocktake data FROM a flat file INTO the
#     database AND also the deletion of old stocktake data
#     FROM the database governed by the stocktake period.


MAIN 
	#Initial UI Init
	CALL setModuleId("FL1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	OPEN WINDOW f178w with FORM "F178" -- alch kd-757 
	CALL  windecoration_f("F178") -- alch kd-757 

	MENU "Stocktake" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","FL1","menu-stock-1") -- alch kd-504 
		COMMAND "Load" " Load stocktake data INTO database" 
			CALL load_stock() 
			NEXT option "Exit" 
		COMMAND "Delete" " Delete old stocktake data FROM database" 
			CALL delete_stock() 
			NEXT option "Exit" 
		COMMAND KEY (interrupt,"E") "Exit" " Exit stocktake load program" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
	CLOSE WINDOW f178w 
END MAIN 

FUNCTION load_stock() 
	DEFINE 
	pr_year_num LIKE fastocklocn.year_num, 
	pr_period_num LIKE fastocklocn.period_num, 
	ans CHAR(1) 
	INPUT pr_year_num, pr_period_num 
	FROM fastocklocn.year_num, fastocklocn.period_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FL1","inp-pr_year_num-2") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	--   prompt " Confirm TO load \"/tmp/maxfa_stklocn\" (Y/N) " FOR ans -- albo
	LET ans = promptYN(""," Confirm TO load \"/tmp/maxfa_stklocn\" (Y/N) ","Y") -- albo 
	IF ans NOT matches "[yY]" THEN 
		RETURN 
	END IF 
	MESSAGE "Loading Stocktake data INTO Database" 
	BEGIN WORK 
		LOAD FROM "/tmp/maxfa_stklocn" 
		INSERT INTO fastocklocn (wand_code, stktake_date, location_code, 
		asset_code, user_code) 
		UPDATE fastocklocn 
		SET cmpy_code = glob_rec_kandoouser.cmpy_code, 
		year_num = pr_year_num, 
		period_num = pr_period_num 
		WHERE cmpy_code IS NULL 
	COMMIT WORK 
	MESSAGE "Stocktake load completed successfully" 
	SLEEP 3 
	CLEAR screen 
END FUNCTION 

FUNCTION delete_stock() 
	DEFINE 
	pr_year_num LIKE fastocklocn.year_num, 
	pr_period_num LIKE fastocklocn.period_num, 
	ans CHAR(1) 
	INPUT pr_year_num, pr_period_num 
	FROM fastocklocn.year_num, fastocklocn.period_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FL1","inp-fastocklocn-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	--   prompt " Confirm TO delete ? (Y/N)  " FOR ans -- albo
	LET ans = promptYN(""," Confirm TO delete ? (Y/N) ","Y") -- albo 
	IF ans NOT matches "[yY]" THEN 
		RETURN 
	END IF 
	MESSAGE "Deleting Stocktake data FROM Database" 
	BEGIN WORK 
		DELETE FROM fastocklocn 
		WHERE year_num < pr_year_num 
		OR (year_num = pr_year_num AND period_num <= pr_period_num) 
	COMMIT WORK 
	MESSAGE "Stocktake data successfully deleted " 
	SLEEP 3 
	CLEAR screen 
END FUNCTION 
