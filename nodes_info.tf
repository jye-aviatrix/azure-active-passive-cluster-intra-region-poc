resource "local_file" "nodes_info" {
    content  = jsonencode(module.network_interfaces)
    filename = "./nodes_info.json"
}