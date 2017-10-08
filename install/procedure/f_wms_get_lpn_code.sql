DROP FUNCTION `f_wms_get_lpn_code`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_get_lpn_code`(
     p_org_id         INT
    ,p_lpn_id         INT
    ) RETURNS varchar(30) CHARSET utf8
BEGIN


DECLARE v_check_count   INT DEFAULT 0;  
DECLARE v_lpn_code      VARCHAR(30);  

SELECT COUNT(*)
INTO v_check_count
FROM cks_wms_lpn lpn
WHERE lpn.ORGANIZATION_ID  = p_org_id
AND   lpn.LPN_ID  = p_lpn_id;

IF v_check_count = 0 THEN
	SET v_lpn_code = NULL;
ELSE 
	SELECT lpn.LICENSE_PLATE_NUMBER
	INTO v_lpn_code
	FROM cks_wms_lpn lpn
	WHERE lpn.ORGANIZATION_ID  = p_org_id
	AND   lpn.LPN_ID  = p_lpn_id;    
END IF;

RETURN v_lpn_code;

END
