resource "tls_private_key" "ops" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ops_private_key" {
  content         = tls_private_key.ops.private_key_openssh
  filename        = "${path.module}/.ssh/id_ed25519"
  file_permission = "0600"
}

locals {
  ssh_keys_metadata = "ops:${trimspace(tls_private_key.ops.public_key_openssh)}"

  internal_ssh_config = <<-EOT
    Host server
      HostName ${google_compute_instance.server.network_interface[0].network_ip}
      User ops
      IdentityFile /opt/k8s-thw/id_ed25519
      StrictHostKeyChecking accept-new
      UserKnownHostsFile /dev/null
    %{ for name, inst in google_compute_instance.workers ~}
    Host ${name}
      HostName ${inst.network_interface[0].network_ip}
      User ops
      IdentityFile /opt/k8s-thw/id_ed25519
      StrictHostKeyChecking accept-new
      UserKnownHostsFile /dev/null
    %{ endfor ~}
  EOT

  jumpbox_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail

    mkdir -p /opt/k8s-thw
    curl -s -H "Metadata-Flavor: Google" \
      "http://metadata.google.internal/computeMetadata/v1/instance/attributes/internal-ssh-private-key" \
      -o /opt/k8s-thw/id_ed25519
    chmod 600 /opt/k8s-thw/id_ed25519

    mkdir -p /etc/ssh/ssh_config.d
    curl -s -H "Metadata-Flavor: Google" \
      "http://metadata.google.internal/computeMetadata/v1/instance/attributes/internal-ssh-config" \
      -o /etc/ssh/ssh_config.d/k8s-thw.conf
  EOT
}
