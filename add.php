<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS - Add</h1>\n");

    if (isset($_POST['formAddRecordA'])) {
        printf("Add A Record<br>\n");

        $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
        $db->connect();
        $record = new RecordA($db);

        $record->name = $_POST['hostname'];
        $record->ip = $_POST['ip'];
        if ($record->validate() == 0) {
            $record->insert();
        }

        $db->close();
    }

    if (isset($_POST['formAddSystem'])) {
        printf("Add System<br>\n");

        $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
        $db->connect();
        $system = new System($db);

        $system->mac = $_POST['mac'];
        $system->description = $_POST['description'];
        if ($system->validate() == 0) {
            $system->insert();
        }

        $db->close();
    }

    printf("<h2>Add A Record</h2>\n");

    printf("<p>\n");
    printf("<form method='post' action='add.php'>\n");
    printf("<table>\n");
    printf("<tr><td>Hostname:</td> <td><input type='text' name='hostname'></td></tr>\n");
    printf("<tr><td>IP Address:</td> <td><input type='text' name='ip'></td></tr>\n");
    printf("</table>\n");
    printf("<p><input name='formAddRecordA' type='submit' value='add'/></p>\n");
    printf("</form>\n");
    printf("</p>\n");

    printf("<h2>Add System</h2>\n");

    printf("<p>\n");
    printf("<form method='post' action='add.php'>\n");
    printf("<table>\n");
    printf("<tr><td>MAC Address:</td> <td><input type='text' name='mac'></td></tr>\n");
    printf("<tr><td>Description:</td> <td><input type='text' name='description'></td></tr>\n");
    printf("</table>\n");
    printf("<p><input name='formAddSystem' type='submit' value='add'/></p>\n");
    printf("</form>\n");
    printf("</p>\n");

    printf("<p>\n");
    printf("<a href=index.php>Home</a>\n");
    printf("</p>\n");
?>
