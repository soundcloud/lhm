CREATE TABLE `fk_example_second_pass` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `master_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_example_ibfk_1_lhmn` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_example_ibfk_2_lhmn` FOREIGN KEY (`master_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
