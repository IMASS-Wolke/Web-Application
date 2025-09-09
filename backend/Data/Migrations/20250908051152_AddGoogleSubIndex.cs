using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IMASS.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddGoogleSubIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_GoogleSub",
                table: "AspNetUsers",
                column: "GoogleSub",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_GoogleSub",
                table: "AspNetUsers");
        }
    }
}
