DROP FUNCTION `f_wms_get_locator_id`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_get_locator_id`(
     p_org_id        INT
    ,p_locator_code  VARCHAR(40)
) RETURNS int(11)
BEGIN
DECLARE v_locator_id  INT DEFAULT -1;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
  RETURN -1;
END;

SELECT INVENTORY_LOCATION_ID
INTO v_locator_id
FROM cks_wms_loc
WHERE ORGANIZATION_ID  = p_org_id
AND   SEGMENT1  = p_locator_code;

RETURN v_locator_id;

END
