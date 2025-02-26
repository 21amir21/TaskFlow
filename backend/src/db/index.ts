import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

const pool = new Pool({
  connectionString: "postgresql://21amir21:test123@db:5432/tasksDB",
});

export const db = drizzle(pool);
