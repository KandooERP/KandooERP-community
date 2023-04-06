--# description: this script modifies all encountered address fields to  nvarchar(60)
--# dependencies: 
--# tables list: carrier company credheadaddr customer customeraudit customership invoicehead jmj_impresttran labourer location mmdr mtopvmst ordquotext poscacust postinvhead postranhead reqperson salesperson tentinvhead vendor vendoraudit vouchpayee warehouse
--# author: Eric Vercelletto
--# date: 2019-08-21
--# Ticket # :
--# more comments:
alter table labourer modify addr1_text nvarchar(60);
alter table mmdr modify addr1_text nvarchar(60);
alter table jmj_impresttran modify addr1_text nvarchar(60);
alter table customeraudit modify addr1_text nvarchar(60);
alter table postranhead modify addr1_text nvarchar(60);
alter table tentinvhead modify addr1_text nvarchar(60);
alter table postinvhead modify addr1_text nvarchar(60);
alter table poscacust modify addr1_text nvarchar(60);
alter table credheadaddr modify addr1_text nvarchar(60);
alter table ordquotext modify addr1_text nvarchar(60);
alter table mtopvmst modify addr1_text nvarchar(60);
alter table vendoraudit modify addr1_text nvarchar(60);
alter table vouchpayee modify addr1_text nvarchar(60);
alter table reqperson modify addr1_text nvarchar(60);
alter table carrier modify addr1_text nvarchar(60);
alter table salesperson modify addr1_text nvarchar(60);
alter table customer modify addr1_text nvarchar(60);
alter table invoicehead modify addr1_text nvarchar(60);
alter table company modify addr1_text nvarchar(60);
alter table vendor modify addr1_text nvarchar(60);
alter table warehouse modify addr1_text nvarchar(60);
alter table location modify addr1_text nvarchar(60);
alter table customeraudit modify addr2_text nvarchar(60);
alter table labourer modify addr2_text nvarchar(60);
alter table poscacust modify addr2_text nvarchar(60);
alter table tentinvhead modify addr2_text nvarchar(60);
alter table postinvhead modify addr2_text nvarchar(60);
alter table jmj_impresttran modify addr2_text nvarchar(60);
alter table postranhead modify addr2_text nvarchar(60);
alter table mmdr modify addr2_text nvarchar(60);
alter table ordquotext modify addr2_text nvarchar(60);
alter table credheadaddr modify addr2_text nvarchar(60);
alter table mtopvmst modify addr2_text nvarchar(60);
alter table vouchpayee modify addr2_text nvarchar(60);
alter table reqperson modify addr2_text nvarchar(60);
alter table vendoraudit modify addr2_text nvarchar(60);
alter table company modify addr2_text nvarchar(60);
alter table invoicehead modify addr2_text nvarchar(60);
alter table carrier modify addr2_text nvarchar(60);
alter table customer modify addr2_text nvarchar(60);
alter table customership modify addr2_text nvarchar(60);
alter table salesperson modify addr2_text nvarchar(60);
alter table vendor modify addr2_text nvarchar(60);
alter table warehouse modify addr2_text nvarchar(60);
alter table location modify addr2_text nvarchar(60);
alter table mtopvmst modify addr3_text nvarchar(60);
alter table reqperson modify addr3_text nvarchar(60);
alter table vendoraudit modify addr3_text nvarchar(60);
alter table vouchpayee modify addr3_text nvarchar(60);
alter table vendor modify addr3_text nvarchar(60);
