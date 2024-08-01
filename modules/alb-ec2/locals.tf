locals {
  name = "${var.name}-${var.environment}"
  env_to_account_aliases = {
    lab = "lab"
    dev = "npr"
    qa  = "npr"
    prd = "prd"
    inf = "inf"
  }
  account_alias = local.env_to_account_aliases[var.environment]
}
