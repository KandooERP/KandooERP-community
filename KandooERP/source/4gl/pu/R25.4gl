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

	Source code beautified by beautify.pl on 2020-01-02 17:06:16	Source code beautified by beautify.pl on 2020-01-02 17:03:25	$Id: $
}


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
# \brief module R25 allows the user TO search FOR receipts on product id

GLOBALS 
	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pt_poaudit RECORD LIKE poaudit.*, 
	pr_product RECORD LIKE product.*, 
	pa_poaudit array[1000] OF RECORD 
		receipt_num LIKE poaudit.tran_num, 
		vend_code LIKE poaudit.vend_code, 
		order_num LIKE poaudit.po_num, 
		type_ind LIKE purchdetl.type_ind, 
		received_qty LIKE poaudit.received_qty, 
		uom_code LIKE purchdetl.uom_code, 
		acct_code LIKE purchdetl.acct_code 
	END RECORD, 
	sel_text, where_part CHAR(500) 
END GLOBALS 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R25") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r131 with FORM "R131" 
	CALL  windecoration_r("R131") 

	WHILE doit() 
	END WHILE 

	CLOSE WINDOW r131 

END MAIN 

FUNCTION doit() 
	DEFINE 
	msgresp LIKE language.yes_flag, 
	idx, scrn SMALLINT 

	LET pr_purchdetl.ref_text = arg_val(1) 
	SELECT * INTO pr_product.* FROM product 
	WHERE part_code = pr_purchdetl.ref_text 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1020,"Product Code") 
		#1020 Enter Product Code Details;  OK TO Continue.
		INPUT BY NAME pr_purchdetl.ref_text ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","R25","inp-purchdetl-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (control-b) 
				CASE 
					WHEN infield (ref_text) 
						LET pr_purchdetl.ref_text = show_item(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME pr_purchdetl.ref_text 

						NEXT FIELD ref_text 
				END CASE 

			AFTER FIELD ref_text 
				SELECT * INTO pr_product.* FROM product 
				WHERE part_code = pr_purchdetl.ref_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9010,"") 
					#9010 Product Code does NOT exist;  Try Window.
					NEXT FIELD ref_text 
				ELSE 
					DISPLAY BY NAME pr_product.desc_text 

				END IF 
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					SELECT * INTO pr_product.* FROM product 
					WHERE part_code = pr_purchdetl.ref_text 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",9010,"") 
						#9010 Product Code does NOT exist;  Try Window.
						NEXT FIELD ref_text 
					ELSE 
						DISPLAY BY NAME pr_product.desc_text 

					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	ELSE 
		DISPLAY BY NAME pr_purchdetl.ref_text, 
		pr_product.desc_text 

	END IF 

	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please Wait.
	DECLARE c_pord CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ref_text = pr_purchdetl.ref_text 
	LET idx = 0 
	FOREACH c_pord INTO pr_purchdetl.* 
		DECLARE audcurs CURSOR FOR 
		SELECT * FROM poaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cmpy_code = pr_purchdetl.cmpy_code 
		AND po_num = pr_purchdetl.order_num 
		AND line_num = pr_purchdetl.line_num 
		AND (poaudit.tran_code = "GA" OR 
		poaudit.tran_code = "GR") 
		ORDER BY tran_num 

		FOREACH audcurs INTO pr_poaudit.* 
			LET idx = idx + 1 
			LET pa_poaudit[idx].receipt_num = pr_poaudit.tran_num 
			LET pa_poaudit[idx].vend_code = pr_poaudit.vend_code 
			LET pa_poaudit[idx].order_num = pr_poaudit.po_num 
			LET pa_poaudit[idx].type_ind = pr_purchdetl.type_ind 
			LET pa_poaudit[idx].received_qty = pr_poaudit.received_qty 
			LET pa_poaudit[idx].uom_code = pr_purchdetl.uom_code 
			LET pa_poaudit[idx].acct_code = pr_purchdetl.acct_code 
			IF idx = 1000 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				#6100 First 1000 records selected only.  More may be ...
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 1000 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected.
	CALL set_count (idx) 
	LET msgresp = kandoomsg("U",1008,"") 
	#1008 F3/F4 TO Page Fwd/Bwd;  Ok TO Continue.
	INPUT ARRAY pa_poaudit WITHOUT DEFAULTS FROM sr_poaudit.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R25","inp-arr-poaudit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD tran_num 
			DISPLAY pa_poaudit[idx].* TO sr_poaudit[scrn].* 

		AFTER FIELD tran_num 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD tran_num 
			END IF 
		BEFORE FIELD vend_code 
			NEXT FIELD tran_num 
		AFTER ROW 
			DISPLAY pa_poaudit[idx].* TO sr_poaudit[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
