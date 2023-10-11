DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS UserGroup;

CREATE TABLE IF NOT EXISTS User(
	id varchar(255) PRIMARY KEY,
	name TEXT,
	groupId varchar(255)
);

CREATE TABLE IF NOT EXISTS UserGroup(
	id varchar(255) PRIMARY KEY,
	name TEXT
);

ALTER TABLE User ADD CONSTRAINT fk_group_id FOREIGN KEY (groupId) REFERENCES UserGroup(id);
INSERT INTO UserGroup (id, name) VALUES('group1', 'Group 1');
INSERT INTO User (id, name, groupId) VALUES('user1', 'User 1', 'group1');
INSERT INTO User (id, name, groupId) VALUES('user2', 'User 2', 'group1');
