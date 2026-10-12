resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "public"
  }
}


resource "aws_subnet" "private_server" {
  count             = length(var.private_server_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_server_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-server-subnet-${count.index + 1}"
    Type = "private-server"
  }
}

resource "aws_subnet" "private_db" {
  count             = length(var.private_db_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-db-subnet-${count.index + 1}"
    Type = "private-db"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_server" {
  count          = length(aws_subnet.private_server)
  subnet_id      = aws_subnet.private_server[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}
