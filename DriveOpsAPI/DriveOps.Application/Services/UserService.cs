using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;

namespace DriveOps.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<UserDto?> GetUserByIdAsync(Guid userId)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            return user?.ToDto();
        }

        public async Task<UserDto?> GetUserByKeycloakIdAsync(string keycloakId)
        {
            var user = await _userRepository.GetByKeycloakIdAsync(keycloakId);
            return user?.ToDto();
        }

        public async Task<UserDto> CreateUserAsync(CreateUserDto dto)
        {
            if (await _userRepository.EmailExistsAsync(dto.Email))
                throw new InvalidOperationException($"A user with email '{dto.Email}' already exists.");

            var user = dto.ToEntity();
            var created = await _userRepository.AddAsync(user);
            return created.ToDto();
        }

        public async Task<UserDto> UpdateUserAsync(UpdateUserDto dto)
        {
            var user = await _userRepository.GetByIdAsync(dto.Id)
                ?? throw new KeyNotFoundException($"User {dto.Id} not found.");

            if (dto.Email != null) user.Email = dto.Email;
            if (dto.FirstName != null) user.FirstName = dto.FirstName;
            if (dto.LastName != null) user.LastName = dto.LastName;
            if (dto.PhoneNumber != null) user.PhoneNumber = dto.PhoneNumber;
            if (dto.ProfileImageUrl != null) user.ProfileImageUrl = dto.ProfileImageUrl;
            if (dto.Address != null) user.Address = dto.Address;
            if (dto.DateOfBirth != null) user.DateOfBirth = dto.DateOfBirth;
            user.UpdatedAt = DateTime.UtcNow;

            await _userRepository.UpdateAsync(user);
            return user.ToDto();
        }

        public async Task<UserDto> CreateOrUpdateFromKeycloakAsync(string keycloakId, string email, string firstName, string lastName)
        {
            // Primary lookup: returning SSO user already has a KeycloakId on record.
            var user = await _userRepository.GetByKeycloakIdAsync(keycloakId);

            // Fallback: a locally-created account may share this email but have no KeycloakId yet.
            // Skipping this would cause a DbUpdateException on the unique Users.Email constraint.
            user ??= await _userRepository.GetByEmailAsync(email);

            if (user == null)
            {
                user = new Model.Entity.User
                {
                    Id = Guid.NewGuid(),
                    KeycloakId = keycloakId,
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    PasswordHash = "KEYCLOAK_MANAGED",
                    PhoneNumber = "",
                    UserType = 0,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                var created = await _userRepository.AddAsync(user);
                return created.ToDto();
            }

            // Link the account if reached via the email fallback, then sync Keycloak-authoritative fields.
            user.KeycloakId = keycloakId;
            user.Email = email;
            user.FirstName = firstName;
            user.LastName = lastName;
            user.UpdatedAt = DateTime.UtcNow;
            await _userRepository.UpdateAsync(user);
            return user.ToDto();
        }

        public async Task UpdateLastLoginAsync(Guid userId)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user != null)
            {
                user.LastLoginAt = DateTime.UtcNow;
                await _userRepository.UpdateAsync(user);
            }
        }
    }
}
