/*
The task in Fiftyville is to solve a mystery!

The CS50 Duck has been stolen! The town of Fiftyville has called upon you to solve the mystery of the stolen duck. 
Authorities believe that the thief stole the duck and then, shortly afterwards, took a flight out of town with the help of an accomplice. 
Your goal is to identify:

- Who the thief is,
- What city the thief escaped to, and
- Who the thief’s accomplice is who helped them escape

All you know is that the theft took place on July 28, 2020 and that it took place on Chamberlin Street. 
Part of solving the mystery is keeping a log of the query process. The following is my log and the answers!
*/

-- Query 1: Getting the description of the theft by reading the crime scene report:
SELECT description FROM crime_scene_reports WHERE year = 2020 AND month = 7 AND day = 28 AND street = "Chamberlin Street";

Output:
-- Theft of the CS50 duck took place at 10:15am at the Chamberlin Street courthouse.
-- Interviews were conducted today with three witnesses who were present at the time
-- — each of their interview transcripts mentions the courthouse.

-- Query 2: Getting the interviews from the witnesses:
SELECT name, transcript FROM interviews WHERE year = 2020 AND month = 7 AND day = 28;

Output:
-- Ruth | Sometime within ten minutes of the theft, I saw the thief get into a car in the courthouse parking lot
-- and drive away. If you have security footage from the courthouse parking lot, you might want to look for cars that
-- left the parking lot in that time frame.
Point: Check licence plate around 10:15 am

-- Eugene | I don't know the thief's name, but it was someone I recognized.
-- Earlier this morning, before I arrived at the courthouse,
-- I was walking by the ATM on Fifer Street and saw the thief there withdrawing some money.
Point: Check ATM transactions before 10:15 am

-- Raymond | As the thief was leaving the courthouse, they called someone who talked to them for less than a minute.
-- In the call, I heard the thief say that they were planning to take the earliest flight out of Fiftyville tomorrow.
-- The thief then asked the person on the other end of the phone to purchase the flight ticket.
Point: Check flights leaving on 29 of july earliest on the morning

-- Query 3: By following flight information we might get an idea of the accomplice and destination.
-- Start by finding the id of the Fiftyville airport and then look at the earliest flight:
SELECT * FROM flights WHERE origin_airport_id = (SELECT id FROM airports WHERE city = "Fiftyville")
AND year = 2020 AND month = 7 AND day = 29
ORDER by hour
LIMIT 1;

Output:
id | origin_airport_id | destination_airport_id | year | month | day | hour | minute
36 | 8                  | 4                     | 2020 | 7      | 29 | 8    | 20

-- With the destination_airport_id we can answer one of our questions: destination
SELECT city FROM airports WHERE id = 4;

Output:
London

-- Query 4: With the id from flights we can use it to find passport_number from passengers table:
SELECT passport_number, seat FROM passengers WHERE flight_id = 36;

Output:
passport_number | seat
7214083635 | 2A
1695452385 | 3B
5773159633 | 4A
1540955065 | 5C
8294398571 | 6C
1988161715 | 6D
9878712108 | 7A
8496433585 | 7B

-- Query 4: Lets add some names and info regarding license plate and phone number (both were mentioned by the witnesses)
SELECT passengers.passport_number, seat, name, license_plate, phone_number FROM passengers JOIN people
ON passengers.passport_number = people.passport_number
WHERE people.passport_number IN (SELECT passport_number FROM passengers WHERE flight_id = 36);

Output:
passport_number | seat | name   | license_plate | phone_number
9878712108      | 7A | Bobby    | 30G67EN       | (826) 555-1652
1695452385      | 3B | Roger    | G412CB7       | (130) 555-0289
1988161715      | 6D | Madison  | 1106N58       | (286) 555-6063
8496433585      | 5D | Danielle | 4328GD8       | (389) 555-5198
8496433585      | 7B | Danielle | 4328GD8       | (389) 555-5198
8496433585      | 7C | Danielle | 4328GD8       | (389) 555-5198
8294398571      | 6C | Evelyn   | 0NTHK55       | (499) 555-9472
1540955065      | 5C | Edward   | 130LD9Z       | (328) 555-1152
5773159633      | 4A | Ernest   | 94KL13X       | (367) 555-5533
7214083635      | 2A | Doris    | M51FA04       | (066) 555-9701

-- Query 5: We can limit the list by looking which license left the courthouse
SELECT license_plate, minute, activity FROM courthouse_security_logs WHERE license_plate IN (SELECT license_plate FROM passengers JOIN people
ON passengers.passport_number = people.passport_number
WHERE people.passport_number IN (SELECT passport_number FROM passengers WHERE flight_id = 36))
AND year = 2020 AND month = 7 AND day = 28 AND hour = 10 AND minute < 25;

Output:
license_plate | minute | activity
94KL13X       | 18     | exit        (Ernest)
4328GD8       | 19     | exit        (Danielle)
G412CB7       | 20     | exit        (Roger)
0NTHK55       | 23     | exit        (Evelyn)

-- Query 6: We can limit the names further by looking at the transactions:
SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = "Fifer Street" AND transaction_type = "withdraw";

SELECT person_id FROM bank_accounts
WHERE account_number IN (SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = "Fifer Street" AND transaction_type = "withdraw");

SELECT name, license_plate, phone_number FROM people
WHERE id IN (SELECT person_id FROM bank_accounts
WHERE account_number IN (SELECT account_number FROM atm_transactions
WHERE year = 2020 AND month = 7 AND day = 28 AND atm_location = "Fifer Street" AND transaction_type = "withdraw"))
AND license_plate IN (SELECT license_plate FROM courthouse_security_logs WHERE license_plate IN (SELECT license_plate FROM passengers JOIN people
ON passengers.passport_number = people.passport_number
WHERE people.passport_number IN (SELECT passport_number FROM passengers WHERE flight_id = 36))
AND year = 2020 AND month = 7 AND day = 28 AND hour = 10 AND minute < 25);

Output:
name     | license_plate | phone_number
Danielle | 4328GD8       | (389) 555-5198
Ernest   | 94KL13X       | (367) 555-5533

-- Given that Danielle booked three seats we can easily rule him out. In other words, our thief is Ernest!

-- Query 7: Given that we now Ernest is the thief we just need to know who he called to book the flight!
SELECT receiver, duration, caller FROM phone_calls
WHERE year = 2020 AND month = 7 AND day = 28 AND duration < 60 AND caller = "(367) 555-5533";

Output:
receiver       | duration | caller
(375) 555-8161 | 45       | (367) 555-5533

-- Finaly we should be able to identify the receivers name:
SELECT name FROM people WHERE phone_number = "(375) 555-8161";

Output:
Berthold

/*
The THIEF is: Ernest
The thief ESCAPED TO: London
The ACCOMPLICE is: Berthold
*/
