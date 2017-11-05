<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS</h1>\n");

    $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
    if ($db->connect_error) {
    	printf("Connection failed: %s<br>\n", $conn->connect_error);
    } else {
        $db->connect();

        printf("<h2>DNS Names</h2>\n");
        $list = $db->getRecordsA();

        printf("<form action='edit.php' method='post'>\n");
        printf("<table>\n");
        printf("<tr><th>Hostname</th><th>Type</th><th>IP Address</th></tr>\n");
        foreach ($list as $record) {
            printf("<tr><td>%s</td> <td>%s</td><td>%s</td>\n", $record->name, $record->type, $record->ip);
            printf("<td><input name='formEdit' type='image' value='%d' src='img/edit.svg.png'/></td>\n", $record->id);
            printf("<td><input name='formDelete' type='image' value='%d' src='img/delete.svg.png' formaction='delete.php'/></td>\n", $record->id);
            printf("</tr>\n");
        }
        printf("</table>\n");
        printf("</form>\n");

        printf("<h2>Systems</h2>\n");
        $list = $db->getSystems();

        printf("<form action='system.php' method='post'>\n");
        printf("<table>\n");
        printf("<tr><th>MAC Address</th><th>Hostname</th><th>Description</th></tr>\n");
        foreach ($list as $system) {
            printf("<tr><td>%s</td> <td>%s</td><td>%s</td>\n", $system->mac, $system->name, $system->description);
            printf("<td><input name='formEditSystem' type='image' value='%d' src='img/edit.svg.png'/></td>\n", $system->id);
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
