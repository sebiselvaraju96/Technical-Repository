   
--Staing stage 

CREATE TABLE XXCM_ITEM_LOAD_STAGE_DR1
(
   ITEM                        VARCHAR2 (100),
   ITEM_TEMPLATE               VARCHAR2 (100),
   ITEM_STATUS                 VARCHAR2 (100),
   USER_ITEM_TYPE              VARCHAR2 (100),
   ORG_ATTRIBUTE               VARCHAR2 (100),
   LOT_CONTROL                 VARCHAR2 (100),
   PREFIX                      VARCHAR2 (100),
   STARTING_NUMBER             NUMBER,
   CHILD_LOT_ENABLE            VARCHAR2 (100),
   CHILD_GENERATION            VARCHAR2 (100),
   LOT_SPLIT_ENABLED           VARCHAR2 (100),
   LOT_DIVISIBLE               VARCHAR2 (100),
   INVENTORY_PLANNING_METHOD   VARCHAR2 (100),
   MIN_QUANTITY                NUMBER,
   MAX_QUANTITY                NUMBER,
   SOURCE_TYPE                 VARCHAR2 (100),
   ITEM_CATEGORY               VARCHAR2 (100)
)


  ALTER TABLE XXCM_ITEM_LOAD_STAGE_DR1 ADD (DR1_VALIDATE_FLAG               VARCHAR2 (1),
   DR1_VALIDATED_DATE              DATE,
   DR1_REMARKS                     VARCHAR2 (100))
   


--Import Items into temp table

SELECT * FROM XXCM_ITEM_LOAD_STAGE_DR1


--Item NOT  Exists IN MASTER ORG


SELECT   ITEM
  FROM   XXCM_ITEM_LOAD_STAGE_DR1
 WHERE   ITEM NOT IN (SELECT   SEGMENT1
                        FROM   APPS.MTL_SYSTEM_ITEMS_B
                       WHERE   ORGANIZATION_ID = 366                     --DR1
                                                    )



UPDATE   XXCM_ITEM_LOAD_STAGE_DR1
   SET   DR1_VALIDATE_FLAG = 'E',
         DR1_VALIDATED_DATE = SYSDATE,
         DR1_REMARKS = DR1_REMARKS || '__Item_not_exists_in_Master_org_DR1'
 WHERE   ITEM NOT IN (SELECT   SEGMENT1
                        FROM   APPS.MTL_SYSTEM_ITEMS_B
                       WHERE   ORGANIZATION_ID = 366)                    --DRI

--Item ..Already Exists 


SELECT   ITEM
  FROM   XXCM_ITEM_LOAD_STAGE_DR1
 WHERE   ITEM IN (SELECT   SEGMENT1
                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                   WHERE   ORGANIZATION_ID = 367                         --DR1
                                                )



UPDATE   XXCM_ITEM_LOAD_STAGE_DR1
   SET   DR1_VALIDATE_FLAG = 'E',
         DR1_VALIDATED_DATE = SYSDATE,
         DR1_REMARKS = DR1_REMARKS || '__Item_already_Loaded'
 WHERE   ITEM IN (SELECT   SEGMENT1
                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                   WHERE   ORGANIZATION_ID = 367                         --DRI
                                                )
                
--Item Template Validation

SELECT   *
  FROM   XXCM_ITEM_LOAD_STAGE_DR1
 WHERE   ITEM_TEMPLATE NOT IN
               (SELECT   TEMPLATE_NAME FROM MTL_ITEM_TEMPLATES_TL)
            


UPDATE   XXCM_ITEM_LOAD_STAGE_DR1
   SET   DR1_VALIDATE_FLAG = 'E',
         DR1_VALIDATED_DATE = SYSDATE,
         DR1_REMARKS = DR1_REMARKS || '__Invalid Template'
 WHERE   ITEM_TEMPLATE NOT IN
               (SELECT   TEMPLATE_NAME FROM MTL_ITEM_TEMPLATES_TL)         
  
---Valid Records

UPDATE XXCM_ITEM_LOAD_STAGE_DR1 SET DR1_VALIDATE_FLAG='Y'
WHERE NVL(DR1_VALIDATE_FLAG,' ') <>'E'


--------Load Item into Interface Table

--create table xxcm_mtl_system_items_interface_2903 as
--SELECT * FROM mtl_system_items_interface
--where organization_id = 366

--delete FROM mtl_system_items_interface
--where organization_id = 366



DECLARE
   H_CNT   NUMBER := 0;

   CURSOR C1
   IS
      SELECT   A.ITEM,
               (SELECT   X.DESCRIPTION
                  FROM   APPS.MTL_SYSTEM_ITEMS_B X
                 WHERE   X.SEGMENT1 = A.ITEM AND X.ORGANIZATION_ID = 366)
                  DESCRIPTION,
               (SELECT   X.PRIMARY_UNIT_OF_MEASURE
                  FROM   APPS.MTL_SYSTEM_ITEMS_B X
                 WHERE   X.SEGMENT1 = A.ITEM AND X.ORGANIZATION_ID = 366)
                  PRIMARY_UNIT_OF_MEASURE,
               B.TEMPLATE_NAME,
               367 ORGANIZATION_ID,                                     --DR1,
               DECODE (A.LOT_CONTROL,
                       'No Control',
                       1,
                       'Full Control',
                       2)
                  LOT_CONTROL_CODE,
               PREFIX AUTO_LOT_ALPHA_PREFIX,
               STARTING_NUMBER START_AUTO_LOT_NUMBER,
               DECODE (CHILD_LOT_ENABLE, 'Enable', 'Y', 'N') CHILD_LOT_FLAG,
               DECODE (CHILD_GENERATION,
                       'Parent+Child',
                       'C',
                       'Parent',
                       'L')
                  PARENT_CHILD_GENERATION_FLAG,
               DECODE (LOT_SPLIT_ENABLED, 'Enable', 'Y', 'N')
                  LOT_SPLIT_ENABLED,
               DECODE (LOT_DIVISIBLE, 'Enable', 'Y', 'N') LOT_DIVISIBLE_FLAG,
               DECODE (INVENTORY_PLANNING_METHOD,
                       'Not Planned',
                       6,
                       'Min-Max',
                       2,
                       'Reorder Point',
                       1,
                       'Vendor Managed',
                       7)
                  INVENTORY_PLANNING_CODE,
               MIN_QUANTITY MIN_MINMAX_QUANTITY,
               MAX_QUANTITY MAX_MINMAX_QUANTITY,
               DECODE (SOURCE_TYPE,
                       'Inventory',
                       1,
                       'Supplier',
                       2,
                       'Subinventory',
                       3)
                  SOURCE_TYPE,
               0 CHILD_LOT_STARTING_NUMBER
        FROM   XXCM_ITEM_LOAD_STAGE_DR1 A, MTL_ITEM_TEMPLATES_TL B
       WHERE       A.DR1_VALIDATE_FLAG = 'Y'
               --AND ITEM = 'CH00400100000124'
               AND A.ITEM_TEMPLATE = B.TEMPLATE_NAME
               AND A.ITEM NOT IN (SELECT   SEGMENT1
                                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                                   WHERE   ORGANIZATION_ID = 367)        --DR1
               AND A.ITEM IN (SELECT   SEGMENT1
                                FROM   APPS.MTL_SYSTEM_ITEMS_B
                               WHERE   ORGANIZATION_ID = 366             --DRI
                                                            );
BEGIN
   FOR I IN C1
   LOOP
      H_CNT := H_CNT + 1;

      BEGIN
         INSERT INTO APPS.MTL_SYSTEM_ITEMS_INTERFACE (
                                                         PROCESS_FLAG,
                                                         SET_PROCESS_ID,
                                                         TRANSACTION_TYPE,
                                                         ORGANIZATION_ID,
                                                         SEGMENT1,
                                                         DESCRIPTION,
                                                         PRIMARY_UNIT_OF_MEASURE,
                                                         TEMPLATE_NAME,
                                                         LOT_CONTROL_CODE,
                                                         AUTO_LOT_ALPHA_PREFIX,
                                                         START_AUTO_LOT_NUMBER,
                                                         CHILD_LOT_FLAG,
                                                         PARENT_CHILD_GENERATION_FLAG,
                                                         LOT_SPLIT_ENABLED,
                                                         LOT_DIVISIBLE_FLAG,
                                                         INVENTORY_PLANNING_CODE,
                                                         MIN_MINMAX_QUANTITY,
                                                         MAX_MINMAX_QUANTITY,
                                                         SOURCE_TYPE,
                                                         CHILD_LOT_STARTING_NUMBER
                    )
           VALUES   (1,
                     1,
                     'CREATE',
                     I.ORGANIZATION_ID,
                     I.ITEM,
                     I.DESCRIPTION,
                     I.PRIMARY_UNIT_OF_MEASURE,
                     I.TEMPLATE_NAME,
                     I.LOT_CONTROL_CODE,
                     I.AUTO_LOT_ALPHA_PREFIX,
                     I.START_AUTO_LOT_NUMBER,
                     I.CHILD_LOT_FLAG,
                     I.PARENT_CHILD_GENERATION_FLAG,
                     I.LOT_SPLIT_ENABLED,
                     I.LOT_DIVISIBLE_FLAG,
                     I.INVENTORY_PLANNING_CODE,
                     I.MIN_MINMAX_QUANTITY,
                     I.MAX_MINMAX_QUANTITY,
                     I.SOURCE_TYPE,
                     I.CHILD_LOT_STARTING_NUMBER);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE ('Error ' || SQLERRM);
            ROLLBACK;
            RETURN;
      END;

      COMMIT;

      DBMS_OUTPUT.PUT_LINE (' Count : ' || H_CNT);
   END LOOP;
END;


--Interface data Checking

SELECT *
 FROM MTL_SYSTEM_ITEMS_INTERFACE
WHERE ORGANIZATION_ID = 367
AND PROCESS_FLAG = 3 AND SET_PROCESS_ID =1



SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,
COUNT(*) FROM APPS.MTL_ITEM_CATEGORIES_INTERFACE
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG


SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,COUNT(*)
FROM APPS.MTL_ITEM_REVISIONS_INTERFACE
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG



SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,COUNT(*)
FROM APPS.MTL_SYSTEM_ITEMS_INTERFACE
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG
ORDER BY 1


---Run Item Import 
   --I/P  367, 2, 1, 1, 1, 1, 1, 1

-- INTERFACE ERROR CHECKING 

select * from MTL_INTERFACE_ERRORS 
where transaction_id in (select transaction_id from  apps.mtl_item_categories_interface)

select * from MTL_INTERFACE_ERRORS 
where transaction_id in (select transaction_id from  apps.mtl_item_revisions_interface)

select * from MTL_INTERFACE_ERRORS 
where transaction_id in (select transaction_id from   mtl_system_items_interface where organization_id = 367 and set_process_id = 1)
and request_id = 84717256
