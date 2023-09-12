#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of movies directed by a given person

import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} FullName"

### Command-line args

if len(sys.argv) < 2:
    print(usage)
    exit(1)

# process the command-line args ...

dir = sys.argv[1]

### Queries


# ~ regular expression matching ~* makes it case insensitive
# finds how many people have the same name
subqry = """
select name, id
from people
where name = %s
"""

qry = """
select p.name, m.title, m.year, p.id
from principals pp
    join people p on (pp.person = p.id)
    join movies m on (pp.movie = m.id)
where pp.job = 'director' and p.name = %s
order by m.year
"""
### Manipulating database

try:
    # your code goes here

    db = psycopg2.connect("dbname=ass2")
    cur = db.cursor()

    numSameName = 0
    cur.execute(subqry, [dir])
    for tup in cur.fetchall():
        numSameName += 1

    if numSameName == 0:
        print("No such person")
        exit(1)

    # find the movies from argv[1] director, limited to 1 id
    firstRow = 1
    count = 0
    cur.execute(qry, [dir])
    for tup in cur.fetchall():
        name, title, year, id = tup

        if  firstRow == 1:
            firstId = id
            firstRow = 0
        if  id == firstId:
            print(title + " (" + str(year)+ ")")
        count += 1

    if count == 0 and numSameName > 1:
        print(f"None of the people called {dir} has directed any films")
    elif count == 0 and numSameName == 1:
        print(f"{dir} has not directed any movies")


except Exception as err:
    print("DB error: ", err)
finally:
    if db:
        db.close()




