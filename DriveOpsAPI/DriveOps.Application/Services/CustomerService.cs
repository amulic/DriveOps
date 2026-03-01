using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;

namespace DriveOps.Application.Services
{
    public class CustomerService : ICustomerService
    {
        private readonly ICustomerRepository _customerRepository;

        public CustomerService(ICustomerRepository customerRepository)
        {
            _customerRepository = customerRepository;
        }

        public async Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId)
        {
            var customer = await _customerRepository.GetByIdAsync(customerId);
            return customer?.ToDto();
        }

        public async Task<CustomerDto?> GetCustomerByUserIdAsync(Guid userId)
        {
            var customer = await _customerRepository.GetByUserIdAsync(userId);
            return customer?.ToDto();
        }

        public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto)
        {
            var customer = dto.ToEntity();
            var created = await _customerRepository.AddAsync(customer);
            return created.ToDto();
        }

        public async Task<CustomerDto> UpdateCustomerAsync(UpdateCustomerDto dto)
        {
            var customer = await _customerRepository.GetByIdAsync(dto.Id)
                ?? throw new KeyNotFoundException($"Customer {dto.Id} not found.");

            if (dto.Name != null) customer.Name = dto.Name;
            if (dto.PhoneNumber != null) customer.PhoneNumber = dto.PhoneNumber;
            if (dto.Email != null) customer.Email = dto.Email;
            if (dto.PreferredPaymentMethod.HasValue) customer.PreferredPaymentMethod = dto.PreferredPaymentMethod;
            customer.UpdatedAt = DateTime.UtcNow;

            await _customerRepository.UpdateAsync(customer);
            return customer.ToDto();
        }
    }
}
