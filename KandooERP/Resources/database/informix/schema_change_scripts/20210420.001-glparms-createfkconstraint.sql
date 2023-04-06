--# description: this script foreign keys on glparms to journal
--# dependencies: 
--# tables list:  glparms,journal
--# author: Eric Vercelletto
--# date: 2021-04-20
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table glparms add constraint foreign key (gj_code,cmpy_code) references journal (jour_code,cmpy_code)  constraint fk_glparms_journal_gj;
alter table glparms add constraint foreign key (rj_code,cmpy_code) references journal (jour_code,cmpy_code)  constraint fk_glparms_journal_rj;
alter table glparms add constraint foreign key (cb_code,cmpy_code) references journal (jour_code,cmpy_code)  constraint fk_glparms_journal_cb;
alter table glparms add constraint foreign key (acrl_code,cmpy_code) references journal (jour_code,cmpy_code)  constraint fk_glparms_journal_acrl;
alter table glparms add constraint foreign key (rev_acrl_code,cmpy_code) references journal (jour_code,cmpy_code)  constraint fk_glparms_journal_rev_acrl;