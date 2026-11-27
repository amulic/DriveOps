using System.Text.Json;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Maps FluentValidation failures to a 400 response with the first error as
    /// the human message and a per-field error map so clients can highlight the
    /// offending input.
    /// </summary>
    public class ValidationExceptionFilter : IExceptionFilter
    {
        public void OnException(ExceptionContext context)
        {
            if (context.Exception is not ValidationException validationException)
                return;

            var errors = validationException.Errors
                .GroupBy(e => JsonNamingPolicy.CamelCase.ConvertName(
                    string.IsNullOrWhiteSpace(e.PropertyName) ? "request" : e.PropertyName))
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(e => e.ErrorMessage).ToArray());

            var firstMessage = validationException.Errors
                .Select(e => e.ErrorMessage)
                .FirstOrDefault(m => !string.IsNullOrWhiteSpace(m))
                ?? "The request is invalid.";

            context.Result = new BadRequestObjectResult(new
            {
                message = firstMessage,
                errors
            });
            context.ExceptionHandled = true;
        }
    }
}
