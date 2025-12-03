using System;
using Microsoft.EntityFrameworkCore.Migrations;


namespace IMASS.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddScenarioChain : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ScenarioId",
                table: "Models",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ChainId",
                table: "Jobs",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateTable(
                name: "Scenarios",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Scenarios", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Chains",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ScenarioId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Chains", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Chains_Scenarios_ScenarioId",
                        column: x => x.ScenarioId,
                        principalTable: "Scenarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Models_ScenarioId",
                table: "Models",
                column: "ScenarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_ChainId",
                table: "Jobs",
                column: "ChainId");

            migrationBuilder.CreateIndex(
                name: "IX_Chains_ScenarioId",
                table: "Chains",
                column: "ScenarioId");

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_Chains_ChainId",
                table: "Jobs",
                column: "ChainId",
                principalTable: "Chains",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Models_Scenarios_ScenarioId",
                table: "Models",
                column: "ScenarioId",
                principalTable: "Scenarios",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_Chains_ChainId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Models_Scenarios_ScenarioId",
                table: "Models");

            migrationBuilder.DropTable(
                name: "Chains");

            migrationBuilder.DropTable(
                name: "Scenarios");

            migrationBuilder.DropIndex(
                name: "IX_Models_ScenarioId",
                table: "Models");

            migrationBuilder.DropIndex(
                name: "IX_Jobs_ChainId",
                table: "Jobs");

            migrationBuilder.DropColumn(
                name: "ScenarioId",
                table: "Models");

            migrationBuilder.DropColumn(
                name: "ChainId",
                table: "Jobs");
        }
    }
}
