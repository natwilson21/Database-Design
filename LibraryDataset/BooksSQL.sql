-- HW4: Books that will change your life
-- Instructions: Run the script "hw4_library_setup.sql" in a ROOT connection
-- This will create a new schema called "library"
-- Write a query that answers each question below.

-- Questions 1-12 are 8 points each. Question 13 is worth 4 points.
-- use library database
USE library;

-- Exploring each Table
SELECT *
FROM book;

SELECT *
FROM borrow;

SELECT *
FROM genre;

SELECT *
FROM payment;

SELECT *
FROM user;

-- 1. Which book(s) are Science Fiction books written in the 1960's?
-- List title, author, and year of publication
SELECT title, author, year
FROM book
WHERE genre_id = 4 AND year > 1960 AND year < 1970
GROUP BY title, author, year;

-- 2. Which users have borrowed no books?
-- Give name and city they live in
-- Write the query in two ways, once by selecting from only one table
-- and using a subquery, and again by joining two tables together.
-- Method using subquery (4 points)
SELECT 
    user_name,
    city
FROM user 
WHERE user_id NOT IN 
	(SELECT user_id 
	FROM borrow);

-- Method using a join (4 points)
SELECT 
	u.user_name, 
    u.city
FROM user u
LEFT JOIN borrow br USING (user_id)
WHERE br.book_id IS NULL;

-- 3. How many books were borrowed by each user in each month?
-- Your table should have three columns: user_name, month, num_borrowed
-- You may ignore users that didn't borrow any books and months in which no books were borrowed.
-- Sort by name, then month
-- The month(date) function returns the month number (1,2,3,...12) of a given date. This is adequate for output.
SELECT 
	u.user_name,
    MONTH(br.borrow_dt) month,
    COUNT(br.user_id) AS 'num_borrowed'
FROM borrow br
JOIN user u USING(user_id)
GROUP BY u.user_name, MONTH(br.borrow_dt)
ORDER BY u.user_name, MONTH(br.borrow_dt);

-- 4. How many times was each book checked out?
-- Output the book's title, genre name, and the number of times it was checked out, and whether the book is still in circulation
-- Include books never borrowed
-- Order from most borrowed to least borrowed
SELECT 
	b.book_id,
    b.title,
    g.genre_name,
    COUNT(br.book_id) AS 'num_checkedOut',
    b.in_circulation
FROM borrow br
RIGHT JOIN book b ON (b.book_id = br.book_id) 
RIGHT JOIN genre g ON (b.genre_id = g.genre_id)
WHERE b.book_id IS NOT NULL
GROUP BY b.book_id, b.title, g.genre_name, b.in_circulation
ORDER BY num_checkedOut DESC;

-- 5. How many times did each user return a book late?
-- Include users that never returned a book late or never even borrowed a book
-- Sort by most number of late returns to least number of late returns (regardless of HOW late the returns were.)
SELECT 
	u.user_name,
    SUM(CASE WHEN DATEDIFF(br.due_dt, br.return_dt) < 0 THEN 1 ELSE 0 END) AS 'num_Late'
FROM borrow br
RIGHT JOIN user u ON (u.user_id = br.user_id)
GROUP BY u.user_name, 'num_Late'
ORDER BY num_Late DESC;

-- 6. How many books of each genre where published after 1950?
-- Include genres that are not represented by any book in our catalog
-- as well as genres for which there are books but none published after 1950.
-- Sort output by number of titles in each genre (most to least)
SELECT
	g.genre_name,
    SUM(CASE WHEN b.year > 1950 THEN 1 ELSE 0 END) AS 'num_books'
FROM genre g
LEFT JOIN book b ON (b.genre_id = g.genre_id)
GROUP BY g.genre_name, g.genre_id
ORDER BY num_books DESC;

-- 7. For each genre, compute a) the number of books borrowed and b) the average
-- number of days borrowed.
-- Includes books never borrowed and genres with no books
-- and in these cases, show zeros instead of null values.
-- Round the averages to one decimal point
-- Sort output in descending order by average
SELECT 
    g.genre_name, 
    COUNT(br.book_id) AS 'num_Books',
    IFNULL(ROUND(AVG(DATEDIFF(br.return_dt, br.borrow_dt)), 1), 0) AS 'average_days_borrowed'
FROM genre g
LEFT JOIN book b ON (g.genre_id = b.genre_id)
LEFT JOIN borrow br ON (b.book_id = br.book_id)
GROUP BY g.genre_name
ORDER BY average_days_borrowed DESC;

-- 8. List all pairs of books published within 10 years of each other
-- Don't include the book with itself
-- Only list (X,Y) pairs where X was published earlier
-- Output the two titles, and the years they were published, the number of years apart they were published
-- Order pairs from those published closest together to farthest
SELECT 
	a.title,
    a.year,
	b.title, 
    b.year,
    SUM(b.year) - a.year AS 'year_difference'
FROM book a 
JOIN book b ON (a.book_id != b.book_id AND a.title != b.title)
GROUP BY a.title, a.year, b.title, b.year
HAVING year_difference <= 10 AND year_difference >= 0
ORDER BY year_difference;

-- 9. Assuming books are returned completely read,
-- Rank the users from fastest to slowest readers (pages per day)
-- include users that borrowed no books (report reading rate as 0.0)
SELECT
u.user_name,
IFNULL(ROUND(AVG(b.pages / DATEDIFF(br.return_dt, br.borrow_dt)), 1), 0) AS 'avg_pages_per_day'
FROM genre g
LEFT JOIN book b ON (g.genre_id = b.genre_id)
LEFT JOIN borrow br ON (b.book_id = br.book_id)
RIGHT JOIN user u ON (u.user_id = br.user_id)
GROUP BY u.user_name
ORDER BY avg_pages_per_day DESC;

-- 10. How many books of each genre were checked out by John?
-- Sort descending by number of books checked out in each genre category.
-- Only include genres where at least two books of that genre were checked out.
-- (Count each time the book was checked out even if the same book was checked out
-- by John more than once.)
SELECT 
    g.genre_name,
    IFNULL(COUNT(br.book_id), 0) AS 'num_Books'
FROM borrow br
JOIN book b ON (b.book_id = br.book_id)
JOIN user u ON (u.user_id = br.user_id)
JOIN genre g ON (g.genre_id = b.genre_id)
WHERE u.user_name = 'John'
GROUP BY g.genre_name
HAVING num_Books >= 2
ORDER BY num_Books DESC;

-- 11. On average how many books are borrowed per user?
-- Output two averages in one row: one average that includes users that
-- borrowed no books, and one average that excludes users that borrowed no books
SELECT
(SELECT COUNT(*) FROM borrow) / (SELECT COUNT(*) FROM user) avg_all_users,
(SELECT COUNT(*) / COUNT(DISTINCT user_id) FROM borrow) avg_active_users;

-- 12. How much does each user owe the library. Include users owing nothing
-- Factor in the 10 cents per day fine for late returns and how much they have already paid the library
CREATE TABLE amt_paid
AS (SELECT
	u.user_name,
    IFNULL(SUM(-p.amount), 0) AS 'num_paid'
FROM payment p
RIGHT JOIN user u ON (u.user_id = p.user_id)
GROUP BY u.user_id);

CREATE TABLE amt_fined
AS (SELECT 
	u.user_name,
	SUM(IF(DATEDIFF(br.return_dt, br.due_dt) >= 0, (DATEDIFF(br.return_dt, br.due_dt) * 0.1) , 0)) AS 'num_fined'
FROM borrow br
RIGHT JOIN user u ON (u.user_id = br.user_id)
GROUP BY u.user_name);

SELECT 
	p.user_name,
    (SELECT (f.num_fined + p.num_paid)) AS 'num_owed'
FROM amt_paid p
JOIN amt_fined f ON (f.user_name = p.user_name)
GROUP BY p.user_name, num_owed;

-- 13. (4 points) Which books will change your life?
-- Answer: All books.
-- Select all books.
SELECT *
FROM book;