-- stage.messages_for_send definition
CREATE TABLE stage.producers (
	id INT auto_increment NOT NULL,
	`path` varchar(100) NOT NULL,
	compile_command varchar(255) NOT NULL,
	run_command varchar(255) NOT NULL,
	is_run BOOL DEFAULT 0 NOT NULL,
	is_deleted BOOL DEFAULT 0 NOT NULL,
    PRIMARY KEY (id)
)
ENGINE=InnoDB;


CREATE TABLE stage.messages_for_send (
	id INT auto_increment NOT NULL,
	`timestamp` TIMESTAMP NOT NULL,
	`data` LONGTEXT NOT NULL,
    is_sent BOOL DEFAULT 0 NOT NULL,
	producer_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (producer_id) REFERENCES producers(id)
)
ENGINE=InnoDB;

CREATE TABLE stage.messages_for_read (
	id INT auto_increment NOT NULL,
	`timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`data` LONGTEXT NOT NULL,
    update_id INT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (update_id)
)
ENGINE=InnoDB;