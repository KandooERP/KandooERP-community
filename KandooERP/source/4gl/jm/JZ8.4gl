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

	Source code beautified by beautify.pl on 2020-01-02 19:48:29	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JZ8 allows the user TO maintain the Task Periods
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pl_taskperiod RECORD LIKE taskperiod.*, 
	pr_taskperiod RECORD 
		task_period_ind LIKE taskperiod.task_period_ind, 
		task_period_text LIKE taskperiod.task_period_text, 
		days_qty LIKE taskperiod.days_qty, 
		avg_days_qty LIKE taskperiod.avg_days_qty 
	END RECORD, 
	pa_taskperiod array[50] OF RECORD 
		delete_flag CHAR(1), 
		task_period_ind LIKE taskperiod.task_period_ind, 
		task_period_text LIKE taskperiod.task_period_text, 
		days_qty LIKE taskperiod.days_qty, 
		avg_days_qty LIKE taskperiod.avg_days_qty 
	END RECORD, 
	i, did_insert, scrn SMALLINT 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JZ8") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	WHILE true 
		CALL get_query() 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		CALL get_info() 
		CLOSE WINDOW wj193 
	END WHILE 
END MAIN 


FUNCTION get_query() 
	DEFINE 
	where_part CHAR(512), 
	query_text CHAR(512) 
	OPEN WINDOW wj193 with FORM "J193" -- alch kd-747 
	CALL winDecoration_j("J193") -- alch kd-747 
	LET msgresp = kandoomsg("U", 1503, "") 
	#MESSAGE " Enter criteria FOR selection - ESC TO begin search "
	#   attribute (yellow)
	CONSTRUCT BY NAME where_part ON 
	task_period_ind, 
	days_qty 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JZ8","const-task_period_ind-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		MESSAGE "" 
		RETURN 
	END IF 
	MESSAGE " Please wait ... " attribute (yellow) 
	LET query_text = "SELECT task_period_ind, task_period_text, ", 
	"days_qty, avg_days_qty ", 
	"FROM taskperiod WHERE ", 
	"cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	where_part clipped, 
	"ORDER BY task_period_ind" 
	PREPARE statement_1 FROM query_text 
	DECLARE taskperiod_set CURSOR FOR statement_1 
	LET i=0 
	FOREACH taskperiod_set INTO pr_taskperiod.* 
		IF i >= 40 THEN 
			LET msgresp = kandoomsg("U", 1505, i) 
			#ERROR "Only first VALUE rows selected"
			EXIT FOREACH 
		END IF 
		IF pr_taskperiod.task_period_ind <> "M" THEN 
			LET i = i + 1 
			LET pa_taskperiod[i].task_period_ind = pr_taskperiod.task_period_ind 
			LET pa_taskperiod[i].task_period_text = pr_taskperiod.task_period_text 
			LET pa_taskperiod[i].days_qty = pr_taskperiod.days_qty 
			LET pa_taskperiod[i].avg_days_qty = pr_taskperiod.avg_days_qty 
			LET pa_taskperiod[i].delete_flag = "" 
		END IF 
	END FOREACH 
	IF i = 0 THEN 
		LET msgresp = kandoomsg("U", 9506, "") 
		#ERROR " No Rows found FOR this Selection Criteria"
	END IF 
	CALL set_count(i) 
END FUNCTION #get_query 


FUNCTION get_info() 
	DEFINE 
	del_no, cntr SMALLINT 

	WHENEVER ERROR CONTINUE 
	OPTIONS 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	LET msgresp = kandoomsg("U", 1003, "") 
	#MESSAGE " F1 TO add, RETURN TO change, F2 TO delete"
	#   attribute (yellow)
	INPUT ARRAY pa_taskperiod WITHOUT DEFAULTS FROM sr_taskperiod.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ8","input_arr-pa_taskperiod-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET i = arr_curr() 
			LET scrn = scr_line() 
			LET pr_taskperiod.task_period_ind = pa_taskperiod[i].task_period_ind 
			LET pr_taskperiod.task_period_text = pa_taskperiod[i].task_period_text 
			LET pr_taskperiod.days_qty = pa_taskperiod[i].days_qty 
			LET pr_taskperiod.avg_days_qty = pa_taskperiod[i].avg_days_qty 

		BEFORE INSERT 
			INITIALIZE pr_taskperiod.* TO NULL 
			IF arr_curr() < arr_count() THEN 
				NEXT FIELD task_period_ind 
			END IF 

		BEFORE FIELD delete_flag 
			LET pr_taskperiod.task_period_ind = pa_taskperiod[i].task_period_ind 
			LET pr_taskperiod.task_period_text = pa_taskperiod[i].task_period_text 
			LET pr_taskperiod.days_qty = pa_taskperiod[i].days_qty 
			LET pr_taskperiod.avg_days_qty = pa_taskperiod[i].avg_days_qty 
			DISPLAY pa_taskperiod[i].* 
			TO sr_taskperiod[scrn].* 

		AFTER FIELD delete_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND pa_taskperiod[i+1].task_period_ind IS NULL THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
		BEFORE FIELD task_period_ind 
			IF pa_taskperiod[i].task_period_ind IS NOT NULL THEN 
				NEXT FIELD task_period_text 
			END IF 
		AFTER FIELD task_period_ind 
			IF pa_taskperiod[i].task_period_ind IS NULL THEN 
				LET msgresp = kandoomsg("J", 9543, "") 
				#ERROR " Task Period Code must be entered "
				NEXT FIELD task_period_ind 
			END IF 
			SELECT count(*) 
			INTO cntr 
			FROM taskperiod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND task_period_ind = pa_taskperiod[i].task_period_ind 
			IF (cntr != 0) THEN 
				IF pa_taskperiod[i].task_period_ind = "M" THEN 
					LET msgresp = kandoomsg("J", 9536, "") 
					#ERROR "Task Period code 'M' FOR Montly already setup"
					LET pa_taskperiod[i].task_period_ind = 
					pr_taskperiod.task_period_ind 
					DISPLAY pa_taskperiod[i].task_period_ind 
					TO sr_taskperiod[scrn].task_period_ind 
				ELSE 
					LET msgresp = kandoomsg("J", 9537, "") 
					#ERROR "Task Period code must be unique"
					LET pa_taskperiod[i].task_period_ind = "" 
					DISPLAY pa_taskperiod[i].task_period_ind 
					TO sr_taskperiod[scrn].task_period_ind 
				END IF 
				NEXT FIELD task_period_ind 
			END IF 
		BEFORE FIELD task_period_text 
			IF (pa_taskperiod[i].task_period_ind IS null) THEN 
				IF (pa_taskperiod[i].days_qty IS NOT null) THEN 
					LET msgresp = kandoomsg("J", 9543, "") 
					#ERROR " Task Period Code must be entered "
					NEXT FIELD task_period_ind 
				END IF 
			END IF 
		AFTER FIELD task_period_text 
			IF pa_taskperiod[i].task_period_text IS NULL THEN 
				LET msgresp = kandoomsg("J", 9538, "") 
				#ERROR "a Description must be entered"
				NEXT FIELD task_period_text 
			END IF 
		AFTER FIELD days_qty 
			IF pa_taskperiod[i].days_qty IS NULL THEN 
				LET msgresp = kandoomsg("J", 9539, "") 
				#ERROR "a number of days must be entered"
				NEXT FIELD days_qty 
			END IF 
		AFTER FIELD avg_days_qty 
			IF pa_taskperiod[i].avg_days_qty IS NULL THEN 
				LET msgresp = kandoomsg("J", 9540, "") 
				#ERROR "a number of working days must be entered"
				NEXT FIELD avg_days_qty 
			END IF 
			IF pa_taskperiod[i].avg_days_qty > pa_taskperiod[i].days_qty THEN 
				LET msgresp = kandoomsg("J", 9541, "") 
				#ERROR "You cannot have more working days than days in period"
				NEXT FIELD avg_days_qty 
			END IF 

		AFTER INSERT 
			IF int_flag OR quit_flag THEN 
			ELSE 
				IF pa_taskperiod[i].task_period_ind IS NULL OR 
				pa_taskperiod[i].task_period_text IS NULL OR 
				pa_taskperiod[i].days_qty IS NULL OR 
				pa_taskperiod[i].avg_days_qty IS NULL THEN 
					NEXT FIELD task_period_ind 
				END IF 
				IF pa_taskperiod[i].avg_days_qty > pa_taskperiod[i].days_qty THEN 
					LET msgresp = kandoomsg("J", 9541, "") 
					#ERROR "You cannot have more working days than days in period"
					NEXT FIELD avg_days_qty 
				END IF 

				LET did_insert = true 

				WHENEVER ERROR CONTINUE 
				LET pl_taskperiod.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pl_taskperiod.task_period_ind = pa_taskperiod[i].task_period_ind 
				LET pl_taskperiod.task_period_text = pa_taskperiod[i].task_period_text 
				LET pl_taskperiod.days_qty = pa_taskperiod[i].days_qty 
				LET pl_taskperiod.avg_days_qty = pa_taskperiod[i].avg_days_qty 
				INSERT INTO taskperiod 
				VALUES (pl_taskperiod.*) 
				IF (status < 0) THEN 
					LET msgresp = kandoomsg("U", 9505, status) 
					#ERROR " An error has occurred, STATUS = "
					CLEAR sr_taskperiod[scrn].* 
					NEXT FIELD task_period_ind 
				END IF 
				WHENEVER ERROR stop 
			END IF 

		ON KEY (f2) 
			IF pa_taskperiod[i].task_period_ind IS NULL OR 
			pa_taskperiod[i].task_period_text IS NULL OR 
			pa_taskperiod[i].days_qty IS NULL OR 
			pa_taskperiod[i].avg_days_qty IS NULL THEN 
				LET msgresp = kandoomsg("J", 9535, "") 
				#ERROR "This Row does NOT exist (yet) AND cannot be deleted.."
				NEXT FIELD task_period_ind 
			END IF 
			IF pa_taskperiod[i].delete_flag IS NULL THEN 
				SELECT count(*) INTO cntr 
				FROM person 
				WHERE person.task_period_ind = pa_taskperiod[i].task_period_ind 
				IF cntr > 0 THEN 
					LET msgresp = kandoomsg("J", 9542, cntr) 
					#" You may NOT delete this Task Period - There are VALUE",
					#" Persons who are using this one"
				ELSE 
					LET pa_taskperiod[i].delete_flag = "*" 
					LET del_no = del_no + 1 
				END IF 
			ELSE 
				LET pa_taskperiod[i].delete_flag = "" 
				LET del_no = del_no - 1 
			END IF 
			DISPLAY pa_taskperiod[i].delete_flag 
			TO sr_taskperiod[scrn].delete_flag 

		AFTER ROW 
			IF int_flag OR quit_flag THEN 
			ELSE 
				IF pa_taskperiod[i].task_period_ind IS NULL OR 
				pa_taskperiod[i].task_period_text IS NULL OR 
				pa_taskperiod[i].days_qty IS NULL OR 
				pa_taskperiod[i].avg_days_qty IS NULL THEN 
					NEXT FIELD task_period_ind 
				END IF 
				IF pa_taskperiod[i].avg_days_qty > pa_taskperiod[i].days_qty THEN 
					LET msgresp = kandoomsg("J", 9541, "") 
					#ERROR "You cannot have more working days than days in period"
					NEXT FIELD avg_days_qty 
				END IF 
				IF (did_insert) THEN 
					LET did_insert = false 
					NEXT FIELD delete_flag 
				END IF 

				IF pa_taskperiod[i].task_period_ind <> "M" THEN 
					IF pr_taskperiod.task_period_ind IS NOT NULL THEN 
						UPDATE taskperiod SET 
						(taskperiod.task_period_ind, 
						taskperiod.task_period_text, 
						taskperiod.days_qty, 
						taskperiod.avg_days_qty) 
						=(pa_taskperiod[i].task_period_ind, 
						pa_taskperiod[i].task_period_text, 
						pa_taskperiod[i].days_qty, 
						pa_taskperiod[i].avg_days_qty) 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND task_period_ind = pr_taskperiod.task_period_ind 
					ELSE 
						WHENEVER ERROR CONTINUE 
						LET pl_taskperiod.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pl_taskperiod.task_period_ind = pa_taskperiod[i].task_period_ind 
						LET pl_taskperiod.task_period_text = pa_taskperiod[i].task_period_text 
						LET pl_taskperiod.days_qty = pa_taskperiod[i].days_qty 
						LET pl_taskperiod.avg_days_qty = pa_taskperiod[i].avg_days_qty 
						INSERT INTO taskperiod 
						VALUES (pl_taskperiod.*) 
						IF (status < 0) THEN 
							LET msgresp = kandoomsg("U", 9505, status) 
							#ERROR "An error has occurred, STATUS = "
							INITIALIZE pa_taskperiod[i].* TO NULL 
							CLEAR sr_taskperiod[scrn].* 
						END IF 
						WHENEVER ERROR stop 
					END IF 
				END IF 
				DISPLAY pa_taskperiod[i].* 
				TO sr_taskperiod[scrn].* 

			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF pa_taskperiod[i].task_period_ind IS NULL THEN 
					FOR i = arr_curr() TO arr_count() 
						LET pa_taskperiod[i].* = pa_taskperiod[i+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE pa_taskperiod[i].* TO NULL 
							EXIT FOR 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_taskperiod[i].* 
							TO sr_taskperiod[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET i =arr_curr() 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD delete_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_no > 0 THEN 
			LET msgresp = kandoomsg("J", 8507, del_no) 
			#prompt "There are VALUE Task Periods TO delete. Confirm...."
			IF msgresp = "Y" THEN 
				FOR i = 1 TO arr_count() 
					IF pa_taskperiod[i].delete_flag IS NOT NULL THEN 
						DELETE FROM taskperiod 
						WHERE taskperiod.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND taskperiod.task_period_ind = 
						pa_taskperiod[i].task_period_ind 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 
