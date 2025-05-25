package com.instagram.server.service;

import com.instagram.server.entity.User;
import io.jsonwebtoken.Claims;
import org.springframework.security.core.userdetails.UserDetails;

import javax.crypto.SecretKey;
import java.util.Date;

public interface JwtService {
    String extractUsername(String token);
    boolean isValid(String token, UserDetails user);
    String generateAccessToken(User user);
    SecretKey getSigningKey();
}
