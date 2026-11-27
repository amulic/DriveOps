using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IAccountAdminService
    {
        Task<List<AccountDto>> GetAccountsAsync(string? search, int first, int max, CancellationToken cancellationToken = default);
        Task<AccountDto> CreateAccountAsync(CreateAccountDto dto, CancellationToken cancellationToken = default);
        Task<AccountDto> UpdateAccountAsync(string accountId, UpdateAccountDto dto, CancellationToken cancellationToken = default);
        Task<AccountDto> SetRolesAsync(string accountId, IReadOnlyCollection<string> roles, CancellationToken cancellationToken = default);
        Task ResetPasswordAsync(string accountId, string temporaryPassword, CancellationToken cancellationToken = default);
    }
}
