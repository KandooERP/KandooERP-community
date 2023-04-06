GLOBALS "lib_db_globals.4gl"
#Module Variables
DEFINE existingNextnumberRowCount INT

#               generates a transaction number depending upon the
#               VALUES stored in arparms.nextinv_num
#
#   Accepts 3 Formal Parameters
#    1. cmpy
#    2. trans_type  TRAN_TYPE_INVOICE_IN Invoice,
#                   TRAN_TYPE_RECEIPT_CA Cashreceipt,
#                   TRAN_TYPE_CREDIT_CR Credit Note
#                   TRAN_TYPE_LOAD_LNO Loads
#                   TRAN_TYPE_DELIVERY_DLV Delivery Dockets
#                   TRAN_TYPE_TRANSPORT_TRN Manual Transport Transactions
#                   TRAN_TYPE_CUSTOMER_CUS Customer Codes
#                   TRAN_TYPE_ORDER_ORD Orders
#                   "SS"  Subscriptions
#                   TRAN_TYPE_BATCH_BAT Batches
#    3. acct_code - Used FOR segment prefixed transaction numbering
#    4. program   - "PROGRAM" Default next number FOR a particular
#                   trans_type
#                   "<program-name>" WHERE program_name IS the name
#                   of the program

#####################################################
# FUNCTION setupTransactionNextNumber()  
#####################################################
FUNCTION setupTransactionNextNumber()
	DEFINE i SMALLINT
	
	IF readExistingTransactionNextNumber() < 1 THEN  #load existing data, if NOT found add defaults
		#Initialise default VALUES
		LET gl_arrRec_nextNumber[1].cmpy_code = gl_setupRec_default_company.cmpy_code
		LET gl_arrRec_nextNumber[1].tran_type_ind = TRAN_TYPE_CREDIT_CR  
		LET gl_arrRec_nextNumber[1].flex_code = "NEXTNUMBER"
		LET gl_arrRec_nextNumber[1].next_num = 1000	
		LET gl_arrRec_nextNumber[1].alloc_ind = "N"

		LET gl_arrRec_nextNumber[2].cmpy_code = gl_setupRec_default_company.cmpy_code
		LET gl_arrRec_nextNumber[2].tran_type_ind = TRAN_TYPE_INVOICE_IN  
		LET gl_arrRec_nextNumber[2].flex_code = "NEXTNUMBER"
		LET gl_arrRec_nextNumber[2].next_num = 1000	
		LET gl_arrRec_nextNumber[2].alloc_ind = "N"

		LET gl_arrRec_nextNumber[3].cmpy_code = gl_setupRec_default_company.cmpy_code
		LET gl_arrRec_nextNumber[3].tran_type_ind = TRAN_TYPE_BATCH_BAT  
		LET gl_arrRec_nextNumber[3].flex_code = "NEXTNUMBER"
		LET gl_arrRec_nextNumber[3].next_num = 1	
		LET gl_arrRec_nextNumber[3].alloc_ind = "N"	

		LET gl_arrRec_nextNumber[4].cmpy_code = gl_setupRec_default_company.cmpy_code
		LET gl_arrRec_nextNumber[4].tran_type_ind = TRAN_TYPE_RECEIPT_CA  
		LET gl_arrRec_nextNumber[4].flex_code = "NEXTNUMBER"
		LET gl_arrRec_nextNumber[4].next_num = 1000	
		LET gl_arrRec_nextNumber[4].alloc_ind = "N"	

		LET gl_arrRec_nextNumber[5].cmpy_code = gl_setupRec_default_company.cmpy_code
		LET gl_arrRec_nextNumber[5].tran_type_ind = TRAN_TYPE_CUSTOMER_CUS  
		LET gl_arrRec_nextNumber[5].flex_code = "NEXTNUMBER"
		LET gl_arrRec_nextNumber[5].next_num = 1	
		LET gl_arrRec_nextNumber[5].alloc_ind = "N"	
		
			
	END IF

	OPEN WINDOW w_transactionNextNumber WITH FORM "per/setup/setup_transaction_nextnumber"

	INPUT ARRAY gl_arrRec_nextNumber WITHOUT DEFAULTS FROM sr_nextnumber.* ATTRIBUTE(UNBUFFERED)

	IF int_flag THEN
		LET int_flag = FALSE
	ELSE
		WHENEVER ERROR CONTINUE

		FOR i = 1 TO gl_arrRec_nextNumber.getLength()
		
			INSERT INTO nextnumber VALUES(gl_arrRec_nextNumber[i].*) 

			DISPLAY "nextnumber STATUS=", trim(STATUS)
		END FOR
		
		WHENEVER ERROR STOP
		
	END IF 

	CLOSE WINDOW w_transactionNextNumber

END FUNCTION	

{	
	FOR i = 1 TO gl_arrRec_nextNumber.length()
		IF gl_arrRec_nextNumber[i].cmpy_code = gl_setupRec_default_company.cmpy_code THEN
			CASE gl_arrRec_nextNumber[i].tran_type_ind
				WHEN TRAN_TYPE_INVOICE_IN
					LET rec_tran.in_tran_type_ind = TRAN_TYPE_INVOICE_IN
					LET rec_tran.in_next_num	= gl_arrRec_nextNumber[i].next_num				
				WHEN TRAN_TYPE_RECEIPT_CA
					LET rec_tran.ca_tran_type_ind = TRAN_TYPE_RECEIPT_CA
					LET rec_tran.ca_next_num	= gl_arrRec_nextNumber[i].next_num				

				WHEN TRAN_TYPE_CREDIT_CR
					LET rec_tran.in_tran_type_ind = TRAN_TYPE_CREDIT_CR
					LET rec_tran.ca_next_num	= gl_arrRec_nextNumber[i].next_num				

				WHEN TRAN_TYPE_LOAD_LNO
					LET rec_tran.in_tran_type_ind = TRAN_TYPE_LOAD_LNO

				WHEN TRAN_TYPE_TRANSPORT_TRN
					LET rec_tran.in_tran_type_ind = TRAN_TYPE_TRANSPORT_TRN

				WHEN TRAN_TYPE_CUSTOMER_CUS				
					LET rec_tran.in_tran_type_ind = TRAN_TYPE_CUSTOMER_CUS
				
		END IF
	END FOR
	}



		#	CALL comboList_transationNumbering("pr_numtype_ind",0,0,0,3)								

#####################################################
# FUNCTION readExistingTransactionNextNumber()  
#####################################################
FUNCTION readExistingTransactionNextNumber()
	DEFINE c_nextnumber CURSOR
	DEFINE sqlQuery VARCHAR(300)
	DEFINE existingTableData BOOLEAN
	DEFINE rec_nextNumber RECORD LIKE nextnumber.*
	DEFINE retError INT
	DEFINE tempMsg STRING
	DEFINE x SMALLINT
	LET existingNextnumberRowCount = getNextNumberCount()
	IF existingNextnumberRowCount > 0 THEN	#if nextnumber table with rows exists, read them

		#Cursor Query
		LET sqlQuery =	"SELECT * ",
										"FROM nextnumber ",
										"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

		CALL c_NextNumber.DECLARE(sqlQuery) #CURSOR FOR getNextNumber
		CALL c_NextNumber.SetResults(rec_nextNumber.*)  --define variable for result output

		WHENEVER ERROR CONTINUE
			LET retError = c_NextNumber.OPEN()
		WHENEVER ERROR STOP

		IF  retError <> 0 THEN
			MESSAGE "Error in Query - Could NOT OPEN CURSOR"
			RETURN -1 #LET ret_NextNumberCount = -1
		END IF
	
		IF gl_setupRec.silentMode = 0 THEN
			LET tempMsg = "Number of nextnumber entries:", trim(existingNextnumberRowCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
			CALL fgl_winmessage("Nextnumber row count", tempMsg,"info") 	
		END IF
		LET x = 1
		WHILE  (c_NextNumber.FetchNext()=0)
				#huho, please change it back TO .append()
			CALL gl_arrRec_nextNumber.INSERT(x,rec_nextNumber)
			LET x = x+1 
		END WHILE	
	
		IF gl_arrRec_nextNumber.getSize() = 0 THEN
			ERROR "No entries in table nextnumber found with the specified company id"
		END IF
	
	END IF
									
	RETURN existingNextnumberRowCount
END FUNCTION
	
########################################################################################
# FUNCTION getNextNumberCount()
#-------------------------------------------------------
# Returns the number of NextNumber entries for the current company
########################################################################################
FUNCTION getNextNumberCount()
	DEFINE ret_NextNumberCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_NextNumber CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM nextnumber ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_NextNumber.DECLARE(sqlQuery) #CURSOR FOR getNextNumber
	CALL c_NextNumber.SetResults(ret_NextNumberCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_NextNumber.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_NextNumberCount = -1
	ELSE
		CALL c_NextNumber.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of rows in transaction nextnumber table:", trim(ret_NextNumberCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("NextNumber Row Count", tempMsg,"info") 	
	END IF

	RETURN ret_NextNumberCount
END FUNCTION

{
########################################################################################
# FUNCTION getNextNumberCount()
#-------------------------------------------------------
# Returns the number of NextNumber entries for the current company
########################################################################################
FUNCTION comboList_transactionType(cb_field_name)  
  DEFINE cb_field_name      VARCHAR(25)   --form field name FOR the  combo list field
	DEFINE pTable, pField1, pField2, pWhere STRING
	DEFINE pVariable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	DEFINE pSort SMALLINT  --0=Sort on first 1=Sort on 2nd
	DEFINE pSingle SMALLINT	--0=variable AND label 1= variable = label
	DEFINE pHint SMALLINT  --0= only variable 1 = show both VALUES in label var left 2 = show both VALUES in label var right  
	DEFINE curs_combo CURSOR
	DEFINE p_sql_stmt STRING
	DEFINE l_comboRec RECORD 
			listValue VARCHAR(100),  --can NOT be STRING
			listLabel VARCHAR(100)  --can NOT be STRING
			END RECORD
	DEFINE ERR_CODE INT
	DEFINE i INT
	DEFINE lLabel STRING


	CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,l_comboRec.listValue)


	LET p_sql_stmt = "SELECT ",
										trim(pfield1), ", ",
										trim(pfield2), " ",


										"FROM ", trim(pTable), " ",
										trim(pWhere)										
	IF pSort = 0 THEN									
		LET p_sql_stmt = p_sql_stmt, " ORDER BY ", trim(pfield1), " ASC "
	ELSE
		LET p_sql_stmt = p_sql_stmt, " ORDER BY ", trim(pfield2), " ASC "	
	END IF
	

	#DISPLAY p_sql_stmt
	
	WHENEVER ERROR CONTINUE

	CALL curs_combo.DECLARE(p_sql_stmt,1)	RETURNING ERR_CODE
	CALL curs_combo.SetResults(l_comboRec.listValue, l_comboRec.listLabel)	RETURNING ERR_CODE
	CALL curs_combo.OPEN()	RETURNING ERR_CODE

	LET i = 1

	WHILE (curs_combo.FetchNext()=0)

		IF i = 1 THEN 
			IF STATUS <> 0 THEN
				CALL fgl_winmessage("Combo Lookup Error",curs_combo.getStatement(),"error")
			END IF
		END IF		
	

		IF pVariable = 0 THEN	--Variable IS first COLUMN/field

			IF pSingle = 1 THEN  --ListItem variable value = label 
				CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,l_comboRec.listValue)
			ELSE	--ListItem IS a pair of variable value AND label

				CASE pHint
					WHEN 0 
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,l_comboRec.listLabel)
					WHEN 1   -- Add both VALUES TO the label
						LET lLabel =  trim(l_comboRec.listValue), "\t", trim(l_comboRec.listLabel)				
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,lLabel)
					WHEN 2 -- Add var TO the right					
						LET lLabel =  trim(l_comboRec.listLabel), " (", trim(l_comboRec.listValue), ")"				
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,lLabel)
					WHEN 3 -- Add var TO the left					
						LET lLabel =  trim(l_comboRec.listValue), " - ", trim(l_comboRec.listLabel)				
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,lLabel)
				END CASE	
						
			END IF 
			
		ELSE	--Variable IS second COLUMN/field

			IF pSingle = 1 THEN  --ListItem variable value = label
				CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listLabel,l_comboRec.listLabel)
			ELSE

				CASE pHint
					WHEN 0 
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listValue,l_comboRec.listLabel)
					WHEN 1   -- Add both VALUES TO the label left
						LET lLabel =  trim(l_comboRec.listLabel), " - ", trim(l_comboRec.listValue)				
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listLabel,lLabel)	
					WHEN 2 -- Add var TO the right					
						LET lLabel =  trim(l_comboRec.listValue), " (", trim(l_comboRec.listLabel), ")"				
						CALL ui.ComboBox.ForName(cb_field_name).addItem(l_comboRec.listLabel,lLabel)	
				END CASE	


			END IF 
		
		
END FUNCTION		
}