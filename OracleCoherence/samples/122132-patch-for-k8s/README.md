Example of Patching an Oracle Coherence Image
=============================================
This image extends the Oracle Coherence binary image and applies a necessary patch for running Coherence on Kubernetes.

# How to build and run
First make sure you have built or pulled **oracle/coherence:12.2.1.3.0**.

Then download file [p29204496_122130_Generic.zip](https://updates.oracle.com/Orion/PatchDetails/process_form?patch_num=29204496),
Coherence 12.2.1.3.2 Cumulative Patch using OPatch, and place it next to this README.

To build, run:

        $ docker build -t oracle/coherence:12.2.1.3.2 .

## Verify that the Patch has been applied correctly
Run a container from the image

        $ docker run -d --name verify_patch oracle/coherence:12.2.1.3.2

Go into the image

        $ docker exec -it verify_patch /bin/bash

Use the OPatch utility, located in `/u01/oracle/oracle_home/OPatch`, to verify that the patch has been installed.

        cd OPatch
        ./opatch lsinventory 

The patch will show in the inventory of applied patches.

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
