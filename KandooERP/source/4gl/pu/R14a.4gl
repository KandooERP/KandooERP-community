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


GLOBALS "../common/glob_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R14  Purchase Order Header Edit
#  allows the user TO edit Purchase Orders Header Information

GLOBALS "R14.4gl" 
DEFINE 
pr_purchhead RECORD LIKE purchhead.*, 
pr_vendor RECORD LIKE vendor.*, 
pr_save_curr LIKE vendor.currency_code 

FUNCTION pordwind(p_cmpy, pr_po_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_po_num LIKE purchhead.order_num, 
	pa_pordmenu array[3] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD, 
	pr_rev_num LIKE purchhead.rev_num, 
	pr_output CHAR(60), 
	idx,scrn,pr_counter SMALLINT 

	OPEN WINDOW r603 with FORM "R603" 
	CALL  windecoration_r("R603") 

	SELECT * INTO pr_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_po_num 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("P",7086,"") 
		#7086 Purchase Order Details NOT found.
		RETURN 
	END IF 
	SELECT * INTO pr_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = pr_purchhead.vend_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("P",7087,"") 
		#7087 Vendor details NOT found.
		RETURN 
	END IF 
	IF pr_vendor.hold_code = "ST" THEN 
		LET msgresp = kandoomsg("P",7088,"") 
		#7088 Vendor IS on hold.  Release before proceeding.
		RETURN 
	END IF 
	FOR pr_counter = 1 TO 3 
		CASE pr_counter 
			WHEN "1" ## HEADER 
				LET idx = idx + 1 
				LET pa_pordmenu[idx].option_num = "1" 
				LET pa_pordmenu[idx].option_text = kandooword("pordwind","1") 
			WHEN "2" ## LINES 
				LET idx = idx + 1 
				LET pa_pordmenu[idx].option_num = "2" 
				LET pa_pordmenu[idx].option_text = kandooword("pordwind","2") 
			WHEN "3" ## delivery 
				LET idx = idx + 1 
				LET pa_pordmenu[idx].option_num = "3" 
				LET pa_pordmenu[idx].option_text = kandooword("pordwind","3") 
			OTHERWISE 
				EXIT FOR 
		END CASE 
	END FOR 
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_pordmenu[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	LET msgresp = kandoomsg("R",1027,"") 
	#1027 Press ENTER TO SELECT;  CANCEL TO Exit.
	DISPLAY BY NAME pr_purchhead.rev_num 

	INPUT ARRAY pa_pordmenu WITHOUT DEFAULTS FROM sr_pordmenu.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R14a","inp-arr-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_pordmenu[idx].* TO sr_pordmenu[scrn].* 

		AFTER FIELD scroll_flag 
			IF pa_pordmenu[idx].scroll_flag IS NULL 
			OR pa_pordmenu[idx].scroll_flag = " " THEN 
				IF (fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right")) 
				AND pa_pordmenu[idx].option_num IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD option_num 
			IF pa_pordmenu[idx].scroll_flag IS NULL THEN 
				LET pa_pordmenu[idx].scroll_flag = pa_pordmenu[idx].option_num 
			ELSE 
				LET pr_counter = 1 
				WHILE (pa_pordmenu[idx].scroll_flag IS NOT null) 
					IF pa_pordmenu[pr_counter].option_num IS NULL THEN 
						LET pa_pordmenu[idx].scroll_flag = NULL 
					ELSE 
						IF pa_pordmenu[idx].scroll_flag 
						= pa_pordmenu[pr_counter].option_num THEN 
							EXIT WHILE 
						END IF 
					END IF 
					LET pr_counter = pr_counter + 1 
					IF pr_counter > 3 THEN 
						LET pa_pordmenu[idx].scroll_flag = NULL 
						EXIT WHILE 
					END IF 
				END WHILE 
			END IF 
			CASE pa_pordmenu[idx].scroll_flag 
				WHEN "1" # HEADER 
					IF edit_header("EDIT",p_cmpy,pr_po_num) THEN 
					END IF 
				WHEN "2" # LINES 
					IF po_mod(p_cmpy,glob_rec_kandoouser.sign_on_code,pr_po_num,"EDIT") THEN 
					END IF 
				WHEN "3" # detail 
					IF edit_delivery("EDIT",pr_po_num) THEN 
					END IF 
				OTHERWISE 
					NEXT FIELD scroll_flag 
			END CASE 
			SELECT purchhead.rev_num INTO pr_rev_num FROM purchhead 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_po_num 
			DISPLAY pr_rev_num 
			TO purchhead.rev_num 

			LET pa_pordmenu[idx].scroll_flag = NULL 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_pordmenu[idx].* TO sr_pordmenu[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW r603 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 

