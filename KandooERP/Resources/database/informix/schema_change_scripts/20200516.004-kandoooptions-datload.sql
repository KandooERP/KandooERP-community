--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-05-16
--# Ticket # : KD-1903
--# dependencies:
--# more comments:

DELETE FROM kandoooption where cmpy_code='KA' AND module_code='AP' AND feature_code='VI';
DELETE FROM kandoooption where cmpy_code='99' AND module_code='AP' AND feature_code='VI';
on exception -691 status=OKE;
INSERT INTO kandoooption values ('KA','AP','VI','Validate Vendor Invoice Code (Voucher)', 'Y'); 
INSERT INTO kandoooption values ('99','AP','VI','Validate Vendor Invoice Code (Voucher)', 'Y');