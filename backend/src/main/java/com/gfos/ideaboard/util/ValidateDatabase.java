package com.gfos.ideaboard.util;

import at.favre.lib.crypto.bcrypt.BCrypt;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

/**
 * Database validation utility to ensure seed data is correct.
 * Run this after database initialization to verify everything is working.
 */
public class ValidateDatabase {

    private static final String DB_URL = "jdbc:postgresql://localhost:5432/ideaboard";
    private static final String DB_USER = "ideaboard_user";
    private static final String DB_PASSWORD = "ideaboard123";

    // Expected test credentials
    private static final Map<String, String> TEST_CREDENTIALS = new HashMap<>() {{
        put("admin", "admin123");
        put("jsmith", "password123");
        put("mwilson", "password123");
        put("tjohnson", "password123");
    }};

    private static int testsRun = 0;
    private static int testsPassed = 0;
    private static int testsFailed = 0;

    public static void main(String[] args) {
        System.out.println("========================================");
        System.out.println("  DATABASE VALIDATION");
        System.out.println("========================================\n");

        try {
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            System.out.println("✓ Database connection successful\n");

            validateUserPasswords(conn);
            validateTableCounts(conn);
            validateDataIntegrity(conn);

            conn.close();

            System.out.println("\n========================================");
            System.out.println("  VALIDATION SUMMARY");
            System.out.println("========================================");
            System.out.println("Tests run:    " + testsRun);
            System.out.println("Tests passed: " + testsPassed + " ✓");
            System.out.println("Tests failed: " + testsFailed + " ✗");

            if (testsFailed == 0) {
                System.out.println("\n✓ ALL VALIDATION CHECKS PASSED!");
                System.out.println("  The database is ready for use.");
                System.exit(0);
            } else {
                System.out.println("\n✗ VALIDATION FAILED!");
                System.out.println("  Please review the errors above.");
                System.exit(1);
            }

        } catch (Exception e) {
            System.err.println("✗ FATAL ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void validateUserPasswords(Connection conn) throws Exception {
        System.out.println("--- Testing User Authentication ---");

        String query = "SELECT username, password_hash, role FROM users WHERE username = ?";
        PreparedStatement stmt = conn.prepareStatement(query);

        for (Map.Entry<String, String> entry : TEST_CREDENTIALS.entrySet()) {
            String username = entry.getKey();
            String expectedPassword = entry.getValue();

            stmt.setString(1, username);
            ResultSet rs = stmt.executeQuery();

            testsRun++;
            if (rs.next()) {
                String passwordHash = rs.getString("password_hash");
                String role = rs.getString("role");

                BCrypt.Result result = BCrypt.verifyer().verify(
                    expectedPassword.toCharArray(),
                    passwordHash
                );

                if (result.verified) {
                    System.out.println("  ✓ " + username + " (" + role + "): password verified");
                    testsPassed++;
                } else {
                    System.out.println("  ✗ " + username + " (" + role + "): password verification FAILED");
                    System.out.println("    Expected: " + expectedPassword);
                    System.out.println("    Hash does not match!");
                    testsFailed++;
                }
            } else {
                System.out.println("  ✗ " + username + ": user NOT FOUND in database");
                testsFailed++;
            }
            rs.close();
        }
        stmt.close();
        System.out.println();
    }

    private static void validateTableCounts(Connection conn) throws Exception {
        System.out.println("--- Checking Table Counts ---");

        String[] tables = {
            "users", "ideas", "badges", "comments", "likes",
            "surveys", "survey_options", "idea_tags"
        };

        PreparedStatement stmt;
        for (String table : tables) {
            testsRun++;
            stmt = conn.prepareStatement("SELECT COUNT(*) FROM " + table);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                int count = rs.getInt(1);
                if (count > 0) {
                    System.out.println("  ✓ " + table + ": " + count + " rows");
                    testsPassed++;
                } else {
                    System.out.println("  ✗ " + table + ": EMPTY (expected seed data)");
                    testsFailed++;
                }
            }
            rs.close();
            stmt.close();
        }
        System.out.println();
    }

    private static void validateDataIntegrity(Connection conn) throws Exception {
        System.out.println("--- Checking Data Integrity ---");

        // Check admin user exists and is active
        testsRun++;
        PreparedStatement stmt = conn.prepareStatement(
            "SELECT is_active, role FROM users WHERE username = 'admin'"
        );
        ResultSet rs = stmt.executeQuery();
        if (rs.next() && rs.getBoolean("is_active") && "ADMIN".equals(rs.getString("role"))) {
            System.out.println("  ✓ Admin user exists and is active");
            testsPassed++;
        } else {
            System.out.println("  ✗ Admin user missing or inactive");
            testsFailed++;
        }
        rs.close();
        stmt.close();

        // Check ideas have valid authors
        testsRun++;
        stmt = conn.prepareStatement(
            "SELECT COUNT(*) FROM ideas i LEFT JOIN users u ON i.author_id = u.id WHERE u.id IS NULL"
        );
        rs = stmt.executeQuery();
        if (rs.next() && rs.getInt(1) == 0) {
            System.out.println("  ✓ All ideas have valid authors");
            testsPassed++;
        } else {
            System.out.println("  ✗ Some ideas have invalid author references");
            testsFailed++;
        }
        rs.close();
        stmt.close();

        // Check badges are defined
        testsRun++;
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM badges WHERE is_active = true");
        rs = stmt.executeQuery();
        if (rs.next() && rs.getInt(1) >= 10) {
            System.out.println("  ✓ Badge system configured (" + rs.getInt(1) + " badges)");
            testsPassed++;
        } else {
            System.out.println("  ✗ Insufficient badges configured");
            testsFailed++;
        }
        rs.close();
        stmt.close();

        System.out.println();
    }
}
