<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS - Add</h1>\n");

    if (isset($_POST['formAdd'])) {
        printf("Add Record<br>\n");

        $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
        $db->connect();
        $record = new Record($db);

        $record->name = $_POST['hostname'];
        if ($record->validate() == 0) {
            $record->insert();
        }

        $db->close();
    }

    printf("<p>\n");
    printf("<form method='post' action='add.php'>\n");
    printf("<table>\n");
    printf("<tr><td>Hostname:</td> <td><input type='text' name='hostname'></td></tr>\n");
    printf("<tr><td>IP Address:</td> <td><input type='text' name='ip'></td></tr>\n");
    printf("</table>\n");
    printf("<p><input name='formAdd' type='submit' value='add'/></p>\n");
    printf("</form>\n");
    printf("</p>\n");

    printf("<p>\n");
    printf("<a href=index.php>Home</a>\n");
    printf("</p>\n");
?>
