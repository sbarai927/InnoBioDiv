# code/python/data_processing.py
"""
Convert raw Arduino soil-moisture serial log -> clean CSV.

Usage:
    python data_processing.py raw_log.txt output/processed_moisture.csv
"""
import sys, csv

infile  = sys.argv[1]
outfile = sys.argv[2]

with open(infile) as fin, open(outfile, 'w', newline='') as fout:
    writer = csv.writer(fout)
    writer.writerow(['timestamp', 'moisture'])
    for line in fin:
        if line.startswith('#'):          # skip comments
            continue
        ts, raw_val = line.strip().split(',')
        writer.writerow([ts, float(raw_val)])
print(f"✓ Wrote cleaned file to {outfile}")
