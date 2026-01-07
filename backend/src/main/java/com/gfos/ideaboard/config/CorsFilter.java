package com.gfos.ideaboard.config;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;

/**
 * CORS filter that handles preflight OPTIONS requests and adds CORS headers to all responses.
 * Uses @PreMatching to intercept OPTIONS requests BEFORE authentication filters run.
 */
@Provider
@PreMatching
@Priority(Priorities.HEADER_DECORATOR)
public class CorsFilter implements ContainerRequestFilter, ContainerResponseFilter {

    private static final String ALLOWED_ORIGIN = "*";
    private static final String ALLOWED_METHODS = "GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH";
    private static final String ALLOWED_HEADERS = "Origin, Content-Type, Accept, Authorization, X-Requested-With";
    private static final String MAX_AGE = "86400";

    /**
     * Request filter - handles OPTIONS preflight requests immediately without authentication.
     */
    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        // Handle preflight OPTIONS requests - abort before authentication
        if ("OPTIONS".equalsIgnoreCase(requestContext.getMethod())) {
            requestContext.abortWith(
                Response.ok()
                    .header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
                    .header("Access-Control-Allow-Credentials", "true")
                    .header("Access-Control-Allow-Headers", ALLOWED_HEADERS)
                    .header("Access-Control-Allow-Methods", ALLOWED_METHODS)
                    .header("Access-Control-Max-Age", MAX_AGE)
                    .build()
            );
        }
    }

    /**
     * Response filter - adds CORS headers to all non-OPTIONS responses.
     */
    @Override
    public void filter(ContainerRequestContext requestContext,
                       ContainerResponseContext responseContext) throws IOException {
        // Add CORS headers to all responses
        responseContext.getHeaders().add("Access-Control-Allow-Origin", ALLOWED_ORIGIN);
        responseContext.getHeaders().add("Access-Control-Allow-Credentials", "true");
        responseContext.getHeaders().add("Access-Control-Allow-Headers", ALLOWED_HEADERS);
        responseContext.getHeaders().add("Access-Control-Allow-Methods", ALLOWED_METHODS);
        responseContext.getHeaders().add("Access-Control-Max-Age", MAX_AGE);
    }
}
