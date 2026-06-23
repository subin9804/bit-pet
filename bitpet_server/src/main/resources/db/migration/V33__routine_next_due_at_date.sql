-- routine_mst.next_due_at: TIMESTAMP → DATE (시간 정보 불필요)
ALTER TABLE routine_mst
    ALTER COLUMN next_due_at TYPE DATE USING next_due_at::date;

ALTER TABLE routine_mst
    ALTER COLUMN last_executed_at TYPE DATE USING last_executed_at::date;
