drop database if exists library;
create database library;
use library;

-- Book genre
drop table if exists genre;
create table genre (
	genre_id int primary key,
    genre_name varchar(25)
);

insert into genre values
(1, 'Non-Fiction'),
(2, 'Fiction'),
(3, 'Philosophy'),
(4, 'Science Fiction'),
(5, 'Science'),
(6, 'Plays'),
(7, 'Japanese literature')
;

-- books
-- information about each book in the library's catalog
drop table if exists book;
create table book (
	book_id int primary key,
    title varchar(255) not null,
    author varchar(255),
    year int,
    pages int,
    genre_id int,
    in_circulation boolean,
    quote varchar(255),
    constraint foreign key (genre_id) references genre(genre_id)
);

insert into book values 
(1, 'The Soul of a New Machine', 'Tracy Kidder', 1981, 320, 1, TRUE, 'Much of the engineering of computers takes place in silence, while engineers pace in hallways or sit alone and gaze at blank pages.'),
(2, 'Nineteen Eighty-Four', 'George Orwell', 1948, 328, 2, true,'Freedom is the freedom to say that 2+2=4'),
(3, 'Fahrenheit 451', 'Ray Bradbury', 1953, 249, 4, TRUE,'It doesn\'t matter what you do...so long as you change something from the way it was before you touched it into something that\'s like you after you take your hands away.'),
(4, 'Brave New World', 'Aldous Huxley', 1932, 288, 2, TRUE,'If one\'s different, one\'s bound to be lonely.'),
(5, 'Zen and the Art of Motorcycle Maintenance', 'Robert Pirsig', 1974, 540, 3, FALSE,'The real cycle you\'re working on is a cycle called yourself.'),
(6, 'Dune', 'Frank Herbert', 1965, 896, 4, TRUE,'Once men turned their thinking over to machines in the hope that this would set them free. But that only permitted other men with machines to enslave them.'),
(7, 'Wonderful Life: The Burgess Shale and the Nature of History', 'Stephen J. Gould', 1990, 352, 5, TRUE,'Genius has as many components as the mind itself'),
(8, 'The Voyage of the Beagle', 'Charles Darwin', 1839, 496, 5, TRUE,'The wilderness has a mysterious tongue, which teaches awful doubt.'),
(9, 'Crime and Punishment', 'Fyodor Dostoevsky', 1866, 565, 2, TRUE,'The darker the night, the brighter the stars.'),
(10, 'Love\'s Labor\'s Lost', 'William Shakespeare', 1598, 160, 6, TRUE,'O, we have made a vow to study, lords, and in that vow we have forsworn our books.');

-- Users, contact information, and where they live
drop table if exists user;
create table user (
	user_id int primary key,
    user_name varchar(25),
    email varchar(255),
    street varchar(100),
    city varchar(100),
    state char(2)
);

insert into user values
(1, 'John', 'john@gmail.com', '1 main st', 'Boston', 'ma'),
(2, 'Abby', 'abby@kids.com', '2 summer st', 'Boston', 'ma'),
(3, 'Jack', 'jack@yahoo.com', '1 main st', 'Burlington', 'ma'),
(4, 'Sonya', 'sonya@aol.com', '3 harbor rd', 'Boylston', 'ma');
 

-- Which users are borrowing which books
drop table if exists borrow;
create table borrow (
	book_id int,
    user_id int,
    borrow_dt date,
    due_dt date,
    return_dt date,
    constraint foreign key (book_id) references book(book_id),
    constraint foreign key (user_id) references user(user_id)
);

insert into borrow values
(1,1,'2019-01-02', '2019-01-16', '2019-01-21'),
(2,1,'2019-01-02', '2019-01-16', '2019-01-15'),
(4,1,'2019-01-02', '2019-01-16', '2019-01-16'),
(6,1,'2019-02-01', '2019-02-16', '2019-02-23'),
(7,1,'2019-02-22', '2019-03-08', '2019-04-22'),
(8,1,'2019-03-10', '2019-03-24', '2019-06-30'),
(9,1,'2019-03-20', '2019-04-04', '2019-04-18'),
(3,1,'2019-04-18', '2019-05-02', '2019-07-13'),
(10,1,'2019-07-13', '2019-07-31', '2019-07-30'),
(6,1, '2019-08-01', '2019-08-14', '2019-12-25'),
(1,2,'2019-01-04', '2019-01-16', '2019-01-15'),
(1,2,'2019-01-15', '2019-01-31', '2019-02-01'),
(1,4,'2019-04-22', '2019-05-08', '2021-05-06');



-- The fine for returning a book late is 10 cents per day!
-- No extensions will be granted! 
-- And we know where you live.
-- This table tracks payment of all fines
-- If you return 2 book 10 days late you are fined $2.00 
-- If you paid us a total of $1.75, then you still owe us $0.25!
drop table if exists payment;
create table payment (
	user_id int,
	paid_dt date,
    amount decimal(9,2),
    constraint foreign key (user_id) references user(user_id)
);

insert into payment values
(1, '2019-01-21', 0.50),
(1, '2019-02-25', 0.60),
(1, '2019-04-22', 4.00),
(1, '2019-07-01', 0.20),
(1, '2019-05-01', 0.10),
(2, '2019-02-01', 0.08),
(4, '2021-05-06', 0.01);


select 'Library DB created.';

