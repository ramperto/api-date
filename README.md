
# Monorepo Services

A tech company uses mono repo to maintain the code version, there are two backend
services built using Go and Nodejs. Also, they use Kubernetes to manage their
container.

The following project consists of two different types of services using the nodejs and golang programming languages.

The goal to be achieved is to create two backend services with different languages and can be accessed from one domain with different paths.

## You Will Need

To build and run all of these examples, you will need:

* Go (any recent version is fine)
* Nodejs version 12 or above
* Docker version 18.03 or above
* Kubernetes Cluster version 1.20 or above
* Helm3
    

## 1. A simple app using both programming languages

This project consists of 2 services with go language and javascript: 

#### a. Simple nodejs application that will tell you random facts of the day:
I made this app pretty simple, it handles http request, then passed http://numbersapi.com/ to
the handler and prints output "Fakta hari ini adalah + {{numberapi output}} ".
### Run Locally

Clone the project

```bash
  git clone https://github.com/ramperto/api-date.git
```

Go to the project directory

```bash
  cd api-date
```

Install dependencies

```bash
  npm install
```

Start the server

```bash
  node index.js
```

Access the App

```bash
  curl http://localhost:3000/
  Fakta hari ini adalah June 17th is the day in 1910 that Aurel Vlaicu pilots a A. Vlaicu nr.
```


#### b. Golang application that provides a list of names when accessed
For this golang application I only use the existing code at 
https://golang.cafe/blog/golang-rest-api-example.html, this application 
will print the name when accessed in the /users path

### Run Locally

Clone the project

```bash
  git clone https://github.com/ramperto/api-date.git
```

Go to the project directory

```bash
  cd api-date
```

Start the server

```bash
  go run main.go
```

Access the App

```bash
curl http://localhost:8080/users/1
{"id":"1","name":"bob"}
```
    
## 2. CI/CD configuration

For this project I use the CI/CD tools released by github, Github Actions.

First we need to set up out secrets env for docker hub, this will be used later to publish
our image to repository.

`DOCKER_PASSWORD`

`DOCKER_USERNAME`

Insert the variable and value to github settings > secrets > Actions

![Github secrets setting](https://github.com/ramperto/api-date/blob/master/secrets_github.png?raw=true)

Github actions workflow files stored in .github/workflow. A workflow is a configurable automated process made up of one or more jobs.

Because this is a monorepo project and we need to run 2 backend services, the deployment will auto
triggered by pushing to tags.

Here is the content of nodejs deployment config file:
```
name: DEVELOPMENT node service Deployment
on: 
  push:
    tags:
      - node-svc-dev.1.*.*
```
The code above is describing our deployment name and what parameter needed to trigger the 
deployment, you can see the workflow will run when you push the tag with format "node-svc-dev.1.\*.\*"

It will not run if you tag the commit with other formats, like "node-svc-1.0.0".

A workflow run is made up of one or more jobs, which run in parallel by default. To run jobs sequentially, you can define dependencies on other jobs using the jobs.<job_id>.needs keyword.

```
jobs:
  test_service:
  push_to_registry:
```

As you can see from above configuration, I made two jobs, *test_service* job is created to 
build and test the service, and *push_to_registry* job to push the code to docker hub.

*push_to_registry* job will not run before *test_service* job success. This is how it look like
from github actions dashboard:

![Github actions jobs](https://github.com/ramperto/api-date/blob/master/actions_2.png?raw=true)

The image above showed the success pipeline when test and pushing docker image done without error.

If *test_service* job failed it will not proceed to *push_to_registry* job, and will notifiy through email:
![Github actions jobs failed](https://github.com/ramperto/api-date/blob/master/action_failed.png?raw=true)
failed *test_service* job
![Github actions jobs failed](https://github.com/ramperto/api-date/blob/master/actions_failed_mail.png?raw=true)
email notification.




#### a. Build and test the service
Here is the configuration to build and test the service:
```
    name: build and test service image
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v3

      - name: update docker files
        run: cp dockerfiles/node_service/* .

      - name: run docker compose test
        run: docker-compose -f docker-compose-test-node.yml -p ci up --abort-on-container-exit --exit-code-from sut
```
After the code pulled from repository to github action node, the needed docker files copied to the
root path, then using docker compose I run the test, the goal of this simple test is to ensure
the service run without error and give output base on the request we define in our test script *({root_path}/test_script/)*.
![Github actions test success](https://github.com/ramperto/api-date/blob/master/actions_test.png?raw=true)

*push_to_registry* job is used to build and push the working image to docker hub.
#### b. Building and push the container image
Here is the pieces of configuration to build and push the container image:
```
  push_to_registry:
    needs: test_service
    name: Push Docker image to Docker Hub
    runs-on: ubuntu-latest
```
*push_to_registry* job run after *test_service* job success, it happen because I set *needs*
as conditional expression that requires *test_service* to run and success first.
```
    steps:
      - name: Check out the repo
        uses: actions/checkout@v3

      - name: create dockerfile
        run: cp dockerfiles/node_service/Dockerfile.node_service Dockerfile
      
      - name: Log in to Docker Hub
        uses: docker/login-action@f054a8b539a109f9f41c372932f1ae047eff08c9
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@98669ae865ea3cffbcbaa878cf57c20bbf1c6c38
        with:
          images: greenlemon/node-service
      
      - name: Build and push Docker image
        uses: docker/build-push-action@ad44023a93711e3deb337508980b4b5e9bcdc5dc
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

In the example workflow above, we use the Docker `login-action` and `build-push-action` actions to build the Docker image and, if the build succeeds, push the built image to Docker Hub.

To push to Docker Hub, you will need to have a Docker Hub account, and have a Docker Hub repository created. For more information, see "Pushing a Docker container image to Docker Hub" in the [Docker documentation](https://docs.docker.com/docker-hub/repos/#pushing-a-docker-container-image-to-docker-hub).

The `login-action` options required for Docker Hub are:

* `username` and `password`: This is your Docker Hub username and password. We recommend storing your Docker Hub username and password as secrets so they aren't exposed in your workflow file.
The metadata-action option required for Docker Hub is:

* `images:` The namespace and name for the Docker image you are building/pushing to Docker Hub.

The build-push-action options required for Docker Hub are:

* `tags:` The tag of your new image in the format DOCKER-HUB-NAMESPACE/DOCKER-HUB-REPOSITORY:VERSION. You can set a single tag as shown below, or specify multiple tags in a list.
* `push:` If set to true, the image will be pushed to the registry if it is built successfully.

#### c. Deploy to Kubernetes Cluster

The deployment to kubernetes cluster with github actions only possible when I am using cloud services.
Since I am working on local environment, I deploy on my docker-desktop kubernetes cluster.

For deployment I am using helm3. The manifest files can be found on *{root_path/k8s/}* directory.
``` bash
├───k8s
│   ├───go_service
│   │   │   Chart.yaml
│   │   │   development-values.yaml
│   │   │   staging-values.yaml
│   │   │   values.yaml
│   │   │
│   │   ├───charts
│   │   │       ingress-nginx-4.1.4.tgz
│   │   │
│   │   └───templates
│   │           deployment.yaml
│   │           service.yaml
│   │
│   └───node_service
│       │   Chart.yaml
│       │   development-values.yaml
│       │   staging-values.yaml
│       │   values.yaml
│       │
│       ├───charts
│       │       ingress-nginx-4.1.4.tgz
│       │
│       └───templates
│               deployment.yaml
│               service.yaml
```

To deploy node service with helm use this command:

``` bash
helm upgrade --install node-service-development --values=.\k8s\node_service\development-values.yaml .\k8s\node_service\
```

To deploy go services with helm use this command:
```
helm upgrade --install go-service-development --values=.\k8s\go_service\development-values.yaml .\k8s\go_service\
```

The services will be deployed using image that pulled from our previous docker image on docker hub repository.

```bash
kubectl get pod -n development 
NAME                           READY   STATUS    RESTARTS   AGE
go-service-975888747-fzljr     1/1     Running   0          4m19s
node-service-966b54d46-hjscx   1/1     Running   0          3m36s
```


```bash
kubectl get deploy -n development 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
go-service     1/1     1            1           2m41s
node-service   1/1     1            1           118s
```

```bash
kubectl get svc -n development
NAME                               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE     
go-service-service-development     LoadBalancer   10.111.4.13     localhost     8080:31061/TCP   2m9s    
node-service-service-development   LoadBalancer   10.101.76.135   localhost     3000:32684/TCP   86s   
```

Below is the default values.yaml for node service:
```bash
environment: staging
container:
  name: node-service
  port: 3000
  image: greenlemon/node-service
  tag: latest
  resources:
    requests:  
      memory: "10Mi"
      cpu: "100m"
    limits:
      memory: "20Mi"
      cpu: "250m"
replicas: 1

```
Here we can see the default values for our deployment and services manifest.

When you need to deploy development environment, some of the values will overide with `development-values.yaml` content:
```bash
environment: development
replicas: 1
```

## 3. Service can be consumed from the public internet using the DNS domain (optional)
To make the kubernetes cluster accessible, I use kubernetes nginx ingress as the ingress Service to serve our service over custom domain.

Run this command to apply the ingress-service:
```bash
kubectl apply -f .\nginx-ingress.yaml
```
The command will deploy our new ingress from `nginx-ingress.yaml` file 
with the specs below:
```
spec:
  rules:
    - host: "192-168-0-105.xip.io"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: node-service-service-development
                port:
                  number: 3000
          - path: /go
            pathType: Prefix
            backend:
              service:
                name: go-service-service-development
                port:
                  number: 8080
```
The service is accessible using [xip.io](http://xip.io/) that worked as wildcard DNS.

For the spec above, I set the root path for node service, which is run on port 3000, and /go path for golang services on 8080.
And all these services will be forwarded to default nginx port for http (80).
