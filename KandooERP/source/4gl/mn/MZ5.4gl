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

	Source code beautified by beautify.pl on 2020-01-02 17:31:37	$Id: $
}



# Purpose : Calender Setup

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10) 

END GLOBALS 

DEFINE 
mv_start_year INTEGER, 
mv_end_year INTEGER, 
ma_work array[7] OF CHAR(1), 
ma_weekday array[7] OF CHAR(9) 

MAIN 

	#Initial UI Init
	CALL setModuleId("MZ5") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL default_main() 

END MAIN 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the SCREEN AND drive the program                   #
#-------------------------------------------------------------------------#

FUNCTION default_main() 

	DEFINE 
	fv_year INTEGER, 
	fv_waste SMALLINT 

	OPEN WINDOW w0_defaults with FORM "M120" 
	CALL  windecoration_m("M120") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE "Press ESC TO save dates"

	CALL init_data() 

	IF get_dates() THEN 
		BEGIN WORK 
			FOR fv_year = mv_start_year TO mv_end_year 
				DELETE FROM calendar 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year(calendar.calendar_date)=fv_year 

				IF new_year(fv_year) THEN 
					IF aniversary_day(fv_year) THEN 
						IF easter(fv_year) THEN 
							IF queens_birth(fv_year) THEN 
								IF labour_day(fv_year) THEN 
									IF christmas(fv_year) THEN 
										CALL start_working() 
										IF work_days(fv_year) THEN 
											CALL stop_working() 
										COMMIT WORK 
									ELSE 
										ROLLBACK WORK 
									END IF 
								ELSE 
									ROLLBACK WORK 
								END IF 
							ELSE 
								ROLLBACK WORK 
							END IF 
						ELSE 
							ROLLBACK WORK 
						END IF 
					ELSE 
						ROLLBACK WORK 
					END IF 
				ELSE 
					ROLLBACK WORK 
				END IF 
			ELSE 
				ROLLBACK WORK 
			END IF 
		END FOR 
	END IF 
	CLOSE WINDOW w0_defaults 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO INITIALIZE the variables holding the data                  #
#-------------------------------------------------------------------------#

FUNCTION init_data() 
	DEFINE 
	fv_count SMALLINT 

	INITIALIZE mv_start_year,mv_end_year TO NULL 

	FOR fv_count = 1 TO 7 
		INITIALIZE ma_work[fv_count] TO NULL 
	END FOR 

	LET ma_weekday[1] = "Sunday" 
	LET ma_weekday[2] = "Monday" 
	LET ma_weekday[3] = "Tuesday" 
	LET ma_weekday[4] = "Wednesday" 
	LET ma_weekday[5] = "Thursday" 
	LET ma_weekday[6] = "Friday" 
	LET ma_weekday[7] = "Saturday" 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the dates FROM the SCREEN                              #
#-------------------------------------------------------------------------#

FUNCTION get_dates() 
	DEFINE 
	fv_count SMALLINT, 
	fv_ok SMALLINT 

	LET mv_start_year = year(today) 
	LET mv_end_year = year(today) 

	FOR fv_count = 1 TO 7 
		IF (fv_count = 1 
		OR fv_count = 7) THEN 
			LET ma_work[fv_count] = "N" 
		ELSE 
			LET ma_work[fv_count] = "Y" 
		END IF 
	END FOR 

	LET fv_ok = true 

	INPUT mv_start_year, mv_end_year, 
	ma_work[1], ma_work[2], 
	ma_work[3], ma_work[4], 
	ma_work[5], ma_work[6], 
	ma_work[7] 
	WITHOUT DEFAULTS 
	FROM start_year, end_year, 
	work_day[1].day_work, work_day[2].day_work, 
	work_day[3].day_work, work_day[4].day_work, 
	work_day[5].day_work, work_day[6].day_work, 
	work_day[7].day_work 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD end_year 
			IF mv_end_year<mv_start_year THEN 
				LET msgresp = kandoomsg("M",9708,"") 
				# ERROR "The END year cannot be before the start year"
				NEXT FIELD start_year 
			END IF 
	END INPUT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_ok = false 

		CALL init_data() 
		CLEAR FORM 
		LET msgresp = kandoomsg("M",9657,"") 
		# ERROR "Data Entry Aborted"
	END IF 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO calculate WHEN weekends are during the year                #
#-------------------------------------------------------------------------#

FUNCTION work_days(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_start_date DATE, 
	fv_end_date DATE, 
	fv_date_date DATE, 
	fv_ok SMALLINT, 
	fv_weekday INTEGER, 
	fv_date INTEGER, 
	fv_date_string CHAR(20) 

	LET fv_start_date = mdy(1,1,fp_year) 
	LET fv_end_date = mdy(12,31,fp_year) 
	LET fv_ok = true 

	FOR fv_date = fv_start_date TO fv_end_date 
		LET fv_weekday = weekday(fv_date) 

		IF ma_work[fv_weekday+1] = "N" THEN 
			SELECT calendar.calendar_date 
			FROM calendar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND calendar.calendar_date=fv_date 

			IF status <> 0 THEN 
				LET fv_date_date = 0 
				LET fv_date_date = fv_date_date + fv_date units day 
				LET fv_date_string = fv_date_date USING "dd/mm/yyyy" 

				CALL working("Date",fv_date_string) 

				INSERT INTO calendar 
				VALUES (glob_rec_kandoouser.cmpy_code,fv_date,ma_weekday[fv_weekday+1],"N", 
				today,glob_rec_kandoouser.sign_on_code,"MZ5") 

				IF sqlca.sqlcode <> 0 THEN 
					LET msgresp = kandoomsg("M",9709,"") 
					# ERROR "Trouble WHILE creating the calendar dates,
					#        calendar dates NOT saved"
					LET fv_ok = false 
					EXIT FOR 
				END IF 
			END IF 
		END IF 
	END FOR 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO work out the days taken off FOR new Years                  #
#-------------------------------------------------------------------------#

FUNCTION new_year(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_date DATE, 
	fv_ok SMALLINT 

	LET fv_ok = true 
	LET fv_date = mdy(1,1,fp_year) 

	INSERT INTO calendar 
	VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"New years Day","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

	IF status <> 0 THEN 
		LET msgresp = kandoomsg("M",9709,"") 
		#ERROR "Trouble WHILE creating calendar dates, calendar dates NOT saved"
		LET fv_ok = false 
	ELSE 
		LET fv_date = mdy(1,2,fp_year) 

		INSERT INTO calendar 
		VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"New Years","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

		IF status <> 0 THEN 
			LET msgresp = kandoomsg("M",9709,"") 
			# ERROR "Trouble WHILE creating calendar dates,
			# calendar dates NOT saved"
			LET fv_ok = false 
		END IF 
	END IF 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the dates taken off FOR Easter                         #
#-------------------------------------------------------------------------#

FUNCTION easter(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_gf_date SMALLINT, 
	fv_gf_month SMALLINT, 
	fv_ea_date SMALLINT, 
	fv_ea_month SMALLINT, 
	fv_ok SMALLINT, 
	fv_date DATE 

	LET fv_ok = true 

	OPEN WINDOW w0_easter with FORM "M120a" 
	CALL  windecoration_m("M120a") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	#MESSAGE "Press ESC TO save dates"

	DISPLAY fp_year,fp_year 
	TO gf_year,ea_year 

	INPUT fv_gf_date, fv_gf_month, 
	fv_ea_date, fv_ea_month 
	WITHOUT DEFAULTS 
	FROM gf_date, gf_month, 
	ea_date, ea_month 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD gf_month 
			IF NOT date_ok(fv_gf_date,fv_gf_month,fp_year) THEN 
				LET msgresp = kandoomsg("M",9710,"") 			# ERROR "This date IS NOT a legal date"
				NEXT FIELD gf_date 
			END IF 

			LET fv_date = mdy(fv_gf_month,fv_gf_date,fp_year) 

			SELECT calendar.calendar_date 
			FROM calendar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND calendar.calendar_date=fv_date 

			IF status != notfound THEN 
				LET msgresp = kandoomsg("M",9711,"") 
				# ERROR "A holiday has already been entered with this date"
				NEXT FIELD gf_date 
			END IF 

		AFTER FIELD ea_month 
			IF NOT date_ok(fv_ea_date,fv_ea_month,fp_year) THEN 
				LET msgresp = kandoomsg("M",9710,"") 
				#ERROR "This date IS NOT a legal date"
				NEXT FIELD ea_date 
			END IF 

			LET fv_date = mdy(fv_ea_month,fv_ea_date,fp_year) 

			SELECT calendar.calendar_date 
			FROM calendar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND calendar.calendar_date=fv_date 

			IF status != notfound THEN 
				LET msgresp = kandoomsg("M",9711,"") 
				# ERROR "A holiday has already been entered with this date"
				NEXT FIELD ea_date 
			END IF 
	END INPUT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_ok = false 
		LET msgresp = kandoomsg("M",9712,"") 
		# ERROR "Calendar Setup Aborted"
	ELSE 
		LET fv_date = mdy(fv_gf_month,fv_gf_date,fp_year) 

		INSERT INTO calendar 
		VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Good Friday","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

		IF status <> 0 THEN 
			LET msgresp = kandoomsg("M",9709,"") 
			# ERROR "Trouble WHILE creating the calendar dates,
			# calendar dates NOT saved"
			LET fv_ok = false 
		ELSE 
			LET fv_date = mdy(fv_ea_month,fv_ea_date,fp_year) 

			INSERT INTO calendar 
			VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Easter Monday","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9709,"") 
				# ERROR "Trouble WHILE creating the calendar dates,
				# calendar dates NOT saved"
				LET fv_ok = false 
			END IF 
		END IF 
	END IF 
	CLOSE WINDOW w0_easter 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO work out the days taken off FOR the Queen's Birthday       #
#-------------------------------------------------------------------------#

FUNCTION queens_birth(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_day INTEGER, 
	fv_date DATE, 
	fv_ok SMALLINT 

	LET fv_ok = true 
	LET fv_day = 1 

	WHILE true 
		LET fv_date = mdy(6,fv_day,fp_year) 
		IF weekday(fv_date) = 1 THEN 
			EXIT WHILE 
		END IF 
		LET fv_day = fv_day + 1 
	END WHILE 

	INSERT INTO calendar 
	VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Queen's Birthday","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

	IF status <> 0 THEN 
		LET msgresp = kandoomsg("M",9709,"") 
		#ERROR "Trouble WHILE creating calendar dates, calendar dates NOT saved"
		LET fv_ok = false 
	END IF 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO work out the days taken off FOR Labour day                 #
#-------------------------------------------------------------------------#

FUNCTION labour_day(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_day INTEGER, 
	fv_date DATE, 
	fv_ok SMALLINT 

	LET fv_ok = true 
	LET fv_day = 31 

	WHILE true 
		LET fv_date = mdy(10,fv_day,fp_year) 
		IF weekday(fv_date) = 1 THEN 
			EXIT WHILE 
		END IF 
		LET fv_day = fv_day - 1 
	END WHILE 

	INSERT INTO calendar 
	VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Labour Day","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

	IF status <> 0 THEN 
		LET msgresp = kandoomsg("M",9709,"") 
		#ERROR "Trouble WHILE creating calendar dates, calendar dates NOT saved"
		LET fv_ok = false 
	END IF 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO work out the days taken off FOR Christmas                  #
#-------------------------------------------------------------------------#

FUNCTION christmas(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_date DATE, 
	fv_ok SMALLINT 

	LET fv_ok = true 
	LET fv_date = mdy(12,24,fp_year) 

	INSERT INTO calendar 
	VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Christmas Eve","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

	IF status <> 0 THEN 
		LET msgresp = kandoomsg("M",9709,"") 
		#ERROR "Trouble WHILE creating the calendar dates,
		#calendar dates NOT saved"
		LET fv_ok = false 
	ELSE 
		LET fv_date = mdy(12,25,fp_year) 

		INSERT INTO calendar 
		VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Christmas Day","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

		IF status <> 0 THEN 
			LET msgresp = kandoomsg("M",9709,"") 
			#ERROR "Trouble WHILE creating the calendar dates,
			#calendar dates NOT saved"
			LET fv_ok = false 
		ELSE 
			LET fv_date = mdy(12,26,fp_year) 

			INSERT INTO calendar 
			VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Boxing Day","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9709,"") 
				# ERROR "Trouble WHILE creating the calendar dates,
				#  calendar dates NOT saved"
				LET fv_ok = false 
			END IF 
		END IF 
	END IF 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the dates taken off FOR Aniversary day                 #
#-------------------------------------------------------------------------#

FUNCTION aniversary_day(fp_year) 
	DEFINE 
	fp_year INTEGER, 
	fv_ad_date SMALLINT, 
	fv_ad_month SMALLINT, 
	fv_ok SMALLINT, 
	fv_date DATE 

	LET fv_ok = true 

	OPEN WINDOW w0_aniversary with FORM "M120b" 
	CALL  windecoration_m("M120b") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") #MESSAGE "Press ESC TO save dates"

	DISPLAY fp_year 
	TO ad_year 

	INPUT fv_ad_date,fv_ad_month WITHOUT DEFAULTS 
	FROM ad_date,ad_month 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD ad_month 
			IF NOT date_ok(fv_ad_date,fv_ad_month,fp_year) THEN 
				LET msgresp = kandoomsg("M",9710,"") 		# ERROR "This date IS NOT a legal date"
				NEXT FIELD ad_date 
			END IF 

			LET fv_date = mdy(fv_ad_month,fv_ad_date,fp_year) 

			SELECT calendar.calendar_date 
			FROM calendar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND calendar.calendar_date=fv_date 

			IF status != notfound THEN 
				LET msgresp = kandoomsg("M",9711,"") 
				#ERROR "A holiday has already been entered with this date"
				NEXT FIELD ad_date 
			END IF 
	END INPUT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_ok = false 
		LET msgresp = kandoomsg("M",9712,"") 
		# ERROR "Calendar Setup Aborted"
	ELSE 
		LET fv_date = mdy(fv_ad_month,fv_ad_date,fp_year) 

		INSERT INTO calendar 
		VALUES (glob_rec_kandoouser.cmpy_code,fv_date,"Aniversary Day","N",today,glob_rec_kandoouser.sign_on_code,"MZ5") 

		IF status <> 0 THEN 
			LET msgresp = kandoomsg("M",9709,"") 
			# ERROR "Trouble WHILE creating the calendar dates,
			# calendar dates NOT saved"
			LET fv_ok = false 
		END IF 
	END IF 
	CLOSE WINDOW w0_aniversary 
	RETURN fv_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO see IF the given date IS a legal one  i.e does it exist    #
#-------------------------------------------------------------------------#

FUNCTION date_ok(fp_date,fp_month,fp_year) 
	DEFINE 
	fp_date SMALLINT, 
	fp_month SMALLINT, 
	fp_year SMALLINT, 
	fv_date DATE 

	WHENEVER ERROR CONTINUE 
	LET fv_date = mdy(fp_month,fp_date,fp_year) 
	WHENEVER ERROR stop 
	RETURN (STATUS = 0) 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION start_working() 
	{
	    OPEN WINDOW w0_working AT 6,6 with 3 rows,56 columns     -- albo  KD-762
	        ATTRIBUTE(white,border)
	}
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION stop_working() 
	--    CLOSE WINDOW w0_working      -- albo  KD-762
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION working(fp_text,fp_value) 
	DEFINE 
	fp_text CHAR(20), 
	fp_value CHAR(30) 

	DISPLAY fp_text clipped,": ",fp_value clipped,"" at 2,2 
	attribute(normal,white) 
END FUNCTION 
