

---ITEM LOADING DRI MASTER ORG

--1.STAGING TABLE 


CREATE TABLE XXCM_ITEM_LOAD_STAGE_DRI
(
   ITEM             VARCHAR2 (100),
   ITEM_TEMPLATE    VARCHAR2 (100),
   USER_ITEM_TYPE   VARCHAR2 (100),
   ITEM_CATEGORY    VARCHAR2 (200)
)

ALTER TABLE   XXCM_ITEM_LOAD_STAGE_DRI ADD(
   VALIDATE_FLAG               VARCHAR2 (1),
   VALIDATED_DATE              DATE,
   REMARKS                     VARCHAR2 (100))
   
-- Duplicate Items checking
   
SELECT ITEM,COUNT(*) FROM XXCM_ITEM_LOAD_STAGE_DRI
GROUP BY ITEM
HAVING COUNT(*) > 1


--2.IMPORT ITEMS INTO TEMP TABLE

SELECT * FROM XXCM_ITEM_LOAD_STAGE_DRI


--3.ITEM ALREADY EXISTS 


SELECT   ITEM
  FROM   XXCM_ITEM_LOAD_STAGE_DRI
 WHERE   ITEM IN (SELECT   SEGMENT1
                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                   WHERE   ORGANIZATION_ID = 366                         --DRI
                                                )

--ITEM

--SR00300100032322
--SR00300100032316
--CH00100100000060
--CH00100100000094



UPDATE   XXCM_ITEM_LOAD_STAGE_DRI
   SET   VALIDATE_FLAG = 'E',
         VALIDATED_DATE = SYSDATE,
         REMARKS = REMARKS || '__Item_already_Loaded'
 WHERE   ITEM IN (SELECT   SEGMENT1
                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                   WHERE   ORGANIZATION_ID = 366                         --DRI
                                                )
                
--4.ITEM TEMPLATE VALIDATION


SELECT   *
  FROM   XXCM_ITEM_LOAD_STAGE_DRI
 WHERE   ITEM_TEMPLATE NOT IN
               (SELECT   TEMPLATE_NAME FROM MTL_ITEM_TEMPLATES_TL)
            


UPDATE   XXCM_ITEM_LOAD_STAGE_DRI
   SET   VALIDATE_FLAG = 'E',
         VALIDATED_DATE = SYSDATE,
         REMARKS = REMARKS || '__Invalid Template'
 WHERE   ITEM_TEMPLATE NOT IN
               (SELECT   TEMPLATE_NAME FROM MTL_ITEM_TEMPLATES_TL)           
            

---5.VALID RECORDS



UPDATE   XXCM_ITEM_LOAD_STAGE_DRI
   SET   VALIDATE_FLAG = 'Y'
 WHERE   NVL (VALIDATE_FLAG, ' ') <> 'E'

--------6.LOAD ITEM INTO INTERFACE TABLE

--INSERT INTO XXCM_MTL_SYSTEM_ITEMS_INTERFACE_2903 
--SELECT * FROM MTL_SYSTEM_ITEMS_INTERFACE
--WHERE ORGANIZATION_ID = 366

--DELETE FROM MTL_SYSTEM_ITEMS_INTERFACE
--WHERE ORGANIZATION_ID = 366



DECLARE
   H_CNT   NUMBER := 0;

   CURSOR C1
   IS
      SELECT   A.ITEM,
               (SELECT   X.DESCRIPTION
                  FROM   APPS.MTL_SYSTEM_ITEMS_B X
                 WHERE   X.SEGMENT1 = A.ITEM AND X.ORGANIZATION_ID = 96)
                  DESCRIPTION,
               (SELECT   X.PRIMARY_UNIT_OF_MEASURE
                  FROM   APPS.MTL_SYSTEM_ITEMS_B X
                 WHERE   X.SEGMENT1 = A.ITEM AND X.ORGANIZATION_ID = 96)
                  PRIMARY_UNIT_OF_MEASURE,
               B.TEMPLATE_NAME,
               366 ORGANIZATION_ID                                       --DRI
        FROM   XXCM_ITEM_LOAD_STAGE_DRI A, MTL_ITEM_TEMPLATES_TL B
       WHERE       A.VALIDATE_FLAG = 'Y'
               --AND ITEM = 'TS01800100029644'
               AND A.ITEM_TEMPLATE = B.TEMPLATE_NAME
               AND A.ITEM NOT IN (SELECT   SEGMENT1
                                    FROM   APPS.MTL_SYSTEM_ITEMS_B
                                   WHERE   ORGANIZATION_ID = 366         --DRI
                                                                )
               AND A.ITEM IN (SELECT   SEGMENT1
                                FROM   APPS.MTL_SYSTEM_ITEMS_B
                               WHERE   ORGANIZATION_ID = 96              --IMO
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
                                                         TEMPLATE_NAME
                    )
           VALUES   (1,
                     1,
                     'CREATE',
                     I.ORGANIZATION_ID,
                     I.ITEM,
                     I.DESCRIPTION,
                     I.PRIMARY_UNIT_OF_MEASURE,
                     I.TEMPLATE_NAME);
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


SELECT * FROM MTL_SYSTEM_ITEMS_INTERFACE
WHERE ORGANIZATION_ID = 366
AND PROCESS_FLAG = 1


--Data Checking

SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,
COUNT(*) FROM APPS.MTL_ITEM_CATEGORIES_INTERFACE WHERE ORGANIZATION_ID = 366
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG


SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,COUNT(*)
FROM APPS.MTL_ITEM_REVISIONS_INTERFACE WHERE  ORGANIZATION_ID = 366
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG



SELECT ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG,COUNT(*)
FROM APPS.MTL_SYSTEM_ITEMS_INTERFACE WHERE ORGANIZATION_ID = 366
GROUP BY ORGANIZATION_ID,TRANSACTION_TYPE,PROCESS_FLAG


---Run Item Import 
   --I/P  366, 2, 1, 1, 1, 1, 1, 1

--ERROR RECORDS

SELECT * FROM MTL_INTERFACE_ERRORS 
WHERE TRANSACTION_ID IN (SELECT TRANSACTION_ID FROM   MTL_SYSTEM_ITEMS_INTERFACE WHERE ORGANIZATION_ID = 366)
and   request_id = 


