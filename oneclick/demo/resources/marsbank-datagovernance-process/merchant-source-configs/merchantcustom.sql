SELECT *,   
to_date(date,'yyyy-MM-dd') as ingest_date
FROM __table__