FROM uwgac/ubuntu-18.04-hpc

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

#RUN wget https://github.com/MMAP/MMAP-releases-issues-Q-and-A/releases/tag/mmap.2018_04_07_13_28.intel
COPY mmap.2018_04_07_13_28.intel /
ENV MMAP=/mmap.2018_04_07_13_28.intel
