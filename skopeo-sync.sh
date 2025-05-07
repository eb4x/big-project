#!/usr/bin/env bash

mirror_registry=${1:-mirror-registry.openshift-utv.uio.no:8443}

for imagelist in imagelists/*.yaml; do
  if [[ "$imagelist" == "imagelists/openstack-all.yaml" ]]; then
    continue
  fi

  skopeo sync --dest-tls-verify=false --keep-going --all --preserve-digests --src yaml $imagelist --scoped --dest docker ${mirror_registry}/mirrors &
done

# Sometimes there aren't any tags, just sha256 digests,
# and mirror-registry won't store images on digests alone, so we
# construct a tag from the first 8 characters of the digest.

declare -A image_digests=(
#  [registry.redhat.io/openshift4/kubernetes-nmstate-operator-bundle]="
#    9e3f46adb0c4a5a4d9585d01b68321f6900f9ea24e450ebf0ed764ef2134562c
#  "
#  [registry.redhat.io/openshift4/kubernetes-nmstate-rhel9-operator]="
#    fb5f34e7b2e799bca25f99f14d0231074162bcecedbe916c7a66de0a3e7a3af4
#  "
)

for image in "${!image_digests[@]}"; do
  for digest in ${image_digests[$image]%%#*}; do
    skopeo copy --all --preserve-digests "docker://${image}@sha256:${digest}" \
      "docker://${mirror_registry}/mirrors/${image}:${digest:0:8}"
  done
done
