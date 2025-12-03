using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IMASS.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSnthermRunTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SnthermRunResults",
                columns: table => new
                {
                    runId = table.Column<string>(type: "text", nullable: false),
                    exitCode = table.Column<int>(type: "integer", nullable: false),
                    StandardOutput = table.Column<string>(type: "text", nullable: false),
                    WorkDir = table.Column<string>(type: "text", nullable: false),
                    ResultsDir = table.Column<string>(type: "text", nullable: false),
                    StandardError = table.Column<string>(type: "text", nullable: false),
                    Outputs = table.Column<string[]>(type: "text[]", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SnthermRunResults", x => x.runId);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SnthermRunResults");
        }
    }
}
