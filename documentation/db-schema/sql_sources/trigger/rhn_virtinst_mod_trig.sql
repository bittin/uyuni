-- created by Oraschemadoc Thu Apr 21 10:04:19 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE OR REPLACE TRIGGER "SPACEWALK"."RHN_VIRTINST_MOD_TRIG" 
before insert or update on rhnVirtualInstance
for each row
begin
        :new.modified := sysdate;
end;
ALTER TRIGGER "SPACEWALK"."RHN_VIRTINST_MOD_TRIG" ENABLE
 
/
