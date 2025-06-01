## Definiendo providers.tf

En este archivo definimos que proveedores vamos a necesitar.
Los providers contienen la configuración, recursos y datos necesarios para comunicarse con Azure (AWS, GCP..)
En este ejemplo usaremos: 
  -azurerm (Azure Resource Manager) que usaremos para la creación de los grupos de recursos 

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"         # Donde encontrar el provider azurerm dentro de registry.terraform
      version = "~> 4.26.0"                 # Defino una versión de hace 2 meses para evitar confictos con versiones beta
    }

provider "azurerm" {                        #¿Que necesita el provider azurerm para poder crear/modificar/eliminar recursos?
  features {}

  subscription_id = var.subscription_id     #El ID de la suscripción que será una variable asociada al archivo secrets.tfvars
}
