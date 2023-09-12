#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of countries where a named movie was released

from shutil import move
import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} 'MovieName' Year"

### Command-line args

if len(sys.argv) < 3:
    print(usage)
    exit(1)
if len(sys.argv[2]) != 4:
    print("Invalid year")
    exit(1)

# process the command-line args ...
inputM = sys.argv[1]
inputY = sys.argv[2]

### Queries

qry = """
select m.title, m.year, c.name
from movies m
    left outer join releasedin r on (m.id = r.movie)
    left outer join countries c on (r.country = c.code)
where m.title = %s and m.year = %s
order by c.name
"""
### Manipulating database

try:
    # your code goes here

    db = psycopg2.connect("dbname = ass2")
    cur = db.cursor()
    cur.execute(qry, [inputM, inputY])

    movieCount = 0
    nonreleases = 0
    for tup in cur.fetchall():
        title, year, country = tup


        if country is None:
            nonreleases +=1
        else:
            print(country)
        movieCount += 1

    if movieCount == 0:
        print("No such movie")
        exit(1)
    if movieCount == nonreleases:
        print("No releases")



except Exception as err:
    print("DB error: ", err)
finally:
    if db:
       db.close()


# non released movies:
#
#         title         | year |   id   | name
# ----------------------+------+--------+------
#  Ringeraja            | 2002 | 105521 |
#  Unlocked             | 2017 | 115140 |
#  Studio 666           | 2022 | 114045 |
#  Ruposh               | 2022 | 114593 |
#  Madeleine Collins    | 2021 | 111043 |
#  D3: The Mighty Ducks | 1996 | 102000 |
#  Bäxt Üzüyü           | 1991 | 113513 |


# select m.title, m.year, m.id, c.name
#     from movies m
#         left outer join releasedin r on (m.id = r.movie)
#         left outer join countries c on (r.country = c.code)
# where c.name is null
# """
