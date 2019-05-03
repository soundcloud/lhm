CREATE TABLE `lhmn_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reference` int(11) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `group` varchar(255) DEFAULT 'Superfriends',
  `created_at` datetime DEFAULT NULL,
  `comment` varchar(20) DEFAULT NULL,
  `description` text,
  `logins` int(12) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_reference` (`reference`),
  KEY `index_users_on_username_and_created_at` (`username`,`created_at`),
  KEY `index_with_a_custom_name` (`username`,`group`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8
