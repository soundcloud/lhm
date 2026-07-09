CREATE TABLE `fk_example` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `master_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_example_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_example_ibfk_2` FOREIGN KEY (`master_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
