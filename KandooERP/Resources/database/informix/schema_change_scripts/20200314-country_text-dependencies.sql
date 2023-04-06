--# description: This script is the dependency for mobile-email alter 20200315.002-country_text-createfkconstraint.sql, 20200315.001-country_text-alttbl.sql and 20200315-customership-alttbl.sql
--# dependencies: 
--# tables list: many tables
--# author: alch
--# date: 2020-10-03
--# Ticket # : KD-****
--# This script must report OK to trigger the execution of the depending scripts
--# More comments: the script is created intentionally with one syntax error: this will prevent the consecutive depending scripts to execute, until the syntax error is fixed
CREATE TABLE IF NOT EXISTS kandoo_dependency (dep_date DATE);
INSERT INTO kandoo_dependency
VALUES (current);
DROP TABLE IF EXISTS kandoo_dependency;

