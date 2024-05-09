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

def main():
    csv_file = 'ueTransTimes.csv'
    df = pd.read_csv(csv_file)
    #print(df)
    if 0:
        df['c_b'] =  df['epoch_create_end']-df['epoch_regcomp_ts1']
        df['d_b'] =  df['epoch_pfcpcreate_end']-df['epoch_regcomp_ts1']
        df['e_b'] =  df['epoch_n1n2_end']-df['epoch_regcomp_ts1']
        df['f_b'] =  df['epoch_pfcpupdate_end']-df['epoch_regcomp_ts1']
        df['g_b'] =  df['epoch_update_end']-df['epoch_regcomp_ts1']
        df['i_h'] =  df['epoch_create_end2']-df['epoch_regcomp_ts2']
        df['j_h'] =  df['epoch_pfcpcreate_end2']-df['epoch_regcomp_ts2']
        df['k_h'] =  df['epoch_n1n2_end2']-df['epoch_regcomp_ts2']
        df['l_h'] =  df['epoch_pfcpupdate_end2']-df['epoch_regcomp_ts2']
        df['m_h'] =  df['epoch_update_end2']-df['epoch_regcomp_ts2']
        df['o_n'] =  df['epoch_create_end3']-df['epoch_regcomp_ts3']
        df['p_n'] =  df['epoch_pfcpcreate_end3']-df['epoch_regcomp_ts3']
        df['q_n'] =  df['epoch_n1n2_end3']-df['epoch_regcomp_ts3']
        df['r_n'] =  df['epoch_pfcpupdate_end3']-df['epoch_regcomp_ts3']
        df['s_n'] =  df['epoch_update_end3']-df['epoch_regcomp_ts3']
    if 1:
        df['c_b'] =  df['epoch_create_end']-df['epoch_create_start']
        df['d_b'] =  df['epoch_pfcpcreate_end']-df['epoch_create_end']
        df['e_b'] =  df['epoch_n1n2_end']-df['epoch_pfcpcreate_end']
        df['f_b'] =  df['epoch_pfcpupdate_end']-df['epoch_n1n2_end']
        df['g_b'] =  df['epoch_update_end']-df['epoch_pfcpupdate_end']
        df['i_h'] =  df['epoch_create_end2']-df['epoch_create_start2']
        df['j_h'] =  df['epoch_pfcpcreate_end2']-df['epoch_create_end2']
        df['k_h'] =  df['epoch_n1n2_end2']-df['epoch_pfcpcreate_end2']
        df['l_h'] =  df['epoch_pfcpupdate_end2']-df['epoch_n1n2_end2']
        df['m_h'] =  df['epoch_update_end2']-df['epoch_pfcpupdate_end2']
        df['o_n'] =  df['epoch_create_end3']-df['epoch_create_start3']
        df['p_n'] =  df['epoch_pfcpcreate_end3']-df['epoch_create_end3']
        df['q_n'] =  df['epoch_n1n2_end3']-df['epoch_pfcpcreate_end3']
        df['r_n'] =  df['epoch_pfcpupdate_end3']-df['epoch_n1n2_end3']
        df['s_n'] =  df['epoch_update_end3']-df['epoch_pfcpupdate_end3']
    #print(df)

    #for index, row in df.iterrows():
    #    if row['c_b'] == 0 and row['c_b'] == 0 and row['c_b'] == 0 and row['c_b'] == 0:

    df = df[df.g_b != 0.00000000000]
    df = df[df.m_h != 0.00000000000]
    df = df[df.s_n != 0.00000000000]
    #print(df)

    #df.loc['mean'] = df.mean()
    #print(df)
    df.to_csv('ueTransTimesDiff.csv', index=False)

    x_labels = ['Create SM\nContext', 'PFCP Session\nEstablishment', 'N1-N2 Message\nTransfer', 'PFCP Session\nModification', 'Update SM\nContext']
    configs = ['Embedding Read Data', 'Transactional Stateless', 'All NFs Share Database']
    order_list = ['Embedding Read Data', 'All NFs Share Database', 'Transactional Stateless']
    df_plot = pd.DataFrame(zip([-1], [-1], [-1]), columns=['time', 'config', 'type'])
    config_lst = []
    i = 0
    j = 0
    for column in df.columns[22:]:

        col_len = len(df[column].tolist())
        config_lst = [configs[0]] * col_len
        if j == 5:
            i = 0
            config_lst = [configs[1]] * col_len
        elif j == 10:
            i = 0
            config_lst = [configs[2]] * col_len
        elif j > 10:
            config_lst = [configs[2]] * col_len
        elif j > 5:
            config_lst = [configs[1]] * col_len
        type_lst = [x_labels[i]] * col_len
        df_temp = pd.DataFrame(zip(df[column].tolist().copy(), config_lst.copy(), type_lst.copy()), columns=['time', 'config', 'type'])
        df_plot = pd.concat([df_plot, df_temp])
        #print(df_plot)
        i=i+1
        j=j+1

    df_plot = df_plot.iloc[1:]
    df_plot.to_csv('df_plot.csv', index=False)
    flatui = [ "#3498db", "#34495e", "#2ecc71"]
    sns.set_palette(flatui)
    sb = sns.barplot(data=df_plot, x='type', y='time', hue='config', palette=flatui, hue_order=order_list)
    sb.legend_.set_title(None)
    plt.xlabel('Transactions', fontsize=12)
    plt.xticks(fontsize=9)
    plt.yticks(fontsize=12)
    plt.tight_layout()
    plt.legend(loc="best",fontsize='x-small')
    #plt.ylabel("Total Time (S)", fontsize=12)
    #plt.savefig('TransTimesT.pdf', bbox_inches='tight')
    plt.ylabel("Relative Time (S)", fontsize=12)
    plt.savefig('TransTimesR.pdf', bbox_inches='tight')
    plt.show()
    plt.close()


if __name__ == "__main__":
    main()