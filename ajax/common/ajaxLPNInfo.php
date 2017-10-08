<?php

include("../db.php");

if(isSet($_POST['lpn_no']))
{    
    $org_id   = mysqli_real_escape_string($db,$_POST['org_id']); 
    $lpn_no   = mysqli_real_escape_string($db,$_POST['lpn_no']); 

    $sql =  "SELECT LPN_ID            AS lpn_id
	               ,LPN_CONTEXT       AS lpn_context
				   ,SUBINVENTORY_CODE AS subinv_code
                   ,LOCATOR_ID        AS loc_id
                   ,PARENT_LPN_ID	  AS parent_lpn_id	
                   ,OUTERMOST_LPN_ID  AS outer_lpn_id
                   ,EX_LPN_TYPE		  AS lpn_type		   
            FROM  cks_wms_lpn
            WHERE LICENSE_PLATE_NUMBER = '$lpn_no'
			AND   ORGANIZATION_ID = $org_id
            " ;

    $result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

    while($row =mysqli_fetch_assoc($result))
    {
        $v_lpn_id         = $row['lpn_id'];
        $v_lpn_context    = $row['lpn_context'];
        $v_subinv_code    = $row['subinv_code'];
        $v_loc_id         = $row['loc_id'];
        $v_parent_lpn_id  = $row['parent_lpn_id'];
        $v_outer_lpn_id   = $row['outer_lpn_id'];
        $v_lpn_type       = $row['lpn_type'];
    }
    
    // Loc Code 
	if ($v_loc_id != null)
	{
		$sql2 =  "SELECT SEGMENT1 AS loc_code
				  FROM  cks_wms_loc
				  WHERE ORGANIZATION_ID   = $org_id
				  AND   SUBINVENTORY_CODE = '$v_subinv_code'
				  AND   INVENTORY_LOCATION_ID = $v_loc_id
				 " ;
				
		$result2 = mysqli_query($db, $sql2) or die("Error in Selecting " . mysqli_error($db));

		while($row =mysqli_fetch_assoc($result2))
		{
			$v_loc_code     = $row['loc_code'];
		}
	}	
    
    $resultInfo[] = array(
      'lpn_id'        => $v_lpn_id,
      'lpn_context'   => $v_lpn_context,
      'subinv_code'   => $v_subinv_code,
      'loc_code'      => $v_loc_code,
      'parent_lpn_id' => $v_parent_lpn_id,
      'outer_lpn_id'  => $v_outer_lpn_id,
      'lpn_type'      => $v_lpn_type 
    );

    echo json_encode($resultInfo);

    //close the db connection
    mysqli_close($db);
}    
?>