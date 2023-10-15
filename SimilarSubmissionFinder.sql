-- Define a CTE to gather all newly received submissions that need to be checked
WITH newly_received_submissions AS (
    -- Aggregate responses for each submission
    SELECT
        s.id AS submission_id,
        ARRAY_TO_STRING(ARRAY_AGG(LOWER(REGEXP_REPLACE(COALESCE(a.automatic_translated_answer, a.response_text), '\s', '', 'g')) ORDER BY a.project_survey_item_id), '') AS responses
    FROM
        submissions s
        INNER JOIN answers a ON a.submission_id = s.id  -- Joining with the answers table
    WHERE
        s.status = 'completed'  -- Only considering 'completed' submissions
        AND a.response_type = 'text'  -- Focusing on text type responses
        AND s.project_id IN ({{Project ID}})
        AND a.status <> 3 -- Exclude rows where answers.status = 3
    GROUP BY
        s.id
),
-- Define a CTE to gather all previously approved submissions
approved_submissions AS (
    SELECT
        s.id AS submission_id,
        s.created_at AS created_at,
        -- Aggregate responses for each submission
        ARRAY_TO_STRING(ARRAY_AGG(LOWER(REGEXP_REPLACE(COALESCE(a.automatic_translated_answer, a.response_text), '\s', '', 'g')) ORDER BY a.project_survey_item_id), '') AS responses
    FROM
        submissions s
        INNER JOIN answers a ON a.submission_id = s.id  -- Joining with the answers table
        INNER JOIN submission_qa_statuses sqs ON sqs.submission_id = s.id  -- Joining with QA statuses to get passed submissions
    WHERE
        (s.status = 'unpaid' OR s.status = 'final')  -- Considering 'unpaid' or 'final' statuses
        AND (sqs.status = 'pass' OR sqs.status is null)  -- Either 'pass' in QA or not checked
        AND a.response_type = 'text'  -- Focusing on text type responses
        AND s.project_id IN ({{Project ID}})
        AND a.status <> 3  -- Exclude rows where answers.status = 3
    GROUP BY
        s.id
),
-- Define a CTE to find submissions from the newly received set that match or are similar to the approved set
matching_or_similar_submissions AS (
    SELECT distinct on (n.submission_id)
        n.submission_id
    FROM
        newly_received_submissions n
    JOIN
        approved_submissions a ON 
        CASE 
            -- If the submission is recent, use a similarity function
            WHEN a.created_at > '2023-01-01' THEN similarity(n.responses, a.responses) > 0.88
            -- For older submissions, direct string matching
            ELSE n.responses = a.responses
        END
)
-- Aggregate all the similar submission IDs into a comma-separated string
SELECT
    STRING_AGG(CAST(matching_or_similar_submissions.submission_id AS VARCHAR), ',') AS "Newly Received Submission IDs"
FROM matching_or_similar_submissions;
