package com.instagram.server.config;

import com.instagram.server.entity.Token;
import com.instagram.server.repository.TokenRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.LogoutHandler;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class CustomLogoutHandler implements LogoutHandler {

    private final TokenRepository tokenRepository;

    public CustomLogoutHandler(TokenRepository tokenRepository) {
        this.tokenRepository = tokenRepository;
    }

    @Override
    public void logout(HttpServletRequest request, HttpServletResponse response, Authentication authentication) {
        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return;
        }

        String token = authHeader.substring(7);

        // Get all tokens matching this access token (might be more than one)
        List<Token> tokensToInvalidate = tokenRepository.findAllByAccessToken(token);

        if (tokensToInvalidate.isEmpty()) {
            System.out.println("No tokens found for the provided access token");
            return;
        }

        // Mark all matching tokens as logged out
        for (Token storedToken : tokensToInvalidate) {
            storedToken.setLoggedOut(true);
        }

        // Save all the updated tokens
        tokenRepository.saveAll(tokensToInvalidate);
        System.out.println("Successfully logged out " + tokensToInvalidate.size() + " token(s)");
    }
}
