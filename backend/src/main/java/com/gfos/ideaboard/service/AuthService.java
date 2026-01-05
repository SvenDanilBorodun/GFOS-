package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.AuthRequest;
import com.gfos.ideaboard.dto.AuthResponse;
import com.gfos.ideaboard.dto.RegisterRequest;
import com.gfos.ideaboard.dto.UserDTO;
import com.gfos.ideaboard.entity.User;
import com.gfos.ideaboard.entity.UserRole;
import com.gfos.ideaboard.exception.ApiException;
import com.gfos.ideaboard.security.JwtUtil;
import com.gfos.ideaboard.security.PasswordUtil;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;

@ApplicationScoped
public class AuthService {

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private JwtUtil jwtUtil;

    @Inject
    private PasswordUtil passwordUtil;

    @Transactional
    public AuthResponse login(AuthRequest request) {
        User user = findByUsername(request.getUsername());

        if (user == null) {
            throw ApiException.unauthorized("Invalid username or password");
        }

        if (!user.getIsActive()) {
            throw ApiException.unauthorized("Account is deactivated");
        }

        if (!passwordUtil.verifyPassword(request.getPassword(), user.getPasswordHash())) {
            throw ApiException.unauthorized("Invalid username or password");
        }

        // Update last login
        user.setLastLogin(LocalDateTime.now());
        em.merge(user);

        return createAuthResponse(user);
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Check if username exists
        if (findByUsername(request.getUsername()) != null) {
            throw ApiException.conflict("Username already exists");
        }

        // Check if email exists
        if (findByEmail(request.getEmail()) != null) {
            throw ApiException.conflict("Email already exists");
        }

        // Create new user
        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordUtil.hashPassword(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setRole(UserRole.EMPLOYEE);
        user.setXpPoints(0);
        user.setLevel(1);
        user.setIsActive(true);

        em.persist(user);
        em.flush();

        return createAuthResponse(user);
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtUtil.isTokenValid(refreshToken) || !jwtUtil.isRefreshToken(refreshToken)) {
            throw ApiException.unauthorized("Invalid refresh token");
        }

        Long userId = jwtUtil.getUserIdFromToken(refreshToken);
        User user = em.find(User.class, userId);

        if (user == null || !user.getIsActive()) {
            throw ApiException.unauthorized("User not found or inactive");
        }

        return createAuthResponse(user);
    }

    private AuthResponse createAuthResponse(User user) {
        String accessToken = jwtUtil.generateAccessToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        return new AuthResponse(
                accessToken,
                refreshToken,
                UserDTO.fromEntity(user),
                jwtUtil.getAccessTokenExpiration()
        );
    }

    private User findByUsername(String username) {
        try {
            return em.createNamedQuery("User.findByUsername", User.class)
                    .setParameter("username", username)
                    .getSingleResult();
        } catch (NoResultException e) {
            return null;
        }
    }

    private User findByEmail(String email) {
        try {
            return em.createNamedQuery("User.findByEmail", User.class)
                    .setParameter("email", email)
                    .getSingleResult();
        } catch (NoResultException e) {
            return null;
        }
    }
}
