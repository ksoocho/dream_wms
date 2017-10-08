<?php

include("../db.php");

if(isSet($_POST['lookup_type'])
  )
{	
	$lookup_type  = mysqli_real_escape_string($db,$_POST['lookup_type']); 
	
	$sql =  "SELECT LOOKUP_CODE       AS lookup_code
				  ,LOOKUP_MEANING     AS lookup_meaning
				  ,IFNULL(LOOKUP_DESCRIPTION,' ') AS lookup_descr
				  ,IFNULL(PARENT_LOOKUP_TYPE,' ') AS parent_lookup_type
				  ,IFNULL(PARENT_LOOKUP_CODE,' ') AS parent_lookup_code
			FROM cks_wms_lookup 
			WHERE `LOOKUP_TYPE` = '$lookup_type'
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{

		$lookup_code        = $row['lookup_code'];
		$lookup_meaning     = $row['lookup_meaning'];
		$lookup_descr       = $row['lookup_descr'];
		$parent_lookup_type = $row['parent_lookup_type'];
		$parent_lookup_code = $row['parent_lookup_code'];

        $resultArray[] = array(
		  'lookup_code'         => $lookup_code,
		  'lookup_meaning'      => $lookup_meaning,
		  'lookup_descr'        => $lookup_descr,
		  'parent_lookup_type'  => $parent_lookup_type,
		  'parent_lookup_code'  => $parent_lookup_code
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>