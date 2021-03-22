# Nomad-Consul-Traefik-Test

This project describes on how to setup a simple Cluster for running workloads.

**NOTE** This is not intended for a production cluster. Only for learning and testing purposes

## Overview

Following tools are deployed with this project

[Traefik](https://docs.traefik.io/): Load balancer using Consul Catalog service discovery. All services registered in Consul with the tag `http` will be exposed as `<service name>.test`. In context of this test setup, you'll have to adjust your `/etc/hosts` file accordingly ([see below](#user-content-etc-hosts)).

[Consul](https://consul.io/): Service Discovery and Service Configuration. All services are registered here and is availale as `<service-name>.service.consul`

[Nomad](https://nomadproject.io/) Cluster Orchestration and running workloads. The Nomad cluster is configured to use Docker Task driver to run containerized workloads

An example deployment configuration for each is included in this setup.

<br clear="both"><br>

## Setup

### Prerequisites

You need three components to get the setup running:

1. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. [Vagrant](https://www.vagrantup.com/downloads.html) <sup id="a1">[1](#f1)</sup>
3. [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)


Also your host system needs at least 6GB of RAM available and about 20GB of free hard disk (sorry, Vagrant VM boxes️).


### Installation

1. **Clone this Git repository:**

   ```sh
   git clone --depth=1 https://github.com/fhemberger/nomad-test.git
   cd nomad-test
   ```

2. **Create and provision virtual machines with Vagrant:**  
   Vagrant will create six virtual machines with IPs _10.1.10.20–25_. If your local network already uses this address range, you can define an alternate range in the `Vagrantfile` before continuing with the installation.

   As there are some logical dependencies in the setup, it is split up in multiple parts:
   
     1. Create the six VMs in VirtualBox
     2. Setup the Consul cluster in server mode and elect a leader
     3. Setup Nomad Cluster in server mode, Setup Client nodes with Consul and Nomad in agent mode 
     4. Setup the Loadbalancer with Traefik
  
     <br>

   ```sh
   ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""
   
   vagrant up --no-provision \
     && vagrant provision --provision-with consul \
     && vagrant provision --provision-with all 
   ```
   - The SSH key is generated and used instead of the insecure key generated by Vagrant. To simplify, a bash script `run.sh` is added to the repo.
   - To run the project, Clone the repo, and run `bash run.sh`
   - This will run the full project in full
    
3. **Configure host names for all services:**  
   On your machine, add the following lines to your `/etc/hosts`. If you changed the IP range before in your `Vagrantfile`, make sure to adjust it here as well:

   ```
   10.1.10.20 traefik.test
   10.1.10.20 consul.test
   10.1.10.20 nomad.test
   10.1.10.20 hello.test
   ```

To check if everything is working correctly, go to http://traefik.test, you should see the UI of the load balancer with a list of registered services:

<br clear="both"><br>

Sites available after installation:

- http://traefik.test - Load balancer UI, see all registered services
- http://consul.test - Consul UI
- http://nomad.test - Nomad UI

## Working with Nomad

### Deploying jobs and testing

#### Running jobs using the CLI

Once Step 2 is completed, we can add jobs to Nomad. To run job from CLI, 

1. Login to a client node
   ```shell
    vagrant ssh consul-nomad-client1
   ```

2. There is a demo job in the `nomad_jobs` folder of the node. This job is also configured to work as a consul template.
    For the job to work, a text needs to be added to the consul server. So run this command
   ```shell
   consul kv put httpd/index "This is version v1" 
   ```

3. Run the nomad job
   ```shell
   nomad job run ~/nomad_jobs/hello-world-docker.nomad
   ```
   
4. The Job must be visible in Nomad UI
5. To test the webpage is up, from a browser access `http://hello.test` and it should display **This is version v1**
6. Now to test templating function, Go to `http://consul.test`, go to **Key/Value** and select `httpd/index` 
7. Update the text with anything. This text will be visible on the web page on `http://hello.test`. After update, click Save.
8. Go to Nomad UI, there will be a redeployment. Once its running, refresh `http://hello.test` page to see the changes 
9. To test if the job will run in the event of failure, run the command to identify the node
   ```shell
   dig A hello.service.consul
   ```
10. The result will show on which node the job is running.
11. Exit from the client node and shutdown the instance. the name of the server can be `consul-nomad-client1` or `consul-nomad-client2`
    ```shell
    vagrant halt <server-name>
    ```
12. Check the nomad UI, the job will be in pending and then start running by allocating the job on the next node. It might take from 20 to 30 seconds to have the job running again.

#### Running jobs from the UI

1. A single example application is only included with this demo: [`hello-world-docker.nomad`](nomad_jobs/hello-world-docker.nomad)
2. Go to http://nomad.test/ui/jobs/run
3. Copy and paste the job content into the editor. Change the name of the service to have a different job name and click "Plan".
4. Nomad performs a syntax check by dry-running the job on the scheduler without applying the changes yet. If you change settings in your job file later on, this step will also show a diff of all the changes (e.g. number of instances):
5. Click "Run" to deploy the job to the Nomad cluster.

### Stopping jobs

Go to the [Job overview page](http://nomad.test/ui/jobs), select a job, click "Stop" and confirm. Stopped jobs don't disappear immediately but remain in the "Dead" state until the garbage collection removes them completely.

### Removing dead/completed jobs

Dead/completed jobs are cleaned up in accordance to the garbage collection interval (default: `1h`). You can force garbage collection using the System API endpoint which will run the global garbage collector:

```sh
vagrant ssh consul-nomad-client1 -c 'curl -X PUT http://localhost:4646/v1/system/gc'
```


## Taking it further

Dive deeper into the [Job specification](https://nomadproject.io/docs/job-specification/): learn about the [`artifact`](https://nomadproject.io/docs/job-specification/artifact/), [`template`](https://nomadproject.io/docs/job-specification/template/) and [`volume`](https://nomadproject.io/docs/job-specification/volume/) stanzas to add config files and storage to your jobs. Starting 0.11 beta, Nomad also supports [Container Storage Interface (CSI)](https://www.hashicorp.com/blog/hashicorp-nomad-container-storage-interface-csi-beta/).

You can launch jobs that claim storage volumes from AWS Elastic Block Storage (EBS) or Elastic File System (EFS) volumes, GCP persistent disks, Digital Ocean droplet storage volumes, Ceph, vSphere, or vendor-agnostic third-party providers like Portworx. This means that the same plugins written by storage providers to support Kubernetes also support Nomad out of the box.


## On Security

For this demo I tried to keep the setup simple. This is kind of like development mode setup. So somethings to take into consideration when moving forward,

- Enable ACLS for Consul, Nomad to restrict accesses for API calls and users
- Integrate Vault to provide a secure tokens which can integrate seamlessly with Nomad and Consul
- TLS communication should be setup for encrypted communications
- Proper firewall rules with a deny all approach and allow only required traffic
- Nomad workloads should be properly designed to make the job itself secure
