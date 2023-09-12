CREATE TABLE Stores (
	phone integer,
  	address text,
  	PRIMARY KEY (phone)
  );

  -- only mention foreign keys for attributes that are pointing the arrow
  -- not where the arrow is pointing
  CREATE TABLE Accounts (
    acctNo integer,
    balance float,
    forUseAt integer NOTNULL-- phone number for the store tuple ; total participation
    PRIMARY KEY (acctNo)
    FOREIGN KEY (forUseAt)
    	REFERENCES Stores(phone)
    );

   CREATE TABLE Customers (
     customerNo integer,
     name text,
     address txt
     has_fav integer
     PRIMARY KEY (customerNo)
     FOREIGN KEY (has_fav)
     	REFERENCES Stores(phone)
     );


   -- if both are full participation

   CREATE table has (
     	custNo integer
     	AcctNo integer
     	PRIMARY KEY ( custNo, actNo)
     	FOREIGN KEY (custNo)
     		REFERENCES Customers(custNo)
     	FOREIGN KEY (acctNo)
     		REFERENCES Account(acctNo)
     )



     CREATE Table product (
       id 		integer PRIMARY KEY
       name 	text NOTNULL
       colour 	colourtype NOTNULL
       weight 	integer


       )

 -- NEW EXAMPLE STUDENT LECTURE 2 MONDAY 26:51
 -- empty string '' is not null
	create table students (
    	stuId char(7) check (studentID ~ '[0-9]{7}'),
      	-- stuId integer check (stuId between 3000000 and 5999999),
      	name varchar(100) not null,
      	degree char(4) check (degree ~ '[0-9]{4}')
        PRIMARY KEY (stuId)
       );


--- WEAK ENTITIES
CREATE TABLE strongEntitiy (
    SSN integer,
    ename varchar(100) not null,
    salary float,
    PRIMARY KEY (SSN)
);

CREATE TABLE weakE (
    emp_SSN integer,
    name PersonName,
    phone text,
    PRIMARY KEY (name, emp_SSN)
    FOREIGN KEY     (emp_SSN)
        REFERENCES strongEntitiy (SSN)
);

create domain PersonName as
    varchar(100) not null;

----
Customer has to have at least one branch no

customer
*custNo*, name, address, _brancNo_, joi




q1.
42.28



select b.name as brewery, m.town as suburb
from breweries b
     join locations m on (b.located_in = m.id)
where b.founded = 2020 AND m.metro = 'Sydney'
order by brewery



q2
select b.name as beer,  br.name as brewery
from brewed_by bb
     join beers b on (bb.beer = b.id)
     join styles s on (b.style = s.id)
     join breweries br on (br.id = bb.brewery)
where s.name = b.name
order by beer

q3.
-- dont use limit 1 as there may be multiple oldest breweries
select b.name as brewery, b.founded as founded
from breweries b
where b.founded = (select min(founded)
                   from breweries b
                   join locations m on (b.located_in = m.id)
                   where m.region = 'California');



q4.

select s.name as style, count(s.name)
from styles s
     join beers b on (b.style = s.id)
where s.name like '%IPA%'
group by s.name
order by style

Q5

select b.name as brewery, coalesce(m.town, m.metro)
from breweries b
     join locations m on (b.located_in = m.id)
where m.region = 'California'
order by brewery

Q6

select b.name as beer, br.name as brewery, b.abv as abv
from beers b
     join brewed_by bb on (b.id = bb.beer)
     join breweries br on (br.id = bb.brewery)
where b.abv = (select max(abv)
               from beers b
               where b.notes like '%aged%barrel%'
                  or b.notes like '%barrel%aged%'
              )


q7
select i.name as hop
from ingredients i
     join contains c on (c.ingredient = i.id)
     join beers b on (c.beer = b.id)
group by hop
having count(beer) = (select max(count)
                     from (select i.name as hop, count(*)
                           from ingredients i
                                join contains c on (c.ingredient = i.id)
                                join beers b on (c.beer = b.id)
                           group by hop
                           order by count)
                           mycount
)

8.
-- first get a view of all breweries that do make said beers
-- left join cause some breweries dont brew beers and will
-- have no style

select distinct(br.name) as brewery
from breweries br
     left join brewed_by bb on (br.id = bb.brewery)
     left join beers b on (bb.beer = b.id)
     left join styles s on (b.style = s.id)
where br.name not in (select distinct(br.name) as brewery
                      from breweries br
                           left join brewed_by bb on (br.id = bb.brewery)
                           left join beers b on (bb.beer = b.id)
                           left join styles s on (b.style = s.id)
                      where s.name like '%Lager%' or
                            s.name like '%IPA%' or
                            s.name like '%Stout%'
)
order by brewery


Q9
-- get a table of all hazy ipa (style) beers
-- get a table of all beers made from grains
-- group by grain
-- get the count


select i.name as grain
from beers b
     join styles s on (b.style = s.id)
     join contains c on (c.beer = b.id)
     join ingredients i on (i.id = c.ingredient)
where s.name like 'Hazy IPA' and i.itype = 'grain'
group by i.name
having count(beer) = (select max(count)
                      from (select i.name, count (*)
                            from beers b
                                 join styles s on (b.style = s.id)
                                 join contains c on (c.beer = b.id)
                                 join ingredients i on (i.id = c.ingredient)
                            where s.name like 'Hazy IPA' and i.itype = 'grain'
                            group by i.name) grainCount
)


q10.
-- get a table of all ingredients
-- get table of beers with their relative ingredients
-- compare ingredients list


select i.name as unused
from ingredients i
where i.name not in (select distinct(i.name)
                     from beers b
                          join styles s on (b.style = s.id)
                          join contains c on (c.beer = b.id)
                          join ingredients i on (i.id = c.ingredient)
                     group by i.name)


q11. (incorrect)

-- given a country, find all the breweries in the country
-- that brew beers, and get a list of all the beers from those breweries
-- and then get the min and max ABV

drop type if exists ABVrange cascade;
create type ABVrange as (minABV float, maxABV float);

create or replace function
        q11(_country text) returns ABVrange
as $$
declare
    r ABVrange;
begin
   return (
    select b.abv as minabv, max(b.abv) over ( order by b.abv desc) maxabv
    from breweries br
         join locations m on (br.located_in = m.id)
         join brewed_by bb on (br.id = bb.brewery)
         join beers b on (bb.beer = b.id)
    where m.country = '_country'
    order by b.abv asc
    limit 1
   );

end;
$$
language plpgsql;
-- HOW TO TEST ON TERMIN
\i q11.sql
select * from q11(input)



Q11. (correct)
-- given a country, find all the breweries in the country
-- that brew beers, and get a list of all the beers from those breweries
-- and then get the min and max ABV

drop type if exists ABVrange cascade;
create type ABVrange as (minABV float, maxABV float);

create or replace function
        Q11(_country text) returns ABVrange
as $$
declare
    r ABVrange;
begin
    r.maxABV =  (select b.abv
    from breweries br
         join locations m on (br.located_in = m.id)
         join brewed_by bb on (br.id = bb.brewery)
         join beers b on (bb.beer = b.id)
    where m.country = _country
    order by b.abv desc limit 1 )::numeric(4,1);

    if (r.maxABV is null) then
        r.maxABV := 0;
    end if;


    r.minABV = (select b.abv
    from breweries br
         join locations m on (br.located_in = m.id)
         join brewed_by bb on (br.id = bb.brewery)
         join beers b on (bb.beer = b.id)
    where m.country = _country
    order by b.abv asc limit 1)::numeric(4,1);

    if (r.minABV is null) then
        r.minABV := 0;
    end if;

    return r;

end;
$$
language plpgsql;


q12:
drop type if exists BeerData cascade;
create type BeerData as (beer text, brewer text, info text);

create or replace function
        Q12(partial_name text) return setof BeerData
as $$

declare
    r BeerData


begin

end

$$
language plpgsql;



select b.name, br.name, i.itype as type, i.name
from beers b
     left join contains c on (c.beer = b.id)
     left join ingredients i on (i.id = c.ingredient)
     left join brewed_by bb on (b.id = bb.beer)
     left join breweries br on (br.id = bb.brewery)
where b.name like '%Hazy%'
order by b.name






   select b.name as beer, br.name as brew, i.itype as type, i.name as ing, bb.beer as brew_by
        from beers b
            left join contains c on (c.beer = b.id)
            left join ingredients i on (i.id = c.ingredient)
            left join brewed_by bb on (b.id = bb.beer)
            left join breweries br on (br.id = bb.brewery)
        where lower(b.name) like '%'||lower('oat cream')||'%'
        order by b.name, br.name, i.itype, i.name