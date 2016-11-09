# BOSH Deployment Resource

An output only resource (at the moment) that will set `runtime-config` and `cloud-config` on a bosh director.

## Source Configuration

* `type`: *Required.* Must be `runtime-config` or `cloud-config`.
* `target`: *Required.* The address of the BOSH director.

When using BOSH with default authentication:
* `username`: *Required.* The username for the BOSH director.
* `password`: *Required.* The password for the BOSH director.

When using BOSH with [UAA authentication](https://bosh.io/docs/director-users-uaa.html#client-login):
* `client_id`: *Required.* The UAA client ID for the BOSH director.
* `client_secret`: *Required.* The UAA client secret for the BOSH director.

* `ca_cert`: *Optional.* CA certificate used to validate SSL connections to Director and UAA.

#### Resource Specification 

``` yaml
  type: bosh-config
  source:
    target: https://bosh.example.com:25555
    username: admin
    password: admin
    type: runtime-config
```

#### Resource Type Specification

``` yaml
- name: bosh-config
  type: docker-image
  source:
    repository: dellemcdojo/bosh-config-resource
```

## Behaviour

### `put`: Update the runtime or cloud config

#### Parameters

* `manifest`: *Required.* Path to the cloud/runtime config manifest.

* `releases`: *Required (`runtime-config` only).* An array of globs that should point to where the
  releases used in the deployment can be found.

``` yaml
- put: staging
  params:
    manifest: path/to/manifest.yml
    releases:
    - path/to/releases-*.tgz
    - other/path/to/releases-*.tgz
```

### `get`: NOT SUPPORTED

Using `get` for this resource type will result in an error.  If you have a reasonable use case for `get` of a config, please let us know in a github issue.