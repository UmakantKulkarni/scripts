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
my_dir = "/Users/umakantkulkarni/Library/CloudStorage/OneDrive-purdue.edu/Research/5gSec/Spring2024/Benchmarking1"
exp_dir = os.path.join(my_dir, "Experiments")

exp_csv_file = os.path.join(exp_dir, "exp-data.csv")
df = pd.read_csv(exp_csv_file)
df = df.rename(columns={'AllSecure2': 'AllSecure', 'CoreSecure2': 'CoreSecure'})
df['experiment'] = df['experiment'].replace(['AllSecure2'], 'AllSecure')
df['experiment'] = df['experiment'].replace(['CoreSecure2'], 'CoreSecure')
print(df)

exp_plot_order = [
    "Unsecured", "RanSecure", "PfcpSecure", "CoreSecure", "IstioSec",
    "AllSecure"
]
cmap = plt.colormaps["Set1"]
# Extract tht colors as a list
colors = list(cmap.colors)

exp_to_color_dict = {}
for i, exp in enumerate(exp_plot_order):
    exp_to_color_dict[exp] = colors[i]

if 1:
    df_plot = df[df['ueSessCount'] >= 0.8 * df['numSessions']]
    flatui = colors[:len(exp_plot_order)]
    sns.set_palette(flatui)

    sb = sns.barplot(data=df_plot,
                     x='numSessions',
                     y='amfTimeTaken',
                     hue='experiment',
                     palette=flatui,
                     hue_order=exp_plot_order)
    plt.ylabel('Time (s)')
    plt.xlabel("Simultaneous Requests")
    sb.legend_.set_title(None)
    plt.tight_layout()
    plt.legend(loc="best")
    plt_file_name = os.path.join(my_dir, "time_plot.{}".format(file_format))
    plt.savefig(plt_file_name, bbox_inches='tight')
    plt.show()
    plt.close()

    for nf in ["amf", "smf"]:
        param = "{}QueueLength".format(nf)
        sb = sns.barplot(data=df_plot,
                        x='numSessions',
                        y=param,
                        hue='experiment',
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
