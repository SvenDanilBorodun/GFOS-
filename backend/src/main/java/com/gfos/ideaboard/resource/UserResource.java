package com.gfos.ideaboard.resource;

import com.gfos.ideaboard.dto.UserDTO;
import com.gfos.ideaboard.entity.UserRole;
import com.gfos.ideaboard.exception.ApiException;
import com.gfos.ideaboard.security.Secured;
import com.gfos.ideaboard.service.LikeService;
import com.gfos.ideaboard.service.UserService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.container.ContainerRequestContext;
import java.util.List;
import java.util.Map;

@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {

    @Inject
    private UserService userService;

    @Inject
    private LikeService likeService;

    @GET
    @Path("/me")
    @Secured
    public Response getCurrentUser(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        UserDTO user = userService.getUserById(userId);
        return Response.ok(user).build();
    }

    @PUT
    @Path("/me")
    @Secured
    public Response updateCurrentUser(@Context ContainerRequestContext requestContext, Map<String, String> body) {
        Long userId = (Long) requestContext.getProperty("userId");
        UserDTO updated = userService.updateUser(
                userId,
                body.get("firstName"),
                body.get("lastName"),
                body.get("email")
        );
        return Response.ok(updated).build();
    }

    @GET
    @Path("/me/likes/remaining")
    @Secured
    public Response getRemainingLikes(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        int remaining = likeService.getRemainingLikes(userId);
        int used = likeService.getWeeklyLikesUsed(userId);
        return Response.ok(Map.of(
                "remainingLikes", remaining,
                "weeklyLikesUsed", used,
                "maxWeeklyLikes", 3
        )).build();
    }

    @GET
    @Secured
    public Response getAllUsers(@Context ContainerRequestContext requestContext) {
        String role = (String) requestContext.getProperty("role");
        if (!"ADMIN".equals(role)) {
            throw ApiException.forbidden("Only admins can list all users");
        }
        List<UserDTO> users = userService.getAllUsers();
        return Response.ok(users).build();
    }

    @GET
    @Path("/{id}")
    @Secured
    public Response getUserById(@PathParam("id") Long id, @Context ContainerRequestContext requestContext) {
        String role = (String) requestContext.getProperty("role");
        if (!"ADMIN".equals(role)) {
            throw ApiException.forbidden("Only admins can view other users");
        }
        UserDTO user = userService.getUserById(id);
        return Response.ok(user).build();
    }

    @PUT
    @Path("/{id}/role")
    @Secured
    public Response updateRole(@PathParam("id") Long id, Map<String, String> body,
                               @Context ContainerRequestContext requestContext) {
        String role = (String) requestContext.getProperty("role");
        if (!"ADMIN".equals(role)) {
            throw ApiException.forbidden("Only admins can change roles");
        }

        String newRole = body.get("role");
        if (newRole == null) {
            throw ApiException.badRequest("Role is required");
        }

        try {
            UserRole userRole = UserRole.valueOf(newRole);
            userService.updateRole(id, userRole);
            return Response.ok(Map.of("message", "Role updated")).build();
        } catch (IllegalArgumentException e) {
            throw ApiException.badRequest("Invalid role");
        }
    }

    @PUT
    @Path("/{id}/status")
    @Secured
    public Response updateStatus(@PathParam("id") Long id, Map<String, Boolean> body,
                                 @Context ContainerRequestContext requestContext) {
        String role = (String) requestContext.getProperty("role");
        if (!"ADMIN".equals(role)) {
            throw ApiException.forbidden("Only admins can change user status");
        }

        Boolean isActive = body.get("isActive");
        if (isActive == null) {
            throw ApiException.badRequest("isActive is required");
        }

        userService.setUserActive(id, isActive);
        return Response.ok(Map.of("message", "Status updated")).build();
    }
}
