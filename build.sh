docker stop $(docker ps -a -q)
docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)

docker build --network=host -t elux .
