region = "us-east-1"

namespace = "eg"

environment = "ue1"

stage = "test"

name = "msk-test"

delimiter = "-"

#zone_id = "Z00000000000000" # add your hosted zone here

availability_zones = ["us-east-1a", "us-east-1b"]

kafka_version = "2.4.2"

number_of_broker_nodes = 2

broker_instance_type = "kafka.t3.small"
