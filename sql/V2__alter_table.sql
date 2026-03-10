-- V2__add_age_column.sql

ALTER TABLE users
ADD COLUMN age INT;

UPDATE users SET age = 25 WHERE name = 'Hritick';
UPDATE users SET age = 30 WHERE name = 'Amit';
UPDATE users SET age = 28 WHERE name = 'Priya';
