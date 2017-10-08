DROP FUNCTION `f_wms_check_lpn`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_check_lpn`(
     p_org_id         INT
    ,p_lpn_id         INT
) RETURNS int(11)
BEGIN


DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_return_value  INT DEFAULT 0;  

SELECT COUNT(*)
INTO v_check_count
FROM cks_wms_lpn lpn
WHERE lpn.ORGANIZATION_ID  = p_org_id
AND   lpn.LPN_ID  = p_lpn_id
AND   lpn.LPN_CONTEXT IN ( 1, 5 );

IF v_check_count = 0 THEN
    SET v_return_value = -1;
END IF;

RETURN v_return_value;

END
