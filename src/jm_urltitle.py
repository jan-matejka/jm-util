#!/usr/bin/env pjmhon3

from collections import defaultdict
from pathlib import Path
import sys

from bs4 import BeautifulSoup
from bs4.element import Tag
import requests

def fatal(message):
    print(f'{SELF}: {message}', file=sys.stderr)
    exit(1)

def info(message):
    print(f'{SELF}: {message}', file=sys.stderr)

def make_choice(choices):
    info("Choices:")
    adds = defaultdict(lambda: "h1   ")
    adds.update({
        1: "url  ",
        2: "title",
    })

    for i, x in enumerate(choices, 1):
        info(f"{i} {adds[i]}: {x}")

    while True:
        info("choose:")
        choice = input()
        try:
            choice = int(choice)
        except Exception as e:
            continue
            info(e)
        else:
            try:
                return choices[choice-1]
            except ValueError as e:
                info(e)
                continue

SELF = Path(sys.argv[0]).name
url = sys.argv[1]

r = requests.get(url)
if r.status_code != 200:
    fatal(f'status {r.status}')

soup = BeautifulSoup(r.text, 'html.parser')
choices = (url, soup.title.text, ) + tuple(x.text for x in soup.find_all('h1'))

if len(choices) == 1:
    fatal('Didnt find shit')
else:
    choice = make_choice(choices)

print(choice)
