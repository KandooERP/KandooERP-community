--# description: this script load data into kandoooption
--# dependencies: 
--# tables list:  kandoooption
--# author: Hubert Hoelzl
--# date: 2020-03-05
--# Ticket: 
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
INSERT INTO kandoooption values("99", "AP", "DA", "Voucher Distribution", "N");
INSERT INTO kandoooption values("99", "AR", "AG", "Report Monthly Aging (Past)", "N" );
INSERT INTO kandoooption values("99", "AR", "CA", "Report Credit Aging (Past)", "N" );
INSERT INTO kandoooption values("99", "AR", "RO", "Report Sort Y=name,cust,date (N=cust,date)", "N");
