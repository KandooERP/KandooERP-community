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
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS "../common/glob_GLOBALS_constant.4gl"
--GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl" 	# ericv: removed this dependency for glob_GLOBALS because no variable here requires any defined in userdatatypes
														# prefer adding this glob whenever really required to avoid SPOF
 
GLOBALS 
	DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* #user/operator 
	DEFINE glob_rec_company RECORD LIKE company.* #user company
	DEFINE glob_rec_glparms RECORD LIKE glparms.* 
	DEFINE glob_rec_prog RECORD #Record to keep any kind of program related properties
		module_id VARCHAR(5),
		prog_id VARCHAR(5) #Note: kandooERP.exe does not count as a parent ! parent module id is used i.e. for background report generation
	END RECORD 
	DEFINE glob_rec_settings RECORD #any app settings i.e. default REPORT ouput path
		dataPath STRING, #env general default root path for any file read/write operations (root of sub-folders for different other jobs 
		reportPath STRING, # env variable reportdir 
		logPath STRING, #Path for any Log File
		logFile STRING, #Path for the MAIN KANDOO LOG file path and filename get_settings_logFile() and set_settings_logFile()
		saveUnbalancedBatch BOOLEAN, 
		maxListArraySize SMALLINT,  #User can not view more list items (array rows) than maxListArraySize regardless of the query even "where 1=1" will not show more...
		maxListArraySizeSwitch SMALLINT, #If the total possible result count is smaller than maxListArraySizeSwitch, the list will be queried/viewed without forcing a construct
		maxComboListSize SMALLINT, 
		maxchildlaunch SMALLINT,
		hideDeletedCustomers BOOLEAN,
		default_country_code LIKE country.country_code,
		default_currency_code LIKE currency.currency_code,
		default_language LIKE language.language_code,
		default_state LIKE state.state_code,
		maxReportHistorySize BIGINT		 #DEFAULT 99999000
	END RECORD 
	#	DEFINE cmpy LIKE company.cmpy_code  #currently used in all programs - should access glob_rec_kandoouser.cmpy_code
	#DEFINE glob_language RECORD LIKE language.* #huho 13.04.2019 removed
	#DEFINE glob_callingprog CHAR(160)
	#DEFINE glob_callingprog_ext CHAR(3)
	#DEFINE glob_msg1_text LIKE kandoomsg.msg1_text #huho 13.04.2019 removed
	#DEFINE glob_msg2_text LIKE kandoomsg.msg1_text	 #huho 13.04.2019 removed
	#DEFINE msgresp LIKE language.yes_flag  #this joke needs TO go as soon we cleanup all files/functions #huho 13.04.2019 removed

	#DEFINE glob_rec_kandoouser.cmpy_code LIKE company.cmpy_code  #huho 02.04.2019 removed
	#DEFINE glob_rec_kandoouser.sign_on_code LIKE kandoouser.sign_on_code  #huho 02.04.2019 removed

	# Preset translation of yes and no as soon as we know the language of the user
	# having both values in the same record allows bilateral translation
	DEFINE g_rec_yes RECORD
		english_val CHAR(1),	# value in english (always Y )
		localized_val CHAR(1)	# value in local language ( set by set_local_yes_no() )
	END RECORD
	
	DEFINE g_rec_no RECORD
		english_val CHAR(1),	# value in english (always N )
		localized_val CHAR(1)	# value in local language ( set by set_local_yes_no() )
	END RECORD	

	#glob_customer RECORD LIKE customer.*,

	#huho I have no idea why we duplicate these in the project - they are basically keeping the same information which IS already available in glob_rec_kandoouser
	#I propose TO remove them AND adjust the 4gl code
	#DEFINE glob_admin_code LIKE kandoouser.sign_on_code
	#DEFINE GL_LANG LIKE language.language_code # also in kandoouser.language_code #SMALLINT # Language ID, should be selected before all
	#DEFINE GL_LOGIN_USER_ID LIKE kandoouser.sign_on_code #qxt_user.u_id
	#DEFINE GL_LOGIN_NAME	LIKE kandoouser.sign_on_code #qxt_user.u_login_name
	#DEFINE GL_LOGIN_PASSWORD LIKE kandoouser.password_text #qxt_user.u_password

	#report page constants were a prototype trial.. must be removed again
	--------------------------------------
	#Report constants *temp note: Original kandoo sources define paper size in different places mostly hard coded, partialy via DB - we use temporary these constants until we move everything to DB
--	CONSTANT rpt_width_a3_p SMALLINT = 132
--	CONSTANT rpt_width_a3_l SMALLINT = 188
--	CONSTANT rpt_width_a4_p SMALLINT = 80
--	CONSTANT rpt_width_a4_l SMALLINT = 132
--	CONSTANT rpt_width_a5_p SMALLINT = 40
--	CONSTANT rpt_width_a5_l SMALLINT = 66
--	CONSTANT rpt_width_a6_p SMALLINT = 20
--	CONSTANT rpt_width_a6_l SMALLINT = 33
--	CONSTANT rpt_width_LABEL1_p SMALLINT = 15
--	CONSTANT rpt_width_LABEL1_l SMALLINT = 30
--	CONSTANT rpt_width_LABEL2_p SMALLINT = 10
--	CONSTANT rpt_width_LABEL2_l SMALLINT = 20

	CONSTANT COA_MASK_CODE_FULL NCHAR(18) = "??????????????????"

	CONSTANT RPT_SHOW_RMS_DIALOG BOOLEAN = TRUE
	CONSTANT RPT_HIDE_RMS_DIALOG BOOLEAN = FALSE
	
	CONSTANT ASCII_FORM_FEED SMALLINT = 12
	CONSTANT ASCII_QUOTATION_MARK SMALLINT = 34	
	--------------------
	#Navigation direction
	CONSTANT DIR_FORWARD boolean = TRUE
	CONSTANT DIR_BACKWARD boolean = FALSE

	---------------------------------------------------
	# GL COA Group Codes
	# NOTE, these must exist and match entries in coa.group_codes (GZ7)
	CONSTANT COA_GROUP_CODE_BANK_BAAC NCHAR(4) = "BAAC"

	---------------------------------------------------
	#Transaction Type
	CONSTANT TRAN_TYPE_CREDIT_CR NCHAR(3) = "CR"
	CONSTANT TRAN_TYPE_INVOICE_IN NCHAR(3) = "IN"
	CONSTANT TRAN_TYPE_RECEIPT_CA NCHAR(3) = "CA"
	CONSTANT TRAN_TYPE_CONTRACT_CON NCHAR(3) = "CON"
	CONSTANT TRAN_TYPE_BATCH_BAT NCHAR(3) = "BAT"
	CONSTANT TRAN_TYPE_JOB_JOB NCHAR(3) = "JOB"
	CONSTANT TRAN_TYPE_CUSTOMER_CUS NCHAR(3) = "CUS"
	CONSTANT TRAN_TYPE_ORDER_ORD NCHAR(3) = "ORD"
	CONSTANT TRAN_TYPE_LOAD_LNO NCHAR(3) = "LNO"
	CONSTANT TRAN_TYPE_DELIVERY_DLV NCHAR(3) = "DLV"
	CONSTANT TRAN_TYPE_TRANSPORT_TRN NCHAR(3) = "TRN"


	---------------------------------------------------
	#Dynamic Attributes/Styles

	CONSTANT ATTRIBUTE_OK STRING = "attribute_GREEN"
	CONSTANT ATTRIBUTE_WARNING STRING = "attribute_MAGENTA"
	CONSTANT ATTRIBUTE_ERROR STRING = "attribute_RED"

	CONSTANT ATTRIBUTE_GREEN STRING = "attribute_GREEN"
	CONSTANT ATTRIBUTE_YELLOW STRING = "attribute_YELLOW"
	CONSTANT ATTRIBUTE_MAGENTA STRING = "attribute_MAGENTA"
	CONSTANT ATTRIBUTE_RED STRING = "attribute_RED"

	---------------------------------------------------
	#Deposit tentbankdetl Transaction Type tentbankdetl.tran_type_ind
	CONSTANT DEPOSIT_TENTBANK_TRAN_TYPE_0 CHAR(1) = "0" 
	CONSTANT DEPOSIT_TENTBANK_TRAN_TYPE_1 CHAR(1) = "1" 
	CONSTANT DEPOSIT_TENTBANK_TRAN_TYPE_2 CHAR(1) = "2" 

	---------------------------------------------------
	#Ledger Type #huho.. I would like to make these upper case ASAP
	#- the ibthead and ibtdetl 'status_ind' determine the status of the transfert. 
	#- Values are:
	#- ibthead
	#- R => Transfer cancelled
	#- C => completed
	#- P => partially completed
	#- U => Undelivered
	#- ibtdetl: not clear yet ....
	#- 0 => New
	#- 4 => Cancelled
	CONSTANT IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R CHAR(1) = "R"
	CONSTANT IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C CHAR(1) = "C"	
	CONSTANT IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P CHAR(1) = "P"	
	CONSTANT IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U CHAR(1) = "U"
	
	CONSTANT IBTDETL_STATUS_IND_NEW_0 CHAR(1) = "0"	
	CONSTANT IBTDETL_STATUS_IND_CANCELED_4 CHAR(1) = "4"	
	
	---------------------------------------------------
	#Ledger Type #huho.. I would like to make these upper case ASAP
	CONSTANT LEDGER_TYPE_GL NCHAR(2) = "gl"
	CONSTANT LEDGER_TYPE_AR NCHAR(2) = "ar"
	CONSTANT LEDGER_TYPE_AP NCHAR(2) = "ap"
	CONSTANT LEDGER_TYPE_IN NCHAR(2) = "in"
	CONSTANT LEDGER_TYPE_OE NCHAR(2) = "oe" #?
	CONSTANT LEDGER_TYPE_PU NCHAR(2) = "pu"
	CONSTANT LEDGER_TYPE_JM NCHAR(2) = "jm"

	---------------------------------------------------
	#ERP-Module Code
	CONSTANT ERP_MODULE_MA_H NCHAR(2) = "MA" #main pr_name = "main" 
	CONSTANT ERP_MODULE_AR_A NCHAR(2) = "AR"
	CONSTANT ERP_MODULE_DD_D NCHAR(2) = "DD"
	CONSTANT ERP_MODULE_EO_E NCHAR(2) = "EO"
	CONSTANT ERP_MODULE_FA_F NCHAR(2) = "FA"
	CONSTANT ERP_MODULE_GL_G NCHAR(2) = "GL"
	CONSTANT ERP_MODULE_IN_I NCHAR(2) = "IN"
	CONSTANT ERP_MODULE_JM_J NCHAR(2) = "JM"
	CONSTANT ERP_MODULE_SS_K NCHAR(2) = "SS"
	CONSTANT ERP_MODULE_LC_L NCHAR(2) = "LC"
	CONSTANT ERP_MODULE_MN_M NCHAR(2) = "MN"
	CONSTANT ERP_MODULE_RE_N NCHAR(2) = "RE"
	CONSTANT ERP_MODULE_AP_P NCHAR(2) = "AP"
	CONSTANT ERP_MODULE_QE_Q NCHAR(2) = "QE"
	CONSTANT ERP_MODULE_PU_R NCHAR(2) = "PU"
	CONSTANT ERP_MODULE_PO_S NCHAR(2) = "PO" #was POS
	CONSTANT ERP_MODULE_WO_W NCHAR(2) = "WO"

	---------------------------------------------------
	#Currency Exchange Buy or Sell Rate B/S
	CONSTANT CASH_EXCHANGE_BUY NCHAR(1) = "B"  
	CONSTANT CASH_EXCHANGE_SELL NCHAR(1) = "S"  

	---------------------------------------------------
	#Payment / Cash Type / cash_type_ind
	CONSTANT PAYMENT_TYPE_CASH_C NCHAR(1) = "C"
	CONSTANT PAYMENT_TYPE_CHEQUE_Q NCHAR(1) = "Q"
	CONSTANT PAYMENT_TYPE_CC_P NCHAR(1) = "P"
	CONSTANT PAYMENT_TYPE_ORDER_O NCHAR(1) = "O"
#https://www.sapexpert.co.uk/eight-methods-pay-vendor-sap/
#*Cash
#*Cheque
#Letter of credit
#Paper Payment order
#Manual electronic transfer
#File electronic transfer
#Direct Debit
#IDOC
	
	---------------------------------------------------
	#disbhead.dr_cr_ind / Disburse Credit,Debit or Both
	CONSTANT DISBURSE_CDB_CREDIT_1 NCHAR(1) = "1"
	CONSTANT DISBURSE_CDB_DEBIT_2 NCHAR(1) = "2"
	CONSTANT DISBURSE_CDB_BOTH_3 NCHAR(1) = "3"

	---------------------------------------------------
	#disbhead.type_ind / Disburse Closing Balance,Period Movement or Trans. Amount
	CONSTANT DISBURSE_TYPE_CLOSING_BALANCE_1 NCHAR(1) = "1"
	CONSTANT DISBURSE_TYPE_PERIOD_MOVEMENT_2 NCHAR(1) = "2"
	CONSTANT DISBURSE_TYPE_TRANS_AMOUNT_3 NCHAR(1) = "3"

	---------------------------------------------------
	#cashreceipt.posted_flag 
	CONSTANT CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y NCHAR(1) = "Y"
	CONSTANT CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N NCHAR(1) = "N"
	CONSTANT CASHRECEIPT_POST_FLAG_STATUS_ON_HOLD_H NCHAR(1) = "H"
	CONSTANT CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V NCHAR(1) = "V"
			
	---------------------------------------------------
	#Wizard Style Navigation
	CONSTANT NAV_BACKWARD SMALLINT = 0
	CONSTANT NAV_FORWARD SMALLINT = 1
	CONSTANT NAV_CANCEL SMALLINT = -1	
	CONSTANT NAV_DONE SMALLINT = 2		 
	---------------------------------------------------
	CONSTANT filter_on boolean = true 
	CONSTANT filter_off boolean = false 

	#CONSTANT SILENT_ON BOOLEAN = TRUE
	#CONSTANT SILENT_OFF BOOLEAN = FALSE

	CONSTANT filter_query_off SMALLINT = 0 
	CONSTANT filter_query_on SMALLINT = 1 
	CONSTANT filter_query_select SMALLINT = 2 
	CONSTANT filter_query_where SMALLINT = 3 

	CONSTANT filter_where_all STRING = " 1=1 " 
	CONSTANT ret_normal SMALLINT = 0 
	CONSTANT ret_cancel SMALLINT = -1 

	CONSTANT MODE_SELECT SMALLINT = 0
	CONSTANT MODE_INSERT SMALLINT = 1 
	CONSTANT MODE_UPDATE SMALLINT = 2 
	CONSTANT MODE_DELETE SMALLINT = 3 
	CONSTANT MODE_FIND SMALLINT = 4 #oooh Kandoo 

	#Classic modes are constants used in original kandoo code
	# Typical topic handled in the generator: we must distinguish FORM operations from SQL operations
	# ADD is a form operation: you CREATE a new record in an INPUT block
	# EDIT is a form operation, you modify an existing record in an input block
	# SUPPR same
	# INSERT is an sql operation ,it is done after ADD in the form
	# UPDATE is an sql operation ,it is done after EDIT in the form
	# DELETE is an sql operation ,it is done after VIEW
	CONSTANT MODE_CLASSIC_VIEW STRING = "VIEW"
	CONSTANT MODE_CLASSIC_ADD STRING = "ADD" #Synonym for INSERT
	CONSTANT MODE_CLASSIC_EDIT STRING = "EDIT" #should only be used if it's used for both, INSERT and UPDATE
	CONSTANT MODE_CLASSIC_REMOVE STRING = "REMOVE"
	CONSTANT MODE_CLASSIC_MODIFY STRING = "MODIFY"	
	CONSTANT MODE_CLASSIC_INSERT STRING = "INSERT" 
	CONSTANT MODE_CLASSIC_UPDATE STRING = "UPDATE" 
	CONSTANT MODE_CLASSIC_DELETE STRING = "DELETE" 
	CONSTANT MODE_CLASSIC_SELECT STRING = "SELECT"	
	CONSTANT MODE_CLASSIC_FIND STRING = "FIND" #oooh Kandoo 


	#Classic modes are constants used in original kandoo code
	CONSTANT MODE_CLASSIC1_VIEW STRING = "V"
	CONSTANT MODE_CLASSIC1_ADD STRING = "A"
	CONSTANT MODE_CLASSIC1_EDIT STRING = "E" #should not be used, use UPDATE !!!
	CONSTANT MODE_CLASSIC1_REMOVE STRING = "R"
	CONSTANT MODE_CLASSIC1_MODIFY STRING = "M"	
	CONSTANT MODE_CLASSIC1_INSERT STRING = "I" 
	CONSTANT MODE_CLASSIC1_UPDATE STRING = "U" 
	CONSTANT MODE_CLASSIC1_DELETE STRING = "D" 
	CONSTANT MODE_CLASSIC1_SELECT STRING = "S"	
	CONSTANT MODE_CLASSIC1_FIND STRING = "F" #oooh Kandoo 
	
	CONSTANT UI_OFF SMALLINT = 0 #without UI messages
	CONSTANT UI_ON SMALLINT = 1 #messages turned on
	CONSTANT UI_PK SMALLINT = 2  #message validation for Primary Key
	CONSTANT UI_FK SMALLINT = 3 #message validation for Foreign Key

	CONSTANT UI_CONFIRM_OFF BOOLEAN = FALSE 
	CONSTANT UI_CONFIRM_ON BOOLEAN = TRUE 
	
	# Type of account required -
	#  "1" = Can Be Normal Transaction
	#  "2" = Can Be Control Bank
	#  "3" = Can Be Control Other
	#  "4" = Is Control Bank
	CONSTANT COA_ACCOUNT_REQUIRED_can_be_normal_transaction SMALLINT = "1" 
	CONSTANT COA_ACCOUNT_REQUIRED_can_be_control_bank SMALLINT = "2" 
	CONSTANT COA_ACCOUNT_REQUIRED_can_be_control_other SMALLINT = "3" 
	CONSTANT COA_ACCOUNT_REQUIRED_is_control_bank SMALLINT = "4" 

	# COMBOList population order
	CONSTANT COMBO_FIRST_ARG_IS_VALUE SMALLINT = 0 
	CONSTANT COMBO_first_ARG_is_LABEL SMALLINT = 1 

	CONSTANT COMBO_SORT_by_VALUE SMALLINT = 0 
	CONSTANT COMBO_SORT_BY_LABEL SMALLINT = 1 

	#pSingle ARGument for COMBO_Lookup
	CONSTANT COMBO_VALUE_AND_LABEL SMALLINT = 0 
	CONSTANT COMBO_VALUE_is_LABEL SMALLINT = 1 

	CONSTANT COMBO_LABEL_IS_LABEL SMALLINT = 0 
	CONSTANT COMBO_LABEL_IS_VALUE_TAB_LABEL SMALLINT = 1 
	CONSTANT COMBO_LABEL_IS_LABEL_BRACE_VALUE SMALLINT = 2 
	CONSTANT COMBO_LABEL_IS_VALUE_DASH_LABEL SMALLINT = 3 

	CONSTANT COMBO_NULL_NOT SMALLINT = 0 
	CONSTANT COMBO_NULL_SPACE SMALLINT = 1 
	CONSTANT COMBO_NULL_NONE SMALLINT = 2 
	CONSTANT COMBO_NULL_NA SMALLINT = 3 
	CONSTANT COMBO_NULL_UD SMALLINT = 4
	CONSTANT COMBO_NULL_NOT_ON_HOLD SMALLINT = 5
	CONSTANT COMBO_NULL_NOT_USED SMALLINT = 6
	CONSTANT COMBO_NULL_ANY SMALLINT = 7
	 
	--------------------------------------------------
	#Eric V. Session and Error handling

	DEFINE session_info RECORD 
		sid INTEGER, # informix session id
		user_name char(32),	# username of the session
 		pid INTEGER, # app server process id 
		login_timestamp DATETIME year TO second ,	# timestamp at which the session started
		database_name CHAR(128)		# current database name
	END RECORD 

	DEFINE error_retry_nbr SMALLINT # number OF ERROR retries used in the FUNCTION sql_errors_handler 
	DEFINE continue_program_on_error BOOLEAN		# in errors handler functions, lets the possibility to continue program or not
	DEFINE custom_error_message STRING
	DEFINE g_default_isolation_mode CHAR(64)		# Default Kandoo isolation mode detect by function get_default_isolation_mode
END GLOBALS 
