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

	Source code beautified by beautify.pl on 2020-01-03 09:12:41	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS8a - Contains the product price load file FORMAT functions
#                FOR each client including specific functions FOR the
#                generic REPORT 'IS8_1_list'


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "IS8_GLOBALS.4gl" 

#Load File formats FOR Product Price Load
#
# Load File INPUT IS the interface FOR the entry of the necessary parameters
# WHEN loading up supplier price/cost files.
#
FUNCTION load_file_input() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_vendor RECORD LIKE vendor.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_path_text LIKE loadparms.path_text, 
	pr_file_text LIKE loadparms.file_text, 
	pr_load_ind LIKE loadparms.load_ind, 
	pr_temp_text CHAR(100), 
	pr_load_file CHAR(60) 

	LET msgresp=kandoomsg("I",9256,"") 
	#9256 Enter Supplier Quotation Load Details - ESC TO Continue"
	IF pr_loadparms.load_ind IS NULL THEN 
		DECLARE c_loadparms CURSOR FOR 
		SELECT * INTO pr_loadparms.* FROM loadparms 
		WHERE module_code = TRAN_TYPE_INVOICE_IN 
		AND ( format_ind = "4" OR format_ind = '5') 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c_loadparms 
		FETCH c_loadparms INTO pr_loadparms.* 
		CLOSE c_loadparms 
		LET pr_path_text = pr_loadparms.path_text 
		LET pr_file_text = pr_loadparms.file_text 
	END IF 
	DISPLAY BY NAME pr_loadparms.load_ind, 
	pr_loadparms.desc_text, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text 

	LET pr_loadvalues.mkcost_per = 0 
	LET pr_loadvalues.mkprice_per = 0 
	LET pr_loadvalues.expiry_date = today 
	LET pr_loadvalues.status_ind = "1" 
	INPUT pr_loadparms.load_ind, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text, 
	pr_loadvalues.mkcost_per, 
	pr_loadvalues.mkprice_per, 
	pr_loadvalues.vend_code, 
	pr_loadvalues.curr_code, 
	pr_loadvalues.break_qty, 
	pr_loadvalues.lead_time_qty, 
	pr_loadvalues.expiry_date, 
	pr_loadvalues.desc_text, 
	pr_loadvalues.status_ind WITHOUT DEFAULTS 
	FROM load_ind, 
	file_text, 
	path_text, 
	mkcost_per, 
	mkprice_per, 
	vend_code, 
	curr_code, 
	break_qty, 
	lead_time_qty, 
	expiry_date, 
	prodquote.desc_text, 
	status_ind 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS8a","input-pr_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 



		ON KEY (control-b) infield (vend_code) 
			LET pr_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,pr_loadvalues.vend_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_loadvalues.vend_code = pr_temp_text 
			END IF 
			NEXT FIELD vend_code 

		ON KEY (control-b) infield (curr_code) 
			LET pr_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_loadvalues.curr_code = pr_temp_text 
			END IF 
			NEXT FIELD curr_code 


		AFTER FIELD load_ind 
			IF pr_loadparms.load_ind IS NULL THEN 
				LET msgresp = kandoomsg("A",9208,"") 
				#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT * INTO pr_loadparms.* FROM loadparms 
				WHERE load_ind = pr_loadparms.load_ind 
				AND module_code = TRAN_TYPE_INVOICE_IN 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("A",9206,"") 
					#9206 Invalid Load indicator
					NEXT FIELD load_ind 
				ELSE 
					LET pr_load_ind = pr_loadparms.load_ind 
				END IF 
			END IF 

		AFTER FIELD file_text 
			IF pr_loadparms.file_text IS NOT NULL 
			AND pr_loadparms.file_text[1,1] != " " THEN 
				LET pr_file_text = pr_loadparms.file_text 
			ELSE 
				LET pr_loadparms.file_text = NULL 
				LET pr_file_text = NULL 
			END IF 

		AFTER FIELD path_text 
			IF pr_loadparms.path_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9129,"") 
				#U9129 Path name must be entered
				NEXT FIELD path_text 
			ELSE 
				LET pr_path_text = pr_loadparms.path_text clipped 
			END IF 
			LET pr_load_file = pr_path_text clipped, 
			"/",pr_file_text clipped 
			IF NOT file_valid(pr_load_file) THEN 
				LET msgresp=kandoomsg("U",9115,"") 
				#9115 The load file does NOT exist...
				NEXT FIELD file_text 
			END IF 

		AFTER FIELD vend_code 
			IF pr_loadvalues.vend_code IS NULL THEN 
				IF pr_loadparms.format_ind = '5' THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					#9102" Value must be entered
					NEXT FIELD vend_code 
				END IF 
			ELSE 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_loadvalues.vend_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("P",9105,"") 
					#9105" Vendor NOT found - try window"
					NEXT FIELD vend_code 
				ELSE 
					DISPLAY BY NAME pr_vendor.name_text 

				END IF 
			END IF 

		AFTER FIELD curr_code 
			IF pr_loadvalues.curr_code IS NULL THEN 
				IF pr_loadparms.format_ind = '5' THEN 
					LET msgresp=kandoomsg("U",9102,"") 
					#9102" Value must be entered
					NEXT FIELD curr_code 
				END IF 
			ELSE 
				SELECT * INTO pr_currency.* FROM currency 
				WHERE currency_code = pr_loadvalues.curr_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9073,"") 
					#9057 Currency Code NOT found - Try WIndow
					NEXT FIELD curr_code 
				ELSE 
					DISPLAY pr_currency.desc_text TO curr_desc 

				END IF 
			END IF 
		AFTER FIELD expiry_date 
			IF pr_loadvalues.expiry_date < today THEN 
				LET msgresp=kandoomsg("I",9260,"") 
				#9251 Expiry Date cannot be less than todays date
				NEXT FIELD expiry_date 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_loadparms.load_ind IS NULL THEN 
					LET msgresp = kandoomsg("A",9208,"") 
					#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				ELSE 
					LET pr_load_ind = pr_loadparms.load_ind 
				END IF 

				IF pr_loadparms.file_text IS NULL 
				OR pr_loadparms.file_text[1,1] = " " THEN 
					LET msgresp = kandoomsg("A",9166,"") 
					#U9166 File name must be entered.
					NEXT FIELD file_text 
				ELSE 
					LET pr_file_text = pr_loadparms.file_text clipped 
				END IF 

				IF pr_loadparms.path_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9129,"") 
					#U9129 Path name must be entered
					NEXT FIELD path_text 
				ELSE 
					LET pr_path_text = pr_loadparms.path_text clipped 
				END IF 

				LET pr_load_file = pr_path_text clipped, 
				"/",pr_file_text clipped 
				IF NOT file_valid(pr_load_file) THEN 
					LET msgresp=kandoomsg("U",9115,"") 
					#9115 The load file does NOT exist...
					NEXT FIELD file_text 
				END IF 

				IF pr_loadvalues.vend_code IS NULL THEN 
					IF pr_loadparms.format_ind = '5' THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102" Value must be entered
						NEXT FIELD vend_code 
					END IF 
				ELSE 
					SELECT * INTO pr_vendor.* FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_loadvalues.vend_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("P",9105,"") 
						#9105" Vendor NOT found - try window"
						NEXT FIELD vend_code 
					END IF 
				END IF 

				IF pr_loadvalues.curr_code IS NULL THEN 
					IF pr_loadparms.format_ind = '5' THEN 
						LET msgresp=kandoomsg("U",9102,"") 
						#9102" Value must be entered
						NEXT FIELD curr_code 
					END IF 
				ELSE 
					SELECT * INTO pr_currency.* FROM currency 
					WHERE currency_code = pr_loadvalues.curr_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("I",9073,"") 
						#9057 Currency Code NOT found - Try WIndow
						NEXT FIELD curr_code 
					END IF 
				END IF 
				IF pr_loadvalues.status_ind IS NULL THEN 
					LET pr_loadvalues.status_ind = "1" 
				END IF 
				IF pr_loadvalues.expiry_date < today THEN 
					LET msgresp=kandoomsg("I",9260,"") 
					#9251 Expiry Date cannot be less than todays date
					NEXT FIELD expiry_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLEAR FORM 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",8039,"") 
		#8039 Commence Supplier Product Quotation Load...
		IF msgresp = "Y" THEN 
			RETURN true 
		ELSE 
			CLEAR FORM 
			RETURN false 
		END IF 
	END IF 
END FUNCTION 
#
#
FUNCTION process_load_files() 
	DEFINE msgresp LIKE language.yes_flag 
	CASE pr_loadparms.format_ind 
		WHEN "4" ### LOAD FORMAT FOR gunns timber 
			IF NOT load_format_4() THEN 
				RETURN false 
			END IF 
			RETURN true 
		WHEN "5" ### LOAD FORMAT FOR alstom 
			IF NOT load_format_5() THEN 
				RETURN false 
			END IF 
			RETURN true 
		OTHERWISE 
			LET msgresp=kandoomsg("U",9116,"") 
			#9116 The Load File FORMAT indicator IS NOT valid
			RETURN false 
	END CASE 
END FUNCTION 
#
# GUNNS Timber specific supplier product quotation load FUNCTION (22/01/97)
#
FUNCTION load_format_4() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_file CHAR(200), 
	pr_temp_file CHAR(200), 
	pr_runner CHAR(500), 
	pr_status INTEGER, 
	pr_line_count,pr_counter,pr_insert_count,idx,pr_sqlerrd3 INTEGER, 
	pr_return, pr_error SMALLINT, 
	pr_loadline CHAR(500), 
	pr_chararray array[500] OF char, 
	pr_part_code LIKE product.part_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_curr_code LIKE currency.currency_code, 
	pr_bar_code LIKE prodquote.barcode_text, 
	pr_acct_text LIKE vendor.acct_text, 
	pr_err_message CHAR(80), 
	pr_err_line RECORD 
		error_number CHAR(12), 
		error_text CHAR(100), 
		line_number INTEGER 
	END RECORD, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_total_count INTEGER, 
	pr_perc_done FLOAT 

	--   OPEN WINDOW display_win AT 5,10 with 2 rows, 35 columns  -- albo  KD-758
	--      ATTRIBUTE(border,white)
	### Convert load file TO INFORMIX delimited FORMAT ###
	LET pr_file = pr_loadparms.path_text clipped, "/", 
	pr_loadparms.file_text 
	LET pr_temp_file = pr_file clipped,".tmp" 
	LET pr_runner = "../bin/DOS_to_UNL2.sh ", pr_file clipped, 
	" ",pr_temp_file clipped 
	LET msgresp=kandoomsg("U",1030,"") 
	#1030 Converting Load File...please wait
	RUN pr_runner RETURNING pr_status 
	IF pr_status THEN 
		LET msgresp=kandoomsg("I",9254,"") 
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("U",1028,"") 
	#1028 "Loading file..."
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_loadfile (loadline CHAR(500)) with no LOG 
	DELETE FROM t_loadfile 
	LOAD FROM pr_temp_file INSERT INTO t_loadfile 
	IF status != 0 THEN 
		IF status = -846 THEN 
			LET msgresp=kandoomsg("U",9119,"") 
			#9119 "Incorrect file FORMAT OR blank lines detected"
		ELSE 
			LET msgresp=kandoomsg("G",9144,"") 
			#9144 "Interface file does NOT exist - Check path AND file name"
		END IF 
		LET pr_runner = "rm ", pr_temp_file clipped, " 2>> ",trim(get_settings_logFile()) 
		RUN pr_runner RETURNING pr_status 
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	LET pr_runner = "rm ", pr_temp_file clipped, " 2>> ",trim(get_settings_logFile()) 
	RUN pr_runner RETURNING pr_status 
	SELECT unique 1 FROM t_loadfile 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("G",9146,"") 
		#9146 "Interface file IS empty - Check PC Transfer was successfull"
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	#######################################################################
	### Process the rows in the temporary table t_loadfile
	### 0. IF row in t_loadfile IS NULL THEN consider EOF AND EXIT
	### 1. Do NOT process rows with position 1-1 with a 'T' (Trailer)
	### 2. Do NOT process rows with position 1-3 with characters (Header)
	### 3. Process remaining rows as detail lines
	###    3.1 Extract the necessary strings FROM the row retrieved
	###        ### Modified WR0061. New positions in []
	###        - APN (Barcode)    (field 1)  position 1-13 [2-14]
	###        - Vendor Code      (field 10) position 160-169 [192-201]
	###        - Supplier Part #  (field 11) position 170-184 [202-216]
	###        - Listed Price     (field 22) position 214-220 [271-278]
	###        - Bench Mark RRP   (field 23) position 221-227 [279-286]
	###        - Unit Cost        (field 25) position 236-242 [295-303]
	###    3.2 Match Supplier Part # TO Product.Barcode
	###        No match will produce error AND row will NOT be processed
	###    3.3 Match Vendor Code     TO Vendor.Acct_Code
	###        IF Vendor acct_text extracted FROM load file does NOT match
	###        a DB Vendor THEN IF there IS a default Vendor Code this will
	###        be used OTHERWISE an error IS produced AND row will NOT be
	###        processed
	###    3.4 Prepare prodquote INSERT row by filling in remaining blank
	###        fields with default VALUES FROM entry SCREEN AND INSERT INTO
	###        prodquote
	#######################################################################
	### Collect the default currency FOR the GL
	SELECT curr_code INTO pr_curr_code FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	### Create a temporary index on product table FOR barcode text
	#create index i_barcode on product(barcode_text)
	#create index i_accttext on vendor(acct_text)
	### Prepare the defaults FOR the IS8 Product Load Error Report
	CALL set_defaults(1) 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	START REPORT is8_1_list TO pr_output 
	### SELECT how many records are being processed
	SELECT count(*) INTO pr_total_count FROM t_loadfile 
	DECLARE c_loadscan CURSOR with HOLD FOR 
	SELECT * FROM t_loadfile 
	LET pr_line_count = 0 
	LET pr_insert_count = 0 
	LET pr_error = false 
	LET pr_return = true ### so far so good 
	LET msgresp=kandoomsg("U",1031,"") 
	#1031 "Processing load file..."
	DISPLAY " Percentage Complete: " at 2,2 
	FOREACH c_loadscan INTO pr_loadline 
		LET pr_line_count = pr_line_count + 1 
		IF (not (pr_line_count mod 2)) OR 
		(pr_line_count = 1) 
		THEN 
			LET pr_perc_done = ((pr_line_count/pr_total_count)*100) 
			DISPLAY pr_perc_done USING "###.#%" at 2,26 
		END IF 
		LET pr_part_code = NULL 
		LET pr_vend_code = NULL 
		IF int_flag OR quit_flag THEN 
			#8023 Continue Processing (Y/N)
			IF kandoomsg("U",8023,"") = "N" THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOREACH 
			END IF 
		END IF 
		### Process EOF AND nulls ###
		IF pr_loadline IS NULL THEN 
			LET pr_return = false ### NOT so good 
			EXIT FOREACH 
		END IF 
		### Process the Trailers/Characters in first CHAR of line ###
		### WR0061 IF pr_loadline[1,1] matches "[A-Z]" THEN
		IF pr_loadline[1,1] != "P" THEN 
			CONTINUE FOREACH 
		END IF 
		### Process the rows ###
		### Verify Product Barcode ###
		WHENEVER ERROR CONTINUE 
		# WR0061 LET pr_bar_code = pr_loadline[1,13]
		LET pr_bar_code = pr_loadline[2,14] 
		SELECT part_code INTO pr_part_code 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bar_code_text = pr_bar_code 
		LET pr_status = sqlca.sqlcode 
		CASE pr_status 
			WHEN 100 # NOT found 
				LET pr_error = true 
				LET pr_err_line.error_number = "001" 
				LET pr_err_line.error_text = "Found no reference TO a product ", 
				"WHEN matching ", 
				"TO APN (Barcode)", 
				" - ", pr_bar_code clipped 
				LET pr_err_line.line_number = pr_line_count 
				OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
				CONTINUE FOREACH 
			WHEN -284 
				LET pr_error = true 
				LET pr_err_line.error_number = "002" 
				LET pr_err_line.error_text = "Found more than 1 product ", 
				"referenced WHEN ", 
				"matching TO products by APN (Barcode)", 
				" - ", pr_bar_code clipped 
				LET pr_err_line.line_number = pr_line_count 
				OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
				CONTINUE FOREACH 
		END CASE 
		IF pr_loadvalues.vend_code IS NULL THEN 
			### Verify Vendor Code ###
			#WR0061 LET pr_acct_text = pr_loadline[160,169]
			LET pr_acct_text = pr_loadline[192,201] 
			SELECT vend_code INTO pr_vend_code 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_text = pr_acct_text 
			LET pr_status = sqlca.sqlcode 
			CASE pr_status 
				WHEN 100 # the vendor was NOT found 
					LET pr_error = true 
					LET pr_err_line.error_number = "003" 
					LET pr_err_line.error_text = "Found NO vendor ", 
					"reference WHEN ", 
					"matching TO Vendors Account Text - ", 
					pr_acct_text clipped 
					LET pr_err_line.line_number = pr_line_count 
					OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
					CONTINUE FOREACH 
				WHEN -284 # more than one vendor with same acct_text 
					LET pr_error = true 
					LET pr_err_line.error_number = "004" 
					LET pr_err_line.error_text = "Found more than 1 ", 
					"vendor referenced WHEN ", 
					"matching TO Vendors Account Text - ", 
					pr_acct_text clipped 
					LET pr_err_line.line_number = pr_line_count 
					OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
					CONTINUE FOREACH 
			END CASE 
		END IF 
		WHENEVER ERROR stop 
		LET idx = idx + 1 
		INITIALIZE pr_prodquote.* TO NULL 
		LET pr_prodquote.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodquote.part_code = pr_part_code 
		### Substitute the vend_code FROM the entry SCREEN IF NOT NULL
		IF pr_loadvalues.vend_code IS NOT NULL THEN 
			LET pr_prodquote.vend_code = pr_loadvalues.vend_code 
		ELSE 
			LET pr_prodquote.vend_code = pr_vend_code 
		END IF 
		# WR0061 LET pr_prodquote.oem_text = pr_loadline[170,184]
		# WR0061 LET pr_prodquote.list_amt = pr_loadline[226,232]
		# WR0061 LET pr_prodquote.cost_amt = pr_loadline[248,254]
		LET pr_prodquote.oem_text = pr_loadline[202,216] 
		LET pr_prodquote.list_amt = pr_loadline[271,278] 
		LET pr_prodquote.cost_amt = pr_loadline[295,303] 
		### Convert the cost AND list amounts WHERE there IS a markup entered
		IF pr_loadvalues.mkprice_per != 0 THEN 
			LET pr_prodquote.list_amt = pr_prodquote.list_amt + 
			((pr_loadvalues.mkprice_per/100)* 
			pr_prodquote.list_amt) 
		END IF 
		IF pr_loadvalues.mkcost_per != 0 THEN 
			LET pr_prodquote.cost_amt = pr_prodquote.cost_amt + 
			((pr_loadvalues.mkcost_per/100)* 
			pr_prodquote.cost_amt) 
		END IF 
		### Apply the default AND remaining VALUES
		IF pr_loadvalues.break_qty IS NOT NULL THEN 
			LET pr_prodquote.break_qty = pr_loadvalues.break_qty 
		END IF 
		### Set up the freight amount
		LET pr_prodquote.freight_amt = 0 
		### Substitute the curr_code FROM the netry SCREEN IF NOT NULL
		IF pr_loadvalues.curr_code IS NOT NULL THEN 
			LET pr_prodquote.curr_code = pr_loadvalues.curr_code 
			LET pr_prodquote.frgt_curr_code = pr_loadvalues.curr_code 
		ELSE 
			LET pr_prodquote.curr_code = pr_curr_code 
			LET pr_prodquote.frgt_curr_code = pr_curr_code 
		END IF 
		### Substitute the lead_time_qty IF NOT NULL
		IF pr_loadvalues.lead_time_qty IS NOT NULL THEN 
			LET pr_prodquote.lead_time_qty = pr_loadvalues.lead_time_qty 
		END IF 
		IF pr_loadvalues.expiry_date IS NULL THEN 
			LET pr_prodquote.expiry_date = today 
		ELSE 
			LET pr_prodquote.expiry_date = pr_loadvalues.expiry_date 
		END IF 
		LET pr_prodquote.desc_text = pr_loadvalues.desc_text 
		# WR0061 LET pr_prodquote.barcode_text = pr_loadline[1,13]
		LET pr_prodquote.barcode_text = pr_loadline[2,14] 
		LET pr_prodquote.status_ind = pr_loadvalues.status_ind 
		LET pr_prodquote.entry_date = today 
		LET pr_prodquote.format_ind = pr_loadparms.format_ind 
		BEGIN WORK 
			WHENEVER ERROR CONTINUE 
			INSERT INTO prodquote VALUES (pr_prodquote.cmpy_code, 
			pr_prodquote.part_code, 
			pr_prodquote.vend_code, 
			pr_prodquote.break_qty, 
			pr_prodquote.cost_amt, 
			pr_prodquote.freight_amt, 
			pr_prodquote.curr_code, 
			pr_prodquote.frgt_curr_code, 
			pr_prodquote.lead_time_qty, 
			pr_prodquote.expiry_date, 
			pr_prodquote.desc_text, 
			pr_prodquote.list_amt, 
			pr_prodquote.oem_text, 
			pr_prodquote.barcode_text, 
			pr_prodquote.status_ind, 
			pr_prodquote.entry_date, 
			pr_prodquote.format_ind) 
			IF status !=0 THEN 
				CASE 
					WHEN status = -239 
						LET pr_error = true 
						LET pr_err_line.error_number = "005" 
						LET pr_err_line.error_text = "Load file line already exists in ", 
						"Product Quotations table ", 
						"- Vendor: " , 
						pr_prodquote.vend_code clipped, " ", 
						"- Product: ", 
						pr_prodquote.part_code clipped 
						LET pr_err_line.line_number = pr_line_count 
					OTHERWISE 
						LET pr_status = status 
						LET pr_error = true 
						LET pr_err_line.error_number = "006" 
						LET pr_err_line.error_text = "Problem with loading row - ", 
						"Status returned: ", 
						pr_status clipped 
						LET pr_err_line.line_number = pr_line_count 
				END CASE 
				OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
				ROLLBACK WORK 
			ELSE 
			COMMIT WORK 
			LET pr_insert_count = pr_insert_count + 1 
		END IF 
		WHENEVER ERROR stop 
	END FOREACH 
	FINISH REPORT is8_1_list 
	CALL upd_reports(pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num) 
	WHENEVER ERROR CONTINUE 
	#drop index i_barcode
	#drop index i_accttext
	DROP TABLE t_loadfile 
	IF pr_error THEN 
		LET msgresp=kandoomsg("U",9120,"") 
		#9120 There were errors detected
	END IF 
	LET msgresp=kandoomsg("U",8025,pr_insert_count) 
	#9255 "999 rows successfully loaded (Any Key)
	--   CLOSE WINDOW display_win  -- albo  KD-758
	RETURN pr_return 
END FUNCTION 


#
# Alstom specific quotation load FUNCTION
#
FUNCTION load_format_5() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_temp_file CHAR(200), 
	pr_temp_file2 CHAR(200), 
	pr_runner CHAR(500), 
	pr_status INTEGER, 
	pr_line_count INTEGER, 
	pr_insert_count INTEGER, 
	pr_error SMALLINT, 
	pr_return SMALLINT, 
	pr_load_quote RECORD 
		part_code LIKE product.oem_text, 
		desc_text LIKE product.desc_text, 
		cost CHAR(12) 
	END RECORD , 
	pr_part_code LIKE product.part_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_curr_code LIKE currency.currency_code, 
	pr_err_line RECORD 
		error_number CHAR(12), 
		error_text CHAR(100), 
		line_number INTEGER 
	END RECORD, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_total_count INTEGER, 
	pr_perc_done FLOAT 

	--   OPEN WINDOW display_win AT 5,10 with 2 rows, 35 columns  -- albo  KD-758
	--      ATTRIBUTE(border,white)
	### Convert load file TO INFORMIX delimited FORMAT ###
	LET pr_temp_file = pr_loadparms.path_text clipped, "/", 
	pr_loadparms.file_text clipped 
	LET pr_temp_file2 = pr_temp_file clipped, ".tmp" 
	LET pr_runner = "mv -f ", pr_temp_file clipped, 
	" ", pr_temp_file2 clipped, " 2>> ",trim(get_settings_logFile()) 
	#   LET pr_runner = "../bin/DOS_to_UNL2.sh ", pr_loadparms.file_text clipped,
	#                   " ",pr_temp_file clipped
	LET msgresp=kandoomsg("U",1030,"") 
	#1030 Converting Load File...please wait
	RUN pr_runner RETURNING pr_status 
	IF pr_status THEN 
		LET msgresp=kandoomsg("I",9254,"") 
		#9254 A problem occured converting the load file. See System
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("U",1028,"") 
	#1028 "Loading file..."
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t5_loadfile(part_code CHAR(30), 
	desc_text CHAR(30), 
	cost CHAR(12) ) with no LOG 
	DELETE FROM t5_loadfile 
	LOAD FROM pr_temp_file2 delimiter "|" INSERT INTO t5_loadfile 
	IF status != 0 THEN 
		IF status = -846 THEN 
			LET msgresp=kandoomsg("U",9119,"") 
			#9119 "Incorrect file FORMAT OR blank lines detected"
		ELSE 
			LET msgresp=kandoomsg("G",9144,"") 
			#9144 "Interface file does NOT exist - Check path AND file name
		END IF 
		LET pr_runner = "rm ", pr_temp_file clipped, " 2>> ",trim(get_settings_logFile()) 
		RUN pr_runner RETURNING pr_status 
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	LET pr_runner = "rm ", pr_temp_file clipped, " 2>> ",trim(get_settings_logFile()) 
	RUN pr_runner RETURNING pr_status 

	#####################################################################
	### Process the rows in the temporary table t5_loadfile
	###  FORMAT
	###      Product Code
	###      Description Text
	###      Product Cost in cents
	#####################################################################
	### Collect the default currency FOR the GL
	SELECT curr_code INTO pr_curr_code FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	### Prepare the defaults FOR the IS8 Product Load Error Report
	CALL set_defaults(1) 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	START REPORT is8_1_list TO pr_output 

	SELECT count(*) INTO pr_total_count FROM t5_loadfile 
	IF pr_total_count = 0 THEN 
		LET msgresp=kandoomsg("G",9146,"") 
		#9146 "Interface file IS empty - Check PC Transfer was successfull
		--      CLOSE WINDOW display_win  -- albo  KD-758
		RETURN false 
	END IF 
	LET pr_line_count = 0 
	LET pr_insert_count = 0 
	LET pr_error = false 
	LET pr_return = true 
	LET msgresp=kandoomsg("U",1031,"") 
	#1031 "Processing load file..."
	DISPLAY " Percentage Complete: " at 2,2 
	DELETE FROM prodquote 
	WHERE vend_code = pr_loadvalues.vend_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE c_loadscan1 CURSOR with HOLD FOR 
	SELECT * FROM t5_loadfile 
	FOREACH c_loadscan1 INTO pr_load_quote.* 
		LET pr_line_count = pr_line_count + 1 
		IF (not (pr_line_count mod 2)) 
		OR (pr_line_count = 1) THEN 
			LET pr_perc_done = ((pr_line_count/pr_total_count)*100) 
			DISPLAY pr_perc_done USING "###.#%" at 2,26 
		END IF 
		LET pr_part_code = NULL 
		LET pr_vend_code = NULL 
		IF int_flag OR quit_flag THEN 
			#8023 Continue Processing (Y/N)
			IF kandoomsg("U",8023,"") = "N" THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOREACH 
			END IF 
		END IF 
		WHENEVER ERROR CONTINUE 
		LET pr_prodquote.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodquote.part_code = pr_load_quote.part_code clipped 
		LET pr_prodquote.oem_text = pr_load_quote.part_code clipped 
		LET pr_prodquote.break_qty = 0 
		LET pr_prodquote.freight_amt = 0 
		LET pr_prodquote.lead_time_qty = 0 
		IF pr_loadvalues.desc_text IS NULL THEN 
			LET pr_prodquote.desc_text = pr_load_quote.desc_text clipped 
		ELSE 
			LET pr_prodquote.desc_text = pr_loadvalues.desc_text 
		END IF 
		LET pr_prodquote.vend_code = pr_loadvalues.vend_code 
		LET pr_prodquote.list_amt = 0 
		LET pr_prodquote.cost_amt = pr_load_quote.cost 
		IF pr_loadvalues.mkcost_per != 0 THEN 
			LET pr_prodquote.cost_amt = pr_prodquote.cost_amt + 
			((pr_loadvalues.mkcost_per/100)* 
			pr_prodquote.cost_amt) 
		END IF 
		### Apply the default AND remaining VALUES
		IF pr_loadvalues.break_qty IS NOT NULL THEN 
			LET pr_prodquote.break_qty = pr_loadvalues.break_qty 
		END IF 
		### Set up the freight amount
		LET pr_prodquote.freight_amt = 0 
		### Substitute the curr_code FROM the netry SCREEN IF NOT NULL
		IF pr_loadvalues.curr_code IS NOT NULL THEN 
			LET pr_prodquote.curr_code = pr_loadvalues.curr_code 
			LET pr_prodquote.frgt_curr_code = pr_loadvalues.curr_code 
		ELSE 
			LET pr_prodquote.curr_code = pr_curr_code 
			LET pr_prodquote.frgt_curr_code = pr_curr_code 
		END IF 
		### Substitute the lead_time_qty IF NOT NULL
		IF pr_loadvalues.lead_time_qty IS NOT NULL THEN 
			LET pr_prodquote.lead_time_qty = pr_loadvalues.lead_time_qty 
		END IF 
		IF pr_loadvalues.expiry_date IS NULL THEN 
			LET pr_prodquote.expiry_date = today 
		ELSE 
			LET pr_prodquote.expiry_date = pr_loadvalues.expiry_date 
		END IF 
		LET pr_prodquote.status_ind = pr_loadvalues.status_ind 
		LET pr_prodquote.entry_date = today 
		LET pr_prodquote.format_ind = pr_loadparms.format_ind 
		BEGIN WORK 
			WHENEVER ERROR CONTINUE 
			INSERT INTO prodquote VALUES (pr_prodquote.*) 
			IF status !=0 THEN 
				LET pr_status = status 
				LET pr_error = true 
				LET pr_err_line.error_number = "006" 
				LET pr_err_line.error_text = "Problem with loading row - ", 
				"Status returned: ", 
				pr_status clipped 
				LET pr_err_line.line_number = pr_line_count 
				OUTPUT TO REPORT is8_1_list(pr_err_line.*) 
				ROLLBACK WORK 
			ELSE 
			COMMIT WORK 
			LET pr_insert_count = pr_insert_count + 1 
		END IF 
		WHENEVER ERROR stop 
	END FOREACH 
	FINISH REPORT is8_1_list 
	CALL upd_reports(pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num) 
	WHENEVER ERROR CONTINUE 
	DROP TABLE t5_loadfile 
	IF pr_error THEN 
		LET msgresp=kandoomsg("U",9120,"") 
		#9120 There were errors detected
	END IF 
	LET msgresp=kandoomsg("U",8025,pr_insert_count) 
	#9255 "999 rows successfully loaded (Any Key)
	--   CLOSE WINDOW display_win  -- albo  KD-758
	RETURN pr_return 
END FUNCTION 

#==================================


#
#  Generic REPORT FUNCTION used TO REPORT on errors in loading load files
#
REPORT is8_1_list(pr_error_line) 
	DEFINE 
	pr_error_line RECORD 
		error_number CHAR(12), 
		error_text CHAR(100), 
		line_number INTEGER 
	END RECORD, 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL report_header(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.*,pageno) 
			RETURNING pa_line[1],pa_line[2],pa_line[3],pa_line[4] 
			PRINT COLUMN 001, pa_line[1] 
			PRINT COLUMN 001, pa_line[2] 
			PRINT COLUMN 001, pa_line[3] 
			PRINT COLUMN 001, glob_rec_kandooreport.line1_text 
			PRINT COLUMN 001, glob_rec_kandooreport.line2_text 
			PRINT COLUMN 001, pa_line[3] 
			PRINT COLUMN 001, "Load File Name : ", pr_loadparms.file_text clipped 
			SKIP 1 line 
			LET rpt_pageno = pageno 

		ON EVERY ROW 
			PRINT COLUMN 001, pr_error_line.error_number, 
			COLUMN 013, pr_error_line.error_text, 
			COLUMN 113, pr_error_line.line_number USING "#####&" 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 50, "**** END OF REPORT ",glob_rec_kandooreport.report_code clipped," ****" 

END REPORT 
