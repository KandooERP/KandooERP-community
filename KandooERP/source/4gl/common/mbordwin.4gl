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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - mbordwin.4gl
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY details WHEN doing a
#           ORDER inquiry.
#
GLOBALS "../common/glob_GLOBALS.4gl" 

#DEFINE l_msgresp LIKE language.yes_flag

FUNCTION ord_clnt(p_cmpy,p_order_num,p_hide_option) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_order_num LIKE ordhead.order_num 
	DEFINE p_hide_option SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_mbparms RECORD LIKE mbparms.* 
	DEFINE l_arr_ordmenu ARRAY[22] OF 
		RECORD 
			scroll_flag CHAR(1), 
			option_num CHAR(1), 
			option_text CHAR(30) 
		END RECORD 
	DEFINE l_idx,l_scrn,l_arr_size SMALLINT 
	DEFINE i SMALLINT

	SELECT * INTO l_rec_ordhead.* FROM ordhead 
	WHERE order_num = p_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_ordhead.cust_code 
	SELECT * INTO l_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = p_cmpy 
	#  p_hide_option removes OPTIONS FROM inquiry window IF called FROM Order Edit
	FOR i = 1 TO 23 
		CASE i 
			WHEN "1" ## general details 
				IF NOT p_hide_option THEN 
					LET l_idx = 1 
					LET l_arr_ordmenu[l_idx].option_num = "1" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
				END IF 
			WHEN "2" ## job address 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "2" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
			WHEN "3" ## additional info 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "3" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
			WHEN "4" ## ORDER LINES 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "4" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
			WHEN "5" ## ORDER status 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "5" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
			WHEN "6" ## CALL forwards 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "6" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
			WHEN "7" ## delivery details 
				IF l_rec_ordhead.last_del_num IS NOT NULL 
				AND l_rec_ordhead.last_del_num != 0 THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "7" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
				END IF 
			WHEN "8" ## delivery instr. 
				IF NOT p_hide_option THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "8" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
				END IF 
			WHEN "9" ## reporting codes 
				IF NOT p_hide_option THEN 
					IF l_rec_mbparms.ref1_text IS NOT NULL 
					OR l_rec_mbparms.ref2_text IS NOT NULL 
					OR l_rec_mbparms.ref3_text IS NOT NULL 
					OR l_rec_mbparms.ref4_text IS NOT NULL 
					OR l_rec_mbparms.ref5_text IS NOT NULL 
					OR l_rec_mbparms.ref6_text IS NOT NULL 
					OR l_rec_mbparms.ref7_text IS NOT NULL 
					OR l_rec_mbparms.ref8_text IS NOT NULL 
					OR l_rec_mbparms.flag1_ind matches "[YN]" 
					OR l_rec_mbparms.flag2_ind matches "[YN]" 
					OR l_rec_mbparms.flag3_ind matches "[YN]" 
					OR l_rec_mbparms.flag4_ind matches "[YN]" 
					OR l_rec_mbparms.flag5_ind matches "[YN]" 
					OR l_rec_mbparms.flag6_ind matches "[YN]" 
					OR l_rec_mbparms.flag7_ind matches "[YN]" 
					OR l_rec_mbparms.flag8_ind matches "[YN]" THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_ordmenu[l_idx].option_num = "9" 
						LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin",i) 
					END IF 
				END IF 
			WHEN "10" ## pallets 
				SELECT unique 1 FROM pallet 
				WHERE cust_code = l_rec_ordhead.cust_code 
				AND order_num = l_rec_ordhead.order_num 
				AND cmpy_code = p_cmpy 
				IF status != notfound THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "A" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","A") 
				END IF 
			WHEN "11" ## additional charges 
				SELECT unique 1 FROM orderline 
				WHERE cmpy_code = p_cmpy 
				AND order_num = l_rec_ordhead.order_num 
				AND part_code IS NULL 
				IF status <> notfound THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "B" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","B") 
				END IF 
			WHEN "12" ## notes 
				IF NOT p_hide_option THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "C" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","C") 
				END IF 
			WHEN "13" ## cash receipts 
				SELECT unique 1 FROM cashreceipt 
				WHERE order_num = l_rec_ordhead.order_num 
				AND cmpy_code = p_cmpy 
				IF status != notfound THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "D" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","D") 
				END IF 
			WHEN "14" ## ORDER AUDIT trail 
				LET l_idx = l_idx + 1 
				LET l_arr_ordmenu[l_idx].option_num = "E" 
				LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","E") 
			WHEN "15" ## export ORDER deliveries (Containers) 
				IF l_rec_ordhead.ord_ind = "8" THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "F" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","F") 
				END IF 
			WHEN "16" ## labour allocations 
				IF l_rec_ordhead.ord_ind = "9" THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "G" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","G") 
				END IF 
			WHEN "17" ## labour item allocations 
				IF l_rec_ordhead.ord_ind = "9" THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "H" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","H") 
				END IF 
			WHEN "18" ## delivery docket inquiry 
				SELECT unique 1 FROM delivhead 
				WHERE order_num = l_rec_ordhead.order_num 
				AND cmpy_code = p_cmpy 
				IF status = 0 THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_ordmenu[l_idx].option_num = "I" 
					LET l_arr_ordmenu[l_idx].option_text = kandooword("mbordwin","I") 
				END IF 
		END CASE 
	END FOR 
	LET l_arr_size = l_idx 
	OPEN WINDOW w177 with FORM "W177" 
	CALL windecoration_w("W177") -- albo kd-767 
	DISPLAY BY NAME l_rec_ordhead.order_num, 
	l_rec_customer.cust_code, 
	l_rec_customer.name_text 

	CALL set_count(l_idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET l_msgresp=kandoomsg("W",1054,"") 
	INPUT ARRAY l_arr_ordmenu WITHOUT DEFAULTS FROM sr_ordmenu.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","mbordwind","input-arr-ordmenu") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			#CALL f_more(l_arr_size, l_idx, l_scrn)
			DISPLAY l_arr_ordmenu[l_idx].* TO sr_ordmenu[l_scrn].* 

		AFTER FIELD scroll_flag 
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD option_num
			--#END IF
			IF l_arr_ordmenu[l_idx].scroll_flag IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD option_num 
			IF l_arr_ordmenu[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_ordmenu[l_idx].scroll_flag = l_arr_ordmenu[l_idx].option_num 
			ELSE 
				LET i = 1 
				WHILE (l_arr_ordmenu[l_idx].scroll_flag IS NOT null) 
					IF l_arr_ordmenu[i].option_num IS NULL THEN 
						LET l_arr_ordmenu[l_idx].scroll_flag = NULL 
					ELSE 
						IF l_arr_ordmenu[l_idx].scroll_flag= 
						l_arr_ordmenu[i].option_num THEN 
							EXIT WHILE 
						END IF 
					END IF 
					LET i = i + 1 
				END WHILE 
			END IF 
			CASE l_arr_ordmenu[l_idx].scroll_flag 
				WHEN "1" 
					OPEN WINDOW w174b with FORM "W174" 
					CALL windecoration_w("W174") -- albo kd-767 
					CALL disp_ordhead(p_cmpy, l_rec_ordhead.order_num) 
					CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 
					CLOSE WINDOW w174b 
				WHEN "2" 
					CALL disp_job_addr(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "3" 
					CALL disp_add_info(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "4" 
					CALL disp_lines(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "5" 
					CALL disp_status(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "6" 
					CALL disp_callfwd(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "7" 
					IF l_rec_ordhead.last_del_num IS NOT NULL 
					AND l_rec_ordhead.last_del_num != 0 THEN 
						CALL disp_deliv(p_cmpy, l_rec_ordhead.order_num) 
					END IF 
				WHEN "8" 
					CALL disp_del_inst(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "9" 
					CALL disp_report(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "A" 
					CALL disp_pallet(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "B" 
					CALL add_chargs(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "C" 
					CALL disp_notes(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "D" 
					CALL disp_cashreceipt(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "E" 
					CALL show_aud(p_cmpy, l_rec_ordhead.order_num,true) 
				WHEN "F" 
					CALL show_exp(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "G" 
					CALL show_labouralloc(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "H" 
					CALL show_labouritem(p_cmpy, l_rec_ordhead.order_num) 
				WHEN "I" 
					CALL run_prog("W2A",l_rec_ordhead.order_num,"","","") 
			END CASE 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET l_arr_ordmenu[l_idx].scroll_flag = NULL 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_ordmenu[l_idx].* 
			TO sr_ordmenu[l_scrn].* 


	END INPUT 
	CLOSE WINDOW w177 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


#This same FUNCTION used FOR W17 as well as mbordwin
#Window size of 8 in common
#huho - We may remove this later @remove
FUNCTION f_more(p_arr_size,p_idx,p_scrn) 
	DEFINE p_arr_size SMALLINT 
	DEFINE p_idx SMALLINT
	DEFINE p_scrn SMALLINT
	DEFINE l_more CHAR(9)

	LET l_more = "more ..." 
	IF p_arr_size > (p_idx - p_scrn + 8) THEN 
		DISPLAY l_more TO more 
	ELSE 
		CLEAR more 
	END IF 
END FUNCTION 


