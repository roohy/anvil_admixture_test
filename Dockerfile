# Pull base image
FROM ubuntu:14.04.2

# Installation instructions: https://www.cog-genomics.org/plink2

# Environment variables
# 150314 == plink 1.9 beta 3 ???
ENV PLINK_VERSION       150314
ENV PLINK_HOME          /usr/local/plink
ENV PATH                $PLINK_HOME:$PATH


RUN DEBIAN_FRONTEND=noninteractive apt-get install -y unzip wget && \
    wget https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20220402.zip --no-check-certificate && \
    unzip plink_linux_x86_64_20220402.zip -d $PLINK_HOME && \
    rm plink_linux_x86_64_20220402.zip && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y unzip wget && \
    rm -rf /var/lib/apt/lists/*



# Set the default action to print plink's options 
CMD ["plink"]


# FROM amazonlinux

# RUN yum install -y gcc gcc-c++ libstdc++ gcc-gfortran glibc glibc-devel make blas-devel lapack lapack-devel atlas-devel perl-Digest-SHA

# COPY b0cec5e.tar.gz /usr/src

# RUN tar xvfz /usr/src/b0cec5e.tar.gz -C /usr/src/ && \
#     mv /usr/src/plink-ng-b0cec5e /usr/src/plink && \
#     rm /usr/src/b0cec5e.tar.gz

# RUN cd /usr/src/plink/1.9 && ./plink_first_compile && cd && ln -s /usr/src/plink/1.9/plink /usr/local/bin/plink1.9

