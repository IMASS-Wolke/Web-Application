using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IMASS.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddGoogleSubToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "GoogleSub",
                table: "AspNetUsers",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GoogleSub",
                table: "AspNetUsers");
        }
    }
}
