-- created by Oraschemadoc Thu Apr 21 10:04:00 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE UNIQUE INDEX "SPACEWALK"."RHN_PKG_REQ_PID_CID_S_UQ" ON "SPACEWALK"."RHNPACKAGEREQUIRES" ("PACKAGE_ID", "CAPABILITY_ID", "SENSE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" 
 
/
