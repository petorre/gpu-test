#!/bin/bash

# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -e

# Bash program that validates worker node GPU allocation, run GPU manager
# and dummy app by using gpu-test Daemonset in k8s folder.

# for usage do:
#   gpu-test.sh --help

TIMEOUT=30

DEBUG="false"
CONFIGFILE="config.json"
LABEL=""
NODE=""
DELETE_NS="false"

# check requirements
for c in "kubectl" "jq" "jo" "awk"; do
    r=$( type "${c}" >> /dev/null 2>>/dev/null && echo 1 || echo 0 )
    if [[ "${r}" -eq 0 ]]; then
        echo "Error: ${c} not found! Exiting."
	exit 1
    fi
done

# parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG="true"
            shift
            ;;
        --config)
            CONFIGFILE="$2"
            shift 2
            ;;
        --label)
            LABEL="$2"
            shift 2
            ;;
        --node)
            NODE="$2"
            shift 2
            ;;
        --delete-ns)
            DELETE_NS="true"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --debug                With debug field"
            echo "  --config FILE          Config file"
            echo -n "  --label KEY[=VALUE]"
            echo "    Only test nodes with label KEY[=VALUE]"
            echo "  --node NAME            Only test node NAME"
            echo "  --delete-ns            Delete k8s Namespace"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

function report_error {
    j_e=$( jo name="gpu-test" description="${DESCRIPTION}" error="$1" )
    j_tc=$( jo -a "${j_e}" )
    j_fv=$( jo testCases="${j_tc}" )
    jo flavourValidation="${j_fv}" | jq -r
}

# starts here
# parse config.json
if [[ -e "${CONFIGFILE}" ]]; then
    j=$( cat "${CONFIGFILE}" )
    j_script=$( echo "${j}" | jq -r ' .script ' )
    SHOW_DESCRIPTION=$( echo "${j_script}" | jq -r ' .show.description ' )
    SHOW_TIMESTAMPS=$( echo "${j_script}" | jq -r ' .show.timeStamps ' )
    if [[ "$( echo "${j_script}" | jq -r ' .debug ' )" == "true" ]]; then
        DEBUG="true"
    fi
    NS_PAUSE=$( echo "${j_script}" | jq -r ' .namespacePause ' )
    POD_PAUSE=$( echo "${j_script}" | jq -r ' .podPause ' )
    NS=$( echo "${j_script}" | jq -r ' .namespace ' )
    j_deployfiles=$( echo "${j_script}" | jq -r ' .deployFiles ' )
    DEPLOY_DIR=$( echo "${j_deployfiles}" | jq -r ' .directory ' )
    DEPLOY_NS=$( echo "${j_deployfiles}" | jq -r ' .namespace ' )
    DEPLOY_DAEMONSET=$( echo "${j_deployfiles}" | jq -r ' .gpuTest ' )
    tc=$( echo "${j}" | jq -r ' .testCases[] |
        select ( .name == "validateGPU" ) ' )
    DESCRIPTION=$( echo "${tc}" | jq -r ' .description ' )
    ALLOCATION_DEVICE_NAME=$( echo "${tc}" | jq -r ' .allocationDeviceName' )
    ALLOCATION_DEVICE_MIN=$( echo "${tc}" | jq -r ' .allocationDeviceMin' )
    GPU_MGR_CMD_RES_MUST_EXIST=$( echo "${tc}" | \
        jq -r ' .gpumgrcmdresMustExist' )
    GPU_FREE_MEM_MIN=$( echo "${tc}" | jq -r ' .gpufreememMin' )
    APP_CMD_RES=$( echo "${tc}" | jq -r ' .appcmdres' )

    # delete NS and exit?
    if [[ "${DELETE_NS}" == "true" ]]; then
        kubectl delete ns "${NS}" --wait=true >> /dev/null
        exit 0
    fi

    START_TIME=$( date )

    # find target nodes
    if [[ "${NODE}" != "" ]]; then
        nodes=$( kubectl get no -o json | jq -r " .items[].metadata |
            select ( .name == \"${NODE}\" ) | .name " )
        if [[ "${nodes}" == "" ]]; then
            report_error "Cannot find node ${NODE}"
            exit 1
        fi
    elif [[ "${LABEL}" != "" ]]; then
        if [[ "${LABEL}" == *"="* ]]; then
            key="${LABEL%%=*}"
            value="${LABEL#*=}"
        else
            key="${LABEL}"
            value=""
        fi
        echo $key = $value
        if [[ "${value}" == "" ]]; then
            nodes=$( kubectl get no -o json | jq -r " .items[].metadata |
                select ( .labels.\"${key}\" ) | .name " )
        else
            nodes=$( kubectl get no -o json | jq -r " .items[].metadata |
                select ( .labels.\"${key}\" == \"${value}\" ) | .name " )
        fi
        if [[ "${nodes}" == "" ]]; then
            report_error "Cannot find node(s) with label ${LABEL}"
            exit 1
        fi
    else
        # all
        nodes=$( kubectl get no -o json | jq -r ' .items[].metadata.name ' )
        if [[ "${nodes}" == "" ]]; then
            report_error "Cannot find any nodes"
            exit 1
        fi
    fi

    if [[ $( timeout "${TIMEOUT}" kubectl get po -n "${NS}" -o json | \
        jq -r ' .items[].metadata.name ' | wc -l ) -ne 0 ]]; then
        report_error "Pods already running in namespace ${NS}"
        exit 1
    fi

    for n in ${nodes}; do
        # maybe more sed will be needed to fit node name to array subscript
        n_=$( echo "${n}" | sed "s/-/_/g" )
        nodeallocdev[${n_}]=$( kubectl get no "${n}" -o json | \
            jq -r " .status.allocatable.\"${ALLOCATION_DEVICE_NAME}\" " )
    done

    kubectl apply -f "${DEPLOY_DIR}/${DEPLOY_NS}.yaml" >> /dev/null
    sleep "${NS_PAUSE}"
    kubectl apply -f "${DEPLOY_DIR}/${DEPLOY_DAEMONSET}.yaml" >> /dev/null
    sleep "${POD_PAUSE}"

    j_n=()
    for n in ${nodes}; do
        n_=$( echo "${n}" | sed "s/-/_/g" )
        if [[ ${nodeallocdev[${n_}]} -ge "${ALLOCATION_DEVICE_MIN}" ]]; then
            p=$( timeout "${TIMEOUT}" kubectl get po -n "${NS}" -o json | \
                jq -r " .items[] | select ( .spec.nodeName == \"$n\" ) | \
                .metadata.name " )
            if [[ -z "${p}" ]]; then
                if [[ "${DEBUG}" == "true" ]]; then
                    j_n+=( $( jo name="${n}" result="false"
                        debug="Cannot_find_pod" ) )
                else
                    j_n+=( $( jo name="${n}" result="false" ) )
                fi
            else
                t=$( mktemp )
                kubectl logs -n "${NS}" "${p}" > "${t}"
                r=$( awk -v GPUMGRCMDRESMUSTEXIST="true" \
                        -v GPUFREEMEMMIN="1" \
                        -v APPCMDRES="333283328000.00" '
                        GPUMGRCMDRESMUSTEXIST=="true" && $1=="gpumgrcmdres:" {
                            if ( $2=="0," )
                                gpumgrcmdresmustexist=1;
                        }
                        $1=="gpufreememres:" {
                            if ( $2 >= GPUFREEMEMMIN )
                                gpufreememmin=1;
                        }
                        $1=="appcmdres:" {
                            if ( $2==APPCMDRES )
                                appcmdres=1;
                        }
                        END {
                            if ( ( GPUMGRCMDRESMUSTEXIST=="true" &&
                                gpumgrcmdresmustexist || 1 ) &&
                                gpufreememmin && appcmdres )
                                    print "true";
                            else
                                print "false";
                        }
                    ' "${t}" )
                if [[ "${DEBUG}" == "true" ]]; then
                    gpumgrcmdresline=$( grep "gpumgrcmdres:" "${t}" || \
                        echo "no_gpumgrcmdres" )
                    gpufreememresline=$( grep "gpufreememres:" "${t}" || \
                        echo "no_gpufreememres" )
                    appcmdresline=$( grep "appcmdres:" "${t}" || \
                        echo "no_appcmdres" )
                    appcmddebugline=$( grep "appcmddebug:" "${t}" || \
                        echo "no_appcmddebug" )
                    d=$( echo "${gpumgrcmdresline}; ${gpufreememresline}; \
${appcmdresline}; ${appcmddebugline}" | sed "s/ /_/g" )
                    j_n+=( $( jo name="${n}" result="${r}" debug="${d}" ) )
                else
                    j_n+=( $( jo name="${n}" result="${r}" ) )
                fi
                rm -f "${t}"
            fi
        else
            if [[ "${DEBUG}" == "true" ]]; then
                if [[ ${nodeallocdev[${n_}]} == "null" ]]; then
                    j_n+=( $( jo name="${n}" result="false" \
                        debug="not_allocatable_${ALLOCATION_DEVICE_NAME}" ) )
                else
                    j_n+=( $( jo name="${n}" result="false" \
                        debug="allocatable_${ALLOCATION_DEVICE_NAME}:\
${nodeallocdev[${n_}]}<${ALLOCATION_DEVICE_MIN}" ) )
                fi
            else
                j_n+=( $( jo name="${n}" result="false" ) )
            fi
        fi
    done

    kubectl delete -f "${DEPLOY_DIR}/${DEPLOY_NS}.yaml" --wait=false >> \
        /dev/null

    j_nodes=$( jo -a ${j_n[*]} )
    if [[ "${SHOW_DESCRIPTION}" == "true" ]]; then
        j_tc=$( jo name="gpu-test" description="${DESCRIPTION}" \
            nodes=${j_nodes} )
    else
        j_tc=$( jo name="gpu-test" nodes=${j_nodes} )
    fi

    if [[ "${SHOW_TIMESTAMPS}" == "true" ]]; then
        STOP_TIME=$( date )
        j_tc=$( echo "${j_tc}" | jq " . +
            {
                timeStamps:
                    {
                        startTime: \"${START_TIME}\",
                        stopTime: \"${STOP_TIME}\"
                    }
            } " )
    fi

    j_tcs=$( jo -a "${j_tc}" )
    j_fv=$( jo testCases="${j_tcs}" )
    jo flavourValidation="${j_fv}" | jq -rM


else
    report_error "Cannot find config file ${CONFIGFILE}"
    exit 1
fi
