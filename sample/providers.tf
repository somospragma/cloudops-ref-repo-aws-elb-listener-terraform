############################################################################
# Provider Configuration
############################################################################

provider "aws" {
  region = var.region
  alias  = "principal"

  default_tags {
    tags = var.common_tags
  }
}
