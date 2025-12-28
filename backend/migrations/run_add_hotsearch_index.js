/**
 * Database migration script to add hotsearch date index
 * Run with: node migrations/run_add_hotsearch_index.js
 */

require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const client = new Client({
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'videoall',
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
  });

  try {
    await client.connect();
    console.log('✅ Connected to PostgreSQL database');

    // Read SQL migration file
    const sqlPath = path.join(__dirname, 'add_hotsearch_date_index.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('📝 Executing migration...');
    await client.query(sql);

    console.log('✅ Migration completed successfully!');
    console.log('');
    console.log('Applied changes:');
    console.log('  - Added index IDX_HOTSEARCH_DATE on hotsearch_snapshots(capture_date)');
    console.log('');
    console.log('This will improve performance for historical date range queries.');

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
}

// Run migration
runMigration();
