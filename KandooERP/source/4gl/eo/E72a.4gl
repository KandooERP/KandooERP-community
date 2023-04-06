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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E72_GLOBALS.4gl"
###########################################################################
# FUNCTION proddisc_scan(p_cmpy,p_cond_code) 
#
# E72a - Inquiry program FOR Sales Conditions
###########################################################################
FUNCTION proddisc_scan(p_cmpy,p_cond_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cond_code LIKE condsale.cond_code 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_arr_rec_proddisc DYNAMIC ARRAY OF RECORD --array[510] OF RECORD 
		part_code LIKE proddisc.part_code, 
		prodgrp_code LIKE proddisc.prodgrp_code, 
		maingrp_code LIKE proddisc.maingrp_code, 
		reqd_amt LIKE proddisc.reqd_amt, 
		disc_per LIKE proddisc.disc_per 
	END RECORD 
	DEFINE l_part_code LIKE proddisc.part_code 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_condsale.* FROM condsale 
	WHERE cmpy_code = p_cmpy 
	AND cond_code = p_cond_code 
	IF status = NOTFOUND THEN 
		RETURN 
	END IF 
	
	OPEN WINDOW E133 with FORM "E133" 
	 CALL windecoration_e("E133") -- albo kd-755
 
	DISPLAY l_rec_condsale.cond_code TO cond_code
	DISPLAY l_rec_condsale.desc_text TO desc_text  

	DECLARE c_proddisc cursor FOR 
	SELECT part_code, prodgrp_code, maingrp_code, reqd_amt, disc_per 
	FROM proddisc 
	WHERE cmpy_code = p_cmpy 
	AND key_num = p_cond_code 
	AND type_ind = "1" 
	LET l_idx = 1 
	
	FOREACH c_proddisc INTO l_arr_rec_proddisc[l_idx].* 
		LET l_idx = l_idx + 1 
	END FOREACH
	 
	LET l_idx = l_idx - 1 
	MESSAGE kandoomsg2("U",9113,l_idx)#9113 l_idx records selected

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("E",1008,"")#1008 F3/F4 TO Page Fwd/Bwd - ESC TO Continue
	--INPUT ARRAY l_arr_rec_proddisc WITHOUT DEFAULTS FROM sr_proddisc.* 
	DISPLAY ARRAY l_arr_rec_proddisc  TO sr_proddisc.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E72a","input-arr-l_arr_rec_proddisc-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW --FIELD part_code 
			LET l_idx = arr_curr() 
			LET l_part_code = l_arr_rec_proddisc[l_idx].part_code 

		AFTER ROW --AFTER FIELD part_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_proddisc[l_idx+1].maingrp_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 				#9001 There are no more rows...
					NEXT FIELD part_code 
				END IF 
			END IF 
			LET l_arr_rec_proddisc[l_idx].part_code = l_part_code 

--		BEFORE FIELD prodgrp_code 
--			NEXT FIELD part_code 

--		AFTER ROW 
--			IF l_arr_rec_proddisc[l_idx].maingrp_code IS NULL THEN 
--				INITIALIZE l_arr_rec_proddisc[l_idx].* TO NULL 
--			END IF 

	END DISPLAY
	 
	CLOSE WINDOW E133
	 
	LET quit_flag = FALSE 
	LET int_flag = FALSE
	 
END FUNCTION 