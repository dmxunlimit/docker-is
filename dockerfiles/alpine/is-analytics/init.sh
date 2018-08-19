#!/bin/sh
# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------
set -e

# product profile variable
wso2_server_profile=is-analytics

# custom WSO2 non-root user and group variables
user=wso2carbon
group=wso2

# file path variables
artifact_volume=${WORKING_DIRECTORY}/wso2-artifact-volume
config_map_volume=${WORKING_DIRECTORY}/wso2-config-volume

# capture the Docker container IP from the container's /etc/hosts file
docker_container_ip=$(awk 'END{print $1}' /etc/hosts)

# check if the WSO2 non-root user home exists
test ! -d ${WORKING_DIRECTORY} && echo "WSO2 Docker non-root user home does not exist" && exit 1

# check if the WSO2 product home exists
test ! -d ${WSO2_SERVER_HOME} && echo "WSO2 Docker product home does not exist" && exit 1

# copy configuration changes and external libraries

# check if any changed configuration files have been mounted
# if any file changes have been mounted, copy the WSO2 configuration files recursively
test -d ${artifact_volume}/ && cp -RL ${artifact_volume}/* ${WSO2_SERVER_HOME}/
test -d ${config_map_volume}/ && cp -RL ${config_map_volume}/* ${WSO2_SERVER_HOME}/

# make any runtime or node specific configuration changes
# for example, setting container IP in relevant configuration files

# set the Docker container IP as the `localMemberHost` under axis2.xml clustering configurations (effective only when clustering is enabled)
sed -i "s#<parameter\ name=\"localMemberHost\".*<\/parameter>#<parameter\ name=\"localMemberHost\">${docker_container_ip}<\/parameter>#" ${WSO2_SERVER_HOME}/repository/conf/axis2/axis2.xml
# replace host name entries (hard-coded with `wso2is-with-analytics-is-analytics`), with the Docker container IP in event-processor.xml file
sed -i "s#<hostName>wso2is-with-analytics-is-analytics</hostName>#<hostName>${docker_container_ip}</hostName>#" ${WSO2_SERVER_HOME}/repository/conf/event-processor.xml

# start the WSO2 Carbon server
sh ${WSO2_SERVER_HOME}/bin/wso2server.sh
