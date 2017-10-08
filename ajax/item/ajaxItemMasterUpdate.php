<?php

include("../db.php");

if(isSet($_POST['item_id']))
{	
	$item_id     = mysqli_real_escape_string($db,$_POST['item_id']); 
	$plan_doc_no = mysqli_real_escape_string($db,$_POST['plan_doc_no']); 
	$item_image  = mysqli_real_escape_string($db,$_POST['item_image']); 
	
	$sql =  "UPDATE cks_wms_master msi
	            SET ITEM_IMAGE = '$item_image' 
				   ,PLAN_DOCUMENT_NO  = '$plan_doc_no' 
			WHERE msi.INVENTORY_ITEM_ID = $item_id
			" ;
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	//close the db connection
	mysqli_close($db);
}	
?>