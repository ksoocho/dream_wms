<?php

include("../db.php");

if(isSet($_POST['org_id'])
  && isSet($_POST['item_group']))
{	
	$org_id  = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group  = mysqli_real_escape_string($db,$_POST['item_group']); 
	
	$sql =  "SELECT SEGMENT1   AS item_group1 
				   , SEGMENT2  AS item_group2
				   , SEGMENT3  AS item_group3
				   , SEGMENT4  AS item_group4
				   , CATALOG_DESCRIPTION  AS item_group_descr
			FROM cks_wms_micg 
			WHERE SEGMENT1 = '$item_group'
			AND   MASTER_ORGANIZATION_ID = $org_id
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{

		$item_group1        = $row['item_group1'];
		$item_group2        = $row['item_group2'];
		$item_group3        = $row['item_group3'];
		$item_group4        = $row['item_group4'];
		$item_group_descr   = $row['item_group_descr'];

        $resultArray[] = array(
		  'item_group1'         => $item_group1,
		  'item_group2'         => $item_group2,
		  'item_group3'         => $item_group3,
		  'item_group4'         => $item_group4,
		  'item_group_descr'    => $item_group_descr 
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>