resource "aws_instance" "cluster-controller" {
  count         = var.controller_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.cluster_flavor
  tags = {
    Name = format("%s-controller-%d", var.cluster_name, count.index)
  }
  key_name                    = aws_key_pair.cluster-key.key_name
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.cluster_allow_ssh.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.k8s-conformance-key.private_key_pem
    host        = self.public_ip
    agent       = true
  }

  provisioner "remote-exec" {
    inline = [<<EOF
      sudo hostnamectl set-hostname controller-${count.index}
      sudo sh -c 'echo 127.0.0.1 controller-${count.index} >> /etc/hosts'
    EOF
    ]
  }
}

resource "aws_eip" "controller-ext" {
  count    = var.controller_count
  instance = aws_instance.cluster-controller[count.index].id
  vpc      = true
}
