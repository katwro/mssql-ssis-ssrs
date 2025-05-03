CREATE EVENT SESSION TrackLongQueries
ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.sql_text, sqlserver.client_hostname, sqlserver.username)
    WHERE (duration > 5000000) 
),
ADD EVENT sqlserver.rpc_completed (
    ACTION (sqlserver.sql_text, sqlserver.client_hostname, sqlserver.username)
    WHERE (duration > 5000000)
)
ADD TARGET package0.event_file (
    SET filename = 'C:\XELogs\TrackLongQueries.xel',
        max_file_size = 50,
        max_rollover_files = 5
)
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = OFF
);
