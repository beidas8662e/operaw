Apache HTTP Server with Oracle WebLogic Server Proxy Plugin on Docker
===============
This project includes a quick start Dockerfile and samples for standalone Apache HTTP Server with the 12.2.1.3.0 Oracle WebLogic Server Proxy Plugin based on Oracle Linux. The certification of Apache on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

## Build Apache With the Plugin Docker Image

This project offers a Dockerfile for the Apache HTTP Server with the Oracle WebLogic Server Proxy Plugin in standalone mode. To assist in building the images, you can use the  `buildDockerImage.sh` script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their preferred set of parameters.

IMPORTANT: You have to download the `Oracle WebLogic Server Proxy Plugin 12.2.1.3.0` package (see the `.download` file) and place it in this directory.

Run the `buildDockerImage.sh` script.

        $ sh buildDockerImage.sh

## Run the Apache HTTP Server in a Container

Run an Apache container to access an Administration Server, or a Managed Server, in a non-clustered environment that is running on `<host>` and listening to `<port>`.

        $ docker run -d -e WEBLOGIC_HOST=<host> -e WEBLOGIC_PORT=<port> -p 80:80 12213-apache

Run an Apache image to proxy and load balance a list of Managed Servers in a cluster.

        Use a list of hosts and ports.

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port -p 80:80 12213-apache

        Or use a cluster URL if it is available

        $ docker run -d -e WEBLOGIC_CLUSTER=<cluster-url> -p 80:80 12213-apache

The values of `WEBLOGIC_CLUSTER` must be valid and correspond to existing containers running WebLogic Servers.

### Administration Server Only Example

First, make sure that you have the WebLogic Server 12.2.1.3 install image. Pull the WebLogic install image from the DockerStore, `store/oracle/weblogic:12.2.1.3`, or build your own image, `oracle/weblogic:12.2.1.3-developer`, at [https://github.com/oracle/docker-images/tree/master/OracleWebLogic/dockerfiles/12.2.1.3](https://github.com/oracle/docker-images/tree/master/OracleWebLogic/dockerfiles/12.2.1.3).

Start a container from the WebLogic install image. During runtime, you can override the default values of the following parameters with the `-e` option:

        ADMIN_NAME (default: AdminServer)
        ADMIN_PORT (default: 7001)
        ADMIN_USERNAME (default: weblogic)
        ADMIN_PASSWORD (default: Auto Generated)
        DOMAIN_NAME (default: base_domain)
        DOMAIN_HOME (default: /u01/oracle/user_projects/domains/base_domain)

NOTE: To set the `DOMAIN_NAME`, you must set both `DOMAIN_NAME` and `DOMAIN_HOME`.

        $ docker run -d -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=welcome1 -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain -p 7001:7001 store/oracle/weblogic:12.2.1.3

Start an Apache container by calling:

        $ docker run -d --name apache -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Now you can access the WebLogic Administration Console under `http://localhost/console` (default to port 80) instead of using port 7001. You can access the Console from a remote machine using the WebLogic Administration Server's `<admin-host>` instead of `localhost`.

## Provide Your Own Apache Plugin Configuration
If you want to start the Apache container with some pre-specified `mod_weblogic` configuration:

* Create a `custom_mod_wl_apache.conf` file by referring to `custom_mod_wl_apache.conf.sample` and Chapter 3 of the [Fusion Middleware Using Oracle WebLogic Server Proxy Plug-Ins](https://docs.oracle.com/middleware/12213/webtier/develop-plugin/apache.htm#GUID-231FB5FD-8D0A-492A-BBFD-DC12A31BF2DE) documentation.

* Place the `custom_mod_wl_apache.conf` file in a directory `<host-config-dir>` on the host machine and then mount this directory into the container at the location `/config`. By doing so, the contents of the host directory `<host-config-dir>` (and hence `custom_mod_wl_apache.conf`) will become available in the container at the mount point.

This mounting can be done by using the `-v` option with the `docker run` command as shown below.

        $ docker run -v <host-config-dir>:/config -w /config -d -p 80:80 12213-apache

**Note**: You can also mount the file directly as follows:

After the mounting is done, the `custom_mod_wl_apache.conf` file will replace the built-in version of the file.

## Stop an Apache Instance

To stop the Apache instance, execute the following command:

        $ docker stop apache (Assuming the name of container is 'apache')

To look at the Docker container logs, run:

        $ docker logs --details <Container-id>

## Considerations When Exposing WebLogic Server Ports
**IMPORTANT**: Although, for demonstration purposes, the examples above expose the default admin port to users outside of the Docker container where the Administration Server is running, Oracle recommends careful consideration before deciding to expose any administrative interfaces externally.

While it is natural to expose web applications outside a container, exposing administrative features, like the WebLogic Administration Console and a T3 channel for WLST, should be given more careful consideration. Similar to running a domain in a traditional data center, the same kind of considerations should be taken into account while running a WebLogic domain in a Docker container. These include various means of controlling access through T3 protocol, such as:

* Running HTTP on a separate port from T3 and other protocols.
* Not exposing T3 ports outside the firewall (for example, expose only HTTP).
* Not enabling HTTP tunneling for T3.

If it is necessary to expose T3 outside the firewall, using two-way SSL and connection filters to ensure that only known clients can connect to T3 ports.

## License
To download and run the Oracle WebLogic Server Proxy Plugins 12.2.1.3.0 distribution, regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

To download and run the Oracle JDK, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
