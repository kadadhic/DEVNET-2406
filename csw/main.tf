terraform {
  required_providers {
    secureworkload = {
      source = "CiscoDevNet/secureworkload"
      # version = "0.1.1"
    }
  }
}
provider "secureworkload" {
  api_key                  = var.key
  api_secret               = var.secret
  api_url                  = var.host
  disable_tls_verification = true
}

###############################################################################################
# Labelling
###############################################################################################
data "secureworkload_scope" "scope" {
    exact_name = "kadadhic:Internal:Datacenter:Production"
    exact_short_name = "Production"
}

resource "secureworkload_label" "label-1" {
    depends_on = [ time_sleep.wait_10_seconds1 ]
    ip = "10.3.1.0/24"
    root_scope_name = "kadadhic"
    attributes = {
        organization = "Internal"
        location = "Datacenter"
        environment = "Production"
        application = "FinanceApp"
    }
}
resource "secureworkload_label" "label-2" {
    depends_on = [ time_sleep.wait_10_seconds1 ]
    ip = "10.3.3.0/24"
    root_scope_name = "kadadhic"
    attributes = {
        organization = "Internal"
        location = "Datacenter"
        environment = "Production"
        application = "FinanceApp"
    }
}
resource "secureworkload_label" "label-3" {
    depends_on = [ time_sleep.wait_10_seconds1 ]
    ip = "10.3.5.0/24"
    root_scope_name = "kadadhic"
    attributes = {
        organization = "Internal"
        location = "Datacenter"
        environment = "Production"
        application = "FinanceApp"
    }
}
resource "secureworkload_label" "label-4" {
    depends_on = [ time_sleep.wait_10_seconds1 ]
    ip = "10.3.10.0/24"
    root_scope_name = "kadadhic"
    attributes = {
        organization = "Internal"
        location = "Datacenter"
        environment = "Production"
        application = "FinanceApp"
    }
}

################################################################################################
# Scopes and Workspace
################################################################################################
resource "secureworkload_scope" "financeapp" {
    depends_on = [ time_sleep.wait_10_seconds2 ]
    short_name = "financeapp"
    short_query = file("${path.module}/query_file.json") 
    parent_app_scope_id = data.secureworkload_scope.scope.id
}
resource "secureworkload_workspace" "workspace" {
  depends_on = [ time_sleep.wait_10_seconds2 ]
  app_scope_id         = secureworkload_scope.financeapp.id
  name                 = "financeapp"
  description          = "A testing workspace for Cisco Live Demo"
}

################################################################################################
# Clusters & Filters
################################################################################################
resource "secureworkload_cluster" "app" {
  depends_on = [ time_sleep.wait_10_seconds3 ]
  workspace_id = secureworkload_workspace.workspace.id
  name = "app-tier"
  description = "Testing feature"
  approved = false
  query = <<EOF
                {
                 "type":"subnet",
                 "field": "ip",
                 "value": "10.3.3.0/24"
                 }
            EOF
}
resource "secureworkload_cluster" "db" {
  depends_on = [ time_sleep.wait_10_seconds3 ]
  workspace_id = secureworkload_workspace.workspace.id
  name = "db-tier"
  description = "Testing feature"
  approved = false
  query = <<EOF
                {
                 "type":"subnet",
                 "field": "ip",
                 "value": "10.3.5.0/24"
                 }
            EOF
}

resource "secureworkload_cluster" "web" {
  depends_on = [ time_sleep.wait_10_seconds3 ]
  workspace_id = secureworkload_workspace.workspace.id
  name = "web-tier"
  description = "Testing feature"
  approved = false
  query = <<EOF
                {
                 "type":"subnet",
                 "field": "ip",
                 "value": "10.3.1.0/24"
                 }
            EOF
}
resource "secureworkload_cluster" "bastion" {
  depends_on = [ time_sleep.wait_10_seconds3 ]
  workspace_id = secureworkload_workspace.workspace.id
  name = "bastion"
  description = "Testing feature"
  approved = false
  query = <<EOF
                {
                 "type":"eq",
                 "field": "ip",
                 "value": "10.3.10.2"
                 }
            EOF
}
data "secureworkload_scope" "internal" {
    depends_on = [ time_sleep.wait_10_seconds4 ]
    exact_name = "kadadhic:Internal"
}
resource "secureworkload_filter" "user" {
    depends_on = [ time_sleep.wait_10_seconds4 ]
    app_scope_id = data.secureworkload_scope.internal.id
    name = "external-user"
    query = <<EOF
                {
                 "type":  "subnet",
                 "field": "ip",
                 "value": "151.0.0.0/8"
                 }
            EOF
    primary = true 
    public = false 
}
################################################################################################
# Policy Creation
################################################################################################

resource "secureworkload_policies" "web2app" {
  depends_on = [ time_sleep.wait_10_seconds5 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_cluster.web.id
  provider_filter_id = secureworkload_cluster.app.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "web2app" {
  depends_on = [ time_sleep.wait_10_seconds5 ]
  policy_id = secureworkload_policies.web2app.id
  start_port= 8989
  end_port= 8997
  proto = 6
}
resource "secureworkload_policies" "app2db" {
  depends_on = [ time_sleep.wait_10_seconds5 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_cluster.app.id
  provider_filter_id = secureworkload_cluster.db.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "app2db" {
  depends_on = [ time_sleep.wait_10_seconds5 ]
  policy_id = secureworkload_policies.app2db.id
  start_port= 3306
  end_port= 3306
  proto = 6
}
resource "secureworkload_port" "app2db2" {
  depends_on = [ secureworkload_port.app2db ]
  policy_id = secureworkload_policies.app2db.id
  start_port= 8998
  end_port= 8998
  proto = 6
}

resource "secureworkload_policies" "user2web" {
  depends_on = [ time_sleep.wait_10_seconds6 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_filter.user.id
  provider_filter_id = secureworkload_cluster.web.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "user2web" {
  depends_on = [ time_sleep.wait_10_seconds6 ]
  policy_id = secureworkload_policies.user2web.id
  start_port= 8080
  end_port= 8080
  proto = 6
}
resource "secureworkload_policies" "bastion2web" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_cluster.bastion.id
  provider_filter_id = secureworkload_cluster.web.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "bastion2web" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  policy_id = secureworkload_policies.bastion2web.id
  start_port= 22
  end_port= 22
  proto = 6
}
resource "secureworkload_policies" "bastion2app" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_cluster.bastion.id
  provider_filter_id = secureworkload_cluster.app.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "bastion2app" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  policy_id = secureworkload_policies.bastion2app.id
  start_port= 22
  end_port= 22
  proto = 6
}
resource "secureworkload_policies" "bastion2db" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  workspace_id = secureworkload_workspace.workspace.id
  consumer_filter_id = secureworkload_cluster.bastion.id
  provider_filter_id = secureworkload_cluster.db.id
  policy_action = "ALLOW"
}
resource "secureworkload_port" "bastion2db" {
  depends_on = [ time_sleep.wait_10_seconds7 ]
  policy_id = secureworkload_policies.bastion2db.id
  start_port= 22
  end_port= 22
  proto = 6
}
################################################################################################
# Policy Enforcement
################################################################################################

resource "secureworkload_enforce" "enforced" {
  depends_on = [  secureworkload_port.bastion2app, secureworkload_port.bastion2db,  secureworkload_port.bastion2web]
  workspace_id = secureworkload_workspace.workspace.id
}















################################################################################################
# Wait Code
################################################################################################
resource "time_sleep" "wait_10_seconds1" {
  depends_on = [data.secureworkload_scope.scope]
  create_duration = "10s"
}
resource "time_sleep" "wait_10_seconds2" {
  depends_on = [secureworkload_label.label-1 ,secureworkload_label.label-2, secureworkload_label.label-3, secureworkload_label.label-4 ]
  create_duration = "10s"
}
resource "time_sleep" "wait_10_seconds3" {
  depends_on = [secureworkload_scope.financeapp, secureworkload_workspace.workspace ]
  create_duration = "10s"
}
resource "time_sleep" "wait_10_seconds4" {
  depends_on = [secureworkload_cluster.app, secureworkload_cluster.db, secureworkload_cluster.web, secureworkload_cluster.bastion ]
  create_duration = "10s"
}
resource "time_sleep" "wait_10_seconds5" {
  depends_on = [data.secureworkload_scope.internal, secureworkload_filter.user]
  create_duration = "10s"
}
resource "time_sleep" "wait_10_seconds6" {
  depends_on = [secureworkload_policies.app2db, secureworkload_policies.web2app , secureworkload_port.app2db2, secureworkload_port.app2db, secureworkload_port.web2app  ]
  create_duration = "10s"
}

resource "time_sleep" "wait_10_seconds7" {
  depends_on = [secureworkload_port.user2web, secureworkload_port.web2app,  secureworkload_port.app2db, secureworkload_port.app2db2 ]
  create_duration = "10s"
}



