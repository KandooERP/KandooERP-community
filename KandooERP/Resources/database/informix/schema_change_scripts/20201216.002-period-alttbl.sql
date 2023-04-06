--# description: this script adds the financial_yearname column in period 'means the name of the financial year, like 2020-2021 
--# dependencies: 
--# tables list: period 
--# author: eric
--# date: 2020-12-16
--# Ticket # : 
--# 

alter table period add legal_yearname NCHAR(10);