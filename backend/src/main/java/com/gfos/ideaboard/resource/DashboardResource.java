package com.gfos.ideaboard.resource;

import com.gfos.ideaboard.dto.IdeaDTO;
import com.gfos.ideaboard.security.Secured;
import com.gfos.ideaboard.service.IdeaService;
import com.gfos.ideaboard.service.SurveyService;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.*;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Path("/dashboard")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Secured
public class DashboardResource {

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private IdeaService ideaService;

    @Inject
    private SurveyService surveyService;

    @GET
    @Path("/statistics")
    public Response getStatistics() {
        Map<String, Object> stats = new HashMap<>();

        // Total ideas
        Long totalIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i", Long.class).getSingleResult();
        stats.put("totalIdeas", totalIdeas);

        // Total users
        Long totalUsers = em.createQuery("SELECT COUNT(u) FROM User u WHERE u.isActive = true", Long.class).getSingleResult();
        stats.put("totalUsers", totalUsers);

        // Ideas this week
        Long ideasThisWeek = em.createQuery(
                "SELECT COUNT(i) FROM Idea i WHERE i.createdAt >= :weekStart", Long.class)
                .setParameter("weekStart", java.time.LocalDate.now().with(java.time.DayOfWeek.SUNDAY).atStartOfDay())
                .getSingleResult();
        stats.put("ideasThisWeek", ideasThisWeek);

        // Status counts
        Long conceptIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.status = 'CONCEPT'", Long.class).getSingleResult();
        Long inProgressIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.status = 'IN_PROGRESS'", Long.class).getSingleResult();
        Long completedIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.status = 'COMPLETED'", Long.class).getSingleResult();
        stats.put("conceptIdeas", conceptIdeas);
        stats.put("inProgressIdeas", inProgressIdeas);
        stats.put("completedIdeas", completedIdeas);

        // Total likes
        Long totalLikes = em.createQuery("SELECT COUNT(l) FROM Like l", Long.class).getSingleResult();
        stats.put("totalLikes", totalLikes);

        // Total comments
        Long totalComments = em.createQuery("SELECT COUNT(c) FROM Comment c", Long.class).getSingleResult();
        stats.put("totalComments", totalComments);

        // Active surveys
        Long activeSurveys = em.createQuery("SELECT COUNT(s) FROM Survey s WHERE s.isActive = true", Long.class).getSingleResult();
        stats.put("activeSurveys", activeSurveys);

        // Most popular category
        List<Object[]> categoryResults = em.createQuery(
                "SELECT i.category, COUNT(i) as cnt FROM Idea i GROUP BY i.category ORDER BY cnt DESC", Object[].class)
                .getResultList();
        stats.put("popularCategory", categoryResults.isEmpty() ? "N/A" : categoryResults.get(0)[0]);

        // Category breakdown for charts
        List<Map<String, Object>> categoryBreakdown = categoryResults.stream()
                .map(row -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("category", row[0]);
                    item.put("count", row[1]);
                    return item;
                })
                .collect(Collectors.toList());
        stats.put("categoryBreakdown", categoryBreakdown);

        // Weekly activity (ideas created per day this week)
        List<Object[]> weeklyActivity = em.createQuery(
                "SELECT FUNCTION('DATE', i.createdAt), COUNT(i) FROM Idea i " +
                "WHERE i.createdAt >= :weekStart GROUP BY FUNCTION('DATE', i.createdAt) ORDER BY FUNCTION('DATE', i.createdAt)", Object[].class)
                .setParameter("weekStart", java.time.LocalDate.now().with(java.time.DayOfWeek.SUNDAY).atStartOfDay())
                .getResultList();
        List<Map<String, Object>> activityData = weeklyActivity.stream()
                .map(row -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("date", row[0].toString());
                    item.put("ideas", row[1]);
                    return item;
                })
                .collect(Collectors.toList());
        stats.put("weeklyActivity", activityData);

        return Response.ok(stats).build();
    }

    @GET
    @Path("/top-ideas")
    public Response getTopIdeas(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        List<IdeaDTO> topIdeas = ideaService.getTopIdeasThisWeek(3, userId);

        // Add rank information
        List<Map<String, Object>> result = topIdeas.stream()
                .map(idea -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("idea", idea);
                    item.put("rank", topIdeas.indexOf(idea) + 1);
                    item.put("weeklyLikes", idea.getLikeCount()); // Simplified
                    return item;
                })
                .collect(Collectors.toList());

        return Response.ok(result).build();
    }

    @GET
    @Path("/new-ideas")
    public Response getNewIdeas(
            @QueryParam("limit") @DefaultValue("5") int limit,
            @Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        List<IdeaDTO> ideas = ideaService.getIdeas(null, null, null, null, 0, limit, userId);
        return Response.ok(ideas).build();
    }

    @GET
    @Path("/surveys")
    public Response getActiveSurveys(@Context ContainerRequestContext requestContext) {
        Long userId = (Long) requestContext.getProperty("userId");
        return Response.ok(surveyService.getActiveSurveys(userId)).build();
    }
}
