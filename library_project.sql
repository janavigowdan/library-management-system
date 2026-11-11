-- COLLEGE LIBRARY MANAGEMENT PROJECT
-- SQL Answers: C2 to C14
-- Database: librarydb
-- Tables: members, books, issues
-- Run this script after creating and populating the three original tables.

USE librarydb;

-- C2: Count records in all three tables.
SELECT COUNT(*) AS total_members FROM members;
SELECT COUNT(*) AS total_books FROM books;
SELECT COUNT(*) AS total_issues FROM issues;

-- C3: Count book titles and total available copies by category.
SELECT
    category,
    COUNT(*) AS total_titles,
    SUM(copies_available) AS total_copies
FROM books
GROUP BY category
ORDER BY category;

-- C4: Find the top 5 most borrowed books.
SELECT
    b.book_id,
    b.title,
    COUNT(i.issue_id) AS times_borrowed
FROM books b
JOIN issues i ON b.book_id = i.book_id
GROUP BY b.book_id, b.title
ORDER BY times_borrowed DESC
LIMIT 5;

-- C5: Find members who have never borrowed a book.
SELECT
    m.member_id,
    m.member_name,
    m.member_type
FROM members m
LEFT JOIN issues i ON m.member_id = i.member_id
WHERE i.issue_id IS NULL;

-- C6: Find currently issued books that have not been returned.
SELECT
    m.member_name,
    b.title,
    i.due_date
FROM issues i
JOIN members m ON i.member_id = m.member_id
JOIN books b ON i.book_id = b.book_id
WHERE i.return_date IS NULL;

-- C7: Find late returns and calculate fines at Rs. 2 per late day.
SELECT
    i.issue_id,
    m.member_name,
    b.title,
    i.due_date,
    i.return_date,
    DATEDIFF(i.return_date, i.due_date) AS late_days,
    DATEDIFF(i.return_date, i.due_date) * 2 AS fine
FROM issues i
JOIN members m ON i.member_id = m.member_id
JOIN books b ON i.book_id = b.book_id
WHERE i.return_date > i.due_date;

-- C8: Calculate the total fine for each member who has a fine.
SELECT
    m.member_id,
    m.member_name,
    SUM(DATEDIFF(i.return_date, i.due_date) * 2) AS total_fine
FROM members m
JOIN issues i ON m.member_id = i.member_id
WHERE i.return_date > i.due_date
GROUP BY m.member_id, m.member_name;

-- C9: Compare books borrowed by Students and Faculty.
SELECT
    m.member_type,
    COUNT(i.issue_id) AS total_books_borrowed
FROM members m
JOIN issues i ON m.member_id = i.member_id
GROUP BY m.member_type;

-- C10: Rank members based on the number of books borrowed.
SELECT
    m.member_id,
    m.member_name,
    COUNT(i.issue_id) AS total_books_borrowed,
    RANK() OVER (ORDER BY COUNT(i.issue_id) DESC) AS member_rank
FROM members m
LEFT JOIN issues i ON m.member_id = i.member_id
GROUP BY m.member_id, m.member_name;

-- C11: Find the most popular book category.
SELECT
    b.category,
    COUNT(i.issue_id) AS total_issues
FROM books b
JOIN issues i ON b.book_id = i.book_id
GROUP BY b.category
ORDER BY total_issues DESC
LIMIT 1;

-- C12: Find books with zero available copies and pending issues.
SELECT
    book_id,
    title,
    copies_available
FROM books
WHERE copies_available = 0
AND book_id IN (
    SELECT book_id
    FROM issues
    WHERE return_date IS NULL
);

-- C13: Create a stored procedure to display a member's borrowing history.
DROP PROCEDURE IF EXISTS member_history;

DELIMITER $$

CREATE PROCEDURE member_history(IN p_member_id INT)
BEGIN
    SELECT
        m.member_id,
        m.member_name,
        b.book_id,
        b.title,
        i.issue_date,
        i.due_date,
        i.return_date
    FROM issues i
    JOIN members m ON i.member_id = m.member_id
    JOIN books b ON i.book_id = b.book_id
    WHERE m.member_id = p_member_id;
END $$

DELIMITER ;

-- Test the stored procedure using member ID 1.
CALL member_history(1);

-- C14: Create separate copies of books and issues for safe trigger testing.
-- Drop old test objects first so this section can be run again.
DROP TRIGGER IF EXISTS decrease_book_copies;
DROP TABLE IF EXISTS issues_copy;
DROP TABLE IF EXISTS books_copy;

CREATE TABLE books_copy LIKE books;
INSERT INTO books_copy
SELECT * FROM books;

CREATE TABLE issues_copy LIKE issues;
INSERT INTO issues_copy
SELECT * FROM issues;

-- Create a trigger to decrease available copies after a new issue is inserted.
DELIMITER $$

CREATE TRIGGER decrease_book_copies
AFTER INSERT ON issues_copy
FOR EACH ROW
BEGIN
    UPDATE books_copy
    SET copies_available = copies_available - 1
    WHERE book_id = NEW.book_id;
END $$

DELIMITER ;

-- Test the trigger with a new issue record.
-- Book 109 originally has 4 copies; after this test it should have 3 in books_copy.
INSERT INTO issues_copy
VALUES (21, 9, 109, '2026-08-01', '2026-08-10', NULL);

-- Verify the trigger result.
SELECT book_id, title, copies_available
FROM books_copy
WHERE book_id = 109;

-- END OF SQL ANSWERS C2-C14
