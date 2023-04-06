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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

#################################################################
# MODULE scope variables
#################################################################

#############################################################################
# FUNCTION lineitem_scan()
#
# \brief module A41c - Line Item Entry (Scan Array)
#############################################################################
FUNCTION lineitem_scan() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rowid INTEGER 
	--DEFINE l_arr_rowid DYNAMIC ARRAY OF INTEGER #array[300] OF INTEGER 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_arr_rec_creditdetl DYNAMIC ARRAY OF  
		RECORD 
			scroll_flag CHAR(1), 
			part_code LIKE creditdetl.part_code, 
			ship_qty LIKE creditdetl.ship_qty, 
			received_qty LIKE creditdetl.received_qty, 
			unit_sales_amt LIKE creditdetl.unit_sales_amt, 
			line_total_amt LIKE creditdetl.line_total_amt 
		END RECORD 
		#DEFINE l_avail_qty LIKE prodstatus.onhand_qty #not used
		#DEFINE l_disc_per DECIMAL(16,2) #not used
		DEFINE l_temp_amt dec(16,2) 
		DEFINE idx INTEGER 
		DEFINE l_seq_num INTEGER 
		DEFINE i INTEGER 
		DEFINE j INTEGER 
		DEFINE h INTEGER 
		DEFINE x INTEGER 
		DEFINE cnt INTEGER 

		DEFINE l_errmsg CHAR(100) 
		DEFINE l_cnt SMALLINT 
		DEFINE l_tab_cnt SMALLINT 
		DEFINE l_array_cnt SMALLINT 
		DEFINE l_temp_text CHAR(40) 

		ERROR kandoomsg2("E",1175,"")	#1175 F1 TO Add etc...
		LET idx = 0 
		
		DECLARE c1_creditdetl CURSOR FOR 
		SELECT * FROM t_creditdetl 

		FOREACH c1_creditdetl INTO l_rec_creditdetl.* 
			LET idx = idx + 1 
--			LET l_arr_rowid[idx] = idx --l_rowid 
			LET l_arr_rec_creditdetl[idx].part_code = l_rec_creditdetl.part_code 
			LET l_arr_rec_creditdetl[idx].received_qty = l_rec_creditdetl.received_qty 
			LET l_arr_rec_creditdetl[idx].ship_qty = l_rec_creditdetl.ship_qty 
			LET l_arr_rec_creditdetl[idx].unit_sales_amt = l_rec_creditdetl.unit_sales_amt 

			IF glob_rec_arparms.show_tax_flag = "Y" THEN 
				LET l_arr_rec_creditdetl[idx].line_total_amt = l_rec_creditdetl.line_total_amt 
			ELSE 
				LET l_arr_rec_creditdetl[idx].line_total_amt = l_rec_creditdetl.ext_sales_amt 
			END IF 

--			IF idx = 300 THEN 
--				EXIT FOREACH 
--			END IF 

		END FOREACH 

		IF idx > 0 THEN 
			ERROR kandoomsg2("U",9113,idx) 
		END IF 

--		CALL set_count(idx) 
		--OPTIONS INSERT KEY f1, 
		--DELETE KEY f36 

		INPUT ARRAY l_arr_rec_creditdetl WITHOUT DEFAULTS FROM sr_creditdetl.* ATTRIBUTE(UNBUFFERED, AUTO APPEND = FALSE, INSERT ROW = FALSE, APPEND ROW=TRUE,DELETE ROW = FALSE) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A41b","inp-arr-creditdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) infield (scroll_flag) 
				LET j = arr_curr() 
				LET h = scr_line() 
				LET x = j - h + 1
				 
				FOR i = 1 TO arr_count() 
					IF l_arr_rec_creditdetl[i].received_qty IS NOT NULL AND	l_arr_rec_creditdetl[i].received_qty <> 0 THEN 

						LET l_arr_rec_creditdetl[i].received_qty = 0 
						SELECT * INTO l_rec_creditdetl.* 
						FROM t_creditdetl 
						WHERE rowid = l_arr_rowid[i] 

						LET l_rec_creditdetl.received_qty =	l_arr_rec_creditdetl[i].received_qty 

						CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 

						CALL serial_delete(l_arr_rec_creditdetl[i].part_code,	l_rec_creditdetl.ware_code) 
				
						IF i >= x AND	i <= x + 6 THEN 
							DISPLAY l_arr_rec_creditdetl[i].received_qty TO sr_creditdetl[(i - x) + 1].received_qty 
						END IF 
					
					END IF 
				END FOR
				 
				NEXT FIELD scroll_flag 

			ON ACTION "LOOKUP" infield (part_code) 
				LET l_temp_text= 
					"(status_ind='1' OR status_ind='4') AND exists", 
					"(SELECT 1 FROM prodstatus ", 
					"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND part_code= product.part_code ", 
					"AND ware_code='",glob_rec_warehouse.ware_code,"' ", 
					"AND (status_ind='1' OR status_ind='4'))" 

				LET l_temp_text = show_part(glob_rec_kandoouser.cmpy_code,l_temp_text) 

				IF l_temp_text IS NOT NULL THEN 
					LET l_arr_rec_creditdetl[idx].part_code = l_temp_text 
					NEXT FIELD part_code 
				END IF 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()

			BEFORE FIELD scroll_flag 
--				SELECT * INTO l_rec_creditdetl.* 
--				FROM t_creditdetl 
--				WHERE rowid = l_arr_rowid[idx] 
--
--				IF status = NOTFOUND THEN 
--					LET l_arr_rowid[idx] = creditdetl_insert_row() 
--				END IF 

				IF l_seq_num > 0 THEN 
					IF l_rec_creditdetl.line_acct_code IS NULL 
					AND l_rec_creditdetl.line_text IS NULL THEN 
						LET l_arr_rec_creditdetl[idx].ship_qty = NULL 
						LET l_arr_rec_creditdetl[idx].received_qty = NULL 
						LET l_arr_rec_creditdetl[idx].unit_sales_amt = NULL 
					ELSE 
						LET l_arr_rec_creditdetl[idx].part_code = l_rec_creditdetl.part_code 
						LET l_arr_rec_creditdetl[idx].ship_qty = l_rec_creditdetl.ship_qty 
						LET l_arr_rec_creditdetl[idx].received_qty = l_rec_creditdetl.received_qty 
						LET l_arr_rec_creditdetl[idx].unit_sales_amt = l_rec_creditdetl.unit_sales_amt 

						IF glob_rec_arparms.show_tax_flag = "Y" THEN 
							LET l_arr_rec_creditdetl[idx].line_total_amt =	l_rec_creditdetl.line_total_amt 
						ELSE 
							LET l_arr_rec_creditdetl[idx].line_total_amt = l_rec_creditdetl.ext_sales_amt 
						END IF 

					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
				END IF 
				LET l_seq_num = 0 
				#DISPLAY l_arr_rec_creditdetl[idx].* TO sr_creditdetl[scrn].*

--DISPLAY "Anna = ",  glob_rec_credithead.*

				CALL disp_credit_detail(l_rec_creditdetl.*) 

			AFTER FIELD scroll_flag 
				CLEAR scroll_flag 
				#BEFORE FIELD part_code
				#   DISPLAY l_arr_rec_creditdetl[idx].* TO sr_creditdetl[scrn].*


			AFTER FIELD part_code 
				LET l_seq_num = 1 
				IF l_arr_rec_creditdetl[idx].part_code IS NOT NULL THEN 
					#Note:  Done on purpose TO stop users adding products
					#       TO adjustment credits
					IF glob_rec_credithead.cred_ind = "4" THEN   #what is cred_ind "4" ??? 
						LET l_rec_creditdetl.ware_code = " " 
					END IF 

					IF NOT valid_part(
						glob_rec_kandoouser.cmpy_code, 
						l_arr_rec_creditdetl[idx].part_code, 
						l_rec_creditdetl.ware_code, 
						TRUE,2,0,"","","") 
					THEN 
						## see partfunc FOR kandoomsg
						NEXT FIELD part_code 
					END IF 
				END IF 

				LET l_rec_creditdetl.part_code = l_arr_rec_creditdetl[idx].part_code 
				LET l_rec_creditdetl.ship_qty = l_arr_rec_creditdetl[idx].ship_qty 
				LET l_rec_creditdetl.received_qty = l_arr_rec_creditdetl[idx].received_qty 
				LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[idx].unit_sales_amt 

				CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*)		RETURNING l_rec_creditdetl.* 

				LET l_arr_rec_creditdetl[idx].unit_sales_amt = l_rec_creditdetl.unit_sales_amt 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.line_total_amt 
				ELSE 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.ext_sales_amt 
				END IF 
				#DISPLAY l_arr_rec_creditdetl[idx].* TO sr_creditdetl[scrn].*

				DISPLAY BY NAME l_rec_creditdetl.line_text 

#------------------------
				IF l_arr_rec_creditdetl[idx].part_code IS NULL THEN 
					IF lineitem_entry(idx) THEN 
						--NEXT FIELD scroll_flag 
					END IF 
				END IF
#------------------------

--				IF fgl_lastkey() != fgl_keyval("RETURN") 
--				AND fgl_lastkey() != fgl_keyval("left") 
--				AND fgl_lastkey() != fgl_keyval("tab") 
--				AND fgl_lastkey() != fgl_keyval("right") THEN 
--					IF l_rec_creditdetl.line_text IS NULL THEN 
--						INITIALIZE l_arr_rec_creditdetl[idx].* TO NULL 
--						NEXT FIELD scroll_flag 
--					ELSE 
--						NEXT FIELD line_total_amt 
--					END IF 
--				END IF 

			BEFORE FIELD ship_qty 
--				IF l_arr_rec_creditdetl[idx].part_code IS NULL THEN 
--					IF lineitem_entry(l_arr_rowid[idx]) THEN 
--						NEXT FIELD scroll_flag 
--					END IF 
--				END IF 

			AFTER FIELD ship_qty 
				LET l_seq_num = 2 
				IF l_arr_rec_creditdetl[idx].ship_qty IS NULL THEN 
					ERROR kandoomsg2("E",9133,"") 
					LET l_arr_rec_creditdetl[idx].ship_qty = 0 
					NEXT FIELD ship_qty 
				END IF 

				IF l_arr_rec_creditdetl[idx].ship_qty < 0 THEN 
					ERROR kandoomsg2("E",9134,"")		#9134 Quantity may NOT be negative
					LET l_arr_rec_creditdetl[idx].ship_qty = l_rec_creditdetl.ship_qty 
					NEXT FIELD ship_qty 
				END IF 

				LET l_rec_creditdetl.ship_qty = l_arr_rec_creditdetl[idx].ship_qty 
				LET l_rec_creditdetl.received_qty = l_arr_rec_creditdetl[idx].received_qty 
				LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[idx].unit_sales_amt 

				CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.line_total_amt 
				ELSE 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.ext_sales_amt 
				END IF 
				#DISPLAY l_arr_rec_creditdetl[idx].* TO sr_creditdetl[scrn].*

--				IF fgl_lastkey() != fgl_keyval("RETURN") 
--				AND fgl_lastkey() != fgl_keyval("left") 
--				AND fgl_lastkey() != fgl_keyval("tab") 
--				AND fgl_lastkey() != fgl_keyval("right") THEN 
--					NEXT FIELD line_total_amt 
--				END IF 

			BEFORE FIELD received_qty 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_arr_rec_creditdetl[idx].part_code 
				AND serial_flag = 'Y' 
				IF status <> NOTFOUND THEN 
					LET l_tab_cnt = serial_count(l_arr_rec_creditdetl[idx].part_code,	l_rec_creditdetl.ware_code) 

					IF l_tab_cnt > l_arr_rec_creditdetl[idx].received_qty THEN 
						
						IF l_arr_rec_creditdetl[idx].received_qty = 0 THEN 
							ERROR kandoomsg2("I",9278,'')	#9278 Product / Warehouse combination can only occur 1
						ELSE 
							ERROR kandoomsg2("I",9279,'')	#9279 Error - INPUT Quantity NOT equal OUTPUT Quantity
							LET l_errmsg = "A41c - Qty supplied NOT= table qty ",	l_arr_rec_creditdetl[idx].received_qty , " <> ", l_tab_cnt 

							CALL errorlog(l_errmsg) 

							LET status = -2 
							EXIT PROGRAM 
						END IF
						 
						NEXT FIELD part_code 
					END IF 

					LET l_cnt = serial_input(
						l_arr_rec_creditdetl[idx].part_code, 
						l_rec_creditdetl.ware_code, 
						l_tab_cnt) 
					
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 

					IF l_cnt < 0 THEN 
						IF l_cnt = -1 THEN 
							NEXT FIELD ship_qty 
						ELSE 
							CALL errorlog("A21b - Fatal error in serial_input ") 
							EXIT PROGRAM 
						END IF 
					ELSE 
						LET l_arr_rec_creditdetl[idx].received_qty = l_cnt 
						DISPLAY BY NAME l_arr_rec_creditdetl[idx].received_qty 

						IF l_arr_rec_creditdetl[idx].received_qty >	l_arr_rec_creditdetl[idx].ship_qty THEN 
							ERROR kandoomsg2("E",7092,"") #7092 Warning Quantity IS > ship_qty
							NEXT FIELD part_code 
						END IF 

--						IF fgl_lastkey() != fgl_keyval("RETURN") 
--						AND fgl_lastkey() != fgl_keyval("left") 
--						AND fgl_lastkey() != fgl_keyval("tab") 
--						AND fgl_lastkey() != fgl_keyval("right") THEN 
--							NEXT FIELD line_total_amt 
--						END IF 
					END IF 
				END IF 

			AFTER FIELD received_qty 
				LET l_seq_num = 3 
				IF l_arr_rec_creditdetl[idx].received_qty < 0 THEN 
					ERROR kandoomsg2("E",9134,"")	#9134 Quantity may NOT be negative
					LET l_arr_rec_creditdetl[idx].received_qty = l_arr_rec_creditdetl[idx].ship_qty 
					NEXT FIELD received_qty 
				END IF 

				IF l_arr_rec_creditdetl[idx].received_qty >	l_arr_rec_creditdetl[idx].ship_qty THEN 
					ERROR kandoomsg2("E",7092,"") 				#7092 Warning Quantity IS > ship_qty
				END IF 
				
				IF l_arr_rec_creditdetl[idx].received_qty IS NULL THEN 
					LET l_arr_rec_creditdetl[idx].received_qty = l_arr_rec_creditdetl[idx].ship_qty 
					ERROR kandoomsg2("E",9133,"") 
					NEXT FIELD received_qty 
				END IF
				 
	--			IF fgl_lastkey() != fgl_keyval("RETURN") 
	--			AND fgl_lastkey() != fgl_keyval("left") 
	--			AND fgl_lastkey() != fgl_keyval("tab") 
	--			AND fgl_lastkey() != fgl_keyval("right") THEN 
	--				NEXT FIELD line_total_amt 
	--			END IF 

			AFTER FIELD unit_sales_amt ## re DISPLAY line totals 
				LET l_seq_num = 4 
				IF l_arr_rec_creditdetl[idx].unit_sales_amt < 0 THEN 
					ERROR kandoomsg2("E",9240,"") 	#9240 Unit sales amount must NOT be negative
					LET l_arr_rec_creditdetl[idx].unit_sales_amt = l_rec_creditdetl.unit_sales_amt 
					NEXT FIELD unit_sales_amt 
				END IF 

				LET l_rec_creditdetl.ship_qty = l_arr_rec_creditdetl[idx].ship_qty 
				LET l_rec_creditdetl.received_qty = l_arr_rec_creditdetl[idx].received_qty 
				LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[idx].unit_sales_amt 

				CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 

				IF glob_rec_arparms.show_tax_flag = "Y" THEN 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.line_total_amt 
				ELSE 
					LET l_arr_rec_creditdetl[idx].line_total_amt=l_rec_creditdetl.ext_sales_amt 
				END IF 

--				IF fgl_lastkey() != fgl_keyval("RETURN") 
--				AND fgl_lastkey() != fgl_keyval("left") 
--				AND fgl_lastkey() != fgl_keyval("tab") 
--				AND fgl_lastkey() != fgl_keyval("right") THEN 
--					NEXT FIELD line_total_amt 
--				END IF 

			BEFORE FIELD line_total_amt ## save orderline 
				LET l_rec_creditdetl.part_code = l_arr_rec_creditdetl[idx].part_code 
				LET l_rec_creditdetl.ship_qty = l_arr_rec_creditdetl[idx].ship_qty 
				LET l_rec_creditdetl.received_qty = l_arr_rec_creditdetl[idx].received_qty 
				LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[idx].unit_sales_amt 
				
				CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 
				
				NEXT FIELD scroll_flag 

			ON ACTION "UPDATE" --ON KEY (F8) --update invoice line ?? 
				IF l_seq_num > 1 THEN 
					LET l_rec_creditdetl.part_code = l_arr_rec_creditdetl[idx].part_code 
					LET l_rec_creditdetl.ship_qty = l_arr_rec_creditdetl[idx].ship_qty 
					LET l_rec_creditdetl.received_qty = l_arr_rec_creditdetl[idx].received_qty 
					LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[idx].unit_sales_amt 
					
					CALL A41_creditdetl_update_line(idx,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 
				END IF 
				
				IF lineitem_entry(idx) THEN 
					LET l_seq_num = 1 
					NEXT FIELD scroll_flag 
				END IF 

			ON KEY (F2) --delete ? or select ? check it 
				SELECT unique 1 FROM creditdetl c, serialinfo s 
				WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND s.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND c.cred_num = glob_rec_credithead.cred_num 
				AND s.credit_num = glob_rec_credithead.cred_num 
				AND s.part_code = c.part_code 
				AND s.part_code = l_arr_rec_creditdetl[idx].part_code 
				AND ( s.trantype_ind <> '0' 
				OR s.ware_code <> c.ware_code ) 
				IF status <> NOTFOUND THEN 
					LET status = kandoomsg("I",9289,'')			#8026 Can NOT cancel RETURN because serial items have be
					NEXT FIELD scroll_flag 
				END IF 
				
				CALL serial_delete(l_arr_rec_creditdetl[idx].part_code,	l_rec_creditdetl.ware_code)
				
				# DELETE FROM t_creditdetl ------------------				 
				DELETE FROM t_creditdetl WHERE rowid = l_arr_rowid[idx] 
				
				CALL fgl_winmessage("needs fixing","needs fixing x","info") 
				
				LET j = idx -- huho.. needs fixing scrn 
				FOR i = idx TO arr_count() 
					IF i = 300 THEN 
						--LET l_arr_rowid[300] = 0 
						
						INITIALIZE l_arr_rec_creditdetl[300].* TO NULL 
					ELSE 
						#@huho
						#DEFINE
						#   l_arr_rowid array[300] of INTEGER,
						#Why did this compile in I4g ?
						#LET l_arr_rowid[i].* = l_arr_rowid[i+1].*
						--LET l_arr_rowid[i] = l_arr_rowid[i+1] --huho removed .* as this IS just an int ARRAY 
						LET l_arr_rec_creditdetl[i].* = l_arr_rec_creditdetl[i+1].* 
					END IF 
					
					IF j <= 7 THEN 
						DISPLAY l_arr_rec_creditdetl[i].* TO sr_creditdetl[j].* 

						--IF l_arr_rowid[i] = 0 THEN 
						--	DISPLAY '' TO sr_creditdetl[j].ship_qty 
						--	DISPLAY '' TO sr_creditdetl[j].received_qty 
						--END IF 
						
						LET j = j + 1 
					END IF 
				END FOR
				 
				NEXT FIELD scroll_flag 

			AFTER DELETE 
				LET l_array_cnt = arr_count() 
				INITIALIZE l_arr_rec_creditdetl[l_array_cnt+1].* TO NULL 

			BEFORE INSERT 
			DISPLAY "-----------------------------------"
			DISPLAY "arr_count()=", arr_count()
--			DISPLAY "i=", i
			DISPLAY "idx=", idx
			DISPLAY "l_arr_rec_creditdetl.getLength()=", l_arr_rec_creditdetl.getLength()
			DISPLAY "-----------------------------------"
			
				#----------------------------------
				#original code.. don'T get it / don't know how to apply it for dynamic arrays / I may experience be a black out
				#original code.. don'T get it / don't know how to apply it for dynamic arrays / I may experience be a black out
				#FOR i = arr_count() TO idx step -1 
				#	LET l_arr_rowid[i+1] = l_arr_rowid[i] 
				#END FOR 
				#----------------------------------

--			DISPLAY "-----------------------------------"
--			DISPLAY "arr_count()=", arr_count()
--			DISPLAY "i=", i
--			DISPLAY "idx=", idx
--			DISPLAY "l_arr_rec_creditdetl.getLength()=", l_arr_rec_creditdetl.getLength()
--			DISPLAY "-----------------------------------"


--				INITIALIZE l_arr_rec_creditdetl[idx].* TO NULL 
--
--				LET l_arr_rec_creditdetl[idx].ship_qty = 0 
--				LET l_arr_rec_creditdetl[idx].received_qty = 0 
--				LET l_arr_rec_creditdetl[idx].line_total_amt = 0 
				
				CALL creditdetl_insert_row() RETURNING  l_arr_rec_creditdetl[idx].*
--				LET l_arr_rowid[idx] = creditdetl_insert_row() #original 

				LET l_arr_rec_creditdetl[idx].ship_qty = 0 
				LET l_arr_rec_creditdetl[idx].received_qty = 0 
				LET l_arr_rec_creditdetl[idx].line_total_amt = 0 

				## Need TO reselect INTO l_rec_creditdetl b/c it retains
				## previous value
--				SELECT * INTO l_rec_creditdetl.* 
--				FROM t_creditdetl 
--				WHERE rowid = l_arr_rowid[idx]
				 
				CALL disp_credit_detail(l_rec_creditdetl.*) 
				
--				NEXT FIELD part_code 
				#AFTER ROW
				#   DISPLAY l_arr_rec_creditdetl[idx].* TO sr_creditdetl[scrn].*

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					 
					IF kandoomsg("A",8004,"") = "N" THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						# DELETE FROM t_creditdetl ------------------
						DELETE FROM t_creditdetl 
						WHERE part_code IS NULL 
						AND ship_qty = 0 
						AND received_qty = 0 
						
						LET quit_flag = true 
					END IF
					 
				ELSE
				 
					FOR i = 1 TO l_arr_rec_creditdetl.getSize()
						SELECT unique 1 FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_arr_rec_creditdetl[i].part_code 
						AND serial_flag = 'Y' 
						IF status <> NOTFOUND THEN 

							LET l_cnt = serial_count(l_arr_rec_creditdetl[i].part_code,	l_rec_creditdetl.ware_code) 

							IF l_cnt <> l_arr_rec_creditdetl[i].received_qty THEN 
								ERROR kandoomsg2("I",9303, l_arr_rec_creditdetl[i].part_code) #9303 Number of Serial Codes entered must = Receive
								NEXT FIELD scroll_flag 
							END IF 
						END IF 

					END FOR 

--					FOR i = 1 TO l_arr_rowid.getSize() 
--						UPDATE t_creditdetl SET line_num = i 
--						WHERE rowid = l_arr_rowid[i] 
--					END FOR 

					# DELETE FROM t_creditdetl ------------------
					DELETE FROM t_creditdetl 
					WHERE part_code IS NULL 
					AND line_text IS NULL 
					AND line_acct_code IS NULL 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
END FUNCTION 
#############################################################################
# END FUNCTION lineitem_scan()
#############################################################################


#############################################################################
# FUNCTION creditdetl_insert_row()
#
# RETURN l_rec_creditdetl.*
#
#############################################################################
FUNCTION creditdetl_insert_row() 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

	LET l_rec_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_creditdetl.cust_code = glob_rec_credithead.cust_code 
	LET l_rec_creditdetl.cred_num = glob_rec_credithead.cred_num 
--	LET l_rec_creditdetl.line_num = 0 
	LET l_rec_creditdetl.ware_code = glob_rec_warehouse.ware_code 
	LET l_rec_creditdetl.ship_qty = 0 
	LET l_rec_creditdetl.ser_ind = "N" 
	LET l_rec_creditdetl.unit_cost_amt = 0 
	LET l_rec_creditdetl.ext_cost_amt = 0 
	LET l_rec_creditdetl.unit_sales_amt = 0 
	LET l_rec_creditdetl.ext_sales_amt = 0 
	LET l_rec_creditdetl.unit_tax_amt = 0 
	LET l_rec_creditdetl.ext_tax_amt = 0 
	LET l_rec_creditdetl.line_total_amt = 0 
	LET l_rec_creditdetl.seq_num = 0 
	LET l_rec_creditdetl.level_code = glob_rec_customer.inv_level_ind 
	LET l_rec_creditdetl.comm_amt = 0 
	LET l_rec_creditdetl.tax_code = glob_rec_credithead.tax_code 
	LET l_rec_creditdetl.reason_code = glob_rec_credithead.reason_code 
	LET l_rec_creditdetl.received_qty = 0 
	LET l_rec_creditdetl.invoice_num = NULL 
	LET l_rec_creditdetl.inv_line_num = NULL 
	LET l_rec_creditdetl.list_amt = 0 

	LET l_rec_creditdetl.line_num = db_creditdetl_get_next_line_num(l_rec_creditdetl.cust_code,l_rec_creditdetl.cred_num)

	# INSERT INTO t_creditdetl ------------------------------
	INSERT INTO t_creditdetl VALUES (l_rec_creditdetl.*)
CALL fgl_winmessage("Insert new line","insert new line\nreditdetl_insert_row()","info")	 
	CALL db_show_creditdetl_arr_rec() #huho-debug
	--LET l_rec_creditdetl.line_num = sqlca.sqlerrd[6] 
	RETURN l_rec_creditdetl.*
END FUNCTION 
#############################################################################
# END FUNCTION creditdetl_insert_row()
#############################################################################

FUNCTION db_creditdetl_get_next_line_num(p_cust_code,p_cred_num)
	DEFINE p_cust_code LIKE creditdetl.cust_code
	DEFINE p_cred_num LIKE creditdetl.cred_num
	DEFINE l_ret_line_num LIKE creditdetl.line_num

	Select max(1) line_num INTO l_ret_line_num
	FROM creditdetl	
	WHERE cmpy_code = glob_rec_company.cmpy_code
	AND cust_code = p_cust_code
	AND cred_num = p_cred_num
	ORDER BY line_num DESC
	
	IF l_ret_line_num IS NULL THEN #For empty / new creditdetl - add the very first row
		LET l_ret_line_num = 0		
	END IF
	
	RETURN l_ret_line_num +1
END FUNCTION
#############################################################################
# FUNCTION A41_creditdetl_update_line(p_line_num,p_rec_creditdetl)
#
#
#############################################################################
FUNCTION A41_creditdetl_update_line(p_line_num,p_rec_creditdetl) 
	DEFINE p_line_num INTEGER 
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.* 

	DEFINE l_rec_creditdetl2 RECORD LIKE creditdetl.* 
	DEFINE l_rec_original_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_temp_amt dec(16,2) 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_taxable_amt DECIMAL(16,2) 
	DEFINE l_round_err DECIMAL(16,2) 
	DEFINE l_tax_amt DECIMAL(16,2) 
	DEFINE l_tax_amt2 DECIMAL(16,2) 

	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_tax2 RECORD LIKE tax.* 

--	IF p_line_num > glob_arr_rec_creditdetl.getSize() THEN #newly appended row
--		#APPEND ? 
--		CALL fgl_winmessage("Seems, you want to append/insert a row, not update","Seems, you want to append/insert a row, not update","ERROR")
--		INITIALIZE p_rec_creditdetl.* TO NULL 
--		RETURN p_rec_creditdetl.*		
--	END IF

	SELECT * INTO l_rec_original_creditdetl.* 
	FROM t_creditdetl 
	WHERE rowid = p_line_num 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",9930,"Line must be re-entered.")	# 9930 Logic Error: Line must be re-entered.
		INITIALIZE p_rec_creditdetl.* TO NULL 
		RETURN p_rec_creditdetl.* 
	END IF 

--	LET l_rec_original_creditdetl.* = glob_arr_rec_creditdetl[p_line_num].*



	CASE 
		WHEN (l_rec_original_creditdetl.part_code IS NULL	AND p_rec_creditdetl.part_code IS null) 
			##
			## User editted non-product line
			##

		WHEN (l_rec_original_creditdetl.part_code IS NOT NULL	AND p_rec_creditdetl.part_code IS null) 
			##
			## User removed product code
			##
			LET p_rec_creditdetl.received_qty = 0 
			LET p_rec_creditdetl.maingrp_code = NULL 
			LET p_rec_creditdetl.prodgrp_code = NULL 
			LET p_rec_creditdetl.proddept_code = NULL 
			LET p_rec_creditdetl.cat_code = NULL 
			LET p_rec_creditdetl.uom_code = NULL 
			LET p_rec_creditdetl.ser_ind = NULL 
			LET p_rec_creditdetl.unit_cost_amt = 0 

		WHEN (l_rec_original_creditdetl.part_code IS NULL 	AND p_rec_creditdetl.part_code IS NOT null) 
			##
			## User added product line
			##
			CALL db_product_get_rec(UI_OFF,p_rec_creditdetl.part_code ) RETURNING l_rec_product.* 

--			SELECT * INTO l_rec_product.* 
--			FROM product 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND part_code = p_rec_creditdetl.part_code 
	
			LET p_rec_creditdetl.maingrp_code = l_rec_product.maingrp_code 
			LET p_rec_creditdetl.prodgrp_code = l_rec_product.prodgrp_code 
			LET p_rec_creditdetl.line_text = l_rec_product.desc_text 


#----------------------------------------------------------
# By HuHo
# DB Schema changes impacted this... code no longer worked
			#added by HuHo
			LET p_rec_creditdetl.proddept_code = l_rec_product.dept_code #? DB changes were wrong.. we did discuss this and could not come to a solution other than rollin back the product dept_code changes dbSchema
			 
#			SELECT dept_code INTO p_rec_creditdetl.proddept_code 
#			FROM maingrp 
#			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
#			AND maingrp_code = p_rec_creditdetl.maingrp_code 
#----------------------------------------------------------

#-------------------------------------------------------
# Eric Vercelletto:house_with_garden:  13:30
# Maybe maingrp_code + dept_code + cmpy_code

#-------------------------------------------------------
# Alex Bondar 
# alter table "informix".maingrp add constraint primary key (maingrp_code,
#     dept_code,cmpy_code) constraint "informix".pk_maingrp  ;
# PK columns are:
# maingrp_code,
# dept_code,
# cmpy_code (edited)
#


			LET p_rec_creditdetl.cat_code = l_rec_product.cat_code 
			LET p_rec_creditdetl.uom_code = l_rec_product.sell_uom_code 
			LET p_rec_creditdetl.ser_ind = l_rec_product.serial_flag 

			IF p_rec_creditdetl.line_acct_code IS NULL THEN 
				## May possibly be using line_account FROM invoice
				SELECT sale_acct_code INTO p_rec_creditdetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_creditdetl.cat_code 
				IF status = NOTFOUND OR p_rec_creditdetl.line_acct_code IS NULL THEN 
					ERROR kandoomsg2("U",9930,"Credit Account NOT setup.") # 9930 Logic Error: Credit Account NOT setup.
				END IF 
			END IF 

			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = glob_rec_warehouse.ware_code 
			AND part_code = p_rec_creditdetl.part_code 

			IF p_rec_creditdetl.invoice_num IS NOT NULL THEN 
				## Imaged FROM warehouse so dont recal prices, costs, tax etc.
			ELSE 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 
				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 

				CALL unit_price(p_rec_creditdetl.part_code,p_rec_creditdetl.level_code) 
				RETURNING p_rec_creditdetl.list_amt,	p_rec_creditdetl.unit_sales_amt 

				CALL calc_line_tax(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.tax_code, 
					p_rec_creditdetl.tax_code, 
					l_rec_prodstatus.sale_tax_amt, 
					p_rec_creditdetl.ship_qty, 
					p_rec_creditdetl.unit_cost_amt, 
					p_rec_creditdetl.unit_sales_amt) 
				RETURNING p_rec_creditdetl.unit_tax_amt,	p_rec_creditdetl.ext_tax_amt 
			END IF 

		WHEN (l_rec_original_creditdetl.part_code IS NOT NULL AND p_rec_creditdetl.part_code IS NOT null) 
			IF l_rec_original_creditdetl.part_code != p_rec_creditdetl.part_code THEN 
				
				#------------------------------
				# User changed product code
				
				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_creditdetl.part_code 

				LET p_rec_creditdetl.maingrp_code = l_rec_product.maingrp_code 
				LET p_rec_creditdetl.prodgrp_code = l_rec_product.prodgrp_code 

				SELECT dept_code INTO p_rec_creditdetl.proddept_code 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_creditdetl.maingrp_code 

				LET p_rec_creditdetl.cat_code = l_rec_product.cat_code 
				LET p_rec_creditdetl.uom_code = l_rec_product.sell_uom_code 
				LET p_rec_creditdetl.ser_ind = l_rec_product.serial_flag 

				SELECT sale_acct_code INTO p_rec_creditdetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_creditdetl.cat_code 

				LET p_rec_creditdetl.line_text = l_rec_product.desc_text 

				SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_warehouse.ware_code 
				AND part_code = p_rec_creditdetl.part_code 

				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 

				## IF product change THEN break link TO invoice

				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF l_rec_original_creditdetl.level_code != p_rec_creditdetl.level_code 
			OR l_rec_original_creditdetl.part_code != p_rec_creditdetl.part_code THEN 

				## IF tax OR price change THEN break link TO invoice

				CALL unit_price(p_rec_creditdetl.part_code,p_rec_creditdetl.level_code) 
				RETURNING p_rec_creditdetl.list_amt,	p_rec_creditdetl.unit_sales_amt 

				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF l_rec_original_creditdetl.unit_sales_amt != p_rec_creditdetl.unit_sales_amt THEN 
				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF p_rec_creditdetl.invoice_num IS NULL THEN 

				## Not based upon invoice so SET costs & taxes
				##
				## IF NOT selected prodstatus - obtain tax_amt

				IF l_rec_prodstatus.part_code IS NULL THEN 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = glob_rec_warehouse.ware_code 
					AND part_code = p_rec_creditdetl.part_code 
				END IF 

				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 

				CALL calc_line_tax(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.tax_code, 
					p_rec_creditdetl.tax_code, 
					l_rec_prodstatus.sale_tax_amt, 
					p_rec_creditdetl.ship_qty, 
					p_rec_creditdetl.unit_cost_amt, 
					p_rec_creditdetl.unit_sales_amt) 
				RETURNING 
					p_rec_creditdetl.unit_tax_amt, 
					p_rec_creditdetl.ext_tax_amt 
			END IF 

	END CASE 
	#------------------------
	## Setup line quantities
	##

	IF p_rec_creditdetl.disc_amt IS NULL THEN 
		LET p_rec_creditdetl.disc_amt = 0 
	END IF 
	IF p_rec_creditdetl.invoice_num = 0 THEN 
		LET p_rec_creditdetl.invoice_num = NULL 
	END IF 
	IF p_rec_creditdetl.inv_line_num = 0 THEN 
		LET p_rec_creditdetl.inv_line_num = NULL 
	END IF 
	IF p_rec_creditdetl.ship_qty IS NULL THEN 
		LET p_rec_creditdetl.ship_qty = 0 
	END IF 
	IF p_rec_creditdetl.received_qty IS NULL THEN 
		LET p_rec_creditdetl.received_qty = p_rec_creditdetl.ship_qty 
	END IF 

	#--------------------------
	## Setup line cost amount
	##
	IF p_rec_creditdetl.unit_cost_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_cost_amt = 0 
	END IF 
	LET p_rec_creditdetl.ext_cost_amt = p_rec_creditdetl.unit_cost_amt 
	* p_rec_creditdetl.ship_qty 
	
	#--------------------------
	## Setup line tax amount
	##
	IF p_rec_creditdetl.unit_tax_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_tax_amt = 0 
	END IF 

	LET p_rec_creditdetl.ext_tax_amt = p_rec_creditdetl.unit_tax_amt * p_rec_creditdetl.ship_qty 
	
	#--------------------------
	## Setup line sale amount
	##
	IF p_rec_creditdetl.unit_sales_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_sales_amt = 0 
	END IF 
	
	LET p_rec_creditdetl.ext_sales_amt = p_rec_creditdetl.unit_sales_amt * p_rec_creditdetl.ship_qty 
	LET l_round_err = 0 

	INITIALIZE l_rec_tax.* TO NULL 

	LET l_taxable_amt = 0 
	LET l_tax_amt = 0 
	LET l_tax_amt2 = 0 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_credithead.tax_code 

	IF l_rec_tax.calc_method_flag = "T" THEN 
		INITIALIZE l_rec_tax2.* TO NULL 
		SELECT * INTO l_rec_tax2.* FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_creditdetl.tax_code 

		IF l_rec_tax2.calc_method_flag != "X" THEN 
			SELECT sum(ext_sales_amt) INTO l_taxable_amt 
			FROM t_creditdetl,tax 
			WHERE t_creditdetl.rowid != p_line_num 
			AND t_creditdetl.tax_code = tax.tax_code 
			AND calc_method_flag != "X" 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_taxable_amt = l_taxable_amt	+ p_rec_creditdetl.ext_sales_amt 

			CALL calc_total_tax(
				glob_rec_kandoouser.cmpy_code, 
				"T", 
				l_taxable_amt, 
				l_rec_tax.tax_code) 
			RETURNING l_tax_amt 

			SELECT sum(ext_tax_amt) INTO l_tax_amt2 FROM t_creditdetl 
			WHERE rowid != p_line_num 
			LET l_tax_amt2 = l_tax_amt2	+ p_rec_creditdetl.ext_tax_amt 

			IF l_tax_amt != l_tax_amt2 THEN 
				LET l_round_err = l_tax_amt2 - l_tax_amt 
			END IF 

			IF l_round_err != 0 THEN 
				LET p_rec_creditdetl.ext_tax_amt = p_rec_creditdetl.ext_tax_amt	- l_round_err 
			END IF 
		END IF 
	END IF 

	IF p_rec_creditdetl.ext_tax_amt IS NULL THEN 
		LET p_rec_creditdetl.ext_tax_amt = 0 
	END IF 

	LET p_rec_creditdetl.line_total_amt = p_rec_creditdetl.ext_sales_amt + p_rec_creditdetl.ext_tax_amt
	
	#write row to master global credit details array
	LET glob_arr_rec_creditdetl[p_line_num].* = p_rec_creditdetl.*

	#UPDATE --------------------------------	 
	UPDATE t_creditdetl	SET 
		part_code = p_rec_creditdetl.part_code, 
		cat_code = p_rec_creditdetl.cat_code, 
		ship_qty = p_rec_creditdetl.ship_qty, 
		line_text = p_rec_creditdetl.line_text, 
		ser_ind = p_rec_creditdetl.ser_ind, 
		uom_code = p_rec_creditdetl.uom_code, 
		unit_cost_amt = p_rec_creditdetl.unit_cost_amt, 
		ext_cost_amt = p_rec_creditdetl.ext_cost_amt, 
		disc_amt = p_rec_creditdetl.disc_amt, 
		unit_sales_amt = p_rec_creditdetl.unit_sales_amt, 
		ext_sales_amt = p_rec_creditdetl.ext_sales_amt, 
		unit_tax_amt = p_rec_creditdetl.unit_tax_amt, 
		ext_tax_amt = p_rec_creditdetl.ext_tax_amt, 
		line_total_amt = p_rec_creditdetl.line_total_amt, 
		seq_num = p_rec_creditdetl.seq_num, 
		line_acct_code = p_rec_creditdetl.line_acct_code, 
		level_code = p_rec_creditdetl.level_code, 
		comm_amt = p_rec_creditdetl.comm_amt, 
		tax_code = p_rec_creditdetl.tax_code, 
		reason_code = p_rec_creditdetl.reason_code, 
		received_qty = p_rec_creditdetl.received_qty, 
		invoice_num = p_rec_creditdetl.invoice_num, 
		inv_line_num = p_rec_creditdetl.inv_line_num, 
		price_uom_code = p_rec_creditdetl.price_uom_code, 
		prodgrp_code = p_rec_creditdetl.prodgrp_code, 
		maingrp_code = p_rec_creditdetl.maingrp_code, 
		proddept_code = p_rec_creditdetl.proddept_code, 
		list_amt = p_rec_creditdetl.list_amt 
		WHERE rowid = p_line_num
 
		RETURN glob_arr_rec_creditdetl[p_line_num].* 
END FUNCTION 
#############################################################################
# FUNCTION A41_creditdetl_update_line(p_line_num,p_rec_creditdetl)
#############################################################################

{
#############################################################################
# FUNCTION A41_creditdetl_update_line(p_rowid,p_rec_creditdetl)
#
#
#############################################################################
FUNCTION A41_creditdetl_update_line(p_rowid,p_rec_creditdetl) 
	DEFINE p_rowid INTEGER 
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.* 

	DEFINE l_rec_creditdetl2 RECORD LIKE creditdetl.* 
	DEFINE l_rec_s_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_temp_amt dec(16,2) 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_taxable_amt DECIMAL(16,2) 
	DEFINE l_round_err DECIMAL(16,2) 
	DEFINE l_tax_amt DECIMAL(16,2) 
	DEFINE l_tax_amt2 DECIMAL(16,2) 

	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_tax2 RECORD LIKE tax.* 

	SELECT * INTO l_rec_s_creditdetl.* 
	FROM t_creditdetl 
	WHERE rowid = p_rowid 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",9930,"Line must be re-entered.")	# 9930 Logic Error: Line must be re-entered.
		INITIALIZE p_rec_creditdetl.* TO NULL 
		RETURN p_rec_creditdetl.* 
	END IF 

	CASE 
		WHEN (l_rec_s_creditdetl.part_code IS NULL 
			AND p_rec_creditdetl.part_code IS null) 
			##
			## User editted non-product line
			##

		WHEN (l_rec_s_creditdetl.part_code IS NOT NULL 
			AND p_rec_creditdetl.part_code IS null) 
			##
			## User removed product code
			##
			LET p_rec_creditdetl.received_qty = 0 
			LET p_rec_creditdetl.maingrp_code = NULL 
			LET p_rec_creditdetl.prodgrp_code = NULL 
			LET p_rec_creditdetl.proddept_code = NULL 
			LET p_rec_creditdetl.cat_code = NULL 
			LET p_rec_creditdetl.uom_code = NULL 
			LET p_rec_creditdetl.ser_ind = NULL 
			LET p_rec_creditdetl.unit_cost_amt = 0 

		WHEN (l_rec_s_creditdetl.part_code IS NULL 
			AND p_rec_creditdetl.part_code IS NOT null) 
			##
			## User added product line
			##
			SELECT * INTO l_rec_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_creditdetl.part_code 

			LET p_rec_creditdetl.maingrp_code = l_rec_product.maingrp_code 
			LET p_rec_creditdetl.prodgrp_code = l_rec_product.prodgrp_code 
			LET p_rec_creditdetl.line_text = l_rec_product.desc_text 

			SELECT dept_code INTO p_rec_creditdetl.proddept_code 
			FROM maingrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND maingrp_code = p_rec_creditdetl.maingrp_code 

			LET p_rec_creditdetl.cat_code = l_rec_product.cat_code 
			LET p_rec_creditdetl.uom_code = l_rec_product.sell_uom_code 
			LET p_rec_creditdetl.ser_ind = l_rec_product.serial_flag 

			IF p_rec_creditdetl.line_acct_code IS NULL THEN 
				## May possibly be using line_account FROM invoice
				SELECT sale_acct_code INTO p_rec_creditdetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_creditdetl.cat_code 
				IF status = NOTFOUND OR p_rec_creditdetl.line_acct_code IS NULL THEN 
					ERROR kandoomsg2("U",9930,"Credit Account NOT setup.") # 9930 Logic Error: Credit Account NOT setup.
				END IF 
			END IF 

			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = glob_rec_warehouse.ware_code 
			AND part_code = p_rec_creditdetl.part_code 

			IF p_rec_creditdetl.invoice_num IS NOT NULL THEN 
				## Imaged FROM warehouse so dont recal prices, costs, tax etc.
			ELSE 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 
				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 

				CALL unit_price(p_rec_creditdetl.part_code,p_rec_creditdetl.level_code) 
				RETURNING p_rec_creditdetl.list_amt,	p_rec_creditdetl.unit_sales_amt 

				CALL calc_line_tax(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.tax_code, 
					p_rec_creditdetl.tax_code, 
					l_rec_prodstatus.sale_tax_amt, 
					p_rec_creditdetl.ship_qty, 
					p_rec_creditdetl.unit_cost_amt, 
					p_rec_creditdetl.unit_sales_amt) 
				RETURNING p_rec_creditdetl.unit_tax_amt,	p_rec_creditdetl.ext_tax_amt 
			END IF 

		WHEN (l_rec_s_creditdetl.part_code IS NOT NULL AND p_rec_creditdetl.part_code IS NOT null) 
			IF l_rec_s_creditdetl.part_code != p_rec_creditdetl.part_code THEN 
				##
				## User changed product code
				##
				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_creditdetl.part_code 

				LET p_rec_creditdetl.maingrp_code = l_rec_product.maingrp_code 
				LET p_rec_creditdetl.prodgrp_code = l_rec_product.prodgrp_code 

				SELECT dept_code INTO p_rec_creditdetl.proddept_code 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_creditdetl.maingrp_code 

				LET p_rec_creditdetl.cat_code = l_rec_product.cat_code 
				LET p_rec_creditdetl.uom_code = l_rec_product.sell_uom_code 
				LET p_rec_creditdetl.ser_ind = l_rec_product.serial_flag 

				SELECT sale_acct_code INTO p_rec_creditdetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_creditdetl.cat_code 

				LET p_rec_creditdetl.line_text = l_rec_product.desc_text 

				SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = glob_rec_warehouse.ware_code 
				AND part_code = p_rec_creditdetl.part_code 

				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 

				## IF product change THEN break link TO invoice

				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF l_rec_s_creditdetl.level_code != p_rec_creditdetl.level_code 
			OR l_rec_s_creditdetl.part_code != p_rec_creditdetl.part_code THEN 

				## IF tax OR price change THEN break link TO invoice

				CALL unit_price(p_rec_creditdetl.part_code,p_rec_creditdetl.level_code) 
				RETURNING p_rec_creditdetl.list_amt,	p_rec_creditdetl.unit_sales_amt 

				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF l_rec_s_creditdetl.unit_sales_amt != p_rec_creditdetl.unit_sales_amt THEN 
				LET p_rec_creditdetl.invoice_num = NULL 
				LET p_rec_creditdetl.inv_line_num = NULL 
			END IF 

			IF p_rec_creditdetl.invoice_num IS NULL THEN 

				## Not based upon invoice so SET costs & taxes
				##
				## IF NOT selected prodstatus - obtain tax_amt

				IF l_rec_prodstatus.part_code IS NULL THEN 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = glob_rec_warehouse.ware_code 
					AND part_code = p_rec_creditdetl.part_code 
				END IF 

				LET p_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_credithead.conv_qty 
				LET p_rec_creditdetl.tax_code = l_rec_prodstatus.sale_tax_code 

				CALL calc_line_tax(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_credithead.tax_code, 
					p_rec_creditdetl.tax_code, 
					l_rec_prodstatus.sale_tax_amt, 
					p_rec_creditdetl.ship_qty, 
					p_rec_creditdetl.unit_cost_amt, 
					p_rec_creditdetl.unit_sales_amt) 
				RETURNING 
					p_rec_creditdetl.unit_tax_amt, 
					p_rec_creditdetl.ext_tax_amt 
			END IF 

	END CASE 
	##
	## Setup line quantities
	##

	IF p_rec_creditdetl.disc_amt IS NULL THEN 
		LET p_rec_creditdetl.disc_amt = 0 
	END IF 
	IF p_rec_creditdetl.invoice_num = 0 THEN 
		LET p_rec_creditdetl.invoice_num = NULL 
	END IF 
	IF p_rec_creditdetl.inv_line_num = 0 THEN 
		LET p_rec_creditdetl.inv_line_num = NULL 
	END IF 
	IF p_rec_creditdetl.ship_qty IS NULL THEN 
		LET p_rec_creditdetl.ship_qty = 0 
	END IF 
	IF p_rec_creditdetl.received_qty IS NULL THEN 
		LET p_rec_creditdetl.received_qty = p_rec_creditdetl.ship_qty 
	END IF 

	##
	## Setup line cost amount
	##
	IF p_rec_creditdetl.unit_cost_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_cost_amt = 0 
	END IF 
	LET p_rec_creditdetl.ext_cost_amt = p_rec_creditdetl.unit_cost_amt 
	* p_rec_creditdetl.ship_qty 
	##
	## Setup line tax amount
	##
	IF p_rec_creditdetl.unit_tax_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_tax_amt = 0 
	END IF 

	LET p_rec_creditdetl.ext_tax_amt = p_rec_creditdetl.unit_tax_amt * p_rec_creditdetl.ship_qty 
	##
	## Setup line sale amount
	##
	IF p_rec_creditdetl.unit_sales_amt IS NULL THEN 
		LET p_rec_creditdetl.unit_sales_amt = 0 
	END IF 
	
	LET p_rec_creditdetl.ext_sales_amt = p_rec_creditdetl.unit_sales_amt * p_rec_creditdetl.ship_qty 
	LET l_round_err = 0 

	INITIALIZE l_rec_tax.* TO NULL 

	LET l_taxable_amt = 0 
	LET l_tax_amt = 0 
	LET l_tax_amt2 = 0 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_credithead.tax_code 

	IF l_rec_tax.calc_method_flag = "T" THEN 
		INITIALIZE l_rec_tax2.* TO NULL 
		SELECT * INTO l_rec_tax2.* FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_creditdetl.tax_code 

		IF l_rec_tax2.calc_method_flag != "X" THEN 
			SELECT sum(ext_sales_amt) INTO l_taxable_amt 
			FROM t_creditdetl,tax 
			WHERE t_creditdetl.rowid != p_rowid 
			AND t_creditdetl.tax_code = tax.tax_code 
			AND calc_method_flag != "X" 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_taxable_amt = l_taxable_amt	+ p_rec_creditdetl.ext_sales_amt 

			CALL calc_total_tax(
				glob_rec_kandoouser.cmpy_code, 
				"T", 
				l_taxable_amt, 
				l_rec_tax.tax_code) 
			RETURNING l_tax_amt 

			SELECT sum(ext_tax_amt) INTO l_tax_amt2 FROM t_creditdetl 
			WHERE rowid != p_rowid 
			LET l_tax_amt2 = l_tax_amt2	+ p_rec_creditdetl.ext_tax_amt 

			IF l_tax_amt != l_tax_amt2 THEN 
				LET l_round_err = l_tax_amt2 - l_tax_amt 
			END IF 

			IF l_round_err != 0 THEN 
				LET p_rec_creditdetl.ext_tax_amt = p_rec_creditdetl.ext_tax_amt	- l_round_err 
			END IF 
		END IF 
	END IF 

	IF p_rec_creditdetl.ext_tax_amt IS NULL THEN 
		LET p_rec_creditdetl.ext_tax_amt = 0 
	END IF 

	LET p_rec_creditdetl.line_total_amt = p_rec_creditdetl.ext_sales_amt + p_rec_creditdetl.ext_tax_amt 
	UPDATE t_creditdetl 
	SET 
		part_code = p_rec_creditdetl.part_code, 
		cat_code = p_rec_creditdetl.cat_code, 
		ship_qty = p_rec_creditdetl.ship_qty, 
		line_text = p_rec_creditdetl.line_text, 
		ser_ind = p_rec_creditdetl.ser_ind, 
		uom_code = p_rec_creditdetl.uom_code, 
		unit_cost_amt = p_rec_creditdetl.unit_cost_amt, 
		ext_cost_amt = p_rec_creditdetl.ext_cost_amt, 
		disc_amt = p_rec_creditdetl.disc_amt, 
		unit_sales_amt = p_rec_creditdetl.unit_sales_amt, 
		ext_sales_amt = p_rec_creditdetl.ext_sales_amt, 
		unit_tax_amt = p_rec_creditdetl.unit_tax_amt, 
		ext_tax_amt = p_rec_creditdetl.ext_tax_amt, 
		line_total_amt = p_rec_creditdetl.line_total_amt, 
		seq_num = p_rec_creditdetl.seq_num, 
		line_acct_code = p_rec_creditdetl.line_acct_code, 
		level_code = p_rec_creditdetl.level_code, 
		comm_amt = p_rec_creditdetl.comm_amt, 
		tax_code = p_rec_creditdetl.tax_code, 
		reason_code = p_rec_creditdetl.reason_code, 
		received_qty = p_rec_creditdetl.received_qty, 
		invoice_num = p_rec_creditdetl.invoice_num, 
		inv_line_num = p_rec_creditdetl.inv_line_num, 
		price_uom_code = p_rec_creditdetl.price_uom_code, 
		prodgrp_code = p_rec_creditdetl.prodgrp_code, 
		maingrp_code = p_rec_creditdetl.maingrp_code, 
		proddept_code = p_rec_creditdetl.proddept_code, 
		list_amt = p_rec_creditdetl.list_amt 
		WHERE rowid = p_rowid 
		RETURN p_rec_creditdetl.* 
END FUNCTION 
#############################################################################
# FUNCTION A41_creditdetl_update_line(p_rowid,p_rec_creditdetl)
#############################################################################

}

#############################################################################
# FUNCTION disp_credit_detail(p_rec_creditdetl)
#
#
#############################################################################
FUNCTION disp_credit_detail(p_rec_creditdetl) 
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_bal_amt LIKE customer.bal_amt 
	DEFINE l_desc_text CHAR(30) 

	CALL A41_credit_total_calculation_display() 
	
	DISPLAY BY NAME 
		p_rec_creditdetl.line_text, 
		p_rec_creditdetl.tax_code, 
		p_rec_creditdetl.invoice_num, 
		p_rec_creditdetl.inv_line_num 

	IF p_rec_creditdetl.tax_code IS NULL THEN 
		CLEAR tax.desc_text 
	ELSE 
		SELECT desc_text INTO l_desc_text 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_creditdetl.tax_code 
		DISPLAY l_desc_text TO tax.desc_text 

	END IF 

	LET l_bal_amt = glob_rec_customer.bal_amt	+ glob_rec_orig_cred_amt	- glob_rec_credithead.total_amt 
	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt - l_bal_amt 

	DISPLAY BY NAME 
		glob_rec_customer.name_text, 
		glob_rec_warehouse.desc_text, 
		glob_rec_customer.cred_bal_amt 

	DISPLAY l_bal_amt TO customer.bal_amt 

END FUNCTION 
#############################################################################
# END FUNCTION disp_credit_detail(p_rec_creditdetl)
#############################################################################