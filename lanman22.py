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
sns.set_context(context="paper",font_scale=1.6)

dir_path = os.path.dirname(os.path.realpath(__file__))
my_file_name = os.path.basename(__file__)
path = Path("{}/{}".format(dir_path, my_file_name)).parent.parent
file_format = "pdf"

CREATE_COMPARISON_CSVS = 0
MIN_MAX_COMPARISON = 0
FIGURE3 = 0
FIGURE4 = 0
FIGURE_NEW = 0
FIGURE4_COMBINED = 0
FIGURE4_1 = 0
FIGURE4_2 = 0
FIGURE5 = 0
FIGURE6 = 1
FIGURE7 = 0
FIGURE8 = 0

dict_map = {"Fully-Stateful": {"amfTimeTaken": [], "plotname": "Stateful", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [i for i in range(1, 11)], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Fully-Procedural-Stateless": {"amfTimeTaken": [], "plotname": "Procedural Stateless", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Fully-Transactional-Stateless": {"amfTimeTaken": [], "plotname": "Transactional Stateless", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [2], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Nonblocking-Api-Enabled": {"amfTimeTaken": [], "plotname": "Non-Blocking", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 3, 4, 7, 8, 9, 10], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "N1n2-Amf-Update-Api-Disabled": {"amfTimeTaken": [], "plotname": "Delete-Create API", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Amf-Smf-Share-Udsf": {"amfTimeTaken": [], "plotname": "AMF-SMF Share Database", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [8], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "All-NFs-Share-Udsf": {"amfTimeTaken": [], "plotname": "All NFs Share Database", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 6, 9], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Upsert-Api-Enabled": {"amfTimeTaken": [], "plotname": "Non-Blocking", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Replace-Api-Enabled": {"amfTimeTaken": [], "plotname": "Replace API", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [2, 3], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "Single-Read-Enabled": {"amfTimeTaken": [], "plotname": "Embedding Read Data", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [2], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            "NAE-Amf-Upf": {"amfTimeTaken": [], "plotname": "Non-Blocking", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "amfQueueLength": 0, "amfMinTime": [], "amfMaxTime": [], "dbMinTime": [], "dbMaxTime": []},
            }

dict_map_keys = list(dict_map.keys()).copy()
dict_map_keys = ["Fully-Transactional-Stateless", "Amf-Smf-Share-Udsf", "Single-Read-Enabled"]
session_list = [i*100 for i in range(1,11)]

def calc_min_max (i,j,param="amfTime"):
    if param == "amfTime":
        p1 = "amfMaxTime"
        p2 = "amfMinTime"
    elif param == "dbTime":
        p1 = "dbMaxTime"
        p2 = "dbMinTime"
    a = dict_map[dict_map_keys[j]][p1]
    b = dict_map[dict_map_keys[i]][p2]
    max_diff = np.mean([(a_i - b_i)*(100/b_i) for a_i, b_i in zip(a, b)])
    print("Max time difference between {} and {} is {}".format(dict_map_keys[j], dict_map_keys[i], max_diff))

def plot_q_cpu_instance(ax,df_t,df_q,NF,label=False):
    
    df_t = df_t[['Time (ms)','CPU-Usage']]
    df_t = df_t.set_index('Time (ms)')
    #print(df_t.head())

    df_t['CPU-Usage'] = df_t['CPU-Usage'].astype(int)
    from matplotlib.ticker import MaxNLocator
    ax1 = df_t['CPU-Usage'].plot(ax=ax,label='CPU',marker='x',style='#34495e',ms=4)
    ax1.set_ylabel('CPU (%)', fontsize=13)
    ax1.yaxis.set_major_locator(MaxNLocator(integer=True,nbins=4))
    # ax1.yaxis.set_major_formatter(PercentFormatter(100))  # percentage using 1 for 100%

    df_q = df_q[['Time (ms)','Q Length']]
    df_q = df_q.set_index('Time (ms)')
    #print(df_q.head())

    df_q['Q Length'].plot(secondary_y=True,style="#2ecc71",ax=ax)
    ax1.right_ax.set_ylabel('Q Length', fontsize=13)
    #sb.set_ylim(5,16)
    if NF == "UPF":
        #ax1.right_ax.set_ylim(-0.1,1)
        ck = [0,1]
        ax1.right_ax.set_yticks(ck, fontsize=13)
        #ax1.right_ax.set_yticks(np.arange(min(ck), max(ck)+10, 10))

    if label == True:
        lines = ax.get_lines() + ax.right_ax.get_lines()
        ax.legend(lines, [l.get_label() for l in lines], loc='upper left',frameon=True,ncol=1, fontsize=11, bbox_to_anchor=(0,1.035))

    #ax.set_title(NF, y=1.0, pad=-14, x=.051)
    ax.set_title(NF, y=1.02, pad=-14, x=.5835, fontsize=13)
    #ax.set_title(NF, y=1.02, pad=-14, x=.5, fontsize=13)


def q_cpu_time_series():

    fig, ax = plt.subplots()
    gs = gridspec.GridSpec(3, 1, height_ratios=[1, 1, 1],hspace=.1)

    ax0 = 0
    pos =0
    #cpu_file = "{}/Results/Fully-Transactional-Stateless-2/1000/topCpuOp".format(path)
    #qlen_file = "{}/Results/Fully-Transactional-Stateless-2/1000/queueLen".format(path)
    #cpu_file = "{}/Results/Amf-Smf-Share-Udsf-8/1000/topCpuOp".format(path)
    #qlen_file = "{}/Results/Amf-Smf-Share-Udsf-8/1000/queueLen".format(path)
    cpu_file = "{}/Results/Single-Read-Enabled-2/1000/topCpuOp".format(path)
    qlen_file = "{}/Results/Single-Read-Enabled-2/1000/queueLen".format(path)
    for item in ['AMF','SMF','UPF']:

        if item == "AMF":
            q_path = "{}.csv".format(qlen_file)
            t_path = "{}.csv".format(cpu_file)
        elif item == "SMF":
            q_path = "{}Smf.csv".format(qlen_file)
            t_path = "{}Smf.csv".format(cpu_file)
        elif item == "UPF":
            q_path = "{}Upf.csv".format(qlen_file)
            t_path = "{}Upf.csv".format(cpu_file)

        df_q = pd.read_csv(q_path)
        df_q.columns = ['UTC-Time','Time (ms)','Q Length']
        # df_q = df_q.head(1000)
        #print (df_q.head())
        df_q = df_q[df_q['Time (ms)'] < 10100]

        df_t = pd.read_csv(t_path)
        df_t.columns = ['UTC-Time','Time (ms)','CPU-Usage']
        df_t = df_t[df_t['Time (ms)'] < 10100]
        #print (df_t.head())

        if pos == 0:
            ax = plt.subplot(gs[pos])
            plot_q_cpu_instance(ax, df_t,df_q, item)
            ax0 = ax
        elif pos == 1:
            ax = plt.subplot(gs[pos], sharex=ax0)
            plot_q_cpu_instance(ax, df_t,df_q, item)
        elif pos == 2:
            ax = plt.subplot(gs[pos], sharex=ax0)
            plot_q_cpu_instance(ax, df_t, df_q, item,label=True)
        #plt.tight_layout()
        plt.subplots_adjust(hspace=.0,top = 0.96)
        pos+=1

    plt.savefig('figure7.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
    plt.show()
    plt.close()

def main():

    df_all = pd.DataFrame()
    df_all["amfTimeTaken"] = [-1]
    df_all["Config"] = [-1]
    df_all["Sessions"] = [-1]
    df_all["amfDbReadTime"] = [-1]
    df_all["amfDbWriteTime"] = [-1]
    df_all["amfDbTotalTime"] = [-1]
    df_all["Rate"] = [-1]
    for folder_name in dict_map_keys:
        print("folder_name is ", folder_name)
        csv_file = "{}-data.csv".format(folder_name)
        df = pd.read_csv(csv_file)
        prev_mean_index = 0
        for row_section in session_list:
            this_mean_index = df.index[df["numSessions"]=="Mean-{}".format(row_section)].values[0]
            for col in list(df.columns.values)[1:]:
                col_values = list(df[prev_mean_index:this_mean_index][col].values).copy()
                col_mean = np.mean(col_values)
                df[col].values[this_mean_index] = col_mean
                if col == "amfTimeTaken":
                    dict_map[folder_name]["amfTimeTaken"].append(col_mean)
                    dict_map[folder_name]["amfMinTime"].append(min(col_values))
                    dict_map[folder_name]["amfMaxTime"].append(max(col_values))
                    df_new = pd.DataFrame()
                    df_new["amfTimeTaken"] = col_values
                    df_new["Config"] = dict_map[folder_name]["plotname"]
                    df_new["Sessions"] = row_section
                    df_new["Rate"] = row_section
                if row_section == 1000:
                    if col == "amfQueueLength":
                        dict_map[folder_name]["amfQueueLength"] = col_mean
                if col == "amfDbReadTime":
                    dict_map[folder_name]["amfDbReadTime"].append(col_mean)
                    df_new["amfDbReadTime"] = col_values
                elif col == "amfDbWriteTime":
                    dict_map[folder_name]["amfDbWriteTime"].append(col_mean)
                    df_new["amfDbWriteTime"] = col_values
                elif col == "amfDbTotalTime":
                    dict_map[folder_name]["amfDbTotalTime"].append(col_mean)
                    dict_map[folder_name]["dbMinTime"].append(min(col_values))
                    dict_map[folder_name]["dbMaxTime"].append(max(col_values))
                    df_new["amfDbTotalTime"] = col_values
            df_all = df_all.append(df_new, ignore_index=True)
            prev_mean_index = this_mean_index+1
        df.to_csv(csv_file, index=False)
    df_all.to_csv("op.csv", index=False)
    
    if FIGURE6:
        valid_cpuq_folders = []
        cpu_q_values = []
        for folder_name in dict_map_keys:
            val_1000_runs = dict_map[folder_name]["valied_1000_runs"]
            mean_cpus = []
            if val_1000_runs:
                for sub_folder in val_1000_runs:
                    cpu_file_name = "{}/Results/{}-{}/1000/topCpuOp.csv".format(path, folder_name, sub_folder)
                    df_cpu_sub = pd.read_csv(cpu_file_name)
                    mean_cpus.append(df_cpu_sub[df_cpu_sub[" CPU-Usage"] > 0][" CPU-Usage"].mean())
                cpu_q_values.append(dict_map[folder_name]["amfQueueLength"])
                cpu_q_values.append(np.mean(mean_cpus))
                valid_cpuq_folders.append(dict_map[folder_name]["plotname"])
                valid_cpuq_folders.append(dict_map[folder_name]["plotname"])
        df_queue_cpu = pd.DataFrame()
        df_queue_cpu["Rate"] = [1000]*6
        df_queue_cpu["Type"] = ["Q Length", "CPU"]*3
        df_queue_cpu["Config"] = valid_cpuq_folders
        df_queue_cpu["Value"] = cpu_q_values

    if MIN_MAX_COMPARISON:
        calc_min_max(6,2)
        calc_min_max(8,2)
        calc_min_max(8,2,"dbTime")
        calc_min_max(9,2)
        calc_min_max(9,6)
        if 0:
            calc_min_max(0,1)
            calc_min_max(0,2)
            calc_min_max(3,2)
            calc_min_max(4,2)
            calc_min_max(5,2)
            calc_min_max(6,2)
            calc_min_max(4,2,"dbTime")
            calc_min_max(9,2)
            calc_min_max(9,6)
            calc_min_max(10,2)


    if CREATE_COMPARISON_CSVS:

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[0]): dict_map[dict_map_keys[0]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[2]): dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-{}".format(dict_map_keys[2])] - df["Time-{}".format(dict_map_keys[0])])*(100/(df["Time-{}".format(dict_map_keys[0])]))
        df1 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[0]): "-", "Time-{}".format(dict_map_keys[2]): "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df1.to_csv("Stateful-Vs-Stateless-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[0]): dict_map[dict_map_keys[0]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[1]): dict_map[dict_map_keys[1]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-{}".format(dict_map_keys[1])] - df["Time-{}".format(dict_map_keys[0])])*(100/(df["Time-{}".format(dict_map_keys[0])]))
        df1 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[0]): "-", "Time-{}".format(dict_map_keys[1]): "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df1.to_csv("Stateful-Vs-Procedural-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[1]): dict_map[dict_map_keys[1]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[2]): dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-{}".format(dict_map_keys[2])] - df["Time-{}".format(dict_map_keys[1])])*(100/(df["Time-{}".format(dict_map_keys[1])]))
        df2 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[1]): "-", "Time-{}".format(dict_map_keys[2]): "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df2.to_csv("Procedural-Vs-Transactional-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[3]): dict_map[dict_map_keys[3]]["amfTimeTaken"], "Time-Blocking-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Blocking-Api-Enabled"] - df["Time-{}".format(dict_map_keys[3])])*(100/(df["Time-{}".format(dict_map_keys[3])]))
        df3 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[3]): "-", "Time-Blocking-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df3.to_csv("Blocking-Vs-Nonblocking-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfTimeTaken"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df4 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df4.to_csv("Update-Vs-Delete-Create-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[5]): dict_map[dict_map_keys[5]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[6]): dict_map[dict_map_keys[6]]["amfTimeTaken"], "Time-Not-Sharing-Udsf": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change - AmfSmf Vs Unshared": [0]*10, "Change - AllShared Vs Unshared": [0]*10})
        df['Change - AmfSmf Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[5])])*(100/(df["Time-{}".format(dict_map_keys[5])]))
        df['Change - AllShared Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[6])])*(100/(df["Time-{}".format(dict_map_keys[6])]))
        df5 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[5]): "-", "Time-{}".format(dict_map_keys[6]): "-", "Time-Not-Sharing-Udsf": "-", 'Change - AmfSmf Vs Unshared': np.mean(df["Change - AmfSmf Vs Unshared"].values), 'Change - AllShared Vs Unshared': np.mean(df["Change - AllShared Vs Unshared"].values)}, ignore_index=True)
        df5.to_csv("Shared-Vs-Unshared-Udsf-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbReadTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbReadTime"], "Change %": [0]*len(dict_map[dict_map_keys[2]]["amfDbReadTime"])})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Read-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbWriteTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbWriteTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Write-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbTotalTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbTotalTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Total-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[9]): dict_map[dict_map_keys[9]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[6]): dict_map[dict_map_keys[6]]["amfTimeTaken"], "Time-Not-Sharing-Udsf": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change - SingleRead Vs Unshared": [0]*10, "Change - AllShared Vs Unshared": [0]*10})
        df['Change - SingleRead Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[9])])*(100/(df["Time-{}".format(dict_map_keys[9])]))
        df['Change - AllShared Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[6])])*(100/(df["Time-{}".format(dict_map_keys[6])]))
        df9 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[9]): "-", "Time-{}".format(dict_map_keys[6]): "-", "Time-Not-Sharing-Udsf": "-", 'Change - SingleRead Vs Unshared': np.mean(df["Change - SingleRead Vs Unshared"].values), 'Change - AllShared Vs Unshared': np.mean(df["Change - AllShared Vs Unshared"].values)}, ignore_index=True)
        df9.to_csv("Single-Vs-Multiple-Read-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Upsert-Api-Enabled": dict_map[dict_map_keys[7]]["amfDbWriteTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbWriteTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Upsert-Api-Enabled"])*(100/(df["Time-Upsert-Api-Enabled"]))
        df7 = df.append({"Number-of-Sessions": "Average", "Time-Upsert-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df7.to_csv("Update-Vs-Upsert-Db-Write-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Replace-Api-Enabled": dict_map[dict_map_keys[8]]["amfTimeTaken"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Replace-Api-Enabled"])*(100/(df["Time-Replace-Api-Enabled"]))
        df8 = df.append({"Number-of-Sessions": "Average", "Time-Replace-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df8.to_csv("Update-Vs-Replace-Avg-Time-Taken.csv", index=False)        

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Replace-Api-Enabled": dict_map[dict_map_keys[8]]["amfDbWriteTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbWriteTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Replace-Api-Enabled"])*(100/(df["Time-Replace-Api-Enabled"]))
        df8 = df.append({"Number-of-Sessions": "Average", "Time-Replace-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df8.to_csv("Update-Vs-Replace-Db-Write-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Replace-Api-Enabled": dict_map[dict_map_keys[8]]["amfDbReadTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbReadTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Replace-Api-Enabled"])*(100/(df["Time-Replace-Api-Enabled"]))
        df8 = df.append({"Number-of-Sessions": "Average", "Time-Replace-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df8.to_csv("Update-Vs-Replace-Db-Read-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Replace-Api-Enabled": dict_map[dict_map_keys[8]]["amfDbTotalTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbTotalTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Replace-Api-Enabled"])*(100/(df["Time-Replace-Api-Enabled"]))
        df8 = df.append({"Number-of-Sessions": "Average", "Time-Replace-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df8.to_csv("Update-Vs-Replace-Db-Total-Avg-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[10]): dict_map[dict_map_keys[10]]["amfTimeTaken"], "Time-Blocking-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Blocking-Api-Enabled"] - df["Time-{}".format(dict_map_keys[10])])*(100/(df["Time-{}".format(dict_map_keys[10])]))
        df10 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[10]): "-", "Time-Blocking-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df10.to_csv("Blocking-Vs-Fully-Nonblocking-Avg-Time-Taken.csv", index=False)


    df_plot = df_all[df_all['Rate'] > 500].copy()

    if FIGURE3:
        config_filter = ['Fully-Stateful','Fully-Procedural-Stateless', 'Fully-Transactional-Stateless']
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db","#34495e", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(5,16)
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure3.{}'.format(file_format), bbox_inches='tight')
        plt.show()
        plt.close()
    
    if FIGURE4:
        config_filter = [dict_map_keys[9], dict_map_keys[6], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db", "#34495e", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(5,14)
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure4.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE_NEW:
        config_filter = [dict_map_keys[8], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(7,14)
        l1 = mpatches.Patch(color=flatui[0], label='Replace API')
        l2 = mpatches.Patch(color=flatui[1], label='Update API')
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best", handles=[l1,l2])
        plt.savefig('figure4_new.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()

    if FIGURE4_COMBINED:
        config_filter = [dict_map_keys[9], dict_map_keys[6], dict_map_keys[8], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db", "#95a5a6", "#34495e", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(5,14)
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure4_combined.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE4_1:
        config_filter = [dict_map_keys[5], dict_map_keys[6], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db","#95a5a6", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(8,16)
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure4_1.{}'.format(file_format), bbox_inches='tight')
        plt.show()
        plt.close()
    
    if FIGURE4_2:
        config_filter = [dict_map_keys[3], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#34495e", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(8,16)
        l1 = mpatches.Patch(color=flatui[0], label='Non-Blocking')
        l2 = mpatches.Patch(color=flatui[1], label='Blocking')
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best", handles=[l1,l2])
        plt.savefig('figure4_2.{}'.format(file_format), bbox_inches='tight')
        plt.show()
        plt.close()
    
    if FIGURE5:
        config_filter = [dict_map_keys[8], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = ["#3498db", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfDbTotalTime', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(450,950)
        l1 = mpatches.Patch(color=flatui[0], label='Replace API')
        l2 = mpatches.Patch(color=flatui[1], label='Update API')
        plt.ylabel('Time (ms)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best", handles=[l1,l2])
        plt.savefig('figure5.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE8:
        config_filter = [dict_map_keys[4], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        order_list[1] = "Update API"
        config_list = [order_list[0]]*5
        config_list.extend([order_list[1]]*5)
        df_mongo = pd.DataFrame()
        df_mongo["Config"] = config_list
        amfRdTime = dict_map[config_filter[0]]["amfDbReadTime"][5:].copy()
        amfRdTime.extend(dict_map[config_filter[1]]["amfDbReadTime"][5:].copy())
        amfWrTime = dict_map[config_filter[0]]["amfDbWriteTime"][5:].copy()
        amfWrTime.extend(dict_map[config_filter[1]]["amfDbWriteTime"][5:].copy())
        df_mongo["amfDbReadTime"] = amfRdTime
        df_mongo["amfDbWriteTime"] = amfWrTime
        df_mongo["Rate"] = session_list[5:]*2
        #ax = df_mongo.plot(x="Rate", y="amfDbWriteTime", kind="bar")
        #df_mongo.plot(x="Rate", y="amfDbReadTime", kind="bar", ax=ax, color="C2")
        #df_mongo[["Rate", "amfDbWriteTime", "amfDbReadTime"]].plot(x="Rate", kind="bar")
        df_mongo.set_index('Rate').plot(kind='bar', stacked=True, y = ["amfDbReadTime","amfDbWriteTime"], color=['steelblue', 'red'])
        plt.show()
    
    if FIGURE6:

        def get_plt_name(x):
            if x == 'AMF-SMF Share Database':
                return 'AMF-SMF\nShare DB'

            if x == 'Transactional Stateless':
                return 'Transactional\nStateless'
            
            if x == 'Embedding Read Data':
                return 'Embedding\nRead Data'

            return x
        
        df_queue_cpu['Config'] = df_queue_cpu['Config'].apply(get_plt_name)
        df_queue_cpu['Type'] = df_queue_cpu['Type'].apply(lambda x: x.replace('QLEN','Q Length'))

        fig, ax1 = plt.subplots()
        flatui = ["#34495e","#2ecc71"]
        sb = sns.barplot(data=df_queue_cpu, x='Config', y='Value', hue='Type',palette=sns.color_palette(flatui),
                        ax=ax1,hue_order=['CPU','Q Length'],
                        order = ['Transactional\nStateless','AMF-SMF\nShare DB', 'Embedding\nRead Data'])
        ax1.set_ylabel('CPU', fontsize=14)
        ax2 = ax1.twinx()
        ax2.set_ylim(ax1.get_ylim())
        ax1.yaxis.set_major_formatter(PercentFormatter(100)) # percentage using 1 for 100%
        ax1.tick_params(labelsize=13)
        ax2.tick_params(labelsize=13)
        ax2.set_ylabel('Queue Length', fontsize=14)
        ax1.set_xlabel('')
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best", fontsize=1)
        plt.savefig('figure6.{}'.format(file_format), bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE7:
        q_cpu_time_series()


if __name__ == "__main__":
    main()

