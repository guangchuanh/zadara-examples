variable "k8s_name" {
  type        = string
  description = "Display name for the k8s cluster. (Only alphanumeric characters and hyphen)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.k8s_name))
    error_message = "The value for 'k8s_name' must contain only alphanumeric characters and hyphens."
  }
}

variable "k8s_version" {
  type        = string
  description = "Version of k8s to use"
  default     = "1.31.2"
}

module "k8s" {
  #source = "../../../terraform-zcompute-k8s"
  source = "github.com/zadarastorage/terraform-zcompute-k8s?ref=main"
  # It's recommended to change `main` to a specific release version to prevent unexpected changes

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  tags = var.tags

  cluster_name    = var.k8s_name
  cluster_version = var.k8s_version
  cluster_helm = {
    cert-manager = {
      order           = 31
      wait            = true
      repository_name = "cert-manager"
      repository_url  = "https://charts.jetstack.io"
      chart           = "cert-manager"
      version         = "v1.15.3"
      namespace       = "cert-manager"
      config          = { crds = { enabled = true } }
    }
    cert-manager-clusterissuers = {
      order           = 32
      wait            = false
      repository_name = "eric-zadara"
      repository_url  = "https://eric-zadara.github.io/helm_charts"
      chart           = "cert-manager-clusterissuers"
      version         = "0.0.1"
      namespace       = "cert-manager"
      config          = { selfSigned = { enabled = true } }
    }
    cloudnative-pg = {
      order           = 31
      wait            = true
      repository_name = "cloudnative-pg"
      repository_url  = "https://cloudnative-pg.io/charts/"
      chart           = "cloudnative-pg"
      version         = "0.22.0"
      namespace       = "cloudnative-pg"
      config          = null
    }
    ollama = {
      order           = 34
      wait            = false
      repository_name = "ollama-helm"
      repository_url  = "https://otwld.github.io/ollama-helm/"
      chart           = "ollama"
      version         = "1.12.0"
      namespace       = "ollama"
      config = {
        ollama = {
          gpu    = { enabled = true, type = "nvidia" }
          # gpu    = { enabled = false, type = "nvidia" }
          models = { pull = ["llama3.1:8b-instruct-q8_0"], run = ["llama3.1:8b-instruct-q8_0"] }
          # models = { pull = [""], run = [""] }
        }
        replicaCount = 1
        extraEnv = [{
          name  = "OLLAMA_KEEP_ALIVE"
          value = "-1"
        }]
        resources = {
          # requests = { cpu = "4", memory = "15Gi", "nvidia.com/gpu" = "8" }
          # limits   = { cpu = "8", memory = "20Gi", "nvidia.com/gpu" = "8" }
          requests = { cpu = "4", memory = "15Gi" }
          limits   = { cpu = "8", memory = "20Gi" }
        }
        persistentVolume = { enabled = true, size = "200Gi" }
        # runtimeClassName = "nvidia"
        runtimeClassName = ""
        # affinity = {
        #   nodeAffinity = {
        #     requiredDuringSchedulingIgnoredDuringExecution = {
        #       nodeSelectorTerms = [
        #         {
        #           matchExpressions = [{
        #             key      = "nvidia.com/device-plugin.config"
        #             operator = "In"
        #             values   = ["tesla-25b6", "tesla-2235", "tesla-27b8", "tesla-26b9"]
        #           }]
        #         }
        #       ]
        #     }
        #   }
        # }
      }
    }
    onyx = {
      order           = 35
      wait            = false
      # repository_name = "onyx-dot-app"
      # repository_url  = "https://github.com/onyx-dot-app/onyx/tree/main/deployment/helm/charts"
      # version         = "0.2.1"
      repository_name = "guangchuanh"
      repository_url  = "https://guangchuanh.github.io/helm-charts"
      #repository_name = "zadarastorage"
      #repository_url  = "https://zadarastorage.github.io/helm-charts"
      chart           = "onyx"
      version         = "0.0.13"
      namespace       = "onyx"
      config = {
        inference = {
          # tolerations      = [{ effect = "NoSchedule", operator = "Exists", key = "nvidia.com/gpu" }]
          tolerations      = []
          # runtimeClassName = "nvidia"
          runtimeClassName = ""
          # affinity = { nodeAffinity = { requiredDuringSchedulingIgnoredDuringExecution = { nodeSelectorTerms = [
          #   { matchExpressions = [{
          #     key      = "nvidia.com/device-plugin.config"
          #     operator = "In"
          #     values   = ["tesla-25b6", "tesla-2235", "tesla-27b8", "tesla-26b9"]
          #     }]
          # }] } } }
          resources = {
            requests = {}
            limits = {}
          }
          # resources = {
          #   requests = { "nvidia.com/gpu" = "4" }
          #   limits   = { "nvidia.com/gpu" = "4" }
          # }
        }
        index = {
          # tolerations      = [{ effect = "NoSchedule", operator = "Exists", key = "nvidia.com/gpu" }]
          tolerations      = []
          # runtimeClassName = "nvidia"
          runtimeClassName = ""
          # affinity = { nodeAffinity = { requiredDuringSchedulingIgnoredDuringExecution = { nodeSelectorTerms = [
          #   { matchExpressions = [{
          #     key      = "nvidia.com/device-plugin.config"
          #     operator = "In"
          #     values   = ["tesla-25b6", "tesla-2235", "tesla-27b8", "tesla-26b9"]
          #     }]
          # }] } } }
          # resources = {
          #   requests = { "nvidia.com/gpu" = "4" }
          #   limits   = { "nvidia.com/gpu" = "4" }
          # }
          resources = {
            requests = {}
            limits = {}
          }
        }
        ingress = {
          enabled = true
          annotations = {
            "cert-manager.io/cluster-issuer"                   = "selfsigned"
            "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
          }
          tls = true
        }
        cnpg = {
          cluster = { instances = 1, monitoring = { enabled = false } }
          pooler  = { instances = 1, monitoring = { enabled = false } }
        }
      }
    }
  }

  node_group_defaults = {
    root_volume_size     = 64
    cluster_flavor       = "k3s-ubuntu"
    iam_instance_profile = module.iam-instance-profile.instance_profile_name
    security_group_rules = {
      egress_ipv4 = {
        description = "Allow all outbound ipv4 traffic"
        protocol    = "all"
        from_port   = 0
        to_port     = 65535
        type        = "egress"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
    key_name = aws_key_pair.this.key_name
    cloudinit_config = [
      {
        order        = 5
        filename     = "cloud-config-registry.yaml"
        content_type = "text/cloud-config"
        content = join("\n", ["#cloud-config", yamlencode({ write_files = [
          { path = "/etc/rancher/k3s/registries.yaml", owner = "root:root", permissions = "0640", encoding = "b64", content = base64encode(yamlencode({
            configs = {}
            mirrors = {
              "*" = {}
              "docker.io" = {
                endpoint = ["https://mirror.gcr.io"]
              }
            }
          })) },
        ] })])
      },
    ]
  }

  node_groups = {
    control = {
      role         = "control"
      min_size     = 3
      max_size     = 3
      desired_size = 1
    }
    worker = {
      role          = "worker"
      min_size      = 1
      max_size      = 3
      desired_size  = 1
      instance_type = "z8.3xlarge"
    }
    # gpu = {
    #   role             = "worker"
    #   min_size         = 0
    #   max_size         = 3
    #   desired_size     = 1
    #   root_volume_size = 200
    #   instance_type    = "z8.3xlarge"
    #   # instance_type    = "A02.4xLarge" # TODO Adjust to formalized instance_type name
    #   # k8s_taints = {
    #   #   "nvidia.com/gpu" = "true:NoSchedule"
    #   # }
    #   k8s_labels = {
    #     "tesla-a16"                       = "true"
    #     "nvidia.com/gpu"                  = "true"
    #     "nvidia.com/device-plugin.config" = "tesla-25b6"
    #     "nvidia.com/gpu.deploy.driver"    = "false"
    #   }
    #   tags = {
    #     "k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu" = "17"
    #     "nvidia.com/device-plugin.config"                                  = "tesla-25b6"
    #   }
    #   # cloudinit_config = [
    #   #   {
    #   #     order        = 11
    #   #     filename     = "setup-gpu.sh"
    #   #     content_type = "text/x-shellscript"
    #   #     content      = file("${path.module}/files/setup-gpu.sh")
    #   #   }
    #   # ]
    # }
  }
}
