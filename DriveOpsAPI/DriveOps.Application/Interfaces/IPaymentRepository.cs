using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IPaymentRepository : IRepository<Payment>
    {
        Task<IReadOnlyList<Payment>> GetByTripIdAsync(Guid tripId);
        Task<Payment?> GetByTransactionIdAsync(string transactionId);
    }
}
