CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_item_generate`(
      IN p_org_id            INT
	, IN p_item_group_id     INT  
 	, IN p_item_descr        VARCHAR(240)  
 	, IN p_item_spec         VARCHAR(240) 
    , IN p_item_type         VARCHAR(30)
    , IN p_serial_flag       VARCHAR(1)
    , IN p_user_id           INT
	, OUT x_item_id          INT  
	, OUT x_item_code        VARCHAR(40)  
	, OUT x_returnCode       VARCHAR(5)
 	, OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_serial_generate
-- Description    : Serial Generate
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_item_seq     INT;
DECLARE v_item_prefix  VARCHAR(4);
DECLARE v_item_code    VARCHAR(40);
DECLARE v_org_id       INT;
DECLARE v_item_id      INT;
DECLARE v_serial_control_code INT;

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT;

DECLARE done INT DEFAULT FALSE;

-- 커서 - Organization
DECLARE c_org CURSOR FOR 
	SELECT ORGANIZATION_ID
    FROM cks_wms_org mp
    WHERE MASTER_ORGANIZATION_ID = p_org_id;

-- 커서가 마지막에 도착할 때의 상태값
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

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
    OR ( p_item_group_id IS NULL ) 
    OR ( p_item_descr IS NULL ) 
    OR ( p_item_spec IS NULL ) THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

END IF;

-- Serial Control Code
IF  IFNULL(p_serial_flag,'N') = 'Y' THEN
   SET v_serial_control_code = 5;
ELSE 
   SET v_serial_control_code = 1;
END IF;  

-- Check Item Group 
IF v_returnCode = 'S' THEN

    SELECT COUNT(*)
    INTO v_check_count
    FROM cks_wms_org mp
    WHERE MASTER_ORGANIZATION_ID = p_org_id;

    IF v_check_count = 0 THEN
	   SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Master Organization'; 
    END IF;
    
END IF;
    
-- Check Item Group 
IF v_returnCode = 'S' THEN

   SELECT COUNT(*)
   INTO v_check_count
   FROM  cks_wms_micg
   WHERE ITEM_CATALOG_GROUP_ID = p_item_group_id;
 
   IF  v_check_count = 0 THEN
      SET v_returnCode = 'E';
      SET v_returnMsg = 'Invalid Item Catalog Group'; 
   END IF;

END IF;
-- Check Item Group 
IF v_returnCode = 'S' THEN

    START TRANSACTION;

     -- ---------------------------------
     -- Item Code 발번
     -- ---------------------------------

    SELECT CONCAT(SUBSTR(SEGMENT1,1,1)
         ,SUBSTR(SEGMENT2,1,1)
         ,SUBSTR(SEGMENT3,1,1)
         ,SUBSTR(SEGMENT4,1,1))
    INTO v_item_prefix
    FROM  cks_wms_micg
    WHERE ITEM_CATALOG_GROUP_ID = p_item_group_id;

    SELECT COUNT(*)
    INTO   v_check_count
    FROM   cks_wms_item_seq
    WHERE  ITEM_PREFIX = v_item_prefix;

    IF  v_check_count = 0 THEN
		INSERT INTO cks_wms_item_seq
		( ITEM_PREFIX  
		  , ITEM_SEQ_NO 
		) VALUES (
		  v_item_prefix
		  , 1 );        
    ELSE    
		UPDATE cks_wms_item_seq
           SET ITEM_SEQ_NO = ITEM_SEQ_NO + 1 
		 WHERE  ITEM_PREFIX = v_item_prefix;
    END IF;
    
    SELECT ITEM_SEQ_NO
    INTO   v_item_seq
    FROM   cks_wms_item_seq
    WHERE  ITEM_PREFIX = v_item_prefix;

    SET v_item_code = CONCAT(v_item_prefix, 10000+v_item_seq ); 

     -- ---------------------------------
     -- Master Item 생성
     -- ---------------------------------
    
    INSERT INTO cks_wms_master 
		( INVENTORY_ITEM_CODE
		, ITEM_DESCRIPTION
		, CREATION_DATE 
		, CREATED_BY 
		, LAST_UPDATE_DATE 
		, LAST_UPDATED_BY  )
    VALUES ( 
        v_item_code
        , p_item_descr
        , SYSDATE()
        , p_user_id
        , SYSDATE()
        , p_user_id);

     SET v_item_id = LAST_INSERT_ID();
     
     -- ---------------------------------
     -- Master ORG 기준으로 모든 조직 Assign
     -- ---------------------------------
     OPEN c_org;
	   
	 read_loop: LOOP
	   
		 FETCH c_org INTO v_org_id ;
		   
		 INSERT INTO cks_wms_item 
			 (ORGANIZATION_ID    
			,INVENTORY_ITEM_ID    
			,SEGMENT1        
			,ITEM_TYPE        
			,ITEM_DESCRIPTION          
			,ITEM_SPEC      
			,ITEM_CATALOG_GROUP_ID      
			,SERIAL_NUMBER_CONTROL_CODE 
			,PRIMARY_UOM_CODE 
			,ENABLED_FLAG   
			,CREATION_DATE     
			,CREATED_BY    
			,LAST_UPDATE_DATE    
			,LAST_UPDATED_BY  
			 )
		  VALUES (
			  v_org_id
			  ,v_item_id 
			  ,v_item_code
			  ,p_item_type
			  ,p_item_descr
			  ,p_item_spec
			  ,p_item_group_id
			  ,v_serial_control_code
			  ,v_uom_code
			  ,'Y'
			  , SYSDATE()
			  ,p_user_id
			  ,SYSDATE()
			  ,p_user_id);
			  
		  -- 커서가 마지막 로우면 Loop를 빠져나간다. 
		  IF done THEN
			  LEAVE read_loop;
		  END IF;
		   
	  END LOOP;
	   
	   CLOSE c_org;          

END IF;

END