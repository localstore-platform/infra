# AWS Resource Group for cost management
# Groups all resources tagged with Project: Local Store Platform

resource "aws_resourcegroups_group" "localstore" {
  name        = "localstore-${var.environment}"
  description = "LocalStore Platform resources for ${var.environment} environment"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Project"
          Values = ["Local Store Platform"]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }

  tags = {
    Name = "localstore-${var.environment}-resource-group"
  }
}
