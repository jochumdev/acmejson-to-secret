#!/usr/bin/env bash

set -e # abort on errors
set -u # abort on unset variables
set -f # disable globbing

STORE="${ACME_STORE}"
RESOLVER="${ACME_RESOLVER}"

IFS=";"
DOMAINS=(${ACME_DOMAINS}) # Make a BASH array from ACME_DOMAINS split by ";"

if [[ ! -f "${STORE}" ]]; then
    echo "acme.json file '${STORE}' not found"
    exit 1
fi

# Do all operations in /tmp
pushd /tmp

for d in ${DOMAINS[@]}; do
    IFS=":"
    dnn=($d) # Split ${d} by ":"
    domain=${dnn[0]};
    
    second_part=${dnn[1]}
    IFS="/"
    nn=($second_part) # Split the second part of DOMAIN by "/"
    IFS=" "
    namespace=${nn[0]}
    name=${nn[1]}

    echo "Domain '${domain}' to '${namespace}/${name}'"

    # Do the actual export
    traefik-acme "${domain}" -r "${RESOLVER}" -a "${STORE}"
    
    if [[ ! -f "cert.pem" ]] || [[ ! -f "key.pem" ]]; then
        echo "Failed to export cert.pem or key.pem"
        rm -f cert.pem
        rm -f key.pem
        continue
    fi

    # Move so kube has the right names for them.
    mv cert.pem tls.crt
    mv key.pem tls.key

    # Download existing tls.crt and compare it.
    mkdir check; cd check
    kubectl get secret --namespace "${namespace}" "${name}" -o json -o=jsonpath="{.data.tls\.crt}" | base64 -d > tls.crt
    cd ..

    # Delete and create the tls secret.
    if cmp --silent -- "tls.crt" "check/tls.crt"; then
        echo "${name}: No update needed."
    else
        kubectl delete secret "${name}" --namespace "${namespace}" --ignore-not-found
        kubectl create secret generic "${name}" \
            --namespace "${namespace}" \
            --from-file="tls.crt" \
            --from-file="tls.key"
    fi

    rm -rf check
    rm -f tls.crt
    rm -f tls.key
done

# Go back to the original directory.
popd