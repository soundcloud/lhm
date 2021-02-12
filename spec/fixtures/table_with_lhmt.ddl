CREATE TABLE IF NOT EXISTS `triggers_origin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `origin` int(11) DEFAULT NULL,
  `common` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `triggers_destination` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `destination` int(11) DEFAULT NULL,
  `common` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TRIGGER `lhmt_ins_triggers_origin`
AFTER INSERT ON `triggers_origin` for each row
REPLACE INTO `triggers_destination` (`destination`, `common`)
VALUES (NEW.`origin`, NEW.`common`);

CREATE TRIGGER `lhmt_upd_triggers_origin`
AFTER UPDATE ON `triggers_origin` for each row
REPLACE INTO `triggers_destination` (`destination`, `common`)
VALUES (NEW.`origin`, NEW.`common`);

CREATE TRIGGER `lhmt_del_triggers_origin`
AFTER DELETE ON `triggers_origin` for each row
DELETE IGNORE FROM `triggers_destination`
WHERE `triggers_destination`.`id` = OLD.`id`;
