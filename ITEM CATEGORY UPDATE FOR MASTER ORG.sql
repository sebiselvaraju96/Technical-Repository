
--------ITEM CATEGORY UPDATE FOR DRI ORG------------

--1 Validate Categories

SELECT   *
  FROM   XXCM_ITEM_LOAD_STAGE_DRI
 WHERE   ITEM_CATEGORY NOT IN
               (SELECT      SEGMENT1
                         || '.'
                         || SEGMENT2
                         || '.'
                         || SEGMENT3
                         || '.'
                         || SEGMENT4
                  FROM   MTL_CATEGORIES)


--2.Verify the data 

sELECT   B.INVENTORY_ITEM_ID,
         (SELECT   X.CATEGORY_SET_ID
            FROM   APPS.MTL_CATEGORY_SETS X
           WHERE   X.CATEGORY_SET_NAME = 'Inventory')
            CATEGORY_SET_ID,
         B.SEGMENT1,
         C.CATEGORY_ID,
         F.CATEGORY_ID OLD_CATEGORY_ID,
            F.SEGMENT1
         || '.'
         || F.SEGMENT2
         || '.'
         || F.SEGMENT3
         || '.'
         || F.SEGMENT4
            OLD_CATEGORY,
         A.ITEM_CATEGORY NEW_ITEM_CATEGORY,
         C.CATEGORY_ID NEW_CATEGORY_ID
  FROM   XXCM_ITEM_LOAD_STAGE_DRI A,
         APPS.MTL_SYSTEM_ITEMS_B B,
         MTL_CATEGORIES C,
         MTL_ITEM_CATEGORIES D,
         MTL_CATEGORIES F
 WHERE   1 = 1 AND NVL (A.VALIDATE_FLAG, ' ') = 'Y'
         AND A.ITEM_CATEGORY IN
                  (SELECT      X.SEGMENT1
                            || '.'
                            || X.SEGMENT2
                            || '.'
                            || X.SEGMENT3
                            || '.'
                            || X.SEGMENT4
                     FROM   MTL_CATEGORIES X)
         AND A.ITEM = B.SEGMENT1
         AND B.ORGANIZATION_ID = 366
         AND A.ITEM_CATEGORY =
                  C.SEGMENT1
               || '.'
               || C.SEGMENT2
               || '.'
               || C.SEGMENT3
               || '.'
               || C.SEGMENT4
         AND B.INVENTORY_ITEM_ID = D.INVENTORY_ITEM_ID
         AND B.ORGANIZATION_ID = D.ORGANIZATION_ID
         AND D.CATEGORY_ID = F.CATEGORY_ID
         AND   F.SEGMENT1
            || '.'
            || F.SEGMENT2
            || '.'
            || F.SEGMENT3
            || '.'
            || F.SEGMENT4 = 'Default.Default.Default.Default'

--3.Load into Category Interface

INSERT INTO APPS.MTL_ITEM_CATEGORIES_INTERFACE (INVENTORY_ITEM_ID,
                                                CATEGORY_SET_ID,
                                                CATEGORY_ID,
                                                PROCESS_FLAG,
                                                ORGANIZATION_ID,
                                                SET_PROCESS_ID,
                                                TRANSACTION_TYPE,
                                                OLD_CATEGORY_ID)
   SELECT   B.INVENTORY_ITEM_ID,
            (SELECT   X.CATEGORY_SET_ID
               FROM   APPS.MTL_CATEGORY_SETS X
              WHERE   X.CATEGORY_SET_NAME = 'Inventory')
               CATEGORY_SET_ID,
            C.CATEGORY_ID NEW_CATEGORY_ID,
            1 PROCESS_FLAG,
            B.ORGANIZATION_ID,
            3 SET_PROCESS_ID,
            'UPDATE' TRANSACTION_TYPE,
            F.CATEGORY_ID OLD_CATEGORY_ID
     FROM   XXCM_ITEM_LOAD_STAGE_DRI A,
            APPS.MTL_SYSTEM_ITEMS_B B,
            MTL_CATEGORIES C,
            MTL_ITEM_CATEGORIES D,
            MTL_CATEGORIES F
    WHERE   1 = 1 AND NVL (A.VALIDATE_FLAG, ' ') = 'Y'
            --AND ITEM = 'TS01800100029644'
            AND A.ITEM_CATEGORY IN
                     (SELECT      X.SEGMENT1
                               || '.'
                               || X.SEGMENT2
                               || '.'
                               || X.SEGMENT3
                               || '.'
                               || X.SEGMENT4
                        FROM   MTL_CATEGORIES X)
            AND A.ITEM = B.SEGMENT1
            AND B.ORGANIZATION_ID = 367
            AND A.ITEM_CATEGORY =
                     C.SEGMENT1
                  || '.'
                  || C.SEGMENT2
                  || '.'
                  || C.SEGMENT3
                  || '.'
                  || C.SEGMENT4
            AND B.INVENTORY_ITEM_ID = D.INVENTORY_ITEM_ID
            AND B.ORGANIZATION_ID = D.ORGANIZATION_ID
            AND D.CATEGORY_ID = F.CATEGORY_ID
            AND   F.SEGMENT1
               || '.'
               || F.SEGMENT2
               || '.'
               || F.SEGMENT3
               || '.'
               || F.SEGMENT4 = 'Default.Default.Default.Default'
    


--3.Run Item Category Assignment Open Interface Concurrent for a DRI Org
   --I/P  3,Y,Y
   

--4.Check the Interface Error

select * from APPS.MTL_ITEM_CATEGORIES_INTERFACE 