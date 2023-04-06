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

	Source code beautified by beautify.pl on 2020-01-03 09:12:50	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module : IZR - Promotion Maintenance
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	err_message CHAR(40) 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZR") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	OPEN WINDOW i680 with FORM "I680" 
	 CALL windecoration_i("I680") 

	WHILE select_pricing() 
		CALL scan_pricing() 
	END WHILE 

	CLOSE WINDOW i680 
END MAIN 


##################################################################################
# FUNCTION select_pricing()
##################################################################################
FUNCTION select_pricing() 
	DEFINE query_text CHAR(300) 
	DEFINE where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	LET l_msgresp = kandoomsg("W",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"

	CONSTRUCT BY NAME where_text ON offer_code, 
	desc_text, 
	type_ind, 
	start_date, 
	end_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZR","construct-promotion") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("W",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT rowid,* FROM pricing ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", where_text clipped," ", 
		"ORDER BY pricing.offer_code, ", 
		"pricing.start_date" 
		PREPARE s_pricing FROM query_text 
		DECLARE c_pricing CURSOR FOR s_pricing 
		RETURN true 
	END IF 

END FUNCTION 


##################################################################################
# FUNCTION scan_pricing()
##################################################################################
FUNCTION scan_pricing() 
	DEFINE pr_pricing RECORD LIKE pricing.* 
	DEFINE pr_custoffer RECORD LIKE custoffer.* 
	DEFINE pa_pricing array[200] OF 
	RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE pricing.offer_code, 
		desc_text LIKE pricing.desc_text, 
		type_ind LIKE pricing.type_ind, 
		start_date LIKE pricing.start_date, 
		end_date LIKE pricing.end_date 
	END RECORD 
	DEFINE pa_sub_code array[200] OF 
	RECORD 
		offer_code LIKE pricing.offer_code, 
		start_date LIKE pricing.start_date, 
		rowid INTEGER 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE pr_rowid INTEGER 
	DEFINE pr_curr,pr_cnt,idx,scrn,del_cnt,x SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DECLARE custcur SCROLL CURSOR FOR 
	SELECT * FROM custoffer 
	WHERE offer_code = pr_pricing.offer_code 
	AND offer_start_date = pr_pricing.start_date 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET idx = 0 

	FOREACH c_pricing INTO pr_rowid,pr_pricing.* 
		LET idx = idx + 1 
		LET pa_sub_code[idx].offer_code = pr_pricing.offer_code 
		LET pa_sub_code[idx].start_date = pr_pricing.start_date 
		LET pa_sub_code[idx].rowid = pr_rowid 
		LET pa_pricing[idx].offer_code = pr_pricing.offer_code 
		LET pa_pricing[idx].desc_text = pr_pricing.desc_text 
		LET pa_pricing[idx].type_ind = pr_pricing.type_ind 
		LET pa_pricing[idx].start_date = pr_pricing.start_date 
		LET pa_pricing[idx].end_date = pr_pricing.end_date 
		IF idx = 200 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113" idx entries selected"

	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_sub_code[idx].* TO NULL 
		INITIALIZE pa_pricing[idx].* TO NULL 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("W",1003,"") 
	#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit

	INPUT ARRAY pa_pricing WITHOUT DEFAULTS FROM sr_pricing.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZR","inp-arr-pricing") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_pricing[idx].scroll_flag 
			DISPLAY pa_pricing[idx].* TO sr_pricing[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_pricing[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_pricing[idx].scroll_flag TO sr_pricing[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				ELSE 
					IF pa_pricing[idx+1].offer_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp=kandoomsg("W",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		ON ACTION "EDIT" 
			NEXT FIELD offer_code 

		BEFORE FIELD offer_code 
			IF pa_pricing[idx].offer_code IS NOT NULL THEN 
				LET pr_pricing.offer_code = pa_sub_code[idx].offer_code 
				LET pr_pricing.start_date = pa_sub_code[idx].start_date 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = edit_pricing(pr_pricing.offer_code, 
				pr_pricing.start_date, 
				pa_sub_code[idx].rowid) 
				IF pr_rowid > 0 THEN 
					SELECT * INTO pr_pricing.* FROM pricing 
					WHERE rowid = pr_rowid 
					LET pa_sub_code[idx].rowid = pr_rowid 
					LET pa_pricing[idx].offer_code = pr_pricing.offer_code 
					LET pa_pricing[idx].desc_text = pr_pricing.desc_text 
					LET pa_pricing[idx].type_ind = pr_pricing.type_ind 
					LET pa_pricing[idx].start_date = pr_pricing.start_date 
					LET pa_pricing[idx].end_date = pr_pricing.end_date 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = edit_pricing("","",0) 

				IF pr_rowid = 0 THEN 

					FOR idx = pr_curr TO pr_cnt 
						LET pa_pricing[idx].* = pa_pricing[idx+1].* 
						IF idx = pr_cnt THEN 
							INITIALIZE pa_pricing[idx].* TO NULL 
						END IF 
						IF scrn <= 10 THEN 
							DISPLAY pa_pricing[idx].* TO sr_pricing[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					LET scrn = scr_line() 

				ELSE 

					FOR x = (pr_cnt+1) TO (idx + 1) step -1 
						LET pa_sub_code[x].offer_code = pa_sub_code[x-1].offer_code 
						LET pa_sub_code[x].start_date = pa_sub_code[x-1].start_date 
						LET pa_sub_code[x].rowid = pa_sub_code[x-1].rowid 
					END FOR 

					SELECT * INTO pr_pricing.* FROM pricing 
					WHERE rowid = pr_rowid 

					LET pa_pricing[idx].offer_code = pr_pricing.offer_code 
					LET pa_pricing[idx].desc_text = pr_pricing.desc_text 
					LET pa_pricing[idx].type_ind = pr_pricing.type_ind 
					LET pa_pricing[idx].start_date = pr_pricing.start_date 
					LET pa_pricing[idx].end_date = pr_pricing.end_date 
					LET pa_sub_code[idx].offer_code = pr_pricing.offer_code 
					LET pa_sub_code[idx].start_date = pr_pricing.start_date 
					LET pa_sub_code[idx].rowid = pr_rowid 
				END IF 

			ELSE 

				IF idx > 1 THEN 
					LET l_msgresp = kandoomsg("W",9001,"") 
					#9001 There are no more rows....
				END IF 

			END IF 

		ON KEY (F2) --delete 
			IF pa_pricing[idx].scroll_flag IS NULL THEN 
				IF pa_pricing[idx].type_ind = 1 
				OR pa_pricing[idx].type_ind = 5 THEN 
					LET pr_pricing.offer_code = pa_sub_code[idx].offer_code 
					LET pr_pricing.start_date = pa_sub_code[idx].start_date 
					OPEN custcur 
					FETCH custcur INTO pr_custoffer.* 

					IF status != notfound THEN 
						LET l_msgresp=kandoomsg("W",9123,"") 
						#9123 This Offer Code Is In Use
					END IF 

					CLOSE custcur 
				END IF 

				LET pa_pricing[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_pricing[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 

			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY pa_pricing[idx].* TO sr_pricing[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	############################

	GOTO bypass 

	LABEL recovery: 

	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i680 
		RETURN false 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			IF del_cnt > 0 THEN 
				LET l_msgresp = kandoomsg("W",8022,del_cnt) 
				#8022 Confirm TO Delete ",del_cnt," Special Offer(s)? (Y/N)"
				IF l_msgresp = "Y" THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_pricing[idx].scroll_flag = "*" THEN 
							DELETE FROM pricing 
							WHERE offer_code = pa_sub_code[idx].offer_code 
							AND start_date = pa_sub_code[idx].start_date 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							DELETE FROM custoffer 
							WHERE offer_code = pa_sub_code[idx].offer_code 
							AND offer_start_date = pa_sub_code[idx].start_date 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 
	COMMIT WORK 
END FUNCTION 


##################################################################################
# FUNCTION edit_pricing(pr_offer_code,pr_start_date,pr_rowid)
##################################################################################
FUNCTION edit_pricing(pr_offer_code,pr_start_date,pr_rowid) 
	DEFINE ps_pricing RECORD LIKE pricing.* 
	DEFINE pr_pricing RECORD LIKE pricing.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE pr_maingrp RECORD LIKE maingrp.* 
	DEFINE pr_prodgrp RECORD LIKE prodgrp.* 
	DEFINE pr_warehouse RECORD LIKE warehouse.* 
	DEFINE pr_class RECORD LIKE class.* 
	DEFINE pr_uom RECORD LIKE uom.* 
	DEFINE pr_offer_code LIKE pricing.offer_code 
	DEFINE pr_start_date DATE 
	DEFINE class_text CHAR(30) 
	DEFINE maingrp_text CHAR(30) 
	DEFINE prodgrp_text CHAR(30) 
	DEFINE product_text CHAR(30) 
	DEFINE pr_direction CHAR(10) 
	DEFINE pr_part_code LIKE product.part_code 
	DEFINE pr_prod_count INTEGER 
	DEFINE pr_rowid INTEGER 
	DEFINE pr_next_offer_code LIKE pricing.offer_code 
	DEFINE winds_text CHAR(40) 
	DEFINE price_text CHAR(40) 
	DEFINE pr_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW i681 with FORM "I681" 
	 CALL windecoration_i("I681") 

	INITIALIZE pr_pricing.* TO NULL 
	INITIALIZE pr_product.* TO NULL 
	INITIALIZE pr_maingrp.* TO NULL 
	INITIALIZE pr_prodgrp.* TO NULL 
	INITIALIZE pr_uom.* TO NULL 

	IF pr_offer_code IS NOT NULL THEN 
		SELECT * INTO pr_pricing.* FROM pricing 
		WHERE rowid = pr_rowid 
		LET price_text = NULL 

		IF pr_pricing.type_ind = 1 
		OR pr_pricing.type_ind = 5 
		OR pr_pricing.type_ind = 3 THEN 
			LET price_text = "Selected Customers Only" 
		END IF 

		IF pr_pricing.type_ind = 2 
		OR pr_pricing.type_ind = 6 
		OR pr_pricing.type_ind = 4 THEN 
			LET price_text = "All Customers" 
		END IF 
		DISPLAY BY NAME price_text 

		IF pr_pricing.part_code IS NOT NULL THEN 
			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = pr_pricing.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY pr_product.desc_text TO product_text 

		END IF 

		IF pr_pricing.prodgrp_code IS NOT NULL THEN 
			SELECT * INTO pr_prodgrp.* FROM prodgrp 
			WHERE prodgrp_code = pr_pricing.prodgrp_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY pr_prodgrp.desc_text TO prodgrp_text 

		END IF 

		IF pr_pricing.maingrp_code IS NOT NULL THEN 
			SELECT * INTO pr_maingrp.* FROM maingrp 
			WHERE maingrp_code = pr_pricing.maingrp_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY pr_maingrp.desc_text TO maingrp_text 

		END IF 

		IF pr_pricing.uom_code IS NOT NULL THEN 
			SELECT * INTO pr_uom.* FROM uom 
			WHERE uom_code = pr_pricing.uom_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY pr_uom.desc_text TO uom_text 

		END IF 

		IF pr_pricing.class_code IS NOT NULL THEN 
			SELECT * INTO pr_class.* FROM class 
			WHERE class_code = pr_pricing.class_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET class_text = pr_class.desc_text 
		END IF 

		IF pr_pricing.ware_code IS NOT NULL THEN 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE ware_code = pr_pricing.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DISPLAY pr_warehouse.desc_text TO ware_text 

		END IF 

	ELSE 

		LET pr_pricing.cmpy_code = glob_rec_kandoouser.cmpy_code 

	END IF 

	DISPLAY BY NAME pr_pricing.offer_code, 
	pr_pricing.desc_text, 
	pr_pricing.type_ind, 
	pr_pricing.start_date, 
	pr_pricing.end_date, 
	pr_pricing.prom1_text, 
	pr_pricing.prom2_text, 
	pr_pricing.maingrp_code, 
	pr_pricing.prodgrp_code, 
	pr_pricing.part_code, 
	pr_pricing.class_code, 
	pr_pricing.disc_price_amt, 
	pr_pricing.uom_code, 
	class_text, 
	pr_pricing.disc_per, 
	pr_pricing.list_level_ind 

	INPUT BY NAME pr_pricing.offer_code, 
	pr_pricing.desc_text, 
	pr_pricing.type_ind, 
	pr_pricing.start_date, 
	pr_pricing.end_date, 
	pr_pricing.prom1_text, 
	pr_pricing.prom2_text, 
	pr_pricing.maingrp_code, 
	pr_pricing.prodgrp_code, 
	pr_pricing.part_code, 
	pr_pricing.class_code, 
	pr_pricing.ware_code, 
	pr_pricing.disc_price_amt, 
	pr_pricing.uom_code, 
	pr_pricing.disc_per, 
	pr_pricing.list_level_ind WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZR","inp-pricing") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) infield (maingrp_code) 
			LET winds_text = NULL 
			LET winds_text = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.maingrp_code = winds_text 
				SELECT * INTO pr_maingrp.* FROM maingrp 
				WHERE maingrp_code = pr_pricing.maingrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_pricing.maingrp_code 

				DISPLAY pr_maingrp.desc_text TO maingrp_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD maingrp_code 

		ON KEY (control-b) infield (prodgrp_code) 
			LET winds_text = NULL 
			LET winds_text = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.prodgrp_code = winds_text 
				SELECT * INTO pr_prodgrp.* 
				FROM prodgrp 
				WHERE prodgrp_code = pr_pricing.prodgrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_pricing.prodgrp_code 

				DISPLAY pr_prodgrp.desc_text TO prodgrp_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD prodgrp_code 

		ON KEY (control-b) infield (part_code) 
			LET winds_text = NULL 
			LET winds_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.part_code = winds_text 
				SELECT * INTO pr_product.* FROM product 
				WHERE part_code = pr_pricing.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_pricing.part_code 

				DISPLAY pr_product.desc_text TO product_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD part_code 

		ON KEY (control-b) infield (class_code) 
			LET winds_text = NULL 
			LET winds_text = show_pcls(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.class_code = winds_text 
				SELECT * INTO pr_class.* FROM class 
				WHERE class_code = pr_pricing.class_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY pr_class.desc_text TO class_text 

			ELSE 
				DISPLAY '' TO class_text 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD class_code 

		ON KEY (control-b) infield (ware_code) 
			LET winds_text = NULL 
			LET winds_text = show_wlocn(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.ware_code = winds_text 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE ware_code = pr_pricing.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_pricing.ware_code 

				DISPLAY pr_warehouse.desc_text TO ware_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD ware_code 

		ON KEY (control-b) infield (uom_code) 
			LET winds_text = NULL 
			LET winds_text = show_uom(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_pricing.uom_code = winds_text 
				SELECT * INTO pr_uom.* 
				FROM uom 
				WHERE uom_code = pr_pricing.uom_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_pricing.uom_code 

				DISPLAY pr_uom.desc_text TO uom_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD uom_code 


		BEFORE FIELD offer_code 
			LET l_msgresp = kandoomsg("W",1034,"") 
			#1034 " Enter Customer Promotion Details; OK TO Continue
			IF pr_offer_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD offer_code 
			IF pr_pricing.offer_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9115,"") 
				#9115 " Customer Promotion Offer Code must be entered
				NEXT FIELD offer_code 
			END IF 

			SELECT unique offer_code FROM pricing 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND offer_code = pr_pricing.offer_code 

			IF status != notfound THEN 
				LET l_msgresp = kandoomsg("U",9104,"") 
				#9104 RECORD already exists
				NEXT FIELD offer_code 
			END IF 

		AFTER FIELD desc_text 
			IF pr_pricing.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9061,"") 
				#9061 " Description must be entered
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD type_ind 
			IF pr_offer_code IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD desc_text 
				ELSE 
					NEXT FIELD start_date 
				END IF 
			END IF 

		AFTER FIELD type_ind 
			IF pr_pricing.type_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9116,"") 
				#9116 " Offer Type Must be entered
				NEXT FIELD type_ind 
			ELSE 
				IF pr_pricing.type_ind != 1 
				AND pr_pricing.type_ind != 2 
				AND pr_pricing.type_ind != 3 
				AND pr_pricing.type_ind != 4 
				AND pr_pricing.type_ind != 5 
				AND pr_pricing.type_ind != 6 THEN 
					LET l_msgresp = kandoomsg("W",9925,"") 
					#9925  The type indicator must be either 1,2,3 OR 4.
					NEXT FIELD type_ind 
				END IF 

				IF pr_pricing.type_ind = 3 
				OR pr_pricing.type_ind = 4 THEN 
					IF pr_pricing.maingrp_code IS NOT NULL 
					OR pr_pricing.prodgrp_code IS NOT NULL 
					OR pr_pricing.part_code IS NOT NULL 
					OR pr_pricing.ware_code IS NOT NULL 
					OR pr_pricing.class_code IS NOT NULL 
					OR pr_pricing.disc_price_amt IS NOT NULL 
					OR pr_pricing.uom_code IS NOT NULL 
					OR pr_pricing.disc_per IS NOT NULL 
					OR pr_pricing.list_level_ind IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("W",9926,"") 
						#9926 No info in second section
						NEXT FIELD type_ind 
					END IF 
				END IF 

				LET price_text = NULL 
				IF pr_pricing.type_ind = 1 
				OR pr_pricing.type_ind = 5 
				OR pr_pricing.type_ind = 3 THEN 
					LET price_text = "Selected Customers Only" 
				END IF 

				IF pr_pricing.type_ind = 2 
				OR pr_pricing.type_ind = 6 
				OR pr_pricing.type_ind = 4 THEN 
					LET price_text = "All Customers" 
				END IF 

				DISPLAY BY NAME price_text 

			END IF 

		BEFORE FIELD start_date 
			IF pr_offer_code IS NOT NULL THEN 
				IF pr_start_date IS NOT NULL THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			END IF 

		AFTER FIELD start_date 
			IF pr_pricing.start_date IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9120,"") 
				#9120 " Start Date Must be entered
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD end_date 
			IF pr_pricing.end_date IS NOT NULL THEN 
				IF pr_pricing.start_date IS NOT NULL THEN 
					IF pr_pricing.start_date >= pr_pricing.end_date THEN 
						LET l_msgresp = kandoomsg("W",9117,"") 
						#9117 Start Date must be lower than END Date
						NEXT FIELD end_date 
					END IF 
				END IF 
			END IF 

		AFTER FIELD prom2_text 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD previous 
			END IF 
			IF pr_pricing.type_ind = 3 
			OR pr_pricing.type_ind = 4 THEN 
				IF pr_pricing.prom1_text IS NULL 
				AND pr_pricing.prom2_text IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD prom1_text 
				END IF 
				LET l_msgresp = kandoomsg("W",7048,"") 
				#7048 Confirm TO save Customer Promotion?
				IF l_msgresp = "Y" THEN 
					EXIT INPUT 
				ELSE 
					NEXT FIELD prom1_text 
				END IF 
			END IF 

		AFTER FIELD maingrp_code 
			INITIALIZE pr_maingrp.* TO NULL 
			IF pr_pricing.maingrp_code IS NOT NULL THEN 
				IF pr_pricing.prodgrp_code IS NOT NULL 
				OR pr_pricing.part_code IS NOT NULL 
				OR pr_pricing.class_code IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("W",9097,"") 
					#9097 Only One Of Product,Group,Main Group can Be Entered
					NEXT FIELD maingrp_code 
				END IF 
				SELECT * INTO pr_maingrp.* FROM maingrp 
				WHERE maingrp_code = pr_pricing.maingrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9210,"") 
					#9210 Main Product Group Not Found - Try Window
					NEXT FIELD maingrp_code 
				END IF 
			END IF 
			DISPLAY pr_maingrp.desc_text TO maingrp_text 

		AFTER FIELD prodgrp_code 
			INITIALIZE pr_prodgrp.* TO NULL 
			IF pr_pricing.prodgrp_code IS NOT NULL THEN 
				IF pr_pricing.maingrp_code IS NOT NULL 
				OR pr_pricing.part_code IS NOT NULL 
				OR pr_pricing.class_code IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("W",9097,"") 
					#9097 Only One Of Product,Group,Main Group can Be Entered
					NEXT FIELD prodgrp_code 
				END IF 
				SELECT * INTO pr_prodgrp.* FROM prodgrp 
				WHERE prodgrp_code = pr_pricing.prodgrp_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("W",9209,"") 
					#9209 Product Group Not Found - Try Window
					NEXT FIELD prodgrp_code 
				END IF 
			END IF 
			DISPLAY pr_prodgrp.desc_text TO prodgrp_text 

		BEFORE FIELD part_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				IF pr_pricing.maingrp_code IS NULL 
				AND pr_pricing.prodgrp_code IS NULL THEN 

					IF fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") THEN 
						LET pr_direction = "up" 
					ELSE 
						LET pr_direction = "down" 
					END IF 

					CALL form_part_code(glob_rec_kandoouser.cmpy_code, pr_pricing.class_code, 
					pr_pricing.part_code) 
					RETURNING pr_pricing.class_code, pr_pricing.part_code 

					DISPLAY BY NAME pr_pricing.part_code 

					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 

					LET pr_product.desc_text = NULL 

					IF pr_pricing.part_code IS NOT NULL THEN 
						LET pr_part_code = pr_pricing.part_code clipped 
						SELECT count(*) INTO pr_prod_count FROM product 
						WHERE part_code matches pr_part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 

						IF pr_prod_count = 1 THEN 
							SELECT * INTO pr_product.* FROM product 
							WHERE part_code matches pr_pricing.part_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 

						LET pr_pricing.maingrp_code = NULL 
						LET pr_pricing.prodgrp_code = NULL 
						LET maingrp_text = NULL 
						LET prodgrp_text = NULL 
						LET product_text = pr_product.desc_text 
					END IF 

					LET pr_class.desc_text = NULL 

					SELECT * INTO pr_class.* FROM class 
					WHERE class_code = pr_pricing.class_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET class_text = pr_class.desc_text 

					DISPLAY BY NAME prodgrp_text, 
					maingrp_text, 
					product_text, 
					class_text, 
					pr_pricing.part_code, 
					pr_pricing.class_code, 
					pr_pricing.prodgrp_code, 
					pr_pricing.maingrp_code 

					IF pr_direction = "up" THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 

				ELSE 

					LET pr_pricing.part_code = NULL 
					LET product_text = NULL 

					DISPLAY BY NAME pr_pricing.part_code, 
					product_text 


					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			END IF 

		AFTER FIELD part_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "N" THEN 
				INITIALIZE pr_product.* TO NULL 

				IF pr_pricing.part_code IS NOT NULL THEN 
					IF pr_pricing.maingrp_code IS NOT NULL 
					OR pr_pricing.prodgrp_code IS NOT NULL 
					OR pr_pricing.class_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("W",9097,"") 
						#9097 Only One Of Product,Group,Main Group can Be Entered
						NEXT FIELD part_code 
					END IF 

					SELECT * INTO pr_product.* FROM product 
					WHERE part_code = pr_pricing.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD Not Found; Try Window.
						NEXT FIELD part_code 
					END IF 
				END IF 
				DISPLAY pr_product.desc_text 
				TO product_text 

			END IF 

		BEFORE FIELD class_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD class_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "N" THEN 
				INITIALIZE pr_class.* TO NULL 

				IF pr_pricing.class_code IS NOT NULL THEN 
					IF pr_pricing.maingrp_code IS NOT NULL 
					OR pr_pricing.part_code IS NOT NULL 
					OR pr_pricing.prodgrp_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("W",9097,"") 
						#9097 Only One Of Product,Group,Main Group can Be Entered
						NEXT FIELD class_code 
					END IF 

					SELECT * INTO pr_class.* FROM class 
					WHERE class_code = pr_pricing.class_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD Not Found; Try Window.
						NEXT FIELD class_code 
					END IF 

				END IF 
				DISPLAY pr_class.desc_text 
				TO class_text 

			ELSE 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD ware_code 
			INITIALIZE pr_warehouse.* TO NULL 

			IF pr_pricing.ware_code IS NOT NULL THEN 
				SELECT * INTO pr_warehouse.* FROM warehouse 
				WHERE ware_code = pr_pricing.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD ware_code 
				END IF 

			END IF 
			DISPLAY pr_warehouse.desc_text TO ware_text 

			IF fgl_lastkey() != fgl_keyval("up") 
			AND fgl_lastkey() != fgl_keyval("left") THEN 
				IF pr_pricing.type_ind = 5 
				OR pr_pricing.type_ind = 6 THEN 
					IF pr_pricing.maingrp_code IS NULL 
					AND pr_pricing.prodgrp_code IS NULL 
					AND pr_pricing.part_code IS NULL 
					AND pr_pricing.class_code IS NULL 
					AND pr_pricing.ware_code IS NULL THEN 
						IF kandoomsg("A",8039,"") = "N" THEN 
							#8039 No Criteria Entered
							NEXT FIELD maingrp_code 
						ELSE 
							EXIT INPUT 
						END IF 
					END IF 
				END IF 

				IF pr_pricing.type_ind = "5" 
				OR pr_pricing.type_ind = "6" THEN 
					LET l_msgresp = kandoomsg("W",7048,"") 

					IF l_msgresp = "Y" THEN 
						EXIT INPUT 
					ELSE 
						NEXT FIELD maingrp_code 
					END IF 

				END IF 

			END IF 

		AFTER FIELD uom_code 
			IF pr_pricing.disc_price_amt IS NOT NULL THEN 
				IF pr_pricing.uom_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9082,"") 
					#9082 Unit Of Measure Must Be Entered
					NEXT FIELD uom_code 
				ELSE 
					SELECT * INTO pr_uom.* FROM uom 
					WHERE uom_code = pr_pricing.uom_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9212,"") 
						#9212 Unit Of Measure Code NOT found - Try window
						NEXT FIELD uom_code 
					ELSE 
						DISPLAY BY NAME pr_pricing.uom_code 

						DISPLAY pr_uom.desc_text TO uom_text 

					END IF 
				END IF 

			ELSE 
				LET pr_uom.desc_text = NULL 
				DISPLAY pr_uom.desc_text TO uom_text 

			END IF 

		AFTER FIELD disc_per 
			IF pr_pricing.disc_per IS NULL THEN 
				IF pr_pricing.disc_price_amt IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9118,"") 
					#9118 One Of Discount Price OR Discount Percent Must Be Entered
					NEXT FIELD disc_price_amt 
				END IF 
			ELSE 
				IF pr_pricing.disc_price_amt IS NOT NULL THEN 
					LET l_msgresp = kandoomsg("W",9119,"") 
					#9119 Only One Of Discount Price OR Discount Percent Must Be Entered
					NEXT FIELD disc_price_amt 
				END IF 
			END IF 

			IF pr_pricing.disc_per IS NOT NULL THEN 
				LET pr_pricing.uom_code = NULL 
			END IF 

		AFTER FIELD list_level_ind 
			IF pr_pricing.disc_per IS NOT NULL THEN 
				IF pr_pricing.list_level_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9119,"") 
					#9119 Price Level must be entered
					NEXT FIELD list_level_ind 
				ELSE 

					IF pr_pricing.list_level_ind <> "L" AND 
					pr_pricing.list_level_ind <> "1" AND 
					pr_pricing.list_level_ind <> "2" AND 
					pr_pricing.list_level_ind <> "3" AND 
					pr_pricing.list_level_ind <> "4" AND 
					pr_pricing.list_level_ind <> "5" AND 
					pr_pricing.list_level_ind <> "6" AND 
					pr_pricing.list_level_ind <> "7" AND 
					pr_pricing.list_level_ind <> "8" AND 
					pr_pricing.list_level_ind <> "9" THEN 
						LET l_msgresp = kandoomsg("W",9160,"") 
						#9160 Price Level must be entered
						NEXT FIELD list_level_ind 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_pricing.offer_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9115,"") 
					#9115 " Customer Promotion Offer Code Must Be Entered
					NEXT FIELD offer_code 
				END IF 

				IF pr_pricing.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9061,"") 
					#9061 " Description must be entered
					NEXT FIELD desc_text 
				END IF 

				IF pr_pricing.type_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9116,"") 
					#9116 Pricing Type Must Be Entered
					NEXT FIELD type_ind 
				END IF 

				IF pr_pricing.start_date IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD start_date 
				END IF 

				IF pr_pricing.type_ind = 3 
				OR pr_pricing.type_ind = 4 THEN 
					IF pr_pricing.prom1_text IS NULL 
					AND pr_pricing.prom2_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD prom1_text 
					END IF 
				END IF 

				IF pr_pricing.type_ind != 3 
				AND pr_pricing.type_ind != 4 THEN 
					IF pr_pricing.part_code IS NOT NULL THEN 
						IF pr_pricing.prodgrp_code IS NOT NULL OR 
						pr_pricing.maingrp_code IS NOT NULL THEN 
							LET l_msgresp = kandoomsg("W",9097,"") 
							#9097 Only One Of Product,Group,Main Group can Be Entered
							NEXT FIELD maingrp_code 
						END IF 
					END IF 

					IF pr_pricing.prodgrp_code IS NOT NULL THEN 
						IF pr_pricing.part_code IS NOT NULL OR 
						pr_pricing.maingrp_code IS NOT NULL THEN 
							LET l_msgresp = kandoomsg("W",9097,"") 
							#9097 Only One Of Product,Group,Main Group can Be Entered
							NEXT FIELD maingrp_code 
						END IF 
					END IF 

					IF pr_pricing.maingrp_code IS NOT NULL THEN 
						IF pr_pricing.part_code IS NOT NULL OR 
						pr_pricing.prodgrp_code IS NOT NULL THEN 
							LET l_msgresp = kandoomsg("W",9097,"") 
							#9097 Only One Of Product,Group,Main Group can Be Entered
							NEXT FIELD maingrp_code 
						END IF 
					END IF 

					IF pr_pricing.type_ind != 5 
					AND pr_pricing.type_ind != 6 THEN 
						IF pr_pricing.disc_per IS NULL THEN 
							IF pr_pricing.disc_price_amt IS NULL THEN 
								LET l_msgresp = kandoomsg("W",9118,"") 
								#9118 Discount Price OR Discount Percent Must Be Entered
								NEXT FIELD disc_price_amt 
							END IF 
						ELSE 
							IF pr_pricing.disc_price_amt IS NOT NULL THEN 
								LET l_msgresp = kandoomsg("W",9119,"") 
								#9119 Discount Price OR Discount Percent Must Be Entered
								NEXT FIELD disc_price_amt 
							END IF 
						END IF 

						IF pr_pricing.disc_price_amt IS NOT NULL THEN 
							IF pr_pricing.uom_code IS NULL THEN 
								LET l_msgresp = kandoomsg("W",9082,"") 
								#9082 Unit Of Measure Must Be Entered
								NEXT FIELD uom_code 
							END IF 
						END IF 

						IF pr_pricing.disc_per IS NOT NULL THEN 
							IF pr_pricing.list_level_ind IS NULL THEN 
								LET l_msgresp = kandoomsg("W",9119,"") 
								#9119 Price Level must be entered
								NEXT FIELD list_level_ind 
							ELSE 
								IF pr_pricing.list_level_ind <> "L" AND 
								pr_pricing.list_level_ind <> "1" AND 
								pr_pricing.list_level_ind <> "2" AND 
								pr_pricing.list_level_ind <> "3" AND 
								pr_pricing.list_level_ind <> "4" AND 
								pr_pricing.list_level_ind <> "5" AND 
								pr_pricing.list_level_ind <> "6" AND 
								pr_pricing.list_level_ind <> "7" AND 
								pr_pricing.list_level_ind <> "8" AND 
								pr_pricing.list_level_ind <> "9" THEN 
									LET l_msgresp = kandoomsg("W",9160,"") 
									#9160 Price Level must be entered
									NEXT FIELD list_level_ind 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 

				IF pr_pricing.start_date IS NOT NULL THEN 
					SELECT * INTO ps_pricing.* FROM pricing 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = pr_pricing.offer_code 
					AND start_date = pr_pricing.start_date 
				ELSE 
					SELECT * INTO ps_pricing.* FROM pricing 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = pr_pricing.offer_code 
					AND start_date IS NULL 
				END IF 

				IF pr_offer_code IS NULL THEN 
					IF status != notfound THEN 
						LET l_msgresp = kandoomsg("W",9225,"") 
						#9225 Offer Code / Start Date Combination Already Exists
						NEXT FIELD offer_code 
					END IF 
				ELSE 
					IF pr_pricing.start_date != pr_start_date THEN 
						IF status != notfound THEN 
							LET l_msgresp = kandoomsg("W",9225,"") 
							#9225 Offer Code / Start Date Combination Already Exists
							NEXT FIELD start_date 
						END IF 
					END IF 
				END IF 

				IF pr_pricing.type_ind = 3 
				OR pr_pricing.type_ind = 4 THEN 
					LET l_msgresp = kandoomsg("W",7048,"") 
					IF l_msgresp != "Y" THEN 
						NEXT FIELD prom1_text 
					END IF 
				END IF 

				IF pr_pricing.type_ind = 5 
				OR pr_pricing.type_ind = 6 THEN 
					IF pr_pricing.maingrp_code IS NULL 
					AND pr_pricing.prodgrp_code IS NULL 
					AND pr_pricing.part_code IS NULL 
					AND pr_pricing.class_code IS NULL 
					AND pr_pricing.ware_code IS NULL THEN 
						IF kandoomsg("A",8039,"") = "N" THEN 
							#8039 No Criteria Entered
							NEXT FIELD maingrp_code 
						END IF 
					ELSE 
						LET l_msgresp = kandoomsg("W",7048,"") 
						IF l_msgresp = "N" THEN 
							NEXT FIELD maingrp_code 
						END IF 
					END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	################################

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i681 
		RETURN false 
	END IF 

	GOTO bypass 

	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i681 
		RETURN false 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "IZR - Updating Customer Promotions" 
		IF pr_offer_code IS NULL THEN 
			INSERT INTO pricing VALUES (pr_pricing.*) 
			LET pr_sqlerrd = sqlca.sqlerrd[6] 
		ELSE 
			UPDATE pricing 
			SET * = pr_pricing.* 
			WHERE rowid = pr_rowid 
			LET pr_sqlerrd = pr_rowid 
		END IF 

	COMMIT WORK 
	CLOSE WINDOW i681 
	RETURN pr_sqlerrd 
END FUNCTION 
