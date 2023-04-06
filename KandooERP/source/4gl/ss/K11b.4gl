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

	Source code beautified by beautify.pl on 2019-12-31 14:28:26	$Id: $
}




#  K11b.4gl:FUNCTION lineitem_scan()
#           ARRAY add/edit of subdetl records
#  K11b.4gl:FUNCTION insert_line()
#           INITIALIZE defaults AND INSERT new t_subdetl
#  K11b.4gl:FUNCTION update_line()
#           Update t_subdetl record
#  K11b.4gl:FUNCTION disp_total()
#           displays subhead totals WHILE in lineitem_scan
#  K11b.4gl:FUNCTION validate_field(pr_field_num)
#           Called FROM lineitem scan AND sub_detail TO validate data entry
#  K11b.4gl:FUNCTION sched_issue(pr_verbose_num)
#           Creates subschedule records AND Calculates
#           subscription quantity FOR scheduled type products
#           pr_verbose_num = TRUE - Allows editing of issue dates & qty
#           pr_verbose_num = FALSE - no DISPLAY OR INPUT - returns qty

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 



FUNCTION lineitem_scan() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subdetl RECORD LIKE subdetl.*, 
	ps_subdetl RECORD LIKE subdetl.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_substype RECORD LIKE substype.*, 
	pa_subdetl array[300] OF RECORD 
		scroll_flag CHAR(1), 
		sub_line_num LIKE subdetl.sub_line_num, 
		part_code LIKE subdetl.part_code, 
		line_text LIKE subdetl.line_text, 
		sub_qty LIKE subdetl.sub_qty, 
		unit_amt LIKE subdetl.unit_amt, 
		line_total_amt LIKE subdetl.line_total_amt 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	idx,save_scrn,scrn,pr_valid_ind,i,j SMALLINT, 
	pr_lastkey INTEGER, 
	pr_part_code LIKE product.part_code, 
	pr_sub_qty LIKE subdetl.sub_qty 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 


	DISPLAY BY NAME pr_subhead.cust_code, 
	pr_customer.name_text, 
	pr_subhead.ware_code, 
	pr_subhead.tax_code 

	SELECT * INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_subhead.ware_code 
	DISPLAY pr_warehouse.desc_text TO ware_text 

	DISPLAY BY NAME pr_subhead.currency_code 
	attribute(green) 
	DECLARE c1_subdetl CURSOR FOR 
	SELECT * FROM t_subdetl 
	WHERE (sub_num IS NULL OR 
	sub_num = pr_subhead.sub_num) 
	ORDER BY sub_line_num 
	LET idx = 0 
	FOREACH c1_subdetl INTO pr_subdetl.* 
		LET idx = idx + 1 
		LET pr_subdetl.ware_code = pr_warehouse.ware_code 
		IF pr_subdetl.sub_line_num != idx THEN 
			UPDATE t_subdetl 
			SET sub_line_num = idx 
			WHERE sub_line_num = pr_subdetl.sub_line_num 
			AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
			LET pr_subdetl.sub_line_num = idx 
		END IF 
		LET pa_subdetl[idx].sub_line_num = pr_subdetl.sub_line_num 
		LET pa_subdetl[idx].part_code = pr_subdetl.part_code 
		LET pa_subdetl[idx].line_text = pr_subdetl.line_text 
		LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
		LET pa_subdetl[idx].unit_amt = pr_subdetl.unit_amt 
		IF pr_arparms.show_tax_flag = "Y" THEN 
			LET pa_subdetl[idx].line_total_amt = pr_subdetl.line_total_amt 
		ELSE 
		LET pa_subdetl[idx].line_total_amt =pr_subdetl.unit_amt * 
		pr_subdetl.sub_qty 
	END IF 
END FOREACH 
CALL set_count(idx) 
OPTIONS INSERT KEY f1, 
DELETE KEY f36 
LET msgresp=kandoomsg("K",1014,"") 
#1014 F1 TO Add etc...
INPUT ARRAY pa_subdetl WITHOUT DEFAULTS FROM sr_subdetl.* 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	ON KEY (control-c) --customer details / customer invoice submenu 
		CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) --customer details / customer invoice submenu 
		NEXT FIELD part_code 

	ON KEY (control-b) 
		IF infield(part_code) THEN 
			LET l_tmp_text= " type_code = '",pr_subhead.sub_type_code,"' ", 
			" AND (linetype_ind = '2' OR ( part_code in ", 
			"(SELECT part_code FROM subissues ", 
			"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND plan_iss_date between '",pr_subhead.start_date, 
			"' AND '",pr_subhead.end_date,"')))" 
			LET l_tmp_text = show_subproduct(glob_rec_kandoouser.cmpy_code,l_tmp_text) 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_tmp_text IS NOT NULL THEN 
				LET pa_subdetl[idx].part_code = l_tmp_text 
				NEXT FIELD part_code 
			END IF 
		END IF 
	ON KEY (F8) 
		LET save_scrn = scr_line() 
		SELECT * INTO pr_subdetl.* 
		FROM t_subdetl 
		WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		IF status = 0 THEN 
			LET pr_gsubdetl.* = pr_subdetl.* 
			CALL sub_detail() 
			CALL disp_total(save_scrn) 
			LET pr_subdetl.* = pr_gsubdetl.* 
			LET pa_subdetl[idx].sub_line_num = pr_subdetl.sub_line_num 
			LET pa_subdetl[idx].part_code = pr_subdetl.part_code 
			LET pa_subdetl[idx].line_text = pr_subdetl.line_text 
			LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
			LET pa_subdetl[idx].unit_amt = 
			pr_subdetl.unit_amt 
			LET pa_subdetl[idx].line_total_amt= 
			pr_subdetl.line_total_amt 
			NEXT FIELD scroll_flag 
		END IF 
	BEFORE FIELD scroll_flag 
		LET idx = arr_curr() 
		LET scrn = scr_line() 
		SELECT * INTO pr_subdetl.* 
		FROM t_subdetl 
		WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		IF sqlca.sqlcode = notfound THEN 
			LET pr_subdetl.sub_line_num = NULL 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				NEXT FIELD sub_line_num 
			END IF 
		ELSE 
		LET pr_gsubdetl.* = pr_subdetl.* 
		CALL disp_total(scrn) 
	END IF 
	BEFORE ROW 
		LET idx = arr_curr() 
		LET scrn = scr_line() 
		NEXT FIELD scroll_flag 
	AFTER FIELD scroll_flag 
		LET pr_lastkey = fgl_lastkey() 
		IF fgl_lastkey() = fgl_keyval("down") THEN 
			IF pa_subdetl[idx].sub_line_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
		END IF 

	BEFORE FIELD sub_line_num 
		LET pr_lastkey = fgl_lastkey() 
		IF pr_subdetl.sub_line_num IS NULL THEN 
			CALL insert_line() 
			LET pr_subdetl.* = pr_gsubdetl.* 
			INITIALIZE ps_subdetl.* TO NULL 
			LET pr_part_code = NULL 
			LET pa_subdetl[idx].sub_line_num = pr_subdetl.sub_line_num 
			LET pa_subdetl[idx].part_code = pr_subdetl.part_code 
			LET pa_subdetl[idx].line_text = pr_subdetl.line_text 
			LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
			LET pa_subdetl[idx].unit_amt = 
			pr_subdetl.unit_amt 
			LET pa_subdetl[idx].line_total_amt= 
			pr_subdetl.line_total_amt 
		ELSE 
		LET ps_subdetl.* = pr_subdetl.* 
		LET pr_part_code = ps_subdetl.part_code 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	CALL disp_total(scrn) 
	IF pr_lastkey = fgl_keyval("left") 
	OR pr_lastkey = fgl_keyval("up") THEN 
		NEXT FIELD scroll_flag 
	ELSE 
	NEXT FIELD part_code 
END IF 
	BEFORE FIELD part_code 
		LET pr_part_code = pa_subdetl[idx].part_code 
	AFTER FIELD part_code 
		LET pr_lastkey = fgl_lastkey() 
		LET pr_subdetl.part_code = pa_subdetl[idx].part_code 
		IF pr_part_code IS NOT NULL 
		AND pr_subdetl.part_code <> pr_part_code THEN 
			IF pr_subdetl.issue_qty > 0 
			OR pr_subdetl.inv_qty > 0 THEN 
				LET pa_subdetl[idx].part_code = pr_part_code 
				LET msgresp = kandoomsg("K",9111,"") 
				#9111 Partially shipped
				NEXT FIELD part_code 
			END IF 
		END IF 
		IF pr_part_code IS NULL 
		OR pr_subdetl.part_code != pr_part_code THEN 
			##
			## WHEN part code changed (OR first entered) the price
			## AND description must be reset.
			## any scheduled items must also be deleted FROM old part code
			##
			DELETE FROM t_subschedule 
			WHERE sub_line_num = pr_subdetl.sub_line_num 
			AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
			LET pr_part_code = pr_subdetl.part_code 
			LET pr_subdetl.unit_amt = NULL 
			LET pr_subdetl.line_text = NULL 
		END IF 
		LET pr_gsubdetl.* = pr_subdetl.* 
		CALL validate_field(0) 
		RETURNING pr_valid_ind 
		CALL disp_total(scrn) 
		LET pr_subdetl.* = pr_gsubdetl.* 
		LET pa_subdetl[idx].part_code = pr_subdetl.part_code 
		LET pa_subdetl[idx].line_text = pr_subdetl.line_text 
		LET pa_subdetl[idx].unit_amt = pr_subdetl.unit_amt 
		LET pa_subdetl[idx].line_total_amt = pr_subdetl.line_total_amt 
		CASE 
			WHEN NOT pr_valid_ind 
				NEXT FIELD part_code 
			WHEN pr_lastkey=fgl_keyval("RETURN") 
				OR pr_lastkey=fgl_keyval("right") 
				OR pr_lastkey=fgl_keyval("tab") 
				OR pr_lastkey=fgl_keyval("down") 
				OR pr_lastkey=fgl_keyval("accept") 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_subdetl[idx].part_code 
				SELECT * INTO pr_substype.* 
				FROM substype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				SELECT * INTO pr_subproduct.* 
				FROM subproduct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_subdetl.part_code 
				AND type_code = pr_subhead.sub_type_code 
				IF pr_subproduct.linetype_ind = "1" THEN 
					LET pr_gsubdetl.* = pr_subdetl.* 
					CALL sched_issue(0) 
					RETURNING pr_valid_ind 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					IF NOT pr_valid_ind THEN 
						NEXT FIELD part_code 
					END IF 
					CALL update_line() 
					CALL disp_total(scrn) 
					LET pr_subdetl.* = pr_gsubdetl.* 
					LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
					NEXT FIELD unit_amt 
				ELSE 
				IF pr_substype.inv_ind = "2" OR 
				pr_substype.inv_ind = "3" THEN 
					LET msgresp = kandoomsg("K",9112,"") 
					LET pa_subdetl[idx].part_code = pr_part_code 
					NEXT FIELD part_code 
				END IF 
				NEXT FIELD sub_qty 
			END IF 
			WHEN pr_lastkey=fgl_keyval("left") 
				OR pr_lastkey=fgl_keyval("up") 
				NEXT FIELD previous 
			OTHERWISE 
				NEXT FIELD part_code 
		END CASE 
	BEFORE FIELD sub_qty 
		LET pr_sub_qty = pa_subdetl[idx].sub_qty 
		IF pr_subproduct.linetype_ind = "1" THEN 
			LET pr_gsubdetl.* = pr_subdetl.* 
			CALL sched_issue(1) 
			RETURNING pr_valid_ind 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF NOT pr_valid_ind THEN 
				NEXT FIELD part_code 
			END IF 
			CALL update_line() 
			CALL disp_total(scrn) 
			LET pr_subdetl.* = pr_gsubdetl.* 
			LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
			NEXT FIELD unit_amt 
		END IF 
	AFTER FIELD sub_qty 
		LET pr_lastkey = fgl_lastkey() 
		LET pr_subdetl.sub_qty = pa_subdetl[idx].sub_qty 
		IF pr_subdetl.sub_qty < pr_subdetl.inv_qty 
		OR pr_subdetl.sub_qty < pr_subdetl.issue_qty THEN 
			LET pa_subdetl[idx].sub_qty = pr_sub_qty 
			LET msgresp = kandoomsg("K",9111,"") 
			#9111 Partially shipped
			NEXT FIELD sub_qty 
		END IF 
		LET pr_gsubdetl.* = pr_subdetl.* 
		CALL validate_field(1) 
		RETURNING pr_valid_ind 
		CALL disp_total(scrn) 
		LET pr_subdetl.* = pr_gsubdetl.* 
		CASE 
			WHEN NOT(pr_valid_ind) 
				NEXT FIELD part_code 
			WHEN pr_lastkey=fgl_keyval("accept") 
				NEXT FIELD line_total_amt 
			WHEN pr_lastkey=fgl_keyval("RETURN") 
				OR pr_lastkey=fgl_keyval("right") 
				OR pr_lastkey=fgl_keyval("tab") 
				OR pr_lastkey=fgl_keyval("down") 
				NEXT FIELD NEXT 
			WHEN pr_lastkey=fgl_keyval("left") 
				OR pr_lastkey=fgl_keyval("up") 
				NEXT FIELD previous 
			OTHERWISE 
				NEXT FIELD sub_qty 
		END CASE 
	BEFORE FIELD unit_amt 
		IF pr_subdetl.issue_qty > 0 
		OR pr_subdetl.inv_qty > 0 THEN 
			NEXT FIELD line_total_amt 
		END IF 
	AFTER FIELD unit_amt 
		LET pr_lastkey = fgl_lastkey() 
		LET pr_subdetl.unit_amt = pa_subdetl[idx].unit_amt 
		LET pr_gsubdetl.* = pr_subdetl.* 
		CALL validate_field(2) 
		RETURNING pr_valid_ind 
		CALL disp_total(scrn) 
		LET pr_subdetl.* = pr_gsubdetl.* 
		LET pa_subdetl[idx].unit_amt = pr_subdetl.unit_amt 
		LET pa_subdetl[idx].line_total_amt = pr_subdetl.line_total_amt 
		CASE 
			WHEN NOT(pr_valid_ind) 
				NEXT FIELD unit_amt 
			WHEN pr_lastkey=fgl_keyval("accept") 
				NEXT FIELD line_total_amt 
			WHEN pr_lastkey=fgl_keyval("RETURN") 
				OR pr_lastkey=fgl_keyval("right") 
				OR pr_lastkey=fgl_keyval("tab") 
				OR pr_lastkey=fgl_keyval("down") 
				NEXT FIELD NEXT 
			WHEN pr_lastkey=fgl_keyval("left") 
				OR pr_lastkey=fgl_keyval("up") 
				NEXT FIELD previous 
			OTHERWISE 
				NEXT FIELD unit_amt 
		END CASE 
	BEFORE FIELD line_total_amt 
		SELECT * INTO pr_subdetl.* 
		FROM t_subdetl 
		WHERE sub_line_num = pr_subdetl.sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		LET pa_subdetl[idx].part_code = pr_subdetl.part_code 
		LET pa_subdetl[idx].line_text = pr_subdetl.line_text 
		LET pa_subdetl[idx].sub_qty = pr_subdetl.sub_qty 
		LET pa_subdetl[idx].unit_amt = pr_subdetl.unit_amt 
		LET pa_subdetl[idx].line_total_amt=pr_subdetl.line_total_amt 
		IF pr_arparms.show_tax_flag = "N" THEN 
			LET pa_subdetl[idx].line_total_amt = 
			pr_subdetl.unit_amt * pr_subdetl.sub_qty 
		ELSE 
		LET pa_subdetl[idx].line_total_amt = 
		pr_subdetl.line_total_amt 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	CALL disp_total(scrn) 
	IF pr_lastkey = fgl_keyval("interrupt") 
	OR pr_lastkey = fgl_keyval("accept") THEN 
		## IF line entry NOT complete THEN RETURN TO scroll flag
		NEXT FIELD scroll_flag 
	END IF 
	AFTER FIELD line_total_amt 
		LET pr_lastkey = fgl_lastkey() 
	ON KEY (F2) 
		#CASE
		#WHEN infield(scroll_flag)
		SELECT * INTO pr_subdetl.* 
		FROM t_subdetl 
		WHERE sub_line_num = pr_subdetl.sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		IF status = 0 THEN 
			IF pr_subdetl.issue_qty > 0 OR 
			pr_subdetl.inv_qty > 0 THEN 
				LET msgresp = kandoomsg("K",9107,"") 
				NEXT FIELD scroll_flag 
			END IF 
		END IF 
		DELETE FROM t_subdetl 
		WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		DELETE FROM t_subschedule 
		WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
		AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		LET j = scrn 
		FOR i = idx TO arr_count() 
			IF i = 300 THEN 
				INITIALIZE pa_subdetl[300].* TO NULL 
			ELSE 
			LET pa_subdetl[i].* = pa_subdetl[i+1].* 
		END IF 
		IF pa_subdetl[i].sub_line_num = 0 THEN 
			INITIALIZE pa_subdetl[i].* TO NULL 
		END IF 
		IF j <= 8 THEN 
			DISPLAY pa_subdetl[i].* TO sr_subdetl[j].* 

			LET j = j + 1 
		END IF 
	END FOR 
	SELECT * INTO pr_subdetl.* 
	FROM t_subdetl 
	WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
	AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
	IF sqlca.sqlcode = notfound THEN 
		INITIALIZE pr_subdetl.* TO NULL 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	CALL disp_total(scrn) 
	NEXT FIELD scroll_flag 
	#OTHERWISE
	#NEXT FIELD scroll_flag
	#END CASE
	BEFORE INSERT 
		INITIALIZE pa_subdetl[idx].* TO NULL 
		INITIALIZE pr_subdetl.* TO NULL 
		NEXT FIELD sub_line_num 
	AFTER ROW 
		LET pa_subdetl[idx].scroll_flag = NULL 
		DISPLAY pa_subdetl[idx].* TO sr_subdetl[scrn].* 

	AFTER INPUT 
		IF int_flag OR quit_flag THEN 
			IF NOT infield(scroll_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				IF ps_subdetl.sub_line_num IS NULL THEN 
					DELETE FROM t_subdetl 
					WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
					AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
					DELETE FROM t_subschedule 
					WHERE sub_line_num = pa_subdetl[idx].sub_line_num 
					AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
					LET j = scrn 
					FOR i = arr_curr() TO arr_count() 
						IF pa_subdetl[i+1].sub_line_num IS NOT NULL THEN 
							LET pa_subdetl[i].* = pa_subdetl[i+1].* 
						ELSE 
						INITIALIZE pa_subdetl[i].* TO NULL 
					END IF 
					IF j <= 10 THEN 
						DISPLAY pa_subdetl[i].* TO sr_subdetl[j].* 

						LET j = j + 1 
					END IF 
				END FOR 
			ELSE 
			LET pr_gsubdetl.* = ps_subdetl.* 
			CALL update_line() 
			LET pa_subdetl[idx].part_code = ps_subdetl.part_code 
			LET pa_subdetl[idx].sub_qty = ps_subdetl.sub_qty 
			LET pa_subdetl[idx].line_text = ps_subdetl.line_text 
			LET pa_subdetl[idx].unit_amt 
			= ps_subdetl.unit_amt 
			LET pa_subdetl[idx].line_total_amt 
			= ps_subdetl.line_total_amt 
		END IF 
		LET pr_gsubdetl.* = pr_subdetl.* 
		CALL disp_total(scrn) 
		NEXT FIELD scroll_flag 
	END IF 
END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END INPUT 
DELETE FROM t_subdetl 
WHERE part_code IS NULL AND line_text IS NULL AND 
(line_total_amt IS NULL OR line_total_amt = 0) 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	IF kandoomsg("A",8011,"") = "N" THEN 
		DELETE FROM t_subdetl 
		WHERE (sub_num = pr_subhead.sub_num OR sub_num IS null) 
		LET pr_subhead.line_num = 0 
		DELETE FROM t_subschedule 
		WHERE (sub_num = pr_subhead.sub_num OR sub_num IS null) 
	END IF 
	RETURN false 
ELSE 
RETURN true 
END IF 
END FUNCTION 


FUNCTION insert_line() 
	##
	## This FUNCTION inserts a line in the t_subdetl with the appropriate
	## defaults.
	##
	DEFINE 
	pr_subdetl RECORD LIKE subdetl.* 

	SELECT max(sub_line_num) INTO pr_subdetl.sub_line_num 
	FROM t_subdetl 
	WHERE (sub_num = pr_subhead.sub_num OR sub_num IS null) 
	IF pr_subdetl.sub_line_num IS NULL THEN 
		LET pr_subdetl.sub_line_num = 1 
	ELSE 
	LET pr_subdetl.sub_line_num = pr_subdetl.sub_line_num + 1 
END IF 
LET pr_subdetl.sub_num = pr_subhead.sub_num 
LET pr_subdetl.ware_code = pr_warehouse.ware_code 
LET pr_subdetl.sub_qty = 0 
LET pr_subdetl.cust_code = pr_subhead.cust_code 
LET pr_subdetl.ship_code = pr_subhead.ship_code 
LET pr_subdetl.issue_qty = 0 
LET pr_subdetl.inv_qty = 0 
LET pr_subdetl.return_qty = 0 
LET pr_subdetl.unit_amt = 0 
LET pr_subdetl.unit_tax_amt = 0 
LET pr_subdetl.line_total_amt = 0 
LET pr_subdetl.level_code = pr_customer.inv_level_ind 
LET pr_subdetl.tax_code = pr_subhead.tax_code 
INSERT INTO t_subdetl VALUES (pr_subdetl.*) 
LET pr_gsubdetl.* = pr_subdetl.* 
END FUNCTION 


FUNCTION update_line() 
	##
	## This fucnction updates an invoice line item.
	##
	DEFINE 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_float FLOAT, 
	idx SMALLINT 

	LET pr_subdetl.* = pr_gsubdetl.* 
	SELECT * INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subdetl.part_code 
	IF pr_subdetl.line_text IS NULL THEN 
		LET pr_subdetl.line_text = pr_product.desc_text 
	END IF 
	SELECT * INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_subdetl.ware_code 
	AND part_code = pr_subdetl.part_code 
	IF pr_subdetl.unit_amt IS NULL THEN 
		LET pr_subdetl.unit_amt = pr_prodstatus.list_amt 
	END IF 
	SELECT unique 1 FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_subhead.tax_code 
	AND calc_method_flag = "P" 
	IF sqlca.sqlcode = 0 THEN 
		LET pr_subdetl.tax_code = pr_subhead.tax_code 
	END IF 
	LET pr_subdetl.unit_tax_amt = 
	unit_tax(pr_subdetl.ware_code, 
	pr_subdetl.part_code, 
	pr_subdetl.unit_amt) 
	LET pr_subdetl.line_total_amt = pr_subdetl.sub_qty 
	* (pr_subdetl.unit_tax_amt 
	+ pr_subdetl.unit_amt) 
	LET pr_gsubdetl.line_total_amt = pr_subdetl.sub_qty 
	* (pr_subdetl.unit_tax_amt 
	+ pr_subdetl.unit_amt) 
	UPDATE t_subdetl 
	SET sub_line_num = pr_subdetl.sub_line_num, 
	part_code = pr_subdetl.part_code, 
	ware_code = pr_subdetl.ware_code, 
	unit_amt = pr_subdetl.unit_amt, 
	level_code = pr_subdetl.level_code, 
	tax_code = pr_subdetl.tax_code, 
	unit_tax_amt = pr_subdetl.unit_tax_amt, 
	sub_qty = pr_subdetl.sub_qty, 
	line_text = pr_subdetl.line_text, 
	line_total_amt = pr_subdetl.line_total_amt 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num = pr_subhead.sub_num OR sub_num IS null) 
END FUNCTION 


FUNCTION disp_total(scrn) 
	DEFINE 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_desc_text CHAR(30), 
	scrn SMALLINT 

	LET pr_subdetl.* = pr_gsubdetl.* 
	### DISPLAY Current Line Info
	IF pr_arparms.show_tax_flag = "N" THEN 
		LET pr_subdetl.line_total_amt = pr_subdetl.unit_amt * 
		pr_subdetl.sub_qty 
	ELSE 
	LET pr_subdetl.line_total_amt = pr_subdetl.line_total_amt 
END IF 
DISPLAY "",pr_subdetl.sub_line_num, 
pr_subdetl.part_code, 
pr_subdetl.line_text, 
pr_subdetl.sub_qty, 
pr_subdetl.unit_amt, 
pr_subdetl.line_total_amt 
TO sr_subdetl[scrn].* 

SELECT sum(unit_amt * sub_qty), 
sum(unit_tax_amt * sub_qty) 
INTO pr_subhead.goods_amt, 
pr_subhead.tax_amt 
FROM t_subdetl 
WHERE (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
IF pr_subhead.goods_amt IS NULL THEN 
	LET pr_subhead.goods_amt = 0 
END IF 
IF pr_subhead.tax_amt IS NULL THEN 
	LET pr_subhead.tax_amt = 0 
END IF 
LET pr_subhead.total_amt = pr_subhead.goods_amt 
+ pr_subhead.tax_amt 
LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
- pr_customer.bal_amt 
- pr_customer.onorder_amt 
- pr_subhead.total_amt 
+ pr_currsub_amt 
DISPLAY BY NAME pr_subhead.goods_amt, 
pr_subhead.tax_amt, 
pr_subhead.total_amt 
attribute(yellow) 
DISPLAY BY NAME pr_customer.cred_bal_amt, 
pr_subdetl.tax_code, 
pr_warehouse.ware_code 

IF pr_subdetl.tax_code IS NULL THEN 
	CLEAR tax.desc_text 
ELSE 
SELECT desc_text INTO pr_desc_text 
FROM tax 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND tax_code = pr_subdetl.tax_code 
DISPLAY pr_desc_text TO tax.desc_text 

END IF 
END FUNCTION 


FUNCTION validate_field(pr_field_num) 
	## Common validation routines are NOT usually in max but has
	## been included here TO avoid gross duplication of code
	## This FUNCTION now uses validation based on whether the line
	## IS being added OR editted.
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_field_num SMALLINT, 
	ps_subdetl, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_product RECORD LIKE product.*, 
	pr_unit_amt LIKE subdetl.unit_amt, 
	i,idx SMALLINT 

	LET pr_subdetl.* = pr_gsubdetl.* 
	SELECT * INTO ps_subdetl.* 
	FROM t_subdetl 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	CASE pr_field_num 
		WHEN 0 ## "part_code" 
			IF pr_subdetl.part_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 error" code must be entered"
				RETURN false 
			END IF 
			IF ps_subdetl.part_code != pr_subdetl.part_code 
			OR ps_subdetl.part_code IS NULL THEN 
				SELECT * INTO pr_subproduct.* 
				FROM subproduct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_subdetl.part_code 
				AND type_code = pr_subhead.sub_type_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105" Subscription NOT found - Try Window "
					RETURN false 
				END IF 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_subdetl.part_code 
				IF NOT valid_part(glob_rec_kandoouser.cmpy_code, 
				pr_subdetl.part_code, 
				pr_subdetl.ware_code, 
				TRUE,2,0,"","","") 
				THEN 
					RETURN false 
				END IF 
				LET pr_subdetl.line_text = pr_product.desc_text 
				## Unit Price always calc. b/c in Add Mode
				IF pr_subproduct.linetype_ind = "1" THEN 
					SELECT unique 1 FROM subissues 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_subdetl.part_code 
					AND plan_iss_date between pr_subhead.start_date 
					AND pr_subhead.end_date 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("K",9106,"") 
						#9106" No issues scheduled FOR this product - use KZ2 "
						RETURN false 
					END IF 
				END IF 
				LET pr_subdetl.unit_amt = 
				unit_price(pr_subdetl.ware_code, 
				pr_subdetl.part_code, 
				pr_subdetl.level_code) 
				LET pr_subdetl.unit_tax_amt = 
				unit_tax(pr_subdetl.ware_code, 
				pr_subdetl.part_code, 
				pr_subdetl.unit_amt) 
			END IF 

		WHEN 1 ## "sub_qty" 
			IF pr_subdetl.sub_qty < 0 THEN 
				LET msgresp = kandoomsg("E",9180,"") 
				#9180 Quantity may NOT be negative
				LET pr_subdetl.sub_qty = 0 - pr_subdetl.sub_qty 
				LET pr_gsubdetl.* = pr_subdetl.* 
				RETURN false 
			END IF 
		WHEN 2 ## "unit_amt" 
			CASE 
				WHEN pr_subdetl.unit_amt IS NULL 
					LET pr_subdetl.unit_amt = 
					unit_price(pr_subdetl.ware_code, 
					pr_subdetl.part_code, 
					pr_subdetl.level_code) 
					LET pr_gsubdetl.* = pr_subdetl.* 
					RETURN false 
				WHEN (pr_subdetl.unit_amt < 0) 
					LET msgresp=kandoomsg("E",9239,"") 
					#9239 Selling price cannot be negative
					LET pr_gsubdetl.* = pr_subdetl.* 
					RETURN false 
				OTHERWISE 
					LET pr_subdetl.unit_tax_amt = 
					unit_tax(pr_subdetl.ware_code, 
					pr_subdetl.part_code, 
					pr_subdetl.unit_amt) 
			END CASE 
	END CASE 
	IF pr_subdetl.unit_tax_amt IS NULL THEN 
		LET pr_subdetl.unit_tax_amt = 0 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	CALL update_line() 
	SELECT * INTO pr_gsubdetl.* 
	FROM t_subdetl 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	RETURN true 
END FUNCTION 





FUNCTION sched_issue(pr_verbose_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_verbose_num SMALLINT, 
	pr_subissues RECORD LIKE subissues.*, 
	pr_subschedule RECORD LIKE subschedule.*, 
	pa_subschedule array[300] OF RECORD 
		scroll_flag CHAR(1), 
		issue_num SMALLINT, 
		desc_text CHAR(40), 
		sched_qty FLOAT, 
		issue_qty FLOAT, 
		inv_qty FLOAT, 
		sched_date DATE 
	END RECORD, 
	pr_temp_sched_qty FLOAT, 
	pr_part_desc,pr_part2_desc LIKE product.desc_text, 
	pr_sched_date DATE, 
	pr_lastkey INTEGER, 
	idx,scrn,cnt SMALLINT 
	DEFINE l_tmp_text CHAR(500) #huho moved FROM GLOBALS 


	LET pr_subdetl.* = pr_gsubdetl.* 
	IF pr_verbose_num THEN 
		OPEN WINDOW k131 at 2,4 WITH FORM "K131" 
		attribute(border) 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 Searching database please wait
		SELECT desc_text INTO pr_part_desc 
		FROM subproduct 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subdetl.part_code 
		AND type_code = pr_subhead.sub_type_code 
	END IF 
	DECLARE c_subschedule CURSOR FOR 
	SELECT * FROM t_subschedule 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	AND part_code = pr_subdetl.part_code 
	ORDER BY issue_num 
	LET idx = 0 
	FOREACH c_subschedule INTO pr_subschedule.* 
		LET idx = idx + 1 
		LET pa_subschedule[idx].issue_num = pr_subschedule.issue_num 
		LET pa_subschedule[idx].sched_qty = pr_subschedule.sched_qty 
		LET pa_subschedule[idx].issue_qty = pr_subschedule.issue_qty 
		LET pa_subschedule[idx].inv_qty = pr_subschedule.inv_qty 
		LET pa_subschedule[idx].sched_date = pr_subschedule.sched_date 
		LET pa_subschedule[idx].desc_text = pr_subschedule.desc_text 
		IF idx = 300 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		DECLARE c_subissues CURSOR FOR 
		SELECT * FROM subissues 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subdetl.part_code 
		AND plan_iss_date between pr_subhead.start_date 
		AND pr_subhead.end_date 
		AND issue_num >= last_issue_num 
		ORDER BY issue_num,plan_iss_date 
		FOREACH c_subissues INTO pr_subissues.* 
			LET idx = idx + 1 
			LET pa_subschedule[idx].issue_num = pr_subissues.issue_num 
			LET pa_subschedule[idx].sched_qty = 1 
			LET pa_subschedule[idx].issue_qty = 0 
			LET pa_subschedule[idx].inv_qty = 0 
			LET pa_subschedule[idx].sched_date = pr_subissues.plan_iss_date 
			LET pa_subschedule[idx].desc_text = pr_subissues.desc_text 
			IF idx = 300 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
	END IF 
	CALL set_count(idx) 
	LET pr_lastkey = 0 
	IF pr_verbose_num THEN 
		LET msgresp = kandoomsg("U",1003,"") 
		#1003 F1 add - F2 Delete - RETURN Edit
		DISPLAY pr_subdetl.part_code , 
		pr_part_desc, 
		pr_subhead.start_date, 
		pr_subhead.end_date 
		TO part_code, 
		part_text, 
		start_date, 
		end_date 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		INPUT ARRAY pa_subschedule WITHOUT DEFAULTS FROM sr_subschedule.* 

			ON ACTION "WEB-HELP" -- albo kd-374 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 

			ON KEY (control-b) 
				CASE 
					WHEN infield(issue_num) 
						LET l_tmp_text= " part_code = '",pr_subdetl.part_code,"' ", 
						"AND plan_iss_date between '",pr_subhead.start_date, 
						"' AND '",pr_subhead.end_date,"'" 
						LET l_tmp_text = show_sub_dates(glob_rec_kandoouser.cmpy_code,l_tmp_text,1) 
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
						IF l_tmp_text IS NOT NULL THEN 
							LET pa_subschedule[idx].issue_num = l_tmp_text 
							LET pr_lastkey = 9 
							NEXT FIELD issue_num 
						END IF 
				END CASE 
			ON KEY (F2) 
				CASE 
					WHEN infield(scroll_flag) 
						SELECT * INTO pr_subschedule.* 
						FROM t_subschedule 
						WHERE sub_line_num = pr_subdetl.sub_line_num 
						AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
						AND issue_num = pa_subschedule[idx].issue_num 
						IF status = 0 THEN 
							IF pr_subschedule.issue_qty > 0 OR 
							pr_subschedule.inv_qty > 0 THEN 
								LET msgresp = kandoomsg("K",9107,"") 
								NEXT FIELD scroll_flag 
							END IF 
						END IF 
						LET scrn = scr_line() 
						LET cnt = arr_count() 
						FOR idx = arr_curr() TO cnt 
							IF idx < cnt THEN 
								LET pa_subschedule[idx].* = pa_subschedule[idx+1].* 
							ELSE 
							INITIALIZE pa_subschedule[idx].* TO NULL 
						END IF 
						IF scrn <= 12 THEN 
							DISPLAY pa_subschedule[idx].* TO sr_subschedule[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET scrn = scr_line() 
					LET idx = arr_curr() 
					NEXT FIELD scroll_flag 
					OTHERWISE 
						NEXT FIELD scroll_flag 
				END CASE 
			BEFORE INSERT 
				NEXT FIELD issue_num 
			BEFORE FIELD issue_num 
				IF pr_lastkey = 9 THEN 
					LET pr_lastkey = 0 
				ELSE 
				IF pa_subschedule[idx].issue_num IS NOT NULL THEN 
					NEXT FIELD NEXT 
				END IF 
			END IF 
			AFTER FIELD issue_num 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("accept") 
						IF pa_subschedule[idx].issue_num IS NULL THEN 
							LET msgresp = kandoomsg("U",9102,"") 
							#9102 Value must be entered
							NEXT FIELD issue_num 
						END IF 
						FOR cnt = 1 TO arr_count() 
							IF pa_subschedule[cnt].issue_num IS NOT NULL AND 
							pa_subschedule[cnt].issue_num = 
							pa_subschedule[idx].issue_num THEN 
								IF cnt <> idx THEN 
									LET msgresp = kandoomsg("K",9108,"") 
									#9108 Issue has already been scheduled
									LET pa_subschedule[idx].issue_num = NULL 
									DISPLAY pa_subschedule[idx].issue_num TO 
									sr_subschedule[scrn].issue_num 

									NEXT FIELD issue_num 
								END IF 
							END IF 
						END FOR 
						SELECT * INTO pr_subissues.* 
						FROM subissues 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pr_subdetl.part_code 
						AND issue_num = pa_subschedule[idx].issue_num 
						AND plan_iss_date between pr_subhead.start_date 
						AND pr_subhead.end_date 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("K",9109,"") 
							LET pa_subschedule[idx].issue_num = NULL 
							DISPLAY pa_subschedule[idx].issue_num TO 
							sr_subschedule[scrn].issue_num 

							NEXT FIELD issue_num 
						ELSE 
						LET pa_subschedule[idx].sched_qty = 1 
						LET pa_subschedule[idx].issue_qty = 0 
						LET pa_subschedule[idx].inv_qty = 0 
						LET pa_subschedule[idx].sched_date =pr_subissues.plan_iss_date 
						LET pa_subschedule[idx].desc_text = pr_subissues.desc_text 
						NEXT FIELD NEXT 
					END IF 
					OTHERWISE 
						NEXT FIELD issue_num 
				END CASE 
			BEFORE FIELD sched_qty 
				LET pr_temp_sched_qty = pa_subschedule[idx].sched_qty 
			AFTER FIELD sched_qty 
				IF pa_subschedule[idx].sched_qty IS NULL THEN 
					LET msgresp = kandoomsg("K",9118,"") 
					LET pa_subschedule[idx].sched_qty = pr_temp_sched_qty 
					NEXT FIELD sched_qty 
				END IF 
				IF pa_subschedule[idx].sched_qty < pa_subschedule[idx].issue_qty 
				OR pa_subschedule[idx].sched_qty < pa_subschedule[idx].inv_qty THEN 
					LET msgresp = kandoomsg("K",9119,"") 
					LET pa_subschedule[idx].sched_qty = pr_temp_sched_qty 
					NEXT FIELD sched_qty 
				END IF 
			BEFORE FIELD sched_date 
				LET pr_sched_date = pa_subschedule[idx].sched_date 
			AFTER FIELD sched_date 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("accept") 
						IF pa_subschedule[idx].sched_date IS NULL THEN 
							LET pa_subschedule[idx].sched_date = pr_sched_date 
							LET msgresp = kandoomsg("U",9102,"") 
							NEXT FIELD sched_date 
						ELSE 
						IF pa_subschedule[idx].sched_date < pr_subhead.start_date 
						OR pa_subschedule[idx].sched_date > pr_subhead.end_date THEN 
							LET msgresp = kandoomsg("U",9110,"") 
							LET pa_subschedule[idx].sched_date = pr_sched_date 
							NEXT FIELD sched_date 
						END IF 
						NEXT FIELD scroll_flag 
					END IF 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
				END CASE 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
			END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW k131 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET pr_gsubdetl.* = pr_subdetl.* 
			RETURN false 
		END IF 
	END IF 
	DELETE FROM t_subschedule 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	FOR idx = 1 TO arr_count() 
		IF pa_subschedule[idx].issue_num IS NOT NULL THEN 
			LET pr_subschedule.sub_num = pr_subdetl.sub_num 
			LET pr_subschedule.sub_line_num = pr_subdetl.sub_line_num 
			LET pr_subschedule.part_code = pr_subdetl.part_code 
			LET pr_subschedule.sched_qty = pa_subschedule[idx].sched_qty 
			LET pr_subschedule.issue_qty = pa_subschedule[idx].issue_qty 
			LET pr_subschedule.issue_num = pa_subschedule[idx].issue_num 
			LET pr_subschedule.inv_qty = pa_subschedule[idx].inv_qty 
			LET pr_subschedule.desc_text = pa_subschedule[idx].desc_text 
			LET pr_subschedule.sched_date = pa_subschedule[idx].sched_date 
			INSERT INTO t_subschedule VALUES (pr_subschedule.*) 
		END IF 
	END FOR 
	SELECT sum(sched_qty), 
	sum(issue_qty) 
	INTO pr_subdetl.sub_qty, 
	pr_subdetl.issue_qty 
	FROM t_subschedule 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 
	AND part_code = pr_subdetl.part_code 
	IF pr_subdetl.sub_qty IS NULL THEN 
		LET pr_subdetl.sub_qty = 0 
	END IF 
	IF pr_subdetl.issue_qty IS NULL THEN 
		LET pr_subdetl.issue_qty = 0 
	END IF 
	LET pr_gsubdetl.* = pr_subdetl.* 
	RETURN true 
END FUNCTION 
