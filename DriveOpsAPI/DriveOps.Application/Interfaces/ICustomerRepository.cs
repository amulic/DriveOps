using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ICustomerRepository : IRepository<Customer>
    {
        Task<Customer?> GetByKeycloakIdAsync(Guid keycloakId);
        Task<Customer?> GetByPhoneNumberAsync(string phoneNumber);
    }
}
