<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['org_id']) 
	&& isSet($_POST['item_group_id'])
	&& isSet($_POST['item_descr'])
	&& isSet($_POST['item_spec'])
	&& isSet($_POST['item_type'])
	&& isSet($_POST['serial_flag'])
	&& isSet($_POST['user_id']))
{
	// username and password sent from Form
	$org_id        = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group_id = mysqli_real_escape_string($db,$_POST['item_group_id']); 
	$item_descr    = mysqli_real_escape_string($db,$_POST['item_descr']); 
	$item_spec     = mysqli_real_escape_string($db,$_POST['item_spec']); 
	$item_type     = mysqli_real_escape_string($db,$_POST['item_type']); 
	$serial_flag   = mysqli_real_escape_string($db,$_POST['serial_flag']); 
	$user_id       = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id        = " . $org_id );
	$db->query("SET @p_item_group_id = " . $item_group_id );
	$db->query("SET @p_item_descr    = " . "'" . $item_descr . "'");
	$db->query("SET @p_item_spec     = " . "'" . $item_spec . "'");
	$db->query("SET @p_item_type     = " . "'" . $item_type . "'");
	$db->query("SET @p_serial_flag   = " . "'" . $serial_flag . "'");
	$db->query("SET @p_user_id       = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_item_id = 0");
	$db->query("set @x_item_code = '0'");
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_item_generate(@p_org_id, 
	                                          @p_item_group_id, 
	                                          @p_item_descr, 
	                                          @p_item_spec, 
	                                          @p_item_type, 
	                                          @p_serial_flag, 
	                                          @p_user_id, 
										      @x_item_id, 
										      @x_item_code, 
										      @x_returnCode, 
										      @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	if (!($res = $db->query("select @x_item_id as item_id , 
									@x_item_code as item_code, 
									@x_returnCode as return_code, 
									@x_returnMsg as return_msg")))
		die("Fetch failed: (" . $db->errno . ") " . $db->error);
	
	$row = $res->fetch_assoc();

	//create user array
	$resultInfo[] = array(
	  'item_id'       => $row['item_id'],
	  'item_code'     => $row['item_code'],
	  'return_code'   => $row['return_code'],
	  'return_msg'    => $row['return_msg']
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>