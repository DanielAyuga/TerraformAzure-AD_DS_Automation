data "azurerm_client_config" "current" {}

# Data del SAS token
data "azurerm_storage_account_sas" "storagesas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true
  start             = "2025-06-04T05:00:00Z" 
  expiry            = "2025-06-08T00:00:00Z"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob = true
    file = false
    table= false
    queue= false
  }

    permissions {
    read    = true
    add     = false
    create  = false
    write   = false
    delete  = false
    list    = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
    
}
