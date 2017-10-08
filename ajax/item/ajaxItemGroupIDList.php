<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['item_group1'])
   && isSet($_POST['item_group2'])
   && isSet($_POST['item_group3'])
	)
{	
	$org_id = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group1 = mysqli_real_escape_string($db,$_POST['item_group1']); 
	$item_group2 = mysqli_real_escape_string($db,$_POST['item_group2']); 
	$item_group3 = mysqli_real_escape_string($db,$_POST['item_group3']); 
	
	$sql =  "SELECT ITEM_CATALOG_GROUP_ID AS item_group_id
				  ,CATALOG_DESCRIPTION    AS item_group_descr
			FROM cks_wms_micg
			WHERE SEGMENT1 = '$item_group1'
			AND   SEGMENT2 = '$item_group2'
			AND   SEGMENT3 = '$item_group3'
			AND   MASTER_ORGANIZATION_ID = $org_id
			" ;
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$itemgroupArray[] = array(
		  'item_group_id'     => $row['item_group_id'],
		  'item_group_descr'  => $row['item_group_descr']
		);
	}
	echo json_encode($itemgroupArray);

	//close the db connection
	mysqli_close($db);
}	
?>