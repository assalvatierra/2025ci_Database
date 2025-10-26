using Npgsql;

namespace SchemaRunner;

class Program
{
    static async Task<int> Main(string[] args)
    {
        // Parse command line arguments
        var config = ParseArguments(args);
        
        if (config.ShowHelp)
        {
            ShowHelp();
            return 0;
        }

        await RunSchemaScripts(config.Server, config.Database, config.Username, config.Password, config.Execute);
        return 0;
    }

    static CommandConfig ParseArguments(string[] args)
    {
        var config = new CommandConfig();
        
        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i].ToLower())
            {
                case "--server":
                case "-s":
                    if (i + 1 < args.Length) config.Server = args[++i];
                    break;
                case "--database":
                case "-d":
                    if (i + 1 < args.Length) config.Database = args[++i];
                    break;
                case "--username":
                case "-u":
                    if (i + 1 < args.Length) config.Username = args[++i];
                    break;
                case "--password":
                case "-p":
                    if (i + 1 < args.Length) config.Password = args[++i];
                    break;
                case "--execute":
                case "-e":
                    config.Execute = true;
                    break;
                case "--help":
                case "-h":
                case "/?":
                    config.ShowHelp = true;
                    break;
            }
        }
        
        return config;
    }

    static void ShowHelp()
    {
        Console.WriteLine("PostgreSQL Schema Script Runner - Lists and executes SQL files in Schema folder");
        Console.WriteLine();
        Console.WriteLine("Usage: SchemaRunner [options]");
        Console.WriteLine();
        Console.WriteLine("Options:");
        Console.WriteLine("  --server, -s      PostgreSQL server name (default: localhost)");
        Console.WriteLine("  --database, -d    Database name (default: master)");
        Console.WriteLine("  --username, -u    PostgreSQL username (default: postgres)");
        Console.WriteLine("  --password, -p    PostgreSQL password");
        Console.WriteLine("  --execute, -e     Execute SQL scripts against database");
        Console.WriteLine("  --help, -h        Show this help message");
        Console.WriteLine();
        Console.WriteLine("Examples:");
        Console.WriteLine("  SchemaRunner                                    # List files only");
        Console.WriteLine("  SchemaRunner --execute -s localhost -d MyDB    # Execute with Windows auth");
        Console.WriteLine("  SchemaRunner -e -s localhost -d MyDB -u postgres -p MyPassword  # Execute with PostgreSQL auth");
    }

    public class CommandConfig
    {
        public string Server { get; set; } = "localhost";
        public string Database { get; set; } = "postgres";
        public string? Username { get; set; } = "postgres";
        public string? Password { get; set; }
        public bool Execute { get; set; } = false;
        public bool ShowHelp { get; set; } = false;
    }

    static async Task RunSchemaScripts(string server, string database, string? username, string? password, bool execute)
    {
        Console.WriteLine("=== SQL Schema Scripts ===");
        Console.ForegroundColor = ConsoleColor.Green;
        
        // Get Schema directory path
        var schemaDir = Path.Combine(Directory.GetCurrentDirectory(), "schema");
        if (!Directory.Exists(schemaDir))
        {
            // Try relative to current directory (for local development)
            schemaDir = Path.Combine(Directory.GetCurrentDirectory(), "..", "Schema");
        }
        if (!Directory.Exists(schemaDir))
        {
            // Try relative to executable (for local development)
            schemaDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "Schema");
        }
        
        Console.ResetColor();
        Console.WriteLine($"Directory: {Path.GetFullPath(schemaDir)}");
        
        if (execute)
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine($"Server: {server}");
            Console.WriteLine($"Database: {database}");
            Console.WriteLine($"Username: {username ?? "postgres"}");
            Console.ResetColor();
        }
        
        Console.WriteLine();

        // Check if Schema directory exists
        if (!Directory.Exists(schemaDir))
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"Error: Schema directory not found at: {schemaDir}");
            Console.ResetColor();
            return;
        }

        // Get all SQL files
        var sqlFiles = Directory.GetFiles(schemaDir, "*.sql")
            .Select(f => new FileInfo(f))
            .OrderBy(f => f.Name)
            .ToList();

        if (sqlFiles.Count == 0)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("No SQL files found in the Schema directory.");
            Console.ResetColor();
            return;
        }

        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine($"Found {sqlFiles.Count} SQL file(s):");
        Console.ResetColor();
        Console.WriteLine();

        int successCount = 0;
        int failureCount = 0;

        // Check execution status if connected to database
        Dictionary<string, DateTime?> executionStatus = new();
        if (execute)
        {
            executionStatus = await GetScriptExecutionStatus(server, database, username, password, sqlFiles.Select(f => f.Name));
        }

        for (int i = 0; i < sqlFiles.Count; i++)
        {
            var file = sqlFiles[i];
            var fileSize = Math.Round(file.Length / 1024.0, 2);
            var hasRun = executionStatus.ContainsKey(file.Name) && executionStatus[file.Name].HasValue;
            
            Console.ForegroundColor = ConsoleColor.White;
            Console.Write($"{i + 1}. {file.Name}");
            
            if (hasRun)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.Write(" ✓");
            }
            Console.WriteLine();
            Console.ResetColor();
            
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine($"   Size: {fileSize} KB");
            Console.WriteLine($"   Modified: {file.LastWriteTime:yyyy-MM-dd HH:mm:ss}");
            
            if (hasRun && executionStatus[file.Name].HasValue)
            {
                Console.WriteLine($"   Last executed: {executionStatus[file.Name]:yyyy-MM-dd HH:mm:ss}");
            }
            Console.ResetColor();

            if (execute)
            {
                var success = await ExecuteSqlFile(file.FullName, server, database, username, password);
                if (success)
                    successCount++;
                else
                    failureCount++;
            }

            Console.WriteLine();
        }

        if (execute)
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("=== Execution Summary ===");
            Console.ResetColor();
            
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"✓ Successful: {successCount}");
            Console.ResetColor();
            
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"✗ Failed: {failureCount}");
            Console.ResetColor();
            
            Console.WriteLine();
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine("=== Usage ===");
            Console.ResetColor();
            Console.WriteLine("To execute scripts against a database, use:");
            Console.WriteLine();
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine("            # PostgreSQL Authentication:");
            Console.ResetColor();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("SchemaRunner --execute --server localhost --database YourDatabase --username postgres --password YourPassword");
            Console.ResetColor();
            Console.WriteLine();
        }

        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("=== End of List ===");
        Console.ResetColor();
    }

    static async Task<bool> ExecuteSqlFile(string filePath, string server, string database, string? username, string? password)
    {
        var fileName = Path.GetFileName(filePath);
        
        try
        {
            // Build PostgreSQL connection string
            var connectionStringBuilder = new NpgsqlConnectionStringBuilder
            {
                Host = server,
                Database = database,
                Username = username ?? "postgres",
                Password = password ?? "",
                CommandTimeout = 300,
                Port = 5432
            };

            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"   Connecting to PostgreSQL as {connectionStringBuilder.Username}...");
            Console.ResetColor();

            using var connection = new NpgsqlConnection(connectionStringBuilder.ConnectionString);
            await connection.OpenAsync();

            // Check if script has already been executed
            var hasRun = await CheckIfScriptHasRun(connection, fileName);
            if (hasRun)
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("   ⚠ Already executed (skipped)");
                Console.ResetColor();
                return true;
            }

            // Read SQL content
            var sqlContent = await File.ReadAllTextAsync(filePath);
            
            // PostgreSQL doesn't use GO statements, execute the entire content
            // Split by semicolon for individual statements
            var statements = sqlContent.Split(new[] { ";\n", ";\r\n" }, StringSplitOptions.RemoveEmptyEntries);

            foreach (var statement in statements)
            {
                var trimmedStatement = statement.Trim();
                if (string.IsNullOrEmpty(trimmedStatement))
                    continue;

                using var command = new NpgsqlCommand(trimmedStatement, connection);
                command.CommandTimeout = 300;
                await command.ExecuteNonQueryAsync();
            }

            // Log successful execution
            await LogScriptExecution(connection, fileName);

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("   ✓ Executed successfully");
            Console.ResetColor();
            return true;
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"   ✗ Execution failed: {ex.Message}");
            Console.ResetColor();
            return false;
        }
    }

    static async Task<bool> CheckIfScriptHasRun(NpgsqlConnection connection, string scriptName)
    {
        try
        {
            // First check if the sysdbscriptlog table exists (PostgreSQL is case-sensitive)
            var checkTableSql = @"
                SELECT COUNT(*) 
                FROM information_schema.tables 
                WHERE table_name = 'sysdbscriptlog' AND table_schema = 'public'";
            
            using var checkCommand = new NpgsqlCommand(checkTableSql, connection);
            var tableExists = ((int?)await checkCommand.ExecuteScalarAsync() ?? 0) > 0;
            
            if (!tableExists)
            {
                return false; // Table doesn't exist, so script hasn't run
            }

            // Check if script has been logged
            var checkScriptSql = @"
                SELECT COUNT(*) 
                FROM sysdbscriptlog 
                WHERE scriptname = @ScriptName";
            
            using var command = new NpgsqlCommand(checkScriptSql, connection);
            command.Parameters.AddWithValue("@ScriptName", scriptName);
            
            var count = (int?)await command.ExecuteScalarAsync() ?? 0;
            return count > 0;
        }
        catch
        {
            // If any error occurs, assume script hasn't run
            return false;
        }
    }

    static async Task LogScriptExecution(NpgsqlConnection connection, string scriptName)
    {
        try
        {
            var logSql = @"
                INSERT INTO sysdbscriptlog (scriptname, runon)
                VALUES (@ScriptName, @RunOn)";
            
            using var command = new NpgsqlCommand(logSql, connection);
            command.Parameters.AddWithValue("@ScriptName", scriptName);
            command.Parameters.AddWithValue("@RunOn", DateTime.Now);
            
            await command.ExecuteNonQueryAsync();
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"   Warning: Failed to log script execution: {ex.Message}");
            Console.ResetColor();
        }
    }

    static async Task<Dictionary<string, DateTime?>> GetScriptExecutionStatus(string server, string database, string? username, string? password, IEnumerable<string> scriptNames)
    {
        var result = new Dictionary<string, DateTime?>();
        
        try
        {
            var connectionStringBuilder = new NpgsqlConnectionStringBuilder
            {
                Host = server,
                Database = database,
                Username = username ?? "postgres",
                Password = password ?? "",
                CommandTimeout = 300,
                Port = 5432
            };

            using var connection = new NpgsqlConnection(connectionStringBuilder.ConnectionString);
            await connection.OpenAsync();

            // Check if table exists
            var checkTableSql = @"
                SELECT COUNT(*) 
                FROM information_schema.tables 
                WHERE table_name = 'sysdbscriptlog' AND table_schema = 'public'";
            
            using var checkCommand = new NpgsqlCommand(checkTableSql, connection);
            var tableExists = ((int?)await checkCommand.ExecuteScalarAsync() ?? 0) > 0;
            
            if (!tableExists)
                return result;

            // Get execution status for all scripts
            var statusSql = @"
                SELECT scriptname, MAX(runon) as lastrun
                FROM sysdbscriptlog 
                WHERE scriptname = ANY(@scriptNames)
                GROUP BY scriptname";

            using var command = new NpgsqlCommand(statusSql, connection);
            command.Parameters.AddWithValue("@scriptNames", scriptNames.ToArray());
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var scriptName = reader.GetString(0);
                var lastRun = reader.GetDateTime(1);
                result[scriptName] = lastRun;
            }
        }
        catch
        {
            // If any error occurs, return empty result
        }

        return result;
    }
}
