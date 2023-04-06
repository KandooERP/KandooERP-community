--# description: this script creates the company cmpy_code = 99 Test
--# dependencies: n/a
--# tables list: company
--# author: ericv
--# date: 2020-04-11
--# Ticket # : 
--# 
DELETE from company where cmpy_code = "99";
LOAD from unl/20200411_company.unl INSERT INTO company;
