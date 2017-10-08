DROP FUNCTION `f_wms_get_lpn_id`//
CREATE DEFINER=`cksoonew`@`localhost` FUNCTION `f_wms_get_lpn_id`(
     p_org_id         INT
    ,p_lpn_code       VARCHAR(30) 
) RETURNS int(11)
BEGIN

DECLARE v_lpn_id        INT DEFAULT -1;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
  RETURN -1;
END;

SELECT LPN_ID
INTO v_lpn_id
FROM cks_wms_lpn lpn
WHERE lpn.ORGANIZATION_ID  = p_org_id
AND   lpn.LICENSE_PLATE_NUMBER  = p_lpn_code;    

RETURN v_lpn_id;

END
