using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface ICustomerService
    {
        Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId);
        Task<CustomerDto?> GetCustomerByKeycloakIdAsync(Guid keycloakId);
        Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto);
        Task<CustomerDto> UpdateCustomerAsync(UpdateCustomerDto dto);
    }
}
