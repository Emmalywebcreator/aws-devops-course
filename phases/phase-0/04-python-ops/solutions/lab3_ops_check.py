#!/usr/bin/env python3
"""Check a list of URLs and log what happened."""
import argparse
import logging
import sys

import requests

log = logging.getLogger("ops_check")


def setup_logging(log_file, verbose):
    formatter = logging.Formatter("%(asctime)s %(levelname)-7s %(message)s")
    handlers = [logging.StreamHandler(sys.stderr), logging.FileHandler(log_file)]
    for handler in handlers:
        handler.setFormatter(formatter)
        log.addHandler(handler)
    log.setLevel(logging.DEBUG if verbose else logging.INFO)


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def main():
    parser = argparse.ArgumentParser(description="Log the HTTP status of each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    parser.add_argument("--log-file", default="ops_check.log", help="where to write the log")
    parser.add_argument("--verbose", action="store_true", help="also log DEBUG messages")
    args = parser.parse_args()
    setup_logging(args.log_file, args.verbose)

    urls = read_urls(args.urls_file)
    log.info("checking %d URL(s) from %s", len(urls), args.urls_file)
    for url in urls:
        log.debug("GET %s (timeout %.1fs)", url, args.timeout)
        response = requests.get(url, timeout=args.timeout)
        if response.ok:
            log.info("%s -> %d", url, response.status_code)
        else:
            log.warning("%s -> %d", url, response.status_code)


if __name__ == "__main__":
    main()
