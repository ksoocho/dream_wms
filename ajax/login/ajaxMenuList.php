<?php

include("../db.php");

if(isSet($_POST['subinv_type']))
{	
	$subinv_type = mysqli_real_escape_string($db,$_POST['subinv_type']); 
	
	$sql =  "SELECT FUNCTION_ID  AS func_id
				  ,FUNCTION_NAME AS func_name
                  ,WEB_HTML_CALL AS web_call
                  ,PARAMETERS    AS web_parameter
			FROM cks_wms_func 
			WHERE ENABLED_FLAG = 'Y'
			AND   EX_SUBINV_TYPE = '$subinv_type'
			ORDER BY FUNCTION_NUM
			" ;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$funcArray[] = array(
		  'func_id'       => $row['func_id'],
		  'func_name'     => $row['func_name'],
		  'web_call'      => $row['web_call'],
		  'web_parameter' => $row['web_parameter']
		);
	}
	echo json_encode($funcArray);

	//close the db connection
	mysqli_close($db);
}	
?>