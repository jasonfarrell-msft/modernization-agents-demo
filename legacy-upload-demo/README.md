# LegacyUploadDemo

This sample application is intentionally "dirty" for modernization demos:

- Uses .NET Framework (`net48`)
- Reads a local upload directory from configuration
- Uses legacy `SqlConnection` / `SqlCommand` / `SqlDataAdapter` ADO.NET patterns
- Assumes a local SQL Server / LocalDB-style database connection

Use this project as the baseline target for comparing:
1. GitHub Modernization Agent
2. improve skill + MCP patterns modernization flow
