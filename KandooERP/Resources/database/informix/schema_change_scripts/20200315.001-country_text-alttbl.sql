--# description: this script changes the fields country_text to country_code (nchar(3) 
--# tables list: tentinvhead,mtopvmst,postranhead,postinvhead,quotehead,arparms,tentsubhead,customeraudit,company,invoicehead,vendor,customership,vendoraudit,vouchpayee,jmj_impresttran,subhead,orderhead,customer,purchhead
--# dependencies: 20200314-country_text-dependencies 
--# author: ericv
--# date: 2020-03-15
--# Ticket # : 	KD-1761
--# more comments:
alter table tentinvhead drop country_text;
alter table mtopvmst drop country_text;
rename column postranhead.country_text to country_code;
alter table postranhead modify country_code nchar(3);
alter table postinvhead drop country_text;
alter table quotehead drop country_text;
alter table arparms drop country_text;
alter table tentsubhead drop country_text;
alter table customeraudit drop country_text;
alter table company drop country_text;
alter table invoicehead drop country_text;
alter table vendor drop country_text;
alter table customership drop country_text;
alter table vendoraudit drop country_text;
rename column vouchpayee.country_text to country_code;
alter table vouchpayee modify country_code nchar(3);
alter table jmj_impresttran drop country_text;
alter table subhead drop country_text;
alter table orderhead drop country_text;
alter table customer drop country_text;
rename column purchhead.del_country_text to del_country_code;
alter table purchhead modify del_country_code nchar(3);
