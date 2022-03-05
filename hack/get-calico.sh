#!/bin/bash

set -e

CSPLIT_BINARY="csplit"

# On MacOS, we need to use the homebrew coreutils (gnu-utils) version of
# csplit, named gcsplit by default.
if [[ "${OSTYPE}" == 'darwin'* ]]; then
    CSPLIT_BINARY="gcsplit"
fi

PATH="${PATH}:${GOPATH}/bin"

DIR="static/manifests/calico"

mkdir -p "${DIR}"

curl -O 'https://docs.projectcalico.org/manifests/calico.yaml'

"${CSPLIT_BINARY}" --digits=2 --quiet --prefix="${DIR}/" calico.yaml "/---/" "{*}"

for f in "${DIR}/"*; do
    # skip directories
    [ -d "${f}" ] && continue

    filename="$(yq eval '.metadata.name' "${f}")"
    kind="$(yq eval '.kind' "${f}")"

    if [[ "${filename}" == "null" || "${kind}" == "null" ]]; then
        rm -f "${f}"
        continue
    fi
    echo "Processing ${kind} ${filename} ${f}"
    mkdir -p "${DIR}/${kind}"
    mv "${f}" "${DIR}/${kind}/${filename}.yaml"
done


# cleanup
rm -f calico.yaml
