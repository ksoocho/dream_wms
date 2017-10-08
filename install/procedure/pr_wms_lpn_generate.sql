CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_lpn_generate`(
      IN p_org_id            INT
    , IN p_lpn_type          VARCHAR(1)
    , IN p_user_id           INT
    , OUT x_lpn_id           INT
	, OUT x_lpn_code         VARCHAR(30)
	, OUT x_returnCode       VARCHAR(5)
 	, OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_lpn_generate
-- Description    : LPN Generate
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_lpn_code    VARCHAR(30);
DECLARE v_lpn_id      INT;  
DECLARE v_lpn_seq     INT;
DECLARE v_date_str    VARCHAR(6);

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT;
DECLARE v_return_value INT; 

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
	GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	 @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	SELECT @full_error;

    SET x_returnCode = 'E';
    SET x_returnMsg =  CONCAT('Error-',v_process,'-',@full_error);
    
    ROLLBACK;
END;

-- Common Code check
SET v_returnCode = 'S';
SET v_returnMsg = 'Success!!';

IF ( p_org_id IS NULL ) 
    OR ( p_lpn_type IS NULL ) THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

END IF;

SET v_process = '1000';

-- Check - Organization
IF v_returnCode = 'S' THEN

    SELECT f_wms_check_org(
            p_org_id)
    INTO v_return_value; 

    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Organization'; 
    END IF;

END IF; 

START TRANSACTION; 

SET v_process = '2000';

IF v_returnCode = 'S' THEN

    -- YYMMDD
	SELECT DATE_FORMAT(sysdate(), '%y%m%d')
	INTO v_date_str;

    SELECT COUNT(*)
    INTO   v_check_count
    FROM   cks_wms_lpn_seq
    WHERE  ORGANIZATION_ID = p_org_id
    AND    LPN_DATE_CODE = v_date_str;

    IF  v_check_count = 0 THEN
		INSERT INTO cks_wms_lpn_seq
		( ORGANIZATION_ID
		  , LPN_DATE_CODE 
		  , LPN_SEQ_NO 
		) VALUES (
		  p_org_id
		  , v_date_str
		  , 1 );        
    ELSE    
		UPDATE cks_wms_lpn_seq
           SET LPN_SEQ_NO = LPN_SEQ_NO + 1 
		WHERE  ORGANIZATION_ID = p_org_id
		AND    LPN_DATE_CODE = v_date_str;    
    END IF;
    
    SELECT LPN_SEQ_NO
    INTO   v_lpn_seq
    FROM   cks_wms_lpn_seq
    WHERE  ORGANIZATION_ID = p_org_id
    AND    LPN_DATE_CODE = v_date_str;

	SET v_lpn_code = CONCAT(p_org_id, v_date_str, 10000+v_lpn_seq, p_lpn_type ); 

    INSERT INTO cks_wms_lpn( 
		 LICENSE_PLATE_NUMBER   
		,ORGANIZATION_ID    
		,LPN_CONTEXT 
        ,EX_LPN_TYPE
		,CREATION_DATE 
		,CREATED_BY    
		,LAST_UPDATE_DATE 
		,LAST_UPDATED_BY )
	VALUES
	  ( v_lpn_code
	   ,p_org_id
	   ,5 -- Defined but not used
       ,p_lpn_type
	   ,SYSDATE()
	   ,p_user_id
	   ,SYSDATE()
	   ,p_user_id
	  );
  
  SET v_lpn_id = LAST_INSERT_ID();

END IF;

IF v_returnCode = 'S' THEN
    SET x_lpn_id = v_lpn_id;
    SET x_lpn_code = v_lpn_code;
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
    COMMIT;
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END