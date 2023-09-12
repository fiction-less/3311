#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print info about one movie; may need to choose

import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} 'PartialMovieName'"

### Command-line args

if len(sys.argv) < 2:
   print(usage)
   exit(1)

# process the command-line args ...

inputN = sys.argv[1]
lowCaseInput = inputN.lower()
### Queries

# find num of matching movies
# if only one then go next query


getNumMovies = """
select count(m.title)
from movies m
where lower(m.title) ~* %s
"""

listMovies = """
select m.title, m.year, m.id
from movies m
where lower(m.title) ~* %s
order by m.title, m.year
"""

# you have to use string place holders even when
# passing thru value !
listPrincipals = """
select m.title, pr.role, m.year, p.id, p.name, pp.job
from people p
   left outer join principals pp on (pp.person = p.id)
   left outer join playsrole pr on (pr.inMovie = pp.id)
   left outer join movies m on (pp.movie = m.id)
where m.ID = %s
order by pp.ord
"""


### Manipulating database

try:
   # your code goes here

   def printMovies(movieID):
      cur.execute(listPrincipals, [movieID])
      for tup in cur.fetchall():
         title, role, year, id, name, job = tup
         if role is None:
            role = "???"

         if job in ['actor', 'actress', 'self']:
            print(f"{name} plays {role}")
         else:
            print(f"{name}: {job}")



   db = psycopg2.connect("dbname=ass2")
   cur = db.cursor()
   cur.execute(getNumMovies, [lowCaseInput])
   numMovies = cur.fetchone()[0]
   counter = 1
   if numMovies == 0:
      print("No movie matching: '" + inputN + "'")
      exit(1)
   if numMovies > 1:
      cur.execute(listMovies, [lowCaseInput])
      for tup in cur.fetchall():
         title, year, id = tup
         print(f"{str(counter)}. {title} ({str(year)})")
         counter += 1

      movieNum = int(input("Which movie? "))
      cur.execute(listMovies, [lowCaseInput])

      movieTitle = cur.fetchall()[movieNum -1][0]
      cur.execute(listMovies, [lowCaseInput])
      movieID = cur.fetchall()[movieNum -1][2]
      cur.execute(listMovies, [lowCaseInput])
      movieYear = cur.fetchall()[movieNum -1][1]
      print(f"{movieTitle} ({str(movieYear)})")

      printMovies(movieID)
   else:
      cur.execute(listMovies, [lowCaseInput])
      movieTitle = cur.fetchone()[0]
      cur.execute(listMovies, [lowCaseInput])
      movieYear = cur.fetchone()[1]
      cur.execute(listMovies, [lowCaseInput])
      movieID = cur.fetchone()[2]
      print(f"{movieTitle} ({str(movieYear)})")
      printMovies(movieID)


except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()
