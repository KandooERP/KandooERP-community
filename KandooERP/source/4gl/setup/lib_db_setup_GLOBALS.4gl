--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 

# SETUP SETUP  SETUP SETUP  SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP
# SETUP SETUP  SETUP SETUP  SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP
# SETUP SETUP  SETUP SETUP  SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP
# SETUP SETUP  SETUP SETUP  SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP
# SETUP SETUP  SETUP SETUP  SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP SETUP

GLOBALS 

DEFINE gl_setupRec 
	RECORD
		ui_mode SMALLINT,											--run operations in silent mode (NOT display TO..., no windows, AND if possible, no ui interactions
		fiscal_startDate DATE,
		fiscal_period_size SMALLINT,  --fiscal tax period 1=year 4=Quarter Yearly 12=Monthly  
		start_year_num LIKE coa.start_year_num,
		start_period_num LIKE coa.start_period_num,
		end_year_num  LIKE coa.end_year_num, 
		end_period_num  LIKE coa.end_period_num,
		industry_type STRING,										--Can be used TO allow for different lookup/list-data imports
		unl_file_extension STRING		--file extension for exporting/unloading AND loading/importing database table data 
	END RECORD	

	DEFINE gl_recStep DYNAMIC ARRAY OF RECORD
		title STRING,
		step_name STRING,
		step_done STRING,
		console STRING	
		END RECORD

	DEFINE gl_arrRec_nextNumber DYNAMIC ARRAY OF RECORD LIKE nextnumber.*





	DEFINE gl_setupRec_admin_rec_kandoouser RECORD LIKE kandoouser.*
	DEFINE glob_language RECORD LIKE language.*
	DEFINE glob_rec_setup_company RECORD LIKE company.*
	DEFINE gl_setupRec_kandooprofile RECORD LIKE kandooprofile.*  
	DEFINE gl_setupRec_bic RECORD LIKE bic.*
	
	DEFINE gl_setupRec_bank RECORD like bank.*
	DEFINE gl_apparms RECORD LIKE apparms.*   --AP - Account Payable Parameters
	DEFINE gl_arparms RECORD LIKE arparms.*   --AR - Account Receivable Parameters
	DEFINE gl_arparmext RECORD LIKE arparmext.* --AR Extension table (AR needs 2 tables)

	DEFINE continue_installation BOOLEAN
	DEFINE step_num INTEGER
	DEFINE mdNavigatePrevious BOOLEAN 
	DEFINE run_submodule_list STRING  --program names of subModuleInstallers
	
	DEFINE setupLookupDataRecord RECORD
		coa SMALLINT,				--table:COA Chart of Accounts
		journal SMALLINT,		--table:Journal
		uom SMALLINT,				--table:UOM = Units of Meassurements
		banktype SMALLINT,  --table:Banktype = Types of banks
		credreas SMALLINT,	--table:redreas = Reasons TO allow/give credit
		holdpay SMALLINT		--table:holdpay = Reasons TO hold back payment
	END RECORD
	
	DEFINE setupModuleRecord RECORD
		a,c,e,f,g,i,j,k,l,m,n,p,q,r,t,u,w BOOLEAN
	END RECORD

END GLOBALS