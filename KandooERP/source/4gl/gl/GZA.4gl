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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_mode CHAR(10)
DEFINE modu_start_date_fiscal_year DATE
DEFINE modu_type_period CHAR(8)

############################################################
# FUNCTION GZA_main()
#
# Purpose - Setting up Fiscal years and Fiscal Periods in GL
############################################################
FUNCTION GZA_main()

	CALL setModuleId("GZA") 

	OPEN WINDOW G153 WITH FORM "G153" 
	CALL windecoration_g("G153") 

	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
	MENU "Fiscal Year Setup" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","GZA","menu-Fiscal_Year_Setup")
			CALL fgl_dialog_setactionlabel("Create Fiscal Year","Create \nFiscal Year","{CONTEXT}/public/querix/icon/svg/24/ic_add_box_24px.svg",4,FALSE,"Create Fiscal Year and Periods automatically")
			CALL fgl_dialog_setactionlabel("Show/Update Periods","Show/Update \nPeriods","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",5,FALSE,"Show/Update Periods of Fiscal Year")
			CALL fgl_dialog_setactionlabel("Delete Fiscal Year","Delete \nFiscal Year","{CONTEXT}/public/querix/icon/svg/24/ic_delete_24px.svg",6,FALSE,"Delete Fiscal Year")

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()

		ON ACTION "Create Fiscal Year"
			LET modu_mode = "CREATE"
			CALL GZA_get_info(GZA_create_fiscal_year())

		ON ACTION "Show/Update Periods"
			LET modu_mode = "UPDATE"
			CALL GZA_get_info(GZA_query())

		ON ACTION "Delete Fiscal Year"
			LET modu_mode = "DELETE"
			CALL GZA_get_info(GZA_delete_fiscal_year())

		ON ACTION "EXIT" 
			EXIT MENU

	END MENU

	CLOSE WINDOW G153

END FUNCTION 
############################################################
# END FUNCTION GZA_main()
############################################################

############################################################
# FUNCTION GZA_query() 
# 
# RETURN r_where_text (Query By Example)
############################################################
FUNCTION GZA_query()
	DEFINE r_where_text STRING

	CLEAR FORM

	MESSAGE "Enter selection criteria."
	CONSTRUCT r_where_text ON 
	year_num, 
	period_num, 
	start_date, 
	end_date, 
	gl_flag, 
	ar_flag, 
	ap_flag, 
	pu_flag, 
	in_flag, 
	jm_flag, 
	oe_flag 
	FROM 
	sr_period[1].year_num, 
	sr_period[1].period_num,
	sr_period[1].start_date,
	sr_period[1].end_date,
	sr_period[1].gl_flag,
	sr_period[1].ar_flag,
	sr_period[1].ap_flag,
	sr_period[1].pu_flag,
	sr_period[1].in_flag,
	sr_period[1].jm_flag,
	sr_period[1].oe_flag

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZA","fiscalYearQuery") 
			CALL fgl_dialog_setactionlabel("ACCEPT","Show Periods","{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg",2,FALSE,"Accept Query and show list of Periods (leave fields empty to show all Periods)")
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION
############################################################
# END FUNCTION GZA_query()
############################################################

############################################################
# FUNCTION GZA_get_info(p_mode)
#
# Displaying Fiscal periods with the ability to change them.
############################################################
FUNCTION GZA_get_info(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF 
	RECORD 
		year_num LIKE period.year_num, 
		type_period CHAR(20),
		period_num LIKE period.period_num, 
		start_date LIKE period.start_date, 
		end_date LIKE period.end_date, 
		gl_flag LIKE period.gl_flag, 
		ar_flag LIKE period.ar_flag, 
		ap_flag LIKE period.ap_flag, 
		pu_flag LIKE period.pu_flag, 
		in_flag LIKE period.in_flag, 
		jm_flag LIKE period.jm_flag, 
		oe_flag LIKE period.oe_flag 
	END RECORD 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_fiscal_year LIKE period.year_num 
	DEFINE l_start_date_fiscal_year LIKE period.start_date
	DEFINE l_end_date_fiscal_year LIKE period.end_date
	DEFINE l_period_num LIKE period.period_num
	DEFINE l_max_period_num LIKE period.period_num
	DEFINE l_msg_err STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_scr_line SMALLINT
	DEFINE l_cnt SMALLINT 
	DEFINE l_while SMALLINT 
	DEFINE l_mode SMALLINT 
	DEFINE l_arr_size INTEGER

	IF p_where_text IS NULL OR
		int_flag = 1 OR quit_flag = 1 THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN NULL
	END IF	

	LET l_query_text = 
	"SELECT * FROM period ", 
	"WHERE ", p_where_text CLIPPED," ",
	"AND period.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"ORDER BY period.start_date"

	PREPARE p_period_0 FROM l_query_text 
	DECLARE c_period_0 CURSOR FOR p_period_0 

	IF p_where_text <> " 1!=1" THEN
		# Create Fiscal Year and Periods automatically		
		LET l_idx = 0
		FOREACH c_period_0 
			LET l_idx = l_idx + 1 
		END FOREACH
 
		IF l_idx = 0 THEN 
			ERROR "Data not found !"
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			RETURN NULL
		END IF
	END IF 

	LET l_while = TRUE 
	WHILE l_while 

		LET l_query_text = 
		"SELECT * FROM period ", 
		"WHERE ", p_where_text CLIPPED," ",
		"AND period.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"ORDER BY period.start_date"

		PREPARE p_period_1 FROM l_query_text 
		DECLARE c_period_1 CURSOR FOR p_period_1

		CALL l_arr_rec_period.CLEAR()
		LET l_idx = 0 
		FOREACH c_period_1 INTO l_rec_period.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_period[l_idx].year_num = l_rec_period.year_num 
			LET l_arr_rec_period[l_idx].period_num = l_rec_period.period_num
			LET l_arr_rec_period[l_idx].start_date = l_rec_period.start_date 
			LET l_arr_rec_period[l_idx].end_date = l_rec_period.end_date 
			LET l_arr_rec_period[l_idx].type_period= get_type_period(l_rec_period.period_num,l_rec_period.start_date,l_rec_period.end_date)
			LET l_arr_rec_period[l_idx].gl_flag = l_rec_period.gl_flag 
			LET l_arr_rec_period[l_idx].ar_flag = l_rec_period.ar_flag 
			LET l_arr_rec_period[l_idx].ap_flag = l_rec_period.ap_flag 
			LET l_arr_rec_period[l_idx].pu_flag = l_rec_period.pu_flag 
			LET l_arr_rec_period[l_idx].in_flag = l_rec_period.in_flag 
			LET l_arr_rec_period[l_idx].jm_flag = l_rec_period.jm_flag 
			LET l_arr_rec_period[l_idx].oe_flag = l_rec_period.oe_flag 
		END FOREACH 

		CALL set_count(l_idx) 
		LET l_mode = MODE_UPDATE 

		INPUT ARRAY l_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* ATTRIBUTES(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZA","fiscalYearList") --albo 
				IF modu_mode = "DELETE" THEN
					LET l_msg_err = "Are you sure you want to delete ",l_rec_period.year_num USING "<<<<&"," Fiscal Year?" 
					IF NOT promptTF("",l_msg_err,TRUE) THEN 
						LET l_while = FALSE
						EXIT INPUT
					ELSE
						IF	check_accounts_fiscal_year_periods(l_rec_period.year_num,NULL) <> 0 THEN
							LET l_msg_err = "There are Accounts that are associated with ",l_rec_period.year_num USING "<<<<&"," Fiscal Year.\nFiscal Year cannot be deleted!"
							CALL msgerror("",l_msg_err)  
							LET l_while = FALSE
							EXIT INPUT
						ELSE
							# If the 'fiscalyear' table will be used, then remove the Comments !!!
--							BEGIN WORK
--							EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
							DELETE FROM period
							WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND period.year_num = l_rec_period.year_num
--							DELETE FROM fiscalyear 
--							WHERE fiscalyear.cmpy_code = glob_rec_kandoouser.cmpy_code
--							AND fiscalyear.year_num = l_rec_period.year_num
--							COMMIT WORK
							LET l_msg_err = "Fiscal Year ",l_rec_period.year_num USING "<<<<&"," has been successfully deleted."
							CALL msgcontinue("",l_msg_err) 
							LET l_while = FALSE
							EXIT INPUT
						END IF
					END IF
				END IF					

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_period.year_num = l_arr_rec_period[l_idx].year_num 
				LET l_rec_period.period_num = l_arr_rec_period[l_idx].period_num 
				LET l_rec_period.start_date = l_arr_rec_period[l_idx].start_date 
				LET l_rec_period.end_date = l_arr_rec_period[l_idx].end_date 
				LET l_rec_period.gl_flag = l_arr_rec_period[l_idx].gl_flag 
				LET l_rec_period.ar_flag = l_arr_rec_period[l_idx].ar_flag 
				LET l_rec_period.ap_flag = l_arr_rec_period[l_idx].ap_flag 
				LET l_rec_period.pu_flag = l_arr_rec_period[l_idx].pu_flag 
				LET l_rec_period.in_flag = l_arr_rec_period[l_idx].in_flag 
				LET l_rec_period.jm_flag = l_arr_rec_period[l_idx].jm_flag 
				LET l_rec_period.oe_flag = l_arr_rec_period[l_idx].oe_flag 
				LET l_arr_rec_period[l_idx].type_period = get_type_period(l_arr_rec_period[l_idx].period_num,l_arr_rec_period[l_idx].start_date,l_arr_rec_period[l_idx].end_date)

			BEFORE INSERT 
				LET l_mode = MODE_INSERT 
				LET l_idx = arr_curr() 
				IF modu_type_period = "Custom" THEN 
					IF l_idx = 1 THEN 
						LET l_arr_rec_period[l_idx].year_num = YEAR(modu_start_date_fiscal_year)
						LET l_arr_rec_period[l_idx].period_num = 1
						LET l_arr_rec_period[l_idx].start_date = modu_start_date_fiscal_year
						LET p_where_text = ""
						NEXT FIELD end_date
					ELSE
						LET l_arr_rec_period[l_idx].year_num = YEAR(modu_start_date_fiscal_year)
						NEXT FIELD period_num						
					END IF
				END IF
				LET l_arr_rec_period[l_idx].gl_flag = "Y" 
				LET l_arr_rec_period[l_idx].ar_flag = "Y" 
				LET l_arr_rec_period[l_idx].ap_flag = "Y" 
				LET l_arr_rec_period[l_idx].pu_flag = "Y" 
				LET l_arr_rec_period[l_idx].in_flag = "Y" 
				LET l_arr_rec_period[l_idx].jm_flag = "Y" 
				LET l_arr_rec_period[l_idx].oe_flag = "Y" 

			BEFORE DELETE 
				LET l_idx = arr_curr() 
				IF l_idx > 0 AND l_arr_rec_period[l_idx].period_num IS NOT NULL THEN 
					LET l_msg_err = "Are you sure you want to delete Period number ",l_arr_rec_period[l_idx].period_num USING "<<<<&","?"  
					IF NOT promptTF("",l_msg_err,TRUE) THEN 
						CANCEL DELETE 
					ELSE 
						IF check_accounts_fiscal_year_periods(l_arr_rec_period[l_idx].year_num,l_arr_rec_period[l_idx].period_num) <> 0 THEN
							LET l_msg_err = "There are Accounts that are associated with Period number ",l_arr_rec_period[l_idx].period_num USING "<<<<&",".\nPeriod cannot be deleted!"
							CALL msgerror("",l_msg_err)
							CANCEL DELETE 
						END IF 
					END IF 
				END IF 

			BEFORE FIELD period_num 
				LET l_idx = arr_curr() 
				IF (l_arr_rec_period[l_idx].year_num IS NULL 
				OR l_arr_rec_period[l_idx].year_num < 1988) THEN 
					ERROR kandoomsg2("G",9529,"1987") 
					#9529 Year entered must be greater THEN XXXX
					NEXT FIELD year_num 
				END IF 

				# Automatic generation of financial period numbers
				IF l_arr_rec_period[l_idx].year_num IS NOT NULL AND 
				l_arr_rec_period[l_idx].period_num IS NULL AND 
				l_mode = MODE_INSERT THEN 
					SELECT MAX(period.period_num)+1 INTO l_max_period_num 
					FROM period 
					WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					period.year_num = l_arr_rec_period[l_idx].year_num 
					IF l_max_period_num IS NOT NULL THEN 
						LET l_arr_rec_period[l_idx].period_num = l_max_period_num 
					ELSE 
						LET l_arr_rec_period[l_idx].period_num = 1 
					END IF 
				END IF 

				IF l_arr_rec_period[l_idx].period_num IS NOT NULL THEN 
					LET l_period_num = l_arr_rec_period[l_idx].period_num 
				ELSE 
					LET l_period_num = NULL 
				END IF 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD year_num 
				LET l_idx = arr_curr() 
				IF l_rec_period.year_num <> l_arr_rec_period[l_idx].year_num THEN 
					IF	check_accounts_fiscal_year_periods(l_rec_period.year_num,NULL) <> 0 THEN
						LET l_msg_err = "There are Accounts that are associated with ",l_rec_period.year_num USING "<<<<&"," Fiscal Year.\nFiscal Year cannot be changed!"
						CALL msgerror("",l_msg_err)  
						LET l_arr_rec_period[l_idx].year_num = l_rec_period.year_num 
						NEXT FIELD year_num
					END IF
				END IF 

			AFTER FIELD period_num 
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line()
				IF l_rec_period.period_num <> l_arr_rec_period[l_idx].period_num THEN 
					IF check_accounts_fiscal_year_periods(l_arr_rec_period[l_idx].year_num,l_rec_period.period_num) <> 0 THEN
						LET l_msg_err = "There are Accounts that are associated with Period number ",l_rec_period.period_num USING "<<<<&",".\nPeriod cannot be changed!"
						CALL msgerror("",l_msg_err)
						LET l_arr_rec_period[l_idx].period_num = l_rec_period.period_num 
						NEXT FIELD period_num 
					END IF
				END IF 

				IF (l_arr_rec_period[l_idx].period_num IS NULL 
				OR l_arr_rec_period[l_idx].period_num < 1 
				OR l_arr_rec_period[l_idx].period_num > 366) THEN 
					ERROR kandoomsg2("G",9532,"") 
					#9532 The period entered must be in the range 1 TO 366
					NEXT FIELD period_num 
				END IF 

				IF (l_arr_rec_period[l_idx].year_num != l_rec_period.year_num 
				OR l_arr_rec_period[l_idx].period_num != l_rec_period.period_num) 
				OR (l_rec_period.year_num IS NULL 
				AND l_rec_period.period_num IS NULL) THEN 
					SELECT COUNT(*) INTO l_cnt 
					FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_arr_rec_period[l_idx].year_num 
					AND period_num = l_arr_rec_period[l_idx].period_num 
					IF l_cnt > 0 THEN 
						ERROR kandoomsg2("U",9104,"") 
						#9104 RECORD already exists
						LET l_arr_rec_period[l_idx].period_num = l_period_num 
						NEXT FIELD period_num 
					END IF 
				END IF 
				LET l_arr_rec_period[l_idx].type_period = get_type_period(l_arr_rec_period[l_idx].period_num,l_arr_rec_period[l_idx].start_date,l_arr_rec_period[l_idx].end_date) 
				DISPLAY l_arr_rec_period[l_idx].type_period TO sr_period[l_scr_line].type_period

			AFTER FIELD start_date 
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line()
				IF l_arr_rec_period[l_idx].start_date IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD start_date 
				END IF 

				IF l_arr_rec_period[l_idx].start_date >= l_arr_rec_period[l_idx].end_date THEN 
					ERROR "End date must be later than Start date." 
					NEXT FIELD end_date 
				END IF 

				SELECT COUNT(*) INTO l_cnt 
				FROM period 
				WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period.start_date <= l_arr_rec_period[l_idx].start_date 
				AND period.end_date >= l_arr_rec_period[l_idx].start_date 
				AND (period.year_num != l_arr_rec_period[l_idx].year_num 
				OR period.period_num != l_arr_rec_period[l_idx].period_num) 
				IF l_cnt <> 0 THEN 
					ERROR kandoomsg2("G",9530,"") 
					#9530 Start OR END date falls within the date range of....
					NEXT FIELD start_date 
				END IF 
				LET l_arr_rec_period[l_idx].type_period = get_type_period(l_arr_rec_period[l_idx].period_num,l_arr_rec_period[l_idx].start_date,l_arr_rec_period[l_idx].end_date) 
				DISPLAY l_arr_rec_period[l_idx].type_period TO sr_period[l_scr_line].type_period

			AFTER FIELD end_date 
				LET l_idx = arr_curr() 
				LET l_scr_line = scr_line()
				IF l_arr_rec_period[l_idx].end_date IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD end_date 
				END IF 

				IF l_arr_rec_period[l_idx].end_date <= l_arr_rec_period[l_idx].start_date THEN 
					ERROR kandoomsg2("G",9531,"") 
					#9531 Start date must be earlier than END date
					NEXT FIELD start_date 
				END IF 

				SELECT COUNT(*) INTO l_cnt 
				FROM period 
				WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period.start_date <= l_arr_rec_period[l_idx].end_date 
				AND period.end_date >= l_arr_rec_period[l_idx].end_date 
				AND (period.year_num != l_arr_rec_period[l_idx].year_num 
				OR period.period_num != l_arr_rec_period[l_idx].period_num) 
				IF l_cnt <> 0 THEN 
					ERROR kandoomsg2("G",9530,"") 
					#9530 Start OR END date falls within the date range of....
					NEXT FIELD end_date 
				END IF 

				IF (l_arr_rec_period[l_idx].year_num IS NULL 
				OR l_arr_rec_period[l_idx].year_num < 1988) THEN 
					ERROR kandoomsg2("G",9529,"1987") 
					#9529 Year entered must be greater THEN XXXX
					NEXT FIELD year_num 
				END IF 
				LET l_arr_rec_period[l_idx].type_period = get_type_period(l_arr_rec_period[l_idx].period_num,l_arr_rec_period[l_idx].start_date,l_arr_rec_period[l_idx].end_date) 
				DISPLAY l_arr_rec_period[l_idx].type_period TO sr_period[l_scr_line].type_period

			AFTER FIELD gl_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].gl_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD gl_flag 
				END IF 

			AFTER FIELD ar_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].ar_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ar_flag 
				END IF 

			AFTER FIELD ap_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].ap_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ap_flag 
				END IF 

			AFTER FIELD pu_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].pu_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pu_flag 
				END IF 

			AFTER FIELD in_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].in_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD in_flag 
				END IF 

			AFTER FIELD jm_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].jm_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD jm_flag 
				END IF 

			AFTER FIELD oe_flag 
				LET l_idx = arr_curr() 
				IF l_arr_rec_period[l_idx].oe_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD oe_flag 
				END IF 

			AFTER INSERT 
				LET l_mode = MODE_UPDATE 
				LET l_idx = arr_curr() 
				LET l_rec_period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (l_arr_rec_period[l_idx].year_num IS NOT NULL 
				AND l_arr_rec_period[l_idx].period_num IS NOT NULL 
				AND l_arr_rec_period[l_idx].start_date IS NOT NULL 
				AND l_arr_rec_period[l_idx].end_date IS NOT NULL) THEN 
					LET l_rec_period.cmpy_code  = glob_rec_kandoouser.cmpy_code 
					LET l_rec_period.year_num   = l_arr_rec_period[l_idx].year_num 
					LET l_rec_period.period_num = l_arr_rec_period[l_idx].period_num 
					LET l_rec_period.start_date = l_arr_rec_period[l_idx].start_date 
					LET l_rec_period.end_date   = l_arr_rec_period[l_idx].end_date 
					LET l_rec_period.gl_flag    = l_arr_rec_period[l_idx].gl_flag 
					LET l_rec_period.ar_flag    = l_arr_rec_period[l_idx].ar_flag 
					LET l_rec_period.ap_flag    = l_arr_rec_period[l_idx].ap_flag 
					LET l_rec_period.pu_flag    = l_arr_rec_period[l_idx].pu_flag 
					LET l_rec_period.in_flag    = l_arr_rec_period[l_idx].in_flag 
					LET l_rec_period.jm_flag    = l_arr_rec_period[l_idx].jm_flag 
					LET l_rec_period.oe_flag    = l_arr_rec_period[l_idx].oe_flag 

					SELECT COUNT(*) INTO l_cnt 
					FROM period 
					WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND period.year_num = l_arr_rec_period[l_idx].year_num 
					AND period.period_num = l_arr_rec_period[l_idx].period_num 
					IF l_cnt = 0 THEN 
						INSERT INTO period VALUES (l_rec_period.*) 
					ELSE 
						ERROR kandoomsg2("U",9104,"") 
						#9104 RECORD already exists
					END IF 
				END IF 

			AFTER DELETE 
				DELETE FROM period 
				WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code
				AND period.year_num = l_rec_period.year_num
				AND period.period_num = l_rec_period.period_num 
				LET l_while = TRUE 
				IF modu_type_period = "Custom" THEN
					LET l_arr_size = l_arr_rec_period.GETSIZE()
					IF l_arr_size <> 0 THEN
						LET p_where_text = "period.start_date >= '",l_arr_rec_period[1].start_date,"' AND period.end_date <= '",l_arr_rec_period[l_arr_size].end_date,"'"
					ELSE
						LET p_where_text = " 1!=1" 
					END IF
				END IF
				EXIT INPUT

			AFTER ROW 
				LET l_idx = arr_curr() 
				IF (l_arr_rec_period[l_idx].year_num IS NOT NULL 
				AND l_arr_rec_period[l_idx].period_num IS NOT NULL 
				AND l_arr_rec_period[l_idx].start_date IS NOT NULL 
				AND l_arr_rec_period[l_idx].end_date IS NOT NULL) THEN 
					UPDATE period 
					SET period.year_num = l_arr_rec_period[l_idx].year_num, 
					period.period_num   = l_arr_rec_period[l_idx].period_num, 
					period.start_date   = l_arr_rec_period[l_idx].start_date, 
					period.end_date     = l_arr_rec_period[l_idx].end_date, 
					period.gl_flag      = l_arr_rec_period[l_idx].gl_flag, 
					period.ar_flag      = l_arr_rec_period[l_idx].ar_flag, 
					period.ap_flag      = l_arr_rec_period[l_idx].ap_flag, 
					period.pu_flag      = l_arr_rec_period[l_idx].pu_flag, 
					period.in_flag      = l_arr_rec_period[l_idx].in_flag, 
					period.jm_flag      = l_arr_rec_period[l_idx].jm_flag, 
					period.oe_flag      = l_arr_rec_period[l_idx].oe_flag 
					WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND period.year_num = l_arr_rec_period[l_idx].year_num 
					AND period.period_num = l_arr_rec_period[l_idx].period_num 
				END IF 

				LET l_rec_period.year_num = l_arr_rec_period[l_idx].year_num 
				LET l_rec_period.period_num = l_arr_rec_period[l_idx].period_num 
				LET l_rec_period.start_date = l_arr_rec_period[l_idx].start_date 
				LET l_rec_period.end_date = l_arr_rec_period[l_idx].end_date 
				LET l_rec_period.gl_flag = l_arr_rec_period[l_idx].gl_flag 
				LET l_rec_period.ar_flag = l_arr_rec_period[l_idx].ar_flag 
				LET l_rec_period.ap_flag = l_arr_rec_period[l_idx].ap_flag 
				LET l_rec_period.pu_flag = l_arr_rec_period[l_idx].pu_flag 
				LET l_rec_period.in_flag = l_arr_rec_period[l_idx].in_flag 
				LET l_rec_period.jm_flag = l_arr_rec_period[l_idx].jm_flag 
				LET l_rec_period.oe_flag = l_arr_rec_period[l_idx].oe_flag 

			AFTER INPUT 
				DECLARE c_period_4 CURSOR FOR 
				SELECT UNIQUE period.year_num 
				FROM period 
				WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				ORDER BY period.year_num

				IF l_arr_rec_period.GETSIZE() = 0 THEN
					CLEAR FORM
				END IF
				# If the 'fiscalyear' table will be used, then remove the Comments !!!
--				BEGIN WORK
--				EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
--				DELETE FROM fiscalyear 
--				WHERE fiscalyear.cmpy_code = glob_rec_kandoouser.cmpy_code
				FOREACH c_period_4 INTO l_fiscal_year  
					IF check_fiscal_year_integrity(l_fiscal_year) THEN	
--						SELECT MIN(period.start_date),MAX(period.end_date) INTO l_start_date_fiscal_year,l_end_date_fiscal_year
--						FROM period
--						WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code
--						AND period.year_num = l_fiscal_year   
--						INSERT INTO fiscalyear VALUES (glob_rec_kandoouser.cmpy_code,l_fiscal_year,l_start_date_fiscal_year,l_end_date_fiscal_year)
					ELSE
--						ROLLBACK WORK
						LET l_msg_err = "The ",l_fiscal_year USING "<<<<&"," Fiscal Year does not contain the right number of days!"  
						CALL msgerror("",l_msg_err)
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						CONTINUE INPUT
					END IF						
				END FOREACH
--				COMMIT WORK

				IF int_flag = 1 OR quit_flag = 1 
				THEN # "Cancel" ACTION activated 
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					LET l_while = FALSE 
					IF modu_type_period = "Custom" THEN
						LET modu_type_period = NULL
					END IF
				ELSE # "Apply" ACTION activated 
					MESSAGE "Data saved."
					LET l_while = TRUE
					IF modu_type_period = "Custom" THEN
						LET l_arr_size = l_arr_rec_period.GETSIZE()
						IF l_arr_size <> 0 THEN
							LET p_where_text = "period.start_date >= '",l_arr_rec_period[1].start_date,"' AND period.end_date <= '",l_arr_rec_period[l_arr_size].end_date,"'"
						ELSE
							LET p_where_text = " 1!=1" 
						END IF
					END IF
				END IF 

		END INPUT 
	END WHILE 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	CALL l_arr_rec_period.CLEAR()
	CLEAR FORM
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION GZA_get_info
############################################################

############################################################
# FUNCTION GZA_create_fiscal_year()
#
# Create Fiscal Year and Periods automatically
############################################################
FUNCTION GZA_create_fiscal_year()
 	DEFINE r_where_text STRING

	OPEN WINDOW G591 WITH FORM "G591" ATTRIBUTE(BORDER) 

#	CALL fgl_list_insert("type_period",1,"Day")    # If you use periods of one "Day", you will need to remove the comment (albo)
	CALL fgl_list_insert("type_period",2,"Month")
	CALL fgl_list_insert("type_period",3,"Quarter")	
	CALL fgl_list_insert("type_period",4,"Year")
	CALL fgl_list_insert("type_period",5,"Custom")

	LET modu_start_date_fiscal_year = NULL
	LET modu_type_period = NULL

	# The start date of the next Fiscal Year (by default).
	SELECT MAX(period.end_date) + 1 INTO modu_start_date_fiscal_year
	FROM period
	WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	INPUT modu_start_date_fiscal_year,modu_type_period WITHOUT DEFAULTS FROM start_date_fisc_year,type_period   
	
	CLOSE WINDOW G591

	IF int_flag = 1 OR quit_flag = 1 THEN # "Cancel" ACTION activated 
		LET modu_type_period = NULL
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET modu_start_date_fiscal_year = NULL
		LET r_where_text = NULL 
		RETURN r_where_text
	END IF        

	CASE 
		WHEN 
			modu_type_period = "Day"     OR 
			modu_type_period = "Month"   OR
			modu_type_period = "Quarter" OR
			modu_type_period = "Year"    OR
			modu_type_period = "Custom"
			# Creating Fiscal Year Periods automatically.
			CALL create_fiscal_year_periods(modu_start_date_fiscal_year,modu_type_period)RETURNING r_where_text 
		OTHERWISE 
			LET modu_type_period = NULL
			LET modu_start_date_fiscal_year = NULL
			LET r_where_text = NULL
	END CASE

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
   RETURN r_where_text
END FUNCTION
############################################################
# END FUNCTION GZA_create_fiscal_year() 
############################################################

############################################################
# FUNCTION create_fiscal_year_periods(p_start_date_fiscal_year,p_type_period)
#
# Creating Fiscal Year Periods automatically.
############################################################
FUNCTION create_fiscal_year_periods(p_start_date_fiscal_year,p_type_period)
	DEFINE p_start_date_fiscal_year DATE          # Start date of Fiscal Year
   DEFINE p_type_period CHAR(8)                  # Type of Period
	DEFINE l_fiscal_year_num LIKE period.year_num # Fiscal Year number 
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF RECORD LIKE period.*
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_err_message STRING
	DEFINE l_arr_size INTEGER
	DEFINE l_total_number_periods INTEGER         # Total number of Periods in the Fiscal Year
	DEFINE l_units_month INTEGER                  # Number of months in one Period
	DEFINE l_units_day INTEGER
	DEFINE l_cnt INTEGER
	DEFINE r_where_text STRING
	DEFINE i SMALLINT

	CASE 
		WHEN p_type_period = "Day" 
			# The duration of the Period is one day. The Fiscal Year contains 365/366 Periods.
			LET l_units_month = 0
			LET l_total_number_periods = number_days_year(p_start_date_fiscal_year)
			LET l_units_day = 0
		WHEN p_type_period = "Month"
			# The duration of the Period is one month. The Fiscal Year contains 12 Periods.
			LET l_units_month = 1
			LET l_total_number_periods = 12
			LET l_units_day = 1
		WHEN p_type_period = "Quarter"
			# The duration of the Period is one quarter. The Fiscal Year contains 4 Periods.
			LET l_units_month = 3
			LET l_total_number_periods = 4
			LET l_units_day = 1
		WHEN p_type_period = "Year" 
			# The duration of the Period is one year. The Fiscal Year contains 1 Period.
			LET l_units_month = 12
			LET l_total_number_periods = 1
			LET l_units_day = 1
		WHEN p_type_period = "Custom"
			# Creating a fiscal year manually by the user.
			LET l_units_month = 0
			LET l_total_number_periods = 1
			LET l_units_day = 0
		OTHERWISE 
			RETURN NULL
	END CASE

	LET l_rec_period.start_date = p_start_date_fiscal_year 
	LET l_fiscal_year_num = YEAR(p_start_date_fiscal_year)
	CALL l_arr_rec_period.CLEAR()

	FOR i = 1 TO l_total_number_periods
		LET l_arr_rec_period[i].cmpy_code = glob_rec_kandoouser.cmpy_code
		LET l_arr_rec_period[i].year_num  = YEAR(l_rec_period.start_date)
		LET l_arr_rec_period[i].period_num = i
		LET l_arr_rec_period[i].start_date = l_rec_period.start_date 		
		WHENEVER ANY ERROR CONTINUE
		LET l_rec_period.end_date = l_rec_period.start_date + l_units_month UNITS MONTH - l_units_day UNITS DAY
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF STATUS <> 0 THEN 
			LET l_err_message = "From the date ",p_start_date_fiscal_year," it is impossible to create automatically Fiscal Year. Create a Fiscal Year manually please." 
			CALL msgerror("",l_err_message)
			RETURN NULL
		END IF 
		LET l_arr_rec_period[i].end_date =	l_rec_period.end_date	 
		LET l_rec_period.start_date = l_rec_period.end_date + 1 UNITS DAY
		LET l_arr_rec_period[i].gl_flag = "Y" 
		LET l_arr_rec_period[i].ar_flag = "Y" 
		LET l_arr_rec_period[i].ap_flag = "Y" 
		LET l_arr_rec_period[i].pu_flag = "Y" 
		LET l_arr_rec_period[i].in_flag = "Y" 
		LET l_arr_rec_period[i].jm_flag = "Y" 
		LET l_arr_rec_period[i].oe_flag = "Y" 
	END FOR

	LET l_arr_size = l_arr_rec_period.GETSIZE()

	# Checking for the existence in the database of the Fiscal Year with same Periods.
	SELECT COUNT(*) INTO l_cnt 
	FROM period
	WHERE period.cmpy_code   = glob_rec_kandoouser.cmpy_code  AND
			period.end_date   >= l_arr_rec_period[1].start_date AND
			period.start_date <= l_arr_rec_period[l_arr_size].end_date
	IF l_cnt <> 0 THEN 
		DECLARE c_period_3 CURSOR FOR 
		SELECT UNIQUE period.year_num 
		FROM period 
		WHERE period.cmpy_code   = glob_rec_kandoouser.cmpy_code  AND
				period.end_date   >= l_arr_rec_period[1].start_date AND
				period.start_date <= l_arr_rec_period[l_arr_size].end_date
 		OPEN c_period_3
 		FETCH c_period_3 INTO l_fiscal_year_num
 		CLOSE c_period_3
		LET l_err_message =  ".                          !!! WARNING !!!", 
--		                     "\nFiscal Year ",l_fiscal_year_num USING "<<<<&"," with the same Periods already exists.",
		                     "\nThe Periods of the Fiscal Year that you create overlap with the Periods of existing ",l_fiscal_year_num USING "<<<<&"," Fiscal Year.",
									"\nFirst delete the existing Fiscal Year and then re-create it."  
		CALL msgerror("",l_err_message)
		RETURN NULL
	END IF

	IF p_type_period = "Custom" THEN 
		LET r_where_text = " 1!=1"
		RETURN r_where_text
	END IF

	BEGIN WORK
--	EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
	FOR i = 1 TO l_arr_size
		LET l_arr_rec_period[i].year_num = l_fiscal_year_num 
		LET l_rec_period.* = l_arr_rec_period[i].* 
		INSERT INTO period VALUES(l_rec_period.*)
	END FOR
	# This function checks that the sum of all days of each period gives 365 or 366 days 
	# except for first fiscal year of the company 
	IF check_fiscal_year_integrity(l_fiscal_year_num) THEN	
		# If the 'fiscalyear' table will be used, then remove the Comments !!!
--		DELETE FROM fiscalyear 
--		WHERE fiscalyear.cmpy_code = glob_rec_kandoouser.cmpy_code
--		AND fiscalyear.year_num = l_fiscal_year_num
--		INSERT INTO fiscalyear VALUES (glob_rec_kandoouser.cmpy_code,l_fiscal_year_num,l_arr_rec_period[1].start_date,l_arr_rec_period[l_arr_size].end_date)
		COMMIT WORK
	ELSE
		ROLLBACK WORK
		LET l_err_message = "The ",l_fiscal_year_num USING "<<<<&"," Fiscal Year does not contain the right number of days!"
		CALL msgerror("",l_err_message)
		RETURN NULL
	END IF

	LET r_where_text = "period.start_date >= '",l_arr_rec_period[1].start_date,"' AND period.end_date <= '",l_arr_rec_period[l_arr_size].end_date,"'"

	RETURN r_where_text
END FUNCTION
############################################################
# END FUNCTION create_fiscal_year_periods() 
############################################################

############################################################
# FUNCTION number_days_year(p_year)
#
# Counting the number of days in a year.
############################################################
FUNCTION number_days_year(p_year)
	DEFINE p_year DATE
	DEFINE r_number_days INTEGER

	IF YEAR(p_year) MOD 4 = 0 THEN 
		IF (YEAR(p_year) MOD 100 = 0) AND (YEAR(p_year) MOD 400 <> 0) THEN 
			LET r_number_days = 365
		ELSE 
			LET r_number_days = 366
		END IF
	ELSE 
		LET r_number_days = 365
	END IF

	RETURN r_number_days
END FUNCTION
############################################################
# END FUNCTION number_days_year(p_year)() 
############################################################

############################################################
# FUNCTION get_type_period(p_period_num,p_start_date,p_end_date)
#
# Function returns the type of the Fiscal period.
############################################################
FUNCTION get_type_period(p_period_num,p_start_date,p_end_date)
	DEFINE p_period_num LIKE period.period_num
	DEFINE p_start_date LIKE period.start_date 
	DEFINE p_end_date LIKE period.end_date 
	DEFINE l_num_days_period INTEGER  
	DEFINE r_type_period CHAR(20)

	IF p_period_num IS NULL OR
		p_start_date IS NULL OR
		p_end_date IS NULL THEN 
		RETURN NULL
	END IF

	# Number of days in the fiscal period
	LET l_num_days_period = p_end_date - p_start_date	+ 1
 
	CASE 
		WHEN l_num_days_period = 1 
			# The fiscal period is Day
			LET r_type_period = "Day"
		WHEN l_num_days_period >= 28 AND l_num_days_period <= 31 
			# The fiscal period is Month
			CASE
				WHEN MONTH(p_start_date) = 1
					IF l_num_days_period = 31 THEN LET r_type_period = "January" END IF 
				WHEN MONTH(p_start_date) = 2
					IF number_days_year(p_start_date) = 365 AND l_num_days_period = 28 THEN LET r_type_period = "February"  END IF
					IF number_days_year(p_start_date) = 366 AND l_num_days_period = 29 THEN LET r_type_period = "February"  END IF
				WHEN MONTH(p_start_date) = 3
					IF l_num_days_period = 31 THEN LET r_type_period = "March" END IF 
				WHEN MONTH(p_start_date) = 4
					IF l_num_days_period = 30 THEN LET r_type_period = "April" END IF 
				WHEN MONTH(p_start_date) = 5
					IF l_num_days_period = 31 THEN LET r_type_period = "May" END IF 
				WHEN MONTH(p_start_date) = 6
					IF l_num_days_period = 30 THEN LET r_type_period = "June" END IF 
				WHEN MONTH(p_start_date) = 7
					IF l_num_days_period = 31 THEN LET r_type_period = "July" END IF 
				WHEN MONTH(p_start_date) = 8
					IF l_num_days_period = 31 THEN LET r_type_period = "August" END IF 
				WHEN MONTH(p_start_date) = 9
					IF l_num_days_period = 30 THEN LET r_type_period = "September" END IF 
				WHEN MONTH(p_start_date) = 10
					IF l_num_days_period = 31 THEN LET r_type_period = "October" END IF 
				WHEN MONTH(p_start_date) = 11
					IF l_num_days_period = 30 THEN LET r_type_period = "November" END IF 
				WHEN MONTH(p_start_date) = 12
					IF l_num_days_period = 31 THEN LET r_type_period = "December" END IF 
				OTHERWISE
					LET r_type_period = NULL
			END CASE
		WHEN l_num_days_period >= 90 AND l_num_days_period <= 92 
			# The fiscal period is Quarter
--			LET r_type_period = "Q",p_period_num USING "<<<<<<"
			CASE
				WHEN p_period_num = 1
					LET r_type_period = "1st Quarter" 
				WHEN p_period_num = 2
					LET r_type_period = "2nd Quarter" 
				WHEN p_period_num = 3
					LET r_type_period = "3rd Quarter" 
				WHEN p_period_num = 4
					LET r_type_period = "4th Quarter" 
				OTHERWISE
					LET r_type_period = p_period_num USING "<<<<<<","th Quarter"
			END CASE
		WHEN l_num_days_period >= 365 AND l_num_days_period <= 366 
			# The fiscal period is Year
			LET r_type_period = "Year"
		OTHERWISE 
			LET r_type_period = NULL 
	END CASE  

	RETURN r_type_period
END FUNCTION
############################################################
# END FUNCTION get_type_period() 
############################################################

############################################################
# FUNCTION GZA_delete_fiscal_year()
#
# Deleting Fiscal Year and it's periods automatically.
############################################################
FUNCTION GZA_delete_fiscal_year()
 	DEFINE r_where_text STRING 
	DEFINE l_year_num LIKE period.year_num
	DEFINE l_arr_year_num DYNAMIC ARRAY OF LIKE period.year_num 
	DEFINE i INTEGER
	DEFINE w UI.WINDOW 

	OPEN WINDOW g590 WITH FORM "G590" ATTRIBUTE(BORDER) 

	LET w = UI.WINDOW.ForName("G590") 

	# Initialization of 'l_arr_year_num' array
	DECLARE c_period_2 CURSOR FOR 
	SELECT UNIQUE period.year_num 
	FROM period 
	WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY period.year_num

	LET i = 0
	FOREACH c_period_2 INTO l_year_num
		LET i = i + 1
		LET l_arr_year_num[i] = l_year_num
	END FOREACH

	IF i = 0 THEN 
		CLOSE WINDOW g590
		CALL msgerror("","Data not found !")
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET r_where_text = NULL 
		RETURN r_where_text
	END IF

	DISPLAY ARRAY l_arr_year_num TO sr_year_num.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZA","fiscalYearList_1") 
			CALL dialog.setActionHidden("FIND",TRUE)
			CALL w.settext("Delete Fiscal Year") 

		AFTER DISPLAY 
			LET l_year_num = l_arr_year_num[arr_curr()]  

	END DISPLAY 
	CLOSE WINDOW g590

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET r_where_text = NULL 
		RETURN r_where_text
	END IF

	LET r_where_text = "period.year_num = ",l_year_num USING "<<<<&"

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
   RETURN r_where_text

END FUNCTION
############################################################
# END FUNCTION GZA_delete_fiscal_year()
############################################################

############################################################
# FUNCTION check_accounts_fiscal_year_periods()
# Checking the existence of accounts in all tables that refer
# to the 'period' table with by Foreign Key.
############################################################
FUNCTION check_accounts_fiscal_year_periods(p_year_num,p_period_num)
	DEFINE p_year_num LIKE period.year_num
	DEFINE p_period_num LIKE period.period_num
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_cnt INTEGER
	DEFINE l_total_cnt INTEGER	

	IF p_year_num IS NULL THEN
		RETURN 0 
	END IF 

	IF p_period_num IS NULL THEN
		LET l_where_text = " AND year_num = ",p_year_num USING "<<<<&"
   ELSE 
   	LET l_where_text = " AND year_num = ",p_year_num USING "<<<<&"," AND period_num = ",p_period_num USING "<<<<&" 
	END IF

	LET l_total_cnt = 0
	# Checking the availability of accounts in the 'accounthist' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM accounthist ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_0 FROM l_query_text
	DECLARE c_query_text_0 CURSOR FOR p_query_text_0
	OPEN c_query_text_0 FETCH c_query_text_0 INTO l_cnt CLOSE c_query_text_0      
	LET l_total_cnt = l_total_cnt + l_cnt  

	# Checking the availability of accounts in the 'accounthistcur' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM accounthistcur ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_1 FROM l_query_text
	DECLARE c_query_text_1 CURSOR FOR p_query_text_1
	OPEN c_query_text_1 FETCH c_query_text_1 INTO l_cnt CLOSE c_query_text_1      
	LET l_total_cnt = l_total_cnt + l_cnt

	# Checking the availability of accounts in the 'accountledger' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM accountledger ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_2 FROM l_query_text
	DECLARE c_query_text_2 CURSOR FOR p_query_text_2
	OPEN c_query_text_2 FETCH c_query_text_2 INTO l_cnt CLOSE c_query_text_2      
	LET l_total_cnt = l_total_cnt + l_cnt

	# Checking the availability of accounts in the 'bankstatement' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM bankstatement ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_3 FROM l_query_text
	DECLARE c_query_text_3 CURSOR FOR p_query_text_3
	OPEN c_query_text_3 FETCH c_query_text_3 INTO l_cnt CLOSE c_query_text_3      
	LET l_total_cnt = l_total_cnt + l_cnt

	# Checking the availability of accounts in the 'driverledger' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM driverledger ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_4 FROM l_query_text
	DECLARE c_query_text_4 CURSOR FOR p_query_text_4
	OPEN c_query_text_4 FETCH c_query_text_4 INTO l_cnt CLOSE c_query_text_4      
	LET l_total_cnt = l_total_cnt + l_cnt

	# Checking the availability of accounts in the 'postpurchase' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM postpurchase ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_5 FROM l_query_text
	DECLARE c_query_text_5 CURSOR FOR p_query_text_5
	OPEN c_query_text_5 FETCH c_query_text_5 INTO l_cnt CLOSE c_query_text_5      
	LET l_total_cnt = l_total_cnt + l_cnt

	# Checking the availability of accounts in the 'prodledg' table
	LET l_query_text = 
	"SELECT COUNT(*) FROM prodledg ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"'",l_where_text	 
	PREPARE p_query_text_6 FROM l_query_text
	DECLARE c_query_text_6 CURSOR FOR p_query_text_6
	OPEN c_query_text_6 FETCH c_query_text_6 INTO l_cnt CLOSE c_query_text_6      
	LET l_total_cnt = l_total_cnt + l_cnt

	RETURN l_total_cnt

END FUNCTION
############################################################
# END FUNCTION check_accounts_fiscal_year_periods()
############################################################

############################################################
# FUNCTION check_fiscal_year_integrity(p_fiscal_year_num)
# This function checks whether the sum of durations of all the 
# fiscal year period are 365 or 366, except for first year of the company's life
############################################################
FUNCTION check_fiscal_year_integrity(p_fiscal_year_num)
	DEFINE p_fiscal_year_num SMALLINT     # Fiscal Year
	DEFINE l_start_date_fiscal_year DATE  # Fiscal Year Start Date
	DEFINE first_year_num SMALLINT        # First year of the company's life
	DEFINE l_year_num SMALLINT
	DEFINE l_total_days SMALLINT

	# identify the first year of all the company's fiscal years, which can be more or less than 365 days
	SELECT YEAR(company.legal_creation_date)
	INTO first_year_num
	FROM company
	WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code
	IF STATUS = NOTFOUND THEN
		LET first_year_num = 1899
	END IF

	IF p_fiscal_year_num > first_year_num THEN
		SELECT period.year_num,SUM(period.end_date-period.start_date+1) 
		INTO l_year_num,l_total_days
		FROM period 
		WHERE period.cmpy_code =  glob_rec_kandoouser.cmpy_code
		AND period.year_num = p_fiscal_year_num
		GROUP BY period.year_num
		IF STATUS = NOTFOUND THEN
			RETURN NULL # There is nothing to check
		ELSE
			IF l_total_days < 365 OR l_total_days > 366 THEN
				RETURN 0 # not 365/366 days for after 1 year
			ELSE
				RETURN 1	# fits the number of days
			END IF
		END IF
	ELSE
		RETURN 2 	   # Does not have the right number of days but it's the first year, then allowed to
	END IF

END FUNCTION
############################################################
# END FUNCTION check_fiscal_year_integrity()
############################################################
