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

	Source code beautified by beautify.pl on 2020-01-02 17:31:32	$Id: $
}


# Purpose - MPS Delete

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	pv_non_part_desc LIKE shoporddetl.desc_text, 
	pv_mps_plan LIKE mps.plan_code, 
	pv_mrp_plan LIKE mrp.plan_code, 
	pv_mps_desc LIKE mps.desc_text, 
	pv_mrp_desc LIKE mrp.desc_text, 
	pv_end_date DATE, 
	pv_background SMALLINT, 
	pv_found_error SMALLINT, 
	pv_errormsg CHAR(100), 
	pv_tot_sel SMALLINT, 
	pv_tot_left SMALLINT, 

	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 

DEFINE 
ma_schedule array[500] OF RECORD 
	plan_code LIKE mps.plan_code, 
	desc_text LIKE mps.desc_text 
END RECORD, 
mv_num_records INTEGER 

MAIN 

	#Initial UI Init
	CALL setModuleId("M52") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL delete_main() 

END MAIN 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the SCREEN AND drive the program via a menu        #
#-------------------------------------------------------------------------#

FUNCTION delete_main() 

	OPEN WINDOW m136 with FORM "M136" 
	CALL  windecoration_m("M136") -- albo kd-762 

	CALL get_mps() 
	CALL show_mps() 

	CALL kandoomenu("M", 147) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			CALL delete_mps() 
			CALL show_mps() 
		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			EXIT MENU 
		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW m136 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the MPS details INTO the ARRAY FOR DISPLAYing          #
#-------------------------------------------------------------------------#

FUNCTION get_mps() 

	DEFINE 
	fv_plan_code LIKE mps.plan_code, 
	fv_description LIKE mps.desc_text, 
	fv_count INTEGER 

	DECLARE smps_cursor CURSOR FOR 
	SELECT unique plan_code, desc_text 
	FROM mps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY plan_code 

	LET fv_count = 0 
	FOREACH smps_cursor INTO fv_plan_code,fv_description 
		IF fv_count = 500 THEN 
			LET msgresp = kandoomsg("M",9659,"") 
			# ERROR "Only the first 500 schedules were selected"
			EXIT FOREACH 
		END IF 
		LET ma_schedule[fv_count+1].plan_code=fv_plan_code 
		LET ma_schedule[fv_count+1].desc_text=fv_description 
		LET fv_count=fv_count+1 
	END FOREACH 
	LET mv_num_records=fv_count 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO SELECT AND THEN delete an MPS FROM the the database        #
#-------------------------------------------------------------------------#

FUNCTION delete_mps() 

	DEFINE 
	fv_count SMALLINT, 
	fv_continue SMALLINT, 
	fv_curr_row INTEGER 

	LET msgresp = kandoomsg("M",1527,"") 
	# MESSAGE "RETURN TO delete MPS f3 fwd f4 bwd del TO EXIT"
	CALL get_mps() 
	CALL show_mps() 

	LET fv_continue=true 
	WHILE fv_continue 
		CALL set_count(mv_num_records) 

		DISPLAY ARRAY ma_schedule TO schedule.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M52","display-arr-schedule") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (control-M) 
				LET fv_curr_row=arr_curr() 
				IF delete_sure(ma_schedule[fv_curr_row].plan_code) THEN 
					BEGIN WORK 

						DELETE FROM mps 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND plan_code = ma_schedule[fv_curr_row].plan_code 

						IF status <> 0 THEN 
							LET msgresp = kandoomsg("M",9660,"") 
							# ERROR "Trouble WHILE deleting MPS, MPS NOT deleted"
							ROLLBACK WORK 
						ELSE 
						COMMIT WORK 
					END IF 

					BEGIN WORK 

						DELETE 
						FROM mpsdemand 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND plan_code = ma_schedule[fv_curr_row].plan_code 
						AND type_text = "RO" 

						IF status <> 0 THEN 
							LET msgresp = kandoomsg("M",9660,"") 
							# ERROR "Trouble WHILE deleting MPS, MPS NOT deleted"
							ROLLBACK WORK 
						ELSE 
						COMMIT WORK 
					END IF 
				END IF 
				EXIT DISPLAY 
			ON KEY (ESC) 
				LET fv_continue = false 
				EXIT DISPLAY 
		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET fv_continue = false 
		END IF 
		CALL get_mps() 
	END WHILE 

	FOR fv_count = 1 TO 10 
		INITIALIZE ma_schedule[fv_count].* TO NULL 
	END FOR 


	CALL show_mps() 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO show the first 10 schedules on the SCREEN                  #
#-------------------------------------------------------------------------#

FUNCTION show_mps() 

	DEFINE 
	fv_count SMALLINT 

	FOR fv_count=1 TO 10 
		DISPLAY ma_schedule[fv_count].plan_code,ma_schedule[fv_count].desc_text 
		TO schedule[fv_count].plan_code,schedule[fv_count].desc_text 
	END FOR 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO RETURN the decision of the user as TO deletion of a RECORD #
#-------------------------------------------------------------------------#

FUNCTION delete_sure(fp_thing) 

	DEFINE 
	fp_thing CHAR(34), 
	fv_length SMALLINT, 
	fv_left SMALLINT, 
	fv_answer CHAR(1), 
	fv_string CHAR(75) 

	LET fv_string = 
	"Are you sure you want TO delete ",fp_thing clipped," (Y/N)?" 
	LET fv_length = length(fv_string)+2 
	LET fv_left = (75-fv_length)/2 
	{   -- albo
	    OPEN WINDOW w0_sure AT 23,fv_left with 1 rows,fv_length columns
	        ATTRIBUTE(white,border,prompt line first)

	    LET fv_answer = "A"
	    WHILE fv_answer NOT matches "[NY]"
	        prompt fv_string FOR CHAR fv_answer
	        IF (int_flag
	        OR quit_flag) THEN
	            LET int_flag  = FALSE
	            LET quit_flag = FALSE
	            LET fv_answer = "N"
	        ELSE
	            LET fv_answer = upshift(fv_answer)
	        END IF
	    END WHILE
	    CLOSE WINDOW w0_sure
	}
	-- albo --
	LET fv_answer = promptYN("",fv_string,"Y") 
	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_answer = "N" 
	ELSE 
		LET fv_answer = upshift(fv_answer) 
	END IF 
	----------
	RETURN (fv_answer="Y") 
END FUNCTION 
