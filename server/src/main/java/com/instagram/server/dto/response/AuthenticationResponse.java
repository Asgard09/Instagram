package com.instagram.server.dto.response;

import lombok.Data;

@Data
public class AuthenticationResponse {

    private String accessToken;

    public AuthenticationResponse(String accessToken) {
        this.accessToken = accessToken;
    }
}
