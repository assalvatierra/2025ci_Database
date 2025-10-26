# 2025ci_Database

| Component       | Purpose                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| **schema/**     | Holds all Data Definition Language (DDL) files — tables, views, stored procedures, etc.                      |
| **migrations/** | Contains versioned scripts that track incremental schema changes (used with tools like Flyway or Liquibase). |
| **scripts/**    | General-purpose SQL files for admin, analysis, or maintenance.                                               |
| **seeds/**      | Inserts sample or initial data for testing or bootstrapping environments.                                    |
| **tests/**      | Optional SQL scripts to verify schema integrity or stored procedure logic.                                   |
| **config/**     | Configuration files for connecting to databases or defining environment variables.                           |
