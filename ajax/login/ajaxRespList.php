<?php

include("../db.php");

if(isSet($_POST['user_id']))
{	
	$user_id = mysqli_real_escape_string($db,$_POST['user_id']); 
	
	$sql =  "SELECT resp.RESPONSIBILITY_ID AS resp_id
				   ,resp.RESPONSIBILITY_NAME AS resp_name
			FROM cks_wms_furg furg
				,cks_wms_resp resp
			WHERE furg.USER_ID = $user_id
			AND   furg.ENABLED_FLAG = 'Y'
			AND   furg.START_DATE <= SYSDATE()
			AND   IFNULL(END_DATE,SYSDATE()) >= SYSDATE()
			AND   resp.RESPONSIBILITY_ID = furg.RESPONSIBILITY_ID
			AND   resp.ENABLED_FLAG = 'Y'
			" ;

	//echo $sql;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$respArray[] = array(
		  'resp_id'   => $row['resp_id'],
		  'resp_name' => $row['resp_name']
		);
	}
	echo json_encode($respArray);

	//close the db connection
	mysqli_close($db);
}	
?>