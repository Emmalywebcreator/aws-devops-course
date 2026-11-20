#!/usr/bin/env python3
"""List the servers in an inventory CSV, optionally only one environment."""
import argparse
import csv


def read_inventory(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def main():
    parser = argparse.ArgumentParser(description="List servers from an inventory CSV.")
    parser.add_argument("inventory", help="path to the CSV file")
    parser.add_argument("--env", help="only show servers in this environment")
    args = parser.parse_args()

    servers = read_inventory(args.inventory)
    if args.env:
        servers = [s for s in servers if s["env"] == args.env]

    for s in servers:
        print(f'{s["name"]}\t{s["env"]}\t{s["port"]}')
    print(f"{len(servers)} server(s)")


if __name__ == "__main__":
    main()
