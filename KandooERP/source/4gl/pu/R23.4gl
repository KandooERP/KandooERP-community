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

	Source code beautified by beautify.pl on 2020-01-02 17:06:16	Source code beautified by beautify.pl on 2020-01-02 17:03:25	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R23 allows the user TO search FOR receipts on job info

GLOBALS 
	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	pt_poaudit RECORD LIKE poaudit.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pa_poaudit array[1000] OF RECORD 
		receipt_num LIKE poaudit.tran_num, 
		vend_code LIKE poaudit.vend_code, 
		order_num LIKE poaudit.po_num, 
		type_ind LIKE purchdetl.type_ind, 
		received_qty LIKE poaudit.received_qty, 
		uom_code LIKE purchdetl.uom_code, 
		desc_text LIKE poaudit.desc_text 
	END RECORD, 
	idx, id_flag, scrn, cnt, err_flag SMALLINT, 
	ans CHAR(2), 
	sel_text, where_part CHAR(500) 
END GLOBALS 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R23") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	LET ans = "Y" 
	WHILE ans matches "[yY]" 
		CALL doit() 
		CLOSE WINDOW r120 
		LET ans = "Y" 
	END WHILE 

END MAIN 

FUNCTION doit() 

	OPEN WINDOW r120 with FORM "R120" 
	CALL  windecoration_r("R120") 


	LET pr_purchdetl.job_code = arg_val(1) 
	LET pr_purchdetl.var_num = arg_val(2) 
	LET pr_purchdetl.activity_code = arg_val(3) 

	SELECT * INTO pr_activity.* FROM activity 
	WHERE job_code = pr_purchdetl.job_code 
	AND var_code = pr_purchdetl.var_num 
	AND activity_code = pr_purchdetl.activity_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		INPUT BY NAME pr_purchdetl.job_code, 
		pr_purchdetl.var_num, 
		pr_purchdetl.activity_code 
		ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","R12","inp-purchdetl-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (control-b) 
				CASE 
					WHEN infield (job_code) 
						LET pr_purchdetl.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_purchdetl.job_code 


					WHEN infield (var_num) 
						LET pr_purchdetl.var_num = 
						show_jobvars(glob_rec_kandoouser.cmpy_code, pr_purchdetl.job_code) 
						DISPLAY BY NAME pr_purchdetl.var_num 


					WHEN infield (activity_code) 
						LET pr_purchdetl.activity_code = 
						show_activity(glob_rec_kandoouser.cmpy_code, pr_purchdetl.job_code, pr_purchdetl.var_num) 
						DISPLAY BY NAME pr_purchdetl.activity_code 

				END CASE 

			AFTER FIELD activity_code 
				SELECT * INTO pr_activity.* FROM activity 
				WHERE job_code = pr_purchdetl.job_code 
				AND var_code = pr_purchdetl.var_num 
				AND activity_code = pr_purchdetl.activity_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9111,"Job, Variation, Activity combination") 
					#9111 Job, Variation, Activity combination NOT found.
					NEXT FIELD job_code 
				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT program 
				ELSE 
					SELECT * INTO pr_activity.* FROM activity 
					WHERE job_code = pr_purchdetl.job_code 
					AND var_code = pr_purchdetl.var_num 
					AND activity_code = pr_purchdetl.activity_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp 
						= kandoomsg("U",9111,"Job, variation, activity combination") 
						#9111 Job, Variation, Activity combination NOT found.
						NEXT FIELD job_code 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		DISPLAY BY NAME pr_purchdetl.job_code, 
		pr_purchdetl.var_num, 
		pr_purchdetl.activity_code 

	END IF 

	DECLARE c_pord CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_purchdetl.job_code 
	AND var_num = pr_purchdetl.var_num 
	AND activity_code = pr_purchdetl.activity_code 

	LET idx = 0 
	FOREACH c_pord INTO pr_purchdetl.* 
		DECLARE audcurs CURSOR FOR 
		SELECT * FROM poaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND po_num = pr_purchdetl.order_num 
		AND line_num = pr_purchdetl.line_num 
		AND (tran_code = "GR" OR 
		tran_code = "GA") 
		ORDER BY tran_num 
		FOREACH audcurs INTO pr_poaudit.* 
			LET idx = idx + 1 
			LET pa_poaudit[idx].receipt_num = pr_poaudit.tran_num 
			LET pa_poaudit[idx].vend_code = pr_purchdetl.vend_code 
			LET pa_poaudit[idx].order_num = pr_purchdetl.order_num 
			LET pa_poaudit[idx].type_ind = pr_purchdetl.type_ind 
			LET pa_poaudit[idx].received_qty = pr_poaudit.received_qty 
			LET pa_poaudit[idx].uom_code = pr_purchdetl.uom_code 
			LET pa_poaudit[idx].desc_text = pr_purchdetl.desc_text 
			IF idx = 1000 THEN 
				LET msgresp = kandoomsg("U",1505,idx) 
				#1505 Only first 1000 rows selected.
				EXIT FOREACH 
			END IF 
		END FOREACH 
	END FOREACH 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("U",1008,"") 
	# F3/F4 TO Page Fwd/Bwd;  OK TO Continue.
	INPUT ARRAY pa_poaudit WITHOUT DEFAULTS FROM sr_poaudit.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R23","inp-arr-poaudit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

			IF arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 The are no more rows in the direction you are going.
			END IF 

		BEFORE FIELD vend_code 
			NEXT FIELD tran_num 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW r120 
		EXIT program 
	END IF 
END FUNCTION 
