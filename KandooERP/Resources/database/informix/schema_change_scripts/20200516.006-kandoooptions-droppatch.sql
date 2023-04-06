--# description: this script drops to patches
--# tables list: kandoooption
--# author: ericv
--# date: 2020-05-16
--# Ticket # : 
--# dependencies:
--# more comments: those two patches must not be applied, they are cancelled
DELETE from dbschema_fix WHERE fix_name IN ('20200520.001-kandoooptions-datload','20200520.002-kandoooptions-datload'); 