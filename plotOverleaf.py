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

CREATE_COMPARISON_CSVS = 1
FIGURE3 = 1
FIGURE4 = 1
FIGURE5 = 1
FIGURE6 = 1
FIGURE7 = 1

dict_map = {"Fully-Stateful": {"amfTimeTaken": [], "plotname": "Stateful", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [i for i in range(1, 11)], "amfQueueLength": 0},
            "Fully-Procedural-Stateless": {"amfTimeTaken": [], "plotname": "Procedural Stateless", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [], "amfQueueLength": 0},
            "Fully-Transactional-Stateless": {"amfTimeTaken": [], "plotname": "Transactional Stateless", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 3, 4, 6, 8], "amfQueueLength": 0},
            "Nonblocking-Api-Enabled": {"amfTimeTaken": [], "plotname": "Non-Blocking", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 3, 4, 7, 8, 9, 10], "amfQueueLength": 0},
            "N1n2-Amf-Update-Api-Disabled": {"amfTimeTaken": [], "plotname": "Delete-Create API", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [], "amfQueueLength": 0},
            "Amf-Smf-Share-Udsf": {"amfTimeTaken": [], "plotname": "AMF-SMF Share Database", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [1, 2, 4, 5, 7, 8, 9], "amfQueueLength": 0},
            "All-NFs-Share-Udsf": {"amfTimeTaken": [], "plotname": "All NFs Share Database", "amfDbReadTime": [], "amfDbWriteTime": [], "amfDbTotalTime": [], "valied_1000_runs": [], "amfQueueLength": 0}
            }

dict_map_keys = list(dict_map.keys()).copy()
session_list = [i*100 for i in range(1,11)]

def plot_q_cpu_instance(ax,df_t,df_q,NF,label=False):
    
    df_t = df_t[['Time (ms)','CPU-Usage']]
    df_t = df_t.set_index('Time (ms)')
    #print(df_t.head())

    df_t['CPU-Usage'] = df_t['CPU-Usage'].astype(int)
    from matplotlib.ticker import MaxNLocator
    ax1 = df_t['CPU-Usage'].plot(ax=ax,label='CPU',marker='x',style='#34495e')
    ax1.set_ylabel('CPU (%)')
    ax1.yaxis.set_major_locator(MaxNLocator(integer=True,nbins=4))
    # ax1.yaxis.set_major_formatter(PercentFormatter(100))  # percentage using 1 for 100%

    df_q = df_q[['Time (ms)','Q Length']]
    df_q = df_q.set_index('Time (ms)')
    #print(df_q.head())

    df_q['Q Length'].plot(secondary_y=True,style="#2ecc71",ax=ax)
    ax1.right_ax.set_ylabel('Q Length')
    #sb.set_ylim(5,16)
    if NF == "UPF":
        #ax1.right_ax.set_ylim(-0.1,1)
        ck = [0,1]
        ax1.right_ax.set_yticks(ck)
        #ax1.right_ax.set_yticks(np.arange(min(ck), max(ck)+10, 10))

    if label == True:
        lines = ax.get_lines() + ax.right_ax.get_lines()
        ax.legend(lines, [l.get_label() for l in lines], loc='lower center',frameon=True,ncol=2)

    ax.set_title(NF, y=1.0, pad=-14, x=.051)


def q_cpu_time_series():

    fig, ax = plt.subplots()
    gs = gridspec.GridSpec(3, 1, height_ratios=[1, 1, 1],hspace=.1)

    ax0 = 0
    pos =0
    cpu_file = "{}/Results2/Fully-Transactional-Stateless-6/1000/topCpuOp".format(path)
    qlen_file = "{}/Results2/Fully-Transactional-Stateless-6/1000/queueLen".format(path)
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
        df_q = df_q[df_q['Time (ms)'] < 15000]

        df_t = pd.read_csv(t_path)
        df_t.columns = ['UTC-Time','Time (ms)','CPU-Usage']
        df_t = df_t[df_t['Time (ms)'] < 15000]
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

    plt.savefig('figure7.pdf', bbox_inches='tight', pad_inches=0)
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
                    df_new["amfDbTotalTime"] = col_values
            df_all = df_all.append(df_new, ignore_index=True)
            prev_mean_index = this_mean_index+1
        df.to_csv(csv_file, index=False)
    df_all.to_csv("op.csv", index=False)
    
    valid_cpuq_folders = []
    cpu_q_values = []
    for folder_name in dict_map_keys:
        val_1000_runs = dict_map[folder_name]["valied_1000_runs"]
        mean_cpus = []
        if val_1000_runs:
            for sub_folder in val_1000_runs:
                cpu_file_name = "{}/Results2/{}-{}/1000/topCpuOp.csv".format(path, folder_name, sub_folder)
                df_cpu_sub = pd.read_csv(cpu_file_name)
                mean_cpus.append(df_cpu_sub[df_cpu_sub[" CPU-Usage"] > 0][" CPU-Usage"].mean())
            cpu_q_values.append(dict_map[folder_name]["amfQueueLength"])
            cpu_q_values.append(np.mean(mean_cpus))
            valid_cpuq_folders.append(dict_map[folder_name]["plotname"])
            valid_cpuq_folders.append(dict_map[folder_name]["plotname"])
    df_queue_cpu = pd.DataFrame()
    df_queue_cpu["Rate"] = [1000]*8
    df_queue_cpu["Type"] = ["Q Length", "CPU"]*4
    df_queue_cpu["Config"] = valid_cpuq_folders
    df_queue_cpu["Value"] = cpu_q_values


    if CREATE_COMPARISON_CSVS:

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[0]): dict_map[dict_map_keys[0]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[2]): dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-{}".format(dict_map_keys[2])] - df["Time-{}".format(dict_map_keys[0])])*(100/(df["Time-{}".format(dict_map_keys[0])]))
        df1 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[0]): "-", "Time-{}".format(dict_map_keys[2]): "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df1.to_csv("Stateful-Vs-Stateless-TimeTaken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[1]): dict_map[dict_map_keys[1]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[2]): dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-{}".format(dict_map_keys[2])] - df["Time-{}".format(dict_map_keys[1])])*(100/(df["Time-{}".format(dict_map_keys[1])]))
        df2 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[1]): "-", "Time-{}".format(dict_map_keys[2]): "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df2.to_csv("Procedural-Vs-Transactional-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[3]): dict_map[dict_map_keys[3]]["amfTimeTaken"], "Time-Blocking-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Blocking-Api-Enabled"] - df["Time-{}".format(dict_map_keys[3])])*(100/(df["Time-{}".format(dict_map_keys[3])]))
        df3 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[3]): "-", "Time-Blocking-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df3.to_csv("Blocking-Vs-Nonblocking-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfTimeTaken"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df4 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df4.to_csv("Update-Vs-Delete-Create-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-{}".format(dict_map_keys[5]): dict_map[dict_map_keys[5]]["amfTimeTaken"], "Time-{}".format(dict_map_keys[6]): dict_map[dict_map_keys[6]]["amfTimeTaken"], "Time-Not-Sharing-Udsf": dict_map[dict_map_keys[2]]["amfTimeTaken"], "Change - AmfSmf Vs Unshared": [0]*10, "Change - AllShared Vs Unshared": [0]*10})
        df['Change - AmfSmf Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[5])])*(100/(df["Time-{}".format(dict_map_keys[5])]))
        df['Change - AllShared Vs Unshared'] = (df["Time-Not-Sharing-Udsf"] - df["Time-{}".format(dict_map_keys[6])])*(100/(df["Time-{}".format(dict_map_keys[6])]))
        df5 = df.append({"Number-of-Sessions": "Average", "Time-{}".format(dict_map_keys[5]): "-", "Time-{}".format(dict_map_keys[6]): "-", "Time-Not-Sharing-Udsf": "-", 'Change - AmfSmf Vs Unshared': np.mean(df["Change - AmfSmf Vs Unshared"].values), 'Change - AllShared Vs Unshared': np.mean(df["Change - AllShared Vs Unshared"].values)}, ignore_index=True)
        df5.to_csv("Shared-Vs-Unshared-Udsf-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbReadTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbReadTime"], "Change %": [0]*len(dict_map[dict_map_keys[2]]["amfDbReadTime"])})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Read-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbWriteTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbWriteTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Write-Time-Taken.csv", index=False)

        df = pd.DataFrame({"Number-of-Sessions": session_list, "Time-Delete-Create-Api-Enabled": dict_map[dict_map_keys[4]]["amfDbTotalTime"], "Time-Update-Api-Enabled": dict_map[dict_map_keys[2]]["amfDbTotalTime"], "Change %": [0]*10})
        df['Change %'] = (df["Time-Update-Api-Enabled"] - df["Time-Delete-Create-Api-Enabled"])*(100/(df["Time-Delete-Create-Api-Enabled"]))
        df6 = df.append({"Number-of-Sessions": "Average", "Time-Delete-Create-Api-Enabled": "-", "Time-Update-Api-Enabled": "-", 'Change %': np.mean(df["Change %"].values)}, ignore_index=True)
        df6.to_csv("Update-Vs-Delete-Create-Db-Total-Time-Taken.csv", index=False)


    df_plot = df_all[df_all['Rate'] > 500]

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
        plt.savefig('figure3.pdf', bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE4:
        config_filter = [dict_map_keys[5], dict_map_keys[6], dict_map_keys[3], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = [ "#3498db","#95a5a6", "#34495e", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfTimeTaken', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(8,16)
        plt.ylabel('Time (s)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure4.pdf', bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE5:
        config_filter = [dict_map_keys[4], dict_map_keys[2]]
        order_list = [dict_map[x]["plotname"] for x in config_filter]
        flatui = ["#3498db", "#2ecc71"]
        sns.set_palette(flatui)
        sb = sns.barplot(data=df_plot, x='Rate', y='amfDbTotalTime', hue='Config', palette=flatui, hue_order=order_list)
        sb.set_ylim(550,1000)
        l1 = mpatches.Patch(color=flatui[0], label='Delete-Create API')
        l2 = mpatches.Patch(color=flatui[1], label='Update API')
        plt.ylabel('Time (ms)')
        plt.xlabel("Simultaneous Requests")
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best", handles=[l1,l2])
        plt.savefig('figure5.pdf', bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
    
    if FIGURE6:

        def get_plt_name(x):
            if x == 'AMF-SMF Share Database':
                return 'AMF-SMF\nShare DB'

            if x == 'Transactional Stateless':
                return 'Transactional\nStateless'

            return x
        
        df_queue_cpu['Config'] = df_queue_cpu['Config'].apply(get_plt_name)
        df_queue_cpu['Type'] = df_queue_cpu['Type'].apply(lambda x: x.replace('QLEN','Q Length'))

        fig, ax1 = plt.subplots()
        flatui = ["#34495e","#2ecc71"]
        sns.set_context(context="paper",font_scale=1)
        sb = sns.barplot(data=df_queue_cpu, x='Config', y='Value', hue='Type',palette=sns.color_palette(flatui),
                        ax=ax1,hue_order=['CPU','Q Length'],
                        order = ['Stateful','Transactional\nStateless','AMF-SMF\nShare DB','Non-Blocking'])
        ax1.set_ylabel('CPU', fontsize=12)
        ax2 = ax1.twinx()
        ax2.set_ylim(ax1.get_ylim())
        ax1.yaxis.set_major_formatter(PercentFormatter(100)) # percentage using 1 for 100%
        ax1.tick_params(labelsize=12)
        ax2.tick_params(labelsize=12)
        ax2.set_ylabel('Queue Length', fontsize=12)
        ax1.set_xlabel('')
        sb.legend_.set_title(None)
        plt.tight_layout()
        plt.legend(loc="best")
        plt.savefig('figure6.pdf', bbox_inches='tight', pad_inches=0)
        plt.show()
        plt.close()
        sns.set_context(context="paper",font_scale=1.6)
    
    if FIGURE7:
        q_cpu_time_series()


if __name__ == "__main__":
    main()

