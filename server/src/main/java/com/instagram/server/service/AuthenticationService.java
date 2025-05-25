package com.instagram.server.service;

import com.instagram.server.dto.request.AuthRequest;
import com.instagram.server.dto.response.AuthenticationResponse;
import com.instagram.server.entity.User;

public interface AuthenticationService {
    AuthenticationResponse register(AuthRequest request);
    void saveUserToken(String jwt, User user);
    AuthenticationResponse authenticate(AuthRequest request);
    void revokeAllTokenByUser(User user);

}
