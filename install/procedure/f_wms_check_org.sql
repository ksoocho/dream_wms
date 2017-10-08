DROP FUNCTION `f_wms_check_org`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_check_org`(
    p_org_id         INT
) RETURNS int(11)
BEGIN

DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_return_value  INT DEFAULT 0;  

SELECT COUNT(*)
INTO v_check_count
FROM cks_wms_org
WHERE ORGANIZATION_ID  = p_org_id;

IF v_check_count = 0 THEN
    SET v_return_value = -1;
END IF;

RETURN v_return_value;

END
