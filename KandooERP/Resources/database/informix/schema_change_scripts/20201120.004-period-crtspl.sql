--# description: this script creates a stored procedure to check periods
--# dependencies: 20201120.000-fiscalyear-dependency
--# tables list: company
--# author: ericv
--# date: 2020-11-20
--# Ticket # : KD-2466
--# 
CREATE PROCEDURE IF NOT EXISTS check_fiscal_year_integrity (p_cmpy_code NCHAR(2),p_start_date_fisc_year DATE)
RETURNING BOOLEAN;
	DEFINE p_start_date_fisc_year DATE;
	DEFINE first_year_num SMALLINT;
	DEFINE l_year_num,l_total_days SMALLINT;
	
-- identify the first year of all the company's fiscal years, which can be more or less than 365 days
	SELECT YEAR(legal_creation_date)
	INTO first_year_num
	FROM company
	WHERE cmpy_code =  p_cmpy_code;
	
	IF YEAR(p_start_date_fisc_year) >  first_year_num THEN
		SELECT year_num,sum(end_date-start_date+1) 
		INTO l_year_num,l_total_days
		FROM period 
		WHERE cmpy_code =  p_cmpy_code
		AND year_num = YEAR(p_start_date_fisc_year)
		GROUP BY year_num ;
		
		IF l_total_days < 365 OR l_total_days > 366 THEN
			RAISE EXCEPTION -746, 0, 'sum of all periods for this year <> 365 days' ;
		ELSE
			RETURN 't';     -- fits the number of days
		END IF

	END IF
	RETURN 't'; 	
END PROCEDURE