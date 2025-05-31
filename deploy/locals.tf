locals {
  custom_data_ad_ds    = base64encode(file("${path.module}/scripts/ad_setup.ps1"))
}
