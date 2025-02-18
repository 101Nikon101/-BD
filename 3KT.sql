CREATE TABLE IF NOT EXISTS st.ndam_book_info (
    book_id INTEGER,
    category VARCHAR(255),
    title VARCHAR(255),
    author VARCHAR(255),
    price VARCHAR(15)
);

INSERT INTO st.ndam_book_info (book_id, category, title, author, price)
SELECT 
    temp_book_id AS book_id,
    temp_category AS category,
    CASE
        WHEN temp_bookTitle = '' THEN 'Эльфийский рок : антология'
        WHEN temp_bookTitle = 'Русские народные сказки А. Н. Афанасьева ' THEN 'Русские народные сказки'
        ELSE temp_bookTitle
    END AS title,
    CASE
        WHEN temp_author = '' THEN 'А. Н. Афанасьев'
        WHEN temp_author = ' Эльфийский рок : антология</p>' THEN 'Отсутствует'
        ELSE substring(temp_author, 0, strpos(temp_author, '<'))
    END AS author,
    temp_price AS price
FROM (
    SELECT
        CAST(
            substring(value, strpos(value, '<p>') + 3, strpos(substring(value, strpos(value, '<p>'), strpos(value, '<p>') + 10), '</') - 4) AS INTEGER
        ) AS temp_book_id,
        substring(value, strpos(value, '<h1>') + 4, strpos(value, '</h1>') - strpos(value, '<h1>') - 4) AS temp_category,
        substring(
            substring(value, strpos(value, 'title'), strpos(value, 'title') + 100), 
            strpos(substring(value, strpos(value, 'title'), strpos(value, 'title') + 100), '>') + 1, 
            strpos(substring(value, strpos(value, 'title'), strpos(value, 'title') + 100), '<') - 8
        ) AS temp_bookTitle,
        substring(
            substring(value, strpos(value, 'author'), strpos(value, 'author') + 100), 
            strpos(substring(value, strpos(value, 'author'), strpos(value, 'author') + 100), '>') + 1, 
            strpos(substring(value, strpos(value, 'author'), strpos(value, 'author') + 100), '<') - 3
        ) AS temp_author,
        substring(
            substring(value, strpos(value, 'price'), strpos(value, 'price') + 100), 
            strpos(substring(value, strpos(value, 'price'), strpos(value, 'price') + 100), '>') + 1, 
            strpos(substring(value, strpos(value, 'price'), strpos(value, 'price') + 100), '<') - 8
        ) AS temp_price
    FROM de.html_data
) AS temp_p;

SELECT * FROM st.ndam_book_info;