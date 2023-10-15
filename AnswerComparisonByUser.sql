-- Define a CTE to gather all recently received answers (surveys) that need to be checked
WITH newly_received_answers AS (
    SELECT
        answers.id AS answer_id,
        answers.response_text,
        answers.submission_id,
        answers.user_id,
        answers.project_survey_item_id,
        submissions.project_id
    FROM
        answers
        LEFT JOIN submissions ON submissions.id = submission_id
    WHERE
        submissions.status = 'completed'
        AND response_type = 'text'
        AND (LENGTH(response_text) - LENGTH(replace(response_text, ' ', ''))) > 6
        AND submissions.project_id IN ({{Project ID}})
),
-- Define a CTE to gather all approved answers
approved_answers AS (
    SELECT
        answers.id AS answer_id,
        answers.response_text,
        answers.submission_id,
        answers.user_id,
        answers.project_survey_item_id,
        submissions.project_id,
        answers.automatic_translated_answer
    FROM
        answers
        LEFT JOIN submissions ON submissions.id = submission_id
        LEFT JOIN submission_qa_statuses sqs ON sqs.submission_id = submissions.id
    WHERE
        (
            submissions.status = 'unpaid' OR submissions.status = 'final'
        )
        AND (sqs.status = 'pass' OR sqs.status is null)
        AND response_type = 'text'
        AND (LENGTH(response_text) - LENGTH(replace(response_text, ' ', ''))) > 6
        AND submissions.project_id IN ({{Project ID}})
),
-- Define a CTE to find answers submitted by the same user in both newly received and approved answers
same_user AS (
    SELECT 
        n.submission_id AS "Newly Received Submission ID",
        n.response_text AS "Response text",
        a.automatic_translated_answer,
        (LENGTH(a.response_text) - LENGTH(replace(a.response_text, ' ', ''))) AS "Original Word Count",
        (LENGTH(a.automatic_translated_answer) - LENGTH(replace(a.automatic_translated_answer, ' ', '')) +1) AS "Translated Word Count",
        n.user_id AS "N User ID",
        a.user_id AS "A User ID",
        a.submission_id AS "Approved Submission ID"
    FROM
        newly_received_answers n
    INNER JOIN
        approved_answers a ON n.response_text = a.response_text
        AND n.user_id = a.user_id
        AND n.project_survey_item_id = a.project_survey_item_id
),
-- Define a CTE to find answers submitted by different users in both newly received and approved answers
different_user AS (
    SELECT 
        n.submission_id AS "Newly Received Submission ID",
        n.response_text AS "Response text",
        a.automatic_translated_answer,
        (LENGTH(a.response_text) - LENGTH(replace(a.response_text, ' ', ''))) AS "Original Word Count",
        (LENGTH(a.automatic_translated_answer) - LENGTH(replace(a.automatic_translated_answer, ' ', '')) +1) AS "Translated Word Count",
        n.user_id AS "N User ID",
        a.user_id AS "A User ID",
        a.submission_id AS "Approved Submission ID"
    FROM
        newly_received_answers n
    INNER JOIN
        approved_answers a ON n.response_text = a.response_text
        AND n.user_id != a.user_id
        AND n.project_survey_item_id = a.project_survey_item_id
)

-- Main query to combine and compare the responses from same_user and different_user CTEs
SELECT DISTINCT ON ("Newly Received Submission ID")
    COALESCE(d."Newly Received Submission ID", s."Newly Received Submission ID") AS "Newly Received Submission ID",
    COALESCE(d."Response text", s."Response text") AS "Response text",
    COALESCE(d.automatic_translated_answer, s.automatic_translated_answer) AS automatic_translated_answer,
    COALESCE(d."Original Word Count", s."Original Word Count") AS "Original Word Count",
    COALESCE(d."Translated Word Count", s."Translated Word Count") AS "Translated Word Count",
    COALESCE(d."N User ID", s."N User ID") AS "N User ID",
    COALESCE(d."A User ID", s."A User ID") AS "A User ID",
    COALESCE(d."Approved Submission ID", s."Approved Submission ID") AS "Approved Submission ID"
FROM
    different_user d
FULL OUTER JOIN
    same_user s ON d."Newly Received Submission ID" = s."Newly Received Submission ID"
WHERE
    (d."Response text" IS NOT NULL OR s."Response text" IS NOT NULL)
ORDER BY "Newly Received Submission ID";