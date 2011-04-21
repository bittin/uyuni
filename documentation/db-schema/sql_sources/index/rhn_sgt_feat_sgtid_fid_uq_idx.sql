-- created by Oraschemadoc Thu Apr 21 10:04:05 2011
-- visit http://www.yarpen.cz/oraschemadoc/ for more info

  CREATE UNIQUE INDEX "SPACEWALK"."RHN_SGT_FEAT_SGTID_FID_UQ_IDX" ON "SPACEWALK"."RHNSERVERGROUPTYPEFEATURE" ("SERVER_GROUP_TYPE_ID", "FEATURE_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" 
 
/
