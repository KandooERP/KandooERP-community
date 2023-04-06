--# description: this script creates 1 new column to the company table
--# dependencies: 
--# tables list: company
--# author: ericv
--# date: 2020-11-20
--# Ticket # : KD-2466
--# 
ALTER TABLE company ADD (legal_creation_date DATE);
update company set legal_creation_date = "01/01/2015" where cmpy_code = "99";
update company set legal_creation_date = "01/04/2016" where cmpy_code = "DE";