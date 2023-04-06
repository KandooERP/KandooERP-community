--# description: this script add list of Business Modules to table_documentation
--# dependencies: 
--# tables list: table_documentation
--# author: ericv
--# date: 2020-05-07
--# Ticket # : 
--# 
ALTER TABLE table_documentation ADD (usage_bmlist CHAR(50) BEFORE language_code) ;

