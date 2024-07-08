#!/usr/bin/env python3

import os
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib import gridspec
from matplotlib.ticker import PercentFormatter
import seaborn as sns

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42
sns.set_context(context="paper", font_scale=1.6)
file_format = "pdf"

my_dir_path = os.path.dirname(os.path.realpath(__file__))
my_dir = "/Users/umakantkulkarni/Library/CloudStorage/OneDrive-purdue.edu/Research/5gSec/Summer2024/ExpResults"
exp_dir = os.path.join(my_dir, "Experiments")

exp_csv_file = os.path.join(exp_dir, "exp-data.csv")
df_read = pd.read_csv(exp_csv_file)
df = df_read.dropna()
print(df)
df['AverageRegTime'] = df['AverageTotalRegTime'] / 1000000
df['AveragePduEstTime'] = df['AverageTotalPduEstTime'] / 1000000


df["mode"] = -1
df.loc[df["experiment"] == "allSecure", "mode"] = "All Secured"
df.loc[df["experiment"] == "allSecure2", "mode"] = "All Secured"
df.loc[df["experiment"] == "allSecure3", "mode"] = "All Secured"
df.loc[df["experiment"] == "unecured", "mode"] = "UnSecured"
df.loc[df["experiment"] == "ranSecure", "mode"] = "RAN Secured"
df.loc[df["experiment"] == "pfcpSecure", "mode"] = "PFCP Secured"
df.loc[df["experiment"] == "pfcpSecure3", "mode"] = "PFCP Secured"
df.loc[df["experiment"] == "coreSecure", "mode"] = "Core Secured"
df.loc[df["experiment"] == "coreSecure2", "mode"] = "Core Secured"
df.loc[df["experiment"] == "coreSecure3", "mode"] = "Core Secured"
df.loc[df["experiment"] == "istioSec", "mode"] = "Istio"

cmap = plt.colormaps["Set1"]
# Extract tht colors as a list
colors = list(cmap.colors)
color_plte = sns.color_palette("tab10")


if 1:
    exp_plot_order = ["UnSecured", "RAN Secured", "PFCP Secured", "Core Secured", "All Secured","Istio"]
    exp_labels = exp_plot_order

    df_plot = df[df['UePassed'] >= 0.8 * df['numSessions']]
    flatui = colors[:len(exp_plot_order)]
    #sns.set_palette(flatui)

    fig, ax = plt.subplots(figsize=(12,5))
    sb = sns.barplot(data=df_plot,
                     x='numSessions',
                     y='amfTimeTaken',
                     hue='mode',
                     palette=color_plte,errorbar=None,
                     hue_order=exp_plot_order)
    plt.ylabel('Session Setup Time (s)')
    plt.xlabel("Simultaneous Requests")
    sb.legend_.set_title(None)
    plt.tight_layout()
    plt.legend(loc="best")
    handles, _ = sb.get_legend_handles_labels()
    sb.legend(handles, exp_labels)
    plt_file_name = os.path.join(my_dir, "time_plot_all.{}".format(file_format))
    plt.savefig(plt_file_name, bbox_inches='tight')
    plt.show()
    sb.clear()
    plt.close()

if 1:
    exp_plot_order = ["Core Secured", "Istio"]
    exp_labels = ["ZTX-SEM", "Istio"]

    df_plot = df[df['UePassed'] >= 0.8 * df['numSessions']]
    flatui = colors[:len(exp_plot_order)]
    #sns.set_palette(flatui)

    fig, ax = plt.subplots(figsize=(8,5))
    sb = sns.barplot(data=df_plot,
                     x='numSessions',
                     y='amfTimeTaken',
                     hue='mode',
                     palette=color_plte,capsize=.1,
                     hue_order=exp_plot_order)
    plt.ylabel('Session Setup Time (s)')
    plt.xlabel("Simultaneous Requests")
    sb.legend_.set_title(None)
    plt.tight_layout()
    plt.legend(loc="best")
    handles, _ = sb.get_legend_handles_labels()
    sb.legend(handles, exp_labels)
    plt_file_name = os.path.join(my_dir, "time_plot.{}".format(file_format))
    plt.savefig(plt_file_name, bbox_inches='tight')
    plt.show()
    sb.clear()
    plt.close()

    fig, ax = plt.subplots(figsize=(8,5))
    sb = sns.barplot(data=df_plot,
                     x='numSessions',
                     y='AverageRegTime',
                     hue='mode',
                     palette=color_plte,capsize=.1,
                     hue_order=exp_plot_order)
    plt.ylabel('UE Registration Time (s)')
    plt.xlabel("Simultaneous Requests")
    sb.legend_.set_title(None)
    plt.tight_layout()
    plt.legend(loc="best")
    handles, _ = sb.get_legend_handles_labels()
    sb.legend(handles, exp_labels)
    plt_file_name = os.path.join(my_dir, "avg_reg_time.{}".format(file_format))
    plt.savefig(plt_file_name, bbox_inches='tight')
    plt.show()
    sb.clear()
    plt.close()

    fig, ax = plt.subplots(figsize=(8,5))
    sb = sns.barplot(data=df_plot,
                     x='numSessions',
                     y='AveragePduEstTime',
                     hue='mode',
                     palette=color_plte,capsize=.1,
                     hue_order=exp_plot_order)
    plt.ylabel('PDU Session Establishment Time (s)')
    plt.xlabel("Simultaneous Requests")
    sb.legend_.set_title(None)
    plt.tight_layout()
    plt.legend(loc="best")
    handles, _ = sb.get_legend_handles_labels()
    sb.legend(handles, exp_labels)
    plt_file_name = os.path.join(my_dir, "avg_pdu_time.{}".format(file_format))
    plt.savefig(plt_file_name, bbox_inches='tight')
    plt.show()
    sb.clear()
    plt.close()

    if 1:
        for nf in ["amf", "smf"]:
            param = "{}QueueLength".format(nf)
            sb = sns.barplot(data=df_plot,
                            x='numSessions',
                            y=param,
                            hue='mode',
                            palette=flatui,
                            hue_order=exp_plot_order)
            plt.ylabel('{} Queue Length'.format(nf.upper()))
            plt.xlabel("Simultaneous Requests")
            sb.legend_.set_title(None)
            plt.tight_layout()
            plt.legend(loc="best")
            plt_file_name = os.path.join(my_dir, "{}.{}".format(param, file_format))
            plt.savefig(plt_file_name, bbox_inches='tight')
            plt.show()
            plt.close()
