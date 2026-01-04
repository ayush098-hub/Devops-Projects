docker volume create --name nexus-data
docker run -d -p 8082:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
