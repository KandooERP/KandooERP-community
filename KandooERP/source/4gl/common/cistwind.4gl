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
# \brief module - cistwind.4gl
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY statistical details
#           WHEN doing a customer inquiry.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

##################################################################################
# FUNCTION cust_stats(p_cmpy,p_cust_code)
#
#
##################################################################################
FUNCTION cust_stats(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
   DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_arr_custmenu ARRAY[9] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_overdue LIKE customer.over1_amt 
	DEFINE l_baddue LIKE customer.over1_amt 
	DEFINE l_idx SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_run_arg STRING
	
	LET l_idx = 0 
	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF STATUS = 0 THEN 
		LET l_overdue = l_rec_customer.over1_amt 
		+ l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt 
		LET l_baddue = l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt 
		FOR l_idx = 1 TO 5 
			LET l_arr_custmenu[l_idx].option_num = l_idx 
			LET l_arr_custmenu[l_idx].option_text = kandooword("cistwind",l_idx) 
		END FOR 
		CALL set_count(5) 

		WHENEVER ERROR STOP
		
		WHENEVER ERROR CONTINUE #Alex K. reported window is already open bug
		OPEN WINDOW A165 with FORM "A165"		
		IF status != 0 THEN
			CURRENT WINDOW IS A165
		ELSE
			CALL windecoration_a("A165")
		END IF	 
		
		IF status > 0 THEN  #@alex k. reported error - window is already open
			CURRENT WINDOW IS A165
		END IF
				 

		DISPLAY l_rec_customer.cust_code TO cust_code
		DISPLAY l_rec_customer.name_text TO name_text 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		MESSAGE kandoomsg2("A",1030,"") 

		#INPUT ARRAY l_arr_custmenu WITHOUT DEFAULTS FROM sr_custmenu.*
		DISPLAY ARRAY l_arr_custmenu TO sr_custmenu.* ATTRIBUTE(UNBUFFERED) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				# DISPLAY l_arr_custmenu[l_idx].*
				#     TO sr_custmenu[scrn].*

				#AFTER FIELD scroll_flag
				#   --#IF fgl_lastkey() = fgl_keyval("accept")
				#   --#AND fgl_fglgui() THEN
				#   --#   NEXT FIELD option_num
				#   --#END IF
				#   IF l_arr_custmenu[l_idx].scroll_flag IS NULL THEN
				#      IF fgl_lastkey() = fgl_keyval("down")
				#      AND arr_curr() = arr_count() THEN
				#         ERROR kandoomsg2("A",9001,"")
				#         NEXT FIELD scroll_flag
				#      END IF
				#   END IF

			ON ACTION "ACCEPT" 
				#BEFORE FIELD option_num
				IF l_arr_custmenu[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_custmenu[l_idx].scroll_flag = l_arr_custmenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_arr_custmenu[l_idx].scroll_flag IS NOT null) 
						IF l_arr_custmenu[i].option_num IS NULL THEN 
							LET l_arr_custmenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_arr_custmenu[l_idx].scroll_flag= 
							l_arr_custmenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 
				END IF 


				LET l_run_arg = "CUSTOMER_CODE=",trim(p_cust_code)
				IF get_debug() = true THEN 
					DISPLAY "l_run_arg=", l_run_arg
				END IF 
				CASE l_arr_custmenu[l_idx].scroll_flag 
					WHEN "1" ## general details 
						CALL cinq_dets(p_cmpy,p_cust_code,l_overdue,l_baddue) 
					WHEN "2" ## turnover STATISTICS 
						CALL run_prog("EA2",l_run_arg,"","","") 
					WHEN "3" ## product/group STATISTICS 
						CALL run_prog("EA3",l_run_arg,"","","") 
					WHEN "4" ## product sales 
						CALL run_prog("EA4",l_run_arg,"","","") 
					WHEN "5" ## profit figures 
						CALL run_prog("EA5",l_run_arg,"","","") 
				END CASE 

				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				LET l_arr_custmenu[l_idx].scroll_flag = NULL 
				#NEXT FIELD scroll_flag

				#AFTER ROW
				#   DISPLAY l_arr_custmenu[l_idx].*
				#        TO sr_custmenu[scrn].*



		END DISPLAY 

		CLOSE WINDOW A165 

	END IF 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
##################################################################################
# END FUNCTION cust_stats(p_cmpy,p_cust_code)
##################################################################################