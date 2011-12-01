sql = <<SQL
CREATE TABLE `aaatest` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `aaatest` (`user`, `created_at`) VALUES ('albert', UTC_TIMESTAMP()), ('berta', UTC_TIMESTAMP()), ('caroline', UTC_TIMESTAMP()), ('detlef', UTC_TIMESTAMP())

# create new table
CREATE TABLE `aaatest__tmp` LIKE `aaatest`;

# alter table
ALTER TABLE `aaatest__tmp` ADD COLUMN `name` varchar(255);

# create triggers
# shared columns are (`id`, `user`, `created_at`)
CREATE TRIGGER mk_osc_del AFTER DELETE ON `aaatest` FOR EACH ROW DELETE IGNORE FROM `aaatest__tmp` WHERE `aaatest__tmp`.`id` = OLD.`id`;
CREATE TRIGGER mk_osc_ins AFTER INSERT ON `aaatest` FOR EACH ROW REPLACE INTO `aaatest__tmp` (`id`, `user`, `created_at`) VALUES (NEW.`id`, NEW.`user`, NEW.`created_at`);
CREATE TRIGGER mk_osc_upd AFTER UPDATE ON `aaatest` FOR EACH ROW REPLACE INTO `aaatest__tmp` (`id`, `user`, `created_at`) VALUES (NEW.`id`, NEW.`user`, NEW.`created_at`);

INSERT INTO `aaatest` (`user`, `created_at`) VALUES ('albert', UTC_TIMESTAMP()), ('berta', UTC_TIMESTAMP()), ('caroline', UTC_TIMESTAMP()), ('detlef', UTC_TIMESTAMP());

# chunked insert
INSERT IGNORE INTO `aaatest__tmp` (`id`, `user`, `created_at`) SELECT `id`, `user`, `created_at` FROM `aaatest`;

# rename
RENAME TABLE `aaatest` TO `aaatest__old`, `aaatest__tmp` TO `aaatest`;

# cleanup
DROP TRIGGER IF EXISTS `mk_osc_del`;
DROP TRIGGER IF EXISTS `mk_osc_ins`;
DROP TRIGGER IF EXISTS `mk_osc_upd`;

DROP TABLE `aaatest__old`;
SQL
