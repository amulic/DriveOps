using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface ICustomerService
    {
        Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId);
        Task<CustomerDto?> GetCustomerByUserIdAsync(Guid userId);
        Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto);
        Task<CustomerDto> UpdateCustomerAsync(UpdateCustomerDto dto);
    }
}
