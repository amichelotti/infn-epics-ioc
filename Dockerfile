##### build stage ##############################################################

ARG TARGET_ARCHITECTURE
ARG BASE=7.0.7ec3
ARG REGISTRY=ghcr.io/epics-containers

FROM  ${REGISTRY}/epics-base-${TARGET_ARCHITECTURE}-developer:${BASE} AS developer

# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location
RUN ln -s ${SOURCE_FOLDER}/ioc ${IOC}

# Get latest ibek while in development. Will come from epics-base when stable
COPY requirements.txt requirements.txt
RUN pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

# copy the global ibek files
COPY ibek-support/_global/ _global

COPY ibek-support/iocStats/ iocStats
RUN iocStats/install.sh 3.2.0

################################################################################
#  TODO - Add further support module installations here
################################################################################

COPY ibek-support/asyn/ asyn/
RUN asyn/install.sh R4-44

COPY ibek-support/autosave/ autosave/
RUN autosave/install.sh R5-11

COPY ibek-support/busy/ busy/
RUN busy/install.sh R1-7-3

COPY ibek-support/StreamDevice/ StreamDevice/
RUN StreamDevice/install.sh 2.8.24

COPY ibek-support/sscan/ sscan/
RUN sscan/install.sh R2-11-6

COPY ibek-support/calc/ calc/
RUN calc/install.sh R3-7-5

COPY ibek-support/motor/ motor/
RUN motor/install.sh R7-3

COPY ibek-support/motorMotorSim/ motorMotorSim/
RUN motorMotorSim/install.sh R1-2

COPY ibek-support/ADCore/ ADCore/
RUN ADCore/install.sh R3-13

COPY ibek-support/ADGenICam ADGenICam/
RUN ADGenICam/install.sh master

COPY ibek-support/ADAravis/ ADAravis/
RUN ADAravis/install.sh R2-3

COPY ibek-support/ADSimDetector ADSimDetector/
RUN ADSimDetector/install.sh R2-10

#COPY ibek-support/lakeshore340  lakeshore340/
#RUN  lakeshore340/install.sh 2-6

COPY ibek-support/modbus/ modbus/
RUN modbus/install.sh R3-3

COPY ibek-support/motorNewport motorNewport/
RUN motorNewport/install.sh R1-2-1

COPY ibek-support/biltItest biltItest/
RUN biltItest/install.sh main


# get the ioc source and build it
COPY ioc ${SOURCE_FOLDER}/ioc
RUN cd ${IOC} && make

##### runtime preparation stage ################################################

FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*

##### runtime stage ############################################################

FROM ${REGISTRY}/epics-base-${TARGET_ARCHITECTURE}-runtime:${BASE} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /

# install runtime system dependencies, collected from install.sh scripts

RUN ibek support apt-install-runtime-packages 

ENV TARGET_ARCHITECTURE ${TARGET_ARCHITECTURE}

CMD ["/bin/bash", "-c", "${IOC}/start.sh"]
