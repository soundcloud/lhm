CREATE TABLE `fk_child_table` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `origin_table_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_origin_table_id` FOREIGN KEY (`origin_table_id`) REFERENCES `origin_example` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
