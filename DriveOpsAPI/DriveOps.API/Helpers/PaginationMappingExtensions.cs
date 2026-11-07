using DriveOps.Application.DTOs;

namespace DriveOps.API.Helpers
{
    public static class PaginationMappingExtensions
    {
        public static PaginatedResult<TOut> MapPage<TIn, TOut>(
            this PaginatedResult<TIn> source, Func<TIn, TOut> selector) => new()
        {
            Items = source.Items.Select(selector).ToList(),
            TotalCount = source.TotalCount,
            Page = source.Page,
            PageSize = source.PageSize
        };
    }
}
