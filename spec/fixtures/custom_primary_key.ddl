CREATE TABLE `custom_primary_key` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pk` varchar(255),
  PRIMARY KEY (`pk`),
  UNIQUE KEY `index_custom_primary_key_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
