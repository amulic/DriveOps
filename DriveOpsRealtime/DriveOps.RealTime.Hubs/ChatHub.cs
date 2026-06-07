
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace DriveOps.RealTime.Hubs;

    [Authorize]
    public class ChatHub : Hub
    {
        private readonly IConnectionMappingService _connectionMapping;
        private readonly IChatService _chatService;

        public ChatHub(IConnectionMappingService connectionMapping, IChatService chatService)
        {
            _connectionMapping = connectionMapping;
            _chatService = chatService;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            await _connectionMapping.AddConnectionAsync(userId, Context.ConnectionId, "chat");
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user-inbox-{userId}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            await _connectionMapping.RemoveConnectionAsync(Context.ConnectionId, "chat");
            await base.OnDisconnectedAsync(exception);
        }

        public async Task SendMessage(Guid conversationId, string content)
        {
            var userId = GetUserId();
            var message = await _chatService.SendMessageAsync(conversationId, userId, content);

            await Clients.GroupExcept($"conversation-{conversationId}", Context.ConnectionId).SendAsync("ReceiveMessage", message);
            await Clients.Caller.SendAsync("MessageSent", message);

            var conversation = await _chatService.GetConversationAsync(conversationId, userId);
            if (conversation != null)
            {
                foreach (var participantId in conversation.ParticipantUserIds)
                    await Clients.Group($"user-inbox-{participantId}").SendAsync("ConversationUpdated", conversation);
            }
        }

        public async Task SendTripMessage(Guid tripId, string content)
        {
            var userId = GetUserId();
            var message = await _chatService.SendTripMessageAsync(tripId, userId, content);

            await Clients.GroupExcept($"conversation-{message.ConversationId}", Context.ConnectionId).SendAsync("ReceiveMessage", message);
            await Clients.Caller.SendAsync("MessageSent", message);
        }

        public async Task JoinConversation(Guid conversationId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"conversation-{conversationId}");
        }

        public async Task LeaveConversation(Guid conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conversation-{conversationId}");
        }

        public async Task MarkAsRead(Guid conversationId)
        {
            var userId = GetUserId();
            await _chatService.MarkAsReadAsync(conversationId, userId);
        }

        public async Task GetConversation(Guid conversationId)
        {
            var userId = GetUserId();
            var conversation = await _chatService.GetConversationAsync(conversationId, userId);
            await Clients.Caller.SendAsync("ConversationLoaded", conversation);
        }

        private Guid GetUserId()
        {
            var sub = Context.User?.FindFirstValue("sub");
            if (!string.IsNullOrEmpty(sub) && Guid.TryParse(sub, out var subGuid))
                return subGuid;

            var nameId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(nameId) && Guid.TryParse(nameId, out var nameGuid))
                return nameGuid;

            throw new HubException("User ID not found in token.");
        }
    }
