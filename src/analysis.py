import numpy as np
import os
from matplotlib import pyplot as plt

def main():
    data_files = [os.path.abspath(os.path.join(root, name)) for root, dirs, files in os.walk("./data") for name in files]
    
    fig = plt.figure(figsize=(32,12))
    fig.suptitle("Cache Performance of RISC-V Matrix Multiplication\n", fontsize=32, weight="bold")

    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    
    legend = []
    missrates = []

    for file in data_files:
        data = np.loadtxt(file, delimiter=",", skiprows=1, dtype="int")
        legend.append(os.path.splitext(os.path.basename(file))[0])
        cycle = data[:, 0]
        missrate = data[:, 4]/data[:, 8]
        missrates.append(missrate[-1])

        ax1.plot(cycle, missrate)
        ax1.legend(legend, fontsize=20)
        ax1.set_xlabel("Cycle Number", fontsize=24, weight="bold")
        ax1.set_ylabel("Cumulative Miss Rate", fontsize=24, weight="bold")
        ax1.tick_params(axis='both', which='major', labelsize=20)
    
    ax2.bar([str(num) for num in range(1, len(legend)+1)], missrates)
    ax2.set_xlabel("Cache Configuration", fontsize=24, weight="bold")
    ax2.set_ylabel("Overall Miss Rate", fontsize=24, weight="bold")
    ax2.tick_params(axis='both', which='major', labelsize=20)
    plt.tight_layout()
    plt.savefig("./plots/analysis.pdf")
    plt.savefig("./plots/analysis.png")

    print(missrates)

if __name__ == "__main__":
    main()

