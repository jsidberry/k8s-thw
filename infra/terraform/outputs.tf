output "jumpbox_external_ip" {
  value = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}

output "internal_ips" {
  value = merge(
    {
      jumpbox = google_compute_instance.jumpbox.network_interface[0].network_ip
      server  = google_compute_instance.server.network_interface[0].network_ip
    },
    { for name, instance in google_compute_instance.workers : name => instance.network_interface[0].network_ip }
  )
}
