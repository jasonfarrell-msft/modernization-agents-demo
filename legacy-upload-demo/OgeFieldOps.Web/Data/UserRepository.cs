using System;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

namespace OgeFieldOps.Web.Data
{
    public class AppUser
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string DisplayName { get; set; }
        public string Role { get; set; }
    }

    /// <summary>
    /// Raw ADO.NET user store used by Forms Authentication.
    /// Passwords are stored as salted SHA-256 hashes (period-typical; not modern KDF).
    /// </summary>
    public class UserRepository
    {
        public AppUser ValidateCredentials(string username, string password)
        {
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "SELECT Id, Username, DisplayName, Role, PasswordSalt, PasswordHash " +
                "FROM dbo.Users WHERE Username = @username AND IsActive = 1", connection))
            {
                command.Parameters.AddWithValue("@username", username ?? string.Empty);
                using (var reader = command.ExecuteReader())
                {
                    if (!reader.Read())
                    {
                        return null;
                    }

                    var salt = reader.GetString(4);
                    var storedHash = reader.GetString(5);
                    var computed = HashPassword(password, salt);

                    if (!string.Equals(storedHash, computed, StringComparison.OrdinalIgnoreCase))
                    {
                        return null;
                    }

                    return new AppUser
                    {
                        Id = reader.GetInt32(0),
                        Username = reader.GetString(1),
                        DisplayName = reader.IsDBNull(2) ? reader.GetString(1) : reader.GetString(2),
                        Role = reader.GetString(3)
                    };
                }
            }
        }

        public AppUser GetByUsername(string username)
        {
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "SELECT Id, Username, DisplayName, Role FROM dbo.Users WHERE Username = @username", connection))
            {
                command.Parameters.AddWithValue("@username", username ?? string.Empty);
                using (var reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        return new AppUser
                        {
                            Id = reader.GetInt32(0),
                            Username = reader.GetString(1),
                            DisplayName = reader.IsDBNull(2) ? reader.GetString(1) : reader.GetString(2),
                            Role = reader.GetString(3)
                        };
                    }
                }
            }
            return null;
        }

        public static string HashPassword(string password, string salt)
        {
            using (var sha = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes((salt ?? string.Empty) + (password ?? string.Empty));
                var hash = sha.ComputeHash(bytes);
                var sb = new StringBuilder(hash.Length * 2);
                foreach (var b in hash)
                {
                    sb.Append(b.ToString("x2"));
                }
                return sb.ToString();
            }
        }
    }
}
