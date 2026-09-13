#!/usr/bin/env python3

import os
import json
import itertools
import pandas as pd
import numpy as np
from glob import glob
import colorcet as cc
import matplotlib
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import seaborn as sns

flatui = sns.color_palette("colorblind")
hatch_list = [
    '///', '|||', '---', '\\\\\\', '***', '+++', 'ooo', 'xxx', 'OOO', '...'
]
hatches = itertools.cycle(hatch_list)
SHOW_PLT = 0
file_format = 'pdf'


def aggregate_istio_logs():
    expName = "/opt/Experiments/IstioBench3"
    IstioCsvLogFile = "/opt/Experiments/IstioBench3.csv"
    NFs = ["amf", "smf", "ausf", "bsf", "pcf", "nrf", "nssf", "udr", "udm"]
    json_data = []

    for runCount in range(1, 11):
        expRunDir = "{}-{}".format(expName, runCount)
        for sessionCount in list(range(100, 401, 100)):
            expSessionDir = os.path.join(expRunDir, str(sessionCount))
            for nf in NFs:
                nfJsonLogFileList = glob("{}/{}IstioLogs.json".format(
                    expSessionDir, nf))
                if len(nfJsonLogFileList) > 0:
                    nfJsonLogFile = nfJsonLogFileList[0]
                else:
                    continue
                print("Working on {}".format(nfJsonLogFile))
                with open(nfJsonLogFile) as f:
                    for line in f:
                        try:
                            json_line = json.loads(line.strip())
                            json_line["NF"] = nf
                            json_line["sessionCount"] = sessionCount
                            json_data.append(json_line)
                        except:
                            pass

    df = pd.DataFrame(json_data)
    df.to_csv(IstioCsvLogFile, index=False)


def plot_from_istio_logs():
    numSessions = list(range(100, 401, 100))
    IstioCsvLogFileDir = "/Users/umakantkulkarni/PurdueOneDrive/OneDrive - purdue.edu/Research/5gSec/Spring2024/IstioBenchmarking/3"
    IstioCsvLogFile = os.path.join(IstioCsvLogFileDir, "IstioBench3.csv")
    df = pd.read_csv(IstioCsvLogFile)
    df.dropna(axis=1, how='all', inplace=True)
    df = df.replace(r'^\s*$', np.nan, regex=True)
    #df.dropna(inplace=True)
    print(df)
    df["rqst_proc_time"] = df["request_tx_duration"] - df["request_duration"]
    df["rspn_proc_time"] = df["response_tx_duration"]
    df["envoy_proc_time"] = df["rqst_proc_time"] + df["rspn_proc_time"]
    df["transaction"] = "unknown"
    df["direction"] = "unknown"
    df["nfProcessTime"] = df["response_duration"] - df["request_tx_duration"]

    df.loc[df['upstream_cluster'].str.startswith('inbound'),
           'direction'] = "inbound"
    df.loc[df['upstream_cluster'].str.startswith('outbound'),
           'direction'] = "outbound"

    df.loc[df['path'] == "/nsmf-pdusession/v1/sm-contexts",
           'transaction'] = "CreateSMContext"

    df.loc[df['path'] == "/nausf-auth/v1/ue-authentications",
           'transaction'] = "UEAuthentications"

    df.loc[(df['path'].str.startswith('/nsmf-pdusession/v1/sm-contexts/')) &
           (df['path'].str.contains('/modify')),
           'transaction'] = "UpdateSMContext"

    df.loc[(df['path'].str.startswith('/namf-comm/v1/ue-contexts/imsi-')) &
           (df['path'].str.contains('/n1-n2-messages')),
           'transaction'] = "N1-N2MessageTransfer"

    df.loc[df['path'] == "/npcf-am-policy-control/v1/policies",
           'transaction'] = "CreateIndividualAMPolicyAssociation"

    df.loc[df['path'] == "/npcf-smpolicycontrol/v1/sm-policies",
           'transaction'] = "CreateSMPolicy"

    df.loc[(df['path'].str.startswith('/nudr-dr/v1/policy-data/ues/imsi-')) &
           (df['path'].str.contains('/am-data')),
           'transaction'] = "GetAccessAndMobilityPolicyData"

    df.loc[(df['path'].str.startswith('/nudr-dr/v1/policy-data/ues/imsi-')) &
           (df['path'].str.contains('/sm-data')),
           'transaction'] = "GetSessionManagementPolicyData"

    df_amf = df.loc[
        (df['transaction'] == "CreateSMContext") |
        (df['transaction'] == "UpdateSMContext") |
        (df['transaction'] == "N1-N2MessageTransfer") |
        (df['transaction'] == "CreateIndividualAMPolicyAssociation") |
        (df['transaction'] == "UEAuthentications")]
    amf_trans_order = [
        "CreateSMContext", "N1-N2MessageTransfer", "UpdateSMContext",
        "CreateIndividualAMPolicyAssociation", "UEAuthentications"
    ]
    for nf in ['amf']:
        df_nf = df_amf.loc[df['NF'] == nf]
        y_labels = [
            "Envoy Request Processing Time (ms)",
            "Envoy Response Processing Time (ms)",
            "Envoy Total Processing Time (ms)", "Total Duration (ms)"
        ]
        y_values = [
            "rqst_proc_time", "rspn_proc_time", "envoy_proc_time", "duration"
        ]
        for ynum, y in enumerate(y_values):
            fig, ax = plt.subplots()
            ax = sns.barplot(df_nf,
                             x='sessionCount',
                             y=y,
                             hue='transaction',
                             hue_order=amf_trans_order,
                             order=numSessions)
            lgnd_labels = []
            for i, lglb in enumerate(amf_trans_order):
                lgnd_labels.append(
                    mpatches.Patch(facecolor=flatui[i],
                                   label=amf_trans_order[i],
                                   hatch=hatch_list[i]))
            lines, labels = ax.get_legend_handles_labels()
            ax.legend(lines, handles=lgnd_labels, loc='best')
            unique_vals = len(df_nf["sessionCount"].unique().tolist())
            hatches = itertools.cycle(hatch_list)
            for i, bar in enumerate(ax.patches):
                if i % unique_vals == 0:
                    hatch = next(hatches)
                bar.set_hatch(hatch)
            plt.xlabel('Simultaneous Requests')
            plt.ylabel(y_labels[ynum])
            plt.tight_layout()
            plt.savefig('{}/{}_{}.{}'.format(IstioCsvLogFileDir, nf, y,
                                             file_format),
                        bbox_inches='tight')
            if SHOW_PLT:
                plt.show()
            plt.close()

    df_smf = df.loc[(df['transaction'] == "CreateSMContext") |
                    (df['transaction'] == "UpdateSMContext") |
                    (df['transaction'] == "N1-N2MessageTransfer") |
                    (df['transaction'] == "CreateSMPolicy")]
    smf_trans_order = [
        "CreateSMContext", "N1-N2MessageTransfer", "UpdateSMContext",
        "CreateSMPolicy"
    ]
    for nf in ['smf']:
        df_nf = df_smf.loc[df['NF'] == nf]
        y_labels = [
            "Envoy Request Processing Time (ms)",
            "Envoy Response Processing Time (ms)",
            "Envoy Total Processing Time (ms)", "Total Duration (ms)"
        ]
        y_values = [
            "rqst_proc_time", "rspn_proc_time", "envoy_proc_time", "duration"
        ]
        for ynum, y in enumerate(y_values):
            fig, ax = plt.subplots()
            ax = sns.barplot(df_nf,
                             x='sessionCount',
                             y=y,
                             hue='transaction',
                             hue_order=smf_trans_order,
                             order=numSessions)
            lgnd_labels = []
            for i, lglb in enumerate(smf_trans_order):
                lgnd_labels.append(
                    mpatches.Patch(facecolor=flatui[i],
                                   label=smf_trans_order[i],
                                   hatch=hatch_list[i]))
            lines, labels = ax.get_legend_handles_labels()
            ax.legend(lines, handles=lgnd_labels, loc='best')
            unique_vals = len(df_nf["sessionCount"].unique().tolist())
            hatches = itertools.cycle(hatch_list)
            for i, bar in enumerate(ax.patches):
                if i % unique_vals == 0:
                    hatch = next(hatches)
                bar.set_hatch(hatch)
            plt.xlabel('Simultaneous Requests')
            plt.ylabel(y_labels[ynum])
            plt.tight_layout()
            plt.savefig('{}/{}_{}.{}'.format(IstioCsvLogFileDir, nf, y,
                                             file_format),
                        bbox_inches='tight')
            if SHOW_PLT:
                plt.show()
            plt.close()

    df_pcf = df.loc[(df['transaction'] == "GetAccessAndMobilityPolicyData") |
                    (df['transaction'] == "GetSessionManagementPolicyData")]
    pcf_trans_order = [
        "GetAccessAndMobilityPolicyData",
        "GetSessionManagementPolicyData",
    ]
    for nf in ['pcf', 'udr']:
        df_nf = df_pcf.loc[df['NF'] == nf]
        y_labels = [
            "Envoy Request Processing Time (ms)",
            "Envoy Response Processing Time (ms)",
            "Envoy Total Processing Time (ms)", "Total Duration (ms)"
        ]
        y_values = [
            "rqst_proc_time", "rspn_proc_time", "envoy_proc_time", "duration"
        ]
        for ynum, y in enumerate(y_values):
            fig, ax = plt.subplots()
            ax = sns.barplot(df_nf,
                             x='sessionCount',
                             y=y,
                             hue='transaction',
                             hue_order=pcf_trans_order,
                             order=numSessions)
            lgnd_labels = []
            for i, lglb in enumerate(pcf_trans_order):
                lgnd_labels.append(
                    mpatches.Patch(facecolor=flatui[i],
                                   label=pcf_trans_order[i],
                                   hatch=hatch_list[i]))
            lines, labels = ax.get_legend_handles_labels()
            ax.legend(lines, handles=lgnd_labels, loc='best')
            unique_vals = len(df_nf["sessionCount"].unique().tolist())
            hatches = itertools.cycle(hatch_list)
            for i, bar in enumerate(ax.patches):
                if i % unique_vals == 0:
                    hatch = next(hatches)
                bar.set_hatch(hatch)
            plt.xlabel('Simultaneous Requests')
            plt.ylabel(y_labels[ynum])
            plt.tight_layout()
            plt.savefig('{}/{}_{}.{}'.format(IstioCsvLogFileDir, nf, y,
                                             file_format),
                        bbox_inches='tight')
            if SHOW_PLT:
                plt.show()
            plt.close()

    df_nf = df.loc[(df['transaction'] != "unknown")
                   & (df['direction'] == "inbound")]
    unique_inbound_trans = df_nf["transaction"].unique().tolist()
    inbounf_nf_list = []
    for trans in unique_inbound_trans:
        inbounf_nf_list.append(df_nf.loc[df_nf['transaction'] == trans]
                               ["NF"].unique().tolist()[0])
    unique_inbound_trans_labels = []
    for i, trans in enumerate(unique_inbound_trans):
        unique_inbound_trans_labels.append("{} ({})".format(
            trans, inbounf_nf_list[i].upper()))
    fig, ax = plt.subplots()
    ax = sns.barplot(df_nf,
                     x='sessionCount',
                     y='nfProcessTime',
                     hue='transaction',
                     hue_order=unique_inbound_trans,
                     order=numSessions)
    lgnd_labels = []
    for i, lglb in enumerate(unique_inbound_trans):
        lgnd_labels.append(
            mpatches.Patch(facecolor=flatui[i],
                           label=unique_inbound_trans_labels[i],
                           hatch=hatch_list[i]))
    lines, labels = ax.get_legend_handles_labels()
    ax.legend(lines, handles=lgnd_labels, loc='best')
    unique_vals = len(df_nf["sessionCount"].unique().tolist())
    hatches = itertools.cycle(hatch_list)
    for i, bar in enumerate(ax.patches):
        if i % unique_vals == 0:
            hatch = next(hatches)
        bar.set_hatch(hatch)
    plt.xlabel('Simultaneous Requests')
    plt.ylabel('NF Processing Time (ms)')
    plt.tight_layout()
    plt.savefig('{}/inbound_{}.{}'.format(IstioCsvLogFileDir, 'nfProcessTime',
                                          file_format),
                bbox_inches='tight')
    if SHOW_PLT:
        plt.show()
    plt.close()

    df.to_csv(IstioCsvLogFile.replace(".csv", "Processed.csv"), index=False)

#aggregate_istio_logs()
plot_from_istio_logs()
