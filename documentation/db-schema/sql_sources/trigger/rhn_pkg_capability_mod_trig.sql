-- created by Oraschemadoc Thu Apr 21 10:04:18 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE OR REPLACE TRIGGER "SPACEWALK"."RHN_PKG_CAPABILITY_MOD_TRIG" 
before insert or update on rhnPackageCapability
for each row
begin
        :new.modified := sysdate;
end;
ALTER TRIGGER "SPACEWALK"."RHN_PKG_CAPABILITY_MOD_TRIG" ENABLE
 
/
