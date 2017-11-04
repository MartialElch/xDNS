<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS</h1>\n");

    $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
    if ($db->connect_error) {
    	printf("Connection failed: %s<br>\n", $conn->connect_error);
    } else {
        $db->connect();
        $list = $db->getList("SELECT * FROM DNS_Record WHERE TYPE='A' ORDER BY name");

        printf("<form action='edit.php' method='post'>\n");
        printf("<table>\n");
        foreach ($list as $entry) {
            printf("<tr><td>%s</td> <td>%s</td>\n", $entry[1], $entry[2]);
            printf("<td><input name='formEdit' type='image' value='%d' src='img/edit.gif'/></td>\n", $entry[0]);
            printf("<td><input name='formDelete' type='image' value='%d' src='img/delete.gif' formaction='delete.php'/></td>\n", $entry[0]);
            printf("</tr>\n");
        }
        printf("</table>\n");
        printf("</form>\n");

    	$db->close();
    }

?>
