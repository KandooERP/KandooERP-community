--# description: this script creates the table vendor with all necessary nchar columns
--# dependencies: n/a
--# tables list: vendor
--# author: eric vercelletto
--# date: 2019-04-16
--# Ticket # :
--# more comments:
drop table if exists vendor;
create table "informix".vendor 
  (
    cmpy_code char(2),
    vend_code nchar(8),
    name_text nvarchar(30),
    addr1_text nvarchar(40),
    addr2_text nvarchar(40),
    addr3_text nvarchar(40),
    city_text nvarchar(40),
    state_code nvarchar(6),
    post_code nvarchar(10),
    country_text nvarchar(40),
    country_code nchar(3),
    language_code nchar(3),
    type_code nchar(3),
    term_code nchar(3),
    tax_code nchar(3),
    setup_date date,
    last_mail_date date,
    tax_text nchar(10),
    our_acct_code nvarchar(21),
    contact_text nvarchar(20),
    tele_text char(20),
    extension_text char(7),
    acct_text nvarchar(20),
    limit_amt decimal(16,2),
    bal_amt decimal(16,2),
    highest_bal_amt decimal(16,2),
    curr_amt decimal(16,2),
    over1_amt decimal(16,2),
    over30_amt decimal(16,2),
    over60_amt decimal(16,2),
    over90_amt decimal(16,2),
    onorder_amt decimal(16,2),
    avg_day_paid_num smallint,
    last_debit_date date,
    last_po_date date,
    last_vouc_date date,
    last_payment_date date,
    next_seq_num integer,
    hold_code nchar(2),
    usual_acct_code nvarchar(18),
    ytd_amt decimal(16,2),
    min_ord_amt decimal(16,2),
    drop_flag char(1),
    finance_per nchar(1),
    fax_text nvarchar(20),
    currency_code nchar(3),
    bank_acct_code nvarchar(20),
    bank_code nvarchar(9),
    pay_meth_ind nchar(1),
    bkdetls_mod_flag char(1),
    purchtype_code nchar(3),
    po_var_per float,
    po_var_amt decimal(16,2),
    def_exp_ind nchar(1),
    backorder_flag char(1),
    contra_cust_code nvarchar(8),
    contra_meth_ind nchar(1),
    abn_text nvarchar(11),
    tax_incl_flag char(1)
  );

create unique index vendor_key on vendor(vend_code,cmpy_code);
alter table vendor add constraint primary key (vend_code,cmpy_code) constraint pky_vendor;
