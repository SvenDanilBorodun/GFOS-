package com.gfos.ideaboard.resource;

import com.gfos.ideaboard.dto.GroupMessageDTO;
import com.gfos.ideaboard.dto.IdeaGroupDTO;
import com.gfos.ideaboard.exception.ApiException;
import com.gfos.ideaboard.security.Secured;
import com.gfos.ideaboard.service.GroupService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;

@Path("/groups")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Secured
public class GroupResource {

    @Inject
    private GroupService groupService;

    /**
     * Get all groups the current user is a member of.
     */
    @GET
    public Response getUserGroups(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        List<IdeaGroupDTO> groups = groupService.getUserGroups(userId);
        return Response.ok(groups).build();
    }

    /**
     * Get a specific group by ID.
     */
    @GET
    @Path("/{id}")
    public Response getGroup(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        IdeaGroupDTO group = groupService.getGroup(id, userId);
        return Response.ok(group).build();
    }

    /**
     * Get group by idea ID.
     */
    @GET
    @Path("/idea/{ideaId}")
    public Response getGroupByIdea(@PathParam("ideaId") Long ideaId, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        IdeaGroupDTO group = groupService.getGroupByIdea(ideaId, userId);
        return Response.ok(group).build();
    }

    /**
     * Join a group.
     */
    @POST
    @Path("/{id}/join")
    public Response joinGroup(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        IdeaGroupDTO group = groupService.joinGroup(id, userId);
        return Response.ok(group).build();
    }

    /**
     * Join a group by idea ID.
     */
    @POST
    @Path("/idea/{ideaId}/join")
    public Response joinGroupByIdea(@PathParam("ideaId") Long ideaId, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        IdeaGroupDTO group = groupService.joinGroupByIdea(ideaId, userId);
        return Response.ok(group).build();
    }

    /**
     * Leave a group.
     */
    @DELETE
    @Path("/{id}/leave")
    public Response leaveGroup(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        groupService.leaveGroup(id, userId);
        return Response.ok(Map.of("message", "Left group successfully")).build();
    }

    /**
     * Get all messages in a group.
     */
    @GET
    @Path("/{id}/messages")
    public Response getGroupMessages(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        List<GroupMessageDTO> messages = groupService.getGroupMessages(id, userId);
        return Response.ok(messages).build();
    }

    /**
     * Send a message to a group.
     */
    @POST
    @Path("/{id}/messages")
    public Response sendMessage(@PathParam("id") Long id, Map<String, String> body,
                                @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        String content = body.get("content");

        if (content == null || content.trim().isEmpty()) {
            throw ApiException.badRequest("Message content is required");
        }

        GroupMessageDTO message = groupService.sendMessage(id, content, userId);
        return Response.status(Response.Status.CREATED).entity(message).build();
    }

    /**
     * Mark all messages in a group as read.
     */
    @PUT
    @Path("/{id}/messages/read")
    public Response markAllAsRead(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        groupService.markAllMessagesAsRead(id, userId);
        return Response.ok(Map.of("message", "All messages marked as read")).build();
    }

    /**
     * Check if user is a member of a group.
     */
    @GET
    @Path("/{id}/membership")
    public Response checkMembership(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        boolean isMember = groupService.isMember(id, userId);
        return Response.ok(Map.of("isMember", isMember)).build();
    }

    /**
     * Check if user is a member of a group by idea ID.
     */
    @GET
    @Path("/idea/{ideaId}/membership")
    public Response checkMembershipByIdea(@PathParam("ideaId") Long ideaId, @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        try {
            IdeaGroupDTO group = groupService.getGroupByIdea(ideaId, userId);
            boolean isMember = groupService.isMember(group.getId(), userId);
            return Response.ok(Map.of("isMember", isMember, "groupId", group.getId())).build();
        } catch (Exception e) {
            return Response.ok(Map.of("isMember", false)).build();
        }
    }

    /**
     * Get total unread count across all groups.
     */
    @GET
    @Path("/unread-count")
    public Response getTotalUnreadCount(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        int unreadCount = groupService.getTotalUnreadCount(userId);
        return Response.ok(Map.of("unreadCount", unreadCount)).build();
    }
}
