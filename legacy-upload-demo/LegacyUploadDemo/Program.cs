using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;

namespace LegacyUploadDemo
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            Console.WriteLine("LegacyUploadDemo starting...");

            var uploadDirectory = ConfigurationManager.AppSettings["UploadDirectory"] ?? Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "uploads");
            var connectionString = ConfigurationManager.ConnectionStrings["LegacyDb"]?.ConnectionString ?? "Server=(localdb)\\MSSQLLocalDB;Database=LegacyUploadDemo;Trusted_Connection=True;";

            Directory.CreateDirectory(uploadDirectory);

            Console.WriteLine($"Upload directory: {uploadDirectory}");
            Console.WriteLine("Scanning for files...");

            var files = Directory.GetFiles(uploadDirectory, "*.txt", SearchOption.TopDirectoryOnly).OrderBy(x => x).ToArray();
            foreach (var file in files)
            {
                Console.WriteLine($"Found file: {Path.GetFileName(file)}");
            }

            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (var command = new SqlCommand("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES", connection))
                {
                    var count = (int)command.ExecuteScalar();
                    Console.WriteLine($"Database reachable. Table count: {count}");
                }

                using (var adapter = new SqlDataAdapter("SELECT TOP 10 * FROM INFORMATION_SCHEMA.TABLES", connection))
                {
                    var table = new DataTable("Tables");
                    adapter.Fill(table);
                    Console.WriteLine($"Sample table rows: {table.Rows.Count}");
                }
            }

            Console.WriteLine("Done.");
        }
    }
}
