package com.gfos.ideaboard.util;

import at.favre.lib.crypto.bcrypt.BCrypt;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class FixPasswordHashes {

    private static final int BCRYPT_COST = 12;
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/ideaboard";
    private static final String DB_USER = "ideaboard_user";
    private static final String DB_PASSWORD = "ideaboard123";

    public static void main(String[] args) {
        try {
            // Generate correct hashes
            String adminHash = BCrypt.withDefaults().hashToString(BCRYPT_COST, "admin123".toCharArray());
            String userHash = BCrypt.withDefaults().hashToString(BCRYPT_COST, "password123".toCharArray());

            System.out.println("Connecting to database...");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);

            // Update admin password
            String updateAdmin = "UPDATE users SET password_hash = ? WHERE username = ?";
            PreparedStatement stmt1 = conn.prepareStatement(updateAdmin);
            stmt1.setString(1, adminHash);
            stmt1.setString(2, "admin");
            int count1 = stmt1.executeUpdate();
            System.out.println("Updated admin password: " + count1 + " row(s)");

            // Update test users
            String updateUsers = "UPDATE users SET password_hash = ? WHERE username IN (?, ?, ?)";
            PreparedStatement stmt2 = conn.prepareStatement(updateUsers);
            stmt2.setString(1, userHash);
            stmt2.setString(2, "jsmith");
            stmt2.setString(3, "mwilson");
            stmt2.setString(4, "tjohnson");
            int count2 = stmt2.executeUpdate();
            System.out.println("Updated test users passwords: " + count2 + " row(s)");

            // Verify
            String query = "SELECT username, role FROM users ORDER BY username";
            PreparedStatement stmt3 = conn.prepareStatement(query);
            ResultSet rs = stmt3.executeQuery();

            System.out.println("\nUsers in database:");
            while (rs.next()) {
                System.out.println("  - " + rs.getString("username") + " (" + rs.getString("role") + ")");
            }

            rs.close();
            stmt1.close();
            stmt2.close();
            stmt3.close();
            conn.close();

            System.out.println("\n✓ Password hashes updated successfully!");
            System.out.println("\nYou can now login with:");
            System.out.println("  admin / admin123");
            System.out.println("  jsmith / password123");
            System.out.println("  mwilson / password123");
            System.out.println("  tjohnson / password123");

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
