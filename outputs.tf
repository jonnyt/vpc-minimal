output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "ngw1_id" {
  value = "${aws_nat_gateway.ngw1.id}"
}

output "ngw2_id" {
  value = "${aws_nat_gateway.ngw2.*.id}"
}

output "pub-net-1_id" {
  value = "${aws_subnet.pub-net-1.id}"
}

output "pub-net-2_id" {
  value = "${aws_subnet.pub-net-2.id}"
}

output "priv-net-1_id" {
  value = "${aws_subnet.priv-net-1.id}"
}

output "priv-net-2_id" {
  value = "${aws_subnet.priv-net-2.id}"
}

output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
}

output "rt_priv-net-1_id" {
  value = "${aws_route_table.priv-net-1.id}"
}

output "rt_priv-net-2_id" {
  value = "${aws_route_table.priv-net-2.id}"
}

output "rt_pub-nets_id" {
  value = "${aws_route_table.pub-nets.id}"
}
