DROP FUNCTION `f_wms_get_onhand_qty`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_get_onhand_qty`(
     p_org_id            INT
    ,p_subinv_code       VARCHAR(10) 
    ,p_locator_id        INT
    ,p_item_id           INT
) RETURNS int(11)
BEGIN


DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_onhand_qty    INT DEFAULT 0;  

SELECT SUM(PRIMARY_TRANSACTION_QUANTITY)
INTO v_onhand_qty
FROM cks_wms_moq moq
WHERE  moq.ORGANIZATION_ID   = p_org_id
AND  moq.INVENTORY_ITEM_ID = p_item_id
AND  moq.SUBINVENTORY_CODE = p_subinv_code
AND  moq.LOCATOR_ID        = p_locator_id ;

RETURN v_onhand_qty;

END
