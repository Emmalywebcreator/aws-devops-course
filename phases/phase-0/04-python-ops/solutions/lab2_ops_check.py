#!/usr/bin/env python3
"""Check a list of URLs and print the HTTP status of each."""
import argparse

import requests


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def main():
    parser = argparse.ArgumentParser(description="Print the HTTP status of each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    args = parser.parse_args()

    for url in read_urls(args.urls_file):
        response = requests.get(url, timeout=args.timeout)
        print(response.status_code, url)


if __name__ == "__main__":
    main()
