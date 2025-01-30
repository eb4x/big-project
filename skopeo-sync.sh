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
#  [quay.io/community-operator-pipeline-prod/project-quay]="
#    4241a9901e4a3d5915a0b4af2ac40b4436656f16636e8a634ca3a2ca674afbff
#    03faf42b41397861e397d5c9bfd7625afc796c524335d82d50e48a714779f5d7
#  "
#  [quay.io/community-operator-pipeline-prod/keycloak-operator]="
#    fa9c1f859f88f8dce5ba73522ce6fe33e9e1036797058ca8a8a7c3b3e9fb0fec
#  "
#  [quay.io/community-operator-pipeline-prod/community-kubevirt-hyperconverged]="
#    e5e0c3b3a25c13ea916d70fa6f6ddc20f2c730bd9909aa2654672280c27afda2
#  "
#  [registry.ci.openshift.org/origin/4.17-okd-scos-2024-06-24-072329]="
#    654a24b31d2501aa04ac9e36e0b7aa4afa4c22059a5caf855135d09170c67809
#  "
#  [registry.redhat.io/openshift4/ose-kube-rbac-proxy-rhel9]="
#    248dfbc9bf39226861e182d615d556d5af51c7a23691c91c157c4ab0926a2413
#  "
#  [registry.redhat.io/openshift4/kubernetes-nmstate-operator-bundle]="
#    9e3f46adb0c4a5a4d9585d01b68321f6900f9ea24e450ebf0ed764ef2134562c
#  "
#  [registry.redhat.io/openshift4/kubernetes-nmstate-rhel9-operator]="
#    fb5f34e7b2e799bca25f99f14d0231074162bcecedbe916c7a66de0a3e7a3af4
#  "
)

for image in "${!image_digests[@]}"; do

  #echo "${image_digests[$image]//[0-9]+\.[0-9]+/}"

  for digest in ${image_digests[$image]%%#*}; do
    skopeo copy --all --preserve-digests "docker://${image}@sha256:${digest}" \
      "docker://${mirror_registry}/mirrors/${image}:${digest:0:8}"
  done
done
