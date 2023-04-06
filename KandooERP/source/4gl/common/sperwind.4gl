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

###########################################################################
# FUNCTION salesperson_inq(p_cmpy,p_sale_code) 
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY details WHEN doing a
#           salesperson inquiry.
###########################################################################
FUNCTION salesperson_inq(p_cmpy,p_sale_code) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_spermenu ARRAY[20] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_idx,l_scrn SMALLINT
	DEFINE i SMALLINT	 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1"

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*
 
	IF status = 0 THEN 
		FOR i = 1 TO 20 
			CASE i 
				WHEN "1" ## general details 
					LET l_idx = 1 
					LET l_arr_spermenu[l_idx].option_num = "1" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind",i) 
				WHEN "2" ## daily sales 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "2" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind",i) 
				WHEN "3" ## monthly sales 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "3" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind",i) 
				WHEN "4" ## monthly turnover 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "4" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","4") 
				WHEN "5" ## week turnover vs sales target 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "5" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","5") 
				WHEN "6" ## monthly turnover vs sales target 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "6" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","6") 
				WHEN "7" ## special offers 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "7" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","7") 
				WHEN "8" ## distribution 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "8" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","8") 
				WHEN "9" ## profit figures 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "9" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","9") 
				WHEN "10" ## commission 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "A" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","A") 
				WHEN "11" ## sales structures 
					LET l_idx = l_idx + 1 
					LET l_arr_spermenu[l_idx].option_num = "B" 
					LET l_arr_spermenu[l_idx].option_text = kandooword("sperwind","B") 
				OTHERWISE 
					EXIT FOR 
			END CASE 
		END FOR 

		OPEN WINDOW E183 with FORM "E183" 
		CALL windecoration_e("E183") -- albo kd-755 

		DISPLAY BY NAME 
			l_rec_salesperson.sale_code, 
			l_rec_salesperson.name_text 

		 
		LET l_msgresp=kandoomsg("E",1078,"") 
		DISPLAY ARRAY l_arr_spermenu TO sr_spermenu.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","sperwind","input-arr-sperwind") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION ("ACCEPT","DOUBLECLICK")	--BEFORE FIELD option_num 
				IF l_arr_spermenu[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_spermenu[l_idx].scroll_flag = l_arr_spermenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_arr_spermenu[l_idx].scroll_flag IS NOT null) 
						IF l_arr_spermenu[i].option_num IS NULL THEN 
							LET l_arr_spermenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_arr_spermenu[l_idx].scroll_flag= 
							l_arr_spermenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 
				END IF 

				CASE l_arr_spermenu[l_idx].scroll_flag 
					WHEN "1" ## general details 
						CALL sper_detls(p_cmpy,p_sale_code) 

					WHEN "2" ## daily sales figures 
						CALL run_prog("EC2",p_sale_code,"","","") 

					WHEN "3" ## monthly sales figures 
						CALL run_prog("EC3",p_sale_code,"","","") 

					WHEN "4" ## monthly turnover 
						CALL run_prog("EC4",p_sale_code,"","","") 

					WHEN "5" ## weekly turnover vs sales targets 
						CALL run_prog("EC5",p_sale_code,"","","") 

					WHEN "6" ## monthly turnover vs sales targets 
						CALL run_prog("EC6",p_sale_code,"","","") 

					WHEN "7" ## special offers 
						CALL run_prog("EC7",p_sale_code,"","","") 

					WHEN "8" ## monthly distribution 
						CALL run_prog("EC8",p_sale_code,"","","") 

					WHEN "9" ## profit figures 
						CALL run_prog("EC9",p_sale_code,"","","") 

					WHEN "A" ## commission 
						CALL run_prog("ECA",p_sale_code,"","","") 

					WHEN "B" ## sales structures 
						#CALL sper_structure(p_cmpy,p_sale_code)
						ERROR kandoomsg2("U",9923,"") 
						#9923 "This option has NOT been implemented"
				END CASE 

				LET l_arr_spermenu[l_idx].scroll_flag = NULL 


		END DISPLAY 
		CLOSE WINDOW E183 

	END IF 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
###########################################################################
# END FUNCTION salesperson_inq(p_cmpy,p_sale_code) 
###########################################################################