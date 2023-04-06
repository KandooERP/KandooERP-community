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

	Source code beautified by beautify.pl on 2020-01-02 17:06:14	Source code beautified by beautify.pl on 2020-01-02 17:03:23	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#as GLOBALS FROM R14a
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
# \brief module R14 allows the user TO search FOR orders on selected info
# OR have PO num passed


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R14") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	CALL create_table("purchdetl","t_purchdetl","","N") 
	CALL create_table("poaudit","t_poaudit","","N") 

	IF num_args() = 1 THEN 
		CALL pordwind(glob_rec_kandoouser.cmpy_code, arg_val(1)) 
	ELSE 
		OPEN WINDOW r108 with FORM "R108" 
		CALL  windecoration_r("R108") 

		WHILE select_order() 
		END WHILE 
		CLOSE WINDOW r108 
	END IF 

END MAIN 


FUNCTION select_order() 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pa_purchhead array[300] OF RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE purchhead.vend_code, 
		order_num LIKE purchhead.order_num, 
		confirm_ind LIKE purchhead.confirm_ind, 
		due_date LIKE purchhead.due_date, 
		ware_code LIKE purchhead.ware_code, 
		curr_code LIKE purchhead.curr_code, 
		authorise_code LIKE purchhead.authorise_code, 
		total_amt LIKE poaudit.line_total_amt, 
		status_ind LIKE purchhead.status_ind 
	END RECORD, 
	idx, scrn SMALLINT, 
	query_text CHAR(800), 
	where_text CHAR(400), 
	pr_tax_tot, pr_received_tot, pr_voucher_tot money(12,2) 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME where_text ON purchhead.vend_code, 
	order_num, 
	confirm_ind, 
	due_date, 
	ware_code, 
	curr_code, 
	authorise_code, 
	status_ind, 
	name_text, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code, 
	order_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","R14","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please wait.
	LET query_text = " SELECT purchhead.*", 
	" FROM purchhead, vendor", 
	" WHERE purchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND vendor.vend_code = purchhead.vend_code", 
	" AND ", where_text clipped, 
	" ORDER BY purchhead.vend_code, order_num" 
	OPTIONS SQL interrupt ON 
	WHENEVER ERROR CONTINUE 
	PREPARE s_purchhead FROM query_text 
	DECLARE c_purchhead CURSOR FOR s_purchhead 
	LET idx = 0 
	FOREACH c_purchhead INTO pr_purchhead.* 
		LET idx = idx + 1 
		LET pa_purchhead[idx].vend_code = pr_purchhead.vend_code 
		LET pa_purchhead[idx].order_num = pr_purchhead.order_num 
		LET pa_purchhead[idx].confirm_ind = pr_purchhead.confirm_ind 
		LET pa_purchhead[idx].due_date = pr_purchhead.due_date 
		LET pa_purchhead[idx].ware_code = pr_purchhead.ware_code 
		LET pa_purchhead[idx].curr_code = pr_purchhead.curr_code 
		LET pa_purchhead[idx].authorise_code = pr_purchhead.authorise_code 
		CALL po_head_info( glob_rec_kandoouser.cmpy_code, pr_purchhead.order_num) 
		RETURNING pa_purchhead[idx].total_amt, 
		pr_received_tot, 
		pr_voucher_tot, 
		pr_tax_tot 
		LET pa_purchhead[idx].status_ind = pr_purchhead.status_ind 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First 300 records selected only.  More may be available.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_purchhead[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36, 
	SQL interrupt off 
	WHENEVER ERROR stop 
	LET msgresp = kandoomsg("R",1506,"") 

	#1506 F3/F4 TO Page Fwd/Bwd;  Enter on line TO Edit.
	INPUT ARRAY pa_purchhead WITHOUT DEFAULTS FROM sr_purchhead.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R14","inp-arr-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

			IF pr_purchhead.vend_code IS NOT NULL THEN 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pa_purchhead[idx].vend_code 
				IF status = notfound THEN 
					INITIALIZE pr_vendor.* TO NULL 
					LET msgresp = kandoomsg("R",9510,"") 
					# WARNING: Vendor FOR this purchase ORDER does NOT exist.
				ELSE 
					SELECT * INTO pr_purchhead.* FROM purchhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pa_purchhead[idx].vend_code 
					AND order_num = pa_purchhead[idx].order_num 
					DISPLAY BY NAME pr_vendor.name_text, 
					pr_vendor.addr1_text, 
					pr_vendor.addr2_text, 
					pr_vendor.addr3_text, 
					pr_vendor.city_text, 
					pr_vendor.state_code, 
					pr_vendor.post_code, 
					pr_purchhead.order_text 

				END IF 
			END IF 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				ELSE 
					IF pa_purchhead[idx+1].vend_code IS NULL THEN 
						LET msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD vend_code 
			IF pa_purchhead[idx].order_num IS NOT NULL THEN 
				IF pr_purchhead.status_ind = "C" THEN 
					LET msgresp = kandoomsg("R",9520,"") 
					#9520 The purchase ORDER cannot be edited as it IS complete.
					NEXT FIELD scroll_flag 
				END IF 
				CALL pordwind(glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
				SELECT * INTO pr_purchhead.* FROM purchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_purchhead.order_num 
				CALL po_head_info( glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
				RETURNING pa_purchhead[idx].total_amt, 
				pr_received_tot, 
				pr_voucher_tot, 
				pr_tax_tot 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				LET pa_purchhead[idx].vend_code = pr_purchhead.vend_code 
				LET pa_purchhead[idx].authorise_code = pr_purchhead.authorise_code 
				LET pa_purchhead[idx].status_ind = pr_purchhead.status_ind 
				LET pa_purchhead[idx].due_date = pr_purchhead.due_date 
				DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 
	RETURN true 
END FUNCTION 
