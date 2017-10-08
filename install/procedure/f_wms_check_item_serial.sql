DROP FUNCTION `f_wms_check_item_serial`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_check_item_serial`(
     p_org_id         INT
    ,p_item_id        INT
) RETURNS int(11)
BEGIN



DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_return_value  INT DEFAULT 0;  

SELECT COUNT(*)
INTO v_check_count
FROM cks_wms_item msib
WHERE msib.ORGANIZATION_ID  = p_org_id
AND   msib.INVENTORY_ITEM_ID  = p_item_id
AND   msib.SERIAL_NUMBER_CONTROL_CODE = 5;

IF v_check_count = 0 THEN
    SET v_return_value = -1;
END IF;

RETURN v_return_value;

END
