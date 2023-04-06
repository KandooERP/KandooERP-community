--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: Hubert Hoelzl
--# date: 2020-11-02
--# Ticket # : KD-2414
--# dependencies:
--# more comments:

on exception -691 status=OKE;
INSERT INTO kandoooption values ('99','AR','AC','AR - Apply Credit Automatically', 'N')
