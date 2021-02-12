CREATE TABLE IF NOT EXISTS `lhmn_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `origin` int(11) DEFAULT NULL,
  `common` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
