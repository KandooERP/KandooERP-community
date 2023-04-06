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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}



#        scostwind.4gl - show_shipcost
#         window FUNCTION that show shipping costs
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_shipcost(p_cmpy,pr_ship_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE pr_ship_code LIKE shiphead.ship_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_othercost RECORD 
		class_ind LIKE shipcosttype.class_ind, 
		res_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE shipcosttype.desc_text, 
		cost_amt LIKE voucherdist.cost_amt 
	END RECORD 
	DEFINE l_arr_othercost ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		class_ind LIKE shipcosttype.class_ind, 
		cost_type_code LIKE shipcosttype.cost_type_code, 
		desc_text LIKE shipcosttype.desc_text, 
		cost_amt LIKE voucherdist.cost_amt 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW l144 with FORM "L144" 
	CALL windecoration_l("L144") -- albo kd-767 
	SELECT * INTO l_rec_shiphead.* 
	FROM shiphead 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_ship_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("L",9004,"") 
		CLOSE WINDOW l144 
		RETURN 
	END IF 
	WHILE true 
		CLEAR FORM 
		DISPLAY BY NAME l_rec_shiphead.ship_code, 
		l_rec_shiphead.ship_type_code 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"

		LET l_query_text = 
		" SELECT class_ind, res_code, shipcosttype.desc_text, ", 
		" sum(voucherdist.dist_amt / conv_qty) ", 
		" FROM voucherdist, voucher, shipcosttype ", 
		" WHERE voucher.cmpy_code = '", p_cmpy, "'", 
		" AND voucherdist.cmpy_code = '", p_cmpy, "'", 
		" AND voucherdist.vouch_code = voucher.vouch_code ", 
		" AND voucherdist.vend_code = voucher.vend_code ", 
		" AND shipcosttype.cmpy_code = '", p_cmpy, "'", 
		" AND shipcosttype.cost_type_code = voucherdist.res_code ", 
		" AND voucherdist.job_code = '", pr_ship_code,"'", 
		" AND voucherdist.type_ind = 'S' ", 
		" group by class_ind, res_code, shipcosttype.desc_text ", 
		" UNION ", 
		" SELECT class_ind, res_code, shipcosttype.desc_text, ", 
		" sum((0 - debitdist.dist_amt) / conv_qty)", 
		" FROM debitdist, debithead, shipcosttype", 
		" WHERE debithead.cmpy_code = '", p_cmpy,"'", 
		" AND debitdist.cmpy_code = '", p_cmpy,"'", 
		" AND debitdist.debit_code = debithead.debit_num", 
		" AND debitdist.vend_code = debithead.vend_code", 
		" AND shipcosttype.cmpy_code = '", p_cmpy, "'", 
		" AND shipcosttype.cost_type_code = debitdist.res_code ", 
		" AND debitdist.job_code = '", pr_ship_code,"'", 
		" AND debitdist.type_ind = 'S'", 
		" group by class_ind, res_code, shipcosttype.desc_text ", 
		" ORDER BY 1, 2, 3 " 

		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_othercost FROM l_query_text 
		DECLARE c_othercost CURSOR FOR s_othercost 
		LET l_idx = 0 
		FOREACH c_othercost INTO l_rec_othercost.* 
			IF l_idx > 0 THEN 
				IF l_arr_othercost[l_idx].class_ind = l_rec_othercost.class_ind 
				AND l_arr_othercost[l_idx].cost_type_code 
				= l_rec_othercost.res_code THEN 
					LET l_arr_othercost[l_idx].cost_amt = l_arr_othercost[l_idx].cost_amt 
					+ l_rec_othercost.cost_amt 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LET l_idx = l_idx + 1 
			LET l_arr_othercost[l_idx].class_ind = l_rec_othercost.class_ind 
			LET l_arr_othercost[l_idx].cost_type_code = l_rec_othercost.res_code 
			LET l_arr_othercost[l_idx].cost_amt = l_rec_othercost.cost_amt 
			LET l_arr_othercost[l_idx].desc_text = l_rec_othercost.desc_text 

			IF l_idx = 100 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
		ELSE 
			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
		END IF 
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_othercost[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("L",1004,"") 
		#1004 " Press ESC TO continue"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_othercost WITHOUT DEFAULTS FROM sr_othercost.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","scostwind","input-arr-othercost") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_othercost[l_idx].cost_type_code IS NOT NULL THEN 
					DISPLAY l_arr_othercost[l_idx].* TO sr_othercost[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_othercost[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD class_ind 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_othercost[l_idx].* TO sr_othercost[l_scrn].* 


		END INPUT 
		EXIT WHILE 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW l144 
	RETURN 
END FUNCTION 


