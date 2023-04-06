--# description: this script creates check constraints on cashreceipt
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cashreceipt
--# author: eric vercelletto
--# date: 2020-10-01
--# Ticket # : KD-2383
--# more comments: check the violations with the following query
--unload to /tmp/20201001-cashreceipt_1-createckconstraint.violations
--select *
--from cashreceipt
--where not (cash_amt > 0  and applied_amt >= 0 and disc_amt >= 0 );
--unload to /tmp/20201001-cashreceipt_2-createckconstraint.violations
--select *
--from cashreceipt
--where not (entry_date >=  "01/01/1900" and cash_date  >=  "01/01/1900" )
--unload to /tmp/20201001-cashreceipt_3-createckconstraint.violations
--select *
--from cashreceipt
--where not (year_num > 0 and period_num between 1 and 365 )
alter table cashreceipt add constraint check (cash_amt > 0  and applied_amt >= 0 and disc_amt >= 0 ) constraint ck_cashreceipt_amt_gt_0;
alter table cashreceipt add constraint check (entry_date >=  "01/01/1900" and cash_date  >=  "01/01/1900" ) constraint ck_cashreceipt_dates_gt_1900;
alter table cashreceipt add constraint check (year_num > 0 and period_num between 1 and 365 ) constraint ck_cashreceipt_periods;
