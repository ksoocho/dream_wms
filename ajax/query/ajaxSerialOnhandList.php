<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['subinv_code'])	
   && isSet($_POST['item_code'])	
  )
{	
	$org_id        = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code   = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	$item_code     = mysqli_real_escape_string($db,$_POST['item_code']); 
	
	$sql =  "SELECT msn.INVENTORY_ITEM_ID     AS item_id
                   ,msib.SEGMENT1             AS item_code 
                   ,msib.ITEM_DESCRIPTION     AS item_descr
                   ,msib.ITEM_SPEC            AS item_spec
                   ,mil.INVENTORY_LOCATION_ID AS locator_id
                   ,mil.SEGMENT1              AS locator_code 
                   ,msn.SERIAL_NUMBER         AS serial_no 
				   ,msn.DESCRIPTIVE_TEXT      AS serial_descr
             FROM cks_wms_msn msn
                 ,cks_wms_item msib
                 ,cks_wms_loc mil
             WHERE msn.CURRENT_ORGANIZATION_ID = $org_id
             AND   msn.CURRENT_SUBINVENTORY_CODE = '$subinv_code'
			 AND   msn.CURRENT_STATUS = 3
             AND   msib.ORGANIZATION_ID = msn.`CURRENT_ORGANIZATION_ID`
             AND   msib.INVENTORY_ITEM_ID = msn.INVENTORY_ITEM_ID
			 AND   msib.SEGMENT1 = '$item_code'
             AND   mil.ORGANIZATION_ID = msn.CURRENT_ORGANIZATION_ID
             AND   mil.INVENTORY_LOCATION_ID = msn.CURRENT_LOCATOR_ID
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{

		$item_id      = $row['item_id'];
		$item_code    = $row['item_code'];
		$item_descr   = $row['item_descr'];
		$item_spec    = $row['item_spec'];
		$locator_id   = $row['locator_id'];
		$locator_code = $row['locator_code'];
		$serial_no    = $row['serial_no'];
		$serial_descr = $row['serial_descr'];

        $resultArray[] = array(
		  'item_id'      => $item_id,
		  'item_code'    => $item_code,
		  'item_descr'   => $item_descr.' ('.$item_spec.')',
		  'locator_id'   => $locator_id,
		  'locator_code' => $locator_code,
		  'serial_descr' => $serial_descr,
		  'serial_no'    => $serial_no
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>