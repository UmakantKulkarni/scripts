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
from datetime import datetime

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42
sns.set_context(context="paper", font_scale=1.6)
file_format = "pdf"

my_dir_path = os.path.dirname(os.path.realpath(__file__))
my_dir = "/Users/umakantkulkarni/Library/CloudStorage/OneDrive-purdue.edu/Research/5gSec/Summer2024/Milcom"
base_dir = os.path.join(my_dir, "Experiments")

# Path to the est.csv file
est_csv_path = os.path.join(base_dir, "ue_se.csv")

# Load the experiment start and end times
est_df = pd.read_csv(est_csv_path)

# Helper function to parse datetime from string
def parse_datetime(dt_str):
    return datetime.strptime(dt_str, '%Y-%m-%dT%H:%M:%S')

# Files to be considered for CPU and memory usage collection
target_files = [
    "top_data_node0.txt",
    "top_data_node1.txt_node1",
    "top_data_node2.txt_node2",
    "top_data_node3.txt_node3"
]

def process_top_output():
    # Process each experiment
    for index, row in est_df.iterrows():
        experiment_name = row['experiment']
        print("Working on {}".format(experiment_name))
        start_time = parse_datetime(row['start_time'])
        end_time = parse_datetime(row['end_time'])
        
        experiment_dir = os.path.join(base_dir, experiment_name, "1000")
        cpu_data = {file_name: [] for file_name in target_files}
        mem_data = {file_name: [] for file_name in target_files}

        # Iterate over the top_data_node files
        # Iterate over the specified files
        for file_name in target_files:
            file_path = os.path.join(experiment_dir, file_name)

            if os.path.exists(file_path):
                with open(file_path, 'r') as f:
                    current_timestamp = None
                    for line in f:
                        # Check for timestamp line
                        if "--" in line:
                            timestamp_str = line.strip()
                            try:
                                # Strip the extra microsecond digits if present
                                if len(timestamp_str.split('.')[1]) > 6:
                                    timestamp_str = timestamp_str[:-3]
                                current_timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d--%H:%M:%S.%f')
                            except ValueError as e:
                                print(f"Error parsing timestamp: {timestamp_str}, {e}")
                                continue
                        # Check if within the start and end time
                        if current_timestamp and start_time <= current_timestamp <= end_time:
                            if "ztx" in line or "envoy" in line:
                                columns = line.split()
                                process_name = columns[-1]
                                cpu_usage = columns[8]
                                mem_usage = columns[9]
                                # Store CPU and memory usage
                                if process_name == 'ztx' or process_name == 'envoy':
                                    cpu_data[file_name].append(cpu_usage)
                                    mem_data[file_name].append(mem_usage)
            else:
                print(f"File {file_name} not found in {experiment_dir}")

        # Find the maximum length of the data collected
        max_length = max(len(lst) for lst in cpu_data.values())

        # Pad the lists with None to ensure they all have the same length
        for file_name in target_files:
            cpu_data[file_name].extend([None] * (max_length - len(cpu_data[file_name])))
            mem_data[file_name].extend([None] * (max_length - len(mem_data[file_name])))

        # Write the aggregated CPU data to cpu.csv
        cpu_df = pd.DataFrame(cpu_data)
        cpu_df.to_csv(os.path.join(experiment_dir, "cpu.csv"), index=False)

        # Write the aggregated Memory data to mem.csv
        mem_df = pd.DataFrame(mem_data)
        mem_df.to_csv(os.path.join(experiment_dir, "mem.csv"), index=False)

        print(f"Processed data for {experiment_name}")

    print("All experiments processed successfully.")

def plot_cpu_mem():
    cmap = plt.colormaps["Set1"]
    # Extract tht colors as a list
    colors = list(cmap.colors)
    color_plte = sns.color_palette("Set2")
    #color_plte = sns.color_palette()
    #color_plte = sns.color_palette("tab10")
    color_plte = sns.color_palette("husl", 8)

    # List of experiments to process
    experiments = ["RanSecure-1","PfcpSecure-1","CoreSecure-1", "AllSecure-1","IstioSec-1"]
    exp_plot_order = ["RAN Secured", "PFCP Secured", "Core Secured", "All Secured","Istio"]
    exp_labels = [exp.replace(" ", "\n") for exp in exp_plot_order]

    # Initialize lists to store average CPU and memory usage
    avg_cpu_usage = []
    avg_mem_usage = []

    # Process each experiment
    for experiment in experiments:
        experiment_dir = os.path.join(base_dir, experiment, "1000")
        
        # Path to the CPU and memory CSV files
        cpu_csv_path = os.path.join(experiment_dir, "cpu.csv")
        mem_csv_path = os.path.join(experiment_dir, "mem.csv")
        
        # Read the CPU and memory data
        if os.path.exists(cpu_csv_path):
            cpu_df = pd.read_csv(cpu_csv_path)
            # Exclude zero values and calculate the average CPU usage
            #cpu_df_no_zeros = cpu_df[cpu_df > 0]
            # Calculate the average CPU usage per column and then across columns
            avg_cpu_per_column = cpu_df.mean()
            final_avg_cpu = avg_cpu_per_column.mean()
            avg_cpu_usage.append(final_avg_cpu)
        else:
            print(f"CPU data not found for {experiment}")
            avg_cpu_usage.append(0)
        
        if os.path.exists(mem_csv_path):
            mem_df = pd.read_csv(mem_csv_path)
            # Exclude zero values and calculate the average memory usage
            #mem_df_no_zeros = mem_df[mem_df > 0]
            # Calculate the average memory usage per column and then across columns
            avg_mem_per_column = mem_df.mean()
            final_avg_mem = avg_mem_per_column.mean()
            avg_mem_usage.append(final_avg_mem)
        else:
            print(f"Memory data not found for {experiment}")
            avg_mem_usage.append(0)

    fntsize = 16
    # Plotting the CPU usage
    plt.figure()
    bars = plt.bar(exp_labels, avg_cpu_usage, color=color_plte[3])
    #plt.title('Average CPU Usage')
    plt.xlabel('Security Model',fontsize=fntsize)
    plt.ylabel('Average CPU Usage (%)',fontsize=fntsize)
    plt.yticks(fontsize=fntsize)
    plt.xticks(fontsize=fntsize)
    #plt.xticks(rotation=45)
    # Add CPU usage percentage above each bar
    for bar in bars:
        yval = bar.get_height()
        plt.text(
            bar.get_x() + bar.get_width()/2,  # x-coordinate
            yval,  # y-coordinate
            f'{yval:.2f}%',  # Text to display
            ha='center',  # Align horizontally center
            va='bottom',   # Align vertically at the bottom of the text
            fontsize=14
        )
    plt.ylim([None,14])
    plt.tight_layout()
    plt.savefig(os.path.join(base_dir, "cpu_usage.{}".format(file_format)))
    plt.show()
    plt.close()

    # Plotting the Memory usage
    plt.figure()
    plt.bar(exp_labels, avg_mem_usage, color=color_plte[2])
    #plt.title('Average Memory Usage')
    plt.xlabel('Security Model',fontsize=fntsize)
    plt.ylabel('Average Memory Usage (MiB)',fontsize=fntsize)
    plt.yticks(fontsize=fntsize)
    plt.xticks(fontsize=fntsize)
    #plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(os.path.join(base_dir, "memory_usage.{}".format(file_format)))
    plt.show()
    plt.close()

process_top_output()
plot_cpu_mem()
