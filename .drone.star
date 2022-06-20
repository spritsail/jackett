repo = "spritsail/jackett"
architectures = ["amd64", "arm64"]
publish_branches = ["master"]

def main(ctx):
  builds = []
  depends_on = []

  for arch in architectures:
    key = "build-%s" % arch
    builds.append(step(arch, key))
    depends_on.append(key)

  if ctx.build.branch in publish_branches:
    builds.append(publish(depends_on))
    builds.append(update_readme())

  return builds

def step(arch, key):
  return {
    "kind": "pipeline",
    "name": key,
    "platform": {
      "os": "linux",
      "arch": arch,
    },
    "steps": [
      {
        "name": "build",
        "pull": "always",
        "image": "spritsail/docker-build",
      },
      {
        "name": "test",
        "pull": "always",
        "image": "spritsail/docker-test",
        "settings": {
          "curl": ":9117",
          "curl_opts": "-c /dev/null"
        }
      },
      {
        "name": "publish",
        "pull": "always",
        "image": "spritsail/docker-publish",
        "settings": {
          "registry": {"from_secret": "registry_url"},
          "login": {"from_secret": "registry_login"},
        },
        "when": {
          "branch": publish_branches,
          "event": ["push"],
        },
      },
    ],
  }

def publish(depends_on):
  return {
    "kind": "pipeline",
    "name": "publish-manifest",
    "depends_on": depends_on,
    "platform": {
      "os": "linux",
    },
    "steps": [
      {
        "name": "publish",
        "image": "spritsail/docker-multiarch-publish",
        "pull": "always",
        "settings": {
          "tags": [
            "latest",
            "%label io.spritsail.version.jackett | %auto"
          ],
          "src_registry": {"from_secret": "registry_url"},
          "src_login": {"from_secret": "registry_login"},
          "dest_repo": repo,
          "dest_login": {"from_secret": "docker_login"},
        },
        "when": {
          "branch": publish_branches,
          "event": ["push"],
        },
      },
    ],
  }

def update_readme():
  return {
    "kind": "pipeline",
    "name": "update-readme",
    "depends_on": [
      "publish-manifest",
    ],
    "steps": [
      {
        "name": "dockerhub-readme",
        "pull": "always",
        "image": "jlesage/drone-push-readme",
        "settings": {
          "repo": repo,
          "username": {"from_secret": "docker_username"},
          "password": {"from_secret": "docker_password"},
        },
        "when": {
          "branch": publish_branches,
          "event": ["push"],
        },
      },
    ],
  }

# vim: ft=python sw=2
