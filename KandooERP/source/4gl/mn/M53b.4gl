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
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M53_GLOBALS.4gl"

DEFINE mv_seq_num INTEGER 
###########################################################################
# Purpose - MRP
########################################################################### 


###########################################################################
# FUNCTION create_table()
#
# 
########################################################################### 
FUNCTION create_table() 

	WHENEVER ERROR CONTINUE 
	CREATE TABLE mrptable 
	( 
	ware_code CHAR(3), 
	ware_desc_text CHAR(30), 
	part_code CHAR(15), 
	part_desc_text CHAR(30), 
	reference_num INTEGER, 
	type_text CHAR(3), 
	required_qty FLOAT, 
	due_date DATE, 
	start_date DATE, 
	on_hand_qty FLOAT, 
	ordered_qty FLOAT, 
	seq_num INTEGER, 
	lead_time INTEGER 
	) 
	CREATE INDEX mrptab_x01 ON mrptable (part_code, 
	reference_num) 
	WHENEVER ERROR stop 
	LET mv_seq_num = 1 

END FUNCTION 
###########################################################################
# END FUNCTION create_table()
########################################################################### 


###########################################################################
# FUNCTION drop_table() 
#
# 
########################################################################### 
FUNCTION drop_table() 

	WHENEVER ERROR CONTINUE 
	DROP TABLE mrptable 

END FUNCTION 
###########################################################################
# END FUNCTION drop_table() 
########################################################################### 


###########################################################################
# FUNCTION working(fp_text, fp_value) 
#
# 
########################################################################### 
FUNCTION working(fp_text, fp_value) 

	DEFINE 
	fp_text CHAR(20), 
	fp_value CHAR(30) 


	DISPLAY fp_text clipped, ": ", fp_value clipped, "" at 2,2 
	--- modif ericv init # attributes (normal,white)

END FUNCTION 
###########################################################################
# END FUNCTION working(fp_text, fp_value) 
########################################################################### 



###########################################################################
# FUNCTION get_cal_date(fv_date, fv_num, fv_direction)
#
# 
########################################################################### 
FUNCTION get_cal_date(fv_date, fv_num, fv_direction) 
	DEFINE 
	fv_old_date DATE, 
	fv_date DATE, 
	fv_date2 DATE, 
	fv_num INTEGER, 
	fv_direction CHAR(1), 
	fv_extra_days INTEGER 


	IF fv_direction = "F" THEN 
		LET fv_date2 = fv_date + fv_num units day 
		LET fv_extra_days = num_days(fv_date,fv_date2) 
	ELSE 
		LET fv_date2 = fv_date - fv_num units day 
		LET fv_extra_days = num_days(fv_date2,fv_date) 
	END IF 

	WHILE fv_extra_days > 0 
		IF fv_direction = "F" THEN 
			LET fv_old_date = fv_date2 
			LET fv_date2 = fv_date2 + (fv_extra_days units day) 

			IF fv_num = 0 THEN 
				LET fv_old_date = fv_date2 
			END IF 

			LET fv_extra_days = num_days(fv_old_date,fv_date2) 
		ELSE 
			LET fv_old_date = fv_date2 
			LET fv_date2 = fv_date2 - (fv_extra_days units day) 

			IF fv_num = 0 THEN 
				LET fv_old_date = fv_date2 
			END IF 

			LET fv_extra_days = num_days(fv_date2,fv_old_date) 
		END IF 
	END WHILE 

	RETURN fv_date2 

END FUNCTION 
###########################################################################
# END FUNCTION get_cal_date(fv_date, fv_num, fv_direction)
########################################################################### 


###########################################################################
# FUNCTION num_days(fp_start_date, fp_end_date)
#
# 
########################################################################### 
FUNCTION num_days(fp_start_date, fp_end_date) 

	DEFINE 
	fp_start_date DATE, 
	fp_end_date DATE, 
	fv_num_days INTEGER 


	IF fp_start_date = fp_end_date THEN 
		SELECT count(*) 
		INTO fv_num_days 
		FROM calendar 
		WHERE calendar_date = fp_start_date 
		AND available_ind = "N" 
	ELSE 
		SELECT count(*) 
		INTO fv_num_days 
		FROM calendar 
		WHERE calendar_date >= fp_start_date 
		AND calendar_date < fp_end_date 
		AND available_ind = "N" 
	END IF 

	RETURN fv_num_days 

END FUNCTION 
###########################################################################
# END FUNCTION num_days(fp_start_date, fp_end_date)
########################################################################### 


###########################################################################
# FUNCTION lookup_cmpy_code()
#
# 
########################################################################### 
FUNCTION lookup_cmpy_code() 

	DEFINE 
	fv_company_name LIKE company.name_text 

	SELECT company.name_text 
	INTO fv_company_name 
	FROM company 
	WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status <> 0 THEN 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("M",9551,"") 
			# ERROR "Company does NOT exist in the database"
			LET fv_company_name = NULL 
		ELSE 
			LET msgresp = kandoomsg("M",9552,"") 
			# ERROR "duplicate company codes exist in the database"
			LET fv_company_name = NULL 
		END IF 
	END IF 
	RETURN fv_company_name 
END FUNCTION 
###########################################################################
# END FUNCTION lookup_cmpy_code()
###########################################################################