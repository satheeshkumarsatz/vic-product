# Copyright 2018 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

*** Settings ***
Documentation  Test 5-01 - Distributed Switch
Resource  ../../resources/Util.robot
Suite Setup  Wait Until Keyword Succeeds  10x  10m  Distributed Switch Setup
Suite Teardown  Run Keyword And Ignore Error  Nimbus Cleanup  ${list}

*** Variables ***
${esx_number}=  3
${datacenter}=  ha-datacenter

*** Keywords ***
Distributed Switch Setup
    [Timeout]    110 minutes
    Run Keyword And Ignore Error  Nimbus Cleanup  ${list}  ${false}
    ${vc}=  Evaluate  'VC-' + str(random.randint(1000,9999)) + str(time.clock())  modules=random,time
    ${pid}=  Deploy Nimbus vCenter Server Async  ${vc}
    Set Suite Variable  ${VC}  ${vc}

    &{esxes}=  Deploy Multiple Nimbus ESXi Servers in Parallel  3  %{NIMBUS_USER}  %{NIMBUS_PASSWORD}
    @{esx_names}=  Get Dictionary Keys  ${esxes}
    @{esx_ips}=  Get Dictionary Values  ${esxes}

    Set Suite Variable  @{list}  @{esx_names}[0]  @{esx_names}[1]  @{esx_names}[2]  %{NIMBUS_USER}-${vc}

    # Finish vCenter deploy
    ${output}=  Wait For Process  ${pid}
    Should Contain  ${output.stdout}  Overall Status: Succeeded

    Open Connection  %{NIMBUS_GW}
    Wait Until Keyword Succeeds  2 min  30 sec  Login  %{NIMBUS_USER}  %{NIMBUS_PASSWORD}
    ${vc_ip}=  Get IP  ${vc}
    Close Connection

    Set Environment Variable  GOVC_INSECURE  1
    Set Environment Variable  GOVC_USERNAME  Administrator@vsphere.local
    Set Environment Variable  GOVC_PASSWORD  Admin!23
    Set Environment Variable  GOVC_URL  ${vc_ip}

    Log To Console  Create a datacenter on the VC
    ${out}=  Run  govc datacenter.create ${datacenter}
    Should Be Empty  ${out}

    Create A Distributed Switch  ${datacenter}

    Create Three Distributed Port Groups  ${datacenter}

    Log To Console  Add ESX host to the VC and Distributed Switch
    :FOR  ${IDX}  IN RANGE  ${esx_number}
    \   ${out}=  Run  govc host.add -hostname=@{esx_ips}[${IDX}] -username=root -dc=${datacenter} -password=${NIMBUS_ESX_PASSWORD} -noverify=true
    \   Should Contain  ${out}  OK
    \   Wait Until Keyword Succeeds  5x  15 seconds  Add Host To Distributed Switch  @{esx_ips}[${IDX}]

    Set Environment Variable  TEST_URL  ${vc_ip}
    Set Environment Variable  TEST_USERNAME  Administrator@vsphere.local
    Set Environment Variable  TEST_PASSWORD  Admin\!23
    Set Environment Variable  BRIDGE_NETWORK  bridge
    Set Environment Variable  PUBLIC_NETWORK  vm-network
    Set Environment Variable  TEST_RESOURCE  /${datacenter}/host/@{esx_ips}[0]/Resources
    Set Environment Variable  TEST_TIMEOUT  30m
    Set Environment Variable  TEST_DATASTORE  datastore1

*** Test Cases ***
Test
    Log To Console  \nStarting test...
    Set Environment Variable  OVA_NAME  OVA-5-01-TEST
    Set Global Variable  ${OVA_USERNAME_ROOT}  root
    Set Global Variable  ${OVA_PASSWORD_ROOT}  e2eFunctionalTest
    Install VIC Product OVA Only  vic-*.ova  %{OVA_NAME}

    Set Browser Variables

    # Install VIC Plugin
    Download VIC And Install UI Plugin  %{OVA_IP}

    # Navigate to the wizard and create a VCH
    Open Firefox Browser
    Navigate To VC UI Home Page
    Login On Single Sign-On Page
    Verify VC Home Page
    Navigate To VCH Creation Wizard
    Navigate To VCH Tab
    Click New Virtual Container Host Button

    #general
    ${name}=  Evaluate  'VCH-5-01-' + str(random.randint(1000,9999)) + str(time.clock())  modules=random,time
    Input VCH Name  ${name}
    Click Next Button
    # compute capacity
    Log To Console  Selecting compute resource...
    Wait Until Element Is Visible And Enabled  css=button.clr-treenode-caret
    Click Button  css=button.clr-treenode-caret
    Wait Until Element Is Visible And Enabled  css=.clr-treenode-content clr-tree-node:nth-of-type(1) .cc-resource
    Click Button  css=.clr-treenode-content clr-tree-node:nth-of-type(1) .cc-resource
    Click Next Button
    # storage capacity
    Select Image Datastore  %{TEST_DATASTORE}
    Click Next Button
    #networks
    Select Bridge Network  %{BRIDGE_NETWORK}
    Select Public Network  %{PUBLIC_NETWORK}
    Click Next Button
    # security
    Toggle Client Certificate Option
    Click Next Button
    #registry access
    Click Next Button
    # ops-user
    Input Ops User Name  %{TEST_USERNAME}
    Input Ops User Password  %{TEST_PASSWORD}
    Click Next Button
    # summary
    Click Finish Button
    Unselect Frame
    Wait Until Page Does Not Contain  VCH name
    # retrieve docker parameters from UI
    Set Docker Host Parameters

    # run vch regression tests
    Run Docker Regression Tests For VCH
