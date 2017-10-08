<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['item_group1'])
   && isSet($_POST['item_group2'])
   && isSet($_POST['item_group3']))
{	
	$org_id = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group1 = mysqli_real_escape_string($db,$_POST['item_group1']); 
	$item_group2 = mysqli_real_escape_string($db,$_POST['item_group2']); 
	$item_group3 = mysqli_real_escape_string($db,$_POST['item_group3']); 
	
	$sql =  "SELECT msib.INVENTORY_ITEM_ID AS item_id
				  ,msib.SEGMENT1           AS item_code
				  ,msib.ITEM_DESCRIPTION   AS item_descr
				  ,msib.ITEM_SPEC          AS item_spec
			FROM cks_wms_micg micg
				,cks_wms_item msib
			WHERE micg.SEGMENT1 = '$item_group1'
			AND   micg.SEGMENT2 = '$item_group2'
			AND   micg.SEGMENT3 = '$item_group3'
			AND   msib.ORGANIZATION_ID = $org_id
			AND   msib.ITEM_CATALOG_GROUP_ID = micg.ITEM_CATALOG_GROUP_ID
			" ;
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$itemArray[] = array(
		  'item_id'     => $row['item_id'],
		  'item_code'   => $row['item_code'],
		  'item_descr'  => $row['item_descr'],
		  'item_spec'   => $row['item_spec']
		);
	}
	echo json_encode($itemArray);

	//close the db connection
	mysqli_close($db);
}	
?>