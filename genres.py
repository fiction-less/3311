#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of countries where a named movie was released

import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} Year"

### Command-line args

if len(sys.argv) < 2:
    print(usage)
    exit(1)
if len(sys.argv[1]) != 4:
    print("Invalid year")
    exit(1)


# process the command-line args ...
inputY = sys.argv[1]

### Queries

qry = """
select count(g.genre), g.genre
from movies m
    join movieGenres g on (g.movie = m.id)
where m.year = %s
group by g.genre
order by count desc, g.genre
fetch first 10 rows with ties
"""

### Manipulating database

try:
    # your code goes here
    db = psycopg2.connect("dbname=ass2")
    cur = db.cursor()

    movieCount = 0
    cur.execute(qry, [inputY])

    maxNumLen = 0
    for tup in cur.fetchall():
        count, genre = tup
        if len(str(count)) > maxNumLen:
            maxNumLen = len(str(count))
        padding = maxNumLen - len(str(count))

        i = 0
        while i < padding:
            print(" ", end = '')
            i += 1

        print(str(count) + " " + genre)
        movieCount+= 1

    if movieCount == 0:
        print("No movies")
        exit(1)


except Exception as err:
    print("DB error: ", err)
finally:
    if db:
        db.close()
