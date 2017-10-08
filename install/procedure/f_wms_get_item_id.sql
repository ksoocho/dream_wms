DROP FUNCTION `f_wms_get_item_id`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_get_item_id`(
     p_org_id         INT
    ,p_item_code        VARCHAR(40)
) RETURNS int(11)
BEGIN


DECLARE v_item_id  INT DEFAULT -1;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
  RETURN -1;
END;

SELECT INVENTORY_ITEM_ID
INTO v_item_id
FROM cks_wms_item msib
WHERE msib.ORGANIZATION_ID  = p_org_id
AND   msib.SEGMENT1  = p_item_code;

RETURN v_item_id;

END
