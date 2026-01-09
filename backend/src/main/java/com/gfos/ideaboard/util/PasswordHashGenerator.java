package com.gfos.ideaboard.util;

import at.favre.lib.crypto.bcrypt.BCrypt;

public class PasswordHashGenerator {

    private static final int BCRYPT_COST = 12;

    public static void main(String[] args) {
        String[] passwords = {"admin123", "password123"};

        System.out.println("BCrypt Password Hashes:");
        System.out.println("======================");

        for (String password : passwords) {
            String hash = BCrypt.withDefaults().hashToString(BCRYPT_COST, password.toCharArray());
            System.out.println("\nPassword: " + password);
            System.out.println("Hash: " + hash);

            // Verify it works
            BCrypt.Result result = BCrypt.verifyer().verify(password.toCharArray(), hash);
            System.out.println("Verification: " + (result.verified ? "SUCCESS" : "FAILED"));
        }
    }
}
