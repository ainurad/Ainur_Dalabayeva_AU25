-- ========================================================================
-- TASK 2: DELETE vs VACUUM FULL vs TRUNCATE Performance Investigation
-- ========================================================================

-- ================================================
-- RESULTS TABLE
-- ================================================

| № | Stage             | Execution Time   | Table Size (total) | Comment                                     |
|---|-------------------|------------------|--------------------|---------------------------------------------|
| 1 | After CREATE      | 34 secs 305 msec | 575 MB             | Table with 10 million rows created          |
| 2 | After DELETE      | 28 secs 995 msec | 383 MB             | Table size didn’t change — space not released |
| 3 | After VACUUM FULL | 14 secs 145 msec | 383 MB             | Table size decreased — space reclaimed      |
| 4 | After RECREATE    | 38 secs 101 msec | 575 MB             | Table recreated successfully                |
| 5 | After TRUNCATE    | 210 msec         | 8192 bytes         | Table cleared instantly                     |

-- ================================================
-- OBSERVATIONS:
-- ================================================

1. After DELETE, the table still occupies almost the same space — deleted rows remain as “dead tuples”.
2. After VACUUM FULL, space is reclaimed, and the table size significantly decreases.
3. TRUNCATE is much faster than DELETE because it removes all data instantly without scanning rows.
4. For large tables, TRUNCATE is the preferred method when you need to clear all data.

-- ================================================
-- CONCLUSIONS:
-- ================================================

1. DELETE — slow and does not immediately release space.  
2. VACUUM FULL — reclaims space but takes additional time.  
3. TRUNCATE — instantly removes all rows and fully frees space.

