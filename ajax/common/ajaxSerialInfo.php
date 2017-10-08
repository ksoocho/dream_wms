<?php

include("../db.php");

if(isSet($_POST['serial_no']))
{    
    $serial_no   = mysqli_real_escape_string($db,$_POST['serial_no']); 

    $sql =  "SELECT INVENTORY_ITEM_ID         AS item_id
	               ,CURRENT_ORGANIZATION_ID   AS org_id
				   ,CURRENT_SUBINVENTORY_CODE AS subinv_code
                   ,CURRENT_LOCATOR_ID        AS loc_id
                   ,CURRENT_STATUS		      AS serial_status		   
            FROM  cks_wms_msn
            WHERE SERIAL_NUMBER = '$serial_no'
            " ;

    $result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

    while($row =mysqli_fetch_assoc($result))
    {
        $v_item_id        = $row['item_id'];
        $v_org_id         = $row['org_id'];
        $v_subinv_code    = $row['subinv_code'];
        $v_loc_id         = $row['loc_id'];
        $v_serial_status  = $row['serial_status'];
    }
    
    // Item Code 
	if( $v_item_id != null)
	{
		$sql1 =  "SELECT SEGMENT1 AS item_code
				FROM  cks_wms_item
				WHERE ORGANIZATION_ID = $org_id
				AND   SEGMENT1        = '$item_code'
				AND   INVENTORY_ITEM_ID = $v_item_id
				" ;
		$result1 = mysqli_query($db, $sql1) or die("Error in Selecting " . mysqli_error($db));

		while($row =mysqli_fetch_assoc($result1))
		{
			$v_item_code     = $row['item_code'];
		}
	}

    // Loc Code 
	if( $v_loc_id != null)
	{
		$sql2 =  "SELECT SEGMENT1 AS loc_code
				  FROM  cks_wms_loc
				  WHERE ORGANIZATION_ID   = $v_org_id
				  AND   SUBINVENTORY_CODE = '$v_subinv_code'
				  AND   INVENTORY_LOCATION_ID = $v_loc_id;
				 " ;
				
		$result2 = mysqli_query($db, $sql2) or die("Error in Selecting " . mysqli_error($db));

		while($row =mysqli_fetch_assoc($result2))
		{
			$v_loc_code     = $row['loc_code'];
		}
	}	
    
    $resultInfo[] = array(
      'item_code'     => $v_item_code,
      'org_id'        => $v_org_id,
      'subinv_code'   => $v_subinv_code,
      'loc_code'      => $v_loc_code,
      'serial_status' => $v_serial_status
    );

    echo json_encode($resultInfo);

    //close the db connection
    mysqli_close($db);
}    
?>