<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['org_id']) 
	&& isSet($_POST['lpn_type'])
	&& isSet($_POST['user_id']))
{
	// username and password sent from Form
	$org_id    = mysqli_real_escape_string($db,$_POST['org_id']); 
	$lpn_type  = mysqli_real_escape_string($db,$_POST['lpn_type']); 
	$user_id   = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id   = " . $org_id );
	$db->query("SET @p_lpn_type = " . "'" . $lpn_type . "'");
	$db->query("SET @p_user_id  = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_lpn_id = 0");
	$db->query("set @x_lpn_code = '0'");
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_lpn_generate(@p_org_id, 
	                                         @p_lpn_type, 
	                                         @p_user_id, 
										     @x_lpn_id, 
										     @x_lpn_code, 
										     @x_returnCode, 
										     @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	if (!($res = $db->query("select @x_lpn_id as lpn_id , 
									@x_lpn_code as lpn_code , 
									@x_returnCode as return_code, 
									@x_returnMsg as return_msg")))
		die("Fetch failed: (" . $db->errno . ") " . $db->error);
	
	$row = $res->fetch_assoc();

	//create user array
	$resultInfo[] = array(
	  'lpn_id'      => $row['lpn_id'],
	  'lpn_code'    => $row['lpn_code'],
	  'return_code' => $row['return_code'],
	  'return_msg'  => $row['return_msg']
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>