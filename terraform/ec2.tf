# Fetch the AMI for the instance based on specified filters
data "aws_ami" "ubuntu" {
    owners      = [var.aws_ami_owners]
    most_recent = true

    filter {
        name   = "name"
        values = [var.aws_instance_os_type]
    }

    filter {
        name   = "state"
        values = ["available"]
    }
}

# Create an SSH key pair
resource "aws_key_pair" "terraform_key" {
    key_name   = "mega-project-key"
    public_key = file("mega-project-key.pub")
}

# Get the default VPC for the region
resource "aws_default_vpc" "default" {
    enable_dns_hostnames = true
    enable_dns_support = true
}

# Create a security group
resource "aws_security_group" "terraform_sg" {
    name        = "mega-project-sg"
    description = var.aws_sg_description
    vpc_id      = aws_default_vpc.default.id

    ingress {
        description = "Allow access to SSH port 22"
        from_port   = 22
        to_port     = 22
       # protocol    = var.ssh_protocol
       # cidr_blocks = [var.ssh_cidr]
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"] 
   }

    ingress {
        description = "Allow access to HTTP port 80"
        from_port   = 80
        to_port     = 80
       # protocol    = var.http_protocol
       # cidr_blocks = [var.http_cidr]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  
  }

    ingress {
        description = "Allow access to HTTPS port 443"
        from_port   = 443
        to_port     = 443
       # protocol    = var.https_protocol
       # cidr_blocks = [var.https_cidr]
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]  
  }

    egress {
        description = "Allow all outgoing traffic"
        from_port   = 0
        to_port     = 0
       # protocol    = var.outgoing_protocol
       # cidr_blocks = [var.outgoing_cidr]
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]  
  }

    tags = {
        Name = var.aws_sg_name
    }
}

# Create an EC2 instance
resource "aws_instance" "mega_project_instance" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = var.aws_instance_type
    key_name      = aws_key_pair.terraform_key.key_name
    vpc_security_group_ids = [aws_security_group.terraform_sg.id]
    associate_public_ip_address = true

    root_block_device {
        volume_size = var.aws_instance_storage_size
        volume_type = var.aws_instance_volume_type
    }

    # User data to ensure SSH is properly configured
    user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y openssh-server
              systemctl enable ssh
              systemctl start ssh
              systemctl status ssh
              
              # Ensure SSH is listening on port 22
              sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
              sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
              sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart ssh
              
              # Log for debugging
              echo "SSH service status:" >> /var/log/user-data.log
              systemctl status ssh >> /var/log/user-data.log
              echo "SSH config:" >> /var/log/user-data.log
              cat /etc/ssh/sshd_config | grep -E "Port|PubkeyAuthentication|PermitRootLogin" >> /var/log/user-data.log
              EOF
    )

    tags = {
        Name = var.aws_instance_name
    }
}
