----# description: this script changes the fields country_text to country_code (nchar(3) 
----# tables list: tentinvhead,mtopvmst,postranhead,postinvhead,quotehead,arparms,tentsubhead,customeraudit,company,invoicehead,vendor,customership,vendoraudit,vouchpayee,jmj_impresttran,subhead,orderhead,customer,purchhead
----# dependencies: 20200314-country_text-dependencies 
----# author: ericv
----# date: 2020-03-15
----# Ticket # : 	KD-1761
----# more comments:
create index d01_tentinvhead on tentinvhead(country_code);
alter table tentinvhead add constraint foreign key (country_code) references country constraint fk_tentinvhead_country;
create index d01_mtopvmst on mtopvmst(country_code);
alter table mtopvmst add constraint foreign key (country_code) references country constraint fk_mtopvmst_country;
create index d01_postranhead on postranhead(country_code);
alter table postranhead add constraint foreign key (country_code) references country constraint fk_postranhead_country;
create index d02_postinvhead on postinvhead(country_code);
alter table postinvhead add constraint foreign key (country_code) references country constraint fk_postinvhead_country;
create index d01_quotehead on quotehead(country_code);
alter table quotehead add constraint foreign key (country_code) references country constraint fk_quotehead_country;
create index d01_arparms on arparms(country_code);
alter table arparms add constraint foreign key (country_code) references country constraint fk_arparms_country;
create index d01_tentsubhead on tentsubhead(country_code);
alter table tentsubhead add constraint foreign key (country_code) references country constraint fk_tentsubhead_country;
create index d01_customeraudit on customeraudit(country_code);
alter table customeraudit add constraint foreign key (country_code) references country constraint fk_customeraudit_country;
create index d01_company on company(country_code);
alter table company add constraint foreign key (country_code) references country constraint fk_company_country;
create index d01_invoicehead on invoicehead(country_code);
alter table invoicehead add constraint foreign key (country_code) references country constraint fk_invoicehead_country;
create index d02_vendor on vendor(country_code);
alter table vendor add constraint foreign key (country_code) references country constraint fk_vendor_country;
create index d01_customership on customership(country_code);
alter table customership add constraint foreign key (country_code) references country constraint fk_customership_country;
create index d01_vendoraudit on vendoraudit(country_code);
alter table vendoraudit add constraint foreign key (country_code) references country constraint fk_vendoraudit_country;
create index d01_vouchpayee on vouchpayee(country_code);
alter table vouchpayee add constraint foreign key (country_code) references country constraint fk_vouchpayee_country;
create index d01_jmj_impresttran on jmj_impresttran(country_code);
alter table jmj_impresttran add constraint foreign key (country_code) references country constraint fk_jmj_impresttran_country;
create index d01_subhead on subhead(country_code);
alter table subhead add constraint foreign key (country_code) references country constraint fk_subhead_country;
create index d01_orderhead on orderhead(country_code);
alter table orderhead add constraint foreign key (country_code) references country constraint fk_orderhead_country;
alter table customer add constraint foreign key (country_code) references country constraint fk_customer_country;
create index d01_purchhead on purchhead(del_country_code);
alter table purchhead add constraint foreign key (del_country_code) references country(country_code) constraint fk_purchhead_country;
