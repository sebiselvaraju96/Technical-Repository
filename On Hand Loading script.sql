CREATE TABLE xx_on_hand_sample_data (
    inventory_item      VARCHAR2(100),
    transaction_uom     VARCHAR2(100),
    primary_qty         VARCHAR2(100),
    transaction_cost    VARCHAR2(100),
    subinventory_code   VARCHAR2(100),
    locator_name        VARCHAR2(100),
    account             VARCHAR2(100),
    lot_number          VARCHAR2(100),
    serial_number       VARCHAR2(100)
);

--==========================================================================

SET SERVEROUTPUT ON;

DECLARE
    CURSOR c1 IS
        SELECT DISTINCT
            a.*,
            b.segment1,
            b.organization_id,
            b.inventory_item_id,
            (
                SELECT
                    code_combination_id
                FROM
                    gl_code_combinations_kfv
                WHERE
                    padded_concatenated_segments = a.account
            ) account_code_id,
            (
                SELECT
                    inventory_location_id
                FROM
                    mtl_item_locations_kfv
                WHERE
                        concatenated_segments = a.locator_name
                    AND
                        subinventory_code = a.subinventory_code
                    AND
                        organization_id = 367
            ) new_wip_locator_id
        FROM
            xx_on_hand_sample_data a,
            apps.mtl_system_items_b b
        WHERE
                1 = 1
            AND
                a.inventory_item = b.segment1
            AND
                b.organization_id = 367
--AND a.INVENTORY_ITEM IN  ('FG00200100001105','FG00200100001114')
            AND
                b.serial_number_control_code = 1
            AND
                a.lot_number IS NOT NULL
            AND NOT
                EXISTS (
                    SELECT
                        1
                    FROM
                        apps.mtl_material_transactions x,
                        mtl_lot_numbers y
                    WHERE
                            x.inventory_item_id = b.inventory_item_id
                        AND
                            x.subinventory_code = a.subinventory_code
                        AND
                            x.inventory_item_id = y.inventory_item_id
                        AND
                            x.organization_id = y.organization_id
                        AND
                            y.lot_number = a.lot_number
                        AND
                            x.organization_id = 367
                )
        ORDER BY 1;

    CURSOR c2 (
        p_inventory_item_id   NUMBER,
        p_lot_number          VARCHAR2
    ) IS
        SELECT DISTINCT
            a.*,
            b.segment1,
            b.organization_id,
            b.inventory_item_id,
            NULL expiration_date
        FROM
            xx_on_hand_sample_data a,
            apps.mtl_system_items_b b
        WHERE
                1 = 1 
--AND a.organization_id = b.organization_id
--AND a.INVENTORY_ITEM IN ('FG00200100001105','FG00200100001114')--
            AND
                a.inventory_item = b.segment1
            AND
                a.lot_number = p_lot_number
            AND
                b.organization_id = 367
            AND
                b.inventory_item_id = p_inventory_item_id
            AND
                b.serial_number_control_code = 1
            AND
                a.lot_number IS NOT NULL
            AND NOT
                EXISTS (
                    SELECT
                        1
                    FROM
                        apps.mtl_material_transactions x,
                        mtl_lot_numbers y
                    WHERE
                            x.inventory_item_id = b.inventory_item_id
                        AND
                            x.subinventory_code = a.subinventory_code
                        AND
                            x.inventory_item_id = y.inventory_item_id
                        AND
                            x.organization_id = y.organization_id
                        AND
                            y.lot_number = a.lot_number
                        AND
                            x.organization_id = 367
                );

    v_primary_code   VARCHAR2(30);
    p_iface_trx_id   NUMBER;
BEGIN
    FOR i IN c1 LOOP
        BEGIN
            SELECT
                mtl_material_transactions_s.NEXTVAL
            INTO
                p_iface_trx_id
            FROM
                dual;

        EXCEPTION
            WHEN OTHERS THEN
                p_iface_trx_id := NULL;
        END;
          
            --p_iface_trx_id := p_iface_trx_id + 1;
--           
--           
--

        BEGIN
            dbms_output.put_line(i.segment1
             || '-'
             || i.lot_number
             || '-'
             || i.primary_qty
             || '-'
             || p_iface_trx_id);

            INSERT INTO apps.mtl_transactions_interface (
                created_by,
                creation_date,
                flow_schedule,
                inventory_item_id,
                last_updated_by,
                last_update_date,
                locator_id,
                organization_id,
                process_flag,
                source_code,
                source_header_id,
                source_line_id,
                subinventory_code,
                transaction_date,
                transaction_mode,
                transaction_quantity,
                transaction_type_id,
                transaction_source_id/*,revision*/,
                transaction_uom,
                distribution_account_id,
                transaction_cost,
                transaction_reference,
                transaction_interface_id,
                transaction_action_id,
                transaction_source_type_id
            ) VALUES (
                1131,
                SYSDATE,
                NULL,
                i.inventory_item_id,
                1131,
                SYSDATE,
                i.new_wip_locator_id,
                367,
                1,
                'TEST',
                1,
                1,
                i.subinventory_code,
                SYSDATE,
                3,
                i.primary_qty,
                42,
                NULL,/*i.revision*/
                (
                    SELECT DISTINCT
                        primary_uom_code
                    FROM
                        mtl_system_items_b
                    WHERE
                            1 = 1
                        AND
                            inventory_item_id = i.inventory_item_id
                )
                    --i.TRANSACTION_UOM
                ,
                i.account_code_id,
                i.transaction_cost,
                'TEST',
                p_iface_trx_id,
                27,
                13
            );

        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('apps.mtl_transactions_interface ' || sqlerrm);
                ROLLBACK;
        END;

        FOR j IN c2(
            i.inventory_item_id,
            i.lot_number
        ) LOOP
            BEGIN
                INSERT INTO mtl_transaction_lots_interface (
                    transaction_interface_id,
                    lot_number,
                    lot_expiration_date,
                    transaction_quantity,
                    last_update_date,
                    last_updated_by,
                    creation_date,
                    created_by
                ) VALUES (
                    p_iface_trx_id,--transaction interface id
                    i.lot_number,--Lot number
                    j.expiration_date,--Lot expiration date
                    i.primary_qty,--transaction quantity
                    SYSDATE,--last update date
                    1131,--last updated by
                    SYSDATE,--creation date
                    1131
                );

            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('apps.mtl_transactions_interface ' || sqlerrm);
                    ROLLBACK;
            END;
        END LOOP;
         
                --dbms_output.put_line(i.segment1 || '-' ||I.lot_number || '-' || I.PRIMARY_QTY);

        COMMIT;
    END LOOP;
END;
/