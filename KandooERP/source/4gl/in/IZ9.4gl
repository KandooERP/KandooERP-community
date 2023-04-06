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

	Source code beautified by beautify.pl on 2020-01-03 09:12:48	$Id: $
}




#                 IZ9 Warehouse Image Program
#  Allows the user TO image a warehouse AND products TO a new warehouse
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_country RECORD LIKE country.* #pr_country 
END GLOBALS 




####################################################################
# MAIN
#
#
####################################################################
MAIN 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("IZ9") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	SELECT * INTO glob_rec_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",5003,"") 
		#5003 Company NOT SET up - Refer System Administrator
		EXIT program 
	END IF 
	SELECT country.* INTO glob_rec_country.* 
	FROM company, country 
	WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND country.country_code = company.country_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET glob_rec_country.state_code_text ="State........" 
		LET glob_rec_country.post_code_text = "Post Code.........." 
	ELSE 
		LET i = length(glob_rec_country.state_code_text) 
		LET glob_rec_country.state_code_text[i+1,20] = "................." 
		LET i = length(glob_rec_country.post_code_text) 
		LET glob_rec_country.post_code_text[i+1,20] = "................." 
	END IF 
	OPEN WINDOW i133 with FORM "I133" 
	 CALL windecoration_i("I133") -- albo kd-758 
	WHILE select_ware() 
		CALL scan_ware() 
	END WHILE 
	CLOSE WINDOW i133 
END MAIN 


####################################################################
# FUNCTION select_ware()
#
#
####################################################################
FUNCTION select_ware() 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON ware_code, 
	desc_text, 
	contact_text, 
	tele_text,
	mobile_phone,
	email

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZ9","construct-ware_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database;  Please wait.
		LET l_query_text = "SELECT * FROM warehouse ", 
		"WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"ware_code" 
		PREPARE s_warehouse FROM l_query_text 
		DECLARE c_warehouse CURSOR FOR s_warehouse 
		RETURN true 
	END IF 
END FUNCTION 


####################################################################
# FUNCTION scan_ware()
#
#
####################################################################
FUNCTION scan_ware() 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF RECORD 
		--         scroll_flag CHAR(1), -- albo KD-1062
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text, 
		contact_text LIKE warehouse.contact_text, 
		tele_text LIKE warehouse.tele_text,
		mobile_phone LIKE warehouse.mobile_phone,
		email LIKE warehouse.email 
	END RECORD 
	DEFINE idx SMALLINT 
	DEFINE del_cnt SMALLINT 

	DEFINE l_resort_array SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET idx = 0 
	FOREACH c_warehouse INTO l_rec_warehouse.* 
		LET idx = idx + 1 
		--      LET l_arr_rec_warehouse[idx].scroll_flag = NULL  -- albo KD-1062
		LET l_arr_rec_warehouse[idx].ware_code = l_rec_warehouse.ware_code 
		LET l_arr_rec_warehouse[idx].desc_text = l_rec_warehouse.desc_text 
		LET l_arr_rec_warehouse[idx].contact_text = l_rec_warehouse.contact_text 
		LET l_arr_rec_warehouse[idx].tele_text = l_rec_warehouse.tele_text 
		LET l_arr_rec_warehouse[idx].mobile_phone = l_rec_warehouse.mobile_phone
		LET l_arr_rec_warehouse[idx].email = l_rec_warehouse.email
	END FOREACH 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("I",1019,"") 
	# 1019 RETURN on line TO SELECT Source Warehouse TO Image
	INPUT ARRAY l_arr_rec_warehouse WITHOUT DEFAULTS FROM sr_warehouse.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ9","input-l_arr_rec_warehouse-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
			{  -- albo KD-1062
			      BEFORE FIELD scroll_flag
			         LET idx = arr_curr()
			         LET scrn = scr_line()
			         LET l_scroll_flag = l_arr_rec_warehouse[idx].scroll_flag
			         DISPLAY l_arr_rec_warehouse[idx].*
			              TO sr_warehouse[scrn].*

			      AFTER FIELD scroll_flag
			         LET l_arr_rec_warehouse[idx].scroll_flag = l_scroll_flag
			         DISPLAY l_arr_rec_warehouse[idx].scroll_flag
			              TO sr_warehouse[scrn].scroll_flag

			         IF fgl_lastkey() = fgl_keyval("down")
			         AND arr_curr() >= arr_count() THEN
			            LET l_msgresp = kandoomsg("U",9001,"")
			# There are no more rows in the direction you are going.
			            NEXT FIELD scroll_flag
			         END IF
			}
		BEFORE FIELD ware_code 
			CALL image_criteria(l_arr_rec_warehouse[idx].ware_code) 
			LET l_resort_array = true 
			CLOSE WINDOW i171 
			EXIT INPUT 
			--         NEXT FIELD scroll_flag  -- albo KD-1062
			#      AFTER ROW
			#         DISPLAY l_arr_rec_warehouse[idx].*
			#              TO sr_warehouse[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 


####################################################################
# FUNCTION check_parents(p_part_code, p_target_ware, p_cmpy)
#
#
####################################################################
FUNCTION check_parents(p_part_code, p_target_ware, p_cmpy) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_target_ware LIKE warehouse.ware_code 
	DEFINE p_cmpy LIKE company.cmpy_code 

	DEFINE l_class_code LIKE class.class_code 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_flex SMALLINT 
	DEFINE l_pr_parent_part LIKE product.part_code 
	DEFINE l_flex_part LIKE product.part_code 
	DEFINE l_dashes LIKE product.part_code 

	SELECT product.class_code INTO l_class_code FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = p_cmpy 
	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN -1 
	END IF 
	SELECT * INTO l_rec_class.* 
	FROM class 
	WHERE class_code = l_class_code 
	AND cmpy_code = p_cmpy 
	
	CALL break_prod(p_cmpy,p_part_code,l_rec_class.class_code,0) 
	RETURNING l_pr_parent_part,l_dashes,l_flex_part,l_flex 
	IF l_pr_parent_part = p_part_code THEN 
		RETURN true 
	END IF 
	SELECT part_code INTO p_part_code 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_pr_parent_part 
	AND ware_code = p_target_ware 
	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 



####################################################################
# FUNCTION image_criteria(p_source_ware)
#
#
####################################################################
FUNCTION image_criteria(p_source_ware) 
	DEFINE p_source_ware LIKE warehouse.ware_code 

	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_target_ware LIKE warehouse.ware_code 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_query1_text STRING 
	DEFINE l_query2_text STRING 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message STRING 
	DEFINE l_okay INTEGER 
	DEFINE l_total INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE l_exists INTEGER 

	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW i171 with FORM "I171" 
	 CALL windecoration_i("I171") -- albo kd-758 

	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND warehouse.ware_code = p_source_ware 
	DISPLAY l_rec_warehouse.ware_code, 
	l_rec_warehouse.desc_text, 
	l_rec_warehouse.addr1_text, 
	l_rec_warehouse.addr2_text, 
	l_rec_warehouse.city_text, 
	glob_rec_country.state_code_text, 
	glob_rec_country.state_code_text, 
	l_rec_warehouse.state_code, 
	glob_rec_country.post_code_text, 
	glob_rec_country.post_code_text, 
	l_rec_warehouse.post_code, 
	l_rec_warehouse.country_code, 
	l_rec_warehouse.contact_text, 
	l_rec_warehouse.tele_text,
	l_rec_warehouse.mobile_phone,
	l_rec_warehouse.email

	TO pr_ware_code, 
	pr_desc_text, 
	pr_addr1_text, 
	pr_addr2_text, 
	pr_city_text, 
	country.state_code_text, 
	pr_state_code, 
	pr_state_code, 
	country.post_code_text, 
	pr_post_text, 
	pr_post_code, 
	pr_country_code, 
	pr_contact_text, 
	pr_tele_text,
	pr_mobile_phone,
	pr_email


	#  INITIALIZE l_rec_warehouse.* TO NULL
	WHILE true 
		CLEAR desc_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		contact_text, 
		tele_text 


		INPUT BY NAME l_rec_warehouse.ware_code WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IZ9","input-l_arr_rec_warehouse-2") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				IF infield(ware_code) THEN 
					LET l_rec_warehouse.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD ware_code 
				END IF 

			AFTER FIELD ware_code 
				IF l_rec_warehouse.ware_code IS NULL THEN 
					error" Warehouse Code must be Entered " 
					NEXT FIELD ware_code 
				END IF 

				#         ON KEY (control-w)
				#            CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 

		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_rec_warehouse.ware_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			MENU " Warehouse Does NOT Exist " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","IZ9","menu-Warehouse_Does-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Create" 
					#DISPLAY "" AT 1,1
					INPUT BY NAME l_rec_warehouse.desc_text, 
					l_rec_warehouse.addr1_text, 
					l_rec_warehouse.addr2_text, 
					l_rec_warehouse.city_text, 
					l_rec_warehouse.state_code, 
					l_rec_warehouse.post_code, 
					l_rec_warehouse.country_code, 
					l_rec_warehouse.contact_text, 
					l_rec_warehouse.tele_text,
					l_rec_warehouse.mobile_phone,
					l_rec_warehouse.email

						BEFORE INPUT 
							CALL publish_toolbar("kandoo","IZ9","input-l_arr_rec_warehouse-3") -- albo kd-505 

						ON ACTION "WEB-HELP" -- albo kd-372 
							CALL onlinehelp(getmoduleid(),null) 

						AFTER FIELD desc_text 
							IF l_rec_warehouse.desc_text IS NULL THEN 
								error" Must enter description" 
								NEXT FIELD desc_text 
							END IF 

							LET l_rec_warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
						ON KEY (control-w) 
							CALL kandoohelp("") 
					END INPUT 
					EXIT MENU 

				COMMAND KEY(interrupt,"R")"Reenter" 
					LET quit_flag = true 
					EXIT MENU 
					#            COMMAND KEY (control-w)
					#               CALL kandoohelp("")

			END MENU 

			#         DISPLAY "" AT 1,1

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CONTINUE WHILE 
			END IF 

		END IF 

		LET l_target_ware = l_rec_warehouse.ware_code 

		DISPLAY BY NAME l_rec_warehouse.ware_code, 
		l_rec_warehouse.desc_text, 
		l_rec_warehouse.addr1_text, 
		l_rec_warehouse.addr2_text, 
		l_rec_warehouse.city_text, 
		l_rec_warehouse.state_code, 
		l_rec_warehouse.post_code, 
		l_rec_warehouse.country_code, 
		l_rec_warehouse.contact_text, 
		l_rec_warehouse.tele_text,
		l_rec_warehouse.mobile_phone,
		l_rec_warehouse.email

		OPEN WINDOW i172 with FORM "I172" 
		 CALL windecoration_i("I172") -- albo kd-758 

		WHILE true 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("I",1319,"") 
			#1319 Enter Selection Criteria;  OK TO Image.
			CONSTRUCT BY NAME l_where_text ON product.part_code, 
			product.desc_text, 
			product.desc2_text, 
			product.cat_code, 
			product.class_code 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","IZ9","construct-product-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 

			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 Searching Database;  Please wait.
			LET l_query_text = 
			"FROM prodstatus,", 
			"product ", 
			"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND product.part_code = prodstatus.part_code ", 
			"AND prodstatus.ware_code = \"",p_source_ware,"\" ", 
			"AND ",l_where_text clipped," ", 
			"AND NOT exists ", 
			"(SELECT * FROM prodstatus ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ware_code = \"",l_target_ware,"\" ", 
			"AND part_code = product.part_code) " 
			LET l_query1_text = "SELECT count(*) ",l_query_text clipped 
			PREPARE s1_prodstatus FROM l_query1_text 
			DECLARE c1_prodstatus CURSOR FOR s1_prodstatus 
			OPEN c1_prodstatus 
			FETCH c1_prodstatus INTO l_total 
			MESSAGE "" 

			IF l_total = 0 THEN 
				#error" No Products Selected FOR Imaging - Try Again"
				LET l_msgresp = kandoomsg("I",9543,"") 
				# 9543 No Products Selected FOR Imaging;  Try Again.
				CONTINUE WHILE 
			END IF 
			--         OPEN WINDOW w1_IZ9 AT 10,10 with 3 rows,62 columns  -- albo  KD-758
			--            ATTRIBUTE(border)
			DISPLAY " ",l_total USING "<<<<<", 
			" Products TO be Imaged TO ", 
			l_rec_warehouse.desc_text clipped at 3,1 
			MENU " Confirmation TO Image Products" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","IZ9","menu-Confirmation-1") -- albo kd-505 
				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 
				COMMAND "Image" 
					EXIT MENU 
				COMMAND KEY(interrupt,"E")"Exit" 
					LET quit_flag = true 
					EXIT MENU 
				COMMAND KEY (control-w) 
					CALL kandoohelp("") 
			END MENU 
			--         CLOSE WINDOW w1_IZ9  -- albo  KD-758
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW i172 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	--   OPEN WINDOW w1_IZ9 AT 12,7 with 5 rows,68 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	LET l_msgresp = kandoomsg("U",1002,"") 
	# 1002 Searching Database;  Please wait.
	LET l_query2_text = "SELECT prodstatus.* ",l_query_text clipped, 
	" ORDER BY prodstatus.cmpy_code,", 
	"prodstatus.part_code" 
	PREPARE s2_prodstatus FROM l_query2_text 
	DECLARE c2_prodstatus CURSOR FOR s2_prodstatus 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(status,l_err_message) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_cnt = 0 
		LET l_exists = 0 
		SELECT desc_text INTO l_rec_warehouse.desc_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_rec_warehouse.ware_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_err_message = " Inserting New Warehouse Row" 
			INSERT INTO warehouse VALUES (l_rec_warehouse.*) 
		END IF 
		LET l_err_message = " Inserting Product Status Rows" 

		FOREACH c2_prodstatus INTO l_rec_prodstatus.* 
			IF l_cnt = 0 THEN 
				MESSAGE "" 
				DISPLAY " Imaging Product: " at 3,1 
				DISPLAY " - Product Number " at 3,34 
				DISPLAY " of ",l_total USING "<<<<<<" at 3,60 
			END IF 
			LET l_cnt = l_cnt + 1 

			DISPLAY l_rec_prodstatus.part_code at 3,19 
			attribute(yellow) 

			DISPLAY l_cnt USING "#####&" at 3,53 
			attribute(yellow) 

			LET l_okay = check_parents(l_rec_prodstatus.part_code, l_target_ware, glob_rec_kandoouser.cmpy_code) 
			CASE l_okay 
				WHEN -1 
					LET l_msgresp = kandoomsg("I",5010,l_rec_prodstatus.part_code) 
					# I 5010 Logic Error: Product code does NOT exist.
					ROLLBACK WORK 
					--               CLOSE WINDOW w1_IZ9  -- albo  KD-758
					CLOSE WINDOW i172 
					RETURN 
				WHEN 0 # false 
					LET l_msgresp = kandoomsg("I",8051,"") 
					#I 8051 Parent product NOT found AT target warehouse, product NOT image..
					IF l_msgresp = "Y" THEN 
						CONTINUE FOREACH 
					ELSE 
						ROLLBACK WORK 
						--                  CLOSE WINDOW w1_IZ9  -- albo  KD-758
						CLOSE WINDOW i172 
						RETURN 
					END IF 
			END CASE 
			LET l_rec_prodstatus.ware_code = l_target_ware 
			LET l_rec_prodstatus.onhand_qty = 0 
			LET l_rec_prodstatus.onord_qty = 0 
			LET l_rec_prodstatus.reserved_qty = 0 
			LET l_rec_prodstatus.back_qty = 0 
			LET l_rec_prodstatus.transit_qty = 0 
			LET l_rec_prodstatus.forward_qty = 0 
			LET l_rec_prodstatus.bin1_text = " " 
			LET l_rec_prodstatus.bin2_text = " " 
			LET l_rec_prodstatus.bin3_text = " " 
			LET l_rec_prodstatus.last_sale_date = today 
			LET l_rec_prodstatus.last_receipt_date = today 
			LET l_rec_prodstatus.seq_num = 0 
			LET l_rec_prodstatus.phys_count_qty = 0 
			LET l_rec_prodstatus.last_stcktake_date = 31/12/1899 
			LET l_rec_prodstatus.stockturn_qty = 0 
			LET l_rec_prodstatus.status_date = today 
			INSERT INTO prodstatus VALUES (l_rec_prodstatus.*) 
		END FOREACH 
	COMMIT WORK 
	WHENEVER ERROR stop 
	--   CLOSE WINDOW w1_IZ9  -- albo  KD-758

	CLOSE WINDOW i172 

	RETURN 
END FUNCTION 
