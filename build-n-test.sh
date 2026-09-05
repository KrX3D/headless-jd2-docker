#!/bin/bash
set -e

cd $(dirname $0)

images=('alpine' 'debian')

if [ "$(docker version --format '{{.Server.Experimental}}')" = 'true' ]; then
    export DOCKER_BUILDKIT=1
fi

# entrypoint.sh does real work as root (user/group creation, chown, writing
# the credentials file) before the app starts; dgoss's default 0.2s
# post-start sleep can be too short for that plus container startup
# overhead, causing spurious failures.
export GOSS_SLEEP="${GOSS_SLEEP:-2}"


for image in "${images[@]}"; do
    tag="jd2dev:${image}"
    
    echo "Building $tag"
    docker build -t $tag -f $image.Dockerfile .

    echo "Testing image"
    GOSS_FILES_PATH=./tests/default dgoss run $tag

    echo "Testing again with UID and GID"
    GOSS_FILES_PATH=./tests/uid-test dgoss run -e UID=1001 -e GID=101 $tag

    echo "Testing again with EMAIL and PASSWORD"
    GOSS_FILES_PATH=./tests/credentials-test dgoss run -e EMAIL=mymail@example.com -e PASSWORD=mypassword $tag
done


