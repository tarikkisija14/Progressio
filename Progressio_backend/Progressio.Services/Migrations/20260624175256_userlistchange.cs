using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Progressio.Services.Migrations
{
    /// <inheritdoc />
    public partial class userlistchange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserListInvites_UserListId_InviteeId",
                table: "UserListInvites");

            migrationBuilder.CreateIndex(
                name: "IX_UserListInvites_UserListId_InviteeId_Status",
                table: "UserListInvites",
                columns: new[] { "UserListId", "InviteeId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserListInvites_UserListId_InviteeId_Status",
                table: "UserListInvites");

            migrationBuilder.CreateIndex(
                name: "IX_UserListInvites_UserListId_InviteeId",
                table: "UserListInvites",
                columns: new[] { "UserListId", "InviteeId" },
                unique: true);
        }
    }
}
