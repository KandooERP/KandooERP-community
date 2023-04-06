
############################################################
#FUNCTION db_company_load()
#LOAD default company FROM UNL
############################################################
FUNCTION db_company_load()
DEFINE rCompany RECORD LIKE company.*
CREATE TEMP TABLE temp_company(
	cmpy_code            CHAR(2),
	name_text            CHAR(30),
	addr1_text           CHAR(30),
	addr2_text           CHAR(30),
	city_text            CHAR(30),
	state_code           CHAR(6),
	post_code            CHAR(10),
	country_text         CHAR(20),
	country_code         CHAR(3),
	language_code        CHAR(3),
	fax_text             CHAR(20),
	tax_text             CHAR(30),
	telex_text           CHAR(30),
	com1_text            CHAR(50),
	com2_text            CHAR(50),
	tele_text            CHAR(20),
	curr_code            CHAR(3),
	module_text          CHAR(26),
	vat_code             CHAR(11),
	vat_div_code         CHAR(3)
);
		WHENEVER ANY ERROR CONTINUE 
			LOAD FROM "unl/company.unl" INSERT INTO country
		WHENEVER ANY ERROR STOP
		CASE STATUS
			WHEN -805 --file NOT found
				ERROR "UNL file NOT found."
			WHEN 239 --duplicated value, company with ID already exists
				IF fgl_winquestion("Replace DB info", "Company with such ID already exist.\nReplace conflict company data?.", "No", "Yes|No", "exclamation", 1) = "Yes" THEN
					LOAD FROM "unl/company.unl" INSERT INTO temp_company
					DECLARE comp CURSOR FOR SELECT * FROM temp_company
					FOREACH comp INTO rCompany.*
						IF db_company_pk_exists(UI_OFF,rCompany.cmpy_code) THEN
						#IF exist_company(rCompany.cmpy_code) THEN
							DELETE FROM company WHERE cmpy_code = rCompany.cmpy_code
							INSERT INTO company VALUES (rCompany.*)
						END IF
					END FOREACH
 					CLOSE comp
		 		END IF
        END CASE
   DROP TABLE temp_company
END FUNCTION

