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

	Source code beautified by beautify.pl on 2020-01-03 09:12:25	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "I28_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I28a - Allows the user TO enter price adjustments FOR fifo
# costing, also UPDATE weighted average cost


DEFINE 
#   pr_prodstatus RECORD LIKE prodstatus.*,
#   pr_product RECORD LIKE product.*,
pa_product array[7] OF RECORD 
	ware_code LIKE warehouse.ware_code, 
	part_code LIKE product.part_code, 
	desc_text LIKE product.desc_text 
END RECORD, 
pop_rec RECORD 
	ware_code LIKE warehouse.ware_code, 
	part_code LIKE product.part_code, 
	desc_text LIKE product.desc_text 
END RECORD, 
pr_cmpy LIKE company.cmpy_code, 
idx, cur, nxt, pa_tot, laslin SMALLINT 


#main
#   defer interrupt
#   defer quit
#   CALL security ("I28")
#   LET ans = "Y"
#   WHILE ans = "Y"
#      CALL doit()
#   END WHILE
#END MAIN

FUNCTION doit() 

	DEFINE 
	i, usr_esc SMALLINT, 
	where_part CHAR(100), 
	sel_text CHAR(500) 

	LET int_flag = 0 
	LET quit_flag = 0 

	OPEN WINDOW wi200 with FORM "I200" 
	 CALL windecoration_i("I200") -- albo kd-758 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.

	CONSTRUCT BY NAME where_part ON 
	prodstatus.ware_code, 
	prodstatus.part_code, 
	product.desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I28a","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	LET sel_text = 
	"SELECT prodstatus.cmpy_code, prodstatus.ware_code, ", 
	" prodstatus.part_code, product.desc_text ", 
	" FROM prodstatus, product ", 
	" WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" prodstatus.part_code = product.part_code AND ", 
	where_part clipped, 
	" ORDER BY prodstatus.cmpy_code, prodstatus.part_code, ", 
	" prodstatus.ware_code " 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET ans = "N" 
		CLOSE WINDOW wi200 
		RETURN 
	END IF 

	PREPARE sel_stmt FROM sel_text 
	DECLARE prod_curs SCROLL CURSOR with HOLD FOR sel_stmt 
	OPEN prod_curs 

	LET pa_tot = 5 
	LET idx = 0 
	INITIALIZE pop_rec.* TO NULL 
	FOR i = 1 TO 7 
		INITIALIZE pa_product[i].* TO NULL 
	END FOR 

	FOR i = 2 TO 6 
		FETCH prod_curs INTO pr_cmpy, pa_product[i].* 
		IF status = notfound THEN 
			LET pa_tot = 0 
			EXIT FOR 
		END IF 
	END FOR 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36, 
	NEXT KEY f36, 
	previous KEY f36 
	LET msgresp = kandoomsg("I",1051,"") 
	#1033  Enter on line TO enter adjustment; F3 Pg-Up; F4 Pg-Down

	CALL set_count(7) 
	LET nxt = 2 
	LET laslin = false 

	WHILE true 
		LET usr_esc = true 
		IF laslin THEN 
			LET nxt = 6 
			LET laslin = false 
			CALL shflup() 
		END IF 
		INPUT ARRAY pa_product WITHOUT DEFAULTS FROM sr_product.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","I28a","input-arr-pa_product-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET cur = arr_curr() 
				IF nxt IS NULL THEN 
					IF cur = 1 THEN 
						LET nxt = 2 
						CALL shfldown() 
					ELSE 
						IF cur = 7 THEN 
							LET laslin = true 
							LET usr_esc = false 
							EXIT INPUT 
						END IF 
					END IF 
				END IF 
				IF nxt > cur THEN 
					NEXT FIELD desc_text 
				END IF 
				LET nxt = NULL 

			BEFORE FIELD part_code 
				LET cur = arr_curr() 
				IF pa_product[cur].ware_code IS NOT NULL THEN 
					CALL sel_cost(glob_rec_kandoouser.cmpy_code, pa_product[cur].ware_code, 
					pa_product[cur].part_code, glob_rec_kandoouser.sign_on_code) 
				END IF 
				NEXT FIELD ware_code 
			AFTER ROW 
				LET cur = arr_curr() 
			ON KEY (F4) # PAGE down 
				CALL pagedown() 
				LET usr_esc = false 
				LET laslin = false 
				LET nxt = 2 
				EXIT INPUT 
			ON KEY (F3) #page up 
				CALL pageup() 
				LET usr_esc = false 
				LET laslin = false 
				LET nxt = 2 
				EXIT INPUT 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF quit_flag != 0 
		OR int_flag != 0 THEN 
			EXIT WHILE 
		END IF 
		IF usr_esc THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wi200 
	CLOSE prod_curs 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2, 
	NEXT KEY f3, 
	previous KEY f4 

END FUNCTION 

#FETCH row AT bottom of SELECT list AND move rows in array
#up one. row AT top IS lost AND row AT bottom becomes newly
#FETCHed row.

FUNCTION shflup() 
	DEFINE 
	i SMALLINT, 
	x SMALLINT 

	IF pa_tot = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	LET idx = idx + 1 
	LET x = idx + pa_tot 
	FETCH absolute x prod_curs INTO pr_cmpy, pop_rec.* 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		LET idx = idx - 1 
		RETURN 
	END IF 
	FOR i = 1 TO pa_tot 
		LET pa_product[i+1].* = pa_product[i+2].* 
	END FOR 
	LET pa_product[6].* = pop_rec.* 
END FUNCTION 

#FETCH row AT top of SELECT list AND move rows in array
#down one. Row AT bottom IS lost AND row AT top becomes newly
#FETCHed row.

FUNCTION shfldown() 
	DEFINE 
	i SMALLINT 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	ELSE 
		FETCH absolute idx prod_curs INTO pr_cmpy, pop_rec.* 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("I",9116,"") 
			#9116  Logic Error: Prodstatus does NOT exist
			INITIALIZE pop_rec.* TO NULL 
		END IF 
		LET idx = idx - 1 
		LET i = 6 
		WHILE i > 2 
			LET pa_product[i].* = pa_product[i-1].* 
			DISPLAY pa_product[i].* TO sr_product[i].* 
			LET i = i - 1 
		END WHILE 
		LET pa_product[2].* = pop_rec.* 
		DISPLAY pa_product[2].* TO sr_product[2].* 
	END IF 
END FUNCTION 

#FETCH rows AT bottom of SELECT list AND move rows in array
#out. Rows are lost AND replaced by newly FETCHed rows

FUNCTION pageup() 
	DEFINE 
	x, i, j, diff SMALLINT 

	IF pa_tot = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	FOR i = 1 TO 5 
		LET idx = idx + 1 
		LET x = pa_tot + idx 
		FETCH absolute x prod_curs INTO pr_cmpy, pop_rec.* 
		IF status = notfound THEN 
			IF i = 1 THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going
				LET idx = idx - 1 
			ELSE # this code IS performed so that the LAST screen has 5 items 
				# AND the idx ARRAY counter IS NOT upset
				LET diff = 5 - i 
				LET idx = idx - i 
				LET idx = idx - (diff + 1) 
				FOR i = 1 TO 5 
					LET idx = idx + 1 
					LET x = pa_tot + idx 
					FETCH absolute x prod_curs INTO pr_cmpy, pop_rec.* 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",2001,"") 
						#2001 Error in ARRAY processing
						EXIT program 
					END IF 
					IF i = 1 THEN 
						FOR j = 1 TO 7 
							INITIALIZE pa_product[j].* TO NULL 
						END FOR 
					END IF 
					LET pa_product[i+1].* = pop_rec.* 
				END FOR 
			END IF 
			RETURN 
		END IF 
		IF i = 1 THEN 
			FOR j = 1 TO 7 
				INITIALIZE pa_product[j].* TO NULL 
			END FOR 
		END IF 
		LET pa_product[i+1].* = pop_rec.* 
	END FOR 
END FUNCTION 

#FETCH rows AT top of SELECT list AND move rows in array
#out. Rows are lost AND replaced by newly FETCHed rows

FUNCTION pagedown() 
	DEFINE 
	x, i, j, diff SMALLINT 

	IF pa_tot = 0 
	OR idx = 0 THEN 
		LET msgresp = kandoomsg("U",9001,"") 
		#9001 There are no more rows in the direction you are going.
		RETURN 
	END IF 
	LET idx = idx - 10 
	IF idx < -5 THEN 
		LET idx = -5 
	END IF 
	FOR i = 1 TO 5 
		LET idx = idx + 1 
		LET x = pa_tot + idx 
		FETCH absolute x prod_curs INTO pr_cmpy, pop_rec.* 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("I",2001,"") 
			#2001 Error in ARRAY processing
			EXIT program 
		END IF 
		IF i = 1 THEN 
			FOR j = 1 TO 7 
				INITIALIZE pa_product[j].* TO NULL 
			END FOR 
		END IF 
		LET pa_product[i+1].* = pop_rec.* 
	END FOR 
END FUNCTION 
