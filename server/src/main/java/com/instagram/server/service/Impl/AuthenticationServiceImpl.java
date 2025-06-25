package com.instagram.server.service.Impl;

import com.instagram.server.dto.request.AuthRequest;
import com.instagram.server.dto.response.AuthenticationResponse;
import com.instagram.server.entity.Token;
import com.instagram.server.entity.User;
import com.instagram.server.repository.TokenRepository;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.AuthenticationService;
import com.instagram.server.service.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
@SuppressWarnings("unused")
@RequiredArgsConstructor
public class AuthenticationServiceImpl implements AuthenticationService {
    private final UserRepository userRepository;
    private final TokenRepository tokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;

    public AuthenticationResponse register(AuthRequest request){
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .createdAt(new Date(System.currentTimeMillis()))
                .build();

        userRepository.save(user);
        String jwt = jwtService.generateAccessToken(user);

        saveUserToken(jwt, user);

        return new AuthenticationResponse(jwt);
    }

    public void saveUserToken(String jwt, User user) {
        Token token = new Token();
        token.setAccessToken(jwt);
        token.setLoggedOut(false);
        token.setUser(user);
        tokenRepository.save(token);
    }

    public AuthenticationResponse authenticate(AuthRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getUsername(),
                            request.getPassword()
                    )
            );

            User user = userRepository.findByUsername(request.getUsername())
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            String accessToken = jwtService.generateAccessToken(user);

            revokeAllTokenByUser(user);

            saveUserToken(accessToken, user);

            return new AuthenticationResponse(accessToken);

        } catch (org.springframework.security.authentication.BadCredentialsException e) {
            throw new RuntimeException("Invalid username or password");
        } catch (Exception e) {
            throw new RuntimeException("Authentication failed: " + e.getMessage());
        }
    }

    private void revokeAllTokenByUser(User user) {
        List<Token> validTokenListByUser = tokenRepository.findAllAccessTokensByUser(user.getUserId());

        if (!validTokenListByUser.isEmpty()){
            validTokenListByUser.forEach(t-> t.setLoggedOut(true));
        }

        tokenRepository.saveAll(validTokenListByUser);
    }
}
