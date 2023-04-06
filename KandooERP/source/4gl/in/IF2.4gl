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

	Source code beautified by beautify.pl on 2020-01-03 09:12:36	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IF2 allows the user TO scan Valuation costs.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pa_prodstat array[200] OF RECORD 
		ware_code LIKE prodstatus.ware_code, 
		wgted_cost_amt DECIMAL(16,2), 
		est_cost_amt DECIMAL(16,2), 
		act_cost_amt DECIMAL(16,2), 
		fifo_lifo DECIMAL(16,2) 
	END RECORD, 
	pr_ware_code LIKE warehouse.ware_code, 
	where_part CHAR(900), 
	query_text CHAR(990), 
	runner, filter_text CHAR(512), 
	idx, scrn SMALLINT 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IF2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5002,"") 
		#5002" Inventory parameters are NOT SET up - Refer Menu IZP
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW i125 with FORM "I125" 
	 CALL windecoration_i("I125") -- albo kd-758 

	IF num_args() > 0 THEN 
		LET pr_prodstatus.part_code = arg_val(1) 
		CALL disp_product() 
		CALL scan_prod() 
	ELSE 
		WHILE select_prod() 
			CALL scan_prod() 
		END WHILE 
	END IF 
	CLOSE WINDOW i125 
END MAIN 


FUNCTION disp_product() 
	LET msgresp = kandoomsg("I",1001,"") 
	# 1001" Enter Selection Criteria - ESC TO Continue"

	DISPLAY pr_prodstatus.part_code TO prodstatus.part_code 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodstatus.part_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",5010,pr_prodstatus.part_code) 
		#5010" Logic error: Product code NOT found ????"
		EXIT program 
	END IF 
	DISPLAY pr_product.desc_text, 
	pr_product.desc2_text 
	TO product.desc_text, 
	product.desc2_text 
END FUNCTION 


FUNCTION select_prod() 
	LET msgresp = kandoomsg("I",1001,"") 
	# 1001" Enter Selection Criteria - ESC TO Continue"

	INPUT BY NAME pr_prodstatus.part_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IF2","input-pr_prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET pr_prodstatus.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_prodstatus.part_code 
					NEXT FIELD part_code 
			END CASE 
		AFTER FIELD part_code 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY pr_product.desc_text, 
				pr_product.desc2_text 
				TO product.desc_text, 
				product.desc2_text 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION scan_prod() 

	CONSTRUCT BY NAME where_part ON ware_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IF2","construct-ware_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET query_text = "SELECT * FROM prodstatus", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND part_code = \"",pr_prodstatus.part_code,"\" ", 
	" AND ",where_part clipped," ", 
	"ORDER BY ware_code" 
	LET idx = 0 
	PREPARE s_product FROM query_text 
	DECLARE c_product SCROLL CURSOR FOR s_product 
	FOREACH c_product INTO pr_prodstatus.* 
		LET idx = idx + 1 
		LET pa_prodstat[idx].ware_code = pr_prodstatus.ware_code 
		LET pa_prodstat[idx].wgted_cost_amt = pr_prodstatus.wgted_cost_amt * 
		pr_prodstatus.onhand_qty 
		LET pa_prodstat[idx].est_cost_amt = pr_prodstatus.est_cost_amt * 
		pr_prodstatus.onhand_qty 
		LET pa_prodstat[idx].act_cost_amt = pr_prodstatus.act_cost_amt * 
		pr_prodstatus.onhand_qty 
		LET pa_prodstat[idx].fifo_lifo = NULL 
		IF pr_inparms.cost_ind = "F" 
		OR pr_inparms.cost_ind = "L" THEN 
			SELECT sum(curr_cost_amt * onhand_qty) INTO pa_prodstat[idx].fifo_lifo 
			FROM costledg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
		END IF 
		IF idx > 200 THEN 
			LET msgresp=kandoomsg("I",9078,200) 
			#9078 "Only first ??? Product Status rows Selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("I",9099,"") 
		#9099 No product STATUS satisfied the selection criteria
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 

	IF pr_inparms.cost_ind = "L" 
	OR pr_inparms.cost_ind = "F" THEN 
		LET msgresp = kandoomsg("I",1007,"") 
		# F3/F4 TO page forward/backward RETURN on line TO View
	ELSE 
		LET msgresp = kandoomsg("I",1008,"") 
		# F3/F4 TO page forward/backward ESC TO continue
	END IF 
	INPUT ARRAY pa_prodstat WITHOUT DEFAULTS FROM sr_prodstat.* 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD ware_code 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_ware_code = pa_prodstat[idx].ware_code 
			DISPLAY pa_prodstat[idx].* TO sr_prodstat[scrn].* 
		AFTER FIELD ware_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_prodstat[idx+1].ware_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("I",9001,"") 
					# There are no more rows in the direction you are going
					NEXT FIELD ware_code 
				END IF 
			END IF 

		BEFORE FIELD wgted_cost_amt 
			IF (pr_inparms.cost_ind = "L" 
			OR pr_inparms.cost_ind = "F") 
			AND pa_prodstat[idx].fifo_lifo IS NOT NULL THEN 
				#             LET runner = "fglgo I1F_H '",pr_prodstatus.part_code,"' ",
				#                                      "'",pr_ware_code,"'"
				#             run runner
				CALL run_prog("IF3",pr_prodstatus.part_code, 
				pr_ware_code, "", "") 
			END IF 
			LET pa_prodstat[idx].ware_code = pr_ware_code 
			DISPLAY pa_prodstat[idx].* TO sr_prodstat[scrn].* 
			NEXT FIELD ware_code 

		AFTER ROW 
			LET pa_prodstat[idx].ware_code = pr_ware_code 
			DISPLAY pa_prodstat[idx].* TO sr_prodstat[scrn].* 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLEAR FORM 
END FUNCTION 
