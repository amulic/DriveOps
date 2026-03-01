using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ICustomerRepository : IRepository<Customer>
    {
        Task<Customer?> GetByUserIdAsync(Guid userId);
        Task<Customer?> GetByPhoneNumberAsync(string phoneNumber);
    }
}
