DROP FUNCTION `f_wms_check_locator`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_check_locator`(
     p_org_id            INT
    ,p_subinv_code       VARCHAR(10) 
    ,p_locator_id        INT
) RETURNS int(11)
BEGIN


DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_return_value  INT DEFAULT 0;  

SELECT COUNT(*)
INTO v_check_count
FROM cks_wms_loc loc
WHERE loc.INVENTORY_LOCATION_ID = p_locator_id
AND   loc.ORGANIZATION_ID  = p_org_id
AND   loc.SUBINVENTORY_CODE  = p_subinv_code;

IF v_check_count = 0 THEN
    SET v_return_value = -1;
END IF;

RETURN v_return_value;

END
