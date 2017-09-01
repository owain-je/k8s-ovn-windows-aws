resource "aws_instance" "bastion-linux" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "${var.bastion-linux-instance-type}"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Bastion-Linux.id}"]
  key_name = "${var.cluster-name}"
  tags {
        Name = "${var.cluster-name}-bastion-linux"
  }
  user_data = <<HEREDOC
  #!/bin/bash
  #yum update -y
  #yum install -y httpd24 php56 php56-mysqlnd
  #service httpd start
  #chkconfig httpd on
  #echo "<?php" >> /var/www/html/calldb.php
  #echo "\$conn = new mysqli('mydatabase.linuxacademy.internal', 'root', 'secret', 'test');" >> /var/www/html/calldb.php
  #echo "\$sql = 'SELECT * FROM mytable'; " >> /var/www/html/calldb.php
  #echo "\$result = \$conn->query(\$sql); " >>  /var/www/html/calldb.php
  #echo "while(\$row = \$result->fetch_assoc()) { echo 'the value is: ' . \$row['mycol'] ;} " >> /var/www/html/calldb.php
  #echo "\$conn->close(); " >> /var/www/html/calldb.php
  #echo "?>" >> /var/www/html/calldb.php
HEREDOC
}

resource "aws_instance" "bastion-win" {
  ami           = "${lookup(var.AmiWin, var.region)}"
  instance_type = "${var.bastion-windows-instance-type}"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Bastion-Win.id}"]
  key_name = "${var.cluster-name}"
  tags {
        Name = "${var.cluster-name}-bastion-windows"
  }
  user_data = <<HEREDOC
  #!/bin/bash
  #yum update -y
  #yum install -y httpd24 php56 php56-mysqlnd
  #service httpd start
  #chkconfig httpd on
  #echo "<?php" >> /var/www/html/calldb.php
  #echo "\$conn = new mysqli('mydatabase.linuxacademy.internal', 'root', 'secret', 'test');" >> /var/www/html/calldb.php
  #echo "\$sql = 'SELECT * FROM mytable'; " >> /var/www/html/calldb.php
  #echo "\$result = \$conn->query(\$sql); " >>  /var/www/html/calldb.php
  #echo "while(\$row = \$result->fetch_assoc()) { echo 'the value is: ' . \$row['mycol'] ;} " >> /var/www/html/calldb.php
  #echo "\$conn->close(); " >> /var/www/html/calldb.php
  #echo "?>" >> /var/www/html/calldb.php
HEREDOC
}