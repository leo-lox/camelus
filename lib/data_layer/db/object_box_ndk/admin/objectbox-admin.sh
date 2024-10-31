#!/bin/sh

# ObjectBox Admin front-end shell script for Docker container version.
# For more information visit https://objectbox.io
# Detailed documentation available at https://docs.objectbox.io/data-browser 

usage()
{
    [ $# -eq 0 ] || echo "$1" 1>&2  
    cat <<EOF 1>&2 

usage: $0 [options] [<database-directory>]

<database-directory> ( defaults to ./objectbox ) should contain an objectbox "data.mdb" file.

Available (optional) options:
  [--port <port-number>] Mapped bind port to localhost (defaults to 8081)
 
EOF
    exit 1
}

port=8081

while [ $# -ne 0 ]; do
    case $1 in
        --help|-h)
            usage
            ;;
        --port)
            [ $# -ge 2 ] || usage
            port=$2
            shift 2
            ;;
        -*|--*)
            usage
            ;;
        *) 
            break
            ;;
    esac
done

[ $# -le 1 ] || usage

db=${1:-.}

echo "Objectbox Admin (Docker-Version)"
echo ""

if [ ! -f "$db/data.mdb" ]; then
    echo "NOTE: No database found at location '$db', trying default location ('$db/objectbox') .." 
    db=$db/objectbox
fi 

[ -f "$db/data.mdb" ] || usage "Oops.. no database file found at '$db/data.mdb'. Please check the path to the database directory."

# make db an absolute path and resolve symbolic links
db=$( cd "$db" ; pwd -P )

echo "Found database at local location '${db}'."
echo "Open http://127.0.0.1:${port} in a browser."
echo "Once done, hit CTRL+C to stop 'ObjectBox Admin' Docker container."
echo "=================================================================="

docker run --rm -it -v "$db:/db" -u $(id -u):$(id -g) -p ${port}:8081 objectboxio/admin:latest || usage
