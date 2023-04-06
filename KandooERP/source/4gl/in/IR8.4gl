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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_data RECORD  # The RECORD includes currency AND tran_date so that WHEN it IS inserted INTO posttemp it contains equal columns 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	ref_num LIKE batchdetl.ref_num, 
	ref_text LIKE batchdetl.ref_text, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	for_debit_amt LIKE batchdetl.for_debit_amt, 
	for_credit_amt LIKE batchdetl.for_credit_amt, 
	base_debit_amt LIKE batchdetl.debit_amt, 
	base_credit_amt LIKE batchdetl.credit_amt, 
	currency_code LIKE batchdetl.currency_code, 
	conv_qty LIKE batchdetl.conv_qty, 
	tran_date DATE, 
	post_flag CHAR(1) 
END RECORD 
DEFINE modu_rec_inparms RECORD LIKE inparms.* 
DEFINE modu_passed_desc LIKE batchdetl.desc_text
DEFINE modu_tempper SMALLINT 
DEFINE modu_fisc_year SMALLINT

############################################################
# FUNCTION IR8_main()
# Purpose - IN Reporting on GL distribution
# Remarks - Based on IS5, Inventory Posting Process integrating INTO GL
############################################################
FUNCTION IR8_main()
	DEFINE l_cnt INTEGER

	CALL setModuleId("IR8") 

	#TODO replace with global l_rec_inparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_rec_inparms.* FROM inparms 
	WHERE inparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			inparms.parm_code = "1" 
	IF STATUS = NOTFOUND 
	THEN 
		CALL msgerror("","IN Parameters missing!")
		EXIT PROGRAM 
	END IF 

	SELECT COUNT(*) INTO l_cnt FROM journal 
	WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code AND
			journal.jour_code = modu_rec_inparms.inv_journal_code 
	IF l_cnt = 0 THEN 
		CALL msgerror("","Inventory Journal NOT found!")
		EXIT PROGRAM 
	END IF 

	# SET glob_rec_kandoouser.sign_on_code TO IN so GL knows WHERE it came FROM
	# SET up temp table
	# The table includes currency AND tran_date so that WHEN it IS passed TO
	# jourprint it contains equal columns TO modu_rec_data
	CREATE TEMP TABLE posttemp 
	( 
	tran_type_ind CHAR(3), 
	ref_num INTEGER, 
	ref_text CHAR(8), 
	acct_code CHAR(18), 
	desc_text CHAR(40), 
	for_debit_amt MONEY(14,2), 
	for_credit_amt MONEY(14,2), 
	base_debit_amt MONEY(14,2), 
	base_credit_amt MONEY(14,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	post_flag CHAR(1)
	) WITH NO LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I177 WITH FORM "I177" 
			 CALL windecoration_i("I177")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Post Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR8","menu-Post Report-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR8_rpt_process(IR8_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR8_rpt_process(IR8_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I177

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR8_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I177 with FORM "I177" 
			 CALL windecoration_i("I177") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR8_rpt_query()) #save where clause in env 
			CLOSE WINDOW I177 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR8_rpt_process(get_url_sel_text())
	END CASE

	DROP TABLE posttemp

END FUNCTION
############################################################
# END FUNCTION IR8_main()
############################################################

############################################################
# FUNCTION IR8_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR8_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON period.year_num,period.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IR8","construct-year_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLEAR FORM
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION IR8_rpt_query() 
############################################################

############################################################
# FUNCTION IR8_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR8_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_arr_period DYNAMIC ARRAY OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD 
	DEFINE idx INTEGER

	IF p_where_text IS NULL THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLEAR FORM
		RETURN NULL	
	END IF

	LET l_query_text = 
	"SELECT UNIQUE period.year_num,period.period_num ", 
	"FROM period WHERE period.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY period.year_num,period.period_num" 

	PREPARE getper FROM l_query_text 
	DECLARE c_per CURSOR FOR getper 

	LET idx = 0 
	FOREACH c_per INTO l_rec_period.year_num,l_rec_period.period_num 
		LET idx = idx + 1 
		LET l_arr_period[idx].year_num = l_rec_period.year_num 
		LET l_arr_period[idx].period_num = l_rec_period.period_num 
	END FOREACH 

	DISPLAY ARRAY l_arr_period TO sr_period.* ATTRIBUTE(UNBUFFERED)

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IR8","input-pa_period-1") -- albo kd-505 
			CALL fgl_dialog_setactionlabel("ACCEPT","Report","{CONTEXT}/public/querix/icon/svg/24/ic_accept_24px.svg",4,FALSE,"Press Report or double click on current row to print Report")            

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			MESSAGE "Press Report or double click on current row to print Report"

		ON ACTION ("ACCEPT","DOUBLECLICK") -- BEFORE FIELD period_num 
			LET idx = arr_curr()
			LET modu_tempper = l_arr_period[idx].period_num 
			LET modu_fisc_year = l_arr_period[idx].year_num 
			# Generating Post Report
			CALL inventory() 

	END DISPLAY

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLEAR FORM
		RETURN NULL
	END IF 

END FUNCTION 
############################################################
# END FUNCTION IR8_rpt_process() 
############################################################

############################################################
# FUNCTION inventory() 
# Purpose - Generating Post Report (COM_rpt_list_bdt) on all
# the accounts FROM the subsidiary ledgers. 
############################################################
FUNCTION inventory()
	DEFINE sel_text STRING
	DEFINE l_type CHAR(4)
	DEFINE bal_rec RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD	
	DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_start_chart SMALLINT
	DEFINE l_end_chart SMALLINT
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE pr_category RECORD LIKE category.*
	DEFINE pos_qty DECIMAL(10,3)
	DEFINE tran_qty DECIMAL(10,3)
	DEFINE tran_ind CHAR(3) 
	DEFINE temp_amt MONEY(14,2) 
	DEFINE its_ok INTEGER 
	DEFINE patch_over LIKE account.acct_code

	LET l_type = "SUMM"
	LET modu_rec_data.currency_code = l_rec_glparms.base_currency_code --> no value assigned ? (albo) 
	LET modu_rec_data.conv_qty = 1.0 
	DECLARE pl_curs CURSOR FOR 
	SELECT * INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodledg.year_num = modu_fisc_year 
	AND prodledg.period_num = modu_tempper 
	AND prodledg.trantype_ind IN ("S", "C") 
	FOREACH pl_curs 
		LET modu_rec_data.tran_type_ind = "COS" 
		LET modu_rec_data.ref_num = l_rec_prodledg.source_num 
		LET modu_rec_data.ref_text = l_rec_prodledg.source_text 

		# now get the COGS account (dr COGS, cr Stock)

		SELECT category.* INTO pr_category.* 
		FROM category, product 
		WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND category.cat_code = product.cat_code 
		AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = l_rec_prodledg.part_code 

		CASE 
			WHEN (l_rec_prodledg.trantype_ind = "S") 
				LET pos_qty = l_rec_prodledg.tran_qty * -1 
				LET tran_ind = "INV" 
				LET modu_rec_data.base_debit_amt = pos_qty * l_rec_prodledg.cost_amt 
				LET modu_rec_data.base_credit_amt = 0 
				LET modu_rec_data.for_debit_amt = modu_rec_data.base_debit_amt 
				LET modu_rec_data.for_credit_amt = 0 

				# now over patch with segment entered INTO the invoice

				LET patch_over = " " 
				DECLARE i_curs CURSOR FOR 
				SELECT line_acct_code 
				INTO patch_over 
				FROM invoicedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_rec_prodledg.source_num 
				AND part_code = l_rec_prodledg.part_code 
				FOREACH i_curs 
					EXIT FOREACH 
				END FOREACH 

			WHEN (l_rec_prodledg.trantype_ind = "C") 
				LET tran_ind = "CRE" 
				LET modu_rec_data.base_credit_amt = 
				l_rec_prodledg.tran_qty * l_rec_prodledg.cost_amt 
				LET modu_rec_data.base_debit_amt = 0 
				LET modu_rec_data.for_credit_amt = modu_rec_data.base_credit_amt 
				LET modu_rec_data.for_debit_amt = 0 

				# now over patch with segment entered INTO the credit

				LET patch_over = " " 
				DECLARE c_curs CURSOR FOR 
				SELECT line_acct_code 
				INTO patch_over 
				FROM creditdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = l_rec_prodledg.source_num 
				AND part_code = l_rec_prodledg.part_code 
				FOREACH c_curs 
					EXIT FOREACH 
				END FOREACH 

		END CASE 

		# now build up the COS account code
		# get the balancing chart part FROM the product category

		SELECT * INTO l_rec_structure.* 
		FROM structure 
		WHERE structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND structure.type_ind = "C" 

		LET l_start_chart = l_rec_structure.start_num 
		LET l_end_chart = l_rec_structure.start_num + l_rec_structure.length_num - 1 
		LET modu_rec_data.acct_code = patch_over 
		LET modu_rec_data.acct_code[l_start_chart, l_end_chart] = 
		pr_category.cogs_acct_code[ l_start_chart, l_end_chart] 

		LET modu_rec_data.desc_text[1,30] = pos_qty USING "<<<<", 
		"*", 
		l_rec_prodledg.part_code clipped, 
		",", 
		tran_ind, 
		l_rec_prodledg.source_num USING "<<<<<<<<" 

		# OK now SET up put INTO the temp post table
		# AND THEN SET up the balancing entry FROM the category stock acct
		# with debits AND credits reversed

		INSERT INTO posttemp VALUES (modu_rec_data.*) 

		LET modu_rec_data.acct_code = pr_category.stock_acct_code 

		LET temp_amt = modu_rec_data.base_debit_amt 
		LET modu_rec_data.base_debit_amt = modu_rec_data.base_credit_amt 
		LET modu_rec_data.base_credit_amt = temp_amt 
		LET modu_rec_data.for_debit_amt = modu_rec_data.base_debit_amt 
		LET modu_rec_data.for_credit_amt = modu_rec_data.base_credit_amt 

		INSERT INTO posttemp VALUES (modu_rec_data.*) 

	END FOREACH 

	IF modu_rec_inparms.gl_del_flag = "N" THEN 
		LET modu_passed_desc = "Summary COS FROM INV ", modu_fisc_year USING "<<<<", 
		" ", modu_tempper USING "<<<<" 
		CALL summary() 
	END IF 

	# OK now we have the temp table SET up we CALL jourprint TO
	# do its good work
	LET bal_rec.tran_type_ind = "CO" 
	# SET up balancing entry as the GL suspense account
	# as everything should balance......
	SELECT * 
	INTO l_rec_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	LET bal_rec.acct_code = l_rec_glparms.susp_acct_code 
	LET bal_rec.desc_text = " Incorrect entry FROM IN " 
	# get COS journal description
	LET sel_text = " SELECT * FROM posttemp WHERE 1 =1 " 

	LET its_ok = jourprint(sel_text, 
	glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	bal_rec.*, 
	modu_tempper, 
	modu_fisc_year, 
	modu_rec_inparms.inv_journal_code, 
	"I", 
	l_rec_glparms.base_currency_code, 
	l_type) 

	# now delete all FROM the table

	DELETE FROM posttemp WHERE 1=1 

	# OK next stick in the adjustments AND the issues
	# Issues first

	DECLARE p2_curs CURSOR FOR 
	SELECT * 
	INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_tempper 
	AND trantype_ind in ("I", "A", "U", "J") 
	FOREACH p2_curs 
		CASE 
			WHEN l_rec_prodledg.trantype_ind = "A" 
				LET modu_rec_data.tran_type_ind = "ADJ" 
				LET tran_ind = "ADJ" 
			WHEN l_rec_prodledg.trantype_ind = "U" 
				LET modu_rec_data.tran_type_ind = "ADJ" 
				LET tran_ind = "ADJ" 
			WHEN l_rec_prodledg.trantype_ind = "I" 
				LET modu_rec_data.tran_type_ind = "ISS" 
				LET tran_ind = "ISS" 
			WHEN l_rec_prodledg.trantype_ind = "J" # jm issue 
				LET modu_rec_data.tran_type_ind = "JMI" 
				LET tran_ind = "JMI" 
		END CASE 
		LET modu_rec_data.base_credit_amt = l_rec_prodledg.tran_qty * 
		l_rec_prodledg.cost_amt 
		LET modu_rec_data.base_debit_amt = 0 
		LET modu_rec_data.for_credit_amt = modu_rec_data.base_credit_amt 
		LET modu_rec_data.for_debit_amt = 0 
		LET modu_rec_data.ref_num = l_rec_prodledg.source_num 
		LET modu_rec_data.ref_text = l_rec_prodledg.source_text 
		LET modu_rec_data.acct_code = l_rec_prodledg.acct_code 

		# IF the prodledg.part_code has its maximum length THEN their
		# will be a truncation of the data (by 2 characters).
		# However, the following IS left TO try AND get the maximum amount
		# of data - MP 4.10.91.

		LET modu_rec_data.desc_text[1,30] = l_rec_prodledg.tran_qty USING "<<<<", 
		"*", 
		l_rec_prodledg.part_code clipped, 
		",", 
		tran_ind, 
		l_rec_prodledg.source_num USING "<<<<<<<<" 

		# SET up put INTO the temp post table
		# AND THEN SET up the balancing entry FROM the category stock acct

		INSERT INTO posttemp VALUES (modu_rec_data.*) 

		SELECT * INTO pr_category.* 
		FROM category, product 
		WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND category.cat_code = product.cat_code 
		AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = l_rec_prodledg.part_code 
		LET modu_rec_data.acct_code = pr_category.stock_acct_code 

		LET temp_amt = modu_rec_data.base_debit_amt 
		LET modu_rec_data.base_debit_amt = modu_rec_data.base_credit_amt 
		LET modu_rec_data.base_credit_amt = temp_amt 
		LET modu_rec_data.for_debit_amt = modu_rec_data.base_debit_amt 
		LET modu_rec_data.for_credit_amt = modu_rec_data.base_credit_amt 

		INSERT INTO posttemp VALUES (modu_rec_data.*) 

	END FOREACH 

	IF modu_rec_inparms.gl_del_flag = "N" THEN 
		LET modu_passed_desc = "Sum ISS/ADJ FROM INV ", modu_fisc_year USING "<<<<", 
		" ", modu_tempper USING "<<<<" 
		CALL summary() 
	END IF 
	# OK now we have the temp table SET up we CALL jourprint TO
	# do its good work
	LET bal_rec.tran_type_ind = "CO" 
	# SET up balancing entry as the GL suspense account
	# as everything should balance......
	SELECT * 
	INTO l_rec_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	LET bal_rec.acct_code = l_rec_glparms.susp_acct_code 
	LET bal_rec.desc_text = " Incorrect entry FROM IN " 
	LET sel_text = " SELECT * FROM posttemp WHERE 1 =1 " 

	LET its_ok = jourprint(sel_text, 
	glob_rec_kandoouser.cmpy_code, 
	glob_rec_kandoouser.sign_on_code, 
	bal_rec.*, 
	modu_tempper, 
	modu_fisc_year, 
	modu_rec_inparms.inv_journal_code, 
	"I", 
	l_rec_glparms.base_currency_code, 
	l_type) 

	# now delete all FROM the table
	DELETE FROM posttemp 

END FUNCTION 
############################################################
# END FUNCTION inventory() 
############################################################

############################################################
# FUNCTION summary() 
# Purpose - Get the SUM, add back in as ref_num = -1 AND ref_text = zzzcczzzc
# THEN delete out the original
############################################################
FUNCTION summary() 

	DECLARE ps_curs CURSOR FOR 
	SELECT posttemp.acct_code, 
	posttemp.tran_type_ind, 
	SUM(posttemp.base_debit_amt - posttemp.base_credit_amt), 
	SUM(posttemp.for_debit_amt - posttemp.for_credit_amt) 
	INTO modu_rec_data.acct_code, 
	modu_rec_data.tran_type_ind, 
	modu_rec_data.base_debit_amt, 
	modu_rec_data.for_debit_amt 
	FROM posttemp 
	GROUP BY posttemp.acct_code,posttemp.tran_type_ind 

	FOREACH ps_curs 
		LET modu_rec_data.ref_num = -1 
		LET modu_rec_data.ref_text = "zzzcczzc" 
		LET modu_rec_data.desc_text = modu_passed_desc 
		LET modu_rec_data.base_credit_amt = 0 
		LET modu_rec_data.for_credit_amt = 0 
		IF modu_rec_data.base_debit_amt < 0 THEN 
			LET modu_rec_data.base_credit_amt = 0 - modu_rec_data.base_debit_amt 
			LET modu_rec_data.base_debit_amt = 0 
		END IF 
		IF modu_rec_data.for_debit_amt < 0 THEN 
			LET modu_rec_data.for_credit_amt = 0 - modu_rec_data.for_debit_amt 
			LET modu_rec_data.for_debit_amt = 0 
		END IF 
		INSERT INTO posttemp VALUES (modu_rec_data.*) 
	END FOREACH 

	# now delete off detail
	DELETE FROM posttemp WHERE ref_num != -1 AND ref_text != "zzzcczzc" 

	# now UPDATE ref_num AND ref_text on those summary left
	UPDATE posttemp SET ref_num = 0,	ref_text = "Summary" 

END FUNCTION 
############################################################
# END FUNCTION summary() 
############################################################
