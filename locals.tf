locals {
  vpc_cidr = "10.123.0.0/16"
}


locals {

  security_groups = {

    public = {
      name        = "public_sg_dynamic"
      description = "SG for public access created dynamically"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }

        rdp = {
          from        = 3389
          to          = 3389
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
      }
    }


  }

}
