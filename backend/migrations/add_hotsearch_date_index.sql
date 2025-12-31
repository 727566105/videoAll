-- Add capture_date index for hotsearch_snapshots table
-- This improves performance for historical date range queries

CREATE INDEX IF NOT EXISTS IDX_HOTSEARCH_DATE
ON hotsearch_snapshots(capture_date);

-- Optional: Create crawl stats table for monitoring (Phase 4)
-- Uncomment the following block if you want to enable monitoring in Phase 1

-- CREATE TABLE IF NOT EXISTS hotsearch_crawl_stats (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     timestamp TIMESTAMP NOT NULL,
--     platform VARCHAR(20),
--     success BOOLEAN,
--     item_count INTEGER,
--     execution_time INTEGER,
--     error_message TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE INDEX IF NOT EXISTS IDX_CRAWL_STATS_PLATFORM_DATE
-- ON hotsearch_crawl_stats(platform, timestamp);
