#!/bin/bash

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }
hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

args=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--cert-pem-file)
    cert_pem_file="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--cert-password)
    cert_password="$2"
    shift # past argument
    shift # past value
    ;;
    --app-base)
    app_base="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

if [ -z "$app_base" ] ; then
    echo '--app-base not set'
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

app_doc=$1

turtle+="@prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="_:install-arg a <http://linkeddatahub.com/ns/apps/templates#Install> .\n"
turtle+="_:install-arg ldt:paramName \"install\" .\n"
turtle+="_:install-arg rdf:value <${app_base}> .\n"

# make Jena scripts available
export PATH=$PATH:$JENA_HOME/bin

# convert Turtle to N-Triples, POST N-Triples to the server

echo -e "$turtle" | turtle | curl -v -k -E "${cert_pem_file}":"${cert_password}" -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${app_doc} -s -D -