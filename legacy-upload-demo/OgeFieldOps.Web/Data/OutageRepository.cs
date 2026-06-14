using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using OgeFieldOps.Web.Models;

namespace OgeFieldOps.Web.Data
{
    /// <summary>
    /// Raw ADO.NET repository for outage records and their documents.
    /// Uses SqlConnection / SqlCommand / SqlDataReader / SqlDataAdapter directly
    /// (no ORM) - the classic on-prem pattern.
    /// </summary>
    public class OutageRepository
    {
        public OutageListResult Search(string search, int page, int pageSize)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;

            var result = new OutageListResult
            {
                Items = new List<OutageRecord>(),
                Page = page,
                PageSize = pageSize,
                Search = search
            };

            using (var connection = Database.OpenConnection())
            {
                // Total count for paging.
                using (var countCommand = new SqlCommand(
                    "SELECT COUNT(*) FROM dbo.Outages " +
                    "WHERE (@search IS NULL OR @search = '' " +
                    "   OR TicketNumber LIKE '%' + @search + '%' " +
                    "   OR Region LIKE '%' + @search + '%' " +
                    "   OR Cause LIKE '%' + @search + '%' " +
                    "   OR Status LIKE '%' + @search + '%')", connection))
                {
                    countCommand.Parameters.AddWithValue("@search", (object)search ?? DBNull.Value);
                    result.TotalCount = (int)countCommand.ExecuteScalar();
                }

                using (var command = new SqlCommand(
                    "SELECT Id, TicketNumber, Region, Cause, Status, CustomersAffected, " +
                    "       ReportedAt, RestoredAt, ReportedBy " +
                    "FROM dbo.Outages " +
                    "WHERE (@search IS NULL OR @search = '' " +
                    "   OR TicketNumber LIKE '%' + @search + '%' " +
                    "   OR Region LIKE '%' + @search + '%' " +
                    "   OR Cause LIKE '%' + @search + '%' " +
                    "   OR Status LIKE '%' + @search + '%') " +
                    "ORDER BY ReportedAt DESC " +
                    "OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY", connection))
                {
                    command.Parameters.AddWithValue("@search", (object)search ?? DBNull.Value);
                    command.Parameters.AddWithValue("@offset", (page - 1) * pageSize);
                    command.Parameters.AddWithValue("@pageSize", pageSize);

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Items.Add(MapOutage(reader));
                        }
                    }
                }
            }

            return result;
        }

        public OutageRecord GetById(int id)
        {
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "SELECT Id, TicketNumber, Region, Cause, Status, CustomersAffected, " +
                "       ReportedAt, RestoredAt, ReportedBy " +
                "FROM dbo.Outages WHERE Id = @id", connection))
            {
                command.Parameters.AddWithValue("@id", id);
                using (var reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        return MapOutage(reader);
                    }
                }
            }
            return null;
        }

        public int Create(OutageRecord outage)
        {
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "INSERT INTO dbo.Outages " +
                "(TicketNumber, Region, Cause, Status, CustomersAffected, ReportedAt, ReportedBy) " +
                "OUTPUT INSERTED.Id " +
                "VALUES (@ticket, @region, @cause, @status, @customers, @reportedAt, @reportedBy)", connection))
            {
                command.Parameters.AddWithValue("@ticket", outage.TicketNumber);
                command.Parameters.AddWithValue("@region", outage.Region);
                command.Parameters.AddWithValue("@cause", (object)outage.Cause ?? DBNull.Value);
                command.Parameters.AddWithValue("@status", outage.Status);
                command.Parameters.AddWithValue("@customers", outage.CustomersAffected);
                command.Parameters.AddWithValue("@reportedAt", outage.ReportedAt);
                command.Parameters.AddWithValue("@reportedBy", (object)outage.ReportedBy ?? DBNull.Value);
                return (int)command.ExecuteScalar();
            }
        }

        public int AddDocument(OutageDocument document)
        {
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "INSERT INTO dbo.OutageDocuments " +
                "(OutageId, FileName, StoredPath, SizeBytes, UploadedAt, UploadedBy) " +
                "OUTPUT INSERTED.Id " +
                "VALUES (@outageId, @fileName, @storedPath, @size, @uploadedAt, @uploadedBy)", connection))
            {
                command.Parameters.AddWithValue("@outageId", document.OutageId);
                command.Parameters.AddWithValue("@fileName", document.FileName);
                command.Parameters.AddWithValue("@storedPath", document.StoredPath);
                command.Parameters.AddWithValue("@size", document.SizeBytes);
                command.Parameters.AddWithValue("@uploadedAt", document.UploadedAt);
                command.Parameters.AddWithValue("@uploadedBy", (object)document.UploadedBy ?? DBNull.Value);
                return (int)command.ExecuteScalar();
            }
        }

        public IList<OutageDocument> GetDocuments(int outageId)
        {
            var documents = new List<OutageDocument>();
            using (var connection = Database.OpenConnection())
            using (var command = new SqlCommand(
                "SELECT Id, OutageId, FileName, StoredPath, SizeBytes, UploadedAt, UploadedBy " +
                "FROM dbo.OutageDocuments WHERE OutageId = @outageId ORDER BY UploadedAt DESC", connection))
            {
                command.Parameters.AddWithValue("@outageId", outageId);
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        documents.Add(new OutageDocument
                        {
                            Id = reader.GetInt32(0),
                            OutageId = reader.GetInt32(1),
                            FileName = reader.GetString(2),
                            StoredPath = reader.GetString(3),
                            SizeBytes = reader.GetInt64(4),
                            UploadedAt = reader.GetDateTime(5),
                            UploadedBy = reader.IsDBNull(6) ? null : reader.GetString(6)
                        });
                    }
                }
            }
            return documents;
        }

        /// <summary>
        /// Returns a DataTable of all outages for CSV export, built with a SqlDataAdapter
        /// (another classic ADO.NET pattern).
        /// </summary>
        public DataTable GetAllForExport()
        {
            var table = new DataTable("Outages");
            using (var connection = Database.OpenConnection())
            using (var adapter = new SqlDataAdapter(
                "SELECT TicketNumber, Region, Cause, Status, CustomersAffected, " +
                "       ReportedAt, RestoredAt, ReportedBy " +
                "FROM dbo.Outages ORDER BY ReportedAt DESC", connection))
            {
                adapter.Fill(table);
            }
            return table;
        }

        private static OutageRecord MapOutage(SqlDataReader reader)
        {
            return new OutageRecord
            {
                Id = reader.GetInt32(0),
                TicketNumber = reader.GetString(1),
                Region = reader.GetString(2),
                Cause = reader.IsDBNull(3) ? null : reader.GetString(3),
                Status = reader.GetString(4),
                CustomersAffected = reader.GetInt32(5),
                ReportedAt = reader.GetDateTime(6),
                RestoredAt = reader.IsDBNull(7) ? (DateTime?)null : reader.GetDateTime(7),
                ReportedBy = reader.IsDBNull(8) ? null : reader.GetString(8)
            };
        }
    }
}
