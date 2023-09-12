#!/usr/bin/python3

import sys
import psycopg2
import re

# Helper functions (if any)

# ... functions go here ...

# Initial setup

db = None
cur = None

if len(sys.argv) < 3:
   print(f"Usage: {sys.argv[0]} Racecourse Date")
   exit(1)
track = sys.argv[1]
date = sys.argv[2]

validDate = re.compile("^\d{4}-\d{2}-\d{2}$")
if not validDate.match(date):
   print(f"Invalid date")
   exit(1)

inDate = sys.argv[2]
inCourse = sys.argv[1]


races = """
select distinct(race.name) from horses h
join runners run on (run.horse = h.id)
join Jockeys j on (run.jockey = j.id)
join races race on (run.race = race.id)
join meetings m on (m.id = race.part_of)
join raceCourses course on (m.run_at = course.id)
where m.run_on = %s and (run.finished = 1 or  run.finished = 2 or  run.finished = 3)
    and course.name = %s


"""
qry = """
select h.name, race.name, race.length, j.name, race.prize, run.finished from horses h
join runners run on (run.horse = h.id)
join Jockeys j on (run.jockey = j.id)
join races race on (run.race = race.id)
join meetings m on (m.id = race.part_of)
join raceCourses course on (m.run_at = course.id)
where m.run_on = %s and (run.finished = 1 or  run.finished = 2 or  run.finished = 3)
    and course.name = %s


"""

try:


    db = psycopg2.connect("dbname=racing")
    cur = db.cursor()
    cur2 = db.cursor()
    cur.execute(races,[inDate, inCourse])
    cur2.execute(qry, [inDate, inCourse])

    print(f"Race meeting at {inCourse} on {inDate}")


    for tup1 in cur.fetchall():
        name = tup1
        for tup in cur2.fetchall():
            horseName, raceName, raceLen, jokey, prize, finished = tup
            print(f"{raceName}, prize pool {prize}, run over {raceLen} ")






except psycopg2.Error as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()
   if cur:
       cur.close()
