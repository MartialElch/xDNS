<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS - Edit</h1>\n");
    $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);

    if(isset($_POST['formEdit'])) {
        $id = $_POST['formEdit'];

        $db->connect();
        $record = new RecordA($db);
        $record->get($id);
        $record->show();
        $db->close();

        if ($record->type) {
            $type = $record->type;
        } else {
            $type = 'A';
        }
    }
    
    if(isset($_POST['formUpdate'])) {
        printf("Update Entry<br>\n");

        printf("id = %s<br>\n", $_POST['id']);
        printf("name = %s<br>\n", $_POST['hostname']);
        printf("ip = %s<br>\n", $_POST['ip']);
        printf("type = %s<br>\n", $_POST['type'][0]);
        $type = $_POST['type'][0];

        $record = new RecordA($db);
        $record->name = $_POST['hostname'];
        $record->ip = $_POST['ip'];
        $record->type = $_POST['type'][0];

        $record->show();

        $db->connect();
        $record->update($_POST['id']);
        $db->close();
    }

    printf("<p>\n");
    printf("<form method='post' action='edit.php'>\n");
    printf("<table>\n");
    printf("<select name='type[]'>\n");
    printf("<option value='A'>Computereintrag</option>\n");
    printf("<option value='CNAME'>Alias-Eintrag</option>\n");
    printf("<option value='MX'>Mail Alias-Eintrag</option>\n");
    printf("<option value='NS'>Name-Servereintrag</option>\n");
    printf("</select>\n");
    printf("<tr><td>Hostname:</td> <td><input type='text' name='hostname' value='%s'></td></tr>\n", $record->name);
    printf("<tr><td>IP Address:</td> <td><input type='text' name='ip' value='%s'></td></tr>\n", $record->ip);
    printf("</table>\n");
    printf("<input type='hidden' name='id' value='%s'>\n", $id);
    printf("<p><input name='formUpdate' type='submit' value='update'/></p>\n");
    printf("</form>\n");
    printf("</p>\n");

    printf("<p>\n");
    printf("<a href=index.php>Home</a>\n");
    printf("</p>\n");
?>
