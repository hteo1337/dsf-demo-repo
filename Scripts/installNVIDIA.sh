#!/bin/bash

#Install GPU Drivers for RHEL and CentOS 7.x
yum clean all
yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
yum install -y http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-10.0.130-1.x86_64.rpm
yum install -y epel-release
yum clean all
yum install -y cuda 
yum install -y jq 
#Install nvidia toolkit
yum clean expire-cache
yum install nvidia-container-toolkit -y
