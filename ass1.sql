-- COMP3311 22T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file *MUST* load into an empty database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without error under these conditions


-- Q1: new breweries in Sydney in 2020

create or replace view Q1(brewery,suburb)
as
select b.name as brewery, m.town as suburb
from breweries b
     join locations m on (b.located_in = m.id)
where b.founded = 2020 AND m.metro = 'Sydney'
order by brewery
;

-- Q2: beers whose name is same as their style

create or replace view Q2(beer,brewery)
as
select b.name as beer,  br.name as brewery
from brewed_by bb
     join beers b on (bb.beer = b.id)
     join styles s on (b.style = s.id)
     join breweries br on (br.id = bb.brewery)
where s.name = b.name
order by beer
;

-- Q3: original Californian craft brewery

create or replace view Q3(brewery,founded)
as
-- dont use limit 1 as there may be multiple oldest breweries
select b.name as brewery, b.founded as founded
from breweries b
where b.founded = (select min(founded)
                   from breweries b
                   join locations m on (b.located_in = m.id)
                   where m.region = 'California');

;

-- Q4: all IPA variations, and how many times each occurs

create or replace view Q4(style,count)
as
select s.name as style, count(s.name)
from styles s
     join beers b on (b.style = s.id)
where s.name like '%IPA%'
group by s.name
order by style
;

-- Q5: all Californian breweries, showing precise location

create or replace view Q5(brewery,location)
as
select b.name as brewery, coalesce(m.town, m.metro)
from breweries b
     join locations m on (b.located_in = m.id)
where m.region = 'California'
order by brewery
;

-- Q6: strongest barrel-aged beer

create or replace view Q6(beer,brewery,abv)
as
select b.name as beer, br.name as brewery, b.abv as abv
from beers b
     join brewed_by bb on (b.id = bb.beer)
     join breweries br on (br.id = bb.brewery)
where b.abv = (select max(abv)
               from beers b
               where b.notes like '%aged%barrel%'
                  or b.notes like '%barrel%aged%'
              )
;

-- Q7: most popular hop

create or replace view Q7(hop)
as
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
;

-- Q8: breweries that don't make IPA or Lager or Stout (any variation thereof)

create or replace view Q8(brewery)
as

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
;

-- Q9: most commonly used grain in Hazy IPAs

create or replace view Q9(grain)
as
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
;

-- Q10: ingredients not used in any beer

create or replace view Q10(unused)
as
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
;

-- Q11: min/max abv for a given country

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




-- Q12: details of beers


drop type if exists BeerData cascade;
create type BeerData as (beer text, brewer text, info text);

create or replace function
	Q12(partial_name text) returns setof BeerData
as $$
declare
    _max     integer;
    _count   integer := 0;
    _info    text := NULL;
    _hops    text := 'Hops: ';
    _grain   text := 'Grain: ';
    _extra   text := 'Extras: ';
    _beer    text := '';
    _brewer  text := '';
    _brewers text := '';
    _brew_by integer;
    _bool    integer := 0;
    r        record;
    res      BeerData;

begin
    _max := (select count(*)
            from (
                select b.name as beer, br.name as brew, i.itype as type, i.name as ing, bb.beer as brew_by
                from beers b
                    left join contains c on (c.beer = b.id)
                    left join ingredients i on (i.id = c.ingredient)
                    left join brewed_by bb on (b.id = bb.beer)
                    left join breweries br on (br.id = bb.brewery)
                where lower(b.name) like '%'||lower(partial_name)||'%'
                order by b.name, br.name, i.itype, i.name) as take
    );

    for r in

        select b.name as beer, br.name as brew, i.itype as type, i.name as ing, bb.beer as brew_by
        from beers b
            left join contains c on (c.beer = b.id)
            left join ingredients i on (i.id = c.ingredient)
            left join brewed_by bb on (b.id = bb.beer)
            left join breweries br on (br.id = bb.brewery)
        where lower(b.name) like '%'||lower(partial_name)||'%'
        order by b.name, br.name, i.itype, i.name
    loop
        _count := _count + 1;
        _bool := 0;
        -- first beer
        if (_count = 1) then
            _beer := r.beer;
            _brewer := r.brew;
            _brewers := r.brew;
            _brew_by := r.brew_by;
        end if;


       -- if weve moved onto the next brewery/beer, then print
        -- info for previous beer out

        if (_beer = r.beer) and (_brewer = r.brew) then
            if (r.type = 'hop') then
                if (_hops = 'Hops: ') then
                    _hops := _hops||r.ing;
                else
                    _hops := _hops||','||r.ing;
                end if;
            elsif (r.type = 'grain') then
                if (_grain = 'Grain: ') then
                    _grain := _grain||r.ing;
                else
                    _grain := _grain||','||r.ing;
                end if;
            elsif (r.type = 'adjunct') then
                if (_extra = 'Extras: ') then
                    _extra := _extra||r.ing;
                else
                    _extra := _extra||','||r.ing;
                end if;
            end if;

            if (_count = 1) then
                continue;
            end if;
		end if;


        if (_beer = r.beer) and (_brewer <> r.brew) then
            if (_brew_by = r.brew_by ) then
                _brewers := _brewers ||' + '|| r.brew;
            end if;
        end if;

        -- share tuple
        if (_beer <> r.beer) or (_brewer <> r.brew) or (_count = _max) then
            if (_hops <> 'Hops: ') then
                _info := concat(_info,_hops);
            end if;

            if (_grain <> 'Grain: ') then
                if (_info is not NULL) then
                    _info := concat(_info,chr(10),_grain);
                else
                    _info := concat(_info, _grain);
                end if;
            end if;

            if (_extra <> 'Extras: ') then
                if (_info is not NULL) then
                    _info := concat(_info,chr(10),_extra);
                else
                    _info := concat(_info, _extra);

                end if;
            end if;

            res.info := _info;
            res.beer := _beer;
            res.brewer := _brewers;

            return next res;
            if (_brew_by = r.brew_by ) then
                _bool := 1;
            end if;

             -- set correct info
            _beer    := r.beer;
            _brewer  := r.brew;
            _brewers := r.brew;
            _brew_by := r.brew_by;
            _hops    := 'Hops: ';
            _grain   := 'Grain: ';
            _extra   := 'Extras: ';
            _info    := NULL;

            if (r.type = 'hop') then
                _hops := _hops||r.ing ;
            elsif (r.type = 'grain') then
                _grain := _grain||r.ing;
            elsif (r.type = 'adjunct') then
                _extra := _extra||r.ing;
            end if;

            -- getting the last element
            if (_count = _max) then
                if (_hops <> 'Hops: ') then
                    _info := concat(_info,_hops);
                end if;

                if (_grain <> 'Grain: ') then
                    if ( _info is not NULL) then
                        _info := concat(_info,_grain);
                    else
                        _info := concat(_info,_grain);
                    end if;
                end if;

                if (_extra <> 'Extras: ') then
                    if (_info is not NULL) then
                        _info := concat(_info, chr(10), _extra);
                    else
                        _info := concat(_info,_extra);
                    end if;
                end if;

                res.info := _info;
                res.beer := _beer;
                res.brewer := _brewers;

                if (_bool <> 1) then
                    return next res;
                end if;
            end if;
        end if;
    end loop;
end;
$$
language plpgsql;



-- ass 22 psycopg
Q1
select p.name, m.title, m.year
from knownfor k
    join movies m on (k.movie = m.id)
    join people p on (p.id = k.person)
where p.name = 'James Cameron'


select p.name, m.title, m.year, p.id
from principals pp
    join people p on (pp.person = p.id)
    join movies m on (pp.movie = m.id)
where pp.job = 'director'
order by m.year

Q2

select m.title, m.year, c.name
from releasedIn r
    join movies m on (r.movie = m.id)
    join countries c on (r.country = c.code)
where title = 'Crime + Punishment'