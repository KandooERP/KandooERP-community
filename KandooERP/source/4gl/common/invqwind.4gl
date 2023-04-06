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
# Requires
# common/orhdwind.4gl
# common/orddfunc.4gl
# common/inhdwind.4gl
# common/unapply_pay.4gl
###########################################################################

###########################################################################
# \brief module - invqwind.4gl
#
# Purpose - Invoice Inquiry with following OPTIONS
#           1. General Details
#           2. Entry Info
#           3. Line Items
#           4. Customer Notes
#           5. Orders
#           6. Payments
#           7. Shipping Info
#           8. Story
#           9. Other Info
#
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  

########################################################################
# FUNCTION invqwind( p_cmpy, p_inv_num )
########################################################################
FUNCTION invqwind(p_cmpy,p_inv_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_wa213 SMALLINT
	DEFINE l_rec_invmenu ARRAY[20] OF RECORD 
				scroll_flag CHAR(1), 
				option_num CHAR(1), 
				option_text CHAR(30) 
			 END RECORD 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_paid_amt LIKE invoicehead.paid_amt 
	DEFINE l_func_type CHAR(14) 
	DEFINE l_idx SMALLINT 
	DEFINE l_run_arg STRING #for forming the RUN url argument
   DEFINE i SMALLINT 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("A",9107,"") 	#A9107 AP Parameters NOT SET up - Refer menu AZP
		RETURN 
	END IF 

	SELECT * INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 

	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("A",7048,p_inv_num)		#7048 Logic Error: Invoice does NOT exist
		RETURN 
	ELSE 



		FOR i = 1 TO 9 
			CASE i 
				WHEN "1" ## general details 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "1" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'1') 
				WHEN "2" ## entry info 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "2" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'2') 
				WHEN "3" ## line items 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "3" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'3') 
				WHEN "4" ## customer notes 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "4" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'4') 
				WHEN "5" ## orders 
					IF l_rec_invoicehead.ord_num IS NOT NULL 
					AND l_rec_invoicehead.ord_num != 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_rec_invmenu[l_idx].option_num = "5" 
						LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'5') 
					END IF 
				WHEN "6" ## payments 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "6" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'6') 
				WHEN "7" ## shipping info 
					LET l_idx = l_idx + 1 
					LET l_rec_invmenu[l_idx].option_num = "7" 
					LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'7') 
				WHEN "8" ## story 
					SELECT unique 1 FROM invstory 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_invoicehead.cust_code 
					AND inv_num = p_inv_num 
					IF sqlca.sqlcode = 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_rec_invmenu[l_idx].option_num = "8" 
						LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'8') 
					END IF 
				WHEN "9" ## other info 
					IF l_rec_company.module_text[23] = "W" THEN 
						SELECT unique 1 FROM invheadext 
						WHERE inv_num = p_inv_num 
						AND cust_code = l_rec_invoicehead.cust_code 
						AND cmpy_code = p_cmpy 
						IF sqlca.sqlcode = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_rec_invmenu[l_idx].option_num = "9" 
							LET l_rec_invmenu[l_idx].option_text = kandooword("invqwind",'9') 
						END IF 
					END IF 
			END CASE 
		END FOR 

		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_invoicehead.cust_code 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("A",9067,"") 
			#A9067 Logic Error: Customer does NOT exist
			RETURN 
		END IF 
		IF l_wa213 < 1 THEN 
			LET l_wa213 = l_wa213 + 1 
			CALL open_window( 'A213', l_wa213 ) 
		ELSE 
			LET l_msgresp = kandoomsg("U",9917,"") 
			#9917 Window IS already OPEN
			RETURN 
		END IF 

		DISPLAY BY NAME l_rec_invoicehead.inv_num, 
		l_rec_invoicehead.cust_code, 
		l_rec_customer.name_text 

		CALL set_count(l_idx) 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		LET l_msgresp=kandoomsg("A",1030,"") 
		#A1030 RETURN TO SELECT Option
		#INPUT ARRAY l_rec_invmenu WITHOUT DEFAULTS FROM sr_invmenu.* ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY l_rec_invmenu TO sr_invmenu.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","invqwind","input-arr-invmenu") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				# DISPLAY l_rec_invmenu[l_idx].*
				#     TO sr_invmenu[scrn].*

				#         AFTER FIELD scroll_flag
				#            IF fgl_lastkey() = fgl_keyval("accept")
				#            AND fgl_fglgui() THEN
				#               NEXT FIELD option_num
				#            END IF
				#
				#            IF l_rec_invmenu[l_idx].scroll_flag IS NULL THEN
				#               IF fgl_lastkey() = fgl_keyval("down")
				#               AND arr_curr() = arr_count() THEN
				#                  LET l_msgresp=kandoomsg("A",9001,"")
				#                  #A9001 No more rows in the direction ...
				#                  NEXT FIELD scroll_flag
				#               END IF
				#            END IF

			ON ACTION ("doubleclick") 
				#	NEXT FIELD option_num
				#
				# BEFORE FIELD option_num
				IF l_rec_invmenu[l_idx].scroll_flag IS NULL THEN 
					LET l_rec_invmenu[l_idx].scroll_flag = l_rec_invmenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_rec_invmenu[l_idx].scroll_flag IS NOT null) 
						IF l_rec_invmenu[i].option_num IS NULL THEN 
							LET l_rec_invmenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_rec_invmenu[l_idx].scroll_flag= 
							l_rec_invmenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 

				END IF 

				CASE l_rec_invmenu[l_idx].scroll_flag 
					WHEN "1" 
						CALL disc_per_head(p_cmpy,l_rec_invoicehead.cust_code,p_inv_num) 
					WHEN "2" 
						CALL show_inv_entry(p_cmpy,p_inv_num) 
					WHEN "3" 
						CALL lineshow( p_cmpy, 
						l_rec_invoicehead.cust_code, 
						p_inv_num, 
						l_func_type) 
					WHEN "4" 
						LET l_run_arg = "CUSTOMER_CODE=", trim(l_rec_invoicehead.cust_code) 
						CALL run_prog("A13",l_run_arg,"","","") #customer notes filter 

					WHEN "5" 
						IF l_rec_company.module_text[23] = "W" THEN 
							CALL run_prog("W15",l_rec_invoicehead.ord_num,"","","") 
						ELSE 
							CALL lordshow( 
								p_cmpy, 
								l_rec_invoicehead.cust_code, 
								l_rec_invoicehead.ord_num, 
								'') 
						END IF 
					WHEN "6" 
						LET l_paid_amt = unapply_pay( p_cmpy, l_rec_invoicehead.cust_code, 
						p_inv_num ) 
					WHEN "7" 
						CALL show_inv_ship(p_cmpy, p_inv_num) 
					WHEN "8" 
						CALL inv_story(p_cmpy,l_rec_invoicehead.cust_code,p_inv_num) 
					WHEN "9" 
						CALL inv_other(p_cmpy,l_rec_invoicehead.cust_code,p_inv_num) 
				END CASE 

				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 

				LET l_rec_invmenu[l_idx].scroll_flag = NULL 
				#NEXT FIELD scroll_flag

				#AFTER ROW
				#   DISPLAY l_rec_invmenu[l_idx].*
				#        TO sr_invmenu[scrn].*

		END DISPLAY 
		###############################

		CALL close_win( 'a213', l_wa213 ) 
		LET l_wa213 = l_wa213 - 1 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


########################################################################
# FUNCTION open_window( p_window, p_win_cnt )
########################################################################
FUNCTION open_window(p_window,p_win_cnt) 
	DEFINE p_window STRING 
	DEFINE p_win_cnt SMALLINT 
--	DISPLAY "@DebugInf: open_window() p_window=", p_window CLIPPED, " p_win_cnt=", p_win_cnt CLIPPED -- albo
	WHENEVER ERROR CONTINUE  #this entire window handler needs to be changed
	
	LET p_window = p_window.touppercase() -- albo
	CASE p_window 
		WHEN "A134" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a134 with FORM "A134" 
					CALL windecoration_a("A134") 
				WHEN 2 
					OPEN WINDOW w2_a134 with FORM "A134" 
					CALL windecoration_a("A134") 
				WHEN 3 
					OPEN WINDOW w3_a134 with FORM "A134" 
					CALL windecoration_a("A134") 
			END CASE 

		WHEN "A213" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a213 with FORM "A213" 
					CALL windecoration_a("A213") 
				WHEN 2 
					OPEN WINDOW w2_a213 with FORM "A213" 
					CALL windecoration_a("A213") 

				WHEN 3 
					OPEN WINDOW w3_a213 with FORM "A213" 
					CALL windecoration_a("A213") 

			END CASE 

		WHEN "A152" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a152 with FORM "A152" 
					CALL windecoration_a("A152") 

				WHEN 2 
					OPEN WINDOW w2_a152 with FORM "A152" 
					CALL windecoration_a("A152") 

				WHEN 3 
					OPEN WINDOW w3_a152 with FORM "A152" 
					CALL windecoration_a("A152") 

			END CASE 

		WHEN "A148" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a148 with FORM "A148" 
					CALL windecoration_a("A148") 

				WHEN 2 
					OPEN WINDOW w2_a148 with FORM "A148" 
					CALL windecoration_a("A148") 
				WHEN 3 
					OPEN WINDOW w3_a148 with FORM "A148" 
					CALL windecoration_a("A148") 
			END CASE 

		WHEN "W1" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_w1 with FORM "U999" 
					CALL windecoration_u("U999") 
				WHEN 2 
					OPEN WINDOW w2_w1 with FORM "U999" 
					CALL windecoration_u("U999") 
				WHEN 3 
					OPEN WINDOW w3_w1 with FORM "U999" 
					CALL windecoration_u("U999") 
			END CASE 

		WHEN "A136" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a136 with FORM "A136" 
					CALL windecoration_a("A136") 
				WHEN 2 
					OPEN WINDOW w2_a136 with FORM "A136" 
					CALL windecoration_a("A136") 
				WHEN 3 
					OPEN WINDOW w3_a136 with FORM "A136" 
					CALL windecoration_a("A136") 
			END CASE 

		WHEN "A630" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a630 with FORM "A630" 
					CALL windecoration_a("A630") 
				WHEN 2 
					OPEN WINDOW w2_a630 with FORM "A630" 
					CALL windecoration_a("A630") 
				WHEN 3 
					OPEN WINDOW w3_a630 with FORM "A630" 
					CALL windecoration_a("A630") 
			END CASE 

		WHEN "A144" 
			CASE p_win_cnt 
				WHEN 1 
					OPEN WINDOW w1_a144 with FORM "A144" 
					CALL windecoration_a("A144") 
				WHEN 2 
					OPEN WINDOW w2_a144 with FORM "A144" 
					CALL windecoration_a("A144") 
				WHEN 3 
					OPEN WINDOW w3_a144 with FORM "A144" 
					CALL windecoration_a("A144") 
			END CASE 
	END CASE 
	
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
END FUNCTION 


########################################################################
# FUNCTION close_win( p_window, p_win_cnt )
########################################################################
FUNCTION close_win(p_window,p_win_cnt) 
	DEFINE p_window STRING 
	DEFINE p_win_cnt SMALLINT 
--	DISPLAY "@DebugInf: close_window() p_window=", p_window CLIPPED, " p_win_cnt=", p_win_cnt CLIPPED -- albo
	WHENEVER ERROR CONTINUE
	LET p_window = p_window.touppercase() -- albo
	CASE p_window 
		WHEN "A134" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a134 
				WHEN 2 
					CLOSE WINDOW w2_a134 
				WHEN 3 
					CLOSE WINDOW w3_a134 
			END CASE 

		WHEN "A213" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a213 
				WHEN 2 
					CLOSE WINDOW w2_a213 
				WHEN 3 
					CLOSE WINDOW w3_a213 
			END CASE 

		WHEN "A152" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a152 
				WHEN 2 
					CLOSE WINDOW w2_a152 
				WHEN 3 
					CLOSE WINDOW w3_a152 
			END CASE 

		WHEN "A148" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a148 
				WHEN 2 
					CLOSE WINDOW w2_a148 
				WHEN 3 
					CLOSE WINDOW w3_a148 
			END CASE 

		WHEN "W1" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_w1 
				WHEN 2 
					CLOSE WINDOW w2_w1 
				WHEN 3 
					CLOSE WINDOW w3_w1 
			END CASE 

		WHEN "A136" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a136 
				WHEN 2 
					CLOSE WINDOW w2_a136 
				WHEN 3 
					CLOSE WINDOW w3_a136 
			END CASE 

		WHEN "A144" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a144 
				WHEN 2 
					CLOSE WINDOW w2_a144 
				WHEN 3 
					CLOSE WINDOW w3_a144 
			END CASE 

		WHEN "A630" 
			CASE p_win_cnt 
				WHEN 1 
					CLOSE WINDOW w1_a630 
				WHEN 2 
					CLOSE WINDOW w2_a630 
				WHEN 3 
					CLOSE WINDOW w3_a630 
			END CASE 
	END CASE 
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION 
