# plot.py

# Copyright (C) 2020 Greenweaves Software Limited

# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.GA

# You should have received a copy of the GNU General Public License
# along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

import re, matplotlib.pyplot as plt

def plot_file(file_name):
    with open(file_name) as file:
        attendances=[]
        for line in file:
            m = re.search('^[0-9]+$',line.strip())
            if m:
                attendances.append(int(m.group(0)))
        plt.plot(attendances,label=file_name)        
 
def get_logfile_name(base):
    out_parts = base.split('.')
    if len(out_parts)==1:
        return base + '.txt'
    return base 

if __name__=='__main__':
    import argparse
    
    parser = argparse.ArgumentParser('Plot attendance from El Farol simulation')
    parser.add_argument('--files', nargs='+')
    parser.add_argument('--show',  action='store_true', default=False)
    parser.add_argument('--out',                        default='out')
    args = parser.parse_args()
    for file_name in args.files:
        plot_file(get_logfile_name(file_name))
    plt.xlabel('Generation')
    plt.ylabel('Attendance')
    plt.title('El Farol runs')
    plt.legend()
    plt.savefig(args.out)
    if args.show:
        plt.show()