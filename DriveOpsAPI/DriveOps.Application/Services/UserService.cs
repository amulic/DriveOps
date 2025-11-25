using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Interface;
using DriveOps.Model.Entity;


namespace DriveOps.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;
        public UserService(IUserRepository userRepository) 
        {
            _userRepository = userRepository;
        }

        public async Task<User> CreateOrUpdateUserAsync(string keycloakId) //user DTO needed
        {
            var user = await _userRepository.GetByKeycloakIdAsync(keycloakId);

            if (user == null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    KeycloakId = keycloakId, // Set Keycloak ID
                    //Email = email,
                    //FirstName = firstName,
                    //LastName = lastName,
                    PasswordHash = "KEYCLOAK_MANAGED",
                    PhoneNumber = "",
                    UserType = 0,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                return await _userRepository.AddAsync(user);
            }

            // Update user info from Keycloak (email might have changed)
            //user.Email = email;
            //user.FirstName = firstName;
            //user.LastName = lastName;
            user.UpdatedAt = DateTime.UtcNow;
            await _userRepository.UpdateAsync(user);

            return user;
        }

        public Task<User?> GetUserByKeycloakIdAsync(string keycloakId)
        {
            throw new NotImplementedException();
        }

        public Task UpdateLastLoginAsync(Guid userId)
        {
            throw new NotImplementedException();
        }
    }
}
