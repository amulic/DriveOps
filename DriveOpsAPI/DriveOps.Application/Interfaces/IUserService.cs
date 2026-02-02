using DriveOps.Model.Entity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.Application.Interfaces
{
    public interface IUserService
    {
        Task<User> GetUserByDbIdAsync(Guid userId);
        Task<User?> GetUserByKeycloakIdAsync(string keycloakId);
        Task<User> CreateUserAsync(UserRequestDto keycloakId); // should be DTO of user
        Task<User> UpdateUserAsync(UserRequestDto userRequestDto);
        Task UpdateLastLoginAsync(Guid userId);
    }
}
