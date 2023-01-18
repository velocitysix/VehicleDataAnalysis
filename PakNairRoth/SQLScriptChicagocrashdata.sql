use ccd2;

# Which vehicles are the most dangerous?

SELECT veh_make,veh_model,SUM(injury_total) as TotalInjuries, count(veh_model) as model_frequency, SUM(injury_total)/count(veh_make) as injury_rate 
FROM crash_event
INNER JOIN vehicle ON crash_event.idCrash = vehicle.idVehicle
INNER JOIN crash_injuries ON crash_event.idCrash = crash_injuries.idCrash
WHERE injury_total <> 0 AND veh_make <> '' AND veh_model <> '' and veh_model <> 'UNKNOWN' and  veh_model not like '%other%'
GROUP BY veh_make,veh_model
HAVING model_frequency > 10
ORDER BY injury_rate DESC;

#check for top 10 crash by location

SELECT location,count(*) as loc_freq FROM People A
INNER JOIN crash_event  B
ON A.crashid=B.idcrash
group by location
HAVING location like 'point%'
order by count(*) DESC
limit 10;


#identify top 3 dangerous streets for possible rerouting and reconstruction
select st_name, count(st_name) AS 'most_common'
from crash_event
group by st_name order by 'most_common' DESC
limit 3;

# checks amount of crash events by year and month
select concat((MONTHNAME(date)) ,' ' ,(year(date))) as yr_month,count(*) as crash_count from crash_event
group by concat((MONTHNAME(date)) ,' ' ,(year(date)))
ORDER BY crash_count DESC;

#identify number of hospitalization and injuries due to crashes
select count(hospital) from people_injury where injury_class like '%REPORTED%' or '%NONINCAPACITATING INJURY%' or '%INCAPACITATING INJURY%' or '%FATAL%';

# lower limit damage cost by year due to accidents

SELECT YEAR(date) as year,
SUM(CASE
	WHEN damage_cost = '$500 or less' THEN 0
    WHEN damage_cost = '$501 - $1,500' THEN 501
    WHEN damage_cost = 'ovr $1,500' THEN 1500
END) AS damages_cost
FROM crash_event
GROUP BY YEAR(date);

# count the total number of crashes per year
SELECT YEAR(date) as year, count(idCrash) as totcrashes
FROM crash_event
group by year(date);


# this creates a view containing all of the information about the red light camera and crash events where the crash events is within 0.1 mile of the red light camera
Create VIEW crashevent_has_redlightcamera as
SELECT red_light_camera_location.INTERSECTION, `red_light_camera_location`.`FIRST APPROACH`,`red_light_camera_location`.`SECOND APPROACH`,`red_light_camera_location`.`THIRD APPROACH`,`red_light_camera_location`.`GO LIVE DATE`,crash_event.*,SQRT(
    POW(69.1 * (crash_event.latitude - red_light_camera_location.LATITUDE), 2) +
    POW(69.1 * (red_light_camera_location.LONGITUDE - crash_event.longitude) * COS(crash_event.latitude / 57.3), 2)) AS distance
FROM crash_event,red_light_camera_location
HAVING distance < 0.1;