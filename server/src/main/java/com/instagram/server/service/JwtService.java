package com.instagram.server.service;

import com.instagram.server.entity.User;
import io.jsonwebtoken.Claims;
import org.springframework.security.core.userdetails.UserDetails;

import javax.crypto.SecretKey;
import java.util.Date;

public interface JwtService {
    String extractUsername(String token);
    boolean isValid(String token, UserDetails user);
    boolean isTokenExpired(String token);
    Date extractExpiration(String token);
    Claims extractAllClaims(String token);
    String generateAccessToken(User user);
    String generateToken(User user, long expireTime);
    SecretKey getSigningKey();
}
