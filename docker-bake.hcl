# Builds the base image and the ecosystem images on top of it, tagged with TAG for local runs and tests,
# or pushed untagged by digest when PUSH_BY_DIGEST is set, the release workflow then tags each platform's digests

variable "REGISTRY" {
  default = "ghcr.io/robgee86"
}

variable "TAG" {
  default = "local"
}

variable "PUSH_BY_DIGEST" {
  type    = bool
  default = false
}

variable "ECOSYSTEMS" {
  default = ["go", "node", "python", "gradle", "cocoapods", "swift"]
}

function "tags" {
  params = [name]
  result = PUSH_BY_DIGEST ? [] : ["${REGISTRY}/${name}:${TAG}"]
}

function "output" {
  params = [name]
  result = PUSH_BY_DIGEST ? ["type=image,name=${REGISTRY}/${name},push-by-digest=true,name-canonical=true,push=true"] : []
}

group "default" {
  targets = ["base", "ecosystem"]
}

target "base" {
  context = "images/base"
  tags    = tags("licensed-action")
  output  = output("licensed-action")
}

# Each ecosystem image builds on the base image of the same build, never on a published one
target "ecosystem" {
  name     = ecosystem
  matrix   = { ecosystem = ECOSYSTEMS }
  context  = "images/${ecosystem}"
  contexts = { base = "target:base" }
  tags     = tags("licensed-${ecosystem}-action")
  output   = output("licensed-${ecosystem}-action")
}
