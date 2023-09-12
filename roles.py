#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of character roles played by an actor/actress

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

inputN = sys.argv[1]

### Queries

checkIDS = """
select count(DISTINCT p.id)
from people p
where p.name = %s
"""

getIDs = """
select m.title, pr.role, m.year, p.id, p.name, pp.job
from people p
    left outer join principals pp on (pp.person = p.id)
    left outer join playsrole pr on (pr.inMovie = pp.id)
    left outer join movies m on (pp.movie = m.id)
where p.name =  %s
order by p.id, m.year, m.title, pr.role
"""

### Manipulating database

try:
    # your code goes here
    db = psycopg2.connect("dbname=ass2")
    cur = db.cursor()

    cur.execute(checkIDS, [inputN])
    numIDs = cur.fetchone()[0]
    notActor = True

    if numIDs == 0:
        print("No such person")
        exit(1)

    elif (numIDs > 1):
        number = 1
        # multiple users exist
        cur.execute(getIDs, [inputN])
        datalist = cur.fetchall()
        curr = -1


        for tup in datalist:
            title, role, year, id, name, job = tup

            if curr != id:
                if notActor == True and number != 1:
                    print("No acting roles")
                notActor = True
                print(name + " #" + str(number))
                number += 1

            if (job in ['actor', 'self', 'actress']):
                print (role + " in " + title + " (" + str(year) + ")")
                notActor = False

            curr = id

        if notActor == True:
            print("No acting roles")
    else:
        cur.execute(getIDs, [inputN])
        for tup in cur.fetchall():
            title, role, year, id, name, job = tup

            if (job in ['actor', 'self', 'actress']):
                print (role + " in " + title + " (" + str(year) + ")")
                notActor = False

        if notActor == True:
            print("No acting roles")

except Exception as err:
    print("DB error: ", err)
finally:
    if db:
        db.close()
