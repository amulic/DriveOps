using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;

namespace DriveOps.Application.Services
{
    public class CustomerService : ICustomerService
    {
        private readonly ICustomerRepository _customerRepository;
        private readonly IUnitOfWork _unitOfWork;

        public CustomerService(ICustomerRepository customerRepository, IUnitOfWork unitOfWork)
        {
            _customerRepository = customerRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId)
        {
            var customer = await _customerRepository.GetByIdAsync(customerId);
            return customer?.ToDto();
        }

        public async Task<CustomerDto?> GetCustomerByKeycloakIdAsync(Guid keycloakId)
        {
            var customer = await _customerRepository.GetByKeycloakIdAsync(keycloakId);
            return customer?.ToDto();
        }

        public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto)
        {
            var customer = dto.ToEntity();
            await _customerRepository.AddAsync(customer);
            await _unitOfWork.SaveChangesAsync();
            return customer.ToDto();
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
            await _unitOfWork.SaveChangesAsync();
            return customer.ToDto();
        }
    }
}
