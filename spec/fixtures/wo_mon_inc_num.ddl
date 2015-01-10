-- Without auto increment
CREATE TABLE `wo_mon_inc_num` (
  `id` int(11) NOT NULL,
  `pk` varchar(255),
  PRIMARY KEY (`pk`),
  UNIQUE KEY `index_custom_primary_key_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
