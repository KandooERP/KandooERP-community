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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZC - Maintains Production Schedules
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_err_message CHAR(40) 
END GLOBALS 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	DEFINE l_msgresp STRING
	DEFINE l_rec_ipparms RECORD LIKE ipparms.*
	#Initial UI Init
	CALL setModuleId("IZC") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	# check before any further step if Production Schedule parameters exist
	SELECT * INTO l_rec_ipparms.* 
	FROM ipparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = 1 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9174,"") 
		LET l_msgresp = "Production Schedule Parameters Not Found - See Menu IZB"
		#9174 Production Schedule Parameters Not Found - See Menu IZB
		CALL fgl_winmessage(l_msgresp,"Please configure schedule in IZB","error") 
	END IF 



	OPEN WINDOW i636 with FORM "I636" 
	 CALL windecoration_i("I636") -- albo kd-758 
	CALL scan_product() 

	#   WHILE build_products_list()
	#      CALL scan_product()
	#   END WHILE
	CLOSE WINDOW i636 
END MAIN 


####################################################################
# FUNCTION build_products_list(p_filter)
#
#
####################################################################
FUNCTION build_products_list(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_wc_with_scrollflag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("I",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON product.part_code, 
		product.desc_text, 
		prodstatus.ware_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IZC","construct-product-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 
	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM product,prodstatus ", 
	"WHERE prodstatus.part_code = product.part_code ", 
	"AND product.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND prodstatus.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY product.part_code", 
	",prodstatus.ware_code" 
	PREPARE s_product FROM l_query_text 
	DECLARE crs_scan_products CURSOR FOR s_product 

	LET idx = 0 
	FOREACH crs_scan_products INTO l_rec_product.*,l_rec_prodstatus.* 
		LET idx = idx + 1 
		LET l_arr_rec_product[idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[idx].ware_code = l_rec_prodstatus.ware_code 
 
	END FOREACH 


	RETURN l_arr_rec_product 

END FUNCTION 


####################################################################
# FUNCTION scan_product()
#
#
####################################################################
FUNCTION scan_product() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_wc_with_scrollflag 

	#	DEFINE l_arr_rec_product array[100] OF
	#		RECORD
	#			scroll_flag CHAR(1),
	#			part_code LIKE product.part_code,
	#			desc_text LIKE product.desc_text,
	#			ware_code LIKE prodstatus.ware_code
	#		END RECORD
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_curr,pr_cnt,idx,del_cnt,pr_rowid,x SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 


	IF db_product_get_count() > 1000 THEN 
		CALL build_products_list(true) RETURNING l_arr_rec_product 
	ELSE 
		CALL build_products_list(false) RETURNING l_arr_rec_product 
	END IF 

	IF l_arr_rec_product.getlength() = 0 THEN 
		LET l_msgresp = kandoomsg("I",9152,"") 
		#9152" No entries satisfied selection criteria "
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	#   CALL set_count(idx)
	LET l_msgresp = kandoomsg("I",9173,"") 
	#9173 "RETURN on line TO Edit - F9 TO ReSelect"

	DISPLAY ARRAY l_arr_rec_product TO sr_product.* 
	#   INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZC","input-l_arr_rec_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_product[idx].scroll_flag 
			LET l_arr_rec_product[idx].scroll_flag = l_scroll_flag 

			#      BEFORE FIELD scroll_flag
			#         LET idx = arr_curr()
			#         LET l_scroll_flag = l_arr_rec_product[idx].scroll_flag

			#      AFTER FIELD scroll_flag
			#         LET l_arr_rec_product[idx].scroll_flag = l_scroll_flag

		ON ACTION ("doubleClick","EDIT") 
			#      BEFORE FIELD part_code
			IF l_arr_rec_product[idx].part_code IS NOT NULL THEN 
				LET l_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				CALL edit_product_schedule(l_arr_rec_product[idx].part_code, l_arr_rec_product[idx].ware_code) 
			END IF 
			CALL build_products_list(false) RETURNING l_arr_rec_product 

		ON ACTION "FILTER" 
			CALL build_products_list(true) RETURNING l_arr_rec_product 

			#         NEXT FIELD scroll_flag
			#     ON KEY(F9)
			#   EXIT DISPLAY

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 



####################################################################
# FUNCTION edit_product_schedule(p_part_code,p_ware_code)
#
#
####################################################################
FUNCTION edit_product_schedule(p_part_code,p_ware_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 

	DEFINE l_rec_s_product RECORD LIKE product.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_ipparms RECORD LIKE ipparms.* 
	DEFINE l_rec_inproduction RECORD LIKE inproduction.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_newmove 
	RECORD 
		new_qty FLOAT, 
		move_qty FLOAT, 
		new1_qty FLOAT, 
		move1_qty FLOAT, 
		new2_qty FLOAT, 
		move2_qty FLOAT, 
		new3_qty FLOAT, 
		move3_qty FLOAT, 
		new4_qty FLOAT, 
		move4_qty FLOAT, 
		new5_qty FLOAT, 
		move5_qty FLOAT, 
		new6_qty FLOAT, 
		move6_qty FLOAT, 
		new7_qty FLOAT, 
		move7_qty FLOAT, 
		new8_qty FLOAT, 
		move8_qty FLOAT, 
		new9_qty FLOAT, 
		move9_qty FLOAT, 
		new10_qty FLOAT, 
		move10_qty FLOAT 
	END RECORD 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_ins_flag SMALLINT 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_inproduction.* TO NULL 
	LET l_ins_flag = false 

	SELECT * INTO l_rec_ipparms.* 
	FROM ipparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = 1 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("I",9174,"") 
		#9174 Production Schedule Parameters Not Found - See Menu IZB
		RETURN 
	END IF 

	SELECT * INTO l_rec_inproduction.* 
	FROM inproduction 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_inproduction.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_inproduction.part_code = p_part_code 
		LET l_rec_inproduction.ware_code = p_ware_code 
		LET l_rec_inproduction.sched_qty = 0 
		LET l_ins_flag = true 
	END IF 

	SELECT * INTO l_rec_product.* 
	FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE ware_code = p_ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	INITIALIZE l_rec_newmove.* TO NULL 

	LET l_rec_newmove.new_qty = l_rec_inproduction.sched_qty 
	LET l_rec_newmove.new1_qty = l_rec_inproduction.field1_qty 
	LET l_rec_newmove.new2_qty = l_rec_inproduction.field2_qty 
	LET l_rec_newmove.new3_qty = l_rec_inproduction.field3_qty 
	LET l_rec_newmove.new4_qty = l_rec_inproduction.field4_qty 
	LET l_rec_newmove.new5_qty = l_rec_inproduction.field5_qty 
	LET l_rec_newmove.new6_qty = l_rec_inproduction.field6_qty 
	LET l_rec_newmove.new7_qty = l_rec_inproduction.field7_qty 
	LET l_rec_newmove.new8_qty = l_rec_inproduction.field8_qty 
	LET l_rec_newmove.new9_qty = l_rec_inproduction.field9_qty 
	LET l_rec_newmove.new10_qty = l_rec_inproduction.fielda_qty 
	LET l_rec_newmove.move_qty = 0 

	OPEN WINDOW i634 with FORM "I634" 
	 CALL windecoration_i("I634") -- albo kd-758 

	DISPLAY l_rec_product.desc_text TO part_text 

	DISPLAY l_rec_warehouse.desc_text TO ware_text 

	DISPLAY BY NAME l_rec_inproduction.part_code, 
	l_rec_inproduction.ware_code, 
	l_rec_inproduction.sched_qty,l_rec_inproduction.sched_date, 
	l_rec_inproduction.field1_qty,l_rec_inproduction.field1_date, 
	l_rec_inproduction.field2_qty,l_rec_inproduction.field2_date, 
	l_rec_inproduction.field3_qty,l_rec_inproduction.field3_date, 
	l_rec_inproduction.field4_qty,l_rec_inproduction.field4_date, 
	l_rec_inproduction.field5_qty,l_rec_inproduction.field5_date, 
	l_rec_inproduction.field6_qty,l_rec_inproduction.field6_date, 
	l_rec_inproduction.field7_qty,l_rec_inproduction.field7_date, 
	l_rec_inproduction.field8_qty,l_rec_inproduction.field8_date, 
	l_rec_inproduction.field9_qty,l_rec_inproduction.field9_date, 
	l_rec_inproduction.fielda_qty,l_rec_inproduction.fielda_date, 
	l_rec_newmove.new_qty,l_rec_newmove.move_qty, 
	l_rec_newmove.new1_qty,l_rec_newmove.move1_qty, 
	l_rec_newmove.new2_qty,l_rec_newmove.move2_qty, 
	l_rec_newmove.new3_qty,l_rec_newmove.move3_qty, 
	l_rec_newmove.new4_qty,l_rec_newmove.move4_qty, 
	l_rec_newmove.new5_qty,l_rec_newmove.move5_qty, 
	l_rec_newmove.new6_qty,l_rec_newmove.move6_qty, 
	l_rec_newmove.new7_qty,l_rec_newmove.move7_qty, 
	l_rec_newmove.new8_qty,l_rec_newmove.move8_qty, 
	l_rec_newmove.new9_qty,l_rec_newmove.move9_qty, 
	l_rec_newmove.new10_qty,l_rec_newmove.move10_qty, 
	l_rec_ipparms.ref1_text, 
	l_rec_ipparms.ref2_text, 
	l_rec_ipparms.ref3_text, 
	l_rec_ipparms.ref4_text, 
	l_rec_ipparms.ref5_text, 
	l_rec_ipparms.ref6_text, 
	l_rec_ipparms.ref7_text, 
	l_rec_ipparms.ref8_text, 
	l_rec_ipparms.ref9_text, 
	l_rec_ipparms.refa_text 

	INPUT BY NAME 
	l_rec_newmove.new_qty,l_rec_newmove.move_qty, 
	l_rec_inproduction.sched_date, 
	l_rec_newmove.new1_qty,l_rec_newmove.move1_qty, 
	l_rec_inproduction.field1_date, 
	l_rec_newmove.new2_qty,l_rec_newmove.move2_qty, 
	l_rec_inproduction.field2_date, 
	l_rec_newmove.new3_qty,l_rec_newmove.move3_qty, 
	l_rec_inproduction.field3_date, 
	l_rec_newmove.new4_qty,l_rec_newmove.move4_qty, 
	l_rec_inproduction.field4_date, 
	l_rec_newmove.new5_qty,l_rec_newmove.move5_qty, 
	l_rec_inproduction.field5_date, 
	l_rec_newmove.new6_qty,l_rec_newmove.move6_qty, 
	l_rec_inproduction.field6_date, 
	l_rec_newmove.new7_qty,l_rec_newmove.move7_qty, 
	l_rec_inproduction.field7_date, 
	l_rec_newmove.new8_qty,l_rec_newmove.move8_qty, 
	l_rec_inproduction.field8_date, 
	l_rec_newmove.new9_qty,l_rec_newmove.move9_qty, 
	l_rec_inproduction.field9_date, 
	l_rec_newmove.new10_qty,l_rec_newmove.move10_qty, 
	l_rec_inproduction.fielda_date 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZC","input-l_rec_newmove-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD new_qty 
			IF l_rec_newmove.new_qty IS NULL THEN 
				LET l_rec_newmove.new_qty = 0 
			END IF 
			IF l_rec_newmove.new_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new_qty 
			END IF 
			LET l_rec_newmove.move_qty = 
			l_rec_newmove.new_qty - l_rec_inproduction.sched_qty 
			DISPLAY BY NAME l_rec_newmove.move_qty 

		AFTER FIELD move_qty 
			IF l_rec_newmove.move_qty IS NULL THEN 
				LET l_rec_newmove.move_qty = 0 
			END IF 
			LET l_rec_newmove.new_qty = 
			l_rec_inproduction.sched_qty + l_rec_newmove.move_qty 
			DISPLAY BY NAME l_rec_newmove.new_qty 

			IF l_rec_newmove.new_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new_qty 
			END IF 

		AFTER FIELD sched_date 
			IF l_rec_newmove.new_qty <> 0 THEN 
				IF l_rec_inproduction.sched_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD sched_date 
				END IF 
			END IF 

		BEFORE FIELD new1_qty 
			IF l_rec_ipparms.ref1_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new_qty 
			ELSE 
				IF l_rec_inproduction.field1_qty IS NULL THEN 
					LET l_rec_inproduction.field1_qty = 0 
					LET l_rec_newmove.new1_qty = 0 
					LET l_rec_newmove.move1_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field1_qty, 
					l_rec_newmove.new1_qty, 
					l_rec_newmove.move1_qty 


				END IF 
			END IF 
		AFTER FIELD new1_qty 
			IF l_rec_newmove.new1_qty IS NULL THEN 
				LET l_rec_newmove.new1_qty = 0 
			END IF 
			IF l_rec_newmove.new1_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new1_qty 
			END IF 
			LET l_rec_newmove.move1_qty = 
			l_rec_newmove.new1_qty - l_rec_inproduction.field1_qty 
			DISPLAY BY NAME l_rec_newmove.move1_qty 

		AFTER FIELD move1_qty 
			IF l_rec_newmove.move1_qty IS NULL THEN 
				LET l_rec_newmove.move1_qty = 0 
			END IF 
			LET l_rec_newmove.new1_qty = 
			l_rec_inproduction.field1_qty + l_rec_newmove.move1_qty 
			DISPLAY BY NAME l_rec_newmove.new1_qty 

			IF l_rec_newmove.new1_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new1_qty 
			END IF 

		AFTER FIELD field1_date 
			IF l_rec_newmove.new1_qty <> 0 THEN 
				IF l_rec_inproduction.field1_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field1_date 
				END IF 
			END IF 

		BEFORE FIELD new2_qty 
			IF l_rec_ipparms.ref2_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new1_qty 
			ELSE 
				IF l_rec_inproduction.field2_qty IS NULL THEN 
					LET l_rec_inproduction.field2_qty = 0 
					LET l_rec_newmove.new2_qty = 0 
					LET l_rec_newmove.move2_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field2_qty, 
					l_rec_newmove.new2_qty, 
					l_rec_newmove.move2_qty 
				END IF 
			END IF 

		AFTER FIELD new2_qty 
			IF l_rec_newmove.new2_qty IS NULL THEN 
				LET l_rec_newmove.new2_qty = 0 
			END IF 
			IF l_rec_newmove.new2_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new2_qty 
			END IF 
			LET l_rec_newmove.move2_qty = 
			l_rec_newmove.new2_qty - l_rec_inproduction.field2_qty 
			DISPLAY BY NAME l_rec_newmove.move2_qty 

		AFTER FIELD move2_qty 
			IF l_rec_newmove.move2_qty IS NULL THEN 
				LET l_rec_newmove.move2_qty = 0 
			END IF 
			LET l_rec_newmove.new2_qty = 
			l_rec_inproduction.field2_qty + l_rec_newmove.move2_qty 
			DISPLAY BY NAME l_rec_newmove.new2_qty 

			IF l_rec_newmove.new2_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new2_qty 
			END IF 
			
		AFTER FIELD field2_date 
			IF l_rec_newmove.new2_qty <> 0 THEN 
				IF l_rec_inproduction.field2_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field2_date 
				END IF 
			END IF 

		BEFORE FIELD new3_qty 
			IF l_rec_ipparms.ref3_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new2_qty 
			ELSE 
				IF l_rec_inproduction.field3_qty IS NULL THEN 
					LET l_rec_inproduction.field3_qty = 0 
					LET l_rec_newmove.new3_qty = 0 
					LET l_rec_newmove.move3_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field3_qty, 
					l_rec_newmove.new3_qty, 
					l_rec_newmove.move3_qty 


				END IF 
			END IF 
			
		AFTER FIELD new3_qty 
			IF l_rec_newmove.new3_qty IS NULL THEN 
				LET l_rec_newmove.new3_qty = 0 
			END IF 
			IF l_rec_newmove.new3_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new3_qty 
			END IF 
			LET l_rec_newmove.move3_qty = 
			l_rec_newmove.new3_qty - l_rec_inproduction.field3_qty 
			DISPLAY BY NAME l_rec_newmove.move3_qty 

		AFTER FIELD move3_qty 
			IF l_rec_newmove.move3_qty IS NULL THEN 
				LET l_rec_newmove.move3_qty = 0 
			END IF 
			LET l_rec_newmove.new3_qty = 
			l_rec_inproduction.field3_qty + l_rec_newmove.move3_qty 
			DISPLAY BY NAME l_rec_newmove.new3_qty 

			IF l_rec_newmove.new3_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new3_qty 
			END IF 
			
		AFTER FIELD field3_date 
			IF l_rec_newmove.new3_qty <> 0 THEN 
				IF l_rec_inproduction.field3_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field3_date 
				END IF 
			END IF 

		BEFORE FIELD new4_qty 
			IF l_rec_ipparms.ref4_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new3_qty 
			ELSE 
				IF l_rec_inproduction.field4_qty IS NULL THEN 
					LET l_rec_inproduction.field4_qty = 0 
					LET l_rec_newmove.new4_qty = 0 
					LET l_rec_newmove.move4_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field4_qty, 
					l_rec_newmove.new4_qty, 
					l_rec_newmove.move4_qty 
				END IF 
			END IF 
			
		AFTER FIELD new4_qty 
			IF l_rec_newmove.new4_qty IS NULL THEN 
				LET l_rec_newmove.new4_qty = 0 
			END IF 
			IF l_rec_newmove.new4_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new4_qty 
			END IF 
			LET l_rec_newmove.move4_qty = 
			l_rec_newmove.new4_qty - l_rec_inproduction.field4_qty 
			DISPLAY BY NAME l_rec_newmove.move4_qty 

		AFTER FIELD move4_qty 
			IF l_rec_newmove.move4_qty IS NULL THEN 
				LET l_rec_newmove.move4_qty = 0 
			END IF 
			LET l_rec_newmove.new4_qty = 
			l_rec_inproduction.field4_qty + l_rec_newmove.move4_qty 
			DISPLAY BY NAME l_rec_newmove.new4_qty 

			IF l_rec_newmove.new4_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new4_qty 
			END IF 
			
		AFTER FIELD field4_date 
			IF l_rec_newmove.new4_qty <> 0 THEN 
				IF l_rec_inproduction.field4_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field4_date 
				END IF 
			END IF 

		BEFORE FIELD new5_qty 
			IF l_rec_ipparms.ref5_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new4_qty 
			ELSE 
				IF l_rec_inproduction.field5_qty IS NULL THEN 
					LET l_rec_inproduction.field5_qty = 0 
					LET l_rec_newmove.new5_qty = 0 
					LET l_rec_newmove.move5_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field5_qty, 
					l_rec_newmove.new5_qty, 
					l_rec_newmove.move5_qty 
				END IF 
			END IF 
			
		AFTER FIELD new5_qty 
			IF l_rec_newmove.new5_qty IS NULL THEN 
				LET l_rec_newmove.new5_qty = 0 
			END IF 
			IF l_rec_newmove.new5_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new5_qty 
			END IF 
			LET l_rec_newmove.move5_qty = 
			l_rec_newmove.new5_qty - l_rec_inproduction.field5_qty 
			DISPLAY BY NAME l_rec_newmove.move5_qty 

		AFTER FIELD move5_qty 
			IF l_rec_newmove.move5_qty IS NULL THEN 
				LET l_rec_newmove.move5_qty = 0 
			END IF 
			LET l_rec_newmove.new5_qty = 
			l_rec_inproduction.field5_qty + l_rec_newmove.move5_qty 
			DISPLAY BY NAME l_rec_newmove.new5_qty 

			IF l_rec_newmove.new5_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new5_qty 
			END IF 
			
		AFTER FIELD field5_date 
			IF l_rec_newmove.new5_qty <> 0 THEN 
				IF l_rec_inproduction.field5_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field5_date 
				END IF 
			END IF 

		BEFORE FIELD new6_qty 
			IF l_rec_ipparms.ref6_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new5_qty 
			ELSE 
				IF l_rec_inproduction.field6_qty IS NULL THEN 
					LET l_rec_inproduction.field6_qty = 0 
					LET l_rec_newmove.new6_qty = 0 
					LET l_rec_newmove.move6_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field6_qty, 
					l_rec_newmove.new6_qty, 
					l_rec_newmove.move6_qty 
				END IF 
			END IF 
			
		AFTER FIELD new6_qty 
			IF l_rec_newmove.new6_qty IS NULL THEN 
				LET l_rec_newmove.new6_qty = 0 
			END IF 
			IF l_rec_newmove.new6_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new6_qty 
			END IF 
			LET l_rec_newmove.move6_qty = 
			l_rec_newmove.new6_qty - l_rec_inproduction.field6_qty 
			DISPLAY BY NAME l_rec_newmove.move6_qty 

		AFTER FIELD move6_qty 
			IF l_rec_newmove.move6_qty IS NULL THEN 
				LET l_rec_newmove.move6_qty = 0 
			END IF 
			LET l_rec_newmove.new6_qty = 
			l_rec_inproduction.field6_qty + l_rec_newmove.move6_qty 
			DISPLAY BY NAME l_rec_newmove.new6_qty 

			IF l_rec_newmove.new6_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new6_qty 
			END IF 
		AFTER FIELD field6_date 
			IF l_rec_newmove.new6_qty <> 0 THEN 
				IF l_rec_inproduction.field6_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field6_date 
				END IF 
			END IF 

		BEFORE FIELD new7_qty 
			IF l_rec_ipparms.ref7_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new6_qty 
			ELSE 
				IF l_rec_inproduction.field7_qty IS NULL THEN 
					LET l_rec_inproduction.field7_qty = 0 
					LET l_rec_newmove.new7_qty = 0 
					LET l_rec_newmove.move7_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field7_qty, 
					l_rec_newmove.new7_qty, 
					l_rec_newmove.move7_qty 
				END IF 
			END IF
			 
		AFTER FIELD new7_qty 
			IF l_rec_newmove.new7_qty IS NULL THEN 
				LET l_rec_newmove.new7_qty = 0 
			END IF 
			IF l_rec_newmove.new7_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new7_qty 
			END IF 
			LET l_rec_newmove.move7_qty = 
			l_rec_newmove.new7_qty - l_rec_inproduction.field7_qty 
			DISPLAY BY NAME l_rec_newmove.move7_qty 

		AFTER FIELD move7_qty 
			IF l_rec_newmove.move7_qty IS NULL THEN 
				LET l_rec_newmove.move7_qty = 0 
			END IF 
			LET l_rec_newmove.new7_qty = 
			l_rec_inproduction.field7_qty + l_rec_newmove.move7_qty 
			DISPLAY BY NAME l_rec_newmove.new7_qty 

			IF l_rec_newmove.new7_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new7_qty 
			END IF 
			
		AFTER FIELD field7_date 
			IF l_rec_newmove.new7_qty <> 0 THEN 
				IF l_rec_inproduction.field7_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field7_date 
				END IF 
			END IF 

		BEFORE FIELD new8_qty 
			IF l_rec_ipparms.ref8_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new7_qty 
			ELSE 
				IF l_rec_inproduction.field8_qty IS NULL THEN 
					LET l_rec_inproduction.field8_qty = 0 
					LET l_rec_newmove.new8_qty = 0 
					LET l_rec_newmove.move8_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field8_qty, 
					l_rec_newmove.new8_qty, 
					l_rec_newmove.move8_qty 
				END IF 
			END IF 
			
		AFTER FIELD new8_qty 
			IF l_rec_newmove.new8_qty IS NULL THEN 
				LET l_rec_newmove.new8_qty = 0 
			END IF 
			IF l_rec_newmove.new8_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new8_qty 
			END IF 
			LET l_rec_newmove.move8_qty = 
			l_rec_newmove.new8_qty - l_rec_inproduction.field8_qty 
			DISPLAY BY NAME l_rec_newmove.move8_qty 

		AFTER FIELD move8_qty 
			IF l_rec_newmove.move8_qty IS NULL THEN 
				LET l_rec_newmove.move8_qty = 0 
			END IF 
			LET l_rec_newmove.new8_qty = 
			l_rec_inproduction.field8_qty + l_rec_newmove.move8_qty 
			DISPLAY BY NAME l_rec_newmove.new8_qty 

			IF l_rec_newmove.new8_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new8_qty 
			END IF 
			
		AFTER FIELD field8_date 
			IF l_rec_newmove.new8_qty <> 0 THEN 
				IF l_rec_inproduction.field8_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field8_date 
				END IF 
			END IF 

		BEFORE FIELD new9_qty 
			IF l_rec_ipparms.ref9_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new8_qty 
			ELSE 
				IF l_rec_inproduction.field9_qty IS NULL THEN 
					LET l_rec_inproduction.field9_qty = 0 
					LET l_rec_newmove.new9_qty = 0 
					LET l_rec_newmove.move9_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.field9_qty, 
					l_rec_newmove.new9_qty, 
					l_rec_newmove.move9_qty 
				END IF 
			END IF 
			
		AFTER FIELD new9_qty 
			IF l_rec_newmove.new9_qty IS NULL THEN 
				LET l_rec_newmove.new9_qty = 0 
			END IF 
			IF l_rec_newmove.new9_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new9_qty 
			END IF 
			LET l_rec_newmove.move9_qty = 
			l_rec_newmove.new9_qty - l_rec_inproduction.field9_qty 
			DISPLAY BY NAME l_rec_newmove.move9_qty 

		AFTER FIELD move9_qty 
			IF l_rec_newmove.move9_qty IS NULL THEN 
				LET l_rec_newmove.move9_qty = 0 
			END IF 
			LET l_rec_newmove.new9_qty = 
			l_rec_inproduction.field9_qty + l_rec_newmove.move9_qty 
			DISPLAY BY NAME l_rec_newmove.new9_qty 

			IF l_rec_newmove.new9_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new9_qty 
			END IF 
			
		AFTER FIELD field9_date 
			IF l_rec_newmove.new9_qty <> 0 THEN 
				IF l_rec_inproduction.field9_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD field9_date 
				END IF 
			END IF 

		BEFORE FIELD new10_qty 
			IF l_rec_ipparms.refa_text IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9176,"") 
				#9176 Description IS NOT SET up - See Menu IZB
				NEXT FIELD new9_qty 
			ELSE 
				IF l_rec_inproduction.fielda_qty IS NULL THEN 
					LET l_rec_inproduction.fielda_qty = 0 
					LET l_rec_newmove.new10_qty = 0 
					LET l_rec_newmove.move10_qty = 0 
					DISPLAY BY NAME l_rec_inproduction.fielda_qty, 
					l_rec_newmove.new10_qty, 
					l_rec_newmove.move10_qty 
				END IF 
			END IF 
			
		AFTER FIELD new10_qty 
			IF l_rec_newmove.new10_qty IS NULL THEN 
				LET l_rec_newmove.new10_qty = 0 
			END IF 
			IF l_rec_newmove.new10_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new10_qty 
			END IF 
			LET l_rec_newmove.move10_qty = 
			l_rec_newmove.new10_qty - l_rec_inproduction.fielda_qty 
			DISPLAY BY NAME l_rec_newmove.move10_qty 

		AFTER FIELD move10_qty 
			IF l_rec_newmove.move10_qty IS NULL THEN 
				LET l_rec_newmove.move10_qty = 0 
			END IF 
			LET l_rec_newmove.new10_qty = 
			l_rec_inproduction.fielda_qty + l_rec_newmove.move10_qty 
			DISPLAY BY NAME l_rec_newmove.new10_qty 

			IF l_rec_newmove.new10_qty < 0 THEN 
				LET l_msgresp = kandoomsg("W",9185,"") 
				#9185 Quantity can NOT be less than 0
				NEXT FIELD new10_qty 
			END IF 
		AFTER FIELD fielda_date 
			IF l_rec_newmove.new10_qty <> 0 THEN 
				IF l_rec_inproduction.fielda_date IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9175,"") 
					#9175 The Release Date Must Be Entered
					NEXT FIELD fielda_date 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i634 
		RETURN 
	END IF 

	LET l_rec_inproduction.sched_qty = l_rec_newmove.new_qty 
	LET l_rec_inproduction.field1_qty = l_rec_newmove.new1_qty 
	LET l_rec_inproduction.field2_qty = l_rec_newmove.new2_qty 
	LET l_rec_inproduction.field3_qty = l_rec_newmove.new3_qty 
	LET l_rec_inproduction.field4_qty = l_rec_newmove.new4_qty 
	LET l_rec_inproduction.field5_qty = l_rec_newmove.new5_qty 
	LET l_rec_inproduction.field6_qty = l_rec_newmove.new6_qty 
	LET l_rec_inproduction.field7_qty = l_rec_newmove.new7_qty 
	LET l_rec_inproduction.field8_qty = l_rec_newmove.new8_qty 
	LET l_rec_inproduction.field9_qty = l_rec_newmove.new9_qty 
	LET l_rec_inproduction.fielda_qty = l_rec_newmove.new10_qty 

		LET glob_err_message = "IZC - Updating product" 
		IF l_ins_flag THEN 
			INSERT INTO inproduction VALUES (l_rec_inproduction.*) 
			LET l_sqlerrd = sqlca.sqlerrd[6] 
		ELSE 
			UPDATE inproduction 
			SET * = l_rec_inproduction.* 
			WHERE part_code = l_rec_inproduction.part_code 
			AND ware_code = l_rec_inproduction.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_sqlerrd = sqlca.sqlerrd[3] 
		END IF 
 

 

END FUNCTION 

