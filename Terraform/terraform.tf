resource "digitalocean_droplet" "katrips" {
  image = "ubuntu-20-04-x64"
  name = "katrips"
  region = "sgp1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.katrips.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
}

# Configure firewall
resource "digitalocean_firewall" "katrips-firewall" {
  name = "katrips-firewall"
  droplet_ids = [digitalocean_droplet.katrips.id]

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# Configure DNS
resource "digitalocean_domain" "katrips-domain" {
  name = "katrips.me"
  ip_address = digitalocean_droplet.katrips.ipv4_address
}

# Configure DNS Records (www and api)
resource "digitalocean_record" "www" {
  domain = digitalocean_domain.katrips-domain.name
  type = "A"
  name = "www"
  value = digitalocean_domain.katrips-domain.ip_address
}

resource "digitalocean_record" "api" {
  domain = digitalocean_domain.katrips-domain.name
  type = "A"
  name = "api"
  value = digitalocean_domain.katrips-domain.ip_address
}

# Create Ansible Inventory file
resource "local_file" "AnsibleInventory" {
  depends_on = [digitalocean_droplet.katrips]

  content = templatefile("inventory.tmpl",
    {
      dbserver-ip = digitalocean_droplet.katrips.ipv4_address
      dbserver-name = digitalocean_droplet.katrips.name
      webserver-ip = digitalocean_droplet.katrips.ipv4_address
      webserver-name = digitalocean_droplet.katrips.name
    }
  )
  filename = "../ansible/inventory"
}