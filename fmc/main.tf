# Fetch existing security zones
data "fmc_security_zone" "inside" {
  name           = "ciscomcd-inside"
}
data "fmc_security_zone" "outside" {
  name           = "ciscomcd-outside"
}

# Define network objects for Spoke VPCs
resource "fmc_network" "spoke1-vpc" {
  name        = "Spoke1-VPC"
  prefix      = "10.1.0.0/16"
}
resource "fmc_network" "spoke2-vpc" {
  name        = "Spoke2-VPC"
  prefix      = "10.2.0.0/16"
}

# Define access control policy with rules
resource "fmc_access_control_policy" "example" {
  name                                = "MCD Deployed FTDv"
  description                         = "CL EMEA-2026"
  default_action                      = "BLOCK"
  default_action_log_connection_begin = true
  default_action_send_events_to_fmc   = true

  manage_rules = true
  rules = [
    {
      action = "ALLOW"
      name   = "Allow Spoke1 to Spoke2 Traffic"
      source_network_objects = [
        {
          id   = fmc_network.spoke1-vpc.id
          type = "Network"
        }
      ]
      destination_network_objects = [
        {
          id   = fmc_network.spoke2-vpc.id
          type = "Network"
        }
      ]
      destination_port_literals = [ 
        {
          type      = "PortLiteral"
          port      = "3306"
          protocol  = "6"
        }
      ]
      
      log_connection_end   = true
      send_events_to_fmc   = true
    },
    {
      action = "ALLOW"
      name   = "Allow Spoke2 to Spoke1 Traffic"
      source_network_objects = [
        {
          id   = fmc_network.spoke2-vpc.id
          type = "Network"
        }
      ]
      destination_network_objects = [
        {
          id   = fmc_network.spoke1-vpc.id
          type = "Network"
        }
      ]
      destination_port_literals = [
        {
          type      = "PortLiteral"
          port      = "443"
          protocol  = "6"
        },
        {
          type      = "PortLiteral"
          port      = "22"
          protocol  = "6"
        }
      ]
      
      log_connection_end   = true
      send_events_to_fmc   = true
    },
    {
      action = "ALLOW"
      name   = "Allow Outbound"
      
      source_zones = [
        {
          id =  data.fmc_security_zone.inside.id
        }
      ]
      destination_zones = [
        {
          id = data.fmc_security_zone.outside.id
        }
      ]
      
      log_connection_end   = true
      send_events_to_fmc   = true
    }
  ]
}