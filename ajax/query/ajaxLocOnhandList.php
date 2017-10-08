<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['subinv_code'])	
   && isSet($_POST['locator_code'])	
  )
{	
	$org_id        = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code   = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	$locator_code    = mysqli_real_escape_string($db,$_POST['locator_code']); 
	
	$sql =  "SELECT moq.INVENTORY_ITEM_ID    AS item_id
				  ,msib.SEGMENT1             AS item_code 
				  ,msib.ITEM_DESCRIPTION     AS item_descr
				  ,msib.ITEM_SPEC            AS item_spec
				  ,(SELECT  micg.CATALOG_DESCRIPTION  
			        FROM cks_wms_micg micg
					WHERE micg.ITEM_CATALOG_GROUP_ID = msib.ITEM_CATALOG_GROUP_ID)   AS item_group_descr
				  ,moq.LPN_ID                AS lpn_id
                  ,(SELECT lpn.LICENSE_PLATE_NUMBER
                    FROM cks_wms_lpn lpn
                    WHERE lpn.ORGANIZATION_ID = moq.ORGANIZATION_ID
		            AND   lpn.LPN_ID = moq.LPN_ID )  AS lpn_code
				  ,moq.TRANSACTION_QUANTITY  AS onhand_qty
			FROM cks_wms_moq moq
				 ,cks_wms_item msib
                 ,cks_wms_loc mil
			WHERE moq.ORGANIZATION_ID = $org_id
			AND   moq.SUBINVENTORY_CODE = '$subinv_code'
			AND   msib.ORGANIZATION_ID = moq.ORGANIZATION_ID
			AND   msib.INVENTORY_ITEM_ID = moq.INVENTORY_ITEM_ID
            AND   mil.ORGANIZATION_ID = moq.ORGANIZATION_ID
            AND   mil.INVENTORY_LOCATION_ID = moq.LOCATOR_ID
			AND   mil.SEGMENT1 = '$locator_code'
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{

		$item_id          = $row['item_id'];
		$item_code        = $row['item_code'];
		$item_descr       = $row['item_descr'];
		$item_spec        = $row['item_spec'];
		$item_group_descr = $row['item_group_descr'];
		$lpn_id           = $row['lpn_id'];
		$lpn_code         = $row['lpn_code'];
		$onhand_qty       = $row['onhand_qty'];

        $resultArray[] = array(
		  'item_id'           => $item_id,
		  'item_code'         => $item_code,
		  'item_descr'        => $item_descr.' ('.$item_spec.')',
		  'item_group_descr'  => $item_group_descr,
		  'lpn_id'            => $lpn_id ,
		  'lpn_code'          => $lpn_code ,
		  'onhand_qty'        => $onhand_qty 
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>