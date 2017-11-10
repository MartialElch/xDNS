<?php
    include_once 'inc/config.php';
    require_once 'inc/database.php';

    printf("<h1>xDNS - System</h1>\n");

    $db = new Database($DB_HOST, $DB_USERNAME, $DB_PASSWORD, $DB_DATABASE);
    $db->connect();
    $list = $db->getSystems();

    if (isset($_POST['formEditSystem'])) {
        printf("<p>\n");
        printf("<h2>Edit System</h2>\n");

        $id = $_POST['formEditSystem'];

        $system = new System($db);
        $system->get($id);
        $namelist = $db->getRecordsA();
        printf("<form method='post' action='system.php'>\n");
        printf("<table>\n");
        printf("<tr><td>MAC Address:</td> <td><input type='text' name='mac' value='%s'></td></tr>\n", $system->mac);
        printf("<tr><td>Description:</td> <td><input type='text' name='description' value='%s'></td></tr>\n", $system->description);
        printf("<tr><td>DHCP Name:</td> <td>\n");
            printf("<select name='DHCPName[]'>\n");
            printf("<option value='0'>none</option>\n");
            foreach ($namelist as $record) {
                if ($record->id == $system->record_id) {
                    $selected = "selected='selected'";
                } else {
                    $selected = "";
                }
                printf("<option %s value='%s'>%s</option>\n", $selected, $record->id, $record->name);
            }
            printf("</select>\n");
        printf("</td></tr>\n");
        printf("</table>\n");
        printf("<input type='hidden' name='id' value='%s'>\n", $id);
        printf("<p><input name='formUpdateSystem' type='submit' value='update'/></p>\n");
        printf("</form>\n");
        printf("</p>\n");
    }

    if (isset($_POST['formUpdateSystem'])) {
        $id = $_POST['id'];
        $system = new System($db);
        $system->mac = $_POST['mac'];
        $system->description = $_POST['description'];
        $system->record_id = $_POST['DHCPName'][0];
        if ($_POST['DHCPName'][0] != 0) {
            $system->fixed = 1;
        } else {
            $system->fixed = 0;
        }
        $system->update($id);

        printf("<p>\n");
        printf("<h2>Edit System</h2>\n");
        $system->get($id);
        $namelist = $db->getRecordsA();
        printf("<form method='post' action='system.php'>\n");
        printf("<table>\n");
        printf("<tr><td>MAC Address:</td> <td><input type='text' name='mac' value='%s'></td></tr>\n", $system->mac);
        printf("<tr><td>Description:</td> <td><input type='text' name='description' value='%s'></td></tr>\n", $system->description);
        printf("<tr><td>DHCP Name:</td> <td>\n");
            printf("<select name='DHCPName[]'>\n");
            printf("<option value='0'>none</option>\n");
            foreach ($namelist as $record) {
                if ($record->id == $system->record_id) {
                    $selected = "selected='selected'";
                } else {
                    $selected = "";
                }
                printf("<option %s value='%s'>%s</option>\n", $selected, $record->id, $record->name);
            }
            printf("</select>\n");
        printf("</td></tr>\n");
        printf("</table>\n");
        printf("<input type='hidden' name='id' value='%s'>\n", $id);
        printf("<p><input name='formUpdateSystem' type='submit' value='update'/></p>\n");
        printf("</form>\n");
        printf("</p>\n");

        $list = $db->getSystems();
    }

    $db->close();

    printf("<p>\n");
    printf("<form action='system.php' method='post'>\n");
    printf("<table>\n");
    printf("<tr><th>MAC Address</th><th>Hostname</th><th>Description</th><th>Fixed<th></tr>\n");
    foreach ($list as $system) {
        if ($system->fixed == 1) {
            $fixed = "fixed";
        } else {
            $fixed = "";
        }
        printf("<tr><td>%s</td> <td>%s</td><td>%s</td><td>%s</td>\n", $system->mac, $system->name, $system->description, $fixed);
        printf("<td><input name='formEditSystem' type='image' value='%d' src='img/edit.svg.png'/></td>\n", $system->id);
        printf("</tr>\n");
    }
    printf("</table>\n");
    printf("</p>\n");
    printf("</form>\n");

    printf("<p>\n");
    printf("<a href=index.php>Home</a>\n");
    printf("</p>\n");
?>
