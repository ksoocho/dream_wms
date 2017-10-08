<?php
define('DB_SERVER', 'localhost');
define('DB_USERNAME', 'cksoonew');
define('DB_PASSWORD', 'xxxxxx');
define('DB_DATABASE', 'cksoonew');

$db = mysqli_connect(DB_SERVER,DB_USERNAME,DB_PASSWORD,DB_DATABASE);

if (mysqli_connect_errno())
{
 echo "connection was not established" . mysqli_connect_error();
}
?>
