Building Docker Doodles
-----------------------

Building can be done with the original `docker build`, or with the new *BuildKit* application.  The new
experimental 'buildx' command, which is in nightly builds as well as in the Docker Engine 19.03 release, provides a new, albeit familiar front end to BuildKit similar to the original `docker build` command. BuildKit has some great new added features such as increased performance, and the ability to easily build cross platform.

To build for your own platform with the original docker build command, use:

    cd <doodle> && docker build -t <username>/doodle:<doodle> ./

To build cross platform, use the `Dockerfile.cross` file, either with *BuildKit* directly, or with *buildx*.
With buildx, you'll first need to create a cross platform `builder` instance with:

    docker buildx create --use

You only need to create one builder instance, and should not need to create new ones with subsequent builds.  To create and push the multi-arch image to Docker Hub, use the command:

```bash
cd <doodle> && docker buildx build -f Dockerfile.cross \
  --platform linux/amd64,linux/arm64,linux/arm/v8,linux/s390x,linux/ppc64le,windows/amd64 \
  -t <username>/doodle:<doodle> --push .
```

This will build the Doodle for these architectures:
* linux/amd64 (64-bit Linux native)
* linux/arm64 (suitable for Amazon EC2 A1 instances)
* linux/arm/v8 (suitable for Raspberry Pi)
* linux/s390x (for IBM mainframes)
* linux/ppc64le (for IBM POWER8 Little Endian)
* windows/amd64 (64-bit Windows native)



# LinkEdIn's Docker class


The class is a really basic introduction into Docker containers. 
https://www.linkedin.com/learning/learning-docker-2018

It covers

- How to install Docker on Windows, Mac, and Linux
- The Docker build and deploy flow
- Managing containers
- Connecting containers together with ports, mounts, and volumes
- Docker registries and building images
- Under the Hood
- Orchestration with Kubernetes in AWS and GCP

The excercise files are included here:

```
Dockerfile-1.txt
Dockerfile-2.txt
Dockerfile-3.txt
FAQ.txt
reformat.sh
```

# Using Docker

https://gist.github.com/PurpleBooth/635a35ed0cffb074014e


## Chapter 2 Docker Networking

**session 1:** 
```bash
    docker run -it --rm **-p 45678:45678 -p 45679:45679** --name nc_server ubuntu:14.04 bash
    nc -lp 45678 | nc -lp 45679
```

**session 2:**
```bash
    nc localhost 45678 # on local MacOS OR
    docker run -it --rm ubuntu:14.04 bash
    nc host.docker.internal 45678
```

**session 3:**
```bash
    nc localhost 45679 # on local MacOS OR
    docker run -it --rm ubuntu:14.04 bash
    nc host.docker.internal 45679
```

Without exposing the ports on the nc_server container, any attempt to run nc against the ports returns $?=1

You can also leave the destination port off and docker will assign one automatically.

**session 1:**
```bash
    docker run -it --rm -p 45678 -p 45679 --name nc_server ubuntu:14.04 bash
    nc -lp 45678 | nc -lp 45679
```

in session 2, determine the port docker assigned

**session 2:**
```bash
    docker port nc_server
    [docker prints the ports assigned...pick the one for port 45678]
    docker run -it --rm ubuntu:14.04 bash
    nc host.docker.internal [docker-assigned port]
```

**session 3:**
```bash
    docker port nc_server
    [docker prints the ports assigned...pick the one for port 45679]
    docker run -it --rm ubuntu:14.04 bash
    nc host.docker.internal [docker-assigned port]
```

Docker can also use udp.

**session 1:**
```bash
    docker run -it --rm -p 45678/udp --name nc_server ubuntu:14.04 bash
    nc -ulp 45678
```

**session 2:**
```bash
    docker port nc_server
    [docker prints the ports assigned...pick the one for port 45678]
    docker run -it --rm ubuntu:14.04 bash
    nc -u host.docker.internal [docker-assigned port]
    #this will appear on session 1
```

## Chapter 2 Docker Virtual Networks

**session 1: on test and stage networks**
```bash
    docker network ls          # show the existing networks
    docker network create test # create a test network
    docker run -it --rm --net test --name catserver ubuntu:14.04 bash

    ping catserver
    [icmp messages]
    ping dogserver # once it's setup
    [icmp messages]
    ping bobcatserver # once it's setup
```

**session 2: only on test network**
```bash
    docker run -it --rm --net test --name dogserver ubuntu:14.04 bash

    ping catserver
    [icmp messages]
    ping dogserver
```

**session 3: only on stage network**
```bash
    docker network create stage
    docker network connect catserver stage

    docker run -it --rm --net test --name bobcatserver ubuntu:14.04 bash

    ping catserver
    [icmp messages]
    ping dogserver
    [can't connect]
```

## Chapter 2 Docker Legacy Network Links

Older legacy `link` allows for one container to join with another and see all the environment variables of the other server, **but not vice-versa**.

**session 1: catserver**

```bash
docker run -it --rm --name catserver -e SECRET=peekaboo ubuntu:14.04 bash
nc -lp 1234 # inside the container
[#output from dogserver]
^C
nc dogserver 1234
nc: getaddressinfo: name or service not known
^C
env | grep SECRET
SECRET=peekaboo
```

**session 2: dogserver linked to catserver**

```bash
docker run -it --rm  --name dogserver --link catserver -e SECRET2=iseeyou ubuntu:14.04 bash
nc catserver 1234
#output from dogserver
^C
nc -lp 1234
^C
env | grep SECRET
SECRET=iseeyou
CATSERVER_ENV_SECRET=peekaboo
```

In the above example, container dogserver can connect to catserver and see the SECRET environment variable in the catserver's container, but dogserver cannot connect to catserver and can't see the environment SECRET2. Also, this makes the deployment **order dependent**. In the above example, catserver must exist before dogserver can link to it.

## Chapter 2 Container Images

```bash
docker images
docker commit <sha> <repo>:<tag>  # if <tag> is absent, it defaults to **latest**
docker pull                       # pulls images from repo [default is dockerhub.io]
docker push                       # publishes images to repo
docker rmi <image-name:tag>       # remove specific image with tag
docker rmi <image-id>             # removes image based on IMAGE-ID
```

repo format: **registry.example.com:port/org/image-name:version-tag**

A bit of shell hackery to remove all images:

```bash
docker rmi `docker images --format={{.ID}}`
```

## Chapter 2 Container Volumes

```bash
mkdir example
touch -t 202001010000 example/x.tmp
ls -l example/x.tmp
-rw-r--r--  1 user  user  0 Jan  1  2020 example/x.tmp

docker run -it --rm --name shared -v `pwd`/example:/shared-folder ubuntu:14.04 bash
[inside the container]
ls -l shared-folder/
total 0
-rw-r--r-- 1 root root 0 Jan  1  2020 x.tmp
```

Sharing a file is the same as sharing a directory, but the file must exist **before** the container is started or Docker will assume it's a directory and create it.

**session 1: create an ephemeral volume inside a container** 

```bash
docker run -it --rm -v shared-folder -name shared-container ubuntu bash # inside container not on host
[inside the container]
date > /shared-data/data
cat /shared-data/data
[UTC date and time]
# exit after session 2 started
```

**session 2: attaches to ephemeral container**

```bash
docker run -it --rm --volumes-from shared-container -name shared-container2 ubuntu bash
[inside the container]
ls /shared-folder
data
echo more > /shared-folder/more-data
```

**session 3: attaches to ephemeral container**

```bash
docker run -it --rm --volumes-from shared-container2 -name shared-container3 ubuntu bash
[inside the container]
ls /shared-folder
data more-data
```

When the last container that access the volume exists, the volume goes away.

## Chapter 2 Docker Registries

```bash
docker search <image> # or search https://hub.docker.com
docker login # asks for username + password to get access token
docker pull debian
  Using default tag: latest
  latest: Pulling from library/debian
  955615a668ce: Pull complete
  Digest: sha256:08db48d59c0a91afb802ebafc921be3154e200c452e4d0b19634b426b03e0e25
  Status: Downloaded newer image for debian:latest
  docker.io/library/debian:latest
docker tag debian my-account/my-new-image:new-version
docker push 
```



## Chapter 3 Dockerfiles

Build images with a Dockerfile using the `docker build` command:

```bash
docker build -t my-container-name .   # "." = directory loc of Dockerfile
```

Each line in Dockerfile runs and creates a layer in the container. If line 1 downloads a large image, line 2 extracts some files from it, and line 3 deletes the large file, each of these steps adds to the resulting image size.  If you can chain them together, it only creates the extracted files. Also, if you run something on line 1, it will finish, create a layer in the container, then docker will execute the next line. *It will not still be running after the line finishes. Dockerfiles are NOT shell scripts.*  However, environment variables are carried forward after they are defined in an **ENV** command.

Each line in a Dockerfile is cached. If you build a container, change something in towards the end if the Dockerfile, `docker build` won't rerun all the previously run lines to create a new version of the container, only what was changed.  *It's best to put the stuff that's changed the most at the END of the Dockerfile.*

Simple Dockerfile:

```dockerfile
FROM busybox
RUN echo "building simple docker image"
CMD echo "Hello Container"
```

A more interesting build creating a notepad. Note the CMD is using *exec format*:

```dockerfile
FROM debian
RUN apt-get -y update
RUN apt-get -y install nano
CMD ["nano", "/tmp/notes"]
```

Build and run it interactively

```bash
docker built -t example/test .
docker run -it --rm example/test
```

Now modify the Dockerfile to build upon this image. Line 2 adds or copies the file notes.txt in the build directory (e.g. ".") into the container. 

NOTE: *the file notes.txt must exist before running the docker build command or else this step will fail*

```dockerfile
FROM example/test
ADD notes.txt /notes.txt
CMD "nano" "/notes.txt"
```

---

## Dockerfile Statements

- **FROM**
first statement in Dockerfile; identifies source 
- **MAINTAINER** 
  documentation on who to contact
    format: `firstname lastname <email@example.com>`
- **RUN**
runs application or shell command
- **ADD**
  adds local file, contents of gz archive file, or content from URL into container
    ADD run.sh /run.sh
    ADD project.tar.gz /install/
    ADD https://project.example.com/download/1.0/project.rpm /project/
- **ENV**
  sets environment variable during build and inside resulting container
    ENV DB_HOST=db.production.example.com
- **CMD**
sets default command to run
if `docker run` specifies command, that replaces what's specified in CMD
CMD most likely is the use-case
- **ENTRYPOINT**
  specifies *starting point* of CMD to run
  if `docker run` specifies a value, that's `appended` to existing entry point
  if you want container to look like a command, use ENTRYPOINT
  If CMD and ENTRYPOINT are used together,  result is contatenated together
  ENTRYPOINT, CMD, and RUN take args in both shell form (actually runs in a shell)
    nano notes.txt
  and in exec form (runs directly not from a shell)
    ["/bin/nano", "notes.txt"]
- **EXPOSE**
  maps ports into a container
    EXPOSE 8080
- **VOLUMES**
defines either shared volumes (2 arguments) or ephemeral volumes (1 argument)
    VOLUME ["/host/path" "/container/path/"]
    VOLUME ["/shared-data"]
NOTE: avoid using shared folders with host since it will only work on single system
- **WORKDIR**
sets directory in the container to start, like type `cd <directory>`
- **USER**
  sets username for all subsequent command to run; affects permissions; must exist on host 
  running container
    USER mysql
    USER 1000

see the [official dockerfile reference page](https://docs.docker.com/engine/reference/builder) 
for more info. There are a lot more commands.

## Multi-Project Builds in Dockerfiles

Feature added in Docker Engine 17.05 to allow for building multi-stage files so that a Dockerfile
can contain multiple build contexts which can be build separately via the **--target** argument

    docker build --target builder -t test/example .

This allows for carrying artifacts from a prior container build and copying them into the next stage.
This makes container sizes smaller and puts the two sequences in a single Dockerfile.

```dockerfile
    FROM ubuntu:16.04 as builder
    RUN apt-get update
    RUN apt-get -y install curl
    RUN curl https://google.com | wc -c > google_size

    FROM alpine
    COPY --from=builder /google_size /google_size
    ENTRYPOINT echo -n "google is this big: "; cat google_size
```

## Avoid Golden Images (a horror story)

- include everything (e.g. any installers neede) needed to build an 
  application into the Dockerfile. 
- build everything canonically from scratch
- tag builds with git commit hash that built the image
- use small base images (e.g. alpine)
- for shared public images, build them from Dockerfiles **always**
- don't leave passwords or access keys hidden in deep layers of images

## Docker, the program (under the hood)

### What Kernels Do

- respond to messages from hardware (e.g. interrupts)
- start and schedule programs
- control and organize storage
- allocate and manage resources (memory, CPU, network)
- pass messages between programs (network, IPC, and signals)

### What is a Docker?

- creates containers by configuring Linux cgroup, namespaces, and
  copy-on-write filesystems to build images
- client and server written in Go to manage Linux kernel features
- makes scripting distributed systems easy
- client/server connect via a socket (network or local file)
- client & server can be same machine or separate or even it's own container 

The following will run docker 4.0.1 client inside a container and connect it to 
the docker server running on the host.  This shows that the docker server can be
controlled from outside the host system.

```bash
    docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock docker sh
```

### Docker Networking

OSI Network model

- layer 1 - physical - NIC or other network adapter
- layer 2 - data link - data frames on wire or WiFi; node 2 node xfer via MAC address
- layer 3 - network - packets move on a local network (IP, IPsec, ICMP)
- layer 4 - transport - packets moved via protocol (TCP, UDP)
- layer 5 - session - (part of TCP protocol) sockets
- layer 6 - presentation - MIME, SSL/TLS
- layer 7 - application - closest to user

TCP/IP model

- link layer - maps to data link layer
- internet layer - subset of network layer
- transport layer - glaceful close of session layer & transport layer
- application layer - application, presentation, & session layers together

Docker incorporates

- link layer - ethernet or WiFi frames
- internet layer - moves packets on local network
- routing layer - routes packets between networks
- ports - address of a programming running on a computer (ip and port#)

Docker Networks

- are bridges creates virtual network inside host
- equivalent to software network switch controlling traffic
- use data link (e.g. ethernet) layer

`--net=host` gives the following full access to the host's network stack
and allows full access to the system

```bash
    docker run -ti --rm --net=host ubuntu:16.04
    # inside container
    apt-get update && apt-get install -y bridge-utils net-tools 
    brctl show
    # do docker network create my-network in another session
    brctl show # shows new bridge
```

Docker uses iptables to route traffic between the various bridges to and
from containers. Note: iptables is not part of MacOS, but you can run it
inside a container.

```bash
    docker run -it --rm --net=host --privileged=true ubuntu bash
    # now inside container
    apt-get update && apt-get install -y iptables
    iptables -n -L -t nat # shows default entries
    # run 2nd container in another session with some ports forwarded
    # docker run -it --rm -p 8080:8080 ubuntu bash
    iptables -n -L -t nat # shows additional entries for port 8080
```
This feature uses kernel Namespaces to provide processes with network 
isolation. While bridges can be share network traffic among multiple 
containers, namespaces isolate each container's networking stack so that
other containers can't reconfigure it.

### Docker processes and cgroups

````bash
    docker run -ti --rm --name hello --pid=host ubuntu bash
    # another session shows the master PID running the container
    docker inspect hello --format="{{.State.Pid}}" hello
    # returns PID
    # run superprivledged container
    docker run -ti --rm --privileged=true --pid=host ubuntu bash
    # inside container
    kill PID # this will kill the other container
````

Docker uses cgroups to allow fine-grained control to CPU scheduling, 
memory allocation, and other system resources.  They are **inherited** 
and cumulative.  The container started with 800M of memory **shares** 
that quota with all processes that run in the container (i.e. the sum 
of all memory in the container by all processes can't exceed 800M).

### Storage

Kernel manages physical drives allowing reading/writing data to them.  

Drives can be grouped logically to improve performance and redunancy 
(e.g. RAID). 

Filesystems structure physical drive(s) to allow for specific access to 
data on a drive.  There are programs that can pretend to be filesystems
(FUSE and NFS). Docker uses COWS (Copy On Write) filesystem which abstract
containers into a base layer and additional R/O layers.  Additional writes
in an active container write to an additonal layer (unless using a volume).

The mechanism for managing COWS images depends on the underlaying OS. Some
OS's use btrfs. Others use the built-in LVM or the overlay filesystem. A
container is copied from a repository by gzipped layers. This makes them
independent of the storage engine running on the Docker server.  But some
storage engines have restrictions on the number of layers they can handle.
So images build with a large number of layers on another system may not
run on such machines.

Docker volumes are part of the Linux VFS (Virtual File System). VFS allows
attaching a directory in the filesystem to be attached and mounted.

```bash
    docker run -ti --rm --privileged=true ubuntu bash
    mkdir -p example/work example/other-work
    cd example/work
    touch a b c d e f
    cd ..
    cd example/other-work
    touch other-a other-b other-c other-d
    cd ..
    ls -R  # shows both directories and their files
    mount -o bind other-work work # mount other-work/ OVER work/
    ls -R  # shows both directories but the files in work aren't shown
           # they're still there but other-work directory is hiding them
           # this happens all the time with physical mounts
    umount work
    ls -R  # all the files are back
```

You must do the mount commands in the right order (e.g. first the 
directory, then the folder).  Mounting Docker volumes **always** mounts
the host's filesystem OVER the container's filesystem.

## Docker Orchestration

### Registries

program run either as a container or installed.
    
- stores layers and images
- listens on port 5000
- requires cert if docker client run w/ default config
- index and search tags
- **must** setup authentication if exposing to a network
    
Official Docker registry https://docs.docker.com/registry

```bash
    docker tag ubuntu:14.04 localhost:5000/mycompany/my-ubuntu:99
    docker push localhost:5000/mycompany/my-ubuntu:99
    docker run -d -p 5000:5000 --restart=always registry registry:2
```
Nexus

Stores containers:

- Docker's dockerhub
- AWS elastic container registry
- Google container registry
- Azure container registry
- local storage
  `docker load` & `docker save` to save containers locally and copy to customer or to move between storage engine types on same server

```bash
    docker save -o my-images.tar.gz debian busybox ubuntu:14.04
    docker rmi debian busybox ubuntu:14.04
    docker load -i my-images.tar.gz
    # images are restored
```

### Orchestration

- many orchestration systems for docker (e.g. kubernetes, rancher, mesosphere)
- start containers and resart them when they fail
- allow service discovery so container's services can find each other
- ensure containers run where they'll have resources they need (storage, RAM, CPU, availability)

#### Docker Compose

- **single** machine coordination of multiple resources
- designed for testing, development, and staging
- won't work large systems and dynamic scaling
- brings up all containers, volumes, and networks in single command

#### [Kubernetes](https://kubernetes.io)

- containers that run programs
- pods group containers together into an application on same node
- Services make pods dynamically distributed with built-in discovery
- labels used for advanced service discovery
- `kubectl` used for scripting large operations 
- very flexible overlay network
- runs well on on-prem HW and in cloud

#### [AWS ECS (EC2 Container Service)](https://aws.amazon.com/ecs)

- Task definition (define a set of containers that run together)
- Tasks (runs containers in definition on same system)
- Services and exposure to Net
  (define 14 copies of a service and it will ensure 14 copies are always running)
- ties services into AWS ELB for availability
- user creates their own EC2 instances and join into a ECS cluster by passing docker control socket to ECS agent
- ECS provides their own repos
- Containers and tasks can be part of AWS CloudFormation stacks

#### Other Solutions

- AWS Fargate (more automated ECS)
- Docker Swarm
- Google Kubernetes Engine (GKS)
- Azure Kubernetes Engine (AKS)

#### AWS Kubernetes (EKS)








