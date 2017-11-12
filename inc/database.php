<?php
    class Database {
        protected $DB_HOST = null;
        protected $DB_USERNAME = null;
        protected $DB_PASSWORD = null;
        protected $DB_DATABASE = null;

        protected $conn = null;

        function __construct($host, $user, $passwd, $db) {
            if ($host != null) {
                $this->DB_HOST = $host;
            } else {
                error("Database::__construct - host not given");
            }
            if ($user != null) {
                $this->DB_USERNAME = $user;
            } else {
                error("Database::__construct - host not given");
            }
            if ($passwd != null) {
                $this->DB_PASSWORD = $passwd;
            } else {
                error("Database::__construct - host not given");
            }
            if ($db != null) {
                $this->DB_DATABASE = $db;
            } else {
                error("Database::__construct - host not given");
            }
        }

        function connect() {
            $this->conn = new mysqli($this->DB_HOST, $this->DB_USERNAME, $this->DB_PASSWORD, $this->DB_DATABASE);
            if ($this->conn->connec_error) {
                error("connection error: ".$this->conn->connect_error);
            }
        }

        function close() {
                $this->conn->close;
                $this->conn = null;
        }
        
        function error($msg) {
            die("ERROR: ".$msg);
        }

        function execute($query) {
            $res = $this->conn->query($query);
            return $res;
        }

        # get single entry from database
        function getEntry($query) {
            $result = $this->conn->query($query);
            if ($result->num_rows > 1) {
                error("Database::getEntry - entry not unique");
            }
            $entry = $result->fetch_row();
            return $entry;
        }

        # get array of entries from database
        function getList($query) {
            $result = $this->conn->query($query);
            $list = array();
            while ($entry = $result->fetch_row()) {
                $list[] = $entry;
            }
            return $list;
        }

        function getDomains() {
            $names = "id, name, type";
            $query = "SELECT ".$names." FROM Domain ORDER BY name";
            $result = $this->getList($query);

            $list = array();
            foreach ($result as $entry) {
                $domain = new Domain($this);
                $domain->id = $entry[0];
                $domain->name = $entry[1];
                $domain->type = $entry[2];

                $list[] = $domain;
            }

            return $list;
        }

        function getRecordsA() {
            $names = "id, name, type, target_id";
            $query = "SELECT ".$names." FROM DNS_Record WHERE type='A' ORDER BY name";
            $result = $this->getList($query);

            $list = array();
            foreach ($result as $entry) {
                $record = new RecordA($this);
                $record->id = $entry[0];
                $record->name = $entry[1];
                $record->type = $entry[2];

                $ptr = new RecordPTR($this);
                $ptr->get($entry[3]);
                $record->ip = $ptr->name;

                $list[] = $record;
            }

            return $list;
        }

        function getSubnets() {
            $names = "id, name";
            $query = "SELECT ".$names." FROM Subnet ORDER BY name";
            $result = $this->getList($query);

            $list = array();
            foreach ($result as $entry) {
                $subnet = new Subnet($this);
                $subnet->id = $entry[0];
                $subnet->name = $entry[1];

                $list[] = $subnet;
            }

            return $list;
        }

        function getSystems() {
            $names = "id, MAC, description, unknown, record_id, fixed";
            $query = "SELECT ".$names." FROM System ORDER BY description";
            $result = $this->getList($query);

            $list = array();
            foreach ($result as $entry) {
                $system = new System($this);
                $system->id = $entry[0];
                $system->mac = $entry[1];
                $system->description = $entry[2];
                $system->unknown = $entry[3];
                $system->record_id = $entry[4];
                $system->fixed = $entry[5];

                $list[] = $system;
            }

            return $list;
        }
    }

    class Domain {
        public $id;
        public $name;
    }

    class Record {
        public $id;
        public $name;
        public $type;
        public $domain_id;

        protected $db;
        protected $target_id;

        function __construct($db = null) {
            if ($db != null) {
                $this->db = $db;
            } else {
                die("class Record->__construct - db not given<br>\n");
            }
        }

        function get($id) {
            $names = "id, name, type, target_id, domain_id";
            $query = "SELECT ".$names." FROM DNS_Record WHERE id='$id'";
            $entry = $this->db->getEntry($query);

            $this->id = $entry[0];
            $this->name = $entry[1];
            $this->type = $entry[2];
            $this->target_id = $entry[3];
            $this->domain_id = $entry[4];
        }

        function insert() {
            $names = "(name)";
            $values = sprintf("('%s')", $this->name);
            $query = "INSERT INTO DNS_Record ".$names." VALUES ".$values;

            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: new record created successfully<br>\n");
            } else {
                printf("mysql: insert error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function show() {
            printf("Record::show<br>\n");
            printf("id = %s<br>\n", $this->id);
            printf("name = %s<br>\n", $this->name);
            printf("type = %s<br>\n", $this->type);
            printf("domain_id = %s<br>\n", $this->domain_id);
            printf("subnet_id = %s<br>\n", $this->subnet_id);
        }

        function update($id) {
            $values = sprintf("name='%s', type='%s'", $this->name, $this->type);
            $query = "UPDATE DNS_Record SET ".$values." WHERE id='$id'";

            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: record updated successfully<br>\n");
            } else {
                printf("mysql: update error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function validate() {
            return 0;
        }
    }
    
    class RecordA extends Record {
        public $ip;
        public $subnet_id;

        function get($id) {
            parent::get($id);
            $ptr = new RecordPTR($this->db);
            $ptr->get($this->target_id);
            $this->ip = $ptr->name;
            $this->subnet_id = $ptr->domain_id;
        }

        function insert() {
            $this->type = "A";

            $names = "(name, type)";
            $values = sprintf("('%s', '%s')", $this->name, $this->type);
            $query = "INSERT INTO DNS_Record ".$names." VALUES ".$values;

            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: new record created successfully<br>\n");
            } else {
                printf("mysql: insert error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function show() {
            parent::show();
            printf("ip = %s<br>\n", $this->ip);
        }

        function update($id) {
            printf("mysql: get ip address %s<br>\n", $this->ip);
            $ptr = new RecordPTR($this->db);
            $res = $ptr->getByName($this->ip);
            $ptr->show();
            printf("DEBUG RecordA::update: %s<br>\n", $res);
            if ($res) {
                printf("ptr: found %s %s<br>\n", $ptr->name, $ptr->id);
                $this->target_id = $ptr->id;
                $ptr->target_id = $id;
                $ptr->domain_id = $this->subnet_id;
                $ptr->update($ptr->id);
            } else {
                printf("ptr: not found %s<br>\n", $this->ip);
                $ptr->name = $this->ip;
                $ptr->target_id = $id;
                $ptr->insert();
                $res = $ptr->getByName($this->ip);
                $this->target_id = $ptr->id;
            }

            $values = sprintf("name='%s', type='%s', domain_id='%s', target_id='%s'", $this->name, $this->type, $this->domain_id, $this->target_id);
            $query = "UPDATE DNS_Record SET ".$values." WHERE id='".$id."'";
            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: record updated successfully<br>\n");
            } else {
                printf("mysql: update error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }
    }

    class RecordPTR extends Record {
        public $hostname;

        function getByName($name) {
            $names = "id, name, type, domain_id, target_id";
            $query = "SELECT ".$names." FROM DNS_Record WHERE name='$name'";
            $entry = $this->db->getEntry($query);
            if (isset($entry)) {
                $this->id = $entry[0];
                $this->name = $entry[1];
                $this->type = $entry[2];
                $this->domain_id = $entry[3];
                $this->target_id = $entry[4];
                return 1;
            } else {
                return 0;
            }
        }

        function insert() {
            $this->type = "PTR";

            $names = "(name, type, domain_id, target_id)";
            $values = sprintf("('%s', '%s', '%s', '%s')", $this->name, $this->type, $this->domain_id, $this->target_id);
            $query = "INSERT INTO DNS_Record ".$names." VALUES ".$values;
            printf("mysql RecordPTR::insert: %s<br>\n", $query);

            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: new record created successfully<br>\n");
            } else {
                printf("mysql: insert error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function update($id) {
            $values = sprintf("name='%s', type='%s', domain_id='%s', target_id='%s'", $this->name, $this->type, $this->domain_id, $this->target_id);
            $query = "UPDATE DNS_Record SET ".$values." WHERE id='$id'";
            printf("mysql: %s<br>\n", $query);
            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: record updated successfully<br>\n");
            } else {
                printf("mysql: update error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }
    }

    class Subnet {
        public $id;
        public $name;
    }

#-------------------
    class System {
        public $id;
        public $mac;
        public $name;
        public $description;
        public $unknown;
        public $record_id;
        public $fixed;

        protected $db;

        function __construct($db = null) {
            if ($db != null) {
                $this->db = $db;
            } else {
                die("class Record->__construct - db not given<br>\n");
            }
        }

        function get($id) {
            $names = "id, MAC, description, unknown, record_id";
            $query = "SELECT ".$names." FROM System WHERE id='$id'";
            $entry = $this->db->getEntry($query);

            $this->id = $entry[0];
            $this->mac = $entry[1];
            $this->description = $entry[2];
            $this->unknown = $entry[3];
            $this->record_id = $entry[4];
            $this->fixed = $entry[5];
        }

        function insert() {
            $names = "(mac, description)";
            $values = sprintf("('%s', '%s')", $this->mac, $this->description);
            $query = "INSERT INTO System ".$names." VALUES ".$values;

            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: new syste created successfully<br>\n");
            } else {
                printf("mysql: insert error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function update($id) {
            $values = sprintf("MAC='%s', description='%s', unknown='%s', record_id='%s', fixed='%s'", $this->mac, $this->description, $this->unknown, $this->record_id, $this->fixed);
            $query = "UPDATE System SET ".$values." WHERE id='$id'";
            $res = $this->db->execute($query);
            if ($res == TRUE) {
                printf("mysql: record updated successfully<br>\n");
            } else {
                printf("mysql: update error<br>\n");
                printf("mysql: %s<br>\n", $res->error);
            }
        }

        function validate() {
            return 0;
        }
    }
?>