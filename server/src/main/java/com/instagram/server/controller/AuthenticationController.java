package com.instagram.server.controller;

import com.instagram.server.service.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthenticationController {

    @Autowired
    private JwtTokenProvider tokenProvider;
    
    @GetMapping("/token")
    public ResponseEntity<?> getToken(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401).body("Not authenticated");
        }
        
        String token = tokenProvider.generateToken(authentication);
        
        Map<String, String> response = new HashMap<>();
        response.put("token", token);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401).body("Not authenticated");
        }
        
        Map<String, Object> userInfo = new HashMap<>();
        
        if (authentication instanceof OAuth2AuthenticationToken) {
            OAuth2AuthenticationToken oauthToken = (OAuth2AuthenticationToken) authentication;
            userInfo.put("name", oauthToken.getPrincipal().getAttribute("name"));
            userInfo.put("email", oauthToken.getPrincipal().getAttribute("email"));
            userInfo.put("provider", oauthToken.getAuthorizedClientRegistrationId());
        } else {
            userInfo.put("name", authentication.getName());
        }
        
        return ResponseEntity.ok(userInfo);
    }
}
