<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['org_id']) 
	&& isSet($_POST['item_code'])
	&& isSet($_POST['serial_descr'])
	&& isSet($_POST['user_id']))
{
	// username and password sent from Form
	$org_id        = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_code     = mysqli_real_escape_string($db,$_POST['item_code']); 
	$serial_descr  = mysqli_real_escape_string($db,$_POST['serial_descr']); 
	$user_id       = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id        = " . $org_id );
	$db->query("SET @p_item_code     = " . "'" . $item_code . "'");
	$db->query("SET @p_serial_descr  = " . "'" . $serial_descr . "'");
	$db->query("SET @p_user_id       = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_serial_no = '0'");
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_serial_generate(@p_org_id, 
	                                            @p_item_code, 
	                                            @p_serial_descr, 
	                                            @p_user_id, 
										        @x_serial_no, 
										        @x_returnCode, 
										        @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	if (!($res = $db->query("select @x_serial_no as serial_no , 
									@x_returnCode as return_code, 
									@x_returnMsg as return_msg")))
		die("Fetch failed: (" . $db->errno . ") " . $db->error);
	
	$row = $res->fetch_assoc();

	//create user array
	$resultInfo[] = array(
	  'serial_no'     => $row['serial_no'],
	  'return_code'   => $row['return_code'],
	  'return_msg'    => $row['return_msg']
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>