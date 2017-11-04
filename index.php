<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS</h1>\n");

    $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
    if ($db->connect_error) {
    	printf("Connection failed: %s<br>\n", $conn->connect_error);
    } else {
        $db->connect();
        $list = $db->getRecordsA();

        printf("<form action='edit.php' method='post'>\n");
        printf("<table>\n");
    printf("<tr><th>Hostname</th><th>Type</th><th>IP Address</th></tr>\n");
    foreach ($list as $record) {
        printf("<tr><td>%s</td> <td>%s</td><td>%s</td>\n", $record->name, $record->type, $record->ip);
        printf("<td><input name='formEdit' type='image' value='%d' src='img/edit.gif'/></td>\n", $record->id);
        printf("<td><input name='formDelete' type='image' value='%d' src='img/delete.gif' formaction='delete.php'/></td>\n", $record->id);
        printf("</tr>\n");
    }
        printf("</table>\n");
        printf("</form>\n");

    	$db->close();
    }

    printf("<p>\n");
    printf("<a href=add.php>Add Host</a>\n");
    printf("</p>\n");

?>
